/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
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
#define PL_NAME "Jump Boots"
#define PL_DESC "Jump Boots"
#define PL_VERSION "0.0.4"
#define PL_TRANSLATION "jumpboots.phrases"

#define EFFECT_WARP "pyro_blast_warp"
#define EFFECT_WARP2 "pyro_blast_warp2"

#define SOUND_BOOTS "player/medic_charged_death.wav"

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
new Handle:g_SpeedMag = INVALID_HANDLE;						// ConVarダッシュ時間
new Handle:g_DamageMag = INVALID_HANDLE;					// ConVarダメージ倍率

new g_NowHealth[MAXPLAYERS+1] = 0; 							// 現在のヘルス

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
		CreateConVar("sm_rmf_tf_jumpboots", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_jumpboots","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_SpeedMag = CreateConVar("sm_rmf_jumpboots_speed_mag","0.8","Speed magnification (0.1-1.0)");
		g_DamageMag = CreateConVar("sm_rmf_jumpboots_damage_mag","0.4","Damage magnification (0.1-1.0)");
		HookConVarChange(g_SpeedMag, ConVarChange_SpeedMag);
		HookConVarChange(g_DamageMag, ConVarChange_DashMag);

		// アビリティクラス設定
		CreateConVar("sm_rmf_jumpboots_class", "3", "Ability class");
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_WARP);
		PrePlayParticle(EFFECT_WARP2);
		
		PrecacheSound(SOUND_BOOTS, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// デフォルトスピード
		TF2_SetPlayerDefaultSpeed(client);
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier)
		{
			Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_0_JUMPBOOTS", client);
			if(GetConVarFloat(g_SpeedMag) != 1.0)
			{
				Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_JUMPBOOTS", client, RoundFloat(FloatAbs(GetConVarFloat(g_SpeedMag) * 100.0 - 100.0)));
			}
		}
		
		g_NowHealth[client] = GetClientHealth(client);
	}

	// プレイヤーダメージ
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client] )
		{
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			if(client == attacker)
			{
				// 下向いてたらロケジャン
				new Float:eang[3];
				GetClientEyeAngles(client, eang);
				
				if(eang[0] >= 30.0 && GetClientButtons(client) & IN_JUMP )
				{
					//PrintToChat(client, "%f, %f", ang[0], ang[1]);
					new damage = g_NowHealth[client] - GetEventInt(event, "health");
					SetEntityHealth(client, g_NowHealth[client] - RoundFloat(damage * GetConVarFloat(g_DamageMag)));
					
					StopSound(client, 0, SOUND_BOOTS);
					EmitSoundToAll(SOUND_BOOTS, client, _, _, SND_CHANGEPITCH, 1.0, 60);
					
					new Float:ang[3];
					ang[0] = 90.0;
					ShowParticleEntity(client, EFFECT_WARP, 0.15, NULL_VECTOR, ang);	
					ShowParticleEntity(client, EFFECT_WARP2, 0.15, NULL_VECTOR, ang);
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
// フレームごとの動作
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// ソルジャー
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client])
		{
			// ヘルス保存
			g_NowHealth[client] = GetClientHealth(client);
			
			// 足の速さダウン
			TF2_SetPlayerSpeed(client, TF2_GetPlayerClassSpeed(client) * GetConVarFloat(g_SpeedMag));
			/*
			if( CheckElapsedTime(client, 0.1) )
			{
				if(GetClientButtons(client) & IN_JUMP)
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
					
					new Float:ang[3];
					ang[0] = 90.0;
					AttachParticle(client, EFFECT_WARP, 0.15, NULL_VECTOR, ang);	
					AttachParticle(client, EFFECT_WARP2, 0.15, NULL_VECTOR, ang);
					
				}
			}*/
		}	
	}
	
}



/////////////////////////////////////////////////////////////////////
//
// スピード倍率
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_SpeedMag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0～10.0まで
	if (StringToFloat(newValue) < 0.1 || StringToFloat(newValue) > 1.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.1 and 1.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// ダメージ倍率
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DashMag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.1～5.0まで
	if (StringToFloat(newValue) < 0.1 || StringToFloat(newValue) > 5.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.1 and 5.0");
	}
}