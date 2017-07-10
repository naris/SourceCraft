/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.7
// ・1.3.1でコンパイル
// 2009/10/06 - 0.0.6
// ・内部処理を変更
// 2009/09/04 - 0.0.5
// ・アフターバーナーの炎で燃えるようにした
// ・sm_rmf_afterburner_burn_enemyを追加
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
#define PL_NAME "After Burner"
#define PL_DESC "After Burner"
#define PL_VERSION "0.0.7"
#define PL_TRANSLATION "afterburner.phrases"


#define SOUND_BURNER_START "weapons/flame_thrower_airblast.wav"
#define SOUND_BURNER_LOOP "weapons/flame_thrower_loop.wav"
#define SOUND_BURNER_END "weapons/flame_thrower_end.wav"
#define SOUND_BURNER_EMPTY "weapons/syringegun_reload_air2.wav"
#define SOUND_BURNER_VOICE "vo/pyro_laughevil01.wav"

#define EFFECT_BURNER_RED "flamethrower_crit_red"
#define EFFECT_BURNER_BLU "flamethrower_crit_blue"
#define EFFECT_BURNER_EMPTY "muzzle_minigun"
#define EFFECT_BURNER_WARP "pyro_blast_warp"
#define EFFECT_BURNER_WARP2 "pyro_blast_warp2"

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
new Handle:g_BurnerAmmoCount = INVALID_HANDLE;		// 消費弾薬
new Handle:g_BurnerUpMulti = INVALID_HANDLE;		// 上昇倍率
new Handle:g_BurnerFallMulti = INVALID_HANDLE;		// 落下倍率
new Handle:g_BurnEnemy = INVALID_HANDLE;			// 燃えるかどうか
new bool:g_BurnerState[MAXPLAYERS+1] = false;		// バーナーの状態
new g_BurnerParticle[MAXPLAYERS+1] = -1;			// バーナーのエフェクトエンティティ
new g_BurnerCount[MAXPLAYERS+1] = 0;				// バーナーのカウント

new bool:g_FirstJump[MAXPLAYERS+1] = false;			// 初回ジャンプ完了？
new bool:g_ReleaseButton[MAXPLAYERS+1] = false;		// キーはなした？
new bool:g_AlreadyBurnered[MAXPLAYERS+1] = false;		// キーはなした？

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
		CreateConVar("sm_rmf_tf_afterburner", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_afterburner","1","After Burner Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		
		// パイロ
		g_BurnerAmmoCount	= CreateConVar("sm_rmf_afterburner_use_ammo",	"4",	"Ammo required (0-200)");
		g_BurnerUpMulti		= CreateConVar("sm_rmf_afterburner_up_mag",		"1.45",	"Up velocity magnification (0.0-10.0)");
		g_BurnerFallMulti	= CreateConVar("sm_rmf_afterburner_fall_mag",	"0.85",	"Fall velocity magnification (0.0-10.0)");
		g_BurnEnemy			= CreateConVar("sm_rmf_afterburner_burn_enemy",	"1",	"Burn enemy when hit After Burner's flame (0 = disabled | 1 = enabled)");

		HookConVarChange(g_BurnerAmmoCount,	ConVarChange_Ammo);
		HookConVarChange(g_BurnerUpMulti,	ConVarChange_Magnification);
		HookConVarChange(g_BurnerFallMulti,	ConVarChange_Magnification);	
		HookConVarChange(g_BurnEnemy,		ConVarChange_Bool);	
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_afterburner_class", "7", "Ability class");
	}

	
	
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBurnerParticle(i);
		}
	
	}
	
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBurnerParticle(i);
		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBurnerParticle(i);
		}
		
		PrePlayParticle(EFFECT_BURNER_RED);
		PrePlayParticle(EFFECT_BURNER_BLU);
		PrePlayParticle(EFFECT_BURNER_EMPTY);
		PrePlayParticle(EFFECT_BURNER_WARP);
		PrePlayParticle(EFFECT_BURNER_WARP2);
		
		PrecacheSound(SOUND_BURNER_START, true);
		PrecacheSound(SOUND_BURNER_LOOP, true);
		PrecacheSound(SOUND_BURNER_END, true);
		PrecacheSound(SOUND_BURNER_EMPTY, true);
		PrecacheSound(SOUND_BURNER_VOICE, true);
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
		// バーナーOFF
		g_BurnerState[client]=false;
		DeleteBurnerParticle(client);	
		StopSound(client, 0, SOUND_BURNER_LOOP);
		g_FirstJump[client] = false;
		g_ReleaseButton[client] = false;
		g_AlreadyBurnered[client] = false;
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_AFTERBURNER", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_AFTERBURNER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_AFTERBURNER_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_AFTERBURNER_ATTRIBUTE_2", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );

		}
	}
		

	// 切断
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		DeleteBurnerParticle(client);	
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
			if( CheckElapsedTime(client, 0.09) )
			{
				// アフターバーナー
				AfterBurner(client);
			}

		}

	}

}

/////////////////////////////////////////////////////////////////////
//
// パイロアフターバーナー
//
/////////////////////////////////////////////////////////////////////
public AfterBurner(any:client)
{
	// 空中ジャンプ
	if ( GetClientButtons(client) & IN_JUMP)
	{
		// キーを押した時間を保存
		SaveKeyTime(client);
		
		if( !(GetEntityFlags(client) & FL_ONGROUND) )
		{
			// 発動までのカウントON
			g_BurnerCount[client] += 1;
			if( g_FirstJump[client] && g_ReleaseButton[client] )
			{

				//new iWeapon = GetPlayerWeaponSlot(client, 0);//GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
				new offset = FindDataMapOffs(client, "m_iAmmo") + (1 * 4);
				new nowAmmo = GetEntData(client, offset, 4);

				if( !g_BurnerState[client] )
				{
					if( nowAmmo > 0)
					{
						g_BurnerState[client] = true;
						
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						if(fVelocity[2] >= -300.0 && !g_AlreadyBurnered[client])
						{
							fVelocity[2] = 250.0;
							SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						}
						
						StopSound(client, 0, SOUND_BURNER_START);
						EmitSoundToAll(SOUND_BURNER_START, client, _, _, SND_CHANGEPITCH, 0.3, 150);
						CreateTimer(0.02, Timer_StartBurnerLoopSound, client);

						EmptyBurnerEffect(client);
						SetBurnerParticle(client);
						
						// ぼわんエフェクト
						new Float:ang[3];
						ang[0] = -25.0;
						ang[1] = 90.0;
						new Float:pos[3];
						pos[1] = 10.0;
						pos[2] = 1.0;
						
						AttachParticleBone(client, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);	
						AttachParticleBone(client, EFFECT_BURNER_WARP, "flag", 0.15, pos, ang);	
						AttachParticleBone(client, EFFECT_BURNER_WARP2, "flag", 0.15, pos, ang);	
						
						// 弾薬消費
						nowAmmo -= GetConVarInt(g_BurnerAmmoCount);
						if(nowAmmo < 0)
						{
							nowAmmo = 0;
						}
						SetEntData(client, offset, nowAmmo);
					}
					else
					{
						g_BurnerCount[client] = 0;
						g_BurnerState[client] = false;
						DeleteBurnerParticle(client);
						if( !g_AlreadyBurnered[client] )
						{
							StopSound(client, 0, SOUND_BURNER_LOOP);
							StopSound(client, 0, SOUND_BURNER_END);
							StopSound(client, 0, SOUND_BURNER_EMPTY);
							EmitSoundToAll(SOUND_BURNER_END, client, _, _, SND_CHANGEPITCH, 0.3, 120);
							EmitSoundToAll(SOUND_BURNER_EMPTY, client, _, _, SND_CHANGEPITCH, 0.4, 80);
							EmptyBurnerEffect(client);
						}
					}
					g_AlreadyBurnered[client] = true;
					
				}
				else
				{
					if( nowAmmo > 0 && !(GetEntityFlags(client) & FL_INWATER))
					{
						
						// 弾薬消費
						nowAmmo -= GetConVarInt(g_BurnerAmmoCount);
						if(nowAmmo < 0)
						{
							nowAmmo = 0;
						}
						SetEntData(client, offset, nowAmmo);
						
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						if(fVelocity[2] >= 0)
						{
							if(fVelocity[2] < 230.0)
							{
								fVelocity[2] *= GetConVarFloat(g_BurnerUpMulti);//1.18;
							}
						}
						else
						{
							fVelocity[2] *= GetConVarFloat(g_BurnerFallMulti);
						}
						SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						
						
						if(GetConVarBool(g_BurnEnemy))
						{
							// 下にいるやつ燃やす
							new Float:clientPos[3];
							new Float:clientAng[3];
							new Float:targetPos[3];
							new Float:targetAng[3];
							new Float:diffYaw = 0.0;
							// クライアントの位置と角度
							GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", clientPos);
							GetEntPropVector(client, Prop_Data, "m_angRotation", clientAng);
		
							new maxclients = GetMaxClients();
							for (new i = 1; i <= maxclients; i++)
							{
								// 生きてるターゲットのみ
								if(IsClientInGame(i) && IsPlayerAlive(i))
								{
									// チームが違う
									if(client != i && GetClientTeam(client) != GetClientTeam(i))
									{
										// ターゲットの位置
										GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", targetPos);
										// ターゲットへの角度
										SubtractVectors(clientPos, targetPos, targetAng);
										GetVectorAngles(targetAng, targetAng);	
										diffYaw = (targetAng[1] - 180.0) - clientAng[1];
										diffYaw = FloatAbs(diffYaw);	
										
										if( diffYaw >= 120.0 && diffYaw < 165.0 )
										{
											if(CanSeeTarget(client, clientPos, i, targetPos, 5.0, true, false))
											{
												// 燃やす
												TF2_IgnitePlayer(i, client);
											}
										}
									}
									
								}
							}
						}
						
					}
					else
					{
						g_BurnerCount[client] = 0;
						g_BurnerState[client] = false;
						DeleteBurnerParticle(client);
						StopSound(client, 0, SOUND_BURNER_LOOP);
						EmitSoundToAll(SOUND_BURNER_END, client, _, _, SND_CHANGEPITCH, 0.3, 120);
						EmitSoundToAll(SOUND_BURNER_EMPTY, client, _, _, SND_CHANGEPITCH, 0.4, 80);
						EmptyBurnerEffect(client);
					}

				}
			}
							
			g_FirstJump[client] = true;

		}
		else
		{
			g_FirstJump[client] = false;
		}

	}
	else
	{
		if(g_FirstJump[client])
		{
			g_ReleaseButton[client] = true;
		}

	}
	
	if( (GetEntityFlags(client) & FL_ONGROUND) || (GetEntityFlags(client) & FL_INWATER))
	{
		g_FirstJump[client] = false;
		g_ReleaseButton[client] = false;
		g_AlreadyBurnered[client] = false;
	}
	
	if( !(GetClientButtons(client) & IN_JUMP) || GetEntityFlags(client) & FL_ONGROUND )
	{
		g_BurnerCount[client] = 0;

		if( g_BurnerState[client] )
		{
			g_BurnerState[client] = false;
			DeleteBurnerParticle(client);
			StopSound(client, 0, SOUND_BURNER_LOOP);
			EmitSoundToAll(SOUND_BURNER_END, client, _, _, SND_CHANGEPITCH, 0.3, 120);
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// パーティクルセット
//
/////////////////////////////////////////////////////////////////////
public SetBurnerParticle(any:client)
{
	if( client > 0 )
	{
		if( IsClientInGame(client) && GetClientTeam(client) > 1 && TF2_GetPlayerClass( client ) == TFClass_Pyro)
		{	
			new Float:ang[3];
			ang[0] = -25.0;
			ang[1] = 90.0;
			
			if(TFTeam:GetClientTeam(client) == TFTeam_Red)
	    	{
				g_BurnerParticle[client] = AttachLoopParticleBone(client, EFFECT_BURNER_RED, "flag", NULL_VECTOR, ang);
	    	}
			else
			{
				g_BurnerParticle[client] = AttachLoopParticleBone(client, EFFECT_BURNER_BLU, "flag", NULL_VECTOR, ang);
			}
			
		}
		else
		{
	    	DeleteBurnerParticle(client);
		}
	}

}
/////////////////////////////////////////////////////////////////////
//
// パーティクル削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteBurnerParticle(any:client)
{
	if (g_BurnerParticle[client] != -1)
	{
		if(IsValidEdict(g_BurnerParticle[client]))
		{
			DeleteParticle(g_BurnerParticle[client])
			// ActivateEntity(g_BurnerParticle[client]);
			//AcceptEntityInput(g_BurnerParticle[client], "stop");
			//DeleteParticles(0.01, g_BurnerParticle[client]);
			//CreateTimer(0.01, DeleteParticles, g_BurnerParticle[client]);
			g_BurnerParticle[client] = -1;
		}
	}
} 

////////////////////////////////////////
//
// しょぼエフェクト
//
////////////////////////////////////////
public EmptyBurnerEffect(client)
{
	new Float:ang[3];
	ang[0] = -25.0;
	ang[1] = 90.0;
	new Float:pos[3];
	pos[1] = 10.0;
	pos[2] = 1.0;
	
	AttachParticleBone(client, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);	
}
/////////////////////////////////////////////////////////////////////
//
// ループサウンド開始タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_StartBurnerLoopSound(Handle:timer, any:client)
{
	if(g_BurnerState[client])
	{
		EmitSoundToAll(SOUND_BURNER_LOOP, client, _, _, SND_CHANGEPITCH, 0.3, 120);
		
		// ついでにボイス
		EmitSoundToAll(SOUND_BURNER_VOICE, client, _, _, SND_CHANGEPITCH, 0.8, 100);
	}
}
