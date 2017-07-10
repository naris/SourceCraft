/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.8
// ・仕様を一部変更
// ・sm_rmf_spikeshoes_jump_height_magを追加
// ・sm_rmf_spikeshoes_movespeed_magを追加
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
#include <sdkhooks>

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Spike Shoes"
#define PL_DESC "Spike Shoes"
#define PL_VERSION "0.0.8"
#define PL_TRANSLATION "spikeshoes.phrases"

#define SOUND_JUMP	"ui/item_acquired.wav"
#define SOUND_STOMP	"weapons/cbar_hitbod1.wav"

#define EFFECT_FOOT_RED			"stunballtrail_red"
#define EFFECT_FOOT_BLU			"stunballtrail_blue"
#define EFFECT_SPIKE_ENABLE_RED	"soldierbuff_red_spikes"
#define EFFECT_SPIKE_ENABLE_BLU	"soldierbuff_blue_spikes"

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
new Handle:g_StompHopping 	= INVALID_HANDLE;			// ConVarジャンプ高さ

new String:SOUND_STOMP_VOICE[21][64];					// 踏みつけボイス

new g_HideSandman[MAXPLAYERS+1]		= -1;				// ボール発生用のサンドマン
new g_HideBall[MAXPLAYERS+1]		= -1;				// スタン用の隠しボール
new g_FootEffect[MAXPLAYERS+1][2];						// 足につけるエフェクト
new Handle:g_CheckTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// チェックタイマー
new g_Stomper[MAXPLAYERS+1]			= -1;				// 踏んだ相手

new Handle:g_MoveSpeedMag = INVALID_HANDLE;				// ConVar移動速度倍率
new Handle:g_SecondJumpMag = INVALID_HANDLE;			// ConVar二段目のジャンプ倍率

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
		CreateConVar("sm_rmf_tf_spikeshoes", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_spikeshoes","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_StompHopping	= CreateConVar("sm_rmf_spikeshoes_hopping_power",	"400.0","Stomp hopping power (400.0-1000.0)");
		HookConVarChange( g_StompHopping,	ConVarChange_StompHopping);

		g_MoveSpeedMag	= CreateConVar("sm_rmf_spikeshoes_movement_speed_mag",	"0.9","Movement speed magnification (0.0-10.0)");
		g_SecondJumpMag	= CreateConVar("sm_rmf_spikeshoes_jump_height_mag",		"1.2","Second jump height magnification (0.0-10.0)");
		HookConVarChange( g_MoveSpeedMag,	ConVarChange_Magnification );
		HookConVarChange( g_SecondJumpMag,	ConVarChange_Magnification );

		// ボイスファイル
		SOUND_STOMP_VOICE[0] = "vo/scout_apexofjump01.wav";
		SOUND_STOMP_VOICE[1] = "vo/scout_award08.wav";
		SOUND_STOMP_VOICE[2] = "vo/scout_jeers10.wav";
		SOUND_STOMP_VOICE[3] = "vo/scout_cheers06.wav";
		SOUND_STOMP_VOICE[4] = "vo/scout_triplejump03.wav";
		SOUND_STOMP_VOICE[5] = "vo/scout_beingshotinvincible15.wav";
		SOUND_STOMP_VOICE[6] = "vo/scout_cheers03.wav";
		SOUND_STOMP_VOICE[7] = "vo/scout_jeers02.wav";
		SOUND_STOMP_VOICE[8] = "vo/scout_apexofjump02.wav";
		SOUND_STOMP_VOICE[9] = "vo/scout_beingshotinvincible14.wav";
		SOUND_STOMP_VOICE[10] = "vo/scout_award01.wav";
		SOUND_STOMP_VOICE[11] = "vo/scout_beingshotinvincible19.wav";
		SOUND_STOMP_VOICE[12] = "vo/scout_beingshotinvincible26.wav";
		SOUND_STOMP_VOICE[13] = "vo/scout_triplejump01.wav";
		SOUND_STOMP_VOICE[14] = "vo/scout_beingshotinvincible28.wav";
		SOUND_STOMP_VOICE[15] = "vo/scout_stunballhit14.wav";
		SOUND_STOMP_VOICE[16] = "vo/scout_triplejump02.wav";
		SOUND_STOMP_VOICE[17] = "vo/scout_beingshotinvincible23.wav";
		SOUND_STOMP_VOICE[18] = "vo/scout_battlecry04.wav";
		SOUND_STOMP_VOICE[19] = "vo/scout_cheers01.wav";
		SOUND_STOMP_VOICE[20] = "vo/scout_triplejump04.wav";

		
		// アビリティクラス設定
		CreateConVar("sm_rmf_spikeshoes_class", "1", "Ability class");
		
	}
	
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 隠しサンドマン削除
			DeleteHideSandman(client);
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 隠しサンドマン削除
			DeleteHideSandman(client)
		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheSound( SOUND_STOMP, true );
		PrecacheSound( SOUND_JUMP, true );

		for(new i = 0; i < 21; i++)
		{
			PrecacheSound( SOUND_STOMP_VOICE[i], true );
		}
		
		PrePlayParticle(EFFECT_FOOT_RED);
		PrePlayParticle(EFFECT_FOOT_BLU);
		PrePlayParticle(EFFECT_SPIKE_ENABLE_RED);
		PrePlayParticle(EFFECT_SPIKE_ENABLE_BLU);
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
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Scout)
		{
			//Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_0_SPIKESHOES", client);
			
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:percentage[16];
			
			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_SPIKESHOES", client );
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_SPIKESHOES_ATTRIBUTE_0", client );
			GetPercentageString( GetConVarFloat( g_MoveSpeedMag ), percentage, sizeof( percentage ) )
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_SPIKESHOES_ATTRIBUTE_1", client, percentage );
			GetPercentageString( GetConVarFloat( g_SecondJumpMag ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_SPIKESHOES_ATTRIBUTE_2", client, percentage );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}
		
		// アビリティ有効？
		if( TF2_GetPlayerClass(client) == TFClass_Scout && g_AbilityUnlock[client] )
		{
			new bool:hasSandman = false;
			// サンドマン有効かチェック
			if( g_HideSandman[ client ] != -1 )
			{
				if( IsValidEntity( g_HideSandman[ client ] ) )
				{
					hasSandman = true;
				}
			}
			
			// 有効じゃなかったら生成
			if( !hasSandman )
			{
				// バット生成
				new ent = CreateEntityByName("tf_weapon_bat_wood");
				if( IsValidEntity( ent ) )
				{
					DispatchKeyValue( ent, "targetname", "SpikeShoesBat" );					// 名前設定
					SetEntPropEnt	( ent, Prop_Send, "m_hOwnerEntity",		client);		// 持ち主
					SetEntPropEnt	( ent, Prop_Send, "m_hOuter",			client);					// 持ち主

					g_HideSandman[ client ] = ent;
				}				
			}
		}
		else
		{
			// アビリティ有効じゃないときは削除
			DeleteHideSandman( client );
		}
		
		// チェックタイマークリア
		ClearTimer( g_CheckTimer[client] );
		
		// 踏んだ相手クリア
		g_Stomper[ client ] = -1;
		
	}
	
	// プレイヤースタン
	if(StrEqual(name, EVENT_PLAYER_STUNNED))
	{
		new attacker = GetClientOfUserId( GetEventInt( event, "stunner" ) );
		
		// スタンだったらジャンプ
		if( attacker > 0 )
		{
			if( IsClientInGame( attacker ) && IsPlayerAlive( attacker ) )
			{
				if( TF2_GetPlayerClass( attacker ) == TFClass_Scout && g_AbilityUnlock[ attacker ] )
				{
					new Float:victimPos[3];
					new Float:attackerPos[3];
					GetClientAbsOrigin( client, victimPos );
					GetClientAbsOrigin( attacker, attackerPos );
					
					if( GetVectorDistanceMeter( victimPos, attackerPos) <= 2.0 ) 
					{
						// ちょいと移動
						new Float:pos[3];
						GetClientAbsOrigin(attacker, pos);
						pos[2] += 40.0;

						// 踏みつけたプレイヤージャンプ
						new Float:fVelocity[3];
						GetEntPropVector( attacker, Prop_Data, "m_vecAbsVelocity", fVelocity );
						fVelocity[2] = GetConVarFloat( g_StompHopping );
						SetEntPropVector( attacker, Prop_Data, "m_vecAbsVelocity", fVelocity );
						
						// 腹立つボイス
//						EmitSoundToAll( SOUND_STOMP_VOICE[ GetRandomInt( 0, 20 ) ], attacker, _, _, _, 1.0 );
						
						// 二段ジャンプクリア
						SetEntProp( attacker, Prop_Send, "m_iAirDash", 0 );
						
						// ボール削除
						DeleteHideBall( attacker );
						
						// 踏付サウンド
						StopSound(client, 0, SOUND_STOMP);
						EmitSoundToAll( SOUND_STOMP, client, _, _, SND_CHANGEPITCH, 1.0, 80 );
						
						// スタナー設定
						SetEntPropEnt( client, Prop_Send, "m_hStunner", attacker );
						g_Stomper[ client ] = attacker;
						
						// タイマー
						g_CheckTimer[client] = CreateTimer(0.1, Timer_CheckEnd, client)
					}
				}
			}
		}
	}	
	
	// プレイヤー死亡
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		new attacker		= GetClientOfUserId( GetEventInt( event, "attacker" ) );
		new assister		= GetClientOfUserId( GetEventInt( event, "assister" ) );
		new stun_flags		= GetEventInt( event, "stun_flags" );
		new death_flags		= GetEventInt( event, "death_flags" );
		new weaponid		= GetEventInt( event, "weaponid" );
//		new victim_entindex	= GetEventInt( event, "victim_entindex" );
		new damagebits		= GetEventInt( event, "damagebits" );
		new customkill		= GetEventInt( event, "customkill" );
		new String:weapon[64];
		GetEventString( event, "weapon", weapon, sizeof( weapon ) );
		
		// 踏みつけでの死亡を検出しイベント書き換え
		if( attacker == 0 && ( stun_flags == 10 || stun_flags == 65 ) && weaponid == 0 )
		{
			new Handle:newEvent = CreateEvent( "player_death" );
			if( newEvent != INVALID_HANDLE )
			{
				attacker = g_Stomper[ client ];
				
				SetEventInt( newEvent, "userid", GetClientUserId(client) );
				SetEventInt( newEvent, "attacker", GetClientUserId(attacker) );
				if( assister > 0)
					SetEventInt( newEvent, "assister", GetClientUserId(assister) );				
				SetEventInt( newEvent, "stun_flags", stun_flags );				
				SetEventInt( newEvent, "death_flags", death_flags );				
				SetEventInt( newEvent, "weaponid", weaponid );				
				SetEventInt( newEvent, "victim_entindex", client );				
				SetEventInt( newEvent, "damagebits", damagebits );				
				SetEventInt( newEvent, "customkill", customkill );				
				SetEventString( newEvent, "weapon", "spike_shoes" );
				FireEvent( newEvent );
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// チェック終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_CheckEnd(Handle:timer, any:client)
{
	g_CheckTimer[client] = INVALID_HANDLE;
	g_Stomper[ client ] = -1;
}


/////////////////////////////////////////////////////////////////////
//
// 発動チェック
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		if( TF2_GetPlayerClass(client) == TFClass_Scout && g_AbilityUnlock[client] )
		{
			// スピードを制限
			if( TF2_GetPlayerClassSpeed(client) == 400.0 && GetConVarFloat( g_MoveSpeedMag ) != 1.0 )
			{
				TF2_SetPlayerSpeed(client, 400.0 * GetConVarFloat( g_MoveSpeedMag ) );
			}
			
			// 二段ジャンプで発動
			if( GetEntProp( client, Prop_Send, "m_iAirDash" ) > 0 && g_HideBall[ client ] == -1 )
			{
				if( g_HideSandman[ client ] != -1 )
				{
					if( IsValidEntity( g_HideSandman[ client ] ) ) 
					{
						// とりあえず最初にあるボール消す
						DeleteHideBall( client );
						
						// スタンボールを生成して足にくっつける
						new stunBall =  CreateEntityByName( "tf_projectile_stun_ball" );
						if( IsValidEntity( stunBall ) )
						{
							DispatchKeyValue( stunBall, "targetname", "SpikeShoesBall" );								// 名前設定
							SetEntPropEnt	( stunBall, Prop_Send, "m_hOwnerEntity",		client);					// 持ち主
							SetEntPropEnt	( stunBall, Prop_Send, "m_hLauncher",		g_HideSandman[ client ]);		// 受け皿のバット
							if( GetRandomInt( 0, 10 ) < 8 )
							{
								SetEntProp( stunBall, Prop_Send, "m_bCritical",		false);							// クリティカル
							}
							else
							{
								SetEntProp( stunBall, Prop_Send, "m_bCritical",		true);							// クリティカル
							}
							DispatchSpawn( stunBall );
							g_HideBall[ client ] = stunBall;
							
							new Float:pos[3];
							GetClientAbsOrigin( client, pos );								// クライアントの位置
							pos[2] -= 5.0;
							
							// 足に移動
							TeleportEntity( stunBall, pos, NULL_VECTOR, NULL_VECTOR );					
							SetVariantString( "!activator" );
							AcceptEntityInput( stunBall, "SetParent", client, client, 0 );

							// SDKHook
							SDKHook( stunBall, SDKHook_SetTransmit, Hook_SetTransmit );

							// エフェクト
							if( GetClientTeam( client ) == _:TFTeam_Red )
							{
								g_FootEffect[ client ][ 0 ] = AttachLoopParticleBone( client, EFFECT_FOOT_RED, "foot_L");
								g_FootEffect[ client ][ 1 ] = AttachLoopParticleBone( client, EFFECT_FOOT_RED, "foot_R");
								ShowParticleEntity( client, EFFECT_SPIKE_ENABLE_RED, 0.5 );
							}
							else
							{
								g_FootEffect[ client ][ 0 ] = AttachLoopParticleBone( client, EFFECT_FOOT_BLU, "foot_L");
								g_FootEffect[ client ][ 1 ] = AttachLoopParticleBone( client, EFFECT_FOOT_BLU, "foot_R");
								ShowParticleEntity( client, EFFECT_SPIKE_ENABLE_BLU, 0.5 );
							}
							
							// ボール透明
							SetEntityRenderMode(stunBall, RENDER_TRANSCOLOR);
							SetEntityRenderColor(stunBall, 255, 255, 255, 0);
							
							if( GetConVarFloat( g_SecondJumpMag ) != 1.0 )
							{
								// 二段目のジャンプ力上昇
								new Float:fVelocity[3];
								GetEntPropVector( client, Prop_Data, "m_vecAbsVelocity", fVelocity );
								fVelocity[2] *= GetConVarFloat( g_SecondJumpMag );
								SetEntPropVector( client, Prop_Data, "m_vecAbsVelocity", fVelocity );
							}
							
							// ジャンプサウンド
							StopSound( client, 0, SOUND_JUMP );
							EmitSoundToAll( SOUND_JUMP, client, _, _, SND_CHANGEPITCH, 0.5, 150, _, pos, _, false );
							EmitSoundToAll( SOUND_STOMP_VOICE[ GetRandomInt( 0, 20 ) ], client, _, _, _, 1.0 );
							
						}
					}
				}				
			}
			else if( ( GetEntityFlags( client ) & FL_ONGROUND ) && g_HideBall[ client ] != -1 )
			{
				DeleteHideBall( client );
			}
			
		}
	
	}
}

/////////////////////////////////////////////////////////////////////
//
// 隠しサンドマン削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteHideSandman( any:client )
{
	// 隠しボール削除
	DeleteHideBall( client );

	// チェック
	if( g_HideSandman[ client ] != -1 && g_HideSandman[ client ] != 0 )
	{
		if( IsValidEntity( g_HideSandman[ client ] ) )
		{
			// ターゲット名取得取得
			new String:nameTarget[64];
			GetEntPropString( g_HideSandman[ client ], Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
			
			// 隠しバットなら
			if( StrEqual( nameTarget, "SpikeShoesBat" ) )
			{
				AcceptEntityInput( g_HideSandman[ client ], "Kill" );
			}
		}	
	}
	g_HideSandman[ client ] = -1;
}

/////////////////////////////////////////////////////////////////////
//
// 隠しボール削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteHideBall( any:client )
{
	// チェック
	if( g_HideBall[ client ] != -1 && g_HideBall[ client ] != 0)
	{
		if( IsValidEntity( g_HideBall[ client ] ) )
		{
			// ターゲット名取得取得
			new String:nameTarget[64];
			GetEntPropString( g_HideBall[ client ], Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );
			
			// 足元のボールなら
			if( StrEqual( nameTarget, "SpikeShoesBall" ) )
			{
				AcceptEntityInput( g_HideBall[ client ], "Kill" );
			}
		}	
	}
	g_HideBall[ client ] = -1;
	
	// ついでにエフェクト削除
	for( new i = 0; i < 2; i++ )
	{
		DeleteParticle( g_FootEffect[ client ][ i ] );				
	}
}

/////////////////////////////////////////////////////////////////////
//
// ホッピング
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_StompHopping(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 400.0～1000.0まで
	if (StringToFloat(newValue) < 400.0 || StringToFloat(newValue) > 1000.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 400.0 and 1000.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 倍率
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_MoveSpeedMag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.1～1.0まで
	if (StringToFloat(newValue) < 0.1 || StringToFloat(newValue) > 1.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.1 and 1.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 倍率
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_SecondJumpMag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0～5.0まで
	if (StringToFloat(newValue) < 1.0 || StringToFloat(newValue) > 5.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 5.0");
	}
}


/////////////////////////////////////////////////////////////////////
//
// 一人称での表示非表示
//
/////////////////////////////////////////////////////////////////////
public Action:Hook_SetTransmit( entity, client )
{

	if( TF2_EdictNameEqual( entity, "tf_projectile_stun_ball") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString( entity, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );

		if( StrEqual( nameTarget, "SpikeShoesBall" ) )
		{
		    return Plugin_Handled;
		}
		
	}
    return Plugin_Continue;
}  
