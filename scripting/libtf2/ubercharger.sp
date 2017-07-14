/**
 * vim: set ai et ts=4 sw=4 :
 * File: ubercharger.sp
 * Description: Medic Uber Charger for TF2
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PL_VERSION      "1.0.4"

#define MODEL_LASER     "materials/sprites/laser.vmt"
#define MODEL_HALO      "materials/sprites/halo01.vmt"

#define SOUND_BLIP		"buttons/blip1.wav"

public Plugin:myinfo = 
{
    name = "TF2 Uber Charger",
    author = "-=|JFH|=-Naris",
    description = "Continously recharges Medic's Uber",
    version = PL_VERSION,
    url = "http://www.jigglysfunhouse.net/"
}

// Charged sounds
new const String:Charged[][] = { "vo/medic_autochargeready01.wav",
                                 "vo/medic_autochargeready02.wav",
                                 "vo/medic_autochargeready03.wav"};

// Basic color arrays for temp entities
new const redColor[4] = {255, 75, 75, 255};
new const greenColor[4] = {75, 255, 75, 255};
new const blueColor[4] = {75, 75, 255, 255};
new const greyColor[4] = {128, 128, 128, 255};

// Following are model indexes for temp entities
new g_BeamSprite;
new g_HaloSprite;

new Float:g_ChargeDelay = 5.0;
new Float:g_BeaconDelay = 3.0;
new Float:g_PingDelay = 12.0;

new Float:g_lastChargeTime = 0.0;
new Float:g_lastBeaconTime = 0.0;
new Float:g_lastPingTime = 0.0;

new Handle:g_IsUberchargerOn = INVALID_HANDLE;
new Handle:g_EnableBeacon = INVALID_HANDLE;
new Handle:g_BeaconRadius = INVALID_HANDLE;
new Handle:g_BeaconTimer = INVALID_HANDLE;
new Handle:g_ChargeAmount = INVALID_HANDLE;
new Handle:g_ChargeTimer = INVALID_HANDLE;
new Handle:g_EnablePing = INVALID_HANDLE;
new Handle:g_PingTimer = INVALID_HANDLE;
new Handle:g_TimerHandle = INVALID_HANDLE;
new bool:ConfigsExecuted = false;
new bool:NativeControl = false;
new bool:NativeMedicEnabled[MAXPLAYERS + 1] = { false, ...};
new Float:NativeAmount[MAXPLAYERS + 1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlUberCharger",Native_ControlUberCharger);
    CreateNative("SetUberCharger",Native_SetUberCharger);
    RegPluginLibrary("ubercharger");
    return APLRes_Success;
}

/**
 * Description: Stocks to return information about TF2 UberCharge.
 */
#tryinclude <tf2_uber>
#if !defined _tf2_uber_included
    stock Float:TF2_GetUberLevel(client)
    {
        new index = GetPlayerWeaponSlot(client, 1);
        if (index > 0)
            return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel");
        else
            return 0.0;
    }

    stock TF2_SetUberLevel(client, Float:uberlevel)
    {
        new index = GetPlayerWeaponSlot(client, 1);
        if (index > 0)
            SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
    }
#endif

/**
 * Description: Functions to return information about weapons.
 */
#tryinclude <weapons>
#if !defined _weapons_included
    stock GetCurrentWeaponClass(client, String:name[], maxlength)
    {
        new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (index > 0)
            GetEntityNetClass(index, name, maxlength);
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

    stock SetupModel(const String:model[], &index, bool:download=false,
                     bool:precache=false, bool:preload=false)
    {
        if (download && FileExists(model))
            AddFileToDownloadsTable(model);

        if (precache)
            index = PrecacheModel(model,preload);
        else
            index = 0;
    }

    stock PrepareModel(const String:model[], &index, bool:preload=true)
    {
        if (index <= 0)
            index = PrecacheModel(model,preload);

        return index;
    }
#endif

public OnPluginStart()
{
    g_IsUberchargerOn = CreateConVar("sm_ubercharger","1","Enable/Disable ubercharger",FCVAR_NONE);
    g_ChargeAmount = CreateConVar("sm_ubercharger_charge_amount", "0.03", "Sets the amount of uber charge to add time for ubercharger.",
                                  FCVAR_NONE, true, 0.0, true, 1.0);

    g_ChargeTimer = CreateConVar("sm_ubercharger_charge_timer", "3.0", "Sets the time interval for ubercharger.",FCVAR_NONE);

    g_EnableBeacon = CreateConVar("sm_ubercharger_beacon","1","Enable/Disable ubercharger beacon",FCVAR_NONE);
    g_BeaconTimer = CreateConVar("sm_ubercharger_beacon_timer","3.0","Sets the time interval of beacons for ubercharger",FCVAR_NONE);
    g_BeaconRadius = CreateConVar("sm_ubercharger_beacon_radius", "375", "Sets the radius for medic enhancer beacon's light rings.",
                                  FCVAR_NONE, true, 50.0, true, 1500.0);

    g_EnablePing = CreateConVar("sm_ubercharger_ping","1","Enable/Disable ubercharger ping",FCVAR_NONE);
    g_PingTimer = CreateConVar("sm_ubercharger_ping_timer", "12.0", "Sets the time interval of pings for ubercharger.",FCVAR_NONE);

    // Execute the config file
    AutoExecConfig(true, "sm_ubercharger");

    CreateConVar("sm_tf_ubercharger", PL_VERSION, "TF2 Medic Uber Charger Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnConfigsExecuted()
{
    if (NativeControl || GetConVarBool(g_IsUberchargerOn))
    {
        if (g_TimerHandle == INVALID_HANDLE)
            g_TimerHandle = CreateTimer(CalcDelay(), Medic_Timer, _, TIMER_REPEAT);
    }

    ConfigsExecuted = true;
}

public OnMapStart()
{
    SetupModel(MODEL_LASER, g_BeamSprite);
    SetupModel(MODEL_HALO, g_HaloSprite);	

    SetupSound(SOUND_BLIP, true, DONT_DOWNLOAD);
    for (new i = 0; i < sizeof(Charged); i++)
        SetupSound(Charged[i], true, DONT_DOWNLOAD);

    g_lastChargeTime = 0.0;
    g_lastBeaconTime = 0.0;
    g_lastPingTime = 0.0;
}

public OnMapEnd()
{
    if (g_TimerHandle != INVALID_HANDLE)
    {
        KillTimer(g_TimerHandle);
        g_TimerHandle = INVALID_HANDLE;
    }
}

// When a new client connects we reset their flags
public OnClientPutInServer(client)
{
    if (client && !IsFakeClient(client))
        NativeMedicEnabled[client] = false;

    if (!NativeControl && GetConVarBool(g_IsUberchargerOn))
        CreateTimer(45.0, Timer_Advert, client);
}

public Action:Timer_Advert(Handle:timer, any:client)
{
    if (!NativeControl &&
        GetConVarBool(g_IsUberchargerOn) &&
        IsClientInGame(client))
    {
        PrintToChat(client, "\x01\x04[SM]\x01 Medics will auto-charge uber (and will beacon while charging)");
    }
}

public Action:Medic_Timer(Handle:timer, any:value)
{
    if (!NativeControl && !GetConVarBool(g_IsUberchargerOn))
        return;

    new Float:gameTime = GetGameTime();
    new bool:charge    = (gameTime - g_lastChargeTime >= g_ChargeDelay);
    new bool:beacon    = (gameTime - g_lastBeaconTime >= g_BeaconDelay);
    new bool:ping      = (gameTime - g_lastPingTime >= g_PingDelay);

    if (charge)
        g_lastChargeTime = gameTime;

    if (beacon)
        g_lastBeaconTime = gameTime;

    if (ping)
        g_lastPingTime = gameTime;

    for (new client = 1; client <= MaxClients; client++)
    {
        if (!NativeControl || NativeMedicEnabled[client])
        {
            if (IsClientInGame(client) && IsPlayerAlive(client))
            {
                new team = GetClientTeam(client);
                if (team >= 2 && team <= 3)
                {
                    if (TF2_GetPlayerClass(client) == TFClass_Medic)
                    {
                        decl String:classname[64];
                        GetCurrentWeaponClass(client, classname, sizeof(classname));
                        if (StrEqual(classname, "CWeaponMedigun"))
                        {
                            new Float:UberCharge = TF2_GetUberLevel(client);
                            if (UberCharge < 1.0)
                            {
                                if (charge)
                                {
                                    new Float:amt = NativeAmount[client];
                                    UberCharge += (amt > 0.0) ? amt : GetConVarFloat(g_ChargeAmount);
                                    if (UberCharge >= 1.0)
                                    {
                                        UberCharge = 1.0;
                                        PrepareAndEmitSoundToAll(Charged[GetRandomInt(0,sizeof(Charged)-1)],client);
                                    }
                                    TF2_SetUberLevel(client, UberCharge);
                                }

                                if (beacon && GetConVarInt(g_EnableBeacon))
                                {
                                    BeaconPing(client, ping && GetConVarInt(g_EnablePing));
                                }
                                else if (ping && GetConVarInt(g_EnablePing))
                                {
                                    new Float:vec[3];
                                    GetClientEyePosition(client, vec);
                                    PrepareAndEmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

BeaconPing(client,bool:ping)
{
    new team = GetClientTeam(client);

    new Float:vec[3];
    GetClientAbsOrigin(client, vec);
    vec[2] += 10;

    PrepareModel(MODEL_LASER, g_BeamSprite, true);
    PrepareModel(MODEL_HALO, g_HaloSprite, true);

    TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
    TE_SendToAll();

    if (team == 2)
    {
        TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
    }
    else if (team == 3)
    {
        TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
    }
    else
    {
        TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
    }

    TE_SendToAll();

    if (ping)
    {
        GetClientEyePosition(client, vec);
        EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
    }
}

Float:CalcDelay()
{
    g_ChargeDelay = GetConVarFloat(g_ChargeTimer);
    g_BeaconDelay = GetConVarFloat(g_BeaconTimer);
    g_PingDelay = GetConVarFloat(g_PingTimer);

    new Float:delay = g_ChargeDelay;
    if (delay > g_BeaconDelay)
        delay = g_BeaconDelay;
    if (delay > g_PingDelay)
        delay = g_PingDelay;

    return delay;
}

public Native_ControlUberCharger(Handle:plugin,numParams)
{
    NativeControl = GetNativeCell(1);

    if (g_TimerHandle == INVALID_HANDLE && NativeControl && ConfigsExecuted)
        g_TimerHandle = CreateTimer(CalcDelay(), Medic_Timer, _, TIMER_REPEAT);
}

public Native_SetUberCharger(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    NativeMedicEnabled[client] = GetNativeCell(2);
    NativeAmount[client] = Float:GetNativeCell(3);
}

