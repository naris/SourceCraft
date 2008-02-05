/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: health.inc
 * Description: Health functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _health_included
 #endinput
#endif
#define _health_included

stock m_OffsetMaxHealth;
stock maxHealthOffset[MAXPLAYERS+1];

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
    if (maxHealth[client] <= 0)
    {
        if (GameType == tf2)
            maxHealth[client] = GetMaxHealth(client);
        else
            maxHealth[client] = GetClientHealth(client);
    }
}

stock SetupHealth(client)
{
    if (GameType == tf2)
    {
        maxHealthOffset[client]=FindDataMapOffs(client,"m_iMaxHealth");
        maxHealth[client] = GetMaxHealth(client);
    }
    else
        maxHealth[client] = GetClientHealth(client);
}

stock ResetMaxHealth(client)
{
    maxHealth[client] = 0;
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

stock SetMaxHealth(entity,amount)
{
    if (GameType == tf2)
        SetEntData(entity,maxHealthOffset[entity],amount);
    else
        maxHealth[entity] = amount;
}

stock GetMaxHealth(entity)
{
    if (GameType == tf2)
        return GetEntData(entity,maxHealthOffset[entity]);
    else
        return maxHealth[entity];
}
