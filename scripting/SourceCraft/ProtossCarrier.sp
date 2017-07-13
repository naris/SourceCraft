/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossCarrier.sp
 * Description: The Protoss Carrier unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#include <tf2_flag>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/jetpack>
#include <libtf2/remote>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/SpeedBoost"
#include "sc/AirWeapons"
#include "sc/ShopItems"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/shields"
#include "sc/burrow"
#include "sc/sounds"

new const String:spawnWav[]     = "sc/pcardy00.wav";
new const String:deathWav[]     = "sc/pcadth00.wav";
new const String:launchWav[]    = "sc/pinlau00.wav";

new g_JetpackFuel[]             = { 40,   50,   70,   90,   120 };
new Float:g_JetpackRefuelTime[] = { 45.0, 35.0, 25.0, 15.0, 5.0 };

new Float:g_SpeedLevels[]       = { -1.0, 1.10, 1.15, 1.20, 1.25 };

new Float:m_InterceptorSpeed[4] = { 150.0, 225.0, 325.0, 400.0 };

new Float:g_WeaponsPercent[]    = { 0.0, 0.30, 0.40, 0.50, 0.70 };
new g_WeaponsChance[]           = { 0,   25,   25,   25,   25 };

new Float:g_InitialShields[]    = { 0.0, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ShieldsPercent[][2] = { {0.00, 0.10},
                                    {0.05, 0.20},
                                    {0.10, 0.30},
                                    {0.20, 0.40},
                                    {0.25, 0.50} };

new raceID, weaponsID, shieldsID, thrusterID, jetpackID, interceptorID, capacityID;

new cfgMaxObjects;
new cfgAllowSentries;

public Plugin:myinfo = 
{
    name = "SourceCraft Unit - Protoss Carrier",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Carrier unit for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.carrier.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("carrier", -1, -1, 24, .energy_rate=2.0, .faction=Protoss,
                             .type=Mechanical, .parent="phoenix");

    weaponsID   = AddUpgrade(raceID, "weapons", .energy=2.0, .cost_crystals=20);
    shieldsID   = AddUpgrade(raceID, "shields", .cost_crystals=10);
    thrusterID  = AddUpgrade(raceID, "thrusters", .cost_crystals=0);

    if (GetGameType() == tf2)
    {
        cfgMaxObjects    = GetConfigNum("max_objects", 3);
        cfgAllowSentries = GetConfigNum("allow_sentries", 2);
    }
    else
    {
        cfgMaxObjects    = 0;
        cfgAllowSentries = 0;
    }

    capacityID  = AddUpgrade(raceID, "capacity", 0, 12,
                             (cfgMaxObjects < 5) ? cfgMaxObjects - 1 : 4,
                             .cost_vespene=10, .cost_crystals=20);


    if (GameType != tf2 || !IsRemoteAvailable())
    {
        SetUpgradeDisabled(raceID, capacityID, true);
        LogError("Disabling Protoss Carrier:Capacity due to remote is not available (or gametype != tf2)");
    }
    else if (cfgAllowSentries <= 1 || cfgMaxObjects <= 1)
    {
        SetUpgradeDisabled(raceID, capacityID, true);
        LogMessage("Disabling Protoss Carrier:Capacity due to configuration: sc_allow_sentries=%d, sc_maxobjects=%d",
                   cfgAllowSentries, cfgMaxObjects);
    }

    // Ultimate 1
    jetpackID   = AddUpgrade(raceID, "jetpack", 1, 0, .cost_crystals=25);

    if (!IsJetpackAvailable())
    {
        SetUpgradeDisabled(raceID, jetpackID, true);
        LogError("Disabling Protoss Carrier:Gravitic Drive due to jetpack is not available");
    }

    // Ultimate 2
    interceptorID  = AddUpgrade(raceID, "interceptor", 2, .energy=30.0, .vespene=5, .cooldown=10.0,
                                .cooldown_type=Cooldown_SpecifiesBaseValue, .cost_crystals=50);

    if (GameType != tf2 || !IsRemoteAvailable())
    {
        SetUpgradeDisabled(raceID, interceptorID, true);
        LogMessage("Disabling Protoss Carrier:Launch Interceptor due remote is not available (or gametype != tf2)");
    }
    else if (cfgAllowSentries < 1 || cfgMaxObjects < 1)
    {
        SetUpgradeDisabled(raceID, interceptorID, true);
        LogMessage("Disabling Protoss Carrier:Launch Interceptor due to configuration: sc_allow_sentries=%d, sc_maxobjects=%d",
                    cfgAllowSentries, cfgMaxObjects);
    }

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
                        g_SpeedLevels, raceID, thrusterID);

    GetConfigArray("chance", g_WeaponsChance, sizeof(g_WeaponsChance),
                   g_WeaponsChance, raceID, weaponsID);

    GetConfigFloatArray("damage_percent", g_WeaponsPercent, sizeof(g_WeaponsPercent),
                        g_WeaponsPercent, raceID, weaponsID);

    GetConfigArray("fuel", g_JetpackFuel, sizeof(g_JetpackFuel),
                   g_JetpackFuel, raceID, jetpackID);

    GetConfigFloatArray("refuel_time", g_JetpackRefuelTime, sizeof(g_JetpackRefuelTime),
                        g_JetpackRefuelTime, raceID, jetpackID);

    if (GameType == tf2)
        ParseInterceptorSpeed();
}

ParseInterceptorSpeed()
{
    //Specify either 1 factor (multiplied by level) or 4 values (per level) separated with spaces
    new String:speedValue[32];
    new String:values[sizeof(m_InterceptorSpeed)][8];
    GetConfigString("speed", speedValue, sizeof(speedValue),
                    "150.0 225.0 325.0 400.0",
                    raceID, interceptorID);

    if (speedValue[0])
    {
        new count = ExplodeString(speedValue," ",values, sizeof(values), sizeof(values[]));
        if (count > sizeof(m_InterceptorSpeed))
            count = sizeof(m_InterceptorSpeed);

        new level=0;
        for (;level < count; level++)
            m_InterceptorSpeed[level] = StringToFloat(values[level]);

        for (;level < sizeof(m_InterceptorSpeed); level++)
            m_InterceptorSpeed[level] = m_InterceptorSpeed[level-1] + (m_InterceptorSpeed[0] * 0.50);
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "jetpack"))
        IsJetpackAvailable(true);
    else if (StrEqual(name, "remote"))
        IsRemoteAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "jetpack"))
        m_JetpackAvailable = false;
    else if (StrEqual(name, "remote"))
        m_RemoteAvailable = false;
}

public OnMapStart()
{
    SetupHaloSprite();
    SetupLightning();
    SetupSpeed();

    SetupErrorSound();
    SetupDeniedSound();

    SetupSound(spawnWav);
    SetupSound(deathWav);
    SetupSound(launchWav);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        SetSpeed(client, -1.0, true);

        DestroyBuildings(client, false);

        if (m_JetpackAvailable)
            TakeJetpack(client);

        if (m_RemoteAvailable)
        {
            StopControllingObject(client);
            SetRemoteControl(client, 0);
            ResetBuild(client);
        }
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        Interceptor(client, GetUpgradeLevel(client,raceID,interceptorID));

        new thrusters_level = GetUpgradeLevel(client,raceID,thrusterID);
        SetSpeedBoost(client, thrusters_level, true, g_SpeedLevels);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        if (m_RemoteAvailable)
        {
            new capacity = GetUpgradeLevel(client,raceID,capacityID);
            if (capacity < 1)
                capacity = 1;
            else if (capacity > cfgMaxObjects)
                capacity = cfgMaxObjects;
            GiveBuild(client, capacity, capacity, capacity, capacity);
        }

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==jetpackID)
            SetupJetpack(client, new_level);
        else if (upgrade==thrusterID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==interceptorID)
            Interceptor(client, new_level);
        else if (upgrade==shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, .upgrade=true);
        }
        else if (upgrade==capacityID)
        {
            if (m_RemoteAvailable)
            {
                new capacity = (new_level < 1) ? 1 : new_level;
                if (capacity > cfgMaxObjects)
                    capacity = cfgMaxObjects;
                GiveBuild(client, capacity, capacity, capacity, capacity);
            }
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
            new level=GetUpgradeLevel(client,raceID,thrusterID);
            if (level > 0)
                SetSpeedBoost(client, level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4,3,2:
            {
                if (GameType == tf2 && m_RemoteAvailable && 
                    !GetRestriction(client, Restriction_NoUltimates) &&
                    !GetRestriction(client, Restriction_Stunned) &&
                    (cfgAllowSentries >= 2 ||
                     (cfgAllowSentries >= 1 &&
                      TF2_GetPlayerClass(client) == TFClass_Engineer)))
                {
                    if (pressed)
                        RemoteControlObject(client);
                }
                else if (pressed)
                    PrintHintText(client,"%t", "InterceptorsNotAvailable");
            }
            default:
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
        }
    }
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        PrepareAndEmitSoundToAll(spawnWav,client);

        Interceptor(client, GetUpgradeLevel(client,raceID,interceptorID));

        new thrusters_level = GetUpgradeLevel(client,raceID,thrusterID);
        SetSpeedBoost(client, thrusters_level, true, g_SpeedLevels);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        if (m_RemoteAvailable)
        {
            new capacity = GetUpgradeLevel(client,raceID,capacityID);
            if (capacity < 1)
                capacity = 1;
            else if (capacity > cfgMaxObjects)
                capacity = cfgMaxObjects;
            GiveBuild(client, capacity, capacity, capacity, capacity);
        }

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        victim_index != attacker_index &&
        attacker_race == raceID)
    {
        if (AirWeapons(raceID, weaponsID, event, damage + absorbed, victim_index,
                       attacker_index, g_WeaponsPercent, g_WeaponsChance))
        {
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if (assister_race == raceID)
    {
        if (AirWeapons(raceID, weaponsID, event, damage + absorbed, victim_index,
                       assister_index, g_WeaponsPercent, g_WeaponsChance))
        {
            return Plugin_Handled;
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
    }
}

public Action:OnBuildObject(client, TFExtObjectType:type)
{
    if (GetRace(client) == raceID)
    {
        if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, interceptorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, interceptorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromLaunchingInterceptors");
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (CanInvokeUpgrade(client, raceID, interceptorID, false))
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerTaunting(client) ||
                    TF2_IsPlayerDazed(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return Plugin_Stop;
                }
                //case TFClass_Scout:
                else if (TF2_IsPlayerBonked(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return Plugin_Stop;
                }
                //case TFClass_Spy:
                else if (TF2_IsPlayerCloaked(client) ||
                         TF2_IsPlayerDeadRingered(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return Plugin_Stop;
                }
                else if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            PrepareAndEmitSoundToAll(launchWav,client);
            ChargeForUpgrade(client, raceID, interceptorID);
            DisplayMessage(client,Display_Ultimate, "%t", "LaunchedInterceptor");

            new counts[TFExtObjectType];
            CountBuildings(client, counts);

            new count = counts[type];
            new Float:cooldown = GetUpgradeCooldown(raceID, interceptorID) * float((count > 1) ? count * 2 : 1);
            CreateCooldown(client, raceID, interceptorID, cooldown);
        }
    }
    return Plugin_Continue;
}

public Action:OnControlObject(client, builder, ent)
{
    if (GetRace(client) == raceID)
    {
        if (builder > 0 && builder != client)
        {
            if (GetImmunity(builder,Immunity_Ultimates))
            {
                PrepareAndEmitSoundToClient(client,errorWav);
                DisplayMessage(client, Display_Ultimate, "%t", "TargetIsImmune");
                return Plugin_Stop;
            }
        }

        if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, interceptorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, interceptorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromLaunchingInterceptors");
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerTaunting(client) ||
                    TF2_IsPlayerDazed(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return Plugin_Stop;
                }
                //case TFClass_Scout:
                else if (TF2_IsPlayerBonked(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return Plugin_Stop;
                }
                //case TFClass_Spy:
                else if (TF2_IsPlayerCloaked(client) ||
                         TF2_IsPlayerDeadRingered(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return Plugin_Stop;
                }
                else if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            PrepareAndEmitSoundToAll(launchWav,client);
            ChargeForUpgrade(client, raceID, interceptorID);
        }
    }

    return Plugin_Continue;
}

public Interceptor(client, level)
{
    if (m_RemoteAvailable)
    {
        if (level > 0 && GameType == tf2 &&
            (cfgAllowSentries >= 2 ||
             (cfgAllowSentries >= 1 &&
              TF2_GetPlayerClass(client) == TFClass_Engineer)))
        {
            new flags = HAS_REMOTE | REMOTE_CAN_BUILD_MINI;
            if (level >= 2)
            {
                flags |= REMOTE_CAN_BUILD_LEVEL_1;
                if (level >= 3)
                {
                    flags |= REMOTE_CAN_BUILD_LEVEL_2;
                    if (level >= 4)
                    {
                        flags |= REMOTE_CAN_BUILD_LEVEL_3;
                        //    |  REMOTE_CAN_BUILD_INSTANTLY;
                    }
                }
            }
            new Float:speed = (level > 0) ? ((level <= sizeof(m_InterceptorSpeed))
                                             ? m_InterceptorSpeed[level-1]
                                             : m_InterceptorSpeed[sizeof(m_InterceptorSpeed)-1])
                                          : 0.0;
            SetRemoteControl(client, flags, speed, 500.0 - (float(level) * 100.0));
        }
        else
            SetRemoteControl(client, 0);
    }
}

SetupJetpack(client, level)
{
    if (m_JetpackAvailable)
    {
        if (level >= sizeof(g_JetpackFuel))
        {
            LogError("%d:%N has too many levels in ProtossCarrier::GraviticDrive level=%d, max=%d",
                     client,ValidClientIndex(client),level,sizeof(g_JetpackFuel));

            level = sizeof(g_JetpackFuel)-1;
        }
        GiveJetpack(client, g_JetpackFuel[level], g_JetpackRefuelTime[level],
                    .explode = (level > 2), .burn = (level > 3));
    }
}

