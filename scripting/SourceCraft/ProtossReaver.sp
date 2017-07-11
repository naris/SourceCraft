 /**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossReaver.sp
 * Description: The Protoss Reaver race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <entlimit>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#include <tf2_meter>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/SpeedBoost"
#include "sc/ShopItems"
#include "sc/maxhealth"
#include "sc/dissolve"
#include "sc/shields"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/Explosion"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

#define MAXENTITIES 2048
#define MASK_GRABBERSOLID   (MASK_PLAYERSOLID|MASK_NPCSOLID|MASK_SHOT)

new const String:scarabModel[]       = "models/items/grenadeAmmo.mdl";
new const String:dodScarabModel[]    = "models/weapons/w_tnt.mdl";
new const String:tf2ScarabModels[][] = { "models/props_halloween/pumpkin_explode.mdl",
                                         "models/props_halloween/pumpkin_01.mdl" };

new const String:spawnWav[]          = "sc/ptrrdy00.wav";
new const String:deathWav[]          = "sc/ptrdth00.wav";
new const String:explodeWav[]        = "sc/PSaHit00.wav";

new const String:g_ScarabFireWav[][] = { "sc/ptrfir00.mp3", "sc/ptrfir01.mp3" };
new const String:g_ScarabReadyWav[]  = "sc/ptryes01.wav";
new const String:g_ActivateSiegeWav[] = "sc/ptrwht00.wav";
new const String:g_DeactivateSiegeWav[] = "sc/ptrpss00.wav";

new raceID, immunityID, speedID, shieldsID;
new scarabAttackID, capacityID, velocityID;
new scarabID, argusScarabID, siegeID, detonateID;

new Float:g_SpeedLevels[]            = { 0.80, 0.90, 0.95, 1.00, 1.05 };

new g_ScrabAttackChance[]            = { 0, 20, 40, 60, 90 };
new Float:g_ScrabAttackPercent[]     = { 0.0, 0.15, 0.30, 0.40, 0.60 };

new Float:g_InitialShields[]         = { 0.05, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ShieldsPercent[][2]      = { {0.05, 0.10},
                                         {0.10, 0.20},
                                         {0.15, 0.30},
                                         {0.20, 0.40},
                                         {0.25, 0.50} };

new Float:cfgStopSpeed               = 10.0;
new Float:cfgThrowTime               = 2.0;
new cfgScarabLimit                   = 50;

new Float:m_ScarabAttackTime[MAXPLAYERS+1];
new bool:m_SiegeActive[MAXPLAYERS+1];
new m_ScarabCount[MAXPLAYERS+1];

new Float:gThrow[MAXPLAYERS+1];         // throw charge state 
new Handle:g_ScarabTimers[MAXPLAYERS+1];
new Handle:gTrackTimers[MAXENTITIES+1]; // entity track timers

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Reaver",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Reaver race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.reaver.phrases.txt");

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
    raceID          = CreateRace("reaver", -1, -1, 37, .energy_rate=2.0,
                                 .faction=Protoss, .type=Robotic,
                                 .parent="dragoon");

    shieldsID       = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);
    speedID         = AddUpgrade(raceID, "speed", .cost_crystals=0);
    scarabAttackID  = AddUpgrade(raceID, "scarab_attack", .energy=2.0, .cost_crystals=20);
    immunityID      = AddUpgrade(raceID, "immunity", .cost_crystals=0);
    capacityID      = AddUpgrade(raceID, "capacity", 0, 4, .cost_crystals=20);
    velocityID      = AddUpgrade(raceID, "velocity", 0, 4, .cost_crystals=20);

    // Ultimate 1
    scarabID        = AddUpgrade(raceID, "scarab", 1, 0, .energy=2.0,
                                 .cooldown=0.0, .cost_crystals=40);

    // Ultimate 2
    argusScarabID   = AddUpgrade(raceID, "argus_scarab", 2, .energy=4.0,
                                 .cooldown=0.0, .cost_crystals=50);

    // Ultimate 3
    siegeID         = AddUpgrade(raceID, "scarab_siege", 3, 16, .energy=300.0,
                                 .vespene=20, .cooldown=120.0, .accumulated=true,
                                 .cost_crystals=50);

    // Ultimate 4
    detonateID      = AddUpgrade(raceID, "detonate", 4, 10, 1, .cost_crystals=30);

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

    cfgStopSpeed = GetConfigFloat("stop_speed", cfgStopSpeed, raceID, scarabID);
    cfgThrowTime = GetConfigFloat("throw_charge", cfgThrowTime, raceID, scarabID);
    cfgScarabLimit = GetConfigNum("limit", cfgScarabLimit, raceID, scarabID);

    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, speedID);

    GetConfigArray("chance", g_ScrabAttackChance, sizeof(g_ScrabAttackChance),
                   g_ScrabAttackChance, raceID, scarabAttackID);

    GetConfigFloatArray("damage_percent", g_ScrabAttackPercent, sizeof(g_ScrabAttackPercent),
                        g_ScrabAttackPercent, raceID, scarabAttackID);

}

public OnMapStart()
{
    SetupHaloSprite();
    SetupExplosion();
    SetupLightning();
    SetupSpeed();

    SetupErrorSound();
    SetupDeniedSound();

    SetupSound(deathWav);
    SetupSound(spawnWav);
    SetupSound(explodeWav);
    SetupSound(g_ScarabReadyWav);
    SetupSound(g_ActivateSiegeWav);
    SetupSound(g_DeactivateSiegeWav);

    for (new i = 0; i < sizeof(g_ScarabFireWav); i++)
        SetupSound(g_ScarabFireWav[i]);

    if (GetGameType() == tf2)
    {
        for (new i = 0; i < sizeof(tf2ScarabModels); i++)
            PrecacheModel(tf2ScarabModels[i], true);
    }
    else if (GameType == dod)
        PrecacheModel(dodScarabModel, true);
    else
        PrecacheModel(scarabModel, true);
}

public OnPlayerAuthed(client)
{
    gThrow[client]=0.0;
    m_ScarabAttackTime[client] = 0.0;
    m_SiegeActive[client] = false;
}

public OnClientDisconnect(client)
{
    Detonate(client);

    new Handle:timer=g_ScarabTimers[client];
    if (timer != INVALID_HANDLE)
    {
        g_ScarabTimers[client] = INVALID_HANDLE;
        KillTimer(timer);
    }
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        new Handle:timer=g_ScarabTimers[client];
        if (timer != INVALID_HANDLE)
        {
            g_ScarabTimers[client] = INVALID_HANDLE;
            KillTimer(timer);
        }

        ResetShields(client);
        SetSpeed(client,-1.0, true);

        if (m_SiegeActive[client])
            DeactivateSiege(INVALID_HANDLE, GetClientUserId(client));

        Detonate(client);

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
        gThrow[client]=0.0;
        m_ScarabAttackTime[client] = 0.0;
        m_SiegeActive[client] = false;

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav, client);

            // Turn on Immunities
            new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
            DoImmunity(client, immunity_level, true);

            new speed_level = GetUpgradeLevel(client,raceID,speedID);
            SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

            new scarab_level = GetUpgradeLevel(client,raceID,scarabID);
            new argus_level = GetUpgradeLevel(client,raceID,argusScarabID);
            if (scarab_level > 0 || argus_level > 0)
            {
                m_ScarabCount[client] = (scarab_level > argus_level) ? scarab_level : argus_level;
                HudMessage(client, "Scarabs: %d", m_ScarabCount[client]);

                if (g_ScarabTimers[client] == INVALID_HANDLE)
                {
                    g_ScarabTimers[client] = CreateTimer(5.0, BuildScarab, GetClientUserId(client),
                                                         TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }

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
        else if (upgrade==scarabID)
        {
            new argus_level = GetUpgradeLevel(client,raceID,argusScarabID);
            new scarab_count = (new_level > argus_level) ? new_level : argus_level;
            if (m_ScarabCount[client] < scarab_count)
            {
                m_ScarabCount[client] = scarab_count;
                if (m_SiegeActive[client])
                    HudMessage(client, "%t", "SiegeHud", m_ScarabCount[client]);
                else
                    HudMessage(client, "%t", "ScarabHud", m_ScarabCount[client]);
            }

            if (g_ScarabTimers[client] == INVALID_HANDLE)
            {
                g_ScarabTimers[client] = CreateTimer(5.0, BuildScarab, GetClientUserId(client),
                                                     TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }
        else if (upgrade==argusScarabID)
        {
            new scarab_level = GetUpgradeLevel(client,raceID,scarabID);
            new scarab_count = (scarab_level > new_level) ? scarab_level : new_level;
            if (m_ScarabCount[client] < scarab_count)
            {
                m_ScarabCount[client] = scarab_count;
                if (m_SiegeActive[client])
                    HudMessage(client, "%t", "SiegeHud", m_ScarabCount[client]);
                else
                    HudMessage(client, "%t", "ScarabHud", m_ScarabCount[client]);
            }

            if (g_ScarabTimers[client] == INVALID_HANDLE)
            {
                g_ScarabTimers[client] = CreateTimer(5.0, BuildScarab, GetClientUserId(client),
                                                     TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }
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
    if (race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4:
            {
                if (GetUpgradeLevel(client,race,detonateID))
                {
                    if (pressed)
                        Detonate(client);
                }
                else
                {
                    new siege_level=GetUpgradeLevel(client,race,siegeID);
                    if (siege_level)
                    {
                        if (pressed)
                            Siege(client, siege_level);
                    }
                    else
                    {
                        new argus_level=GetUpgradeLevel(client,race,argusScarabID);
                        if (argus_level)
                            LaunchScarab(client, argus_level, 1, pressed);
                        else
                        {
                            new scarab_level=GetUpgradeLevel(client,race,scarabID);
                            if (scarab_level)
                                LaunchScarab(client, scarab_level, 0, pressed);
                        }
                    }
                }
            }
            case 3:
            {
                new siege_level=GetUpgradeLevel(client,race,siegeID);
                if (siege_level)
                {
                    if (pressed)
                        Siege(client, siege_level);
                }
                else
                {
                    new argus_level=GetUpgradeLevel(client,race,argusScarabID);
                    if (argus_level)
                        LaunchScarab(client, argus_level, 1, pressed);
                    else
                    {
                        new scarab_level=GetUpgradeLevel(client,race,scarabID);
                        if (scarab_level)
                            LaunchScarab(client, scarab_level, 0, pressed);
                    }
                }
            }
            case 2:
            {
                new argus_level=GetUpgradeLevel(client,race,argusScarabID);
                if (argus_level)
                    LaunchScarab(client, argus_level, 1, pressed);
                else
                {
                    new scarab_level=GetUpgradeLevel(client,race,scarabID);
                    if (scarab_level)
                        LaunchScarab(client, scarab_level, 0, pressed);
                }
            }
            default:
            {
                new scarab_level=GetUpgradeLevel(client,race,scarabID);
                if (scarab_level)
                    LaunchScarab(client, scarab_level, 0, pressed);
            }
        }
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        gThrow[client]=0.0;
        m_ScarabAttackTime[client] = 0.0;
        m_SiegeActive[client] = false;

        PrepareAndEmitSoundToAll(spawnWav, client);

        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new speed_level = GetUpgradeLevel(client,raceID,speedID);
        SetSpeedBoost(client, speed_level, true, g_SpeedLevels);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        new scarab_level = GetUpgradeLevel(client,raceID,scarabID);
        new argus_level = GetUpgradeLevel(client,raceID,argusScarabID);
        if (scarab_level > 0 || argus_level > 0)
        {
            m_ScarabCount[client] = (scarab_level > argus_level) ? scarab_level : argus_level;
            HudMessage(client, "Scarabs: %d", m_ScarabCount[client]);

            if (g_ScarabTimers[client] == INVALID_HANDLE)
            {
                g_ScarabTimers[client] = CreateTimer(5.0, BuildScarab, GetClientUserId(client),
                                                     TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
        if (attacker_race == raceID)
        {
            if (ScarabAttack(damage + absorbed, victim_index, attacker_index))
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
        if (ScarabAttack(damage + absorbed, victim_index, assister_index))
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
        if (m_SiegeActive[victim_index])
            DeactivateSiege(INVALID_HANDLE, GetClientUserId(victim_index));

        new Handle:timer=g_ScarabTimers[victim_index];
        if (timer != INVALID_HANDLE)
        {
            g_ScarabTimers[victim_index] = INVALID_HANDLE;
            KillTimer(timer);
        }

        PrepareAndEmitSoundToAll(deathWav,victim_index);
        DissolveRagdoll(victim_index, 0.1);
    }
}

public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        if (GetRace(index) == raceID)
        {
            Detonate(index);
            gThrow[index]=0.0;
            m_SiegeActive[index] = false;
            m_ScarabAttackTime[index] = 0.0;
        }
    }
}

bool:ScarabAttack(damage, victim_index, index)
{
    new rs_level = GetUpgradeLevel(index, raceID, scarabAttackID);
    if (rs_level > 0)
    {
        if (!GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_Explosion) &&
            !GetImmunity(victim_index,Immunity_HealthTaking) &&
            !GetImmunity(victim_index,Immunity_Upgrades) &&
            !IsInvulnerable(victim_index))
        {
            new Float:lastTime = m_ScarabAttackTime[index];
            new Float:interval = GetGameTime() - lastTime;
            if (lastTime == 0.0 || interval > 0.25)
            {
                if (GetRandomInt(1,100) <= g_ScrabAttackChance[rs_level])
                {
                    new health_take = RoundToFloor(float(damage)*g_ScrabAttackPercent[rs_level]);
                    if (health_take > 0)
                    {
                        if (CanInvokeUpgrade(index, raceID, scarabAttackID, .notify=false))
                        {
                            if (interval == 0.0 || interval >= 2.0)
                            {
                                new Float:Origin[3];
                                GetEntityAbsOrigin(victim_index, Origin);
                                Origin[2] += 5;

                                TE_SetupExplosion(Origin, Explosion(), 5.0, 1,0, 5, 10);
                                TE_SendEffectToAll();
                            }

                            PrepareAndEmitSoundToAll(explodeWav,victim_index);
                            FlashScreen(victim_index,RGBA_COLOR_RED);

                            m_ScarabAttackTime[index] = GetGameTime();
                            HurtPlayer(victim_index, health_take, index,
                                       "sc_scarab_attack", .type=DMG_BLAST,
                                       .in_hurt_event=true);
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
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

public Action:BuildScarab(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client) && GetRace(client) == raceID &&
        !GetRestriction(client,Restriction_NoUltimates) &&
        !GetRestriction(client,Restriction_Stunned))
    {
        new capactity_level = GetUpgradeLevel(client,raceID,capacityID);
        if (m_ScarabCount[client] < (capactity_level*2)+5)
        {
            PrepareAndEmitSoundToAll(g_ScarabReadyWav,client);

            m_ScarabCount[client]++;
            if (m_SiegeActive[client])
                HudMessage(client, "%t", "SiegeHud", m_ScarabCount[client]);
            else
                HudMessage(client, "%t", "ScarabHud", m_ScarabCount[client]);

        }
    }
    return Plugin_Continue;
}

LaunchScarab(client, level, model, pressed)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromLaunchingScarabs");
        PrepareAndEmitSoundToClient(client,deniedWav);
        gThrow[client] = 0.0;
    }
    else if (IsEntLimitReached(cfgScarabLimit, 16, client, "Unable to spawn anymore scarabs"))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "NoScarabEntitiesAvailable");
        PrepareAndEmitSoundToClient(client,deniedWav);
        gThrow[client] = 0.0;
    }
    else if (m_ScarabCount[client] < 1)
    {
        DisplayMessage(client, Display_Ultimate, "%t", "NoScarabsAvailable");
        PrepareAndEmitSoundToClient(client,errorWav);
        gThrow[client] = 0.0;
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, scarabID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,errorWav);
        gThrow[client] = 0.0;
    }
    else if (GameType == tf2 && TF2_IsPlayerDisguised(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        gThrow[client] = 0.0;
    }
    else if (pressed)
    {
        // start throw timer
        gThrow[client] = GetEngineTime();
        CreateTimer(0.1, UpdateBar, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    else if (CanInvokeUpgrade(client, raceID, scarabID))
    {
        // throw scarab
        new bool:siege = m_SiegeActive[client];
        new Float:throwspeed = float(GetUpgradeLevel(client,raceID,velocityID)+1)*1000.0;
        if (siege)
            throwspeed *= 5.0;

        new Float:time = GetEngineTime() - gThrow[client];
        if (time < cfgThrowTime)
            throwspeed *= time / cfgThrowTime;

        gThrow[client] = 0.0;

        // get position and angles
        new Float:startpt[3];
        GetClientEyePosition(client, startpt);
        new Float:angle[3];
        new Float:speed[3];
        new Float:playerspeed[3];
        GetClientEyeAngles(client, angle);
        GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(speed, throwspeed);

        GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
        AddVectors(speed, playerspeed, speed);

        m_ScarabCount[client]--;

        if (m_SiegeActive[client])
            HudMessage(client, "%t", "SiegeHud", m_ScarabCount[client]);
        else
            HudMessage(client, "%t", "ScarabHud", m_ScarabCount[client]);

        new num = GetRandomInt(0,sizeof(g_ScarabFireWav)-1);
        PrepareAndEmitSoundToAll(g_ScarabFireWav[num], client);

        new ent = CreateEntityByName("prop_physics_override");
        if (ent > 0 && IsValidEntity(ent))
        {
            SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
            SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
            SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
            //SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
            //SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);

            if (GetGameType() == tf2)
                SetEntityModel(ent, tf2ScarabModels[model]);
            else if (GameType == dod)
                SetEntityModel(ent, dodScarabModel);
            else
                SetEntityModel(ent, scarabModel);

            DispatchSpawn(ent);

            startpt[2] += 50.0;
            TeleportEntity(ent, startpt, angle, speed);

            new ref = EntIndexToEntRef(ent);

            new Handle:pack;
            gTrackTimers[ent] = CreateDataTimer(0.2,TrackObject,pack,TIMER_REPEAT);
            if (gTrackTimers[ent] != INVALID_HANDLE)
            {
                new Float:vecPos[3];
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
                WritePackCell(pack, ref); // EntIndexToEntRef(ent));
                WritePackFloat(pack, vecPos[0]);
                WritePackFloat(pack, vecPos[1]);
                WritePackFloat(pack, vecPos[2]);
                WritePackFloat(pack, throwspeed);
                WritePackCell(pack, 0);
                WritePackFloat(pack, siege ? float(level) * 25.0 : float(level) * 5.0);
                WritePackCell(pack, client);
            }

            CreateCooldown(client, raceID, scarabID);
        }
        else
            LogError("Unable to create prop_physics!");
    }
}

public Action:UpdateBar(Handle:timer,any:client)
{
    if (gThrow[client] > 0.0 && IsValidClientAlive(client))
    {
        if (ShowBar(client, GetEngineTime() - gThrow[client], cfgThrowTime))
        {
            return Plugin_Continue;
        }
    }
    return Plugin_Stop;
}

// show a progres bar via hint text
ShowBar(client, Float:curTime, Float:totTime)
{
    new String:gauge[30] = "[=====================]";
    new Float:percent = curTime/totTime;
    new bool:partial = (percent < 1.0);
    if (partial)
    {
        new pos = RoundFloat(percent * 20.0) + 1;
        if (pos < 21)
        {
            gauge{pos} = ']';
            gauge{pos+1} = 0;
        }
    }
    PrintHintText(client, gauge);
    return partial;
}

public Action:TrackObject(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    new ref = ReadPackCell(pack);
    new ent = EntRefToEntIndex(ref);

    // check if the object is still the same type we picked up
    if (ent > 0 && IsValidEntity(ent) && IsValidEdict(ent))
    {
        decl Float:lastPos[3];
        lastPos[0] = ReadPackFloat(pack);
        lastPos[1] = ReadPackFloat(pack);
        lastPos[2] = ReadPackFloat(pack);

        new Float:lastSpeed = ReadPackFloat(pack);
        new stopCount = ReadPackCell(pack);
        new Float:fuseTime = ReadPackFloat(pack);
        new client = ReadPackCell(pack);

        decl Float:vecPos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);

        decl Float:vecVel[3];
        SubtractVectors(lastPos, vecPos, vecVel);

        new Float:vecGround[3];
        vecGround[0] = vecPos[0];
        vecGround[1] = vecPos[1];
        vecGround[2] = vecPos[2];

        new Float:stopSpeed = cfgStopSpeed;
        new Float:speed = vecVel[0] + vecVel[1] + vecVel[2];
        if (speed < 0)
            speed *= -1.0;

        new bool:bStop = (speed < stopSpeed);
        new Float:height = 0.0;
        decl Float:vecBelow[3];
        decl Float:vecCheckBelow[3];

        new bool:bGround = ((GetEntityFlags(ent) & FL_ONGROUND) != 0);
        //if (!bGround) // F_ONGROUND flag lies!!!
        {
            //Check below the object for the ground
            vecCheckBelow[0] = vecPos[0];
            vecCheckBelow[1] = vecPos[1];
            vecCheckBelow[2] = vecPos[2] - 1000.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayDontHitSelf, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                vecGround[2] = vecBelow[2];
                height = (vecPos[2] - vecBelow[2]);
                if (bGround && height > 0.0)
                    bGround = false;

                if (bStop)
                {
                    // Don't Stop if it's more than 10 units off ground.
                    bStop = (height < 10.0);
                }
                else
                {
                    // Stop if it's within 5 units of the ground.
                    bStop = (height <= 5.0);
                }
            }
            else
                bGround = bStop = false;
        }

        if (!bStop && !bGround && lastSpeed < stopSpeed)
        {
            if (speed < stopSpeed)
            {
                stopCount++;
                if (stopCount > 10)
                    bStop = true; // it's stuck real good :(
                else if (stopCount > 2)
                {
                    if (height > 10.0)
                    {
                        // it's stuck, try to knock it loose.
                        stopSpeed *= 5.0;
                        new Float:negSpeed = stopSpeed * -1.0;
                        decl Float:vecKnock[3];
                        vecKnock[0]= GetRandomFloat(negSpeed, stopSpeed);
                        vecKnock[1]= GetRandomFloat(negSpeed, stopSpeed);
                        vecKnock[2]= GetRandomFloat(negSpeed, stopSpeed);
                        TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vecKnock);
                    }
                    else
                        bStop = true;
                }
            }
            else
                stopCount = 0;
        }

        if (bStop || bGround || height <= 0.0)
        {
            new Float:vecAngles[3];
            GetEntPropVector(ent, Prop_Send, "m_angRotation", vecAngles);
            if (vecAngles[0] != 0.0 || vecAngles[2] != 0.0)
            {
                vecAngles[0] = 0.0;
                vecAngles[2] = 0.0;
                TeleportEntity(ent, NULL_VECTOR, vecAngles, NULL_VECTOR);
            }
        }

        if (bStop)
        {
            if (!bGround)
            {
                //Check the right side
                vecPos[0] += 30.0;
                vecCheckBelow[0] += 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the top right corner
                vecPos[1] += 30.0;
                vecCheckBelow[1] += 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the top middle
                vecPos[0] -= 30.0;
                vecCheckBelow[0] -= 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the top left corner
                vecPos[0] -= 30.0;
                vecCheckBelow[0] -= 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the left side
                vecPos[1] -= 30.0;
                vecCheckBelow[1] -= 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the bottom left corner
                vecPos[1] -= 30.0;
                vecCheckBelow[1] -= 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the bottom middle
                vecPos[0] += 30.0;
                vecCheckBelow[0] += 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the bottom right corner
                vecPos[0] += 30.0;
                vecCheckBelow[0] += 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayDontHitSelf, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                new Float:delta = vecPos[2] - vecGround[2];
                if (delta > 5.0)
                {
                    // Move building down to ground (or whatever it hit).
                    TeleportEntity(ent, vecGround, NULL_VECTOR, NULL_VECTOR);
                }
            }

            /* Scarab Stopped */
            if (GetGameType() == tf2)
            {
                /* Create pumpkin bomb in it's place */
                new Float:vecAngles[3];
                GetEntPropVector(ent, Prop_Send, "m_angRotation", vecAngles);
                AcceptEntityInput(ent, "kill");

                ent = CreateEntityByName("tf_pumpkin_bomb");
                if (ent > MaxClients && IsValidEntity(ent))
                {
                    if (IsValidClient(client))
                        SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);

                    DispatchSpawn(ent);
                    TeleportEntity(ent, vecPos, vecAngles, NULL_VECTOR);

                    ref = EntIndexToEntRef(ent);
                }
                else
                    LogError("Unable to create tf_pumpkin_bomb!");
            }

            CreateTimer(fuseTime, DetonateTimer, ref); //EntIndexToEntRef(ent));
        }
        else
        {
            ResetPack(pack);
            WritePackCell(pack, ref);
            WritePackFloat(pack, vecPos[0]);
            WritePackFloat(pack, vecPos[1]);
            WritePackFloat(pack, vecPos[2]);
            WritePackFloat(pack, speed);
            WritePackCell(pack, stopCount);
            WritePackFloat(pack, fuseTime);
            WritePackCell(pack, client);
            return Plugin_Continue;
        }

        gTrackTimers[ent] = INVALID_HANDLE;
    }

    return Plugin_Stop;
}

public Action:DetonateTimer(Handle:timer,any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0)
    {
        DamageEntity(ent,100, GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity"));
    }
}

Detonate(client)
{
    new ent = -1;
    while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")==client)
            CreateTimer(0.1, DetonateTimer, EntIndexToEntRef(ent));
    }
}

Siege(client, level)
{
    if (level > 0)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, siegeID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, siegeID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,errorWav);
        }
        else if (CanInvokeUpgrade(client, raceID, siegeID))
        {
            m_SiegeActive[client] = true;
            m_ScarabCount[client] += level * 20;
            PrintHintText(client, "%t", "SiegeActive");
            PrepareAndEmitSoundToAll(g_ActivateSiegeWav,client);
            HudMessage(client, "%t", "SiegeHud", m_ScarabCount[client]);
            CreateTimer(float(level)*10.0, DeactivateSiege, GetClientUserId(client),
                        TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:DeactivateSiege(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        PrepareAndEmitSoundToAll(g_DeactivateSiegeWav,client);

        m_ScarabCount[client] = 0;
        m_SiegeActive[client] = false;
        PrintHintText(client, "%t", "SiegeExpired");
        HudMessage(client, "%t", "ScarabHud", m_ScarabCount[client]);

        CreateCooldown(client, raceID, siegeID,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
    return Plugin_Stop;
}

