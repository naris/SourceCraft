#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "1.0"

new Handle:g_Database = INVALID_HANDLE;
new String:g_ServerIP[32];
public Plugin:myinfo = 
{
	name = "Item Logger",
	author = "Geit",
	description = "Item Logger",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
};

public OnPluginStart()
{
	CreateConVar("sm_item_logger_version", PL_VERSION, "TF2 Item Logger", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("item_found", Event_item_found);
	decl String:ip[24], String:port[8];
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));
	Format(g_ServerIP, sizeof(g_ServerIP), "%s:%s", ip, port);
	Database_Init();
}
public Action:Event_item_found(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "player");
	if (userid > 0 && DatabaseIntact() && IsClientInGame(userid))
	{
		decl String:item[128], String:item_esc[512], String:client_name[32], String:client_auth[32], String:client_name_esc[128], String:client_auth_esc[128], String:query[1024];
		//Client Info
		GetClientName(userid, client_name, sizeof(client_name));
		GetClientAuthString(userid, client_auth, sizeof(client_auth));
		//Item Info
		GetEventString(event, "item", item, sizeof(item));
		new method = GetEventInt(event, "method");
		new quality = GetEventInt(event, "quality");
		//Escaping
		SQL_EscapeString(g_Database, client_name, client_name_esc, sizeof(client_name_esc));
		SQL_EscapeString(g_Database, client_auth, client_auth_esc, sizeof(client_auth_esc));
		SQL_EscapeString(g_Database, item, item_esc, sizeof(item_esc));
		
		Format(query, sizeof(query), "INSERT INTO `log` SET `name`='%s', `steam_id`='%s', `time`=UNIX_TIMESTAMP(), `players`=%i, `item`='%s', `server`='%s', `method`=%i, `quality`=%i;", client_name_esc, client_auth_esc, GetClientCount(true), item_esc, g_ServerIP, method, quality);
		SQL_TQuery(g_Database, T_ErrorOnly, query);
	}
}

public DatabaseIntact()
{
	if(g_Database != INVALID_HANDLE)
	{
		return true;
	} 
	else 
	{
		return false;
	}	
}

public T_ErrorOnly(Handle:owner, Handle:result, const String:error[], any:client)
{
	if(result == INVALID_HANDLE)
	{
		LogError("[Item Logger] MYSQL ERROR (error: %s)", error);
		PrintToChatAll("MYSQL ERROR (error: %s)", error);
	}
}
stock Database_Init()
{
	
	decl String:error[255];	
	g_Database = SQL_Connect("feedback", true, error, sizeof(error));
	
	if(g_Database != INVALID_HANDLE)
	{
		SQL_FastQuery(g_Database, "SET NAMES 'UTF8'");
		SQL_FastQuery(g_Database, "CREATE TABLE IF NOT EXISTS `log` (  `id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(64) NOT NULL, `steam_id` varchar(25) NOT NULL DEFAULT '0',  `time` int(11) NOT NULL DEFAULT '0', `players` int(11) NOT NULL DEFAULT '0', `item` varchar(50) NOT NULL DEFAULT '0', `server` varchar(32) NOT NULL DEFAULT '0', `method` tinyint(2) NOT NULL DEFAULT '0', `quality` tinyint(2) NOT NULL DEFAULT '0', PRIMARY KEY (`id`), KEY `actualderptime` (`time`), KEY `Index 3` (`steam_id`) ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");
		return;
	} 
	else 
	{
		PrintToServer("Connection Failed for item logger: %s", error);
		return;
	}
}