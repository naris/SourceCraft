/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.6
// 一部仕様を変更
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
#define PL_NAME "Metal Hopper"
#define PL_DESC "Metal Hopper"
#define PL_VERSION "0.0.6"
#define PL_TRANSLATION "metalhopper.phrases"

#define SOUND_HOP_VOICE "vo/engineer_battlecry06.wav"

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
new Handle:g_BaseDamage = INVALID_HANDLE;					// ConVarベースダメージ
new Handle:g_BasePower = INVALID_HANDLE;					// ConVarベースパワー
//new Handle:g_IsEnemyDamage = INVALID_HANDLE;				// ConVar敵にダメージ？
//new Handle:g_EnemyBaseDamage = INVALID_HANDLE;				// ConVarベースダメージ(敵)
//new Handle:g_EnemyBasePower = INVALID_HANDLE;				// ConVarベースパワー(敵)
//new Handle:g_EnemyDamageRadius = INVALID_HANDLE;			// ConVarダメージ半径
//new g_AttackerDispenser[MAXPLAYERS+1]	= -1;				// 爆破を受けたディスペンサーの持ち主

new bool:g_Hop[MAXPLAYERS+1] = false;						// ホップした？

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
		CreateConVar("sm_rmf_tf_metalhopper", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_metalhopper","1","Metal Hopper Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		// ダメージとパワー
		g_BaseDamage		= CreateConVar("sm_rmf_metalhopper_base_damage",		"35",	"Base damage(0-1000)");
		g_BasePower			= CreateConVar("sm_rmf_metalhopper_base_power",			"300.0","Base power(10.0-5000.0)");
//		g_IsEnemyDamage		= CreateConVar("sm_rmf_metalhopper_allow_damage",		"1",	"Damage to enemy Enable/Disable (0 = disabled | 1 = enabled)");
//		g_EnemyBaseDamage	= CreateConVar("sm_rmf_metalhopper_enemy_base_damage",	"20",	"Base damage to enemy(0-100)");
//		g_EnemyBasePower	= CreateConVar("sm_rmf_metalhopper_enemy_base_power",	"100.0","Base power to enemy(10.0-5000.0)");
//		g_EnemyDamageRadius	= CreateConVar("sm_rmf_metalhopper_enemy_damage_radius","2.0",	"Damage radius to enemy(0.0-100.0)");
		HookConVarChange(g_BaseDamage,			ConVarChange_Damage);
		HookConVarChange(g_BasePower,			ConVarChange_BasePower);
//		HookConVarChange(g_IsEnemyDamage,		ConVarChange_Bool);
//		HookConVarChange(g_EnemyBaseDamage, 	ConVarChange_Damage);
//		HookConVarChange(g_EnemyBasePower,		ConVarChange_BasePower);
//		HookConVarChange(g_EnemyDamageRadius,	ConVarChange_Radiuss);
		
		// デストロイコマンドゲット
		RegConsoleCmd("destroy", Command_Destroy, "Destroy");
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_metalhopper_class", "9", "Ability class");
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheSound(SOUND_HOP_VOICE, true);
	}

	// プレイヤーリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
//		g_AttackerDispenser[ client ] = -1;
		g_Hop[ client ] = false;
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_METALHOPPER", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_METALHOPPER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_METALHOPPER_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_METALHOPPER_ATTRIBUTE_2", client );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
			
//			if( GetConVarBool( g_IsEnemyDamage ) )
//			{
//				Format(g_PlayerHintText[client][2], HintTextMaxSize , "%T", "DESCRIPTION_2_METALHOPPER", client);
//
//			}
		}
	}
	
	// プレイヤー死亡
//	if(StrEqual(name, EVENT_PLAYER_DEATH))
//	{
//		new attacker		= GetClientOfUserId( GetEventInt( event, "attacker" ) );
//		new assister		= GetClientOfUserId( GetEventInt( event, "assister" ) );
//		new stun_flags		= GetEventInt( event, "stun_flags" );
//		new death_flags		= GetEventInt( event, "death_flags" );
//		new weaponid		= GetEventInt( event, "weaponid" );
//		new victim_entindex	= GetEventInt( event, "victim_entindex" );
//		new damagebits		= GetEventInt( event, "damagebits" );
//		new customkill		= GetEventInt( event, "customkill" );
//		new String:weapon[64];
//		GetEventString( event, "weapon", weapon, sizeof( weapon ) );
//
//		// イベント書き換え
//		if( attacker == client && g_AttackerDispenser[ client ] != -1 )
//		{
//			new Handle:newEvent = CreateEvent( "player_death" );
//			if( newEvent != INVALID_HANDLE )
//			{
//				attacker = g_AttackerDispenser[ client ];
//				
//				SetEventInt( newEvent, "userid", GetClientUserId(client) );
//				SetEventInt( newEvent, "attacker", GetClientUserId(attacker) );
//				if( assister > 0)
//					SetEventInt( newEvent, "assister", GetClientUserId(assister) );				
//				SetEventInt( newEvent, "stun_flags", stun_flags );				
//				SetEventInt( newEvent, "death_flags", 128 );				
//				SetEventInt( newEvent, "weaponid", -1 );				
//				SetEventInt( newEvent, "victim_entindex", client );				
//				SetEventInt( newEvent, "damagebits", 2359360 );				
//				SetEventInt( newEvent, "customkill", 0 );				
//				SetEventString( newEvent, "weapon", "dispenser_explosion" );
//				FireEvent( newEvent );
//				return Plugin_Handled;
//			}
//		}
//	}
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
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// エンジニア
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer && g_AbilityUnlock[client] )
		{
			// キーチェック
			if( CheckElapsedTime(client, 1.0) )
			{
				// 攻撃ボタン2
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
					
					MetalHop(client);
					g_Hop[ client ] = true;
				}
			}			
		}	
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// デストロイコマンド取得
//
/////////////////////////////////////////////////////////////////////
public Action:Command_Destroy(client, args)
{
	// MODがONの時だけ
	if( !g_IsRunning || client <= 0 )
		return Plugin_Continue;
	
	if(TF2_GetPlayerClass(client) == TFClass_Engineer && g_AbilityUnlock[client])
	{
		new String:arg[128];
		if(args == 1)
		{
			// 一つ目の引数ゲット
			GetCmdArg(1, arg, sizeof(arg));
			
			new objType = StringToInt(arg);
			
			if( objType == 0 && g_Hop[ client ] )
			{
				// ディスペンサージャンプ
				//MetalHop(client);
				
				g_Hop[ client ] = false;
			}
		}
	}	

	return Plugin_Continue;
}


/////////////////////////////////////////////////////////////////////
//
// ディスペンサージャンプ
//
/////////////////////////////////////////////////////////////////////
public MetalHop(client)
{
	// ディスペンサー検索
	new obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_dispenser")) != -1)
	{
		// 持ち主チェック
		new iOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if(iOwner == client)
		{
			new Float:fObjPos[3];			// オブジェクトの位置
			new Float:fPlayerPos[3];		// プレイヤーの位置
			new Float:fKnockVelocity[3];	// 爆発の反動
			new Float:Power = GetConVarFloat(g_BasePower) * -1;		// 反動のベース値
			new Float:distance;				// セントリーとプレイヤーの距離
			
			// プレイヤー位置取得
			GetClientAbsOrigin(client, fPlayerPos);
			// ディスペンサーの位置取得
			GetEntPropVector(obj, Prop_Data, "m_vecOrigin", fObjPos);
			// プレイヤーとディスペンサーの距離算出
			distance = GetVectorDistanceMeter( fPlayerPos, fObjPos );
			
			// 周囲にダメージ
//			if( GetConVarBool( g_IsEnemyDamage ) )
//			{
//				RadiusDamage(obj);
//			}

			// 4m以内でディスペンサーより高い位置に居る場合のみ
			if( distance < 4.0 && fPlayerPos[2] > fObjPos[2])
			{
				// 反動の方向取得
				SubtractVectors(fObjPos, fPlayerPos, fKnockVelocity);
				NormalizeVector(fKnockVelocity, fKnockVelocity); 
				
				// 距離による減衰
				//Power *= (1.0 / distance);
				
				// ディスペンサーのメタル残量とレベル取得
				new metal = GetEntProp(obj, Prop_Send, "m_iAmmoMetal");
				new level = GetEntProp(obj, Prop_Send, "m_iUpgradeLevel");
				
				// プレイヤーのベクトル方向を取得
				new Float:fVelocity[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
				
				
				// レベルとメタル残量による変化
				Power -= (level * 125);
				Power -= (metal / 2);
				
				// 反動を算出
				ScaleVector(fKnockVelocity, Power); 
				AddVectors(fVelocity, fKnockVelocity, fVelocity);

				// プレイヤーへの反動を設定
				SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
			
				// ダメージ算出
				new dmg = RoundFloat((GetConVarInt(g_BaseDamage) + (metal / 20)) * (1.0 / distance) + (level * 20));
				
				// 無敵じゃない
				if( !TF2_IsPlayerInvuln(client) )
				{
					if( GetClientHealth(client) - dmg <= 0 )
					{
						// ダメージがヘルスを上回ったら爆死
						FakeClientCommand(client, "explode");
					}
					else
					{
						// ダメージ
						SetEntityHealth(client, GetClientHealth(client) - dmg);
						// ついでにボイス
						EmitSoundToAll(SOUND_HOP_VOICE, client, _, _, SND_CHANGEPITCH, 0.8, 100);
					}
				}
				
				//AttachParticle(client, "warp_version", 1.0);
				
				FakeClientCommand( client, "Destroy 0" );
			}
		}
	
	}
}


/////////////////////////////////////////////////////////////////////
//
// 人体へのダメージ
//
/////////////////////////////////////////////////////////////////////
/*
stock RadiusDamage(any:obj)
{
	new Float:fVictimPos[3];
	new maxclients = GetMaxClients();
	new Float:fObjPos[3];			// オブジェクトの位置
	new Float:fKnockVelocity[3];	// 爆発の反動
	new iOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	
	// 被害チェック
	for (new victim = 1; victim <= maxclients; victim++)
	{
		if( IsClientInGame(victim) && IsPlayerAlive(victim) )
		{
			if( GetClientTeam(victim) != GetClientTeam(iOwner) && victim != iOwner )
			{
				new Float:Power = GetConVarFloat(g_EnemyBasePower) * -1;		// 反動のベース値
				new Float:distance;				// セントリーとプレイヤーの距離
				
				// プレイヤー位置取得
				GetClientAbsOrigin(victim, fVictimPos);
				// ディスペンサーの位置取得
				GetEntPropVector(obj, Prop_Data, "m_vecOrigin", fObjPos);
				// プレイヤーとディスペンサーの距離算出
				distance = GetVectorDistanceMeter( fVictimPos, fObjPos );

				// 5m以内
				if( CanSeeTarget(victim, fVictimPos, iOwner, fObjPos, GetConVarFloat(g_EnemyDamageRadius), true, true) )
				{
//					PrintToChat(iOwner, "fObjPos = %f %f %f", fObjPos[0], fObjPos[1], fObjPos[2]);
//					PrintToChat(iOwner, "fVictimPos = %f %f %f", fVictimPos[0], fVictimPos[1], fVictimPos[2]);
					// 反動の方向取得
					SubtractVectors(fObjPos, fVictimPos, fKnockVelocity);
					NormalizeVector(fKnockVelocity, fKnockVelocity); 
					
					// 距離による減衰
					//Power *= (1.0 / distance);
					
					// ディスペンサーのメタル残量とレベル取得
					new metal = GetEntProp(obj, Prop_Send, "m_iAmmoMetal");
					new level = GetEntProp(obj, Prop_Send, "m_iUpgradeLevel");
					
					// プレイヤーのベクトル方向を取得
					new Float:fVelocity[3];
					GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
					fVelocity[2] = 280.0;
					
					// レベルとメタル残量による変化
					Power -= (level * 125);
					Power -= (metal / 2);
					
					// 反動を算出
					ScaleVector(fKnockVelocity, Power * 0.8); 
					AddVectors(fVelocity, fKnockVelocity, fVelocity);
					
					// プレイヤーへの反動を設定
					SetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
				
					// ダメージ算出
					new dmg = RoundFloat((GetConVarInt(g_EnemyBaseDamage) + (metal / 10)) * (1.0 / distance) + (level * 35) );
					
					// 無敵じゃない
					if( !TF2_IsPlayerInvuln(victim) && !TF2_IsPlayerBlur(victim) )
					{
						if( GetClientHealth(victim) - dmg <= 0 )
						{
							// ダメージがヘルスを上回ったら爆死
							g_AttackerDispenser[ victim ] = iOwner;
							FakeClientCommand(victim, "explode");
						}
						else
						{
							// ダメージ
							SetEntityHealth(victim, GetClientHealth(victim) - dmg);
						}
					}
					
					//AttachParticle(victim, "warp_version", 1.0);
				
				}
					
			}
		}
	}	
	
}
*/
/////////////////////////////////////////////////////////////////////
//
// ベースパワー
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_BasePower(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 10.0～5000.0まで
	if (StringToFloat(newValue) < 10.0 || StringToFloat(newValue) > 5000.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 10.0 and 5000.0");
	}
}
