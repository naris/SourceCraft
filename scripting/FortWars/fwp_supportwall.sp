#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <fortwars>

public Plugin:myinfo = 
{
	name = "[FWP] Support Wall",
	author = "Matheus28",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart(){
	if(LibraryExists("fortwars")){
		Loaded();
	}
}

public OnLibraryAdded(const String:name[]){
	if(StrEqual(name, "fortwars")){
		Loaded();
	}
}

public Loaded(){
	FW_AddDependence();
	FW_AddProp("Support Wall",	"models/props_mining/support_wall001a.mdl",	FORTWARS_HEALTH_VERYHIGH,	150, 2);
}