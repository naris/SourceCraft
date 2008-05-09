/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_player.inc
 * Description: Functions to return information about TF2 player condition.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _tf2_player_included
 #endinput
#endif
#define _tf2_player_included

#include <tf2>
#include <sdktools>

#define TF2_PLAYER_SLOWED       (1 << 0)    // 1
#define TF2_PLAYER_ZOOMED       (1 << 1)    // 2
#define TF2_PLAYER_DISGUISING   (1 << 2)    // 4
#define TF2_PLAYER_DISGUISED	(1 << 3)    // 8
#define TF2_PLAYER_CLOAKED      (1 << 4)    // 16
#define TF2_PLAYER_INVULN       (1 << 5)    // 32
#define TF2_PLAYER_HEALING	    (1 << 6)    // 64
#define TF2_PLAYER_TAUNTING	    (1 << 7)    // 128
//#define TF2_PLAYER	        (1 << 8)    // 256

stock tf2_PlayerCondOffset;
stock bool:tf2_PlayerCondSet = false;

stock TF2_GetNumHealers(client)
{
    static numHealersOffset;
    static bool:numHealersSet = false;

    if (IsClientConnected(client))
    {
        if (!m_PlayerNumHealers)
        {
            numHealersOffset=FindSendPropInfo("CTFPlayer","m_nNumHealers");
            numHealersSet = true;
        }

        if (numHealersOffset > 0)
            return GetEntData(client,numHealersOffset);
    }
    return -1;
}

stock TF2_GetPlayerCondOffset()
{
    if (!tf2_PlayerCondSet)
    {
        tf2_PlayerCondOffset=FindSendPropInfo("CTFPlayer","m_nPlayerCond");
        tf2_PlayerCondSet = true;
    }
    return tf2_PlayerCondSet;
}

stock TF2_GetPlayerCond(client)
{
    if (IsClientConnected(client))
    {
        if (TF2_GetPlayerCondOffset() > 0)
            return GetEntData(client,tf2_PlayerCondOffset);
    }
    return -1;
}

stock TF2_SetPlayerCond(client,playerCond)
{
    if (IsClientConnected(client))
    {
        if (TF2_GetPlayerCondOffset() > 0)
            SetEntData(client,tf2_PlayerCondOffset,playerCond);
    }
}

stock bool:TF2_IsPlayerZoomed(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_ZOOMED) != 0) : false;
}

stock bool:TF2_IsPlayerSlowed(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_SLOWED) != 0) : false;
}

stock bool:TF2_IsPlayerDisguised(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_DISGUISED) != 0) : false;
}

stock bool:TF2_IsPlayerCloaked(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_CLOAKED) != 0) : false;
}

stock bool:TF2_IsPlayerInvuln(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_INVULN) != 0) : false;
}

stock TF2_SetPlayerCloak(client, bool:enabled)
{
    new playerCond = TF2_GetPlayerCond(client);
    if (playerCond >= 0)
    {
        if (enabled)
            TF2_SetPlayerCond(client, (playerCond | TF2_PLAYER_CLOAKED));
        else
            TF2_SetPlayerCond(client, (playerCond & (~TF2_PLAYER_CLOAKED)));
    }
}
