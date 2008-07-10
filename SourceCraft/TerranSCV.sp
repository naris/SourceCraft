/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranSCV.sp
 * Description: The Terran SCV race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_player>
#include <tf2_objects>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include "ammopacks"
#include "tripmines"
#include "tf2teleporter"
#include "zgrabber"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/screen"
#include "sc/range"
#include "sc/trace"

#include "sc/SupplyDepot"

new raceID, ammopackID, teleporterID, immunityID, armorID, tripmineID, engineerID;

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_Armor[MAXPLAYERS+1];

new bool:m_AmmopacksAvailable = false;
new bool:m_TripminesAvailable = false;
new bool:m_TeleporterAvailable = false;
new bool:m_GravgunAvailable = false;

new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:liftoffWav[] = "sourcecraft/liftoff.wav";
new String:deniedWav[] = "sourcecraft/buzz.wav";
new String:errorWav[] = "sourcecraft/perror.mp3";
new String:landWav[] = "sourcecraft/land.wav";

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran SCV",
    author = "-=|JFH|=-Naris",
    description = "The Terran SCV race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();
    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnSourceCraftReady()
{
    m_AmmopacksAvailable = LibraryExists("ammopacks");
    m_TripminesAvailable = LibraryExists("tripmines");
    m_TeleporterAvailable = LibraryExists("tf2teleporter");
    m_GravgunAvailable = LibraryExists("zgrabber");

    raceID      = CreateRace("Terran SCV", "scv",
                             "You are now a Terran SCV.",
                             "You will be a Terran SCV when you die or respawn.",
                             48, 20);

    AddSupplyDepotUpgrade(raceID);

    if (m_AmmopacksAvailable)
    {
        ammopackID  = AddUpgrade(raceID,"Ammopack", "ammopack", "Drop Ammopacks on death and with alt fire of the wrench (at level 2).", false, -1, 2);
        ControlAmmopacks(true);
    }
    else
        ammopackID  = AddUpgrade(raceID,"Ammopack", "ammopack", "Not Available", false, 99, 0);

    if (m_TeleporterAvailable)
    {
        teleporterID = AddUpgrade(raceID,"Teleportation", "teleporter", "Decreases the recharge rate of your teleporters.");
        ControlTeleporter(true, 1.0);
    }
    else
        teleporterID = AddUpgrade(raceID,"Teleportation", "teleporter", "Not Available", false, 99, 0);

    immunityID = AddUpgrade(raceID,"Immunity", "immunity",
                            "Makes you Immune to: Crystal Theft at Level 1,\nUltimates at Level 2,\nMotion Taking at Level 3,\nand Blindness at level 4.");

    armorID     = AddUpgrade(raceID,"Armor", "armor", "A suit of Light Armor that takes damage up to 60% until it is depleted.");

    if (m_TripminesAvailable)
    {
        tripmineID = AddUpgrade(raceID,"Tripmine", "tripmine", "You will be given a tripmine to plant for every level.", true); // Ultimate
        ControlTripmines(true);
    }
    else
        tripmineID = AddUpgrade(raceID,"Tripmine", "tripmine", "Not Available", true,99,0); // Ultimate

    if (m_GravgunAvailable)
    {
        engineerID = AddUpgrade(raceID,"Advanced Engineering", "engineer", "Allows you pick up and move objects around.", true, 12, 4); // Ultimate
        ControlZGrabber(true);
        HookPickup(OnPickup);
    }
    else
        engineerID = AddUpgrade(raceID,"Advanced Engineering", "engineer", "Not Available", true, 99, 0); // Ultimate

    CreateSupplyTimer(raceID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "ammopacks"))
    {
        m_AmmopacksAvailable = true;
        ControlAmmopacks(true);
    }
    else if (StrEqual(name, "tf2teleporter"))
    {
        m_TeleporterAvailable = true;
        ControlTeleporter(true, 1.0);
    }
    else if (StrEqual(name, "tripmines"))
    {
        m_TripminesAvailable = true;
        ControlTripmines(true);
    }
    else if (StrEqual(name, "zgrabber"))
    {
        m_GravgunAvailable = true;
        ControlZGrabber(true);
        HookPickup(OnPickup);
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "ammopacks"))
        m_AmmopacksAvailable = false;
    else if (StrEqual(name, "tf2teleporter"))
        m_TeleporterAvailable = false;
    else if (StrEqual(name, "tripmines"))
        m_TripminesAvailable = false;
    else if (StrEqual(name, "zgrabber"))
        m_GravgunAvailable = false;
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

    SetupSound(rechargeWav, true, true);
    SetupSound(liftoffWav, true, true);
    SetupSound(deniedWav, true, true);
    SetupSound(errorWav, true, true);
    SetupSound(landWav, true, true);
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            // Turn off Immunities
            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,false);

            if (m_AmmopacksAvailable)
                SetAmmopack(client, 0);

            if (m_TeleporterAvailable)
                SetTeleporter(client, 0.0);

            if (m_TripminesAvailable)
                GiveTripmine(client, 0);

            if (m_GravgunAvailable)
                TakeGravgun(client);
        }
        else if (race == raceID)
        {
            // Turn on Immunities
            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,true);

            if (m_TripminesAvailable)
            {
                new tripmine_level=GetUpgradeLevel(player,race,tripmineID);
                GiveTripmine(client, tripmine_level);
            }

            new ammopack_level = GetUpgradeLevel(player,raceID,ammopackID);
            if (ammopack_level)
                SetupAmmopack(client, ammopack_level);

            new armor_level = GetUpgradeLevel(player,raceID,armorID);
            if (armor_level)
                SetupArmor(client, armor_level);

            new teleporter_level = GetUpgradeLevel(player,raceID,teleporterID);
            if (teleporter_level)
                SetupTeleporter(client, teleporter_level);

            new engineer_level=GetUpgradeLevel(player,race,engineerID);
            if (engineer_level)
                SetupGravgun(client, engineer_level);
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && GetRace(player) == raceID)
    {
        if (upgrade==armorID)
            SetupArmor(client, new_level);
        else if (upgrade == immunityID)
            DoImmunity(client, player, new_level,true);
        else if (upgrade==ammopackID)
            SetupAmmopack(client, new_level);
        else if (upgrade==teleporterID)
            SetupTeleporter(client, new_level);
        else if (upgrade==engineerID)
            SetupGravgun(client, new_level);
        else if (upgrade==tripmineID)
        {
            if (m_TripminesAvailable)
                GiveTripmine(client, new_level);
        }
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        new tripmine_level=GetUpgradeLevel(player,race,tripmineID);
        if (tripmine_level)
        {
            if (m_TripminesAvailable && !pressed)
                SetTripmine(client);
            else
            {
                if (pressed)
                    PrintHintText(client,"Tripmines are not available");
            }
        }
        else
        {
            new engineer_level=GetUpgradeLevel(player,race,engineerID);
            if (engineer_level)
            {
                if (m_GravgunAvailable)
                {
                    if (pressed)
                        StartThrowObject(client);
                    else
                        ThrowObject(client);
                }
                else
                {
                    if (pressed)
                        PrintHintText(client, "Advanced Engineering is not available");
                }
            }
        }
    }
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
                new immunity_level=GetUpgradeLevel(player,raceID,immunityID);
                if (immunity_level)
                    DoImmunity(client, player, immunity_level,true);

                new armor_level = GetUpgradeLevel(player,raceID,armorID);
                if (armor_level)
                    SetupArmor(client, armor_level);
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

    return changed ? Plugin_Changed : Plugin_Continue;
}

DoImmunity(client, Handle:player, level, bool:value)
{
    if (level >= 1)
    {
        SetImmunity(player,Immunity_Theft,value);
        if (level >= 2)
        {
            SetImmunity(player,Immunity_Ultimates,value);
            if (level >= 3)
            {
                SetImmunity(player,Immunity_MotionTake,value);
                if (level >= 4)
                    SetImmunity(player,Immunity_Blindness,value);
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

SetupArmor(client, level)
{
    switch (level)
    {
        case 0: m_Armor[client] = 0;
        case 1: m_Armor[client] = GetMaxHealth(client) / 4;
        case 2: m_Armor[client] = GetMaxHealth(client) / 3;
        case 3: m_Armor[client] = GetMaxHealth(client) / 2;
        case 4: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*0.75);
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
                to_percent=0.50;
            }
            case 4:
            {
                from_percent=0.20;
                to_percent=0.60;
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

            DisplayMessage(victim_index,SC_DISPLAY_DEFENSE,
                           "%c[SourceCraft] %s %cyour armor absorbed %d hp",
                           COLOR_GREEN,victimName,COLOR_DEFAULT,amount);
            return true;
        }
    }
    return false;
}

public SetupAmmopack(client, level)
{
    if (m_AmmopacksAvailable)
    {
        if (level)
            SetAmmopack(client, (level >= 2) ? 3 : 1);
        else
            SetAmmopack(client, 0);
    }
}

public SetupTeleporter(client, level)
{
    if (m_TeleporterAvailable)
    {
        switch (level)
        {
            case 0: SetTeleporter(client, 0.0);
            case 1: SetTeleporter(client, 8.0);
            case 2: SetTeleporter(client, 6.0);
            case 3: SetTeleporter(client, 3.0);
            case 4: SetTeleporter(client, 1.0);
        }
    }
}

public SetupGravgun(client, level)
{
    if (m_GravgunAvailable)
    {
        if (level == 0)
            TakeGravgun(client);
        else
        {
            new Float:speed = 500.0 * float(level);
            new Float:duration = 5.0 * float(level);
            new permissions=HAS_GRABBER|CAN_GRAB_BUILDINGS;
            switch (level)
            {
                case 2: permissions |= CAN_STEAL|CAN_GRAB_OTHER_BUILDINGS;
                case 3: permissions |= CAN_STEAL|CAN_GRAB_OTHER_BUILDINGS|CAN_THROW_BUILDINGS;
                case 4:
                {
                    permissions |= CAN_STEAL|CAN_GRAB_OTHER_BUILDINGS|CAN_THROW_BUILDINGS;
                    duration = 30.0;
                }
            }
            GiveGravgun(client, duration, speed, -1.0, permissions);
        }
    }
}

public Action:OnPickup(client, builder, ent)
{
    if (builder != client)
    {
        new Handle:player_check=GetPlayerHandle(builder);
        if (player_check != INVALID_HANDLE)
        {
            if (GetImmunity(player_check,Immunity_Ultimates))
            {
                PrintToChat(client,"%c[SourceCraft] %cTarget is %cimmune%c to ultimates!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                return Plugin_Stop;
            }
        }
    }
    return Plugin_Continue;
}
