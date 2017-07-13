/**
 * vim: set ai et ts=4 sw=4 :
 * File: DarkArchon.sp
 * Description: The Protoss Dark Archon race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_meter>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <libtf2/sidewinder>
#include "sc/MindControl"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/PsionicRage"
#include "sc/UltimateFeedback"
#include "sc/MeleeAttack"
#include "sc/clienttimer"
#include "sc/maxhealth"
#include "sc/dissolve"
#include "sc/plugins"
#include "sc/shields"
#include "sc/freeze"
#include "sc/burrow"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/FlashScreen"

new const String:deathWav[]      = "sc/pardth00.wav";
new const String:summonWav[]     = "sc/pdardy00.wav";
new const String:rageReadyWav[]  = "sc/pdapss03.wav";
new const String:rageExpireWav[] = "sc/pdawht00.wav";

new const String:archonWav[][]   = { "sc/pdapss00.wav" ,
                                     "sc/pdapss01.wav" ,
                                     "sc/pdapss02.wav" ,
                                     "sc/pdayes01.wav" ,
                                     "sc/pdayes03.wav" ,
                                     "sc/pdawht00.wav" ,
                                     "sc/pdawht02.wav" ,
                                     "sc/pdawht03.wav" };

new const String:g_PsiBladesSound[] = "sc/uzefir00.wav";

new raceID, shockwaveID, shieldsID, meleeID, rageID;
new maelstormID, controlID, ultimateFeedbackID;

new g_MindControlChance[]       = { 30, 50, 70, 90, 95 };
new Float:g_MindControlRange[]  = { 150.0, 300.0, 450.0, 650.0, 800.0 };
new Float:g_MaelstormRange[]    = { 350.0, 400.0, 650.0, 750.0, 900.0 };
new Float:g_PsiBladesPercent[]  = { 0.15, 0.30, 0.40, 0.50, 0.70 };
new Float:g_ShockwavePercent[]  = { 0.30, 0.40, 0.50, 0.60, 0.80 };

new Float:g_FeedbackRange[]     = { 350.0, 400.0, 650.0, 750.0, 900.0 };

new Float:g_InitialShields[]      = { 0.10, 0.25, 0.50, 0.75, 1.0 };
new Float:g_ShieldsPercent[][2]   = { { 0.05, 0.10 },
                                      { 0.10, 0.20 },
                                      { 0.15, 0.30 },
                                      { 0.20, 0.40 },
                                      { 0.25, 0.50 } };

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
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.detector.phrases.txt");
    LoadTranslations("sc.dark_archon.phrases.txt");
    LoadTranslations("sc.mind_control.phrases.txt");
    LoadTranslations("sc.psionic_rage.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID = CreateRace("dark_archon", -1, -1, 28, 45.0, 100.0, 2.0,
                        Protoss, Energy, "dark_templar");

    shockwaveID = AddUpgrade(raceID, "shockwave", 0, 0, .energy=2.0, .cost_crystals=20);
    shieldsID   = AddUpgrade(raceID, "shields", 0, 0, .energy=1.0, .cost_crystals=10);
    meleeID     = AddUpgrade(raceID, "blades", 0, 0, .energy=2.0, .cost_crystals=10);

    // Ultimate 1
    maelstormID = AddUpgrade(raceID, "maelstorm", 1, 0, .energy=45.0, .cooldown=2.0, .cost_crystals=30);

    // Ultimate 2
    controlID   = AddUpgrade(raceID, "mind_control", 2, .energy=45.0, .cooldown=2.0, .cost_crystals=30);

    if (GetGameType() != tf2 || !IsMindControlAvailable())
    {
        SetUpgradeDisabled(raceID, controlID, true);
        LogMessage("Disabling Protoss Dark Archon:Mind Control due to MindControl is not available (or gametype != tf2)");
    }

    // Ultimate 3
    ultimateFeedbackID = AddUpgrade(raceID, "ultimate_feedback", 3, 8, .energy=30.0, .cooldown=3.0, .cost_crystals=30);

    // Ultimate 4
    rageID = AddUpgrade(raceID, "rage", 4, 12, .energy=180.0, .vespene=20, .cooldown=100.0, .cost_crystals=50);

    // Set the Sidewinder available flag
    IsSidewinderAvailable();

    // Get Configuration Data
    GetConfigFloatArray("damage_percent",  g_ShockwavePercent, sizeof(g_ShockwavePercent),
                        g_ShockwavePercent, raceID, shockwaveID);

    GetConfigFloatArray("shields_amount",  g_InitialShields, sizeof(g_InitialShields),
                        g_InitialShields, raceID, shieldsID);

    for (new level=0; level < sizeof(g_ShieldsPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "shields_percent_level_%d", level);
        GetConfigFloatArray(key, g_ShieldsPercent[level], sizeof(g_ShieldsPercent[]),
                            g_ShieldsPercent[level], raceID, shieldsID);
    }

    GetConfigFloatArray("damage_percent",  g_PsiBladesPercent, sizeof(g_PsiBladesPercent),
                        g_PsiBladesPercent, raceID, meleeID);

    GetConfigFloatArray("range",  g_MaelstormRange, sizeof(g_MaelstormRange),
                        g_MaelstormRange, raceID, maelstormID);

    GetConfigArray("chance", g_MindControlChance, sizeof(g_MindControlChance),
                   g_MindControlChance, raceID, controlID);

    GetConfigFloatArray("range",  g_MindControlRange, sizeof(g_MindControlRange),
                        g_MindControlRange, raceID, controlID);

    GetConfigFloatArray("range",  g_FeedbackRange, sizeof(g_FeedbackRange),
                        g_FeedbackRange, raceID, ultimateFeedbackID);

    m_PsionicRageTime = GetConfigFloat("time", m_PsionicRageTime, raceID, rageID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "MindControl"))
        IsMindControlAvailable(true);
    else if (StrEqual(name, "sidewinder"))
        IsSidewinderAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "MindControl"))
        m_MindControlAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
}

public OnMapStart()
{
    SetupLightning();
    SetupHaloSprite();

    SetupUltimateFeedback();
    //SetupDeniedSound();
    //SetupPsionicRage();

    SetupSound(deathWav);
    SetupSound(summonWav);
    SetupSound(rageReadyWav);
    SetupSound(rageExpireWav);
    SetupSound(g_PsiBladesSound);

    for (new i = 0; i < sizeof(archonWav); i++)
        SetupSound(archonWav[i]);
}

public OnMapEnd()
{
    ResetAllClientTimers();
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

        if (m_RageActive[client])
            EndRage(INVALID_HANDLE, GetClientUserId(client));

        if (m_MindControlAvailable)
            ResetMindControlledObjects(client, false);
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
                      .r=r, .g=g, .b=b);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields,
                     g_ShieldsPercent, float(shields_level+1),
                     Armor_IsShield|Armor_NoLimit);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(summonWav, client);
            CreateClientTimer(client, 3.0, Exclaimation, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
        if (upgrade == shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, float(new_level+1),
                         Armor_IsShield|Armor_NoLimit,
                         .upgrade=true);
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
                new rage_level = GetUpgradeLevel(client,race,rageID);
                if (rage_level > 0)
                {
                    PsionicRage(client, race, rageID, rage_level,
                                rageReadyWav, rageExpireWav);
                }
                else
                {
                    new ultimate_feedback_level = GetUpgradeLevel(client,race,ultimateFeedbackID);
                    if (ultimate_feedback_level > 0)
                    {
                        UltimateFeedback(client, raceID, ultimateFeedbackID,
                                         ultimate_feedback_level, g_FeedbackRange);
                    }
                    else
                    {
                        new maelstorm_level=GetUpgradeLevel(client,race,maelstormID);
                        if (maelstorm_level > 0)
                            Maelstorm(client,maelstorm_level);
                        else
                        {
                            new control_level=GetUpgradeLevel(client,race,controlID);
                            DoMindControl(client,control_level);
                        }
                    }
                }
            }
            case 3:
            {
                new ultimate_feedback_level = GetUpgradeLevel(client,race,ultimateFeedbackID);
                if (ultimate_feedback_level > 0)
                {
                    UltimateFeedback(client, raceID, ultimateFeedbackID,
                                     ultimate_feedback_level, g_FeedbackRange);
                }
                else
                {
                    new maelstorm_level=GetUpgradeLevel(client,race,maelstormID);
                    if (maelstorm_level > 0)
                        Maelstorm(client,maelstorm_level);
                    else
                    {
                        new control_level=GetUpgradeLevel(client,race,controlID);
                        DoMindControl(client,control_level);
                    }
                }
            }
            case 2:
            {
                new control_level=GetUpgradeLevel(client,race,controlID);
                DoMindControl(client,control_level);
            }
            default:
            {
                new maelstorm_level=GetUpgradeLevel(client,race,maelstormID);
                Maelstorm(client,maelstorm_level);
            }
        }
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        m_RageActive[client] = false;

        PrepareAndEmitSoundToAll(summonWav, client);

        // Adjust Health to offset shields
        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        new shield_amount = SetupShields(client, shields_level, g_InitialShields,
                                         g_ShieldsPercent, float(shields_level+1),
                                         Armor_IsShield|Armor_NoLimit);

        new health = GetClientHealth(client)-shield_amount;
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
                      .r=r, .g=g, .b=b);

        CreateClientTimer(client, 3.0, Exclaimation, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        damage += absorbed;

        new blades_level=GetUpgradeLevel(attacker_index,raceID,meleeID);
        if (MeleeAttack(raceID, meleeID, blades_level, event, damage,
                        victim_index, attacker_index, g_PsiBladesPercent,
                        g_PsiBladesSound, "sc_blades"))
        {
            returnCode = Plugin_Handled;
        }

        if (PsionicShockwave(damage, victim_index, attacker_index))
        {
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
        if (PsionicShockwave(damage + absorbed, victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot,bool:backstab,bool:melee)
{
    if (victim_race == raceID)
    {
        if (m_RageActive[victim_index])
            EndRage(INVALID_HANDLE, GetClientUserId(victim_index));

        PrepareAndEmitSoundToAll(deathWav, victim_index);

        DissolveRagdoll(victim_index, 0.1);        
        KillClientTimer(victim_index);
    }
}

public bool:PsionicShockwave(damage, victim_index, index)
{
    if (!GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned) &&
        !GetImmunity(victim_index,Immunity_HealthTaking) &&
        !GetImmunity(victim_index, Immunity_Upgrades) &&
        !IsInvulnerable(victim_index))
    {
        new shockwave_level=GetUpgradeLevel(index,raceID,shockwaveID);
        new adj = shockwave_level*10;
        if (GetRandomInt(1,100) <= GetRandomInt(10+adj,100-adj))
        {
            if (CanInvokeUpgrade(index, raceID, shockwaveID))
            {
                new dmgamt = RoundFloat(float(damage)*g_ShockwavePercent[shockwave_level]);
                if (dmgamt > 0)
                {
                    new Float:Origin[3];
                    GetEntityAbsOrigin(victim_index, Origin);
                    Origin[2] += 5;

                    FlashScreen(victim_index,RGBA_COLOR_RED);
                    TE_SetupSparks(Origin,Origin,255,1);
                    TE_SendEffectToAll();

                    HurtPlayer(victim_index, dmgamt, index,
                               "sc_shockwave", "Psionic Shockwave",
                               .in_hurt_event=true, .type=DMG_SHOCK);
                    return true;
                }
            }
        }
    }
    return false;
}

public Maelstorm(client, level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, maelstormID, upgradeName, sizeof(upgradeName), client);

    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "Prevented", upgradeName);
    }
    else if (CanInvokeUpgrade(client, raceID, maelstormID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        new Float:range = g_MaelstormRange[level];

        new count=0;
        new Float:indexLoc[3];
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        new lightning  = Lightning();
        new haloSprite = HaloSprite();
        static const color[4] = { 0, 255, 0, 255 };

        new team=GetClientTeam(client);
        for (new index=1;index<=MaxClients;index++)
        {
            if (client != index && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_Restore))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(clientLoc,indexLoc,range) &&
                        TraceTargetIndex(client, index, clientLoc, indexLoc))
                    {
                        if (!GetImmunity(index,Immunity_Detection))
                        {
                            SetOverrideVisiblity(index, 255);
                            if (m_SidewinderAvailable)
                                SidewinderDetectClient(index, true);

                            CreateTimer(10.0,RecloakPlayer,GetClientUserId(index),TIMER_FLAG_NO_MAPCHANGE);
                        }

                        if (GameType == tf2 &&
                            !GetImmunity(index,Immunity_Uncloaking) &&
                            TF2_GetPlayerClass(index) == TFClass_Spy)
                        {
                            TF2_RemovePlayerDisguise(index);
                            TF2_RemoveCondition(client,TFCond_Cloaked);

                            new Float:cloakMeter = TF2_GetCloakMeter(index);
                            if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                TF2_SetCloakMeter(index, 0.0);

                            DisplayMessage(index,Display_Enemy_Ultimate, "%t",
                                           "HasUndisguised", client, upgradeName);
                        }

                        new Float:meter = TF2_GetEnergyDrinkMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetEnergyDrinkMeter(index, 0.0);

                        meter = TF2_GetChargeMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetChargeMeter(index, 0.0);

                        meter = TF2_GetRageMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetRageMeter(index, 0.0);

                        meter = TF2_GetHypeMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetHypeMeter(index, 0.0);

                        if (!GetImmunity(index,Immunity_MotionTaking) &&
                            !GetImmunity(index,Immunity_Restore) &&
                            !IsBurrowed(index))
                        {
                            TE_SetupBeamPoints(clientLoc,indexLoc, lightning, haloSprite,
                                              0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                            TE_SendEffectToAll();

                            DisplayMessage(index,Display_Enemy_Ultimate, "%t",
                                           "HasEnsnared", client, upgradeName);

                            FreezeEntity(index);
                            CreateTimer(20.0,UnfreezePlayer,GetClientUserId(index),TIMER_FLAG_NO_MAPCHANGE);
                            count++;
                        }
                    }
                }
            }
        }

        if (count)
        {
            DisplayMessage(client, Display_Ultimate, "%t",
                           "ToEnsnareEnemies", upgradeName,
                           count);
        }
        else
        {
            DisplayMessage(client,Display_Ultimate, "%t",
                           "WithoutEffect", upgradeName);
        }

        CreateCooldown(client, raceID, maelstormID);
    }
}

public Action:RecloakPlayer(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        SetOverrideVisiblity(client, -1);
        if (m_SidewinderAvailable)
            SidewinderDetectClient(client, false);
    }
    return Plugin_Stop;
}

DoMindControl(client,level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, controlID, upgradeName, sizeof(upgradeName), client);

    if (!m_MindControlAvailable)
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
        return;
    }
    else
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t",
                           "Prevented", upgradeName);
        }
        else if (CanInvokeUpgrade(client, raceID, controlID, false))
        {
            new builder;
            new TFExtObjectType:type;
            if (MindControl(client, g_MindControlRange[level],
                            g_MindControlChance[level],
                            builder, type, true))
            {
                if (IsValidClient(builder))
                {
                    DisplayMessage(builder, Display_Enemy_Ultimate,
                                   "%t", "HasControlled", client,
                                   TF2_ObjectNames[type]);

                    DisplayMessage(client, Display_Ultimate, "%t", 
                                   "YouHaveControlled", builder,
                                   TF2_ObjectNames[type]);
                }

                ChargeForUpgrade(client, raceID, controlID);
                CreateCooldown(client, raceID, controlID);
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

