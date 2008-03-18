/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: eventsi_cstrike.inc
 * Description: The handler for all the counter-strike event based stuff.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

public bool:HookCStrikeEvents()
{
    if(!HookEventEx("bomb_defused",BombDefusedEvent))
    {
        PrintToServer("[SourceCraft] Could not hook the bomb_defused event.");
        return false;
    }
    if(!HookEventEx("bomb_planted",BombPlantedEvent))
    {
        PrintToServer("[SourceCraft] Could not hook the bomb_planted event.");
        return false;
    }
    if(!HookEventEx("hostage_rescued",HostageRescuedEvent))
    {
        PrintToServer("[SourceCraft] Could not hook the hostage_rescued event.");
        return false;
    }

    return true;
}

public BombDefusedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
            GiveDefuseXP(index,playerHandle);
    }
}

public BombPlantedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
            GivePlantXP(index,playerHandle);
    }
}

public HostageRescuedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new Handle:playerHandle=GetPlayerHandle(index);
        if (playerHandle != INVALID_HANDLE)
            GiveHostageRescuedXP(index,playerHandle);
    }
}
