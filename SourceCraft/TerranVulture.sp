/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranVulture.sp
 * Description: The Terran Vulture unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include "firemines"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/screen"
#include "sc/range"
#include "sc/trace"

#include "sc/SupplyDepot"

new raceID, thrustersID, platingID, weaponsID, mineID;

new m_Plating[MAXPLAYERS+1];

new bool:m_FireminesAvailable = false;

new g_smokeSprite;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Vulture",
    author = "-=|JFH|=-Naris",
    description = "The Terran Vulture race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnSourceCraftReady()
{
    m_FireminesAvailable = LibraryExists("firemines");

    raceID      = CreateRace("Terran Vulture", "vulture",
                             "You are now a Terran Vulture.",
                             "You will be a Terran Vulture when you die or respawn.",
                             32, 20);

    AddSupplyDepotUpgrade(raceID);

    thrustersID = AddUpgrade(raceID,"Ion Thrusters", "thrusters",
                             "Gives you a speed boost, 15-30\% faster.");

    platingID   = AddUpgrade(raceID,"Plating", "plating", "Vehicle Plating that takes damage up to 60\% until it is depleted.");

    weaponsID   = AddUpgrade(raceID,"Weapons Upgrade", "weapons", 
                             "Does 20-80% extra damage to the \nenemy, chance is 30-60%.");

    if (m_FireminesAvailable)
    {
        mineID = AddUpgrade(raceID,"Spider Mine", "mine", "You will be given 3 spider mines to plant for every level.", true); // Ultimate
        ControlMines(true);
    }
    else
    {
        mineID = AddUpgrade(raceID,"Spider Mine", "mine", "Not Available", true, 99, 0); // Ultimate
    }

    CreateSupplyTimer(raceID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "firemines"))
    {
        m_FireminesAvailable = true;
        ControlMines(true);
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "firemines"))
        m_FireminesAvailable = false;
}

public OnMapStart()
{
    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt", true);
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            SetSpeed(player,-1.0);
            ApplyPlayerSettings();

            if (m_FireminesAvailable)
                GiveMine(client, 0);
        }
        else if (race == raceID)
        {
            if (m_FireminesAvailable)
            {
                new mine_level=GetUpgradeLevel(player,race,mineID);
                GiveMine(client, mine_level);
            }

            new plating_level = GetUpgradeLevel(player,raceID,platingID);
            if (plating_level)
                SetupPlating(client, plating_level);

            new thrusters_level = GetUpgradeLevel(player,race,thrustersID);
            Thrusters(client, player, thrusters_level);
            if (thrusters_level)
                ApplyPlayerSettings();
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && GetRace(player) == raceID)
    {
        if (upgrade==thrustersID)
        {
            Thrusters(client, player, new_level);
            ApplyPlayerSettings();
        }
        else if (upgrade==platingID)
            SetupPlating(client, new_level);
        else if (upgrade==mineID)
        {
            if (m_FireminesAvailable)
                GiveMine(client, new_level*3);
        }
    }
}

public OnItemPurchase(client,Handle:player,item)
{
    new race=GetRace(player);
    if (race == raceID && IsPlayerAlive(client))
    {
        if (item == FindShopItem("boots"))
        {
            new thrusters_level = GetUpgradeLevel(player,race,thrustersID);
            Thrusters(client, player, thrusters_level);
            ApplyPlayerSettings();
        }
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        new mine_level=GetUpgradeLevel(player,race,mineID);
        if (mine_level)
        {
            if (m_FireminesAvailable)
            {
                if (!pressed)
                    SetMine(client);
            }
            else
            {
                if (pressed)
                    PrintHintText(client,"Spider Mines are not available");
            }
        }
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new plating_level = GetUpgradeLevel(player,raceID,platingID);
                if (plating_level)
                    SetupPlating(client, plating_level);

                new thrusters_level = GetUpgradeLevel(player,race,thrustersID);
                Thrusters(client, player, thrusters_level);
                if (thrusters_level)
                    ApplyPlayerSettings();
            }
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    if (victim_race == raceID)
        changed = Plating(damage, victim_index, victim_player);

    if (attacker_index && attacker_index != victim_index)
    {
        if (attacker_race == raceID)
        {
            if (WeaponsUpgrade(damage, victim_index, victim_player,
                               attacker_index, attacker_player))
            {
                changed = true;
            }
        }
    }

    if (assister_index && assister_index != victim_index)
    {
        if (assister_race == raceID)
        {
            if (WeaponsUpgrade(damage, victim_index, victim_player,
                               assister_index, assister_player))
            {
                changed = true;
            }
        }
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

Thrusters(client, Handle:player, level)
{
    if (level > 0)
    {
        new Float:speed=1.0;
        switch (level)
        {
            case 1: speed=1.15;
            case 2: speed=1.20;
            case 3: speed=1.25;
            case 4: speed=1.30;
        }

        /* If the Player also has the Boots of Speed,
         * Increase the speed further
         */
        new boots = FindShopItem("boots");
        if (boots != -1 && GetOwnsItem(player,boots))
        {
            speed *= 1.1;
        }

        new Float:start[3];
        GetClientAbsOrigin(client, start);

        new color[4] = { 255, 100, 0, 255 };
        TE_SetupBeamRingPoint(start,20.0,60.0,g_smokeSprite,g_smokeSprite,
                              0, 1, 1.0, 4.0, 0.0 ,color, 10, 0);
        TE_SendToAll();

        SetSpeed(player,speed);
    }
    else
        SetSpeed(player,-1.0);
}

SetupPlating(client, level)
{
    switch (level)
    {
        case 0: m_Plating[client] = 0;
        case 1: m_Plating[client] = GetMaxHealth(client) / 3;
        case 2: m_Plating[client] = GetMaxHealth(client) / 2;
        case 3: m_Plating[client] = GetMaxHealth(client);
        case 4: m_Plating[client] = RoundFloat(float(GetMaxHealth(client))*1.25); 
    }
}

bool:Plating(damage, victim_index, Handle:victim_player)
{
    new plating_level = GetUpgradeLevel(victim_player,raceID,platingID);
    if (plating_level)
    {
        new Float:from_percent,Float:to_percent;
        switch(plating_level)
        {
            case 1:
            {
                from_percent=0.0;
                to_percent=0.10;
            }
            case 2:
            {
                from_percent=0.0;
                to_percent=0.30;
            }
            case 3:
            {
                from_percent=0.10;
                to_percent=0.50;
            }
            case 4:
            {
                from_percent=0.20;
                to_percent=0.60;
            }
        }
        new amount=RoundFloat(float(damage)*GetRandomFloat(from_percent,to_percent));
        new plating=m_Plating[victim_index];
        if (amount > plating)
            amount = plating;
        if (amount > 0)
        {
            new newhp=GetClientHealth(victim_index)+amount;
            new maxhp=GetMaxHealth(victim_index);
            if (newhp > maxhp)
                newhp = maxhp;

            SetEntityHealth(victim_index,newhp);

            m_Plating[victim_index] = plating - amount;

            decl String:victimName[64];
            GetClientName(victim_index,victimName,63);

            DisplayMessage(victim_index,SC_DISPLAY_DEFENSE,
                           "%c[SourceCraft] %s %cyour plating absorbed %d hp",
                           COLOR_GREEN,victimName,COLOR_DEFAULT,amount);
            return true;
        }
    }
    return false;
}

public WeaponsUpgrade(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new weapons_level=GetUpgradeLevel(player,raceID,weaponsID);
    if (weapons_level &&
        !GetImmunity(victim_player,Immunity_HealthTake) &&
        !TF2_IsPlayerInvuln(victim_index))
    {
        if (GetRandomInt(1,100) <= GetRandomInt(30,60))
        {
            new Float:percent;
            switch(weapons_level)
            {
                case 1:
                    percent=0.20;
                case 2:
                    percent=0.35;
                case 3:
                    percent=0.60;
                case 4:
                    percent=0.80;
            }

            new amount=RoundFloat(float(damage)*percent);
            if (amount > 0)
            {
                new newhp=GetClientHealth(victim_index)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    DisplayKill(index, victim_index, "weapons", "Weapons Upgrade", amount);
                }
                else
                    DisplayDamage(index, victim_index, "weapons", "Weapons Upgrade", amount);

                SetEntityHealth(victim_index,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victim_index, Origin);
                Origin[2] += 5;

                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendToAll();
                return amount;
            }
        }
    }
    return 0;
}
