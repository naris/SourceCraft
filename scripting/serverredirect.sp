/* vim: set ai et ts=4 sw=4 syntax=sourcepawn :
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/*

Versions:
    3.0
        ! Merged Azelphur's changes
        + Switched to using RegConsoleCmd instead of hooking say.
        + New CVAR: sm_redirect_disablecurrent Disable (Grey out) the current server in the menu.
        + new CVAR: sm_redirect_disableoffline Disable (Grey out) offline servers in the menu.

    2.1
        ! Fixed handle leaks

    2.0
        ! Merged Wazz's Server Redirector plugin to allow automatically redirecting players when the server is full.

    1.2
        ! Changed UpdateStatus() to use threaded queries to prevent lag.
        ! Fixed serverredirect to properly register itself with SourceMod in AskPluginLoad2().

    1.1
        ! Fixed settings not being applied properly
        ! Fixed package (proper lay-out and correct files)
        ! Fixed mysql script, commented the create database statement and fixed syntax.
        ? Now uses sv_maxvisibleplayers by default to determine max amount of players. Provides compatibility
            with reserved slot plugins. If sv_visiblemaxplayers is not set (less than 0), it'll
            use the maximum amount of player slots on the server.
        + Added sm_redirect_menusort to be able to choose how items get sorted.
        + Added sm_redirect_enableheartbeat tobe able to enable/disable the heartbeat. Can be used to (temporarily) disable
            the plugin and avoid advertising the server.
 
    1.0 - initial release
    
*/


#include <sourcemod>
#include <serverredirect>
#pragma semicolon 1

#define PLUGIN_VERSION "2.0"
// amount of seconds after which a server is considered to be offline. Offline servers will not show up in the redirect window.
#define SERVER_TIMEOUT_SECONDS 120
// interval at which the database is updated
#define SERVER_UPDATE_INTERVAL 30.0

#define ADDRESS_OFFLINE "#OFFLINE#"
#define TRANSLATION_FILE "serverredirect.phrases.txt"
#define DATABASE_KEY "serverredirect"
#define CHAT_COLOR 0x04

new Handle:g_varServerId;                       // ID of the server
new Handle:g_varShowCurrent;                    // Whether to show the current server in the redirect menu
new Handle:g_varShowOffline;                    // Whether to show offline servers in the redirect menu
new Handle:g_varMenuSortMode;                   // Sort mode in the menu (1 = by name, 2 = by ID)
new Handle:g_varHeartbeatEnabled;               // Whether the heartbeat function is enabled
new Handle:g_varDisableCurrent;                 // Set the current server to ITEMDRAW_DISABLED in the menu
new Handle:g_varDisableOffline;                 // Set offline servers to ITEMDRAW_DISABLED in the menu
new Handle:g_varSvMaxVisiblePlayers;            // sv_visiblemaxplayers var

new Handle:g_varFullRedirectAnnounce;           // Announces when the server automatically redirects a player
new Handle:g_varFullRedirectServer;             // IP of the server to automatically redirect to when the server is full.
new Handle:g_varFullRedirectSlots;              // Number of slots to reserve for automatically redirecting players (if any).
new Handle:g_varFullRedirectTime;               // Time until a player in a redirect slot is kicked.

new Handle:g_updateTimer = INVALID_HANDLE;      // update timer handler
new Handle:g_hDatabase = INVALID_HANDLE;        // database handle

new g_fakeClientCount;                          // amount of fake clients
new bool:g_playerCountChanged;                  // whether the amount of players has changed

new const String:g_FullRedirectMessage[] = "\x04This server is full. Please press F3 to be redirected to our second server or you will be kicked.\x01";

public Plugin:myinfo = 
{
    name = "Server Redirect",
    author = "Brainstorm",
    description = "Allows players to switch to a different server.",
    version = PLUGIN_VERSION,
    url = "http://www.teamfortress.be"
}

public OnPluginStart()
{
    g_fakeClientCount = 0;
    
    CreateConVar("sm_redirect_version", PLUGIN_VERSION, "Version number of server redirect plugin.", FCVAR_NONE | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    g_varServerId = CreateConVar("sm_redirect_serverid", "0", "ID of the server in the database.", 0, true, 0.0, false);
    g_varShowCurrent = CreateConVar("sm_redirect_showcurrent", "1", "Whether to show the current server in the redirect menu", 0, true, 0.0, true, 1.0);
    g_varShowOffline = CreateConVar("sm_redirect_showoffline", "1", "Whether to show offline servers in the redirect menu", 0, true, 0.0, true, 1.0);
    g_varMenuSortMode = CreateConVar("sm_redirect_menusort", "1", "Indicates how menu items get sorted. 1 = by display name (default), 2 = by server ID", 0, true, 1.0, false);
    g_varDisableCurrent = CreateConVar("sm_redirect_disablecurrent", "1", "sm_redirect_disablecurrent - Disable (Grey out) the current server in the menu.", 0, true, 1.0, false);
    g_varDisableOffline = CreateConVar("sm_redirect_disableoffline", "1", "sm_redirect_disableoffline - Disable (Grey out) offline servers in the menu.", 0, true, 1.0, false);
    g_varHeartbeatEnabled = CreateConVar("sm_redirect_enableheartbeat", "1", "Whether to enable heartbeat signal for this server. If stopped, the server will be marked as offline.", 0, true, 0.0, true, 1.0);

    g_varFullRedirectAnnounce = CreateConVar("sm_redirect_announce", "1", "Announces when the server redirects a player", 0, true, 0.0);
    g_varFullRedirectServer = CreateConVar("sm_redirect_server", "127.0.0.1", "IP of the server to redirect to.", 0, true, 0.0);
    g_varFullRedirectSlots = CreateConVar("sm_redirect_slots", "0", "Number of slots to use for redirecting players.", 0, true, 0.0);
    g_varFullRedirectTime = CreateConVar("sm_redirect_time", "35", "Time until a player in a redirect slot is kicked.", 0, true, 0.0);

    g_varSvMaxVisiblePlayers = FindConVar("sv_visiblemaxplayers");
    if (g_varSvMaxVisiblePlayers == INVALID_HANDLE)
    {
        SetFailState("Unable to find sv_visiblemaxplayers, I need this var please.");
    }
    
    LoadTranslations(TRANSLATION_FILE);
    
    // register events
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);

    RegConsoleCmd("sm_server", Command_ShowMenu);
    RegConsoleCmd("sm_servers", Command_ShowMenu);

    AutoExecConfig(true, "plugin.serverredirect");
    
}

public OnPluginEnd()
{
    DisconnectFromDatabase();
}

public OnMapStart()
{
    g_playerCountChanged = true;
    new bool:isEnabled = GetConVarBool(g_varHeartbeatEnabled);
    if (isEnabled)
    {
        StartStatusUpdateTimer();
    }
    HookConVarChange(g_varHeartbeatEnabled, OnHeartBeatEnableChange);
}

public OnMapEnd()
{
    EndStatusUpdateTimer();
    UnhookConVarChange(g_varHeartbeatEnabled, OnHeartBeatEnableChange);
}

public OnHeartBeatEnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    new bool:newVal = GetConVarBool(g_varHeartbeatEnabled);
    if (newVal)
    {
        // create timer if needed
        if (g_updateTimer == INVALID_HANDLE)
        {
            StartStatusUpdateTimer();
            UpdateStatus();
        }
    }
    else
    {
        EndStatusUpdateTimer();
    }
}

CountFakePlayers()
{
    new fakeClientCount = 0;
    new maxClients = GetMaxClients();
    
    for (new i=1; i <= maxClients; i++)
    {
        if (IsClientConnected(i) && IsFakeClient(i))
        {
            fakeClientCount++;
        }
    }
    
    g_fakeClientCount = fakeClientCount;
}

public void OnClientConnected(client)
{
    g_playerCountChanged = true;
    
    UpdateStatus();
}

public OnClientDisconnect_Post(client)
{
    g_playerCountChanged = true;
    UpdateStatus();
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    new limit = getLimit();

    if (limit > 0 && client > limit)
    {
        ChangeClientTeam(client, 1);
    }
}

public OnClientPostAdminCheck(client)
{
    new String:serverIP[128];
    GetConVarString(g_varFullRedirectServer, serverIP, sizeof(serverIP));

    new limit = getLimit();
    if (limit > 0 && client > limit && StrContains(serverIP, "127.0.0.1") == -1)
    {
        CreateTimer(2.0, VGUITimer, client, TIMER_REPEAT);

        PrintToChat(client, g_FullRedirectMessage);
        PrintCenterText(client, g_FullRedirectMessage);
        ChangeClientTeam(client, 1);

        new String:time[64];
        GetConVarString(g_varFullRedirectTime, time, 64);

        new Handle:kv = CreateKeyValues("msg");
        KvSetString(kv, "time", time); 
        KvSetString(kv, "title", serverIP); 
        CreateDialog(client, kv, DialogType_AskConnect);
        CloseHandle(kv);

        CreateTimer(5.0, MessageTimer, client, TIMER_REPEAT);
        CreateTimer(GetConVarFloat(g_varFullRedirectTime), KickTimer, client);
    }
}

public Action:VGUITimer(Handle:timer, any:client)
{
    static c = 0;
    
    if (!client || !IsClientInGame(client))
    {
        c = 0;
        return Plugin_Stop;
    }

    ShowVGUIPanel(client, "info", _, false);
    ShowVGUIPanel(client, "team", _, false);
    ShowVGUIPanel(client, "active", _, false);
    c++;
    
    if (c == (GetConVarInt(g_varFullRedirectTime) / 2))
    {
        c = 0;
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public Action:MessageTimer(Handle:timer, any:client)
{
    static i = 0;
    
    if (!client || !IsClientInGame(client))
    {
        i = 0;
        return Plugin_Stop;
    }
    
    PrintToChat(client, g_FullRedirectMessage);
    PrintCenterText(client, g_FullRedirectMessage);
    i++;
    
    if (i == 6)
    {
        i = 0;
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public Action:KickTimer(Handle:timer, any:client)
{   
    decl String:serverIP[128];
    GetConVarString(g_varSvMaxVisiblePlayers, serverIP, sizeof(serverIP));
    
    if (!client || !IsClientInGame(client))
    {
        LogMessage( "Client was redirected to %s.", serverIP );
        if (GetConVarBool(g_varFullRedirectAnnounce))
        {
            PrintToChatAll("\x01Player was redirected to \x04%s\x01.", client, serverIP);    
        }
        return Plugin_Handled;
    }
            
    new limit = getLimit();
    if (limit > 0 && client > limit)
    {   
        KickClient(client, "Server is full and you did not redirect");  
        LogMessage( "\"%L\" was kicked (did not redirect).", client, serverIP );                
        if (GetConVarBool(g_varFullRedirectAnnounce))
        {
            PrintToChatAll("\x04%N \x01was kicked (did not redirect).", client);    
        }
    }   
    
    return Plugin_Handled;
}

getLimit()
{
    new visibleSlots;
    if (g_varSvMaxVisiblePlayers==INVALID_HANDLE)
    {
        visibleSlots = GetMaxClients();
    }
    else
    {
        visibleSlots = GetConVarInt(g_varSvMaxVisiblePlayers);
        if (visibleSlots < 0)
            visibleSlots = GetMaxClients();
    }
    
    return visibleSlots - GetConVarInt(g_varFullRedirectSlots);
}

StartStatusUpdateTimer()
{
    EndStatusUpdateTimer();
    g_updateTimer = CreateTimer(SERVER_UPDATE_INTERVAL, Timer_StatusUpdate, INVALID_HANDLE, TIMER_REPEAT);
}

EndStatusUpdateTimer()
{
    if (g_updateTimer != INVALID_HANDLE)
    {
        KillTimer(g_updateTimer);
        g_updateTimer = INVALID_HANDLE;
    }
}

public Action:Timer_StatusUpdate(Handle:timer)
{
    UpdateStatus();
}

public Action:Command_ShowMenu(client, args)
{
	ShowServerMenu(client);		
	return Plugin_Handled;
}

ShowServerMenu(client)
{
    if (!IsClientConnected(client) || IsFakeClient(client))
    {
        return;
    }
    
    new serverId = GetConVarInt(g_varServerId);
    new bool:showOffline = GetConVarBool(g_varShowOffline);
    new bool:showCurrent = GetConVarBool(g_varShowCurrent);
    
    // start a query for the active servers in the group
    new bool:isReady = CheckSQLConnection();
    if (isReady)
    {
        decl String:query[512];
        CreateServerListQuery(query, sizeof(query), serverId, showOffline, showCurrent);
        SQL_TQuery(g_hDatabase, Query_ActiveServers, query, client);
    }
    else
    {
        PrintToChat(client, "%T", "redir failed no database", client, CHAT_COLOR);
    }
}

CreateServerListQuery(String:query[], maxlength, serverId, bool:showOffline, bool:showCurrent)
{
    Format(query, maxlength, "SELECT id, address, display_name, offline_name, maxplayers, currplayers, map, (NOW() - last_update) AS timediff FROM `server` WHERE groupnumber IN (SELECT groupnumber FROM `server` WHERE `id` = %d)", serverId);
    
    if (!showOffline)
    {
        Format(query, maxlength, "%s AND last_update >= DATE_SUB(NOW(), INTERVAL %d SECOND)", query, SERVER_TIMEOUT_SECONDS);
    }
    if (!showCurrent)
    {
        Format(query, maxlength, "%s AND `id` != %d", query, serverId);
    }
    
    new sortMode = GetConVarInt(g_varMenuSortMode);
    
    if (sortMode == 2)
    {
        Format(query, maxlength, "%s ORDER BY `id`", query);
    }
    else
    {
        Format(query, maxlength, "%s ORDER BY display_name", query);
    }
}

public Query_ActiveServers(Handle:db, Handle:query, const String:error[], any:client)
{
    /* Make sure the client didn't disconnect while the thread was running */
    if (!IsClientConnected(client))
    {
        return;
    }
 
    if (query == INVALID_HANDLE)
    {
        LogError("Active server query failed, error: %s", error);
        PrintToChat(client, "%T", "redir failed query error", client, CHAT_COLOR);
        DisconnectFromDatabase();
    }
    else
    {
        // get convars
        new thisServer = GetConVarInt(g_varServerId);
        new bool:showOffline = GetConVarBool(g_varShowOffline);

        // construct voting menu
        new itemCount = 0;
        new Handle:hRedirMenu = CreateMenu(RedirMenuHandler);
        SetMenuTitle(hRedirMenu, "%T", "redir menu title", client);
        SetMenuExitButton(hRedirMenu, true);
        
        decl String:address[50];
        decl String:display_name[255];
        decl String:offline_name[100];
        decl String:map[64];
        new maxPlayers;
        new currPlayers;
        new timeDiff;
        new draw;
        new id;
        
        while (SQL_FetchRow(query))
        {
            draw = ITEMDRAW_DEFAULT;
            id = SQL_FetchInt(query, 0);
            SQL_FetchString(query, 1, address, sizeof(address));
            SQL_FetchString(query, 2, display_name, sizeof(display_name));
            SQL_FetchString(query, 3, offline_name, sizeof(offline_name));
            maxPlayers = SQL_FetchInt(query, 4);
            currPlayers = SQL_FetchInt(query, 5);
            SQL_FetchString(query, 6, map, sizeof(map));
            timeDiff = SQL_FetchInt(query, 7);
            
            if (showOffline && timeDiff > SERVER_TIMEOUT_SECONDS)
            {
                strcopy(display_name, sizeof(display_name), offline_name);
                strcopy(address, sizeof(address), ADDRESS_OFFLINE);
                if (GetConVarInt(g_varDisableOffline))
                    draw = ITEMDRAW_DISABLED;
            }
            
            if (id == thisServer && GetConVarInt(g_varDisableCurrent))
                draw = ITEMDRAW_DISABLED;

            // format nicely
            FormatServerName(display_name, sizeof(display_name), map, currPlayers, maxPlayers);
            
            AddMenuItem(hRedirMenu, address, display_name, draw);
            itemCount++;
        }
        
        if (itemCount > 0)
        {
            DisplayMenu(hRedirMenu, client, 30);
        }
        else
        {
            CloseHandle(hRedirMenu);
            PrintToChat(client, "%T", "redir no servers", client, CHAT_COLOR);
        }
    }
}

FormatServerName(String:buffer[], bufferSize, const String:map[], currPlayers, maxPlayers)
{
    decl String:tmpVal[10];

    if (StrContains(buffer, "{MAP}") != -1)
    {
        ReplaceString(buffer, bufferSize, "{MAP}", map);
    }
    if (StrContains(buffer, "{CURR}") != -1)
    {
        IntToString(currPlayers, tmpVal, sizeof(tmpVal));
        ReplaceString(buffer, bufferSize, "{CURR}", tmpVal);
    }
    if (StrContains(buffer, "{MAX}") != -1)
    {
        IntToString(maxPlayers, tmpVal, sizeof(tmpVal));
        ReplaceString(buffer, bufferSize, "{MAX}", tmpVal);
    }
}

public RedirMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select) 
    {
        // obtain selected address
        new String:selectedItem[64];
        GetMenuItem(menu, param2, selectedItem, sizeof(selectedItem));
        
        if (strcmp(selectedItem, ADDRESS_OFFLINE, false) == 0)
        {
            PrintToChat(param1, "%T", "server offline", param1, CHAT_COLOR);
            return;
        }
        
        // message in the top of the screen
        new Handle:msgValues = CreateKeyValues("msg");
        KvSetString(msgValues, "title", "Join another server");
        KvSetNum(msgValues, "level", 1); 
        KvSetString(msgValues, "time", "20"); 
        CreateDialog(param1, msgValues, DialogType_Msg);
        CloseHandle(msgValues);
        
        // redirect box
        new Handle:dialogValues = CreateKeyValues("msg");
        KvSetString(dialogValues, "title", selectedItem); 
        KvSetString(dialogValues, "time", "20"); 
        CreateDialog(param1, dialogValues, DialogType_AskConnect);
        CloseHandle(dialogValues);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

// used to update the status of the server to the database
UpdateStatus()
{
    new bool:isEnabled = GetConVarBool(g_varHeartbeatEnabled);
    if (!isEnabled)
    {
        return 0;
    }
    
    if (g_playerCountChanged)
    {
        g_playerCountChanged = false;
        CountFakePlayers();
    }
    
    // obtain vars
    new maxVisiblePlayers = GetConVarInt(g_varSvMaxVisiblePlayers);
    if (maxVisiblePlayers < 0)
    {
        maxVisiblePlayers = GetMaxClients();
    }
    new maxPlayers = maxVisiblePlayers - g_fakeClientCount;
    new currPlayers = GetClientCount(false) - g_fakeClientCount;
    //PrintToServer("maxvis:%d   fake:%d   maxpl:%d   currpl:%d   igcount:%d", maxVisiblePlayers, g_fakeClientCount, maxPlayers, currPlayers, currPlayers + g_fakeClientCount);
    decl String:map[64];
    GetCurrentMap(map, sizeof(map));
    new serverId = GetConVarInt(g_varServerId);
    
    new bool:isReady = CheckSQLConnection();
    if (isReady)
    {
        decl String:query[255];
        Format(query, sizeof(query),
               "UPDATE server SET maxplayers = %d, currplayers = %d, map = '%s', last_update = now() WHERE id = %d",
               maxPlayers, currPlayers, map, serverId);

        SQL_TQuery(g_hDatabase, Query_UpdateServers, query, serverId);
    }
    return 0;
}

public Query_UpdateServers(Handle:db, Handle:query, const String:error[], any:serverId)
{
    if (query == INVALID_HANDLE || error[0] != '\0')
    {
        LogError("Server update failed, error: %s", error);
        DisconnectFromDatabase();
    }
}

// Checks the SQL connection and returns whether it's available for usage. If not, an attempt will be made
// to create the connection.
bool:CheckSQLConnection()
{
    // connect to the database if needed
    if (g_hDatabase == INVALID_HANDLE)
    {
        SQL_TConnect(DatabaseConnected, DATABASE_KEY);
        return false;
    }
    else
    {
        return true;
    }
}

public DatabaseConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE || error[0] != '\0')
        LogMessage("Failed to connect to database, error: %s", error);
    else
        g_hDatabase = hndl;
}

DisconnectFromDatabase()
{
    if (g_hDatabase != INVALID_HANDLE)
    {
        CloseHandle(g_hDatabase);
        g_hDatabase = INVALID_HANDLE;
    }
}

// Native function for showing the redirect window
public Native_ShowServerRedirectMenu(Handle:plugin, numParams)
{
   new client = GetNativeCell(1);
   ShowServerMenu(client);
}

public Native_RedirectList(Handle:plugin, numParams)
{
    new bool:showCurrent = GetConVarBool(g_varShowCurrent);
    new bool:showOffline = GetConVarBool(g_varShowOffline);
    new any:callback = GetNativeCell(1);
    new any:userData = GetNativeCell(2);
    Internal_RedirectList(plugin, showCurrent, showOffline, callback, userData);
}

public Native_RedirectListFiltered(Handle:plugin, numParams)
{
    new bool:showCurrent = bool:GetNativeCell(1);
    new bool:showOffline = bool:GetNativeCell(2);
    new any:callback = GetNativeCell(3);
    new any:userData = GetNativeCell(4);
    Internal_RedirectList(plugin, showCurrent, showOffline, callback, userData);
}

Internal_RedirectList(Handle:plugin, bool:showCurrent, bool:showOffline, any:callback, any:userData)
{   
    new serverId = GetConVarInt(g_varServerId);

    // execute async query for the server list
    new bool:isReady = CheckSQLConnection();
    if (isReady)
    {
        decl String:query[512];
        CreateServerListQuery(query, sizeof(query), serverId, showOffline, showCurrent);
        
        // store plugin handle and callback function in a datapack
        new Handle:data = CreateDataPack();
        WritePackCell(data, _:callback);
        WritePackCell(data, _:plugin);
        WritePackCell(data, _:userData);
        
        SQL_TQuery(g_hDatabase, LoadServerRedirectList_Query, query, data);
    }
    else
    {
        Call_StartFunction(plugin, callback);
        Call_PushCell(-1);
        Call_PushString("Database connection unavailable");
        Call_PushCell(Handle:INVALID_HANDLE);
        Call_PushCell(userData);
        new result;
        Call_Finish(result);
    }
}

public LoadServerRedirectList_Query(Handle:db, Handle:query, const String:error[], any:data)
{
    // read vars from the data
    ResetPack(data);
    new any:callback = ReadPackCell(data);
    new Handle:plugin = Handle:ReadPackCell(data);
    new any:userData = any:ReadPackCell(data);
    CloseHandle(data);
    
    
    if (query == INVALID_HANDLE)
    {
        LogError("(LoadServerRedirectList_Query) Active server query failed, error: %s", error);
        DisconnectFromDatabase();
        
        Call_StartFunction(plugin, callback);
        Call_PushCell(-1);
        Call_PushString("Failed to query server list from the database. Check the log for errors");
        Call_PushCell(Handle:INVALID_HANDLE);
        Call_PushCell(userData);
        new result;
        Call_Finish(result);
    }
    else
    {
        // create keyvalues structure containing the servers
        new Handle:list = CreateKeyValues("servers");
        
        decl String:address[50];
        decl String:display_name[255];
        decl String:offline_name[255];
        decl String:map[64];
        new maxPlayers;
        new currPlayers;
        new timeDiff;
        new bool:isOnline;
        new serverCount = 0;

        while (SQL_FetchRow(query))
        {
            SQL_FetchString(query, 1, address, sizeof(address));
            SQL_FetchString(query, 2, display_name, sizeof(display_name));
            SQL_FetchString(query, 3, offline_name, sizeof(offline_name));
            maxPlayers = SQL_FetchInt(query, 4);
            currPlayers = SQL_FetchInt(query, 5);
            SQL_FetchString(query, 6, map, sizeof(map));
            timeDiff = SQL_FetchInt(query, 7);
            
            if (timeDiff > SERVER_TIMEOUT_SECONDS)
            {
                isOnline = false;
            }
            else
            {
                isOnline = true;
            }
            
            // format names
            FormatServerName(display_name, sizeof(display_name), map, currPlayers, maxPlayers);
            FormatServerName(offline_name, sizeof(offline_name), map, currPlayers, maxPlayers);

            
            KvJumpToKey(list, address, true);
            KvSetSectionName(list, address);
            KvSetString(list, "display_name", display_name);
            KvSetString(list, "offline_name", offline_name);
            KvSetNum(list, "maxplayers", maxPlayers);
            KvSetNum(list, "currentplayers", currPlayers);
            KvSetNum(list, "update_sec", timeDiff);
            KvSetString(list, "map", map);
            KvSetNum(list, "isonline", isOnline);
            KvRewind(list);
            
            serverCount++;
        }
        
        Call_StartFunction(plugin, callback);
        Call_PushCell(serverCount);
        Call_PushString("");
        Call_PushCell(list);
        Call_PushCell(userData);
        new result;
        Call_Finish(result);

        // close key values handle
        CloseHandle(list);
    }
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("ShowServerRedirectMenu", Native_ShowServerRedirectMenu);
    CreateNative("LoadServerRedirectList", Native_RedirectList);
    CreateNative("LoadServerRedirectListFiltered", Native_RedirectListFiltered);
    RegPluginLibrary("serverredir");
    return APLRes_Success;
}
