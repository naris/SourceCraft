/**
 * File: War3Source_UndeadScourge.sp
 * Description: The Undead Scourge race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "War3Source/War3Source_Interface"
#include <sdktools>

// Defines
#define MAX_PLAYERS 64
#define IS_ALIVE !GetLifestate

// War3Source stuff
new raceID; // The ID we are assigned to
new healthOffset[MAX_PLAYERS+1];
new lifestateOffset;
new explosionModel;

// Suicide bomber check
new bool:m_Suicided[MAX_PLAYERS+1]={false};

public Plugin:myinfo = 
{
    name = "War3Source Race - Undead Scourge",
    author = "PimpinJuice",
    description = "The Undead Scourge race for War3Source.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

// War3Source Functions
public OnPluginStart()
{
    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);
}

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Undead Scourge","undead","You are now an Undead Scourge.","You will be an Undead Scourge when you die or respawn.","Vampiric Aura","Gives you a 60% chance to gain 12-30% of the\ndamage you did in attack, back as health. It can\nbe blocked if the player is immune.","Unholy Aura","Gives you a speed boost, 8-36% faster.","Levitation","Allows you to jump higher by \nreducing your gravity by 8-64%.","Suicide Bomber","Use your ultimate bind to explode\nand damage the surrounding players extremely,\nwill automatically activate on death.");
    lifestateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
    explosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
}

public OnMapStart()
{
    PrecacheSound("weapons/explode5.wav",false);
}

public OnWar3PlayerAuthed(client,war3player)
{
    healthOffset[client]=FindDataMapOffs(client,"m_iHealth");
}

public Float:DistanceBetween(Float:a[3],Float:b[3])
{
    return SquareRoot((a[0]-b[0])*(a[0]-b[0])+(a[1]-b[1])*(a[1]-b[1])+(a[2]-b[2])*(a[2]-b[2]));
}

public PowerOfRange(Float:location[3],Float:radius,Float:check_location[3])
{
    new Float:distance=DistanceBetween(location,check_location);
    new Float:healthtakeaway=0.0;
    if(distance<radius)
        healthtakeaway=1-FloatDiv(distance,radius)+0.20;
    return RoundFloat(100*healthtakeaway);
}

// Stocks
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // Actually red for DOD
stock War3Source_ChatMessage(target,color,const String:szMsg[],any:...)
{
    if(strlen(szMsg)>191)
    {
        LogError("Disallow string len(%d)>191",strlen(szMsg));
        return;
    }
    decl String:buffer[192];
    VFormat(buffer,sizeof(buffer),szMsg,4);
    Format(buffer,191,"%s\n",buffer);
    new Handle:hBf;
    if(target==0)
        hBf=StartMessageAll("SayText");
    else
        hBf=StartMessageOne("SayText",target);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, 0); 
        BfWriteString(hBf, buffer);
        EndMessage();
    }
}

public GetLifestate(client)
{
    return GetEntData(client,lifestateOffset,1);
}

public Undead_SuicideBomber(client,war3player,race,ult_level)
{
    new Float:radius=0.0;
    new r_int;
    switch(ult_level)
    {
        case 1:
        {
            radius=200.0;
            r_int=200;
        }
        case 2:
        {
            radius=250.0;
            r_int=250;
        }
        case 3:
        {
            radius=300.0;
            r_int=300;
        }
        case 4:
        {
            radius=350.0;
            r_int=350;
        }
    }
    new Float:client_location[3];
    GetClientAbsOrigin(client,client_location);
    for(new x=1;x<MAX_PLAYERS+1;x++)
    {
        if(x<=GetClientCount()&&IsClientConnected(x))
        {
            TE_SetupExplosion(client_location,explosionModel,10.0,30,0,r_int,20);
            TE_SendToAll();
            EmitSoundToAll("weapons/explode5.wav",client);
            if(x!=client&&IS_ALIVE(x))
            {
                new war3player_check=War3_GetWar3Player(x);
                if(war3player_check>-1)
                {
                    if(!War3_GetImmunity(war3player_check,Immunity_Ultimates)&&!War3_GetImmunity(war3player_check,Immunity_Explosion))
                    {
                        new Float:location_check[3];
                        GetClientAbsOrigin(x,location_check);
                        new hp=PowerOfRange(client_location,radius,location_check);
                        new newhealth=GetClientHealth(x)-hp;
                        SetHealth(x,newhealth);
                        if(newhealth<=0)
                        {
                            FakeClientCommand(x,"kill\n");
                            if(GetClientTeam(client)!=GetClientTeam(x))
                            {
                                new addxp;
                                new level=War3_GetLevel(war3player,race);
                                addxp=5+level;
                                new newxp=War3_GetXP(war3player,race)+addxp;
                                War3_SetXP(war3player,race,newxp);
                                War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou gained %d XP for killing someone with a suicide bomb.",COLOR_GREEN,COLOR_DEFAULT,addxp);
                            }
                        }
                    }
                }
            }
        }
    }
    m_Suicided[client]=true;
    FakeClientCommand(client,"kill\n");
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if(pressed)
    {
        if(race==raceID&&IS_ALIVE(client))
        {
            new ult_level=War3_GetSkillLevel(war3player,race,3);
            if(ult_level)
                Undead_SuicideBomber(client,war3player,race,ult_level);
        }
    }
}

public OnSkillLevelChanged(client,war3player,race,skill,oldskilllevel,newskilllevel)
{
    if(War3_GetRace(war3player)==raceID)
    {
        if(race==raceID&&skill==1)
        {
            new Float:speed=1.0;
            switch(newskilllevel)
            {
                case 1:
                    speed=1.08;
                case 2:
                    speed=1.1733;
                case 3:
                    speed=1.266;
                case 4:
                    speed=1.36;
            }
            War3_SetMaxSpeed(war3player,speed);
        }
        else if(race==raceID&&skill==2)
        {
            new Float:gravity=1.0;
            switch(newskilllevel)
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
            War3_SetMinGravity(war3player,gravity);
        }
    }
}

public OnRaceSelected(client,war3player,oldrace,newrace)
{
    if(oldrace==raceID&&newrace!=raceID)
    {
        War3_SetMaxSpeed(war3player,1.0);
        War3_SetMinGravity(war3player,1.0);
    }
}

// Generic
public SetHealth(entity,amount)
{
    SetEntData(entity,healthOffset[entity],amount,true);
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new attacker_userid=GetEventInt(event,"attacker");
    if(userid&&attacker_userid&&userid!=attacker_userid)
    {
        new index=GetClientOfUserId(userid);
        new attacker_index=GetClientOfUserId(attacker_userid);
        new war3player=War3_GetWar3Player(index);
        new war3player_attacker=War3_GetWar3Player(attacker_index);
        if(war3player!=-1&&war3player_attacker!=-1)
        {
            new race_attacker=War3_GetRace(war3player_attacker);
            if(race_attacker==raceID)
            {
                new skill_attacker=War3_GetSkillLevel(war3player_attacker,race_attacker,0);
                if(skill_attacker>0&&GetRandomInt(1,10)<=6&&!War3_GetImmunity(war3player,Immunity_HealthTake))
                {
                    new Float:percent_health;
                    switch(skill_attacker)
                    {
                        case 1:
                            percent_health=0.12;
                        case 2:
                            percent_health=0.18;
                        case 3:
                            percent_health=0.24;
                        case 4:
                            percent_health=0.30;
                    }
                    new Float:damage=float(GetEventInt(event,"dmg_health"));
                    new leechhealth=RoundFloat(damage*percent_health);
                    if(leechhealth)
                    {
                        new newhealth=GetClientHealth(index)-leechhealth;
                        if(newhealth<0)
                            newhealth=0;
                        SetHealth(index,newhealth);
                        new newhealth_attacker=GetClientHealth(attacker_index)+leechhealth;
                        SetHealth(attacker_index,newhealth_attacker);
                    }
                }
            }
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(index);
    if(war3player>-1)
    {
        m_Suicided[index]=false;
        new race=War3_GetRace(war3player);
        if(race==raceID)
        {
            new skilllevel_unholy=War3_GetSkillLevel(war3player,race,1);
            if(skilllevel_unholy)
            {
                new Float:speed=1.0;
                switch(skilllevel_unholy)
                {
                    case 1:
                        speed=1.08;
                    case 2:
                        speed=1.1733;
                    case 3:
                        speed=1.266;
                    case 4:
                        speed=1.36;
                }
                War3_SetMaxSpeed(war3player,speed);
            }
            new skilllevel_levi=War3_GetSkillLevel(war3player,race,2);
            if(skilllevel_levi)
            {
                new Float:gravity=1.0;
                switch(skilllevel_levi)
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
                War3_SetMinGravity(war3player,gravity);
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(index);
    if(war3player>-1&&!m_Suicided[index])
    {
        new race=War3_GetRace(war3player);
        if(race==raceID)
        {
            new ult_level=War3_GetSkillLevel(war3player,race,3);
            if(ult_level)
                Undead_SuicideBomber(index,war3player,race,ult_level);
        }
    }
}