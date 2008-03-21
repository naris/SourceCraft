/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: trace.inc
 * Description: Trace Ray functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _trace_included
 #endinput
#endif
#define _trace_included

new g_TraceFilterIndex;

stock bool:TraceTarget(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
    clientLoc[2] += 50.0; // Adjust trace position to the middle
    targetLoc[2] += 50.0; // of the person instead of the feet.
    g_TraceFilterIndex = client;
    TR_TraceRayFilter(clientLoc,targetLoc,MASK_SOLID,RayType_EndPoint,TraceRayFilterIndex);
    return (TR_GetEntityIndex() == target);
}

stock TraceAimTarget(client)
{
    new Float:clientloc[3],Float:clientang[3];
    GetClientEyePosition(client,clientloc);
    GetClientEyeAngles(client,clientang);
    g_TraceFilterIndex = client;
    TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite, TraceRayFilterIndex);
    return TR_GetEntityIndex();
}

stock bool:TraceAimPosition(client, Float:destLoc[3], bool:hitPlayers)
{
    new Float:clientloc[3],Float:clientang[3];
    GetClientEyePosition(client,clientloc);
    GetClientEyeAngles(client,clientang);
    g_TraceFilterIndex = client;

    if (hitPlayers)
        TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite,
                          TraceRayFilterIndex);
    else
        TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite,
                          TraceRayTryToHit);

    TR_GetEndPosition(destLoc);
    return TR_DidHit();
}

/***************
 *Trace Filters*
****************/

public bool:TraceRayFilterIndex(entity,mask)
{
  // Check if the beam hit the originating client (g_TraceFilterIndex)
  // and tell it to keep tracing if it did
  return (entity != g_TraceFilterIndex);
}

public bool:TraceRayTryToHit(entity,mask)
{
  // Check if the beam hit a player and tell it to keep tracing if it did
  return (entity <= 0 || entity > GetMaxClients());
}
