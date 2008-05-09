/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_cloak.inc
 * Description: Functions to return information about TF2 spy cloak.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _tf2_cloak_included
 #endinput
#endif
#define _tf2_cloak_included

#include <sdktools>

stock tf2_CloakMeterOffset;
stock bool:tf2_CloakMeterSet = false;

stock TF2_GetCloakMeterOffset()
{
    if (!tf2_CloakMeterOffset)
    {
        tf2_CloakMeterOffset=FindSendPropInfo("CTFPlayer","m_flCloakMeter");
        tf2_CloakMeterSet = true;
    }
    return tf2_CloakMeterOffset;
}

stock Float:TF2_GetCloakMeter(client)
{
    if (IsClientConnected(client))
    {
        if (TF2_GetCloakMeterOffset() > 0)
            return GetEntDataFloat(client,tf2_CloakMeterOffset);
    }
    return -1.0;
}

stock TF2_SetCloakMeter(client,Float:cloakMeter)
{
    if (IsClientConnected(client))
    {
        if (TF2_GetCloakMeterOffset() > 0)
            SetEntDataFloat(client,tf2_CloakMeterOffset,cloakMeter);
    }
}
