/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossTemplar.sp
 * Description: The Protoss Templar race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/freeze"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";

new raceID, immunityID, levitationID, feedbackID, psionicStormID, hallucinationID, archonID;

new g_lightningSprite;
new g_haloSprite;

new bool:m_AllowPsionicStorm[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Templar",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Templar race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    if (!HookEvent("player_spawn",PlayerSpawnEvent,EventHookMode_Post))
        SetFailState("Couldn't hook the player_spawn event.");
}

public OnPluginReady()
{
    raceID      = CreateRace("Protoss Templar", "templar",
                             "You are now a Protoss Templar.",
                             "You will be a Protoss Templar when you die or respawn.");

    immunityID  = AddUpgrade(raceID,"Immunity", "immunity",
                             "Makes you Immune to: Decloaking at Level 1,\nMotion Taking at Level 2,\nCrystal Theft at level 3,\nand ShopItems at Level 4.");

    levitationID = AddUpgrade(raceID,"Levitation", "levitation",
                              "Allows you to jump higher by \nreducing your gravity by 8-64%.");

    feedbackID  = AddUpgrade(raceID,"Feedback", "feedback",
                             "Gives you 5-50% chance of reflecting a shot back to the attacker.");

    hallucinationID = AddUpgrade(raceID,"Hallucination", "hallucination",
                                 "Enemies that stike you have a chance of experiencing hallucinations.");

    psionicStormID = AddUpgrade(raceID,"Psionic Storm", "psistorm", 
                                "Every enemy in 150-300 feet range will \nbe damaged continously while in range",
                                true); // Ultimate

    archonID = AddUpgrade(raceID,"Summon Archon", "archon", "You become an Archon until you die", true, 15); // Ultimate
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    SetupSound(rechargeWav,true,true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    m_AllowPsionicStorm[client]=true;
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            ResetMaxHealth(client);
            SetGravity(player,-1.0);

            // Turn off Immunities
            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,false);
        }
        else if (race == raceID)
        {
            // Turn on Immunities
            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,true);

            new levitation_level = GetUpgradeLevel(player,race,levitationID);
            if (levitation_level)
                Levitation(client, player, levitation_level);
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && new_level > 0 && GetRace(player) == raceID)
    {
        if (upgrade == immunityID)
            DoImmunity(client, player, new_level,true);
        else if (upgrade==levitationID)
            Levitation(client, player, new_level);
    }
}

public OnItemPurchase(client,Handle:player,item)
{
    new race=GetRace(player);
    if (race == raceID && IsPlayerAlive(client))
    {
        if (item == FindShopItem("sock"))
        {
            new levitation_level = GetUpgradeLevel(player,race,levitationID);
            Levitation(client,player, levitation_level);
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client>0)
    {
        m_AllowPsionicStorm[client]=true;
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            if (GetRace(player) == raceID)
            {
                new immunity_level=GetUpgradeLevel(player,raceID,immunityID);
                if (immunity_level)
                    DoImmunity(client, player, immunity_level,true);

                new levitation_level = GetUpgradeLevel(player,raceID,levitationID);
                if (levitation_level)
                    Levitation(client, player, levitation_level);
            }
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;
    if (victim_race == raceID)
    {
        changed = Feedback(damage, victim_index, victim_player,
                           attacker_index, attacker_player, assister_index);
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public bool:Feedback(damage, victim_index, Handle:victim_player, attacker_index,
                     Handle:attacker_player, assister_index)
{
    new feedback_level = GetUpgradeLevel(victim_player,raceID,feedbackID);
    if (feedback_level)
    {
        new chance;
        switch(feedback_level)
        {
            case 1: chance=15;
            case 2: chance=25;
            case 3: chance=35;
            case 4: chance=50;
        }

        if(GetRandomInt(1,100) <= chance)
        {
            new newhp=GetClientHealth(victim_index)+damage;
            new maxhp=GetMaxHealth(victim_index);
            if (newhp > maxhp)
                newhp = maxhp;

            SetEntityHealth(victim_index,newhp);

            LogToGame("[SourceCraft] Feedback prevented damage to %N from %N!\n",
                      victim_index, attacker_index);

            if (attacker_index && attacker_index != victim_index &&
                !GetImmunity(attacker_player,Immunity_HealthTake) &&
                !TF2_IsPlayerInvuln(attacker_index))
            {
                newhp=GetClientHealth(attacker_index)-damage;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(victim_index, attacker_index, "feedback", "Feedback", damage);
                }
                else
                    LogDamage(victim_index, attacker_index, "feedback", "Feedback", damage);

                SetEntityHealth(attacker_index,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(attacker_index, Origin);
                Origin[2] += 5;

                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendToAll();
                return true;
            }
            else
            {
                if (attacker_index && attacker_index != victim_index)
                {
                    PrintToChat(victim_index,"%c[SourceCraft] you %c have %cevaded%c an attack from %N!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT, attacker_index);
                    PrintToChat(attacker_index,"%c[SourceCraft] %N %c has %cevaded%c your attack!",
                            COLOR_GREEN,victim_index,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    PrintToChat(victim_index,"%c[SourceCraft] you %c have %cevaded%c damage!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
            }

            if (assister_index)
            {
                PrintToChat(assister_index,"%c[SourceCraft] %N %c has %cevaded%c your attack!",
                            COLOR_GREEN,victim_index,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
            }
        }
    }
    return false;
}

DoImmunity(client, Handle:player, level, bool:value)
{
    if (level >= 1)
    {
        SetImmunity(player,Immunity_Uncloaking,value);
        if (level >= 2)
        {
            SetImmunity(player,Immunity_MotionTake,value);
            if (level >= 3)
            {
                SetImmunity(player,Immunity_Theft,value);
                if (level >= 4)
                    SetImmunity(player,Immunity_ShopItems,value);
            }
        }

        if (value)
        {
            new Float:start[3];
            GetClientAbsOrigin(client, start);

            new color[4] = { 0, 255, 50, 128 };
            TE_SetupBeamRingPoint(start,30.0,60.0,g_lightningSprite,g_lightningSprite,
                                  0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
            TE_SendToAll();
        }
    }
}

Levitation(client, Handle:player, level)
{
    if (level > 0)
    {
        new Float:gravity=1.0;
        switch (level)
        {
            case 1:
                gravity=0.92;
            case 2:
                gravity=0.733;
            case 3:
                gravity=0.5466;
            case 4:
                gravity=0.36;
        }

        /* If the Player also has the Sock of the Feather,
         * Decrease the gravity further.
         */
        new sock = FindShopItem("sock");
        if (sock != -1 && GetOwnsItem(player,sock))
        {
            gravity *= 0.8;
        }

        new Float:start[3];
        GetClientAbsOrigin(client, start);

        new color[4] = { 0, 20, 100, 255 };
        TE_SetupBeamRingPoint(start,20.0,50.0,g_lightningSprite,g_lightningSprite,
                              0, 1, 2.0, 60.0, 0.8 ,color, 10, 1);
        TE_SendToAll();

        SetGravity(player,gravity);
    }
    else
        SetGravity(player,-1.0);
}