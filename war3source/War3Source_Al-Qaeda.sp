/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_Al-Qaeda.sp
 * Description: The Al-Qaeda race for War3Source.
 * Author(s): -=|JFH|=-Naris (Murray Wilson) 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/range"
#include "War3Source/health"
#include "War3Source/authtimer"
#include "War3Source/respawn"
#include "War3Source/log"

// War3Source stuff
new raceID; // The ID we are assigned to

new explosionModel;
new g_beamSprite;
new g_haloSprite;
new g_purpleGlow;
new g_smokeSprite;
new g_lightningSprite;

new String:allahWav[] = "war3/allahuakbar.wav";
new String:kaboomWav[] = "war3/iraqi_engaging.wav";
new String:explodeWav[] = "weapons/explode5.wav";

// Suicide bomber check
new bool:m_Exploded[MAXPLAYERS+1];
new bool:m_IsRespawning[MAXPLAYERS+1];

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

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Al-Qaeda",
                           "alqaeda",
                           "You are now an Al-Qaeda.",
                           "You will be an Al-Qaeda when you die or respawn.",
                           "Reincarnation",
                           "Gives you a 15-80% chance of immediately respawning where you died.",
                           "Flaming Wrath",
                           "You cause damage to opponents around you.",
                           "Suicide Bomber",
                           "You explode when you die",
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
    if (g_haloSprite == -1)
        SetFailState("Couldn't find purpleglow Model");

    if (GameType == tf2)
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt");
    else
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");

    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(allahWav);
    SetupSound(kaboomWav);
    SetupSound(explodeWav);
}

public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client);
}
public Action:FlamingWrath(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            new war3player=War3_GetWar3Player(client);
            if(war3player>=0 && War3_GetRace(war3player) == raceID)
            {
                new skill_flaming_wrath=War3_GetSkillLevel(war3player,raceID,1);
                if (skill_flaming_wrath)
                {
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
                    for (new index=1;index<=maxplayers;index++)
                    {
                        if (index != client && IsClientConnected(index) && IsPlayerAlive(index) &&
                            GetClientTeam(index) != GetClientTeam(client))
                        {
                            new war3player_check=War3_GetWar3Player(index);
                            if (war3player_check>-1)
                            {
                                if (IsInRange(client,index,range))
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
    if (pressed)
    {
        if (race == raceID && IsPlayerAlive(client))
        {
            new level = War3_GetSkillLevel(war3player,race,3);
            if (level)
            {
                EmitSoundToAll(allahWav,client);
                AuthTimer(GetSoundDuration(allahWav), client, AlQaeda_MabBomber);
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid     = GetEventInt(event,"userid");
    new index      = GetClientOfUserId(userid);
    new war3player = War3_GetWar3Player(index);
    if (war3player > -1 && !m_Exploded[index])
    {
        if(War3_GetRace(war3player) == raceID)
        {
            if (!m_Exploded[index])
            {
                new ult_level=War3_GetSkillLevel(war3player,raceID,3);
                if (ult_level)
                {
                    EmitSoundToAll(kaboomWav,index);
                    AlQaeda_Bomber(index,war3player,ult_level,true);
                }
            }

            if (!m_Exploded[index])
            {
                new skill=War3_GetSkillLevel(war3player,raceID,0);
                if (skill)
                {
                    new percent;
                    switch (skill)
                    {
                        case 1:
                            percent=25;
                        case 2:
                            percent=42;
                        case 3:
                            percent=76;
                        case 4:
                            percent=98;
                    }
                    if (GetRandomInt(1,100)<=percent)
                    {
                        AuthTimer(0.5,index,RespawnPlayerHandle);
                        m_IsRespawning[index]=true;
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
        m_Exploded[client]=false;
        new war3player=War3_GetWar3Player(client);
        if (war3player>-1)
        {
            new race=War3_GetRace(war3player);
            if (race==raceID)
            {
                if (m_IsRespawning[client])
                {
                    m_IsRespawning[client]=false;
                    new Float:Origin[3];
                    GetClientAbsOrigin(client, Origin);
                    TE_SetupGlowSprite(Origin,g_purpleGlow,1.0,3.5,150);
                    TE_SendToAll();
                }
            }
        }
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_IsRespawning[x]=false;
        m_Exploded[x]=false;
    }
}

public OnRaceSelected(client,war3player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        m_IsRespawning[client]=false;
        m_Exploded[client]=false;
    }
}

public Action:AlQaeda_MabBomber(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client && !m_Exploded[client])
    {
        new war3player = War3_GetWar3Player(client);
        if (war3player > -1)
        {
            new ult_level=War3_GetSkillLevel(war3player,raceID,3);
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
                    ForcePlayerSuicide(client);
                else
                    AlQaeda_Bomber(client,war3player,ult_level,false);
            }
        }
    }
    ClearArray(temp);
}

public AlQaeda_Bomber(client,war3player,ult_level,bool:ondeath)
{
    m_Exploded[client]=true;

    new Float:radius;
    new r_int, damage;
    switch(ult_level)
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
    }

    if (ondeath)
    {
        damage = 300;
    }

    new Float:client_location[3];
    GetClientAbsOrigin(client,client_location);
    TE_SetupExplosion(client_location,explosionModel,10.0,30,0,r_int,20);
    TE_SendToAll();

    EmitSoundToAll(explodeWav,client);

    new clientCount = GetClientCount();
    for(new x=1;x<=clientCount;x++)
    {
        if (x != client && IsClientConnected(x) && IsPlayerAlive(x) &&
            GetClientTeam(x) != GetClientTeam(client))
        {
            new war3player_check=War3_GetWar3Player(x);
            if (war3player_check>-1)
            {
                if (!War3_GetImmunity(war3player_check,Immunity_Ultimates) &&
                    !War3_GetImmunity(war3player_check,Immunity_Explosion))
                {
                    new Float:location_check[3];
                    GetClientAbsOrigin(x,location_check);

                    new hp=PowerOfRange(client_location,radius,location_check,damage);
                    if (hp)
                    {
                        new newhealth = GetClientHealth(x)-hp;
                        if (newhealth <= 0)
                        {
                            newhealth=0;
                            new addxp=5+ult_level;
                            new newxp=War3_GetXP(war3player,raceID)+addxp;
                            War3_SetXP(war3player,raceID,newxp);

                            LogKill(client, x, "suicide_bomb", "Suicide Bomb", hp, addxp);
                        }
                        else
                        {
                            LogDamage(client, x, "suicide_bomb", "Suicide Bomb", hp);
                        }
                        SetHealth(x,newhealth);
                    }
                }
            }
        }
    }
}
