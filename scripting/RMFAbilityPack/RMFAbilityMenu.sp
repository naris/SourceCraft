/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.1.0
// ・1.3.1でコンパイル
// ・sm_rmf_ability_menu_admin_onlyを追加
// 2009/09/20 - 0.0.8
// ・メニュー表示コマンドの問題を修正
// 2009/09/20 - 0.0.7
// ・ショートコマンド搭載。"!r"でもメニューが表示可能になった。
// 2009/09/05 - 0.0.6
// ・観戦・またはチームを選んでいない場合はメニューを表示しないようにした。
// 2009/08/24 - 0.0.5
// ・リスポンルーム内ならすぐに装備変更できるようにした。
// ・アリーナモード・サドンデスモードの場合はラウンド開始から数秒が経過すると変更不可
// ・1.2.3でコンパイル
// 2009/08/14 - 0.0.2
// ・クラスレスアップデートに対応(1.2.2でコンパイル)
// ・sm_rmf_allow_ability_menuを0にしてもメニューが表示されていたのを修正


/////////////////////////////////////////////////////////////////////
//
// インクルード
//
/////////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include "rmf/tf2_codes"
#include "rmf/tf2_events"

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "RMF Ability Menu"
#define PL_DESC "RMF Ability Menu"
#define PL_VERSION "0.1.0"

#define MAX_PLUGINS 64
#define MAX_PLUGIN_NAME 64

/////////////////////////////////////////////////////////////////////
//
// MOD情報
//
/////////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = PL_NAME,
	author = "RIKUSYO",
	description = PL_DESC,
	version = PL_VERSION,
	url = "http://ameblo.jp/rikusyo/"
}

/////////////////////////////////////////////////////////////////////
//
// グローバル変数
//
/////////////////////////////////////////////////////////////////////
new Handle:g_ConVarAdminOnly = INVALID_HANDLE;				// ConVarAdminOnly

new String:g_RMFPlugins[MAX_PLUGINS][MAX_PLUGIN_NAME];	// プラグイン名
new g_PluginNum = 0;									// プラグイン数

new Handle:g_MenuTimer = INVALID_HANDLE;				// メニュー終了タイマー
new bool:g_AbilityLock = false;							// アリーナ開始済み？
new bool:g_SelectedAbility[MAXPLAYERS+1] = false;		// アビリティー選択済み？
new String:g_NextAbilityName[MAXPLAYERS+1][128];
new String:g_NowAbilityName[MAXPLAYERS+1][128];

new bool:g_InRespawnRoom[MAXPLAYERS+1] = false;			// リスポンルームにいる？


/////////////////////////////////////////////////////////////////////
//
// イベント発動
//
/////////////////////////////////////////////////////////////////////
stock Action:Event_FiredUser(Handle:event, const String:name[], any:client=0)
{

	// プラグイン開始
	if(StrEqual(name, EVENT_PLUGIN_START))
	{
		// 言語ファイル読込
		LoadTranslations("rmf_abilitymenu.phrases");

		// コマンド作成
		CreateConVar("sm_rmf_tf_ability_menu", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_ability_menu","1","Ability menu Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		RegConsoleCmd("say", Command_Say);
		RegConsoleCmd("say_team", Command_Say);
		
		// リスポンルームの退出などをフック
		HookEntityOutput("func_respawnroom",  "OnStartTouch",    EntityOutput_StartTouch);
		HookEntityOutput("func_respawnroom", "OnEndTouch",    EntityOutput_EndTouch);
		
		g_ConVarAdminOnly = CreateConVar("sm_rmf_ability_menu_admin_only",	"0",	"Admin Only Enable/Disable (0 = disabled | 1 = enabled)");
		HookConVarChange(g_ConVarAdminOnly,		ConVarChange_Bool);	
		
		// RMFプラグインリスト取得
		new String:file[256];
		BuildPath(Path_SM, file, 255, "configs/RMFPlugins.txt");
		
		// ファイルから取得
		new Handle:fileh = OpenFile(file, "r");
		if(fileh != INVALID_HANDLE)
		{
			new String:buffer[256];
			new String:smxName[128];
			while (ReadFileLine(fileh, buffer, sizeof(buffer)))
			{
				// 改行コードを修正
				//new len = strlen(buffer)
				//if(buffer[len-1] == '\n')
				//{
				//	PrintToServer("%s", buffer);
		   		//	buffer[len-1] = '\0';
				//}
				
				// トリム
				TrimString(buffer);
				
				// SMXファイルがあるかチェック
				Format(smxName, sizeof(smxName), "addons/sourcemod/plugins/%s.smx", buffer)
				//PrintToServer("%s %d", smxName, FileExists(smxName));
				if(FileExists(smxName))
				{
					new String:phrasesPath[256];
					new String:phrasesName[256];
					// 存在したらプラグイン名を(例：AfterBurner)リストに保存
					strcopy(g_RMFPlugins[g_PluginNum], MAX_PLUGIN_NAME, buffer);
					
					// 言語ファイル名設定
					StringToLower(phrasesName, buffer);	// 大文字を小文字に
					Format(phrasesName, sizeof(phrasesName), "%s.phrases", phrasesName)
					Format(phrasesPath, sizeof(phrasesPath), "addons/sourcemod/translations/%s.txt", phrasesName)
					//PrintToServer("%s", phrasesPath);
					
					// ファイルが存在したら言語ファイル読み込み
					if(FileExists(phrasesPath))
					{
						LoadTranslations(phrasesName);
					}
					
					// プラグイン数を保存
					g_PluginNum += 1;
				}
				
				if(IsEndOfFile(fileh))
					break;
			}		
		}
		else
		{
			// 読めませんでした
			LogMessage("configs/RMFPlugins.txt was not able to be read.");
		}
			
		g_AbilityLock = false;
	}

	// プラグイン状態変更
	if(StrEqual(name, EVENT_PLUGIN_STATE_CHANGED))
	{
		// 全員解除設定
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			if( IsClientInGame(i) )
			{
				// アビリティ全部使用不可に。
				for(new j = 0; j < g_PluginNum; j++)
				{
					ServerCommand("rmf_ability %d %s 0", i, g_RMFPlugins[j]);
				}		
				g_SelectedAbility[i] = false;
				g_NextAbilityName[i] = "";
				g_NowAbilityName[i] = "";
			}
		}
		
	}

	
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			g_SelectedAbility[client] = false;
			g_NextAbilityName[client] = "";
			g_NowAbilityName[client] = "";
		}
		
		
	}
	// マップエンド
	if(StrEqual(name, EVENT_MAP_END))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			g_SelectedAbility[client] = false;
			g_NextAbilityName[client] = "";
			g_NowAbilityName[client] = "";
		}
		// タイマークリア
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		// ラウンド終了
		g_AbilityLock = false;		
	}	
	// アリーナラウンドアクティブ
	if(StrEqual(name, EVENT_ARENA_ROUND_ACTIVE))
	{

		// タイマークリア
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		g_MenuTimer = CreateTimer(5.0, Timer_MenuEnd, 0);
		// ラウンド開始
		g_AbilityLock = true;
	
	}
	// サドンデス開始
	if(StrEqual(name, EVENT_SUDDEN_DEATH_START))
	{

		// タイマークリア
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		g_MenuTimer = CreateTimer(10.0, Timer_MenuEnd, 0);
		// ラウンド開始
		g_AbilityLock = true;
	}
	
	// アリーナWinパネル
	if(StrEqual(name, EVENT_ARENA_WIN_PANEL))
	{
		// タイマークリア
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		// ラウンド終了
		g_AbilityLock = false;
	
	}
	// Winパネル
	if(StrEqual(name, EVENT_WIN_PANEL))
	{
		// タイマークリア
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		// ラウンド終了
		g_AbilityLock = false;
	
	}
	
	// プレイヤークラス変更
	if(StrEqual(name, EVENT_PLAYER_CHANGE_CLASS))
	{
		
		if( IsClientInGame(client) && !IsPlayerAlive(client))
		{
			// 取り合えずアビリティ全部使用不可に。
			for(new i = 0; i < g_PluginNum; i++)
			{
				ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
			}		
			g_SelectedAbility[client] = false;
			g_NextAbilityName[client] = "";
			g_NowAbilityName[client] = "";
		}

	}
	// プレイヤー復活
	if(StrEqual(name, EVENT_PLAYER_SPAWN))
	{
	
		// タイマークリア
//		if(g_MenuTimer[client] != INVALID_HANDLE)
//		{
//			KillTimer(g_MenuTimer[client]);
//			g_MenuTimer[client] = INVALID_HANDLE;
//		}
//		g_MenuTimer[client] = CreateTimer(10.0, Timer_MenuEnd, client);

		if(!StrEqual(g_NowAbilityName[client], "") || !StrEqual(g_NextAbilityName[client], ""))
		{
			new bool:otherClass = false;
			new String:lowerName[64];
			new String:buffer[128];
			new Handle:cvar;

			// 次のアビリティ
			StringToLower(lowerName, g_NextAbilityName[client]);	// 大文字を小文字に
			// クラスCVAR取得
			Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
			cvar = FindConVar(buffer);
			if(cvar != INVALID_HANDLE && TFClassType:GetConVarInt(cvar) != TF2_GetPlayerClass( client ))
			{
				otherClass = true;
			}
			
			lowerName = "";
			buffer = "";
			
			// 今のアビリティ
			StringToLower(lowerName, g_NowAbilityName[client]);	// 大文字を小文字に
			// クラスCVAR取得
			Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
			
			cvar = FindConVar(buffer);
			if(cvar != INVALID_HANDLE && TFClassType:GetConVarInt(cvar) != TF2_GetPlayerClass( client ))
			{
				otherClass = true;
			}
			
			if(otherClass)
			{
				// アビリティ全部使用不可に。
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
				}	
				
				g_SelectedAbility[client] = false;
				g_NextAbilityName[client] = "";
				g_NowAbilityName[client] = "";
				
			}
			
		}

		
		
		// アビリティ変更
		if(!StrEqual(g_NextAbilityName[client], ""))
		{
			if(!StrEqual(g_NextAbilityName[client], "Unequipped"))
			{

				g_NowAbilityName[client] = g_NextAbilityName[client];
				
				// 大文字取得
				new String:upperName[32];
				StringToUpper(upperName, g_NextAbilityName[client]);	// 小文字を大文字に
				
				// 取り合えずアビリティ全部使用不可に。
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
				}		

				// 選択したアビリティを有効
				ServerCommand("rmf_ability %d %s 1", client, g_NextAbilityName[client]);

				// プラグイン名取得
				new String:pluginName[64];
				Format(pluginName, sizeof(pluginName), "ABILITYNAME_%s", upperName);
				Format(pluginName, sizeof(pluginName), "%T", pluginName, client);
				PrintToChat(client, "\x04%T", "ABILITYMENU_EQUIPPED", client, pluginName);
				
				g_SelectedAbility[client] = true;
				g_NextAbilityName[client] = "";
			
			}
			else
			{
				// アビリティ全部使用不可に。
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
				}	
				
				if(g_SelectedAbility[client])
				{
					PrintToChat(client, "\x04%T", "ABILITYMENU_UNEQUIPPED", client);
				}
				g_SelectedAbility[client] = false;
				g_NextAbilityName[client] = "";
				g_NowAbilityName[client] = "";
			}
		}
				
	}

	// プレイヤーリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		if(g_IsRunning)
		{
			if(!g_SelectedAbility[client] && g_PluginNum > 0)
			{
				Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_MENU", client);
			}
		}

		
	}
	// プレイヤー復活ディレイ
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{

	}
	
	// プレイヤー切断
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		// 取り合えずアビリティ全部使用不可に。
		for(new i = 0; i < g_PluginNum; i++)
		{
			ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
		}		
		g_SelectedAbility[client] = false;
		g_NextAbilityName[client] = "";
		g_NowAbilityName[client] = "";

	}	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// メニュー終了タイマーー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_MenuEnd(Handle:timer, any:client)
{
	g_MenuTimer = INVALID_HANDLE;

}

/////////////////////////////////////////////////////////////////////
//
// メニュー表示コマンド
//
/////////////////////////////////////////////////////////////////////
public Action:Command_Say(client, args)
{
	if(g_IsRunning)
	{
		// Adminオンリー？
		if( GetConVarBool( g_ConVarAdminOnly ) == true )
		{
			if( GetUserAdmin( client ) == INVALID_ADMIN_ID )
			{
				PrintToChat( client, "\x04%T", "MESSAGE_ADMIN_ONLY", client );
				return Plugin_Handled;
			}
		}
		
		decl String:originalstring[191];
		GetCmdArgString(originalstring, sizeof(originalstring));
		ReplaceString( originalstring, sizeof(originalstring), "\"", "" );
		//PrintToChat(client, "%d", strlen(originalstring));
		//PrintToChat(client, "%s", originalstring);
		if( ( StrContains(originalstring, "rmf_menu") != -1 && strlen(originalstring) == 8 )
		|| ( StrContains(originalstring, "!r") != -1 && strlen(originalstring) == 2 ) )
		{

			//PrintToChat(client, "%d", GetEntProp(g_RoundTimer, Prop_Send, "m_nState"));
				//GetEntProp(g_RoundTimer, Prop_Send, "m_iRoundState"));
		
			//PrintToChat(client, "%d", g_InRespawnRoom[client]);
		
			
			if( client > 0 && ( GetClientTeam(client) == _:TFTeam_Red || GetClientTeam(client) == _:TFTeam_Blue ) )
			{
				// メニューを開く
				AbilityMenu(client);
				
			}

		
				
			/*
			if(g_MenuTimer[client] != INVALID_HANDLE)
			{
			}
			else
			{
				if(g_SelectedAbility[client])
				{
					PrintToChat(client, "\x03%T", "ABILITYMENU_CANTCHANGE", client);
				}
				else
				{
					PrintToChat(client, "\x03%T", "ABILITYMENU_TIMEOVER", client);
				}
			}		*/
			return Plugin_Handled;
		}

	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// メニュー選択
//
/////////////////////////////////////////////////////////////////////
public AbilityMenu(client)
{
	new Handle:menu = CreateMenu(AbilityMenuHandler);
	
	// メニュータイトル
	new String:title[64];
	Format(title, sizeof(title), "%T", "ABILITYMENU_TITLE", client);
	SetMenuTitle(menu, title);
	
	new allowCount = 0;
	for(new i = 0; i < g_PluginNum; i++)
	{
		// 文字が入っている
		if(!StrEqual(g_RMFPlugins[i], ""))
		{
			
			// 大文字小文字用意
			new String:lowerName[64];
			new String:upperName[64];
			new String:buffer[128];
			new Handle:cvar;
			
			StringToLower(lowerName, g_RMFPlugins[i]);	// 大文字を小文字に
			StringToUpper(upperName, g_RMFPlugins[i]);	// 小文字を大文字に
			
			// ON/OFFのCVAR取得
			Format(buffer, sizeof(buffer), "sm_rmf_allow_%s", lowerName);
			cvar = FindConVar(buffer);
			// プラグインがONかオフかチェック
			if(cvar != INVALID_HANDLE && GetConVarInt(cvar))
			{
				// クラスCVAR取得
				Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
				cvar = FindConVar(buffer);
				//PrintToServer("%d, %d", GetConVarInt(cvar), TF2_GetPlayerClass( client ));
				// クラスが同じかチェック
				if(cvar != INVALID_HANDLE && TFClassType:GetConVarInt(cvar) == TF2_GetPlayerClass( client ))
				{
					// トランスレーション取得
					new String:pluginName[128];
					Format(pluginName, sizeof(pluginName), "ABILITYNAME_%s", upperName);
					Format(pluginName, sizeof(pluginName), "%T", pluginName, client);
					
					// メニューに追加
					AddMenuItem(menu, g_RMFPlugins[i], pluginName);
					
					// カウントアップ
					allowCount += 1;
				}
				
			}
		}
		
	}
	// 使用しないメニュー
	new String:notuse[128];
	if(g_SelectedAbility[client])
	{
		Format(notuse, sizeof(notuse), "%T", "ABILITYMENU_CANCEL", client);
		AddMenuItem(menu, "NOTUSE", notuse);
	}
	//else
	//{
	//	Format(notuse, sizeof(notuse), "%T", "ABILITYMENU_NOTUSE", client);
	//}
	SetMenuExitButton(menu, true);
	
	if(allowCount > 0)
	{
		DisplayMenu(menu, client, 10);
	}	
}

/////////////////////////////////////////////////////////////////////
//
// メニュー選択
//
/////////////////////////////////////////////////////////////////////
public AbilityMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
	// アイテム選択した
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		// アビリティ使う
		if(!StrEqual(info, "NOTUSE"))
		{
			// まだ選んでない
			if(!g_SelectedAbility[param1] && g_InRespawnRoom[param1]/* && g_MenuTimer[param1] != INVALID_HANDLE*/)
			{
				// 大文字取得
				new String:upperName[32];
				StringToUpper(upperName, info);	// 小文字を大文字に
				new String:lowerName[64];
				StringToLower(lowerName, info);	// 大文字を小文字に
					
				// 取り合えずアビリティ全部使用不可に。
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", param1, g_RMFPlugins[i]);
				}		

				// クラスCVAR取得
				new String:buffer[128];
				Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
				new Handle:cvar = FindConVar(buffer);
				// クラスが同じかチェック
				if(TFClassType:GetConVarInt(cvar) == TF2_GetPlayerClass( param1 ))
				
				{				// 選択したアビリティを有効
					ServerCommand("rmf_ability %d %s 1", param1, info);

					// プラグイン名取得
					new String:pluginName[64];
					Format(pluginName, sizeof(pluginName), "ABILITYNAME_%s", upperName);
					Format(pluginName, sizeof(pluginName), "%T", pluginName, param1);
					PrintToChat(param1, "\x04%T", "ABILITYMENU_EQUIPPED", param1, pluginName);
					
					g_SelectedAbility[param1] = true;
					g_NowAbilityName[param1] = info;
				}
			}
			// 選んでる
			else
			{
				g_NextAbilityName[param1] = info;
				
				// 前と違うやつなら保存
				if(!StrEqual(g_NextAbilityName[param1], g_NowAbilityName[param1]))
				{
					// メッセージ
					//PrintToChat(param1, "henkou");
					// アリーナおよびサドンデスの場合は制限時間内
					if(!g_AbilityLock || g_MenuTimer != INVALID_HANDLE)
					{
						// リスポンルーム内ならすぐ切り替え
						if(g_InRespawnRoom[param1])
						{
							TF2_RespawnPlayer(param1);
						}
						else
						{
							PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE", param1);
						}
					}
					else
					{
						// 今は変更できないメッセージ
						PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE_NOW", param1);
					}
					
				}

			}
		}
		else
		{
			g_NextAbilityName[param1] = "Unequipped";
			// アリーナおよびサドンデスの場合は制限時間内
			if(!g_AbilityLock || g_MenuTimer != INVALID_HANDLE)
			{
				// リスポンルーム内ならすぐ切り替え
				if(g_InRespawnRoom[param1])
				{
					TF2_RespawnPlayer(param1);
				}
				else
				{
					PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE", param1);
				}
			}
			else
			{
				// 今は変更できないメッセージ
				PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE_NOW", param1);
			}			
	
			// アビリティ全部使用不可に。
			/*
			for(new i = 0; i < g_PluginNum; i++)
			{
				ServerCommand("rmf_ability %d %s 0", param1, g_RMFPlugins[i]);
			}	
			
			if(g_SelectedAbility[param1])
			{
				PrintToChat(param1, "%T", "ABILITYMENU_CANCELED", param1);
			}
			g_SelectedAbility[param1] = false;
			g_NextAbilityName[param1] = "";
			g_NowAbilityName[param1] = "";*/
		}
	}
	// キャンセル
	else if (action == MenuAction_Cancel)
	{
		// アビリティ使用不可に
	}
	// メニュー閉じた
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
			
		

}

/////////////////////////////////////////////////////////////////////
//
// リスポンルーム出る入る
//
/////////////////////////////////////////////////////////////////////
public EntityOutput_StartTouch( const String:output[], caller, activator, Float:delay )
{
//	PrintToChat(activator, "Touch");
	if(TF2_EdictNameEqual(activator, "player"))
	{
		g_InRespawnRoom[activator] = true;
	}
}
public EntityOutput_EndTouch( const String:output[], caller, activator, Float:delay )
{
//	PrintToChat(activator, "NoTouch");
	if(TF2_EdictNameEqual(activator, "player"))
	{
		g_InRespawnRoom[activator] = false;
	}

}

