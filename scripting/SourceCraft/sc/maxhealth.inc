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

#include <tf2_player>
#include <gametype>

#include "sc/client"
#include "sc/HealthParticle"

#define HEALTH_ADDS_ARMOR
#if defined HEALTH_ADDS_ARMOR
    stock g_addHealth[MAXPLAYERS+1];
#endif

stock g_maxHealth[MAXPLAYERS+1];

stock GetPlayerMaxHealth(entity)
{
    if (IsClient(entity))
    {
        if (GetGameType() == tf2)
            return TF2_GetPlayerMaxHealth(entity);
        else
            return 100;
    }
    else
    {
        //new offset = GetEntSendPropOffs(entity, "m_iMaxHealth", true);
        //return (offset > 0) ? GetEntData(entity, offset) : -1;
        return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
    }
}

stock GetMaxHealth(entity)
{
    if (GetGameType() == tf2)
        return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
    else
    {
        new max = g_maxHealth[entity];
        return (max > 0) ? max : 100;
    }
}

stock SetMaxHealth(entity,amount)
{
    if (GameType == tf2)
        SetEntProp(entity, Prop_Data, "m_iMaxHealth", amount);
    else
        g_maxHealth[entity] = amount;
}

stock SetIncreasedHealth(client, amount, armor=0, const String:name[]="")
{
    new maxhp = GetMaxHealth(client);
    new health = GetClientHealth(client)+amount;
    if (health > maxhp)
    {
        SetMaxHealth(client, health);

        #if defined HEALTH_ADDS_ARMOR
            amount = health - maxhp;
            g_addHealth[client] = amount;
            SetArmorAmount(client, armor+amount);

            if (name[0])
                SetArmorName(client, name);
        #else
            #pragma unused armor, name
        #endif
    }

    SetEntityHealth(client, health);
    ShowHealthParticle(client);
}

stock IncreaseHealth(client, amount)
{
    new maxhp = GetMaxHealth(client);
    new classmax = GetPlayerMaxHealth(client)+amount;
    new health = GetClientHealth(client)+amount;
    if (health > classmax)
        health = classmax;
    if (health > maxhp)
    {
        SetMaxHealth(client, health);

        #if defined HEALTH_ADDS_ARMOR
            amount = health - maxhp;
            g_addHealth[client] += amount;
            IncrementArmor(client, amount);
        #endif
    }

    SetEntityHealth(client, health);
    ShowHealthParticle(client);
}

stock ResetMaxHealth(client)
{
    if (GameType == tf2 && IsClientInGame(client))
    {
        new maxhp = GetPlayerMaxHealth(client); // TF2_GetPlayerResourceData(client,TFResource_MaxHealth);
        SetMaxHealth(client, maxhp);

        #if defined HEALTH_ADDS_ARMOR
            DecrementArmor(client, g_addHealth[client]);
            g_addHealth[client] = 0;
        #endif
    }
    else
        g_maxHealth[client] = 100;
}
