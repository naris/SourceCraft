/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.6
// ・エフェクトなどを追加
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
#define PL_NAME "Sticky Flash"
#define PL_DESC "Sticky Flash"
#define PL_VERSION "0.0.6"
#define PL_TRANSLATION "stickyflash.phrases"

#define SOUND_BOMB_BANG "player/medic_charged_death.wav"
#define SOUND_BOMB_BANG2 "player/pl_impact_airblast2.wav"
#define SOUND_BOMB_SIGNAL "weapons/stickybomblauncher_det.wav"

#define EFFECT_EXPLODE_SMOKE "Explosions_MA_Smoke_1"
#define EFFECT_EXPLODE_DEBRIS "Explosions_MA_Debris001"
#define EFFECT_EXPLODE_FLASH "teleported_flash"
#define EFFECT_PUSE_RED "stickybomb_pulse_red"
#define EFFECT_PUSE_BLU "stickybomb_pulse_blue"

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
new Handle:g_BlindTime = INVALID_HANDLE;						// ConVar目が眩む時間ベース
new Handle:g_BlindTimeNormalAdd = INVALID_HANDLE;				// ConVar目が眩む時間追加
new Handle:g_BlindTimeCriticalAdd = INVALID_HANDLE;				// ConVarクリティカル時の目が眩む時間

new Handle:g_TauntTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// 挑発チェックタイマー
new Handle:g_FlashTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// フラッシュ終了タイマー
new Handle:g_SoundTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// サウンド発動タイマー

new g_FlashPower[MAXPLAYERS+1] = 0;		// フラッシュパワー

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
		CreateConVar("sm_rmf_tf_stickyflash", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_stickyflash","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_BlindTime				= CreateConVar("sm_rmf_stickyflash_base_blindtime",		"2.0","Base blind time (0.0-120.0)");
		g_BlindTimeNormalAdd	= CreateConVar("sm_rmf_stickyflash_blindtime_add",		"2.0","Add blind time (0.0-120.0)");
		g_BlindTimeCriticalAdd	= CreateConVar("sm_rmf_stickyflash_blindtime_add_crits","4.0","Add blind time critical(0.0-120.0)");
		HookConVarChange(g_BlindTime,				ConVarChange_Time);
		HookConVarChange(g_BlindTimeNormalAdd,		ConVarChange_Time);
		HookConVarChange(g_BlindTimeCriticalAdd,	ConVarChange_Time);

		// 挑発コマンドゲット
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_stickyflash_class", "4", "Ability class");
		
	}
	
	// マップ開始
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_EXPLODE_SMOKE);
		PrePlayParticle(EFFECT_EXPLODE_DEBRIS);
		PrePlayParticle(EFFECT_EXPLODE_FLASH);
		
		PrecacheSound(SOUND_BOMB_BANG, true);
		PrecacheSound(SOUND_BOMB_BANG2, true);
		PrecacheSound(SOUND_BOMB_SIGNAL, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		ClearTimer(g_TauntTimer[client]);
		ClearTimer(g_FlashTimer[client]);
		ClearTimer(g_SoundTimer[client]);
		
		g_FlashPower[client] = 0;
		
		ScreenFade(client, 255, 255, 255, 0, 0, 0);

		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_DemoMan)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_STICKYFLASH", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_STICKYFLASH_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_STICKYFLASH_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_STICKYFLASH_ATTRIBUTE_2", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}

	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 挑発コマンド取得
//
/////////////////////////////////////////////////////////////////////
public Action:Command_Taunt(client, args)
{
	// MODがONの時だけ
	if( !g_IsRunning || client <= 0 )
		return Plugin_Continue;
	
	
	if(TF2_GetPlayerClass(client) == TFClass_DemoMan && g_AbilityUnlock[client])
	{
		if( !TF2_IsPlayerTaunt(client) && GetEntityFlags(client) & FL_ONGROUND )
		{
			StickyFlash(client);
		}
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動
//
/////////////////////////////////////////////////////////////////////
public StickyFlash(any:client)
{
	// グレネードランチャーのみ
	if(TF2_CurrentWeaponEqual(client, "CTFGrenadeLauncher"))
	{
		ClearTimer(g_TauntTimer[client]);
		g_TauntTimer[client] = CreateTimer(2.0, Timer_TauntEnd, client);

		ClearTimer(g_SoundTimer[client]);
		g_SoundTimer[client] = CreateTimer(1.5, Timer_Sound, client);
	}	
}
/////////////////////////////////////////////////////////////////////
//
// サウンド終了タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_Sound(Handle:timer, any:client)
{
	g_SoundTimer[client] = INVALID_HANDLE;
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if( TF2_IsPlayerTaunt(client) )
		{
			// 撒かれている粘着を取得
			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_projectile_pipe_remote")) != -1)
			{
				// 粘着のオーナー
				new iOwner = GetEntDataEnt2(ent, FindSendPropInfo("CTFGrenadePipebombProjectile", "m_hThrower"));
				if(iOwner == client)
				{
					if(IsValidEntity(ent))
					{
						if( GetClientTeam(client) == _:TFTeam_Red )
						{
							ShowParticleEntity(ent, EFFECT_PUSE_RED, 0.5);
							
						}
						else
						{
							ShowParticleEntity(ent, EFFECT_PUSE_BLU, 0.5);
						}
						EmitSoundToAll(SOUND_BOMB_SIGNAL, ent, _, _, SND_CHANGEPITCH, 1.0, 80);
					}		
				}
			}		
		
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// 挑発終了タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntEnd(Handle:timer, any:client)
{
	g_TauntTimer[client] = INVALID_HANDLE;
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if( TF2_IsPlayerTaunt(client) )
		{
			// フラッシュ発生
			SpawnFlash(client);
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// フラッシュ発生
//
/////////////////////////////////////////////////////////////////////
stock SpawnFlash(client)
{
	// 粘着捜索
	new ent = -1;
	new count = 0;
	new bomb[14];

	// とりあえずクリア
	for( new i = 0; i < 14; i++)
	{
		bomb[i] = -1;
	}
	
	// 撒かれている粘着を取得
	while ((ent = FindEntityByClassname(ent, "tf_projectile_pipe_remote")) != -1)
	{
		// 粘着のオーナー
		new iOwner = GetEntDataEnt2(ent, FindSendPropInfo("CTFGrenadePipebombProjectile", "m_hThrower"));
		if(iOwner == client)
		{
			if(IsValidEntity(ent))
			{
				bomb[count] = ent;
				count++;
			}		
		}
	}
	
	new Float:fBombPos[3];
	new Float:fVictimPos[3];
	new Float:dist;
	new maxclients = GetMaxClients();

	// 被害チェック
	for (new victim = 1; victim <= maxclients; victim++)
	{
		if( IsClientInGame(victim) && IsPlayerAlive(victim) )
		{
			// 喰らうのは敵と自分
			if( GetClientTeam(victim) != GetClientTeam(client) || victim == client )
			{
				new blindPower = 0;
				new Float:blindTime = GetConVarFloat(g_BlindTime);
				new Float:bonusTime = 0.0;

				// 撒かれている粘着分チェック
				for( new i = 0; i < 14; i++)
				{
					if(IsValidEntity(bomb[i]))
					{
						// ボム位置
						GetEntPropVector(bomb[i], Prop_Data, "m_vecOrigin", fBombPos);
						// 被害者位置
						GetEntPropVector(victim, Prop_Data, "m_vecOrigin", fVictimPos);
						// ボムと被害者の位置
						dist = GetVectorDistanceMeter(fBombPos, fVictimPos);
						new Float:eyePos[3];		// 被害者の視点位置
						// 目の位置取得
						GetClientEyePosition(victim, eyePos); 

						if(CanSeeTarget(victim, eyePos, bomb[i], fBombPos, 10.0, true, false))
						{
							new Float:eyeAngles[3];		// 被害者の視点角度
							new Float:bombAngles[3];	// 粘着への方向
							new Float:diffYaw = 0.0;	// 視線と粘着方向への差
							new power = 0;				// 光のパワー
							
							// 目線を取得
							GetClientEyeAngles(victim, eyeAngles);
							// 粘着への角度
							SubtractVectors(eyePos, fBombPos, bombAngles);
							GetVectorAngles(bombAngles, bombAngles);
							diffYaw = (bombAngles[1] - 180.0) - eyeAngles[1];
							diffYaw = FloatAbs(diffYaw);
							
							// 粘着への向きによって低減
							if(diffYaw < 45.0)
							{
								power = 255;
							}
							else if( diffYaw >= 45.0 && diffYaw < 90.0 )
							{
								power = 128;
							}
							else if( diffYaw >= 90.0 && diffYaw < 135.0 )
							{
								power = 64;
							}
							else
							{
								power = 32;
							}

							// 距離によっても低減
							if(dist < 4.0)
							{
								power = RoundFloat(power * 1.0);
							}
							else if( dist >= 4.0 && dist < 6.0 )
							{
								power = RoundFloat(power * 1.0);
							}
							else if( dist >= 6.0 && dist < 8.0 )
							{
								power = RoundFloat(power * 0.4);
							}
							else
							{
								power = RoundFloat(power * 0.2);
							}

							// 合計値
							blindPower += power;
							// 超えたら最大値
							if(blindPower > 255)
							{
								blindPower = 255;
							}
							
							// 持続時間
							if(GetEntProp(bomb[i], Prop_Send, "m_bCritical") == 1)
							{
								bonusTime += GetConVarFloat(g_BlindTimeCriticalAdd) * (1 / dist);
							}				
							else
							{
								blindTime += GetConVarFloat(g_BlindTimeNormalAdd) * (1 / dist);
							}							
						}
					}
				}
				
				// 最終的な目眩み
				g_FlashPower[victim] = blindPower;
				// 効果適用
				ScreenFade(victim, 255, 255, 255, g_FlashPower[victim], 1000000, IN);
				
				// 復帰タイマー
				ClearTimer(g_FlashTimer[victim]);
				g_FlashTimer[victim] = CreateTimer(blindTime + bonusTime, Timer_FadeEnd, victim);
			}
		}
	}

	// 粘着消去
	for( new i = 0; i < 14; i++)
	{
		if(IsValidEntity(bomb[i]))
		{
			SetEntPropVector(bomb[i], Prop_Send, "m_angRotation", NULL_VECTOR);
			ShowParticleEntity(bomb[i], EFFECT_EXPLODE_SMOKE, 0.5);
			ShowParticleEntity(bomb[i], EFFECT_EXPLODE_DEBRIS, 0.5);
			ShowParticleEntity(bomb[i], EFFECT_EXPLODE_FLASH, 0.5);

			EmitSoundToAll(SOUND_BOMB_BANG, bomb[i], _, _, SND_CHANGEPITCH, 1.0, 200);
			EmitSoundToAll(SOUND_BOMB_BANG2, bomb[i], _, _, SND_CHANGEPITCH, 1.0, 120);
			AcceptEntityInput(bomb[i], "Kill");
		}
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// フェードアウト
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FadeEnd(Handle:timer, any:client)
{
	g_FlashTimer[client] = INVALID_HANDLE;

	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		ScreenFade(client, 255, 255, 255, g_FlashPower[client], 0, IN);
	}
	g_FlashPower[client] = 0;
}


