/* vim: set ai et ts=4 sw=4 :
 * File: ShopItems.sp
 * Description: The shop items that come with SourceCraft.
 * Author(s): Anthony Iacono
 * Modifications by: -=|JFH|=-Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <new_tempents_stocks>
#include <particle>
#include <weapons>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#include <tf2_player>
#include <tf2_ammo>
#include <cstrike>
#include <TeleportPlayer>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/jetpack>
#include <lib/tripmines>
#include <lib/firemines>
#include <lib/ztf2nades>
#include <lib/Hallucinate>
#include <libdod/dod_ignite>
#include <libtf2/sidewinder>
#include <libtf2/MedicInfect>
#include <libtf2/AdvancedInfiniteAmmo>
#define REQUIRE_PLUGIN

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <lib/trace>

#include "sc/SourceCraft"
#include "sc/HealthParticle"
#include "sc/SupplyDepot"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/sounds"

#include "effect/FlashScreen"

// Defines

#define ITEM_ANKH             0 // Ankh of Reincarnation - Retrieve Equipment after death
#define ITEM_BOOTS            1 // Boots of Speed - Move Faster
#define ITEM_CLAWS            2 // Claws of Attack - Extra Damage
#define ITEM_CLOAK            3 // Cloak of Shadows - Invisibility and Immunity to uncloaking
#define ITEM_DARKNESS         4 // Cloak of Darkness - Immunity to detection
#define ITEM_MASK             5 // Mask of Death - Recieve Health for Hits
#define ITEM_NECKLACE         6 // Necklace of Immunity - Immune to Ultimates
#define ITEM_LUBE             7 // Lubricant - Immune to MotionTaking
#define ITEM_ORB_FROST        8 // Orb of Frost - Slow Enemy
#define ITEM_ORB_FIRE         9 // Orb of Fire - Set Enemy on Fire
#define ITEM_PERIAPT         10 // Periapt of Health - Get Extra Health when Purchased
#define ITEM_TOME            11 // Tome of Experience - Get Extra Experience when Purchased
#define ITEM_SCROLL          12 // Scroll of Respawning - Respawn after death.
#define ITEM_SOCK            13 // Sock of the Feather - Jump Higher
#define ITEM_GLOVES          14 // Flaming Gloves of Warmth - Given Grenades.
#define ITEM_PACK            15 // Ammo Pack - Given ammo or metal every 10 seconds.
#define ITEM_AMMO            16 // Infinite Ammo - Given unlimited, infinite ammo.
#define ITEM_SACK            17 // Sack of looting - Loot crystals from corpses.
#define ITEM_LOCKBOX         18 // Lockbox - Keep crystals safe from theft.
#define ITEM_RING            19 // Ring of Regeneration + 1 - Given extra health over time
#define ITEM_RING3           20 // Ring of Regeneration + 3 - Given extra health over time
#define ITEM_RING5           21 // Ring of Regeneration + 5 - Given extra health over time
#define ITEM_MOLE            22 // Mole - Respawn in enemies spawn with cloak.
#define ITEM_MOLE_PROTECTION 23 // Mole Protection - Reduce damage from a Mole.
#define ITEM_MOLE_REFLECTION 24 // Mole Reflection - Reflects damage back to the Mole.
#define ITEM_MOLE_RETENTION  25 // Mole Retention - Keep Mole Protection/Reflection until used.
#define ITEM_GOGGLES         26 // The Goggles - Immunity to Blindness/etc.!
#define ITEM_BLINDERS        27 // Blinders - Permanent converts drugs and other obnoxious effects to blindness
#define ITEM_TRIPMINE        28 // Tripmines - 1 tripmine to plant (using sm_tripmine command/bind)
#define ITEM_FIREMINE        29 // Firemines - 1 firemine (spidermine) to plant (using sm_mine command/bind)
#define ITEM_ANTIBIOTIC      30 // Antibiotic - Cures or prevents infection
#define ITEM_ANTIVENOM       31 // Antivenom - Cures or prevents poison
#define ITEM_ANTIRAD         32 // Antirad - Cures or prevents radiation illness
#define ITEM_ANTIDOTE        33 // Antidote - Cures or prevents poison, infection and radiation
#define ITEM_RESTORATION     34 // Potion of Restoration - Cures most ills (restores players)
#define ITEM_MAGNIFYER       35 // Experience Magnifyer - Experience multiplied by 1.5 for remainder of life
#define ITEM_FUEL            36 // Jetpack Fuel
#define ITEM_JACKET          37 // Flack Jacket - Protects from explosions.
#define ITEM_SILVER          38 // Silver Ammo - Prevents victims from reincarnating.
#define ITEM_HELM            39 // Helm of the Black Legion - Protects from Headshots.
#define ITEM_ENERGY10        40 // 10 Energy - Purchase 10 energy
#define ITEM_ENERGY50        41 // 50 Energy - Purchase 50 energy
#define ITEM_ENERGY100       42 // 100 Energy - Purchase 100 energy
#define ITEM_ENERGY          43 // Energy - Convert all +crystals into energy.
#define MAXITEMS             44

new const String:maskSnd[]   = "sc/mask.mp3";
new const String:bootsWav[]  = "sc/bootospeed.mp3";
new const String:tomeSound[] = "sc/tomes.wav";

new String:helmSound[][]     = { "physics/metal/metal_solid_impact_bullet1.wav",
                                 "physics/metal/metal_solid_impact_bullet2.wav",
                                 "physics/metal/metal_solid_impact_bullet3.wav",
                                 "physics/metal/metal_solid_impact_bullet4.wav" };

new bool:cfgAllowInvisibility = true;

new shopItem[MAXITEMS+1] = { -1, ... };

new Handle:g_BootTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_NadeTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_AmmoPackTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_RegenerationTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

new Handle:g_TrackWeaponsTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:vecPlayerWeapons[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new myWepsOffset = 0;

new m_BootCount[MAXPLAYERS+1];
new m_MoleHealth[MAXPLAYERS+1];
new Float:m_SpawnLoc[MAXPLAYERS+1][3];
new bool:m_UsedPeriapt[MAXPLAYERS+1];
new bool:m_IsMole[MAXPLAYERS+1];
new Float:m_MaskTime[MAXPLAYERS+1];
new Float:m_ClawTime[MAXPLAYERS+1];
new Float:m_FireTime[MAXPLAYERS+1][MAXPLAYERS+1];

new Handle:hGameConf      = INVALID_HANDLE;
new Handle:hUTILRemove    = INVALID_HANDLE;
new Handle:hWeaponDrop    = INVALID_HANDLE;
new Handle:hSetModel      = INVALID_HANDLE;

#define _ShopItems
#include "sc/respawn"
#include "sc/giveammo"

public Plugin:myinfo = 
{
    name = "SourceCraft - Shopitems",
    author = "-=|JFH|=-Naris, PimpinJuice",
    description = "The shop items that come with SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://www.jigglysfunhouse.net/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("IsMole",Native_IsMole);
    CreateNative("SetMole",Native_SetMole);
    CreateNative("InvokeMole",Native_InvokeMole);
    RegPluginLibrary("ShopItems");
    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.supply.phrases.txt");
    LoadTranslations("sc.restore.phrases.txt");
    AdditionalTranslations("sc.shopitems.phrases.txt");

    RegConsoleCmd("+item",ItemCommand,"use SourceCraft item (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-item",ItemCommand,"use SourceCraft item (keyup)",FCVAR_GAMEDLL);

    RegAdminCmd("sc_test",CMD_Test,ADMFLAG_GENERIC,"Test stuff. (for Admins)");

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
        if (!HookEventEx("round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the round_win event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    //                                CreateShopItem(short_name,    crystals,vespene,energon,money,use_pcrystals,max,required_level,...);
    shopItem[ITEM_BLINDERS]         = CreateShopItem("blinders",    0);
    shopItem[ITEM_ANKH]             = CreateShopItem("ankh",        60, 2);
    shopItem[ITEM_BOOTS]            = CreateShopItem("boots",       55);
    shopItem[ITEM_CLAWS]            = CreateShopItem("claws",       60);

    cfgAllowInvisibility            = bool:GetConfigNum("allow_invisibility", cfgAllowInvisibility);
    if (cfgAllowInvisibility)
    {
        shopItem[ITEM_CLOAK]        = CreateShopItem("cloak",       25);
    }
    else
    {
        shopItem[ITEM_CLOAK]        = CreateShopItem("cloak",       10,
                                                     .desc="%cloak_noinvis_desc");
    }
    
    shopItem[ITEM_DARKNESS]         = CreateShopItem("darkness",    15);
    shopItem[ITEM_MASK]             = CreateShopItem("mask",        10);
    shopItem[ITEM_NECKLACE]         = CreateShopItem("necklace",    15);
    shopItem[ITEM_JACKET]           = CreateShopItem("jacket",      10);
    shopItem[ITEM_ANTIBIOTIC]       = CreateShopItem("antibiotic",  5,  0, .max=10);
    shopItem[ITEM_ANTIVENOM]        = CreateShopItem("antivenom",   30);
    shopItem[ITEM_ANTIRAD]          = CreateShopItem("antirad",     30);
    shopItem[ITEM_ANTIDOTE]         = CreateShopItem("antidote",    60);
    shopItem[ITEM_RESTORATION]      = CreateShopItem("restoration", 75, 0, .max=10);
    shopItem[ITEM_GOGGLES]          = CreateShopItem("goggles",     10);
    shopItem[ITEM_LUBE]             = CreateShopItem("lube",        30);
    shopItem[ITEM_ORB_FROST]        = CreateShopItem("orb",         40);
    shopItem[ITEM_ORB_FIRE]         = CreateShopItem("fire",        55);
    shopItem[ITEM_SILVER]           = CreateShopItem("silver",      50);
    shopItem[ITEM_HELM]             = CreateShopItem("helm",        15);
    shopItem[ITEM_PERIAPT]          = CreateShopItem("periapt",     40);
    shopItem[ITEM_TOME]             = CreateShopItem("tome",        50, 2);
    shopItem[ITEM_MAGNIFYER]        = CreateShopItem("magnifier",   85, 5);
    shopItem[ITEM_SCROLL]           = CreateShopItem("scroll",      15);
    shopItem[ITEM_SOCK]             = CreateShopItem("sock",        45);
    shopItem[ITEM_PACK]             = CreateShopItem("pack",        35);

    if (IsInfiniteAmmoAvailable())
        shopItem[ITEM_AMMO]         = CreateShopItem("ammo",        40);

    shopItem[ITEM_SACK]             = CreateShopItem("sack",        65);
    shopItem[ITEM_LOCKBOX]          = CreateShopItem("lockbox",     10);
    shopItem[ITEM_RING]             = CreateShopItem("ring+1",      15);
    shopItem[ITEM_RING3]            = CreateShopItem("ring+3",      35);
    shopItem[ITEM_RING5]            = CreateShopItem("ring+5",      55);
    shopItem[ITEM_MOLE]             = CreateShopItem("mole",        75);
    shopItem[ITEM_MOLE_PROTECTION]  = CreateShopItem("protection",  15);
    shopItem[ITEM_MOLE_REFLECTION]  = CreateShopItem("reflection",  35);
    shopItem[ITEM_MOLE_RETENTION]   = CreateShopItem("retention",   15);

    if (IsNadesAvailable() || GameTypeIsCS() || GameType == dod)
    {
        shopItem[ITEM_GLOVES]       = CreateShopItem("gloves",      65, 25);
    }
    else
    {
        LogMessage("ztf2nades are not available");
        shopItem[ITEM_GLOVES]=-1;
    }

    if (IsTripminesAvailable())
    {
        shopItem[ITEM_TRIPMINE]     = CreateShopItem("tripmine",    60, 5, .max=5);
    }                                               
    else
    {
        LogMessage("Tripmines are not available");
        shopItem[ITEM_TRIPMINE]=-1;
    }

    if (IsFireminesAvailable())
    {
        shopItem[ITEM_FIREMINE]     = CreateShopItem("mine",        35, 0, .max=5);
    }                                               
    else
    {
        LogMessage("Firemines are not available");
        shopItem[ITEM_FIREMINE]=-1;
    }

    if (IsJetpackAvailable())
    {
        shopItem[ITEM_FUEL]         = CreateShopItem("fuel",        25, 50);
    }                                               
    else
    {
        LogMessage("jetpack is not available");
        shopItem[ITEM_FUEL]=-1;
    }

    new Float:cfgEnergyRate = GetConfigFloat("energy_rate");
    new Float:cfgEnergyFactor = GetConfigFloat("energy_factor");
    new bool:defEnergyItem = (cfgEnergyRate < 1.0 || cfgEnergyFactor < 1.0);
    if (GetConfigNum("energy_item", defEnergyItem, SHOPITEM))
    {
        shopItem[ITEM_ENERGY]       = CreateShopItem("energy",       -1,  0, true); // Use all available +crystals
        shopItem[ITEM_ENERGY10]     = CreateShopItem("energy10",     10,  0, true);
        shopItem[ITEM_ENERGY50]     = CreateShopItem("energy50",     50,  0, true);
        shopItem[ITEM_ENERGY100]    = CreateShopItem("energy100",    100, 0, true);
    }
    else
    {
        shopItem[ITEM_ENERGY] = shopItem[ITEM_ENERGY10] = shopItem[ITEM_ENERGY50] = shopItem[ITEM_ENERGY100] = -1;
    }

    // Set the Sidewinder available flag
    IsSidewinderAvailable();

    // Set the Infection available flag
    IsInfectionAvailable();

    LoadSDKToolStuff();
}

public LoadSDKToolStuff()
{
    if (GameTypeIsCS())
    {
        myWepsOffset = FindSendPropInfo("CAI_BaseNPC", "m_hMyWeapons");

        hGameConf = LoadGameConfigFile("plugin.sourcecraft");

        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"UTIL_SetModel");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_String,SDKPass_Pointer);
        hSetModel=EndPrepSDKCall();

        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"UTIL_Remove");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
        hUTILRemove=EndPrepSDKCall();

        StartPrepSDKCall(SDKCall_Entity);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"Weapon_Drop");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_Vector,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
        PrepSDKCall_AddParameter(SDKType_Vector,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
        hWeaponDrop=EndPrepSDKCall();
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "tripmines"))
        IsTripminesAvailable(true);
    else if (StrEqual(name, "firemines"))
        IsFireminesAvailable(true);
    else if (StrEqual(name, "ztf2nades"))
        IsNadesAvailable(true);
    else if (StrEqual(name, "sidewinder"))
        IsSidewinderAvailable(true);
    else if (StrEqual(name, "aia"))
        IsInfiniteAmmoAvailable(true);
    else if (StrEqual(name, "MedicInfect"))
        IsInfectionAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "tripmines"))
        m_TripminesAvailable = false;
    else if (StrEqual(name, "firemines"))
        m_FireminesAvailable = false;
    else if (StrEqual(name, "ztf2nades"))
        m_NadesAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
    else if (StrEqual(name, "aia"))
        m_InfiniteAmmoAvailable = false;
    else if (StrEqual(name, "MedicInfect"))
        m_InfectionAvailable = false;
}

public OnMapStart()
{
    SetupDeniedSound();

    SetupSound(maskSnd);
    SetupSound(bootsWav);
    SetupSound(tomeSound);

    for (new i = 0; i < sizeof(helmSound); i++)
        SetupSound(helmSound[i], false, DONT_DOWNLOAD);
}

public OnMapEnd()
{
    // Kill All Timers and reset Spawn Locations
    for (new i = 1; i <= MaxClients; i++)
    {
        KillNadeTimer(i);
        KillBootTimer(i);
        KillAmmoPackTimer(i);
        KillRegenerationTimer(i);

        m_SpawnLoc[i][0] = m_SpawnLoc[i][1] = m_SpawnLoc[i][2] = 0.0;

        if (GameTypeIsCS())
            KillTrackWeaponsTimer(i);
    }
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public OnPlayerAuthed(client)
{
    TraceInto("ShopItems", "OnPlayerAuthed", "client=%d:%N", \
              client, ValidClientIndex(client));

    for (new index=1;index<=MaxClients;index++)
    {
        m_FireTime[client][index] = 0.0;
        m_FireTime[index][client] = 0.0;
    }

    m_MaskTime[client] = 0.0;
    m_ClawTime[client] = 0.0;

    if (GameTypeIsCS() && vecPlayerWeapons[client] == INVALID_HANDLE)
    {
        vecPlayerWeapons[client]=CreateArray(ByteCountToCells(128));

        TraceCat("Array", "CreateArray vecPlayerWeapons[%d]=%x", \
                 client, vecPlayerWeapons[client]);
    }

    TraceReturn();
}

public OnClientDisconnect(client)
{
    TraceInto("ShopItems", "OnClientDisconnect", "client=%d:%N", \
              client, ValidClientIndex(client));

    SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);

    KillNadeTimer(client);
    KillBootTimer(client);
    KillAmmoPackTimer(client);
    KillRegenerationTimer(client);

    if (GameTypeIsCS())
    {
        KillTrackWeaponsTimer(client);

        new Handle:array = vecPlayerWeapons[client];
        if (array != INVALID_HANDLE)
        {
            CloseHandle(array);
            vecPlayerWeapons[client] = INVALID_HANDLE;

            TraceCat("Array", "CloseArray vecPlayerWeapons[%d]=%x", \
                     client, array);
        }
    }

    TraceReturn();
}

public Action:OnItemPurchaseEx(client,item,&bool:use_pcrystals,&cost,&cost_vespene,&cost_xp)
{
    new Action:returnCode = Plugin_Continue;

    TraceInto("ShopItems", "OnItemPurchaseEx", "client=%d:%N, item=%d, pcrystals=%d, cost=%d", \
              client, ValidClientIndex(client), item, pcrystals, cost);

    if (item == shopItem[ITEM_ENERGY]   ||
        item == shopItem[ITEM_ENERGY10] ||
        item == shopItem[ITEM_ENERGY50] ||
        item == shopItem[ITEM_ENERGY100])
    {
        IncrementEnergy(client, float(cost), false);
        returnCode = Plugin_Handled;
    }

    TraceReturn();
    return returnCode;
}

public OnItemPurchase(client,item)
{
    new Action:returnCode = Plugin_Continue;

    TraceInto("ShopItems", "OnItemPurchase", "client=%d:%N, item=%d", \
              client, ValidClientIndex(client), item);

    if (item==shopItem[ITEM_BOOTS] && IsPlayerAlive(client))             // Boots of Speed
    {
        returnCode = Plugin_Handled;
        PrepareAndEmitSoundToAll(bootsWav,client);
        SetSpeed(client, 1.2, true);
        if (GameType == tf2 && GetMode() != MvM)
            CreateBootTimer(client);
    }
    else if (item==shopItem[ITEM_CLOAK] && IsPlayerAlive(client))        // Cloak of Shadows
    {
        returnCode = Plugin_Handled;
        SetImmunity(client,Immunity_Uncloaking,true);
        if (m_SidewinderAvailable)
            SidewinderCloakClient(client, true);

        if (cfgAllowInvisibility)
            SetVisibility(client, TimedMeleeInvisibility, 0, 1.0, 10.0);
    }
    else if (item==shopItem[ITEM_DARKNESS])                             // Cloak of Darkness
    {
        returnCode = Plugin_Handled;
        SetImmunity(client,Immunity_Detection, true);
        if (m_SidewinderAvailable)
            SidewinderCloakClient(client, true);
    }
    else if (item==shopItem[ITEM_BLINDERS])                              // Blinders
    {
        SetImmunity(client,Immunity_Drugs,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_NECKLACE])                              // Necklace of Immunity
    {
        SetImmunity(client,Immunity_Ultimates,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_JACKET])                                // Flack Jacket
    {
        SetImmunity(client,Immunity_Explosion,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_GOGGLES])                               // Goggles
    {
        SetImmunity(client,Immunity_Blindness,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_LUBE])                                  // Lubricant
    {
        SetImmunity(client,Immunity_MotionTaking,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_LOCKBOX])                               // Lockbox
    {
        SetImmunity(client,Immunity_Theft,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_SILVER])                                // Silver Ammo
    {
        SetImmunity(client,Immunity_Silver,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_PERIAPT] && IsPlayerAlive(client))      // Periapt of Health
    {
        UsePeriapt(client);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_TOME])                                  // Tome of Experience
    {
        returnCode = Plugin_Handled;
        SetOwnsItem(client,shopItem[ITEM_TOME],false);
        SetXP(client,GetRace(client),GetXP(client,GetRace(client))+100);

        DisplayMessage(client, Display_Item | Display_XP,
                       "%t", "GainedTomeXP");

        ShowXP(client, Display_Details);

        if (IsPlayerAlive(client))
        {
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);
            TE_SetupDynamicLight(clientLoc, 255,255,0, 50, 105.0, 10.0, 80.0);
            TE_SendDEffectToAll();

            PrepareAndEmitSoundToAll(tomeSound,client);
        }
        else
        {
            PrepareAndEmitSoundToClient(client,tomeSound);
        }
    }
    else if (item==shopItem[ITEM_SCROLL] && !IsPlayerAlive(client))      // Scroll of Respawning 
    {
        Trace("Scroll of Respawning is respawning %N for the %d time", \
              client,m_ReincarnationCount[client]);

        SetOwnsItem(client,shopItem[ITEM_SCROLL],false);
        RespawnPlayer(client);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_SOCK])                                 // Sock of the Feather
    {
        SetGravity(client, 0.5, true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_TRIPMINE] && IsPlayerAlive(client))    // Tripmine
    {
        returnCode = Plugin_Handled;
        if (m_TripminesAvailable)
        {
            AddTripmines(client, 1);

            // Make sure player knows how to use tripmines
            if (HasTripmines(client, true) > 0)
            {
                PrintToChat(client, "[SC] Bind a key to \"+item 4\" or \"sm_tripmine\" to plant the tripmine.");
            }
        }
        else
            PrintToChat(client, "[SC] Sorry, Tripmines are not available!");
    }
    else if (item==shopItem[ITEM_FIREMINE] && IsPlayerAlive(client))    // Firemine
    {
        returnCode = Plugin_Handled;
        if (m_FireminesAvailable)
        {
            // Make sure player knows how to use mines
            PrintToChat(client, "[SC] Bind a key to \"+item 3\" or \"sm_mine\" to plant the mine.");

            if (HasMines(client, true) > 0)
                AddMines(client, 1);
            else
                GiveMines(client, 1, 0, 3);
        }
        else
            PrintToChat(client, "[SC] Sorry, Mines are not available!");
    }
    else if (item==shopItem[ITEM_GLOVES] && IsPlayerAlive(client))       // Flaming Gloves of Warmth
    {
        returnCode = Plugin_Handled;
        CreateNadeTimer(client);
        if (m_NadesAvailable)
        {
            if (HasFragNades(client, 2) == 0)
            {
                GiveNades(client, 1, 0, 1, 0, false, DefaultNade,
                          _:DamageFrom_ShopItems);

                // Make sure player knows how to use nades
                PrintToChat(client, "[SC] Bind a key to \"+item 1\" or \"+nade1\" to throw a frag nade");
                PrintToChat(client, "[SC] Bind a key to \"+item 2\" or \"+nade2\" to throw a special nade");
                PrintToChat(client, "[SC] Type !nade for more information");
            }
            else
            {
                AddFragNades(client, 1, _:DamageFrom_ShopItems);
                AddSpecialNades(client, 1, _:DamageFrom_ShopItems);
            }
        }
        else
            PrintToChat(client, "[SC] Sorry, Nades are not available!");
    }
    else if (item==shopItem[ITEM_ANTIBIOTIC])                            // Antibiotics
    {
        SetImmunity(client,Immunity_Infection,true);
        returnCode = Plugin_Handled;

        if (m_InfectionAvailable && IsInfected(client))
        {
            HealInfect(client,client);
            new count = GetOwnsItem(client,shopItem[ITEM_ANTIBIOTIC]);
            SetOwnsItem(client,shopItem[ITEM_ANTIBIOTIC],--count);
        }
    }
    else if (item==shopItem[ITEM_ANTIVENOM])                             // Antivenom
    {
        SetImmunity(client,Immunity_Poison,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_ANTIRAD])                               // Antirad
    {
        SetImmunity(client,Immunity_Radiation,true);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_ANTIDOTE])                              // Antidote
    {
        returnCode = Plugin_Handled;
        SetImmunity(client, Immunity_Poison    |
                            Immunity_Infection |
                            Immunity_Radiation , true);

        if (m_InfectionAvailable && IsInfected(client))
            HealInfect(client,client);
    }
    else if (item==shopItem[ITEM_RESTORATION] && IsPlayerAlive(client)) // Potion of Restoration
    {
        returnCode = Plugin_Handled;
        RestorePlayer(client);
        PerformDrug(client, 0);
        PerformBlind(client, 0);
        if (m_InfectionAvailable)
            HealInfect(client);

        SetImmunity(client,Immunity_Restore,true);
        CreateTimer(10.0,ResetRestore,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
        PrintHintText(client, "%t", "RestoreActive", 10.0);
        HudMessage(client, "%t", "RestoreHud");
    }
    else if (item==shopItem[ITEM_PACK] && IsPlayerAlive(client))         // Ammo Pack
    {
        CreateAmmoPackTimer(client);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_AMMO] && IsPlayerAlive(client))         // Infinite Ammo
    {
        returnCode = Plugin_Handled;
        if (m_InfiniteAmmoAvailable)
            SetInfiniteAmmo(client, true, 20.0);
    }
    else if ((item==shopItem[ITEM_RING] ||                               // Rings of Regeneration
                item==shopItem[ITEM_RING3] ||
                item==shopItem[ITEM_RING5]) &&
            IsPlayerAlive(client))
    {
        CreateRegenerationTimer(client);
        returnCode = Plugin_Handled;
    }
    else if (item==shopItem[ITEM_ANKH] && IsPlayerAlive(client))         // Ankh of Reincarnation
    {
        returnCode = Plugin_Handled;
        if (GameTypeIsCS())
            CreateTrackWeaponsTimer(client);
    }
    else if (item==shopItem[ITEM_FUEL])                                  // Fuel
    {
        returnCode = Plugin_Handled;
        if (m_JetpackAvailable)
        {
            GiveJetpackFuel(client, 100);
            SetOwnsItem(client,shopItem[ITEM_FUEL],false);
            DisplayMessage(client, Display_Item, "%t", "AddedFuel");
        }                       
    }

    TraceReturn();
    return _:returnCode;
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (IsClient(client))
    {
        for (new index=1;index<=MaxClients;index++)
        {
            m_FireTime[client][index] = 0.0;
            m_FireTime[index][client] = 0.0;
        }

        GetClientAbsOrigin(client,m_SpawnLoc[client]);
        m_MaskTime[client] = 0.0;
        m_ClawTime[client] = 0.0;

        if (GetRestriction(client, Restriction_NoShopItems) ||
            GetRestriction(client, Restriction_Stunned))
        {
            DisplayMessage(client, Display_Item, "%t",
                           "PreventedFromItems");
        }
        else
        {
            if (GameTypeIsCS())
            {
                if (GetOwnsItem(client,shopItem[ITEM_ANKH]))                         // Ankh of Reincarnation
                {
                    decl String:wepName[128];
                    new size=GetArraySize(vecPlayerWeapons[client]);
                    new Handle:pack = CreateDataPack();
                    WritePackCell(pack, GetClientUserId(client));
                    WritePackCell(pack, size);
                    for(new x=0;x<size;x++)
                    {
                        GetArrayString(vecPlayerWeapons[client],x,wepName,sizeof(wepName));
                        WritePackString(pack, wepName);
                    }
                    SetOwnsItem(client,shopItem[ITEM_ANKH],false);
                    CreateTimer(0.2,Ankh,pack,TIMER_FLAG_NO_MAPCHANGE);
                }
            }

            if (GetOwnsItem(client,shopItem[ITEM_BOOTS]))                           // Boots of Speed
            {
                SetSpeed(client,1.2);
                StopSound(client,SNDCHAN_AUTO,bootsWav);
                PrepareAndEmitSoundToAll(bootsWav,client);
                if (GetGameType() == tf2 && GetMode() != MvM)
                    CreateBootTimer(client);
            }

            if (GetOwnsItem(client,shopItem[ITEM_CLOAK]))                           // Cloak of Shadows
            {
                SetImmunity(client,Immunity_Uncloaking,true);
                if (m_SidewinderAvailable)
                    SidewinderCloakClient(client, true);

                if (cfgAllowInvisibility)
                    SetVisibility(client, TimedMeleeInvisibility, 0, 1.0, 10.0);
            }

            if (GetOwnsItem(client,shopItem[ITEM_DARKNESS]))                        // Cloak of Darkness
            {
                SetImmunity(client,Immunity_Detection, true);
                if (m_SidewinderAvailable)
                    SidewinderCloakClient(client, true);
            }

            if (GetOwnsItem(client,shopItem[ITEM_BLINDERS]))                        // Blinders
                SetImmunity(client,Immunity_Drugs,true);

            if (GetOwnsItem(client,shopItem[ITEM_NECKLACE]))                        // Necklace of Immunity
                SetImmunity(client,Immunity_Ultimates,true);

            if (GetOwnsItem(client,shopItem[ITEM_JACKET]))                          // Flack Jacket
                SetImmunity(client,Immunity_Explosion,true);

            if (GetOwnsItem(client,shopItem[ITEM_GOGGLES]))                         // Goggles
                SetImmunity(client,Immunity_Blindness,true);

            if (GetOwnsItem(client,shopItem[ITEM_LUBE]))                            // Lubricant
                SetImmunity(client,Immunity_MotionTaking,true);

            if (GetOwnsItem(client,shopItem[ITEM_LOCKBOX]))                         // Lockbox
                SetImmunity(client,Immunity_Theft,true);

            if (GetOwnsItem(client,shopItem[ITEM_SILVER]))                          // Silver Ammo
                SetImmunity(client,Immunity_Silver,true);

            if (GetOwnsItem(client,shopItem[ITEM_ANTIVENOM]))                       // Antivenom
                SetImmunity(client,Immunity_Poison,true);

            if (GetOwnsItem(client,shopItem[ITEM_ANTIRAD]))                         // Antirad
                SetImmunity(client,Immunity_Radiation,true);

            if (GetOwnsItem(client,shopItem[ITEM_ANTIDOTE]))                        // Antidote
            {
                SetImmunity(client, Immunity_Poison    |
                                    Immunity_Infection |
                                    Immunity_Radiation , true);
            }

            if (GetOwnsItem(client,shopItem[ITEM_RESTORATION]))                     // Potion of Restoration
            {
                SetImmunity(client,Immunity_Restore,true);
                PrintHintText(client, "You have 10 seconds of Restoration!");
                CreateTimer(10.0,ResetRestore,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
            }

            if (GetOwnsItem(client,shopItem[ITEM_PERIAPT]) && !m_UsedPeriapt[client]) // Periapt of Health
                CreateTimer(0.1,DoPeriapt,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);

            if (GetOwnsItem(client,shopItem[ITEM_SOCK]))                            // Sock of the Feather
                SetGravity(client,0.5);

            if (GetOwnsItem(client,shopItem[ITEM_PACK]))                            // Ammo Pack
                CreateAmmoPackTimer(client);

            if (GetOwnsItem(client,shopItem[ITEM_PACK]))                            // Infinite Ammo
            {
                if (m_InfiniteAmmoAvailable)
                    SetInfiniteAmmo(client, true, 20.0);
                else                
                    CreateAmmoPackTimer(client);
            }

            if (GetOwnsItem(client,shopItem[ITEM_GLOVES]))                          // Flaming Gloves of Warmth
            {
                CreateNadeTimer(client);
                if (m_NadesAvailable)
                {
                    if (HasFragNades(client, 2) == 0)
                    {
                        GiveNades(client, 1, 0, 1, 0, false, DefaultNade,
                                _:DamageFrom_ShopItems);

                        // Make sure player knows how to use nades
                        PrintToChat(client, "[SC] Bind a key to \"+item 1\" or \"+nade1\" to throw a frag nade");
                        PrintToChat(client, "[SC] Bind a key to \"+item 2\" or \"+nade2\" to throw a special nade");
                        PrintToChat(client, "[SC] Type !nade for more information");
                    }
                    else
                    {
                        AddFragNades(client, 1, _:DamageFrom_ShopItems);
                        AddSpecialNades(client, 1, _:DamageFrom_ShopItems);
                    }
                }
            }

            if (GetOwnsItem(client,shopItem[ITEM_TRIPMINE]))                        // Tripmine
            {
                if (m_TripminesAvailable)
                {
                    // Make sure player knows how to use tripmines
                    PrintToChat(client, "[SC] Bind a key to \"+item 4\" or \"sm_tripmine\" to plant the tripmine.");

                    if (HasTripmines(client, true) > 0)
                        AddTripmines(client, 1);
                    else
                        GiveTripmines(client, 1, 0, 1);
                }
            }

            if (GetOwnsItem(client,shopItem[ITEM_FIREMINE]))                        // Firemine
            {
                if (m_FireminesAvailable)
                {
                    // Make sure player knows how to use mines
                    PrintToChat(client, "[SC] Bind a key to \"+item 3\" or \"sm_mine\" to plant the mine.");

                    if (HasMines(client, true) > 0)
                        AddMines(client, 1);
                    else
                        GiveMines(client, 1, 0, 3);
                }
            }

            if (GetOwnsItem(client,shopItem[ITEM_RING]) ||                          // Rings of Regeneration
                GetOwnsItem(client,shopItem[ITEM_RING3]) ||
                GetOwnsItem(client,shopItem[ITEM_RING5]))
            {
                CreateRegenerationTimer(client);
            }

            if (GetOwnsItem(client,shopItem[ITEM_MOLE]))                            // Mole
            {
                // We need to check to use mole, or did we JUST use it?
                if (m_IsMole[client])
                {
                    // we already used it, take it away
                    SetOwnsItem(client,shopItem[ITEM_MOLE],false);
                    SetAttribute(client, Attribute_IsAMole,false);
                    m_IsMole[client]=false;
                }
                else
                    CreateTimer(0.1,DoMole,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
            }
            else
            {
                SetAttribute(client, Attribute_IsAMole,false);
                m_IsMole[client]=false;
            }
        }
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    TraceInto("ShopItems", "OnPlayerDeathEvent", "victim_index=%d:%N, victim_race=%d, attacker_index=%d:%N, attacker_race=%d", \
              victim_index, ValidClientIndex(victim_index), victim_race, \
              attacker_index, ValidClientIndex(attacker_index), attacker_race);

    KillNadeTimer(victim_index);
    KillBootTimer(victim_index);
    KillAmmoPackTimer(victim_index);
    KillRegenerationTimer(victim_index);
    KillRegenerationTimer(victim_index);

    if (GameTypeIsCS())
        KillTrackWeaponsTimer(victim_index);

    // Reset player speed/gravity/visibility attributes when they die
    SetSpeed(victim_index,-1.0);
    SetGravity(victim_index,-1.0);
    SetVisibility(victim_index, NormalVisibility);

    // Reset Overrides when players die
    SetOverrideSpeed(victim_index,-1.0);

    // Reset MaxHealth back to normal
    if (m_UsedPeriapt[victim_index])
    {
        m_UsedPeriapt[victim_index]=false;
        ResetMaxHealth(victim_index);

        if (GetOwnsItem(victim_index,shopItem[ITEM_PERIAPT]))
            SetOwnsItem(victim_index,shopItem[ITEM_PERIAPT],false);
    }

    if (GetOwnsItem(victim_index,shopItem[ITEM_MAGNIFYER]))
        SetOwnsItem(victim_index,shopItem[ITEM_MAGNIFYER],false);

    if (!GetImmunity(victim_index,Immunity_ShopItems) &&
        !GetImmunity(victim_index,Immunity_Theft))
    {
        if (victim_index != attacker_index)
        {
            if (IsClient(attacker_index))
            {
                if (GetOwnsItem(attacker_index,shopItem[ITEM_SACK]))
                    LootCorpse(event, victim_index, attacker_index);
            }

            if (IsClient(assister_index))
            {
                if (GetOwnsItem(assister_index,shopItem[ITEM_SACK]))
                    LootCorpse(event, victim_index, assister_index);
            }
        }
    }

    new bool:hasAnkh      = (GetOwnsItem(victim_index,shopItem[ITEM_ANKH]) > 0);
    new bool:isRestricted = GetRestriction(victim_index, Restriction_NoShopItems) ||
                            GetRestriction(victim_index, Restriction_Stunned);

    if (!hasAnkh || isRestricted)
    {
        if (GetOwnsItem(victim_index,shopItem[ITEM_MASK]))
            SetOwnsItem(victim_index,shopItem[ITEM_MASK],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_CLAWS]))
            SetOwnsItem(victim_index,shopItem[ITEM_CLAWS],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_ORB_FROST]))
            SetOwnsItem(victim_index,shopItem[ITEM_ORB_FROST],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_ORB_FIRE]))
            SetOwnsItem(victim_index,shopItem[ITEM_ORB_FIRE],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_SOCK]))
            SetOwnsItem(victim_index,shopItem[ITEM_SOCK],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_GLOVES]))
            SetOwnsItem(victim_index,shopItem[ITEM_GLOVES],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_PACK]))
            SetOwnsItem(victim_index,shopItem[ITEM_PACK],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_AMMO]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_AMMO],false);
            if (m_InfiniteAmmoAvailable)
                SetInfiniteAmmo(victim_index, false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_HELM]))
            SetOwnsItem(victim_index,shopItem[ITEM_HELM],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_SACK]))
            SetOwnsItem(victim_index,shopItem[ITEM_SACK],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_BOOTS]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_BOOTS],false);
            StopSound(victim_index,SNDCHAN_AUTO,bootsWav);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_CLOAK]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_CLOAK],false);
            SetImmunity(victim_index,Immunity_Uncloaking,false);
            if (m_SidewinderAvailable)
                SidewinderCloakClient(victim_index, false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_DARKNESS]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_DARKNESS],false);
            SetImmunity(victim_index,Immunity_Detection, false);
            if (m_SidewinderAvailable)
                SidewinderCloakClient(victim_index, false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_NECKLACE]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_NECKLACE],false);
            SetImmunity(victim_index,Immunity_Ultimates,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_JACKET]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_JACKET],false);
            SetImmunity(victim_index,Immunity_Explosion,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_SILVER]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_SILVER],false);
            SetImmunity(victim_index,Immunity_Silver,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_GOGGLES]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_GOGGLES],false);
            SetImmunity(victim_index,Immunity_Blindness,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_LUBE]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_LUBE],false);
            SetImmunity(victim_index,Immunity_MotionTaking,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_LOCKBOX]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_LOCKBOX],false);
            SetImmunity(victim_index,Immunity_Theft,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_ANTIBIOTIC]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_ANTIBIOTIC],false);
            SetImmunity(victim_index,Immunity_Infection,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_ANTIVENOM]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_ANTIVENOM],false);
            SetImmunity(victim_index,Immunity_Poison,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_ANTIRAD]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_ANTIRAD],false);
            SetImmunity(victim_index,Immunity_Radiation,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_ANTIDOTE]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_ANTIDOTE],false);
            SetImmunity(victim_index,Immunity_Poison    |
                                     Immunity_Infection |
                                     Immunity_Radiation , false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_RESTORATION]))
        {
            SetOwnsItem(victim_index,shopItem[ITEM_RESTORATION],false);
            SetImmunity(victim_index,Immunity_Restore,false);
        }

        if (GetOwnsItem(victim_index,shopItem[ITEM_RING]))
            SetOwnsItem(victim_index,shopItem[ITEM_RING],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_RING3]))
            SetOwnsItem(victim_index,shopItem[ITEM_RING3],false);

        if (GetOwnsItem(victim_index,shopItem[ITEM_RING5]))
            SetOwnsItem(victim_index,shopItem[ITEM_RING5],false);

        if (m_TripminesAvailable)
        {
            new numTripmines = GetOwnsItem(victim_index,shopItem[ITEM_TRIPMINE]);
            if (numTripmines > 0)
            {
                SetOwnsItem(victim_index,shopItem[ITEM_TRIPMINE],false);
                if (HasTripmines(victim_index, true) > 0)
                    SubTripmines(victim_index, numTripmines);
                else
                    TakeTripmines(victim_index);
            }
        }

        if (m_FireminesAvailable)
        {
            new numFiremines = GetOwnsItem(victim_index,shopItem[ITEM_FIREMINE]);
            if (numFiremines > 0)
            {
                SetOwnsItem(victim_index,shopItem[ITEM_FIREMINE],false);
                if (HasMines(victim_index, true) > 0)
                    SubMines(victim_index, numFiremines);
                else
                    TakeMines(victim_index);
            }
        }

        if (!GetOwnsItem(victim_index,shopItem[ITEM_MOLE_RETENTION]))
        {
            if(GetOwnsItem(victim_index,shopItem[ITEM_MOLE_PROTECTION]))
                SetOwnsItem(victim_index,shopItem[ITEM_MOLE_PROTECTION],false);

            if(GetOwnsItem(victim_index,shopItem[ITEM_MOLE_REFLECTION]))
                SetOwnsItem(victim_index,shopItem[ITEM_MOLE_REFLECTION],false);
        }
    }

    if (hasAnkh)
    {
        SetOwnsItem(victim_index,shopItem[ITEM_ANKH],false);

        if (isRestricted)
        {
            PrepareAndEmitSoundToClient(victim_index,deniedWav);
            DisplayMessage(victim_index, Display_Item, "%t",
                           "PreventedFromRetaining");
        }
    }

    if (m_IsMole[victim_index])
    {
        if (GetOwnsItem(victim_index,shopItem[ITEM_MOLE]))
        {
            // We used the mole, take it away
            SetOwnsItem(victim_index,shopItem[ITEM_MOLE],false);
        }
    }

    if (GetOwnsItem(victim_index,shopItem[ITEM_SCROLL]))
    {
        if (m_IsMole[victim_index])
        {
            m_ReincarnationCount[victim_index] = 0;
            PrepareAndEmitSoundToClient(victim_index,deniedWav);

            decl String:itemName[64];
            GetItemName(shopItem[ITEM_SCROLL], itemName, sizeof(itemName), victim_index);
            DisplayMessage(victim_index, Display_Item, "%t",
                           "CantUseAsMole", itemName);
        }
        else if (!isRestricted)
        {
            m_ReincarnationCount[victim_index] = 0;
            PrepareAndEmitSoundToClient(victim_index,deniedWav);
            DisplayMessage(victim_index, Display_Item, "%t",
                           "PreventedFromRespawning");
        }
        else
        {
            Trace("Scroll of Respawning is respawning %d:%N for the %d time", \
                  victim_index, ValidClientIndex(victim_index), \
                  m_ReincarnationCount[victim_index]);

            SetOwnsItem(victim_index,shopItem[ITEM_SCROLL],false);
            CreateTimer(0.1,RespawnPlayerHandler, GetClientUserId(victim_index),TIMER_FLAG_NO_MAPCHANGE);
        }
    }

    TraceReturn();
}

public Action:OnXPGiven(client,&amount,bool:taken)
{
    if (GetOwnsItem(client,shopItem[ITEM_MAGNIFYER]) &&
        !GetRestriction(client, Restriction_NoShopItems) &&
        !GetRestriction(client, Restriction_Stunned))
    {
        amount=RoundToNearest(float(amount)*1.5);
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action:OnInfected(victim,infector,source,bool:infected,const color[4])
{
    if (infected)
    {
        new count = GetOwnsItem(victim,shopItem[ITEM_ANTIBIOTIC]);
        if (count >= 1)
        {
            SetOwnsItem(victim,shopItem[ITEM_ANTIBIOTIC],--count);

            if (count <= 0 && !GetOwnsItem(victim,shopItem[ITEM_ANTIDOTE]))
                SetImmunity(victim,Immunity_Infection,false);

            return Plugin_Stop;
        }
        else if (GetOwnsItem(victim,shopItem[ITEM_ANTIDOTE]))
            return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action:OnSetTripmine(client)
{
    if (m_IsMole[client] || GetAttribute(client, Attribute_IsAMole))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);

        decl String:itemName[64];
        GetItemName(shopItem[ITEM_TRIPMINE], itemName, sizeof(itemName), client);
        DisplayMessage(client, Display_Item, "%t", "CantUseAsMole", itemName);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action:OnSetMine(client)
{
    if (m_IsMole[client] || GetAttribute(client, Attribute_IsAMole))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);

        decl String:itemName[64];
        GetItemName(shopItem[ITEM_FIREMINE], itemName, sizeof(itemName), client);
        DisplayMessage(client, Display_Item, "%t", "CantUseAsMole", itemName);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
    if (hitgroup == 1 &&
        GetOwnsItem(victim, shopItem[ITEM_HELM]) &&
        !GetRestriction(victim, Restriction_NoShopItems) &&
        !GetRestriction(victim, Restriction_Stunned))
    {
        damage=0.0;
        PrepareAndEmitSoundToAll(helmSound[GetRandomInt(0,3)],victim);

        if (GameType == tf2 && GetMode() != MvM)
        {
            decl Float:pos[3];
            GetClientEyePosition(victim, pos);
            pos[2] += 4.0;
            TE_SetupParticle("miss_text", pos);
            TE_SendToClient(attacker);
        }
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public OnCabinetUsed(client,entity)
{
    if (m_IsMole[client])
    {
        new health = GetClientHealth(client);
        new old_health = m_MoleHealth[client];
        if (health > old_health && old_health > 0)
            SetEntityHealth(client, old_health);
    }
}

public Action:ResetHealth(Handle:timer,any:pack)
{
    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        new client=ReadPackCell(pack);
        new health=ReadPackCell(pack);
        if (GetClientHealth(client) > health)
            SetEntityHealth(client, health);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new bool:handled     = false;
    new bool:itemInvoked = false;

    if (victim_index > 0 && victim_index != attacker_index)
    {
        damage += absorbed;

        #if defined HEALTH_ADDS_ARMOR
            if (absorbed > 0 &&
                GetOwnsItem(victim_index,shopItem[ITEM_PERIAPT]))
            {
                ShowHealthParticle(victim_index);
            }
        #endif

        if (IsClient(attacker_index))
        {
            if (m_IsMole[attacker_index])
            {
                new reflection = GetOwnsItem(victim_index,shopItem[ITEM_MOLE_REFLECTION]);
                new protection = GetOwnsItem(victim_index,shopItem[ITEM_MOLE_PROTECTION]);
                if (reflection || protection)
                {
                    new victim_health = GetClientHealth(victim_index);
                    new prev_health   = victim_health+damage;
                    new new_health    = (victim_health+prev_health)/2;

                    if (new_health <= victim_health)
                        new_health = victim_health+(damage/2);

                    if (reflection && protection && GetRandomInt(1,100)<=50)
                        new_health += (damage*GetRandomFloat(0.25,0.75));

                    new amount = new_health-victim_health;
                    handled=true;

                    if (reflection)
                    {
                        // Don't allow Restore Immunity for moles.
                        if(!GetImmunity(attacker_index,Immunity_ShopItems) &&
                           !GetImmunity(attacker_index,Immunity_HealthTaking) &&
                           !IsInvulnerable(attacker_index))
                        {
                            new reflect=RoundToNearest(damage * GetRandomFloat(0.50,1.10));
                            FlashScreen(attacker_index,RGBA_COLOR_RED);
                            HurtPlayer(attacker_index, reflect, victim_index,
                                       "sc_mole_reflection", .xp=10,
                                       .in_hurt_event=true);

                            if (amount < reflect)
                            {
                                new_health += reflect - amount;
                                amount = reflect;
                            }
                        }

                        decl String:itemName[64];
                        GetItemName(shopItem[ITEM_MOLE_REFLECTION], itemName, sizeof(itemName), victim_index);
                        DisplayMessage(victim_index, Display_Item | Display_Defense,
                                       "%t", "ReceivedHPFrom", amount, attacker_index,
                                       itemName);
                    }
                    else
                    {
                        decl String:itemName[64];
                        GetItemName(shopItem[ITEM_MOLE_PROTECTION], itemName, sizeof(itemName), victim_index);
                        DisplayMessage(victim_index, Display_Item | Display_Defense,
                                       "%t", "ReceivedHP", amount, itemName);
                    }

                    if (new_health > victim_health)
                    {
                        new max_health = (GameType == tf2) ? TF2_GetPlayerResourceData(attacker_index, TFResource_MaxHealth) : 100;
                        if (victim_health < max_health)
                        {
                            SetEntityHealth(victim_index,(new_health>max_health) ? max_health : new_health);
                            FlashScreen(victim_index,RGBA_COLOR_GREEN);
                            ShowHealthParticle(victim_index);
                        }
                    }

                    if (GetOwnsItem(victim_index,shopItem[ITEM_MOLE_RETENTION]))
                    {
                        SetOwnsItem(victim_index,shopItem[ITEM_MOLE_RETENTION],false);
                        DisplayMessage(victim_index, Display_Item, "%t", "UsedMoleRetention");
                    }
                }
            }

            if (!from_sc && !GetImmunity(victim_index,Immunity_ShopItems) &&
                !GetRestriction(attacker_index, Restriction_NoShopItems) &&
                !GetRestriction(attacker_index, Restriction_Stunned))
            {
                if (!IsInvulnerable(victim_index))
                {
                    if (!GetImmunity(victim_index,Immunity_HealthTaking))
                    {
                        if (IsClient(victim_index) &&
                            !GetImmunity(victim_index,Immunity_Burning))
                        {
                            if (GetOwnsItem(attacker_index,shopItem[ITEM_ORB_FIRE]))
                            {
                                new Float:lastTime =  m_FireTime[attacker_index][victim_index];
                                if (lastTime == 0.0 || GetGameTime() - lastTime > 10.0)
                                {
                                    if (GameType == tf2)
                                        TF2_IgnitePlayer(victim_index, attacker_index);
                                    else if (GameType == dod)
                                        DOD_IgniteEntity(victim_index, 10.0);
                                    else
                                        IgniteEntity(victim_index, 10.0);

                                    itemInvoked = true;
                                    m_FireTime[attacker_index][victim_index] = GetGameTime();
                                    DisplayMessage(victim_index, Display_Enemy_Item,
                                                   "%t", "SetOnFireWithOrb", attacker_index);
                                }
                            }
                        }

                        if (!itemInvoked && GetOwnsItem(attacker_index,shopItem[ITEM_CLAWS]))
                        {
                            new Float:lastTime = m_ClawTime[attacker_index];
                            if (lastTime == 0.0 || GetGameTime() - lastTime > 0.25)
                            {
                                new amount=RoundToCeil(float(damage)*0.25);
                                if (amount < 1)
                                    amount = 1;
                                else if (amount > 8)
                                    amount = 8;

                                if (GameType != tf2 || GetMode() != MvM)
                                {
                                    new entities = EntitiesAvailable(200, .message="Reducing Effects");
                                    if (entities > 50)
                                        CreateParticle("blood_impact_red_01_chunk", 0.1, victim_index, Attach, "head");
                                }

                                handled=true;
                                itemInvoked = true;
                                m_ClawTime[attacker_index] = GetGameTime();

                                FlashScreen(victim_index,RGBA_COLOR_RED);
                                HurtPlayer(victim_index, amount, attacker_index,
                                           "sc_item_claws", .type=DMG_SLASH,
                                           .in_hurt_event=true);
                            }
                        }
                    }

                    if (!itemInvoked && IsClient(victim_index) &&
                        !GetImmunity(victim_index,Immunity_MotionTaking) &&
                        !GetImmunity(victim_index,Immunity_Freezing) &&
                        !GetImmunity(victim_index,Immunity_Restore))
                    {
                        if (GetOwnsItem(attacker_index,shopItem[ITEM_ORB_FROST]))
                        {
                            itemInvoked = true;
                            SetOverrideSpeed(victim_index, 0.5);
                            FlashScreen(victim_index,RGBA_COLOR_BLUE);
                            SetVisibility(victim_index, BasicVisibility,
                                          .visibility=192, 
                                          .mode=RENDER_TRANSCOLOR,
                                          .r=((GetClientTeam(victim_index) == _:TFTeam_Red) ? 255 : 0),
                                          .g=128, .b=255, .apply=true);

                            CreateTimer(5.0,RestoreSpeed, GetClientUserId(victim_index),TIMER_FLAG_NO_MAPCHANGE);
                            DisplayMessage(victim_index, Display_Enemy_Item, "%t",
                                           "FrozenWithOrb", attacker_index);
                        }
                    }
                }

                if (GetOwnsItem(attacker_index,shopItem[ITEM_MASK]))
                {
                    if (!itemInvoked && IsValidClientAlive(attacker_index))
                    {
                        new health = GetClientHealth(attacker_index);
                        new max_health = (GameType == tf2) ? TF2_GetPlayerResourceData(attacker_index, TFResource_MaxHealth) : 100;
                        if (health > 0 && health <= max_health-2)
                        {
                            handled=true;
                            itemInvoked = true;
                            ShowHealthParticle(attacker_index);
                            SetEntityHealth(attacker_index,health+2);
                            FlashScreen(attacker_index,RGBA_COLOR_GREEN);

                            decl String:itemName[64];
                            GetItemName(shopItem[ITEM_MASK], itemName, sizeof(itemName), attacker_index);
                            if (IsClient(victim_index))
                            {
                                DisplayMessage(attacker_index, Display_Item | Display_Defense,
                                               "%t", "ReceivedHPFrom", 2, victim_index,
                                               itemName);
                            }
                            else
                            {
                                DisplayMessage(attacker_index, Display_Item | Display_Defense,
                                               "%t", "ReceivedHP", 2, itemName);
                            }

                            new Float:lastTime = m_MaskTime[attacker_index];
                            if (lastTime == 0.0 || GetGameTime() - lastTime > 0.25)
                            {
                                PrepareAndEmitSoundToAll(maskSnd,attacker_index);
                                m_MaskTime[attacker_index] = GetGameTime();
                            }

                            if (IsClient(victim_index))
                            {
                                lastTime = m_MaskTime[victim_index];
                                if (lastTime == 0.0 || GetGameTime() - lastTime > 0.25)
                                {
                                    PrepareAndEmitSoundToAll(maskSnd,attacker_index);
                                    m_MaskTime[victim_index] = GetGameTime();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (IsClient(victim_index) && m_IsMole[victim_index])
        m_MoleHealth[victim_index] = GetClientHealth(victim_index);

    return handled ? Plugin_Handled : Plugin_Continue;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    new bool:handled=false;
    new bool:itemInvoked = false;

    if (!GetImmunity(victim_index,Immunity_ShopItems) &&
        !GetRestriction(assister_index, Restriction_NoShopItems) &&
        !GetRestriction(assister_index, Restriction_Stunned))
    {
        if (!IsInvulnerable(victim_index))
        {
            if (!GetImmunity(victim_index,Immunity_HealthTaking))
            {
                if (GetOwnsItem(assister_index,shopItem[ITEM_CLAWS]))
                {
                    new Float:lastTime = m_ClawTime[assister_index];
                    if (lastTime == 0.0 || GetGameTime() - lastTime > 0.25)
                    {
                        new amount=RoundToFloor(float(damage)*0.25);
                        if (amount < 1)
                            amount = 1;
                        else if (amount > 8)
                            amount = 8;

                        if (GameType != tf2 || GetMode() != MvM)
                        {
                            new entities = EntitiesAvailable(200, .message="Reducing Effects");
                            if (entities > 50)
                                CreateParticle("blood_impact_red_01_chunk", 0.1, victim_index, Attach, "head");
                        }

                        handled=true;
                        itemInvoked = true;
                        m_ClawTime[assister_index] = GetGameTime();

                        FlashScreen(victim_index,RGBA_COLOR_RED);
                        HurtPlayer(victim_index,amount,assister_index,
                                   "sc_item_claws", .type=DMG_SLASH,
                                   .in_hurt_event=true);
                    }
                }

                if (!itemInvoked && IsClient(victim_index) &&
                    !GetImmunity(victim_index,Immunity_Burning))
                {
                    if (GetOwnsItem(assister_index,shopItem[ITEM_ORB_FIRE]))
                    {
                        new Float:lastTime = IsClient(victim_index) ? m_FireTime[assister_index][victim_index] : 0.0;
                        if (lastTime == 0.0 || GetGameTime() - lastTime > 10.0)
                        {
                            TF2_IgnitePlayer(victim_index, assister_index);
                            m_FireTime[assister_index][victim_index] = GetGameTime();
                            DisplayMessage(victim_index, Display_Enemy_Item, "%t",
                                           "SetOnFireWithOrb", assister_index);
                        }
                    }
                }
            }

            if (!itemInvoked && IsClient(victim_index) &&
                !GetImmunity(victim_index,Immunity_MotionTaking) &&
                !GetImmunity(victim_index,Immunity_Freezing) &&
                !GetImmunity(victim_index,Immunity_Restore))
            {
                if (GetOwnsItem(assister_index,shopItem[ITEM_ORB_FROST]))
                {
                    itemInvoked = true;
                    SetOverrideSpeed(victim_index, 0.5);
                    FlashScreen(victim_index,RGBA_COLOR_BLUE);
                    SetVisibility(victim_index, BasicVisibility,
                                  .visibility=192, 
                                  .mode=RENDER_TRANSCOLOR,
                                  .r=((GetClientTeam(victim_index) == _:TFTeam_Red) ? 255 : 0),
                                  .g=128, .b=255, .apply=true);

                    CreateTimer(5.0,RestoreSpeed, GetClientUserId(victim_index),TIMER_FLAG_NO_MAPCHANGE);
                    DisplayMessage(victim_index, Display_Enemy_Item, "%t",
                                   "FrozenWithOrb", assister_index);
                }
            }
        }

        if (!itemInvoked && GetOwnsItem(assister_index,shopItem[ITEM_MASK]))
        {
            new health = GetClientHealth(assister_index);
            new max_health = (GameType == tf2) ? TF2_GetPlayerResourceData(assister_index, TFResource_MaxHealth) : 100;
            if (health > 0 && health <= max_health-2)
            {
                handled=true;
                PrepareAndEmitSoundToAll(maskSnd,assister_index);
                ShowHealthParticle(assister_index);
                SetEntityHealth(assister_index,health+2);
                FlashScreen(assister_index,RGBA_COLOR_GREEN);

                decl String:itemName[64];
                GetItemName(shopItem[ITEM_MASK], itemName, sizeof(itemName), assister_index);

                if (IsValidClient(victim_index))
                {
                    DisplayMessage(assister_index, Display_Item | Display_Defense, "%t",
                                   "ReceivedHPFrom", 2, victim_index, itemName);
                }
                else
                {
                    decl String:victimName[64];
                    GetEntityName(victim_index, victimName, sizeof(victimName));
                    DisplayMessage(assister_index, Display_Item | Display_Defense, "%t",
                                   "ReceivedHPFromEnt", 2, victimName, itemName);
                }

                new Float:lastTime = m_MaskTime[assister_index];
                if (lastTime == 0.0 || GetGameTime() - lastTime > 0.25)
                {
                    PrepareAndEmitSoundToAll(maskSnd,assister_index);
                    m_MaskTime[assister_index] = GetGameTime();
                }

                if (IsClient(victim_index))
                {
                    lastTime = m_MaskTime[victim_index];
                    if (lastTime == 0.0 || GetGameTime() - lastTime > 0.25)
                    {
                        PrepareAndEmitSoundToAll(maskSnd,assister_index);
                        m_MaskTime[victim_index] = GetGameTime();
                    }
                }
            }
        }
    }

    return handled ? Plugin_Handled : Plugin_Continue;
}

public EventRoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        // Reset Spawn locations in case the spawn points move.
        m_SpawnLoc[index][0] = m_SpawnLoc[index][1] = m_SpawnLoc[index][2] = 0.0;

        if (IsClientInGame(index))
        {
            SetSpeed(index,-1.0);
            SetGravity(index,-1.0);
            SetVisibility(index, NormalVisibility);
        }
    }
}

public Action:ItemCommand(client,args)
{
    TraceInto("ShopItems", "ItemCommand");

    if (IsValidClientAlive(client))
    {
        if (GetRestriction(client, Restriction_NoShopItems) ||
            GetRestriction(client, Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Item, "%t", "PreventedFromItems");
        }
        else
        {
            decl String:command[32];
            GetCmdArg(0,command,sizeof(command));
            new bool:pressed=(!strcmp(command,"+item"));

            new arg;
            decl String:argString[16];
            if (GetCmdArgs() >= 2)
            {
                GetCmdArg(1,argString,sizeof(argString));
                arg = StringToInt(argString);
            }
            else
            {
                arg = 1;

                #if defined _TRACE
                    argString[0] = '\0';
                #endif
            }

            Trace("%N issuing +item %s(%d), pressed=%d, CmdArgs=%d", \
                  client, argString, arg, pressed, GetCmdArgs());

            for (;(arg <= 4); arg++)
            {
                switch (arg)
                {
                    case 1: // Flaming Gloves of Warmth (+nade1)
                    {
                        if (m_NadesAvailable && GetOwnsItem(client,shopItem[ITEM_GLOVES]))
                        {
                            ThrowFragNade(client, pressed);
                            break;
                        }
                    }
                    case 2: // Flaming Gloves of Warmth (+nade2)
                    {
                        if (m_NadesAvailable && GetOwnsItem(client,shopItem[ITEM_GLOVES]))
                        {
                            ThrowSpecialNade(client, pressed);
                            break;
                        }
                    }
                    case 3: // Firemine (sm_mine)
                    {
                        if (m_FireminesAvailable && GetOwnsItem(client,shopItem[ITEM_FIREMINE]) > 0)
                        {
                            SetMine(client, true);
                            break;
                        }
                    }
                    case 4: // Tripmine (sm_tripmine)
                    {
                        if (m_TripminesAvailable && GetOwnsItem(client,shopItem[ITEM_TRIPMINE]) > 0)
                        {
                            SetTripmine(client);
                            break;
                        }
                    }
                }
            }

            Trace("%N completed +item %s, pressed=%d", client, arg, pressed);
        }
    }

    TraceReturn();
    return Plugin_Handled;
}

// Item specific
public Action:RestoreSpeed(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        SetOverrideSpeed(client,-1.0);
        SetVisibility(client, NormalVisibility);
    }
    return Plugin_Stop;
}

public Action:Regeneration(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client) &&
        !GetRestriction(client, Restriction_NoShopItems) &&
        !GetRestriction(client, Restriction_Stunned))
    {
        new addhp = GetOwnsItem(client,shopItem[ITEM_RING]); // * 1;
        addhp += GetOwnsItem(client,shopItem[ITEM_RING3]) * 3;
        addhp += GetOwnsItem(client,shopItem[ITEM_RING5]) * 5;

        if (addhp > 0)
        {
            new hp = GetClientHealth(client);
            if (hp > 0)
            {
                new maxhp=GetMaxHealth(client);
                hp += addhp;
                if (hp <= maxhp)
                {
                    SetEntityHealth(client,hp);
                    ShowHealthParticle(client);
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:ResetRestore(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0 && GetImmunity(client,Immunity_Restore))
    {
        SetImmunity(client, Immunity_Restore, false);
        PrintHintText(client, "%t", "RestoreExpired");
        ClearHud(client, "%t", "RestoreHud");
    }
    return Plugin_Stop;
}

public Action:BootTimer(Handle:time, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (shopItem[ITEM_BOOTS] >= 0 && GetOwnsItem(client,shopItem[ITEM_BOOTS]))
        {
            new entities = EntitiesAvailable(200, .message="Reducing Effects");
            if (entities > 50)
            {
                m_BootCount[client]++;
                new flags = GetEntityFlags(client);
                if (m_BootCount[client] == 5 && !(flags & FL_INWATER))
                {
                    CreateParticle("rocketjump_flame", 1.0, client, Attach, "foot_L");
                    CreateParticle("rocketjump_flame", 1.0, client, Attach, "foot_R");
                }
                else if (m_BootCount[client] > 5)
                {
                    new Float:vec[3];
                    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
                    NormalizeVector(vec, vec);
                    ScaleVector(vec, -90.0);

                    CreateParticle("Explosion_Smoke_1", 0.05, client, Attach, "", vec);
                    m_BootCount[client] = 0;
                }

                if ((flags & FL_ONGROUND) && !(flags & FL_INWATER))
                {
                    new Float:offset[3];
                    offset[0] = GetRandomFloat(0.0, 32.0) - 16.0;
                    offset[1] = GetRandomFloat(0.0, 32.0) - 16.0;
                    offset[0] = 0.0;
                    CreateParticle("burningplayer_corpse", 0.5, client, NoAttach, "", offset);
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:NadeTimer(Handle:time, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (shopItem[ITEM_GLOVES] >= 0 && GetOwnsItem(client,shopItem[ITEM_GLOVES]) &&
            !GetRestriction(client, Restriction_NoShopItems) &&
            !GetRestriction(client, Restriction_Stunned))
        {
            if (m_NadesAvailable)
            {
                AddFragNades(client, 1, _:DamageFrom_ShopItems);
                AddSpecialNades(client, 1, _:DamageFrom_ShopItems);
            }
            else if (GameTypeIsCS())
                GivePlayerItem(client,"weapon_hegrenade");
            else if (GameType == dod)
            {
                new team=GetClientTeam(client);
                GivePlayerItem(client,team == 2 ? "weapon_frag_us" : "weapon_frag_ger");
            }
            else
            {
                g_NadeTimers[client] = INVALID_HANDLE;	
                return Plugin_Stop;
            }
        }
    }
    return Plugin_Continue;
}

public Action:AmmoPack(Handle:time, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if ((shopItem[ITEM_PACK] >= 0 && GetOwnsItem(client,shopItem[ITEM_PACK])) &&
            !GetRestriction(client, Restriction_NoShopItems) &&
            !GetRestriction(client, Restriction_Stunned))
        {
            new amount;
            new SupplyTypes:type;
            if (GameType == dod)
            {
                new pick = GetRandomInt(0,10);
                if (pick > 6)
                {
                    amount = 20;
                    type = SupplyDefault;
                }
                else if (pick > 2)
                {
                    amount = 20;
                    type = SupplySecondary;
                }
                else if (pick > 1)
                {
                    amount = 1;
                    type = SupplySmoke;
                }
                else
                {
                    amount = 1;
                    type = SupplyGrenade;
                }
            }
            else
            {
                amount = 20;
                type = (GetRandomInt(0,10) > 5) ? SupplyDefault : SupplySecondary;
            }

            SupplyAmmo(client, amount, "Ammo Pack", type);
        }
    }
    return Plugin_Continue;
}

public Action:Ankh(Handle:timer,Handle:pack)
{
    ResetPack(pack);
    new client = GetClientOfUserId(ReadPackCell(pack));
    if (client > 0)
    {
        decl String:wepName[128];
        new Float:playerPos[3];
        GetClientAbsOrigin(client,playerPos);
        playerPos[2]+=5.0;
        new iter=myWepsOffset;
        for(new x=0;x<48;x++)
        {
            new ent=GetEntDataEnt2(client,iter);
            if(ent>0&&IsValidEdict(ent))
            {
                GetEdictClassname(ent,wepName,sizeof(wepName));
                if(!StrEqual(wepName,"weapon_c4"))
                {
                    DropWeapon(client,ent);
                    RemoveEntity(ent);
                }
            }
            iter+=4;
        }
        new size = ReadPackCell(pack);
        for(new x=1;x<size;x++)
        {
            ReadPackString(pack, wepName,sizeof(wepName));
            new ent=GivePlayerItem(client,wepName);
            new ammotype=GetPrimaryAmmoType(ent);
            if (ammotype!=-1)
                GiveAmmo(client,ammotype,1000,true);
        }
    }
    CloseHandle(pack);
    return Plugin_Stop;
}

public Action:TrackWeapons(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (myWepsOffset && IsValidClientAlive(client))
    {
        ClearArray(vecPlayerWeapons[client]);
        new iterOffset=myWepsOffset;
        for (new y=0;y<48;y++)
        {
            new wepEnt = GetEntDataEnt2(client,iterOffset);
            if (wepEnt > 0 && IsValidEdict(wepEnt))
            {
                decl String:wepName[128];
                GetEdictClassname(wepEnt,wepName,sizeof(wepName));
                if(!StrEqual(wepName,"weapon_c4"))
                    PushArrayString(vecPlayerWeapons[client],wepName);
            }
            iterOffset+=4;
        }
    }
    return Plugin_Continue;
}

public Action:DoMole(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        new team=GetClientTeam(client);
        new Float:teleLoc[3];
        new searchteam=(team==2)?3:2;
        new Handle:playerList=PlayersOnTeam(searchteam);
        if (GetArraySize(playerList) > 0) // are there any enemies?
        {
            // who gets their position mooched off them?
            new num_players = GetArraySize(playerList)-1;
            new lucky_player_iter=GetRandomInt(0,num_players);
            new lucky_player=GetArrayCell(playerList,lucky_player_iter);

            for (new attempt=1; attempt < num_players; attempt++)
            {
                if (m_SpawnLoc[lucky_player][0] == 0.0 &&
                    m_SpawnLoc[lucky_player][1] == 0.0 &&
                    m_SpawnLoc[lucky_player][2] == 0.0)
                {
                    lucky_player=GetArrayCell(playerList,lucky_player_iter);
                }
                else
                    break;
            }
                
            if (m_SpawnLoc[lucky_player][0] == 0.0 &&
                m_SpawnLoc[lucky_player][1] == 0.0 &&
                m_SpawnLoc[lucky_player][2] == 0.0)
            {
                // Can't find someplace to mole to
                // Give them back the mole
                SetOwnsItem(client,shopItem[ITEM_MOLE],true);

                PrepareAndEmitSoundToClient(client,deniedWav);
                DisplayMessage(client, Display_Item, "%t", "MoleFailed");
            }
            else
            {
                teleLoc[0]=m_SpawnLoc[lucky_player][0] + 5.0;
                teleLoc[1]=m_SpawnLoc[lucky_player][1];
                teleLoc[2]=m_SpawnLoc[lucky_player][2];
                if (TeleportPlayer(client,teleLoc, NULL_VECTOR, NULL_VECTOR))
                {
                    SetAttribute(client, Attribute_IsAMole,true);
                    m_MoleHealth[client] = GetClientHealth(client);
                    m_IsMole[client] = true;
                    if (GameTypeIsCS())
                    {
                        SetModel(client, (team == 2) ? "models/player/ct_urban.mdl"
                                                     : "models/player/t_phoenix.mdl");
                    }
                    else if (GameType == tf2)
                    {
                        for (new TFCond:c = TFCond_CritHype;c <= TFCond_CritOnKill; c++)
                        {
                            if (TF2_IsPlayerInCondition(client, c))
                                TF2_RemoveCondition(client, c);
                        }

                        TF2_AddCondition(client, TFCond_TeleportedGlow, 30.0);
                    }
                }
            }
        }
        else
        {
            // Can't find someplace to mole to
            // Give them back the mole
            SetOwnsItem(client,shopItem[ITEM_MOLE],true);

            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Item, "%t", "MoleFailed");
        }
    }
    return Plugin_Stop;
}

public Action:DoPeriapt(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        UsePeriapt(client);
    }
    return Plugin_Stop;
}

UsePeriapt(client)
{
    IncreaseHealth(client, 50);
    m_UsedPeriapt[client]=true;
}

LootCorpse(Handle:event,victim_index, index)
{
    if (GetRestriction(index, Restriction_NoShopItems) ||
        GetRestriction(index, Restriction_Stunned) ||
        GetImmunity(victim_index,Immunity_Theft))
    {
        PrepareAndEmitSoundToClient(index,deniedWav);
        DisplayMessage(index, Display_Item, "%t",
                       "PreventedFromLooting",
                       victim_index);
    }
    else
    {
        decl String:weapon[64];
        new bool:is_equipment = GetWeapon(event,index,weapon,sizeof(weapon));
        new bool:backstab     = GetEventInt(event, "customkill") == 2;
        new bool:is_melee     = backstab || IsMelee(weapon, is_equipment,
                                                    index, victim_index);

        new chance=backstab ? 85 : (is_melee ? 75 : 55);
        if (GetRandomInt(1,100)<=chance)
        {
            new victim_cash=GetCrystals(victim_index);
            if (victim_cash > 0)
            {
                new Float:percent=GetRandomFloat(backstab ? 0.40 : 0.10,is_melee ? 0.50 : 0.25);
                new cash=GetCrystals(index);
                new amount = RoundToCeil(float(victim_cash) * percent);

                SetCrystals(victim_index,victim_cash-amount);
                SetCrystals(index,cash+amount);

                DisplayMessage(index, Display_Item, "%t",
                               "YouHaveLootedCrystals",
                               amount, victim_index);

                DisplayMessage(victim_index, Display_Enemy_Item, "%t",
                               "LootedYourCrystals", index, amount);
            }
        }
    }
}

stock CreateRegenerationTimer(client)
{
    if (g_RegenerationTimers[client] == INVALID_HANDLE)
        g_RegenerationTimers[client] = CreateTimer(2.0,Regeneration,GetClientUserId(client),TIMER_REPEAT);
}

stock KillRegenerationTimer(client)
{
    if (g_RegenerationTimers[client] != INVALID_HANDLE)
    {
        KillTimer(g_RegenerationTimers[client]);
        g_RegenerationTimers[client] = INVALID_HANDLE;	
    }
}

stock CreateNadeTimer(client)
{
    if (g_NadeTimers[client] == INVALID_HANDLE)
        g_NadeTimers[client] = CreateTimer(30.0,NadeTimer,client,TIMER_REPEAT);
}

stock KillNadeTimer(client)
{
    if (g_NadeTimers[client] != INVALID_HANDLE)
    {
        KillTimer(g_NadeTimers[client]);
        g_NadeTimers[client] = INVALID_HANDLE;	
    }
}

stock CreateBootTimer(client)
{
    CreateParticle("rocketjump_flame", 1.0, client, Attach, "foot_L");
    CreateParticle("rocketjump_flame", 1.0, client, Attach, "foot_R");

    if (g_BootTimers[client] == INVALID_HANDLE)
        g_BootTimers[client] = CreateTimer(0.2,BootTimer,GetClientUserId(client),TIMER_REPEAT);
}

stock KillBootTimer(client)
{
    if (g_BootTimers[client] != INVALID_HANDLE)
    {
        KillTimer(g_BootTimers[client]);
        g_BootTimers[client] = INVALID_HANDLE;	
    }
}

stock CreateAmmoPackTimer(client)
{
    if (g_AmmoPackTimers[client] == INVALID_HANDLE)
        g_AmmoPackTimers[client] = CreateTimer(1.0,AmmoPack,GetClientUserId(client),TIMER_REPEAT);
}

stock KillAmmoPackTimer(client)
{
    if (g_AmmoPackTimers[client] != INVALID_HANDLE)
    {
        KillTimer(g_AmmoPackTimers[client]);
        g_AmmoPackTimers[client] = INVALID_HANDLE;	
    }
}

stock CreateTrackWeaponsTimer(client)
{
    if (g_TrackWeaponsTimers[client] == INVALID_HANDLE)
        g_TrackWeaponsTimers[client] = CreateTimer(1.0,TrackWeapons,GetClientUserId(client),TIMER_REPEAT);
}

stock KillTrackWeaponsTimer(client)
{
    if (g_TrackWeaponsTimers[client] != INVALID_HANDLE)
    {
        KillTimer(g_TrackWeaponsTimers[client]);
        g_TrackWeaponsTimers[client] = INVALID_HANDLE;	
    }
}

// Non-specific stuff

stock RemoveEntity(entity)
{
    SDKCall(hUTILRemove,entity);
}

stock DropWeapon(client,weapon)
{
    SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,NULL_VECTOR);
}

stock SetModel(entity,const String:model[])
{
    SDKCall(hSetModel,entity,model);
}

stock Handle:PlayersOnTeam(team)
{
    new Handle:temp=CreateArray();
    for(new x=1;x<=MaxClients;x++)
    {
        if(IsClientInGame(x) && GetClientTeam(x)==team)
            PushArrayCell(temp,x);
    }
    return temp;
}

// Natives
//
public Native_IsMole(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    return m_IsMole[client];
}

public Native_SetMole(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new bool:value = bool:GetNativeCell(2);
    SetAttribute(client, Attribute_IsAMole, value);
    m_IsMole[GetNativeCell(1)] = value;
}

public Native_InvokeMole(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    DoMole(INVALID_HANDLE, GetClientUserId(client));
}

public Action:CMD_Test(client,args)
{
    static const Float:Velocity[3] = { 10.0, 10.0, 800.0 };
    new arg;
    if (args > 0)
    {
        decl String:argString[32];
        GetCmdArg(1,argString,sizeof(argString));
        arg = StringToInt(argString);
    }
    else
        arg = 1;

    PrintToChat(client, "Test %d", arg);

    switch (arg)
    {
        case 1: TeleportPlayer(client,m_SpawnLoc[client], NULL_VECTOR, NULL_VECTOR);
        case 2: CrashTeleportPlayer(client,m_SpawnLoc[client], NULL_VECTOR, NULL_VECTOR);
        case 3: TF2_StunPlayer(client, 5.0, 0.5, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_LIMITMOVEMENT|TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_CHEERSOUND);
        case 4: TeleportEntity(client,NULL_VECTOR, NULL_VECTOR, Velocity);
    }
    return Plugin_Handled;
}

