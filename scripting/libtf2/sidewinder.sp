/**
 * vim: set ai et ts=4 sw=4 :
 * File: Sidewinder.sp
 * Description: Sidewinder - Homing projectiles for TF2
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 * Credits: Based on javila's TF2CoolRocket which is based on idea and work of predcrab`s extension, sidewinder
 *          incorporating Naris' enhancements to the sidewinder extension
 */

new const String:PLUGIN_VERSION[60] = "2.0";

public Plugin:myinfo =
{
    name = "Sidewinder",
    author = "naris & javalia",
    description = "based on javila's TF2CoolRocket which is based on idea and work of predcrab`s extension, sidewinder",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};

//semicolon!!!!
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <libtf2/sidewinder>

new Handle:g_cvarWeaponList = INVALID_HANDLE;
new Handle:g_cvarTrackCrits = INVALID_HANDLE;
new Handle:g_cvarEnable = INVALID_HANDLE;
new Handle:g_cvarToHead = INVALID_HANDLE;
new Handle:g_cvarTrack = INVALID_HANDLE;

// forwards
new Handle:g_fwdOnSeek = INVALID_HANDLE;

new g_iTarget[2048];
new bool:g_bToHead[2048];
new bool:g_bValidated[2048];

new SidewinderClientFlags:g_SidewinderFlags[MAXPLAYERS+1];
new g_iTrackChance[MAXPLAYERS+1];
new g_iTrackCritChance[MAXPLAYERS+1];
new g_iSentryCritChance[MAXPLAYERS+1];

new SidewinderEnableFlags:g_EnableFlags = SidewinderEnable;
new bool:g_bNativeControl = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("SidewinderControl",Native_Control);
    CreateNative("SidewinderFlags",Native_SetFlags);
    CreateNative("SidewinderTrackChance",Native_TrackChance);
    CreateNative("SidewinderSentryCritChance",Native_SentryCritChance);
    CreateNative("SidewinderDesignateClient",Native_DesignateClient);
    CreateNative("SidewinderCloakClient",Native_CloakClient);
    CreateNative("SidewinderDetectClient",Native_DetectClient);

    // Register Forwards
    g_fwdOnSeek = CreateGlobalForward("OnSidewinderSeek",ET_Hook,Param_Cell,Param_Cell,Param_Cell,Param_Cell);

    RegPluginLibrary("sidewinder");
    return APLRes_Success;
}

public OnPluginStart()
{
    HookEvent("player_spawn", PlayerSpawnEvent);

    CreateConVar("sm_sidewinder_version", PLUGIN_VERSION, "sidewinder plugin version", FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);

    new String:enableString[64];
    IntToString(_:g_EnableFlags, enableString, sizeof(enableString));

    g_cvarEnable = CreateConVar("sm_sidewinder_enable", enableString, "Set to 0 to disable homing or set bits to enable individual projectiles globally (1=sentry,2=rocket,4=energy,8=pipe,16=flare,32=arrow,64=syringe,128=bolt,256=bolt,512=ball,1024=jar,2048=milk");

    g_cvarWeaponList = CreateConVar("sm_sidewinder_weapons", "tf_projectile_sentryrocket;", "Either all or names of projectiles to track (tf_projectile_sentryrocket, _rocket, _energy_ball, _pipe, _flare, _arrow, _syringe, _healing_bolt, _ball, _ball_ornament, _jar, _jar_milk)");
    g_cvarToHead = CreateConVar("sm_sidewinder_to_head", "1", "Should arrows, bolts and balls home to the head? 1 or 0");
    g_cvarTrackCrits = CreateConVar("sm_sidewinder_track_crit_chance", "100", "Percent chance to track crits (0-100)");
    g_cvarTrack = CreateConVar("sm_sidewinder_track_chance", "25", "Percent chance to track non-crits (0-100)");

    AutoExecConfig(true, "plugin.sidewinder");

    HookConVarChange(g_cvarEnable, OnConfigsChanged);
}

public OnConfigsExecuted()
{
    g_EnableFlags = SidewinderEnableFlags:GetConVarInt(g_cvarEnable);
}

public OnConfigsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == g_cvarEnable)
        g_EnableFlags = SidewinderEnableFlags:StringToInt(newValue);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (!g_bNativeControl)
    {
        new client=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index

        decl String:cvarstring[2048];
        GetConVarString(g_cvarWeaponList, cvarstring, sizeof(cvarstring));

        if (StrEqual(cvarstring, "all", false))
        {
            g_SidewinderFlags[client] = TrackingAll;
        }
        else
        {
            g_SidewinderFlags[client] = NoTracking;

            if (StrContains(cvarstring, "sentryrocket", false) >= 0)
                g_SidewinderFlags[client] |= TrackingSentryRockets;

            if (StrContains(cvarstring, "_rocket", false) >= 0)
                g_SidewinderFlags[client] |= TrackingRockets;

            if (StrContains(cvarstring, "energy_ball", false) >= 0)
                g_SidewinderFlags[client] |= TrackingEnergyBalls;

            if (StrContains(cvarstring, "pipe", false) >= 0)
                g_SidewinderFlags[client] |= TrackingPipes;

            if (StrContains(cvarstring, "flare", false) >= 0)
                g_SidewinderFlags[client] |= TrackingFlares;

            if (StrContains(cvarstring, "arrow", false) >= 0)
                g_SidewinderFlags[client] |= TrackingArrows;

            if (StrContains(cvarstring, "syringe", false) >= 0)
                g_SidewinderFlags[client] |= TrackingSyringes;

            if (StrContains(cvarstring, "bolt", false) >= 0)
                g_SidewinderFlags[client] |= TrackingBolts;

            if (StrContains(cvarstring, "ornament", false) >= 0)
                g_SidewinderFlags[client] |= TrackingWrapBalls;

            if (StrContains(cvarstring, "milk", false) >= 0)
                g_SidewinderFlags[client] |= TrackingMilk;

            // Check for ball and ensure it's not part of ball_ornament
            for (new ball_pos=0, new_pos=0;
                 (new_pos = StrContains(cvarstring[ball_pos+1], "ball", false)) >= 0;
                 ball_pos += new_pos)
            {
                if (cvarstring[ball_pos+4] != '_')
                {
                    g_SidewinderFlags[client] |= TrackingBalls;
                    break;
                }
            }

            // Check for jar and ensure it's not part of jar_milk
            for (new jar_pos=0, new_pos=0;
                 (new_pos = StrContains(cvarstring[jar_pos+1], "jar", false)) >= 0;
                 jar_pos += new_pos)
            {
                if (cvarstring[jar_pos+3] != '_')
                {
                    g_SidewinderFlags[client] |= TrackingJars;
                    break;
                }
            }
        }

        g_iTrackChance[client] |= GetConVarInt(g_cvarTrack);
        g_iTrackCritChance[client] |= GetConVarInt(g_cvarTrackCrits);

        if (GetConVarBool(g_cvarToHead))
            g_SidewinderFlags[client] |= TargetHeads;
    }
}

public OnEntityCreated(entity, const String:classname[])
{
    //lets save cpu. at this will avoid long string compare compute that can execute for EVERY entitys that are created on server.
    if (strncmp(classname, "tf_projectile_", 14) == 0)
    {
        g_bValidated[entity] = false;
        g_bToHead[entity]    = false;
        g_iTarget[entity]    = INVALID_ENT_REFERENCE;
        SDKHook(entity, SDKHook_Think, SidewinderThinkHook);
    }
}

public SidewinderThinkHook(entity)
{
    if (g_bValidated[entity])
        SidewinderTrackHook(entity);
    else
    {
        decl String:classname[32];
        if (GetEdictClassname(entity, classname , sizeof(classname)) &&
            strncmp(classname, "tf_projectile_", 14) == 0)
        {
            new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

            // Compare classname starting at pos 14 since we already know it starts with tf_projectile_
            new bool:isSentry = StrEqual(classname[14], "sentryrocket");

            // For sentry rockets, the actual owner is the builder of the sentry
            if (isSentry && owner > 0 && owner < MaxClients)
                owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");

            if (owner > 0 && owner < MaxClients)
            {
                new SidewinderClientFlags:flags = g_SidewinderFlags[owner];

                if (isSentry) // StrEqual(classname[14], "sentryrocket"))
                {
                    new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                    if (!crit && (flags & CritSentryRockets) != NoTracking &&
                        GetRandomInt(1,100) <= g_iSentryCritChance[owner])
                    {
                        crit = true;
                        SetEntPropEnt(owner, Prop_Send, "m_bCritical", crit);
                    }

                    if ((g_EnableFlags & SidewinderSentryRockets) != SidewinderDisabled &&
                        (flags & (TrackingSentryRockets|TrackingAll)) != NoTracking &&
                        GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                    {
                        TrackProjectile(entity, false);
                    }
                    else
                    {
                        SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                    }
                }
                else
                {
                    if (StrEqual(classname[14], "rocket"))
                    {
                        new bool:crit    = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderRockets) != SidewinderDisabled &&
                            (flags & (TrackingRockets|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, false);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "energy_ball"))
                    {
                        new bool:crit = (GetRandomInt(1,100) <= g_iSentryCritChance[owner]);
                        if ((g_EnableFlags & SidewinderEnergyBalls) != SidewinderDisabled &&
                            (flags & (TrackingEnergyBalls|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, false);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "energy_ring"))
                    {
                        new bool:crit = isCrit(entity, owner, classname);
                        if ((g_EnableFlags & SidewinderEnergyRings) != SidewinderDisabled &&
                            (flags & (TrackingEnergyRings|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, false);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "pipe"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderPipes) != SidewinderDisabled &&
                            (flags & (TrackingPipes|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, false);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "flare"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderFlares) != SidewinderDisabled &&
                            (flags & (TrackingFlares|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, (flags & TargetHeads) != NoTracking);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "arrow"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderArrows) != SidewinderDisabled &&
                            (flags & (TrackingArrows|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, (flags & TargetHeads) != NoTracking);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "syringe"))
                    {
                        new bool:crit = (GetRandomInt(1,100) <= g_iSentryCritChance[owner]);
                        if ((g_EnableFlags & SidewinderSyringes) != SidewinderDisabled &&
                            (flags & (TrackingSyringes|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, (flags & TargetHeads) != NoTracking);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "healing_bolt"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderBolts) != SidewinderDisabled &&
                            (flags & (TrackingBolts|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, (flags & TargetHeads) != NoTracking);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "ball"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderBalls) != SidewinderDisabled &&
                            (flags & (TrackingBalls|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, (flags & TargetHeads) != NoTracking);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "ball_ornament"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderWrapBalls) != SidewinderDisabled &&
                            (flags & (TrackingBalls|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, (flags & TargetHeads) != NoTracking);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "jar"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderJars) != SidewinderDisabled &&
                            (flags & (TrackingJars|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, false);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "jar_milk"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderMilk) != SidewinderDisabled &&
                            (flags & (TrackingMilk|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, false);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else if (StrEqual(classname[14], "cleaver"))
                    {
                        new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
                        if ((g_EnableFlags & SidewinderCleaver) != SidewinderDisabled &&
                            (flags & (TrackingCleaver|TrackingAll)) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner]))
                        {
                            TrackProjectile(entity, false);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                    else
                    {
                        // In case new projectiles are added
                        new bool:crit = isCrit(entity, owner, classname);
                        if ((flags & TrackingAll) != NoTracking &&
                            GetRandomInt(1,100) <= (crit ? g_iTrackCritChance[owner] : g_iTrackChance[owner])) 
                        {
                            TrackProjectile(entity, (flags & TargetHeads) != NoTracking);
                        }
                        else
                        {
                            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
                        }
                    }
                }
            }
            else
                SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
        }
        else
            SDKUnhook(entity, SDKHook_Think, SidewinderThinkHook);
    }
}

stock bool:isCrit(entity, owner, const String:classname[])
{
    new offset = GetEntSendPropOffs(entity, "m_bCritical");
    if (offset < 0)
    {
        decl String:netclass[32];
        if (!GetEntityNetClass(entity, netclass , sizeof(netclass)))
            netclass[0] = '\0';

        LogError("Entity %s (%s) has no m_bCritical flag!", classname, netclass);
        return (GetRandomInt(1,100) <= g_iSentryCritChance[owner]);
    }
    else
        return bool:GetEntDataEnt2(entity, offset);
}

TrackProjectile(entity, bool:toHead)
{
    g_bToHead[entity] = toHead;
    g_iTarget[entity] = INVALID_ENT_REFERENCE;
    g_bValidated[entity] = true;
    SidewinderTrackHook(entity);
}

public SidewinderTrackHook(entity)
{
    //does the rocket have a target?
    new target = EntRefToEntIndex(g_iTarget[entity]);
    if (target != INVALID_ENT_REFERENCE && isValidTarget(entity, target) && isTargetTraceable(entity, target))
    {
        decl Float:rocketposition[3], Float:targetpos[3], Float:vecangle[3], Float:angle[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", rocketposition);

        //로켓포지션에서 추적 위치로 가는 벡터를 구한다
        GetClientEyePosition(target, targetpos);
        if (!g_bToHead[entity])
        {
            targetpos[2] -= 25.0;
        }

        MakeVectorFromPoints(rocketposition, targetpos, vecangle);
        NormalizeVector(vecangle, vecangle);
        GetVectorAngles(vecangle, angle);
        decl Float:speed[3];
        GetEntPropVector(entity, Prop_Data, "m_vecVelocity", speed);
        ScaleVector(vecangle, GetVectorLength(speed));
        TeleportEntity(entity, NULL_VECTOR, angle, vecangle);
    }
    else
    {
        g_iTarget[entity] = findNewTarget(entity);
    }
}

findNewTarget(entity)
{
    new designatedList[MaxClients];
    new targetList[MaxClients];
    new designatedCount = 0;
    new targetCount = 0;

    //make list of valid and designated clients
    for (new i = 0; i < MaxClients; i++)
    {
        if (isValidTarget(entity, i) &&
            isTargetTraceable(entity, i))
        {
            if ((g_SidewinderFlags[i] & TrackingClientIsDesignated) != NoTracking)
                designatedList[designatedCount++] = i;
            else
                targetList[targetCount++] = i;
        }
    }

    new targetRef = (designatedCount > 0) ? getClosestTarget(entity, designatedList, designatedCount)
                     : (targetCount > 0)  ? getClosestTarget(entity, targetList, targetCount)
                                          : INVALID_ENT_REFERENCE;

    if (targetRef != INVALID_ENT_REFERENCE)
    {
        //new bool:crit = bool:GetEntProp(entity, Prop_Send, "m_bCritical");
        new offset = GetEntSendPropOffs(entity, "m_bCritical");
        new bool:crit = (offset >= 0) ? (bool:GetEntDataEnt2(entity, offset)) : false;

        new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
        new target = EntRefToEntIndex(targetRef);

        decl String:classname[32];
        if (GetEdictClassname(entity, classname , sizeof(classname)) &&
            StrEqual(classname, "tf_projectile_sentryrocket"))
        {
            owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");
        }

        // Check with other plugins/forward (if any)
        new Action:res = Plugin_Continue;
        Call_StartForward(g_fwdOnSeek);
        Call_PushCell(owner);
        Call_PushCell(target);
        Call_PushCell(entity);
        Call_PushCell(crit);
        Call_Finish(res);

        if (res == Plugin_Continue)
            target = INVALID_ENT_REFERENCE;
    }

    return targetRef;
}

getClosestTarget(entity, targetList[], targetCount)
{
    //make list of all valid client`s distance from rocket
    //and find closest distance
    new Float:closest;
    new Float:distance[MaxClients];

    for (new i = 0; i < targetCount; i++)
    {
        new Float:entOrigin[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entOrigin);

        new Float:targetOrigin[3];
        GetClientEyePosition(targetList[i], targetOrigin);

        new Float:dist = distance[i] = GetVectorDistance(entOrigin, targetOrigin);
        if (i == 0 || closest > dist)
            closest = dist;
    }

    //make a list of clients where thier distance is same as closest
    //most of time, there will be only 1 client in this list
    new count = 0;
    new list[MaxClients];

    for (new i = 0; i < targetCount; i++)
    {
        if (distance[i] == closest)
            list[count++] = targetList[i];
    }

    //get and return random client.
    return EntIndexToEntRef(list[GetRandomInt(0, count - 1)]);
}

bool:isValidTarget(entity, target)
{
    if (target > 0 && target < MaxClients && IsClientInGame(target) && IsPlayerAlive(target) && !IsClientObserver(target))
    {
        if (GetEntProp(entity, Prop_Send, "m_iTeamNum") != GetClientTeam(target))
        {
            return true;
        }
    }

    return false;
}

bool:isTargetTraceable(entity, target)
{
    new bool:traceable = false;
    new bool:targetvalid = ((g_SidewinderFlags[target] & TrackingClientIsDetected) != NoTracking);

    if (!targetvalid && !((g_SidewinderFlags[target] & TrackingClientIsCloaked) != NoTracking))
    {
        //은폐를 사용중인가?
        if (TF2_IsPlayerInCondition(target, TFCond_Cloaked))
        {
            //보이는 상황인가?
            targetvalid = (TF2_IsPlayerInCondition(target, TFCond_CloakFlicker)
                           || TF2_IsPlayerInCondition(target, TFCond_OnFire)
                           || TF2_IsPlayerInCondition(target, TFCond_Jarated)
                           || TF2_IsPlayerInCondition(target, TFCond_Milked)
                           || TF2_IsPlayerInCondition(target, TFCond_Bleeding)
                           || TF2_IsPlayerInCondition(target, TFCond_Disguising));
        }
        else
        {
            //변장을 했고, 변장이 끝났는가?
            targetvalid = !(!TF2_IsPlayerInCondition(target, TFCond_Disguising)
                            && TF2_IsPlayerInCondition(target, TFCond_Disguised)
                            && (GetEntProp(target, Prop_Send, "m_nDisguiseTeam")
                                == GetEntProp(entity, Prop_Send, "m_iTeamNum")));
        }
    }

    if (targetvalid)
    {
        //타겟까지 트레이스가 가능한가
        decl Float:entityposition[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);

        decl Float:clientpos[3];
        GetClientEyePosition(target, clientpos);

        if (!g_bToHead[entity])
        {
            clientpos[2] = clientpos[2] - 25.0;
        }

        new Handle:traceresult = TR_TraceRayFilterEx(entityposition, clientpos, MASK_SOLID,
                                                     RayType_EndPoint, tracerayfilterdefault,
                                                     entity);

        if (TR_GetEntityIndex(traceresult) == target)
        {
            traceable = true;
        }
        CloseHandle(traceresult);
    }

    return traceable;
}

//트레이스레이필터
public bool:tracerayfilterdefault(entity, mask, any:data)
{
    return (entity != data);
}

public Native_Control(Handle:plugin,numParams)
{
    g_bNativeControl = (numParams >= 1) ? (bool:GetNativeCell(1)) : true;
}

public Native_SetFlags(Handle:plugin,numParams)
{
    if (GetNativeCell(3))
        g_SidewinderFlags[GetNativeCell(1)] = SidewinderClientFlags:GetNativeCell(2);
    else        
        g_SidewinderFlags[GetNativeCell(1)] |= (SidewinderClientFlags:GetNativeCell(2) & (~TrackingClientStatus));
}

public Native_TrackChance(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    g_iTrackChance[client] = GetNativeCell(2);

    new critChance = GetNativeCell(3);
    g_iTrackCritChance[client] = (critChance < 0) ? g_iTrackChance[client] : critChance;
}

public Native_SentryCritChance(Handle:plugin,numParams)
{
    g_iSentryCritChance[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_DesignateClient(Handle:plugin,numParams)
{
    if (GetNativeCell(2))
        g_SidewinderFlags[GetNativeCell(1)] |= TrackingClientIsDesignated;
    else        
        g_SidewinderFlags[GetNativeCell(1)] &= ~TrackingClientIsDesignated;
}

public Native_CloakClient(Handle:plugin,numParams)
{
    if (GetNativeCell(2))
        g_SidewinderFlags[GetNativeCell(1)] |= TrackingClientIsCloaked;
    else        
        g_SidewinderFlags[GetNativeCell(1)] &= ~TrackingClientIsCloaked;
}

public Native_DetectClient(Handle:plugin,numParams)
{
    if (GetNativeCell(2))
        g_SidewinderFlags[GetNativeCell(1)] |= TrackingClientIsDetected;
    else        
        g_SidewinderFlags[GetNativeCell(1)] &= ~TrackingClientIsDetected;
}
