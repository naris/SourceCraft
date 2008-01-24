/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_UndeadScourge.sp
 * Description: The Undead Scourge race for SourceCraft.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/range"
#include "War3Source/trace"
#include "War3Source/health"
#include "War3Source/log"

new raceID; // The ID we are assigned to

new explosionModel;
new g_beamSprite;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new String:explodeWav[] = "weapons/explode5.wav";

// Suicide bomber check
new bool:m_Suicided[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "War3Source Race - Undead Scourge",
    author = "PimpinJuice",
    description = "The Undead Scourge race for War3Source.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

// War3Source Functions
public OnPluginStart()
{
    GetGameType();

    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);
}

public OnPluginReady()
{
    raceID=CreateRace("Undead Scourge", "undead",
                      "You are now an Undead Scourge.",
                      "You will be an Undead Scourge when you die or respawn.",
                      "Vampiric Aura",
                      "Gives you a 60% chance to gain 12-30% of the\ndamage you did in attack, back as health. It can\nbe blocked if the player is immune.",
                      "Unholy Aura",
                      "Gives you a speed boost, 8-36% faster.",
                      "Levitation",
                      "Allows you to jump higher by \nreducing your gravity by 8-64%.",
                      "Suicide Bomber",
                      "Use your ultimate bind to explode\nand damage the surrounding players extremely,\nwill automatically activate on death.");

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

    if (GameType == tf2)
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt");
    else
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");

    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(explodeWav);
}

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (pressed)
    {
        if (race == raceID && IsPlayerAlive(client))
        {
            new ult_level = GetSkillLevel(player,race,0);
            if (ult_level)
                Undead_SuicideBomber(client,player,ult_level,false);
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid     = GetEventInt(event,"userid");
    new index      = GetClientOfUserId(userid);
    new player = GetPlayer(index);
    if (player > -1 && !m_Suicided[index])
    {
        if(GetRace(player) == raceID)
        {
            new ult_level=GetSkillLevel(player,raceID,0);
            if (ult_level)
                Undead_SuicideBomber(index,player,ult_level,true);
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid     = GetEventInt(event,"userid");
    new index      = GetClientOfUserId(userid);
    if (index)
    {
        new player = GetPlayer(index);
        if (player > -1)
        {
            m_Suicided[index]=false;
            new race=GetRace(player);
            if(race==raceID)
            {
                new skilllevel_unholy = GetSkillLevel(player,race,1);
                if (skilllevel_unholy)
                    Undead_UnholyAura(index, player, skilllevel_unholy);

                new skilllevel_levi = GetSkillLevel(player,race,2);
                if (skilllevel_levi)
                    Undead_Levitation(index, player, skilllevel_levi);
            }
        }
    }
}

public OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && GetRace(player) == raceID)
    {
        if (skill==1)
            Undead_UnholyAura(client, player, newskilllevel);
        else if (skill==2)
            Undead_Levitation(client, player, newskilllevel);
    }
}

public OnItemPurchase(client,player,item)
{
    new race=GetRace(player);
    if (race == raceID && IsPlayerAlive(client))
    {
        new boots = GetShopItem("Boots of Speed");
        if (boots == item)
        {
            new skilllevel_unholy = GetSkillLevel(player,race,1);
            Undead_UnholyAura(client,player, skilllevel_unholy);
        }
        else
        {
            new sock = GetShopItem("Sock of the Feather");
            if (sock == item)
            {
                new skilllevel_levi = GetSkillLevel(player,race,2);
                Undead_Levitation(client,player, skilllevel_levi);
            }
        }
    }
}

public OnRaceSelected(client,player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        SetMaxSpeed(player,1.0);
        SetMinGravity(player,1.0);
    }
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid = GetEventInt(event,"userid");
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
                    {
                        Undead_VampiricAura(event, attackerIndex, attackerWar3player,
                                            victimIndex, victimWar3player);
                    }
                }
            }

            new assisterUserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisterUserid && victimUserid != assisterUserid)
            {
                new assisterIndex      = GetClientOfUserId(assisterUserid);
                new assisterWar3player = GetPlayer(assisterIndex);
                if (assisterWar3player != -1)
                {
                    if (GetRace(assisterWar3player) == raceID)
                    {
                        Undead_VampiricAura(event, assisterIndex, assisterWar3player,
                                            victimIndex, victimWar3player);
                    }
                }
            }
        }
    }
}

public Undead_UnholyAura(client, player, skilllevel)
{
    new Float:speed=1.0;
    switch (skilllevel)
    {
        case 1:
            speed=1.08;
        case 2:
            speed=1.1733;
        case 3:
            speed=1.266;
        case 4:
            speed=1.36;
    }

    /* If the Player also has the Boots of Speed,
     * Increase the speed further
     */
    new boots = GetShopItem("Boots of Speed");
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

    SetMaxSpeed(player,speed);
}

public Undead_Levitation(client, player, skilllevel)
{
    new Float:gravity=1.0;
    switch (skilllevel)
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
    new sock = GetShopItem("Sock of the Feather");
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

    SetMinGravity(player,gravity);
}

public Undead_VampiricAura(Handle:event, index, player, victim, victim_player)
{
    new skill = GetSkillLevel(player,raceID,0);
    if (skill > 0 && GetRandomInt(1,10) <= 6 &&
        !GetImmunity(victim_player, Immunity_HealthTake))
    {
        new Float:percent_health;
        switch(skill)
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
        new Float:damage=float(GetDamage(event, victim));
        new leechhealth=RoundFloat(damage*percent_health);
        if(leechhealth)
        {
            new victim_health=GetClientHealth(victim)-leechhealth;
            if (victim_health < 0)
                victim_health = 0;
            SetHealth(victim,victim_health);

            new health=GetClientHealth(index)+leechhealth;
            SetHealth(index,health);

            decl String:name[64];
            GetClientName(index,name,63);
            PrintToChat(victim,"%c[War3Source] %s %chas leeched %d hp from you using %cVampiric Aura%c.",
                        COLOR_GREEN,name,COLOR_DEFAULT,leechhealth,COLOR_TEAM,COLOR_DEFAULT);

            decl String:victimName[64];
            GetClientName(victim,victimName,63);
            PrintToChat(index,"%c[War3Source]%c You have leeched %d hp from %s using %cVampiric Aura%c.",
                        COLOR_GREEN,COLOR_DEFAULT,leechhealth,victimName,COLOR_TEAM,COLOR_DEFAULT);

            LogMessage("[War3Source] %s leeched %d health from %s\n", name, leechhealth, victimName);

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
        }
    }
}

public Undead_SuicideBomber(client,player,ult_level,bool:ondeath)
{
    if (!ondeath)
    {
        m_Suicided[client]=true;
        ForcePlayerSuicide(client);
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

    new Float:clientLoc[3];
    GetClientAbsOrigin(client, clientLoc);
    new clientCount = GetClientCount();
    for(new x=1;x<=clientCount;x++)
    {
        if (x != client && IsClientConnected(x) && IsPlayerAlive(x) &&
            GetClientTeam(x) != GetClientTeam(client))
        {
            new player_check=GetPlayer(x);
            if (player_check>-1)
            {
                if (!GetImmunity(player_check,Immunity_Ultimates) &&
                    !GetImmunity(player_check,Immunity_Explosion))
                {
                    new Float:location_check[3];
                    GetClientAbsOrigin(x,location_check);

                    new hp=PowerOfRange(client_location,radius,location_check,300);
                    if (hp)
                    {
                        if (TraceTarget(client, x, clientLoc, location_check))
                        {
                            new newhealth = GetClientHealth(x)-hp;
                            if (newhealth <= 0)
                            {
                                newhealth=0;
                                new addxp=5+ult_level;
                                new newxp=GetXP(player,raceID)+addxp;
                                SetXP(player,raceID,newxp);

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
}
