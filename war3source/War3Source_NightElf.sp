/**
* vim: set ai et ts=4 sw=4 syntax=cpp :
* File: War3Source_NightElf.sp
* Description: The Night Elf race for War3Source.
* Author(s): Anthony Iacono 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "War3Source/War3Source_Interface"

// Defines
#define IS_ALIVE !GetLifestate

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // DOD = Red

// War3Source stuff
new raceID; // The ID we are assigned to
new lifestateOffset;
new movetypeOffset;
new healthOffset[MAXPLAYERS+1];
new bool:m_AllowEntangle[MAXPLAYERS+1];
 
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

    lifestateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
    if(lifestateOffset==-1)
        SetFailState("Couldn't find LifeState offset");

    movetypeOffset=FindSendPropOffs("CAI_BaseNPC","movetype");
    if(movetypeOffset==-1)
        SetFailState("Couldn't find MoveType offset");
}

public OnWar3PlayerAuthed(client,war3player)
{
    healthOffset[client]=FindDataMapOffs(client,"m_iHealth");
    m_AllowEntangle[client]=true;
}

public GetLifestate(client)
{
    return GetEntData(client,lifestateOffset,1);
}

public SetHealth(entity,amount)
{
    SetEntData(entity,healthOffset[entity],amount,true);
}
 
public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if(race==raceID&&pressed&&IS_ALIVE(client)&&m_AllowEntangle[client])
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
                        PrintToChat(index,"%c[War3Source] %s %chas tied you down with %cEntangled Roots.%c",COLOR_GREEN,name,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                        SetEntData(index,movetypeOffset,0,1);
                        AuthTimer(10.0,index,Unfreeze);
                    }
                }
            }
            PrintToChat(client,"%c[War3Source]%c You have used your ultimate \"Entangled Roots\", you now need to wait 45 seconds before using it again.",COLOR_GREEN,COLOR_DEFAULT);
            m_AllowEntangle[client]=false;
            CreateTimer(45.0,AllowEntangle,client);
        }
    }
}

public Action:Unfreeze(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
        SetEntData(client,movetypeOffset,2,1);
    ClearArray(temp);
}

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
    new Float:distance=GetDistanceBetween(startclient,endclient);
    return (distance<maxdistance);
}

public Float:GetDistanceBetween(Float:startvec[3],Float:endvec[3])
{
    return SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+(startvec[1]-endvec[1])*(startvec[1]-endvec[1])+(startvec[2]-endvec[2])*(startvec[2]-endvec[2]));
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
    new victimuserid=GetEventInt(event,"userid");
    new attackeruserid=GetEventInt(event,"attacker");
    if(victimuserid&&attackeruserid&&victimuserid!=attackeruserid)
    {
        new victimindex=GetClientOfUserId(victimuserid);
        new attackerindex=GetClientOfUserId(attackeruserid);
        new war3playervictim=War3_GetWar3Player(victimindex);
        new war3playerattacker=War3_GetWar3Player(attackerindex);
        if(war3playervictim!=-1&&war3playerattacker!=-1)
        {
            if(War3_GetRace(war3playervictim)==raceID)
            {
                new skill_level_evasion=War3_GetSkillLevel(war3playervictim,raceID,0);
                new skill_level_thorns=War3_GetSkillLevel(war3playervictim,raceID,1);
                // Evasion
                if(skill_level_evasion)
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
                    if(GetRandomInt(1,100)<=chance)
                    {
                        new losthp=GetEventInt(event,"dmg_health");
                        new newhp=GetClientHealth(victimindex)+losthp;
                        SetHealth(victimindex,newhp);
                    }
                }
                // Thorns Aura
                if(skill_level_thorns)
                {
                    if(!War3_GetImmunity(war3playerattacker,Immunity_HealthTake))
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
                        if(GetRandomInt(1,100)<=chance)
                        {
                            new damage=RoundToNearest(GetEventInt(event,"dmg_health")*0.30);
                            new newhp=GetClientHealth(attackerindex)-damage;
                            if(newhp<0)
                                newhp=0;
                            SetHealth(attackerindex,newhp);
                        }
                    }
                }
            }
            if(War3_GetRace(war3playerattacker)==raceID)
            {
                new skill_level_trueshot=War3_GetSkillLevel(war3playerattacker,raceID,2);
                // Trueshot Aura
                if(skill_level_trueshot)
                {
                    if(GetRandomInt(1,100)<=30)
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
                        new damage=RoundFloat(float(GetEventInt(event,"dmg_health"))*percent);
                        new newhp=GetClientHealth(victimindex)-damage;
                        if(newhp<0)
                            newhp=0;
                        SetHealth(victimindex,newhp);
                    }
                }
            }
        }
    }
}

// Misc
public AuthTimer(Float:delay,index,Timer:func)
{
    new Handle:temp=CreateArray(ByteCountToCells(64));
    decl String:auth[64];
    GetClientAuthString(index,auth,63);
    PushArrayString(temp,auth);
    CreateTimer(delay,func,temp);
}

stock PlayerOfAuth(const String:auth[])
{
    new max=GetMaxClients();
    decl String:authStr[64];
    for(new x=1;x<=max;x++)
    {
        if(IsClientConnected(x))
        {
            GetClientAuthString(x,authStr,63);
            if(StrEqual(auth,authStr))
                return x;
        }
    }
    return 0;
}
