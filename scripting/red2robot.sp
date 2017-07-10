#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "[TF2] Red2Robot",
	author = "Bitl",
	description = "Change your team to robot!",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_bot", Command_Help, ADMFLAG_CHEATS);
	RegAdminCmd("sm_machine", Command_Robot_Me, ADMFLAG_CHEATS);
	RegAdminCmd("sm_mann", Command_Human_Me, ADMFLAG_CHEATS);
	RegAdminCmd("sm_giant", Command_Giant, ADMFLAG_CHEATS);
	RegAdminCmd("sm_small", Command_Small, ADMFLAG_CHEATS);
}

public Action:Command_Robot_Me(client, args)
{
	if (GetClientTeam(client) ==2)
	{
		SetEntProp(client, Prop_Send, "m_iTeamNum", 3)
		SetModel(client)
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You are already in the BLU/Robots team!");
	}	
}

public Action:Command_Human_Me(client, args)
{
	if (GetClientTeam(client) ==3)
	{
		SetEntProp(client, Prop_Send, "m_iTeamNum", 2)
		RemoveModel(client)
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You are already in the RED/Defenders team!");
	}
	
}

public Action:Command_Giant(client, args)
{
	if (GetClientTeam(client) ==3)
	{	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn giant.");
	}
}

public Action:Command_Small(client, args)
{
	if (GetClientTeam(client) ==3)
	{	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn small.");
	}
}

public OnClientDisconnect(client)
{
	RemoveModel(client);
}

public Action:Command_Help(client, args)
{
	ReplyToCommand(client, "[Red2Robot] !bot, !machine, !mann, !giant, !small");
}

stock bool:SetModel(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout");
		case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier");
		case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro");
		case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo");
		case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy");
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "");
	}
	if (!StrEqual(Mdl, ""))
	{
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
		PrecacheModel(Mdl);
	}
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	if (StrEqual(Mdl, "")) return false;
	return true;
}

stock bool:RemoveModel(client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
