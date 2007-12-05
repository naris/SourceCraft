/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source_OrcishHorde.sp
 * Description: The Orcish Horde race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "War3Source/War3Source_Interface"
#include <sdktools>

// Defines
#define MAXPLAYERS 64
#define IS_ALIVE !GetLifestate

// War3Source stuff
new raceID; // The ID we are assigned to
new healthOffset[MAXPLAYERS+1];
new lifestateOffset;
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
    raceID=War3_CreateRace(
                            "Orcish Horde", // Full race name
                            "orc", // SQLite ID name (short name, no spaces)
                            "You are now an Orcish Horde.", // Selected Race message
                            "You will be an Orcish Horde when you die or respawn.", // Selected Race message if you are not allowed until death or respawn
                            "Critical Strike", //Skill 1 Name
                            "Gives you a 15% chance of doing\n40-240% more damage.", // Skill 1 Description
                            "Critical Grenade", // Skill 2 Name
                            "Grenades will always do a 40-240%\nmore damage.", // Skill 2 Description
                            "Reincarnation", // Skill 3 Name
                            "Gives you a 15-80% chance of respawning\nonce.", // Skill 3 Description
                            "Chain Lightning", // Ultimate Name
                            "Discharges a bolt of lightning that jumps\non up to 4 nearby enemies 150-300 units in range,\ndealing each 32 damage."); // Ultimate Description
    LoadSDKToolStuff();
    lifestateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
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
    healthOffset[client]=FindDataMapOffs(client,"m_iHealth");
}

public OnRaceSelected(client,war3player,oldrace,newrace)
{
}

public GetLifestate(client)
{
    return GetEntData(client,lifestateOffset,1);
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
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if(pressed&&m_AllowChainLightning[client]&&race==raceID&&IS_ALIVE(client))
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
    new attacker_userid=GetEventInt(event,"attacker");
    if(userid&&attacker_userid&&userid!=attacker_userid)
    {
        new index=GetClientOfUserId(userid);
        new attacker_index=GetClientOfUserId(attacker_userid);
        new war3player=War3_GetWar3Player(index);
        new war3player_attacker=War3_GetWar3Player(attacker_index);
        if(war3player!=-1&&war3player_attacker!=-1)
        {
            new race_attacker=War3_GetRace(war3player_attacker);
            if(race_attacker==raceID)
            {
                new skill_cs_attacker=War3_GetSkillLevel(war3player_attacker,race_attacker,0);
                if(skill_cs_attacker>0)
                {
                    if(GetRandomInt(1,100)<=15)
                    {
                        new Float:percent;
                        switch(skill_cs_attacker)
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
                        new new_health=GetClientHealth(index)-health_take;
                        if(new_health<0)
                            new_health=0;
                        SetHealth(index,new_health);
                    }
                }
                new skill_cg_attacker=War3_GetSkillLevel(war3player_attacker,race_attacker,1);
                if(skill_cg_attacker>0)
                {
                    decl String:weapon[64];
                    GetEventString(event,"weapon",weapon,63);
                    if(StrEqual(weapon,"hegrenade",false))
                    {
                        new Float:percent;
                        switch(skill_cg_attacker)
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
                        new new_health=GetClientHealth(index)-health_take;
                        if(new_health<0)
                            new_health=0;
                        SetHealth(index,new_health);
                    }
                }
            }
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

// Generic
public SetHealth(entity,amount)
{
    SetEntData(entity,healthOffset[entity],amount,true);
}
