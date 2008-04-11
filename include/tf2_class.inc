/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_class.inc
 * Description: Functions to return infomation about TF2 classes.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _tf2_class_included
 #endinput
#endif
#define _tf2_class_included

stock Float:GetClassSpeed(client)
{
    switch (TF2_GetPlayerClass(client))
    {
        case TFClass_Scout:     return 400.0;
        case TFClass_Soldier:   return 240.0;
        case TFClass_DemoMan:   return 280.0;
        case TFClass_Medic:     return 320.0;
        case TFClass_Pyro:      return 300.0;
        case TFClass_Spy:       return 300.0;
        case TFClass_Engineer:  return 300.0;
        case TFClass_Sniper:    return TF2_IsPlayerSlowed(client) ? 80.0 : 300.0;
        case TFClass_Heavy:     return TF2_IsPlayerSlowed(client) ? 80.0 : 230.0;
    }
    return 0.0;
}

