/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.9
// ・sm_rmf_delicioussandvich_heal_amountをsm_rmf_delicioussandvich_add_heal_amountに変更
// ・一部仕様を変更(回復量増大、キル数によって回復量が増加)
// ・1.3.1でコンパイル
// 2009/09/18 - 0.0.7
// ・一部仕様変更(回復量UP、オーバーヒール状態)
// ・sm_rmf_delicioussandvich_heal_amountを追加
// ・sm_rmf_delicioussandvich_heal_magを削除
// ・sm_rmf_delicioussandvich_overhealを削除
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
#define PL_NAME			"Delicious Sandvich"
#define PL_DESC			"Delicious Sandvich"
#define PL_VERSION		"0.0.9"
#define PL_TRANSLATION	"delicioussandvich.phrases"

#define SOUND_END_VOICE	"vo/heavy_sandwichtaunt17.wav"

#define SOUND_KGB_ENABLE "weapons/weapon_crit_charged_on.wav"
#define SOUND_KGB_DISABLE "weapons/weapon_crit_charged_off.wav"
#define SOUND_KGB_HIT_1 "weapons/boxing_gloves_hit_crit1.wav"
#define SOUND_KGB_HIT_2 "weapons/boxing_gloves_hit_crit2.wav"
#define SOUND_KGB_HIT_3 "weapons/boxing_gloves_hit_crit3.wav"

#define EFFECT_EAT_RED	"critgun_weaponmodel_red"
#define EFFECT_EAT_BLU	"critgun_weaponmodel_blu"


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
new Handle:g_TauntTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// 挑発チェックタイマー
new Handle:g_TauntVoiceTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// ボイス用のタイマー
new Handle:g_HealthDreinTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// 体力減らす用のタイマー
new Handle:g_HealingAmount					= INVALID_HANDLE;	// ConVar回復量
new Handle:g_OffTimer[MAXPLAYERS+1] 		= INVALID_HANDLE;   // オフタイマー

new bool:g_NowDelicious[MAXPLAYERS+1]	= false;				// デリシャス中？
new bool:g_NeedDrein[MAXPLAYERS+1]		= false;				// オーバーヒールが必要か？
new bool:g_KGBKill[MAXPLAYERS+1]		= false;				// KGBKill？
new g_KillCout[MAXPLAYERS+1]			= 0;					// キル数
new g_Sandvich[MAXPLAYERS+1]			= -1;					// サンドヴィっち
new g_SandvichEffect[MAXPLAYERS+1]		= -1;					// サンドヴィっちエフェクト
new g_LastHealth[MAXPLAYERS+1]			= 0;					// ヘルス

new String:SOUND_KGB_HIT[3][] = { SOUND_KGB_HIT_1, SOUND_KGB_HIT_2, SOUND_KGB_HIT_3 };

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
		CreateConVar("sm_rmf_tf_delicioussandvich", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_delicioussandvich","1","Delicious Sandvich Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_HealingAmount = CreateConVar("sm_rmf_delicioussandvich_add_heal_amount","45","Add heal amount per 1 second (0-500)");
		HookConVarChange(g_HealingAmount, ConVarChange_Health);

		// エンティティフック
		HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
		
		// 挑発コマンドゲット
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_delicioussandvich_class", "6", "Ability class");
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_EAT_RED);
		PrePlayParticle(EFFECT_EAT_BLU);
		
		PrecacheSound(SOUND_END_VOICE, true);
		
		PrecacheSound(SOUND_KGB_ENABLE, true);
		PrecacheSound(SOUND_KGB_DISABLE, true);
		PrecacheSound(SOUND_KGB_HIT_1, true);
		PrecacheSound(SOUND_KGB_HIT_2, true);
		PrecacheSound(SOUND_KGB_HIT_3, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// エフェクト削除
		DeleteParticle( g_SandvichEffect[ client ] );

		// タイマークリア
		ClearTimer( g_TauntTimer[client] );
		ClearTimer( g_TauntVoiceTimer[client] );
		ClearTimer( g_HealthDreinTimer[client] );
		ClearTimer( g_OffTimer[ client ] );
		
		g_NowDelicious[ client ]= false;
		g_NeedDrein[ client ]	= false;
		g_KGBKill[ client ]		= false;
		g_KillCout[ client ]	= 0;
		g_LastHealth[ client ]	= 0;
		g_Sandvich[ client ]	= -1;
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy )
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_DELICIOUSSANDVICH", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_DELICIOUSSANDVICH_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_DELICIOUSSANDVICH_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_DELICIOUSSANDVICH_ATTRIBUTE_2", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}
		
		StopSound( client, 0, SOUND_KGB_ENABLE );
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
	// プレイヤーダメージ
	if( StrEqual( name, EVENT_PLAYER_DAMAGE ) )
	{
		new health = GetEventInt( event, "health" );
		g_LastHealth[client] = health;
	}
	
	// プレイヤー死亡
	if( StrEqual( name, EVENT_PLAYER_DEATH ) )
	{
		new attacker	= GetClientOfUserId( GetEventInt( event, "attacker" ) );
		new String:weapon[64];
		GetEventString( event, "weapon", weapon, sizeof( weapon ) );
		
		if( attacker > 0 && StrEqual( weapon, "gloves" ) )
		{
			if( IsClientInGame( attacker ) && IsPlayerAlive( attacker ) && g_AbilityUnlock[ attacker ] )
			{
				DeleteParticle( g_SandvichEffect[ attacker ] );
				g_Sandvich[ attacker ] = -1;
				
				if( g_KGBKill[ attacker ] )
				{
					new weaponIndex = GetPlayerWeaponSlot( attacker, 2 );
					EmitSoundToAll( SOUND_KGB_HIT [ GetRandomInt( 0, 2 ) ], attacker, _, _, _, 1.0, _, weaponIndex );
				}
				else
				{
					new weaponIndex = GetPlayerWeaponSlot( attacker, 2 );
					EmitSoundToAll( SOUND_KGB_ENABLE, attacker, _, _, _, 1.0, _, weaponIndex );
				}
			
				ClearTimer( g_OffTimer[ attacker ] );
				g_OffTimer[ attacker ] = CreateTimer( 5.0, Timer_DeliciousEnd, attacker );
				
				g_KGBKill[ attacker ] = true;
				
				// キルカウント増やす
				g_KillCout[ attacker ]  += 1;
				
			}
		}
	}
	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// KGBOff
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DeliciousEnd( Handle:timer, any:client )
{
	DeleteParticle( g_SandvichEffect[ client ] );
	g_Sandvich[ client ]	= -1;
	g_OffTimer[ client ]	= INVALID_HANDLE;
	g_KGBKill[ client ]		= false;
	g_KillCout[ client ]	= 0;
	StopSound( client, 0, SOUND_KGB_ENABLE );
	EmitSoundToAll(SOUND_KGB_DISABLE, client, _, _, _, 1.0);
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
		// ヘビー
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy && g_AbilityUnlock[client] )
		{
			if( TF2_IsPlayerCrits(client) && TF2_IsPlayerTaunt(client) )
			{
				if( CheckElapsedTime(client, 0.01) )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);

					// 攻撃
					if ( GetClientButtons(client) & IN_ATTACK )
					{
						DeliciousSandvich( client );
					}
				}
			}
			
			// 投げたとき
			if( g_KGBKill[ client ] )
			{
				if( CheckElapsedTime(client, 0.1) )
				{

					// 攻撃
					if ( GetClientButtons(client) & IN_ATTACK2 )
					{
						// キーを押した時間を保存
						SaveKeyTime(client);
						
						new sandvich = -1;
						while (( sandvich = FindEntityByClassname( sandvich, "item_healthkit_medium")) != -1)
						{
							//PrintToChat(client, "%d %d",client, GetEntProp(body, Prop_Send, "m_iPlayerIndex"));
							new iOwner = GetEntPropEnt( sandvich, Prop_Send, "m_hOwnerEntity" );
							if( iOwner == client && GetEntPropEnt( sandvich, Prop_Data, "m_hGroundEntity" ) == -1 )
							{
								new Float:pos[3];
								pos[2] = 10.0;
								DeleteParticle( g_SandvichEffect[ client ] );
								if( GetClientTeam( client ) == _:TFTeam_Red )
								{
									g_SandvichEffect[ client ] = AttachParticle( sandvich, "player_intel_trail_red", 25.0, pos );
								}
								else
								{
									g_SandvichEffect[ client ] = AttachParticle( sandvich, "player_intel_trail_blue", 25.0, pos );
								}
								
								// サンドヴィッチを保存
								g_Sandvich[ client ] = sandvich;
							}
						}
					}
				}
			}
		}		
	}
}


/////////////////////////////////////////////////////////////////////
//
// エンティティフック
//
/////////////////////////////////////////////////////////////////////
public Action:Entity_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
	new iOwner = GetEntPropEnt( caller, Prop_Send, "m_hOwnerEntity" );
	if( iOwner != -1 )
	{
		if( g_KGBKill[ iOwner ] && g_Sandvich[ iOwner ] == caller )
		{
			DeleteParticle( g_SandvichEffect[ iOwner ] );
			g_Sandvich[ iOwner ] = -1;
			
			// 体力を最大まで回復
			new Handle:newEvent = CreateEvent( "player_healonhit" );
			if( newEvent != INVALID_HANDLE )
			{
				SetEventInt( newEvent, "amount", TF2_GetPlayerDefaultHealth( activator ) );
				SetEventInt( newEvent, "entindex", activator );
				FireEvent( newEvent );
			}
			
			// 適用
			SetEntityHealth( activator, TF2_GetPlayerDefaultHealth( activator ) );
		}
	}
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
	
	// ヘビーでアビリティONのとき
	if( TF2_GetPlayerClass(client) == TFClass_Heavy && g_AbilityUnlock[client] && !TF2_IsPlayerTaunt(client))
	{
		DeliciousSandvich(client);
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動
//
/////////////////////////////////////////////////////////////////////
public DeliciousSandvich(any:client)
{
		
	// サンドヴィッチのみ
	if(TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_SANDVICH )
	{
		g_LastHealth[client] = GetClientHealth( client );
	
		// 挑発タイマー発動
		ClearTimer( g_TauntTimer[client] );
		g_TauntTimer[client] = CreateTimer(1.0, Timer_TauntEnd, client);
		
		// 挑発ボイスタイマー発動
		ClearTimer( g_TauntVoiceTimer[client] );
		g_TauntVoiceTimer[client] = CreateTimer(3.2, Timer_DeliciousVoice, client);
		
		// オーバーヒール状態設定
		if( TF2_IsPlayerOverHealing( client ) )
		{
			g_NeedDrein[client] = false;
		}
	}	
}

/////////////////////////////////////////////////////////////////////
//
// サンドヴィッチタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntEnd(Handle:timer, any:client)
{
	g_TauntTimer[client] = INVALID_HANDLE;
	
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// クリッツ状態挑発中終了していない
		if(TF2_IsPlayerCrits(client) && TF2_IsPlayerTaunt(client) && g_TauntVoiceTimer[client] != INVALID_HANDLE)
		{
			g_NowDelicious[client] = true;
			
			new String:effect[32];
			if( TFTeam:GetClientTeam(client) == TFTeam_Red)
			{
		    	effect = EFFECT_EAT_RED;
			}
			else
			{
				effect = EFFECT_EAT_BLU;
			}	
			
			new Float:pos[3];
			pos[0]=3.0;
			pos[2]=-10.0;
			AttachParticleBone(client, effect, "head", 0.4, pos);
			
			new nowHealth = GetClientHealth(client);
			
			if( !TF2_IsPlayerOverHealing( client ) )
			{
				g_NeedDrein[client] = true;
				
			}
			
			new Float:mag = (g_KillCout[ client ] - 1) * 0.5 + 1.0;
			new healAmout = RoundFloat( GetConVarInt(g_HealingAmount) * mag )

			new diff = 0;
			if( nowHealth != g_LastHealth[client] + 75 + healAmout )
			{
				diff = (g_LastHealth[client] + 75 + healAmout) - nowHealth - healAmout;
			}
			nowHealth += healAmout + diff;
			
			
			new Handle:newEvent = CreateEvent( "player_healonhit" );
			if( newEvent != INVALID_HANDLE )
			{
				SetEventInt( newEvent, "amount", healAmout + 75 );
				SetEventInt( newEvent, "entindex", client );
				FireEvent( newEvent );
			}

			// 最大ヘルス超えない
			if( nowHealth >= TF2_GetPlayerMaxHealth(client))
			{
				nowHealth = TF2_GetPlayerMaxHealth(client);
			}
			
			// 適用
			SetEntityHealth(client, nowHealth);

			g_LastHealth[client] = nowHealth;
			// 一秒後に設定
			g_TauntTimer[client] = CreateTimer(1.0, Timer_TauntEnd, client);
		}
	}
}
/////////////////////////////////////////////////////////////////////
//
// ボイス用タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DeliciousVoice(Handle:timer, any:client)
{
	g_TauntVoiceTimer[client] = INVALID_HANDLE;
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(TF2_IsPlayerTaunt(client))
		{
			// 発動した後だけ
			if(g_NowDelicious[client])
			{
				EmitSoundToAll(SOUND_END_VOICE, client, _, _, _, 1.0);
				g_NowDelicious[client] = false;
			}		
		}

		if( g_NeedDrein[client] )
		{
			// ヘルスドレイン用のタイマー
			ClearTimer( g_HealthDreinTimer[client] );
			g_HealthDreinTimer[client] = CreateTimer(0.15, Timer_HealthDrein, client, TIMER_REPEAT );
			
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ヘルスドレイン用
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_HealthDrein(Handle:timer, any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// オーバーヒール状態＆回復されていない
		if( TF2_IsPlayerOverHealing( client ) && TF2_GetNumHealers(client) == 0 )
		{
			// 1減らす
			new nowHealth = GetClientHealth(client);
			
			// 通常ヘルス以上ならドレイン
			if( nowHealth > TF2_GetPlayerDefaultHealth(client))
			{
				nowHealth--;
				SetEntityHealth(client, nowHealth);
				return;
			}
		}		
	}

	// 条件満たしてなければ終了
	ClearTimer( g_HealthDreinTimer[client] );
}



