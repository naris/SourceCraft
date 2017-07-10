/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranFirebat.sp
 * Description: The Terran Firebat unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

// Pump up the memory!
#pragma dynamic 65536

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <raytrace>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <sm_flamethrower>
#include <dod_ignite>

#include "sc/RateOfFire"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/PlagueInfect"
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
#include "effect/Shake"

new const String:spawnWav[]          = "sc/tfbrdy00.wav";        // Spawn sound
new const String:flameWav[][]        = { "sc/tfbfir00.wav",    // flamethrower sounds
                                         "sc/tfbfir01.wav" };
new const String:deathWav[][]        = { "sc/tfbdth00.wav",    // Death sounds
                                         "sc/tfbdth01.wav",
                                         "sc/tfbdth02.wav" };

new raceID, weaponsID, armorID, plasmaID, flamethrowerID, bunkerID;

new const String:g_ArmorName[]       = "Armor";
new Float:g_InitialArmor[]           = { 0.0, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ArmorPercent[][2]        = { {0.00, 0.00},
                                         {0.00, 0.10},
                                         {0.00, 0.20},
                                         {0.10, 0.40},
                                         {0.20, 0.50} };

new Float:g_SpeedLevels[]            = { -1.0, 1.10, 1.15, 1.20, 1.25 };

new Float:g_BunkerPercent[]          = { 0.00, 0.10, 0.25, 0.50, 0.75 };

new Float:g_InfantryWeaponsPercent[] = { 0.00, 0.10, 0.25, 0.40, 0.50 };

new Float:g_ExplodeRadius[]          = { 0.0, 300.0, 450.0, 500.0, 650.0 };

new Float:m_FireTime[MAXPLAYERS+1][MAXPLAYERS+1];

#include "sc/Stimpacks"

public Plugin:myinfo = 
{
    name = "SourceCraft Unit - Terran Firebat",
    author = "-=|JFH|=-Naris",
    description = "The Terran Firebat unit for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.bunker.phrases.txt");
    LoadTranslations("sc.firebat.phrases.txt");
    LoadTranslations("sc.stimpacks.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID    = CreateRace("firebat", -1, 0, 24, .faction=Terran,
                           .type=Biological, .parent="marine");

    weaponsID = AddUpgrade(raceID, "weapons", .energy=2.0);

    armorID   = AddUpgrade(raceID, "armor");

    // Ultimate 3
    if (IsROFAvailable())
    {
        stimpacksID = AddUpgrade(raceID, "ultimate_stimpacks", 3, 4, .energy=30.0,
                                 .recurring_energy=3.0, .cooldown=10.0);
    }
    else
    {
        stimpacksID = AddUpgrade(raceID, "stimpacks", 0, 12);
    }

    plasmaID = AddUpgrade(raceID, "plasma", false, 0, .energy=1.0);

    // Ultimate 1
    flamethrowerID = AddUpgrade(raceID, "flamethrower", 1, 1);

    if (!IsFlamethrowerAvailable())
    {
        SetUpgradeDisabled(raceID, flamethrowerID, true);
        LogError("sm_flamethrower is not available");
    }

    // Ultimate 2
    bunkerID = AddUpgrade(raceID, "bunker", 2, .energy=30.0, .cooldown=5.0);

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

    GetConfigFloatArray("damage_percent", g_InfantryWeaponsPercent, sizeof(g_InfantryWeaponsPercent),
                        g_InfantryWeaponsPercent, raceID, weaponsID);

    GetConfigFloatArray("speed",  g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, stimpacksID);

    GetConfigFloatArray("explosion_radius", g_ExplodeRadius, sizeof(g_ExplodeRadius),
                        g_ExplodeRadius, raceID, flamethrowerID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "sm_flame"))
        IsFlamethrowerAvailable(true);
    else if (StrEqual(name, "RateOfFire"))
        IsROFAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "sm_flame"))
        m_FlamethrowerAvailable = false;
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

    for (new i = 0; i < sizeof(flameWav); i++)
        SetupSound(flameWav[i]);

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
        SetImmunity(client,Immunity_Burning,false);

        SetSpeed(client, -1.0, true);

        if (m_FlamethrowerAvailable)
            TakeFlamethrower(client);

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
        SetImmunity(client,Immunity_Burning,(armor_level > 0));
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new stimpacks_level = GetUpgradeLevel(client,raceID,stimpacksID);
        SetSpeedBoost(client, stimpacks_level, true, g_SpeedLevels);

        new flamethrower_level=GetUpgradeLevel(client,raceID,flamethrowerID);
        if (flamethrower_level > 0)
        {
            GiveFlamethrower(client, flamethrower_level*3,
                             float(flamethrower_level+1)*200.0);
        }

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
            SetImmunity(client,Immunity_Burning,(new_level > 0));
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==stimpacksID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==flamethrowerID)
        {
            GiveFlamethrower(client, new_level*3,
                             float(new_level+1)*200.0);
        }
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
            case 4,3: // Ultimate Stimpack
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
                    else if (m_FlamethrowerAvailable)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);

                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, flamethrowerID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                        }
                        else                            
                        {
                            new num = GetRandomInt(0,sizeof(flameWav)-1);
                            SetFlamethrowerSound(flameWav[num]);
                            UseFlamethrower(client);
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
                else if (m_FlamethrowerAvailable)
                {
                    if (GetRestriction(client, Restriction_NoUltimates) ||
                        GetRestriction(client, Restriction_Stunned))
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);

                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, flamethrowerID, upgradeName, sizeof(upgradeName), client);
                        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                    }
                    else                            
                    {
                        new num = GetRandomInt(0,sizeof(flameWav)-1);
                        SetFlamethrowerSound(flameWav[num]);
                        UseFlamethrower(client);
                    }
                }
            }
            default: // Flamethrower or Bunker
            {
                if (m_FlamethrowerAvailable)
                {
                    if (GetRestriction(client, Restriction_NoUltimates) ||
                        GetRestriction(client, Restriction_Stunned))
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);

                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, flamethrowerID, upgradeName, sizeof(upgradeName), client);
                        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                    }
                    else                            
                    {
                        new num = GetRandomInt(0,sizeof(flameWav)-1);
                        SetFlamethrowerSound(flameWav[num]);
                        UseFlamethrower(client);
                    }
                }
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
                        new stimpacks_level=GetUpgradeLevel(client,race,stimpacksID);
                        if (stimpacks_level > 0)
                            Stimpacks(client, stimpacks_level,race,stimpacksID);
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
        SetImmunity(client,Immunity_Burning,(armor_level > 0));
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new stimpacks_level = GetUpgradeLevel(client,raceID,stimpacksID);
        SetSpeedBoost(client, stimpacks_level, true, g_SpeedLevels);

        new flamethrower_level=GetUpgradeLevel(client,raceID,flamethrowerID);
        if (flamethrower_level > 0)
        {
            GiveFlamethrower(client, flamethrower_level*3,
                             float(flamethrower_level+1)*200.0);
        }
    }
}

public Action:OnEntityHurtEvent(Handle:event, victim_index, attacker_index, attacker_race, damage)
{
    if (attacker_race == raceID)
    {
        InfantryWeapons(event, damage, victim_index, attacker_index);
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnEntityAssistEvent(Handle:event, victim_index, assister_index, assister_race, damage)
{
    if (assister_race == raceID)
    {
        InfantryWeapons(event, damage, victim_index, assister_index);
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}


public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (ViralPlasma(victim_index, attacker_index))
            returnCode = Plugin_Handled;

        if (InfantryWeapons(event, damage + absorbed, victim_index, attacker_index))
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
        if (ViralPlasma(victim_index, assister_index))
            returnCode = Plugin_Handled;

        if (InfantryWeapons(event, damage + absorbed, victim_index, assister_index))
            returnCode = Plugin_Handled;
    }

    return returnCode;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_race == raceID && !IsChangingClass(victim_index))
    {
        if (m_StimpacksActive[victim_index])
            EndStimpack(INVALID_HANDLE, GetClientUserId(victim_index));
        else if (m_ROFAvailable)
            SetROF(victim_index, 0.0, 0.0);

        new num = GetRandomInt(0,sizeof(deathWav)-1);
        PrepareAndEmitSoundToAll(deathWav[num],victim_index);

        new level = GetUpgradeLevel(victim_index,raceID,flamethrowerID);
        if (level > 0 &&
            !GetRestriction(victim_index, Restriction_NoUpgrades) &&
            !GetRestriction(victim_index, Restriction_Stunned))
        {
            new fuel = (m_FlamethrowerAvailable) ? GetFlamethrowerFuel(victim_index) : level*3;
            new explode_damage  = (fuel * 125) * GetRandomInt(level,10);
            ExplodePlayer(victim_index, victim_index, GetClientTeam(victim_index),
                          g_ExplodeRadius[level], explode_damage, explode_damage,
                          FlamingExplosion | OnDeathExplosion, level+5);
        }
    }
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
    if (client > 0 && GetRace(client) == raceID)
    {
        if (weapon > 0 && IsValidEntity(weapon) &&
            StrEqual(weaponname, "tf_weapon_compound_bow"))
        {
            SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1);
        }
    }
    return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "tf_projectile_arrow"))
		SDKHook(entity, SDKHook_Spawn, FlameArrow);
}

public FlameArrow(entity)
{
    new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if (owner > 0 && GetRace(owner) == raceID)
    {
        SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
    }
}

public Action:OnPlayerFlamed(attacker,victim)
{
    if (GetRace(attacker) != raceID)
        return Plugin_Continue;
    else
    {
        if (GetRestriction(attacker,Restriction_NoUltimates) ||
            GetRestriction(attacker,Restriction_Stunned) ||
            GetImmunity(victim,Immunity_Burning) ||
            GetImmunity(victim,Immunity_Ultimates))
        {
            return Plugin_Stop;
        }
        else
            return Plugin_Continue;
    }
}

bool:InfantryWeapons(Handle:event, damage, victim_index, index)
{
    new weapons_level = GetUpgradeLevel(index, raceID, weaponsID);
    if (weapons_level > 0)
    {
        if (!GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_HealthTaking) &&
            !GetImmunity(victim_index,Immunity_Upgrades) &&
            !IsInvulnerable(victim_index))
        {
            if (GetRandomInt(1,100) <= 25)
            {
                decl String:weapon[64];
                new bool:is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
                if (!IsMelee(weapon, is_equipment,index,victim_index))
                {
                    new health_take = RoundFloat(float(damage)*g_InfantryWeaponsPercent[weapons_level]);
                    if (health_take > 0 && CanInvokeUpgrade(index, raceID, weaponsID, .notify=false))
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
                                   "sc_infantry_weapons", .type=DMG_BULLET,
                                   .in_hurt_event=true);
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

bool:ViralPlasma(victim_index, index)
{
    new plasma_level = GetUpgradeLevel(index, raceID, plasmaID);
    if (plasma_level > 0 && GetRandomInt(1,100) <= plasma_level*20)
    {
        if (!GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_Burning) &&
            !IsInvulnerable(victim_index))
        {
            new Float:lastTime = m_FireTime[index][victim_index];
            if ((lastTime == 0.0 || GetGameTime() - lastTime > 10.0) &&
                CanInvokeUpgrade(index, raceID, plasmaID, .notify=false))
            {
                m_FireTime[index][victim_index] = GetGameTime();

                if (GameType == tf2)
                    TF2_IgnitePlayer(victim_index, index);
                else if (GameType == dod)
                    DOD_IgniteEntity(victim_index, 10.0);
                else
                    IgniteEntity(victim_index, 10.0);

                decl String:upgradeName[64];
                GetUpgradeName(raceID, plasmaID, upgradeName, sizeof(upgradeName), victim_index);
                DisplayMessage(victim_index, Display_Enemy_Message, "%t", "SetOnFire", index, upgradeName);
                return true;
            }
        }
    }
    return false;
}

