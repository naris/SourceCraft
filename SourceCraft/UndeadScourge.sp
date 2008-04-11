/**
 * vim: set ai et ts=4 sw=4 :
 * File: UndeadScourge.sp
 * Description: The Undead Scourge race for SourceCraft.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "sc/SourceCraft"
#include "sc/tf2_player"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/log"

new String:explodeWav[] = "weapons/explode5.wav";

new raceID, vampiricID, unholyID, levitationID, suicideID;

new explosionModel;
new g_beamSprite;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

// Suicide bomber check
new bool:m_Suicided[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Undead Scourge",
    author = "PimpinJuice",
    description = "The Undead Scourge race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

// War3Source Functions
public OnPluginStart()
{
    GetGameType();

    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnPluginReady()
{
    raceID       = CreateRace("Undead Scourge", "undead",
                              "You are now an Undead Scourge.",
                              "You will be an Undead Scourge when you die or respawn.");

    vampiricID   = AddUpgrade(raceID,"Vampiric Aura", "vampiric_aura",
                              "Gives you a 60% chance to gain 12-30% of the\ndamage you did in attack, back as health. It can\nbe blocked if the player is immune.");

    unholyID     = AddUpgrade(raceID,"Unholy Aura", "unholy_aura",
                              "Gives you a speed boost, 8-36% faster.");

    levitationID = AddUpgrade(raceID,"Levitation", "levitation",
                              "Allows you to jump higher by \nreducing your gravity by 8-64%.");

    suicideID    = AddUpgrade(raceID,"Suicide Bomber", "suicide_bomb",
                              "Use your ultimate bind to explode\nand damage the surrounding players extremely,\nwill automatically activate on death.", true); // Ultimate
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

    if (GameType == tf2)
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt", true);
    else
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt", true);

    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(explodeWav, true, true);
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (pressed)
    {
        if (race == raceID && IsPlayerAlive(client))
        {
            new ult_level = GetUpgradeLevel(player,race,suicideID);
            if (ult_level)
                SuicideBomber(client,ult_level,false);
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if(race == raceID && GetRace(player) == raceID)
    {
        if (upgrade==1)
            UnholyAura(client, player, new_level);
        else if (upgrade==2)
            Levitation(client, player, new_level);
    }
}

public OnItemPurchase(client,Handle:player,item)
{
    new race=GetRace(player);
    if (race == raceID && IsPlayerAlive(client))
    {
        new boots = FindShopItem("boots");
        if (boots == item)
        {
            new unholy_level = GetUpgradeLevel(player,race,unholyID);
            UnholyAura(client,player, unholy_level);
        }
        else
        {
            new sock = FindShopItem("sock");
            if (sock == item)
            {
                new levitation_level = GetUpgradeLevel(player,race,levitationID);
                Levitation(client,player, levitation_level);
            }
        }
    }
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            SetSpeed(player,-1.0);
            SetGravity(player,-1.0);
        }
        else if (race == raceID)
        {
            new unholy_level = GetUpgradeLevel(player,race,unholyID);
            if (unholy_level)
                UnholyAura(client, player, unholy_level);

            new levitation_level = GetUpgradeLevel(player,race,levitationID);
            if (levitation_level)
                Levitation(client, player, levitation_level);
        }
    }
}

public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid     = GetEventInt(event,"userid");
    new index      = GetClientOfUserId(userid);
    if (index)
    {
        new Handle:player = GetPlayerHandle(index);
        if (player != INVALID_HANDLE)
        {
            m_Suicided[index]=false;
            new race=GetRace(player);
            if(race==raceID)
            {
                new unholy_level = GetUpgradeLevel(player,race,unholyID);
                if (unholy_level)
                    UnholyAura(index, player, unholy_level);

                new levitation_level = GetUpgradeLevel(player,race,levitationID);
                if (levitation_level)
                    Levitation(index, player, levitation_level);
            }
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
    if (victim_race == raceID && !m_Suicided[victim_index])
    {
        new suicide_level=GetUpgradeLevel(victim_player,raceID,suicideID);
        if (suicide_level)
            SuicideBomber(victim_index,suicide_level,true);
    }
    return Plugin_Continue;
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;
    if (attacker_race == raceID && attacker_index != victim_index)
    {
        if (VampiricAura(damage, attacker_index, attacker_player, victim_index, victim_player))
            changed = true;
    }

    if (assister_race == raceID && assister_index != victim_index)
    {
        if (VampiricAura(damage, assister_index, assister_player, victim_index, victim_player))
            changed = true;
    }
    return changed ? Plugin_Changed : Plugin_Continue;
}

UnholyAura(client, Handle:player, level)
{
    if (level > 0)
    {
        new Float:speed=1.0;
        switch (level)
        {
            case 1:
                speed=1.05;
            case 2:
                speed=1.10;
            case 3:
                speed=1.15;
            case 4:
                speed=1.20;
        }

        /* If the Player also has the Boots of Speed,
         * Increase the speed further
         */
        new boots = FindShopItem("boots");
        if (boots != -1 && GetOwnsItem(player,boots))
        {
            speed *= 1.1;
        }

        new Float:start[3];
        GetClientAbsOrigin(client, start);

        new color[4] = { 255, 100, 0, 255 };
        TE_SetupBeamRingPoint(start,20.0,60.0,g_smokeSprite,g_smokeSprite,
                0, 1, 1.0, 4.0, 0.0 ,color, 10, 0);
        TE_SendToAll();

        SetSpeed(player,speed);
    }
    else
        SetSpeed(player,-1.0);
}

Levitation(client, Handle:player, level)
{
    if (level > 0)
    {
        new Float:gravity=1.0;
        switch (level)
        {
            case 1:
                gravity=0.92;
            case 2:
                gravity=0.733;
            case 3:
                gravity=0.5466;
            case 4:
                gravity=0.36;
        }

        /* If the Player also has the Sock of the Feather,
         * Decrease the gravity further.
         */
        new sock = FindShopItem("sock");
        if (sock != -1 && GetOwnsItem(player,sock))
        {
            gravity *= 0.8;
        }

        new Float:start[3];
        GetClientAbsOrigin(client, start);

        new color[4] = { 0, 20, 100, 255 };
        TE_SetupBeamRingPoint(start,20.0,50.0,g_lightningSprite,g_lightningSprite,
                0, 1, 2.0, 60.0, 0.8 ,color, 10, 1);
        TE_SendToAll();

        SetGravity(player,gravity);
    }
    else
        SetGravity(player,-1.0);
}

bool:VampiricAura(damage, index, Handle:player, victim_index, Handle:victim_player)
{
    new level = GetUpgradeLevel(player,raceID,vampiricID);
    if (level > 0 && GetRandomInt(1,10) <= 6 &&
        !GetImmunity(victim_player, Immunity_HealthTake) &&
        !TF2_IsPlayerInvuln(victim_index))
    {
        new Float:percent_health;
        switch(level)
        {
            case 1:
                percent_health=0.12;
            case 2:
                percent_health=0.18;
            case 3:
                percent_health=0.24;
            case 4:
                percent_health=0.30;
        }

        new leechhealth=RoundFloat(float(damage)*percent_health);
        if(leechhealth <= 0)
            leechhealth = 1;

        //if(leechhealth)
        {
            LogToGame("[SourceCraft] %N leeched %d health from %N\n", index, leechhealth, victim_index);

            if (IsClientInGame(index) && IsPlayerAlive(index))
            {
                PrintToChat(index,"%c[SourceCraft]%c You have leeched %d hp from %N using %cVampiric Aura%c.",
                            COLOR_GREEN,COLOR_DEFAULT,leechhealth,victim_index,COLOR_TEAM,COLOR_DEFAULT);

                new health=GetClientHealth(index);
                SetEntityHealth(index,health + leechhealth);
            }

            new victim_health=GetClientHealth(victim_index);
            if (victim_health <= leechhealth)
            {
                victim_health = 0;
                LogKill(index, victim_index, "vampiric_aura", "Vampiric Aura", leechhealth);
            }
            else
            {
                victim_health -= leechhealth;

                PrintToChat(victim_index,"%c[SourceCraft] %N %chas leeched %d hp from you using %cVampiric Aura%c.",
                        COLOR_GREEN,index,COLOR_DEFAULT,leechhealth,COLOR_TEAM,COLOR_DEFAULT);
            }

            SetEntityHealth(victim_index, victim_health);

            new Float:start[3];
            GetClientAbsOrigin(index, start);
            start[2] += 1620;

            new Float:end[3];
            GetClientAbsOrigin(index, end);
            end[2] += 20;

            new color[4] = { 255, 10, 25, 255 };
            TE_SetupBeamPoints(start,end,g_beamSprite,g_haloSprite,
                    0, 1, 3.0, 20.0,10.0,5,50.0,color,255);
            TE_SendToAll();
            return true;
        }
    }
    return false;
}

SuicideBomber(client,ult_level,bool:ondeath)
{
    if (!ondeath)
    {
        m_Suicided[client]=true;
        KillPlayer(client);
    }

    new Float:radius;
    new r_int;
    switch(ult_level)
    {
        case 1:
        {
            radius = 200.0;
            r_int  = 200;
        }
        case 2:
        {
            radius = 250.0;
            r_int  = 250;
        }
        case 3:
        {
            radius = 300.0;
            r_int  = 300;
        }
        case 4:
        {
            radius = 350.0;
            r_int  = 350;
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
        if (index != client && IsClientInGame(index) && IsPlayerAlive(index) &&
            GetClientTeam(index) != GetClientTeam(client))
        {
            new Handle:check_player=GetPlayerHandle(index);
            if (check_player != INVALID_HANDLE)
            {
                if (!GetImmunity(check_player,Immunity_Ultimates) &&
                    !GetImmunity(check_player,Immunity_Explosion) &&
                    !TF2_IsPlayerInvuln(index))
                {
                    new Float:check_location[3];
                    GetClientAbsOrigin(index,check_location);

                    new hp=PowerOfRange(client_location,radius,check_location,300);
                    if (hp > 0)
                    {
                        if (TraceTarget(client, index, client_location, check_location))
                        {
                            HurtPlayer(index,hp,client,"suicide_bomb",
                                       "Suicide Bomb", 5+ult_level);
                        }
                    }
                }
            }
        }
    }
}
