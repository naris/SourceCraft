/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2009/03/01 - 0.0.6
// ・sm_rmf_styptic_use_uberを追加
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
#define PL_NAME "Styptic"
#define PL_DESC "Styptic"
#define PL_VERSION "0.0.6"
#define PL_TRANSLATION "styptic.phrases"

#define EFFECT_HEAL_RED "healthgained_red"
#define EFFECT_HEAL_BLU "healthgained_blu"
#define EFFECT_BACK_RED "critical_rocket_red"
#define EFFECT_BACK_BLU "critical_rocket_blue"

#define SOUND_HEAL_LOOP "weapons/teleporter_spin.wav"
#define SOUND_HEAL_END "weapons/teleporter_ready.wav"
#define SOUND_HEAL_EMPTY "weapons/syringegun_reload_air2.wav"

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
new Handle:g_StypticHealSpeed = INVALID_HANDLE;		// ConVarスティップティック回復速度
new Handle:g_StypticHealRate = INVALID_HANDLE;		// ConVarスティップティック回復レート
new Handle:g_StypticUberAmount = INVALID_HANDLE;	// ConVarスティップティック消費ユーバー
new bool:g_StypticState[MAXPLAYERS+1] = false;		// スティップティックの状態
new g_BackParticle[MAXPLAYERS+1];					// 背中のパーティクルエフェクト

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
		CreateConVar("sm_rmf_tf_styptic", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_styptic","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		// メディック
		g_StypticHealSpeed	= CreateConVar("sm_rmf_styptic_heal_speed",	"0.5",	"heal Speed (0.0-120.0)");
		g_StypticHealRate	= CreateConVar("sm_rmf_styptic_heal_rate",	"10",	"Heal rate (0-500)");
		g_StypticUberAmount	= CreateConVar("sm_rmf_styptic_use_uber",	"3",	"Use ubercharge amount (0-100)");
		HookConVarChange(g_StypticHealSpeed,	ConVarChange_Time);
		HookConVarChange(g_StypticHealRate,		ConVarChange_Health);
		HookConVarChange(g_StypticUberAmount,	ConVarChange_Uber);
		
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_styptic_class", "5", "Ability class");
		
	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBackParticle(i);
		}
	
	}
	
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBackParticle(i);
		}
	}
	
	// マップ開始
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_HEAL_RED);
		PrePlayParticle(EFFECT_HEAL_BLU);
		PrePlayParticle(EFFECT_BACK_RED);
		PrePlayParticle(EFFECT_BACK_BLU);
		
		PrecacheSound(SOUND_HEAL_LOOP, true);
		PrecacheSound(SOUND_HEAL_END, true);
		PrecacheSound(SOUND_HEAL_EMPTY, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// パーティクル削除
		StopStyptic(client);
		
		
		new String:abilityname[256];
		new String:attribute0[256];
		new String:attribute1[256];
		new String:attribute2[256];

		// アビリティ名
		Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_STYPTIC", client );
		// アトリビュート
		Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_STYPTIC_ATTRIBUTE_0", client );
		Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_STYPTIC_ATTRIBUTE_1", client );
		Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_STYPTIC_ATTRIBUTE_2", client, GetConVarInt( g_StypticUberAmount ), GetConVarInt( g_StypticHealRate ) );
		
		// 1ページ目
		Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
		// 2ページ目
		Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
	}

	// プレイヤー死亡
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		StopStyptic(client);
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
// 発動チェック
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// メディックである
		if( TF2_GetPlayerClass( client ) == TFClass_Medic  && g_AbilityUnlock[client])
		{
			if((g_StypticState[client] && CheckElapsedTime(client, GetConVarFloat(g_StypticHealSpeed))) || (!g_StypticState[client] && CheckElapsedTime(client, 1.6)))
			{
				
				// メディガンのみ
				if(TF2_CurrentWeaponEqual(client, "CWeaponMedigun"))
				{
					// 攻撃2
					if ( GetClientButtons(client) & IN_ATTACK2 )
					{
						/*
						new ent = -1;
						while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1)
						{
							// 
							new String:effname[32];
							GetEntPropString(ent, Prop_Data, "m_iszEffectName", effname, sizeof(effname));
							if(StrEqual(effname, "medicgun_beam_blue_trail"))
							{
								new String:attachname[32];
								GetEntPropString(ent, Prop_Data, "m_iszControlPointNames[0]", attachname, sizeof(attachname));
								PrintToChat(client, "%s", effname);
							
								PrintToChat(client, "%s", attachname);
							}
						}							
						*/
						
						if(!TF2_IsPlayerChargeReleased(client))
						{
							new nowUber = TF2_GetPlayerUberLevel(client);
							new nowHealth = GetClientHealth(client);
						
							if( nowUber >= 100 || nowUber <= 0 || nowHealth >= TF2_GetPlayerDefaultHealth(client))
							{
								StopStyptic(client);
							}
							else
							{
								if(!g_StypticState[client])
								{
									// 背中のパーティクル設定
									SetBackParticle(client);
									//EmitSoundToAll(SOUND_TRANSPLANT_START, client, _, _, SND_CHANGEPITCH, 0.6, 200);
									//CreateTimer(0.2, Timer_StartLoopSound, client);
								}
								
								nowUber -= GetConVarInt( g_StypticUberAmount );
								if( nowUber < 0 )
								{
									nowUber = 0;
								}
								else
								{
									nowHealth +=  GetConVarInt(g_StypticHealRate);
								}
								
								if( nowHealth >= TF2_GetPlayerDefaultHealth(client) )
								{
									nowHealth = TF2_GetPlayerDefaultHealth(client);
								}
								
								// ユーバー反映
								TF2_SetPlayerUberLevel(client, nowUber);
								SetEntityHealth(client, nowHealth);

								// 回復表示
								new Handle:newEvent = CreateEvent( "player_healonhit" );
								if( newEvent != INVALID_HANDLE )
								{
									SetEventInt( newEvent, "amount", GetConVarInt(g_StypticHealRate) );
									SetEventInt( newEvent, "entindex", client );
									FireEvent( newEvent );
								}
								
								new Float:ang[3];
								ang[2] = 90.0;
								//AttachParticleBone(client, "teleported_blue", "flag", 1.0, NULL_VECTOR, ang);
								//AttachParticleBone(target, "teleported_blue", "flag", 1.0, NULL_VECTOR, ang);
								
								// サウンドとかエフェクト
								EmitSoundToAll(SOUND_HEAL_LOOP, client, _, _, SND_CHANGEPITCH, 0.70, 60);
													
								new Float:pos[3];
								for(new i = 0; i < GetConVarInt(g_StypticHealRate); i++)
								{
							    	pos[0] = GetRandomFloat(-20.0, 20.0);
							    	pos[1] = GetRandomFloat(-20.0, 20.0);
							    	pos[2] = GetRandomFloat(-30.0, 0.0);
							    	if( TFTeam:GetClientTeam(client) == TFTeam_Red)
							    	{
							    		
										AttachParticleBone(client, EFFECT_HEAL_RED, "head", GetRandomFloat(1.0, 3.0), pos);
							    	}
									else
									{
										AttachParticleBone(client, EFFECT_HEAL_BLU, "head", GetRandomFloat(1.0, 3.0), pos);
									}
								}
								
								// 有効
								g_StypticState[client] = true;
								
							}
						}
						else
						{
							StopStyptic(client);
						}
					}
					else
					{
						StopStyptic(client);
					}
				}
				else
				{
					StopStyptic(client);
				}
				
				// ボタン間隔
				if( g_StypticState[client] )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
										
					// 発動中なら指定間隔
					//g_PlayerButtonDown[client] = CreateTimer(GetConVarFloat(g_TransplantSpeed), Timer_ButtonUp, client);
				}
				else
				{
					StopStyptic(client);
				}
			}
				
			if( !(GetClientButtons(client) & IN_ATTACK2) )
			{
				StopStyptic(client);
			}
		}		
		

	}
}

/////////////////////////////////////////////////////////////////////
//
// 背中のパーティクルセット
//
/////////////////////////////////////////////////////////////////////
public SetBackParticle(any:client)
{

	if( IsClientInGame(client) && GetClientTeam(client) > 1 )
	{
		new Float:pos[3];
		pos[1] = -8.0;

		if(TFTeam:GetClientTeam(client) == TFTeam_Red)
		{
			g_BackParticle[client] = AttachLoopParticleBone(client, EFFECT_BACK_RED, "flag", pos, NULL_VECTOR);
		}
		else
		{
			g_BackParticle[client] = AttachLoopParticleBone(client, EFFECT_BACK_BLU, "flag", pos, NULL_VECTOR);
		}

	}
	else
	{
		DeleteBackParticle(client);
	}
}
/////////////////////////////////////////////////////////////////////
//
// 背中のパーティクル削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteBackParticle(any:client)
{
	if (g_BackParticle[client] > 0)
	{
		if(IsValidEdict(g_BackParticle[client]))
		{
			DeleteParticle( g_BackParticle[client] );
//			ActivateEntity();
//			AcceptEntityInput(g_BackParticle[client], "stop");
//			CreateTimer(0.01, DeleteParticles, g_BackParticle[client]);
//			g_BackParticle[client] = -1;
		}
	}
} 

/////////////////////////////////////////////////////////////////////
//
// 回復終了
//
/////////////////////////////////////////////////////////////////////
stock StopStyptic(any:client)
{
	// 発動してたら
	if(g_StypticState[client])
	{
		StopSound(client, 0, SOUND_HEAL_LOOP);
		//EmitSoundToAll(SOUND_TRANSPLANT_END, client, _, _, SND_CHANGEPITCH, 0.5, 200);
		EmitSoundToAll(SOUND_HEAL_END, client, _, _, SND_CHANGEPITCH, 0.6, 180);
		DeleteBackParticle(client);
	}
	
	// 発動できないサウンド
	if( GetClientButtons(client) & IN_ATTACK2  && g_AbilityUnlock[client] )
	{
		EmitSoundToClient(client, SOUND_HEAL_EMPTY, client, _, _, SND_CHANGEPITCH, 0.5, 100);
	}
	
	g_StypticState[client] = false;
	
/*	if(g_PlayerButtonDown[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerButtonDown[client]);
		g_PlayerButtonDown[client] = INVALID_HANDLE;
	}
	g_PlayerButtonDown[client] = CreateTimer(1.8, Timer_ButtonUp, client);
*/
	// キーを押した時間を保存
	SaveKeyTime(client);
	
}



