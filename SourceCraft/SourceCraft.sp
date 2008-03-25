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
#include <sdktools>
#include <tf2>

new m_FirstSpawn[MAXPLAYERS + 1] = {1, ...}; // Cheap trick
#define VERSION     "2.0.3 $Revision$ beta"

// ConVar definitions
new Handle:m_SaveXPConVar         = INVALID_HANDLE;
new Handle:m_MinimumUltimateLevel = INVALID_HANDLE;
new Handle:m_MaxCredits           = INVALID_HANDLE;

new String:notEnoughWav[] = "sourcecraft/taderr00.wav";

#define SAVE_ENABLED       (GetConVarInt(m_SaveXPConVar)==1 && GetRaceCount() > 0)
#define MIN_ULTIMATE_LEVEL GetConVarInt(m_MinimumUltimateLevel)
#define MAX_LEVELS         16

// SourceCraft Includes
#include "sc/util"
#include "sc/weapons"
#include "sc/immunity"
#include "sc/visibility"
#include "sc/maxhealth"
#include "sc/log"

#include "sc/engine/help"
#include "sc/engine/offsets"
#include "sc/engine/damage"
#include "sc/engine/races"
#include "sc/engine/shopmenu"
#include "sc/engine/playertracking"
#include "sc/engine/db"
#include "sc/engine/natives"
#include "sc/engine/credits"
#include "sc/engine/xp"
#include "sc/engine/hooks"
#include "sc/engine/console"
#include "sc/engine/tf2classes"
#include "sc/engine/menus"
#include "sc/engine/events"
#include "sc/engine/events_tf2"
#include "sc/engine/events_cstrike"
#include "sc/engine/strtoken"

new bool:m_CalledReady=false;

public Plugin:myinfo= 
{
    name="SourceCraft",
    author="Naris",
    description="StarCraft/WarCraft for the Source engine.",
    version=VERSION,
    url="http://www.jigglysfunhouse.net/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    if(!InitNatives())
    {
        LogError("There was a failure in creating the native based functions.");
        return false;
    }
    else if(!InitForwards())
    {
        LogError("There was a failure in creating the forward based functions.");
        return false;
    }
    else if(!InitRaceArray())
    {
        LogError("There was a failure in creating the race vector.");
        return false;
    }
    else
        return true;
}

public OnPluginStart()
{
    LogMessage("-------------------------------------------------------------------------\n[SourceCraft] Plugin loading...");
    PrintToServer("-------------------------------------------------------------------------\n[SourceCraft] Plugin loading...");

    GetGameType();

    if(!InitRaceArray())
        SetFailState("There was a failure in creating the race vector.");

    if(!ConnectToDatabase())
        LogMessage("Saving DISABLED!");
    
    if(!InitiateShopVector())
        SetFailState("There was a failure in creating the shop vector.");
    if(!InitiateHelpVector())
        SetFailState("There was a failure in creating the help vector.");

    if(!InitOffset())
        SetFailState("There was a failure in finding the offsets required.");
    if(!HookEvents())
        SetFailState("There was a failure in initiating event hooks.");

    if (GameType == tf2)
    {
        if(!InitTFOffset())
            SetFailState("There was a failure in finding the tf2 offsets required.");
        if(!HookTFEvents())
            SetFailState("There was a failure in initiating tf2 event hooks.");
    }
    else if(GameType == cstrike)
    {
        if(!HookCStrikeEvents())
            SetFailState("There was a failure in initiating cstrike event hooks.");
    }

    if(!InitCVars())
        SetFailState("There was a failure in initiating console variables.");
    if(!InitMenus())
        SetFailState("There was a failure in initiating menus.");
    if(!InitHooks())
        SetFailState("There was a failure in initiating the hooks.");
    if(!ParseSettings())
        SetFailState("There was a failure in parsing the configuration file.");

    // MaxSpeed/MinGravity/OverrideSpeed/OverrideGravity
    CreateTimer(2.0,PlayerProperties,INVALID_HANDLE,TIMER_REPEAT);

    PrintToServer("[SourceCraft] Plugin finished loading.\n-------------------------------------------------------------------------");
    LogMessage("[SourceCraft] Plugin finished loading.\n-------------------------------------------------------------------------");
}

public OnAllPluginsLoaded()
{
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
    ClearPlayerArray();
    ClearRaceArray();
    LogMessage("[SourceCraft] Plugin shutdown.\n-------------------------------------------------------------------------");
    PrintToServer("[SourceCraft] Plugin shutdown.\n-------------------------------------------------------------------------");
}

public OnMapStart()
{
    LogMessage("OnMapStart()");
    g_MapChanging = false;
    g_AllPlayersSaved = false;
    SetupSound(notEnoughWav,true,true);
    ClearPlayerArray();
}

public OnMapEnd()
{
    LogMessage("OnMapEnd(), g_AllPlayersSaved=%d, g_MapChanging=%d", g_AllPlayersSaved, g_MapChanging);

    if (SAVE_ENABLED)
    {
        // Wait for all threaded DB transactions to complete!
        SQL_LockDatabase(DBIDB);
        SQL_UnlockDatabase(DBIDB);
    }

    g_MapChanging = false;
}

public OnClientPutInServer(client)
{
    if (client>0 && !IsFakeClient(client))
    {
        //LogMessage("OnClientPutInServer(%N)", client);
        m_OffsetGravity[client]=FindDataMapOffs(client,"m_flGravity");

        new Handle:playerHandle=CreatePlayer(client);
        if (playerHandle != INVALID_HANDLE)
        {
            Call_StartForward(g_OnPlayerAuthedHandle);
            Call_PushCell(client);
            Call_PushCell(playerHandle);
            new res;
            Call_Finish(res);

            if(SAVE_ENABLED)
                m_FirstSpawn[client]=LoadPlayerData(client,playerHandle,false);
            else
                m_FirstSpawn[client]=2;

            // Default race to human for new players.
            if (m_FirstSpawn[client] == 2)
                SetRace(playerHandle, FindRace("human"));
        }
        else
            SetFailState("There was a failure processing client %d-%N.", client, client);
    }
}

public OnClientDisconnect(client)
{
    if (client>0 && !IsFakeClient(client))
    {
        LogMessage("OnClientDisconnect(%N), g_MapChanging=%d", client, g_MapChanging);
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            if (SAVE_ENABLED && !GetDatabaseSaved(playerHandle))
            {
                // Don't use threaded saves when the map is changing!
                new bool:threaded;
                if (g_MapChanging)
                    threaded = false;
                else
                {
                    new timeleft = 0;
                    if (GetMapTimeLeft(timeleft))
                        threaded = (timeleft > 30);
                    else
                        threaded = true;
                }
                SavePlayerData(client,playerHandle,threaded,false);
                if (!threaded)
                    ClearPlayer(client,playerHandle);
            }
            else
                ClearPlayer(client,playerHandle);

            arrayPlayers[client] = INVALID_HANDLE;
            m_FirstSpawn[client] = 2;
        }
    }
}

public OnGameFrame()
{
    SaveAllHealth();
}

public bool:ParseSettings()
{
    new Handle:keyValue=CreateKeyValues("SourceCraftSettings");
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM,path,sizeof(path),"configs/sourcecraft.ini");
    FileToKeyValues(keyValue,path);

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

