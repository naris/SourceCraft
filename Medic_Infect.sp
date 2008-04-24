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
	version = "Alpha:5",
	url = "http://www.sourcemod.net/"
};

new Handle:Cvar_DmgAmount = INVALID_HANDLE;
new Handle:Cvar_DmgTime = INVALID_HANDLE;
new Handle:Cvar_DmgDistance = INVALID_HANDLE;

new Handle:Cvar_SpreadAll = INVALID_HANDLE;
new Handle:Cvar_SpreadSameTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadOpposingTeam = INVALID_HANDLE;

new Handle:Cvar_InfectSameTeam = INVALID_HANDLE;
new Handle:Cvar_InfectOpposingTeam = INVALID_HANDLE;
new Handle:Cvar_InfectInfector = INVALID_HANDLE;
new Handle:Cvar_InfectMedics = INVALID_HANDLE;
new Handle:Cvar_InfectDelay = INVALID_HANDLE;

new Handle:Cvar_InfectMedi = INVALID_HANDLE;
new Handle:Cvar_InfectSyringe = INVALID_HANDLE;

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
	Cvar_DmgDistance = CreateConVar("sv_medic_infect_dmg_distance", "1000.0", "Distance infection can spread",FCVAR_PLUGIN);

	Cvar_SpreadAll = CreateConVar("sv_medic_infect_spread_all", "0", "Allow medical infections to run rampant",FCVAR_PLUGIN);
	Cvar_SpreadSameTeam = CreateConVar("sv_medic_infect_spread_friendly", "1", "Allow medical infections to run rampant inside a team",FCVAR_PLUGIN);
	Cvar_SpreadOpposingTeam = CreateConVar("sv_medic_infect_spread_enemy", "0", "Allow medical infections to run rampant between teams",FCVAR_PLUGIN);		

	Cvar_InfectSameTeam = CreateConVar("sv_medic_infect_friendly", "1", "Allow medics to infect friends",FCVAR_PLUGIN);
	Cvar_InfectOpposingTeam = CreateConVar("sv_medic_infect_enemy", "1", "Allow medics to infect enemies",FCVAR_PLUGIN);
	
	Cvar_InfectInfector = CreateConVar("sv_medic_infect_infector", "0", "Allow reinfections",FCVAR_PLUGIN);
	Cvar_InfectMedics = CreateConVar("sv_medic_infect_medics", "0", "Allow medics to be infected",FCVAR_PLUGIN);
	Cvar_InfectDelay = CreateConVar("sv_medic_infect_delay", "1.0", "Delay between infections",FCVAR_PLUGIN);
	
	Cvar_InfectMedi = CreateConVar("sv_medic_infect_medi", "1", "Infect using medi gun",FCVAR_PLUGIN);
	Cvar_InfectSyringe = CreateConVar("sv_medic_infect_syringe", "0", "Infect using syringe gun",FCVAR_PLUGIN);
		
	CreateTimer(1.0, HandleInfection);
	HookEventEx("player_death", MedicModify, EventHookMode_Pre);
}

new beamSprite;
new haloSprite;

public OnMapStart()
{
	beamSprite = PrecacheModel("materials/sprites/bluelaser1.vmt");
	haloSprite = PrecacheModel("materials/sprites/fire.vmt");
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

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	ClientInfected[client] = 0;
	ClientFriendlyInfected[client] = false;
	return true;
}

public OnGameFrame()
{
	if(GetConVarInt(Cvar_InfectMedi)) CheckMedics();
	RunInfection();
}

new Float:MedicDelay[MAXPLAYERS];

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
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
			MedicInfect(client,target,1)
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
		if( !IsClientInGame(i) 
			|| !IsPlayerAlive(i) 
			|| (TF2_GetPlayerClass(i) != TFClass_Medic) 
			|| (MedicDelay[i] > GetGameTime()) ) 
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
						MedicInfect(i,target,0)
						MedicDelay[i] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
					}
				}
				if(buttons & IN_RELOAD)
				{
					new target = GetClientAimTarget(i);
					if(target > 0) 
					{
						MedicInfect(i,target,1)
						MedicDelay[i] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
					}
				}
			}
		}
	}
}

stock MedicInfect(a,b,amount)
{
	// Rukia: are the teams identical?
	new t_same = GetClientTeam(a) == GetClientTeam(b);
	
	// Rukia: Don't spread to same team
	if(!GetConVarInt(Cvar_InfectSameTeam) && t_same )
	{
		return 0;
	}
	
	// Rukia: Don't spread to opposing team
	if(!GetConVarInt(Cvar_InfectOpposingTeam) && !t_same )
	{
		return 0;
	}
	
	decl Float:ori1[3], Float:ori2[3];
	
	GetClientAbsOrigin(a, ori1);
	GetClientAbsOrigin(b, ori2);

	if( GetVectorDistance(ori1, ori2, true) < GetConVarFloat(Cvar_DmgDistance) )
	{
		Infect(a,b,amount);
		return 1;
	}
	
	return 0;
}

stock Infect(from,to,allow)
{
	// Rukia: are the teams identical?
	new t_same = GetClientTeam(from) == GetClientTeam(to);
	
	if(allow && GetConVarInt(Cvar_InfectSameTeam) && ( t_same ) )
	{
		ClientInfected[to] = from
		ClientFriendlyInfected[to] = true;
	}
	else if(GetConVarInt(Cvar_InfectOpposingTeam) && ( !t_same ) )
		ClientInfected[to] = from;
	else if(GetClientTeam(from) == GetClientTeam(to) )
		ClientInfected[to] = 0;
		
	InfectionEffect(from,to);
}

public RunInfection()
{
	new maxplayers = GetMaxClients();

	static Float:InfectedVec[MAXPLAYERS][3];
	static Float:NotInfectedVec[MAXPLAYERS][3];
	static PlayerVec[MAXPLAYERS]
	
	new InfectedCount, NotInfectedCount
	
	new i = 1, a = 0
	for(; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		PlayerVec[a] = i;
		
		if(ClientInfected[a])
		{
			GetClientAbsOrigin(a, InfectedVec[a]);
			InfectedCount++;
		}
		else
		{
			GetClientAbsOrigin(a, NotInfectedVec[a]);
			NotInfectedCount++;
		}
		
		a++;
	}
	
	new k = 0, m = 0;
	for(i = 0; i < InfectedCount; i++)
	{
		for(k = 0; k < NotInfectedCount; k++)
		{
			if(GetVectorDistance(InfectedVec[i], NotInfectedVec[k], true) < GetConVarFloat(Cvar_DmgDistance) )
			{
				a = PlayerVec[k];
				m = PlayerVec[i];
				TransmitInfection(a,m);
				
			}
		}
	}
}

stock TransmitInfection(from, to)
{
	// Rukia: Spread to all
	if(GetConVarInt(Cvar_SpreadAll) )
	{
		ClientInfected[to] = from;
		InfectionEffect(from,to)
		return 1;
	}
	
	// Rukia: Don't spread to medics
	if(!GetConVarInt(Cvar_InfectMedics) && (TF2_GetPlayerClass(to) == TFClass_Medic) )
	{
		return 0;
	}
	
	if(!GetConVarInt(Cvar_InfectInfector))
	{
		new a = from;
		while(ClientInfected[a])
		{
			if(ClientInfected[a] == to) return 0;
			a = ClientInfected[a];
		}
	}

	// Rukia: are the teams identical?
	new t_same = GetClientTeam(from) == GetClientTeam(to);
	
	// Rukia: Spread to same team
	if(GetConVarInt(Cvar_SpreadSameTeam) && t_same )
	{
		ClientInfected[to] = from;
		ClientFriendlyInfected[to] = true;
	}
	// Rukia: Spread to opposing team
	else if(GetConVarInt(Cvar_SpreadOpposingTeam) && !t_same )
	{
		ClientInfected[to] = from;
	}
	// Rukia: If a medic infects a friendly, allow the infection to spread across team boundaries
	else if(GetConVarInt(Cvar_InfectSameTeam) && !t_same && ClientFriendlyInfected[from])
	{
		ClientInfected[to] = from;
	}
	else return 0;
	
	InfectionEffect(from,to)
	return 1;
}
	
stock InfectionEffect(from,to)
{
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
