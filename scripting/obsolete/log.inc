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

stock Log(const String:message[])
{
    LogMessage(message);
    PrintToServer(message);
}

stock Error(const String:message[])
{
    LogError(message);
    PrintToServer(message);
}

stock Fail(const String:message[])
{
    PrintToServer(message);
    SetFailState(message);
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
        decl String:team[64];
        decl String:steamID[64];
        decl String:attacker_weapon[64];
        if (attacker)
        {
            GetClientAuthString(attacker,steamID,sizeof(steamID));
            GetTeamName(GetClientTeam(attacker), team, sizeof(team));
            GetClientWeapon(attacker, attacker_weapon, sizeof(attacker_weapon));
            health=GetClientHealth(attacker);
        }
        else
        {
            team[0]=0;
            attacker_weapon[0]=0;
            strcopy(steamID,sizeof(steamID), "World");
        }

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
