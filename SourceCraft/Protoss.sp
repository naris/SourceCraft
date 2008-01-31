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

#include "SourceCraft/SourceCraft"

#include "SourceCraft/util"
#include "SourceCraft/range"
#include "SourceCraft/trace"
#include "SourceCraft/health"
#include "SourceCraft/log"

new raceID; // The ID we are assigned to

new Handle:cvarMindControlCooldown = INVALID_HANDLE;
new Handle:cvarMindControlEnable = INVALID_HANDLE;
new Handle:cvarReaverScarabEnable = INVALID_HANDLE;

new m_Cloaked[MAXPLAYERS+1][MAXPLAYERS+1];
new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];
new bool:m_AllowMindControl[MAXPLAYERS+1];
new Float:gReaverScarabTime[MAXPLAYERS+1];

enum objects { unknown, sentrygun, dispenser, teleporter };
new m_BuilderOffset[objects];
new m_BuildingOffset[objects];

new g_redGlow;
new g_blueGlow;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new explosionModel;

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
    cvarMindControlEnable=CreateConVar("sc_mindcontrolenable","0");
    cvarReaverScarabEnable=CreateConVar("sc_reaverscarabenable","1");

    HookEvent("player_spawn",PlayerSpawnEvent);

    CreateTimer(2.0,CloakingAndDetector,INVALID_HANDLE,TIMER_REPEAT);
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
    m_AllowMindControl[client]=true;
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
        ResetCloakingAndDetector(client);
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
        m_AllowMindControl[index]=true;
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
        if (ReaverScarab(damage, victim_index, attacker_index, attacker_player))
            changed = true;
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        if (ReaverScarab(damage, victim_index, assister_index, assister_player))
            changed = true;
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
        ResetCloakingAndDetector(victim_index);
}

public bool:ReaverScarab(damage, victim_index, index, player)
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
                percent=0.37;
            }
            case 3:
            {
                chance=60;
                percent=0.53;
            }
            case 4:
            {
                chance=90;
                percent=0.73;
            }
        }

        if (GetRandomInt(1,100) <= chance &&
            GetGameTime() - gReaverScarabTime[index] > 1.000)
        {
            if (!GetConVarBool(cvarReaverScarabEnable))
            {
                PrintToChat(index,"%c[SourceCraft] %c Sorry, Reaver Scarab has been disabled for testing purposes!",
                            COLOR_GREEN,COLOR_DEFAULT);
                return false;
            }

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

                SetHealth(victim_index,new_health);

                if (GetGameTime() - gReaverScarabTime[index] >= 10.0)
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

public MindControl(client,player)
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

public Action:AllowMindControl(Handle:timer,any:index)
{
    m_AllowMindControl[index]=true;
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
                                                LogToGame("[SourceCraft] %s has been cloaked by %s!\n", name,clientName);
                                                PrintToChat(index,"%c[SourceCraft] %s %c has been cloaked by %s!",
                                                            COLOR_GREEN,name,COLOR_DEFAULT,clientName);
                                            }
                                        }
                                        else if (m_Cloaked[client][index])
                                        {
                                            SetMinVisibility(player_check, 255);
                                            m_Cloaked[client][index] = false;

                                            EmitSoundToClient(client, unCloakWav);
                                            LogToGame("[SourceCraft] %s has been uncloaked!\n", name);
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
