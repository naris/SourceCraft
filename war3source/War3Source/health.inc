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

stock healthOffset[MAXPLAYERS+1]            = { 0, ... };
stock maxHealthOffset[MAXPLAYERS+1]         = { 0, ... };

stock maxHealth[MAXPLAYERS+1]               = { 0, ... };
stock bool:healthIncreased[MAXPLAYERS+1]    = { false, ... };

stock SetupHealth(client)
{
    healthOffset[client]=FindDataMapOffs(client,"m_iHealth");

    if (GameType == tf2)
    {
        maxHealthOffset[client]=FindDataMapOffs(client,"m_iMaxHealth");
        maxHealth[client] = GetMaxHealth(client);
    }
    else
        maxHealth[client] = GetHealth(client);
}

stock SetupMaxHealth(client)
{
    if (maxHealth[client] <= 0)
    {
        if (GameType == tf2)
            maxHealth[client] = GetMaxHealth(client);
        else
            maxHealth[client] = GetHealth(client);
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
    SetEntData(entity,healthOffset[entity],amount,1);
}

stock GetHealth(entity)
{
    return GetEntData(entity,healthOffset[entity],1);
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

stock GetDamage(Handle:event, attacker=0, min=5, max=20)
{
    new damage=GetEventInt(event,"damage");
    if (!damage)
    {
        damage = GetEventInt(event,"dmg_health");
        if (!damage)
        {
            if (attacker)
            {
                decl String:weapon[64];
                GetClientWeapon(attacker, weapon, sizeof(weapon));

                if (StrEqual(weapon, "bat"))
                    damage = GetRandomInt(30,45);
                else if (StrEqual(weapon, "knife"))
                    damage = GetRandomInt(30,40);
                else if (StrEqual(weapon, "smg"))
                    damage = GetRandomInt(6,12);
                else if (StrEqual(weapon, "pistol") || StrEqual(weapon, "pistol_scout"))
                    damage = GetRandomInt(9,25);
                else if (StrEqual(weapon, "revolver"))
                    damage = GetRandomInt(20,60);
                else if (StrEqual(weapon, "scattergun"))
                    damage = GetRandomInt(3,110);
                else if (StrEqual(weapon, "flamethrower"))
                    damage = GetRandomInt(5,15);
                else if (StrEqual(weapon, "sniperrifle"))
                    damage = GetRandomInt(30,190);
                else if (StrEqual(weapon, "syringegun_medic"))
                    damage = GetRandomInt(8,13);
                else if (StrEqual(weapon, "tf_projectile_rocket"))
                    damage = GetRandomInt(50,110);
                else if (StrEqual(weapon, "tf_projectile_pipe"))
                    damage = GetRandomInt(45,120);
                else if (StrEqual(weapon, "tf_projectile_pipe_remote"))
                    damage = GetRandomInt(85,150);
                else if (StrEqual(weapon, "shotgun_pyro") || StrEqual(weapon, "shotgun_hwg") ||
                         StrEqual(weapon, "shotgun_soldier") || StrEqual(weapon, "shotgun_primary"))
                {
                    damage = GetRandomInt(3,100);
                }
                else if (StrEqual(weapon, "shovel") || StrEqual(weapon, "fireaxe") ||
                         StrEqual(weapon, "bonesaw") || StrEqual(weapon, "machete") ||
                         StrEqual(weapon, "bottle") || StrEqual(weapon, "wrench") ||
                         StrEqual(weapon, "club") || StrEqual(weapon, "fists"))
                {
                    damage = GetRandomInt(45,90);
                }
                else
                {
                    damage = GetRandomInt(min,max);
                }
            }
            else
            {
                damage = GetRandomInt(min,max);
            }
        }
    }
    return damage;
}
