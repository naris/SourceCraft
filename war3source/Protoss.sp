/**
 * vim: set ai et ts=4 sw=4 :
 * File: Protoss.sp
 * Description: The Protoss race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "SourceCraft/SourceCraft"

#include "SourceCraft/util"
#include "SourceCraft/range"
#include "SourceCraft/trace"
#include "SourceCraft/health"
#include "SourceCraft/log"

new raceID; // The ID we are assigned to

new m_Cloaked[MAXPLAYERS+1][MAXPLAYERS+1];
new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

enum objects { unknown, sentrygun, dispenser, teleporter };
new m_BuilderOffset[objects];
new m_BuildingOffset[objects];

new g_redGlow;
new g_blueGlow;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new explosionModel;

new String:explodeWav[] = "war3/PSaHit00.wav";
new String:controlWav[] = "war3/pteSum00.wav";
new String:unCloakWav[] = "war3/PabCag00.wav";
new String:cloakWav[] = "war3/pabRdy00.wav";

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

    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_hurt",PlayerHurtEvent);

    //CreateTimer(2.0,CloakingAndDetector,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID=CreateRace("Protoss", "protoss",
                      "You are now part of the Protoss.",
                      "You will be part of the Protoss when you die or respawn.",
                      "Reaver Scarabs",
                      "Explode upon contact with enemies, causing increased damage.",
                      "Arbiter Reality-Warping Field",
                      "Cloaks all friendly units within range",
                      "Observer Sensors",
                      "Reveals enemy invisible units within range",
                      "Dark Archon Mind Control",
                      "Allows you to control an object from the opposite team.",
                      "16");

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

    SetupSound(explodeWav);
    SetupSound(controlWav);
    SetupSound(unCloakWav);
    SetupSound(cloakWav);
}

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
        ResetCloakingAndDetector(client);
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            Protoss_MindControl(client,player);
    }
}

// Events
public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);

    if (client)
        ResetCloakingAndDetector(client);
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid=GetEventInt(event,"userid");
    if (victimUserid)
    {
        new victimIndex      = GetClientOfUserId(victimUserid);
        new victimplayer = GetPlayer(victimIndex);
        if (victimplayer != -1)
        {
            new attackerUserid = GetEventInt(event,"attacker");
            if (attackerUserid && victimUserid != attackerUserid)
            {
                new attackerIndex      = GetClientOfUserId(attackerUserid);
                new attackerplayer = GetPlayer(attackerIndex);
                if (attackerplayer != -1)
                {
                    if (GetRace(attackerplayer) == raceID)
                        Protoss_Scarab(event, attackerIndex, attackerplayer, victimIndex);
                }
            }

            new assisterUserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisterUserid && victimUserid != assisterUserid)
            {
                new assisterIndex      = GetClientOfUserId(assisterUserid);
                new assisterplayer = GetPlayer(assisterIndex);
                if (assisterplayer != -1)
                {
                    if (GetRace(assisterplayer) == raceID)
                        Protoss_Scarab(event, assisterIndex, assisterplayer, victimIndex);
                }
            }
        }
    }
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
                                    decl String:clientName[64];
                                    GetClientName(client,clientName,63);

                                    decl String:name[64];
                                    GetClientName(index,name,63);

                                    if (GetClientTeam(index) == GetClientTeam(client))
                                    {
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
                                            SetMinVisibility(player_check, cloaked_visibility);
                                            m_Cloaked[client][index] = true;

                                            if (!m_Cloaked[client][index])
                                            {
                                                EmitSoundToClient(client, cloakWav);
                                                LogMessage("[SourceCraft] %s has been cloaked by %s!\n", name,clientName);
                                                PrintToChat(index,"%c[SourceCraft] %s %c has been cloaked by %s!",
                                                        COLOR_GREEN,name,COLOR_DEFAULT,clientName);
                                            }
                                        }
                                        else if (m_Cloaked[client][index])
                                        {
                                            SetMinVisibility(player_check, 255);
                                            m_Cloaked[client][index] = false;

                                            EmitSoundToClient(client, unCloakWav);
                                            LogMessage("[SourceCraft] %s has been uncloaked!\n", name);
                                            PrintToChat(index,"%c[SourceCraft] %s %c has been uncloaked!",
                                                        COLOR_GREEN,name,COLOR_DEFAULT);
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

public ResetCloakingAndDetector(client)
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

public Protoss_MindControl(client,player)
{
    new ult_level=GetSkillLevel(player,raceID,3);
    if(ult_level)
    {
        new Float:range, percent;
        switch(ult_level)
        {
            case 1:
            {
                range=50.0;
                percent=30;
            }
            case 2:
            {
                range=125.0;
                percent=50;
            }
            case 3:
            {
                range=250.0;
                percent=70;
            }
            case 4:
            {
                range=450.0;
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
                            new building = GetEntDataEnt(target, m_BuildingOffset[obj]);
                            if (building != 1)
                            {
                                //Find the owner of the object m_hBuilder holds the client index 1 to Maxplayers
                                new builder = GetEntDataEnt(target, m_BuilderOffset[obj]); // Get the current owner of the object.
                                new builderTeam = GetClientTeam(builder);
                                new team = GetClientTeam(client);
                                if (builderTeam != team)
                                {
                                    SetEntDataEnt(target, m_BuilderOffset[obj], client, true); // Change the builder to client

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

                                    TE_SetupGlowSprite(targetLoc,(team == 3) ? g_blueGlow : g_redGlow,5.0,5.0,255);
                                    TE_SendToAll();

                                    new Float:splashDir[3];
                                    splashDir[0] = 0.0;
                                    splashDir[1] = 0.0;
                                    splashDir[2] = 100.0;
                                    TE_SetupEnergySplash(targetLoc, splashDir, true);

                                    decl String:clientName[64];
                                    GetClientName(client,clientName,63);

                                    decl String:builderName[64];
                                    GetClientName(builder,builderName,63);

                                    decl String:object[32] = "";
                                    strcopy(object, sizeof(object), class[7]);
                                    LogMessage("[SourceCraft] %s has stolen %s's %s!\n", clientName,builderName,object);
                                    PrintToChat(client,"%c[SourceCraft] %c you have stolen %s's %s!",
                                                COLOR_GREEN,COLOR_DEFAULT,builderName,object);
                                    PrintToChat(builder,"%c[SourceCraft] %c %s has stolen your %s!",
                                                COLOR_GREEN,COLOR_DEFAULT,clientName,object);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

public Protoss_Scarab(Handle:event, index, player, victimIndex)
{
    new skill_cg = GetSkillLevel(player,raceID,1);
    if (skill_cg > 0)
    {
        new Float:percent, chance;
        switch(skill_cg)
        {
            case 1:
            {
                chance=20;
                percent=0.24;
            }
            case 2:
            {
                chance=40;
                percent=0.57;
            }
            case 3:
            {
                chance=60;
                percent=0.83;
            }
            case 4:
            {
                chance=90;
                percent=1.00;
            }
        }

        if (GetRandomInt(1,100) <= chance)
        {
            new damage=GetDamage(event, victimIndex);
            new health_take=RoundFloat(float(damage)*percent);
            if (health_take > 0)
            {
                new new_health=GetClientHealth(victimIndex)-health_take;
                if (new_health <= 0)
                {
                    new_health=0;
                    LogKill(index, victimIndex, "scarab", "Reaver Scarab", health_take);
                }
                else
                    LogDamage(index, victimIndex, "scarab", "Reaver Scarab", health_take);

                SetHealth(victimIndex,new_health);

                new Float:Origin[3];
                GetClientAbsOrigin(victimIndex, Origin);
                Origin[2] += 5;

                TE_SetupExplosion(Origin,explosionModel,10.0,30,0,10,20);
                TE_SendToAll();
                EmitSoundToAll(explodeWav,victimIndex);
            }
        }
    }
}
