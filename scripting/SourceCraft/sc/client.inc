/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: client.inc
 * Description: Client functions
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _client_included
 #endinput
#endif
#define _client_included

#define IsClient(%1)             (%1 > 0 && %1 <= MaxClients)
#define IsValidClient(%1)        (IsClient(%1) && IsClientInGame(%1))
#define IsValidClientNotSpec(%1) (IsValidClient(%1) && GetClientTeam(%1) > 1)
#define IsValidClientAlive(%1)   (IsValidClientNotSpec(%1) && IsPlayerAlive(%1))

#define IsPlayerInGameAlive(%1)  (IsClientInGame(%1) && IsPlayerAlive(%1))

#define ValidClientIndex(%1)     (IsValidClient(%1) ? %1 : 0)

/**
 * Returns the entity's origin vector.
 *
 * @param entity		Entity index.
 * @param vec			Destination vector to store the origin vector.
 * @noreturn
 */
stock GetEntityAbsOrigin(entity, Float:vec[3])
{
    if (IsClient(entity))
        GetClientAbsOrigin(entity, vec);
    else
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
}

#define COUNT_ALL       -1
#define COUNT_ACTIVE    -2
/*
* Returns the client count of the players in a team
*
* @param team               Team to count the clients on, COUNT_ALL to count all players
*                             or COUNT_ACTIVE to count all "active" players on an actual team.
* @param countFakeClients   If true bots will be counted too.
* @param inGameOnly         If false connecting players are also counted.
* @return                   Client count in the server.
*/
stock CountClients(team=COUNT_ALL, bool:countFakeClients=true, bool:inGameOnly=true)
{
    if (countFakeClients && team == COUNT_ALL)
        return GetClientCount(inGameOnly);
    else
    {
        new numClients = 0;

        for (new client=1; client <= MaxClients; client++)
        {
            if (!inGameOnly && !IsClientInGame(client))
            {
                continue;
            }
            else if (!countFakeClients && IsFakeClient(client))
            {
                continue;
            }
            else
            {
                new clientTeam = GetClientTeam(client);
                if (team == COUNT_ALL || (team >= 0 && clientTeam == team) ||
                    (team == COUNT_ACTIVE && clientTeam >= 2 && clientTeam <= 3))
                {
                    numClients++;
                }
            }
        }

        return numClients;
    }
}

/*
* Returns true if the client count of the players in a team is num or more
*
* @param team               Team to count the clients on, COUNT_ALL to count all players
*                             or COUNT_ACTIVE to count all "active" players on an actual team.
* @param countFakeClients   If true bots will be counted too.
* @param inGameOnly         If false connecting players are also counted.
* @return                   Client count in the server.
*/
stock bool:CheckClientCount(num, team=COUNT_ALL, bool:countFakeClients=true)
{
    if (countFakeClients && team == COUNT_ALL)
        return (GetClientCount() >= num);
    else
    {
        new numClients = 0;

        for (new client=1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client))
            {
                continue;
            }
            else if (!countFakeClients && IsFakeClient(client))
            {
                continue;
            }
            else
            {
                new clientTeam = GetClientTeam(client);
                if (team == COUNT_ALL || (team >= 0 && clientTeam == team) ||
                    (team == COUNT_ACTIVE && clientTeam >= 2 && clientTeam <= 3))
                {
                    if (++numClients >= num)
                        return true;
                }
            }
        }

        return (numClients >= num);
    }
}
