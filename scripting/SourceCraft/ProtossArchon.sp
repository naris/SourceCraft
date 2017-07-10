/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossArchon.sp
 * Description: The Protoss Archon race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_meter>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <hgrsource>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/UltimateFeedback"
#include "sc/PsionicRage"
#include "sc/Hallucinate"
#include "sc/clienttimer"
#include "sc/Levitation"
#include "sc/maxhealth"
#include "sc/Feedback"
#include "sc/dissolve"
#include "sc/shields"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/BeamSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"
#include "effect/PlasmaHaloSprite"

new const String:deathWav[]       = "sc/pardth00.wav";
new const String:summonWav[]      = "sc/parrdy00.wav";
new const String:rageReadyWav[]   = "sc/parwht03.wav";
new const String:rageExpireWav[]  = "sc/parwht01.wav";
new const String:psionicBoltWav[] = "sc/parwht02.wav";

new const String:archonWav[][]    = { "sc/paryes00.wav" ,
                                      "sc/paryes01.wav" ,
                                      "sc/paryes02.wav" ,
                                      "sc/paryes03.wav" ,
                                      "sc/parwht00.wav" };

new const String:g_FeedbackSound[]= "sc/mind.mp3";

new raceID, shockwaveID, shieldsID, levitationID, rageID;
new feedbackID, hallucinationID, boltID, ultimateFeedbackID;

new Float:g_ShockwavePercent[]    = { 0.30, 0.40, 0.50, 0.60, 0.80 };

new Float:g_InitialShields[]      = { 0.10, 0.25, 0.50, 0.75, 1.0 };
new Float:g_ShieldsPercent[][2]   = { { 0.05, 0.10 },
                                      { 0.10, 0.20 },
                                      { 0.15, 0.30 },
                                      { 0.20, 0.40 },
                                      { 0.25, 0.50 } };

new Float:g_BoltRange[]           = { 350.0, 400.0, 650.0, 750.0, 900.0};
new g_BoltDamage[][2]             = { { 5, 15},
                                      {15, 25},
                                      {25, 50},
                                      {50, 75},
                                      {75, 100} };

new g_HallucinateChance[]         = { 0, 15, 25, 35, 50 };

new Float:g_LevitationLevels[]    = { 0.92, 0.733, 0.5466, 0.36, 0.26 };

new g_FeedbackChance[]            = { 10, 15, 25, 35, 50 };
new Float:g_FeedbackPercent[][2]  = { { 0.10, 1.00 },
                                      { 0.25, 1.00 },
                                      { 0.40, 1.00 },
                                      { 0.50, 1.00 },
                                      { 0.75, 1.00 } };

new Float:g_FeedbackRange[]       = { 350.0, 400.0, 650.0, 750.0, 900.0 };

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Archon",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Archon race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.psionic_rage.phrases.txt");
    LoadTranslations("sc.hallucinate.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.archon.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("archon", -1, -1, 32, 45.0, -1.0, 2.0,
                                 Protoss, Energy, "templar");

    shockwaveID     = AddUpgrade(raceID, "shockwave", 0, 0, .energy=2.0);
    shieldsID       = AddUpgrade(raceID, "shields", 0, 0, .energy=1.0);
    feedbackID      = AddUpgrade(raceID, "feedback", 0, 0, .energy=2.0);
    levitationID    = AddUpgrade(raceID, "levitation", 0, 0);
    hallucinationID = AddUpgrade(raceID, "hallucination", .energy=2.0);

    // Ultimate 1
    boltID = AddUpgrade(raceID, "psionic_bolt", 1, 4,
                        .energy=45.0, .cooldown=10.0);

    // Ultimate 2
    ultimateFeedbackID = AddUpgrade(raceID, "ultimate_feedback", 2, 10,
                                    .energy=30.0, .cooldown=3.0);

    // Ultimate 3
    rageID = AddUpgrade(raceID, "rage", 3, 12, .energy=180.0,
                        .vespene=20, .cooldown=100.0);

    // Get Configuration Data
    GetConfigFloatArray("damage_percent",  g_ShockwavePercent, sizeof(g_ShockwavePercent),
                        g_ShockwavePercent, raceID, shockwaveID);

    GetConfigFloatArray("shields_amount", g_InitialShields, sizeof(g_InitialShields),
                        g_InitialShields, raceID, shieldsID);

    for (new level=0; level < sizeof(g_ShieldsPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "shields_percent_level_%d", level);
        GetConfigFloatArray(key, g_ShieldsPercent[level], sizeof(g_ShieldsPercent[]),
                            g_ShieldsPercent[level], raceID, shieldsID);
    }

    GetConfigFloatArray("range",  g_BoltRange, sizeof(g_BoltRange),
                        g_BoltRange, raceID, boltID);

    for (new level=0; level < sizeof(g_BoltDamage); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "damage_level_%d", level);
        GetConfigArray(key, g_BoltDamage[level], sizeof(g_BoltDamage[]),
                       g_BoltDamage[level], raceID, boltID);
    }

    GetConfigFloatArray("range",  g_FeedbackRange, sizeof(g_FeedbackRange),
                        g_FeedbackRange, raceID, ultimateFeedbackID);

    GetConfigArray("chance", g_FeedbackChance, sizeof(g_FeedbackChance),
                   g_FeedbackChance, raceID, feedbackID);

    for (new level=0; level < sizeof(g_ShieldsPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "damage_percent_level_%d", level);
        GetConfigFloatArray(key, g_FeedbackPercent[level], sizeof(g_FeedbackPercent[]),
                            g_FeedbackPercent[level], raceID, feedbackID);
    }

    GetConfigFloatArray("gravity",  g_LevitationLevels, sizeof(g_LevitationLevels),
                        g_LevitationLevels, raceID, levitationID);

    GetConfigArray("chance", g_HallucinateChance, sizeof(g_HallucinateChance),
                   g_HallucinateChance, raceID, hallucinationID);

    m_PsionicRageTime = GetConfigFloat("time", m_PsionicRageTime, raceID, rageID);
}

public OnMapStart()
{
    SetupLightning();
    SetupLevitation();
    SetupBeamSprite();
    SetupPlasmaHaloSprite();

    SetupHallucinate();

    SetupUltimateFeedback();
    //SetupDeniedSound();
    //SetupPsionicRage();

    SetupSound(deathWav);
    SetupSound(summonWav);
    SetupSound(rageReadyWav);
    SetupSound(rageExpireWav);
    SetupSound(psionicBoltWav);
    SetupSound(g_FeedbackSound);

    for (new i = 0; i < sizeof(archonWav); i++)
        SetupSound(archonWav[i]);
}

public OnMapEnd()
{
    KillAllClientTimers();
}

public OnPlayerAuthed(client)
{
    m_RageActive[client] = false;
}

public OnClientDisconnect(client)
{
    m_RageActive[client] = false;
    KillClientTimer(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        KillClientTimer(client);
        SetVisibility(client, NormalVisibility);
        SetGravity(client,-1.0, true);

        if (m_RageActive[client])
            EndRage(INVALID_HANDLE, GetClientUserId(client));
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_RageActive[client] = false;

        //Set Archon Color
        new r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 255; g = 0; b = 0; }
        else
        { r = 0; g = 0; b = 255; }

        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b,
                      .apply=false);

        new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
        SetLevitation(client, levitation_level, false, g_LevitationLevels);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields,
                     g_ShieldsPercent, float(shields_level+1),
                     Armor_IsShield|Armor_NoLimit);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(summonWav, client);
            CreateClientTimer(client, 3.0, Exclaimation, TIMER_REPEAT);
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
        if (upgrade==levitationID)
            SetLevitation(client, new_level, true, g_LevitationLevels);
        else if (upgrade == shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, float(new_level+1),
                         Armor_IsShield|Armor_NoLimit,
                         .upgrade=true);
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
            new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
            SetLevitation(client, levitation_level, true, g_LevitationLevels);
        }
    }
}

public Action:OnDropPlayer(client, target)
{
    if (IsValidClientAlive(target) && GetRace(target) == raceID)
    {
        new levitation_level = GetUpgradeLevel(target,raceID,levitationID);
        SetLevitation(target, levitation_level, true, g_LevitationLevels);
    }
    return Plugin_Continue;
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        m_RageActive[client] = false;

        PrepareAndEmitSoundToAll(summonWav, client);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        new shield_amount = SetupShields(client, shields_level, g_InitialShields,
                                         g_ShieldsPercent, float(shields_level+1),
                                         Armor_IsShield|Armor_NoLimit);

        // Adjust Health to offset shields
        new health=GetClientHealth(client)-shield_amount;
        if (health <= 0)
            health = GetMaxHealth(client) / 2;

        SetEntityHealth(client, health);

        //Set Archon Color
        new r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 255; g = 0; b = 0; }
        else
        { r = 0; g = 0; b = 255; }

        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b,
                      .apply=false);

        new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
        SetLevitation(client, levitation_level, false, g_LevitationLevels);

        ApplyPlayerSettings(client);

        CreateClientTimer(client, 3.0, Exclaimation, TIMER_REPEAT);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index)
    {
        if (victim_race == raceID && IsPlayerAlive(attacker_index))
        {
            new feedback_level = GetUpgradeLevel(victim_index,raceID,feedbackID);
            if (Feedback(raceID, feedbackID, feedback_level, damage, absorbed, victim_index,
                         attacker_index, g_FeedbackPercent, g_FeedbackChance, g_FeedbackSound))
            {
                returnCode = Plugin_Changed;
            }
        }

        if (attacker_race == raceID)
        {
            new hallucination_level = GetUpgradeLevel(attacker_index,raceID,hallucinationID);
            new Float:hallucination_amount = GetUpgradeEnergy(raceID,hallucinationID);
            if (Hallucinate(victim_index, attacker_index, hallucination_level,
                            hallucination_amount, g_HallucinateChance))

            {
                returnCode = Plugin_Handled;
            }

            if (PsionicShockwave(damage + absorbed, victim_index, attacker_index))
            {
                returnCode = Plugin_Handled;
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
        new hallucination_level = GetUpgradeLevel(assister_index,raceID,hallucinationID);
        new Float:hallucination_amount = GetUpgradeEnergy(raceID,hallucinationID);
        if (Hallucinate(victim_index, assister_index, hallucination_level,
                        hallucination_amount, g_HallucinateChance))

        {
            returnCode = Plugin_Handled;
        }

        if (PsionicShockwave(damage + absorbed, victim_index, assister_index))
        {
            returnCode = Plugin_Handled;
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
        if (m_RageActive[victim_index])
            EndRage(INVALID_HANDLE, GetClientUserId(victim_index));

        PrepareAndEmitSoundToAll(deathWav,victim_index);
        
        KillClientTimer(victim_index);
        DissolveRagdoll(victim_index, 0.2);
    }
}

public bool:PsionicShockwave(damage, victim_index, index)
{
    new shockwave_level=GetUpgradeLevel(index,raceID,shockwaveID);
    if (!GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned) &&
        !GetImmunity(victim_index,Immunity_HealthTaking) &&
        !GetImmunity(victim_index,Immunity_Upgrades) &&
        !GetImmunity(victim_index,Immunity_Restore) &&
        !IsInvulnerable(victim_index))
    {
        new adj = shockwave_level*10;
        if (GetRandomInt(1,100) <= GetRandomInt(10+adj,100-adj))
        {
            new dmgamt = RoundFloat(float(damage)*g_ShockwavePercent[shockwave_level]);
            if (dmgamt > 0 && CanInvokeUpgrade(index, raceID, shockwaveID, .notify=false))
            {
                new Float:Origin[3];
                GetEntityAbsOrigin(victim_index, Origin);
                Origin[2] += 5;

                FlashScreen(victim_index,RGBA_COLOR_RED);
                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendEffectToAll();

                HurtPlayer(victim_index, dmgamt, index, "sc_shockwave",
                           .type=DMG_SHOCK, .in_hurt_event=true);
                return true;
            }
        }
    }
    return false;
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4,3:
            {
                new rage_level = GetUpgradeLevel(client,race,rageID);
                if (rage_level > 0)
                {
                    PsionicRage(client, race, rageID, rage_level,
                                rageReadyWav, rageExpireWav);
                }
                else
                {
                    new ultimate_feedback_level=GetUpgradeLevel(client,race,ultimateFeedbackID);
                    if (ultimate_feedback_level > 0)
                    {
                        UltimateFeedback(client, raceID, ultimateFeedbackID,
                                         ultimate_feedback_level, g_FeedbackRange);
                    }
                    else
                    {
                        new bolt_level=GetUpgradeLevel(client,race,boltID);
                        if (bolt_level > 0)
                            PsionicBolt(client, bolt_level);
                    }
                }
            }
            case 2:
            {
                new ultimate_feedback_level=GetUpgradeLevel(client,race,ultimateFeedbackID);
                if (ultimate_feedback_level > 0)
                {
                    UltimateFeedback(client, raceID, ultimateFeedbackID,
                                     ultimate_feedback_level, g_FeedbackRange);
                }
                else
                {
                    new rage_level = GetUpgradeLevel(client,race,rageID);
                    if (rage_level > 0)
                    {
                        PsionicRage(client, race, rageID, rage_level,
                                    rageReadyWav, rageExpireWav);
                    }
                    else
                    {
                        new bolt_level=GetUpgradeLevel(client,race,boltID);
                        if (bolt_level > 0)
                            PsionicBolt(client, bolt_level);
                    }
                }
            }
            default:
            {
                new bolt_level=GetUpgradeLevel(client,race,boltID);
                if (bolt_level > 0)
                    PsionicBolt(client, bolt_level);
                else
                {
                    new ultimate_feedback_level=GetUpgradeLevel(client,race,ultimateFeedbackID);
                    if (ultimate_feedback_level > 0)
                    {
                        UltimateFeedback(client, raceID, ultimateFeedbackID,
                                         ultimate_feedback_level, g_FeedbackRange);
                    }
                    else
                    {
                        new rage_level = GetUpgradeLevel(client,race,rageID);
                        if (rage_level > 0)
                        {
                            PsionicRage(client, race, rageID, rage_level,
                                        rageReadyWav, rageExpireWav);
                        }
                    }
                }
            }
        }
    }
}

public Action:Exclaimation(Handle:timer, any:userid) // Every 3.0 seconds
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID)
        {
            new Float:vec[3];
            GetClientEyePosition(client, vec);
            
            new num = GetRandomInt(0,sizeof(archonWav)-1);
            PrepareAndEmitAmbientSound(archonWav[num], vec, client);
        }
    }
    return Plugin_Continue;
}

PsionicBolt(client, level)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, boltID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, boltID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        static const lightningColor[4] = { 10, 200, 255, 255 };

        new Float:range = g_BoltRange[level];
        new dmg = GetRandomInt(g_BoltDamage[level][0],
                               g_BoltDamage[level][1]);

        new Float:lastLoc[3];
        new Float:indexLoc[3];
        new Float:targetLoc[3];
        GetClientAbsOrigin(client, lastLoc);
        lastLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        new count  = 0;
        new last   = client;
        new team   = GetClientTeam(client);
        new target = GetClientAimTarget(client);
        if (target > 0) 
        {
            GetClientAbsOrigin(target, targetLoc);
            targetLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

            if (IsPointInRange(targetLoc, lastLoc, range) &&
                TraceTargetIndex(target, client, targetLoc, lastLoc))
            {
                if (GetClientTeam(target) != team &&
                    !GetImmunity(target,Immunity_Ultimates) &&
                    !GetImmunity(target,Immunity_HealthTaking) &&
                    !GetImmunity(target,Immunity_Restore) &&
                    !IsInvulnerable(target))
                {
                    TE_SetupBeamPoints(lastLoc, targetLoc, Lightning(), PlasmaHaloSprite(),
                                       0, 1, 10.0, 10.0,10.0,2,50.0,lightningColor,255);
                    TE_SendQEffectToAll(client, target);
                    FlashScreen(target,RGBA_COLOR_PURPLE);

                    HurtPlayer(target, dmg, client, "sc_psionic_bolt",
                               .xp=5+level, .type=DMG_ENERGYBEAM);

                    FreezeEntity(target);
                    CreateTimer(2.0,UnfreezePlayer,GetClientUserId(target),TIMER_FLAG_NO_MAPCHANGE);

                    dmg -= GetRandomInt(10,20);
                    lastLoc = targetLoc;
                    last=target;
                    count++;
                }
            }
            else
            {
                target = client;
                targetLoc = lastLoc;
            }
        }
        else
        {
            target = client;
            targetLoc = lastLoc;
        }

        PrepareAndEmitSoundToAll(psionicBoltWav,client);
        
        new lightning  = Lightning();
        new beamSprite = BeamSprite();
        new haloSprite = PlasmaHaloSprite();

        new b_count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

        if (b_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, 10.0, range, beamSprite, haloSprite,
                                  0, 15, 0.5, 5.0, 0.0, lightningColor, 10, 0);

            TE_Send(list, b_count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, range-10.0, range, beamSprite, haloSprite,
                                  0, 15, 0.5, 5.0, 0.0, lightningColor, 10, 0);

            TE_Send(alt_list, alt_count, 0.0);
        }
        
        for (new index=1;index<=MaxClients;index++)
        {
            if (client != index && client != target && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_HealthTaking) &&
                    !GetImmunity(index,Immunity_Restore) &&
                    !IsInvulnerable(index))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(targetLoc, indexLoc, range) &&
                        TraceTargetIndex(client, index, targetLoc, indexLoc))
                    {
                        TE_SetupBeamPoints(lastLoc, indexLoc, lightning, haloSprite,
                                           0, 1, 10.0, 10.0,10.0,2,50.0,lightningColor,255);
                        TE_SendQEffectToAll(last, index);
                        FlashScreen(index,RGBA_COLOR_PURPLE);

                        HurtPlayer(index, dmg, client, "sc_psionic_bolt",
                                   .xp=5+level, .type=DMG_ENERGYBEAM);

                        FreezeEntity(index);
                        CreateTimer(2.0,UnfreezePlayer,GetClientUserId(index),TIMER_FLAG_NO_MAPCHANGE);

                        count++;
                        last=index;
                        lastLoc = indexLoc;
                        dmg -= GetRandomInt(10,20);
                        if (dmg <= 0)
                            break;
                    }
                }
            }
        }

        decl String:upgradeName[64];
        GetUpgradeName(raceID, boltID, upgradeName, sizeof(upgradeName), client);

        if (count)
        {
            DisplayMessage(client, Display_Ultimate, "%t",
                           "ToDamageEnemies", upgradeName,
                           count);
        }
        else
        {
            DisplayMessage(client,Display_Ultimate, "%t",
                           "WithoutEffect", upgradeName);
        }

        CreateCooldown(client, raceID, boltID);
    }
}

