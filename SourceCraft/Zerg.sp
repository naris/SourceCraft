/**
 * vim: set ai et ts=4 sw=4 :
 * File: Zerg.sp
 * Description: The Zerg race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "hgrsource.inc"

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/range"
#include "sc/trace"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/log"

new raceID; // The ID we are assigned to

new g_haloSprite;
new g_lightningSprite;

new String:errorWav[PLATFORM_MAX_PATH] = "soundcraft/PError.wav"; // "player/suit_denydevice.wav";

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Zerg",
    author = "-=|JFH|=-Naris",
    description = "The Zerg race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    HookEvent("player_spawn",PlayerSpawnEvent);

    CreateTimer(3.0,Regeneration,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID=CreateRace("Zerg", "zerg",
                      "You are now part of the Zerg.",
                      "You will be part of the Zerg when you die or respawn.",
                      "Adrenal Glands",
                      "Increases Melee Attack Damage",
                      "Regeneration",
                      "Regenerates your Health.",
                      "Healing Aura",
                      "Regenerates Health of all teammates in range (It does NOT heal you).",
                      "Tentacles",
                      "Reach out and grab an opponent.");

    FindUberOffsets();
    FindMaxHealthOffset();

    ControlHookGrabRope(true);
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    SetupSound(errorWav,true);
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
            TakeGrab(client);
        else if (race == raceID)
        {
            new skill_tentacles=GetSkillLevel(player,race,3);
            if (skill_tentacles)
                Zerg_Tentacles(client, player, skill_tentacles);
        }
    }
}


public Action:Regeneration(Handle:timer)
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
                    new skill_regeneration=GetSkillLevel(player,raceID,1);
                    if (skill_regeneration)
                    {
                        new newhp=GetClientHealth(client)+skill_regeneration;
                        new maxhp=(GameType == tf2) ? GetMaxHealth(client) : 100;
                        if(newhp<=maxhp)
                            SetEntityHealth(client,newhp);
                    }

                    new skill_healing_aura=GetSkillLevel(player,raceID,2);
                    if (skill_healing_aura)
                    {
                        new num=skill_healing_aura*2;
                        new Float:range=1.0;
                        switch(skill_healing_aura)
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
                            if (index != client && IsClientInGame(index) && IsPlayerAlive(index) &&
                                GetClientTeam(index) == GetClientTeam(client))
                            {
                                new player_check=GetPlayer(index);
                                if (player_check>-1)
                                {
                                    if (IsInRange(client,index,range))
                                    {
                                        new Float:indexLoc[3];
                                        GetClientAbsOrigin(index, indexLoc);
                                        if (TraceTarget(client, index, clientLoc, indexLoc))
                                        {
                                            new color[4] = { 0, 0, 255, 255 };
                                            TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                    0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                            TE_SendToAll();

                                            new newhp=GetClientHealth(index)+skill_healing_aura;
                                            new maxhp=(GameType == tf2) ? GetMaxHealth(index) : 100;
                                            if(newhp<=maxhp)
                                                HealPlayer(index,newhp);

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
    return Plugin_Continue;
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            Grab(client);
        else
            Drop(client);
    }
}

public Action:OnGrab(client, target)
{
    if (target != client && IsClientInGame(target) && IsPlayerAlive(target) &&
        GetClientTeam(client) != GetClientTeam(target))
    {
        new player_check=GetPlayer(target);
        if (player_check>-1)
        {
            if (!GetImmunity(player_check,Immunity_Ultimates))
                return Plugin_Continue;
        }
    }
    EmitSoundToClient(client,errorWav);
    return Plugin_Stop;
}

public OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && newskilllevel > 0 && GetRace(player) == raceID && IsPlayerAlive(client))
    {
        if (skill==3)
            Zerg_Tentacles(client, player, newskilllevel);
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
                new skill_tentacles=GetSkillLevel(player,race,3);
                if (skill_tentacles)
                    Zerg_Tentacles(client, player, skill_tentacles);
            }
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,victim_player,victim_race,
                                attacker_index,attacker_player,attacker_race,
                                assister_index,assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    LogEventDamage(event, damage, "Zerg::PlayerHurtEvent", raceID);

    decl String:weapon[64] = "";
    new bool:is_equipment=GetWeapon(event,attacker_index,weapon,sizeof(weapon));
    if (IsMelee(weapon, is_equipment))
    {
        if (attacker_race == raceID && attacker_index != victim_index)
        {
            if (Zerg_AdrenalGlands(damage, victim_index, victim_player,
                                   attacker_index, attacker_player))
            {
                changed = true;
            }
        }

        if (assister_race == raceID && assister_index != victim_index)
        {
            if (Zerg_AdrenalGlands(damage, victim_index, victim_player,
                                   assister_index, assister_player))
            {
                changed = true;
            }
        }
    }
    return changed ? Plugin_Changed : Plugin_Continue;
}


public bool:Zerg_AdrenalGlands(damage, victim_index, victim_player, index, player)
{
    new skill_adrenal_glands=GetSkillLevel(player,raceID,0);
    if (skill_adrenal_glands)
    {
        if (!GetImmunity(victim_player,Immunity_HealthTake) &&
            !IsUber(victim_index))
        {
            new Float:percent;
            switch(skill_adrenal_glands)
            {
                case 1:
                    percent=0.20;
                case 2:
                    percent=0.55;
                case 3:
                    percent=0.75;
                case 4:
                    percent=1.00;
            }

            new amount=RoundFloat(float(damage)*percent);
            new newhp=GetClientHealth(victim_index)-amount;
            LogMessage("ZerAdrenal for %N, damage=%d,amount=%d", index, damage, amount);
            if (newhp <= 0)
            {
                newhp=0;
                LogKill(index, victim_index, "adrenal_glands", "Adrenal Glands", amount);
            }
            else
                LogDamage(index, victim_index, "adrenal_glands", "Adrenal Glands", amount);

            SetEntityHealth(victim_index,newhp);

            new Float:Origin[3];
            GetClientAbsOrigin(victim_index, Origin);
            Origin[2] += 5;

            TE_SetupSparks(Origin,Origin,255,1);
            TE_SendToAll();
            return true;
        }
    }
    return false;
}

public Zerg_Tentacles(client, player, skilllevel)
{
    if (skilllevel)
    {
        new duration, Float:range;
        switch(skilllevel)
        {
            case 1:
            {
                duration=5;
                range=150.0;
            }
            case 2:
            {
                duration=15;
                range=300.0;
            }
            case 3:
            {
                duration=30;
                range=450.0;
            }
            case 4:
            {
                duration=45;
                range=0.0;
            }
        }
        GiveGrab(client,duration,range,1);
    }
}
