#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <entlimit>

#pragma newdecls required

//#define DEBUG
#define PLUGIN_VERSION	"1.5"

// settings for m_takedamage
#define DAMAGE_NO               0
#define DAMAGE_EVENTS_ONLY      1       // Call damage functions, but don't modify health
#define DAMAGE_YES              2
#define DAMAGE_AIM              3

enum
{
	STATE_IDLE = 0,
	STATE_OPEN,
	STATE_CLOSED,
	STATE_STUNNED,
};

#define ROLLERMINE_SE_CLEAR					0
#define ROLLERMINE_SE_TAUNT					0x1

#define ROLLERMINE_MAX_ATTACK_DIST			4096
#define ROLLERMINE_HOP_DELAY				2	// Don't allow hops faster than this, Doesn't actually do anything

// Colors
char g_strMineColor[6][16] = { "",            // 0:Unassigned / Default
                               "",            // 1:Spectator
                               "255 0 0",     // 2:Red  / Allies / Terrorists
                               "0 0 255",     // 3:Blue / Axis   / Counter-Terrorists
                               "",            // 4:No Team?
                               ""             // 5:Boss?
};

int g_iShockIndex = -1;
int g_iShockHaloIndex = -1;

bool g_NativeControl = false;

ConVar g_hRollerSpeed;
ConVar g_hRollerForce;
ConVar g_hRollerDamage;
ConVar g_hRollerStunDur;
ConVar g_hRollerOpenThreshold;
ConVar g_hRollerAttackDist;
ConVar g_hRollerExplode;
ConVar g_hRollerRadius;
ConVar g_hMineColor[4];

ConVar g_hFriendlyFire;

GlobalForward g_fwdOnSetRollermine;

public Plugin myinfo = 
{
	name = "[TF2] Rollermine", 
	author = "Pelipoika", 
	description = "Zzap", 
	version = PLUGIN_VERSION, 
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Register Natives
	CreateNative("ControlRM",Native_ControlRM);
	CreateNative("SetRollermine",Native_SetRollermine);
	CreateNative("SpawnRollerMine",Native_SpawnRollerMine);

	// Register Forwards
	g_fwdOnSetRollermine=CreateGlobalForward("OnSetRollermine",ET_Hook,Param_Cell);

	RegPluginLibrary("rollermine");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_rollermine", Command_Rollermine, ADMFLAG_ROOT);
	RegAdminCmd("sm_clearmines", Command_ClearMines, ADMFLAG_ROOT);
	
	g_hRollerSpeed = CreateConVar("rollermine_speed", "200", "Rollermine rotation speed");
	g_hRollerForce = CreateConVar("rollermine_force", "5000", "Rollermine angular force");
	g_hRollerDamage = CreateConVar("rollermine_damage", "35", "Rollermine shock damage");
	g_hRollerStunDur = CreateConVar("rollermine_stunduration", "1.5", "Rollermine stun duration");
	g_hRollerOpenThreshold = CreateConVar("rollermine_open_threshold", "256", "Rollermine open threshold");
	g_hRollerAttackDist = CreateConVar("rollermine_max_attack_distance", "4096", "Rollermine max attack distance");
	g_hRollerExplode = CreateConVar("rollermine_explode","160","Explosion damage of Rollermines", _, true, 0.0, true, 1000.0);
	g_hRollerRadius = CreateConVar("rollermine_radius","250","Explosion radius of Rollermines", _, true, 0.0, true, 1000.0);

	g_hMineColor[1] = CreateConVar("rollermine_color_1", g_strMineColor[1], "Mine Color (can include alpha) for team 1 (Spectators)");
	g_hMineColor[2] = CreateConVar("rollermine_color_2", g_strMineColor[2], "Mine Color (can include alpha) for team 2 (Red  / Allies / Terrorists)");
	g_hMineColor[3] = CreateConVar("rollermine_color_3", g_strMineColor[3], "Mine Color (can include alpha) for team 3 (Blue / Axis   / Counter-Terrorists)");

	g_hFriendlyFire = FindConVar("mp_friendlyfire");

	g_hRollerSpeed.AddChangeHook(OnSettingsChanged);
	g_hRollerForce.AddChangeHook(OnSettingsChanged);

	g_hMineColor[1].AddChangeHook(OnSettingsChanged);
	g_hMineColor[2].AddChangeHook(OnSettingsChanged);
	g_hMineColor[3].AddChangeHook(OnSettingsChanged);
	
	CreateConVar("rollermine_version", PLUGIN_VERSION, "Rollermine spawner version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	AutoExecConfig(true);

	//If we load after the map has started, the OnEntityCreated check wont be called
	int iSpawn = -1;
	while ((iSpawn = FindEntityByClassname(iSpawn, "func_respawnroom")) != -1)
	{
		// If plugin is loaded early, these won't be called because the func_respawnroom wont exist yet
		SDKHook(iSpawn, SDKHook_StartTouch, SpawnStartTouch);
	}
}

public void OnConfigsExecuted()
{
    // Get the color settings
    g_hMineColor[1].GetString(g_strMineColor[1], sizeof(g_strMineColor[]));
    g_hMineColor[2].GetString(g_strMineColor[2], sizeof(g_strMineColor[]));
    g_hMineColor[3].GetString(g_strMineColor[3], sizeof(g_strMineColor[]));
}

public void OnPluginEnd()
{
	int iCount = 0;
	
	int index = -1;
	while((index = FindEntityByClassname(index, "prop_physics_multiplayer")) != -1)
	{
		if (IsValidEntity(index))
		{
			char strName[64];
			GetEntPropString(index, Prop_Data, "m_iName", strName, sizeof(strName));
			
			if(StrContains(strName, "RollerMine") != -1)
			{
				StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
				StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
				StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
				AcceptEntityInput(index, "Kill");
				
				iCount++;
			}
		}
	}
	
	#if defined DEBUG
	PrintToChatAll("[SM] Removed %i Rollermines", iCount);
	#endif
}

public void OnMapStart()
{
	PrecacheModel("models/roller.mdl");
	PrecacheModel("models/roller_spikes.mdl");
	
	g_iShockHaloIndex = PrecacheModel("sprites/bluelight1.vmt");
	g_iShockIndex = PrecacheModel("sprites/rollermine_shock.vmt");
	
	PrecacheModel("sprites/rollermine_shock_yellow.vmt");
	
	PrecacheSound("npc/roller/mine/rmine_blades_in1.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_in2.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_in3.wav");
	
	PrecacheSound("npc/roller/mine/rmine_blades_out1.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_out2.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_out3.wav");
	
	PrecacheSound("npc/roller/mine/rmine_seek_loop2.wav");
	PrecacheSound("npc/roller/mine/rmine_movefast_loop1.wav");
	PrecacheSound("npc/roller/mine/rmine_moveslow_loop1.wav");
	PrecacheSound("npc/roller/mine/rmine_taunt1.wav");
	PrecacheSound("npc/roller/mine/rmine_explode_shock1.wav");
}

public void OnSettingsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_hMineColor[1])
        strcopy(g_strMineColor[1], sizeof(g_strMineColor[]), newValue);
    else if (convar == g_hMineColor[2])
        strcopy(g_strMineColor[2], sizeof(g_strMineColor[]), newValue);
    else if (convar == g_hMineColor[3])
        strcopy(g_strMineColor[3], sizeof(g_strMineColor[]), newValue);
	else
	{
		int iEnt = -1;
		while((iEnt = FindEntityByClassname(iEnt, "prop_physics_multiplayer")) != -1)
		{
			if (IsValidEntity(iEnt))
			{
				char strName[64];
				GetEntPropString(iEnt, Prop_Data, "m_iName", strName, sizeof(strName));
				
				if(StrContains(strName, "RollerMine") != -1)
				{
					int iMotor = GetEntPropEnt(iEnt, Prop_Data, "m_hMoveChild");
				
					char strSpeed[16], strForce[16];
					g_hRollerSpeed.GetString(strSpeed, sizeof(strSpeed));
					g_hRollerForce.GetString(strForce, sizeof(strForce));
				
					DispatchKeyValue(iMotor, "force", strForce);
					DispatchKeyValue(iMotor, "speed", strSpeed);
				}
			}
		}
	}
}

public void OnEntityCreated(int entity, const char [] classname)
{
	if (StrEqual(classname, "func_respawnroom", false))	// This is the earliest we can catch this
	{
		SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
	}
}

public void OnEntityDestroyed(int entity)
{
	if(entity > MaxClients)
	{
		char strName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(StrContains(strName, "RollerMine") != -1)
		{
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
		}
	}
}

public void SpawnStartTouch(int spawn, int entity)
{
	if(entity > MaxClients)
	{
		char strName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(StrContains(strName, "RollerMine") != -1)
		{
			// If any mines enter spawn, Silence them
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
		
			// Then Dissolve them
			int dissolver = CreateEntityByName("env_entity_dissolver");
			if (dissolver>0)
			{
				DispatchKeyValue(dissolver, "dissolvetype", "1");
				DispatchKeyValue(dissolver, "target", strName);
				AcceptEntityInput(dissolver, "Dissolve");
				AcceptEntityInput(dissolver, "kill");
			}
			CreateTimer(0.2, KillEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action KillEntity(Handle timer, any entRef)
{
    // Ensure the entity is the same 
    int entity = EntRefToEntIndex(entRef);
    if (entity > 0 && IsValidEntity(entity))
		AcceptEntityInput(entity, "kill");

    return Plugin_Stop;
}

public Action Command_ClearMines(int client, int args)
{
	if (!g_NativeControl)
		OnPluginEnd();

	return Plugin_Handled;
}

public Action Command_Rollermine(int client, int args)
{
	if (!g_NativeControl)
		PlaceRollerMine(client);

	return Plugin_Handled;
}

public int PlaceRollerMine(int client)
{
	int iEnt = 0;
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		float origin[3], angles[3], pos[3];
		GetClientEyePosition(client, origin);
		GetClientEyeAngles(client, angles);
		
		Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceFilterSelf, client);
		
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(pos, trace);
			pos[2] += 15.0;
			
			Action res = Plugin_Continue;
			Call_StartForward(g_fwdOnSetRollermine);
			Call_PushCell(client);
			Call_Finish(res);
			if (res != Plugin_Continue)
			{
				delete trace;
				return 0;
			}

			iEnt = SpawnRollerMine(client, pos);
		}
		
		delete trace;
	}
	return iEnt;
}

public int SpawnRollerMine(int client, float pos[3])
{
	if (IsEntLimitReached(100, .message="unable to create rollermine"))
	{
		// don't crash the server spawning too many of these
		return 0;
	}
	else
	{
		int iEnt = CreateEntityByName("prop_physics_multiplayer");
		if (IsValidEntity(iEnt))
		{
			char strName[64];
			Format(strName, sizeof(strName), "RollerMine%i", iEnt);
			DispatchKeyValue(iEnt, "targetname", strName);
			DispatchKeyValueVector(iEnt, "origin", pos);
			DispatchKeyValue(iEnt, "model", "models/roller.mdl");
			DispatchSpawn(iEnt);

			int team = g_hFriendlyFire.BoolValue ? 0 : GetClientTeam(client);
			SetMineColor(iEnt, team);

			SetEntProp(iEnt, Prop_Send, "m_iTeamNum", team, 4);
			SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", client);
			SetEntPropEnt(iEnt, Prop_Data, "m_hLastAttacker", client);
			SetEntPropEnt(iEnt, Prop_Data, "m_hPhysicsAttacker", client);

			DispatchKeyValue(iEnt, "OnBreak", "!self,Kill,,0,-1");

			char strExplode[16];
			g_hRollerExplode.GetString(strExplode, sizeof(strExplode));
			DispatchKeyValue(iEnt, "ExplodeDamage", strExplode);

			char strRadius[16];
			g_hRollerRadius.GetString(strRadius, sizeof(strRadius));
			DispatchKeyValue(iEnt, "ExplodeRadius", strRadius);

			SDKHook(iEnt, SDKHook_SetTransmit, OnRollermineThink);
			
			char strSpeed[16], strForce[16];
			g_hRollerSpeed.GetString(strSpeed, sizeof(strSpeed));
			g_hRollerForce.GetString(strForce, sizeof(strForce));
		
			int iMotor = CreateEntityByName("phys_torque");
			DispatchKeyValueVector(iMotor, "origin", pos);
			DispatchKeyValue(iMotor, "attach1", strName);
			DispatchKeyValue(iMotor, "force", strForce);
			DispatchKeyValue(iMotor, "speed", strSpeed);
			DispatchSpawn(iMotor);
			
			SetVariantString("!activator");
			AcceptEntityInput(iMotor, "SetParent", iEnt);
			
			ActivateEntity(iMotor);
		}
		return iEnt;
	}
}

void SetMineColor(int iEnt, int team)
{
    if (team > 0 && team < sizeof(g_strMineColor) && g_strMineColor[team][0] != '\0')
    {
        char color[4][4];
        if (ExplodeString(g_strMineColor[team], " ", color, sizeof(color), sizeof(color[])) <= 3)
            strcopy(color[3], sizeof(color[]), "255");

        SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
        SetEntityRenderColor(iEnt, StringToInt(color[0]), StringToInt(color[1]),
                                   StringToInt(color[2]), StringToInt(color[3]));
    }
    else
    {
        SetEntityRenderMode(iEnt, RENDER_NORMAL);
        SetEntityRenderColor(iEnt, 255, 255, 255, 255);
    }
}

//Yes i know, it's not ideal to use SetTransmit in place of think but timers are dumb and physics props don't think
public void OnRollermineThink(int iEnt, int client)
{
	static int iThinkWhenClient = 0;
	
	//This bad code ensures that we don't think any more than we should
	if(iThinkWhenClient > 0 && iThinkWhenClient <= MaxClients && IsClientInGame(iThinkWhenClient))
	{
		int iMotor = GetEntPropEnt(iEnt, Prop_Data, "m_hMoveChild");
	
		if(GetRollerState(iEnt) != STATE_STUNNED)
		{
			float flEntPos[3];
			GetEntPropVector(iEnt, Prop_Data, "m_vecAbsOrigin", flEntPos);
		
			//float flLastSeenPos[3];
			//GetEntPropVector(iEnt, Prop_Data, "m_vecVelocity", flLastSeenPos);
		
			int iTarget = Entity_GetClosestClient(iEnt);		
			if(iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget))
			{
				float flClientPos[3];
				GetClientAbsOrigin(iTarget, flClientPos);
				
				//Set last seen position
				//SetEntPropVector(iEnt, Prop_Data, "m_vecVelocity", flClientPos);
				
				float flDistance = GetVectorDistance(flClientPos, flEntPos);
				if(flDistance <= g_hRollerOpenThreshold.FloatValue)
				{
					if(GetRollerState(iEnt) != STATE_OPEN)
					{
						SetRollerState(iEnt, STATE_OPEN);
					}
				}
				else if(GetRollerState(iEnt) != STATE_CLOSED)
				{
					AcceptEntityInput(iMotor, "Deactivate");
					SetRollerState(iEnt, STATE_CLOSED);
				}
				
				if(flDistance <= 400.0 && !(GetRollerFlags(iEnt) & ROLLERMINE_SE_TAUNT))
				{
					EmitSoundToAll("npc/roller/mine/rmine_taunt1.wav", iEnt, _, _, _, _, GetRandomInt(90, 110));
					
					int iFlags = GetRollerFlags(iEnt) | ROLLERMINE_SE_TAUNT;
					SetRollerFlags(iEnt, iFlags); 
					
					#if defined DEBUG
					PrintToChatAll("TAUNT");
					#endif
				}
				
				if(flDistance <= 35.0)
				{
					EmitSoundToAll("npc/roller/mine/rmine_explode_shock1.wav", iEnt, _, _, _, _, GetRandomInt(100, 120));
					
					float impulse[3];
					SubtractVectors(flEntPos, flClientPos, impulse);
					impulse[2] = 0.0;
					NormalizeVector(impulse, impulse);
					impulse[2] = 0.75;
					NormalizeVector(impulse, impulse);
					ScaleVector(impulse, 600.0);
		
					TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, impulse);
					
					SDKHooks_TakeDamage(iTarget, iEnt, iEnt, g_hRollerDamage.FloatValue, DMG_SHOCK);
					
					float flStundDuration = g_hRollerStunDur.FloatValue;
					if(flStundDuration > 0.0)
					{
						SetRollerState(iEnt, STATE_STUNNED);
						AcceptEntityInput(iMotor, "Deactivate");
						
						CreateTimer(flStundDuration, Timer_UnStun, EntIndexToEntRef(iEnt));
					}
				}
				
				float flDirection[3];
				MakeVectorFromPoints(flEntPos, flClientPos, flDirection);
				flDirection[2] = 0.0;
				
				NormalizeVector(flDirection, flDirection);
				
				float flRight[3];
				GetVectorVectors(flDirection, flRight, NULL_VECTOR);
				
				NegateVector(flRight);
				
				SetEntPropVector(iMotor, Prop_Data, "m_axis", flRight);
		
				AcceptEntityInput(iMotor, "Deactivate");
				AcceptEntityInput(iMotor, "Activate");
			}
			else if(GetRollerState(iEnt) != STATE_IDLE)
			{
			/*	if(flLastSeenPos[0] != 0.0 && flLastSeenPos[1] != 0.0 && flLastSeenPos[2] != 0.0)
				{	
					float flDirection[3];
					MakeVectorFromPoints(flEntPos, flLastSeenPos, flDirection);
					flDirection[2] = 0.0;
					
					NormalizeVector(flDirection, flDirection);
					
					float flRight[3];
					GetVectorVectors(flDirection, flRight, NULL_VECTOR);
					
					NegateVector(flRight);
					
					SetEntPropVector(iMotor, Prop_Data, "m_axis", flRight);
			
					AcceptEntityInput(iMotor, "Deactivate");
					AcceptEntityInput(iMotor, "Activate");
					
					Handle hTrace = TR_TraceRayFilterEx(flEntPos, flLastSeenPos, MASK_SOLID, RayType_EndPoint, TraceFilterSelf, iEnt);
					bool bSee = TR_DidHit(hTrace);
					
					PrintToServer("- [%.1f] %i", GetGameTime(), TR_GetEntityIndex(hTrace));
					
					delete hTrace;
					
					float flDistance = GetVectorDistance(flEntPos, flLastSeenPos);
					
					if(flDistance <= 50.0 || bSee)
					{
						PrintToChatAll("Stop snooping");
						
						SetEntPropVector(iEnt, Prop_Data, "m_vecVelocity", view_as<float>({0.0, 0.0, 0.0}));
					}
				}
				else
				{*/
				AcceptEntityInput(iMotor, "Deactivate");
				
				SetRollerState(iEnt, STATE_IDLE);
			//	}
			}
		}
		else if(GetRollerState(iEnt) == STATE_STUNNED)
		{
			AcceptEntityInput(iMotor, "Deactivate");
		}
	}
	else
		iThinkWhenClient = client;
}

public Action Timer_UnStun(Handle timet, any ref)
{
	int iEnt = EntRefToEntIndex(ref);
	if(iEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEnt))
	{
		SetRollerState(iEnt, STATE_IDLE);
	}
}

stock void SetRollerFlags(int iRollerMine, int iFlags)
{
	SetEntProp(iRollerMine, Prop_Data, "m_fFlags", iFlags);
}

stock int GetRollerFlags(int iRollerMine)
{
	return GetEntProp(iRollerMine, Prop_Data, "m_fFlags");
}

stock void SetRollerState(int iRollerMine, int iState)
{
	switch(iState)
	{
		case STATE_IDLE:
		{
			SetEntityModel(iRollerMine, "models/roller.mdl");

			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_seek_loop2.wav", iRollerMine);
			
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("npc/roller/mine/rmine_blades_in1.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 2: EmitSoundToAll("npc/roller/mine/rmine_blades_in2.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 3: EmitSoundToAll("npc/roller/mine/rmine_blades_in3.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
			}
			
			#if defined DEBUG
			PrintToChatAll("IDLE");
			#endif
			
			SetRollerFlags(iRollerMine, ROLLERMINE_SE_CLEAR);
		}
		case STATE_CLOSED:
		{
			SetEntityModel(iRollerMine, "models/roller.mdl");

			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_moveslow_loop1.wav", iRollerMine);
			
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("npc/roller/mine/rmine_blades_in1.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 2: EmitSoundToAll("npc/roller/mine/rmine_blades_in2.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 3: EmitSoundToAll("npc/roller/mine/rmine_blades_in3.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
			}
			
			#if defined DEBUG
			PrintToChatAll("CLOSED");
			#endif
			
			SetRollerFlags(iRollerMine, ROLLERMINE_SE_CLEAR);
		}
		case STATE_OPEN:
		{
			SetEntityModel(iRollerMine, "models/roller_spikes.mdl");
			
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_moveslow_loop1.wav", iRollerMine);
			EmitSoundToAll("npc/roller/mine/rmine_movefast_loop1.wav", iRollerMine);
			
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("npc/roller/mine/rmine_blades_out1.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 2: EmitSoundToAll("npc/roller/mine/rmine_blades_out2.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 3: EmitSoundToAll("npc/roller/mine/rmine_blades_out3.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
			}
			
			#if defined DEBUG
			PrintToChatAll("OPEN");
			#endif
		}
		case STATE_STUNNED:
		{
			SetEntityModel(iRollerMine, "models/roller_spikes.mdl");

			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_seek_loop2.wav", iRollerMine);

			#if defined DEBUG
			PrintToChatAll("STUNNED");
			#endif
			
			SetRollerFlags(iRollerMine, ROLLERMINE_SE_CLEAR);
		}
	}
	
	SetEntProp(iRollerMine, Prop_Data, "m_nBody", iState);
}

stock int GetRollerState(int iRollerMine)
{
	return GetEntProp(iRollerMine, Prop_Data, "m_nBody");
}

stock void ShockTarget(int iRollermine, int iTarget)
{
/*	float flEntPos[3];
	GetEntPropVector(iRollermine, Prop_Data, "m_vecAbsOrigin", flEntPos);

	float flTargetPos[3];
	GetClientEyePosition(iTarget, flTargetPos);*/
	
	TE_SetupBeamLaser(iRollermine, iTarget, g_iShockIndex, g_iShockHaloIndex, 0, 1, 0.5, 16.0, 16.0, 300, 16.0, {255, 255, 255, 255}, 1);
	TE_SendToAll();
}

stock int Entity_GetClosestClient(int iEnt)
{
	float flPos1[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", flPos1);
	
	int iBestTarget = -1;
	float flBestLength = g_hRollerAttackDist.FloatValue;

	int team = GetEntProp(iEnt, Prop_Send, "m_iTeamNum", 4);
	int owner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && Entity_Cansee(iEnt, i) && IsPlayerAlive(i) &&
		   (team == 0 || GetClientTeam(i) != team || i == owner))
		{
			float flPos2[3];
			GetClientEyePosition(i, flPos2);
			
			float flDistance = GetVectorDistance(flPos1, flPos2);

			if(flDistance < flBestLength)
			{
				iBestTarget = i;
				flBestLength = flDistance;
			}
		}
	}
	
	if(iBestTarget > 0 && iBestTarget <= MaxClients && IsClientInGame(iBestTarget))
	{
		return iBestTarget;
	}
	
	return iBestTarget;
}

stock bool Entity_Cansee(int iEnt, int iClient)
{
	if(TF2_IsPlayerInCondition(iClient, TFCond_Disguised) || TF2_IsPlayerInCondition(iClient, TFCond_Cloaked)
	|| TF2_IsPlayerInCondition(iClient, TFCond_Stealthed) || TF2_IsPlayerInCondition(iClient, TFCond_CloakFlicker)
	|| TF2_IsPlayerInCondition(iClient, TFCond_DeadRingered) || TF2_GetClientTeam(iClient) == TFTeam_Spectator)
		return false;
	
	float flStart[3], flEnd[3];
	GetClientEyePosition(iClient, flEnd);
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", flStart);
	
	flStart[2] += 10.0;
	
	bool bSee = true;
	Handle hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterSelf, iEnt);
	if(hTrace != INVALID_HANDLE)
	{
		if(TR_DidHit(hTrace))
			bSee = false;
			
		CloseHandle(hTrace);
	}
	
	return bSee;
}

public bool TraceFilterSelf(int entity, int contentsMask, any iPumpking)
{
	if(entity == iPumpking || entity > MaxClients || (entity >= 1 && entity <= MaxClients))
		return false;
	
	return true;
}


public int Native_ControlRM(Handle plugin, int numParams)
{
    g_NativeControl = GetNativeCell(1);
}

public int Native_SetRollermine(Handle plugin, int numParams)
{
    PlaceRollerMine(GetNativeCell(1));
}

public int Native_SpawnRollerMine(Handle plugin, int numParams)
{
	float pos[3];
	GetNativeArray(2, pos, sizeof(pos));
	SpawnRollerMine(GetNativeCell(1), pos);
}

