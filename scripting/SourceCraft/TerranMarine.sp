/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranMarine.sp
 * Description: The Terran Marine unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/bunker"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:g_ArmorName[]      = "Armor";
new Float:g_InitialArmor[]          = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]       = { {0.00, 0.00},
                                        {0.00, 0.10},
                                        {0.00, 0.20},
                                        {0.10, 0.40},
                                        {0.20, 0.50} };

new Float:g_SpeedLevels[]           = { -1.0, 1.05, 1.07, 1.10, 1.13 };

new Float:g_BunkerPercent[]         = { 0.00, 0.10, 0.20, 0.30, 0.40 };

new Float:g_U238Percent[]           = { 0.0, 0.15, 0.30, 0.40, 0.50 };

new Float:g_CombatShieldHealth[]    = { 0.0, 0.10, 0.20, 0.30, 0.40 };

new raceID, u238ID, armorID, stimpacksID, bunkerID, combatShieldID, firebatID, marauderID;

new g_firebatRace = -1;
new g_marauderRace = -1;

public Plugin:myinfo = 
{
    name = "SourceCraft Unit - Terran Marine",
    author = "-=|JFH|=-Naris",
    description = "The Terran Marine unit for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.marine.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("marine", 16, 0, 22, .faction=Terran,
                                 .type=Biological);

    u238ID          = AddUpgrade(raceID, "u238", .energy=2.0, .cost_crystals=20);
    armorID         = AddUpgrade(raceID, "armor", .cost_crystals=5);
    stimpacksID     = AddUpgrade(raceID, "stimpacks", .cost_crystals=0);
    combatShieldID  = AddUpgrade(raceID, "combat_shield", .cost_crystals=5);

    // Ultimate 1
    bunkerID        = AddBunkerUpgrade(raceID, 1, 6, .energy=10.0,
                                       .cooldown=2.0, .cost_crystals=10);

    // Ultimate 3
    marauderID      = AddUpgrade(raceID, "marauder", 3, 10,1, .energy=200.0,
                                 .cooldown=30.0, .accumulated=true, .cost_crystals=50);

    // Ultimate 4
    firebatID       = AddUpgrade(raceID, "firebat", 4, 8,1, .energy=150.0,
                                 .cooldown=30.0, .accumulated=true, .cost_crystals=50);

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

    GetConfigFloatArray("bunker_armor", g_BunkerPercent, sizeof(g_BunkerPercent),
                        g_BunkerPercent, raceID, bunkerID);

    GetConfigFloatArray("damage_percent", g_U238Percent, sizeof(g_U238Percent),
                        g_U238Percent, raceID, u238ID);

    GetConfigFloatArray("speed",  g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, stimpacksID);

    GetConfigFloatArray("health_percent",  g_CombatShieldHealth, sizeof(g_CombatShieldHealth),
                        g_CombatShieldHealth, raceID, combatShieldID);
}

public OnMapStart()
{
    SetupSmokeSprite();
    SetupHaloSprite();
    SetupLightning();
    SetupBlueGlow();
    SetupRedGlow();

    SetupSpeed();

    //SetupBunker();
    SetupDeniedSound();
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);
        SetSpeed(client, -1.0, true);
        return Plugin_Handled;
    }
    else
    {
        if (g_firebatRace < 0)
            g_firebatRace = FindRace("firebat");

        if (g_marauderRace < 0)
            g_marauderRace = FindRace("marauder");

        if (oldrace == g_firebatRace &&
            GetCooldownExpireTime(client, raceID, firebatID) <= 0.0)
        {
            CreateCooldown(client, raceID, firebatID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
        else if (oldrace == g_marauderRace &&
                 GetCooldownExpireTime(client, raceID, marauderID) <= 0.0)
        {
            CreateCooldown(client, raceID, marauderID,
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
        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        new armor = SetupArmor(client, armor_level, g_InitialArmor,
                               g_ArmorPercent, g_ArmorName);

        new shield_level=GetUpgradeLevel(client,raceID,combatShieldID);
        CombatShield(client, shield_level, armor);

        new stimpacks_level = GetUpgradeLevel(client,raceID,stimpacksID);
        SetSpeedBoost(client, stimpacks_level, true, g_SpeedLevels);

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
        else if (upgrade==stimpacksID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
    }
}

public OnItemPurchase(client,item)
{
    if (GetRace(client) == raceID && IsValidClientAlive(client))
    {
        if (g_bootsItem < 0)
            g_bootsItem = FindShopItem("boots");

        if (item == g_bootsItem)
        {
            new level=GetUpgradeLevel(client,raceID,stimpacksID);
            if (level > 0)
                SetSpeedBoost(client, level, true, g_SpeedLevels);
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
                new firebat_level=GetUpgradeLevel(client,race,firebatID);
                if (firebat_level > 0)
                    FirebatTraining(client);
            }
            case 3:
            {
                new marauder_level=GetUpgradeLevel(client,race,marauderID);
                if (marauder_level > 0)
                    MarauderTraining(client);
            }
            default:
            {
                new bunker_level = GetUpgradeLevel(client,race,bunkerID);
                if (bunker_level > 0)
                {
                    new armor = RoundToNearest(float(GetPlayerMaxHealth(client))
                                               * g_BunkerPercent[bunker_level]);

                    EnterBunker(client, armor, raceID, bunkerID);
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
        new stimpacks_level = GetUpgradeLevel(client,raceID,stimpacksID);
        if (stimpacks_level > 0)
            SetSpeedBoost(client, stimpacks_level, true, g_SpeedLevels);

        new shield_level=GetUpgradeLevel(client,raceID,combatShieldID);
        if (shield_level > 0)
        {
            CreateTimer(0.1,DoCombatShield,GetClientUserId(client),
                        TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            new armor_level = GetUpgradeLevel(client,raceID,armorID);
            SetupArmor(client, armor_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName);
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (U238Shells(event, damage, victim_index, attacker_index))
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
        if (U238Shells(event, damage, victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (g_firebatRace < 0)
        g_firebatRace = FindRace("firebat");

    if (g_marauderRace < 0)
        g_marauderRace = FindRace("marauder");

    if (victim_race == g_firebatRace &&
        GetCooldownExpireTime(victim_index, raceID, firebatID) <= 0.0)
    {
        CreateCooldown(victim_index, raceID, firebatID,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
    else if (victim_race == g_marauderRace &&
             GetCooldownExpireTime(victim_index, raceID, marauderID) <= 0.0)
    {
        CreateCooldown(victim_index, raceID, marauderID,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
}

bool:U238Shells(Handle:event, damage, victim_index, index)
{
    new u238_level = GetUpgradeLevel(index,raceID,u238ID);
    if (u238_level > 0)
    {
        if (!GetRestriction(index,Restriction_NoUpgrades) &&
            !GetRestriction(index,Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_HealthTaking) &&
            !GetImmunity(victim_index,Immunity_Upgrades) &&
            !IsInvulnerable(victim_index))
        {
            if (GetRandomInt(1,100)<=25)
            {
                decl String:weapon[64];
                new bool:is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
                if (!IsMelee(weapon, is_equipment,index,victim_index))
                {
                    new health_take = RoundFloat(float(damage)*g_U238Percent[u238_level]);
                    if (health_take > 0 && CanInvokeUpgrade(index, raceID, u238ID, .notify=false))
                    {
                        HurtPlayer(victim_index, health_take, index,
                                   "sc_u238_shells", .type=DMG_BULLET,
                                   .in_hurt_event=true);

                        if (IsClient(index))
                        {
                            new Float:indexLoc[3];
                            GetClientAbsOrigin(index, indexLoc);
                            indexLoc[2] += 50.0;

                            new Float:victimLoc[3];
                            GetEntityAbsOrigin(victim_index, victimLoc);
                            victimLoc[2] += 50.0;

                            static const color[4] = { 100, 255, 55, 255 };
                            TE_SetupBeamPoints(indexLoc, victimLoc, Lightning(), HaloSprite(),
                                               0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                            TE_SendQEffectToAll(index, victim_index);
                            FlashScreen(victim_index,RGBA_COLOR_RED);
                        }
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

public Action:DoCombatShield(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        if (GetRace(client) == raceID)
        {
            new armor_level = GetUpgradeLevel(client,raceID,armorID);
            new armor = SetupArmor(client, armor_level, g_InitialArmor, g_ArmorPercent);

            new shield_level=GetUpgradeLevel(client,raceID,combatShieldID);
            CombatShield(client, shield_level, armor);
        }
    }
    return Plugin_Stop;
}

CombatShield(client, level, armor)
{
    if (level > 0 && IsValidClient(client) &&
        !GetRestriction(client, Restriction_NoUpgrades) &&
        !GetRestriction(client, Restriction_Stunned))
    {
        new classmax = GetPlayerMaxHealth(client);
        new maxhp = GetMaxHealth(client);
        if (maxhp > classmax)
            maxhp = classmax;

        new hpadd=RoundFloat(float(maxhp)*g_CombatShieldHealth[level]);
        if (GetClientHealth(client) < classmax + hpadd)
        {
            SetIncreasedHealth(client, hpadd, armor);
            DisplayMessage(client,Display_Message, "%t",
                           "HPFromCombatShield", hpadd);
        }
    }
}

FirebatTraining(client)
{
    if (g_firebatRace < 0)
        g_firebatRace = FindRace("firebat");

    if (g_firebatRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, firebatID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
        LogError("***The Terran Firebat race is not Available!");
    }
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromTrainingFirebat");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, firebatID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_firebatRace, true, false, true);
    }
}

MarauderTraining(client)
{
    if (g_marauderRace < 0)
        g_marauderRace = FindRace("marauder");

    if (g_marauderRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, marauderID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
        LogError("***The Terran Marauder race is not Available!");
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromTrainingMarauder");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, marauderID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_marauderRace, true, false, true);
    }
}

