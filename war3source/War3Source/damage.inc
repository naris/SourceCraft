/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: damage.inc
 * Description: Damage functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _damage_included
 #endinput
#endif
#define _damage_included


stock savedHealth[MAXPLAYERS+1]             = { 0, ... };

stock SaveHealth(client)
{
    if (IsClientConnected(client) && IsPlayerAlive(client))
        savedHealth[client] = GetHealth(client);
}

stock SaveAllHealth()
{
    new clientCount = GetClientCount();
    for(new x=1;x<=clientCount;x++)
    {
        if (IsClientConnected(x) && IsPlayerAlive(x))
        {
            savedHealth[x] = GetHealth(x);
        }
    }
}

stock GetDamage(Handle:event, victim=0, attacker=0, min=5, max=20)
{
    new damage=GetEventInt(event,"damage");
    if (!damage)
    {
        damage = GetEventInt(event,"dmg_health");
        if (!damage)
        {
            new prevHealth = savedHealth[victim]; 
            if (prevHealth)
            {
                if (!victim)
                {
                    new userid = GetEventInt(event,"userid");
                    if (userid)
                        victim = GetClientOfUserId(userid);
                }

                if (victim)
                {
                    new health = GetEventInt(event,"health");
                    if (health > prevHealth)
                        damage = health - prevHealth;
                }
            }

            if (!damage)
            {
                if (attacker)
                {
                    decl String:weapon[64];
                    GetClientWeapon(attacker, weapon, sizeof(weapon));

                    if (GameType == tf2)
                    {
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
                    else  // not tf2
                    {
                        damage = GetRandomInt(min,max);
                    }
                }
                else // no attacker
                {
                    damage = GetRandomInt(min,max);
                }
            }
        }
    }
    return damage;
}
