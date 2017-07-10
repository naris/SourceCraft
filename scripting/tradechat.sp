#include <sourcemod>
#include <clientprefs>
#include <colors>

public Plugin:myinfo = 
{
	name = "Trade Chat",
	author = "Luki",
	description = "",
	version = "1.1",
	url = "http://luki.net.pl"
};

new Handle:hCookie = INVALID_HANDLE;
new HideTradeChat[MAXPLAYERS + 1];
new TradeChatGag[MAXPLAYERS + 1];
new String:logfile[255];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("tradechat.phrases");

	RegConsoleCmd("sm_t", Command_TradeChat);
	RegConsoleCmd("sm_lf", Command_TradeChat);
	RegConsoleCmd("sm_wts", Command_TradeChat);
	RegConsoleCmd("sm_wtt", Command_TradeChat);
	RegConsoleCmd("sm_wtb", Command_TradeChat);
	
	RegConsoleCmd("sm_trade", Command_TradeChat);
	RegConsoleCmd("sm_hidechat", Command_HideChat);
	
	RegAdminCmd("sm_trade_gag", Command_TradeGag, ADMFLAG_CHAT);
	RegAdminCmd("sm_trade_ungag", Command_TradeUnGag, ADMFLAG_CHAT);
	
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/tradechat.log");
	
	CreateTimer(180.0, AdTimer, _, TIMER_REPEAT);
}

public OnAllPluginsLoaded()
{
	new Handle:Plugin_ClientPrefs = FindPluginByFile("clientprefs.smx");
	new PluginStatus:Plugin_ClientPrefs_Status = GetPluginStatus(Plugin_ClientPrefs);
	if ((Plugin_ClientPrefs == INVALID_HANDLE) || (Plugin_ClientPrefs_Status != Plugin_Running))
		LogError("This plugin require clientprefs plugin to allow users to disable trade chat.");
	else
		hCookie = RegClientCookie("tradechat", "Hide trade chat", CookieAccess_Protected);
}

public OnClientPostAdminCheck(client)
{
	TradeChatGag[client] = 0;
	if (hCookie != INVALID_HANDLE)
	{
		new String:cookie[4];
		if (AreClientCookiesCached(client))
		{
			GetClientCookie(client, hCookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "on"))
			{
				HideTradeChat[client] = 1;
				return;
			}
			if (StrEqual(cookie, "off"))
			{
				HideTradeChat[client] = 0;
				return;
			}
		}
		SetClientCookie(client, hCookie, "off");
		HideTradeChat[client] = 0;
	}
	else
	{
		HideTradeChat[client] = 0;
	}
}

public Action:Command_TradeChat(client, args)
{
	new String:text[512], String:name[MAX_NAME_LENGTH], String:steamID[32];
	GetCmdArgString(text, sizeof(text));
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, steamID, sizeof(steamID));
	
	if (HideTradeChat[client])
	{
		CPrintToChat(client, "%t", "TradeDisabledForYou");
		return Plugin_Handled;
	}
	
	if (TradeChatGag[client])
	{
		CPrintToChat(client, "%t", "TradeBanned");
		return Plugin_Handled;
	}
	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			if (!HideTradeChat[i])
				CPrintToChat(i, "{green}[Trade Chat] {lightgreen}%s: {default}%s", name, text);
	}
	
	LogToFile(logfile, "\"%s<%d><%s><>\" say \"%s\"", name, GetClientUserId(client), steamID, text);
	
	return Plugin_Handled;
}

public Action:Command_TradeGag(client, args)
{
	new String:sTarget[MAX_NAME_LENGTH];

	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		ReplyToCommand(client, "%t", "TradeGagUsage");
		return Plugin_Handled;
	}
	
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml, String:target_name[MAX_TARGET_LENGTH];
	
	if ((target_count = ProcessTargetString(
			sTarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED || COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new String:name[MAX_NAME_LENGTH], String:clientSID[32], String:targetSID[32];
		GetClientName(target_list[i], sTarget, sizeof(sTarget));
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, clientSID, sizeof(clientSID));
		GetClientAuthString(target_list[i], targetSID, sizeof(targetSID));
		TradeChatGag[target_list[i]] = 1;

		CPrintToChatAll("%t", "TradeBan", name, sTarget);
		LogToFile(logfile, "\"%s<%d><%s><>\" has disabled trade chat for \"%s<%d><%s><>\"", name, GetClientUserId(client), clientSID, sTarget, GetClientUserId(target_list[i]), targetSID);
	}
	
	return Plugin_Handled;
}

public Action:Command_TradeUnGag(client, args)
{
	new String:sTarget[MAX_NAME_LENGTH];

	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		ReplyToCommand(client, "%t", "TradeGagUsage");
		return Plugin_Handled;
	}
	
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml, String:target_name[MAX_TARGET_LENGTH];
	
	if ((target_count = ProcessTargetString(
			sTarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED || COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new String:name[MAX_NAME_LENGTH], String:clientSID[32], String:targetSID[32];
		GetClientName(target_list[i], sTarget, sizeof(sTarget));
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, clientSID, sizeof(clientSID));
		GetClientAuthString(target_list[i], targetSID, sizeof(targetSID));
		TradeChatGag[target_list[i]] = 0;

		CPrintToChatAll("%t", "TradeUnBan", name, sTarget);
		LogToFile(logfile, "\"%s<%d><%s><>\" has enabled trade chat for \"%s<%d><%s><>\"", name, GetClientUserId(client), clientSID, sTarget, GetClientUserId(target_list[i]), targetSID);
	}
	
	return Plugin_Handled;
}

public Action:Command_HideChat(client, args)
{
	if (hCookie != INVALID_HANDLE)
	{
		new String:name[MAX_NAME_LENGTH], String:steamID[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamID, sizeof(steamID));
		if (!HideTradeChat[client])
		{
			SetClientCookie(client, hCookie, "on");
			HideTradeChat[client] = 1;
			CPrintToChat(client, "%t", "HideChatOn");
			LogToFile(logfile, "\"%s<%d><%s><>\" has disabled trade chat.", name, GetClientUserId(client), steamID);
		}
		else
		{
			SetClientCookie(client, hCookie, "off");
			HideTradeChat[client] = 0;
			CPrintToChat(client, "%t", "HideChatOff");
			LogToFile(logfile, "\"%s<%d><%s><>\" has enabled trade chat.", name, GetClientUserId(client), steamID);
		}
	}
	
	return Plugin_Handled;
}

public Action:AdTimer(Handle:timer)
{
	CPrintToChatAll("%t", "Advert1");
	CPrintToChatAll("%t", "Advert2");
	return Plugin_Continue;
}