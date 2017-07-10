/**
 * vim: set ai et ts=4 sw=4 :
 * File: UndeadScourge.sp
 * Description: The Undead Scourge race for SourceCraft.
 * Author(s): Anthony Iacono 
 * Rewritten by: Naris (Murray Wilson)
 */
 
#pragma semicolon 1

// Pump up the memory!
#pragma dynamic 32767

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <hgrsource>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/PlagueInfect"
#include "sc/HealthParticle"
#include "sc/Levitation"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"
#include "effect/Shake"

new Float:g_SpeedLevels[]           = { -1.0, 1.05,  1.10,   1.16, 1.23  };
new Float:g_LevitationLevels[]      = { 1.0,  0.92, 0.733, 0.5466, 0.36  };
new Float:g_VampiricAuraPercent[]   = { 0.0,  0.12,  0.18,   0.24, 0.30  };
new Float:g_BombRadius[]            = { 0.0, 200.0, 250.0,  300.0, 350.0 };
new g_SucideBombDamage[]            = {   0,   300,   350,    400, 500   };

new raceID, vampiricID, unholyID, levitationID, suicideID, necroID;

new g_necroRace = -1;

// Suicide bomber check
new bool:m_Suicided[MAXPLAYERS+1];
new Float:m_VampiricAuraTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Undead Scourge",
    author = "-=|JFH|=-Naris with credits to PimpinJuice",
    description = "The Undead Scourge race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://www.jigglysfunhouse.net/"
};

// War3Source Functions
public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.undead.phrases.txt");

    if (GetGameType() == tf2)
    {
        if (!HookEventEx("teamplay_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_win event.");

        if (!HookEventEx("teamplay_round_stalemate",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_stalemate event.");
    }
    else if (GameType == dod)
    {
        if (!HookEventEx("dod_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the dod_round_win event.");
    }
    else if (GameTypeIsCS())
    {
        if (!HookEventEx("round_end",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the round_end event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID       = CreateRace("undead", 0, 0, 17, .faction=UndeadScourge, .type=Undead);

    vampiricID   = AddUpgrade(raceID, "vampiric_aura", .energy=2.0);
    unholyID     = AddUpgrade(raceID, "unholy_aura");
    levitationID = AddUpgrade(raceID, "levitation");

    // Ultimate 1
    suicideID    = AddUpgrade(raceID, "suicide_bomb", 1, .energy=30.0);

    // Ultimate 2
    necroID      = AddUpgrade(raceID, "necromancer", 2, 12,1,
                              .energy=300.0, .cooldown=30.0,
                              .accumulated=true);

    // Get Configuration Data
    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, unholyID);

    GetConfigFloatArray("gravity", g_LevitationLevels, sizeof(g_LevitationLevels),
                        g_LevitationLevels, raceID, levitationID);

    GetConfigFloatArray("damage_percent", g_VampiricAuraPercent, sizeof(g_VampiricAuraPercent),
                        g_VampiricAuraPercent, raceID, vampiricID);

    GetConfigFloatArray("range", g_BombRadius, sizeof(g_BombRadius),
                        g_BombRadius, raceID, suicideID);

    GetConfigArray("damage", g_SucideBombDamage, sizeof(g_SucideBombDamage),
                   g_SucideBombDamage, raceID, suicideID);
}

public OnMapStart()
{
    g_necroRace = -1;

    SetupSmokeSprite();
    SetupBeamSprite();
    SetupHaloSprite();
    SetupLevitation();
    SetupBlueGlow();
    SetupRedGlow();
    SetupSpeed();

    SetupDeniedSound();
}

public OnPlayerAuthed(client)
{
    m_VampiricAuraTime[client] = 0.0;
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race == raceID && IsValidClientAlive(client))
    {
        if (arg >= 2)
        {
            new necro_level = GetUpgradeLevel(client,race,necroID);
            if (necro_level > 0)
                SummonNecromancer(client);
        }
        else
        {
            new level = GetUpgradeLevel(client, race, suicideID);
            if (level > 0)
            {
                if (GetRestriction(client,Restriction_NoUltimates) ||
                    GetRestriction(client,Restriction_Stunned))
                {
                    decl String:upgradeName[NAME_STRING_LENGTH];
                    GetUpgradeName(raceID, suicideID, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                    PrepareAndEmitSoundToClient(client,deniedWav);
                }
                else if (GameType == tf2 && TF2_IsPlayerDisguised(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                }
                else if (CanInvokeUpgrade(client, race, suicideID))
                {
                    ExplodePlayer(client, client, GetClientTeam(client),
                                  g_BombRadius[level], g_SucideBombDamage[level], 0,
                                  RingExplosion|ParticleExplosion|UltimateExplosion,
                                  level+5, "sc_suicide_bomb");
                }
            }
            else
            {
                new necro_level = GetUpgradeLevel(client,race,necroID);
                if (necro_level > 0)
                    SummonNecromancer(client);
            }
        }
    }
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==unholyID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==levitationID)
            SetLevitation(client, new_level, true, g_LevitationLevels);
    }
}

public OnItemPurchase(client,item)
{
    if (GetRace(client) == raceID && IsValidClientAlive(client))
    {
        if (g_bootsItem < 0)
            g_bootsItem = FindShopItem("boots");

        if (g_sockItem < 0)
            g_sockItem = FindShopItem("sock");

        if (item == g_bootsItem)
        {
            new unholy_level = GetUpgradeLevel(client,raceID,unholyID);
            if (unholy_level > 0)
                SetSpeedBoost(client, unholy_level, true, g_SpeedLevels);
        }
        else if (item == g_sockItem)
        {
            new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
            SetLevitation(client, levitation_level, true, g_LevitationLevels);
        }
    }
}

public Action:OnDropPlayer(client, target)
{
    if (IsValidClient(target) && GetRace(target) == raceID)
    {
        new levitation_level = GetUpgradeLevel(target,raceID,levitationID);
        SetLevitation(target, levitation_level, true, g_LevitationLevels);
    }
    return Plugin_Continue;
}
public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        SetSpeed(client,-1.0);
        SetGravity(client,-1.0);
        ApplyPlayerSettings(client);
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
        SetLevitation(client, levitation_level, false, g_LevitationLevels);

        new unholy_level = GetUpgradeLevel(client,raceID,unholyID);
        SetSpeedBoost(client, unholy_level, false, g_SpeedLevels);

        if (unholy_level > 0 || levitation_level > 0)
            ApplyPlayerSettings(client);

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race==raceID)
    {
        m_VampiricAuraTime[client] = 0.0;
        m_Suicided[client]=false;

        new levitation_level = GetUpgradeLevel(client,raceID,levitationID);
        SetLevitation(client, levitation_level, false, g_LevitationLevels);

        new unholy_level = GetUpgradeLevel(client,raceID,unholyID);
        SetSpeedBoost(client, unholy_level, false, g_SpeedLevels);

        if (unholy_level > 0 || levitation_level > 0)
            ApplyPlayerSettings(client);
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_race == raceID)
    {
        if (!m_Suicided[victim_index] &&
            !IsChangingClass(victim_index))
        {
            new level = GetUpgradeLevel(victim_index,raceID,suicideID);
            if (level > 0)
            {
                ExplodePlayer(victim_index, victim_index, GetClientTeam(victim_index),
                              g_BombRadius[level], g_SucideBombDamage[level], 0,
                              RingExplosion|ParticleExplosion|UpgradeExplosion|OnDeathExplosion,
                              level+5, "sc_suicide_bomb");
            }
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
        if (VampiricAura(damage + absorbed, attacker_index, victim_index))
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
        if (VampiricAura(damage + absorbed, assister_index, victim_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

bool:VampiricAura(damage, index, victim_index)
{
    new level = GetUpgradeLevel(index, raceID, vampiricID);
    if (level > 0 && GetRandomInt(1,10) <= 6 && IsValidClientAlive(index) &&
        !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned))
    {
        new bool:victimIsNPC    = (victim_index > MaxClients);
        new bool:victimIsPlayer = !victimIsNPC && IsValidClientAlive(victim_index) &&
                                  !GetImmunity(victim_index,Immunity_HealthTaking) &&
                                  !GetImmunity(victim_index,Immunity_Upgrades) &&
                                  !IsInvulnerable(victim_index);

        if (victimIsPlayer || victimIsNPC)
        {
            new Float:lastTime = m_VampiricAuraTime[index];
            new Float:interval = GetGameTime() - lastTime;
            if ((lastTime == 0.0 || interval > 0.25) &&
                CanInvokeUpgrade(index, raceID, vampiricID, .notify=false))
            {
                new Float:start[3];
                GetClientAbsOrigin(index, start);
                start[2] += 1620;

                new Float:end[3];
                GetClientAbsOrigin(index, end);
                end[2] += 20;

                static const color[4] = { 255, 10, 25, 255 };
                TE_SetupBeamPoints(start, end, BeamSprite(), HaloSprite(),
                                   0, 1, 3.0, 20.0,10.0,5,50.0,color,255);
                TE_SendEffectToAll();
                FlashScreen(index,RGBA_COLOR_GREEN);
                FlashScreen(victim_index,RGBA_COLOR_RED);

                m_VampiricAuraTime[index] = GetGameTime();

                new leechhealth=RoundFloat(float(damage)*g_VampiricAuraPercent[level]);
                if (leechhealth <= 0)
                    leechhealth = 1;

                new health = GetClientHealth(index) + leechhealth;
                if (health <= GetMaxHealth(index))
                {
                    ShowHealthParticle(index);
                    SetEntityHealth(index,health);

                    decl String:upgradeName[NAME_STRING_LENGTH];
                    GetUpgradeName(raceID, vampiricID, upgradeName, sizeof(upgradeName), index);

                    if (victimIsPlayer)
                    {
                        DisplayMessage(index, Display_Damage, "%t", "YouHaveLeechedFrom",
                                       leechhealth, victim_index, upgradeName);
                    }
                    else
                    {
                        DisplayMessage(index, Display_Damage, "%t", "YouHaveLeeched",
                                       leechhealth, upgradeName);
                    }
                }

                if (victimIsPlayer)
                {
                    new victim_health = GetClientHealth(victim_index);
                    if (victim_health <= leechhealth)
                        KillPlayer(victim_index, index, "sc_vampiric_aura");
                    else
                    {
                        SetEntityHealth(victim_index, victim_health-leechhealth);

                        if (GameType != tf2 || GetMode() != MvM)
                        {
                            new entities = EntitiesAvailable(200, .message="Reducing Effects");
                            if (entities > 50)
                                CreateParticle("blood_impact_red_01_chunk", 0.1, victim_index, Attach, "head");
                        }

                        decl String:upgradeName[NAME_STRING_LENGTH];
                        GetUpgradeName(raceID, vampiricID, upgradeName, sizeof(upgradeName), victim_index);
                        DisplayMessage(victim_index, Display_Injury, "%t", "HasLeeched",
                                       index, leechhealth, upgradeName);
                    }
                }
                else
                {
                    DamageEntity(victim_index, leechhealth, index, DMG_GENERIC, "sc_vampiric_aura");
                    DisplayDamage(index, victim_index, leechhealth, "sc_vampiric_aura");
                }

                return true;
            }
        }
    }
    return false;
}

public EventRoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        if (IsClientInGame(index))
        {
            SetSpeed(index,-1.0);
            SetGravity(index,-1.0);
        }
    }
}

SummonNecromancer(client)
{
    if (g_necroRace < 0)
        g_necroRace = FindRace("necromancer");

    if (g_necroRace < 0)
    {
        decl String:upgradeName[NAME_STRING_LENGTH];
        GetUpgradeName(raceID, necroID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Necromancer race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningNecromancer");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (HasCooldownExpired(client, raceID, necroID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        ChangeRace(client, g_necroRace, true, false);
    }
}
