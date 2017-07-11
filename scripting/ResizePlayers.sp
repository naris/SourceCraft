#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
    name 		=		"[TF2] Resize Players",
    author		=		"11530",
    description	=		"Tiny!",
    version		=		PLUGIN_VERSION,
    url			=		"http://www.sourcemod.net"
};


new Handle:g_hVersion = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hResizeScale = INVALID_HANDLE;
new Handle:g_hDefaultStatus = INVALID_HANDLE;
new Handle:g_hMode = INVALID_HANDLE;

new bool:g_bEnabled;
new bool:g_bDefaultStatus;
new Float:g_fDefaultScale;
new Float:g_fClientScale[MAXPLAYERS+1];
new g_iMode;


public OnPluginStart()
{
	g_hVersion = CreateConVar("sm_resize_version", PLUGIN_VERSION, "\"Resize Players\" Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("sm_resize_enabled", "1", "0 = Disable plugin, 1 = Enable plugin", 0, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	g_hResizeScale = CreateConVar("sm_resize_defaultresize", "0.5", "Scale of models", 0, true, 0.0);
	g_fDefaultScale = GetConVarFloat(g_hResizeScale);
	
	g_hDefaultStatus = CreateConVar("sm_resize_defaultstatus", "0", "0 = Turned off for clients by default, 1 = Turned on", 0, true, 0.0, true, 1.0);
	g_bDefaultStatus = GetConVarBool(g_hDefaultStatus);
	
	g_hMode = CreateConVar("sm_resize_mode", "2", "1 = All players, 2 = Admins with correct flag", 0, true, 1.0, true, 2.0);
	g_iMode = GetConVarInt(g_hMode);
	
	HookConVarChange(g_hEnabled, ConVarChangeCallback);
	HookConVarChange(g_hDefaultStatus, ConVarChangeCallback);
	HookConVarChange(g_hMode, ConVarChangeCallback);
	
	RegAdminCmd("sm_resize", OnResizeCmd, 0, "Toggles a client's size");
}

public OnConfigsExecuted()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_fClientScale[i] = g_fDefaultScale;
		if (IsClientInGame(i) && IsClientAuthorized(i) && g_bDefaultStatus)
		{
			if (g_iMode == 2 && !CheckCommandAccess(i, "sm_resizeself", ADMFLAG_CHEATS))
			{
				continue;
			}
			
			ResizePlayer(i, g_fDefaultScale);
		}
	}
}

public OnMapStart()
{
	// hax against valvefail
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE)
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION);
	}
}

ResizePlayer(client, Float:fScale = 0.0)
{
	new Float:fCurrent = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	if (fScale == 0.0)
	{
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", ((fCurrent != g_fClientScale[client]) ? g_fClientScale[client] : 1.0));		
	}
	else
	{
		if (fScale != 1.0)
		{
			g_fClientScale[client] = fScale;
		}
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", fScale);
	}
}

public Action:OnResizeCmd(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "\x05[SM]\x01 Cannot use command from RCON.");
		return Plugin_Handled;
	}
	
	if (g_bEnabled)
	{
		if (args == 0)
		{
			if (g_iMode == 1 || (g_iMode == 2 && CheckCommandAccess(client, "sm_resizeself", ADMFLAG_CHEATS)))
			{
				ResizePlayer(client);
				ShowActivity2(client, "\x05[SM]\x01 ","%N was \x05resized\x01!", client);				
			}
		}
		else if (args == 1 || args == 2)
		{
			if (CheckCommandAccess(client, "sm_resize", ADMFLAG_CHEATS))
			{
				new target_count, bool:tn_is_ml;
				decl String:sTargetName[MAX_TARGET_LENGTH], iTargetList[MAXPLAYERS], String:sTarget[MAX_NAME_LENGTH];
				GetCmdArg(1, sTarget, sizeof(sTarget));
				if ((target_count = ProcessTargetString(sTarget, client, iTargetList, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), tn_is_ml)) <= 0)
				{
					ReplyToTargetError(client, target_count);
					return Plugin_Handled;
				}
				ShowActivity2(client, "\x05[SM]\x01 ", "%N \x05resized\x01 %s!", client, sTargetName);
				
				new Float:fScale = 0.0;
				if (args == 2)
				{
					decl String:sScale[128];
					GetCmdArg(2, sScale, sizeof(sScale));
					if ((fScale = StringToFloat(sScale)) <= 0.0)
					{
						fScale = 1.0;
					}
				}
				
				for (new i = 0; i < target_count; i++)
				{
					if (iTargetList[i] != 0)
					{
						ResizePlayer(iTargetList[i], fScale);
					}
				}

			}
			else
			{
				ReplyToCommand(client, "\x05[SM]\x01 You do not have access to this command!");
			}
		}
		else
		{
			ReplyToCommand(client, "\x05[SM]\x01 Usage: sm_resize [#userid|name] [scale]");
		}
	}
	return Plugin_Handled;
}

public ConVarChangeCallback(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	if (convar == g_hEnabled)
	{
		g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);
		//Set everyone to normal size if the plugin disabled/reenabled
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsClientObserver(i))
			{
				ResizePlayer(i, 1.0);
			}
		}
	}
	else if (convar == g_hResizeScale)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
				g_fClientScale[i] = g_fDefaultScale;
		}
	}
	else if (convar == g_hDefaultStatus)
	{
		g_bDefaultStatus = (StringToInt(newvalue) == 0 ? false : true);
	}
	else if (convar == g_hMode)
	{
		g_iMode = StringToInt(newvalue);
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (g_bDefaultStatus)
	{
		if (g_iMode == 2 && !CheckCommandAccess(client, "sm_resizeself", ADMFLAG_CHEATS))
		{
			return;
		}
		
		ResizePlayer(client, g_fDefaultScale);
	}
}

public OnClientDisconnect(client)
{
	g_fClientScale[client] = g_fDefaultScale;
}

public OnPluginEnd()
{
	//Reset current players back to normal size
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsClientObserver(i))
		{
			ResizePlayer(i, 1.0);
		}
	}
}