/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_HumanAlliance.sp
 * Description: The Human Alliance race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/health"
#include "War3Source/freeze"
#include "War3Source/authtimer"

#define TELEPORT_RANGE 600

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
                           "Allows you to teleport to where you \naim, 60-105 feet being the range.");

    FindMoveTypeOffset();
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
    if (race==raceID && IsPlayerAlive(client))
    {
        new Float:clientloc[3],Float:clientang[3],Float:destloc[3];
        GetClientEyePosition(client,clientloc); // Get the position of the player's eyes
        GetClientEyeAngles(client,clientang); // Get the angle the player is looking
        TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite,TraceRayTryToHit); // Create a ray that tells where the player is looking
        TR_GetEndPosition(destloc); // Get the end xyz coordinate of where a player is looking

        new Float:save[3];
        save[0] = destloc[0];
        save[1] = destloc[1];
        save[2] = destloc[2];

        new Float:distance[3];
        distance[0] = destloc[0]-clientloc[0];
        distance[1] = destloc[1]-clientloc[1];
        distance[2] = destloc[2]-clientloc[2];
        if (distance[0] < 0)
            distance[0] *= -1;
        if (distance[1] < 0)
            distance[1] *= -1;
        if (distance[2] < 0)
            distance[2] *= -1;

        // Linit the teleport location to remain within the TELEPORT_RANGE
        for (new i = 0; i<=2; i++)
        {
            if (distance[i] > TELEPORT_RANGE)
            {
                if (clientloc[i] >= 0)
                {
                    if (destloc[i] >= 0)
                    {
                        if (clientloc[i] <= destloc[i])
                            destloc[i] = clientloc[i] + TELEPORT_RANGE;
                        if (clientloc[i] > destloc[i])
                            destloc[i] = clientloc[i] - TELEPORT_RANGE;
                    }
                    else
                        destloc[i] = clientloc[i] - TELEPORT_RANGE;
                }
                else
                {
                    if (destloc[i] < 0)
                    {
                        if (clientloc[i] <= destloc[i])
                            destloc[i] = clientloc[i] + TELEPORT_RANGE;
                        if (clientloc[i] > destloc[i])
                            destloc[i] = clientloc[i] - TELEPORT_RANGE;
                    }
                    else
                        destloc[i] = clientloc[i] + TELEPORT_RANGE;
                }
            }
        }

        LogMessage("start=(%1.0f,%1.0f,%1.0f);",
                   clientloc[0], clientloc[1], clientloc[2]);
        LogMessage("end=(%1.0f,%1.0f,%1.0f);",
                   save[0], save[1], save[2]);
        LogMessage("dest=(%1.0f,%1.0f,%1.0f)",
                   destloc[0],destloc[1],destloc[2]);

        PrintToChat(client,"%c[War3Source]%c start=(%1.0f,%1.0f,%1.0f);",
                    COLOR_GREEN,COLOR_DEFAULT,clientloc[0], clientloc[1], clientloc[2]);

        PrintToChat(client,"%c[War3Source]%c end=(%1.0f,%1.0f,%1.0f);",
                    COLOR_GREEN,COLOR_DEFAULT, save[0], save[1], save[2]);

        PrintToChat(client,"%c[War3Source]%c dest=(%1.0f,%1.0f,%1.0f)",
                    COLOR_GREEN,COLOR_DEFAULT, destloc[0],destloc[1],destloc[2]);

        TeleportEntity(client,destloc,NULL_VECTOR,NULL_VECTOR);
        EmitSoundToAll("beams/beamstart5.wav",client);
    }
}

public OnSkillLevelChanged(client,war3player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && skill==0 && newskilllevel > 0 &&
       War3_GetRace(war3player) == raceID && IsPlayerAlive(client))
    {
        HumanAlliance_Invisibility(war3player, newskilllevel);
    }
}

public OnItemPurchase(client,war3player,item)
{
    new race=War3_GetRace(war3player);
    if (race == raceID && IsPlayerAlive(client))
    {
        new cloak = War3_GetShopItem("Cloak of Shadows");
        if (cloak == item)
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

    /* If the Player also has the Cloak of Shadows,
     * Decrease the visibility further
     */
    new cloak = War3_GetShopItem("Cloak of Shadows");
    if (cloak != -1 && War3_GetOwnsItem(war3player,cloak))
    {
        alpha *= 0.75;
    }

    War3_SetMinVisibility(war3player,alpha, 0.75);
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

/***************
 *Trace Filters*
****************/

public bool:TraceRayTryToHit(entity,mask)
{
  return !(entity > 0 && entity <= 64); // Check if the beam hit a player and tell it to keep tracing if it did
}
