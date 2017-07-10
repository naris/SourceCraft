/**
 * vim: set ai et ts=4 sw=4 :
 * File: ZergDrone.sp
 * Description: The Zerg Drone race for SourceCraft.
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
#include <ztf2grab>
#include <tf2teleporter>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/SupplyDepot"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/burrow"
#include "sc/sounds"
#include "sc/armor"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/SendEffects"

new const String:spawnWav[]     = "sc/zdrrdy00.wav";
new const String:deathWav[]     = "sc/zdrdth00.wav";
new const String:burrowUpWav[]  = "sc/burrowup.wav";
new const String:burrowDownWav[] = "sc/burrowdn.wav";

new raceID;

#include "sc/Mutate"

new const String:g_ArmorName[]  = "Carapace";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.30},
                                    {0.10, 0.40},
                                    {0.20, 0.50} };

new Float:g_NydusCanalRate[]    = { 0.0, 8.0, 6.0, 3.0, 1.0 };

new carapaceID, regenerationID, creepID, nydusCanalID;
new evolutionID, mutateID, burrowStructID, hiveQueenID;

new g_hiveQueenRace = -1;

new cfgMaxObjects;
new cfgAllowSentries;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Zerg Drone",
    author = "-=|JFH|=-Naris",
    description = "The Zerg Drone race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.objects.phrases.txt");
    LoadTranslations("sc.mutate.phrases.txt");
    LoadTranslations("sc.recall.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.supply.phrases.txt");
    LoadTranslations("sc.drone.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID = CreateRace("drone", 64, 0, 27, .faction=Zerg,
                        .type=Biological);

    carapaceID      = AddUpgrade(raceID, "armor");
    regenerationID  = AddUpgrade(raceID, "regeneration");

    if (GetGameType() == tf2)
    {
        creepID     = AddUpgrade(raceID, "creep");

        cfgAllowSentries = GetConfigNum("allow_sentries", 2);
        if (cfgAllowSentries < 2)
        {
            SetUpgradeDisabled(raceID, creepID, true);
            LogMessage("Disabling Zerg Drone:Creep due to configuration: sc_allow_sentries=%d",
                       cfgAllowSentries);
        }

        nydusCanalID = AddUpgrade(raceID, "teleporter");

        if (!IsTeleporterAvailable())
        {
            SetUpgradeDisabled(raceID, nydusCanalID, true);
            LogMessage("tf2teleporter is not available");
        }

        evolutionID = AddUpgrade(raceID, "evolution", 0, 8, (cfgMaxObjects < 5) ? cfgMaxObjects-1 : 4,
                                 .cost_vespene=10);

        cfgMaxObjects    = GetConfigNum("max_objects", 3);
        if (cfgMaxObjects <= 1)
        {
            SetUpgradeDisabled(raceID, evolutionID, true);
            LogMessage("Disabling Zerg Drone:Evolution Chamber due to configuration: sc_maxobjects=%d",
                       cfgMaxObjects);
        }

        // Ultimate 1
        mutateID = AddUpgrade(raceID, "mutate", true, 4, .energy=30.0, .vespene=2, .cooldown=5.0,
                              .cooldown_type=Cooldown_SpecifiesBaseValue,
                              .desc=(cfgAllowSentries >= 2) ? "%drone_mutate_desc"
                              : "%drone_mutate_engyonly_desc");

        if (!IsBuildAvailable())
        {
            SetUpgradeDisabled(raceID, mutateID, true);
            LogMessage("remote is not available");
        }
        else if (cfgAllowSentries < 1)
        {
            SetUpgradeDisabled(raceID, mutateID, true);
            LogMessage("Disabling Zerg Drone:Mutate due to configuration: sc_allow_sentries=%d",
                       cfgAllowSentries);
        }
    }
    else
    {
        creepID     = AddUpgrade(raceID, "creep", 0, 99, 0,
                                 .desc="%NotAvailable");

        nydusCanalID = AddUpgrade(raceID, "teleporter", 0, 99, 0,
                                  .desc="%NotAvailable");

        evolutionID = AddUpgrade(raceID, "evolution", 0, 99, 0,
                                 .desc="%NotAvailable");

        // Ultimate 1
        mutateID = AddUpgrade(raceID, "mutate", 1, 99,0, .desc="%NotAvailable");
    }

    // Ultimate 2
    AddBurrowUpgrade(raceID, 2, 6, 1);

    // Ultimate 3
    if (GameType == tf2)
    {
        burrowStructID = AddUpgrade(raceID, "burrow_structure", 3, 8, 1,
                                    .energy=5.0);
    }
    else
    {
        burrowStructID = AddUpgrade(raceID, "burrow_structure", 3, 99,0,
                                    .desc="%NotAvailable");
    }

    // Ultimate 4
    hiveQueenID = AddUpgrade(raceID, "hive_queen", 4, 10, 1,
                             .energy=300.0, .cooldown=30.0,
                             .accumulated=true);

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

    if (GameType == tf2)
    {
        GetConfigFloatArray("rate", g_NydusCanalRate, sizeof(g_NydusCanalRate),
                            g_NydusCanalRate, raceID, nydusCanalID);

        m_MutateDisableLevel = GetConfigNum("disable_level", 5, raceID, mutateID);
        m_MutateMultiplyEnergy = bool:GetConfigNum("multiply_energy", true, raceID, mutateID);
        m_MutateMultiplyVespene = bool:GetConfigNum("multiply_vespene", true, raceID, mutateID);

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
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "tf2teleporter"))
        IsTeleporterAvailable(true);
    else if (StrEqual(name, "ztf2grab"))
        IsGravgunAvailable(true);
    else if (StrEqual(name, "remote"))
        IsBuildAvailable(true);
    else if (StrEqual(name, "amp_node"))
        IsAmpNodeAvailable(true);
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
}

public OnMapStart()
{
    SetupRedGlow();
    SetupBlueGlow();
    SetupSmokeSprite();

    SetupDeniedSound();

    SetupMutate();

    SetupSound(spawnWav);
    SetupSound(deathWav);
    SetupSound(mutateWav);
    SetupSound(mutateErr);
    SetupSound(burrowUpWav);
    SetupSound(burrowDownWav);
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
        KillClientTimer(client);

        SetHealthRegen(client, 0.0);
        ResetArmor(client);

        if (m_BuildAvailable && GameType == tf2)
        {
            if (g_hiveQueenRace < 0)
                g_hiveQueenRace = FindRace("hive_queen");

            if (newrace != g_hiveQueenRace)
                DestroyBuildings(client, false);
        }

        if (m_TeleporterAvailable)
            SetTeleporter(client, 0.0);

        return Plugin_Handled;
    }
    else
    {
        if (g_hiveQueenRace < 0)
            g_hiveQueenRace = FindRace("hive_queen");

        if (oldrace == g_hiveQueenRace &&
            GetCooldownExpireTime(client, raceID, hiveQueenID) <= 0.0)
        {
            CreateCooldown(client, raceID, hiveQueenID,
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
        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new teleporter_level = GetUpgradeLevel(client,raceID,nydusCanalID);
        if (teleporter_level > 0)
            SetupTeleporter(client, teleporter_level);

        if (IsValidClientAlive(client))
        {
            if (GameType == tf2 && GetUpgradeLevel(client,raceID,creepID) &&
                (GetUpgradeLevel(client,raceID,mutateID) ||
                 TF2_GetPlayerClass(client) == TFClass_Engineer))
            {
                CreateClientTimer(client, 1.0, CreepTimer,
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
        else if (upgrade==burrowID)
        {
            if (new_level <= 0)
                ResetBurrow(client, true);
        }
        else if (upgrade==creepID)
        {
            if (GameType == tf2 && new_level &&
                (GetUpgradeLevel(client,race,mutateID) ||
                 TF2_GetPlayerClass(client) == TFClass_Engineer))
            {
                if (IsPlayerAlive(client))
                {
                    CreateClientTimer(client, 1.0, CreepTimer,
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
                if (!pressed)
                {
                    if (GetUpgradeLevel(client,race,hiveQueenID))
                        EvolveHiveQueen(client);
                }
            }
            case 3:
            {
                if (GameType == tf2 && GetUpgradeLevel(client,race,burrowStructID))
                {
                    if (pressed)
                        BurrowStructure(client, GetUpgradeEnergy(raceID,burrowStructID));
                }
                else if (!pressed)
                {
                    if (GetUpgradeLevel(client,race,hiveQueenID))
                        EvolveHiveQueen(client);
                }
            }
            case 2:
            {
                new burrow_level=GetUpgradeLevel(client,race,burrowID);
                if (burrow_level > 0)
                {
                    if (pressed)
                        Burrow(client, burrow_level);
                }
                else if (GameType == tf2 && GetUpgradeLevel(client,race,burrowStructID))
                {
                    if (pressed)
                        BurrowStructure(client, GetUpgradeEnergy(raceID,burrowStructID));
                }
                else if (!pressed)
                {
                    if (GetUpgradeLevel(client,race,hiveQueenID))
                        EvolveHiveQueen(client);
                }
            }
            default:
            {
                new mutate_level = GetUpgradeLevel(client,race,mutateID);
                if (mutate_level && m_BuildAvailable && GameType == tf2 && cfgAllowSentries >= 1)
                {
                    if (pressed)
                    {
                        Mutate(client, mutate_level, race, mutateID, evolutionID,
                               cfgMaxObjects, (cfgAllowSentries < 2));
                    }
                }
                else if (GameType == tf2 && GetUpgradeLevel(client,race,burrowStructID))
                {
                    if (pressed)
                        BurrowStructure(client, GetUpgradeEnergy(raceID,burrowStructID));
                }
                else
                {
                    new burrow_level=GetUpgradeLevel(client,race,burrowID);
                    if (burrow_level > 0)
                    {
                        if (pressed)
                            Burrow(client, burrow_level);
                    }
                    else if (!pressed)
                    {
                        if (GetUpgradeLevel(client,race,hiveQueenID))
                            EvolveHiveQueen(client);
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
        
        SetOverrideSpeed(client, -1.0);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        if (GameType == tf2 && GetUpgradeLevel(client,raceID,creepID) &&
            (GetUpgradeLevel(client,raceID,mutateID) ||
             TF2_GetPlayerClass(client) == TFClass_Engineer))
        {
            CreateClientTimer(client, 1.0, CreepTimer,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    SetOverrideSpeed(victim_index, -1.0);

    if (victim_race == raceID)
    {
        PrepareAndEmitSoundToAll(deathWav,victim_index);
        KillClientTimer(victim_index);
    }
    else
    {
        if (g_hiveQueenRace < 0)
            g_hiveQueenRace = FindRace("hive_queen");

        if (victim_race == g_hiveQueenRace &&
            GetCooldownExpireTime(victim_index, raceID, hiveQueenID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, hiveQueenID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
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
            new creep_level=GetUpgradeLevel(client,raceID,creepID);
            if (creep_level && (cfgAllowSentries >= 2) &&
                (GetUpgradeLevel(client,raceID,mutateID) ||
                 TF2_GetPlayerClass(client) == TFClass_Engineer))
            {
                new object, amount = creep_level * 2;
                while ((object = FindEntityByClassname(object, "obj_sentrygun")) != -1)
                {
                    ReplenishObject(client, object, TFObject_Sentry, amount, creep_level);
                }

                while ((object = FindEntityByClassname(object, "obj_teleporter")) != -1)
                {
                    ReplenishObject(client, object, TFObject_Teleporter, amount, creep_level);
                }

                while ((object = FindEntityByClassname(object, "obj_dispenser")) != -1)
                {
                    ReplenishObject(client, object, TFObject_Dispenser, amount, creep_level);
                }
            }
        }
    }
    return Plugin_Continue;
}

ReplenishObject(client, object, TFObjectType:type, amount, num_rockets)
{
    if (GetEntPropEnt(object, Prop_Send, "m_hBuilder") == client &&
        GetEntPropFloat(object, Prop_Send, "m_flPercentageConstructed") >= 1.0)
    {
        new iLevel = GetEntProp(object, Prop_Send, "m_bMiniBuilding") ? 0 : 
                     GetEntProp(object, Prop_Send, "m_iUpgradeLevel");

        if (iLevel > 0 && iLevel < 3)
        {
            new iUpgrade = GetEntProp(object, Prop_Send, "m_iUpgradeMetal");
            if (iUpgrade < TF2_MaxUpgradeMetal)
            {
                iUpgrade += amount;
                if (iUpgrade > TF2_MaxUpgradeMetal)
                    iUpgrade = TF2_MaxUpgradeMetal;
                SetEntProp(object, Prop_Send, "m_iUpgradeMetal", iUpgrade);
            }                                        
        }

        new max_health = GetEntProp(object, Prop_Data, "m_iMaxHealth");
        new health = GetEntProp(object, Prop_Send, "m_iHealth");
        if (health < max_health)
        {
            health += amount;
            if (health > max_health)
                health = max_health;

            SetEntProp(object, Prop_Send, "m_iHealth", health);
        }

        switch (type)
        {
            case TFObject_Dispenser:
            {
                new iMetal = GetEntProp(object, Prop_Send, "m_iAmmoMetal");
                if (iMetal < TF2_MaxDispenserMetal)
                {
                    iMetal += amount;
                    if (iMetal > TF2_MaxDispenserMetal)
                        iMetal = TF2_MaxDispenserMetal;
                    SetEntProp(object, Prop_Send, "m_iAmmoMetal", iMetal);
                }
            }
            case TFObject_Sentry:
            {
                new maxShells = TF2_MaxSentryShells[iLevel];
                new iShells = GetEntProp(object, Prop_Send, "m_iAmmoShells");
                if (iShells < maxShells)
                {
                    iShells += amount;
                    if (iShells > maxShells)
                        iShells = maxShells;
                    SetEntProp(object, Prop_Send, "m_iAmmoShells", iShells);
                }

                if (iLevel > 2)
                {
                    new maxRockets = TF2_MaxSentryRockets[iLevel];
                    new iRockets = GetEntProp(object, Prop_Send, "m_iAmmoRockets");
                    if (iRockets < maxRockets)
                    {
                        iRockets += num_rockets;
                        if (iRockets > maxRockets)
                            iRockets = maxRockets;
                        SetEntProp(object, Prop_Send, "m_iAmmoRockets", iRockets);
                    }
                }
            }
        }
    }
}

SetupTeleporter(client, level)
{
    if (m_TeleporterAvailable)
        SetTeleporter(client, g_NydusCanalRate[level]);
}

EvolveHiveQueen(client)
{
    if (g_hiveQueenRace < 0)
        g_hiveQueenRace = FindRace("hive_queen");

    if (g_hiveQueenRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, hiveQueenID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Zerg Hive Queen race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromHiveQueen");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (HasCooldownExpired(client, raceID, hiveQueenID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_hiveQueenRace, true, false);
    }
}

