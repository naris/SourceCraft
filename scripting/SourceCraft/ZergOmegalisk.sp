/**
 * vim: set ai et ts=4 sw=4 :
 * File: ZergOmegalisk.sp
 * Description: The Zerg Omegalisk unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_flag>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/hgrsource>
#define REQUIRE_PLUGIN

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <lib/trace>

#include "sc/SourceCraft"
#include "sc/MeleeAttack"
#include "sc/clienttimer"
#include "sc/ShopItems"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/burrow"
#include "sc/sounds"
#include "sc/armor"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"

new const String:g_KaiserBladesSound[] = "sc/zulhit01.wav";

new raceID, regenerationID, healingID, carapaceID, burrowID;
new meleeID, nodeID, tentacleID, ultraliskID;

new const String:g_ArmorName[]      = "Carapace";
new Float:g_InitialArmor[]          = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:g_ArmorPercent[][2]       = { {0.00, 0.00},
                                        {0.00, 0.10},
                                        {0.00, 0.30},
                                        {0.10, 0.40},
                                        {0.20, 0.50} };

new Float:g_KaiserBladesPercent[]   = { 0.0, 0.15, 0.30, 0.40, 0.50 };

new g_HealingAmount[]               = { 0, 1, 2, 3, 4 };
new Float:g_HealingRange[]          = { 0.0, 300.0, 450.0, 650.0, 800.0 };

new Float:g_TentacleRange[]         = { 0.0, 500.0, 1000.0, 1500.0, 2000.0 };
new g_TentacleDuration[]            = { 0, 10, 30, 50, 200 };

new g_ultraliskRace = -1;

public Plugin:myinfo = 
{
    name = "SourceCraft Unit - Zerg Omegalisk",
    author = "-=|JFH|=-Naris",
    description = "The Zerg Omegalisk unit for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.omegalisk.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID          = CreateRace("omegalisk", 32, 0, 26, 50.0, 500.0,
                                 .faction=Zerg, .type=Biological);

    meleeID         = AddUpgrade(raceID, "kaiser_blades", .energy=2.0, .cost_crystals=20);
    regenerationID  = AddUpgrade(raceID, "regeneration", .cost_crystals=10);
    healingID       = AddUpgrade(raceID, "healing", .cost_crystals=10);
    carapaceID      = AddUpgrade(raceID, "armor", .cost_crystals=5);
    nodeID          = AddUpgrade(raceID, "node", .cost_crystals=25);

    // Ultimate 1
    tentacleID  = AddUpgrade(raceID, "tentacle", 1, .energy=10.0,
                             .recurring_energy=1.0, .cooldown=5.0,
                             .cost_crystals=30);

    if (!IsHGRSourceAvailable())
    {
        SetUpgradeDisabled(raceID, tentacleID, true);
        LogMessage("Disabling Zerg Omegalisk:Tentacle due to hgrsource is not available");
    }

    // Ultimate 2
    burrowID    = AddBurrowUpgrade(raceID, 2, 6, 1);

    // Ultimate 3
    ultraliskID = AddUpgrade(raceID, "ultralisk", 3, 14,1,
                             .energy=500.0, .cooldown=60.0,
                             .accumulated=true, .cost_crystals=50);

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

    GetConfigArray("health", g_HealingAmount, sizeof(g_HealingAmount),
                   g_HealingAmount, raceID, healingID);

    GetConfigFloatArray("range",  g_HealingRange, sizeof(g_HealingRange),
                        g_HealingRange, raceID, healingID);

    GetConfigFloatArray("damage_percent", g_KaiserBladesPercent, sizeof(g_KaiserBladesPercent),
                        g_KaiserBladesPercent, raceID, meleeID);

    GetConfigArray("duration", g_TentacleDuration, sizeof(g_TentacleDuration),
                   g_TentacleDuration, raceID, tentacleID);

    GetConfigFloatArray("range", g_TentacleRange, sizeof(g_TentacleRange),
                        g_TentacleRange, raceID, tentacleID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "hgrsource"))
        IsHGRSourceAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "hgrsource"))
        m_HGRSourceAvailable = false;
}

public OnMapStart()
{
    SetupBeamSprite();
    SetupHaloSprite();
    SetupSmokeSprite();
    SetupBlueGlow();
    SetupRedGlow();

    SetupErrorSound();
    SetupDeniedSound();

    SetupSound(g_KaiserBladesSound);
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
        SetEnergyRate(client, -1.0);
        KillClientTimer(client);
        SetupTentacle(client, 0);
        return Plugin_Handled;
    }
    else
    {
        if (g_ultraliskRace < 0)
            g_ultraliskRace = FindRace("ultralisk");

        if (oldrace == g_ultraliskRace &&
            GetCooldownExpireTime(client, raceID, ultraliskID) <= 0.0)
        {
            CreateCooldown(client, raceID, ultraliskID,
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
        SetupTentacle(client, GetUpgradeLevel(client,raceID,tentacleID));

        new node_level = GetUpgradeLevel(client,raceID,nodeID);
        SetEnergyRate(client, (node_level > 0) ? float(node_level) : -1.0);

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new healing_aura_level=GetUpgradeLevel(client,raceID,healingID);
        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        if ((healing_aura_level > 0 || regeneration_level > 0)
            && IsValidClientAlive(client))
        {
            CreateClientTimer(client, 1.0, Regeneration,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
        if (upgrade==tentacleID)
            SetupTentacle(client, new_level);
        else if (upgrade==nodeID)
            SetEnergyRate(client, (new_level > 0) ? float(new_level) : -1.0);
        else if (upgrade==carapaceID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade==healingID)
        {
            if (new_level || GetUpgradeLevel(client,raceID,regenerationID))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 1.0, Regeneration,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
        }
        else if (upgrade==regenerationID)
        {
            if (new_level || GetUpgradeLevel(client,raceID,healingID))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 1.0, Regeneration,
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
            case 4,3:
            {
                if (!pressed)
                {
                    new ultralisk_level=GetUpgradeLevel(client,race,ultraliskID);
                    if (ultralisk_level > 0)
                        EvolveUltralisk(client);
                }
            }
            case 2:
            {
                if (pressed)
                {
                    new burrow_level=GetUpgradeLevel(client,race,burrowID);
                    if (burrow_level > 0)
                        Burrow(client, burrow_level);
                }
            }
            default:
            {
                if (m_HGRSourceAvailable)
                {
                    if (pressed)
                    {
                        if (GetRestriction(client, Restriction_NoUltimates) ||
                            GetRestriction(client, Restriction_Stunned))
                        {
                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, tentacleID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else
                        {
                            if (GameType == tf2 && TF2_IsPlayerDisguised(client))
                                TF2_RemovePlayerDisguise(client);

                            Grab(client);
                        }
                    }
                    else
                        Drop(client);
                }
                else if (pressed)
                {
                    decl String:upgradeName[64];
                    GetUpgradeName(raceID, tentacleID, upgradeName, sizeof(upgradeName), client);
                    PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
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
        SetupTentacle(client, GetUpgradeLevel(client,raceID,tentacleID));

        new node_level = GetUpgradeLevel(client,raceID,nodeID);
        SetEnergyRate(client, (node_level > 0) ? float(node_level) : -1.0);

        new carapace_level = GetUpgradeLevel(client,raceID,carapaceID);
        SetupArmor(client, carapace_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new healing_aura_level=GetUpgradeLevel(client,raceID,healingID);
        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        if (healing_aura_level > 0 || regeneration_level > 0)
        {
            CreateClientTimer(client, 1.0, Regeneration,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (attacker_index && attacker_index != victim_index &&
        attacker_race == raceID && !from_sc)
    {
        new kaiser_blades_level=GetUpgradeLevel(attacker_index,raceID,meleeID);
        if (kaiser_blades_level > 0)
        {
            if (MeleeAttack(raceID, meleeID, kaiser_blades_level, event, damage+absorbed,
                            victim_index, attacker_index, g_KaiserBladesPercent,
                            g_KaiserBladesSound, "sc_kaiser_blades"))
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
    KillClientTimer(victim_index);

    if (g_ultraliskRace < 0)
        g_ultraliskRace = FindRace("ultralisk");

    if (victim_race == g_ultraliskRace &&
        GetCooldownExpireTime(victim_index, raceID, ultraliskID) <= 0.0)
    {
        CreateCooldown(victim_index, raceID, ultraliskID,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
}

public Action:OnGrabPlayer(client, target)
{
    TraceInto("ZergOnegalisk", "OnGrabPlayer", "client=%d:%N, client=%d:%N", \
              client, ValidClientIndex(client), target, ValidClientIndex(target));
    
    if (GetRace(client) != raceID)
    {
        TraceReturn();
        return Plugin_Continue;
    }
    else if (!IsValidClientAlive(target))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        TraceReturn("IsValidClientAlive() failed");
        return Plugin_Stop;
    }
    /*else if (GetClientTeam(client) == GetClientTeam(target))
    {
        PrepareAndEmitSoundToClient(client,errorWav);
        DisplayMessage(client, Display_Ultimate, "%t", "TargetIsTeammate");
        TraceReturn("GetClientTeam() failed, target is same team as client;");
        return Plugin_Stop;
    }*/
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, tentacleID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
        TraceReturn("GetRestriction() failed;");
        return Plugin_Stop;
    }
    else if (GetImmunity(target,Immunity_Ultimates))
    {
        PrepareAndEmitSoundToClient(client,errorWav);
        DisplayMessage(client, Display_Ultimate, "%t", "TargetIsImmune");
        TraceReturn("GetImmunity() failed;");
        return Plugin_Stop;
    }
    else if (IsBurrowed(target))
    {
        PrepareAndEmitSoundToClient(client,errorWav);
        DisplayMessage(client, Display_Ultimate, "%t", "TargetIsBurrowed");
        TraceReturn("IsBurrowed() failed;");
        return Plugin_Stop;
    }
    else
    {
        /*if (GameType == tf2)
        {
            if (TF2_IsPlayerTaunting(client) ||
                     TF2_IsPlayerDazed(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_IsPlayerTaunting() || TF2_IsPlayerDazed() failed;");
                return Plugin_Stop;
            }
            //case TFClass_Scout:
            else if (TF2_IsPlayerBonked(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_IsPlayerBonked() failed;");
                return Plugin_Stop;
            }
            //case TFClass_Spy:
            else if (TF2_IsPlayerCloaked(client) ||
                     TF2_IsPlayerDeadRingered(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_IsPlayerCloaked() || TF2_IsPlayerDeadRingered() failed;");
                return Plugin_Stop;
            }
            else if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
            else if (TF2_HasTheFlag(target))
            {
                // Don't let flag carrier get grabbed to prevent crashes.
                decl String:upgradeName[64];
                GetUpgradeName(raceID, tentacleID, upgradeName, sizeof(upgradeName), client);
                DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn("TF2_HasTheFlag() failed;");
                return Plugin_Stop;
            }
        }*/

        if (CanInvokeUpgrade(client, raceID, tentacleID))
        {
            SetOverrideGravity(target, 0.0);
            TraceReturn("Plugin_Continue");
            return Plugin_Continue;
        }
        else
        {
            TraceReturn("CanInvokeUpgrade() failed;");
            return Plugin_Stop;
        }
    }
}

public Action:OnDragPlayer(client, target)
{
    TraceInto("ZergOnegalisk", "OnDragPlayer", "client=%d:%N, client=%d:%N", \
              client, ValidClientIndex(client), target, ValidClientIndex(target));

    if (GetRace(client) == raceID && IsValidClient(client) &&
        IsValidClientAlive(target))
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, tentacleID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            TraceReturn("GetRestriction() failed;");
            return Plugin_Stop;
        }
        else
        {
            /*if (GameType == tf2)
            {
                if (TF2_IsPlayerTaunting(client) ||
                    TF2_IsPlayerDazed(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    TraceReturn("TF2_IsPlayerTaunting() || TF2_IsPlayerDazed() failed;");
                    return Plugin_Stop;
                }
                //case TFClass_Scout:
                else if (TF2_IsPlayerBonked(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    TraceReturn("TF2_IsPlayerBonked() failed;");
                    return Plugin_Stop;
                }
                //case TFClass_Spy:
                else if (TF2_IsPlayerCloaked(client) ||
                        TF2_IsPlayerDeadRingered(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    TraceReturn("TF2_IsPlayerCloaked() || TF2_IsPlayerDeadRingered() failed;");
                    return Plugin_Stop;
                }
                else if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }*/

            if (CanProcessUpgrade(client, raceID, tentacleID))
            {
                if (IsBurrowed(target))
                    ResetBurrow(target, true);

                TraceReturn("Plugin_Continue");
                return Plugin_Continue;
            }
            else
            {
                TraceReturn("CanProcessUpgrade() failed");
                return Plugin_Stop;
            }
        }
    }
    else
    {
        TraceReturn("Plugin_Continue");
        return Plugin_Continue;
    }
}

public Action:OnDropPlayer(client, target)
{
    if (client > 0 && GetRace(client) == raceID)
    {
        if (IsValidClient(target))
            SetOverrideGravity(target, -1.0, true, true);

        if (IsValidClient(client))
            CreateCooldown(client, raceID, tentacleID);
    }
    return Plugin_Continue;
}

public SetupTentacle(client, level)
{
    if (m_HGRSourceAvailable)
    {
        if (level > 0)
            GiveGrab(client,g_TentacleDuration[level],g_TentacleRange[level],0.0,1);
        else
            TakeGrab(client);
    }
}

public Action:Regeneration(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client) && GetRace(client) == raceID &&
        !GetRestriction(client,Restriction_NoUpgrades) &&
        !GetRestriction(client,Restriction_Stunned))
    {
        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        if (regeneration_level > 0)
            HealPlayer(client,regeneration_level);

        new healing_aura_level=GetUpgradeLevel(client,raceID,healingID);
        if (healing_aura_level > 0)
        {
            static const healingColor[4] = {0, 255, 0, 255};
            new Float:indexLoc[3];
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);
            clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

            new count=0;
            new alt_count=0;
            new list[MaxClients+1];
            new alt_list[MaxClients+1];
            new team = GetClientTeam(client);
            new auraAmount = g_HealingAmount[healing_aura_level]; // healing_aura_level*5;
            new Float:range=g_HealingRange[healing_aura_level];
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
                    if (IsPointInRange(clientLoc,indexLoc,range) &&
                        TraceTargetIndex(client, index, clientLoc, indexLoc))
                    {
                        HealPlayer(index,auraAmount);
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
                TE_SetupBeamRingPoint(clientLoc, 10.0, range, BeamSprite(), HaloSprite(),
                                      0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                TE_Send(list, count, 0.0);
            }

            if (alt_count > 0)
            {
                TE_SetupBeamRingPoint(clientLoc, range-10.0, range, BeamSprite(), HaloSprite(),
                                      0, 10, 0.6, 10.0, 0.5, healingColor, 10, 0);
                TE_Send(alt_list, alt_count, 0.0);
            }
        }
    }
    return Plugin_Continue;
}

EvolveUltralisk(client)
{
    if (g_ultraliskRace < 0)
        g_ultraliskRace = FindRace("ultralisk");

    if (g_ultraliskRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, ultraliskID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Zerg Ultralisk race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromUltralisk");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (HasCooldownExpired(client, raceID, ultraliskID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0,40.0,255);
        TE_SendEffectToAll();

        ChangeRace(client, g_ultraliskRace, true, false, true);
    }
}

