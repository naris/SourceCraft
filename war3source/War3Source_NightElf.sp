/**
* vim: set ai et ts=4 sw=4 :
* File: War3Source_NightElf.sp
* Description: The Night Elf race for War3Source.
* Author(s): Anthony Iacono 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"
#include "War3Source/messages"
#include "War3Source/util"
#include "War3Source/freeze"

// War3Source stuff
new raceID; // The ID we are assigned to

new bool:m_AllowEntangle[MAXPLAYERS+1] = {true, ...};
new g_beamSprite;
new g_haloSprite;

public Plugin:myinfo = 
{
    name = "War3Source Race - Night Elf",
    author = "PimpinJuice",
    description = "The Night Elf race for War3Source.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Night Elf",
                           "nightelf",
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

    FindOffsets();
    FindMoveTypeOffset();
}

public OnMapStart()
{
    g_beamSprite    = PrecacheModel("materials/sprites/lgtning.vmt");
    g_haloSprite    = PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client);
    m_AllowEntangle[client]=true;
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if (race==raceID && pressed && IS_ALIVE(client) &&
        m_AllowEntangle[client])
    {
        new ult_level=War3_GetSkillLevel(war3player,race,3);
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
            new maxplayers=GetMaxClients();
            for(new index=1;index<=maxplayers;index++)
            {
                if(IsClientConnected(index)&&client!=index&&IS_ALIVE(index))
                {
                    new bool:inrange=IsInRange(client,index,range);
                    if(inrange)
                    {
                        decl String:name[64];
                        GetClientName(client,name,63);
                        PrintToChat(index,"%c[War3Source] %s %chas tied you down with %cEntangled Roots.%c",
                                    COLOR_GREEN,name,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                        SetEntData(index,movetypeOffset,0,1);
                        AuthTimer(10.0,index,UnfreezePlayer);

                        new color[4] = { 0, 255, 0, 255 };
                        TE_SetupBeamLaser(client,index,g_beamSprite,g_haloSprite,
                                          0, 1, 1.0, 10.0,10.0,45,50.0,color,255);
                        TE_SendToAll();
                    }
                }
            }
            PrintToChat(client,"%c[War3Source]%c You have used your ultimate %cEntangled Roots%c, you now need to wait 45 seconds before using it again.",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
            m_AllowEntangle[client]=false;
            CreateTimer(45.0,AllowEntangle,client);
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    if(index>0)
        m_AllowEntangle[index]=true;
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimuserid = GetEventInt(event,"userid");
    if (victimuserid)
    {
        new victimindex      = GetClientOfUserId(victimuserid);
        new war3playervictim = War3_GetWar3Player(victimindex);
        if (war3playervictim != -1)
        {
            new bool:evaded = false;
            new victimrace = War3_GetRace(war3playervictim);
            if (victimrace == raceID)
            {
                evaded = NightElf_Evasion(event, victimindex, war3playervictim);
            }

            new attackeruserid = GetEventInt(event,"attacker");
            if (attackeruserid && victimuserid != attackeruserid)
            {
                new attackerindex=GetClientOfUserId(attackeruserid);
                new war3playerattacker=War3_GetWar3Player(attackerindex);
                if (war3playerattacker != -1)
                {
                    new damage = 0;
                    if (War3_GetRace(war3playerattacker)==raceID)
                    {
                        damage = NightElf_TrueshotAura(event, war3playerattacker, victimindex, evaded);
                    }

                    if (victimrace == raceID && (!evaded || damage))
                    {
                        NightElf_ThornsAura(event, attackerindex, war3playerattacker,
                                            victimindex, war3playervictim, evaded, damage);
                    }
                }
            }

            new assisteruserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisteruserid && victimuserid != assisteruserid)
            {
                new assisterindex=GetClientOfUserId(assisteruserid);
                new war3playerassister=War3_GetWar3Player(assisterindex);
                if (war3playerassister != -1)
                {
                    new damage = 0;
                    if (War3_GetRace(war3playerassister)==raceID)
                    {
                        damage = NightElf_TrueshotAura(event, war3playerassister, victimindex, evaded);
                    }

                    if (victimrace == raceID && (!evaded || damage))
                    {
                        NightElf_ThornsAura(event, assisterindex, war3playerassister,
                                            victimindex, war3playervictim, evaded, damage);
                    }
                }
            }
        }
    }
}

public bool:NightElf_Evasion(Handle:event, victimIndex, victimWar3player)
{
    new skill_level_evasion = War3_GetSkillLevel(victimWar3player,raceID,0);
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
            new losthp=GetEventInt(event,"damage");
            if (!losthp)
                losthp = GetEventInt(event,"dmg_health");

            new newhp=GetClientHealth(victimIndex)+losthp;
            SetHealth(victimIndex,newhp);

            decl String:victimName[64];
            GetClientName(victimIndex,victimName,63);

            PrintToChat(victimIndex,"%c[War3Source] %s %cyou have evaded an attack!",
                        COLOR_GREEN,victimName,COLOR_DEFAULT);
            LogMessage("[War3Source] %s evaded an attack!\n", victimName);
            return true;
        }
    }
    return false;
}

public NightElf_ThornsAura(Handle:event, index, war3player, victimindex, war3playervictim, evaded, prev_damage)
{
    new skill_level_thorns = War3_GetSkillLevel(war3playervictim,raceID,1);
    if (skill_level_thorns)
    {
        if (!War3_GetImmunity(war3player,Immunity_HealthTake))
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
                new damage=GetEventInt(event,"damage");
                if (!damage)
                    damage = GetEventInt(event,"dmg_health");

                new amount=RoundToNearest((damage + (evaded ? 0 : prev_damage)) * 0.30);
                new newhp=GetClientHealth(index)-amount;
                if(newhp<0)
                    newhp=0;
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

public NightElf_TrueshotAura(Handle:event, war3player, victimindex, evaded)
{
    // Trueshot Aura
    new skill_level_trueshot=War3_GetSkillLevel(war3player,raceID,2);
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

            new damage=GetEventInt(event,"damage");
            if (!damage)
                damage = GetEventInt(event,"dmg_health");

            new amount=RoundFloat(float(damage)*percent);
            new newhp=GetClientHealth(victimindex)-amount;
            if(newhp<0)
                newhp=0;
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

// Misc

public Action:AllowEntangle(Handle:timer,any:index)
{
    m_AllowEntangle[index]=true;
}

public bool:IsInRange(client,index,Float:maxdistance)
{
    new Float:startclient[3];
    new Float:endclient[3];
    GetClientAbsOrigin(client,startclient);
    GetClientAbsOrigin(index,endclient);
    new Float:distance=DistanceBetween(startclient,endclient);
    return (distance<maxdistance);
}

