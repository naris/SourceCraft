/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: events.inc
 * Description: The handler for all the counter-strike event based stuff.
 * Author(s): Anthony Iacono  
 */

public bool:War3Source_HookCStrikeEvents()
{
    if(!HookEvent("object_destroyed", War3Source_EventObjectDestroyed))
    {
        PrintToServer("[War3Source] Could not hook the object_destroyed event.");
        return false;
    }
    if(!HookEvent("ctf_flag_captured", War3Source_EventFlagCaptured))
    {
        PrintToServer("[War3Source] Could not hook the ctf_flag_captured event.");
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
    if(!HookEvent("teamplay_round_win", War3Source_Eventteamplayroundwin))
    {
        PrintToServer("[War3Source] Could not hook the teamplay_round_win event.");
        return false;
    }

    return true;
}

public War3Source_EventObjectDestroyed(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveDefuseXP(index,vecpos);
    }
}

public War3Source_EventPointCaptured(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GivePlantXP(index,vecpos);
    }
}

public War3Source_EventCaptureBlocked(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveHostageRescuedXP(index,vecpos);
    }
}
