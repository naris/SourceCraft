/**
 * vim: set ai et ts=4 sw=4 :
 * File: inspector.sp
 * Description: Display values of various entities.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2_objects>

#define PL_VERSION "1.3"

new Handle:g_InspectionEnabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "The Inspector",
    author = "-=|JFH|=-Naris",
    description = "A Testing Module to inspect various entities.",
    version = PL_VERSION,
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    CreateConVar("sm_obj_inspector", PL_VERSION, "Object Inspector", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_InspectionEnabled = CreateConVar("sm_obj_inspection","0","Enable inspecting object on events (0=disabled|1=enabled)", _, true, 0.0, true, 1.0);

    if (!HookEvent("player_builtobject", PlayerBuiltObject))
        SetFailState("Could not hook the player_builtobject event.");

    if (!HookEvent("player_upgradedobject", PlayerBuiltObject))
        SetFailState("Could not hook the player_upgradedobject event.");

    if (!HookEvent("object_destroyed", ObjectRemoved))
        SetFailState("Could not hook the object_destroyed event.");

    if (!HookEvent("object_removed", ObjectRemoved))
        SetFailState("Could not hook the object_removed event.");

    RegConsoleCmd("sm_inspect", InspectCmd);
    RegAdminCmd("sm_objhp", Command_ObjHealth, ADMFLAG_CHEATS);
    RegAdminCmd("sm_objshell", Command_ObjShells, ADMFLAG_CHEATS);
    RegAdminCmd("sm_objrocket", Command_ObjRockets, ADMFLAG_CHEATS);
}

// Events

public PlayerBuiltObject(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (GetConVarBool(g_InspectionEnabled))
    {
        new userid = GetEventInt(event,"userid");
        new client = GetClientOfUserId(userid);
        if (client > 0)
        {
            //new objects:type = unknown;
            new objectid = GetEventInt(event,"index");
            new TFObjectType:obj = TFObjectType:GetEventInt(event,"object");

            LogMessage("%s: userid=%d:%d:%N, entity=%d, object=%d:%s",
                       name, userid, client, client, objectid, obj,
                       TF2_ObjectNames[obj]);

            InspectEntity(0, objectid);
        }
    }
}

public ObjectRemoved(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (GetConVarBool(g_InspectionEnabled))
    {
        new userid = GetEventInt(event,"userid");
        new client = GetClientOfUserId(userid);
        if (client > 0)
        {
            //new objects:type = unknown;
            new objectid = GetEventInt(event,"index");
            new TFObjectType:obj = TFObjectType:GetEventInt(event,"objecttype");

            LogMessage("%s: userid=%d:%d:%N, entity=%d, object=%d:%s",
                       name, userid, client, client, objectid, obj, TF2_ObjectNames[obj]);

            InspectEntity(0, objectid);
        }
    }
}

public Action:InspectCmd(client, args)
{
    new target = GetClientAimTarget(client, false);
    if (target > 0)
    {
        LogMessage("Inspected by %d:%N: entity=%d", client, client, target);
        InspectEntity(client, target);
    }
}

InspectEntity(client, entity)
{
    decl String:class[32];
    if (!GetEdictClassname(entity,class,sizeof(class)))
        class[0] = '\0';

    decl String:net_class[32];
    if (!GetEntityNetClass(entity,net_class,sizeof(net_class)))
        net_class[0] = '\0';

    new flags = GetEdictFlags(entity);

    new m_nSkin = GetEntProp(entity, Prop_Send, "m_nSkin");
    new m_nBody = GetEntProp(entity, Prop_Send, "m_nBody");
    new m_iTeamNum = GetEntProp(entity, Prop_Send, "m_iTeamNum");

    new Float:m_vecOrigin[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", m_vecOrigin);

    new Float:m_angRotation[3];
    GetEntPropVector(entity, Prop_Send, "m_angRotation", m_vecOrigin);

    new Float:m_vecMaxs[3];
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", m_vecMaxs);

    new Float:m_vecMins[3];
    GetEntPropVector(entity, Prop_Send, "m_vecMins", m_vecMins);

    LogMessage("%s/%s: flags=%x, skin=%d, body=%d, team=%d, maxs={%f,%f,%f}, mins={%f,%f,%f}, origin={%f,%f,%f}, angle={%f,%f,%f}",
               class, net_class, flags, m_nSkin, m_nBody, m_iTeamNum, m_vecMaxs[0], m_vecMaxs[1], m_vecMaxs[2],
               m_vecMins[0], m_vecMins[1], m_vecMins[2], m_vecOrigin[0], m_vecOrigin[1], m_vecOrigin[2],
               m_angRotation[0], m_angRotation[1], m_angRotation[2]);

    if (client > 0)
    {
        PrintToChat(client, "%s/%s: flags=%x, skin=%d, body=%d",
                    class, net_class, flags, m_nSkin, m_nBody);
    }

    if (strncmp(class, "obj_", 4) == 0)
    {
        new Float:m_vecBuildMaxs[3];
        GetEntPropVector(entity, Prop_Send, "m_vecBuildMaxs", m_vecBuildMaxs);

        new Float:m_vecBuildMins[3];
        GetEntPropVector(entity, Prop_Send, "m_vecBuildMins", m_vecBuildMins);

        new m_iHealth = GetEntProp(entity, Prop_Send, "m_iHealth");
        new m_iMaxHealth = GetEntProp(entity, Prop_Send, "m_iMaxHealth");
        new m_bHasSapper = GetEntProp(entity, Prop_Send, "m_bHasSapper");
        new m_iObjectType = GetEntProp(entity, Prop_Send, "m_iObjectType");
        new m_iObjectMode = GetEntProp(entity, Prop_Send, "m_iObjectMode");
        new m_iUpgradeMetal = GetEntProp(entity, Prop_Send, "m_iUpgradeMetal");
        new m_iUpgradeLevel = GetEntProp(entity, Prop_Send, "m_iUpgradeLevel");
        new m_iHighestUpgradeLevel = GetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel");
        new m_fObjectFlags = GetEntProp(entity, Prop_Send, "m_fObjectFlags");
        new m_bBuilding = GetEntProp(entity, Prop_Send, "m_bBuilding");
        new m_bPlacing = GetEntProp(entity, Prop_Send, "m_bPlacing");
        new m_bCarried = GetEntProp(entity, Prop_Send, "m_bCarried");
        new m_bCarryDeploy = GetEntProp(entity, Prop_Send, "m_bCarryDeploy");
        new m_bMiniBuilding = GetEntProp(entity, Prop_Send, "m_bMiniBuilding");
        new m_hBuiltOnEntity = GetEntProp(entity, Prop_Send, "m_hBuiltOnEntity");
        new m_bDisabled = GetEntProp(entity, Prop_Send, "m_bDisabled");
        new m_iDesiredBuildRotations = GetEntProp(entity, Prop_Send, "m_iDesiredBuildRotations");
        new m_bServerOverridePlacement = GetEntProp(entity, Prop_Send, "m_bServerOverridePlacement");

        new m_hBuilder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");

        new Float:m_flPercentageConstructed = GetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed");

        LogMessage("type=%d, mode=%d, mini=%d, oflags=%x, disabled=%d, level=%d, hlevel=%d, BuildMaxs={%f,%f,%f}, BuildMins={%f,%f,%f}",
                   m_iObjectType, m_iObjectMode, m_bMiniBuilding, m_fObjectFlags, m_bDisabled, m_iUpgradeLevel, m_iHighestUpgradeLevel,
                   m_vecBuildMaxs[0], m_vecBuildMaxs[1], m_vecBuildMaxs[2],
                   m_vecBuildMins[0], m_vecBuildMins[1], m_vecBuildMins[2]);

        LogMessage("health=%d, MaxHealth=%d, sapper=%d, metal=%d, building=%d, placing=%d, carried=%d, CarryDeploy=%d, placement=%d, percentage=%f",
                   m_iHealth, m_iMaxHealth, m_bHasSapper, m_iUpgradeMetal,
                   m_bBuilding, m_bPlacing, m_bCarried, m_bCarryDeploy,
                   m_bServerOverridePlacement, m_flPercentageConstructed);

        LogMessage("BuiltOnEntity=%d, DesiredBuildRotations=%d, Builder=%d",
                   m_hBuiltOnEntity, m_iDesiredBuildRotations, m_hBuilder);

        if (client > 0)
        {
            PrintToChat(client, "type=%d, mode=%d, mini=%d, oflags=%x, disabled=%d, metal=%d, level=%d, hlevel=%d, maxs={%f,%f,%f}",
                        m_iObjectType, m_iObjectMode, m_bMiniBuilding, m_fObjectFlags, m_bDisabled, m_iUpgradeMetal, m_iUpgradeLevel,
                        m_iHighestUpgradeLevel, m_vecBuildMaxs[0], m_vecBuildMaxs[1], m_vecBuildMaxs[2]);
        }                        

        if (StrEqual(class, "obj_sentrygun"))
        {
            new m_iAmmoShells = GetEntProp(entity, Prop_Send, "m_iAmmoShells");
            new m_iAmmoRockets = GetEntProp(entity, Prop_Send, "m_iAmmoRockets");
            new m_iState = GetEntProp(entity, Prop_Send, "m_iState");
            new m_bPlayerControlled = GetEntProp(entity, Prop_Send, "m_bPlayerControlled");
            new m_bShielded = GetEntProp(entity, Prop_Send, "m_bShielded");
            new m_hEnemy = GetEntProp(entity, Prop_Send, "m_hEnemy");
            new m_hAutoAimTarget = GetEntProp(entity, Prop_Send, "m_hAutoAimTarget");

            new Float:m_HackedGunPos[3];
            GetEntPropVector(entity, Prop_Data, "m_HackedGunPos", m_HackedGunPos);

            LogMessage("shells=%d, rockets=%d, shielded=%d, state=%d, controlled=%d, enemy=%d, target=%d, GunPos={%f,%f,%f}",
                       m_iAmmoShells, m_iAmmoRockets, m_bShielded, m_iState, m_bPlayerControlled, m_hEnemy, m_hAutoAimTarget, 
                       m_HackedGunPos[0], m_HackedGunPos[1], m_HackedGunPos[2]);

            if (client > 0)
            {
                PrintToChat(client, "shells=%d, rockets=%d, shielded=%d, state=%d, controlled=%d, enemy=%d, target=%d",
                            m_iAmmoShells, m_iAmmoRockets, m_bShielded, m_iState, m_bPlayerControlled, m_hEnemy, m_hAutoAimTarget);

                PrintToChat(client, "GunPos={%f,%f,%f}",
                            m_HackedGunPos[0], m_HackedGunPos[1], m_HackedGunPos[2]);
            }
        }
        LogMessage("------------------------------------------------------------------------------------------------------------------");
    }
}

public Action:Command_ObjHealth(client, args)
{
    new target = GetClientAimTarget(client, false);
    if (target > 0)
    {
        decl String:class[32];
        if (GetEdictClassname(target,class,sizeof(class)))
        {
            if (strncmp(class, "obj_", 4) == 0)
            {
                new m_iMaxHealth = GetEntProp(target, Prop_Send, "m_iMaxHealth");
                new m_iHealth = GetEntProp(target, Prop_Send, "m_iHealth");

                if (args >= 1)
                {
                    decl String:arg1[32];
                    GetCmdArg(1, arg1, sizeof(arg1));

                    new num=StringToInt(arg1);
                    if (num != 0)
                    {
                        m_iHealth += num;
                        SetEntProp(target, Prop_Send, "m_iHealth", m_iHealth);
                        PrintToChat(client, "Set Object %d's health=%d/%d", target, m_iHealth, m_iMaxHealth);
                    }
                    else
                        PrintToChat(client, "Object %d's health=%d/%d", target, m_iHealth, m_iMaxHealth);
                }
                else
                    PrintToChat(client, "Object %d's health=%d/%d", target, m_iHealth, m_iMaxHealth);
            }
        }
    }

    return Plugin_Handled;
}

public Action:Command_ObjShells(client, args)
{
    new target = GetClientAimTarget(client, false);
    if (target > 0)
    {
        decl String:class[32];
        if (GetEdictClassname(target,class,sizeof(class)))
        {
            if (StrEqual(class, "obj_sentrygun"))
            {
                new m_iAmmoShells = GetEntProp(target, Prop_Send, "m_iAmmoShells");

                if (args >= 1)
                {
                    decl String:arg1[32];
                    GetCmdArg(1, arg1, sizeof(arg1));

                    new num=StringToInt(arg1);
                    if (num != 0)
                    {
                        m_iAmmoShells += num;
                        SetEntProp(target, Prop_Send, "m_iAmmoShells", m_iAmmoShells);
                        PrintToChat(client, "Set Object %d's shells=%d", target, m_iAmmoShells);
                    }
                    else
                        PrintToChat(client, "Object %d's shells=%d", target, m_iAmmoShells);
                }
                else
                    PrintToChat(client, "Object %d's shells=%d", target, m_iAmmoShells);
            }
        }
    }

    return Plugin_Handled;
}

public Action:Command_ObjRockets(client, args)
{
    new target = GetClientAimTarget(client, false);
    if (target > 0)
    {
        decl String:class[32];
        if (GetEdictClassname(target,class,sizeof(class)))
        {
            if (StrEqual(class, "obj_sentrygun"))
            {
                new m_iAmmoRockets = GetEntProp(target, Prop_Send, "m_iAmmoRockets");

                if (args >= 1)
                {
                    decl String:arg1[32];
                    GetCmdArg(1, arg1, sizeof(arg1));

                    new num=StringToInt(arg1);
                    if (num != 0)
                    {
                        m_iAmmoRockets += num;
                        SetEntProp(target, Prop_Send, "m_iAmmoRockets", m_iAmmoRockets);
                        PrintToChat(client, "Set Object %d's rockets=%d", target, m_iAmmoRockets);
                    }
                    else
                        PrintToChat(client, "Object %d's rockets=%d", target, m_iAmmoRockets);
                }
                else
                    PrintToChat(client, "Object %d's rockets=%d", target, m_iAmmoRockets);
            }
        }
    }

    return Plugin_Handled;
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
    if (client > 0 && weapon > 0)
    {
        PrintToChat(client, "Attack with %d:%s", weapon, weaponname);
    }
    return Plugin_Continue;
}
