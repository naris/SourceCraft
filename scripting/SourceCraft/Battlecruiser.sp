/**
 * vim: set ai et ts=4 sw=4 :
 * File: Battlecruiser.sp
 * Description: The Terran Battlecruiser race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_objects>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include "jetpack"
#include "ztf2grab"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/freeze"
#include "sc/sounds"
#include "sc/armor"

#include "effect/Lightning"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:buildWav[]         = "sc/tbardy00.wav";
new const String:deathWav[]         = "sc/tbadth00.wav";
new const String:barrageWav[]       = "sc/hkmissle.wav";
new const String:yamatoFireWav[]    = "sc/tbayam00.wav";
new const String:yamatoRepeatWav[]  = "sc/tbayam02.wav";
new const String:explosionsWav[][]  = { "sc/explo1.wav",
                                        "sc/explo2.wav",
                                        "sc/explo3.wav",
                                        "sc/explo4.wav",
                                        "sc/explo5.wav",
                                        "sc/explosm.wav",
                                        "sc/explomed.wav",
                                        "sc/explolrg.wav" };

new const String:g_ArmorName[]      = "Plating";
new Float:g_InitialArmor[]          = { 0.05, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ArmorPercent[][2]       = { {0.00, 0.10},
                                        {0.05, 0.20},
                                        {0.15, 0.30},
                                        {0.20, 0.40},
                                        {0.25, 0.50} };

new g_JetpackFuel[]                 = { 40,   50,   70,   90,   120 };
new Float:g_JetpackRefuelTime[]     = { 45.0, 35.0, 25.0, 15.0, 5.0 };

new Float:g_GravgunSpeed[]          = { 0.10, 0.30, 0.50, 0.70, 0.90 };

new Float:g_ShipWeaponsDamage[]     = { 0.15, 0.30, 0.40, 0.50, 0.70 };

new Float:g_BarrageRange[]          = { 0.0, 250.0, 400.0, 550.0, 650.0 };

new Float:g_YamatoRange[]           = { 350.0, 400.0, 650.0, 750.0, 900.0 };
new g_YamatoDamage[][2]             = { {25,   50},
                                        {75,  100},
                                        {100, 150},
                                        {125, 200},
                                        {150, 250} };

new cfgAllowGravgun                 = 2;
new bool:cfgAllowRepair             = true;
new bool:cfgAllowEnabled            = true;
new Float:cfgGravgunDuration        = 15.0;
new Float:cfgGravgunThrowSpeed      = 500.0;

new raceID, immunityID, armorID, weaponsID, gravAccelID, jetpackID, yamatoID, barrageID;

new gMissileBarrageDuration[MAXPLAYERS+1];
new Float:m_GravTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Battlecruiser",
    author = "-=|JFH|=-Naris",
    description = "The Terran Battlecruiser race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.battlecruiser.phrases.txt");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("battlecruiser", -1, -1, 28, 60.0, -1.0, 1.0,
                             Terran, Mechanical, "scv");

    immunityID  = AddUpgrade(raceID, "immunity", 0, 0);
    armorID     = AddUpgrade(raceID, "armor",    0, 0);
    weaponsID   = AddUpgrade(raceID, "weapons",  0, 0, .energy=2.0);

    // Ultimate 2
    jetpackID   = AddUpgrade(raceID, "jetpack", 2, 0);

    if (!IsJetpackAvailable())
    {
        SetUpgradeDisabled(raceID, jetpackID, true);
        LogMessage("jetpack is not available");
    }

    // Ultimate 1
    if (GetGameType() != tf2)
    {
        gravAccelID = AddUpgrade(raceID, "gravgun", 1, 10, 1, .energy=10.0, .recurring_energy=10.0, .cooldown=2.0,
                                 .desc="%battlecruiser_gravgun_notf2_desc" );
    }
    else
    {
        cfgAllowEnabled = bool:GetConfigNum("allow_enable", cfgAllowEnabled, .section="gravgun");
        cfgAllowRepair = bool:GetConfigNum("allow_repair", cfgAllowRepair, .section="gravgun");

        if (cfgAllowRepair)
        {
            gravAccelID = AddUpgrade(raceID, "gravgun", 1, 0, .energy=10.0, .recurring_energy=10.0, .cooldown=2.0,
                                     .desc=(cfgAllowGravgun >= 2) ? "%battlecruiser_gravgun_desc"
                                     : "%battlecruiser_gravgun_engyonly_desc");
        }
        else if (cfgAllowEnabled)
        {
            gravAccelID = AddUpgrade(raceID, "gravgun", 1, 0, .energy=10.0, .recurring_energy=10.0, .cooldown=2.0,
                                     .desc=(cfgAllowGravgun >= 2) ? "%battlecruiser_gravgun_norepair_desc"
                                     : "%battlecruiser_gravgun_norepair_engyonly_desc");
        }
        else
        {
            gravAccelID = AddUpgrade(raceID, "gravgun", 1, 0, 2, .energy=10.0, .recurring_energy=10.0, .cooldown=2.0, .name="",
                                     .desc=(cfgAllowGravgun >= 2) ? "%battlecruiser_gravgun_noenable_desc"
                                     : "%battlecruiser_gravgun_noenable_engyonly_desc");
        }
    }

    cfgAllowGravgun = GetConfigNum("allow_use", cfgAllowGravgun, .section="gravgun");

    if (!IsGravgunAvailable())
    {
        SetUpgradeDisabled(raceID, gravAccelID, true);
        LogMessage("ztf2grab is not available");
    }
    else if (cfgAllowGravgun < 1)
    {
        SetUpgradeDisabled(raceID, gravAccelID, true);
        LogMessage("Disabling Terran Battlecruiser:Gravity Accelerator due to configuration: sc_allow_gravgun=%d",
                   cfgAllowGravgun);
    }

    // Ultimate 3
    yamatoID  = AddUpgrade(raceID, "yamato", 3, 8, .energy=60.0, .cooldown=2.0);

    // Ultimate 4
    barrageID = AddUpgrade(raceID, "barrage", 4, 6, .energy=60.0, .cooldown=2.0);

    // Get Configuration Data
    GetConfigFloatArray("armor_amount", g_InitialArmor, sizeof(g_InitialArmor),
                        g_InitialArmor, raceID, armorID);

    for (new level=0; level < sizeof(g_ArmorPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "armor_percent_level_%d", level);
        GetConfigFloatArray(key, g_ArmorPercent[level], sizeof(g_ArmorPercent[]),
                            g_ArmorPercent[level], raceID, armorID);
    }

    GetConfigArray("fuel", g_JetpackFuel, sizeof(g_JetpackFuel),
                   g_JetpackFuel, raceID, jetpackID);

    GetConfigFloatArray("refuel_time", g_JetpackRefuelTime, sizeof(g_JetpackRefuelTime),
                        g_JetpackRefuelTime, raceID, jetpackID);

    cfgGravgunDuration=GetConfigFloat("duration", cfgGravgunDuration, raceID, gravAccelID);
    cfgGravgunThrowSpeed=GetConfigFloat("throw_speed", cfgGravgunThrowSpeed, raceID, gravAccelID);

    GetConfigFloatArray("speed", g_GravgunSpeed, sizeof(g_GravgunSpeed),
                        g_GravgunSpeed, raceID, gravAccelID);

    GetConfigFloatArray("range", g_YamatoRange, sizeof(g_YamatoRange),
                        g_YamatoRange, raceID, yamatoID);

    for (new level=0; level < sizeof(g_YamatoDamage); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "damage_level_%d", level);
        GetConfigArray(key, g_YamatoDamage[level], sizeof(g_YamatoDamage[]),
                       g_YamatoDamage[level], raceID, yamatoID);
    }

    GetConfigFloatArray("range", g_BarrageRange, sizeof(g_BarrageRange),
                        g_BarrageRange, raceID, barrageID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "ztf2grab"))
        IsGravgunAvailable(true);
    else if (StrEqual(name, "jetpack"))
        IsJetpackAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "ztf2grab"))
        m_GravgunAvailable = false;
    else if (StrEqual(name, "jetpack"))
        m_JetpackAvailable = false;
}

public OnMapStart()
{
    SetupLightning();
    SetupBeamSprite();
    SetupHaloSprite();

    SetupErrorSound();
    SetupDeniedSound();

    SetupSound(buildWav);
    SetupSound(deathWav);
    SetupSound(barrageWav);
    SetupSound(yamatoFireWav);
    SetupSound(yamatoRepeatWav);

    for (new i = 0; i < sizeof(explosionsWav); i++)
        SetupSound(explosionsWav[i]);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);

        // Turn off Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, false);

        if (m_JetpackAvailable)
            TakeJetpack(client);

        if (m_GravgunAvailable)
            TakeGravgun(client);
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        // Turn on Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level,true);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new gravaccel_level=GetUpgradeLevel(client,raceID,gravAccelID);
        SetupGravgun(client, gravaccel_level);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(buildWav,client);
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
        if (upgrade==armorID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade == immunityID)
            DoImmunity(client, new_level, true);
        else if (upgrade==jetpackID)
            SetupJetpack(client, new_level);
        else if (upgrade==gravAccelID)
            SetupGravgun(client, new_level);
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4:
            {
                if (pressed)
                {
                    new barrage_level=GetUpgradeLevel(client,race,barrageID);
                    if (barrage_level > 0)
                        MissileBarrage(client,barrage_level);
                    else
                    {
                        new yamato_level=GetUpgradeLevel(client,race,yamatoID);
                        if (yamato_level && pressed)
                            YamatoCannon(client,yamato_level);
                    }
                }
            }
            case 3:
            {
                if (pressed)
                {
                    new yamato_level=GetUpgradeLevel(client,race,yamatoID);
                    if (yamato_level)
                        YamatoCannon(client,yamato_level);
                    else
                    {
                        new barrage_level=GetUpgradeLevel(client,race,barrageID);
                        if (barrage_level > 0)
                            MissileBarrage(client,barrage_level);
                    }
                }
            }
            case 2:
            {
                if (m_JetpackAvailable)
                {
                    if (pressed)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Grounded) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToAll(deniedWav, client);
                        }
                        else
                            StartJetpack(client);
                    }
                    else
                        StopJetpack(client);
                }
                else if (pressed)
                {
                    decl String:upgradeName[64];
                    GetUpgradeName(raceID, jetpackID, upgradeName, sizeof(upgradeName), client);
                    PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                }
            }
            default:
            {
                if (!m_GravgunAvailable || cfgAllowGravgun < 1)
                {
                    if (pressed)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, gravAccelID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
                else
                {
                    if (cfgAllowGravgun < 2 && GetGameType() == tf2 &&
                        TF2_GetPlayerClass(client) != TFClass_Engineer)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, gravAccelID, upgradeName, sizeof(upgradeName), client);
                        DisplayMessage(client, Display_Ultimate, "%t", "EngineersOnly", upgradeName);
                        PrepareAndEmitSoundToClient(client,deniedWav);
                    }
                    else
                    {
                        if (pressed)
                        {
                            if (GetRestriction(client,Restriction_NoUltimates) ||
                                GetRestriction(client,Restriction_Stunned))
                            {
                                decl String:upgradeName[64];
                                GetUpgradeName(raceID, gravAccelID, upgradeName, sizeof(upgradeName), client);
                                DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                                PrepareAndEmitSoundToClient(client,deniedWav);
                            }
                            else if (CanInvokeUpgrade(client, raceID, gravAccelID, .charge=false))
                                StartThrowObject(client);
                        }
                        else // if (!pressed)
                            ThrowObject(client);
                    }
                }
            }
        }
    }
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        SetOverrideSpeed(client, -1.0);

        new immunity_level = GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new gravaccel_level=GetUpgradeLevel(client,raceID,gravAccelID);
        SetupGravgun(client, gravaccel_level);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        PrepareAndEmitSoundToAll(buildWav,client);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (ShipWeapons(damage + absorbed, victim_index, attacker_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if (assister_race == raceID)
    {
        if (ShipWeapons(damage + absorbed, victim_index, assister_index))
            return Plugin_Handled;
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
        SetOverrideSpeed(victim_index, -1.0);
    }
}

DoImmunity(client, level, bool:value)
{
    SetImmunity(client,Immunity_ShopItems, value);
    SetImmunity(client,Immunity_Theft, (value && level >= 1));
    SetImmunity(client,Immunity_Ultimates, (value && level >= 2));
    SetImmunity(client,Immunity_MotionTaking, (value && level >= 3));
    SetImmunity(client,Immunity_Blindness, (value && level >= 4));

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

public SetupGravgun(client, level)
{
    if (m_GravgunAvailable)
    {
        if (cfgAllowGravgun >= 2 || (cfgAllowGravgun >= 1 && (GameType != tf2 || TF2_GetPlayerClass(client) == TFClass_Engineer)))
        {
            new Float:speed = cfgGravgunThrowSpeed * float(level);
            new Float:duration = cfgGravgunDuration * float(level);
            new permissions=HAS_GRABBER|CAN_STEAL|CAN_JUMP_WHILE_HOLDING;

            if (GameType == tf2)
            {
                permissions |= CAN_GRAB_BUILDINGS|CAN_GRAB_OTHER_BUILDINGS;

                if (level >= 1 && cfgAllowRepair)
                    permissions |= CAN_REPAIR_WHILE_HOLDING;

                if (level >= 2)
                    permissions |= CAN_THROW_BUILDINGS;

                if (cfgAllowEnabled)
                {
                    if (level >= 3)
                        permissions |= CAN_HOLD_ENABLED_BUILDINGS;

                    if (level >= 4)
                        permissions |= CAN_THROW_ENABLED_BUILDINGS;
                }
            }
            else
                permissions |= CAN_GRAB_PROPS;

            GiveGravgun(client, duration, speed, 2.0, permissions);
        }
        else
            TakeGravgun(client);
    }
}

public Action:OnPickupObject(client, builder, ent)
{
    if (GetRace(client) == raceID)
    {
        if (builder > 0 && builder != client)
        {
            if (GetImmunity(builder,Immunity_Ultimates))
            {
                PrepareAndEmitSoundToClient(client,errorWav);
                DisplayMessage(client, Display_Ultimate,
                               "%t", "TargetIsImmune");
                return Plugin_Stop;
            }
        }

        if (m_JetpackAvailable && IsJetpackOn(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, gravAccelID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            return Plugin_Stop;
        }
        else if (CanInvokeUpgrade(client, raceID, gravAccelID))
        {
            m_GravTime[client] = GetEngineTime();

            new grav_level = GetUpgradeLevel(client,raceID,gravAccelID);
            SetOverrideSpeed(client, g_GravgunSpeed[grav_level], true);
        }
    }

    return Plugin_Continue;
}

public Action:OnCarryObject(client,ent,Float:time)
{
    if (GetRace(client) == raceID)
    {
        if (m_JetpackAvailable && IsJetpackOn(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, gravAccelID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            return Plugin_Stop;
        }
        else
        {
            new Float:now = GetEngineTime();
            new Float:amount = GetUpgradeRecurringEnergy(raceID,gravAccelID);
            if (now-m_GravTime[client] > amount)
            {
                new level = GetUpgradeLevel(client,raceID,gravAccelID);
                if (level < 3 || !GetEntProp(ent, Prop_Send, "m_bDisabled"))
                {
                    decl String:upgradeName[64];
                    GetUpgradeName(raceID, gravAccelID, upgradeName, sizeof(upgradeName), client);

                    if (CanProcessUpgrade(client, raceID, gravAccelID))
                    {
                        m_GravTime[client] = now;
                        DisplayMessage(client, Display_Energy, "%t", "ConsumedEnergy",
                                       upgradeName, amount);
                        return Plugin_Continue;
                    }
                    else
                    {
                        EmitEnergySoundToClient(client,Terran);
                        DisplayMessage(client, Display_Energy, "%t", "OutOfEnergy", upgradeName);

                        if (level < 3)
                            return Plugin_Stop;
                        else
                        {
                            SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
                            return Plugin_Changed;
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public OnDropObject(client, ent)
{
    if (GetRace(client) == raceID)
    {
        SetOverrideSpeed(client, -1.0, true);
        CreateCooldown(client, raceID, gravAccelID);
    }
}

public Action:OnThrowObject(client, ent)
{
    OnDropObject(client, ent);
    return Plugin_Continue;
}

public bool:ShipWeapons(damage, victim_index, index)
{
    if (!GetRestriction(index,Restriction_NoUpgrades) &&
        !GetRestriction(index,Restriction_Stunned) &&
        !GetImmunity(victim_index, Immunity_HealthTaking) &&
        !GetImmunity(victim_index, Immunity_Upgrades) &&
        !IsInvulnerable(victim_index))
    {
        if (GetRandomInt(1,100) <= GetRandomInt(30,60))
        {
            if (CanInvokeUpgrade(index, raceID, weaponsID))
            {
                new level = GetUpgradeLevel(index, raceID, weaponsID);
                new Float:percent = g_ShipWeaponsDamage[level];
                new dmgamt = RoundFloat(float(damage)*percent);
                if (dmgamt > 0)
                {
                    new Float:Origin[3];
                    GetEntityAbsOrigin(victim_index, Origin);
                    Origin[2] += 5;

                    TE_SetupSparks(Origin,Origin,255,1);
                    TE_SendEffectToAll();

                    FlashScreen(victim_index,RGBA_COLOR_RED);
                    HurtPlayer(victim_index, dmgamt, index, "sc_ship_weapons",
                               .type=DMG_BULLET, .in_hurt_event=true);
                    return true;
                }
            }
        }
    }
    return false;
}

SetupJetpack(client, level)
{
    if (m_JetpackAvailable)
    {
        if (level >= sizeof(g_JetpackFuel))
        {
            LogError("%d:%N has too many levels in Battlecruiser::ShipPropulsion level=%d, max=%d",
                     client,ValidClientIndex(client),level,sizeof(g_JetpackFuel));

            level = sizeof(g_JetpackFuel)-1;
        }
        GiveJetpack(client, g_JetpackFuel[level], g_JetpackRefuelTime[level],
                    .explode = (level > 2), .burn = (level > 3));
    }
}

public MissileBarrage(client,ultlevel)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "PreventedFromLaunchingMissileBarrage");
    }
    else if (CanInvokeUpgrade(client, raceID, barrageID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        gMissileBarrageDuration[client] = (ultlevel+1)*3;

        new Handle:MissileBarrageTimer = CreateTimer(0.4, PersistMissileBarrage,
                                                     GetClientUserId(client),
                                                     TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        TriggerTimer(MissileBarrageTimer, true);

        CreateCooldown(client, raceID, barrageID);
    }
}

public Action:PersistMissileBarrage(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client) &&
        !GetRestriction(client,Restriction_NoUltimates) &&
        !GetRestriction(client,Restriction_Stunned))
    {
        new level = GetUpgradeLevel(client,raceID,barrageID);
        new Float:range = g_BarrageRange[level];

        new Float:indexLoc[3];
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        PrepareAndEmitSoundToAll(barrageWav,client);

        new count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, count, alt_count, client);

        new lightning  = Lightning();
        new haloSprite = HaloSprite();
        static const barrageColor[4] = { 200, 200, 100, 255 };

        if (count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, 10.0, range, lightning, haloSprite,
                                  0, 15, 0.5, 5.0, 0.0, barrageColor, 10, 0);

            TE_Send(list, count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, range-10.0, range, lightning, haloSprite,
                                  0, 15, 0.5, 5.0, 0.0, barrageColor, 10, 0);

            TE_Send(alt_list, alt_count, 0.0);
        }

        new minDmg=level*5;
        new maxDmg=level*10;
        new team=GetClientTeam(client);
        for(new index=1;index<=MaxClients;index++)
        {
            if (client != index && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_HealthTaking) &&
                    !IsInvulnerable(index))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(clientLoc,indexLoc,range) &&
                        TraceTargetIndex(client, index, clientLoc, indexLoc))
                    {
                        new num = GetRandomInt(0,sizeof(explosionsWav)-1);
                        PrepareAndEmitSoundToAll(explosionsWav[num], index);
                            
                        TE_SetupBeamPoints(clientLoc,indexLoc, lightning, haloSprite,
                                           0, 1, 10.0, 10.0,10.0,2,50.0,barrageColor,255);
                        TE_SendQEffectToAll(client,index);

                        new amt=GetRandomInt(minDmg,maxDmg);
                        HurtPlayer(index, amt, client, "sc_barrage",
                                   .xp=5+level, .type=DMG_BLAST);
                    }
                }
            }
        }
        if (--gMissileBarrageDuration[client] > 0)
            return Plugin_Continue;
    }
    return Plugin_Stop;
}

YamatoCannon(client,level)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "PreventedFromFiringYamatoCannon");
    }
    else if (CanInvokeUpgrade(client, raceID, yamatoID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        new Float:range = g_YamatoRange[level];
        new dmg = GetRandomInt(g_YamatoDamage[level][0],
                               g_YamatoDamage[level][1]);

        new Float:indexLoc[3];
        new Float:targetLoc[3];
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        new lightning  = Lightning();
        new haloSprite = HaloSprite();
        new beamSprite = BeamSprite();
        static const yamatoColor[4] = {139, 200, 255, 255};
        static const yamatoFlash[4] = {139, 200, 255, 3};

        new count  = 0;
        new team   = GetClientTeam(client);
        new target = GetClientAimTarget(client);
        if (target > 0) 
        {
            GetClientAbsOrigin(target, targetLoc);
            targetLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

            if (TraceTargetIndex(target, client, targetLoc, clientLoc))
            {
                if (GetClientTeam(target) != team &&
                    !GetImmunity(target,Immunity_Ultimates) &&
                    !GetImmunity(target,Immunity_HealthTaking) &&
                    !IsInvulnerable(target))
                {
                    TE_SetupBeamPoints(clientLoc,targetLoc, lightning, haloSprite,
                                       0, 1, 10.0, 50.0,100.0,2,50.0,yamatoColor,255);
                    TE_SendQEffectToAll(client,target);
                    FlashScreen(target,yamatoFlash);

                    HurtPlayer(target, dmg, client, "sc_yamato_cannon",
                               .xp=5+level, .limit=0.95, .type=DMG_ENERGYBEAM);

                    FreezeEntity(target);
                    CreateTimer(2.0,UnfreezePlayer,GetClientUserId(target),TIMER_FLAG_NO_MAPCHANGE);

                    dmg -= GetRandomInt(10,20);
                    count++;
                }
            }
            else
            {
                target = client;
                targetLoc = clientLoc;
            }
        }
        else
        {
            target = client;
            targetLoc = clientLoc;
        }

        new b_count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

        if (b_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, 10.0, range, beamSprite, haloSprite,
                                  0, 15, 0.5, 50.0, 0.0, yamatoColor, 10, 0);

            TE_Send(list, b_count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, range-10.0, range, beamSprite, haloSprite,
                                  0, 15, 0.5, 50.0, 0.0, yamatoColor, 10, 0);

            TE_Send(alt_list, alt_count, 0.0);
        }

        PrepareAndEmitSoundToAll(yamatoFireWav, client);

        for (new index=1;index<=MaxClients;index++)
        {
            if (client != index && client != target && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_HealthTaking) &&
                    !IsInvulnerable(index))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(targetLoc,indexLoc,range) &&
                        TraceTargetIndex(target, index, targetLoc, indexLoc))
                    {
                        PrepareAndEmitSoundToAll(yamatoRepeatWav, index);
                            
                        TE_SetupBeamPoints(clientLoc, indexLoc, lightning, haloSprite,
                                           0, 1, 10.0, 50.0,100.0,2,50.0,yamatoColor,255);
                        TE_SendQEffectToAll(client,index);
                        FlashScreen(index,yamatoFlash);

                        HurtPlayer(index, dmg, client, "sc_yamato_cannon",
                                   .xp=5+level, .limit=0.95, .type=DMG_ENERGYBEAM);

                        FreezeEntity(index);
                        CreateTimer(2.0,UnfreezePlayer,GetClientUserId(index),TIMER_FLAG_NO_MAPCHANGE);

                        count++;
                        dmg -= GetRandomInt(10,20);
                        if (dmg <= 0)
                            break;
                    }
                }
            }
        }

        decl String:upgradeName[64];
        GetUpgradeName(raceID, yamatoID, upgradeName, sizeof(upgradeName), client);

        if (count)
        {
            DisplayMessage(client, Display_Ultimate, "%t",
                           "ToDamageEnemies", upgradeName, count);
        }
        else
        {
            DisplayMessage(client, Display_Ultimate, "%t",
                           "WithoutEffect", upgradeName);
        }

        CreateCooldown(client, raceID, yamatoID);
    }
}

