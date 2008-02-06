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

stock m_OffsetMaxHealth;

stock maxHealth[MAXPLAYERS+1];
stock bool:healthIncreased[MAXPLAYERS+1];

stock FindMaxHealthOffset()
{
    if (GameType == tf2)
    {
        m_OffsetMaxHealth=FindSendPropInfo("CTFPlayer", "m_iMaxHealth");
        if(m_OffsetMaxHealth == -1)
            SetFailState("Error finding MaxHealth offset.");
    }
}

stock SetupMaxHealth(client)
{
    if (GameType == tf2)
        maxHealth[client] = GetMaxHealth(client);
    else
        maxHealth[client] = GetClientHealth(client);
}

stock IncreaseHealth(client, amount)
{
    new health = GetClientHealth(client)+amount;
    if (GameType == tf2 && health > GetMaxHealth(client))
    {
        SetMaxHealth(client, health);
        healthIncreased[client] = true;
    }
    SetEntityHealth(client, health);
}

stock ResetMaxHealth(client)
{
    if (GameType == tf2)
        SetMaxHealth(client,maxHealth[client]);
    else
        maxHealth[client] = 100;
}

stock SetMaxHealth(entity,amount)
{
    if (GameType == tf2)
        SetEntData(entity,m_OffsetMaxHealth,amount);
    else
        maxHealth[entity] = amount;
}

stock GetMaxHealth(entity)
{
    if (GameType == tf2)
        return GetEntData(entity,m_OffsetMaxHealth);
    else
        return maxHealth[entity];
}
