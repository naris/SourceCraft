/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: events.inc
 * Description: The handler for all the source engine event based stuff.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

#include "SourceCraft/tf2classes"

public bool:HookEvents()
{
    if(!HookEventEx("player_spawn",PlayerSpawnEvent))
    {
        PrintToServer("[SourceCraft] Could not hook the player_spawn event.");
        return false;
    }
    if(!HookEventEx("player_death",PlayerDeathEvent))
    {
        PrintToServer("[SourceCraft] Could not hook the player_spawn event.");
        return false;
    }

    if (GameType == tf2)
    {
        if(!HookEventEx("player_changeclass",PlayerChangeClass))
        {
            PrintToServer("[SourceCraft] Could not hook the player_changeclass event.");
            return false;
        }

        if(!HookEventEx("teamplay_round_active",RoundActive))
        {
            PrintToServer("[SourceCraft] Could not hook the teamplay_round_active event.");
            return false;
        }

        if(!HookEventEx("teamplay_round_win",RoundOver))
        {
            PrintToServer("[SourceCraft] Could not hook the teamplay_round_active event.");
            return false;
        }

        if(!HookEventEx("teamplay_round_stalemate",RoundOver))
        {
            PrintToServer("[SourceCraft] Could not hook the teamplay_round_active event.");
            return false;
        }
    }

    return true;
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        if (index > 0)
        {
            speedAltered[index]=true;
            if(GameType == tf2)
                m_BaseSpeed[index]=GetNormalSpeed(index);
        }

        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
        {
            PendingCheck(index,vecpos);
            ShowXP(index,vecpos);
            ShowCredits(index,vecpos);
            new race=GetRace(vecpos);
            if (m_FirstSpawn[index])
                IntroMenu(index);
            else if (GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                SkillMenu(index, vecpos, INVALID_FUNCTION);
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new uid_victim=GetEventInt(event,"userid");
    new victimIndex=GetClientOfUserId(uid_victim);

    if(uid_victim > 0)
    {
        new vecposvictim=GetClientVectorPosition(victimIndex);
        if(vecposvictim!=-1)
        {
            PendingCheck(victimIndex,vecposvictim);
            new race=GetRace(vecposvictim);
            if(GetSkillCount(vecposvictim,race)<GetLevel(vecposvictim,race))
                SkillMenu(victimIndex, vecposvictim, INVALID_FUNCTION);
        }
    }

    new uid_attacker=GetEventInt(event,"attacker");
    if(uid_victim != uid_attacker && uid_attacker > 0)
    {
        new attackerIndex=GetClientOfUserId(uid_attacker);
        new vecPos=GetClientVectorPosition(attackerIndex);
        if(vecPos != -1 && GetClientTeam(attackerIndex) != GetClientTeam(victimIndex))
        {
            decl String:weapon[64];
            GetEventString(event,"weapon",weapon,63);
            if (!strlen(weapon))
                GetClientWeapon(attackerIndex, weapon, 63);

            new bool:backstab = false;
            new bool:headshot = false;
            new bool:melee    = false;
            if (GameType == cstrike)
            {
                headshot = GetEventBool(event,"headshot");
                melee    = StrEqual(weapon,"knife");
            }
            else if(GameType == tf2)
            {
                decl String:customkill[64];
                GetEventString(event,"customkill",customkill,63);

                headshot = StrEqual(customkill,"headshot");
                backstab = StrEqual(customkill,"backstab");
                melee    = (StrEqual(weapon,"knife") ||
                            StrEqual(weapon,"shovel") ||
                            StrEqual(weapon,"wrench") ||
                            StrEqual(weapon,"bat") ||
                            StrEqual(weapon,"bonesaw") ||
                            StrEqual(weapon,"bottle") ||
                            StrEqual(weapon,"club") ||
                            StrEqual(weapon,"fireaxe") ||
                            StrEqual(weapon,"fists"));
            }
            else if(GameType == dod)
            {
                headshot = GetEventBool(event,"headshot");
                melee    = (StrEqual(weapon,"amerknife") ||
                            StrEqual(weapon,"spade"));
            }

            GiveKillXP(attackerIndex,vecPos,victimIndex,headshot,melee,backstab);
            GiveKillCredits(attackerIndex,vecPos);
        }
    }

    new uid_assister=GetEventInt(event,"assister");
    if(uid_assister > 0)
    {
        new assisterIndex=GetClientOfUserId(uid_assister);
        new vecPos=GetClientVectorPosition(assisterIndex);
        if(vecPos != -1 && GetClientTeam(assisterIndex) != GetClientTeam(victimIndex))
        {
            GiveKillXP(assisterIndex,vecPos,victimIndex,false,false,false);
            GiveKillCredits(assisterIndex,vecPos);
        }
    }
}

public PlayerChangeClass(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client > 0)
    {
        new Float:maxSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed[client]);
        if (maxSpeed > 100)
        {
            speedAltered[client]=true;
            if(GameType == tf2)
                m_BaseSpeed[client]=GetNormalSpeed(client);
        }
    }
}

public RoundActive(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (GameType == tf2)
    {
        for(new x=0;x<GetArraySize(arrayPlayers);x++)
        {
            new Handle:playerHandle=GetArrayCell(arrayPlayers,x);
            new client=GetArrayCell(playerHandle,0);
            if(IsClientInGame(client))
            {
                speedAltered[client]=true;
                if(GameType == tf2)
                    m_BaseSpeed[client]=GetNormalSpeed(client);
            }
        }
    }
}

public RoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    /*
    new bool:saveEnabled = SAVE_ENABLED;
    if (GameType == tf2)
    {
        for(new x=0;x<GetArraySize(arrayPlayers);x++)
        {
            m_OffsetMaxSpeed[x]=0;
            new Handle:playerHandle=GetArrayCell(arrayPlayers,x);
            new client=GetArrayCell(playerHandle,0);
            if (saveEnabled && IsClientInGame(client))
                SavePlayerData(client,GetClientVectorPosition(client));
        }
    }
    */
}

public OnMapEnd()
{
    if (SAVE_ENABLED)
    {
        for(new x=0;x<GetArraySize(arrayPlayers);x++)
        {
            new Handle:playerHandle=GetArrayCell(arrayPlayers,x);
            new client=GetArrayCell(playerHandle,0);
            if (IsClientInGame(client))
                SavePlayerData(client,GetClientVectorPosition(client));
        }
    }
}
