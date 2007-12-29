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

#if defined USE_CS_RESPAWN
    #undef REQUIRE_EXTENSIONS
    #include <cstrike>
    #define REQUIRE_EXTENSIONS
#endif

stock SetupRespawn()
{
    #if defined USE_CS_RESPAWN
        if (GetGameType() != cstrike)
            MarkNativeAsOptional("CS_RespawnPlayer");
    #endif
}

stock RespawnPlayer(client)
{
    #if defined USE_CS_RESPAWN
        if (GameType == cstrike)
            CS_RespawnPlayer(client);
        else
            DispatchSpawn(client);
    #else
        DispatchSpawn(client);
    #endif
}

public Action:RespawnPlayerHandle(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
        RespawnPlayer(client);
    ClearArray(temp);
}
