/**
 * vim: set ai et ts=4 sw=4 :
 * File: ZergDefiler.sp
 * Description: The Zerg Defiler race for SourceCraft.
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
#include "sc/HealthParticle"
#include "sc/clienttimer"
#include "sc/maxhealth"
#include "sc/DarkSwarm"
#include "sc/weapons"
#include "sc/Plague"
#include "sc/burrow"
#include "sc/armor"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:evolveWav[] = "sc/evolutioncomplete.wav";

new const String:g_PlagueSound[] = "sc/zdeblo01.wav";
new const String:g_PlagueShort[] = "sc_plague";

new const String:g_ArmorName[]  = "Carapace";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.30},
                                    {0.10, 0.40},
                                    {0.20, 0.50} };

new Float:g_PlagueRange[]       = { 300.0, 400.0, 550.0, 700.0, 900.0 };
new Float:g_DarkSwarmRange[]    = { 300.0, 400.0, 600.0, 800.0, 1000.0 };
new Float:g_ConsumePercent[]    = { 0.0, 0.10, 0.18, 0.28, 0.40 };

new raceID, carapaceID, regenerationID, consumeID, burrowID, darkSwarmID, plagueID, infestorID;

new g_infestorRace = -1;

new Float:m_ConsumeEnemyTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Zerg Defiler",
    author = "-=|JFH|=-Naris",
    description = "The Zerg race Defiler for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.defiler.phrases.txt");
    LoadTranslations("sc.protector.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("defiler", 48, 0, 22, 45.0,
                                 .faction=Zerg, .type=Biological);

    regenerationID  = AddUpgrade(raceID, "regeneration", .cost_crystals=10);
    carapaceID      = AddUpgrade(raceID, "armor", .cost_crystals=5);
    consumeID       = AddUpgrade(raceID, "consume", .energy=2.0, .cost_crystals=20);

    // Ultimate 2
    burrowID        = AddBurrowUpgrade(raceID, 2, 6, 1);

    // Ultimate 3
    darkSwarmID     = AddUpgrade(raceID, "dark_swarm", 3, 8, .energy=90.0,
                                 .cooldown=10.0, .cost_crystals=30);

    // Ultimate 1
    plagueID        = AddUpgrade(raceID, "plague", 1, .energy=90.0,
                                 .cooldown=10.0, .cost_crystals=30);

    // Ultimate 4
    infestorID      = AddUpgrade(raceID, "infestor", 4, 12, 1,
                                 .energy=120.0, .cooldown=30.0,
                                 .accumulated=true, .cost_crystals=30);

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

    GetConfigFloatArray("damage_percent", g_ConsumePercent, sizeof(g_ConsumePercent),
                        g_ConsumePercent, raceID, consumeID);

    GetConfigFloatArray("range", g_DarkSwarmRange, sizeof(g_DarkSwarmRange),
                        g_DarkSwarmRange, raceID, darkSwarmID);

    GetConfigFloatArray("range", g_PlagueRange, sizeof(g_PlagueRange),
                        g_PlagueRange, raceID, plagueID);
}

public OnMapStart()
{
    SetupBeamSprite();
    SetupHaloSprite();
    SetupSmokeSprite();
    SetupBlueGlow();
    SetupRedGlow();

    SetupDeniedSound();

    SetupDarkSwarm();
    SetupPlague(g_PlagueSound);

    SetupSound(evolveWav);
}

public OnPlayerAuthed(client)
{
    m_ConsumeEnemyTime[client] = 0.0;
}

public OnClientDisconnect(client)
{
    ResetPlague(client);
    ResetDarkSwarm(client);
    ResetProtected(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        SetHealthRegen(client, 0.0);
        ResetDarkSwarm(client);
        ResetPlague(client);
        ResetArmor(client);
        return Plugin_Handled;
    }
    else
    {
        if (g_infestorRace < 0)
            g_infestorRace = FindRace("infestor");

        if (oldrace == g_infestorRace &&
            GetCooldownExpireTime(client, raceID, infestorID) <= 0.0)
        {
            CreateCooldown(client, raceID, infestorID,
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
        if (upgrade==regenerationID)
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

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4:
            {
                if (!pressed)
                {
                    new infestor_level=GetUpgradeLevel(client,race,infestorID);
                    if (infestor_level > 0)
                        EvolveInfestor(client);
                }
            }
            case 3:
            {
                new swarm_level=GetUpgradeLevel(client,race,darkSwarmID);
                if (swarm_level > 0)
                {
                    if (pressed)
                        DarkSwarm(client, race, darkSwarmID, swarm_level, g_DarkSwarmRange);
                }
                else if (!pressed)
                {
                    new infestor_level=GetUpgradeLevel(client,race,infestorID);
                    if (infestor_level > 0)
                        EvolveInfestor(client);
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
                    new swarm_level=GetUpgradeLevel(client,race,darkSwarmID);
                    if (swarm_level > 0)
                    {
                        if (pressed)
                            DarkSwarm(client, race, darkSwarmID, swarm_level, g_DarkSwarmRange);
                    }
                    else if (!pressed)
                    {
                        new infestor_level=GetUpgradeLevel(client,race,infestorID);
                        if (infestor_level > 0)
                            EvolveInfestor(client);
                    }
                }
            }
            default:
            {
                new plague_level=GetUpgradeLevel(client,race,plagueID);
                if (plague_level > 0)
                {
                    if (pressed)
                    {
                        Plague(client, race, plagueID, plague_level,
                               UltimatePlague|InfectiousPlague, false,
                               g_PlagueRange, g_PlagueSound, g_PlagueShort);
                    }
                }
                else
                {
                    new swarm_level=GetUpgradeLevel(client,race,darkSwarmID);
                    if (swarm_level > 0)
                    {
                        if (pressed)
                            DarkSwarm(client, race, darkSwarmID, swarm_level, g_DarkSwarmRange);
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
                            new infestor_level=GetUpgradeLevel(client,race,infestorID);
                            if (infestor_level > 0)
                                EvolveInfestor(client);
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
        m_ConsumeEnemyTime[client] = 0.0;

        new regeneration_level = GetUpgradeLevel(client,raceID,regenerationID);
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
    ResetProtected(victim_index);

    if (g_infestorRace < 0)
        g_infestorRace = FindRace("infestor");

    if (victim_race == g_infestorRace &&
        GetCooldownExpireTime(victim_index, victim_race, infestorID) <= 0.0)
    {
        CreateCooldown(victim_index, raceID, infestorID,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (ConsumeEnemy(damage + absorbed, attacker_index, victim_index))
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
        if (ConsumeEnemy(damage + absorbed, assister_index, victim_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

bool:ConsumeEnemy(damage, index, victim_index)
{
    new level = GetUpgradeLevel(index, raceID, consumeID);
    if (level > 0 && GetRandomInt(1,10) <= 6 &&
        IsValidClientAlive(index) &&
        !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned))
    {
        new bool:victimIsNPC    = (victim_index > MaxClients);
        new bool:victimIsPlayer = !victimIsNPC && IsValidClientAlive(victim_index) &&
                                  !GetImmunity(victim_index,Immunity_HealthTaking) &&
                                  !GetImmunity(victim_index,Immunity_Upgrades) &&
                                  !IsInvulnerable(victim_index);

        if (victimIsPlayer || victimIsNPC)
        {
            new Float:lastTime = m_ConsumeEnemyTime[index];
            new Float:interval = GetGameTime() - lastTime;
            if ((lastTime == 0.0 || interval > 0.5) &&
                CanInvokeUpgrade(index, raceID, consumeID, .notify=false))
            {
                new Float:start[3];
                GetClientAbsOrigin(index, start);
                start[2] += 1620;

                new Float:end[3];
                GetClientAbsOrigin(index, end);
                end[2] += 20;

                static const color[4] = { 255, 10, 25, 255 };
                TE_SetupBeamPoints(start, end, BeamSprite(), HaloSprite(),
                                   0, 1, 3.0, 20.0,10.0,5,50.0,color,255);
                TE_SendEffectToAll();
                FlashScreen(index,RGBA_COLOR_GREEN);
                FlashScreen(victim_index,RGBA_COLOR_RED);

                m_ConsumeEnemyTime[index] = GetGameTime();

                new leechhealth=RoundFloat(float(damage)*g_ConsumePercent[level]);
                if (leechhealth <= 0)
                    leechhealth = 1;

                new health=GetClientHealth(index) + leechhealth;
                if (health <= GetMaxHealth(index))
                {
                    ShowHealthParticle(index);
                    SetEntityHealth(index,health);

                    decl String:upgradeName[NAME_STRING_LENGTH];
                    GetUpgradeName(raceID, consumeID, upgradeName, sizeof(upgradeName), index);

                    if (victimIsPlayer)
                    {
                        DisplayMessage(index, Display_Damage, "%t", "YouHaveLeechedFrom",
                                       leechhealth, victim_index, upgradeName);
                    }
                    else
                    {
                        DisplayMessage(index, Display_Damage, "%t", "YouHaveLeeched",
                                       leechhealth, upgradeName);
                    }
                }

                if (victimIsPlayer)
                {
                    new victim_health = IsClient(victim_index) ? GetClientHealth(victim_index) : leechhealth+1;
                    if (victim_health <= leechhealth)
                        KillPlayer(victim_index, index, "sc_consume");
                    else
                    {
                        SetEntityHealth(victim_index, victim_health - leechhealth);

                        if (GameType != tf2 || GetMode() != MvM)
                        {
                            new entities = EntitiesAvailable(200, .message="Reducing Effects");
                            if (entities > 50)
                                CreateParticle("blood_impact_red_01_chunk", 0.1, victim_index, Attach, "head");
                        }

                        decl String:upgradeName[NAME_STRING_LENGTH];
                        GetUpgradeName(raceID, consumeID, upgradeName, sizeof(upgradeName), victim_index);
                        DisplayMessage(victim_index, Display_Injury, "%t", "HasLeeched",
                                       index, leechhealth, upgradeName);
                    }
                }
                else
                {
                    DamageEntity(victim_index, leechhealth, index, DMG_GENERIC, "sc_consume");
                    DisplayDamage(index, victim_index, leechhealth, "sc_consume");
                }

                return true;
            }
        }
    }
    return false;
}

EvolveInfestor(client)
{
    if (g_infestorRace < 0)
        g_infestorRace = FindRace("infestor");

    if (g_infestorRace < 0)
    {
        decl String:upgradeName[NAME_STRING_LENGTH];
        GetUpgradeName(raceID, infestorID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Zerg Infestor race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromInfestor");
    }
    else if (HasCooldownExpired(client, raceID, infestorID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        PrepareAndEmitSoundToAll(evolveWav,client);
        ChangeRace(client, g_infestorRace, true, false, true);
    }
}

