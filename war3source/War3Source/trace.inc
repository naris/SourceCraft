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

stock bool:TraceTarget(client, target, const Float:clientLoc[3], const Float:targetLoc[3])
{
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

public bool:TraceRayFilterIndex(entity,mask)
{
  return (entity != g_TraceFilterIndex);
}
