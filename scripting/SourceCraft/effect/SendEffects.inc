/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: SendEffects.inc
 * Description: Stocks to TE_Send() tempents based on settings.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _SendEffects_included
 #endinput
#endif
#define _SendEffects_included

#include <lib/ResourceManager>

/**
 * Sets up the list[] and alt_list[] for beacon effects.
 */
stock SetupBeaconLists(list[], alt_list[], &count, &alt_count)
{
    count = alt_count = 0;
    new maxClients = GetMaxClients();
    for (new i=1; i<=maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (!GetSetting(i, Remove_Queasiness) &&
                !GetSetting(i, Disable_Beacons))
            {
                if (GetSetting(i, Reduce_Queasiness))
                    alt_list[alt_count++] = i;
                else
                    list[count++] = i;
            }
        }
    }
}

/**
 * Sets up the list[] and alt_list[] for offensive beacon effects.
 */
stock SetupOBeaconLists(list[], alt_list[], &count, &alt_count, client=0)
{
    count = alt_count = 0;
    new maxClients = GetMaxClients();
    for (new i=1; i<=maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (!GetSetting(i, Remove_Queasiness))
            {
                if (i == client)
                {
                    if (!GetSetting(i, Disable_Beacons))
                    {
                        if (GetSetting(i, Reduce_Queasiness))
                            alt_list[alt_count++] = i;
                        else
                            list[count++] = i;
                    }
                }
                else if (!GetSetting(i, Disable_OBeacons))
                {
                    if (GetSetting(i, Reduce_Queasiness))
                        alt_list[alt_count++] = i;
                    else
                        list[count++] = i;
                }
            }
        }
    }
}

/**
 * Broadcasts the current beacon temp entity to all clients
 * that don't have Disable_Beacons set.
 * @note See TE_Start().
 *
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendBeaconToAll(Float:delay=0.0)
{
	new maxClients = GetMaxClients();
	new total = 0;
	new clients[maxClients];
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) &&
            !GetSetting(i, Disable_Beacons))
		{
			clients[total++] = i;
		}
	}
	TE_Send(clients, total, delay);
}

/**
 * Broadcasts the current beacon temp entity to all clients
 * that don't have Disable_Beacons set.
 * @note See TE_Start().
 *
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendOBeaconToAll(client=0, Float:delay=0.0)
{
    new maxClients = GetMaxClients();
    new total = 0;
    new clients[maxClients];
    for (new i=1; i<=maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (i == client)
            {
                if (!GetSetting(i, Disable_Beacons))
                    clients[total++] = i;
            }
            else if (!GetSetting(i, Disable_OBeacons))
            {
                clients[total++] = i;
            }
        }
    }
    TE_Send(clients, total, delay);
}

/**
 * Broadcasts the current (possibly queasy Effect) temp entity to all clients
 * that don't have Disable_Effects set.
 * @note See TE_Start().
 *
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendQEffectToAll(client=0, victim=0, Float:delay=0.0)
{
    new maxClients = GetMaxClients();
    new total = 0;
    new clients[maxClients];
    for (new i=1; i<=maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (!GetSetting(i, Disable_Effects) &&
                !GetSetting(i, Remove_Queasiness) &&
                (!GetSetting(i, Reduce_Queasiness) ||
                 i == client || i == victim))
            {
                clients[total++] = i;
            }
        }
    }
    TE_Send(clients, total, delay);
}

/**
 * Broadcasts the current Dynamic Effect (accused of being laggy)
 * temp entity to all clients that don't have Disable_Effects set.
 * @note See TE_Start().
 *
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendDEffectToAll(Float:delay=0.0)
{
    new maxClients = GetMaxClients();
    new total = 0;
    new clients[maxClients];
    for (new i=1; i<=maxClients; i++)
    {
		if (IsClientInGame(i) && !IsFakeClient(i) &&
            !GetSetting(i, Disable_Effects) &&
            !GetSetting(i, Disable_DEffects))
		{
			clients[total++] = i;
		}
    }
    TE_Send(clients, total, delay);
}

/**
 * Broadcasts the current Effect temp entity to all clients
 * that don't have Disable_Effects set.
 * @note See TE_Start().
 *
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendEffectToAll(Float:delay=0.0)
{
	new maxClients = GetMaxClients();
	new total = 0;
	new clients[maxClients];
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) &&
            !GetSetting(i, Disable_Effects))
		{
			clients[total++] = i;
		}
	}
	TE_Send(clients, total, delay);
}

/**
 * Broadcasts the current Effect temp entity to all clients
 * that don't have Disable_Effects set.
 * @note See TE_Start().
 *
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendEffectToOthers(client=0, victim=0, Float:delay=0.0)
{
    new maxClients = GetMaxClients();
    new total = 0;
    new clients[maxClients];
    for (new i=1; i<=maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if ((i != client && i != victim) &&
                !GetSetting(i, Disable_Effects))
            {
                clients[total++] = i;
            }
        }
    }
    TE_Send(clients, total, delay);
}

/**
 * Sends the current TE to only a client
 * that doesn't have Disable_Effects set.
 * @note See TE_Start().
 *
 * @param client	Client to send to.
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendEffectToClient(client, Float:delay=0.0)
{
    if (!GetSetting(client, Disable_Effects))
    {
        new players[1];

        players[0] = client;

        TE_Send(players, 1, delay);
    }
}

/**
 * Sends the current TE to only players on the given team
 * that don't have Disable_Effects set.
 * @note See TE_Start().
 *
 * @param team	    Team to send to.
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendEffectToTeam(team,Float:delay=0.0)
{
    new total = 0;
    new clients[MaxClients];
    for (new i=1; i<=MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (GetClientTeam(i) == team &&
                !GetSetting(i, Disable_Effects))
            {
                clients[total++] = i;
            }
        }
    }
    TE_Send(clients, total, delay);
}

/**
 * Sends the current TE to only players not on the given team
 * that don't have Disable_Effects set.
 * @note See TE_Start().
 *
 * @param team	    Team NOT to send to.
 * @param delay		Delay in seconds to send the TE.
 * @noreturn
 */
stock void TE_SendEffectToOtherTeam(team,Float:delay=0.0)
{
    new total = 0;
    new clients[MaxClients];
    for (new i=1; i<=MaxClients; i++)
    {
        if (ValidPlayer(i,false)&&!IsFakeClient(i))
        {
            if (GetClientTeam(i) != team &&
                !GetSetting(i, Disable_Effects))
            {
                clients[total++] = i;
            }
        }
    }
    TE_Send(clients, total, delay);
}

