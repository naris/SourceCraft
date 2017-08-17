/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranSCV.sp
 * Description: The Terran SCV race for SourceCraft.
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
#include <tf2_objects>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/ztf2grab>
#include <lib/ztf2nades>
#include <lib/tripmines>
#include <libdod/dod_ammo>
#include <libtf2/amp_node>
#include <libtf2/ammopacks>
#include <libtf2/tf2teleporter>
#include <libtf2/AdvancedInfiniteAmmo>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/ShopItems"
#include "sc/clienttimer"
#include "sc/SupplyDepot"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/bunker"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/BeamSprite"
#include "effect/SendEffects"

new const String:bunkerWav[]    = "sc/tmedheal.wav";

new const String:g_ArmorName[]  = "Armor";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.05},
                                    {0.00, 0.10},
                                    {0.05, 0.15},
                                    {0.10, 0.20} };

new Float:g_BunkerPercent[]     = { 0.00, 0.10, 0.20, 0.30, 0.40 };
new Float:g_TeleporterRate[]    = { 0.0, 8.0, 6.0, 3.0, 1.0 };
new Float:g_SupplyBunkerRange[] = { 0.0, 150.0, 250.0, 350.0, 450.0 };
new g_AmmopackMetal[]           = { 0, 0, 50, 100, 200 };

new Float:g_AmpRange[][]        =
{
    { 0.0,   0.0,   0.0,   0.0 },
    { 0.0, 100.0, 150.0, 200.0 },
    { 0.0, 150.0, 200.0, 250.0 },
    { 0.0, 200.0, 250.0, 300.0 },
    { 0.0, 250.0, 300.0, 350.0 }
};

new Float:g_NodeRange[][]       =
{
    { 0.0,   0.0,   0.0,   0.0 },
    { 0.0, 100.0, 150.0, 200.0 },
    { 0.0, 150.0, 250.0, 350.0 },
    { 0.0, 200.0, 300.0, 400.0 },
    { 0.0, 250.0, 350.0, 500.0 }
};

new g_NodeRegen[][]             =
{
    { 0,  0,  0,  0 },
    { 0, 10, 15, 20 },
    { 0, 15, 20, 25 },
    { 0, 20, 25, 30 },
    { 0, 25, 30, 40 }
};

new g_NodeShells[][]            =
{
    { 0,  0,  0,  0 },
    { 0,  0,  0,  0 },
    { 0,  0,  5, 10 },
    { 0,  5, 10, 15 },
    { 0, 10, 15, 20 }
};

new g_NodeRockets[]             = { 0,  0,  0,  2, 4 };

new raceID, armorID, supplyID, supplyBunkerID, ammopackID, teleporterID, immunityID;
new amplifierID, repairNodeID, tripmineID, nadeID, gravgunID, battlecruiserID, bunkerID;

new g_battlecruiserRace = -1;

new cfgAllowGravgun;
new bool:cfgAllowRepair;
new Float:cfgGravgunDuration;
new Float:cfgGravgunThrowSpeed;

new Float:m_GravTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran SCV",
    author = "-=|JFH|=-Naris",
    description = "The Terran SCV race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.ammopack.phrases.txt");
    LoadTranslations("sc.tripmine.phrases.txt");
    LoadTranslations("sc.grenade.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.bunker.phrases.txt");
    LoadTranslations("sc.supply.phrases.txt");
    LoadTranslations("sc.scv.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("scv", 48, 0, 37, .faction=Terran,
                                 .type=BioMechanical);

    supplyID        = AddUpgrade(raceID, "supply_depot", .cost_crystals=15);

    supplyBunkerID  = AddUpgrade(raceID, "supply_bunker", 0, 0, .cost_crystals=25);

    if (GameType != tf2)
    {
        SetUpgradeDisabled(raceID, supplyBunkerID, true);
        LogMessage("Disabling Terran SCV:Research Supply Bunkers due to gametype != tf2");
    }

    if (GameType == dod)
    {
        ammopackID = AddUpgrade(raceID, "ammopack", .cost_crystals=0,
                                .desc="%scv_ammopack_dod_desc");

        if (!IsDodAmmoAvailable())
        {
            SetUpgradeDisabled(raceID, ammopackID, true);
            LogMessage("Disabling Terran SCV:Ammopack due to dodammo is not available");
        }
    }
    else
    {
        ammopackID  = AddUpgrade(raceID, "ammopack", 5, 0, .energy=30.0,
                                 .cooldown=10.0, .cost_crystals=0);

        if (GetGameType() != tf2 || !IsAmmopacksAvailable())
        {
            SetUpgradeDisabled(raceID, ammopackID, true);
            LogMessage("Disabling Terran SCV:Ammopack due to ammopacks are not available (or gametype != tf2)");
        }
    }

    teleporterID    = AddUpgrade(raceID, "teleporter", .cost_crystals=0);

    if (GameType != tf2 || !IsTeleporterAvailable())
    {
        SetUpgradeDisabled(raceID, teleporterID, true);
        LogMessage("Disabling Terran SCV:Ammopack due to tf2teleporter is not available (or gametype != tf2)");
    }


    immunityID      = AddUpgrade(raceID, "immunity", .cost_crystals=0);
    armorID         = AddUpgrade(raceID, "armor", .cost_crystals=5);

    // Ultimate 1
    cfgAllowGravgun = GetConfigNum("allow_use", 2, .section="gravgun");

    if (GameType != tf2)
    {
        gravgunID   = AddUpgrade(raceID, "gravgun", 1, 10, 1, .energy=5.0,
                                 .recurring_energy=5.0, .cooldown=2.0, .cost_crystals=30,
                                 .desc="%scv_gravgun_notf2_desc");
    }
    else
    {
        cfgAllowRepair = bool:GetConfigNum("allow_repair", true, .section="gravgun");
        if (cfgAllowRepair)
        {
            gravgunID = AddUpgrade(raceID, "gravgun", 1, 10, .energy=5.0, .recurring_energy=5.0,
                                   .cooldown=2.0, .cost_crystals=75, .name="Gravity Gun",
                                   .desc=(cfgAllowGravgun >= 2) ?  "%scv_gravgun_desc"
                                                                :  "%scv_gravgun_engyonly_desc");
        }
        else
        {
            gravgunID = AddUpgrade(raceID, "gravgun", 1, 10, .energy=5.0, .recurring_energy=5.0,
                                   .cooldown=2.0, .cost_crystals=50, .name="Gravity Gun",
                                   .desc=(cfgAllowGravgun >= 2) ?  "%scv_gravgun_norepair_desc"
                                                                :  "%scv_gravgun_norepair_engyonly_desc");
        }
    }

    if (!IsGravgunAvailable() || !cfgAllowGravgun)
    {
        SetUpgradeDisabled(raceID, gravgunID, true);
        LogMessage("Disabling Terran SCV:Gravity Gun due to configuration: sc_allow_gravgun=%d or ztf2grab is not available",
                   cfgAllowGravgun);
    }

    // Ultimate 2
    bunkerID            = AddBunkerUpgrade(raceID, 2);

    // Ultimate 2
    tripmineID          = AddUpgrade(raceID, "tripmine", 2, .cost_crystals=40);

    if (!IsTripminesAvailable())
    {
        SetUpgradeDisabled(raceID, tripmineID, true);
        LogMessage("Disabling Terran SCV:Tripmine due to tripmines are not available");
    }

    // Ultimate 3 & 2
    nadeID              = AddUpgrade(raceID, "nade", 3, .cost_crystals=40);

    if (!IsNadesAvailable())
    {
        SetUpgradeDisabled(raceID, nadeID, true);
        LogMessage("Disabling Terran SCV:Grenade due to ztf2nades are not available");
    }

    // Ultimate 4
    battlecruiserID     = AddUpgrade(raceID, "battlecruiser", 4, 16, 1, .energy=300.0,
                                     .accumulated=true, .cooldown=60.0, .cost_crystals=50);

    amplifierID     = AddUpgrade(raceID, "amplifier", 0, 1);
    repairNodeID    = AddUpgrade(raceID, "repair_node", 0, 1);

    if (GameType != tf2 || !IsAmpNodeAvailable())
    {
        SetUpgradeDisabled(raceID, amplifierID, true);
        SetUpgradeDisabled(raceID, repairNodeID, true);
        LogMessage("Disabling Terran SCV:Research Amplifier & Repair Node due to amp_node is not available (or gametype != tf2)");
    }

    // Set the Infinite Ammo available flag
    IsInfiniteAmmoAvailable();

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

    if (GetGameType() == tf2)
    {
        GetConfigFloatArray("range", g_SupplyBunkerRange, sizeof(g_SupplyBunkerRange),
                            g_SupplyBunkerRange, raceID, supplyBunkerID);

        GetConfigArray("metal", g_AmmopackMetal, sizeof(g_AmmopackMetal),
                       g_AmmopackMetal, raceID, ammopackID);

        GetConfigFloatArray("rate", g_TeleporterRate, sizeof(g_TeleporterRate),
                            g_TeleporterRate, raceID, teleporterID);

        cfgGravgunDuration=GetConfigFloat("duration", 15.0, raceID, gravgunID);
        cfgGravgunThrowSpeed=GetConfigFloat("throw_speed", 500.0, raceID, gravgunID);

        for (new level=0; level < sizeof(g_AmpRange); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "range_level_%d", level);
            GetConfigFloatArray(key, g_AmpRange[level], sizeof(g_AmpRange[]),
                                g_AmpRange[level], raceID, amplifierID);
        }

        for (new level=0; level < sizeof(g_NodeRange); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "range_level_%d", level);
            GetConfigFloatArray(key, g_NodeRange[level], sizeof(g_NodeRange[]),
                                g_NodeRange[level], raceID, repairNodeID);
        }

        for (new level=0; level < sizeof(g_NodeRegen); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "regen_level_%d", level);
            GetConfigArray(key, g_NodeRegen[level], sizeof(g_NodeRegen[]),
                           g_NodeRegen[level], raceID, repairNodeID);
        }

        for (new level=0; level < sizeof(g_NodeShells); level++)
        {
            decl String:key[32];
            Format(key, sizeof(key), "shells_level_%d", level);
            GetConfigArray(key, g_NodeShells[level], sizeof(g_NodeShells[]),
                           g_NodeShells[level], raceID, repairNodeID);
        }

        GetConfigArray("rockets", g_NodeRockets, sizeof(g_NodeRockets),
                       g_NodeRockets, raceID, repairNodeID);
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "amp_node"))
        IsAmpNodeAvailable(true);
    else if (StrEqual(name, "tf2teleporter"))
        IsTeleporterAvailable(true);
    else if (StrEqual(name, "ammopacks"))
        IsAmmopacksAvailable(true);
    else if (StrEqual(name, "dodammo"))
        IsDodAmmoAvailable(true);
    else if (StrEqual(name, "tripmines"))
        IsTripminesAvailable(true);
    else if (StrEqual(name, "ztf2nades"))
        IsNadesAvailable(true);
    else if (StrEqual(name, "ztf2grab"))
        IsGravgunAvailable(true);
    else if (StrEqual(name, "aia"))
        IsInfiniteAmmoAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "ammopacks"))
        m_AmmopacksAvailable = false;
    else if (StrEqual(name, "dodammo"))
        m_DodAmmoAvailable = false;
    else if (StrEqual(name, "tf2teleporter"))
        m_TeleporterAvailable = false;
    else if (StrEqual(name, "tripmines"))
        m_TripminesAvailable = false;
    else if (StrEqual(name, "ztf2nades"))
        m_NadesAvailable = false;
    else if (StrEqual(name, "ztf2grab"))
        m_GravgunAvailable = false;
    else if (StrEqual(name, "amp_node"))
        m_AmpNodeAvailable = false;
    else if (StrEqual(name, "aia"))
        m_InfiniteAmmoAvailable = false;
}

public OnMapStart()
{
    SetupLightning();
    SetupBeamSprite();
    SetupHaloSprite();
    SetupSmokeSprite();
    SetupBlueGlow();
    SetupRedGlow();

    //SetupBunker();
    SetupDeniedSound();

    SetupErrorSound();

    SetupSound(bunkerWav);
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

        if (m_AmmopacksAvailable && GameType == tf2)
            SetAmmopack(client, 0);
        else if (m_DodAmmoAvailable && GameType == dod)
            SetDodAmmo(client, 0, 0, 0);

        if (m_TeleporterAvailable && GameType == tf2)
            SetTeleporter(client, 0.0);

        if (m_TripminesAvailable)
            TakeTripmines(client);

        if (m_AmpNodeAvailable)
        {
            SetUpgradeStation(client, .enable=false);
            SetAmplifier(client, .enable=false);
            SetRepairNode(client, .enable=false);
        }

        if (m_GravgunAvailable)
            TakeGravgun(client);

        if (m_NadesAvailable)
            TakeNades(client);

        // Turn off Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, false);

        return Plugin_Handled;
    }
    else
    {
        if (g_battlecruiserRace < 0)
            g_battlecruiserRace = FindRace("battlecruiser");

        if (oldrace == g_battlecruiserRace &&
            GetCooldownExpireTime(client, raceID, battlecruiserID) <= 0.0)
        {
            CreateCooldown(client, raceID, battlecruiserID,
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
        // Turn on Immunities
        new immunity_level=GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        if (m_TripminesAvailable)
        {
            new tripmine_level=GetUpgradeLevel(client,raceID,tripmineID);
            GiveTripmines(client, tripmine_level, tripmine_level, tripmine_level);
        }

        if (m_NadesAvailable)
        {
            new nade_level=GetUpgradeLevel(client,raceID,nadeID);
            GiveNades(client, nade_level, nade_level, nade_level,
                      nade_level, false, DefaultNade,
                      _:DamageFrom_Ultimates);
        }

        if (m_AmpNodeAvailable)
        {
            new amplifier_level = GetUpgradeLevel(client,raceID,amplifierID);
            SetAmplifier(client, .range=g_AmpRange[amplifier_level], .enable=(amplifier_level > 0));

            new repair_node_level = GetUpgradeLevel(client,raceID,repairNodeID);
            SetRepairNode(client, .range=g_NodeRange[repair_node_level],
                          .regen=g_NodeRegen[repair_node_level],
                          .shells=g_NodeShells[repair_node_level],
                          .rockets=g_NodeRockets[repair_node_level],
                          .enable=(repair_node_level > 0),
                          .team=(repair_node_level > 2));

            //SetUpgradeStation(client, .enable=(amplifier_level > 0) || (repair_node_level > 0));
        }

        new ammopack_level = GetUpgradeLevel(client,raceID,ammopackID);
        SetupAmmopack(client, ammopack_level);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new teleporter_level = GetUpgradeLevel(client,raceID,teleporterID);
        SetupTeleporter(client, teleporter_level);

        new gravgun_level=GetUpgradeLevel(client,raceID,gravgunID);
        SetupGravgun(client, gravgun_level);

        if (IsValidClientAlive(client))
        {
            new supply_level=GetUpgradeLevel(client,raceID,supplyID);
            new bunker_level=GetUpgradeLevel(client,raceID,supplyBunkerID);
            if (supply_level > 2 || bunker_level > 0)
            {
                CreateClientTimer(client, 5.0, SupplyDepot,
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
        if (upgrade == immunityID)
            DoImmunity(client, new_level, true);
        else if (upgrade==ammopackID)
            SetupAmmopack(client, new_level);
        else if (upgrade==teleporterID)
            SetupTeleporter(client, new_level);
        else if (upgrade==gravgunID)
            SetupGravgun(client, new_level);
        else if (upgrade==armorID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==tripmineID)
        {
            if (m_TripminesAvailable)
                GiveTripmines(client, new_level, new_level, new_level);
        }
        else if (upgrade==amplifierID)
        {
            if (m_AmpNodeAvailable)
            {
                //new repair_node_level=GetUpgradeLevel(client,raceID,repairNodeID);
                //SetUpgradeStation(client, .enable=(new_level > 0) || (repair_node_level > 0));

                SetAmplifier(client, .range=g_AmpRange[new_level],
                             .enable=(new_level > 0));
            }
        }
        else if (upgrade==repairNodeID)
        {
            if (m_AmpNodeAvailable)
            {
                //new amplifier_level=GetUpgradeLevel(client,raceID,amplifierID);
                //SetUpgradeStation(client, .enable=(amplifier_level > 0) || (new_level > 0));

                SetRepairNode(client, .range=g_NodeRange[new_level],
                              .regen=g_NodeRegen[new_level],
                              .shells=g_NodeShells[new_level],
                              .rockets=g_NodeRockets[new_level],
                              .enable=(new_level > 0),
                              .team=(new_level > 2));
            }
        }
        else if (upgrade==nadeID)
        {
            if (m_NadesAvailable)
            {
                GiveNades(client, new_level, new_level, new_level,
                          new_level, false, DefaultNade,
                          _:DamageFrom_Ultimates);
            }
        }
        else if (upgrade==supplyID)
        {
            new bunker_level=GetUpgradeLevel(client,raceID,supplyBunkerID);
            if (new_level > 0 || bunker_level > 0)
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 5.0, SupplyDepot,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
        }
        else if (upgrade==supplyBunkerID)
        {
            new supply_level=GetUpgradeLevel(client,raceID,supplyID);
            if (new_level > 0 || supply_level > 0)
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 5.0, SupplyDepot,
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
    if (race == raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 6:
            {
				new nade_level = GetUpgradeLevel(client,race,nadeID);
				if (nade_level > 0)
				{
					if (m_NadesAvailable)
					{
						if (GetRestriction(client, Restriction_NoUltimates) ||
							GetRestriction(client, Restriction_Stunned))
						{
							PrepareAndEmitSoundToClient(client,deniedWav);
							DisplayMessage(client, Display_Ultimate, "%t",
										   "PreventedFromThrowingGrenade");
						}
						else
							ThrowFragNade(client, pressed);
					}
					else if (pressed)
					{
						decl String:upgradeName[64];
						GetUpgradeName(raceID, nadeID, upgradeName, sizeof(upgradeName), client);
						PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
					}
				}
            }
            case 5:
            {
                if (!pressed)
                {
                    if (m_AmmopacksAvailable)
                    {
                        new ammopack_level = GetUpgradeLevel(client,race,ammopackID);
                        if (ammopack_level > 0)
                            DropPack(client, ammopack_level);
                    }
                }
            }
            case 4:
            {
                if (!pressed)
                {
                    new battlecruiser_level = GetUpgradeLevel(client,race,battlecruiserID);
                    if (battlecruiser_level > 0)
                        BuildBattlecruiser(client);
                    else if (m_AmmopacksAvailable)
                    {
                        new ammopack_level = GetUpgradeLevel(client,race,ammopackID);
                        if (ammopack_level > 0)
                            DropPack(client, ammopack_level);
                    }
                }
            }
            case 3:
            {
                new nade_level = GetUpgradeLevel(client,race,nadeID);
                if (nade_level > 0)
                {
                    if (m_NadesAvailable)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate, "%t",
                                           "PreventedFromThrowingGrenade");
                        }
                        else
                            ThrowSpecialNade(client, pressed);
                    }
                    else if (pressed)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, nadeID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
                else if (!pressed)
                {
                    new battlecruiser_level=GetUpgradeLevel(client,race,battlecruiserID);
                    if (battlecruiser_level > 0)
                        BuildBattlecruiser(client);
                    else if (m_AmmopacksAvailable)
                    {
                        new ammopack_level = GetUpgradeLevel(client,race,ammopackID);
                        if (ammopack_level > 0)
                            DropPack(client, ammopack_level);
                    }
                }
            }
            case 2:
            {
                new bunker_level = GetUpgradeLevel(client,race,bunkerID);
                if (bunker_level > 0)
                {
                    if (!pressed)
                    {
                        new armor = RoundToNearest(float(GetPlayerMaxHealth(client))
                                                   * g_BunkerPercent[bunker_level]);

                        EnterBunker(client, armor, raceID, bunkerID);
                    }
                }
                else
                {
                    new tripmine_level=GetUpgradeLevel(client,race,tripmineID);
                    if (tripmine_level > 0)
                    {
                        if (!pressed)
                        {
                            if (m_TripminesAvailable)
                            {
                                if (IsMole(client))
                                {
                                    decl String:upgradeName[64];
                                    GetUpgradeName(raceID, tripmineID, upgradeName, sizeof(upgradeName), client);
                                    DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                }
                                else if (GetRestriction(client, Restriction_NoUltimates) ||
                                         GetRestriction(client, Restriction_Stunned))
                                {
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                    DisplayMessage(client, Display_Ultimate, "%t",
                                                   "PreventedFromPlantingTripmine");
                                }
                                else
                                    SetTripmine(client);
                            }
                            else
                            {
                                decl String:upgradeName[64];
                                GetUpgradeName(raceID, tripmineID, upgradeName, sizeof(upgradeName), client);
                                PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                            }
                        }
                    }
                    else
                    {
                        new nade_level = GetUpgradeLevel(client,race,nadeID);
                        if (nade_level > 0)
                        {
                            if (m_NadesAvailable)
                            {
                                if (GetRestriction(client, Restriction_NoUltimates) ||
                                    GetRestriction(client, Restriction_Stunned))
                                {
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                    DisplayMessage(client, Display_Ultimate, "%t",
                                                   "PreventedFromThrowingGrenade");
                                }
                                else
                                    ThrowFragNade(client, pressed);
                            }
                            else if (pressed)
                            {
                                decl String:upgradeName[64];
                                GetUpgradeName(raceID, nadeID, upgradeName, sizeof(upgradeName), client);
                                PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                            }
                        }
                        else if (m_AmmopacksAvailable)
                        {
                            new ammopack_level = GetUpgradeLevel(client,race,ammopackID);
                            if (ammopack_level > 0)
                                DropPack(client, ammopack_level);
                        }
                    }
                }
            }
            default:
            {
                new gravgun_level = GetUpgradeLevel(client,race,gravgunID);
                if (gravgun_level > 0 && cfgAllowGravgun > 0)
                {
                    if (m_GravgunAvailable)
                    {
                        if (cfgAllowGravgun < 2 && GetGameType() == tf2 &&
                            TF2_GetPlayerClass(client) != TFClass_Engineer)
                        {
                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, gravgunID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "EngineersOnly", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else
                        {
                            if (pressed)
                            {
                                if (GetRestriction(client, Restriction_NoUltimates) ||
                                    GetRestriction(client, Restriction_Stunned))
                                {
                                    decl String:upgradeName[64];
                                    GetUpgradeName(raceID, gravgunID, upgradeName, sizeof(upgradeName), client);
                                    DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                }
                                else if (CanInvokeUpgrade(client, raceID, gravgunID, .notify=false))
                                    StartThrowObject(client);
                            }
                            else // if (!pressed)
                                ThrowObject(client);
                        }
                    }
                    else if (pressed)
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, gravgunID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
                else
                {
                    new tripmine_level = GetUpgradeLevel(client,race,tripmineID);
                    if (tripmine_level > 0)
                    {
                        if (!pressed)
                        {
                            if (m_TripminesAvailable)
                            {
                                if (IsMole(client))
                                {
                                    decl String:upgradeName[64];
                                    GetUpgradeName(raceID, tripmineID, upgradeName, sizeof(upgradeName), client);
                                    DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                }
                                else if (GetRestriction(client, Restriction_NoUltimates) ||
                                         GetRestriction(client, Restriction_Stunned))
                                {
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                    DisplayMessage(client, Display_Ultimate, "%t",
                                                   "PreventedFromPlantingTripmine");
                                }
                                else
                                    SetTripmine(client);
                            }
                            else
                            {
                                decl String:upgradeName[64];
                                GetUpgradeName(raceID, tripmineID, upgradeName, sizeof(upgradeName), client);
                                PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                            }
                        }
                    }
                    else
                    {
                        new nade_level = GetUpgradeLevel(client,race,nadeID);
                        if (nade_level > 0)
                        {
                            if (m_NadesAvailable)
                            {
                                if (GetRestriction(client, Restriction_NoUltimates) ||
                                    GetRestriction(client, Restriction_Stunned))
                                {
                                    PrepareAndEmitSoundToClient(client,deniedWav);
                                    DisplayMessage(client, Display_Ultimate, "%t",
                                                   "PreventedFromThrowingGrenade");
                                }
                                else
                                    ThrowFragNade(client, pressed);
                            }
                            else if (pressed)
                            {
                                decl String:upgradeName[64];
                                GetUpgradeName(raceID, nadeID, upgradeName, sizeof(upgradeName), client);
                                PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                            }
                        }
                        else if (m_AmmopacksAvailable)
                        {
                            new ammopack_level = GetUpgradeLevel(client,race,ammopackID);
                            if (ammopack_level > 0)
                                DropPack(client, ammopack_level);
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
        SetOverrideSpeed(client, -1.0);

        new immunity_level = GetUpgradeLevel(client,raceID,immunityID);
        DoImmunity(client, immunity_level, true);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new gravgun_level=GetUpgradeLevel(client,raceID,gravgunID);
        SetupGravgun(client, gravgun_level);

        if (m_AmpNodeAvailable)
        {
            new amplifier_level = GetUpgradeLevel(client,raceID,amplifierID);
            SetAmplifier(client, .range=g_AmpRange[amplifier_level],
                         .enable=(amplifier_level > 0));

            new repair_node_level = GetUpgradeLevel(client,raceID,repairNodeID);
            SetRepairNode(client, .range=g_NodeRange[repair_node_level],
                          .regen=g_NodeRegen[repair_node_level],
                          .shells=g_NodeShells[repair_node_level],
                          .rockets=g_NodeRockets[repair_node_level],
                          .enable=(repair_node_level > 0),
                          .team=(repair_node_level > 2));

            //SetUpgradeStation(client, .enable=(amplifier_level > 0) || (repair_node_level > 0));
        }

        new supply_level = GetUpgradeLevel(client,raceID,supplyID);
        new bunker_level = GetUpgradeLevel(client,raceID,supplyBunkerID);
        if (supply_level > 0 || bunker_level > 0)
        {
            CreateClientTimer(client, 5.0, SupplyDepot,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    SetOverrideSpeed(victim_index, -1.0);
    KillClientTimer(victim_index);

    if (g_battlecruiserRace < 0)
        g_battlecruiserRace = FindRace("battlecruiser");

    if (victim_race == g_battlecruiserRace &&
        GetCooldownExpireTime(victim_index, raceID, battlecruiserID) <= 0.0)
    {
        CreateCooldown(victim_index, raceID, battlecruiserID,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
}

DoImmunity(client, level, bool:value)
{
    SetImmunity(client,Immunity_Theft, (value && level >= 1));
    SetImmunity(client,Immunity_Ultimates, (value && level >= 2));
    SetImmunity(client,Immunity_MotionTaking, (value && level >= 3));
    SetImmunity(client,Immunity_Blindness, (value && level >= 4));

    if (value && IsValidClientAlive(client))
    {
        new Float:start[3];
        GetClientAbsOrigin(client, start);

        static const color[4] = { 0, 255, 50, 128 };
        TE_SetupBeamRingPoint(start,30.0,60.0, Lightning(), HaloSprite(),
                              0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
        TE_SendEffectToAll();
    }
}

SetupAmmopack(client, level)
{
    if (m_AmmopacksAvailable && GameType == tf2)
    {
        if (level > 0)
            SetAmmopack(client, (level >= 2) ? 3 : 1);
        else
            SetAmmopack(client, 0);
    }
    else if (m_DodAmmoAvailable && GameType == dod)
    {
        if (level > 0)
            SetDodAmmo(client, (level >= 2) ? 3 : 1, level);
        else
            SetDodAmmo(client, 0, 0, 0);
    }
}

SetupTeleporter(client, level)
{
    if (m_TeleporterAvailable)
        SetTeleporter(client, g_TeleporterRate[level]);
}

SetupGravgun(client, level)
{
    if (m_GravgunAvailable)
    {
        if (level > 0 && (cfgAllowGravgun >= 2 ||
                          (cfgAllowGravgun >= 1 &&
                           (GameType != tf2 || TF2_GetPlayerClass(client) == TFClass_Engineer))))
        {
            new Float:speed = cfgGravgunThrowSpeed * float(level);
            new Float:duration = cfgGravgunDuration * float(level);
            new permissions=HAS_GRABBER|CAN_STEAL;

            if (GameType == tf2)
            {
                permissions |= CAN_GRAB_BUILDINGS;

                if (level >= 2)
                    permissions |= CAN_GRAB_OTHER_BUILDINGS;

                if (level >= 3 && cfgAllowRepair)
                    permissions |= CAN_REPAIR_WHILE_HOLDING;

                if (level >= 4)
                    permissions |= CAN_THROW_BUILDINGS;
            }
            else
                permissions |= CAN_GRAB_PROPS;

            GiveGravgun(client, duration, speed, -1.0, permissions);
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

        if (GetRestriction(client, Restriction_NoUltimates) ||
            GetRestriction(client, Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, gravgunID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (CanInvokeUpgrade(client, raceID, gravgunID))
        {
            m_GravTime[client] = GetEngineTime();
        }
    }

    return Plugin_Continue;
}

public Action:OnCarryObject(client,ent,Float:time)
{
    if (GetRace(client) == raceID)
    {
        new Float:now = GetEngineTime();
        new Float:amount = GetUpgradeRecurringEnergy(raceID,gravgunID);
        if (now-m_GravTime[client] > amount)
        {
            if (GetRestriction(client, Restriction_NoUltimates) ||
                GetRestriction(client, Restriction_Stunned))
            {
                decl String:upgradeName[64];
                GetUpgradeName(raceID, gravgunID, upgradeName, sizeof(upgradeName), client);
                DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                PrepareAndEmitSoundToClient(client,deniedWav);
            }
            else if (CanProcessUpgrade(client, raceID, gravgunID))
            {
                decl String:upgradeName[64];
                GetUpgradeName(raceID, gravgunID, upgradeName, sizeof(upgradeName), client);
                DisplayMessage(client, Display_Energy, "%t", "ConsumedEnergy", upgradeName, amount);
                m_GravTime[client] = now;
                return Plugin_Continue;
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
        CreateCooldown(client, raceID, gravgunID);
    }
}

public Action:OnThrowObject(client, ent)
{
    OnDropObject(client, ent);
    return Plugin_Continue;
}

public Action:SupplyDepot(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client) && GetRace(client) == raceID &&
        !GetRestriction(client, Restriction_NoUpgrades) ||
        !GetRestriction(client, Restriction_Stunned))
    {
        new supply_level=GetUpgradeLevel(client,raceID,supplyID);
        if (supply_level > 0)
            SupplyAmmo(client, supply_level, "Supply Depot", SupplyDefault);

        if (GetGameType() == tf2 && TF2_GetPlayerClass(client) == TFClass_Engineer)
        {
            new bunker_level=GetUpgradeLevel(client,raceID,supplyBunkerID);
            if (bunker_level > 0)
            {
                new bunker_amount = bunker_level + 1;
                new bunker_health = bunker_amount * 5;
                new bunker_ammo = bunker_amount * 2;
                new Float:bunker_energy = float(bunker_amount) / 2.0;
                new Float:bunker_range=g_SupplyBunkerRange[bunker_level];

                new beamSprite = BeamSprite();
                new haloSprite = HaloSprite();

                static const ammoColor[4]    = {255, 225, 0, 255};
                static const healingColor[4] = {0, 255, 0, 255};

                new team = GetClientTeam(client);
                new maxentities = GetMaxEntities();
                for (new ent = MaxClients + 1; ent <= maxentities; ent++)
                {
                    if (IsValidEntity(ent) && IsValidEdict(ent))
                    {
                        if (TF2_GetExtObjectType(ent) != TFExtObject_Unknown)
                        {
                            if (GetEntPropEnt(ent, Prop_Send, "m_hBuilder") == client &&
                                GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") >= 1.0)
                            {
                                // Heal/Supply teammates
                                new Float:indexLoc[3];
                                new Float:pos[3];
                                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
                                pos[2] += 25.0; // Adjust trace position to the middle/top of the object instead of the bottom.

                                new count=0;
                                new alt_count=0;
                                new list[MaxClients+1];
                                new alt_list[MaxClients+1];
                                for (new index=1;index<=MaxClients;index++)
                                {
                                    if (IsClientInGame(index) && IsPlayerAlive(index))
                                    {
                                        if (index == client || GetClientTeam(index) == team)
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
                                            if (IsPointInRange(pos,indexLoc,bunker_range) &&
                                                TraceTargetIndex(ent, index, pos, indexLoc))
                                            {
                                                if (HealPlayer(index,bunker_health) > 0)
                                                {
                                                    PrepareAndEmitSoundToAll(bunkerWav,ent);
                                                }

                                                SupplyAmmo(index, bunker_ammo, "Supply Bunker", 
                                                           (GetRandomInt(0,10) > 8) ? SupplyDefault
                                                                                    : SupplySecondary);

                                                if (index != client)
                                                    IncrementEnergy(index, bunker_energy);
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

                                pos[2] -= 25.0; // Adjust position back to the floor.

                                if (count > 0)
                                {
                                    TE_SetupBeamRingPoint(pos, 10.0, bunker_range, beamSprite, haloSprite,
                                                          0, 15, 0.5, 5.0, 0.0, ammoColor, 10, 0);
                                    TE_Send(list, count, 0.0);

                                    TE_SetupBeamRingPoint(pos, 10.0, bunker_range, beamSprite, haloSprite,
                                                          0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                                    TE_Send(list, count, 0.0);
                                }

                                if (alt_count > 0)
                                {
                                    TE_SetupBeamRingPoint(pos, bunker_range-10.0, bunker_range, beamSprite, haloSprite,
                                                          0, 15, 0.5, 5.0, 0.0, ammoColor, 10, 0);
                                    TE_Send(alt_list, alt_count, 0.0);

                                    TE_SetupBeamRingPoint(pos, bunker_range-10.0, bunker_range, beamSprite, haloSprite,
                                                          0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                                    TE_Send(alt_list, alt_count, 0.0);
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

BuildBattlecruiser(client)
{
    if (g_battlecruiserRace < 0)
        g_battlecruiserRace = FindRace("battlecruiser");

    if (g_battlecruiserRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, battlecruiserID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Terran Battlecruiser race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromBuildingBattlecruiser");
    }
    else if (HasCooldownExpired(client, raceID, battlecruiserID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_battlecruiserRace, true, false, true);
    }
}

public Action:OnAmplify(builder,client,TFCond:condition)
{
    if (condition == TFCond_Buffed && builder > 0 && GetRace(builder) == raceID)
    {
        new Float:energy = GetEnergy(client);
        if (energy < 4.0)
            return Plugin_Stop;
        else
            SetEnergy(client, energy-4.0);
    }

    return Plugin_Continue;
}

DropPack(client,level)
{
    if (TF2_GetPlayerClass(client) == TFClass_Engineer)
        DropAmmopack(client, -1);
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate, "%t",
                       "PreventedFromDroppingAmmopack");
    }
    else if (CanInvokeUpgrade(client, raceID, ammopackID))
    {
        if (DropAmmopack(client, g_AmmopackMetal[level]))
            CreateCooldown(client, raceID, ammopackID);
    }
}
