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
    else
        DispatchSpawn(client);
}

public Action:RespawnPlayerHandle(Handle:timer,any:arg)
{
    new client=PlayerOfAuthTimer(arg);
    if(client)
        RespawnPlayer(client);
    return Plugin_Stop;
}

public Action:ResetUber(Handle:timer,any:arg)
{
    new client=PlayerOfAuthTimer(arg);
    if(client)
        UnUberEntity(client);
    return Plugin_Stop;
}

