/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.2
// ・1.3.1でコンパイル
// ・仕様を一部変更

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
#define PL_NAME			"Flying Doctor"
#define PL_DESC			"Flying Doctor"
#define PL_VERSION		"0.0.2"
#define PL_TRANSLATION	"flyingdoctor.phrases"


#define SOUND_GRAB	"misc/rubberglove_stretch.wav"
#define SOUND_CUT	"misc/rubberglove_snap.wav"

/////////////////////////////////////////////////////////////////////
//
// MOD情報
//
/////////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name		= PL_NAME,
	author		= "RIKUSYO",
	description	= PL_DESC,
	version		= PL_VERSION,
	url			= "http://ameblo.jp/rikusyo/"
}

/////////////////////////////////////////////////////////////////////
//
// グローバル変数
//
/////////////////////////////////////////////////////////////////////
new bool:g_Grab[MAXPLAYERS+1] = false;	// グラブ発動？
new bool:g_Long[MAXPLAYERS+1] = false;	// 長くなった？
new g_GrabCount[MAXPLAYERS+1] = 0;		// 発動まで？


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
		CreateConVar("sm_rmf_tf_flyingdoctor", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_flyingdoctor","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_flyingdoctor_class", "5", "Ability class");
	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
	}	
	
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheSound( SOUND_GRAB,	true );
		PrecacheSound( SOUND_CUT,	true );
		
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
	
	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		 g_Grab[client]		= false;
		 g_Long[client]		= false;
		 g_GrabCount[client]= 0;

		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Medic )
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_FLYINGDOCTOR", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_FLYINGDOCTOR_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_FLYINGDOCTOR_ATTRIBUTE_1", client );
			Format( attribute1, sizeof( attribute2 ), "%T", "DESCRIPTION_FLYINGDOCTOR_ATTRIBUTE_2", client );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s", attribute1 );
			// 3ページ目
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s", attribute2 );
		}
	}
	
	// プレイヤー死亡
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
	}

	// プレイヤー切断
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
	}
	// プレイヤー復活ディレイ
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
		// メディック
		if( TF2_GetPlayerClass(client) == TFClass_Medic && g_AbilityUnlock[client] )
		{
			ClientCommand(client, "slot3");
			// セカンダリ削除
			new weaponIndex = GetPlayerWeaponSlot(client, 2);
			if( weaponIndex != -1 )
			{
				TF2_RemoveWeaponSlot(client, 2);
			}
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
				ClientCommand(client, "slot3");
				// セカンダリ削除
				new weaponIndex = GetPlayerWeaponSlot(client, 2);
				if( weaponIndex != -1 )
				{
					TF2_RemoveWeaponSlot(client, 2);
				}
				
			}
		}
	}	
	
	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動チェック
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// メディックである
		if( TF2_GetPlayerClass( client ) == TFClass_Medic && g_AbilityUnlock[client] )
		{
			// キーチェック
			if( CheckElapsedTime(client, 0.01) )
			{
				// ジャンプキー
				if ( GetClientButtons(client) & IN_JUMP )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);

					// 回復中のターゲット取得
					new target = TF2_GetHealingTarget(client);
					// ターゲットいた
					if( target != -1 )
					{
						// カウントアップ
						g_GrabCount[client] += 1;
						
						// 15超えたら発動
						if( g_GrabCount[client] > 15 )
						{
							// メディックとターゲットの位置取得して差を求める
							new Float:targetPos[3];
							new Float:clientPos[3];
							GetClientAbsOrigin(target, targetPos);
							GetClientAbsOrigin(client, clientPos);
							
							// 空中にいる間だけ
							if( !(GetEntityFlags(client) & FL_ONGROUND) )
							{
								// どれだけ進ませるかを取得
								new Float:diffPos[3];
								targetPos[2] += 120.0;
								SubtractVectors(targetPos, clientPos, diffPos);
								ScaleVector(diffPos, 0.05);
									
								// 実際に適用
								new Float:clientVelocity[3];
								GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", clientVelocity);
								AddVectors(clientVelocity, diffPos, clientVelocity);
								SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", clientVelocity);
								
								// 初回なら音鳴らす
								if(!g_Grab[client])
								{
									g_Grab[client] = true;
									StopSound(TF2_GetCurrentWeapon(client), 0, SOUND_GRAB);
									EmitSoundToAll(SOUND_GRAB, TF2_GetCurrentWeapon(client), _, _, _, 0.8);
								}
									
								// ターゲットとの距離が4.5m超えたら音鳴らす
								if( GetVectorDistanceMeter(clientPos, targetPos) > 4.5 )
								{
									// 一回のみ
									if(!g_Long[client])
									{
										g_Long[client] = true;
										StopSound(TF2_GetCurrentWeapon(client), 0, SOUND_GRAB);
										EmitSoundToAll(SOUND_GRAB, TF2_GetCurrentWeapon(client), _, _, _, 0.8);
									
									}
								
								}
								else
								{
									// 短い場合
									g_Long[client] = false;
									
								}
							}							
						}
					
					}
					else
					{
						// 距離が離れすぎたときは音鳴らして終了
						if( g_Grab[client] )
						{
							g_Grab[client]		= false;
							g_Long[client]		= false;
							g_GrabCount[client]	= 0;
							StopSound(TF2_GetCurrentWeapon(client), 0, SOUND_GRAB);
							EmitSoundToAll(SOUND_CUT, TF2_GetCurrentWeapon(client), _, _, SND_CHANGEPITCH, 1.00, 100);
						}
					}
				}
				else
				{
					// リセット
					g_Grab[client]		= false;
					g_Long[client]		= false;
					g_GrabCount[client]	= 0;
				}				
			}
		}		
	}
}

