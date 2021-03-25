/**
 * vim: set ai et ts=4 sw=4 :
 * File: ZergHiveQueen.sp
 * Description: The Zerg Hive Queen race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_objects>
#include <tf2_player>
#include <tf2_flag>
#include <TeleportPlayer>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/ztf2grab>
#include <libtf2/remote>
#include <libtf2/amp_node>
#include <libtf2/tf2teleporter>
#include <libtf2/AdvancedInfiniteAmmo>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/SupplyDepot"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/Mutate"
#include "sc/burrow"
#include "sc/sounds"
#include "sc/Spawn"
#include "sc/armor"

#include "effect/Lightning"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:evolveWav[] = "sc/zhawht00.wav";
new const String:deathWav[] = "sc/zbldgdth.wav";
new const String:spineWav[] = "sc/zquhit00.wav";
new const String:spawnWav[] = "sc/zbldgplc.wav";
new const String:toxicWav[] = "sc/zsbwht00.wav";
new const String:tunnelWav[] = "sc/zovtra00.wav";
new const String:transfusionWav[] = "sc/zcbwht00.wav";

new const String:g_ArmorName[] = "Carapace";
new Float:g_InitialArmor[]     = { 0.15, 0.25, 0.33, 0.50, 0.75 };
new Float:g_ArmorPercent[][2]  = { {0.00, 0.10},
                                   {0.01, 0.20},
                                   {0.05, 0.30},
                                   {0.10, 0.40},
                                   {0.20, 0.50} };

new Float:g_SpinePercent[]      = { 0.30, 0.40, 0.50, 0.60, 0.70 };
new Float:g_NydusCanalRate[]    = { 0.0, 8.0, 6.0, 3.0, 1.0 };
new Float:g_TransfusionRange[]  = { 150.0, 200.0, 250.0, 350.0, 500.0 };
new Float:g_ToxicCreepRange[]   = { 150.0, 200.0, 250.0, 350.0, 500.0 };
new g_ToxicCreepDamage[][2]     = { { 0, 1 },
                                    { 0, 3 },
                                    { 1, 5 },
                                    { 2, 8 },
                                    { 4, 10} };

new raceID, carapaceID, regenerationID, transfusionID, burrowID;
new nydusCanalID, spinesID, mutateID, tunnelID, toxicID, spawnID;

new cfgMaxObjects;
new cfgAllowSentries;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Zerg Hive Queen",
    author = "-=|JFH|=-Naris",
    description = "The Zerg Hive Queen race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.recall.phrases.txt");
    LoadTranslations("sc.mutate.phrases.txt");
    LoadTranslations("sc.supply.phrases.txt");
    LoadTranslations("sc.objects.phrases.txt");
    LoadTranslations("sc.hive_queen.phrases.txt");

    GetGameType();

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    if (GameType == tf2)
    {
        cfgMaxObjects = GetConfigNum("max_objects", 3);
        cfgAllowSentries = GetConfigNum("allow_sentries", 2);

        IsAmpNodeAvailable();
        IsGravgunAvailable();
    }
    else
    {
        cfgMaxObjects    = 0;
        cfgAllowSentries = 0;
    }

    raceID          = CreateRace("hive_queen", -1, -1, 32, .faction=Zerg,
                                 .type=Biological, .parent="drone");

    carapaceID      = AddUpgrade(raceID, "armor", 0, 0, .cost_crystals=5);
    regenerationID  = AddUpgrade(raceID, "regeneration", 0, 0, .cost_crystals=10);

    transfusionID   = AddUpgrade(raceID, "transfusion", 0, 0, .cost_crystals=75,
                                 .desc=(cfgAllowSentries >= 2) ?
                                 "%hive_queen_transfusion_desc" : 
                                 "%hive_queen_transfusion_nosentries_desc");

    toxicID         = AddUpgrade(raceID, "toxic_creep", 0, 0, .cost_crystals=25);

    spinesID        = AddUpgrade(raceID, "spines", 0, 0, .energy=2.0, .cost_crystals=20);

    nydusCanalID    = AddUpgrade(raceID, "teleporter", 0, 0, .cost_crystals=0);

    // Ultimate 1
    mutateID        = AddUpgrade(raceID, "mutate", 1, 1, .energy=0.0, .vespene=0, .cost_crystals=65,
                                 .cooldown=0.0, .cooldown_type=Cooldown_SpecifiesBaseValue,
                                 .desc=(cfgAllowSentries >= 2) ? "%hive_queen_mutate_desc"
                                       : "%hive_queen_mutate_engyonly_desc");

    // Ultimate 4
    spawnID         = AddUpgrade(raceID, "spawn", 4, 4, .energy=30.0, .vespene=5, .cost_crystals=75,
                                 .cooldown=10.0, .cooldown_type=Cooldown_SpecifiesBaseValue,
                                 .desc=(cfgAllowSentries >= 2) ? "%hive_queen_spawn_desc"
                                       : "%hive_queen_spawn_engyonly_desc");

    // Ultimate 2
    burrowID        = AddBurrowUpgrade(raceID, 2, 0, 2, 1);

    // Ultimate 3
    tunnelID = AddUpgrade(raceID, "tunnel", 3, 0, 1, .energy=30.0,
                          .cooldown=0.0, .cost_crystals=30);

    // Disable inapplicable upgrades
    if (GameType != tf2)
    {
        SetUpgradeDisabled(raceID, transfusionID, true);
        SetUpgradeDisabled(raceID, toxicID, true);
        SetUpgradeDisabled(raceID, tunnelID, true);
        LogMessage("Disabling Zerg Hive Queen:Transfusion, Toxic Creep & Deep Tunnel due to gametype != tf2)");
    }

    if (!IsTeleporterAvailable())
    {
        SetUpgradeDisabled(raceID, nydusCanalID, true);
        LogMessage("Disabling Zerg Hive Queen:Transfusion & Toxic Creep due to tf2teleporter is not available (or gametype != tf2)");
    }

    if (!IsBuildAvailable())
    {
        SetUpgradeDisabled(raceID, tunnelID, true);
        LogMessage("Disabling Zerg Hive Queen:Deep Tunnel due to remote is not available (or gametype != tf2)");
    }

    if (!IsBuildAvailable() || cfgAllowSentries < 1)
    {
        SetUpgradeDisabled(raceID, mutateID, true);
        LogMessage("Disabling Zerg Hive Queen:Mutate due to configuration: sc_allow_sentries=%d or remote is not available (or gametype != tf2)",
                   cfgAllowSentries);
    }

    if (GameType != tf2 || cfgAllowSentries < 1 || cfgMaxObjects <= 1)
    {
        SetUpgradeDisabled(raceID, spawnID, true);
        LogMessage("Disabling Zerg Hive Queen:Spawn Structure due to configuration: sc_allow_sentries=%d, sc_maxobjects=%d (or gametype != tf2)",
                   cfgAllowSentries, cfgMaxObjects);
    }

    // Set the Infinite Ammo available flag
    IsInfiniteAmmoAvailable();

    // Get Configuration Data
    GetConfigFloatArray("armor_amount", g_InitialArmor, sizeof(g_InitialArmor),
                        g_InitialArmor, raceID, carapaceID);

    for (new level=0; level < sizeof(g_ArmorPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "armor_percent_level_%d", level);
        GetConfigFloatArray(key, g_ArmorPercent[level], sizeof(g_ArmorPercent[]),
                            g_ArmorPercent[level], raceID, carapaceID);
    }

    GetConfigFloatArray("damage_percent",  g_SpinePercent, sizeof(g_SpinePercent),
                        g_SpinePercent, raceID, spinesID);

    if (GameType == tf2)
    {
        GetConfigFloatArray("range",  g_TransfusionRange, sizeof(g_TransfusionRange),
                            g_TransfusionRange, raceID, transfusionID);

        GetConfigFloatArray("range",  g_ToxicCreepRange, sizeof(g_ToxicCreepRange),
                            g_ToxicCreepRange, raceID, toxicID);

        for (new level=0; level < sizeof(g_ToxicCreepDamage); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "damage_level_%d", level);
            GetConfigArray(key, g_ToxicCreepDamage[level], sizeof(g_ToxicCreepDamage[]),
                           g_ToxicCreepDamage[level], raceID, toxicID);
        }

        m_MutateDisableLevel = GetConfigNum("disable_level", 0, raceID, mutateID);
        m_MutateMultiplyEnergy = bool:GetConfigNum("multiply_energy", false, raceID, mutateID);
        m_MutateMultiplyVespene = bool:GetConfigNum("multiply_vespene", false, raceID, mutateID);

        for (new level=0; level < sizeof(m_MutateAmpRange); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "amp_range_level_%d", level);
            GetConfigFloatArray(key, m_MutateAmpRange[level], sizeof(m_MutateAmpRange[]),
                                m_MutateAmpRange[level], raceID, mutateID);
        }

        for (new level=0; level < sizeof(m_MutateNodeRange); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "node_range_level_%d", level);
            GetConfigFloatArray(key, m_MutateNodeRange[level], sizeof(m_MutateNodeRange[]),
                                m_MutateNodeRange[level], raceID, mutateID);
        }

        for (new level=0; level < sizeof(m_MutateNodeRegen); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "node_regen_level_%d", level);
            GetConfigArray(key, m_MutateNodeRegen[level], sizeof(m_MutateNodeRegen[]),
                           m_MutateNodeRegen[level], raceID, mutateID);
        }

        for (new level=0; level < sizeof(m_MutateNodeShells); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "node_shells_level_%d", level);
            GetConfigArray(key, m_MutateNodeShells[level], sizeof(m_MutateNodeShells[]),
                           m_MutateNodeShells[level], raceID, mutateID);
        }

        GetConfigArray("node_rockets", m_MutateNodeRockets, sizeof(m_MutateNodeRockets),
                       m_MutateNodeRockets, raceID, mutateID);

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
    if (StrEqual(name, "remote"))
        IsBuildAvailable(true);
    else if (StrEqual(name, "tf2teleporter"))
        IsTeleporterAvailable(true);
    else if (StrEqual(name, "ztf2grab"))
        IsGravgunAvailable(true);
    else if (StrEqual(name, "amp_node"))
        IsAmpNodeAvailable(true);
    else if (StrEqual(name, "aia"))
        IsInfiniteAmmoAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "tf2teleporter"))
        m_TeleporterAvailable = false;
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
    SetupLightning();
    SetupBeamSprite();
    SetupHaloSprite();

    SetupDeniedSound();
    SetupMutate();
    //SetupErrorSound();
    //SetupButtonSound();
    //SetupSpawn();

    SetupSound(evolveWav);
    SetupSound(deathWav);
    SetupSound(spineWav);
    SetupSound(spawnWav);
    SetupSound(toxicWav);
    SetupSound(tunnelWav);
    SetupSound(mutateWav);
    SetupSound(mutateErr);
    SetupSound(transfusionWav);
}

public OnMapEnd()
{
    KillAllClientTimers();
}

public OnClientDisconnect(client)
{
    KillClientTimer(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        KillClientTimer(client);

        SetHealthRegen(client, 0.0);
        ResetArmor(client);

        if (m_TeleporterAvailable)
            SetTeleporter(client, 0.0);

        DestroyBuildings(client, false);
        if (m_BuildAvailable)
            ResetBuild(client);
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        new teleporter_level = GetUpgradeLevel(client,raceID,nydusCanalID);
        SetupTeleporter(client, teleporter_level);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        if (m_BuildAvailable)
        {
            new spawn_num = RoundToCeil((float(GetUpgradeLevel(client,raceID,spawnID)) / 2.0) + 0.5);
            if (spawn_num > cfgMaxObjects)
                spawn_num = cfgMaxObjects;
            GiveBuild(client, spawn_num, spawn_num, spawn_num, spawn_num);
        }

        if (GameType == tf2)
        {
            CreateClientTimer(client, 1.0, CreepTimer,
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
        if (upgrade==nydusCanalID)
            SetupTeleporter(client, new_level);
        else if (upgrade==regenerationID)
            SetHealthRegen(client, float(new_level));
        else if (upgrade==carapaceID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
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
        else if (upgrade==burrowID)
        {
            if (new_level <= 0)
                ResetBurrow(client, true);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && pressed)
    {
        if (GameType != tf2 || cfgAllowSentries < 1)
        {
            new burrow_level=GetUpgradeLevel(client,race,burrowID);
            Burrow(client, burrow_level+1);
        }
        else
        {
            switch (arg)
            {
                case 4:
                {
                    new spawn_level = GetUpgradeLevel(client,race,spawnID);
                    if (spawn_level > 0)
                    {
                        Spawn(client, spawn_level, race, spawnID, cfgMaxObjects,
                              true, true, (cfgAllowSentries < 2), spawnWav,
                              "SpawnTitle");
                    }
                }
                case 3:
                {
                    new tunnel_level = GetUpgradeLevel(client,race,tunnelID);
                    if (tunnel_level > 0)
                        DeepTunnel(client);
                    else
                    {
                        new spawn_level = GetUpgradeLevel(client,race,spawnID);
                        if (spawn_level > 0)
                        {
                            Spawn(client, spawn_level, race, spawnID, cfgMaxObjects,
                                  true, true, (cfgAllowSentries < 2), spawnWav,
                                  "SpawnTitle");
                        }
                    }
                }
                case 2:
                {
                    new burrow_level=GetUpgradeLevel(client,race,burrowID);
                    Burrow(client, burrow_level+1);
                }
                default:
                {
                    new mutate_level=GetUpgradeLevel(client,race,mutateID);
                    if (mutate_level > 0)
                    {
                        Mutate(client, mutate_level, race, mutateID, -1,
                               cfgMaxObjects, (cfgAllowSentries < 2));
                    }
                    else
                    {
                        new burrow_level=GetUpgradeLevel(client,race,burrowID);
                        Burrow(client, burrow_level+1);
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
        PrepareAndEmitSoundToAll(evolveWav,client);
        
        SetOverrideSpeed(client, -1.0);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        if (m_BuildAvailable)
        {
            new spawn_num = RoundToCeil((float(GetUpgradeLevel(client,raceID,spawnID)) / 2.0) + 0.5);
            if (spawn_num > cfgMaxObjects)
                spawn_num = cfgMaxObjects;
            GiveBuild(client, spawn_num, spawn_num, spawn_num, spawn_num);
        }

        if (GameType == tf2)
        {
            CreateClientTimer(client, 1.0, CreepTimer,
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
        if (Spines(damage + absorbed, victim_index, attacker_index))
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
        if (Spines(damage + absorbed, victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    SetOverrideSpeed(victim_index, -1.0);
    KillClientTimer(victim_index);

    if (victim_race==raceID)
    {
        PrepareAndEmitSoundToAll(deathWav,victim_index);
    }
}

public Action:CreepTimer(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientNotSpec(client))
    {
        if (GetRace(client) == raceID &&
            !GetRestriction(client,Restriction_NoUpgrades) &&
            !GetRestriction(client,Restriction_Stunned))
        {
            static const toxicColor[4]  = {255, 10, 55, 255};

            new toxic_level             = GetUpgradeLevel(client,raceID,toxicID);
            new Float:toxic_range       = g_ToxicCreepRange[toxic_level];
            new toxic_amount            = GetRandomInt(g_ToxicCreepDamage[toxic_level][0],
                                                       g_ToxicCreepDamage[toxic_level][1]);

            new transfusion_level       = GetUpgradeLevel(client,raceID,transfusionID);
            new Float:transfusion_range = g_TransfusionRange[transfusion_level];
            new transfusion_amount      = transfusion_level+1;
            new transfusion_health      = transfusion_amount*5;
            new transfusion_ammo        = transfusion_amount*2;

            new lightning               = Lightning();
            new beamSprite              = BeamSprite();
            new haloSprite              = HaloSprite();

            new team = GetClientTeam(client);
            new maxentities = GetMaxEntities();
            for (new ent = MaxClients + 1; ent <= maxentities; ent++)
            {
                if (IsValidEdict(ent) && IsValidEntity(ent))
                {
                    new TFExtObjectType:type=TF2_GetExtObjectType(ent);
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
                                        iUpgrade += transfusion_ammo;
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
                                                iMetal += transfusion_ammo;
                                                if (iMetal > TF2_MaxDispenserMetal)
                                                    iMetal = TF2_MaxDispenserMetal;
                                                SetEntProp(ent, Prop_Send, "m_iAmmoMetal", iMetal);
                                            }
                                        }
                                        case TFExtObject_Sentry:
                                        {
                                            new maxShells = TF2_MaxSentryShells[iLevel];
                                            new iShells = GetEntProp(ent, Prop_Send, "m_iAmmoShells");
                                            if (iShells < maxShells)
                                            {
                                                iShells += transfusion_ammo;
                                                if (iShells > maxShells)
                                                    iShells = maxShells;
                                                SetEntProp(ent, Prop_Send, "m_iAmmoShells", iShells);
                                            }

                                            new maxRockets = TF2_MaxSentryRockets[iLevel];
                                            new iRockets = GetEntProp(ent, Prop_Send, "m_iAmmoRockets");
                                            if (iRockets < TF2_MaxSentryRockets[iLevel])
                                            {
                                                iRockets += transfusion_amount;
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
                                    health += transfusion_ammo;
                                    if (health > max_health)
                                        health = max_health;

                                    SetEntityHealth(ent, health);
                                }
                            }

                            // Heal/Supply teammates and/or Poison enemies

                            new Float:indexLoc[3];
                            new Float:pos[3];
                            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
                            pos[2] += 15.0;

                            new count=0;
                            new alt_count=0;
                            new team_count=0;
                            new alt_team_count=0;
                            new list[MaxClients+1];
                            new alt_list[MaxClients+1];
                            new team_list[MaxClients+1];
                            new alt_team_list[MaxClients+1];
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
                                                alt_team_list[alt_team_count++] = index;
                                            else
                                                team_list[team_count++] = index;
                                        }

                                        GetClientAbsOrigin(index, indexLoc);
                                        if (IsPointInRange(pos,indexLoc,transfusion_range) &&
                                            TraceTargetIndex(ent, index, pos, indexLoc))
                                        {
                                            if (HealPlayer(index,transfusion_health) > 0)
                                            {
                                                PrepareAndEmitSoundToAll(transfusionWav,ent);
                                            }

                                            new Float:energy=GetEnergy(index);
                                            SetEnergy(index, energy+float(transfusion_amount));
                                            SupplyAmmo(index, transfusion_ammo, "Transfusion", 
                                                       (GetRandomInt(0,10) > 8) ? SupplyDefault
                                                                                : SupplySecondary,
                                                       .full=(transfusion_level >= 4));
                                        }
                                    }
                                    else if (toxic_amount)
                                    {
                                        if (!IsInvulnerable(index) &&
                                            !GetImmunity(index,Immunity_HealthTaking) &&
                                            !GetImmunity(index,Immunity_Upgrades))
                                        {
                                            GetClientAbsOrigin(index, indexLoc);
                                            indexLoc[2] += 50.0;

                                            if (IsPointInRange(pos,indexLoc,toxic_range) &&
                                                TraceTargetIndex(ent, index, pos, indexLoc))
                                            {
                                                if (toxic_level > 0)
                                                {
                                                    new Float:venergy = GetEnergy(index);
                                                    if (venergy >= float(toxic_level))
                                                    {
                                                        venergy -= toxic_level;
                                                        SetEnergy(index,venergy);
                                                        SetEnergy(client, GetEnergy(client)+toxic_level);

                                                        LogToGame("%N drained %1.0f energy from %N",
                                                                  client, toxic_level, index);

                                                        PrintToChat(client," You have drained %1.0f energy from %N!",
                                                                    toxic_level, index);

                                                        PrintToChat(index," %N drained %1.0f energy from you!",
                                                                    client,toxic_level);
                                                    }
                                                }

                                                PrepareAndEmitSoundToAll(toxicWav,ent);
                                                
                                                TE_SetupBeamPoints(pos, indexLoc, lightning, haloSprite,
                                                                   0, 1, 3.0, 10.0,10.0,5,50.0,toxicColor,255);
                                                TE_SendQEffectToAll(0, index);

                                                if (!GetSetting(index, Disable_OBeacons) &&
                                                    !GetSetting(index, Remove_Queasiness))
                                                {
                                                    if (GetSetting(index, Reduce_Queasiness))
                                                        alt_list[alt_count++] = index;
                                                    else
                                                        list[count++] = index;
                                                }

                                                FlashScreen(index,RGBA_COLOR_RED);
                                                HurtPlayer(index, toxic_amount, client,
                                                           "sc_toxic_creep", .type=DMG_NERVEGAS);
                                            }
                                        }
                                    }
                                }
                            }

                            if (!GetSetting(client, Disable_Beacons) &&
                                !GetSetting(client, Remove_Queasiness))
                            {
                                if (GetSetting(client, Reduce_Queasiness))
                                {
                                    alt_list[alt_count++] = client;
                                    alt_team_list[alt_team_count++] = client;
                                }
                                else
                                {
                                    list[count++] = client;
                                    team_list[team_count++] = client;
                                }
                            }

                            static const ammoColor[4] = {255, 225, 0, 255};
                            static const healingColor[4] = {0, 255, 0, 255};

                            if (team_count > 0)
                            {
                                TE_SetupBeamRingPoint(pos, 10.0, transfusion_range, beamSprite, haloSprite,
                                                      0, 15, 0.5, 5.0, 0.0, ammoColor, 10, 0);
                                TE_Send(team_list, team_count, 0.0);

                                TE_SetupBeamRingPoint(pos, 10.0, transfusion_range, beamSprite, haloSprite,
                                                      0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                                TE_Send(team_list, team_count, 0.0);
                            }

                            if (alt_team_count > 0)
                            {
                                TE_SetupBeamRingPoint(pos, transfusion_range-10.0, transfusion_range, beamSprite, haloSprite,
                                                      0, 15, 0.5, 5.0, 0.0, ammoColor, 10, 0);
                                TE_Send(alt_team_list, alt_team_count, 0.0);

                                TE_SetupBeamRingPoint(pos, transfusion_range-10.0, transfusion_range, beamSprite, haloSprite,
                                                      0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                                TE_Send(alt_team_list, alt_team_count, 0.0);
                            }

                            if (toxic_level > 0)
                            {
                                if (count > 0)
                                {
                                    TE_SetupBeamRingPoint(pos, 10.0, toxic_range, beamSprite, haloSprite,
                                                          0, 10, 0.6, 10.0, 0.5, toxicColor, 10, 0);
                                    TE_Send(list, count, 0.0);
                                }

                                if (alt_count > 0)
                                {
                                    TE_SetupBeamRingPoint(pos, toxic_range-10.0, toxic_range, beamSprite, haloSprite,
                                                          0, 10, 0.6, 10.0, 0.5, toxicColor, 10, 0);
                                    TE_Send(alt_list, alt_count, 0.0);
                                }
                            }
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
        SetTeleporter(client, g_NydusCanalRate[level]);
}

bool:Spines(damage, victim_index, index)
{
    if (!GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned) &&
        !GetImmunity(victim_index,Immunity_HealthTaking) &&
        !GetImmunity(victim_index,Immunity_Upgrades) &&
        !IsInvulnerable(victim_index))
    {
        new level = GetUpgradeLevel(index, raceID, spinesID)+1;
        if (GetRandomInt(1,100) <= level * 19 &&
            CanInvokeUpgrade(index, raceID, spinesID, .notify=false))
        {
            new health_take=RoundFloat(float(damage)*g_SpinePercent[level]);
            if (health_take < 1)
                health_take = 1;

            HurtPlayer(victim_index, health_take, index,
                       "sc_spines", .type=DMG_POISON,
                       .in_hurt_event=true);

            PrepareAndEmitSoundToAll(spineWav,victim_index);
            return true;
        }
    }
    return false;
}

DeepTunnel(client)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromTunneling");
    }
    else if (GameType == tf2 && TF2_HasTheFlag(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);

        decl String:upgradeName[64];
        GetUpgradeName(raceID, tunnelID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWithFlag", upgradeName);
    }
    else if (CanInvokeUpgrade(client, raceID, tunnelID, false))
    {
        new target = GetClientAimTarget(client);
        if (target > 0) 
            TunnelToIt(client, target);
        else
        {
            new Handle:menu=CreateMenu(DeepTunnel_Selected);
            SetMenuTitle(menu,"[SC] %T", "TunnelStructureTitle", client);

            new counts[TFOBJECT_COUNT];
            new sum = AddBuildingsToMenu(menu, client, true, counts, target);
            if (sum == 1)
            {
                CancelMenu(menu);
                TunnelToIt(client, target);
            }
            else if (sum > 0)
                DisplayMenu(menu,client,MENU_TIME_FOREVER);
            else
            {
                CancelMenu(menu);
                PrepareAndEmitSoundToClient(client,errorWav);
                DisplayMessage(client, Display_Ultimate,
                               "%t", "NoStructuresToTunnel");
            }
        }
    }
}

public DeepTunnel_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(client,buttonWav);
        
        if (GetRace(client) == raceID)
        {
            decl String:SelectionInfo[12];
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
            TunnelToIt(client, EntRefToEntIndex(StringToInt(SelectionInfo)));
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

TunnelToIt(client, target)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromTunneling");
    }
    else if (GameType == tf2 && TF2_HasTheFlag(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);

        decl String:upgradeName[64];
        GetUpgradeName(raceID, tunnelID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWithFlag", upgradeName);
        return;
    }
    else if (IsValidEdict(target) && IsValidEntity(target))
    {
        new TFExtObjectType:type = TF2_GetExtObjectType(target);
        if (type != TFExtObject_Unknown)
        {
            if (GetEntPropEnt(target, Prop_Send, "m_hBuilder") == client)
            {
                if (CanInvokeUpgrade(client, raceID, tunnelID))
                {
                    new Float:pos[3];
                    GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);

                    new Float:size[3];
                    GetEntPropVector(target, Prop_Send, "m_vecBuildMaxs", size);

                    pos[2] += size[2] * 1.1;

                    TeleportPlayer(client, pos, NULL_VECTOR, NULL_VECTOR);

                    PrepareAndEmitSoundToAll(tunnelWav,client);

                    DisplayMessage(client,Display_Ultimate, "%t",
                                   "TunneledTo", TF2_ObjectNames[type]);

                    CreateCooldown(client, raceID, tunnelID);
                }
            }
            else
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                DisplayMessage(client, Display_Ultimate,
                               "%t", "TargetInvalid");
            }
        }
        else
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "TargetInvalid");
        }
    }
    else
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "TargetInvalid");
    }
}

