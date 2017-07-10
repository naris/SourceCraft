/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.1.1
// ・仕様を変更
// ・sm_rmf_markingshot_charge_magを追加
// ・sm_rmf_markingshot_time_maxを追加
// ・sm_rmf_markingshot_time_minを追加
// ・1.3.1でコンパイル
// 2009/10/06 - 0.0.5
// ・内部処理を変更
// ・マーキング時間のベース値を変更。
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
#define PL_NAME "Marking Shot"
#define PL_DESC "Marking Shot"
#define PL_VERSION "0.1.1"
#define PL_TRANSLATION "markingshot.phrases"

#define SOUND_PLAYER_MARKED "items/cart_explode_trigger.wav"

#define SOUND_MARKING_FIRE "player/flame_out.wav"
#define SOUND_MARKING_HIT "weapons/jar_explode.wav"

#define EFFECT_PEE_HIT "peejar_groundsplash"

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
new Float:g_PlayerMarkingEndTime[MAXPLAYERS+1] = 0.0;				// マーキング開始時間
new Float:g_PlayerMarkingTime[MAXPLAYERS+1] = 0.0;					// マーキング時間
new Handle:g_MarkingEndTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// マーキング終了タイマー
new bool:g_PlayerMarked[MAXPLAYERS+1] = false;						// 尿マークされた？
new Handle:g_MarkingTimeMax = INVALID_HANDLE;						// ConVar最大マーキング時間
new Handle:g_MarkingTimeMin = INVALID_HANDLE;						// ConVar最小マーキング時間
new Handle:g_ChargeMag = INVALID_HANDLE;							// ConVarチャージ量倍率


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
		CreateConVar("sm_rmf_tf_markingshot", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_markingshot","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_markingshot_class", "2", "Ability class");
		
		g_MarkingTimeMax	= CreateConVar("sm_rmf_markingshot_time_max",	"25.0","Max marking time (0.0-120.0)");
		g_MarkingTimeMin	= CreateConVar("sm_rmf_markingshot_time_min",	"2.0","Min marking time (0.0-120.0)");
		g_ChargeMag			= CreateConVar("sm_rmf_markingshot_charge_mag",	"0.8","Charge amount magnification (0.0-10.0)");
		HookConVarChange(g_MarkingTimeMin, ConVarChange_Time);
		HookConVarChange(g_MarkingTimeMax, ConVarChange_Time);
		HookConVarChange(g_ChargeMag, ConVarChange_Magnification);

		
	}
	
	// マップ開始
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_PEE_HIT);
		PrecacheSound(SOUND_MARKING_FIRE, true);
		PrecacheSound(SOUND_MARKING_HIT, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// タイマークリア
		ClearTimer( g_MarkingEndTimer[ client ] );
		
		// マーキングされていない
		g_PlayerMarkingEndTime[client] =  0.0;
		g_PlayerMarkingTime[client] = 0.0
		g_PlayerMarked[client] = false;
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:percentage[16];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_MARKINGSHOT", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_1", client );
			GetPercentageString( GetConVarFloat( g_ChargeMag ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_2", client, percentage );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_3", client );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s\n%s", attribute1, attribute2, attribute3 );
		}

	}
	
	// プレイヤー復活ディレイ
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
		// 発動
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper && g_AbilityUnlock[client])
		{
			ClientCommand(client, "slot1");
			// セカンダリ削除
			new weaponIndex = GetPlayerWeaponSlot(client, 1);
			if( weaponIndex != -1 )
			{
				TF2_RemoveWeaponSlot(client, 1);
				//RemovePlayerItem(client, weaponIndex);
				//AcceptEntityInput(weaponIndex, "Kill");		
			}	
		}
	}
	
	// プレイヤーダメージ
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new health = GetEventInt(event, "health");
		
		if( attacker > 0 && attacker != client && TF2_GetPlayerClass( attacker ) == TFClass_Sniper && g_AbilityUnlock[attacker] && health > 0 )
		{
			if(TF2_CurrentWeaponEqual(attacker, "CTFSniperRifle"))
			{
				// マーキング時間はチャージ時間に比例
				new Float:time = TF2_GetPlayerSniperCharge( attacker ) * 0.1 * 5.0;
				
				// チャージしてる場合のみ
				if( time > 0.0 )
				{
					// 既に設定済みのマーキング時間よりながいときだけ
					if(( g_PlayerMarkingEndTime[client] - GetGameTime() ) <= time )
					{
						// 最大設定
						if( time > GetConVarFloat( g_MarkingTimeMax ) )
						{
							time = GetConVarFloat( g_MarkingTimeMax );
						}
						
						// 最小設定
						if( time < GetConVarFloat( g_MarkingTimeMin ) )
						{
							time = GetConVarFloat( g_MarkingTimeMin );
						}
						
						// 開始時間を保存
						g_PlayerMarkingEndTime[client] = GetGameTime() +  time;
						// マーキング時間
						g_PlayerMarkingTime[client] = time;

						//PrintToChat(attacker, "%f", g_PlayerMarkingTime[client]);
						// チャージしてるときだけ
						if( g_PlayerMarkingTime[client] > 0.0 )
						{
							EmitSoundToAll(SOUND_MARKING_HIT, client, _, _, SND_CHANGEPITCH, 1.0, 150);		
							
							new Float:pos[3];
							pos[2] = 50.0;
							AttachParticle( client, EFFECT_PEE_HIT, 2.0, pos );
							
							// 終了タイマー設定
							//PrintToChatAll("%f", time);
							ClearTimer( g_MarkingEndTimer[ client ] );	
							g_MarkingEndTimer[ client ] = CreateTimer( time,  Timer_MarkingEnd, client );
							
							// 尿まみれ
							TF2_RemoveCond( client, TF2_COND_URINE );
							TF2_AddCond( client, TF2_COND_URINE );
							
							// マーキングされた
							g_PlayerMarked[ client ] = true;
							
							// メッセージ表示
							PrintToChat(client, "\x05%T", "MARKINGSHOT_TAKE_MARK", client);	// マーキングされた！
						}
					}
				}
			}
		}
	}	

	// プレイヤーリサプライ
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame( client ) && IsPlayerAlive( client ) )
		{
			// タイマークリア
			ClearTimer( g_MarkingEndTimer[ client ] );
			
			// マーキングされていない
			g_PlayerMarkingEndTime[ client ] = 0.0;
			g_PlayerMarkingTime[ client ] = 0.0
			g_PlayerMarked[ client ] = false;
			
			// スナイパー
			if( TF2_GetPlayerClass(client) == TFClass_Sniper && g_AbilityUnlock[client] )
			{
				// 武器再取得しないように
				// セカンダリ削除
				ClientCommand(client, "slot1");
				new weaponIndex = GetPlayerWeaponSlot(client, 1);
				if( weaponIndex != -1 )
				{
					TF2_RemoveWeaponSlot(client, 1);
					//RemovePlayerItem(client, weaponIndex);
					//AcceptEntityInput(weaponIndex, "Kill");		
				}	
			}
		}
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
		// スナイパーのみ
		if( TF2_GetPlayerClass(client) == TFClass_Sniper && g_AbilityUnlock[client] )
		{
			// ズーム中
			if( TF2_IsPlayerZoomed( client ) )
			{
				// チャージ量制限
				if( TF2_GetPlayerSniperCharge(client) > 100 * GetConVarFloat( g_ChargeMag ) )
				{	
					TF2_SetPlayerSniperCharge( client, RoundFloat( 100 * GetConVarFloat( g_ChargeMag ) ) );
				}
			}
		}
	}
}
/////////////////////////////////////////////////////////////////////
//
// マーキング終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_MarkingEnd(Handle:timer, any:client)
{
	g_MarkingEndTimer[ client ] = INVALID_HANDLE;
	// ゲームに入っている
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		// マーキングされていて尿まみれなら解除
		if( g_PlayerMarked[ client ] && TF2_IsPlayerUrine( client ) )
		{
			TF2_RemoveCond( client, TF2_COND_URINE );
			g_PlayerMarkingEndTime[ client ] = 0.0;
			g_PlayerMarkingTime[ client ] = 0.0
			g_PlayerMarked[ client ] = false;
		}
	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// クリティカル検出
//
/////////////////////////////////////////////////////////////////////
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	// MODがONの時だけ
	if( !g_IsRunning )
		return Plugin_Continue;	

	// スナイパーのときのみ
	if( TF2_GetPlayerClass(client) == TFClass_Sniper && g_AbilityUnlock[client] )
	{
		// スナイパーライフル
		if( TF2_CurrentWeaponEqual(client, "CTFSniperRifle" ) && TF2_GetPlayerSniperCharge(client) > 0)
		{
			EmitSoundToAll(SOUND_MARKING_FIRE, TF2_GetCurrentWeapon(client), _, _, SND_CHANGEPITCH, 1.0, 180);		
		}
		
	}

	return Plugin_Continue;	
}

