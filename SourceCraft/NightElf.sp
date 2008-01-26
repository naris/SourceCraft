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

#include "SourceCraft/SourceCraft"

#include "SourceCraft/util"
#include "SourceCraft/range"
#include "SourceCraft/trace"
#include "SourceCraft/health"
#include "SourceCraft/freeze"
#include "SourceCraft/authtimer"
#include "SourceCraft/log"

new raceID; // The ID we are assigned to

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

    cvarEntangleCooldown=CreateConVar("sc_entangledrootscooldown","45");

    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnPluginReady()
{
    raceID=CreateRace("Night Elf", "nightelf",
                      "You are now a Night Elf.",
                      "You will be a Night Elf when you die or respawn.",
                      "Evasion",
                      "Gives you 5-30% chance of evading a shot.",
                      "Thorns Aura",
                      "Does 30% mirror damage to the person \nwho shot you, chance to activate 15-50%.",
                      "Trueshot Aura",
                      "Does 10-60% extra damage to the \nenemy, chance is 30%.",
                      "Entangled Roots",
                      "Every enemy in 25-60 feet range will \nnot be able to move for 10 seconds.");

    FindMoveTypeOffset();
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");
}

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
    m_AllowEntangle[client]=true;
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && pressed && IsPlayerAlive(client) &&
        m_AllowEntangle[client])
    {
        new ult_level=GetSkillLevel(player,race,3);
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
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);
            new maxplayers=GetMaxClients();
            for (new index=1;index<=maxplayers;index++)
            {
                if (client != index && IsClientConnected(index) && IsPlayerAlive(index) &&
                    GetClientTeam(index) != GetClientTeam(client))
                {
                    new player_check=GetPlayer(index);
                    if (player_check>-1)
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

                                    decl String:name[64];
                                    GetClientName(client,name,63);
                                    PrintToChat(index,"%c[SourceCraft] %s %chas tied you down with %cEntangled Roots.%c",
                                                COLOR_GREEN,name,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    SetEntData(index,movetypeOffset,0,1);
                                    AuthTimer(10.0,index,UnfreezePlayer);
                                }
                            }
                        }
                    }
                }
            }

            PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cEntangled Roots%c, you now need to wait 45 seconds before using it again.",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

            new Float:cooldown = GetConVarFloat(cvarEntangleCooldown);
            if (cooldown > 0.0)
            {
                m_AllowEntangle[client]=false;
                CreateTimer(cooldown,AllowEntangle,client);
            }
        }
    }
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

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimuserid = GetEventInt(event,"userid");
    if (victimuserid)
    {
        new victimindex      = GetClientOfUserId(victimuserid);
        new playervictim = GetPlayer(victimindex);
        if (playervictim != -1)
        {
            new bool:evaded = false;
            new victimrace = GetRace(playervictim);
            if (victimrace == raceID)
            {
                evaded = NightElf_Evasion(event, victimindex, playervictim);
            }

            new attackeruserid = GetEventInt(event,"attacker");
            if (attackeruserid && victimuserid != attackeruserid)
            {
                new attackerindex = GetClientOfUserId(attackeruserid);
                new playerattacker=GetPlayer(attackerindex);
                if (playerattacker != -1)
                {
                    new damage = 0;
                    if (GetRace(playerattacker)==raceID)
                    {
                        damage = NightElf_TrueshotAura(event, attackerindex,
                                                       playerattacker, victimindex, evaded);
                    }

                    if (victimrace == raceID && (!evaded || damage))
                    {
                        NightElf_ThornsAura(event, attackerindex, playerattacker,
                                            victimindex, playervictim, evaded, damage);
                    }
                }
            }

            new assisteruserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisteruserid && victimuserid != assisteruserid)
            {
                new assisterindex=GetClientOfUserId(assisteruserid);
                new playerassister=GetPlayer(assisterindex);
                if (playerassister != -1)
                {
                    new damage = 0;
                    if (GetRace(playerassister)==raceID)
                    {
                        damage = NightElf_TrueshotAura(event, assisterindex,
                                                       playerassister, victimindex, evaded);
                    }

                    if (victimrace == raceID && (!evaded || damage))
                    {
                        NightElf_ThornsAura(event, assisterindex, playerassister,
                                            victimindex, playervictim, evaded, damage);
                    }
                }
            }
        }
    }
}

public bool:NightElf_Evasion(Handle:event, victimIndex, victimPlayer)
{
    new skill_level_evasion = GetSkillLevel(victimPlayer,raceID,0);
    if (skill_level_evasion)
    {
        new chance;
        switch(skill_level_evasion)
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
            new losthp=GetDamage(event, victimIndex);
            new newhp=GetClientHealth(victimIndex)+losthp;
            new maxhp=GetMaxHealth(victimIndex);
            if (newhp > maxhp)
                newhp = maxhp;

            SetHealth(victimIndex,newhp);

            decl String:victimName[64];
            GetClientName(victimIndex,victimName,63);

            LogMessage("[SourceCraft] %s evaded an attack!\n", victimName);
            PrintToChat(victimIndex,"%c[SourceCraft] %s %c evaded an attack!",
                        COLOR_GREEN,victimName,COLOR_DEFAULT);
            return true;
        }
    }
    return false;
}

public NightElf_ThornsAura(Handle:event, index, player, victimindex, playervictim, evaded, prev_damage)
{
    new skill_level_thorns = GetSkillLevel(playervictim,raceID,1);
    if (skill_level_thorns)
    {
        if (!GetImmunity(player,Immunity_HealthTake))
        {
            new chance;
            switch(skill_level_thorns)
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
                new damage=GetDamage(event, victimindex);
                new amount=RoundToNearest((damage + (evaded ? 0 : prev_damage)) * 0.30);
                new newhp=GetClientHealth(index)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(victimindex, index, "thorns_aura", "Thorns Aura", amount);
                }
                else
                    LogDamage(victimindex, index, "thorns_aura", "Thorns Aura", amount);

                SetHealth(index,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victimindex, Origin);
                Origin[2] += 5;

                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendToAll();
                return amount;
            }
        }
    }
    return 0;
}

public NightElf_TrueshotAura(Handle:event, index, player, victimindex, evaded)
{
    // Trueshot Aura
    new skill_level_trueshot=GetSkillLevel(player,raceID,2);
    if (skill_level_trueshot)
    {
        if (GetRandomInt(1,100) <= (evaded) ? 10 : 30)
        {
            new Float:percent;
            switch(skill_level_trueshot)
            {
                case 1:
                    percent=0.10;
                case 2:
                    percent=0.25;
                case 3:
                    percent=0.40;
                case 4:
                    percent=0.60;
            }

            new damage=GetDamage(event, victimindex);
            new amount=RoundFloat(float(damage)*percent);
            new newhp=GetClientHealth(victimindex)-amount;
            if (newhp <= 0)
            {
                newhp=0;
                LogKill(index, victimindex, "trueshot_aura", "Trueshot Aura", amount);
            }
            else
                LogDamage(index, victimindex, "trueshot_aura", "Trueshot Aura", amount);

            SetHealth(victimindex,newhp);

            new Float:Origin[3];
            GetClientAbsOrigin(victimindex, Origin);
            Origin[2] += 5;

            TE_SetupSparks(Origin,Origin,255,1);
            TE_SendToAll();
            return amount;
        }
    }
    return 0;
}

public Action:AllowEntangle(Handle:timer,any:index)
{
    m_AllowEntangle[index]=true;
    return Plugin_Stop;
}
