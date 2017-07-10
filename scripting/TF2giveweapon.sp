/**
 * vim: set ai et ts=4 sw=4 :
 * File: TF2giveweapon.sp
 * Description: Give Named Weapons for TF2
 * Author(s): bl4nk
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2_weapon>

// Global Definitions
#define PLUGIN_VERSION "1.0.3"

new Handle:hKV = INVALID_HANDLE;

// Functions
public Plugin:myinfo =
{
	name = "GiveNamedItem",
	author = "bl4nk",
	description = "Give a specific weapon to a player",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_giveweapon", Command_GiveWeapon, ADMFLAG_CHEATS, "sm_giveweapon <name>");

	hKV = CreateKeyValues("TF2WeaponData");

	new String:file[128];
	BuildPath(Path_SM, file, sizeof(file), "data/tf2weapondata.txt");
	FileToKeyValues(hKV, file);
}

public Action:Command_GiveWeapon(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_giveweapon <#userid|name> <weapon>");
		return Plugin_Handled;
	}

	decl String:name[65];
	GetCmdArg(1, name, sizeof(name));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			name,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	decl String:weaponName[32];
	GetCmdArg(2, weaponName, sizeof(weaponName));

	if (!KvJumpToKey(hKV, weaponName))
	{
		ReplyToCommand(client, "[SM] Invalid weapon name.");
		return Plugin_Handled;
	}

	new weaponSlot = KvGetNum(hKV, "slot");
	//new weaponClip = KvGetNum(hKV, "clip");
	new weaponMax = KvGetNum(hKV, "max");

	KvRewind(hKV);

	for (new i = 0; i < target_count; i++)
	{
		new target = target_list[i];
		TF2_RemoveWeaponSlot(target, weaponSlot - 1);
		TF2_GivePlayerWeapon(target, weaponName);

		if (weaponMax != -1)
		{
			SetEntData(target, FindSendPropInfo("CTFPlayer", "m_iAmmo") + weaponSlot * 4, weaponMax);
			//SetEntData(GetPlayerWeaponSlot(target, weaponSlot - 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), weaponClip);
		}
	}

	return Plugin_Handled;
}
