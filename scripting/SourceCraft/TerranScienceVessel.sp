/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranScienceVessel.sp
 * Description: The Terran Science Vessel race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#include <tf2_player>
#include <tf2_meter>
#include <tf2_flag>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <hgrsource>
#include <sidewinder>
#include <ubershield>
#include <ubercharger>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/Levitation"
#include "sc/ShopItems"
#include "sc/plugins"
#include "sc/Plague"
#include "sc/sounds"
#include "sc/freeze"
#include "sc/armor"

#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"

new const String:empWav[]           = "sc/tveemp00.wav";    // EMP sound
new const String:deathWav[]         = "sc/tvedth00.wav";  // Death sound
new const String:buildWav[]         = "sc/tverdy00.wav";  // Spawn sound

new const String:g_PlagueSound[]    = "sc/tveirr00.wav"; // Irradiate sound
new const String:g_PlagueShort[]    = "sc_irradiate";

new raceID, armorID, liftersID, detectorID, reactorID;
new chargeID, plagueID, matrixID, empID, ravenID;

new const String:g_ArmorName[]  = "Plating";
new Float:g_InitialArmor[]      = { 0.0, 0.10, 0.25, 0.50, 0.75 };
new Float:g_ArmorPercent[][2]   = { {0.00, 0.00},
                                    {0.00, 0.10},
                                    {0.00, 0.30},
                                    {0.10, 0.40},
                                    {0.20, 0.50} };

new Float:g_PlagueRange[]       = { 300.0, 400.0, 550.0, 700.0, 900.0 };
new Float:g_EmpRadius[]         = { 0.0, 250.0, 500.0, 750.0, 1000.0 };
new Float:g_DetectorRange[]     = { 0.0, 300.0, 450.0, 650.0, 800.0 };
new Float:g_LevitationLevels[]  = { 1.0, 0.92, 0.733, 0.5466, 0.36 };

new g_ravenRace = -1;

new bool:m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Science Vessel",
    author = "-=|JFH|=-Naris",
    description = "The Terran Science Vessel race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.vessel.phrases.txt");
    LoadTranslations("sc.detector.phrases.txt");

    if (GetGameType() == tf2)
    {
        if (!HookEventEx("teamplay_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_win event.");

        if (!HookEventEx("teamplay_round_stalemate",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_stalemate event.");
    }
    else if (GameType == dod)
    {
        if (!HookEventEx("dod_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the dod_round_win event.");
    }
    else if (GameTypeIsCS())
    {
        if (!HookEventEx("round_end",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the round_end event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("vessel", -1, -1, 80, .energy_limit=1000.0,
                             .faction=Terran, .type=Mechanical,
                             .parent="ghost");

    armorID     = AddUpgrade(raceID, "armor", 0, 0, .cost_crystals=5);
    liftersID   = AddUpgrade(raceID, "lifters", .cost_crystals=0);
    detectorID  = AddUpgrade(raceID, "detector", .cost_crystals=0);
    reactorID   = AddUpgrade(raceID, "reactor", 0, 14, .cost_crystals=20);

    chargeID = AddUpgrade(raceID, "ubercharger", .cost_crystals=0);

    if (GetGameType() != tf2 || !IsUberChargerAvailable())
    {
        SetUpgradeDisabled(raceID, chargeID, true);
        LogMessage("Disabling Terran Science Vessel:Uber Charger due to ubercharger is not available (or gametype != tf2)");
    }

    // Ultimate 1
    matrixID = AddUpgrade(raceID, "matrix", 1, 8, .energy=60.0, .cost_crystals=30,
                          .cooldown=2.0, .name="Defensive Matrix");

    if (!IsUberShieldAvailable())
    {
        SetUpgradeDisabled(raceID, matrixID, true);
        LogMessage("Disabling Terran Science Vessel:Defensive Matrix due to ubershield is not available (or gametype != tf2)");
    }

    // Ultimate 2
    empID       = AddUpgrade(raceID, "emp", 2, 1, .energy=80.0,
                             .cooldown=2.0, .cost_crystals=30);

    // Ultimate 3
    plagueID    = AddUpgrade(raceID, "irradiate", 3, 14, .energy=45.0, .cooldown=2.0, .cost_crystals=30);

    // Ultimate 4
    ravenID     = AddUpgrade(raceID, "raven", 4, 16, 1, .energy=300.0,
                             .cooldown=120.0, .accumulated=true, .cost_crystals=50);

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

    GetConfigFloatArray("radius", g_EmpRadius, sizeof(g_EmpRadius),
                        g_EmpRadius, raceID, empID);

    GetConfigFloatArray("range", g_DetectorRange, sizeof(g_DetectorRange),
                        g_DetectorRange, raceID, detectorID);

    GetConfigFloatArray("range", g_PlagueRange, sizeof(g_PlagueRange),
                        g_PlagueRange, raceID, plagueID);

    GetConfigFloatArray("gravity",  g_LevitationLevels, sizeof(g_LevitationLevels),
                        g_LevitationLevels, raceID, liftersID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "hgrsource"))
        IsHGRSourceAvailable(true);
    else if (StrEqual(name, "ubershield"))
        IsUberShieldAvailable(true);
    else if (StrEqual(name, "ubercharger"))
        IsUberChargerAvailable(true);
    else if (StrEqual(name, "sidewinder"))
        IsSidewinderAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "ubershield"))
        m_UberShieldAvailable = false;
    else if (StrEqual(name, "ubercharger"))
        m_UberChargerAvailable = false;
    else if (StrEqual(name, "hgrsource"))
        m_HGRSourceAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
}

public OnMapStart()
{
    SetupRedGlow();
    SetupBlueGlow();
    SetupBeamSprite();
    SetupHaloSprite();
    SetupSmokeSprite();

    SetupLevitation();

    SetupDeniedSound();

    SetupPlague(g_PlagueSound);

    SetupSound(empWav);
    SetupSound(buildWav);
    SetupSound(deathWav);
    SetupSound(shieldStopWav);
    SetupSound(shieldStartWav);
    SetupSound(shieldActiveWav);
}

public OnMapEnd()
{
    ResetAllClientTimers();
}

public OnClientDisconnect(client)
{
    ResetPlague(client);
    ResetDetected(client);
    ResetDetection(client);
    KillClientTimer(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);
        SetGravity(client,-1.0);
        KillClientTimer(client);
        ResetDetection(client);
        ResetPlague(client);
        ApplyPlayerSettings(client);

        SetEnergyRate(client, -1.0);

        if (m_UberChargerAvailable)
            SetUberCharger(client, false, 0.0);

        if (m_UberShieldAvailable)
            TakeUberShield(client);
    }
    else
    {
        if (g_ravenRace < 0)
            g_ravenRace = FindRace("raven");

        if (oldrace == g_ravenRace &&
            GetCooldownExpireTime(client, raceID, ravenID) <= 0.0)
        {
            CreateCooldown(client, raceID, ravenID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
    return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        new reactor_level = GetUpgradeLevel(client,raceID,reactorID);
        SetEnergyRate(client, (reactor_level > 0) ? float(reactor_level) : -1.0);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new lifters_level = GetUpgradeLevel(client,raceID,liftersID);
        SetLevitation(client, lifters_level, true, g_LevitationLevels);

        new charge_level = GetUpgradeLevel(client,raceID,chargeID);
        if (charge_level > 0)
            SetupUberCharger(client, charge_level);

        new matrix_level=GetUpgradeLevel(client,raceID,matrixID);
        if (matrix_level > 0)
            SetupUberShield(client, matrix_level);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(buildWav,client);
        }

        new detecting_level=GetUpgradeLevel(client,raceID,detectorID);
        if (detecting_level && IsValidClientAlive(client))
        {
            CreateClientTimer(client, 0.5, Detection,
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
        if (upgrade==liftersID)
            SetLevitation(client, new_level, true, g_LevitationLevels);
        else if (upgrade==chargeID)
            SetupUberCharger(client, new_level);
        else if (upgrade==matrixID)
            SetupUberShield(client, new_level);
        else if (upgrade==reactorID)
            SetEnergyRate(client, (new_level > 0) ? float(new_level) : -1.0);
        else if (upgrade==armorID)
        {
            SetupArmor(client, new_level, g_InitialArmor,
                       g_ArmorPercent, g_ArmorName,
                       .upgrade=true);
        }
        else if (upgrade == detectorID)
        {
            if (new_level > 0)
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 0.5, Detection,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
                KillClientTimer(client);
        }
    }
}

public OnItemPurchase(client,item)
{
    if (GetRace(client) == raceID && IsValidClientAlive(client))
    {
        if (g_sockItem < 0)
            g_sockItem = FindShopItem("sock");

        if (item == g_sockItem)
        {
            new lifters_level = GetUpgradeLevel(client,raceID,liftersID);
            SetLevitation(client, lifters_level, true, g_LevitationLevels);
        }
    }
}

public Action:OnDropPlayer(client, target)
{
    if (IsValidClient(target) && GetRace(target) == raceID)
    {
        new lifters_level = GetUpgradeLevel(target,raceID,liftersID);
        SetLevitation(target, lifters_level, true, g_LevitationLevels);
    }
    return Plugin_Continue;
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 4: // Raven
            {
                new raven_level=GetUpgradeLevel(client,race,ravenID);
                if (raven_level > 0)
                    BuildRaven(client);
            }
            case 3: // Irradiate
            {
                new plague_level=GetUpgradeLevel(client,race,plagueID);
                if (plague_level > 0)
                {
                    Plague(client, raceID, plagueID, plague_level,
                           UltimatePlague|ContagiousPlague|IrradiatePlague,
                           true, g_PlagueRange, g_PlagueSound, g_PlagueShort);
                }
                else
                {
                    new raven_level=GetUpgradeLevel(client,race,ravenID);
                    if (raven_level > 0)
                        BuildRaven(client);
                }
            }
            case 2: // EMP
            {
                new emp_level=GetUpgradeLevel(client,race,empID);
                if (emp_level > 0)
                    EMPShockWave(client, emp_level);
                else
                {
                    new plague_level=GetUpgradeLevel(client,race,plagueID);
                    if (plague_level > 0)
                    {
                        Plague(client, raceID, plagueID, plague_level,
                               UltimatePlague|ContagiousPlague|IrradiatePlague,
                               true, g_PlagueRange, g_PlagueSound, g_PlagueShort);
                    }
                    else
                    {
                        new raven_level=GetUpgradeLevel(client,race,ravenID);
                        if (raven_level > 0)
                            BuildRaven(client);
                    }
                }
            }
            default:
            {
                new matrix_level=GetUpgradeLevel(client,race,matrixID);
                if (matrix_level > 0)
                    DefensiveMatrix(client, matrix_level);
                else
                {
                    new plague_level=GetUpgradeLevel(client,race,plagueID);
                    if (plague_level > 0)
                    {
                        Plague(client, raceID, plagueID, plague_level,
                               UltimatePlague|ContagiousPlague|IrradiatePlague,
                               true, g_PlagueRange, g_PlagueSound, g_PlagueShort);
                    }
                    else
                    {
                        new emp_level=GetUpgradeLevel(client,race,empID);
                        if (emp_level > 0)
                            EMPShockWave(client, emp_level);
                        else
                        {
                            new raven_level=GetUpgradeLevel(client,race,ravenID);
                            if (raven_level > 0)
                                BuildRaven(client);
                        }
                    }
                }
            }
        }
    }
}

DefensiveMatrix(client, matrix_level)
{
    decl String:upgradeName[64];
    GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);

    if (!m_UberShieldAvailable)
    {
        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsMole(client))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (m_HGRSourceAvailable && IsGrabbed(client))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseWhileHeld", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GameType == tf2 && TF2_HasTheFlag(client))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, matrixID, false))
    {
        new Float:duration = float(matrix_level) * 3.0;
        UberShieldTarget(client, duration, GetShieldFlags(matrix_level));
        DisplayMessage(client,Display_Ultimate,"%t", "Invoked", upgradeName);
        CreateCooldown(client, raceID, matrixID);
    }
}

public Action:OnDeployUberShield(client, target)
{
    if (GetRace(client) == raceID)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GameType == tf2 && TF2_HasTheFlag(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && GameType == tf2 && TF2_HasTheFlag(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (m_HGRSourceAvailable && IsGrabbed(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWhileHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && m_HGRSourceAvailable && IsGrabbed(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, matrixID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnSomeoneBeingHeld", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (!CanInvokeUpgrade(client, raceID, matrixID))
            return Plugin_Stop;
    }
    return Plugin_Continue;
}

EMPShockWave(client, emp_level)
{
    if (GetRestriction(client,Restriction_NoUltimates) ||
        GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, empID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, empID))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        new Float:radius = g_EmpRadius[emp_level];
        new Float:targetLoc[3];
        TraceAimPosition(client, targetLoc, true);

        PrepareAndEmitSoundToAll(empWav,client, .origin=targetLoc);

        new team = GetClientTeam(client);
        new beamColor[4];
        if (team==2)
        {
            beamColor[0]=255;beamColor[1]=0;beamColor[2]=0;beamColor[3]=255;
        }
        else
        {
            beamColor[0]=0;beamColor[1]=0;beamColor[2]=255;beamColor[3]=255;
        }

        new b_count=0;
        new alt_count=0;
        new list[MaxClients+1];
        new alt_list[MaxClients+1];
        SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

        if (b_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, 0.1, radius, BeamSprite(), g_beamSprite,
                                  1, 1, 0.5, 4.0, 10.0, beamColor, 100, 0);
            TE_Send(list, b_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, 0.1, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 0.75, 4.0, 10.0, beamColor, 100, 0);
            TE_Send(list, b_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, 0.1, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 1.0, 4.0, 10.0, beamColor, 100, 0);
            TE_Send(list, b_count, 0.0);
        }

        if (alt_count > 0)
        {
            TE_SetupBeamRingPoint(targetLoc, radius-10.0, radius, BeamSprite(), g_beamSprite,
                                  1, 1, 0.5, 4.0, 10.0, beamColor, 100, 0);
            TE_Send(alt_list, alt_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, radius-10.0, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 0.75, 4.0, 10.0, beamColor, 100, 0);
            TE_Send(alt_list, alt_count, 0.0);

            TE_SetupBeamRingPoint(targetLoc, radius-10.0, radius, g_beamSprite, g_beamSprite,
                                  1, 1, 1.0, 4.0, 10.0, beamColor, 100, 0);
            TE_Send(alt_list, alt_count, 0.0);
        }

        new count=0;
        for(new index=1;index<=MaxClients;index++)
        {
            if (index != client && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if ((GetAttribute(index,Attribute_IsMechanical) ||
                     GetAttribute(index,Attribute_IsRobotic) ||
                     GetAttribute(index,Attribute_IsEnergy)) &&
                    !GetImmunity(index,Immunity_Ultimates) &&
                    !IsInvulnerable(index))
                {
                    new Float:indexLoc[3];
                    GetClientAbsOrigin(index,indexLoc);

                    if (IsPointInRange(targetLoc,indexLoc,radius) &&
                        TraceTargetIndex(client, index, targetLoc, indexLoc))
                    {
                        count++;
                        SetEnergy(index, 0.0);
                        if (HasShields(index))
                            SetArmorAmount(index, 0);

                        TF2_RemovePlayerDisguise(index);

                        new Float:meter = TF2_GetEnergyDrinkMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetEnergyDrinkMeter(index, 0.0);

                        meter = TF2_GetChargeMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetChargeMeter(index, 0.0);

                        meter = TF2_GetRageMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetRageMeter(index, 0.0);

                        meter = TF2_GetHypeMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetHypeMeter(index, 0.0);

                        meter = TF2_GetCloakMeter(index);
                        if (meter > 0.0 && meter <= 100.0)
                            TF2_SetCloakMeter(index, 0.0);

                        if (TF2_IsPlayerCloaked(index))
                            SetEntPropFloat(index, Prop_Send, "m_flInvisChangeCompleteTime", GetGameTime() + 1.0);
                    }
                }
            }
        }

        new obj_count=0;
        if (GameType == tf2)
        {
            new Float:pos[3];
            new maxents = GetMaxEntities();
            for (new ent = MaxClients; ent < maxents; ent++)
            {
                if (IsValidEdict(ent) && IsValidEntity(ent))
                {
                    if (TF2_GetExtObjectType(ent) != TFExtObject_Unknown)
                    {
                        if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team &&
                            !GetEntProp(ent, Prop_Send, "m_bDisabled"))
                        {
                            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
                            if (IsPointInRange(targetLoc,pos,radius) &&
                                TraceTargetEntity(client, ent, targetLoc, pos))
                            {
                                obj_count++;
                                SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
                                CreateTimer(5.0, EnableObject, EntIndexToEntRef(ent));
                            }
                        }
                    }
                }
            }
        }

        if (count > 0 || obj_count > 0)
        {
            DisplayMessage(client,Display_Ultimate, "%t",
                           "EMPDisrupted", count, obj_count);
        }
        else
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, empID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client,Display_Ultimate, "%t",
                           "WithoutEffect", upgradeName);
        }

        CreateCooldown(client, raceID, empID);
    }
}

BuildRaven(client)
{
    if (g_ravenRace < 0)
        g_ravenRace = FindRace("raven");

    if (g_ravenRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, ravenID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Terran Raven race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromBuildingRaven");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (HasCooldownExpired(client, raceID, ravenID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_ravenRace, true, false, true);
    }
}

public Action:EnableObject(Handle:timer, any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent) && IsValidEdict(ent))
    {
        if (!GetEntProp(ent, Prop_Send, "m_bHasSapper"))
        {
            if (GetEntProp(ent, Prop_Send, "m_bDisabled"))
                SetEntProp(ent, Prop_Send, "m_bDisabled", 0);
        }
    }
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        PrepareAndEmitSoundToAll(buildWav,client);

        new reactor_level = GetUpgradeLevel(client,raceID,reactorID);
        SetEnergyRate(client, (reactor_level > 0) ? float(reactor_level) : -1.0);

        new armor_level = GetUpgradeLevel(client,raceID,armorID);
        SetupArmor(client, armor_level, g_InitialArmor,
                   g_ArmorPercent, g_ArmorName);

        new lifters_level = GetUpgradeLevel(client,raceID,liftersID);
        SetLevitation(client, lifters_level, true, g_LevitationLevels);
        
        new charge_level = GetUpgradeLevel(client,raceID,chargeID);
        if (charge_level > 0)
            SetupUberCharger(client, charge_level);

        new matrix_level=GetUpgradeLevel(client,raceID,matrixID);
        if (matrix_level > 0)
            SetupUberShield(client, matrix_level);

        new detecting_level=GetUpgradeLevel(client,raceID,detectorID);
        if (detecting_level > 0)
        {
            CreateClientTimer(client, 0.5, Detection,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    KillClientTimer(victim_index);
    ResetDetected(victim_index);

    if (victim_race == raceID)
    {
        PrepareAndEmitSoundToAll(deathWav,victim_index);
        ResetDetection(victim_index);
    }
    else
    {
        if (g_ravenRace < 0)
            g_ravenRace = FindRace("raven");

        if (victim_race == g_ravenRace &&
            GetCooldownExpireTime(victim_index, raceID, ravenID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, ravenID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

public EventRoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new index=1;index<=MaxClients;index++)
    {
        if (IsClientInGame(index))
        {
            if (GetRace(index) == raceID)
            {
                SetVisibility(index, NormalVisibility);
            }
        }
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

SetupUberShield(client, level)
{
    if (m_UberShieldAvailable)
    {
        if (level > 0)
        {
            new num = level * 3;
            GiveUberShield(client, num, num,
                           GetShieldFlags(level));
        }
        else
            TakeUberShield(client);
    }
}

ShieldFlags:GetShieldFlags(level)
{
    new ShieldFlags:flags = Shield_Target_Self  | Shield_Reload_Self |
                            Shield_With_Medigun | Shield_UseAlternateSounds;
    switch (level)
    {
        case 2: flags |= Shield_Target_Team;

        case 3: flags |= Shield_Target_Team | Shield_Team_Specific |
                         Shield_Reload_Team_Specific;

        case 4: flags |= Shield_Target_Team | Shield_Team_Specific |
                         Shield_Mobile | Shield_Reload_Team_Specific;
    }

    if (level >= 3)
        flags |= Shield_Reload_Location | Shield_Reload_Immobilize;

    return flags;
}

public Action:Detection(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID)
        {
            new detecting_level=GetUpgradeLevel(client,raceID,detectorID);
            if (detecting_level > 0 &&
                !GetRestriction(client, Restriction_NoUpgrades) ||
                !GetRestriction(client, Restriction_Stunned))
            {
                new bool:detect;
                new Float:indexLoc[3];
                new Float:clientLoc[3];
                GetClientAbsOrigin(client, clientLoc);
                clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

                decl String:upgradeName[64];
                GetUpgradeName(raceID, detectorID, upgradeName, sizeof(upgradeName), client);

                new count=0;
                new alt_count=0;
                new list[MaxClients+1];
                new alt_list[MaxClients+1];
                new team = GetClientTeam(client);
                new Float:detecting_range = g_DetectorRange[detecting_level];
                for (new index=1;index<=MaxClients;index++)
                {
                    if (index != client && IsClientInGame(index))
                    {
                        if (GetClientTeam(index) == team)
                        {
                            if (!GetSetting(index, Disable_Beacons) &&
                                !GetSetting(index, Remove_Queasiness))
                            {
                                if (GetSetting(index, Reduce_Queasiness))
                                    alt_list[alt_count++] = index;
                                else
                                    list[count++] = index;
                            }
                        }
                        else
                        {
                            detect = IsPlayerAlive(index);
                            if (detect)
                            {
                                GetClientAbsOrigin(index, indexLoc);
                                detect = IsPointInRange(clientLoc,indexLoc,detecting_range) &&
                                         TraceTargetIndex(client, index, clientLoc, indexLoc);
                            }

                            if (detect)
                            {
                                new bool:uncloaked = false;
                                if (GameType == tf2 &&
                                    !GetImmunity(index,Immunity_Uncloaking) &&
                                    TF2_GetPlayerClass(index) == TFClass_Spy)
                                {
                                    //TF2_RemovePlayerDisguise(index);
                                    TF2_RemoveCondition(index, TFCond_Cloaked);

                                    new Float:cloakMeter = TF2_GetCloakMeter(index);
                                    if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                        TF2_SetCloakMeter(index, 0.0);

                                    uncloaked = true;
                                    HudMessage(index, "%t", "UncloakedHud");
                                    DisplayMessage(index, Display_Enemy_Message, "%t",
                                                   "HasUncloaked", client, upgradeName);
                                }

                                if (!GetImmunity(index,Immunity_Detection))
                                {
                                    SetOverrideVisiblity(index, 255);
                                    if (m_SidewinderAvailable)
                                    {
                                        SidewinderDetectClient(index, true);
                                        HudMessage(index, "%t", "DetectedHud");
                                    }

                                    if (!m_Detected[client][index])
                                    {
                                        m_Detected[client][index] = true;
                                        ApplyPlayerSettings(index);
                                    }

                                    if (!uncloaked)
                                    {
                                        HudMessage(index, "%t", "DetectedHud");
                                        DisplayMessage(index, Display_Enemy_Message, "%t",
                                                       "HasDetected", client, upgradeName);
                                    }
                                }
                            }
                            else // undetect
                            {
                                SetOverrideVisiblity(index, -1);
                                if (m_SidewinderAvailable)
                                    SidewinderDetectClient(index, false);

                                if (m_Detected[client][index])
                                {
                                    m_Detected[client][index] = false;
                                    ApplyPlayerSettings(index);

                                    decl String:message[64];
                                    GetHudMessage(index, message, sizeof(message));

                                    decl String:detected[64];
                                    Format(message, sizeof(message), "%T", "DetectedHud", index);
                                    ReplaceString(message, sizeof(message), "*", "");
                                    ReplaceString(message, sizeof(message), " ", "");

                                    decl String:uncloaked[64];
                                    Format(message, sizeof(message), "%T", "UncloakedHud", index);
                                    ReplaceString(message, sizeof(message), "*", "");
                                    ReplaceString(message, sizeof(message), " ", "");

                                    if (StrContains(message, detected) != -1 ||
                                        StrContains(message, uncloaked) != -1)
                                    {
                                        ClearHud(index);
                                    }
                                }
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

                static const detectColor[4] = {202, 225, 255, 255};
                clientLoc[2] -= 50.0; // Adjust position back to the feet.

                if (count > 0)
                {
                    TE_SetupBeamRingPoint(clientLoc, 10.0, detecting_range, BeamSprite(), HaloSprite(),
                                          0, 10, 0.6, 10.0, 0.5, detectColor, 10, 0);

                    TE_Send(list, count, 0.0);
                }

                if (alt_count > 0)
                {
                    TE_SetupBeamRingPoint(clientLoc, detecting_range-10.0, detecting_range, BeamSprite(), HaloSprite(),
                                          0, 10, 0.6, 10.0, 0.5, detectColor, 10, 0);

                    TE_Send(alt_list, alt_count, 0.0);
                }
            }
            else
                ResetDetection(client);
        }
    }
    return Plugin_Continue;
}

ResetDetection(client)
{
    for (new index=1;index<=MaxClients;index++)
    {
        if (IsClientInGame(index))
        {
            SetOverrideVisiblity(index, -1, m_Detected[client][index]);
            if (m_SidewinderAvailable)
                SidewinderDetectClient(index, false);
        }

        if (m_Detected[client][index])
        {
            m_Detected[client][index] = false;

            decl String:message[64];
            GetHudMessage(index, message, sizeof(message));

            decl String:detected[64];
            Format(message, sizeof(message), "%T", "DetectedHud", index);
            ReplaceString(message, sizeof(message), "*", "");
            ReplaceString(message, sizeof(message), " ", "");

            decl String:uncloaked[64];
            Format(message, sizeof(message), "%T", "UncloakedHud", index);
            ReplaceString(message, sizeof(message), "*", "");
            ReplaceString(message, sizeof(message), " ", "");

            if (StrContains(message, detected) != -1 ||
                StrContains(message, uncloaked) != -1)
            {
                ClearHud(index);
            }
        }
    }
}

ResetDetected(index)
{
    SetOverrideVisiblity(index, -1);
    if (m_SidewinderAvailable)
        SidewinderDetectClient(index, false);

    for (new client=1;client<=MaxClients;client++)
    {
        if (m_Detected[client][index])
        {
            m_Detected[client][index] = false;

            decl String:message[64];
            GetHudMessage(index, message, sizeof(message));

            decl String:detected[64];
            Format(message, sizeof(message), "%T", "DetectedHud", index);
            ReplaceString(message, sizeof(message), "*", "");
            ReplaceString(message, sizeof(message), " ", "");

            decl String:uncloaked[64];
            Format(message, sizeof(message), "%T", "UncloakedHud", index);
            ReplaceString(message, sizeof(message), "*", "");
            ReplaceString(message, sizeof(message), " ", "");

            if (StrContains(message, detected) != -1 ||
                StrContains(message, uncloaked) != -1)
            {
                ClearHud(index);
            }
        }
    }
}
