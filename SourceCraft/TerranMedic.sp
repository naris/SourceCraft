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

#undef REQUIRE_PLUGIN
#include "medipacks"
#include "medihancer"
#include "MedicInfect"
#define REQUIRE_PLUGIN

#include "drug"
#include "jetpack"

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/screen"
#include "sc/trace"

#include "sc/log" // for debugging

new raceID, regenerationID, healingID, chargeID, armorID, medipackID, infectID;
new restoreID, flareID, jetpackID;

new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new m_Armor[MAXPLAYERS+1];
new bool:m_AllowOpticFlare[MAXPLAYERS+1];

new bool:m_MedipacksAvailable = false;
new bool:m_InfectionAvailable = false;
new bool:m_UberChargerAvailable = false;

new Handle:cvarFlareCooldown = INVALID_HANDLE;

new String:rechargeWav[] = "sourcecraft/transmission.wav";

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

    cvarFlareCooldown=CreateConVar("sc_opticflarecooldown","30");

    HookEvent("player_spawn",PlayerSpawnEvent);

    CreateTimer(3.0,Restore,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    m_MedipacksAvailable = LibraryExists("medipacks");
    m_UberChargerAvailable = LibraryExists("medihancer");
    m_InfectionAvailable = LibraryExists("MedicInfect");

    raceID      = CreateRace("Terran Medic", "medic",
                             "You are now a Terran Medic.",
                             "You will be a Terran Medic when you die or respawn.",
                             32,20);

    if (m_InfectionAvailable)
        infectID    = AddUpgrade(raceID,"Infection", "infection", "Infects your victims, which can then spread the infection");
    else
        infectID    = AddUpgrade(raceID,"Infection", "infection", "Infection is currently disabled", false, 99, 0);

    if (m_UberChargerAvailable)
        chargeID    = AddUpgrade(raceID,"Uber Charger", "ubercharger", "Constantly charges your Uber over time");
    else
        chargeID    = AddUpgrade(raceID,"Uber Charger", "ubercharger", "Uber Charger is currently disabled", false, 99, 0);

    armorID     = AddUpgrade(raceID,"Light Armor", "armor", "Reduces damage.");

    if (m_MedipacksAvailable)
        medipackID  = AddUpgrade(raceID,"Medipack", "medipack", "Drop Medipacks on death and with alt fire of medigun (at level 2 and above).\nAlso gives some ubercharge on spawn.");
    else
        medipackID  = AddUpgrade(raceID,"Medipack", "medipack", "Medipacks are currently disabled.", false, 99, 0);

    regenerationID  = AddUpgrade(raceID,"Regeneration", "regeneration", "Regenerates your Health.");
    healingID       = AddUpgrade(raceID,"Healing Aura", "healing", "Heals all of your teammates in range (It does NOT heal you).");

    restoreID   = AddUpgrade(raceID,"Restore", "restore", "Restores (removes effects of orb,bash,lockdown, etc.) for\nthe teammates around you or yourself (when +ultimate is hit).", true); // Ultimate
    flareID   = AddUpgrade(raceID,"Optical Flare", "flare", "Blinds the enemies around you.", true, 10); // Ultimate
    jetpackID   = AddUpgrade(raceID,"Jetpack", "jetpack", "Allows you to fly until you run out of fuel.", true, 12); // Ultimate

    ControlJetpack(true,true);
    SetJetpackRefuelingTime(0,30.0);
    SetJetpackFuel(0,100);

    if (m_UberChargerAvailable)
        ControlMedicEnhancer(true);

    if (m_InfectionAvailable)
        ControlMedicInfect(true);

    if (m_MedipacksAvailable)
        ControlMedipacks(true);
}

public OnMapStart()
{
    m_MedipacksAvailable = LibraryExists("medipacks");
    m_UberChargerAvailable = LibraryExists("medihancer");
    m_InfectionAvailable = LibraryExists("MedicInfect");

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
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            TakeJetpack(client);

            if (m_InfectionAvailable)
                SetMedicInfect(client, false, 0);

            if (m_UberChargerAvailable)
                SetMedicEnhancement(client, false, 0);

            if (m_MedipacksAvailable)
                SetMedipack(client, 0, 0);
        }
        else if (race == raceID)
        {
            new infect_level = GetUpgradeLevel(player,raceID,infectID);
            if (infect_level)
                SetupInfection(client, infect_level);

            new charge_level = GetUpgradeLevel(player,raceID,chargeID);
            if (charge_level)
                SetupUberCharger(client, charge_level);

            new medipack_level = GetUpgradeLevel(player,raceID,medipackID);
            if (medipack_level)
                SetupMedipack(client, medipack_level);

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
        new restore_level=GetUpgradeLevel(player,race,restoreID);
        if (restore_level)
        {
            RestorePlayer(player);
            PerformBlind(client, 0);
            if (m_InfectionAvailable)
                HealInfect(client,client);
        }
        else
        {
            new flare_level=GetUpgradeLevel(player,race,flareID);
            if (flare_level)
                OpticFlare(client, flare_level);
            else
            {
                new jetpack_level=GetUpgradeLevel(player,race,jetpackID);
                if (jetpack_level)
                {
                    if (pressed)
                        StartJetpack(client);
                    else
                        StopJetpack(client);
                }
            }
        }
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
        else if (upgrade==medipackID)
            SetupMedipack(client, new_level);
        else if (upgrade==armorID)
            SetupArmor(client, new_level);
        else if (upgrade==jetpackID)
            Jetpack(client, new_level);
    }
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    m_AllowOpticFlare[client]=true;
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
                m_AllowOpticFlare[client]=true;

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
        changed |= Infect(victim_index, victim_player,
                          attacker_index, attacker_player);
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        changed |= Infect(victim_index, victim_player,
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

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_player != INVALID_HANDLE)
    {
        // Make sure infected players don't stay green!
        SetVisibility(victim_player, -1);
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

bool:Infect(victim_index, Handle:victim_player, index, Handle:player)
{
    if (m_InfectionAvailable)
    {
        new infect_level = GetUpgradeLevel(player,raceID,infectID);
        if (infect_level > 0)
        {
            if (!GetImmunity(victim_player,Immunity_HealthTake) &&
                !TF2_IsPlayerInvuln(victim_index))
            {
                if(GetRandomInt(1,100)<=(infect_level*4))
                {
                    MedicInfect(index, victim_index, false);
                    return true;
                }
            }
        }
    }
    return false;
}

public OnInfected(victim,infector,bool:infected,const color[4])
{
    new Handle:player=GetPlayerHandle(victim);
    if (player != INVALID_HANDLE)
    {
        LogMessage("%N infected, infected=%d, color=%d,%d,%d,%d",
                   victim, infected, color[0], color[1], color[2], color[3]);

        SetVisibility(player, color[3], BasicVisibility,
                      -1.0, -1.0, RenderMode:-1, RenderFx:-1,
                      color[0], color[1], color[2], false);
    }
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
    if (m_InfectionAvailable)
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
}

public SetupUberCharger(client, level)
{
    if (m_UberChargerAvailable)
    {
        if (level)
            SetMedicEnhancement(client, true, level);
        else
            SetMedicEnhancement(client, false, 0);
    }
}

public SetupMedipack(client, level)
{
    if (m_MedipacksAvailable)
    {
        if (level)
            SetMedipack(client, (level >= 2) ? 3 : 1, (level-1)*2);
        else
            SetMedipack(client, 0, 0);
    }
}

public Action:Restore(Handle:timer)
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
                    new regeneration_level=GetUpgradeLevel(player,raceID,regenerationID);
                    if (regeneration_level)
                    {
                        new newhp=GetClientHealth(client)+regeneration_level;
                        new maxhp=GetMaxHealth(client);
                        if(newhp<=maxhp)
                            SetEntityHealth(client,newhp);
                    }

                    new restore_level=GetUpgradeLevel(player,raceID,restoreID);
                    new healing_aura_level=GetUpgradeLevel(player,raceID,healingID);
                    if (restore_level || healing_aura_level)
                    {
                        new Float:restore_range;
                        switch(restore_level)
                        {
                            case 1:  restore_range = 300.0;
                            case 2:  restore_range = 450.0;
                            case 3:  restore_range = 650.0;
                            case 4:  restore_range = 800.0;
                            default: restore_range = 0.0;
                        }

                        new Float:healing_range;
                        switch(healing_aura_level)
                        {
                            case 1:  healing_range = 300.0;
                            case 2:  healing_range = 450.0;
                            case 3:  healing_range = 650.0;
                            case 4:  healing_range = 800.0;
                            default: healing_range = 0.0;
                        }

                        new Float:distance;
                        new Float:indexLoc[3];
                        new Float:clientLoc[3];
                        GetClientAbsOrigin(client, clientLoc);
                        new team = GetClientTeam(client);
                        for (new index=1;index<=maxplayers;index++)
                        {
                            if (index != client && IsClientInGame(index) &&
                                IsPlayerAlive(index) && GetClientTeam(index) == team)
                            {
                                new Handle:player_check=GetPlayerHandle(index);
                                if (player_check != INVALID_HANDLE)
                                {
                                    GetClientAbsOrigin(index, indexLoc);
                                    distance = DistanceBetween(clientLoc,indexLoc);

                                    if (restore_level > 0 && distance <= restore_range)
                                    {
                                        if (TraceTarget(client, index, clientLoc, indexLoc))
                                        {
                                            RestorePlayer(player_check);
                                            if (m_InfectionAvailable)
                                                HealInfect(client,index);

                                            new color[4] = { 0, 0, 255, 255 };
                                            TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                              0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                            TE_SendToAll();
                                        }
                                    }

                                    if (healing_aura_level > 0 && distance <= healing_range)
                                    {
                                        if (TraceTarget(client, index, clientLoc, indexLoc))
                                        {
                                            new health=GetClientHealth(index);
                                            new max=GetMaxHealth(index);
                                            if (health < max)
                                            {
                                                HealPlayer(index,healing_aura_level*5,health,max);

                                                new color[4] = { 0, 0, 255, 255 };
                                                TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                                  0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                                TE_SendToAll();
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
    }
    return Plugin_Continue;
}

OpticFlare(client,ultlevel)
{
    if (m_AllowOpticFlare[client] && ultlevel)
    {
        new Float:range;
        switch(ultlevel)
        {
            case 1: range=300.0;
            case 2: range=450.0;
            case 3: range=650.0;
            case 4: range=800.0;
        }

        new count=0;
        new duration = ultlevel*100;
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        new maxplayers=GetMaxClients();
        for(new index=1;index<=maxplayers;index++)
        {
            if (client != index && IsClientInGame(index) && IsPlayerAlive(index) &&
                    GetClientTeam(client) != GetClientTeam(index))
            {
                new Handle:player_check=GetPlayerHandle(index);
                if (player_check != INVALID_HANDLE)
                {
                    if (!GetImmunity(player_check,Immunity_Ultimates) &&
                            !GetImmunity(player_check,Immunity_HealthTake) &&
                            !TF2_IsPlayerInvuln(index))
                    {
                        if (IsInRange(client,index,range))
                        {
                            new Float:indexLoc[3];
                            GetClientAbsOrigin(index, indexLoc);
                            if (TraceTarget(client, index, clientLoc, indexLoc))
                            {
                                new color[4]={250,250,250,255};
                                FadeOne(index, duration, duration , color, FADE_IN);
                            }
                        }
                    }
                }
            }
        }
        new Float:cooldown = GetConVarFloat(cvarFlareCooldown);
        if (count)
        {
            PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cOptic Flare%c to blind %d enemies, you now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
        }
        else
        {
            PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cOptic Flare%c, with no effect! You now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
        }
        if (cooldown > 0.0)
        {
            m_AllowOpticFlare[client]=false;
            CreateTimer(cooldown,AllowOpticFlare,client);
        }
    }
}

public Action:AllowOpticFlare(Handle:timer,any:index)
{
    m_AllowOpticFlare[index]=true;

    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        if (GetRace(GetPlayerHandle(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cOptic Flare%c is now available again!",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}

