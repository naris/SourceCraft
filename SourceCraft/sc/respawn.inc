/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: util.inc
 * Description: Respawn functions
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _respawn_included
 #endinput
#endif
#define _respawn_included

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <cstrike>
#define REQUIRE_EXTENSIONS

// Reincarnation variables
stock m_ReincarnationCount[MAXPLAYERS+1];
stock bool:m_IsRespawning[MAXPLAYERS+1];
stock bool:m_IsChangingClass[MAXPLAYERS+1];
stock Float:m_DeathLoc[MAXPLAYERS+1][3];

stock SetupRespawn()
{
    if (GetGameType() != cstrike)
        MarkNativeAsOptional("CS_RespawnPlayer");
}

stock RespawnPlayer(client)
{
    if (GameType == cstrike)
        CS_RespawnPlayer(client);
    else if (GameType == tf2)
    {
        SetEntPropFloat(client, Prop_Send, "m_flDeathTime", 0.0);
        TF2_RespawnPlayer(client);
    }
    else
        DispatchSpawn(client);
}

public Action:RespawnPlayerHandle(Handle:timer,Handle:pack)
{
    new client=ClientOfAuthTimer(pack);
    if(client)
        RespawnPlayer(client);
    return Plugin_Stop;
}

public Action:SetInvuln(Handle:timer,Handle:pack)
{
    /*
    new client=ClientOfAuthTimer(pack);
    if(client)
    {
        TF2_SetPlayerInvuln(client, true);
        new Float:duration = ReadPackFloat(pack);
        if (duration > 0.0)
            AuthTimer(duration,client,ResetInvuln);
    }
     */
    return Plugin_Stop;
}

public Action:ResetInvuln(Handle:timer,Handle:pack)
{
    /*
    new client=ClientOfAuthTimer(pack);
    if(client)
        TF2_SetPlayerInvuln(client, false);
     */
    return Plugin_Stop;
}

