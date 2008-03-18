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

    PrintToChat(victim, "%c[SourceCraft] %N %chas damaged you for %d with a %c%s%c",
                COLOR_GREEN,client,COLOR_DEFAULT,hp,COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToChat(client, "%c[SourceCraft] %cYou damaged %N for %d hp with a %c%s%c.",
                COLOR_GREEN,COLOR_DEFAULT,victim, hp, COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

    PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

    LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
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

    PrintToChat(victim, "%c[SourceCraft] %N %c killed you with a %c%s%c",
                COLOR_GREEN,client,COLOR_DEFAULT,COLOR_TEAM,description,COLOR_DEFAULT);

    if (xp)
    {
        PrintToChat(client, "%c[SourceCraft] %cYou gained %d XP for killing %N with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,xp,victim, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

        PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

        LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" fatally injured \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                  client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
    }
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cYou killed %N with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,victim, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

        PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

        LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" fatally injured \"%N<%d><%s><%s>\" with %s\n",
                  client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
    }
}

stock LogEventDamage(Handle:event,damage,const String:source[], race_id)
{
    new userid=GetEventInt(event,"userid");
    new victim=GetClientOfUserId(userid);
    new victim_player=GetPlayerHandle(victim);
    new victim_race=(victim_player != INVALID_HANDLE) ? GetRace(victim_player) : -1;

    new attacker_uid=GetEventInt(event,"attacker");
    new attacker=GetClientOfUserId(attacker_uid);
    new attacker_player=GetPlayerHandle(attacker);
    new attacker_race=(attacker_player != INVALID_HANDLE) ? GetRace(attacker_player) : -1;

    new assister_uid = GetEventInt(event,"assister");
    new assister=GetClientOfUserId(assister_uid);
    new assister_player=GetPlayerHandle(assister);
    new assister_race=(assister_player != INVALID_HANDLE) ? GetRace(assister_player) : -1;

    if (race_id == victim_race   || race_id == attacker_race ||
        race_id == assister_race || race_id < 0)
    {
        new health=0;
        decl String:team[64] = "";
        decl String:steamID[64] = "";
        decl String:attacker_weapon[64] = "";
        if (attacker)
        {
            GetClientAuthString(attacker,steamID,sizeof(steamID));
            GetTeamName(GetClientTeam(attacker), team, sizeof(team));
            GetClientWeapon(attacker, attacker_weapon, sizeof(attacker_weapon));
            health=GetClientHealth(attacker);
        }
        else
            strcopy(steamID,sizeof(steamID), "World");

        decl String:victimID[64];
        GetClientAuthString(victim,victimID,sizeof(victimID));

        decl String:victimTeam[64];
        GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

        new victimHealth=GetClientHealth(victim);

        decl String:event_weapon[64];
        GetEventString(event,"weapon",event_weapon,sizeof(event_weapon));

        new event_damage = GetEventInt(event, "damage");

        if (assister)
        {
            decl String:assisterID[64];
            GetClientAuthString(assister,assisterID,63);

            decl String:assisterTeam[64];
            GetTeamName(GetClientTeam(assister), assisterTeam, sizeof(assisterTeam));

            decl String:assister_weapon[64];
            GetClientWeapon(assister, assister_weapon, sizeof(assister_weapon));

            new assisterHealth=GetClientHealth(assister);

            LogMessage("[%s] \"%N<%d><%s><%s>[%d]\"+\"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s+%s)",
                       source, attacker, attacker, steamID, team, health,
                       assister, assister,assisterID, assisterTeam, assisterHealth,
                       victim, victim, victimID, victimTeam, victimHealth,
                       damage, event_damage, event_weapon, attacker_weapon, assister_weapon);

            LogToGame("[%s] \"%N<%d><%s><%s>[%d]\"+\"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s+%s)",
                      source, attacker, attacker, steamID, team, health,
                      assister, assister,assisterID, assisterTeam, assisterHealth,
                      victim, victim, victimID, victimTeam, victimHealth,
                      damage, event_damage, event_weapon, attacker_weapon, assister_weapon);
        }
        else
        {
            LogMessage("[%s] \"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s)",
                       source, attacker, attacker, steamID, team, health,
                       victim, victim, victimID, victimTeam, victimHealth,
                       damage, event_damage, event_weapon, attacker_weapon);
            LogToGame("[%s] \"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s)\n",
                      source, attacker, attacker, steamID, team, health,
                      victim, victim, victimID, victimTeam, victimHealth,
                      damage, event_damage, event_weapon, attacker_weapon);
        }
    }
}
