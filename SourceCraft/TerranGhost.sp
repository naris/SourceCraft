/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranGhost.sp
 * Description: The Terran Ghost race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/freeze"
#include "sc/screen"

#include "sc/log" // for debugging

enum NuclearStatus { Quiescent, Ready, Tracking, LaunchInitiated, LockedOn, Exploding};

new raceID, cloakID, lockdownID, detectorID, nukeID;

new g_HaloSprite;
new g_fireSprite;
new g_fire2Sprite;
new g_whiteSprite;
new g_laserSprite;
new g_smokeSprite;
new g_lightningSprite;
new g_explosionModel;

new m_OffsetCloakMeter;

new Handle:cvarNuclearLaunchEnable = INVALID_HANDLE;
new Handle:cvarNuclearLaunchTime = INVALID_HANDLE;
new Handle:cvarNuclearLockTime = INVALID_HANDLE;
new Handle:cvarNuclearCooldown = INVALID_HANDLE;

new m_NuclearDuration[MAXPLAYERS+1];
new Handle:m_NuclearTimer[MAXPLAYERS+1];
new Float:m_NuclearAimPos[MAXPLAYERS+1][3];
new NuclearStatus:m_NuclearLaunchStatus[MAXPLAYERS+1];

new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

new Float:gLockdownTime[MAXPLAYERS+1];

new String:readyWav[] = "sourcecraft/tadupd07.wav";
new String:targetWav[] = "sourcecraft/tghlas00.wav";
new String:launchWav[] = "sourcecraft/tnsfir00.wav";
new String:detectedWav[] = "sourcecraft/tadupd04.wav";
new String:lockdownWav[] = "sourcecraft/tghlkd00.wav";
new String:airRaidWav[] = "sourcecraft/air_raid.wav";
new String:explode1Wav[] = "sourcecraft/tnshit00.wav";
new String:explode2Wav[] = "ambient/explosions/explode_8.wav";
new String:explode3Wav[] = "sourcecraft/boom2.wav";
new String:explode4Wav[] = "sourcecraft/war01.mp3";
new String:explode5Wav[] = "sourcecraft/inferno.wav";
new String:explode6Wav[] = "sourcecraft/explosions_sparks.wav";
new String:explode7Wav[] = "sourcecraft/usat_bomb.wav";


public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Ghost",
    author = "-=|JFH|=-Naris",
    description = "The Terran Ghost race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarNuclearLaunchEnable=CreateConVar("sc_nuclearlaunchenable","1");
    cvarNuclearLaunchTime=CreateConVar("sc_nuclearlaunchtime","20");
    cvarNuclearLockTime=CreateConVar("sc_nuclearlocktime","5");
    cvarNuclearCooldown=CreateConVar("sc_nuclearlaunchcooldown","300");

    HookEvent("player_spawn",PlayerSpawnEvent);

    CreateTimer(1.0,OcularImplants,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID      = CreateRace("Terran Ghost", "ghost",
                             "You are now a Terran Ghost.",
                             "You will be a Terran Ghost when you die or respawn.",
                             32);

    cloakID     = AddUpgrade(raceID,"Personal Cloaking Device", "cloak",
                             "Makes you partially invisible, \n62% visibility - 37% visibility.\nTotal Invisibility when standing still");

    lockdownID  = AddUpgrade(raceID,"Lockdown", "lockdown", 
                             "Have a 15-52\% chance to render an \nenemy immobile for 1 second.");

    detectorID  = AddUpgrade(raceID,"Ocular Implants", "implants", 
                             "Detect cloaked units around you.");

    nukeID      = AddUpgrade(raceID,"Nuclear Launch", "nuke", 
                             "Launches a Nuclear Device that does extreme damage to all players in the area.",
                             true); // Ultimate

    if (GameType == tf2)
    {
        m_OffsetCloakMeter=FindSendPropInfo("CTFPlayer","m_flCloakMeter");
        if (m_OffsetCloakMeter == -1)
            SetFailState("Couldn't find CloakMeter Offset");
    }
}

public OnMapStart()
{
    g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
    if (g_HaloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_fireSprite = PrecacheModel("sprites/sprite_fire01.vmt");
    if (g_fireSprite == -1)
        SetFailState("Couldn't find fire Model");

    g_fire2Sprite = PrecacheModel("materials/sprites/fire2.vmt");
    if (g_fire2Sprite == -1)
        SetFailState("Couldn't find fire2 Model");

    g_whiteSprite = PrecacheModel("materials/sprites/white.vmt");
    if (g_whiteSprite == -1)
        SetFailState("Couldn't find white Model");

    g_laserSprite = PrecacheModel("materials/sprites/laser.vmt");
    if (g_laserSprite == -1)
        SetFailState("Couldn't find laser Model");

    g_smokeSprite = PrecacheModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = PrecacheModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    if (GameType == tf2)
        g_explosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt");
    else
        g_explosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt");

    if (g_explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(readyWav, true, true);
    SetupSound(targetWav, true, true);
    SetupSound(launchWav, true, true);
    SetupSound(airRaidWav, true, true);
    SetupSound(explode1Wav, true, true);
    SetupSound(explode2Wav, true, true);
    SetupSound(explode3Wav, true, true);
    SetupSound(explode4Wav, true, true);
    SetupSound(explode5Wav, true, true);
    SetupSound(explode6Wav, true, true);
    SetupSound(explode7Wav, true, true);
    SetupSound(detectedWav, true, true);
    SetupSound(lockdownWav, true, true);
}

public OnPlayerAuthed(client,Handle:player)
{
    m_NuclearLaunchStatus[client] = Ready;
}

public OnClientDisconnect(client)
{
    ResetOcularImplants(client);
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            SetVisibility(player, -1);
            ResetOcularImplants(client);
        }
        else if (race == raceID)
            Cloak(client, player, GetUpgradeLevel(player,race,cloakID));
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && m_NuclearLaunchStatus[client] >= Ready
                     && m_NuclearLaunchStatus[client] <= Tracking
                     && IsPlayerAlive(client))
    {
        new ult_level=GetUpgradeLevel(player,race,nukeID);
        if (ult_level)
        {
            if (pressed)
                TargetNuclearDevice(client);
            else
                LaunchNuclearDevice(client,player);
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && GetRace(player) == raceID)
    {
        if (upgrade==0)
            Cloak(client, player, new_level);
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new cloak_level=GetUpgradeLevel(player,race,cloakID);
                if (cloak_level)
                    Cloak(client, player, cloak_level);
            }
        }
    }
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_player != INVALID_HANDLE && victim_race == raceID)
    {
        SetVisibility(victim_player, -1);
        SetOverrideSpeed(victim_player, -1.0);

        if (m_NuclearLaunchStatus[victim_index] == Tracking)
            m_NuclearLaunchStatus[victim_index] = Ready;
        else if (m_NuclearLaunchStatus[victim_index] >= LaunchInitiated)
            m_NuclearLaunchStatus[victim_index] = Quiescent;
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    if (attacker_index && attacker_index != victim_index)
    {
        if (victim_race == raceID)
            Lockdown(attacker_index, victim_player);

        if (attacker_race == raceID)
            Lockdown(victim_index, attacker_player);
    }

    if (assister_index && assister_index != victim_index)
    {
        if (assister_race == raceID)
            Lockdown(victim_index, assister_player);
    }
    return Plugin_Continue;
}

/*
enum RenderFx
{	
	RENDERFX_NONE = 0, 
	RENDERFX_PULSE_SLOW, 
	RENDERFX_PULSE_FAST, 
	RENDERFX_PULSE_SLOW_WIDE, 
	RENDERFX_PULSE_FAST_WIDE, 
	RENDERFX_FADE_SLOW, 
	RENDERFX_FADE_FAST, 
	RENDERFX_SOLID_SLOW, 
	RENDERFX_SOLID_FAST, 	   
	RENDERFX_STROBE_SLOW, 
	RENDERFX_STROBE_FAST, 
	RENDERFX_STROBE_FASTER, 
	RENDERFX_FLICKER_SLOW, 
	RENDERFX_FLICKER_FAST,
	RENDERFX_NO_DISSIPATION,
	RENDERFX_DISTORT,			**< Distort/scale/translate flicker *
	RENDERFX_HOLOGRAM,			**< kRenderFxDistort + distance fade *
	RENDERFX_EXPLODE,			**< Scale up really big! *
	RENDERFX_GLOWSHELL,			**< Glowing Shell *
	RENDERFX_CLAMP_MIN_SCALE,	**< Keep this sprite from getting very small (SPRITES only!) *
	RENDERFX_ENV_RAIN,			**< for environmental rendermode, make rain *
	RENDERFX_ENV_SNOW,			**<  "        "            "    , make snow *
	RENDERFX_SPOTLIGHT,			**< TEST CODE for experimental spotlight *
	RENDERFX_RAGDOLL,			**< HACKHACK: TEST CODE for signalling death of a ragdoll character *
	RENDERFX_PULSE_FAST_WIDER,
	RENDERFX_MAX
};
*/
Cloak(client, Handle:player, level)
{
    if (level > 0)
    {
        new alpha, Float:delay, Float:duration, RenderFx:fx;
        switch(level)
        {
            case 1:
            {
                alpha = 255;
                delay = 2.0;
                duration = 5.0;
                fx=RENDERFX_PULSE_SLOW;
            }
            case 2:
            {
                alpha = 235;
                delay = 1.5;
                duration = 10.0;
                fx=RENDERFX_PULSE_FAST;
            }
            case 3:
            {
                alpha = 215;
                delay = 1.0;
                duration = 15.0;
                fx=RENDERFX_FLICKER_SLOW;
            }
            case 4:
            {
                alpha = 100;
                delay = 0.5;
                duration = 20.0;
                fx=RENDERFX_HOLOGRAM;
            }
        }

        /* If the Player also has the Cloak of Shadows,
         * Decrease the delay and Increase the duration.
         */
        new cloak = FindShopItem("cloak");
        if (cloak != -1 && GetOwnsItem(player,cloak))
        {
            alpha    *= 0.90;
            delay    *= 0.90;
            duration *= 1.10;
        }

        new Float:start[3];
        GetClientAbsOrigin(client, start);

        new color[4] = { 0, 255, 50, 128 };
        TE_SetupBeamRingPoint(start,30.0,60.0,g_lightningSprite,g_lightningSprite,
                0, 1, 2.0, 10.0, 0.0, color, 10, 0);
        TE_SendToAll();

        SetVisibility(player, alpha, TimedMeleeInvisibility, delay, duration,
                      RENDER_TRANSTEXTURE, fx);
    }
    else
        SetVisibility(player, -1);
}

Lockdown(victim_index, Handle:player)
{
    new lockdown_level=GetUpgradeLevel(player,raceID,lockdownID);
    if (lockdown_level)
    {
        new percent;
        switch(lockdown_level)
        {
            case 1:
                percent=15;
            case 2:
                percent=21;
            case 3:
                percent=37;
            case 4:
                percent=52;
        }
        if (GetRandomInt(1,100)<=percent && (!gLockdownTime[victim_index] ||
             GetGameTime() - gLockdownTime[victim_index] > 2.0))
        {
            new Float:Origin[3];
            GetClientAbsOrigin(victim_index, Origin);
            TE_SetupGlowSprite(Origin,g_lightningSprite,1.0,2.3,90);

            gLockdownTime[victim_index] = GetGameTime();
            FreezeEntity(victim_index);
            EmitSoundToAll(lockdownWav,victim_index);
            AuthTimer(1.0,victim_index,UnfreezePlayer);
        }
    }
}

public Action:OcularImplants(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceID)
                {
                    new Float:detecting_range;
                    new detecting_level=GetUpgradeLevel(player,raceID,detectorID);
                    if (detecting_level)
                    {
                        switch(detecting_level)
                        {
                            case 1:
                                detecting_range=300.0;
                            case 2:
                                detecting_range=450.0;
                            case 3:
                                detecting_range=650.0;
                            case 4:
                                detecting_range=800.0;
                        }
                    }

                    new Float:clientLoc[3];
                    GetClientAbsOrigin(client, clientLoc);
                    for (new index=1;index<=maxplayers;index++)
                    {
                        if (index != client && IsClientInGame(index))
                        {
                            if (IsPlayerAlive(index))
                            {
                                new Handle:player_check=GetPlayerHandle(index);
                                if (player_check != INVALID_HANDLE)
                                {
                                    decl String:clientName[64];
                                    GetClientName(client,clientName,63);

                                    decl String:name[64];
                                    GetClientName(index,name,63);

                                    if (GetClientTeam(index) != GetClientTeam(client))
                                    {
                                        new bool:detect = IsInRange(client,index,detecting_range);
                                        if (detect)
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            detect = TraceTarget(client, index, clientLoc, indexLoc);
                                        }
                                        if (detect && !GetImmunity(player_check,Immunity_Uncloaking))
                                        {
                                            SetOverrideVisiblity(player_check, 255);
                                            if (TF2_GetPlayerClass(index) == TFClass_Spy)
                                            {
                                                TF2_RemovePlayerDisguise(index);
                                                TF2_SetPlayerCloak(index, false);

                                                new Float:cloakMeter = GetEntDataFloat(index,m_OffsetCloakMeter);
                                                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                                {
                                                    SetEntDataFloat(index,m_OffsetCloakMeter, 0.0);
                                                }
                                            }
                                            m_Detected[client][index] = true;
                                        }
                                        else if (m_Detected[client][index])
                                        {
                                            SetOverrideVisiblity(player_check, -1);
                                            m_Detected[client][index] = false;
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
    return Plugin_Continue;
}

ResetOcularImplants(client)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        new Handle:player = GetPlayerHandle(index);
        if (player != INVALID_HANDLE)
        {
            if (m_Detected[client][index])
            {
                SetOverrideVisiblity(player, -1);
                m_Detected[client][index] = false;
            }
        }
    }
}

TargetNuclearDevice(client)
{
    if (!GetConVarBool(cvarNuclearLaunchEnable))
    {
        PrintToChat(client,"%c[SourceCraft] %c Sorry, NuclearLaunch has been disabled for testing purposes!",
                    COLOR_GREEN,COLOR_DEFAULT);
        return;
    }

    EmitSoundToAll(targetWav,client);
    new Handle:TrackTimer = AuthTimer(0.2,client,TrackNuclearTarget,TIMER_REPEAT); // Create aiming loop
    m_NuclearTimer[client] = TrackTimer;
    m_NuclearLaunchStatus[client] = Tracking;
    TriggerTimer(TrackTimer, true);
}

LaunchNuclearDevice(client,Handle:player)
{
    if (m_NuclearTimer[client] != INVALID_HANDLE)
    {
        KillTimer(m_NuclearTimer[client]);
        m_NuclearTimer[client] = INVALID_HANDLE;
    }

    m_NuclearLaunchStatus[client]=LaunchInitiated;

    EmitSoundToAll(detectedWav,SOUND_FROM_PLAYER);
    SetVisibility(player, 100, TimedInvisibility, 0.0, 0.0, RENDER_TRANSTEXTURE, RENDERFX_HOLOGRAM);
    SetOverrideSpeed(player, 0.0);

    new Float:launchTime = GetConVarFloat(cvarNuclearLaunchTime);
    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c, you must now wait %3.1f seconds for the missle to lock on.",
                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, launchTime);

    AuthTimer(launchTime,client,NuclearLockOn);
}

public Action:TrackNuclearTarget(Handle:timer,Handle:pack)
{
    new index=ClientOfAuthTimer(pack);
    if (m_NuclearLaunchStatus[index]  == Tracking &&
        IsClientInGame(index) && IsPlayerAlive(index))
    {
        new Float:indexLoc[3], Float:targetLoc[3];
        GetClientEyePosition(index, indexLoc);
        TraceAimPosition(index, targetLoc, true);

        new color[4] = { 0, 0, 0, 150 };
        new team = GetClientTeam(index);
        if (team == 3)
            color[2] = 255; // Blue
        else
            color[0] = 255; // Red

        indexLoc[2] -= 30;
        TE_SetupBeamPoints(indexLoc, targetLoc, g_laserSprite, 0,
                           0, 0, 0.2, 3.0, 3.0, 1, 0.0, color, 0);

        TE_SendToClient(index);
        m_NuclearAimPos[index] = targetLoc;
        return Plugin_Handled;
    }
    else
    {
        if (m_NuclearTimer[index] == timer)
            m_NuclearTimer[index] = INVALID_HANDLE;

        return Plugin_Stop;
    }
}

public Action:NuclearLockOn(Handle:timer,Handle:pack)
{
    new client=ClientOfAuthTimer(pack);
    if (m_NuclearLaunchStatus[client] == LaunchInitiated)
    {
        m_NuclearLaunchStatus[client] = LockedOn;
        new Handle:player = GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            SetVisibility(player, -1);
            SetOverrideSpeed(player, -1.0);

            EmitSoundToAll(launchWav,SOUND_FROM_PLAYER);

            new Float:lockTime = GetConVarFloat(cvarNuclearLockTime);
            PrintToChat(client,"%c[SourceCraft]%c The missle has locked on, you have %3.1f seconds to evacuate.",
                        COLOR_GREEN,COLOR_DEFAULT, lockTime);

            if (GetRandomInt(1,10) > 5)
            {
                EmitSoundToAll(airRaidWav,SOUND_FROM_WORLD,SNDCHAN_AUTO,
                               SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,
                               SNDPITCH_NORMAL,-1,m_NuclearAimPos[client],
                               NULL_VECTOR,true,0.0);
            }

            new Handle:NuclearPack;
            if (CreateDataTimer(lockTime,NuclearImpact,NuclearPack)
                && pack != INVALID_HANDLE)
            {
                WritePackCell(NuclearPack, client);
                WritePackCell(NuclearPack, GetUpgradeLevel(player,raceID,nukeID));
            }
        }
        else
            m_NuclearLaunchStatus[client] = Ready;
    }
    else
    {
        new Float:cooldown = GetConVarFloat(cvarNuclearCooldown);
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c without effect, you now need to wait %3.1f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
        CreateTimer(cooldown,AllowNuclearLaunch,client);
    }
}

public Action:NuclearImpact(Handle:timer,Handle:pack)
{
    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        new client = ReadPackCell(pack);
        new ult_level=ReadPackCell(pack);
        LogMessage("NuclearImpact, client=%d", client);
        if (m_NuclearLaunchStatus[client] == LockedOn)
        {
            m_NuclearLaunchStatus[client] = Exploding;
            m_NuclearDuration[client] = ult_level*3;
            new Handle:NuclearPack;
            new Handle:NuclearTimer = CreateDataTimer(0.4, NuclearExplosion, NuclearPack,TIMER_REPEAT);
            if (NuclearTimer != INVALID_HANDLE && NuclearPack != INVALID_HANDLE)
            {
                WritePackCell(NuclearPack, client);
                WritePackCell(NuclearPack, ult_level);
                TriggerTimer(NuclearTimer, true);
            }
        }
    }
}

public Action:NuclearExplosion(Handle:timer,Handle:pack)
{
    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        new client = ReadPackCell(pack);
        new ult_level=ReadPackCell(pack);
        new iteration = (--m_NuclearDuration[client]);
        LogMessage("NuclearExplosion, client=%d, iteration=%d", client, iteration);
        if (iteration > 0)
        {
            new Handle:player=GetPlayerHandle(client);
            if (player != INVALID_HANDLE)
            {
                new Float:radius, Float:scale;
                new r_int, magnitude, damage;
                switch(ult_level)
                {
                    case 1:
                    {
                        damage = 600;
                        radius = 600.0;
                        r_int  = 600;
                        magnitude = 600;
                        scale = 100.0;
                    }
                    case 2:
                    {
                        damage = 700;
                        radius = 1000.0;
                        r_int  = 1000;
                        magnitude = 1000;
                        scale = 100.0;
                    }
                    case 3:
                    {
                        damage = 800;
                        radius = 2000.0;
                        r_int  = 2000;
                        magnitude = 2000;
                        scale = 100.0;
                    }
                    case 4:
                    {
                        damage = 1000;
                        radius = 0.0;
                        r_int  = 3000;
                        magnitude = 3000;
                        scale = 100.0;
                    }
                }

                switch (iteration % 8)
                {
                    case 1:
                    {
                        LogMessage("NuclearExplosion, effect=2");
                        new Float:rorigin[3],sb;
                        for(new i = 1 ;i < 50; ++i)
                        {
                            rorigin[0] = GetRandomFloat(0.0,3000.0);
                            rorigin[1] = GetRandomFloat(0.0,3000.0);
                            rorigin[2] = GetRandomFloat(0.0,2000.0);
                            sb = GetRandomInt(0,2);
                            if(sb == 0)
                                rorigin[0] = rorigin[0] * -1;
                            sb = GetRandomInt(0,2);
                            if(sb == 0)
                                rorigin[1] = rorigin[1] * -1;
                            sb = GetRandomInt(0,2);
                            if(sb == 0)
                                rorigin[2] = rorigin[2] * -1;
                            explodeall(rorigin);
                        }
                    }
                    case 2:
                    {
                        LogMessage("NuclearExplosion, effect=3");
                        Shake(0, 14.0, 10.0, 150.0);
                        explodeall(m_NuclearAimPos[client]);
                    }
                    case 3:
                    {
                        LogMessage("NuclearExplosion, effect=4");
                        new color[4]={250,250,250,255};
                        Fade(600, 600 , color);
                        explodeall(m_NuclearAimPos[client]);
                    }
                    case 4:
                    {
                        Shake(0, 14.0, 10.0, 150.0);
                    }
                    default:
                    {
                        LogMessage("NuclearExplosion, effect=default");
                        TE_SetupExplosion(m_NuclearAimPos[client],g_explosionModel,scale,1,0,r_int,magnitude);
                        TE_SendToAll();

                        new Float:dir[3];
                        dir[0] = 0.0;
                        dir[1] = 0.0;
                        dir[2] = 2.0;
                        TE_SetupDust(m_NuclearAimPos[client],dir,radius,100.0);
                        TE_SendToAll();
                    }
                }

                new String:explosion[64];
                switch(GetRandomInt(1,8))
                {
                    case 1: strcopy(explosion, sizeof(explosion), explode1Wav);
                    case 2: strcopy(explosion, sizeof(explosion), explode2Wav);
                    case 3: strcopy(explosion, sizeof(explosion), explode3Wav);
                    case 4: strcopy(explosion, sizeof(explosion), explode4Wav);
                    case 5: strcopy(explosion, sizeof(explosion), explode5Wav);
                    case 6: strcopy(explosion, sizeof(explosion), explode6Wav);
                    case 7: strcopy(explosion, sizeof(explosion), explode7Wav);
                }

                EmitSoundToAll(explosion,SOUND_FROM_WORLD,SNDCHAN_AUTO,
                               SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,
                               SNDPITCH_NORMAL,-1,m_NuclearAimPos[client],
                               NULL_VECTOR,true,0.0);

                new count=0;
                new num=iteration*2;
                new minDmg=iteration*5;
                new maxDmg=iteration*20;
                new maxplayers=GetMaxClients();
                for(new index=1;index<=maxplayers;index++)
                {
                    if (IsClientInGame(index) && IsPlayerAlive(index))
                    {
                        new Handle:player_check=GetPlayerHandle(index);
                        if (player_check != INVALID_HANDLE)
                        {
                            if (!GetImmunity(player_check,Immunity_Ultimates) &&
                                !GetImmunity(player_check,Immunity_Explosion) &&
                                !GetImmunity(player_check,Immunity_HealthTake) &&
                                !TF2_IsPlayerInvuln(index))
                            {
                                new Float:indexLoc[3];
                                GetClientAbsOrigin(index, indexLoc);
                                if ( IsPointInRange(m_NuclearAimPos[client],indexLoc,radius))
                                {
                                    if (TraceTarget(0, index, m_NuclearAimPos[client], indexLoc))
                                    {
                                        new amt = PowerOfRange(m_NuclearAimPos[client],radius,indexLoc,damage,0.5,false);
                                        if (amt <= minDmg)
                                            amt = GetRandomInt(minDmg,maxDmg);

                                        if (HurtPlayer(index,amt,client,"nuclear_launch", "Nuclear Launch", 5+ult_level) <= 0)
                                            LogMessage("Nuclear Launch killed %d->%N!", index, index);
                                        else
                                            LogMessage("Nuclear Launch damaged %d->%N!", index, index);

                                        if (++count > num)
                                            break;
                                    }
                                }
                            }
                        }
                    }
                }
                return Plugin_Continue;
            }
            else
                LogMessage("Invalid Player Handle");
        }
        else
            LogMessage("iterations expired");

        Shake(1, 0.0, 0.0, 0.0);

        if (IsClientInGame(client))
        {
            new Float:cooldown = GetConVarFloat(cvarNuclearCooldown);

            PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c, you now need to wait %3.1f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);

            m_NuclearLaunchStatus[client]=Quiescent;
            CreateTimer(cooldown,AllowNuclearLaunch,client);
        }
        else
            m_NuclearLaunchStatus[client] = Ready;
    }
    else
        LogMessage("invalid pack");

    return Plugin_Stop;
}

public Action:AllowNuclearLaunch(Handle:timer,any:index)
{
    m_NuclearLaunchStatus[index] = Ready;
    if (IsClientInGame(index) && IsPlayerAlive(index))
        EmitSoundToClient(index,readyWav);

    return Plugin_Stop;
}

public explodeall(Float:vec1[3])
{
	vec1[2] += 10.0;
	new color[4]={188,220,255,255};
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_fire2Sprite, 10.0, 1, 0, 0, 5000); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 1500.0, g_fireSprite, g_HaloSprite, 0, 66, 6.0, 128.0, 0.2, color, 25, 0);
  	TE_SendToAll();
}

public explode(Float:vec1[3])
{
	new color[4]={188,220,255,200};
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_fire2Sprite, 10.0, 1, 0, 0, 5000); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, g_whiteSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();
}

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}
