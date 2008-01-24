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
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveDefuseXP(index,vecpos);
    }
}

public BombPlantedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GivePlantXP(index,vecpos);
    }
}

public HostageRescuedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveHostageRescuedXP(index,vecpos);
    }
}
