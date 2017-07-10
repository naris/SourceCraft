/////////////////////////////////////////////////////////////////////
//
// RMF用インクルードファイル
//
/////////////////////////////////////////////////////////////////////
#if defined _tf2_events_included
#endinput
#endif
#define _tf2_events_included

/////////////////////////////////////////////////////////////////////
//
// インクルード
//
/////////////////////////////////////////////////////////////////////
#include "rmf/tf2_codes"

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define EVENT_PLAYER_CONNECT		"player_activate"				// プレイヤー接続
#define EVENT_PLAYER_DISCONNECT		"player_disconnect"				// プレイヤー切断
#define EVENT_PLAYER_DATA_RESET		"PlayerDataReset"				// プレイヤーデータリセット
#define EVENT_PLAYER_CHANGE_TEAM	"player_team"					// プレイヤーチーム変更
#define EVENT_PLAYER_CHANGE_CLASS	"player_changeclass"			// プレイヤークラス変更
#define EVENT_PLAYER_DAMAGE			"player_hurt"					// プレイヤーダメージ
#define EVENT_PLAYER_SPAWN			"player_spawn"					// プレイヤー復活
#define EVENT_PLAYER_SPAWN_DELAY	"PlayerSpawnDelay"				// プレイヤー復活
#define EVENT_PLAYER_DEATH			"player_death"					// プレイヤー死亡
#define EVENT_PLAYER_BUILT_OBJECT	"player_builtobject"			// プレイヤーオブジェクト建設
#define EVENT_PLAYER_REMOVE_OBJECT	"object_removed"				// プレイヤーオブジェクト破壊(自分で)
#define EVENT_PLAYER_RESUPPLY		"Player_Resupply"				// プレイヤーリサプライ
#define EVENT_PLAYER_STUNNED		"player_stunned"				// プレイヤースタン

#define EVENT_OBJECT_DESTROYED		"object_destroyed"				// 建設物破壊
#define EVENT_CP_START_TOUCH		"controlpoint_starttouch"		// CPタッチ開始
#define EVENT_CP_END_TOUCH			"controlpoint_endtouch"			// CPタッチ終了
#define EVENT_GAME_OVER				"tf_game_over"					// ゲーム終了
#define EVENT_GAME_END				"teamplay_game_over"			// ゲーム終了
#define EVENT_ROUND_START			"teamplay_round_start"			// ラウンド開始
#define EVENT_ROUND_ACTIVE			"teamplay_round_active"			// ラウンドアクティブ
#define EVENT_ARENA_ROUND_ACTIVE	"arena_round_start"				// アリーナラウンドアクティブ
#define EVENT_ROUND_WIN				"teamplay_round_win"			// ラウンド終了
#define EVENT_WIN_PANEL				"teamplay_win_panel"			// 勝利スコアボード
#define EVENT_ARENA_WIN_PANEL		"arena_win_panel"				// アリーナWinパネル
#define EVENT_SUDDEN_DEATH_START	"teamplay_round_stalemate"		// サドンデス開始
#define EVENT_WAIT_BEGIN			"teamplay_waiting_begins"		// プレイヤーを待っています開始
#define EVENT_WAIT_ABOUTTOEND		"teamplay_waiting_abouttoend"	// プレイヤーを待っています終了直前
#define EVENT_WAIT_END				"teamplay_waiting_ends"			// プレイヤーを待っています終了

#define EVENT_PLUGIN_START			"OnPluginStart"				// プラグイン開始
#define EVENT_PLUGIN_INIT			"InitPluginData"			// プラグイン初期化
#define EVENT_PLUGIN_FINAL			"FinalPluginData"			// プラグイン後始末
#define EVENT_PLUGIN_STATE_CHANGED	"PluginStateChanged"		// プラグインの状態変化
#define EVENT_GAME_FRAME			"OnGameFrame"				// ゲームフレーム
#define EVENT_MAP_START				"OnMapStart"				// マップ開始
#define EVENT_CONFIG_EXECUTED		"OnConfigsExecuted"			// 全てのロード完了
#define EVENT_MAP_END				"OnMapEnd"					// マップ終了

#define HintTextPages 4									// HintTextのページ数
#define HintTextMaxSize 256								// HintTex最大サイズ
#define HintTextInterval 8.0							// HintTexページ変更インターバル

#define AbilityNameMaxSize 64							// アビリティ名最大サイズ

/////////////////////////////////////////////////////////////////////
//
// グローバル変数(お決まりの)
//
/////////////////////////////////////////////////////////////////////
new bool:g_IsRunning = true;
new Handle:g_IsPluginOn = INVALID_HANDLE;
//new Float:g_LastTime[MAXPLAYERS+1] = 0.0;			// 最後のチェック時間
new Float:g_LastKeyCheckTime[MAXPLAYERS+1] = 0.0;			// 最後のチェック時間

new String:g_PlayerHintText[MAXPLAYERS+1][HintTextPages][HintTextMaxSize];	// HintText用
new Handle:g_HintTextTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// ヒントテキスト用タイマー
new g_PlayerHintPage[MAXPLAYERS+1] = 0;
new bool:g_PlayerReadyFeignDeath[MAXPLAYERS+1] = false;
new Handle:g_SpawnDelayTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// 復活ディレイタイマー

new Handle:g_ResupplyTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// リサプライタイマー

new bool:g_AbilityUnlock[MAXPLAYERS+1] = true;		// アビリティロック
new String:g_AbilityName[AbilityNameMaxSize];		// アビリティ名


/////////////////////////////////////////////////////////////////////
//
// アビリティ個別ON
//
/////////////////////////////////////////////////////////////////////
public Action:Command_AbilityStateChange(args)
{
	if(args < 3)
	{
		//ReplyToCommand(0, "Usage: rmf_ability <client> <ability name> <state(0/1)>");
		return Plugin_Handled;
	}

	new String:client_id[4];
	GetCmdArg(1, client_id, sizeof(client_id));
	new String:ability[AbilityNameMaxSize];
	GetCmdArg(2, ability, sizeof(ability));
	new String:var[2];
	GetCmdArg(3, var, sizeof(var));

	new client = StringToInt(client_id);
	if(client > 0 && IsClientInGame(client) && StrEqual(ability, g_AbilityName))
	{
		if(StringToInt(var) == 0)
		{
			g_AbilityUnlock[client] = false;
			PlayerDataReset( client );
			//PrintToChat(client, "%s:Reset", g_AbilityName);
		}
		else
		{
			g_AbilityUnlock[client] = true;
			PlayerDataReset(client);
			ClearTimer( g_SpawnDelayTimer[ client ] );
			g_SpawnDelayTimer[ client ] = CreateTimer(0.5, Timer_PlayerSpawnDelay, client);
		}
	}
	return Plugin_Handled;
}

/////////////////////////////////////////////////////////////////////
//
// MODのOn/Off後の挙動
//
/////////////////////////////////////////////////////////////////////
public PluginStateChanged()
{
	if ( g_IsRunning  )
	{
		// プラグインデータ初期化
		InitializePluginData()
	}
	else
	{
		// プラグインデータ後始末
		FinalizePluginData()
	}
	
	Event_FiredUser(INVALID_HANDLE, EVENT_PLUGIN_STATE_CHANGED);
//	PluginStateChangedUser();
}

/////////////////////////////////////////////////////////////////////
//
// プラグイン開始
//
/////////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	// 言語ファイル読込
	LoadTranslations("common.phrases");
	
	// イベントフック
	HookEvent(EVENT_PLAYER_CONNECT,			Event_Fired);
	HookEvent(EVENT_PLAYER_DISCONNECT,		Event_Fired,			EventHookMode_Pre);
	HookEvent(EVENT_PLAYER_CHANGE_TEAM,		Event_Fired);
	HookEvent(EVENT_PLAYER_CHANGE_CLASS,	Event_Fired);
	HookEvent(EVENT_PLAYER_DAMAGE,			Event_Fired);
	HookEvent(EVENT_PLAYER_SPAWN,			Event_Fired,			EventHookMode_Pre);
	HookEvent(EVENT_PLAYER_DEATH,			Event_Fired,			EventHookMode_Pre);
	HookEvent(EVENT_PLAYER_BUILT_OBJECT,	Event_Fired);
	HookEvent(EVENT_PLAYER_REMOVE_OBJECT,	Event_Fired);
	HookEvent(EVENT_PLAYER_STUNNED,			Event_Fired);

	HookEvent(EVENT_OBJECT_DESTROYED,		Event_Fired);
	HookEvent(EVENT_CP_START_TOUCH,			Event_Fired);
	HookEvent(EVENT_CP_END_TOUCH,			Event_Fired);
	HookEvent(EVENT_GAME_OVER,				Event_Fired);
	HookEvent(EVENT_GAME_END,				Event_Fired);
	HookEvent(EVENT_ROUND_START,			Event_Fired);
	HookEvent(EVENT_ROUND_ACTIVE,			Event_Fired);
	HookEvent(EVENT_ARENA_ROUND_ACTIVE,		Event_Fired);
	HookEvent(EVENT_ROUND_WIN,				Event_Fired);
	HookEvent(EVENT_WIN_PANEL,				Event_Fired);
	HookEvent(EVENT_ARENA_WIN_PANEL,		Event_Fired);
	HookEvent(EVENT_SUDDEN_DEATH_START,		Event_Fired);
	HookEvent(EVENT_WAIT_BEGIN,				Event_Fired);
	HookEvent(EVENT_WAIT_ABOUTTOEND,		Event_Fired);
	HookEvent(EVENT_WAIT_END,				Event_Fired);

	Event_FiredUser(INVALID_HANDLE,			EVENT_PLUGIN_START);

	// アビリティコマンド設定
	RegServerCmd("rmf_ability", Command_AbilityStateChange, "Usage: rmf_ability <client> <ability name> <state(0/1)>");

		
	// プラグインのファイル名取得
	GetPluginFilename(INVALID_HANDLE, g_AbilityName, sizeof(g_AbilityName));
	ReplaceString(g_AbilityName, sizeof(g_AbilityName), ".smx", "");

	// サウンドフック(ロッカー) 
	AddNormalSoundHook( HookResupplySound );		

	// 各プラグインの処理
//	OnPluginStartUser()
	
	// プラグインデータ初期化
	InitializePluginData();
	
	// ゲームコンフィグ初期化
	InitGameConf();
}

/////////////////////////////////////////////////////////////////////
//
// プラグイン終了
//
/////////////////////////////////////////////////////////////////////
public OnPluginEnd()
{
	// プラグインデータ後処理
	FinalizePluginData();
	
	// アイテムデータ後処理
	FinalItemData();
}

/////////////////////////////////////////////////////////////////////
//
// 初期化
//
/////////////////////////////////////////////////////////////////////
public InitializePluginData()
{

	new maxclients = GetMaxClients();
	for (new client = 1; client <= maxclients; client++)
	{
		// プレイヤーデータリセット
		PlayerDataReset( client );
		
		// とりあえずロック
		g_AbilityUnlock[client] = true;
	}
	
	// 各プラグインの処理
	Event_FiredUser(INVALID_HANDLE, EVENT_PLUGIN_INIT);

//	InitPluginDataUser();
}

/////////////////////////////////////////////////////////////////////
//
// 後始末
//
/////////////////////////////////////////////////////////////////////
public FinalizePluginData()
{
	new maxclients = GetMaxClients();
	for (new client = 1; client <= maxclients; client++)
	{
		// プレイヤーデータリセット
		PlayerDataReset( client );
		
		// ロック
		//g_AbilityUnlock[client] = false;
	}
	
	Event_FiredUser(INVALID_HANDLE, EVENT_PLUGIN_FINAL);

	// 各プラグインの処理
//	InitPluginDataUser();
}

/////////////////////////////////////////////////////////////////////
//
// イベント発動
//
/////////////////////////////////////////////////////////////////////
public Action:Event_Fired(Handle:event, const String:name[], bool:dontBroadcast)
{
	// MODがONの時だけ
	if( !g_IsRunning )
		return Plugin_Continue;	
	
	
	if( StrEqual(name, EVENT_PLAYER_SPAWN)
		|| StrEqual(name, EVENT_PLAYER_CHANGE_CLASS)
		|| StrEqual(name, EVENT_PLAYER_DEATH)
		|| StrEqual(name, EVENT_PLAYER_DAMAGE)
		|| StrEqual(name, EVENT_PLAYER_CHANGE_TEAM)
		|| StrEqual(name, EVENT_PLAYER_CONNECT)
		|| StrEqual(name, EVENT_PLAYER_DISCONNECT)
		|| StrEqual(name, EVENT_PLAYER_BUILT_OBJECT)
		|| StrEqual(name, EVENT_PLAYER_REMOVE_OBJECT)
		|| StrEqual(name, EVENT_OBJECT_DESTROYED)
		|| StrEqual(name, EVENT_PLAYER_STUNNED))
	{
		new client;
		
		if( StrEqual(name, EVENT_PLAYER_STUNNED) )
		{
			client = GetClientOfUserId(GetEventInt(event, "victim"));
			if( client <= 0 && !StrEqual(name, EVENT_PLAYER_DISCONNECT) )
				return Plugin_Continue;	
		}
		else
		{
			client = GetClientOfUserId(GetEventInt(event, "userid"));
			if( client <= 0 && !StrEqual(name, EVENT_PLAYER_DISCONNECT) )
				return Plugin_Continue;	
		}

		// デッドリンガー用
		if(StrEqual(name, EVENT_PLAYER_DAMAGE))
		{
			if(TF2_IsReadyFeignDeath(client))
			{
				g_PlayerReadyFeignDeath[client] = true;
			}
		}
		
		new Action:result = Event_FiredUser(event, name, client);
 
		if(StrEqual(name, EVENT_PLAYER_SPAWN)
			|| StrEqual(name, EVENT_PLAYER_DEATH)
			|| StrEqual(name, EVENT_PLAYER_SPAWN)
			|| StrEqual(name, EVENT_PLAYER_CHANGE_TEAM))
		{
			if(!g_PlayerReadyFeignDeath[client])
			{
				// プレイヤーデータリセット
				PlayerDataReset( client );
			}
			else
			{
				g_PlayerReadyFeignDeath[client] = false;
			}
		}
		
		if(StrEqual(name, EVENT_PLAYER_SPAWN))
		{
			// ディレイ
			ClearTimer( g_SpawnDelayTimer[ client ] );
			g_SpawnDelayTimer[ client ] = CreateTimer(0.15, Timer_PlayerSpawnDelay, client);
		}
		
		
		if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
		{
			// プレイヤーデータリセット
			PlayerDataReset( client );
		}
		
		return result;
	}
	// ラウンド開始
	else if( StrEqual(name, EVENT_ROUND_START) )
	{
		new maxclients = GetMaxClients();
		for (new client = 1; client <= maxclients; client++)
		{
			// プレイヤーデータリセット
			PlayerDataReset( client );
		}
	}
	
	return Event_FiredUser(event, name);
}

/////////////////////////////////////////////////////////////////////
//
// マップ開始
//
/////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	// プラグインデータ初期化
	InitItemData();
	
	new Handle:cvar = FindConVar("sm_rmf_tf_ability_menu");
	if( cvar == INVALID_HANDLE )
	{
		new maxclients = GetMaxClients();
		for (new client = 1; client <= maxclients; client++)
		{
			// ロック解除
			g_AbilityUnlock[client] = true;
		}		
	}
	
	Event_FiredUser(INVALID_HANDLE, EVENT_MAP_START);

	// 各プラグインの処理
	//OnMapStartUser();
}
/////////////////////////////////////////////////////////////////////
//
// 全てのロード終了
//
/////////////////////////////////////////////////////////////////////
public OnConfigsExecuted()
{
	
	Event_FiredUser(INVALID_HANDLE, EVENT_CONFIG_EXECUTED);

	// 各プラグインの処理
	//OnConfigsExecutedUser();
}

/////////////////////////////////////////////////////////////////////
//
// マップ終了
//
/////////////////////////////////////////////////////////////////////
public OnMapEnd()
{
	// プラグインデータ初期化
//	InitPluginData();

	Event_FiredUser(INVALID_HANDLE, EVENT_MAP_END);

	// 各プラグインの処理
	//OnMapEndUser();
}

/////////////////////////////////////////////////////////////////////
//
// ゲームフレーム
//
/////////////////////////////////////////////////////////////////////
public OnGameFrame()
{
	// MODがONの時だけ
	if( !g_IsRunning )
		return;	

	Event_FiredUser(INVALID_HANDLE, EVENT_GAME_FRAME);
	// 各プラグインの処理
//	OnGameFrameUser();

}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーデータリセット
//
/////////////////////////////////////////////////////////////////////
public PlayerDataReset( any:client )
{
    if ( client > 0  )
	{
		// ゲームに入っている
		if( IsClientInGame(client) )
		{		
			// HintText初期化
			for(new i = 0; i < HintTextPages; i++)
			{
				Format(g_PlayerHintText[client][i], HintTextMaxSize , "");
			}
			g_PlayerHintPage[client] = 0;
			
			// タイマークリア
			ClearTimer(g_HintTextTimer[client]);
			ClearTimer(g_SpawnDelayTimer[client]);
			ClearTimer(g_ResupplyTimer[client]);
			
			// キー入力した時間を保存
			SaveKeyTime(client);
			
			// プレイヤーの言語設定？
			//SetGlobalTransTarget(GetServerLanguage());

			Event_FiredUser(INVALID_HANDLE, EVENT_PLAYER_DATA_RESET, client);
//			PlayerDataResetUser( client );
		}

	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤー復活ディレイ
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_PlayerSpawnDelay(Handle:timer, any:client)
{
	g_SpawnDelayTimer[ client ] = INVALID_HANDLE;
	
	// 各プラグインの処理
	Event_FiredUser(INVALID_HANDLE, EVENT_PLAYER_SPAWN_DELAY, client);
	
	new String:cmd[64];
	StringToLower(cmd, g_AbilityName);
	Format(cmd, sizeof(cmd), "sm_rmf_%s_class", cmd);
	new Handle:cvar = FindConVar(cmd);
	if( IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient( client ) && (g_AbilityUnlock[client] || !cvar))
	{
		g_PlayerHintPage[client] = 0;
		if(!StrEqual(g_PlayerHintText[client][g_PlayerHintPage[client]], ""))
		{
			PrintHintText(client, "%s", g_PlayerHintText[client][g_PlayerHintPage[client]]);
			g_PlayerHintPage[client] += 1;
			if(g_PlayerHintPage[client] < HintTextPages)
			{
				ClearTimer( g_HintTextTimer[ client ] );
				//PrintToChat(client, "%s", g_PlayerHintText[client][g_PlayerHintPage[client]]);
				g_HintTextTimer[client] = CreateTimer(HintTextInterval, Timer_ShowHintText, client);
			}
		}
	}
//	Timer_PlayerSpawnDelayUser(Handle:timer, any:client);

}


/////////////////////////////////////////////////////////////////////
//
// リサプライエリアにIN
//
/////////////////////////////////////////////////////////////////////
public Action:HookResupplySound( clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
    if( !StrEqual( sample, "items/regenerate.wav", true ) )
	{
		return Plugin_Continue;
	}
	
	// ロッカーじゃないなら抜ける
	new String:name[64];
	GetEdictClassname( entity, name, 64 );
	if( !StrEqual( name,  "player" ) )
	{
		return Plugin_Continue;
	}

	// イベント発生
	for( new i = 0; i < numClients + 1; i++ )
	{
		if( i == entity && i != 0 )
		{
			// ちょっと遅延
			ClearTimer( g_ResupplyTimer[ i ] );
			g_ResupplyTimer[ i ] = CreateTimer( 0.1, Timer_Resupply, i );
			
		}
	}
	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// リサプライイベント発生
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_Resupply(Handle:timer, any:client)
{
	g_ResupplyTimer[ client ] = INVALID_HANDLE;
	
	if( IsClientInGame( client ) && IsPlayerAlive( client) )
	{
		// 各プラグインの処理
		Event_FiredUser( INVALID_HANDLE, EVENT_PLAYER_RESUPPLY, client );
	}
}

/////////////////////////////////////////////////////////////////////
//
// 二つ目以降の説明タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_ShowHintText(Handle:timer, any:client)
{
	g_HintTextTimer[client] = INVALID_HANDLE;
	if(IsClientInGame(client) && IsPlayerAlive(client) && g_PlayerHintPage[client] < HintTextPages)
	{
		if(!StrEqual(g_PlayerHintText[client][g_PlayerHintPage[client]], ""))
		{
			PrintHintText(client, "%s", g_PlayerHintText[client][g_PlayerHintPage[client]]);
			g_PlayerHintPage[client] += 1;
			if(g_PlayerHintPage[client] < HintTextPages)
			{
				ClearTimer( g_HintTextTimer[ client ] );
				//PrintToChat(client, "%s", g_PlayerHintText[client][g_PlayerHintPage[client]]);
				g_HintTextTimer[client] = CreateTimer(HintTextInterval, Timer_ShowHintText, client);
				
			}
		}
	}
}


/////////////////////////////////////////////////////////////////////
//
// キー入力時間保存
//
/////////////////////////////////////////////////////////////////////
stock SaveKeyTime(any:client)
{
	if( IsClientInGame(client) )
	{		
		g_LastKeyCheckTime[client] = GetGameTime();
	}
}

/////////////////////////////////////////////////////////////////////
//
// キー入力可能かチェック
//
/////////////////////////////////////////////////////////////////////
stock bool:CheckElapsedTime(any:client, Float:time)
{
	if( IsClientInGame(client) )
	{	
		if( GetGameTime() - g_LastKeyCheckTime[client] >= time)
		{
			return true;
		}
	}
	return false;
}



/////////////////////////////////////////////////////////////////////
//
// MODのOn/Off変更
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_IsPluginOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) > 0)
	{
		g_IsRunning = true
	}
	else
	{
		g_IsRunning = false;
	}
	PluginStateChanged();
}


/////////////////////////////////////////////////////////////////////
//
// ブール値
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Bool(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0か1
	if (StringToInt(newValue) != 0 && StringToInt(newValue) != 1)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be 0 or 1");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 倍率
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Magnification(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.1～10.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 10.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 10.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 半径(メートル)
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Radius(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0～100.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 100.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 100.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 時間
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Time(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0～120.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 120.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 120.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 弾薬
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Ammo(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0～200まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 200)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 200");
	}
}

/////////////////////////////////////////////////////////////////////
//
// ユーバー
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Uber(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0～100まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 100");
	}
}
/////////////////////////////////////////////////////////////////////
//
// ダメージ
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Damage(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0～1000まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 1000)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 1000");
	}
}

/////////////////////////////////////////////////////////////////////
//
// ヘルス
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Health(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0～500まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 500)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 500");
	}
}