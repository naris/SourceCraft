/**
 * vim: set ai et ts=4 sw=4 :
 * File: SourceCraft.sp
 * Description: The main file for SourceCraft.
 * Author: Naris (Murray Wilson)
 * Credits: Anthony Iacono 
 *
 * $Id: SourceCraft.sp 1233 2008-05-15 15:38:07Z Naris $
 */

#pragma semicolon 1

// Pump up the memory!
#pragma dynamic 262144

#include <sourcemod>
#include <keyvalues>
#include <sdktools>
#include <sdkhooks>

#include <colors>
#include <gametype>
#include <lib/ResourceManager>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#include <tf2_player>
#include <tf2_meter>
#include <cstrike>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <lib/jetpack>
#define REQUIRE_PLUGIN

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <lib/trace>

// Define TRACK_DAMAGE to enable damage tracking
// Required for mods that don't report damage
// in player_hurt events such as hl2dm.
//#define TRACK_DAMAGE

// SourceCraft defines & enums
#include "sc/defines"
#include "sc/version"
#include "sc/faction"
#include "sc/immunity"
#include "sc/settings"
#include "sc/visibility"
#include "sc/round_state"
#include "sc/armor_flags"

#define SAVE_ENABLED                (g_bDatabaseConnected && g_bSaveXP && GetRaceCount() > 1)

#define DEFAULT_MAX_LEVELS          16

// Models
new const String:mdlPackage[][] = { "models/items/crystal_ball_pickup.mdl", "models/items/currencypack_small.mdl",
                                    "models/items/currencypack_medium.mdl", "models/items/currencypack_large.mdl",
                                    "models/items/tf_gift.mdl" };

// Sound Files
new const String:sndPickup[]  = "items/gift_pickup.wav";
new const String:sndPain[][]  = { "player/pl_pain5.wav", "player/pl_pain6.wav",
                                  "player/pl_pain7.wav", "player/pain.wav" };

new String:g_InfoURL[LONG_STRING_LENGTH]     = "http://http://sc.clanservers.com/sc/player/show/steamid/%s";
new String:g_InfoBaseURL[LONG_STRING_LENGTH] = "http://http://sc.clanservers.com/sc/";
new String:g_UpdateURL[LONG_STRING_LENGTH]   = "https://bitbucket.org/sourcecraft/sourcecraft/commits/all";
new String:g_WikiURL[LONG_STRING_LENGTH]     = "https://bitbucket.org/sourcecraft/sourcecraft/wiki/Home";
new String:g_BugURL[LONG_STRING_LENGTH]      = "https://bitbucket.org/sourcecraft/sourcecraft/issues";

new bool:g_bSourceCraftLoaded     = false;
new bool:g_bDatabaseConnected     = false;
new bool:g_bUseMoney              = false;
new bool:g_bUpdate                = false;
new bool:g_bCreate                = false;
new bool:g_bChargeForUpgrades     = false;
new bool:g_bSaveUpgrades          = true;
new bool:g_bSaveXP                = true;

new bool:g_bShowDisabledRaces     = false;
new bool:g_bShowUpgradeInfo       = true;
new g_fMinEnergyForPackage        = 50.0;
new g_fMinEnergyInPackage         = 25.0;
new g_iRaceMenuThreshold          = 16;

new g_iMaxCrystals                = 100;
new g_iMaxVespene                 = 5000;
new g_iMinPlayers                 = 4;
new g_iMinUltimate                = 8;

new g_iUpgradeCrystalsCost        = 25;
new g_iUpgradeVespeneCost         = 0;

new Float:g_fEnergyFactor         = 0.1;
new Float:g_fEnergyRate           = 1.0;

new Float:g_fMvMEnergyFactor      = 0.1;
new Float:g_fMvMEnergyRate        = 1.0;

new Float:g_fCrystalSellRate      = 5.0;
new Float:g_fCrystalBuyRate       = 1.0;

new g_iMaxDropXP                  = 500;
new g_iDropXPBias                 = -50;
new g_iMaxDropMoney               = 500;
new g_iDropMoneyBias              = -50;
new g_iMaxDropCrystals            = 50;
new g_iDropCrystalBias            = -5;
new g_iMaxDropPCrystals           = 500;
new g_iDropPCrystalsBias          = -10;
new g_iMaxPackages                = 50;
new Float:g_fPackageDuration      = 30.0;

new bool:g_IsInSpawn[MAXPLAYERS+1]     = { false, ... };
new bool:g_FirstSpawn[MAXPLAYERS + 1]  = { true,  ... };

// SourceCraft Includes
#include "sc/menuitemt"
#include "sc/weapons"
#include "sc/client"
#include "sc/invuln"
#include "sc/sounds"

#include "sc/engine/help"
#include "sc/engine/offsets"
#include "sc/engine/menumode"
#include "sc/engine/get_damage"
#include "sc/engine/playerinfo"
#include "sc/engine/factions"
#include "sc/engine/races"
#include "sc/engine/shopitems"
#include "sc/engine/config"
#include "sc/engine/info"
#include "sc/engine/cooldown"
#include "sc/engine/attribute"
#include "sc/engine/playertracking"
#include "sc/engine/playerproperties"
#include "sc/engine/db"
#include "sc/engine/display"
#include "sc/engine/natives"
#include "sc/engine/credits"
#include "sc/engine/xp"
#include "sc/engine/hooks"
#include "sc/engine/console"
#include "sc/engine/adminmenus"
#include "sc/engine/menus"
#include "sc/engine/changesettings"
#include "sc/engine/events"
#include "sc/engine/events_tf2"
#include "sc/engine/events_dod"
#include "sc/engine/events_cstrike"

public Plugin:myinfo= 
{
    name="SourceCraft",
    author = "-=|JFH|=-Naris",
    description="StarCraft/WarCraft for the Source engine.",
    version=SOURCECRAFT_VERSION,
    url="http://www.jigglysfunhouse.net/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    InitNatives();
    InitForwards();

    if(!InitRaceArray())
    {
        LogError("There was a failure creating the race vector.");
        return APLRes_Failure;
    }
    else
        return APLRes_Success;
}

public OnPluginStart()
{
    LogMessage("[SC] Plugin loading...\n-------------------------------------------------------------------------");
    PrintToServer("[SC] Plugin loading...\n-------------------------------------------------------------------------");

    // Load SourceMod translations
    LoadTranslations("common.phrases");

    // Load SourceCraft translations
    LoadTranslations("SourceCraft.phrases");
    LoadTranslations("sc.weapons.phrases");
    LoadTranslations("sc.common.phrases");
    LoadTranslations("sc.entity.phrases");
    LoadTranslations("sc.unit.phrases");
    LoadFactionTranslations();

    // Load War3Source translations for emulation
    LoadTranslations("w3s._common.phrases");

    GetGameType();

    InitCVars();
    InitHooks();
    InitHud();

    if(!InitOffsets())
        SetFailState("There was a failure finding the offsets required.");

    if (!ParseSettings())
        SetFailState("There was a failure parsing the configuration file.");

    g_bDatabaseConnected = InitDatabase();
    if (!g_bDatabaseConnected)
        LogError("Saving DISABLED!");
    
    if (!InitShopVector())
        SetFailState("There was a failure creating the shop vector.");

    if (!InitHelpVector())
        SetFailState("There was a failure creating the help vector.");

    if (!HookEvents())
        SetFailState("There was a failure initializing event hooks.");

    if (GameType == tf2)
    {
        if(!HookTFEvents())
            SetFailState("There was a failure initializing tf2 event hooks.");
    }
    else if (GameType == dod)
    {
        if(!HookDodEvents())
            SetFailState("There was a failure initializing dod event hooks.");
    }
    else if (GameTypeIsCS())
    {
        if(!HookCStrikeEvents())
            SetFailState("There was a failure initializing cstrike event hooks.");
    }

    if (!InitAdminMenu())
        SetFailState("There was a failure initializing admin menus.");

    InitHelpCommands();
    InitCookies();
    InitHint();

    PrintToServer("[SC] Plugin finished loading.\n-------------------------------------------------------------------------");
    LogMessage("[SC] Plugin finished loading.\n-------------------------------------------------------------------------");
}

public OnConfigsExecuted()
{
    TraceInto("SourceCraft", "OnConfigsExecuted");

    if (!g_bSourceCraftLoaded)
    {
        new res;
        Call_StartForward(g_OnSourceCraftReadyHandle);
        Call_Finish(res);
        g_bSourceCraftLoaded=true;

        CompleteConfigs();
    }

    TraceReturn();
}

public OnPluginEnd()
{
    ClearPlayerArray();
    ClearShopVector();
    ClearHelpVector();
    ClearRaceArray();
    ClearDatabase();
    CloseHud();

    LogMessage("[SC] Plugin shutdown.\n-------------------------------------------------------------------------");
    PrintToServer("[SC] Plugin shutdown.\n-------------------------------------------------------------------------");
}

public OnMapStart()
{
    TraceInto("SourceCraft", "OnMapStart");

    g_MapChanging = false;
    g_PackageCount = 0;
    SetupLevelUpEffect();

    for (new i = 0; i < sizeof(mdlPackage); i++)
        SetupModel(mdlPackage[i]);
    
    SetupDeniedSound();
    SetupButtonSound();
    SetupRechargeSound();

    SetupSound(sndPickup, true, DONT_DOWNLOAD, true, true);

    decl String:factionWav[NAME_STRING_LENGTH];
    for (new Faction:f = Generic; f < Faction; f++)
    {
        GetFactionLevelSound(f, factionWav, sizeof(factionWav));
        SetupSound(factionWav, true, ALWAYS_DOWNLOAD, true, true);

        GetFactionCrystalSound(f, factionWav, sizeof(factionWav));
        SetupSound(factionWav, true, ALWAYS_DOWNLOAD, true, true);

        GetFactionVespeneSound(f, factionWav, sizeof(factionWav));
        SetupSound(factionWav, true, ALWAYS_DOWNLOAD, true, true);

        GetFactionEnergySound(f, factionWav, sizeof(factionWav));
        SetupSound(factionWav, true, ALWAYS_DOWNLOAD, true, true);
    }

    for (new i = 0; i < sizeof(sndPain); i++)
        SetupSound(sndPain[i], false, DONT_DOWNLOAD, false, false);

    // If the database is not available
    if (!g_bDatabaseConnected)
    {
        // Retry connecting to it
        g_bDatabaseConnected = InitDatabase();
        if (!g_bDatabaseConnected)
            LogError("Saving Still DISABLED!");
    }

    TraceReturn();
}

public OnMapEnd()
{
    TraceInto("SourceCraft", "OnMapEnd");

    #if defined TRACK_DAMAGE
        ResetAllHealthTimers();
    #endif

    CleanupDamageEntity();
    ResetAllPropertyTimers();
    ResetAllHUDTimers();
    ResetAllCooldowns();
    ResetGameMode();

    CompleteConfigs();
    CloseDatabase();

    TraceReturn();
}

public OnClientPutInServer(client)
{
    SetTraceCategory("Connect");
    TraceInto("SourceCraft", "OnClientPutInServer", "client=%d:%L", \
              client, ValidClientIndex(client));

    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

    if (GameType == tf2)
        SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);

    ResetPlayer(client, true);
    RemoveAllAttributes(client);

    m_CloakTime[client] = 0.0;

    TraceReturn();
}

public Action:OnClientPreAdminCheck(client)
{
    SetTraceCategory("Connect");
    TraceInto("SourceCraft", "OnClientPreAdminCheck", "client=%d:%L", \
              client, ValidClientIndex(client));

    // Load players in OnClientPreAdminCheck() to ensure
    // they have been PutInServer and Authorized.

    if (client > 0)
    {
        new last_race = GetRaceCount()-1;
        if (last_race > 0)
        {
            if (IsFakeClient(client))
            {
                // Assign bots a random race and level
                new race;
                new required;
                new Handle:raceHandle;
                new overall = GetRandomInt(1,200);

                do
                {
                    race = GetRandomInt(1,last_race);
                    raceHandle = GetRaceHandle(race);
                    required = GetRaceRequiredLevel(raceHandle);
                } while (required < 0 || required > overall);

                SetOverallLevel(client,overall);
                SetRace(client,race);

                new max = GetRaceMaxLevel(raceHandle);
                if (required > 0)
                {
                    max -= required;
                    if (max < 1)
                        max = 1;
                }

                if (max > overall)
                    max = overall;

                new level = GetRandomInt(1, max);
                SetLevel(client, race, level, false);

                new count = GetUpgradeCount(raceHandle)-1;
                if (count >= 0 )
                {
                    while (level > 0)
                    {
                        new upgrade = GetRandomInt(0, count);
                        new ulevel = GetUpgradeLevel(client, race, upgrade);
                        new maxLevel = GetUpgradeMaxLevel(raceHandle,upgrade);
                        if (ulevel < maxLevel)
                        {
                            SetUpgradeLevel(client, race, upgrade, ++ulevel);
                        }
                        level--;
                    }
                }
            }
            else
            {
                // Default race to human for new players.
                if (GetRace(client) < 0)
                {
                    new race = FindRace("human");
                    SetRace(client, (race >= 0) ? race : 0);
                }

                if (g_bSaveXP && GetRaceCount() > 1)
                {
                    if (g_bDatabaseConnected)
                        LoadPlayerData(client);
                    else
                    {
                        LogError("Database not available to load %N's levels!", client);
                        PrintHintText(client, "%t", "NoDatabaseForLoad");
                    }                        
                }
            }
        }
    }

    new res;
    Call_StartForward(g_OnPlayerAuthedHandle);
    Call_PushCell(client);
    Call_Finish(res);

    TraceReturn();
    return Plugin_Continue;
}

public OnClientDisconnect(client)
{
    SetTraceCategory("Connect");
    TraceInto("SourceCraft", "OnClientDisconnect", "client=%d:%L", \
              client, ValidClientIndex(client));

    g_IsInSpawn[client]  = false;
    g_FirstSpawn[client] = true;

    // Clear HUD Message
    m_HudMessage[client][0] = '\0';

    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);

    if (GameType == tf2)
        SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);

    KillHUDTimer(client);
    KillPropertyTimer(client);
    CooldownDisconnect(client);

    #if defined TRACK_DAMAGE
        KillHealthTimer(client);
    #endif

    if (!IsFakeClient(client))
    {
        //if (!GetDatabaseSaved(client) && 
        if (g_bSaveXP && GetRaceCount() > 1 &&
            GetPlayerStatus(client) != PlayerDisabled &&
            GetDatabaseLoaded(client) >= DataOK)
        {
            new race = GetRace(client);
            if (race <= 0 || GetRaceLoaded(client, race) >= DataOK)
            {
                Trace("Saving Player Data, g_bDatabaseConnected=%d",g_bDatabaseConnected);
                if (g_bDatabaseConnected)
                    SavePlayerData(client);
                else
                    LogError("Database not available to save %d's levels", client);
            }
        }
    }

    TraceReturn();
}

#if defined _TRACE
    public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
    {
        SetTraceCategory("Connect");
        TraceInto("SourceCraft", "OnClientConnect", "client=%d:%L", \
                  client, ValidClientIndex(client));

        TraceReturn();
        return true;
    }

    public OnClientConnected(client)
    {
        SetTraceCategory("Connect");
        TraceInto("SourceCraft", "OnClientConnected", "client=%d:%L", \
                  client, ValidClientIndex(client));

        TraceReturn();
    }

    public OnClientAuthorized(client, const String:auth[])
    {
        SetTraceCategory("Connect");
        TraceInto("SourceCraft", "OnClientAuthorized", "client=%d:%L Authorized as %s", \
                  client, ValidClientIndex(client), auth);

        TraceReturn();
    }

    public OnClientPostAdminCheck(client)
    {
        SetTraceCategory("Connect");
        TraceInto("SourceCraft", "OnClientPostAdminCheck", "client=%d:%L", \
                  client, ValidClientIndex(client));

        TraceReturn();
    }

    public OnClientDisconnect_Post(client)
    {
        SetTraceCategory("Connect");
        TraceInto("SourceCraft", "OnClientDisconnect_Post", "client=%d", \
                  client);

        TraceReturn();
    }
#endif
