/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: events_tf2.inc
 * Description: The handler for all the Team Fortress event based stuff.
 * Author(s): Naris (Murray Wilson)
 */

public bool:HookTFEvents()
{
    if(!HookEventEx("player_changeclass",PlayerChangeClass))
    {
        LogError("Could not hook the player_changeclass event.");
        return false;
    }

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
   
    if(!HookEvent("controlpoint_starttouch", DumpEvent))
    {
        LogError("Could not hook the controlpoint_starttouch event.");
    }

    if(!HookEvent("controlpoint_endtouch", DumpEvent))
    {
        LogError("Could not hook the controlpoint_endtouch event.");
    }

    if(!HookEvent("controlpoint_initialized", DumpEvent,EventHookMode_PostNoCopy))
    {
        LogError("Could not hook the controlpoint_initialized event.");
    }

    if(!HookEvent("controlpoint_updateimages", DumpEvent))
    {
        LogError("Could not hook the controlpoint_updateimages event.");
    }

    if(!HookEvent("controlpoint_updatelayout", DumpEvent))
    {
        LogError("Could not hook the controlpoint_updatelayout event.");
    }

    if(!HookEvent("controlpoint_updatecapping", DumpEvent))
    {
        LogError("Could not hook the controlpoint_updatecapping event.");
    }

    if(!HookEvent("controlpoint_updateowner", DumpEvent))
    {
        LogError("Could not hook the controlpoint_updateowner event.");
    }

    if(!HookEvent("controlpoint_pulse_element", DumpEvent))
    {
        LogError("Could not hook the controlpoint_pulse_element event.");
    }
 
    return true;
}

public PlayerChangeClass(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client))
    {
        if (g_RoundActive)
        {
            new Float:maxSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed);
            m_BaseSpeed[client]=maxSpeed;
            new Float:classSpeed=GetClassSpeed(client);
            new oldClass=GetClass(client);
            new newClass=GetEventInt(event,"class");
            LogMessage("[ChangeClass] Set BaseSpeed of %N(%d) to %f, maxSpeed=%f, classSpeed=%f, oldClass=%d, newClass=%d",
                       client, client, m_BaseSpeed[client], maxSpeed, classSpeed, oldClass ,newClass);
        }
    }
}

public PlayerChargeDeployed(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
        {
            GiveChargeDeployedXP(index,vecpos);
            GiveChargeDeployedCredits(index,vecpos);
        }
    }
}

public PlayerBuiltObject(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveObjectBuiltXP(index,vecpos);
    }
}

public EventObjectDestroyed(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    new index  = GetClientOfUserId(userid);

    new attacker = GetEventInt(event,"attacker");
    if (attacker > 0 && attacker != userid)
    {
        new attacker_index=GetClientOfUserId(attacker);
        new vecpos=GetClientVectorPosition(attacker_index);
        if(vecpos!=-1)
            GiveObjectDestroyedXP(attacker_index,vecpos);
    }
    else
    {
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            TakeObjectBuiltXP(index,vecpos);
    }

    new assister = GetEventInt(event,"assister");
    if (assister> 0 && assister != userid)
    {
        new assister_index=GetClientOfUserId(assister);
        new vecpos=GetClientVectorPosition(assister_index);
        if(vecpos!=-1)
            GiveObjectDestroyedXP(assister_index,vecpos);
    }

    decl String:weapon[64] = "";
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    LogMessage("%d+%d destroyed %N's %d with %s", attacker, assister, index,
               GetEventInt(event,"objecttype"), weapon);
}

public EventFlagEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new player=GetEventInt(event,"player");
    if (player>0)
    {
        new eventtype = GetEventInt(event,"eventtype");
        if (eventtype == 2) // Flag Captured
        {
            new vecpos=GetClientVectorPosition(player);
            if (vecpos!=-1)
                GiveFlagCapturedXP(player,vecpos);
        }
        else if (eventtype == 1) // Flag Picked Up
        {
            new vecpos=GetClientVectorPosition(player);
            if (vecpos!=-1)
                GivePickedUpFlagCredits(player,vecpos);
        }
    }
}

public EventPointCapture(Handle:event,const String:name[],bool:dontBroadcast)
{
    decl String:cappers[MAXPLAYERS+1] = "";
    if (GetEventString(event,"cappers", cappers, MAXPLAYERS)>0)
    {
        new bool:captured = StrEqual(name, "teamplay_point_captured");
        //new bool:startcap = StrEqual(name, "teamplay_point_startcapture");
        new len = strlen(cappers);
        for(new i=0;i<len;i++)
        {
            new index  = cappers{i};
            new vecpos = GetClientVectorPosition(index);
            if (vecpos != -1)
            {
                if (captured)
                {
                    GivePointCapturedXP(index,vecpos);
                    GivePointCapturedCredits(index,vecpos);
                }
                else // if (startcap)
                {
                    GivePointTouchedCredits(index,vecpos);
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
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveCaptureBlockedXP(index,vecpos);
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

    if (GameType == tf2)
    {
        for(new x=0;x<GetArraySize(arrayPlayers);x++)
        {
            new Handle:playerHandle=GetArrayCell(arrayPlayers,x);
            new client=GetArrayCell(playerHandle,0);
            if(IsClientInGame(client))
            {
                m_BaseSpeed[client]=GetEntDataFloat(client,m_OffsetMaxSpeed);
                LogMessage("[RoundActive] Set BaseSpeed of %n(%d) to %f, classSpeed=%f",
                           client, client, m_BaseSpeed[client],GetClassSpeed(client));
            }
        }
    }
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
            new vecpos=GetClientVectorPosition(index);
            if (vecpos>-1)
            {
                GiveRoundWinCredits(index,vecpos);
                GiveRoundWinXP(index,vecpos);
            }
        }
    }
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
            new vecpos=GetClientVectorPosition(index);
            if (vecpos>-1)
            {
                GiveGameWinCredits(index,vecpos,score);
                GiveGameWinXP(index,vecpos,score);
            }
        }
    }

    new index = GetEventInt(event, "player_1");
    if (index)
    {
        new vecpos=GetClientVectorPosition(index);
        if (vecpos>-1)
        {
            new points = GetEventInt(event,"player_1_points");
            GiveMvpCredits(index,vecpos,1,points);
            GiveMvpXP(index,vecpos,1,points);
        }
    }

    index = GetEventInt(event, "player_2");
    if (index)
    {
        new vecpos=GetClientVectorPosition(index);
        if (vecpos>-1)
        {
            new points = GetEventInt(event,"player_2_points");
            GiveMvpCredits(index,vecpos,2,points);
            GiveMvpXP(index,vecpos,2,points);
        }
    }

    index = GetEventInt(event, "player_3");
    if (index)
    {
        new vecpos=GetClientVectorPosition(index);
        if (vecpos>-1)
        {
            new points = GetEventInt(event,"player_3_points");
            GiveMvpCredits(index,vecpos,3,points);
            GiveMvpXP(index,vecpos,3,points);
        }
    }
}

