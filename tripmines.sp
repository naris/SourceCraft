#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0.2"

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"
#define MDL_MINE "models/props_lab/tpplug.mdl"

#define SND_MINE "npc/roller/mine/rmine_blades_in2.wav"

// globals
new gRemaining[MAXPLAYERS+1];                 // how many tripmines player has this spawn
new gCount = 1;

// convars
new Handle:cvNumMines = INVALID_HANDLE;


public Plugin:myinfo = {
	name = "Tripmines",
	author = "L. Duke",
	description = "Plant a trip mine",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};


public OnPluginStart() 
{ 
  // events
  HookEvent("player_spawn",PlayerSpawn);
  
  // convars
  CreateConVar("sm_tripmines_version", PLUGIN_VERSION, "Tripmines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  cvNumMines = CreateConVar("sm_tripmines_allowed","3");
  
  // commands
  RegConsoleCmd("sm_tripmine", Command_TripMine);
  
}



public OnEventShutdown()
{
	UnhookEvent("player_spawn",PlayerSpawn);
}



public OnMapStart()
{
  // precache models
  PrecacheModel(MDL_MINE, true);
  PrecacheModel(MDL_LASER, true);
  
  // precache sounds
  PrecacheSound(SND_MINE, true);
}



public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	gRemaining[client] = GetConVarInt(cvNumMines);
	return Plugin_Continue;
}



public Action:Command_TripMine(client, args)
{  
  // make sure client is not spectating
  if (!IsPlayerAlive(client))
    return Plugin_Handled;
   
  if (gRemaining[client]>0) {
    SetMine(client);
  }
  else {
    PrintHintText(client, "You do not have any tripmines.");
  }
  return Plugin_Handled;
}


SetMine(client)
{
  // setup unique target names for entities to be created with
  new String:beam[64];
  new String:beammdl[64];
  new String:tmp[128];
  Format(beam, sizeof(beam), "tmbeam%d", gCount);
  Format(beammdl, sizeof(beammdl), "tmbeammdl%d", gCount);
  gCount++;
  if (gCount>10000)
  {
    gCount = 1;
  }
  
  // trace client view to get position and angles for tripmine
  
  decl Float:start[3], Float:angle[3], Float:end[3], Float:normal[3], Float:beamend[3];
  GetClientEyePosition( client, start );
  GetClientEyeAngles( client, angle );
  GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
  NormalizeVector(end, end);

  start[0]=start[0]+end[0]*TRACE_START;
  start[1]=start[1]+end[1]*TRACE_START;
  start[2]=start[2]+end[2]*TRACE_START;
  
  end[0]=start[0]+end[0]*TRACE_END;
  end[1]=start[1]+end[1]*TRACE_END;
  end[2]=start[2]+end[2]*TRACE_END;
  
  TR_TraceRayFilter(start, end, CONTENTS_SOLID, RayType_EndPoint, FilterAll, 0);
  
  if (TR_DidHit(INVALID_HANDLE))
  {
    // update client's inventory
    gRemaining[client]-=1;
    
    // find angles for tripmine
    TR_GetEndPosition(end, INVALID_HANDLE);
    TR_GetPlaneNormal(INVALID_HANDLE, normal);
    GetVectorAngles(normal, normal);
    
    // trace laser beam
    TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
    TR_GetEndPosition(beamend, INVALID_HANDLE);
    
    // create tripmine model
    new ent = CreateEntityByName("prop_physics_override");
    SetEntityModel(ent,MDL_MINE);
    DispatchKeyValue(ent, "StartDisabled", "false");
    DispatchSpawn(ent);
    TeleportEntity(ent, end, normal, NULL_VECTOR);
    SetEntProp(ent, Prop_Data, "m_usSolidFlags", 152);
    SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
    SetEntityMoveType(ent, MOVETYPE_NONE);
    SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
    SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
    SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
    DispatchKeyValue(ent, "targetname", beammdl);
    DispatchKeyValue(ent, "ExplodeRadius", "256");
    DispatchKeyValue(ent, "ExplodeDamage", "400");
    Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
    DispatchKeyValue(ent, "OnHealthChanged", tmp);
    Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", beam);
    DispatchKeyValue(ent, "OnBreak", tmp);
    SetEntProp(ent, Prop_Data, "m_takedamage", 2);
    AcceptEntityInput(ent, "Enable");

    
    // create laser beam
    ent = CreateEntityByName("env_beam");
    TeleportEntity(ent, beamend, NULL_VECTOR, NULL_VECTOR);
    SetEntityModel(ent, MDL_LASER);
    DispatchKeyValue(ent, "texture", MDL_LASER);
    DispatchKeyValue(ent, "targetname", beam);
    DispatchKeyValue(ent, "TouchType", "4");
    DispatchKeyValue(ent, "LightningStart", beam);
    DispatchKeyValue(ent, "BoltWidth", "4.0");
    DispatchKeyValue(ent, "life", "0");
    DispatchKeyValue(ent, "rendercolor", "0 0 0");
    DispatchKeyValue(ent, "renderamt", "0");
    DispatchKeyValue(ent, "HDRColorScale", "1.0");
    DispatchKeyValue(ent, "decalname", "Bigshot");
    DispatchKeyValue(ent, "StrikeTime", "0");
    DispatchKeyValue(ent, "TextureScroll", "35");
    Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
    DispatchKeyValue(ent, "OnTouchedByEntity", tmp);   
    SetEntPropVector(ent, Prop_Data, "m_vecEndPos", end);
    SetEntPropFloat(ent, Prop_Data, "m_fWidth", 4.0);
    AcceptEntityInput(ent, "TurnOff");
    CreateTimer(1.0, TurnBeamOn, ent);
    
    // play sound
    EmitSoundToAll(SND_MINE, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
    
    // send message
    PrintHintText(client, "Tripmines remaining: %d", gRemaining[client]);
  }
  else
  {
    PrintHintText(client, "could find a valid location to put tripmine");
  } 
}

public Action:TurnBeamOn(Handle:timer, any:ent)
{
  if (IsValidEntity(ent))
  {
    DispatchKeyValue(ent, "rendercolor", "0 255 255");
    AcceptEntityInput(ent, "TurnOn");
  }
}

public bool:FilterAll (entity, contentsMask)
{
  return false;
}

