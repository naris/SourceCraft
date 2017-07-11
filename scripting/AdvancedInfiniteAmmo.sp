#pragma semicolon 1

#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1.2"


public Plugin:myinfo =
{
	name = "Advanced Infinite Ammo",
	author = "Tylerst",
	description = "Infinite usage for just about everything",
	version = PLUGIN_VERSION,
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
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

public OnPluginStart()
{
	CreateConVar("sm_aia_version", PLUGIN_VERSION, "Advanced Infinite Ammo", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");

	g_hAllInfiniteAmmo = CreateConVar("sm_aia_all", "0", "Advanced Infinite Ammo for everyone");
	g_hAdminOnly = CreateConVar("sm_aia_adminonly", "0", "Advanced Infinite Ammo will work for admins only");
	g_hBots = CreateConVar("sm_aia_bots", "1", "Advanced Infinite Ammo will work for bots");
	g_hRoundWin = CreateConVar("sm_aia_roundwin", "1", "Advanced Infinite Ammo for everyone on round win");
	g_hWaitingForPlayers = CreateConVar("sm_aia_waitingforplayers", "1", "Advanced Infinite Ammo for everyone during waiting for players phase");
	g_hChat = CreateConVar("sm_aia_chat", "1", "Show Advanced Infinite Ammo changes in chat");
	g_hLog = CreateConVar("sm_aia_log", "1", "Log Advanced Infinite Ammo commands");

	HookConVarChange(g_hAllInfiniteAmmo, CvarChange_AllInfiniteAmmo);
	HookConVarChange(g_hAdminOnly, CvarChange_AdminOnly);
	HookConVarChange(g_hBots, CvarChange_Bots);

	RegAdminCmd("sm_aia", Command_SetAIA, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) - Usage: sm_aia \"target\" \"1/0\"");
	RegAdminCmd("sm_aia2", Command_SetAIATimed, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time - Usage: sm_aia2 \"target\" \"time(in seconds)\"");
	RegAdminCmd("sm_advanced_infinite_ammo", Command_SetAIA, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) - Usage: sm_advanced_infinite_ammo \"target\" \"1/0\"");
	RegAdminCmd("sm_advanced_infinite_ammo_timed", Command_SetAIATimed, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time - Usage: sm_advanced_infinite_ammo_timed \"target\" \"time(in seconds)\"");

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("mvm_begin_wave", Event_MVMWaveStart);


	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client, false))
		{
			SDKHook(client, SDKHook_PreThink, SDKHook_OnPreThink);
			SDKHook(client, SDKHook_WeaponEquipPost, SDKHook_OnWeaponEquipPost);
		}
	}
}

public CvarChange_AllInfiniteAmmo(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	new iOldValue = StringToInt(strOldValue);
	new iNewValue = StringToInt(strNewValue);

	if(iNewValue && !iOldValue)
	{
		if(GetConVarBool(g_hChat))
		{
			if(GetConVarBool(g_hAdminOnly)) PrintToChatAll("[SM] Advanced Infinite Ammo for admins enabled");
			else PrintToChatAll("[SM] Advanced Infinite Ammo For Everyone Enabled");
		}
		for(new client = 1; client <= MaxClients; client++)

		{
			g_bInfiniteAmmo[client] = true;
		}
	}
	if(!iNewValue && iOldValue)
	{
		if(GetConVarBool(g_hChat)) PrintToChatAll("[SM] Advanced Infinite Ammo for everyone disabled");
		for(new client = 1; client <= MaxClients; client++)

		{
			g_bInfiniteAmmo[client] = false;
			ResetAmmo(client);
		}
	}
}

public CvarChange_AdminOnly(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	new iOldValue = StringToInt(strOldValue);
	new iNewValue = StringToInt(strNewValue);

	if(iNewValue && !iOldValue)
	{
		for(new client = 1; client <= MaxClients; client++)

		{
			ResetAmmo(client);
		}
	}
}


public CvarChange_Bots(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	new iOldValue = StringToInt(strOldValue);
	new iNewValue = StringToInt(strNewValue);

	if(iNewValue && !iOldValue)
	{
		for(new client = 1; client <= MaxClients; client++)

		{
			ResetAmmo(client);
		}
	}
}

public OnClientPutInServer(client)
{
	GetConVarBool(g_hAllInfiniteAmmo) ? (g_bInfiniteAmmo[client] = true) : (g_bInfiniteAmmo[client] = false);
	if(IsValidClient(client, false))
	{
		SDKHook(client, SDKHook_PreThink, SDKHook_OnPreThink);
		SDKHook(client, SDKHook_WeaponEquipPost, SDKHook_OnWeaponEquipPost);
	}
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

public Action:Command_SetAIA(client, args)
{
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
			if(bOnOff)
			{
				for(new i = 0; i < target_count; i++)
				{
					g_bInfiniteAmmo[target_list[i]] = true;
					if(GetConVarBool(g_hLog)) LogAction(client, target_list[i], "\"%L\" enabled Advanced Infinite Ammo for  \"%L\"", client, target_list[i]);
				}
				if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo for %s enabled", target_name);
			}
			else
			{
				for(new i = 0; i < target_count; i++)
				{
					g_bInfiniteAmmo[target_list[i]] = false;
					ResetAmmo(target_list[i]);
					if(GetConVarBool(g_hLog)) LogAction(client, target_list[i], "\"%L\" disabled Advanced Infinite Ammo for  \"%L\"", client, target_list[i]);
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

	for(new i=0;i<target_count;i++)
	{
		g_bInfiniteAmmo[target_list[i]] = true;
		CreateTimer(time, Timer_RemoveAIA, target_list[i], TIMER_FLAG_NO_MAPCHANGE);
		if(GetConVarBool(g_hLog)) LogAction(client, target_list[i], "\"%L\" Advanced Infinite Ammo enabled for \"%L\" for %f Seconds", client, target_list[i], time);
	}
	if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo enabled for %s for %-.2f seconds", target_name, time);

	return Plugin_Handled;
}

public Action:Timer_RemoveAIA(Handle:timer, any:client)
{
	g_bInfiniteAmmo[client] = false;
	ResetAmmo(client);
}

public SDKHook_OnWeaponEquipPost(client, weapon)
{
	if(IsValidClient(client))
	{
		g_iClientWeapons[client][0] = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		g_iClientWeapons[client][1] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		g_iClientWeapons[client][2] = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	}
}

public SDKHook_OnPreThink(client)
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

bool:CheckInfiniteAmmoAccess(client)
{
	if(GetConVarBool(g_hAdminOnly) && !CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC)) return false;
	if(g_bInfiniteAmmo[client] || g_bInfiniteAmmoToggle) return true;
	return false;
}

bool:IsValidClient(client, bool:bCheckAlive=true)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	if(!GetConVarBool(g_hBots) && IsFakeClient(client)) return false;
	if(bCheckAlive) return IsPlayerAlive(client);
	return true;
}

bool:IsValidWeapon(iEntity)
{
	decl String:strClassname[128];
	if(IsValidEntity(iEntity) && GetEntityClassname(iEntity, strClassname, sizeof(strClassname)) && StrContains(strClassname, "tf_weapon", false) != -1) return true;
	return false;
}

GiveInfiniteAmmo(client, iWeapon)
{
	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Melee Weapons or exceptions - Do nothing
		case 0,1,2,3,4,5,6,7,8,25,26,27,28,30,37,38,43,59,60,128,131,133,140,
			142,153,154,155.169,171,172,173,190,191,192,193,194,195,196,
			197,198,212,214,221,225,232,239,264,297,304,310,317,325,326,
			327,329,331,348,349,355,356,357,401,404,413,416,423,426,447,
			450,452,457,461,466,474,527,528,572,574,587,589,593,609,638,
			656,660,662,665,727,735,736,737,739,775,810,813,831,834: {}

		//Type 1 Weapons - Only Clip
		case 9,10,11,12,13,16,17,18,19,20,22,23,24,36,45,61,127,130,160,161,
			199,200,203,204,205,206,207,209,210,220,222,224,228,237,265,
			294,305,308,412,414,415,425,449,460,513,658,661,669,773:
		{
			SetClip(iWeapon);
		}

		//Type 2 Weapons - Only Ammo
		case 14,15,39,41,42,56,58,159,201,202,230,298,311,312,351,
			424,433,526,664,740,811,812,832,833:
		{
			SetAmmo(client, iWeapon);
		}

		//Flamethrower(Normal, Upgradeable, & Festive), Backburner, Degreaser - Ammo and Clip(AirBlast Ammo)
		case 21,40,208,215,659,741:
		{
			SetAmmo(client, iWeapon);
			SetClip(iWeapon);
		}

		//Medigun(Normal, Upgradeable, & Festive), Kritzkrieg, Quick-Fix - Ubercharge Meter
		case 29,35,211,411,663:
		{
			SetUberCharge(iWeapon);
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
			SetAmmo(client, iWeapon);
			SetDrinkMeter(client);
			if(GetClientButtons(client) & IN_ATTACK2) TF2_RemoveCondition(client, TFCond_Bonked);
		}

		//Buff Banner, Battalion's Backup, Concheror
		case 129,226,354:
		{
			SetRageMeter(client);
		}

		//Eyelander, HHHH, Nine Iron - Decapitations
		case 132,266,482:
		{
			SetDecapitations(client);
		}

		//Frontier Justice, Diamondback - Clip and Revenge Crits
		case 141,525:
		{
			SetClip(iWeapon);
			SetRevengeCrits(client);
		}

		//Ullapool Caber - Detonation Reset
		case 307:
		{
			ResetCaber(iWeapon);
		}

		//Bazaar Bargain - Ammo and Decapitations
		case 402:
		{
			SetAmmo(client, iWeapon);
			SetDecapitations(client);
		}

		//Cow Mangler, Bison, Pomson - Energy Ammo
		case 441,442,588:
		{
			SetEnergyAmmo(iWeapon);
		}

		//Soda Popper and Baby Face's Blaster - Clip and Hype Meter
		case 448,772:
		{
			SetClip(iWeapon);
			SetHypeMeter(client);
		}

		//Phlogistinator, Hitman's Heatmaker - Ammo and Rage
		case 594,752:
		{
			SetAmmo(client, iWeapon);
			SetRageMeter(client);
		}

		//Manmelter - Only Revenge Crits
		case 595:
		{
			SetRevengeCrits(client);
		}

		//Spycicle - Recharge Time
		case 649:
		{
			SetEntPropFloat(iWeapon, Prop_Send, "m_flKnifeRegenerateDuration", 0.0);
		}

		//Beggar's Bazooka - Clip while holing attack and Ammo
		case 730:
		{
			if(GetClientButtons(client) & IN_ATTACK2) SetClip(iWeapon, 3);
			SetAmmo(client, iWeapon);
		}

		//Cleaner's Carbine - Clip and Crits
		case 751:
		{
			SetClip(iWeapon);
			TF2_AddCondition(client, TFCond_CritOnKill, 3.0);
		}

		//Everything Else(Usually new weapons added to TF2 since last plugin update)
		default:
		{
			SetClip(iWeapon, 95);
			SetAmmo(client, iWeapon, 95);
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(CheckInfiniteAmmoAccess(client))
	{
		switch(condition)
		{
			case TFCond_Charging:
			{
				SetChargeMeter(client);
			}
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

stock SetRageMeter(client, Float:flRage = 100.0)
{
	if(!GetEntPropFloat(client, Prop_Send, "m_flRageMeter"))
	{

		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRage);
	}
}

stock SetUberCharge(iWeapon, Float:flUberCharge = 1.00)
{
	if(!GetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel"))
	{
		SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", flUberCharge);
	}
}

stock SetChargeMeter(client, Float:flChargeMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", flChargeMeter);
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

stock SetSentryAmmo(client, iLevel1 = 150, iLevel2 = 200, iLevel3 = 200, iLevel3Rockets = 20)
{
	new iSentrygun = -1;
	while ((iSentrygun = FindEntityByClassname(iSentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(iSentrygun))
		{
			if(GetEntPropEnt(iSentrygun, Prop_Send, "m_hBuilder") == client)
			{
				switch (GetEntProp(iSentrygun, Prop_Send, "m_iUpgradeLevel"))
				{
					case 1:
					{
						SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", iLevel1);
					}
					case 2:
					{
						SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", iLevel2);
					}
					case 3:
					{
						SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", iLevel3);
						SetEntProp(iSentrygun, Prop_Send, "m_iAmmoRockets", iLevel3Rockets);
					}
				}
			}
		}
	}
}

stock SetMetal(client, iMetal = 200)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", iMetal, _, 3);
}

stock SetCloak(client, Float:flCloak = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", flCloak);
}
