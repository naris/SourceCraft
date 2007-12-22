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
#include "War3Source/messages"
#include "War3Source/util"
#include "War3Source/freeze"

// War3Source stuff
new raceID; // The ID we are assigned to

// Offset variables
new GetVelocityOffset_0;
new GetVelocityOffset_1;
new GetVelocityOffset_2;

// SDK Handles
new Handle:hHGRConf;
new Handle:hEyePosition;
new Handle:hEyeAngles;

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

    hHGRConf=LoadGameConfigFile("plugin.hgrsource"); // Game configuration file

    // Find offsets
    GetVelocityOffset_0=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    if(GetVelocityOffset_0==-1)
        SetFailState("[HGR:Source] Error: Failed to find the GetVelocity_0 offset, aborting");

    GetVelocityOffset_1=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
    if(GetVelocityOffset_1==-1)
        SetFailState("[HGR:Source] Error: Failed to find the GetVelocity_1 offset, aborting");

    GetVelocityOffset_2=FindSendPropOffs("CBasePlayer","m_vecVelocity[2]");
    if(GetVelocityOffset_2==-1)
        SetFailState("[HGR:Source] Error: Failed to find the GetVelocity_2 offset, aborting");

    // EyePosition SDK call
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hHGRConf,SDKConf_Virtual,"EyePosition");
    PrepSDKCall_SetReturnInfo(SDKType_QAngle,SDKPass_ByValue);
    hEyePosition=EndPrepSDKCall();

    // EyeAngles SDK call
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hHGRConf,SDKConf_Virtual,"EyeAngles");
    PrepSDKCall_SetReturnInfo(SDKType_QAngle,SDKPass_ByValue);
    hEyeAngles=EndPrepSDKCall();
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
        new Float:clientloc[3],Float:clientang[3],Float:teleportloc[3];
        GetEyePosition(client,clientloc); // Get the position of the player's eyes
        GetAngles(client,clientang); // Get the angle the player is looking
        TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite,TraceRayTryToHit); // Create a ray that tells where the player is looking
        //SetEntPropFloat(client,Prop_Data,"m_flGravity",0.0); // Set gravity to 0 so client floats in a straight line
        TR_GetEndPosition(teleportloc); // Get the end xyz coordinate of where a player is looking

        //EmitSoundFromOrigin("weapons/crossbow/hit1.wav",gHookEndloc[client]); // Emit sound from where the hook landed
        //TeleportEntity(client,teleportloc,NULL_VECTOR,NULL_VECTOR); // Push the client
        PrintToChat(client,"%c[War3Source]%c Location=%f,%f,%f",
                    COLOR_GREEN,COLOR_DEFAULT,teleportloc[0],teleportloc[1],teleportloc[2]);
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

/*********
 *Helpers*
**********/

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
  EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

public GetAngles(client,Float:output[3])
{
  SDKCall(hEyeAngles,client,output);
}

public GetEyePosition(client,Float:output[3])
{
  SDKCall(hEyePosition,client,output);
}

public GetVelocity(client,Float:output[3])
{
  output[0]=GetEntDataFloat(client,GetVelocityOffset_0);
  output[1]=GetEntDataFloat(client,GetVelocityOffset_1);
  output[2]=GetEntDataFloat(client,GetVelocityOffset_2);
}

/***************
 *Trace Filters*
****************/

public bool:TraceRayTryToHit(entity,mask)
{
  if(entity>0&&entity<=64) // Check if the beam hit a player and tell it to keep tracing if it did
    return false;
  return true;
}
