#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <fortwars>

public Plugin:myinfo = 
{
	name = "[FWP] Health Kit",
	author = "Matheus28",
	description = "",
	version = "1.0",
	url = ""
}

new FWAProp:myId=INVALID_APROP;

public OnPluginStart(){
	if(LibraryExists("fortwars")){
		AddMe();
	}
}

public OnLibraryAdded(const String:name[]){
	if(StrEqual(name, "fortwars")){
		AddMe();
	}
}

public AddMe(){
	FW_AddDependence();
	myId = FW_AddProp("Small Health Kit", "models/items/medkit_small.mdl", 3, 200);
}

public OnPropBuilt(builder, ent, FWProp:prop, FWAProp:propid, const Float:pos[3], const Float:ang[3]){
	if(propid==myId){
		new nEnt = SpawnHealthKit(GetClientTeam(builder), "item_healthkit_small", pos);
		FW_SetPropEntity(prop, nEnt);
		RemoveEdict(ent);
	}
}

stock SpawnHealthKit(team, String:name[], const Float:pos[3]){
	new ent = CreateEntityByName(name);
	HookSingleEntityOutput(ent, "OnPlayerTouch", OnPlayerTouch);
	DispatchSpawn(ent)
	SetEntProp(ent, Prop_Send, "m_iTeamNum", team);
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	return ent;
}

public OnPlayerTouch(const String:output[], caller, activator, Float:delay){
	new FWProp:prop = FW_GetEntityProp(caller);
	if(prop==INVALID_PROP) return;
	
	FW_PropDestroyed(prop);
	AcceptEntityInput(caller, "Kill");
}