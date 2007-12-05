/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: events.inc
 * Description: The handler for all the counter-strike event based stuff.
 * Author(s): Anthony Iacono  
 */

public bool:War3Source_HookCStrikeEvents()
{
    if(!HookEventEx("bomb_defused",War3Source_BombDefusedEvent))
    {
        PrintToServer("[War3Source] Could not hook the bomb_defused event.");
        return false;
    }
    if(!HookEventEx("bomb_planted",War3Source_BombPlantedEvent))
    {
        PrintToServer("[War3Source] Could not hook the bomb_planted event.");
        return false;
    }
    if(!HookEventEx("hostage_rescued",War3Source_HostageRescuedEvent))
    {
        PrintToServer("[War3Source] Could not hook the hostage_rescued event.");
        return false;
    }

    return true;
}

public War3Source_BombDefusedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveDefuseXP(index,vecpos);
    }
}

public War3Source_BombPlantedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GivePlantXP(index,vecpos);
    }
}

public War3Source_HostageRescuedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new index=GetClientOfUserId(GetEventInt(event,"userid"));
        new vecpos=GetClientVectorPosition(index);
        if(vecpos!=-1)
            GiveHostageRescuedXP(index,vecpos);
    }
}
