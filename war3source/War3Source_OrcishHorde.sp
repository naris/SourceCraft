/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_OrcishHorde.sp
 * Description: The Orcish Horde race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/health"
#include "War3Source/authtimer"
#include "War3Source/respawn"
#include "War3Source/log"

// War3Source stuff
new raceID; // The ID we are assigned to

new bool:m_HasRespawned[MAXPLAYERS+1]        = {false};
new Float:m_UseTime[MAXPLAYERS+1]            = {0.0,...};
new bool:m_AllowChainLightning[MAXPLAYERS+1] = {true,...};

new Handle:cvarChainCooldown;

new g_beamSprite;
new g_haloSprite;
new g_crystalSprite;

new String:thunderWav[] = "war3/thunder1Long.mp3"; // "ambient/weather/thunder1.wav";

public Plugin:myinfo = 
{
    name = "War3Source Race - Orcish Horde",
    author = "PimpinJuice",
    description = "The Orcish Horde race for War3Source.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarChainCooldown=CreateConVar("war3_chainlightningcooldown","30"); // Chain Lightning Cooldown, default: 30 seconds
    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("round_start",RoundStartEvent);
}

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Orcish Horde", // Full race name
                           "orc", // SQLite ID name (short name, no spaces)
                           "You are now an Orcish Horde.", // Selected Race message
                           "You will be an Orcish Horde when you die or respawn.", // Selected Race message if you are not allowed until death or respawn
                           "Acute Strike", //Skill 1 Name
                           "Gives you a 15% chance of doing\n40-240% more damage.", // Skill 1 Description
                           "Acute Grenade", // Skill 2 Name
                           "Grenades and Rockets will always do a 40-240%\nmore damage.", // Skill 2 Description
                           "Reincarnation", // Skill 3 Name
                           "Gives you a 15-80% chance of respawning\nonce.", // Skill 3 Description
                           "Chain Lightning", // Ultimate Name
                           "Discharges a bolt of lightning that jumps\non up to 4 nearby enemies 150-300 units in range,\ndealing each 32 damage.\nNOT IMPLEMENTED YET!"); // Ultimate Description

}

public OnMapStart()
{
    g_beamSprite    = SetupModel("materials/sprites/lgtning.vmt"); // "materials/sprites/laser.vmt");
    g_haloSprite    = SetupModel("materials/sprites/halo01.vmt");
    g_crystalSprite = SetupModel("materials/sprites/crystal_beam1.vmt");

    SetupSound(thunderWav);
}

public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client);
    m_AllowChainLightning[client]=true;
}

public OnRaceSelected(client,war3player,oldrace,newrace)
{
    m_AllowChainLightning[client]=true;
    m_HasRespawned[client]=false;
}

public OnGameFrame()
{
    for (new x=0;x<=MAXPLAYERS;x++)
    {
        if (!m_AllowChainLightning[x])
        {
            if (GetEngineTime() >= m_UseTime[x] + GetConVarFloat(cvarChainCooldown))
                m_AllowChainLightning[x]=true;
        }
    }
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if (pressed && m_AllowChainLightning[client] &&
        race == raceID && IsPlayerAlive(client))
    {
        new skill = War3_GetSkillLevel(war3player,race,3);
        if (skill)
        {
            OrcishHorde_ChainLightning(war3player,client,skill);
            m_AllowChainLightning[client]=false;
            m_UseTime[client]=GetEngineTime();
        }
    }
}

// Events
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
                    {
                        OrcishHorde_AcuteStrike(event, attackerIndex, attackerWar3player, victimIndex);
                        OrcishHorde_AcuteGrenade(event, attackerIndex, attackerWar3player, victimIndex);
                    }
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
                    {
                        OrcishHorde_AcuteStrike(event, assisterIndex, assisterWar3player, victimIndex);
                        OrcishHorde_AcuteGrenade(event, assisterIndex, assisterWar3player, victimIndex);
                    }
                }
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(index);
    if (war3player>-1)
    {
        new race=War3_GetRace(war3player);
        if (race==raceID&&!m_HasRespawned[index])
        {
            new skill=War3_GetSkillLevel(war3player,race,2);
            if (skill)
            {
                new percent;
                switch (skill)
                {
                    case 1:
                        percent=15;
                    case 2:
                        percent=37;
                    case 3:
                        percent=59;
                    case 4:
                        percent=80;
                }
                if (GetRandomInt(1,100)<=percent)
                {
                    AuthTimer(0.5,index,RespawnPlayerHandle);
                    m_HasRespawned[index]=true;
                }
            }
        }
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
        m_HasRespawned[x]=false;
}

public OrcishHorde_AcuteStrike(Handle:event, index, war3player, victimIndex)
{
    new skill_cs = War3_GetSkillLevel(war3player,raceID,0);
    if (skill_cs > 0)
    {
        if(GetRandomInt(1,100)<=15)
        {
            new Float:percent;
            switch(skill_cs)
            {
                case 1:
                    percent=0.4;
                case 2:
                    percent=1.067;
                case 3:
                    percent=1.733;
                case 4:
                    percent=2.4;
            }

            new damage=GetDamage(event, index, 5, 20);
            new health_take=RoundFloat(float(damage)*percent);
            new new_health=GetClientHealth(victimIndex)-health_take;
            if (new_health <= 0)
            {
                new_health=0;
                LogKill(index, victimIndex, "acute_strike", "Acute Strike", health_take);
            }
            else
                LogDamage(index, victimIndex, "acute_strike", "Acute Strike", health_take);

            SetHealth(victimIndex,new_health);

            new color[4] = { 100, 255, 55, 255 };
            TE_SetupBeamLaser(index,victimIndex,g_beamSprite,g_haloSprite,
                              0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
            TE_SendToAll();
        }
    }
}

public OrcishHorde_AcuteGrenade(Handle:event, index, war3player, victimIndex)
{
    new skill_cg = War3_GetSkillLevel(war3player,raceID,1);
    if (skill_cg > 0)
    {
        decl String:weapon[64];
        GetEventString(event,"weapon",weapon,63);
        if (!strlen(weapon))
            GetClientWeapon(index, weapon, 63);

        if (StrEqual(weapon,"hegrenade",false) ||
            StrEqual(weapon,"tf_projectile_pipe",false) ||
            StrEqual(weapon,"tf_projectile_pipe_remote",false) ||
            StrEqual(weapon,"tf_weapon_rocketlauncher",false) ||
            StrEqual(weapon,"tf_projectile_rocket",false) ||
            StrEqual(weapon,"weapon_frag_us",false) ||
            StrEqual(weapon,"weapon_frag_ger",false) ||
            StrEqual(weapon,"weapon_bazooka",false) ||
            StrEqual(weapon,"weapon_pschreck",false))
        {
            new Float:percent;
            switch(skill_cg)
            {
                case 1:
                    percent=0.4;
                case 2:
                    percent=1.067;
                case 3:
                    percent=1.733;
                case 4:
                    percent=2.4;
            }

            new damage=GetDamage(event, index, 10, 30);
            new health_take=RoundFloat(float(damage)*percent);
            new new_health=GetClientHealth(victimIndex)-health_take;
            if (new_health <= 0)
            {
                new_health=0;
                LogKill(index, victimIndex, "acute_grenade", "Acute Grenade", health_take);
            }
            else
                LogDamage(index, victimIndex, "acute_grenade", "Acute Grenade", health_take);

            SetHealth(victimIndex,new_health);

            new Float:Origin[3];
            GetClientAbsOrigin(victimIndex, Origin);
            Origin[2] += 5;

            TE_SetupGlowSprite(Origin,g_crystalSprite,0.7,3.0,200);
            TE_SendToAll();
        }
    }
}

public OrcishHorde_ChainLightning(war3player,client,ultlevel)
{
    new ult_level=War3_GetSkillLevel(war3player,raceID,3);
    if(ult_level)
    {
        new Float:range=1.0;
        switch(ult_level)
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
        new last=client;
        new count=0;
        new maxplayers=GetMaxClients();
        for(new index=1;index<=maxplayers;index++)
        {
            if (client != index && IsClientConnected(index) &&
                IsPlayerAlive(index) && GetClientTeam(client) != GetClientTeam(index))
            {
                new war3player_check=War3_GetWar3Player(index);
                if (war3player_check>-1)
                {
                    if (!War3_GetImmunity(war3player_check,Immunity_Ultimates))
                    {
                        if ( IsInRange(client,index,range))
                        {
                            new color[4] = { 10, 200, 255, 255 };
                            TE_SetupBeamLaser(last,index,g_beamSprite,g_haloSprite,
                                              0, 1, 10.0, 10.0,10.0,2,50.0,color,255);
                            TE_SendToAll();

                            new new_health=GetClientHealth(index)-40;
                            if (new_health <= 0)
                            {
                                new_health=0;

                                new addxp=5+ultlevel;
                                new newxp=War3_GetXP(war3player,raceID)+addxp;
                                War3_SetXP(war3player,raceID,newxp);

                                LogKill(client, index, "chain_lightning", "Chain Lightning", 40, addxp);
                            }
                            else
                                LogDamage(client, index, "chain_lightning", "Chain Lightning", 40);

                            SetHealth(index,new_health);

                            last=index;
                            if (++count > 4)
                                break;
                        }
                    }
                }
            }
        }
        EmitSoundToAll(thunderWav,client);
        PrintToChat(client,"%c[War3Source]%c You have used your ultimate %cChained Lightning%c, you now need to wait 45 seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
    }
}

public bool:IsInRange(client,index,Float:maxdistance)
{
    new Float:startclient[3];
    new Float:endclient[3];
    GetClientAbsOrigin(client,startclient);
    GetClientAbsOrigin(index,endclient);
    new Float:distance=DistanceBetween(startclient,endclient);
    return (distance<maxdistance);
}

