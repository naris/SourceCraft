/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: db_create.inc
 * Description: Creates Database Tables.
 * Author(s): -=|JFH|=-Naris
 */

#if defined _db_create_included
 #endinput
#endif
#define _db_create_included

new bool:g_DbIsSQLite  = false;

bool:InitDatabase()
{
    if (ConnectToDatabase())
    {
        g_DbIsSQLite = (StrContains(dbident, "sqlite", false) >= 0);
        SQL_CreateTables();
        return true;
    }
    else
        return false;
}

SQL_CreateTables()
{
    // Create the sc_races table, if it doesn't exist
    decl String:SQLString[512];
    Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s",
           "CREATE TABLE IF NOT EXISTS sc_races ",
           "(race_ident int not null auto_increment,",
           " race_name varchar(16) not null,",
           " long_name varchar(64),",
           " add_date timestamp default current_timestamp,",
           "PRIMARY KEY(race_ident),",
           "INDEX(race_name))");

    if (!g_DbIsSQLite)
        StrCat(SQLString,sizeof(SQLString), " ENGINE=INNODB");

    // Process this query in the main thread (NOT a worker thread)
    // since we will need the race table to exist before we proceed.
    SQL_LockDatabase(g_DbHandle);

    if (!SQL_FastQuery(g_DbHandle,SQLString))
    {
        decl String:error[256];
        error[0] = '\0';
        SQL_GetError(g_DbHandle, error, sizeof(error));
        SQL_UnlockDatabase(g_DbHandle);
        LogError("Error in the creation of the sc_races SQL table:%s", error);
        SetFailState("Error in the creation of the sc_races SQL table");
    }
    else 
    {
        SQL_UnlockDatabase(g_DbHandle);

        // Create the sc_players table, if it doesn't exist
        Format(SQLString,sizeof(SQLString), "%s%s%s%s%s%s%s%s%s%s%s%s",
               "CREATE TABLE IF NOT EXISTS sc_players ",
               "(player_ident int not null auto_increment,",
               " steamid varchar(64) not null,",
               " name varchar(64),",
               " race_ident int default 0,",
               " crystals int default 0,",
               " vespene int default 0,",
               " overall_level int default 0,",
               " settings int default 0,",
               " last_update timestamp default current_timestamp,",
               "PRIMARY KEY(player_ident),",
               "UNIQUE INDEX (steamid))");

        if (!g_DbIsSQLite)
            StrCat(SQLString,sizeof(SQLString), " ENGINE=INNODB");

        SQL_TQuery(g_DbHandle, SQL_CreatePlayers, SQLString);
    }
}

public SQL_CreatePlayers(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        LogError("Error in the creation of the sc_players SQL table:%s", error);
    else
    {
        // Create the sc_player_races table, if it doesn't exist
        decl String:SQLString[2560];

        if (g_DbIsSQLite)
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
        SQL_TQuery(g_DbHandle, SQL_CreatePlayerRaces, SQLString);
    }
}

public SQL_CreatePlayerRaces(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        LogError("Error in the creation of the sc_player_races SQL table:%s", error);
    else
    {
        // Create the sc_player_upgrades table, if it doesn't exist
        decl String:SQLString[2048];

        if (g_DbIsSQLite)
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
        SQL_TQuery(g_DbHandle, SQL_CreatePlayerUpgrades, SQLString);
    }
}

public SQL_CreatePlayerUpgrades(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        LogError("Error in the creation of the sc_player_upgrades SQL table:%s", error);
}
