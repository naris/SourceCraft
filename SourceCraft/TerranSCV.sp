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

#include "tripmines"
#include "ammopacks"
#include "medihancer"
#include "tf2teleporter"

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/ammo"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/screen"
#include "sc/range"
#include "sc/trace"

#include "sc/log" // for debugging

new raceID, supplyID, ammopackID, armorID, teleporterID, tripmineID, engineerID;

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_Armor[MAXPLAYERS+1];
new m_Object[MAXPLAYERS+1];

new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:deniedWav[] = "sourcecraft/buzz.wav";
new String:errorWav[] = "soundcraft/perror.mp3";

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

    CreateTimer(5.0,Supply,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID      = CreateRace("Terran SCV", "medic",
                             "You are now a Terran SCV.",
                             "You will be a Terran SCV when you die or respawn.",
                             32);

    supplyID  = AddUpgrade(raceID,"Supply Depot", "supply", "Provides additional metal or ammo");

    ammopackID  = AddUpgrade(raceID,"Ammopack", "ammopack", "Drop Ammopacks on death and with alt fire of the wrench (at level 2).", false, -1, 2);

    armorID     = AddUpgrade(raceID,"Armor", "armor", "Reduces damage.");

    teleporterID = AddUpgrade(raceID,"Teleportation", "teleporter", "Increases the recharge rate of your teleporters.");

    tripmineID   = AddUpgrade(raceID,"Tripmine", "tripmine", "You will be given a tripmine to plant for every level.", true); // Ultimate

    engineerID   = AddUpgrade(raceID,"Advanced Engineering", "engineer", "Allows you pick up and move objects around.", true, 12); // Ultimate
    ControlTeleporter(true, 1.0);
    ControlAmmopacks(true);
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

    SetupSound(rechargeWav,true,true);
    SetupSound(deniedWav, true, true);
    SetupSound(errorWav, true, true);
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            SetAmmopack(client, 0);
            SetTeleporter(client, 0.0);
            GiveTripmine(client, 0);
            DropObject(client);
        }
        else if (race == raceID)
        {
            new tripmine_level=GetUpgradeLevel(player,race,tripmineID);
            GiveTripmine(client, tripmine_level);

            new ammopack_level = GetUpgradeLevel(player,raceID,ammopackID);
            if (ammopack_level)
                SetupAmmopack(client, ammopack_level);

            new armor_level = GetUpgradeLevel(player,raceID,armorID);
            if (armor_level)
                SetupArmor(client, armor_level);

            new teleporter_level = GetUpgradeLevel(player,raceID,teleporterID);
            if (teleporter_level)
                SetupTeleporter(client, teleporter_level);
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
            if (!pressed)
                SetTripmine(client);
        }
        else
        {
            new engineer_level=GetUpgradeLevel(player,race,engineerID);
            if (engineer_level)
            {
                if (pressed)
                {
                    if (m_Object[client] > 0)
                        DropObject(client);
                    else
                        PickupObject(client);
                }
            }
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && GetRace(player) == raceID)
    {
        if (upgrade==ammopackID)
            SetupAmmopack(client, new_level);
        else if (upgrade==armorID)
            SetupArmor(client, new_level);
        else if (upgrade==tripmineID)
            GiveTripmine(client, new_level);
        else if (upgrade==teleporterID)
            SetupTeleporter(client, new_level);
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

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_index && victim_race == raceID)
    {
        DropObject(victim_index);
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

PickupObject(client)
{
    new target = TraceAimTarget(client);
    if (target >= 0)
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);

        new Float:targetLoc[3];
        TR_GetEndPosition(targetLoc);

        if (IsPointInRange(clientLoc,targetLoc,100.0))
        {
            decl String:class[32];
            if (IsValidEntity(target) &&
                GetEntityNetClass(target,class,sizeof(class)))
            {
                new objects:type;
                if (StrEqual(class, "CObjectSentrygun", false))
                    type = sentrygun;
                else if (StrEqual(class, "CObjectDispenser", false))
                    type = dispenser;
                else if (StrEqual(class, "CObjectTeleporter", false))
                    type = objects:GetEntPropEnt(target, Prop_Send, "m_iObjectType");
                else
                    type = unknown;

                if (type != unknown)
                {
                    //Check to see if the object is still being built
                    new placing = GetEntProp(target, Prop_Send, "m_bPlacing");
                    new building = GetEntProp(target, Prop_Send, "m_bBuilding");
                    new Float:complete = GetEntPropFloat(target, Prop_Send, "m_flPercentageConstructed");
                    if (placing == 0 && building == 0 && complete >= 1.0)
                    {
                        new builder = GetEntPropEnt(target, Prop_Send, "m_hBuilder");
                        new Handle:player_check=GetPlayerHandle(builder);
                        if (player_check != INVALID_HANDLE)
                        {
                            if (!GetImmunity(player_check,Immunity_Ultimates))
                            {
                                new String:strClientName[64];
                                IntToString(client, strClientName, sizeof(strClientName));
                                DispatchKeyValue(client, "targetname", strClientName);

                                m_Object[client] = target;
                                SetVariantString(strClientName);
                                AcceptEntityInput(target, "SetParent", -1, -1, 0);
                                //SetEntPropEnt(target, Prop_Send, "moveparent", client);
                                SetEntityMoveType(target,MOVETYPE_FLY);
                                CreateTimer(0.1,Attach,target);

                                PrintToChat(client,"%c[SourceCraft] %cParent of %d set to %s!",
                                            COLOR_GREEN,COLOR_DEFAULT,target, strClientName);
                            }
                            else
                            {
                                EmitSoundToClient(client,errorWav);
                                PrintToChat(client,"%c[SourceCraft] %cTarget is %cimmune%c to ultimates!",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        else
                            EmitSoundToClient(client,deniedWav);
                    }
                    else
                    {
                        EmitSoundToClient(client,errorWav);
                        PrintToChat(client,"%c[SourceCraft] %cTarget is still %cbuilding%c!",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                    }
                }
                else
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[SourceCraft] %cInvalid Target!",
                                COLOR_GREEN,COLOR_DEFAULT);
                }
            }
            else
            {
                EmitSoundToClient(client,deniedWav);
                PrintToChat(client,"%c[SourceCraft] %cInvalid Target!",
                            COLOR_GREEN,COLOR_DEFAULT);
            }
        }
        else
        {
            EmitSoundToClient(client,errorWav);
            PrintToChat(client,"%c[SourceCraft] %cTarget is too far away!",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
        EmitSoundToClient(client,deniedWav);
}

public Action:Attach(Handle:timer,any:target)
{
    //new target = m_Object[client];
    if (target > 0)
    {
        //m_Object[client] = 0;
        if (IsValidEntity(target))
        {
            AcceptEntityInput(target, "SetParentAttachmentMaintainOffset", -1, -1, 0);
            PrintToChatAll("%c[SourceCraft] %cSetAttachment for %d!",
                           COLOR_GREEN,COLOR_DEFAULT,target);
        }
    }
}

DropObject(client)
{
    new target = m_Object[client];
    if (target > 0)
    {
        m_Object[client] = 0;
        if (IsValidEntity(target))
        {
            AcceptEntityInput(target, "ClearParent", -1, -1, 0);
            SetEntityMoveType(target,MOVETYPE_NONE);
            PrintToChat(client,"%c[SourceCraft] %cDropped %d!",
                        COLOR_GREEN,COLOR_DEFAULT,target);
        }
    }
}

public SetupAmmopack(client, level)
{
    if (level)
        SetAmmopack(client, (level >= 2) ? 3 : 1);
    else
        SetAmmopack(client, 0);
}

public SetupTeleporter(client, level)
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

public Action:Supply(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceID)
                {
                    new supply_level=GetUpgradeLevel(player,raceID,supplyID);
                    if (supply_level)
                    {
                        if (GameType == tf2)
                        {
                            switch (TF2_GetPlayerClass(client))
                            {
                                case TFClass_Heavy: 
                                {
                                    new ammo = GetAmmo(client, Primary);
                                    if (ammo < 400.0)
                                    {
                                        SetAmmo(client, Primary, ammo + (10 * supply_level));
                                        PrintToChat(client,"%c[SourceCraft]%c You have received ammo from the %cInfinite Ammo Pack%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                case TFClass_Pyro: 
                                {
                                    new ammo = GetAmmo(client, Primary);
                                    if (ammo < 400.0)
                                    {
                                        SetAmmo(client, Primary, ammo + (10 * supply_level));
                                        PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                case TFClass_Medic: 
                                {
                                    new ammo = GetAmmo(client, Primary);
                                    if (ammo < 300.0)
                                    {
                                        SetAmmo(client, Primary, ammo + (10 * supply_level));
                                        PrintToChat(client,"%c[SourceCraft]%c You have received ammo from the %cSupply Depot%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                case TFClass_Engineer: // Gets Metal instead of Ammo
                                {
                                    new ammo = GetAmmo(client, Metal);
                                    if (ammo < 400.0)
                                    {
                                        SetAmmo(client, Metal, ammo + (10 * supply_level));
                                        PrintToChat(client,"%c[SourceCraft]%c You have received metal from the %cSupply Depot%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                default:
                                {
                                    new ammo = GetAmmo(client, Primary);
                                    if (ammo < 60.0)
                                    {
                                        SetAmmo(client, Primary, ammo + (10 * supply_level));
                                        PrintToChat(client,"%c[SourceCraft]%c You have received ammo from the %cSupply Depot%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                            }
                        }
                        else
                        {
                            new ammoType  = 0;
                            new curWeapon = GetActiveWeapon(client);
                            if (curWeapon > 0)
                                ammoType  = GetAmmoType(curWeapon);

                            if (ammoType > 0)
                                GiveAmmo(client,ammoType,10,true);
                            else
                                SetClip(curWeapon, 5);

                            PrintToChat(client,"%c[SourceCraft]%c You have received ammo from the %cSupply Depot%c.",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}
