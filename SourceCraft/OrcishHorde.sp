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

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/respawn"
#include "sc/weapons"
#include "sc/log"

new String:thunderWav[] = "sourcecraft/thunder1long.mp3";
new String:rechargeWav[] = "sourcecraft/transmission.wav";

new raceID; // The ID we are assigned to

new bool:m_AllowChainLightning[MAXPLAYERS+1];
new bool:m_HasRespawned[MAXPLAYERS+1];

new Handle:cvarChainCooldown = INVALID_HANDLE;

new g_haloSprite;
new g_purpleGlow;
new g_crystalSprite;
new g_lightningSprite;

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

    if (!HookEvent("player_spawn",PlayerSpawnEvent,EventHookMode_Post))
        SetFailState("Couldn't hook the player_spawn event.");

    if (GameType == cstrike)
    {
        if (!HookEvent("round_start",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the round_start event.");
    }
    else if (GameType == dod)
    {
        if (!HookEvent("dod_round_start",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the dod_round_start event.");
    }
    else if (GameType == tf2)
    {
        if (!HookEvent("player_changeclass",PlayerChangeClassEvent,EventHookMode_Post))
            SetFailState("Couldn't hook the player_changeclass event.");

        if (!HookEvent("teamplay_round_start",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_start event.");

        if (!HookEvent("teamplay_suddendeath_begin",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_suddendeath_begin event.");
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

    FindUberOffsets();
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

    SetupSound(thunderWav,true,true);
    SetupSound(rechargeWav,true,true);

    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_HasRespawned[x]=false;
        m_IsRespawning[x]=false;
        m_IsChangingClass[x]=false;
        m_ReincarnationCount[x]=0;
    }
}

public OnPlayerAuthed(client,player)
{
    m_AllowChainLightning[client]=true;
}

public OnRaceSelected(client,player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        m_AllowChainLightning[client]=true;
        m_HasRespawned[client]=false;
        m_IsRespawning[client]=false;
        m_IsChangingClass[client] = false;
    }
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (pressed && m_AllowChainLightning[client] &&
        race == raceID && IsPlayerAlive(client))
    {
        new skill = GetSkillLevel(player,race,3);
        if (skill)
            ChainLightning(player,client,skill);
    }
}

// Events
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_HasRespawned[x]=false;
        m_IsRespawning[x]=false;
        m_IsChangingClass[x]=false;
        m_ReincarnationCount[x]=0;
    }
}

public Action:PlayerChangeClassEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new player = GetPlayer(client);
        if (GetRace(player) == raceID && IsPlayerAlive(client))
        {
            m_IsChangingClass[client] = true;
        }
    }
    return Plugin_Continue;
}

public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
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
                if (m_IsChangingClass[client])
                    m_IsChangingClass[client] = false;
                else if (m_IsRespawning[client])
                {
                    m_IsRespawning[client]=false;

                    if (GameType != cstrike)
                        TeleportEntity(client,m_DeathLoc[client], NULL_VECTOR, NULL_VECTOR);

                    TE_SetupGlowSprite(m_DeathLoc[client],g_purpleGlow,1.0,3.5,150);
                    TE_SendToAll();

                    SetUber(client);
                    AuthTimer(0.5,client,ResetUber);
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,victim_player,victim_race,
                                attacker_index,attacker_player,attacker_race,
                                assister_index,assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    decl String:weapon[64] = "";
    GetWeapon(event, attacker_index, weapon, sizeof(weapon));

    if (attacker_race == raceID && victim_index != attacker_index)
    {
        if (AcuteGrenade(damage, victim_index, victim_player,
                         attacker_index, attacker_player, weapon))
        {
            changed = true;
        }
        else if (AcuteStrike(damage, victim_index, victim_player,
                             attacker_index, attacker_player))
        {
            changed = true;
        }
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        if (AcuteGrenade(damage, victim_index, victim_player,
                         assister_index, assister_player, weapon))
        {
            changed = true;
        }
        else if (AcuteStrike(damage, victim_index, victim_player,
                             assister_index, assister_player))
        {
            changed = true;
        }
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,victim_player,victim_race,
                                 attacker_index,attacker_player,attacker_race,
                                 assister_index,assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_race==raceID && !m_IsChangingClass[victim_index] &&
        (!m_HasRespawned[victim_index] || GameType != cstrike))
    {
        new skill=GetSkillLevel(victim_player,victim_race,2);
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
            if (GetRandomInt(1,100)<=percent && m_ReincarnationCount[victim_index] < 3*skill)
            {
                GetClientAbsOrigin(victim_index, m_DeathLoc[victim_index]);
                TE_SetupGlowSprite(m_DeathLoc[victim_index],g_purpleGlow,1.0,3.5,150);
                TE_SendToAll();

                AuthTimer(0.5,victim_index,RespawnPlayerHandle);
                m_HasRespawned[victim_index]=true;
                m_IsRespawning[victim_index]=true;
                m_ReincarnationCount[victim_index]++;
            }
            else
                m_ReincarnationCount[victim_index] = 0;

        }
        else
            m_ReincarnationCount[victim_index] = 0;
    }
}

bool:AcuteStrike(damage, victim_index, victim_player, index, player)
{
    new skill_cs = GetSkillLevel(player,raceID,0);
    if (skill_cs > 0 && !GetImmunity(victim_player,Immunity_HealthTake) && !IsUber(victim_index))
    {
        if(GetRandomInt(1,100)<=15)
        {
            new Float:percent;
            switch(skill_cs)
            {
                case 1:
                    percent=0.30;
                case 2:
                    percent=0.60;
                case 3:
                    percent=0.90;
                case 4:
                    percent=1.20;
            }

            new health_take=RoundFloat(float(damage)*percent);
            new new_health=GetClientHealth(victim_index)-health_take;
            if (new_health <= 0)
            {
                new_health=0;
                LogKill(index, victim_index, "acute_strike", "Acute Strike", health_take);
            }
            else
                LogDamage(index, victim_index, "acute_strike", "Acute Strike", health_take);

            SetEntityHealth(victim_index,new_health);

            new color[4] = { 100, 255, 55, 255 };
            TE_SetupBeamLaser(index,victim_index,g_lightningSprite,g_haloSprite,
                              0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
            TE_SendToAll();
            return true;
        }
    }
    return false;
}

bool:AcuteGrenade(damage, victim_index, victim_player, index, player, const String:weapon[])
{
    new skill_cg = GetSkillLevel(player,raceID,1);
    if (skill_cg > 0 && !GetImmunity(victim_player,Immunity_HealthTake) && !IsUber(victim_index))
    {
        if(GetRandomInt(1,100)<=50)
        {
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
                        percent=0.35;
                    case 2:
                        percent=0.60;
                    case 3:
                        percent=0.85;
                    case 4:
                        percent=1.25;
                }

                new health_take=RoundFloat(float(damage)*percent);
                new new_health=GetClientHealth(victim_index)-health_take;
                if (new_health <= 0)
                {
                    new_health=0;
                    LogKill(index, victim_index, "acute_grenade", "Acute Grenade", health_take);
                }
                else
                    LogDamage(index, victim_index, "acute_grenade", "Acute Grenade", health_take);

                SetEntityHealth(victim_index,new_health);

                new Float:Origin[3];
                GetClientAbsOrigin(victim_index, Origin);
                Origin[2] += 5;

                TE_SetupGlowSprite(Origin,g_crystalSprite,0.7,3.0,200);
                TE_SendToAll();
                return true;
            }
        }
    }
    return false;
}

ChainLightning(player,client,ultlevel)
{
    new dmg;
    new num=ultlevel*2;
    new Float:range;
    switch(ultlevel)
    {
        case 1:
        {
            dmg=GetRandomInt(20,40);
            range=300.0;
        }
        case 2:
        {
            dmg=GetRandomInt(30,50);
            range=450.0;
        }
        case 3:
        {
            dmg=GetRandomInt(40,60);
            range=650.0;
        }
        case 4:
        {
            dmg=GetRandomInt(50,70);
            range=800.0;
        }
    }
    new count=0;
    new last=client;
    new Float:clientLoc[3];
    GetClientAbsOrigin(client, clientLoc);
    new maxplayers=GetMaxClients();
    for(new index=1;index<=maxplayers;index++)
    {
        if (client != index && IsClientInGame(index) && IsPlayerAlive(index) &&
            GetClientTeam(client) != GetClientTeam(index))
        {
            new player_check=GetPlayer(index);
            if (player_check>-1)
            {
                if (!GetImmunity(player_check,Immunity_Ultimates) &&
                    !GetImmunity(player_check,Immunity_HealthTake) && !IsUber(index))
                {
                    if (IsInRange(client,index,range))
                    {
                        new Float:indexLoc[3];
                        GetClientAbsOrigin(index, indexLoc);
                        if (TraceTarget(client, index, clientLoc, indexLoc))
                        {
                            new color[4] = { 10, 200, 255, 255 };
                            TE_SetupBeamLaser(last,index,g_lightningSprite,g_haloSprite,
                                              0, 1, 10.0, 10.0,10.0,2,50.0,color,255);
                            TE_SendToAll();

                            new new_health=GetClientHealth(index)-dmg;
                            if (new_health <= 0)
                            {
                                new_health=0;

                                new addxp=5+ultlevel;
                                new newxp=GetXP(player,raceID)+addxp;
                                SetXP(player,raceID,newxp);

                                LogKill(client, index, "chain_lightning", "Chain Lightning", 40, addxp);
                                KillPlayer(index);
                            }
                            else
                            {
                                LogDamage(client, index, "chain_lightning", "Chain Lightning", 40);
                                HurtPlayer(index, dmg, client, "chain_lightning");
                            }

                            last=index;
                            if (++count > num)
                                break;
                        }
                    }
                }
            }
        }
    }
    new Float:cooldown = GetConVarFloat(cvarChainCooldown);
    if (count)
    {
        EmitSoundToAll(thunderWav,client);
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cChained Lightning%c to damage %d enemies, you now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
    }
    else
    {
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cChained Lightning%c, which did no damage! You now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
    }
    if (cooldown > 0.0)
    {
        m_AllowChainLightning[client]=false;
        CreateTimer(cooldown,AllowChainLightning,client);
    }
}

public Action:AllowChainLightning(Handle:timer,any:index)
{
    m_AllowChainLightning[index]=true;

    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        if (GetRace(GetPlayer(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cChained Lightning%c is now available again!",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}

