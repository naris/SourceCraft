#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"

#define MOVETYPE_WALK			2
#define MOVETYPE_FLYGRAVITY		5
#define MOVECOLLIDE_DEFAULT		0
#define MOVECOLLIDE_FLY_BOUNCE	1

#define LIFE_ALIVE	0

// ConVars
new Handle:sm_jetpack			= INVALID_HANDLE;
new Handle:sm_jetpack_sound		= INVALID_HANDLE;
new Handle:sm_jetpack_speed		= INVALID_HANDLE;
new Handle:sm_jetpack_volume	= INVALID_HANDLE;

// SendProp Offsets
new g_iLifeState	= -1;
new g_iMoveCollide	= -1;
new g_iMoveType		= -1;
new g_iVelocity		= -1;

// Soundfile
new String:g_sSound[255]	= "vehicles/airboat/fan_blade_fullthrottle_loop1.wav";

// Is Jetpack Enabled
new bool:g_bJetpacks[MAXPLAYERS + 1]	= {false,...};

// Timer For GameFrame
new Float:g_fTimer	= 0.0;

// MaxClients
new g_iMaxClients	= 0;

public Plugin:myinfo =
{
	name = "Jetpack",
	author = "Knagg0",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.mfzb.de"
};

public OnPluginStart()
{
	AutoExecConfig();
	
	// Create ConVars
	CreateConVar("sm_jetpack_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_jetpack = CreateConVar("sm_jetpack", "1", "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_jetpack_sound = CreateConVar("sm_jetpack_sound", g_sSound, "", FCVAR_PLUGIN);
	sm_jetpack_speed = CreateConVar("sm_jetpack_speed", "100", "", FCVAR_PLUGIN);
	sm_jetpack_volume = CreateConVar("sm_jetpack_volume", "0.5", "", FCVAR_PLUGIN);

	// Create ConCommands
	RegConsoleCmd("+sm_jetpack", JetpackP, "", FCVAR_GAMEDLL);
	RegConsoleCmd("-sm_jetpack", JetpackM, "", FCVAR_GAMEDLL);
	
	// Find SendProp Offsets
	if((g_iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState")) == -1)
		LogError("Could not find offset for CBasePlayer::m_lifeState");
		
	if((g_iMoveCollide = FindSendPropOffs("CBaseEntity", "movecollide")) == -1)
		LogError("Could not find offset for CBaseEntity::movecollide");
		
	if((g_iMoveType = FindSendPropOffs("CBaseEntity", "movetype")) == -1)
		LogError("Could not find offset for CBaseEntity::movetype");
		
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
}

public OnMapStart()
{
	g_fTimer = 0.0;
	g_iMaxClients = GetMaxClients();
}

public OnConfigsExecuted()
{
	GetConVarString(sm_jetpack_sound, g_sSound, sizeof(g_sSound));
	PrecacheSound(g_sSound, true);
}

public OnGameFrame()
{
	if(GetConVarBool(sm_jetpack) && g_fTimer < GetGameTime() - 0.075)
	{
		g_fTimer = GetGameTime();
		
		for(new i = 1; i <= g_iMaxClients; i++)
		{
			if(g_bJetpacks[i])
			{
				if(!IsAlive(i)) StopJetpack(i);
				else AddVelocity(i, GetConVarFloat(sm_jetpack_speed));
			}
		}
	}
}

public OnClientDisconnect(client)
{
	StopJetpack(client);
}

public Action:JetpackP(client, args)
{
	if(GetConVarBool(sm_jetpack) && !g_bJetpacks[client] && IsAlive(client))
	{
		new Float:vecPos[3];
		GetClientAbsOrigin(client, vecPos);
		EmitSoundToAll(g_sSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(sm_jetpack_volume), SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
		SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
		g_bJetpacks[client] = true;
	}
	
	return Plugin_Continue;
}

public Action:JetpackM(client, args)
{
	StopJetpack(client);
	return Plugin_Continue;
}

StopJetpack(client)
{
	if(g_bJetpacks[client])
	{
		if(IsAlive(client)) SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
		StopSound(client, SNDCHAN_AUTO, g_sSound);
		g_bJetpacks[client] = false;
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
	if(g_iLifeState != -1 && GetEntData(client, g_iLifeState, 1) == LIFE_ALIVE)
		return true;

	return false;
}