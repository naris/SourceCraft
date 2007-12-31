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


stock savedHealth[MAXPLAYERS+1];

stock SaveHealth(client)
{
    savedHealth[client] = GetClientHealth(client);
}

stock GetSavedHealth(client)
{
    return savedHealth[client];
}

stock SaveAllHealth()
{
    new clientCount = GetClientCount();
    for(new x=1;x<=clientCount;x++)
    {
        if (IsClientConnected(x) && IsPlayerAlive(x))
            savedHealth[x] = GetClientHealth(x);
    }
}

stock GetDamage(Handle:event, victim=0, attacker=0, min=5, max=20)
{
    new damage;

    switch (GameType)
    {
        case cstrike:
            damage = GetEventInt(event,"dmg_health");
        case dod:
            damage = GetEventInt(event,"damage");
        default:
        {
            if (!victim)
                victim = GetClientOfUserId(GetEventInt(event,"userid"));

            if (victim)
            {
                new prevHealth = savedHealth[victim]; 
                if (prevHealth)
                    damage = prevHealth - GetEventInt(event,"health");
            }
        }
    }
    return damage;
}
