/**
 * vim: set ai et ts=4 sw=4 :
 * File: SickFarter.sp
 * Description: The Sick Farter race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/respawn"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:anxiousWav[] = "misc/anxious.wav";
new String:blowerWav[] = "misc/blower.wav";

new raceID; // The ID we are assigned to

new bool:m_AllowFart[MAXPLAYERS+1];
//new Float:gFartLoc[MAXPLAYERS+1][3];

new Handle:m_Currency   = INVALID_HANDLE; 
new Handle:m_Currencies = INVALID_HANDLE; 
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

public OnConfigsExecuted()
{
    m_Currency = FindConVar("sc_currency");
    if (m_Currency == INVALID_HANDLE)
        SetFailState("Couldn't find sc_currency variable");

    m_Currencies = FindConVar("sc_currencies");
    if (m_Currencies == INVALID_HANDLE)
        SetFailState("Couldn't find sc_currencies variable");
}

public OnPluginStart()
{
    GetGameType();

    cvarFartCooldown=CreateConVar("sc_fartcooldown","30");

    CreateTimer(2.0,Revulsion,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID=CreateRace("Sick Fucker", // Full race name
                      "farter", // SQLite ID name (short name, no spaces)
                      "You are now a Sick Fucker.", // Selected Race message
                      "You will be a Sick Fucker when you die or respawn.", // Selected Race message if you are not allowed until death or respawn
                      "Festering Abomination", //Skill 1 Name
                      "Gives you a 15% chance of doing\n40-240% more damage.", // Skill 1 Description
                      "Pickpocket", // Skill 2 Name
                      "Steals crystals from enemies.", // Skill 2 Description
                      "Revulsion", // Skill 3 Name
                      "Your level of Revulsion is so high, all enemies quake as you approach.", // Skill 3 Description
                      "Flatulence", // Ultimate Name
                      "Farts a cloud of noxious gasses that\ndamages enemies 150-300 units in range.");

    FindUberOffsets();
}

public OnMapStart()
{
    g_bubbleModel = SetupModel("effects/bubbles/bubble.vmt", true);
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

    SetupSound(blowerWav, true, true);
    SetupSound(anxiousWav, true, true);
    SetupSound(rechargeWav, true, true);
}

public OnPlayerAuthed(client,player)
{
    m_AllowFart[client]=true;
}

public OnRaceSelected(client,player,oldrace,newrace)
{
    if (oldrace == raceID && newrace != raceID)
    {
        m_AllowFart[client]=true;
    }
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (pressed && m_AllowFart[client] &&
        race == raceID && IsPlayerAlive(client))
    {
        new skill = GetSkillLevel(player,race,3);
        if (skill)
            Fart(player,client,skill);
    }
}

// Events
public Action:OnPlayerHurtEvent(Handle:event,victim_index,victim_player,victim_race,
                                attacker_index,attacker_player,attacker_race,
                                assister_index,assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    if (attacker_race == raceID && attacker_index != victim_index)
    {
        if (victim_player != -1)
            PickPocket(victim_index, victim_player, attacker_index, attacker_player);

        if (attacker_player != -1)
        {
            if (FesteringAbomination(damage, victim_index, attacker_index, attacker_player))
                changed = true;
        }

    }

    if (assister_race == raceID && assister_index != victim_index)
    {
        if (victim_player != -1)
            PickPocket(victim_index, victim_player, assister_index, assister_player);

        if (assister_player != -1)
        {
            if (FesteringAbomination(damage, victim_index, assister_index, assister_player))
                changed = true;
        }
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public bool:FesteringAbomination(damage, victim_index, index, player)
{
    new skill_cs = GetSkillLevel(player,raceID,0);
    if (skill_cs > 0)
    {
        if (!GetImmunity(player,Immunity_HealthTake) && !IsUber(index))
        {
            new chance;
            switch(skill_cs)
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
                switch(skill_cs)
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

public PickPocket(victim_index, victim_player, index, player)
{
    new skill_pp = GetSkillLevel(player,raceID,1);
    if (skill_pp > 0)
    {
        new chance;
        switch(skill_pp)
        {
            case 1:
                chance=15;
            case 2:
                chance=25;
            case 3:
                chance=40;
            case 4:
                chance=60;
        }
        if(GetRandomInt(1,100)<=chance)
        {
            new Float:percent;
            switch(skill_pp)
            {
                case 1:
                    percent=0.20;
                case 2:
                    percent=0.37;
                case 3:
                    percent=0.63;
                case 4:
                    percent=1.0;
            }

            new victim_cash=GetCredits(victim_player);
            if (victim_cash > 0)
            {
                new cash=GetCredits(player);
                new amount = RoundToCeil(float(victim_cash) * percent);

                SetCredits(victim_player,victim_cash-amount);
                SetCredits(player,cash+amount);

                new color[4] = { 100, 255, 55, 255 };
                TE_SetupBeamLaser(index,victim_index,g_lightningSprite,g_haloSprite,
                                  0, 50, 1.0, 3.0,6.0,50,50.0,color,255);
                TE_SendToAll();

                decl String:currencies[64];
                GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));

                PrintToChat(index,"%c[SourceCraft]%c You have stolen %d %s from %N!",
                            COLOR_GREEN,COLOR_DEFAULT,amount,currencies,victim_index,COLOR_TEAM,COLOR_DEFAULT);
                PrintToChat(victim_index,"%c[SourceCraft]%c %N stole %d %s from you!",
                            COLOR_GREEN,COLOR_DEFAULT,index,amount,currencies);
            }
        }
    }
}

public Fart(player,client,ultlevel)
{
    new num=ultlevel*3;
    new Float:range;
    switch(ultlevel)
    {
        case 1:
            range=300.0;
        case 2:
            range=450.0;
        case 3:
            range=650.0;
        case 4:
            range=800.0;
    }

    EmitSoundToAll(blowerWav,client);

    new Float:clientLoc[3];
    GetClientAbsOrigin(client, clientLoc);

    //gFartLoc[client][0] = clientLoc[0];
    //gFartLoc[client][1] = clientLoc[1];
    //gFartLoc[client][2] = clientLoc[2];

    new Float:maxLoc[3];
    maxLoc[0] = clientLoc[0] + 256.0;
    maxLoc[1] = clientLoc[1] + 256.0;
    maxLoc[2] = clientLoc[2] + 256.0;

    TE_Start("Bubbles");
    TE_WriteVector("m_vecMins", clientLoc);
    TE_WriteVector("m_vecMaxs", maxLoc);
    TE_WriteNum("m_nModelIndex", g_bubbleModel);
    TE_WriteFloat("m_fHeight", 256.0);
    TE_WriteNum("m_nCount", 50);
    TE_WriteFloat("m_fSpeed", 2.0);
    TE_SendToAll();

    TE_Start("Bubble Trail");
    TE_WriteVector("m_vecMins", clientLoc);
    TE_WriteVector("m_vecMaxs", maxLoc);
    TE_WriteNum("m_nModelIndex", g_bubbleModel);
    TE_WriteFloat("m_flWaterZ", 0.0);
    TE_WriteNum("m_nCount", 20);
    TE_WriteFloat("m_fSpeed", 8.0);
    TE_SendToAll();

    TE_SetupSmoke(clientLoc,g_smokeSprite,40.0,50);
    TE_SendToAll();

    TE_SetupSmoke(clientLoc,g_smokeSprite,range,400);
    TE_SendToAll();

    new Float:dir[3];
    dir[0] = 0.0;
    dir[1] = 0.0;
    dir[2] = 2.0;
    TE_SetupDust(clientLoc,dir,range,100.0);
    TE_SendToAll();

    new count=0;
    new maxplayers=GetMaxClients();
    for(new index=1;index<=maxplayers;index++)
    {
        if (client != index && IsClientInGame(index) && IsPlayerAlive(index) && 
            GetClientTeam(client) != GetClientTeam(index))
        {
            new player_check=GetPlayer(index);
            if (player_check>-1)
            {
                if (!GetImmunity(player_check,Immunity_Ultimates) &&
                    !GetImmunity(player_check,Immunity_HealthTake) && !IsUber(index))
                {
                    if ( IsInRange(client,index,range))
                    {
                        new Float:indexLoc[3];
                        GetClientAbsOrigin(client, indexLoc);
                        if (TraceTarget(client, index, clientLoc, indexLoc))
                        {
                            new new_health=GetClientHealth(index)-40;
                            if (new_health <= 0)
                            {
                                new_health=0;

                                new addxp=5+ultlevel;
                                new newxp=GetXP(player,raceID)+addxp;
                                SetXP(player,raceID,newxp);

                                //LogKill(client, index, "flatulence", "Flatulence", 40, addxp);
                                KillPlayer(index);
                            }
                            else
                            {
                                LogDamage(client, index, "flatulence", "Flatulence", 40);
                                HurtPlayer(index, 40, client, "flatulence");
                            }

                            if (++count > num)
                                break;
                        }
                    }
                }
            }
        }
    }
    new Float:cooldown = GetConVarFloat(cvarFartCooldown) * 0.0; // Disable cooldown for now

    if (count)
    {
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cFlatulence%c to damage %d enemies, you now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
    }
    else
    {
        PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cFlatulence%c, which did no damage! You now need to wait %2.0f seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
    }

    if (cooldown > 0.0)
    {
        m_AllowFart[client]=false;
        CreateTimer(cooldown,AllowFart,client);
    }
}

public Action:AllowFart(Handle:timer,any:index)
{
    EmitSoundToClient(index, rechargeWav);
    PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cFlatulence%c is now available again!",
                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
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
                new player=GetPlayer(client);
                if(player>=0 && GetRace(player) == raceID)
                {
                    new skill_revulsion=GetSkillLevel(player,raceID,2);
                    if (skill_revulsion)
                    {
                        new num=skill_revulsion*3;
                        new Float:range;
                        new health;
                        switch(skill_revulsion)
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
                                    new player_check=GetPlayer(index);
                                    if (player_check>-1)
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

