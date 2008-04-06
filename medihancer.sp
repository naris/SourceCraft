/**
 * vim: set ai et ts=4 sw=4 :
 * File: medihancer.sp
 * Description: Medic Enhancer for TF2
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#include <sourcemod>
#include <sdktools>

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
new String:Charged[3][] = { "vo/medic_autochargeready01",
                            "vo/medic_autochargeready02",
                            "vo/medic_autochargeready03"};

// Basic color arrays for temp entities
new redColor[4] = {255, 75, 75, 255};
new greenColor[4] = {75, 255, 75, 255};
new blueColor[4] = {75, 75, 255, 255};
new greyColor[4] = {128, 128, 128, 255};

// Following are model indexes for temp entities
new g_BeamSprite;
new g_HaloSprite;

new g_BeaconCount[MAXPLAYERS+1];

new Handle:g_IsMedihancerOn = INVALID_HANDLE;
new Handle:g_EnableBeacon = INVALID_HANDLE;
new Handle:g_BeaconRadius = INVALID_HANDLE;
new Handle:g_PingCount = INVALID_HANDLE;
new g_TF_ClassOffsets, g_TF_ChargeLevelOffset, g_TF_ChargeReleaseOffset,
    g_TF_CurrentOffset, g_TF_TeamNumOffset, g_ResourceEnt;

public OnPluginStart()
{
    CreateConVar("sm_tf_medihancer", PL_VERSION, "Medihancer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_IsMedihancerOn = CreateConVar("sm_medihancer","3","Enable/Disable medihancer");
    g_EnableBeacon = CreateConVar("sm_medihancer_beacon","3","Enable/Disable medihancer beacon");
    g_BeaconRadius = CreateConVar("sm_medihancer_beacon_radius", "375", "Sets the radius for medic enhancer beacon's light rings.", 0, true, 50.0, true, 1500.0);
    g_PingCount = CreateConVar("sm_medihancer_ping_count", "4", "Sets the number of beacon pulses inbetween pings for medihancer.");

    g_TF_ClassOffsets = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass");
    g_TF_ChargeLevelOffset = FindSendPropOffs("CWeaponMedigun", "m_flChargeLevel");
    g_TF_ChargeReleaseOffset = FindSendPropOffs("CWeaponMedigun", "m_bChargeRelease");
    g_TF_CurrentOffset = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");
    g_TF_TeamNumOffset = FindSendPropOffs("CTFItem", "m_iTeamNum");

    if (g_TF_ClassOffsets == -1)
        SetFailState("Cannot find TF2 m_iPlayerClass offset!");
    if (g_TF_ChargeLevelOffset == -1)
        SetFailState("Cannot find TF2 m_flChargeLevel offset!");
    if (g_TF_ChargeReleaseOffset == -1)
        SetFailState("Cannot find TF2 m_bChargeRelease offset!");
    if (g_TF_CurrentOffset == -1)
        SetFailState("Cannot find TF2 m_hActiveWeapon offset!");
    if (g_TF_TeamNumOffset == -1)
        SetFailState("Cannot find TF2 m_iTeamNum offset!");

    HookConVarChange(g_IsMedihancerOn, ConVarChange_IsMedihancerOn);
    HookEvent("teamplay_round_active", Event_RoundStart);

    CreateTimer(3.0, Medic_Timer, _, TIMER_REPEAT);
}

public OnMapStart()
{
    g_ResourceEnt = FindResourceObject();

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
        PrintToChatAll("[SM] Medics will auto-charge uber (and will beacon while charging)");
        if (StringToInt(newValue) != StringToInt(oldValue))
            g_ResourceEnt = FindResourceObject();
    }
    else
    {
        PrintToChatAll("[SM] Medic Enhancer is disabled");
    }
}

public Action:Medic_Timer(Handle:timer)
{
    new maxclients = GetMaxClients();
    for (new client = 1; client <= maxclients; client++)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            new team = GetClientTeam(client);
            if (team >= 2 && team <= 3)
            {
                new class = TF_GetClass(client);
                if (class == TF_MEDIC)
                {
                    new String:classname[64];
                    TF_GetCurrentWeaponClass(client, classname, sizeof(classname));
                    if(StrEqual(classname, "CWeaponMedigun"))
                    {
                        new UberCharge = TF_GetUberLevel(client);
                        if (UberCharge < 100)
                        {
                            if (UberCharge >= 100)
                            {
                                UberCharge = 100;
                                EmitSoundToAll(Charged[GetRandomInt(0,2)],client);
                            }
                            TF_SetUberLevel(client, UberCharge+3);
                            if (GetConVarInt(g_EnableBeacon))
                            {
                                new count = GetConVarInt(g_PingCount);
                                if (count > 0)
                                {
                                    new bool:ping = (++g_BeaconCount[client] >= count);
                                    BeaconPing(client, ping);
                                    if (ping)
                                        g_BeaconCount[client] = 0;
                                }
                            }
                            else
                            {
                                new count = GetConVarInt(g_PingCount);
                                if (count > 0)
                                {
                                    if (++g_BeaconCount[client] >= count)
                                    {
                                        new Float:vec[3];
                                        GetClientEyePosition(client, vec);
                                        EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
                                        g_BeaconCount[client] = 0;
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
    if (MedihancerOn)
        PrintToChatAll("[SM] Medic Enhancer is enabled");
}

stock FindResourceObject()
{
    new maxclients = GetMaxClients();
    new maxents = GetMaxEntities();
    new i, String:classname[64];
    for(i = maxclients; i <= maxents; i++)
    {
        if(IsValidEntity(i))
        {
            GetEntityNetClass(i, classname, 64);
            if(StrEqual(classname, "CTFPlayerResource"))
            {
                return i;
            }
        }
    }
    SetFailState("Cannot find TF2 player ressource prop!");
    return -1;
}

stock TF_GetClass(client)
{
    return GetEntData(g_ResourceEnt, g_TF_ClassOffsets + (client*4), 4);
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
