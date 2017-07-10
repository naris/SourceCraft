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
#define PL_NAME "Curving Arrow"
#define PL_DESC "Curving Arrow"
#define PL_VERSION "0.0.5"
#define PL_TRANSLATION "curvingarrow.phrases"

#define SOUND_CURVARROW "weapons/fx/nearmiss/bulletltor09.wav"

#define EFFECT_CURARROW_RED "player_dripsred"
#define EFFECT_CURARROW_BLU "player_drips_blue"

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
new g_BowHold[MAXPLAYERS+1] = -1;					// 照準中？
new g_Arrow[MAXPLAYERS+1] = -1;						// 発射した矢
new Float:g_ChargeBeginTime[MAXPLAYERS+1] = 0.0;	// 照準開始時間
new Float:g_ChargeTime[MAXPLAYERS+1] = 0.0;			// チャージ時間
new Float:g_CurvDir[MAXPLAYERS+1][2];				// カーブ方向



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
		CreateConVar("sm_rmf_tf_curvingarrow", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_curvingarrow","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		

		// アビリティクラス設定
		CreateConVar("sm_rmf_curvingarrow_class", "2", "Ability class");
	
	}
	
	// マップ開始
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_CURARROW_RED);
		PrePlayParticle(EFFECT_CURARROW_BLU);

		PrecacheSound(SOUND_CURVARROW, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// 速度戻す
		TF2_SetPlayerDefaultSpeed(client);
		
		// 弓放してる
		g_BowHold[client] = -1;
		
		// 放った矢なし
		g_Arrow[client] = -1;
		
		// カーブ方向クリア
		g_CurvDir[client][0] = 0.0;
		g_CurvDir[client][1] = 0.0;
		
		// チャージ時間クリア
		g_ChargeBeginTime[client] = 0.0;
		g_ChargeTime[client] = 0.0;
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];


			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_CURVINGARROW", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_3", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s\n%s", attribute1, attribute2, attribute3 );
			
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
// ゲームフレーム
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// スナイパー
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper && g_AbilityUnlock[client])
		{
			// ハンツマン
			if(TF2_CurrentWeaponEqual(client, "CTFCompoundBow"))
			{
				// 弓を構えているときは動けない
				if( CheckElapsedTime(client, 0.1) )
				{
					// キーチェック時間保存
					SaveKeyTime(client);
					
					// 弓構えていなければ速度戻す
					if(!(GetClientButtons(client) & IN_ATTACK && TF2_IsPlayerSlowed(client)))
					{
						// デフォルト速度
						TF2_SetPlayerDefaultSpeed(client);
					}
					
					// 照準中
					if(GetClientButtons(client) & IN_ATTACK && GetEntPropFloat(TF2_GetCurrentWeapon(client), Prop_Send, "m_flChargeBeginTime") != 0.0)
					{
						// チャージ開始時間保存
						if(g_BowHold[client] == -1)
						{
							g_ChargeBeginTime[client] = GetEntPropFloat(TF2_GetCurrentWeapon(client), Prop_Send, "m_flChargeBeginTime");
						}
						
						// 照準中に設定
						g_BowHold[client] = 1;
						
						// 移動速度落とす
						if(TF2_IsPlayerSlowed(client))
						{
							TF2_SetPlayerSpeed(client, 0.5);
						}
						
						// 矢のカーブ方向設定
						g_CurvDir[client][0] = 0.0; // Y
						g_CurvDir[client][1] = 0.0; // X
						if(GetClientButtons(client) & IN_MOVELEFT)
						{
							g_CurvDir[client][1] = 1.0;
						}
						if(GetClientButtons(client) & IN_MOVERIGHT)
						{
							g_CurvDir[client][1] = -1.0;
						}
						if(GetClientButtons(client) & IN_FORWARD)
						{
							g_CurvDir[client][0] = -1.0;
						}
						if(GetClientButtons(client) & IN_BACK)
						{
							g_CurvDir[client][0] = 1.0;
						}	
						
						
					}
					else
					{
						// 弓発射＆カーブ方向設定済みか
						if(g_BowHold[client] == 1 && (g_CurvDir[client][0] != 0.0 || g_CurvDir[client][1] != 0.0))
						{
							// チャージ時間
							g_ChargeTime[client] = GetGameTime() -g_ChargeBeginTime[client];
							
							// 放った弓を検索
							g_Arrow[client] = -1;
							new arrow = -1;
							while ((arrow = FindEntityByClassname(arrow, "tf_projectile_arrow")) != -1)
							{
								// 発射したプレイヤーチェック
								new iOwner = GetEntPropEnt(arrow, Prop_Send, "m_hOwnerEntity");
								if(iOwner == client)
								{
									// 矢を保存
									g_Arrow[client] = arrow;
									
									// ブオンって音
									EmitSoundToAll(SOUND_CURVARROW, arrow, _, _, SND_CHANGEPITCH, 1.0, 40);
									
									// 矢にエフェクト
									if(TFTeam:GetClientTeam(client) == TFTeam_Red)
									{
										AttachParticle(arrow, EFFECT_CURARROW_RED, 0.5);	
										
									}
									else
									{
										AttachParticle(arrow, EFFECT_CURARROW_BLU, 0.5);	
									}
								}
							}
					
						}
						
						// 弓構えてない
						g_BowHold[client] = -1;
						// デフォルト速度
						TF2_SetPlayerDefaultSpeed(client);
					}
					
					
				}
			}

			// 矢を曲げる
			if(g_Arrow[client] != -1 && IsValidEntity(g_Arrow[client]) )
			{
					
				new String:name[64];
				GetEntityNetClass(g_Arrow[client], name, sizeof(name));
				if(StrEqual(name, "CTFProjectile_Arrow") && GetEntityMoveType(g_Arrow[client]) == MOVETYPE_FLYGRAVITY)
				{
					new Float:arrowPos[3];	// 矢の位置
					new Float:arrowAng[3];	// 矢の角度
					new Float:arrowVec[3];	// 矢の方向
					new Float:arrowNewVec[3];	// 矢の方向
					
					// 矢のデータ読み込み
					GetEntPropVector(g_Arrow[client], Prop_Data, "m_vecAbsOrigin", arrowPos);			// 矢の位置
					GetEntPropVector(g_Arrow[client], Prop_Data, "m_angRotation", arrowAng);			// 矢の角度
					GetEntPropVector(g_Arrow[client], Prop_Data, "m_vecAbsVelocity", arrowVec);			// 矢の方向
					
					// 曲がる角度はチャージ時間に比例
					arrowAng[0] += g_CurvDir[client][0] * 0.5 * g_ChargeTime[client];
					arrowAng[1] += g_CurvDir[client][1] * 0.5 * g_ChargeTime[client];
					
					// 矢の進む方向取得
					GetAngleVectors(arrowAng, arrowNewVec, NULL_VECTOR, NULL_VECTOR);
					
					// 矢はだんだんと落下する
					ScaleVector(arrowNewVec, GetVectorLength(arrowVec));
					arrowNewVec[2] -= 0.9 * (1 / g_ChargeTime[client]);
					
					// データ上書き
					SetEntPropVector(g_Arrow[client], Prop_Data, "m_vecAbsVelocity", arrowNewVec);
					
					// 矢の角度適用
					GetVectorAngles(arrowNewVec, arrowAng);
					SetEntPropVector(g_Arrow[client], Prop_Data, "m_angRotation", arrowAng);
				}
				else
				{
					// 曲がる方向クリア
					g_CurvDir[client][0] = 0.0;
					g_CurvDir[client][1] = 0.0;
					
					// チャージ時間クリア
					g_ChargeTime[client] = 0.0;
					
					// 矢クリア
					g_Arrow[client] = -1;
				}
				
			}
		
		}

	}

}


