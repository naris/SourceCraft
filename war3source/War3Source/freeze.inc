/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: freeze.inc
 * Description: Freeze functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _freeze_included
 #endinput
#endif
#define _freeze_included

stock movetypeOffset   = 0;

stock FindMoveTypeOffset()
{
    movetypeOffset=FindSendPropOffs("CBaseEntity","movetype");
    if(movetypeOffset==-1)
        SetFailState("Couldn't find MoveType offset");
}

stock FreezeEntity(entity)
{
    SetEntData(entity,movetypeOffset,0,1);
}

stock UnFreezeEntity(entity)
{
    SetEntData(entity,movetypeOffset,2,1);
}

public Action:UnfreezePlayer(Handle:timer,Handle:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
        UnFreezeEntity(client);
    ClearArray(temp);
    return Plugin_Stop;
}
