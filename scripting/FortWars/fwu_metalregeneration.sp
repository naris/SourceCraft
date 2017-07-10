#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <fortwars>

public Plugin:myinfo = 
{
	name = "[FWU] Metal Regeneration",
	author = "Matheus28",
	description = "",
	version = "1.0",
	url = ""
}

new regenId=1;

public OnPluginStart(){
	if(LibraryExists("fortwars")){
		AddUnlock();
	}
	
	CreateTimer(1.0, Timer_MetalRegen, _, TIMER_REPEAT);
}

public OnAllPluginsLoaded(){
	new Handle:cvar = FindConVar("fw_unlock_engineer");
	if(cvar!=INVALID_HANDLE){
		HookConVarChange(cvar, CC_UnlockEnable);
		if(!GetConVarBool(cvar)){
			RemoveUnlock();
		}
	}
}

public OnLibraryAdded(const String:name[]){
	if(StrEqual(name, "fortwars")){
		AddUnlock();
	}
}

public AddUnlock(){
	FW_AddDependence();
	regenId = FW_AddUnlock2("metalregen", "Metal Regeneration (Engineer)", 3, {2500, 5000, 2500}, "engineer");
}

public RemoveUnlock(){
	regenId = -1;
	FW_RemoveUnlock("metalregen");
}

public CC_UnlockEnable(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarBool(convar)){
		AddUnlock();
	}else{
		RemoveUnlock();
	}
}

public Action:Timer_MetalRegen(Handle:timer){
	if(regenId==-1) return;
	if(!FW_IsRunning()) return;
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(TF2_GetPlayerClass(i)!=TFClass_Engineer) continue;
		
		new lvl = FW_HasUnlock(i, regenId);
		if(lvl==0) continue;
		
		new fh=TF2_GetClientMetal(i);
		if(fh>=200) continue;
		fh+=RoundToZero(lvl*1.5);
		if(fh>=200) fh=200;
		TF2_SetClientMetal(i, fh);
	}
}

public TF2_GetClientMetal(client){
	return GetEntData(client, FindDataMapOffs(client, "m_iAmmo")+(3*4), 4);
}

public TF2_SetClientMetal(client, amount){
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo")+(3*4), amount, 4, true);
}