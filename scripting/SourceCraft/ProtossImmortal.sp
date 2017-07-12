 /**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossImmortal.sp
 * Description: The Protoss Immortal race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#include <tf2_meter>
#include <tf2_flag>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/hgrsource>
#include <lib/ubershield>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/MissileAttack"
#include "sc/SpeedBoost"
#include "sc/ShopItems"
#include "sc/maxhealth"
#include "sc/dissolve"
#include "sc/plugins"
#include "sc/shields"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/SendEffects"

new const String:spawnWav[]         = "sc/pdryes06.wav";
new const String:deathWav[]         = "sc/pdrdth00.wav";

new String:g_MissileAttackSound[]   = "sc/pdrfir00.wav";

new raceID, immunityID, speedID, shieldsID, missileID, hardenedShieldsID,  collosusID;

new g_MissileAttackChance[]         = { 5, 10, 15, 25, 35 };
new Float:g_MissileAttackPercent[]  = { 0.15, 0.30, 0.40, 0.50, 0.70 };

new Float:g_SpeedLevels[]           = { 0.80, 0.90, 0.95, 1.00, 1.05 };

new Float:g_InitialShields[]        = { 0.05, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ShieldsPercent[][2]     = { {0.05, 0.10},
                                        {0.10, 0.20},
                                        {0.15, 0.30},
                                        {0.20, 0.40},
                                        {0.25, 0.50} };

new g_collosusRace = -1;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Immortal",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Immortal race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.immortal.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("immortal", -1, -1, 21, .energy_rate=2.0,
                             .faction=Protoss, .type=Cybernetic,
                             .parent="zealot");

    shieldsID   = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);
    speedID     = AddUpgrade(raceID, "speed", .cost_crystals=0);
    missileID   = AddUpgrade(raceID, "ground_weapons", .energy=2.0, .cost_crystals=20);
    immunityID  = AddUpgrade(raceID, "immunity", .cost_crystals=0);

    // Ultimate 1
    hardenedShieldsID = AddUpgrade(raceID, "hard_shields", 1, 8, .energy=60.0,
                                   .cooldown=2.0, .cost_crystals=30);

    if (!IsUberShieldAvailable())
    {
        SetUpgradeDisabled(raceID, hardenedShieldsID, true);
        LogMessage("Disabling Protoss Immortal:Hardened Shields due to ubershield is not available");
    }

    // Ultimate 2
    collosusID = AddUpgrade(raceID, "collosus", 2, 4,1,
                            .energy=100.0, .cooldown=20.0,
                            .accumulated=true, .cost_crystals=50);

    // Set the HGRSource available flag
    IsHGRSourceAvailable();

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
                        g_SpeedLevels, raceID, speedID);

    GetConfigArray("chance", g_MissileAttackChance, sizeof(g_MissileAttackChance),
                   g_MissileAttackChance, raceID, missileID);

    GetConfigFloatArray("damage_percent", g_MissileAttackPercent, sizeof(g_MissileAttackPercent),
                        g_MissileAttackPercent, raceID, missileID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "hgrsource"))
        IsHGRSourceAvailable(true);
    else if (StrEqual(name, "ubershield"))
        IsUberShieldAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "hgrsource"))
        m_HGRSourceAvailable = false;
    else if (StrEqual(name, "ubershield"))
        m_UberShieldAvailable = false;
}

public OnMapStart()
{
    SetupSmokeSprite();
    SetupHaloSprite();
    SetupLightning();
    SetupBlueGlow();
    SetupRedGlow();

    SetupSpeed();

    SetupDeniedSound();

    SetupSound(deathWav);
    SetupSound(spawnWav);
    SetupSound(shieldStopWav);
    SetupSound(shieldStartWav);
    SetupSound(shieldActiveWav);
    SetupMissileAttack(g_MissileAttackSound);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        SetSpeed(client,-1.0, true);

        if (m_UberShieldAvailable)
            TakeUberShield(client);

        // Turn off Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, false);
    }
    else
    {
        if (g_collosusRace < 0)
            g_collosusRace = FindRace("collosus");

        if (oldrace == g_collosusRace &&
            GetCooldownExpireTime(client, raceID, collosusID) <= 0.0)
        {
            CreateCooldown(client, raceID, collosusID,
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
        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav, client);

            // Turn on Immunities
            new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
            DoImmunity(client, immunity_level, true);

            new speed_level = GetUpgradeLevel(client,raceID,speedID);
            SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

            new hard_shields_level=GetUpgradeLevel(client,raceID,hardenedShieldsID);
            if (hard_shields_level > 0)
                SetupUberShield(client, hard_shields_level);

            new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
            SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);
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
        if (upgrade == immunityID)
            DoImmunity(client, new_level, true);
        else if (upgrade==speedID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==hardenedShieldsID)
            SetupUberShield(client, new_level);
        else if (upgrade==shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, .upgrade=true);
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
            new speed_level = GetUpgradeLevel(client,race,speedID);
            SetSpeedBoost(client, speed_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4,3,2:
            {
                new collosus_level = GetUpgradeLevel(client,race,collosusID);
                if (collosus_level > 0)
                    SummonCollosus(client);
                else
                {
                    new hard_shields_level=GetUpgradeLevel(client,race,hardenedShieldsID);
                    if (hard_shields_level)
                        HardenedShields(client, hard_shields_level);
                }
            }
            default:
            {
                new hard_shields_level=GetUpgradeLevel(client,race,hardenedShieldsID);
                if (hard_shields_level)
                    HardenedShields(client, hard_shields_level);
            }
        }
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        PrepareAndEmitSoundToAll(spawnWav, client);

        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new speed_level = GetUpgradeLevel(client,raceID,speedID);
        SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

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
        new weapons_level=GetUpgradeLevel(attacker_index,raceID,missileID);
        if (weapons_level > 0)
        {
            if (MissileAttack(raceID, missileID, weapons_level, event, damage + absorbed, victim_index,
                              attacker_index, victim_index, false, sizeof(g_MissileAttackChance),
                              g_MissileAttackPercent, g_MissileAttackChance, g_MissileAttackSound,
                              "sc_ground_weapons"))
            {
                return Plugin_Handled;
            }
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
        DissolveRagdoll(victim_index, 0.1);
    }
    else
    {
        if (g_collosusRace < 0)
            g_collosusRace = FindRace("collosus");

        if (victim_race == g_collosusRace &&
            GetCooldownExpireTime(victim_index, raceID, collosusID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, collosusID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

DoImmunity(client, level, bool:value)
{
    SetImmunity(client,Immunity_MotionTaking, (value && level >= 1));
    SetImmunity(client,Immunity_ShopItems, (value && level >= 2));
    SetImmunity(client,Immunity_Ultimates, (value && level >= 3));
    SetImmunity(client,Immunity_Upgrades, (value && level >= 4));

    if (value && IsValidClientAlive(client))
    {
        new Float:start[3];
        GetClientAbsOrigin(client, start);

        static const color[4] = { 0, 255, 50, 128 };
        TE_SetupBeamRingPoint(start,30.0,60.0,Lightning(),HaloSprite(),
                              0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
        TE_SendEffectToAll();
    }
}

SummonCollosus(client)
{
    if (g_collosusRace < 0)
        g_collosusRace = FindRace("collosus");

    if (g_collosusRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, collosusID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Protoss Collosus race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "PreventedFromSummoningCollosus");
    }
    else if (CanInvokeUpgrade(client, raceID, collosusID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc,SmokeSprite(),8.0,2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,
                           (GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        ChangeRace(client, g_collosusRace, true, false, true);
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
    new ShieldFlags:flags = Shield_Target_Self  | Shield_Reload_Self |
                            Shield_With_Medigun;
    switch (level)
    {
        case 2: flags |= Shield_Target_Team;

        case 3: flags |= Shield_Target_Team | Shield_Team_Specific |
                         Shield_Reload_Team_Specific;

        case 4: flags |= Shield_Target_Team | Shield_Team_Specific |
                         Shield_Mobile | Shield_Reload_Team_Specific;
    }

    if (level >= 3)
        flags |= Shield_Reload_Location | Shield_Reload_Immobilize;

    return flags;
}

HardenedShields(client, hard_shields_level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, hardenedShieldsID, upgradeName, sizeof(upgradeName), client);

    if (!m_UberShieldAvailable)
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        PrintHintText(client, "%t", "AreNotAvailable", upgradeName);
    }
    else
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        }
        else if (IsMole(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
        }
        else if (GameType == tf2 && TF2_HasTheFlag(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
        }
        else if (m_HGRSourceAvailable && IsGrabbed(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWhileHeld", upgradeName);
        }
        else if (CanInvokeUpgrade(client, raceID, hardenedShieldsID, false))
        {
            new Float:duration = float(hard_shields_level) * 3.0;
            UberShieldTarget(client, duration, GetShieldFlags(hard_shields_level));
            DisplayMessage(client,Display_Ultimate,"%t", "Invoked", upgradeName);
            CreateCooldown(client, raceID, hardenedShieldsID);
        }
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
            GetUpgradeName(raceID, hardenedShieldsID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, hardenedShieldsID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && GameType == tf2 && TF2_HasTheFlag(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, hardenedShieldsID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && m_HGRSourceAvailable && IsGrabbed(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, hardenedShieldsID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnSomeoneBeingHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (!CanInvokeUpgrade(client, raceID, hardenedShieldsID))
            return Plugin_Stop;
    }
    return Plugin_Continue;
}

