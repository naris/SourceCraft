#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <fortwars>

public Plugin:myinfo = 
{
	name = "[FW] Fly Mode",
	author = "Matheus28",
	description = "",
	version = "1.0",
	url = ""
}

new bool:flymode[MAXPLAYERS+1];
new Float:tickInterval;

public OnPluginStart(){
	tickInterval=GetTickInterval();
	
	HookEvent("player_death", player_death);
	
	if(LibraryExists("fortwars")){
		AddMe();
	}
}

public OnLibraryAdded(const String:name[]){
	if(StrEqual(name, "fortwars")){
		AddMe();
	}
}

public OnPluginEnd(){
	RemoveMe();
}

public OnGameFrame(){
	if(!FW_IsRunning()) return;
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!flymode[i]) continue;
		if(!IsPlayerAlive(i)) continue;
		
		new Float:vel[3];
		GetEntPropVector(i, Prop_Data, "m_vecAbsVelocity", vel);
		new Float:length=GetVectorLength(vel);
		if(length>200.0){
			new Float:s=200.0/GetVectorLength(vel);
			vel[0] = vel[0] * s;
			vel[1] = vel[1] * s;
			vel[2] = vel[2] * s;
		}
		vel[0] = vel[0] * (1.0 - (2.0*tickInterval));
		vel[1] = vel[1] * (1.0 - (2.0*tickInterval));
		vel[2] = vel[2] * (1.0 - (2.0*tickInterval));
		TeleportEntity(i,NULL_VECTOR,NULL_VECTOR,vel);
		
	}
}

public AddMe(){
	FW_AddDependence();
	FW_AddMenuItem("flymode", "Toggle Fly Mode", true, ToggleFly);
}

public RemoveMe(){
	FW_RemoveMenuItem("flymode");
}

public Action:player_death(Handle:event,  const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	TurnFlyOff(client);
}

public OnClientConnected(client){
	flymode[client]=false;
}

public OnBuildEnd(){
	for(new i=1;i<=MaxClients;++i){
		if(flymode[i]) TurnFlyOff(i);
	}
}

public TurnFlyOn(i){
	if(!IsClientInGame(i)) return;
	if(!IsPlayerAlive(i)) return;
	SetEntityMoveType(i, MOVETYPE_FLY);
	flymode[i]=true;
}

public TurnFlyOff(i){
	flymode[i]=false;
	if(!IsClientInGame(i)) return;
	if(!IsPlayerAlive(i)) return;
	SetEntityMoveType(i, MOVETYPE_WALK);
}

public ToggleFly(i){
	if(flymode[i]){
		TurnFlyOff(i);
	}else{
		TurnFlyOn(i);
	}
	FW_ShowMainMenu(i);
}