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

stock maxHealthOffset[MAXPLAYERS+1];

stock maxHealth[MAXPLAYERS+1];
stock bool:healthIncreased[MAXPLAYERS+1];

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
    SetHealth(client, health);
}

stock SetHealth(entity,amount)
{
    SetEntityHealth(entity,(amount <= 0) ? 0 : amount);
}

stock SetMaxHealth(entity,amount)
{
    if (GameType == tf2)
        SetEntData(entity,maxHealthOffset[entity],amount,1);
    else
        maxHealth[entity] = amount;
}

stock GetMaxHealth(entity)
{
    if (GameType == tf2)
        return GetEntData(entity,maxHealthOffset[entity],1);
    else
        return maxHealth[entity];
}

stock KillPlayer(client)
{
    // die! die! die!!!!
    //SetEntityHealth(client,0);
    //ForcePlayerSuicide(client);
    FakeClientCommand(client,"kill\n");
}
