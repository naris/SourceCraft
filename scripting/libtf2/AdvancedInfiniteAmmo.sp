/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: AdvancedInfiniteAmmo.sp
 * Description: Infinite Ammo for TF2
 * Author(s): Tylerst
 */

#pragma semicolon 1

#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2.9"


public Plugin:myinfo = 
{
	name = "Advanced Infinite Ammo",
	author = "Tylerst",
	
	description = "Infinite usage for just about everything",
	
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=190562"
}

new bool:g_bLateLoad = false;
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(late) g_bLateLoad = true;
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}

	CreateNative("ControlInfiniteAmmo", Native_ControlInfiniteAmmo);
	CreateNative("SetInfiniteAmmo", Native_SetInfiniteAmmo);
	CreateNative("FillWeaponAmmo", Native_FillWeaponAmmo);
	CreateNative("FillAmmo", Native_FillAmmo);
	RegPluginLibrary("aia");

	return APLRes_Success;
}



new bool:g_bInfiniteAmmo[MAXPLAYERS+1] = false;
new g_iClientWeapons[MAXPLAYERS+1][3];
new bool:g_bInfiniteAmmoToggle = false;
new bool:g_bWaitingForPlayers;

new Handle:g_hAllInfiniteAmmo = INVALID_HANDLE;
new Handle:g_hRoundWin = INVALID_HANDLE;
new Handle:g_hWaitingForPlayers = INVALID_HANDLE;
new Handle:g_hAdminOnly = INVALID_HANDLE;
new Handle:g_hBots = INVALID_HANDLE;
new Handle:g_hChat = INVALID_HANDLE;
new Handle:g_hLog = INVALID_HANDLE;
new Handle:g_hAmmoOnly = INVALID_HANDLE;
new Handle:g_hExtraStuff = INVALID_HANDLE;

new bool:g_bNativeControl = false;

public OnPluginStart()
{
	CreateConVar("sm_aia_version", PLUGIN_VERSION, "Advanced Infinite Ammo", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");

	g_hAllInfiniteAmmo = CreateConVar("sm_aia_all", "0", "Advanced Infinite Ammo for everyone");
	g_hAdminOnly = CreateConVar("sm_aia_adminonly", "0", "Advanced Infinite Ammo will work for admins only, 1 = Completely Admin Only, 2 = Admin Only but the commands will work on non-admins");
	g_hBots = CreateConVar("sm_aia_bots", "1", "Advanced Infinite Ammo will work for bots");
	g_hRoundWin = CreateConVar("sm_aia_roundwin", "1", "Advanced Infinite Ammo for everyone on round win");
	g_hWaitingForPlayers = CreateConVar("sm_aia_waitingforplayers", "1", "Advanced Infinite Ammo for everyone during waiting for players phase");
	g_hChat = CreateConVar("sm_aia_chat", "1", "Show Advanced Infinite Ammo changes in chat");
	g_hLog = CreateConVar("sm_aia_log", "1", "Log Advanced Infinite Ammo commands");
	g_hAmmoOnly = CreateConVar("sm_aia_ammoonly", "0", "Sets how to give ammo, 0 = Infinite Clip and Ammo(default behavior), 1 = Infinite Ammo but must still reload clip");
	g_hExtraStuff = CreateConVar("sm_aia_extrastuff", "1", "Whether to add non-ammo related things such as infinite Ubercharge, shield charge, rage, bonk, etc");

	HookConVarChange(g_hAllInfiniteAmmo, CvarChange_AllInfiniteAmmo);
	HookConVarChange(g_hAdminOnly, CvarChange_AdminOnly);
	HookConVarChange(g_hBots, CvarChange_Bots);
	HookConVarChange(g_hAmmoOnly, CvarChange_AmmoOnly);
	HookConVarChange(g_hExtraStuff, CvarChange_ExtraStuff);

	RegAdminCmd("sm_aia", Command_SetAIA, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) - Usage: sm_aia \"target\" \"1/0\"");
	RegAdminCmd("sm_aia2", Command_SetAIATimed, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time - Usage: sm_aia2 \"target\" \"time(in seconds)\"");
	RegAdminCmd("sm_advanced_infinite_ammo", Command_SetAIA, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) - Usage: sm_advanced_infinite_ammo \"target\" \"1/0\"");
	RegAdminCmd("sm_advanced_infinite_ammo_timed", Command_SetAIATimed, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time - Usage: sm_advanced_infinite_ammo_timed \"target\" \"time(in seconds)\"");

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("mvm_begin_wave", Event_MVMWaveStart);

	if(g_bLateLoad)
	{
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsValidClient(client, false)) 
			{
				SDKHook(client, SDKHook_PreThink, SDKHooks_OnPreThink);
				SDKHook(client, SDKHook_WeaponEquipPost, SDKHooks_OnWeaponEquipPost);
				SDKHook(client, SDKHook_OnTakeDamage, SDKHooks_OnTakeDamage);
				if(IsPlayerAlive(client))
				{
					g_iClientWeapons[client][0] = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
					g_iClientWeapons[client][1] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					g_iClientWeapons[client][2] = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				}
			}
		}
	}
}

public OnConfigsExecuted()
{
	if(g_bLateLoad && GetConVarBool(g_hAllInfiniteAmmo))
	{
		new iAdminOnly = GetConVarInt(g_hAdminOnly);
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsValidClient(client, false))
			{
				switch(iAdminOnly)
				{
					case 1,2:
					{
						if(CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC)) g_bInfiniteAmmo[client] = true;
						else g_bInfiniteAmmo[client] = false;
					}
					default:
					{
						g_bInfiniteAmmo[client] = true;
					}
				}
			}
		}
		if(iAdminOnly == 1 || iAdminOnly == 2) PrintToChatAll("[SM] Advanced Infinite Ammo for admins enabled");
		else PrintToChatAll("[SM] Advanced Infinite Ammo for everyone enabled");
	}
}

public OnPluginEnd()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			ResetAmmo(client);
		}
	}
}

////////////////
//Cvar Changes//
////////////////

public CvarChange_AllInfiniteAmmo(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	new iNewValue = StringToInt(strNewValue);

	if(iNewValue)
	{
		new iAdminOnly = GetConVarInt(g_hAdminOnly);
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsValidClient(client, false))
			{
				switch(iAdminOnly)
				{
					case 1,2:
					{
						if(CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC)) g_bInfiniteAmmo[client] = true;
						else g_bInfiniteAmmo[client] = false;						
					}
					default:
					{
						g_bInfiniteAmmo[client] = true;						
					}
				}
			}
		}
		if(iAdminOnly == 1 || iAdminOnly == 2) PrintToChatAll("[SM] Advanced Infinite Ammo for admins enabled");
		else PrintToChatAll("[SM] Advanced Infinite Ammo for everyone enabled");
	}
	else
	{
		for(new client = 1; client <= MaxClients; client++)

		{
			g_bInfiniteAmmo[client] = false;
			ResetAmmo(client);
			
		}
		PrintToChatAll("[SM] Advanced Infinite Ammo for everyone disabled");
	}
}

public CvarChange_AdminOnly(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	new iNewValue = StringToInt(strNewValue);

	if(!iNewValue)
	{
		if(GetConVarBool(g_hAllInfiniteAmmo))
		{
			for(new client = 1; client <= MaxClients; client++)

			{
				g_bInfiniteAmmo[client] = true;
			}
		}
	}
	else
	{
		if(GetConVarBool(g_hAllInfiniteAmmo))
		{
			for(new client = 1; client <= MaxClients; client++)
			{
				if(!CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC)) g_bInfiniteAmmo[client] = false;
				ResetAmmo(client);
			}
		}
	}
}

public CvarChange_Bots(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	new iNewValue = StringToInt(strNewValue);

	if(iNewValue)
	{
		for(new client = 1; client <= MaxClients; client++)

		{
			if(IsClientInGame(client) && IsFakeClient(client) && GetConVarBool(g_hAllInfiniteAmmo)) g_bInfiniteAmmo[client] = true;
		}
	}
	else
	{
		for(new client = 1; client <= MaxClients; client++)

		{
			if(IsClientInGame(client) && IsFakeClient(client))
			{
				g_bInfiniteAmmo[client] = false;
				if(IsPlayerAlive(client))
				{
					SetRevengeCrits(client, 1);
					SetDecapitations(client, 0);
					new iClientHealth = GetClientHealth(client);
					TF2_RegeneratePlayer(client);
					SetEntityHealth(client, iClientHealth);
				}			
			}
		}
	}
}

public CvarChange_AmmoOnly(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	for(new client = 1; client <= MaxClients; client++)
	{
		ResetAmmo(client);
	}
}

public CvarChange_ExtraStuff(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	for(new client = 1; client <= MaxClients; client++)
	{
		ResetAmmo(client);
	}
}

////////////
//Commands//
////////////

public Action:Command_SetAIA(client, args)
{
	if (g_bNativeControl)
	{
		ReplyToCommand(client, "[SM] You do not have access to Infinite Ammo");
		return Plugin_Handled;
	}

	switch(args)
	{
		case 0:
		{
			if(g_bInfiniteAmmo[client])
			{
				g_bInfiniteAmmo[client] = false;
				ResetAmmo(client);
				if(GetConVarBool(g_hLog)) LogAction(client, client, "\"%L\" Disabled Advanced Infinite Ammo for  \"%L\"", client, client);		
				if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo for %N disabled", client);
				
			}
			else
			{
				g_bInfiniteAmmo[client] = true;
				if(GetConVarBool(g_hLog)) LogAction(client, client, "\"%L\" Enabled Advanced Infinite Ammo for  \"%L\"", client, client);
				if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo for %N enabled", client);
			}			
		}
		case 2:
		{
			new String:strTarget[MAX_TARGET_LENGTH], String:strOnOff[2], bool:bOnOff, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
			GetCmdArg(1, strTarget, sizeof(strTarget));
			if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			if((target_count > 1 || target_list[0] != client) && !CheckCommandAccess(client, "sm_aia_targetflag", ADMFLAG_SLAY))
			{
				ReplyToCommand(client, "[SM] You do not have access to targeting others");
				return Plugin_Handled;
			}

			GetCmdArg(2, strOnOff, sizeof(strOnOff));
			bOnOff = bool:StringToInt(strOnOff);
			new bool:bLogging = GetConVarBool(g_hLog);
			if(bOnOff)
			{
				for(new i = 0; i < target_count; i++)
				{
					g_bInfiniteAmmo[target_list[i]] = true;
					if(bLogging) LogAction(client, target_list[i], "\"%L\" enabled Advanced Infinite Ammo for  \"%L\"", client, target_list[i]);
				}
				if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo for %s enabled", target_name);
			}
			else 
			{
				for(new i = 0; i < target_count; i++)
				{
					g_bInfiniteAmmo[target_list[i]] = false;
					ResetAmmo(target_list[i]);
					if(bLogging) LogAction(client, target_list[i], "\"%L\" disabled Advanced Infinite Ammo for  \"%L\"", client, target_list[i]);
				}
				if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo for %s disabled", target_name);				
			}
		}
		default:
		{
			ReplyToCommand(client, "[SM] Usage: sm_aia \"target\" \"1/0\"");
		}
	}

	return Plugin_Handled;
}

public Action:Command_SetAIATimed(client, args)
{
	if (g_bNativeControl)
	{
		ReplyToCommand(client, "[SM] You do not have access to Infinite Ammo");
		return Plugin_Handled;
	}

	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_aia2 \"target\" \"time(in seconds)\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:strTime[8], Float:time, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if((target_count > 1 || target_list[0] != client) && !CheckCommandAccess(client, "sm_aia_targetflag", ADMFLAG_SLAY))
	{
		ReplyToCommand(client, "[SM] You do not have access to targeting others");
		return Plugin_Handled;
	}

	GetCmdArg(2, strTime, sizeof(strTime));
	time = StringToFloat(strTime);

	new bool:bLogging = GetConVarBool(g_hLog);
	for(new i=0;i<target_count;i++)
	{
		g_bInfiniteAmmo[target_list[i]] = true;
		CreateTimer(time, Timer_RemoveAIA, target_list[i], TIMER_FLAG_NO_MAPCHANGE);
		if(bLogging) LogAction(client, target_list[i], "\"%L\" Advanced Infinite Ammo enabled for \"%L\" for %f Seconds", client, target_list[i], time); 
	}
	if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo enabled for %s for %-.2f seconds", target_name, time);

	return Plugin_Handled;	
}

public Action:Timer_RemoveAIA(Handle:timer, any:client)
{
	g_bInfiniteAmmo[client] = false;
	ResetAmmo(client);
}

//////////
//Events//
//////////

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(g_bInfiniteAmmoToggle && !g_bWaitingForPlayers)
	{
		g_bInfiniteAmmoToggle = false;
		if(GetConVarBool(g_hChat)) PrintToChatAll("[SM] Round Start - Advanced Infinite Ammo disabled");
	}
}

public Event_MVMWaveStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(g_bInfiniteAmmoToggle && !g_bWaitingForPlayers)
	{
		g_bInfiniteAmmoToggle = false;
		if(GetConVarBool(g_hChat)) PrintToChatAll("[SM] Round Start - Advanced Infinite Ammo disabled");
		for(new client = 1; client <= MaxClients; client++)
		{
			ResetAmmo(client);
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_hAllInfiniteAmmo) && GetConVarBool(g_hRoundWin))
	{
		g_bInfiniteAmmoToggle = true;	
		if(GetConVarBool(g_hChat)) PrintToChatAll("[SM] Round Win - Advanced Infinite Ammo enabled");
	}
}

public Event_ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(g_bInfiniteAmmoToggle && !g_bWaitingForPlayers)
	{
		g_bInfiniteAmmoToggle = false;
		if(GetConVarBool(g_hChat)) PrintToChatAll("[SM] Round Start - Advanced Infinite Ammo disabled");
	}
}

////////////
//Forwards//
////////////

public OnClientPutInServer(client)
{
	if(IsValidClient(client, false)) 
	{
		SDKHook(client, SDKHook_PreThink, SDKHooks_OnPreThink);
		SDKHook(client, SDKHook_WeaponEquipPost, SDKHooks_OnWeaponEquipPost);
		SDKHook(client, SDKHook_OnTakeDamage, SDKHooks_OnTakeDamage);
	}

	if(GetConVarBool(g_hAllInfiniteAmmo))
	{
		switch(GetConVarInt(g_hAdminOnly))
		{
			case 1,2:
			{
				if(CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC)) g_bInfiniteAmmo[client] = true;
				else g_bInfiniteAmmo[client] = false;
			}
			default:
			{
				 g_bInfiniteAmmo[client] = true;
			}
		}
	}
	else g_bInfiniteAmmo[client] = false;
}

public TF2_OnWaitingForPlayersStart()
{
	g_bWaitingForPlayers = true;
	if(!GetConVarBool(g_hAllInfiniteAmmo) && GetConVarBool(g_hWaitingForPlayers))
	{
		g_bInfiniteAmmoToggle = true;
		if(GetConVarBool(g_hChat)) PrintToChatAll("[SM] Waiting For Players Started - Advanced Infinite Ammo enabled");
	}	
}

public TF2_OnWaitingForPlayersEnd()
{
	g_bWaitingForPlayers = false;
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(GetConVarBool(g_hExtraStuff) && condition == TFCond_Charging && CheckInfiniteAmmoAccess(client))
	{
		SetChargeMeter(client);
	}
}


///////////////////
//Main Ammo Stuff//
///////////////////

public SDKHooks_OnWeaponEquipPost(client, weapon)
{
	if(IsValidClient(client))
	{
		g_iClientWeapons[client][0] = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		g_iClientWeapons[client][1] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		g_iClientWeapons[client][2] = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	}
}

public SDKHooks_OnPreThink(client)
{
	if(IsValidClient(client) && CheckInfiniteAmmoAccess(client))
	{
		if(IsValidWeapon(g_iClientWeapons[client][0])) GiveInfiniteAmmo(client, g_iClientWeapons[client][0]);
		if(IsValidWeapon(g_iClientWeapons[client][1])) GiveInfiniteAmmo(client, g_iClientWeapons[client][1]);
		if(IsValidWeapon(g_iClientWeapons[client][2])) GiveInfiniteAmmo(client, g_iClientWeapons[client][2]);

		
		SetSentryAmmo(client);
		SetMetal(client);
		SetCloak(client);
	}
}

public Action:SDKHooks_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
 Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(IsValidClient(victim) && damagecustom == TF_CUSTOM_BACKSTAB && CheckInfiniteAmmoAccess(victim) && HasRazorback(victim))
	{
		return Plugin_Handled;	
	}
	return Plugin_Continue;
}

bool:CheckInfiniteAmmoAccess(client)
{
	switch(GetConVarInt(g_hAdminOnly))
	{
		case 1:
		{
			if(CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC) && (g_bInfiniteAmmo[client] || g_bInfiniteAmmoToggle)) return true;
		}
		case 2:
		{
			if(g_bInfiniteAmmo[client] || (CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC) && g_bInfiniteAmmoToggle)) return true;
		}
		default:
		{
			if(g_bInfiniteAmmo[client] || g_bInfiniteAmmoToggle) return true;
		}
	}
	return false;
}

GiveInfiniteAmmo(client, iWeapon)
{
	new bool:bSetClip = !GetConVarBool(g_hAmmoOnly);
	new bool:bExtraStuff = GetConVarBool(g_hExtraStuff);
	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Melee Weapons or exceptions - Do nothing
		case 0,1,2,3,4,5,6,7,8,25,26,27,28,30,37,38,43,59,60,128,131,133,140,
			142,153,154,155.169,171,172,173,190,191,192,193,194,195,196,
			197,198,212,214,221,225,232,239,264,297,304,310,317,325,326,
			327,329,331,348,349,355,356,357,401,404,413,416,423,426,447,
			450,452,457,461,466,474,527,528,572,574,587,589,593,609,638,
			656,660,662,665,727,737,739,775,794,795,803,804,813,834,880,
			883,884,892,893,901,902,910,911,939,954,959,960,968,969,999,
			1000,1003,1013: {}

		//Type 1 Weapons - Only Clip
		case 9,10,11,12,13,16,17,18,19,20,22,23,24,36,45,61,127,130,160,161,
			199,200,203,204,205,206,207,209,210,220,222,224,228,237,265,
			294,305,308,412,414,415,425,449,460,513,658,661,669,773,797,
			800,806,808,809,886,888,889,895,897,898,904,906,907,913,915,
			916,962,964,965,971,973,974,996,997,1006,1007:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(client, iWeapon);
		}

		//Type 2 Weapons - Only Ammo
		case 21,39,40,42,56,58,159,208,215,311,351,433,659,740,741,798,799,
			807,812,833,851,863,887,896,905,914,963,972,1002,1005:
		{
			SetAmmo(client, iWeapon);
		}

		//Sniper Rifle - Ammo and Charge
		case 14,201,230,526,664,792,801,881,890,899,908,957,966:
		{
			SetAmmo(client, iWeapon);
			if(bExtraStuff && TF2_IsPlayerInCondition(client, TFCond_Zoomed)) SetSniperRifleCharge(iWeapon);
		}

		//Miniguns - Ammo and Rage(MvM)
		case 15,41,202,298,312,424,654,793,802,811,832,850,882,891,900,909,958,967:
		{
			SetAmmo(client, iWeapon);
			if(bExtraStuff && !GetRageMeter(client)) SetRageMeter(client);
		}

		//Medigun(Normal, Upgradeable, Festive, Botkiller,Vaccinator), Kritzkrieg, Quick-Fix - Ubercharge Meter
		case 29,35,211,411,663,796,805,885,894,903,912,961,970,998: 
		{
			if(bExtraStuff && !GetUberCharge(iWeapon)) SetUberCharge(iWeapon);
		}
		
		
		//Sandman, Wrap Assassin - Ammo
		case 44, 648:
		{
			//Admin Check(Old Plugin Behavior)
			//if(!CheckCommandAccess(client, "sm_fia_adminflag", ADMFLAG_GENERIC)) return;
			SetAmmo(client, iWeapon);
		}

		//Bonk!, CritACola - Ammo
		case 46,163:
		{
			if(bExtraStuff)
			{
				SetAmmo(client, iWeapon);
				SetDrinkMeter(client);
				if(GetClientButtons(client) & IN_ATTACK2) TF2_RemoveCondition(client, TFCond_Bonked);
			}
		}

		//Buff Banner, Battalion's Backup, Concheror
		case 129,226,354,1001: 
		{
			if(bExtraStuff && !GetRageMeter(client)) SetRageMeter(client);
		}

		//Eyelander, HHHH, Nine Iron - Decapitations
		case 132,266,482:
		{
			if(bExtraStuff) SetDecapitations(client);
		}

		//Frontier Justice, Diamondback - Clip and Revenge Crits
		case 141,525,1004:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(client, iWeapon);
			if(bExtraStuff) SetRevengeCrits(client);	
		}

		//Ullapool Caber - Detonation Reset
		case 307:
		{
			if(bExtraStuff) ResetCaber(iWeapon);					
		}

		//Bazaar Bargain - Ammo and Decapitations
		case 402:
		{
			SetAmmo(client, iWeapon);
			if(bExtraStuff)
			{
				SetDecapitations(client);
				if(TF2_IsPlayerInCondition(client, TFCond_Zoomed)) SetSniperRifleCharge(iWeapon);
			} 
		}

		//Cow Mangler, Bison, Pomson - Energy Ammo
		case 441,442,588:
		{
			if(bSetClip) SetEnergyAmmo(iWeapon);
		}

		//Soda Popper and Baby Face's Blaster - Clip and Hype Meter
		case 448,772:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(client, iWeapon);
			if(bExtraStuff) SetHypeMeter(client);
		}

		//Phlogistinator- Ammo and Rage
		case 594: 
		{
			SetAmmo(client, iWeapon);
			if(bExtraStuff && !GetRageMeter(client)) SetRageMeter(client);
		}

		//Manmelter - Only Revenge Crits
		case 595:
		{
			if(bExtraStuff) SetRevengeCrits(client);
		}

		//Spycicle - Recharge Time
		case 649:
		{
			if(bExtraStuff) SetEntPropFloat(iWeapon, Prop_Send, "m_flKnifeRegenerateDuration", 0.0);
		}

		//Beggar's Bazooka - Clip while holing attack and Ammo
		case 730:
		{
			if(bSetClip && bExtraStuff) if(GetClientButtons(client) & IN_ATTACK2) SetClip(iWeapon, 3);
			SetAmmo(client, iWeapon);
		}

		//Sappers - Instant recharge(MvM)
		case 735,736,810,831,933:
		{
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEffectBarRegenTime", 0.1);
		}

		//Cleaner's Carbine - Clip and Crits
		case 751:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(client, iWeapon);
			if(bExtraStuff) TF2_AddCondition(client, TFCond_CritOnKill, 3.0);			
		}
		//Hitman's Heatmaker - Ammo, Charge, and Rage
		case 752: 
		{
			SetAmmo(client, iWeapon);
			if(bExtraStuff)
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Zoomed)) SetSniperRifleCharge(iWeapon);
				if(!GetRageMeter(client)) SetRageMeter(client);
			}
		}

		//Everything Else(Usually new weapons added to TF2 since last plugin update)
		default:
		{
			if(bSetClip) SetClip(iWeapon);
			SetAmmo(client, iWeapon);
		}
	}
	
}

ResetAmmo(client)
{
	if(IsValidClient(client))
	{		
		SetRevengeCrits(client, 1);
		SetDecapitations(client, 0);
		new iClientHealth = GetClientHealth(client);
		TF2_RegeneratePlayer(client);
		SetEntityHealth(client, iClientHealth);
	}
}

//////////
//Stocks//
//////////

stock bool:IsValidClient(client, bool:bCheckAlive=true)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	if(!GetConVarBool(g_hBots) && IsFakeClient(client)) return false;
	if(bCheckAlive) return IsPlayerAlive(client);
	return true;
}

stock bool:IsValidWeapon(iEntity)
{
	decl String:strClassname[128];
	if(IsValidEntity(iEntity) && GetEntityClassname(iEntity, strClassname, sizeof(strClassname)) && StrContains(strClassname, "tf_weapon", false) != -1) return true;
	return false;
}

stock SetAmmo(client, iWeapon, iAmmo = 999)
{
	new iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if(iAmmoType != -1) SetEntProp(client, Prop_Data, "m_iAmmo", iAmmo, _, iAmmoType);
}

stock SetEnergyAmmo(iWeapon, Float:flEnergyAmmo = 100.0)
{
	SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", flEnergyAmmo);
}

stock SetClip(iWeapon, iClip = 99)
{
	SetEntProp(iWeapon, Prop_Data, "m_iClip1", iClip);

}

stock SetDrinkMeter(client, Float:flDrinkMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", flDrinkMeter);
}

stock SetHypeMeter(client, Float:flHypeMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", flHypeMeter);
}

stock Float:GetRageMeter(client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
}

stock SetRageMeter(client, Float:flRage = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRage);
}

stock Float:GetUberCharge(iWeapon)
{
	return GetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel");
}
stock SetUberCharge(iWeapon, Float:flUberCharge = 1.00)
{
	SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", flUberCharge);
}

stock SetChargeMeter(client, Float:flChargeMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", flChargeMeter);
}

stock SetSniperRifleCharge(iWeapon, Float:flCharge = 150.0)
{
	SetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage", flCharge);
}

stock SetRevengeCrits(client, iAmount = 99)
{
	SetEntProp(client, Prop_Send, "m_iRevengeCrits", iAmount);
}

stock SetDecapitations(client, iAmount = 99)
{
	SetEntProp(client, Prop_Send, "m_iDecapitations", iAmount);
}

stock ResetCaber(iWeapon)
{
	SetEntProp(iWeapon, Prop_Send, "m_bBroken", 0);

	SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
}

stock SetSentryAmmo(client, iLevel1Ammo = 150, iLevel2Ammo = 200, iLevel3Ammo = 200, iLevel3Rockets = 20)
{
	new iSentrygun = -1; 
	while((iSentrygun = FindEntityByClassname(iSentrygun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(iSentrygun) && GetEntPropEnt(iSentrygun, Prop_Send, "m_hBuilder") == client)
		{
			switch (GetEntProp(iSentrygun, Prop_Send, "m_iUpgradeLevel"))
			{
				case 1:
				{
					SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", iLevel1Ammo);
				}
				case 2:
				{
					SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", iLevel2Ammo);
				}
				case 3:
				{
					SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", iLevel3Ammo);
					SetEntProp(iSentrygun, Prop_Send, "m_iAmmoRockets", iLevel3Rockets);
				}
			}
		}
	}
}

stock SetMetal(client, iMetal = 200)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", iMetal, 4, 3);
}

stock SetCloak(client, Float:flCloak = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", flCloak);	
}

stock bool:HasRazorback(client)
{
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_wearable")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 57 && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			return true;
		}
	}
	return false;
}


///////////
//Natives//
///////////

public Native_ControlInfiniteAmmo(Handle:plugin, numParams)
{
    g_bNativeControl = GetNativeCell(1);
}

public Native_SetInfiniteAmmo(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new bool:enabled = bool:GetNativeCell(2);
    new Float:time = Float:GetNativeCell(3);

    g_bInfiniteAmmo[client] = enabled;

    if (!enabled)
        ResetAmmo(client);
    else if (time > 0.0)
        CreateTimer(time, Timer_RemoveAIA, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Native_FillWeaponAmmo(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new weapon = GetNativeCell(2);

    if (IsValidWeapon(weapon))
    {
        GiveInfiniteAmmo(client, weapon);
        return true;
    }
    else
        return false;
}

public Native_FillAmmo(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new slot   = GetNativeCell(2);

    if (slot < 0)
    {
        new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (IsValidWeapon(weapon))
        {
            GiveInfiniteAmmo(client, weapon);
            return true;
        }
    }
    else if (slot < sizeof(g_iClientWeapons) &&
             IsValidWeapon(g_iClientWeapons[client][slot]))
    {
        GiveInfiniteAmmo(client, g_iClientWeapons[client][slot]);
        return true;
    }

    return false;
}
