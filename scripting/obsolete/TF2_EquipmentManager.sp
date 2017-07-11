// vim: set ai et ts=4 sw=4 :
// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <tf2>
#include <tf2_stocks>
//#include <tf2_ext>
#include <clientprefs>
#include <entlimit>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME              "[TF2] Equipment Manager"
#define PLUGIN_AUTHOR            "Damizean"
#define PLUGIN_VERSION           "1.1.7"
#define PLUGIN_CONTACT           "elgigantedeyeso@gmail.com"
#define CVAR_FLAGS               FCVAR_PLUGIN|FCVAR_NOTIFY

//#define DEBUG                    // Uncomment this for debug.information
//#define NOTIFY                   // Uncomment this to log items loaded
//#define DEBUG_EQUIP              // Uncomment this for debug.information when equipping items
#define DELAY_PRECACHE             // Uncomment this to enable modified code for delayed precaching, etc.

// ---- Items management -----------------------------------------------------------
#define MAX_ITEMS                256
#define MAX_SLOTS                3
#define MAX_LENGTH               256

// ---- Wearables flags ------------------------------------------------------------
#define PLAYER_ADMIN             (1 << 0)        // Player is admin.
#define PLAYER_OVERRIDE          (1 << 1)        // Player is overriding the restrictions of the items.
#define PLAYER_LOCK              (1 << 2)        // Player has it's equipment locked

#define FLAG_ADMIN_ONLY          (1 << 0)        // Only admins can use this item.
#define FLAG_USER_DEFAULT        (1 << 1)        // This is the forced default for users.
#define FLAG_ADMIN_DEFAULT       (1 << 2)        // This is the forced default for admins.
#define FLAG_HIDDEN              (1 << 3)        // Hidden from list
#define FLAG_INVISIBLE             (1 << 4)      // Invisible! INVISIBLE!
#define FLAG_HIDE_SCOUT_HAT        (1 << 5)
#define FLAG_HIDE_SCOUT_HEADPHONES (1 << 6)
#define FLAG_HIDE_HEAVY_HANDS      (1 << 7)
#define FLAG_HIDE_ENGINEER_HELMET  (1 << 8)
#define FLAG_HIDE_SNIPER_QUIVER    (1 << 9)
#define FLAG_HIDE_SNIPER_HAT       (1 << 10)
#define FLAG_HIDE_SOLDIER_ROCKET   (1 << 11)
#define FLAG_HIDE_SOLDIER_HELMET   (1 << 12)
#define FLAG_SHOW_SOLDIER_MEDAL    (1 << 13)

#define CLASS_SCOUT              (1 << 0)
#define CLASS_SNIPER             (1 << 1)
#define CLASS_SOLDIER            (1 << 2)
#define CLASS_DEMOMAN            (1 << 3)
#define CLASS_MEDIC              (1 << 4)
#define CLASS_HEAVY              (1 << 5)
#define CLASS_PYRO               (1 << 6)
#define CLASS_SPY                (1 << 7)
#define CLASS_ENGINEER           (1 << 8)
#define CLASS_ALL                0b111111111

#define TEAM_RED                 (1 << 0)
#define TEAM_BLU                 (1 << 1)

// ---- Engine flags ---------------------------------------------------------------
#define EF_BONEMERGE            (1 << 0)
#define EF_BRIGHTLIGHT          (1 << 1)
#define EF_DIMLIGHT             (1 << 2)
#define EF_NOINTERP             (1 << 3)
#define EF_NOSHADOW             (1 << 4)
#define EF_NODRAW               (1 << 5)
#define EF_NORECEIVESHADOW      (1 << 6)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_ITEM_BLINK           (1 << 8)
#define EF_PARENT_ANIMATES      (1 << 9)

// ---- Game bodygroups ------------------------------------------------------------
#define BODYGROUP_SCOUT_HAT        (1 << 0)
#define BODYGROUP_SCOUT_HEADPHONES (1 << 1)
#define BODYGROUP_HEAVY_HANDS      (1 << 0)
#define BODYGROUP_ENGINEER_HELMET  (1 << 0)
#define BODYGROUP_SNIPER_QUIVER    (1 << 0)
#define BODYGROUP_SNIPER_HAT       (1 << 1)
#define BODYGROUP_SOLDIER_ROCKET   (1 << 0)
#define BODYGROUP_SOLDIER_HELMET   (1 << 1)
#define BODYGROUP_SOLDIER_MEDAL    (1 << 2)

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// ---- Player variables -----------------------------------------------------------
new g_iPlayerItem[MAXPLAYERS+1][MAX_SLOTS];
new g_iPlayerEntity[MAXPLAYERS+1][MAX_SLOTS];
new g_iPlayerFlags[MAXPLAYERS+1];
new g_iPlayerBGroups[MAXPLAYERS+1];

// ---- Item variables -------------------------------------------------------------
//new g_iSlotsCount;
//new String:g_strSlots[MAX_SLOTS][MAX_LENGTH];            // In a future, perhaps?

new g_iItemCount;
new String:g_strItemName[MAX_ITEMS][MAX_LENGTH];
new String:g_strItemModel[MAX_ITEMS][MAX_LENGTH];
#if defined DELAY_PRECACHE
new Handle:g_hItemDecals[MAX_ITEMS];
new Handle:g_hItemModels[MAX_ITEMS];
new bool:g_bItemPrecached[MAX_ITEMS];
new g_iUsedItemCount;
#endif
new g_iItemFlags[MAX_ITEMS];
new g_iItemClasses[MAX_ITEMS];
new g_iItemSlot[MAX_ITEMS];
new g_iItemTeams[MAX_ITEMS];
new g_iItemIndex[MAX_ITEMS];

// --- SDK variables ---------------------------------------------------------------
new bool:g_bSdkStarted = false;
new Handle:g_hSdkEquipWearable;
new Handle:g_hSdkRemoveWearable;

// ---- Cvars ----------------------------------------------------------------------
new Handle:g_hCvarVersion              = INVALID_HANDLE;
new Handle:g_hCvarAdminOnly            = INVALID_HANDLE;
new Handle:g_hCvarAdminFlags           = INVALID_HANDLE;
new Handle:g_hCvarAdminOverride        = INVALID_HANDLE;
new Handle:g_hCvarAnnounce             = INVALID_HANDLE;
new Handle:g_hCvarAnnouncePlugin       = INVALID_HANDLE;
new Handle:g_hCvarForceDefaultOnUsers  = INVALID_HANDLE;
new Handle:g_hCvarForceDefaultOnAdmins = INVALID_HANDLE;
new Handle:g_hCvarDelayOnSpawn         = INVALID_HANDLE;
new Handle:g_hCvarBlockTriggers        = INVALID_HANDLE;
#if defined DELAY_PRECACHE
new Handle:g_hCvarPrecacheLimit        = INVALID_HANDLE;
new Handle:g_hCvarItemLimit            = INVALID_HANDLE;
#endif

// ---- Others ---------------------------------------------------------------------
new Handle:g_hCookies[10][MAX_SLOTS];

new bool:g_bAdminOnly      = false;
new bool:g_bAdminOverride  = false;
new bool:g_bAnnounce       = false;
new bool:g_bAnnouncePlugin = false;
new bool:g_bForceUsers     = false;
new bool:g_bForceAdmins    = false;
new bool:g_bBlockTriggers  = false;
new Float:g_fSpawnDelay    = 0.0;
new String:g_strAdminFlags[32];

#if defined DELAY_PRECACHE
new g_iPrecacheLimit       = -1;
new g_iItemLimit           = -1;
#endif

new Handle:g_hMenuMain   = INVALID_HANDLE;
new Handle:g_hMenuEquip  = INVALID_HANDLE;
new Handle:g_hMenuRemove = INVALID_HANDLE;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ BASIC PLUGIN MANAGEMENT ]========================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
// At plugin start, create and hook all the proper events to manage the
// wearable items.
// ------------------------------------------------------------------------
public OnPluginStart()
{    
    // Plugin is TF2 only, so make sure it's ran on TF
    decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is TF2 only.");
    
    // Create plugin cvars
    g_hCvarVersion              = CreateConVar("tf_equipment_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
    g_hCvarAdminFlags           = CreateConVar("tf_equipment_admin_flags",     "b",   "Only users with one of these flags are considered administrators.", CVAR_FLAGS);
    g_hCvarAdminOnly            = CreateConVar("tf_equipment_admin",           "0",   "Only administrators can use the equipment.",                        CVAR_FLAGS);
    g_hCvarAdminOverride        = CreateConVar("tf_equipment_admin_override",  "0",   "Administrators can override the equipment restrictions.",           CVAR_FLAGS);
    g_hCvarAnnounce             = CreateConVar("tf_equipment_announce",        "1",   "Announces usage and tips about equipable items.",                   CVAR_FLAGS);
    g_hCvarAnnouncePlugin       = CreateConVar("tf_equipment_announce_plugin", "1",   "Announces information of the plugin when joining.",                 CVAR_FLAGS);
    g_hCvarForceDefaultOnUsers  = CreateConVar("tf_equipment_force_users",     "0",   "Forces the default equipment for common users.",                    CVAR_FLAGS);
    g_hCvarForceDefaultOnAdmins = CreateConVar("tf_equipment_force_admins",    "0",   "Forces the default equipment for admin users.",                     CVAR_FLAGS);
    g_hCvarDelayOnSpawn         = CreateConVar("tf_equipment_delayonspawn",    "0.3", "Amount of time to wait to re-equip items after spawn.",             CVAR_FLAGS);
    g_hCvarBlockTriggers        = CreateConVar("tf_equipment_blocktriggers",   "1",   "Blocks the triggers so they won't spam on the chat.",               CVAR_FLAGS);

    #if defined DELAY_PRECACHE
    g_hCvarPrecacheLimit        = CreateConVar("tf_equipment_precache",        "0",   "Number of items to precache on map start (-1=unlimited).",          CVAR_FLAGS);
    g_hCvarItemLimit            = CreateConVar("tf_equipment_itemlimit",       "100", "Maximum number of different items to allow (-1=unlimited).",        CVAR_FLAGS);
    #endif
    
    // Create cookies
    g_hCookies[_:TFClass_DemoMan][0]  = RegClientCookie("tf_equipment_demoman_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_DemoMan][1]  = RegClientCookie("tf_equipment_demoman_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_DemoMan][2]  = RegClientCookie("tf_equipment_demoman_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Engineer][0] = RegClientCookie("tf_equipment_engineer_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Engineer][1] = RegClientCookie("tf_equipment_engineer_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Engineer][2] = RegClientCookie("tf_equipment_engineer_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Heavy][0]    = RegClientCookie("tf_equipment_heavy_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Heavy][1]    = RegClientCookie("tf_equipment_heavy_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Heavy][2]    = RegClientCookie("tf_equipment_heavy_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Medic][0]    = RegClientCookie("tf_equipment_medic_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Medic][1]    = RegClientCookie("tf_equipment_medic_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Medic][2]    = RegClientCookie("tf_equipment_medic_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Pyro][0]     = RegClientCookie("tf_equipment_pyro_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Pyro][1]     = RegClientCookie("tf_equipment_pyro_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Pyro][2]     = RegClientCookie("tf_equipment_pyro_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Scout][0]    = RegClientCookie("tf_equipment_scout_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Scout][1]    = RegClientCookie("tf_equipment_scout_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Scout][2]    = RegClientCookie("tf_equipment_scout_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Sniper][0]   = RegClientCookie("tf_equipment_sniper_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Sniper][1]   = RegClientCookie("tf_equipment_sniper_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Sniper][2]   = RegClientCookie("tf_equipment_sniper_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Soldier][0]  = RegClientCookie("tf_equipment_soldier_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Soldier][1]  = RegClientCookie("tf_equipment_soldier_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Soldier][2]  = RegClientCookie("tf_equipment_soldier_2", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Spy][0]      = RegClientCookie("tf_equipment_spy_0", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Spy][1]      = RegClientCookie("tf_equipment_spy_1", "", CookieAccess_Public);
    g_hCookies[_:TFClass_Spy][2]      = RegClientCookie("tf_equipment_spy_2", "", CookieAccess_Public);
    
    // Startup extended stocks
    TF2_SdkStartup();
    
    // Register console commands
    RegConsoleCmd("tf_equipment",        Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("equipment",           Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("equip",               Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("em",                  Cmd_Menu, "Shows the equipment manager menu");
    RegConsoleCmd("hats",                Cmd_Menu, "Shows the equipment manager menu");
    RegAdminCmd("tf_equipment_equip",    Cmd_EquipItem,         ADMFLAG_CHEATS, "Forces to equip an item onto a client.");
    RegAdminCmd("tf_equipment_remove",   Cmd_RemoveItem,        ADMFLAG_CHEATS, "Forces to remove an item on the client.");
    RegAdminCmd("tf_equipment_lock",     Cmd_LockEquipment,     ADMFLAG_CHEATS, "Locks/unlocks the client's equipment so it can't be changed.");
    RegAdminCmd("tf_equipment_override", Cmd_OverrideEquipment, ADMFLAG_CHEATS, "Enables restriction overriding for the client.");
    RegAdminCmd("tf_equipment_reload",   Cmd_Reload,            ADMFLAG_CHEATS, "Reparses the items file and rebuilds the equipment list.");
    RegConsoleCmd("say", Cmd_BlockTriggers);
    RegConsoleCmd("say_team", Cmd_BlockTriggers);
    
    // Hook the proper events and cvars
    HookEvent("post_inventory_application", Event_EquipItem,  EventHookMode_Post);
    HookConVarChange(g_hCvarAdminFlags,           Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAdminOnly,            Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAdminOverride,        Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAnnounce,             Cvar_UpdateCfg);
    HookConVarChange(g_hCvarAnnouncePlugin,       Cvar_UpdateCfg);
    HookConVarChange(g_hCvarForceDefaultOnUsers,  Cvar_UpdateCfg);
    HookConVarChange(g_hCvarForceDefaultOnAdmins, Cvar_UpdateCfg);
    HookConVarChange(g_hCvarDelayOnSpawn,         Cvar_UpdateCfg);

    #if defined DELAY_PRECACHE
    HookConVarChange(g_hCvarPrecacheLimit,        Cvar_UpdateCfg);
    HookConVarChange(g_hCvarItemLimit,            Cvar_UpdateCfg);
    #endif
    
    // Load translations for this plugin
    LoadTranslations("common.phrases");
    LoadTranslations("TF2_EquipmentManager");
    
    // Execute configs.
    AutoExecConfig(true, "TF2_EquipmentManager");
    
    // Create announcement timer.
    CreateTimer(900.0, Timer_Announce, _, TIMER_REPEAT);
}

// ------------------------------------------------------------------------
// OnPluginEnd()
// ------------------------------------------------------------------------
public OnPluginEnd()
{
    // Destroy all entities for everyone, if possible.
    for (new iClient=1; iClient<=MaxClients; iClient++)
    {
        for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++)
            Item_Remove(iClient, iSlot, false);
    }
}

// ------------------------------------------------------------------------
// OnConfigsExecuted()
// ------------------------------------------------------------------------
public OnConfigsExecuted()
{
    // Determine if the version of the cfg is the correct one
    new String:strVersion[16]; GetConVarString(g_hCvarVersion, strVersion, sizeof(strVersion));
    if (StrEqual(strVersion, PLUGIN_VERSION) == false)
    {
        LogMessage("WARNING: Your config file for \"%s\" seems to be out-dated! This may lead to conflicts with \
        the plugin and non-working configs. Fix this by deleting your current config and restart your \
        server. It'll generate a new config with the default Cfg.", PLUGIN_NAME);
    }
    
    // Force Cfg update
    Cvar_UpdateCfg(INVALID_HANDLE, "", "");
}

// ------------------------------------------------------------------------
// UpdateCfg()
// ------------------------------------------------------------------------
public Cvar_UpdateCfg(Handle:hHandle, String:strOldVal[], String:strNewVal[])
{
    g_bAdminOnly      = GetConVarBool(g_hCvarAdminOnly);
    g_bAdminOverride  = GetConVarBool(g_hCvarAdminOverride);
    g_bAnnounce       = GetConVarBool(g_hCvarAnnounce);
    g_bAnnouncePlugin = GetConVarBool(g_hCvarAnnouncePlugin);
    g_bForceUsers     = GetConVarBool(g_hCvarForceDefaultOnUsers);
    g_bForceAdmins    = GetConVarBool(g_hCvarForceDefaultOnAdmins);
    g_fSpawnDelay     = GetConVarFloat(g_hCvarDelayOnSpawn);
    g_bBlockTriggers  = GetConVarBool(g_hCvarBlockTriggers);
    #if defined DELAY_PRECACHE
    g_iPrecacheLimit  = GetConVarBool(g_hCvarPrecacheLimit);
    g_iItemLimit      = GetConVarInt(g_hCvarItemLimit);
    #endif
    GetConVarString(g_hCvarAdminFlags, g_strAdminFlags, sizeof(g_strAdminFlags));
}

// ------------------------------------------------------------------------
// OnMapStart()
// ------------------------------------------------------------------------
// At map start, make sure to reset all the values for all the clients
// to the default. Also, reparse the items list and rebuild the
// basic menus.
// ------------------------------------------------------------------------
public OnMapStart()
{
    // Reset player's slots
    for (new iClient=1; iClient<=MaxClients; iClient++)
    {
        g_iPlayerFlags[iClient] = 0;
        
        for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++)
        {
            g_iPlayerItem[iClient][iSlot] = -1;
            g_iPlayerEntity[iClient][iSlot] = -1;
        }
    }
    
    // Reparse and re-build the menus
    Item_ParseList();
    g_hMenuMain   = Menu_BuildMain();
    g_hMenuEquip  = Menu_BuildSlots("EquipItem");
    g_hMenuRemove = Menu_BuildSlots("RemoveSlot");
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
// At map end, destroy all the built menus.
// ------------------------------------------------------------------------
public OnMapEnd()
{
    // Destroy menus
    if (g_hMenuMain   != INVALID_HANDLE) { CloseHandle(g_hMenuMain);   g_hMenuMain   = INVALID_HANDLE; }
    if (g_hMenuEquip  != INVALID_HANDLE) { CloseHandle(g_hMenuEquip);  g_hMenuEquip  = INVALID_HANDLE; }
    if (g_hMenuRemove != INVALID_HANDLE) { CloseHandle(g_hMenuRemove); g_hMenuRemove = INVALID_HANDLE; }
}

// ------------------------------------------------------------------------
// OnClientPutInServer()
// ------------------------------------------------------------------------
// When a client is put in server, greet the player and show off information
// about the plugin.
// ------------------------------------------------------------------------
public OnClientPutInServer(iClient)
{
    if (g_bAnnouncePlugin)
    {
        CreateTimer(30.0, Timer_Welcome, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// ------------------------------------------------------------------------
// OnClientPostAdminCheck()
// ------------------------------------------------------------------------
// Identify the client that just connected, checking if at least one of the
// flags listed in the cvar.
// ------------------------------------------------------------------------
public OnClientPostAdminCheck(iClient)
{
    // Retrieve needed flags and determine if the player is an admin.
    new ibFlags = ReadFlagString(g_strAdminFlags);
    
    // Test and setup flag if so.
    if (GetUserFlagBits(iClient) & ibFlags)      g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
    if (GetUserFlagBits(iClient) & ADMFLAG_ROOT) g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
}

// ------------------------------------------------------------------------
// Event_EquipItem()
// ------------------------------------------------------------------------
// On the player spawn (or any other event that requires re-equipment) we
// requip the items the player had selected. If none are found, we also check
// if we should force one upon the player.
// ------------------------------------------------------------------------
public Event_EquipItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    CreateTimer(g_fSpawnDelay, Timer_EquipItem, GetClientOfUserId(GetEventInt(hEvent, "userid")), TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_EquipItem(Handle:hTimer, any:iClient)
{
    if (!IsValidClient(iClient)) return Plugin_Handled;
    if (!IsPlayerAlive(iClient)) return Plugin_Handled;
    
    // Retrieve current player bodygroups status.
    g_iPlayerBGroups[iClient] = GetEntProp(iClient, Prop_Send, "m_nBody");
    
    // Iterate through each slot
    for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++)
    {
        // Retrieve the proper cookie value
        g_iPlayerItem[iClient][iSlot] = Item_RetrieveSlotCookie(iClient, iSlot);
        
        // Determine if the hats are still valid for the
        // client.
        if (!Item_IsWearable(iClient, g_iPlayerItem[iClient][iSlot]))
        {
            Item_Remove(iClient, iSlot);
            g_iPlayerItem[iClient][iSlot] = Item_FindDefaultItem(iClient, iSlot);
        }
        
        // Equip the player with the selected item.
        #if defined DELAY_PRECACHE
        if (Item_Equip(iClient, g_iPlayerItem[iClient][iSlot]))
        {
            #if defined DEBUG_EQUIP
            new iItem = g_iPlayerItem[iClient][iSlot];
            if (IsValidClient(iClient) && Item_IsWearable(iClient, iItem))
                LogMessage("%N Equipped Hat %s", iClient, g_strItemName[iItem]);
            #endif
        }
        else
        {
            #if defined DEBUG_EQUIP
            new iItem = g_iPlayerItem[iClient][iSlot];
            if (IsValidClient(iClient) && Item_IsWearable(iClient, iItem))
                LogMessage("%N Denied Hat %s", iClient, g_strItemName[iItem]);
            #endif
        }
        #else
        Item_Equip(iClient, g_iPlayerItem[iClient][iSlot]);
        #endif
    }    
    
    return Plugin_Handled;
}
/*
// ------------------------------------------------------------------------
// Event_RemoveItem()
// ------------------------------------------------------------------------
// On player's death or change class, we need to remove the item equipped,
// otherwise there would appear some errors where the items would take over  
// weapons slots.
// ------------------------------------------------------------------------
public Event_RemoveItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++) Item_Remove(iClient, iSlot);
}

// ------------------------------------------------------------------------
// Hook_Sound()
// ------------------------------------------------------------------------
// When using a resupply, the game automatically removes all the items
// and re-equps them to the player. However, it will also remove the items
// equipped, so we need to re-equip them. We detect the resupply through the
// specific sound it plays when used.
// ------------------------------------------------------------------------
public Action:Hook_Sound(iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity)
{
    if (!StrEqual(strSample, "items/regenerate.wav", true)) return Plugin_Continue;
    for (new iSlot=0; iSlot<MAX_SLOTS; iSlot++)
    {    
        // Retrieve new bodygroups
        g_iPlayerBGroups[iEntity] = GetEntProp(iEntity, Prop_Send, "m_nBody");
        
        // Re-equip everything.
        if (Item_IsValidWearable(g_iPlayerEntity[iEntity][iSlot])) RemoveEdict(g_iPlayerEntity[iEntity][iSlot]);
        Item_Equip(iEntity, g_iPlayerItem[iEntity][iSlot]); 
    }
    return Plugin_Continue;
}*/  

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
// When the client disconnects, remove it's equipped items and reset all
// the flags.
// ------------------------------------------------------------------------
public OnClientDisconnect(iClient)
{
    for (new i=0; i<MAX_SLOTS; i++) Item_Remove(iClient, i, false);
    g_iPlayerFlags[iClient] = 0;
}

// ------------------------------------------------------------------------
// Item_Equip
// ------------------------------------------------------------------------
// Equip the desired item onto a client.
// ------------------------------------------------------------------------
#if defined DELAY_PRECACHE
bool:Item_Equip(iClient, iItem)
#else
Item_Equip(iClient, iItem)
#endif
{
    // Assert if the player is alive.
    #if defined DELAY_PRECACHE
    if (!IsValidClient(iClient)) return false;
    if (!Item_IsWearable(iClient, iItem)) return false;
    #else
    if (!IsValidClient(iClient)) return;
    if (!Item_IsWearable(iClient, iItem)) return;
    #endif
    
    // Retrieve the information of the item and the current item
    new iSlot          = g_iItemSlot[iItem];
    new iCurrentItem   = g_iPlayerItem[iClient][iSlot];
    new CurrentEntity = g_iPlayerEntity[iClient][iSlot];
    
    #if defined DEBUG_EQUIP
    LogMessage("%N Equipping Hat %s", iClient, g_strItemName[iItem]);
    #endif

    #if defined DELAY_PRECACHE
    // Ensure the item has been precached and is visible
    if (!g_bItemPrecached[iItem] && !(g_iItemFlags[iItem] & FLAG_INVISIBLE))
    {
        // Make sure the item can be precached
        if (g_iUsedItemCount >= g_iItemLimit || g_iUsedItemCount >= MAX_ITEMS)
            return false;
        else
        {
            if (Item_Precache(iItem))
            {
                g_iUsedItemCount++;
                g_bItemPrecached[iItem] = true;
            }
            else
            {
                PrintToServer("Error: Unable to precache models and/or decals for item %s!", g_strItemName[iItem]);
                LogError("Error: Unable to precache models and/or decals for item %s!", g_strItemName[iItem]);
                return false;
            }
        }
    }
    #endif

    // Change the item index now
    g_iPlayerItem[iClient][iSlot] = iItem;
    
    // Determine if the current entity is valid. If not, create a new
    // iEntity to use as hat. If it was valid, just change the model.
    if (!TF2_IsEntityWearable(CurrentEntity))
    {   
        // Of course, only create the entity 
        if (IsPlayerAlive(iClient)) 
        {
            #if defined DELAY_PRECACHE
            if (IsEntLimitReached(.message="Limiting Items"))
                return false;
            #endif

            new iEntity = TF2_SpawnWearable(iClient, g_iItemIndex[iItem]);
            TF2_EquipWearable(iClient, iEntity);
            
            #if defined DELAY_PRECACHE
            if (g_iItemFlags[iItem] & FLAG_INVISIBLE) SetEntityRenderMode(iEntity, RENDER_NONE);
            #else
            if (g_iItemFlags[g_iItemCount] & FLAG_INVISIBLE) SetEntityRenderMode(iEntity, RENDER_NONE);
            #endif
            else                                             SetEntityModel(iEntity, g_strItemModel[iItem]);
            SetEntProp(iClient, Prop_Send, "m_nBody", g_iPlayerBGroups[iClient] | Item_DetermineBodyGroups(iClient));
            
            g_iPlayerEntity[iClient][iSlot] = iEntity;
        }
    }
    else if (iItem != iCurrentItem)
    {
        SetEntProp(CurrentEntity, Prop_Send, "m_iItemDefinitionIndex", g_iItemIndex[iItem]);
        #if defined DELAY_PRECACHE
        if (g_iItemFlags[iItem] & FLAG_INVISIBLE)
        #else
        if (g_iItemFlags[g_iItemCount] & FLAG_INVISIBLE)
        #endif
        {
            SetEntityRenderMode(CurrentEntity, RENDER_NONE);
        }
        else
        {
            SetEntityRenderMode(CurrentEntity, RENDER_NORMAL);
            SetEntityModel(CurrentEntity, g_strItemModel[iItem]);
        }
        SetEntProp(iClient, Prop_Send, "m_nBody", g_iPlayerBGroups[iClient] | Item_DetermineBodyGroups(iClient));
    }
    #if defined DELAY_PRECACHE
    return true;
    #endif
}

// ------------------------------------------------------------------------
// Item_Remove
// ------------------------------------------------------------------------
// Remove the item equipped at the selected slot.
// ------------------------------------------------------------------------
Item_Remove(iClient, iSlot, bool:bCheck = true)
{
    // Assert if the player is alive.
    if (bCheck == true && !IsValidClient(iClient)) return;
    if (g_iPlayerItem[iClient][iSlot] == -1) return;
    
    if (TF2_IsEntityWearable(g_iPlayerEntity[iClient][iSlot]))
    {
        TF2_RemoveWearable(iClient, g_iPlayerEntity[iClient][iSlot]);
        SetEntProp(iClient, Prop_Send, "m_nBody", g_iPlayerBGroups[iClient] | Item_DetermineBodyGroups(iClient));
    }
    
    g_iPlayerItem[iClient][iSlot] = -1;
    g_iPlayerEntity[iClient][iSlot] = -1;
}

// ------------------------------------------------------------------------
// Item_ParseList()
// ------------------------------------------------------------------------
// Parse the items list and precache all the needed models through the
// dependencies file.
// ------------------------------------------------------------------------
Item_ParseList()
{
    // Parse the objects list key values text to acquire all the possible
    // wearable items.
    new Handle:kvItemList = CreateKeyValues("TF2_EquipmentManager");
    new Handle:hStream = INVALID_HANDLE;
    new String:strLocation[256];
    new String:strDependencies[256];
    new String:strLine[256];
    
    #if defined DELAY_PRECACHE
    // Clear precache item & model lists and flags.
    for (new i = 0; i < MAX_ITEMS; i++)
    {
        g_bItemPrecached[i] = false;

        if (g_hItemDecals[i] != INVALID_HANDLE)
            ClearArray(g_hItemDecals[i]);

        if (g_hItemModels[i] != INVALID_HANDLE)
            ClearArray(g_hItemModels[i]);
    }

    g_iUsedItemCount = 0;
    #endif

    // Load the key files.
    BuildPath(Path_SM, strLocation, 256, "configs/TF2_ItemList.cfg");
    FileToKeyValues(kvItemList, strLocation);
    
    // Check if the parsed values are correct
    if (!KvGotoFirstSubKey(kvItemList)) { SetFailState("Error, can't read file containing the item list : %s", strLocation); return; }
    g_iItemCount = 0;

    #if defined DEBUG
    LogMessage("Parsing item list {");
    #endif
    
    // Iterate through all keys.
    do
    {
        // Retrieve section name, wich is pretty much the name of the wearable. Also, parse the model.
        KvGetSectionName(kvItemList,       g_strItemName[g_iItemCount],  MAX_LENGTH);
        KvGetString(kvItemList, "model",   g_strItemModel[g_iItemCount], MAX_LENGTH);
        KvGetString(kvItemList, "index",   strLine, sizeof(strLine)); g_iItemIndex[g_iItemCount]   = StringToInt(strLine);
        KvGetString(kvItemList, "flags",   strLine, sizeof(strLine)); g_iItemFlags[g_iItemCount]   = Item_ParseFlags(strLine);
        KvGetString(kvItemList, "classes", strLine, sizeof(strLine)); g_iItemClasses[g_iItemCount] = Item_ParseClasses(strLine);
        KvGetString(kvItemList, "teams",   strLine, sizeof(strLine)); g_iItemTeams[g_iItemCount]   = Item_ParseTeams(strLine);
        KvGetString(kvItemList, "slot",    strLine, sizeof(strLine)); g_iItemSlot[g_iItemCount]    = StringToInt(strLine)-1;
        
        #if defined DEBUG || defined NOTIFY
        LogMessage("    Found item -> %s", g_strItemName[g_iItemCount]);
        #endif
        #if defined DEBUG
        LogMessage("        - Model : \"%s\"", g_strItemModel[g_iItemCount]);
        LogMessage("        - Index : %i", g_iItemIndex[g_iItemCount]);
        LogMessage("        - Flags : %b", g_iItemFlags[g_iItemCount]);
        LogMessage("        - Class : %08b", g_iItemClasses[g_iItemCount]);
        LogMessage("        - Teams : %02b", g_iItemTeams[g_iItemCount]);
        LogMessage("        - Slot  : %i", g_iItemSlot[g_iItemCount]+1);
        #endif
        
        // Assert the different parameters passed
        if (g_iItemIndex[g_iItemCount] == 0)
        {
            LogMessage("        @ERROR : Item index should be set to one of the hat index values. Please refer to the config file table.");
            continue;
        }
        if (g_iItemSlot[g_iItemCount] < 0 || g_iItemSlot[g_iItemCount] >= MAX_SLOTS)
        {
            LogMessage("        @ERROR : Item slot should be within valid ranges (1 to %i). Please change it to a correct slot.", MAX_SLOTS);
            continue;
        }
        
        // If it's invisible, skip
        if (!(g_iItemFlags[g_iItemCount] & FLAG_INVISIBLE))
        {
            // Check if model exists, so we can prevent crashes.
            if (!FileExists(g_strItemModel[g_iItemCount], true))
            {
                LogMessage("        @ERROR : File \"%s\" not found. Excluding from list.", g_strItemModel[g_iItemCount]);
                continue;
            }
            
            #if defined DELAY_PRECACHE
            new bool:bDelayPrecache = (g_iUsedItemCount >= g_iItemLimit) || 
                                       ((g_iPrecacheLimit >= 0) && (g_iUsedItemCount >= g_iPrecacheLimit));
            #endif

            // Retrieve dependencies file and open if possible.
            Format(strDependencies, sizeof(strDependencies), "%s.dep", g_strItemModel[g_iItemCount]);
            if (FileExists(strDependencies))
            {
                #if defined DEBUG
                LogMessage("        - Found dependencies file. Trying to read.");
                #endif
                
                // Open stream, if possible
                hStream = OpenFile(strDependencies, "r");
                if (hStream == INVALID_HANDLE) { LogMessage("Error, can't read file containing model dependencies."); return; }
                
                while(!IsEndOfFile(hStream))
                {
                    // Try to read line. If EOF has been hit, exit.
                    ReadFileLine(hStream, strLine, sizeof(strLine));
                    
                    // Cleanup line
                    CleanString(strLine);
                    
                    #if defined DEBUG
                    LogMessage("            + File: \"%s\"", strLine);
                    #endif

                    // If file exists...
                    if (!FileExists(strLine, true))
                    {
                        continue;
                    }
                   
		            #if defined DELAY_PRECACHE
                    if (bDelayPrecache)
                    {
                        // Store strings depending on type
                        if (StrContains(strLine, ".vmt", false) != -1)      PushString(g_hItemDecals[g_iItemCount], strLine);
                        else if (StrContains(strLine, ".vtf", false) != -1) PushString(g_hItemDecals[g_iItemCount], strLine);
                        else if (StrContains(strLine, ".mdl", false) != -1) PushString(g_hItemModels[g_iItemCount], strLine);
                    }
                    else
                    #endif
		            {
                        // Precache depending on type
                        if (StrContains(strLine, ".vmt", false) != -1)      PrecacheDecal(strLine, true);
                        else if (StrContains(strLine, ".vtf", false) != -1) PrecacheDecal(strLine, true);
                        else if (StrContains(strLine, ".mdl", false) != -1) PrecacheModel(strLine, true);
                    }

                    // Add to download table
                    AddFileToDownloadsTable(strLine);
                }
                
                // Close file
                CloseHandle(hStream);
            }

            #if defined DELAY_PRECACHE
            if (bDelayPrecache)
            {
                PushString(g_hItemModels[g_iItemCount], strLine);
                g_bItemPrecached[g_iItemCount] = false;
            }
            else
            #endif
            {
                PrecacheModel(g_strItemModel[g_iItemCount], true);

                #if defined DELAY_PRECACHE
                    g_iUsedItemCount++;
                #endif
            }
        }
        
        // Go to next.
        g_iItemCount++;

        // Don't allow more than MAX_ITEMS to be added to the list.
        if (g_iItemCount >= MAX_ITEMS)
        {
            LogMessage("        @ERROR : Item list should contain no more than %i items. Please remove excess items after the %s item.", MAX_ITEMS, g_strItemName[MAX_ITEMS-1]);
            break;
        }
    }
    while (KvGotoNextKey(kvItemList));
        
    CloseHandle(kvItemList);    
    #if defined DEBUG || defined NOTIFY
    LogMessage("    Loaded %i items", g_iItemCount);
    #endif
    #if defined DEBUG
    LogMessage("}");
    #endif
}

#if defined DELAY_PRECACHE
// ------------------------------------------------------------------------
// Item_Precache()
// ------------------------------------------------------------------------
// Precache all the resources needed by the item
// ------------------------------------------------------------------------
bool:Item_Precache(item)
{
    new String:strValue[MAX_LENGTH];
    new Handle:hDecals = g_hItemDecals[item];
    if (hDecals != INVALID_HANDLE)
    {
        new size = GetArraySize(hDecals);
        for (new i = 0; i < size; i++)
        {
            GetArrayString(hDecals, i, strValue, sizeof(strValue));
            if (PrecacheDecal(strValue, true) <= 0)
                return false;
        }
    }

    new Handle:hModels = g_hItemModels[item];
    if (hModels != INVALID_HANDLE)
    {
        new size = GetArraySize(hModels);
        for (new i = 0; i < size; i++)
        {
            GetArrayString(hModels, i, strValue, sizeof(strValue));
            if (PrecacheModel(strValue, true) <= 0)
                return false;
        }
    }
    return true;
}
#endif

// ------------------------------------------------------------------------
// Item_ParseFlags()
// ------------------------------------------------------------------------
// Parses the items flags, duh.
// ------------------------------------------------------------------------
Item_ParseFlags(String:strFlags[])
{
    new Flags;
    if (StrContains(strFlags, "USER_DEFAULT", false)  != -1) Flags |= FLAG_USER_DEFAULT;
    if (StrContains(strFlags, "ADMIN_DEFAULT", false) != -1) Flags |= FLAG_ADMIN_DEFAULT;
    if (StrContains(strFlags, "ADMIN_ONLY", false)    != -1) Flags |= FLAG_ADMIN_ONLY;
    if (StrContains(strFlags, "HIDDEN", false)        != -1) Flags |= FLAG_HIDDEN;
    if (StrContains(strFlags, "INVISIBLE", false)     != -1) Flags |= FLAG_INVISIBLE;
    if (StrContains(strFlags, "HIDE_SCOUT_HAT", false)         != -1) Flags |= FLAG_HIDE_SCOUT_HAT;
    if (StrContains(strFlags, "HIDE_SCOUT_HEADPHONES", false)  != -1) Flags |= FLAG_HIDE_SCOUT_HEADPHONES;
    //if (StrContains(strFlags, "HIDE_HEAVY_HANDS", false)       != -1) Flags |= FLAG_HIDE_HEAVY_HANDS;    
    if (StrContains(strFlags, "HIDE_ENGINEER_HELMET", false)   != -1) Flags |= FLAG_HIDE_ENGINEER_HELMET;
    //if (StrContains(strFlags, "HIDE_SNIPER_QUIVER", false)     != -1) Flags |= FLAG_HIDE_SNIPER_QUIVER;
    if (StrContains(strFlags, "HIDE_SNIPER_HAT", false)        != -1) Flags |= FLAG_HIDE_SNIPER_HAT;     
    //if (StrContains(strFlags, "HIDE_SOLDIER_ROCKET", false)    != -1) Flags |= FLAG_HIDE_SOLDIER_ROCKET;
    if (StrContains(strFlags, "HIDE_SOLDIER_HELMET", false)    != -1) Flags |= FLAG_HIDE_SOLDIER_HELMET;
    if (StrContains(strFlags, "SHOW_SOLDIER_MEDAL", false)     != -1) Flags |= FLAG_SHOW_SOLDIER_MEDAL;
    
    return Flags;
}

// ------------------------------------------------------------------------
// Item_ParseClasses()
// ------------------------------------------------------------------------
// Parses the wearable classes, duh.
// ------------------------------------------------------------------------
Item_ParseClasses(String:strClasses[])
{
    new iFlags;
    if (StrContains(strClasses, "SCOUT", false)    != -1) iFlags |= CLASS_SCOUT;
    if (StrContains(strClasses, "SNIPER", false)   != -1) iFlags |= CLASS_SNIPER;
    if (StrContains(strClasses, "SOLDIER", false)  != -1) iFlags |= CLASS_SOLDIER;
    if (StrContains(strClasses, "DEMOMAN", false)  != -1) iFlags |= CLASS_DEMOMAN;
    if (StrContains(strClasses, "MEDIC", false)    != -1) iFlags |= CLASS_MEDIC;
    if (StrContains(strClasses, "HEAVY", false)    != -1) iFlags |= CLASS_HEAVY;
    if (StrContains(strClasses, "PYRO", false)     != -1) iFlags |= CLASS_PYRO;
    if (StrContains(strClasses, "SPY", false)      != -1) iFlags |= CLASS_SPY;
    if (StrContains(strClasses, "ENGINEER", false) != -1) iFlags |= CLASS_ENGINEER;
    if (StrContains(strClasses, "ALL", false)      != -1) iFlags |= CLASS_ALL;
    
    return iFlags;
}
// ------------------------------------------------------------------------
// Item_ParseTeams()
// ------------------------------------------------------------------------
// Parses the wearable teams, duh.
// ------------------------------------------------------------------------
Item_ParseTeams(String:strTeams[])
{
    new iFlags;
    if (StrContains(strTeams, "RED", false) != -1 ) iFlags |= TEAM_RED;
    if (StrContains(strTeams, "BLUE", false) != -1) iFlags |= TEAM_BLU;
    if (StrContains(strTeams, "ALL", false) != -1)  iFlags |= TEAM_RED|TEAM_BLU;
    
    return iFlags;
}

// ------------------------------------------------------------------------
// Item_IsWearable()
// ------------------------------------------------------------------------
// Determines if the selected item is wearable by a player (that means, 
// the player has the enough admin level, is the correct class, etc. These
// Cfg can be overriden if the player has the override flag, though.
// ------------------------------------------------------------------------
Item_IsWearable(iClient, Item)
{
    // If the selected item is not valid, it can't be wearable! Rargh!
    if (Item < 0 || Item >= g_iItemCount) return 0;
    
    // Determine if the client has the override flag.
    if (g_iPlayerFlags[iClient] & PLAYER_OVERRIDE) return 1;
    
    if (g_iPlayerFlags[iClient] & PLAYER_ADMIN)
    {
        if (g_bAdminOverride) return 1;
    } else {
        if (g_iItemFlags[Item] & FLAG_ADMIN_ONLY) return 0;
    }
    
    if (!(Client_ClassFlags(iClient) & g_iItemClasses[Item])) return 0;
    if (!(Client_TeamFlags(iClient) & g_iItemTeams[Item]))    return 0;
    
    // Success!
    return 1;
}

// ------------------------------------------------------------------------
// Item_FindDefaultItem()
// ------------------------------------------------------------------------
Item_FindDefaultItem(iClient, iSlot)
{
    new iFlagsFilter;
    if (g_bForceAdmins && (g_iPlayerFlags[iClient] & PLAYER_ADMIN)) iFlagsFilter = FLAG_ADMIN_DEFAULT;
    else if (g_bForceUsers)                                         iFlagsFilter = FLAG_USER_DEFAULT;
    
    if (iFlagsFilter)
        for (new j=0; j<g_iItemCount; j++)
        {
            if (g_iItemSlot[j] != iSlot)           continue;
            if (!(g_iItemFlags[j] & iFlagsFilter)) continue;
            if (!Item_IsWearable(iClient, j))      continue;
            
            return j;
        }
    
    return -1;
}

// ------------------------------------------------------------------------
// Item_DetermineBodyGroups()
// ------------------------------------------------------------------------
Item_DetermineBodyGroups(iClient)
{
    // Determine bodygroups across all the equiped items
    new BodyGroups = 0;
    for (new Slot=0; Slot<MAX_SLOTS; Slot++)
    {
        new Item = g_iPlayerItem[iClient][Slot];
        if (Item == -1) continue;
        
        new Flags = g_iItemFlags[Item];
        
        switch(TF2_GetPlayerClass(iClient))
        {
            case TFClass_Engineer:
            {
                if (Flags & FLAG_HIDE_ENGINEER_HELMET) BodyGroups |= BODYGROUP_ENGINEER_HELMET;
            }
            case TFClass_Scout:
            {
                if (Flags & FLAG_HIDE_SCOUT_HAT) BodyGroups |= BODYGROUP_SCOUT_HAT;
                if (Flags & FLAG_HIDE_SCOUT_HEADPHONES) BodyGroups |= BODYGROUP_SCOUT_HEADPHONES;
            }
            case TFClass_Sniper:
            {
                if (Flags & FLAG_HIDE_SNIPER_HAT) BodyGroups |= BODYGROUP_SNIPER_HAT;
            }
            case TFClass_Soldier:
            {
                if (Flags & FLAG_HIDE_SOLDIER_HELMET) BodyGroups |= BODYGROUP_SOLDIER_HELMET;    
                if (Flags & FLAG_SHOW_SOLDIER_MEDAL) BodyGroups |= BODYGROUP_SOLDIER_MEDAL;
            }
        }
    }
    
    return BodyGroups;
}

// ------------------------------------------------------------------------
// Item_RetrieveSlotCookie()
// ------------------------------------------------------------------------
Item_RetrieveSlotCookie(iClient, Slot)
{
    // If the cookies aren't cached, return.
    if (!AreClientCookiesCached(iClient)) return -1;
    
    // Retrieve current class
    new TFClassType:Class = TF2_GetPlayerClass(iClient);
    if (Class == TFClass_Unknown) return -1;
    
    // Retrieve the class cookie
    decl String:strCookie[64];
    GetClientCookie(iClient, g_hCookies[Class][Slot], strCookie, sizeof(strCookie));
    
    // If it's void, return -1
    if (StrEqual(strCookie, "")) return -1;
    
    // Otherwise, return the cookie value
    return StringToInt(strCookie);    
}

// ------------------------------------------------------------------------
// Item_SetSlotCookie()
// ------------------------------------------------------------------------
Item_SetSlotCookie(iClient, Slot)
{
    // If the cookies aren't cached, return.
    if (!AreClientCookiesCached(iClient)) return;
    
    // Retrieve current class
    new TFClassType:Class = TF2_GetPlayerClass(iClient);
    if (Class == TFClass_Unknown) return;
    
    // Set the class cookie
    decl String:strCookie[64];
    Format(strCookie, sizeof(strCookie), "%i", g_iPlayerItem[iClient][Slot]);
    SetClientCookie(iClient, g_hCookies[_:Class][Slot], strCookie);
}


// ------------------------------------------------------------------------
// Client_ClassFlags()
// ------------------------------------------------------------------------
// Calculates the current class flags and returns them
// ------------------------------------------------------------------------
Client_ClassFlags(iClient)
{
    switch(TF2_GetPlayerClass(iClient))
    {
        case TFClass_DemoMan:  return CLASS_DEMOMAN;
        case TFClass_Engineer: return CLASS_ENGINEER;
        case TFClass_Heavy:    return CLASS_HEAVY;
        case TFClass_Medic:    return CLASS_MEDIC;
        case TFClass_Pyro:     return CLASS_PYRO;
        case TFClass_Scout:    return CLASS_SCOUT;
        case TFClass_Sniper:   return CLASS_SNIPER;
        case TFClass_Soldier:  return CLASS_SOLDIER;
        case TFClass_Spy:      return CLASS_SPY;
    }
    
    return 0;
}

// ------------------------------------------------------------------------
// Client_TeamFlags()
// ------------------------------------------------------------------------
// Calculates the current team flags and returns them
// ------------------------------------------------------------------------
Client_TeamFlags(iClient)
{
    switch(GetClientTeam(iClient))
    {
        case TFTeam_Blue: return TEAM_BLU;
        case TFTeam_Red:  return TEAM_RED;
    }
    
    return 0;
}

// ------------------------------------------------------------------------
// Menu_BuildMain()
// ------------------------------------------------------------------------
// Builds the main menu, displaying the options for the wearable
// items.
// ------------------------------------------------------------------------
Handle:Menu_BuildMain()
{
    // Create menu handle
    new Handle:hMenu = CreateMenu(Menu_Manager, MenuAction_DisplayItem|MenuAction_Display);
    
    // Add the different options
    AddMenuItem(hMenu, "", "Menu_Equip");
    AddMenuItem(hMenu, "", "Menu_Remove");
    AddMenuItem(hMenu, "", "Menu_RemoveAll");
    
    // Setup title
    SetMenuTitle(hMenu, "Menu_Main");
    return hMenu;
}

// ------------------------------------------------------------------------
// Menu_BuildSlots()
// ------------------------------------------------------------------------
// Builds the select slots menu. Nothing fancy, just the slots.
// ------------------------------------------------------------------------
Handle:Menu_BuildSlots(String:StrTitle[])
{
    // Create menu handle
    new Handle:hMenu = CreateMenu(Menu_Manager, MenuAction_Display);
    
    // Add the different options
    for (new i=0; i<MAX_SLOTS; i++)
    {
        new String:StrBuffer[32]; Format(StrBuffer, sizeof(StrBuffer), "Slot %i", i+1);
        AddMenuItem(hMenu, "", StrBuffer);
    }
    
    // Setup title
    SetMenuTitle(hMenu, StrTitle);
    return hMenu;
}

// ------------------------------------------------------------------------
// Menu_BuildItemList(iClient, Slot)
// ------------------------------------------------------------------------
// This method builds and specific menu for the client, based on it's
// current state, class and flags.
// ------------------------------------------------------------------------
Handle:Menu_BuildItemList(iClient, Slot)
{
    // Create the menu Handle
    new Handle:Menu = CreateMenu(Menu_Manager);
    new String:strBuffer[64]; 
    
    #if defined DELAY_PRECACHE
    new bool:bItemsMaxed = (g_iUsedItemCount < g_iItemLimit);
    #endif

    // Add all objects
    for (new i=0; i<g_iItemCount; i++) 
    {
        // Skip if not a correct item
        if (g_iItemSlot[i] != Slot)         continue;
        if (!Item_IsWearable(iClient, i)) continue;
        if (g_iItemFlags[i] & FLAG_HIDDEN)  continue;
        
        Format(strBuffer, sizeof(strBuffer), "%i", i);
        #if defined DELAY_PRECACHE
        AddMenuItem(Menu, strBuffer, g_strItemName[i],
                    (bItemsMaxed || g_bItemPrecached[i])
                    ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        #else
        AddMenuItem(Menu, strBuffer, g_strItemName[i]);
        #endif
    }
    
    // Set the menu title
    SetMenuTitle(Menu, "%T", "Menu_SelectItem", iClient, Slot+1);
    
    return Menu;
}

// ------------------------------------------------------------------------
// Menu_Manager()
// ------------------------------------------------------------------------
// The master menu manager. Manages the different menu usages and 
// makes sure to translate the options when necessary.
// ------------------------------------------------------------------------
public Menu_Manager(Handle:hMenu, MenuAction:maState, iParam1, iParam2)
{
    new String:strBuffer[64];
    
    switch(maState)
    {
        case MenuAction_Select:
        {
            // First, check if the player is alive and ingame. If not, do nothing.
            if (!IsValidClient(iParam1)) return 0;
            
            if (hMenu == g_hMenuMain)
            {
                if (iParam2 == 0) DisplayMenu(g_hMenuEquip,  iParam1, MENU_TIME_FOREVER);
                else if (iParam2 == 1) DisplayMenu(g_hMenuRemove, iParam1, MENU_TIME_FOREVER);
                else {
                    for (new i=0; i<MAX_SLOTS; i++)
                    {
                        Item_Remove(iParam1, i);
                        Item_SetSlotCookie(iParam1, i);
                    }
                    CPrintToChat(iParam1, "%t", "Message_RemovedAllItems");
                }
            }
            else if (hMenu == g_hMenuEquip)
            {
                new Handle:hListMenu = Menu_BuildItemList(iParam1, iParam2);
                DisplayMenu(hListMenu,  iParam1, MENU_TIME_FOREVER);
            }
            else if (hMenu == g_hMenuRemove)
            {
                Item_Remove(iParam1, iParam2);
                Item_SetSlotCookie(iParam1, iParam2);
                CPrintToChat(iParam1, "%t", "Message_RemovedItem", iParam2+1);
            }
            else
            {
                GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));
                new Item = StringToInt(strBuffer);
                #if defined DELAY_PRECACHE
                if (Item_Equip(iParam1, Item))
                {
                    Item_SetSlotCookie(iParam1, g_iItemSlot[Item]);
                    CPrintToChat(iParam1, "%t", "Message_EquippedItem", g_strItemName[Item], g_iItemSlot[Item]+1);  
                    #if defined DEBUG_EQUIP
                    LogMessage("%N Equipped Hat %s", iParam1, g_strItemName[Item]);
                    #endif
                }
                else
                {
                    CPrintToChat(iParam1, "%t", "Error_NotAvailable", g_strItemName[Item]);  
                    #if defined DEBUG_EQUIP
                    LogMessage("%N Denied Hat %s", iParam1, g_strItemName[Item]);
                    #endif
                }
                #else
                Item_Equip(iParam1, Item);
                Item_SetSlotCookie(iParam1, g_iItemSlot[Item]);
                CPrintToChat(iParam1, "%t", "Message_EquippedItem", g_strItemName[Item], g_iItemSlot[Item]+1);  
                #endif
            }
        }
        
        case MenuAction_DisplayItem:
        {
            // Get the display string, we'll use it as a translation phrase
            decl String:strDisplay[64]; GetMenuItem(hMenu, iParam2, "", 0, _, strDisplay, sizeof(strDisplay));
            decl String:strTranslation[255]; Format(strTranslation, sizeof(strTranslation), "%T", strDisplay, iParam1);
            return RedrawMenuItem(strTranslation);
        }
        
        case MenuAction_Display:
        {
            // Retrieve panel
            new Handle:Panel = Handle:iParam2;
            
            // Translate title
            decl String:strTranslation[255];
            if (hMenu == g_hMenuMain)        { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Main",   iParam1); }
            else if (hMenu == g_hMenuEquip)  { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Equip",  iParam1); }
            else if (hMenu == g_hMenuRemove) { Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Remove", iParam1); }
            
            // Set title.
            SetPanelTitle(Panel, strTranslation);
        }
        
        case MenuAction_End:
        {
            if (hMenu != g_hMenuMain && hMenu != g_hMenuEquip && hMenu != g_hMenuRemove)
                CloseHandle(hMenu);
        }
    }
    
    return 1;
}

// ------------------------------------------------------------------------
// Cmd_BlockTriggers()
// ------------------------------------------------------------------------
public Action:Cmd_BlockTriggers(iClient, iArgs)
{
    if (!g_bBlockTriggers) return Plugin_Continue;
    if (iClient < 1 || iClient > MaxClients) return Plugin_Continue;
    if (iArgs < 1) return Plugin_Continue;
    
    // Retrieve the first argument and check it's a valid trigger
    decl String:strArgument[64]; GetCmdArg(1, strArgument, sizeof(strArgument));
    if (StrEqual(strArgument, "!tf_equipment", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!equip", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!em", true)) return Plugin_Handled;
    if (StrEqual(strArgument, "!hats", true)) return Plugin_Handled;
    
    // If no valid argument found, pass
    return Plugin_Continue;
}

// ------------------------------------------------------------------------
// Cmd_Menu()
// ------------------------------------------------------------------------
// Shows menu to clients, if the client is able to: The plugin isn't set
// to admin only or his equipment is locked.
// ------------------------------------------------------------------------
public Action:Cmd_Menu(iClient, iArgs)
{
    // Not allowed if not ingame.
    if (iClient == 0) { ReplyToCommand(iClient, "[TF2] Command is in-game only."); return Plugin_Handled; }
    
    // Check if the user doesn't have permission. If not, ignore command.
    if (!(g_iPlayerFlags[iClient] & PLAYER_ADMIN))
    {
        if (g_bAdminOnly)
        {
            CPrintToChat(iClient, "%t", "Error_AccessLevel");
            return Plugin_Handled;
        }
        if (g_iPlayerFlags[iClient] & PLAYER_LOCK)
        {
            CPrintToChat(iClient, "%t", "Error_EquipmentLocked");
            return Plugin_Handled;
        }
    }
    
    // Display menu.
    DisplayMenu(g_hMenuMain, iClient, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_EquipItem()
// ------------------------------------------------------------------------
// Force a client to equip an specific items.
// ------------------------------------------------------------------------
public Action:Cmd_EquipItem(iClient, iArgs)
{
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_equip <#id|name> <item name>."); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strItem[128];  GetCmdArg(2, strItem,   sizeof(strItem));
    new iItem = -1;
    
    // Check if item exists and if so, grab index
    for (new i=0; i<g_iItemCount; i++)
        if (StrEqual(g_strItemName[i], strItem, false))
        {
            iItem = i;
            break;
        }
    if (iItem == -1) { ReplyToCommand(iClient, "[TF2] Unknown item : \"%s\"", strItem); return Plugin_Handled; }
    
    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        // If item isn't wearable, for the client.
        if (!Item_IsWearable(iTargetList[i], iItem)) {
            decl String:strName[64]; GetClientName(iTargetList[i], strName, sizeof(strName));
            CPrintToChat(iClient, "%t", "Error_CantWear", strName);  
            continue;
        }
        
        // Equip item and tell to client.
        #if defined DELAY_PRECACHE
        if (Item_Equip(iTargetList[i], iItem))
        {
            Item_SetSlotCookie(iTargetList[i], g_iItemSlot[iItem]);
            CPrintToChat(iTargetList[i], "%t", "Message_ForcedEquip", g_strItemName[iItem], g_iItemSlot[iItem]+1);  

            #if defined DEBUG_EQUIP
            LogMessage("%N Force Equipped Hat %s", iTargetList[i], g_strItemName[iItem]);
            #endif
        }
        else
        {
            #if defined DEBUG_EQUIP
            LogMessage("%N Force Denied Hat %s", iTargetList[i], g_strItemName[iItem]);
            #endif
        }
        #else
        Item_SetSlotCookie(iTargetList[i], g_iItemSlot[iItem]);
        CPrintToChat(iTargetList[i], "%t", "Message_ForcedEquip", g_strItemName[iItem], g_iItemSlot[iItem]+1);  
        #endif
    }

    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_RemoveItem()
// ------------------------------------------------------------------------
public Action:Cmd_RemoveItem(iClient, iArgs)
{
    // Determine if the number of arguments is valid
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_remove <#id|name> <slot>."); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strSlot[8];    GetCmdArg(2, strSlot,   sizeof(strSlot));
    new iSlot = StringToInt(strSlot)-1;
    
    // Check if it's a valid slot.
    if (iSlot < 0 || iSlot >= MAX_SLOTS) { ReplyToCommand(iClient, "[TF2] Slot out of range : %i", iSlot+1); return Plugin_Handled; }
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        Item_Remove(iTargetList[i], iSlot);
        Item_SetSlotCookie(iTargetList[i], iSlot);
        CPrintToChat(iTargetList[i], "%t", "Message_ForcedRemove", iSlot+1);  
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_LockEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_LockEquipment(iClient, iArgs)
{
    // Determine if the number of arguments is valid
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_lock <#id|name> <state>"); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    new State = StringToInt(strState);
    if (State == 1) 
        for (new i = 0; i < iTargetCount; i++)
        {
            if (!IsValidClient(iTargetList[i])) continue;
            if (g_iPlayerFlags[iTargetList[i]] & PLAYER_ADMIN) continue;
        
            g_iPlayerFlags[iTargetList[i]] |= PLAYER_LOCK;
            CPrintToChat(iTargetList[i], "%t", "Message_Locked");  
        }
    else
        for (new i = 0; i < iTargetCount; i++)
        {
            if (!IsValidClient(iTargetList[i])) continue;
            if (g_iPlayerFlags[iTargetList[i]] & PLAYER_ADMIN) continue;
            
            g_iPlayerFlags[iTargetList[i]] &= ~PLAYER_LOCK;
            CPrintToChat(iTargetList[i], "%t", "Message_Unlocked");  
        }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_OverrideEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_OverrideEquipment(iClient, iArgs)
{
    // Determine if the number of arguments is valid
    if (iArgs < 2) { ReplyToCommand(iClient, "[TF2] Usage: tf_equipment_override <#id|name> <state>"); return Plugin_Handled; }
    
    // Retrieve arguments
    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
    decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));
    
    // Process the targets
    decl String:strTargetName[MAX_TARGET_LENGTH];
    decl iTargetList[MAXPLAYERS], iTargetCount;
    decl bool:bTargetTranslate;
    
    if ((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
    strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
    {        
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }
    
    // Apply to all targets
    new iState = StringToInt(strState);
    
    if (iState == 1) 
        for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        g_iPlayerFlags[iTargetList[i]] |= PLAYER_OVERRIDE;
        CPrintToChat(iTargetList[i], "%t", "Message_Override_On");  
    }
    else
    for (new i = 0; i < iTargetCount; i++)
    {
        if (!IsValidClient(iTargetList[i])) continue;
        
        g_iPlayerFlags[iTargetList[i]] &= ~PLAYER_OVERRIDE;
        CPrintToChat(iTargetList[i], "%t", "Message_Override_Off");  
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_Reload()
// ------------------------------------------------------------------------
public Action:Cmd_Reload(iClient, iArgs)
{
    // Reparse item list
    Item_ParseList();
    
    // Re-read admins flags
    new ibFlags = ReadFlagString(g_strAdminFlags);
    for (iClient=1; iClient<=MaxClients; iClient++)
    {    
        if (!IsValidClient(iClient)) continue;
        
        g_iPlayerFlags[iClient] &= ~PLAYER_ADMIN;
        if (GetUserFlagBits(iClient) & ibFlags)      g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
        if (GetUserFlagBits(iClient) & ADMFLAG_ROOT) g_iPlayerFlags[iClient] |= PLAYER_ADMIN;
    }
    
    // Done
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Timer_Welcome
// ------------------------------------------------------------------------
public Action:Timer_Welcome(Handle:hTimer, any:iClient)
{
    if (iClient < 1 || iClient > MaxClients) return Plugin_Stop;
    if (!IsValidClient(iClient)) return Plugin_Stop;
    
    CPrintToChat(iClient, "%t", "Announce_Plugin", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    return Plugin_Stop;
}

// ------------------------------------------------------------------------
// Timer_Announce
// ------------------------------------------------------------------------
public Action:Timer_Announce(Handle:hTimer)
{
    if (!g_bAnnounce) return Plugin_Continue;
    
    if (g_bAdminOnly)
    {
        for (new iClient=1; iClient<=MaxClients; iClient++)
        {
            if (!IsValidClient(iClient)) continue;
            
            if (!(g_iPlayerFlags[iClient] & PLAYER_ADMIN)) continue;
            CPrintToChat(iClient, "%t", "Announce_Command");
        }
    } else {
        CPrintToChatAll("%t", "Announce_Command");
    }
    
    return Plugin_Continue;
}

// ------------------------------------------------------------------------
// CleanString
// ------------------------------------------------------------------------
stock CleanString(String:strBuffer[])
{
    // Cleanup any illegal characters
    new Length = strlen(strBuffer);
    for (new iPos=0; iPos<Length; iPos++)
    {
        switch(strBuffer[iPos])
        {
            case '\r': strBuffer[iPos] = ' ';
            case '\n': strBuffer[iPos] = ' ';
            case '\t': strBuffer[iPos] = ' ';
        }
    }
    
    // Trim string
    TrimString(strBuffer);
}

// ------------------------------------------------------------------------
// TF2_SdkStartup
// ------------------------------------------------------------------------
stock TF2_SdkStartup()
{
    new Handle:hGameConf = LoadGameConfigFile("TF2_EquipmentManager");
    if (hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"EquipWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkEquipWearable = EndPrepSDKCall();
        
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"RemoveWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkRemoveWearable = EndPrepSDKCall();
        
        CloseHandle(hGameConf);
        g_bSdkStarted = true;
    } else {
        SetFailState("Couldn't load SDK functions (TF2_EquipmentManager).");
    }
}

// ------------------------------------------------------------------------
// TF2_SpawnWearable
// ------------------------------------------------------------------------
stock TF2_SpawnWearable(iOwner, iDef=52, iLevel=100, iQuality=0)
{
    new iTeam = GetClientTeam(iOwner);
    new iItem = CreateEntityByName("tf_wearable_item");
    
    if (IsValidEdict(iItem))
    {
        SetEntProp(iItem, Prop_Send, "m_bInitialized", 1);
        
        // Using reference data from Batter's Helmet. Thanks to MrSaturn.
        SetEntProp(iItem, Prop_Send, "m_fEffects",             EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_NOSHADOW|EF_PARENT_ANIMATES);
        SetEntProp(iItem, Prop_Send, "m_iTeamNum",             iTeam);
        SetEntProp(iItem, Prop_Send, "m_nSkin",                (iTeam-2));
        SetEntProp(iItem, Prop_Send, "m_CollisionGroup",       11);
        SetEntProp(iItem, Prop_Send, "m_iItemDefinitionIndex", iDef);
        SetEntProp(iItem, Prop_Send, "m_iEntityLevel",         iLevel);
        SetEntProp(iItem, Prop_Send, "m_iEntityQuality",       iQuality);
        
        // Spawn and change model
        DispatchSpawn(iItem);
    }
    
    return iItem;
}

// ------------------------------------------------------------------------
// TF2_EquipWearable
// ------------------------------------------------------------------------
stock TF2_EquipWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem))
    {
        SDKCall(g_hSdkEquipWearable, iOwner, iItem);
    }
    else
    {
        LogMessage("Error: Item %i isn't a valid wearable.", iItem);
    }
}

// ------------------------------------------------------------------------
// TF2_RemoveWearable
// ------------------------------------------------------------------------
stock TF2_RemoveWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem))
    {
        if (GetEntPropEnt(iItem, Prop_Send, "m_hOwnerEntity") == iOwner)
        {
            SDKCall(g_hSdkRemoveWearable, iOwner, iItem);
        }
        RemoveEdict(iItem);
    }
}

// ------------------------------------------------------------------------
// TF2_IsEntityWearable
// ------------------------------------------------------------------------
stock bool:TF2_IsEntityWearable(iEntity)
{
    if (iEntity > 0)
    {
        if (IsValidEdict(iEntity))
        {
            new String:strClassname[32];
            GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
            
            return StrEqual(strClassname, "tf_wearable_item", false);
        }
    }
    
    return false;
}

// ------------------------------------------------------------------------
// IsValidClient
// ------------------------------------------------------------------------
stock bool:IsValidClient(iClient)
{
    if (iClient < 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

#if defined DELAY_PRECACHE
// ------------------------------------------------------------------------
// PushString()
// ------------------------------------------------------------------------
// Push a string onto an array, create the array if necessary.
// ------------------------------------------------------------------------
PushString(&Handle:array, const String:string[], blocksize=MAX_LENGTH, startsize=0)
{
    if (array == INVALID_HANDLE)
        array = CreateArray(blocksize, startsize);

    PushArrayString(array, string);
}
#endif
