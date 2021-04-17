 /**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossChimera.sp
 * Description: The Protoss Chimera unit for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_meter>
#include <tf2_stocks>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <lib/rollermine>
#include <libtf2/sidewinder>
#include "sc/MindControl"
#define REQUIRE_PLUGIN

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/ShopItems"
#include "sc/Detector"
#include "sc/plugins"
#include "sc/shields"
#include "sc/sounds"

#include "effect/Explosion"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

char cloakWav[]       = "sc/pabfol01.wav";
char explodeWav[]     = "sc/PSaHit00.wav";
char unCloakWav[]     = "sc/PabCag00.wav";
char cloakReadyWav[]  = "sc/pabRdy00.wav";

float g_InitialShields[]    = { 0.0, 0.15, 0.25, 0.20, 0.75 };
float g_ShieldsPercent[][2] = { {0.00, 0.00},
                                {0.00, 0.10},
                                {0.00, 0.30},
                                {0.10, 0.40},
                                {0.20, 0.50} };

int g_MindControlChance[]   = { 0, 30, 50, 70, 90 };
float g_MindControlRange[]  = { 0.0, 150.0, 300.0, 350.0, 500.0 };

int g_ScrabChance[]         = { 0, 20, 40, 60, 90 };
float g_ScrabPercent[]      = { 0.0, 0.15, 0.30, 0.40, 0.50 };

float g_CloakingRange[]     = { 0.0, 150.0, 300.0, 350.0, 500.0 };
float g_DetectingRange[]    = { 0.0, 300.0, 450.0, 650.0, 800.0 };

int   g_mineHealth[]        = { 0,    35,    55,    75,   100   };
float g_mineDelay[]         = { 0.0,   1.0,   3.0,   6.0,  10.0 };
float g_mineLife[]          = { 0.0, 120.0, 300.0, 600.0,   0.0 };
int   g_mineExplode[]       = { 0,    50,    75,   100,   120   };
int   g_mineRadius[]        = { 0,    75,   150,   225,   300   };

int raceID, scarabID, cloakID, sensorID, shieldsID, controlID, mineID, explodeID;

bool cfgAllowInvisibility;

bool m_Cloaked[MAXPLAYERS+1][MAXPLAYERS+1];
float m_ScarabAttackTime[MAXPLAYERS+1];

public Plugin myinfo = 
{
    name = "SourceCraft Unit - Protoss Chimera",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Chimera unit for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public void OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.chimera.phrases.txt");
    LoadTranslations("sc.detector.phrases.txt");
    LoadTranslations("sc.mind_control.phrases.txt");

    if (GetGameType() == tf2)
    {
        if (!HookEventEx("teamplay_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_win event.");

        if (!HookEventEx("teamplay_round_stalemate",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_stalemate event.");

        if (!HookEventEx("tf_game_over",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the tf_game_over event.");

        if (!HookEventEx("teamplay_game_over",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_game_over event.");

        if (!HookEventEx("teamplay_win_panel",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_win_panel event.");
    }
    else if (GameType == dod)
    {
        if (!HookEventEx("dod_round_win",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the dod_round_win event.");

        if (!HookEventEx("dod_game_over",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the dod_game_over event.");
    }
    else if (GameTypeIsCS())
    {
        if (!HookEventEx("round_end",EventRoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the round_end event.");
    }

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public int OnSourceCraftReady()
{
    raceID    = CreateRace("chimera", 32, 0, 20, 45.0, 150.0, 2.0,
                           Protoss, Mechanical);

    scarabID  = AddUpgrade(raceID, "scarab_attack", .energy=2.0, .cost_crystals=10);

    cloakID   = AddUpgrade(raceID, "distortion", .cost_crystals=30);

    cfgAllowInvisibility = bool:GetConfigNum("allow_invisibility", true);
    if (!cfgAllowInvisibility)
    {
        SetUpgradeDisabled(raceID, cloakID, true);
        LogMessage("Disabling Protoss Chimera: Distortion Field due to configuration: sc_allow_invisibility=%d (or gametype != tf2)",
                   cfgAllowInvisibility);
    }

    sensorID  = AddUpgrade(raceID, "sensors", .cost_crystals=0);
    shieldsID = AddUpgrade(raceID, "shields", .energy=1.0, .cost_crystals=10);

    // Ultimate 1
    controlID = AddUpgrade(raceID, "mind_control", 1, .energy=45.0, .cooldown=2.0, .cost_crystals=30);

    if (GetGameType() != tf2 || !IsMindControlAvailable())
    {
        SetUpgradeDisabled(raceID, controlID, true);
        LogMessage("Disabling Protoss Chimera:Mind Control due to MindControl is not available (or gametype != tf2)");
    }

    // Ultimate 2
    mineID    = AddUpgrade(raceID, "phase_mine", 2, 1, .cost_crystals=30);

    // Ultimate 2
    explodeID    = AddUpgrade(raceID, "phase_explode", 3, 1, .cost_crystals=30);

    if (!IsRollermineAvailable())
    {
        SetUpgradeDisabled(raceID, mineID, true);
        LogMessage("Disabling Protoss Chimera:Phase Mine due to rollermine is not available");
    }

    // Set the Sidewinder available flag
    IsSidewinderAvailable();

    // Get Configuration Data
    GetConfigFloatArray("shields_amount", g_InitialShields, sizeof(g_InitialShields),
                        g_InitialShields, raceID, shieldsID);

    for (new level=0; level < sizeof(g_ShieldsPercent); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "shields_percent_level_%d", level);
        GetConfigFloatArray(key, g_ShieldsPercent[level], sizeof(g_ShieldsPercent[]),
                            g_ShieldsPercent[level], raceID, shieldsID);
    }

    GetConfigArray("chance", g_ScrabChance, sizeof(g_ScrabChance),
                   g_ScrabChance, raceID, scarabID);

    GetConfigFloatArray("damage_percent",  g_ScrabPercent, sizeof(g_ScrabPercent),
                        g_ScrabPercent, raceID, scarabID);

    GetConfigFloatArray("range",  g_CloakingRange, sizeof(g_CloakingRange),
                        g_CloakingRange, raceID, cloakID);

    GetConfigFloatArray("range",  g_DetectingRange, sizeof(g_DetectingRange),
                        g_DetectingRange, raceID, sensorID);

    GetConfigArray("chance", g_MindControlChance, sizeof(g_MindControlChance),
                   g_MindControlChance, raceID, controlID);

    GetConfigFloatArray("range",  g_MindControlRange, sizeof(g_MindControlRange),
                        g_MindControlRange, raceID, controlID);
}

public void OnLibraryAdded(const char [] name)
{
    if (StrEqual(name, "rollermine"))
        IsRollermineAvailable(true);
    else if (StrEqual(name, "MindControl"))
        IsMindControlAvailable(true);
    else if (StrEqual(name, "sidewinder") && GetGameType() == tf2)
        IsSidewinderAvailable(true);
}

public void OnLibraryRemoved(const char [] name)
{
    if (StrEqual(name, "rollermine"))
        m_RollermineAvailable = false;
    else if (StrEqual(name, "MindControl"))
        m_MindControlAvailable = false;
    else if (StrEqual(name, "sidewinder"))
        m_SidewinderAvailable = false;
}

public void OnMapStart()
{
    SetupExplosion();
    SetupBeamSprite();
    SetupHaloSprite();

    SetupDeniedSound();

    SetupSound(cloakWav);
    SetupSound(unCloakWav);
    SetupSound(explodeWav);
    SetupSound(cloakReadyWav);
}

public void OnMapEnd()
{
    for (int index=1;index<=MaxClients;index++)
    {
        ResetClientTimer(index);
        ResetCloakingAndDetector(index);
    }
}

public int OnPlayerAuthed(int client)
{
    m_ScarabAttackTime[client] = 0.0;
}

public void OnClientDisconnect(int client)
{
    KillClientTimer(client);
    ResetCloakedAndDetected(client);
    ResetCloakingAndDetector(client);
}

public Action OnRaceDeselected(int client, int oldrace, int newrace)
{
    if (oldrace == raceID)
    {
        ResetShields(client);
        KillClientTimer(client);
        ResetCloakingAndDetector(client);
        if (m_MindControlAvailable)
            ResetMindControlledObjects(client, false);

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action OnRaceSelected(int client, int oldrace, int newrace)
{
    if (newrace == raceID)
    {
        m_ScarabAttackTime[client] = 0.0;

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        if (IsValidClientAlive(client))
        {
            new cloaking_level=GetUpgradeLevel(client,raceID,cloakID);
            if (cloaking_level > 0 && cfgAllowInvisibility)
            {
                PrepareAndEmitSoundToAll(cloakReadyWav,client);
            }

            new detecting_level=GetUpgradeLevel(client,raceID,sensorID);
            if ((detecting_level > 0 || shields_level > 0 ||
                ((cloaking_level > 0 && cfgAllowInvisibility))))
            {
                CreateClientTimer(client, 1.0, CloakingAndDetector,
                                  TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public int OnUpgradeLevelChanged(int client, int race, int upgrade, int new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==cloakID)
        {
            if (new_level > 0 && cfgAllowInvisibility)
            {
                PrepareAndEmitSoundToAll(cloakReadyWav,client);
            }

            if ((new_level && cfgAllowInvisibility) ||
                GetUpgradeLevel(client,raceID,shieldsID) ||
                GetUpgradeLevel(client,raceID,sensorID))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 1.0, CloakingAndDetector,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
            {
                KillClientTimer(client);
                ResetCloakingAndDetector(client);
            }
        }
        else if (upgrade==sensorID)
        {
            if (new_level || GetUpgradeLevel(client,raceID,shieldsID)
                          || (GetUpgradeLevel(client,raceID,cloakID) &&
                              cfgAllowInvisibility))
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 1.0, CloakingAndDetector,
                                      TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            else
            {
                KillClientTimer(client);
                ResetCloakingAndDetector(client);
            }
        }
        else if (upgrade==shieldsID)
        {
            SetupShields(client, new_level, g_InitialShields,
                         g_ShieldsPercent, .upgrade=true);

            if (new_level || GetUpgradeLevel(client,raceID,sensorID)
                          || (GetUpgradeLevel(client,raceID,cloakID)
                              && cfgAllowInvisibility))
            {
                if (IsValidClientAlive(client))
                {
                    if (new_level > 0)
                    {
                        CreateClientTimer(client, 1.0, CloakingAndDetector,
                                          TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                    }
                }
            }
            else
            {
                KillClientTimer(client);
                ResetCloakingAndDetector(client);
            }
        }
    }
}

public int OnUltimateCommand(int client, int race, bool pressed, int arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 3:
            {
                int explode_level = GetUpgradeLevel(client,race,explodeID);
                if (explode_level > 0)
                {
                    if (m_RollermineAvailable)
                    {
                        if (IsMole(client))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);

                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, mineID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
                        }
                        else if (GetRestriction(client, Restriction_NoUltimates) ||
                                 GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate, "%t",
                                            "PreventedFromPlantingMine");
                        }
                        else
                            ExplodeRollermines(client);
                    }
                    else
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, mineID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
            }
            case 2:
            {
                int mine_level = GetUpgradeLevel(client,race,mineID);
                if (mine_level > 0)
                {
                    if (m_RollermineAvailable)
                    {
                        if (IsMole(client))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);

                            decl String:upgradeName[64];
                            GetUpgradeName(raceID, mineID, upgradeName, sizeof(upgradeName), client);
                            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
                        }
                        else if (GetRestriction(client, Restriction_NoUltimates) ||
                                 GetRestriction(client, Restriction_Stunned))
                        {
                            PrepareAndEmitSoundToClient(client,deniedWav);
                            DisplayMessage(client, Display_Ultimate, "%t",
                                            "PreventedFromPlantingMine");
                        }
                        else
                        {
                            int explode_level = GetUpgradeLevel(client,race,explodeID);
                            SetRollermine(client, .health=g_mineHealth[mine_level],
                                          .damageDelay=g_mineDelay[mine_level],
                                          .explodeDamage=g_mineExplode[explode_level],
                                          .explodeRadius=g_mineRadius[explode_level],
                                          .lifetime=g_mineLife[mine_level]);
                        }
                    }
                    else
                    {
                        decl String:upgradeName[64];
                        GetUpgradeName(raceID, mineID, upgradeName, sizeof(upgradeName), client);
                        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
                    }
                }
            }
            default:
            {
                int ult_level=GetUpgradeLevel(client,raceID,controlID);
                if (ult_level > 0)
                {
                    decl String:upgradeName[64];
                    GetUpgradeName(raceID, controlID, upgradeName, sizeof(upgradeName), client);

                    if (!m_MindControlAvailable)
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);
                        PrintHintText(client, "%t", "IsNotAvailable", upgradeName);
                        return;
                    }

                    if (GetRestriction(client,Restriction_NoUltimates) ||
                        GetRestriction(client,Restriction_Stunned))
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);
                        DisplayMessage(client, Display_Ultimate, "%t",
                                    "Prevented", upgradeName);
                    }
                    else if (CanInvokeUpgrade(client, raceID, controlID, false))
                    {
                        int builder;
                        TFExtObjectType type;
                        if (MindControl(client, g_MindControlRange[ult_level],
                                        g_MindControlChance[ult_level],
                                        builder, type, true))
                        {
                            if (IsValidClient(builder))
                            {
                                DisplayMessage(builder, Display_Enemy_Ultimate,
                                            "%t", "HasControlled", client,
                                            TF2_ObjectNames[type]);

                                DisplayMessage(client, Display_Ultimate, "%t", 
                                            "YouHaveControlled", builder,
                                            TF2_ObjectNames[type]);

                            }

                            CreateCooldown(client, raceID, controlID);
                            ChargeForUpgrade(client, raceID, controlID);
                        }
                    }
                }
            }
        }
    }
}

public int OnPlayerSpawnEvent(Handle event, int client, int race)
{
    SetVisibility(client, NormalVisibility);

    if (race == raceID)
    {
        m_ScarabAttackTime[client] = 0.0;

        new cloaking_level=GetUpgradeLevel(client,raceID,cloakID);
        if (cloaking_level > 0 && cfgAllowInvisibility)
        {
            PrepareAndEmitSoundToAll(cloakReadyWav,client);
        }

        new shields_level = GetUpgradeLevel(client,raceID,shieldsID);
        SetupShields(client, shields_level, g_InitialShields, g_ShieldsPercent);

        new detecting_level=GetUpgradeLevel(client,raceID,sensorID);
        if (detecting_level > 0 || shields_level > 0 ||
            (cloaking_level > 0 && cfgAllowInvisibility))
        {
            CreateClientTimer(client, 1.0, CloakingAndDetector,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action OnPlayerHurtEvent(Handle event, int victim_index, int victim_race,
                                int attacker_index, int attacker_race,
                                int damage, int absorbed, bool from_sc)
{
    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (ScarabAttack(damage + absorbed, victim_index, attacker_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action OnPlayerAssistEvent(Handle:event, int victim_index, int victim_race,
                                  int assister_index, int assister_race, int damage,
                                  int absorbed)
{
    if (assister_race == raceID)
    {
        if (ScarabAttack(damage + absorbed, victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public int OnPlayerDeathEvent(Handle event, int victim_index, int victim_race,
                              int attacker_index, int attacker_race,
                              int assister_index, int assister_race,
                              int damage, const char [] weapon,
                              bool is_equipment, int customkill,
                              bool headshot, bool backstab, bool melee)
{
    if (victim_index)
    {
        SetVisibility(victim_index, NormalVisibility);

        if (victim_race == raceID)
        {
            KillClientTimer(victim_index);
            ResetCloakingAndDetector(victim_index);
            ResetCloakedAndDetected(victim_index);
            if (m_MindControlAvailable)
                ResetMindControlledObjects(victim_index, false);
        }
    }
}

public int EventRoundOver(Handle event, const char [] name, bool dontBroadcast)
{
    for (int index=1;index<=MaxClients;index++)
    {
        ResetCloakingAndDetector(index);
        if (m_MindControlAvailable)
            ResetMindControlledObjects(index, true);
    }
}

bool ScarabAttack(int damage, int victim_index, int index)
{
    int rs_level = GetUpgradeLevel(index,raceID,scarabID);
    if (rs_level > 0)
    {
        if (!GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(victim_index, Immunity_Explosion) &&
            !GetImmunity(victim_index, Immunity_HealthTaking) &&
            !GetImmunity(victim_index, Immunity_Upgrades) &&
            !IsInvulnerable(victim_index))
        {
            float lastTime = m_ScarabAttackTime[index];
            float interval = GetGameTime() - lastTime;
            if (lastTime == 0.0 || interval > 0.25)
            {
                if (GetRandomInt(1,100) <= g_ScrabChance[rs_level])
                {
                    int health_take = RoundToFloor(float(damage)*g_ScrabPercent[rs_level]);
                    if (health_take > 0)
                    {
                        if (CanInvokeUpgrade(index, raceID, scarabID, .notify=false))
                        {
                            if (interval == 0.0 || interval >= 2.0)
                            {
                                float Origin[3];
                                GetEntityAbsOrigin(victim_index, Origin);
                                Origin[2] += 5;

                                TE_SetupExplosion(Origin, Explosion(), 5.0, 1,0, 5, 10);
                                TE_SendEffectToAll();
                            }

                            PrepareAndEmitSoundToAll(explodeWav,victim_index);
                            FlashScreen(victim_index,RGBA_COLOR_RED);

                            m_ScarabAttackTime[index] = GetGameTime();
                            HurtPlayer(victim_index, health_take, index,
                                       "sc_scarab_attack", .type=DMG_BLAST,
                                       .in_hurt_event=true);
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

public Action CloakingAndDetector(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID)
        {
            bool restricted = (GetRestriction(client, Restriction_NoUpgrades) ||
                               GetRestriction(client, Restriction_Stunned));

            int cloaking_level=GetUpgradeLevel(client,raceID,cloakID);
            int detecting_level=GetUpgradeLevel(client,raceID,sensorID);
            if (cloaking_level > 0 || detecting_level > 0)
            {
                float cloaking_range = g_CloakingRange[cloaking_level];
                float detecting_range = g_DetectingRange[detecting_level];

                float indexLoc[3];
                float clientLoc[3];
                GetClientAbsOrigin(client, clientLoc);
                clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

                int count=0;
                int alt_count=0;
                int[] list = new int[MaxClients+1];
                int[] alt_list = new int[MaxClients+1];
                int team = GetClientTeam(client);
                bool isSpyCloaked = TF2_IsPlayerCloaked(client);
                for (int index=1;index<=MaxClients;index++)
                {
                    if (index != client && IsValidClient(index))
                    {
                        if (GetClientTeam(index) == team)
                        {
                            if (!restricted &&
                                !GetSetting(index, Disable_Beacons) &&
                                !GetSetting(index, Remove_Queasiness))
                            {
                                if (GetSetting(index, Reduce_Queasiness))
                                    alt_list[alt_count++] = index;
                                else
                                    list[count++] = index;
                            }

                            bool cloak;
                            if (cfgAllowInvisibility && !restricted && !isSpyCloaked &&
                                cloaking_level > 0 && IsPlayerAlive(index) &&
                                GetRace(index) != raceID) // Don't cloak other arbiters!
                            {
                                GetClientAbsOrigin(index, indexLoc);
                                cloak = IsPointInRange(clientLoc, indexLoc, cloaking_range) &&
                                        TraceTargetIndex(client, index, clientLoc, indexLoc);
                            }
                            else
                                cloak = false;

                            if (cloak)
                            {
                                SetVisibility(index, BasicVisibility, 0, 0.1, 0.1,
                                              RENDER_TRANSCOLOR, RENDERFX_NONE);

                                if (m_SidewinderAvailable)
                                    SidewinderCloakClient(client, true);

                                if (!m_Cloaked[client][index])
                                {
                                    m_Cloaked[client][index] = true;
                                    ApplyPlayerSettings(index);

                                    PrepareAndEmitSoundToClient(index, cloakWav);
                                    HudMessage(index, "%t", "CloakedHud");
                                    DisplayMessage(index, Display_Message, "%t",
                                                   "YouHaveBeenCloaked", client);
                                }
                            }
                            else // uncloak
                            {
                                SetVisibility(index, NormalVisibility);
                                if (m_SidewinderAvailable)
                                    SidewinderCloakClient(client, false);

                                if (m_Cloaked[client][index])
                                {
                                    m_Cloaked[client][index] = false;
                                    ApplyPlayerSettings(index);
                                    EmitSoundToClient(index, unCloakWav);
                                    ClearHud(index, "%t", "CloakedHud");
                                    DisplayMessage(index, Display_Message,
                                                   "%t", "YouHaveBeenUncloaked");
                                }
                            }
                        }
                        else
                        {
                            bool detect;
                            if (!restricted && detecting_level > 0 && IsPlayerAlive(index))
                            {
                                GetClientAbsOrigin(index, indexLoc);
                                detect = IsPointInRange(clientLoc,indexLoc,detecting_range) &&
                                         TraceTargetIndex(client, index, clientLoc, indexLoc);
                            }
                            else
                                detect = false;

                            if (detect)
                            {
                                char upgradeName[64];
                                GetUpgradeName(raceID, sensorID, upgradeName,
                                               sizeof(upgradeName), index);

                                bool uncloaked = false;
                                if (GetGameType() == tf2 &&
                                    !GetImmunity(index,Immunity_Uncloaking) &&
                                    TF2_GetPlayerClass(index) == TFClass_Spy)
                                {
                                    //TF2_RemovePlayerDisguise(index);
                                    TF2_RemoveCondition(client,TFCond_Cloaked);

                                    float cloakMeter = TF2_GetCloakMeter(index);
                                    if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                        TF2_SetCloakMeter(index, 0.0);

                                    uncloaked = true;
                                    HudMessage(index, "%t", "UncloakedHud");
                                    DisplayMessage(index, Display_Enemy_Message, "%t",
                                                   "HasUndisguised", client, upgradeName);
                                }

                                if (!GetImmunity(index,Immunity_Detection))
                                {
                                    SetOverrideVisiblity(index, 255);
                                    if (m_SidewinderAvailable)
                                        SidewinderDetectClient(index, true);

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
                                    ClearDetectedHud(index);
                                }
                            }
                        }
                    }
                }

                if (!restricted &&
                    !GetSetting(client, Disable_Beacons) &&
                    !GetSetting(client, Remove_Queasiness))
                {
                    if (GetSetting(client, Reduce_Queasiness))
                        alt_list[alt_count++] = client;
                    else
                        list[count++] = client;
                }

                clientLoc[2] -= 50.0; // Adjust position back to the feet.

                static const int detectColor[4] = {202, 225, 255, 255};
                static const int cloakColor[4] = {92, 92, 92, 255};

                if (count > 0)
                {
                    if (detecting_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, 10.0, detecting_range, BeamSprite(), HaloSprite(),
                                              0, 15, 0.5, 5.0, 0.0, detectColor, 10, 0);
                        TE_Send(list, count, 0.0);
                    }

                    if (cloaking_level > 0 && cfgAllowInvisibility)
                    {
                        TE_SetupBeamRingPoint(clientLoc, 10.0, cloaking_range, BeamSprite(), HaloSprite(),
                                              0, 10, 0.6, 10.0, 0.5, cloakColor, 10, 0);
                        TE_Send(list, count, 0.0);
                    }
                }

                if (alt_count > 0)
                {
                    if (detecting_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, detecting_range-10.0, detecting_range, BeamSprite(), HaloSprite(),
                                              0, 15, 0.5, 5.0, 0.0, detectColor, 10, 0);
                        TE_Send(alt_list, alt_count, 0.0);
                    }

                    if (cloaking_level > 0 && cfgAllowInvisibility)
                    {
                        TE_SetupBeamRingPoint(clientLoc, cloaking_range-10.0, cloaking_range, BeamSprite(), HaloSprite(),
                                              0, 10, 0.6, 10.0, 0.5, cloakColor, 10, 0);
                        TE_Send(alt_list, alt_count, 0.0);
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

void ResetCloakingAndDetector(int client)
{
    for (int index=1;index<=MaxClients;index++)
    {
        if (m_Cloaked[client][index])
        {
            m_Cloaked[client][index] = false;

            if (IsClientInGame(index))
            {
                SetVisibility(index, NormalVisibility,
                              .apply=m_Cloaked[client][index]);

                SetOverrideVisiblity(index, -1, m_Detected[client][index]);

                if (m_SidewinderAvailable)
                {
                    SidewinderDetectClient(index, false);
                    SidewinderCloakClient(index, false);
                }
            }
        }

        if (m_Detected[client][index])
        {
            m_Detected[client][index] = false;
            ClearDetectedHud(index);
        }
    }
}

void ResetCloakedAndDetected(int index)
{
    SetVisibility(index, NormalVisibility);
    SetOverrideVisiblity(index, -1);

    if (m_SidewinderAvailable)
    {
        SidewinderDetectClient(index, false);
        SidewinderCloakClient(index, false);
    }

    for (int client=1;client<=MaxClients;client++)
    {
        if (m_Cloaked[client][index])
        {
            m_Cloaked[client][index] = false;
            if (IsClientInGame(index))
            {
                ApplyPlayerSettings(index);
                EmitSoundToClient(index, unCloakWav);
                ClearHud(index, "%t", "CloakedHud");
                DisplayMessage(index, Display_Message,
                               "%t", "YouHaveBeenUncloaked");
            }
        }
        if (m_Detected[client][index])
        {
            m_Detected[client][index] = false;
            ClearDetectedHud(index);
        }
    }
}

