#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define cDefault    0x01
#define cLightGreen 0x03
#define cGreen      0x04
#define cDarkGreen  0x05

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new maxclients;
new maxents;
new ownerOffset;

// Functions
public Plugin:myinfo =
{
	name = "Destroy Engineer Buildings",
	author = "bl4nk",
	description = "Destroy an engineer's buildings",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("destroy.phrases");

	CreateConVar("sm_destroyengybuildings_version", PLUGIN_VERSION, "Destroy Engineer Buildings Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_destroy", Command_Destroy, ADMFLAG_SLAY, "sm_destroy <name/@all/@red/@blu> [sentry/dispenser/entrance/exit/all]");

	ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	if (ownerOffset == -1)
		SetFailState("Could not find offset");

	maxclients = GetMaxClients();
	maxents = GetMaxEntities();
}

public Action:Command_Destroy(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_destroy <name/@all/@red/@blu> [sentry/dispenser/entrance/exit/all]");
		return Plugin_Handled;
	}

	decl String:text[256], String:arg[64];
	GetCmdArg(1, text, sizeof(text));
	GetCmdArg(2, arg, sizeof(arg));

	if (strcmp(arg, "\0") == 0)
		Format(arg, sizeof(arg), "all");

	if (strncmp(text, "@", 1) == 0)
	{
		if (strcmp(text[1], "all") == 0)
		{
			for (new i = 1; i <= maxclients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Engineer)
				{
					if (!DestroyBuildingByName(i, arg))
					{
						ReplyToCommand(client, "[SM] %T", "Destroy_Invalid");
						break;
					}
				}
			}
		}
		else if (strcmp(text[1], "red") == 0)
		{
			for (new i = 1; i <= maxclients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Engineer && GetClientTeam(i) == 2)
				{
					if (!DestroyBuildingByName(i, arg))
					{
						ReplyToCommand(client, "[SM] %T", "Destroy_Invalid");
						break;
					}
				}
			}
		}
		else if (strcmp(text[1], "blu") == 0)
		{
			for (new i = 1; i <= maxclients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Engineer && GetClientTeam(i) == 3)
				{
					if (!DestroyBuildingByName(i, arg))
					{
						ReplyToCommand(client, "[SM] %T", "Destroy_Invalid");
						break;
					}
				}
			}
		}
	}
	else
	{
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
				text,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_NO_MULTI,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		if (!DestroyBuildingByName(target_list[0], arg))
			ReplyToCommand(client, "[SM] %T", "Destroy_Invalid");
	}

	return Plugin_Handled;
}

stock bool:DestroyBuildingByName(client, const String:name[])
{
	if (strcmp(name, "sentry") == 0)
	{
		new bool:destroyed = false;
		for (new i = maxclients + 1; i <= maxents; i++)
		{
			if (!IsValidEntity(i))
				continue;

			decl String:netclass[32];
			GetEntityNetClass(i, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0)
			{
				if (GetEntDataEnt2(i, ownerOffset) == client)
				{
					SetVariantInt(9999);
					AcceptEntityInput(i, "RemoveHealth");
					destroyed = true;
				}
			}
		}

		if (destroyed)
			PrintToChat(client, "%c[SM]%c %T", cGreen, cDefault, "Destroy_Sentry", LANG_SERVER, cLightGreen, cDefault);

		return true;
	}
	else if (strcmp(name, "dispenser") == 0)
	{
		new bool:destroyed = false;
		for (new i = maxclients + 1; i <= maxents; i++)
		{
			if (!IsValidEntity(i))
				continue;

			decl String:netclass[32];
			GetEntityNetClass(i, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectDispenser") == 0)
			{
				if (GetEntDataEnt2(i, ownerOffset) == client)
				{
					SetVariantInt(9999);
					AcceptEntityInput(i, "RemoveHealth");
					destroyed = true;
				}
			}
		}

		if (destroyed)
			PrintToChat(client, "%c[SM]%c %T", cGreen, cDefault, "Destroy_Dispenser", LANG_SERVER, cLightGreen, cDefault);

		return true;
	}
	else if (strcmp(name, "entrance") == 0)
	{
		new bool:destroyed = false;
		for (new i = maxclients + 1; i <= maxents; i++)
		{
			if (!IsValidEntity(i))
				continue;

			decl String:netclass[32];
			GetEntityNetClass(i, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectTeleporter") == 0)
			{
				decl String:classname[32];
				GetEdictClassname(i, classname, sizeof(classname));

				if (strcmp(classname, "obj_teleporter_entrance") == 0)
				{
					if (GetEntDataEnt2(i, ownerOffset) == client)
					{
						SetVariantInt(9999);
						AcceptEntityInput(i, "RemoveHealth");
						destroyed = true;
					}
				}
			}
		}

		if (destroyed)
			PrintToChat(client, "%c[SM]%c %T", cGreen, cDefault, "Destroy_Entrance", LANG_SERVER, cLightGreen, cDefault);

		return true;
	}
	else if (strcmp(name, "exit") == 0)
	{
		new bool:destroyed = false;
		for (new i = maxclients + 1; i <= maxents; i++)
		{
			if (!IsValidEntity(i))
				continue;

			decl String:netclass[32];
			GetEntityNetClass(i, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectTeleporter") == 0)
			{
				decl String:classname[32];
				GetEdictClassname(i, classname, sizeof(classname));

				if (strcmp(classname, "obj_teleporter_exit") == 0)
				{
					if (GetEntDataEnt2(i, ownerOffset) == client)
					{
						SetVariantInt(9999);
						AcceptEntityInput(i, "RemoveHealth");
						destroyed = true;
					}
				}
			}
		}

		if (destroyed)
			PrintToChat(client, "%c[SM]%c %T", cGreen, cDefault, "Destroy_Exit", LANG_SERVER, cLightGreen, cDefault);

		return true;
	}
	else if (strcmp(name, "all") == 0)
	{
		new bool:destroyed = false;
		for (new i = maxclients + 1; i <= maxents; i++)
		{
			if (!IsValidEntity(i))
				continue;

			decl String:netclass[32];
			GetEntityNetClass(i, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
			{
				if (GetEntDataEnt2(i, ownerOffset) == client)
				{
					SetVariantInt(9999);
					AcceptEntityInput(i, "RemoveHealth");
					destroyed = true;
				}
			}
		}

		if (destroyed)
			PrintToChat(client, "%c[SM]%c %T", cGreen, cDefault, "Destroy_All", LANG_SERVER, cLightGreen, cDefault);

		return true;
	}

	return false;
}