/**
 * vim: set ai et ts=4 sw=4 :
 * File: HumanAlliance.sp
 * Description: The Human Alliance race for SourceCraft.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/health"
#include "War3Source/freeze"
#include "War3Source/authtimer"

new raceID; // The ID we are assigned to

new String:teleportWav[] = "beams/beamstart5.wav";

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_VelocityOffset;

new Handle:cvarTeleportCooldown = INVALID_HANDLE;

new m_TeleportCount[MAXPLAYERS+1];
new m_UltimatePressed[MAXPLAYERS+1];

new Float:spawnLoc[MAXPLAYERS+1][3];

public Plugin:myinfo = 
{
    name = "War3Source Race - Human Alliance",
    author = "PimpinJuice",
    description = "The Human Alliance race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarTeleportCooldown=CreateConVar("war3_teleportcooldown","30");

    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_hurt",PlayerHurtEvent);

    if (GameType == tf2)
        HookEvent("player_changeclass",PlayerChangeClassEvent);
}

public OnPluginReady()
{
    raceID=CreateRace("Human Alliance", "human",
                      "You are now part of the Human Alliance.",
                      "You will be part of the Human Alliance when you die or respawn.",
                      "Invisibility",
                      "Makes you partially invisible, \n62% visibility - 37% visibility.",
                      "Devotion Aura",
                      "Gives you additional 15-50 health each round.",
                      "Bash",
                      "Have a 15-32% chance to render an \nenemy immobile for 1 second.",
                      "Teleport",
                      "Allows you to teleport to where you \naim, 60-105 feet being the range.");

    FindMoveTypeOffset();

    m_VelocityOffset = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
    if(m_VelocityOffset == -1)
        SetFailState("[SourceCraft] Error finding Velocity offset.");
}

public OnMapStart()
{
    SetupSound(teleportWav);

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");
}


public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
    m_TeleportCount[client]=0;
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
    {
        m_TeleportCount[client]=0;

        // Reset MaxHealth back to normal
        if (healthIncreased[client] && GameType == tf2)
        {
            SetMaxHealth(client, maxHealth[client]);
            healthIncreased[client] = false;
        }

        // Reset invisibility
        if (player != -1)
        {
            SetMinVisibility(player, 255, 1.0);
        }
    }
}


public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        new ult_level=GetSkillLevel(player,race,3);
        if(ult_level)
        {
            if (pressed)
                m_UltimatePressed[client] = GetSysTickCount();
            else
            {
                if (m_TeleportCount[client] < 2)
                {
                    new bool:toSpawn = false;
                    if (m_TeleportCount[client] >= 1)
                    {
                        new Float:vecVelocity[3];
                        GetEntDataVector(client, m_VelocityOffset, vecVelocity);
                        if (vecVelocity[0] == 0.0 && vecVelocity[1] == 0.0 &&
                            (vecVelocity[2] >= -10.0 && vecVelocity[2] <= 10.0))
                        {
                            toSpawn = true;
                        }
                        else
                        {
                            PrintToChat(client,"%c[SourceCraft]%c Sorry, your %cTeleport%c has not recharged yet.",
                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            return;
                        }
                    }

                    PrintToChat(client,"%c[SourceCraft]%c %cTeleport%cing!",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                    HumanAlliance_Teleport(client,player,ult_level, toSpawn,
                                           GetSysTickCount() - m_UltimatePressed[client]);
                    if (!toSpawn)
                    {
                        new Float:cooldown = GetConVarFloat(cvarTeleportCooldown);
                        if (cooldown > 0.0)
                            CreateTimer(cooldown,AllowTeleport,client);
                    }
                }
                else
                {
                    PrintToChat(client,"%c[SourceCraft]%c Sorry, your %cTeleport%c has not recharged yet!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                }
            }
        }
    }
}

public Action:AllowTeleport(Handle:timer,any:index)
{
    m_TeleportCount[index]=0;
    PrintToChat(index,"%c[SourceCraft]%c Your %cTeleport%c has recharged and can be used again.",
                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
    return Plugin_Stop;
}

public OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && skill==0 && newskilllevel > 0 &&
       GetRace(player) == raceID && IsPlayerAlive(client))
    {
        HumanAlliance_Invisibility(client, player, newskilllevel);
    }
}

public OnItemPurchase(client,player,item)
{
    new race=GetRace(player);
    if (race == raceID && IsPlayerAlive(client))
    {
        new cloak = GetShopItem("Cloak of Shadows");
        if (cloak == item)
        {
            new skill_invis=GetSkillLevel(player,race,0);
            HumanAlliance_Invisibility(client, player, skill_invis);
        }
    }
}

// Events
public PlayerChangeClassEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
        ResetMaxHealth(client);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        SetupMaxHealth(client);
        GetClientAbsOrigin(client,spawnLoc[client]);
        m_TeleportCount[client]=0;

        new player=GetPlayer(client);
        if (player>-1)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new skill_invis=GetSkillLevel(player,race,0);
                if (skill_invis)
                {
                    HumanAlliance_Invisibility(client, player, skill_invis);
                }

                new skill_devo=GetSkillLevel(player,race,1);
                if (skill_devo)
                {
                    // Devotion Aura
                    new hpadd;
                    switch(skill_devo)
                    {
                        case 1:
                            hpadd=15;
                        case 2:
                            hpadd=26;
                        case 3:
                            hpadd=38;
                        case 4:
                            hpadd=50;
                    }
                    IncreaseHealth(client,hpadd);

                    new Float:start[3];
                    GetClientAbsOrigin(client, start);

                    new Float:end[3];
                    end[0] = start[0];
                    end[1] = start[1];
                    end[2] = start[2] + 150;

                    new color[4] = { 200, 255, 205, 255 };
                    TE_SetupBeamPoints(start,end,g_lightningSprite,g_haloSprite,
                                       0, 1, 2.0, 40.0, 10.0 ,5,50.0,color,255);
                    TE_SendToAll();
                }
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);

    if (client)
    {
        // Reset MaxHealth back to normal
        if (healthIncreased[client] && GameType == tf2)
        {
            SetMaxHealth(client, maxHealth[client]);
            healthIncreased[client] = false;
        }

        // Reset invisibility
        new player=GetPlayer(client);
        if (player != -1)
        {
            SetMinVisibility(player, 255, 1.0);
        }
    }
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid=GetEventInt(event,"userid");
    if (victimUserid)
    {
        new victimIndex      = GetClientOfUserId(victimUserid);
        new victimWar3player = GetPlayer(victimIndex);
        if (victimWar3player != -1)
        {
            new attackerUserid = GetEventInt(event,"attacker");
            if (attackerUserid && victimUserid != attackerUserid)
            {
                new attackerIndex      = GetClientOfUserId(attackerUserid);
                new attackerWar3player = GetPlayer(attackerIndex);
                if (attackerWar3player != -1)
                {
                    if (GetRace(attackerWar3player) == raceID)
                        HumanAlliance_Bash(attackerWar3player, victimIndex);
                }
            }

            new assisterUserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisterUserid != 0)
            {
                new assisterIndex      = GetClientOfUserId(assisterUserid);
                new assisterWar3player = GetPlayer(assisterIndex);
                if (assisterWar3player != -1)
                {
                    if (GetRace(assisterWar3player) == raceID)
                        HumanAlliance_Bash(assisterWar3player, victimIndex);
                }
            }
        }
    }
}

public HumanAlliance_Invisibility(client, player, skilllevel)
{
    new alpha;
    switch(skilllevel)
    {
        case 1:
            alpha=158;
        case 2:
            alpha=137;
        case 3:
            alpha=115;
        case 4:
            alpha=100; // 94;
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

    SetMinVisibility(player,alpha, 0.90, 1.0);
}

public HumanAlliance_Bash(player, victim)
{
    new skill_bash=GetSkillLevel(player,raceID,2);
    if (skill_bash)
    {
        // Bash
        new percent;
        switch(skill_bash)
        {
            case 1:
                percent=15;
            case 2:
                percent=21;
            case 3:
                percent=27;
            case 4:
                percent=32;
        }
        if (GetRandomInt(1,100)<=percent)
        {
            new Float:Origin[3];
            GetClientAbsOrigin(victim, Origin);
            TE_SetupGlowSprite(Origin,g_lightningSprite,1.0,2.3,90);

            FreezeEntity(victim);
            AuthTimer(1.0,victim,UnfreezePlayer);
        }
    }
}

public HumanAlliance_Teleport(client,player,ult_level, bool:to_spawn, time_pressed)
{
    new Float:origin[3];
    GetClientAbsOrigin(client, origin);
    TE_SetupSmoke(origin,g_smokeSprite,40.0,1);
    TE_SendToAll();

    new Float:destloc[3];
    if (to_spawn)
    {
        destloc[0]=spawnLoc[client][0];
        destloc[1]=spawnLoc[client][1];
        destloc[2]=spawnLoc[client][2];
    }
    else
    {
        if (time_pressed > 3000)
            time_pressed = 3000;

        new Float:range=1.0;
        switch(ult_level)
        {
            case 1:
                range=(float(time_pressed) / 3000.0) * 100.0;
            case 2:
                range=(float(time_pressed) / 3000.0) * 250.0;
            case 3:
                range=(float(time_pressed) / 3000.0) * 450.0;
            case 4:
                range=(float(time_pressed) / 3000.0) * 600.0;
        }

        new Float:clientloc[3],Float:clientang[3];
        GetClientEyePosition(client,clientloc);
        GetClientEyeAngles(client,clientang);
        TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite,TraceRayTryToHit);
        TR_GetEndPosition(destloc);

        if (TR_DidHit())
        {
            new Float:size[3];
            GetClientMaxs(client, size);
            if (destloc[0] > clientloc[0])
                destloc[0] -= size[0];
            else
                destloc[0] += size[0];

            if (destloc[1] > clientloc[1])
                destloc[1] -= size[1];
            else
                destloc[1] += size[1];

            if (destloc[2] > clientloc[2])
                destloc[2] -= size[2];
            else
                destloc[2] += size[2];
        }
        else
        {
            new Float:distance[3];
            distance[0] = destloc[0]-clientloc[0];
            distance[1] = destloc[1]-clientloc[1];
            distance[2] = destloc[2]-clientloc[2];
            if (distance[0] < 0)
                distance[0] *= -1;
            if (distance[1] < 0)
                distance[1] *= -1;
            if (distance[2] < 0)
                distance[2] *= -1;

            // Limit the teleport location to remain within the range
            for (new i = 0; i<=2; i++)
            {
                if (distance[i] > range)
                {
                    if (clientloc[i] >= 0)
                    {
                        if (destloc[i] >= 0)
                        {
                            if (clientloc[i] <= destloc[i])
                                destloc[i] = clientloc[i] + range;
                            if (clientloc[i] > destloc[i])
                                destloc[i] = clientloc[i] - range;
                        }
                        else
                            destloc[i] = clientloc[i] - range;
                    }
                    else
                    {
                        if (destloc[i] < 0)
                        {
                            if (clientloc[i] <= destloc[i])
                                destloc[i] = clientloc[i] + range;
                            if (clientloc[i] > destloc[i])
                                destloc[i] = clientloc[i] - range;
                        }
                        else
                            destloc[i] = clientloc[i] + range;
                    }
                }
            }
        }
    }

    TeleportEntity(client,destloc,NULL_VECTOR,NULL_VECTOR);
    EmitSoundToAll(teleportWav,client);

    TE_SetupSmoke(destloc,g_smokeSprite,40.0,1);
    TE_SendToAll();

    m_TeleportCount[client]++;
}

/***************
 *Trace Filters*
****************/

public bool:TraceRayTryToHit(entity,mask)
{
  // Check if the beam hit a player and tell it to keep tracing if it did
  return (entity < 0 || entity >= 64);
}
