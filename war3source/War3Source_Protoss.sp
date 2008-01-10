/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_Protoss.sp
 * Description: The Protoss race for War3Source.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/range"
#include "War3Source/trace"
#include "War3Source/health"
#include "War3Source/log"

// War3Source stuff
new raceID; // The ID we are assigned to

new m_Cloaked[MAXPLAYERS+1][MAXPLAYERS+1];
new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

new m_BuilderOffset;

new g_redGlow;
new g_purpleGlow;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new explosionModel;

new String:explodeWav[] = "war3/PSaHit00.wav";
new String:controlWav[] = "war3/pteSum00.wav";

public Plugin:myinfo = 
{
    name = "War3Source Race - Protoss",
    author = "-=|JFH|=-Naris",
    description = "The Protoss race for War3Source.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_hurt",PlayerHurtEvent);

    CreateTimer(2.0,CloakingAndDetector,INVALID_HANDLE,TIMER_REPEAT);
}

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Protoss",
                           "protoss",
                           "You are now part of the Protoss.",
                           "You will be part of the Protoss when you die or respawn.",
                           "Reaver Scarabs",
                           "Explode upon contact with enemies, causing increased damage.",
                           "Arbiter Reality-Warping Field",
                           "Cloaks all friendly units within range",
                           "Observer Sensors",
                           "Reveals enemy invisible units within range",
                           "Dark Archon Mind Control",
                           "Allows you to control an object from the opposite team.");

    m_BuilderOffset = FindSendPropOffs("CObjectSentrygun","m_hBuilder");
    if(m_BuilderOffset == -1)
        SetFailState("[War3Source] Error finding Builder offset.");
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_purpleGlow = SetupModel("materials/sprites/purpleglow1.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find purpleglow Model");

    g_redGlow = SetupModel("materials/sprites/redglow1.vmt");
    if (g_redGlow == -1)
        SetFailState("Couldn't find redglow Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    if (GameType == tf2)
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt");
    else
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");

    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(explodeWav);
    SetupSound(controlWav);
}

public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client);
}

public OnRaceSelected(client,war3player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
        ResetCloakingAndDetector(client);
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            Protoss_MindControl(client,war3player);
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
        new victimWar3player = War3_GetWar3Player(victimIndex);
        if (victimWar3player != -1)
        {
            /*
            new victimrace = War3_GetRace(victimWar3player);
            if (victimrace == raceID)
                Protoss_Shields(event, victimIndex, victimWar3player);
            */

            new attackerUserid = GetEventInt(event,"attacker");
            if (attackerUserid && victimUserid != attackerUserid)
            {
                new attackerIndex      = GetClientOfUserId(attackerUserid);
                new attackerWar3player = War3_GetWar3Player(attackerIndex);
                if (attackerWar3player != -1)
                {
                    if (War3_GetRace(attackerWar3player) == raceID)
                        Protoss_Scarab(event, attackerIndex, attackerWar3player, victimIndex);
                }
            }

            new assisterUserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisterUserid && victimUserid != assisterUserid)
            {
                new assisterIndex      = GetClientOfUserId(assisterUserid);
                new assisterWar3player = War3_GetWar3Player(assisterIndex);
                if (assisterWar3player != -1)
                {
                    if (War3_GetRace(assisterWar3player) == raceID)
                        Protoss_Scarab(event, assisterIndex, assisterWar3player, victimIndex);
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
                new war3player=War3_GetWar3Player(client);
                if(war3player>=0 && War3_GetRace(war3player) == raceID)
                {
                    new Float:cloaking_range;
                    new skill_cloaking=War3_GetSkillLevel(war3player,raceID,1);
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
                    new skill_detecting=War3_GetSkillLevel(war3player,raceID,2);
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
                                new war3player_check=War3_GetWar3Player(index);
                                if (war3player_check>-1)
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
                                            War3_SetMinVisibility(war3player_check, cloaked_visibility);
                                            m_Cloaked[client][index] = true;

                                            LogMessage("[War3Source] %s has been cloaked by %s!\n", name,clientName);
                                            PrintToChat(index,"%c[War3Source] %s %c has been cloaked by %s!",
                                                        COLOR_GREEN,name,clientName,COLOR_DEFAULT);
                                        }
                                        else if (m_Cloaked[client][index])
                                        {
                                            War3_SetMinVisibility(war3player_check, 255);
                                            m_Cloaked[client][index] = false;

                                            LogMessage("[War3Source] %s has been uncloaked!\n", name);
                                            PrintToChat(index,"%c[War3Source] %s %c has been uncloaked!",
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
                                            War3_SetOverrideVisible(war3player_check, 255);
                                            m_Detected[client][index] = true;
                                        }
                                        else if (m_Detected[client][index])
                                        {
                                            War3_SetOverrideVisible(war3player_check, -1);
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
        new war3player = War3_GetWar3Player(index);
        if (war3player > -1)
        {
            if (m_Cloaked[client][index])
            {
                War3_SetMinVisibility(war3player, 255);
                m_Cloaked[client][index] = false;
            }

            if (m_Detected[client][index])
            {
                War3_SetOverrideVisible(war3player, -1);
                m_Detected[client][index] = false;
            }
        }
    }
}

public Protoss_MindControl(client,war3player)
{
    new ult_level=War3_GetSkillLevel(war3player,raceID,3);
    if(ult_level)
    {
        new Float:range, percent;
        switch(ult_level)
        {
            case 1:
            {
                range=300.0;
                percent=30;
            }
            case 2:
            {
                range=450.0;
                percent=50;
            }
            case 3:
            {
                range=650.0;
                percent=70;
            }
            case 4:
            {
                range=800.0;
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

            if (GetRandomInt(1,100)<=percent && IsPointInRange(clientLoc,targetLoc,range))
            {
                decl String:class[64] = "";
                if (GetEntityNetClass(target,class,sizeof(class)))
                {
                    if (StrEqual(class, "CObjectSentrygun", false) ||
                            StrEqual(class, "CObjectDispenser", false) ||
                            StrEqual(class, "CObjectTeleporter", false))
                    {
                        //Find the owner of the object m_hBuilder holds the client index 1 to Maxplayers
                        new builder = GetEntDataEnt(target, m_BuilderOffset); // Get the current owner of the object.
                        new builderTeam = GetClientTeam(builder);
                        new team = GetClientTeam(client);
                        if (builderTeam != team)
                        {
                            SetEntDataEnt(target, m_BuilderOffset, client, true); // Change the builder to client

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
                                               0, 1, 10.0, 10.0,10.0,2,50.0,color,255);
                            TE_SendToAll();

                            TE_SetupSmoke(targetLoc,g_smokeSprite,10.0,1);
                            TE_SendToAll();

                            TE_SetupGlowSprite(targetLoc,(team == 3) ? g_purpleGlow : g_redGlow,0.7,10.0,200);
                            TE_SendToAll();
                        }
                    }
                }
            }
        }
    }
}

public Protoss_Scarab(Handle:event, index, war3player, victimIndex)
{
    new skill_cg = War3_GetSkillLevel(war3player,raceID,1);
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
            new damage=War3_GetDamage(event, victimIndex);
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
