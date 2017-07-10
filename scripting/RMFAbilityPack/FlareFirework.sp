/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.8
// ・仕様を変更
// ・sm_rmf_flarefirework_flare_speed_magを追加
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
#define PL_NAME "Flare Firework"
#define PL_DESC "Flare Firework"
#define PL_VERSION "0.0.8"
#define PL_TRANSLATION "flarefirework.phrases"


#define SOUND_FIREWORK_EXPLODE1 "weapons/jar_explode.wav"
#define SOUND_FIREWORK_EXPLODE2 "misc/happy_birthday.wav"
#define SOUND_FIREWORK_EXPLODE3 "player/pl_impact_airblast2.wav"

#define EFFECT_FIREWORK "mini_fireworks"
#define EFFECT_FIREWORK_FLARE "mini_firework_flare"
#define EFFECT_FIREWORK_FLASH "teleported_flash"


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
new Handle:g_EffectiveRadius	= INVALID_HANDLE;		// ConVar有効範囲
new Handle:g_ProjectileSpeed	= INVALID_HANDLE;		// ConVar弾速


new Handle:g_FlareCheckTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// フレアチェクタイマー

//new String:g_ShockVoice[9][64];				// ボイスファイル名 9クラス

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
		CreateConVar("sm_rmf_tf_flarefirework", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_flarefirework","1","Flare Firework Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		// CanVar
		g_EffectiveRadius = CreateConVar("sm_rmf_flarefirework_radius",				"2.5", "Effective radius[meter] (0.0-100.0)");
		g_ProjectileSpeed = CreateConVar("sm_rmf_flarefirework_flare_speed_mag",	"0.5", "Flare speed magnification (0.0-10.0)");
		HookConVarChange(g_EffectiveRadius, ConVarChange_Radius);
		HookConVarChange(g_ProjectileSpeed, ConVarChange_Magnification);
		
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_flarefirework_class", "7", "Ability class");

		// ボイスファイル
//		g_ShockVoice[_:TFClass_Scout - 1] = "vo/scout_painsharp01.wav"
//		g_ShockVoice[_:TFClass_Sniper - 1] = "vo/sniper_painsharp01.wav"
//		g_ShockVoice[_:TFClass_Soldier - 1] = "vo/soldier_painsharp01.wav"
//		g_ShockVoice[_:TFClass_DemoMan - 1] = "vo/demoman_painsharp02.wav"
//		g_ShockVoice[_:TFClass_Medic - 1] = "vo/medic_painsharp08.wav"
//		g_ShockVoice[_:TFClass_Heavy - 1] = "vo/heavy_painsharp02.wav"
//		g_ShockVoice[_:TFClass_Pyro - 1] = "vo/pyro_painsharp03.wav"
//		g_ShockVoice[_:TFClass_Spy - 1] = "vo/spy_painsharp03.wav"
//		g_ShockVoice[_:TFClass_Engineer - 1] = "vo/engineer_painsharp02.wav"
	
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
		
		PrePlayParticle(EFFECT_FIREWORK_FLARE);
		PrePlayParticle(EFFECT_FIREWORK);
		PrePlayParticle(EFFECT_FIREWORK_FLASH);
		PrecacheSound(SOUND_FIREWORK_EXPLODE1, true);
		PrecacheSound(SOUND_FIREWORK_EXPLODE2, true);
		PrecacheSound(SOUND_FIREWORK_EXPLODE3, true);
		
//		// ボイス読み込み
//		for(new i = 0; i < 9; i++)
//		{
//			PrecacheSound(g_ShockVoice[i], true);
//		}		
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
		// タイマークリア
		ClearTimer( g_FlareCheckTimer[ client ] );
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro)
		{
			
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:percentage[16];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_FLAREFIREWORK", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_FLAREFIREWORK_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_FLAREFIREWORK_ATTRIBUTE_1", client );
			
			GetPercentageString( GetConVarFloat( g_ProjectileSpeed ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_FLAREFIREWORK_ATTRIBUTE_2", client, percentage );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
			
	
			
			//Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_0_FLAREFIREWORK", client);
			//Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_FLAREFIREWORK", client, RoundFloat(FloatAbs(GetConVarFloat(g_ProjectileSpeed) * 100.0 - 100.0)));
		}
	}
		

	// 切断
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
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
		// パイロ
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro && g_AbilityUnlock[client])
		{
			if( CheckElapsedTime(client, 0.1) )
			{
				FlareFirework(client);
			}
		}

	}

}


/////////////////////////////////////////////////////////////////////
//
// フレアガン花火
//
/////////////////////////////////////////////////////////////////////
public FlareFirework(any:client)
{
	// 攻撃2
	if ( GetClientButtons(client) & IN_ATTACK2 )
	{
		// フレアガンのみ
		if(TF2_CurrentWeaponEqual(client, "CTFFlareGun"))
		{
			// キーを押した時間を保存
			SaveKeyTime(client);
			
			new ent = -1;
			new flare = -1;
			while ((ent = FindEntityByClassname(ent, "tf_projectile_flare")) != -1)
			{
				new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
				if(iOwner == client)
				{
					flare = ent;
				}
			}
			
			if(flare != -1)
			{
				ShowParticleEntity(flare, EFFECT_FIREWORK_FLARE, 0.1);
				ShowParticleEntity(flare, EFFECT_FIREWORK_FLASH, 0.1);

				new Float:pos[3];
				pos[2] = -10.0;
				
				new Float:ang[3];
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos);
				ang[0] = 90.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 180.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 270.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 90.0;
				ang[1] = 90.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 90.0;
				ang[1] = 270.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);

				//AttachParticle(flare, EFFECT_FIREWORK_DEBRIS, 0.1);
				//AttachParticle(flare, EFFECT_FIREWORK_SMOKE, 0.1);
				StopSound(flare, 0, SOUND_FIREWORK_EXPLODE2);
				EmitSoundToAll(SOUND_FIREWORK_EXPLODE1, flare, _, _, SND_CHANGEPITCH, 1.0, 80);
				EmitSoundToAll(SOUND_FIREWORK_EXPLODE2, flare, _, _, SND_CHANGEPITCH, 1.0, 100);
				EmitSoundToAll(SOUND_FIREWORK_EXPLODE3, flare, _, _, SND_CHANGEPITCH, 1.0, 150);
				
				//if(GetEntProp(flare, Prop_Send, "m_bCritical") == 1)
				//{

				//}
				
				//ShowParticle(pos, EFFECT_FIREWORK_ADDFLAME, 5.0);
				
				new Float:fFlarePos[3];
				new Float:fVictimPos[3];
//				new Float:fKnockVelocity[3];	// 爆発の反動

				new maxclients = GetMaxClients();
				// 被害チェック
				for (new victim = 1; victim <= maxclients; victim++)
				{
					if( IsClientInGame(victim) && IsPlayerAlive(victim) )
					{
						// 喰らうのは敵と自分
						if( GetClientTeam(victim) != GetClientTeam(client) )
						{
							// フレアの位置
							GetEntPropVector(flare, Prop_Data, "m_vecOrigin", fFlarePos);
							// 被害者位置
							GetClientAbsOrigin(victim, fVictimPos);
							
							if(CanSeeTarget( flare, fFlarePos, victim, fVictimPos, GetConVarFloat(g_EffectiveRadius), true, false))
							{
								// 燃やす
								TF2_IgnitePlayer(victim, client);
								
//								// 反動の方向取得
//								SubtractVectors(fFlarePos, fVictimPos, fKnockVelocity);
//								NormalizeVector(fKnockVelocity, fKnockVelocity); 
//
//								// 被害者のベクトル方向を取得
//								new Float:fVelocity[3];
//								//GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
//								if( GetEntityFlags(victim) & FL_ONGROUND )
//								{
//									fVelocity[2] = 280.0;
//								}
//								
//								// 反動を算出
//								//ScaleVector(fKnockVelocity, -100.0); 
//								
//								// ボイス再生
//								EmitSoundToAll(g_ShockVoice[_:TF2_GetPlayerClass( victim ) -1], victim, _, _, SND_CHANGEPITCH, 1.0, 100);
//								
//								//AddVectors(fVelocity, fKnockVelocity, fVelocity);
//								
//								// プレイヤーへの反動を設定
//								SetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
								
							}
						}
					}
				}
				
				AcceptEntityInput( flare, "Kill" );
			}
		}
	}
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

	// パイロで有効の時
	if( TF2_GetPlayerClass(client) == TFClass_Pyro && g_AbilityUnlock[client] )
	{
		// フレアガン
		if( StrEqual( weaponname, "tf_weapon_flaregun") )
		{
			// チェック
			ClearTimer( g_FlareCheckTimer[client] );
			g_FlareCheckTimer[client] = CreateTimer( 0.05, Timer_FlareCheck, client );
		}
		
	}
	

	return Plugin_Continue;	
}

/////////////////////////////////////////////////////////////////////
//
// フレアガンチェック
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FlareCheck(Handle:timer, any:client)
{
	g_FlareCheckTimer[client] = INVALID_HANDLE;
	
	// 遅する
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_projectile_flare")) != -1)
	{
		new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(iOwner == client)
		{
			new Float:vec[ 3 ];
			new Float:speed;
			
			// ベクトル取得
			GetEntPropVector( ent, Prop_Data, "m_vecAbsVelocity", vec );

			// 速度取得
			speed = GetVectorLength( vec );
			
			if( speed > 2000 * GetConVarFloat( g_ProjectileSpeed )  )
			{
				speed *= GetConVarFloat( g_ProjectileSpeed );
				
				NormalizeVector( vec, vec );
				
				// ベクトルを上書き
				ScaleVector( vec, speed );
				SetEntPropVector( ent, Prop_Data, "m_vecAbsVelocity", vec );
				
			}
		}
	}	
}
