 /**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossZealot.sp
 * Description: The Protoss Zealot race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#include <tf2_meter>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/MeleeAttack"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/dissolve"
#include "sc/shields"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/SendEffects"

new const String:spawnWav[]         = "sc/pzerdy00.wav";
new const String:deathWav[]         = "sc/pzedth00.mp3";

new const String:g_PsiBladesSound[] = "sc/uzefir00.wav";

new const String:g_ChargeSound[]    = "sc/pzerag00.wav";

new const String:g_ChargeAttackSound[][] = { "sc/pzeatt00.wav" ,
                                             "sc/pzeatt01.wav" ,
                                             "sc/pzehit00.wav" };

new raceID, immunityID, legID, shieldsID, chargeID;
new meleeID, dragoonID, immortalID, stalkerID;

new Float:g_ChargePercent[]         = { 0.10, 0.25, 0.50, 0.75, 1.00 };
#include "sc/Charge"

new Float:g_PsiBladesPercent[]      = { 0.0, 0.15, 0.30, 0.40, 0.50 };

new Float:g_SpeedLevels[]           = { -1.0, 1.05, 1.10, 1.15, 1.20 };

new Float:g_InitialShields[]        = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ShieldsPercent[][2]     = { {0.00, 0.00},
                                        {0.00, 0.05},
                                        {0.02, 0.10},
                                        {0.05, 0.15},
                                        {0.08, 0.20} };

new g_dragoonRace = -1;
new g_stalkerRace = -1;
new g_immortalRace = -1;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Zealot",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Zealot race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.charge.phrases.txt");
    LoadTranslations("sc.zealot.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("zealot", 16, 0, 30, .energy_rate=2.0,
                             .faction=Protoss, .type=Biological);

    immunityID  = AddUpgrade(raceID, "immunity", .cost_crystals=0);
    legID       = AddUpgrade(raceID, "leg", .cost_crystals=0);
    shieldsID   = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);
    meleeID     = AddUpgrade(raceID, "blades", .energy=5.0, .cost_crystals=20);

    // Ultimate 1
    chargeID = AddUpgrade(raceID, "charge", 1, 8,
                          .energy=200.0, .cooldown=30.0,
                          .accumulated=true, .cost_crystals=30);

    // Ultimate 2
    dragoonID = AddUpgrade(raceID, "dragoon", 2, 4,1,
                           .energy=120.0, .cooldown=10.0,
                           .accumulated=true, .cost_crystals=50);

    // Ultimate 3
    immortalID = AddUpgrade(raceID, "immortal", 3, 10,1,
                            .energy=120.0, .cooldown=30.0,
                            .accumulated=true, .cost_crystals=50);

    // Ultimate 4
    stalkerID = AddUpgrade(raceID, "stalker", 4, 12,1,
                           .energy=120.0, .cooldown=30.0,
                           .accumulated=true, .cost_crystals=50);

    // Get Configuration Data
    GetConfigFloatArray("shields_amount", g_InitialShields, sizeof(g_InitialShields),
                        g_InitialShields, raceID, shieldsID);

    for (new level=0; level < sizeof(g_ShieldsPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "shields_percent_level_%d", level);
        GetConfigFloatArray(key, g_ShieldsPercent[level], sizeof(g_ShieldsPercent[]),
                            g_ShieldsPercent[level], raceID, shieldsID);
    }

    GetConfigFloatArray("damage_percent",  g_PsiBladesPercent, sizeof(g_PsiBladesPercent),
                        g_PsiBladesPercent, raceID, meleeID);

    GetConfigFloatArray("speed",  g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, legID);

    GetConfigFloatArray("damage_percent", g_ChargePercent, sizeof(g_ChargePercent),
                        g_ChargePercent, raceID, chargeID);
}

public OnMapStart()
{
    SetupSmokeSprite();
    SetupHaloSprite();
    SetupLightning();
    SetupBlueGlow();
    SetupRedGlow();
    SetupSpeed();

    //SetupCharge();
    SetupDeniedSound();

    SetupSound(deathWav);
    SetupSound(spawnWav);
    SetupSound(g_PsiBladesSound);

    SetupSound(g_ChargeSound);
    for (new i = 0; i < sizeof(g_ChargeAttackSound); i++)
        SetupSound(g_ChargeAttackSound[i]);
}

public OnPlayerAuthed(client)
{
    m_ChargeActive[client] = false;
}

public OnClientDisconnect(client)
{
    m_ChargeActive[client] = false;
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        SetSpeed(client,-1.0, true);

        // Turn off Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, false);

        return Plugin_Handled;
    }
    else
    {
        if (g_dragoonRace < 0)
            g_dragoonRace = FindRace("dragoon");

        if (g_immortalRace < 0)
            g_immortalRace = FindRace("immortal");

        if (g_stalkerRace < 0)
            g_stalkerRace = FindRace("stalker");

        if (oldrace == g_dragoonRace &&
            GetCooldownExpireTime(client, raceID, dragoonID) <= 0.0)
        {
            CreateCooldown(client, raceID, dragoonID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
        else if (oldrace == g_immortalRace &&
                 GetCooldownExpireTime(client, raceID, immortalID) <= 0.0)
        {
            CreateCooldown(client, raceID, immortalID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
        else if (oldrace == g_stalkerRace &&
                 GetCooldownExpireTime(client, raceID, stalkerID) <= 0.0)
        {
            CreateCooldown(client, raceID, stalkerID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }

        return Plugin_Continue;
    }
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_ChargeActive[client] = false;

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav, client);

            // Turn on Immunities
            new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
            DoImmunity(client, immunity_level, true);

            new leg_level = GetUpgradeLevel(client,raceID,legID);
            SetSpeedBoost(client, leg_level, true, g_SpeedLevels);

            new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
            SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);
        }
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade == immunityID)
            DoImmunity(client, new_level, true);
        else if (upgrade==legID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, .upgrade=true);
        }
    }
}

public OnItemPurchase(client,item)
{
    new race=GetRace(client);
    if (race == raceID && IsValidClientAlive(client))
    {
        if (g_bootsItem < 0)
            g_bootsItem = FindShopItem("boots");

        if (item == g_bootsItem)
        {
            new leg_level = GetUpgradeLevel(client,race,legID);
            if (leg_level > 0)
                SetSpeedBoost(client, leg_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4:
            {
                new stalker_level = GetUpgradeLevel(client,race,stalkerID);
                if (stalker_level > 0)
                    SummonStalker(client);
                else
                {
                    new immortal_level = GetUpgradeLevel(client,race,immortalID);
                    if (immortal_level > 0)
                        SummonImmortal(client);
                    else
                    {
                        new dragoon_level = GetUpgradeLevel(client,race,dragoonID);
                        if (dragoon_level > 0)
                            SummonDragoon(client);
                        else
                        {
                            new charge_level = GetUpgradeLevel(client,race,chargeID);
                            if (charge_level)
                                Charge(client, race, chargeID, charge_level, 0, 10, 75.0, 50.0);
                        }
                    }
                }
            }
            case 3:
            {
                new immortal_level = GetUpgradeLevel(client,race,immortalID);
                if (immortal_level > 0)
                    SummonImmortal(client);
                else
                {
                    new dragoon_level = GetUpgradeLevel(client,race,dragoonID);
                    if (dragoon_level > 0)
                        SummonDragoon(client);
                    else
                    {
                        new charge_level=GetUpgradeLevel(client,race,chargeID);
                        if (charge_level)
                            Charge(client, race, chargeID, charge_level, 0, 10, 75.0, 50.0);
                        else
                        {
                            new stalker_level = GetUpgradeLevel(client,race,stalkerID);
                            if (stalker_level > 0)
                                SummonStalker(client);
                        }
                    }
                }
            }
            case 2:
            {
                new dragoon_level = GetUpgradeLevel(client,race,dragoonID);
                if (dragoon_level > 0)
                    SummonDragoon(client);
                else
                {
                    new charge_level=GetUpgradeLevel(client,race,chargeID);
                    if (charge_level)
                        Charge(client, race, chargeID, charge_level, 0, 10, 75.0, 50.0);
                    else
                    {
                        new immortal_level = GetUpgradeLevel(client,race,immortalID);
                        if (immortal_level > 0)
                            SummonImmortal(client);
                        else
                        {
                            new stalker_level = GetUpgradeLevel(client,race,stalkerID);
                            if (stalker_level > 0)
                                SummonStalker(client);
                        }
                    }
                }
            }
            default:
            {
                new charge_level=GetUpgradeLevel(client,race,chargeID);
                if (charge_level)
                    Charge(client, race, chargeID, charge_level, 0, 10, 75.0, 50.0);
                else
                {
                    new dragoon_level = GetUpgradeLevel(client,race,dragoonID);
                    if (dragoon_level > 0)
                        SummonDragoon(client);
                    else
                    {
                        new immortal_level = GetUpgradeLevel(client,race,immortalID);
                        if (immortal_level > 0)
                            SummonImmortal(client);
                        else
                        {
                            new stalker_level = GetUpgradeLevel(client,race,stalkerID);
                            if (stalker_level > 0)
                                SummonStalker(client);
                        }
                    }
                }
            }
        }
    }
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        m_ChargeActive[client] = false;

        PrepareAndEmitSoundToAll(spawnWav, client);

        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new leg_level = GetUpgradeLevel(client,raceID,legID);
        SetSpeedBoost(client, leg_level, true, g_SpeedLevels);

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        new blades_level=GetUpgradeLevel(attacker_index,raceID,meleeID);
        if (blades_level > 0)
        {
            if (MeleeAttack(raceID, meleeID, blades_level, event, damage+absorbed,
                            victim_index, attacker_index, g_PsiBladesPercent,
                            g_PsiBladesSound, "sc_blades"))
            {
                return Plugin_Handled;
            }
        }
    }
    return Plugin_Continue;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_race == raceID)
    {
        PrepareAndEmitSoundToAll(deathWav,victim_index);
        DissolveRagdoll(victim_index, 0.1);
    }
    else
    {
        if (g_dragoonRace < 0)
            g_dragoonRace = FindRace("dragoon");

        if (g_immortalRace < 0)
            g_immortalRace = FindRace("immortal");

        if (g_stalkerRace < 0)
            g_stalkerRace = FindRace("stalker");

        if (victim_race == g_dragoonRace &&
            GetCooldownExpireTime(victim_index, raceID, dragoonID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, dragoonID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
        else if (victim_race == g_immortalRace &&
                 GetCooldownExpireTime(victim_index, raceID, immortalID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, immortalID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
        else if (victim_race == g_stalkerRace &&
                 GetCooldownExpireTime(victim_index, raceID, stalkerID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, stalkerID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

DoImmunity(client, level, bool:value)
{
    SetImmunity(client,Immunity_HealthTaking, (value && level >= 1));
    SetImmunity(client,Immunity_Theft, (value && level >= 2));
    SetImmunity(client,Immunity_Blindness, (value && level >= 3));
    SetImmunity(client,Immunity_Upgrades, (value && level >= 4));

    if (value && IsValidClientAlive(client))
    {
        new Float:start[3];
        GetClientAbsOrigin(client, start);

        static const color[4] = { 0, 255, 50, 128 };
        TE_SetupBeamRingPoint(start,30.0,60.0,Lightning(),HaloSprite(),
                              0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
        TE_SendEffectToAll();
    }
}

SummonDragoon(client)
{
    if (g_dragoonRace < 0)
        g_dragoonRace = FindRace("dragoon");

    if (g_dragoonRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, dragoonID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Protoss Dragoon race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningDragoon");
    }
    else if (CanInvokeUpgrade(client, raceID, dragoonID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc,SmokeSprite(),8.0,2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,
                           (GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        ChangeRace(client, g_dragoonRace, true, false, true);
    }
}

SummonImmortal(client)
{
    if (g_immortalRace < 0)
        g_immortalRace = FindRace("immortal");

    if (g_immortalRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, immortalID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Protoss Immortal race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningImmortal");
    }
    else if (CanInvokeUpgrade(client, raceID, immortalID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc,SmokeSprite(),8.0,2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,
                           (GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        ChangeRace(client, g_immortalRace, true, false, true);
    }
}

SummonStalker(client)
{
    if (g_stalkerRace < 0)
        g_stalkerRace = FindRace("stalker");

    if (g_stalkerRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, stalkerID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Protoss Stalker race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningStalker");
    }
    else if (CanInvokeUpgrade(client, raceID, stalkerID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc,SmokeSprite(),8.0,2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,
                           (GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        ChangeRace(client, g_stalkerRace, true, false, true);
    }
}
