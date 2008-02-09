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
    savedHealth[client] = GetHealth(client);
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
        if (IsClientInGame(x) && !IsFakeClient(x))
        {
            if (IsPlayerAlive(x))
                savedHealth[x] = GetHealth(x);
        }
    }
}

stock GetDamage(Handle:event, client=0)
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
            if (!client)
                client = GetClientOfUserId(GetEventInt(event,"userid"));

            if (client)
            {
                new prevHealth = savedHealth[client]; 
                if (prevHealth)
                {
                    damage = prevHealth - GetEventInt(event,"health");
                    if (damage < 0)
                        damage = 0;
                }
            }
        }
    }
    return damage;
}
