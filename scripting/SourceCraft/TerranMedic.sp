/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranMedic.sp
 * Description: The Terran Medic race for SourceCraft.
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
#include <lib/jetpack>
#include <lib/Hallucinate>
#include <libtf2/medipacks>
#include <libtf2/ubercharger>
#include <libtf2/MedicInfect>
#include <libdod/sm_dod_medic_class>
#include <libdod/dod_drophealthkit_source>

#include "sc/PlagueInfect"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/bunker"
#include "sc/sounds"

#include "effect/Fade"
#include "effect/Lightning"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"

//new const String:healWav[]    = "sc/tmedheal.wav";
new const String:restWav[]      = "sc/tmedrest.mp3";
new const String:flareWav[]     = "sc/tmedflsh.mp3";

new const String:g_ArmorName[]  = "Armor";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                   {0.00, 0.10},
                                   {0.00, 0.30},
                                   {0.10, 0.40},
                                   {0.20, 0.50} };

new g_JetpackFuel[]             = { 0, 40, 50, 70, 90 };
new Float:g_JetpackRefuelTime[] = { 0.0, 45.0, 35.0, 25.0, 15.0 };

new Float:g_BunkerPercent[]     = { 0.00, 0.10, 0.20, 0.30, 0.40 };

new Float:g_FlareRange[]        = { 0.0, 150.0, 300.0, 450.0, 600.0 };

new g_MedipackCharge[]          = { 0, 0, 10, 25, 50 };

new g_RegenerationAmount[]      = { 0, 1, 2, 3, 4 };

new g_HealingAmount[]           = { 0, 1, 2, 3, 4 };
new Float:g_HealingRange[]      = { 0.0, 150.0, 300.0, 450.0, 600.0 };

new Float:g_RestoreRange[]      = { 0.0, 150.0, 300.0, 450.0, 600.0 };

new g_MedicHeal[]               = { 35,  45,  50,  55,   60   };
new g_MedicNades[]              = { 0,   1,   2,   2,    2    };
new g_MedicWeapon[]             = { 0,   0,   0,   1,    1    };
new Float:g_MedicSpeed[]        = { 1.0, 1.1, 1.1, 1.15, 1.15 };
new Float:g_MedicWeight[]       = { 1.0, 1.0, 1.1, 1.1,  1.15 };

new raceID, regenerationID, healingID, chargeID, armorID, medipackID, infectID;
new restoreID, flareID, jetpackID, combatID, medicID, bunkerID;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Medic",
    author = "-=|JFH|=-Naris",
    description = "The Terran Medic race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.restore.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.medic.phrases.txt");

    if (!HookEvent("player_spawn",PlayerSpawnEvent))
        SetFailState("Couldn't hook the player_spawn event.");

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID  = CreateRace("medic", 32, 0, 36, .faction=Terran, .type=Biological);

    infectID = AddUpgrade(raceID, "infection", .energy=5.0, .cost_crystals=20);

    if (!IsPlagueInfectAvailable() && !IsInfectionAvailable())
    {
        LogMessage("Disabling Terran Medic:Infection due to PlagueInfect and/or MedicInfect are not available");
        SetUpgradeDisabled(raceID, infectID, true);
    }

    if (GetGameType() == dod)
    {
        // Ultimate 4
        medicID = AddUpgrade(raceID, "training", 4, 0, .cost_crystals=0);
        chargeID = -1;

        if (!IsMedicClassAvailable())
        {
            SetUpgradeDisabled(raceID, medicID, true);
            LogMessage("Disabling Terran Medic:Medic Training due to medic_class is not available");
        }
    }
    else
    {
        chargeID = AddUpgrade(raceID, "ubercharger", .cost_crystals=15);

        if (GameType != tf2 || !IsUberChargerAvailable())
        {
            SetUpgradeDisabled(raceID, chargeID, true);
            LogMessage("Disabling Terran Medic:Uber Charger due to ubercharger is not available (or gametype != tf2)");
        }

        if (GameType != tf2)
        {
            LogMessage("Disabling Terran Medic: Medic Training due to gametype != dod");
            medicID = AddUpgrade(raceID, "training", 4, 0, .cost_crystals=0);
            SetUpgradeDisabled(raceID, medicID, true);
        }
        else
        {
            medicID = -1;
        }
    }

    armorID = AddUpgrade(raceID, "armor", .cost_crystals=5);

    if (GameType == dod)
    {
        medipackID = AddUpgrade(raceID, "healthkit", .cost_crystals=0);

        if (!IsHealthkitAvailable())
        {
            SetUpgradeDisabled(raceID, medipackID, true);
            LogMessage("Disabling Terran Medic:Healthkit due to healthkits are not available");
        }
    }
    else
    {
        medipackID = AddUpgrade(raceID, "medipack", 4, 0, .energy=30.0,
                                .cooldown=10.0, .cost_crystals=0);

        if (GameType != tf2 || !IsMedipacksAvailable())
        {
            SetUpgradeDisabled(raceID, medipackID, true);
            LogMessage("Disabling Terran Medic:Medipack due to medipacks are not available (or gametype != tf2)");
        }
    }

    regenerationID  = AddUpgrade(raceID, "regeneration", .cost_crystals=10);

    healingID   = AddUpgrade(raceID, "healing", .cost_crystals=10);

    // Ultimate 3
    restoreID   = AddUpgrade(raceID, "restore", 3, .energy=20.0, .cost_crystals=0);

    // Ultimate 4 (or 3 in DoD)
    flareID     = AddUpgrade(raceID, "flare",
                             (GameType == dod && m_MedicClassAvailable) ? 4 : 3,
                             10, .energy=30.0, .cooldown=2.0, .cost_crystals=20);

    // Ultimate 1
    jetpackID   = AddUpgrade(raceID, "jetpack", 1, 12, .cost_crystals=25);

    if (!IsJetpackAvailable())
    {
        SetUpgradeDisabled(raceID, jetpackID, true);
        LogMessage("Disabling Terran Medic:Jetpack due to jetpack is not available");
    }

    // Ultimate 2
    bunkerID    = AddBunkerUpgrade(raceID, 2);

    combatID    = AddUpgrade(raceID, "combat", .cost_crystals=0);

    if (GameType != dod || !IsMedicClassAvailable())
    {
        LogMessage("Disabling Terran Medic:Combat Training due to medic_class is not available (or gametype != dod)");
        SetUpgradeDisabled(raceID, combatID, true);
    }

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

    GetConfigArray("health", g_RegenerationAmount, sizeof(g_RegenerationAmount),
                   g_RegenerationAmount, raceID, regenerationID);

    GetConfigArray("health", g_HealingAmount, sizeof(g_HealingAmount),
                   g_HealingAmount, raceID, healingID);

    GetConfigFloatArray("range",  g_HealingRange, sizeof(g_HealingRange),
                        g_HealingRange, raceID, healingID);

    GetConfigFloatArray("range",  g_RestoreRange, sizeof(g_RestoreRange),
                        g_RestoreRange, raceID, restoreID);

    GetConfigFloatArray("range", g_FlareRange, sizeof(g_FlareRange),
                        g_FlareRange, raceID, flareID);

    GetConfigArray("fuel", g_JetpackFuel, sizeof(g_JetpackFuel),
                   g_JetpackFuel, raceID, jetpackID);

    GetConfigFloatArray("refuel_time", g_JetpackRefuelTime, sizeof(g_JetpackRefuelTime),
                        g_JetpackRefuelTime, raceID, jetpackID);

    if (GameType == tf2)
    {
        GetConfigArray("charge", g_MedipackCharge, sizeof(g_MedipackCharge),
                       g_MedipackCharge, raceID, medipackID);
    }
    else if (GameType == dod)
    {
        GetConfigArray("heal", g_MedicHeal, sizeof(g_MedicHeal),
                       g_MedicHeal, raceID, medicID);

        GetConfigArray("nades", g_MedicNades, sizeof(g_MedicNades),
                       g_MedicNades, raceID, medicID);

        GetConfigArray("weapon", g_MedicWeapon, sizeof(g_MedicWeapon),
                       g_MedicWeapon, raceID, medicID);

        GetConfigFloatArray("speed", g_MedicSpeed, sizeof(g_MedicSpeed),
                            g_MedicSpeed, raceID, medicID);

        GetConfigFloatArray("gravity", g_MedicWeight, sizeof(g_MedicWeight),
                            g_MedicWeight, raceID, medicID);
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "PlagueInfect"))
        IsPlagueInfectAvailable(true);
    else if (StrEqual(name, "MedicInfect"))
        IsInfectionAvailable(true);
    else if (StrEqual(name, "medipacks"))
        IsMedipacksAvailable(true);
    else if (StrEqual(name, "healthkit"))
        IsHealthkitAvailable(true);
    else if (StrEqual(name, "ubercharger"))
        IsUberChargerAvailable(true);
    else if (StrEqual(name, "medic_class"))
        IsMedicClassAvailable(true);
    else if (StrEqual(name, "jetpack"))
        IsJetpackAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "PlagueInfect"))
        m_PlagueInfectAvailable = false;
    else if (StrEqual(name, "MedicInfect"))
        m_InfectionAvailable = false;
    else if (StrEqual(name, "medipacks"))
        m_MedipacksAvailable = false;
    else if (StrEqual(name, "healthkit"))
        m_HealthkitAvailable = false;
    else if (StrEqual(name, "ubercharger"))
        m_UberChargerAvailable = false;
    else if (StrEqual(name, "medic_class"))
        m_MedicClassAvailable = false;
    else if (StrEqual(name, "jetpack"))
        m_JetpackAvailable = false;
}

public OnMapStart()
{
    SetupLightning();
    SetupBeamSprite();
    SetupHaloSprite();

    //SetupBunker();
    SetupDeniedSound();

    SetupSound(restWav);
    SetupSound(flareWav);
    //SetupSound(healWav);
}

public OnMapEnd()
{
    ResetAllClientTimers();
}

public OnClientDisconnect(client)
{
    KillClientTimer(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);
        KillClientTimer(client);
        SetGravity(client,-1.0,false);
        SetSpeed(client,-1.0,false);

        if (m_UberChargerAvailable)
            SetUberCharger(client, false, 0.0);
        else if (m_MedicClassAvailable)
            UnassignMedic(client);

        if (m_JetpackAvailable)
            TakeJetpack(client);

        if (m_InfectionAvailable)
            SetMedicInfect(client, false, 0, 0);

        if (m_MedipacksAvailable)
            SetMedipack(client, 0, 0);

        if (m_HealthkitAvailable)
            SetHealthkit(client, 0, 0, 0);

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, jetpack_level);

        new medipack_level = GetUpgradeLevel(client,raceID,medipackID);
        if (medipack_level > 0)
            SetupMedipack(client, medipack_level);

        new infect_level = GetUpgradeLevel(client,raceID,infectID);
        if (infect_level > 0)
            SetupInfection(client, infect_level);

        if (GameType == dod)
        {
            new medic_level = GetUpgradeLevel(client,raceID,medicID);
            new combat_level = GetUpgradeLevel(client,raceID,combatID);
            SetupMedicClass(client, medic_level, combat_level);
        }
        else if (GameType == tf2)
        {
            new charge_level = GetUpgradeLevel(client,raceID,chargeID);
            if (charge_level > 0)
                SetupUberCharger(client, charge_level);
        }

        if (IsValidClientAlive(client))
        {
            new restore_level=GetUpgradeLevel(client,raceID,restoreID);
            new healing_aura_level=GetUpgradeLevel(client,raceID,healingID);
            new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
            if (restore_level > 0 || healing_aura_level > 0 || regeneration_level > 0)
            {
                CreateClientTimer(client, 2.0, Healing,
                                  TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
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
        if (upgrade==infectID)
            SetupInfection(client, new_level);
        else if (upgrade==chargeID)
            SetupUberCharger(client, new_level);
        else if (upgrade==medipackID)
            SetupMedipack(client, new_level);
        else if (upgrade==jetpackID)
            SetupJetpack(client, new_level);
        else if (upgrade==armorID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==medicID)
        {
            new combat_level = GetUpgradeLevel(client,raceID,combatID);
            SetupMedicClass(client, new_level, combat_level);
        }
        else if (upgrade==combatID)
        {
            new medic_level = GetUpgradeLevel(client,raceID,medicID);
            SetupMedicClass(client, medic_level, new_level);
        }
        else if (upgrade==restoreID)
        {
            if (new_level || GetUpgradeLevel(client,raceID,healingID)
                          || GetUpgradeLevel(client,raceID,regenerationID))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 2.0, Healing,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
        }
        else if (upgrade==healingID)
        {
            if (new_level || GetUpgradeLevel(client,raceID,restoreID)
                          || GetUpgradeLevel(client,raceID,regenerationID))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 2.0, Healing,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
        }
        else if (upgrade==regenerationID)
        {
            if (new_level || GetUpgradeLevel(client,raceID,restoreID)
                          || GetUpgradeLevel(client,raceID,healingID))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 2.0, Healing,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
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
                if (pressed)
                {
                    if (GameType == dod && m_MedicClassAvailable)
                        MedicHeal(client);
                    else
                    {
                        new flare_level=GetUpgradeLevel(client,race,flareID);
                        if (flare_level > 0)
                            OpticFlare(client, flare_level);
                        else
                        {
                            new restore_level = GetUpgradeLevel(client,race,restoreID);
                            if (restore_level > 0)
                                Restore(client, restore_level);
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
                                    new medipack_level = (m_MedipacksAvailable) ? GetUpgradeLevel(client,race,medipackID) : 0;
                                    if (medipack_level > 0)
                                        DropPack(client, medipack_level);
                                }
                            }
                        }
                    }
                }
            }
            case 3:
            {
                if (pressed)
                {
                    new restore_level = GetUpgradeLevel(client,race,restoreID);
                    if (restore_level > 0)
                        Restore(client, restore_level);
                    else
                    {
                        new flare_level=GetUpgradeLevel(client,race,flareID);
                        if (flare_level > 0)
                            OpticFlare(client, flare_level);
                        else
                        {
                            new bunker_level = GetUpgradeLevel(client,race,bunkerID);
                            if (bunker_level > 0)
                            {
                                new armor = RoundToNearest(float(GetPlayerMaxHealth(client))
                                          * g_BunkerPercent[bunker_level]);

                                EnterBunker(client, armor, raceID, bunkerID);
                            }
                            else if (GameType == dod && m_MedicClassAvailable)
                                MedicHeal(client);
                        }
                    }
                }
            }
            case 2:
            {
                if (pressed)
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
                        new restore_level = GetUpgradeLevel(client,race,restoreID);
                        if (restore_level > 0)
                            Restore(client, restore_level);
                        else
                        {
                            new flare_level=GetUpgradeLevel(client,race,flareID);
                            if (flare_level > 0)
                                OpticFlare(client, flare_level);
                            else if (m_MedicClassAvailable)
                                MedicHeal(client);
                        }
                    }
                }
            }
            default:
            {
                new jetpack_level = GetUpgradeLevel(client,race,jetpackID);
                if (jetpack_level > 0)
                    Jetpack(client, pressed);
                else if (pressed)
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
                        new restore_level = GetUpgradeLevel(client,race,restoreID);
                        if (restore_level > 0)
                            Restore(client, restore_level);
                        else
                        {
                            new flare_level=GetUpgradeLevel(client,race,flareID);
                            if (flare_level > 0)
                                OpticFlare(client, flare_level);
                            else if (m_MedicClassAvailable)
                                MedicHeal(client);
                        }
                    }
                }
            }
        }
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    if (client > 0)
    {
        SetVisibility(client, NormalVisibility); // Make sure infected players don't stay green!
        SetImmunity(client, Immunity_Restore, false); // Ensure no leftover restores hang around!

        if (GetRace(client) == raceID)
        {
            new armor_level = GetUpgradeLevel(client,raceID,armorID);
            SetupArmor(client, armor_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName);

            new jetpack_level=GetUpgradeLevel(client,raceID,jetpackID);
            SetupJetpack(client, jetpack_level);

            new medipack_level = GetUpgradeLevel(client,raceID,medipackID);
            if (medipack_level > 0)
                SetupMedipack(client, medipack_level);

            if (GameType == dod)
            {
                new medic_level = GetUpgradeLevel(client,raceID,medicID);
                new combat_level = GetUpgradeLevel(client,raceID,combatID);
                SetupMedicClass(client, medic_level, combat_level);
            }
            else if (GameType == tf2)
            {
                new charge_level = GetUpgradeLevel(client,raceID,chargeID);
                if (charge_level > 0)
                    SetupUberCharger(client, charge_level);
            }

            new restore_level = GetUpgradeLevel(client,raceID,restoreID);
            new healing_aura_level=GetUpgradeLevel(client,raceID,healingID);
            new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
            if (restore_level > 0 || healing_aura_level > 0 || regeneration_level > 0)
                CreateClientTimer(client, 2.0, Healing, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
        new infect_level = GetUpgradeLevel(attacker_index,raceID,infectID);
        if (GetRandomInt(1,100)<=infect_level*25)
        {
            if (!GetRestriction(attacker_index,Restriction_NoUpgrades) &&
                !GetRestriction(attacker_index,Restriction_Stunned) &&
                !GetImmunity(victim_index,Immunity_HealthTaking) &&
                !GetImmunity(victim_index,Immunity_Restore) &&
                !GetImmunity(victim_index,Immunity_Upgrades) &&
                !IsInvulnerable(victim_index))
            {
                if (CanInvokeUpgrade(attacker_index, raceID, infectID, .notify=false))
                {
                    PlagueInfect(attacker_index, victim_index, infect_level, infect_level,
                                 FatalPlague|ContagiousPlague|InfectiousPlague,
                                 "sc_infection");
                    return Plugin_Handled;
                }
            }
        }
    }
    return Plugin_Continue;
}


public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if (assister_race == raceID)
    {
        new infect_level = GetUpgradeLevel(assister_index,raceID,infectID);
        if (GetRandomInt(1,100)<=infect_level*25)
        {
            if (IsClient(victim_index) && !IsInvulnerable(victim_index) &&
                !GetRestriction(assister_index,Restriction_NoUpgrades) &&
                !GetRestriction(assister_index,Restriction_Stunned) &&
                !GetImmunity(victim_index,Immunity_HealthTaking) &&
                !GetImmunity(victim_index,Immunity_Upgrades) &&
                !GetImmunity(victim_index,Immunity_Restore))
            {
                if (CanInvokeUpgrade(assister_index, raceID, infectID, .notify=false))
                {
                    PlagueInfect(assister_index, victim_index, infect_level, infect_level,
                                 FatalPlague|ContagiousPlague|InfectiousPlague,
                                 "sc_infection");

                    return Plugin_Handled;
                }
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
    KillClientTimer(victim_index);
    SetVisibility(victim_index, NormalVisibility); // Make sure infected players don't stay green!
    SetImmunity(victim_index,Immunity_Restore, false); // Also Make sure Restore goes away!
}

public Action:OnInfected(victim,infector,source,bool:infected,const color[4])
{
    if (infected && (IsInvulnerable(victim) ||
        GetImmunity(victim,Immunity_HealthTaking) ||
        GetImmunity(victim,Immunity_Upgrades) ||
        GetImmunity(victim,Immunity_Restore)))
    {
        return Plugin_Stop;
    }
    else
    {
        // Only subtract energy for initial infection
        new medic = (source > 0) ? source : infector;
        if (medic > 0 && GetRace(medic) == raceID)
        {
            if (!CanInvokeUpgrade(medic, raceID, infectID, .notify=false))
                return Plugin_Stop;
        }

        SetVisibility(victim, BasicVisibility, color[3], .mode=RENDER_GLOW,
                      .r=color[0], .g=color[1], .b=color[2]);
    }
    return Plugin_Continue;
}

public Action:OnInfectionHurt(victim,infector,&amount)
{
    if (IsInvulnerable(victim) ||
        GetImmunity(victim,Immunity_HealthTaking) ||
        GetImmunity(victim,Immunity_Upgrades) ||
        GetImmunity(victim,Immunity_Restore))
    {
        return Plugin_Stop;
    }
    else
        return Plugin_Continue;
}

public Action:ResetRestore(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0 && GetImmunity(client,Immunity_Restore))
    {
        SetImmunity(client, Immunity_Restore, false);
        PrintHintText(client, "%t", "RestoreExpired");
        ClearHud(client, "%t", "RestoreHud");
    }
    return Plugin_Stop;
}

public Action:OnMedicHealed(client, patient, amount)
{
    if (GetRace(client) == raceID)
    {
        new xp = (amount / 2);
        new crystals = (amount / 5);
        new vespene = (amount / 10);
        SetXP(client, raceID, GetXP(client, raceID)+xp);
        SetCrystals(client, GetCrystals(client)+crystals);
        SetVespene(client, GetVespene(client)+vespene);

        LogToGame("%N gained %d experience for healing %N", client, xp, patient);
        DisplayMessage(client, Display_XP, "%t", "GainedXPForHealing", xp, patient);

        LogToGame("%N gained %d crystals for healing %N", client, crystals, patient);
        DisplayMessage(client, Display_Crystals, "%t", "GainedCrystalsForHealing", crystals, patient);

        LogToGame("%N gained %d vespene for healing %N", client, vespene, patient);
        DisplayMessage(client, Display_Vespene, "%t", "GainedVespeneForHealing", vespene, patient);
    }
}

public Action:Healing(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID &&
            !GetRestriction(client,Restriction_NoUpgrades) &&
            !GetRestriction(client,Restriction_Stunned))
        {
            new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
            if (regeneration_level > 0)
                HealPlayer(client,g_RegenerationAmount[regeneration_level]);

            new restore_level = GetUpgradeLevel(client,raceID,restoreID);
            new healing_aura_level=GetUpgradeLevel(client,raceID,healingID);
            if (restore_level > 0 || healing_aura_level > 0)
            {
                static const restoreColor[4] = { 64, 245, 208, 255 };
                static const healingColor[4] = { 0, 255, 0, 255 };

                new Float:distance;
                new Float:indexLoc[3];
                new Float:clientLoc[3];
                GetClientAbsOrigin(client, clientLoc);
                clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

                new Float:restore_range = g_RestoreRange[restore_level];
                new Float:healing_range = g_HealingRange[healing_aura_level];
                new healing_amount = g_HealingAmount[healing_aura_level];

                new count=0;
                new alt_count=0;
                new list[MaxClients+1];
                new alt_list[MaxClients+1];
                new team=GetClientTeam(client);
                for (new index=1;index<=MaxClients;index++)
                {
                    if (index != client && IsClientInGame(index) &&
                        IsPlayerAlive(index) && GetClientTeam(index) == team)
                    {
                        if (!GetSetting(index, Disable_Beacons) &&
                            !GetSetting(index, Remove_Queasiness))
                        {
                            if (GetSetting(index, Reduce_Queasiness))
                                alt_list[alt_count++] = index;
                            else
                                list[count++] = index;
                        }

                        GetClientAbsOrigin(index, indexLoc);
                        indexLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

                        distance = GetVectorDistance(clientLoc,indexLoc);

                        if (restore_level > 0 && distance <= restore_range)
                        {
                            if (TraceTarget(client, index, clientLoc, indexLoc))
                            {
                                TE_SetupBeamPoints(clientLoc, indexLoc, Lightning(), HaloSprite(),
                                                   0, 1, 3.0, 10.0,10.0,5,50.0,restoreColor,255);
                                TE_SendEffectToOthers(client, index);

                                //PrepareAndEmitSoundToAll(restWav,index);
                                RestorePlayer(index);
                                if (m_InfectionAvailable)
                                    HealInfect(client,index);

                                if (!GetImmunity(index,Immunity_Restore))
                                    SetImmunity(index, Immunity_Restore, true);
                            }
                            else
                                SetImmunity(index, Immunity_Restore, false);
                        }
                        else
                            SetImmunity(index, Immunity_Restore, false);

                        if (healing_aura_level > 0 && distance <= healing_range)
                        {
                            if (TraceTarget(client, index, clientLoc, indexLoc))
                            {
                                //PrepareAndEmitSoundToAll(healWav,index);
                                HealPlayer(index,healing_amount);
                            }
                        }
                    }
                }

                if (!GetSetting(client, Disable_Beacons) &&
                    !GetSetting(client, Remove_Queasiness))
                {
                    if (GetSetting(client, Reduce_Queasiness))
                        alt_list[alt_count++] = client;
                    else
                        list[count++] = client;
                }

                clientLoc[2] -= 50.0; // Adjust position back to the feet.

                if (count > 0)
                {
                    if (restore_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, 10.0, restore_range, BeamSprite(), HaloSprite(),
                                              0, 15, 0.5, 5.0, 0.0, restoreColor, 10, 0);
                        TE_Send(list, count, 0.0);
                    }

                    if (healing_aura_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, 10.0, healing_range, BeamSprite(), HaloSprite(),
                                              0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                        TE_Send(list, count, 0.0);
                    }
                }

                if (alt_count > 0)
                {
                    if (restore_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, restore_range-10.0, restore_range, BeamSprite(), HaloSprite(),
                                              0, 15, 0.5, 5.0, 0.0, restoreColor, 10, 0);
                        TE_Send(alt_list, alt_count, 0.0);
                    }

                    if (healing_aura_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, healing_range-10.0, healing_range, BeamSprite(), HaloSprite(),
                                              0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                        TE_Send(alt_list, alt_count, 0.0);
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

Jetpack(client, bool:pressed)
{
    if (m_JetpackAvailable)
    {
        if (pressed)
        {
            if (InBunker(client) ||
                GetRestriction(client, Restriction_NoUltimates) ||
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

SetupJetpack(client, level)
{
    if (m_JetpackAvailable)
    {
        if (level > 0)
        {
            if (level >= sizeof(g_JetpackFuel))
            {
                LogError("%d:%N has too many levels in TerranMedic::Jetpack level=%d, max=%d",
                         client,ValidClientIndex(client),level,sizeof(g_JetpackFuel));

                level = sizeof(g_JetpackFuel)-1;
            }
            GiveJetpack(client, g_JetpackFuel[level], g_JetpackRefuelTime[level]);
        }
        else
            TakeJetpack(client);
    }
}

SetupInfection(client, level)
{
    if (m_InfectionAvailable)
    {
        if (level > 0)
            SetMedicInfect(client, true, level, level*25);
        else
            SetMedicInfect(client, false, 0, 0);
    }
}

SetupUberCharger(client, level)
{
    if (m_UberChargerAvailable)
    {
        if (level > 0)
            SetUberCharger(client, true, float(level) * 0.01);
        else
            SetUberCharger(client, false, 0.0);
    }
}

SetupMedicClass(client, medic_level, combat_level)
{
    if (m_MedicClassAvailable)
    {
        new bool:all_weapons = (combat_level >= 4);

        AssignMedic(client, all_weapons, all_weapons, g_MedicSpeed[medic_level],
                    g_MedicWeight[medic_level], .heal=g_MedicHeal[medic_level],
                    .packs=(medic_level+1), .weapon=g_MedicWeapon[combat_level],
                    .nades=g_MedicNades[combat_level]);

        SetGravity(client,g_MedicWeight[medic_level],false);
        SetSpeed(client,g_MedicSpeed[medic_level],false);
    }
}

SetupMedipack(client, level)
{
    if (m_MedipacksAvailable && GameType == tf2)
    {
        if (level > 0)
            SetMedipack(client, (level >= 2) ? 3 : 1, (level-1)*2);
        else
            SetMedipack(client, 0, 0);
    }
    else if (m_HealthkitAvailable && GameType == dod)
    {
        if (level > 0)
            SetHealthkit(client, (level >= 2) ? 3 : 1, 0, level);
        else
            SetHealthkit(client, 0, 0, 0);
    }
}

Restore(client,restore_level)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, restoreID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, restoreID))
    {
        PrepareAndEmitSoundToAll(restWav,client);
        RestorePlayer(client);
        PerformDrug(client, 0);
        PerformBlind(client, 0);
        if (m_InfectionAvailable)
            HealInfect(client);

        SetImmunity(client, Immunity_Restore, true);

        new Float:time = 2.0 * float(restore_level);
        CreateTimer(time,ResetRestore,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
        PrintHintText(client, "%t", "RestoreActive", time);
        HudMessage(client, "%t", "RestoreHud");
    }
}

OpticFlare(client,ultlevel)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, flareID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, flareID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        new count=0;
        new duration = ultlevel*100;
        new team = GetClientTeam(client);
        new Float:range = g_FlareRange[ultlevel];
        for(new index=1;index<=MaxClients;index++)
        {
            if (client != index && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!IsInvulnerable(index) &&
                    !GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_Blindness) &&
                    !GetImmunity(index,Immunity_Restore))
                {
                    new Float:indexLoc[3];
                    GetClientAbsOrigin(index, indexLoc);
                    if (IsPointInRange(clientLoc, indexLoc, range) &&
                        TraceTargetIndex(client, index, clientLoc, indexLoc))
                    {
                        static const color[4]={250,250,250,255};
                        FadeOne(index, duration, duration , color, FFADE_IN);
                        count++;
                    }
                }
            }
        }
        
        decl String:upgradeName[64];
        GetUpgradeName(raceID, flareID, upgradeName, sizeof(upgradeName), client);

        if (count)
        {
            DisplayMessage(client, Display_Ultimate, "%t",
                           "ToBlindEnemies", upgradeName,
                           count);
        }
        else
        {
            DisplayMessage(client,Display_Ultimate, "%t",
                           "WithoutEffect", upgradeName);
        }

        PrepareAndEmitSoundToAll(flareWav,client);
        CreateCooldown(client, raceID, flareID);
    }
}

DropPack(client,level)
{
    if (TF2_GetPlayerClass(client) == TFClass_Medic)
        DropMedipack(client, -1);
    else if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "PreventedFromDroppingMedipack");
    }
    else if (CanInvokeUpgrade(client, raceID, medipackID))
    {
        if (DropMedipack(client, g_MedipackCharge[level]))
            CreateCooldown(client, raceID, medipackID);
    }
}

