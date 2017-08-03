/*
 *  vim: set ai et ts=4 sw=4 :
 *
 *  TF2 Ammopacks - SourceMod Plugin
 *  Copyright (C) 2009  Marc H�rsken
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

#include <sourcemod>
#include <sdktools>

#include <tf2>
#include <tf2_stocks>
#include "tf2_ammo"

#include "weapons"
#include "entlimit"

#undef REQUIRE_PLUGIN
#include "lib/ResourceManager"
#define REQUIRE_PLUGIN

#define PL_VERSION "1.4"

#define SOUND_A         "weapons/smg_clip_out.wav"
#define SOUND_B         "items/spawn_item.wav"
#define SOUND_C         "ui/hint.wav"

#define SMALL_MODEL     "models/items/ammopack_small.mdl"
#define LARGE_MODEL     "models/items/ammopack_large.mdl"
#define MEDIUM_MODEL    "models/items/ammopack_medium.mdl"

public Plugin:myinfo = 
{
    name = "TF2 Ammopacks",
    author = "Hunter",
    description = "Allows engineers to drop ammopacks on death or with secondary Wrench fire.",
    version = PL_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=65355"
}

new bool:g_NativeControl = false;
new bool:g_EngiButtonDown[MAXPLAYERS+1];
new Float:g_EngiPosition[MAXPLAYERS+1][3];
new g_NativeAmmopacks[MAXPLAYERS+1];
new g_EngiMetal[MAXPLAYERS+1];
new g_AmmopacksCount = 0;
new g_FilteredEntity = -1;
new Handle:g_IsAmmopacksOn = INVALID_HANDLE;
new Handle:g_AmmopacksSmall = INVALID_HANDLE;
new Handle:g_AmmopacksMedium = INVALID_HANDLE;
new Handle:g_AmmopacksFull = INVALID_HANDLE;
new Handle:g_AmmopacksKeep = INVALID_HANDLE;
new Handle:g_AmmopacksTeam = INVALID_HANDLE;
new Handle:g_AmmopacksLimit = INVALID_HANDLE;
new Handle:g_AmmopacksTime = INVALID_HANDLE;
new Handle:g_AmmopacksRef = INVALID_HANDLE;

new g_LargeModel = 0;
new g_SmallModel = 0;
new g_MediumModel = 0;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("ControlAmmopacks", Native_ControlAmmopacks);
    CreateNative("SetAmmopack", Native_SetAmmopack);
    CreateNative("DropAmmopack", Native_DropAmmopack);
    RegPluginLibrary("ammopacks");
    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("ammopacks.phrases");

    HookConVarChange(CreateConVar("sm_tf_ammopacks", PL_VERSION, "Ammopacks", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), ConVarChange_Version);
    g_IsAmmopacksOn = CreateConVar("sm_ammopacks","3","Enable/Disable ammopacks (0=disabled|1=on death|2=on command|3=on death and command)", _, true, 0.0, true, 3.0);
    g_AmmopacksSmall = CreateConVar("sm_ammopacks_small","50","Metal required for small Ammopacks", _, true, 0.0, true, 200.0);
    g_AmmopacksMedium = CreateConVar("sm_ammopacks_medium","100","Metal required for medium Ammopacks", _, true, 0.0, true, 200.0);
    g_AmmopacksFull = CreateConVar("sm_ammopacks_full","200","Metal required for full Ammopacks", _, true, 0.0, true, 200.0);
    g_AmmopacksKeep = CreateConVar("sm_ammopacks_keep","60","Time to keep Ammopacks on map. (0=off|>0=seconds)", _, true, 0.0, true, 600.0);
    g_AmmopacksTeam = CreateConVar("sm_ammopacks_team","3","Team to drop Ammopacks for. (0=any team|1=own team|2=opposing team|3=own on command, any on death)", _, true, 0.0, true, 3.0);
    g_AmmopacksLimit = CreateConVar("sm_ammopacks_limit","100","Maximum number of extra Ammopacks on map at a time. (0=unlimited)", _, true, 0.0, true, 512.0);

    new maxents = GetMaxEntities();
    g_AmmopacksTime = CreateArray(_, maxents);
    g_AmmopacksRef = CreateArray(_, maxents);

    HookConVarChange(g_IsAmmopacksOn, ConVarChange_IsAmmopacksOn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("teamplay_round_start", Event_TeamplayRoundStart);
    HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    RegConsoleCmd("sm_ammopack", Command_Ammopack);
    RegAdminCmd("sm_metal", Command_MetalAmount, ADMFLAG_CHEATS);

    CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);

    AutoExecConfig(true);
}

public OnMapStart()
{
    SetupModel(LARGE_MODEL, g_LargeModel);
    SetupModel(MEDIUM_MODEL, g_SmallModel);
    SetupModel(SMALL_MODEL, g_MediumModel);

    SetupSound(SOUND_A, true, DONT_DOWNLOAD, false, false);
    SetupSound(SOUND_B, true, DONT_DOWNLOAD, false, false);
    SetupSound(SOUND_C, true, DONT_DOWNLOAD, true,  true);

    new maxents = GetMaxEntities();
    ClearArray(g_AmmopacksRef);
    ClearArray(g_AmmopacksTime);
    ResizeArray(g_AmmopacksRef, maxents);
    ResizeArray(g_AmmopacksTime, maxents);
    g_AmmopacksCount = 0;

    AutoExecConfig(true);
}

public OnClientDisconnect(client)
{
    g_EngiButtonDown[client] = false;
    g_EngiMetal[client] = 0;
    g_EngiPosition[client] = NULL_VECTOR;
}

public OnClientPutInServer(client)
{
    if(!g_NativeControl && GetConVarBool(g_IsAmmopacksOn))
        CreateTimer(45.0, Timer_Advert, client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (buttons & IN_ATTACK2 && !g_EngiButtonDown[client])
    {
        if (!g_NativeControl && GetConVarInt(g_IsAmmopacksOn) < 2)
            return Plugin_Continue;
        else if (g_NativeControl && g_NativeAmmopacks[client] < 2)
            return Plugin_Continue;
        else if (TF2_GetPlayerClass(client) == TFClass_Engineer)
        {
            g_EngiButtonDown[client] = true;
            CreateTimer(0.5, Timer_ButtonUp, client);

            new String:classname[64];
            GetCurrentWeaponClass(client, classname, 64);
            if(StrEqual(classname, "CTFWrench"))
                TF_DropAmmopack(client, true);
        }
    }
    return Plugin_Continue;
}

public ConVarChange_Version(Handle:convar, const String:oldValue[], const String:newValue[])
{
    SetConVarString(convar, PL_VERSION);
}

public ConVarChange_IsAmmopacksOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
        PrintToChatAll("[SM] %t", "Enabled Ammopacks");
    else
        PrintToChatAll("[SM] %t", "Disabled Ammopacks");
}

public Action:Command_Ammopack(client, args)
{
    new AmmopacksOn = g_NativeControl ? g_NativeAmmopacks[client]
                                      : GetConVarInt(g_IsAmmopacksOn);
    if (AmmopacksOn < 2)
        return Plugin_Handled;

    new TFClassType:class = TF2_GetPlayerClass(client);
    if (class != TFClass_Engineer)
        return Plugin_Handled;

    new String:classname[64];
    GetCurrentWeaponClass(client, classname, 64);
    if(!StrEqual(classname, "CWrench"))
        return Plugin_Handled;

    TF_DropAmmopack(client, true);

    return Plugin_Handled;
}

public Action:Command_MetalAmount(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] %t", "Metal Usage");
        return Plugin_Handled;
    }

    new String:arg1[32], String:arg2[32];
    GetCmdArg(1, arg1, sizeof(arg1));

    new target = FindTarget(client, arg1);
    if (target == -1)
    {
        return Plugin_Handled;
    }

    new String:name[MAX_NAME_LENGTH];
    GetClientName(target, name, sizeof(name));

    new bool:alive = IsPlayerAlive(target);
    if (!alive)
    {
        ReplyToCommand(client, "[SM] %t", "Cannot be performed on dead", name);
        return Plugin_Handled;
    }

    new TFClassType:class = TF2_GetPlayerClass(target);
    if (class != TFClass_Engineer)
    {
        ReplyToCommand(client, "[SM] %t", "Not a Engineer", name);
        return Plugin_Handled;
    }

    new charge = 100;
    if (args > 1)
    {
        GetCmdArg(2, arg2, sizeof(arg2));
        charge = StringToInt(arg2);
        if (charge < 0 || charge > 200)
        {
            ReplyToCommand(client, "[SM] %t", "Invalid Amount");
            return Plugin_Handled;
        }
    }

    TF2_SetMetalAmount(target, charge);

    ReplyToCommand(client, "[SM] %t", "Changed Metal", name, charge);
    return Plugin_Handled;
}

public Action:Timer_Advert(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        new AmmopacksOn = GetConVarInt(g_IsAmmopacksOn);
        switch (AmmopacksOn)
        {
            case 1:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Ammopacks");
            case 2:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Ammopacks");
            case 3:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Ammopacks");
        }
    }
}

public Action:Timer_Caching(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Engineer)
        {
            g_EngiMetal[i] = TF2_GetMetalAmount(i);
            GetClientAbsOrigin(i, g_EngiPosition[i]);
        }
    }

    new AmmopacksKeep = GetConVarInt(g_AmmopacksKeep);
    new AmmopacksLimit = GetConVarInt(g_AmmopacksLimit);
    if (AmmopacksKeep > 0 || AmmopacksLimit > 0)
    {
        new maxents = GetMaxEntities();
        new mintime = GetTime() - AmmopacksKeep;
        for (new c = MaxClients; c < maxents; c++)
        {
            new time = GetArrayCell(g_AmmopacksTime, c);
            if (time > 0)
            {
                new bool:valid = (EntRefToEntIndex(GetArrayCell(g_AmmopacksRef, c)) == c &&
                                 IsValidEdict(c));
                if (valid)
                {
                    if (AmmopacksKeep > 0 && time < mintime)
                    {
                        EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        AcceptEntityInput(c, "kill");
                        valid = false;
                    }
                }

                if (!valid)
                {
                    g_AmmopacksCount--;
                    SetArrayCell(g_AmmopacksRef, c, INVALID_ENT_REFERENCE);
                    SetArrayCell(g_AmmopacksTime, c, 0.0);
                }
            }
        }
    }
}

public Action:Timer_ButtonUp(Handle:timer, any:client)
{
    g_EngiButtonDown[client] = false;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
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
    if (!IsClientInGame(client))
        return;

    new AmmopacksOn = g_NativeControl ? g_NativeAmmopacks[client] : GetConVarInt(g_IsAmmopacksOn);
    if (AmmopacksOn < 1 || AmmopacksOn == 2)
        return;

    new TFClassType:class = TF2_GetPlayerClass(client);	
    if (class != TFClass_Engineer)
        return;

    TF_DropAmmopack(client, false);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new disconnect = GetEventInt(event, "disconnect");
    if (disconnect)
        return;

    new team = GetEventInt(event, "team");
    if (team > 1)
        return;

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client))
        return;

    g_EngiButtonDown[client] = false;
    g_EngiMetal[client] = 0;
    g_EngiPosition[client] = NULL_VECTOR;
}

public Action:Event_TeamplayRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new full_reset = GetEventInt(event, "full_reset");
    if (full_reset)
    {
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            new time = GetArrayCell(g_AmmopacksTime, c);
            if (time > 0)
            {
                SetArrayCell(g_AmmopacksRef, c, INVALID_ENT_REFERENCE);
                SetArrayCell(g_AmmopacksTime, c, 0.0);
                g_AmmopacksCount--;
            }
        }
    }
}

public Action:Entity_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
    if (activator > 0 && caller > 0)
    {
        new time = GetArrayCell(g_AmmopacksTime, caller);
        if (time > 0)
        {
            SetArrayCell(g_AmmopacksRef, caller, INVALID_ENT_REFERENCE);
            SetArrayCell(g_AmmopacksTime, caller, 0.0);
            g_AmmopacksCount--;
        }
    }
}

public bool:AmmopackTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

stock TF_SpawnAmmopack(client, String:name[], bool:cmd)
{
    new Float:PlayerPosition[3];
    if (cmd)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_EngiPosition[client];

    if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 &&
        !IsEntLimitReached(.client=client,.message="unable to create ammopack"))
    {
        PlayerPosition[2] += 4;
        g_FilteredEntity = client;
        if (cmd)
        {
            new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
            GetClientEyeAngles(client, PlayerAngle);
            PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[2] = 0.0;
            ScaleVector(PlayerPosEx, 75.0);
            AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

            new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        new Float:Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);

        new Float:AmmoPos[3];
        TR_GetEndPosition(AmmoPos, Trace);
        CloseHandle(Trace);
        AmmoPos[2] += 4;

        new Ammopack = CreateEntityByName(name);
        if (Ammopack > 0 && IsValidEntity(Ammopack))
        {
            DispatchKeyValue(Ammopack, "OnPlayerTouch", "!self,Kill,,0,-1");
            if (DispatchSpawn(Ammopack))
            {
                new team = 0;
                new AmmopacksTeam = GetConVarInt(g_AmmopacksTeam);
                if (AmmopacksTeam == 2)
                    team = ((GetClientTeam(client)-1) % 2) + 2;
                else if (AmmopacksTeam == 1 || (AmmopacksTeam == 3 && cmd))
                    team = GetClientTeam(client);

                SetEntProp(Ammopack, Prop_Send, "m_iTeamNum", team, 4);
                TeleportEntity(Ammopack, AmmoPos, NULL_VECTOR, NULL_VECTOR);
                SetArrayCell(g_AmmopacksRef, Ammopack, EntIndexToEntRef(Ammopack));
                SetArrayCell(g_AmmopacksTime, Ammopack, GetTime());
                g_AmmopacksCount++;

                if (PrepareSound(SOUND_B))
                    EmitSoundToAll(SOUND_B, Ammopack, _, _, _, 0.75);
            }
        }
    }
}

stock bool:TF_DropAmmopack(client, bool:cmd)
{
    new metal;
    if (cmd)
        metal = TF2_GetMetalAmount(client);
    else
        metal = g_EngiMetal[client];

    new AmmopacksLimit = GetConVarInt(g_AmmopacksLimit);
    if (AmmopacksLimit > 0 && g_AmmopacksCount >= AmmopacksLimit)
        metal = 0;

    new AmmopacksSmall = GetConVarInt(g_AmmopacksSmall);
    new AmmopacksMedium = GetConVarInt(g_AmmopacksMedium);
    new AmmopacksFull = GetConVarInt(g_AmmopacksFull);
    if (metal >= AmmopacksFull && AmmopacksFull != 0)
    {
        if (cmd) TF2_SetMetalAmount(client, (metal-AmmopacksFull));
        PrepareModel(LARGE_MODEL, g_LargeModel);
        TF_SpawnAmmopack(client, "item_ammopack_full", cmd);
        return true;
    }
    else if (metal >= AmmopacksMedium && AmmopacksMedium != 0)
    {
        if (cmd) TF2_SetMetalAmount(client, (metal-AmmopacksMedium));
        PrepareModel(MEDIUM_MODEL, g_SmallModel);
        TF_SpawnAmmopack(client, "item_ammopack_medium", cmd);
        return true;
    }
    else if (metal >= AmmopacksSmall && AmmopacksSmall != 0)
    {
        if (cmd) TF2_SetMetalAmount(client, (metal-AmmopacksSmall));
        PrepareModel(SMALL_MODEL, g_MediumModel);
        TF_SpawnAmmopack(client, "item_ammopack_small", cmd);
        return true;
    }
    else if (cmd && PrepareSound(SOUND_A))
    {
        EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
    }
    return false;
}

public Native_ControlAmmopacks(Handle:plugin, numParams)
{
    g_NativeControl = GetNativeCell(1);
}

public Native_SetAmmopack(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    g_NativeAmmopacks[client] = GetNativeCell(2);
}

public Native_DropAmmopack(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new metal = GetNativeCell(2);

    if (metal >= 0)
    {
        g_EngiMetal[client] = metal;
        return TF_DropAmmopack(client, false);
    }
    else
        return TF_DropAmmopack(client, true);
}
