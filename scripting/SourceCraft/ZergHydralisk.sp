/**
 * vim: set ai et ts=4 sw=4 :
 * File: ZergHydralisk.sp
 * Description: The Zerg Hydralisk race for SourceCraft.
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
#include "sc/MissileAttack"
#include "sc/PlagueInfect"
#include "sc/clienttimer"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/burrow"
#include "sc/sounds"
#include "sc/armor"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:poisonHitWav[]          = "sc/spifir00.wav";
new const String:poisonReadyWav[]        = "sc/zhyrdy00.wav";
new const String:poisonExpireWav[]       = "sc/zhywht01.wav";

new const String:g_MissileAttackSound[]  = "sc/spooghit.wav";
new g_MissileAttackChance[]              = { 0, 5, 15, 25, 35 };
new Float:g_MissileAttackPercent[]       = { 0.0, 0.15, 0.30, 0.40, 0.50 };

new const String:g_ArmorName[]           = "Carapace";
new Float:g_InitialArmor[]               = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]            = { {0.00, 0.00},
                                             {0.00, 0.05},
                                             {0.00, 0.10},
                                             {0.05, 0.15},
                                             {0.10, 0.20} };

new Float:g_SpeedLevels[]                = { -1.0, 1.10, 1.15, 1.20, 1.25 };
//new Float:g_SpeedLevels[]              = { -1.0, 1.20, 1.28, 1.36, 1.50 };

new g_lurkerRace = -1;

new raceID, carapaceID, regenerationID, augmentsID;
new burrowID, missileID, spinesID, poisonID, lurkerID;

new bool:m_PoisonActive[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Zerg Hydralisk",
    author = "-=|JFH|=-Naris",
    description = "The Zerg Hydralisk race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.hydralisk.phrases.txt");

    GetGameType();

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("hydralisk", 48, 0, 26, .faction=Zerg,
                                 .type=Biological);

    carapaceID      = AddUpgrade(raceID, "armor", .cost_crystals=5);
    regenerationID  = AddUpgrade(raceID, "regeneration", .cost_crystals=10);
    augmentsID      = AddUpgrade(raceID, "augments", .cost_crystals=0);

    missileID       = AddUpgrade(raceID, "missile_attack", .energy=2.0,
                                 .cost_crystals=20);

    spinesID        = AddUpgrade(raceID, "grooved_spines", .energy=2.0,
                                 .cost_crystals=20);

    // Ultimate 1
    poisonID        = AddUpgrade(raceID, "poison_spines", 1, .energy=20.0,
                                 .cooldown=2.0, .cost_crystals=30);

    // Ultimate 2
    burrowID        = AddBurrowUpgrade(raceID, 2, 6, 1);

    // Ultimate 3
    lurkerID        = AddUpgrade(raceID, "lurker", 3, 12, 1, .energy=120.0,
                                 .accumulated=true, .cooldown=60.0,
                                 .cost_crystals=50);

    // Get Configuration Data
    GetConfigFloatArray("armor_amount", g_InitialArmor, sizeof(g_InitialArmor),
                        g_InitialArmor, raceID, carapaceID);

    for (new level=0; level < sizeof(g_ArmorPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "armor_percent_level_%d", level);
        GetConfigFloatArray(key, g_ArmorPercent[level], sizeof(g_ArmorPercent[]),
                            g_ArmorPercent[level], raceID, carapaceID);
    }

    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, augmentsID);

    GetConfigArray("chance", g_MissileAttackChance, sizeof(g_MissileAttackChance),
                   g_MissileAttackChance, raceID, missileID);

    GetConfigFloatArray("damage_percent", g_MissileAttackPercent, sizeof(g_MissileAttackPercent),
                        g_MissileAttackPercent, raceID, missileID);
}

public OnMapStart()
{
    SetupSpeed();
    SetupRedGlow();
    SetupBlueGlow();
    SetupSmokeSprite();

    SetupDeniedSound();

    SetupSound(poisonHitWav);
    SetupSound(poisonReadyWav);
    SetupSound(poisonExpireWav);
    SetupMissileAttack(g_MissileAttackSound);
}

public OnPlayerAuthed(client)
{
    m_PoisonActive[client] = false;
}

public OnClientDisconnect(client)
{
    m_PoisonActive[client] = false;
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        SetSpeed(client,-1.0);
        SetHealthRegen(client, 0.0);
        ResetArmor(client);

        if (m_PoisonActive[client])
            EndPoison(INVALID_HANDLE, GetClientUserId(client));

        return Plugin_Handled;
    }
    else
    {
        if (g_lurkerRace < 0)
            g_lurkerRace = FindRace("lurker");

        if (oldrace == g_lurkerRace &&
            GetCooldownExpireTime(client, raceID, lurkerID) <= 0.0)
        {
            CreateCooldown(client, raceID, lurkerID,
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
        m_PoisonActive[client] = false;

        new augments_level = GetUpgradeLevel(client,raceID,augmentsID);
        SetSpeedBoost(client, augments_level, true, g_SpeedLevels);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==augmentsID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==regenerationID)
            SetHealthRegen(client, float(new_level));
        else if (upgrade==carapaceID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==burrowID)
        {
            if (new_level <= 0)
                ResetBurrow(client, true);
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
            new augments_level = GetUpgradeLevel(client,race,augmentsID);
            if (augments_level > 0)
                SetSpeedBoost(client, augments_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4,3:
            {
                new lurker_level=GetUpgradeLevel(client,race,lurkerID);
                if (lurker_level > 0)
                {
                    if (!pressed)
                        LurkerAspect(client);
                }
                else if (pressed)
                {
                    new burrow_level=GetUpgradeLevel(client,race,burrowID);
                    if (burrow_level > 0)
                        Burrow(client, burrow_level);
                    else
                    {
                        new poison_level=GetUpgradeLevel(client,race,poisonID);
                        if (poison_level > 0)
                            Poison(client, poison_level);
                    }
                }
            }
            case 2:
            {
                new burrow_level=GetUpgradeLevel(client,race,burrowID);
                if (burrow_level > 0)
                {
                    if (pressed)
                        Burrow(client, burrow_level);
                }
                else
                {
                    new poison_level=GetUpgradeLevel(client,race,poisonID);
                    if (poison_level > 0)
                    {
                        if (pressed)
                            Poison(client, poison_level);
                    }
                    else if (!pressed)
                    {
                        new lurker_level=GetUpgradeLevel(client,race,lurkerID);
                        if (lurker_level > 0)
                            LurkerAspect(client);
                    }
                }
            }
            default:
            {
                new poison_level=GetUpgradeLevel(client,race,poisonID);
                if (poison_level > 0)
                {
                    if (pressed)
                        Poison(client, poison_level);
                }
                else
                {
                    new burrow_level=GetUpgradeLevel(client,race,burrowID);
                    if (burrow_level > 0)
                    {
                        if (pressed)
                            Burrow(client, burrow_level);
                    }
                    else if (!pressed)
                    {
                        new lurker_level=GetUpgradeLevel(client,race,lurkerID);
                        if (lurker_level > 0)
                            LurkerAspect(client);
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
        m_PoisonActive[client] = false;

        new augments_level = GetUpgradeLevel(client,raceID,augmentsID);
        SetSpeedBoost(client, augments_level, true, g_SpeedLevels);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_race == raceID)
    {
        if (m_PoisonActive[victim_index])
            EndPoison(INVALID_HANDLE, GetClientUserId(victim_index));
    }
    else
    {
        if (g_lurkerRace < 0)
            g_lurkerRace = FindRace("lurker");

        if (victim_race == g_lurkerRace &&
            GetCooldownExpireTime(victim_index, raceID, lurkerID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, lurkerID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new bool:handled=false;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        new bool:used=false;
        if (m_PoisonActive[attacker_index])
        {
            new poison_level=GetUpgradeLevel(attacker_index,raceID,poisonID);
            if (poison_level > 0)
            {
                if (!GetRestriction(attacker_index, Restriction_NoUltimates) &&
                    !GetRestriction(attacker_index, Restriction_Stunned) &&
                    !GetImmunity(victim_index,Immunity_Ultimates) &&
                    !GetImmunity(victim_index,Immunity_HealthTaking) &&
                    !GetImmunity(victim_index,Immunity_Restore) &&
                    !IsInvulnerable(victim_index))
                {
                    PlagueInfect(attacker_index, victim_index,
                                 poison_level, poison_level,
                                 UltimatePlague|FatalPlague|PoisonousPlague,
                                 "sc_poison_spines");

                    if (PrepareSound(poisonHitWav))
                    {
                        EmitSoundToClient(attacker_index,poisonHitWav);
                        EmitSoundToAll(poisonHitWav,victim_index);
                    }
                    handled = used = true;
                }
            }
        }

        if (!used)
        {
            damage += absorbed;

            new spines_level=GetUpgradeLevel(attacker_index,raceID,spinesID);
            new missile_level=GetUpgradeLevel(attacker_index,raceID,missileID);
            if (missile_level > 0)
            {
                handled |= (used = MissileAttack(raceID, missileID, missile_level, event,
                                                 damage, victim_index, attacker_index,
                                                 victim_index, (spines_level > 0),
                                                 sizeof(g_MissileAttackChance),
                                                 g_MissileAttackPercent,
                                                 g_MissileAttackChance,
                                                 g_MissileAttackSound,
                                                 "sc_missile_attack"));
            }

            if (spines_level && !used)
            {
                handled |= GroovedSpines(damage, victim_index,
                                         attacker_index, spines_level);
            }
        }
    }

    return handled ? Plugin_Handled : Plugin_Continue;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    new bool:handled=false;

    if (assister_race == raceID)
    {
        new bool:used=false;
        if (m_PoisonActive[assister_index])
        {
            new poison_level=GetUpgradeLevel(assister_index,raceID,poisonID);
            if (poison_level > 0)
            {
                if (!GetRestriction(assister_index, Restriction_NoUltimates) &&
                    !GetRestriction(assister_index, Restriction_Stunned) &&
                    !GetImmunity(victim_index,Immunity_Ultimates) &&
                    !GetImmunity(victim_index,Immunity_HealthTaking) &&
                    !GetImmunity(victim_index,Immunity_Restore) &&
                    !IsInvulnerable(victim_index))
                {
                    PlagueInfect(assister_index, victim_index,
                                 poison_level, poison_level,
                                 UltimatePlague|FatalPlague|PoisonousPlague,
                                 "sc_poison_spines");

                    if (PrepareSound(poisonHitWav))
                    {
                        EmitSoundToClient(assister_index,poisonHitWav);
                        EmitSoundToAll(poisonHitWav,victim_index);
                    }
                    handled = used = true;
                }
            }
        }

        if (!used)
        {
            damage += absorbed;

            new spines_level=GetUpgradeLevel(assister_index,raceID,spinesID);
            new missile_level=GetUpgradeLevel(assister_index,raceID,missileID);
            if (missile_level > 0)
            {
                handled |= (used = MissileAttack(raceID, missileID, missile_level, event,
                                                 damage, victim_index, assister_index,
                                                 victim_index, (spines_level > 0),
                                                 sizeof(g_MissileAttackChance),
                                                 g_MissileAttackPercent,
                                                 g_MissileAttackChance,
                                                 g_MissileAttackSound,
                                                 "sc_missile_attack"));
            }

            if (spines_level && !used)
            {
                handled |= GroovedSpines(damage, victim_index,
                                         assister_index, spines_level);
            }
        }
    }

    return handled ? Plugin_Handled : Plugin_Continue;
}

bool:GroovedSpines(damage, victim_index, index, level)
{
    if (!GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned) &&
        !GetImmunity(victim_index,Immunity_HealthTaking) &&
        !GetImmunity(victim_index,Immunity_Upgrades) &&
        !IsInvulnerable(victim_index))
    {
        new Float:percent;
        new Float:distance = TargetRange(index, victim_index);
        if (distance > 1000.0)
        {
            if (GameType == tf2)
            {
                switch (TF2_GetPlayerClass(index))
                {
                    case TFClass_Scout:     percent = 0.08 * float(level);
                    case TFClass_Sniper:    percent = 0.02 * float(level);
                    case TFClass_Soldier:   percent = 0.08 * float(level);
                    case TFClass_DemoMan:   percent = 0.08 * float(level);
                    case TFClass_Medic:     percent = 0.08 * float(level);
                    case TFClass_Heavy:     percent = 0.10 * float(level);
                    case TFClass_Pyro:      percent = 0.10 * float(level);
                    case TFClass_Spy:       percent = 0.08 * float(level);
                    case TFClass_Engineer:  percent = 0.08 * float(level);
                }
            }
            else
                percent = 0.10 * float(level);
        }
        else if (distance > 500.0)
        {
            if (GameType == tf2)
            {
                switch (TF2_GetPlayerClass(index))
                {
                    case TFClass_Scout:     percent = 0.04 * float(level);
                    case TFClass_Sniper:    percent = 0.01 * float(level);
                    case TFClass_Soldier:   percent = 0.04 * float(level);
                    case TFClass_DemoMan:   percent = 0.04 * float(level);
                    case TFClass_Medic:     percent = 0.04 * float(level);
                    case TFClass_Heavy:     percent = 0.05 * float(level);
                    case TFClass_Pyro:      percent = 0.05 * float(level);
                    case TFClass_Spy:       percent = 0.04 * float(level);
                    case TFClass_Engineer:  percent = 0.04 * float(level);
                }
            }
            else
                percent = 0.05 * float(level);
        }
        else
            percent = 0.0;

        if (percent > 0.0)
        {
            new health_take=RoundFloat(float(damage)*percent);
            if (health_take > 0 && CanInvokeUpgrade(index, raceID, spinesID, .notify=false))
            {
                FlashScreen(victim_index,RGBA_COLOR_RED);
                HurtPlayer(victim_index, health_take, index,
                           "sc_grooved_spines", .type=DMG_SLASH,
                           .in_hurt_event=true);

                return true;
            }
        }
    }
    return false;
}

LurkerAspect(client)
{
    if (g_lurkerRace < 0)
        g_lurkerRace = FindRace("lurker");

    if (g_lurkerRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, lurkerID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Zerg Lurker race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromLurker");
    }
    else if (CanInvokeUpgrade(client, raceID, lurkerID))
    {
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);
            clientLoc[2] += 40.0; // Adjust position to the middle

            TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
            TE_SendEffectToAll();

            TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                               5.0, 40.0, 255);
            TE_SendEffectToAll();

            ChangeRace(client, g_lurkerRace, true, false, true);
    }
}

Poison(client, level)
{
    if (level > 0)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceID, poisonID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        }
        else if (CanInvokeUpgrade(client, raceID, poisonID))
        {
            m_PoisonActive[client] = true;
            CreateTimer(5.0 * float(level), EndPoison, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);

            PrintHintText(client, "%t", "PoisonActive");
            HudMessage(client, "%t", "PoisonHud");
            
            PrepareAndEmitSoundToAll(poisonReadyWav,client);
        }
    }
}

public Action:EndPoison(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0 && m_PoisonActive[client])
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            PrepareAndEmitSoundToAll(poisonExpireWav,client);

            PrintHintText(client, "%t", "PoisonEnded");
        }

        ClearHud(client, "%t", "PoisonHud");
        m_PoisonActive[client]=false;
        CreateCooldown(client, raceID, poisonID);
    }
}

