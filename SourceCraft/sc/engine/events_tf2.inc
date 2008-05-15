/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: events_tf2.inc
 * Description: The handler for all the Team Fortress event based stuff.
 * Author(s): Naris (Murray Wilson)
 */

new Handle:m_ObjectKilledRegex = INVALID_HANDLE;

bool:HookTFEvents()
{
    if(!HookEvent("player_chargedeployed", PlayerChargeDeployed))
    {
        LogError("Could not hook the player_chargedeployed event.");
        return false;
    }

    if(!HookEvent("player_builtobject", PlayerBuiltObject))
    {
        LogError("Could not hook the player_builtobject event.");
        return false;
    }

    if(!HookEvent("object_destroyed", EventObjectDestroyed))
    {
        LogError("Could not hook the object_destroyed event.");
        return false;
    }

    if(!HookEvent("teamplay_flag_event", EventFlagEvent))
    {
        LogError("Could not hook the teamplay_flag_event.");
        return false;
    }

    if(!HookEvent("teamplay_point_captured", EventPointCapture))
    {
        LogError("Could not hook the teampoint_point_captured event.");
        return false;
    }

    if(!HookEvent("teamplay_point_startcapture", EventPointCapture))
    {
        LogError("Could not hook the teampoint_point_captured event.");
        return false;
    }

    if(!HookEvent("teamplay_capture_blocked", EventCaptureBlocked))
    {
        LogError("Could not hook the teadmplay_capture_blocked event.");
        return false;
    }

    if(!HookEventEx("teamplay_round_start",RoundStart,EventHookMode_PostNoCopy))
    {
        LogError("Could not hook the teamplay_round_start event.");
        return false;
    }

    if(!HookEventEx("teamplay_round_active",RoundActive,EventHookMode_PostNoCopy))
    {
        LogError("Could not hook the teamplay_round_active event.");
        return false;
    }

    if(!HookEventEx("teamplay_round_win",RoundWin))
    {
        LogError("Could not hook the teamplay_round_win event.");
        return false;
    }

    if(!HookEventEx("teamplay_round_stalemate",RoundOver,EventHookMode_PostNoCopy))
    {
        LogError("Could not hook the teamplay_round_stalemate event.");
        return false;
    }

    if(!HookEventEx("teamplay_win_panel",GameWin))
    {
        LogError("Could not hook the teamplay_win_panel event.");
        return false;
    }

    if(!HookEventEx("tf_game_over",GameOver))
    {
        LogError("Could not hook the tf_game_over event.");
        return false;
    }

    if(!HookEventEx("teamplay_game_over",GameOver))
    {
        LogError("Could not hook the teamplay_game_over event.");
        return false;
    }

    if(!HookEventEx("achievement_earned",LogEvent))
    {
        LogError("Could not hook the achievement_earned event.");
    }

    if(!HookEventEx("player_invulned",LogEvent))
    {
        LogError("Could not hook the player_invulned event.");
    }

    if(!HookEventEx("player_extinguished",LogEvent))
    {
        LogError("Could not hook the player_extinguished event.");
    }

    if(!HookEventEx("teamplay_waiting_begins",LogEvent))
    {
        LogError("Could not hook the teamplay_game_over event.");
    }

    if(!HookEventEx("teamplay_waiting_ends",LogEvent))
    {
        LogError("Could not hook the teamplay_game_over event.");
    }

    if(!HookEventEx("player_escort_score",LogEvent))
    {
        LogError("Could not hook the player_escort_score event.");
    }

    if(!HookEventEx("escort_progress",LogEvent))
    {
        LogError("Could not hook the escort_progress event.");
    }

    if(!HookEventEx("escort_recede",LogEvent))
    {
        LogError("Could not hook the escort_recede event.");
    }

    if(!HookEventEx("escort_speed",LogEvent))
    {
        LogError("Could not hook the escort_speed event.");
    }

    if(!HookEventEx("player_healedmediccall",LogEvent))
    {
        LogError("Could not hook the player_healedmediccall event.");
    }

    if(!HookEventEx("player_ignited_inv",LogEvent))
    {
        LogError("Could not hook the player_ignited_inv event.");
    }

    if(!HookEventEx("player_calledformedic",LogEvent))
    {
        LogError("Could not hook the player_calledformedic event.");
    }   

    AddGameLogHook(LogScanner);

    return true;
}

public PlayerChargeDeployed(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
        {
            GiveChargeDeployedXP(index,playerHandle);
            GiveChargeDeployedCredits(index,playerHandle);
        }
    }
}

public PlayerBuiltObject(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
        {
            GiveObjectBuiltXP(index,playerHandle,
                              objects:GetEventInt(event,"object"));
        }
    }
}

public EventObjectDestroyed(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    new index  = GetClientOfUserId(userid);
    new objects:object = objects:GetEventInt(event,"objecttype");

    new attacker = GetEventInt(event,"attacker");
    if (attacker > 0 && attacker != userid)
    {
        new attacker_index=GetClientOfUserId(attacker);
        new Handle:attacker_player=GetPlayerHandle(attacker_index);
        if (attacker_player != INVALID_HANDLE)
            GiveObjectDestroyedXP(attacker_index,attacker_player,object);
    }
    else
    {
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
            TakeObjectBuiltXP(index,playerHandle,object);
    }

    new assister = GetEventInt(event,"assister");
    if (assister> 0 && assister != userid)
    {
        new assister_index=GetClientOfUserId(assister);
        new Handle:assister_player=GetPlayerHandle(assister_index);
        if (assister_player != INVALID_HANDLE)
            GiveObjectDestroyedXP(assister_index,assister_player,object);
    }
}

public EventFlagEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new player=GetEventInt(event,"player");
    if (player>0)
    {
        new eventtype = GetEventInt(event,"eventtype");
        if (eventtype == 2) // Flag Captured
        {
            new Handle:playerHandle=GetPlayerHandle(player);
            if (playerHandle != INVALID_HANDLE)
                GiveFlagCapturedXP(player,playerHandle);
        }
        else if (eventtype == 1) // Flag Picked Up
        {
            new Handle:playerHandle=GetPlayerHandle(player);
            if (playerHandle != INVALID_HANDLE)
                GivePickedUpFlagCredits(player,playerHandle);
        }
        else if (eventtype == 4) // Flag Dropped
        {
            new Handle:playerHandle=GetPlayerHandle(player);
            if (playerHandle != INVALID_HANDLE)
                TakeDroppedFlagCredits(player,playerHandle);
        }
    }
}

public EventPointCapture(Handle:event,const String:name[],bool:dontBroadcast)
{
    decl String:cappers[MAXPLAYERS+1];
    if (GetEventString(event,"cappers", cappers, MAXPLAYERS)>0)
    {
        new bool:captured = StrEqual(name, "teamplay_point_captured");
        //new bool:startcap = StrEqual(name, "teamplay_point_startcapture");
        new len = strlen(cappers);
        for(new i=0;i<len;i++)
        {
            new index = cappers{i};
            new Handle:playerHandle=GetPlayerHandle(index);
            if (playerHandle != INVALID_HANDLE)
            {
                if (captured)
                {
                    GivePointCapturedXP(index,playerHandle);
                    GivePointCapturedCredits(index,playerHandle);
                }
                else // if (startcap)
                {
                    GivePointTouchedCredits(index,playerHandle);
                }
            }
        }
    }
}

public EventCaptureBlocked(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index=GetEventInt(event,"blocker");
    if (index > 0)
    {
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
            GiveCaptureBlockedXP(index,playerHandle);
    }
}

public RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundActive = false;
}

public RoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundActive = false;
}

public RoundActive(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundActive = true;
}

public RoundWin(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundActive = false;

    new team  = GetEventInt(event,"team");
    new count = GetClientCount();
    for(new index=1;index<=count;index++)
    {
        if (IsClientInGame(index) && IsPlayerAlive(index) &&
            GetClientTeam(index) == team)
        {
            new Handle:playerHandle=GetPlayerHandle(index);
            if (playerHandle != INVALID_HANDLE)
            {
                GiveRoundWinCredits(index,playerHandle);
                GiveRoundWinXP(index,playerHandle);
            }
        }
    }

    //if (DBIDB && SAVE_ENABLED)
    //    SaveAllPlayersData();
}

public GameWin(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundActive = false;

    new team  = GetEventInt(event,"winning_team");
    new score = (team == 2) ? GetEventInt(event,"blue_score")
                            : GetEventInt(event,"red_score");

    new count = GetClientCount();
    for(new index=1;index<=count;index++)
    {
        if (IsClientInGame(index) && IsPlayerAlive(index) &&
            GetClientTeam(index) == team)
        {
            new Handle:playerHandle=GetPlayerHandle(index);
            if (playerHandle != INVALID_HANDLE)
            {
                GiveGameWinCredits(index,playerHandle,score);
                GiveGameWinXP(index,playerHandle,score);
            }
        }
    }

    new index = GetEventInt(event, "player_1");
    if (index)
    {
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
        {
            new points = GetEventInt(event,"player_1_points");
            GiveMvpCredits(index,playerHandle,1,points);
            GiveMvpXP(index,playerHandle,1,points);
        }
    }

    index = GetEventInt(event, "player_2");
    if (index)
    {
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
        {
            new points = GetEventInt(event,"player_2_points");
            GiveMvpCredits(index,playerHandle,2,points);
            GiveMvpXP(index,playerHandle,2,points);
        }
    }

    index = GetEventInt(event, "player_3");
    if (index)
    {
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
        {
            new points = GetEventInt(event,"player_3_points");
            GiveMvpCredits(index,playerHandle,3,points);
            GiveMvpXP(index,playerHandle,3,points);
        }
    }

    //if (DBIDB && SAVE_ENABLED)
    //    SaveAllPlayersData();
}

public GameOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    LogMessage("GameOver(%s)", name);
    g_RoundActive = false;
    g_MapChanging = true;
}

public LogEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new player=GetEventInt(event,"userid");
    LogMessage("LogEvent(%s), userid=%d, player=%d", name, userid, player);
}

public Action:LogScanner(const String:message[])
{
    decl String:buffer[5];
    decl String:object[64];

    new attacker = 0;
    new builder = 0;
    new result;

    if (m_ObjectKilledRegex == INVALID_HANDLE)
        m_ObjectKilledRegex = CompileRegex("\".+<([0-9]+)><.+><.+>.*\".* triggered \"killedobject\" .object \"([[:word:]]+)\". .*objectowner \".+<([0-9]+)><.+>\"");

    if (MatchRegex(m_ObjectKilledRegex, message))
    {
        if (GetRegexSubString(m_ObjectKilledRegex, 1, buffer, sizeof(buffer)))
        {
            attacker = GetClientOfUserId(StringToInt(buffer));
            if (GetRegexSubString(m_ObjectKilledRegex, 2, object, sizeof(object)))
            {
                if (GetRegexSubString(m_ObjectKilledRegex, 3, buffer, sizeof(buffer)))
                    builder = GetClientOfUserId(StringToInt(buffer));
            }
            else
                object[0] = 0;
        }

        new objects:type = unknown;
        if (StrEqual(object, "OBJ_SENTRYGUN", false))
            type = sentrygun;
        else if (StrEqual(object, "OBJ_DISPENSER", false))
            type = dispenser;
        else if (StrEqual(object, "OBJ_TELEPORTER_ENTRANCE", false))
            type = teleporter_entry;
        else if (StrEqual(object, "OBJ_TELEPORTER_EXIT", false))
            type = teleporter_exit;
        else if (StrEqual(object, "OBJ_SAPPER", false))
            type = teleporter_exit;

        if (attacker && attacker == builder)
        {
            new Handle:playerHandle=GetPlayerHandle(builder);
            if (playerHandle != INVALID_HANDLE)
                TakeObjectBuiltXP(builder, playerHandle,type);
        }

        Call_StartForward(g_OnObjectKilledHandle);
        Call_PushCell(attacker);
        Call_PushCell(builder);
        Call_PushCell(type);
        Call_Finish(result);
    }
}
