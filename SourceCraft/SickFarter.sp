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

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/respawn"
#include "sc/weapons"
#include "sc/respawn"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:fart1Wav[] = "sourcecraft/fart.wav";
new String:fart2Wav[] = "sourcecraft/fart3.wav";
new String:fart3Wav[] = "sourcecraft/poot.mp3";

new raceID, festerID, pickPocketID, revulsionID, fartID;

new bool:m_AllowFart[MAXPLAYERS+1];
new gFartDuration[MAXPLAYERS+1];

new Handle:cvarFartCooldown = INVALID_HANDLE;

new g_haloSprite;
new g_smokeSprite;
new g_bubbleModel;
new g_lightningSprite;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Sick Farter",
    author = "Naris",
    description = "The Sick Farter race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://www.jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarFartCooldown=CreateConVar("sc_fartcooldown","30");

    CreateTimer(2.0,Revulsion,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID       = CreateRace("Sick Fucker", "farter",
                              "You are now a Sick Fucker.",
                              "You will be a Sick Fucker when you die or respawn.",
                              16);

    festerID     = AddUpgrade(raceID,"Festering Abomination",
                              "Gives you a 15% chance of doing\n40-240% more damage.");

    pickPocketID = AddUpgrade(raceID,"Pickpocket", "Gives you a 15-80% chance of stealing up to 5-15% of the enemies crystals when you hit them\nAttacking with melee weapons increases the odds and amount of crystals stolen.");

    revulsionID  = AddUpgrade(raceID,"Revulsion",
                              "Your level of Revulsion is so high, all enemies quake as you approach.");

    fartID       = AddUpgrade(raceID,"Flatulence",
                              "Farts a cloud of noxious gasses that\ndamages enemies 150-300 units in range.",
                              true); // Ultimate

    FindUberOffsets();
}

public OnMapStart()
{
    g_bubbleModel = SetupModel("materials/effects/bubble.vmt", true);
    if (g_bubbleModel == -1)
        SetFailState("Couldn't find bubble Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt", true);
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    SetupSound(rechargeWav, true, true);
    SetupSound(fart1Wav, true, true);
    SetupSound(fart2Wav, true, true);
    SetupSound(fart3Wav, true, true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    m_AllowFart[client]=true;
}

public OnRaceSelected(client,Handle:player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
        m_AllowFart[client]=true;
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (pressed && m_AllowFart[client] &&
        race == raceID && IsPlayerAlive(client))
    {
        new fart_level = GetUpgradeLevel(player,race,fartID);
        if (fart_level)
            Fart(player,client,fart_level);
    }
}

// Events
public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    if (attacker_race == raceID && attacker_index != victim_index)
    {
        if (victim_player != INVALID_HANDLE)
            PickPocket(event, victim_index, victim_player, attacker_index, attacker_player);

        if (attacker_player != INVALID_HANDLE)
        {
            if (FesteringAbomination(damage, victim_index, attacker_index, attacker_player))
                changed = true;
        }

    }

    if (assister_race == raceID && assister_index != victim_index)
    {
        if (victim_player != INVALID_HANDLE)
            PickPocket(event, victim_index, victim_player, assister_index, assister_player);

        if (assister_player != INVALID_HANDLE)
        {
            if (FesteringAbomination(damage, victim_index, assister_index, assister_player))
                changed = true;
        }
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public bool:FesteringAbomination(damage, victim_index, index, Handle:player)
{
    new fa_level = GetUpgradeLevel(player,raceID,festerID);
    if (fa_level > 0)
    {
        if (!GetImmunity(player,Immunity_HealthTake) && !IsUber(index))
        {
            new chance;
            switch(fa_level)
            {
                case 1:
                    chance=10;
                case 2:
                    chance=15;
                case 3:
                    chance=20;
                case 4:
                    chance=25;
            }
            if(GetRandomInt(1,100)<=chance)
            {
                new Float:percent;
                switch(fa_level)
                {
                    case 1:
                        percent=0.10;
                    case 2:
                        percent=0.27;
                    case 3:
                        percent=0.47;
                    case 4:
                        percent=0.67;
                }

                new health_take=RoundFloat(float(damage)*percent);
                new new_health=GetClientHealth(victim_index)-health_take;
                if (new_health <= 0)
                {
                    new_health=0;
                    LogKill(index, victim_index, "festering_abomination", "Festering Abomination", health_take);
                }
                else
                    LogDamage(index, victim_index, "festering_abomination", "Festering Abomination", health_take);

                SetEntityHealth(victim_index,new_health);

                new color[4] = { 100, 255, 55, 255 };
                TE_SetupBeamLaser(index,victim_index,g_lightningSprite,g_haloSprite,
                                  0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendToAll();
                return true;
            }
        }
    }
    return false;
}

public PickPocket(Handle:event,victim_index, Handle:victim_player, index, Handle:player)
{
    new pp_level = GetUpgradeLevel(player,raceID,pickPocketID);
    if (pp_level > 0)
    {
        decl String:weapon[64] = "";
        new bool:is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
        new bool:is_melee=IsMelee(weapon, is_equipment);

        new chance;
        switch(pp_level)
        {
            case 1:
                chance=is_melee ? 25 : 15;
            case 2:
                chance=is_melee ? 40 : 25;
            case 3:
                chance=is_melee ? 60 : 40;
            case 4:
                chance=is_melee ? 80 : 60;
        }

        if( GetRandomInt(1,100)<=chance &&
            !GetImmunity(victim_player,Immunity_Theft) &&
            !IsUber(victim_index))
        {
            new victim_cash=GetCredits(victim_player);
            if (victim_cash > 0)
            {
                new Float:percent=GetRandomFloat(0.0,is_melee ? 0.15 : 0.05);
                new cash=GetCredits(player);
                new amount = RoundToCeil(float(victim_cash) * percent);

                SetCredits(victim_player,victim_cash-amount);
                SetCredits(player,cash+amount);

                new color[4] = { 100, 255, 55, 255 };
                TE_SetupBeamLaser(index,victim_index,g_lightningSprite,g_haloSprite,
                                  0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendToAll();

                LogToGame("%N stole %d crystal(s) from %N", index, amount, victim_index);

                PrintToChat(index,"%c[SourceCraft]%c You have stolen %d %s from %N!",
                            COLOR_GREEN,COLOR_DEFAULT,amount,
                            (amount == 1) ? "crystal" : "crystals",
                            victim_index);

                PrintToChat(victim_index,"%c[SourceCraft]%c %N stole %d %s from you!",
                            COLOR_GREEN,COLOR_DEFAULT,index,amount,
                            (amount == 1) ? "crystal" : "crystals");
            }
        }
    }
}

public Fart(Handle:player,client,ultlevel)
{
    gFartDuration[client] = ultlevel*3;

    new Handle:FartTimer = CreateTimer(0.4, PersistFart, client,TIMER_REPEAT);
    TriggerTimer(FartTimer, true);

    new Float:cooldown = GetConVarFloat(cvarFartCooldown);

    PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cFlatulence%c! You now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);

    if (cooldown > 0.0)
    {
        m_AllowFart[client]=false;
        CreateTimer(cooldown,AllowFart,client);
    }
}

public Action:PersistFart(Handle:timer,any:client)
{
    new Handle:player=GetPlayerHandle(client);
    if (player != INVALID_HANDLE)
    {
        new Float:range;
        new fart_level = GetUpgradeLevel(player,raceID,fartID);
        switch(fart_level)
        {
            case 1: range=400.0;
            case 2: range=550.0;
            case 3: range=850.0;
            case 4: range=1000.0;
        }

        switch(GetRandomInt(1,3))
        {
            case 1: EmitSoundToAll(fart1Wav,client);
            case 2: EmitSoundToAll(fart2Wav,client);
            case 3: EmitSoundToAll(fart3Wav,client);
        }

        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);

        new Float:maxLoc[3];
        maxLoc[0] = clientLoc[0] + 256.0;
        maxLoc[1] = clientLoc[1] + 256.0;
        maxLoc[2] = clientLoc[2] + 256.0;

        //new Float:dir[3];
        //dir[0] = 0.0;
        //dir[1] = 0.0;
        //dir[2] = 2.0;
        //TE_SetupDust(clientLoc,dir,range,100.0);
        //TE_SendToAll();

        new bubble_count = RoundToNearest(range/4.0);

        TE_SetupBubbles(clientLoc, maxLoc, g_bubbleModel, range, bubble_count, 2.0);
        TE_SendToAll();

        TE_SetupBubbleTrail(clientLoc, maxLoc, g_bubbleModel, range, bubble_count, 8.0);
        TE_SendToAll();

        TE_SetupSmoke(clientLoc,g_smokeSprite,range,400);
        TE_SendToAll();

        new count=0;
        new num=fart_level*3;
        new minDmg=fart_level*2;
        new maxDmg=fart_level*4;
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
                        !GetImmunity(player_check,Immunity_HealthTake) && !IsUber(index))
                    {
                        if ( IsInRange(client,index,range))
                        {
                            new Float:indexLoc[3];
                            GetClientAbsOrigin(index, indexLoc);
                            if (TraceTarget(client, index, clientLoc, indexLoc))
                            {
                                LogMessage("Farting on %d->%N!", index, index);
                                new amt=GetRandomInt(minDmg,maxDmg);
                                if (HurtPlayer(index,amt,client,"flatulence", "Flatulence", 5+fart_level) <= 0)
                                    LogMessage("Fart killed %d->%N!", index, index);
                                else
                                    LogMessage("Fart damaged %d->%N!", index, index);

                                if (++count > num)
                                    break;
                            }
                            else
                                LogMessage("%d->%N is UnTraceable!", index, index);
                        }
                        else
                            LogMessage("%d->%N is out of range!", index, index);
                    }
                    else
                        LogMessage("%d->%N is immune or ubered!", index, index);
                }
                else
                    LogMessage("%d has no player!", index);
            }
            else
                LogMessage("%d is UnFartable!", index);
        }
        if (--gFartDuration[client] > 0)
        {
            return Plugin_Continue;
        }
    }
    return Plugin_Stop;
}

public Action:AllowFart(Handle:timer,any:index)
{
    if (IsClientInGame(index))
    {
        EmitSoundToClient(index, rechargeWav);
        PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cFlatulence%c is now available again!",
                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
    }
    m_AllowFart[index]=true;
    return Plugin_Stop;
}

public Action:Revulsion(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if (IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceID)
                {
                    new revulsion_level=GetUpgradeLevel(player,raceID,revulsionID);
                    if (revulsion_level)
                    {
                        new num=revulsion_level*3;
                        new Float:range;
                        new health;
                        switch(revulsion_level)
                        {
                            case 1:
                            {
                                range=300.0;
                                health=0;
                            }
                            case 2:
                            {
                                range=450.0;
                                health=GetRandomInt(0,1);
                            }
                            case 3:
                            {
                                range=650.0;
                                health=GetRandomInt(0,3);
                            }
                            case 4:
                            {
                                range=800.0;
                                health=GetRandomInt(0,5);
                            }
                        }
                        new count=0;
                        new Float:clientLoc[3];
                        GetClientAbsOrigin(client, clientLoc);
                        for (new index=1;index<=maxplayers;index++)
                        {
                            if (index != client && IsClientInGame(index))
                            {
                                if (IsPlayerAlive(index) && GetClientTeam(index) != GetClientTeam(client))
                                {
                                    new Handle:player_check=GetPlayerHandle(index);
                                    if (player_check != INVALID_HANDLE)
                                    {
                                        if (IsInRange(client,index,range))
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            if (TraceTarget(client, index, clientLoc, indexLoc))
                                            {
                                                new color[4] = { 255, 10, 55, 255 };
                                                TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                        0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                                TE_SendToAll();

                                                SlapPlayer(index,health);

                                                if (++count > num)
                                                    break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

