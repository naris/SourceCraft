/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: events.inc
 * Description: The handler for all the source engine event based stuff.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

public bool:HookEvents()
{
    if(!HookEventEx("player_spawn",PlayerSpawnEvent,EventHookMode_Post))
    {
        LogError("Could not hook the player_spawn event.");
        return false;
    }

    if(!HookEventEx("player_hurt",PlayerHurtEvent,EventHookMode_Pre))
    {
        LogError("Could not hook the player_hurt event.");
        return false;
    }

    if(!HookEventEx("player_death",PlayerDeathEvent,EventHookMode_Pre))
    {
        LogError("Could not hook the player_spawn event.");
        return false;
    }

    if(!HookEventEx("player_shoot",DumpEvent,EventHookMode_Post))
    {
        LogError("Could not hook the player_shoot event.");
    }

    if(!HookEventEx("player_score",DumpEvent,EventHookMode_Post))
    {
        LogError("Could not hook the player_shoot event.");
    }

    if(!HookEventEx("player_team",DumpEvent,EventHookMode_Post))
    {
        LogError("Could not hook the player_team event.");
    }

    if(!HookEventEx("player_class",DumpEvent,EventHookMode_Post))
    {
        LogError("Could not hook the player_class event.");
    }

    if(!HookEventEx("team_score",DumpEvent,EventHookMode_Post))
    {
        LogError("Could not hook the team_score event.");
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

                LogMessage("[PlayerSpawnEvent] Set BaseSpeed of %N to %f, maxSpeed=%f, classSpeed=%f",
                           index, m_BaseSpeed[index], maxSpeed, GetClassSpeed(index));
                }
            }

        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
        {
            PendingCheck(index,vecpos);
            PrintToChat(index, "This is a Test of the SourceCraft Beta");
            ShowXP(index,vecpos);
            ShowCredits(index,vecpos);
            PrintToChat(index, "Please report any bugs in the forums of www.jigglysfunhouse.net");
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

    if (!GetEventBool(event, "from_sourcecraft"))
    {
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

            //LogEventDamage(event, damage, "PlayerHurtEvent", -1);

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
    }
    return result;
}

public Action:PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new Action:result = Plugin_Continue;

    if (!GetEventBool(event, "from_sourcecraft"))
    {
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
            new attacker_player=(attacker_index) ? GetClientVectorPosition(attacker_index) : -1;
            new attacker_race=(attacker_player != -1) ? GetRace(attacker_player) : -1;
            new bool:attacker_dominated=bool:GetEventInt(event,"dominated");
            new bool:attacker_revenge=bool:GetEventInt(event,"revenge");

            LogMessage("attacker: userid=%d, index=%d, player=%d, race=%d, dom=%d, rev=%d",
                       attacker_userid, attacker_index, attacker_player, attacker_race, attacker_dominated, attacker_revenge);

            new assister_userid=GetEventInt(event,"assister");
            new assister_index=GetClientOfUserId(assister_userid);
            new assister_player=(assister_index) ? GetClientVectorPosition(assister_index) : -1;
            new assister_race=(assister_player != -1) ? GetRace(assister_player) : -1;
            new bool:assister_dominated=bool:GetEventInt(event,"assister_dominated");
            new bool:assister_revenge=bool:GetEventInt(event,"assister_revenge");

            LogMessage("assister: userid=%d, index=%d, player=%d, race=%d, dom=%d, rev=%d",
                       assister_userid, assister_index, assister_player, assister_race, assister_dominated, assister_revenge);

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

            LogEventDamage(event, damage, "PlayerDeathEvent", -1);

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
                if (attacker_player != -1 && attacker_userid != victim_userid)
                {
                    if (GetClientTeam(attacker_index) != GetClientTeam(victim_index))
                    {
                        GiveKillCredits(attacker_index,attacker_player);
                        GiveKillXP(attacker_index,attacker_player,victim_index,
                                   headshot,backstab,melee,attacker_dominated,
                                   attacker_revenge,false);
                    }
                }
                SaveHealth(attacker_index);
            }

            if (assister_index)
            {
                if (assister_player != -1 && assister_userid != victim_userid)
                {
                    if (GetClientTeam(assister_index) != GetClientTeam(victim_index))
                    {
                        GiveKillCredits(assister_index,assister_player);
                        GiveKillXP(assister_index,assister_player,victim_index,
                                   headshot,backstab,melee,assister_dominated,
                                   assister_revenge,true);
                    }
                }
                SaveHealth(assister_index);
            }

            if (victim_index)
            {
                if (victim_player!=-1)
                {
                    PendingCheck(victim_index,victim_player);
                    new race=GetRace(victim_player);
                    if(GetSkillCount(victim_player,race)<GetLevel(victim_player,race))
                        SkillMenu(victim_index, victim_player, INVALID_FUNCTION);
                }
                SaveHealth(victim_index);
            }
        }
    }
    return result;
}

public OnMapEnd()
{
    if (SAVE_ENABLED)
    {
        for(new x=0;x<GetArraySize(arrayPlayers);x++)
        {
            new client=GetClientIndex(x);
            if (IsClientInGame(client))
                SavePlayerData(client,x);
        }
    }
}

public DumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new player = GetEventInt(event, "player");
    new index = GetEventInt(event, "index");
    new area = GetEventInt(event, "area");

    new userid = GetEventInt(event, "userid");
    new teamid = GetEventInt(event, "teamid");
    new score = GetEventInt(event, "score");

    LogMessage("Event %s, player=%d, area=%d, index=%d, userid=%d, teamid=%d, score=%d",
               name, player, area, index, userid, teamid, score);
    /*
    if (player && IsClientInGame(player))
        PrintToChat(player, "Event %s, player=%d, area=%d, index=%d, userid=%d, teamid=%d, score=%d",
                    name, player, area, index, userid, teamid, score);

    if (userid && IsClientInGame(userid))
        PrintToChat(userid, "Event %s, player=%d, area=%d, index=%d, userid=%d, teamid=%d, score=%d",
                    name, player, area, index, userid, teamid, score);

    new client=1;
    if (client != player && IsClientInGame(client))
        PrintToChat(client, "Event %s, player=%d, area=%d, index=%d, userid=%d, teamid=%d, score=%d",
                    name, player, area, index, userid, teamid, score);
    */               
}

