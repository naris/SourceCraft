/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_TerranConfederacy .sp
 * Description: The Terran Confederacy race for War3Source.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "hgrsource.inc"

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/range"
#include "War3Source/trace"
#include "War3Source/health"
#include "War3Source/weapons"
#include "War3Source/log"

// War3Source stuff
new raceID; // The ID we are assigned to

new g_haloSprite;
new g_lightningSprite;

public Plugin:myinfo = 
{
    name = "War3Source Race - Terran Confederacy",
    author = "-=|JFH|=-Naris",
    description = "The Zerg race for War3Source.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_hurt",PlayerHurtEvent);

    CreateTimer(3.0,Regeneration,INVALID_HANDLE,TIMER_REPEAT);
}

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Zerg",
                           "zerg",
                           "You are now part of the Zerg.",
                           "You will be part of the Zerg when you die or respawn.",
                           "Adrenal Glands",
                           "Increases Melee Attack Damage",
                           "Regeneration",
                           "Regenerates your Health.",
                           "Healing Aura",
                           "Regenerates Health of all teammates in range (It does NOT heal you).",
                           "Tentacles",
                           "Reach out and grab an opponent.");

    ControlHookGrabRope(true);
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");
}


public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client);
}

public OnRaceSelected(client,war3player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
        TakeGrab(client);
}

public Action:Regeneration(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            new war3player=War3_GetWar3Player(client);
            if(war3player>=0 && War3_GetRace(war3player) == raceID)
            {
                new skill_regeneration=War3_GetSkillLevel(war3player,raceID,1);
                if (skill_regeneration)
                {
                    new newhp=GetClientHealth(client)+skill_regeneration;
                    new maxhp=(GameType == tf2) ? GetMaxHealth(client) : 100;
                    if(newhp<=maxhp)
                        SetHealth(client,newhp);
                }

                new skill_healing_aura=War3_GetSkillLevel(war3player,raceID,2);
                if (skill_healing_aura)
                {
                    new num=skill_healing_aura*2;
                    new Float:range=1.0;
                    switch(skill_healing_aura)
                    {
                        case 1:
                            range=300.0;
                        case 2:
                            range=450.0;
                        case 3:
                            range=650.0;
                        case 4:
                            range=800.0;
                    }
                    new count=0;
                    new Float:clientLoc[3];
                    GetClientAbsOrigin(client, clientLoc);
                    for (new index=1;index<=maxplayers;index++)
                    {
                        if (index != client && IsClientConnected(index) && IsPlayerAlive(index) &&
                            GetClientTeam(index) == GetClientTeam(client))
                        {
                            new war3player_check=War3_GetWar3Player(index);
                            if (war3player_check>-1)
                            {
                                if (IsInRange(client,index,range))
                                {
                                    new Float:indexLoc[3];
                                    GetClientAbsOrigin(index, indexLoc);
                                    if (TraceTarget(client, index, clientLoc, indexLoc))
                                    {
                                        new color[4] = { 0, 0, 255, 255 };
                                        TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                          0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                        TE_SendToAll();

                                        new newhp=GetClientHealth(index)+skill_healing_aura;
                                        new maxhp=(GameType == tf2) ? GetMaxHealth(index) : 100;
                                        if(newhp<=maxhp)
                                            SetHealth(index,newhp);

                                        if (++count > num)
                                            break;
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

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            Grab(client);
        else
            Drop(client);
    }
}

public Action:OnGrabbed(client, target)
{
    if (target != client && IsClientConnected(target) && IsPlayerAlive(target) &&
        GetClientTeam(target) != GetClientTeam(client))
    {
        new war3player_check=War3_GetWar3Player(target);
        if (war3player_check>-1)
        {
            if (!War3_GetImmunity(war3player_check,Immunity_Ultimates))
                return Plugin_Continue;
        }
    }
    return Plugin_Stop;
}

public OnSkillLevelChanged(client,war3player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && newskilllevel > 0 && War3_GetRace(war3player) == raceID && IsPlayerAlive(client))
    {
        if (skill==3)
            Zerg_Tentacles(client, war3player, newskilllevel);
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        SetupMaxHealth(client);

        new war3player=War3_GetWar3Player(client);
        if (war3player>-1)
        {
            new race = War3_GetRace(war3player);
            if (race == raceID)
            {
                new skill_tentacles=War3_GetSkillLevel(war3player,race,3);
                if (skill_tentacles)
                    Zerg_Tentacles(client, war3player, skill_tentacles);
            }
        }
    }
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
            new attackerUserid = GetEventInt(event,"attacker");
            if (attackerUserid && victimUserid != attackerUserid)
            {
                new attackerIndex      = GetClientOfUserId(attackerUserid);
                new attackerWar3player = War3_GetWar3Player(attackerIndex);
                if (attackerWar3player != -1)
                {
                    if (War3_GetRace(attackerWar3player) == raceID)
                        Zerg_AdrenalGlands(event, attackerIndex, attackerWar3player, victimIndex);
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
                        Zerg_AdrenalGlands(event, assisterIndex, assisterWar3player, victimIndex);
                }
            }
        }
    }
}


public Zerg_AdrenalGlands(Handle:event, index, war3player, victimIndex)
{
    new skill_adrenal_glands=War3_GetSkillLevel(war3player,raceID,1);
    if (skill_adrenal_glands)
    {
        decl String:wepName[128];
        if (GetEventString(event,"weapon", wepName, sizeof(wepName))>0)
        {
            if (IsDamageFromMelee(wepName) && GetRandomInt(1,100) <= 75)
            {
                new Float:percent;
                switch(skill_adrenal_glands)
                {
                    case 1:
                        percent=0.20;
                    case 2:
                        percent=0.55;
                    case 3:
                        percent=0.75;
                    case 4:
                        percent=1.00;
                }

                new damage=War3_GetDamage(event, victimIndex);
                new amount=RoundFloat(float(damage)*percent);
                new newhp=GetClientHealth(victimIndex)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(index, victimIndex, "adrenal_glands", "Adrenal Glands", amount);
                }
                else
                    LogDamage(index, victimIndex, "adrenal_glands", "Adrenal Glands", amount);

                SetHealth(victimIndex,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victimIndex, Origin);
                Origin[2] += 5;

                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendToAll();
                return amount;
            }
        }
    }
    return 0;
}

public Zerg_Tentacles(client, war3player, skilllevel)
{
    if (skilllevel)
    {
        new grabTime;
        switch(skilllevel)
        {
            case 1:
                grabTime=5;
            case 2:
                grabTime=15;
            case 3:
                grabTime=30;
            case 4:
                grabTime=45;
        }
        GiveGrab(client,grabTime);
    }
}
