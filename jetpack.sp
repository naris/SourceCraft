/**
 * vim: set ai et ts=4 sw=4 :
 * File: jetpack.sp
 * Description: Jetpack for source.
 * Author(s): Knagg0
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "topmessage"

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.1.0"

#define MOVETYPE_WALK		2
#define MOVETYPE_FLYGRAVITY	5
#define MOVECOLLIDE_DEFAULT	0
#define MOVECOLLIDE_FLY_BOUNCE	1

#define LIFE_ALIVE	0

#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

//#define ADMFLAG_JETPACK ADMFLAG_GENERIC
#define ADMFLAG_JETPACK ADMFLAG_CUSTOM2

// ConVars
new Handle:sm_jetpack		= INVALID_HANDLE;
new Handle:sm_jetpack_sound	= INVALID_HANDLE;
new Handle:sm_jetpack_speed	= INVALID_HANDLE;
new Handle:sm_jetpack_volume= INVALID_HANDLE;
new Handle:sm_jetpack_fuel	= INVALID_HANDLE;
new Handle:sm_jetpack_onspawn	= INVALID_HANDLE;
new Handle:sm_jetpack_announce	= INVALID_HANDLE;
new Handle:sm_jetpack_adminonly	= INVALID_HANDLE;
new Handle:sm_jetpack_refueling_time= INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;
new TopMenuObject:oGiveJetpack = INVALID_TOPMENUOBJECT;
new TopMenuObject:oTakeJetpack = INVALID_TOPMENUOBJECT;

// SendProp Offsets
new g_iLifeState	= -1;
new g_iMoveCollide	= -1;
new g_iMoveType		= -1;
new g_iVelocity		= -1;

// Soundfile
new String:g_sSound[255]	= "vehicles/airboat/fan_blade_fullthrottle_loop1.wav";

// Is Jetpack Enabled
new bool:g_bHasJetpack[MAXPLAYERS + 1];
new bool:g_bFromNative[MAXPLAYERS + 1];
new bool:g_bJetpackOn[MAXPLAYERS + 1];

// Fuel for the Jetpacks
new g_iFuel[MAXPLAYERS + 1];
new g_iRefuelAmount[MAXPLAYERS + 1];
new Float:g_fRefuelingTime[MAXPLAYERS + 1];

// Timer For GameFrame
new Float:g_fTimer	= 0.0;

// MaxClients
new g_iMaxClients	= 0;

// Native interface settings
new bool:g_bNativeOverride = false;
new g_iNativeJetpacks      = 0;

public Plugin:myinfo =
{
	name = "Jetpack",
	author = "Knagg0",
	description = "Adds a jetpack to fly around the map with",
	version = PLUGIN_VERSION,
	url = "http://www.mfzb.de"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
	// Register Natives
	CreateNative("ControlJetpack",Native_ControlJetpack);
	CreateNative("GetJetpack",Native_GetJetpack);
	CreateNative("GetJetpackFuel",Native_GetJetpackFuel);
	CreateNative("GetJetpackRefuelingTime",Native_GetJetpackRefuelingTime);
	CreateNative("SetJetpackFuel",Native_SetJetpackFuel);
	CreateNative("SetJetpackRefuelingTime",Native_SetJetpackRefuelingTime);
	CreateNative("GiveJetpack",Native_GiveJetpack);
	CreateNative("TakeJetpack",Native_TakeJetpack);
	CreateNative("GiveJetpackFuel",Native_GiveJetpackFuel);
	CreateNative("TakeJetpackFuel",Native_TakeJetpackFuel);
	CreateNative("StartJetpack",Native_StartJetpack);
	CreateNative("StopJetpack",Native_StopJetpack);

	return true;
}

public OnPluginStart()
{
	AutoExecConfig();
	
	// Create ConVars
	CreateConVar("sm_jetpack_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_jetpack = CreateConVar("sm_jetpack", "1", "enable jetpacks on the server", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_jetpack_sound = CreateConVar("sm_jetpack_sound", g_sSound, "enable the jetpack sound", FCVAR_PLUGIN);
	sm_jetpack_speed = CreateConVar("sm_jetpack_speed", "100", "speed of the jetpack", FCVAR_PLUGIN);
	sm_jetpack_volume = CreateConVar("sm_jetpack_volume", "0.5", "volume of the jetpack sound", FCVAR_PLUGIN);
	sm_jetpack_fuel = CreateConVar("sm_jetpack_fuel", "-1", "amount of fuel to start with (-1 == unlimited)", FCVAR_PLUGIN);
	sm_jetpack_refueling_time = CreateConVar("sm_jetpack_refueling_time", "30.0", "amount of time to wait before refueling", FCVAR_PLUGIN);
	sm_jetpack_onspawn = CreateConVar("sm_jetpack_onspawn", "1", "enable giving players a jetpack when they spawn", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
  	sm_jetpack_announce = CreateConVar("sm_jetpack_announce","1","This will enable announcements that jetpacks are available");
	sm_jetpack_adminonly = CreateConVar("sm_jetpack_adminonly", "0", "only allows admins to have jetpacks when set to 1", FCVAR_PLUGIN);

	// Create ConCommands
	RegConsoleCmd("+sm_jetpack", JetpackP, "use jetpack (keydown)", FCVAR_GAMEDLL);
	RegConsoleCmd("-sm_jetpack", JetpackM, "use jetpack (keyup)", FCVAR_GAMEDLL);

	// Register admin cmds
	RegAdminCmd("sm_jetpack_give",Command_GiveJetpack,ADMFLAG_JETPACK,"","give a jetpack to a player");
	RegAdminCmd("sm_jetpack_take",Command_TakeJetpack,ADMFLAG_JETPACK,"","take the jetpack from a player");

	// Hook events
	HookEvent("player_spawn",PlayerSpawnEvent);
	
	// Find SendProp Offsets
	if((g_iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState")) == -1)
		LogError("Could not find offset for CBasePlayer::m_lifeState");
		
	if((g_iMoveCollide = FindSendPropOffs("CBaseEntity", "movecollide")) == -1)
		LogError("Could not find offset for CBaseEntity::movecollide");
		
	if((g_iMoveType = FindSendPropOffs("CBaseEntity", "movetype")) == -1)
		LogError("Could not find offset for CBaseEntity::movetype");
		
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	g_fTimer = 0.0;
	g_iMaxClients = GetMaxClients();
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index

	if (g_bHasJetpack[index])
		g_iFuel[index] = g_iRefuelAmount[index];
	else if (!g_bNativeOverride && GetConVarBool(sm_jetpack) && GetConVarBool(sm_jetpack_onspawn))
	{
		// Check for Admin Only
		if (GetConVarBool(sm_jetpack_adminonly))
		{
			new AdminId:aid = GetUserAdmin(index);
			if (aid == INVALID_ADMIN_ID || !GetAdminFlag(aid, Admin_Generic, Access_Effective))
				return;
		}

		g_bHasJetpack[index] = true;
		g_iFuel[index] = g_iRefuelAmount[index] = GetConVarInt(sm_jetpack_fuel);
		g_fRefuelingTime[index] = GetConVarFloat(sm_jetpack_refueling_time);
		if (GetConVarBool(sm_jetpack_announce))
		{
			PrintToChat(index,"%c[Jetpack] %cIs enabled, valid commands are: [%c+jetpack%c] [%c-jetpack%c]",
					COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
		}
	}
}

public OnConfigsExecuted()
{
	GetConVarString(sm_jetpack_sound, g_sSound, sizeof(g_sSound));
	PrecacheSound(g_sSound, true);
}

public OnGameFrame()
{
	if((g_iNativeJetpacks > 0 || GetConVarBool(sm_jetpack)) && g_fTimer < GetGameTime() - 0.075)
	{
		g_fTimer = GetGameTime();

		for(new i = 1; i <= g_iMaxClients; i++)
		{
			if(g_bJetpackOn[i])
			{
				if (g_iFuel[i] != 0)
				{
					if(!IsAlive(i))
						StopJetpack(i);
					else
					{
						if (g_iFuel[i] > 0 && g_iFuel[i] < 25)
						{
							// Low on Fuel, Make it sputter.
							if (g_iFuel[i] % 2)
                            {
								StopSound(i, SNDCHAN_AUTO, g_sSound);
								SetMoveType(i, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
							}
							else
							{
								StartJetpack(i);
								AddVelocity(i, GetConVarFloat(sm_jetpack_speed));
							}
						}
						else
							AddVelocity(i, GetConVarFloat(sm_jetpack_speed));

						if (g_iFuel[i] > 0)
						{
							g_iFuel[i]--;
							/* Display the Fuel Gauge */
							decl String:gauge[30] = "[====+=====|=====+====]";
							new Float:percent = float(g_iFuel[i]) / float(g_iRefuelAmount[i]);
							new pos = RoundFloat(percent * 21.0);
							if (pos < 21)
							{
								gauge{pos} = ']';
								gauge{pos+1} = 0;
							}

							new r,g,b;
							if (percent <= 0.25 || g_iFuel[i] < 25)
							{
								r = 255;
								g = 0;
								b = 0;
							}
							else if (percent >= 0.50)
							{
								r = 0;
								g = 255;
								b = 0;
							}
							else
							{
								r = 255;
								g = 255;
								b = 0;
							}
							SendTopMessage(i, pos+2, 1, r,g,b,255, gauge);
						}
					}
				}

				if (g_iFuel[i] == 0)
				{
					StopJetpack(i);
					CreateTimer(g_fRefuelingTime[i],RefuelJetpack,i);
					if(GetConVarBool(sm_jetpack_announce))
					{
						SendTopMessage(i, 1, 1, 255,0,0,128, "[] Your jetpack has run out of fuel");
						PrintToChat(i,"%c[Jetpack] %cYour jetpack has run out of fuel",
									COLOR_GREEN,COLOR_DEFAULT);
					}
				}
			}
		}
	}
}

public Action:RefuelJetpack(Handle:timer,any:client)
{
	if (client && g_bHasJetpack[client] && IsClientConnected(client) && IsPlayerAlive(client))
	{
		new tank_size = g_iRefuelAmount[client];
		if (g_iFuel[client] < tank_size)
		{
			g_iFuel[client] = tank_size;
			if(GetConVarBool(sm_jetpack_announce))
			{
				SendTopMessage(client, 30, 1, 0,255,0,128, "[====+=====|=====+====]");
				PrintToChat(client,"%c[Jetpack] %cYour jetpack has been refueled",
							COLOR_GREEN,COLOR_DEFAULT);
			}
		}
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	g_bHasJetpack[client] = false;
	if (g_bFromNative[client])
	{
		g_bFromNative[client] = false;
		g_iNativeJetpacks--;
	}
}

public OnClientDisconnect(client)
{
	StopJetpack(client);
	g_bHasJetpack[client] = false;
	if (g_bFromNative[client])
	{
		g_bFromNative[client] = false;
		g_iNativeJetpacks--;
	}
}

public Action:JetpackP(client, args)
{
	if ((g_iNativeJetpacks > 0 || GetConVarBool(sm_jetpack)) && 
	    g_bHasJetpack[client] && !g_bJetpackOn[client] && IsAlive(client))
	{
		StartJetpack(client);
	}
	return Plugin_Continue;
}

public Action:JetpackM(client, args)
{
	StopJetpack(client);
	return Plugin_Continue;
}

StartJetpack(client)
{
	if (g_iFuel[client] != 0)
	{
		new Float:vecPos[3];
		GetClientAbsOrigin(client, vecPos);
		EmitSoundToAll(g_sSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,
				       GetConVarFloat(sm_jetpack_volume), SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
		SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
		g_bJetpackOn[client] = true;
	}
}

StopJetpack(client)
{
	if(g_bJetpackOn[client])
	{
		if(IsAlive(client)) SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
		StopSound(client, SNDCHAN_AUTO, g_sSound);
		g_bJetpackOn[client] = false;
	}
}

SetMoveType(client, movetype, movecollide)
{
	if(g_iMoveType == -1) return;
	SetEntData(client, g_iMoveType, movetype);
	if(g_iMoveCollide == -1) return;
	SetEntData(client, g_iMoveCollide, movecollide);
}

AddVelocity(client, Float:speed)
{
	if(g_iVelocity == -1) return;
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	
	vecVelocity[2] += speed;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

bool:IsAlive(client)
{
	return (g_iLifeState != -1 && GetEntData(client, g_iLifeState, 1) == LIFE_ALIVE);
}

public Native_StartJetpack(Handle:plugin,numParams)
{
	if(numParams == 1)
	{
		new client = GetNativeCell(1);
		if(g_bHasJetpack[client] && !g_bJetpackOn[client] && IsAlive(client))
		{
			StartJetpack(client);
			return 1;
		}
		else
			return 0;
	}
	else
		return -1;
}

public Native_StopJetpack(Handle:plugin,numParams)
{
	if(numParams == 1)
	{
		new client = GetNativeCell(1);
		StopJetpack(client);
		return 0;
	}
	else
		return -1;
}

public Native_GiveJetpack(Handle:plugin,numParams)
{
	if(numParams >= 1 && numParams <= 3)
	{
		new client = GetNativeCell(1);
		g_bHasJetpack[client] = true;
		g_bFromNative[client] = true;
		g_iFuel[client] = g_iRefuelAmount[client] = (numParams >= 2) ? GetNativeCell(2) : GetConVarInt(sm_jetpack_fuel);
		g_fRefuelingTime[client] = (numParams >= 3) ? GetNativeCell(3) : GetConVarFloat(sm_jetpack_refueling_time);
		g_iNativeJetpacks++;
		return g_iFuel[client];
	}
	else
		return -1;
}

public Native_TakeJetpack(Handle:plugin,numParams)
{
	if(numParams == 1)
	{
		new client = GetNativeCell(1);
		StopJetpack(client);
		g_bHasJetpack[client] = false;
		if (g_bFromNative[client])
		{
			g_bFromNative[client] = false;
			g_iNativeJetpacks--;
		}
		return 0;
	}
	else
		return -1;
}

public Native_GiveJetpackFuel(Handle:plugin,numParams)
{
	if(numParams >= 1 && numParams <= 2)
	{
		new client = GetNativeCell(1);
		if (numParams > 1) 
		{
			if (client > 0 && client <= MAXPLAYERS+1)
				g_iFuel[client] +=  GetNativeCell(2);
		}
		else
		{
			new amount = GetConVarInt(sm_jetpack_fuel);
			if (amount >= 0)
				g_iFuel[client] += amount;
			else
				g_iFuel[client] = amount;
		}
		return g_iFuel[client];
	}
	else
		return -1;
}

public Native_TakeJetpackFuel(Handle:plugin,numParams)
{
	if(numParams >= 1 && numParams <= 2)
	{
		new client = GetNativeCell(1);
		if (client > 0 && client <= MAXPLAYERS+1)
			g_iFuel[client] -= (numParams > 1) ? GetNativeCell(2) : g_iFuel[client];
		return g_iFuel[client];
	}
	else
		return -1;
}

public Native_SetJetpackFuel(Handle:plugin,numParams)
{
	if(numParams == 2)
	{
		new client = GetNativeCell(1);
		if (client)
		{
			if (client <= MAXPLAYERS+1)
				g_iFuel[client] = g_iRefuelAmount[client] = GetNativeCell(2);
		}
		else
			SetConVarInt(sm_jetpack_fuel, GetNativeCell(2));
	}
	else if(numParams == 1)
	{
		SetConVarInt(sm_jetpack_fuel, GetNativeCell(1));
	}

	return 0;
}

public Native_SetJetpackRefuelingTime(Handle:plugin,numParams)
{
	if(numParams == 2)
	{
		new client = GetNativeCell(1);
		if (client)
		{
			if (client <= MAXPLAYERS+1)
				g_fRefuelingTime[client] =  Float:GetNativeCell(2);
		}
		else
			SetConVarFloat(sm_jetpack_refueling_time, Float:GetNativeCell(2));
	}
	else if(numParams == 1)
	{
		SetConVarFloat(sm_jetpack_refueling_time, Float:GetNativeCell(1));
	}

	return 0;
}

public Native_GetJetpackFuel(Handle:plugin,numParams)
{
	return (numParams == 1) ? g_iFuel[GetNativeCell(1)] : GetConVarInt(sm_jetpack_fuel);
}

public Native_GetJetpackRefuelingTime(Handle:plugin,numParams)
{
	return _:((numParams == 1) ? g_fRefuelingTime[GetNativeCell(1)] : GetConVarFloat(sm_jetpack_refueling_time));
}

public Native_GetJetpack(Handle:plugin,numParams)
{
	if (numParams == 1)
		return g_bHasJetpack[GetNativeCell(1)];
	else
		return 0;
}

public Native_ControlJetpack(Handle:plugin,numParams)
{
	g_bNativeOverride = (numParams >= 1) ? GetNativeCell(1) : true;
	if (numParams >= 2)
	{
		SetConVarBool(sm_jetpack_announce, GetNativeCell(2));
	}
	return 0;
}

public Action:Command_GiveJetpack(client,argc)
{
	if(argc>=1)
	{
		if (g_bNativeOverride)
			ReplyToCommand(client,"Jetpacks are controlled by another plugin");
		else
		{
			decl String:target[64];
			GetCmdArg(1,target,64);
			new count=SetJetpack(client,target,true);
			if(!count)
				ReplyToTargetError(client, count);
		}
	}
	else
	{
		ReplyToCommand(client,"%c[Jetpack] Usage: %csm_jetpack_give <@userid/partial name>",
				       COLOR_GREEN,COLOR_DEFAULT);
	}
	return Plugin_Handled;
}

public Action:Command_TakeJetpack(client,argc)
{
	if(argc>=1)
	{
		decl String:target[64];
		if (g_bNativeOverride)
			ReplyToCommand(client,"Jetpacks are controlled by another plugin");
		else
		{
			GetCmdArg(1,target,64);
			new count=SetJetpack(client,target,false);
			if(!count)
				ReplyToTargetError(client, count);
		}
	}
	else
	{
		ReplyToCommand(client,"%c[Jetpack] Usage: %csm_jetpack_take <@userid/partial name>",
				       COLOR_GREEN,COLOR_DEFAULT);
	}
	return Plugin_Handled;
}

public SetJetpack(client,const String:target[],bool:enable)
{
	decl String:name[64];
	new bool:isml,clients[MAXPLAYERS+1];
	new count=ProcessTargetString(target,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,
                                  name,sizeof(name),isml);
	if(count)
	{
		for(new x=0;x<count;x++)
		{
			switch (PerformJetpack(client, clients[x], enable))
			{
				case 1: ReplyToCommand(client,"Target already has a jetpack");
				case 2: ReplyToCommand(client,"Unable to remove the jetpack");
				case 0:
				{
					if (enable)
						ReplyToCommand(client, "Gave a jetpack to target");
					else
						ReplyToCommand(client, "Removed the jetpack form target");
				}
			}
		}
	}
	return count;
}

public PerformJetpack(client, target, bool:enable)
{
	if(enable)
	{
		if (!g_bHasJetpack[target])
		{
			g_bHasJetpack[target] = true;
			g_iFuel[target] = g_iRefuelAmount[target] = GetConVarInt(sm_jetpack_fuel);
			g_fRefuelingTime[target] = GetConVarFloat(sm_jetpack_refueling_time);
			if(GetConVarBool(sm_jetpack_announce))
			{
				PrintToChat(target,"%c[Jetpack] %cIs enabled, valid commands are: [%c+jetpack%c] [%c-jetpack%c]",
						COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
			}
			LogAction(client, target, "\"%L\" gave a jetpack to \"%L\"", client, target);
			return 0;
		}
		else
			return 1;
	}
	else
	{
		if (!g_bFromNative[target])
		{
			StopJetpack(target);
			g_bHasJetpack[target] = false;
			LogAction(client, target, "\"%L\" took the jetpack from \"%L\"", client, target);
			return 0;
		}
		else
			return 2;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu != hAdminMenu)
	{
		/* Save the Handle */
		hAdminMenu = topmenu;
		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
		oGiveJetpack = AddToTopMenu(hAdminMenu, "sm_give_jetpack", TopMenuObject_Item, AdminMenu,
				server_commands, "sm_give_jetpack", ADMFLAG_JETPACK);
		oTakeJetpack = AddToTopMenu(hAdminMenu, "sm_take_jetpack", TopMenuObject_Item, AdminMenu,
				server_commands, "sm_take_jetpack", ADMFLAG_JETPACK);
	}
}

public AdminMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == oGiveJetpack)
			Format(buffer, maxlength, "Give Jetpack");
		else if (object_id == oTakeJetpack)
			Format(buffer, maxlength, "Take Jetpack");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		JetpackMenu(param, object_id);
	}
}

JetpackMenu(client, TopMenuObject:object_id)
{
	new Handle:menu = CreateMenu(MenuHandler_Jetpack);
	
	decl String:title[100];
	if (object_id == oGiveJetpack)
		Format(title, sizeof(title), "%T:", "Give a Jetpack", client);
	else
		Format(title, sizeof(title), "%T:", "Take the Jetpack", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	AddTargetsToMenu(menu, client, true, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Jetpack(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:title[32];
	GetMenuTitle(menu,title,sizeof(title));

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			new String:name[32];
			GetClientName(target, name, sizeof(name));

			if (StrContains(title, "Give") != -1)
			{
				PerformJetpack(param1, target, true);
				ShowActivity2(param1, "[SM] ", "%t", "Gave target a jetpack", "_s", name);
			}
			else
			{
				PerformJetpack(param1, target, false);
				ShowActivity2(param1, "[SM] ", "%t", "Took the jetpack from target", "_s", name);
			}
		}

		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			if (StrContains(title, "Give") != -1)
			{
				JetpackMenu(param1, oGiveJetpack);
			}
			else
			{
				JetpackMenu(param1, oTakeJetpack);
			}
		}
	}
}

