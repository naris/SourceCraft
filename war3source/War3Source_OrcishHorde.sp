/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source_OrcishHorde.sp
 * Description: The Orcish Horde race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"
#include "War3Source/util"

// Defines
#define MAXPLAYERS 64
#define IS_ALIVE !GetLifestate

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // DOD = Red

// War3Source stuff
new raceID; // The ID we are assigned to
new bool:m_HasRespawned[MAXPLAYERS+1]={false};
new Float:m_UseTime[MAXPLAYERS+1]={0.0,...};
new bool:m_AllowChainLightning[MAXPLAYERS+1]={false,...};
new Handle:cvarChainCooldown;
new Handle:hGameConf;
new Handle:hRoundRespawn;

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
                           "Critical Strike", //Skill 1 Name
                           "Gives you a 15% chance of doing\n40-240% more damage.", // Skill 1 Description
                           "Critical Grenade", // Skill 2 Name
                           "Grenades and Rockets will always do a 40-240%\nmore damage.", // Skill 2 Description
                           "Reincarnation", // Skill 3 Name
                           "Gives you a 15-80% chance of respawning\nonce.", // Skill 3 Description
                           "Chain Lightning", // Ultimate Name
                           "Discharges a bolt of lightning that jumps\non up to 4 nearby enemies 150-300 units in range,\ndealing each 32 damage.\nNOT IMPLEMENTED YET!"); // Ultimate Description

    FindOffsets();

    LoadSDKToolStuff();
}

public LoadSDKToolStuff()
{
    hGameConf=LoadGameConfigFile("plugin.war3source");
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"RoundRespawn");
    hRoundRespawn=EndPrepSDKCall();
}

public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client,war3player);
}

public OnRaceSelected(client,war3player,oldrace,newrace)
{
}

public OnGameFrame()
{
    for(new x=0;x<=MAXPLAYERS;x++)
    {
        if(!m_AllowChainLightning[x])
            if(GetEngineTime()>=m_UseTime[x]+GetConVarFloat(cvarChainCooldown))
                m_AllowChainLightning[x]=true;
    }
}

public War3Source_ChainLightning(war3player,client,ultlevel)
{
    // we need traceline :[
    PrintToChat(client,"%c[War3Source]%c DOH! Chain Lightning has not been implemented yet!",COLOR_GREEN,COLOR_DEFAULT);
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if(pressed && m_AllowChainLightning[client] &&
       race==raceID && IS_ALIVE(client))
    {
        new skill=War3_GetSkillLevel(war3player,race,3);
        if(skill)
        {
            War3Source_ChainLightning(war3player,client,skill);
            m_AllowChainLightning[client]=false;
            m_UseTime[client]=GetEngineTime();
        }
    }
}

// Events
public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    if (userid)
    {
        new index      = GetClientOfUserId(userid);
        new war3player = War3_GetWar3Player(index);
        if (war3player != -1)
        {
            new attacker_userid = GetEventInt(event,"attacker");
            if (attacker_userid && userid != attacker_userid)
            {
                new attacker_index      = GetClientOfUserId(attacker_userid);
                new war3player_attacker = War3_GetWar3Player(attacker_index);
                if (war3player_attacker != -1)
                {
                    if (War3_GetRace(war3player_attacker) == raceID)
                    {
                        DoCriticalStrike(event, war3player_attacker, index);
                        DoCriticalGrenade(event, war3player_attacker, index);
                    }
                }
            }

            new assister_userid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assister_userid && userid != assister_userid)
            {
                new assister_index      = GetClientOfUserId(assister_userid);
                new war3player_assister = War3_GetWar3Player(assister_index);
                if (war3player_assister != -1)
                {
                    if (War3_GetRace(war3player_assister) == raceID)
                    {
                        DoCriticalStrike(event, war3player_assister, index);
                        DoCriticalGrenade(event, war3player_assister, index);
                    }
                }
            }
        }
    }
}

public DoCriticalStrike(Handle:event, war3player, victim)
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
            new health_take=RoundFloat((float(GetEventInt(event,"dmg_health"))*percent));
            new new_health=GetClientHealth(victim)-health_take;
            if(new_health<0)
                new_health=0;
            SetHealth(victim,new_health);
        }
    }
}

public DoCriticalGrenade(Handle:event, war3player, victim)
{
    new skill_cg = War3_GetSkillLevel(war3player,raceID,1);
    if (skill_cg > 0)
    {
        decl String:weapon[64];
        GetEventString(event,"weapon",weapon,63);
        if (StrEqual(weapon,"hegrenade",false) ||
            StrEqual(weapon,"tf_projectile_pipe",false) ||
            StrEqual(weapon,"tf_projectile_pipe_remote",false) ||
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
            new health_take=RoundFloat((float(GetEventInt(event,"dmg_health"))*percent));
            new new_health=GetClientHealth(victim)-health_take;
            if(new_health<0)
                new_health=0;
            SetHealth(victim,new_health);
        }
    }
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
    SDKCall(hRoundRespawn,client);
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(index);
    if(war3player>-1)
    {
        new race=War3_GetRace(war3player);
        if(race==raceID&&!m_HasRespawned[index])
        {
            new skill=War3_GetSkillLevel(war3player,race,2);
            if(skill)
            {
                new percent;
                switch(skill)
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
                if(GetRandomInt(1,100)<=percent)
                {
                    CreateTimer(0.5,RespawnPlayer,index);
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
