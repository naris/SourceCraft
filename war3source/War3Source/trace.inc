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

stock bool:TraceTarget(client, index, const Float:clientLoc[3], const Float:indexLoc[3])
{
    new Float:angle[3];
    angle[0] = indexLoc[0] - clientLoc[0];
    angle[1] = indexLoc[1] - clientLoc[1];
    angle[2] = indexLoc[2] - clientLoc[2];
    g_TraceFilterIndex = index;
    TR_TraceRayFilter(indexLoc,angle,MASK_SOLID,RayType_Infinite,TraceRayFilterIndex);
    return (TR_GetEntityIndex() == index);
}

public bool:TraceRayFilterIndex(entity,mask)
{
  return (entity != g_TraceFilterIndex);
}
