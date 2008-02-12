/**
 * vim: set ai et ts=4 sw=4 :
 * File: Protoss.sp
 * Description: The Protoss race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/range"
#include "sc/trace"
#include "sc/log"

new raceID; // The ID we are assigned to

new Handle:cvarMindControlCooldown = INVALID_HANDLE;
new Handle:cvarMindControlEnable = INVALID_HANDLE;

new m_Cloaked[MAXPLAYERS+1][MAXPLAYERS+1];
new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];
new bool:m_AllowMindControl[MAXPLAYERS+1];
new Float:gReaverScarabTime[MAXPLAYERS+1];

enum objects { unknown, sentrygun, dispenser, teleporter };
new m_BuilderOffset[objects];
new m_BuildingOffset[objects];

new m_OffsetCloakMeter;
new m_OffsetDisguiseTeam;
new m_OffsetDisguiseClass;
new m_OffsetDisguiseHealth;

// Arrays to keep track of stolen objects
new Handle:m_StolenObjectList[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:m_StolenBuilderList[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:m_StolenClassList[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

new g_redGlow;
new g_blueGlow;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new explosionModel;

new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:explodeWav[] = "sourcecraft/PSaHit00.wav";
new String:controlWav[] = "sourcecraft/pteSum00.wav";
new String:unCloakWav[] = "sourcecraft/PabCag00.wav";
new String:cloakWav[] = "sourcecraft/pabRdy00.wav";

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
    }

    CreateTimer(1.0,CloakingAndDetector,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID=CreateRace("Protoss", "protoss",
                      "You are now part of the Protoss.",
                      "You will be part of the Protoss when you die or respawn.",
                      "Reaver Scarabs",
                      "Explode upon contact with enemies, causing increased damage. (Disabled)",
                      "Arbiter Reality-Warping Field",
                      "Cloaks all friendly units within range",
                      "Observer Sensors",
                      "Reveals enemy invisible units within range",
                      "Dark Archon Mind Control",
                      "Allows you to control an object from the opposite team.",
                      "16");

    FindUberOffsets();

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

        m_BuilderOffset[sentrygun] = FindSendPropOffs("CObjectSentrygun","m_hBuilder");
        if(m_BuilderOffset[sentrygun] == -1)
            SetFailState("[SourceCraft] Error finding Sentrygun Builder offset.");

        m_BuildingOffset[sentrygun] = FindSendPropOffs("CObjectSentrygun","m_bBuilding");
        if(m_BuildingOffset[sentrygun] == -1)
            SetFailState("[SourceCraft] Error finding Sentrygun Building offset.");

        m_BuilderOffset[dispenser] = FindSendPropOffs("CObjectDispenser","m_hBuilder");
        if(m_BuilderOffset[dispenser] == -1)
            SetFailState("[SourceCraft] Error finding Dispenser Builder offset.");

        m_BuildingOffset[dispenser] = FindSendPropOffs("CObjectDispenser","m_bBuilding");
        if(m_BuildingOffset[dispenser] == -1)
            SetFailState("[SourceCraft] Error finding Dispenser Building offset.");

        m_BuilderOffset[teleporter] = FindSendPropOffs("CObjectTeleporter","m_hBuilder");
        if(m_BuilderOffset[teleporter] == -1)
            SetFailState("[SourceCraft] Error finding Teleporter Builder offset.");

        m_BuildingOffset[teleporter] = FindSendPropOffs("CObjectTeleporter","m_bBuilding");
        if(m_BuildingOffset[teleporter] == -1)
            SetFailState("[SourceCraft] Error finding Teleporter Building offset.");
    }
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_blueGlow = SetupModel("materials/sprites/blueglow1.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find blueglow Model");

    g_redGlow = SetupModel("materials/sprites/redglow1.vmt");
    if (g_redGlow == -1)
        SetFailState("Couldn't find redglow Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");
    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(rechargeWav, true);
    SetupSound(explodeWav, true);
    SetupSound(controlWav, true);
    SetupSound(unCloakWav, true);
    SetupSound(cloakWav, true);
}

public OnPlayerAuthed(client,player)
{
    m_AllowMindControl[client]=true;
}

public OnClientDisconnect(client)
{
    ResetCloakingAndDetector(client);
    ResetMindControledObjects(client);
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
    {
        ResetCloakingAndDetector(client);
        ResetMindControledObjects(client);
    }
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client) &&
        m_AllowMindControl[client] && pressed)
    {
        MindControl(client,player);
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    if (index>0)
    {
        new player=GetPlayer(index);
        if (player>-1)
        {
            new race = GetRace(player);
            if (race == raceID)
                m_AllowMindControl[index]=true;
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,victim_player,victim_race,
                                attacker_index,attacker_player,attacker_race,
                                assister_index,assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    LogEventDamage(event, damage, "Protoss::PlayerHurtEvent", raceID);

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

public Action:OnPlayerDeathEvent(Handle:event,victim_index,victim_player,victim_race,
                                 attacker_index,attacker_player,attacker_race,
                                 assister_index,assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    LogEventDamage(event, damage, "Protoss::PlayerDeathEvent", raceID);

    if (victim_index && victim_race == raceID)
    {
        ResetCloakingAndDetector(victim_index);
        ResetMindControledObjects(victim_index);
    }
}

public RoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        ResetCloakingAndDetector(index);
        ResetMindControledObjects(index);
    }
}

bool:ReaverScarab(damage, victim_index, victim_player, index, player)
{
    new skill_cg = GetSkillLevel(player,raceID,0);
    if (skill_cg > 0)
    {
        new Float:percent, chance;
        switch(skill_cg)
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

        if (!GetImmunity(victim_player,Immunity_Explosion) && !IsUber(victim_index) &&
            GetRandomInt(1,100) <= chance &&
            (!gReaverScarabTime[index] ||
             GetGameTime() - gReaverScarabTime[index] > 0.5))
        {
            new health_take= RoundToFloor(float(damage)*percent);
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

                if (!gReaverScarabTime[index] ||
                    GetGameTime() - gReaverScarabTime[index] >= 2.0)
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
    return false;
}

MindControl(client,player)
{
    new ult_level=GetSkillLevel(player,raceID,3);
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

        new target = TraceAimTarget(client);
        if (target >= 0)
        {
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);

            new Float:targetLoc[3];
            TR_GetEndPosition(targetLoc);

            if (IsPointInRange(clientLoc,targetLoc,range))
            {
                new Float:distance=DistanceBetween(clientLoc,targetLoc);
                if (GetRandomFloat(1.0,100.0) <= float(percent) * (1.0 - FloatDiv(distance,range)+0.20))
                {
                    decl String:class[32] = "";
                    if (GetEntityNetClass(target,class,sizeof(class)))
                    {
                        new objects:obj;
                        if (StrEqual(class, "CObjectSentrygun", false))
                            obj = sentrygun;
                        else if (StrEqual(class, "CObjectDispenser", false))
                            obj = dispenser;
                        else if (StrEqual(class, "CObjectTeleporter", false))
                            obj = teleporter;
                        else
                            obj = unknown;

                        if (obj != unknown)
                        {
                            //Check to see if the object is still being built
                            new building = GetEntDataEnt2(target, m_BuildingOffset[obj]);
                            if (building != 1)
                            {
                                //Find the owner of the object m_hBuilder holds the client index 1 to Maxplayers
                                new builder = GetEntDataEnt2(target, m_BuilderOffset[obj]); // Get the current owner of the object.
                                new player_check=GetPlayer(builder);
                                if (player_check>-1)
                                {
                                    if (!GetImmunity(player_check,Immunity_Ultimates))
                                    {
                                        new builderTeam = GetClientTeam(builder);
                                        new team = GetClientTeam(client);
                                        if (builderTeam != team)
                                        {
                                            if (m_StolenObjectList[client] == INVALID_HANDLE)
                                                m_StolenObjectList[client] = CreateArray();

                                            if (m_StolenBuilderList[client] == INVALID_HANDLE)
                                                m_StolenBuilderList[client] = CreateArray();

                                            if (m_StolenClassList[client] == INVALID_HANDLE)
                                                m_StolenClassList[client] = CreateArray();

                                            // Keep a list of stolen object and thier original owners.
                                            PushArrayCell(m_StolenObjectList[client], target);
                                            PushArrayCell(m_StolenBuilderList[client], builder);
                                            PushArrayCell(m_StolenClassList[client], obj);

                                            SetEntDataEnt2(target, m_BuilderOffset[obj], client, true); // Change the builder to client

                                            SetVariantInt(team); //Prep the value for the call below
                                            AcceptEntityInput(target, "TeamNum", -1, -1, 0); //Change TeamNum

                                            SetVariantInt(team); //Same thing again but we are changing SetTeam
                                            AcceptEntityInput(target, "SetTeam", -1, -1, 0);

                                            EmitSoundToAll(controlWav,target);

                                            new color[4] = { 0, 0, 0, 255 };
                                            if (team == 3)
                                                color[2] = 255; // Blue
                                            else
                                                color[0] = 255; // Red

                                            TE_SetupBeamPoints(clientLoc,targetLoc,g_lightningSprite,g_haloSprite,
                                                               0, 1, 2.0, 10.0,10.0,2,50.0,color,255);
                                            TE_SendToAll();

                                            TE_SetupSmoke(targetLoc,g_smokeSprite,8.0,2);
                                            TE_SendToAll();

                                            TE_SetupGlowSprite(targetLoc,(team == 3) ? g_blueGlow : g_redGlow,
                                                               5.0,5.0,255);
                                            TE_SendToAll();

                                            new Float:splashDir[3];
                                            splashDir[0] = 0.0;
                                            splashDir[1] = 0.0;
                                            splashDir[2] = 100.0;
                                            TE_SetupEnergySplash(targetLoc, splashDir, true);

                                            decl String:object[32] = "";
                                            strcopy(object, sizeof(object), class[7]);

                                            LogToGame("[SourceCraft] %N has stolen %N's %s!\n",
                                                      client,builder,object);
                                            PrintToChat(client,"%c[SourceCraft] %c you have stolen %N's %s!",
                                                        COLOR_GREEN,COLOR_DEFAULT,builder,object);
                                            PrintToChat(builder,"%c[SourceCraft] %c %N has stolen your %s!",
                                                        COLOR_GREEN,COLOR_DEFAULT,client,object);

                                            new Float:cooldown = GetConVarFloat(cvarMindControlCooldown);
                                            if (cooldown > 0.0)
                                            {
                                                m_AllowMindControl[client]=false;
                                                CreateTimer(cooldown,AllowMindControl,client);
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
    }
}

ResetMindControledObjects(client)
{
    if (m_StolenObjectList[client] != INVALID_HANDLE)
    {
        new size = GetArraySize(m_StolenObjectList[client]);
        for (new index = 0; index < size; index++)
        {
            new target = GetArrayCell(m_StolenObjectList[client], index);
            if (IsValidEntity(target))
            {
                decl String:class[32] = "";
                if (GetEntityNetClass(target,class,sizeof(class)))
                {
                    new objects:obj2;
                    if (StrEqual(class, "CObjectSentrygun", false))
                        obj2 = sentrygun;
                    else if (StrEqual(class, "CObjectDispenser", false))
                        obj2 = dispenser;
                    else if (StrEqual(class, "CObjectTeleporter", false))
                        obj2 = teleporter;
                    else
                        obj2 = unknown;

                    // Is the object still what we stole?
                    new objects:obj = objects:GetArrayCell(m_StolenClassList[client], index);
                    if (obj == obj2)
                    {
                        // Do we still own it?
                        if (GetEntDataEnt2(target, m_BuilderOffset[obj]) == client)
                        {
                            // Is the original builser still around?
                            new builder = GetArrayCell(m_StolenBuilderList[client], index);
                            if (IsClientInGame(builder) && TF_GetClass(builder) == TF2_ENG)
                            {
                                // Give it back.
                                new team = GetClientTeam(builder);
                                SetEntDataEnt2(target, m_BuilderOffset[obj], builder, true); // Change the builder back

                                SetVariantInt(team); //Prep the value for the call below
                                AcceptEntityInput(target, "TeamNum", -1, -1, 0); //Change TeamNum

                                SetVariantInt(team); //Same thing again but we are changing SetTeam
                                AcceptEntityInput(target, "SetTeam", -1, -1, 0);
                            }
                            else
                            {
                                // Zap it.
                                //SetEntityHealth(target, 0); // Kill the object.
                                RemoveEdict(target); // Remove the object.
                            }
                        }
                    }
                }
            }
        }
        ClearArray(m_StolenObjectList[client]);
        ClearArray(m_StolenBuilderList[client]);
        ClearArray(m_StolenClassList[client]);
    }
}


public Action:AllowMindControl(Handle:timer,any:index)
{
    m_AllowMindControl[index]=true;
    EmitSoundToClient(index, rechargeWav);
    PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cMind Control%c is now available again!",
                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
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
                new player=GetPlayer(client);
                if(player>=0 && GetRace(player) == raceID)
                {
                    new Float:cloaking_range;
                    new skill_cloaking=GetSkillLevel(player,raceID,1);
                    if (skill_cloaking)
                    {
                        switch(skill_cloaking)
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
                    new skill_detecting=GetSkillLevel(player,raceID,2);
                    if (skill_detecting)
                    {
                        switch(skill_detecting)
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

                    new cloaked_count      = 0;
                    new cloaked_visibility = 0;
                    new Float:clientLoc[3];
                    GetClientAbsOrigin(client, clientLoc);
                    for (new index=1;index<=maxplayers;index++)
                    {
                        if (index != client && IsClientInGame(index))
                        {
                            if (IsPlayerAlive(index))
                            {
                                new player_check=GetPlayer(index);
                                if (player_check>-1)
                                {
                                    if (GetClientTeam(index) == GetClientTeam(client))
                                    {
                                        new check_player = GetPlayer(index);
                                        if (check_player>-1)
                                        {
                                            if (GetRace(check_player) == raceID &&
                                                GetSkillLevel(check_player,raceID,1) > 0)
                                            {
                                                continue; // Don't cloak other arbiters!
                                            }
                                        }

                                        new bool:cloak = (cloaked_visibility < 255 &&
                                                          IsInRange(client,index,cloaking_range));
                                        if (cloak)
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            cloak = TraceTarget(client, index, clientLoc, indexLoc);
                                            if (cloak)
                                            {
                                                cloak = (++cloaked_count < skill_cloaking);
                                                if (cloak)
                                                {
                                                    cloaked_count = 0;
                                                    cloaked_visibility += 51;
                                                    cloak = (cloaked_visibility < 255);
                                                }
                                            }
                                        }

                                        if (cloak)
                                        {
                                            SetMinVisibility(player_check, cloaked_visibility,0.5,0.0);
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
                                            SetMinVisibility(player_check, 255);
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
                                        if (detect)
                                        {
                                            SetOverrideVisible(player_check, 255);
                                            if (TF_GetClass(index) == TF2_SPY)
                                            {
                                                // Set the disguise(8) and cloak(16) bits to 0.
                                                new playerCond = GetEntData(index,m_OffsetPlayerCond);
                                                SetEntData(index,m_OffsetPlayerCond,playerCond & (~24));

                                                new Float:cloakMeter = GetEntDataFloat(index,m_OffsetCloakMeter);
                                                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                                {
                                                    SetEntDataFloat(index,m_OffsetCloakMeter, 0.0);
                                                }

                                                new disguiseTeam = GetEntData(index,m_OffsetDisguiseTeam);
                                                if (disguiseTeam != 0)
                                                {
                                                    SetEntData(index,m_OffsetDisguiseTeam, 0);
                                                    SetEntData(index,m_OffsetDisguiseClass, 0);
                                                    SetEntData(index,m_OffsetDisguiseHealth, 0);
                                                }
                                            }
                                            m_Detected[client][index] = true;
                                        }
                                        else if (m_Detected[client][index])
                                        {
                                            SetOverrideVisible(player_check, -1);
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

ResetCloakingAndDetector(client)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        new player = GetPlayer(index);
        if (player > -1)
        {
            if (m_Cloaked[client][index])
            {
                SetMinVisibility(player, 255);
                m_Cloaked[client][index] = false;
            }

            if (m_Detected[client][index])
            {
                SetOverrideVisible(player, -1);
                m_Detected[client][index] = false;
            }
        }
    }
}
