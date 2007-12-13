/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source_HumanAlliance.sp
 * Description: The Human Alliance race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>

#include "War3Source/War3Source_Interface"
#include "War3Source/messages"
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
    SetupHealth(client);
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
        HumanAlliance_Invisibility(war3player, newskilllevel);
    }
}

public OnItemPurchase(client,war3player,item)
{
    new race=War3_GetRace(war3player);
    if (race == raceID && IS_ALIVE(client))
    {
        new boots = War3_GetShopItem("Boots of Speed");
        if (boots == item)
        {
            new skill_invis=War3_GetSkillLevel(war3player,race,0);
            HumanAlliance_Invisibility(war3player, skill_invis);
        }
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(client);
    if (war3player>-1)
    {
        new race = War3_GetRace(war3player);
        if (race == raceID)
        {
            new skill_invis=War3_GetSkillLevel(war3player,race,0);
            if (skill_invis)
            {
                HumanAlliance_Invisibility(war3player, skill_invis);
            }

            new skill_devo=War3_GetSkillLevel(war3player,race,1);
            if (skill_devo)
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

    if (client > -1)
    {
        // Reset MaxHealth back to normal
        if (healthIncreased[client] && GameType == tf2)
        {
            SetMaxHealth(client, maxHealth[client]);
            healthIncreased[client] = false;
        }

        // Reset invisibility
        new war3player=War3_GetWar3Player(client);
        if (war3player != -1)
        {
            War3_SetMinVisibility(war3player, 255, 1.0);
        }

    }
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid=GetEventInt(event,"userid");
    if (victimUserid)
    {
        new victimIndex      = GetClientOfUserId(victimUserid);
        new victimWar3player = War3_GetWar3Player(victimIndex);
        if (victimWar3player != -1)
        {
            new attackerUserid = GetEventInt(event,"attacker");
            if (attackerUserid && victimUserid != attackerUserid)
            {
                new attackerIndex      = GetClientOfUserId(attackerUserid);
                new attackerWar3player = War3_GetWar3Player(attackerIndex);
                if (attackerWar3player != -1)
                {
                    if (War3_GetRace(attackerWar3player) == raceID)
                        HumanAlliance_Bash(attackerWar3player, victimIndex);
                }
            }

            new assisterUserid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
            if (assisterUserid != 0)
            {
                new assisterIndex      = GetClientOfUserId(assisterUserid);
                new assisterWar3player = War3_GetWar3Player(assisterIndex);
                if (assisterWar3player != -1)
                {
                    if (War3_GetRace(assisterWar3player) == raceID)
                        HumanAlliance_Bash(assisterWar3player, victimIndex);
                }
            }
        }
    }
}

public HumanAlliance_Invisibility(war3player, skilllevel)
{
    // Invisibility
    new alpha;
    switch(skilllevel)
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

    /* If the Player also has the Boots of Speed,
     * Decrease the visibility further
     */
    new boots = War3_GetShopItem("Boots of Speed");
    if (boots != -1 && War3_GetOwnsItem(war3player,boots))
    {
        alpha /= 2;
    }

    War3_SetMinVisibility(war3player,alpha, 0.50);
}

public HumanAlliance_Bash(war3player, victim)
{
    new skill_bash=War3_GetSkillLevel(war3player,raceID,2);
    if (skill_bash)
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
        if (GetRandomInt(1,100)<=percent)
        {
            FreezeEntity(victim);
            AuthTimer(1.0,victim,UnfreezePlayer);
        }
    }
}

public Action:UnfreezePlayer(Handle:timer,Handle:temp)
{
    Unfreeze(timer, temp);
}
