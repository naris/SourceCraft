/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source_HumanAlliance.sp
 * Description: The Human Alliance race for War3Source.
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
new colorOffset;
new renderModeOffset;
new movetypeOffset;
new healthOffset[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "War3Source Race - Human Alliance",
    author = "PimpinJuice",
    description = "The Human Alliance race for War3Source.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_hurt",PlayerHurtEvent);
}

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Human Alliance",
                           "human",
                           "You are now part of the Human Alliance.",
                           "You will be part of the Human Alliance when you die or respawn.",
                           "Invisibility",
                           "Makes you partially invisible, \n62% visibility - 37% visibility.",
                           "Devotion Aura",
                           "Gives you additional 15-50 health each round.",
                           "Bash",
                           "Have a 15-32% chance to render an \nenemy immobile for 1 second.",
                           "Teleport",
                           "Allows you to teleport to where you \naim, 60-105 feet being the range.");

    lifestateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
    if(lifestateOffset==-1)
        SetFailState("Couldn't find LifeState offset");

    movetypeOffset=FindSendPropOffs("CBaseEntity","movetype");
    if(movetypeOffset==-1)
        SetFailState("Couldn't find MoveType offset");

    colorOffset=FindSendPropOffs("CAI_BaseNPC","m_clrRender");
    if(colorOffset==-1)
        SetFailState("Couldn't find Color offset");

    renderModeOffset=FindSendPropOffs("CBaseAnimating","m_nRenderMode");
    if(renderModeOffset==-1)
        SetFailState("Couldn't find RenderMode offset");
}

public OnWar3PlayerAuthed(client,war3player)
{
    healthOffset[client]=FindDataMapOffs(client,"m_iHealth");
}

public OnRaceSelected(client,war3player,oldrace,race)
{
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    PrintToChat(client,"%c[War3Source]%c DOH! Teleport has not been implemented yet!",COLOR_GREEN,COLOR_DEFAULT);
}

public OnSkillLevelChanged(client,war3player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && skill==0 && newskilllevel > 0 &&
       War3_GetRace(war3player) == raceID && IS_ALIVE(client))
    {
        // Invisibility
        new alpha;
        switch(newskilllevel)
        {
            case 1:
                alpha=158;
            case 2:
                alpha=137;
            case 3:
                alpha=115;
            case 4:
                alpha=94;
        }
        SetRenderColor(client,255,255,255,alpha);
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(client);
    if(war3player>-1)
    {
        new race=War3_GetRace(war3player);
        if(race==raceID)
        {
            new skill_invis=War3_GetSkillLevel(war3player,race,0);
            if(skill_invis)
            {
                // Invisibility
                new alpha;
                switch(skill_invis)
                {
                    case 1:
                        alpha=158;
                    case 2:
                        alpha=137;
                    case 3:
                        alpha=115;
                    case 4:
                        alpha=94;
                }
                SetRenderColor(client,255,255,255,alpha);
            }
            new skill_devo=War3_GetSkillLevel(war3player,race,1);
            if(skill_devo)
            {
                // Devotion Aura
                new hpadd;
                switch(skill_devo)
                {
                    case 1:
                        hpadd=15;
                    case 2:
                        hpadd=26;
                    case 3:
                        hpadd=38;
                    case 4:
                        hpadd=50;
                }
                SetHealth(client,GetClientHealth(client)+hpadd);
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(client);
    if(war3player>-1)
        SetRenderColor(client,255,255,255,255);
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new attacker_userid=GetEventInt(event,"attacker");
    if(userid && attacker_userid && userid!=attacker_userid)
    {
        new index=GetClientOfUserId(userid);
        new attacker_index=GetClientOfUserId(attacker_userid);
        new war3player=War3_GetWar3Player(index);
        new war3player_attacker=War3_GetWar3Player(attacker_index);
        if(war3player != -1 && war3player_attacker != -1)
        {
            new race=War3_GetRace(war3player_attacker);
            if(race == raceID)
            {
                new skill_bash=War3_GetSkillLevel(war3player_attacker,race,2);
                if(skill_bash)
                {
                    // Bash
                    new percent;
                    switch(skill_bash)
                    {
                        case 1:
                            percent=15;
                        case 2:
                            percent=21;
                        case 3:
                            percent=27;
                        case 4:
                            percent=32;
                    }
                    if(GetRandomInt(1,100)<=percent)
                    {
                        FreezeEntity(index);
                        AuthTimer(1.0,index,UnfreezePlayer);
                    }
                }
            }
        }
    }
}

// Misc stuff
public Action:UnfreezePlayer(Handle:timer,Handle:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
        UnFreezeEntity(client);
    ClearArray(temp);
}

public AuthTimer(Float:delay,index,Timer:func)
{
    new Handle:temp=CreateArray(ByteCountToCells(64));
    decl String:auth[64];
    GetClientAuthString(index,auth,63);
    PushArrayString(temp,auth);
    CreateTimer(delay,func,temp);
}

public SetHealth(entity,amount)
{
    SetEntData(entity,healthOffset[entity],amount,1);
}

public GetLifestate(client)
{
    return GetEntData(client,lifestateOffset,1);
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

stock FreezeEntity(entity)
{
    SetEntData(entity,movetypeOffset,0,1);
}

stock UnFreezeEntity(entity)
{
    SetEntData(entity,movetypeOffset,2,1);
}

public SetRenderColor(client,r,g,b,a)
{
	if(colorOffset != -1)
    {
        SetEntData(client,colorOffset,r,1,true);
        SetEntData(client,colorOffset+1,g,1,true);
        SetEntData(client,colorOffset+2,b,1,true);
        SetEntData(client,colorOffset+3,a,1,true);

        if(renderModeOffset != -1)
            SetEntData(client,renderModeOffset,3,1,true);
    }
}
