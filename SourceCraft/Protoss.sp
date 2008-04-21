/**
 * vim: set ai et ts=4 sw=4 :
 * File: Protoss.sp
 * Description: The Protoss race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/log"

new String:errorWav[] = "soundcraft/perror.mp3";
new String:deniedWav[] = "sourcecraft/buzz.wav";
new String:rechargeWav[] = "sourcecraft/transmission.wav";
new String:explodeWav[] = "sourcecraft/PSaHit00.wav";
new String:controlWav[] = "sourcecraft/pteSum00.wav";
new String:unCloakWav[] = "sourcecraft/PabCag00.wav";
new String:cloakWav[] = "sourcecraft/pabRdy00.wav";

new raceID, scarabID, cloakID, sensorID, controlID;

new Handle:cvarMindControlCooldown = INVALID_HANDLE;
new Handle:cvarMindControlEnable = INVALID_HANDLE;

new m_Cloaked[MAXPLAYERS+1][MAXPLAYERS+1];
new m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];
new bool:m_AllowMindControl[MAXPLAYERS+1];
new Float:gReaverScarabTime[MAXPLAYERS+1];

enum objects { dispenser, teleporter_entry, teleporter_exit, sentrygun, sapper, unknown };

new m_SkinOffset;
new m_BuilderOffset;
new m_BuildingOffset;
new m_PlacingOffset;
new m_ObjectTypeOffset;

new Handle:m_StolenObjectList[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

new m_OffsetCloakMeter;
new m_OffsetDisguiseTeam;
new m_OffsetDisguiseClass;
new m_OffsetDisguiseHealth;

new g_redGlow;
new g_blueGlow;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

new explosionModel;

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss",
    author = "-=|JFH|=-Naris",
    description = "The Protoss race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    cvarMindControlCooldown=CreateConVar("sc_mindcontrolcooldown","45");
    cvarMindControlEnable=CreateConVar("sc_mindcontrolenable","1");

    if(!HookEventEx("player_spawn",PlayerSpawnEvent))
        SetFailState("Could not hook the player_spawn event.");

    if (GameType == tf2)
    {
        if(!HookEventEx("teamplay_round_win",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_win event.");

        if(!HookEventEx("teamplay_round_stalemate",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_round_stalemate event.");

        if(!HookEventEx("tf_game_over",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_win_panel event.");

        if(!HookEventEx("teamplay_game_over",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_win_panel event.");

        if(!HookEventEx("teamplay_win_panel",RoundOver,EventHookMode_PostNoCopy))
            SetFailState("Could not hook the teamplay_win_panel event.");

        if(!HookEvent("player_builtobject", PlayerBuiltObject))
            SetFailState("Could not hook the player_builtobject event.");
    }

    CreateTimer(1.0,CloakingAndDetector,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID    = CreateRace("Protoss", "protoss",
                           "You are now part of the Protoss.",
                           "You will be part of the Protoss when you die or respawn.",
                           32);

    scarabID  = AddUpgrade(raceID,"Reaver Scarabs", "scarabs",
                           "Explode upon contact with enemies, causing increased damage. (Disabled)");

    cloakID   = AddUpgrade(raceID,"Arbiter Reality-Warping Field", "arbiter",
                           "Cloaks all friendly units within range");

    sensorID  = AddUpgrade(raceID,"Observer Sensors", "sensors",
                           "Reveals enemy invisible units within range");

    controlID = AddUpgrade(raceID,"Dark Archon Mind Control", "mind_control",
                           "Allows you to control an object from the opposite team.",
                           true); // Ultimate

    if (GameType == tf2)
    {
        m_OffsetCloakMeter=FindSendPropInfo("CTFPlayer","m_flCloakMeter");
        if (m_OffsetCloakMeter == -1)
            SetFailState("Couldn't find CloakMeter Offset");

        m_OffsetDisguiseTeam=FindSendPropInfo("CTFPlayer","m_nDisguiseTeam");
        if (m_OffsetDisguiseTeam == -1)
            SetFailState("Couldn't find DisguiseTeam Offset");

        m_OffsetDisguiseClass=FindSendPropInfo("CTFPlayer","m_nDisguiseClass");
        if (m_OffsetDisguiseClass == -1)
            SetFailState("Couldn't find DisguiseClass Offset");

        m_OffsetDisguiseHealth=FindSendPropInfo("CTFPlayer","m_iDisguiseHealth");
        if (m_OffsetDisguiseHealth == -1)
            SetFailState("Couldn't find DisguiseHealth Offset");

        m_SkinOffset = FindSendPropInfo("CObjectSentrygun","m_nSkin");
        if(m_SkinOffset == -1)
            SetFailState("[SourceCraft] Error finding Sentrygun Skin offset.");

        m_BuilderOffset = FindSendPropInfo("CObjectSentrygun","m_hBuilder");
        if(m_BuilderOffset == -1)
            SetFailState("[SourceCraft] Error finding Sentrygun Builder offset.");

        m_BuildingOffset = FindSendPropInfo("CObjectSentrygun","m_bBuilding");
        if(m_BuildingOffset == -1)
            SetFailState("[SourceCraft] Error finding Sentrygun Building offset.");

        m_PlacingOffset = FindSendPropInfo("CObjectSentrygun","m_bPlacing");
        if(m_PlacingOffset == -1)
            SetFailState("[SourceCraft] Error finding Sentrygun Placing offset.");

        m_ObjectTypeOffset = FindSendPropInfo("CObjectSentrygun","m_iObjectType");
        if(m_ObjectTypeOffset == -1)
            SetFailState("[SourceCraft] Error finding Sentrygun ObjectType offset.");
    }
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_blueGlow = SetupModel("materials/sprites/blueglow1.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find blueglow Model");

    g_redGlow = SetupModel("materials/sprites/redglow1.vmt");
    if (g_redGlow == -1)
        SetFailState("Couldn't find redglow Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");
    if (explosionModel == -1)
        SetFailState("Couldn't find Explosion Model");

    SetupSound(errorWav, true, true);
    SetupSound(deniedWav, true, true);
    SetupSound(rechargeWav, true, true);
    SetupSound(explodeWav, true, true);
    SetupSound(controlWav, true, true);
    SetupSound(unCloakWav, true, true);
    SetupSound(cloakWav, true, true);
}

public OnMapEnd()
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        ResetCloakingAndDetector(index);
        ResetMindControlledObjects(index, true);
    }
}

public OnPlayerAuthed(client,Handle:player)
{
    m_AllowMindControl[client]=true;
}

public OnClientDisconnect(client)
{
    ResetCloakingAndDetector(client);
    ResetMindControlledObjects(client, false);
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
    {
        ResetCloakingAndDetector(client);
        ResetMindControlledObjects(client, false);
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client) &&
        m_AllowMindControl[client] && pressed)
    {
        MindControl(client,player);
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    if (index>0)
    {
        new Handle:player=GetPlayerHandle(index);
        if (player != INVALID_HANDLE)
        {
            new race = GetRace(player);
            if (race == raceID)
                m_AllowMindControl[index]=true;
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;

    if (attacker_race == raceID && victim_index != attacker_index)
    {
        if (ReaverScarab(damage, victim_index, victim_player,
                         attacker_index, attacker_player))
        {
            changed = true;
        }
    }

    if (assister_race == raceID && victim_index != assister_index)
    {
        if (ReaverScarab(damage, victim_index, victim_player,
                         assister_index, assister_player))
        {
            changed = true;
        }
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_index && victim_race == raceID)
    {
        ResetCloakingAndDetector(victim_index);
        ResetMindControlledObjects(victim_index, false);
    }
}

public RoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        ResetCloakingAndDetector(index);
        ResetMindControlledObjects(index, true);
    }
}

public PlayerBuiltObject(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index = GetClientOfUserId(userid);
        if (index > 0)
        {
            new objects:type = objects:GetEventInt(event,"object");
            UpdateMindControlledObject(-1, index, type, false);
        }
    }
}

public OnObjectKilled(attacker, builder, const String:object[])
{
    new objects:type = unknown;
    if (StrEqual(object, "OBJ_SENTRYGUN", false))
        type = sentrygun;
    else if (StrEqual(object, "OBJ_DISPENSER", false))
        type = dispenser;
    else if (StrEqual(object, "OBJ_TELEPORTER_ENTRANCE", false))
        type = teleporter_entry;
    else if (StrEqual(object, "OBJ_TELEPORTER_EXIT", false))
        type = teleporter_exit;
    else if (StrEqual(object, "OBJ_SAPPER", false))
        type = teleporter_exit;

    UpdateMindControlledObject(-1, builder, type, true);
}

bool:ReaverScarab(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new rs_level = GetUpgradeLevel(player,raceID,scarabID);
    if (rs_level > 0)
    {
        new Float:percent, chance;
        switch(rs_level)
        {
            case 1:
            {
                chance=20;
                percent=0.14;
            }
            case 2:
            {
                chance=40;
                percent=0.27;
            }
            case 3:
            {
                chance=60;
                percent=0.43;
            }
            case 4:
            {
                chance=90;
                percent=0.63;
            }
        }

        if (!GetImmunity(victim_player,Immunity_Explosion) &&
            !TF2_IsPlayerInvuln(victim_index) &&
            GetRandomInt(1,100) <= chance &&
            (!gReaverScarabTime[index] ||
             GetGameTime() - gReaverScarabTime[index] > 0.5))
        {
            new health_take= RoundToFloor(float(damage)*percent);
            if (health_take > 0)
            {
                new new_health=GetClientHealth(victim_index)-health_take;
                if (new_health <= 0)
                {
                    new_health=0;
                    LogKill(index, victim_index, "scarab", "Reaver Scarab", health_take);
                }
                else
                    LogDamage(index, victim_index, "scarab", "Reaver Scarab", health_take);

                SetEntityHealth(victim_index,new_health);

                if (!gReaverScarabTime[index] ||
                    GetGameTime() - gReaverScarabTime[index] >= 2.0)
                {
                    new Float:Origin[3];
                    GetClientAbsOrigin(victim_index, Origin);
                    Origin[2] += 5;

                    TE_SetupExplosion(Origin,explosionModel,5.0,1,0,5,10);
                    TE_SendToAll();
                }

                EmitSoundToAll(explodeWav,victim_index);
                gReaverScarabTime[index] = GetGameTime();
                return true;
            }
        }
    }
    return false;
}

MindControl(client,Handle:player)
{
    new ult_level=GetUpgradeLevel(player,raceID,controlID);
    if(ult_level)
    {
        if (!GetConVarBool(cvarMindControlEnable))
        {
            PrintToChat(client,"%c[SourceCraft] %c Sorry, MindControl has been disabled for testing purposes!",
                        COLOR_GREEN,COLOR_DEFAULT);
            return;
        }

        new Float:range, percent;
        switch(ult_level)
        {
            case 1:
            {
                range=150.0;
                percent=30;
            }
            case 2:
            {
                range=300.0;
                percent=50;
            }
            case 3:
            {
                range=450.0;
                percent=70;
            }
            case 4:
            {
                range=650.0;
                percent=90;
            }
        }

        new target = TraceAimTarget(client);
        if (target >= 0)
        {
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);

            new Float:targetLoc[3];
            TR_GetEndPosition(targetLoc);

            if (IsPointInRange(clientLoc,targetLoc,range))
            {
                new Float:distance=DistanceBetween(clientLoc,targetLoc);
                if (GetRandomFloat(1.0,100.0) <= float(percent) * (1.0 - FloatDiv(distance,range)+0.20))
                {
                    decl String:class[32];
                    if (GetEntityNetClass(target,class,sizeof(class)))
                    {
                        new objects:type;
                        if (StrEqual(class, "CObjectSentrygun", false))
                            type = sentrygun;
                        else if (StrEqual(class, "CObjectDispenser", false))
                            type = dispenser;
                        else if (StrEqual(class, "CObjectTeleporter", false))
                        {
                            type = teleporter_entry;
                        }
                        else
                            type = unknown;

                        if (type != unknown)
                        {
                            new placing = GetEntData(target, m_PlacingOffset);
                            new building = GetEntData(target, m_BuildingOffset);
                            //Check to see if the object is still being built
                            if (placing != 1 && building != 1)
                            {
                                //Find the owner of the object m_hBuilder holds the client index 1 to Maxplayers
                                new builder = GetEntDataEnt2(target, m_BuilderOffset); // Get the current owner of the object.
                                new Handle:player_check=GetPlayerHandle(builder);
                                if (player_check != INVALID_HANDLE)
                                {
                                    if (!GetImmunity(player_check,Immunity_Ultimates))
                                    {
                                        new builderTeam = GetClientTeam(builder);
                                        new team = GetClientTeam(client);
                                        if (builderTeam != team)
                                        {
                                            // Check to see if this target has already been controlled.
                                            builder = UpdateMindControlledObject(target, builder, type, true);
                                            // Change the builder to client
                                            SetEntDataEnt2(target, m_BuilderOffset, client, true);

                                            //paint red or blue
                                            SetEntData(target, m_SkinOffset, (team==3)?1:0, 1, true);

                                            //Change TeamNum
                                            SetVariantInt(team);
                                            AcceptEntityInput(target, "TeamNum", -1, -1, 0);

                                            //Same thing again but we are changing SetTeam
                                            SetVariantInt(team);
                                            AcceptEntityInput(target, "SetTeam", -1, -1, 0);

                                            EmitSoundToAll(controlWav,target);

                                            new color[4] = { 0, 0, 0, 255 };
                                            if (team == 3)
                                                color[2] = 255; // Blue
                                            else
                                                color[0] = 255; // Red

                                            TE_SetupBeamPoints(clientLoc,targetLoc,g_lightningSprite,g_haloSprite,
                                                               0, 1, 2.0, 10.0,10.0,2,50.0,color,255);
                                            TE_SendToAll();

                                            TE_SetupSmoke(targetLoc,g_smokeSprite,8.0,2);
                                            TE_SendToAll();

                                            TE_SetupGlowSprite(targetLoc,(team == 3) ? g_blueGlow : g_redGlow,
                                                               5.0,5.0,255);
                                            TE_SendToAll();

                                            new Float:splashDir[3];
                                            splashDir[0] = 0.0;
                                            splashDir[1] = 0.0;
                                            splashDir[2] = 100.0;
                                            TE_SetupEnergySplash(targetLoc, splashDir, true);

                                            decl String:object[32];
                                            strcopy(object, sizeof(object), class[7]);

                                            new Float:cooldown = GetConVarFloat(cvarMindControlCooldown);
                                            LogToGame("[SourceCraft] %N has stolen %N's %s!\n",
                                                      client,builder,object);
                                            PrintToChat(builder,"%c[SourceCraft] %c %N has stolen your %s!",
                                                        COLOR_GREEN,COLOR_DEFAULT,client,object);
                                            PrintToChat(client,"%c[SourceCraft] %c You have used your ultimate %cMind Control%c to steal %N's %s, you now need to wait %2.0f seconds before using it again.!", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,builder,object, cooldown);

                                            if (cooldown > 0.0)
                                            {
                                                m_AllowMindControl[client]=false;
                                                CreateTimer(cooldown,AllowMindControl,client);
                                            }

                                            // Create the Tracking Package
                                            /*
                                            new Handle:pack = CreateDataPack();
                                            WritePackCell(pack, builder);
                                            WritePackCell(pack, type);
                                            WritePackCell(pack, target);
                                            */

                                            // And add it to the list
                                            /*
                                            if (m_StolenObjectList[client] == INVALID_HANDLE)
                                                m_StolenObjectList[client] = CreateArray();

                                            PushArrayCell(m_StolenObjectList[client], pack);
                                            */
                                        }
                                        else
                                        {
                                            EmitSoundToClient(client,errorWav);
                                            PrintToChat(client,"%c[SourceCraft] %cTarget belongs to a teammate!",
                                                        COLOR_GREEN,COLOR_DEFAULT);
                                        }
                                    }
                                    else
                                    {
                                        EmitSoundToClient(client,errorWav);
                                        PrintToChat(client,"%c[SourceCraft] %cTarget is %cimmune%c to ultimates!",
                                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                    }
                                }
                                else
                                    EmitSoundToClient(client,deniedWav);
                            }
                            else
                            {
                                EmitSoundToClient(client,errorWav);
                                PrintToChat(client,"%c[SourceCraft] %cTarget is still %cbuilding%c!",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        else
                        {
                            EmitSoundToClient(client,deniedWav);
                            PrintToChat(client,"%c[SourceCraft] %cInvalid Target!",
                                        COLOR_GREEN,COLOR_DEFAULT);
                        }
                    }
                    else
                    {
                        EmitSoundToClient(client,deniedWav);
                        PrintToChat(client,"%c[SourceCraft] %cInvalid Target!",
                                    COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                else
                    EmitSoundToClient(client,errorWav); // Chance check failed.
            }
            else
            {
                EmitSoundToClient(client,errorWav);
                PrintToChat(client,"%c[SourceCraft] %cTarget is too far away!",
                            COLOR_GREEN,COLOR_DEFAULT);
            }
        }
        else
            EmitSoundToClient(client,deniedWav);
    }
    else
        EmitSoundToClient(client,deniedWav);
}

public Action:AllowMindControl(Handle:timer,any:index)
{
    m_AllowMindControl[index]=true;
    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        if (GetRace(GetPlayerHandle(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cMind Control%c is now available again!",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}

public Action:CloakingAndDetector(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceID)
                {
                    new Float:cloaking_range;
                    new cloaking_level=GetUpgradeLevel(player,raceID,cloakID);
                    if (cloaking_level)
                    {
                        switch(cloaking_level)
                        {
                            case 1:
                                cloaking_range=300.0;
                            case 2:
                                cloaking_range=450.0;
                            case 3:
                                cloaking_range=650.0;
                            case 4:
                                cloaking_range=800.0;
                        }
                    }

                    new Float:detecting_range;
                    new detecting_level=GetUpgradeLevel(player,raceID,sensorID);
                    if (detecting_level)
                    {
                        switch(detecting_level)
                        {
                            case 1:
                                detecting_range=300.0;
                            case 2:
                                detecting_range=450.0;
                            case 3:
                                detecting_range=650.0;
                            case 4:
                                detecting_range=800.0;
                        }
                    }

                    new Float:clientLoc[3];
                    GetClientAbsOrigin(client, clientLoc);
                    for (new index=1;index<=maxplayers;index++)
                    {
                        if (index != client && IsClientInGame(index))
                        {
                            if (IsPlayerAlive(index))
                            {
                                new Handle:player_check=GetPlayerHandle(index);
                                if (player_check != INVALID_HANDLE)
                                {
                                    if (GetClientTeam(index) == GetClientTeam(client))
                                    {
                                        if (GetRace(player_check) == raceID &&
                                            GetUpgradeLevel(player_check,raceID,cloakID) > 0)
                                        {
                                            continue; // Don't cloak other arbiters!
                                        }

                                        new bool:cloak = IsInRange(client,index,cloaking_range);
                                        if (cloak)
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            cloak = TraceTarget(client, index, clientLoc, indexLoc);
                                        }

                                        if (cloak)
                                        {
                                            SetVisibility(player_check,0,BasicVisibility,0.0,0.0);
                                            m_Cloaked[client][index] = true;

                                            if (!m_Cloaked[client][index])
                                            {
                                                EmitSoundToClient(client, cloakWav);
                                                LogToGame("[SourceCraft] %N has been cloaked by %N!\n", index,client);
                                                PrintToChat(index,"%c[SourceCraft] %N %c has been cloaked by %N!",
                                                            COLOR_GREEN,index,COLOR_DEFAULT,client);
                                            }
                                        }
                                        else if (m_Cloaked[client][index])
                                        {
                                            SetVisibility(player_check, -1);
                                            m_Cloaked[client][index] = false;

                                            EmitSoundToClient(client, unCloakWav);
                                            LogToGame("[SourceCraft] %N has been uncloaked!\n", index);
                                            PrintToChat(index,"%c[SourceCraft] %N %c has been uncloaked!",
                                                        COLOR_GREEN,index,COLOR_DEFAULT);
                                        }
                                    }
                                    else
                                    {
                                        new bool:detect = IsInRange(client,index,detecting_range);
                                        if (detect)
                                        {
                                            new Float:indexLoc[3];
                                            GetClientAbsOrigin(index, indexLoc);
                                            detect = TraceTarget(client, index, clientLoc, indexLoc);
                                        }
                                        if (detect && !GetImmunity(player_check,Immunity_Uncloaking))
                                        {
                                            SetOverrideVisiblity(player_check, 255);
                                            if (TF2_GetPlayerClass(index) == TFClass_Spy)
                                            {
                                                TF2_RemovePlayerDisguise(index);
                                                TF2_SetPlayerCloak(client, false);

                                                new Float:cloakMeter = GetEntDataFloat(index,m_OffsetCloakMeter);
                                                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                                {
                                                    SetEntDataFloat(index,m_OffsetCloakMeter, 0.0);
                                                }
                                            }
                                            m_Detected[client][index] = true;
                                        }
                                        else if (m_Detected[client][index])
                                        {
                                            SetOverrideVisiblity(player_check, -1);
                                            m_Detected[client][index] = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

stock ResetCloakingAndDetector(client)
{
    new maxplayers=GetMaxClients();
    for (new index=1;index<=maxplayers;index++)
    {
        new Handle:player = GetPlayerHandle(index);
        if (player != INVALID_HANDLE)
        {
            if (m_Cloaked[client][index])
            {
                SetVisibility(player, -1);
                m_Cloaked[client][index] = false;
            }

            if (m_Detected[client][index])
            {
                SetOverrideVisiblity(player, -1);
                m_Detected[client][index] = false;
            }
        }
    }
}

stock UpdateMindControlledObject(object, builder, objects:obj, bool:remove)
{
    new bindex = builder;
    if (object > 0 || builder > 0)
    {
        new maxplayers=GetMaxClients();
        for (new client=1;client<=maxplayers;client++)
        {
            if (m_StolenObjectList[client] != INVALID_HANDLE)
            {
                new size = GetArraySize(m_StolenObjectList[client]);
                for (new index = 0; index < size; index++)
                {
                    new Handle:pack = GetArrayCell(m_StolenObjectList[client], index);
                    if (pack != INVALID_HANDLE)
                    {
                        ResetPack(pack);
                        bindex           = ReadPackCell(pack);
                        new objects:type = objects:ReadPackCell(pack);
                        new target       = ReadPackCell(pack);

                        new bool:found;
                        if (object > 0)
                            found = (object == target);
                        else
                            found = (builder == bindex && obj == type);

                        if (found)
                        {
                            CloseHandle(pack);

                            if (remove)
                                RemoveFromArray(m_StolenObjectList[client], index);
                            else
                            {
                                // Update the tracking package
                                pack = CreateDataPack();
                                WritePackCell(pack, -1);
                                WritePackCell(pack, type);
                                WritePackCell(pack, target);
                                SetArrayCell(m_StolenObjectList[client], index, pack);
                            }

                            client = maxplayers+1;
                            break;
                        }
                    }
                }
            }
        }
    }
    return bindex;
}

stock ResetMindControlledObjects(client, bool:endRound)
{
    if (m_StolenObjectList[client] != INVALID_HANDLE)
    {
        new size = GetArraySize(m_StolenObjectList[client]);
        for (new index = 0; index < size; index++)
        {
            new Handle:pack = GetArrayCell(m_StolenObjectList[client], index);
            if (pack != INVALID_HANDLE)
            {
                ResetPack(pack);
                new builder = ReadPackCell(pack);
                new objects:type = objects:ReadPackCell(pack);
                new target = ReadPackCell(pack);

                if (IsValidEntity(target))
                {
                    decl String:class[32];
                    if (GetEntityNetClass(target,class,sizeof(class)))
                    {
                        new objects:current_type;
                        if (StrEqual(class, "CObjectSentrygun", false))
                            current_type = sentrygun;
                        else if (StrEqual(class, "CObjectDispenser", false))
                            current_type = dispenser;
                        else if (StrEqual(class, "CObjectTeleporter", false))
                            current_type = objects:GetEntData(target, m_ObjectTypeOffset);
                        else
                            current_type = unknown;

                        // Is the object still what we stole?
                        if (current_type == type)
                        {
                            // Do we still own it?
                            if (GetEntDataEnt2(target, m_BuilderOffset) == client)
                            {
                                // Is the round not ending and the builder valid?
                                if (!endRound && builder > 0)
                                {
                                    // Is the original builder still around and still an engie?
                                    if (IsClientInGame(builder) &&
                                        TF2_GetPlayerClass(builder) == TFClass_Engineer)
                                    {
                                        // Give it back.
                                        new team = GetClientTeam(builder);

                                        // Change the builder back
                                        SetEntDataEnt2(target, m_BuilderOffset, builder, true);

                                        //paint red or blue
                                        SetEntData(target, m_SkinOffset, (team==3)?1:0, 1, true);

                                        //Change TeamNum
                                        SetVariantInt(team);
                                        AcceptEntityInput(target, "TeamNum", -1, -1, 0);

                                        //Same thing again but we are changing SetTeam
                                        SetVariantInt(team);
                                        AcceptEntityInput(target, "SetTeam", -1, -1, 0);
                                    }
                                    else // Zap it.
                                        RemoveEdict(target); // Remove the object.
                                }
                                else // Zap it.
                                    RemoveEdict(target); // Remove the object.
                            }
                        }
                    }
                }

                CloseHandle(pack);
                //SetArrayCell(m_StolenObjectList[client], index, INVALID_HANDLE);
            }
        }
        ClearArray(m_StolenObjectList[client]);
        CloseHandle(m_StolenObjectList[client]);
        m_StolenObjectList[client] = INVALID_HANDLE;
    }
}

