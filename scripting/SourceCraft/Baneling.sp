/**
 * vim: set ai et ts=4 sw=4 :
 * File: Baneling.sp
 * Description: The Baneling race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/PlagueInfect"
#include "sc/MeleeAttack"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/burrow"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/HaloSprite"
#include "effect/SendEffects"
//#include "effect/FlashScreen"
#include "effect/Shake"

new raceID, boostID, rollID, meleeID, explodeID, volatileID;

new Float:g_SpeedLevels[]           = {  0.60,  0.70,  0.80,  1.00, 1.10 };
new Float:g_AdrenalGlandsPercent[]  = {  0.15,  0.30,  0.40,  0.50, 0.70 };
new Float:g_ExplodeRadius[]         = { 300.0, 450.0, 500.0, 650.0, 800.0 };
new g_ExplodePlayerDamage[]         = {   800,   900,  1000,  1100, 1200  };
new g_ExplodeBuildingDamage[]       = {  1000,  1250,  1500,  1750, 2000  };

new const String:spawnWav[] = "sc/zzeyes02.wav";  // Spawn sound
new const String:deathWav[] = "sc/zbghit00.wav";  // Death sound
new const String:g_AdrenalGlandsSound[] = "sc/zulhit00.wav";

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Baneling",
    author = "-=|JFH|=-Naris",
    description = "The Baneling race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.explode.phrases.txt");
    LoadTranslations("sc.baneling.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID     = CreateRace("baneling", -1, -1, 21, .faction=Zerg,
                            .type=Biological, .parent="zergling");

    boostID    = AddUpgrade(raceID, "hooks", 0, 0);
    meleeID    = AddUpgrade(raceID, "adrenal_glands", 0, 0, .energy=2.0);

    // Ultimate 1
    rollID     = AddUpgrade(raceID, "roll", 1, 0, .energy=20.0);

    // Ultimate 2
    AddBurrowUpgrade(raceID, 2, 0, 1, 1);

    // Ultimate 3
    explodeID  = AddUpgrade(raceID, "explode", 3, 0);

    volatileID = AddUpgrade(raceID, "volatile", 0, 8);

    // Get Configuration Data
    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, boostID);

    GetConfigFloatArray("damage_percent", g_AdrenalGlandsPercent, sizeof(g_AdrenalGlandsPercent),
                        g_AdrenalGlandsPercent, raceID, meleeID);

    GetConfigFloatArray("range", g_ExplodeRadius, sizeof(g_ExplodeRadius),
                        g_ExplodeRadius, raceID, explodeID);

    GetConfigArray("player_damage", g_ExplodePlayerDamage, sizeof(g_ExplodePlayerDamage),
                   g_ExplodePlayerDamage, raceID, explodeID);

    GetConfigArray("building_damage", g_ExplodeBuildingDamage, sizeof(g_ExplodeBuildingDamage),
                   g_ExplodeBuildingDamage, raceID, explodeID);
}

public OnMapStart()
{
    SetupSpeed();
    SetupSmokeSprite();

    SetupDeniedSound();

    SetupSound(g_AdrenalGlandsSound);
    SetupSound(spawnWav);
    SetupSound(deathWav);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        SetSpeed(client,-1.0);
        SetVisibility(client, NormalVisibility);
        ApplyPlayerSettings(client);
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        //Set Baneling Color
        new r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 255; g = 165; b = 0; }
        else
        { r = 0; g = 224; b = 208; }
        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b);

        new boost_level = GetUpgradeLevel(client,raceID,boostID);
        SetSpeedBoost(client, boost_level, true, g_SpeedLevels);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav,client);
        }
    }
    return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==boostID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
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
            new boost_level = GetUpgradeLevel(client,race,boostID);
            SetSpeedBoost(client, boost_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4,3:
            {
                if (GetRestriction(client,Restriction_NoUltimates) ||
                    GetRestriction(client,Restriction_Stunned))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    DisplayMessage(client, Display_Ultimate,
                                   "%t", "PreventedFromExploding");
                }
                else if (GameType == tf2 && TF2_IsPlayerDisguised(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                }
                else
                    Explode(client,false);
            }
            case 2:
            {
                new burrow_level=GetUpgradeLevel(client,race,burrowID);
                Burrow(client, burrow_level+1);
            }
            default:
            {
                new roll_level=GetUpgradeLevel(client,race,rollID);
                Roll(client, roll_level);
            }
        }
    }
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        PrepareAndEmitSoundToAll(spawnWav,client);

        //Set Baneling Color
        new r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 255; g = 165; b = 0; }
        else
        { r = 0; g = 224; b = 208; }

        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b);

        new boost_level = GetUpgradeLevel(client,raceID,boostID);
        SetSpeedBoost(client, boost_level, true, g_SpeedLevels);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        new adrenal_glands_level = GetUpgradeLevel(attacker_index,raceID,meleeID);
        if (adrenal_glands_level > 0)
        {
            if (MeleeAttack(raceID, meleeID, adrenal_glands_level, event, damage+absorbed,
                            victim_index, attacker_index, g_AdrenalGlandsPercent,
                            g_AdrenalGlandsSound, "sc_adrenal_glands"))
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
    if (victim_race == raceID && !IsChangingClass(victim_index))
    {
        if (GetRestriction(victim_index,Restriction_NoUpgrades) ||
            GetRestriction(victim_index,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(victim_index,deniedWav);
            DisplayMessage(victim_index, Display_Message,
                           "%t", "PreventedFromExploding");
        }
        else
        {
            PrepareAndEmitSoundToAll(deathWav,victim_index);
            Explode(victim_index,true);
        }
    }
}

Roll(client, level)
{
    if (IsValidClientAlive(client))
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "PreventedFromRolling");
        }
        else if (CanInvokeUpgrade(client, raceID, rollID))
        {
            new Float:speed=1.10 + (float(level)*0.15);

            /* If the Player also has the Boots of Speed,
             * Increase the speed further
             */
            if (g_bootsItem < 0)
                g_bootsItem = FindShopItem("boots");

            if (g_bootsItem != -1 && GetOwnsItem(client,g_bootsItem))
            {
                speed *= 1.1;
            }

            SetSpeed(client,speed);

            new Float:start[3];
            GetClientAbsOrigin(client, start);

            static const color[4] = { 255, 100, 100, 255 };
            TE_SetupBeamRingPoint(start, 20.0, 60.0, SmokeSprite(), HaloSprite(),
                                  0, 1, 1.0, 4.0, 0.0 ,color, 10, 0);
            TE_SendEffectToAll();

            CreateTimer(10.0, EndRoll, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:EndRoll(Handle:timer,any:userid)
{
    new index = GetClientOfUserId(userid);
    if (IsValidClientAlive(index))
    {
        if (GetRace(index) == raceID)
        {
            new boost_level = GetUpgradeLevel(index,raceID,boostID);
            SetSpeedBoost(index, boost_level, true, g_SpeedLevels);
        }
        else
            SetSpeed(index,-1.0,true);
    }
}

Explode(client,bool:ondeath)
{
    new ExplosionType:type = ondeath ? OnDeathExplosion : UltimateExplosion;
    new explode_level      = GetUpgradeLevel(client,raceID,explodeID);
    new volatile_level     = GetUpgradeLevel(client,raceID,volatileID);
    if (volatile_level >= 1)
    {
        type |= FlamingExplosion;
        if (volatile_level >= 2)
        {
            type |= IgnoreStructureImmunity;
            if (volatile_level >= 3)
            {
                type |= IgnoreExplosionImmunity;
                if (volatile_level >= 4)
                    type |= IgnoreHealthImmunity;
            }
        }
    }

    if (IsBurrowed(client))
        ResetBurrow(client, true);

    ExplodePlayer(client, client, GetClientTeam(client),
                  g_ExplodeRadius[explode_level],
                  g_ExplodePlayerDamage[explode_level],
                  g_ExplodeBuildingDamage[explode_level],
                  ParticleExplosion | type,
                  explode_level+volatile_level+5);
}
