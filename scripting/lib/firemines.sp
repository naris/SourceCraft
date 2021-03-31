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
#include <tf2_stocks>

#include "tf2_player"
#include "tf2_ammo"
#include "entlimit"
#include "weapons"

#undef REQUIRE_PLUGIN
#include "lib/ResourceManager"
#define REQUIRE_PLUGIN

#define MAXENTITIES 2048

#define PL_VERSION "3.3"

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

public Plugin:myinfo = 
{
    name = "TF2 Firemines",
    author = "Hunter",
    description = "Allows pyros to drop firemines on death or with secondary Flamethrower fire.",
    version = PL_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=71404"
}

new g_FilteredEntity = -1;
new g_FiremineModelIndex;
new g_PlayerAmmo[MAXPLAYERS+1];
new g_FireminesRef[MAXENTITIES] = { INVALID_ENT_REFERENCE, ... };
new g_FireminesTime[MAXENTITIES];
new g_FireminesOwner[MAXENTITIES];
new bool:g_FiremineSeeking[MAXENTITIES];
new bool:g_PlayerButtonDown[MAXPLAYERS+1];
new Float:g_PlayerPosition[MAXPLAYERS+1][3];
new Handle:g_IsFireminesOn = INVALID_HANDLE;
new Handle:g_FireminesAmmo = INVALID_HANDLE;
new Handle:g_FireminesType = INVALID_HANDLE;
new Handle:g_FireminesMobile = INVALID_HANDLE;
new Handle:g_FireminesDamage = INVALID_HANDLE;
new Handle:g_FireminesRadius = INVALID_HANDLE;
new Handle:g_FireminesDetect = INVALID_HANDLE;
new Handle:g_FireminesProximity = INVALID_HANDLE;
new Handle:g_FireminesKeep = INVALID_HANDLE;
new Handle:g_FireminesStay = INVALID_HANDLE;
new Handle:g_FriendlyFire = INVALID_HANDLE;
new Handle:g_FireminesActTime = INVALID_HANDLE;
new Handle:g_FireminesLimit = INVALID_HANDLE;
new Handle:g_FireminesMax = INVALID_HANDLE;

new bool:g_NativeControl = false;
new g_Limit[MAXPLAYERS+1];      // how many mines player allowed
new g_Maximum[MAXPLAYERS+1];    // how many mines player can have active at once
new g_Remaining[MAXPLAYERS+1];  // how many mines player has this spawn
new bool:g_ChangingClass[MAXPLAYERS+1];

// forwards
new Handle:fwdOnSetMine;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
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

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("firemines.phrases");

    CreateConVar("sm_tf_firemines", PL_VERSION, "Firemines", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_IsFireminesOn = CreateConVar("sm_firemines","3","Enable/Disable firemines (0 = disabled | 1 = on death | 2 = on command | 3 = on death and command)", _, true, 0.0, true, 3.0);
    g_FireminesAmmo = CreateConVar("sm_firemines_ammo","100","Ammo required for Firemines", _, true, 0.0, true, 200.0);
    g_FireminesType = CreateConVar("sm_firemines_type","1","Explosion type of Firemines (0 = normal explosion | 1 = fire explosion | 2 = Spider Mine (chases enemies)", _, true, 0.0, true, 1.0);
    g_FireminesMobile = CreateConVar("sm_firemines_seeking","1","Seeking mines/Spider Mines (0 = mines don't move | 1 =  Mines chase enemies", _, true, 0.0, true, 1.0);
    g_FireminesDamage = CreateConVar("sm_firemines_damage","80","Explosion damage of Firemines", _, true, 0.0, true, 1000.0);
    g_FireminesRadius = CreateConVar("sm_firemines_radius","150","Explosion radius of Firemines", _, true, 0.0, true, 1000.0);
    g_FireminesDetect = CreateConVar("sm_firemines_detect","1000","Detection radius of SpiderMines", _, true, 0.0, true, 5000.0);
    g_FireminesProximity = CreateConVar("sm_firemines_proximity","100","Proximity radius of SpiderMines", _, true, 0.0, true, 1000.0);
    g_FireminesKeep = CreateConVar("sm_firemines_keep","180","Time to keep Firemines on map. (0 = off | >0 = seconds)", _, true, 0.0, true, 600.0);
    g_FireminesStay = CreateConVar("sm_firemines_stay","1","Firemines stay if the owner dies. (0 = no | 1 = yes)", _, true, 0.0, true, 1.0);
    g_FriendlyFire = FindConVar("mp_friendlyfire");

    g_FireminesActTime = CreateConVar("sm_firemines_activate_time", "2.0", "If the owner dies before activation time, mine is removed. (0 = off)", _, true, 0.0, true, 600.0);
    g_FireminesLimit = CreateConVar("sm_firemines_limit", "-1", "Number of firemines allowed per life (-1 = unlimited)", _, true, -1.0, true, 99.0);
    g_FireminesMax = CreateConVar("sm_firemines_max", "3", "Maximum Number of firemines allowed to be active per client (-1 = unlimited)", _, true, -1.0, true, 99.0);

    HookConVarChange(g_IsFireminesOn, ConVarChange_IsFireminesOn);
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

    if (GetConVarBool(g_FireminesType) || !GetConVarBool(g_FriendlyFire))
    {
        HookEntityOutput("prop_physics", "OnHealthChanged", EntityOutput:Entity_OnHealthChanged);
        HookEntityOutput("prop_physics_override", "OnHealthChanged", EntityOutput:Entity_OnHealthChanged);
    }

    CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);

    AutoExecConfig(true);
}

public OnMapStart()
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

    //AutoExecConfig(true);
}

public OnClientDisconnect(client)
{
    //g_Pyros[client] = false;
    g_ChangingClass[client] = false;
    g_PlayerButtonDown[client] = false;
    g_PlayerAmmo[client] = 0;
    g_PlayerPosition[client] = NULL_VECTOR;
    g_Remaining[client] = g_Limit[client] = g_Maximum[client] = 0;
}

// When a new client is put in the server we reset their mines count
public OnClientPutInServer(client)
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

public OnGameFrame()
{
    new FireminesOn = GetConVarInt(g_IsFireminesOn);
    if (FireminesOn < 2 && !g_NativeControl)
        return;

    for (new i = 1; i <= MaxClients; i++)
    {
        //if (g_Pyros[i] && !g_PlayerButtonDown[i] && IsClientInGame(i))
        if (g_Remaining[i] && !g_PlayerButtonDown[i] && IsClientInGame(i) &&
            TF2_GetPlayerClass(i) == TFClass_Pyro)
        {
            if (GetClientButtons(i) & IN_RELOAD)
            {
                g_PlayerButtonDown[i] = true;
                CreateTimer(0.5, Timer_ButtonUp, i);
                new String:classname[64];
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

public ConVarChange_IsFireminesOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
        PrintToChatAll("[SM] %t", "Enabled Firemines");
    else
        PrintToChatAll("[SM] %t", "Disabled Firemines");
}

public Action:Command_Firemine(client, args)
{
    new FireminesOn = GetConVarInt(g_IsFireminesOn);
    if (FireminesOn < 2 && !g_NativeControl)
        return Plugin_Handled;

    new DropType:cmd;
    if (g_NativeControl)
        cmd = OnCommand;
    else
    {
        new TFClassType:class = TF2_GetPlayerClass(client);
        if (class != TFClass_Pyro)
            return Plugin_Handled;

        new String:classname[64];
        GetCurrentWeaponClass(client, classname, 64);
        if(!StrEqual(classname, "CTFFlameThrower"))
            return Plugin_Handled;

        cmd = WithFlameThrower;
    }

    new bool:seeking = false;
    decl String:arg[16];
    if (args >= 1 && GetCmdArg(1,arg,sizeof(arg)))
        seeking = bool:StringToInt(arg);

    TF_DropFiremine(client, cmd, seeking);

    return Plugin_Handled;
}

public Action:Timer_Advert(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        new FireminesOn = GetConVarInt(g_IsFireminesOn);
        switch (FireminesOn)
        {
            case 1:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Firemines");
            case 2:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Firemines");
            case 3:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Firemines");
        }
    }
}

public Action:Timer_Caching(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        //if (g_Pyros[i] && IsClientInGame(i))
        if (IsClientInGame(i) && IsPlayerAlive(i) &&
            (g_NativeControl ? g_Limit[i] != 0 : TF2_GetPlayerClass(i) == TFClass_Pyro))
        {
            g_PlayerAmmo[i] = TF2_GetAmmoAmount(i);
            GetClientAbsOrigin(i, g_PlayerPosition[i]);
        }
    }

    new FireminesKeep = GetConVarInt(g_FireminesKeep);
    if (FireminesKeep > 0)
    {
        new time = GetTime() - FireminesKeep;
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            if (g_FireminesTime[c] != 0 && g_FireminesTime[c] < time)
            {
                new ref = g_FireminesRef[c];
                if (ref != INVALID_ENT_REFERENCE)
                {
                    new ent = EntRefToEntIndex(ref);
                    if (ent == c && g_FireminesTime[c] < time)
                    {
                        PrepareAndEmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        AcceptEntityInput(c, "kill");
                        ent = -1;
                    }
                    if (ent != c)
                    {
                        g_FireminesOwner[c] = 0;
                        g_FireminesTime[c] = 0;
                        g_FireminesRef[c] = INVALID_ENT_REFERENCE;
                    }
                }
            }
        }
    }
}

public Action:Timer_ButtonUp(Handle:timer, any:client)
{
    g_PlayerButtonDown[client] = false;
}

public Action:Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!IsClientInGame(client))
        return;

    g_ChangingClass[client] = true;

    new FireminesStay = GetConVarInt(g_FireminesStay);
    new Float:ActTime = GetConVarFloat(g_FireminesActTime);
    if (FireminesStay < 1 || ActTime > 0.0)
    {
        new Float:time = GetTime() - ActTime;
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            if (g_FireminesOwner[c] == client)
            {
                new ent = EntRefToEntIndex(g_FireminesRef[c]);
                if (ent != c || FireminesStay < 1 || g_FireminesTime[c] < time)
                {
                    g_FireminesOwner[c] = 0;
                    g_FireminesTime[c] = 0;
                    g_FireminesRef[c] = INVALID_ENT_REFERENCE;
                    if (c == ent && IsValidEntity(c))
                    {
                        PrepareAndEmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        AcceptEntityInput(c, "kill");
                    }
                }
            }
        }
    }

    new any:class = GetEventInt(event, "class");
    if (class != TFClass_Pyro)
    {
        //g_Pyros[client] = false;
        if (!g_NativeControl)
            return;
    }
    //g_Pyros[client] = true;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

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

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new FireminesOn = GetConVarInt(g_IsFireminesOn);
    if (FireminesOn < 1 && !g_NativeControl)
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

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    //if (!g_Pyros[client] || !IsClientInGame(client))
    if (!IsClientInGame(client))
        return;

    if (!g_NativeControl)
    {
        new TFClassType:class = TF2_GetPlayerClass(client); 
        if (class != TFClass_Pyro)
            return;
    }

    g_ChangingClass[client] = false;

    new FireminesStay = GetConVarInt(g_FireminesStay);
    new Float:ActTime = GetConVarFloat(g_FireminesActTime);
    if (FireminesStay < 1 || ActTime > 0.0)
    {
        new Float:time = GetTime() - ActTime;
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            if (g_FireminesOwner[c] == client)
            {
                new ent = EntRefToEntIndex(g_FireminesRef[c]);
                if (ent != c || FireminesStay < 1 || g_FireminesTime[c] < time)
                {
                    g_FireminesOwner[c] = 0;
                    g_FireminesTime[c] = 0;
                    g_FireminesRef[c] = INVALID_ENT_REFERENCE;
                    if (c == ent && IsValidEntity(c))
                    {
                        PrepareAndEmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        AcceptEntityInput(c, "kill");
                    }
                }
            }
        }
    }

    if (g_NativeControl)
    {
        if (g_Remaining[client] == 0)
            return;
    }

    if (FireminesOn != 2 || g_NativeControl)
        TF_DropFiremine(client, OnDeath, false);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client != 0)
    {
        new team = GetEventInt(event, "team");
        if (team < 2 && IsClientInGame(client))
        {
            //g_Pyros[client] = false;
            g_PlayerButtonDown[client] = false;
            g_PlayerAmmo[client] = 0;
            g_PlayerPosition[client] = NULL_VECTOR;
        }
    }
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        new ent = EntRefToEntIndex(g_FireminesRef[c]);
        g_FireminesOwner[c] = 0;
        g_FireminesTime[c] = 0;
        g_FireminesRef[c] = INVALID_ENT_REFERENCE;
        if (c == ent && IsValidEntity(c))
            AcceptEntityInput(c, "kill");
    }
}

public Entity_OnHealthChanged(const String:output[], caller, activator, Float:delay)
{
    if (caller > 0 && activator > 0 && activator <= MaxClients && g_FireminesTime[caller] > 0 &&
        caller == EntRefToEntIndex(g_FireminesRef[caller]) && IsClientInGame(activator))
    {
        // Make sure it's a Firemine and the owner is still in the game
        new owner=GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
        if (owner == g_FireminesOwner[caller] && IsClientInGame(owner))
        {
            new team = 0;
            if (!GetConVarBool(g_FriendlyFire))
                team = GetEntProp(caller, Prop_Send, "m_iTeamNum");

            if (team != GetClientTeam(activator) || activator == owner)
            {
                if (GetConVarBool(g_FireminesType))
                {
                    decl Float:vecPos[3];
                    GetEntPropVector(caller, Prop_Send, "m_vecOrigin", vecPos);

                    decl Float:PlayerPosition[3];
                    new Float:maxdistance = GetConVarFloat(g_FireminesRadius);
                    for (new i = 1; i <= MaxClients; i++)
                    {
                        if (IsClientInGame(i))
                        {
                            GetClientAbsOrigin(i, PlayerPosition);
                            new Float:distance = GetVectorDistance(PlayerPosition, vecPos);
                            if (distance < 0.0)
                                distance *= -1.0;

                            if (distance <= maxdistance)
                            {
                                if (i == owner)
                                    IgniteEntity(i, 2.5);
                                else if (team != GetClientTeam(i))
                                {
                                    if (!TF2_IsPlayerUbercharged(i))
                                    {
                                        if (owner > 0 && IsClientInGame(owner))
                                            TF2_IgnitePlayer(i, owner);
                                        else
                                            IgniteEntity(i, 2.5);
                                    }
                                }
                            }

                            if (g_Remaining[i])
                            {
                                g_PlayerAmmo[i] = TF2_GetAmmoAmount(i);
                                g_PlayerPosition[i] = PlayerPosition;
                            }
                        }
                    }
                }

                AcceptEntityInput(caller, "Break", owner, owner);
                CreateTimer(0.2, RemoveMine, EntIndexToEntRef(caller));

                g_FireminesOwner[caller] = 0;
                g_FireminesTime[caller] = 0;
                g_FireminesRef[caller] = INVALID_ENT_REFERENCE;
            }
        }
    }
}

public bool:FiremineTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

TF_SpawnFiremine(client, DropType:cmd, bool:seeking)
{
    new Float:PlayerPosition[3];
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
            new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
            GetClientEyeAngles(client, PlayerAngle);
            PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[2] = 0.0;
            ScaleVector(PlayerPosEx, 75.0);
            AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

            new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID,
                                                     RayType_EndPoint, FiremineTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        new Float:Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID,
                                               RayType_EndPoint, FiremineTraceFilter);

        new Float:MinePos[3];
        TR_GetEndPosition(MinePos, Trace);
        CloseHandle(Trace);
        MinePos[2] += 1;

        new Firemine = CreateEntityByName("prop_physics_override");
        if (Firemine > 0 && IsValidEntity(Firemine))
        {
            if (seeking)
                DispatchKeyValue(Firemine, "spawnflags", "48");
            else
                DispatchKeyValue(Firemine, "spawnflags", "152");

            SetEntPropEnt(Firemine, Prop_Send, "m_hOwnerEntity", client);
            SetEntPropFloat(Firemine, Prop_Data, "m_flGravity", 0.0);

            // Ensure the mine model is precached
            PrepareModel(MINE_MODEL, g_FiremineModelIndex, true);
            SetEntityModel(Firemine, MINE_MODEL);

            new String:targetname[32];
            Format(targetname, sizeof(targetname), "firemine_%d", Firemine);
            DispatchKeyValue(Firemine, "targetname", targetname);

            new team = GetConVarBool(g_FriendlyFire) ? 0 : GetClientTeam(client);
            SetEntProp(Firemine, Prop_Send, "m_iTeamNum", team, 4);
            SetEntProp(Firemine, Prop_Send, "m_nSolidType", 6);
            SetEntProp(Firemine, Prop_Data, "m_takedamage", 3);
            SetEntPropEnt(Firemine, Prop_Data, "m_hLastAttacker", client);
            SetEntPropEnt(Firemine, Prop_Data, "m_hPhysicsAttacker", client);
            DispatchKeyValue(Firemine, "physdamagescale", "1.0");

            DispatchKeyValue(Firemine, "StartDisabled", "false");
            DispatchSpawn(Firemine);

            TeleportEntity(Firemine, MinePos, NULL_VECTOR, NULL_VECTOR);

            DispatchKeyValue(Firemine, "OnBreak", "!self,Kill,,0,-1");
            DispatchKeyValueFloat(Firemine, "ExplodeDamage", GetConVarFloat(g_FireminesDamage));
            DispatchKeyValueFloat(Firemine, "ExplodeRadius", GetConVarFloat(g_FireminesRadius));

            // we might handle this ourself now...
            if (!GetConVarBool(g_FireminesType) && GetConVarBool(g_FriendlyFire))
                DispatchKeyValue(Firemine, "OnHealthChanged", "!self,Break,,0,-1");

            PrepareAndEmitSoundToAll(SOUND_B, Firemine, _, _, _, 0.75);

            g_FireminesRef[Firemine] = EntIndexToEntRef(Firemine);
            g_FireminesTime[Firemine] = GetTime();
            g_FireminesOwner[Firemine] = client;
            g_FiremineSeeking[Firemine] =  false;
            return Firemine;
        }
    }
    return 0;
}

bool:TF_DropFiremine(client, DropType:cmd, bool:seeking)
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

    new max = g_Maximum[client];
    if (max > 0)
    {
        new count = CountMines(client);
        if (count > max)
        {
            PrepareAndEmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
            PrintHintText(client, "You already have %d mines active.", count);
            return false;
        }
    }

    new ammo = (cmd == OnDeath) ? g_PlayerAmmo[client] : TF2_GetAmmoAmount(client);
    new FireminesAmmo = GetConVarInt(g_FireminesAmmo);
    new TFClassType:class = TF2_GetPlayerClass(client);
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

    if (ammo >= FireminesAmmo)
    {
        new Action:res = Plugin_Continue;
        Call_StartForward(fwdOnSetMine);
        Call_PushCell(client);
        Call_Finish(res);
        if (res != Plugin_Continue)
            return false;

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

            ammo -= FireminesAmmo;
            g_PlayerAmmo[client] = ammo;
            TF2_SetAmmoAmount(client, ammo);

            // update client's inventory
            if (g_Remaining[client] > 0)
                g_Remaining[client]--;
        }

        new mine = TF_SpawnFiremine(client, cmd, bool:seeking);

        if (seeking)
        {
            new Float:ActTime = GetConVarFloat(g_FireminesActTime);
            CreateTimer(ActTime, MineActivate, EntIndexToEntRef(mine));
        }

        return true;
    }
    else if (cmd != OnDeath)
    {
        PrepareAndEmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
    }
    return false;
}

CountMines(client)
{
    new count = 0;
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        if (g_FireminesOwner[c] == client)
        {
            new ref = g_FireminesRef[c];
            if (ref != INVALID_ENT_REFERENCE)
            {
                if (EntRefToEntIndex(ref) == c)
                    count++;
                else
                {
                    g_FireminesRef[c] = INVALID_ENT_REFERENCE;
                    g_FireminesTime[c] = 0;
                    g_FireminesOwner[c] = 0;
                }
            }
        }
    }
    return count;
}

public Action:RemoveMine(Handle:timer, any:mineRef)
{
    // Remove the mine, if it's still there
    new mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
    {
        LogError("Removing Mine %d!", mine);
        AcceptEntityInput(mine, "kill");
        g_FireminesOwner[mine] = 0;
        g_FireminesTime[mine] = 0;
        g_FireminesRef[mine] = INVALID_ENT_REFERENCE;
    }
    return Plugin_Stop;
}

public Action:MineActivate(Handle:timer, any:mineRef)
{
    // Ensure the entity is still a mine
    new mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
        CreateTimer(0.2, MineSeek, mineRef, TIMER_REPEAT);

    return Plugin_Stop;
}

public Action:MineSeek(Handle:timer, any:mineRef)
{
    // Ensure the entity is still a mine
    new mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
    {
        decl Float:minePos[3], Float:PlayerPosition[3];
        GetEntPropVector(mine, Prop_Send, "m_vecOrigin", minePos);

        new target = 0;
        new team = GetEntProp(mine, Prop_Send, "m_iTeamNum");
        new Float:detect = GetConVarFloat(g_FireminesDetect);
        new Float:proximity = GetConVarFloat(g_FireminesProximity);

        // Find closest enemy within range
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) &&
                GetClientTeam(i) != team)
            {
                GetClientAbsOrigin(i, PlayerPosition);
                new Float:distance = GetVectorDistance(minePos, PlayerPosition);
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
                            Entity_OnHealthChanged("OnProximity", mine, i, 0.0);
                            return Plugin_Stop;
                        }
                    }

                    TR_TraceRayFilter(minePos, PlayerPosition, MASK_SOLID, RayType_EndPoint,
                                      TraceRayDontHitSelf, mine);
                    if (TR_GetEntityIndex() == i)
                    {
                        target = i;
                        detect = distance;
                    }
                }
            }
        }

        // Did we find a target?
        if (target > 0)
        {
            decl Float:vector[3], Float:angles[3];
            GetClientEyePosition(target, PlayerPosition);
            MakeVectorFromPoints(minePos, PlayerPosition, vector);
            NormalizeVector(vector, vector);

            GetVectorAngles(vector, angles);
            TeleportEntity(mine, NULL_VECTOR, angles, NULL_VECTOR);

            SetEntityRenderMode(mine, RENDER_GLOW);
            SetEntityRenderColor(mine, (team == 2) ? 255 : 0, 0, (team == 3) ? 0 : 255, 255);

            if (!g_FiremineSeeking[mine])
            {
                minePos[2] += 20.0;

                TeleportEntity(mine, minePos, NULL_VECTOR, NULL_VECTOR);
                g_FiremineSeeking[mine] =  true;
            }

            decl Float:velocity[3];
            velocity[0] = vector[0] * 80.0;
            velocity[1] = vector[1] * 80.0;
            velocity[2] = 10.0;

            TeleportEntity(mine, NULL_VECTOR, NULL_VECTOR, velocity);

            PrepareAndEmitSoundToAll(SOUND_C, mine);
        }
        else if (g_FiremineSeeking[mine])
        {
            new Float:angles[3] = {0.0,0.0,0.0};
            TeleportEntity(mine, NULL_VECTOR, angles, NULL_VECTOR);

            new Float:vecBelow[3];
            vecBelow[0] = minePos[0];
            vecBelow[1] = minePos[1];
            vecBelow[2] = minePos[2] - 2000.0;

            new Float:vecMins[3];
            GetEntPropVector(mine, Prop_Send, "m_vecMins", vecMins);

            new Float:vecMaxs[3];
            GetEntPropVector(mine, Prop_Send, "m_vecMaxs", vecMaxs);

            //TR_TraceRayFilter(minePos, vecBelow, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayDontHitSelf, mine);
            TR_TraceHullFilter(minePos, vecBelow, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRayDontHitSelf, mine);
            if (TR_DidHit(INVALID_HANDLE))
            {
                // Move mine down to ground.
                TR_GetEndPosition(minePos, INVALID_HANDLE);
                TeleportEntity(mine, minePos, NULL_VECTOR, NULL_VECTOR);
            }

            SetEntityRenderColor(mine, 255, 255, 255, 255);
            SetEntityRenderMode(mine, RENDER_NORMAL);
            g_FiremineSeeking[mine] =  false;

            PrepareAndEmitSoundToAll(SOUND_B, mine);
        }
        return Plugin_Continue;
    }
    return Plugin_Stop;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    return (entity != data); // Check if the TraceRay hit the itself.
}

public Native_ControlMines(Handle:plugin,numParams)
{
    g_NativeControl = GetNativeCell(1);
}

public Native_GiveMines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    g_Remaining[client] = GetNativeCell(2);
    g_Limit[client] = GetNativeCell(3);
    g_Maximum[client] = GetNativeCell(4);

    if (g_Maximum[client] < 0)
        g_Maximum[client] = GetConVarInt(g_FireminesMax);
}

public Native_TakeMines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        g_Remaining[client] = g_Limit[client] = g_Maximum[client] = 0;
    }
}

public Native_AddMines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (g_Limit[client] >= 0)
    {
        g_Remaining[client] += GetNativeCell(2);
    }
}

public Native_SubMines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (g_Limit[client] >= 0)
    {
        g_Remaining[client] -= GetNativeCell(2);
        if (g_Remaining[client] < 0)
            g_Remaining[client] = 0;
    }
}

public Native_HasMines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    return (GetNativeCell(2)) ? g_Limit[client] : g_Remaining[client];
}

public Native_SetMine(Handle:plugin,numParams)
{
    new bool:seeking = bool:GetNativeCell(2);
    TF_DropFiremine(GetNativeCell(1), OnCommand, seeking);
}

public Native_CountMines(Handle:plugin,numParams)
{
    return CountMines(GetNativeCell(1));
}
