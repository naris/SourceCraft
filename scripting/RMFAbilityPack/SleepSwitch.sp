/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.5
// ・1.3.1でコンパイル
// 2009/10/06 - 0.0.4
// ・内部処理を変更
// 2009/08/29 - 0.0.3
// ・単体動作に対応。
// ・1.2.3でコンパイル
// 2009/08/14 - 0.0.1
// ・クラスレスアップデートに対応(1.2.2でコンパイル)

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
#define PL_NAME "Sleep Switch"
#define PL_DESC "Sleep Switch"
#define PL_VERSION "0.0.5"
#define PL_TRANSLATION "sleepswitch.phrases"

#define EFFECT_WAKEUP "sapper_debris"

#define MDL_SLEEP_ICON "models/extras/info_speech.mdl"

#define SOUND_STATE_CHANGE "items/cart_explode_trigger.wav"
#define SOUND_ERROR "items/cart_explode_falling.wav"
#define SOUND_SLEEP_ON "weapons/sentry_move_short2.wav"
#define SOUND_SLEEP_OFF "weapons/sentry_finish.wav"
#define SOUND_WAKEUP "weapons/pistol_shoot.wav"
#define SOUND_GOODNIGHT "vo/engineer_jeers04.wav"

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
new Handle:g_EffectiveDist = INVALID_HANDLE;				// ConVar有効距離
new Handle:g_AddHealth = INVALID_HANDLE;					// ConVar回復量


new bool:g_IsSentrySleep[MAXPLAYERS+1] = false;				// セントリースリープ中？
new g_PlayerSentry[MAXPLAYERS+1] = -1;						// 建設したセントリー
new g_SleepIcon[MAXPLAYERS+1] = -1;							// スリープアイコン

new Handle:g_CheckTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// セントリーチェックタイマー
new Handle:g_BreathTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// 寝息タイマー

new String:SOUND_WAKEUP_VOICE[9][64];						// ウェイクアップボイス
new String:SOUND_BREATH[2][64];								// 寝息
new g_BreathNum = 0;										//寝息カウント

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
		LoadTranslations(PL_TRANSLATION);

		// コマンド作成
		CreateConVar("sm_rmf_tf_sleepswitch", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_sleepswitch","1","Sleep Switch Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		
		g_EffectiveDist = CreateConVar("sm_rmf_sleepswitch_dist","20.0","Effective dist[meter] (0.0-100.0)");
		g_AddHealth = CreateConVar("sm_rmf_sleepswitch_heal_amount","20","Heal amount (0-500)");
		HookConVarChange(g_EffectiveDist,	ConVarChange_Radius);
		HookConVarChange(g_AddHealth,		ConVarChange_Health);

		// アビリティクラス設定
		CreateConVar("sm_rmf_sleepswitch_class", "9", "Ability class");
		
		// ボイス
		SOUND_WAKEUP_VOICE[0] = "vo/engineer_cheers01.wav";
		SOUND_WAKEUP_VOICE[1] = "vo/engineer_cheers02.wav";
		SOUND_WAKEUP_VOICE[2] = "vo/engineer_moveup01.wav";
		SOUND_WAKEUP_VOICE[3] = "vo/engineer_battlecry07.wav";
		SOUND_WAKEUP_VOICE[4] = "vo/engineer_battlecry06.wav";
		SOUND_WAKEUP_VOICE[5] = "vo/engineer_battlecry03.wav";
		SOUND_WAKEUP_VOICE[6] = "vo/engineer_cheers07.wav";
		SOUND_WAKEUP_VOICE[7] = "vo/engineer_yes03.wav";
		SOUND_WAKEUP_VOICE[8] = "vo/engineer_autobuildingsentry01.wav";

		SOUND_BREATH[0] = "weapons/sentry_upgrading_steam1.wav";
		SOUND_BREATH[1] = "weapons/sentry_upgrading_steam4.wav";
	}

	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// スリープスイッチ強制停止
			ForceStopSleepMode(i)
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// スリープスイッチ強制停止
			ForceStopSleepMode(i)
		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// スリープスイッチ強制停止
			ForceStopSleepMode(i)
		}
		
		PrecacheSound(SOUND_STATE_CHANGE);
		PrecacheSound(SOUND_ERROR);
		PrecacheSound(SOUND_SLEEP_ON);
		PrecacheSound(SOUND_SLEEP_OFF);
		PrecacheSound(SOUND_WAKEUP);
		PrecacheSound(SOUND_GOODNIGHT);
		
		for( new i = 0; i < 7; i++)
		{
			PrecacheSound(SOUND_WAKEUP_VOICE[i], true);
		}

		for( new i = 0; i < 2; i++)
		{
			PrecacheSound(SOUND_BREATH[i], true);
		}
	
		
		PrecacheModel(MDL_SLEEP_ICON, true);

	}
	// ゲームフレーム
	if(StrEqual(name, EVENT_GAME_FRAME))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			FrameAction(i);
		}
	}

	// プレイヤーリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// アビリティOFFなら目を覚ます
		if(!g_AbilityUnlock[client] && g_IsSentrySleep[client])
		{
			// スリープスイッチ強制停止
			ForceStopSleepMode(client)
			
			// OFF
			g_IsSentrySleep[client] = false;
		}
		
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_SLEEPSWITCH", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_SLEEPSWITCH_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_SLEEPSWITCH_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_SLEEPSWITCH_ATTRIBUTE_2", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}
	}
	
	// オブジェクト建設
	if(StrEqual(name, EVENT_PLAYER_BUILT_OBJECT))
	{
		new objType = GetEventInt(event, "object");
		
		if( objType == 3 )
		{
			ForceStopSleepMode(client);
		}		
	}

	// オブジェクト破壊
	if(StrEqual(name, EVENT_OBJECT_DESTROYED))
	{
		new objType = GetEventInt(event, "objecttype");
		
		if( objType == 3 )
		{
			ForceStopSleepMode(client);
		}		
	}

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動チェック
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// エンジニアのみ
		if(TF2_GetPlayerClass(client) == TFClass_Engineer && g_AbilityUnlock[client])
		{
			// レンチのみ
			if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_WRENCH )
			{
				// キーチェック
				if( CheckElapsedTime(client, 2.0) )
				{
					if ( GetClientButtons(client) & IN_ATTACK2 )
					{
						// キーを押した時間を保存
						SaveKeyTime(client);
						
						if(!TF2_CurrentWeaponEqual(client, "CTFWeaponBuilder"))
						{
							SleepSwitch(client);
						}
					}

				}			
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// スリープセントリーチェック
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_SentryCheck(Handle:timer, any:client)
{
	// 発動中ならチェック
	if(g_IsSentrySleep[client])
	{
		// 正しいオブジェクトかチェック
		if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun"))
		{
			// 高さ調整用
			new Float:pos[3];
			pos[1] = 15.0;
			new Float:ang[3];

			// セントリーガンのレベルチェック
			new sentryLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
			// レベルに合わせてアイコンの高さ調整
			if( sentryLevel == 1 )
			{
				pos[2] = 60.0;
			}
			else if( sentryLevel == 2 )
			{
				pos[2] = 80.0;
			}
			else if( sentryLevel == 3 )
			{
				pos[2] = 90.0;
			}
			
			// アイコンが正しければ移動
			if(g_SleepIcon[client] != -1 && IsValidEdict(g_SleepIcon[client]) && TF2_EdictNameEqual(g_SleepIcon[client], "prop_dynamic"))
			{
				TeleportEntity(g_SleepIcon[client], pos, ang, NULL_VECTOR);
			}
			
			// セントリー停止
			SetEntProp(g_PlayerSentry[client], Prop_Send, "m_bDisabled", 1);
		}
	}
	else
	{
		// スリープスイッチ強制停止
		ForceStopSleepMode(client)
	}
}
/////////////////////////////////////////////////////////////////////
//
// 寝息タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_BreathTimer(Handle:timer, any:client)
{
	// 発動中ならチェック
	if(g_IsSentrySleep[client])
	{
		// 正しいオブジェクトかチェック
		if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun") && GetEntProp(g_PlayerSentry[client], Prop_Send, "m_bHasSapper") != 1)
		{
			// 寝息
			EmitSoundToAll(SOUND_BREATH[g_BreathNum], g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 0.2, 75);
			
			new nowHealth = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iHealth");
			new nowLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
			new addHealth = GetConVarInt(g_AddHealth);		// 回復量
		
			// ヘルス増加
			nowHealth += addHealth;
			
			if( nowLevel == 1 )
			{
				if(nowHealth > 150)
				{
					addHealth = nowHealth - 150;
				}
			}
			else if( nowLevel == 2 )
			{
				if(nowHealth > 180)
				{
					addHealth = nowHealth - 180;
				}
			}
			else if( nowLevel == 3 )
			{
				if(nowHealth > 216)
				{
					addHealth = nowHealth - 216;
				}
			}			
			
			// ヘルス適用
			//SetEntProp(g_PlayerSentry[client], Prop_Send, "m_iHealth", nowHealth);
			SetVariantInt(addHealth);
			AcceptEntityInput(g_PlayerSentry[client], "AddHealth");
			
			if(g_BreathNum == 0)
			{
				g_BreathNum = 1;
			}
			else
			{
				g_BreathNum = 0;
			}
		}
	}

}


/////////////////////////////////////////////////////////////////////
//
// スリープスイッチ発動
//
/////////////////////////////////////////////////////////////////////
stock SleepSwitch(client)
{
	// 発動中なら解除、解除されてるなら発動
	if(!g_IsSentrySleep[client])
	{
		// 開始
		StartSleepMode(client);
	}
	else
	{
		// 停止
		StopSleepMode(client);
	}

}
/////////////////////////////////////////////////////////////////////
//
// スリープモード開始
//
/////////////////////////////////////////////////////////////////////
stock StartSleepMode(client)
{
	// セントリーガンを捜索
	new obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_sentrygun")) != -1)
	{
		new iOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if(iOwner == client)
		{
			new Float:sentryPos[3];
			GetEntPropVector(obj, Prop_Data, "m_vecAbsOrigin", sentryPos);
			new Float:playerPos[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", playerPos);
			
			if(GetEntProp(obj, Prop_Send, "m_iState") == 1 && GetVectorDistanceMeter(sentryPos, playerPos) <= GetConVarFloat(g_EffectiveDist) )
			{
				// セントリーを保存
				g_PlayerSentry[client] = obj;
				
				// チェックタイマー発動
				ClearTimer(g_CheckTimer[client]);
				g_CheckTimer[client] = CreateTimer(0.5, Timer_SentryCheck, client, TIMER_REPEAT);
				
				// 寝息タイマー発動
				ClearTimer(g_BreathTimer[client]);
				g_BreathTimer[client] = CreateTimer(2.5, Timer_BreathTimer, client, TIMER_REPEAT);

				// 寝息カウント
				g_BreathNum = 0;
				
				// スリープアイコン作成
				CreateSleepIcon(client);
				
				// 切り替えサウンド
				EmitSoundToClient(client, SOUND_STATE_CHANGE, client, _, _, SND_CHANGEPITCH, 0.3, 80);
				
				// おねむ開始
				EmitSoundToAll(SOUND_SLEEP_ON, g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 50);
				EmitSoundToAll(SOUND_GOODNIGHT, g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 140);

				// スリープON
				g_IsSentrySleep[client] = true;
				
				return;
			}
			else
			{
				// 離れすぎ
				if( GetVectorDistanceMeter(sentryPos, playerPos) > GetConVarFloat(g_EffectiveDist) )
				{
					// エラーメッセージ
					PrintToChat(client, "\x05%T", "MESSAGE_LONG_DISTANCE", client);
				}
			}
		}
	}
	
	// エラー音
	EmitSoundToClient(client, SOUND_ERROR, client, _, _, SND_CHANGEPITCH, 0.3, 200);
	
}

/////////////////////////////////////////////////////////////////////
//
// スリープモード停止
//
/////////////////////////////////////////////////////////////////////
stock StopSleepMode(client)
{

	// 正しいオブジェクトかチェック
	if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun"))
	{
		new Float:sentryPos[3];
		GetEntPropVector(g_PlayerSentry[client], Prop_Data, "m_vecAbsOrigin", sentryPos);
		new Float:playerPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", playerPos);
		
		// サッパーつけられていない状態
		if(GetEntProp(g_PlayerSentry[client], Prop_Send, "m_bHasSapper") != 1 && GetVectorDistanceMeter(sentryPos, playerPos) <= GetConVarFloat(g_EffectiveDist) )
		{
			// チェックタイマー停止
			ClearTimer(g_CheckTimer[client]);
			// 寝息タイマー停止
			ClearTimer(g_BreathTimer[client]);

			// セントリー停止解除
			SetEntProp(g_PlayerSentry[client], Prop_Send, "m_bDisabled", 0);
			
			// アイコン削除
			RemoveSleepIcon(client);

			// お目覚め
			EmitSoundToAll(SOUND_SLEEP_OFF, g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 150);
			EmitSoundToAll(SOUND_WAKEUP_VOICE[GetRandomInt(0, 8)], g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 140);
			
			// 切り替えサウンド
			EmitSoundToClient(client, SOUND_STATE_CHANGE, client, _, _, SND_CHANGEPITCH, 0.3, 80);

			// セントリークリア
			g_PlayerSentry[client] = -1;
			
			// スリープOFF
			g_IsSentrySleep[client] = false;	
			
			return;
		}
		else
		{
			// 離れすぎ
			if( GetVectorDistanceMeter(sentryPos, playerPos) > GetConVarFloat(g_EffectiveDist) )
			{
				// エラーメッセージ
				PrintToChat(client, "\x05%T", "MESSAGE_LONG_DISTANCE", client);
			}
		}
		
	}

	if(TF2_GetPlayerClass(client) == TFClass_Engineer && g_AbilityUnlock[client])
	{
		// エラー音
		EmitSoundToClient(client, SOUND_ERROR, client, _, _, SND_CHANGEPITCH, 0.3, 200);
	}
	else
	{
		// チェックタイマー停止
		ClearTimer(g_CheckTimer[client]);
		// 寝息タイマー停止
		ClearTimer(g_BreathTimer[client]);
	}
						
}


/////////////////////////////////////////////////////////////////////
//
// スリープモード強制停止
//
/////////////////////////////////////////////////////////////////////
stock ForceStopSleepMode(client)
{
	// チェックタイマー停止
	ClearTimer(g_CheckTimer[client]);
	// 寝息タイマー停止
	ClearTimer(g_BreathTimer[client]);

	// スリープアイコンを消す
	if(g_SleepIcon[client] != -1 && IsValidEdict(g_SleepIcon[client]) && TF2_EdictNameEqual(g_SleepIcon[client], "prop_dynamic"))
	{
		// アイコン削除
		AcceptEntityInput(g_SleepIcon[client], "Kill");
		g_SleepIcon[client] = -1;
	}	
	
	
	// 正しいオブジェクトかチェック
	if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun"))
	{

		// サッパーつけられていない状態
		if(GetEntProp(g_PlayerSentry[client], Prop_Send, "m_bHasSapper") != 1)
		{
			// セントリー停止解除
			SetEntProp(g_PlayerSentry[client], Prop_Send, "m_bDisabled", 0);
			
		}
	
	}

	// セントリークリア
	g_PlayerSentry[client] = -1;
	
	// スリープOFF
	g_IsSentrySleep[client] = false;	
}


/////////////////////////////////////////////////////////////////////
//
// スリープアイコン作成
//
/////////////////////////////////////////////////////////////////////
stock CreateSleepIcon(any:client)
{
	// スリープアイコン作成
	g_SleepIcon[client] = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(g_SleepIcon[client]))
	{
		new String:tName[32];
		GetEntPropString(g_PlayerSentry[client], Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(g_SleepIcon[client], "targetname", "sleep_icon");
		DispatchKeyValue(g_SleepIcon[client], "parentname", tName);
		SetEntityModel(g_SleepIcon[client], MDL_SLEEP_ICON);
		DispatchSpawn(g_SleepIcon[client]);
		SetVariantString("!activator");
		AcceptEntityInput(g_SleepIcon[client], "SetParent", g_PlayerSentry[client], g_PlayerSentry[client], 0);
		//SetVariantString("build_point_0");
		//AcceptEntityInput(g_SleepIcon[client], "SetParentAttachment", g_SleepIcon[client], g_SleepIcon[client], 0);
		ActivateEntity(g_SleepIcon[client]);

		// セントリーの位置取得
		new Float:pos[3];
		pos[1] = 15.0;
		new Float:ang[3];

		// セントリーのレベルに合わせて高さ調整
		new sentryLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
		if( sentryLevel ==  1 )
		{
			pos[2] = 60.0;
		}
		else if( sentryLevel ==  2 )
		{
			pos[2] = 80.0;
		}
		else if( sentryLevel ==  3 )
		{
			pos[2] = 90.0;
		}
		TeleportEntity(g_SleepIcon[client], pos, ang, NULL_VECTOR);
	}	
					
}
/////////////////////////////////////////////////////////////////////
//
// スリープアイコン削除
//
/////////////////////////////////////////////////////////////////////
stock RemoveSleepIcon(any:client)
{
	// スリープアイコンを消す
	if(g_SleepIcon[client] != -1 && IsValidEdict(g_SleepIcon[client]) && TF2_EdictNameEqual(g_SleepIcon[client], "prop_dynamic"))
	{
		// ウェイ区アップエフェクト
		// セントリーのレベルに合わせて高さ調整
		new sentryLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
		new Float:pos[3];
		pos[1] = 15.0;
		new Float:ang[3];
		if( sentryLevel ==  1 )
		{
			pos[2] = 60.0;
		}
		else if( sentryLevel ==  2 )
		{
			pos[2] = 80.0;
		}
		else if( sentryLevel ==  3 )
		{
			pos[2] = 90.0;
		}
		AttachParticle(g_PlayerSentry[client], EFFECT_WAKEUP, 1.0, pos, ang);

		// 割れる音
		EmitSoundToAll(SOUND_WAKEUP, g_SleepIcon[client], _, _, SND_CHANGEPITCH, 1.0, 200);

		// アイコン削除
		AcceptEntityInput(g_SleepIcon[client], "Kill");
		g_SleepIcon[client] = -1;
	}	
					
}

