/**
 * vim: set ai et ts=4 sw=4 :
 * File: Necromancer.sp
 * Description: The Necromancer race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 * Credits:   [Oddity]TeacherCreature
 *            Anthony Iacono 
 */
 
#pragma semicolon 1

// Pump up the memory!
#pragma dynamic 32767

#include <sourcemod>
#include <sdktools>

#include <smlib/teams>
#include <entity_flags>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <libtf2/horsemann>
#include <libtf2/MonoSpawn>
#include <libtf2/wrangleye>
#include <libtf2/behorsemann>
#include "sc/RateOfFire"
#define REQUIRE_PLUGIN

//#include "smlib/teams"

#include "sc/SourceCraft"
#include "sc/HealthParticle"
#include "sc/SpeedBoost"
#include "sc/ShopItems"
#include "sc/maxhealth"
#include "sc/plugins"
#include "sc/sounds"

#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:deathWav[]      = "sc/Necromancer_Boss_WoundCritical_01.mp3";
new const String:summonWav[]     = "sc/Necromancer2_Greetings_02.mp3";
new const String:frenzyWav[]     = "sc/FX_Spirit_Channel05.mp3";

new const String:necroWav[][]   = { "sc/NecromancerReady1.mp3" ,
                                    "sc/NecromancerWarcry1.mp3" ,
                                    "sc/NecromancerWhat1.mp3" };

new g_CrippleChance[]               = { 0, 20, 24, 28, 32, 36, 40, 44, 48 };
new Float:g_SpeedLevels[]           = { -1.0, 1.05,  1.10,   1.16, 1.23  };
new Float:g_VampiricAuraPercent[]   = { 0.0,  0.12,  0.18,   0.24, 0.30  };
new g_HorsemannHealthFactor[]       = { 0,  25,  50, 100, 200,  250 };
new g_HorsemannMaxHealth[]          = { 0, 400, 550, 700, 850, 1200 };

new String:raiseWav[]="vo/trainyard/ba_backup.wav";

new raceID, vampiricID, crippleID, trainingID, wrangleID, frenzyID;
new raiseDeadID, raiseHorseID, raiseEyeID, summonHorseID, scareID;

new bool:m_FrenzyActive[MAXPLAYERS+1];
new Float:m_VampiricAuraTime[MAXPLAYERS+1];

new Handle:m_CrippleTimer[MAXPLAYERS+1];
new Float:m_CrippleROF[MAXPLAYERS+1];
new Float:m_CrippleEnergy[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Necromancer",
    author = "-=|JFH|=-Naris",
    description = "The Necromancer race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://www.jigglysfunhouse.net/"
};

// War3Source Functions
public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.necromancer.phrases.txt");

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
    raceID       = CreateRace("necromancer", -1, -1, 33, .faction=UndeadScourge,
                              .type=Undead, .parent="undead");

    vampiricID   = AddUpgrade(raceID, "vampiric_aura", .energy=2.0, .cost_crystals=10);

    crippleID    = AddUpgrade(raceID, "cripple", .max_level=sizeof(g_CrippleChance)-1,
                              .energy=5.0, .cost_crystals=10);

    trainingID   = AddUpgrade(raceID, "training", .cost_crystals=20);

    // Ultimate 1
    frenzyID     = AddUpgrade(raceID, "unholy_frenzy", 1, .energy=30.0,
                              .recurring_energy=3.0, .cooldown=10.0,
                              .cost_crystals=30);

    wrangleID    = AddUpgrade(raceID, "wrangle_eye", 1, 12, 1,
                              .energy=30.0, .vespene=10,
                              .cost_crystals=35);

    if (GetGameType() != tf2 || !IsWrangleyeAvailable())
    {
        SetUpgradeDisabled(raceID, wrangleID, true);
        LogMessage("Disabling Necromancer:Direct Monoculus due to wrangleye is not available (or gametype != tf2)");
    }

    raiseDeadID  = AddUpgrade(raceID, "raise_dead", 2, 6, 1,
                              .energy=30.0, .cost_crystals=30);

    raiseEyeID   = AddUpgrade(raceID, "raise_eye", 3, 8, 4,
                              .energy=200.0, .vespene=80,
                              .cooldown=160.0, .cost_crystals=50);

    if (GameType != tf2 || !IsMonoculusAvailable())
    {
        SetUpgradeDisabled(raceID, raiseEyeID, true);
        LogMessage("Disabling Necromancer:Raise Monoculus due to MonoSpawn is not available (or gametype != tf2)");
    }

    raiseHorseID = AddUpgrade(raceID, "raise_horse", 3, 6, 1,
                              .energy=180.0, .vespene=50,
                              .cooldown=120.0, .cost_crystals=40);

    if (GameType != tf2 || !IsHorsemannAvailable())
    {
        SetUpgradeDisabled(raceID, raiseHorseID, true);
        LogMessage("Disabling Necromancer:Raise Horsemann due to horsemann is not available (or gametype != tf2)");
    }

    summonHorseID = AddUpgrade(raceID, "summon_horse", 4, 16, 5,
                               .energy=300.0, .vespene=100,
                               .cooldown=200.0, .cost_crystals=75);

    scareID       = AddUpgrade(raceID, "scare", 5, 16, 4,
                               .energy=30.0, .vespene=10,
                               .recurring_energy=5.0,
                               .cooldown=2.0, .cost_crystals=15);

    if (GameType != tf2 || !IsBeHorsemannAvailable())
    {
        SetUpgradeDisabled(raceID, summonHorseID, true);
        SetUpgradeDisabled(raceID, scareID, true);
        LogMessage("Disabling Necromancer:Summon Horsemann & Scare due to behorsemann is not available (or gametype != tf2)");
    }

    // Set  the ROF Available flag
    IsROFAvailable();

    // Get Configuration Data

    GetConfigArray("chance", g_CrippleChance, sizeof(g_CrippleChance),
                   g_CrippleChance, raceID, crippleID);

    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, frenzyID);

    GetConfigFloatArray("damage_percent", g_VampiricAuraPercent, sizeof(g_VampiricAuraPercent),
                        g_VampiricAuraPercent, raceID, vampiricID);

    GetConfigArray("hhh_health", g_HorsemannHealthFactor, sizeof(g_HorsemannHealthFactor),
                   g_HorsemannHealthFactor, raceID, summonHorseID);

    GetConfigArray("hhh_maxhealth", g_HorsemannMaxHealth, sizeof(g_HorsemannMaxHealth),
                   g_HorsemannMaxHealth, raceID, summonHorseID);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "RateOfFire"))
        IsROFAvailable(true);
    else  if (StrEqual(name, "behorsemann"))
        IsBeHorsemannAvailable(true);
    else if (StrEqual(name, "horsemann"))
        IsHorsemannAvailable(true);
    else if (StrEqual(name, "MonoSpawn"))
        IsMonoculusAvailable(true);
    else if (StrEqual(name, "wrangleye"))
        IsWrangleyeAvailable(true);
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "RateOfFire"))
        m_ROFAvailable = false;
    else if (StrEqual(name, "behorsemann"))
        m_BeHorsemannAvailable = false;
    else if (StrEqual(name, "horsemann"))
        m_HorsemannAvailable = false;
    else if (StrEqual(name, "MonoSpawn"))
        m_MonoculusAvailable = false;
    else if (StrEqual(name, "wrangleye"))
        m_WrangleyeAvailable = false;
}

public OnMapStart()
{
    SetupBeamSprite();
    SetupHaloSprite();
    SetupSpeed();

    SetupErrorSound();
    SetupDeniedSound();
    
    SetupSound(raiseWav);
    SetupSound(deathWav);
    SetupSound(summonWav);
    SetupSound(frenzyWav);

    for (new i = 0; i < sizeof(necroWav); i++)
        SetupSound(necroWav[i]);
}

public OnMapEnd()
{
    for (new index=1;index<=MaxClients;index++)
    {
        m_FrenzyActive[index] = false;
        m_VampiricAuraTime[index] = 0.0;
        m_CrippleTimer[index] = INVALID_HANDLE;
    }
}

public OnClientDisconnect(client)
{
    m_FrenzyActive[client] = false;
    m_VampiricAuraTime[client] = 0.0;
    ResetCripple(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        SetInitialEnergy(client, -1.0);

        SetSpeed(client,-1.0, true);

        if (m_FrenzyActive[client])
            EndFrenzy(INVALID_HANDLE, GetClientUserId(client));
        else if (m_ROFAvailable)
            SetROF(client, 0.0, 0.0);

        return (m_BeHorsemannAvailable && IsHorsemann(client)) ? Plugin_Stop : Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_FrenzyActive[client] = false;

        new training_level  = GetUpgradeLevel(client,raceID,trainingID);
        new Float:training_energy = 80.0 + (float(training_level)*15.0);
        new Float:initial_energy  = GetInitialEnergy(client);
        SetInitialEnergy(client, training_energy);
        if (GetEnergy(client, true) >= initial_energy)
            SetEnergy(client, training_energy, true);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(summonWav, client);
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
        if (!m_BeHorsemannAvailable || !IsHorsemann(client))
        {
            if (upgrade==frenzyID && m_FrenzyActive[client])
                SetSpeedBoost(client, new_level, true, g_SpeedLevels);
            else if (upgrade==trainingID)
            {
                new Float:training_energy = 80.0 + (float(new_level)*15.0);
                new Float:initial_energy  = GetInitialEnergy(client);
                SetInitialEnergy(client, training_energy);
                if (GetEnergy(client, true) >= initial_energy)
                    SetEnergy(client, training_energy, true);
            }
        }
    }
}

public OnItemPurchase(client,item)
{
    if (m_FrenzyActive[client] &&
        (!m_BeHorsemannAvailable || !IsHorsemann(client)))
    {
        if (GetRace(client) == raceID && IsValidClientAlive(client))
        {
            if (g_bootsItem < 0)
                g_bootsItem = FindShopItem("boots");

            if (item == g_bootsItem)
            {
                new frenzy_level = GetUpgradeLevel(client,raceID,frenzyID);
                if (frenzy_level > 0)
                    SetSpeedBoost(client, frenzy_level, true, g_SpeedLevels);
            }
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        if (m_BeHorsemannAvailable && IsHorsemann(client))
        {
            HorsemannScare(client);
        }
        else
        {
            switch (arg)
            {
                case 4, 5: // Summon Horsemann and Horsemann Scare
                {
                    new horse_level = GetUpgradeLevel(client,race,summonHorseID);
                    if (m_BeHorsemannAvailable && horse_level > 0)
                    {
                        if (GetRestriction(client,Restriction_NoUltimates) ||
                            GetRestriction(client,Restriction_Stunned))
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, summonHorseID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (IsMole(client))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);

                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, summonHorseID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
                        }
                        else if (CanInvokeUpgrade(client, raceID, summonHorseID, false))
                        {
                            int count = Team_GetClientCount(GetClientTeam(client) == 2 ? 3 : 2);
                            int health = 200 + (g_HorsemannHealthFactor[horse_level] * count);
                            if (health > g_HorsemannMaxHealth[horse_level])
                                health = g_HorsemannMaxHealth[horse_level];

                            if (MakeHorsemann(client, health, (TF2_GetPlayerClass(client) != TFClass_DemoMan)) == 0)
                            {
                                SetInitialEnergy(client, -1.0);
                                SetSpeed(client,-1.0, true);

                                if (m_FrenzyActive[client])
                                    EndFrenzy(INVALID_HANDLE, GetClientUserId(client));
                                else if (m_ROFAvailable)
                                    SetROF(client, 0.0, 0.0);

                                ChargeForUpgrade(client, raceID, summonHorseID);
                                CreateCooldown(client, raceID, summonHorseID);
                            }
                        }
                    }
                }
                case 3: // Raise Monoculus or Raise Horsemann
                {
                    new eye_level = GetUpgradeLevel(client,race,raiseEyeID);
                    if (m_MonoculusAvailable && eye_level > 0)
                    {
                        if (GetRestriction(client,Restriction_NoUltimates) ||
                            GetRestriction(client,Restriction_Stunned))
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, raiseEyeID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (IsMole(client))
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, raiseEyeID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (CanInvokeUpgrade(client, raceID, raiseEyeID, false))
                        {
                            if (TF2_SpawnMonoculus(client, eye_level-1) == 0)
                            {
                                ChargeForUpgrade(client, raceID, raiseEyeID);
                                CreateCooldown(client, raceID, raiseEyeID);
                            }
                        }
                    }
                    else if (m_HorsemannAvailable &&
                             GetUpgradeLevel(client,race,raiseHorseID) > 0)
                    {
                        if (GetRestriction(client,Restriction_NoUltimates) ||
                            GetRestriction(client,Restriction_Stunned))
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, raiseHorseID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (IsMole(client))
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, raiseHorseID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (CanInvokeUpgrade(client, raceID, raiseHorseID, false))
                        {
                            if (SpawnHorsemann(client) == 0)
                            {
                                ChargeForUpgrade(client, raceID, raiseHorseID);
                                CreateCooldown(client, raceID, raiseHorseID);
                            }
                        }
                    }
                }
                case 2: // Raise Dead
                {
                    new raise_level = GetUpgradeLevel(client,race,raiseDeadID);
                    if (raise_level > 0)
                    {
                        if (GetRestriction(client,Restriction_NoUltimates) ||
                            GetRestriction(client,Restriction_NoRespawn)   ||
                            GetRestriction(client,Restriction_Stunned)    )
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, raiseDeadID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (IsMole(client))
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, raiseDeadID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "CantUseAsMole", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (CanInvokeUpgrade(client, raceID, raiseDeadID, false))
                        {
                            if (RaiseDead(client))
                            {
                                ChargeForUpgrade(client, raceID, raiseDeadID);
                                CreateCooldown(client, raceID, raiseDeadID);
                            }
                        }
                    }
                }
                default: // Direct Monoculus or Unholy Frenzy
                {
                    new wrangle_level = GetUpgradeLevel(client,race,wrangleID);
                    if (wrangle_level > 0)
                    {
                        if (GetRestriction(client,Restriction_NoUltimates) ||
                            GetRestriction(client,Restriction_Stunned))
                        {
                            decl String:upgradeName[NAME_STRING_LENGTH];
                            GetUpgradeName(raceID, wrangleID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                            PrepareAndEmitSoundToClient(client,deniedWav);
                        }
                        else if (CanInvokeUpgrade(client, raceID, wrangleID, false))
                        {
                            if (TF2_WrangleMonoculus(client))
                            {
                                ChargeForUpgrade(client, raceID, raiseDeadID);
                                CreateCooldown(client, raceID, wrangleID);
                            }
                        }
                    }
                    else
                    {
                        new frenzy_level = GetUpgradeLevel(client,race,frenzyID);
                        if (frenzy_level > 0)
                        {
                            if (GetRestriction(client,Restriction_NoUltimates) ||
                                GetRestriction(client,Restriction_Stunned))
                            {
                                decl String:upgradeName[NAME_STRING_LENGTH];
                                GetUpgradeName(raceID, frenzyID, upgradeName, sizeof(upgradeName), client);
                                DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                                PrepareAndEmitSoundToClient(client,deniedWav);
                            }
                            else
                            {
                                new hurt = frenzy_level*10;
                                new health = GetClientHealth(client);
                                if (health <= hurt+10)
                                {
                                    PrepareAndEmitSoundToClient(client,errorWav);
                                    DisplayMessage(client, Display_Ultimate, "%t",
                                                   "InsufficientHealthForFrenzy");
                                }
                                else if (CanInvokeUpgrade(client, raceID, frenzyID))
                                {
                                    PrepareAndEmitSoundToAll(frenzyWav, client);
                                    SetEntityHealth(client, health - hurt);

                                    SetROF(client, 2.0/float(frenzy_level),
                                           GetUpgradeRecurringEnergy(raceID,frenzyID));

                                    m_FrenzyActive[client]=true;
                                    HudMessage(client, "%t", "FrenzyHud");
                                    PrintHintText(client, "%t", "FrenzyActive");

                                    //new num = GetRandomInt(0,sizeof(frenzyWav)-1);
                                    //PrepareAndEmitSoundToAll(frenzyWav[num],client);

                                    CreateCooldown(client, raceID, frenzyID);
                                    CreateTimer(2.0 * float(frenzy_level), EndFrenzy,
                                                GetClientUserId(client),
                                                TIMER_FLAG_NO_MAPCHANGE);
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
        m_FrenzyActive[client] = false;
        m_VampiricAuraTime[client] = 0.0;

        new training_level  = GetUpgradeLevel(client,raceID,trainingID);
        new Float:training_energy = 80.0 + (float(training_level)*15.0);
        new Float:initial_energy  = GetInitialEnergy(client);
        SetInitialEnergy(client, training_energy);
        if (GetEnergy(client, true) >= initial_energy)
            SetEnergy(client, training_energy, true);
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    if (m_CrippleTimer[victim_index] != INVALID_HANDLE)
    {
        ResetCripple(victim_index);
    }

    if (victim_race == raceID)
    {
        PrepareAndEmitSoundToAll(deathWav, victim_index);

        SetSpeed(victim_index,-1.0);

        if (m_FrenzyActive[victim_index])
            EndFrenzy(INVALID_HANDLE, GetClientUserId(victim_index));
        else if (m_ROFAvailable)
            SetROF(victim_index, 0.0, 0.0);
    }
    else if (attacker_race == raceID)
    {
        if (IsValidClientAlive(attacker_index))
        {
            new Float:vec[3];
            GetClientEyePosition(attacker_index, vec);
            
            new num = GetRandomInt(0,sizeof(necroWav)-1);
            PrepareAndEmitAmbientSound(necroWav[num], vec, attacker_index);
        }
    }
    else if (assister_race == raceID)
    {
        if (IsValidClientAlive(assister_index))
        {
            new Float:vec[3];
            GetClientEyePosition(assister_index, vec);
            
            new num = GetRandomInt(0,sizeof(necroWav)-1);
            PrepareAndEmitAmbientSound(necroWav[num], vec, assister_index);
        }
    }
}

public Action:OnPlayerTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
    if (GetRace(attacker) == raceID && attacker != victim && IsClient(victim))
    {
        if (!m_BeHorsemannAvailable || !IsHorsemann(attacker))
        {
            new cripple_level = GetUpgradeLevel(attacker,raceID,crippleID);
            if (cripple_level > 0 && m_CrippleTimer[victim] == INVALID_HANDLE &&
                !GetRestriction(attacker,Restriction_NoUpgrades) &&
                !GetRestriction(attacker,Restriction_Stunned) &&
                !GetImmunity(victim,Immunity_MotionTaking) &&
                !GetImmunity(victim,Immunity_Restore))
            {
                if (GetRandomInt(1,100) <= g_CrippleChance[cripple_level] &&
                    CanInvokeUpgrade(attacker, raceID, crippleID, .notify=false))
                {
                    SetSpeed(victim,0.6, true);
                    if (m_ROFAvailable)
                    {
                        m_CrippleROF[victim] = GetROF(victim, m_CrippleEnergy[victim]);
                        SetROF(victim, 0.5, 0.0);
                    }

                    FlashScreen(victim,RGBA_COLOR_RED);
                    DisplayMessage(attacker,Display_Defense, "%t", "YouCrippled", victim);
                    DisplayMessage(victim,Display_Enemy_Defended, "%t", "HasCrippled", attacker);
                    HudMessage(victim, "%t", "CrippleHud");

                    m_CrippleTimer[victim] = CreateTimer(2.0, RemoveCripple, GetClientUserId(victim),
                                                         TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:RemoveCripple(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        m_CrippleTimer[client] = INVALID_HANDLE;
        ResetCripple(client);
    }
}

ResetCripple(client)
{
    new Handle:timer = m_CrippleTimer[client];
    if (timer != INVALID_HANDLE)
    {
        m_CrippleTimer[client] = INVALID_HANDLE;	
        KillTimer(timer);
    }

    ClearHud(client, "%t", "CrippleHud");
    SetSpeed(client, -1.0, true);

    if (m_ROFAvailable)
    {
        SetROF(client, m_CrippleROF[client], m_CrippleEnergy[client]);
    }
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (!m_BeHorsemannAvailable || !IsHorsemann(attacker_index))
        {
            if (VampiricAura(damage + absorbed, attacker_index, victim_index))
                return Plugin_Handled;
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
        if (!m_BeHorsemannAvailable || !IsHorsemann(assister_race))
        {
            if (VampiricAura(damage + absorbed, assister_index, victim_index))
                return Plugin_Handled;
        }                
    }

    return Plugin_Continue;
}

bool:VampiricAura(damage, index, victim_index)
{
    new level = GetUpgradeLevel(index,raceID,vampiricID);
    if (level > 0 && GetRandomInt(1,10) <= 6 && IsValidClientAlive(index) &&
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
            new Float:lastTime = m_VampiricAuraTime[index];
            new Float:interval = GetGameTime() - lastTime;
            if ((lastTime == 0.0 || interval > 0.25) &&
                CanInvokeUpgrade(index, raceID, vampiricID, .notify=false))
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

                m_VampiricAuraTime[index] = GetGameTime();

                new leechhealth=RoundFloat(float(damage)*g_VampiricAuraPercent[level]);
                if (leechhealth <= 0)
                    leechhealth = 1;

                new health = GetClientHealth(index) + leechhealth;
                if (health <= GetMaxHealth(index))
                {
                    ShowHealthParticle(index);
                    SetEntityHealth(index,health);

                    decl String:upgradeName[NAME_STRING_LENGTH];
                    GetUpgradeName(raceID, vampiricID, upgradeName, sizeof(upgradeName), index);

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
                    new victim_health = GetClientHealth(victim_index);
                    if (victim_health <= leechhealth)
                        KillPlayer(victim_index, index, "sc_vampiric_aura");
                    else
                    {
                        SetEntityHealth(victim_index, victim_health-leechhealth);

                        if (GameType != tf2 || GetMode() != MvM)
                        {
                            new entities = EntitiesAvailable(200, .message="Reducing Explosion Effects");
                            if (entities > 50)
                                CreateParticle("blood_impact_red_01_chunk", 0.1, victim_index, Attach, "head");
                        }

                        decl String:upgradeName[NAME_STRING_LENGTH];
                        GetUpgradeName(raceID, vampiricID, upgradeName, sizeof(upgradeName), victim_index);
                        DisplayMessage(victim_index, Display_Injury, "%t", "HasLeeched",
                                       index, leechhealth, upgradeName);
                    }
                }
                else
                {
                    DamageEntity(victim_index, leechhealth, index, DMG_GENERIC, "sc_vampiric_aura");
                    DisplayDamage(index, victim_index, leechhealth, "sc_vampiric_aura");
                }

                return true;
            }
        }
    }
    return false;
}

public Action:EndFrenzy(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        m_FrenzyActive[client]=false;

        SetSpeed(client,-1.0);

        if (m_ROFAvailable)
            SetROF(client, 0.0, 0.0);

        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            decl String:message[NAME_STRING_LENGTH];
            Format(message, sizeof(message), "%T", "FrenzyHud", client);
            ReplaceString(message, sizeof(message), "*", "");
            ReplaceString(message, sizeof(message), " ", "");
            ClearHud(client, message);

            PrintHintText(client, "%t", "FrenzyDissipated");
            //PrepareAndEmitSoundToAll(frenzyExpireWav,client);
        }

        CreateCooldown(client, raceID, frenzyID);
    }
}

public EventRoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        if (IsClientInGame(index))
        {
            SetSpeed(index,-1.0);
        }
    }
}

bool:RaiseDead(client)
{
    new team=GetClientTeam(client);
    new targetCount=0;
    new targetList[MAXPLAYERS+1];
    for(new x=1;x<=MaxClients;x++)
    {
        if(IsValidClient(x) && team==GetClientTeam(x) && !IsPlayerAlive(x))
        {
            targetList[targetCount++]=x;
        }
    }

    if (targetCount>0)
    {
        new Float:ang[3];
        GetClientEyeAngles(client,ang);

        new Float:pos[3];
        GetClientAbsOrigin(client,pos);
        pos[0]+=45.0;
        pos[1]+=45.0;
        pos[2]+=5.0;

        new target=targetList[GetRandomInt(0, targetCount-1)];
        if (target > 0)
        {
            RespawnPlayer(target);
            TeleportEntity(target,pos,ang,NULL_VECTOR);

            PrepareAndEmitSoundToAll(raiseWav,client);
            PrintHintText(target,"You were raised from the dead");
            PrintHintText(client,"You raised the dead!");

            SetEntProp(target, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
            CreateTimer(2.0, ResetCollisionGroup, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
            return true;
        }
    }

    PrepareAndEmitSoundToClient(client,errorWav);
    PrintHintText(client,"There are no dead to raise!");
    return false;
}

public Action:ResetCollisionGroup(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        new client_team = GetClientTeam(client);

        new Float:client_pos[3];
        GetClientAbsOrigin(client,client_pos);

        for(new i=1;i<=MaxClients;i++)
        {
            if (i != client && IsClientInGame(i) && IsPlayerAlive(i))
            {
                new team = GetClientTeam(i);
                if (team > 1 && (team != client_team || GetGameType() != tf2))
                {
                    new Float:pos[3];
                    GetClientAbsOrigin(i,pos);
                    if(GetVectorDistance(pos, client_pos)<=50.0)
                    {
                        CreateTimer(0.3, ResetCollisionGroup, userid, TIMER_FLAG_NO_MAPCHANGE);
                        return;
                    }
                }
            }
        }

        SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
    }
}

public Action:OnHorsemannScare(client, target)
{
    if (target <= 0 && IsValidClient(client) && GetRace(client) == raceID)
    {
        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[NAME_STRING_LENGTH];
            GetUpgradeName(raceID, scareID, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
            return Plugin_Stop;
        }
        else if (IsValidClientAlive(client))
        {
            if (CanInvokeUpgrade(client, raceID, scareID))
            {
                CreateCooldown(client, raceID, scareID);
                return Plugin_Continue;
            }
            else
                return Plugin_Stop;
        }
        else
            return Plugin_Stop;
    }
    else
        return Plugin_Continue;
}
