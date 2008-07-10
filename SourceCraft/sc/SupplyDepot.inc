/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: SupplyDepot.inc
 * Description: The Terran Suply Depot upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */

#include <tf2_player>
#include "sc/ammo"

stock supplyID;

stock CreateSupplyTimer(raceId)
{
    CreateTimer(5.0,SupplyDepot,raceId,TIMER_REPEAT);
}

stock AddSupplyDepotUpgrade(raceId)
{
    supplyID = AddUpgrade(raceId,"Supply Depot", "supply", "Provides additional ammo or metal");
}

public Action:SupplyDepot(Handle:timer, any:raceId)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceId)
                {
                    new supply_level=GetUpgradeLevel(player,raceId,supplyID);
                    if (supply_level)
                    {
                        if (GameType == tf2)
                        {
                            switch (TF2_GetPlayerClass(client))
                            {
                                case TFClass_Heavy: 
                                {
                                    new ammo = TF2_GetAmmoAmount(client, Primary);
                                    if (ammo < 400.0)
                                    {
                                        TF2_SetAmmoAmount(client, ammo + (10 * supply_level), Primary);
                                        DisplayMessage(client,SC_DISPLAY_MISC_MESSAGE,
                                                       "%c[SourceCraft]%c You have received ammo from the %cSupply Depot%c.",
                                                       COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                case TFClass_Pyro: 
                                {
                                    new ammo = TF2_GetAmmoAmount(client, Primary);
                                    if (ammo < 400.0)
                                    {
                                        TF2_SetAmmoAmount(client, ammo + (10 * supply_level), Primary);
                                        DisplayMessage(client,SC_DISPLAY_MISC_MESSAGE,
                                                       "%c[SourceCraft]%c You have received ammo from %cSupply Depot%c.",
                                                       COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                case TFClass_Medic: 
                                {
                                    new ammo = TF2_GetAmmoAmount(client, Primary);
                                    if (ammo < 300.0)
                                    {
                                        TF2_SetAmmoAmount(client, ammo + (10 * supply_level), Primary);
                                        DisplayMessage(client,SC_DISPLAY_MISC_MESSAGE,
                                                       "%c[SourceCraft]%c You have received ammo from the %cSupply Depot%c.",
                                                       COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                case TFClass_Engineer: // Gets Metal instead of Ammo
                                {
                                    new ammo = TF2_GetAmmoAmount(client, Metal);
                                    if (ammo < 400.0)
                                    {
                                        TF2_SetAmmoAmount(client, ammo + (10 * supply_level), Metal);
                                        DisplayMessage(client,SC_DISPLAY_MISC_MESSAGE,
                                                       "%c[SourceCraft]%c You have received metal from the %cSupply Depot%c.",
                                                       COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                default:
                                {
                                    new ammo = TF2_GetAmmoAmount(client, Primary);
                                    if (ammo < 60.0)
                                    {
                                        TF2_SetAmmoAmount(client, ammo + (10 * supply_level), Primary);
                                        DisplayMessage(client,SC_DISPLAY_MISC_MESSAGE,
                                                       "%c[SourceCraft]%c You have received ammo from the %cSupply Depot%c.",
                                                       COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                            }
                        }
                        else
                        {
                            new curWeapon = GetActiveWeapon(client);
                            if (curWeapon > 0)
                            {
                                SetClip(curWeapon, 5);

                                DisplayMessage(client,SC_DISPLAY_MISC_MESSAGE,
                                               "%c[SourceCraft]%c You have received ammo from the %cSupply Depot%c.",
                                               COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}
