/**
 * vim: set ai et ts=4 sw=4 :
 * File: OrcishHorde.sp
 * Description: The Orcish Horde race for SourceCraft.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "SourceCraft/SourceCraft"

#include "SourceCraft/util"
#include "SourceCraft/range"
#include "SourceCraft/trace"
#include "SourceCraft/health"
#include "SourceCraft/authtimer"
#include "SourceCraft/respawn"
#include "SourceCraft/log"

new raceID; // The ID we are assigned to

new bool:m_HasRespawned[MAXPLAYERS+1];
new bool:m_IsRespawning[MAXPLAYERS+1];
new bool:m_AllowChainLightning[MAXPLAYERS+1];
new Float:m_DeathLoc[MAXPLAYERS+1][3];

new Handle:cvarChainCooldown = INVALID_HANDLE;

new g_haloSprite;
new g_purpleGlow;
new g_crystalSprite;
new g_lightningSprite;

new String:thunderWav[] = "sourcecraft/thunder1Long.mp3"; // "ambient/weather/thunder1.wav";

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Orcish Horde",
    author = "PimpinJuice",
    description = "The Orcish Horde race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    SetupRespawn();
    return true;
}

public OnPluginStart()
{
    GetGameType();

    cvarChainCooldown=CreateConVar("sc_chainlightningcooldown","30");

    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_death",PlayerDeathEvent);

    if (GameType == cstrike)
        HookEvent("round_start",RoundStartEvent);
    else if (GameType == dod)
        HookEvent("dod_round_start",RoundStartEvent);
    else if (GameType == tf2)
    {
        HookEvent("teamplay_round_start",RoundStartEvent);
        HookEvent("teamplay_suddendeath_begin",SuddenDeathBeginEvent);
    }
}

public OnPluginReady()
{
    raceID=CreateRace("Orcish Horde", // Full race name
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
                      "Discharges a bolt of lightning that jumps\non up to 4 nearby enemies 150-300 units in range,\ndealing each 32 damage."); // Ultimate Description
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_crystalSprite = SetupModel("materials/sprites/crystal_beam1.vmt");
    if (g_crystalSprite == -1)
        SetFailState("Couldn't find crystal_beam Model");

    g_purpleGlow = SetupModel("materials/sprites/purpleglow1.vmt");
    if (g_purpleGlow == -1)
        SetFailState("Couldn't find purpleglow Model");

    SetupSound(thunderWav);
}

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
    m_AllowChainLightning[client]=true;
}

public OnRaceSelected(client,player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        m_AllowChainLightning[client]=true;
        m_HasRespawned[client]=false;
        m_IsRespawning[client]=false;
    }
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (pressed && m_AllowChainLightning[client] &&
        race == raceID && IsPlayerAlive(client))
    {
        new skill = GetSkillLevel(player,race,3);
        if (skill)
        {
            OrcishHorde_ChainLightning(player,client,skill);
            new Float:cooldown = GetConVarFloat(cvarChainCooldown);
            if (cooldown > 0.0)
            {
                m_AllowChainLightning[client]=false;
                CreateTimer(cooldown,AllowChainLightning,client);
            }
        }
    }
}

public Action:AllowChainLightning(Handle:timer,any:index)
{
    m_AllowChainLightning[index]=true;
    return Plugin_Stop;
}

// Events
public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid=GetEventInt(event,"userid");
    if (victimUserid)
    {
        new victimIndex  = GetClientOfUserId(victimUserid);
        if (victimIndex != -1)
        {
            new attackerUserid = GetEventInt(event,"attacker");
            if (attackerUserid && victimUserid != attackerUserid)
            {
                new attackerIndex  = GetClientOfUserId(attackerUserid);
                new attackerPlayer = GetPlayer(attackerIndex);
                if (attackerPlayer != -1)
                {
                    if (GetRace(attackerPlayer) == raceID)
                    {
                        OrcishHorde_AcuteStrike(event, attackerIndex, attackerPlayer, victimIndex);
                        OrcishHorde_AcuteGrenade(event, attackerIndex, attackerPlayer, victimIndex);
                    }
                }
            }

            new assisterUserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisterUserid && victimUserid != assisterUserid)
            {
                new assisterIndex  = GetClientOfUserId(assisterUserid);
                new assisterPlayer = GetPlayer(assisterIndex);
                if (assisterPlayer != -1)
                {
                    if (GetRace(assisterPlayer) == raceID)
                    {
                        OrcishHorde_AcuteStrike(event, assisterIndex, assisterPlayer, victimIndex);
                        OrcishHorde_AcuteGrenade(event, assisterIndex, assisterPlayer, victimIndex);
                    }
                }
            }
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new player=GetPlayer(client);
        if (player>-1)
        {
            new race=GetRace(player);
            if (race==raceID)
            {
                if (m_IsRespawning[client])
                {
                    m_IsRespawning[client]=false;

                    if (GameType != cstrike)
                        TeleportEntity(client,m_DeathLoc[client], NULL_VECTOR, NULL_VECTOR);

                    TE_SetupGlowSprite(m_DeathLoc[client],g_purpleGlow,1.0,3.5,150);
                    TE_SendToAll();
                }
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    new player=GetPlayer(index);
    if (player>-1)
    {
        new race=GetRace(player);
        if (race==raceID && (!m_HasRespawned[index] || GameType != cstrike))
        {
            new skill=GetSkillLevel(player,race,2);
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
                    GetClientAbsOrigin(index, m_DeathLoc[index]);
                    TE_SetupGlowSprite(m_DeathLoc[index],g_purpleGlow,1.0,3.5,150);
                    TE_SendToAll();

                    AuthTimer(0.5,index,RespawnPlayerHandle);
                    m_HasRespawned[index]=true;
                    m_IsRespawning[index]=true;
                }
            }
        }
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_HasRespawned[x]=false;
        m_IsRespawning[x]=false;
    }
}

public SuddenDeathBeginEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_HasRespawned[x]=false;
        m_IsRespawning[x]=false;
    }
}

public OrcishHorde_AcuteStrike(Handle:event, index, player, victimIndex)
{
    new skill_cs = GetSkillLevel(player,raceID,0);
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

            new damage=GetDamage(event, victimIndex);
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
            TE_SetupBeamLaser(index,victimIndex,g_lightningSprite,g_haloSprite,
                              0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
            TE_SendToAll();
        }
    }
}

public OrcishHorde_AcuteGrenade(Handle:event, index, player, victimIndex)
{
    new skill_cg = GetSkillLevel(player,raceID,1);
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

            new damage=GetDamage(event, victimIndex);
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

public OrcishHorde_ChainLightning(player,client,ultlevel)
{
    new ult_level=GetSkillLevel(player,raceID,3);
    if(ult_level)
    {
        new num=ult_level*2;
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
        new count=0;
        new last=client;
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        new maxplayers=GetMaxClients();
        for(new index=1;index<=maxplayers;index++)
        {
            if (client != index && IsClientConnected(index) &&
                IsPlayerAlive(index) && GetClientTeam(client) != GetClientTeam(index))
            {
                new player_check=GetPlayer(index);
                if (player_check>-1)
                {
                    if (!GetImmunity(player_check,Immunity_Ultimates))
                    {
                        if ( IsInRange(client,index,range))
                        {
                            new Float:indexLoc[3];
                            GetClientAbsOrigin(index, indexLoc);
                            if (TraceTarget(client, index, clientLoc, indexLoc))
                            {
                                new color[4] = { 10, 200, 255, 255 };
                                TE_SetupBeamLaser(last,index,g_lightningSprite,g_haloSprite,
                                        0, 1, 10.0, 10.0,10.0,2,50.0,color,255);
                                TE_SendToAll();

                                new new_health=GetClientHealth(index)-40;
                                if (new_health <= 0)
                                {
                                    new_health=0;

                                    new addxp=5+ultlevel;
                                    new newxp=GetXP(player,raceID)+addxp;
                                    SetXP(player,raceID,newxp);

                                    LogKill(client, index, "chain_lightning", "Chain Lightning", 40, addxp);
                                }
                                else
                                    LogDamage(client, index, "chain_lightning", "Chain Lightning", 40);

                                SetHealth(index,new_health);

                                last=index;
                                if (++count > num)
                                    break;
                            }
                        }
                    }
                }
            }
        }
        EmitSoundToAll(thunderWav,client);
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cChained Lightning%c, you now need to wait 45 seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
    }
}