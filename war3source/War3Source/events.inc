/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: events.inc
 * Description: The handler for all the source engine event based stuff.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

public bool:War3Source_HookEvents()
{
    if(!HookEventEx("player_spawn",War3Source_PlayerSpawnEvent))
    {
        PrintToServer("[War3Source] Could not hook the player_spawn event.");
        return false;
    }
    if(!HookEventEx("player_death",War3Source_PlayerDeathEvent))
    {
        PrintToServer("[War3Source] Could not hook the player_spawn event.");
        return false;
    }

    return true;
}

public War3Source_PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
        {
            War3Source_PendingCheck(index,vecpos);
            ShowXP(index,vecpos);
            new race=GetRace(vecpos);
            if(m_FirstSpawn[index])
            {
                War3Source_IntroMenu(index);
                m_FirstSpawn[index]=false;
            }
            if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                War3Source_SkillMenu(index,vecpos);
        }
    }
}

public War3Source_PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new uid_victim=GetEventInt(event,"userid");
    new uid_attacker=GetEventInt(event,"attacker");
    if(uid_victim > 0)
    {
        new victimIndex=GetClientOfUserId(uid_victim);
        new vecposvictim=GetClientVectorPosition(victimIndex);
        if(vecposvictim!=-1)
        {
            War3Source_PendingCheck(victimIndex,vecposvictim);
            new race=GetRace(vecposvictim);
            if(GetSkillCount(vecposvictim,race)<GetLevel(vecposvictim,race))
                War3Source_SkillMenu(victimIndex,vecposvictim);
        }
    }
    if(uid_victim != uid_attacker && uid_attacker > 0)
    {
        new attackerIndex=GetClientOfUserId(uid_attacker);
        new victimIndex=GetClientOfUserId(uid_victim);
        new vecPos=GetClientVectorPosition(attackerIndex);
        if(vecPos != -1 && GetClientTeam(attackerIndex) != GetClientTeam(victimIndex))
        {
            decl String:weapon[64];
            GetEventString(event,"weapon",weapon,63);
            GiveKillXP(attackerIndex,vecPos,victimIndex,GetEventBool(event,"headshot"),StrEqual(weapon,"knife"));
            GiveKillCredits(attackerIndex,vecPos);
        }
    }
}
