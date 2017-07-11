/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranGhost.sp
 * Description: The Terran Ghost race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <entlimit>
#include <particle>
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
#include <sidewinder>
#include <ubershield>
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/ShopItems"
#include "sc/clienttimer"
#include "sc/maxhealth"
#include "sc/Detector"
#include "sc/freeze"
#include "sc/cloak"
#include "sc/bunker"
#include "sc/sounds"

#include "effect/Fade"
#include "effect/Shake"
#include "effect/Smoke"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Explosion"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/PhysCannonGlow"
#include "effect/SendEffects"
#include "effect/FlashScreen"

#define SetupWhiteSprite() SetupModel(g_whiteModel, g_whiteSprite)
#define WhiteSprite()      PrepareModel(g_whiteModel, g_whiteSprite)

// Following are model indexes for temp entities
new g_whiteSprite;

stock const String:g_whiteModel[]   = "materials/sprites/white.vmt";

new const String:readyWav[]         = "sc/tadupd07.wav";
new const String:targetWav[]        = "sc/tghlas00.wav";
new const String:launchWav[]        = "sc/tnsfir00.wav";
new const String:detectedWav[]      = "sc/tadupd04.wav";
new const String:lockdownWav[]      = "sc/tghlkd00.wav";
//new const String:airRaidWav[]     = "sc/air_raid.wav";

new const String:explosionsWav[][]  = { "items/cart_explode.wav",
                                        "ambient/explosions/explode_8.wav",
                                        "sc/tnshit00.wav",
                                        "sc/boom2.wav",
                                        "sc/war01.mp3",
                                        "sc/inferno.wav",
                                        "sc/explosions_sparks.wav",
                                        "sc/usat_bomb.wav" };

new Float:g_InitialArmor[]          = { 0.0 };
new Float:g_ArmorPercent[][2]       = { {0.0, 0.0} };

new Float:g_BunkerPercent[]         = { 0.00, 0.10, 0.20, 0.30, 0.40 };

new g_LockdownChance[]              = { 0, 15, 21, 37, 52 };

new Float:g_OcularImplantRange[]    = { 0.0, 300.0, 450.0, 650.0, 800.0 };

new g_NukeDamage[]                  = { 0,   1000,  1500,  2000,   3000   };
new g_NukeMagnitude[]               = { 0,   600,   1000,  1500,   2000   };
new Float:g_NukeRadius[]            = { 0.0, 500.0, 800.0, 1000.0, 1500.0 };

new cfgNuclearEffects               = 10;
new Float:cfgNuclearLaunchTime      = 15.0;
new Float:cfgNuclearLockTime        = 10.0;

new Float:cfgLockdownFactor         = 0.5;
new Float:cfgLockdownMechMult       = 2.0;
new Float:cfgLockdownDuration       = 1.0;

enum NuclearStatus { Ready, Tracking, LaunchInitiated, LockedOn, Exploding};

new raceID, cloakID, lockdownID, detectorID, nukeID, reactorID, bunkerID;
new ultlockdownID, vesselID;

new g_scienceVesselRace = -1;

new m_NuclearDuration[MAXPLAYERS+1];
new Handle:m_NuclearTimer[MAXPLAYERS+1];
new Float:m_NuclearAimPos[MAXPLAYERS+1][3];
new NuclearStatus:m_NuclearLaunchStatus[MAXPLAYERS+1];

new Float:gNuclearParticleTime;
new Float:gLockdownTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Ghost",
    author = "-=|JFH|=-Naris",
    description = "The Terran Ghost race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.detector.phrases.txt");
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.ghost.phrases.txt");

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
        if (!HookEventEx("round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the round_win event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("ghost", 32, 0, 25, 150.0, 1000.0, 1.0,
                             Terran, Biological);

    cfgAllowInvisibility = bool:GetConfigNum("allow_invisibility", cfgAllowInvisibility);
    if (cfgAllowInvisibility)
    {
        cloakID = AddUpgrade(raceID, "cloak", .cost_crystals=0);
    }
    else
    {
        cloakID = AddUpgrade(raceID, "cloak", 0, 0, 1, .desc="%ghost_cloak_noinvis_desc", .cost_crystals=25);
        LogMessage("Reducing Terran Ghost:Personal Cloaking Device due to configuration: sc_allow_invisibility=%d",
                   cfgAllowInvisibility);
    }

    lockdownID  = AddUpgrade(raceID, "lockdown", .energy=2.0, .cost_crystals=40);
    detectorID  = AddUpgrade(raceID, "implants", .cost_crystals=0);
    reactorID   = AddUpgrade(raceID, "reactor", .cost_crystals=25);

    // Ultimate 1
    nukeID      = AddUpgrade(raceID, "nuke", 1, .energy=300.0,
                             .cooldown=60.0, .accumulated=true,
                             .cost_crystals=50);

    // Ultimate 2
    bunkerID    = AddBunkerUpgrade(raceID, 2);

    // Ultimate 3
    ultlockdownID = AddUpgrade(raceID, "ult_lockdown", 3, 18, .energy=100.0,
                               .cooldown=5.0, .cost_crystals=40);

    if (!IsUberShieldAvailable())
    {
        SetUpgradeDisabled(raceID, ultlockdownID, true);
        LogMessage("ubershield is not available");
        LogMessage("Disabling Terran Ghost:Ultimate Lockdown due to ubershield is not available");
    }

    // Ultimate 4
    vesselID = AddUpgrade(raceID, "vessel", 4, 16,1,
                          .energy=200.0, .cooldown=30.0,
                          .accumulated=true, .cost_crystals=50);

    // Set the Sidewinder available flag
    IsSidewinderAvailable();

    // Get Configuration Data
    cfgNuclearLaunchTime = GetConfigFloat("launch_time", cfgNuclearLaunchTime, raceID, nukeID);
    cfgNuclearLockTime = GetConfigFloat("lock_time", cfgNuclearLockTime, raceID, nukeID);
    cfgNuclearEffects = GetConfigNum("effects", cfgNuclearEffects, raceID, nukeID);

    cfgLockdownFactor = GetConfigFloat("factor", cfgLockdownFactor, raceID, lockdownID);
    cfgLockdownMechMult = GetConfigFloat("duration_mech_mult", cfgLockdownMechMult, raceID, lockdownID);
    cfgLockdownDuration = GetConfigFloat("duration", cfgLockdownDuration, raceID, lockdownID);

    GetConfigArray("chance", g_LockdownChance, sizeof(g_LockdownChance),
                   g_LockdownChance, raceID, lockdownID);

    GetConfigFloatArray("bunker_armor", g_BunkerPercent, sizeof(g_BunkerPercent),
                        g_BunkerPercent, raceID, bunkerID);

    GetConfigFloatArray("range", g_OcularImplantRange, sizeof(g_OcularImplantRange),
                        g_OcularImplantRange, raceID, detectorID);

    GetConfigArray("damage", g_NukeDamage, sizeof(g_NukeDamage),
                   g_NukeDamage, raceID, nukeID);

    GetConfigArray("magnitude", g_NukeMagnitude, sizeof(g_NukeMagnitude),
                   g_NukeMagnitude, raceID, nukeID);

    GetConfigFloatArray("radius", g_NukeRadius, sizeof(g_NukeRadius),
                        g_NukeRadius, raceID, nukeID);

}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "ubershield"))
        IsUberShieldAvailable(true);
    else if (StrEqual(name, "sidewinder") && GetGameType() == tf2)
        IsSidewinderAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "ubershield"))
        m_UberShieldAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
}

public OnMapStart()
{
    SetupCloak();
    SetupRedGlow();
    SetupBlueGlow();
    SetupBeamSprite();
    SetupHaloSprite();
    SetupFireSprite();
    SetupFire2Sprite();
    SetupWhiteSprite();
    SetupSmokeSprite();
    SetupBigExplosion();
    SetupPhysCannonGlow();

    //SetupBunker();
    SetupDeniedSound();

    SetupSound(readyWav);
    SetupSound(targetWav);
    SetupSound(launchWav);
    SetupSound(detectedWav);
    SetupSound(lockdownWav);
    //SetupSound(airRaidWav);

    //Don't download explosions[0,1] since they are built in hl2/tf2 sounds
    for (new i = 0; i < sizeof(explosionsWav); i++)
        SetupSound(explosionsWav[i], false, (i > 1));
}

public OnMapEnd()
{
    ResetAllClientTimers();
}

public OnPlayerAuthed(client)
{
    gLockdownTime[client] = 0.0;
    m_NuclearLaunchStatus[client] = Ready;
    m_NuclearTimer[client] = INVALID_HANDLE;
}

public OnClientDisconnect(client)
{
    KillClientTimer(client);
    ResetDetection(client);
    ResetDetected(client);

    new Handle:timer = m_NuclearTimer[client];
    if (timer != INVALID_HANDLE)
    {
        m_NuclearTimer[client] = INVALID_HANDLE;
        KillTimer(timer);
    }
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        ResetArmor(client);
        KillClientTimer(client);
        ResetDetection(client);
        SetInitialEnergy(client, -1.0);
        SetVisibility(client, NormalVisibility);
        ApplyPlayerSettings(client);

        if (m_UberShieldAvailable)
            TakeUberShield(client);

        return Plugin_Handled;
    }
    else
    {
        if (g_scienceVesselRace < 0)
            g_scienceVesselRace = FindRace("vessel");

        if (oldrace == g_scienceVesselRace &&
            GetCooldownExpireTime(client, raceID, vesselID) <= 0.0)
        {
            CreateCooldown(client, raceID, vesselID,
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
        gLockdownTime[client] = 0.0;

        SetupArmor(client, 0, g_InitialArmor, g_ArmorPercent);

        new reactor_level = GetUpgradeLevel(client,raceID,reactorID);
        if (reactor_level > 0)
            SetInitialEnergy(client, float(reactor_level+1)*30.0);

        new cloak_level = GetUpgradeLevel(client,raceID,cloakID);
        AlphaCloak(client, cloak_level, true);

        new ult_level = GetUpgradeLevel(client,raceID,ultlockdownID);
        if (ult_level > 0)
            SetupUberShield(client, ult_level);

        if (IsValidClientAlive(client))
        {
            new detecting_level = GetUpgradeLevel(client,raceID,detectorID);
            if (detecting_level > 0)
            {
                CreateClientTimer(client, 0.5, OcularImplants,
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
        if (upgrade == cloakID)
            AlphaCloak(client, new_level, true);
        else if (upgrade==reactorID)
            SetInitialEnergy(client, float(new_level+1)*30.0);
        else if (upgrade==reactorID)
            SetupUberShield(client, new_level);
        else if (upgrade == detectorID)
        {
            if (new_level > 0)
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 0.5, OcularImplants,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
            {
                KillClientTimer(client);
                ResetDetection(client);
            }
        }
    }
}

public OnItemPurchase(client,item)
{
    if (GetRace(client) == raceID && IsValidClientAlive(client))
    {
        if (g_cloakItem < 0)
            g_cloakItem = FindShopItem("cloak");

        if (item == g_cloakItem)
        {
            new cloak_level=GetUpgradeLevel(client,raceID,cloakID);
            AlphaCloak(client, cloak_level, true);
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
                new vessel_level=GetUpgradeLevel(client,race,vesselID);
                if (vessel_level > 0)
                {
                    if (!pressed)
                        BuildScienceVessel(client);
                }
            }
            case 3:
            {
                new ult_level=GetUpgradeLevel(client,race,ultlockdownID);
                if (ult_level > 0)
                {
                    if (pressed)
                        UltimateLockdown(client, ult_level);
                }
                else
                {
                    new vessel_level=GetUpgradeLevel(client,race,vesselID);
                    if (vessel_level > 0)
                    {
                        if (!pressed)
                            BuildScienceVessel(client);
                    }
                }
            }
            case 2:
            {
                new bunker_level = GetUpgradeLevel(client,race,bunkerID);
                if (bunker_level > 0)
                {
                    if (pressed)
                    {
                        new armor = RoundToNearest(float(GetPlayerMaxHealth(client))
                                                   * g_BunkerPercent[bunker_level]);

                        EnterBunker(client, armor, raceID, bunkerID);
                    }
                }
                else
                {
                    new ult_level=GetUpgradeLevel(client,race,ultlockdownID);
                    if (ult_level > 0)
                    {
                        if (pressed)
                            UltimateLockdown(client, ult_level);
                    }
                    else
                    {
                        new vessel_level=GetUpgradeLevel(client,race,vesselID);
                        if (vessel_level > 0)
                        {
                            if (!pressed)
                                BuildScienceVessel(client);
                        }
                    }
                }
            }
            default:
            {
                new ult_level=GetUpgradeLevel(client,race,nukeID);
                if (ult_level > 0)
                {
                    if (m_NuclearLaunchStatus[client] == Tracking)
                        LaunchNuclearDevice(client);
                    else if (pressed)
                        TargetNuclearDevice(client);
                }
                else
                {
                    new lockdown_level=GetUpgradeLevel(client,race,ultlockdownID);
                    if (lockdown_level > 0)
                    {
                        if (pressed)
                            UltimateLockdown(client, lockdown_level);
                    }
                    else
                    {
                        new bunker_level = GetUpgradeLevel(client,race,bunkerID);
                        if (bunker_level > 0)
                        {
                            if (pressed)
                            {
                                new armor = RoundToNearest(float(GetPlayerMaxHealth(client))
                                                           * g_BunkerPercent[bunker_level]);

                                EnterBunker(client, armor, raceID, bunkerID);
                            }
                        }
                        else
                        {
                            new vessel_level=GetUpgradeLevel(client,race,vesselID);
                            if (vessel_level > 0)
                            {
                                if (!pressed)
                                    BuildScienceVessel(client);
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
        gLockdownTime[client] = 0.0;

        SetupArmor(client, 0, g_InitialArmor, g_ArmorPercent);

        new cloak_level=GetUpgradeLevel(client,raceID,cloakID);
        AlphaCloak(client, cloak_level, true);

        new ult_level=GetUpgradeLevel(client,raceID,ultlockdownID);
        if (ult_level > 0)
            SetupUberShield(client, ult_level);

        new reactor_level = GetUpgradeLevel(client,raceID,reactorID);
        if (reactor_level > 0)
        {
            new Float:initial = float(reactor_level+1) * 30.0;
            SetInitialEnergy(client, initial);
            if (GetEnergy(client, true) < initial)
                SetEnergy(client, initial, true);
        }

        new detecting_level=GetUpgradeLevel(client,raceID,detectorID);
        if (detecting_level > 0)
        {
            CreateClientTimer(client, 0.5, OcularImplants,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    ResetDetected(victim_index);

    if (victim_race == raceID)
    {
        KillClientTimer(victim_index);
        ResetDetection(victim_index);

        SetVisibility(victim_index, NormalVisibility);
        SetOverrideSpeed(victim_index, -1.0);

        new NuclearStatus:nukeStatus = m_NuclearLaunchStatus[victim_index];
        if (nukeStatus >= Tracking && nukeStatus <= LaunchInitiated)
        {
            m_NuclearLaunchStatus[victim_index] = Ready;
            CreateCooldown(victim_index, raceID, nukeID,
                           .type=Cooldown_CreateNotify);
        }
    }
    else
    {
        if (g_scienceVesselRace < 0)
            g_scienceVesselRace = FindRace("vessel");

        if (victim_race == g_scienceVesselRace &&
            GetCooldownExpireTime(victim_index, raceID, vesselID) <= 0.0)
        {
            CreateCooldown(victim_index, raceID, vesselID,
                           .type=Cooldown_CreateNotify
                                |Cooldown_AlwaysNotify);
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && IsClient(attacker_index) &&
        attacker_index != victim_index)
    {
        if (victim_race == raceID && IsValidClientAlive(attacker_index))
            Lockdown(attacker_index, victim_index);

        if (attacker_race == raceID && IsClient(victim_index))
        {
            if (Lockdown(victim_index, attacker_index))
                return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if (assister_race == raceID && IsClient(victim_index))
    {
        if (Lockdown(victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
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
                SetOverrideSpeed(index, -1.0);
            }
        }
    }
}

bool:Lockdown(victim_index, index)
{
    if (m_NuclearLaunchStatus[victim_index] != LaunchInitiated &&
        !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned) &&
        !GetImmunity(victim_index,Immunity_MotionTaking) &&
        !GetImmunity(victim_index,Immunity_Upgrades) &&
        !GetImmunity(victim_index,Immunity_Restore) &&
        !IsBurrowed(victim_index))
    {
        new lockdown_level=GetUpgradeLevel(index, raceID, lockdownID);
        if (lockdown_level > 0)
        {
            new Float:lastTime = gLockdownTime[victim_index];
            if (lastTime == 0.0 || (GetGameTime() - lastTime > 2.0))
            {
                new Float:duration = cfgLockdownDuration;
                new chance = g_LockdownChance[lockdown_level];

                // Lockdown effects Mechanical and Robotic units differently.
                if (GetAttribute(index,Attribute_IsMechanical) ||
                    GetAttribute(index,Attribute_IsRobotic))
                {
                    chance += chance / 2; // Increase chance 50%
                    duration *= cfgLockdownMechMult;
                }

                if (GetRandomInt(1,100)<=chance)
                {
                    if (CanInvokeUpgrade(index, raceID, lockdownID, .notify=false))
                    {
                        new Float:Origin[3];
                        GetClientAbsOrigin(victim_index, Origin);
                        TE_SetupGlowSprite(Origin, PhysCannonGlow(), 1.0, 2.3, 90);
                        TE_SendEffectToAll();

                        PrepareAndEmitSoundToAll(lockdownWav,victim_index);
                        
                        DisplayMessage(victim_index, Display_Enemy_Ultimate,
                                       "%t","LockedDown", index);

                        gLockdownTime[victim_index] = GetGameTime();

                        if (cfgLockdownFactor > 0.0)
                        {
                            SetOverrideSpeed(victim_index, cfgLockdownFactor);
                            SetRestriction(victim_index, Restriction_Grounded, true);
                            CreateTimer(duration, RestoreSpeed, GetClientUserId(victim_index),
                                        TIMER_FLAG_NO_MAPCHANGE);
                        }
                        else
                        {
                            FreezeEntity(victim_index);
                            CreateTimer(duration, UnfreezePlayer,
                                        GetClientUserId(victim_index),
                                        TIMER_FLAG_NO_MAPCHANGE);
                        }
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

public Action:RestoreSpeed(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        SetRestriction(client, Restriction_Grounded, false);
        SetOverrideSpeed(client,-1.0);
    }
    return Plugin_Stop;
}

public Action:OcularImplants(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID)
        {
            new detecting_level = GetUpgradeLevel(client,raceID,detectorID);
            if (detecting_level <= 0 || GetRestriction(client, Restriction_NoUpgrades) ||
                GetRestriction(client, Restriction_Stunned))
            {
                ResetDetection(client);
            }
            else
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
                new Float:detecting_range = g_OcularImplantRange[detecting_level];
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
                                    TF2_RemoveCondition(client,TFCond_Cloaked);

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

                                        if (!uncloaked)
                                        {
                                            HudMessage(index, "%t", "DetectedHud");
                                            DisplayMessage(index, Display_Enemy_Message, "%t",
                                                           "HasDetected", client, upgradeName);
                                        }
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
                                    ClearDetectedHud(index);
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
        }
    }
    return Plugin_Continue;
}

TargetNuclearDevice(client)
{
    if (m_NuclearLaunchStatus[client] > Tracking)
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "NuclearLaunchInProcess");
    }
    else if (IsMole(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);

        decl String:upgradeName[64];
        GetUpgradeName(raceID, nukeID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromLaunchingNuke");
    }
    else
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerSlowed(client) ||
                TF2_IsPlayerZoomed(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
            else if (TF2_IsPlayerTaunting(client) ||
                     TF2_IsPlayerDazed(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
            //case TFClass_Scout:
            else if (TF2_IsPlayerBonked(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
            //case TFClass_Spy:
            else if (TF2_IsPlayerCloaked(client) ||
                     TF2_IsPlayerDeadRingered(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
            else if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        PrepareAndEmitSoundToAll(targetWav,client);

        if (CanInvokeUpgrade(client, raceID, nukeID))
        {
            m_NuclearLaunchStatus[client] = Tracking;
            m_NuclearTimer[client] = CreateTimer(0.2,TrackNuclearTarget,GetClientUserId(client),
                                                 TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

            TriggerTimer(m_NuclearTimer[client], true);
        }
    }
}

LaunchNuclearDevice(client)
{
    new Handle:timer = m_NuclearTimer[client];
    if (timer != INVALID_HANDLE)
    {
        m_NuclearTimer[client] = INVALID_HANDLE;
        KillTimer(timer);
    }

    if (GameType == tf2)
    {
        if (TF2_IsPlayerSlowed(client) ||
            TF2_IsPlayerZoomed(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            m_NuclearLaunchStatus[client] = Ready;
            return;
        }
        else if (TF2_IsPlayerTaunting(client) ||
                 TF2_IsPlayerDazed(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            m_NuclearLaunchStatus[client] = Ready;
            return;
        }
        //case TFClass_Scout:
        else if (TF2_IsPlayerBonked(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            m_NuclearLaunchStatus[client] = Ready;
            return;
        }
        //case TFClass_Spy:
        else if (TF2_IsPlayerCloaked(client) ||
                 TF2_IsPlayerDeadRingered(client))
        {
            TF2_RemoveCondition(client,TFCond_Cloaked);
            new Float:cloakMeter = TF2_GetCloakMeter(client);
            if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                TF2_SetCloakMeter(client, 0.0);
        }
        else if (TF2_IsPlayerDisguised(client))
            TF2_RemovePlayerDisguise(client);
    }

    m_NuclearLaunchStatus[client]=LaunchInitiated;

    PrepareAndEmitSoundToAll(detectedWav,SOUND_FROM_PLAYER);

    SetVisibility(client, BasicVisibility, 255, 0.1, 0.1,
                  RENDER_TRANSCOLOR, RENDERFX_NONE);

    if (m_SidewinderAvailable)
        SidewinderCloakClient(client, true);

    SetOverrideSpeed(client, 0.0);
    ApplyPlayerSettings(client);

    DisplayMessage(client,Display_Ultimate, "%t", "NukeLaunched", cfgNuclearLaunchTime);
    m_NuclearTimer[client] = CreateTimer(cfgNuclearLaunchTime,NuclearLockOn,GetClientUserId(client),
                                         TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TrackNuclearTarget(Handle:timer,any:userid)
{
    new index = GetClientOfUserId(userid);
    if (IsValidClientAlive(index) &&
        m_NuclearLaunchStatus[index] == Tracking)
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerSlowed(index) ||
                TF2_IsPlayerZoomed(index))
            {
                PrepareAndEmitSoundToClient(index,deniedWav);
                m_NuclearLaunchStatus[index] = Ready;
                m_NuclearTimer[index] = INVALID_HANDLE;
                return Plugin_Stop;
            }
            else if (TF2_IsPlayerTaunting(index) ||
                     TF2_IsPlayerDazed(index))
            {
                PrepareAndEmitSoundToClient(index,deniedWav);
                m_NuclearLaunchStatus[index] = Ready;
                m_NuclearTimer[index] = INVALID_HANDLE;
                return Plugin_Stop;
            }
            //case TFClass_Scout:
            else if (TF2_IsPlayerBonked(index))
            {
                PrepareAndEmitSoundToClient(index,deniedWav);
                m_NuclearLaunchStatus[index] = Ready;
                m_NuclearTimer[index] = INVALID_HANDLE;
                return Plugin_Stop;
            }
            //case TFClass_Spy:
            else if (TF2_IsPlayerCloaked(index) ||
                     TF2_IsPlayerDeadRingered(index))
            {
                TF2_RemoveCondition(index,TFCond_Cloaked);
                new Float:cloakMeter = TF2_GetCloakMeter(index);
                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                    TF2_SetCloakMeter(index, 0.0);
            }
            else if (TF2_IsPlayerDisguised(index))
                TF2_RemovePlayerDisguise(index);
        }

        new Float:indexLoc[3], Float:targetLoc[3];
        GetClientEyePosition(index, indexLoc);
        TraceAimPosition(index, targetLoc, true);

        new color[4] = { 0, 0, 0, 150 };
        new team = GetClientTeam(index);
        if (team == 3)
            color[2] = 255; // Blue
        else
            color[0] = 255; // Red

        indexLoc[2] -= 30;
        TE_SetupBeamPoints(indexLoc, targetLoc, BeamSprite(), 0,
                           0, 0, 0.2, 3.0, 3.0, 1, 0.0, color, 0);

        TE_SendToClient(index);
        m_NuclearAimPos[index] = targetLoc;
        return Plugin_Continue;
    }
    else
    {
        m_NuclearTimer[index] = INVALID_HANDLE;
        return Plugin_Stop;
    }
}

public Action:NuclearLockOn(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        if (m_NuclearLaunchStatus[client] == LaunchInitiated)
        {
            m_NuclearLaunchStatus[client] = LockedOn;

            // Reset speed and cloak.
            SetOverrideSpeed(client, -1.0);
            AlphaCloak(client, GetUpgradeLevel(client,raceID,cloakID), true);

            PrepareAndEmitSoundToAll(launchWav,SOUND_FROM_PLAYER);

            DisplayMessage(client,Display_Ultimate, "%t",
                           "NukeLockedOn", cfgNuclearLockTime);

            /*
            if (GetRandomInt(1,10) > 5)
            {
               PrepareAndEmitSoundToAll(airRaidWav,SOUND_FROM_WORLD,
                                        .origin=m_NuclearAimPos[client]);
            }
            */

            new Handle:NuclearPack;
            m_NuclearTimer[client] = CreateDataTimer(cfgNuclearLockTime,NuclearImpact,NuclearPack,
                                                     TIMER_FLAG_NO_MAPCHANGE);
            WritePackCell(NuclearPack, userid);
            WritePackCell(NuclearPack, GetUpgradeLevel(client,raceID,nukeID));
        }
        else
        {
            m_NuclearTimer[client] = INVALID_HANDLE;

            decl String:upgradeName[64];
            GetUpgradeName(raceID, nukeID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "WithoutEffect", upgradeName);
            CreateCooldown(client, raceID, nukeID,
                           .type=Cooldown_CreateNotify);
        }
    }
    return Plugin_Stop;
}

public Action:NuclearImpact(Handle:timer,Handle:pack)
{
    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        new userid = ReadPackCell(pack);
        new client = GetClientOfUserId(userid);
        if (client > 0)
        {
            new ult_level=ReadPackCell(pack);
            if (m_NuclearLaunchStatus[client] == LockedOn)
            {
                m_NuclearLaunchStatus[client] = Exploding;
                m_NuclearDuration[client] = ult_level*3;

                new Handle:NuclearPack;
                m_NuclearTimer[client] = CreateDataTimer(0.4, NuclearExplosion, NuclearPack,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                WritePackCell(NuclearPack, userid);
                WritePackCell(NuclearPack, ult_level);
                TriggerTimer(m_NuclearTimer[client], true);
            }
            else
                m_NuclearTimer[client] = INVALID_HANDLE;
        }
    }
    return Plugin_Stop;
}

public Action:NuclearExplosion(Handle:timer,Handle:pack)
{
    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        new userid = ReadPackCell(pack);
        new client = GetClientOfUserId(userid);
        if (client > 0)
        {
            new ult_level=ReadPackCell(pack);
            new iteration = (--m_NuclearDuration[client]);
            if (iteration > 0 && IsClientInGame(client))
            {
                new amt;
                new Float:indexLoc[3];
                new Float:radius = g_NukeRadius[ult_level];
                new damage = g_NukeDamage[ult_level];

                switch (iteration % 8)
                {
                    case 1:
                    {
                        new Float:rorigin[3],sb;
                        for(new i = 1 ;i < 50; ++i)
                        {
                            rorigin[0] = GetRandomFloat(0.0,3000.0);
                            rorigin[1] = GetRandomFloat(0.0,3000.0);
                            rorigin[2] = GetRandomFloat(0.0,2000.0);
                            sb = GetRandomInt(0,2);
                            if(sb == 0)
                                rorigin[0] = rorigin[0] * -1;
                            sb = GetRandomInt(0,2);
                            if(sb == 0)
                                rorigin[1] = rorigin[1] * -1;
                            sb = GetRandomInt(0,2);
                            if(sb == 0)
                                rorigin[2] = rorigin[2] * -1;
                            ExplodeAll(rorigin);
                        }
                    }
                    case 2:
                    {
                        ShakeAllAllowed(0, 14.0, 10.0, 150.0);
                        ExplodeAll(m_NuclearAimPos[client]);
                    }
                    case 3:
                    {
                        ExplodeAll(m_NuclearAimPos[client]);
                    }
                    case 4:
                    {
                        ShakeAllAllowed(0, 14.0, 10.0, 150.0);
                    }
                    case 5:
                    {
                        if (GameType == tf2 && GetMode() != MvM && GetParticleCount() < 25 &&
                            (gNuclearParticleTime == 0.0 || GetGameTime() - gNuclearParticleTime > 1.0))
                        {
                            if (cfgNuclearEffects > 0)
                            {
                                new entities = EntitiesAvailable(200, .message="Reducing Nuke Effects");
                                if (entities > 50)
                                {
                                    new Float:rorigin[3];
                                    rorigin[0] = GetRandomFloat(0.0,3000.0);
                                    rorigin[1] = GetRandomFloat(0.0,3000.0);
                                    rorigin[2] = GetRandomFloat(0.0,2000.0);

                                    gNuclearParticleTime = GetGameTime();

                                    CreateParticle("ExplosionCore_MidAir", 5.0, 0, NoAttach, "", rorigin);
                                    CreateParticle("ExplosionCore_MidAir", 5.0, 0, NoAttach, "", rorigin);
                                    CreateParticle("Explosions_MA_Debris001", 5.0, 0, NoAttach, "", rorigin);

                                    if (cfgNuclearEffects >= 2 && entities > 100)
                                    {
                                        CreateParticle("cinefx_goldrush_embers", 5.0, 0, NoAttach, "", rorigin);
                                        CreateParticle("cinefx_goldrush_debris", 5.0, 0, NoAttach, "", rorigin);
                                        CreateParticle("cinefx_goldrush_initial_smoke", 5.0, 0, NoAttach, "", rorigin);
                                        CreateParticle("cinefx_goldrush_smoke", 10.0, 0, NoAttach, "", rorigin);

                                        if (cfgNuclearEffects >= 3 && entities > 150)
                                        {
                                            CreateParticle("cinefx_goldrush_flames", 10.0, 0, NoAttach, "", rorigin);
                                            CreateParticle("cinefx_goldrush_flash", 10.0, 0, NoAttach, "", rorigin);
                                            CreateParticle("cinefx_goldrush_hugedustup", 10.0, 0, NoAttach, "", rorigin);

                                            if (cfgNuclearEffects >= 4 && entities > 200)
                                            {
                                                CreateParticle("Explosion_Smoke_1", 10.0, 0, NoAttach, "", rorigin);
                                                CreateParticle("cinefx_goldrush_burningdebris", 10.0, 0, NoAttach, "", rorigin);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    default:
                    {
                        TE_SetupExplosion(m_NuclearAimPos[client],
                                          (iteration % 2) ? FireSprite() : BigExplosion(),
                                          100.0,1,0,RoundToNearest(radius),
                                          g_NukeMagnitude[ult_level]);
                        TE_SendEffectToAll();

                        new Float:dir[3];
                        dir[0] = 0.0;
                        dir[1] = 0.0;
                        dir[2] = 2.0;
                        TE_SetupDust(m_NuclearAimPos[client],dir,radius,100.0);
                        TE_SendEffectToAll();

                        if (GameType == tf2 && GetMode() != MvM && GetParticleCount() < 25 &&
                            gNuclearParticleTime == 0.0 || (GetGameTime() - gNuclearParticleTime > 2.0))
                        {
                            new entities = (cfgNuclearEffects > 0) ? EntitiesAvailable(200, .message="Reducing Nuke Effects") : 0;
                            if (cfgNuclearEffects >= 5 && entities > 200)
                            {
                                gNuclearParticleTime = GetGameTime();

                                CreateParticle("cinefx_goldrush_embers", 5.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                CreateParticle("cinefx_goldrush_debris", 5.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                CreateParticle("cinefx_goldrush_initial_smoke", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                CreateParticle("cinefx_goldrush_flash", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);

                                if (cfgNuclearEffects >= 6)
                                {
                                    CreateParticle("Explosion_Smoke_1", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                    CreateParticle("ExplosionCore_MidAir", 5.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                    CreateParticle("Explosions_MA_Debris001", 5.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                    CreateParticle("cinefx_goldrush_burningdebris", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);

                                    if (cfgNuclearEffects >= 7)
                                    {
                                        CreateParticle("cinefx_goldrush_flames", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                        CreateParticle("cinefx_goldrush_smoke", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                        CreateParticle("cinefx_goldrush_hugedustup", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                                    }
                                }
                            }
                            else
                            {
                                CreateParticle("cinefx_goldrush", 10.0, 0, NoAttach, "", m_NuclearAimPos[client]);
                            }
                        }
                    }
                }

                new num = GetRandomInt((GameType == tf2) ? 1 : 0,sizeof(explosionsWav)-1);
                PrepareAndEmitSoundToAll(explosionsWav[num], SOUND_FROM_WORLD,
                                         .origin=m_NuclearAimPos[client]);

                new total = 0;
                new altTotal = 0;
                new clients[MaxClients];
                new altClients[MaxClients];

                new minDmg=iteration;
                new maxDmg=iteration*ult_level;
                for(new index=1;index<=MaxClients;index++)
                {
                    if (IsClientInGame(index) && IsPlayerAlive(index))
                    {
                        new bool:canBlind  = !GetImmunity(index,Immunity_Blindness);

                        new bool:canDamage = (!GetImmunity(index,Immunity_Ultimates) &&
                                              !GetImmunity(index,Immunity_Explosion) &&
                                              !GetImmunity(index,Immunity_HealthTaking) &&
                                              !IsInvulnerable(index));

                        if (canBlind || canDamage)
                        {
                            GetClientAbsOrigin(index, indexLoc);
                            if (TraceTargetIndex(0, index, m_NuclearAimPos[client], indexLoc))
                            {
                                amt = PowerOfRange(m_NuclearAimPos[client],radius,indexLoc,damage,0.5,false);
                                if (canBlind)
                                {
                                    if (!GetSetting(index, Remove_Queasiness) &&
                                        !GetSetting(index, Reduce_Queasiness))
                                    {
                                        clients[total++] = index;
                                    }
                                    else
                                        altClients[altTotal++] = index;
                                }
                            }
                            else if ( canDamage && IsPointInRange(m_NuclearAimPos[client],indexLoc,radius))
                                amt = GetRandomInt(minDmg,maxDmg)-ult_level;
                            else
                                amt = 0;

                            if (canDamage && amt > 0)
                            {
                                FlashScreen(index,RGBA_COLOR_RED);
                                HurtPlayer(index,amt,client,"sc_nuke",
                                           .xp=5+ult_level, .limit=0.0,
                                           .type=DMG_BLAST);
                            }
                        }
                    }
                }

                if (total > 0)
                {
                    static const color[4]={250,250,250,255};
                    Fade(clients, total, 600,600,color,FFADE_IN);
                }

                if (altTotal > 0)
                {
                    static const black[4]={0,0,0,255};
                    Fade(altClients, altTotal, 600,600,black,FFADE_IN);
                }

                new maxents = GetMaxEntities();
                for (new ent = MaxClients; ent < maxents; ent++)
                {
                    if (IsValidEdict(ent) && IsValidEntity(ent))
                    {
                        if (TF2_GetExtObjectType(ent) != TFExtObject_Unknown)
                        {
                            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", indexLoc);
                            new dmg=PowerOfRange(m_NuclearAimPos[client],radius,indexLoc,damage);
                            if (dmg > 0)
                            {
                                if (TraceTargetEntity(client, ent, m_NuclearAimPos[client], indexLoc))
                                {
                                    SetVariantInt(dmg);
                                    AcceptEntityInput(ent, "RemoveHealth", client, client);
                                }
                            }
                        }
                    }
                }
                return Plugin_Continue;
            }
        }

        // End of last explosion iteration, time to quit

        ShakeAll(1, 0.0, 0.0, 0.0);

        if (IsValidClient(client))
        {
            m_NuclearTimer[client] = INVALID_HANDLE;
            DisplayMessage(client, Display_Ultimate,
                           "%t", "NukeExploded");

            m_NuclearLaunchStatus[client] = Ready;
            CreateCooldown(client, raceID, nukeID,
                           .type=Cooldown_CreateNotify);
        }
    }
    return Plugin_Stop;
}

public OnCooldownExpired(client,race,upgrade,bool:expiredByTime)
{
    if (race == raceID && upgrade == nukeID)
    {
        if (IsClientInGame(client))
        {
            PrepareAndEmitSoundToClient(client,readyWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "NukeReady");
        }
    }
}

ExplodeAll(Float:vec1[3])
{
    PrepareAndEmitSoundToAll(explosionsWav[(GameType == tf2) ? 1 : 0],SOUND_FROM_WORLD,.origin=vec1);

    vec1[2] += 10.0;

    TE_SetupExplosion(vec1, Fire2Sprite(), 10.0, 1, 0, 0, 5000); // 600
    TE_SendEffectToAll();

    new entities = (GameType == tf2 && GetMode() != MvM && cfgNuclearEffects > 0)
                   ? EntitiesAvailable(100, .message="Reducing Nuke Effects") : 0;

    if (entities < 50 || cfgNuclearEffects < 1 || GetParticleCount() > 10 ||
        (gNuclearParticleTime != 0.0 && GetGameTime() - gNuclearParticleTime < 2.0))
    {
        //static const color[4]={188,220,255,255};
        //TE_SetupBeamRingPoint(vec1, 10.0, 1500.0, FireSprite(), HaloSprite(),
        //                      0, 66, 6.0, 128.0, 0.2, color, 25, 0);
        //TE_SendOBeaconToAll();
        TE_SetupExplosion(vec1, FireSprite(), 100.0,1,0,1500, 5000);
        TE_SendEffectToAll();
    }
    else if (cfgNuclearEffects < 2 || entities < 100)
        CreateParticle("cinefx_goldrush", 10.0, 0, NoAttach, "", vec1);
    else
    {
        gNuclearParticleTime = GetGameTime();

        CreateParticle("Explosion_Smoke_1", 1.0, 0, NoAttach, "", vec1);
        CreateParticle("cinefx_goldrush_burningdebris", 10.0, 0, NoAttach, "", vec1);

        if (cfgNuclearEffects >= 3 && entities > 150)
        {
            CreateParticle("cinefx_goldrush_embers", 5.0, 0, NoAttach, "", vec1);
            CreateParticle("cinefx_goldrush_debris", 5.0, 0, NoAttach, "", vec1);
            CreateParticle("cinefx_goldrush_initial_smoke", 5.0, 0, NoAttach, "", vec1);
            CreateParticle("cinefx_goldrush_flash", 10.0, 0, NoAttach, "", vec1);

            if (cfgNuclearEffects >= 4 && entities > 200)
            {
                CreateParticle("cinefx_goldrush_flames", 10.0, 0, NoAttach, "", vec1);
                CreateParticle("cinefx_goldrush_smoke", 10.0, 0, NoAttach, "", vec1);
                CreateParticle("cinefx_goldrush_hugedustup", 10.0, 0, NoAttach, "", vec1);
            }
        }
    }
}

BuildScienceVessel(client)
{
    if (g_scienceVesselRace < 0)
        g_scienceVesselRace = FindRace("vessel");

    if (g_scienceVesselRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, vesselID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Terran Science Vessel race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromBuildingScienceVessel");
    }
    else if (CanInvokeUpgrade(client, raceID, vesselID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_scienceVesselRace, true, false, true);
    }
}

SetupUberShield(client, level)
{
    if (m_UberShieldAvailable)
    {
        if (level > 0)
        {
            GiveUberShield(client, level, level,
                           Shield_Immobilize |
                           Shield_Target_Enemy |
                           Shield_Target_Location |
                           Shield_DisableStopSound);
        }
        else
            TakeUberShield(client);
    }
}

UltimateLockdown(client, ult_level)
{
    if (!m_UberShieldAvailable)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, nukeID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GameType == tf2 && TF2_HasTheFlag(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, ultlockdownID, false))
    {
        new Float:duration = float(ult_level) + 1.0;
        UberShieldTarget(client, duration, Shield_Immobilize | Shield_Target_Enemy |
                                           Shield_Target_Location | Shield_DisableStopSound);

        decl String:upgradeName[64];
        GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client,Display_Ultimate,"%t", "Invoked", upgradeName);
        CreateCooldown(client, raceID, ultlockdownID);
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
            GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (GameType == tf2 && TF2_HasTheFlag(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseWithFlag", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && target != client &&
                 GameType == tf2 && TF2_HasTheFlag(target))
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceID, ultlockdownID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "CantUseOnFlagCarrier", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (target > 0 && target != client &&
                 (GetImmunity(target,Immunity_Ultimates) ||
                  GetImmunity(target,Immunity_MotionTaking)))
        {
            DisplayMessage(client, Display_Ultimate, "%t", "TargetIsImmune");
            PrepareAndEmitSoundToClient(client,deniedWav);
            return Plugin_Stop;
        }
        else if (!CanInvokeUpgrade(client, raceID, ultlockdownID))
            return Plugin_Stop;
    }
    return Plugin_Continue;
}
