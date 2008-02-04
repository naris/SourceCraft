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

#include "sc/log" // for debugging

new raceID; // The ID we are assigned to

new g_smokeSprite;
new g_lightningSprite;

new bool:m_AllowNuclearLaunch[MAXPLAYERS+1];
new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

new m_OffsetCloakMeter[MAXPLAYERS+1];

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
                      "Freezes an enemy when he shoots you, or when you shoot him.",
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
    if (race==raceID && m_AllowNuclearLaunch[client] &&
        IsPlayerAlive(client))
    {
        if (pressed)
            LaunchNuclearDevice(client);
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
        // Set CloakMeter up for ALL races (it's needed for victims) Mwuhaha!!
        m_OffsetCloakMeter[client]=FindDataMapOffs(client,"m_flCloakMeter");

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

    if (victim_index)
    {
        // Reset invisibility
        if (victim_player != -1)
        {
            SetMinVisibility(victim_player, 255, 1.0, 1.0);
        }

    }
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
                                                new Float:cloakMeter = GetEntDataFloat(index,m_OffsetCloakMeter[index]);
                                                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                                {
                                                    SetEntDataFloat(index,m_OffsetCloakMeter[index], 0.0);
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

NuclearExplosion(player,client,ultlevel)
{
    new dmg;
    new num=ultlevel*2;
    new Float:range=1.0;
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
                if (!GetImmunity(player_check,Immunity_Ultimates))
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
    EmitSoundToAll(thunderWav,client);
    new Float:cooldown = GetConVarFloat(cvarChainCooldown);
    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cChained Lightning%c to damage %d enemies, you now need to wait %3.1f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
    if (cooldown > 0.0)
    {
        m_AllowChainLightning[client]=false;
        CreateTimer(cooldown,AllowChainLightning,client);
    }
}
