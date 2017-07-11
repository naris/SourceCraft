 /**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossDisrupter.sp
 * Description: The Protoss Disrupter race for SourceCraft.
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
#include <sidewinder>
#include <ubershield>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/MissileAttack"
#include "sc/Hallucinate"
#include "sc/SpeedBoost"
#include "sc/ShopItems"
#include "sc/maxhealth"
#include "sc/Detector"
#include "sc/dissolve"
#include "sc/plugins"
#include "sc/shields"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/HaloSprite"
#include "effect/BeamSprite"
#include "effect/SendEffects"

new const String:spawnWav[]             = "sc/pdrwht07.wav";
new const String:deathWav[]             = "sc/pdrdth00.wav";
new const String:disruptionHitWav[]     = "sc/DragBull.wav";
new const String:disruptionReadyWav[]   = "sc/zhyrdy00.wav";
new const String:disruptionExpireWav[]  = "sc/zhywht01.wav";
new const String:nullVoidWav[]          = "sc/tveemp00.wav";    // EMP sound

new const String:g_MissileAttackSound[] = "sc/pdrfir00.wav";

new raceID, armorID, shieldsID, speedID, missileID, hallucinationID;
new disruptionID, guardianShieldID, forceFieldID, nullVoidID;

new g_MissileAttackChance[]             = { 5, 10, 15, 25, 35 };
new Float:g_MissileAttackPercent[]      = { 0.25, 0.35, 0.50, 0.60, 0.75 };

new g_HallucinateChance[]               = { 15, 25, 35, 50, 75 };
new Float:g_SpeedLevels[]               = { 0.80, 0.90, 0.95, 1.00, 1.05 };
new Float:g_DisruptionRadius[]          = { 300.0, 450.0, 650.0, 750.0, 900.0 };
new Float:g_NullVoidRadius[]            = { 300.0, 500.0, 700.0, 1000.0, 1500.0 };

new Float:g_InitialArmor[]              = { 0.10, 0.20, 0.30, 0.40, 0.50 };
new Float:g_InitialShields[]            = { 0.10, 0.20, 0.30, 0.40, 0.50 };
new Float:g_ShieldsPercent[][2]         = { {0.05, 0.10},
                                            {0.10, 0.20},
                                            {0.15, 0.30},
                                            {0.20, 0.40},
                                            {0.25, 0.50} };

new bool:m_ForceFieldInvoked[MAXPLAYERS+1];
new bool:m_DisruptionActive[MAXPLAYERS+1];

new bool:m_HasBeenDisrupted[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Disrupter",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Disrupter race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.detector.phrases.txt");
    LoadTranslations("sc.disrupter.phrases.txt");
    LoadTranslations("sc.hallucinate.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID           = CreateRace("disrupter", -1, -1, 21, 60.0, 200.0, 2.0,
                                  .faction=Protoss, .type=Cybernetic,
                                  .parent="stalker");

    armorID          = AddUpgrade(raceID, "armor", 0, 0, .cost_crystals=5);
    shieldsID        = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);
    speedID          = AddUpgrade(raceID, "speed", .cost_crystals=0);
    missileID        = AddUpgrade(raceID, "ground_weapons", .energy=2.0, .cost_crystals=20);
    hallucinationID  = AddUpgrade(raceID, "hallucination", .energy=60.0,
                                  .recurring_energy=2.0, .cooldown=2.0, .cost_crystals=25);

    // Ultimate 1
    disruptionID     = AddUpgrade(raceID, "disruption", 1, 1, .energy=60.0,
                                  .recurring_energy=2.0, .cooldown=2.0, .cost_crystals=30);

    // Ultimate 2
    nullVoidID       = AddUpgrade(raceID, "null_void", 2, 10, .energy=80.0,
                                  .cooldown=2.0, .cost_crystals=15);

    // Ultimate 3
    guardianShieldID = AddUpgrade(raceID, "guardian_shield", 3, 8, .energy=60.0,
                                  .cooldown=2.0, .cost_crystals=25);

    // Ultimate 4
    forceFieldID     = AddUpgrade(raceID, "force_field", 4, 8, .energy=100.0,
                                  .cooldown=5.0, .cost_crystals=25);

    if (!IsUberShieldAvailable())
    {
        SetUpgradeDisabled(raceID, guardianShieldID, true);
        SetUpgradeDisabled(raceID, forceFieldID, true);
        LogMessage("Disabling Protoss Disrupter:Guardian & Force Field due to ubershield is not available");
    }

    // Set the HGRSource available flag
    IsHGRSourceAvailable();

    // Set the Sidewinder available flag
    IsSidewinderAvailable();

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

    GetConfigArray("chance", g_HallucinateChance, sizeof(g_HallucinateChance),
                   g_HallucinateChance, raceID, hallucinationID);

    GetConfigArray("chance", g_MissileAttackChance, sizeof(g_MissileAttackChance),
                   g_MissileAttackChance, raceID, missileID);

    GetConfigFloatArray("damage_percent", g_MissileAttackPercent, sizeof(g_MissileAttackPercent),
                        g_MissileAttackPercent, raceID, missileID);

    GetConfigFloatArray("range", g_DisruptionRadius, sizeof(g_DisruptionRadius),
                        g_DisruptionRadius, raceID, disruptionID);

    GetConfigFloatArray("range", g_NullVoidRadius, sizeof(g_NullVoidRadius),
                        g_NullVoidRadius, raceID, nullVoidID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "hgrsource"))
        IsHGRSourceAvailable(true);
    else if (StrEqual(name, "ubershield"))
        IsUberShieldAvailable(true);
    else if (StrEqual(name, "sidewinder") && GetGameType() == tf2)
        IsSidewinderAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "hgrsource"))
        m_HGRSourceAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
    else if (StrEqual(name, "ubershield"))
        m_UberShieldAvailable = false;
}

public OnMapStart()
{
    SetupSpeed();
    SetupHaloSprite();
    SetupBeamSprite();
    SetupHallucinate();

    SetupDeniedSound();

    SetupSound(deathWav);
    SetupSound(spawnWav);
    SetupSound(nullVoidWav);
    SetupSound(disruptionHitWav);
    SetupSound(disruptionReadyWav);
    SetupSound(disruptionExpireWav);
    SetupSound(shieldStopWav);
    SetupSound(shieldStartWav);
    SetupSound(shieldActiveWav);
    SetupMissileAttack(g_MissileAttackSound);
}

public OnPlayerAuthed(client)
{
    m_DisruptionActive[client] = false;
}

public OnClientDisconnect(client)
{
    m_DisruptionActive[client] = false;

    ResetDetected(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        SetSpeed(client,-1.0, true);

        if (m_DisruptionActive[client])
            EndDisruption(INVALID_HANDLE, GetClientUserId(client));
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_DisruptionActive[client] = false;

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav, client);

            new speed_level = GetUpgradeLevel(client,raceID,speedID);
            SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

            new force_field_level=GetUpgradeLevel(client,raceID,forceFieldID);
            new guardian_shield_level=GetUpgradeLevel(client,raceID,guardianShieldID);
            if (force_field_level > 0 || guardian_shield_level > 0)
                SetupUberShield(client, force_field_level, guardian_shield_level);

            new armor_level = GetUpgradeLevel(client,raceID,armorID);
            new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
            SetupArmorAndShields(client, armor_level, shields_level,
                                 g_InitialArmor, g_ShieldsPercent,
                                 g_InitialShields);
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
        if (upgrade==speedID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==forceFieldID)
            SetupUberShield(client, new_level, GetUpgradeLevel(client,race,guardianShieldID));
        else if (upgrade==guardianShieldID)
            SetupUberShield(client, GetUpgradeLevel(client,race,forceFieldID), new_level);
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
            case 4:
            {
                new force_field_level=GetUpgradeLevel(client,race,forceFieldID);
                if (force_field_level > 0)
                    ForceField(client, force_field_level);
                else
                {
                    new disruption_level=GetUpgradeLevel(client,race,disruptionID);
                    if (disruption_level)
                        InvokeDisruption(client, disruption_level);
                    else
                    {
                        new null_void_level=GetUpgradeLevel(client,race,nullVoidID);
                        if (null_void_level)
                            NullVoid(client, null_void_level);
                        else
                        {
                            new guardian_shield_level=GetUpgradeLevel(client,race,guardianShieldID);
                            if (guardian_shield_level)
                                GuardianShield(client, guardian_shield_level);
                        }
                    }
                }
            }
            case 3:
            {
                new guardian_shield_level=GetUpgradeLevel(client,race,guardianShieldID);
                if (guardian_shield_level)
                    GuardianShield(client, guardian_shield_level);
                else
                {
                    new force_field_level=GetUpgradeLevel(client,race,forceFieldID);
                    if (force_field_level > 0)
                        ForceField(client, force_field_level);
                    else
                    {
                        new disruption_level=GetUpgradeLevel(client,race,disruptionID);
                        if (disruption_level)
                            InvokeDisruption(client, disruption_level);
                        else
                        {
                            new null_void_level=GetUpgradeLevel(client,race,nullVoidID);
                            if (null_void_level)
                                NullVoid(client, null_void_level);
                        }
                    }
                }
            }
            case 2:
            {
                new null_void_level=GetUpgradeLevel(client,race,nullVoidID);
                if (null_void_level)
                    NullVoid(client, null_void_level);
                else
                {
                    new guardian_shield_level=GetUpgradeLevel(client,race,guardianShieldID);
                    if (guardian_shield_level)
                        GuardianShield(client, guardian_shield_level);
                    else
                    {
                        new force_field_level=GetUpgradeLevel(client,race,forceFieldID);
                        if (force_field_level > 0)
                            ForceField(client, force_field_level);
                        else
                        {
                            new disruption_level=GetUpgradeLevel(client,race,disruptionID);
                            if (disruption_level)
                                InvokeDisruption(client, disruption_level);
                        }
                    }
                }
            }
            default:
            {
                new disruption_level=GetUpgradeLevel(client,race,disruptionID);
                if (disruption_level)
                    InvokeDisruption(client, disruption_level);
                else
                {
                    new null_void_level=GetUpgradeLevel(client,race,nullVoidID);
                    if (null_void_level)
                        NullVoid(client, null_void_level);
                    else
                    {
                        new guardian_shield_level=GetUpgradeLevel(client,race,guardianShieldID);
                        if (guardian_shield_level)
                            GuardianShield(client, guardian_shield_level);
                        else
                        {
                            new force_field_level=GetUpgradeLevel(client,race,forceFieldID);
                            if (force_field_level > 0)
                                ForceField(client, force_field_level);
                        }
                    }
                }
            }
        }
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        m_DisruptionActive[client] = false;

        PrepareAndEmitSoundToAll(spawnWav, client);

        new speed_level = GetUpgradeLevel(client,raceID,speedID);
        SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupArmorAndShields(client, armor_level, shields_level, g_InitialArmor,
                             g_ShieldsPercent, g_InitialShields);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

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
        new Float:amount = GetUpgradeEnergy(raceID,hallucinationID);
        new level = GetUpgradeLevel(attacker_index,raceID,hallucinationID);
        if (Hallucinate(victim_index, attacker_index, level, amount, g_HallucinateChance))
        {
            returnCode = Plugin_Handled;
        }

        if (m_DisruptionActive[attacker_index] &&
            Disruption(attacker_index, victim_index, damage))
        {
            returnCode = Plugin_Handled;
        }
        else
        {
            new weapons_level=GetUpgradeLevel(attacker_index,raceID,missileID);
            if (weapons_level > 0)
            {
                if (MissileAttack(raceID, missileID, weapons_level, event, damage + absorbed, victim_index,
                                  attacker_index, victim_index, false, sizeof(g_MissileAttackChance),
                                  g_MissileAttackPercent, g_MissileAttackChance,
                                  g_MissileAttackSound, "sc_ground_weapons"))
                {
                    returnCode = Plugin_Handled;
                }
            }
        }
    }

    return returnCode;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    new Action:returnCode = Plugin_Continue;

    if (assister_race == raceID)
    {
        new Float:amount = GetUpgradeEnergy(raceID,hallucinationID);
        new level = GetUpgradeLevel(assister_index,raceID,hallucinationID);
        if (Hallucinate(victim_index, assister_index, level, amount, g_HallucinateChance))
        {
            returnCode = Plugin_Handled;
        }

        if (m_DisruptionActive[assister_index])
        {
            if (Disruption(assister_index, victim_index, damage + absorbed))
            {
                returnCode = Plugin_Handled;
            }
        }
    }

    return returnCode;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_race == raceID)
    {
        if (m_DisruptionActive[victim_index])
            EndDisruption(INVALID_HANDLE, GetClientUserId(victim_index));

        ResetDetected(victim_index);

        PrepareAndEmitSoundToAll(deathWav,victim_index);
        DissolveRagdoll(victim_index, 0.1);
    }
}

public Action:OnPlayerRestored(client)
{
    ResetDetected(client);
}

InvokeDisruption(client, level)
{
    if (level > 0)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, disruptionID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, disruptionID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (CanInvokeUpgrade(client, raceID, disruptionID))
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            PrepareAndEmitSoundToAll(disruptionReadyWav,client);

            PrintHintText(client, "%t", "DisruptionActive");
            HudMessage(client, "%t", "DisruptionHud");

            m_DisruptionActive[client] = true;
            CreateTimer(5.0 * float(level), EndDisruption, GetClientUserId(client),
                        TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:EndDisruption(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0 && m_DisruptionActive[client])
    {
        m_DisruptionActive[client]=false;

        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            PrepareAndEmitSoundToAll(disruptionExpireWav,client);
            PrintHintText(client, "%t", "DisruptionEnded");
        }

        ClearHud(client, "%t", "DisruptionHud");
        CreateCooldown(client, raceID, disruptionID);
    }
}

bool:Disruption(client, target, damage)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        return false;
    }

    if (GameType == tf2)
    {
        if (TF2_IsPlayerTaunting(client) ||
            TF2_IsPlayerDazed(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            return false;
        }
        //case TFClass_Scout:
        else if (TF2_IsPlayerBonked(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            return false;
        }
        //case TFClass_Spy:
        else if (TF2_IsPlayerCloaked(client) ||
                 TF2_IsPlayerDeadRingered(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            return false;
        }
        else if (TF2_IsPlayerDisguised(client))
            TF2_RemovePlayerDisguise(client);
    }

    if (CanProcessUpgrade(client, raceID, disruptionID))
    {
        for(new x=1;x<=MaxClients;x++)
            m_HasBeenDisrupted[client][x]=false;

        new Float:energy = GetEnergy(client);
        new Float:amount = GetUpgradeRecurringEnergy(raceID,disruptionID);
        new level=GetUpgradeLevel(client,raceID,disruptionID);
        DoDisruption(client,g_DisruptionRadius[level],damage,target,level*3, amount, energy);
        SetEnergy(client, energy);
        return true;
    }
    return false;
}

DoDisruption(client,Float:distance,dmg,last,count, Float:amount, &Float:energy)
{
    new team=GetClientTeam(client);
    new Float:lastLoc[3];
    GetEntityAbsOrigin(last,lastLoc);

    new target=-1;
    while (target <= 0)
    {
        for (new index=1;index<=MaxClients;index++)
        {
            if (client != index && !m_HasBeenDisrupted[client][index] &&
                IsClientInGame(index) && IsPlayerAlive(index) &&
                GetClientTeam(index) != team &&
                !GetImmunity(index,Immunity_Ultimates) &&
                !GetImmunity(index,Immunity_HealthTaking) &&
                !IsInvulnerable(index))
            {
                new Float:indexLoc[3];
                GetClientAbsOrigin(index,indexLoc);
                new Float:check=GetVectorDistance(lastLoc,indexLoc);
                if (check < distance && TraceTargetIndex(client, index, lastLoc, indexLoc))
                {
                    // found a candidate, whom is currently the closest
                    target=index;
                    distance=check;
                }
            }
        }

        if (target < 0)
        {
            target = 0;
            for(new x=1;x<=MaxClients;x++)
                m_HasBeenDisrupted[client][x]=false;
        }
        else
            break;
    }

    if (target > 0)
    {
        // found someone
        m_HasBeenDisrupted[client][target]=true; // don't let them get disrupted twice
        HurtPlayer(target, dmg, client, "sc_disruption",
                   .type=DMG_ENERGYBEAM);

        new Float:targetLoc[3];
        GetClientAbsOrigin(target,targetLoc);
        targetLoc[2] += 50.0;
        lastLoc[2]   += 50.0;
        TE_SetupBeamPoints(lastLoc, targetLoc, BeamSprite(), HaloSprite(),
                           0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
        TE_SendEffectToAll();

        PrepareAndEmitSoundToAll(disruptionHitWav,client, .origin=targetLoc);
        FlashScreen(target,RGBA_COLOR_RED);

        energy -= amount;
        if (--count > 0 && energy > 0.0)
        {
            dmg = RoundFloat(float(dmg)*0.75);
            if (dmg > 0)
                DoDisruption(client,distance,dmg,target,count,amount,energy);
        }
    }
}

NullVoid(client, level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, nullVoidID, upgradeName, sizeof(upgradeName), client);

    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "Prevented", upgradeName);
    }
    else if (CanInvokeUpgrade(client, raceID, nullVoidID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        new Float:radius = g_NullVoidRadius[level];
        new Float:targetLoc[3];
        TraceAimPosition(client, targetLoc, true);

        PrepareAndEmitSoundToAll(nullVoidWav,client, .origin=targetLoc);

        new team = GetClientTeam(client);
        new beamColor[4];
        if (team==2)
        {
            beamColor[0]=255;beamColor[1]=0;beamColor[2]=0;beamColor[3]=255;
        }
        else
        {
            beamColor[0]=0;beamColor[1]=0;beamColor[2]=255;beamColor[3]=255;
        }

        new count=0;
        new b_count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

        if (b_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, 0.1, radius, BeamSprite(), g_beamSprite,
                                  1, 1, 0.5, 40.0, 10.0, beamColor, 100, 0);
            TE_Send(list, b_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, 0.1, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 0.75, 40.0, 10.0, beamColor, 100, 0);
            TE_Send(list, b_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, 0.1, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 1.0, 40.0, 10.0, beamColor, 100, 0);
            TE_Send(list, b_count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, radius-10.0, radius, BeamSprite(), g_beamSprite,
                                  1, 1, 0.5, 40.0, 10.0, beamColor, 100, 0);
            TE_Send(alt_list, alt_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, radius-10.0, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 0.75, 40.0, 10.0, beamColor, 100, 0);
            TE_Send(alt_list, alt_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, radius-10.0, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 1.0, 40.0, 10.0, beamColor, 100, 0);
            TE_Send(alt_list, alt_count, 0.0);
        }

        for (new index=1;index<=MaxClients;index++)
        {
            if (index != client && IsClientInGame(index) &&
                IsPlayerAlive(index))
            {
                if (GetClientTeam(index) != team)
                {
                    new bool:detect = !GetImmunity(index,Immunity_Ultimates) &&
                                      IsInRange(client,index,radius);
                    if (detect)
                    {
                        new Float:indexLoc[3];
                        GetClientAbsOrigin(index, indexLoc);
                        detect = TraceTargetIndex(client, index, targetLoc, indexLoc);
                    }

                    if (detect)
                    {
                        new bool:uncloaked = false;

                        if (GameType == tf2 &&
                            !GetImmunity(index,Immunity_Uncloaking) &&
                            TF2_GetPlayerClass(index) == TFClass_Spy)
                        {
                            TF2_RemovePlayerDisguise(index);
                            TF2_RemoveCondition(client,TFCond_Cloaked);

                            new Float:cloakMeter = TF2_GetCloakMeter(index);
                            if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                TF2_SetCloakMeter(index, 0.0);

                            uncloaked = true;
                            HudMessage(index, "%t", "UncloakedHud");
                            DisplayMessage(index, Display_Enemy_Ultimate, "%t",
                                           "HasUndisguised", client, upgradeName);
                        }

                        if (!GetImmunity(index,Immunity_Detection))
                        {
                            SetOverrideVisiblity(index, 255);
                            if (m_SidewinderAvailable)
                                SidewinderDetectClient(index, true);

                            if (!m_Detected[client][index])
                            {
                                m_Detected[client][index] = true;
                                ApplyPlayerSettings(index);
                            }

                            if (!uncloaked)
                            {
                                HudMessage(index, "%t", "DetectedHud");
                                DisplayMessage(index, Display_Enemy_Ultimate, "%t",
                                               "HasDetected", client, upgradeName);
                            }
                        }

                        new Float:energyDrinkMeter = TF2_GetEnergyDrinkMeter(index);
                        if (energyDrinkMeter > 0.0 && energyDrinkMeter <= 100.0)
                            TF2_SetEnergyDrinkMeter(index, 0.0);

                        new Float:chargeMeter = TF2_GetChargeMeter(index);
                        if (chargeMeter > 0.0 && chargeMeter <= 100.0)
                            TF2_SetChargeMeter(index, 0.0);

                        new Float:rageMeter = TF2_GetRageMeter(index);
                        if (rageMeter > 0.0 && rageMeter <= 100.0)
                            TF2_SetRageMeter(index, 0.0);

                        new Float:hypeMeter = TF2_GetHypeMeter(index);
                        if (hypeMeter > 0.0 && hypeMeter <= 100.0)
                            TF2_SetHypeMeter(index, 0.0);
                    }
                    else // undetect
                    {
                        SetOverrideVisiblity(index, -1);
                        if (m_SidewinderAvailable)
                            SidewinderDetectClient(index, false);

                        if (m_Detected[client][index])
                        {
                            m_Detected[client][index] = false;
                            ApplyPlayerSettings(index);
                            ClearDetectedHud(index);
                        }
                    }

                    SetEnergy(index, 0.0);
                    if (HasShields(index))
                        SetArmorAmount(index, 0);
                }
                else
                {
                    if (!GetSetting(index, Disable_OBeacons) &&
                        !GetSetting(index, Remove_Queasiness))
                    {
                        if (GetSetting(index, Reduce_Queasiness))
                            alt_list[alt_count++] = index;
                        else
                            list[count++] = index;
                    }
                }
            }
        }

        if (GameType == tf2)
        {
            new Float:pos[3];
            new maxents = GetMaxEntities();
            for (new ent = MaxClients; ent < maxents; ent++)
            {
                if (IsValidEdict(ent) && IsValidEntity(ent))
                {
                    if (TF2_GetExtObjectType(ent) != TFExtObject_Unknown)
                    {
                        if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team &&
                            !GetEntProp(ent, Prop_Send, "m_bDisabled"))
                        {
                            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
                            if (IsPointInRange(targetLoc,pos,radius) &&
                                TraceTargetEntity(client, ent, targetLoc, pos))
                            {
                                SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
                                CreateTimer(5.0, EnableObject, EntIndexToEntRef(ent));
                            }
                        }
                    }
                }
            }
        }

        static const nullVoidColor[4] = {25, 18, 19, 255};
        targetLoc[2] -= 50.0; // Adjust position back to the feet.

        if (count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, 10.0, 500.0, BeamSprite(), HaloSprite(),
                                  0, 10, 0.6, 100.0, 0.5, nullVoidColor, 10, 0);
            TE_Send(list, count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, 490.0, 500.0, BeamSprite(), HaloSprite(),
                                  0, 10, 0.6, 100.0, 0.5, nullVoidColor, 10, 0);
            TE_Send(alt_list, alt_count, 0.0);
        }

        CreateCooldown(client, raceID, nullVoidID);
    }
}

public Action:EnableObject(Handle:timer, any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent) && IsValidEdict(ent))
    {
        if (!GetEntProp(ent, Prop_Send, "m_bHasSapper"))
        {
            if (GetEntProp(ent, Prop_Send, "m_bDisabled"))
                SetEntProp(ent, Prop_Send, "m_bDisabled", 0);
        }
    }
}

SetupUberShield(client, force_field_level, guardian_shield_level)
{
    static const ShieldFlags:force_field_flags = Shield_Immobilize |
                                                 Shield_Target_Enemy |
                                                 Shield_Target_Location |
                                                 Shield_DisableStopSound;
    if (m_UberShieldAvailable)
    {
        if (guardian_shield_level > 0 || force_field_level > 0)
        {
            GiveUberShield(client, -1, -1,
                           (guardian_shield_level > 0)
                           ? GetGuardianShieldFlags(guardian_shield_level)
                           : force_field_flags);
        }
        else
            TakeUberShield(client);
    }
}

ShieldFlags:GetGuardianShieldFlags(level)
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

GuardianShield(client, null_flux_level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, guardianShieldID, upgradeName, sizeof(upgradeName), client);

    if (!m_UberShieldAvailable)
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
    }
    else
    {
        if (IsMole(client))
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
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        }
        else if (CanInvokeUpgrade(client, raceID, guardianShieldID, false))
        {
            new Float:duration = float(null_flux_level) * 3.0;
            UberShieldTarget(client, duration, GetGuardianShieldFlags(null_flux_level));
            DisplayMessage(client,Display_Ultimate,"%t", "Invoked", upgradeName);
            CreateCooldown(client, raceID, guardianShieldID);
            m_ForceFieldInvoked[client] = false;
        }
    }
}

ForceField(client, force_field_level)
{
    if (!m_UberShieldAvailable)
    {
        PrepareAndEmitSoundToClient(client,deniedWav);

        decl String:upgradeName[64];
        GetUpgradeName(raceID, forceFieldID, upgradeName, sizeof(upgradeName), client);
        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
    }
    else
    {
        if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, forceFieldID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (GameType == tf2 && TF2_HasTheFlag(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, forceFieldID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, forceFieldID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (CanInvokeUpgrade(client, raceID, forceFieldID, false))
        {
            m_ForceFieldInvoked[client] = true;

            new Float:duration = float(force_field_level) + 1.0;
            UberShieldTarget(client, duration, Shield_Immobilize |
                                               Shield_Target_Enemy |
                                               Shield_Target_Location |
                                               Shield_DisableStopSound);

            CreateCooldown(client, raceID, forceFieldID);
        }
    }
}

public Action:OnDeployUberShield(client, target)
{
    if (GetRace(client) == raceID)
    {
        new upgradeID = m_ForceFieldInvoked[client] ? forceFieldID : guardianShieldID;

        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, upgradeID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, upgradeID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && GameType == tf2 && TF2_HasTheFlag(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, upgradeID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && m_HGRSourceAvailable && IsGrabbed(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, upgradeID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnSomeoneBeingHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (!CanInvokeUpgrade(client, raceID, upgradeID))
            return Plugin_Stop;
    }
    return Plugin_Continue;
}

