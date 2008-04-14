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

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/respawn"
#include "sc/weapons"
#include "sc/log"

new String:thunderWav[] = "sourcecraft/thunder1long.mp3";
new String:rechargeWav[] = "sourcecraft/transmission.wav";

new raceID, strikeID, grenadeID, reincarnationID, lightningID;

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

    if (!HookEvent("player_spawn",PlayerSpawnEvent))
        SetFailState("Couldn't hook the player_spawn event.");

    if(!HookEvent("player_team",PlayerChangeClassEvent))
        SetFailState("Could not hook the player_team event.");

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
        if (!HookEvent("player_changeclass",PlayerChangeClassEvent))
            SetFailState("Couldn't hook the player_changeclass event.");

        if (!HookEvent("teamplay_round_start",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_start event.");

        if (!HookEvent("teamplay_suddendeath_begin",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_suddendeath_begin event.");
    }
}

public OnPluginReady()
{
    raceID          = CreateRace("Orcish Horde", "orc",
                                 "You are now an Orcish Horde.",
                                 "You will be an Orcish Horde when you die or respawn.");

    strikeID        = AddUpgrade(raceID,"Acute Strike", "acute_strike",
                                 "Gives you a 25% chance of doing\n40-120% more damage.");

    grenadeID       = AddUpgrade(raceID,"Acute Grenade", "acute_grenade",
                                 "Grenades and Rockets have a 15% chance of doing 35-100%\nmore damage.");

    reincarnationID = AddUpgrade(raceID,"Reincarnation", "reincarnation",
                                 "Gives you a 15-80% chance of respawning\nonce.");

    lightningID     = AddUpgrade(raceID,"Chain Lightning", "lightning",
                                 "Discharges a bolt of lightning that jumps\non up to 4 nearby enemies 150-300 units in range,\ndealing each 32 damage.", true); // Ultimate
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

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    m_AllowChainLightning[client]=true;
}

public OnRaceSelected(client,Handle:player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        m_AllowChainLightning[client]=true;
        m_HasRespawned[client]=false;
        m_IsRespawning[client]=false;
        m_IsChangingClass[client] = false;
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (pressed && m_AllowChainLightning[client] &&
        race == raceID && IsPlayerAlive(client))
    {
        new lightning_level = GetUpgradeLevel(player,race,lightningID);
        if (lightning_level)
            ChainLightning(client,lightning_level);
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
        new Handle:player = GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            if (GetRace(player) == raceID && IsPlayerAlive(client))
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
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            if (GetRace(player)==raceID)
            {
                if (m_IsChangingClass[client])
                    m_IsChangingClass[client] = false;
                else if (m_IsRespawning[client])
                {
                    m_IsRespawning[client]=false;

                    TeleportEntity(client,m_DeathLoc[client], NULL_VECTOR, NULL_VECTOR);

                    TE_SetupGlowSprite(m_DeathLoc[client],g_purpleGlow,1.0,3.5,150);
                    TE_SendToAll();

                    if (GameType == tf2)
                    {
                        new Handle:pack = AuthTimer(0.1,client,SetInvuln);
                        WritePackFloat(pack, 0.5);
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    decl String:weapon[64];
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

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_race==raceID && !m_IsChangingClass[victim_index] &&
        (!m_HasRespawned[victim_index] || GameType != cstrike))
    {
        new reincarnation_level=GetUpgradeLevel(victim_player,victim_race,reincarnationID);
        if (reincarnation_level)
        {
            new percent, times;
            switch (reincarnation_level)
            {
                case 1:
                {
                    percent=15;
                    times=2;
                }
                case 2:
                {
                    percent=37;
                    times=3;
                }
                case 3:
                {
                    percent=59;
                    times=4;
                }
                case 4:
                {
                    percent=80;
                    times=5;
                }
            }
            if (GetRandomInt(1,100)<=percent &&
                m_ReincarnationCount[victim_index] <= times)
            {
                GetClientAbsOrigin(victim_index, m_DeathLoc[victim_index]);
                TE_SetupGlowSprite(m_DeathLoc[victim_index],g_purpleGlow,1.0,3.5,150);
                TE_SendToAll();

                AuthTimer(0.1,victim_index,RespawnPlayerHandle);
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

bool:AcuteStrike(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new strike_level = GetUpgradeLevel(player,raceID,strikeID);
    if (strike_level > 0 && !GetImmunity(victim_player,Immunity_HealthTake)
                         && !TF2_IsPlayerInvuln(victim_index))
    {
        if(GetRandomInt(1,100)<=25)
        {
            new Float:percent;
            switch(strike_level)
            {
                case 1:
                    percent=0.40;
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

bool:AcuteGrenade(damage, victim_index, Handle:victim_player, index, Handle:player, const String:weapon[])
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
        new grenade_level = GetUpgradeLevel(player,raceID,grenadeID);
        if (grenade_level > 0 && !GetImmunity(victim_player,Immunity_HealthTake)
                              && !TF2_IsPlayerInvuln(victim_index))
        {
            if(GetRandomInt(1,100)<=15)
            {
                new Float:percent;
                switch(grenade_level)
                {
                    case 1:
                        percent=0.35;
                    case 2:
                        percent=0.60;
                    case 3:
                        percent=0.80;
                    case 4:
                        percent=1.00;
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
            }
        }
        return true;
    }
    return false;
}

ChainLightning(client,ultlevel)
{
    new dmg;
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
            new Handle:player_check=GetPlayerHandle(index);
            if (player_check != INVALID_HANDLE)
            {
                if (!GetImmunity(player_check,Immunity_Ultimates) &&
                    !GetImmunity(player_check,Immunity_HealthTake) &&
                    !TF2_IsPlayerInvuln(index))
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

                            HurtPlayer(index,dmg,client,"chain_lightning", "Chain Lightning", 5+ultlevel);
                            last=index;
                        }
                    }
                }
            }
        }
    }
    EmitSoundToAll(thunderWav,client);
    new Float:cooldown = GetConVarFloat(cvarChainCooldown);
    if (count)
    {
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
        if (GetRace(GetPlayerHandle(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cChained Lightning%c is now available again!",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}

