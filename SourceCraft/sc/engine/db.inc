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

    if(!SQL_FastQuery(DBIDB,SQLString))
    {
        decl String:error[256] = "";
        SQL_GetError(DBIDB, error, sizeof(error));
        LogError("Error in the creation of the sc_races SQL table:%s", error);
        SetFailState("Error in the creation of the sc_races SQL table");
    }
    else 
    {
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
        ThrowError("Error in the creation of the sc_players SQL table:%s", error);
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
        ThrowError("Error in the creation of the sc_player_races SQL table:%s", error);
    else
    {
        // Create the sc_player_skills table, if it doesn't exist
        decl String:SQLString[2048] = "";

        if (DBIsSQLite)
        {
            Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s",
                    "CREATE TABLE IF NOT EXISTS sc_player_skills ",
                    "(player_ident int not null,",
                    " race_ident int not null,",
                    " skill int not null,",
                    " skill_level int default 0,",
                    "PRIMARY KEY(player_ident,race_ident,skill))");
        }
        else
        {
            Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
                    "CREATE TABLE IF NOT EXISTS sc_player_skills ",
                    "(player_ident int not null,",
                    " race_ident int not null,",
                    " skill int not null,",
                    " skill_level int default 0,",
                    "PRIMARY KEY(player_ident,race_ident,skill),",
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
        SQL_TQuery(DBIDB, SQL_CreatePlayerSkills, SQLString);
    }
}

public SQL_CreatePlayerSkills(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        ThrowError("Error in the creation of the sc_player_skills SQL table:%s", error);
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
        {
            race_ident = SQL_FetchInt(query,0);
            LogMessage("Found race_ident=%d for %s", race_ident, shortName);
        }
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
                    {
                        race_ident = SQL_FetchInt(race_query,0);
                        LogMessage("Inserted race %s,  race_ident=%d", shortName, race_ident);
                    }
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
    else
        ThrowNativeError(-1, "Database Connection Not Found");

    return race_ident;
}

public LoadPlayerData(client,vectorpos)
{
    new bool:fetch=false;
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

                    SetDatabaseIdent(vectorpos,player_ident);
                    SetRace(vectorpos,raceId);
                    SetCredits(vectorpos,SQL_FetchInt(query,2));
                    SetOverallLevel(vectorpos,SQL_FetchInt(query,3));

                    LogMessage("Loaded %N's player data, client=%d, vectorpos=%d, player_ident=%d",
                               client, client, vectorpos, player_ident);

                    // Load the rest of the Player data using threads.
                    CloseHandle(query);
                    SQL_UnlockDatabase(DBIDB);

                    Format(SQLString,sizeof(SQLString), "SELECT race_ident, xp, level FROM sc_player_races WHERE player_ident = %d", player_ident);

                    new Handle:dataPack = CreateDataPack();
                    WritePackCell(dataPack, client);
                    WritePackCell(dataPack, vectorpos);
                    WritePackCell(dataPack, player_ident);
                    ResetPack(dataPack);
                    SQL_TQuery(DBIDB, SQL_LoadRaces, SQLString, dataPack);
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
        ThrowError("Invalid Datapack Passed to SQL_LoadRaces!");
    else 
    {
        new client       = ReadPackCell(data); 
        new vectorpos    = ReadPackCell(data); 
        new player_ident = ReadPackCell(data);
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            ThrowError("Unable to query %N's race data: %s", client, error);
        else if (SQL_HasResultSet(hndl))
        {
            decl String:SQLString[512] = "";

            while (SQL_FetchRow(hndl))
            {
                new race_ident = SQL_FetchInt(hndl,0);
                new raceId = FindRaceForIdent(race_ident);

                SetXP(vectorpos,raceId,SQL_FetchInt(hndl,1));
                SetLevel(vectorpos,raceId,SQL_FetchInt(hndl,2));

                Format(SQLString,sizeof(SQLString), "SELECT skill, skill_level FROM sc_player_skills WHERE player_ident = %d and race_ident = %d", player_ident,race_ident);

                new Handle:dataPack = CreateDataPack();
                WritePackCell(dataPack, client);
                WritePackCell(dataPack, vectorpos);
                WritePackCell(dataPack, raceId);
                ResetPack(dataPack);
                SQL_TQuery(DBIDB, SQL_LoadSkills, SQLString, dataPack);
            }
        }
    }
}

public SQL_LoadSkills(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        ThrowError("Invalid Datapack Passed to SQL_LoadSkills!");
    else 
    {
        new client    = ReadPackCell(data); 
        new vectorpos = ReadPackCell(data); 
        new raceId    = ReadPackCell(data);
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            ThrowError("Unable to query %N's skill data: %s", client, error);
        else if (SQL_HasResultSet(hndl))
        {
            while (SQL_FetchRow(hndl))
            {
                SetSkillLevel(vectorpos,raceId,
                              SQL_FetchInt(hndl,0),
                              SQL_FetchInt(hndl,1));
            }
        }
    }
}

public SavePlayerData(client,vectorpos)
{
    if(DBIDB)
    {
        decl String:steamid[64]="";
        if(GetClientAuthString(client,steamid,sizeof(steamid)))
        {
            decl String:SQLString[512] = "";

            new credits           = GetCredits(vectorpos);
            new overall_level     = GetOverallLevel(vectorpos);
            new player_ident      = GetDatabaseIdent(vectorpos);

            new raceId            = GetRace(vectorpos);
            new Handle:raceHandle = Race(raceId);
            new race_ident        = GetRaceIdent(raceHandle);

            decl String:name[64];
            GetClientName(client,name,sizeof(name));
            ReplaceString(name,sizeof(name),"\\","\\\\");
            ReplaceString(name,sizeof(name),"'","''");

            if (player_ident > 0)
            {
                Format(SQLString,sizeof(SQLString), "UPDATE sc_players SET race_ident=%d, credits=%d, overall_level=%d,last_update=current_timestamp WHERE player_ident = %d", race_ident, credits, overall_level, player_ident);

                new Handle:dataPack = CreateDataPack();
                WritePackCell(dataPack, client);
                WritePackCell(dataPack, vectorpos);
                WritePackCell(dataPack, player_ident);
                ResetPack(dataPack);
                SQL_TQuery(DBIDB, SQL_UpdatePlayer, SQLString, dataPack);
            }
            else
            {
                Format(SQLString,sizeof(SQLString), "INSERT INTO sc_players (steamid,name,race_ident,credits,overall_level,last_update) VALUES ('%s','%s',%d,%d,%d,current_timestamp)", steamid, name, race_ident, credits, overall_level);

                new Handle:dataPack = CreateDataPack();
                WritePackCell(dataPack, client);
                WritePackCell(dataPack, vectorpos);
                WritePackString(dataPack, steamid);
                ResetPack(dataPack);
                SQL_TQuery(DBIDB, SQL_InsertPlayer, SQLString, dataPack);
            }
        }
        else
            LogError("Unable to obtain steamid for %N", client);
    }
}

public SQL_UpdatePlayer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        ThrowError("Invalid Datapack Passed to SQL_UpdatePlayer!");
    else 
    {
        new client       = ReadPackCell(data); 
        new vectorpos    = ReadPackCell(data); 
        new player_ident = ReadPackCell(data); 
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
        {
            SetDatabaseIdent(vectorpos,-1);
            ThrowError("Unable to update %N's player record, client=%d, vectorpos=%d, player_ident=%d: %s",
                       client, client, vectorpos, player_ident, error);
        }
        else
        {
            LogMessage("Updated %N's player data, client=%d, vectorpos=%d, player_ident=%d",
                       client, client, vectorpos, player_ident);

            SavePlayerRaces(client, vectorpos, player_ident);
        }
    }
}

public SQL_InsertPlayer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        ThrowError("Invalid Datapack Passed to SQL_InsertPlayer!");
    else 
    {
        decl String:SQLString[512] = "";

        new client    = ReadPackCell(data); 
        new vectorpos = ReadPackCell(data); 

        decl String:steamid[64]="";
        ReadPackString(data, steamid, sizeof(steamid));

        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
        {
            LogError("Unable to insert %N's player data, client=%d, vectorpos=%d: %s",
                     client, client, vectorpos, error);

            Format(SQLString,sizeof(SQLString), "SELECT player_ident FROM sc_players WHERE steamid = '%s'",
                   steamid);

            new Handle:dataPack = CreateDataPack();
            WritePackCell(dataPack, client);
            WritePackCell(dataPack, vectorpos);
            ResetPack(dataPack);
            SQL_TQuery(DBIDB, SQL_SelectPlayerIdent, SQLString, dataPack);
        }
        else
        {
            if (DBIsSQLite)
                strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_rowid()");
            else
                strcopy(SQLString,sizeof(SQLString), "SELECT last_insert_id()");

            new Handle:dataPack = CreateDataPack();
            WritePackCell(dataPack, client);
            WritePackCell(dataPack, vectorpos);
            ResetPack(dataPack);
            SQL_TQuery(DBIDB, SQL_SelectLastPlayerIdent, SQLString, dataPack);
        }
    }
}

public SQL_SelectPlayerIdent(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        ThrowError("Invalid Datapack Passed to SQL_SelectPlayerIdent!");
    else 
    {
        new client    = ReadPackCell(data); 
        new vectorpos = ReadPackCell(data); 
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            ThrowError("Unable to query %N's ident: %s", client, error);
        else if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
        {
            new player_ident = SQL_FetchInt(hndl,0);
            if (player_ident > 0)
            {
                LogMessage("Found %N's player_ident=%d, retrying save...",
                           client, player_ident);

                SetDatabaseIdent(vectorpos,player_ident);
                SavePlayerData(client,vectorpos);
            }
            else
            {
                ThrowError("Found %N's player_ident, which is invalid: %d",
                           client, player_ident);
            }
        }
        else
            ThrowError("Unable to fetch %N's ident: %s", client, error);
    }
}

public SQL_SelectLastPlayerIdent(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        ThrowError("Invalid Datapack Passed to SQL_LoadSkills!");
    else 
    {
        new client    = ReadPackCell(data); 
        new vectorpos = ReadPackCell(data); 
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
            ThrowError("Unable to query %N's ident: %s", client, error);
        else if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
        {
            new player_ident = SQL_FetchInt(hndl,0);
            SetDatabaseIdent(vectorpos,player_ident);

            LogMessage("Inserted %N's player data, client=%d, vectorpos=%d, player_ident=%d",
                       client, client, vectorpos, player_ident);

            SavePlayerRaces(client, vectorpos, player_ident);
        }
        else
            ThrowError("Unable to fetch %N's ident: %s", client, error);
    }
}


public SavePlayerRaces(client, vectorpos, player_ident)
{
    decl String:SQLString[512] = "";
    new raceCount = RACE_COUNT();
    for(new raceId=0;raceId<raceCount;raceId++)
    {
        new xp    = GetXP(vectorpos,raceId);
        new level = GetLevel(vectorpos,raceId);

        if (xp || level)
        {
            new Handle:raceHandle = Race(raceId);
            new race_ident = GetRaceIdent(raceHandle);

            if (DBIsSQLite)
            {
                Format(SQLString,sizeof(SQLString), "REPLACE INTO sc_player_races (player_ident,race_ident,xp,level) VALUES (%d,%d,%d,%d)", player_ident, race_ident, xp, level);
            }
            else
            {
                Format(SQLString,sizeof(SQLString), "INSERT INTO sc_player_races (player_ident,race_ident,xp,level) VALUES (%d,%d,%d,%d) ON DUPLICATE KEY UPDATE xp=%d,level=%d", player_ident, race_ident, xp, level, xp, level);
            }

            new Handle:dataPack = CreateDataPack();
            WritePackCell(dataPack, client);
            WritePackCell(dataPack, vectorpos);
            WritePackCell(dataPack, player_ident);
            WritePackCell(dataPack, raceId);
            WritePackCell(dataPack, race_ident);
            WritePackCell(dataPack, _:raceHandle);
            ResetPack(dataPack);
            SQL_TQuery(DBIDB, SQL_SavePlayerRaces, SQLString, dataPack);
        }
    }
}

public SQL_SavePlayerRaces(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (data == INVALID_HANDLE)
        ThrowError("Invalid Datapack Passed to SQL_SavePlayerRaces!");
    else 
    {
        new client = ReadPackCell(data); 
        new vectorpos = ReadPackCell(data); 
        new player_ident = ReadPackCell(data); 
        new raceId = ReadPackCell(data);
        new race_ident = ReadPackCell(data);
        new Handle:raceHandle = Handle:ReadPackCell(data);
        CloseHandle(data);

        if (hndl == INVALID_HANDLE || error[0] != '\0')
        {
            decl String:raceName[64] = "";
            GetRaceShortName(raceHandle, raceName, sizeof(raceName));
            ThrowError("Unable to insert/replace %N's %s data: %s",
                       client, raceName, error);

            SetDatabaseIdent(vectorpos,-1); // Reset ident!
        }
        else
        {
            LogMessage("Updated %N's race data, player_ident=%d, race_ident=%d",
                       client, player_ident, race_ident);

            decl String:SQLString[512] = "";
            for(new skill=0;skill<SKILL_COUNT;skill++)
            {
                new skillLevel = GetSkillLevel(vectorpos,raceId,skill);

                if (DBIsSQLite)
                {
                    Format(SQLString,sizeof(SQLString), "REPLACE INTO sc_player_skills (player_ident,race,skill,skill_level) VALUES (%d,%d,%d,%d)", player_ident, race_ident, skill, skillLevel);
                }
                else
                {
                    Format(SQLString,sizeof(SQLString), "INSERT INTO sc_player_skills (player_ident,race_ident,skill,skill_level) VALUES (%d,%d,%d,%d) ON DUPLICATE KEY UPDATE skill_level=%d", player_ident, race_ident, skill, skillLevel, skillLevel);
                }

                SQL_TQuery(DBIDB, SQL_SavePlayerSkills, SQLString, client);
            }
        }
    }

}

public SQL_SavePlayerSkills(Handle:owner, Handle:hndl, const String:error[], any:client)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        ThrowError("Unable to insert/replace one of %N's skills: %s", client, error);
}
