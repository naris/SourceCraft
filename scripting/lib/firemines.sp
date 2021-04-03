/*
 *  vim: set ai et ts=4 sw=4 :
 *
 *  TF2 Firemines - SourceMod Plugin
 *  Copyright (C) 2008  Marc Hörsken
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#pragma semicolon 1
#pragma dynamic 65536 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#include "entity_flags"
#include "tf2_player"
#include "tf2_ammo"
#include "entlimit"
#include "weapons"

#undef REQUIRE_PLUGIN
#include "lib/ResourceManager"
#define REQUIRE_PLUGIN

#pragma newdecls required

#define MAXENTITIES 2048

#define PL_VERSION "4.0"

#define SOUND_A "weapons/smg_clip_out.wav"
#define SOUND_E "common/wpn_denyselect.wav"

//Use SourceCraft sounds if it is present
#tryinclude "../SourceCraft/sc/version"
#if defined SOURCECRAFT_VERSION
    #define SOUND_B "sc/tvumin01.wav"
    #define SOUND_C "sc/tvumin00.wav"
#else
    #define SOUND_B "items/spawn_item.wav"
    #define SOUND_C "ui/hint.wav"
#endif

#define MINE_MODEL "models/props_2fort/groundlight001.mdl"

// Colors
char gMineColor[6][16] = { "",            // 0:Unassigned / Default
                           "",            // 1:Spectator
                           "255 0 0",     // 2:Red  / Allies / Terrorists
                           "0 0 255",     // 3:Blue / Axis   / Counter-Terrorists
                           "",            // 4:No Team?
                           ""             // 5:Boss?
};

// settings for m_takedamage
#define DAMAGE_NO               0
#define DAMAGE_EVENTS_ONLY      1       // Call damage functions, but don't modify health
#define DAMAGE_YES              2
#define DAMAGE_AIM              3

// Phys prop spawnflags
#define SF_PHYSPROP_START_ASLEEP                0x000001
#define SF_PHYSPROP_DONT_TAKE_PHYSICS_DAMAGE    0x000002        // this prop can't be damaged by physics collisions
#define SF_PHYSPROP_DEBRIS                      0x000004
#define SF_PHYSPROP_MOTIONDISABLED              0x000008        // motion disabled at startup (flag only valid in spawn - motion can be enabled via input)
#define SF_PHYSPROP_TOUCH                       0x000010        // can be 'crashed through' by running player (plate glass)
#define SF_PHYSPROP_PRESSURE                    0x000020        // can be broken by a player standing on it
#define SF_PHYSPROP_ENABLE_ON_PHYSCANNON        0x000040        // enable motion only if the player grabs it with the physcannon
#define SF_PHYSPROP_NO_ROTORWASH_PUSH           0x000080        // The rotorwash doesn't push these
#define SF_PHYSPROP_ENABLE_PICKUP_OUTPUT        0x000100        // If set, allow the player to +USE this for the purposes of generating an output
#define SF_PHYSPROP_PREVENT_PICKUP              0x000200        // If set, prevent +USE/Physcannon pickup of this prop
#define SF_PHYSPROP_PREVENT_PLAYER_TOUCH_ENABLE 0x000400        // If set, the player will not cause the object to enable its motion when bumped into
#define SF_PHYSPROP_HAS_ATTACHED_RAGDOLLS       0x000800        // Need to remove attached ragdolls on enable motion/etc
#define SF_PHYSPROP_FORCE_TOUCH_TRIGGERS        0x001000        // Override normal debris behavior and respond to triggers anyway
#define SF_PHYSPROP_FORCE_SERVER_SIDE           0x002000        // Force multiplayer physics object to be serverside
#define SF_PHYSPROP_RADIUS_PICKUP               0x004000        // For Xbox, makes small objects easier to pick up by allowing them to be found 
#define SF_PHYSPROP_ALWAYS_PICK_UP              0x100000        // Physcannon can always pick this up, no matter what mass or constraints may apply.
#define SF_PHYSPROP_NO_COLLISIONS               0x200000        // Don't enable collisions on spawn
#define SF_PHYSPROP_IS_GIB                      0x400000        // Limit # of active gibs

enum DropType   { OnDeath, WithFlameThrower, OnCommand };

public Plugin myinfo = 
{
    name = "TF2 Firemines",
    author = "Hunter",
    description = "Allows pyros to drop firemines on death or with secondary Flamethrower fire.",
    version = PL_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=71404"
}

int g_FilteredEntity = -1;
int g_FiremineModelIndex;
int g_PlayerAmmo[MAXPLAYERS+1];
int g_FireminesRef[MAXENTITIES] = { INVALID_ENT_REFERENCE, ... };
int g_FireminesTime[MAXENTITIES];
int g_FireminesOwner[MAXENTITIES];
bool g_FiremineSeeking[MAXENTITIES];
bool g_PlayerButtonDown[MAXPLAYERS+1];
float g_PlayerPosition[MAXPLAYERS+1][3];
Handle g_IsFireminesOn = INVALID_HANDLE;
Handle g_FireminesAmmo = INVALID_HANDLE;
Handle g_FireminesType = INVALID_HANDLE;
Handle g_FireminesMobile = INVALID_HANDLE;
Handle g_FireminesDamage = INVALID_HANDLE;
Handle g_FireminesRadius = INVALID_HANDLE;
Handle g_FireminesDetect = INVALID_HANDLE;
Handle g_FireminesProximity = INVALID_HANDLE;
Handle g_FireminesKeep = INVALID_HANDLE;
Handle g_FireminesStay = INVALID_HANDLE;
Handle g_FriendlyFire = INVALID_HANDLE;
Handle g_FireminesActTime = INVALID_HANDLE;
Handle g_FireminesLimit = INVALID_HANDLE;
Handle g_FireminesMax = INVALID_HANDLE;
Handle g_FiremineColor[4] = { INVALID_HANDLE, ... };


bool g_NativeControl = false;
int g_Limit[MAXPLAYERS+1];      // how many mines player allowed
int g_Maximum[MAXPLAYERS+1];    // how many mines player can have active at once
int g_Remaining[MAXPLAYERS+1];  // how many mines player has this spawn
bool g_ChangingClass[MAXPLAYERS+1];

// forwards
Handle fwdOnSetMine;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Register Natives
    CreateNative("ControlMines",Native_ControlMines);
    CreateNative("GiveMines",Native_GiveMines);
    CreateNative("TakeMines",Native_TakeMines);
    CreateNative("AddMines",Native_AddMines);
    CreateNative("SubMines",Native_SubMines);
    CreateNative("HasMines",Native_HasMines);
    CreateNative("SetMine",Native_SetMine);

    // Register Forwards
    fwdOnSetMine=CreateGlobalForward("OnSetMine",ET_Hook,Param_Cell);

    RegPluginLibrary("firemines");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("firemines.phrases");

    CreateConVar("sm_tf_firemines", PL_VERSION, "Firemines", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_IsFireminesOn = CreateConVar("sm_firemines","4","Enable/Disable firemines (0 = disabled | 1 = on death | 2 = on command | 3 = on command and death  | 4 = on command and death without ammo check on death)", _, true, 0.0, true, 4.0);
    g_FireminesAmmo = CreateConVar("sm_firemines_ammo","100","Ammo required for Firemines", _, true, 0.0, true, 200.0);
    g_FireminesType = CreateConVar("sm_firemines_type","1","Explosion type of Firemines (0 = normal explosion | 1 = fire explosion | 2 = Spider Mine (chases enemies)", _, true, 0.0, true, 1.0);
    g_FireminesMobile = CreateConVar("sm_firemines_seeking","1","Seeking mines/Spider Mines (0 = mines don't move | 1 =  Mines chase enemies", _, true, 0.0, true, 1.0);
    g_FireminesDamage = CreateConVar("sm_firemines_damage","80","Explosion damage of Firemines", _, true, 0.0, true, 1000.0);
    g_FireminesRadius = CreateConVar("sm_firemines_radius","150","Explosion radius of Firemines", _, true, 0.0, true, 1000.0);
    g_FireminesDetect = CreateConVar("sm_firemines_detect","1000","Detection radius of SpiderMines", _, true, 0.0, true, 5000.0);
    g_FireminesProximity = CreateConVar("sm_firemines_proximity","100","Proximity radius of SpiderMines", _, true, 0.0, true, 1000.0);
    g_FireminesKeep = CreateConVar("sm_firemines_keep","300.0","Time to keep Firemines on map. (0 = off | >0 = seconds)", _, true, 0.0, true, 600.0);
    g_FireminesStay = CreateConVar("sm_firemines_stay","1","Firemines stay if the owner dies. (0 = no | 1 = yes)", _, true, 0.0, true, 1.0);
    g_FriendlyFire = FindConVar("mp_friendlyfire");

    g_FireminesActTime = CreateConVar("sm_firemines_activate_time", "2.0", "If the owner dies before activation time, mine is removed. (0 = off)", _, true, 0.0, true, 600.0);
    g_FireminesLimit = CreateConVar("sm_firemines_limit", "-1", "Number of firemines allowed per life (-1 = unlimited)", _, true, -1.0, true, 99.0);
    g_FireminesMax = CreateConVar("sm_firemines_max", "3", "Maximum Number of firemines allowed to be active per client (-1 = unlimited)", _, true, -1.0, true, 99.0);

    g_FiremineColor[1] = CreateConVar("sm_firemines_mine_color_1", gMineColor[1], "Mine Color (can include alpha) for team 1 (Spectators)");
    g_FiremineColor[2] = CreateConVar("sm_firemines_mine_color_2", gMineColor[2], "Mine Color (can include alpha) for team 2 (Red  / Allies / Terrorists)");
    g_FiremineColor[3] = CreateConVar("sm_firemines_mine_color_3", gMineColor[3], "Mine Color (can include alpha) for team 3 (Blue / Axis   / Counter-Terrorists)");

    HookConVarChange(g_IsFireminesOn, ConVarChange);
    HookConVarChange(g_FiremineColor[1], ConVarChange);
    HookConVarChange(g_FiremineColor[2], ConVarChange);
    HookConVarChange(g_FiremineColor[3], ConVarChange);

    HookEvent("player_changeclass", Event_PlayerClass);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("arena_win_panel", Event_RoundEnd);
    HookEvent("teamplay_round_win", Event_RoundEnd);
    HookEvent("teamplay_round_stalemate", Event_RoundEnd);

    RegConsoleCmd("sm_firemine", Command_Firemine);
    RegConsoleCmd("sm_mine", Command_Firemine);
    RegConsoleCmd("mine", Command_Firemine);

    CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);

    AutoExecConfig(true);
}

public void OnConfigsExecuted()
{
    // Get the color settings
    GetConVarString(g_FiremineColor[1], gMineColor[1], sizeof(gMineColor[]));
    GetConVarString(g_FiremineColor[2], gMineColor[2], sizeof(gMineColor[]));
    GetConVarString(g_FiremineColor[3], gMineColor[3], sizeof(gMineColor[]));
}

public void OnMapStart()
{
    SetupSound(SOUND_A, true, DONT_DOWNLOAD);
    SetupSound(SOUND_E, true, DONT_DOWNLOAD);

    #if defined SOURCECRAFT_VERSION
        SetupSound(SOUND_B, true, DOWNLOAD);
        SetupSound(SOUND_C, true, DOWNLOAD);
    #else
        SetupSound(SOUND_B, true, DONT_DOWNLOAD);
        SetupSound(SOUND_C, true, DONT_DOWNLOAD);
    #endif

    SetupModel(MINE_MODEL, g_FiremineModelIndex, false, true);

    AutoExecConfig(true);
}

public void OnClientDisconnect(int client)
{
    RemoveMines(client);

    g_ChangingClass[client] = false;
    g_PlayerButtonDown[client] = false;
    g_PlayerAmmo[client] = 0;
    g_PlayerPosition[client] = NULL_VECTOR;
    g_Remaining[client] = g_Limit[client] = g_Maximum[client] = 0;
}

// When a new client is put in the server we reset their mines count
public void OnClientPutInServer(int client)
{
    if (client && !IsFakeClient(client))
    {
        g_ChangingClass[client] = false;

        if (g_NativeControl)
        {
            g_Remaining[client] = g_Limit[client] =  g_Maximum[client] = 0;
        }
        else
        {
            g_Maximum[client] = GetConVarInt(g_FireminesMax);
            g_Remaining[client] = g_Limit[client] =  GetConVarInt(g_FireminesLimit);
        }
    }

    if(!g_NativeControl && GetConVarBool(g_IsFireminesOn))
        CreateTimer(45.0, Timer_Advert, client);
}

public void OnGameFrame()
{
    if (!g_NativeControl && GetConVarInt(g_IsFireminesOn) < 2)
        return;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_Remaining[i] && !g_PlayerButtonDown[i] && IsClientInGame(i) &&
            TF2_GetPlayerClass(i) == TFClass_Pyro)
        {
            if (GetClientButtons(i) & IN_RELOAD)
            {
                g_PlayerButtonDown[i] = true;
                CreateTimer(0.5, Timer_ButtonUp, i);

                char classname[64];
                GetCurrentWeaponClass(i, classname, 64);
                if (StrEqual(classname, "CTFFlameThrower"))
                {
                    TF_DropFiremine(i, WithFlameThrower,
                                    GetConVarBool(g_FireminesMobile));
                }
            }
        }
    }
}

public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_IsFireminesOn)
    {
        if (StringToInt(newValue) > 0)
            PrintToChatAll("[SM] %t", "Enabled Firemines");
        else
            PrintToChatAll("[SM] %t", "Disabled Firemines");
    }
    else if (convar == g_FiremineColor[1])
        strcopy(gMineColor[1], sizeof(gMineColor[]), newValue);
    else if (convar == g_FiremineColor[2])
        strcopy(gMineColor[2], sizeof(gMineColor[]), newValue);
    else if (convar == g_FiremineColor[3])
        strcopy(gMineColor[3], sizeof(gMineColor[]), newValue);
}

public Action Command_Firemine(int client, int args)
{
    if (!g_NativeControl && GetConVarInt(g_IsFireminesOn) < 2)
        return Plugin_Handled;

    DropType cmd;
    if (g_NativeControl)
        cmd = OnCommand;
    else
    {
        TFClassType class = TF2_GetPlayerClass(client);
        if (class != TFClass_Pyro)
            return Plugin_Handled;

        char classname[64];
        GetCurrentWeaponClass(client, classname, 64);
        if(!StrEqual(classname, "CTFFlameThrower"))
            return Plugin_Handled;

        cmd = WithFlameThrower;
    }

    char arg[16];
    bool seeking = false;
    if (args >= 1 && GetCmdArg(1,arg,sizeof(arg)))
        seeking = view_as<bool>(StringToInt(arg));

    TF_DropFiremine(client, cmd, seeking);

    return Plugin_Handled;
}

public Action Timer_Advert(Handle timer, any client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        switch (GetConVarInt(g_IsFireminesOn))
        {
            case 1:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Firemines");
            case 2:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Firemines");
            case 3, 4:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Firemines");
        }
    }
}

public Action Timer_Caching(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) &&
            (g_NativeControl ? g_Limit[i] != 0 : TF2_GetPlayerClass(i) == TFClass_Pyro))
        {
            g_PlayerAmmo[i] = TF2_GetAmmoAmount(i);
            GetClientAbsOrigin(i, g_PlayerPosition[i]);
        }
    }

    float keep = GetConVarFloat(g_FireminesKeep);
    if (keep > 0)
    {
        RemoveMines(0, keep);
    }
}

public Action Timer_ButtonUp(Handle timer, any client)
{
    g_PlayerButtonDown[client] = false;
}

public Action Event_PlayerClass(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client))
        return;

    g_ChangingClass[client] = true;

    int stay = GetConVarInt(g_FireminesStay);
    float time = GetConVarFloat(g_FireminesActTime);
    if (stay < 1 || time > 0.0)
    {
        RemoveMines(client, time, stay < 1);
    }

    any class = GetEventInt(event, "class");
    if (class != TFClass_Pyro)
    {
        if (!g_NativeControl)
            return;
    }
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_ChangingClass[client])
        g_ChangingClass[client]=false;
    else
    {
        if (g_NativeControl)
            g_Remaining[client] = g_Limit[client];
        else
        {
            g_Maximum[client] = GetConVarInt(g_FireminesMax);
            g_Remaining[client] = g_Limit[client] = GetConVarInt(g_FireminesLimit);
        }
    }

    return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int fireminesOn = GetConVarInt(g_IsFireminesOn);
    if (!g_NativeControl && fireminesOn < 1)
        return;

    // Skip feigned deaths.
    if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        return;

    // Skip fishy deaths.
    if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH &&
        GetEventInt(event, "customkill") != TF_CUSTOM_FISH_KILL)
    {
        return;
    }

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client))
        return;

    if (!g_NativeControl)
    {
        TFClassType class = TF2_GetPlayerClass(client); 
        if (class != TFClass_Pyro)
            return;
    }

    g_ChangingClass[client] = false;

    int stay = GetConVarInt(g_FireminesStay);
    float time = GetConVarFloat(g_FireminesActTime);
    if (stay < 1 || time > 0.0)
    {
        RemoveMines(client, time, stay < 1);
    }

    if (g_NativeControl)
    {
        if (g_Remaining[client] == 0)
            return;
    }

    if (fireminesOn != 2 || g_NativeControl)
    {
        TF_DropFiremine(client, OnDeath, false);
    }
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client != 0)
    {
        int team = GetEventInt(event, "team");
        if (team < 2 && IsClientInGame(client))
        {
            g_PlayerButtonDown[client] = false;
            g_PlayerAmmo[client] = 0;
            g_PlayerPosition[client] = NULL_VECTOR;
        }
    }
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    RemoveMines();
}

public Action OnTouched(int entity, int other)
{
    if (entity > 0 && entity < sizeof(g_FireminesRef) && other > 0 && other <= MaxClients
        && g_FireminesTime[entity] > 0 && entity == EntRefToEntIndex(g_FireminesRef[entity])
        && IsClientInGame(other))
    {
        LogMessage("OnStartTouched(%d,%d:%N)", entity, other, other);
        return ActivateMine(entity, other);
    }
    else
    {
        LogMessage("OnStartTouched for invalid mine %d", entity);
    }
    return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
    if (victim > 0 && victim < sizeof(g_FireminesRef) && attacker > 0 && attacker <= MaxClients
        && g_FireminesTime[victim] > 0 && victim == EntRefToEntIndex(g_FireminesRef[victim]))
    {
        LogMessage("OnTakeDamage(%d,%d:%N,%d,%f,%d)", victim, attacker, attacker, inflictor, damage, damagetype);
        ExplodeMine(victim);
        return Plugin_Handled;
    }
    else
    {
        LogMessage("OnTakeDamage for invalid mine %d", victim);
    }
    return Plugin_Continue;
}

public Action OnBreak(const char[] output, int caller, int activator, float delay)
{
    if (caller > 0 && caller < sizeof(g_FireminesRef) && activator > 0 && activator <= MaxClients
        && g_FireminesTime[caller] > 0 && caller == EntRefToEntIndex(g_FireminesRef[caller])
        && IsClientInGame(activator))
    {
        LogMessage("OnBreak(%s,%d,%d:%N,%f)",output, caller, activator, activator, delay);
        ExplodeMine(caller, .broken=true);
        //return Plugin_Handled;
    }
    else
    {
        LogMessage("OnBreak for invalid mine %d", caller);
    }
    return Plugin_Continue;
}

public Action OnTouchedByEntity(const char[] output, int caller, int activator, float delay)
{
    if (caller > 0 && caller < sizeof(g_FireminesRef) && activator > 0 && activator <= MaxClients
        && g_FireminesTime[caller] > 0 && caller == EntRefToEntIndex(g_FireminesRef[caller])
        && IsClientInGame(activator))
    {
        LogMessage("OnTouchedByEntity(%s,%d,%d:%N,%f)", output, caller, activator, activator, delay);
        return ActivateMine(caller, activator);
    }
    else
    {
        LogMessage("OnTouchedByEntity for invalid mine %d", caller);
        return Plugin_Continue;
    }
}

public Action OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
    if (caller > 0 && caller < sizeof(g_FireminesRef) && activator > 0 && activator <= MaxClients
        && g_FireminesTime[caller] > 0 && caller == EntRefToEntIndex(g_FireminesRef[caller])
        && IsClientInGame(activator))
    {
        LogMessage("OnHealthChanged(%s,%d,%d:%N,%f)", output, caller, activator, activator, delay);
        ExplodeMine(caller);
        return Plugin_Handled;
    }
    else
    {
        LogMessage("OnHealthChanged for invalid mine %d", caller);
        return Plugin_Continue;
    }
}

Action ActivateMine(int caller, int activator, bool broken=false)
{
    if (caller > 0 && caller < sizeof(g_FireminesRef) && activator > 0 && activator <= MaxClients
        && g_FireminesTime[caller] > 0 && caller == EntRefToEntIndex(g_FireminesRef[caller])
        && IsClientInGame(activator))
    {
        LogMessage("ActivateMine(%d,%d:%N,%d)", caller, activator, activator, broken);

        // Make sure it's a Firemine and the owner is still in the game
        int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
        if (owner == g_FireminesOwner[caller] && IsClientInGame(owner))
        {
            int team = GetConVarBool(g_FriendlyFire) ? 0 : GetEntProp(caller, Prop_Send, "m_iTeamNum");
            //if (team != GetClientTeam(activator))
            if (team != GetClientTeam(activator) || activator == owner) // <-- DEBUG
            {
                ExplodeMine(caller, owner, team, broken);
                return Plugin_Handled;
            }
            else
            {
                LogMessage("ActivateMine: Same Team, Plugin_Stop");
                return Plugin_Stop;
            }
        }
        else
        {
            LogMessage("ActivateMine: Invalid Owner! Start Remove Timer for mine %d, Plugin_Stop", caller);
            CreateTimer(0.2, RemoveMine, EntIndexToEntRef(caller));
            return Plugin_Stop;
        }
    }
    else
    {
        LogMessage("ActivateMine for invalid mine %d", caller);
        return Plugin_Continue;
    }
}

void ExplodeMine(int mine, int owner=-1, int team=-1, bool broken=false)
{
    if (owner < 0)
        owner = GetEntPropEnt(mine, Prop_Send, "m_hOwnerEntity");

    if (GetConVarBool(g_FireminesType))
    {
        if (team < 0)
        {
            team = GetConVarBool(g_FriendlyFire) ? 0 : GetEntProp(mine, Prop_Send, "m_iTeamNum");
        }

        float vecPos[3];
        GetEntPropVector(mine, Prop_Send, "m_vecOrigin", vecPos);

        float PlayerPosition[3];
        float maxdistance = GetConVarFloat(g_FireminesRadius);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                GetClientAbsOrigin(i, PlayerPosition);
                float distance = GetVectorDistance(PlayerPosition, vecPos);
                if (distance < 0.0)
                    distance *= -1.0;

                if (distance <= maxdistance)
                {
                    if (i == owner)
                    {
                        LogMessage("ExplodeMine: ignite owner %d distance=%f", i, distance);
                        IgniteEntity(i, 2.5);
                    }
                    else if (team != GetClientTeam(i))
                    {
                        if (!TF2_IsPlayerUbercharged(i))
                        {
                            LogMessage("ExplodeMine: ignite player %d, team=%d, mine_team=%d, distance=%f", i, GetClientTeam(i), team, distance);
                            if (owner > 0 && IsClientInGame(owner))
                                TF2_IgnitePlayer(i, owner);
                            else
                                IgniteEntity(i, 2.5);
                        }
                    }
                }
            }
        }
    }

    if (!broken)
    {
        LogMessage("ExplodeMine: Break mine %d, owner=%d, Plugin_Continue", mine, owner);
        AcceptEntityInput(mine, "Break", owner, owner);
    }

    LogMessage("ExplodeMine: Start Remove Timer for mine %d", mine);
    CreateTimer(0.2, RemoveMine, EntIndexToEntRef(mine));
}

public bool FiremineTraceFilter(int ent, int contentMask)
{
    return (ent != g_FilteredEntity);
}

void SetSolidFlags(int fireMine, bool seeking)
{
    if (seeking)
    {
        //DispatchKeyValue(fireMine, "spawnflags", "48");
        //SetEntProp(fireMine, Prop_Send, "m_usSolidFlags", FSOLID_VOLUME_CONTENTS|FSOLID_NOT_STANDABLE);
        //DispatchKeyValue(fireMine, "spawnflags", "32");
        SetEntProp(fireMine, Prop_Send, "m_usSolidFlags", FSOLID_VOLUME_CONTENTS);
    }
    else
    {
        //DispatchKeyValue(fireMine, "spawnflags", "152");
        //SetEntProp(fireMine, Prop_Send, "m_usSolidFlags", FSOLID_USE_TRIGGER_BOUNDS|FSOLID_NOT_STANDABLE|FSOLID_TRIGGER);
        //DispatchKeyValue(fireMine, "spawnflags", "136");
        SetEntProp(fireMine, Prop_Send, "m_usSolidFlags", FSOLID_USE_TRIGGER_BOUNDS|FSOLID_TRIGGER);
    }
}

void SetMineColor(int fireMine, int team)
{
    if (team >= 0 && team < sizeof(gMineColor) && gMineColor[team][0] != '\0')
    {
        char color[4][4];
        if (ExplodeString(gMineColor[team], " ", color, sizeof(color), sizeof(color[])) <= 3)
            strcopy(color[3], sizeof(color[]), "255");

        SetEntityRenderMode(fireMine, RENDER_TRANSCOLOR);
        SetEntityRenderColor(fireMine, StringToInt(color[0]), StringToInt(color[1]),
                                        StringToInt(color[2]), StringToInt(color[3]));
    }
    else
    {
        SetEntityRenderMode(fireMine, RENDER_NORMAL);
        SetEntityRenderColor(fireMine, 255, 255, 255, 255);
    }
}

int TF_SpawnFiremine(int client, DropType cmd)
{
    float PlayerPosition[3];
    if (cmd != OnDeath)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_PlayerPosition[client];

    if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 &&
        PlayerPosition[2] != 0.0 && !IsEntLimitReached(100, .message="unable to create mine"))
    {
        PlayerPosition[2] += 4.0;
        g_FilteredEntity = client;
        if (cmd != OnDeath)
        {
            float PlayerAngle[3];
            GetClientEyeAngles(client, PlayerAngle);

            float PlayerPosEx[3];
            PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[2] = 0.0;
            ScaleVector(PlayerPosEx, 75.0);

            float PlayerPosAway[3];
            AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

            Handle TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID,
                                                 RayType_EndPoint, FiremineTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        float Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        Handle Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID,
                                           RayType_EndPoint, FiremineTraceFilter);

        float MinePos[3];
        TR_GetEndPosition(MinePos, Trace);
        CloseHandle(Trace);
        MinePos[2] += 1;

        //int fireMine = CreateEntityByName("prop_physics_multiplayer");
        //int fireMine = CreateEntityByName("prop_physics_override");
        int fireMine = CreateEntityByName("prop_dynamic_override");
        if (fireMine > 0 && IsValidEntity(fireMine))
        {
            // Ensure the mine model is precached
            PrepareModel(MINE_MODEL, g_FiremineModelIndex, true);
            SetEntityModel(fireMine, MINE_MODEL);

            int team = GetConVarBool(g_FriendlyFire) ? 0 : GetClientTeam(client);
            SetMineColor(fireMine, team);
            SetSolidFlags(fireMine, false);

            SetEntProp(fireMine, Prop_Send, "m_iTeamNum", team, 4);
            SetEntPropEnt(fireMine, Prop_Send, "m_hOwnerEntity", client);
            SetEntPropEnt(fireMine, Prop_Data, "m_hLastAttacker", client);
            SetEntPropEnt(fireMine, Prop_Data, "m_hPhysicsAttacker", client);

            /*
            SetEntProp(fireMine, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_INTERACTIVE_DEB);
            SetEntityMoveType(fireMine, MOVETYPE_FLYGRAVITY); //MOVETYPE_VPHYSICS);
            SetEntProp(fireMine, Prop_Data, "m_MoveCollide", COLLISION_GROUP_INTERACTIVE_DEB);
            */

            SetEntProp(fireMine, Prop_Send, "m_nSolidType", SOLID_BBOX); //SOLID_VPHYSICS);
            SetEntPropFloat(fireMine, Prop_Data, "m_flGravity", 0.0);

            SetEntProp(fireMine, Prop_Data, "m_takedamage", DAMAGE_YES);
            DispatchKeyValue(fireMine, "physdamagescale", "1.0");

            char targetname[32];
            Format(targetname, sizeof(targetname), "firemine_%d", fireMine);
            DispatchKeyValue(fireMine, "targetname", targetname);

            DispatchKeyValue(fireMine, "StartDisabled", "false");

            if (DispatchSpawn(fireMine))
            {
                char tmp[128];

                TeleportEntity(fireMine, MinePos, NULL_VECTOR, NULL_VECTOR);

                GetConVarString(g_FireminesDamage, tmp, sizeof(tmp));
                DispatchKeyValue(fireMine, "ExplodeRadius", tmp);

                GetConVarString(g_FireminesRadius, tmp, sizeof(tmp));
                DispatchKeyValue(fireMine, "ExplodeDamage", tmp);

                if (!SDKHookEx(fireMine, SDKHook_StartTouchPost, OnTouched))
                {
                    HookSingleEntityOutput(fireMine, "OnTouchedByEntity", OnTouchedByEntity, true);
                    LogMessage("FAILED to hook SDKHook_StartTouchPost for %d", fireMine);
                }

                if (!SDKHookEx(fireMine, SDKHook_OnTakeDamage, OnTakeDamage))
                {
                    HookSingleEntityOutput(fireMine, "OnHealthChanged", OnHealthChanged, true);
                    LogMessage("FAILED to hook SDKHook_OnTakeDamage for %d", fireMine);
                }

                //DispatchKeyValue(fireMine, "OnBreak", "!self,Kill,,0,-1");
                HookSingleEntityOutput(fireMine, "OnBreak", OnBreak, true);

                AcceptEntityInput(fireMine, "Enable");

                PrepareAndEmitSoundToAll(SOUND_B, fireMine, _, _, _, 0.75);

                g_FireminesRef[fireMine] = EntIndexToEntRef(fireMine);
                g_FireminesTime[fireMine] = GetTime();
                g_FireminesOwner[fireMine] = client;
                g_FiremineSeeking[fireMine] =  false;
                return fireMine;
            }
        }
    }
    return 0;
}

bool TF_DropFiremine(int client, DropType cmd, bool seeking)
{
    if (g_Remaining[client] <= 0 && g_Limit[client] >= 0)
    {
        if (IsClientInGame(client))
        {
            PrepareAndEmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
            PrintHintText(client, "You do not have any mines.");
        }
        return false;
    }

    int max = g_Maximum[client];
    if (max > 0)
    {
        int count = CountMines(client);
        if (count > max)
        {
            PrepareAndEmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
            PrintHintText(client, "You already have %d mines active.", count);
            return false;
        }
    }

    int ammo = (cmd == OnDeath) ? g_PlayerAmmo[client] : TF2_GetAmmoAmount(client);
    int FireminesAmmo = GetConVarInt(g_FireminesAmmo);
    TFClassType class = TF2_GetPlayerClass(client);
    switch (class)
    {
        case TFClass_Medic:     FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 1.33);
        case TFClass_Scout:     FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 6.5);
        case TFClass_Engineer:  FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 6.5);
        case TFClass_Soldier:   FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 12.5);
        case TFClass_DemoMan:   FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 12.5);
        case TFClass_Sniper:    FireminesAmmo /= 10;
        case TFClass_Spy:       FireminesAmmo /= 10;
    }

    int fireminesOn = GetConVarInt(g_IsFireminesOn);
    if (ammo >= FireminesAmmo || (cmd == OnDeath && fireminesOn > 3))
    {
        Action res = Plugin_Continue;
        Call_StartForward(fwdOnSetMine);
        Call_PushCell(client);
        Call_Finish(res);
        if (res != Plugin_Continue)
        {
            return false;
        }

        if (cmd != OnDeath)
        {
            switch (class)
            {
                case TFClass_Spy:
                {
                    if (TF2_IsPlayerCloaked(client) ||
                        TF2_IsPlayerDeadRingered(client))
                    {
                        PrepareAndEmitSoundToClient(client, SOUND_E);
                        return false;
                    }
                    else if (TF2_IsPlayerDisguised(client))
                        TF2_RemovePlayerDisguise(client);
                }
                case TFClass_Scout:
                {
                    if (TF2_IsPlayerBonked(client))
                    {
                        PrepareAndEmitSoundToClient(client, SOUND_E);
                        return false;
                    }
                }
            }

            if (cmd != OnDeath)
            {
                ammo -= FireminesAmmo;
                g_PlayerAmmo[client] = ammo;
                TF2_SetAmmoAmount(client, ammo);
            }

            // update client's inventory
            if (g_Remaining[client] > 0)
                g_Remaining[client]--;
        }

        int mine = TF_SpawnFiremine(client, cmd);

        if (seeking)
        {
            CreateTimer(GetConVarFloat(g_FireminesActTime),
                        MineActivate, EntIndexToEntRef(mine));
        }

        return true;
    }
    else
    {
        if (cmd != OnDeath)
            PrepareAndEmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
    }
    return false;
}

int CountMines(int client)
{
    int count = 0;
    int maxents = GetMaxEntities();
    for (int c = MaxClients; c < maxents; c++)
    {
        if (g_FireminesOwner[c] == client)
        {
            int ref = g_FireminesRef[c];
            if (ref != INVALID_ENT_REFERENCE)
            {
                if (EntRefToEntIndex(ref) == c)
                    count++;
                else
                {
                    LogMessage("CountMines: Cleaning up invalid mine %d", c);
                    g_FireminesRef[c] = INVALID_ENT_REFERENCE;
                    g_FireminesOwner[c] = 0;
                    g_FireminesTime[c] = 0;
                }
            }
        }
    }
    return count;
}

void RemoveMines(int client=0, float time=0.0, bool force=false)
{
    int maxents = GetMaxEntities();
    for (int c = MaxClients; c < maxents; c++)
    {
        if (client == 0 || g_FireminesOwner[c] == client)
        {
            int ref = g_FireminesRef[c];
            if (ref != INVALID_ENT_REFERENCE)
            {
                int ent = EntRefToEntIndex(ref);
                bool kill = (force || ent != c ||
                            (time >= 0.0 && g_FireminesTime[c] < (GetTime() - time)));
                if (kill)
                {
                    if (c == ent && IsValidEntity(c))
                    {
                        LogMessage("RemoveMines: Killing Mine %d, ent=%d, ref=%d, owner=%d:%N, client=%d, time=%d, mineTime=%d, force=%d, expired=%d!",
                                    c, ent, ref, g_FireminesOwner[c], client, client, time, g_FireminesTime[c], force, (time >= 0.0 && g_FireminesTime[c] < (GetTime() - time)));

                        PrepareAndEmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        RemoveMineEntity(c, ref);
                    }
                }

                if (kill || ent != c)
                {
                    LogMessage("RemoveMines: Cleaning up mine %d, ent=%d, ref=%d, owner=%d, client=%d",
                                c, ent, ref, g_FireminesRef[c], client);

                    g_FireminesRef[c] = INVALID_ENT_REFERENCE;
                    g_FireminesOwner[c] = 0;
                    g_FireminesTime[c] = 0;
                }
            }
        }
    }
}

void RemoveMineEntity(int mine=-1, int mineRef=-1)
{
    if (mine == -1)
        mine = EntRefToEntIndex(mineRef);

    if (mineRef == -1 && mine > 0 && mine < sizeof(g_FireminesRef))
        mineRef = g_FireminesRef[mine];

    if (mine > 0)
    {
        if (mine == EntRefToEntIndex(mineRef) && IsValidEntity(mine))
        {
            UnhookSingleEntityOutput(mine, "OnBreak", OnBreak);

            if (!GetConVarBool(g_FriendlyFire))
            {
                UnhookSingleEntityOutput(mine, "OnHealthChanged", OnHealthChanged);
                UnhookSingleEntityOutput(mine, "OnTouchedByEntity", OnTouchedByEntity);
            }

            SDKUnhook(mine, SDKHook_Touch, OnTouched);
            SDKUnhook(mine, SDKHook_StartTouchPost, OnTouched);
            SDKUnhook(mine, SDKHook_OnTakeDamage, OnTouched);

            //RemoveEdict(mine);
            AcceptEntityInput(mine, "Kill");
        }
        else
        {
            LogMessage("Attempt to remove invalid mine %d,%d", mine, mineRef);
        }

        LogMessage("RemoveMineEntity: Cleaning up Mine %d", mine);
        g_FireminesRef[mine] = INVALID_ENT_REFERENCE;
        g_FireminesOwner[mine] = 0;
        g_FireminesTime[mine] = 0;
    }
}

public Action RemoveMine(Handle timer, any mineRef)
{
    RemoveMineEntity(.mineRef=mineRef);
    return Plugin_Stop;
}

public Action MineActivate(Handle timer, any mineRef)
{
    // Ensure the entity is still a mine
    int mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
        CreateTimer(0.2, MineSeek, mineRef, TIMER_REPEAT);
    else
    {
        LogMessage("Attempt to activate invalid mine %d,%d", mine, mineRef);
    }

    return Plugin_Stop;
}

public Action MineSeek(Handle timer, any mineRef)
{
    // Ensure the entity is still a mine
    int mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
    {
        //LogMessage("MineSeek: mineRef=%d, mine=%d", mineRef, mine);

        float minePos[3];
        GetEntPropVector(mine, Prop_Send, "m_vecOrigin", minePos);

        int team = GetEntProp(mine, Prop_Send, "m_iTeamNum");
        float detect = GetConVarFloat(g_FireminesDetect);
        float proximity = GetConVarFloat(g_FireminesProximity);

        // Find closest enemy within range
        int target = 0;
        float PlayerPosition[3];
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != team)
            {
                GetClientAbsOrigin(i, PlayerPosition);
                float distance = GetVectorDistance(minePos, PlayerPosition);
                if (distance < 0.0)
                    distance *= -1.0;

                if (distance <= detect)
                {
                    if (distance <= proximity)
                    {
                        TR_TraceRayFilter(minePos, PlayerPosition, MASK_SOLID, RayType_EndPoint,
                                TraceRayDontHitSelf, mine);
                        if (TR_GetEntityIndex() == i)
                        {
                            // Explode when within proximity range!
                            LogMessage("MineSeek: Explode mine=%d, client=%d, distance=%f, proximity=%f", mine, i, distance, proximity);
                            ExplodeMine(mine);
                            return Plugin_Stop;
                        }
                    }

                    TR_TraceRayFilter(minePos, PlayerPosition, MASK_SOLID, RayType_EndPoint,
                                      TraceRayDontHitSelf, mine);
                    if (TR_GetEntityIndex() == i)
                    {
                        //LogMessage("MineSeek: found target mine=%d, client=%d, distance=%f, proximity=%f", mine, i, distance, proximity);
                        target = i;
                        detect = distance;
                    }
                }
            }
        }

        // Did we find a target?
        if (target > 0)
        {
            SetSolidFlags(mine, true);

            float vector[3];
            GetClientEyePosition(target, PlayerPosition);
            MakeVectorFromPoints(minePos, PlayerPosition, vector);
            NormalizeVector(vector, vector);

            //LogMessage("MineSeek: has target, mine=%d, target=%d, vector=%f,%f,%f", mine, target, vector[0], vector[1], vector[2]);

            float angles[3];
            GetVectorAngles(vector, angles);
            //LogMessage("MineSeek: teleport mine=%d, angles=%f,%f,%f", mine, angles[0], angles[1], angles[2]);
            TeleportEntity(mine, NULL_VECTOR, angles, NULL_VECTOR);

            SetEntityRenderMode(mine, RENDER_GLOW);
            SetEntityRenderColor(mine, (team == 2) ? 255 : 0, 0, (team == 3) ? 0 : 255, 255);

            if (!g_FiremineSeeking[mine])
            {
                minePos[2] += 20.0;

                //LogMessage("MineSeek: teleport mine=%d, pos=%f,%f,%f", mine, minePos[0], minePos[1], minePos[2]);
                TeleportEntity(mine, minePos, NULL_VECTOR, NULL_VECTOR);
                g_FiremineSeeking[mine] =  true;
            }

            float velocity[3];
            velocity[0] = vector[0] * 80.0;
            velocity[1] = vector[1] * 80.0;
            velocity[2] = 10.0;

            //LogMessage("MineSeek: teleport mine=%d, velocity=%f,%f,%f", mine, velocity[0], velocity[1], velocity[2]);
            TeleportEntity(mine, NULL_VECTOR, NULL_VECTOR, velocity);

            PrepareAndEmitSoundToAll(SOUND_C, mine);
        }
        else if (g_FiremineSeeking[mine])
        {
            float angles[3] = {0.0,0.0,0.0};
            //LogMessage("MineSeek: teleport mine=%d, angles=%f,%f,%f", mine, angles[0], angles[1], angles[2]);
            TeleportEntity(mine, NULL_VECTOR, angles, NULL_VECTOR);

            float vecBelow[3];
            vecBelow[0] = minePos[0];
            vecBelow[1] = minePos[1];
            vecBelow[2] = minePos[2] - 2000.0;

            float vecMins[3];
            GetEntPropVector(mine, Prop_Send, "m_vecMins", vecMins);

            float vecMaxs[3];
            GetEntPropVector(mine, Prop_Send, "m_vecMaxs", vecMaxs);

            //TR_TraceRayFilter(minePos, vecBelow, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayDontHitSelf, mine);
            TR_TraceHullFilter(minePos, vecBelow, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRayDontHitSelf, mine);
            if (TR_DidHit(INVALID_HANDLE))
            {
                // Move mine down to ground.
                //LogMessage("MineSeek: teleport to ground mine=%d, pos=%f,%f,%f", mine,  minePos[0], minePos[1], minePos[2]);
                TR_GetEndPosition(minePos, INVALID_HANDLE);
                TeleportEntity(mine, minePos, NULL_VECTOR, NULL_VECTOR);
            }

            SetMineColor(mine, team);
            SetSolidFlags(mine, false);

            g_FiremineSeeking[mine] =  false;

            PrepareAndEmitSoundToAll(SOUND_B, mine);
        }
        return Plugin_Continue;
    }
    else
    {
        LogMessage("Ending seek for invalid mine %d,%d", mine, mineRef);
        return Plugin_Stop;
    }
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
    return (entity != data); // Check if the TraceRay hit the entity.
}

public int Native_ControlMines(Handle plugin, int numParams)
{
    g_NativeControl = GetNativeCell(1);
}

public int Native_GiveMines(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    g_Remaining[client] = GetNativeCell(2);
    g_Limit[client] = GetNativeCell(3);
    g_Maximum[client] = GetNativeCell(4);

    if (g_Maximum[client] < 0)
        g_Maximum[client] = GetConVarInt(g_FireminesMax);
}

public int Native_TakeMines(Handle plugin, int numParams)
{
    if (numParams >= 1)
    {
        int client = GetNativeCell(1);
        g_Remaining[client] = g_Limit[client] = g_Maximum[client] = 0;
    }
}

public int Native_AddMines(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (g_Limit[client] >= 0)
    {
        g_Remaining[client] += GetNativeCell(2);
    }
}

public int Native_SubMines(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (g_Limit[client] >= 0)
    {
        g_Remaining[client] -= GetNativeCell(2);
        if (g_Remaining[client] < 0)
            g_Remaining[client] = 0;
    }
}

public int Native_HasMines(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return (GetNativeCell(2)) ? g_Limit[client] : g_Remaining[client];
}

public int Native_SetMine(Handle plugin, int numParams)
{
    bool seeking = view_as<bool>(GetNativeCell(2));
    TF_DropFiremine(GetNativeCell(1), OnCommand, seeking);
}

public int Native_CountMines(Handle plugin, int numParams)
{
    return CountMines(GetNativeCell(1));
}
