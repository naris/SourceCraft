 /**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossCollosus.sp
 * Description: The Protoss Collosus race for SourceCraft.
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
#include <hgrsource>
#include <ubershield>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/MissileAttack"
#include "sc/Levitation"
#include "sc/SpeedBoost"
#include "sc/ShopItems"
#include "sc/maxhealth"
#include "sc/dissolve"
#include "sc/plugins"
#include "sc/shields"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/BeamSprite"
#include "effect/SendEffects"

new const String:spawnWav[]             = "sc/pdryes06.wav";
new const String:deathWav[]             = "sc/pdrdth00.wav";
new const String:thermalLanceWav[]      = "sc/phofir00.wav";
new const String:thermalLanceHit[]      = "sc/phohit00.wav";

new const String:g_MissileAttackSound[] = "sc/pdrfir00.wav";

new raceID, immunityID, speedID, armorID, shieldsID;
new missileID, extendedID, lanceID, nullFluxGeneratorID;

new g_MissileAttackChance[]             = { 5, 10, 15, 25, 35 };
new Float:g_MissileAttackPercent[]      = { 0.20, 0.30, 0.40, 0.50, 0.75 };

new Float:g_SpeedLevels[]               = { 0.60, 0.70, 0.80, 0.90, 1.05 };

new Float:g_LanceRange[]                = { 350.0, 400.0, 650.0, 750.0, 900.0 };
new g_LanceDamage[][2]                  = { { 10,  25},
                                            { 20,  50},
                                            { 40,  60},
                                            { 60,  75},
                                            { 75, 100} };

new Float:g_InitialArmor[]              = { 0.10, 0.20, 0.30, 0.40, 0.50 };
new Float:g_InitialShields[]            = { 0.05, 0.10, 0.25, 0.40, 0.50 };
new Float:g_ShieldsPercent[][2]         = { {0.05, 0.10},
                                            {0.10, 0.20},
                                            {0.15, 0.30},
                                            {0.20, 0.40},
                                            {0.25, 0.50} };

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Collosus",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Collosus race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.collosus.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("collosus", -1, -1, 32, .energy_rate=2.0,
                             .faction=Protoss, .type=Robotic,
                             .parent="immortal");

    armorID     = AddUpgrade(raceID, "armor", 0, 0, .cost_crystals=5);
    shieldsID   = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);
    speedID     = AddUpgrade(raceID, "speed", .cost_crystals=0);
    missileID   = AddUpgrade(raceID, "ground_weapons", .energy=2.0, .cost_crystals=20);
    immunityID  = AddUpgrade(raceID, "immunity", .cost_crystals=0);
    extendedID  = AddUpgrade(raceID, "extended_lance", .cost_crystals=10);

    // Ultimate 1
    lanceID   = AddUpgrade(raceID, "thermal_lance", 1, 0, .energy=90.0,
                           .cooldown=5.0, .cost_crystals=30);

    // Ultimate 2
    nullFluxGeneratorID = AddUpgrade(raceID, "null_flux", 2, 8, .energy=60.0,
                                     .cooldown=2.0, .cost_crystals=25);

    if (!IsUberShieldAvailable())
    {
        SetUpgradeDisabled(raceID, nullFluxGeneratorID, true);
        LogMessage("Disabling Protoss Collosus:Null-Flux Generator due to ubershield is not available");
    }

    // Set the HGRSource available flag
    IsHGRSourceAvailable();

    // Get Configuration Data
    GetConfigFloatArray("armor_amount", g_InitialArmor, sizeof(g_InitialArmor),
                        g_InitialArmor, raceID, armorID);

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

    for (new level=0; level < sizeof(g_LanceDamage); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "damage_level_%d", level);
        GetConfigArray(key, g_LanceDamage[level], sizeof(g_LanceDamage[]),
                       g_LanceDamage[level], raceID, lanceID);
    }

    GetConfigFloatArray("range", g_LanceRange, sizeof(g_LanceRange),
                        g_LanceRange, raceID, lanceID);
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
    SetupBeamSprite();
    SetupHaloSprite();
    SetupLightning();

    SetupLevitation();
    SetupSpeed();

    SetupDeniedSound();

    SetupSound(deathWav);
    SetupSound(spawnWav);
    SetupSound(shieldStopWav);
    SetupSound(shieldStartWav);
    SetupSound(shieldActiveWav);
    SetupSound(thermalLanceWav);
    SetupSound(thermalLanceHit);
    SetupMissileAttack(g_MissileAttackSound);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);

        SetGravity(client,-1.0);
        SetSpeed(client,-1.0, true);

        if (m_UberShieldAvailable)
            TakeUberShield(client);

        // Turn off Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, false);
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        Levitation(client, 0.25, false);

        new speed_level = GetUpgradeLevel(client,raceID,speedID);
        SetSpeedBoost(client, speed_level, false, g_SpeedLevels);

        // Turn on Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new null_flux_level=GetUpgradeLevel(client,raceID,nullFluxGeneratorID);
        if (null_flux_level > 0)
            SetupUberShield(client, null_flux_level);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupArmorAndShields(client, armor_level, shields_level, g_InitialArmor,
                             g_ShieldsPercent, g_InitialShields);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav, client);
            ApplyPlayerSettings(client);
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
        else if (upgrade==nullFluxGeneratorID)
            SetupUberShield(client, new_level);
        else if (upgrade==armorID || upgrade==shieldsID)
        {
            new armor_level = (upgrade==armorID) ? new_level : GetUpgradeLevel(client,raceID,armorID);
            new shields_level = (upgrade==shieldsID) ? new_level : GetUpgradeLevel(client,raceID,shieldsID);
            SetupArmorAndShields(client, armor_level, shields_level, g_InitialArmor,
                                 g_ShieldsPercent, g_InitialShields, .upgrade=true);
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

        if (g_sockItem < 0)
            g_sockItem = FindShopItem("sock");

        if (item == g_bootsItem)
        {
            new speed_level = GetUpgradeLevel(client,race,speedID);
            SetSpeedBoost(client, speed_level, true, g_SpeedLevels);
        }
        else if (item == g_sockItem)
        {
            Levitation(client, 0.25, true);
        }
    }
}

public Action:OnDropPlayer(client, target)
{
    if (IsValidClient(target) && GetRace(target) == raceID)
    {
        Levitation(target, 0.25, true);
    }
    return Plugin_Continue;
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client) && pressed)
    {
        switch (arg)
        {
            case 4,3,2:
            {
                new null_flux_level=GetUpgradeLevel(client,race,nullFluxGeneratorID);
                if (null_flux_level)
                    NullFluxGenerator(client, null_flux_level);
                else
                {
                    new lance_level=GetUpgradeLevel(client,race,lanceID);
                    if (lance_level)
                        ThermalLance(client, lance_level);
                }
            }
            default:
            {
                new lance_level=GetUpgradeLevel(client,race,lanceID);
                if (lance_level)
                    ThermalLance(client, lance_level);
                else
                {
                    new null_flux_level=GetUpgradeLevel(client,race,nullFluxGeneratorID);
                    if (null_flux_level)
                        NullFluxGenerator(client, null_flux_level);
                }
            }
        }
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        PrepareAndEmitSoundToAll(spawnWav, client);

        Levitation(client, 0.25, false);

        new speed_level = GetUpgradeLevel(client,raceID,speedID);
        SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupArmorAndShields(client, armor_level, shields_level, g_InitialArmor,
                             g_ShieldsPercent, g_InitialShields);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (victim_race == raceID)
    {
        new armor_level = GetUpgradeLevel(victim_index,raceID,armorID);
        new shields_level = GetUpgradeLevel(victim_index,raceID,shieldsID);
        new level = (GetShields(victim_index) > g_InitialArmor[armor_level])
                    ? shields_level : armor_level;

        SetShieldsPercent(victim_index, g_ShieldsPercent[level]);
    }

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        new weapons_level=GetUpgradeLevel(attacker_index,raceID,missileID);
        if (weapons_level > 0)
        {
            if (MissileAttack(raceID, missileID, weapons_level, event, damage + absorbed, victim_index,
                              attacker_index, victim_index, false, sizeof(g_MissileAttackPercent),
                              g_MissileAttackPercent, g_MissileAttackChance,
                              g_MissileAttackSound, "sc_ground_weapons"))
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

NullFluxGenerator(client, null_flux_level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, nullFluxGeneratorID, upgradeName, sizeof(upgradeName), client);

    if (!m_UberShieldAvailable)
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
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
        else if (m_HGRSourceAvailable && IsGrabbed(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWhileHeld", upgradeName);
        }
        else if (GameType == tf2 && TF2_HasTheFlag(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
        }
        else if (CanInvokeUpgrade(client, raceID, nullFluxGeneratorID, false))
        {
            new Float:duration = float(null_flux_level) * 3.0;
            UberShieldTarget(client, duration, GetShieldFlags(null_flux_level));
            DisplayMessage(client,Display_Ultimate,"%t", "Invoked", upgradeName);
            CreateCooldown(client, raceID, nullFluxGeneratorID);
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
            GetUpgradeName(raceID, nullFluxGeneratorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, nullFluxGeneratorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GameType == tf2 && TF2_HasTheFlag(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, nullFluxGeneratorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (m_HGRSourceAvailable && IsGrabbed(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, nullFluxGeneratorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWhileHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && GameType == tf2 && TF2_HasTheFlag(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, nullFluxGeneratorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && m_HGRSourceAvailable && IsGrabbed(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, nullFluxGeneratorID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnSomeoneBeingHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (!CanInvokeUpgrade(client, raceID, nullFluxGeneratorID))
            return Plugin_Stop;
    }
    return Plugin_Continue;
}

ThermalLance(client, level)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, lanceID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, lanceID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GameType == tf2 && TF2_IsPlayerDisguised(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, lanceID))
    {
        new Float:range = g_LanceRange[GetUpgradeLevel(client,raceID,extendedID)];
        new dmg = GetRandomInt(g_LanceDamage[level][0], g_LanceDamage[level][1]);

        new Float:indexLoc[3];
        new Float:targetLoc[3];
        new Float:clientLoc[3];
        GetClientEyePosition(client, clientLoc);

        new lightning  = Lightning();
        new haloSprite = HaloSprite();
        new beamSprite = BeamSprite();
        static const lanceColor[4] = {139, 69, 19, 255};

        new count   = 0;
        new xplevel = level+5;
        new team    = GetClientTeam(client);
        new target  = GetClientAimTarget(client);
        if (target > 0)
        {
            GetClientAbsOrigin(target, targetLoc);
            targetLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

            if (IsPointInRange(clientLoc, targetLoc, range) &&
                TraceTargetIndex(target, client, targetLoc, clientLoc))
            {
                if (GetClientTeam(target) != team &&
                    !GetImmunity(target,Immunity_HealthTaking) &&
                    !GetImmunity(target,Immunity_Ultimates) &&
                    !IsInvulnerable(target))
                {
                    TE_SetupBeamPoints(clientLoc,targetLoc, lightning, haloSprite,
                                       0, 1, 10.0, 10.0,10.0,2,50.0,lanceColor,255);
                    TE_SendQEffectToAll(client,target);

                    PrepareAndEmitSoundToAll(thermalLanceWav, target);

                    HurtPlayer(target, dmg, client, "sc_thermal_lance",
                               .xp=xplevel, .no_suicide=true, .limit=0.0);

                    dmg -= GetRandomInt(10,20);
                    count++;
                }
            }
            else
            {
                target = client;
                targetLoc = clientLoc;
            }

        }
        else
        {
            target = client;
            targetLoc = clientLoc;
        }

        new b_count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

        if (b_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, 10.0, range, beamSprite, haloSprite,
                                  0, 15, 0.5, 5.0, 0.0, lanceColor, 10, 0);

            TE_Send(list, b_count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, range-10.0, range, beamSprite, haloSprite,
                                  0, 15, 0.5, 5.0, 0.0, lanceColor, 10, 0);

            TE_Send(alt_list, alt_count, 0.0);
        }

        PrepareAndEmitSoundToAll(thermalLanceWav, client);

        targetLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        for (new index=1;index<=MaxClients;index++)
        {
            if (index != client && index != target && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_HealthTaking) &&
                    !IsInvulnerable(index))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(targetLoc,indexLoc,range) &&
                        TraceTargetIndex(target, index, targetLoc, indexLoc))
                    {
                        TE_SetupBeamPoints(clientLoc, indexLoc, lightning, haloSprite,
                                           0, 1, 10.0, 10.0,10.0,2,50.0,lanceColor,255);
                        TE_SendQEffectToAll(client, index);

                        HurtPlayer(index, dmg, client, "sc_thermal_lance",
                                   .xp=xplevel, .no_suicide=true, .limit=0.0);

                        PrepareAndEmitSoundToAll(thermalLanceHit, index);

                        count++;
                        dmg -= GetRandomInt(10,20);
                        if (dmg <= 0)
                            break;
                    }
                }
            }
        }

        decl String:upgradeName[64];
        GetUpgradeName(raceID, lanceID, upgradeName, sizeof(upgradeName), client);

        if (count)
        {
            DisplayMessage(client, Display_Ultimate, "%t", "ToDamageEnemies",
                           upgradeName, count);
        }
        else
        {
            DisplayMessage(client,Display_Ultimate, "%t", "WithoutEffect",
                           upgradeName);
        }

        CreateCooldown(client, raceID, lanceID);
    }
}
