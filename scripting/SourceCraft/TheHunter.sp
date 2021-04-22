/**
 * vim: set ai et ts=4 sw=4 :
 * File: TheHunter.sp
 * Description: The Titty Hunter race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <new_tempents_stocks>
#include <entlimit>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include "tf2_stocks"
#include "tf2_player"
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include "lib/jetpack"
#include "libtf2/sidewinder"
#define REQUIRE_PLUGIN

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include "lib/trace"

#include "sc/SourceCraft"
#include "sc/PlagueInfect"
#include "sc/Hallucinate"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/SendEffects"

char fartWav[][]            = { "sc/fart.wav",
                                "sc/fart3.wav",
                                "sc/poot.mp3" };

int g_DrainChance[][]       = { {  0,  0 },
                                { 15, 25 },
                                { 25, 40 },
                                { 40, 60 },
                                { 60, 80 } };

int g_SiphonChance[][]      = { {  0,  0 },
                                { 15, 25 },
                                { 25, 40 },
                                { 40, 60 },
                                { 60, 80 } };

int g_PickPocketChance[][]  = { {  0,  0 },
                                { 15, 25 },
                                { 25, 40 },
                                { 40, 60 },
                                { 60, 80 } };

int g_FrescaChance[]        = { 5, 15, 25, 35, 45 };

int g_HallucinateChance[]   = { 0, 15, 25, 35, 50 };

int g_JetpackFuel[]         = { 0, 40, 50, 70, 90 };
float g_JetpackRefuelTime[] = { 0.0, 45.0, 35.0, 25.0, 15.0 };


int raceID, drainID, siphonID, pickPocketID, hallucinationID, frescaID, fartID, snatchID, jetpackID, nippleID;

float gDrainTime[MAXPLAYERS+1];
float gSiphonTime[MAXPLAYERS+1];
float gPickPocketTime[MAXPLAYERS+1];

bool m_SnatchActive[MAXPLAYERS+1];
bool m_IsNipple[MAXPLAYERS+1];

int m_SnatchedXP[MAXPLAYERS+1][MAXPLAYERS+1];
int m_SnatchedLevels[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin myinfo = 
{
    name = "SourceCraft Race - Titty Hunter",
    author = "Naris",
    description = "The Titty Hunter race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://www.jigglysfunhouse.net/"
};

public void OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.hallucinate.phrases.txt");
    LoadTranslations("sc.titty_hunter.phrases.txt");

    if (GetGameType() == tf2)
    {
        if(!HookEventEx("teamplay_round_win",RoundEndEvent, EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_win event.");

        if(!HookEventEx("teamplay_round_stalemate",RoundEndEvent, EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_stalemate event.");

        if(!HookEventEx("teamplay_overtime_end",RoundEndEvent, EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_overtime_end event.");

        if(!HookEventEx("teamplay_win_panel",RoundEndEvent, EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_win_panel event.");

        if(!HookEventEx("teamplay_game_over",RoundEndEvent, EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_game_over event.");

        if (!HookEventEx("arena_win_panel",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the arena_win_panel event.");

        if (!HookEvent("teamplay_suddendeath_end",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_suddendeath_end event.");

        if (!HookEvent("mvm_wave_complete",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the mvm_wave_complete event.");

        if (!HookEvent("mvm_wave_failed",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the mvm_wave_failed event.");
    }
    else if (GameTypeIsCS())
    {
        if (!HookEvent("cs_win_panel_round",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the cs_win_panel_round event.");

        if (!HookEvent("cs_win_panel_match",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the cs_win_panel_match event.");
    }
    else if (GameType == dod)
    {
        if (!HookEvent("dod_round_win",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the dod_round_start event.");

        if (!HookEvent("dod_game_over",RoundEndEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the dod_game_over event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public int OnSourceCraftReady()
{
    raceID          = CreateRace("titty_hunter", -1, -1, 36, .energy_limit=1000.0,
                                 .faction=UndeadScourge, .type=Undead, .parent="farter");

    drainID         = AddUpgrade(raceID, "drain", .energy=1.0, .cost_crystals=20);
    siphonID        = AddUpgrade(raceID, "siphon", .energy=5.0, .cost_crystals=20);
    pickPocketID    = AddUpgrade(raceID, "pickpocket", .energy=1.0, .name="Pickpocket", .cost_crystals=40);
    hallucinationID = AddUpgrade(raceID, "hallucination", .energy=2.0, .cost_crystals=30);
    frescaID        = AddUpgrade(raceID, "fresca", 0, 0, .energy=20.0, .cost_crystals=30);

    // Ultimate 1
    jetpackID       = AddUpgrade(raceID, "jetpack", 1, .cost_crystals=25);

    if (!IsJetpackAvailable())
    {
        SetUpgradeDisabled(raceID, jetpackID, true);
        LogMessage("Disabling Titty Hunter:Summon Jetpack due to jetpack is not available");
    }

    // Ultimate 2
    fartID          = AddUpgrade(raceID, "fart", 2, .energy=30.0,
                                 .cooldown=2.0, .cost_crystals=30);

    // Ultimate 3
    nippleID        = AddUpgrade(raceID, "nipple", 3, 12, .energy=100.0,
                                 .vespene=10, .cooldown=30.0, .cost_crystals=75);

    if (!IsSidewinderAvailable())
    {
        SetUpgradeDisabled(raceID, nippleID, true);
        LogMessage("Disabling Titty Hunter:The Nipple due to sidewinder is not available");
    }

    // Ultimate 4
    snatchID        = AddUpgrade(raceID, "snatch", 4, .energy=120.0,
                                 .vespene=30, .cooldown=60.0, .cost_crystals=75);

    // Get Configuration Data
    GetConfigArray("chance", g_HallucinateChance, sizeof(g_HallucinateChance),
                   g_HallucinateChance, raceID, hallucinationID);

    GetConfigArray("chance", g_FrescaChance, sizeof(g_FrescaChance),
                   g_FrescaChance, raceID, frescaID);

    GetConfigArray("fuel", g_JetpackFuel, sizeof(g_JetpackFuel),
                   g_JetpackFuel, raceID, jetpackID);

    GetConfigFloatArray("refuel_time", g_JetpackRefuelTime, sizeof(g_JetpackRefuelTime),
                        g_JetpackRefuelTime, raceID, jetpackID);

    for (int level=0; level < sizeof(g_DrainChance); level++)
    {
        char key[32];
        Format(key, sizeof(key), "chance_level_%d", level);
        GetConfigArray(key, g_DrainChance[level], sizeof(g_DrainChance[]),
                       g_DrainChance[level], raceID, drainID);
    }

    for (int level=0; level < sizeof(g_SiphonChance); level++)
    {
        char key[32];
        Format(key, sizeof(key), "chance_level_%d", level);
        GetConfigArray(key, g_SiphonChance[level], sizeof(g_SiphonChance[]),
                       g_SiphonChance[level], raceID, siphonID);
    }

    for (int level=0; level < sizeof(g_PickPocketChance); level++)
    {
        char key[32];
        Format(key, sizeof(key), "chance_level_%d", level);
        GetConfigArray(key, g_PickPocketChance[level], sizeof(g_PickPocketChance[]),
                       g_PickPocketChance[level], raceID, pickPocketID);
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "jetpack"))
        IsJetpackAvailable(true);
    else if (StrEqual(name, "sidewinder"))
        IsSidewinderAvailable(true);
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "jetpack"))
        m_JetpackAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
}

public void OnMapStart()
{
    SetupLightning();
    SetupHaloSprite();
    SetupHallucinate();

    SetupErrorSound();
    SetupDeniedSound();

    for (int i = 0; i < sizeof(fartWav); i++)
        SetupSound(fartWav[i]);
}

public int OnPlayerAuthed(int client)
{
    gDrainTime[client] = 0.0;
    gSiphonTime[client] = 0.0;
    gPickPocketTime[client] = 0.0;

    m_SnatchActive[client] = false;
    for (int index = 0; index < MAXPLAYERS+1; index++)
    {
        m_SnatchedXP[client][index] = 0;
        m_SnatchedLevels[client][index] = 0;
    }
}

public void OnClientDisconnect(int client)
{
    gDrainTime[client] = 0.0;
    gSiphonTime[client] = 0.0;
    gPickPocketTime[client] = 0.0;

    m_SnatchActive[client] = false;
    Release(client);
}

public Action OnRaceDeselected(int client, int oldrace, int newrace)
{
    TraceInto("TheHunter", "OnRaceDeselected", "client=%d, oldrace=%d, newrace=%d", \
                client, oldrace, newrace);

    if (oldrace == raceID)
    {
        m_SnatchActive[client] = false;

        SetupSidewinder(client, -1, false);
        SetVisibility(client, NormalVisibility);

        if (m_JetpackAvailable)
            TakeJetpack(client);

        int maxCrystals = GetMaxCrystals();
        if (GetCrystals(client) > maxCrystals)
        {
            SetCrystals(client, maxCrystals);
            DisplayMessage(client, Display_Crystals, "%t",
                           "CrystalsReduced", maxCrystals);
        }

        Release(client);
    }
    else
    {
        Recover(client);
    }

    TraceReturn();
    return Plugin_Continue;
}

public Action OnRaceSelected(int client, int oldrace, int newrace)
{
    if (newrace == raceID)
    {
        TraceInto("TheHunter", "OnRaceSelected", "client=%d, oldrace=%d, newrace=%d", \
                  client, oldrace, newrace);

        //Set Hunter Color
        int r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 255; g = 255; b = 64; }
        else
        { r = 64; g = 255; b = 255; }

        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b);

        gDrainTime[client] = 0.0;
        gSiphonTime[client] = 0.0;
        gPickPocketTime[client] = 0.0;
        m_SnatchActive[client] = false;

        int jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        int nipple_level=GetUpgradeLevel(client,raceID,nippleID);
        SetupSidewinder(client, nipple_level, false);

        TraceReturn();
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public int OnUpgradeLevelChanged(int client, int race, int upgrade, int new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==jetpackID)
            SetupJetpack(client, new_level);
        else if (upgrade==nippleID)
            SetupSidewinder(client, new_level, m_IsNipple[client]);
    }
}

public int OnUltimateCommand(int client, int race, bool pressed, int arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        TraceInto("TheHunter", "OnUltimateCommand", "client=%N(%d), race=%d, pressed=%d, arg=%d", \
                  client, client, race, pressed, arg);

        switch (arg)
        {
            case 4: // Snatch Level
            {
                if (pressed && GetUpgradeLevel(client,race,snatchID))
                    Snatch(client);
            }
            case 3: // The Nipple
            {
                if (pressed)
                {
                    int nipple_level=GetUpgradeLevel(client,race,nippleID);
                    if (nipple_level > 0)
                        TheNipple(client, nipple_level);
                    else if (GetUpgradeLevel(client,race,snatchID))
                        Snatch(client);
                }
            }
            case 2: // Taco-Burrito Fart
            {
                if (pressed)
                {
                    int fart_level = GetUpgradeLevel(client,race,fartID);
                    if (fart_level > 0)
                        Fart(client,fart_level);
                    else
                    {
                        int nipple_level=GetUpgradeLevel(client,race,nippleID);
                        if (nipple_level > 0)
                            TheNipple(client, nipple_level);
                        else if (GetUpgradeLevel(client,race,snatchID))
                            Snatch(client);
                    }
                }
            }
            default: // Jetpack
            {
                int jetpack_level = GetUpgradeLevel(client,race,jetpackID);
                if (jetpack_level > 0)
                    Jetpack(client, pressed);
                else if (pressed)
                {
                    int fart_level = GetUpgradeLevel(client,race,fartID);
                    if (fart_level > 0)
                        Fart(client,fart_level);
                    else
                    {
                        int nipple_level=GetUpgradeLevel(client,race,nippleID);
                        if (nipple_level > 0)
                            TheNipple(client, nipple_level);
                        else if (pressed && GetUpgradeLevel(client,race,snatchID))
                            Snatch(client);
                    }
                }
            }
        }

        TraceReturn();
    }
}

// Events
public void RoundEndEvent(Handle event,const char[] name,bool dontBroadcast)
{
    for (int index=1;index<=MaxClients;index++)
    {
        Release(index);
        Recover(index);
    }
}

public int OnPlayerSpawnEvent(Handle event, int client, int race)
{
    if (race == raceID)
    {
        TraceInto("TheHunter", "OnPlayerSpawnEvent", "client=%N(%d), handle=%x, raceID=%d", \
                  client, client, raceID);

        m_SnatchActive[client] = false;

        //Set Hunter Color
        int r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 255; g = 255; b = 64; }
        else
        { r = 64; g = 255; b = 255; }

        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b);

        int jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        int nipple_level=GetUpgradeLevel(client,raceID,nippleID);
        SetupSidewinder(client, nipple_level, false);

        TraceReturn();
    }
}

public Action OnPlayerHurtEvent(Handle event, int victim_index, int victim_race,
                                int attacker_index, int attacker_race, int damage,
                                int absorbed, bool from_sc)
{
    bool handled=false;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID &&
        IsClient(victim_index))
    {
        if (m_SnatchActive[attacker_index])
            SnatchLevel(victim_index, attacker_index);
        else
        {
            int fresca_level=GetUpgradeLevel(attacker_index, raceID, frescaID);
            if (GetRandomInt(1,100)<=g_FrescaChance[fresca_level])
            {
                if (!GetRestriction(attacker_index, Restriction_NoUpgrades) &&
                    !GetRestriction(attacker_index, Restriction_Stunned) &&
                    !GetImmunity(victim_index,Immunity_HealthTaking) &&
                    !GetImmunity(victim_index,Immunity_Upgrades) &&
                    !GetImmunity(victim_index,Immunity_Restore) &&
                    !IsInvulnerable(victim_index))
                {
                    if (CanInvokeUpgrade(attacker_index, raceID, frescaID))
                    {
                        handled = true;
                        PlagueInfect(attacker_index, victim_index, fresca_level, fresca_level,
                                     ExplosivePlague|FatalPlague|EnsnaringPlague|PoisonousPlague,
                                     "sc_fresca");
                    }
                }
            }

            if (!handled)
            {
                float halluc_amount = GetUpgradeEnergy(raceID,hallucinationID);
                int halluc_level = GetUpgradeLevel(attacker_index,raceID,hallucinationID);
                Hallucinate(victim_index, attacker_index, halluc_level, halluc_amount,
                            g_HallucinateChance);

                Drain(event, victim_index, attacker_index);
                Siphon(event, victim_index, attacker_index);
                PickPocket(event, victim_index, attacker_index);
            }
        }
    }

    return handled ? Plugin_Handled : Plugin_Continue;
}


public Action OnPlayerAssistEvent(Handle event, int victim_index, int victim_race,
                                  int assister_index, int assister_race, int damage,
                                  int absorbed)
{
    bool handled=false;

    if (assister_race == raceID)
    {
        if (m_SnatchActive[assister_index])
            SnatchLevel(victim_index, assister_index);
        else
        {
            int fresca_level=GetUpgradeLevel(assister_index, raceID, frescaID);
            if (GetRandomInt(1,100)<=g_FrescaChance[fresca_level])
            {
                if (!GetRestriction(assister_index, Restriction_NoUpgrades) &&
                    !GetRestriction(assister_index, Restriction_Stunned) &&
                    !GetImmunity(victim_index,Immunity_Ultimates) &&
                    !GetImmunity(victim_index,Immunity_HealthTaking) &&
                    !GetImmunity(victim_index,Immunity_Upgrades) &&
                    !GetImmunity(victim_index,Immunity_Restore) &&
                    !IsInvulnerable(victim_index))
                {
                    if (CanInvokeUpgrade(assister_index, raceID, frescaID))
                    {
                        handled = true;
                        PlagueInfect(assister_index, victim_index, fresca_level, fresca_level,
                                     ExplosivePlague|FatalPlague|EnsnaringPlague|PoisonousPlague,
                                     "sc_fresca");
                    }
                }
            }

            if (!handled)
            {
                Drain(event, victim_index, assister_index);
                Siphon(event, victim_index, assister_index);
                PickPocket(event, victim_index, assister_index);

                float halluc_amount = GetUpgradeEnergy(raceID,hallucinationID);
                int halluc_level = GetUpgradeLevel(assister_index,raceID,hallucinationID);
                Hallucinate(victim_index, assister_index, halluc_level, halluc_amount,
                            g_HallucinateChance);
            }
        }
    }

    return handled ? Plugin_Handled : Plugin_Continue;
}

public int OnPlayerDeathEvent(Handle event, int victim_index, int victim_race,
                               int attacker_index, int attacker_race,
                               int assister_index, int assister_race,
                               int damage, const char[] weapon,
                               bool is_equipment, int customkill,
                               bool headshot, bool backstab, bool melee)
{
    m_SnatchActive[victim_index] = false;

    if (victim_race == raceID)
    {
        SetupSidewinder(victim_index, -1, false);
        Release(victim_index);
    }
}

float Drain(Handle event, int victim_index, int index)
{
    TraceInto("TheHunter", "Drain", "index=%N(%d), victim_index=%N(%d), event=%x", \
              index, index, victim_index, victim_index, event);

    float plunder = 0.0;
    int level = GetUpgradeLevel(index, raceID, drainID);
    if (level > 0 && !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned))
    {
        char weapon[64];
        bool is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
        bool is_melee=IsMelee(weapon, is_equipment,index,victim_index);

        float victim_energy=GetEnergy(victim_index);
        if (victim_energy > 0)
        {
            if ((gDrainTime[index] == 0.0 || GetGameTime() - gDrainTime[index] > 0.5)  &&
                GetRandomInt(1,100) <= g_DrainChance[level][is_melee] &&
                !GetImmunity(victim_index,Immunity_Upgrades) &&
                !GetImmunity(victim_index,Immunity_Theft) &&
                !IsInvulnerable(victim_index) &&
                CanInvokeUpgrade(index, raceID, drainID))
            {
                float percent=GetRandomFloat(0.0,is_melee ? 0.25 : 0.15);
                plunder = victim_energy * percent;

                SetEnergy(victim_index,victim_energy-plunder);
                SetEnergy(index,GetEnergy(index)+plunder);
                gDrainTime[index] = GetGameTime();

                float indexLoc[3];
                GetClientAbsOrigin(index, indexLoc);
                indexLoc[2] += 50.0;

                float victimLoc[3];
                GetClientAbsOrigin(victim_index, victimLoc);
                victimLoc[2] += 50.0;

                static const int color[4] = { 100, 255, 255, 55 };
                TE_SetupBeamPoints(indexLoc, victimLoc, Lightning(), HaloSprite(),
                                   0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendQEffectToAll(index, victim_index);

                LogToGame("%N drained %f energy from %N", index, plunder, victim_index);

                DisplayMessage(index, Display_Damage, "%t",
                               "YouHaveDrainedEnergy", plunder, victim_index);

                DisplayMessage(victim_index, Display_Injury, "%t",
                               "DrainedYourEnergy", index, plunder);
            }
        }
    }

    TraceReturn("plunder=%d", plunder);
    return plunder;
}

int Siphon(Handle event, int victim_index, int index)
{
    TraceInto("TheHunter", "Siphon", "index=%N(%d), victim_index=%N(%d), event=%x", \
              index, index, victim_index, victim_index, event);

    int plunder = 0;
    int level = GetUpgradeLevel(index, raceID, siphonID);
    if (level > 0 && !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned))
    {
        char weapon[64];
        bool is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
        bool is_melee=IsMelee(weapon, is_equipment,index,victim_index);

        int gas = GetVespene(index);
        int victim_gas = GetVespene(victim_index);
        if (victim_gas > 0 && gas < GetMaxVespene())
        {
            if ((gSiphonTime[index] == 0.0 || GetGameTime() - gSiphonTime[index] > 2.0 &&
                GetRandomInt(1,100) <= g_SiphonChance[level][is_melee] &&
                !GetImmunity(victim_index,Immunity_Upgrades) &&
                !GetImmunity(victim_index,Immunity_Theft) &&
                !IsInvulnerable(victim_index)) &&
                CanInvokeUpgrade(index, raceID, siphonID))
            {
                float percent=GetRandomFloat(0.0,is_melee ? 0.15 : 0.05);
                plunder = RoundToCeil(float(victim_gas) * percent);

                SetVespene(victim_index,victim_gas-plunder);
                SetVespene(index,gas+plunder);
                gSiphonTime[index] = GetGameTime();

                float indexLoc[3];
                GetClientAbsOrigin(index, indexLoc);
                indexLoc[2] += 50.0;

                float victimLoc[3];
                GetClientAbsOrigin(victim_index, victimLoc);
                victimLoc[2] += 50.0;

                static const int color[4] = { 100, 55, 255, 255 };
                TE_SetupBeamPoints(indexLoc, victimLoc, Lightning(), HaloSprite(),
                                   0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendQEffectToAll(index, victim_index);

                LogToGame("%N siphoned %d vespene from %N", index, plunder, victim_index);

                DisplayMessage(index, Display_Damage, "%t",
                               "YouHaveSiphonedVespene", plunder, victim_index);

                DisplayMessage(victim_index, Display_Injury, "%t",
                               "SiphonedYourVespene", index, plunder);
            }
        }
    }

    TraceReturn("plunder=%d", plunder);
    return plunder;
}

int PickPocket(Handle event, int victim_index, int index)
{
    TraceInto("TheHunter", "PickPocket", "index=%N(%d), victim_index=%N(%d), event=%x", \
              index, index, victim_index, victim_index, event);

    int plunder = 0;
    int level = GetUpgradeLevel(index, raceID, pickPocketID);
    if (level > 0 && !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned))
    {
        char weapon[64];
        bool is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
        bool is_melee=IsMelee(weapon, is_equipment,index,victim_index);

        int victim_cash=GetCrystals(victim_index);
        if (victim_cash > 0)
        {
            if ((gPickPocketTime[index] == 0.0 || GetGameTime() - gPickPocketTime[index] > 0.5) &&
                GetRandomInt(1,100) <= g_PickPocketChance[level][is_melee] &&
                !GetImmunity(victim_index,Immunity_Upgrades) &&
                !GetImmunity(victim_index,Immunity_Theft) &&
                !IsInvulnerable(victim_index) &&
                CanInvokeUpgrade(index, raceID, pickPocketID))
            {
                float percent=GetRandomFloat(0.0,is_melee ? 0.15 : 0.05);
                int cash=GetCrystals(index);
                plunder = RoundToCeil(float(victim_cash) * percent);

                SetCrystals(victim_index,victim_cash-plunder,false);
                SetCrystals(index,cash+plunder,false);
                gPickPocketTime[index] = GetGameTime();

                float indexLoc[3];
                GetClientAbsOrigin(index, indexLoc);
                indexLoc[2] += 50.0;

                float victimLoc[3];
                GetClientAbsOrigin(victim_index, victimLoc);
                victimLoc[2] += 50.0;

                static const int color[4] = { 100, 255, 55, 255 };
                TE_SetupBeamPoints(indexLoc, victimLoc, Lightning(), HaloSprite(),
                                   0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendQEffectToAll(index, victim_index);

                LogToGame("%N stole %d crystal(s) from %N", index, plunder, victim_index);

                DisplayMessage(index, Display_Damage, "%t",
                              "YouHaveStolenCrystals", plunder, victim_index);

                DisplayMessage(victim_index, Display_Injury, "%t",
                               "StoleYourCrystals", index, plunder);
            }
        }
    }

    TraceReturn("plunder=%d", plunder);
    return plunder;
}

void Jetpack(client, bool pressed)
{
    if (m_JetpackAvailable)
    {
        if (pressed)
        {
            if (GetRestriction(client, Restriction_NoUltimates) ||
                GetRestriction(client, Restriction_Grounded) ||
                GetRestriction(client, Restriction_Stunned))
            {
                PrepareAndEmitSoundToAll(deniedWav, client);
            }
            else
                StartJetpack(client);
        }
        else
            StopJetpack(client);
    }
    else if (pressed)
    {
        char upgradeName[64];
        GetUpgradeName(raceID, jetpackID, upgradeName, sizeof(upgradeName), client);
        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
    }
}

void SetupJetpack(int client, int level)
{
    if (m_JetpackAvailable)
    {
        if (level > 0)
        {
            if (level >= sizeof(g_JetpackFuel))
            {
                LogError("%d:%N has too many levels in TheHunter::Jetpack level=%d, max=%d",
                         client,ValidClientIndex(client),level,sizeof(g_JetpackFuel));

                level = sizeof(g_JetpackFuel)-1;
            }
            GiveJetpack(client, g_JetpackFuel[level], g_JetpackRefuelTime[level],
                        .explode = (level > 2), .burn = (level > 3));
        }
        else
            TakeJetpack(client);
    }
}

void Fart(int client, int fart_level)
{
    if (IsEntLimitReached(.client=client,
                          .message="Unable to spawn anymore fart clouds"))
    {
        char upgradeName[64];
        GetUpgradeName(raceID, fartID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NoEntitiesAvailable");
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        char upgradeName[64];
        GetUpgradeName(raceID, fartID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, fartID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        float location[3];
        GetClientAbsOrigin(client, location);

        char originData[64];
        Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);

        char damage[64];
        Format(damage, sizeof(damage), "%i", ((fart_level+1)*12));

        char radius[64];
        Format(radius, sizeof(radius), "%i", ((fart_level+1)*100));

        char team[64];
        Format(team, sizeof(team), "%i", GetClientTeam(client));

        // Don't Create the filter
        /*
        char filter_name[128];
        Format(filter_name, sizeof(filter_name), "FartFilter%i", client);

        int filter = CreateEntityByName("filter_activator_tfteam");
        if (filter && IsValidEntity(filter))
        {
            DispatchKeyValue(filter,"targetname", filter_name);
            DispatchKeyValue(filter,"Team", team);
            DispatchSpawn(filter);
        }
        else
            LogError("TheHunter::Fart() Unable to create filter");
        */

        // Create the PointHurt
        int pointHurt = CreateEntityByName("point_hurt");
        if (pointHurt > 0 && IsValidEdict(pointHurt))
        {
            //DispatchKeyValue(pointHurt,"filtername", filter_name);
            DispatchKeyValue(pointHurt,"Origin", originData);
            DispatchKeyValue(pointHurt,"Damage", damage);
            DispatchKeyValue(pointHurt,"DamageRadius", radius);
            DispatchKeyValue(pointHurt,"DamageDelay", "0.5");
            DispatchKeyValue(pointHurt,"DamageType", "65536");
            DispatchSpawn(pointHurt);
            AcceptEntityInput(pointHurt, "TurnOn");

            // Create the Gas Cloud
            char gas_name[128];
            Format(gas_name, sizeof(gas_name), "Fart%i", client);

            int gascloud = CreateEntityByName("env_smokestack");
            if (gascloud > 0 && IsValidEdict(gascloud))
            {
                //DispatchKeyValue(pointHurt,"filtername", filter_name);
                DispatchKeyValue(gascloud,"targetname", gas_name);
                DispatchKeyValue(gascloud,"Origin", originData);
                DispatchKeyValue(gascloud,"BaseSpread", "100");
                DispatchKeyValue(gascloud,"SpreadSpeed", "10");
                DispatchKeyValue(gascloud,"Speed", "80");
                DispatchKeyValue(gascloud,"StartSize", "200");
                DispatchKeyValue(gascloud,"EndSize", "2");
                DispatchKeyValue(gascloud,"Rate", "15");
                DispatchKeyValue(gascloud,"JetLength", "400");
                DispatchKeyValue(gascloud,"Twist", "4");
                DispatchKeyValue(gascloud,"RenderColor", "110 115 0");
                DispatchKeyValue(gascloud,"RenderAmt", "100");
                DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
                DispatchSpawn(gascloud);
                AcceptEntityInput(gascloud, "TurnOn");

                float length = float((fart_level+1)*4);
                if (length <= 8.0)
                    length = 8.0;

                int snd = GetRandomInt(0,sizeof(fartWav)-1);
                PrepareAndEmitSoundToAll(fartWav[snd], client);

                Handle entitypack = CreateDataPack();
                CreateTimer(1.0, ActivateGas, entitypack);
                CreateTimer(length, ClearGas, entitypack);
                CreateTimer(length + 5.0, KillGas, entitypack);
                WritePackCell(entitypack, gascloud);
                WritePackCell(entitypack, pointHurt);
                //WritePackCell(entitypack, filter);

                DisplayMessage(client,Display_Ultimate,
                               "%t", "TacoBurritoFarted");

                CreateCooldown(client, raceID, fartID);
            }
            else
                LogError("Unable to create gas cloud!");
        }
        else
            LogError("Unable to create point_hurt!");
    }
}

public Action ActivateGas(Handle timer, Handle entitypack)
{
    ResetPack(entitypack);

    int gascloud = ReadPackCell(entitypack);
    if (gascloud > 0 && IsValidEntity(gascloud))
    {
        int snd = GetRandomInt(0,sizeof(fartWav)-1);
        PrepareAndEmitSoundToAll(fartWav[snd], gascloud);
        AcceptEntityInput(gascloud, "TurnOn");
    }

    int pointHurt = ReadPackCell(entitypack);
    if (pointHurt > 0 && IsValidEntity(pointHurt))
    {
        int snd = GetRandomInt(0,sizeof(fartWav)-1);
        PrepareAndEmitSoundToAll(fartWav[snd], pointHurt);
        AcceptEntityInput(pointHurt, "TurnOn");
    }
}

public Action ClearGas(Handle timer, Handle entitypack)
{
    ResetPack(entitypack);

    int gascloud = ReadPackCell(entitypack);
    if (gascloud > 0 && IsValidEntity(gascloud))
        AcceptEntityInput(gascloud, "TurnOff");

    int pointHurt = ReadPackCell(entitypack);
    if (pointHurt > 0 && IsValidEntity(pointHurt))
        AcceptEntityInput(pointHurt, "TurnOff");
}

public Action KillGas(Handle timer, Handle entitypack)
{
    ResetPack(entitypack);

    int gascloud = ReadPackCell(entitypack);
    if (gascloud > 0 && IsValidEntity(gascloud))
        AcceptEntityInput(gascloud, "Kill");

    int pointHurt = ReadPackCell(entitypack);
    if (pointHurt > 0 && IsValidEntity(pointHurt))
        AcceptEntityInput(pointHurt, "Kill");

    /*
    int filter = ReadPackCell(entitypack);
    if (filter > 0 && IsValidEntity(filter))
        AcceptEntityInput(filter, "Kill");
    */

    CloseHandle(entitypack);
}

TheNipple(int client, int level)
{
    if (level > 0)
    {
        if (m_IsNipple[client])
        {
            PrepareAndEmitSoundToClient(client,errorWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "NippleAlreadyActive");
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            char upgradeName[64];
            GetUpgradeName(raceID, nippleID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (CanInvokeUpgrade(client, raceID, nippleID))
        {
            SetupSidewinder(client, level, true);

            //PrepareAndEmitSoundToAll(seekerReadyWav,client);
            HudMessage(client, "%t", "NippleHud");
            PrintHintText(client, "%t", "NippleActive");
            CreateTimer(5.0 * float(level), EndNipple,
                        GetClientUserId(client),
                        TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action EndNipple(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0)
    {
        bool isHunter = (GetRace(client) == raceID);
        if (isHunter && IsClientInGame(client) && IsPlayerAlive(client))
        {
            //PrepareAndEmitSoundToAll(seekerExpireWav,client);
            PrintHintText(client, "%t", "NippleExpired");
            ClearHud(client, "%t", "NippleHud");
        }

        int nipple_level=isHunter ? GetUpgradeLevel(client,raceID,nippleID) : 0;
        SetupSidewinder(client, nipple_level, false);
        CreateCooldown(client, raceID, nippleID);
    }
}

void SetupSidewinder(int client, int level, bool nipple)
{
    static const int sentryCritChance[] = { 5, 10, 20, 35, 50 };

    if (m_SidewinderAvailable)
    {
        int trackCritChance = 0;
        SidewinderClientFlags flags = CritSentryRockets;

        if (nipple)
        {
            trackCritChance = 100;

            switch (level)
            {
                case 1: flags |= TrackingSentryRockets | TrackingRockets;

                case 2: flags |= TrackingSentryRockets | TrackingRockets |
                                 TrackingEnergyBalls | TrackingPipes |
                                 TrackingFlares;

                case 3: flags |= TrackingSentryRockets | TrackingRockets |
                                 TrackingEnergyBalls | TrackingPipes |
                                 TrackingFlares | TrackingArrows |
                                 TrackingBolts;

                case 4:
                        flags |= TrackingAll;
            }
        }

        m_IsNipple[client] = nipple;
        SidewinderFlags(client, flags, false);
        SidewinderTrackChance(client, 0, trackCritChance);
        SidewinderSentryCritChance(client, sentryCritChance[level]);
    }
}

public Action OnSidewinderSeek(int client, int target, int projectile, bool critical)
{
    if (GetRace(client) == raceID)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            char nippleName[64];
            Format(nippleName, sizeof(nippleName), "%T", "Nipple", client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", nippleName);
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

void Snatch(int client)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        char upgradeName[64];
        GetUpgradeName(raceID, snatchID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, snatchID))
    {
        m_SnatchActive[client] = true;
        HudMessage(client, "%t", "SnatchHud");
        PrintHintText(client, "%t", "SnatchActive");
    }
}

void SnatchLevel(int victim, int index)
{
    int snatch_level=GetUpgradeLevel(index,raceID,snatchID);
    if (snatch_level > 0)
    {
        if (!GetImmunity(victim,Immunity_Ultimates) &&
            !GetImmunity(victim,Immunity_Theft) &&
            !IsInvulnerable(victim))
        {
            static const int chance[5] = { 0, 20, 30, 40, 50 };
            int level = GetLevel(index);
            int victim_race = GetRace(victim);
            int victim_level = GetLevel(victim);
            int amt = (victim_level > level) ? GetRandomInt(snatch_level*100,snatch_level*1000) : 0;
            if (victim_level > 1 && GetRandomInt(0,100) < chance[snatch_level])
            {
                int xp        = GetXP(index, raceID)       + amt;
                int victim_xp = GetXP(victim, victim_race) - amt;
                if (victim_xp > 0 && amt > 0)
                {
                    LogToGame("%N snatched %d experience from %N", index, amt, victim);

                    DisplayMessage(index, Display_Damage, "%t",
                                   "YouHaveSnatchedExperience", amt, victim);

                    DisplayMessage(victim, Display_Injury, "%t",
                                   "SnatchedYourExperience", index, amt);

                    ResetXP(index, raceID, xp);
                    ResetXP(victim, victim_race, victim_xp);
                    m_SnatchedXP[index][victim] += amt;
                }
                else
                {
                    LogToGame("%N snatched a level from %N", index, victim);

                    DisplayMessage(index, Display_Damage, "%t",
                                   "YouHaveSnatchedALevel", victim);

                    DisplayMessage(victim, Display_Injury, "%t",
                                   "SnatchedALevel", index);

                    ResetLevel(index, raceID, level+1);
                    ResetLevel(victim, victim_race, victim_level-1);
                    m_SnatchedLevels[index][victim]++;
                }
            }
            else if (level > 1)
            {
                int victim_xp   = GetXP(victim, victim_race) + amt;
                int xp          = GetXP(index, raceID)       - amt;
                if (xp > 0 && amt > 0)
                {
                    LogToGame("%N lost %d experience to %N", index, amt, victim);

                    DisplayMessage(index, Display_Damage, "%t",
                                   "SnatchMisfiredLostXP", amt, victim);

                    DisplayMessage(victim, Display_Injury, "%t",
                                   "SnatchMisfiredGainedXP", index, amt);

                    m_SnatchedXP[index][victim] += amt;
                    ResetXP(index, raceID, xp);
                    ResetXP(victim, victim_race, victim_xp);
                }
                else
                {
                    LogToGame("%N lost a level to %N", index, victim);

                    DisplayMessage(index, Display_Damage, "%t",
                                   "SnatchMisfiredLostLevel", victim);

                    DisplayMessage(victim, Display_Injury, "%t",
                                   "SnatchMisfiredGainedLevel", index);

                    m_SnatchedLevels[index][victim]++;
                    ResetLevel(index, raceID, level-1);
                    ResetLevel(victim, victim_race, victim_level+1);
                }
            }
            else
            {
                char upgradeName[64];
                GetUpgradeName(raceID, snatchID, upgradeName, sizeof(upgradeName), index);
                PrintToChat(index, "%t", "NoEffect", upgradeName, victim);
            }

            m_SnatchActive[index]=false;
            CreateCooldown(index, raceID, snatchID);
            ClearHud(index, "%t", "SnatchHud");
        }
    }
}

void Release(int client)
{
    for (int index = 0; index < MAXPLAYERS+1; index++)
    {
        if (IsValidClient(index))
        {
            int amt = m_SnatchedXP[client][index];
            if (amt != 0)
            {
                LogToGame("%N recovered %d experience from %N", index, amt, client);

                DisplayMessage(client, Display_Damage, "%t",
                                "ReleasedExperience", amt, index);

                DisplayMessage(index, Display_Injury, "%t",
                                "RecoveredExperience", client, amt);

                ResetXP(client, -1, GetXP(index) - amt);
                ResetXP(index, -1, GetXP(index) + amt);
                m_SnatchedXP[client][index] = 0;
            }

            amt = m_SnatchedLevels[client][index];
            if (amt != 0)
            {
                LogToGame("%N recovered %d level(s) from %N", index, amt, client);

                DisplayMessage(client, Display_Damage, "%t",
                                "ReleasedLevels", amt, index);

                DisplayMessage(index, Display_Injury, "%t",
                                "RecoveredLevels", amt, client);

                ResetLevel(index, -1, GetLevel(index) + amt);
                ResetLevel(client, -1, GetLevel(client) - amt);
                m_SnatchedLevels[client][index] = 0;
            }
        }
    }
}

void Recover(int index)
{
    for (int client = 0; client < MAXPLAYERS+1; client++)
    {
        int amt = m_SnatchedXP[client][index];
        if (amt != 0)
        {
            LogToGame("%N recovered %d experience from %N", index, amt, client);

            DisplayMessage(client, Display_Damage, "%t",
                            "ReleasedExperience", amt, index);

            DisplayMessage(index, Display_Injury, "%t",
                            "RecoveredExperience", client, amt);

            ResetXP(client, -1, GetXP(index) - amt);
            ResetXP(index, -1, GetXP(index) + amt);
            m_SnatchedXP[client][index] = 0;
        }

        amt = m_SnatchedLevels[client][index];
        if (amt != 0)
        {
            LogToGame("%N recovered %d level(s) from %N", index, amt, client);

            DisplayMessage(client, Display_Damage, "%t",
                            "ReleasedLevels", amt, index);

            DisplayMessage(index, Display_Injury, "%t",
                            "RecoveredLevels", amt, client);

            ResetLevel(index, -1, GetLevel(index) + amt);
            ResetLevel(client, -1, GetLevel(client) - amt);
            m_SnatchedLevels[client][index] = 0;
        }
    }
}