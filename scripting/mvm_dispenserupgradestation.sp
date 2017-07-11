#pragma semicolon 1
#include <sourcemod>
#include <tf2>
//#include <mdebug>
#include <sdkhooks>
#include <sdktools>
#include <entity_flags>

#define PLUGIN_VERSION  "1.0.0"

#define PLUGIN_NAME  "[TF2-MvM] Dispenser Upgrade Station"
#define PLUGIN_AUTHOR  "[GNC] Matt"
#define PLUGIN_DESCRIPTION  "Creates an upgrade station on engineer dispensers."
#define PLUGIN_URL  "http://www.mattsfiles.com"


public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

new Handle:g_hDispenserUpgradeStations = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_dispenserupgradestation_version", PLUGIN_VERSION, "Dispenser Upgrade Station Version.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("player_builtobject", OnBuiltObject);
	HookEvent("player_carryobject", OnPickupObject);
	
	g_hDispenserUpgradeStations = CreateTrie();
}

public OnMapStart()
{
	PrecacheModel("models/props_hydro/road_bumper01.mdl");
}

public Action:OnBuiltObject(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	// new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new obj = GetEventInt(hEvent, "object");
	new entity = GetEventInt(hEvent, "index");
	
	if(obj != 0) return Plugin_Continue;
	
	new entindex = CreateEntityByName("func_upgradestation");
	if(entindex == -1) return Plugin_Continue;
	DispatchKeyValue(entindex, "StartDisabled", "0");
	DispatchSpawn(entindex);
	ActivateEntity(entindex);
	
	decl Float:objpos[3]; GetEntPropVector(entity, Prop_Data, "m_vecOrigin", objpos);
	TeleportEntity(entindex, objpos, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(entindex, "models/props_hydro/road_bumper01.mdl");

	SetEntPropVector(entindex, Prop_Send, "m_vecMins", Float:{-30.0, -30.0, 0.0}); 
	SetEntPropVector(entindex, Prop_Send, "m_vecMaxs", Float:{30.0, 30.0, 100.0}); 
	SetEntProp(entindex, Prop_Send, "m_nSolidType", SOLID_BBOX);
	
	new enteffects = GetEntProp(entindex, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(entindex, Prop_Send, "m_fEffects", enteffects);
	
	decl String:key[8]; Format(key, sizeof(key), "%i", EntIndexToEntRef(entity));
	SetTrieValue(g_hDispenserUpgradeStations, key, entindex);

	return Plugin_Continue;
}

public OnEntityDestroyed(entity)
{
	if(!IsValidEntity(entity)) return;
	decl String:classname[64]; GetEntityClassname(entity, classname, sizeof(classname));
	
	if(StrEqual(classname, "obj_dispenser"))
	{
		RemoveUpgradeStation(entity);
	}
}

public Action:OnPickupObject(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	new entity = GetEventInt(hEvent, "index");
	
	RemoveUpgradeStation(entity);
	return Plugin_Continue;
}

stock RemoveUpgradeStation(dispenser)
{
	new upgradestation;
	decl String:key[8]; Format(key, sizeof(key), "%i", EntIndexToEntRef(dispenser));
	if(GetTrieValue(g_hDispenserUpgradeStations, key, upgradestation))
	{
		if(IsValidEntity(upgradestation))
		{
			AcceptEntityInput(upgradestation, "Kill");
		}
		RemoveFromTrie(g_hDispenserUpgradeStations, key);
	}
}