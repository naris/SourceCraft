/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranMedic.sp
 * Description: The Terran Medic race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "jetpack"
#include "medihancer"
#include "Medic_Infect"

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/maxhealth"
#include "sc/weapons"

#include "sc/log" // for debugging

new raceID, infectID, chargeID, armorID, jetpackID;

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_Armor[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Medic",
    author = "-=|JFH|=-Naris",
    description = "The Terran Medic race for SourceCraft.",
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
    raceID      = CreateRace("Terran Medic", "medic",
                             "You are now part of the Terran Medic.",
                             "You will be part of the Terran Medic when you die or respawn.",
                             32);

    infectID    = AddUpgrade(raceID,"Infection", "infection", "Infects your victims, which can then spread the infection");
    chargeID    = AddUpgrade(raceID,"Uber Charger", "ubercharger", "Constantly charges you Uber over time");

    armorID     = AddUpgrade(raceID,"Light Armor", "armor", "Reduces damage.");
    jetpackID   = AddUpgrade(raceID,"Jetpack", "jetpack", "Allows you to fly until you run out of fuel.", true); // Ultimate

    ControlMedicInfect(true);
    ControlMedicEnhancer(true);
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
            SetMedicInfect(client, false, 0);
            SetMedicEnhancement(client, false, 0);
            TakeJetpack(client);
            SetSpeed(player,-1.0);
        }
        else if (race == raceID)
        {
            new infect_level = GetUpgradeLevel(player,raceID,infectID);
            if (infect_level)
                SetupInfection(client, infect_level);

            new charge_level = GetUpgradeLevel(player,raceID,chargeID);
            if (charge_level)
                SetupInfection(client, charge_level);

            new armor_level = GetUpgradeLevel(player,raceID,armorID);
            if (armor_level)
                SetupArmor(client, armor_level);

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
    if (race == raceID && GetRace(player) == raceID)
    {
        if (upgrade==infectID)
            SetupInfection(client, new_level);
        else if (upgrade==chargeID)
            SetupUberCharger(client, new_level);
        else if (upgrade==armorID)
            SetupArmor(client, new_level);
        else if (upgrade==jetpackID)
            Jetpack(client, new_level);
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
        changed |= Infect(event, damage, victim_index, victim_player,
                          attacker_index, attacker_player);
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        changed |= Infect(event, damage, victim_index, victim_player,
                          assister_index, assister_player);
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

SetupArmor(client, level)
{
    switch (level)
    {
        case 0: m_Armor[client] = 0;
        case 1: m_Armor[client] = GetMaxHealth(client) / 3;
        case 2: m_Armor[client] = GetMaxHealth(client) / 2;
        case 3: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*0.75);
        case 4: m_Armor[client] = GetMaxHealth(client);
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

bool:Infect(Handle:event, damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new infect_level = GetUpgradeLevel(player,raceID,infectID);
    if (infect_level > 0)
    {
        if (!GetImmunity(victim_player,Immunity_HealthTake) &&
            !TF2_IsPlayerInvuln(victim_index))
        {
            if(GetRandomInt(1,100)<=25)
            {
                decl String:weapon[64];
                new bool:is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
                if (!IsMelee(weapon, is_equipment,index,victim_index))
                {
                    new Float:percent;
                    switch(infect_level)
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

Jetpack(client, level)
{
    if (level > 0)
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
    else
        TakeJetpack(client);
}

public SetupInfection(client, level)
{
    if (level)
    {
        new amount;
        switch(level)
        {
            case 1: amount=2;
            case 2: amount=8;
            case 3: amount=10;
            case 4: amount=12;
        }
        SetMedicInfect(client, true, amount);
    }
    else
        SetMedicInfect(client, false, 0);
}

public SetupUberCharger(client, level)
{
    if (level)
        SetMedicEnhancement(client, true, level);
    else
        SetMedicEnhancement(client, false, 0);
}
