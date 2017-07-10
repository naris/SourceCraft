#include <sourcemod>
#include <sdktools>
#include <fortwars>

public Plugin:myinfo = 
{
    name = "[FW] Menu On Round Start",
    author = "Matheus28",
    description = "",
    version = "1.0",
    url = ""
}


public OnPluginStart(){
	if(LibraryExists("fortwars")){
		Register();
	}
}


public OnLibraryAdded(const String:name[]){
	if(StrEqual(name, "fortwars")){
		Register();
	}
}

public Register(){
	FW_AddDependence();
}

public OnBuildStart(){
    for(new i=1;i<=MaxClients;++i){
        FW_ShowMainMenu(i);
    }
}