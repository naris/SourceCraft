/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source.sp
 * Description: The main file for War3Source.
 * Author(s): Anthony Iacono 
 * Modifications by: Naris (Murray Wilson)
 *
 * $Id$
 */
 
#pragma semicolon 1

#include <sourcemod>

new bool:m_FirstSpawn[65]={true}; // Cheap trick
#define VERSION_NUM "0.9 $Revision$" // "0.8.6.1"
#define VERSION     "$Revision$" // "0.8.6.1 by Anthony \"PimpinJuice\" Iacono"

// War3Source Includes
#include "War3Source/War3Source"
new bool:m_CalledReady=false;

public Plugin:myinfo= 
{
    name="War3Source",
    author="PimpinJuice",
    description="Brings a Warcraft like gamemode to the Source engine.",
    version=VERSION_NUM,
    url="http://pimpinjuice.net/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    if(!War3Source_InitNatives())
    {
        PrintToServer("[War3Source] There was a failure in creating the native based functions, definately halting.");
        return false;
    }
    if(!War3Source_InitForwards())
    {
        PrintToServer("[War3Source] There was a failure in creating the forward based functions, definately halting.");
        return false;
    }
    return true;
}

public OnPluginStart()
{
    PrintToServer("-------------------------------------------------------------------------\n[War3Source] Plugin loading...");

    GetGameType();
    
    arrayPlayers=CreateArray();
    if(!War3Source_InitiatearrayRaces())
        SetFailState("[War3Source] There was a failure in creating the race vector, definately halting.");
    if(!War3Source_InitiateShopVector())
        SetFailState("[War3Source] There was a failure in creating the shop vector, definately halting.");
    if(!War3Source_InitiateHelpVector())
        SetFailState("[War3Source] There was a failure in creating the help vector, definitely halting.");

    if(!War3Source_HookEvents())
        SetFailState("[War3Source] There was a failure in initiating event hooks.");

    if (GameType == tf2)
    {
        if(!War3Source_HookTFEvents())
            SetFailState("[War3Source] There was a failure in initiating tf2 event hooks.");
    }
    else if(GameType == cstrike)
    {
        if(!War3Source_HookCStrikeEvents())
            SetFailState("[War3Source] There was a failure in initiating cstrike event hooks.");
    }

    if(!War3Source_InitCVars())
        SetFailState("[War3Source] There was a failure in initiating console variables.");
    if(!War3Source_InitMenus())
        SetFailState("[War3Source] There was a failure in initiating menus.");
    if(!War3Source_InitHooks())
        SetFailState("[War3Source] There was a failure in initiating the hooks.");
    if(!War3Source_InitOffset())
        SetFailState("[War3Source] There was a failure in finding the offsets required.");
    if(!War3Source_ParseSettings())
        SetFailState("[War3Source] There was a failure in parsing the configuration file.");

    // MaxSpeed/MinGravity/OverrideSpeed/OverrideGravity
    CreateTimer(2.0,PlayerProperties,INVALID_HANDLE,TIMER_REPEAT);
    PrintToServer("[War3Source] Plugin finished loading.\n-------------------------------------------------------------------------");
}

public OnAllPluginsLoaded()
{
    if(!m_CalledReady)
    {
        Call_StartForward(g_OnWar3PluginReadyHandle);
        new res;
        Call_Finish(res);
        m_CalledReady=true;
    }
    if(SAVE_ENABLED)
        War3Source_SQLTable();
    War3Source_InitHelpCommands();
}

public OnPluginEnd()
{
    PrintToServer("-------------------------------------------------------------------------\n[War3Source] Plugin shutting down...");
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
    PrintToServer("[War3Source] Plugin shutdown finished.\n-------------------------------------------------------------------------");
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
            for(new y=0;y<SKILL_COUNT;y++)
                PushArrayCell(newPlayer,0); // Skill level for race x skill y
        if (GetArraySize(newPlayer)==(INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+RACE_COUNT+RACE_COUNT+(RACE_COUNT*SKILL_COUNT)))
        {
            PushArrayCell(arrayPlayers,newPlayer); // Put our new player at the end of the arrayPlayers vector
            Call_StartForward(g_OnWar3PlayerAuthedHandle);
            Call_PushCell(client);
            Call_PushCell(GetClientVectorPosition(client));
            new res;
            Call_Finish(res);

            m_OffsetGravity[client]=FindDataMapOffs(client,"m_flGravity");

            if (GameType == tf2)
            {
                m_OffsetMaxSpeed[client]=FindDataMapOffs(client,"m_flMaxspeed");
                m_BaseSpeed[client]= GetEntDataFloat(client,m_OffsetMaxSpeed[client]);

                /*
                LogMessage("[War3Source] Set Base Speed=%f\n", m_BaseSpeed[client]);

                War3Source_ChatMessage(client,COLOR_DEFAULT,
                                       "%c[War3Source] %cSet Base Speed=%f.",
                                       COLOR_GREEN,COLOR_DEFAULT,m_BaseSpeed[client]);
                */
            }

            if(SAVE_ENABLED)
                War3Source_LoadPlayerData(client,GetClientVectorPosition(client));

            m_FirstSpawn[client]=true;
        }
        else
            SetFailState("[War3Source] There was a failure on processing client, halting.");
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
                War3Source_SavePlayerData(client,clientVecPos);

            RemoveFromArray(arrayPlayers,clientVecPos);
            m_FirstSpawn[client]=true;
        }
    }
}
