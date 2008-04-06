/**
 * vim: set ai et ts=4 sw=4 :
 * File: Al-Qaeda.sp
 * Description: The Al-Qaeda race for SourceCraft.
 * Author(s): -=|JFH|=-Naris (Murray Wilson) 
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
#include "sc/maxhealth"
#include "sc/respawn"
#include "sc/log"

new String:allahWav[] = "sourcecraft/allahuakbar.wav";
new String:kaboomWav[] = "sourcecraft/iraqi_engaging.wav";
new String:explodeWav[] = "weapons/explode5.wav";

new raceID, reincarnationID, wrathID, suicideID, bomberID;

new explosionModel;
new bigExplosionModel;
new g_beamSprite;
new g_haloSprite;
new g_purpleGlow;
new g_smokeSprite;
new g_lightningSprite;

new bool:m_Suicided[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Al-Qaeda",
    author = "-=|JFH|=-Naris (Murray Wilson)",
    description = "The Al-Qaeda race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    SetupRespawn();
    return true;
}

public OnPluginStart()
{
    GetGameType();

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
        if (!HookEvent("player_changeclass",PlayerChangeClassEvent,EventHookMode_Post))
            SetFailState("Couldn't hook the player_changeclass event.");

        if (!HookEvent("teamplay_round_start",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_round_start event.");

        if (!HookEvent("teamplay_suddendeath_begin",RoundStartEvent,EventHookMode_PostNoCopy))
            SetFailState("Couldn't hook the teamplay_suddendeath_begin event.");
    }

    CreateTimer(3.0,FlamingWrath,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID = CreateRace("Al-Qaeda", "alqaeda",
                        "You are now an Al-Qaeda.",
                        "You will be an Al-Qaeda when you die or respawn.",
                        16);

    reincarnationID  = AddUpgrade(raceID,"Reincarnation",
                                  "Gives you a 15-80% chance of immediately respawning where you died.");

    wrathID     = AddUpgrade(raceID,"Flaming Wrath",
                             "You cause damage to opponents around you.");

    suicideID   = AddUpgrade(raceID,"Suicide Bomber",
                             "You explode when you die, causing great damage to opponents around you");

    bomberID    = AddUpgrade(raceID,"Mad Bomber",
                             "Use your ultimate bind to explode\nand damage the surrounding players extremely,\nyou might even live trough it!", true); // Ultimate

    FindUberOffsets();
}

public OnMapStart()
{
    g_beamSprite = SetupModel("materials/models/props_lab/airlock_laser.vmt", true);
    if (g_beamSprite == -1)
        SetFailState("Couldn't find laser Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt", true);
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_purpleGlow = SetupModel("materials/sprites/purpleglow1.vmt", true);
    if (g_purpleGlow == -1)
        SetFailState("Couldn't find purpleglow Model");

    explosionModel=SetupModel("materials/sprites/zerogxplode.vmt", true);
    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    if (GameType == tf2)
    {
        bigExplosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt", true);
        if (bigExplosionModel == -1)
            SetFailState("Couldn't find Explosion Model");
    }
    else
        bigExplosionModel = explosionModel;

    SetupSound(allahWav, true, true);
    SetupSound(kaboomWav, true, true);
    SetupSound(explodeWav, true, true);

    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_IsRespawning[x]=false;
        m_IsChangingClass[x]=false;
        m_ReincarnationCount[x]=0;
    }
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (pressed)
    {
        if (race == raceID && IsPlayerAlive(client))
        {
            new level = GetUpgradeLevel(player,race,bomberID);
            if (level)
            {
                EmitSoundToAll(allahWav,client);
                AuthTimer(0.5, client, MadBomber);
            }
        }
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
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
        if (m_IsChangingClass[client])
            m_IsChangingClass[client] = false;
        else if (m_IsRespawning[client])
        {
            m_IsRespawning[client]=false;
            TeleportEntity(client,m_DeathLoc[client], NULL_VECTOR, NULL_VECTOR);
            TE_SetupGlowSprite(m_DeathLoc[client],g_purpleGlow,1.0,3.5,150);
            TE_SendToAll();

            //SetUber(client);
            //AuthTimer(1.0,client,ResetUber);
        }
    }
    return Plugin_Continue;
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_race == raceID && !m_IsChangingClass[victim_index])
    {
        if (m_Suicided[victim_index])
        {
            m_Suicided[victim_index]=false;
            m_ReincarnationCount[victim_index] = 0;
        }
        else
        {
            new reincarnation_level=GetUpgradeLevel(victim_player,victim_race,reincarnationID);
            if (reincarnation_level)
            {
                new percent;
                switch (reincarnation_level)
                {
                    case 1:
                        percent=9;
                    case 2:
                        percent=22;
                    case 3:
                        percent=36;
                    case 4:
                        percent=53;
                }
                if (GetRandomInt(1,100)<=percent &&
                    m_ReincarnationCount[victim_index] < 2*reincarnation_level)
                {
                    m_IsRespawning[victim_index]=true;
                    m_ReincarnationCount[victim_index]++;
                    GetClientAbsOrigin(victim_index,m_DeathLoc[victim_index]);
                    AuthTimer(0.5,victim_index,RespawnPlayerHandle);
                    return Plugin_Continue;
                }
                else
                    m_ReincarnationCount[victim_index] = 0;
            }
        }

        new suicide_level=GetUpgradeLevel(victim_player,victim_race,suicideID);
        if (suicide_level)
        {
            EmitSoundToAll(kaboomWav,victim_index);
            AuthTimer(0.4, victim_index, Kaboom);
        }
    }
    return Plugin_Continue;
}

public OnRaceSelected(client,Handle:player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        m_ReincarnationCount[client]=0;
        m_IsRespawning[client]=false;
        m_Suicided[client]=false;
    }
}

public Action:MadBomber(Handle:timer,any:arg)
{
    new client=PlayerOfAuthTimer(arg);
    if(client)
    {
        new Handle:player = GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            new ult_level=GetUpgradeLevel(player,raceID,bomberID);
            if (ult_level)
            {
                new percent;
                switch(ult_level)
                {
                    case 1:
                            percent=75;
                    case 2:
                            percent=50;
                    case 3:
                            percent=25;
                    case 4:
                            percent=10;
                }

                if (GetRandomInt(1,100)<=percent)
                {
                    m_Suicided[client]=true;
                    ForcePlayerSuicide(client);
                }
                else
                    Bomber(client,player,ult_level,false);
            }
        }
    }
    return Plugin_Stop;
}

public Action:Kaboom(Handle:timer,any:arg)
{
    new client=PlayerOfAuthTimer(arg);
    if(client)
    {
        new Handle:player = GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            new suicide_level=GetUpgradeLevel(player,raceID,suicideID);
            Bomber(client,player,suicide_level,true);
        }
    }
    return Plugin_Stop;
}

public Bomber(client,Handle:player,level,bool:ondeath)
{
    new Float:radius;
    new r_int, damage;
    switch(level)
    {
        case 1:
        {
            radius = 100.0;
            r_int  = 100;
            damage = 25;
        }
        case 2:
        {
            radius = 200.0;
            r_int  = 200;
            damage = 50;
        }
        case 3:
        {
            radius = 250.0;
            r_int  = 250;
            damage = 70;
        }
        case 4:
        {
            radius = 300.0;
            r_int  = 300;
            damage = 80;
        }
    }

    if (ondeath)
        damage = 300;

    new Float:client_location[3];
    GetClientAbsOrigin(client,client_location);
    TE_SetupExplosion(client_location,ondeath ? bigExplosionModel : explosionModel,10.0,30,0,r_int,20);
    TE_SendToAll();

    EmitSoundToAll(explodeWav,client);

    new clientCount = GetClientCount();
    for(new index=1;index<=clientCount;index++)
    {
        if (index != client && IsClientInGame(index) && IsPlayerAlive(index) &&
            GetClientTeam(index) != GetClientTeam(client) && !IsUber(index))
        {
            new Handle:check_player=GetPlayerHandle(index);
            if (check_player != INVALID_HANDLE)
            {
                if (!GetImmunity(check_player,Immunity_Ultimates) &&
                    !GetImmunity(check_player,Immunity_Explosion))
                {
                    new Float:check_location[3];
                    GetClientAbsOrigin(index,check_location);

                    new hp=PowerOfRange(client_location,radius,check_location,damage);
                    if (hp)
                    {
                        if (TraceTarget(client, index, client_location, check_location))
                        {
                            if (ondeath)
                                HurtPlayer(index,hp,client,"suicide_bomb", "Suicide Bomb", 5+level);
                            else
                                HurtPlayer(index,hp,client,"mad_bomber", "Mad Bomber", 5+level);
                        }
                    }
                }
            }
        }
    }
}

public Action:FlamingWrath(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if (IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceID)
                {
                    new flaming_wrath_level=GetUpgradeLevel(player,raceID,wrathID);
                    if (flaming_wrath_level)
                    {
                        new num=flaming_wrath_level*5;
                        new Float:range=1.0;
                        switch(flaming_wrath_level)
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
                            if (index != client && IsClientInGame(index))
                            {
                                if (IsPlayerAlive(index) &&
                                    GetClientTeam(index) != GetClientTeam(client) &&
                                    !IsUber(index))
                                {
                                    new Handle:player_check=GetPlayerHandle(index);
                                    if (player_check != INVALID_HANDLE)
                                    {
                                        if (!GetImmunity(player_check, Immunity_HealthTake) &&
                                            IsInRange(client,index,range))
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            if (TraceTarget(client, index, clientLoc, indexLoc))
                                            {
                                                new color[4] = { 255, 10, 55, 255 };
                                                TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                                  0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                                TE_SendToAll();

                                                new newhp=GetClientHealth(index)-flaming_wrath_level;
                                                if (newhp <= 0)
                                                {
                                                    newhp=0;
                                                    LogKill(client, index, "flaming_wrath", "Flaming Wrath", flaming_wrath_level);
                                                    KillPlayer(index,client,"flaming_wrath");
                                                }
                                                else
                                                {
                                                    LogDamage(client, index, "flaming_wrath", "Flaming Wrath", flaming_wrath_level);
                                                    HurtPlayer(index,flaming_wrath_level,client,"flaming_wrath");
                                                }

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
        }
    }
    return Plugin_Continue;
}

