/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source_HumanAlliance.sp
 * Description: The Human Alliance race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "War3Source/War3Source_Interface"
#include "War3Source/util"

// War3Source stuff
new raceID; // The ID we are assigned to

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
    GetGameType();

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
                           "Allows you to teleport to where you \naim, 60-105 feet being the range.\nNOT IMPLEMENTED YET!");

    FindOffsets();
}

public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client,war3player);
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
                new visibility=140;
                switch(skill_invis)
                {
                    case 1:
                        visibility=158;
                    case 2:
                        visibility=137;
                    case 3:
                        visibility=115;
                    case 4:
                        visibility=94;
                }
                MakeInvisible(client, war3player, visibility);
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
                IncreaseHealth(client,hpadd);
            }
        }
    }
}


public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(client);

    // Reset invisibility
    if(war3player>-1)
        SetRenderColor(client,255,255,255,255);

    // Reset MaxHealth back to normal
    if (healthIncreased[client] && GameType == tf2)
    {
        SetMaxHealth(client, maxHealth[client]);
        healthIncreased[client] = false;
    }
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
