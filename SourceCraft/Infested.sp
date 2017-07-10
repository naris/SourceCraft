/**
 * vim: set ai et ts=4 sw=4 :
 * File: Infested.sp
 * Description: The Infested races for SourceCraft.
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
#include "sc/PlagueInfect"
#include "sc/clienttimer"
#include "sc/SpeedBoost"
#include "sc/weapons"
#include "sc/burrow"
#include "sc/sounds"

#include "effect/SendEffects"
#include "effect/Shake"

new const String:spawnWav[]      = "sc/zbgrdy00.wav";
new const String:deathWav[]      = "sc/zbghit00.wav";

new const String:infestedWav[][] = { "sc/zbgwht00.wav" ,
                                     "sc/zbgwht01.wav" ,
                                     "sc/zbgwht02.wav" ,
                                     "sc/zbgwht03.wav" ,
                                     "sc/zbgpss00.wav" ,
                                     "sc/zbgpss01.wav" ,
                                     "sc/zbgpss02.wav" ,
                                     "sc/zbgpss03.wav" ,
                                     "sc/zbgyes03.wav" };

new Float:g_SpeedLevels[]        = {   -1.0,  1.05,  1.07,  1.09, 1.11 };
new Float:g_ExplodeRadius[]      = { 1000.0, 800.0, 600.0, 450.0, 300.0 };
new g_ExplodePlayerDamage[]      = {    800,   900,  1000,  1100, 1200  };
new g_ExplodeBuildingDamage[]    = {   1000,  1250,  1500,  1750, 2000  };

new raceID, boostID, explodeID;

new m_LastRace[MAXPLAYERS+1];
new m_Countdown[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Infested",
    author = "-=|JFH|=-Naris",
    description = "The Infested race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.infested.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID   = CreateRace("infested", -1, -1, 13, .faction=Zerg, .type=Biological);

    AddUpgrade(raceID, "disarming", 0, 0);

    boostID  = AddUpgrade(raceID, "boost", 0, 0);

    // Ultimate 2
    AddBurrowUpgrade(raceID, 2, 4, 1);

    // Ultimate 1
    explodeID = AddUpgrade(raceID, "explode", 1, 0);

    // Get Configuration Data
    GetConfigFloatArray("speed", g_SpeedLevels, sizeof(g_SpeedLevels),
                        g_SpeedLevels, raceID, boostID);

    GetConfigFloatArray("range", g_ExplodeRadius, sizeof(g_ExplodeRadius),
                        g_ExplodeRadius, raceID, explodeID);

    GetConfigArray("player_damage", g_ExplodePlayerDamage, sizeof(g_ExplodePlayerDamage),
                   g_ExplodePlayerDamage, raceID, explodeID);

    GetConfigArray("building_damage", g_ExplodeBuildingDamage, sizeof(g_ExplodeBuildingDamage),
                   g_ExplodeBuildingDamage, raceID, explodeID);
}

public OnMapStart()
{
    SetupSpeed();

    SetupDeniedSound();

    SetupSound(spawnWav);
    SetupSound(deathWav);

    for (new i = 0; i < sizeof(infestedWav); i++)
        SetupSound(infestedWav[i]);
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
        SetSpeed(client,-1.0);
        SetVisibility(client, NormalVisibility);
        ApplyPlayerSettings(client);

        if (IsValidClientAlive(client))
            RespawnPlayer(client);

        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    if (newrace == raceID)
    {
        m_LastRace[client] = oldrace;
        m_Countdown[client] = 20;

        HudMessage(client, "%t", "InfestedHud");

        //Set Infested Color
        new r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 0; g = 224; b = 208; }
        else
        { r = 255; g = 165; b = 0; }
        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b,
                      .apply=false);

        new boost_level = GetUpgradeLevel(client,raceID,boostID);
        SetSpeedBoost(client, boost_level, true, g_SpeedLevels);

        if (IsValidClientAlive(client))
        {
            PrepareAndEmitSoundToAll(spawnWav,client);
            TF2_StunPlayer(client, 2.5, .stunflags=TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_THIRDPERSON);
            CreateClientTimer(client, 2.5, Exclaimation, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
        if (upgrade==boostID)
            SetSpeedBoost(client, new_level, true, g_SpeedLevels);
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
            new boost_level = GetUpgradeLevel(client,race,boostID);
            if (boost_level > 0)
                SetSpeedBoost(client, boost_level, true, g_SpeedLevels);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        switch (arg)
        {
            case 2:
            {
                Burrow(client, GetUpgradeLevel(client,race,burrowID)+1);
            }
            default:
            {
                if (GameType == tf2 && TF2_IsPlayerDisguised(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                }
                else
                {
                    new level=GetUpgradeLevel(client,race,explodeID);
                    ExplodePlayer(client, client, 0, g_ExplodeRadius[level],
                                  g_ExplodePlayerDamage[level],
                                  g_ExplodeBuildingDamage[level],
                                  ParticleExplosion|UltimateExplosion, 0);
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
        m_Countdown[client] = 20;

        HudMessage(client, "%t", "InfestedHud");

        //Set Infested Color
        new r,g,b;
        if (TFTeam:GetClientTeam(client) == TFTeam_Red)
        { r = 0; g = 224; b = 208; }
        else
        { r = 255; g = 165; b = 0; }

        SetVisibility(client, BasicVisibility,
                      .mode=RENDER_GLOW,
                      .fx=RENDERFX_GLOWSHELL,
                      .r=r, .g=g, .b=b,
                      .apply=false);

        new boost_level = GetUpgradeLevel(client,raceID,boostID);
        SetSpeedBoost(client, boost_level, true, g_SpeedLevels);

        PrepareAndEmitSoundToAll(spawnWav,client);

        TF2_StunPlayer(client, 2.5, .stunflags=TF_STUNFLAG_NOSOUNDOREFFECT|
                                               TF_STUNFLAG_THIRDPERSON);

        CreateClientTimer(client, 2.5, Exclaimation,
                          TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    KillClientTimer(victim_index);

    if (victim_race == raceID)
    {
        PrepareAndEmitSoundToAll(deathWav, victim_index);
        ClearHud(victim_index, "%t", "InfestedHud");

        new level=GetUpgradeLevel(victim_index,raceID,explodeID);
        ExplodePlayer(victim_index, victim_index, 0, g_ExplodeRadius[level],
                      g_ExplodePlayerDamage[level],
                      g_ExplodeBuildingDamage[level],
                      OnDeathExplosion, 0);

        // Default race to human for new players.
        new race = m_LastRace[victim_index];
        if (race <= 0)
            race = FindRace("human");

        // Revert back to previous race upon death as an Infested.
        ChangeRace(victim_index, race, true, true);
    }
}

public Action:Exclaimation(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID)
        {
            if (GameType != tf2 || TF2_IsPlayerTaunting(client))
                SetNextAttack(client, 2.5);
            else
            {
                TF2_StunPlayer(client, 2.5,
                               .stunflags=TF_STUNFLAG_NOSOUNDOREFFECT |
                                          TF_STUNFLAG_THIRDPERSON);
            }

            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);

            new num = GetRandomInt(0,sizeof(infestedWav)-1);
            PrepareAndEmitAmbientSound(infestedWav[num], clientLoc, client);

            if (--m_Countdown[client] <= 0)
            {
                new level=GetUpgradeLevel(client,raceID,explodeID);
                ExplodePlayer(client, client, 0, g_ExplodeRadius[level],
                              g_ExplodePlayerDamage[level],
                              g_ExplodeBuildingDamage[level],
                              ParticleExplosion, 0);
            }
        }
    }
    return Plugin_Continue;
}
