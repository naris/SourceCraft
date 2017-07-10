/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.8
// ・仕様を変更
// ・1.3.1でコンパイル
// ・sm_rmf_dopinginjection_doping_timeを追加
// ・sm_rmf_dopinginjection_use_ammoを追加
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
#include <sdkhooks>

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Doping Injection"
#define PL_DESC "Doping Injection"
#define PL_VERSION "0.0.8"
#define PL_TRANSLATION "dopinginjection.phrases"

#define EFFECT_HEAL_RED	"healthgained_red"
#define EFFECT_HEAL_BLU	"healthgained_blu"
#define EFFECT_BLOOD	"blood_impact_red_01"
#define EFFECT_BREAK	"lowV_debrischunks"

//#define SOUND_HEAL_START "weapons/minigun_wind_up.wav"
//#define SOUND_HEAL_LOOP "weapons/minigun_spin.wav"
//#define SOUND_HEAL_STOP "weapons/minigun_wind_down.wav"

#define SOUND_DOPING_INJECTION "weapons/ubersaw_hit1.wav"
#define SOUND_BREAK_SYRINGE "weapons/bottle_break.wav"
#define SOUND_NO_TARGET "weapons/medigun_no_target.wav"

#define MDL_SYRINGE "models/weapons/w_models/w_syringe.mdl"
#define MDL_INSIDE "models/effects/miniguncasing.mdl"

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
new Handle:g_HealLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ループ処理
new Handle:g_HealSpeed = INVALID_HANDLE;		// ConVar回復速度
new Handle:g_HealRate = INVALID_HANDLE;			// ConVar回復レート
new bool:g_NowHealing[MAXPLAYERS+1] = false; 						// 回復中？

new Handle:g_HealthDreinTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// 体力減らす用のタイマー
new bool:g_NeedDrein[MAXPLAYERS+1]		= false;				// ドレインが必要か？
new Handle:g_DopingTime = INVALID_HANDLE;			// ConVar持続時間
new Handle:g_UseAmmo = INVALID_HANDLE;				// ConVa使用弾薬
new g_SyringeModel[MAXPLAYERS+1] = -1; 							// 頭に刺す注射
new g_InsideModel[MAXPLAYERS+1] = -1; 							// 頭に刺す注射の中身
new bool:g_NowDoping[MAXPLAYERS+1] = false; 					// ドーピング中？
new Handle:g_SyringeTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// 注射タイマー
new Handle:g_DopingLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// ループ処理
new g_NowTrans[MAXPLAYERS+1] = 255; 							// 液体の透明度

new String:SOUND_VOICE[9][64];				// ボイスファイル名 9クラス

new model = -1;


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
		CreateConVar("sm_rmf_tf_dopinginjection", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_dopinginjection","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_HealSpeed	= CreateConVar("sm_rmf_dopinginjection_heal_speed",		"1.0",	"heal Speed (0.0-120.0)");
		g_HealRate	= CreateConVar("sm_rmf_dopinginjection_heal_rate",		"10",	"Heal rate (0-500)");
		g_DopingTime= CreateConVar("sm_rmf_dopinginjection_doping_time",	"10.0",	"Doping duration (0.0-120.0)");
		g_UseAmmo	= CreateConVar("sm_rmf_dopinginjection_use_ammo",		"20",	"Ammo required (0-200)");
		HookConVarChange(g_HealSpeed, ConVarChange_Time);
		HookConVarChange(g_HealRate, ConVarChange_Health);
		HookConVarChange(g_DopingTime, ConVarChange_Time);
		HookConVarChange(g_UseAmmo, ConVarChange_Ammo);
	
		// アビリティクラス設定
		CreateConVar("sm_rmf_dopinginjection_class", "5", "Ability class");
		
		// ボイスファイル
		SOUND_VOICE[_:TFClass_Scout - 1]	= "vo/scout_painsharp01.wav"
		SOUND_VOICE[_:TFClass_Sniper - 1]	= "vo/sniper_painsharp01.wav"
		SOUND_VOICE[_:TFClass_Soldier - 1]	= "vo/soldier_painsharp01.wav"
		SOUND_VOICE[_:TFClass_DemoMan - 1]	= "vo/demoman_painsharp02.wav"
		SOUND_VOICE[_:TFClass_Medic - 1]	= "vo/medic_painsharp08.wav"
		SOUND_VOICE[_:TFClass_Heavy - 1]	= "vo/heavy_painsharp02.wav"
		SOUND_VOICE[_:TFClass_Pyro - 1]		= "vo/pyro_painsharp03.wav"
		SOUND_VOICE[_:TFClass_Spy - 1]		= "vo/spy_painsharp03.wav"
		SOUND_VOICE[_:TFClass_Engineer - 1]	= "vo/engineer_painsharp02.wav"
		
		
	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 注射削除
			DeleteSyringe(i);
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 注射削除
			DeleteSyringe(i);
		}
	}
	
	// マップ開始
	if(StrEqual(name, EVENT_MAP_START))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 注射削除
			DeleteSyringe(client)
		}

		PrePlayParticle(EFFECT_HEAL_RED);
		PrePlayParticle(EFFECT_HEAL_BLU);
		PrePlayParticle(EFFECT_BLOOD);
		PrePlayParticle(EFFECT_BREAK);
		
//		PrecacheSound(SOUND_HEAL_START, true);
//		PrecacheSound(SOUND_HEAL_LOOP, true);
//		PrecacheSound(SOUND_HEAL_STOP, true);
		PrecacheSound(SOUND_DOPING_INJECTION, true);
		PrecacheSound(SOUND_BREAK_SYRINGE, true);
		PrecacheSound(SOUND_NO_TARGET, true);
		
		// ボイス読み込み
		for(new i = 0; i < 9; i++)
		{
			PrecacheSound(SOUND_VOICE[i], true);
		}		
		
		model=PrecacheModel(MDL_SYRINGE, true);
		PrecacheModel(MDL_INSIDE, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// サウンド停止
//		StopSound(client, 0, SOUND_HEAL_LOOP);
	
		// 回復状態クリア
		g_NowHealing[client] = false;
		g_NowDoping[client] = false;

		// 透明度リセット
		g_NowTrans[client] = 255;
		

		// タイマークリア
		ClearTimer( g_HealLoopTimer[ client ] );
		ClearTimer( g_SyringeTimer[ client ] );
		ClearTimer( g_DopingLoopTimer[ client ] );
		ClearTimer( g_HealthDreinTimer[client] );

		// ドレインリセット
		g_NeedDrein[ client ]	= false;
		
		// カラー元に戻す。
		SetEntityRenderColor(client, 255, 255, 255, 255);

		// 頭の注射削除
		DeleteSyringe(client);
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Medic)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_DOPINGINJECTION", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_DOPINGINJECTION_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_DOPINGINJECTION_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_DOPINGINJECTION_ATTRIBUTE_2", client, GetConVarInt( g_UseAmmo ) );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s", attribute1 );
			// 3ページ目
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s", attribute2 );
		}
	}
	
	// プレイヤー復活ディレイ
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
//		// 発動
//		if( TF2_GetPlayerClass( client ) == TFClass_Medic && g_AbilityUnlock[client])
//		{
//			ClientCommand(client, "slot2");
//			// セカンダリ削除
//			new weaponIndex = GetPlayerWeaponSlot(client, 0);
//			if( weaponIndex != -1 )
//			{
//			//	TF2_RemoveWeaponSlot(client, 0);
//				//RemovePlayerItem(client, weaponIndex);
//				//AcceptEntityInput(weaponIndex, "Kill");		
//			}			
//			// 連続処理用タイマー発動
//			//ClearTimer( g_HealLoopTimer[ client ] );
//			//g_HealLoopTimer[client] = CreateTimer(GetConVarFloat(g_HealSpeed), Timer_HealLoop, client, TIMER_REPEAT);
//			
//			// 色変更
//			if( TFTeam:GetClientTeam(client) == TFTeam_Red )
//			{
//				SetEntityRenderColor(client, 255, 200, 200, 255);
//			}
//			else
//			{
//				SetEntityRenderColor(client, 220, 220, 255, 255);
//			}	
//		}
	}
		
	// プレイヤーリサプライ
//	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
//	{
//		if( IsClientInGame(client) && IsPlayerAlive(client) )
//		{
//			// メディック
//			if( TF2_GetPlayerClass(client) == TFClass_Medic && g_AbilityUnlock[client] )
//			{
//				// 武器再取得しないように
//				// 注射銃・ブルートザオガー削除
//				ClientCommand(client, "slot2");
//				// セカンダリ削除
//				new weaponIndex = GetPlayerWeaponSlot(client, 0);
//				if( weaponIndex != -1 )
//				{
//			//		TF2_RemoveWeaponSlot(client, 0);
//					//RemovePlayerItem(client, weaponIndex);
//					//AcceptEntityInput(weaponIndex, "Kill");		
//				}
//				
//				// 色変更
//				if( TFTeam:GetClientTeam(client) == TFTeam_Red )
//				{
//					SetEntityRenderColor(client, 255, 200, 200, 255);
//				}
//				else
//				{
//					SetEntityRenderColor(client, 220, 220, 255, 255);
//				}	
//					
//			}
//		}
//	}
	// プレイヤー接続
	if(StrEqual(name, EVENT_PLAYER_CONNECT))
	{
	}
	
	// プレイヤー切断
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
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
	return Plugin_Continue;
}


/////////////////////////////////////////////////////////////////////
//
// フレームアクション
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// メディックのみ
		if(TF2_GetPlayerClass(client) == TFClass_Medic && g_AbilityUnlock[client])
		{
			// キーチェック
			if( CheckElapsedTime(client, 1.5) )
			{
				// 攻撃ボタン
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
					DopingInjection(client);
				}

			}
		}
		
		// スパイの透明チェック
		if( TF2_GetPlayerClass(client) == TFClass_Spy && g_NowDoping[ client ] )
		{
			// 変装中や透明中なら注射隠す
			if( TF2_IsPlayerDisguised(client)
				|| TF2_IsPlayerChangingCloak(client)
				|| TF2_IsPlayerCloaked(client)
				|| TF2_IsPlayerFeignDeath(client) )
			{
				if( g_SyringeModel[ client ] != -1 )
				{
					SetEntityRenderMode( g_SyringeModel[ client ], RENDER_TRANSCOLOR );
					SetEntityRenderColor( g_SyringeModel[ client ], 255, 255, 255, 0 );
				}
				
				if( g_InsideModel[ client ] != -1 )
				{
					SetEntityRenderColor( g_InsideModel[ client ], 255, 255, 255, 0 );
				}
			}
			else
			{
				if( g_SyringeModel[ client ] != -1 )
				{
					SetEntityRenderMode( g_SyringeModel[ client ], RENDER_NORMAL );
					SetEntityRenderColor( g_SyringeModel[ client ], 255, 255, 255, 255 );
				}
				
				if( g_InsideModel[ client ] != -1 )
				{
					SetEntityRenderColor( g_InsideModel[ client ], 255, 255, 255, g_NowTrans[client] );
				}
			}
			
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// 注射刺す
//
/////////////////////////////////////////////////////////////////////
stock DopingInjection(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// 武器は注射銃とブルートザオガー
		if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_SYRINGEGUN 
		|| TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_BLUTSAUGER )
		{
			// ターゲットを取得
			new target = GetClientAimTarget(client, false);
//			if(target < 1)
//				target = client;
			
			// ターゲットが味方
			if( target != -1 && IsPlayer( client )  )
			{
				if( GetClientTeam( client ) == GetClientTeam( target ) && GetDistanceMeter( client, target ) <= 2.0 )
				{
					// 注射してない
					if( !g_NowDoping[ target ] )
					{
						new nowAmmo = GetEntProp( TF2_GetCurrentWeapon(client), Prop_Send, "m_iClip1"); 
						
						// 弾が指定数以上
						if( nowAmmo >= GetConVarInt( g_UseAmmo ) )
						{
							// 終了タイマー発動
							ClearTimer( g_SyringeTimer[ target ] );
							g_SyringeTimer[ target ] = CreateTimer( GetConVarFloat( g_DopingTime ), Timer_DopingEnd, target );
							
							// 連続処理用タイマー発動
							ClearTimer( g_DopingLoopTimer[ target ] );
							g_DopingLoopTimer[ target ] = CreateTimer(GetConVarFloat(g_HealSpeed), Timer_DopingLoop, target, TIMER_REPEAT);
							
							// 頭に注射
							SpawnSyringe( target );
							
							// 弾減らす
							nowAmmo -= GetConVarInt( g_UseAmmo );
							SetEntProp( TF2_GetCurrentWeapon(client), Prop_Send, "m_iClip1", nowAmmo ); 
							
							// 発動
							g_NowDoping[ target ] = true;
							
							// メッセージ
							PrintToChat( target, "\x05%T", "MESSAGE_INJECTION", client);

							return;
						}
					}
				}
			}
			EmitSoundToClient(client, SOUND_NO_TARGET, client, _, _, _, 1.0);
		}
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// ループタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DopingLoop(Handle:timer, any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// 変装中や透明中は回復できない
		if( !TF2_IsPlayerDisguised(client)
			&& !TF2_IsPlayerChangingCloak(client)
			&& !TF2_IsPlayerCloaked(client)
			&& !TF2_IsPlayerFeignDeath(client) )
		{
			// 回復
			new nowHealth = GetClientHealth(client);
			if( nowHealth < TF2_GetPlayerMaxHealth(client) )
			{
				
				// ヘルスを回復
				nowHealth += GetConVarInt(g_HealRate);
				
				if(nowHealth >= TF2_GetPlayerMaxHealth(client))
				{
					nowHealth = TF2_GetPlayerMaxHealth(client);
				}
				
				// この回復によってオーバーヒール状態になったらドレインが必要
				if( GetClientHealth(client) <= TF2_GetPlayerDefaultHealth(client) && nowHealth > TF2_GetPlayerDefaultHealth(client) )
				{
					g_NeedDrein[client] = true;
				}

				// デフォルト以下ならいらない
				if( nowHealth <= TF2_GetPlayerDefaultHealth(client) )
				{
					g_NeedDrein[client] = false;
				}
				
				// 体力設定
				SetEntityHealth(client, nowHealth);

				// 回復表示
				new Handle:newEvent = CreateEvent( "player_healonhit" );
				if( newEvent != INVALID_HANDLE )
				{
					SetEventInt( newEvent, "amount", GetConVarInt(g_HealRate) );
					SetEventInt( newEvent, "entindex", client );
					FireEvent( newEvent );
				}

				// エフェクト
				new Float:pos[3];
				for(new i = 0; i < GetConVarInt(g_HealRate); i++)
				{
					pos[0] = GetRandomFloat(-20.0, 20.0);
					pos[1] = GetRandomFloat(-20.0, 20.0);
					pos[2] = GetRandomFloat(-20.0, 0.0);
					if( TFTeam:GetClientTeam(client) == TFTeam_Red)
					{
			    		
						AttachParticleBone(client, EFFECT_HEAL_RED, "head", GetRandomFloat(1.0, 3.0), pos);
			    	}
					else
					{
						AttachParticleBone(client, EFFECT_HEAL_BLU, "head", GetRandomFloat(1.0, 3.0), pos);
					}
				}

				// ドレインタイマー発動
				ClearTimer( g_HealthDreinTimer[client] );
				if( g_NeedDrein[client] )
				{
					g_HealthDreinTimer[client] = CreateTimer(0.25, Timer_HealthDrein, client, TIMER_REPEAT );
				}
				
			}
					
			// 液体を薄める
			if( g_InsideModel[ client ]  != -1 )
			{
				g_NowTrans[client] -= RoundFloat( 255.0 / ( (GetConVarFloat( g_DopingTime ) / GetConVarFloat( g_HealSpeed ) ) ) );
				if( g_NowTrans[client] < 0 )
				{
					g_NowTrans[client] = 0;
				}
				SetEntityRenderColor( g_InsideModel[ client ], 255, 255, 255, g_NowTrans[client] );
			}
		}
	
	}
	else
	{
		ClearTimer( g_DopingLoopTimer[ client ] );
	}
}

/////////////////////////////////////////////////////////////////////
//
// ヘルスドレイン用
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_HealthDrein(Handle:timer, any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// オーバーヒール状態＆回復されていない
		if( TF2_IsPlayerOverHealing( client ) && TF2_GetNumHealers(client) == 0 && g_NeedDrein[client] )
		{
			// 1減らす
			new nowHealth = GetClientHealth(client);
			
			// 通常ヘルス以上ならドレイン
			if( nowHealth > TF2_GetPlayerDefaultHealth(client))
			{
				nowHealth--;
				SetEntityHealth(client, nowHealth);
				return;
			}
		}		
	}

	// 条件満たしてなければ終了
	ClearTimer( g_HealthDreinTimer[client] );
}

/////////////////////////////////////////////////////////////////////
//
// ドーピング終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DopingEnd(Handle:timer, any:client)
{
	g_SyringeTimer[ client ] = INVALID_HANDLE;
	ClearTimer( g_DopingLoopTimer[ client ] );
	
	// 発動終了
	g_NowDoping[ client ] = false;
	
	// ゲームに入っている
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		// 変装中や透明中以外
		if( !TF2_IsPlayerDisguised(client)
			&& !TF2_IsPlayerChangingCloak(client)
			&& !TF2_IsPlayerCloaked(client)
			&& !TF2_IsPlayerFeignDeath(client) )
		{
			if( g_SyringeModel[client] != -1 && g_SyringeModel[client] != 0)
			{
				if( IsValidEntity(g_SyringeModel[client]) )
				{
					// エフェクト
					new Float:pos[3];
					pos[0] = -5.0;
					pos[2] = 10.0;
					AttachParticleBone(client, EFFECT_BREAK, "head", 1.0, pos);
					
					// 壊れた音
					EmitSoundToAll( SOUND_BREAK_SYRINGE, g_SyringeModel[client], _, _, SND_CHANGEPITCH, 0.5, 100);		
				}	
			}
		}
		
		DeleteSyringe( client );
							
		// メッセージ
		PrintToChat( client, "\x05%T", "MESSAGE_END", client);
	}
}

/////////////////////////////////////////////////////////////////////
//
// ループタイマー
//
/////////////////////////////////////////////////////////////////////
//public Action:Timer_HealLoop(Handle:timer, any:client)
//{
//	// ゲームに入っている
//	if( IsClientInGame(client) && IsPlayerAlive(client) )
//	{
//		// 回復
//		new nowHealth = GetClientHealth(client);
//		// オーバーヒールされていないとき。
//		if( nowHealth < TF2_GetPlayerDefaultHealth(client) )
//		{
//			// 回復はじめだけループサウンド再生
//			if(!g_NowHealing[client])
//			{
//				// サウンドとかエフェクト
//				EmitSoundToAll(SOUND_HEAL_START, client, _, _, SND_CHANGEPITCH, 0.08, 150);
//				EmitSoundToAll(SOUND_HEAL_LOOP, client, _, _, SND_CHANGEPITCH, 0.05, 170);
//			}
//
//			nowHealth += GetConVarInt(g_HealRate);
//
//			if(nowHealth >= TF2_GetPlayerDefaultHealth(client))
//			{
//				nowHealth = TF2_GetPlayerDefaultHealth(client);
//			}
//			
//			// 体力設定
//			SetEntityHealth(client, nowHealth);
//
//			// 回復表示
//			new Handle:newEvent = CreateEvent( "player_healonhit" );
//			if( newEvent != INVALID_HANDLE )
//			{
//				SetEventInt( newEvent, "amount", GetConVarInt(g_HealRate) );
//				SetEventInt( newEvent, "entindex", client );
//				FireEvent( newEvent );
//			}
//			
//			new Float:pos[3];
//			for(new i = 0; i < GetConVarInt(g_HealRate); i++)
//			{
//		    	pos[0] = GetRandomFloat(-20.0, 20.0);
//		    	pos[1] = GetRandomFloat(-20.0, 20.0);
//		    	pos[2] = GetRandomFloat(-20.0, 0.0);
//		    	if( TFTeam:GetClientTeam(client) == TFTeam_Red)
//		    	{
//		    		
//					AttachParticleBone(client, EFFECT_HEAL_RED, "head", GetRandomFloat(1.0, 3.0), pos);
//		    	}
//				else
//				{
//					AttachParticleBone(client, EFFECT_HEAL_BLU, "head", GetRandomFloat(1.0, 3.0), pos);
//				}
//			}
//			g_NowHealing[client] = true;	
//		}
//		else
//		{
//			// 回復中じゃなければサウンド停止
//			if(g_NowHealing[client])
//			{
//				// サウンド停止
//				StopSound(client, 0, SOUND_HEAL_LOOP);
//				EmitSoundToAll(SOUND_HEAL_STOP, client, _, _, SND_CHANGEPITCH, 0.08, 150);
//				g_NowHealing[client] = false;
//			}
//			
//		}
//	
//	}
//	else
//	{
//		ClearTimer( g_HealLoopTimer[ client ] );
//	}
//}


/////////////////////////////////////////////////////////////////////
//
// 頭の注射作成
//
/////////////////////////////////////////////////////////////////////
stock SpawnSyringe(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// 一旦削除
		DeleteSyringe( client );
//		new Float:pos[3];
//		new Float:vec[3];
//		new Float:vel[3];
//		vec[0] = 1.0;
//		vec[1] = 1.0;
//		vec[2] = 1.0;
//		GetClientAbsOrigin(client, pos);
//		TE_Start("Client Projectile");
//		TE_WriteVector("m_vecOrigin",pos);
//		TE_WriteVector("m_vecVelocity",vel);
//		TE_WriteNum("m_nModelIndex",model);
//		TE_WriteNum("m_nLifeTime",100);
//		TE_WriteNum("m_hOwner",client);
//		TE_SendToClient(client)


		// 作成
		new syringe = CreateEntityByName("prop_dynamic");
		if ( IsValidEdict( syringe ) )
		{
			new String:tName[32];
			GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof( tName ) );
			DispatchKeyValue(syringe,	"targetname",	"head_syringe");
			DispatchKeyValue(syringe,	"parentname",	tName);
			SetEntityModel( syringe, MDL_SYRINGE );
			DispatchSpawn( syringe );
			SetVariantString( "!activator" );
			AcceptEntityInput(syringe, "SetParent",				client, client, 0);
			SetVariantString( "head" );
			AcceptEntityInput(syringe, "SetParentAttachment",	client, client, 0);
			ActivateEntity(syringe);
			SetEntPropEnt(syringe, Prop_Send, "m_hOwnerEntity", client );
			new Float:pos[3];
			new Float:ang[3];
			pos[0] = -5.0;
			pos[1] = 0.0;
			pos[2] = 18.0;
			ang[0] = 165.0;
			ang[1] = 0.0;
			ang[2] = 0.0;

			// 刺さっているように移動
			TeleportEntity( syringe , pos, ang, NULL_VECTOR );

			// 流血
			AttachParticleBone( client, EFFECT_BLOOD, "head", GetRandomFloat(1.0, 3.0) );
			
			// ボイス再生
			EmitSoundToAll(SOUND_VOICE[_:TF2_GetPlayerClass( client ) -1], client, _, _, SND_CHANGEPITCH, 1.0, 100);
			
			// さした音
			EmitSoundToAll( SOUND_DOPING_INJECTION, client, _, _, SND_CHANGEPITCH, 0.8, 80);
			
			// データを入れる
			g_SyringeModel[ client ] = syringe;
			
			// SDKHook
			SDKHook( g_SyringeModel[ client ], SDKHook_SetTransmit, Hook_SetTransmit );

			// 注射器の中身
			new inside = CreateEntityByName("prop_dynamic");
			if ( IsValidEdict( inside ) )
			{
				GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof( tName ) );
				DispatchKeyValue(inside,	"targetname",	"head_inside");
				DispatchKeyValue(inside,	"parentname",	tName);
				SetEntityModel( inside, MDL_INSIDE );
				DispatchSpawn( inside );
				SetVariantString( "!activator" );
				AcceptEntityInput(inside, "SetParent",				client, client, 0);
				SetVariantString( "head" );
				AcceptEntityInput(inside, "SetParentAttachment",	client, client, 0);
				ActivateEntity(inside);
				SetEntPropEnt(inside, Prop_Send, "m_hOwnerEntity", client );
				new Float:pos2[3];
				new Float:ang2[3];
				pos2[0] = -2.0;
				pos2[1] = 0.0;
				pos2[2] = 7.0;
				ang2[0] = 0.0;
				ang2[1] = 90.0;
				ang2[2] = -105.0;
				
				// 刺さっているように移動
				TeleportEntity( inside , pos2, ang2, NULL_VECTOR );
				
				g_NowTrans[client] = 255;
				SetEntityRenderMode( inside, RENDER_TRANSCOLOR );
				SetEntityRenderColor( inside, 255, 255, 255, g_NowTrans[client] );

				// データを入れる
				g_InsideModel[ client ] = inside;
				
				// SDKHook
				SDKHook( g_InsideModel[ client ], SDKHook_SetTransmit, Hook_SetTransmit );
			}
			
			
			// ドレインタイマークリア
			ClearTimer( g_HealthDreinTimer[client] );
	    }
	}
}
/////////////////////////////////////////////////////////////////////
//
// 頭の注射削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteSyringe(any:client)
{
	// 注射のモデルを削除
	if( g_SyringeModel[client] != -1 && g_SyringeModel[client] != 0)
	{
		// SDKUnhook
		SDKUnhook( g_SyringeModel[client], SDKHook_SetTransmit, Hook_SetTransmit );
		if( IsValidEntity(g_SyringeModel[client]) )
		{
			ActivateEntity(g_SyringeModel[client]);
			AcceptEntityInput(g_SyringeModel[client], "Kill");
			g_SyringeModel[client] = -1;
		}	
	}
	// 注射のモデルを削除
	if( g_InsideModel[client] != -1 && g_InsideModel[client] != 0)
	{
		if( IsValidEntity(g_InsideModel[client]) )
		{
			ActivateEntity(g_InsideModel[client]);
			AcceptEntityInput(g_InsideModel[client], "Kill");
			g_InsideModel[client] = -1;
		}	
	}
}

/////////////////////////////////////////////////////////////////////
//
// 一人称での表示非表示
//
/////////////////////////////////////////////////////////////////////
public Action:Hook_SetTransmit( entity, client )
{

	if( TF2_EdictNameEqual( entity, "prop_dynamic") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString( entity, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );

		// 設置したショベルなら
		if( StrEqual( nameTarget, "head_syringe" ) || StrEqual( nameTarget, "head_inside" ) )
		{
			// 自分（三人称中以外）は見えない
			if( client == GetEntPropEnt( entity, Prop_Send, "m_hOwnerEntity" ) && !TF2_IsPlayerTaunt(client) )
			{
			    return Plugin_Handled;
			}
		}
		
	}
    return Plugin_Continue;
}  
