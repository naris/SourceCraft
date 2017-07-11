/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossTemplar.sp
 * Description: The Protoss Templar race for SourceCraft.
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
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <sidewinder>
#include <hgrsource>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/Hallucinate"
#include "sc/Levitation"
#include "sc/maxhealth"
#include "sc/Feedback"
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
#include "effect/FlashScreen"

new const String:deathWav[]         = "sc/ptedth00.wav";
new const String:spawnWav[]         = "sc/pterdy00.wav";
new const String:psistormWav[]      = "sc/ptesto00.wav";

new const String:g_FeedbackSound[]  = "sc/mind.mp3";

new raceID, immunityID, levitationID, psionicStormID;
new feedbackID, hallucinationID, shieldsID, amuletID;
new archonID;

new g_FeedbackChance[]              = { 0, 15, 25, 35, 50 };
new Float:g_FeedbackPercent[][2]    = { {0.00, 0.00},
                                        {0.05, 0.20},
                                        {0.10, 0.30},
                                        {0.15, 0.40},
                                        {0.20, 0.50} };

new g_HallucinateChance[]           = { 0, 15, 25, 35, 50 };

new Float:g_PsionicStormRange[]     = { 0.0, 250.0, 400.0, 550.0, 650.0 };

new Float:g_LevitationLevels[]      = { 1.0, 0.92, 0.733, 0.5466, 0.36 };

new Float:g_InitialShields[]        = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ShieldsPercent[][2]     = { {0.00, 0.00},
                                        {0.00, 0.05},
                                        {0.02, 0.10},
                                        {0.05, 0.15},
                                        {0.08, 0.20} };

new g_archonRace = -1;

new gPsionicStormDuration[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Templar",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Templar race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.templar.phrases.txt");
    LoadTranslations("sc.hallucinate.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("templar", 48, 0, 29, .energy_rate=2.0,
                                 .faction=Protoss, .type=Biological);

    immunityID      = AddUpgrade(raceID, "immunity", .cost_crystals=0);
    levitationID    = AddUpgrade(raceID, "levitation", .cost_crystals=0);
    feedbackID      = AddUpgrade(raceID, "feedback", .energy=2.0, .cost_crystals=20);
    hallucinationID = AddUpgrade(raceID, "hallucination", .energy=2.0, .cost_crystals=30);

    // Ultimate 1
    psionicStormID = AddUpgrade(raceID, "psistorm", 1, .energy=60.0,
                                .cooldown=2.0, .cost_crystals=30);

    shieldsID       = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);
    amuletID        = AddUpgrade(raceID, "amulet", .cost_crystals=25);

    // Ultimate 2
    archonID        = AddUpgrade(raceID, "archon", 2, 12,1,
                                 .energy=300.0, .cooldown=30.0,
                                 .accumulated=true, .cost_crystals=50);

    // Set the Sidewinder available flag
    IsSidewinderAvailable();

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

    GetConfigFloatArray("range",  g_PsionicStormRange, sizeof(g_PsionicStormRange),
                        g_PsionicStormRange, raceID, psionicStormID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "sidewinder"))
        IsSidewinderAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
}

public OnMapStart()
{
    g_archonRace = -1;

    SetupHallucinate();
    SetupSmokeSprite();
    SetupHaloSprite();
    SetupLevitation();
    SetupLightning();
    SetupBlueGlow();
    SetupRedGlow();

    SetupDeniedSound();

    SetupSound(spawnWav);
    SetupSound(deathWav);
    SetupSound(psistormWav);
    SetupSound(g_FeedbackSound);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        SetInitialEnergy(client, -1.0);
        SetGravity(client,-1.0, true);

        // Turn off Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, false);

        return Plugin_Handled;
    }
    else
    {
        if (g_archonRace < 0)
            g_archonRace = FindRace("archon");

        if (oldrace == g_archonRace &&
            GetCooldownExpireTime(client, raceID, archonID) <= 0.0)
        {
            CreateCooldown(client, raceID, archonID,
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
        // Turn on Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
        SetLevitation(client, levitation_level, true, g_LevitationLevels);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        new amulet_level = GetUpgradeLevel(client,raceID,amuletID);
        if (amulet_level > 0)
            SetInitialEnergy(client, (float(amulet_level+1)*30.0));

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav,client);
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
        else if (upgrade==levitationID)
            SetLevitation(client, new_level, true, g_LevitationLevels);
        else if (upgrade==amuletID)
            SetInitialEnergy(client, (float(new_level+1)*30.0));
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

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race == raceID && IsValidClientAlive(client))
    {
        if (arg >= 2)
        {
            if (!pressed)
            {
                new archon_level = GetUpgradeLevel(client,race,archonID);
                if (archon_level > 0)
                    SummonArchon(client);
            }
        }
        else
        {
            new ps_level = GetUpgradeLevel(client,race,psionicStormID);
            if (ps_level > 0)
            {
                if (pressed)
                    PsionicStorm(client,ps_level);
            }
            else if (!pressed)
            {
                new archon_level = GetUpgradeLevel(client,race,archonID);
                if (archon_level > 0)
                    SummonArchon(client);
            }
        }
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        PrepareAndEmitSoundToAll(spawnWav,client);

        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
        SetLevitation(client, levitation_level, true, g_LevitationLevels);

        new amulet_level = GetUpgradeLevel(client,raceID,amuletID);
        if (amulet_level > 0)
        {
            new Float:initial = float(amulet_level+1) * 30.0;
            SetInitialEnergy(client, initial);
            if (GetEnergy(client, true) < initial)
                SetEnergy(client, initial, true);
        }

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index)
    {
        if (victim_race == raceID && IsValidClientAlive(attacker_index))
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
            new Float:amount = GetUpgradeEnergy(raceID,hallucinationID);
            new level = GetUpgradeLevel(attacker_index,raceID,hallucinationID);
            if (Hallucinate(victim_index, attacker_index, level, amount, g_HallucinateChance))
                returnCode = Plugin_Handled;
        }
    }

    return returnCode;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if (assister_race == raceID)
    {
        new Float:amount = GetUpgradeEnergy(raceID,hallucinationID);
        new level = GetUpgradeLevel(assister_index,raceID,hallucinationID);
        if (Hallucinate(victim_index, assister_index, level, amount, g_HallucinateChance))
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
        PrepareAndEmitSoundToAll(deathWav,victim_index);
        DissolveRagdoll(victim_index, 0.2);
    }
    else
    {
        if (g_archonRace < 0)
            g_archonRace = FindRace("archon");

        if (victim_race == g_archonRace &&
            GetCooldownExpireTime(victim_index, raceID, archonID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, archonID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

DoImmunity(client, level, bool:value)
{
    if (value && level >= 1)
    {
        SetImmunity(client,Immunity_Uncloaking, true);
        SetImmunity(client,Immunity_Detection, true);

        if (m_SidewinderAvailable)
            SidewinderCloakClient(client, true);
    }
    else
    {
        SetImmunity(client,Immunity_Uncloaking, false);

        if (m_SidewinderAvailable &&
            !GetImmunity(client,Immunity_Uncloaking) &&
            !GetImmunity(client,Immunity_Detection))
        {
            SidewinderCloakClient(client, false);
        }
    }

    SetImmunity(client,Immunity_MotionTaking, (value && level >= 2));
    SetImmunity(client,Immunity_Theft, (value && level >= 3));
    SetImmunity(client,Immunity_ShopItems, (value && level >= 4));

    if (value && IsValidClientAlive(client))
    {
        new Float:start[3];
        GetClientAbsOrigin(client, start);

        static const color[4] = { 0, 255, 50, 128 };
        TE_SetupBeamRingPoint(start, 30.0, 60.0, Lightning(), HaloSprite(),
                              0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
        TE_SendEffectToAll();
    }
}

public PsionicStorm(client,ultlevel)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, psionicStormID, upgradeName, sizeof(upgradeName), client);

    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "Prevented", upgradeName);
    }
    else if (CanInvokeUpgrade(client, raceID, psionicStormID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        gPsionicStormDuration[client] = ultlevel*3;

        new Handle:PsionicStormTimer = CreateTimer(0.4, PersistPsionicStorm, GetClientUserId(client),
                                                   TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        TriggerTimer(PsionicStormTimer, true);

        DisplayMessage(client,Display_Ultimate, "%t", "Invoked", upgradeName);
        CreateCooldown(client, raceID, psionicStormID);
    }
}

public Action:PersistPsionicStorm(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client) &&
        !GetRestriction(client,Restriction_NoUltimates) &&
        !GetRestriction(client,Restriction_Stunned))
    {
        new level = GetUpgradeLevel(client,raceID,psionicStormID);
        new Float:range = g_PsionicStormRange[level];

        new Float:lastLoc[3];
        new Float:indexLoc[3];
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);

        new b_count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

        static const psistormColor[4] = { 10, 200, 255, 255 };

        if (b_count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, 10.0, range, Lightning(), HaloSprite(),
                                  0, 15, 0.5, 5.0, 0.0, psistormColor, 10, 0);

            TE_Send(list, b_count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, range-10.0, range, Lightning(), HaloSprite(),
                                  0, 15, 0.5, 5.0, 0.0, psistormColor, 10, 0);

            TE_Send(alt_list, alt_count, 0.0);
        }
        
        clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.
        lastLoc = clientLoc;

        PrepareAndEmitSoundToAll(psistormWav,client);

        new last=client;
        new minDmg=level;
        new maxDmg=level*5;
        new team=GetClientTeam(client);
        for(new index=1;index<=MaxClients;index++)
        {
            if (client != index && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_HealthTaking) &&
                    !IsInvulnerable(index))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(clientLoc,indexLoc,range) &&
                        TraceTargetIndex(client, index, clientLoc, indexLoc))
                    {
                        TE_SetupBeamPoints(lastLoc, indexLoc, Lightning(), HaloSprite(),
                                           0, 1, 10.0, 10.0,10.0,2,50.0,psistormColor,255);
                        TE_SendQEffectToAll(last, index);
                        FlashScreen(index,RGBA_COLOR_RED);

                        new amt=GetRandomInt(minDmg,maxDmg);
                        HurtPlayer(index, amt, client, "sc_psistorm",
                                   .xp=level+5, .type=DMG_ENERGYBEAM);
                        last=index;
                        lastLoc = indexLoc;
                    }
                }
            }
        }

        if (--gPsionicStormDuration[client] > 0)
            return Plugin_Continue;
    }
    return Plugin_Stop;
}

SummonArchon(client)
{
    if (g_archonRace < 0)
        g_archonRace = FindRace("archon");

    if (g_archonRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, archonID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Protoss Archon race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningArchon");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, archonID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        ChangeRace(client, g_archonRace, true, false, true);
    }
}
