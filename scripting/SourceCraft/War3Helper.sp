/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Helper.sp
 * Description: Helper natives for War3Source compatability.
 * Author(s): PimpinJuice(Anthony Iacono) and Ownz
 * Adapted to SourceCraft by: -=|JFH|=-Naris
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <gametype>
#include <ResourceManager>

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <trace>

#include "sc/SourceCraft"
#include "sc/maxhealth"
#include "sc/client"

#include "effect/SendEffects"

//#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/War3Source_Constants"
#include "W3SIncs/mana"

#define VERSION_NUM "1.2.1.8"
#define REVISION_NUM 12108 //increment every release

#define g_Game                      GameType
#define War3_GetGame()              GameType
#define GameTF()                    (GameType == tf2)
#define GameCS()                    GameTypeIsCS()

#define War3_GetRace                GetRace
#define War3_GetRacesLoaded         GetRaceCount
#define GetCurrentWeaponEnt         GetActiveWeapon

#define War3_GetMaxHP(%1)           g_iMaxXP[%1]

#define W3GetDamageType()           g_CurDamageType
#define W3GetDamageInflictor()      g_CurInflictor

#define W3HasImmunity               GetImmunity
#define W3GetDamageIsBullet()       NW3GetDamageIsBullet(INVALID_HANDLE,0)
#define W3ForceDamageIsBullet()     NW3ForceDamageIsBullet(INVALID_HANDLE,0)

new const String:abilityReadySound[]="war3source/ability_refresh.mp3";
new const String:ultimateReadySound[]="war3source/ult_ready.wav";

// Forwards
new Handle:g_OnWar3RaceChangedHandle;
new Handle:g_OnWar3RaceSelectedHandle;
new Handle:g_OnWar3UltimateCommandHandle;
new Handle:g_OnAbilityCommandHandle;
new Handle:g_OnWar3PluginReadyHandle; //loadin default races in order
new Handle:g_OnWar3PluginReadyHandle2; //other races
new Handle:g_OnWar3PluginReadyHandle3; //other races backwards compatable
new Handle:g_War3InterfaceExecFH;
new Handle:g_OnWar3EventSpawnFH;
new Handle:g_OnWar3EventDeathFH;
new Handle:g_War3GlobalEventFH; 
new Handle:g_hfwddenyable; 
//new Handle:g_OnWar3EventRoundStartFH;
//new Handle:g_OnWar3EventRoundEndFH;

// Forwards from War3Source_Engine_DamageSystem
new Handle:FHOnW3TakeDmgAllPre;
new Handle:FHOnW3TakeDmgBulletPre;
new Handle:FHOnW3TakeDmgAll;
new Handle:FHOnW3TakeDmgBullet;

new Handle:g_OnWar3EventPostHurtFH;

// Convars
new Handle:hUseMetric;

// Offsets
new MyWeaponsOffset;
new Clip1Offset;
new AmmoOffset;

// SDK Handles
new Handle:hSDKWeaponDrop;

// GameFrame tracking definitions
new Float:fAngle[65][3];
new Float:fPos[65][3];
new bool:bDucking[65];
new iWeapon[65][10][2]; // [client][iterator][0-ent/1-clip1]
new iAmmo[65][32];
new iDeadAmmo[65][32];
new iDeadClip1[65][10];
new String:sWepName[65][10][64];
new bool:bIgnoreTrackGF[65];

// MaxHP
new g_iMaxXP[MAXPLAYERS+1]; // kinda hacky
new any:W3VarArr[W3Var];

// Damage
new g_CurDamageType=0;
new g_CurInflictor=0; //variables from sdkhooks, natives retrieve them if needed
new g_CurDamageIsWarcraft=0; //for this damage only
new g_CurDamageIsTrueDamage=0; //not used yet?

new Float:g_CurDMGModifierPercent=1.0;

new g_CurLastActualDamageDealt=0;

new bool:g_CanSetDamageMod=false; //default false, you may not change damage percent when there is none to change
new bool:g_CanDealDamage=true; //default true, you can initiate damage out of nowhere

new Float:LastDamageDealtTime[MAXPLAYERSCUSTOM];
new Float:ChanceModifier[MAXPLAYERSCUSTOM];

//for deal damage only
new g_NextDamageIsWarcraftDamage=0;
new g_NextDamageIsTrueDamage=0;

new damagestack=0;

// Weapons Restrictions
new String:weaponsAllowed[MAXPLAYERSCUSTOM][MAXRACES][300];
new restrictionPriority[MAXPLAYERSCUSTOM][MAXRACES];
new highestPriority[MAXPLAYERSCUSTOM];
new bool:restrictionEnabled[MAXPLAYERSCUSTOM][MAXRACES]; ///if restriction has length, then this should be true (caching allows quick skipping)

new bool:hasAnyRestriction[MAXPLAYERSCUSTOM]; //if any of the races said client has restriction, this is true (caching allows quick skipping)
// Events
new bool:notdenied=true;
new timerskip;

// Expire Timer stuff
#define MAXTHREADS 2000
new Float:expireTime[MAXTHREADS];
new threadsLoaded;

public Plugin:myinfo= 
{
    name="War3Helper",
    author="Naris, PimpinJuice and Ownz",
    description="War3Source compatibility for SourceCraft.",
    version=SOURCECRAFT_VERSION,
    url="http://war3source.com/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    if(!War3Source_InitNatives())
    {
        PrintToServer("[War3Source] There was a failure in creating the native based functions, definately halting.");
        return APLRes_Failure;
    }
    else if(!War3Source_InitForwards())
    {
        PrintToServer("[War3Source] There was a failure in creating the forward based functions, definately halting.");
        return APLRes_Failure;
    }
    else
        return APLRes_Success;
}

public OnPluginStart()
{
    GetGameType();

    if(!War3Source_InitCVars())
        SetFailState("[War3Source] There was a failure in initiating console variables.");

    if(!War3Source_InitHooks())
        SetFailState("[War3Source] There was a failure in initiating the hooks.");

    if(!War3Source_InitOffset())
        SetFailState("[War3Source] There was a failure in finding the offsets required.");

    if(War3_GetGame()==CS)
    {
        new Handle:hGameConf = LoadGameConfigFile("plugin.war3source");
        if(hGameConf == INVALID_HANDLE)
        {
            SetFailState("gamedata/plugin.war3source.txt load failed");
        }

        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CSWeaponDrop");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        hSDKWeaponDrop = EndPrepSDKCall();
        if(hSDKWeaponDrop == INVALID_HANDLE){
            SetFailState("Unable to find WeaponDrop Signature");
        }
    }

    if (hSDKWeaponDrop != INVALID_HANDLE)
        CreateTimer(0.1,WeaponRestrictionTimer,_,TIMER_REPEAT);
}

public OnSourceCraftReady()
{
    //ordered loads
    new res;
    for(new i;i<=MAXRACES*10;i++){
        Call_StartForward(g_OnWar3PluginReadyHandle);
        Call_PushCell(i);
        Call_Finish(res);
    }

    //orderd loads 2
    for(new i;i<=MAXRACES*10;i++){
        Call_StartForward(g_OnWar3PluginReadyHandle2);
        Call_PushCell(i);
        Call_Finish(res);
    }

    //unorderd loads
    Call_StartForward(g_OnWar3PluginReadyHandle3);
    Call_Finish(res);
}

public OnMapStart()
{
    new dummyreturn;
    Call_StartForward(g_War3InterfaceExecFH);
    Call_Finish(dummyreturn);

    for(new i=0;i<sizeof(expireTime);i++){
        expireTime[i]=0.0;
    }

    SetupSound(abilityReadySound, true,  ALWAYS_DOWNLOAD, true, true);
    SetupSound(ultimateReadySound, true, ALWAYS_DOWNLOAD, true, true);
}

public OnClientPutInServer(client)
{
    DoFwd_War3_Event(InitPlayerVariables,client);

    // Weapons Restrictions

    new limit=War3_GetRacesLoaded();
    for(new raceid=0;raceid<=limit;raceid++)
    {
        restrictionEnabled[client][raceid]=false;
    }

    CalculateWeaponRestCache(client);

    //weapon touch and equip only
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);

    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
}

public OnClientDisconnect(client)
{
    DoFwd_War3_Event(ClearPlayerVariables,client);

    // Weapons Restrictions
    SDKUnhook(client,SDKHook_WeaponCanUse,OnWeaponCanUse); 

    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook); 
}

public OnEntityCreated(entity, const String:classname[])
{
    if (GameType == tf2)
    {
        if (StrEqual(classname, "headless_hatman") ||  // TF2 Bosses
            StrEqual(classname, "eyeball_boss")    ||
            StrEqual(classname, "merasmus")        ||
            StrEqual(classname, "tank_boss"))
        {
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
        }
#if 0
        else if (strncmp(classname, "obj_", 4) == 0)
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
#endif
    }
    else if (GameType == l4d || GameType == l4d2)
    {
        if (StrEqual(classname, "infected", false) ||  // Left4Dead
            StrEqual(classname, "witch", false))
        {
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
        }
    }
}

new ignoreClient;
public NWar3_GetAimEndPoint(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new Float:angle[3];
    GetClientEyeAngles(client,angle);
    new Float:endpos[3];
    new Float:startpos[3];
    GetClientEyePosition(client,startpos);
    
    ignoreClient=client;
    TR_TraceRayFilter(startpos,angle,MASK_ALL,RayType_Infinite,AimTargetFilter);
    TR_GetEndPosition(endpos);
    
    SetNativeArray(2,endpos,3);
}
public NWar3_GetAimTraceMaxLen(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new Float:angle[3];
    GetClientEyeAngles(client,angle);
    new Float:endpos[3];
    new Float:startpos[3];
    GetClientEyePosition(client,startpos);
    new Float:dir[3];
    GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
    
    ScaleVector(dir, GetNativeCell(3));
    AddVectors(startpos, dir, endpos);
    
    ignoreClient=client;
    TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
    
    TR_GetEndPosition(endpos); //overwrites to actual end pos
    
    SetNativeArray(2,endpos,3);
}
public bool:AimTargetFilter(entity,mask)
{
    return !(entity==ignoreClient);
}
public bool:CanHitThis(entityhit, mask, any:data)
{
    if(entityhit == data )
    {// Check if the TraceRay hit the itself.
        return false; // Don't allow self to be hit, skip this result
    }
    if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
        return false; //skip result, prend this space is not taken cuz they on same team
    }
    return true; // It didn't hit itself
}

public Native_War3_GetTargetInViewCone(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    if(ValidPlayer(client))
    {
        new Float:max_distance=GetNativeCell(2);
        new bool:include_friendlys=GetNativeCell(3);
        new Float:cone_angle=GetNativeCell(4);
        new Function:FilterFunction=GetNativeCell(5);
        if(max_distance<0.0)    max_distance=0.0;
        if(cone_angle<0.0)  cone_angle=0.0;

        new Float:PlayerEyePos[3];
        new Float:PlayerAimAngles[3];
        new Float:PlayerToTargetVec[3];
        new Float:OtherPlayerPos[3];
        GetClientEyePosition(client,PlayerEyePos);
        GetClientEyeAngles(client,PlayerAimAngles);
        new Float:ThisAngle;
        new Float:playerDistance;
        new Float:PlayerAimVector[3];
        GetAngleVectors(PlayerAimAngles,PlayerAimVector,NULL_VECTOR,NULL_VECTOR);
        new bestTarget=0;
        new Float:bestTargetDistance;
        for(new i=1;i<=MaxClients;i++)
        {
            if(cone_angle<=0.0) break;
            if(ValidPlayer(i,true)&& client!=i)
            {
                if(FilterFunction!=INVALID_FUNCTION)
                {
                    Call_StartFunction(plugin,FilterFunction);
                    Call_PushCell(i);
                    new result;
                    if(Call_Finish(result)>SP_ERROR_NONE)
                    {
                        result=1; // bad callback, lets return 1 to be safe
                        new String:plugin_name[256];
                        GetPluginFilename(plugin,plugin_name,sizeof(plugin_name));
                        PrintToServer("[War3Source] ERROR in plugin \"%s\" traced to War3_GetTargetInViewCone(), bad filter function provided.",plugin_name);
                    }
                    if(result==0)
                    {
                        continue;
                    }
                }
                if(!include_friendlys && GetClientTeam(client) == GetClientTeam(i))
                {
                    continue;
                }
                GetClientEyePosition(i,OtherPlayerPos);
                playerDistance = GetVectorDistance(PlayerEyePos,OtherPlayerPos);
                if(max_distance>0.0 && playerDistance>max_distance)
                {
                    continue;
                }
                SubtractVectors(OtherPlayerPos,PlayerEyePos,PlayerToTargetVec);
                ThisAngle=ArcCosine(GetVectorDotProduct(PlayerAimVector,PlayerToTargetVec)/(GetVectorLength(PlayerAimVector)*GetVectorLength(PlayerToTargetVec)));
                ThisAngle=ThisAngle*360/2/3.14159265;
                if(ThisAngle<=cone_angle)
                {
                    ignoreClient=client;
                    TR_TraceRayFilter(PlayerEyePos,OtherPlayerPos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
                    if(TR_DidHit())
                    {
                        new entity=TR_GetEntityIndex();
                        if(entity!=i)
                        {
                            continue;
                        }
                    }
                    if(bestTarget>0)
                    {
                        if(playerDistance<bestTargetDistance)
                        {
                            bestTarget=i;
                            bestTargetDistance=playerDistance;
                        }
                    }
                    else
                    {
                        bestTarget=i;
                        bestTargetDistance=playerDistance;
                    }
                }
            }
        }
        if(bestTarget==0)
        {
            new Float:endpos[3];
            if(max_distance>0.0)
                ScaleVector(PlayerAimVector,max_distance);
            else
            {
                ScaleVector(PlayerAimVector,56756.0);
                AddVectors(PlayerEyePos,PlayerAimVector,endpos);
                TR_TraceRayFilter(PlayerEyePos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
                if(TR_DidHit())
                {
                    new entity=TR_GetEntityIndex();
                    if(entity>0 && entity<=MaxClients && IsClientConnected(entity) && IsPlayerAlive(entity) && GetClientTeam(client)!=GetClientTeam(entity) )
                    {
                        new result=1;
                        if(FilterFunction!=INVALID_FUNCTION)
                        {
                            Call_StartFunction(plugin,FilterFunction);
                            Call_PushCell(entity);
                            if(Call_Finish(result)>SP_ERROR_NONE)
                            {
                                result=1; // bad callback, return 1 to be safe
                                new String:plugin_name[256];
                                GetPluginFilename(plugin,plugin_name,sizeof(plugin_name));
                                PrintToServer("[War3Source] ERROR in plugin \"%s\" traced to War3_GetTargetInViewCone(), bad filter function provided.",plugin_name);
                            }
                        }
                        if(result!=0)
                        {
                            bestTarget=entity;
                        }
                    }
                }
            }
        }
        return bestTarget;
    }
    return 0;
}

public NW3LOS(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new target=GetNativeCell(2);
    if(ValidPlayer(client,true)&&ValidPlayer(target,true))
    {
        new Float:PlayerEyePos[3];
        new Float:OtherPlayerPos[3];
        GetClientEyePosition(client,PlayerEyePos);
        GetClientAbsOrigin(target,OtherPlayerPos);
        ignoreClient=client;
        TR_TraceRayFilter(PlayerEyePos,OtherPlayerPos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
        if(TR_DidHit())
        {
            new entity=TR_GetEntityIndex();
            if(entity==target)
            {
                return true;
            }
        }
    }
    return false;
}

public Native_War3_CachedAngle(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client=GetNativeCell(1);
        SetNativeArray(2,fAngle[client],3);
    }
}

public Native_War3_CachedPosition(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client=GetNativeCell(1);
        SetNativeArray(2,fPos[client],3);
    }
}

public Native_War3_CachedDucking(Handle:plugin,numParams)
{
    if(numParams==1)
    {
        new client=GetNativeCell(1);
        return (bDucking[client])?1:0;
    }
    return 0;
}

public Native_War3_CachedWeapon(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client=GetNativeCell(1);
        new iter=GetNativeCell(2);
        if (iter>=0 && iter<10)
        {
            return iWeapon[client][iter][0];
        }
    }
    return 0;
}

public Native_War3_CachedClip1(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client=GetNativeCell(1);
        new iter=GetNativeCell(2);
        if (iter>=0 && iter<10)
        {
            return iWeapon[client][iter][1];
        }
    }
    return 0;
}

public Native_War3_CachedAmmo(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client=GetNativeCell(1);
        new id=GetNativeCell(2);
        if (id>=0 && id<32)
        {
            return iAmmo[client][id];
        }
    }
    return 0;
}

public Native_War3_CachedDeadClip1(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client=GetNativeCell(1);
        new iter=GetNativeCell(2);
        if (iter>=0 && iter<10)
        {
            return iDeadClip1[client][iter];
        }
    }
    return 0;
}

public Native_War3_CachedDeadAmmo(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client=GetNativeCell(1);
        new id=GetNativeCell(2);
        if (id>=0 && id<32)
        {
            return iDeadAmmo[client][id];
        }
    }
    return 0;
}

public Native_War3_CDWN(Handle:plugin,numParams)
{
    if(numParams==4)
    {
        new client=GetNativeCell(1);
        new iter=GetNativeCell(2);
        if (iter>=0 && iter<10)
        {
            SetNativeString(3,sWepName[client][iter],GetNativeCell(4));
        }
    }
}

public Native_War3_TF_PTC(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        if (GameType == tf2 && GetMode() != MvM)
        {
            new entities = EntitiesAvailable(200, .message="Reducing Effects");
            if (entities > 50)
            {
                new client = GetNativeCell(1);
                new String:str[32];
                GetNativeString(2, str, 31);
                new Float:pos[3];
                GetNativeArray(3,pos,3);
                TE_ParticleToClient(client,str,pos);
            }
        }
    }
}

TE_ParticleToClient(client,
            String:Name[],
            Float:origin[3]=NULL_VECTOR,
            Float:start[3]=NULL_VECTOR,
            Float:angles[3]=NULL_VECTOR,
            entindex=-1,
            attachtype=-1,
            attachpoint=-1,
            bool:resetParticles=true,
            Float:delay=0.0)
{
    if (GameType == tf2 && GetMode() != MvM)
    {
        new entities = EntitiesAvailable(200, .message="Reducing Effects");
        if (entities > 50)
        {
            // find string table
            new tblidx = FindStringTable("ParticleEffectNames");
            if (tblidx==INVALID_STRING_TABLE) 
            {
                LogError("Could not find string table: ParticleEffectNames");
                return;
            }

            // find particle index
            new String:tmp[256];
            new count = GetStringTableNumStrings(tblidx);
            new stridx = INVALID_STRING_INDEX;
            new i;
            for (i=0; i<count; i++)
            {
                ReadStringTable(tblidx, i, tmp, sizeof(tmp));
                if (StrEqual(tmp, Name, false))
                {
                    stridx = i;
                    break;
                }
            }
            if (stridx==INVALID_STRING_INDEX)
            {
                LogError("Could not find particle: %s", Name);
                return;
            }

            TE_Start("TFParticleEffect");
            TE_WriteFloat("m_vecOrigin[0]", origin[0]);
            TE_WriteFloat("m_vecOrigin[1]", origin[1]);
            TE_WriteFloat("m_vecOrigin[2]", origin[2]);
            TE_WriteFloat("m_vecStart[0]", start[0]);
            TE_WriteFloat("m_vecStart[1]", start[1]);
            TE_WriteFloat("m_vecStart[2]", start[2]);
            TE_WriteVector("m_vecAngles", angles);
            TE_WriteNum("m_iParticleSystemIndex", stridx);
            if (entindex!=-1)
            {
                TE_WriteNum("entindex", entindex);
            }
            if (attachtype!=-1)
            {
                TE_WriteNum("m_iAttachType", attachtype);
            }
            if (attachpoint!=-1)
            {
                TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
            }
            TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
            if(client==0)
            {
                TE_SendEffectToAll(delay);
            }
            else
            {
                TE_SendEffectToClient(client, delay);
            }
        }
    }
}

///should be deprecated
public Native_War3_SetMaxHP(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new hp=GetNativeCell(2);
    if(client>0 && client<=MaxClients)
        g_iMaxXP[client]=hp;
}

public Native_War3_GetMaxHP(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    if(client>0 && client<MaxClients)
        return g_iMaxXP[client];
    return 0;
}

public Native_War3_HTMHP(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client = GetNativeCell(1);
        new addhp = GetNativeCell(2);
        new maxhp=War3_GetMaxHP(client);
        new currenthp=GetClientHealth(client);
        
        if (addhp<0)
            LogError("Attempted negative Heal %d:%N's curhp=%d, addhp=%d,maxhp=%d", client, client, currenthp, addhp, maxhp);
        else if (currenthp>0&&currenthp<maxhp){ ///do not make hp lower
            new newhp=currenthp+addhp;
            if (newhp>maxhp){
                newhp=maxhp;
            }
            SetEntityHealth(client,newhp);
        }
    }
}

public Native_War3_HTBHP(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client = GetNativeCell(1);
        new addhp = GetNativeCell(2);
        new maxhp=(g_Game=Game_TF)?RoundFloat(float(War3_GetMaxHP(client))*1.5):War3_GetMaxHP(client);
        
        new currenthp=GetClientHealth(client);
        if (addhp<0)
            LogError("Attempted negative HealToBuff %d:%N's curhp=%d, addhp=%d,maxhp=%d", client, client, currenthp, addhp, maxhp);
        else if (currenthp>0&&currenthp<maxhp){ ///do not make hp lower
            new newhp=currenthp+addhp;
            if (newhp>maxhp){
                newhp=maxhp;
            }
            SetEntityHealth(client,newhp);
        }
    }
}

public Native_War3_DecreaseHP(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new client = GetNativeCell(1);
        new dechp = GetNativeCell(2);
        new newhp=GetClientHealth(client)-dechp;
        if(newhp<0){
            newhp=0;
        }
        SetEntityHealth(client,newhp);
    }
}

public NW3GetW3Revision(Handle:plugin,numParams)
{
    return REVISION_NUM;
}
public NW3GetW3Version(Handle:plugin,numParams)
{
    SetNativeString(1,VERSION_NUM,GetNativeCell(2));
}

public NW3CreateEvent(Handle:plugin,numParams)
{

    new event=GetNativeCell(1);
    new client=GetNativeCell(2);
    DoFwd_War3_Event(W3EVENT:event,client);
}

DoFwd_War3_Event(W3EVENT:event,client)
{
    new dummyreturn;
    Call_StartForward(g_War3GlobalEventFH);
    Call_PushCell(event);
    Call_PushCell(client);
    Call_Finish(dummyreturn);
}

public NW3Denied(Handle:plugin,numParams)
{
    new dummyreturn;
    notdenied=true;
    Call_StartForward(g_hfwddenyable);
    Call_PushCell(GetNativeCell(1)); //event,/
    Call_PushCell(GetNativeCell(2));    //client
    Call_Finish(dummyreturn);
    return !notdenied;
}

public NW3Deny(Handle:plugin,numParams)
{
    notdenied=false;
}

public Action:War3Source_AbilityCommand(client,args)
{
    decl String:command[32];
    GetCmdArg(0,command,32);

    new bool:pressed=(command[0]=='+');

    new num = 0;
    if (IsCharNumeric(command[8]))
        num=_:command[8]-48;

    new result;
    Call_StartForward(g_OnAbilityCommandHandle);
    Call_PushCell(client);
    Call_PushCell(num);
    Call_PushCell(pressed);
    Call_Finish(result);
    return Plugin_Handled;
}

public OnUltimateCommand(client,race,bool:pressed,arg)
{
    if (arg <= 1)
    {
        new result;
        Call_StartForward(g_OnWar3UltimateCommandHandle);
        Call_PushCell(client);
        Call_PushCell(race);
        Call_PushCell(pressed);
        Call_Finish(result);
    }
    else
    {
        new result;
        Call_StartForward(g_OnAbilityCommandHandle);
        Call_PushCell(client);
        Call_PushCell(arg-2);
        Call_PushCell(pressed);
        Call_Finish(result);
    }
}

public Action:OnRaceSelected(client,oldrace,newrace)
{
    new result;
    W3VarArr[OldRace]=oldrace;

    Call_StartForward(g_OnWar3RaceSelectedHandle);
    Call_PushCell(client);
    Call_PushCell(newrace);
    Call_Finish(result);

    Call_StartForward(g_OnWar3RaceChangedHandle);
    Call_PushCell(client);
    Call_PushCell(oldrace);
    Call_PushCell(newrace);
    Call_Finish(result);
    return Plugin_Continue;
}

public OnPlayerSpawnEvent(Handle:event, client, race)
{
    g_iMaxXP[client]=GetClientHealth(client);

    new result;
    Call_StartForward(g_OnWar3EventSpawnFH);
    Call_PushCell(client);
    Call_Finish(result);
}

public OnPlayerDeathEvent(Handle:event,victim_index,victim_race, attacker_index,
                          attacker_race,assister_index,assister_race,
                          damage,const String:weapon[], bool:is_equipment,
                          customkill,bool:headshot,bool:backstab,bool:melee)
{
    new result;
    W3VarArr[DeathRace]=victim_race;
    W3VarArr[SmEvent]=_:event; //stacking on stack 
    Call_StartForward(g_OnWar3EventDeathFH);
    Call_PushCell(victim_index);
    Call_PushCell(attacker_index);
    Call_PushCell(victim_race);
    Call_Finish(result);

    g_CurDamageIsWarcraft=false;
}

public OnTakeDamagePostHook(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
    TraceInto("War3Helper", "OnTakeDamagePostHook", "victim=%N, attacker=%N, damage=%d, absorbed=%d, damagestack=%d", \
              ValidClientIndex(victim_index), ValidClientIndex(attacker_index), damage, absorbed, damagestack);

    // GHOSTS!!
    if (weapon == -1 && inflictor == -1)
    {
        TraceError("OnTakeDamagePostHook: Who was pho^H^H^Hweapon?");
        TraceReturn();
        return;
    }
    
    damagestack++;
    
    new bool:old_CanDealDamage=g_CanDealDamage;
    g_CanSetDamageMod=true;
    
    g_CurInflictor = inflictor;
    
    // Figure out what really hit us. A weapon? A sentry gun?
    new String:weaponName[64];
    new realWeapon = weapon == -1 ? inflictor : weapon;
    GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));

    TraceInfo("OnTakeDamagePostHook called with weapon \"%s\"", weaponName);

    new dummyresult;
    Call_StartForward(g_OnWar3EventPostHurtFH);
    Call_PushCell(victim);
    Call_PushCell(attacker);
    Call_PushFloat(damage);
    Call_PushString(weaponName);
    Call_PushCell(g_CurDamageIsWarcraft);
    Call_Finish(dummyresult);
    
    g_CanDealDamage=old_CanDealDamage;
    
    damagestack--;
    
    g_CurLastActualDamageDealt = RoundToFloor(damage);

    TraceReturn();
}

public Action:OnXPGiven(client,&amount,bool:taken)
{
    //set event vars
    W3VarArr[EventArg1]=0; // W3XPAwardedBy:awardedfromevent
    W3VarArr[EventArg2]=amount;
    W3VarArr[EventArg3]=0;
    DoFwd_War3_Event(OnPreGiveXPGold,client); //fire event
    new addxp=W3VarArr[EventArg2]; //retrieve possibly modified vars
    if (addxp != amount)
    {
        amount = addxp;
        return Plugin_Changed;
    }
    else
        return Plugin_Continue;
}

public Action:OnCrystalsGiven(client,&amount,bool:taken)
{
    //set event vars
    W3VarArr[EventArg1]=0; // W3XPAwardedBy:awardedfromevent
    W3VarArr[EventArg2]=0;
    W3VarArr[EventArg3]=amount;
    DoFwd_War3_Event(OnPreGiveXPGold,client); //fire event
    new addgold=W3VarArr[EventArg3]; //retrieve possibly modified vars
    if (addgold != amount)
    {
        amount = addgold;
        return Plugin_Changed;
    }
    else
        return Plugin_Continue;
}

public Native_W3ChanceModifier(Handle:plugin,numParams)
{
    new attacker=GetNativeCell(1);
    if(!GameTF()||attacker<=0 || attacker>MaxClients || !IsValidEdict(attacker))
        return _:1.0;
    else
        return _:ChanceModifier[attacker];
}

public Native_War3_DamageModPercent(Handle:plugin,numParams)
{
    if(!g_CanSetDamageMod){
        LogError("You may not set damage mod percent here, use ....Pre forward");
        //W3LogError("You may not set damage mod percent here, use ....Pre forward");
        //PrintPlugin(plugin);
    }

    new Float:num=GetNativeCell(1); 
    g_CurDMGModifierPercent*=num;
}

public NW3GetDamageType(Handle:plugin,numParams)
{
    return g_CurDamageType;
}

public NW3GetDamageInflictor(Handle:plugin,numParams)
{
    return g_CurInflictor;
}

public NW3GetDamageIsBullet(Handle:plugin,numParams)
{
    return _:(!g_CurDamageIsWarcraft ||
              !GetDamageFromPlayerHurt() ||
              !GetSuppressDamageForward());
}

public NW3ForceDamageIsBullet(Handle:plugin,numParams)
{
    g_CurDamageIsWarcraft=false;
}

public NW3GetDamageStack(Handle:plugin,numParams)
{
    return damagestack;
}

public Native_War3_GetWar3DamageDealt(Handle:plugin,numParams)
{
    return g_CurLastActualDamageDealt;
}

Float:PhysicalArmorMulti(client)
{
    new Float:armor=GetPhysicalArmorSum(client);
    return (1.0-(armor*0.06)/(1+armor*0.06));
}

Float:MagicArmorMulti(client)
{
    new Float:armor=GetMagicalArmorSum(client);
    return (1.0-(armor*0.06)/(1+armor*0.06));
}

public Native_NotifyPlayerTookDamageFromSkill(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    new damage = GetNativeCell(3);
    new skill = GetNativeCell(4);

    decl String:short[32];
    decl  String:name[32];

    if (skill == 0)
        short[0] = name[0] = '\0';
    else
    {
        new race = GetRace(attacker);
        GetUpgradeName(race, skill, short, sizeof(short));
        GetUpgradeName(race, skill, name, sizeof(name));
    }

    DisplayDamage(attacker, victim, damage, short, name);
}

stock War3_SetCSArmor(client,amount)
{
    if (War3_GetGame()==Game_CS)
    {
        if (amount>125)
            amount=125;

        SetEntProp(client,Prop_Send,"m_ArmorValue",amount);
    }
}

stock War3_GetCSArmor(client)
{
    if (War3_GetGame()==Game_CS)
        return GetEntProp(client,Prop_Send,"m_ArmorValue");
    else        
        return 0;
}

public Native_War3_DealDamage(Handle:plugin,numParams)
{
    new bool:whattoreturn=true;
    if(!g_CanDealDamage){
        LogError("War3_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
    }

    new victim=GetNativeCell(1);
    new damage=GetNativeCell(2);
    new attacker=GetNativeCell(3);

    TraceInto("War3Helper", "DealDamage", "victim=%d:%N, attacker=%d:%N, damage=%d, damagestack=%d", \
              victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), damage, damagestack);

    if (ValidPlayer(victim,true) && damage>0 )
    {
        //new old_DamageDealt=g_CurActualDamageDealt;
        new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
        new old_IsTrueDamage = g_CurDamageIsTrueDamage;

        new old_NextDamageIsWarcraftDamage=g_NextDamageIsWarcraftDamage; 
        new old_NextDamageIsTrueDamage=g_NextDamageIsTrueDamage;

        g_CurLastActualDamageDealt=-88;

        new dmg_type=GetNativeCell(4);  //original weapon damage type

        decl String:weapon[64];
        GetNativeString(5,weapon,64);

        new War3DamageOrigin:W3DMGORIGIN=GetNativeCell(6);
        new War3DamageType:WAR3_DMGTYPE=GetNativeCell(7);

        new bool:respectVictimImmunity=GetNativeCell(8);

        if (respectVictimImmunity)
        {
            switch(W3DMGORIGIN)
            {
                case W3DMGORIGIN_SKILL:
                {
                    if(W3HasImmunity(victim,Immunity_Skills) )
                        return false;
                }
                case W3DMGORIGIN_ULTIMATE:
                {
                    if(W3HasImmunity(victim,Immunity_Ultimates) )
                        return false;
                }
                case W3DMGORIGIN_ITEM:
                {
                    if(W3HasImmunity(victim,Immunity_Items) )
                        return false;
                }
            }

            switch(WAR3_DMGTYPE)
            {
                case W3DMGTYPE_PHYSICAL:
                {
                    if(W3HasImmunity(victim,Immunity_PhysicalDamage) )
                        return false;
                }
                case W3DMGTYPE_MAGIC:
                {
                    if(W3HasImmunity(victim,Immunity_MagicDamage) )
                        return false;
                }
            }
        }

        new bool:countAsFirstTriggeredDamage=GetNativeCell(9);
        g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage=!countAsFirstTriggeredDamage;

        //new bool:settobullet=bool:W3GetDamageIsBullet(); //just in case someone dealt damage inside this forward and made it "not bullet"
        decl oldcsarmor;
        if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS)
        {
            oldcsarmor=War3_GetCSArmor(victim);
            War3_SetCSArmor(victim,0) ;
        }

        g_CurDamageIsTrueDamage=g_NextDamageIsTrueDamage=(WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG);

        if (damage < 1)
            damage = 1;

        damagestack++;

        Trace("DealDamage: victim=%d:%N, attacker=%d:%N, health=%d, damage=%d, damagestack=%d, weapon=%s", \
              victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), GetClientHealth(victim), \
              damage, damagestack, weapon);

        HurtPlayer(victim,damage,attacker,weapon, .type=dmg_type,
                   .ignore_immunity=!respectVictimImmunity,
                   .category=W3DMGORIGIN|WAR3_DMGTYPE,
                   .no_translate=true);

        if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS)
            War3_SetCSArmor(victim,oldcsarmor);

        if(g_CurLastActualDamageDealt==-88){
            g_CurLastActualDamageDealt=0;
            whattoreturn=false;
        }

        g_CurDamageIsWarcraft= old_IsWarcraftDamage;

        g_CurDamageIsTrueDamage = old_IsTrueDamage;

        g_NextDamageIsWarcraftDamage=old_NextDamageIsWarcraftDamage; 
        g_NextDamageIsTrueDamage=old_NextDamageIsTrueDamage;
    }
    else
    {
        whattoreturn=false;
    }

    TraceReturn();
    return whattoreturn;
}

public Action:OnPlayerTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
    new Action:result = Plugin_Continue;
    if (IsPlayerAlive(victim))
    {
        //store old variables on local stack!

        new old_DamageType= g_CurDamageType;
        new old_Inflictor= g_CurInflictor;
        new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
        new Float:old_DamageModifierPercent = g_CurDMGModifierPercent;
        new old_IsTrueDamage = g_CurDamageIsTrueDamage;

        //set these to global
        g_CurDamageType=damagetype;
        g_CurInflictor=inflictor;
        g_CurDMGModifierPercent=1.0;
        g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
        g_CurDamageIsTrueDamage=g_NextDamageIsTrueDamage;

        #if defined _TRACE
            static count = 0;

            TraceInto("War3Helper", "OnPlayerTakeDamage", "count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d, damagestack=%d, g_CurDamageIsWarcraft=%d, g_CurDamageIsTrueDamage=%d, g_CurDMGModifierPercent=%f", \
                      count, victim, ValidClientIndex(victim), attacker, inflictor, damage, damagetype, damagestack, \
                      g_CurDamageIsWarcraft, g_CurDamageIsTrueDamage, g_CurDamageIsTrueDamage);
        #endif

        damagestack++;

        new Float:modifier = 1.0;
        if(g_CurDamageIsWarcraft)
        {
            modifier = MagicArmorMulti(victim);
            //damage=FloatMul(damage,W3GetMagicArmorMulti(victim));
            //PrintToChatAll("magic %f %d to %d",MagicArmorMulti(victim),attacker,victim);
            Trace("magic=%f, %d to %d, damage=%f",modifier,attacker,victim,damage);
        }
        else if(!g_CurDamageIsTrueDamage) //bullet 
        {
            modifier = PhysicalArmorMulti(victim);
            //damage=FloatMul(damage,W3GetPhysicalArmorMulti(victim));
            //PrintToChatAll("physical %f %d to %d",PhysicalArmorMulti(victim),attacker,victim);
            Trace("physical=%f, %d to %d, damage=%f",modifier,attacker,victim,damage);
            //g_CurDamageIsWarcraft=false;
        }

        if (modifier != 1.0)
        {
            damage *= modifier;
            Trace("modifier=%f, %d to %d, damage=%f",modifier,attacker,victim,damage);
            result = Plugin_Changed;
        }

        if(!g_CurDamageIsWarcraft && ValidPlayer(attacker)){
            new Float:now=GetGameTime();
            
            new Float:value=now-LastDamageDealtTime[attacker];
            if(value>1.0||value<0.0){
                ChanceModifier[attacker]=1.0;
            }
            else{
                ChanceModifier[attacker]=value;
            }
            //DP("%f",ChanceModifier[attacker]);
            LastDamageDealtTime[attacker]=GetGameTime();
        }
        //else it is true damage
        //PrintToChatAll("takedmg %f BULLET %d   lastiswarcraft %d",damage,isBulletDamage,g_CurDamageIsWarcraft);

        new bool:old_CanSetDamageMod=g_CanSetDamageMod;
        new bool:old_CanDealDamage=g_CanDealDamage;
        g_CanSetDamageMod=true;
        g_CanDealDamage=false;

        new Action:dummyresult;
        Call_StartForward(FHOnW3TakeDmgAllPre);
        Call_PushCell(victim);
        Call_PushCell(attacker);
        Call_PushCell(damage);
        Call_Finish(dummyresult);

        if(!g_CurDamageIsWarcraft)
        {
            Call_StartForward(FHOnW3TakeDmgBulletPre);
            Call_PushCell(victim);
            Call_PushCell(attacker);
            Call_PushCell(damage);
            Call_Finish(dummyresult);
        }

        g_CanSetDamageMod=false;
        g_CanDealDamage=true;

        if (g_CurDMGModifierPercent>0.001)
        {
            // so if damage is already canceled, no point in forwarding the second part,
            // do we dont get: evaded but still recieve warcraft damage proc)
            Call_StartForward(FHOnW3TakeDmgAll);
            Call_PushCell(victim);
            Call_PushCell(attacker);
            Call_PushCell(damage);
            Call_Finish(dummyresult);

            if (!g_CurDamageIsWarcraft)
            {
                Call_StartForward(FHOnW3TakeDmgBullet);
                Call_PushCell(victim);
                Call_PushCell(attacker);
                Call_PushCell(damage);
                Call_Finish(dummyresult);
            }
        }

        g_CanSetDamageMod=old_CanSetDamageMod;
        g_CanDealDamage=old_CanDealDamage;

        //modify final damage
        if (g_CurDMGModifierPercent != 1.0)
        {
            damage=damage*g_CurDMGModifierPercent; ////so we calculate the percent 
            Trace("g_CurDMGModifierPercent=%f %d to %d, damage=%f",g_CurDMGModifierPercent,attacker,victim,damage);
            result = Plugin_Changed;
        }

        //nobobdy retrieves our global variables outside of the forward call, restore old stack vars
        g_CurDamageType= old_DamageType;
        g_CurInflictor= old_Inflictor;
        g_CurDamageIsWarcraft= old_IsWarcraftDamage;
        g_CurDMGModifierPercent = old_DamageModifierPercent;
        g_CurDamageIsTrueDamage = old_IsTrueDamage;

        damagestack--;

        #if defined _TRACE
            Trace("count=%d:victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d, damagestack=%d, result=%d", \
                  count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, \
                  damage,  damagetype, damagestack, result);

            count++;
        #endif
    }

    TraceReturn("result=%d", result);
    return result;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer(client))
    {
        bDucking[client]=((buttons & IN_DUCK) != 0);
    }
    return Plugin_Continue;
}

// Game Frame tracking
public OnGameFrame()
{
    for(new x=1;x<=MaxClients;x++)
    {
        if(IsClientConnected(x)&&IsClientInGame(x)&&IsPlayerAlive(x)&&!bIgnoreTrackGF[x])
        {
            GetClientEyeAngles(x,fAngle[x]);
            GetClientAbsOrigin(x,fPos[x]);
            new cur_wep=0;
            for(new s=0;s<10;s++)
            {
                // null values
                iWeapon[x][s][0]=0;
                iWeapon[x][s][1]=0;
            }
            for(new s=0;s<32;s++)
            {
                iAmmo[x][s]=GetEntData(x,AmmoOffset+(s*4),4);
            }
            for(new s=0;s<10;s++)
            {
                new ent=GetEntDataEnt2(x,MyWeaponsOffset+(s*4));
                if(ent>0)
                {
                    iWeapon[x][cur_wep][0]=ent;
                    iWeapon[x][cur_wep][1]=GetEntData(ent,Clip1Offset,4);
                    ++cur_wep;
                }
            }
        }
    }
}

War3Source_InitCVars()
{
    hUseMetric=CreateConVar("war3_metric_system","0","Do you want use metric system? 1-Yes, 0-No");
    W3VarArr[hUseMetricCvar]=_:hUseMetric;

    return true;
}

bool:War3Source_InitHooks()
{
    RegConsoleCmd("+ability",War3Source_AbilityCommand);
    RegConsoleCmd("-ability",War3Source_AbilityCommand);
    RegConsoleCmd("+ability0",War3Source_AbilityCommand);
    RegConsoleCmd("-ability0",War3Source_AbilityCommand);
    RegConsoleCmd("+ability1",War3Source_AbilityCommand);
    RegConsoleCmd("-ability1",War3Source_AbilityCommand);
    RegConsoleCmd("+ability2",War3Source_AbilityCommand);
    RegConsoleCmd("-ability2",War3Source_AbilityCommand);
    RegConsoleCmd("+ability3",War3Source_AbilityCommand);
    RegConsoleCmd("-ability3",War3Source_AbilityCommand);
    RegConsoleCmd("+ability4",War3Source_AbilityCommand);
    RegConsoleCmd("-ability4",War3Source_AbilityCommand);
    RegConsoleCmd("+ability5",War3Source_AbilityCommand);
    RegConsoleCmd("-ability5",War3Source_AbilityCommand);
    RegConsoleCmd("+ability6",War3Source_AbilityCommand);
    RegConsoleCmd("-ability6",War3Source_AbilityCommand);
    return true;
}

bool:War3Source_InitNatives()
{
    CreateNative("W3ChanceModifier",Native_W3ChanceModifier);
    CreateNative("War3_CachedAngle",Native_War3_CachedAngle);
    CreateNative("War3_CachedPosition",Native_War3_CachedPosition);
    CreateNative("War3_CachedDucking",Native_War3_CachedDucking);
    CreateNative("War3_CachedWeapon",Native_War3_CachedWeapon);
    CreateNative("War3_CachedClip1",Native_War3_CachedClip1);
    CreateNative("War3_CachedAmmo",Native_War3_CachedAmmo);
    CreateNative("War3_CachedDeadClip1",Native_War3_CachedDeadClip1);
    CreateNative("War3_CachedDeadAmmo",Native_War3_CachedDeadAmmo);
    CreateNative("War3_CachedDeadWeaponName",Native_War3_CDWN);
    CreateNative("War3_TF_ParticleToClient",Native_War3_TF_PTC);
    CreateNative("War3_HealToMaxHP",Native_War3_HTMHP);
    CreateNative("War3_HealToBuffHP",Native_War3_HTBHP);
    CreateNative("War3_DecreaseHP",Native_War3_DecreaseHP);
    CreateNative("War3_GetMaxHP",Native_War3_GetMaxHP);
    CreateNative("War3_SetMaxHP_INTERNAL",Native_War3_SetMaxHP);    

    CreateNative("W3CreateEvent",NW3CreateEvent);//foritems
    CreateNative("W3Denied",NW3Denied);
    CreateNative("W3Deny",NW3Deny);

    CreateNative("War3_RegisterDelayTracker",NWar3_RegisterDelayTracker);
    CreateNative("War3_TrackDelay",NWar3_TrackDelay);
    CreateNative("War3_TrackDelayExpired",NWar3_TrackDelayExpired);

    CreateNative("W3GetW3Version",NW3GetW3Version);
    CreateNative("W3GetW3Revision",NW3GetW3Revision);

    CreateNative("War3_DamageModPercent",Native_War3_DamageModPercent);

    CreateNative("W3GetDamageType",NW3GetDamageType);
    CreateNative("W3GetDamageInflictor",NW3GetDamageInflictor);
    CreateNative("W3GetDamageIsBullet",NW3GetDamageIsBullet);
    CreateNative("W3ForceDamageIsBullet",NW3ForceDamageIsBullet);

    CreateNative("War3_DealDamage",Native_War3_DealDamage);
    CreateNative("War3_GetWar3DamageDealt",Native_War3_GetWar3DamageDealt);

    CreateNative("W3GetDamageStack",NW3GetDamageStack);

    CreateNative("W3GetVar",NW3GetVar);
    CreateNative("W3SetVar",NW3SetVar);

    CreateNative("W3GetRaceString",NW3GetRaceString);
    CreateNative("W3GetRaceSkillString",NW3GetRaceSkillString);

    CreateNative("War3_AddRaceSkill",NWar3_AddRaceSkill);
    CreateNative("War3_AddRaceSkillT",NWar3_AddRaceSkillT);

    // from War3Source_Engine_PlayerTrace
    CreateNative("W3LOS",NW3LOS);
    CreateNative("War3_GetAimEndPoint",NWar3_GetAimEndPoint);
    CreateNative("War3_GetAimTraceMaxLen",NWar3_GetAimTraceMaxLen);
    CreateNative("War3_GetTargetInViewCone",Native_War3_GetTargetInViewCone);

    // from War3Source_Engine_Weapon
    CreateNative("War3_WeaponRestrictTo",NWar3_WeaponRestrictTo);
    CreateNative("W3GetCurrentWeaponEnt",NW3GetCurrentWeaponEnt);
    CreateNative("W3DropWeapon",NW3DropWeapon);

    // Generic Skills from War3Source_Engine_RaceClass
    CreateNative("War3_CreateGenericSkill",NWar3_CreateGenericSkill);
    CreateNative("War3_UseGenericSkill",NWar3_UseGenericSkill);
    CreateNative("W3_GenericSkillLevel",NW3_GenericSkillLevel);

    // Mana natives from mana.inc
    CreateNative("W3SetMana",N_W3SetMana);
    CreateNative("W3GetMana",N_W3GetMana);
    CreateNative("W3PrintMana",N_W3PrintMana);
    CreateNative("W3Hint",NW3Hint);

    // Notify natives
    CreateNative("War3_NotifyPlayerTookDamageFromSkill", Native_NotifyPlayerTookDamageFromSkill);

    return true;
}

bool:War3Source_InitForwards()
{
    g_OnWar3UltimateCommandHandle=CreateGlobalForward("OnWar3UltimateCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnAbilityCommandHandle=CreateGlobalForward("OnAbilityCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    g_OnWar3RaceSelectedHandle=CreateGlobalForward("OnWar3RaceSelected",ET_Ignore,Param_Cell,Param_Cell);
    g_OnWar3RaceChangedHandle=CreateGlobalForward("OnRaceChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    g_OnWar3EventSpawnFH=CreateGlobalForward("OnWar3EventSpawn",ET_Ignore,Param_Cell);
    g_OnWar3EventDeathFH=CreateGlobalForward("OnWar3EventDeath",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    g_OnWar3PluginReadyHandle=CreateGlobalForward("OnWar3LoadRaceOrItemOrdered",ET_Ignore,Param_Cell);//ordered
    g_OnWar3PluginReadyHandle2=CreateGlobalForward("OnWar3LoadRaceOrItemOrdered2",ET_Ignore,Param_Cell);//ordered
    g_OnWar3PluginReadyHandle3=CreateGlobalForward("OnWar3PluginReady",ET_Ignore); //unodered rest of the items or races. backwards compatable..
    g_War3InterfaceExecFH=CreateGlobalForward("War3InterfaceExec",ET_Ignore);

    FHOnW3TakeDmgAllPre=CreateGlobalForward("OnW3TakeDmgAllPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    FHOnW3TakeDmgBulletPre=CreateGlobalForward("OnW3TakeDmgBulletPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    FHOnW3TakeDmgAll=CreateGlobalForward("OnW3TakeDmgAll",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    FHOnW3TakeDmgBullet=CreateGlobalForward("OnW3TakeDmgBullet",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

    g_OnWar3EventPostHurtFH = CreateGlobalForward("OnWar3EventPostHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_String, Param_Cell);
    g_War3GlobalEventFH=CreateGlobalForward("OnWar3Event",ET_Ignore,Param_Cell,Param_Cell);
    g_hfwddenyable=CreateGlobalForward("OnW3Denyable",ET_Ignore,Param_Cell,Param_Cell);

    return true;
}

bool:War3Source_InitOffset()
{
    new bool:ret=true;

    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    if(MyWeaponsOffset==-1)
    {
        PrintToServer("[War3Source] Error finding weapon list offset.");
        ret=false;
    }

    Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
    if(Clip1Offset==-1)
    {
        PrintToServer("[War3Source] Error finding clip1 offset.");
        ret=false;
    }

    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
    if(AmmoOffset==-1)
    {
        PrintToServer("[War3Source] Error finding ammo offset.");
        ret=false;
    }

    return ret;
}

stock bool:ValidPlayer(client,bool:check_alive=false)
{
    if (IsValidClient(client))
        return (!check_alive || (GetClientTeam(client) > 1 && IsPlayerAlive(client)));
    else
        return false;
}

public NWar3_RegisterDelayTracker(Handle:plugin,numParams)
{
    if(threadsLoaded<MAXTHREADS){
        return threadsLoaded++;
    }
    LogError("[War3Helper] DELAY TRACKER MAXTHREADS LIMIT REACHED! return -1");
    return -1;
}
public NWar3_TrackDelay(Handle:plugin,numParams)
{
    new index=GetNativeCell(1);
    new Float:delay=GetNativeCell(2);
    expireTime[index]=GetGameTime()+delay;
}
public NWar3_TrackDelayExpired(Handle:plugin,numParams)
{
    return GetGameTime()>expireTime[GetNativeCell(1)];
}

public NW3GetVar(Handle:plugin,numParams){
    return _:W3VarArr[War3Var:GetNativeCell(1)];
}
public NW3SetVar(Handle:plugin,numParams){
    W3VarArr[War3Var:GetNativeCell(1)]=GetNativeCell(2);
}

public NW3GetRaceString(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);

    decl String:longbuf[1000];
    switch (RaceString:GetNativeCell(2))
    {
        case RaceName:
        {
            GetRaceName(race, longbuf, sizeof(longbuf));
        }            
        case RaceShortname:
        {
            GetRaceShortName(race, longbuf, sizeof(longbuf));
        }            
        case RaceDescription, RaceStory:
        {
            GetRaceDescription(race, longbuf, sizeof(longbuf));
        }
        default:
        {
            longbuf[0] = '\0'; 
        }
    }
    SetNativeString(3,longbuf,GetNativeCell(4));
}

public NW3GetRaceSkillString(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new skill=GetNativeCell(2);

    decl String:longbuf[1000];
    switch (SkillString:GetNativeCell(3))
    {
        case (SkillString:SkillName):
        {
            GetUpgradeName(race, skill, longbuf, sizeof(longbuf));
        }            
        case SkillDescription, SkillStory:
        {
            GetUpgradeDescription(race, skill, longbuf, sizeof(longbuf));
        }
        default:
        {
            longbuf[0] = '\0'; 
        }
    }
    SetNativeString(4,longbuf,GetNativeCell(5));
}

//translated
//native War3_AddRaceSkillT(raceid,String:SkillNameIdentifier[],bool:isult,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);
public NWar3_AddRaceSkillT(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    new String:skillname[64];
    GetNativeString(2,skillname,sizeof(skillname));
    new bool:isult=bool:GetNativeCell(3);
    new maxskilllevel=GetNativeCell(4);

    decl String:parm[8][64];
    for (new i=0; i<sizeof(parm); i++)
        parm[i][0] = '\0';

    if(numParams>4)
    {
        for(new arg=5, i=0; arg<=numParams; arg++, i++)
            GetNativeString(arg,parm[i],sizeof(parm[]));
    }

    new newskillnum = AddUpgrade(raceid,skillname,_:isult,.max_level=maxskilllevel,
                                 .p1=parm[0], .p2=parm[1], .p3=parm[2], .p4=parm[3],
                                 .p5=parm[4], .p6=parm[5], .p7=parm[6], .p8=parm[7]);

    decl String:description[2048];
    new category = GetUpgradeDescription(raceid, newskillnum, description, sizeof(description));

    category = get_category(category, skillname, description, isult);
    if (category != _:isult)
        SetUpgradeCategory(raceid, newskillnum, category);

    return newskillnum;
}


public NW3GetCurrentWeaponEnt(Handle:plugin,numParams){
    return GetActiveWeapon(GetNativeCell(1));
}

public NW3DropWeapon(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new wpent = GetNativeCell(2);
    if (hSDKWeaponDrop != INVALID_HANDLE && ValidPlayer(client,true) && IsValidEdict(wpent))
        SDKCall(hSDKWeaponDrop, client, wpent, false, false);
}

public NWar3_WeaponRestrictTo(Handle:plugin,numParams)
{
    
    new client=GetNativeCell(1);
    new raceid=GetNativeCell(2);
    new String:restrictedto[300];
    GetNativeString(3,restrictedto,sizeof(restrictedto));
    
    restrictionPriority[client][raceid]=GetNativeCell(4);
    //new String:pluginname[100];
    //GetPluginFilename(plugin, pluginname, 100);
    //PrintToServer("%s NEW RESTRICTION: %s",pluginname,restrictedto);
    //LogError("%s NEW RESTRICTION: %s",pluginname,restrictedto);
    //PrintIfDebug(client,"%s NEW RESTRICTION: %s",pluginname,restrictedto);
    strcopy(weaponsAllowed[client][raceid],200,restrictedto);
    CalculateWeaponRestCache(client);
}

CalculateWeaponRestCache(client){
    new num=0;
    new limit=War3_GetRacesLoaded();
    new highestpri=0;
    for(new raceid=0;raceid<=limit;raceid++){
        restrictionEnabled[client][raceid]=(strlen(weaponsAllowed[client][raceid])>0)?true:false;
        if(restrictionEnabled[client][raceid]){
            
            
            num++;
            if(restrictionPriority[client][raceid]>highestpri){
                highestpri=restrictionPriority[client][raceid];
            }
        }
    }
    hasAnyRestriction[client]=num>0?true:false;
    
    
    highestPriority[client]=highestpri;
    
    timerskip=0; //force next timer to check weapons
}

bool:CheckCanUseWeapon(client,weaponent){
    decl String:WeaponName[32];
    GetEdictClassname(weaponent, WeaponName, sizeof(WeaponName));
    
    if(StrContains(WeaponName,"c4")>-1){ //allow c4
        return true;
    }
    
    new limit=War3_GetRacesLoaded();
    for(new raceid=0;raceid<=limit;raceid++){
        if(restrictionEnabled[client][raceid]&&restrictionPriority[client][raceid]==highestPriority[client]){ //cached strlen is not zero
            if(StrContains(weaponsAllowed[client][raceid],WeaponName)<0){ //weapon name not found
                return false;
            }
        }
    }
    return true; //allow
}


public Action:OnWeaponCanUse(client, weaponent)
{
    if(hasAnyRestriction[client]){
        if(CheckCanUseWeapon(client,weaponent))
        {
            return Plugin_Continue; //ALLOW
        }
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action:WeaponRestrictionTimer(Handle:h,any:a){
    timerskip--;
    if(timerskip<1){
        timerskip=10;
        for(new client=1;client<=MaxClients;client++){
            /*if(true){ //test
            new wpnent = GetCurrentWeaponEnt(client);
            if(FindSendPropOffs("CWeaponUSP","m_bSilencerOn")>0){
            
            SetEntData(wpnent,FindSendPropOffs("CWeaponUSP","m_bSilencerOn"),true,true);
            }
            
            }*/
            
            if(hasAnyRestriction[client]&&ValidPlayer(client,true)){
                
                new String:name[32];
                GetClientName(client,name,sizeof(name));
                //PrintToChatAll("ValidPlayer %d",client);
                
                new wpnent = GetCurrentWeaponEnt(client);
                //PrintIfDebug(client,"   weapon ent %d %d",client,wpnent);
                //new String:WeaponName[32];
                
                //if(IsValidEdict(wpnent)){
                
                //  }
                
                //PrintIfDebug(client,"    %s res: (%s) weapon: %s",name,weaponsAllowed[client],WeaponName);        
                //  if(strlen(weaponsAllowed[client])>0){
                if(wpnent>0&&IsValidEdict(wpnent)){
                    
                    
                    if (CheckCanUseWeapon(client,wpnent)){
                        //allow
                    }
                    else
                    {
                        //RemovePlayerItem(client,wpnent);
                        
                        //PrintIfDebug(client,"            drop");
                        
                        
                        SDKCall(hSDKWeaponDrop, client, wpnent, false, false);
                        AcceptEntityInput(wpnent, "Kill");
                        //UTIL_Remove(wpnent);
                        
                    }
                    
                }
                else{
                    //PrintIfDebug(client,"no weapon");
                    //PrintToChatAll("no weapon");
                }
                //  }
            }
        }
    }
}

// Generic Skills

//adds a skill or a ultimate
//native War3_AddRaceSkill(raceid,String:tskillorultname[],String:tskillorultdescription[],bool:isult=false,maxskilllevel=DEF_MAX_SKILL_LEVEL);
public NWar3_AddRaceSkill(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);

    decl String:skillname[64];
    GetNativeString(2,skillname,sizeof(skillname));

    decl String:skilldesc[2001];
    GetNativeString(3,skilldesc,sizeof(skilldesc));

    new bool:isult=GetNativeCell(4);
    new maxskilllevel=GetNativeCell(5);

    return AddRaceSkill(raceid,skillname,skillname,skilldesc,isult,maxskilllevel);
}

stock AddRaceSkill(raceid,const String:shortname[],const String:name[],const String:description[],bool:isult=false,maxskilllevel=DEF_MAX_SKILL_LEVEL)
{
    decl String:short[16];
    fix_short(short, sizeof(short), shortname);

    decl String:desc[2048];
    new category = fix_ability(desc, sizeof(desc), description, isult);
    return AddUpgrade(raceid, short, get_category(category, name, description, isult),
                      .max_level=maxskilllevel, .name=name, .desc=desc);
}

stock fix_short(String:buffer[], maxlength, const String:short[])
{
    for(new i=0;i<maxlength;i++)
    {
        new c = short[i];
        if (c == '\0')
        {
            buffer[i] = '\0';
            break;
        }
        else if (c == ' ' || c == '/' || c == '\\')
            buffer[i] = '_';
        else if (IsCharUpper(c))
            buffer[i] = CharToLower(c);
        else
            buffer[i] = c;
    }
    buffer[maxlength] = '\0';
}

stock fix_ability(String:buffer[], maxlength, const String:desc[], bool:isult=false)
{
    new category = _:isult;
    strcopy(buffer, maxlength, desc);

    if (ReplaceString(buffer, maxlength, "+ability2", "+ultimate4", false) > 0)
        category = 4;

    if (ReplaceString(buffer, maxlength, "ability2",  "+ultimate4", false) > 0)
        category = 4;

    if (ReplaceString(buffer, maxlength, "+ability1", "+ultimate3", false) > 0)
        category = 3;

    if (ReplaceString(buffer, maxlength, "ability1",  "+ultimate3", false) > 0)
        category = 3;

    if (ReplaceString(buffer, maxlength, "+ability0", "+ultimate2", false) > 0)
        category = 2;

    if (ReplaceString(buffer, maxlength, "ability0",  "+ultimate2", false) > 0)
        category = 2;

    if (ReplaceString(buffer, maxlength, "+ability",  "+ultimate2", false) > 0)
        category = 2;

    if (ReplaceString(buffer, maxlength, "(ability)", "+ultimate2", false) > 0)
        category = 2;

    //ReplaceString(buffer, maxlength, "ability", "+ultimate2", false);
    return category;
}

stock get_category(category, const String:name[], const String:desc[], bool:isult=false)
{
    if (isult)
        return _:isult; // probably 1
    else if (category > 0)
        return category;
    else if (StrContains(desc, "ability2", false) >= 0   ||
             StrContains(desc, "ultimate4", false) >= 0  ||
             StrContains(name, "ability2", false) >= 0   ||
             StrContains(name, "ultimate4", false) >= 0)
    {
        return 4;
    }
    else if (StrContains(desc, "ability1", false) >= 0   ||
             StrContains(desc, "ultimate3", false) >= 0  ||
             StrContains(name, "ability1", false) >= 0   ||
             StrContains(name, "ultimate3", false) >= 0)
    {
        return 3;
    }
    else if (StrContains(desc, "+ability", false) >= 0   ||
             StrContains(desc, "(ability)", false) >= 0  ||
             StrContains(desc, "+ultimate2", false) >= 0 ||
             StrContains(desc, "ultimate2", false) >= 0  ||
             StrContains(name, "+ability", false) >= 0   ||
             StrContains(name, "(ability)", false) >= 0  ||
             StrContains(name, "+ultimate2", false) >= 0 ||
             StrContains(name, "ultimate2", false) >= 0)
    {
        return 2;
    }
    else if (StrContains(desc, "ultimate1", false) >= 0  ||
             StrContains(desc, "+ultimate", false) >= 0  ||
             StrContains(name, "ultimate1", false) >= 0  ||
             StrContains(name, "+ultimate", false) >= 0)
    {
        return 1;
    }
    else
        return category;
}

#define War3_GetSkillLevel(%1,%2,%3) GetUpgradeLevel(%1,%2,%3,true)

new genericskillcount=0;

//how many skills can use a generic skill, limited for memory
#define MAXCUSTOMERRACES 32
enum GenericSkillClass
{
    String:cskillname[32], 
    redirectedfromrace[MAXCUSTOMERRACES], //theset start from 0!!!!
    redirectedfromskill[MAXCUSTOMERRACES],
    redirectedcount, //how many races are using this generic skill, first is 1, loop from 1 to <=redirected count
    Handle:raceskilldatahandle[MAXCUSTOMERRACES], //handle the customer races passed us
}

//55 generic skills
new GenericSkill[55][GenericSkillClass];
public NWar3_CreateGenericSkill(Handle:plugin,numParams){
    new String:tempgenskillname[32];
    GetNativeString(1,tempgenskillname,32);
    
    //find existing
    for(new i=1;i<=genericskillcount;i++){
        
        if(StrEqual(tempgenskillname,GenericSkill[i][cskillname])){
            return i;
        }
    }
    
    //no existing found, add 
    genericskillcount++;
    GetNativeString(1,GenericSkill[genericskillcount][cskillname],32);
    return genericskillcount;
}
public NWar3_UseGenericSkill(Handle:plugin,numParams){
    new raceid=GetNativeCell(1);
    new String:genskillname[32];
    GetNativeString(2,genskillname,sizeof(genskillname));
    new Handle:genericSkillData=Handle:GetNativeCell(3);
    //start from 1
    for(new i=1;i<=genericskillcount;i++){
        //DP("1 %s %s ]",genskillname,GenericSkill[i][cskillname]);
        if(StrEqual(genskillname,GenericSkill[i][cskillname])){
            //DP("2");
            if(raceid>0){
            
                
            
                //DP("3");
                new String:raceskillname[2001];
                new String:raceskilldesc[2001];
                GetNativeString(4,raceskillname,sizeof(raceskillname));
                GetNativeString(5,raceskilldesc,sizeof(raceskilldesc));
                
                //new bool:istranaslated=GetNativeCell(6);
                
                //native War3_UseGenericSkill(raceid,String:gskillname[],Handle:genericSkillData,String:yourskillname[],String:untranslatedSkillDescription[],bool:translated=false,bool:isUltimate=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);

                new bool:isult=GetNativeCell(7);
                new tmaxskilllevel=GetNativeCell(8);
                
                //W3Log("add skill %s %s",skillname,skilldesc);
                
                new newskillnum;
                newskillnum = AddRaceSkill(raceid,raceskillname,raceskillname,raceskilldesc,isult,tmaxskilllevel);
                /*
                if(istranaslated){
                    skillTranslated[raceid][newskillnum]=true;  
                }
                */
                
                //check that the data handle isnt leaking
                new genericcustomernumber=GenericSkill[i][redirectedcount];
                for(new j=0;j<genericcustomernumber;j++){
                    if(
                    GenericSkill[i][redirectedfromrace][j]==raceid
                    &&
                    GenericSkill[i][redirectedfromskill][j]==newskillnum
                    ){
                        if(GenericSkill[i][raceskilldatahandle][j]!=INVALID_HANDLE && GenericSkill[i][raceskilldatahandle][j] !=genericSkillData){
                            //DP("ERROR POSSIBLE HANDLE LEAK, NEW GENERIC SKILL DATA HANDLE PASSED, CLOSING OLD GENERIC DATA HANDLE");
                            CloseHandle(GenericSkill[i][raceskilldatahandle][j]);
                            GenericSkill[i][raceskilldatahandle][j]=genericSkillData;
                        }   
                    }
                    
                }
                
                
                //first time creating the race
                //if(ignoreRaceEnd==false)
                {
                    //variable args start at 8
                    /*
                    for(new arg=9;arg<=numParams;arg++){
                    
                        GetNativeString(arg,raceSkillDescReplace[raceid][newskillnum][raceSkillDescReplaceNum[raceid][newskillnum]],64);
                        raceSkillDescReplaceNum[raceid][newskillnum]++;
                    }
                    
                    SkillRedirected[raceid][newskillnum]=true;
                    SkillRedirectedToSkill[raceid][newskillnum]=i;
                    */
                    
                    
                    GenericSkill[i][raceskilldatahandle][genericcustomernumber]=genericSkillData;
                    GenericSkill[i][redirectedfromrace][GenericSkill[i][redirectedcount]]=raceid;
                    
                    GenericSkill[i][redirectedfromskill][GenericSkill[i][redirectedcount]]=newskillnum;
                    GenericSkill[i][redirectedcount]++;
                    //DP("FOUND GENERIC SKILL %d, real skill id for race %d",i,newskillnum);
                }
                
                return newskillnum;
                    
            }
        }
    }
    LogError("NO GENREIC SKILL FOUND");
    return 0;
}

//native W3_GenericSkillLevel(client,g_skill_id,&Handle:genericSkillData,&customerRaceID=0,&customerSkillID=0);
public NW3_GenericSkillLevel(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new genericskill=GetNativeCell(2);
    new count=GenericSkill[genericskill][redirectedcount];
    new found=0;
    new level=0;
    new reallevel=0;
    new customernumber=0;
    new clientrace=War3_GetRace(client);
    //DP("customer count %d genericskill %d",count,genericskill);
    for(new i=0;i<count;i++){
        if(clientrace==GenericSkill[genericskill][redirectedfromrace][i]){
            level = War3_GetSkillLevel( client, GenericSkill[genericskill][redirectedfromrace][i], GenericSkill[genericskill][redirectedfromskill][i]);
            //DP("real skill %d %d %d",GenericSkill[genericskill][redirectedfromrace][i], GenericSkill[genericskill][redirectedfromskill][i],level);
            if(level){ 
                found++;
                reallevel=level;
                customernumber=i;
            }
        }
    }
    if(found>1)
    {
        LogError("ERR FOUND MORE THAN 1 GERNIC SKILL MATCH");
        return 0;
    }
    if(found){
        SetNativeCellRef(3,GenericSkill[genericskill][raceskilldatahandle][customernumber]);
        if(numParams>=4){
            SetNativeCellRef(4, GenericSkill[genericskill][redirectedfromrace][customernumber]);
        }
        if(numParams>=5){
            SetNativeCellRef(5, GenericSkill[genericskill][redirectedfromskill][customernumber]);
        }
    }
    return reallevel;
}

public N_W3SetMana(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new ManaType:type=ManaType:GetNativeCell(2);
    new any:value=any:GetNativeCell(1);

    switch (type)
    {
        case iValue:        SetEnergy(client, value);
        case iRegen:        SetEnergyRate(client, value);
        case iSpawnValue:   SetInitialEnergy(client, value);
    //  case iRoundValue: 
        case iMaxCap:       SetEnergyLimit(client, value);
    //  case szPrefix: 
    //  case bActive: 
    //  case aColor: 
    }
}

public N_W3GetMana(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new ManaType:type=ManaType:GetNativeCell(2);

    switch (type)
    {
        case iValue:        return RoundToNearest(GetEnergy(client));
        case iRegen:        return RoundToNearest(GetEnergyRate(client));
        case iSpawnValue:   return RoundToNearest(GetInitialEnergy(client));
        case iRoundValue:   return 0;
        case iMaxCap:       return RoundToNearest(GetEnergyLimit(client));
        case szPrefix:      return SetNativeString(3, "Energy", GetNativeCell(4));
        case bActive:       return (GetRaceEnergyFlags(GetRace(client)) > NoEnergy);
        case aColor:        return SetNativeArray(3, {255, 255, 255, 255}, 4);
    }
    return 0;
}


public N_W3PrintMana(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    //new duration=GetNativeCell(2);
    //decl rgba[4];
    //GetNativeArray(3,rgba,4);
    ShowEnergy(client);
}

public NW3Hint(Handle:plugin,numParams)
{
    new client= GetNativeCell(1);
    if (ValidPlayer(client))
    {
        new W3HintPriority:priority=W3HintPriority:GetNativeCell(2);
        new Float:Duration=GetNativeCell(3);
        if(Duration>20.0)
        {
            Duration=20.0;
        }   

        new String:format[128];
        GetNativeString(4,format,sizeof(format));

        new written;
        new String:output[256];
        FormatNativeString(0, 4, 5, sizeof(output), written, output);

        DisplayHint(client, HintSlot:priority,
                    (W3GetHintPriorityType(priority) == HINT_TYPE_SINGLE),
                    Duration, output);
    }
}
