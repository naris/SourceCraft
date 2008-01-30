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
    if(!HookEventEx("player_hurt",PlayerHurtEvent))
    {
        PrintToServer("[SourceCraft] Could not hook the player_hurt event.");
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
            if (m_OffsetMaxSpeed[index] == 0)
                m_OffsetMaxSpeed[index]=FindDataMapOffs(index,"m_flMaxspeed");

            new Float:maxSpeed = GetEntDataFloat(index,m_OffsetMaxSpeed[index]);
            m_BaseSpeed[index]=maxSpeed;

            LogMessage("[PlayerSpawnEvent] Set BaseSpeed of %N to %f, maxSpeed=%f, classSpeed=%f\n",
                       index, m_BaseSpeed[index], maxSpeed, GetNormalSpeed(index));
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

public Action:PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new Action:result=Plugin_Continue;

    new victim_userid=GetEventInt(event,"userid");
    new victim_index=GetClientOfUserId(victim_userid);
    if (victim_index)
    {
        new victim_player=GetClientVectorPosition(victim_index);
        new victim_race=(victim_player > -1) ? GetRace(victim_player) : -1;

        new attacker_userid=GetEventInt(event,"attacker");
        new attacker_index=GetClientOfUserId(attacker_userid);
        new attacker_player=(attacker_index) ? GetClientVectorPosition(attacker_index) : -1;
        new attacker_race=(attacker_player != -1) ? GetRace(attacker_player) : -1;

        new assister_userid=GetEventInt(event,"assister");
        new assister_index=GetClientOfUserId(assister_userid);
        new assister_player=(assister_index) ? GetClientVectorPosition(assister_index) : -1;
        new assister_race=(assister_player != -1) ? GetRace(assister_player) : -1;

        new damage=GetDamage(event, victim_index);

        Call_StartForward(g_OnPlayerHurtEventHandle);
        Call_PushCell(event);
        Call_PushCell(victim_index);
        Call_PushCell(victim_player);
        Call_PushCell(victim_race);
        Call_PushCell(attacker_index);
        Call_PushCell(attacker_player);
        Call_PushCell(attacker_race);
        Call_PushCell(assister_index);
        Call_PushCell(assister_player);
        Call_PushCell(assister_race);
        Call_PushCell(damage);
        Call_Finish(result);

        SaveHealth(victim_index);

        if (attacker_index)
            SaveHealth(attacker_index);

        if (assister_index)
            SaveHealth(assister_index);
    }
    return result;
}

public Action:PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new Action:result       = Plugin_Continue;

    new victim_userid=GetEventInt(event,"userid");
    new victim_index=GetClientOfUserId(victim_userid);
    if (victim_index)
    {
        new customkill;
        new bool:backstab;
        new bool:headshot;

        new victim_player=GetClientVectorPosition(victim_index);
        new victim_race=(victim_player != -1) ? GetRace(victim_player) : -1;

        new attacker_userid=GetEventInt(event,"attacker");
        new attacker_index=GetClientOfUserId(attacker_userid);
        new attacker_player=(attacker_index) ? GetClientVectorPosition(attacker_index) : 0;
        new attacker_race=(attacker_player != -1) ? GetRace(attacker_player) : -1;

        new assister_userid=GetEventInt(event,"assister");
        new assister_index=GetClientOfUserId(assister_index);
        new assister_player=(assister_index) ? GetClientVectorPosition(assister_index) : -1;
        new assister_race=(assister_player != -1) ? GetRace(assister_player) : -1;

        new bool:is_equipment;
        decl String:weapon[64]  = "";
        GetWeapon(event, attacker_index, weapon, sizeof(weapon));

        if (GameType == cstrike)
        {
            headshot   = GetEventBool(event,"headshot");
            customkill = headshot ? 1 : 0;
            backstab   = false;
        }
        else if(GameType == dod)
        {
            headshot   = GetEventBool(event,"headshot");
            customkill = headshot ? 1 : 0;
            backstab   = false;
        }
        else if(GameType == tf2)
        {
            customkill = GetEventInt(event,"customkill");
            headshot   = (customkill == 1);
            backstab   = (customkill == 2);
        }

        new bool:melee = IsMelee(weapon, is_equipment);
        new damage     = GetDamage(event, victim_index);

        Call_StartForward(g_OnPlayerDeathEventHandle);
        Call_PushCell(event);
        Call_PushCell(victim_index);
        Call_PushCell(victim_player);
        Call_PushCell(victim_race);
        Call_PushCell(attacker_index);
        Call_PushCell(attacker_player);
        Call_PushCell(attacker_race);
        Call_PushCell(assister_index);
        Call_PushCell(assister_player);
        Call_PushCell(assister_race);
        Call_PushCell(damage);
        Call_PushString(weapon);
        Call_PushCell(is_equipment);
        Call_PushCell(customkill);
        Call_PushCell(headshot);
        Call_PushCell(backstab);
        Call_PushCell(melee);
        Call_Finish(result);

        if (attacker_userid != victim_userid && attacker_player != -1 && 
            GetClientTeam(attacker_index) != GetClientTeam(victim_index))
        {
            GiveKillCredits(attacker_index,attacker_player);
            GiveKillXP(attacker_index,attacker_player,victim_index,
                       headshot,backstab,melee,false);
        }

        if (assister_userid != victim_userid && assister_player != -1 && 
            GetClientTeam(assister_index) != GetClientTeam(victim_index))
        {
            GiveKillCredits(assister_index,assister_player);
            GiveKillXP(assister_index,assister_player,victim_index,
                       false,false,false,true);
        }

        if (victim_player!=-1)
        {
            PendingCheck(victim_index,victim_player);
            new race=GetRace(victim_player);
            if(GetSkillCount(victim_player,race)<GetLevel(victim_player,race))
                SkillMenu(victim_index, victim_player, INVALID_FUNCTION);
        }

        SaveHealth(victim_index);

        if (attacker_index)
            SaveHealth(attacker_index);

        if (assister_index)
            SaveHealth(assister_index);
    }
    return result;
}

public PlayerChangeClass(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client > 0)
    {
        m_OffsetMaxSpeed[client]=FindDataMapOffs(client,"m_flMaxspeed");
        new Float:maxSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed[client]);
        if (maxSpeed > 100)
        {
            m_BaseSpeed[client]=maxSpeed;
        }
        LogMessage("[ChangeClass] Set BaseSpeed of %N to %f, maxSpeed=%f, classSpeed=%f\n",
                   client, m_BaseSpeed[client],maxSpeed,GetNormalSpeed(client));
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
                m_OffsetMaxSpeed[client]=FindDataMapOffs(client,"m_flMaxspeed");
                m_BaseSpeed[client]=GetEntDataFloat(client,m_OffsetMaxSpeed[client]);
                LogMessage("[RoundActive] Set BaseSpeed of %N to %f, classSpeed=%f\n",
                           client, m_BaseSpeed[client],GetNormalSpeed(client));
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
