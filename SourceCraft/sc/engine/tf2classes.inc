/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2classes.inc
 * Description: Functions to return infomation about TF2 classes.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _tf2classes_included
 #endinput
#endif
#define _tf2classes_included

stock Float:GetNormalSpeed(client)
{
    if (GameType == tf2)
    {
        new class;
        switch (class = TF_GetClass(client))
        {
            case TF2_SCOUT:     return 400.0;
            case TF2_SNIPER:    return 300.0;
            case TF2_SOLDIER:   return 240.0;
            case TF2_DEMOMAN:   return 280.0;
            case TF2_MEDIC:     return 320.0;
            case TF2_HEAVY:     return 230.0;
            case TF2_PYRO:      return 300.0;
            case TF2_SPY:       return 300.0;
            case TF2_ENG:       return 300.0;
            default:            LogMessage("Unknown TF2 class %d", class);
        }
    }
    return 0.0;
}

