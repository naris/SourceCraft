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
    decl String:name[64];
    GetClientName(client,name,63);

    decl String:steamID[64];
    GetClientAuthString(client,steamID,63);

    new team=GetClientTeam(client);

    decl String:victimName[64];
    GetClientName(victim,victimName,63);

    decl String:victimID[64];
    GetClientAuthString(victim,victimID,63);

    new victimTeam=GetClientTeam(victim);

    PrintToChat(victim, "%c[War3Source] %s %chas damaged you for %d with a %c%s%c",
                COLOR_GREEN,name,COLOR_DEFAULT,hp,COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToChat(client, "%c[War3Source] %cYou damaged %s for %d hp with a %c%s%c.",
                COLOR_GREEN,COLOR_DEFAULT,victimName, hp, COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToConsole(victim, "[War3Source] \"%s\"<%d><%s><%s> damaged \"%s\"<%d><%s><%s> for %d with %s\n",
                   name, client, steamID, (team == 2) ? "Red" : "Blue",
                   victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", hp, weapon);

    PrintToConsole(client, "[War3Source] \"%s\"<%d><%s><%s> damaged \"%s\"<%d><%s><%s> for %d with %s\n",
                   name, client, steamID, (team == 2) ? "Red" : "Blue",
                   victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", hp, weapon);

    LogToGame("[War3Source] \"%s\"<%d><%s><%s> damaged \"%s\"<%d><%s><%s> for %d with %s\n",
              name, client, steamID, (team == 2) ? "Red" : "Blue",
              victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", hp, weapon);
}

stock LogKill(client, victim, String:weapon[], String:description[], hp=0, xp=0)
{
    decl String:name[64];
    GetClientName(client,name,63);

    decl String:steamID[64];
    GetClientAuthString(client,steamID,63);

    new team=GetClientTeam(client);

    decl String:victimName[64];
    GetClientName(victim,victimName,63);

    decl String:victimID[64];
    GetClientAuthString(victim,victimID,63);

    new victimTeam=GetClientTeam(victim);

    PrintToChat(victim, "%c[War3Source] %s %c killed you with a %c%s%c",
                COLOR_GREEN,name,COLOR_DEFAULT,COLOR_TEAM,description,COLOR_DEFAULT);

    if (xp)
    {
        PrintToChat(client, "%c[War3Source] %cYou gained %d XP for killing %s with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,xp,victimName, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(victim, "[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s (%d XP)\n",
                       name, client, steamID, (team == 2) ? "Red" : "Blue",
                       victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", weapon,  xp);

        PrintToConsole(client, "[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s (%d XP)\n",
                       name, client, steamID, (team == 2) ? "Red" : "Blue",
                       victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", weapon,  xp);

        LogToGame("[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s (%d XP)\n",
                  name, client, steamID, (team == 2) ? "Red" : "Blue", weapon,  xp);
    }
    else
    {
        PrintToChat(client, "%c[War3Source] %cYou killed %s with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,victimName, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(client, "[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s\n",
                       name, client, steamID, (team == 2) ? "Red" : "Blue",
                       victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", weapon);

        PrintToConsole(victim, "[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s\n",
                       name, client, steamID, (team == 2) ? "Red" : "Blue",
                       victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", weapon);

        LogToGame("[War3Source] \"%s\"<%d><%s><%s> killed \"%s\"<%d><%s><%s> with %s\n",
                  name, client, steamID, (team == 2) ? "Red" : "Blue",
                  victimName, victim, victimID, (victimTeam == 2) ? "Red" : "Blue", weapon);
    }
}
