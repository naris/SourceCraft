/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.7
// ・一部仕様を変更
// ・1.3.1でコンパイル
// ・sm_rmf_supercharger_drain_speedを追加
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
#define PL_NAME "Supercharger"
#define PL_DESC "Supercharger"
#define PL_VERSION "0.0.7"
#define PL_TRANSLATION "supercharger.phrases"


#define EFFECT_ABLE_SMOKE "sapper_smoke"
#define EFFECT_ABLE_EMBERS "sapper_flyingembers"
#define EFFECT_ABLE_FLASH "sapper_flashup"
#define EFFECT_ABLE_DEBRIS "sapper_debris"

#define EFFECT_CHARGER_SPARK1 "buildingdamage_sparks2"
#define EFFECT_CHARGER_SPARK2 "buildingdamage_sparks4"
#define EFFECT_CHARGER_FIRE "buildingdamage_fire3"

#define SOUND_CHARGER_ON "weapons/sapper_removed.wav"
#define SOUND_CHARGER_START "weapons/minifun_wind_up.wav"
#define SOUND_CHARGER_LOOP "misc/hologram_malfunction.wav"
#define SOUND_CHARGER_STOP "weapons/minigun_wind_down.wav"

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
new Handle:g_ChargeLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ループ処理
new Handle:g_ChargeSpeed = INVALID_HANDLE;							// ConVar回復速度
new Handle:g_ChargeRate = INVALID_HANDLE;							// ConVar回復レート
new Handle:g_DrainSpeed = INVALID_HANDLE;							// ConVarドレインスピード
new Handle:g_DrainLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;				// ドレインループ処理
new g_LoopEffect[MAXPLAYERS+1][3];									// ループエフェクト
new bool:g_NowHealing[MAXPLAYERS+1] = false; 						// 回復中？

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
		CreateConVar("sm_rmf_tf_supercharger", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_supercharger","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_ChargeSpeed	= CreateConVar("sm_rmf_supercharger_charg_speed",	"1.0",	"Charge Speed (0.0-120.0)");
		g_ChargeRate	= CreateConVar("sm_rmf_supercharger_charge_rate",	"2",	"Charge rate (0-100)");
		g_DrainSpeed	= CreateConVar("sm_rmf_supercharger_drain_speed",	"0.25",	"Ubercharge drain speed (0.0-120.0)");
		HookConVarChange(g_ChargeSpeed,	ConVarChange_Time);
		HookConVarChange(g_ChargeRate,	ConVarChange_Uber);
		HookConVarChange(g_DrainSpeed,	ConVarChange_Time);
		
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_supercharger_class", "5", "Ability class");
		
	}
	
	// マップ開始
	if(StrEqual(name, EVENT_MAP_START))
	{
		
		PrePlayParticle(EFFECT_CHARGER_SPARK1);
		PrePlayParticle(EFFECT_CHARGER_SPARK2);
		PrePlayParticle(EFFECT_CHARGER_FIRE);
		
		PrePlayParticle(EFFECT_ABLE_SMOKE);
		PrePlayParticle(EFFECT_ABLE_EMBERS);
		PrePlayParticle(EFFECT_ABLE_FLASH);
		PrePlayParticle(EFFECT_ABLE_DEBRIS);

		
		PrecacheSound(SOUND_CHARGER_ON, true);
		PrecacheSound(SOUND_CHARGER_START, true);
		PrecacheSound(SOUND_CHARGER_LOOP, true);
		PrecacheSound(SOUND_CHARGER_STOP, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		for(new i = 0; i < 3; i++)
		{
			DeleteParticle(g_LoopEffect[client][i]);
			g_LoopEffect[client][i] = -1;
		}

		// サウンド停止
		StopSound(client, 0, SOUND_CHARGER_LOOP);
	
		// 回復状態クリア
		g_NowHealing[client] = false;

		// タイマークリア
		ClearTimer( g_ChargeLoopTimer[ client ] );
		ClearTimer( g_DrainLoopTimer[ client ] );
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Medic)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_SUPERCHARGER", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_SUPERCHARGER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_SUPERCHARGER_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_SUPERCHARGER_ATTRIBUTE_2", client );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );

		}

	}

	// プレイヤー復活ディレイ
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
		// 発動
		if( TF2_GetPlayerClass( client ) == TFClass_Medic && g_AbilityUnlock[client])
		{
			Supercharger( client );
			// 近接武器以外削除
			ClientCommand(client, "slot2");
			new weaponIndex;
			for(new i=0;i<3;i++)
			{
				if(i != 1)
				{
					weaponIndex = GetPlayerWeaponSlot(client, i);
					if( weaponIndex != -1 )
					{
						TF2_RemoveWeaponSlot(client, i);
						//RemovePlayerItem(client, weaponIndex);
						//AcceptEntityInput(weaponIndex, "Kill");		
					}
				}
			}
			
			ClearTimer( g_DrainLoopTimer[ client ] );
			g_DrainLoopTimer[client] = CreateTimer( GetConVarFloat( g_DrainSpeed ), Timer_DrainLoop, client, TIMER_REPEAT);
		}
	}

	// プレイヤーリサプライ
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			// メディック
			if( TF2_GetPlayerClass(client) == TFClass_Medic && g_AbilityUnlock[client] )
			{
				// 近接武器以外削除
				ClientCommand(client, "slot2");
				new weaponIndex;
				for(new i=0;i<3;i++)
				{
					if(i != 1)
					{
						weaponIndex = GetPlayerWeaponSlot(client, i);
						if( weaponIndex != -1 )
						{
							TF2_RemoveWeaponSlot(client, i);
							//RemovePlayerItem(client, weaponIndex);
							//AcceptEntityInput(weaponIndex, "Kill");		
						}
					}
				}						
			}
		}
	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動
//
/////////////////////////////////////////////////////////////////////
public Supercharger( any:client )
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// 連続処理用タイマー発動
		ClearTimer( g_ChargeLoopTimer[ client ] );
		g_ChargeLoopTimer[client] = CreateTimer(GetConVarFloat(g_ChargeSpeed), Timer_ChargeLoop, client, TIMER_REPEAT);
		
		
		// サウンドとかエフェクト
		EmitSoundToAll(SOUND_CHARGER_ON, client, _, _, SND_CHANGEPITCH, 0.2, 80);
	
		AttachParticleBone(client, EFFECT_ABLE_SMOKE, "flag", 1.0);
		AttachParticleBone(client, EFFECT_ABLE_EMBERS, "flag", 1.0);
		AttachParticleBone(client, EFFECT_ABLE_FLASH, "flag", 1.0);
		AttachParticleBone(client, EFFECT_ABLE_DEBRIS, "flag", 1.0);
		
		g_LoopEffect[client][0] = AttachLoopParticleBone(client, EFFECT_CHARGER_SPARK1, "flag")
		g_LoopEffect[client][1] = AttachLoopParticleBone(client, EFFECT_CHARGER_SPARK2, "flag")
		//g_LoopEffect[client][2] = AttachLoopParticleBone(client, EFFECT_CHARGER_FIRE, "flag")
	}
}


/////////////////////////////////////////////////////////////////////
//
// ユーバードレインループ
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DrainLoop(Handle:timer, any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		// 回復対象がいない＆ユーバー中じゃない。
		if( TF2_GetHealingTarget(client) <= 0 && !TF2_IsPlayerUber(client))
		{
			// 現在のユーバー量取得
			new nowUber = TF2_GetPlayerUberLevel(client);
			
			// 1以上の時
			if( nowUber > 0 )
			{
				nowUber -= 1;
			}
			// ユーバー量設定
			TF2_SetPlayerUberLevel(client, nowUber);
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ループタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_ChargeLoop(Handle:timer, any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		// 回復対象がいる。
		if(TF2_GetHealingTarget(client) > 0 && !TF2_IsPlayerUber(client))
		{
			// 回復はじめだけサウンドとループエフェクト再生
			if(!g_NowHealing[client])
			{
				EmitSoundToAll(SOUND_CHARGER_ON, client, _, _, SND_CHANGEPITCH, 0.2, 80);
				
				AttachParticleBone(client, EFFECT_ABLE_DEBRIS, "flag", 1.0);
				AttachParticleBone(client, EFFECT_ABLE_FLASH, "flag", 1.0);
				AttachParticleBone(client, EFFECT_ABLE_SMOKE, "flag", 1.0);
				
				
				EmitSoundToAll(SOUND_CHARGER_LOOP, client, _, _, SND_CHANGEPITCH, 0.2, 120);
				//g_LoopEffect[client][1] = AttachLoopParticleBone(client, EFFECT_CHARGER_SPARK2, "flag")
				g_LoopEffect[client][2] = AttachLoopParticleBone(client, EFFECT_CHARGER_FIRE, "flag")
			}
			
			// 現在のユーバー量取得
			new nowCharge = TF2_GetPlayerUberLevel(client);
			
			// 満タンでないとき
			if( nowCharge < 100 )
			{
				nowCharge += GetConVarInt(g_ChargeRate);

				if(nowCharge >= 100)
				{
					nowCharge = 100;
				}
				
				// ユーバー量設定
				TF2_SetPlayerUberLevel(client, nowCharge)
				
				//AttachParticleBone(client, EFFECT_ABLE_SMOKE, "flag", 1.0);

		    		
			}
			
			AttachParticleBone(client, EFFECT_ABLE_EMBERS, "flag", 1.0);
			g_NowHealing[client] = true;
		}
		else
		{
			// 回復中じゃなければサウンドとか停止
			if(g_NowHealing[client])
			{
				// サウンド停止
				StopSound(client, 0, SOUND_CHARGER_LOOP);
				//DeleteParticle(g_LoopEffect[client][1], 0.01);
				
				EmitSoundToAll(SOUND_CHARGER_STOP, client, _, _, SND_CHANGEPITCH, 0.5, 200);
				DeleteParticle(g_LoopEffect[client][2], 0.01);
				g_NowHealing[client] = false;
			}
			
		}
	
	}
	else
	{
		ClearTimer( g_ChargeLoopTimer[ client ] );
	}
}


/////////////////////////////////////////////////////////////////////
//
// チャージ速度
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_ChargeSpeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0～5.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 5.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 5.0");
	}
}
/////////////////////////////////////////////////////////////////////
//
// チャージレート
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_ChargeRate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0～100まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 100");
	}
}
