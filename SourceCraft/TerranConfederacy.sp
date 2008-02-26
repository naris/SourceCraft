/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranConfederacy.sp
 * Description: The Terran Confederacy race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "jetpack.inc"

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/maxhealth"

#include "sc/log" // for debugging

new raceID; // The ID we are assigned to

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_Armor[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Confederacy",
    author = "-=|JFH|=-Naris",
    description = "The Terran Confederacy race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnPluginReady()
{
    raceID=CreateRace("Terran Confederacy", "terran",
                      "You are now part of the Terran Confederacy.",
                      "You will be part of the Terran Confederacy when you die or respawn.",
                      "Depleted U-238 Shells",
                      "Increases damage",
                      "Heavy Armor",
                      "Reduces damage.",
                      "Stimpacks",
                      "Gives you a speed boost, 8-36% faster.",
                      "Jetpack",
                      "Allows you to fly until you run out of fuel.",
                      32);

    FindUberOffsets();

    ControlJetpack(true,true);
    SetJetpackRefuelingTime(0,30.0);
    SetJetpackFuel(0,100);
}

public OnMapStart()
{
    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt", true);
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            TakeJetpack(client);
            SetSpeed(player,-1.0);
        }
        else if (race == raceID)
        {
            new skill_armor = GetSkillLevel(player,raceID,1);
            if (skill_armor)
                SetupArmor(client, skill_armor);

            new skill_stimpacks = GetSkillLevel(player,race,2);
            if (skill_stimpacks)
                Stimpacks(client, player, skill_stimpacks);

            new skill_jetpack=GetSkillLevel(player,race,3);
            if (skill_jetpack)
                Jetpack(client, skill_jetpack);
        }
    }
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            StartJetpack(client);
        else
            StopJetpack(client);
    }
}

public OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel)
{
    if (race == raceID && newskilllevel > 0 && GetRace(player) == raceID)
    {
        if (skill==1)
            SetupArmor(client, newskilllevel);
        else if (skill==2)
            Stimpacks(client, player, newskilllevel);
        else if (skill==3)
            Jetpack(client, newskilllevel);
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
            new skill=GetSkillLevel(player,race,2);
            Stimpacks(client, player, skill);
        }
    }
}

public OnPlayerAuthed(client,player)
{
    FindMaxHealthOffset(client);
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
                new skill_armor = GetSkillLevel(player,raceID,1);
                if (skill_armor)
                    SetupArmor(client, skill_armor);

                new skill_stimpacks = GetSkillLevel(player,race,2);
                if (skill_stimpacks)
                    Stimpacks(client, player, skill_stimpacks);

                new skill_jetpack=GetSkillLevel(player,race,3);
                if (skill_jetpack)
                    Jetpack(client, skill_jetpack);
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

    if (victim_race == raceID)
        changed = Armor(damage, victim_index, victim_player);

    if (attacker_race == raceID && victim_index != attacker_index)
    {
        changed |= U238Shells(damage, victim_index, attacker_index, attacker_player);
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        changed |= U238Shells(damage, victim_index, assister_index, assister_player);
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

SetupArmor(client, skilllevel)
{
    switch (skilllevel)
    {
        case 1: m_Armor[client] = GetMaxHealth(client);
        case 2: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*1.50);
        case 3: m_Armor[client] = GetMaxHealth(client)*2;
        case 4: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*2.50);
    }
}

bool:Armor(damage, victim_index, victim_player)
{
    new skill_level_armor = GetSkillLevel(victim_player,raceID,1);
    if (skill_level_armor)
    {
        new Float:from_percent,Float:to_percent;
        switch(skill_level_armor)
        {
            case 1:
            {
                from_percent=0.0;
                to_percent=0.10;
            }
            case 2:
            {
                from_percent=0.0;
                to_percent=0.30;
            }
            case 3:
            {
                from_percent=0.10;
                to_percent=0.60;
            }
            case 4:
            {
                from_percent=0.20;
                to_percent=0.80;
            }
        }
        new amount=RoundFloat(float(damage)*GetRandomFloat(from_percent,to_percent));
        new armor=m_Armor[victim_index];
        if (amount > armor)
            amount = armor;
        if (amount > 0)
        {
            new newhp=GetClientHealth(victim_index)+amount;
            new maxhp=GetMaxHealth(victim_index);
            if (newhp > maxhp)
                newhp = maxhp;

            SetEntityHealth(victim_index,newhp);

            m_Armor[victim_index] = armor - amount;

            decl String:victimName[64];
            GetClientName(victim_index,victimName,63);

            PrintToChat(victim_index,"%c[SourceCraft] %s %cyour armor absorbed %d hp",
                        COLOR_GREEN,victimName,COLOR_DEFAULT,amount);
            return true;
        }
    }
    return false;
}

bool:U238Shells(damage, victim_index, index, player)
{
    new skill_cs = GetSkillLevel(player,raceID,0);
    if (skill_cs > 0)
    {
        if (!GetImmunity(player,Immunity_HealthTake) && !IsUber(index))
        {
            if(GetRandomInt(1,100)<=25)
            {
                new Float:percent;
                switch(skill_cs)
                {
                    case 1:
                        percent=0.30;
                    case 2:
                        percent=0.50;
                    case 3:
                        percent=0.80;
                    case 4:
                        percent=1.00;
                }

                new health_take=RoundFloat(float(damage)*percent);
                new new_health=GetClientHealth(victim_index)-health_take;
                if (new_health <= 0)
                {
                    new_health=0;
                    LogKill(index, victim_index, "u238_shells", "U238 Shells", health_take);
                }
                else
                    LogDamage(index, victim_index, "u238_shells", "U238 Shells", health_take);

                SetEntityHealth(victim_index,new_health);

                new color[4] = { 100, 255, 55, 255 };
                TE_SetupBeamLaser(index,victim_index,g_lightningSprite,g_haloSprite,
                        0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendToAll();
                return true;
            }
        }
    }
    return false;
}

Stimpacks(client, player, skilllevel)
{
    new Float:speed=1.0;
    switch (skilllevel)
    {
        case 1:
            speed=1.10;
        case 2:
            speed=1.15;
        case 3:
            speed=1.20;
        case 4:
            speed=1.25;
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

    SetSpeed(player,speed);
}

Jetpack(client, skilllevel)
{
    if (skilllevel)
    {
        new fuel,Float:refueling_time;
        switch(skilllevel)
        {
            case 1:
            {
                fuel=60;
                refueling_time=45.0;
            }
            case 2:
            {
                fuel=90;
                refueling_time=30.0;
            }
            case 3:
            {
                fuel=120;
                refueling_time=20.0;
            }
            case 4:
            {
                fuel=150;
                refueling_time=10.0;
            }
        }
        GiveJetpack(client, fuel, refueling_time);
    }
}
