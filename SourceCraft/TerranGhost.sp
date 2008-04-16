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

#include "sc/log" // for debugging

new raceID, cloakID, lockdownID, detectorID, nukeID;

new explosionModel;
new g_smokeSprite;
new g_lightningSprite;

new m_OffsetCloakMeter;
new m_OffsetDisguiseTeam;
new m_OffsetDisguiseClass;
new m_OffsetDisguiseHealth;

new Handle:cvarNuclearLaunchEnable = INVALID_HANDLE;
new Handle:cvarNuclearLaunchTime = INVALID_HANDLE;
new Handle:cvarNuclearLockTime = INVALID_HANDLE;
new Handle:cvarNuclearCooldown = INVALID_HANDLE;

new m_nuclearAimDot[MAXPLAYERS+1];
new Float:m_nuclearAimPos[MAXPLAYERS+1][3];
new bool:m_AllowNuclearLaunch[MAXPLAYERS+1];
new bool:m_NuclearLaunchInitiated[MAXPLAYERS+1];
new bool:m_NuclearLaunchLockedOn[MAXPLAYERS+1];

new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

new Float:gLockdownTime[MAXPLAYERS+1];

new String:readyWav[] = "sourcecraft/tadupd07.wav";
new String:targetWav[] = "sourcecraft/tghlas00.wav";
new String:launchWav[] = "sourcecraft/tnsfir00.wav";
new String:detectedWav[] = "sourcecraft/tadupd04.wav";
new String:explodeWav[] = "sourcecraft/tnshit00.wav";
new String:lockdownWav[] = "sourcecraft/tghlkd00.wav";

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

    cvarNuclearLaunchEnable=CreateConVar("sc_nuclearlaunchenable","0");
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

        m_OffsetDisguiseTeam=FindSendPropInfo("CTFPlayer","m_nDisguiseTeam");
        if (m_OffsetDisguiseTeam == -1)
            SetFailState("Couldn't find DisguiseTeam Offset");

        m_OffsetDisguiseClass=FindSendPropInfo("CTFPlayer","m_nDisguiseClass");
        if (m_OffsetDisguiseClass == -1)
            SetFailState("Couldn't find DisguiseClass Offset");

        m_OffsetDisguiseHealth=FindSendPropInfo("CTFPlayer","m_iDisguiseHealth");
        if (m_OffsetDisguiseHealth == -1)
            SetFailState("Couldn't find DisguiseHealth Offset");
    }
}

public OnMapStart()
{
    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt", true);
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    if (GameType == tf2)
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt", true);
    else
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt", true);

    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(readyWav, true, true);
    SetupSound(targetWav, true, true);
    SetupSound(launchWav, true, true);
    SetupSound(explodeWav, true, true);
    SetupSound(detectedWav, true, true);
    SetupSound(lockdownWav, true, true);
}

public OnPlayerAuthed(client,Handle:player)
{
    m_AllowNuclearLaunch[client]=true;
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
            m_AllowNuclearLaunch[client]=true;
        }
        else if (race == raceID)
            Cloak(client, player, GetUpgradeLevel(player,race,cloakID));
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && m_AllowNuclearLaunch[client] &&
        IsPlayerAlive(client))
    {
        new ult_level=GetUpgradeLevel(player,race,nukeID);
        if(ult_level)
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

        if (m_NuclearLaunchInitiated[victim_index])
        {
            m_NuclearLaunchInitiated[victim_index]=false;
            SetOverrideSpeed(victim_player, -1.0);
        }
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
    TraceAimPosition(client, m_nuclearAimPos[client], true);

    new ent = CreateEntityByName("env_sniperdot");
    if (ent)
    {
        SetEntDataVector(ent, FindSendPropOffs("CSniperDot","m_vecOrigin") , m_nuclearAimPos[client]);
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_flSimulationTime"), GetGameTime(), 1); // (bits 8)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_nModelIndex"), -65536, 2); // (bits 11)
        SetEntData(ent, FindSendPropInfo("CSniperDot","m_nRenderFX"), 0, 1); // (bits 8)
        SetEntData(ent, FindSendPropInfo("CSniperDot","m_nRenderMode"), -16777216, 1); // (bits 8)
        SetEntData(ent, FindSendPropInfo("CSniperDot","m_fEffects"), 16, 2); // (bits 10)
        SetEntData(ent, FindSendPropInfo("CSniperDot","m_clrRender"), -1, 4); // (bits 32)
        SetEntData(ent, FindSendPropInfo("CSniperDot","m_iTeamNum"), GetClientTeam(client), 1); // (bits 6)
        SetEntData(ent, FindSendPropInfo("CSniperDot","m_CollisionGroup"), 0, 1); // (bits 5)
        SetEntDataFloat(ent, FindSendPropInfo("CSniperDot","m_flElasticity"), 1.0);
        SetEntDataFloat(ent, FindSendPropInfo("CSniperDot","m_flShadowCastDistance"), 0.0); // (bits 12)
        SetEntDataEnt2(ent, FindSendPropInfo("CSniperDot","m_hOwnerEntity"), client); // (bits 21)
        //SetEntDataEnt2(ent, FindSendPropInfo("CSniperDot","m_hEffectEntity"), -1); // (bits 21)
        //SetEntDataEnt2(ent, FindSendPropInfo("CSniperDot","moveparent"), -1); // (bits 21)
        SetEntData(ent, FindSendPropInfo("CSniperDot","m_iParentAttachment"), -16777216, 1); // (bits 6)
        SetEntData(ent, FindSendPropInfo("CSniperDot","movetype"), -65536); // (bits 4)
        SetEntData(ent, FindSendPropInfo("CSniperDot","movecollide"), -256); // (bits 3)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_angRotation"), 0); // (bits 13)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_iTextureFrameIndex"), 0); // (bits 8)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_bSimulatedEveryTick"), 0);
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_bAnimatedEveryTick"), 0);
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_bAlternateSorting"), 0);
        //SetEntDataFloat(ent, FindSendPropInfo("CSniperDot","m_flChargeStartTime"), GetGameTime());

    //   Sub-Class Table (3 Deep): DT_AnimTimeMustBeFirst
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_flAnimTime"), 0); // (bits 8)

    //   Sub-Class Table (3 Deep): DT_CollisionProperty
        //new Float:m_vecMins[3];
        //SetEntDataVector(ent, FindSendPropInfo("CSniperDot","m_vecMins"), m_vecMins);

        //new Float:m_vecMaxs[3];
        //SetEntDataVector(ent, FindSendPropInfo("CSniperDot","m_vecMaxs"), m_vecMaxs);

        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_nSolidType"), 0); // (bits 3)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_usSolidFlags"), 119341060); // (bits 10)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_nSurroundType"), 0); // (bits 3)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_triggerBloat"), 0); // (bits 8)

        //new Float:m_vecSpecifiedSurroundingMins[3] = { 0.0, 0.0, 0.0 };
        //SetEntDataVector(ent, FindSendPropInfo("CSniperDot","m_vecSpecifiedSurroundingMins"), m_vecSpecifiedSurroundingMins);

        //new Float:m_vecSpecifiedSurroundingMaxs[3] = { 0.0, 0.0, 0.0 };
        //SetEntDataVector(ent, FindSendPropInfo("CSniperDot","m_vecSpecifiedSurroundingMaxs"), m_vecSpecifiedSurroundingMaxs);

    //   Sub-Class Table (3 Deep): DT_PredictableId
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_PredictableID"), 0); // (bits 31)
        //SetEntData(ent, FindSendPropInfo("CSniperDot","m_bIsPlayerSimulated"), 0);

        DispatchSpawn(ent);
        TeleportEntity(ent, m_nuclearAimPos[client], NULL_VECTOR, NULL_VECTOR);

        m_nuclearAimDot[client] = ent;
        CreateTimer(0.1,TrackNuclearTarget,client,TIMER_REPEAT); // Create aiming loop
    }
}

public Action:TrackNuclearTarget(Handle:timer,any:index)
{
    if (m_nuclearAimDot[index])
    {
        if (IsClientInGame(index) && IsPlayerAlive(index) &&
            !m_NuclearLaunchLockedOn[index])
        {
            TraceAimPosition(index, m_nuclearAimPos[index], true);
            TeleportEntity(m_nuclearAimDot[index], m_nuclearAimPos[index],
                           NULL_VECTOR, NULL_VECTOR);
            return Plugin_Handled;
        }
        else
        {
            RemoveEdict(m_nuclearAimDot[index]);
            m_nuclearAimDot[index] = 0;
        }
    }
    return Plugin_Stop;
}

LaunchNuclearDevice(client,Handle:player)
{
    EmitSoundToAll(detectedWav,SOUND_FROM_PLAYER);
    SetVisibility(player, 100, TimedInvisibility, 0.0, 0.0, RENDER_TRANSTEXTURE, RENDERFX_HOLOGRAM);
    SetOverrideSpeed(player, 0.0);

    new Float:launchTime = GetConVarFloat(cvarNuclearLaunchTime);
    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c, you must now wait %2.0f seconds for the missle to lock on.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, launchTime);
    m_AllowNuclearLaunch[client]=false;
    m_NuclearLaunchInitiated[client]=true;
    CreateTimer(launchTime,NuclearLockOn,client);
}

public Action:NuclearLockOn(Handle:timer,any:client)
{
    if (m_NuclearLaunchInitiated[client])
    {
        m_NuclearLaunchInitiated[client]=false;
        m_NuclearLaunchLockedOn[client]=true;
        EmitSoundToAll(launchWav,SOUND_FROM_PLAYER);

        new Float:lockTime = GetConVarFloat(cvarNuclearLockTime);
        PrintToChat(client,"%c[SourceCraft]%c The missle has locked on, you have %2.0f seconds to evacuate.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, lockTime);

        new Handle:player = GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            SetVisibility(player, -1);
            SetOverrideSpeed(player, -1.0);
        }

        CreateTimer(lockTime,NuclearExplosion,client);
    }
    else
    {
        new Float:cooldown = GetConVarFloat(cvarNuclearCooldown);
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c without effect, you now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
        CreateTimer(cooldown,AllowNuclearLaunch,client);
    }
}

public Action:NuclearExplosion(Handle:timer,any:client)
{
    new num = 0;
    if (m_NuclearLaunchLockedOn[client])
    {
        new Handle:player = GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            new Float:radius, Float:scale;
            new r_int, magnitude, damage;
            new ult_level=GetUpgradeLevel(player,raceID,nukeID);
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

            TE_SetupExplosion(m_nuclearAimPos[client],explosionModel,scale,1,0,r_int,magnitude);
            TE_SendToAll();

            EmitSoundToAll(explodeWav,SOUND_FROM_WORLD,SNDCHAN_AUTO,
                           SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,
                           SNDPITCH_NORMAL,-1,m_nuclearAimPos[client],
                           NULL_VECTOR,true,0.0);

            new count = GetClientCount();
            for(new index=1;index<=count;index++)
            {
                if (IsClientInGame(index) && IsPlayerAlive(index))
                {
                    new Handle:check_player=GetPlayerHandle(index);
                    if (check_player != INVALID_HANDLE)
                    {
                        if (!GetImmunity(check_player,Immunity_Ultimates) &&
                            !GetImmunity(check_player,Immunity_Explosion) &&
                            !TF2_IsPlayerInvuln(index))
                        {
                            new Float:check_location[3];
                            GetClientAbsOrigin(index,check_location);

                            new hp=PowerOfRange(m_nuclearAimPos[client],radius,check_location,damage,0.5,false);
                            if (hp)
                            {
                                if (TraceTarget(client, index, m_nuclearAimPos[client], check_location))
                                {
                                    HurtPlayer(index,hp,client,"nuclear_launch", "Nuclear Launch", 5+ult_level);
                                    num++;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    new Float:cooldown = GetConVarFloat(cvarNuclearCooldown);

    if (num)
    {
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c to damage %d enemies, you now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, num, cooldown);
    }
    else
    {
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c, which did no damage! You now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
    }

    CreateTimer(cooldown,AllowNuclearLaunch,client);
    m_NuclearLaunchLockedOn[client]=false;
}

public Action:AllowNuclearLaunch(Handle:timer,any:index)
{
    if (IsClientInGame(index))
    {
        if (IsPlayerAlive(index))
        {
            EmitSoundToClient(index,readyWav);
            m_AllowNuclearLaunch[index]=true;
        }
    }
    return Plugin_Stop;
}

/**
 * Sets up a TF2 explosion effect.
 *
 * @param pos			Explosion position.
 * @param Model			Precached model index.
 * @param Scale			Explosion scale.
 * @param Framerate		Explosion frame rate.
 * @param Flags			Explosion flags.
 * @param Radius		Explosion radius.
 * @param Magnitude		Explosion size.
 * @param normal		Normal vector to the explosion.
 * @param MaterialType		Exploded material type.
 * @noreturn
 */
stock TE_SetupTFExplosion(const Float:pos[3], Model, Float:Scale, Framerate, Flags, Radius, Magnitude, const Float:normal[3]={0.0, 0.0, 1.0}, MaterialType='C')
{
	TE_Start("TFExplosion");
	TE_WriteVector("m_vecOrigin[0]", pos);
	TE_WriteVector("m_vecNormal", normal);
	TE_WriteNum("m_nModelIndex", Model);
	TE_WriteFloat("m_fScale", Scale);
	TE_WriteNum("m_nFrameRate", Framerate);
	TE_WriteNum("m_nFlags", Flags);
	TE_WriteNum("m_nRadius", Radius);
	TE_WriteNum("m_nMagnitude", Magnitude);
	TE_WriteNum("m_chMaterialType", MaterialType);
}

