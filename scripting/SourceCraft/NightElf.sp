/**
 * vim: set ai et ts=4 sw=4 :
 * File: NightElf.sp
 * Description: The Night Elf race for SourceCraft.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <new_tempents_stocks>
#include <particle>
#include <raytrace>
#include <range>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/maxhealth"
#include "sc/freeze"
#include "sc/sounds"

#include "effect/Lightning"
#include "effect/BeamSprite"
#include "effect/HaloSprite"
#include "effect/SendEffects"
#include "effect/FlashScreen"
#include "effect/TPBeamSprite"

new const String:entangleSound[]="sc/entanglingrootsdecay1.wav";

new g_EvasionChance[]           = { 0, 5, 10, 15, 20 };

new g_ThornsChance[]            = { 0, 5, 10, 15, 20 };
new Float:g_ThornsPercent[]     = { 0.0, 0.05, 0.10, 0.15, 0.20 };

new g_TrueshotChance[]          = { 0, 5, 10, 15, 20 };
new Float:g_TrueshotPercent[]   = { 0.0, 0.05, 0.10, 0.15, 0.20 };

new Float:g_RootsRange[]        = { 0.0, 300.0, 450.0, 650.0, 800.0};

new Float:g_EntangleDuration[]  = { 0.0, 2.0, 5.0, 7.0, 10.0 };

new raceID, evasionID, thornsID, trueshotID, rootsID;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Night Elf",
    author = "-=|JFH|=-Naris with credits to PimpinJuice",
    description = "The Night Elf race for SourceCraft.",
    version = SOURCECRAFT_VERSION,
    url = "http://www.jigglysfunhouse.net/"
};

public OnPluginStart()
{
    LoadTranslations("sc.common.phrases.txt");
    LoadTranslations("sc.nightelf.phrases.txt");
    GetGameType();

    if (IsSourceCraftLoaded())
        OnSourceCraftReady();
}

public OnSourceCraftReady()
{
    raceID      = CreateRace("nightelf", .initial_energy=30.0,
                             .energy_limit=150.0, .faction=NightElf,
                             .type=Biological);

    evasionID   = AddUpgrade(raceID, "evasion", .energy=1.0, .cost_crystals=0);
    thornsID    = AddUpgrade(raceID, "thorns", .energy=2.0, .cost_crystals=10);
    trueshotID  = AddUpgrade(raceID, "trueshot", .energy=1.0, .cost_crystals=10);

    // Ultimate 1
    rootsID     = AddUpgrade(raceID, "roots", 1, .energy=30.0, .cooldown=2.0, .cost_crystals=20);

    // Get Configuration Data

    GetConfigArray("chance", g_EvasionChance, sizeof(g_EvasionChance),
                   g_EvasionChance, raceID, evasionID);

    GetConfigArray("chance", g_ThornsChance, sizeof(g_ThornsChance),
                   g_ThornsChance, raceID, thornsID);

    GetConfigFloatArray("damage_percent",  g_ThornsPercent, sizeof(g_ThornsPercent),
                        g_ThornsPercent, raceID, thornsID);

    GetConfigArray("chance", g_TrueshotChance, sizeof(g_TrueshotChance),
                   g_TrueshotChance, raceID, trueshotID);

    GetConfigFloatArray("damage_percent",  g_TrueshotPercent, sizeof(g_TrueshotPercent),
                        g_TrueshotPercent, raceID, trueshotID);

    GetConfigFloatArray("range",  g_RootsRange, sizeof(g_RootsRange),
                        g_RootsRange, raceID, rootsID);

    GetConfigFloatArray("duration",  g_EntangleDuration, sizeof(g_EntangleDuration),
                        g_EntangleDuration, raceID, rootsID);
}

public OnMapStart()
{
    SetupLightning();
    SetupBeamSprite();
    SetupHaloSprite();
    SetupTPBeamSprite();

    SetupDeniedSound();

    SetupSound(entangleSound);
}

public Action:OnPlayerTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
    if (GetRace(victim) == raceID)
    {
        new evasion_level = GetUpgradeLevel(victim,raceID,evasionID);
        if (evasion_level > 0 &&
            !GetRestriction(victim,Restriction_NoUpgrades) &&
            !GetRestriction(victim,Restriction_Stunned))
        {
            if (GetRandomInt(1,100) <= g_EvasionChance[evasion_level] &&
                CanInvokeUpgrade(victim, raceID, evasionID, .notify=false))
            {
                if (attacker > 0 && attacker <= MaxClients && attacker != victim)
                {
                    DisplayMessage(victim,Display_Defense, "%t", "YouEvadedFrom", attacker);
                    DisplayMessage(attacker,Display_Enemy_Defended, "%t", "HasEvaded", victim);
                }
                else
                {
                    DisplayMessage(victim,Display_Defense, "%t", "YouEvaded");
                }

                if (attacker > 0 && attacker <= MaxClients &&
                    GameType == tf2 && GetMode() != MvM)
                {
                    new entities = EntitiesAvailable(200, .message="Reducing Effects");
                    if (entities > 50)
                    {
                        decl Float:pos[3];
                        GetClientEyePosition(victim, pos);
                        pos[2] += 4.0;
                        TE_SetupParticle("miss_text", pos);
                        TE_SendToClient(attacker);
                    }
                }
                return Plugin_Handled;
            }
        }
    }
    return Plugin_Continue;
}

public Action:OnPlayerHurtEvent(Handle:event, victim_index, victim_race, attacker_index,
                                attacker_race, damage, absorbed, bool:from_sc)
{
    new Action:returnCode = Plugin_Continue;

    if (!from_sc && attacker_index > 0 &&
        attacker_index != victim_index)
    {
        damage += absorbed;

        if (victim_race == raceID)
        {
            if (ThornsAura(event, damage, victim_index, attacker_index))
            {
                returnCode = Plugin_Changed;
            }
        }

        if (attacker_race == raceID)
        {
            if (TrueshotAura(damage, victim_index, attacker_index))
            {
                returnCode = Plugin_Handled;
            }
        }
    }

    return returnCode;
}

public Action:OnPlayerAssistEvent(Handle:event, victim_index, victim_race,
                                  assister_index, assister_race, damage,
                                  absorbed)
{
    if (assister_race == raceID)
    {
        if (TrueshotAura(damage + absorbed, victim_index, assister_index))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public bool:ThornsAura(Handle:event, damage, victim_index, index)
{
    new thorns_level = GetUpgradeLevel(victim_index,raceID,thornsID);
    if (thorns_level > 0)
    {
        if (!GetRestriction(index, Restriction_NoUpgrades) &&
            !GetRestriction(index, Restriction_Stunned) &&
            !GetImmunity(index, Immunity_HealthTaking) &&
            !GetImmunity(index, Immunity_Upgrades) &&
            !IsInvulnerable(index))
        {
            new dmgamt = RoundToNearest(damage * GetRandomFloat(0.30,g_ThornsPercent[thorns_level]));
            if (dmgamt > 0 && GetRandomInt(1,100) <= g_ThornsChance[thorns_level] &&
                CanInvokeUpgrade(index, raceID, thornsID, .notify=false))
            {
                decl Float:indexPos[3];
                GetClientAbsOrigin(index, indexPos); 
                indexPos[2]+=35.0;

                new Float:victimPos[3];
                GetEntityAbsOrigin(victim_index, victimPos);
                victimPos[2] += 40;

                new beamSprite = TPBeamSprite();
                TE_SetupBeamPoints(indexPos, victimPos, beamSprite, beamSprite, 0, 45, 1.0, 10.0, 10.0, 0, 0.5, {255,35,15,255}, 30);
                TE_SendEffectToAll();

                victimPos[2] -= 35; // +5;
                TE_SetupSparks(victimPos,victimPos,255,1);
                TE_SendEffectToAll();

                // reset victimPos to be above indexPos
                victimPos[0]=indexPos[0];
                victimPos[1]=indexPos[1];
                victimPos[2]=indexPos[2] + 80.0;
                TE_SetupBubbles(indexPos, victimPos, HaloSprite(), 35.0,GetRandomInt(6,8),8.0);
                TE_SendEffectToAll();

                FlashScreen(index,RGBA_COLOR_RED);

                HurtPlayer(index, dmgamt, victim_index,
                           "sc_thorns", .in_hurt_event=true);
                return true;
            }
        }
    }
    return false;
}

public bool:TrueshotAura(damage, victim_index, index)
{
    new trueshot_level = GetUpgradeLevel(index,raceID,trueshotID);
    if (trueshot_level > 0 && !IsInvulnerable(victim_index) &&
        !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned) &&
        !GetImmunity(victim_index, Immunity_HealthTaking) &&
        !GetImmunity(victim_index, Immunity_Upgrades))
    {
        if (GetRandomInt(1,100) <= g_TrueshotChance[trueshot_level])
        {
            new dmgamt=RoundFloat(float(damage)*g_TrueshotPercent[trueshot_level]);
            if (dmgamt > 0 && CanInvokeUpgrade(index, raceID,trueshotID, .notify=false))
            {
                new Float:victimPos[3];
                GetEntityAbsOrigin(victim_index, victimPos);
                victimPos[2] += 5;

                FlashScreen(victim_index,RGBA_COLOR_RED);
                TE_SetupSparks(victimPos,victimPos,255,1);
                TE_SendEffectToAll();

                HurtPlayer(victim_index, dmgamt, index,
                           "sc_trueshot", .in_hurt_event=true);
                return true;
            }
        }
    }
    return false;
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (pressed && race==raceID && IsValidClientAlive(client))
    {
        new ult_level=GetUpgradeLevel(client,race,rootsID);
        if (ult_level > 0)
        {
            if (GetRestriction(client,Restriction_NoUltimates) ||
                GetRestriction(client,Restriction_Stunned))
            {
                decl String:upgradeName[64];
                GetUpgradeName(raceID, rootsID, upgradeName, sizeof(upgradeName), client);
                DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
            else if (CanInvokeUpgrade(client, raceID, rootsID))
            {
                if (GameType == tf2)
                {
                    if (TF2_IsPlayerDisguised(client))
                        TF2_RemovePlayerDisguise(client);
                }

                new Float:indexLoc[3];
                new Float:clientLoc[3];
                GetClientAbsOrigin(client, clientLoc);
                clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

                static const beamColor[]        = { 80, 255,  90, 255};
                static const rootsColor[]       = {139, 69,   19, 255};
                static const entangleColor[]    = {  0, 255,   0, 255};
                static const entangleFlash[]    = {  0, 255, 200,  3 };

                new lightning  = Lightning();
                new beamSprite = BeamSprite();
                new haloSprite = HaloSprite();
                new Float:range = g_RootsRange[ult_level];
                new Float:duration = g_EntangleDuration[ult_level];

                new b_count=0;
                new alt_count=0;
                new list[MaxClients+1];
                new alt_list[MaxClients+1];
                SetupOBeaconLists(list, alt_list, b_count, alt_count, client);

                if (b_count > 0)
                {
                    TE_SetupBeamRingPoint(clientLoc, 10.0, range, beamSprite, haloSprite,
                                          0, 15, 0.5, 5.0, 0.0, rootsColor, 10, 0);

                    TE_Send(list, b_count, 0.0);
                }

                if (alt_count > 0)
                {
                    TE_SetupBeamRingPoint(clientLoc, range-10.0, range, beamSprite, haloSprite,
                                          0, 15, 0.5, 5.0, 0.0, rootsColor, 10, 0);

                    TE_Send(alt_list, alt_count, 0.0);
                }


                new bool:playSound = PrepareSound(entangleSound);

                new count = 0;
                new team  = GetClientTeam(client);
                for (new index=1;index<=MaxClients;index++)
                {
                    if (client != index && IsValidClient(index) &&
                        IsPlayerAlive(index) && GetClientTeam(index) != team)
                    {
                        if (!GetImmunity(index,Immunity_Ultimates) &&
                            !GetImmunity(index,Immunity_Restore) &&
                            !GetImmunity(index,Immunity_MotionTaking) &&
                            !IsBurrowed(index))
                        {
                            GetClientAbsOrigin(index, indexLoc);
                            indexLoc[2] += 50.0;

                            if (IsPointInRange(clientLoc,indexLoc,range) &&
                                TraceTargetIndex(client, index, clientLoc, indexLoc))
                            {
                                TE_SetupBeamPoints(clientLoc, indexLoc, lightning, haloSprite,
                                                   0, 1, duration / 2.0, 10.0,10.0,5,50.0,
                                                   entangleColor,255);
                                TE_SendQEffectToAll(client,index);

                                indexLoc[2]-= 35.0; // -50.0 + 15.0
                                TE_SetupBeamRingPoint(indexLoc,45.0,44.0,beamSprite,haloSprite,
                                                      0,15,duration,5.0,0.0, entangleColor,10,0);
                                TE_SendEffectToAll();

                                indexLoc[2]+=15.0;
                                TE_SetupBeamRingPoint(indexLoc,45.0,44.0,beamSprite,haloSprite,
                                                      0,15,duration,5.0,0.0, entangleColor,10,0);
                                TE_SendEffectToAll();

                                indexLoc[2]+=15.0;
                                TE_SetupBeamRingPoint(indexLoc,45.0,44.0,beamSprite,haloSprite,
                                                      0,15,duration,5.0,0.0, entangleColor,10,0);
                                TE_SendEffectToAll();

                                TE_SetupBeamPoints(clientLoc,indexLoc,beamSprite,haloSprite,
                                                   0,50,4.0,6.0,25.0,0,12.0,beamColor,40);
                                TE_SendEffectToAll();

                                FlashScreen(index,entangleFlash);

                                if (playSound)
                                    EmitSoundToAll(entangleSound, index);

                                DisplayMessage(index,Display_Enemy_Ultimate, "%t",
                                               "HasEntangled", client);

                                FreezeEntity(index);
                                CreateTimer(duration,UnfreezePlayer,GetClientUserId(index),
                                            TIMER_FLAG_NO_MAPCHANGE);
                                count++;
                            }
                        }
                    }
                }

                if (count)
                {
                    DisplayMessage(client,Display_Ultimate, "%t",
                                   "ToEntangleEnemies", count);
                }
                else
                {
                    decl String:upgradeName[64];
                    GetUpgradeName(raceID, rootsID, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client,Display_Ultimate, "%t", "WithoutEffect", upgradeName);
                }

                CreateCooldown(client, raceID, rootsID);
            }
        }
    }
}
