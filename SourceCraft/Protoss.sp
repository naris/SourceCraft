 /**
 * vim: set ai et ts=4 sw=4 :
 * File: Protoss.sp
 * Description: The Protoss race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <tf2_player>
#include <tf2_cloak>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/MindControl"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:explodeWav[] = "sourcecraft/PSaHit00.wav";
new String:unCloakWav[] = "sourcecraft/PabCag00.wav";
new String:cloakWav[] = "sourcecraft/pabRdy00.wav";

new raceID, scarabID, cloakID, sensorID, controlID;

new bool:m_MindControlAvailable = false;

new Handle:cvarMindControlCooldown = INVALID_HANDLE;
new Handle:cvarMindControlEnable = INVALID_HANDLE;

new m_Cloaked[MAXPLAYERS+1][MAXPLAYERS+1];
new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];
new bool:m_AllowMindControl[MAXPLAYERS+1];
new Float:gReaverScarabTime[MAXPLAYERS+1];

new explosionModel;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss",
    author = "-=|JFH|=-Naris",
    description = "The Protoss race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarMindControlCooldown=CreateConVar("sc_mindcontrolcooldown","45");
    cvarMindControlEnable=CreateConVar("sc_mindcontrolenable","1");

    if(!HookEventEx("player_spawn",PlayerSpawnEvent))
        SetFailState("Could not hook the player_spawn event.");

    if (GameType == tf2)
    {
        if(!HookEventEx("teamplay_round_win",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_win event.");

        if(!HookEventEx("teamplay_round_stalemate",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_stalemate event.");

        if(!HookEventEx("tf_game_over",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_win_panel event.");

        if(!HookEventEx("teamplay_game_over",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_win_panel event.");

        if(!HookEventEx("teamplay_win_panel",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_win_panel event.");
    }

    CreateTimer(1.0,CloakingAndDetector,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    m_MindControlAvailable = LibraryExists("MindControl");

    raceID    = CreateRace("Protoss", "protoss",
                           "You are now part of the Protoss.",
                           "You will be part of the Protoss when you die or respawn.",
                           32);

    scarabID  = AddUpgrade(raceID,"Reaver Scarabs", "scarabs",
                           "Explode upon contact with enemies, causing increased damage. (Disabled)");

    cloakID   = AddUpgrade(raceID,"Arbiter Reality-Warping Field", "arbiter",
                           "Cloaks all friendly units within range");

    sensorID  = AddUpgrade(raceID,"Observer Sensors", "sensors",
                           "Reveals enemy invisible units within range");

    if (m_MindControlAvailable)
    {
        controlID = AddUpgrade(raceID,"Mind Control", "mind_control",
                               "Allows you to control an object from the opposite team.",
                               true); // Ultimate
    }
    else
    {
        controlID = AddUpgrade(raceID,"Mind Control", "mind_control",
                               "Not Available", true, 99, 0); // Ultimate
    }
}

public OnMapStart()
{
    explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");
    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(rechargeWav, true, true);
    SetupSound(explodeWav, true, true);
    SetupSound(unCloakWav, true, true);
    SetupSound(cloakWav, true, true);
}

public OnMapEnd()
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
        ResetCloakingAndDetector(index);
}

public OnPlayerAuthed(client,Handle:player)
{
    m_AllowMindControl[client]=true;
}

public OnClientDisconnect(client)
{
    ResetCloakingAndDetector(client);
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
    {
        ResetCloakingAndDetector(client);
        ResetMindControlledObjects(client, false);
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client) &&
        m_AllowMindControl[client] && pressed &&
        m_MindControlAvailable)
    {
        new ult_level=GetUpgradeLevel(player,raceID,controlID);
        if(ult_level)
        {
            if (!GetConVarBool(cvarMindControlEnable))
            {
                PrintToChat(client,"%c[SourceCraft] %c Sorry, MindControl has been disabled for testing purposes!",
                        COLOR_GREEN,COLOR_DEFAULT);
                return;
            }

            new Float:range, percent;
            switch(ult_level)
            {
                case 1:
                    {
                        range=150.0;
                        percent=30;
                    }
                case 2:
                    {
                        range=300.0;
                        percent=50;
                    }
                case 3:
                    {
                        range=450.0;
                        percent=70;
                    }
                case 4:
                    {
                        range=650.0;
                        percent=90;
                    }
            }

            new builder;
            new objects:type;
            if (MindControl(client, range, percent, builder, type))
            {
                new Float:cooldown = GetConVarFloat(cvarMindControlCooldown);
                LogToGame("[SourceCraft] %N has stolen %d's %s!\n",
                        client,builder,objectName[type]);
                PrintToChat(builder,"%c[SourceCraft] %c %N has stolen your %s!",
                        COLOR_GREEN,COLOR_DEFAULT,client,objectName[type]);
                PrintToChat(client,"%c[SourceCraft] %c You have used your ultimate %cMind Control%c to steal %N's %s, you now need to wait %2.0f seconds before using it again.!", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,builder,objectName[type], cooldown);

                if (cooldown > 0.0)
                {
                    m_AllowMindControl[client]=false;
                    CreateTimer(cooldown,AllowMindControl,client);
                }
            }
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    if (index>0)
    {
        new Handle:player=GetPlayerHandle(index);
        if (player != INVALID_HANDLE)
        {
            new race = GetRace(player);
            if (race == raceID)
                m_AllowMindControl[index]=true;
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    if (attacker_race == raceID && victim_index != attacker_index)
    {
        if (ReaverScarab(damage, victim_index, victim_player,
                         attacker_index, attacker_player))
        {
            changed = true;
        }
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        if (ReaverScarab(damage, victim_index, victim_player,
                         assister_index, assister_player))
        {
            changed = true;
        }
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_index && victim_race == raceID)
    {
        ResetCloakingAndDetector(victim_index);
        ResetMindControlledObjects(victim_index, false);
    }
}

public RoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        ResetCloakingAndDetector(index);
        ResetMindControlledObjects(index, true);
    }
}

bool:ReaverScarab(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new rs_level = GetUpgradeLevel(player,raceID,scarabID);
    if (rs_level > 0)
    {
        if (!GetImmunity(victim_player,Immunity_Explosion) &&
            !TF2_IsPlayerInvuln(victim_index))
        {
            new Float:lastTime = gReaverScarabTime[index];
            new Float:interval = GetGameTime() - lastTime;
            if (lastTime == 0.0 || interval > 0.5)
            {
                new Float:percent, chance;
                switch(rs_level)
                {
                    case 1:
                    {
                        chance=20;
                        percent=0.14;
                    }
                    case 2:
                    {
                        chance=40;
                        percent=0.27;
                    }
                    case 3:
                    {
                        chance=60;
                        percent=0.43;
                    }
                    case 4:
                    {
                        chance=90;
                        percent=0.63;
                    }
                }

                if (GetRandomInt(1,100) <= chance)
                {
                    new health_take = RoundToFloor(float(damage)*percent);
                    if (health_take > 0)
                    {
                        new new_health=GetClientHealth(victim_index)-health_take;
                        if (new_health <= 0)
                        {
                            new_health=0;
                            LogKill(index, victim_index, "scarab", "Reaver Scarab", health_take);
                        }
                        else
                            LogDamage(index, victim_index, "scarab", "Reaver Scarab", health_take);

                        SetEntityHealth(victim_index,new_health);

                        if (gReaverScarabTime[index] == 0.0 || interval >= 2.0)
                        {
                            new Float:Origin[3];
                            GetClientAbsOrigin(victim_index, Origin);
                            Origin[2] += 5;

                            TE_SetupExplosion(Origin,explosionModel,5.0,1,0,5,10);
                            TE_SendToAll();
                        }

                        EmitSoundToAll(explodeWav,victim_index);
                        gReaverScarabTime[index] = GetGameTime();
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

public Action:AllowMindControl(Handle:timer,any:index)
{
    m_AllowMindControl[index]=true;
    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        if (GetRace(GetPlayerHandle(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cMind Control%c is now available again!",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}

public Action:CloakingAndDetector(Handle:timer)
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
                    new Float:cloaking_range;
                    new cloaking_level=GetUpgradeLevel(player,raceID,cloakID);
                    if (cloaking_level)
                    {
                        switch(cloaking_level)
                        {
                            case 1:
                                cloaking_range=300.0;
                            case 2:
                                cloaking_range=450.0;
                            case 3:
                                cloaking_range=650.0;
                            case 4:
                                cloaking_range=800.0;
                        }
                    }

                    new Float:detecting_range;
                    new detecting_level=GetUpgradeLevel(player,raceID,sensorID);
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
                                    if (GetClientTeam(index) == GetClientTeam(client))
                                    {
                                        if (GetRace(player_check) == raceID &&
                                            GetUpgradeLevel(player_check,raceID,cloakID) > 0)
                                        {
                                            continue; // Don't cloak other arbiters!
                                        }

                                        new bool:cloak = IsInRange(client,index,cloaking_range);
                                        if (cloak)
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            cloak = TraceTarget(client, index, clientLoc, indexLoc);
                                        }

                                        if (cloak)
                                        {
                                            SetVisibility(player_check,0,BasicVisibility,0.0,0.0);
                                            m_Cloaked[client][index] = true;

                                            if (!m_Cloaked[client][index])
                                            {
                                                EmitSoundToClient(client, cloakWav);
                                                LogToGame("[SourceCraft] %N has been cloaked by %N!\n", index,client);
                                                PrintToChat(index,"%c[SourceCraft] %N %c has been cloaked by %N!",
                                                            COLOR_GREEN,index,COLOR_DEFAULT,client);
                                            }
                                        }
                                        else if (m_Cloaked[client][index])
                                        {
                                            SetVisibility(player_check, -1);
                                            m_Cloaked[client][index] = false;

                                            EmitSoundToClient(client, unCloakWav);
                                            LogToGame("[SourceCraft] %N has been uncloaked!\n", index);
                                            PrintToChat(index,"%c[SourceCraft] %N %c has been uncloaked!",
                                                        COLOR_GREEN,index,COLOR_DEFAULT);
                                        }
                                    }
                                    else
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
                                                TF2_SetPlayerCloak(client, false);

                                                new Float:cloakMeter = TF2_GetCloakMeter(index);
                                                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                                    TF2_SetCloakMeter(index, 0.0);
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

stock ResetCloakingAndDetector(client)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        new Handle:player = GetPlayerHandle(index);
        if (player != INVALID_HANDLE)
        {
            if (m_Cloaked[client][index])
            {
                SetVisibility(player, -1);
                m_Cloaked[client][index] = false;
            }

            if (m_Detected[client][index])
            {
                SetOverrideVisiblity(player, -1);
                m_Detected[client][index] = false;
            }
        }
    }
}
