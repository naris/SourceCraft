/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossPhasePrism.sp
 * Description: The Protoss Warp Prism race for SourceCraft.
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
#include <tf2_objects>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <remote>
#include <jetpack>
#include <amp_node>
#include <ztf2grab>
#include <tf2teleporter>
#include <AdvancedInfiniteAmmo>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/RecallStructure"
#include "sc/clienttimer"
#include "sc/SupplyDepot"
#include "sc/SpeedBoost"
#include "sc/RecallTeam"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/shields"
#include "sc/sounds"
#include "sc/Spawn"

#include "effect/Explosion"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:summonWav[]        = "sc/ppbwht00.wav";
new const String:deathWav[]         = "sc/pshdth00.wav";
new const String:spawnWav[]         = "sc/pbldgplc.wav";
new const String:forgeWav[]         = "sc/pfowht00.wav";
new const String:cannonWav[]        = "sc/phohit00.wav";
new const String:shieldBatteryWav[] = "sc/pbaact00.wav";

new Float:g_InitialShields[]    = { 0.0, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ShieldsPercent[][2] = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.30},
                                    {0.10, 0.40},
                                    {0.20, 0.50} };

new Float:g_SpeedLevels[]       = { 1.10, 1.15, 1.20, 1.25, 1.30 };

new Float:g_BatteryRange[]      = { 150.0, 200.0, 250.0, 350.0, 500.0 };

new Float:g_WarpGateRate[]      = { 0.0, 8.0, 6.0, 3.0, 1.0 };

new Float:g_ForgeFactor[]       = { 1.0, 1.10, 1.30, 1.50, 1.80 };

new g_CannonChance[]            = {   0,     20,    40,    60,    90  };
new Float:g_CannonPercent[]     = {   0.0,  0.15,  0.30,  0.40,  0.60 };
new Float:g_CannonRange[]       = { 150.0, 200.0, 250.0, 350.0, 500.0 };

new Float:m_BatteryEnergy[]     = { 1.0, 2.0, 3.0, 4.0, 5.0 };
new m_BatteryUpgradeMetal[]     = { 1,   2,   3,   4,   5 };
new m_BatteryAmmoRockets[]      = { 1,   2,   3,   4,   5 };
new m_BatteryAmmoShells[]       = { 2,   4,   6,   8,  10 };
new m_BatteryAmmoMetal[]        = { 1,   2,   3,   4,   5 };
new m_BatteryRepair[]           = { 1,   2,   3,   4,   5 };
new m_BatteryHealth[]           = { 2,   4,   6,   8,  10 };
new m_BatteryAmmo[]             = { 1,   2,   3,   4,   5 };

new g_JetpackFuel[]             = { 0, 40, 50, 70, 90 };
new Float:g_JetpackRefuelTime[] = { 0.0, 45.0, 35.0, 25.0, 15.0 };


new raceID, shieldsID, batteriesID, forgeID, warpGateID, cannonID;
new recallID, spawnID, recallStructureID, enhancementID, jetpackID;

new cfgMaxObjects;
new cfgAllowSentries;
new bool:cfgAllowTeleport;

new bool:m_HasCannon[MAXPLAYERS+1][MAXPLAYERS+1];
new Float:m_CannonTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Warp/Phase Prism",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Warp/Phase Prism race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.objects.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.recall.phrases.txt");
    LoadTranslations("sc.supply.phrases.txt");
    LoadTranslations("sc.prism.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("prism", -1, -1, 32, .energy_rate=2.0,
                                 .faction=Protoss, .type=Robotic,
                                 .parent="probe");

    shieldsID       = AddUpgrade(raceID, "shields", 0, 0, .energy=1.0,
                                 .cost_crystals=10);

    if (GetGameType() == tf2)
    {
        cfgMaxObjects = GetConfigNum("max_objects", 3);
        cfgAllowSentries = GetConfigNum("allow_sentries", 2);
    }
    else
    {
        cfgMaxObjects = 0;
        cfgAllowSentries = 0;
    }

    forgeID = AddUpgrade(raceID, "forge", 0, 0, .cost_crystals=20);

    if (GameType != tf2 || cfgAllowSentries < 2)
    {
        batteriesID = AddUpgrade(raceID, "batteries", 0, 0, .cost_crystals=20,
                                 .desc="%prism_batteries_nosentries_desc");

        SetUpgradeDisabled(raceID, forgeID, true);
        LogMessage("Disabling Protoss Warp Prism:Forge due to configuration: sc_allow_sentries=%d (or gametype != tf2)",
                   cfgAllowSentries);
    }
    else
    {
        batteriesID = AddUpgrade(raceID, "batteries", 0, 0, .cost_crystals=30);
    }


    warpGateID = AddUpgrade(raceID, "warp_gate", 0, 0, .cost_crystals=0);

    if (GameType != tf2 || !IsTeleporterAvailable())
    {
        SetUpgradeDisabled(raceID, warpGateID, true);
        LogMessage("Disabling Protoss Warp Prism:Warp Gate due to tf2teleporter is not available (or gametype != tf2)");
    }

    cannonID    = AddUpgrade(raceID, "phase_cannon", 0, 0, .energy=2.0, .cost_crystals=30);

    if (GameType != tf2)
    {
        SetUpgradeDisabled(raceID, cannonID, true);
        LogMessage("Disabling Protoss Warp Prism:Phase Cannon due to gametype != tf2");
    }

    enhancementID   = AddUpgrade(raceID, "speed", 0, 0, .cost_crystals=0);

    // Ultimate 1
    jetpackID       = AddUpgrade(raceID, "jetpack", 1, 4, .cost_crystals=25);

    if (!IsJetpackAvailable())
    {
        SetUpgradeDisabled(raceID, jetpackID, true);
        LogMessage("Disabling Protoss Warp Prism:Gravitic Drive due to jetpack is not available");
    }

    cfgAllowTeleport = bool:GetConfigNum("allow_teleport", true);

    // Ultimate 2
    spawnID = AddUpgrade(raceID, "warp_in", 2, 0, 4, .energy=30.0,
                         .vespene=5, .cooldown=10.0, .cost_crystals=75,
                         .cooldown_type=Cooldown_SpecifiesBaseValue,
                         .desc=(cfgAllowSentries >= 2) ? "%prism_warp_in_desc"
                               : "%prism_warp_in_engyonly_desc");

    if (GameType != tf2 || cfgAllowSentries < 1 || cfgMaxObjects <= 1)
    {
        SetUpgradeDisabled(raceID, spawnID, true);
        LogMessage("Disabling Protoss Warp Prism:Warp In due to configuration: sc_allow_sentries=%d, sc_maxobjects=%d (or gametype != tf2)",
                   cfgAllowSentries, cfgMaxObjects);
    }

    // Ultimate 3
    recallStructureID = AddUpgrade(raceID, "recall_structure", 3, 1, 1, .energy=30.0,
                                   .vespene=5, .cooldown=5.0, .cost_crystals=50);

    if (GameType != tf2 || !cfgAllowTeleport || cfgAllowSentries < 1)
    {
        SetUpgradeDisabled(raceID, recallStructureID, true);
        LogMessage("Disabling Protoss Warp Prism:Recall Structure due to configuration: sc_allow_sentries=%d, sc_allow_teleport=%d (or gametype != tf2)",
                   cfgAllowSentries, cfgAllowTeleport);
    }

    // Ultimate 4
    recallID = AddUpgrade(raceID, "recall_team", 4, 8, 1, .energy=30.0,
                          .vespene=5, .cooldown=5.0, .cost_crystals=50);

    if (!cfgAllowTeleport)
    {
        SetUpgradeDisabled(raceID, recallID, true);
        LogMessage("Disabling Protoss Warp Prism:Recall Team due to configuration: sc_allow_teleport=%d",
                   cfgAllowTeleport);
    }

    // Set the Infinite Ammo available flag
    IsInfiniteAmmoAvailable();

    // Get Configuration Data
    GetConfigFloatArray("shields_amount", g_InitialShields, sizeof(g_InitialShields),
                        g_InitialShields, raceID, shieldsID);

    for (new level=0; level < sizeof(g_ShieldsPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "shields_percent_level_%d", level);
        GetConfigFloatArray(key, g_ShieldsPercent[level], sizeof(g_ShieldsPercent[]),
                            g_ShieldsPercent[level], raceID, shieldsID);
    }

    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, enhancementID);

    GetConfigArray("chance", g_CannonChance, sizeof(g_CannonChance),
                   g_CannonChance, raceID, cannonID);

    GetConfigFloatArray("damage_percent", g_CannonPercent, sizeof(g_CannonPercent),
                        g_CannonPercent, raceID, cannonID);

    GetConfigArray("upgrade", m_BatteryUpgradeMetal, sizeof(m_BatteryUpgradeMetal),
                   m_BatteryUpgradeMetal, raceID, batteriesID);

    GetConfigArray("rockets", m_BatteryAmmoRockets, sizeof(m_BatteryAmmoRockets),
                   m_BatteryAmmoRockets, raceID, batteriesID);

    GetConfigArray("shells", m_BatteryAmmoShells, sizeof(m_BatteryAmmoShells),
                   m_BatteryAmmoShells, raceID, batteriesID);

    GetConfigArray("metal", m_BatteryAmmoMetal, sizeof(m_BatteryAmmoMetal),
                   m_BatteryAmmoMetal, raceID, batteriesID);

    GetConfigArray("repair", m_BatteryRepair, sizeof(m_BatteryRepair),
                   m_BatteryRepair, raceID, batteriesID);

    GetConfigArray("health", m_BatteryHealth, sizeof(m_BatteryHealth),
                   m_BatteryHealth, raceID, batteriesID);

    GetConfigArray("energy", m_BatteryEnergy, sizeof(m_BatteryEnergy),
                   m_BatteryEnergy, raceID, batteriesID);

    GetConfigArray("ammo", m_BatteryAmmo, sizeof(m_BatteryAmmo),
                   m_BatteryAmmo, raceID, batteriesID);

    GetConfigArray("fuel", g_JetpackFuel, sizeof(g_JetpackFuel),
                   g_JetpackFuel, raceID, jetpackID);

    GetConfigFloatArray("refuel_time", g_JetpackRefuelTime, sizeof(g_JetpackRefuelTime),
                        g_JetpackRefuelTime, raceID, jetpackID);

    if (GameType == tf2)
    {
        GetConfigFloatArray("factor", g_ForgeFactor, sizeof(g_ForgeFactor),
                            g_ForgeFactor, raceID, forgeID);

        GetConfigFloatArray("range", g_BatteryRange, sizeof(g_BatteryRange),
                            g_BatteryRange, raceID, batteriesID);

        GetConfigFloatArray("range", g_WarpGateRate, sizeof(g_WarpGateRate),
                            g_WarpGateRate, raceID, warpGateID);

        GetConfigFloatArray("range", g_CannonRange, sizeof(g_CannonRange),
                            g_CannonRange, raceID, cannonID);

        for (new level=0; level < sizeof(m_SpawnAmpRange); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "amp_range_level_%d", level);
            GetConfigFloatArray(key, m_SpawnAmpRange[level], sizeof(m_SpawnAmpRange[]),
                                m_SpawnAmpRange[level], raceID, spawnID);
        }

        for (new level=0; level < sizeof(m_SpawnNodeRange); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "node_range_level_%d", level);
            GetConfigFloatArray(key, m_SpawnNodeRange[level], sizeof(m_SpawnNodeRange[]),
                                m_SpawnNodeRange[level], raceID, spawnID);
        }

        for (new level=0; level < sizeof(m_SpawnNodeRegen); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "node_regen_level_%d", level);
            GetConfigArray(key, m_SpawnNodeRegen[level], sizeof(m_SpawnNodeRegen[]),
                           m_SpawnNodeRegen[level], raceID, spawnID);
        }

        for (new level=0; level < sizeof(m_SpawnNodeShells); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "node_shells_level_%d", level);
            GetConfigArray(key, m_SpawnNodeShells[level], sizeof(m_SpawnNodeShells[]),
                           m_SpawnNodeShells[level], raceID, spawnID);
        }

        GetConfigArray("node_rockets", m_SpawnNodeRockets, sizeof(m_SpawnNodeRockets),
                       m_SpawnNodeRockets, raceID, spawnID);
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "jetpack"))
        IsJetpackAvailable(true);
    else if (StrEqual(name, "ztf2grab"))
        IsGravgunAvailable(true);
    else if (StrEqual(name, "tf2teleporter"))
        IsTeleporterAvailable(true);
    else if (StrEqual(name, "remote"))
        IsBuildAvailable(true);
    else if (StrEqual(name, "amp_node"))
        IsAmpNodeAvailable(true);
    else if (StrEqual(name, "aia"))
        IsInfiniteAmmoAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "tf2teleporter"))
        m_TeleporterAvailable = false;
    else if (StrEqual(name, "jetpack"))
        m_JetpackAvailable = false;
    else if (StrEqual(name, "remote"))
        m_BuildAvailable = false;
    else if (StrEqual(name, "ztf2grab"))
        m_GravgunAvailable = false;
    else if (StrEqual(name, "amp_node"))
        m_AmpNodeAvailable = false;
    else if (StrEqual(name, "aia"))
        m_InfiniteAmmoAvailable = false;
}

public OnMapStart()
{
    SetupHaloSprite();
    SetupBeamSprite();
    SetupExplosion();
    SetupSpeed();

    SetupSpawn();
    //SetupDeniedSound();

    SetupRecallSounds();


    SetupSound(spawnWav);
    SetupSound(forgeWav);
    SetupSound(deathWav);
    SetupSound(summonWav);
    SetupSound(cannonWav);
    SetupSound(shieldBatteryWav);
}

public OnMapEnd()
{
    ResetAllClientTimers();
}

public OnClientDisconnect(client)
{
    KillClientTimer(client);
}

public OnPlayerAuthed(client)
{
    m_CannonTime[client] = 0.0;
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        KillClientTimer(client);
        DestroyBuildings(client, false);

        ResetShields(client);
        SetSpeed(client, -1.0, true);

        m_CannonTime[client] = 0.0;

        if (m_TeleporterAvailable)
            SetTeleporter(client, 0.0);

        if (m_BuildAvailable)
            ResetBuild(client);

        if (m_JetpackAvailable)
            TakeJetpack(client);

        // Reset all the cannons
        for (new index=1;index<=MaxClients;index++)
            m_HasCannon[client][index] = false;
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_CannonTime[client] = 0.0;

        new enhancement_level = GetUpgradeLevel(client,raceID,enhancementID);
        SetSpeedBoost(client, enhancement_level, true, g_SpeedLevels);

        new teleporter_level = GetUpgradeLevel(client,raceID,warpGateID);
        SetupTeleporter(client, teleporter_level);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        if (GetGameType() == tf2 && m_BuildAvailable)
        {
            new spawn_num = RoundToCeil((float(GetUpgradeLevel(client,raceID,spawnID)) / 2.0) + 0.5);
            if (spawn_num > cfgMaxObjects)
                spawn_num = cfgMaxObjects;
            GiveBuild(client, spawn_num, spawn_num, spawn_num, spawn_num);
        }

        if (IsValidClientAlive(client))
        {
            new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
            SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

            CreateClientTimer(client, 1.0, BatteryTimer,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
        if (upgrade==warpGateID)
            SetupTeleporter(client, new_level);
        else if (upgrade==jetpackID)
            SetupJetpack(client, new_level);
        else if (upgrade==enhancementID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, .upgrade=true);
        }
        else if (upgrade==spawnID)
        {
            if (m_BuildAvailable)
            {
                new spawn_num = RoundToCeil((float(new_level) / 2.0) + 0.5);
                if (spawn_num > cfgMaxObjects)
                    spawn_num = cfgMaxObjects;
                GiveBuild(client, spawn_num, spawn_num, spawn_num, spawn_num);
            }
        }
    }
}

public OnItemPurchase(client,item)
{
    new race=GetRace(client);
    if (race == raceID && IsValidClientAlive(client))
    {
        if (g_bootsItem < 0)
            g_bootsItem = FindShopItem("boots");

        if (item == g_bootsItem)
        {
            new enhancement_level = GetUpgradeLevel(client,race,enhancementID);
            SetSpeedBoost(client, enhancement_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID)
    {
        switch (arg)
        {
            case 4:
            {
                new recall_level=GetUpgradeLevel(client,race,recallID);
                if (recall_level > 0)
                    RecallTeam(client,race,recallID);
            }
            case 3:
            {
                if (pressed)
                {
                    new recall_structure_level = GetUpgradeLevel(client,race,recallStructureID);
                    if (recall_structure_level && GameType == tf2 && cfgAllowTeleport &&
                        (cfgAllowSentries >= 2) || (cfgAllowSentries >= 1 && TF2_GetPlayerClass(client) == TFClass_Engineer))
                    {
                        RecallStructure(client,race,recallStructureID, true, cfgAllowSentries == 1);
                    }
                    else
                    {
                        new recall_level=GetUpgradeLevel(client,race,recallID);
                        if (recall_level > 0)
                            RecallTeam(client,race,recallID);
                    }
                }
            }
            case 2:
            {
                if (pressed)
                {
                    new spawn_level = GetUpgradeLevel(client,race,spawnID);
                    if (spawn_level > 0 && cfgAllowSentries >= 1)
                    {
                        Spawn(client, spawn_level, race, spawnID, cfgMaxObjects,
                              true, true, (cfgAllowSentries < 2), spawnWav,
                              "WarpInTitle");
                    }
                    else
                    {
                        new recall_structure_level = GetUpgradeLevel(client,race,recallStructureID);
                        if (recall_structure_level && GameType == tf2 && cfgAllowTeleport &&
                            ((cfgAllowSentries >= 2) || (cfgAllowSentries >= 1 && TF2_GetPlayerClass(client) == TFClass_Engineer)))
                        {
                            RecallStructure(client,race,recallStructureID, true, cfgAllowSentries == 1);
                        }
                        else
                        {
                            new recall_level=GetUpgradeLevel(client,race,recallID);
                            if (recall_level > 0)
                                RecallTeam(client,race,recallID);
                        }
                    }
                }
            }
            default:
            {
                new jetpack_level = GetUpgradeLevel(client,raceID,jetpackID);
                if (jetpack_level > 0)
                {
                    if (m_JetpackAvailable)
                    {
                        if (pressed)
                        {
                            if (GetRestriction(client, Restriction_NoUltimates) ||
                                GetRestriction(client, Restriction_Grounded) ||
                                GetRestriction(client, Restriction_Stunned))
                            {
                                PrepareAndEmitSoundToAll(deniedWav, client);
                            }
                            else
                                StartJetpack(client);
                        }
                        else
                            StopJetpack(client);
                    }
                    else if (pressed)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, jetpackID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
                else
                {
                    new spawn_level = GetUpgradeLevel(client,race,spawnID);
                    if (spawn_level > 0 && cfgAllowSentries >= 1)
                    {
                        Spawn(client, spawn_level, race, spawnID, cfgMaxObjects,
                              true, true, (cfgAllowSentries < 2), spawnWav,
                              "WarpInTitle");
                    }
                    else
                    {
                        new recall_structure_level = GetUpgradeLevel(client,race,recallStructureID);
                        if (recall_structure_level && GameType == tf2 && cfgAllowTeleport &&
                            ((cfgAllowSentries >= 2) || (cfgAllowSentries >= 1 && TF2_GetPlayerClass(client) == TFClass_Engineer)))
                        {
                            RecallStructure(client,race,recallStructureID, true, cfgAllowSentries == 1);
                        }
                        else
                        {
                            new recall_level=GetUpgradeLevel(client,race,recallID);
                            if (recall_level > 0)
                                RecallTeam(client,race,recallID);
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
        PrepareAndEmitSoundToAll(summonWav,client);

        m_CannonTime[client] = 0.0;

        new enhancement_level = GetUpgradeLevel(client,raceID,enhancementID);
        SetSpeedBoost(client, enhancement_level, true, g_SpeedLevels);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        if (m_BuildAvailable)
        {
            new spawn_num = RoundToCeil((float(GetUpgradeLevel(client,raceID,spawnID)) / 2.0) + 0.5);
            if (spawn_num > cfgMaxObjects)
                spawn_num = cfgMaxObjects;
            GiveBuild(client, spawn_num, spawn_num, spawn_num, spawn_num);
        }

        CreateClientTimer(client, 1.0, BatteryTimer,
                          TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 && attacker_index != victim_index &&
        (attacker_race == raceID || HasCannon(attacker_index)))
    {
        if (PhaseCannon(damage + absorbed, victim_index, attacker_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if ((assister_race == raceID || HasCannon(assister_index)))
    {
        if (PhaseCannon(damage + absorbed, victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_race == raceID)
    {
        KillClientTimer(victim_index);

        PrepareAndEmitSoundToAll(deathWav,victim_index);
    }
}

public OnPlayerBuiltObject(Handle:event, client, object, TFObjectType:type)
{
    if (object > 0 && type != TFObject_Sapper && cfgAllowSentries >= 1)
    {
        if (IsValidClientNotSpec(client) && GetRace(client) == raceID &&
            !GetRestriction(client, Restriction_NoUpgrades) &&
            !GetRestriction(client, Restriction_Stunned))
        {
            if (GetUpgradeLevel(client,raceID,forgeID) > 0)
            {
                new Float:time = (GetEntPropFloat(object, Prop_Send, "m_flPercentageConstructed") >= 1.0) ? 0.1 : 10.0;
                CreateTimer(time, ForgeTimer, EntIndexToEntRef(object), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public Action:ForgeTimer(Handle:timer,any:ref)
{
    new object = EntRefToEntIndex(ref);
    if (object > 0 && IsValidEntity(object) && IsValidEdict(object))
    {
        new builder = GetEntPropEnt(object, Prop_Send, "m_hBuilder");
        if (builder > 0 && GetRace(builder) == raceID &&
            !GetRestriction(builder, Restriction_NoUpgrades) &&
            !GetRestriction(builder, Restriction_Stunned))
        {
            if (GetEntPropFloat(object, Prop_Send, "m_flPercentageConstructed") >= 1.0)
            {
                new build_level = GetUpgradeLevel(builder,raceID,forgeID);
                if (build_level > 0)
                {
                    new health = GetEntProp(object, Prop_Data, "m_iMaxHealth");
                    health = RoundToNearest(float(health)*g_ForgeFactor[build_level]);

                    new maxHealth = TF2_SentryHealth[4]; //[iLevel+1];
                    if (health > maxHealth)
                        health = maxHealth;

                    SetEntProp(object, Prop_Data, "m_iMaxHealth", health);
                    SetEntityHealth(object, health);

                    if (TF2_GetObjectType(object) == TFObject_Sentry)
                    {
                        new iShells = GetEntProp(object, Prop_Send, "m_iAmmoShells");
                        iShells = RoundToNearest(float(iShells)*g_ForgeFactor[build_level]);
                        if (iShells > 511)
                            iShells = 511;
                        SetEntProp(object, Prop_Send, "m_iAmmoShells", iShells);

                        new iRockets = GetEntProp(object, Prop_Send, "m_iAmmoRockets");
                        if (iRockets > 0)
                        {
                            iRockets = RoundToNearest(float(iRockets)*g_ForgeFactor[build_level]);
                            if (iRockets > 63)
                                iRockets = 63;
                            SetEntProp(object, Prop_Send, "m_iAmmoRockets", iRockets);
                        }
                    }

                    PrepareAndEmitSoundToAll(forgeWav,object);
                }
            }
            else
            {
                CreateTimer(1.0, ForgeTimer, object, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    return Plugin_Stop;
}

public Action:BatteryTimer(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientNotSpec(client) && GetRace(client) == raceID &&
        !GetRestriction(client,Restriction_NoUpgrades) &&
        !GetRestriction(client,Restriction_Stunned))
    {
        // Reset all the cannons
        for (new index=1;index<=MaxClients;index++)
            m_HasCannon[client][index] = false;

        if (GetGameType() != tf2)
            return Plugin_Continue;

        new battery_level = GetUpgradeLevel(client,raceID,batteriesID);
        new Float:battery_range=g_BatteryRange[battery_level];

        new cannon_level = GetUpgradeLevel(client,raceID,cannonID);
        new Float:cannon_range=g_CannonRange[cannon_level];

        new Float:energy_amount = m_BatteryEnergy[battery_level];
        new upgrade_amount = m_BatteryUpgradeMetal[battery_level];
        new rocket_amount = m_BatteryAmmoRockets[battery_level];
        new shells_amount = m_BatteryAmmoShells[battery_level];
        new metal_amount = m_BatteryAmmoMetal[battery_level];
        new repair_amount = m_BatteryRepair[battery_level];
        new health_amount = m_BatteryHealth[battery_level];
        new ammo_amount = m_BatteryAmmo[battery_level];

        new team = GetClientTeam(client);
        new maxentities = GetMaxEntities();
        for (new ent = MaxClients + 1; ent <= maxentities; ent++)
        {
            if (IsValidEntity(ent) && IsValidEdict(ent))
            {
                new TFExtObjectType:type=TF2_GetExtObjectType(ent, true);
                if (type != TFExtObject_Unknown)
                {
                    if (GetEntPropEnt(ent, Prop_Send, "m_hBuilder") == client &&
                        GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") >= 1.0)
                    {
                        if (cfgAllowSentries >= 1)
                        {
                            new iLevel = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
                            if (iLevel < 3)
                            {
                                new iUpgrade = GetEntProp(ent, Prop_Send, "m_iUpgradeMetal");
                                if (iUpgrade < TF2_MaxUpgradeMetal)
                                {
                                    iUpgrade += upgrade_amount;
                                    if (iUpgrade > TF2_MaxUpgradeMetal)
                                        iUpgrade = TF2_MaxUpgradeMetal;
                                    SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", iUpgrade);
                                }
                            }
                            else
                            {
                                switch (type)
                                {
                                    case TFExtObject_Dispenser:
                                    {
                                        new iMetal = GetEntProp(ent, Prop_Send, "m_iAmmoMetal");
                                        if (iMetal < TF2_MaxDispenserMetal)
                                        {
                                            iMetal += metal_amount;
                                            if (iMetal > TF2_MaxDispenserMetal)
                                                iMetal = TF2_MaxDispenserMetal;
                                            SetEntProp(ent, Prop_Send, "m_iAmmoMetal", iMetal);
                                        }
                                    }
                                    case TFExtObject_Sentry:
                                    {
                                        new maxShells = TF2_MaxSentryShells[iLevel];
                                        new iShells = GetEntProp(ent, Prop_Send, "m_iAmmoShells");
                                        if (iShells < TF2_MaxSentryShells[iLevel])
                                        {
                                            iShells += shells_amount;
                                            if (iShells > maxShells)
                                                iShells = maxShells;
                                            SetEntProp(ent, Prop_Send, "m_iAmmoShells", iShells);
                                        }

                                        new maxRockets = TF2_MaxSentryRockets[iLevel];
                                        new iRockets = GetEntProp(ent, Prop_Send, "m_iAmmoRockets");
                                        if (iRockets < TF2_MaxSentryRockets[iLevel])
                                        {
                                            iRockets += rocket_amount;
                                            if (iRockets > maxRockets)
                                                iRockets = maxRockets;
                                            SetEntProp(ent, Prop_Send, "m_iAmmoRockets", iRockets);
                                        }
                                    }
                                }
                            }

                            new max_health = GetEntProp(ent, Prop_Data, "m_iMaxHealth");
                            new health = GetEntProp(ent, Prop_Send, "m_iHealth");
                            if (health < max_health)
                            {
                                health += repair_amount;
                                if (health > max_health)
                                    health = max_health;

                                SetEntProp(ent, Prop_Send, "m_iHealth", health);
                            }
                        }

                        // Heal/Supply/Arm teammates

                        new Float:pos[3];
                        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

                        new count=0;
                        new alt_count=0;
                        new list[MaxClients+1];
                        new alt_list[MaxClients+1];
                        for (new index=1;index<=MaxClients;index++)
                        {
                            if (IsClientInGame(index) && IsPlayerAlive(index))
                            {
                                if (index == client || GetClientTeam(index) == team)
                                {
                                    if (!GetSetting(index, Disable_Beacons) &&
                                        !GetSetting(index, Remove_Queasiness))
                                    {
                                        if (GetSetting(index, Reduce_Queasiness))
                                            alt_list[alt_count++] = index;
                                        else
                                            list[count++] = index;
                                    }

                                    decl Float:indexLoc[3];
                                    GetClientAbsOrigin(index, indexLoc);
                                    if (TraceTargetIndex(ent, index, pos, indexLoc))
                                    {
                                        m_HasCannon[client][index] = IsPointInRange(pos,indexLoc,cannon_range);

                                        if (IsPointInRange(pos,indexLoc,battery_range))
                                        {
                                            if (HealPlayer(index,health_amount) > 0)
                                            {
                                                PrepareAndEmitSoundToAll(shieldBatteryWav,ent);
                                            }

                                            IncrementEnergy(index, energy_amount, true);
                                            SupplyAmmo(index, ammo_amount, "Shield Battery", 
                                                       (GetRandomInt(0,10) > 8) ? SupplyDefault
                                                                                : SupplySecondary);
                                        }
                                    }
                                }
                            }
                        }

                        new haloSprite      = HaloSprite();
                        new beamSprite      = BeamSprite();

                        static const ammoColor[4] = {255, 225, 0, 255};
                        static const cannonColor[4] = {255, 97, 3, 255};
                        static const healingColor[4] = {0, 255, 0, 255};

                        if (count > 0)
                        {
                            TE_SetupBeamRingPoint(pos, 10.0, battery_range, beamSprite, haloSprite,
                                                  0, 15, 0.5, 5.0, 0.0, healingColor, 10, 0);
                            TE_Send(list, count, 0.0);

                            TE_SetupBeamRingPoint(pos, 10.0, battery_range, beamSprite, haloSprite,
                                                  0, 10, 0.6, 10.0, 0.5, ammoColor, 10, 0);
                            TE_Send(list, count, 0.0);

                            TE_SetupBeamRingPoint(pos, 10.0, cannon_range, beamSprite, haloSprite,
                                                  0, 5, 0.7, 15.0, 1.0, cannonColor, 10, 0);
                            TE_Send(list, count, 0.0);
                        }

                        if (alt_count > 0)
                        {
                            TE_SetupBeamRingPoint(pos, battery_range-10.0, battery_range, beamSprite, haloSprite,
                                                  0, 15, 0.5, 5.0, 0.0, healingColor, 10, 0);
                            TE_Send(alt_list, alt_count, 0.0);

                            TE_SetupBeamRingPoint(pos, battery_range-10.0, battery_range, beamSprite, haloSprite,
                                                  0, 10, 0.6, 10.0, 0.5, ammoColor, 10, 0);
                            TE_Send(alt_list, alt_count, 0.0);

                            TE_SetupBeamRingPoint(pos, cannon_range-10.0, cannon_range, beamSprite, haloSprite,
                                                  0, 5, 0.7, 15.0, 1.0, cannonColor, 10, 0);
                            TE_Send(alt_list, alt_count, 0.0);
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

SetupTeleporter(client, level)
{
    if (m_TeleporterAvailable)
        SetTeleporter(client, g_WarpGateRate[level]);
}

SetupJetpack(client, level)
{
    if (m_JetpackAvailable)
    {
        if (level > 0)
        {
            if (level >= sizeof(g_JetpackFuel))
            {
                LogError("%d:%N has too many levels in ProtossPhasePrism::GraviticDrive level=%d, max=%d",
                         client,ValidClientIndex(client),level,sizeof(g_JetpackFuel));

                level = sizeof(g_JetpackFuel)-1;
            }
            GiveJetpack(client, g_JetpackFuel[level], g_JetpackRefuelTime[level],
                        .explode = (level > 2), .burn = (level > 3));
        }
        else
            TakeJetpack(client);
    }
}

bool:HasCannon(index)
{
    for (new client=1;client<=MaxClients;client++)
    {
        if (m_HasCannon[client][index])
            return true;
    }
    return false;
}

bool:PhaseCannon(damage, victim_index, index)
{
    new cannon_level = GetUpgradeLevel(index,raceID,cannonID);
    if (cannon_level > 0)
    {
        if (!GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_HealthTaking) &&
            !GetImmunity(victim_index,Immunity_Upgrades) &&
            !IsInvulnerable(victim_index))
        {
            new Float:lastTime = m_CannonTime[index];
            new Float:interval = GetGameTime() - lastTime;
            if (lastTime == 0.0 || interval > 0.25)
            {
                if (GetRandomInt(1,100) <= g_CannonChance[cannon_level])
                {
                    new health_take = RoundToFloor(float(damage)*g_CannonPercent[cannon_level]);
                    if (health_take > 0)
                    {
                        if (CanInvokeUpgrade(index, raceID, cannonID, .notify=false))
                        {
                            if (interval == 0.0 || interval >= 2.0)
                            {
                                new Float:Origin[3];
                                GetEntityAbsOrigin(victim_index, Origin);
                                Origin[2] += 5;

                                TE_SetupExplosion(Origin, Explosion(), 5.0, 1,0, 5, 10);
                                TE_SendEffectToAll();
                            }

                            PrepareAndEmitSoundToAll(cannonWav,victim_index);
                            FlashScreen(victim_index,RGBA_COLOR_RED);

                            m_CannonTime[index] = GetGameTime();
                            HurtPlayer(victim_index, health_take, index,
                                       "sc_phase_cannon", .type=DMG_ENERGYBEAM,
                                       .in_hurt_event=true);
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

