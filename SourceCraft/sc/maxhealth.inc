/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: maxhealth.inc
 * Description: Max Health functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _maxhealth_included
 #endinput
#endif
#define _maxhealth_included

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

stock maxHealth[MAXPLAYERS+1];

stock GetMaxHealth(entity)
{
    if (GameType == tf2)
        return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
    else
        return maxHealth[entity];
}

stock SetMaxHealth(entity,amount)
{
    if (GameType == tf2)
        SetEntProp(entity, Prop_Data, "m_iMaxHealth", amount);
    else
        maxHealth[entity] = amount;
}

stock IncreaseHealth(client, amount)
{
    new health = GetClientHealth(client)+amount;
    if (GameType == tf2)
    {
        if (health > GetMaxHealth(client))
            SetMaxHealth(client, health);
    }
    SetEntityHealth(client, health);
}

stock ResetMaxHealth(client)
{
    if (GameType == tf2)
    {
        new max=TF2_GetPlayerResourceData(client,TFResource_MaxHealth);
        SetMaxHealth(client, max);
    }
    else
        maxHealth[client] = 100;
}
