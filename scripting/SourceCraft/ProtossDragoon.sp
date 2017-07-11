 /**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossDragoon.sp
 * Description: The Protoss Dragoon race for SourceCraft.
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
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/MissileAttack"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/dissolve"
#include "sc/shields"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/SendEffects"

new const String:spawnWav[]               = "sc/pdrrdy00.wav";
new const String:deathWav[]               = "sc/pdrdth00.wav";

new const String:g_SingularityFireWav[]   = "sc/DragBull.wav";
new const String:g_SingularityReadyWav[]  = "sc/pdryes01.wav";
new const String:g_SingularityExpireWav[] = "sc/pdrwht05.wav";

new const String:g_MissileAttackSound[]   = "sc/pdrfir00.wav";

new raceID, immunityID, speedID, shieldsID, missileID, singularityID,  reaverID;

new g_MissileAttackChance[]               = { 5, 10, 15, 25, 35 };
new Float:g_MissileAttackPercent[]        = { 0.15, 0.30, 0.40, 0.50, 0.70 };

new Float:g_SpeedLevels[]                 = { 0.80, 0.90, 0.95, 1.00, 1.05 };

new g_SingularityChance[]                 = { 50, 60, 80, 90, 100 };

new Float:g_InitialShields[]              = { 0.05, 0.10, 0.25, 0.50, 0.75 };

new Float:g_ShieldsPercent[][2]           = { {0.05, 0.10},
                                              {0.10, 0.20},
                                              {0.15, 0.30},
                                              {0.20, 0.40},
                                              {0.25, 0.50} };

new g_reaverRace = -1;

new bool:m_SingularityActive[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Dragoon",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Dragoon race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.dragoon.phrases.txt");

    if (GetGameType() == cstrike)
    {
        if (!HookEvent("round_start",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the round_start event.");
    }
    else if (GameType == dod)
    {
        if (!HookEvent("dod_round_start",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the dod_round_start event.");

        if (!HookEventEx("dod_round_active",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the dod_round_active event.");

        if (!HookEvent("dod_round_win",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the dod_round_start event.");
    }
    else if (GameType == tf2)
    {
        if (!HookEvent("teamplay_round_start",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_start event.");

        if (!HookEventEx("teamplay_round_active",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_active event.");

        if(!HookEventEx("teamplay_round_win",RoundEndEvent, EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_win event.");

        if(!HookEventEx("teamplay_round_stalemate",RoundEndEvent, EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_stalemate event.");

        if (!HookEventEx("arena_round_start",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the arena_round_start event.");

        if (!HookEventEx("arena_win_panel",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the arena_win_panel event.");

        if (!HookEvent("teamplay_suddendeath_begin",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_suddendeath_begin event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("dragoon", -1, -1, 21, .energy_rate=2.0,
                             .faction=Protoss, .type=Cybernetic,
                             .parent="zealot");

    shieldsID   = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);
    speedID     = AddUpgrade(raceID, "speed", .cost_crystals=0);
    missileID   = AddUpgrade(raceID, "ground_weapons", .energy=2.0, .cost_crystals=20);
    immunityID  = AddUpgrade(raceID, "immunity", .cost_crystals=0);

    // Ultimate 1
    singularityID = AddUpgrade(raceID, "singularity", 1, .energy=60.0,
                               .cooldown=2.0, .cost_crystals=30);

    // Ultimate 2
    reaverID = AddUpgrade(raceID, "reaver", 2, 4, 1, .energy=80.0,
                          .accumulated=true, .cooldown=10.0,
                          .cost_crystals=60);

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

    GetConfigArray("chance", g_SingularityChance, sizeof(g_SingularityChance),
                   g_SingularityChance, raceID, singularityID);
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
    SetupSound(g_SingularityFireWav);
    SetupSound(g_SingularityReadyWav);
    SetupSound(g_SingularityExpireWav);
    SetupMissileAttack(g_MissileAttackSound);
}

public OnPlayerAuthed(client)
{
    m_SingularityActive[client] = false;
}

public OnClientDisconnect(client)
{
    m_SingularityActive[client] = false;
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        SetSpeed(client,-1.0, true);

        // Turn off Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, false);

        if (m_SingularityActive[client])
            EndSingularity(INVALID_HANDLE, GetClientUserId(client));
    }
    else
    {
        if (g_reaverRace < 0)
            g_reaverRace = FindRace("reaver");

        if (oldrace == g_reaverRace &&
            GetCooldownExpireTime(client, raceID, reaverID) <= 0.0)
        {
            CreateCooldown(client, raceID, reaverID,
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
        m_SingularityActive[client] = false;

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav, client);

            // Turn on Immunities
            new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
            DoImmunity(client, immunity_level, true);

            new speed_level = GetUpgradeLevel(client,raceID,speedID);
            SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

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
                new reaver_level = GetUpgradeLevel(client,race,reaverID);
                if (reaver_level > 0)
                    SummonReaver(client);
                else
                {
                    new singularity_level=GetUpgradeLevel(client,race,singularityID);
                    if (singularity_level)
                        Singularity(client, singularity_level);
                }
            }
            default:
            {
                new singularity_level=GetUpgradeLevel(client,race,singularityID);
                if (singularity_level)
                    Singularity(client, singularity_level);
            }
        }
    }
}

public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        m_SingularityActive[index] = false;
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        m_SingularityActive[client] = false;

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
        if (m_SingularityActive[attacker_index])
        {
            decl Float:singularityPercent[sizeof(g_MissileAttackPercent)];
            new singularity_level= GetUpgradeLevel(attacker_index,raceID,singularityID);
            new Float:increase = (float(singularity_level) * 0.25) + 1.0;
            for (new i = 0; i < sizeof(g_MissileAttackPercent); i++)
            {
                singularityPercent[i] = g_MissileAttackPercent[i] * increase;
            }

            if (MissileAttack(raceID, missileID, weapons_level, event, damage + absorbed, victim_index,
                              attacker_index, attacker_index, false, sizeof(g_SingularityChance),
                              singularityPercent, g_SingularityChance, g_SingularityFireWav,
                              "sc_singularity"))
            {
                return Plugin_Handled;
            }
        }
        else if (weapons_level > 0)
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
        if (m_SingularityActive[victim_index])
            EndSingularity(INVALID_HANDLE, GetClientUserId(victim_index));

        PrepareAndEmitSoundToAll(deathWav,victim_index);
        DissolveRagdoll(victim_index, 0.1);
    }
    else
    {
        if (g_reaverRace < 0)
            g_reaverRace = FindRace("reaver");

        if (victim_race == g_reaverRace &&
            GetCooldownExpireTime(victim_index, raceID, reaverID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, reaverID,
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

Singularity(client, level)
{
    if (level > 0)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, singularityID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (CanInvokeUpgrade(client, raceID, singularityID))
        {
            m_SingularityActive[client] = true;
            CreateTimer(5.0 * float(level), EndSingularity, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);

            HudMessage(client, "%t", "SingularityHud");
            PrintHintText(client, "%t", "SingularityActive");
            PrepareAndEmitSoundToAll(g_SingularityReadyWav,client);
        }
    }
}

public Action:EndSingularity(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClient(client) && m_SingularityActive[client])
    {
        m_SingularityActive[client]=false;

        if (IsPlayerAlive(client))
        {
            PrepareAndEmitSoundToAll(g_SingularityExpireWav,client);
            PrintHintText(client, "%t", "SingularityEnded");
        }

        ClearHud(client, "%t", "SingularityHud");
        CreateCooldown(client, raceID, singularityID);
    }
}

SummonReaver(client)
{
    if (g_reaverRace < 0)
        g_reaverRace = FindRace("reaver");

    if (g_reaverRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, reaverID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Protoss Reaver race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, reaverID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningReaver");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, reaverID))
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

        ChangeRace(client, g_reaverRace, true, false, true);
    }
}

