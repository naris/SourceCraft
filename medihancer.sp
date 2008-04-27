/**
 * vim: set ai et ts=4 sw=4 :
 * File: medihancer.sp
 * Description: Medic Enhancer for TF2
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define TF_SCOUT 1
#define TF_SNIPER 2
#define TF_SOLDIER 3 
#define TF_DEMOMAN 4
#define TF_MEDIC 5
#define TF_HEAVY 6
#define TF_PYRO 7
#define TF_SPY 8
#define TF_ENG 9

#define PL_VERSION "1.0.0"

#define SOUND_BLIP		"buttons/blip1.wav"

public Plugin:myinfo = 
{
    name = "TF2 Medihancer",
    author = "-=|JFH|=-Naris",
    description = "Continously recharges all Medic's Uber.",
    version = PL_VERSION,
    url = "http://www.jigglysfunhouse.net/"
}

// Charged sounds
new String:Charged[3][] = { "vo/medic_autochargeready01.wav",
                            "vo/medic_autochargeready02.wav",
                            "vo/medic_autochargeready03.wav"};

// Basic color arrays for temp entities
new redColor[4] = {255, 75, 75, 255};
new greenColor[4] = {75, 255, 75, 255};
new blueColor[4] = {75, 75, 255, 255};
new greyColor[4] = {128, 128, 128, 255};

// Following are model indexes for temp entities
new g_BeamSprite;
new g_HaloSprite;

new Float:g_LastChargeTime[MAXPLAYERS+1];
new Float:g_LastBeaconTime[MAXPLAYERS+1];
new Float:g_LastPingTime[MAXPLAYERS+1];

new Float:g_ChargeDelay = 5.0;
new Float:g_BeaconDelay = 5.0;
new Float:g_PingDelay = 20.0;

new Handle:g_IsMedihancerOn = INVALID_HANDLE;
new Handle:g_EnableBeacon = INVALID_HANDLE;
new Handle:g_BeaconRadius = INVALID_HANDLE;
new Handle:g_BeaconTimer = INVALID_HANDLE;
new Handle:g_ChargeAmount = INVALID_HANDLE;
new Handle:g_ChargeTimer = INVALID_HANDLE;
new Handle:g_EnablePing = INVALID_HANDLE;
new Handle:g_PingTimer = INVALID_HANDLE;
new Handle:g_TimerHandle = INVALID_HANDLE;
new g_TF_ChargeLevelOffset, g_TF_ChargeReleaseOffset,
    g_TF_CurrentOffset, g_TF_TeamNumOffset;

new bool:ConfigsExecuted = false;
new bool:NativeControl = false;
new bool:NativeMedicEnabled[MAXPLAYERS + 1] = { false, ...};
new NativeAmount[MAXPLAYERS + 1];

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlMedicEnhancer",Native_ControlMedicEnhancer);
    CreateNative("SetMedicEnhancement",Native_SetMedicEnhancement);
    RegPluginLibrary("medihancer");
    return true;
}

public OnPluginStart()
{
    g_IsMedihancerOn = CreateConVar("sm_medihancer","1","Enable/Disable medihancer");
    g_ChargeAmount = CreateConVar("sm_medihancer_charge_amount", "3", "Sets the amount of uber charge to add time for medihancer.");
    g_ChargeTimer = CreateConVar("sm_medihancer_charge_timer", "5.0", "Sets the time interval for medihancer.");

    g_EnableBeacon = CreateConVar("sm_medihancer_beacon","1","Enable/Disable medihancer beacon");
    g_BeaconTimer = CreateConVar("sm_medihancer_beacon_timer","5.0","Sets the time interval of beacons for medihancer");
    g_BeaconRadius = CreateConVar("sm_medihancer_beacon_radius", "375", "Sets the radius for medic enhancer beacon's light rings.", 0, true, 50.0, true, 1500.0);

    g_EnablePing = CreateConVar("sm_medihancer_ping","1","Enable/Disable medihancer ping");
    g_PingTimer = CreateConVar("sm_medihancer_ping_timer", "20.0", "Sets the time interval of pings for medihancer.");

    // Execute the config file
    AutoExecConfig(true, "sm_medihancer");

    CreateConVar("sm_tf_medihancer", PL_VERSION, "Medihancer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_TF_ChargeLevelOffset = FindSendPropOffs("CWeaponMedigun", "m_flChargeLevel");
    if (g_TF_ChargeLevelOffset == -1)
        SetFailState("Cannot find TF2 m_flChargeLevel offset!");

    g_TF_ChargeReleaseOffset = FindSendPropOffs("CWeaponMedigun", "m_bChargeRelease");
    if (g_TF_ChargeReleaseOffset == -1)
        SetFailState("Cannot find TF2 m_bChargeRelease offset!");

    g_TF_CurrentOffset = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");
    if (g_TF_CurrentOffset == -1)
        SetFailState("Cannot find TF2 m_hActiveWeapon offset!");

    g_TF_TeamNumOffset = FindSendPropOffs("CTFItem", "m_iTeamNum");
    if (g_TF_TeamNumOffset == -1)
        SetFailState("Cannot find TF2 m_iTeamNum offset!");

    HookEvent("teamplay_round_active", Event_RoundStart);
}

public OnConfigsExecuted()
{
    if (GetConVarInt(g_IsMedihancerOn))
    {
        if (g_TimerHandle == INVALID_HANDLE)
        {
            new Float:delay = CalcDelay();
            LogMessage("[OnConfigExecuted]Created Medic_Timer with delay=%f", delay);
            g_TimerHandle = CreateTimer(delay, Medic_Timer, _, TIMER_REPEAT);
        }
    }

    HookConVarChange(g_PingTimer, ConVarChange_IsMedihancerOn);
    HookConVarChange(g_ChargeTimer, ConVarChange_IsMedihancerOn);
    HookConVarChange(g_BeaconTimer, ConVarChange_IsMedihancerOn);
    HookConVarChange(g_IsMedihancerOn, ConVarChange_IsMedihancerOn);
    ConfigsExecuted = true;
}

public OnMapStart()
{
    PrecacheSound(SOUND_BLIP, true);
    PrecacheSound(Charged[0], true);
    PrecacheSound(Charged[1], true);
    PrecacheSound(Charged[2], true);

    g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
    g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
}


public ConVarChange_IsMedihancerOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
    {
        if (g_TimerHandle != INVALID_HANDLE && (convar == g_ChargeTimer ||
                                                convar == g_BeaconTimer ||
                                                convar == g_PingTimer))
        {
            KillTimer(g_TimerHandle);
            g_TimerHandle = INVALID_HANDLE;
        }

        if (g_TimerHandle == INVALID_HANDLE && ConfigsExecuted)
        {
            new Float:delay = CalcDelay();
            LogMessage("OnConvarChange]Created Medic_Timer with delay=%f", delay);
            g_TimerHandle = CreateTimer(delay, Medic_Timer, _, TIMER_REPEAT);
        }

        if (!NativeControl)
            PrintToChatAll("[SM] Medics will auto-charge uber (and will beacon while charging)");
    }
    else
    {
        if (g_TimerHandle != INVALID_HANDLE)
        {
            KillTimer(g_TimerHandle);
            g_TimerHandle = INVALID_HANDLE;
        }
        PrintToChatAll("[SM] Medic Enhancer is disabled");
    }
}

new Float:lastGameTime = 0.0;
new Float:lastEngineTime = 0.0;
new lastTime = 0;
public Action:Medic_Timer(Handle:timer)
{
    decl String:buffer[64];
    new Float:gameTime = GetGameTime();
    new Float:engineTime = GetEngineTime();
    new time = GetTime();
    FormatTime(buffer, sizeof(buffer),"%D %T", time);
    LogMessage("Medic_Timer, gameTime=%f(%f), engineTime=%f(%f), time=%d(%d) - %s",
               gameTime,gameTime-lastGameTime,engineTime,engineTime-lastEngineTime,time,time-lastTime,buffer);
    lastGameTime=gameTime;
    lastEngineTime=engineTime;
    lastTime=time;

    new maxclients = GetMaxClients();
    for (new client = 1; client <= maxclients; client++)
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
                        new String:classname[64];
                        TF_GetCurrentWeaponClass(client, classname, sizeof(classname));
                        if(StrEqual(classname, "CWeaponMedigun"))
                        {
                            new UberCharge = TF_GetUberLevel(client);
                            if (UberCharge < 100)
                            {
                                if (gameTime - g_LastChargeTime[client] >= g_ChargeDelay)
                                {
                                    new amt = NativeAmount[client];
                                    LogMessage("Add %d Uber", amt);
                                    UberCharge += (amt > 0) ? amt : GetConVarInt(g_ChargeAmount);
                                    if (UberCharge >= 100)
                                    {
                                        UberCharge = 100;
                                        new num=GetRandomInt(0,2);
                                        EmitSoundToAll(Charged[num],client);
                                    }
                                    TF_SetUberLevel(client, UberCharge);
                                    g_LastChargeTime[client] = gameTime;
                                }
                                if (GetConVarInt(g_EnableBeacon))
                                {
                                    if (gameTime - g_LastBeaconTime[client] >= g_BeaconDelay)
                                    {
                                        new bool:ping = GetConVarInt(g_EnablePing) &&
                                                        (gameTime - g_LastPingTime[client] >= g_PingDelay);

                                        BeaconPing(client, ping);
                                        LogMessage("Beacon, ping=%d", ping);
                                        g_LastBeaconTime[client] = gameTime;
                                        if (ping)
                                            g_LastPingTime[client] = gameTime;
                                    }
                                }
                                else if (GetConVarInt(g_EnablePing))
                                {
                                    if (gameTime - g_LastPingTime[client] >= g_PingDelay)
                                    {
                                        LogMessage("Ping");
                                        new Float:vec[3];
                                        GetClientEyePosition(client, vec);
                                        EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
                                        g_LastPingTime[client] = gameTime;
                                    }
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

    GetClientEyePosition(client, vec);

    if (ping)
        EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new MedihancerOn = GetConVarInt(g_IsMedihancerOn);
    if (MedihancerOn && !NativeControl)
        PrintToChatAll("[SM] Medics will auto-charge uber (and will beacon while charging)");
}

stock TF_IsUberCharge(client)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
        return GetEntData(index, g_TF_ChargeReleaseOffset, 1);
    else
        return 0;
}

stock TF_GetUberLevel(client)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
        return RoundFloat(GetEntDataFloat(index, g_TF_ChargeLevelOffset)*100);
    else
        return 0;
}

stock TF_SetUberLevel(client, uberlevel)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
    {
        SetEntDataFloat(index, g_TF_ChargeLevelOffset, uberlevel*0.01, true);
    }
}

stock TF_GetCurrentWeaponClass(client, String:name[], maxlength)
{
    new index = GetEntDataEnt(client, g_TF_CurrentOffset);
    if (index != 0)
        GetEntityNetClass(index, name, maxlength);
}

Float:CalcDelay()
{
    new Float:chargeDelay = GetConVarFloat(g_ChargeTimer);
    new Float:beaconDelay = GetConVarFloat(g_BeaconTimer);
    new Float:pingDelay = GetConVarFloat(g_PingTimer);

    new Float:delay = chargeDelay;
    if (delay > beaconDelay)
        delay = beaconDelay;
    if (delay > pingDelay)
        delay = pingDelay;

    return delay;
}

public Native_ControlMedicEnhancer(Handle:plugin,numParams)
{
    if (numParams == 0)
        NativeControl = true;
    else if(numParams == 1)
        NativeControl = GetNativeCell(1);

    if (g_TimerHandle == INVALID_HANDLE && NativeControl && ConfigsExecuted)
    {
        new Float:delay = CalcDelay();
        LogMessage("[NativeControl]Created Medic_Timer with delay=%f", delay);
        g_TimerHandle = CreateTimer(delay, Medic_Timer, _, TIMER_REPEAT);
    }
}

public Native_SetMedicEnhancement(Handle:plugin,numParams)
{
    if(numParams >= 1 && numParams <= 3)
    {
        new client = GetNativeCell(1);
        NativeMedicEnabled[client] = (numParams >= 2) ? GetNativeCell(2) : true;
        NativeAmount[client] = (numParams >= 3) ? GetNativeCell(3) : 0;
    }
}

