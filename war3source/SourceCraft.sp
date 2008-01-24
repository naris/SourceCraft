/**
 * vim: set ai et ts=4 sw=4 :
 * File: SourceCraft.sp
 * Description: The main file for SourceCraft.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 *
 * $Id$
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <keyvalues>

new m_FirstSpawn[MAXPLAYERS + 1] = {1, ...}; // Cheap trick
#define VERSION_NUM "1.0 $Revision$"
#define VERSION     "$Revision$"

// Temporary Definitions
new Handle:arrayPlayers = INVALID_HANDLE;

// ConVar definitions
new Handle:m_SaveXPConVar         = INVALID_HANDLE;
new Handle:m_MinimumUltimateLevel = INVALID_HANDLE;
new Handle:m_MaxCredits           = INVALID_HANDLE;
new Handle:m_Currency             = INVALID_HANDLE; 
new Handle:m_Currencies           = INVALID_HANDLE; 

#define SAVE_ENABLED       GetConVarInt(m_SaveXPConVar)==1
#define MIN_ULTIMATE_LEVEL GetConVarInt(m_MinimumUltimateLevel)
#define MAX_CREDITS        GetConVarInt(m_MaxCredits)

// SourceCraft Includes
#include "War3Source/help"
#include "War3Source/util"
#include "War3Source/damage"
#include "War3Source/immunity"
#include "War3Source/offsets"
#include "War3Source/races"
#include "War3Source/xp"
#include "War3Source/events"
#include "War3Source/events_tf2"
#include "War3Source/events_cstrike"
#include "War3Source/credits"
#include "War3Source/console"
#include "War3Source/shopmenu"
#include "War3Source/weapons"
#include "War3Source/playertracking"
#include "War3Source/db"
#include "War3Source/natives"
#include "War3Source/hooks"
#include "War3Source/menus"
#include "War3Source/log"
#include "War3Source/strtoken"

new bool:m_CalledReady=false;

public Plugin:myinfo= 
{
    name="SourceCraft",
    author="Naris (with some PimpinJuice code)",
    description="StarCraft/WarCraft for the Source engine.",
    version=VERSION_NUM,
    url="http://www.jigglysfunhouse.net/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    if(!InitNatives())
    {
        PrintToServer("[SourceCraft] There was a failure in creating the native based functions, definately halting.");
        return false;
    }
    if(!InitForwards())
    {
        PrintToServer("[SourceCraft] There was a failure in creating the forward based functions.");
        return false;
    }
    return true;
}

public OnPluginStart()
{
    PrintToServer("-------------------------------------------------------------------------\n[SourceCraft] Plugin loading...");

    GetGameType();
    
    arrayPlayers=CreateArray();
    if(!InitiatearrayRaces())
        SetFailState("[SourceCraft] There was a failure in creating the race vector.");
    if(!InitiateShopVector())
        SetFailState("[SourceCraft] There was a failure in creating the shop vector.");
    if(!InitiateHelpVector())
        SetFailState("[SourceCraft] There was a failure in creating the help vector.");

    if(!HookEvents())
        SetFailState("[SourceCraft] There was a failure in initiating event hooks.");

    if (GameType == tf2)
    {
        if(!HookTFEvents())
            SetFailState("[SourceCraft] There was a failure in initiating tf2 event hooks.");
    }
    else if(GameType == cstrike)
    {
        if(!HookCStrikeEvents())
            SetFailState("[SourceCraft] There was a failure in initiating cstrike event hooks.");
    }

    if(!InitCVars())
        SetFailState("[SourceCraft] There was a failure in initiating console variables.");
    if(!InitMenus())
        SetFailState("[SourceCraft] There was a failure in initiating menus.");
    if(!InitHooks())
        SetFailState("[SourceCraft] There was a failure in initiating the hooks.");
    if(!InitOffset())
        SetFailState("[SourceCraft] There was a failure in finding the offsets required.");
    if(!ParseSettings())
        SetFailState("[SourceCraft] There was a failure in parsing the configuration file.");

    // MaxSpeed/MinGravity/OverrideSpeed/OverrideGravity
    CreateTimer(2.0,PlayerProperties,INVALID_HANDLE,TIMER_REPEAT);
    PrintToServer("[SourceCraft] Plugin finished loading.\n-------------------------------------------------------------------------");
}

public OnAllPluginsLoaded()
{
    if(SAVE_ENABLED)
        SQLTable();

    if(!m_CalledReady)
    {
        Call_StartForward(g_OnPluginReadyHandle);
        new res;
        Call_Finish(res);
        m_CalledReady=true;
    }

    InitHelpCommands();
}

public OnPluginEnd()
{
    PrintToServer("-------------------------------------------------------------------------\n[SourceCraft] Plugin shutting down...");
    for(new x=0;x<GetArraySize(arrayPlayers);x++)
    {
        new Handle:vec=GetArrayCell(arrayPlayers,x);
        ClearArray(vec);
    }
    ClearArray(arrayPlayers);
    for(new x=0;x<GetArraySize(arrayRaces);x++)
    {
        new Handle:vec=GetArrayCell(arrayRaces,x);
        ClearArray(vec);
    }
    ClearArray(arrayRaces);
    PrintToServer("[SourceCraft] Plugin shutdown finished.\n-------------------------------------------------------------------------");
}

public OnMapStart()
{
    for(new x=0;x<GetArraySize(arrayPlayers);x++)
    {
        new Handle:vec=GetArrayCell(arrayPlayers,x);
        ClearArray(vec);
    }
    ClearArray(arrayPlayers); // Clear our temporary players vector.
}

public OnClientPutInServer(client)
{
    if (client>0 && !IsFakeClient(client))
    {
        new Handle:newPlayer=CreateArray();
        PushArrayCell(newPlayer,client); // The first thing is client index
        PushArrayCell(newPlayer,0); // Player race
        PushArrayCell(newPlayer,-1); // Pending race
        PushArrayCell(newPlayer,0); // Pending skill reset
        PushArrayCell(newPlayer,0); // Credits
        PushArrayCell(newPlayer,0); // Overall Level
        new Handle:temp=CreateArray();
        PushArrayCell(newPlayer,temp); // Information about speed and gravity
        for(new x=0;x<IMMUNITY_COUNT;x++)
            PushArrayCell(newPlayer,0);
        for(new x=0;x<SHOPITEM_COUNT;x++)
            PushArrayCell(newPlayer,0); // Owns item x
        for(new x=0;x<RACE_COUNT;x++)
            PushArrayCell(newPlayer,0); // Race x XP
        for(new x=0;x<RACE_COUNT;x++)
            PushArrayCell(newPlayer,0); // Race x Level
        for(new x=0;x<RACE_COUNT;x++)
        {
            for(new y=0;y<SKILL_COUNT;y++)
                PushArrayCell(newPlayer,0); // Skill level for race x skill y
        }
        if (GetArraySize(newPlayer)==(INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+RACE_COUNT+RACE_COUNT+(RACE_COUNT*SKILL_COUNT)))
        {
            PushArrayCell(arrayPlayers,newPlayer); // Put our new player at the end of the arrayPlayers vector
            Call_StartForward(g_OnPlayerAuthedHandle);
            Call_PushCell(client);
            Call_PushCell(GetClientVectorPosition(client));
            new res;
            Call_Finish(res);

            m_OffsetGravity[client]=FindDataMapOffs(client,"m_flGravity");

            if (GameType == tf2)
            {
                m_OffsetMaxSpeed[client]=FindDataMapOffs(client,"m_flMaxspeed");
                m_BaseSpeed[client]= GetEntDataFloat(client,m_OffsetMaxSpeed[client]);
            }

            new vecpos=GetClientVectorPosition(client);
            if(SAVE_ENABLED)
                m_FirstSpawn[client]=LoadPlayerData(client,vecpos);
            else
                m_FirstSpawn[client]=2;

            if (m_FirstSpawn[client] == 2)
                SetRace(vecpos, FindRace("human")); // Default race to human.
        }
        else
            SetFailState("[SourceCraft] There was a failure processing client.");
    }
}

public OnClientDisconnect(client)
{
    if (client>0 && !IsFakeClient(client))
    {
        new clientVecPos=GetClientVectorPosition(client);
        if (clientVecPos>-1)
        {
            if (SAVE_ENABLED)
                SavePlayerData(client,clientVecPos);

            RemoveFromArray(arrayPlayers,clientVecPos);
            m_FirstSpawn[client]=2;
        }
    }
}

public OnGameFrame()
{
    SaveAllHealth();
}

public bool:ParseSettings()
{
    new Handle:keyValue=CreateKeyValues("War3SourceSettings");
    decl String:path[1024];
    BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
    FileToKeyValues(keyValue,path);
    decl String:error[256];
    DBIDB=SQL_DefConnect(error,255);
    if(!DBIDB)
    {
        LogError("Unable to get a Database Connection.");
    }
    // Load level configuration
    KvRewind(keyValue);
    vecLevelConfiguration=CreateArray();
    if(!KvJumpToKey(keyValue,"levels"))
    {
        LogError("KvJumpToKey failed in ParseSettings");
        return false;
    }
    new Handle:longterm_required=CreateArray();
    new Handle:longterm_killxp=CreateArray();
    new Handle:shortterm_required=CreateArray();
    new Handle:shortterm_killxp=CreateArray();
    decl String:temp[2048];
    if(!KvGotoFirstSubKey(keyValue))
    {
        LogError("KvJumpToKey failed in ParseSettings");
        return false;
    }
    // required xp, long term
    KvGetString(keyValue,"required_xp",temp,2047);
    new tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for required xp, long term in ParseSettings");
        return false;
    }
    decl String:temp_iter[16];
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(longterm_required,StringToInt(temp_iter));
    }
    // kill xp, long term
    KvGetString(keyValue,"kill_xp",temp,2047);
    tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for kill xp, long term in ParseSettings");
        return false;
    }
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(longterm_killxp,StringToInt(temp_iter));
    }
    if(!KvGotoNextKey(keyValue))
    {
        LogError("KvGotoNextKey failed in ParseSettings");
        return false;
    }
    // required xp, short term
    KvGetString(keyValue,"required_xp",temp,2047);
    tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for required xp, short term in ParseSettings");
        return false;
    }
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(shortterm_required,StringToInt(temp_iter));
    }
    // kill xp, short term
    KvGetString(keyValue,"kill_xp",temp,2047);
    tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for kill xp, short term in ParseSettings");
        return false;
    }
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(shortterm_killxp,StringToInt(temp_iter));
    }
    PushArrayCell(vecLevelConfiguration,longterm_required);
    PushArrayCell(vecLevelConfiguration,longterm_killxp);
    PushArrayCell(vecLevelConfiguration,shortterm_required);
    PushArrayCell(vecLevelConfiguration,shortterm_killxp);
    return true;
}

