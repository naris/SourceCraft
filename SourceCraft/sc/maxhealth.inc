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

stock m_OffsetMaxHealth[MAXPLAYERS+1];

stock maxHealth[MAXPLAYERS+1];
stock bool:healthIncreased[MAXPLAYERS+1];

stock FindMaxHealthOffset(client)
{
    if (GameType == tf2)
    {
        m_OffsetMaxHealth[client]=FindDataMapOffs(client,"m_iMaxHealth");
        if(m_OffsetMaxHealth[client] == -1)
            LogError("Error finding MaxHealth offset for %d.", client);
    }
}

stock GetMaxHealth(entity)
{
    if (GameType == tf2)
    {
        if (entity <= MAXPLAYERS && m_OffsetMaxHealth[entity])
            return GetEntData(entity,m_OffsetMaxHealth[entity]);
        else
        {
            new offset = FindDataMapOffs(entity,"m_iMaxHealth");
            if (offset)
                return GetEntData(entity,offset);
            else
                return -1;
        }
    }
    else
        return maxHealth[entity];
}

stock SetMaxHealth(entity,amount)
{
    if (GameType == tf2)
    {
        if (entity <= MAXPLAYERS && m_OffsetMaxHealth[entity])
            SetEntData(entity,m_OffsetMaxHealth[entity],amount);
        else
        {
            new offset = FindDataMapOffs(entity,"m_iMaxHealth");
            if (offset)
                SetEntData(entity,offset,amount);
        }
    }
    else
        maxHealth[entity] = amount;
}

stock IncreaseHealth(client, amount)
{
    new health = GetClientHealth(client)+amount;
    if (GameType == tf2)
    {
        if (health > GetMaxHealth(client))
        {
            SetMaxHealth(client, health);
            healthIncreased[client] = true;
        }
    }
    SetEntityHealth(client, health);
}

stock ResetMaxHealth(client)
{
    if (healthIncreased[client])
    {
        healthIncreased[client] = false;
        if (GameType == tf2)
            SetMaxHealth(client,TF2_GetPlayerResourceData(client,TFResource_MaxHealth));
        else
            maxHealth[client] = 100;
    }
}
