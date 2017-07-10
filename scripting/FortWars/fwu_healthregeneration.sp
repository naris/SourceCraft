#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <fortwars>

public Plugin:myinfo = 
{
	name = "[FWU] Health Regeneration",
	author = "Matheus28",
	description = "",
	version = "1.0",
	url = ""
}

new regenId=1;
new maxHealth[MAXPLAYERS+1];
new lastHurt[MAXPLAYERS+1];

public OnPluginStart(){
	if(LibraryExists("fortwars")){
		AddUnlock();
	}
	
	CreateTimer(1.0, Timer_HealthRegen, _, TIMER_REPEAT);
	
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_hurt", player_hurt);
}

public OnLibraryAdded(const String:name[]){
	if(StrEqual(name, "fortwars")){
		AddUnlock();
	}
}

public AddUnlock(){
	FW_AddDependence();
	regenId = FW_AddUnlock2("healthregen", "Health Regeneration", 3, {5000, 5000, 5000});
}


public Action:player_spawn(Handle:event,  const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	maxHealth[client]=0;
	CreateTimer(0.1, Timer_RegHealth, client);
}

public Action:player_hurt(Handle:event,  const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	lastHurt[client]=GetTime();
}

public Action:Timer_RegHealth(Handle:timer, any:data){
	if(!IsClientInGame(data) || !IsPlayerAlive(data)) return;
	maxHealth[data] = GetClientHealth(data);
}

public Action:Timer_HealthRegen(Handle:timer){
	if(regenId==-1) return;
	if(!FW_IsRunning()) return;
	
	
	new time=GetTime()-5;
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		new lvl = FW_HasUnlock(i, regenId);
		if(lvl==0) continue;
		if(lastHurt[i]>time) continue;
		
		new fh=GetClientHealth(i);
		if(fh>=maxHealth[i]) continue;
		fh+=lvl;
		if(fh>=maxHealth[i]) fh=maxHealth[i];
		SetEntityHealth(i, fh);
	}
}