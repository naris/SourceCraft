/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossPhoenix.sp
 * Description: The Protoss Phoenix unit for SourceCraft.
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
#include <lib/hgrsource>
#define REQUIRE_PLUGIN

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <lib/trace>

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

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:spawnWav[]     = "sc/pscrdy00.wav";
new const String:deathWav[]     = "sc/pscdth00.wav";

new g_JetpackFuel[]             = { 0,     20,   25,   35,   45 };
new Float:g_JetpackRefuelTime[] = { 0.0, 45.0, 35.0, 25.0, 15.0 };

new g_GravitonBeamDuration[]    = { 0,      20,     50,     80,     -1 };
new Float:g_GravitonBeamRange[] = { 0.0, 500.0, 1500.0, 2500.0, 3500.0 };

new Float:g_WeaponsPercent[]    = { 0.0, 0.15, 0.30, 0.40, 0.50 };
new g_WeaponsChance[]           = { 0,     15,   20,   25,   30 };

new Float:g_SpeedLevels[]       = { -1.0, 1.10, 1.15, 1.20, 1.25 };

new Float:g_InitialShields[]    = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ShieldsPercent[][2] = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.20},
                                    {0.05, 0.40},
                                    {0.10, 0.50} };

new raceID, weaponsID, shieldsID, thrusterID, jetpackID, beamID, carrierID;

new g_carrierRace = -1;

public Plugin:myinfo = 
{
    name = "SourceCraft Unit - Protoss Phoenix",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Phoenix unit for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.phoenix.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("phoenix", 64, 0, 21, .energy_rate=2.0,
                             .faction=Protoss, .type=Mechanical);

    weaponsID   = AddUpgrade(raceID, "weapons", .energy=2.0, .cost_crystals=20);
    shieldsID   = AddUpgrade(raceID, "shields", .cost_crystals=10);
    thrusterID  = AddUpgrade(raceID, "thrusters", .cost_crystals=0);

    // Ultimate 1
    jetpackID = AddUpgrade(raceID, "jetpack", 1, .cost_crystals=25);

    if (!IsJetpackAvailable())
    {
        SetUpgradeDisabled(raceID, jetpackID, true);
        LogMessage("Disabling Protoss Phoenix:Gravitic Drive due to jetpack is not available");
    }

    // Ultimate 2
    beamID  = AddUpgrade(raceID, "beam", 2, .energy=1.0, .recurring_energy=1.0,
                         .cooldown=2.0, .cost_crystals=40);

    if (!IsHGRSourceAvailable())
    {
        SetUpgradeDisabled(raceID, beamID, true);
        LogMessage("Disabling Protoss Phoenix:Graviton Beam due to hgrsource is not available");
    }

    // Ultimate 3
    carrierID = AddUpgrade(raceID, "carrier", 3, 16,1,
                           .energy=300.0, .cooldown=60.0,
                           .accumulated=true, .cost_crystals=50);

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

    GetConfigFloatArray("damage_percent", g_WeaponsPercent, sizeof(g_WeaponsPercent),
                        g_WeaponsPercent, raceID, weaponsID);

    GetConfigArray("chance", g_WeaponsChance, sizeof(g_WeaponsChance),
                   g_WeaponsChance, raceID, weaponsID);

    GetConfigArray("fuel", g_JetpackFuel, sizeof(g_JetpackFuel),
                   g_JetpackFuel, raceID, jetpackID);

    GetConfigFloatArray("refuel_time", g_JetpackRefuelTime, sizeof(g_JetpackRefuelTime),
                        g_JetpackRefuelTime, raceID, jetpackID);

    GetConfigArray("duration", g_GravitonBeamDuration, sizeof(g_GravitonBeamDuration),
                   g_GravitonBeamDuration, raceID, beamID);

    GetConfigFloatArray("range", g_GravitonBeamRange, sizeof(g_GravitonBeamRange),
                        g_GravitonBeamRange, raceID, beamID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "jetpack"))
        IsJetpackAvailable(true);
    else if (StrEqual(name, "hgrsource"))
        IsHGRSourceAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "jetpack"))
        m_JetpackAvailable = false;
    else if (StrEqual(name, "hgrsource"))
        m_HGRSourceAvailable = false;
}

public OnMapStart()
{
    SetupSmokeSprite();
    SetupAirWeapons();
    SetupBlueGlow();
    SetupRedGlow();
    SetupSpeed();

    SetupErrorSound();
    SetupDeniedSound();

    SetupSound(spawnWav);
    SetupSound(deathWav);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        SetSpeed(client, -1.0, true);
        SetupGravitonBeam(client, 0);
        SetupJetpack(client, 0);
    }
    else
    {
        if (g_carrierRace < 0)
            g_carrierRace = FindRace("carrier");

        if (oldrace == g_carrierRace &&
            GetCooldownExpireTime(client, raceID, carrierID) <= 0.0)
        {
            CreateCooldown(client, raceID, carrierID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        SetupGravitonBeam(client, GetUpgradeLevel(client,raceID,beamID));

        new thrusters_level = GetUpgradeLevel(client,raceID,thrusterID);
        SetSpeedBoost(client, thrusters_level, true, g_SpeedLevels);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

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
        else if (upgrade==beamID)
            SetupGravitonBeam(client, new_level);
        else if (upgrade==shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, .upgrade=true);
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
            new level = GetUpgradeLevel(client,raceID,thrusterID);
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
            case 4,3:
            {
                new carrier_level=GetUpgradeLevel(client,race,carrierID);
                if (carrier_level > 0)
                {
                    if (!pressed)
                        SummonCarrier(client);
                }
            }
            case 2:
            {
                new beam_level = GetUpgradeLevel(client,raceID,beamID);
                if (beam_level > 0)
                {
                    if (m_HGRSourceAvailable)
                    {
                        if (pressed)
                        {
                            if (GameType == tf2)
                            {
                                if (TF2_IsPlayerDisguised(client))
                                    TF2_RemovePlayerDisguise(client);
                            }

                            if (GetRestriction(client, Restriction_NoUltimates) ||
                                GetRestriction(client, Restriction_Stunned))
                            {
                                PrepareAndEmitSoundToClient(client,deniedWav);

                                decl String:upgradeName[64];
                                GetUpgradeName(raceID, beamID, upgradeName, sizeof(upgradeName), client);
                                DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                            }
                            else if (CanInvokeUpgrade(client, raceID, beamID, false))
                                Grab(client);
                        }
                        else
                            Drop(client);
                    }
                    else if (pressed)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, beamID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                        PrepareAndEmitSoundToClient(client,deniedWav);
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
                        PrepareAndEmitSoundToClient(client,deniedWav);
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

        SetupGravitonBeam(client, GetUpgradeLevel(client,raceID,beamID));

        new thrusters_level = GetUpgradeLevel(client,raceID,thrusterID);
        SetSpeedBoost(client, thrusters_level, true, g_SpeedLevels);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
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
    else
    {
        if (g_carrierRace < 0)
            g_carrierRace = FindRace("carrier");

        if (victim_race == g_carrierRace &&
            GetCooldownExpireTime(victim_index, raceID, carrierID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, carrierID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

public Action:OnGrabPlayer(client, target)
{
    TraceInto("ProtossPhoenix", "OnGrabPlayer", "client=%d:%N, client=%d:%N", \
              client, ValidClientIndex(client), target, ValidClientIndex(target));

    if (GetRace(client) != raceID)
    {
        TraceReturn();
        return Plugin_Continue;
    }
    else if (!IsValidClientAlive(target))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        TraceReturn("IsValidClientAlive() failed");
        return Plugin_Stop;
    }
    else if (GetClientTeam(client) == GetClientTeam(target))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "TargetIsTeammate");
        PrepareAndEmitSoundToClient(client,errorWav);
        TraceReturn("GetClientTeam() failed;");
        return Plugin_Stop;
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, beamID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
        TraceReturn("GetRestriction() failed;");
        return Plugin_Stop;
    }
    else if (GetImmunity(target,Immunity_Ultimates))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "TargetIsImmune");
        PrepareAndEmitSoundToClient(client,errorWav);
        TraceReturn("GetImmunity() failed;");
        return Plugin_Stop;
    }
    else if (IsBurrowed(target))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "TargetIsBurrowed");
        PrepareAndEmitSoundToClient(client,errorWav);
        TraceReturn(" IsBurrowed() failed;");
        return Plugin_Stop;
    }
    else if (CanInvokeUpgrade(client, raceID, beamID))
    {
        if (GameType == tf2)
        {
            // Don't let flag carrier get grabbed to prevent crashes.
            if (GameType == tf2 && TF2_HasTheFlag(target))
            {
                decl String:upgradeName[64];
                GetUpgradeName(raceID, beamID, upgradeName, sizeof(upgradeName), client);
                DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_HasTheFlag() failed;");
                return Plugin_Stop;
            }
            else if (TF2_IsPlayerTaunting(client) ||
                     TF2_IsPlayerDazed(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_IsPlayerTaunting() || TF2_IsPlayerDazed() failed;");
                return Plugin_Stop;
            }
            //case TFClass_Scout:
            else if (TF2_IsPlayerBonked(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_IsPlayerBonked() failed;");
                return Plugin_Stop;
            }
            //case TFClass_Spy:
            else if (TF2_IsPlayerCloaked(client) ||
                     TF2_IsPlayerDeadRingered(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_IsPlayerCloaked() || TF2_IsPlayerDeadRingered() failed;");
                return Plugin_Stop;
            }
            else if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        if (CanInvokeUpgrade(client, raceID, beamID))
        {
            if (IsBurrowed(target))
                ResetBurrow(target, true);

            SetOverrideGravity(target, 0.0);
            SetEntPropFloat(target, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
            SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);

            TraceReturn("Plugin_Continue");
            return Plugin_Continue;
        }
        else
        {
            TraceReturn("CanInvokeUpgrade() failed;");
            return Plugin_Stop;
        }
    }
    TraceReturn("Plugin_Stop");
    return Plugin_Stop;
}

public Action:OnDragPlayer(client, target)
{
    TraceInto("ProtossPhoenix", "OnDragPlayer", "client=%d:%N, client=%d:%N", \
              client, ValidClientIndex(client), target, ValidClientIndex(target));

    if (GetRace(client) == raceID && IsValidClient(client) &&
        IsValidClientAlive(target))
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, beamID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            TraceReturn("GetRestriction() failed;");
            return Plugin_Stop;
        }
        else
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerTaunting(client) ||
                    TF2_IsPlayerDazed(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    TraceReturn("TF2_IsPlayerTaunting() || TF2_IsPlayerDazed() failed;");
                    return Plugin_Stop;
                }
                //case TFClass_Scout:
                else if (TF2_IsPlayerBonked(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    TraceReturn("TF2_IsPlayerBonked() failed;");
                    return Plugin_Stop;
                }
                //case TFClass_Spy:
                else if (TF2_IsPlayerCloaked(client) ||
                         TF2_IsPlayerDeadRingered(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    TraceReturn("TF2_IsPlayerCloaked() || TF2_IsPlayerDeadRingered() failed;");
                    return Plugin_Stop;
                }
                else if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            if (CanProcessUpgrade(client, raceID, beamID))
            {
                if (IsBurrowed(target))
                    ResetBurrow(target, true);

                SetEntPropFloat(target, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
                SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
                TraceReturn("Plugin_Continue");
                return Plugin_Continue;
            }
            else
            {
                TraceReturn("CanProcessUpgrade() failed");
                return Plugin_Stop;
            }
        }
    }
    else
    {
        TraceReturn("Plugin_Continue");
        return Plugin_Continue;
    }
}

public Action:OnDropPlayer(client, target)
{
    if (client > 0 && GetRace(client) == raceID)
    {
        if (IsValidClient(target))
        {
            SetOverrideGravity(target, -1.0, true, true);
            if (IsPlayerAlive(target))
                SetEntPropFloat(target, Prop_Send, "m_flNextAttack", GetGameTime());
        }

        if (IsValidClient(client))
        {
            if (IsPlayerAlive(client))
                SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime());

            CreateCooldown(client, raceID, beamID);
        }
    }
    return Plugin_Continue;
}

public SetupGravitonBeam(client, level)
{
    if (m_HGRSourceAvailable)
    {
        if (level > 0)
        {
            GiveGrab(client,g_GravitonBeamDuration[level],
                            g_GravitonBeamRange[level],
                            0.0,1);
        }
        else
            TakeGrab(client);
    }
}

SetupJetpack(client, level)
{
    if (m_JetpackAvailable)
    {
        if (level > 0)
        {
            GiveJetpack(client, g_JetpackFuel[level], g_JetpackRefuelTime[level]);
        }
        else
            TakeJetpack(client);
    }
}

SummonCarrier(client)
{
    if (g_carrierRace < 0)
        g_carrierRace = FindRace("carrier");

    if (g_carrierRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, carrierID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Protoss Carrier race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningCarrier");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, carrierID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_carrierRace, true, false, true);
    }
}

