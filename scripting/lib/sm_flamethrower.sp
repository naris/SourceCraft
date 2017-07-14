// vim: set ai et! ts=4 sw=4 :
//
// SourceMod Script
//
// Developed by <eVa>Dog
// October 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// This plugin is a port of my Flamethrower plugin
// originally created using EventScripts

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>

#define PLUGIN_VERSION "2.0.1"

#define ADMIN_LEVEL ADMFLAG_SLAY

#define EMPTY_SOUND "weapons/ar2/ar2_empty.wav"

new flameGiven[MAXPLAYERS+1];
new flameAmount[MAXPLAYERS+1];
new Float:flameRange[MAXPLAYERS+1];
new bool:flameEnabled[MAXPLAYERS+1];

new String:g_flameSound[PLATFORM_MAX_PATH];

new bool:g_NativeControl = false;

new Handle:g_Cvar_FlameAmount = INVALID_HANDLE;
new Handle:g_Cvar_FlameRange = INVALID_HANDLE;
new Handle:g_Cvar_Admins = INVALID_HANDLE;
new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_Cvar_Delay  = INVALID_HANDLE;
new Handle:g_Cvar_SpawnDelay = INVALID_HANDLE;
new Handle:g_Cvar_FlameSound = INVALID_HANDLE;

new Handle:fwdOnPlayerFlamed = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Flamethrower",
	author = "<eVa>Dog",
	description = "Flamethrower plugin",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
};

/**
 * Description: Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included
    #define TF2_IsPlayerDisguised(%1)    TF2_IsPlayerInCondition(%1,TFCond_Disguised)
    #define TF2_IsPlayerCloaked(%1)      TF2_IsPlayerInCondition(%1,TFCond_Cloaked)
    #define TF2_IsPlayerUbercharged(%1)  TF2_IsPlayerInCondition(%1,TFCond_Ubercharged)
    #define TF2_IsPlayerDeadRingered(%1) TF2_IsPlayerInCondition(%1,TFCond_DeadRingered)
    #define TF2_IsPlayerBonked(%1)       TF2_IsPlayerInCondition(%1,TFCond_Bonked)
#endif

/**
 * Description: Function to determine game/mod type
 */
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, csgo, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
    {
        if (GameType == undetected)
        {
            new String:modname[30];
            GetGameFolderName(modname, sizeof(modname));
            if (StrEqual(modname,"tf",false))
                GameType=tf2;
            else if (StrEqual(modname,"cstrike",false))
                GameType=cstrike;
            else if (StrEqual(modname,"csgo",false))
                GameType=csgo;
            else if (StrEqual(modname,"dod",false))
                GameType=dod;
            else if (StrEqual(modname,"hl2mp",false))
                GameType=hl2mp;
            else if (StrEqual(modname,"Insurgency",false))
                GameType=insurgency;
            else if (StrEqual(modname,"left4dead", false))
                GameType=l4d;
            else if (StrEqual(modname,"left4dead2", false))
                GameType=l4d2;
            else if (StrEqual(modname,"zps",false))
                GameType=zps;
            else
                GameType=other_game;
        }
        return GameType;
    }
#endif

/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 */
#tryinclude <entlimit>
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
        new max = GetMaxEntities();
        new count = GetEntityCount();
        new remaining = max - count;
        if (remaining <= warn)
        {
            if (count <= critical)
            {
                PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
                LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            else
            {
                PrintToServer("Caution: Entity count is getting high!");
                LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            return count;
        }
        else
            return 0;
    }
#endif

/**
 * Description: Manage precaching resources.
 */
#tryinclude <lib/ResourceManager>
#if !defined _ResourceManager_included
    #tryinclude <ResourceManager>
#endif
#if !defined _ResourceManager_included
    #define AUTO_DOWNLOAD   -1
	#define DONT_DOWNLOAD    0
	#define DOWNLOAD         1
	#define ALWAYS_DOWNLOAD  2

	enum State { Unknown=0, Defined, Download, Force, Precached };

	// Trie to hold precache status of sounds
	new Handle:g_soundTrie = INVALID_HANDLE;

	stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=false)
	{
        #pragma unused force
        new State:value = Unknown;
        if (!GetTrieValue(g_soundTrie, sound, value) || value < Precached)
        {
            PrecacheSound(sound, preload);
            SetTrieValue(g_soundTrie, sound, Precached);
        }
        return true;
    }

	stock SetupSound(const String:sound[], bool:force=false, download=AUTO_DOWNLOAD,
	                 bool:precache=false, bool:preload=false)
	{
        new State:value = Unknown;
        new bool:update = !GetTrieValue(g_soundTrie, sound, value);
        if (update || value < Defined)
        {
            value  = Defined;
            update = true;
        }

        if (download && value < Download)
        {
            decl String:file[PLATFORM_MAX_PATH+1];
            Format(file, sizeof(file), "sound/%s", sound);

            if (FileExists(file))
            {
                if (download < 0)
                {
                    if (!strncmp(file, "ambient", 7) ||
                        !strncmp(file, "beams", 5) ||
                        !strncmp(file, "buttons", 7) ||
                        !strncmp(file, "coach", 5) ||
                        !strncmp(file, "combined", 8) ||
                        !strncmp(file, "commentary", 10) ||
                        !strncmp(file, "common", 6) ||
                        !strncmp(file, "doors", 5) ||
                        !strncmp(file, "friends", 7) ||
                        !strncmp(file, "hl1", 3) ||
                        !strncmp(file, "items", 5) ||
                        !strncmp(file, "midi", 4) ||
                        !strncmp(file, "misc", 4) ||
                        !strncmp(file, "music", 5) ||
                        !strncmp(file, "npc", 3) ||
                        !strncmp(file, "physics", 7) ||
                        !strncmp(file, "pl_hoodoo", 9) ||
                        !strncmp(file, "plats", 5) ||
                        !strncmp(file, "player", 6) ||
                        !strncmp(file, "resource", 8) ||
                        !strncmp(file, "replay", 6) ||
                        !strncmp(file, "test", 4) ||
                        !strncmp(file, "ui", 2) ||
                        !strncmp(file, "vehicles", 8) ||
                        !strncmp(file, "vo", 2) ||
                        !strncmp(file, "weapons", 7))
                    {
                        // If the sound starts with one of those directories
                        // assume it came with the game and doesn't need to
                        // be downloaded.
                        download = 0;
                    }
                    else
                        download = 1;
                }

                if (download > 0)
                {
                    AddFileToDownloadsTable(file);

                    update = true;
                    value  = Download;
                }
            }
        }

        if (precache && value < Precached)
        {
            PrecacheSound(sound, preload);
            value  = Precached;
            update = true;
        }
        else if (force && value < Force)
        {
            value  = Force;
            update = true;
        }

        if (update)
            SetTrieValue(g_soundTrie, sound, value);
    }

	stock PrepareAndEmitAmbientSound(const String:name[],
							const Float:pos[3],
							entity = SOUND_FROM_WORLD,
							level = SNDLEVEL_NORMAL,
							flags = SND_NOFLAGS,
							Float:vol = SNDVOL_NORMAL,
							pitch = SNDPITCH_NORMAL,
							Float:delay = 0.0)
	{
		if (PrepareSound(name))
		{
			EmitAmbientSound(name, pos, entity, level,
							 flags, vol, pitch, delay);
		}
	}

	stock PrepareAndEmitSoundToClient(client,
					 const String:sample[],
					 entity = SOUND_FROM_PLAYER,
					 channel = SNDCHAN_AUTO,
					 level = SNDLEVEL_NORMAL,
					 flags = SND_NOFLAGS,
					 Float:volume = SNDVOL_NORMAL,
					 pitch = SNDPITCH_NORMAL,
					 speakerentity = -1,
					 const Float:origin[3] = NULL_VECTOR,
					 const Float:dir[3] = NULL_VECTOR,
					 bool:updatePos = true,
					 Float:soundtime = 0.0)
	{
	    if (PrepareSound(sample))
	    {
		    EmitSoundToClient(client, sample, entity, channel,
				              level, flags, volume, pitch, speakerentity,
				              origin, dir, updatePos, soundtime);
	    }
	}

    stock PrepareAndEmitSoundToAll(const String:sample[],
                     entity = SOUND_FROM_PLAYER,
                     channel = SNDCHAN_AUTO,
                     level = SNDLEVEL_NORMAL,
                     flags = SND_NOFLAGS,
                     Float:volume = SNDVOL_NORMAL,
                     pitch = SNDPITCH_NORMAL,
                     speakerentity = -1,
                     const Float:origin[3] = NULL_VECTOR,
                     const Float:dir[3] = NULL_VECTOR,
                     bool:updatePos = true,
                     Float:soundtime = 0.0)
    {
        if (PrepareSound(sample))
        {
            EmitSoundToAll(sample, entity, channel,
                           level, flags, volume, pitch, speakerentity,
                           origin, dir, updatePos, soundtime);
        }
    }
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("ControlFlamethrower", Native_ControlFlamethrower);
    CreateNative("GiveFlamethrower", Native_GiveFlamethrower);
    CreateNative("TakeFlamethrower", Native_TakeFlamethrower);
    CreateNative("RefuelFlamethrower", Native_RefuelFlamethrower);
    CreateNative("GetFlamethrowerFuel", Native_GetFlamethrowerFuel);
    CreateNative("SetFlamethrowerSound", Native_SetFlamethrowerSound);
    CreateNative("UseFlamethrower", Native_UseFlamethrower);

    fwdOnPlayerFlamed=CreateGlobalForward("OnPlayerFlamed",ET_Hook,Param_Cell,Param_Cell);

    RegPluginLibrary("sm_flame");
    return APLRes_Success;
}

public OnPluginStart()
{
    RegConsoleCmd("sm_flame", Flame, " -  Use the flamethrower");

    CreateConVar("sm_flame_version", PLUGIN_VERSION, "Version of Flamethrower on this server", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_Cvar_FlameAmount = CreateConVar("sm_flame_amount", "5", " Number of flamethrower cells per player at spawn", FCVAR_NONE);
    g_Cvar_FlameRange  = CreateConVar("sm_flame_range", "600.0", " Range of the flamethrower", FCVAR_NONE);
    g_Cvar_Admins      = CreateConVar("sm_flame_admins", "0", " Allow Admins only to use the Flamethrower", FCVAR_NONE);
    g_Cvar_Enable      = CreateConVar("sm_flame_enabled", "1", " Enable/Disable the Flamethrower plugin", FCVAR_NONE);
    g_Cvar_Delay       = CreateConVar("sm_flame_delay", "3.0", " Delay between flamethrower blasts", FCVAR_NONE);
    g_Cvar_SpawnDelay  = CreateConVar("sm_flame_spawndelay", "5.0", " Delay before flamethrower is available (0.0 disables)", FCVAR_NONE);
    g_Cvar_FlameSound  = CreateConVar("sm_flame_sound", "weapons/rpg/rocketfire1.wav", " Flamethrower sound", FCVAR_NONE);

    GetGameType();
}

public OnMapStart()
{
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("player_death", PlayerDeathEvent);

	SetupSound(EMPTY_SOUND, true, DONT_DOWNLOAD);
}

public OnConfigsExecuted()
{
    GetConVarString(g_Cvar_FlameSound, g_flameSound, sizeof(g_flameSound));
    SetupSound(g_flameSound, true);
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_NativeControl)
    {
        new amount = flameGiven[client];
        flameAmount[client] = (amount >= 0) ? amount : GetConVarInt(g_Cvar_FlameAmount);

        new Float:range = flameRange[client];
        flameRange[client] = (range >= 0.0) ? range : GetConVarFloat(g_Cvar_FlameRange);
    }
    else if (GetConVarBool(g_Cvar_Enable))
    {
        if (GetConVarBool(g_Cvar_Admins))
        {
            if (GetUserFlagBits(client) & ADMIN_LEVEL)
            {
                flameAmount[client] = GetConVarInt(g_Cvar_FlameAmount);
                flameRange[client] = GetConVarFloat(g_Cvar_FlameRange);
            }
            else
            {
                flameAmount[client] = 0;
                flameRange[client] = 0.0;
            }
        }
        else
        {
            flameAmount[client] = GetConVarInt(g_Cvar_FlameAmount);
            flameRange[client] = GetConVarFloat(g_Cvar_FlameRange);
        }
    }
    else
    {
        flameAmount[client] = 0;
        flameRange[client] = 0.0;
    }

    if (flameAmount[client] > 0)
    {
        if (GetConVarFloat(g_Cvar_SpawnDelay) > 0.0)
        {
            CreateTimer(GetConVarFloat(g_Cvar_SpawnDelay), SetFlame, client);
        }
        else
        {
            flameEnabled[client] = true;
        }
    }
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_NativeControl || GetConVarBool(g_Cvar_Enable))
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (client > 0 && IsClientInGame(client))
        {
            flameRange[client] = 0.0;
            flameAmount[client] = 0;
            flameEnabled[client] = false;
            ExtinguishEntity(client);
        }
    }
}

public Action:SetFlame(Handle:timer, any:client)
{
	flameEnabled[client] = true;
}

public Action:Flame(client, args)
{
    if (g_NativeControl || GetConVarBool(g_Cvar_Enable))
    {
        if (client)
        { 
            if (IsPlayerAlive(client))
            {
                if (GameType == tf2)
                {
                    switch (TF2_GetPlayerClass(client))
                    {
                        case TFClass_Spy:
                        {
                            if (TF2_IsPlayerCloaked(client) || TF2_IsPlayerDeadRingered(client))
                                return Plugin_Handled;
                            else if (TF2_IsPlayerDisguised(client))
                                TF2_RemovePlayerDisguise(client);
                        }
                        case TFClass_Scout:
                        {
                            if (TF2_IsPlayerBonked(client))
                                return Plugin_Handled;
                        }
                    }
                }

                if (flameAmount[client] > 0)
                {
                    if (flameEnabled[client])
                    {
                        new Float:vAngles[3];
                        new Float:vOrigin[3];
                        new Float:aOrigin[3];
                        new Float:EndPoint[3];
                        new Float:AnglesVec[3];
                        new Float:targetOrigin[3];

                        if (IsEntLimitReached(.client=client,.message="unable to spawn flames"))
                            return Plugin_Handled;

                        flameAmount[client]--;
                        PrintToChat(client, "[SM] Number of cells left: %i", flameAmount[client]);

                        new String:tName[128];

                        new Float:distance = flameRange[client];

                        GetClientEyePosition(client, vOrigin);
                        GetClientAbsOrigin(client, aOrigin);
                        GetClientEyeAngles(client, vAngles);

                        // A little routine developed by Sollie and Crimson to find the endpoint of a traceray
                        // Very useful!
                        GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

                        EndPoint[0] = vOrigin[0] + (AnglesVec[0]*distance);
                        EndPoint[1] = vOrigin[1] + (AnglesVec[1]*distance);
                        EndPoint[2] = vOrigin[2] + (AnglesVec[2]*distance);

                        new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, client);
                        if(TR_DidHit(trace))
                        {
                            TR_GetEndPosition(EndPoint, trace);
                        }
                        CloseHandle(trace);

                        PrepareAndEmitAmbientSound(g_flameSound, vOrigin, client, SNDLEVEL_NORMAL);
                        //PrepareAndEmitSoundToAll(g_flameSound, client, _, _, _, _, 0.7);

                        // Ident the player
                        Format(tName, sizeof(tName), "target%i", client);
                        DispatchKeyValue(client, "targetname", tName);

                        // Create the Flame
                        new String:flame_name[128];
                        Format(flame_name, sizeof(flame_name), "Flame%i", client);

                        new String:strFlameLength[64];
                        FloatToString(distance - 200.0, strFlameLength, sizeof(strFlameLength));

                        new flame = CreateEntityByName("env_steam");
                        if (flame > 0 && IsValidEdict(flame))
                        {
                            DispatchKeyValue(flame,"targetname", flame_name);
                            DispatchKeyValue(flame, "parentname", tName);
                            DispatchKeyValue(flame,"SpawnFlags", "1");
                            DispatchKeyValue(flame,"Type", "0");
                            DispatchKeyValue(flame,"InitialState", "1");
                            DispatchKeyValue(flame,"Spreadspeed", "10");
                            DispatchKeyValue(flame,"Speed", "800");
                            DispatchKeyValue(flame,"Startsize", "10");
                            DispatchKeyValue(flame,"EndSize", "250");
                            DispatchKeyValue(flame,"Rate", "15");
                            DispatchKeyValue(flame,"JetLength", strFlameLength);
                            DispatchKeyValue(flame,"RenderColor", "180 71 8");
                            DispatchKeyValue(flame,"RenderAmt", "180");
                            DispatchSpawn(flame);
                            TeleportEntity(flame, aOrigin, vAngles, NULL_VECTOR);
                            SetVariantString(tName);
                            AcceptEntityInput(flame, "SetParent", flame, flame, 0);

                            if (GameType == dod || GameType == insurgency)
                            {
                                SetVariantString("anim_attachment_RH");
                            }
                            else
                            {
                                SetVariantString("forward");
                            }

                            AcceptEntityInput(flame, "SetParentAttachment", flame, flame, 0);
                            AcceptEntityInput(flame, "TurnOn");

                            // Create the Heat Plasma
                            new String:flame_name2[128];
                            Format(flame_name2, sizeof(flame_name2), "Flame2%i", client);

                            new String:strPlasmaLength[64];
                            FloatToString(distance - 100.0, strPlasmaLength, sizeof(strPlasmaLength));

                            new flame2 = CreateEntityByName("env_steam");
                            if (flame2 > 0 && IsValidEdict(flame2))
                            {
                                DispatchKeyValue(flame2,"targetname", flame_name2);
                                DispatchKeyValue(flame2, "parentname", tName);
                                DispatchKeyValue(flame2,"SpawnFlags", "1");
                                DispatchKeyValue(flame2,"Type", "1");
                                DispatchKeyValue(flame2,"InitialState", "1");
                                DispatchKeyValue(flame2,"Spreadspeed", "10");
                                DispatchKeyValue(flame2,"Speed", "600");
                                DispatchKeyValue(flame2,"Startsize", "50");
                                DispatchKeyValue(flame2,"EndSize", "400");
                                DispatchKeyValue(flame2,"Rate", "10");
                                DispatchKeyValue(flame2,"JetLength", strPlasmaLength);
                                DispatchSpawn(flame2);
                                TeleportEntity(flame2, aOrigin, vAngles, NULL_VECTOR);
                                SetVariantString(tName);
                                AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);

                                if (GameType == dod || GameType == insurgency)
                                {
                                    SetVariantString("anim_attachment_RH");
                                }
                                else
                                {
                                    SetVariantString("forward");
                                }

                                AcceptEntityInput(flame2, "SetParentAttachment", flame2, flame2, 0);
                                AcceptEntityInput(flame2, "TurnOn");

                                new Handle:flamedata = CreateDataPack();
                                CreateTimer(1.0, KillFlame, flamedata);
                                WritePackCell(flamedata, EntIndexToEntRef(flame));
                                WritePackCell(flamedata, EntIndexToEntRef(flame2));

                                new dist = RoundToNearest(distance);
                                new bool:ff_on = GetConVarBool(FindConVar("mp_friendlyfire"));

                                for (new i = 1; i <= GetMaxClients(); i++)
                                {
                                    if (i == client)
                                        continue;

                                    if (IsClientInGame(i) && IsPlayerAlive(i))
                                    {
                                        if (ff_on || GetClientTeam(i) != GetClientTeam(client))
                                        {
                                            GetClientAbsOrigin(i, targetOrigin);

                                            if ((GetVectorDistance(targetOrigin, EndPoint) <= dist)  &&
                                                (GetVectorDistance(targetOrigin, vOrigin) <= dist) &&
                                                 TraceTargetIndex(client, i, vOrigin, targetOrigin))
                                            {
                                                if (GameType == tf2 && TF2_IsPlayerUbercharged(i))
                                                    continue;

                                                new Action:res = Plugin_Continue;
                                                Call_StartForward(fwdOnPlayerFlamed);
                                                Call_PushCell(client);
                                                Call_PushCell(i);
                                                Call_Finish(res);

                                                if (res == Plugin_Continue)
                                                {
                                                    if (GameType == tf2)
                                                        TF2_IgnitePlayer(i, client);
                                                    else
                                                        IgniteEntity(i, 5.0, false, 1.5, false);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            else
                                LogError("Unable to create flame2 entity!");
                        }
                        else
                            LogError("Unable to create flame entity!");
                    }
                    else
                    {
                        PrintToChat(client, "[SM] Flamethrower recharging.  Please wait....");
                    }
                }
                else
                {
                    PrintToChat(client, "[SM] Flamethrower out of fuel");
                    PrepareAndEmitSoundToClient(client, EMPTY_SOUND, _, _, _, _, 0.8);
                }
            }
        }
    }

    flameEnabled[client] = false;
    CreateTimer(GetConVarFloat(g_Cvar_Delay), SetFlame, client);
    return Plugin_Handled;
}

stock bool:TraceTargetIndex(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
    targetLoc[2] += 50.0; // Adjust trace position of target
    TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID, RayType_EndPoint,
                      TraceEntityFilterPlayer, client);
    return (TR_GetEntityIndex() == target);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)
{
	return data != entity;
} 

public Action:KillFlame(Handle:timer, Handle:flamedata)
{
    ResetPack(flamedata);
    new ent1 = EntRefToEntIndex(ReadPackCell(flamedata));
    new ent2 = EntRefToEntIndex(ReadPackCell(flamedata));
    CloseHandle(flamedata);

    new String:classname[256];

    if (ent1 > 0 && IsValidEntity(ent1))
    {
        AcceptEntityInput(ent1, "TurnOff");
        GetEdictClassname(ent1, classname, sizeof(classname));
        if (StrEqual(classname, "env_steam", false))
        {
			AcceptEntityInput(ent1, "kill");
        }
    }

    if (ent2 > 0 && IsValidEntity(ent2))
    {
        AcceptEntityInput(ent2, "TurnOff");
        GetEdictClassname(ent2, classname, sizeof(classname));
        if (StrEqual(classname, "env_steam", false))
        {
			AcceptEntityInput(ent2, "kill");
        }
    }
}

public Native_ControlFlamethrower(Handle:plugin, numParams)
{
    g_NativeControl = GetNativeCell(1);
}

public Native_GiveFlamethrower(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    flameAmount[client] = flameGiven[client] = GetNativeCell(2);
    flameRange[client] = Float:GetNativeCell(3);
    flameEnabled[client] = true;
}

public Native_TakeFlamethrower(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    flameEnabled[client] = false;
    flameAmount[client] = 0;
    flameRange[client] = 0.0;
    flameGiven[client] = 0;
}

public Native_RefuelFlamethrower(Handle:plugin, numParams)
{
    flameAmount[GetNativeCell(1)] += GetNativeCell(2);
}

public Native_GetFlamethrowerFuel(Handle:plugin, numParams)
{
    return flameAmount[GetNativeCell(1)];
}

public Native_UseFlamethrower(Handle:plugin, numParams)
{
    Flame(GetNativeCell(1), 0);
}


public Native_SetFlamethrowerSound(Handle:plugin,numParams)
{
    GetNativeString(1, g_flameSound, sizeof(g_flameSound));
}
