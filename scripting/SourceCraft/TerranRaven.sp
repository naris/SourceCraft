/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranRaven.sp
 * Description: The Terran Raven race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

// Pump up the memory!
#pragma dynamic 65536

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#include <tf2_player>
#include <tf2_meter>
#include <tf2_flag>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/ztf2nades>
#include <lib/firemines>
#include <lib/hgrsource>
#include <lib/ubershield>
#include <libtf2/remote>
#include <libtf2/amp_node>
#include <libtf2/sidewinder>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/Levitation"
#include "sc/ShopItems"
#include "sc/plugins"
#include "sc/freeze"
#include "sc/burrow"
#include "sc/Spawn"
#include "sc/armor"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

#define MDL_NAIL "models/weapons/nades/duke1/w_grenade_nail.mdl"
#define SND_THROWNADE "weapons/grenade_throw.wav"
#define SND_NADE_NAIL "ambient/levels/labs/teleport_rings_loop2.wav"
#define SND_NADE_NAIL_EXPLODE "weapons/explode1.wav"
#define SND_NADE_NAIL_SHOOT1 "npc/turret_floor/shoot1.wav"
#define SND_NADE_NAIL_SHOOT2 "npc/turret_floor/shoot2.wav"
#define SND_NADE_NAIL_SHOOT3 "npc/turret_floor/shoot3.wav"

new const String:spawnWav[] = "sc/tbldgplc.wav";
new const String:buildWav[] = "sc/tveyes00.wav";  // Spawn sound
new const String:deathWav[] = "sc/tvedth00.wav"; // Death sound
new const String:empWav[] = "sc/tveemp00.wav"; // EMP sound

new raceID, armorID, liftersID, reactorID, hunterID, seekerID;
new mineID, droneID, thumperID, matrixID, spawnID;

new const String:g_ArmorName[]  = "Plating";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.30},
                                    {0.10, 0.40},
                                    {0.20, 0.50} };

new g_HunterCritChance[]        = { 0,  5, 10, 25, 50 };
new g_SeekerTrackChance[]       = { 0, 10, 25, 35, 50 };
new Float:g_ThumperRange[]      = { 350.0, 400.0, 650.0, 750.0, 900.0 };
new Float:g_LevitationLevels[]  = { 1.0, 0.92, 0.733, 0.5466, 0.36 };

new cfgMaxObjects;
new cfgAllowSentries;

new bool:m_IsSeeker[MAXPLAYERS+1];
new bool:m_Thumped[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Raven",
    author = "-=|JFH|=-Naris",
    description = "The Terran Raven race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.objects.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.raven.phrases.txt");
    LoadTranslations("sc.mine.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("raven", -1, -1, 100, .energy_limit=1000.0,
                             .faction=Terran, .type=Mechanical,
                             .parent="vessel");

    armorID     = AddUpgrade(raceID, "armor", 0, 0, .cost_crystals=5);
    liftersID   = AddUpgrade(raceID, "lifters", .cost_crystals=0);
    reactorID   = AddUpgrade(raceID, "reactor", .cost_crystals=10);

    hunterID    = AddUpgrade(raceID, "hunter", 0, 16, 1, .energy=10.0,
                             .vespene=2, .cost_crystals=50);

    // Ultimate 2
    seekerID    = AddUpgrade(raceID, "seeker", 2, 12, .energy=100.0,
                            .vespene=10, .cooldown=30.0, .cost_crystals=75);

    if (!IsSidewinderAvailable())
    {
        SetUpgradeDisabled(raceID, hunterID, true);
        SetUpgradeDisabled(raceID, seekerID, true);
        LogMessage("Disabling Hunter-Seeker Missiles due to sidewinder is not available");
    }

    // Ultimate 1
    matrixID    = AddUpgrade(raceID, "matrix", 2, 8, .cooldown=2.0,
                             .cost_crystals=30);

    if (!IsUberShieldAvailable())
    {
        SetUpgradeDisabled(raceID, matrixID, true);
        LogMessage("Disabling Terran Raven:Defensive Matrix due to ubershield is not available");
    }

    // Ultimate 3
    mineID      = AddUpgrade(raceID, "spider_mine", 3, 1, .cost_crystals=30);

    if (!IsFireminesAvailable())
    {
        SetUpgradeDisabled(raceID, mineID, true);
        LogMessage("Disabling Terran Raven:Spider Mine due to firemines are not available");
    }

    // Ultimate 3
    thumperID   = AddUpgrade(raceID, "thumper", 3, 4, .energy=80.0,
                             .cooldown=0.0, .cost_crystals=20);

    // Ultimate 4
    droneID     = AddUpgrade(raceID, "drone", 4, 1, .energy=80.0,
                            .cooldown=2.0, .cost_crystals=20);

    if (!IsNadesAvailable())
    {
        SetUpgradeDisabled(raceID, droneID, true);
        LogMessage("Disabling Terran Raven:Targeting Drone due to ztf2nades are not available");
    }

    // Ultimate 2
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

    spawnID = AddUpgrade(raceID, "turret", 2, 0, 4, .energy=30.0, .vespene=5, .cost_crystals=75,
                         .cooldown=10.0, .cooldown_type=Cooldown_SpecifiesBaseValue,
                         .desc=(cfgAllowSentries >= 2) ? "%raven_turret_desc"
                                                       : "%raven_turret_engyonly_desc");

    if (cfgAllowSentries < 1 || cfgMaxObjects <= 1  ||
        GameType != tf2      || !IsBuildAvailable())
    {
        SetUpgradeDisabled(raceID, spawnID, true);
        LogMessage("Disabling Terran Raven:Auto Turret due to configuration: allow_sentries=%d, max_objects=%d (or remote is not available or gametype != tf2)", cfgAllowSentries, cfgMaxObjects);
    }

    // Set the HGRSource available flag
    IsHGRSourceAvailable();

    // Get Configuration Data
    GetConfigFloatArray("armor_amount", g_InitialArmor, sizeof(g_InitialArmor),
                        g_InitialArmor, raceID, armorID);

    for (new level=0; level < sizeof(g_ArmorPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "armor_percent_level_%d", level);
        GetConfigFloatArray(key, g_ArmorPercent[level], sizeof(g_ArmorPercent[]),
                            g_ArmorPercent[level], raceID, armorID);
    }

    GetConfigFloatArray("gravity",  g_LevitationLevels, sizeof(g_LevitationLevels),
                        g_LevitationLevels, raceID, liftersID);

    GetConfigFloatArray("range", g_ThumperRange, sizeof(g_ThumperRange),
                        g_ThumperRange, raceID, thumperID);

    if (GameType == tf2)
    {
        GetConfigArray("crit_chance", g_HunterCritChance, sizeof(g_HunterCritChance),
                       g_HunterCritChance, raceID, hunterID);

        GetConfigArray("track_chance", g_SeekerTrackChance, sizeof(g_SeekerTrackChance),
                       g_SeekerTrackChance, raceID, seekerID);

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
    if (StrEqual(name, "firemines"))
        IsFireminesAvailable(true);
    else if (StrEqual(name, "ztf2nades"))
        IsNadesAvailable(true);
    else if (StrEqual(name, "ubershield"))
        IsUberShieldAvailable(true);
    else if (StrEqual(name, "sidewinder"))
        IsSidewinderAvailable(true);
    else if (StrEqual(name, "remote"))
        IsBuildAvailable(true);
    else if (StrEqual(name, "hgrsource"))
        IsHGRSourceAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "firemines"))
        m_FireminesAvailable = false;
    else if (StrEqual(name, "ztf2nades"))
        m_NadesAvailable = false;
    else if (StrEqual(name, "ubershield"))
        m_UberShieldAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
    else if (StrEqual(name, "remote"))
        m_BuildAvailable = false;
    else if (StrEqual(name, "hgrsource"))
        m_HGRSourceAvailable = false;
}

public OnMapStart()
{
    SetupLightning();
    SetupBeamSprite();
    SetupHaloSprite();

    SetupLevitation();

    SetupSpawn();
    //SetupErrorSound();
    //SetupDeniedSound();

    SetupSound(empWav);
    SetupSound(spawnWav);
    SetupSound(buildWav);
    SetupSound(deathWav);
}

public OnPlayerAuthed(client)
{
    m_IsSeeker[client] = false;
    SetupSidewinder(client, 0, 0);
}

public OnClientDisconnect(client)
{
    m_IsSeeker[client] = false;
    SetupSidewinder(client, 0, 0);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        m_IsSeeker[client] = false;

        ResetArmor(client);
        SetGravity(client,-1.0);
        ApplyPlayerSettings(client);

        SetEnergyRate(client, -1.0);
        SetupSidewinder(client, 0, 0);

        DestroyBuildings(client, false);

        if (m_FireminesAvailable)
            TakeMines(client);

        if (m_UberShieldAvailable)
            TakeUberShield(client);
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_IsSeeker[client] = false;

        new hunter_level=GetUpgradeLevel(client,raceID,hunterID);
        SetupSidewinder(client, hunter_level, 0);

        new reactor_level = GetUpgradeLevel(client,raceID,reactorID);
        SetEnergyRate(client, (reactor_level > 0) ? float(reactor_level) : -1.0);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new lifters_level = GetUpgradeLevel(client,raceID,liftersID);
        SetLevitation(client, lifters_level, true, g_LevitationLevels);

        new mine_level=GetUpgradeLevel(client,raceID,mineID);
        if (mine_level && m_FireminesAvailable)
            GiveMines(client, mine_level*3, mine_level*3, mine_level*2);

        new matrix_level=GetUpgradeLevel(client,raceID,matrixID);
        if (matrix_level > 0)
            SetupUberShield(client, matrix_level);

        if (m_BuildAvailable)
        {
            new spawn_num = RoundToCeil((float(GetUpgradeLevel(client,raceID,spawnID)) / 2.0) + 0.5);
            if (spawn_num > cfgMaxObjects)
                spawn_num = cfgMaxObjects;
            GiveBuild(client, spawn_num, spawn_num, spawn_num, spawn_num);
        }

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(buildWav,client);
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
        if (upgrade==liftersID)
            SetLevitation(client, new_level, true, g_LevitationLevels);
        else if (upgrade==matrixID)
            SetupUberShield(client, new_level);
        else if (upgrade==reactorID)
            SetEnergyRate(client, (new_level > 0) ? float(new_level) : -1.0);
        else if (upgrade==armorID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==hunterID)
        {
            new seeker_level=GetUpgradeLevel(client,raceID,seekerID);
            SetupSidewinder(client, new_level, seeker_level);
        }
        else if (upgrade==mineID)
        {
            if (m_FireminesAvailable)
                GiveMines(client, new_level*3, new_level*3, new_level*2);
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
    if (GetRace(client) == raceID && IsValidClientAlive(client))
    {
        if (g_sockItem < 0)
            g_sockItem = FindShopItem("sock");

        if (item == g_sockItem)
        {
            new lifters_level = GetUpgradeLevel(client,raceID,liftersID);
            SetLevitation(client, lifters_level, true, g_LevitationLevels);
        }
    }
}

public Action:OnDropPlayer(client, target)
{
    if (IsValidClient(target) && GetRace(target) == raceID)
    {
        new lifters_level = GetUpgradeLevel(target,raceID,liftersID);
        SetLevitation(target, lifters_level, true, g_LevitationLevels);
    }
    return Plugin_Continue;
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4: // Targeting Drone
            {
                new drone_level = GetUpgradeLevel(client,race,droneID);
                if (drone_level > 0 && GameType == tf2)
                    ThrowTargetingDrone(client, pressed);
                else if (pressed)
                {
                    new thumper_level = GetUpgradeLevel(client,race,thumperID);
                    if (thumper_level > 0)
                        SeismicThumper(client, thumper_level);
                    else
                    {
                        new spawn_level = GetUpgradeLevel(client,race,spawnID);
                        if (spawn_level > 0)
                            AutoTurret(client, spawn_level);
                    }
                }
            }
            case 3: // Seismic Thumper
            {
                new thumper_level = GetUpgradeLevel(client,race,thumperID);
                if (thumper_level > 0)
                {
                    if (pressed)
                        SeismicThumper(client, thumper_level);
                }
                else
                {
                    new drone_level = GetUpgradeLevel(client,race,droneID);
                    if (drone_level > 0)
                        ThrowTargetingDrone(client, pressed);
                    else
                    {
                        new spawn_level = GetUpgradeLevel(client,race,spawnID);
                        if (spawn_level > 0)
                        {
                            if (pressed)
                                AutoTurret(client, spawn_level);
                        }
                    }
                }
            }
            case 2: // Spider Mine or Auto-Turret
            {
                new mine_level = GetUpgradeLevel(client,race,mineID);
                if (mine_level > 0)
                {
                    if (pressed)
                        SpiderMine(client);
                }
                else
                {
                    new spawn_level = GetUpgradeLevel(client,race,spawnID);
                    if (spawn_level > 0)
                    {
                        if (pressed)
                            AutoTurret(client, spawn_level);
                    }
                    else
                    {
                        new thumper_level = GetUpgradeLevel(client,race,thumperID);
                        if (thumper_level > 0)
                        {
                            if (pressed)
                                SeismicThumper(client, thumper_level);
                        }
                        else
                        {
                            new drone_level = GetUpgradeLevel(client,race,droneID);
                            if (drone_level > 0)
                                ThrowTargetingDrone(client, pressed);
                        }
                    }
                }
            }
            default: // Defensive Matrix or Hunter-Seeker
            {
                if (pressed)
                {
                    new seeker_level = GetUpgradeLevel(client,race,seekerID);
                    if (seeker_level > 0)
                        Seeker(client, seeker_level);
                    else
                    {
                        new matrix_level = GetUpgradeLevel(client,race,matrixID);
                        if (matrix_level > 0)
                            DefensiveMatrix(client, matrix_level);
                        else
                        {
                            new mine_level = GetUpgradeLevel(client,race,mineID);
                            if (mine_level > 0)
                            {
                                if (pressed)
                                    SpiderMine(client);
                            }
                            else
                            {
                                new thumper_level = GetUpgradeLevel(client,race,thumperID);
                                if (thumper_level > 0)
                                {
                                    if (pressed)
                                        SeismicThumper(client, thumper_level);
                                }
                                else
                                {
                                    new drone_level = GetUpgradeLevel(client,race,droneID);
                                    if (drone_level > 0)
                                        ThrowTargetingDrone(client, pressed);
                                    else
                                    {
                                        new spawn_level = GetUpgradeLevel(client,race,spawnID);
                                        if (spawn_level > 0)
                                        {
                                            if (pressed)
                                                AutoTurret(client, spawn_level);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

AutoTurret(client, spawn_level)
{
    if (spawn_level > 0 && m_BuildAvailable && GameType == tf2 && 
        (cfgAllowSentries >= 2 ||
         (cfgAllowSentries >= 1 &&
          TF2_GetPlayerClass(client) == TFClass_Engineer)))
    {
        if (IsMole(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, spawnID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, spawnID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        }
        else
        {
            new counts[TFExtObjectType];
            if (cfgMaxObjects > 0)
                CountBuildings(client, counts);

            SetEntProp(client, Prop_Send, "m_bShieldEquipped", true, 2);

            if (counts[2] < cfgMaxObjects)
            {
                SpawnIt(client, TFExtObject_Sentry, raceID, spawnID,
                        spawn_level, true, true, spawnWav);
            }
            else
            {
                Spawn(client, spawn_level, raceID, spawnID, cfgMaxObjects,
                      false, false, (cfgAllowSentries < 2), spawnWav,
                      "AutoTurretTitle");
            }
        }
    }
    else
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, spawnID, upgradeName, sizeof(upgradeName), client);
        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
    }
}

SpiderMine(client)
{
    if (m_FireminesAvailable)
    {
        if (IsMole(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, mineID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
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

DefensiveMatrix(client, matrix_level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);

    if (!m_UberShieldAvailable)
    {
        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsMole(client))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (m_HGRSourceAvailable && IsGrabbed(client))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseWhileHeld", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GameType == tf2 && TF2_HasTheFlag(client))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, matrixID, false))
    {
        new Float:duration = float(matrix_level) * 3.0;
        UberShieldTarget(client, duration, GetShieldFlags(matrix_level));
        DisplayMessage(client,Display_Ultimate,"%t", "Invoked", upgradeName);
        CreateCooldown(client, raceID, matrixID);
    }
}

public Action:OnDeployUberShield(client, target)
{
    if (GetRace(client) == raceID)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GameType == tf2 && TF2_HasTheFlag(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && GameType == tf2 && TF2_HasTheFlag(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (m_HGRSourceAvailable && IsGrabbed(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWhileHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && m_HGRSourceAvailable && IsGrabbed(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnSomeoneBeingHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (!CanInvokeUpgrade(client, raceID, matrixID))
            return Plugin_Stop;
    }
    return Plugin_Continue;
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        m_IsSeeker[client] = false;

        new hunter_level=GetUpgradeLevel(client,raceID,hunterID);
        SetupSidewinder(client, hunter_level, 0);

        new reactor_level = GetUpgradeLevel(client,raceID,reactorID);
        SetEnergyRate(client, (reactor_level > 0) ? float(reactor_level) : -1.0);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new lifters_level = GetUpgradeLevel(client,raceID,liftersID);
        SetLevitation(client, lifters_level, true, g_LevitationLevels);

        new matrix_level=GetUpgradeLevel(client,raceID,matrixID);
        if (matrix_level > 0)
            SetupUberShield(client, matrix_level);

        if (m_BuildAvailable)
        {
            new spawn_num = RoundToCeil((float(GetUpgradeLevel(client,raceID,spawnID)) / 2.0) + 0.5);
            if (spawn_num > cfgMaxObjects)
                spawn_num = cfgMaxObjects;
            GiveBuild(client, spawn_num, spawn_num, spawn_num, spawn_num);
        }

        PrepareAndEmitSoundToAll(buildWav,client);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (m_NadesAvailable && IsTargeted(victim_index))
    {
        // Override the default targetting drone damage here
        if (!GetImmunity(victim_index,Immunity_RangedAttacks) &&
            !GetImmunity(victim_index,Immunity_HealthTaking) &&
            !GetImmunity(victim_index,Immunity_Ultimates) &&
            !GetImmunity(victim_index,Immunity_Upgrades) &&
            !IsInvulnerable(victim_index))
        {
            FlashScreen(victim_index,RGBA_COLOR_RED);
            HurtPlayer(victim_index, damage+absorbed,
                       attacker_index, "sc_targeting",
                       .in_hurt_event=true);

            return Plugin_Changed;
        }
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
        PrepareAndEmitSoundToAll(deathWav,victim_index);

        m_IsSeeker[victim_index] = false;
        SetupSidewinder(victim_index, 0, 0);
    }
}

SetupUberShield(client, level)
{
    if (m_UberShieldAvailable)
    {
        if (level > 0)
        {
            new num = level * 3;
            GiveUberShield(client, num, num,
                           GetShieldFlags(level));
        }
        else
            TakeUberShield(client);
    }
}

ShieldFlags:GetShieldFlags(level)
{
    new ShieldFlags:flags = Shield_Target_Self  | Shield_Reload_Location |
                            Shield_With_Medigun | Shield_UseAlternateSounds;
    switch (level)
    {
        case 2: flags |= Shield_Target_Team | Shield_Reload_Immobilize;
        case 3: flags |= Shield_Target_Team | Shield_Team_Specific | Shield_Reload_Immobilize;
        case 4: flags |= Shield_Target_Team | Shield_Team_Specific | Shield_Mobile |
                         Shield_Reload_Team_Specific;
    }

    return flags;
}

SetupSidewinder(client, hunter_level, seeker_level)
{
    if (m_SidewinderAvailable)
    {
        new SidewinderClientFlags:flags = (hunter_level > 0) ? CritSentryRockets : NoTracking;

        if (m_IsSeeker[client] && seeker_level > 0)
            flags |= TrackingAll;
        else if (hunter_level > 0)
        {
            switch (hunter_level)
            {
                case 1: flags |= TrackingSentryRockets | TrackingRockets;

                case 2: flags |= TrackingSentryRockets | TrackingRockets |
                                 TrackingEnergyBalls | TrackingPipes |
                                 TrackingFlares;

                case 3: flags |= TrackingSentryRockets | TrackingRockets |
                                 TrackingEnergyBalls | TrackingPipes |
                                 TrackingFlares | TrackingArrows |
                                 TrackingBolts;

                case 4:
                        flags |= TrackingAll;
            }
        }

        SidewinderFlags(client, flags);
        SidewinderTrackChance(client, m_IsSeeker[client] ? g_SeekerTrackChance[seeker_level] : 0, 100);
        SidewinderSentryCritChance(client, g_HunterCritChance[hunter_level]);
    }
}

public Action:OnSidewinderSeek(client, target, projectile, bool:critical)
{
    if (GetRace(client) == raceID)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:seekerName[64];
            Format(seekerName, sizeof(seekerName), "%T", "HunterSeeker", client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", seekerName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (!m_IsSeeker[client])
        {
            new Float:energy = GetEnergy(client);
            new Float:amount = GetUpgradeEnergy(raceID,hunterID);
            if (energy < amount)
            {
                decl String:seekerName[64];
                Format(seekerName, sizeof(seekerName), "%T", "HunterSeeker", client);
                DisplayMessage(client, Display_Energy, "%t", "InsufficientEnergyFor", seekerName, amount);
                EmitEnergySoundToClient(client,Terran);
                return Plugin_Stop;
            }
            else
            {
                new vespene = GetVespene(client);
                new vespene_cost = GetUpgradeVespene(raceID,hunterID);
                if (vespene < vespene_cost)
                {
                    decl String:seekerName[64];
                    Format(seekerName, sizeof(seekerName), "%T", "HunterSeeker", client);
                    DisplayMessage(client, Display_Energy, "%t", "InsufficientVespeneFor", seekerName, vespene_cost);
                    EmitVespeneSoundToClient(client,Terran);
                    return Plugin_Stop;
                }
                else
                {
                    DecrementEnergy(client, amount);
                    DecrementVespene(client, vespene_cost);
                }
            }
        }
    }

    return Plugin_Continue;
}

SeismicThumper(client, level)
{

    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, thumperID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, thumperID))
    {
        new Float:range = g_ThumperRange[level];

        new lightning  = Lightning();
        new haloSprite = HaloSprite();
        static const thumpColor[4] = {139, 69, 19, 255};

        decl Float:indexLoc[3];
        decl Float:clientLoc[3];
        GetClientEyePosition(client, clientLoc);

        new b_count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

        if (b_count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, 10.0, range, BeamSprite(), haloSprite,GameType == tf2 &&
                                  0, 15, 0.5, 5.0, 0.0, thumpColor, 10, 0);

            TE_Send(list, b_count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, range-10.0, range, BeamSprite(), haloSprite,
                                  0, 15, 0.5, 5.0, 0.0, thumpColor, 10, 0);

            TE_Send(alt_list, alt_count, 0.0);
        }

        new count=0;
        new team=GetClientTeam(client);
        for (new index=1;index<=MaxClients;index++)
        {
            if (index != client && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!m_Thumped[index] &&
                    !GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_Restore) &&
                    !GetImmunity(index,Immunity_MotionTaking) &&
                    !IsInvulnerable(index))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(clientLoc,indexLoc,range))
                    {
                        TE_SetupBeamPoints(clientLoc, indexLoc, lightning, haloSprite,
                                           0, 1, 10.0, 10.0,10.0,2,50.0,thumpColor,255);
                        TE_SendQEffectToAll(client, index);

                        DisplayMessage(index,Display_Enemy_Ultimate, "%t",
                                       "ExposedBySeismicThumper", client);

                        m_Thumped[index] = true;

                        UnBurrow(index);
                        SetRestriction(index,Restriction_NoBurrow, true);
                        SetOverrideSpeed(index, 0.50);
                        CreateTimer(10.0,UnslowPlayer,GetClientUserId(index),TIMER_FLAG_NO_MAPCHANGE);
                        count++;
                    }
                }
            }
        }

        decl String:upgradeName[64];
        GetUpgradeName(raceID, thumperID, upgradeName, sizeof(upgradeName), client);

        if (count)
        {
            DisplayMessage(client, Display_Ultimate, "%t",
                           "ToSlowEnemies", upgradeName,
                           count);
        }
        else
        {
            DisplayMessage(client,Display_Ultimate, "%t",
                           "WithoutEffect", upgradeName);
        }

        CreateCooldown(client, raceID, thumperID);
    }
}

public Action:UnslowPlayer(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        SetRestriction(client,Restriction_NoBurrow, false);
        SetOverrideSpeed(client, -1.0);
    }
    return Plugin_Stop;
}

ThrowTargetingDrone(client, bool:pressed)
{
    if (!m_NadesAvailable)
    {
        if (pressed)
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, droneID, upgradeName, sizeof(upgradeName), client);
            PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
        }
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        if (pressed)
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, droneID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
    }
    else if (CanInvokeUpgrade(client, raceID, droneID, pressed, pressed))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        ThrowNade(client, pressed, TargetingDrone);

        if (!pressed)
        {
            DisplayMessage(client,Display_Ultimate, "%t", "TargetingDroneDeployed");
            CreateCooldown(client, raceID, droneID);
        }
    }
}

Seeker(client, level)
{
    if (level > 0)
    {
        if (m_IsSeeker[client])
        {
            PrepareAndEmitSoundToClient(client,errorWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "HunterSeekerAlreadyActive");
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, seekerID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (CanInvokeUpgrade(client, raceID, seekerID))
        {
            m_IsSeeker[client] = true;

            new hunter_level=GetUpgradeLevel(client,raceID,hunterID);
            new seeker_level=GetUpgradeLevel(client,raceID,seekerID);
            SetupSidewinder(client, hunter_level, seeker_level);

            //PrepareAndEmitSoundToAll(seekerReadyWav,client);

            new Float:time = 5.0 * float(level);
            CreateTimer(time, EndSeeker, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
            PrintHintText(client, "%t", "SeekerActive", time);
            HudMessage(client, "%t", "SeekerHud");
        }
    }
}

public Action:EndSeeker(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        m_IsSeeker[client] = false;

        new bool:isRaven = (GetRace(client) == raceID);
        if (isRaven && IsClientInGame(client) && IsPlayerAlive(client))
        {
            //PrepareAndEmitSoundToAll(seekerExpireWav,client);
            PrintHintText(client, "%t", "SeekerExpired");
            ClearHud(client, "%t", "SeekerHud");
        }

        new hunter_level=isRaven ? GetUpgradeLevel(client,raceID,hunterID) : 0;
        SetupSidewinder(client, hunter_level, 0);
        CreateCooldown(client, raceID, seekerID);
    }
}
