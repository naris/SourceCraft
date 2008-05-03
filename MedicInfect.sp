/**
 * File: MedicInfect.sp
 * Description: Medic Infection for TF2
 * Author(s): Twilight Suzuka
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

new ClientInfected[MAXPLAYERS + 1];
new bool:ClientFriendlyInfected[MAXPLAYERS + 1];

new bool:NativeControl = false;
new bool:NativeMedicArmed[MAXPLAYERS + 1] = { false, ...};
new NativeAmount[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Medic Infection",
	author = "Twilight Suzuka",
	description = "Allows medics to infect again",
	version = "Beta:1",
	url = "http://www.sourcemod.net/"
};

new Handle:Cvar_DmgAmount = INVALID_HANDLE;
new Handle:Cvar_DmgTime = INVALID_HANDLE;
new Handle:Cvar_DmgDistance = INVALID_HANDLE;

new Handle:Cvar_SpreadAll = INVALID_HANDLE;
new Handle:Cvar_SpreadSameTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadOpposingTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadDistance = INVALID_HANDLE;

new Handle:Cvar_InfectSameTeam = INVALID_HANDLE;
new Handle:Cvar_InfectOpposingTeam = INVALID_HANDLE;
new Handle:Cvar_InfectInfector = INVALID_HANDLE;
new Handle:Cvar_InfectMedics = INVALID_HANDLE;
new Handle:Cvar_InfectDelay = INVALID_HANDLE;

new Handle:Cvar_InfectMedi = INVALID_HANDLE;
new Handle:Cvar_InfectSyringe = INVALID_HANDLE;

new Handle:CvarEnable = INVALID_HANDLE;
new Handle:CvarRedTeamRed = INVALID_HANDLE;
new Handle:CvarRedTeamBlue = INVALID_HANDLE;
new Handle:CvarRedTeamGreen = INVALID_HANDLE;
new Handle:CvarRedTeamTrans = INVALID_HANDLE;
new Handle:CvarBlueTeamRed = INVALID_HANDLE;
new Handle:CvarBlueTeamBlue = INVALID_HANDLE;
new Handle:CvarBlueTeamGreen = INVALID_HANDLE;
new Handle:CvarBlueTeamTrans = INVALID_HANDLE;

new Handle:InfectionTimer = INVALID_HANDLE;

new Handle:OnInfectedHandle = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
	// Register Natives
	CreateNative("ControlMedicInfect",Native_ControlMedicInfect);
	CreateNative("SetMedicInfect",Native_SetMedicInfect);
	CreateNative("MedicInfect",Native_MedicInfect);
	CreateNative("HealInfect",Native_HealInfect);
	OnInfectedHandle=CreateGlobalForward("OnInfected",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Array);
	RegPluginLibrary("MedicInfect");
	return true;
}

public OnPluginStart()
{
	CvarEnable = CreateConVar("medic_infect_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CvarRedTeamRed = CreateConVar("medic_infect_red_team_red", "255", "Amount of Red for the Red Team", FCVAR_NOTIFY);
	CvarRedTeamGreen = CreateConVar("medic_infect_red_team_green", "100", "Amount of Green for the Red Team", FCVAR_NOTIFY);
	CvarRedTeamBlue = CreateConVar("medic_infect_red_team_blue", "60", "Amount of Blue for the Red Team", FCVAR_NOTIFY);
	CvarRedTeamTrans = CreateConVar("medic_infect_red_team_alpha", "255", "Amount of Transperency for the Red Team", FCVAR_NOTIFY);
	CvarBlueTeamRed = CreateConVar("medic_infect_blue_team_red", "0", "Amount of Red for the Blue Team", FCVAR_NOTIFY);
	CvarBlueTeamGreen = CreateConVar("medic_infect_blue_team_green", "255", "Amount of Green for the Blue Team", FCVAR_NOTIFY);
	CvarBlueTeamBlue = CreateConVar("medic_infect_blue_team_blue", "100", "Amount of Blue for the Blue Team", FCVAR_NOTIFY);
	CvarBlueTeamTrans = CreateConVar("medic_infect_blue_team_alpha", "255", "Amount of Transperency for the Blue Team", FCVAR_NOTIFY);
	
	Cvar_DmgAmount = CreateConVar("sv_medic_infect_dmg_amount", "10", "Amount of damage medic infect does each heartbeat",FCVAR_PLUGIN);
	Cvar_DmgTime = CreateConVar("sv_medic_infect_dmg_time", "12", "Amount of time between infection heartbeats",FCVAR_PLUGIN);
	Cvar_DmgDistance = CreateConVar("sv_medic_infect_dmg_distance", "0.0", "Distance infection can spread",FCVAR_PLUGIN);

	Cvar_SpreadAll = CreateConVar("sv_medic_infect_spread_all", "0", "Allow medical infections to run rampant",FCVAR_PLUGIN);
	Cvar_SpreadSameTeam = CreateConVar("sv_medic_infect_spread_friendly", "1", "Allow medical infections to run rampant inside a team",FCVAR_PLUGIN);
	Cvar_SpreadOpposingTeam = CreateConVar("sv_medic_infect_spread_enemy", "0", "Allow medical infections to run rampant between teams",FCVAR_PLUGIN);		
	Cvar_SpreadDistance = CreateConVar("sv_medic_infect_spread_distance", "2000.0", "Distance infection can spread",FCVAR_PLUGIN);
	
	Cvar_InfectSameTeam = CreateConVar("sv_medic_infect_friendly", "1", "Allow medics to infect friends",FCVAR_PLUGIN);
	Cvar_InfectOpposingTeam = CreateConVar("sv_medic_infect_enemy", "1", "Allow medics to infect enemies",FCVAR_PLUGIN);
	
	Cvar_InfectInfector = CreateConVar("sv_medic_infect_infector", "0", "Allow reinfections",FCVAR_PLUGIN);
	Cvar_InfectMedics = CreateConVar("sv_medic_infect_medics", "0", "Allow medics to be infected",FCVAR_PLUGIN);
	Cvar_InfectDelay = CreateConVar("sv_medic_infect_delay", "1.0", "Delay between infections",FCVAR_PLUGIN);
	
	Cvar_InfectMedi = CreateConVar("sv_medic_infect_medi", "1", "Infect using medi gun",FCVAR_PLUGIN);
	Cvar_InfectSyringe = CreateConVar("sv_medic_infect_syringe", "1", "Infect using syringe gun",FCVAR_PLUGIN);
	
	HookEventEx("player_death", MedicModify, EventHookMode_Pre);
}

public OnConfigsExecuted()
{
	if (InfectionTimer != INVALID_HANDLE)
		CloseHandle(InfectionTimer);

	InfectionTimer = CreateTimer(GetConVarFloat(Cvar_DmgTime), HandleInfection,_,TIMER_REPEAT);
	HookConVarChange(Cvar_DmgTime, HandleInfectionChange);
}

public OnMapEnd()
{
	new maxplayers = GetMaxClients();
	for(new a = 1; a <= maxplayers; a++)
	{
		ClientInfected[a] = 0;
		ClientFriendlyInfected[a] = false;
	}
}

public HandleInfectionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (InfectionTimer != INVALID_HANDLE)
		CloseHandle(InfectionTimer);

	InfectionTimer = CreateTimer(StringToFloat(newValue), HandleInfection,_,TIMER_REPEAT);
}

public Action:HandleInfection(Handle:timer)
{
	if(!GetConVarInt(CvarEnable) && !NativeControl) return;
	
	new maxplayers = GetMaxClients();
	for(new a = 1; a <= maxplayers; a++)
	{
		if(ClientInfected[a] == 0 || !IsClientInGame(a) || !IsPlayerAlive(a)) continue;
	
		new amt = NativeAmount[ClientInfected[a]];
		new hp = GetClientHealth(a);
		hp -= (amt > 0) ? amt : GetConVarInt(Cvar_DmgAmount);
		
		if(hp <= 0)
			ForcePlayerSuicide(a);
		else
		{
			SetEntityHealth(a,hp);
			//SetEntProp(a, Prop_Send, "m_iHealth", hp, 1);
			//SetEntProp(a, Prop_Data, "m_iHealth", hp, 1);
		}
	}
}

public Action:MedicModify(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!ClientInfected[id]) return Plugin_Continue;
	
	new infector = ClientInfected[id];
	
	ClientInfected[id] = 0;
	ClientFriendlyInfected[id] = false;

	if (IsClientInGame(id))
	{
		SetEntityRenderColor(id);
		SetEntityRenderMode(id, RENDER_NORMAL);

		if (IsClientInGame(infector))
		{
			new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
			if (attacker == id)
			{
				SetEventInt(event,"attacker",GetClientUserId(infector));
				if(TF2_GetPlayerClass(infector) != TFClass_Medic)
				{
					if(ClientInfected[infector])
						SetEventInt(event,"assister",GetClientUserId(ClientInfected[infector]));
				}
				//SetEventString(event,"weapon","infection");
				//SetEventInt(event,"customkill",1); // This makes the kill a Headshot!
			}
			else if (attacker != infector)
			{
				if (GetEventInt(event,"assister") <= 0)
					SetEventInt(event,"assister",GetClientUserId(infector));
			}
		}
	}
	return Plugin_Continue;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	ClientInfected[client] = 0;
	ClientFriendlyInfected[client] = false;
	return true;
}

/*
public OnGameFrame()
{
	if(!GetConVarInt(CvarEnable) && !NativeControl) return;

	if(GetConVarInt(Cvar_InfectMedi))
		CheckMedics();


	if(GetConVarInt(Cvar_SpreadSameTeam) || GetConVarInt(Cvar_SpreadOpposingTeam) || GetConVarInt(Cvar_SpreadAll))
		RunInfection();
}
*/

new Float:MedicDelay[MAXPLAYERS + 1];

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(GetConVarInt(CvarEnable) && !NativeControl) return Plugin_Continue;
	if (NativeControl && !NativeMedicArmed[client]) return Plugin_Continue;

	if(
		GetConVarInt(Cvar_InfectSyringe) 
		|| (TF2_GetPlayerClass(client) != TFClass_Medic) 
		|| (MedicDelay[client] > GetGameTime())
		) 
		return Plugin_Continue;

	if(StrEqual(weaponname, "tf_weapon_syringegun_medic") )
	{
		new target = GetClientAimTarget(client);
		if(target > 0) 
		{
			MedicInfect(client,target,1);
			MedicDelay[client] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
		}
	}

	return Plugin_Continue;
}

public CheckMedics()
{
	decl String:classname[32];
	new maxplayers = GetMaxClients();

	for(new i = 1; i <= maxplayers; i++)
	{
		if (NativeControl && !NativeMedicArmed[i])
			 continue;

		if( !IsClientInGame(i) 
			|| !IsPlayerAlive(i) 
			|| (TF2_GetPlayerClass(i) != TFClass_Medic) 
			|| (MedicDelay[i] > GetGameTime()) 
			) 
			continue;

		new weaponent = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

		if(GetEdictClassname(weaponent, classname , sizeof(classname)) )
		{
			if(StrEqual(classname, "tf_weapon_medigun") )
			{
				new buttons = GetClientButtons(i);
				if(buttons & IN_ATTACK)
				{
					new target = GetClientAimTarget(i);
					if(target > 0) 
					{
						MedicInfect(i,target,0);
						MedicDelay[i] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
					}
				}
				if(buttons & IN_RELOAD)
				{
					new target = GetClientAimTarget(i);
					if(target > 0) 
					{
						MedicInfect(i,target,1);
						MedicDelay[i] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
					}
				}
			}
		}
	}
}

MedicInfect(medic,target,allow)
{
	if (!IsClientInGame(medic) || !IsClientInGame(target))
		return;

	// Rukia: are the teams identical?
	new t_same = (GetClientTeam(medic) == GetClientTeam(target));
	if( t_same )
	{
		if( allow  )
		{
			// Rukia: Don't infect same team if not allowed
			if(  !GetConVarInt(Cvar_InfectSameTeam) )
				return;
			// Rukia: Don't reinfect!
			else if(ClientInfected[target])
				return;
		}
	}
	else
	{
		// Rukia: Don't infect opposing team if not allowed
		if(!GetConVarInt(Cvar_InfectOpposingTeam) )
			return;
		// Rukia: Don't reinfect!
		else if(ClientInfected[target])
			return;
	}

	decl Float:ori1[3], Float:ori2[3];
	GetClientAbsOrigin(medic, ori1);
	GetClientAbsOrigin(target, ori2);

	if( (GetConVarFloat(Cvar_DmgDistance) == 0.0) || (GetVectorDistance(ori1, ori2, true) < GetConVarFloat(Cvar_DmgDistance)) )
	{
		if( t_same ) 
		{
			// Rukia: Infect same team if allowed is on
			if(allow)
				SendInfection(target,medic,true,true);
			// Rukia: Heal if applicable.
			else if (ClientInfected[target] || ClientFriendlyInfected[target])
				HealInfection(target, medic);
		}
		// Rukia: Infect the opposing team otherwise
		else if (!ClientInfected[target])
		{
			SendInfection(target,medic,false,true);
		}
	}
}

public RunInfection()
{
	static Float:InfectedVec[MAXPLAYERS][3];
	static Float:NotInfectedVec[MAXPLAYERS][3];
	static InfectedPlayerVec[MAXPLAYERS];
	static NotInfectedPlayerVec[MAXPLAYERS];
	
	new InfectedCount, NotInfectedCount;
	
	new maxplayers = GetMaxClients();
	for(new index = 1; index <= maxplayers; index++)
	{
		if(!IsClientInGame(index) || !IsPlayerAlive(index)) continue;
		
		if(ClientInfected[index])
		{
			GetClientAbsOrigin(index, InfectedVec[InfectedCount]);
			InfectedPlayerVec[InfectedCount] = index;
			InfectedCount++;
		}
		else
		{
			GetClientAbsOrigin(index, NotInfectedVec[NotInfectedCount]);
			NotInfectedPlayerVec[NotInfectedCount] = index;
			NotInfectedCount++;
		}
	}
	
	for(new infected = 0; infected < InfectedCount; infected++)
	{
		for(new uninfected = 0; uninfected < NotInfectedCount; uninfected++)
		{
			if(GetVectorDistance(InfectedVec[infected], NotInfectedVec[uninfected], true)
			   < GetConVarFloat(Cvar_SpreadDistance) )
			{
				TransmitInfection(NotInfectedPlayerVec[uninfected],InfectedPlayerVec[infected]);
			}
		}
	}
}

TransmitInfection(to, from)
{
	if (!IsClientInGame(from) || !IsClientInGame(to))
		return;

	// Rukia: are the teams identical?
	new bool:t_same = (GetClientTeam(from) == GetClientTeam(to));
	
	// Rukia: Spread to all
	if(GetConVarInt(Cvar_SpreadAll) )
	{
		SendInfection(to,from,t_same,false);
		return;
	}
	
	// Rukia: Don't spread to medics
	if(!GetConVarInt(Cvar_InfectMedics) && (TF2_GetPlayerClass(to) == TFClass_Medic) )
	{
		return;
	}
	
	if(!GetConVarInt(Cvar_InfectInfector))
	{
		new check = from;
		while(ClientInfected[check])
		{
			if(ClientInfected[check] == to) return;
			check = ClientInfected[check];
		}
	}

	// Rukia: Spread to same team
	if(GetConVarInt(Cvar_SpreadSameTeam) && t_same )
	{
		SendInfection(to,from,true,false);
	}
	// Rukia: Spread to opposing team
	else if(GetConVarInt(Cvar_SpreadOpposingTeam) && !t_same )
	{
		SendInfection(to,from,false,false);
	}
	// Rukia: If a medic infects a friendly, allow the infection to spread across team boundaries
	else if(GetConVarInt(Cvar_InfectSameTeam) && !t_same && ClientFriendlyInfected[from])
	{
		SendInfection(to,from,false,false);
	}
}

SendInfection(to,from,bool:friendly,bool:infect)
{
	if (to > 0 && !ClientInfected[to])
	{
		ClientInfected[to] = from;
		ClientFriendlyInfected[to] = friendly;

		new color[4];
		if (GetClientTeam(to) == _:TFTeam_Blue)
		{
			color[0] = GetConVarInt(CvarBlueTeamRed);
			color[1] = GetConVarInt(CvarBlueTeamGreen);
			color[2] = GetConVarInt(CvarBlueTeamBlue);
			color[3] = GetConVarInt(CvarBlueTeamTrans);
		}
		else
		{
			color[0] = GetConVarInt(CvarRedTeamRed);
			color[1] = GetConVarInt(CvarRedTeamGreen);
			color[2] = GetConVarInt(CvarRedTeamBlue);
			color[3] = GetConVarInt(CvarRedTeamTrans);
		}
		SetEntityRenderColor(to,color[0],color[1],color[2],color[3]);

		PrintHintText(to,"You have been infected!");

		if(from > 0 && IsClientInGame(from))
		{
			if(infect) PrintHintText(from,"Virus administered!");
			else PrintHintText(from,"Virus spread!");
		}

		new res;
		Call_StartForward(OnInfectedHandle);
		Call_PushCell(to);
		Call_PushCell(from);
		Call_PushCell(true);
		Call_PushArray(color, sizeof(color));
		Call_Finish(res);
	}
}

HealInfection(target,client)
{
	if (target > 0 && IsClientInGame(target) && IsPlayerAlive(target))
	{
		new color[4] = {255, 255, 255, 255};

		ClientInfected[target] = 0; 
		ClientFriendlyInfected[target] = false;

		SetEntityRenderColor(target,color[0],color[1],color[2],color[3]);
		PrintHintText(target,"You have been cured!");

		if (client > 0 && IsClientInGame(client))
			PrintHintText(client,"%N has been cured!", target);

		new res;
		Call_StartForward(OnInfectedHandle);
		Call_PushCell(target);
		Call_PushCell(client);
		Call_PushCell(false);
		Call_PushArray(color, sizeof(color));
		Call_Finish(res);
	}
}

public Native_ControlMedicInfect(Handle:plugin,numParams)
{
	if (numParams == 0)
		NativeControl = true;
	else if(numParams == 1)
		NativeControl = GetNativeCell(1);
}

public Native_SetMedicInfect(Handle:plugin,numParams)
{
	if (numParams >= 1 && numParams <= 3)
	{
		new client = GetNativeCell(1);
		NativeMedicArmed[client] = (numParams >= 2) ? GetNativeCell(2) : true;
		NativeAmount[client] = (numParams >= 3) ? GetNativeCell(3) : 0;
	}
}

public Native_MedicInfect(Handle:plugin,numParams)
{
	if (numParams >= 2 && numParams <= 3)
	{
		new client = GetNativeCell(1);
		new target = GetNativeCell(2);
		new allow = (numParams >= 3) ? GetNativeCell(3) : 0;
		MedicInfect(client,target,allow);
	}
}

public Native_HealInfect(Handle:plugin,numParams)
{
	if (numParams == 2)
	{
		new client = GetNativeCell(1);
		new target = GetNativeCell(2);
		if (ClientInfected[target] || ClientFriendlyInfected[target])
			HealInfection(target, client);
	}
}
