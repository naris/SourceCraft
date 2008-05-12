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

#include "drug"

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/freeze"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:psistormWav[] = "sourcecraft/ptesto00.wav";
new String:feedbackWav[] = "sourcecraft/mind.wav"; // "sourcecraft/feedback.wav";
new String:hallucinateWav[] = "sourcecraft/ptehal00.wav";
new String:cureWav[] = "sourcecraft/ptehal01.wav";

new String:summonWav[][] = { "sourcecraft/parrdy00.wav",
                             "sourcecraft/parwht03.wav" };

new raceID, immunityID, levitationID, feedbackID, psionicStormID, hallucinationID, archonID;

new g_lightningSprite;
new g_haloSprite;
new g_blueGlow;
new g_redGlow;

new bool:m_AllowArchon[MAXPLAYERS+1];
new bool:m_AllowPsionicStorm[MAXPLAYERS+1];
new gPsionicStormDuration[MAXPLAYERS+1];

new Handle:cvarArchonCooldown = INVALID_HANDLE;
new Handle:cvarPsionicStormCooldown = INVALID_HANDLE;

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

    cvarPsionicStormCooldown=CreateConVar("sc_psionicstormcooldown","30");
    cvarArchonCooldown=CreateConVar("sc_archoncooldown","120");
}

public OnPluginReady()
{
    raceID      = CreateRace("Protoss Templar", "templar",
                             "You are now a Protoss Templar.",
                             "You will be a Protoss Templar when you die or respawn.",
                             48);

    immunityID  = AddUpgrade(raceID,"Immunity", "immunity",
                             "Makes you Immune to: Decloaking at Level 1,\nMotion Taking at Level 2,\nCrystal Theft at level 3,\nand ShopItems at Level 4.");

    levitationID = AddUpgrade(raceID,"Levitation", "levitation",
                              "Allows you to jump higher by \nreducing your gravity by 8-64%.");

    feedbackID  = AddUpgrade(raceID,"Feedback", "feedback",
                             "Gives you 5-50% chance of reflecting a shot back to the attacker.");

    hallucinationID = AddUpgrade(raceID,"Hallucination", "hallucination",
                                 "Gives you a 15-50% chance to cause temporary hallucinations in an enemy.");

    psionicStormID = AddUpgrade(raceID,"Psionic Storm", "psistorm", 
                                "Every enemy in 150-300 feet range will \nbe damaged continously while in range",
                                true); // Ultimate

    archonID = AddUpgrade(raceID,"Summon Archon", "archon", "You become an Archon until you die",
                          true, 12,1); // Ultimate
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_blueGlow = SetupModel("materials/sprites/blueglow1.vmt");
    if (g_blueGlow == -1)
        SetFailState("Couldn't find blueglow Model");

    g_redGlow = SetupModel("materials/sprites/redglow1.vmt");
    if (g_redGlow == -1)
        SetFailState("Couldn't find redglow Model");

    SetupSound(rechargeWav,true,true);
    SetupSound(psistormWav,true,true);
    SetupSound(summonWav[0],true,true);
    SetupSound(summonWav[1],true,true);
}

public OnPlayerAuthed(client,Handle:player)
{
    m_AllowArchon[client]=true;
    m_AllowPsionicStorm[client]=true;
    FindMaxHealthOffset(client);
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

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (pressed && race == raceID && IsPlayerAlive(client))
    {
        new ps_level = GetUpgradeLevel(player,race,psionicStormID);
        if (ps_level)
        {
            if (m_AllowPsionicStorm[client])
                PsionicStorm(player,client,ps_level);
        }
        else if (m_AllowArchon[client])
        {
            new archon_level = GetUpgradeLevel(player,race,archonID);
            if (archon_level)
            {
                new archon_race = FindRace("archon");
                if (archon_race)
                {
                    new Float:cooldown = GetConVarFloat(cvarArchonCooldown);
                    new Float:minutes = cooldown / 60.0;
                    new Float:seconds = FloatFraction(minutes) * 60.0;
                    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cSummon Archon%c to become an Archon, you now need to wait %d:%3.1f before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, RoundToFloor(minutes), seconds);

                    EmitSoundToAll(summonWav[GetRandomInt(0,1)],client);

                    new Float:clientLoc[3];
                    GetClientAbsOrigin(client, clientLoc);
                    clientLoc[2] += 50.0; // Adjust position to the middle
                    TE_SetupGlowSprite(clientLoc,(GetClientTeam(client) == 3) ? g_blueGlow : g_redGlow,
                                       6.0,50.0,255);
                    TE_SendToAll();

                    ChangeRace(player, archon_race, true);
                    CreateTimer(cooldown,AllowArchon,client);
                    m_AllowArchon[client]=false;
                }
            }
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

    if (attacker_index && attacker_index != victim_index)
    {
        if (attacker_race == raceID)
        {
            Hallucinate(victim_index, victim_player,
                        attacker_index, attacker_player);
        }
    }

    if (assister_index && assister_index != victim_index)
    {
        if (assister_race == raceID)
        {
            Hallucinate(victim_index, victim_player,
                        assister_index, assister_player);
        }
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
                HurtPlayer(attacker_index,damage,victim_index,"feedback", "Feedback");

                EmitSoundToAll(feedbackWav,victim_index);

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

public Hallucinate(victim_index, Handle:victim_player, index, Handle:player)
{
    new level = GetUpgradeLevel(victim_player,raceID,hallucinationID);
    if (level)
    {
        new chance;
        switch(level)
        {
            case 1: chance=15;
            case 2: chance=25;
            case 3: chance=35;
            case 4: chance=50;
        }

        if (!GetImmunity(victim_player,Immunity_Blindness))
        {
            if (GetRandomInt(1,100) <= chance)
            {
                if (GetImmunity(victim_player,Immunity_Drugs))
                {
                    PerformBlind(victim_index, 255);
                    CreateTimer(float(level)*2.0,UnblindPlayer,victim_index,TIMER_FLAG_NO_MAPCHANGE);
                }
                else
                {
                    if (PerformDrug(victim_index, 1))
                    {
                        PrintToChat(victim_index,"%c[SourceCraft] %c %N has caused you to %challucinate%c!",
                                COLOR_GREEN,COLOR_DEFAULT,index,COLOR_TEAM,COLOR_DEFAULT);
                        PrintToChat(index,"%c[SourceCraft] %c %N is now %challucinating%c!",
                                COLOR_GREEN,COLOR_DEFAULT,victim_index,COLOR_TEAM,COLOR_DEFAULT);

                        EmitSoundToAll(hallucinateWav,index);
                        CreateTimer(float(level)*2.0,CurePlayer,victim_index,TIMER_FLAG_NO_MAPCHANGE);
                    }
                }
            }
        }
    }
}

public Action:CurePlayer(Handle:timer,any:client)
{
    if(client)
    {
        EmitSoundToAll(cureWav,client);
        PerformDrug(client, 0);
    }
    return Plugin_Stop;
}

public Action:UnblindPlayer(Handle:timer,any:client)
{
    if(client)
    {
        EmitSoundToAll(cureWav,client);
        PerformBlind(client, 0);
    }
    return Plugin_Stop;
}

public PsionicStorm(Handle:player,client,ultlevel)
{
    gPsionicStormDuration[client] = ultlevel*3;

    new Handle:PsionicStormTimer = CreateTimer(0.4, PersistPsionicStorm, client,TIMER_REPEAT);
    TriggerTimer(PsionicStormTimer, true);

    new Float:cooldown = GetConVarFloat(cvarPsionicStormCooldown);

    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %Psionic Storm%c! You now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);

    if (cooldown > 0.0)
    {
        m_AllowPsionicStorm[client]=false;
        CreateTimer(cooldown,AllowPsionicStorm,client);
    }
}

public Action:PersistPsionicStorm(Handle:timer,any:client)
{
    new Handle:player=GetPlayerHandle(client);
    if (player != INVALID_HANDLE)
    {
        new Float:range;
        new level = GetUpgradeLevel(player,raceID,psionicStormID);
        switch(level)
        {
            case 1: range=400.0;
            case 2: range=550.0;
            case 3: range=850.0;
            case 4: range=1000.0;
        }

        EmitSoundToAll(psistormWav,client);

        new Float:indexLoc[3];
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);

        new last=client;
        new minDmg=level*5;
        new maxDmg=level*10;
        new maxplayers=GetMaxClients();
        for(new index=1;index<=maxplayers;index++)
        {
            if (client != index && IsClientInGame(index) && IsPlayerAlive(index) && 
                GetClientTeam(client) != GetClientTeam(index))
            {
                new Handle:player_check=GetPlayerHandle(index);
                if (player_check != INVALID_HANDLE)
                {
                    if (!GetImmunity(player_check,Immunity_Ultimates) &&
                        !GetImmunity(player_check,Immunity_HealthTake) &&
                        !TF2_IsPlayerInvuln(index))
                    {
                        GetClientAbsOrigin(index, indexLoc);
                        if ( IsPointInRange(clientLoc,indexLoc,range))
                        {
                            if (TraceTarget(client, index, clientLoc, indexLoc))
                            {
                                new color[4] = { 10, 200, 255, 255 };
                                TE_SetupBeamLaser(last,index,g_lightningSprite,g_haloSprite,
                                                  0, 1, 10.0, 10.0,10.0,2,50.0,color,255);
                                TE_SendToAll();

                                new amt=GetRandomInt(minDmg,maxDmg);
                                HurtPlayer(index,amt,client,"psistorm", "Psionic Storm");
                                last=index;
                            }
                        }
                    }
                }
            }
        }
        if (--gPsionicStormDuration[client] > 0)
            return Plugin_Continue;
    }
    return Plugin_Stop;
}

public Action:AllowPsionicStorm(Handle:timer,any:index)
{
    m_AllowPsionicStorm[index]=true;
    if (IsClientInGame(index))
    {
        EmitSoundToClient(index, rechargeWav);
        PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cPsionic Storm%c is now available again!",
                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
    }
    return Plugin_Stop;
}

public Action:AllowArchon(Handle:timer,any:index)
{
    m_AllowArchon[index]=true;
    if (IsClientInGame(index))
    {
        EmitSoundToClient(index, rechargeWav);
        PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cSummon Archon%c is now available again!",
                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
    }
    return Plugin_Stop;
}

