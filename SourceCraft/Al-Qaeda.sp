/**
 * vim: set ai et ts=4 sw=4 :
 * File: Al-Qaeda.sp
 * Description: The Al-Qaeda race for SourceCraft.
 * Author(s): -=|JFH|=-Naris (Murray Wilson) 
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

new explosionModel;
new bigExplosionModel;
new g_beamSprite;
new g_haloSprite;
new g_purpleGlow;
new g_smokeSprite;
new g_lightningSprite;

new String:allahWav[] = "sourcecraft/allahuakbar.wav";
new String:kaboomWav[] = "sourcecraft/iraqi_engaging.wav";
new String:explodeWav[] = "weapons/explode5.wav";

// Reincarnation variables
new bool:m_Suicided[MAXPLAYERS+1];
new bool:m_IsRespawning[MAXPLAYERS+1];
new Float:m_DeathLoc[MAXPLAYERS+1][3];

public Plugin:myinfo = 
{
    name = "War3Source Race - Al-Qaeda",
    author = "-=|JFH|=-Naris (Murray Wilson)",
    description = "The Al-Qaeda race for War3Source.",
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

    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);

    CreateTimer(3.0,FlamingWrath,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID=CreateRace("Al-Qaeda", "alqaeda",
                      "You are now an Al-Qaeda.",
                      "You will be an Al-Qaeda when you die or respawn.",
                      "Reincarnation",
                      "Gives you a 15-80% chance of immediately respawning where you died.",
                      "Flaming Wrath",
                      "You cause damage to opponents around you.",
                      "Suicide Bomber",
                      "You explode when you die, causing great damage to opponents around you",
                      "Mad Bomber",
                      "Use your ultimate bind to explode\nand damage the surrounding players extremely,\nyou might even live trough it!");

}

public OnMapStart()
{
    g_beamSprite = SetupModel("materials/models/props_lab/airlock_laser.vmt");
    if (g_beamSprite == -1)
        SetFailState("Couldn't find laser Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_purpleGlow = SetupModel("materials/sprites/purpleglow1.vmt");
    if (g_purpleGlow == -1)
        SetFailState("Couldn't find purpleglow Model");

    explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");
    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    if (GameType == tf2)
    {
        bigExplosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt");
        if (bigExplosionModel == -1)
            SetFailState("Couldn't find Explosion Model");
    }
    else
        bigExplosionModel = explosionModel;

    SetupSound(allahWav);
    SetupSound(kaboomWav);
    SetupSound(explodeWav);
}

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
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
                new player=GetPlayer(client);
                if(player>=0 && GetRace(player) == raceID)
                {
                    new skill_flaming_wrath=GetSkillLevel(player,raceID,1);
                    if (skill_flaming_wrath)
                    {
                        new num=skill_flaming_wrath*2;
                        new Float:range=1.0;
                        switch(skill_flaming_wrath)
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
                            if (index != client && IsClientConnected(index))
                            {
                                if (IsPlayerAlive(index) && GetClientTeam(index) != GetClientTeam(client))
                                {
                                    new player_check=GetPlayer(index);
                                    if (player_check>-1)
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

                                                new newhp=GetClientHealth(index)-skill_flaming_wrath;
                                                if (newhp <= 0)
                                                {
                                                    newhp=0;
                                                    LogKill(client, index, "flaming_wrath", "Flaming Wrath", skill_flaming_wrath);
                                                }
                                                else
                                                    LogDamage(client, index, "flaming_wrath", "Flaming Wrath", skill_flaming_wrath);

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
        }
    }
    return Plugin_Continue;
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (pressed)
    {
        if (race == raceID && IsPlayerAlive(client))
        {
            new level = GetSkillLevel(player,race,3);
            if (level)
            {
                EmitSoundToAll(allahWav,client);
                AuthTimer(GetSoundDuration(allahWav), client, AlQaeda_MadBomber);
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid     = GetEventInt(event,"userid");
    new index      = GetClientOfUserId(userid);
    new player = GetPlayer(index);
    if (player > -1)
    {
        if (GetRace(player) == raceID)
        {
            if (m_Suicided[index])
                m_Suicided[index]=false;
            else
            {
                new reincarnation_skill=GetSkillLevel(player,raceID,0);
                if (reincarnation_skill)
                {
                    new percent;
                    switch (reincarnation_skill)
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
                    if (GetRandomInt(1,100)<=percent)
                    {
                        m_IsRespawning[index]=true;
                        GetClientAbsOrigin(index,m_DeathLoc[index]);
                        AuthTimer(0.5,index,RespawnPlayerHandle);
                        return;
                    }
                }

                new suicide_skill=GetSkillLevel(player,raceID,2);
                if (suicide_skill)
                {
                    EmitSoundToAll(kaboomWav,index);
                    AuthTimer(GetSoundDuration(kaboomWav), index, AlQaeda_Kaboom);
                }
            }
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client && m_IsRespawning[client])
    {
        m_IsRespawning[client]=false;
        TeleportEntity(client,m_DeathLoc[client], NULL_VECTOR, NULL_VECTOR);
        TE_SetupGlowSprite(m_DeathLoc[client],g_purpleGlow,1.0,3.5,150);
        TE_SendToAll();
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_IsRespawning[x]=false;
        m_Suicided[x]=false;
    }
}

public OnRaceSelected(client,player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        m_IsRespawning[client]=false;
        m_Suicided[client]=false;
    }
}

public Action:AlQaeda_MadBomber(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
    {
        new player = GetPlayer(client);
        if (player > -1)
        {
            new ult_level=GetSkillLevel(player,raceID,3);
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
                    EmitSoundToAll(kaboomWav,client);
                    AuthTimer(GetSoundDuration(kaboomWav), client, AlQaeda_Kaboom);
                }
                else
                    AlQaeda_Bomber(client,player,ult_level,false);
            }
        }
    }
    ClearArray(temp);
    return Plugin_Stop;
}

public Action:AlQaeda_Kaboom(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
    {
        new player = GetPlayer(client);
        if (player > -1)
        {
            new suicide_skill=GetSkillLevel(player,raceID,2);
            AlQaeda_Bomber(client,player,suicide_skill,true);
        }
    }
    ClearArray(temp);
    return Plugin_Stop;
}

public AlQaeda_Bomber(client,player,level,bool:ondeath)
{
    new Float:radius;
    new r_int, damage;
    switch(level)
    {
        case 1:
        {
            radius = 200.0;
            r_int  = 200;
            damage = 50;
        }
        case 2:
        {
            radius = 250.0;
            r_int  = 250;
            damage = 70;
        }
        case 3:
        {
            radius = 300.0;
            r_int  = 300;
            damage = 80;
        }
        case 4:
        {
            radius = 350.0;
            r_int  = 350;
            damage = 100;
        }
        default:
        {
            radius = 100.0;
            r_int  = 100;
            damage = 25;
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
    for(new x=1;x<=clientCount;x++)
    {
        if (x != client && IsClientConnected(x) && IsPlayerAlive(x) &&
            GetClientTeam(x) != GetClientTeam(client))
        {
            new player_check=GetPlayer(x);
            if (player_check>-1)
            {
                if (!(ondeath || GetImmunity(player_check,Immunity_Ultimates)) &&
                    !GetImmunity(player_check,Immunity_Explosion))
                {
                    new Float:location_check[3];
                    GetClientAbsOrigin(x,location_check);

                    new hp=PowerOfRange(client_location,radius,location_check,damage);
                    if (hp)
                    {
                        if (TraceTarget(client, x, client_location, location_check))
                        {
                            new newhealth = GetClientHealth(x)-hp;
                            if (newhealth <= 0)
                            {
                                newhealth=0;
                                new addxp=5+level;
                                new newxp=GetXP(player,raceID)+addxp;
                                SetXP(player,raceID,newxp);

                                if (ondeath)
                                    LogKill(client, x, "mad_bomber", "Mad Bomber", hp, addxp);
                                else
                                    LogKill(client, x, "suicide_bomb", "Suicide Bomb", hp, addxp);
                            }
                            else
                            {
                                if (ondeath)
                                    LogDamage(client, x, "mad_bomber", "Mad Bomber", hp);
                                else
                                    LogDamage(client, x, "suicide_bomb", "Suicide Bomb", hp);
                            }
                            SetHealth(x,newhealth);
                        }
                    }
                }
            }
        }
    }
}
