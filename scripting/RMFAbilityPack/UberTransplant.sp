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
#define PL_NAME "Uber Transplant"
#define PL_DESC "Uber Transplant"
#define PL_VERSION "0.0.5"
#define PL_TRANSLATION "ubertransplant.phrases"

#define SOUND_TRANSPLANT_START "misc/hologram_start.wav"
#define SOUND_TRANSPLANT_LOOP "misc/hologram_move.wav"
#define SOUND_TRANSPLANT_END "misc/hologram_stop.wav"
#define SOUND_TRANSPLANT_EMPTY "ui/projector_screen_down.wav"
#define SOUND_START_VOICE "vo/medic_laughhappy01.wav"
#define SOUND_STOP_VOICE "vo/medic_laughlong01.wav"

#define EFFECT_BEAM_RED_1 "medicgun_beam_attrib_overheal_red"
#define EFFECT_BEAM_BLU_1 "medicgun_beam_attrib_overheal_blue"
#define EFFECT_BEAM_RED_2 "medicgun_beam_red_pluses"
#define EFFECT_BEAM_BLU_2 "medicgun_beam_blue_pluses"
#define EFFECT_BEAM_RED_3 "medicgun_beam_red_trail"
#define EFFECT_BEAM_BLU_3 "medicgun_beam_blue_trail"
#define EFFECT_BEAM_RED_4 "medicgun_beam_red_invulnbright"
#define EFFECT_BEAM_BLU_4 "medicgun_beam_blue_invulnbright"
#define EFFECT_BEAM_RED_5 "medicgun_beam_red_invunglow"
#define EFFECT_BEAM_BLU_5 "medicgun_beam_blue_invunglow"

#define EFFECT_BALL_RED "critical_rocket_red"
#define EFFECT_BALL_BLU "critical_rocket_blue"

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
new Handle:g_TransplantSpeed = INVALID_HANDLE;			// ConVarユーバー移植速度
new Handle:g_TransplantAmount = INVALID_HANDLE;			// ConVarユーバー1%移植するのに必要なユーバー
new bool:g_TransplantState[MAXPLAYERS+1] = false;		// 状態
new g_BackParticle[MAXPLAYERS+1][5];					// 背中のパーティクルエフェクト
new g_HealingTarget[MAXPLAYERS+1] = -1;					// 回復中の味方メディック
new g_BallParticle[MAXPLAYERS+1][2];					// 背中のボールパーティクルエフェクト



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
		CreateConVar("sm_rmf_tf_ubertransplant", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_ubertransplant","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		g_TransplantSpeed	= CreateConVar("sm_rmf_ubertransplant_speed",		"0.1",	"Uber transplant speed (0.0-120.0)");
		g_TransplantAmount	= CreateConVar("sm_rmf_ubertransplant_ubar_amount",	"2",	"Uber transplant amount per 1% (0-100)");
		HookConVarChange(g_TransplantSpeed,		ConVarChange_Time);
		HookConVarChange(g_TransplantAmount,	ConVarChange_Uber);

		
		// アビリティクラス設定
		CreateConVar("sm_rmf_ubertransplant_class", "5", "Ability class");
	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBackParticle(client);
		}	
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBackParticle(client);
		}	
	}	
	
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBackParticle(client);
		}	
		
		PrecacheSound(SOUND_TRANSPLANT_START, true);
		PrecacheSound(SOUND_TRANSPLANT_LOOP, true);
		PrecacheSound(SOUND_TRANSPLANT_END, true);
		PrecacheSound(SOUND_TRANSPLANT_EMPTY, true);
		PrecacheSound(SOUND_START_VOICE, true);
		PrecacheSound(SOUND_STOP_VOICE, true);

		PrePlayParticle(EFFECT_BEAM_RED_1);
		PrePlayParticle(EFFECT_BEAM_BLU_1);
		PrePlayParticle(EFFECT_BEAM_RED_2);
		PrePlayParticle(EFFECT_BEAM_BLU_2);
		PrePlayParticle(EFFECT_BEAM_RED_3);
		PrePlayParticle(EFFECT_BEAM_BLU_3);
		PrePlayParticle(EFFECT_BEAM_RED_4);
		PrePlayParticle(EFFECT_BEAM_BLU_4);
		PrePlayParticle(EFFECT_BEAM_RED_5);
		PrePlayParticle(EFFECT_BEAM_BLU_5);
		PrePlayParticle(EFFECT_BALL_RED);
		PrePlayParticle(EFFECT_BALL_BLU);
		
	}

	// ゲームフレーム
	if(StrEqual(name, EVENT_GAME_FRAME))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			TransplantCheck(i);
		}
	}
	
	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		StopTransplant(client);
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Medic)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_UBERTRANSPLANT", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_UBERTRANSPLANT_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_UBERTRANSPLANT_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_UBERTRANSPLANT_ATTRIBUTE_2", client, GetConVarInt( g_TransplantAmount ) );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}
	}
	
	// プレイヤー死亡
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		StopTransplant(client);
	}

	// プレイヤー切断
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		DeleteBackParticle(client);
	}

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動チェック
//
/////////////////////////////////////////////////////////////////////
stock TransplantCheck(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// メディックである
		if( TF2_GetPlayerClass( client ) == TFClass_Medic  && g_AbilityUnlock[client])
		{
			if((g_TransplantState[client] && CheckElapsedTime(client, GetConVarFloat(g_TransplantSpeed))) || (!g_TransplantState[client] && CheckElapsedTime(client, 1.6)))
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
						
						new target = TF2_GetHealingTarget(client);
						if(target != -1 && !g_TransplantState[target] && TF2_GetPlayerClass( target ) == TFClass_Medic && !TF2_IsPlayerChargeReleased(client))
						{
							g_HealingTarget[client] = target; 
							new nowUber = TF2_GetPlayerUberLevel(client);
							new targetUber = TF2_GetPlayerUberLevel(target);
						
							if( nowUber >= 100 || nowUber <= 0 || targetUber >= 100)
							{
								StopTransplant(client);
							}
							else
							{
								if(!g_TransplantState[client])
								{
									// 背中のパーティクル設定
									SetBackParticle(client);
									EmitSoundToAll(SOUND_TRANSPLANT_START, client, _, _, SND_CHANGEPITCH, 0.6, 200);
									CreateTimer(0.2, Timer_StartLoopSound, client);
								}
								
								nowUber -= GetConVarInt(g_TransplantAmount);
								if( nowUber < 0 )
								{
									nowUber = 0;
								}
								else
								{
									targetUber += 1;
								}
								
								if( targetUber > 100 )
								{
									targetUber = 100;
								}
								
								// ユーバー反映
								TF2_SetPlayerUberLevel(client, nowUber);
								TF2_SetPlayerUberLevel(target, targetUber);
								
								new Float:ang[3];
								ang[2] = 90.0;
								//AttachParticleBone(client, "teleported_blue", "flag", 1.0, NULL_VECTOR, ang);
								//AttachParticleBone(target, "teleported_blue", "flag", 1.0, NULL_VECTOR, ang);
								
								// 有効
								g_TransplantState[client] = true;
								
							}
						}
						else
						{
							StopTransplant(client);
						}
					}
					else
					{
						StopTransplant(client);
					}
				}
				else
				{
					StopTransplant(client);
				}
				
				// ボタン間隔
				if( g_TransplantState[client] )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
										
					// 発動中なら指定間隔
					//g_PlayerButtonDown[client] = CreateTimer(GetConVarFloat(g_TransplantSpeed), Timer_ButtonUp, client);
				}
				else
				{
					StopTransplant(client);
				}
			}
				
			if( !(GetClientButtons(client) & IN_ATTACK2) )
			{
				StopTransplant(client);
			}
		}		
		

	}
}

/////////////////////////////////////////////////////////////////////
//
// ループサウンド開始タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_StartLoopSound(Handle:timer, any:client)
{
	if(g_TransplantState[client])
	{
		EmitSoundToAll(SOUND_START_VOICE, client, _, _, SND_CHANGEPITCH, 0.8, 100);
		EmitSoundToAll(SOUND_TRANSPLANT_LOOP, client, _, _, SND_CHANGEPITCH, 0.4, 200);
	}
	else
	{
		StopSound(client, 0, SOUND_TRANSPLANT_LOOP);
	}
}

/////////////////////////////////////////////////////////////////////
//
// ユーバー移植終了
//
/////////////////////////////////////////////////////////////////////
stock StopTransplant(any:client)
{
	// 発動してたら
	if(g_TransplantState[client])
	{
		StopSound(client, 0, SOUND_TRANSPLANT_LOOP);
		EmitSoundToAll(SOUND_TRANSPLANT_END, client, _, _, SND_CHANGEPITCH, 0.5, 200);
		if(g_HealingTarget[client] > 0 && IsClientInGame(g_HealingTarget[client]) && IsPlayerAlive(g_HealingTarget[client]))
		{
			EmitSoundToAll(SOUND_STOP_VOICE, g_HealingTarget[client], _, _, SND_CHANGEPITCH, 0.8, 100);
		}
		DeleteBackParticle(client);
	}
	
	// 発動できないサウンド
	if( GetClientButtons(client) & IN_ATTACK2  && g_AbilityUnlock[client] )
	{
		EmitSoundToClient(client, SOUND_TRANSPLANT_EMPTY, client, _, _, SND_CHANGEPITCH, 0.5, 150);
	}
	
	g_TransplantState[client] = false;
	
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
	 		g_BallParticle[ client ][0] = AttachLoopParticleBone( TF2_GetHealingTarget( client ) ,	EFFECT_BALL_RED, "flag", pos);
	 		g_BallParticle[ client ][1] = AttachLoopParticleBone( client,							EFFECT_BALL_RED, "flag", pos);
				
			g_BackParticle[client][0] = AttachLoopParticleBone(client, EFFECT_BEAM_RED_1, "flag", pos, NULL_VECTOR);
 			g_BackParticle[client][1] = AttachLoopParticleBone(client, EFFECT_BEAM_RED_2, "flag", pos, NULL_VECTOR);
			g_BackParticle[client][2] = AttachLoopParticleBone(client, EFFECT_BEAM_RED_3, "flag", pos, NULL_VECTOR);
			g_BackParticle[client][3] = AttachLoopParticleBone(client, EFFECT_BEAM_RED_4, "flag", pos, NULL_VECTOR);
			g_BackParticle[client][4] = AttachLoopParticleBone(client, EFFECT_BEAM_RED_5, "flag", pos, NULL_VECTOR);
	   	}
		else
		{
	 		g_BallParticle[ client ][0] = AttachLoopParticleBone( TF2_GetHealingTarget( client ) ,	EFFECT_BALL_BLU, "flag", pos);
	 		g_BallParticle[ client ][1] = AttachLoopParticleBone( client,							EFFECT_BALL_BLU, "flag", pos);

			g_BackParticle[client][0] = AttachLoopParticleBone(client, EFFECT_BEAM_BLU_1, "flag", pos, NULL_VECTOR);
 			g_BackParticle[client][1] = AttachLoopParticleBone(client, EFFECT_BEAM_BLU_2, "flag", pos, NULL_VECTOR);
			g_BackParticle[client][2] = AttachLoopParticleBone(client, EFFECT_BEAM_BLU_3, "flag", pos, NULL_VECTOR);
			g_BackParticle[client][3] = AttachLoopParticleBone(client, EFFECT_BEAM_BLU_4, "flag", pos, NULL_VECTOR);
			g_BackParticle[client][4] = AttachLoopParticleBone(client, EFFECT_BEAM_BLU_5, "flag", pos, NULL_VECTOR);
		}
		for(new i = 0; i < 5; i++)
		{
			if(g_BackParticle[client][i] != -1)
			{
				if (IsValidEdict(g_BackParticle[client][i]))
				{
					//new weapon = GetEntPropEnt(TF2_GetHealingTarget(client), Prop_Send, "m_hActiveWeapon");
					SetEntPropEnt(g_BackParticle[client][i], Prop_Data, "m_hControlPointEnts", g_BallParticle[ client ][0]);
				}
			}
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
	for(new i = 0; i < 5; i++)
	{
		if (g_BackParticle[client][i] > 0)
		{
			if(IsValidEdict(g_BackParticle[client][i]))
			{
				DeleteParticle(g_BackParticle[client][i]);
				g_BackParticle[client][i] = -1;
			}
		}
	}
	for(new i = 0; i < 2; i++)
	{
		if (g_BallParticle[client][i] > 0)
		{
			if(IsValidEdict(g_BallParticle[client][i]))
			{
				DeleteParticle(g_BallParticle[client][i]);
				g_BallParticle[client][i] = -1;
			}
		}
	}
} 

