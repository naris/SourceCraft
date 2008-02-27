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

public SQLTable()
{
    if (DBIDB)
    {
        decl String:SQLString[2048] = "";
        // Create the tables, if they don't exist
        Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s",
               "CREATE TABLE IF NOT EXISTS sc_races ",
               "(race_ident int not null auto_increment,",
               " race_name varchar(16) not null,",
               " long_name varchar(64),",
               " add_date timestamp default current_timestamp,",
               "PRIMARY KEY(race_ident),",
               "INDEX(race_name)) ENGINE=INNODB");
        if(!SQL_FastQuery(DBIDB,SQLString))
        {
            decl String:error[256] = "";
            SQL_GetError(DBIDB, error, sizeof(error));
            LogError("Error in the creation of the sc_races SQL table:%s", error);
            SetFailState("Error in the creation of the sc_races SQL table");
        }
        else 
        {
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
                   "UNIQUE INDEX (steamid)) ENGINE=INNODB");
            if(!SQL_FastQuery(DBIDB,SQLString))
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Error in the creation of the sc_players SQL table:%s", error);
                SetFailState("Error in the creation of the sc_players SQL table");
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
                if(!SQL_FastQuery(DBIDB,SQLString))
                {
                    decl String:error[256] = "";
                    SQL_GetError(DBIDB, error, sizeof(error));
                    LogError("Error in the creation of the sc_player_races SQL table:%s", error);
                    SetFailState("Error in the creation of the sc_player_races SQL table");
                }
                else
                {
                    Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
                           "CREATE TABLE IF NOT EXISTS sc_player_skills",
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
                    if(!SQL_FastQuery(DBIDB,SQLString))
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Error in the creation of the sc_player_skills SQL table:%s", error);
                        SetFailState("Error in the creation of the sc_player_skills SQL table");
                    }
                }
            }
        }
    }
}

public SaveRaceInfo(const String:shortName[], const String:raceName[])
{
    new race_ident;
    if(DBIDB)
    {
        decl String:SQLString[512] = "";

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
                query=SQL_Query(DBIDB,"SELECT LAST_INSERT_ID()");
                if (query)
                {
                    if (SQL_FetchRow(query))
                    {
                        race_ident = SQL_FetchInt(query,0);
                        if (!SQL_FastQuery(DBIDB,"COMMIT"))
                        {
                            decl String:error[256] = "";
                            SQL_GetError(DBIDB, error, sizeof(error));
                            LogError("Error commiting race data: %s", error);
                        }
                    }
                    else
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to fetch race_ident: %s", error);
                        race_ident = -1;
                    }
                    CloseHandle(query);
                }
                else
                {
                    decl String:error[256] = "";
                    SQL_GetError(DBIDB, error, sizeof(error));
                    LogError("Unable to query race_ident: %s", error);
                    race_ident = -1;
                }
            }
            else
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Unable to insert race: %s\nSQL:%s", error, SQLString);
                race_ident = -1;
            }
        }
    }
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

                    Format(SQLString,sizeof(SQLString), "SELECT race_ident, xp, level FROM sc_player_races WHERE player_ident = %d", player_ident);

                    new Handle:raceQuery=SQL_Query(DBIDB,SQLString);
                    if(raceQuery)
                    {
                        while (SQL_FetchRow(raceQuery))
                        {
                            race_ident = SQL_FetchInt(raceQuery,0);
                            raceId = FindRaceForIdent(race_ident);

                            SetXP(vectorpos,raceId,SQL_FetchInt(raceQuery,1));
                            SetLevel(vectorpos,raceId,SQL_FetchInt(raceQuery,2));

                            Format(SQLString,sizeof(SQLString), "SELECT skill, skill_level FROM sc_player_skills WHERE player_ident = %d and race_ident = %d", player_ident,race_ident);

                            new Handle:skillQuery=SQL_Query(DBIDB,SQLString);
                            if(skillQuery)
                            {
                                while (SQL_FetchRow(skillQuery))
                                {
                                    SetSkillLevel(vectorpos,raceId,
                                                  SQL_FetchInt(skillQuery,0),
                                                  SQL_FetchInt(skillQuery,1));
                                }
                                CloseHandle(skillQuery);
                            }
                            else
                            {
                                decl String:error[256] = "";
                                SQL_GetError(DBIDB, error, sizeof(error));
                                LogError("Unable to query skill data: %s\nSQL:%s", error, SQLString);
                            }
                        }
                        CloseHandle(raceQuery);
                    }
                    else
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to query race data: %s\nSQL:%s", error, SQLString);
                    }
                }
                CloseHandle(query);
            }
            else
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Unable to query player data: %s\nSQL:%s", error, SQLString);
            }
        }
    }

    // Return 2 if not fetched so race selection menu will be displayed
    return (fetch) ? 1 : 2;
}

public SavePlayerData(client,vectorpos)
{
    if(DBIDB)
    {
        decl String:steamid[64]="";
        if(GetClientAuthString(client,steamid,sizeof(steamid)))
        {
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

            decl String:SQLString[512] = "";

            if (player_ident > 0)
            {
                Format(SQLString,sizeof(SQLString), "UPDATE sc_players SET race_ident=%d, credits=%d, overall_level=%d,last_update=current_timestamp WHERE player_ident = %d", race_ident, credits, overall_level, player_ident);
                if (!SQL_FastQuery(DBIDB,SQLString))
                {
                    decl String:error[256] = "";
                    SQL_GetError(DBIDB, error, sizeof(error));
                    LogError("Unable to update %N's player record: %s\nSQL:%s",
                             client, error, SQLString);
                    return;
                }
            }
            else
            {
                if (DBIsSQLite)
                {
                    Format(SQLString,sizeof(SQLString), "REPLACE INTO sc_players (steamid,name,race_ident,credits,overall_level,last_update) VALUES ('%s','%s',%d,%d,%d,current_timestamp)", steamid, name, race_ident, credits, overall_level);
                }
                else
                {
                    Format(SQLString,sizeof(SQLString), "INSERT INTO sc_players (steamid,name,race_ident,credits,overall_level,last_update) VALUES ('%s','%s',%d,%d,%d,current_timestamp) ON DUPLICATE KEY UPDATE race_ident=%d, credits=%d, overall_level=%d,last_update=current_timestamp", steamid, name, race_ident, credits, overall_level, race_ident, credits, overall_level);
                }

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
                            CloseHandle(player_query);
                        }
                        else
                        {
                            decl String:error[256] = "";
                            SQL_GetError(DBIDB, error, sizeof(error));
                            LogError("Unable to fetch %N's ident: %s\nSQL:%s",
                                     client, error, SQLString);
                            CloseHandle(player_query);
                            return;
                        }
                    }
                    else
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to query %N's ident: %s\nSQL:%s",
                                 client, error, SQLString);
                        return;
                    }
                }
                else
                {
                    decl String:error[256] = "";
                    SQL_GetError(DBIDB, error, sizeof(error));
                    LogError("Unable to insert/replace %N's player data: %s\nSQL:%s",
                             client, error, SQLString);
                    return;
                }
            }

            new raceCount = RACE_COUNT();
            for(raceId=0;raceId<raceCount;raceId++)
            {
                new xp    = GetXP(vectorpos,raceId);
                new level = GetLevel(vectorpos,raceId);

                if (xp || level)
                {
                    raceHandle = Race(raceId);
                    race_ident = GetRaceIdent(raceHandle);

                    if (DBIsSQLite)
                    {
                        Format(SQLString,sizeof(SQLString), "REPLACE INTO sc_player_races (player_ident,race_ident,xp,level) VALUES (%d,%d,%d,%d)", player_ident, race_ident, xp, level);
                    }
                    else
                    {
                        Format(SQLString,sizeof(SQLString), "INSERT INTO sc_player_races (player_ident,race_ident,xp,level) VALUES (%d,%d,%d,%d) ON DUPLICATE KEY UPDATE xp=%d,level=%d", player_ident, race_ident, xp, level, xp, level);
                    }

                    if (SQL_FastQuery(DBIDB,SQLString))
                    {
                        for(new skill=0;skill<SKILL_COUNT;skill++)
                        {
                            new skillLevel = GetSkillLevel(vectorpos,raceId,skill);
                            if (skillLevel)
                            {
                                if (DBIsSQLite)
                                {
                                    Format(SQLString,sizeof(SQLString), "REPLACE INTO sc_player_skills (player_ident,race,skill,skill_level) VALUES (%d,%d,%d,%d)", player_ident, race_ident, skill, skillLevel);
                                }
                                else
                                {
                                    Format(SQLString,sizeof(SQLString), "INSERT INTO sc_player_skills (player_ident,race_ident,skill,skill_level) VALUES (%d,%d,%d,%d) ON DUPLICATE KEY UPDATE skill_level=%d", player_ident, race_ident, skill, skillLevel, skillLevel);
                                }

                                if (!SQL_FastQuery(DBIDB,SQLString))
                                {
                                    decl String:error[256] = "";
                                    SQL_GetError(DBIDB, error, sizeof(error));
                                    LogError("Unable to insert/replace one of %N's skills: %s\nSQL:%s",
                                             client, error, SQLString);
                                }
                            }
                        }
                    }
                    else
                    {
                        decl String:error[256] = "";
                        decl String:raceName[64] = "";
                        GetRaceShortName(raceHandle, raceName, sizeof(raceName));
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to insert/replace %N's %s data: %s\nSQL:%s",
                                 client, raceName, error, SQLString);
                    }
                }
            }

            if (!SQL_FastQuery(DBIDB,"COMMIT"))
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("Error commiting %N's data: %s", client, error);
            }
        }
    }
}
