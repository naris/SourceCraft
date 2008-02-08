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
new bool:bUpdateIsOK = true;

public SQLTable()
{
    if (DBIDB)
    {
        // Create the tables, if they don;t exist
        if(!SQL_FastQuery(DBIDB,"CREATE TABLE IF NOT EXISTS w3s_players (steamid varchar(64) not null, name varchar(64), race varchar(30), credits int default 0, overall_level int default 0, last_update timestamp default current_timestamp, PRIMARY KEY(steamid))"))
        {
            decl String:error[256] = "";
            SQL_GetError(DBIDB, error, sizeof(error));
            LogError("Error in the creation of the w3s_players SQL table:%s", error);
            SetFailState("Error in the creation of the w3s_players SQL table");
        }
        else if(!SQL_FastQuery(DBIDB,"CREATE TABLE IF NOT EXISTS w3s_player_races (steamid varchar(64) not null, race varchar(30) not null, xp int default 0, level int default 0, PRIMARY KEY(steamid,race))"))
        {
            decl String:error[256] = "";
            SQL_GetError(DBIDB, error, sizeof(error));
            LogError("Error in the creation of the w3s_skills SQL table:%s", error);
            SetFailState("Error in the creation of the w3s_skills SQL table");
        }
        else if(!SQL_FastQuery(DBIDB,"CREATE TABLE IF NOT EXISTS w3s_player_skills (steamid varchar(64) not null, race varchar(30) not null, skill int not null, skill_level int default 0,  PRIMARY KEY(steamid,race,skill))"))
        {
            decl String:error[256] = "";
            SQL_GetError(DBIDB, error, sizeof(error));
            LogError("Error in the creation of the w3s_skills SQL table:%s", error);
            SetFailState("Error in the creation of the w3s_skills SQL table");
        }
    }
}

public LoadPlayerData(client,vectorpos)
{
    new bool:fetch=false;
    if(DBIDB)
    {
        decl String:steamid[64] = "";
        if(GetClientAuthString(client,steamid,sizeof(steamid)))
        {
            decl String:buf[256] = "";
            Format(buf,sizeof(buf),
                   "SELECT race, credits, overall_level FROM w3s_players WHERE steamid = '%s'",
                   steamid);

            new Handle:query=SQL_Query(DBIDB,buf);
            if(query)
            {
                fetch = SQL_FetchRow(query);
                if (fetch)
                {
                    decl String:raceName[64]="";
                    SQL_FetchString(query,0,raceName,sizeof(raceName));

                    SetRace(vectorpos,FindRace(raceName));
                    SetCredits(vectorpos,SQL_FetchInt(query,1));
                    SetOverallLevel(vectorpos,SQL_FetchInt(query,2));

                    Format(buf,sizeof(buf),
                           "SELECT race, xp, level FROM w3s_player_races WHERE steamid = '%s'",
                           steamid);

                    new Handle:raceQuery=SQL_Query(DBIDB,buf);
                    if(raceQuery)
                    {
                        while (SQL_FetchRow(raceQuery))
                        {
                            SQL_FetchString(raceQuery,0,raceName,sizeof(raceName));
                            new raceId=FindRace(raceName);

                            SetXP(vectorpos,raceId,SQL_FetchInt(raceQuery,1));
                            SetLevel(vectorpos,raceId,SQL_FetchInt(raceQuery,2));

                            Format(buf,sizeof(buf),
                                   "SELECT skill, skill_level FROM w3s_player_skills WHERE steamid = '%s' and race = '%s'",
                                   steamid,raceName);

                            new Handle:skillQuery=SQL_Query(DBIDB,buf);
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
                        }
                        CloseHandle(raceQuery);
                    }
                }
                CloseHandle(query);
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
            decl String:raceName[64]="";
            GetRaceShortName(Race(GetRace(vectorpos)), raceName, sizeof(raceName));

            new credits       = GetCredits(vectorpos);
            new overall_level = GetOverallLevel(vectorpos);

            decl String:name[64];
            GetClientName(client,name,sizeof(name));
            ReplaceString(name,sizeof(name),"\\","\\\\");
            ReplaceString(name,sizeof(name),"'","''");

            decl String:SQLString[512] = "";

            for(;;) // loop until break.
            {
                if (bUpdateIsOK)
                {
                    Format(SQLString,sizeof(SQLString), "INSERT INTO w3s_players (steamid,name,race,credits,overall_level,last_update) VALUES ('%s','%s','%s',%d,%d,current_timestamp) ON DUPLICATE KEY UPDATE race='%s', credits=%d, overall_level=%d,last_update=current_timestamp", steamid, name, raceName, credits, overall_level, raceName, credits, overall_level);
                }
                else
                {
                    Format(SQLString,sizeof(SQLString), "REPLACE INTO w3s_players (steamid,name,race,credits,overall_level,last_update) VALUES ('%s','%s','%s',%d,%d,current_timestamp)", steamid, name, raceName, credits, overall_level);
                }

                if (SQL_FastQuery(DBIDB,SQLString))
                    break;
                else
                {
                    decl String:error[256] = "";
                    SQL_GetError(DBIDB, error, sizeof(error));

                    if (bUpdateIsOK)
                    {
                        LogMessage("INSERT ON DUPLICATE UPDATE failed, using REPLACE! %s\nSQL:%s",error, SQLString);
                        bUpdateIsOK = false;
                    }
                    else
                    {
                        LogError("Unable to replace player's race: %s\nSQL:%s",
                                 error, SQLString);
                        return;
                    }
                }
            }

            new raceCount = GetArraySize(arrayRaces);
            for(new raceId=0;raceId<raceCount;raceId++)
            {
                new Handle:race=Race(raceId);
                GetArrayString(race,RACE_SHORT_NAME,raceName,sizeof(raceName));

                new xp    = GetXP(vectorpos,raceId);
                new level = GetLevel(vectorpos,raceId);

                if (xp || level)
                {
                    if (bUpdateIsOK)
                    {
                        Format(SQLString,sizeof(SQLString), "INSERT INTO w3s_player_races (steamid,race,xp,level) VALUES ('%s','%s',%d,%d) ON DUPLICATE KEY UPDATE xp=%d,level=%d", steamid, raceName, xp, level, xp, level);
                    }
                    else
                    {
                        Format(SQLString,sizeof(SQLString), "REPLACE INTO w3s_player_races (steamid,race,xp,level) VALUES ('%s','%s',%d,%d)", steamid, raceName, xp, level);
                    }
                    if (!SQL_FastQuery(DBIDB,SQLString))
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("Unable to replace player: %s\nSQL:%s\n",
                                 error, SQLString);
                        return;
                    }

                    for(new skill=0;skill<SKILL_COUNT;skill++)
                    {
                        new skillLevel = GetSkillLevel(vectorpos,raceId,skill);
                        if (skillLevel)
                        {
                            if (bUpdateIsOK)
                            {
                                Format(SQLString,sizeof(SQLString), "INSERT INTO w3s_player_skills (steamid,race,skill,skill_level) VALUES ('%s','%s',%d,%d) ON DUPLICATE KEY UPDATE skill_level=%d", steamid, raceName, skill, skillLevel, skillLevel);
                            }
                            else
                            {
                                Format(SQLString,sizeof(SQLString), "REPLACE INTO w3s_player_skills (steamid,race,skill,skill_level) VALUES ('%s','%s',%d,%d)", steamid, raceName, skill, skillLevel);
                            }

                            if (!SQL_FastQuery(DBIDB,SQLString))
                            {
                                decl String:error[256] = "";
                                SQL_GetError(DBIDB, error, sizeof(error));
                                LogError("Unable to insert player's skill: %s\nSQL:%s\n",
                                         error, SQLString);
                                return;
                            }
                        }
                    }
                }
            }
        }
    }
}
