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
#include "War3Source/health"
#include "War3Source/damage"
#include "War3Source/weapons"

// War3Source stuff
new raceID; // The ID we are assigned to

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_GrabTime[MAXPLAYERS+1];
new m_GrabRechargeTime[MAXPLAYERS+1];

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
                           "Regenerates Health.",
                           "Healing Aura",
                           "Regenerates Health fo all teammates in range.",
                           "Tentacles",
                           "Reach out and grab an opponent.");

    /*
    ControlHookGrabRope(true);
    */
}

public OnMapStart()
{
    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

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

public OnGameFrame()
{
    SaveAllHealth();
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
                new skill_regeneration=War3_GetSkillLevel(war3player,raceID,2);
                if (skill_regeneration)
                {
                    new newhp=GetClientHealth(client)+skill_regeneration;
                    new maxhp=(GameType == tf2) ? GetMaxHealth(client) : 100;
                    if(newhp<=maxhp)
                        SetHealth(client,newhp);
                }

                new skill_healing_aura=War3_GetSkillLevel(war3player,raceID,3);
                if (skill_healing_aura)
                {
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
                                    new color[4] = { 0, 0, 255, 255 };
                                    TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                            0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                    TE_SendToAll();

                                    new newhp=GetClientHealth(index)+skill_healing_aura;
                                    new maxhp=(GameType == tf2) ? GetMaxHealth(index) : 100;
                                    if(newhp<=maxhp)
                                        SetHealth(index,newhp);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
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

public OnSkillLevelChanged(client,war3player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && newskilllevel > 0 && War3_GetRace(war3player) == raceID && IsPlayerAlive(client))
    {
        if (skill==0)
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
                new skill_tentacles=War3_GetSkillLevel(war3player,race,0);
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
            new victimrace = War3_GetRace(victimWar3player);
            if (victimrace == raceID)
                Zerg_AdrenalGlands(event, victimIndex, war3player);
        }
    }
}

public Zerg_AdrenalGlands(Handle:event, victimindex, war3player)
{
    new skill_adrenal_glands=War3_GetSkillLevel(war3player,raceID,2);
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

                new damage=GetDamage(event, victimindex, index, 10, 20);
                new amount=RoundFloat(float(damage)*percent);
                new newhp=GetClientHealth(victimindex)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(index, victimindex, "adrenal_glands", "Adrenal Glands", amount);
                }
                else
                    LogDamage(index, victimindex, "adrenal_glands", "Adrenal Glands", amount);

                SetHealth(victimindex,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victimindex, Origin);
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
        switch(skilllevel)
        {
            case 1:
            {
                m_GrabTime[client]=20;
                m_GrabRechargeTime[client]=45;
            }
            case 2:
            {
                m_GrabTime[client]=35;
                mGrabRechargeTime[client]=30;
            }
            case 3:
            {
                m_GrabTime[client]=50;
                m_GrabRechargeTime[client]=20;
            }
            case 4:
            {
                m_GrabTime[client]=60;
                m_GrabRechargeTime[client]=10;
            }
        }
        GiveGrab(client);
    }
}
