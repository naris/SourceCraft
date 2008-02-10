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

stock g_OffsetHealth[MAXPLAYERS+1];
stock m_OffsetMaxHealth[MAXPLAYERS+1];

stock maxHealth[MAXPLAYERS+1];
stock bool:healthIncreased[MAXPLAYERS+1];

stock FindHealthOffsets(client)
{
    if (GameType == tf2)
    {
        g_OffsetHealth[client]=FindDataMapOffs(client,"m_iHealth");
        if(g_OffsetHealth[client] == -1)
            LogError("Error finding Health offset for %d.", client);

        m_OffsetMaxHealth[client]=FindDataMapOffs(client,"m_iMaxHealth");
        if(m_OffsetMaxHealth[client] == -1)
            LogError("Error finding MaxHealth offset for %d.", client);
    }
}

stock GetHealth(entity)
{
    if (GameType == tf2)
    {
        if (entity <= MAXPLAYERS && g_OffsetHealth[entity])
            return GetEntData(entity,g_OffsetHealth[entity]);
        else
        {
            new offset = FindDataMapOffs(entity,"m_iHealth");
            if (offset)
                return GetEntData(entity,offset);
            else
                return -1;
        }
    }
    else
        return GetClientHealth(entity);
}

stock SetHealth(entity,amount)
{
    if (GameType == tf2)
    {
        if (entity <= MAXPLAYERS && g_OffsetHealth[entity])
            SetEntData(entity,g_OffsetHealth[entity],amount);
        else
        {
            new offset = FindDataMapOffs(entity,"m_iHealth");
            if (offset)
                SetEntData(entity,offset,amount);
        }
    }
    else
        SetEntityHealth(entity,amount);
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

stock SaveMaxHealth(client)
{
    if (GameType == tf2)
        maxHealth[client] = GetMaxHealth(client);
    else
        maxHealth[client] = GetHealth(client);
}

stock IncreaseHealth(client, amount)
{
    new health = GetHealth(client);
    if (GameType == tf2)
    {
        new health2 = GetEntData(client,m_OffsetHealth);
        new max_health = GetMaxHealth(client);
        new max_health2 = TF_GetMaxHealth(client);

        LogMessage("[IncreaseHealth] %d - health=%d(%d), maxHealth=%d(%d)", client, health, health2, max_health, max_health2);
        if (client &&  IsClientInGame(client))
            PrintToChat(client,"[IncreaseHealth] health=%d(%d), maxHealth=%d(%d)", health, health2, max_health, max_health2);

        health += amount;
        if (health > max_health)
        {
            SetMaxHealth(client, health);
            healthIncreased[client] = true;

            LogMessage("[IncreaseHealth] %d - set maxHealth=%d", client, health);
            if (client &&  IsClientInGame(client))
                PrintToChat(client,"[IncreaseHealth] set maxHealth=%d", health);
        }
        SetHealth(client, health);
    }
    else
        SetHealth(client, health+amount);
}

stock ResetMaxHealth(client)
{
    if (healthIncreased[client])
    {
        healthIncreased[client] = false;
        if (GameType == tf2)
            SetMaxHealth(client,maxHealth[client]);
        else
            maxHealth[client] = 100;
    }
}
