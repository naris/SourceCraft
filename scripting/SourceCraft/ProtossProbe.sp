/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossProbe.sp
 * Description: The Protoss Probe race for SourceCraft.
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
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <remote>
#include <amp_node>
#include <lib/ztf2grab>
#include <tf2teleporter>
#include <AdvancedInfiniteAmmo>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/RecallStructure"
#include "sc/clienttimer"
#include "sc/SupplyDepot"
#include "sc/maxhealth"
#include "sc/menuitemt"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/shields"
#include "sc/sounds"
#include "sc/WarpIn"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Explosion"
#include "effect/SendEffects"
#include "effect/FlashScreen"

#define MAXENTITIES 2048

new const String:summonWav[]    = "sc/pprrdy00.wav";
new const String:deathWav[]     = "sc/pprdth00.wav";
new const String:pylonWav[]     = "sc/ppywht00.wav";
new const String:resetWav[]     = "sc/unrwht00.wav";
new const String:forgeWav[]     = "sc/pfowht00.wav";
new const String:cannonWav[]    = "sc/phohit00.wav";

new Float:g_InitialShields[]    = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ShieldsPercent[][2] = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.20},
                                    {0.10, 0.30},
                                    {0.20, 0.40} };

new Float:g_ForgeFactor[]       = { 1.0, 1.10, 1.20, 1.40, 1.60 };

new Float:g_WarpGateRate[]      = { 0.0, 8.0, 6.0, 3.0, 1.0 };

new m_BatteryUpgradeMetal[]     = { 0, 1, 2, 3, 4 };
new m_BatteryAmmoRockets[]      = { 0, 1, 2, 3, 4 };
new m_BatteryAmmoShells[]       = { 0, 2, 4, 6, 8 };
new m_BatteryAmmoMetal[]        = { 0, 2, 4, 6, 8 };
new m_BatteryRepair[]           = { 0, 1, 2, 3, 4 };

new g_CannonChance[]            = { 0, 20, 40, 60, 90 };
new Float:g_CannonPercent[]     = { 0.0, 0.15, 0.30, 0.40, 0.50 };

new m_DarkPylonAlpha[]          = { 255, 150, 100, 50, 10, 0 };

new raceID, shieldsID, batteriesID, forgeID, warpGateID, cannonID;
new recallStructureID, pylonID, amplifierID, phasePrismID;

new g_phasePrismRace = -1;

new cfgAllowSentries;
new bool:cfgAllowTeleport;
new bool:cfgAllowInvisibility;

new bool:m_IsDarkPylon[MAXPLAYERS+1];
new Float:m_CannonTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Probe",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Probe race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.objects.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.recall.phrases.txt");
    LoadTranslations("sc.supply.phrases.txt");
    LoadTranslations("sc.probe.phrases.txt");

    if (GetGameType() == tf2)
    {
        if (!HookEvent("player_upgradedobject", PlayerUpgradedObject))
            SetFailState("Could not hook the player_builtobject event.");

        if (!HookEventEx("teamplay_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_win event.");

        if (!HookEventEx("teamplay_round_stalemate",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_stalemate event.");
    }
    else if (GameType == dod)
    {
        if (!HookEventEx("dod_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the dod_round_win event.");

        if (!HookEventEx("dod_game_over",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the dod_game_over event.");
    }
    else if (GameTypeIsCS())
    {
        if (!HookEventEx("end",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the round_end event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("probe", 80, 0, 33, .energy_rate=2.0,
                             .faction=Protoss, .type=Robotic);

    shieldsID   = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);

    batteriesID = AddUpgrade(raceID, "batteries", .cost_crystals=50);
    forgeID     = AddUpgrade(raceID, "forge", .cost_crystals=50);
    warpGateID  = AddUpgrade(raceID, "warp_gate", .cost_crystals=0);

    cannonID    = AddUpgrade(raceID, "cannon", 0, 8, .energy=2.0, .cost_crystals=50);

    // Ultimate 1
    recallStructureID = AddUpgrade(raceID, "recall_structure", 1, 8, .energy=30.0,
                                   .vespene=5, .cooldown=5.0, .cost_crystals=50);

    // Ultimate 2
    pylonID     = AddUpgrade(raceID, "pylon", 2, 10, .energy=30.0, .cooldown=2.0,
                             .cost_crystals=50);

    // Ultimate 3
    amplifierID = AddUpgrade(raceID, "amplifier", 3, 8, .energy=30.0,
                             .vespene=5, .cooldown=10.0, .cost_crystals=10);

    // Ultimate 4
    phasePrismID = AddUpgrade(raceID, "prism", 4, 14, 1,
                              .energy=300.0, .cooldown=60.0,
                              .accumulated=true, .cost_crystals=50);

    // Check GameType and configurations
    if (GetGameType() != tf2)
    {
        LogMessage("Disabling Protoss Probe:Shield Batteries, Forge, Warp Gate, Dark Pylon and Warp In Amplifier due to gametype != tf2");

        SetUpgradeDisabled(raceID, batteriesID, true);
        SetUpgradeDisabled(raceID, forgeID, true);
        SetUpgradeDisabled(raceID, warpGateID, true);

        SetUpgradeDisabled(raceID, recallStructureID, true);
        SetUpgradeDisabled(raceID, pylonID, true);
        SetUpgradeDisabled(raceID, amplifierID, true);
    }
    else
    {
        cfgAllowSentries = GetConfigNum("allow_sentries", 2);
        if (cfgAllowSentries < 2)
        {
            SetUpgradeDisabled(raceID, forgeID, true);
            LogMessage("Disabling Protoss Probe:Forge due to configuration: sc_allow_sentries=%d",
                       cfgAllowSentries);
        }

        if (!IsTeleporterAvailable())
        {
            SetUpgradeDisabled(raceID, warpGateID, true);
            LogMessage("Disabling Protoss Probe:Warp Gate due to tf2teleporter is not available");
        }

        cfgAllowTeleport = bool:GetConfigNum("allow_teleport", true);
        if (!cfgAllowTeleport || cfgAllowSentries < 1)
        {
            SetUpgradeDisabled(raceID, recallStructureID, true);
            LogMessage("Disabling Protoss Probe:Recall Structure due to configuration: sc_allow_sentries=%d, sc_allow_teleport=%d",
                        cfgAllowSentries, cfgAllowTeleport);
        }

        cfgAllowInvisibility = bool:GetConfigNum("allow_invisibility", true);
        if (!cfgAllowInvisibility)
        {
            SetUpgradeDisabled(raceID, pylonID, true);
            LogMessage("Disabling Protoss Probe:Dark Pylon due to configuration: sc_allow_invisibility=%d",
                        cfgAllowInvisibility);
        }

        if (!IsAmpNodeAvailable() || !IsBuildAvailable())
        {
            SetUpgradeDisabled(raceID, amplifierID, true);
            LogMessage("Disabling Protoss Probe:Warp In Amplifier due to amp_node and/or remote are not available");
        }
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

    GetConfigArray("chance", g_CannonChance, sizeof(g_CannonChance),
                   g_CannonChance, raceID, cannonID);

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

    GetConfigFloatArray("damage_percent", g_CannonPercent, sizeof(g_CannonPercent),
                        g_CannonPercent, raceID, cannonID);

    if (GameType == tf2)
    {
        GetConfigFloatArray("factor", g_ForgeFactor, sizeof(g_ForgeFactor),
                            g_ForgeFactor, raceID, forgeID);

        GetConfigFloatArray("rate", g_WarpGateRate, sizeof(g_WarpGateRate),
                            g_WarpGateRate, raceID, warpGateID);

        GetConfigArray("alpha", m_DarkPylonAlpha, sizeof(m_DarkPylonAlpha),
                       m_DarkPylonAlpha, raceID, pylonID);

        for (new type=0; type < sizeof(g_AmpRange); type++)
        {
            decl String:section[32];
            Format(section, sizeof(section), "amplifier_type_%d", type);

            for (new level=0; level < sizeof(g_AmpRange[]); level++)
            {
                decl String:key[32];
                Format(key, sizeof(key), "range_level_%d", level);
                GetConfigFloatArray(key, g_AmpRange[type][level], sizeof(g_AmpRange[][]),
                                    g_AmpRange[type][level], raceID, amplifierID, section);
            }
        }
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "tf2teleporter"))
        IsTeleporterAvailable(true);
    else if (StrEqual(name, "remote"))
        IsBuildAvailable(true);
    else if (StrEqual(name, "amp_node"))
        IsAmpNodeAvailable(true);
    else if (StrEqual(name, "ztf2grab"))
        IsGravgunAvailable(true);
    else if (StrEqual(name, "aia"))
        IsInfiniteAmmoAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "tf2teleporter"))
        m_TeleporterAvailable = false;
    else if (StrEqual(name, "ztf2grab"))
        m_GravgunAvailable = false;
    else if (StrEqual(name, "remote"))
        m_BuildAvailable = false;
    else if (StrEqual(name, "amp_node"))
        m_AmpNodeAvailable = false;
    else if (StrEqual(name, "aia"))
        m_InfiniteAmmoAvailable = false;
}

public OnMapStart()
{
    SetupExplosion();
    SetupSmokeSprite();
    SetupBlueGlow();
    SetupRedGlow();

    SetupRecallSounds();

    SetupErrorSound();
    SetupDeniedSound();
    SetupButtonSound();

    SetupSound(summonWav);
    SetupSound(pylonWav);
    SetupSound(resetWav);
    SetupSound(forgeWav);
    SetupSound(deathWav);
    SetupSound(cannonWav);
}

public OnMapEnd()
{
    ResetAllClientTimers();
}

public OnPlayerAuthed(client)
{
    m_IsDarkPylon[client] = false;
    m_CannonTime[client] = 0.0;
}

public OnClientDisconnect(client)
{
    KillClientTimer(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        KillClientTimer(client);

        if (m_TeleporterAvailable)
            SetTeleporter(client, 0.0);

        if (m_BuildAvailable)
            DestroyBuildings(client, false);

        return Plugin_Handled;
    }
    else
    {
        if (g_phasePrismRace < 0)
            g_phasePrismRace = FindRace("prism");

        if (oldrace == g_phasePrismRace &&
            GetCooldownExpireTime(client, raceID, phasePrismID) <= 0.0)
        {
            CreateCooldown(client, raceID, phasePrismID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }

        return Plugin_Continue;
    }
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_CannonTime[client] = 0.0;
        m_IsDarkPylon[client] = false;

        new warp_gate_level = GetUpgradeLevel(client,raceID,warpGateID);
        if (warp_gate_level > 0)
            SetupTeleporter(client, warp_gate_level);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        if (IsValidClientAlive(client))
        {
            new battery_level = GetUpgradeLevel(client,raceID,batteriesID);
            if (shields_level ||
                (battery_level && GameType == tf2 &&
                 TF2_GetPlayerClass(client) == TFClass_Engineer))
            {
                CreateClientTimer(client, 1.0, BatteryTimer,
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
        if (upgrade==warpGateID)
            SetupTeleporter(client, new_level);
        else if (upgrade==shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, .upgrade=true);

            if (new_level ||
                (GetUpgradeLevel(client,raceID,batteriesID) &&
                 GameType == tf2 && TF2_GetPlayerClass(client) == TFClass_Engineer))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 1.0, BatteryTimer,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
        }
        else if (upgrade==batteriesID)
        {
            if (GetUpgradeLevel(client,raceID,shieldsID) ||
                (new_level && GameType == tf2 && TF2_GetPlayerClass(client) == TFClass_Engineer))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 1.0, BatteryTimer,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
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
                new phase_prism_level=GetUpgradeLevel(client,race,phasePrismID);
                if (phase_prism_level > 0)
                {
                    if (!pressed)
                        SummonPhasePrism(client);
                }
                else
                {
                    new amplifier_level = GetUpgradeLevel(client,raceID,amplifierID);
                    if (GameType == tf2 && amplifier_level > 0)
                    {
                        if (!pressed)
                            WarpInAmplifier(client, amplifier_level,raceID,amplifierID,false);
                    }
                    else
                    {
                        new pylon_level=GetUpgradeLevel(client,race,pylonID);
                        if (GameType == tf2 && pylon_level > 0 && cfgAllowInvisibility)
                        {
                            if (pressed)
                                DarkPylon(client, pylon_level);
                        }
                    }
                }
            }
            case 3:
            {
                new amplifier_level = GetUpgradeLevel(client,raceID,amplifierID);
                if (GameType == tf2 && amplifier_level > 0)
                {
                    if (!pressed)
                        WarpInAmplifier(client, amplifier_level,raceID,amplifierID,false);
                }
                else
                {
                    new pylon_level=GetUpgradeLevel(client,race,pylonID);
                    if (GameType == tf2 && pylon_level > 0 && cfgAllowInvisibility)
                    {
                        if (pressed)
                            DarkPylon(client, pylon_level);
                    }
                    else if (!pressed)
                    {
                        new phase_prism_level=GetUpgradeLevel(client,race,phasePrismID);
                        if (phase_prism_level > 0)
                            SummonPhasePrism(client);
                    }
                }
            }
            case 2:
            {
                new pylon_level=GetUpgradeLevel(client,race,pylonID);
                if (GameType == tf2 && pylon_level > 0 && cfgAllowInvisibility)
                {
                    if (pressed)
                        DarkPylon(client, pylon_level);
                }
                else if (!pressed)
                {
                    new phase_prism_level=GetUpgradeLevel(client,race,phasePrismID);
                    if (phase_prism_level > 0)
                        SummonPhasePrism(client);
                }
            }
            default:
            {
                new recall_structure_level = GetUpgradeLevel(client,race,recallStructureID);
                if (GameType == tf2 && recall_structure_level > 0 && cfgAllowTeleport &&
                    (cfgAllowSentries >= 2) || (cfgAllowSentries >= 1 && GameType == tf2 &&
                                                TF2_GetPlayerClass(client) != TFClass_Engineer))
                {
                    if (pressed)
                        RecallStructure(client,race,recallStructureID, true, cfgAllowSentries == 1);
                }
                else
                {
                    new pylon_level=GetUpgradeLevel(client,race,pylonID);
                    if (GameType == tf2 && pylon_level > 0 && cfgAllowInvisibility)
                    {
                        if (pressed)
                            DarkPylon(client, pylon_level);
                    }
                    else if (!pressed)
                    {
                        new phase_prism_level=GetUpgradeLevel(client,race,phasePrismID);
                        if (phase_prism_level > 0)
                            SummonPhasePrism(client);
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
        m_CannonTime[client] = 0.0;

        PrepareAndEmitSoundToAll(summonWav,client);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        new battery_level=GetUpgradeLevel(client,raceID,batteriesID);
        if (shields_level ||
            (battery_level && GameType == tf2 &&
             TF2_GetPlayerClass(client) == TFClass_Engineer))
        {
            CreateClientTimer(client, 1.0, BatteryTimer,
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
        if (PhotonCannon(damage + absorbed, victim_index, attacker_index))
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
        if (PhotonCannon(damage + absorbed, victim_index, assister_index))
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
    else
    {
        if (g_phasePrismRace < 0)
            g_phasePrismRace = FindRace("prism");

        if (victim_race == g_phasePrismRace &&
            GetCooldownExpireTime(victim_index, raceID, phasePrismID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, phasePrismID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

public EventRoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        m_IsDarkPylon[index] = false;
    }
}

public OnPlayerBuiltObject(Handle:event, client, obj, TFObjectType:type)
{
    if (obj > 0 && type != TFObject_Sapper)
    {
        if (IsValidClientNotSpec(client) && GetRace(client) == raceID &&
            !GetRestriction(client, Restriction_NoUpgrades) &&
            !GetRestriction(client, Restriction_Stunned))
        {
            if (cfgAllowSentries >= 1 && GetUpgradeLevel(client,raceID,forgeID) > 0)
            {
                new Float:time = (GetEntPropFloat(obj, Prop_Send, "m_flPercentageConstructed") >= 1.0) ? 0.1 : 10.0;
                CreateTimer(time, ForgeTimer, EntIndexToEntRef(obj), TIMER_FLAG_NO_MAPCHANGE);
            }

            new pylon_level = cfgAllowInvisibility && m_IsDarkPylon[client] ? GetUpgradeLevel(client,raceID,pylonID) : 0;
            if (pylon_level > 0)
            {
                SetEntityRenderColor(obj, 255, 255, 255, m_DarkPylonAlpha[pylon_level]);
                SetEntityRenderMode(obj,RENDER_TRANSCOLOR);
            }
        }
    }
}

public PlayerUpgradedObject(Handle:event,const String:name[],bool:dontBroadcast)
{
    new obj = GetEventInt(event,"index");
    if (obj > 0)
    {
        new client = GetClientOfUserId(GetEventInt(event,"userid"));
        if (IsValidClientNotSpec(client) && GetRace(client) == raceID &&
            !GetRestriction(client, Restriction_NoUpgrades) &&
            !GetRestriction(client, Restriction_Stunned))
        {
            if (cfgAllowSentries >= 1 && GetUpgradeLevel(client,raceID,forgeID) > 0)
                CreateTimer(0.1, ForgeTimer, EntIndexToEntRef(obj), TIMER_FLAG_NO_MAPCHANGE);

            new pylon_level = m_IsDarkPylon[client] ? GetUpgradeLevel(client,raceID,pylonID) : 0;
            if (pylon_level > 0 && cfgAllowInvisibility)
            {
                SetEntityRenderColor(obj, 255, 255, 255, m_DarkPylonAlpha[pylon_level]);
                SetEntityRenderMode(obj,RENDER_TRANSCOLOR);
            }
        }
    }
}

public Action:ForgeTimer(Handle:timer,any:ref)
{
    new obj = EntRefToEntIndex(ref);
    if (obj > 0 && IsValidEntity(obj) && IsValidEdict(obj))
    {
        new builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
        if (builder > 0 && GetRace(builder) == raceID &&
            !GetRestriction(builder, Restriction_NoUpgrades) &&
            !GetRestriction(builder, Restriction_Stunned))
        {
            if (GetEntPropFloat(obj, Prop_Send, "m_flPercentageConstructed") >= 1.0)
            {
                new build_level = GetUpgradeLevel(builder,raceID,forgeID);
                if (build_level > 0 && cfgAllowSentries >= 1)
                {
                    new iLevel = GetEntProp(obj, Prop_Send, "m_bMiniBuilding") ? 0 : 
                                 GetEntProp(obj, Prop_Send, "m_iUpgradeLevel");

                    //new health = GetEntProp(obj, Prop_Send, "m_iHealth");
                    new health = RoundToNearest(float(TF2_SentryHealth[iLevel]) * g_ForgeFactor[build_level]);

                    new maxHealth = TF2_SentryHealth[4]; //[iLevel+1];
                    if (health > maxHealth)
                        health = maxHealth;

                    if (health > GetEntProp(obj, Prop_Data, "m_iMaxHealth"))
                        SetEntProp(obj, Prop_Data, "m_iMaxHealth", health);

                    SetEntityHealth(obj, health);

                    if (TF2_GetObjectType(obj) == TFObject_Sentry)
                    {
                        new maxShells = TF2_MaxSentryShells[4]; //[iLevel+1];
                        //new iShells = GetEntProp(obj, Prop_Send, "m_iAmmoShells");
                        new iShells = RoundToNearest(float(TF2_MaxSentryShells[iLevel]) *g_ForgeFactor[build_level]);
                        if (iShells > maxShells)
                            iShells = maxShells;

                        SetEntProp(obj, Prop_Send, "m_iAmmoShells", iShells);

                        if (iLevel > 2)
                        {
                            new maxRockets = TF2_MaxSentryRockets[4]; //[iLevel+1];
                            //new iRockets = GetEntProp(obj, Prop_Send, "m_iAmmoRockets");
                            new iRockets = RoundToNearest(float(TF2_MaxSentryRockets[iLevel]) *g_ForgeFactor[build_level]);
                            if (iRockets > maxRockets)
                                iRockets = maxRockets;

                            SetEntProp(obj, Prop_Send, "m_iAmmoRockets", iRockets);
                        }
                    }

                    PrepareAndEmitSoundToAll(forgeWav,obj);
                }

                new pylon_level = m_IsDarkPylon[builder] ? GetUpgradeLevel(builder,raceID,pylonID) : 0;
                if (pylon_level > 0 && cfgAllowInvisibility)
                {
                    SetEntityRenderColor(obj, 255, 255, 255, m_DarkPylonAlpha[pylon_level]);
                    SetEntityRenderMode(obj,RENDER_TRANSCOLOR);
                }
            }
            else
                CreateTimer(1.0, ForgeTimer, ref, TIMER_FLAG_NO_MAPCHANGE);
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
        if (GetGameType() != tf2)
            return Plugin_Continue;

        new battery_level = GetUpgradeLevel(client,raceID,batteriesID);
        if (battery_level > 0 && cfgAllowSentries >= 1 && GameType == tf2 &&
            TF2_GetPlayerClass(client) == TFClass_Engineer)
        {
            new upgrade_amount = m_BatteryUpgradeMetal[battery_level];
            new rocket_amount = m_BatteryAmmoRockets[battery_level];
            new shells_amount = m_BatteryAmmoShells[battery_level];
            new metal_amount = m_BatteryAmmoMetal[battery_level];
            new repair_amount = m_BatteryRepair[battery_level];

            new maxentities = GetMaxEntities();
            for (new i = MaxClients + 1; i <= maxentities; i++)
            {
                if (IsValidEntity(i) && IsValidEdict(i))
                {
                    new TFExtObjectType:type=TF2_GetExtObjectType(i);
                    if (type != TFExtObject_Unknown)
                    {
                        if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client &&
                            GetEntPropFloat(i, Prop_Send, "m_flPercentageConstructed") >= 1.0)
                        {
                            new iLevel = GetEntProp(i, Prop_Send, "m_iUpgradeLevel");
                            if (iLevel < 3)
                            {
                                new iUpgrade = GetEntProp(i, Prop_Send, "m_iUpgradeMetal");
                                if (iUpgrade < TF2_MaxUpgradeMetal)
                                {
                                    iUpgrade += upgrade_amount;
                                    if (iUpgrade > TF2_MaxUpgradeMetal)
                                        iUpgrade = TF2_MaxUpgradeMetal;
                                    SetEntProp(i, Prop_Send, "m_iUpgradeMetal", iUpgrade);
                                }
                            }
                            else
                            {
                                switch (type)
                                {
                                    case TFExtObject_Dispenser:
                                    {
                                        new iMetal = GetEntProp(i, Prop_Send, "m_iAmmoMetal");
                                        if (iMetal < TF2_MaxDispenserMetal)
                                        {
                                            iMetal += metal_amount;
                                            if (iMetal > TF2_MaxDispenserMetal)
                                                iMetal = TF2_MaxDispenserMetal;
                                            SetEntProp(i, Prop_Send, "m_iAmmoMetal", iMetal);
                                        }
                                    }
                                    case TFExtObject_Sentry:
                                    {
                                        new maxShells = TF2_MaxSentryShells[iLevel];
                                        new iShells = GetEntProp(i, Prop_Send, "m_iAmmoShells");
                                        if (iShells < maxShells)
                                        {
                                            iShells += shells_amount;
                                            if (iShells > maxShells)
                                                iShells = maxShells;
                                            SetEntProp(i, Prop_Send, "m_iAmmoShells", iShells);
                                        }

                                        new maxRockets = TF2_MaxSentryRockets[iLevel];
                                        new iRockets = GetEntProp(i, Prop_Send, "m_iAmmoRockets");
                                        if (iRockets < maxRockets)
                                        {
                                            iRockets += rocket_amount;
                                            if (iRockets > maxRockets)
                                                iRockets = maxRockets;
                                            SetEntProp(i, Prop_Send, "m_iAmmoRockets", iRockets);
                                        }
                                    }
                                }
                            }

                            new maxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
                            new health = GetEntProp(i, Prop_Send, "m_iHealth");
                            if (health < maxHealth)
                            {
                                health += repair_amount;
                                if (health > maxHealth)
                                    health = maxHealth;

                                SetEntityHealth(i, health);
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
        SetTeleporter(client, g_WarpGateRate[level]);
}

bool:PhotonCannon(damage, victim_index, index)
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
                                       "sc_photon_cannon", .type=DMG_ENERGYBEAM,
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

DarkPylon(client, level)
{
    if (m_IsDarkPylon[client])
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client,Display_Ultimate,
                       "%t", "PylonAlreadyActive");
    }
    else
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, pylonID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        }
        else if (CanInvokeUpgrade(client, raceID, pylonID))
        {
            new count = 0;
            new maxentities = GetMaxEntities();
            for (new i = MaxClients + 1; i <= maxentities; i++)
            {
                if (IsValidEntity(i) && IsValidEdict(i))
                {
                    if (TF2_GetExtObjectType(i) != TFExtObject_Unknown)
                    {
                        if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client)
                        {
                            count++;
                            SetEntityRenderColor(i, 255, 255, 255, m_DarkPylonAlpha[level]);
                            SetEntityRenderMode(i,RENDER_TRANSCOLOR);

                            PrepareAndEmitSoundToAll(pylonWav,i);
                        }
                    }
                }
            }

            if (count > 0)
            {
                new Float:time = float(level)*2.0;
                DisplayMessage(client,Display_Ultimate, "%t", "PylonInvoked", time);
                CreateTimer(time, ResetDarkPylon, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
                ChargeForUpgrade(client, raceID, pylonID);
                CreateCooldown(client, raceID, pylonID);
                m_IsDarkPylon[client] = true;
            }
            else
            {
                DisplayMessage(client,Display_Ultimate, "%t", "PylonFoundNothing");
                PrepareAndEmitSoundToClient(client,errorWav);
            }
        }
    }
}

public Action:ResetDarkPylon(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        new maxentities = GetMaxEntities();
        for (new i = MaxClients + 1; i <= maxentities; i++)
        {
            if (IsValidEntity(i) && IsValidEdict(i))
            {
                if (TF2_GetExtObjectType(i) != TFExtObject_Unknown)
                {
                    if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client)
                    {
                        PrepareAndEmitSoundToAll(resetWav,i);

                        SetEntityRenderColor(i, 255, 255, 255, 255);
                        SetEntityRenderMode(i,RENDER_NORMAL);
                    }
                }
            }
        }

        m_IsDarkPylon[client] = false;
        DisplayMessage(client,Display_Ultimate,
                       "%t", "PylonExpired");
    }
}

SummonPhasePrism(client)
{
    if (g_phasePrismRace < 0)
        g_phasePrismRace = FindRace("prism");

    if (g_phasePrismRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, phasePrismID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Phase Prism race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromSummoningPrism");
    }
    else if (CanInvokeUpgrade(client, raceID, phasePrismID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_phasePrismRace, true, false, true);
    }
}

public Action:OnAmplify(builder,client,TFCond:condition)
{
    new from;
    new Float:amount;
    switch (condition)
    {
        case TFCond_Slowed, TFCond_Zoomed:
        {
            if (GetImmunity(client,Immunity_MotionTaking) ||
                GetImmunity(client,Immunity_Restore))
            {
                return Plugin_Stop;
            }
            else
            {
                from  = builder;
                amount = 2.0;
            }
        }
        case TFCond_Taunting, TFCond_Dazed:
        {
            if (GetImmunity(client,Immunity_MotionTaking) ||
                GetImmunity(client,Immunity_Restore))
            {
                return Plugin_Stop;
            }
            else
            {
                from  = builder;
                amount = 10.0;
            }
        }
        case TFCond_Disguised, TFCond_Cloaked:
        {
            if (GetImmunity(client,Immunity_Uncloaking))
                return Plugin_Stop;
            else
            {
                from  = builder;
                amount = 10.0;
            }
        }
        case TFCond_OnFire:
        {
            if (GetImmunity(client,Immunity_Burning) ||
                GetImmunity(client,Immunity_Restore))
            {
                return Plugin_Stop;
            }
            else
            {
                from  = builder;
                amount = 1.0;
            }
        }
        case TFCond_Bleeding:
        {
            if (GetImmunity(client,Immunity_HealthTaking) ||
                GetImmunity(client,Immunity_Restore))
            {
                return Plugin_Stop;
            }
            else
            {
                from  = builder;
                amount = 1.0;
            }
        }
        case TFCond_Jarated, TFCond_Milked, TFCond_MarkedForDeath:
        {
            if (GetImmunity(client,Immunity_Poison) ||
                GetImmunity(client,Immunity_Restore))
            {
                return Plugin_Stop;
            }
            else
            {
                from  = builder;
                amount = 1.0;
            }
        }
        case TFCond_Buffed, TFCond_DefenseBuffed, TFCond_RegenBuffed:
        {
            from  = client;
            amount = 1.0;
        }
        case TFCond_Kritzkrieged, TFCond_Ubercharged:
        {
            from  = client;
            amount = 4.0;
        }
        default:
        {
            from = 0;
            amount = 0.0;
        }
    }

    if (from > 0 && amount > 0.0 &&
        builder > 0 && GetRace(builder) == raceID)
    {
        if (!DecrementEnergy(from, amount, false))
            return Plugin_Stop;
    }

    return Plugin_Continue;
}

