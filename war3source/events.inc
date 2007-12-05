/**
 * File: events.inc
 * Description: The handler for all the source engine event based stuff.
 * Author(s): Anthony Iacono  
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
    #if !defined BUILD_DOD
    if(!HookEventEx("bomb_defused",War3Source_BombDefusedEvent))
    {
        PrintToServer("[War3Source] Could not hook the bomb_defused event.");
        return false;
    }
    if(!HookEventEx("bomb_planted",War3Source_BombPlantedEvent))
    {
        PrintToServer("[War3Source] Could not hook the bomb_planted event.");
        return false;
    }
    if(!HookEventEx("hostage_rescued",War3Source_HostageRescuedEvent))
    {
        PrintToServer("[War3Source] Could not hook the hostage_rescued event.");
        return false;
    }
    #endif
    return true;
}

public War3Source_PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
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

#if !defined BUILD_DOD
public War3Source_BombDefusedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveDefuseXP(index,vecpos);
    }
}

public War3Source_BombPlantedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GivePlantXP(index,vecpos);
    }
}

public War3Source_HostageRescuedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveHostageRescuedXP(index,vecpos);
    }
}
#endif

public War3Source_PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new uid_victim=GetEventInt(event,"userid");
    new uid_attacker=GetEventInt(event,"attacker");
    if(uid_victim>0)
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
    if(uid_victim!=uid_attacker&&uid_attacker>0)
    {
        new attackerIndex=GetClientOfUserId(uid_attacker);
        new victimIndex=GetClientOfUserId(uid_victim);
        new vecPos=GetClientVectorPosition(attackerIndex);
        if(vecPos!=-1&&GetClientTeam(attackerIndex)!=GetClientTeam(victimIndex))
        {
            decl String:weapon[64];
            GetEventString(event,"weapon",weapon,63);
            GiveKillXP(attackerIndex,vecPos,victimIndex,GetEventBool(event,"headshot"),StrEqual(weapon,"knife"));
            GiveKillCredits(attackerIndex,vecPos);
        }
    }
}