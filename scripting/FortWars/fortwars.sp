/*////////////////////////////////////////////////////////////////////////////
 * 		This plugin was created by Matheus28 (M28, for short)
 * 
 * 		Do not remove credits, if you modify the plugin, add "MODIFIED" to
 * the PLUGIN_VERSION, this will help me to keep track of the plugin version
 * running on servers.
 *
 *////////////////////////////////////////////////////////////////////////////
//

#include <fortwars>
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "6.12"
//#define PLUGIN_VERSION "6.12 MODIFIED"

#define PLUGIN_PREFIX FORTWARS_PREFIX

// 300 is already enough to cause an reliable snapshot overflow,
// I'll leave 400 for people that build on a local server
#define MAX_PROPS_PER_TEAM FORTWARS_MAX_PROPS_PER_TEAM
#define PROPS_ARRAY_SIZE FORTWARS_PROPS_ARRAY_SIZE


#define MAX_PLUGINS 256
#define MAX_UNLOCKS 128
#define MAX_MENUI 64
#define MAX_UNLOCK_LEVEL FORTWARS_MAX_UNLOCK_LEVEL


#define MONEY_LIMIT 999999
#define MONEY_MIN_DONATION 500

#define MONEY_IMPRECISION_MIN 0.75
#define MONEY_IMPRECISION_MAX 1.25


#define MAX_DISTANCE_CREATE_PROP 512.0

#define OBJECTIVE_INTEL_MIN_DISTANCE 256.0
#define OBJECTIVE_CP_MIN_SIZE 256.0


#define HEALTH_VERYLOW FORTWARS_HEALTH_VERYLOW
#define HEALTH_LOW FORTWARS_HEALTH_LOW
#define HEALTH_MEDIUM FORTWARS_HEALTH_MEDIUM
#define HEALTH_HIGH FORTWARS_HEALTH_HIGH
#define HEALTH_VERYHIGH FORTWARS_HEALTH_VERYHIGH
#define HEALTH_EXTREME FORTWARS_HEALTH_EXTREME

#define PROP_NUM FORTWARS_MAX_APROPS
#define DPROP_NUM 64

#define DPROP_LIMIT 16

#define MASK_CUSTOM (CONTENTS_SOLID)

#define TICK_INTERVAL 0.5

#define INVALID_ENT -1

// Enums

enum TextColor{
	White,
	Team,
	Red,
	Blue,
	DarkTeam,
	DarkRed,
	DarkBlue,
	Green,
	Black,
	Yellow
}

enum Channel{
	Error=0,
	Money,
	RedProps,
	BlueProps,
	Owner,
	Phase
}

// Avaliable Props
new aPropsCount=0;
new bool:aPropsValid[FWAProp];
new String:aPropsName[FWAProp][64];
new String:aPropsPath[FWAProp][MAX_TARGET_LENGTH];
new aPropsHealth[FWAProp];
new aPropsCost[FWAProp];
new bool:aPropsStick[FWAProp];
new Float:aPropsPosOffset[FWAProp][3];
new Float:aPropsAnglesOffset[FWAProp][3];
new aPropsCountAs[FWAProp];

new bool:aPropsDynamic[PROP_NUM];
new aPropsDynamicId[PROP_NUM];
new aPropsDynamicCount[PROP_NUM];

new aDynamicPropsCount=0;
new String:aPropsDynamicPath[DPROP_NUM][DPROP_LIMIT][MAX_TARGET_LENGTH];

// Props in-game
new propsCount=0;
new props[FWProp]={-1};
new propsOwner[FWProp];
new propsType[FWProp];
new TFTeam:propsTeam[FWProp];
new Float:propsAng[FWProp][3];
new Float:propsPos[FWProp][3];
new bool:propsNotSolid[FWProp];
new bool:propsTeleport[FWProp];
new bool:propsRefund[FWProp];

// Props count
new propsTeamCount[TFTeam];
new propsTeamCountStart[TFTeam]={0, ...};


// Unlocks
new bool:unlocksValid[MAX_UNLOCKS];
new String:unlocksId[MAX_UNLOCKS][64];
new String:unlocksName[MAX_UNLOCKS][128];
new unlocksCost[MAX_UNLOCKS][MAX_UNLOCK_LEVEL];
new unlocksMaxLevel[MAX_UNLOCKS];
new unlocksRequire[MAX_UNLOCKS];
new unlocksRequireLevel[MAX_UNLOCKS];
new unlocksCount=0;

// Custom Menu Items
new bool:menuiValid[MAX_MENUI];
new String:menuiId[MAX_MENUI][64];
new String:menuiName[MAX_MENUI][128];
new bool:menuiBuildOnly[MAX_MENUI];
new Handle:menuiCallback[MAX_MENUI] = {INVALID_HANDLE, ...};
new menuiCount=0;

// API
new Handle:fwd_buildstart;
new Handle:fwd_buildend;
new Handle:fwd_propbuilt;
new Handle:fwd_propbuilt_pre;
new Handle:fwd_proprotated;
new Handle:fwd_propdestroyed;

new myPluginsCount=0;
new Handle:myPlugins[MAX_PLUGINS];

// Client
new propsPlayerCount[MAXPLAYERS+1];
new money[MAXPLAYERS+1];
new selectedEntRef[MAXPLAYERS+1];
new rotationAxis[MAXPLAYERS+1];
new bool:hasCustomSpawnPoint[MAXPLAYERS+1];
new Float:spawnPointPos[MAXPLAYERS+1][3];
new Float:spawnPointAng[MAXPLAYERS+1][3];
new bool:respawn[MAXPLAYERS+1];
new bool:clearSpawn[MAXPLAYERS+1];
new bool:teleport[MAXPLAYERS+1];
new Float:teleportPos[MAXPLAYERS+1][3];
new Float:teleportAng[MAXPLAYERS+1][3];
new moneyOffset[MAXPLAYERS+1];
new unlock[MAXPLAYERS+1][MAX_UNLOCKS];
new Float:spawnPos[MAXPLAYERS+1][3];
new bool:canReceiveWinMoney[MAXPLAYERS+1]
new moneyAdded[MAXPLAYERS+1];
new moneySpentOnProps[MAXPLAYERS+1];
new canSaveMoney[MAXPLAYERS+1];

// Misc
new String:sError[256];
new bool:started=false;
new bool:playing;
new setupTime;
new inSetup;
new Handle:tickTimer;
new bool:sql=false;
new bool:connecting=false;
new Handle:hSql=INVALID_HANDLE;
new Handle:saveMoneyTimer;
new bool:lateLoad;
new bool:teamCanBuild[TFTeam];
new bool:noPlayerLimit;
new Float:setupTimeLeft;
new timerEnt=-1;
new bool:needSetupTimer;
new debugSprite;


#define MAX_NOBUILD 128
new nobuildCount=0;
new Float:nobuildPosMin[MAX_NOBUILD][3];
new Float:nobuildPosMax[MAX_NOBUILD][3];
new NB:nobuildReason[MAX_NOBUILD];
enum NB{
	NB_CanBuild=0,
	NB_Map,
	NB_Intel,
	NB_CP,
	NB_Respawn
}

// Convars
new Handle:cv_sql;
new Handle:cv_maps;
new Handle:cv_max_team;
new Handle:cv_max_player;
new Handle:cv_max_player_admin;
new Handle:cv_spawn_protection;
new Handle:cv_custom_spawn;
new Handle:cv_stuck_protection;
new Handle:cv_health_multipler;
new Handle:cv_shadows;
new Handle:cv_setup;
new Handle:cv_max_free;
new Handle:cv_lulz // i did it for teh lulz
new Handle:cv_unlock_menu_style

new Handle:cv_money_start;
new Handle:cv_money_win;
new Handle:cv_money_kill;
new Handle:cv_money_domination;
new Handle:cv_money_headshot;
new Handle:cv_money_backstab;
new Handle:cv_money_dispenser;
new Handle:cv_money_sentry;
new Handle:cv_money_balance;


stock LoadProps(){
	decl Float:tmp[3];
	
	DefineProp("Pipe",			"models/props_farm/concrete_pipe001.mdl", 	HEALTH_MEDIUM,	40);
	
	new FWAProp:barrel= DefineProp("Barrel", "", HEALTH_LOW, 20, _, false, true);
	DefineDynamicPropPath(barrel, "models/props_badlands/barrel01.mdl");
	DefineDynamicPropPath(barrel, "models/props_badlands/barrel02.mdl");
	DefineDynamicPropPath(barrel, "models/props_badlands/barrel03.mdl");
	
	tmp[0] = 0.0;
	tmp[1] = 0.0;
	tmp[2] = -4.8;
	DefineProp("Pallet",		"models/props_farm/pallet001.mdl", 			HEALTH_LOW,		10, _, _, _, tmp);
	DefineProp("Concrete Block","models/props_farm/concrete_block001.mdl", 	HEALTH_HIGH,	50);
	DefineProp("Stairs",		"models/props_farm/stairs_wood001b.mdl", 	HEALTH_MEDIUM,	30);
	DefineProp("Tri-Pipe",		"models/props_farm/concrete_pipe002.mdl", 	HEALTH_HIGH,	60);
	
	new FWAProp:reinf = DefineProp("Reinforcement", "", HEALTH_HIGH, 100, _, true, true);
	DefineDynamicPropPath(reinf, "models/props_2fort/corrugated_metal004.mdl");
	DefineDynamicPropPath(reinf, "models/props_2fort/corrugated_metal005.mdl");
	DefineDynamicPropPath(reinf, "models/props_2fort/corrugated_metal006.mdl");
	
}

public Plugin:myinfo = {
	name = "TF2 FortWars",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	lateLoad=late;
	
	RegPluginLibrary("fortwars");
	
	fwd_buildstart	= CreateGlobalForward("OnBuildStart", ET_Ignore);
	fwd_buildend	= CreateGlobalForward("OnBuildEnd", ET_Ignore);
	fwd_propbuilt		= CreateGlobalForward("OnPropBuilt", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array);
	fwd_propbuilt_pre	= CreateGlobalForward("OnPropBuilt_Pre", ET_Ignore, Param_Cell, Param_CellByRef, Param_Cell);
	fwd_proprotated		= CreateGlobalForward("OnPropRotated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array);
	fwd_propdestroyed	= CreateGlobalForward("OnPropDestroyed", ET_Ignore, Param_Cell, Param_Cell);
	
	CreateNative("FW_IsRunning", Native_IsRunning);
	CreateNative("FW_AddUnlock", Native_AddUnlock);
	CreateNative("FW_AddUnlock2", Native_AddUnlock2);
	CreateNative("FW_HasUnlock", Native_HasUnlock);
	CreateNative("FW_RemoveUnlock", Native_RemoveUnlock);
	CreateNative("FW_UnlockExists", Native_UnlockExists);
	CreateNative("FW_UnlockIdToNumId", Native_UnlockIdToNumId);
	CreateNative("FW_AddMenuItem", Native_AddMenuItem);
	CreateNative("FW_RemoveMenuItem", Native_RemoveMenuItem);
	CreateNative("FW_ShowMainMenu", Native_ShowMainMenu);
	CreateNative("FW_AddProp", Native_AddProp);
	CreateNative("FW_AddProp2", Native_AddProp2);
	CreateNative("FW_AddPropModel", Native_AddPropModel);
	CreateNative("FW_SetPropEntity", Native_SetPropEntity);
	CreateNative("FW_GetEntityProp", Native_GetEntityProp);
	CreateNative("FW_PropDestroyed", Native_PropDestroyed);
	CreateNative("FW_AddDependence", Native_AddDependence);
	
	CreateNative("FW_AddPropCount", Native_AddPropCount);
	CreateNative("FW_GetTeamPropCount", Native_GetTeamPropCount);
	CreateNative("FW_GetClientPropCount", Native_GetClientPropCount);
	
	CreateNative("FW_ShowError", Native_ShowError);
	
	return APLRes_Success;
}

public OnPluginStart(){
	LoadTranslations("common.phrases");
	
	CreateConVar("fw_version", PLUGIN_VERSION, "TF2 FortWars Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cv_sql = CreateConVar("fw_sql", "1", "Enables or disables SQL",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	cv_maps = CreateConVar("fw_maps", "1", "FortWars will only work on fw_ maps",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(cv_maps, CC_Maps);
	
	cv_max_team = CreateConVar("fw_props_per_team", "250", "Maximum number of props per team",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 50.0, true, float(MAX_PROPS_PER_TEAM));
	
	cv_max_player = CreateConVar("fw_props_per_player", "70", "Maximum number of props per player",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 10.0, true, float(MAX_PROPS_PER_TEAM));
	
	cv_max_player_admin = CreateConVar("fw_props_per_player_admin", "70", "Maximum number of props per player if the client has 'a' flag",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 10.0, true, float(MAX_PROPS_PER_TEAM));
	
	cv_spawn_protection = CreateConVar("fw_spawn_protection", "2.5", "Duration of the spawn protection, 0.0 to disable",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 10.0);
	
	cv_custom_spawn = CreateConVar("fw_custom_spawn", "0", "Enable custom spawn points",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	cv_stuck_protection = CreateConVar("fw_stuck_protection", "1", "Enable Stuck Protection (Disable if it is lagging your server)",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	cv_health_multipler = CreateConVar("fw_prop_health_multipler", "1", "Prop Health Multipler",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.2, true, 5.0);
	
	cv_shadows = CreateConVar("fw_prop_shadows", "1", "Props shadows: 0 = Disabled, 1 = Enabled, 2 = Partially enabled (doesn't receive shadows)",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	
	cv_setup = CreateConVar("fw_setup_time", "-1", "Overrides the map setup time, -1 to use the map default setup time. Recommended value: 180-240",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, -1.0);
	
	cv_max_free = CreateConVar("fw_no_limit_time", "60", "If the time remaining in the setup is less than this, there is no individual prop limit",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);
	
	cv_lulz = CreateConVar("fw_lulz", "0", "If enabled, props created will have physics effects applied. (Do it for teh lulz only, it may lag/crash the server)",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	cv_unlock_menu_style = CreateConVar("fw_unlock_menu_style", "1", "Style to use for the Unlocks Menu (0 = Valve; 1 = Radio)",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	
	cv_money_start = CreateConVar("fw_money_start", "1000", "Amount of money given to a player when he first joins the server",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_win = CreateConVar("fw_money_win", "1000", "Amount of money given to a player when his team wins",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_kill = CreateConVar("fw_money_kill", "100", "Amount of money given to a player when he kills another player",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_domination = CreateConVar("fw_money_domination", "300", "Amount of money given to a player when he dominates another player",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_headshot = CreateConVar("fw_money_headshot", "50", "Amount of money given to a player when he headshots another player",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_backstab = CreateConVar("fw_money_backstab", "50", "Amount of money given to a player when he backstabs another player",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_dispenser = CreateConVar("fw_money_destroy_dispenser", "75", "Amount of money given to a player when he destroys a dispenser",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_sentry = CreateConVar("fw_money_destroy_sentry", "75", "Amount of money given to a player when he destroys a sentry per sentry kill (assists count as half)",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	cv_money_balance = CreateConVar("fw_money_balance", "1000", "Amount of money given to a player when he is moved to another team for balance",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(MONEY_LIMIT));
	
	//AutoExecConfig(true, "fortwars"); Not yet, I may add more cvars
	
	HookConVarChange(cv_sql, CC_SQL);
	
	if(GetConVarBool(cv_sql)){
		ConnectToSQL();
	}
	
	RegConsoleCmd("sm_fwhelp", Cmd_Help, "Opens the Fortwars Help Menu", FCVAR_PLUGIN);
	RegConsoleCmd("sm_fwmoney", Cmd_Money, "Gets how much money the player has", FCVAR_PLUGIN);
	RegConsoleCmd("sm_fwmenu", Cmd_Menu, "Opens the FortWars Menu", FCVAR_PLUGIN);
	RegConsoleCmd("sm_fwresetspawn", Cmd_ResetSpawn, "Resets your spawn point", FCVAR_PLUGIN);
	RegConsoleCmd("sm_fwunstuck", Cmd_Unstuck, "Teleports you back to your spawn", FCVAR_PLUGIN);
	RegConsoleCmd("sm_fwgivemoney", Cmd_GiveMoney, "Gives money to another player", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_fwaddmoney", Cmd_AddMoney, ADMFLAG_CHEATS, "Gives a certain money to another player", _, FCVAR_PLUGIN);
	RegAdminCmd("sm_fwaddtime", Cmd_AddTime, ADMFLAG_CHEATS, "Adds more time to the current setup time", _, FCVAR_PLUGIN);
	RegAdminCmd("sm_fwwipe", Cmd_WipeClient, ADMFLAG_CHEATS, "All the player unlocks and money", _, FCVAR_PLUGIN);
	RegAdminCmd("sm_fwwipedb", Cmd_WipeDb, ADMFLAG_ROOT, "Wipes the database", _, FCVAR_PLUGIN);
	RegAdminCmd("sm_fwfixdb", Cmd_FixDb, ADMFLAG_ROOT, "Attempts to fix the database", _, FCVAR_PLUGIN);
	
	RegAdminCmd("sm_fwdebugnb", Cmd_DebugNobuild, ADMFLAG_ROOT, "Shows the nobuild areas", _, FCVAR_PLUGIN);
	
	LoadProps();
}

public OnPluginEnd(){
	
	SaveMoneyAll();
	
	new Handle:iter=GetPluginIterator();
	
	while(MorePlugins(iter)){
		new Handle:cur = ReadPlugin(iter);
		for(new i=0;i<myPluginsCount;++i){
			if(myPlugins[i]!=cur) continue;
			decl String:filename[300];
			GetPluginFilename(myPlugins[i], filename, sizeof(filename));
			ServerCommand("sm plugins unload \"%s\"", filename);
		}
	}
}

public OnAllPluginsLoaded(){
	if(lateLoad){
		ServerCommand("sm plugins refresh");
	}
}

public Action:OnGetGameDescription(String:gameDesc[64]){
	if(started){
		strcopy(gameDesc, 64, "FortWars");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
stock ConnectToSQL(bool:threaded=true){
	if(sql) return;
	if(connecting) return;
	
	sql=false;
	hSql = INVALID_HANDLE;
	
	if(SQL_CheckConfig("fortwars")){
		connecting=true;
		SQL_TConnect(SQLC_Connect, "fortwars");
		return;
	}else{
		hSql = SQLite_UseDatabase("sourcemod-local", sError, sizeof(sError));
		if(hSql==INVALID_HANDLE){
			LogError("Couldn't connect to SQLite, error message: '%s'", sError);
			SetFailState("Couldn't connect to SQLite, error message: '%s'", sError);
			return;
		}else{
			LogMessage("Connected to SQLite");
			sql=true;
		}
		CreateDatabase();
		LoadMoneyAll();
	}
}

public SQLC_Connect(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl==INVALID_HANDLE){
		connecting=false;
		sql=false;
		LogError("Couldn't connect to mysql, error message: '%s'", error);
		return;
	}
	
	hSql=hndl;
	connecting=false;
	sql=true;
	CreateDatabase();
	LoadMoneyAll();
}

public SQLC_Ignore(Handle:owner, Handle:hndl, const String:error[], any:data){
	// Ignoring :P
}

stock DisconnectFromSQL(){
	if(!sql) return;
	sql=false;
	CloseHandle(hSql);
	hSql = INVALID_HANDLE;
}

stock CreateDatabase(){
	// This may throw an error, but I am too lazy to make a condition to check
	// if the table exists, the error won't be displayed to the server anyway
	// There isn't an easy way to check if the table exists, so this won't be a problem
	SQL_FastQuery(hSql, "CREATE TABLE fw_users (id INT(64) NOT NULL AUTO_INCREMENT PRIMARY KEY, auth CHAR(64) UNIQUE, money INT(16) DEFAULT '0', unlocks VARCHAR(8000))");
}
public Action:Cmd_WipeDb(client, args){
	SQL_FastQuery(hSql, "DROP TABLE fw_users");
	sql=false;
	RestartFortWars();
}

public Action:Cmd_FixDb(client, args){
	if(!sql || hSql==INVALID_HANDLE) ReplyToCommand(client, "%s Not connected", PLUGIN_PREFIX);
	// Not implemented
}

public RestartFortWars(){
	decl String:filename[300];
	GetPluginFilename(GetMyHandle(), filename, sizeof(filename));
	ServerCommand("sm plugins reload \"%s\"", filename);
}


public StartPlugin(){
	if(started) return;
	started=true;
	
	ResetMapVars();
	
	saveMoneyTimer=CreateTimer(600.0, Timer_SaveMoney, _, TIMER_REPEAT);
	
	tickTimer=CreateTimer(TICK_INTERVAL, Timer_Tick, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_start", teamplay_round_start);
	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("teamplay_round_win", teamplay_round_win);
	HookEvent("teamplay_setup_finished", teamplay_setup_finished);
	HookEvent("teamplay_teambalanced_player", teamplay_teambalanced_player);
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_team", player_team);
	HookEvent("player_spawn", player_spawn);
	HookEvent("object_destroyed", object_destroyed);
	
	HookEntityOutput("item_teamflag", "OnDrop", OnFlagDropped);
}

public StopPlugin(){
	if(!started) return;
	started=false;
	
	KillTimer(saveMoneyTimer);
	
	KillTimer(tickTimer);
	
	UnhookEvent("teamplay_round_start", teamplay_round_start);
	UnhookEvent("teamplay_round_active", teamplay_round_active);
	UnhookEvent("teamplay_round_win", teamplay_round_win);
	UnhookEvent("teamplay_setup_finished", teamplay_setup_finished);
	UnhookEvent("teamplay_teambalanced_player", teamplay_teambalanced_player);
	UnhookEvent("player_death", player_death, EventHookMode_Pre);
	UnhookEvent("player_team", player_team);
	UnhookEvent("player_spawn", player_spawn);
	UnhookEvent("object_destroyed", object_destroyed);
	
	UnhookEntityOutput("item_teamflag", "OnDrop", OnFlagDropped);
}

public OnMapStart(){
	timerEnt=-1;
	
	#pragma unused debugSprite
	//debugSprite=PrecacheModel("");
	
	for(new i=0;i<aPropsCount;++i){
		if(!aPropsValid[i]) continue;
		if(aPropsDynamic[i]){
			new propModelsId=aPropsDynamicId[i];
			new numPropModels=aPropsDynamicCount[i];
			for(new j=0;j<numPropModels;++j){
				if(strlen(aPropsDynamicPath[propModelsId][j])>0){
					PrecacheModel(aPropsDynamicPath[propModelsId][j], true);
				}
			}
		}else{
			if(strlen(aPropsPath[i])>0){
				PrecacheModel(aPropsPath[i], true);
			}
		}
	}
	ResetMapVars();
	FixNoObserverCrash();
	
	MapCheck();
	
	FindTimer();
	
	if(started){
		if(lateLoad && GetClientCount()>0){
			PrintToChatAll("%s FortWars Loaded!", PLUGIN_PREFIX);
			ServerCommand("mp_restartgame 1");
		}
		lateLoad=false;
	}
}

public OnMapEnd(){
	SaveMoneyAll();
}

public MapCheck(){
	if(!IsFwMap() && GetConVarBool(cv_maps)){
		StopPlugin();
	}else{
		StartPlugin();
	}
}

public ResetMapVars(){
	inSetup=false;
	playing=true;
	setupTime=0;
	propsCount=0;
	
	for(new i=1;i<=MaxClients;++i){
		canReceiveWinMoney[i]=true;
		moneySpentOnProps[i]=0;
		moneyAdded[i]=0;
	}
	
	for(new i=0;i<sizeof(props);++i){
		props[i]=INVALID_ENT;
	}
	for(new i=0;i<sizeof(propsTeamCount);++i){
		propsTeamCount[i]=0;
	}
	for(new i=0;i<MAXPLAYERS;++i){
		hasCustomSpawnPoint[i]=false;
		teleport[i]=false;
		propsPlayerCount[i]=0;
	}
	for(new i=0;i<sizeof(teamCanBuild);++i){
		teamCanBuild[i]=true;
	}
	FindMapPermissions();
	FindNoBuildAreas();
}


public OnClientConnected(client){
	ResetClientVars(client);
}

public OnClientAuthorized(client, const String:auth[]){
	if(IsFakeClient(client)) return;
	LoadMoney(client);
}

public OnClientDisconnect(client){
	SaveMoney(client);
	ResetClientVars(client);
}

public ResetClientVars(i){
	propsPlayerCount[i]=0;
	selectedEntRef[i]=0;
	rotationAxis[i]=0;
	hasCustomSpawnPoint[i]=false;
	teleport[i]=false;
	clearSpawn[i]=false;
	respawn[i]=false;
	moneyOffset[i]=0;
	canReceiveWinMoney[i]=false;
	
	WipeClient(i);
	canSaveMoney[i]=false;
	
	ResetClientPropOwnership(i);
}

public ResetClientPropOwnership(i){
	for(new j=0;j<propsCount;++j){
		if(propsOwner[j]==i){
			propsOwner[j]=0;
		}
	}
}

public OnPropBuilt(builder, ent, FWProp:prop, FWAProp:propid){
	new cost=aPropsCost[propid];
	RemoveMoney(builder, cost);
	moneySpentOnProps[builder]+=cost;
}

public OnPropDestroyed(ent, FWProp:prop){
	new TFTeam:team = propsTeam[prop];
	--propsTeamCount[team];
	--propsPlayerCount[propsOwner[prop]];
	
	if(propsRefund[prop] && inSetup){
		RefundProp(prop, -1.0);
	}
}



//////////////////////////////////////////////////////////////////////////////

public CC_Maps(Handle:convar, const String:oldValue[], const String:newValue[]){
	MapCheck();
}
public CC_SQL(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarBool(cv_sql)){
		ConnectToSQL();
	}else{
		DisconnectFromSQL();
	}
}
public OnGameFrame(){
	if(!started) return;
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		new bool:alive=IsPlayerAlive(i);
		if(teleport[i]){
			teleport[i]=false;
			if(alive){
				TeleportEntity(i, teleportPos[i], teleportAng[i], NULL_VECTOR);
			}
		}
		if(clearSpawn[i]){
			clearSpawn[i]=false;
			if(alive){
				new stuck=IsPlayerStuck(i);
				new FWProp:prop=EntToProp(stuck);
				if(stuck>0){
					if(prop!=INVALID_PROP && IsValidEntity(props[prop])){
						if(hasCustomSpawnPoint[i]){
							hasCustomSpawnPoint[i]=false;
							TF2_RespawnPlayer(i);
							ShowSuccess(i, _, "Your custom spawn point was broken, your spawn point got reset");
						}else{
							BreakProp(prop);
							clearSpawn[i]=true;
							ShowSuccess(i, _, "You were stuck in the spawn point, the prop that was blocking you was removed");
						}
					}
				}
			}
		}
		if(respawn[i]){
			respawn[i]=false;
			TF2_RespawnPlayer(i);
		}
	}
	
	if(GetConVarBool(cv_stuck_protection)){
		for(new i=0;i<propsCount;++i){
			new FWProp:prop = FWProp:i;
			if(props[prop]==INVALID_ENT) continue;
			if(!IsValidEntity(props[i])){
				props[prop]=INVALID_ENT;
				continue;
			}
			if(propsTeleport[prop]){
				propsTeleport[prop]=false;
				TeleportEntity(props[prop], propsPos[prop], propsAng[prop], NULL_VECTOR);
			}
			if(!propsNotSolid[prop]) continue;
			
			new ent=props[prop];
			if(inSetup){
				new change=true;
				PropEnableCollision(prop);
				for(new j=1;j<=MaxClients;++j){
					if(IsValid(j) && IsPlayerAlive(j) && IsPlayerStuckInEnt(j, ent)){
						change=false;
						break;
					}
				}
				
				if(change){
					propsNotSolid[prop]=false;
					ColorProp(prop, ent);
				}else{
					PropDisableCollision(prop);
				}
			}else{
				PropEnableCollision(prop);
				propsNotSolid[prop]=false;
				ColorProp(prop, ent);
				for(new j=1;j<=MaxClients;++j){
					if(IsValid(j) && IsPlayerAlive(j) && IsPlayerStuckInEnt(j, ent)){
						Unstuck(j);
					}
				}
			}
		}
	}
}

public Action:Timer_Tick(Handle:timer){
	
	
	decl String:phase[64];
	phase[0]='\0';
	
	if(needSetupTimer && inSetup){
		setupTimeLeft-=TICK_INTERVAL;
		if(setupTimeLeft<0.0){
			setupTimeLeft=0.0;
		}
		if(!noPlayerLimit && setupTimeLeft<GetConVarInt(cv_max_free)){
			noPlayerLimit=true;
		}
		
		new r=RoundToFloor(setupTimeLeft);
		Format(phase, sizeof(phase), "[%02d:%02d]", r/60, r%60)
	}
	
	new Float:redperc;
	new Float:blueperc;
	
	if(!inSetup){
		new redmax = propsTeamCountStart[TFTeam_Red];
		if(redmax<=0) redmax=1;
		redperc = float(propsTeamCount[TFTeam_Red])/float(redmax)*100;
		
		new bluemax = propsTeamCountStart[TFTeam_Blue];
		if(bluemax<=0) bluemax=1;
		blueperc = float(propsTeamCount[TFTeam_Blue])/float(bluemax)*100;
		
	}
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		new mOffset=moneyOffset[i];
		moneyOffset[i]=0;
		decl String:msg[192];
		if(mOffset>0){
			Format(msg, sizeof(msg), "Money: $%d (+$%d)", GetMoney(i), mOffset);
		}else if(mOffset<0){
			Format(msg, sizeof(msg), "Money: $%d ($%d)", GetMoney(i), mOffset);
		}else{
			Format(msg, sizeof(msg), "Money: $%d", GetMoney(i));
		}
		ShowMessage(i, Money, 0.05, 0.75, TICK_INTERVAL, Green, msg);
		
		new TFTeam:team=TFTeam:GetClientTeam(i);
		
		if(!IsClientSpec(i)){
			if(inSetup){
				if(teamCanBuild[team]){
					decl String:fmsg[192];
					new Float:yoffset=0.275;
					
					Format(fmsg, sizeof(fmsg), "Team Props: %d/%d", propsTeamCount[team], GetConVarInt(cv_max_team));
					ShowMessage(i, RedProps, -1.0, (yoffset+=0.025), TICK_INTERVAL, Team, fmsg);
					
					if(!noPlayerLimit){
						Format(fmsg, sizeof(fmsg), "Your Props: %d/%d", propsPlayerCount[i], GetPlayerPropLimit(i));
						ShowMessage(i, BlueProps, -1.0, (yoffset+=0.025), TICK_INTERVAL, Team, fmsg);
					}
					
					if(phase[0]!='\0'){
						ShowMessage(i, Phase, -1.0, 0.10, TICK_INTERVAL, Team, phase);
					}
					
				}
			}else{
				decl String:fmsg[192];
				new Float:yoffset=0.125;
				if(teamCanBuild[TFTeam_Red]){
					Format(fmsg, sizeof(fmsg), "Red Fort: %.1f%%", redperc);
					ShowMessage(i, RedProps, -1.0, (yoffset+=0.025), TICK_INTERVAL, Red, fmsg);
				}
				if(teamCanBuild[TFTeam_Blue]){
					Format(fmsg, sizeof(fmsg), "Blue Fort: %.1f%%", blueperc);
					ShowMessage(i, BlueProps, -1.0, (yoffset+=0.025), TICK_INTERVAL, Blue, fmsg);
				}
				
			}
		}
		
		if(inSetup){
			new FWProp:prop = EntToProp(GetClientAimTarget(i, false));
			if(prop!=INVALID_PROP){
				if(propsOwner[prop]==0){
					ShowMessage(i, Owner, -1.0, 0.6, TICK_INTERVAL, Team, "This prop doesn't have an owner")
				}else{
					decl String:omsg[192];
					Format(omsg, sizeof(omsg), "Prop Owner:\n%N", propsOwner[prop]);
					ShowMessage(i, Owner, -1.0, 0.6, TICK_INTERVAL, Team, omsg)
				}
			}
		}
	}
}

public Action:Timer_SaveMoney(Handle:timer){
	if(started){
		SaveMoneyAll();
	}
}

//////////////////////////////////////////////////////////////////////////////

public Action:Cmd_Help(client, args){
	if(!started) return Plugin_Continue;
	if(!IsValid(client)) return Plugin_Continue;
	if(IsClientSpec(client)){
		ShowError(client, _, "You cannot use the help menu as a spectator");
		return Plugin_Handled;
	}
	ShowHelpMenu(client);
	return Plugin_Handled;
}


public Action:Cmd_Menu(client, args){
	if(!started) return Plugin_Continue;
	if(client==0||!IsClientInGame(client)) return Plugin_Continue;
	if(IsClientSpec(client)){
		ShowError(client, _, "You cannot use the menu as a spectator");
		return Plugin_Handled;
	}
	ShowMainMenu(client);
	return Plugin_Handled;
}

public Action:Cmd_Unstuck(client, args){
	if(!started) return Plugin_Continue;
	if(!IsValid(client)) return Plugin_Continue;
	if(IsClientSpec(client)){
		ShowError(client, _, "You cannot unstuck as a spectator");
		return Plugin_Handled;
	}
	if(!CanBuild(client)){
		ShowError(client, _, "You cannot unstuck at this time");
		return Plugin_Handled;
	}
	
	Unstuck(client);
	return Plugin_Handled;
}

public Action:Cmd_ResetSpawn(client, args){
	if(!started) return Plugin_Continue;
	if(!IsValid(client)) return Plugin_Continue;
	
	if(hasCustomSpawnPoint[client]){
		hasCustomSpawnPoint[client]=false;
		PrintToChat(client, "%s Spawn point reseted!", PLUGIN_PREFIX);
	}else if(GetConVarBool(cv_custom_spawn)){
		PrintToChat(client, "%s Custom Spawn Points are disabled", PLUGIN_PREFIX);
	}else{
		PrintToChat(client, "%s You don't have a spawn point set", PLUGIN_PREFIX);
	}
	
	return Plugin_Handled;
}

public Action:Cmd_AddMoney(admin, args){
	if(!started) return Plugin_Continue;
	if(args<2){
		ReplyToCommand(admin, "%s Usage: sm_fwaddmoney <amount> <player>", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	decl String:sAmount[16];
	new amount;
	GetCmdArg(1, sAmount, sizeof(sAmount));
	amount=StringToInt(sAmount); //Change to base 16 if you are cool enough
	
	if(amount<0){
		ReplyToCommand(admin, "%s Don't be so bad :(", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	decl String:sTarget[MAX_NAME_LENGTH];
	GetCmdArg(2, sTarget, sizeof(sTarget));
	
	
	new client=FindTarget(admin, sTarget, true, false);
	if(client!=-1){
		LogAction(admin, client, "%s Gave $%d to %N", PLUGIN_PREFIX, amount, client);
		AddMoney(client, amount, true, "Gave to you by %N", admin);
		PrintToChat(admin, "%s Gave \x03$%d\x01 to %N", PLUGIN_PREFIX, amount, client);
		SaveMoney(client);
	}
	
	return Plugin_Handled;
}

public Action:Cmd_AddTime(admin, args){
	if(!started) return Plugin_Continue;
	if(args<1){
		ReplyToCommand(admin, "%s Usage: sm_fwaddtime <amount>", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(!inSetup){
		ReplyToCommand(admin, "%s Not in setup", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	decl String:sAmount[32];
	GetCmdArg(1, sAmount, sizeof(sAmount));
	
	if(timerEnt > -1){
		new n=StringToInt(sAmount);
		SetVariantInt(n);
		AcceptEntityInput(timerEnt, "AddTime");
		setupTimeLeft+=n;
	}
	return Plugin_Handled;
}

public Action:Cmd_GiveMoney(client, args){
	if(!started) return Plugin_Continue;
	if(args<2){
		ReplyToCommand(client, "%s Usage: sm_fwgivemoney <amount> <player>", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	new amount;
	new String:sAmount[16];
	new target;
	new String:sTarget[MAX_NAME_LENGTH];
	GetCmdArg(1, sAmount, sizeof(sAmount));
	GetCmdArg(2, sTarget, sizeof(sTarget));
	
	target=FindTarget(client, sTarget, true, false);
	
	if(target==-1){
		return Plugin_Handled;
	}
	
	if(target==client){
		ReplyToCommand(client, "%s You are too greedy, you can't give money to yourself", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	amount = StringToInt(sAmount);
	
	if(amount<=0){
		ReplyToCommand(client, "%s Invalid amount of money", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(!HasMoney(client, amount)){
		ReplyToCommand(client, "%s You do not have \x03$%d", PLUGIN_PREFIX, amount);
		return Plugin_Handled;
	}
	
	if(amount<MONEY_MIN_DONATION){
		ReplyToCommand(client, "%s You need to give at least \x03$%d", PLUGIN_PREFIX, MONEY_MIN_DONATION);
		return Plugin_Handled;
	}
	
	RemoveMoney(client, amount, true, "Donation to %N", target);
	AddMoney(target, amount, true, "Donation by %N", client);
	
	SaveMoney(client);
	SaveMoney(target);
	
	return Plugin_Handled;
}

public Action:Cmd_WipeClient(admin, args){
	if(!started) return Plugin_Continue;
	if(args<1){
		ReplyToCommand(admin, "%s Usage: sm_fwaddmoney <player>", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	decl String:sTarget[MAX_NAME_LENGTH];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	new client=FindTarget(admin, sTarget, true, false);
	if(client<0) return Plugin_Handled;
	
	WipeClient(client);
	SaveMoney(client);
	
	ReplyToCommand(admin, "%s Client wiped!", PLUGIN_PREFIX);
	
	return Plugin_Handled;
}

public Action:Cmd_DebugNobuild(client, args){
	if(!started) return Plugin_Continue;
	
	if(nobuildCount<=0){
		ReplyToCommand(client, "%s No nobuild areas found", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	for(new i=0;i<nobuildCount;++i){
		ShowRect(nobuildPosMin[i], nobuildPosMax[i]);
	}
	
	ReplyToCommand(client, "%s Displaying %d nobuild areas", PLUGIN_PREFIX, nobuildCount);
	return Plugin_Handled;
}

public Action:Cmd_Money(client, args){
	if(!started) return Plugin_Continue;
	if(args<1){
		ReplyToCommand(client, "%s Usage: sm_fwmoney <player>", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	decl String:sTarget[MAX_NAME_LENGTH];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	new target=FindTarget(client, sTarget, true, false);
	if(target<0) return Plugin_Handled;
	
	if(GetUserFlagBits(target)&ADMFLAG_ROOT){
		ReplyToCommand(client, "%s \x03%N\x01 has \x03$563e+45", PLUGIN_PREFIX, target);
	}else{
		ReplyToCommand(client, "%s \x03%N\x01 has \x03$%d", PLUGIN_PREFIX, target, money[target]);
	}
	
	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////////////////

public Action:teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast){
	ResetMapVars();
	playing=false;
	inSetup=true;
	noPlayerLimit=false;
	
	FindTimer();
	
	{
		if(GetConVarInt(cv_setup)>=0 && timerEnt > -1){
			new amount=GetConVarInt(cv_setup);
			if(amount<1) amount=1;
			setupTime=amount;
			FindSendPropOffs("CTeamRoundTimer", "m_nSetupTimeLength")
			SetVariantInt(amount);
			AcceptEntityInput(timerEnt, "SetTime");
			SetEntData(timerEnt, FindSendPropOffs("CTeamRoundTimer", "m_nSetupTimeLength"), amount);
		}
	}
	
	
	{
		if(timerEnt>-1){
			setupTimeLeft = float(GetEntProp(timerEnt, Prop_Send, "m_nSetupTimeLength"));
		}
	}
	
	
	// If you change this, you'll die a little inside (-10 Hp)
	// (This only prints if the plugin is running and it has a small change to print)
	if(GetRandomInt(0,9)==0){
		PrintToChatAll("%s \x03FortWars\x01 by \x03Matheus28\x01", PLUGIN_PREFIX);
	}
	
	PrintToChatAll("%s Type \x03/fwhelp\x01 to open the FortWars Help menu", PLUGIN_PREFIX);
	
	Call_StartForward(fwd_buildstart);
	Call_Finish();
}


public Action:teamplay_round_active(Handle:event, const String:name[], bool:dontBroadcast){
	playing=true;
	CalculateSetupTime();
	if(setupTime > 0){
		inSetup=true;
	}else{
		inSetup=false;
		FireEvent(CreateEvent("teamplay_setup_finished", true), true);
	}
	if(inSetup){
		PrintToChatAll("%s Type \x03/fwmenu\x01 to open the FortWars building menu", PLUGIN_PREFIX);
	}
}

public Action:teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast){
	playing=false;
	new TFTeam:team = TFTeam:GetEventInt(event, "team");
	if(team==TFTeam_Unassigned){
		RefundAllTeamProps(_:TFTeam_Red, 0.6);
		RefundAllTeamProps(_:TFTeam_Blue, 0.6);
	}else if(team==TFTeam_Blue){
		for(new i=1;i<=MaxClients;++i){
			if(!IsClientInGame(i)) continue;
			if(GetClientTeam(i)!=_:TFTeam_Blue) continue;
			if(!canReceiveWinMoney[i]) continue;
			AddMoney(i, GetConVarInt(cv_money_win), true, "Win");
		}
		RefundAllTeamProps(_:TFTeam_Blue, 0.8);
		RefundAllTeamProps(_:TFTeam_Red, 0.4);
	}else if(team==TFTeam_Red){
		for(new i=1;i<=MaxClients;++i){
			if(!IsClientInGame(i)) continue;
			if(GetClientTeam(i)!=_:TFTeam_Red) continue;
			if(!canReceiveWinMoney[i]) continue;
			AddMoney(i, GetConVarInt(cv_money_win), true, "Win");
		}
		RefundAllTeamProps(_:TFTeam_Red, 0.8);
		RefundAllTeamProps(_:TFTeam_Blue, 0.4);
	}
	
	{
		for(new i=1;i<=MaxClients;++i){
			if(!IsClientInGame(i)) continue;
			
			if(moneySpentOnProps[i]>0){
				PrintToChat(i, "%s Money spent: \x03$%d\x01", FORTWARS_PREFIX, moneySpentOnProps[i]);
			}
			if(moneyAdded[i]>0){
				PrintToChat(i, "%s Money won: \x03$%d\x01", FORTWARS_PREFIX, moneyAdded[i]);
			}
		}
	}
}


public Action:teamplay_setup_finished(Handle:event,  const String:name[], bool:dontBroadcast) {
	inSetup=false;
	for(new i=0;i<sizeof(propsTeamCountStart);++i){
		propsTeamCountStart[i] = propsTeamCount[i];
	}
	Call_StartForward(fwd_buildend);
	Call_Finish();
	
	RestoreAllPropsHealth();
}

public Action:teamplay_teambalanced_player(Handle:event,  const String:name[], bool:dontBroadcast) {
	new client = GetEventInt(event, "player");
	AddMoney(client, GetConVarInt(cv_money_balance), true, "Team Balanced");
}

public Action:player_death(Handle:event,  const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	new deathflags = GetEventInt(event, "death_flags");
	new customkill = GetEventInt(event, "customkill");
	
	if(!playing && !inSetup){
		if(deathflags & TF_DEATHFLAG_KILLERDOMINATION){
			AddImpreciseMoney(attacker, GetConVarInt(cv_money_domination), true, "Domination");
		}
		if(deathflags & TF_DEATHFLAG_ASSISTERDOMINATION){
			AddImpreciseMoney(assister, GetConVarInt(cv_money_domination), true, "Domination");
		}
		return Plugin_Continue;
	}
	if(inSetup){
		CreateTimer(2.0, Timer_Dissolve, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		if(!GetEventBool(event, "feign_death")){
			CreateTimer(2.5, Timer_RespawnPlayer, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Handled;
	}

	
	if(victim != attacker && IsValid(attacker)){
		if(GetEventBool(event, "feign_death")){
			AddImpreciseFakeMoney(attacker, GetConVarInt(cv_money_kill), true, "Kill");
		}else{
			AddImpreciseMoney(attacker, GetConVarInt(cv_money_kill), true, "Kill");
			if(deathflags & TF_DEATHFLAG_KILLERDOMINATION){
				AddImpreciseMoney(attacker, GetConVarInt(cv_money_domination), true, "Domination");
			}
			
			if(customkill == TF_CUSTOM_BACKSTAB){
				AddImpreciseMoney(attacker, GetConVarInt(cv_money_backstab), true, "Backstab");
			}
			
			if(customkill == TF_CUSTOM_HEADSHOT){
				AddImpreciseMoney(attacker, GetConVarInt(cv_money_headshot), true, "Headshot");
			}
		}
	}
	if(victim != assister && IsValid(assister)){
		if(GetEventBool(event, "feign_death")){
			AddImpreciseFakeMoney(assister, GetConVarInt(cv_money_kill), true, "Kill");
		}else{
			AddMoney(assister, GetConVarInt(cv_money_kill), true, "Kill");
			if(deathflags & TF_DEATHFLAG_ASSISTERDOMINATION){
				AddImpreciseMoney(assister, GetConVarInt(cv_money_domination), true, "Domination");
			}
		}
	}
	return Plugin_Continue;
}

public Action:player_team(Handle:event,  const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	hasCustomSpawnPoint[client]=false;
	if(canReceiveWinMoney[client] && (!inSetup && playing)){
		PrintToChat(client, "%s You'll no longer receive money if your team win this round", PLUGIN_PREFIX);
		canReceiveWinMoney[client]=false;
	}
	ResetClientPropOwnership(client);
}

public Action:player_spawn(Handle:event,  const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!inSetup || !playing){
		new Float:dur = GetConVarFloat(cv_spawn_protection);
		if(hasCustomSpawnPoint[client]){
			dur*=0.5;
		}
		if(dur>0.0){
			TF2_AddCondition(client, TFCond_Ubercharged, dur);
			decl String:msg[192];
			Format(msg, sizeof(msg), "Spawn Protection for %.1f seconds", dur);
			ShowSuccess(client, dur+0.5, msg);
		}
	}
	
	GetClientAbsOrigin(client, spawnPos[client]);

	if(hasCustomSpawnPoint[client]){
		teleport[client]=true;
		teleportPos[client]=spawnPointPos[client];
		teleportAng[client]=spawnPointAng[client];
	}else{
		teleport[client]=false;
	}
	clearSpawn[client]=true;
}

public Action:object_destroyed(Handle:event,  const String:name[], bool:dontBroadcast) {
	new engineer = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new bool:building = GetEventBool(event, "was_building");
	new ent=GetEventInt(event, "index");
	new TFObjectType:type=TFObjectType:GetEventInt(event, "objecttype");
	
	switch(type){
		case TFObject_Sentry:{
			new Float:kills=GetEntProp(ent, Prop_Send, "m_iKills")+(float(GetEntProp(ent, Prop_Send, "m_iAssists"))/2);
			
			if(kills>0.0){
				if(engineer != attacker && IsValid(attacker)){
					AddImpreciseMoney(attacker, RoundFloat(GetConVarInt(cv_money_sentry)*kills), true, "Sentry Destruction (%.1f kills)", kills);
				}
				if(engineer != assister && IsValid(assister)){
					AddImpreciseMoney(assister, RoundFloat(GetConVarInt(cv_money_sentry)*kills), true, "Sentry Destruction (%.1f kills)", kills);
				}
			}
		}
		case TFObject_Dispenser:{
			if(engineer != attacker && IsValid(attacker) && !building){
				AddImpreciseMoney(attacker, GetConVarInt(cv_money_dispenser), true, "Dispenser Destruction");
			}
			if(engineer != assister && IsValid(assister) && !building){
				AddImpreciseMoney(assister, GetConVarInt(cv_money_dispenser), true, "Dispenser Destruction");
			}
		}
	}
	
}

//////////////////////////////////////////////////////////////////////////////

public _ShowMainMenu(client, page){
	ShowMainMenu(client, page);
}

stock ShowMainMenu(client, page=0){
	if(!IsValid(client) || IsClientSpec(client)) return;
	
	new canbuild=CanBuild(client);
	new Handle:menu = CreateMenu(HandleMainMenu);
	SetMenuTitle(menu, "Fortwars - Main Menu");
	
	if(canbuild){
		AddMenuItem(menu, "c", "Create Prop");
		AddMenuItem(menu, "r", "Rotate Prop");
		AddMenuItem(menu, "d", "Delete Prop");
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
		AddMenuItem(menu, "u", "Unstuck");
		if(GetConVarBool(cv_custom_spawn)){
			if(hasCustomSpawnPoint[client]){
				AddMenuItem(menu, "s", "Change Spawn Point");
			}else{
				AddMenuItem(menu, "s", "Set Spawn Point");
			}
		}
		//AddMenuItem(menu, "",  "", ITEMDRAW_SPACER);
	}else{
		AddMenuItem(menu, "", "Create Prop", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Rotate Prop", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Delete Prop", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
		AddMenuItem(menu, "", "Unstuck", ITEMDRAW_DISABLED);
		if(GetConVarBool(cv_custom_spawn)){
			if(hasCustomSpawnPoint[client]){
				AddMenuItem(menu, "", "Change Spawn Point", ITEMDRAW_DISABLED);
			}else{
				AddMenuItem(menu, "", "Set Spawn Point", ITEMDRAW_DISABLED);
			}
		}
	}
	
	if(unlocksCount>0){
		AddMenuItem(menu, "l", "Unlocks");
	}
	
	if(menuiCount>0){
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	}
	
	for(new i=0;i<menuiCount;++i){
		if(!menuiValid[i]) continue;
		if(menuiBuildOnly[i] && !canbuild){
			AddMenuItem(menu, "", menuiName[i], ITEMDRAW_DISABLED);
		}else{
			AddMenuItem(menu, menuiId[i], menuiName[i]);
		}
	}
	
	new multipage=GetMenuItemCount(menu)>9;
	
	if(!multipage){
		SetMenuPagination(menu, MENU_NO_PAGINATION);
	}
	
	SetMenuExitButton(menu, true);
	if(multipage){
		DisplayMenuAtItem(menu, client, page*7, MENU_TIME_FOREVER);
	}else{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public HandleMainMenu(Handle:menu, MenuAction:action, param1, param2){
	if(action==MenuAction_Select){
		if(!IsValid(param1) || IsClientSpec(param1)) return;
		
		decl String:info[32];
		if(!GetMenuItem(menu, param2, info, sizeof(info))){
			return;
		}
		
		new index;
		if((index=MenuItemIdToIndex(info))!=-1){
			if(menuiBuildOnly[index] && !CanBuild(param1)){
				ShowMainMenu(param1, param2/7);
				return;
			}
			Call_StartForward(menuiCallback[index]);
			Call_PushCell(param1);
			Call_Finish();
		}
		
		if(StrEqual(info,"l")){
			ShowUnlocksMenu(param1);
			return;
		}
		
		if(!CanBuild(param1)){
			ShowMainMenu(param1, param2/7);
			return;
		}
		
		
		if(StrEqual(info,"c")){
			ShowPropsMenu(param1);
			return
		}else if(StrEqual(info,"r")){
			ShowRotationMenu(param1);
			return
		}else if(StrEqual(info,"d")){
			DeleteProp(param1);
		}else if(StrEqual(info,"s")){
			SetSpawn(param1);
		}else if(StrEqual(info,"u")){
			Unstuck(param1);
		}
		ShowMainMenu(param1, param2/7);
	}else if(action==MenuAction_End){
		CloseHandle(menu);
	}
}

stock ShowPropsMenu(client, page=0){
	if(!CanBuild(client)) return;
	new Handle:menu = CreateMenu(HandlePropMenu);
	SetMenuTitle(menu, "Fortwars - Create Prop");
	
	AddMenuItem(menu, "b", "<- Back");
	
	new cost;
	for(new i=0;i<aPropsCount;++i){
		if(!aPropsValid[i]) continue;
		cost=aPropsCost[i];
		decl String:id[6];
		IntToString(i, id, sizeof(id));
		decl String:name[64];
		Format(name, sizeof(name), "[$%d] %s", cost, aPropsName[i]);
		if(HasMoney(client, cost)){
			AddMenuItem(menu, id, name);
		}else{
			AddMenuItem(menu, id, name, ITEMDRAW_DISABLED);
		}
	}
	
	new bool:multipage=GetMenuItemCount(menu)>9;
	
	if(!multipage){
		SetMenuPagination(menu, MENU_NO_PAGINATION);
	}
	
	SetMenuExitButton(menu, true);
	if(multipage){
		DisplayMenuAtItem(menu, client, page*7, MENU_TIME_FOREVER);
	}else{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public HandlePropMenu(Handle:menu, MenuAction:action, param1, param2){
	if(action==MenuAction_Select){
		if(!CanBuild(param1)) return;
		decl String:info[32];
		if(!GetMenuItem(menu, param2, info, sizeof(info))){
			return;
		}
		if(StrEqual(info, "b")){
			ShowMainMenu(param1);
			return;
		}
		
		new propid = StringToInt(info);
		CreateProp(param1, propid);
		ShowPropsMenu(param1, param2/7);
	}else if(action==MenuAction_End){
		CloseHandle(menu);
	}
}

public ShowRotationMenu(client){
	if(!CanBuild(client)) return;
	new Handle:menu = CreateMenu(HandleRotationMenu);
	SetMenuTitle(menu, "Fortwars - Rotate Prop");
	
	AddMenuItem(menu, "b", "<- Back");
	
	decl String:axis[16];
	if(rotationAxis[client]>1){
		rotationAxis[client]=0;
	}
	switch(rotationAxis[client]){
		case 0:{axis="Horinzontal";}
		case 1:{axis="Vertical";}
		default:{
			axis="Horinzontal";
			rotationAxis[client]=0;
		}
		
	}
	decl String:raxis[64];
	Format(raxis, sizeof(raxis), "Rotation Axis: %s (Change)", axis);
	
	AddMenuItem(menu, "a", raxis);
	
	if(selectedEntRef[client]!=0 && IsValidEntity(EntRefToEntIndex(selectedEntRef[client]))){
		AddMenuItem(menu, "s", "Select another Prop");
		AddMenuItem(menu, "r", "Rotate Prop");
	}else{
		AddMenuItem(menu, "s", "Select Prop");
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HandleRotationMenu(Handle:menu, MenuAction:action, param1, param2){
	if(action==MenuAction_Select){
		if(!CanBuild(param1)) return;
		decl String:info[32];
		if(!GetMenuItem(menu, param2, info, sizeof(info))){
			return;
		}
		if(StrEqual(info, "b")){
			ShowMainMenu(param1);
			return;
		}else if(StrEqual(info,"a")){
			++rotationAxis[param1];
		}else if(StrEqual(info,"s")){
			SelectProp(param1);
		}else if(StrEqual(info,"r")){
			RotateProp(param1);
		}
		ShowRotationMenu(param1);
	}else if(action==MenuAction_End){
		CloseHandle(menu);
	}
}

public ShowUnlocksMenu(client){
	if(!IsValid(client) || IsClientSpec(client)) return;
	
	new bool:hasEverything=true;
	for(new i=0;i<unlocksCount;++i){
		if(!unlocksValid[i]
		|| HasUnlock(client, i) == unlocksMaxLevel[i]) continue;
		
		if(unlocksRequire[i]!=-1){
			if(HasUnlock(client, unlocksRequire[i])<unlocksRequireLevel[i]){
				continue;
			}
		}
		
		hasEverything=false;
		break;
	}
	
	new style=GetConVarInt(cv_unlock_menu_style);
	
	new Handle:menu;
	if(style || hasEverything){
		menu = CreateMenu(HandleUnlocksMenu);
		SetMenuTitle(menu, "Fortwars - Unlocks");
		AddMenuItem(menu, "b", "<- Back");
	}else{
		menu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Valve), HandleUnlocksMenu);
		SetMenuTitle(menu, "Fortwars\n\nClick on the unlock you want\nto buy it");
	}
	
	for(new i=0;i<unlocksCount;++i){
		if(!unlocksValid[i]
		|| HasUnlock(client, i) == unlocksMaxLevel[i]) continue;
		
		if(unlocksRequire[i]!=-1){
			if(HasUnlock(client, unlocksRequire[i])<unlocksRequireLevel[i]){
				continue;
			}
		}
		
		decl String:name[sizeof(unlocksName[])];
		decl String:num[4];
		IntToString(i, num, sizeof(num));
		
		strcopy(name, sizeof(name), unlocksName[i]);
		new cost=unlocksCost[i][HasUnlock(client, i)];
		
		decl String:desc[128];
		
		if(name[0]!='['){
			Format(name, sizeof(name), " %s", name);
		}
		
		if(unlocksMaxLevel[i]>1){
			new dLevel = HasUnlock(client, i)+1;
			if(style){
				Format(desc, sizeof(desc), "[$%d] %s (Level %d)", cost, name, dLevel);
			}else{
				Format(desc, sizeof(desc), "%s - $%d - Level %d", name, cost, dLevel);
			}
		}else{
			if(style){
				Format(desc, sizeof(desc), "[$%d] %s", cost, name);
			}else{
				Format(desc, sizeof(desc), "%s - $%d", name, cost);
			}
		}
		
		if(HasMoney(client, cost)){
			AddMenuItem(menu, num, desc);
		}else{
			AddMenuItem(menu, "", desc, ITEMDRAW_DISABLED);
		}
	}
	
	if(hasEverything){
		AddMenuItem(menu, "", "You already have every unlock", ITEMDRAW_DISABLED);
	}
	
	if(style){
		SetMenuExitButton(menu, true);
	}else{
		SetMenuExitButton(menu, false); // Doesn't seem to work
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HandleUnlocksMenu(Handle:menu, MenuAction:action, param1, param2){
	if(action==MenuAction_Select){
		if(!IsValid(param1) || IsClientSpec(param1)) return;
		decl String:info[32];
		if(!GetMenuItem(menu, param2, info, sizeof(info))){
			return;
		}
		if(StrEqual(info, "b")){
			ShowMainMenu(param1);
			return;
		}
		new unlockNum = StringToInt(info);
		
		BuyUnlock(param1, unlockNum);
		ShowUnlocksMenu(param1);
	}else if(action==MenuAction_End){
		CloseHandle(menu);
	}
}

public ShowHelpMenu(client){
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "Fortwars - Help");
	DrawPanelText(menu, " ");
	DrawPanelText(menu, "  FortWars Commands:");
	DrawPanelText(menu, "    /fwmenu - Opens FortWars Menu");
	DrawPanelText(menu, "    /fwmoney - Gets how much money a player has");
	DrawPanelText(menu, "    /fwunstuck - Unstucks you");
	DrawPanelText(menu, "    /fwresetspawn - Resets your spawn point");
	DrawPanelText(menu, "    /fwgivemoney - Gives a certain money to another player");
	
	DrawPanelText(menu, " ");
	
	SetPanelCurrentKey(menu, 10);
	DrawPanelItem(menu, "Exit");
	
	SendPanelToClient(menu, client, HandleHelpMenu, MENU_TIME_FOREVER);
	
	CloseHandle(menu);
}

public HandleHelpMenu(Handle:menu, MenuAction:action, param1, param2){
}

//////////////////////////////////////////////////////////////////////////////

stock SaveMoneyAll(){
	if(!sql) return;
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i) && IsClientAuthorized(i)){
			SaveMoney(i);
		}
	}
}

#define MAX_UNLOCKS_STRING_SIZE 8000


stock LoadMoneyAll(){
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientConnected(i)) continue;
		if(!IsClientAuthorized(i)) continue;
		LoadMoney(i);
	}
}

stock LoadMoney(client){
	if(!sql){
		money[client]=GetConVarInt(cv_money_start);
		return;
	}
	if(!IsClientAuthorized(client)) return;
	if(hSql==INVALID_HANDLE){
		sql=false;
		ConnectToSQL(false);
		if(hSql==INVALID_HANDLE){
			return;
		}
	}
	
	decl String:query[512+MAX_UNLOCKS_STRING_SIZE];
	decl String:auth[64];
	decl String:eauth[128];
	GetClientAuthString(client, auth, sizeof(auth));
	SQL_EscapeString(hSql, auth, eauth, sizeof(eauth));
	
	Format(query, sizeof(query), "SELECT money, unlocks FROM fw_users WHERE auth='%s'", eauth);
	
	SQL_TQuery(hSql, SQLT_LoadMoney, query, GetClientUserId(client), DBPrio_High);
}
public SQLT_LoadMoney(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(owner==INVALID_HANDLE || hndl==INVALID_HANDLE){
		LogError("SQL Error: %s", error);
		return;
	}
	
	new client=GetClientOfUserId(data);
	
	if(client<=0) return;
	
	if(SQL_GetRowCount(hndl)==0){
		decl String:query[256];
		decl String:auth[64];
		decl String:eauth[128];
		
		GetClientAuthString(client, auth, sizeof(auth));
		SQL_EscapeString(hSql, auth, eauth, sizeof(eauth));
		
		WipeClient(client);
		
		Format(query, sizeof(query), "INSERT INTO fw_users (money, unlocks, auth) VALUES (%d, '', '%s')", money[client], eauth);
		
		SQL_TQuery(hSql, SQLT_Error, query, _, DBPrio_High);
		
		if(started && IsClientInGame(client)){
			PrintToChat(client, "%s Welcome, new user!", PLUGIN_PREFIX);
		}
	}else{
		decl String:unlockss[MAX_UNLOCKS_STRING_SIZE];
		SQL_FetchRow(hndl);
		new field;
		SQL_FieldNameToNum(hndl, "money", field)
		money[client] = SQL_FetchInt(hndl, field);
		canSaveMoney[client]=true;
		
		SQL_FieldNameToNum(hndl, "unlocks", field)
		SQL_FetchString(hndl, field, unlockss, sizeof(unlockss));
		ParseUnlocksString(client, unlockss);
		
		if(started && IsClientInGame(client)){
			PrintToChat(client, "%s Loaded your money and unlocks from database", PLUGIN_PREFIX);
		}
	}
}

stock SaveMoney(client){
	if(!sql) return;
	if(!IsClientAuthorized(client)) return;
	if(!canSaveMoney[client]) return;
	if(hSql==INVALID_HANDLE){
		sql=false;
		ConnectToSQL();
		if(hSql==INVALID_HANDLE){
			return;
		}
	}
	LimitMoney(client);
	
	decl String:query[512+MAX_UNLOCKS_STRING_SIZE];
	decl String:auth[64];
	decl String:eauth[128];
	GetClientAuthString(client, auth, sizeof(auth));
	decl String:unlockss[MAX_UNLOCKS_STRING_SIZE];
	decl String:unlocksse[MAX_UNLOCKS_STRING_SIZE];
	CreateUnlocksString(client, unlockss, sizeof(unlockss));
	
	SQL_EscapeString(hSql, unlockss, unlocksse, sizeof(unlocksse));
	SQL_EscapeString(hSql, auth, eauth, sizeof(eauth));
	Format(query, sizeof(query), "UPDATE fw_users SET money=%d, unlocks='%s' WHERE auth='%s'", money[client], unlocksse, eauth);
	
	SQL_TQuery(hSql, SQLT_Error, query, _, DBPrio_Normal);
}

stock WipeClient(client){
	money[client]=GetConVarInt(cv_money_start);
		
	for(new i=0;i<sizeof(unlock[]);++i){
		unlock[client][i]=0;
	}
}

public SQLT_Error(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl==INVALID_HANDLE){
		LogError("SQL Error: %s", error);
	}
}

stock GetMoney(client){
	return money[client];
}

stock ShowMoney(client){
	PrintToChat(client, "%s Money: \x03$%d", PLUGIN_PREFIX, GetMoney(client));
}

stock AddMoneyToTeam(team, amount, bool:show=false, const String:reason[]="", any:...){
	decl String:res[512];
	VFormat(res, sizeof(res), reason, 5);
	
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i) && GetClientTeam(i)==team){
			AddMoney(i, amount, show, res);
		}
	}
}
stock AddImpreciseFakeMoney(client, amount, bool:show=false, const String:reason[]="", any:...){
	if(amount==0) return;
	amount=RoundFloat(amount*GetRandomFloat(MONEY_IMPRECISION_MIN, MONEY_IMPRECISION_MAX));
	decl String:str[256];
	VFormat(str, sizeof(str), reason, 5);
	AddFakeMoney(client, amount, show, str);
}

stock AddImpreciseMoney(client, amount, bool:show=false, const String:reason[]="", any:...){
	if(amount==0) return;
	amount=RoundFloat(amount*GetRandomFloat(MONEY_IMPRECISION_MIN, MONEY_IMPRECISION_MAX));
	decl String:str[256];
	VFormat(str, sizeof(str), reason, 5);
	AddMoney(client, amount, show, str);
}

stock AddFakeMoney(client, amount, bool:show=false, const String:reason[]="", any:...){
	if(amount==0) return;
	moneyOffset[client]+=amount;
	if(show){
		decl String:res[512];
		VFormat(res, sizeof(res), reason, 5);
		PrintToChat(client, "%s Money: \x03$%d\x01 (\x03+%d %s\x01)", PLUGIN_PREFIX, money[client], amount, res);
	}
}

stock AddMoney(client, amount, bool:show=false, const String:reason[]="", any:...){
	if(amount==0) return;
	moneyAdded[client]+=amount;
	moneyOffset[client]+=amount;
	money[client]+=amount;
	LimitMoney(client);
	if(show){
		decl String:res[512];
		VFormat(res, sizeof(res), reason, 5);
		PrintToChat(client, "%s Money: \x03$%d\x01 (\x03+%d %s\x01)", PLUGIN_PREFIX, money[client], amount, res);
	}
}


stock RemoveMoney(client, amount, bool:show=false, const String:reason[]="", any:...){
	if(amount==0) return;
	moneyOffset[client]-=amount;
	money[client]-=amount;
	LimitMoney(client);
	if(show){
		decl String:res[512];
		VFormat(res, sizeof(res), reason, 5);
		PrintToChat(client, "%s Money: \x03$%d\x01 (\x03-%d %s\x01)", PLUGIN_PREFIX, money[client], amount, res);
	}
}

stock LimitMoney(client){
	if(money[client]>MONEY_LIMIT){
		money[client]=MONEY_LIMIT;
	}
}

stock bool:HasMoney(client, amount){
	return money[client]>=amount;
}

stock BuyUnlock(client, unlockNum){
	if(HasUnlock(client, unlockNum)==unlocksMaxLevel[unlockNum]){
		PrintToChat(client, "%s You already have this unlock", PLUGIN_PREFIX);
		return;
	}
	if(unlocksRequire[unlockNum]!=-1){
		if(HasUnlock(client, unlocksRequire[unlockNum])<unlocksRequireLevel[unlockNum]){
			PrintToChat(client, "%s You do not have the required unlock", PLUGIN_PREFIX);
			return;
		}
	}
	new cost=unlocksCost[unlockNum][HasUnlock(client, unlockNum)];
	if(!HasMoney(client, cost)){
		PrintToChat(client, "%s Not enough money", PLUGIN_PREFIX);
		return;
	}
	if(unlocksMaxLevel[unlockNum]>1){
		RemoveMoney(client, cost, true, "Bought '%s (Level %d)'", unlocksName[unlockNum], HasUnlock(client, unlockNum)+1);
	}else{
		RemoveMoney(client, cost, true, "Bought '%s'", unlocksName[unlockNum]);
	}
	++unlock[client][unlockNum];
	SaveMoney(client);
}

//////////////////////////////////////////////////////////////////////////////

stock Unstuck(client){
	if(!hasCustomSpawnPoint[client]){
		clearSpawn[client]=true;
	}
	teleport[client]=true;
	teleportPos[client]=spawnPos[client];
	GetClientEyeAngles(client, teleportAng[client]);
	if(GetEntProp(client, Prop_Send, "m_iClass") != GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass")){
		TF2_RespawnPlayer(client);
	}else{
		TF2_RegeneratePlayer(client);
	}
}

stock SetSpawn(client){
	if(!IsValid(client)) return;
	if(IsClientSpec(client)){
		ShowError(client, _, "You cannot set a spawn point as spectator");
		return;
	}
	if(!IsPlayerAlive(client)){
		ShowError(client, _, "You must be alive to set a spawn point");
		return;
	}
	if(GetEntProp(client, Prop_Send, "m_bDucked")
	|| GetEntProp(client, Prop_Send, "m_bDucking")
	){
		ShowError(client, _, "You cannot set a spawn point while ducked");
		return;
	}
	hasCustomSpawnPoint[client]=true;
	GetClientAbsOrigin(client, spawnPos[client]);
	GetClientAbsOrigin(client, spawnPointPos[client]);
	GetClientEyeAngles(client, spawnPointAng[client]);
	ShowSuccess(client, _, "Spawn point set! You'll spawn here when you die");
	PrintToChat(client, "%s To reset your spawn point, type \x04/fwresetspawn", PLUGIN_PREFIX);
}

stock DeleteProp(client){
	new ent=GetClientAimTargetFW(client);
	new FWProp:prop=EntToProp(ent);
	if(prop==INVALID_PROP){
		ShowError(client, _, "Please aim at a prop");
		return;
	}
	if(!IsPropOwner(client, prop)){
		ShowError(client, _, "You are not the owner of this prop");
		return
	}
	
	PropDestroyed(prop);
	Dissolve(ent, 3);
}

stock GetClientAimTargetFW(client){
	if(!IsPlayerAlive(client)) return -1;
	decl Float:StartOrigin[3];
	decl Float:Angles[3];
	GetClientEyePosition(client, StartOrigin);
	GetClientEyeAngles(client, Angles);
	new Handle:TraceRay = TR_TraceRayFilterEx(StartOrigin, Angles, MASK_CUSTOM, RayType_Infinite, TraceRayProp);
	new ent=TR_GetEntityIndex(TraceRay);
	CloseHandle(TraceRay);
	return ent;
}

stock BreakProp(FWProp:prop){
	new ent=props[prop];
	AcceptEntityInput(ent, "Break");
}

stock RefundProp(FWProp:prop, Float:refund){
	new owner=propsOwner[prop];
	if(!IsValid(owner)) return 0;
	new propid = propsType[prop];
	new cost;
	new ent=props[prop];
	
	if(refund<0.0){
		cost = aPropsCost[propid];
		moneySpentOnProps[owner]-=cost; // It's still setup, let's not count it
		moneyAdded[owner]-=cost; // To counter what the AddMoney function will do
	}else if(!IsValidEntity(ent)){
		cost = 0;
	}else{
		cost = RoundFloat((GetEntityHealth(ent)/float(GetEntityMaxHealth(ent)))*aPropsCost[propid]*refund);
	}
	if(cost>0){
		AddMoney(owner, cost);
	}
	propsRefund[prop]=false;
	return cost;
}
stock SelectProp(client){
	new ent=GetClientAimTargetFW(client);
	new FWProp:prop=EntToProp(ent);
	if(prop==INVALID_PROP){
		ShowError(client, _, "Please aim at a prop");
		return;
	}
	if(!IsPropOwner(client, prop)){
		ShowError(client, _, "You are not the owner of this prop");
		return
	}
	if(aPropsStick[propsType[prop]]){
		ShowError(client, _, "This prop cannot be rotated");
		return
	}
	selectedEntRef[client] = EntIndexToEntRef(ent);
}

stock ShowSuccess(client, Float:duration=5.0, const String:msg[]){
	ShowMessage(client, Error, -1.0, 0.40, duration, Green, msg); 
}

stock ShowError(client, Float:duration=5.0, const String:error[]){
	ShowMessage(client, Error, -1.0, 0.40, duration, Red, error); 
}

stock ShowMessage(client, Channel:channel, Float:x, Float:y, Float:duration, TextColor:color=White, const String:msg[]){
	new r,g,b;
	
	if(color==Team){
		switch(TFTeam:GetClientTeam(client)){
			case TFTeam_Red:	{ color=Red; }
			case TFTeam_Blue:	{ color=Blue; }
			default:		{ color=White; }
		}
	}else if(color==DarkTeam){
		switch(TFTeam:GetClientTeam(client)){
			case TFTeam_Red:	{ color=DarkRed; }
			case TFTeam_Blue:	{ color=DarkBlue; }
			default:		{ color=White; }
		}
	}
	
	switch(color){
		case Red:		{r=255;	g=0;	b=0;	}
		case Blue:		{r=0;	g=0;	b=255;	}
		case DarkRed:	{r=128;	g=0;	b=0;	}
		case DarkBlue:	{r=0;	g=0;	b=128;	}
		case Green:		{r=0;	g=255;	b=0;	}
		case Black:		{r=0;	g=0;	b=0;	}
		case Yellow:	{r=255;	g=255;	b=0;	}
		default:		{r=255;	g=255;	b=255;	}
	}
	
	
	SetHudTextParams(x, y, duration, r, g, b, 255);
	ShowHudText(client, _:channel, msg);
}


public FWProp:CreateProp(client, propid){
	if(IsClientSpec(client)) return INVALID_PROP;
	new FWProp:prop = SearchAvaliableProp();
	new TFTeam:team = TFTeam:GetClientTeam(client);
	
	if(IsClientSpec(client)){
		ShowError(client, _, "You can't defend the nothing, you must join in a team first");
		return INVALID_PROP;
	}
	if(prop==INVALID_PROP){
		ShowError(client, _, "No avaliable prop index");
		return INVALID_PROP;
	}
	if(!teamCanBuild[team]){
		ShowError(client, _, "Your team cannot build props");
		return INVALID_PROP;
	}
	if(!HasMoney(client,aPropsCost[propid])){
		ShowError(client, _, "You don't have enough money");
		return INVALID_PROP;
	}
	
	new countCost=aPropsCountAs[propid];
	if(propsTeamCount[team]+countCost>GetConVarInt(cv_max_team)){
		ShowError(client, _, "Your team cannot build any more props");
		return INVALID_PROP;
	}
	if(propsPlayerCount[client]+countCost>GetPlayerPropLimit(client)){
		ShowError(client, _, "You cannot build any more props");
		return INVALID_PROP;
	}
	
	if(!CanBuild(client)){
		return INVALID_PROP;
	}
	new bool:allow=true;
	// OnPropBuilt_Pre(builder, bool:&allow, FWAProp:propid);
	Call_StartForward(fwd_propbuilt_pre);
	Call_PushCell(client);
	Call_PushCellRef(allow);
	Call_PushCell(propid);
	Call_Finish();
	if(!allow) return INVALID_PROP;
	
	decl Handle:TraceRay;
	decl Float:StartOrigin[3], Float:Angles[3];
	GetClientEyeAngles(client, Angles);
	GetClientEyePosition(client, StartOrigin);
	TraceRay = TR_TraceRayFilterEx(StartOrigin, Angles, MASK_CUSTOM, RayType_Infinite, TraceRayProp);
	if(TR_DidHit(TraceRay)){
		decl Float:Distance;
		decl Float:PositionBuffer[3], Float:EndOrigin[3];
		TR_GetEndPosition(EndOrigin, TraceRay);
		Distance = (GetVectorDistance(StartOrigin, EndOrigin));
		
		PositionBuffer = EndOrigin;
		
		PositionBuffer[0] += aPropsPosOffset[propid][0];
		PositionBuffer[1] += aPropsPosOffset[propid][1];
		PositionBuffer[2] += aPropsPosOffset[propid][2];
		
		
		if(Distance<MAX_DISTANCE_CREATE_PROP){
			new NB:nobuild = IsInNoBuildArea(EndOrigin);
			if(nobuild!=NB_CanBuild){
				switch(nobuild){
					case NB_Respawn:{
						ShowError(client, _, "You cannot build in respawn");
					}
					case NB_Intel:{
						ShowError(client, _, "You cannot build so close to the intelligence");
					}
					case NB_CP:{
						ShowError(client, _, "You cannot build so close to the control point");
					}
					default:{
						ShowError(client, _, "You cannot build there");
					}
				}
				CloseHandle(TraceRay);
				return INVALID_PROP;
			}
			
			new entHit=TR_GetEntityIndex(TraceRay);
			if(entHit!=0){
				decl String:name[64];
				GetEntPropString(entHit, Prop_Data, "m_iClassname", name, sizeof(name));
				if(StrEqual("func_door", name, false)){
					ShowError(client, _, "You cannot build there");
					CloseHandle(TraceRay);
					return INVALID_PROP;
				}
			}
			
			// From here, the prop WILL be created
			
			AddPropCount(client, countCost);
			
			new ent=0;
			new health = RoundToCeil(aPropsHealth[propid]*GetConVarFloat(cv_health_multipler));
			decl String:model[MAX_TARGET_LENGTH];
			GetPropIdModel(propid, model, sizeof(model));
			ent = CreatePropEntity(PositionBuffer, model, health, client);
			
			props[prop]=ent;
			propsOwner[prop]=client;
			propsType[prop]=propid
			propsTeam[prop]=team;
			propsRefund[prop]=true;
			if(GetConVarBool(cv_stuck_protection)){
				propsNotSolid[prop]=true;
				PropDisableCollision(prop);
			}
			ColorProp(prop, ent);
			
			if(aPropsStick[propid]){
				decl Float:normal[3];
				TR_GetPlaneNormal(TraceRay, normal);
				GetVectorAngles(normal, normal);
				
				propsAng[prop][0] = normal[0];
				propsAng[prop][1] = normal[1];
				propsAng[prop][2] = normal[2];
			}else{
				propsAng[prop][0] = 0.0
				propsAng[prop][1] = Angles[1]-180.0
				propsAng[prop][2] = 0.0
			}
			
			propsAng[prop][0] += aPropsAnglesOffset[propid][0];
			propsAng[prop][1] += aPropsAnglesOffset[propid][1];
			propsAng[prop][2] += aPropsAnglesOffset[propid][2];
			
			propsPos[prop]=PositionBuffer;
			TeleportEntity(ent, propsPos[prop],propsAng[prop],NULL_VECTOR);
			// OnPropBuilt(client, ent, prop, propid, const Float:pos[3], const Float:ang[3]);
			Call_StartForward(fwd_propbuilt);
			Call_PushCell(client);
			Call_PushCell(ent);
			Call_PushCell(prop);
			Call_PushCell(propid);
			Call_PushArray(propsPos[prop], 3);
			Call_PushArray(propsAng[prop], 3);
			Call_Finish();
		}
	}
	CloseHandle(TraceRay);
	return prop;
}

public bool:TraceRayProp(entityhit, mask) {
	if(IsValid(entityhit)){
		return false;
	}
	decl String:name[64];
	GetEntPropString(entityhit, Prop_Data, "m_iClassname", name, sizeof(name));
	if(StrEqual("func_respawnroomvisualizer", name)){
		return false;
	}
	
	return true;
}

public bool:TraceRayDontHitPlayerAndWorld(entityhit, mask) {
	return entityhit>MaxClients
}
public bool:TraceRayHitOnlyEnt(entityhit, mask, any:data) {
	return entityhit==data;
}

stock RotateProp(client){
	new ent = EntRefToEntIndex(selectedEntRef[client]);
	new FWProp:prop = EntToProp(ent);
	if(prop==INVALID_PROP||ent==-1||!IsValidEntity(ent)){
		ShowError(client, _, "This prop doesn't exist anymore");
		return;
	}
	if(!IsPropOwner(client, prop)){
		ShowError(client, _, "You are not the owner of this prop");
		return
	}
	if(aPropsStick[propsType[prop]]){
		ShowError(client, _, "This prop cannot be rotated");
		return
	}
	
	new propid=propsType[prop];
	
	decl Float:StartOrigin[3], Float:Angles[3];
	GetClientEyeAngles(client, Angles);
	GetClientEyePosition(client, StartOrigin);
	new Handle:TraceRay = TR_TraceRayFilterEx(StartOrigin, Angles, MASK_CUSTOM, RayType_Infinite, TraceRayProp);
	if(TR_DidHit(TraceRay)){
		decl Float:EndOrigin[3];
		TR_GetEndPosition(EndOrigin, TraceRay);
		
		decl Float:tmpangs[3];
		decl Float:newangs[3];
		MakeVectorFromPoints(propsPos[prop],EndOrigin,tmpangs);
		GetVectorAngles(tmpangs,newangs);
		if(rotationAxis[client]==1){
			propsAng[prop][0]=newangs[0]+aPropsAnglesOffset[propid][0];
		}else{
			propsAng[prop][1]=newangs[1]+aPropsAnglesOffset[propid][1];
			propsAng[prop][2]=newangs[2]+aPropsAnglesOffset[propid][2];
		}
		
		if(GetConVarBool(cv_stuck_protection)){
			propsNotSolid[prop]=true;
			PropDisableCollision(prop);
		}
		
		ColorProp(prop, ent);
		TeleportEntity(ent,NULL_VECTOR,propsAng[prop],NULL_VECTOR);
		
		// OnPropRotated(client, ent, prop, propid, const Float:pos[3], const Float:ang[3]);
		Call_StartForward(fwd_proprotated);
		Call_PushCell(client);
		Call_PushCell(ent);
		Call_PushCell(prop);
		Call_PushCell(propid);
		Call_PushArray(propsPos[prop], 3);
		Call_PushArray(propsAng[prop], 3);
		Call_Finish();
	}
	CloseHandle(TraceRay);
}

public PropDestroyed(FWProp:prop){
	if(props[prop]==INVALID_ENT) return;
	
	//OnPropDestroyed(ent, FWProp:prop);
	Call_StartForward(fwd_propdestroyed);
	Call_PushCell(props[prop]);
	Call_PushCell(prop);
	Call_Finish();
	
	props[prop]=INVALID_ENT;
}

stock FWProp:SearchAvaliableProp(){
	if(GetEntityCount()>GetMaxEntities()-32){
		return INVALID_PROP;
	}
	
	for(new i=0;i<=sizeof(props);i++){
		if(props[i]==INVALID_ENT){
			if(propsCount<=i) propsCount=i+1;
			return FWProp:i;
		}
	}
	return INVALID_PROP;
}


public CreatePropEntity(Float:pos[3],String:model[],health,client){
	new ent=-1;
	if(GetConVarBool(cv_lulz)){
		// Maximum lulz
		ent = CreateEntityByName("prop_physics_override");
	}else{
		ent = CreateEntityByName("prop_dynamic_override");
	}
	
	SetEntityModel(ent, model);
	
	new shadows=GetConVarInt(cv_shadows);
	if(shadows==0){
		DispatchKeyValue(ent, "disableshadows", "1");
		DispatchKeyValue(ent, "disablereceiveshadows", "1");
	}else if(shadows==2){
		DispatchKeyValue(ent, "disablereceiveshadows", "1");
	}
	
	DispatchSpawn(ent);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2); 
	
	DispatchKeyValue(ent, "Solid", "6");
	
	SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
	SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 5);
	SetEntProp(ent, Prop_Data, "m_usSolidFlags", 16);
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
	
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	
	AcceptEntityInput(ent, "DisableCollision");
	AcceptEntityInput(ent, "EnableCollision");
	
	SetEntityRenderColor(ent, 255, 255, 255, 255);
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", health);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
	
	HookSingleEntityOutput(ent, "OnBreak", propBreak, false);
	HookSingleEntityOutput(ent,"OnHealthChanged",propDamaged, false);
	TeleportEntity(ent,pos,NULL_VECTOR,NULL_VECTOR);
	
	
	return ent;
}

stock bool:IsClientSpec(client){
	return GetClientTeam(client)<2;
}

public FWProp:EntToProp(ent){
	if(ent<=0) return INVALID_PROP;
	for(new i=0;i<propsCount;++i){
		if(props[i]==ent){
			return FWProp:i;
		}
	}
	return INVALID_PROP;
}

public bool:IsPropOwner(client, FWProp:prop){
	if(prop==INVALID_PROP) return false;
	new AdminId:adm = GetUserAdmin(client);
	new bool:isAdmin = GetAdminFlag(adm, Admin_Ban) || GetAdminFlag(adm, Admin_Root);
	new bool:isOwner = propsOwner[prop]==client || propsOwner[prop]==0;
	return isOwner || isAdmin;
}

public propBreak(const String:output[], caller, activator, Float:delay){
	new FWProp:prop = EntToProp(caller);
	if(prop==INVALID_PROP){
		return;
	}
	
	PropDestroyed(prop);
}

public propDamaged(const String:output[], caller, activator, Float:delay){
	new FWProp:prop=EntToProp(caller);
	if(prop==INVALID_PROP){
		return;
	}
	
	if(inSetup){
		new attacker=activator;
		new owner=propsOwner[prop];
		if(attacker==owner){
			if(IsValid(owner)){
				ShowError(attacker, _, "You are attacking your own prop!\nIf you want to remove it, use Delete Prop");
			}
		}else if(IsValid(attacker) && IsValid(owner)){
			if(GetClientTeam(attacker) == GetClientTeam(owner)){
				ShowError(attacker, _, "You are attacking a teammate prop!\nIf you need to unstuck, type /fwunstuck");
			}
		}
	}
	
	ColorProp(prop, caller);
}

public OnFlagDropped(const String:output[], caller, activator, Float:delay){
	new ent=caller;
	decl Float:pos[3];
	new Float:ang[3];
	new owner = GetEntPropEnt(ent, Prop_Send, "m_hPrevOwner");
	if(owner<=0 || owner>MaxClients || !IsClientInGame(owner)) return;
	
	GetEntPropVector(owner, Prop_Send, "m_vecOrigin", pos);
	
	ang[0]=90.0;
	new Handle:ray = TR_TraceRayFilterEx(pos, ang, MASK_CUSTOM, RayType_Infinite, TraceRayProp);
	if(TR_DidHit(ray)){
		TR_GetEndPosition(pos, ray);
		pos[2]+=8.0;
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	}
	
	CloseHandle(ray);
}
public bool:TraceRayFlag(entityhit, mask, any:data) {
	if(entityhit==0) return true;
	if(entityhit>0&&entityhit<=MaxClients) return false;
	return entityhit!=data;
}
public bool:TraceRayWorldOnly(entityhit, mask) {
	return entityhit==0;
}
public bool:TraceRayPropsOnly(entityhit, mask) {
	return EntToProp(entityhit)!=INVALID_PROP;
}
public bool:TraceRayNoProp(entityhit, mask) {
	if(entityhit==0) return true;
	if(entityhit>0&&entityhit<=MaxClients) return false;
	return EntToProp(entityhit)==INVALID_PROP;
}
stock BreakAllProps(){
	for(new i=0;i<propsCount;++i){
		if(props[i]==INVALID_ENT) continue;
		if(!IsValidEntity(props[i])) continue;
		BreakProp(i);
	}
}

stock RefundAllTeamProps(team, Float:refunda){
	new refund[MAXPLAYERS+1];
	for(new i=0;i<propsCount;++i){
		if(props[i]==INVALID_ENT) continue;
		if(!IsValidEntity(props[i])) continue;
		if(_:propsTeam[i]!=team) continue;
		new FWProp:prop = FWProp:i;
		refund[propsOwner[prop]]+=RefundProp(prop, refunda);
	}
	for(new i=1;i<=MaxClients;++i){
		if(refund[i]>0){
			AddFakeMoney(i, refund[i], true, "Prop Refund");
		}
	}
}

stock RefundAllProps(Float:refunda){
	new refund[MAXPLAYERS+1];
	for(new i=0;i<propsCount;++i){
		if(props[i]==INVALID_ENT) continue;
		if(!IsValidEntity(props[i])) continue;
		new FWProp:prop = FWProp:i;
		refund[propsOwner[prop]]+=RefundProp(prop, refunda);
	}
	for(new i=1;i<=MaxClients;++i){
		if(refund[i]>0){
			AddFakeMoney(i, refund[i], true, "Prop Refund");
		}
	}
}
stock RestoreAllPropsHealth(){
	for(new i=0;i<propsCount;++i){
		if(props[i]==INVALID_ENT) continue;
		if(!IsValidEntity(props[i])) continue;
		SetEntityHealth2(props[i], GetEntityMaxHealth(props[i]));
		ColorProp(FWProp:i, props[i]);
	}
}

stock ColorProp(FWProp:prop, ent){
	if(propsNotSolid[prop]){
		if(propsTeam[prop]==TFTeam_Red){
			SetEntityRenderColor(ent, 255, 128, 128, 255);
		}else{
			SetEntityRenderColor(ent, 128, 128, 255, 255);
		}
	}else{
		new Float:maxhealth=float(GetEntityMaxHealth(ent));
		new Float:health=float(GetEntityHealth(ent));
		new perc=RoundFloat(health/maxhealth*255.0)
		SetEntityRenderColor(ent, perc, perc, perc, 255);
	}
}

stock GetEntityHealth(ent){
	return GetEntProp(ent,Prop_Data,"m_iHealth");
}

stock GetEntityMaxHealth(ent){
	return GetEntProp(ent,Prop_Data,"m_iMaxHealth");
}

stock PropEnableCollision(FWProp:prop){
	new ent=props[prop];
	
	AcceptEntityInput(ent, "EnableCollision");
	
	// This is a little hack to fix the client prediction
	decl Float:tmp[3];
	tmp=propsAng[prop];
	tmp[0]+=0.1;
	TeleportEntity(ent, propsPos[prop], tmp, NULL_VECTOR);
	propsTeleport[prop]=true;
}

stock PropDisableCollision(FWProp:prop){
	AcceptEntityInput(props[prop], "DisableCollision");
}

stock SetEntityHealth2(ent, health){
	// The native SetEntityHealth doesn't work
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
}

stock bool:CanBuild(client){
	new TFTeam:team=TFTeam:GetClientTeam(client);
	return IsValid(client) && (inSetup || !playing) && (team!=TFTeam_Unassigned && team!=TFTeam_Spectator) && teamCanBuild[team];
}

stock GetPropIdModel(propid, String:model[], size){
	if(!aPropsDynamic[propid]){
		strcopy(model, size, aPropsPath[propid]);
	}else{
		new did = aPropsDynamicId[propid];
		new modelId=GetRandomInt(0, aPropsDynamicCount[propid]-1);
		strcopy(model, size, aPropsDynamicPath[did][modelId]);
	}
}

stock FWAProp:DefineProp(const String:name[], const String:path[], health, cost, count=1, bool:stick=false, bool:dynamic=false, Float:posOffset[3]=NULL_VECTOR, Float:anglesOffset[3]=NULL_VECTOR){
	new FWAProp:i=SearchAvaliableAProp();
	strcopy(aPropsName[i], sizeof(aPropsName[]), name);
	strcopy(aPropsPath[i], sizeof(aPropsPath[]), path);
	aPropsValid[i]=true;
	aPropsHealth[i]=health;
	aPropsCost[i]=cost;
	aPropsStick[i]=stick;
	aPropsDynamic[i]=false;
	if(count<1) count=1;
	aPropsCountAs[i]=count;
	
	aPropsPosOffset[i]=posOffset;
	aPropsAnglesOffset[i]=anglesOffset;
	
	if(dynamic){
		aPropsDynamic[i]=true;
		aPropsDynamicId[i]=aDynamicPropsCount;
		aPropsDynamicCount[i]=0;
		++aDynamicPropsCount;
	}
	return i;
}

stock DefineDynamicPropPath(FWAProp:propid, const String:path[]){
	strcopy(aPropsDynamicPath[aPropsDynamicId[propid]][aPropsDynamicCount[propid]], sizeof(aPropsDynamicPath[][]), path);
	++aPropsDynamicCount[propid];
}

stock IsPlayerStuck(client){
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
	
	GetClientAbsOrigin(client, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayerAndWorld);
	return TR_GetEntityIndex();
}

stock bool:IsPlayerStuckInEnt(client, ent){
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
	
	GetClientAbsOrigin(client, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_ALL, TraceRayHitOnlyEnt, ent);
	return TR_DidHit();
}


stock bool:IsFwMap(){
	decl String:curMap[128];
	GetCurrentMap(curMap, sizeof(curMap));
	return strncmp("fw_", curMap, 3, false)==0;
}

stock CalculateSetupTime(){
	new m_nSetupTimeLength = FindSendPropOffs("CTeamRoundTimer", "m_nSetupTimeLength");
	new team_round_timer = FindEntityByClassname(-1, "team_round_timer");
	if(IsValidEntity(team_round_timer)){
		setupTime = GetEntData(team_round_timer,m_nSetupTimeLength);
	}
	return setupTime;
}

public Action:Timer_RespawnPlayer(Handle:timer, any:data){
	new client=GetClientOfUserId(data);
	if(client) TF2_RespawnPlayer(client);
}
public Action:Timer_Dissolve(Handle:timer, any:data){
	new client=GetClientOfUserId(data);
	if(!client) return;
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(ragdoll==-1) return;
	
	Dissolve(ragdoll, 0);
}
stock UnlockIdToIndex(const String:id[]){
	for(new i=0;i<unlocksCount;++i){
		if(unlocksValid[i] && StrEqual(unlocksId[i], id)){
			return i;
		}
	}
	return -1;
}

stock FWAProp:SearchAvaliableAProp(){
	for(new i=0;i<PROP_NUM;++i){
		if(!aPropsValid[i]){
			if(aPropsCount<=i) aPropsCount=i+1;
			return FWAProp:i;
		}
	}
	return INVALID_APROP;
}
stock SearchAvaliableUnlockIndex(){
	for(new i=0;i<MAX_UNLOCKS;++i){
		if(!unlocksValid[i]){
			if(unlocksCount<=i) unlocksCount=i+1;
			return i;
		}
	}
	return -1;
}

stock SearchAvaliableMenuItemIndex(){
	for(new i=0;i<MAX_MENUI;++i){
		if(!menuiValid[i]){
			if(menuiCount<=i) menuiCount=i+1;
			return i;
		}
	}
	return -1;
}

stock CreateUnlocksString(client, String:buffer[], bsize){
	decl String:str[MAX_UNLOCKS_STRING_SIZE];
	str[0]='\0';
	for(new i=0;i<unlocksCount;++i){
		if(!unlocksValid[i] || unlock[client][i]<=0) continue;
		decl String:fmt[sizeof(unlocksId[])+4];
		Format(fmt, sizeof(fmt), "%s=%d;", unlocksId[i], unlock[client][i]);
		StrCat(str, sizeof(str), fmt);
	}
	strcopy(buffer, bsize, str);
}

stock ParseUnlocksString(client, String:str[]){
	decl String:statements[MAX_UNLOCKS][sizeof(unlocksId[])+8];
	new count;
	
	
	count=ExplodeString(str, ";", statements, sizeof(statements), sizeof(statements[]));
	decl String:idvalue[MAX_UNLOCKS][2][sizeof(unlocksId[])];
	for(new i=0;i<count+1;++i){
		ExplodeString(statements[i],"=",idvalue[i],sizeof(idvalue[]), sizeof(idvalue[][]));
		
		new level = StringToInt(idvalue[i][1]);
		new ulk = UnlockIdToIndex(idvalue[i][0]);
		if(ulk!=-1){
			unlock[client][ulk]=level;
		}
	}
}

stock MenuItemIdToIndex(const String:id[]){
	for(new i=0;i<menuiCount;++i){
		if(menuiValid[i] && StrEqual(menuiId[i], id)){
			return i;
		}
	}
	return -1;
}

stock NB:IsInNoBuildArea(const Float:pos[3]){
	for(new i=0;i<nobuildCount;++i){
		if(IsInsideRect(pos, nobuildPosMin[i], nobuildPosMax[i])){
			return nobuildReason[i];
		}
	}
	return NB_CanBuild;
}

stock GetPlayerPropLimit(i){
	if(noPlayerLimit) return GetConVarInt(cv_max_team);
	
	if(GetAdminFlag(GetUserAdmin(i), Admin_Reservation)
	&& GetConVarInt(cv_max_player_admin)>GetConVarInt(cv_max_player)
	){
		return GetConVarInt(cv_max_player_admin);
	}
	
	return GetConVarInt(cv_max_player);
}

stock FindNoBuildAreas(){
	nobuildCount=0;
	new ent=-1;
	while((ent = FindEntityByClassname(ent, "item_teamflag"))!=-1){
		new Float:dist=OBJECTIVE_INTEL_MIN_DISTANCE;
		decl Float:pos[3];
		decl Float:posMin[3];
		decl Float:posMax[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		posMin[0] = pos[0]-dist;
		posMin[1] = pos[1]-dist;
		posMin[2] = pos[2]-dist;
		
		posMax[0] = pos[0]+dist;
		posMax[1] = pos[1]+dist;
		posMax[2] = pos[2]+dist;
		
		new i=nobuildCount++;
		nobuildPosMin[i]=posMin;
		nobuildPosMax[i]=posMax;
		nobuildReason[i]=NB_Intel;
	}
	ent=-1;
	while((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=-1){
		decl Float:posMin[3];
		decl Float:posMax[3];
		GetEntRect(ent, posMin, posMax);
		
		// The King Of The Flag uses a small control point area to make a fake CP, ignore it
		if(GetVectorDistance(posMin, posMax)<OBJECTIVE_CP_MIN_SIZE){
			continue;
		}
		
		new i=nobuildCount++;
		nobuildPosMin[i]=posMin;
		nobuildPosMax[i]=posMax;
		nobuildReason[i]=NB_CP;
	}
	
	ent=-1;
	while((ent = FindEntityByClassname(ent, "func_respawnroom"))!=-1){
		new i=nobuildCount++;
		GetEntRect(ent, nobuildPosMin[i], nobuildPosMax[i]);
		nobuildReason[i]=NB_Respawn;
	}
	
	ent=-1;
	decl String:name[64];
	while((ent = FindEntityByClassname(ent, "trigger_multiple"))!=-1){
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrEqual("fw_nobuild", name, false)){
			continue;
		}
		
		new i=nobuildCount++;
		GetEntRect(ent, nobuildPosMin[i], nobuildPosMax[i]);
		nobuildReason[i]=NB_Map;
	}
}

stock GetEntRect(ent, Float:posMin[3], Float:posMax[3], Float:dist=1.0){
	GetEntPropVector(ent, Prop_Send, "m_vecMins", posMin);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", posMax);
	decl Float:orig[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", orig);
	
	AddVectors(posMin, orig, posMin);
	AddVectors(posMax, orig, posMax);
	
	posMin[0] -= dist;
	posMin[1] -= dist;
	posMin[2] -= dist;
	posMax[0] += dist;
	posMax[1] += dist;
	posMax[2] += dist;
}

stock FindTimer(){
	timerEnt = FindEntityByClassname(-1, "team_round_timer");
	
	needSetupTimer = timerEnt>0 && FindEntityByClassname(-1, "team_control_point")>0 && FindEntityByClassname(-1, "item_teamflag")>0;
	
}

stock FixNoObserverCrash(){
	// I am too lazy to recompile all the maps, so I'll just add
	// this hack, it checks if there is an observer point, and if
	// there isn't, it creates one.
	// If there is an objective in the map, it will put the observer
	// point above it.
	if(FindEntityByClassname(-1, "info_observer_point")==-1){
		if(nobuildCount>0){
			for(new i=0;i<nobuildCount;++i){
				decl Float:pos[3];
				SubtractVectors(nobuildPosMax[i], nobuildPosMin[i], pos);
				ScaleVector(pos, 0.5);
				AddVectors(pos, nobuildPosMin[i], pos);
				pos[2]+=256.0;
				new ent=CreateEntityByName("info_observer_point");
				DispatchKeyValue(ent, "Angles", "90 0 0");
				DispatchKeyValue(ent, "TeamNum", "0");
				DispatchKeyValue(ent, "StartDisabled", "0");
				DispatchSpawn(ent);
				AcceptEntityInput(ent, "Enable");
				TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
			}
		}else{
			new ent=CreateEntityByName("info_observer_point");
			DispatchKeyValue(ent, "Angles", "90 0 0");
			DispatchKeyValue(ent, "TeamNum", "0");
			DispatchKeyValue(ent, "StartDisabled", "0");
			DispatchSpawn(ent);
			AcceptEntityInput(ent, "Enable");
			TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

stock FindMapPermissions(){
	new ent=-1;
	while((ent = FindEntityByClassname(ent, "tf_team"))!=-1){
		new TFTeam:team = TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum");
		// If role==2, it's an attacker team
		new bool:canbuild = GetEntProp(ent, Prop_Send, "m_iRole")!=2;
		if(team==TFTeam_Red || team==TFTeam_Blue){
			teamCanBuild[team]=canbuild;
		}
	}
}

stock bool:IsInsideRect(const Float:Pos[3], const Float:Corner1[3], const Float:Corner2[3]) { 
	decl Float:field1[2]; 
	decl Float:field2[2]; 
	decl Float:field3[2];  
	if(Corner1[0] < Corner2[0]){ 
		field1[0] = Corner1[0]; 
		field1[1] = Corner2[0]; 
	}else{ 
		field1[0] = Corner2[0]; 
		field1[1] = Corner1[0]; 
	}
	if(Corner1[1] < Corner2[1]){ 
		field2[0] = Corner1[1]; 
		field2[1] = Corner2[1]; 
	}else{ 
		field2[0] = Corner2[1]; 
		field2[1] = Corner1[1]; 
	}
	if(Corner1[2] < Corner2[2]){ 
		field3[0] = Corner1[2]; 
		field3[1] = Corner2[2]; 
	}else{ 
		field3[0] = Corner2[2]; 
		field3[1] = Corner1[2]; 
	} 
	if (Pos[0] < field1[0] || Pos[0] > field1[1]) return false; 
	if (Pos[1] < field2[0] || Pos[1] > field2[1]) return false; 
	if (Pos[2] < field3[0] || Pos[2] > field3[1]) return false; 

	return true; 
}

stock AddPropCount(builder, amount){
	new team = GetClientTeam(builder);
	propsPlayerCount[builder]+=amount;
	propsTeamCount[team]+=amount;
}

stock GetClientPropCount(i){
	return propsPlayerCount[i];
}

stock GetTeamPropCount(team){
	return propsTeamCount[team];
}

stock AddUnlock(const String:id[], const String:name[], numLevels, cost[], const String:required[]="", requireLevel=1){
	
	decl String:rid[sizeof(unlocksId[])];
	strcopy(rid, sizeof(rid), id);
	ReplaceString(rid, sizeof(rid), "=", "");
	ReplaceString(rid, sizeof(rid), ";", "");
	ReplaceString(rid, sizeof(rid), "'", "");
	
	if(strlen(rid)<3){
		return -1;
	}
	
	new index=UnlockIdToIndex(id);
	if(index!=-1){
		return index;
	}
	
	new i=SearchAvaliableUnlockIndex();
	
	if(numLevels<1) numLevels=1;
	if(numLevels>MAX_UNLOCK_LEVEL) numLevels = MAX_UNLOCK_LEVEL;
	
	unlocksValid[i]=true;
	
	new bool:isTheSame = StrEqual(rid, unlocksId[i]);
	
	strcopy(unlocksId[i], sizeof(unlocksId[]), rid);
	strcopy(unlocksName[i], sizeof(unlocksName[]), name);
	for(new j=0;j<numLevels;++j){
		unlocksCost[i][j]=cost[j];
	}
	unlocksMaxLevel[i]=numLevels;
	
	if(strlen(required)==0){
		unlocksRequire[i]=-1;
	}else{
		new rindex=UnlockIdToIndex(required);
		unlocksRequire[i]=rindex;
		unlocksRequireLevel[i]=requireLevel;
	}
	
	if(!isTheSame){
		for(new j=0;j<MAXPLAYERS;++j){
			unlock[j][i]=0;
		}
	}
	
	return i;
}

stock Dissolve(ent, type){
	if(!IsValidEntity(ent)) return;
	
	decl String:dname[32], String:dtype[32];
	Format(dname, sizeof(dname), "dis_%d", EntIndexToEntRef(ent));
	Format(dtype, sizeof(dtype), "%d", type);
	
	new dis = CreateEntityByName("env_entity_dissolver");
	if(dis>0){
		DispatchKeyValue(ent, "targetname", dname);
		DispatchKeyValue(dis, "dissolvetype", dtype);
		DispatchKeyValue(dis, "target", dname);
		DispatchKeyValue(dis, "magnitude", "10");
		AcceptEntityInput(dis, "Dissolve");
		AcceptEntityInput(dis, "Kill");
	}
}

stock ShowRect(const Float:vec1[3], const Float:vec2[3]){
	//TODO
}

stock HasUnlock(client, ulk){
	if(!IsValid(client)) return 0;
	if(IsFakeClient(client)) return unlocksMaxLevel[ulk];
	new f=GetUserFlagBits(client);
	if(f&ADMFLAG_RESERVATION || f&ADMFLAG_ROOT){
		return unlocksMaxLevel[ulk];
	}
	return unlock[client][ulk];
}

stock IsValid(client){
	if(client<=0){
		return false;
	}
	if(client>MaxClients){
		return false;
	}
	if(!IsClientInGame(client)){
		return false;
	}
	return true;
}


//////////////////////////////////////////////////////////////////////////////
// API
//////////////////////////////////////////////////////////////////////////////

public Native_AddUnlock(Handle:plugin, numParams){
	decl String:id[sizeof(unlocksId[])];
	GetNativeString(1, id, sizeof(id));
	
	ReplaceString(id, sizeof(id), "=", "");
	ReplaceString(id, sizeof(id), ";", "");
	ReplaceString(id, sizeof(id), "'", "");
	
	if(strlen(id)<3){
		ThrowNativeError(SP_ERROR_NATIVE, "Unlock Id must be at least 3 characters long");
		return -1;
	}
	
	new index=UnlockIdToIndex(id);
	if(index!=-1){
		return index;
	}
	
	decl String:name[sizeof(unlocksName[])];
	GetNativeString(2, name, sizeof(name));
	
	new cost=GetNativeCell(3);
	new rcost[1];
	rcost[0]=cost;
	return AddUnlock(id, name, 1, rcost);
}

public Native_AddUnlock2(Handle:plugin, numParams){
	decl String:id[sizeof(unlocksId[])];
	GetNativeString(1, id, sizeof(id));
	
	ReplaceString(id, sizeof(id), "=", "");
	ReplaceString(id, sizeof(id), ";", "");
	ReplaceString(id, sizeof(id), "'", "");
	
	if(strlen(id)<3){
		ThrowNativeError(SP_ERROR_NATIVE, "Unlock Id must be at least 3 characters long");
		return -1;
	}
	
	
	decl String:name[sizeof(unlocksName[])];
	GetNativeString(2, name, sizeof(name));
	
	new cost[MAX_UNLOCK_LEVEL+1];
	GetNativeArray(4, cost, sizeof(cost));
	
	if(numParams==4){
		return AddUnlock(id, name, GetNativeCell(3), cost);
	}else{
		decl String:required[sizeof(unlocksId[])];
		GetNativeString(5, required, sizeof(required));
		
		return AddUnlock(id, name, GetNativeCell(3), cost, required, GetNativeCell(6));
	}
}


public Native_HasUnlock(Handle:plugin, numParams){
	return HasUnlock(GetNativeCell(1), GetNativeCell(2));
}

public Native_RemoveUnlock(Handle:plugin, numParams){
	decl String:id[sizeof(unlocksId[])];
	GetNativeString(1, id, sizeof(id));
	
	new i = UnlockIdToIndex(id);
	if(i==-1) return false;
	
	unlocksValid[i]=false;
	
	
	return true;
}

public Native_UnlockExists(Handle:plugin, numParams){
	decl String:id[sizeof(unlocksId[])];
	GetNativeString(1, id, sizeof(id));
	
	return UnlockIdToIndex(id)!=-1;
}

public Native_UnlockIdToNumId(Handle:plugin, numParams){
	decl String:id[sizeof(unlocksId[])];
	GetNativeString(1, id, sizeof(id));
	
	return UnlockIdToIndex(id);
}

public Native_IsRunning(Handle:plugin, numParams){
	return started;
}

public Native_AddMenuItem(Handle:plugin, numParams){
	//const String:id[], const String:name[], bool:buildPhaseOnly=false, FW_ClientCallback:func
	
	decl String:id[sizeof(menuiId[])];
	GetNativeString(1, id, sizeof(id));
	
	if(strlen(id)<3){
		ThrowNativeError(SP_ERROR_NATIVE, "Menu Item Id must be at least 3 characters long");
		return -1;
	}
	new index=MenuItemIdToIndex(id);
	new i;
	if(index==-1){
		i=SearchAvaliableMenuItemIndex();
	}else{
		i=index;
	}
	
	menuiValid[i]=true;
	strcopy(menuiId[i], sizeof(menuiId[]), id);
	GetNativeString(2, menuiName[i], sizeof(menuiName[]));
	menuiBuildOnly[i] = bool:GetNativeCell(3);
	
	if(menuiCallback[i]!=INVALID_HANDLE){
		CloseHandle(menuiCallback[i]);
	}
	
	menuiCallback[i] = CreateForward(ET_Ignore, Param_Cell);
	
	AddToForward(menuiCallback[i], plugin, Function:GetNativeCell(4));
	
	return i;
}

public Native_RemoveMenuItem(Handle:plugin, numParams){
	decl String:id[sizeof(menuiId[])];
	GetNativeString(1, id, sizeof(id));
	
	new i = MenuItemIdToIndex(id);
	if(i==-1) return false;
	
	menuiValid[i]=false;
	return true;
}

public Native_ShowMainMenu(Handle:plugin, numParams){
	if(numParams==1){
		ShowMainMenu(GetNativeCell(1));
	}else{
		ShowMainMenu(GetNativeCell(1), GetNativeCell(2));
	}
}

public Native_AddProp(Handle:plugin, numParams){
	//const String:name[], const String:path[], health, cost, count, bool:stick, Float:posOffset[3], Float:anglesOffset[3]
	decl String:name[sizeof(aPropsName[])];
	GetNativeString(1, name, sizeof(name));
	
	for(new i=0;i<aPropsCount;++i){
		if(aPropsValid[i] && StrEqual(aPropsName[i], name)){
			return i;
		}
	}
	
	decl String:path[sizeof(aPropsPath[])];
	GetNativeString(2, path, sizeof(path));
	new health = GetNativeCell(3);
	new cost = GetNativeCell(4);
	new count = GetNativeCell(5);
	new bool:stick = bool:GetNativeCell(6);
	decl Float:pos[3];
	decl Float:ang[3];
	GetNativeArray(7, pos, sizeof(pos));
	GetNativeArray(8, ang, sizeof(ang));
	
	return _:DefineProp(name, path, health, cost, count, stick, false, pos, ang);
}

public Native_AddProp2(Handle:plugin, numParams){
	//const String:name[], health, cost, count, bool:stick=false, Float:posOffset[3]=NULL_VECTOR, Float:anglesOffset[3]=NULL_VECTOR
	decl String:name[sizeof(aPropsName[])];
	GetNativeString(1, name, sizeof(name));
	
	for(new i=0;i<aPropsCount;++i){
		if(aPropsValid[i] && StrEqual(aPropsName[i], name)){
			return i;
		}
	}
	
	new health = GetNativeCell(2);
	new cost = GetNativeCell(3);
	new count= GetNativeCell(4);
	new bool:stick = bool:GetNativeCell(5);
	decl Float:pos[3];
	decl Float:ang[3];
	GetNativeArray(6, pos, sizeof(pos));
	GetNativeArray(7, ang, sizeof(ang));
	
	return _:DefineProp(name, "", health, cost, count, stick, true, pos, ang);
}

public Native_AddPropModel(Handle:plugin, numParams){
	//FWAProp:propid, const String:path[]
	
	decl String:path[300];
	GetNativeString(2, path, sizeof(path));
	
	DefineDynamicPropPath(FWAProp:GetNativeCell(1),path);
}

public Native_SetPropEntity(Handle:plugin, numParams){
	new FWProp:prop = GetNativeCell(1);
	new ent = GetNativeCell(2);
	
	if(props[prop]==ent){
		return;
	}
	
	if(IsValidEntity(props[prop])){
		UnhookSingleEntityOutput(props[prop], "OnBreak", propBreak);
		UnhookSingleEntityOutput(props[prop], "OnHealthChanged",propDamaged);
	}
	
	props[prop]=ent;
	
	TeleportEntity(ent, propsPos[prop], propsAng[prop], NULL_VECTOR);
}

public Native_GetEntityProp(Handle:plugin, numParams){
	return _:EntToProp(GetNativeCell(1));
}

public Native_PropDestroyed(Handle:plugin, numParams){
	PropDestroyed(FWProp:GetNativeCell(1));
}

public Native_AddDependence(Handle:plugin, numParams){
	for(new i=0;i<myPluginsCount;++i){
		if(myPlugins[i]==plugin) return false;
	}
	myPlugins[myPluginsCount++] = plugin;
	return true;
}

public Native_AddPropCount(Handle:plugin, numParams){
	//client, amount
	AddPropCount(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetTeamPropCount(Handle:plugin, numParams){
	GetTeamPropCount(GetNativeCell(1));
}

public Native_GetClientPropCount(Handle:plugin, numParams){
	GetClientPropCount(GetNativeCell(1));
}

public Native_ShowError(Handle:plugin, numParams){
	decl String:error[256];
	GetNativeString(3, error, sizeof(error));
	ShowError(GetNativeCell(1), Float:GetNativeCell(2), error)
}
//////////////////////////////////////////////////////////////////////////////