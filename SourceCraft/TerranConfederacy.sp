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
#include "sc/weapons"

#include "sc/log" // for debugging

new raceID, u238ID, armorID, stimpackID, jetpackID;

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
    raceID      = CreateRace("Terran Confederacy", "terran",
                             "You are now part of the Terran Confederacy.",
                             "You will be part of the Terran Confederacy when you die or respawn.",
                             32);

    u238ID      = AddUpgrade(raceID,"Depleted U-238 Shells", "Increases damage");
    armorID     = AddUpgrade(raceID,"Heavy Armor", "Reduces damage.");
    stimpackID  = AddUpgrade(raceID,"Stimpacks", "Gives you a speed boost, 8-36% faster.");
    jetpackID   = AddUpgrade(raceID,"Jetpack", "Allows you to fly until you run out of fuel.", true); // Ultimate

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

public OnRaceSelected(client,Handle:player,oldrace,race)
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
            new armor_level = GetUpgradeLevel(player,raceID,armorID);
            if (armor_level)
                SetupArmor(client, armor_level);

            new stimpacks_level = GetUpgradeLevel(player,race,stimpackID);
            if (stimpacks_level)
                Stimpacks(client, player, stimpacks_level);

            new jetpack_level=GetUpgradeLevel(player,race,jetpackID);
            if (jetpack_level)
                Jetpack(client, jetpack_level);
        }
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            StartJetpack(client);
        else
            StopJetpack(client);
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && new_level > 0 && GetRace(player) == raceID)
    {
        if (upgrade==1)
            SetupArmor(client, new_level);
        else if (upgrade==2)
            Stimpacks(client, player, new_level);
        else if (upgrade==3)
            Jetpack(client, new_level);
    }
}

public OnItemPurchase(client,Handle:player,item)
{
    new race=GetRace(player);
    if (race == raceID && IsPlayerAlive(client))
    {
        new boots = GetShopItem("Boots of Speed");
        if (boots == item)
        {
            new level=GetUpgradeLevel(player,race,stimpackID);
            Stimpacks(client, player, level);
        }
    }
}

public OnPlayerAuthed(client,Handle:player)
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
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new armor_level = GetUpgradeLevel(player,raceID,armorID);
                if (armor_level)
                    SetupArmor(client, armor_level);

                new stimpacks_level = GetUpgradeLevel(player,race,stimpackID);
                if (stimpacks_level)
                    Stimpacks(client, player, stimpacks_level);

                new jetpack_level=GetUpgradeLevel(player,race,jetpackID);
                if (jetpack_level)
                    Jetpack(client, jetpack_level);
            }
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    if (victim_race == raceID)
        changed = Armor(damage, victim_index, victim_player);

    if (attacker_race == raceID && victim_index != attacker_index)
    {
        changed |= U238Shells(event, damage, victim_index, victim_player,
                              attacker_index, attacker_player);
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        changed |= U238Shells(event, damage, victim_index, victim_player,
                              assister_index, assister_player);
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

SetupArmor(client, level)
{
    switch (level)
    {
        case 1: m_Armor[client] = GetMaxHealth(client);
        case 2: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*1.50);
        case 3: m_Armor[client] = GetMaxHealth(client)*2;
        case 4: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*2.50);
    }
}

bool:Armor(damage, victim_index, Handle:victim_player)
{
    new armor_level = GetUpgradeLevel(victim_player,raceID,armorID);
    if (armor_level)
    {
        new Float:from_percent,Float:to_percent;
        switch(armor_level)
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

bool:U238Shells(Handle:event, damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new u238_level = GetUpgradeLevel(player,raceID,u238ID);
    if (u238_level > 0)
    {
        if (!GetImmunity(victim_player,Immunity_HealthTake) && !IsUber(victim_index))
        {
            if(GetRandomInt(1,100)<=25)
            {
                decl String:weapon[64] = "";
                new bool:is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
                if (!IsMelee(weapon, is_equipment))
                {
                    new Float:percent;
                    switch(u238_level)
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
    }
    return false;
}

Stimpacks(client, Handle:player, level)
{
    new Float:speed=1.0;
    switch (level)
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

Jetpack(client, level)
{
    if (level)
    {
        new fuel,Float:refueling_time;
        switch(level)
        {
            case 1:
            {
                fuel=40;
                refueling_time=45.0;
            }
            case 2:
            {
                fuel=50;
                refueling_time=35.0;
            }
            case 3:
            {
                fuel=70;
                refueling_time=25.0;
            }
            case 4:
            {
                fuel=90;
                refueling_time=15.0;
            }
        }
        GiveJetpack(client, fuel, refueling_time);
    }
}
