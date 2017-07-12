/**
 * vim: set ai et ts=4 sw=4 :
 * File: SickFarter.sp
 * Description: The Sick Farter race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <new_tempents_stocks>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <lib/trace>

#include "sc/SourceCraft"
#include "sc/clienttimer"
#include "sc/maxhealth"
#include "sc/weapons"
#include "sc/sounds"

#include "effect/Smoke"
#include "effect/Bubble"
#include "effect/RedGlow"
#include "effect/BlueGlow"
#include "effect/Lightning"
#include "effect/HaloSprite"
#include "effect/BeamSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"

new const String:fartWav[][]    = { "sc/fart.wav",
                                    "sc/fart3.wav",
                                    "sc/poot.mp3" };

new g_FesterChance[]            = { 0, 10, 15, 20, 25 };
new Float:g_FesterPercent[]     = { 0.0, 0.15, 0.30, 0.40, 0.50 };

new Float:g_FartRange[]         = { 0.0, 400.0, 550.0, 850.0, 1000.0 };
new Float:g_RevulsionRange[]    = { 0.0, 300.0, 450.0, 650.0, 800.0 };

new g_PickPocketChance[][]      = { {  0,  0 },
                                    { 10, 20 },
                                    { 20, 30 },
                                    { 30, 40 },
                                    { 40, 50 }};



new raceID, festerID, pickPocketID, revulsionID, fartID, hunterID;

new g_hunterRace = -1;

new gFartDuration[MAXPLAYERS+1];
new Float:gPickPocketTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Sick Farter",
    author = "Naris",
    description = "The Sick Farter race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://www.jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.farter.phrases.txt");

    GetGameType();
    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID       = CreateRace("farter", 16, 0, 17, .faction=UndeadScourge, .type=Undead);

    festerID     = AddUpgrade(raceID, "abomination", .energy=1.0, .cost_crystals=20);
    pickPocketID = AddUpgrade(raceID, "pickpocket", .energy=1.0, .cost_crystals=40);
    revulsionID  = AddUpgrade(raceID, "revulsion", .energy=1.0, .cost_crystals=20);

    // Ultimate 1
    fartID       = AddUpgrade(raceID, "flatulence", 1, .energy=30.0,
                              .cooldown=2.0, .cost_crystals=30);

    // Ultimate 2
    hunterID     = AddUpgrade(raceID, "hunter", 2, 16,1,
                              .energy=300.0, .cooldown=60.0,
                              .accumulated=true, .cost_crystals=50);

    // Get Configuration Data
    GetConfigArray("chance", g_FesterChance, sizeof(g_FesterChance),
                   g_FesterChance, raceID, festerID);

    GetConfigFloatArray("damage_percent", g_FesterPercent, sizeof(g_FesterPercent),
                        g_FesterPercent, raceID, festerID);

    GetConfigFloatArray("range", g_RevulsionRange, sizeof(g_RevulsionRange),
                        g_RevulsionRange, raceID, revulsionID);

    GetConfigFloatArray("range", g_FartRange, sizeof(g_FartRange),
                        g_FartRange, raceID, fartID);

    for (new level=0; level < sizeof(g_PickPocketChance); level++)
    {
        decl String:key[32];
        Format(key, sizeof(key), "chance_level_%d", level);
        GetConfigArray(key, g_PickPocketChance[level], sizeof(g_PickPocketChance[]),
                       g_PickPocketChance[level], raceID, pickPocketID);
    }
}

public OnMapStart()
{
    SetupLightning();
    SetupBeamSprite();
    SetupHaloSprite();
    SetupSmokeSprite();
    SetupBubbleModel();
    SetupBlueGlow();
    SetupRedGlow();

    SetupDeniedSound();

    for (new i = 0; i < sizeof(fartWav); i++)
        SetupSound(fartWav[i]);
}

public OnMapEnd()
{
    ResetAllClientTimers();
}

public OnPlayerAuthed(client)
{
    gPickPocketTime[client] = 0.0;
}

public OnClientDisconnect(client)
{
    KillClientTimer(client);
}

public Action:OnRaceDeselected(client,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        TraceInto("SickFarter", "OnRaceDeselected", "client=%d, oldrace=%d, newrace=%d", \
                  client, oldrace, newrace);

        KillClientTimer(client);

        new maxCrystals = GetMaxCrystals();
        if (GetCrystals(client) > maxCrystals)
        {
            SetCrystals(client, maxCrystals);
            DisplayMessage(client, Display_Crystals, "%t",
                           "CrystalsReduced", maxCrystals);
        }

        TraceReturn();
        return Plugin_Handled;
    }
    else
    {
        if (g_hunterRace < 0)
            g_hunterRace = FindRace("hunter");

        if (oldrace == g_hunterRace &&
            GetCooldownExpireTime(client, raceID, hunterID) <= 0.0)
        {
            CreateCooldown(client, raceID, hunterID,
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
        TraceInto("SickFarter", "OnRaceSelected", "client=%d, oldrace=%d, newrace=%d", \
                  client, oldrace, newrace);

        gPickPocketTime[client] = 0.0;

        new revulsion_level=GetUpgradeLevel(client,raceID,revulsionID);
        if (revulsion_level && IsValidClientAlive(client))
            CreateClientTimer(client, 2.0, Revulsion, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

        TraceReturn();
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public OnUpgradeLevelChanged(client,race,upgrade,new_level)
{
    if (race == raceID && GetRace(client) == raceID)
    {
        if (upgrade==revulsionID)
        {
            if (new_level > 0)
            {
                if (IsValidClientAlive(client))
                {
                    CreateClientTimer(client, 2.0, Revulsion,
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
        TraceInto("SickFarter", "OnUltimateCommand", "client=%N(%d), race=%d, pressed=%d, arg=%d", \
                  client, client, race, pressed, arg);

        if (arg >= 2)
        {
            new hunter_level=GetUpgradeLevel(client,race,hunterID);
            if (hunter_level > 0)
            {
                if (!pressed)
                    SummonHunter(client);
            }
        }
        else if (pressed)
        {
            new fart_level = GetUpgradeLevel(client,race,fartID);
            if (fart_level > 0)
            {
                if (GetRestriction(client,Restriction_NoUltimates) ||
                    GetRestriction(client,Restriction_Stunned))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);

                    decl String:upgradeName[64];
                    GetUpgradeName(raceID, fartID, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                }
                else if (CanInvokeUpgrade(client, raceID, fartID))
                {
                    if (GameType == tf2)
                    {
                        if (TF2_IsPlayerDisguised(client))
                            TF2_RemovePlayerDisguise(client);
                    }

                    gFartDuration[client] = fart_level * 3;

                    new Handle:FartTimer = CreateTimer(0.4, PersistFart, GetClientUserId(client),
                                                       TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                    TriggerTimer(FartTimer, true);

                    decl String:upgradeName[64];
                    GetUpgradeName(raceID, fartID, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client,Display_Ultimate, "%t", "Invoked", upgradeName);
                    CreateCooldown(client, raceID, fartID);
                }
            }
        }

        TraceReturn();
    }
}

// Events
public OnPlayerSpawnEvent(Handle:event, client, race)
{
    if (race == raceID)
    {
        TraceInto("SickFarter", "OnPlayerSpawnEvent", "client=%N(%d), raceID=%d", \
                  client, client, raceID);

        new revulsion_level=GetUpgradeLevel(client,raceID,revulsionID);
        if (revulsion_level > 0)
        {
            CreateClientTimer(client, 2.0, Revulsion,
                              TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }

        TraceReturn();
    }
}

public Action:OnEntityHurtEvent(Handle:event, victim_index, attacker_index, attacker_race, damage)
{
    if (attacker_race == raceID)
    {
        FesteringAbomination(damage, victim_index, attacker_index);
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnEntityAssistEvent(Handle:event, victim_index, assister_index, assister_race, damage)
{
    if (assister_race == raceID)
    {
        FesteringAbomination(damage, victim_index, assister_index);
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index &&
        attacker_race == raceID)
    {
        if (PickPocket(event, victim_index, attacker_index))
            returnCode = Plugin_Handled;

        if (FesteringAbomination(damage + absorbed, victim_index, attacker_index))
            returnCode = Plugin_Handled;
    }

    return returnCode;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    new Action:returnCode = Plugin_Continue;

    if (assister_race == raceID)
    {
        if (PickPocket(event, victim_index, assister_index))
            returnCode = Plugin_Handled;

        if (FesteringAbomination(damage + absorbed, victim_index, assister_index))
            returnCode = Plugin_Handled;
    }

    return returnCode;
}

public OnPlayerDeathEvent(Handle:event, victim_index, victim_race, attacker_index,
                          attacker_race, assister_index, assister_race, damage,
                          const String:weapon[], bool:is_equipment, customkill,
                          bool:headshot, bool:backstab, bool:melee)
{
    KillClientTimer(victim_index);

    if (g_hunterRace < 0)
        g_hunterRace = FindRace("hunter");

    if (victim_race == g_hunterRace &&
        GetCooldownExpireTime(victim_index, raceID, hunterID) <= 0.0)
    {
        CreateCooldown(victim_index, raceID, hunterID,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
}

bool:FesteringAbomination(damage, victim_index, index)
{
    TraceInto("SickFarter", "FesteringAbomination", "index=%N(%d), victim_index=%N(%d), damage=%d", \
              index, index, victim_index, victim_index, damage);

    new fa_level = GetUpgradeLevel(index, raceID, festerID);
    if (fa_level >= sizeof(g_FesterChance))
    {
        LogError("%d:%N has too many levels in SickFarter::FesteringAbomination level=%d, max=%d",
                 index, index, fa_level, sizeof(g_FesterChance));

        fa_level = sizeof(g_FesterChance)-1;
    }
    if (fa_level > 0)
    {
        if (!GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_HealthTaking) &&
            !GetImmunity(victim_index,Immunity_Upgrades) &&
            !IsInvulnerable(victim_index))
        {
            new health_take = RoundFloat(float(damage)*g_FesterPercent[fa_level]);
            if (health_take > 0 && GetRandomInt(1,100) <= g_FesterChance[fa_level] &&
                CanInvokeUpgrade(index, raceID, festerID, .notify=false))
            {
                new Float:indexLoc[3];
                GetClientAbsOrigin(index, indexLoc);
                indexLoc[2] += 50.0;

                new Float:victimLoc[3];
                GetEntityAbsOrigin(victim_index, victimLoc);
                victimLoc[2] += 50.0;

                static const color[4] = { 100, 255, 55, 255 };
                TE_SetupBeamPoints(indexLoc, victimLoc, Lightning(), HaloSprite(),
                                   0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendQEffectToAll(index, victim_index);
                FlashScreen(victim_index,RGBA_COLOR_RED);

                HurtPlayer(victim_index, health_take, index,
                           "sc_festering_abomination",
                           .type=DMG_NERVEGAS,
                           .in_hurt_event=true);

                TraceReturn();
                return true;
            }
        }
    }

    TraceReturn();
    return false;
}

bool:PickPocket(Handle:event,victim_index, index)
{
    TraceInto("SickFarter", "PickPocket", "index=%N(%d), victim_index=%N(%d), event=%x", \
              index, index, victim_index, victim_index, event);

    new pp_level = GetUpgradeLevel(index, raceID, pickPocketID);
    if (pp_level > 0)
    {
        decl String:weapon[64];
        new bool:is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
        new bool:is_melee=IsMelee(weapon, is_equipment,index,victim_index);

        if ((gPickPocketTime[index] == 0.0 || GetGameTime() - gPickPocketTime[index] > 1.0) &&
            GetRandomInt(1,100) <= g_PickPocketChance[pp_level][is_melee] &&
            !GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(victim_index,Immunity_Upgrades) &&
            !GetImmunity(victim_index,Immunity_Theft) &&
            !IsInvulnerable(victim_index))
        {
            new victim_cash = GetCrystals(victim_index);
            if (victim_cash > 0 && CanInvokeUpgrade(index, raceID, pickPocketID))
            {
                new Float:percent=GetRandomFloat(0.0,is_melee ? 0.15 : 0.05);
                new cash=GetCrystals(index);
                new plunder = RoundToCeil(float(victim_cash) * percent);

                SetCrystals(victim_index,victim_cash-plunder,false);
                SetCrystals(index,cash+plunder,false);
                gPickPocketTime[index] = GetGameTime();

                new Float:indexLoc[3];
                GetClientAbsOrigin(index, indexLoc);
                indexLoc[2] += 50.0;

                new Float:victimLoc[3];
                GetClientAbsOrigin(victim_index, victimLoc);
                victimLoc[2] += 50.0;

                static const color[4] = { 100, 255, 55, 255 };
                TE_SetupBeamPoints(indexLoc, victimLoc, Lightning(), HaloSprite(),
                                   0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendQEffectToAll(index, victim_index);

                LogToGame("%N stole %d crystal(s) from %N", index, plunder, victim_index);
                DisplayMessage(index, Display_Damage, "%t", "YouHaveStolenCrystals", plunder, victim_index);
                DisplayMessage(victim_index, Display_Injury, "%t", "StoleYourCrystals", index, plunder);

                TraceReturn();
                return true;
            }
        }
    }

    TraceReturn();
    return false;
}

public Action:PersistFart(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientNotSpec(client) && GetRace(client) == raceID &&
        !GetRestriction(client,Restriction_NoUltimates) &&
        !GetRestriction(client,Restriction_Stunned))
    {
        TraceInto("SickFarter", "PersistFart", "client=%d, timer=%x", \
                  client, timer);

        if (GameType == tf2)
        {
            if (TF2_IsPlayerTaunting(client) ||
                TF2_IsPlayerDazed(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn();
                return Plugin_Stop;
            }
            //case TFClass_Scout:
            else if (TF2_IsPlayerBonked(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn();
                return Plugin_Stop;
            }
            //case TFClass_Spy:
            else if (TF2_IsPlayerCloaked(client) ||
                     TF2_IsPlayerDeadRingered(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                TraceReturn();
                return Plugin_Stop;
            }
            else if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        new fart_level = GetUpgradeLevel(client,raceID,fartID);
        new Float:range = g_FartRange[fart_level];

        new Float:indexLoc[3];
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

        new Float:maxLoc[3];
        maxLoc[0] = clientLoc[0] + 256.0;
        maxLoc[1] = clientLoc[1] + 256.0;
        maxLoc[2] = clientLoc[2] + 256.0;

        new bubble_count = RoundToNearest(range/4.0);

        TE_SetupBubbles(clientLoc, maxLoc, BubbleModel(), range,
                        bubble_count, 2.0);
        TE_SendEffectToAll();

        TE_SetupBubbleTrail(clientLoc, maxLoc, g_bubbleModel,
                            range, bubble_count, 8.0);
        TE_SendEffectToAll();

        TE_SetupSmoke(clientLoc, SmokeSprite(),range,400);
        TE_SendEffectToAll();

        new snd = GetRandomInt(0,sizeof(fartWav)-1);
        PrepareAndEmitSoundToAll(fartWav[snd], client);

        new count=0;
        new num=fart_level*3;
        new team = GetClientTeam(client);
        new minDmg=fart_level*2;
        new maxDmg=fart_level*4;
        for (new index=1;index<=MaxClients;index++)
        {
            if (client != index && IsClientInGame(index) &&
                IsPlayerAlive(index) && GetClientTeam(index) != team)
            {
                if (!IsInvulnerable(index) &&
                    !GetImmunity(index,Immunity_Ultimates) &&
                    !GetImmunity(index,Immunity_HealthTaking))
                {
                    GetClientAbsOrigin(index, indexLoc);
                    if (IsPointInRange(clientLoc,indexLoc,range) &&
                        TraceTargetIndex(client, index, clientLoc, indexLoc))
                    {
                        new amt=GetRandomInt(minDmg,maxDmg);
                        FlashScreen(index,RGBA_COLOR_BROWN);
                        HurtPlayer(index,amt,client,"sc_flatulence",
                                   .xp=5+fart_level, .type=DMG_NERVEGAS);

                        if (++count > num)
                            break;
                    }
                }
            }
        }
        if (--gFartDuration[client] > 0)
        {
            TraceReturn();
            return Plugin_Continue;
        }

        TraceReturn();
    }

    return Plugin_Stop;
}

public Action:Revulsion(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client) &&
        !GetRestriction(client, Restriction_NoUpgrades) &&
        !GetRestriction(client, Restriction_Stunned))
    {
        TraceInto("SickFarter", "Revulsion", "client=%N(%d), timer=%x", \
                  client, client, timer);

        if (GetRace(client) == raceID)
        {
            new revulsion_level=GetUpgradeLevel(client,raceID,revulsionID);
            if (revulsion_level > 0)
            {
                new health;
                new Float:range = g_RevulsionRange[revulsion_level];
                switch(revulsion_level)
                {
                    case 1: health=0;
                    case 2: health=GetRandomInt(0,1);
                    case 3: health=GetRandomInt(0,3);
                    case 4: health=GetRandomInt(0,5);
                }

                new Float:indexLoc[3];
                new Float:clientLoc[3];
                GetClientAbsOrigin(client, clientLoc);
                clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

                new lightning  = Lightning();
                new haloSprite = HaloSprite();
                static const revulsionColor[4] = {255, 10, 55, 255};

                new count=0;
                new alt_count=0;
                new list[MaxClients+1];
                new alt_list[MaxClients+1];
                new team=GetClientTeam(client);
                for (new index=1;index<=MaxClients;index++)
                {
                    if (index != client && IsClientInGame(index)
                                        && IsPlayerAlive(index))
                    {
                        if (GetClientTeam(index) != team)
                        {
                            if (!IsInvulnerable(index))
                            {
                                GetClientAbsOrigin(index, indexLoc);
                                indexLoc[2] += 50.0;

                                if (IsPointInRange(clientLoc,indexLoc,range) &&
                                    TraceTargetIndex(client, index, clientLoc, indexLoc))
                                {
                                    TE_SetupBeamPoints(clientLoc, indexLoc, lightning, haloSprite,
                                                       0, 1, 3.0, 10.0,10.0,5,50.0,revulsionColor,255);
                                    TE_SendQEffectToAll(client, index);

                                    SlapPlayer(index,health);

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
                    TE_SetupBeamRingPoint(clientLoc, 10.0, range, BeamSprite(), haloSprite,
                                          0, 10, 0.6, 10.0, 0.5, revulsionColor, 10, 0);

                    TE_Send(list, count, 0.0);
                }

                if (alt_count > 0)
                {
                    TE_SetupBeamRingPoint(clientLoc, range-10.0, range, BeamSprite(), haloSprite,
                                          0, 10, 0.6, 10.0, 0.5, revulsionColor, 10, 0);

                    TE_Send(alt_list, alt_count, 0.0);
                }
            }
        }

        TraceReturn();
    }
    return Plugin_Continue;
}

SummonHunter(client)
{
    if (g_hunterRace < 0)
        g_hunterRace = FindRace("titty_hunter");

    if (g_hunterRace < 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceID, hunterID, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "IsNotAvailable", upgradeName);
        LogError("***The Titty Hunter race is not Available!");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        DisplayMessage(client, Display_Ultimate, "%t", "PreventedFromSummoningHunter");
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceID, hunterID))
    {
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        clientLoc[2] += 40.0; // Adjust position to the middle

        TE_SetupSmoke(clientLoc, SmokeSprite(), 8.0, 2);
        TE_SendEffectToAll();

        TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? BlueGlow() : RedGlow(),
                           5.0, 40.0, 255);
        TE_SendEffectToAll();

        ChangeRace(client, g_hunterRace, true, false, true);
    }
}

