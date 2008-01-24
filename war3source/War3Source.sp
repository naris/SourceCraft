/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source.sp
 * Description: The main file for SourceCraft.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 *
 * $Id$
 */
 
#pragma semicolon 1

#include <sourcemod>

new m_FirstSpawn[MAXPLAYERS + 1] = {1, ...}; // Cheap trick
#define VERSION_NUM "1.0 $Revision$"
#define VERSION     "$Revision$"

// War3Source Includes
#include "War3Source/War3Source"
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

