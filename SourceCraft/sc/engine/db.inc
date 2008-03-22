/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: db.inc
 * Description: Loads and Saves Player data to the DataBase.
 * Author(s): -=|JFH|=-Naris
 */

#if defined _db_included
 #endinput
#endif
#define _db_included

// DBI
new Handle:DBIDB = INVALID_HANDLE;
new bool:DBIsSQLite = false;
new bool:g_AllPlayersSaved = false;

public ConnectToDatabase()
{
    decl String:error[256] = "";
    DBIDB = SQL_Connect("sourcecraft",true,error,sizeof(error));
    if (DBIDB == INVALID_HANDLE || error[0] != '\0')
    {
        LogError("Error connecting to the database:%s", error);
        return false;
    }
    else
    {
        decl String:dbident[64];
        SQL_ReadDriver(DBIDB, dbident, sizeof(dbident));
        LogMessage("Connected to the %s database", dbident);
        DBIsSQLite = (StrContains(dbident, "sqlite", false) >= 0);

        SQL_CreateTables();
        return true;
    }
}

public SQL_CreateTables()
{
    // Create the sc_races table, if it doesn't exist
    decl String:SQLString[512] = "";
    Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s",
            "CREATE TABLE IF NOT EXISTS sc_races ",
            "(race_ident int not null auto_increment,",
            " race_name varchar(16) not null,",
            " long_name varchar(64),",
            " add_date timestamp default current_timestamp,",
            "PRIMARY KEY(race_ident),",
            "INDEX(race_name))");

    if (!DBIsSQLite)
        StrCat(SQLString,sizeof(SQLString), " ENGINE=INNODB");

    // Process this query in the main thread (NOT a worker thread)
    // since we will need the race table to exist before we proceed.
    SQL_LockDatabase(DBIDB);

    if(!SQL_FastQuery(DBIDB,SQLString))
    {
        decl String:error[256] = "";
        SQL_GetError(DBIDB, error, sizeof(error));
        SQL_UnlockDatabase(DBIDB);
        LogError("Error in the creation of the sc_races SQL table:%s", error);
        SetFailState("Error in the creation of the sc_races SQL table");
    }
    else 
    {
        SQL_UnlockDatabase(DBIDB);

        // Create the sc_players table, if it doesn't exist
        Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s%s%s%s",
                "CREATE TABLE IF NOT EXISTS sc_players ",
                "(player_ident int not null auto_increment,",
                " steamid varchar(64) not null,",
                " name varchar(64),",
                " race_ident int default 0,",
                " credits int default 0,",
                " overall_level int default 0,",
                " last_update timestamp default current_timestamp,",
                "PRIMARY KEY(player_ident),",
                "UNIQUE INDEX (steamid))");

        if (!DBIsSQLite)
            StrCat(SQLString,sizeof(SQLString), " ENGINE=INNODB");

        SQL_TQuery(DBIDB, SQL_CreatePlayers, SQLString);
    }
}


public SQL_CreatePlayers(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        LogError("Error in the creation of the sc_players SQL table:%s", error);
    else
    {
        // Create the sc_player_races table, if it doesn't exist
        decl String:SQLString[2560] = "";

        if (DBIsSQLite)
        {
            Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s",
                    "CREATE TABLE IF NOT EXISTS sc_player_races ",
                    "(player_ident int not null,",
                    " race_ident int not null,",
                    " xp int default 0,",
                    " level int default 0,",
                    "PRIMARY KEY(player_ident,race_ident))");
        }
        else
        {
            Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
                    "CREATE TABLE IF NOT EXISTS sc_player_races ",
                    "(player_ident int not null,",
                    " race_ident int not null,",
                    " xp int default 0,",
                    " level int default 0,",
                    "PRIMARY KEY(player_ident,race_ident),",
                    "FOREIGN KEY (player_ident)",
                    "        REFERENCES sc_players(player_ident)",
                    "        ON DELETE CASCADE ON UPDATE CASCADE,",
                    "INDEX (race_ident),",
                    "FOREIGN KEY (race_ident)",
                    "        REFERENCES sc_races(race_ident)",
                    "        ON DELETE CASCADE ON UPDATE CASCADE) ",
                    "ENGINE=INNODB");
        }
        SQL_TQuery(DBIDB, SQL_CreatePlayerRaces, SQLString);
    }
}

public SQL_CreatePlayerRaces(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        LogError("Error in the creation of the sc_player_races SQL table:%s", error);
    else
    {
        // Create the sc_player_upgrades table, if it doesn't exist
        decl String:SQLString[2048] = "";

        if (DBIsSQLite)
        {
            Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s",
                    "CREATE TABLE IF NOT EXISTS sc_player_upgrades ",
                    "(player_ident int not null,",
                    " race_ident int not null,",
                    " upgrade int not null,",
                    " upgrade_level int default 0,",
                    "PRIMARY KEY(player_ident,race_ident,upgrade))");
        }
        else
        {
            Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
                    "CREATE TABLE IF NOT EXISTS sc_player_upgrades ",
                    "(player_ident int not null,",
                    " race_ident int not null,",
                    " upgrade int not null,",
                    " upgrade_level int default 0,",
                    "PRIMARY KEY(player_ident,race_ident,upgrade),",
                    "FOREIGN KEY (player_ident)",
                    "        REFERENCES sc_players(player_ident)",
                    "        ON DELETE CASCADE ON UPDATE CASCADE,",
                    "INDEX (race_ident),",
                    "FOREIGN KEY (race_ident)",
                    "        REFERENCES sc_races(race_ident)",
                    "        ON DELETE CASCADE ON UPDATE CASCADE,",
                    "FOREIGN KEY (player_ident,race_ident)",
                    "        REFERENCES sc_player_races(player_ident,race_ident)",
                    "        ON DELETE CASCADE ON UPDATE CASCADE) ",
                    "ENGINE=INNODB");
        }
        SQL_TQuery(DBIDB, SQL_CreatePlayerUpgrades, SQLString);
    }
}

public SQL_CreatePlayerUpgrades(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        LogError("Error in the creation of the sc_player_upgrades SQL table:%s", error);
}

public SaveRaceInfo(const String:shortName[], const String:raceName[])
{
    new race_ident = -1;
    if(DBIDB)
    {
        decl String:SQLString[512] = "";

        // Process this query in the main thread (NOT a worker thread)
        // since we have to return the result to the caller!
        SQL_LockDatabase(DBIDB);

        Format(SQLString,sizeof(SQLString), "SELECT race_ident FROM sc_races WHERE race_name='%s'", shortName);

        new Handle:query=SQL_Query(DBIDB,SQLString);
        if (query && SQL_FetchRow(query))
            race_ident = SQL_FetchInt(query,0);
        else
        {
            if (query)
                CloseHandle(query);

            Format(SQLString,sizeof(SQLString), "INSERT INTO sc_races (race_name,long_name,add_date) VALUES ('%s','%s',current_timestamp)", shortName, raceName);
            if (SQL_FastQuery(DBIDB,SQLString))
            {
                if (DBIsSQLite)
                    strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_rowid()");
                else
                    strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_id()");

                new Handle:race_query=SQL_Query(DBIDB,SQLString);
                if (race_query)
                {
                    if (SQL_FetchRow(race_query))
                        race_ident = SQL_FetchInt(race_query,0);
                    else
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to fetch race_ident for %s: %s",
                                 shortName, error);
                    }
                    CloseHandle(race_query);
                }
                else
                {
                    decl String:error[256] = "";
                    SQL_GetError(DBIDB, error, sizeof(error));
                    LogError("Unable to query race_ident for %s: %s",
                             shortName, error);
                }
            }
            else
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Unable to insert race %s: %s\nSQL:%s",
                         shortName, error, SQLString);
            }
        }
        SQL_UnlockDatabase(DBIDB);
    }
    return race_ident;
}

public LoadPlayerData(client,Handle:playerHandle, bool:threaded)
{
    new bool:fetch=false;
    //LogMessage("LoadPlayerData(%N), DBIDB=%d", client, DBIDB);
    if(DBIDB)
    {
        decl String:steamid[64] = "";
        if(GetClientAuthString(client,steamid,sizeof(steamid)))
        {
            decl String:SQLString[512] = "";

            // Process this query in the main thread (NOT a worker thread)
            // since we have to return the result to the caller!
            SQL_LockDatabase(DBIDB);

            Format(SQLString,sizeof(SQLString), "SELECT player_ident, race_ident, credits, overall_level FROM sc_players WHERE steamid = '%s'", steamid);

            new Handle:query=SQL_Query(DBIDB,SQLString);
            if(query)
            {
                fetch = SQL_FetchRow(query);
                if (fetch)
                {
                    new player_ident = SQL_FetchInt(query,0);
                    new race_ident = SQL_FetchInt(query,1);
                    new raceId = FindRaceForIdent(race_ident);

                    SetDatabaseIdent(playerHandle,player_ident);
                    SetRace(playerHandle,raceId);
                    SetCredits(playerHandle,SQL_FetchInt(query,2));
                    SetOverallLevel(playerHandle,SQL_FetchInt(query,3));

                    CloseHandle(query);

                    Format(SQLString,sizeof(SQLString), "SELECT race_ident, xp, level FROM sc_player_races WHERE player_ident = %d", player_ident);

                    if (threaded)
                    {
                        SQL_UnlockDatabase(DBIDB);

                        new Handle:dataPack = CreateDataPack();
                        WritePackCell(dataPack, client);
                        WritePackCell(dataPack, _:playerHandle);
                        WritePackCell(dataPack, player_ident);
                        ResetPack(dataPack);
                        SQL_TQuery(DBIDB, SQL_LoadRaces, SQLString, dataPack);
                    }
                    else
                    {
                        new Handle:raceQuery=SQL_Query(DBIDB,SQLString);
                        if(raceQuery)
                        {
                            if (SQL_HasResultSet(raceQuery))
                                ReadPlayerRaces(raceQuery, client, playerHandle, player_ident, threaded);
                        }
                        else
                        {
                            decl String:error[256] = "";
                            SQL_GetError(DBIDB, error, sizeof(error));
                            LogError("Unable to query %N's (%s) player data: %s\nSQL:%s",
                                     client, steamid, error, SQLString);
                        }
                        CloseHandle(raceQuery);

                        SQL_UnlockDatabase(DBIDB);
                    }
                }
                else
                {
                    CloseHandle(query);
                    SQL_UnlockDatabase(DBIDB);
                }
            }
            else
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Unable to query %N's (%s) player data: %s\nSQL:%s",
                         client, steamid, error, SQLString);

                SQL_UnlockDatabase(DBIDB);
            }
        }
        else
            LogError("Unable to obtain steamid for %N!", client);
    }

    // Return 2 if not fetched so race selection menu will be displayed
    return (fetch) ? 1 : 2;
}

public SQL_LoadRaces(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_LoadRaces!");
    else 
    {
        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 
        new player_ident = ReadPackCell(data);
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            LogError("Unable to query %N's race data: %s", client, error);
        else if (SQL_HasResultSet(hndl))
            ReadPlayerRaces(hndl, client, playerHandle, player_ident, true);
    }
}

ReadPlayerRaces(Handle:hndl, client, Handle:playerHandle, player_ident, bool:threaded)
{
    decl String:SQLString[512] = "";

    while (SQL_FetchRow(hndl))
    {
        new race_ident = SQL_FetchInt(hndl,0);
        new raceId = FindRaceForIdent(race_ident);

        SetXP(playerHandle,raceId,SQL_FetchInt(hndl,1));
        SetLevel(playerHandle,raceId,SQL_FetchInt(hndl,2));

        Format(SQLString,sizeof(SQLString), "SELECT upgrade, upgrade_level FROM sc_player_upgrades WHERE player_ident = %d and race_ident = %d", player_ident,race_ident);

        if (threaded)
        {
            new Handle:dataPack = CreateDataPack();
            WritePackCell(dataPack, client);
            WritePackCell(dataPack, _:playerHandle);
            WritePackCell(dataPack, raceId);
            ResetPack(dataPack);
            SQL_TQuery(DBIDB, SQL_LoadUpgrades, SQLString, dataPack);
        }
        else
        {
            new Handle:upgradeQuery=SQL_Query(DBIDB,SQLString);
            if(upgradeQuery)
            {
                if (SQL_HasResultSet(upgradeQuery))
                    ReadPlayerUpgrades(upgradeQuery, playerHandle, raceId);
            }
            else
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Unable to query %N's player data: %s\nSQL:%s",
                         client, error, SQLString);
            }
            CloseHandle(upgradeQuery);
        }
    }
}

public SQL_LoadUpgrades(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_LoadUpgrades!");
    else 
    {
        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 
        new raceId = ReadPackCell(data);
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            LogError("Unable to query %N's upgrade data: %s", client, error);
        else if (SQL_HasResultSet(hndl))
            ReadPlayerUpgrades(hndl, playerHandle, raceId);
    }
}

ReadPlayerUpgrades(Handle:hndl, Handle:playerHandle, raceId)
{
    while (SQL_FetchRow(hndl))
    {
        SetUpgradeLevel(playerHandle,raceId, SQL_FetchInt(hndl,0), SQL_FetchInt(hndl,1));
    }
}

public SaveAllPlayersData(bool:threaded)
{
    new playerCount = GetMaxClients();
    //LogMessage("SaveAllPlayersData(), threaded=%d, playerCount=%d", threaded, playerCount);
    for(new client=1;client<=playerCount;client++)
    {
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE && IsClientInGame(client))
            SavePlayerData(client,playerHandle,threaded,threaded);
    }
    g_AllPlayersSaved = true;
}

public SavePlayerData(client, Handle:playerHandle, bool:threaded, bool:cloneData)
{
    //LogMessage("SavePlayerData(%N), threaded=%d, clone=%d, DBIDB=%d", client, threaded, cloneData, DBIDB);
    if(DBIDB)
    {
        decl String:steamid[64]="";
        if(GetClientAuthString(client,steamid,sizeof(steamid)))
        {
            decl String:SQLString[512] = "";

            new credits           = GetCredits(playerHandle);
            new overall_level     = GetOverallLevel(playerHandle);
            new player_ident      = GetDatabaseIdent(playerHandle);

            new Handle:raceHandle = GetRaceHandle(GetRace(playerHandle));
            new race_ident        = GetRaceIdent(raceHandle);

            decl String:name[64];
            GetClientName(client,name,sizeof(name));
            ReplaceString(name,sizeof(name),"\\","\\\\");
            ReplaceString(name,sizeof(name),"'","''");

            //LogMessage("Saving Player Data for %N, player_ident=%d", client, player_ident);
            if (player_ident > 0)
            {
                Format(SQLString,sizeof(SQLString), "UPDATE sc_players SET race_ident=%d, credits=%d, overall_level=%d,last_update=current_timestamp WHERE player_ident = %d", race_ident, credits, overall_level, player_ident);

                if (threaded)
                {
                    //LogMessage("Starting thread to process:%s", SQLString);
                    // When threading, copy the data first so it can't
                    // get freed while we are using it!
                    new Handle:dataPack = CreateDataPack();
                    WritePackCell(dataPack, client);
                    WritePackCell(dataPack, _:(cloneData ? ClonePlayer(playerHandle) :  playerHandle));
                    WritePackCell(dataPack, player_ident);
                    ResetPack(dataPack);
                    SQL_TQuery(DBIDB, SQL_UpdatePlayer, SQLString, dataPack);
                }
                else
                {
                    // Process this query in the main thread
                    SQL_LockDatabase(DBIDB);

                    //LogMessage("Processing :%s", SQLString);
                    if (SQL_FastQuery(DBIDB,SQLString))
                        SavePlayerRaces(client, playerHandle, player_ident,threaded);
                    else
                    {
                        SetDatabaseIdent(playerHandle,-1);
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to update %N's player record, client=%d, playerHandle=%d, player_ident=%d: %s\nSQL:%s",
                                client, client, playerHandle, player_ident, error, SQLString);
                    }
                    SQL_UnlockDatabase(DBIDB);
                }
            }
            else
            {
                Format(SQLString,sizeof(SQLString), "INSERT INTO sc_players (steamid,name,race_ident,credits,overall_level,last_update) VALUES ('%s','%s',%d,%d,%d,current_timestamp)", steamid, name, race_ident, credits, overall_level);

                if (threaded)
                {
                    //LogMessage("Starting thread to process:%s", SQLString);
                    new Handle:dataPack = CreateDataPack();
                    WritePackCell(dataPack, client);
                    WritePackCell(dataPack, _:playerHandle);
                    WritePackString(dataPack, steamid);
                    ResetPack(dataPack);
                    SQL_TQuery(DBIDB, SQL_InsertPlayer, SQLString, dataPack);
                }
                else
                {
                    // Process this query in the main thread
                    SQL_LockDatabase(DBIDB);

                    //LogMessage("Processing :%s", SQLString);
                    if (SQL_FastQuery(DBIDB,SQLString))
                    {
                        if (DBIsSQLite)
                            strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_rowid()");
                        else
                            strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_id()");

                        new Handle:player_query=SQL_Query(DBIDB,SQLString);
                        if (player_query)
                        {
                            if(SQL_FetchRow(player_query))
                            {
                                player_ident = SQL_FetchInt(player_query,0);
                                SetDatabaseIdent(playerHandle,player_ident);
                                CloseHandle(player_query);
                                SavePlayerRaces(client, playerHandle, player_ident,threaded);
                            }
                            else
                            {
                                decl String:error[256] = "";
                                SQL_GetError(DBIDB, error, sizeof(error));
                                LogError("Unable to fetch %N's ident: %s\nSQL:%s",
                                         client, error, SQLString);
                                CloseHandle(player_query);
                            }
                        }
                        else
                        {
                            decl String:error[256] = "";
                            SQL_GetError(DBIDB, error, sizeof(error));
                            LogError("Unable to query %N's ident: %s\nSQL:%s",
                                     client, error, SQLString);
                        }
                    }
                    else
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to insert %N's player data, client=%d, playerHandle=%d, player_ident=%d: %s\nSQL:%s",
                                 client, client, playerHandle, player_ident, error, SQLString);

                        Format(SQLString,sizeof(SQLString), "SELECT player_ident FROM sc_players WHERE steamid = '%s'",
                                steamid);

                        new Handle:query=SQL_Query(DBIDB,SQLString);
                        if(query)
                        {
                            if (SQL_FetchRow(query))
                            {
                                player_ident = SQL_FetchInt(query,0);
                                if (player_ident > 0)
                                {
                                    LogMessage("Found %N's player_ident=%d, retrying save...",
                                               client, player_ident);

                                    SetDatabaseIdent(playerHandle,player_ident);
                                    SavePlayerData(client,playerHandle,threaded,cloneData);
                                }
                            }
                        }
                    }
                    SQL_UnlockDatabase(DBIDB);
                }
            }
        }
        else
            LogError("Unable to obtain steamid for %N", client);
    }
}

public SQL_UpdatePlayer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_UpdatePlayer!");
    else 
    {
        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 
        new player_ident = ReadPackCell(data); 
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
        {
            SetDatabaseIdent(playerHandle,-1);
            LogError("Unable to update player record, client=%d, playerHandle=%d, player_ident=%d: %s",
                     client, playerHandle, player_ident, error);
        }
        else
        {
            //LogMessage("Updated player data, client=%d, playerHandle=%d, player_ident=%d",
            //           client, playerHandle, player_ident);

            SavePlayerRaces(client, playerHandle, player_ident,true);
        }
    }
}

public SQL_InsertPlayer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_InsertPlayer!");
    else 
    {
        decl String:SQLString[512] = "";

        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 

        decl String:steamid[64]="";
        ReadPackString(data, steamid, sizeof(steamid));

        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
        {
            LogError("Unable to insert player data, client=%d, playerHandle=%d: %s",
                     client, playerHandle, error);

            Format(SQLString,sizeof(SQLString), "SELECT player_ident FROM sc_players WHERE steamid = '%s'",
                   steamid);

            //LogMessage("Starting thread to process:%s", SQLString);
            new Handle:dataPack = CreateDataPack();
            WritePackCell(dataPack, client);
            WritePackCell(dataPack, _:playerHandle);
            ResetPack(dataPack);
            SQL_TQuery(DBIDB, SQL_SelectPlayerIdent, SQLString, dataPack);
        }
        else
        {
            if (DBIsSQLite)
                strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_rowid()");
            else
                strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_id()");

            //LogMessage("Starting thread to process:%s", SQLString);
            new Handle:dataPack = CreateDataPack();
            WritePackCell(dataPack, client);
            WritePackCell(dataPack, _:playerHandle);
            ResetPack(dataPack);
            SQL_TQuery(DBIDB, SQL_SelectLastPlayerIdent, SQLString, dataPack);
        }
    }
}

public SQL_SelectPlayerIdent(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_SelectPlayerIdent!");
    else 
    {
        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            LogError("Unable to query %N's ident: %s", client, error);
        else if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
        {
            new player_ident = SQL_FetchInt(hndl,0);
            if (player_ident > 0)
            {
                LogMessage("Found player data, client=%d, player_ident=%d, retrying save...",
                           client, player_ident);

                SetDatabaseIdent(playerHandle,player_ident);
                SavePlayerData(client,playerHandle,true,false);
            }
            else
            {
                LogError("Found player_ident for client=%d, which is invalid: %d",
                         client, player_ident);
            }
        }
        else
            LogError("Unable to fetch player ident, client=%d : %s", client, error);
    }
}

public SQL_SelectLastPlayerIdent(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_LoadUpgrades!");
    else 
    {
        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            LogError("Unable to query player ident, client=%d : %s", client, error);
        else if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
        {
            new player_ident = SQL_FetchInt(hndl,0);
            SetDatabaseIdent(playerHandle,player_ident);
            SavePlayerRaces(client, playerHandle, player_ident,true);
            //LogMessage("Inserted %N's player data, client=%d, playerHandle=%d, player_ident=%d",
            //           client, client, playerHandle, player_ident);
        }
        else
            LogError("Unable to fetch player identi for client=%d: %s", client, error);
    }
}

public SavePlayerRaces(client, Handle:playerHandle, player_ident, bool:threaded)
{
    decl String:SQLString[512] = "";
    new raceCount = GetRaceCount();
    new lastRace  = raceCount - 1;
    for(new raceId=0;raceId<raceCount;raceId++)
    {
        new xp    = GetXP(playerHandle,raceId);
        new level = GetLevel(playerHandle,raceId);

        if (xp || level)
        {
            new Handle:raceHandle = GetRaceHandle(raceId);
            new race_ident = GetRaceIdent(raceHandle);

            if (DBIsSQLite)
            {
                Format(SQLString,sizeof(SQLString), "REPLACE INTO sc_player_races (player_ident,race_ident,xp,level) VALUES (%d,%d,%d,%d)", player_ident, race_ident, xp, level);
            }
            else
            {
                Format(SQLString,sizeof(SQLString), "INSERT INTO sc_player_races (player_ident,race_ident,xp,level) VALUES (%d,%d,%d,%d) ON DUPLICATE KEY UPDATE xp=%d,level=%d", player_ident, race_ident, xp, level, xp, level);
            }

            if (threaded)
            {
                //LogMessage("Starting thread to process:%s", SQLString);
                new Handle:dataPack = CreateDataPack();
                WritePackCell(dataPack, client);
                WritePackCell(dataPack, _:playerHandle);
                WritePackCell(dataPack, player_ident);
                WritePackCell(dataPack, raceId);
                WritePackCell(dataPack, race_ident);
                WritePackCell(dataPack, _:raceHandle);
                WritePackCell(dataPack, _:(raceId == lastRace)); // Last Race Indicator
                ResetPack(dataPack);
                SQL_TQuery(DBIDB, SQL_SavePlayerRaces, SQLString, dataPack);
            }
            else
            {
                //LogMessage("Processing :%s", SQLString);
                if (SQL_FastQuery(DBIDB,SQLString))
                {
                    SavePlayerUpgrades(client, playerHandle, player_ident,
                                       raceId, race_ident, raceHandle,
                                       threaded, (raceId == lastRace));
                }
                else
                {
                    decl String:error[256] = "";
                    decl String:raceName[64] = "";
                    GetRaceShortName(raceHandle, raceName, sizeof(raceName));
                    SQL_GetError(DBIDB, error, sizeof(error));
                    LogError("Unable to insert/replace %s data, client=%d: %s\nSQL:%s",
                             raceName, client, error, SQLString);

                    SetDatabaseIdent(playerHandle,-1); // Reset ident!
                }
            }
        }
    }
}

public SQL_SavePlayerRaces(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_SavePlayerRaces!");
    else 
    {
        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 
        new player_ident = ReadPackCell(data); 
        new raceId = ReadPackCell(data);
        new race_ident = ReadPackCell(data);
        new Handle:raceHandle = Handle:ReadPackCell(data);
        new bool:last_race = bool:ReadPackCell(data);
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
        {
            decl String:raceName[64] = "";
            GetRaceShortName(raceHandle, raceName, sizeof(raceName));
            LogError("Unable to insert/replace %s data, client=%d : %s",
                     raceName, client, error);

            SetDatabaseIdent(playerHandle,-1); // Reset ident!
        }
        else
        {
            //LogMessage("Updated race data, client=%d, player_ident=%d, race_ident=%d",
            //           client, player_ident, race_ident);

            SavePlayerUpgrades(client, playerHandle, player_ident, raceId, race_ident, raceHandle, true,last_race);
        }
    }
}

public SavePlayerUpgrades(client, Handle:playerHandle, player_ident,
                          raceId, race_ident, Handle:raceHandle,
                          bool:threaded, bool:last_race)
{
    decl String:SQLString[512] = "";
    new upgradeCount = GetUpgradeCount(raceHandle);
    new lastUpgrade  = upgradeCount - 1;
    for(new upgrade=0;upgrade<upgradeCount;upgrade++)
    {
        new upgradeLevel = GetUpgradeLevel(playerHandle,raceId,upgrade);

        if (DBIsSQLite)
        {
            Format(SQLString,sizeof(SQLString), "REPLACE INTO sc_player_upgrades (player_ident,race,upgrade,upgrade_level) VALUES (%d,%d,%d,%d)", player_ident, race_ident, upgrade, upgradeLevel);
        }
        else
        {
            Format(SQLString,sizeof(SQLString), "INSERT INTO sc_player_upgrades (player_ident,race_ident,upgrade,upgrade_level) VALUES (%d,%d,%d,%d) ON DUPLICATE KEY UPDATE upgrade_level=%d", player_ident, race_ident, upgrade, upgradeLevel, upgradeLevel);
        }

        if (threaded)
        {
            //LogMessage("Starting thread to process:%s", SQLString);
            new Handle:dataPack = CreateDataPack();
            WritePackCell(dataPack, client);
            WritePackCell(dataPack, _:playerHandle);
            WritePackCell(dataPack, _:(last_race && (upgrade == lastUpgrade)));
            ResetPack(dataPack);

            SQL_TQuery(DBIDB, SQL_SavePlayerUpgrades, SQLString, dataPack);
        }
        else
        {
            //LogMessage("Processing :%s", SQLString);
            if (!SQL_FastQuery(DBIDB,SQLString))
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Unable to insert/replace upgrade data, client=%d : %s\nSQL:%s",
                         client, error, SQLString);
            }
        }
    }
}

public SQL_SavePlayerUpgrades(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        LogError("Invalid Datapack Passed to SQL_SavePlayerUpgrades!");
    else 
    {
        new client = ReadPackCell(data); 
        new Handle:playerHandle = Handle:ReadPackCell(data); 
        new bool:last_upgrade = bool:ReadPackCell(data);
        if (hndl == INVALID_HANDLE || error[0] != '\0')
            LogError("Unable to insert/replace one upgrade data, client=%d : %s", client, error);

        if (last_upgrade)
            ClearPlayer(0, playerHandle);
    }
}
