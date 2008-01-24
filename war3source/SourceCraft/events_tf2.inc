/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: events_tf2.inc
 * Description: The handler for all the Team Fortress event based stuff.
 * Author(s): Naris (Murray Wilson)
 */

public bool:HookTFEvents()
{
    if(!HookEvent("player_builtobject", EventObjectBuilt))
    {
        PrintToServer("[SourceCraft] Could not hook the player_builtobject event.");
        return false;
    }
    if(!HookEvent("object_destroyed", EventObjectDestroyed))
    {
        PrintToServer("[SourceCraft] Could not hook the object_destroyed event.");
        return false;
    }
    if(!HookEvent("teamplay_flag_event", EventFlagEvent))
    {
        PrintToServer("[SourceCraft] Could not hook the teamplay_flag_event.");
        return false;
    }
    if(!HookEvent("teamplay_point_captured", EventPointCaptured))
    {
        PrintToServer("[SourceCraft] Could not hook the teampoint_point_captured event.");
        return false;
    }
    if(!HookEvent("teamplay_capture_blocked", EventCaptureBlocked))
    {
        PrintToServer("[SourceCraft] Could not hook the teadmplay_capture_blocked event.");
        return false;
    }

    /*
    if(!HookEvent("teamplay_round_win", RoundWin))
    {
        PrintToServer("[SourceCraft] Could not hook the teamplay_round_win event.");
        return false;
    }
    */

    return true;
}

public EventObjectBuilt(Handle:event,const String:name[],bool:dontBroadcast)
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
    new attacker = GetEventInt(event,"attacker");
    if (attacker > 0)
    {
        new index=GetClientOfUserId(attacker);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveObjectDestroyedXP(index,vecpos);
    }

    new assister = GetEventInt(event,"assister");
    if (assister> 0)
    {
        new index=GetClientOfUserId(assister);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveObjectDestroyedXP(index,vecpos);
    }
}

public EventFlagEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new player=GetEventInt(event,"player");
    if (player>0)
    {
        new eventtype = GetEventInt(event,"eventtype");
        if (eventtype == 2) // Point Captured
        {
            new vecpos=GetClientVectorPosition(player);
            if (vecpos!=-1)
                GiveFlagCapturedXP(player,vecpos);
        }
    }
}

public EventPointCaptured(Handle:event,const String:name[],bool:dontBroadcast)
{
    decl String:cappers[MAXPLAYERS+1] = "";
    if (GetEventString(event,"cappers", cappers, MAXPLAYERS)>0)
    {
        new len = strlen(cappers);
        for(new i=0;i<len;i++)
        {
            new index  = cappers{i};
            new vecpos = GetClientVectorPosition(index);
            if (vecpos != -1)
                GivePointCapturedXP(index,vecpos);
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
