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

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/freeze"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";

new raceID, evasionID, thornsID, trueshotID, rootsID;

new bool:m_AllowEntangle[MAXPLAYERS+1];
new Handle:cvarEntangleCooldown = INVALID_HANDLE;

new g_lightningSprite;
new g_haloSprite;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Night Elf",
    author = "PimpinJuice",
    description = "The Night Elf race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
    GetGameType();

    if (!HookEvent("player_spawn",PlayerSpawnEvent,EventHookMode_Post))
        SetFailState("Couldn't hook the player_spawn event.");

    cvarEntangleCooldown=CreateConVar("sc_entangledrootscooldown","45");
}

public OnPluginReady()
{
    raceID      = CreateRace("Night Elf", "nightelf",
                             "You are now a Night Elf.",
                             "You will be a Night Elf when you die or respawn.");

    evasionID   = AddUpgrade(raceID,"Evasion",
                             "Gives you 5-30% chance of evading a shot.");

    thornsID    = AddUpgrade(raceID,"Thorns Aura",
                             "Does 30-90% mirror damage to the person \nwho shot you, chance to activate 15-50%.");

    trueshotID  = AddUpgrade(raceID,"Trueshot Aura",
                             "Does 20-80% extra damage to the \nenemy, chance is 30-60%.");

    rootsID     = AddUpgrade(raceID,"Entangled Roots",
                             "Every enemy in 25-60 feet range will \nnot be able to move for 10 seconds.",
                             true); // Ultimate

    FindUberOffsets();
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
    m_AllowEntangle[client]=true;
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    if (index>0)
    {
        m_AllowEntangle[index]=true;
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
        changed |= Evasion(damage, victim_index, victim_player,
                attacker_index, assister_index);
    }

    if (attacker_index && attacker_index != victim_index)
    {
        new amount = 0;

        if (attacker_race == raceID)
        {
            amount = TrueshotAura(damage, victim_index, victim_player,
                    attacker_index, attacker_player);
            if (amount)
                changed = true;
        }

        if (victim_race == raceID)
        {
            amount += ThornsAura(damage, victim_index, victim_player,
                    attacker_index, attacker_player);
        }

        if (amount)
            changed = true;
    }

    if (assister_index && assister_index != victim_index)
    {
        new amount = 0;
        if (assister_race == raceID)
        {
            amount = TrueshotAura(damage, victim_index, victim_player,
                    assister_index, assister_player);
        }

        if (victim_race == raceID)
        {
            amount += ThornsAura(damage, victim_index, victim_player,
                    assister_index, assister_player);
        }

        if (amount)
            changed = true;
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public bool:Evasion(damage, victim_index, Handle:victim_player, attacker_index, assister_index)
{
    new evasion_level = GetUpgradeLevel(victim_player,raceID,evasionID);
    if (evasion_level)
    {
        new chance;
        switch(evasion_level)
        {
            case 1:
                chance=5;
            case 2:
                chance=15;
            case 3:
                chance=20;
            case 4:
                chance=30;
        }
        if (GetRandomInt(1,100) <= chance)
        {
            new newhp=GetClientHealth(victim_index)+damage;
            new maxhp=GetMaxHealth(victim_index);
            if (newhp > maxhp)
                newhp = maxhp;

            SetEntityHealth(victim_index,newhp);

            LogToGame("[SourceCraft] %N evaded an attack from %N!\n", victim_index, attacker_index);

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

            if (assister_index)
            {
                PrintToChat(assister_index,"%c[SourceCraft] %N %c has %cevaded%c your attack!",
                            COLOR_GREEN,victim_index,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
            }
            return true;
        }
    }
    return false;
}

public ThornsAura(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new thorns_level = GetUpgradeLevel(victim_player,raceID,thornsID);
    if (thorns_level)
    {
        if (!GetImmunity(player,Immunity_HealthTake) && !IsUber(index))
        {
            new chance;
            switch(thorns_level)
            {
                case 1:
                    chance=15;
                case 2:
                    chance=25;
                case 3:
                    chance=35;
                case 4:
                    chance=50;
            }
            if(GetRandomInt(1,100) <= chance)
            {
                new amount=RoundToNearest(damage * GetRandomFloat(0.30,0.90));
                new newhp=GetClientHealth(index)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(victim_index, index, "thorns_aura", "Thorns Aura", amount);
                }
                else
                    LogDamage(victim_index, index, "thorns_aura", "Thorns Aura", amount);

                SetEntityHealth(index,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victim_index, Origin);
                Origin[2] += 5;

                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendToAll();
                return amount;
            }
        }
    }
    return 0;
}

public TrueshotAura(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    // Trueshot Aura
    new trueshot_level=GetUpgradeLevel(player,raceID,trueshotID);
    if (trueshot_level &&
        !GetImmunity(victim_player,Immunity_HealthTake) &&
        !IsUber(victim_index))
    {
        if (GetRandomInt(1,100) <= GetRandomInt(30,60))
        {
            new Float:percent;
            switch(trueshot_level)
            {
                case 1:
                    percent=0.20;
                case 2:
                    percent=0.35;
                case 3:
                    percent=0.60;
                case 4:
                    percent=0.80;
            }

            new amount=RoundFloat(float(damage)*percent);
            if (amount > 0)
            {
                new newhp=GetClientHealth(victim_index)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(index, victim_index, "trueshot_aura", "Trueshot Aura", amount);
                }
                else
                    LogDamage(index, victim_index, "trueshot_aura", "Trueshot Aura", amount);

                SetEntityHealth(victim_index,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victim_index, Origin);
                Origin[2] += 5;

                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendToAll();
                return amount;
            }
        }
    }
    return 0;
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && pressed && IsPlayerAlive(client) &&
        m_AllowEntangle[client])
    {
        new ult_level=GetUpgradeLevel(player,race,rootsID);
        if(ult_level)
        {
            new Float:range=1.0;
            switch(ult_level)
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
            new count=0;
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);
            new maxplayers=GetMaxClients();
            for (new index=1;index<=maxplayers;index++)
            {
                if (client != index && IsClientInGame(index) && IsPlayerAlive(index) &&
                    GetClientTeam(index) != GetClientTeam(client))
                {
                    new Handle:player_check=GetPlayerHandle(index);
                    if (player_check != INVALID_HANDLE)
                    {
                        if (!GetImmunity(player_check,Immunity_Ultimates))
                        {
                            if (IsInRange(client,index,range))
                            {
                                new Float:indexLoc[3];
                                GetClientAbsOrigin(index, indexLoc);
                                if (TraceTarget(client, index, clientLoc, indexLoc))
                                {
                                    new color[4] = { 0, 255, 0, 255 };
                                    TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                      0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                    TE_SendToAll();

                                    PrintToChat(index,"%c[SourceCraft] %N %chas tied you down with %cEntangled Roots.%c",
                                                COLOR_GREEN,client,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    FreezeEntity(index);
                                    AuthTimer(10.0,index,UnfreezePlayer);
                                    count++;
                                }
                            }
                        }
                    }
                }
            }

            new Float:cooldown = GetConVarFloat(cvarEntangleCooldown);
            if (count)
            {
                PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cEntangled Roots%c to ensnare %d enemies, you now need to wait %2.0f seconds before using it again.", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
            }
            else
            {
                PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cEntangled Roots%c without effect, you now need to wait %2.0f seconds before using it again.", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
            }

            if (cooldown > 0.0)
            {
                m_AllowEntangle[client]=false;
                CreateTimer(cooldown,AllowEntangle,client);
            }
        }
    }
}

public Action:AllowEntangle(Handle:timer,any:index)
{
    m_AllowEntangle[index]=true;

    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        if (GetRace(GetPlayerHandle(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cEntangled Roots%c is now available again!",
                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}
