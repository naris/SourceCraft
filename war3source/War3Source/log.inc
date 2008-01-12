/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: log.inc
 * Description: Writes message to console and log.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _log_included
 #endinput
#endif
#define _log_included

stock Log(String:message[])
{
    PrintToServer(message);
    LogMessage(message);
}

stock Error(String:message[])
{
    PrintToServer(message);
    LogError(message);
}

stock Fail(String:message[])
{
    PrintToServer(message);
    SetFailState(message);
}

stock LogDamage(client, victim, String:weapon[], String:description[], hp, xp=0)
{
    decl String:steamID[64];
    GetClientAuthString(client,steamID,63);

    decl String:team[64];
    GetTeamName(GetClientTeam(client), team, sizeof(team));

    decl String:victimID[64];
    GetClientAuthString(victim,victimID,63);

    decl String:victimTeam[64];
    GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

    PrintToChat(victim, "%c[War3Source] %N %chas damaged you for %d with a %c%s%c",
                COLOR_GREEN,client,COLOR_DEFAULT,hp,COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToChat(client, "%c[War3Source] %cYou damaged %N for %d hp with a %c%s%c.",
                COLOR_GREEN,COLOR_DEFAULT,victim, hp, COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToConsole(victim, "[War3Source] \"%N\"<%d><%s><%s> damaged \"%N\"<%d><%s><%s> for %d with %s\n",
                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

    PrintToConsole(client, "[War3Source] \"%N\"<%d><%s><%s> damaged \"%N\"<%d><%s><%s> for %d with %s\n",
                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

    LogToGame("[War3Source] \"%s\"<%d><%s><%s> damaged \"%N\"<%d><%s><%s> for %d with %s\n",
              client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
}

stock LogKill(client, victim, String:weapon[], String:description[], hp=0, xp=0)
{
    decl String:steamID[64];
    GetClientAuthString(client,steamID,63);

    decl String:team[64];
    GetTeamName(GetClientTeam(client), team, sizeof(team));

    decl String:victimID[64];
    GetClientAuthString(victim,victimID,63);

    decl String:victimTeam[64];
    GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

    PrintToChat(victim, "%c[War3Source] %N %c killed you with a %c%s%c",
                COLOR_GREEN,client,COLOR_DEFAULT,COLOR_TEAM,description,COLOR_DEFAULT);

    if (xp)
    {
        PrintToChat(client, "%c[War3Source] %cYou gained %d XP for killing %N with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,xp,victim, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(victim, "[War3Source] \"%N\"<%d><%s><%s> killed \"%N\"<%d><%s><%s> with %s (%d XP)\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

        PrintToConsole(client, "[War3Source] \"%N\"<%d><%s><%s> killed \"%N\"<%d><%s><%s> with %s (%d XP)\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

        LogToGame("[War3Source] \"%N\"<%d><%s><%s> killed \"%N\"<%d><%s><%s> with %s (%d XP)\n",
                  client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
    }
    else
    {
        PrintToChat(client, "%c[War3Source] %cYou killed %N with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,victim, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(client, "[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

        PrintToConsole(victim, "[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

        LogToGame("[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s\n",
                  client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
    }
}
