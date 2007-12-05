/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: events.inc
 * Description: The handler for all the counter-strike event based stuff.
 * Author(s): Anthony Iacono  
 */

public bool:War3Source_HookTFEvents()
{
    if(!HookEvent("player_builtobject", War3Source_EventObjectBuilt))
    {
        PrintToServer("[War3Source] Could not hook the player_builtobject event.");
        return false;
    }
    if(!HookEvent("object_destroyed", War3Source_EventObjectDestroyed))
    {
        PrintToServer("[War3Source] Could not hook the object_destroyed event.");
        return false;
    }
    if(!HookEvent("teamplay_flag_event", War3Source_EventFlagEvent))
    {
        PrintToServer("[War3Source] Could not hook the teamplay_flag_event.");
        return false;
    }
    if(!HookEvent("teamplay_point_captured", War3Source_EventPointCaptured))
    {
        PrintToServer("[War3Source] Could not hook the teampoint_point_captured event.");
        return false;
    }
    if(!HookEvent("teamplay_capture_blocked", War3Source_EventCaptureBlocked))
    {
        PrintToServer("[War3Source] Could not hook the teadmplay_capture_blocked event.");
        return false;
    }

    /*
    if(!HookEvent("teamplay_round_win", War3Source_RoundWin))
    {
        PrintToServer("[War3Source] Could not hook the teamplay_round_win event.");
        return false;
    }
    */

    return true;
}

public War3Source_EventObjectBuilt(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveObjectDestroyedXP(index,vecpos);
    }
}

public War3Source_EventObjectDestroyed(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveObjectDestroyedXP(index,vecpos);
    }
}

public War3Source_EventFlagEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        if (GetEventInt(event,"eventtype") == 2) // Point Captured
        {
            new index=GetClientOfUserId(GetEventInt(event,"userid"));
            new vecpos=GetClientVectorPosition(index);
            if (vecpos!=-1)
                GiveFlagCapturedXP(index,vecpos);
        }
    }
}

public War3Source_EventPointCaptured(Handle:event,const String:name[],bool:dontBroadcast)
{
    /* Need to add code here */
    /*
    if (GetEventString(event,"cappers")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GivePointCapturedXP(index,vecpos);
    }
    */
}

public War3Source_EventCaptureBlocked(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index=GetEventInt(event,"blocker");
    if (index > 0)
    {
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveCaptureBlockedXP(index,vecpos);
    }
}
