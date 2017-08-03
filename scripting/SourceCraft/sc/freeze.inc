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

#undef REQUIRE_PLUGIN
#include "lib/jetpack"
#define REQUIRE_PLUGIN

#include "lib/ResourceManager"

#include "sc/burrow"

stock FreezeEntity(entity, id=0)
{
    if (entity <= MAXPLAYERS)
    {
        SetRestriction(entity, Restriction_Grounded, true);
        SetMoveType(entity, MOVETYPE_NONE,.id=id);
    }
    else
        SetEntityMoveType(entity,MOVETYPE_NONE);
}

stock UnFreezeEntity(entity, id=0)
{
    if (entity <= MAXPLAYERS)
    {
        SetRestriction(entity, Restriction_Grounded, false);

        if (!IsBurrowed(entity))
            SetMoveType(entity, MOVETYPE_WALK,.id=id);
    }
    else
        SetEntityMoveType(entity,MOVETYPE_DEFAULT);
}

public Action:UnfreezePlayer(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client)
        UnFreezeEntity(client);

    return Plugin_Stop;
}
