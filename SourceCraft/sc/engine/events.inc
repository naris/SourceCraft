/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: events.inc
 * Description: The handler for all the source engine event based stuff.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

bool:HookEvents()
{
    if(!HookEventEx("player_spawn",PlayerSpawnEvent))
    {
        LogError("Could not hook the player_spawn event.");
        return false;
    }

    if(!HookEventEx("player_hurt",PlayerHurtEvent))
    {
        LogError("Could not hook the player_hurt event.");
        return false;
    }

    if(!HookEventEx("player_death",PlayerDeathEvent))
    {
        LogError("Could not hook the player_spawn event.");
        return false;
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
            if (g_RoundActive)
            {
                new Float:maxSpeed = GetEntDataFloat(index,m_OffsetMaxSpeed);
                m_BaseSpeed[index] = maxSpeed;

                //LogMessage("[PlayerSpawnEvent] Set BaseSpeed of %N to %f, maxSpeed=%f, classSpeed=%f",
                //           index, m_BaseSpeed[index], maxSpeed, GetClassSpeed(index));
                }
            }

        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
        {
            PendingCheck(index,playerHandle);
            PrintToChat(index, "This is a Test of the SourceCraft Beta");
            ShowXP(index,playerHandle);
            ShowCredits(index,playerHandle);
            PrintToChat(index, "Please report any bugs in the forums of www.jigglysfunhouse.net");
            new race=GetRace(playerHandle);
            if (m_FirstSpawn[index])
                IntroMenu(index);
            else if (GetUpgradeLevelCount(playerHandle,race)<GetLevel(playerHandle,race))
                UpgradeMenu(index, playerHandle);
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
        new Handle:victim_player=GetPlayerHandle(victim_index);
        new victim_race=(victim_player != INVALID_HANDLE) ? GetRace(victim_player) : -1;

        new attacker_userid=GetEventInt(event,"attacker");
        new attacker_index=GetClientOfUserId(attacker_userid);
        new Handle:attacker_player=(attacker_index) ? GetPlayerHandle(attacker_index) : INVALID_HANDLE;
        new attacker_race=(attacker_player != INVALID_HANDLE) ? GetRace(attacker_player) : -1;

        new assister_userid=GetEventInt(event,"assister");
        new assister_index=GetClientOfUserId(assister_userid);
        new Handle:assister_player=(assister_index) ? GetPlayerHandle(assister_index) : INVALID_HANDLE;
        new assister_race=(assister_player != INVALID_HANDLE) ? GetRace(assister_player) : -1;

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
    new Action:result = Plugin_Continue;

    new victim_userid=GetEventInt(event,"userid");
    new victim_index=GetClientOfUserId(victim_userid);
    if (victim_index)
    {
        new customkill;
        new bool:backstab;
        new bool:headshot;

        new Handle:victim_player=GetPlayerHandle(victim_index);
        new victim_race=(victim_player != INVALID_HANDLE) ? GetRace(victim_player) : -1;

        new attacker_userid=GetEventInt(event,"attacker");
        new attacker_index=GetClientOfUserId(attacker_userid);
        new Handle:attacker_player=(attacker_index) ? GetPlayerHandle(attacker_index) : INVALID_HANDLE;
        new attacker_race=(attacker_player != INVALID_HANDLE) ? GetRace(attacker_player) : -1;
        new bool:attacker_dominated=bool:GetEventInt(event,"dominated");
        new bool:attacker_revenge=bool:GetEventInt(event,"revenge");

        new assister_userid=GetEventInt(event,"assister");
        new assister_index=GetClientOfUserId(assister_userid);
        new Handle:assister_player=(assister_index) ? GetPlayerHandle(assister_index) : INVALID_HANDLE;
        new assister_race=(assister_player != INVALID_HANDLE) ? GetRace(assister_player) : -1;
        new bool:assister_dominated=bool:GetEventInt(event,"assister_dominated");
        new bool:assister_revenge=bool:GetEventInt(event,"assister_revenge");

        decl String:weapon[64];
        new bool:is_equipment = GetWeapon(event, attacker_index,
                                          weapon, sizeof(weapon));

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

        new damage     = GetDamage(event, victim_index);
        new bool:melee = backstab || IsMelee(weapon, is_equipment,
                                             attacker_index, victim_index);

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

        if (attacker_index)
        {
            if (attacker_player != INVALID_HANDLE &&
                attacker_userid != victim_userid)
            {
                if (GetClientTeam(attacker_index) != GetClientTeam(victim_index))
                {
                    GiveKillCredits(attacker_index,attacker_player);
                    GiveKillXP(attacker_index,attacker_player,
                               victim_player,headshot,backstab,melee,
                               attacker_dominated,attacker_revenge,false);
                }
            }
            SaveHealth(attacker_index);
        }

        if (assister_index)
        {
            if (assister_player != INVALID_HANDLE &&
                assister_userid != victim_userid)
            {
                if (GetClientTeam(assister_index) != GetClientTeam(victim_index))
                {
                    GiveKillCredits(assister_index,assister_player);
                    GiveKillXP(assister_index,assister_player,
                               victim_player,headshot,backstab,melee,
                               assister_dominated,assister_revenge,true);
                }
            }
            SaveHealth(assister_index);
        }

        if (victim_index)
        {
            if (victim_player != INVALID_HANDLE)
            {
                PendingCheck(victim_index,victim_player);
                new race=GetRace(victim_player);
                if(GetUpgradeLevelCount(victim_player,race)<GetLevel(victim_player,race))
                    UpgradeMenu(victim_index, victim_player);
            }
            SaveHealth(victim_index);
        }
    }
    return result;
}
