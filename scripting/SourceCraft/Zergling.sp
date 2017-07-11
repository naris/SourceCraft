/**
 * vim: set ai et ts=4 sw=4 :
 * File: Zergling.sp
 * Description: The Zergling race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
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

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <trace>

#include "sc/SourceCraft"
#include "sc/MeleeAttack"
#include "sc/clienttimer"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/ShopItems"
#include "sc/weapons"
#include "sc/respawn"
#include "sc/burrow"
#include "sc/sounds"
#include "sc/armor"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/PurpleGlow"
#include "effect/HaloSprite"
#include "effect/SendEffects"

new const String:spawnWav[] = "sc/zzerdy00.wav";  // Spawn sound
new const String:deathWav[] = "sc/zzedth00.wav";  // Death sound
new const String:bloodlustEndWav[] = "sc/zzewht00.wav";
new const String:bloodlustWav[] = "sc/zzerdy00.wav";

new const Float:g_SpeedLevels[] = { -1.0, 1.05, 1.10, 1.15, 1.20 };
//new const Float:g_SpeedLevels[] = { -1.0, 1.08, 1.19, 1.25, 1.36 };

new const String:g_AdrenalGlandsSound[] = "sc/zulhit00.wav";
new Float:g_AdrenalGlandsPercent[] = { 0.0, 0.15, 0.30, 0.40, 0.50 };

new const String:g_ArmorName[] = "Carapace";
new Float:g_InitialArmor[]     = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]  = { {0.00, 0.00},
                                   {0.00, 0.10},
                                   {0.00, 0.20},
                                   {0.10, 0.40},
                                   {0.10, 0.50} };

new cfgMaxRespawns             = 4;

new raceID, boostID, carapaceID, regenerationID, burrowID;
new meleeID, spawningID, bloodlustID, banelingID;

new g_banelingRace = -1;

new bool:m_BloodlustActive[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Zergling",
    author = "-=|JFH|=-Naris",
    description = "The Zergling race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.respawn.phrases.txt");
    LoadTranslations("sc.zergling.phrases.txt");

    if (GetGameType() == tf2)
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
    else if (GameTypeIsCS())
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

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("zergling", 16, 0, 29, .faction=Zerg, .type=Biological);

    boostID         = AddUpgrade(raceID, "boost", .cost_crystals=0);
    meleeID         = AddUpgrade(raceID, "adrenal_glands", .energy=2.0, .cost_crystals=20);
    regenerationID  = AddUpgrade(raceID, "regeneration", .cost_crystals=10);
    carapaceID      = AddUpgrade(raceID, "carapace", .cost_crystals=5);

    cfgMaxRespawns  = GetConfigNum("max_respawns", cfgMaxRespawns);
    spawningID      = AddUpgrade(raceID, "spawning", .max_level=cfgMaxRespawns,
                                 .energy=10.0, .cost_crystals=25);

    if (cfgMaxRespawns < 1)
    {
        SetUpgradeDisabled(raceID, spawningID, true);
        LogMessage("Disabling Zergling:Spawning Pool due to configuration: sc_maxrespawns=%d",
                   cfgMaxRespawns);
    }

    // Ultimate 1
    bloodlustID     = AddUpgrade(raceID, "bloodlust", 1, .energy=30.0, .cost_crystals=30);

    // Ultimate 2
    burrowID        = AddBurrowUpgrade(raceID, 2, 6, 1);

    // Ultimate 3
    banelingID      = AddUpgrade(raceID, "baneling", 3, 12, 1, .energy=120.0,
                                 .accumulated=true, .cooldown=30.0,
                                 .cost_crystals=50);

    // Get Configuration Data

    GetConfigFloatArray("armor_amount", g_InitialArmor, sizeof(g_InitialArmor),
                        g_InitialArmor, raceID, carapaceID);

    for (new level=0; level < sizeof(g_ArmorPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "armor_percent_level_%d", level);
        GetConfigFloatArray(key, g_ArmorPercent[level], sizeof(g_ArmorPercent[]),
                            g_ArmorPercent[level], raceID, carapaceID);
    }
}

public OnMapStart()
{
    SetupSmokeSprite();
    SetupHaloSprite();
    SetupPurpleGlow();
    SetupBlueGlow();
    SetupRedGlow();
    SetupRespawn();
    SetupSpeed();

    SetupDeniedSound();

    SetupSound(spawnWav);
    SetupSound(deathWav);
    SetupSound(bloodlustWav);
    SetupSound(bloodlustEndWav);
    SetupSound(g_AdrenalGlandsSound);
}

public OnPlayerAuthed(client)
{
    m_BloodlustActive[client] = false;
    m_ReincarnationCount[client]=0;
    m_IsRespawning[client]=false;

    #if defined _TRACE
        m_SpawnCount[client]=0;
    #endif
}

public OnClientDisconnect(client)
{
    m_BloodlustActive[client] = false;
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        TraceInto("Zergling", "OnRaceDeselected", "client=%d:%N, oldrace=%d, race=%d", \
                  client, ValidClientIndex(client), oldrace, race);

        SetSpeed(client,-1.0);
        SetHealthRegen(client, 0.0);
        ResetArmor(client);

        if (m_BloodlustActive[client])
            EndBloodlust(INVALID_HANDLE, GetClientUserId(client));

        TraceReturn();
        return Plugin_Handled;
    }
    else
    {
        if (g_banelingRace < 0)
            g_banelingRace = FindRace("baneling");

        if (oldrace == g_banelingRace &&
            GetCooldownExpireTime(client, raceID, banelingID) <= 0.0)
        {
            CreateCooldown(client, raceID, banelingID,
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
        TraceInto("Zergling", "OnRaceSelected", "client=%d:%N, oldrace=%d, race=%d", \
                  client, ValidClientIndex(client), oldrace, race);

        #if defined _TRACE
            m_SpawnCount[client]=0;
        #endif

        m_BloodlustActive[client] = false;
        m_ReincarnationCount[client]=0;
        m_IsRespawning[client]=false;

        new boost_level = GetUpgradeLevel(client,raceID,boostID);
        SetSpeedBoost(client, boost_level, true, g_SpeedLevels);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        TraceReturn();
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==boostID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==regenerationID)
            SetHealthRegen(client, float(new_level));
        else if (upgrade==carapaceID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==burrowID)
        {
            if (new_level <= 0)
                ResetBurrow(client, true);
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
            new boost_level = GetUpgradeLevel(client,race,boostID);
            if (boost_level > 0)
                SetSpeedBoost(client, boost_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        TraceInto("Zergling", "OnUltimateCommand", "client=%d:%N, race=%d, pressed=%d, arg=%d", \
                  client, ValidClientIndex(client), race, pressed, arg);

        switch (arg)
        {
            case 4,3:
            {
                if (!pressed)
                {
                    new baneling_level=GetUpgradeLevel(client,race,banelingID);
                    if (baneling_level > 0)
                        BanelingMorph(client);
                }
            }
            case 2:
            {
                new burrow_level=GetUpgradeLevel(client,race,burrowID);
                if (burrow_level > 0)
                {
                    if (pressed)
                        Burrow(client, burrow_level);
                }
                else if (!pressed)
                {
                    new baneling_level=GetUpgradeLevel(client,race,banelingID);
                    if (baneling_level > 0)
                        BanelingMorph(client);
                }
            }
            default:
            {
                new bloodlust_level=GetUpgradeLevel(client,race,bloodlustID);
                if (bloodlust_level > 0)
                {
                    if (pressed)
                        Bloodlust(client, bloodlust_level);
                }
                else
                {
                    new burrow_level=GetUpgradeLevel(client,race,burrowID);
                    if (burrow_level > 0)
                    {
                        if (pressed)
                            Burrow(client, burrow_level);
                    }
                    else if (!pressed)
                    {
                        new baneling_level=GetUpgradeLevel(client,race,banelingID);
                        if (baneling_level > 0)
                            BanelingMorph(client);
                    }
                }
            }
        }

        TraceReturn();
    }
}

// Events
public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        m_BloodlustActive[index] = false;
        m_ReincarnationCount[index]=0;
        m_IsRespawning[index]=false;

        #if defined _TRACE
            m_SpawnCount[index]=0;
        #endif
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        TraceInto("Zergling", "OnPlayerSpawnEvent", "client=%d:%N, raceID=%d", \
                  client, ValidClientIndex(client), raceID);

        PrepareAndEmitSoundToAll(spawnWav,client);

        m_BloodlustActive[client] = false;
        Respawned(client,true);

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new boost_level = GetUpgradeLevel(client,raceID,boostID);
        SetSpeedBoost(client, boost_level, true, g_SpeedLevels);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        TraceReturn();
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        new adrenal_glands_level=GetUpgradeLevel(attacker_index,raceID,meleeID);
        new bloodlust = m_BloodlustActive[attacker_index];
        if (bloodlust && !GetRestriction(attacker_index,Restriction_NoUltimates) &&
            !GetRestriction(attacker_index,Restriction_Stunned))
        {
            decl Float:bloodlustPercent[sizeof(g_AdrenalGlandsPercent)];
            new bloodlust_level= GetUpgradeLevel(attacker_index,raceID,bloodlustID);
            new Float:increase = (float(bloodlust_level) * 0.25) + 1.0;
            for (new i = 0; i < sizeof(g_AdrenalGlandsPercent); i++)
            {
                bloodlustPercent[i] = g_AdrenalGlandsPercent[i] * increase;
            }

            new attack_level = (bloodlust_level > adrenal_glands_level ?
                                bloodlust_level : adrenal_glands_level);

            if (MeleeAttack(raceID, meleeID, attack_level, event, damage + absorbed,
                            victim_index, attacker_index, bloodlustPercent,
                            g_AdrenalGlandsSound, "sc_bloodlust"))
            {
                return Plugin_Handled;
            }
        }
        else if (adrenal_glands_level > 0)
        {
            if (MeleeAttack(raceID, meleeID, adrenal_glands_level, event, damage + absorbed,
                            victim_index, attacker_index, g_AdrenalGlandsPercent,
                            g_AdrenalGlandsSound, "sc_adrenal_glands"))
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
    if (victim_race==raceID)
    {
        TraceInto("Zergling", "OnPlayerDeathEvent", "victim_index=%d:%N, victim_race=%d, attacker_index=%d:%N, attacker_race=%d", \
                  victim_index, ValidClientIndex(victim_index), victim_race, \
                  attacker_index, ValidClientIndex(attacker_index), attacker_race);

        SetSpeed(victim_index,-1.0);

        if (m_BloodlustActive[victim_index])
            EndBloodlust(INVALID_HANDLE, GetClientUserId(victim_index));

        PrepareAndEmitSoundToAll(deathWav,victim_index);

        if (m_IsRespawning[victim_index])
        {
            Trace("%N died again while respawning", \
                  ValidClientIndex(victim_index));
        }
        else if (IsChangingClass(victim_index))
        {
            m_ReincarnationCount[victim_index]=0;

            #if defined _TRACE
                m_SpawnCount[victim_index]=0;
            #endif

            Trace("%N changed class", \
                  ValidClientIndex(victim_index));
        }
        else if (IsBurrowed(victim_index))
        {
            m_ReincarnationCount[victim_index]=0;

            #if defined _TRACE
                m_SpawnCount[victim_index]=0;
            #endif

            Trace("%N died while burrowed", \
                  ValidClientIndex(victim_index));
        }
        else if (IsMole(victim_index))
        {
            PrepareAndEmitSoundToClient(victim_index,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, spawningID, upgradeName, sizeof(upgradeName), victim_index);
            DisplayMessage(victim_index, Display_Message, "%t", "NotAsMole", upgradeName);
            m_ReincarnationCount[victim_index] = 0;

            #if defined _TRACE
                m_SpawnCount[victim_index]=0;
            #endif

            Trace("%N died while a mole", \
                  ValidClientIndex(victim_index));
        }
        else if (GetImmunity(attacker_index,Immunity_Silver))
        {
            PrepareAndEmitSoundToClient(victim_index,deniedWav);
            m_ReincarnationCount[victim_index] = 0;

            if (attacker_index != victim_index && IsValidClient(attacker_index))
            {
                DisplayMessage(victim_index, Display_Message, "%t", "PreventedFromRespawningBySilver", attacker_index);
                DisplayMessage(attacker_index, Display_Enemy_Message, "%t", "RespawnWasPreventedBySilver", victim_index);
            }
            else
            {
                DisplayMessage(victim_index, Display_Message, "%t", "RespawnPreventedBySilver");
            }

            #if defined _TRACE
                m_SpawnCount[victim_index]=0;
            #endif

            Trace("%d:%N died due to %d:%N's silver!", \
                  victim_index, ValidClientIndex(victim_index), \
                  attacker_index, ValidClientIndex(attacker_index));
        }
        else if (assister_index > 0 && GetImmunity(assister_index,Immunity_Silver))
        {
            PrepareAndEmitSoundToClient(victim_index,deniedWav);
            m_ReincarnationCount[victim_index] = 0;

            if (IsValidClient(assister_index))
            {
                DisplayMessage(victim_index, Display_Message, "%t", "PreventedFromRespawningBySilver", assister_index);
                DisplayMessage(assister_index, Display_Enemy_Message, "%t", "RespawnWasPreventedBySilver", victim_index);
            }
            else
            {
                DisplayMessage(victim_index, Display_Message, "%t", "RespawnPreventedBySilver");
            }

            #if defined _TRACE
                m_SpawnCount[victim_index]=0;
            #endif

            Trace("%d:%N died due to %d:%N's silver!", \
                  victim_index, ValidClientIndex(victim_index), \
                  assister_index, ValidClientIndex(assister_index));
        }
        else if (GetRestriction(victim_index,Restriction_NoRespawn) ||
                 GetRestriction(victim_index,Restriction_NoUpgrades) ||
                 GetRestriction(victim_index,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(victim_index,deniedWav);
            DisplayMessage(victim_index, Display_Message, "%t", "RespawnPrevented");
            m_ReincarnationCount[victim_index] = 0;

            #if defined _TRACE
                m_SpawnCount[victim_index]=0;
            #endif

            Trace("%d:%N died due to restrictions!", \
                  victim_index, ValidClientIndex(victim_index));
        }
        else
        {
            new count = m_ReincarnationCount[victim_index];
            new spawning_level = GetUpgradeLevel(victim_index, victim_race, spawningID);
            if (spawning_level > 0 && count < cfgMaxRespawns && count < spawning_level)
            {
                if (count == 0 || GetRandomInt(1,100) <= (100 - (count*30)))
                {
                    if (CanInvokeUpgrade(victim_index, victim_race, spawningID, .notify=false))
                    {
                        Respawn(victim_index);

                        decl String:suffix[3];
                        count = m_ReincarnationCount[victim_index];
                        GetNumberSuffix(count, suffix, sizeof(suffix));

                        if (GameType == dod)
                        {
                            DisplayMessage(victim_index, Display_Message, "%t",
                                           "WillRespawn", count, suffix);
                        }
                        else
                        {
                            TE_SetupGlowSprite(m_DeathLoc[victim_index], PurpleGlow(), 1.0, 3.5, 150);
                            TE_SendEffectToAll();

                            DisplayMessage(victim_index, Display_Message,"%t",
                                           "YouAreRespawning",  count, suffix);
                            if (attacker_index != victim_index && IsValidClient(attacker_index))
                            {
                                DisplayMessage(attacker_index,Display_Enemy_Message,"%t",
                                               "IsRespawning",  victim_index, count, suffix);
                            }
                        }
                    }
                    else
                    {
                        m_ReincarnationCount[victim_index] = 0;

                        #if defined _TRACE
                            m_SpawnCount[victim_index]=0;
                        #endif

                        Trace("%N died due to lack of energy", victim_index);
                    }
                }
                else
                {
                    m_ReincarnationCount[victim_index] = 0;

                    #if defined _TRACE
                        m_SpawnCount[victim_index]=0;
                    #endif

                    Trace("%N died due to fate", victim_index);
                }
            }
            else
            {
                m_ReincarnationCount[victim_index] = 0;

                #if defined _TRACE
                    m_SpawnCount[victim_index]=0;
                #endif

                Trace("%N died due to lack of levels(=%d, count=%d)", \
                      victim_index, spawning_level, count);
            }
        }

        TraceReturn();
    }
    else
    {
        if (g_banelingRace < 0)
            g_banelingRace = FindRace("baneling");

        if (victim_race == g_banelingRace &&
            GetCooldownExpireTime(victim_index, raceID, banelingID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, banelingID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

BanelingMorph(client)
{
    if (g_banelingRace < 0)
        g_banelingRace = FindRace("baneling");

    if (g_banelingRace < 0)
    {
        DisplayMessage(client, Display_Ultimate, "%t", "BanelingNotAvailable");
        LogError("***The Baneling race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromBaneling");
    }
    else if (HasCooldownExpired(client, raceID, banelingID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        DisplayMessage(client,Display_Ultimate, "%t", "MorphedIntoBaneling");

        ChangeRace(client, g_banelingRace, true, false, true);
    }
}

Bloodlust(client, level)
{
    if (level > 0)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, bloodlustID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (CanInvokeUpgrade(client, raceID, bloodlustID))
        {
            new Float:speed=g_SpeedLevels[level] + (float(level)*0.05);

            /* If the Player also has the Boots of Speed,
             * Increase the speed further
             */
            new boots = FindShopItem("boots");
            if (boots != -1 && GetOwnsItem(client,boots))
            {
                speed *= 1.1;
            }

            SetSpeed(client,speed);

            new Float:start[3];
            GetClientAbsOrigin(client, start);

            static const color[4] = { 255, 100, 100, 255 };
            TE_SetupBeamRingPoint(start,20.0,60.0, SmokeSprite(), HaloSprite(),
                                  0, 1, 1.0, 4.0, 0.0 ,color, 10, 0);
            TE_SendEffectToAll();

            m_BloodlustActive[client] = true;
            PrintHintText(client, "%t", "InvokedBloodlust");
            HudMessage(client, "%t", "BloodlustHud");
            
            PrepareAndEmitSoundToAll(bloodlustWav,client);
            
            CreateTimer(10.0, EndBloodlust, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:EndBloodlust(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        m_BloodlustActive[client] = false;

        if (IsPlayerAlive(client) && GetRace(client) == raceID)
        {
            PrepareAndEmitSoundToAll(bloodlustEndWav,client);
            PrintHintText(client, "%t", "BloodlustEnded");
            ClearHud(client, "%t", "BloodlustHud");

            new boost_level = GetUpgradeLevel(client,raceID,boostID);
            SetSpeedBoost(client, boost_level, true, g_SpeedLevels);
        }
        else
            SetSpeed(client,-1.0);
    }
}

