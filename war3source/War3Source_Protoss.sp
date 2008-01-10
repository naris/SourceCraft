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
                           "Explode upon contact with enimies, causing increased damage.",
                           "Arbiter Reality-Warping Field",
                           "Cloaks all friendly units within range",
                           "Observer Sensors",
                           "Reveals enemy invisible units within range",
                           "Dark Archon Mind Control",
                           "Allows you to control an object from the opposite team.");

    m_BuilderOffset = FindSendPropOffs("CObjectSentrygun","m_hBuilder");
    if(m_BuilderOffset == -1)
        SetFailState("[War3Source] Error finding Builder offset.");

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
            Protoss_MindControl(client);
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
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            new war3player=War3_GetWar3Player(client);
            if(war3player>=0 && War3_GetRace(war3player) == raceID)
            {
                new Float:cloaking_range=0.0;
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

                new Float:detecting_range=0.0;
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

                new Float:clientLoc[3];
                GetClientAbsOrigin(client, clientLoc);
                for (new index=1;index<=maxplayers;index++)
                {
                    if (index != client && IsClientConnected(index))
                    {
                        if (IsPlayerAlive(index))
                        {
                            new war3player_check=War3_GetWar3Player(index);
                            if (war3player_check>-1)
                            {
                                if (GetClientTeam(index) == GetClientTeam(client))
                                {
                                    if (IsInRange(client,index,cloaking_range))
                                    {
                                        new Float:indexLoc[3];
                                        GetClientAbsOrigin(index, indexLoc);
                                        if (TraceTarget(client, index, clientLoc, indexLoc))
                                        {
                                            War3_SetMinVisibility(war3player_check, 0);
                                            m_Cloaked[client][index] = true;
                                        }
                                        else if (m_Cloaked[client][index])
                                        {
                                            War3_SetMinVisibility(war3player_check, -1);
                                            m_Cloaked[client][index] = false;
                                        }
                                    }
                                    else if (m_Cloaked[client][index])
                                    {
                                        War3_SetMinVisibility(war3player_check, -1);
                                        m_Cloaked[client][index] = false;
                                    }
                                }
                                else
                                {
                                    if (IsInRange(client,index,detecting_range))
                                    {
                                        new Float:indexLoc[3];
                                        GetClientAbsOrigin(index, indexLoc);
                                        if (TraceTarget(client, index, clientLoc, indexLoc))
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
                War3_SetMinVisibility(war3player, -1);
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

public Protoss_MindControl(client)
{
    new victim = 0;
    new target = GetClientAimTarget(client);
    if (target >= 0)
    {
        decl String:class[64] = "";
        if (GetEdictClassname(target, class, sizeof(class)))
        {
            if (StrEqual(class, "obj_sentrygun", false) ||
                StrEqual(class, "obj_dispenser", false) ||
                StrEqual(class, "obj_teleporter_entrance", false) ||
                StrEqual(class, "obj_teleporter_exit", false))
            {
                //Find the owner of the sentry gun m_hBuilder holds the client index 1 to Maxplayers
                victim = GetEntDataEnt(target, m_BuilderOffset); // Get the current owner of the object.
                SetEntDataEnt(target, m_BuilderOffset, client, true); // Change the builder to client

                new team = GetClientTeam(client);

                SetVariantInt(team); //Prep the value for the call below
                AcceptEntityInput(target, "TeamNum", -1, -1, 0); //Change TeamNum

                SetVariantInt(team); //Same thing again but we are changing SetTeam
                AcceptEntityInput(target, "SetTeam", -1, -1, 0);

                EmitSoundToAll(controlWav,target);
            }
        }
    }
    return victim;
}

public Protoss_Scarab(Handle:event, index, war3player, victimIndex)
{
    new skill_cg = War3_GetSkillLevel(war3player,raceID,1);
    if (skill_cg > 0)
    {
        new Float:percent;
        switch(skill_cg)
        {
            case 1:
                percent=0.24;
            case 2:
                percent=0.57;
            case 3:
                percent=0.83;
            case 4:
                percent=1.00;
        }

        new damage=War3_GetDamage(event, victimIndex);
        new health_take=RoundFloat(float(damage)*percent);
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

/*
public bool:Protoss_Shields(Handle:event, victimIndex, victimWar3player)
{
    new skill_level_armor = War3_GetSkillLevel(victimWar3player,raceID,0);
    if (skill_level_armor)
    {
        new Float:from_percent,Float:to_percent;
        switch(skill_level_armor)
        {
            case 1:
            {
                from_percent=0.0;
                to_percent=0.10;
            }
            case 2:
            {
                from_percent=0.0;
                to_percent=0.30;
            }
            case 3:
            {
                from_percent=0.10;
                to_percent=0.60;
            }
            case 4:
            {
                from_percent=0.20;
                to_percent=0.80;
            }
        }
        new damage=War3_GetDamage(event, victimIndex);
        new amount=RoundFloat(float(damage)*GetRandomFloat(from_percent,to_percent));
        if (amount > 0)
        {
            new newhp=GetClientHealth(victimIndex)+amount;
            new maxhp=GetMaxHealth(victimIndex);
            if (newhp > maxhp)
                newhp = maxhp;

            SetHealth(victimIndex,newhp);

            decl String:victimName[64];
            GetClientName(victimIndex,victimName,63);

            PrintToChat(victimIndex,"%c[War3Source] %s %cyour shields absorbed %d hp",
                        COLOR_GREEN,victimName,COLOR_DEFAULT,amount);
        }
        return true;
    }
    return false;
}
*/
