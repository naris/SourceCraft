/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranVulture.sp
 * Description: The Terran Vulture unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <firemines>
#include <tripmines>
#include <ztf2nades>
#include <AdvancedInfiniteAmmo>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/sounds"
#include "sc/armor"

#include "sc/ShopItems"
#include "sc/SupplyDepot"

#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:spawnWav[]     = "sc/tvurdy00.wav";  // Spawn sound
new const String:deathWav[]     = "sc/tvudth00.wav";  // Death sound

new raceID, supplyID, thrustersID, platingID, weaponsID, mineID, tripmineID, nadeID;

new const String:g_ArmorName[]  = "Plating";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.30},
                                    {0.10, 0.40},
                                    {0.20, 0.50} };

new Float:g_SpeedLevels[]       = { -1.0, 1.15, 1.20, 1.25, 1.30 };

new Float:g_WeaponsPercent[]    = { 0.0, 0.15, 0.30, 0.40, 0.50 };

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Vulture",
    author = "-=|JFH|=-Naris",
    description = "The Terran Vulture race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.ammopack.phrases.txt");
    LoadTranslations("sc.tripmine.phrases.txt");
    LoadTranslations("sc.grenade.phrases.txt");
    LoadTranslations("sc.vulture.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.bunker.phrases.txt");
    LoadTranslations("sc.supply.phrases.txt");
    LoadTranslations("sc.mine.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("vulture", 32, 0, 24, .faction=Terran,
                             .type=BioMechanical);

    supplyID    = AddUpgrade(raceID, "supply_depot");
    thrustersID = AddUpgrade(raceID, "thrusters");
    platingID   = AddUpgrade(raceID, "armor");
    weaponsID   = AddUpgrade(raceID, "weapons", .energy=2.0);

    // Ultimate 1
    mineID = AddUpgrade(raceID, "spider_mine", 1);

    if (!IsFireminesAvailable())
    {
        SetUpgradeDisabled(raceID, mineID, true);
        LogMessage("Firemines are not available");
    }

    // Ultimate 2
    tripmineID = AddUpgrade(raceID, "tripmine", 2);

    if (!IsTripminesAvailable())
    {
        SetUpgradeDisabled(raceID, tripmineID, true);
        LogMessage("Tripmines are not available");
    }

    // Ultimate 3, 4 & 2
    nadeID = AddUpgrade(raceID, "nade", 3);

    if (!IsNadesAvailable())
    {
        SetUpgradeDisabled(raceID, nadeID, true);
        LogMessage("ztf2nades are not available");
    }

    // Set the Infinite Ammo available flag
    IsInfiniteAmmoAvailable();

    // Get Configuration Data
    GetConfigFloatArray("armor_amount", g_InitialArmor, sizeof(g_InitialArmor),
                        g_InitialArmor, raceID, platingID);

    for (new level=0; level < sizeof(g_ArmorPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "armor_percent_level_%d", level);
        GetConfigFloatArray(key, g_ArmorPercent[level], sizeof(g_ArmorPercent[]),
                            g_ArmorPercent[level], raceID, platingID);
    }

    GetConfigFloatArray("speed",  g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, thrustersID);

    GetConfigFloatArray("damage_percent", g_WeaponsPercent, sizeof(g_WeaponsPercent),
                        g_WeaponsPercent, raceID, weaponsID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "firemines"))
        IsFireminesAvailable(true);
    else if (StrEqual(name, "tripmines"))
        IsTripminesAvailable(true);
    else if (StrEqual(name, "ztf2nades"))
        IsNadesAvailable(true);
    else if (StrEqual(name, "aia"))
        IsInfiniteAmmoAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "firemines"))
        m_FireminesAvailable = false;
    else if (StrEqual(name, "tripmines"))
        m_TripminesAvailable = false;
    else if (StrEqual(name, "ztf2nades"))
        m_NadesAvailable = false;
    else if (StrEqual(name, "aia"))
        m_InfiniteAmmoAvailable = false;
}

public OnMapStart()
{
    SetupSpeed();

    SetupDeniedSound();

    SetupSound(spawnWav);
    SetupSound(deathWav);
}

public OnMapEnd()
{
    ResetAllClientTimers();
}

public OnClientDisconnect(client)
{
    KillClientTimer(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);
        KillClientTimer(client);
        SetSpeed(client, -1.0, true);

        if (m_FireminesAvailable)
            TakeMines(client);

        if (m_TripminesAvailable)
            TakeTripmines(client);

        if (m_NadesAvailable)
            TakeNades(client);

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        new plating_level = GetUpgradeLevel(client,raceID,platingID);
        SetupArmor(client, plating_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new thrusters_level = GetUpgradeLevel(client,raceID,thrustersID);
        SetSpeedBoost(client, thrusters_level, true, g_SpeedLevels);

        if (m_FireminesAvailable)
        {
            new mine_level=GetUpgradeLevel(client,raceID,mineID);
            GiveMines(client, mine_level*3, mine_level*3, mine_level*2);
        }

        if (m_TripminesAvailable)
        {
            new tripmine_level=GetUpgradeLevel(client,raceID,tripmineID);
            GiveTripmines(client, tripmine_level, tripmine_level, tripmine_level);
        }

        if (m_NadesAvailable)
        {
            new nade_level=GetUpgradeLevel(client,raceID,nadeID);
            GiveNades(client, nade_level*2, nade_level*2,
                      nade_level*2, nade_level*2, false,
                      DefaultNade, _:DamageFrom_Ultimates);
        }

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav,client);

            new supply_level=GetUpgradeLevel(client,raceID,supplyID);
            if (supply_level > 0)
            {
                CreateClientTimer(client, 5.0, SupplyDepot,
                                  TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==thrustersID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==platingID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==mineID)
        {
            if (m_FireminesAvailable)
                GiveMines(client, new_level*3, new_level*3, new_level*2);
        }
        else if (upgrade==tripmineID)
        {
            if (m_TripminesAvailable)
                GiveTripmines(client, new_level, new_level, new_level);
        }
        else if (upgrade==nadeID)
        {
            if (m_NadesAvailable)
            {
                GiveNades(client, new_level*2, new_level*2,
                          new_level*2, new_level*2, false,
                          DefaultNade, _:DamageFrom_Ultimates);
            }
        }
        else if (upgrade==supplyID)
        {
            if (new_level > 0)
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 5.0, SupplyDepot,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
        }
    }
}

public OnItemPurchase(client,item)
{
    if (GetRace(client) == raceID && IsValidClientAlive(client))
    {
        if (g_bootsItem < 0)
            g_bootsItem = FindShopItem("boots");

        if (item == g_bootsItem)
        {
            new thrusters_level = GetUpgradeLevel(client,raceID,thrustersID);
            if (thrusters_level > 0)
                SetSpeedBoost(client, thrusters_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4:
            {
                new nade_level = GetUpgradeLevel(client,race,nadeID);
                if (nade_level > 0)
                {
                    if (m_NadesAvailable)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate, "%t",
                                           "PreventedFromThrowingGrenade");
                        }
                        else
                            ThrowFragNade(client, pressed);
                    }
                    else if (pressed)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, nadeID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
            }
            case 3:
            {
                new nade_level = GetUpgradeLevel(client,race,nadeID);
                if (nade_level > 0)
                {
                    if (m_NadesAvailable)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate, "%t",
                                           "PreventedFromThrowingGrenade");
                        }
                        else
                            ThrowSpecialNade(client, pressed);
                    }
                    else if (pressed)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, nadeID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
            }
            case 2:
            {
                new tripmine_level = GetUpgradeLevel(client,race,tripmineID);
                if (tripmine_level > 0)
                {
                    if (pressed)
                    {
                        if (IsMole(client))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);

                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, tripmineID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
                        }
                        else if (GetRestriction(client, Restriction_NoUltimates) ||
                                 GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate, "%t",
                                           "PreventedFromPlantingTripmine");
                        }
                        else if (m_TripminesAvailable)
                        {
                            SetTripmine(client);
                        }
                        else
                        {
                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, tripmineID, upgradeName, sizeof(upgradeName), client);
                            PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                        }
                    }
                }
                else
                {
                    new nade_level = GetUpgradeLevel(client,race,nadeID);
                    if (nade_level > 0)
                    {
                        if (m_NadesAvailable)
                        {
                            if (GetRestriction(client, Restriction_NoUltimates) ||
                                GetRestriction(client, Restriction_Stunned))
                            {
                                PrepareAndEmitSoundToClient(client,deniedWav);
                                DisplayMessage(client, Display_Ultimate, "%t",
                                               "PreventedFromThrowingGrenade");
                            }
                            else
                                ThrowFragNade(client, pressed);
                        }
                        else if (pressed)
                        {
                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, nadeID, upgradeName, sizeof(upgradeName), client);
                            PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                        }
                    }
                }
            }
            default:
            {
                new mine_level = GetUpgradeLevel(client,race,mineID);
                if (mine_level > 0)
                {
                    if (m_FireminesAvailable)
                    {
                        if (!pressed)
                        {
                            if (IsMole(client))
                            {
                                PrepareAndEmitSoundToClient(client,deniedWav);

                                decl String:upgradeName[64];
                                GetUpgradeName(raceID, mineID, upgradeName, sizeof(upgradeName), client);
                                DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
                            }
                            else if (GetRestriction(client, Restriction_NoUltimates) ||
                                     GetRestriction(client, Restriction_Stunned))
                            {
                                PrepareAndEmitSoundToClient(client,deniedWav);
                                DisplayMessage(client, Display_Ultimate, "%t",
                                               "PreventedFromPlantingMine");
                            }
                            else
                                SetMine(client, true);
                        }
                        else
                        {
                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, mineID, upgradeName, sizeof(upgradeName), client);
                            PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                        }
                    }
                }
            }
        }
    }
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        PrepareAndEmitSoundToAll(spawnWav,client);

        new plating_level = GetUpgradeLevel(client,raceID,platingID);
        SetupArmor(client, plating_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new thrusters_level = GetUpgradeLevel(client,raceID,thrustersID);
        SetSpeedBoost(client, thrusters_level, true, g_SpeedLevels);

        new supply_level=GetUpgradeLevel(client,raceID,supplyID);
        if (supply_level > 0)
        {
            CreateClientTimer(client, 5.0, SupplyDepot,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (VehicleWeapons(damage + absorbed, victim_index, attacker_index))
            return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if (assister_race == raceID)
    {
        if (VehicleWeapons(damage + absorbed, victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    KillClientTimer(victim_index);

    if (victim_race == raceID)
    {
        PrepareAndEmitSoundToAll(deathWav,victim_index);
    }
}

bool:VehicleWeapons(damage, victim_index, index)
{
    new weapons_level = GetUpgradeLevel(index, raceID, weaponsID);
    if (weapons_level > 0 &&
        !GetRestriction(index,Restriction_NoUpgrades) &&
        !GetRestriction(index,Restriction_Stunned) &&
        !GetImmunity(victim_index,Immunity_HealthTaking) &&
        !GetImmunity(victim_index,Immunity_Upgrades) &&
        !IsInvulnerable(victim_index))
    {
        if (GetRandomInt(1,100) <= GetRandomInt(30,60))
        {
            new dmgamt = RoundFloat(float(damage)*g_WeaponsPercent[weapons_level]);
            if (dmgamt > 0 && CanInvokeUpgrade(index, raceID, weaponsID, .notify=false))
            {
                HurtPlayer(victim_index, dmgamt, index,
                        "sc_vehicle_weapons", .type=DMG_BULLET,
                        .in_hurt_event=true);

                if (IsClient(victim_index))
                {
                    new Float:Origin[3];
                    GetEntityAbsOrigin(victim_index, Origin);
                    Origin[2] += 5;

                    TE_SetupSparks(Origin,Origin,255,1);
                    TE_SendEffectToAll();

                    FlashScreen(victim_index,RGBA_COLOR_RED);
                }

                return true;
            }
        }
    }
    return false;
}

public Action:SupplyDepot(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID &&
            !GetRestriction(client, Restriction_NoUpgrades) ||
            !GetRestriction(client, Restriction_Stunned))
        {
            new supply_level = GetUpgradeLevel(client,raceID,supplyID);
            if (supply_level > 0)
            {
                SupplyAmmo(client, supply_level,
                           "Supply Depot", SupplyDefault);
            }
        }
    }
    return Plugin_Continue;
}

