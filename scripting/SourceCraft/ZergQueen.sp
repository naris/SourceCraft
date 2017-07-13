/*
 * vim: set ai et ts=4 sw=4 :
 * File: ZergQueen.sp
 * Description: The Zerg Queen race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2_meter>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/jetpack>
#include <libtf2/sidewinder>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/SpeedBoost"
#include "sc/maxhealth"
#include "sc/Detector"
#include "sc/plugins"
#include "sc/weapons"
#include "sc/sounds"
#include "sc/armor"

#include "effect/BeamSprite"
#include "effect/HaloSprite"

new const String:queenFireWav[] = "sc/zqufir00.wav";
new const String:ensnareHitWav[] = "sc/zquens00.wav";
new const String:infestedHitWav[] = "sc/zquhit02.wav";
new const String:parasiteHitWav[] = "sc/zqutag01.wav";
new const String:parasiteFireWav[] = "sc/zqutag00.wav";
new const String:broodlingHitWav[] = "sc/zqutag01.wav";

new const String:g_ArmorName[]  = "Carapace";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.25, 0.35, 0.50 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.05},
                                    {0.00, 0.10},
                                    {0.05, 0.20},
                                    {0.10, 0.40} };

new g_JetpackFuel[]             = { 0,     40,   50,   70, 90 };
new Float:g_JetpackRefuelTime[] = { 0.0, 45.0, 35.0, 25.0, 15.0 };

new Float:g_BroodlingRange[]    = { 350.0, 400.0, 650.0, 750.0, 900.0 };
new Float:g_InfestRange[]       = { 350.0, 400.0, 650.0, 750.0, 900.0 };
new Float:g_SpeedLevels[]       = { -1.0, 1.10, 1.15, 1.20, 1.25 };

new Float:g_EnsnareSpeed[]      = { 0.95, 0.90, 0.80, 0.70, 0.60 };
new g_EnsnareChance[]           = {    5,   15,   25,   35, 45 };

new raceID, armorID, regenerationID, pneumatizedID, parasiteID, ensnareID;
new jetpackID, meiosisID, broodlingID, infestID;

new g_broodlingRace = -1;
new g_infestedRace = -1;

new bool:m_Ensnared[MAXPLAYERS+1];
new Handle:m_ParasiteTimer[MAXPLAYERS+1];
new m_ParasiteCount[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Zerg Queen",
    author = "-=|JFH|=-Naris",
    description = "The Zerg Queen race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    LoadTranslations("sc.detector.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.queen.phrases.txt");

    raceID          = CreateRace("queen", 100, 0, 36, 120.0, 1000.0, 1.0,
                                 Zerg, Biological);

    armorID         = AddUpgrade(raceID, "armor", .cost_crystals=5);
    pneumatizedID   = AddUpgrade(raceID, "pneumatized", .cost_crystals=0);
    regenerationID  = AddUpgrade(raceID, "regeneration", .cost_crystals=10);
    parasiteID      = AddUpgrade(raceID, "parasite", .energy=1.0, .cost_crystals=20);
    ensnareID       = AddUpgrade(raceID, "ensnare", .energy=3.0, .cost_crystals=20);

    // Ultimate 1
    jetpackID       = AddUpgrade(raceID, "flyer", 1, .cost_crystals=30);

    if (!IsJetpackAvailable())
    {
        SetUpgradeDisabled(raceID, jetpackID, true);
        LogMessage("jetpack is not available");
    }

    meiosisID       = AddUpgrade(raceID, "meiosis", .cost_crystals=25);

    // Ultimate 2
    broodlingID     = AddUpgrade(raceID, "broodling", 2, 10,
                                 .energy=90.0, .cooldown=5.0,
                                 .accumulated=true, .cost_crystals=40);

    // Ultimate 3
    infestID        = AddUpgrade(raceID, "infest", 3, 12,
                                 .energy=180.0, .cooldown=5.0,
                                 .accumulated=true, .cost_crystals=40);

    // Set the Sidewinder available flag
    IsSidewinderAvailable();

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

    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, pneumatizedID);

    GetConfigArray("chance", g_EnsnareChance, sizeof(g_EnsnareChance),
                   g_EnsnareChance, raceID, ensnareID);

    GetConfigFloatArray("speed", g_EnsnareSpeed, sizeof(g_EnsnareSpeed),
                        g_EnsnareSpeed, raceID, ensnareID);

    GetConfigFloatArray("range",  g_BroodlingRange, sizeof(g_BroodlingRange),
                        g_BroodlingRange, raceID, broodlingID);

    GetConfigFloatArray("range",  g_InfestRange, sizeof(g_InfestRange),
                        g_InfestRange, raceID, infestID);

    GetConfigArray("fuel", g_JetpackFuel, sizeof(g_JetpackFuel),
                   g_JetpackFuel, raceID, jetpackID);

    GetConfigFloatArray("refuel_time", g_JetpackRefuelTime, sizeof(g_JetpackRefuelTime),
                        g_JetpackRefuelTime, raceID, jetpackID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "jetpack"))
        IsJetpackAvailable(true);
    else if (StrEqual(name, "sidewinder"))
        IsSidewinderAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "jetpack"))
        m_JetpackAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
}

public OnMapStart()
{
    SetupBeamSprite();
    SetupHaloSprite();

    SetupSpeed();

    SetupDeniedSound();

    SetupSound(queenFireWav);
    SetupSound(ensnareHitWav);
    SetupSound(infestedHitWav);
    SetupSound(parasiteHitWav);
    SetupSound(parasiteFireWav);
    SetupSound(broodlingHitWav);
}

public OnMapEnd()
{
    for (new index=1;index<=MaxClients;index++)
    {
        m_ParasiteTimer[index] = INVALID_HANDLE;	
        ResetParasite(index);
        ResetDetected(index);
        ResetEnsnared(index);
    }
}

public OnClientDisconnect(client)
{
    ResetParasite(client);
    ResetDetected(client);
    ResetEnsnared(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);
        SetHealthRegen(client, 0.0);
        SetSpeed(client, -1.0, true);
        SetInitialEnergy(client, -1.0);

        if (m_JetpackAvailable)
            TakeJetpack(client);

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

        new pneumatized_level = GetUpgradeLevel(client,raceID,pneumatizedID);
        SetSpeedBoost(client, pneumatized_level, true, g_SpeedLevels);

        new flyer_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, flyer_level);

        new meiosis_level = GetUpgradeLevel(client,raceID,meiosisID);
        new Float:initial_energy = GetInitialEnergy(client);
        new Float:meiosis_energy = 120.0 + float(meiosis_level*30);
        SetInitialEnergy(client, meiosis_energy);
        if (GetEnergy(client, true) >= initial_energy)
            SetEnergy(client, meiosis_energy, true);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==jetpackID)
            SetupJetpack(client, new_level);
        else if (upgrade==pneumatizedID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
        else if (upgrade==regenerationID)
            SetHealthRegen(client, float(new_level));
        else if (upgrade==meiosisID)
        {
            new Float:initial_energy = GetInitialEnergy(client);
            new Float:meiosis_energy = 120.0 + float(new_level*30);
            SetInitialEnergy(client, meiosis_energy);
            if (GetEnergy(client, true) >= initial_energy)
                SetEnergy(client, meiosis_energy, true);
        }
        else if (upgrade==armorID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
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
            new level = GetUpgradeLevel(client,race,pneumatizedID);
            if (level > 0)
                SetSpeedBoost(client, level, true, g_SpeedLevels);
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
                if (pressed)
                    InfestEnemy(client);
            }
            case 2:
            {
                if (pressed)
                    SpawnBroodling(client);
            }
            default:
            {
                new flyer_level=GetUpgradeLevel(client,raceID,jetpackID);
                if (flyer_level > 0)
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
            }
        }
    }
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new pneumatized_level = GetUpgradeLevel(client,raceID,pneumatizedID);
        SetSpeedBoost(client, pneumatized_level, true, g_SpeedLevels);

        new flyer_level=GetUpgradeLevel(client,raceID,jetpackID);
        SetupJetpack(client, flyer_level);

        new meiosis_level = GetUpgradeLevel(client,raceID,meiosisID);
        new Float:initial_energy = GetInitialEnergy(client);
        new Float:meiosis_energy = 120.0 + float(meiosis_level*30);
        SetInitialEnergy(client, meiosis_energy);
        if (GetEnergy(client, true) >= initial_energy)
            SetEnergy(client, meiosis_energy, true);

        new regeneration_level=GetUpgradeLevel(client,raceID,regenerationID);
        SetHealthRegen(client, float(regeneration_level));
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_race == raceID && attacker_index != victim_index &&
        IsClient(attacker_index) && IsClient(victim_index) )
    {
        new ensnare_level=GetUpgradeLevel(attacker_index, raceID, ensnareID);
        if (GetRandomInt(1,100)<=g_EnsnareChance[ensnare_level])
        {
            if (!m_Ensnared[victim_index] &&
                !GetRestriction(attacker_index, Restriction_NoUpgrades) &&
                !GetRestriction(attacker_index, Restriction_Stunned) &&
                !GetImmunity(victim_index,Immunity_MotionTaking) &&
                !GetImmunity(victim_index,Immunity_Upgrades) &&
                !GetImmunity(victim_index,Immunity_Restore) &&
                !IsInvulnerable(victim_index))
            {
                if (CanInvokeUpgrade(attacker_index, raceID, ensnareID, .notify=false))
                {
                    if (PrepareSound(ensnareHitWav))
                    {
                        EmitSoundToAll(ensnareHitWav,victim_index);
                        EmitSoundToClient(attacker_index, ensnareHitWav);
                    }

                    m_Ensnared[victim_index] = true;

                    SetOverrideGravity(victim_index, 1.0);
                    SetOverrideSpeed(victim_index, g_EnsnareSpeed[ensnare_level]);
                    SetRestriction(victim_index, Restriction_Grounded, true);

                    new Float:victim_energy=GetEnergy(victim_index)-float(ensnare_level*5);
                    SetEnergy(victim_index, (victim_energy > 0.0) ? victim_energy : 0.0);
                    CreateTimer(5.0,EnsnareExpire, GetClientUserId(victim_index),TIMER_FLAG_NO_MAPCHANGE);
                    returnCode = Plugin_Handled;
                }
            }
        }
        else
        {
            new parasite_level=GetUpgradeLevel(attacker_index, raceID, parasiteID);
            if (GetRandomInt(1,100)<=g_EnsnareChance[parasite_level])
            {
                if (m_ParasiteTimer[victim_index] == INVALID_HANDLE &&
                    !GetRestriction(attacker_index, Restriction_NoUpgrades) &&
                    !GetRestriction(attacker_index, Restriction_Stunned) &&
                    !GetImmunity(victim_index,Immunity_Upgrades) &&
                    !GetImmunity(victim_index,Immunity_Restore) &&
                    !IsInvulnerable(victim_index))
                {
                    if (CanInvokeUpgrade(attacker_index, raceID, parasiteID, .notify=false))
                    {
                        PrepareAndEmitSoundToAll(parasiteFireWav,attacker_index);
                        PrepareAndEmitSoundToAll(parasiteHitWav,victim_index);

                        SetOverrideVisiblity(victim_index, 255);
                        HudMessage(victim_index, "%t", "ParasiteHud");
                        DisplayMessage(victim_index,Display_Enemy_Ultimate, "%t",
                                       "InfestedWithParasite", attacker_index);

                        m_ParasiteCount[victim_index] = parasite_level*15;
                        m_ParasiteTimer[victim_index] = CreateTimer(1.0,Parasite,victim_index,
                                                                    TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

                        returnCode = Plugin_Handled;
                    }
                }
            }
        }
    }

    return returnCode;
}


public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    new Action:returnCode = Plugin_Continue;

    if (assister_race == raceID && IsClient(assister_index) && IsClient(victim_index))
    {
        new ensnare_level=GetUpgradeLevel(assister_index,raceID,ensnareID);
        if (GetRandomInt(1,100)<=g_EnsnareChance[ensnare_level])
        {
            if (!m_Ensnared[victim_index] &&
                !GetRestriction(assister_index, Restriction_NoUpgrades) &&
                !GetRestriction(assister_index, Restriction_Stunned) &&
                !GetImmunity(victim_index,Immunity_MotionTaking) &&
                !GetImmunity(victim_index,Immunity_Upgrades) &&
                !GetImmunity(victim_index,Immunity_Restore) &&
                !IsInvulnerable(victim_index))
            {
                if (CanInvokeUpgrade(assister_index, raceID, ensnareID, .notify=false))
                {
                    if (PrepareSound(ensnareHitWav))
                    {
                        EmitSoundToAll(ensnareHitWav,victim_index);
                        EmitSoundToClient(assister_index, ensnareHitWav);
                    }

                    m_Ensnared[victim_index] = true;
                    SetOverrideGravity(victim_index, 1.0);
                    SetOverrideSpeed(victim_index, g_EnsnareSpeed[ensnare_level]);
                    SetRestriction(victim_index, Restriction_Grounded, true);

                    new Float:victim_energy=GetEnergy(victim_index)-float(ensnare_level*5);
                    SetEnergy(victim_index, (victim_energy > 0.0) ? victim_energy : 0.0);
                    CreateTimer(5.0,EnsnareExpire, GetClientUserId(victim_index),TIMER_FLAG_NO_MAPCHANGE);
                    returnCode = Plugin_Handled;
                }
            }
        }
        else
        {
            new parasite_level=GetUpgradeLevel(assister_index,raceID,parasiteID);
            if (GetRandomInt(1,100)<=g_EnsnareChance[parasite_level])
            {
                if (m_ParasiteTimer[victim_index] == INVALID_HANDLE &&
                    !GetRestriction(assister_index, Restriction_NoUpgrades) &&
                    !GetRestriction(assister_index, Restriction_Stunned) &&
                    !GetImmunity(victim_index,Immunity_Upgrades) &&
                    !GetImmunity(victim_index,Immunity_Restore) &&
                    !IsInvulnerable(victim_index))
                {
                    if (CanInvokeUpgrade(assister_index, raceID, parasiteID, .notify=false))
                    {
                        PrepareAndEmitSoundToAll(parasiteFireWav,assister_index);
                        PrepareAndEmitSoundToAll(parasiteHitWav,victim_index);

                        SetOverrideVisiblity(victim_index, 255);
                        HudMessage(victim_index, "%t", "ParasiteHud");
                        DisplayMessage(victim_index,Display_Enemy_Ultimate, "%t",
                                "InfestedWithParasite", assister_index);

                        m_ParasiteCount[victim_index] = parasite_level*15;
                        m_ParasiteTimer[victim_index] = CreateTimer(1.0,Parasite,victim_index,
                                                                    TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                        returnCode = Plugin_Handled;
                    }
                }
            }
        }
    }

    return returnCode;
}

public Action:OnJetpack(client)
{
    if (m_Ensnared[client])
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action:EnsnareExpire(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
        ResetEnsnared(client);

    return Plugin_Stop;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (victim_index > 0)
    {
        ResetParasite(victim_index);
        ResetDetected(victim_index);
        ResetEnsnared(victim_index);
    }
}

public Action:OnPlayerRestored(client)
{
    ResetParasite(client);
    ResetDetected(client);
    ResetEnsnared(client);
    return Plugin_Continue;
}

public Action:Parasite(Handle:timer, any:client)
{
    if (IsValidClientAlive(client))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        new bool:decloaked=false;
        if (GetGameType() == tf2 &&
            !GetImmunity(client,Immunity_Upgrades))
        {
            new Float:meter = TF2_GetEnergyDrinkMeter(client);
            if (meter > 0.0 && meter <= 100.0)
                TF2_SetEnergyDrinkMeter(client, 0.0);

            meter = TF2_GetChargeMeter(client);
            if (meter > 0.0 && meter <= 100.0)
                TF2_SetChargeMeter(client, 0.0);

            meter = TF2_GetRageMeter(client);
            if (meter > 0.0 && meter <= 100.0)
                TF2_SetRageMeter(client, 0.0);

            meter = TF2_GetHypeMeter(client);
            if (meter > 0.0 && meter <= 100.0)
                TF2_SetHypeMeter(client, 0.0);

            if (!GetImmunity(client,Immunity_Uncloaking) &&
                TF2_GetPlayerClass(client) == TFClass_Spy)
            {
                TF2_GetCloakMeter(client);
                if (meter > 0.0 && meter <= 100.0)
                    TF2_SetCloakMeter(client, 0.0);

                if (TF2_IsPlayerDisguised(client))
                {
                    TF2_RemovePlayerDisguise(client);
                    decloaked=true;
                }

                if (TF2_IsPlayerCloaked(client) ||
                    TF2_IsPlayerDeadRingered(client))
                {
                    TF2_RemoveCondition(client,TFCond_Cloaked);
                    decloaked=true;
                }

                if (decloaked)
                {
                    DisplayMessage(client,Display_Enemy_Ultimate,
                                   "%t", "ParasiteUncloakedYou");
                }
            }
        }

        if (!GetImmunity(client,Immunity_Detection) &&
            !GetImmunity(client,Immunity_Upgrades))
        {
            SetOverrideVisiblity(client, 255);
            if (m_SidewinderAvailable)
                SidewinderDetectClient(client, true);
        }

        HudMessage(client, "%t", "ParasiteHud");

        new count = 0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        new amount = GetRandomInt(0,3)-2;
        new team = GetClientTeam(client);
        for (new index=1;index<=MaxClients;index++)
        {
            if (index != client && IsClientInGame(index))
            {
                if (GetClientTeam(index) == team)
                {
                    new bool:detect = !GetImmunity(index,Immunity_Detection) &&
                                      !GetImmunity(index,Immunity_Upgrades) &&
                                      IsPlayerAlive(index) &&
                                      IsInRange(client,index,500.0);
                    if (detect)
                    {
                        new Float:indexLoc[3];
                        GetClientAbsOrigin(index, indexLoc);
                        detect = TraceTargetIndex(client, index, clientLoc, indexLoc);
                    }
                    if (detect)
                    {
                        amount++;
                        SetOverrideVisiblity(index, 255);
                        if (m_SidewinderAvailable)
                            SidewinderDetectClient(index, true);

                        if (!m_Detected[client][index])
                        {
                            m_Detected[client][index] = true;
                            ApplyPlayerSettings(index);
                        }

                        HudMessage(index, "%t", "DetectedHud");
                        DisplayMessage(index,Display_Enemy_Ultimate, "%t",
                                       "DetectedByParasite", client);
                    }
                    else // undetect
                    {
                        SetOverrideVisiblity(index, -1);
                        if (m_SidewinderAvailable)
                            SidewinderDetectClient(index, false);

                        if (m_Detected[client][index])
                        {
                            m_Detected[client][index] = false;
                            ClearHud(index, "%t", "DetectedHud");
                            ApplyPlayerSettings(index);
                        }
                    }
                }
                else
                {
                    if (!GetSetting(index, Disable_OBeacons) &&
                        !GetSetting(index, Remove_Queasiness))
                    {
                        if (GetSetting(index, Reduce_Queasiness))
                            alt_list[alt_count++] = index;
                        else
                            list[count++] = index;
                    }
                }
            }
        }

        if (amount > 0)
        {
            new Float:energy = GetEnergy(client) - float(amount);
            SetEnergy(client, (energy > 0.0) ? energy : 0.0);
        }            

        if (GetRandomInt(1,100)<50)
        {
            PrepareAndEmitSoundToAll(parasiteHitWav,client);
        }

        static const parasiteColor[4] = {255, 182, 193, 255};
        clientLoc[2] -= 50.0; // Adjust position back to the feet.

        if (count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, 10.0, 500.0, BeamSprite(), HaloSprite(),
                                  0, 10, 0.6, 10.0, 0.5, parasiteColor, 10, 0);
            TE_Send(list, count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(clientLoc, 490.0, 500.0, BeamSprite(), HaloSprite(),
                                  0, 10, 0.6, 10.0, 0.5, parasiteColor, 10, 0);
            TE_Send(alt_list, alt_count, 0.0);
        }

        if (--m_ParasiteCount[client] > 0)
            return Plugin_Continue;
    }

    m_ParasiteTimer[client] = INVALID_HANDLE;
    ResetParasite(client);

    return Plugin_Stop;
}

ResetParasite(client)
{
    new Handle:timer = m_ParasiteTimer[client];
    if (timer != INVALID_HANDLE)
    {
        m_ParasiteTimer[client] = INVALID_HANDLE;	
        KillTimer(timer);
    }

    ClearHud(client, "%t", "ParasiteHud");
    ResetDetection(client);
    ResetDetected(client);
}

ResetEnsnared(client)
{
    if (m_Ensnared[client])
    {
        m_Ensnared[client] = false;
        SetOverrideSpeed(client, -1.0);
        SetOverrideGravity(client, -1.0);
        SetRestriction(client, Restriction_Grounded, false);
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
                LogError("%d:%N has too many levels in ZergQueen::Flyer level=%d, max=%d",
                         client,ValidClientIndex(client),level,sizeof(g_JetpackFuel));

                level = sizeof(g_JetpackFuel)-1;
            }
            GiveJetpack(client, g_JetpackFuel[level], g_JetpackRefuelTime[level]);
        }
        else
            TakeJetpack(client);
    }
}

GetTarget(client, level, const Float:range[])
{
    new target = GetClientAimTarget(client);
    if (target > 0 &&
        GetClientTeam(target) != GetClientTeam(client)) 
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);

        new Float:targetLoc[3];
        GetClientAbsOrigin(target, targetLoc);

        if (IsPointInRange(clientLoc,targetLoc,range[level]) &&
            TraceTargetClients(client, target, clientLoc, targetLoc))
        {
            if (!GetImmunity(target,Immunity_Ultimates) &&
                !IsInvulnerable(target))
            {
                return target;
            }
        }
    }
    return 0;
}

SpawnBroodling(client)
{
    new broodling_level = GetUpgradeLevel(client,raceID,broodlingID);
    if (broodling_level > 0)
    {
        if (g_broodlingRace < 0)
            g_broodlingRace = FindRace("broodling");

        if (g_broodlingRace < 0)
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, broodlingID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
            LogError("***The Broodling race is not Available!");
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromBroodling");
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (CanInvokeUpgrade(client, raceID, broodlingID))
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            new target = GetTarget(client, broodling_level, g_BroodlingRange);
            if (target > 0)
            {
                if ((GetAttribute(target,Attribute_IsBiological) ||
                     GetAttribute(target,Attribute_IsMechanical)) &&
                    !GetImmunity(target,Immunity_Ultimates) &&
                    !IsInvulnerable(target))
                {
                    PrepareAndEmitSoundToAll(queenFireWav,client);
                    PrepareAndEmitSoundToAll(broodlingHitWav,target);

                    ChangeRace(target, g_broodlingRace, true, false, false);

                    DisplayMessage(client,Display_Ultimate, "%t",
                                   "BroodlingSpawned", target);

                    CreateCooldown(client, raceID, broodlingID);
                }
                else
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    DisplayMessage(client, Display_Ultimate,
                                   "%t", "TargetIsInvulerable");
                }
            }
            else
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                DisplayMessage(client, Display_Ultimate,
                               " No Targets in Range!");
            }
        }
    }
}

InfestEnemy(client)
{
    new infest_level = GetUpgradeLevel(client,raceID,infestID);
    if (infest_level > 0)
    {
        if (g_infestedRace < 0)
            g_infestedRace = FindRace("infested");

        if (g_infestedRace < 0)
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, infestID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
            LogError("***The Infested race is not Available!");
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "PreventedFromInfesting");
        }
        else if (CanInvokeUpgrade(client, raceID, infestID))
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            new target = GetTarget(client, infest_level, g_InfestRange);
            if (target > 0)
            {
                if (!GetImmunity(target,Immunity_Ultimates) &&
                    !IsInvulnerable(target))
                {
                    PrepareAndEmitSoundToAll(queenFireWav,client);
                    PrepareAndEmitSoundToAll(infestedHitWav,target);

                    ChangeRace(target, g_infestedRace, true, false, false);

                    DisplayMessage(client,Display_Ultimate, "%t",
                                   "YouHaveInfested", target);

                    CreateCooldown(client, raceID, infestID);
                }
                else
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    DisplayMessage(client, Display_Ultimate,
                                   " Target is Immune or Invulerable!");
                }
            }
            else
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                DisplayMessage(client, Display_Ultimate,
                               " No Targets in Range!");
            }
        }
    }
}
