/*
 * vim: set ai et! ts=4 sw=4 :
 * [TF2] Wrangle Monoculus
 * Author(s): FlaminSarge
 * File: wrangleye.sp
 * Description: Allows someone to direct the Monoculus
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"

#define ADMFLAG_EYEBOSS	ADMFLAG_SLAY	

new iCurrentWrangler = 0;

new bool:gNativeOverride = false;

public Plugin:myinfo = 
{
    name = "[TF2] Wrangle Monoculus",
    author = "FlaminSarge, -=|JFH|=-Naris",
    description = "Direct where MONOCULUS aims!",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
    CreateConVar("sm_wrangleye_version", PLUGIN_VERSION, "[TF2] Wrangle Monoculus Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    HookEvent("player_death", player_death, EventHookMode_Pre);
    RegAdminCmd("sm_wrangleeye", WrangleMonoculus, ADMFLAG_EYEBOSS);
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!IsValidClient(iCurrentWrangler)) return Plugin_Continue;

    new client = GetClientOfUserId(GetEventInt(event, "attacker"));
    if (iCurrentWrangler == client)
        iCurrentWrangler = 0;
    else
    {
        decl String:wep[64];
        GetEventString(event, "weapon", wep, sizeof(wep));
        if (client == 0 && StrEqual(wep, "eyeball_rocket"))
        {
            SetEventInt(event, "assister", GetClientUserId(iCurrentWrangler));
        }
    }

    return Plugin_Continue;
}

public Action:WrangleMonoculus(client, args)
{
    if (gNativeOverride)
    {
        ReplyToCommand(client, "This command has been disabled by the server.");
        return Plugin_Handled;
    }
    else if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[SM] Command is in-game only.");
        return Plugin_Handled;
    }

    new String:arg1[32] = "1";
    if (args == 1)
        GetCmdArg(1, arg1, sizeof(arg1));

    new bool:onoff = bool:StringToInt(arg1);
    if (!onoff)
    {
        if (client != iCurrentWrangler)
        {
            ReplyToCommand(client, "[SM] You are already not controlling MONOCULUS!");
            return Plugin_Handled;
        }
        else
        {
            ReplyToCommand(client, "[SM] You have relinquished control of MONOCULUS!");
            iCurrentWrangler = 0;
            return Plugin_Handled;
        }
    }

    if (iCurrentWrangler != 0 && iCurrentWrangler != client && IsValidClient(iCurrentWrangler))
    {
        PrintToChat(iCurrentWrangler, "[SM] %N has taken over control of MONOCULUS!", client);
    }

    iCurrentWrangler = client;
    ReplyToCommand(client, "[SM] You are now wrangling MONOCULUS!");
    return Plugin_Handled;
}

public OnClientPutInServer(client)
{
    if (client == iCurrentWrangler)
        iCurrentWrangler = 0;
}

public OnClientDisconnect_Post(client)
{
    OnClientPutInServer(client);
}

public OnGameFrame()
{
    if (!IsValidClient(iCurrentWrangler)) return;

    decl Float:pos[3];
    GetPlayerEye(iCurrentWrangler, pos);

    new eye = -1;
    while ((eye = FindEntityByClassname(eye, "eyeball_boss")) != -1)
    {
        SetEntPropVector(eye, Prop_Send, "m_lookAtSpot", pos);
    }
}

stock bool:GetPlayerEye(client, Float:pos[3])
{
    new Float:vAngles[3], Float:vOrigin[3];
    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);

    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);

    if(TR_DidHit(trace))
    {
        TR_GetEndPosition(pos, trace);
        CloseHandle(trace);
        return true;
    }
    CloseHandle(trace);
    return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)
{
    if ( entity <= 0 ) return true;
    if ( entity == data ) return false;

    decl String:sClassname[128];
    GetEdictClassname(entity, sClassname, sizeof(sClassname));
    if(StrEqual(sClassname, "func_respawnroomvisualizer", false))
        return false;
    else
        return true;
}

stock bool:IsValidClient(client)
{
    if (client <= 0) return false;
    if (client > MaxClients) return false;
    return IsClientInGame(client);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!IsValidClient(iCurrentWrangler)) return;
    if (strcmp(classname, "tf_projectile_rocket", false) == 0)
        SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawned);
}

public OnRocketSpawned(entity)
{
    new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if (IsValidEntity(owner))
    {
        decl String:classname[32];
        GetEdictClassname(owner, classname, sizeof(classname));
        if (strcmp(classname, "eyeball_boss", false) == 0)
        {
            CreateTimer(0.0, Timer_SetRocket, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:Timer_SetRocket(Handle:timer, any:ref)
{
    if (!IsValidClient(iCurrentWrangler)) return;
    decl Float:pos[3];
    GetPlayerEye(iCurrentWrangler, pos);
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent))
    {
        new owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
        decl Float:orig[3], Float:ang[3], Float:vel[3];
        GetEntPropVector(owner, Prop_Send, "m_vecOrigin", orig);
        MakeVectorFromPoints(orig, pos, orig);
        GetVectorAngles(orig, ang);
        GetEntPropVector(ent, Prop_Send, "m_vInitialVelocity", vel);
        new Float:speed = GetVectorLength(vel);
        NormalizeVector(orig, vel);
        ScaleVector(vel, speed);
        TeleportEntity(ent, NULL_VECTOR, ang, vel);
    }
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Native
    CreateNative("TF2_WrangleMonoculus",Native_Wrangleeyeboss);
    CreateNative("ControlWrangleMonoculus",Native_Control);
    RegPluginLibrary("wrangleye");
    return APLRes_Success;
}

public Native_Control(Handle:plugin,numParams)
{
    gNativeOverride |= GetNativeCell(1);
}

public Native_Wrangleeyeboss(Handle:plugin,numParams)
{
    if (!GetNativeCell(2) &&
        IsValidClient(iCurrentWrangler) &&
        IsPlayerAlive(iCurrentWrangler))
    {
        return false;
    }
    else
    {
        new client = GetNativeCell(1);
        if (IsValidClient(client) &&
            IsPlayerAlive(client))
        {
            iCurrentWrangler = GetNativeCell(1);
            return true;
        }
        else
        {
            return false;
        }
    }
}
