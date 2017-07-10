#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#include <fortwars>

public Plugin:myinfo = 
{
	name = "[FWU] Class Unlocks",
	author = "Matheus28",
	description = "",
	version = "",
	url = ""
}

new soldier=-1;
new pyro=-1;
new demoman=-1;
new heavy=-1;
new engineer=-1;
new medic=-1;
new sniper=-1;
new spy=-1;

new Handle:cv_soldier;
new Handle:cv_pyro;
new Handle:cv_demoman;
new Handle:cv_heavy;
new Handle:cv_engineer;
new Handle:cv_medic;
new Handle:cv_sniper;
new Handle:cv_spy;

new Handle:cv_soldier_price;
new Handle:cv_pyro_price;
new Handle:cv_demoman_price;
new Handle:cv_heavy_price;
new Handle:cv_engineer_price;
new Handle:cv_medic_price;
new Handle:cv_sniper_price;
new Handle:cv_spy_price;

public OnPluginStart(){
	HookEvent("player_changeclass", player_changeclass, EventHookMode_Pre);
	
	cv_soldier=CreateConVar("fw_unlock_soldier", "1", "Enable the Soldier unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_pyro=CreateConVar("fw_unlock_pyro", "1", "Enable the Pyro unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_demoman=CreateConVar("fw_unlock_demoman", "1", "Enable the Demoman unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_heavy=CreateConVar("fw_unlock_heavy", "1", "Enable the Heavy unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_engineer=CreateConVar("fw_unlock_engineer", "1", "Enable the Engineer unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_medic=CreateConVar("fw_unlock_medic", "1", "Enable the Medic unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_sniper=CreateConVar("fw_unlock_sniper", "1", "Enable the Sniper unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_spy=CreateConVar("fw_unlock_spy", "1", "Enable the Spy unlock", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookConVarChange(cv_soldier, CC_UnlockEnable);
	HookConVarChange(cv_pyro, CC_UnlockEnable);
	HookConVarChange(cv_demoman, CC_UnlockEnable);
	HookConVarChange(cv_heavy, CC_UnlockEnable);
	HookConVarChange(cv_engineer, CC_UnlockEnable);
	HookConVarChange(cv_medic, CC_UnlockEnable);
	HookConVarChange(cv_sniper, CC_UnlockEnable);
	HookConVarChange(cv_spy, CC_UnlockEnable);
	
	cv_soldier_price=CreateConVar("fw_unlock_soldier_price", "5000", "Price to buy the soldier unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);
	cv_pyro_price=CreateConVar("fw_unlock_pyro_price", "3500", "Price to buy the pyro unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);
	cv_demoman_price=CreateConVar("fw_unlock_demoman_price", "6000", "Price to buy the demoman unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);
	cv_heavy_price=CreateConVar("fw_unlock_heavy_price", "7000", "Price to buy the heavy unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);
	cv_engineer_price=CreateConVar("fw_unlock_engineer_price", "5000", "Price to buy the engineer unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);
	cv_medic_price=CreateConVar("fw_unlock_medic_price", "2000", "Price to buy the medic unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);
	cv_sniper_price=CreateConVar("fw_unlock_sniper_price", "4000", "Price to buy the sniper unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);
	cv_spy_price=CreateConVar("fw_unlock_spy_price", "4500", "Price to buy the spy unlock", FCVAR_PLUGIN, true, 1.0, true, 999999.0);

	if(LibraryExists("fortwars")){
		AddUnlocks();
	}
}

public OnLibraryAdded(const String:name[]){
	if(StrEqual(name, "fortwars")){
		AddUnlocks();
	}
}

public CC_UnlockEnable(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(convar==cv_soldier){
		if(GetConVarBool(cv_soldier)){
			FW_AddUnlock("soldier", "Soldier", GetConVarInt(cv_soldier_price));
		}else{
			FW_RemoveUnlock("soldier");
		}
	}else if(convar==cv_pyro){
		if(GetConVarBool(cv_pyro)){
			FW_AddUnlock("pyro", "Pyro", GetConVarInt(cv_pyro_price));
		}else{
			FW_RemoveUnlock("pyro");
		}
	}else if(convar==cv_demoman){
		if(GetConVarBool(cv_demoman)){
			FW_AddUnlock("demoman", "Demoman", GetConVarInt(cv_demoman_price));
		}else{
			FW_RemoveUnlock("demoman");
		}
	}else if(convar==cv_heavy){
		if(GetConVarBool(cv_heavy)){
			FW_AddUnlock("heavy", "Heavy", GetConVarInt(cv_heavy_price));
		}else{
			FW_RemoveUnlock("heavy");
		}
	}else if(convar==cv_engineer){
		if(GetConVarBool(cv_engineer)){
			FW_AddUnlock("engineer", "Engineer", GetConVarInt(cv_engineer_price));
		}else{
			FW_RemoveUnlock("engineer");
		}
	}else if(convar==cv_medic){
		if(GetConVarBool(cv_medic)){
			FW_AddUnlock("medic", "Medic", GetConVarInt(cv_medic_price));
		}else{
			FW_RemoveUnlock("medic");
		}
	}else if(convar==cv_sniper){
		if(GetConVarBool(cv_sniper)){
			FW_AddUnlock("sniper", "Sniper", GetConVarInt(cv_sniper_price));
		}else{
			FW_RemoveUnlock("sniper");
		}
	}else if(convar==cv_spy){
		if(GetConVarBool(cv_spy)){
			FW_AddUnlock("spy", "Spy", GetConVarInt(cv_spy_price));
		}else{
			FW_RemoveUnlock("spy");
		}
	}
}

public AddUnlocks(){
	FW_AddDependence();
	if(GetConVarBool(cv_soldier))
		soldier =	FW_AddUnlock("soldier", "Soldier", GetConVarInt(cv_soldier_price));
	
	if(GetConVarBool(cv_pyro))
		pyro = 		FW_AddUnlock("pyro", "Pyro", GetConVarInt(cv_pyro_price));
	
	if(GetConVarBool(cv_demoman))
		demoman = 	FW_AddUnlock("demoman", "Demoman", GetConVarInt(cv_demoman_price));
	
	if(GetConVarBool(cv_heavy))
		heavy = 	FW_AddUnlock("heavy", "Heavy", GetConVarInt(cv_heavy_price));
	
	if(GetConVarBool(cv_engineer))
		engineer = 	FW_AddUnlock("engineer", "Engineer", GetConVarInt(cv_engineer_price));
	
	if(GetConVarBool(cv_medic))
		medic = 	FW_AddUnlock("medic", "Medic", GetConVarInt(cv_medic_price));
	
	if(GetConVarBool(cv_sniper))
		sniper = 	FW_AddUnlock("sniper", "Sniper", GetConVarInt(cv_sniper_price));
	
	if(GetConVarBool(cv_spy))
		spy = 		FW_AddUnlock("spy", "Spy", GetConVarInt(cv_spy_price));
	
}

public RemoveUnlocks(){
	soldier=-1;
	pyro=-1;
	demoman=-1;
	heavy=-1;
	engineer=-1;
	medic=-1;
	sniper=-1;
	spy=-1;
	FW_RemoveUnlock("soldier");
	FW_RemoveUnlock("pyro");
	FW_RemoveUnlock("demoman");
	FW_RemoveUnlock("heavy");
	FW_RemoveUnlock("engineer");
	FW_RemoveUnlock("medic");
	FW_RemoveUnlock("sniper");
	FW_RemoveUnlock("spy");
}

public Action:player_changeclass(Handle:event,  const String:name[], bool:dontBroadcast) {
	if(!FW_IsRunning()) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	switch(class){
		case TFClass_Soldier:{
			if(soldier>-1 && !FW_HasUnlock(client, soldier)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
		case TFClass_Pyro:{
			if(pyro>-1 && !FW_HasUnlock(client, pyro)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
		case TFClass_DemoMan:{
			if(demoman>-1 && !FW_HasUnlock(client, demoman)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
		case TFClass_Heavy:{
			if(heavy>-1 && !FW_HasUnlock(client, heavy)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
		case TFClass_Engineer:{
			if(engineer>-1 && !FW_HasUnlock(client, engineer)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
		case TFClass_Medic:{
			if(medic>-1 && !FW_HasUnlock(client, medic)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
		case TFClass_Sniper:{
			if(sniper>-1 && !FW_HasUnlock(client, sniper)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
		case TFClass_Spy:{
			if(spy>-1 && !FW_HasUnlock(client, spy)){
				BlockClass(client);
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

public BlockClass(client){
	TF2_SetPlayerClass(client, TFClass_Scout);
	PrintToChat(client, "%s You haven't unlocked that class yet. Type \x03/fwmenu\x01 to go to the unlocks menu", FORTWARS_PREFIX);
}