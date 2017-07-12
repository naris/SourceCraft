/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranMarauder.sp
 * Description: The Terran Marauder unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/sm_tnt>
#include "sc/RateOfFire"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/bunker"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:spawnWav[]     = "sc/tmardy00.wav";  // Spawn sound
new const String:deathWav[][]   = { "sc/tmadth00.wav",  // Death sounds
                                    "sc/tmadth01.wav" };

new raceID, u238ID, armorID, graviticID, chargeID, bunkerID;

new Float:g_SpeedLevels[]       = { -1.0, 1.10, 1.15, 1.20, 1.25 };

new Float:g_BunkerPercent[]     = { 0.00, 0.10, 0.25, 0.50, 0.75 };

new Float:g_U238Percent[]       = { 0.0, 0.30, 0.40, 0.50, 0.70 };

new const String:g_ArmorName[]  = "Armor";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.20},
                                    {0.10, 0.40},
                                    {0.20, 0.50} };

#include "sc/Stimpacks"

public Plugin:myinfo = 
{
    name = "SourceCraft Unit - Terran Marauder",
    author = "-=|JFH|=-Naris",
    description = "The Terran Marauder unit for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.marauder.phrases.txt");
    LoadTranslations("sc.d8charge.phrases.txt");
    LoadTranslations("sc.stimpacks.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("marauder", -1, 0, 24, .faction=Terran,
                             .type=Biological, .parent="marine");

    u238ID      = AddUpgrade(raceID, "u238", .energy=2.0, .cost_crystals=20);
    armorID     = AddUpgrade(raceID, "armor", .cost_crystals=5);

    // Ultimate 1
    if (IsROFAvailable())
    {
        stimpacksID = AddUpgrade(raceID, "ultimate_stimpacks", 1, 4, .energy=30.0,
                                 .recurring_energy=3.0, .cooldown=10.0,
                                 .cost_crystals=25);
    }
    else
    {
        stimpacksID = AddUpgrade(raceID, "stimpacks", 0, 12, .cost_crystals=0);
    }

    graviticID  = AddUpgrade(raceID, "gravitic", 0, 6, .energy=2.0, .cost_crystals=20);

    // Ultimate 3 & 4
    chargeID = AddUpgrade(raceID, "d8charge", 3, 8, .cost_crystals=30);

    if (!IsTNTAvailable())
    {
        SetUpgradeDisabled(raceID, chargeID, true);
        LogError("sm_tnt is not available");
    }

    // Ultimate 2
    bunkerID    = AddBunkerUpgrade(raceID, 2);

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
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "sm_tnt"))
        IsTNTAvailable(true);
    else if (StrEqual(name, "RateOfFire"))
        IsROFAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "sm_tnt"))
        m_TNTAvailable = false;
    else if (StrEqual(name, "RateOfFire"))
        m_ROFAvailable = false;
}

public OnMapStart()
{
    SetupHaloSprite();
    SetupLightning();
    SetupSpeed();

    SetupStimpacks();
    //SetupBunker();
    //SetupDeniedSound();

    SetupSound(spawnWav);

    for (new i = 0; i < sizeof(deathWav); i++)
        SetupSound(deathWav[i]);
}

public OnPlayerAuthed(client)
{
    m_StimpacksActive[client] = false;
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);
        SetSpeed(client, -1.0, true);
        SetImmunity(client,Immunity_Explosion, false);

        if (m_StimpacksActive[client])
            EndStimpack(INVALID_HANDLE, GetClientUserId(client));
        else if (m_ROFAvailable)
            SetROF(client, 0.0, 0.0);
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_StimpacksActive[client] = false;

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetImmunity(client,Immunity_Explosion,(armor_level > 0));
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new stimpacks_level = GetUpgradeLevel(client,raceID,stimpacksID);
        SetSpeedBoost(client, stimpacks_level, true, g_SpeedLevels);

        new charge_level=GetUpgradeLevel(client,raceID,chargeID);
        SetupTNT(client, charge_level);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav,client);
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
            SetImmunity(client,Immunity_Explosion,(new_level > 0));
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==stimpacksID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==chargeID)
            SetupTNT(client, new_level);
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
            new level = GetUpgradeLevel(client,raceID,stimpacksID);
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
            case 4: // Detonate or Defuse D8 Charge
            {
                new charge_level = GetUpgradeLevel(client,race,chargeID);
                if (charge_level > 0)
                {
                    if (m_TNTAvailable)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate,
                                           "%t", "PreventedFromDetonatingD8");
                        }
                        else                            
                        {
                            TNT(client);
                        }
                    }
                }
            }
            case 3: // Plant D8 Charge
            {
                new charge_level = GetUpgradeLevel(client,race,chargeID);
                if (charge_level > 0)
                {
                    if (m_TNTAvailable)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate,
                                           "%t", "PreventedFromPlantingD8");
                        }
                        else                            
                        {
                            PlantTNT(client);
                        }
                    }
                }
            }
            case 2: // Enter Bunker
            {
                new bunker_level = GetUpgradeLevel(client,race,bunkerID);
                if (bunker_level > 0)
                {
                    new armor = RoundToNearest(float(GetPlayerMaxHealth(client))
                                               * g_BunkerPercent[bunker_level]);

                    EnterBunker(client, armor, raceID, bunkerID);
                }
                else if (m_TNTAvailable)
                {
                    if (GetRestriction(client, Restriction_NoUltimates) ||
                        GetRestriction(client, Restriction_Stunned))
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);
                        DisplayMessage(client, Display_Ultimate,
                                       "%t", "PreventedFromPlantingD8");
                    }
                    else                            
                    {
                        PlantTNT(client);
                    }
                }
            }
            default: // Ultimate Stimpack
            {
                new stimpacks_level=GetUpgradeLevel(client,race,stimpacksID);
                if (stimpacks_level > 0)
                    Stimpacks(client, stimpacks_level,race,stimpacksID);
                else
                {
                    new bunker_level = GetUpgradeLevel(client,race,bunkerID);
                    if (bunker_level > 0)
                    {
                        new armor = RoundToNearest(float(GetPlayerMaxHealth(client))
                                                   * g_BunkerPercent[bunker_level]);

                        EnterBunker(client, armor, raceID, bunkerID);
                    }
                    else
                    {
                        new charge_level = GetUpgradeLevel(client,race,chargeID);
                        if (charge_level > 0)
                        {
                            if (m_TNTAvailable)
                            {
                                if (GetRestriction(client, Restriction_NoUltimates) ||
                                    GetRestriction(client, Restriction_Stunned))
                                {
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                    DisplayMessage(client, Display_Ultimate,
                                                   "%t", "PreventedFromPlantingD8");
                                }
                                else                            
                                {
                                    PlantTNT(client);
                                }
                            }
                        }
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
        m_StimpacksActive[client] = false;

        PrepareAndEmitSoundToAll(spawnWav,client);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetImmunity(client,Immunity_Explosion,(armor_level > 0));
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new stimpacks_level = GetUpgradeLevel(client,raceID,stimpacksID);
        SetSpeedBoost(client, stimpacks_level, true, g_SpeedLevels);

        new charge_level=GetUpgradeLevel(client,raceID,chargeID);
        if (charge_level > 0)
            SetupTNT(client, charge_level);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (U238Shells(event, damage + absorbed, victim_index, attacker_index))
            returnCode = Plugin_Handled;

        if (GraviticCharge(victim_index, attacker_index))
            returnCode = Plugin_Handled;

    }

    return returnCode;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    new Action:returnCode = Plugin_Continue;

    if (assister_race == raceID)
    {
        if (U238Shells(event, damage + absorbed, victim_index, assister_index))
            returnCode = Plugin_Handled;

        if (GraviticCharge(victim_index, assister_index))
            returnCode = Plugin_Handled;
    }

    return returnCode;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_race == raceID)
    {
        if (m_StimpacksActive[victim_index])
            EndStimpack(INVALID_HANDLE, GetClientUserId(victim_index));
        else if (m_ROFAvailable)
            SetROF(victim_index, 0.0, 0.0);

        new num = GetRandomInt(0,sizeof(deathWav)-1);
        PrepareAndEmitSoundToAll(deathWav[num],victim_index);
    }
}

bool:U238Shells(Handle:event, damage, victim_index, index)
{
    new u238_level = GetUpgradeLevel(index, raceID, u238ID);
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

                        HurtPlayer(victim_index, health_take, index,
                                   "sc_u238_shells", .type=DMG_BULLET,
                                   .in_hurt_event=true);
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

bool:GraviticCharge(victim_index, index)
{
    new gravitic_level = GetUpgradeLevel(index,raceID,graviticID);
    if (gravitic_level > 0)
    {
        if (IsValidClient(victim_index) &&
            !GetRestriction(index,Restriction_NoUpgrades) &&
            !GetRestriction(index,Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_MotionTaking) &&
            !GetImmunity(victim_index,Immunity_Restore))
        {
            SetOverrideSpeed(victim_index, 0.5);
            SetVisibility(victim_index, BasicVisibility,
                          .visibility=192, 
                          .mode=RENDER_GLOW,
                          .r=((GetClientTeam(victim_index) == _:TFTeam_Red) ? 255 : 0),
                          .g=128, .b=255, .apply=true);

            CreateTimer(1.5*float(gravitic_level),RestoreSpeed, GetClientUserId(victim_index),TIMER_FLAG_NO_MAPCHANGE);
            DisplayMessage(victim_index,Display_Enemy_Message, "%t", "SlowedbyGraviticCharge", index);
        }
    }
    return false;
}

public Action:RestoreSpeed(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        SetOverrideSpeed(client,-1.0);
        SetVisibility(client, NormalVisibility);
    }
    return Plugin_Stop;
}

SetupTNT(client, level)
{
    if (m_TNTAvailable)
    {
        if (level > 0)
        {
            SetTNT(client, level, (level >= 2) ? 3 : 2, (level >= 4),
                   12.0 - (float(level) * 3.0), 12.0 - (float(level) * 2.0));
        }
        else
            SetTNT(client, 0);
    }
}

public Action:OnTNTBombed(tnt,owner,victim)
{
    if (GetRace(owner) != raceID)
        return Plugin_Continue;
    else
    {
        if (GetImmunity(victim,Immunity_Explosion) ||
            GetImmunity(victim,Immunity_Ultimates))
        {
            return Plugin_Stop;
        }
        else
        {
            DisplayKill(owner, victim, 0, "sc_d8charge");
            return Plugin_Continue;
        }
    }
}

