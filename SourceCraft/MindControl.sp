/**
 * vim: set ai et ts=4 sw=4 :
 * File: MindControl.sp
 * Description: The MindControl upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#include <hooker>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <tf2_player>
#include <tf2_objects>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"

enum disposition { update, remove, reset };

new String:errorWav[] = "sourcecraft/perror.mp3";
new String:deniedWav[] = "sourcecraft/buzz.wav";
new String:controlWav[] = "sourcecraft/pteSum00.wav";

new Handle:m_StolenObjectList[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

new g_redGlow;
new g_blueGlow;
new g_haloSprite;
new g_smokeSprite;
new g_lightningSprite;

public Plugin:myinfo = 
{
    name = "SourceCraft Upgrade - MindControl",
    author = "-=|JFH|=-Naris",
    description = "The MindControl upgrade for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
	// Register Natives
	CreateNative("MindControl",Native_MindControl);
	CreateNative("ResetMindControlledObjects",Native_ResetMindControlledObjs);
	RegPluginLibrary("MindControl");
	return true;
}

public OnPluginStart()
{
    if(!HookEvent("player_builtobject", PlayerBuiltObject))
        SetFailState("Could not hook the player_builtobject event.");

    //RegisterHook(HK_EventKilled, ObjectDestroyed, false);
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt");
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_blueGlow = SetupModel("materials/sprites/blueglow1.vmt");
    if (g_blueGlow == -1)
        SetFailState("Couldn't find blueglow Model");

    g_redGlow = SetupModel("materials/sprites/redglow1.vmt");
    if (g_redGlow == -1)
        SetFailState("Couldn't find redglow Model");

    SetupSound(errorWav, true, true);
    SetupSound(deniedWav, true, true);
    SetupSound(controlWav, true, true);
}

public OnClientDisconnect(client)
{
    LogMessage("%d disconnected", client);
    ResetMindControlledObjects(client, false);
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
            LogMessage("%N build a %s", index, TF2_ObjectNames[type]);
            UpdateMindControlledObject(-1, index, type, update);
        }
    }
}

public Action:ObjectDestroyed(entity, &inflictor, &attacker, &Float:Damage, &DamageType, &AmmoType)
{
    LogMessage("entity %d was destroyed", entity);
    UpdateMindControlledObject(entity, -1, unknown, reset);
    return Plugin_Continue;
}

public OnObjectKilled(attacker, builder, objects:type)
{
    LogMessage("%N's %s was killed", builder, TF2_ObjectNames[type]);
    UpdateMindControlledObject(-1, builder, type, remove);
}

bool:MindControl(client, Float:range, percent, &builder, &objects:type)
{
    LogMessage("%N is attempting MindControl", client);
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
                if (IsValidEntity(target) &&
                    GetEntityNetClass(target,class,sizeof(class)))
                {
                    type = GetObjectTypeFromNetClass(target, class);
                    if (type == sentrygun || type == dispenser)
                    {
                        //Check to see if the object is still being built
                        new placing = GetEntProp(target, Prop_Send, "m_bPlacing");
                        new building = GetEntProp(target, Prop_Send, "m_bBuilding");
                        new Float:complete = GetEntPropFloat(target, Prop_Send, "m_flPercentageConstructed");
                        if (placing == 0 && building == 0 && complete >= 1.0)
                        {
                            //Find the owner of the object m_hBuilder holds the client index 1 to Maxplayers
                            builder = GetEntPropEnt(target, Prop_Send, "m_hBuilder");

                            //LogMessage("Target Builder=%d, Percent=%f, ObjectType=%d, building=%d, placing=%d, Class=%s",
                            //           builder, complete, type, building, placing, class);

                            new Handle:player_check=GetPlayerHandle(builder);
                            if (player_check != INVALID_HANDLE)
                            {
                                if (!GetImmunity(player_check,Immunity_Ultimates))
                                {
                                    new builderTeam = GetClientTeam(builder);
                                    new team = GetClientTeam(client);
                                    if (builderTeam != team || true)
                                    {
                                        // Check to see if this target has already been controlled.
                                        builder = UpdateMindControlledObject(target, builder, type, update);

                                        LogMessage("Mind Control the object=%d, type=%d, builder=%d", target, type, builder);

                                        // Change the builder to client
                                        SetEntPropEnt(target, Prop_Send, "m_hBuilder", client);

                                        //paint red or blue
                                        SetEntProp(target, Prop_Send, "m_nSkin", (team==3)?1:0);

                                        //Change TeamNum
                                        SetVariantInt(team);
                                        AcceptEntityInput(target, "TeamNum", -1, -1, 0);

                                        //Same thing again but we are changing SetTeam
                                        SetVariantInt(team);
                                        AcceptEntityInput(target, "SetTeam", -1, -1, 0);

                                        //HookEntity(HKE_CBaseEntity, target);
                                        LogMessage("entity %d was mind controlled", target);

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

                                        // Create the Tracking Package
                                        //LogMessage("Track the target=%d, type=%d, builder=%d", target, type, builder);
                                        new Handle:pack = CreateDataPack();
                                        WritePackCell(pack, builder);
                                        WritePackCell(pack, type);
                                        WritePackCell(pack, target);

                                        // And add it to the list
                                        if (m_StolenObjectList[client] == INVALID_HANDLE)
                                        {
                                            //LogMessage("Create %N's object List", client);
                                            m_StolenObjectList[client] = CreateArray();
                                        }

                                        //LogMessage("Push Pack onto %N's List; list=%x, pack=%x",
                                        //           client, m_StolenObjectList[client], pack);

                                        PushArrayCell(m_StolenObjectList[client], pack);
                                        return true;
                                    }
                                    else
                                    {
                                        EmitSoundToClient(client,errorWav);
                                        PrintToChat(client,"%c[MindControl] %cTarget belongs to a teammate!",
                                                    COLOR_GREEN,COLOR_DEFAULT);
                                    }
                                }
                                else
                                {
                                    EmitSoundToClient(client,errorWav);
                                    PrintToChat(client,"%c[MindControl] %cTarget is %cimmune%c to ultimates!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                }
                            }
                            else
                                EmitSoundToClient(client,deniedWav);
                        }
                        else
                        {
                            EmitSoundToClient(client,errorWav);
                            PrintToChat(client,"%c[MindControl] %cTarget is still %cbuilding%c!",
                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                        }
                    }
                    else
                    {
                        EmitSoundToClient(client,deniedWav);
                        PrintToChat(client,"%c[MindControl] %cInvalid Target!",
                                    COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                else
                {
                    EmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[MindControl] %cInvalid Target!",
                                COLOR_GREEN,COLOR_DEFAULT);
                }
            }
            else
                EmitSoundToClient(client,errorWav); // Chance check failed.
        }
        else
        {
            EmitSoundToClient(client,errorWav);
            PrintToChat(client,"%c[MindControl] %cTarget is too far away!",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
        EmitSoundToClient(client,deniedWav);

    return false;
}

UpdateMindControlledObject(object, builder, objects:type, disposition:disp)
{
    LogMessage("UpdateMindControlledObject() of %d, object=%d, type=%d, disp=%d", builder, object, type, disp);
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
                        new pack_builder      = ReadPackCell(pack);
                        new objects:pack_type = objects:ReadPackCell(pack);
                        new pack_target       = ReadPackCell(pack);

                        new bool:found;
                        if (object > 0)
                            found = (object == pack_target);
                        else
                            found = (builder == pack_builder && type == pack_type);

                        if (found)
                        {
                            //LogMessage("Object Found in %x", pack);
                            CloseHandle(pack);

                            if (disp == remove || !IsValidEntity(pack_target)
                                               || GetObjectType(pack_target) != pack_type)
                            {
                                //LogMessage("Removing %x", pack);
                                RemoveFromArray(m_StolenObjectList[client], index);
                            }
                            else if (disp == reset)
                                ResetObject(-1, pack_target, pack_builder, pack_type, false);
                            else
                            {
                                //LogMessage("Updating %x", pack);
                                // Update the tracking package
                                pack = CreateDataPack();
                                WritePackCell(pack, -1);
                                WritePackCell(pack, type);
                                WritePackCell(pack, pack_target);
                                SetArrayCell(m_StolenObjectList[client], index, pack);
                            }
                            //LogMessage("Original owner=%d", pack_builder);
                            return pack_builder;
                        }
                    }
                }
            }
        }
    }
    return builder;
}

ResetMindControlledObjects(client, bool:kill)
{
    LogMessage("ResetMindControlledObject() for %d, kill=%d", client, kill);
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
                CloseHandle(pack);

                ResetObject(client, target, builder, type, kill);
                //SetArrayCell(m_StolenObjectList[client], index, INVALID_HANDLE);
            }
        }
        ClearArray(m_StolenObjectList[client]);
        CloseHandle(m_StolenObjectList[client]);
        m_StolenObjectList[client] = INVALID_HANDLE;
    }
}

ResetObject(client, target, builder, objects:type, bool:kill)
{
    if (IsValidEntity(target))
    {
        decl String:class[32];
        if (GetEntityNetClass(target,class,sizeof(class)))
        {
            new objects:current_type = GetObjectTypeFromNetClass(target, class);

            // Is the object still what we stole?
            if (current_type == type)
            {
                // Do we still own it?
                if (client <= 0 || GetEntPropEnt(target, Prop_Send, "m_hBuilder") ==  client)
                {
                    // Is the round not ending and the builder valid?
                    // (still around and still an engie)?
                    if (kill || builder <= 0 || !IsClientInGame(builder) ||
                        TF2_GetPlayerClass(builder) != TFClass_Engineer)
                    {
                        //LogMessage("Orphaned object %x", target);
                        AcceptEntityInput(target, "Kill", -1, -1, 0);
                        //RemoveEdict(target); // Remove the object.
                    }
                    else
                    {
                        // Give it back.
                        new team = GetClientTeam(builder);

                        // Change the builder back
                        SetEntPropEnt(target, Prop_Send, "m_hBuilder", builder);

                        //paint red or blue
                        SetEntProp(target, Prop_Send, "m_nSkin", (team==3)?1:0);

                        //Change TeamNum
                        SetVariantInt(team);
                        AcceptEntityInput(target, "TeamNum", -1, -1, 0);

                        //Same thing again but we are changing SetTeam
                        SetVariantInt(team);
                        AcceptEntityInput(target, "SetTeam", -1, -1, 0);
                    }
                }
            }
        }
    }
}

public Native_MindControl(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new Float:range = Float:GetNativeCell(2);
    new percent = GetNativeCell(3);
    new builder = GetNativeCellRef(4);
    new objects:type = GetNativeCellRef(5);
    new bool:success=MindControl(client,range,percent, builder, type);
    if (success)
    {
        SetNativeCellRef(4, builder);
        SetNativeCellRef(5, type);
    }
    return success;
}

public Native_ResetMindControlledObjs(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new bool:kill = bool:GetNativeCell(2);
    ResetMindControlledObjects(client,kill);
}

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,
                   SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,
                   NULL_VECTOR,true,0.0);
}

