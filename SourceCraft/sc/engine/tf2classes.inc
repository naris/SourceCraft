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

stock GetClass(client)
{
    return GetEntData(client,m_OffsetClass);
}

stock GetPlayerCond(client)
{
    return GetEntData(client,m_OffsetPlayerCond);
}

stock Float:GetClassSpeed(client)
{
    if (GameType == tf2)
    {
        switch (GetClass(client))
        {
            case TF2_SCOUT:     return 400.0;
            case TF2_SOLDIER:   return 240.0;
            case TF2_DEMOMAN:   return 280.0;
            case TF2_MEDIC:     return 320.0;
            case TF2_PYRO:      return 300.0;
            case TF2_SPY:       return 300.0;
            case TF2_ENG:       return 300.0;
            case TF2_SNIPER:    return (GetPlayerCond(client) & 1) ? 80.0 : 300.0;
            case TF2_HEAVY:     return (GetPlayerCond(client) & 1) ? 80.0 : 230.0;
        }
    }
    return 0.0;
}

