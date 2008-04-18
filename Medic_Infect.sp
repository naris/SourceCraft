#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new ClientInfected[MAXPLAYERS];
new bool:ClientFriendlyInfected[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "Medic Infection",
	author = "Twilight Suzuka",
	description = "Allows medics to infect again",
	version = "Alpha:1",
	url = "http://www.sourcemod.net/"
};

new Handle:Cvar_DmgAmount = INVALID_HANDLE;
new Handle:Cvar_DmgTime = INVALID_HANDLE;

new Handle:Cvar_SpreadAll = INVALID_HANDLE;
new Handle:Cvar_SpreadSameTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadOpposingTeam = INVALID_HANDLE;

new Handle:Cvar_InfectSameTeam = INVALID_HANDLE;
new Handle:Cvar_InfectOpposingTeam = INVALID_HANDLE;

new Handle:CvarEnable = INVALID_HANDLE;
new Handle:CvarRed = INVALID_HANDLE;
new Handle:CvarBlue = INVALID_HANDLE;
new Handle:CvarGreen = INVALID_HANDLE;
new Handle:CvarTrans = INVALID_HANDLE;

public OnPluginStart()
{
	CvarEnable = CreateConVar("medic_infect_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CvarRed = CreateConVar("medic_infect_red", "200", "Amount of Red", FCVAR_NOTIFY);
	CvarGreen = CreateConVar("medic_infect_green", "0", "Amount of Green", FCVAR_NOTIFY);
	CvarBlue = CreateConVar("medic_infect_blue", "25", "Amount of Blue", FCVAR_NOTIFY);
	CvarTrans = CreateConVar("medic_infect_alpha", "100", "Amount of Transperency", FCVAR_NOTIFY);
	
	Cvar_DmgAmount = CreateConVar("sv_medic_infect_dmg_amount", "10", "Amount of damage medic infect does each heartbeat",FCVAR_PLUGIN);
	Cvar_DmgTime = CreateConVar("sv_medic_infect_dmg_time", "12", "Amount of time between infection heartbeats",FCVAR_PLUGIN);

	Cvar_SpreadAll = CreateConVar("sv_medic_infect_spread_all", "0", "Allow medical infections to run rampant",FCVAR_PLUGIN);
	Cvar_SpreadSameTeam = CreateConVar("sv_medic_infect_spread_friendly", "1", "Allow medical infections to run rampant inside a team",FCVAR_PLUGIN);
	Cvar_SpreadOpposingTeam = CreateConVar("sv_medic_infect_spread_enemy", "0", "Allow medical infections to run rampant between teams",FCVAR_PLUGIN);		

	Cvar_InfectSameTeam = CreateConVar("sv_medic_infect_friendly", "1", "Allow medics to infect friends",FCVAR_PLUGIN);
	Cvar_InfectOpposingTeam = CreateConVar("sv_medic_infect_enemy", "1", "Allow medics to infect enemies",FCVAR_PLUGIN);
	
	RegConsoleCmd("infect", InfectCommand);
	
	CreateTimer(1.0, HandleInfection);
	HookEventEx("player_death", MedicModify, EventHookMode_Pre);
}

public Action:MedicModify(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!ClientInfected[id]) return Plugin_Continue;
	
	new attacker = ClientInfected[id];
	SetEventInt(event,"attacker",GetClientUserId(attacker));
	if(TF2_GetPlayerClass(attacker) != TFClass_Medic)
	{
		if(ClientInfected[attacker]) SetEventInt(event,"assister",GetClientUserId(ClientInfected[attacker]));
	}
	SetEventString(event,"weapon","infection");
	SetEventInt(event,"customkill",1);
	
	return Plugin_Continue;
}

new beamSprite;
new haloSprite;

public OnMapStart()
{
	beamSprite = PrecacheModel("materials/sprites/bluelaser1.vmt");
	haloSprite = PrecacheModel("materials/sprites/fire.vmt");
}


public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	ClientInfected[client] = 0;
	ClientFriendlyInfected[client] = false;
	return true;
}

public Action:HandleInfection(Handle:timer)
{
	CreateTimer(GetConVarFloat(Cvar_DmgTime), HandleInfection);
	if(!GetConVarInt(CvarEnable)) return;
	
	new maxplayers = GetMaxClients();
	for(new a = 1; a <= maxplayers; a++)
	{
		if(!IsClientInGame(a) || !IsPlayerAlive(a) || ClientInfected[a] == 0) continue;
		
		new hp = GetClientHealth(a);
		hp -= GetConVarInt(Cvar_DmgAmount);
		SetEntityHealth(a,hp);
	}
}

public OnGameFrame()
{
	if(!GetConVarInt(CvarEnable)) return;
	new i = 1;
	decl Float:ori1[3], Float:ori2[3];
	
	new maxplayers = GetMaxClients();
	for(; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;

		if(ClientInfected[i] == 0) continue;
		
		GetClientAbsOrigin(i, ori1);
		for(new a = 1; a <= maxplayers; a++)
		{
			if(!IsClientInGame(a) || !IsPlayerAlive(a)) continue;
			
			GetClientAbsOrigin(a, ori2);
			if( (GetVectorDistance(ori1, ori2, true) < 1000.0) && (TF2_GetPlayerClass(a) != TFClass_Medic) )
			{
				SpreadInfection(i,a);
			}
		}
	}
}

public Action:InfectCommand(i, args)
{
	if(TF2_GetPlayerClass(i) == TFClass_Medic)
	{
		new weaponent = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			
		decl String:classname[32];
		if(GetEdictClassname(weaponent, classname , sizeof(classname)) )
		{
			if(StrEqual(classname, "tf_weapon_medigun") )
			{
				if(GetClientButtons(i) & IN_ATTACK)
				{
					new target = GetClientAimTarget(i);
					if(target > 0) 
					{
						if(CheckIfShouldSpread(i,target) ) Infect(i,target,0);
					}
				}
				else if(GetClientButtons(i) & IN_RELOAD)
				{
					new target = GetClientAimTarget(i);
					if(target > 0) 
					{
						if(CheckIfShouldSpread(i,target) ) Infect(i,target,1);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

stock CheckIfShouldSpread(a,b)
{
	decl Float:ori1[3], Float:ori2[3];
	
	GetClientAbsOrigin(a, ori1);
	GetClientAbsOrigin(b, ori2);
	
	if( (GetVectorDistance(ori1, ori2, true) < 1000.0) && (TF2_GetPlayerClass(b) != TFClass_Medic) )
	{
		return 1;
	}
	
	return 0;
}

stock SpreadInfection(from, to)
{
	if(GetConVarInt(Cvar_SpreadAll) )
		ClientInfected[to] = from;
	else if(GetConVarInt(Cvar_SpreadSameTeam) && (GetClientTeam(from) == GetClientTeam(to) ) )
		ClientInfected[to] = from; 
	else if(GetConVarInt(Cvar_SpreadOpposingTeam) && (GetClientTeam(from) != GetClientTeam(to) ) )
		ClientInfected[to] = from; 
	else if(GetConVarInt(Cvar_InfectSameTeam) && (GetClientTeam(from) != GetClientTeam(to) ) )
		ClientInfected[to] = from;
}
	
stock Infect(from,to,allow)
{
	if(allow && GetConVarInt(Cvar_InfectSameTeam) && (GetClientTeam(from) == GetClientTeam(to) ) )
	{
		ClientInfected[to] = from
		ClientFriendlyInfected[to] = true;
	}
	else if(GetConVarInt(Cvar_InfectOpposingTeam) && (GetClientTeam(from) != GetClientTeam(to) ) )
		ClientInfected[to] = from;
	else if(GetClientTeam(from) == GetClientTeam(to) )
		ClientInfected[to] = 0;
		
	decl Float:ori1[3], Float:ori2[3];
	
	GetClientAbsOrigin(from, ori1);
	GetClientAbsOrigin(to, ori2);

	decl color[4];
	color[0] = GetConVarInt(CvarRed); 
	color[1] = GetConVarInt(CvarGreen);
	color[2] = GetConVarInt(CvarBlue);
	color[3] = GetConVarInt(CvarTrans);
			
	TE_SetupBeamPoints(ori1, ori2, beamSprite, haloSprite, 0, 0, 5.0, 
				2.0, 4.0, 10, 1.0,color, 1);
}
			
		
		