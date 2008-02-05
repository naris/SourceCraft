/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranGhost.sp
 * Description: The Terran Ghost race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <tf2>

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/health"
#include "sc/range"
#include "sc/trace"
#include "sc/freeze"
#include "sc/authtimer"

#include "sc/log" // for debugging

new raceID; // The ID we are assigned to

new explosionModel;
new g_smokeSprite;
new g_lightningSprite;

new m_OffsetCloakMeter;
new m_OffsetDisguiseTeam;
new m_OffsetDisguiseClass;
new m_OffsetDisguiseHealth;

new Handle:cvarNuclearLaunchTime = INVALID_HANDLE;
new Handle:cvarNuclearLockTime = INVALID_HANDLE;
new Handle:cvarNuclearCooldown = INVALID_HANDLE;

new bool:m_AllowNuclearLaunch[MAXPLAYERS+1];
new bool:m_NuclearLaunchInitiated[MAXPLAYERS+1];

new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

new String:launchWav[] = "weapons/explode5.wav";
new String:explodeWav[] = "weapons/explode5.wav";

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Ghost",
    author = "-=|JFH|=-Naris",
    description = "The Terran Ghost race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarNuclearLaunchTime=CreateConVar("sc_nuclearlaunchtime","20");
    cvarNuclearLockTime=CreateConVar("sc_nuclearlocktime","5");
    cvarNuclearCooldown=CreateConVar("sc_nuclearlaunchcooldown","300");

    HookEvent("player_spawn",PlayerSpawnEvent);

    CreateTimer(2.0,OcularImplants,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID=CreateRace("Terran Ghost", "ghost",
                      "You are now a Terran Ghost.",
                      "You will be a Terran Ghost when you die or respawn.",
                      "Personal Cloaking Device",
                      "Makes you partially invisible, \n62% visibility - 37% visibility.\nTotal Invisibility when standing still",
                      "Lockdown",
                      "Have a 15-52\% chance to render an \nenemy immobile for 1 second.",
                      "Ocular Implants",
                      "Detect cloaked units around you.",
                      "Nuclear Launch",
                      "Launches a Nuclear Device that does extreme damage to all players in the area.",
                      "32");
}

public OnMapStart()
{
    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    if (GameType == tf2)
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt");
    else
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");

    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    if (GameType == tf2)
    {
        m_OffsetCloakMeter=FindSendPropInfo("CTFPlayer","m_flCloakMeter");
        if (m_OffsetCloakMeter == -1)
            SetFailState("Couldn't find CloakMeter Offset");

        m_OffsetDisguiseTeam=FindSendPropInfo("CTFPlayer","m_nDisguiseTeam");
        if (m_OffsetDisguiseTeam == -1)
            SetFailState("Couldn't find DisguiseTeam Offset");

        m_OffsetDisguiseClass=FindSendPropInfo("CTFPlayer","m_nDisguiseClass");
        if (m_OffsetDisguiseClass == -1)
            SetFailState("Couldn't find DisguiseClass Offset");

        m_OffsetDisguiseHealth=FindSendPropInfo("CTFPlayer","m_iDisguiseHealth");
        if (m_OffsetDisguiseHealth == -1)
            SetFailState("Couldn't find DisguiseHealth Offset");
    }

    SetupSound(explodeWav);
}

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
    m_AllowNuclearLaunch[client]=true;
}

public OnClientDisconnect(client)
{
    ResetOcularImplants(client);
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            SetMinVisibility(player, 255, 1.0, 1.0);
            ResetOcularImplants(client);
            m_AllowNuclearLaunch[client]=true;
        }
        else if (race == raceID)
        {
            new skill_cloak=GetSkillLevel(player,race,0);
            if (skill_cloak)
                Cloak(client, player, skill_cloak);
        }
    }
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && pressed && m_AllowNuclearLaunch[client] &&
        IsPlayerAlive(client))
    {
        new ult_level=GetSkillLevel(player,race,3);
        if(ult_level)
            LaunchNuclearDevice(client,player);
    }
}

public OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel)
{
    if (race == raceID && newskilllevel > 0 && GetRace(player) == raceID)
    {
        if (skill==0)
            Cloak(client, player, newskilllevel);
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new player=GetPlayer(client);
        if (player>-1)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new skill_cloak=GetSkillLevel(player,race,0);
                if (skill_cloak)
                    Cloak(client, player, skill_cloak);
            }
        }
    }
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,victim_player,victim_race,
                                 attacker_index,attacker_player,attacker_race,
                                 assister_index,assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    LogEventDamage(event, damage, "TerranGhost::PlayerDeathEvent", raceID);

    if (victim_player != -1 && victim_race == raceID)
    {
        SetMinVisibility(victim_player, 255, 1.0, 1.0);

        if (m_NuclearLaunchInitiated[victim_index])
        {
            m_NuclearLaunchInitiated[victim_index]=false;
            SetOverrideSpeed(victim_player, 1.0);
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,victim_player,victim_race,
                                attacker_index,attacker_player,attacker_race,
                                assister_index,assister_player,assister_race,
                                damage)
{
    LogEventDamage(event,damage,"TerranGhost::PlayerHurtEvent", raceID);

    if (attacker_index && attacker_index != victim_index)
    {
        if (victim_race == raceID)
            LockDown(attacker_index, victim_player);

        if (attacker_race == raceID)
            LockDown(victim_index, attacker_player);
    }

    if (assister_index && assister_index != victim_index)
    {
        if (assister_race == raceID)
            LockDown(victim_index, assister_player);
    }
    return Plugin_Continue;
}

bool:Cloak(client, player, skilllevel)
{
    new alpha;
    switch(skilllevel)
    {
        case 1:
            alpha=210;
        case 2:
            alpha=190;
        case 3:
            alpha=170;
        case 4:
            alpha=150;
    }

    /* If the Player also has the Cloak of Shadows,
     * Decrease the visibility further
     */
    new cloak = GetShopItem("Cloak of Shadows");
    if (cloak != -1 && GetOwnsItem(player,cloak))
    {
        alpha *= 0.90;
    }

    new Float:start[3];
    GetClientAbsOrigin(client, start);

    new color[4] = { 0, 255, 50, 128 };
    TE_SetupBeamRingPoint(start,30.0,60.0,g_lightningSprite,g_lightningSprite,
                          0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
    TE_SendToAll();

    SetMinVisibility(player,alpha, 0.80, 0.0);
}

LockDown(victim_index, player)
{
    new skill_lockdown=GetSkillLevel(player,raceID,1);
    if (skill_lockdown)
    {
        new percent;
        switch(skill_lockdown)
        {
            case 1:
                percent=15;
            case 2:
                percent=21;
            case 3:
                percent=37;
            case 4:
                percent=52;
        }
        if (GetRandomInt(1,100)<=percent)
        {
            new Float:Origin[3];
            GetClientAbsOrigin(victim_index, Origin);
            TE_SetupGlowSprite(Origin,g_lightningSprite,1.0,2.3,90);

            FreezeEntity(victim_index);
            AuthTimer(1.0,victim_index,UnfreezePlayer);
        }
    }
}

public Action:OcularImplants(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                new player=GetPlayer(client);
                if(player>=0 && GetRace(player) == raceID)
                {
                    new Float:detecting_range;
                    new skill_detecting=GetSkillLevel(player,raceID,2);
                    if (skill_detecting)
                    {
                        switch(skill_detecting)
                        {
                            case 1:
                                detecting_range=300.0;
                            case 2:
                                detecting_range=450.0;
                            case 3:
                                detecting_range=650.0;
                            case 4:
                                detecting_range=800.0;
                        }
                    }

                    new Float:clientLoc[3];
                    GetClientAbsOrigin(client, clientLoc);
                    for (new index=1;index<=maxplayers;index++)
                    {
                        if (index != client && IsClientInGame(index))
                        {
                            if (IsPlayerAlive(index))
                            {
                                new player_check=GetPlayer(index);
                                if (player_check>-1)
                                {
                                    decl String:clientName[64];
                                    GetClientName(client,clientName,63);

                                    decl String:name[64];
                                    GetClientName(index,name,63);

                                    if (GetClientTeam(index) != GetClientTeam(client))
                                    {
                                        new bool:detect = IsInRange(client,index,detecting_range);
                                        if (detect)
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            detect = TraceTarget(client, index, clientLoc, indexLoc);
                                        }
                                        if (detect)
                                        {
                                            SetOverrideVisible(player_check, 255);
                                            if (TF_GetClass(player_check) == TF2_SPY)
                                            {
                                                new Float:cloakMeter = GetEntDataFloat(index,m_OffsetCloakMeter);
                                                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                                {
                                                    SetEntDataFloat(index,m_OffsetCloakMeter, 0.0);
                                                }

                                                new disguiseTeam = GetEntData(index,m_OffsetDisguiseTeam);
                                                if (disguiseTeam != 0)
                                                {
                                                    SetEntData(index,m_OffsetDisguiseTeam, 0);
                                                    SetEntData(index,m_OffsetDisguiseClass, 0);
                                                    SetEntData(index,m_OffsetDisguiseHealth, 0);
                                                }
                                            }
                                            m_Detected[client][index] = true;
                                        }
                                        else if (m_Detected[client][index])
                                        {
                                            SetOverrideVisible(player_check, -1);
                                            m_Detected[client][index] = false;
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

ResetOcularImplants(client)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        new player = GetPlayer(index);
        if (player > -1)
        {
            if (m_Detected[client][index])
            {
                SetOverrideVisible(player, -1);
                m_Detected[client][index] = false;
            }
        }
    }
}

LaunchNuclearDevice(client,player)
{
    EmitSoundToAll(launchWav,client);
    SetOverrideSpeed(player, 0.0);

    new Float:launchTime = GetConVarFloat(cvarNuclearLaunchTime);
    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c, you must now wait %3.1f seconds for the missle to lock on.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, launchTime);
    m_AllowNuclearLaunch[client]=false;
    m_NuclearLaunchInitiated[client]=true;
    CreateTimer(launchTime,NuclearLockOn,client);
}

public Action:NuclearLockOn(Handle:timer,any:client)
{
    new player = GetPlayer(client);
    if (m_NuclearLaunchInitiated[client])
    {
        SetOverrideSpeed(player, 1.0);
        new Float:lockTime = GetConVarFloat(cvarNuclearLockTime);
        PrintToChat(client,"%c[SourceCraft]%c The missle has locked on, you have %3.1f seconds to evacuate.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, lockTime);
        CreateTimer(lockTime,NuclearExplosion,client);
    }
    else
    {
        new Float:cooldown = GetConVarFloat(cvarNuclearCooldown);
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c without effect, you now need to wait %3.1f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
        CreateTimer(cooldown,AllowNuclearLaunch,client);
    }
}

public Action:NuclearExplosion(Handle:timer,any:client)
{
    new num    = 0;
    new player = GetPlayer(client);
    if (m_NuclearLaunchInitiated[client] && player != -1)
    {
        new Float:radius;
        new r_int;
        new ult_level=GetSkillLevel(player,raceID,3);
        switch(ult_level)
        {
            case 1:
                {
                    radius = 300.0;
                    r_int  = 300;
                }
            case 2:
                {
                    radius = 450.0;
                    r_int  = 450;
                }
            case 3:
                {
                    radius = 600.0;
                    r_int  = 600;
                }
            case 4:
                {
                    radius = 850.0;
                    r_int  = 850;
                }
        }

        new Float:client_location[3];
        GetClientAbsOrigin(client,client_location);

        TE_SetupExplosion(client_location,explosionModel,10.0,30,0,r_int,20);
        TE_SendToAll();
        EmitSoundToAll(explodeWav,client);

        new count = GetClientCount();
        for(new index=1;index<=count;index++)
        {
            if (IsClientInGame(index) && IsPlayerAlive(index))
            {
                new check_player=GetPlayer(index);
                if (check_player>-1)
                {
                    if (!GetImmunity(check_player,Immunity_Ultimates) &&
                            !GetImmunity(check_player,Immunity_Explosion))
                    {
                        new Float:check_location[3];
                        GetClientAbsOrigin(index,check_location);

                        new hp=PowerOfRange(client_location,radius,check_location,600);
                        if (hp)
                        {
                            if (TraceTarget(client, index, client_location, check_location))
                            {
                                new newhealth = GetClientHealth(index)-hp;
                                if (newhealth <= 0)
                                {
                                    newhealth=0;
                                    new addxp=5+ult_level;
                                    new newxp=GetXP(player,raceID)+addxp;
                                    SetXP(player,raceID,newxp);

                                    //LogKill(client, index, "nuclear_launch", "Nuclear Launch", hp, addxp);
                                    KillPlayer(index,client,"nuclear_launch");
                                }
                                else
                                {
                                    LogDamage(client, index, "nuclear_launch", "Nuclear Launch", hp);
                                    HurtPlayer(index,hp,client,"nuclear_launch");
                                }
                                num++;
                            }
                        }
                    }
                }
            }
        }
    }
    new Float:cooldown = GetConVarFloat(cvarNuclearCooldown);
    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cNuclear Launch%c to damage %d enemies, you now need to wait %3.1f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, num, cooldown);
    CreateTimer(cooldown,AllowNuclearLaunch,client);

}

public Action:AllowNuclearLaunch(Handle:timer,any:index)
{
    m_AllowNuclearLaunch[index]=true;
    return Plugin_Stop;
}

