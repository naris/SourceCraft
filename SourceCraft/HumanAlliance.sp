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

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/freeze"

new String:teleportWav[] = "ambient/machines/teleport1.wav"; //"beams/beamstart5.wav";
new String:rechargeWav[] = "sourcecraft/transmission.wav";

new raceID, immunityID, devotionID, bashID, teleportID;

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_VelocityOffset;

new Handle:cvarTeleportCooldown = INVALID_HANDLE;

new m_TeleportCount[MAXPLAYERS+1];
new Float:m_UltimatePressed[MAXPLAYERS+1];

new Float:spawnLoc[MAXPLAYERS+1][3];
new Float:teleportLoc[MAXPLAYERS+1][3];

new Float:gBashTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Human Alliance",
    author = "PimpinJuice",
    description = "The Human Alliance race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarTeleportCooldown=CreateConVar("sc_teleportcooldown","10");

    if (!HookEvent("player_spawn",PlayerSpawnEvent,EventHookMode_Post))
        SetFailState("Couldn't hook the player_spawn event.");
}

public OnPluginReady()
{
    raceID     = CreateRace("Human Alliance", "human",
                            "You are now part of the Human Alliance.",
                            "You will be part of the Human Alliance when you die or respawn.");

    immunityID = AddUpgrade(raceID,"Immunity", "immunity",
                            "Makes you Immune to: ShopItems at Level 1,\nExplosions at Level 2,\nHealthTaking at level 3,\nand Ultimates at Level 4.");

    devotionID = AddUpgrade(raceID,"Devotion Aura", "devotion",
                            "Gives you additional 15-50 health each round.");

    bashID     = AddUpgrade(raceID,"Bash", "bash", 
                            "Gives you a 15-32\% chance to render an \nenemy immobile for 1 second.");

    teleportID = AddUpgrade(raceID,"Teleport", "teleport",
                            "Allows you to teleport to where you \naim, 60-105 feet being the range.",
                            true); // Ultimate

    m_VelocityOffset = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
    if(m_VelocityOffset == -1)
        SetFailState("[SourceCraft] Error finding Velocity offset.");
}

public OnMapStart()
{
    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt", true);
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    SetupSound(teleportWav, true, true);
    SetupSound(rechargeWav, true, true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    m_TeleportCount[client]=0;
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            m_TeleportCount[client]=0;
            ResetMaxHealth(client);

            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,false);
        }
        else if (race == raceID)
        {
            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,true);

            new devotion_level=GetUpgradeLevel(player,race,devotionID);
            if (devotion_level)
                DevotionAura(client, devotion_level);
        }
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        new ult_level=GetUpgradeLevel(player,race,teleportID);
        if(ult_level)
        {
            if (pressed)
                m_UltimatePressed[client] = GetGameTime();
            else
            {
                if (m_TeleportCount[client] < 2)
                {
                    new bool:toSpawn = false;
                    if (m_TeleportCount[client] >= 1)
                    {
                        // Check to see if player got stuck with 1st teleport
                        new Float:origin[3];
                        GetClientAbsOrigin(client, origin);
                        if (origin[0] == teleportLoc[client][0] &&
                            origin[1] == teleportLoc[client][1] &&
                            origin[2] == teleportLoc[client][2])
                        {
                            toSpawn = true; // If player is stuck, allow teleport to spawn.
                            PrintToChat(client,"%c[SourceCraft]%c You appear to be stuck, teleporting back to spawn.",
                                        COLOR_GREEN,COLOR_DEFAULT);
                        }
                        else
                        {
                            PrintToChat(client,"%c[SourceCraft]%c Sorry, your %cTeleport%c has not recharged yet.",
                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            return;
                        }
                    }
                    Teleport(client,ult_level, toSpawn, GetGameTime() - m_UltimatePressed[client]);
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

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && new_level > 0 && GetRace(player) == raceID)
    {
        if (upgrade == 0)
            DoImmunity(client, player, new_level,true);
        else if (upgrade == 1)
            DevotionAura(client, new_level);
    }
}

// Events
public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            if (GetRace(player) == raceID)
            {
                GetClientAbsOrigin(client,spawnLoc[client]);
                m_TeleportCount[client]=0;

                new immunity_level=GetUpgradeLevel(player,raceID,immunityID);
                if (immunity_level)
                    DoImmunity(client, player, immunity_level,true);

                new devotion_level=GetUpgradeLevel(player,raceID,devotionID);
                if (devotion_level)
                    AuthTimer(0.1,client,DoDevotionAura);
            }
        }
    }
    return Plugin_Continue;
}

public Action:DoDevotionAura(Handle:timer,Handle:pack)
{
    new client=ClientOfAuthTimer(pack);
    if(client)
    {
        SaveMaxHealth(client);
        DevotionAura(client, GetUpgradeLevel(GetPlayerHandle(client),raceID,devotionID));
    }
    return Plugin_Stop;
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    // Reset MaxHealth back to normal
    if (victim_race == raceID)
        ResetMaxHealth(victim_index);

    return Plugin_Continue;
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    if (attacker_index && attacker_index != victim_index)
    {
        if (attacker_race == raceID)
            Bash(victim_index, attacker_player);
    }

    if (assister_index && assister_index != victim_index)
    {
        if (assister_race == raceID)
            Bash(victim_index, assister_player);
    }
    return Plugin_Continue;
}

DoImmunity(client, Handle:player, level, bool:value)
{
    if (level >= 1)
    {
        SetImmunity(player,Immunity_ShopItems,value);
        if (level >= 2)
        {
            SetImmunity(player,Immunity_Explosion,value);
            if (level >= 3)
            {
                SetImmunity(player,Immunity_HealthTake,value);
                if (level >= 4)
                    SetImmunity(player,Immunity_Ultimates,value);
            }
        }

        if (value)
        {
            new Float:start[3];
            GetClientAbsOrigin(client, start);

            new color[4] = { 0, 255, 50, 128 };
            TE_SetupBeamRingPoint(start,30.0,60.0,g_lightningSprite,g_lightningSprite,
                                  0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
            TE_SendToAll();
        }
    }
}

DevotionAura(client, level)
{
    if (client &&  IsClientInGame(client))
    {
        new hpadd;
        switch(level)
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

        PrintToChat(client,"%c[SourceCraft]%c You have received %d extra hp from %cDevotion Aura%c.",
                   COLOR_GREEN,COLOR_DEFAULT,hpadd,COLOR_TEAM,COLOR_DEFAULT);

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

Bash(victim_index, Handle:player)
{
    new upgrade_bash=GetUpgradeLevel(player,raceID,bashID);
    if (upgrade_bash)
    {
        // Bash
        new percent;
        switch(upgrade_bash)
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
        if (GetRandomInt(1,100)<=percent &&
            (!gBashTime[victim_index] ||
             GetGameTime() - gBashTime[victim_index] > 2.0))
        {
            new Float:Origin[3];
            GetClientAbsOrigin(victim_index, Origin);
            TE_SetupGlowSprite(Origin,g_lightningSprite,1.0,2.3,90);

            gBashTime[victim_index] = GetGameTime();
            FreezeEntity(victim_index);
            AuthTimer(1.0,victim_index,UnfreezePlayer);
        }
    }
}

Teleport(client,ult_level, bool:to_spawn, Float:time_pressed)
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
        if (time_pressed > 2.0 || time_pressed <= 0.0)
            time_pressed = 2.0;

        new Float:range=1.0;
        switch(ult_level)
        {
            case 1:
                range=(time_pressed / 2.0) * 300.0;
            case 2:
                range=(time_pressed / 2.0) * 500.0;
            case 3:
                range=(time_pressed / 2.0) * 800.0;
            case 4:
                range=(time_pressed / 2.0) * 1500.0;
        }

        new Float:clientloc[3],Float:clientang[3];
        GetClientEyePosition(client,clientloc);
        GetClientEyeAngles(client,clientang);
        TR_TraceRayFilterEx(clientloc,clientang,MASK_SHOT,RayType_Infinite,TraceRayTryToHit);
        TR_GetEndPosition(destloc);

        new Float:size[3];
        GetClientMaxs(client, size);
        size[0] += 5.0;
        size[1] += 5.0;
        size[2] += 5.0;

        if (TR_DidHit())
        {
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

            /*
            new Float:dist = (GetVectorDistance(clientloc, destloc) - size[1]);
            destloc[1] = (clientloc[1] + (dist * Sine(DegToRad(clientang[1]))));
            destloc[0] = (clientloc[0] + (dist * Cosine(DegToRad(clientang[1]))));
            */
        }

        if (range > 0.0 && DistanceBetween(clientloc,destloc) > range)
        {
            // Limit the teleport location to remain within the range
            destloc[1] = (clientloc[1] + (range * Sine(DegToRad(clientang[1]))));
            destloc[0] = (clientloc[0] + (range * Cosine(DegToRad(clientang[1]))));
            /*
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
            */

            // Check if new coordinates get you stuck!
            TR_TraceRayFilter(clientloc,destloc,MASK_SHOT,RayType_EndPoint,TraceRayTryToHit);
            if (TR_DidHit())
            {
                TR_GetEndPosition(destloc);

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

                /*
                new Float:dist = (GetVectorDistance(clientloc, destloc) - size[1]);
                destloc[1] = (clientloc[1] + (dist * Sine(DegToRad(clientang[1]))));
                destloc[0] = (clientloc[0] + (dist * Cosine(DegToRad(clientang[1]))));
                */
            }
        }

        //Check ceiling
        decl Float:ceiling[3];
        ceiling = destloc;
        ceiling[2] -= size[2];
        if(TR_GetPointContents(ceiling) == 0)
            destloc[2] = ceiling[2];

        // Save teleport location for stuck comparison later
        teleportLoc[client][0] = destloc[0];
        teleportLoc[client][1] = destloc[1];
        teleportLoc[client][2] = destloc[2];
    }

    TeleportEntity(client,destloc,NULL_VECTOR,NULL_VECTOR);
    EmitSoundToAll(teleportWav,client);

    TE_SetupSmoke(destloc,g_smokeSprite,40.0,1);
    TE_SendToAll();

    m_TeleportCount[client]++;

    new Float:cooldown = GetConVarFloat(cvarTeleportCooldown) * (5-ult_level);
    PrintToChat(client,"%c[SourceCraft]%c %cTeleport%cing, you must wait %2.0f seconds before teleporting again!",
                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);

    if (!to_spawn)
    {
        if (cooldown > 0.0)
            CreateTimer(cooldown,AllowTeleport,client);
    }
}

public Action:AllowTeleport(Handle:timer,any:index)
{
    m_TeleportCount[index]=0;
    if(IsClientInGame(index))
    {
        new Handle:player = GetPlayerHandle(index);
        if (GetRace(player) == raceID && IsPlayerAlive(index))
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft]%c Your %cTeleport%c has recharged and can be used again.",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
        }
    }
    return Plugin_Stop;
}
