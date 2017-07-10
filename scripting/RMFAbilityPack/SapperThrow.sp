/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.1.1
// ・仕様を一部変更
// ・sm_rmf_sapperthrow_damage_amountを追加
// ・sm_rmf_sapperthrow_damage_rateを追加
// ・sm_rmf_sapperthrow_recharge_timeを追加
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
#define PL_NAME "Sapper Throw"
#define PL_DESC "Sapper Throw"
#define PL_VERSION "0.1.1"
#define PL_TRANSLATION "sapperthrow.phrases"

#define MDL_THROW_SAPPER "models/weapons/w_models/w_sapper.mdl"

#define SOUND_SAPPER_REMOVED "weapons/sapper_removed.wav"
#define SOUND_SAPPER_NOISE "weapons/sapper_timer.wav"
#define SOUND_SAPPER_NOISE2 "player/invulnerable_off.wav"
#define SOUND_SAPPER_PLANT "weapons/sapper_plant.wav"
#define SOUND_SAPPER_THROW "weapons/knife_swing.wav"
#define SOUND_RECHARGED "player/recharged.wav"
#define SOUND_BOOT "weapons/weapon_crit_charged_on.wav"

#define SOUND_NO_THROW "weapons/medigun_no_target.wav"

#define SPRITE_ELECTRIC_WAVE "sprites/laser.vmt"

#define MAX_TARGET_BUILDING 10			// 一度に停止させられる建物数

#define EFFECT_CORE_FLASH "sapper_coreflash"
#define EFFECT_DEBRIS "sapper_debris"
#define EFFECT_FLASH "sapper_flash"
#define EFFECT_FLASHUP "sapper_flashup"
#define EFFECT_FLYINGEMBERS "sapper_flyingembers"
#define EFFECT_SMOKE "sapper_smoke"
#define EFFECT_SENTRY_FX "sapper_sentry1_fx"
#define EFFECT_SENTRY_SPARKS1 "sapper_sentry1_sparks1"
#define EFFECT_SENTRY_SPARKS2 "sapper_sentry1_sparks2"
#define EFFECT_TRAIL_RED "stunballtrail_red_crit"
#define EFFECT_TRAIL_BLU "stunballtrail_blue_crit"
	


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
new Handle:g_EffectiveRadius = INVALID_HANDLE;					// ConVar有効範囲
new Handle:g_EffectiveTime = INVALID_HANDLE;					// ConVar有効時間
new Handle:g_DamageAmount = INVALID_HANDLE;						// ConVarダメージ量
new Handle:g_DamageRate = INVALID_HANDLE;						// ConVarダメージ間隔
new Handle:g_RechargeTime = INVALID_HANDLE;						// ConVarリチャージ時間


new g_EffectSprite;												// エフェクト用スプライト

new g_ThrowSapper[MAXPLAYERS+1] = -1;							// 投げたサッパー
new Float:g_SapperPos[MAXPLAYERS+1][3];							// 投げたサッパーの位置
new g_TargetBuilding[MAXPLAYERS+1][MAX_TARGET_BUILDING];		// ターゲットビルディング

new Handle:g_RemoveSapperTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// サッパー消滅タイマー
new Handle:g_SapperLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// エフェクト用のタイマー
new Handle:g_DamageLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// ダメージ用のタイマー
new Handle:g_RechargeTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// リチャージタイマー

new Float:g_NextUseTime[MAXPLAYERS+1] = 0.0; 					// 次に使えるようになるまでの時間

new g_TeamColor[4][4];									// チームカラー

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
		CreateConVar("sm_rmf_tf_sapperthrow", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_sapperthrow","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		
		g_EffectiveRadius	= CreateConVar("sm_rmf_sapperthrow_radius",	"2.5",	"Effective radius[meter] (0.0-100.0)");
		g_EffectiveTime		= CreateConVar("sm_rmf_sapperthrow_time",	"3.0",	"Effective time (0.0-120.0)");
		HookConVarChange(g_EffectiveRadius,	ConVarChange_Radius);
		HookConVarChange(g_EffectiveTime,	ConVarChange_Time);
		
		g_DamageAmount	= CreateConVar("sm_rmf_sapperthrow_damage_amount",	"10",	"Building damage amount (0-1000)");
		g_DamageRate	= CreateConVar("sm_rmf_sapperthrow_damage_rate",	"0.1",	"Building damage rate (0.0-120.0)");
		g_RechargeTime	= CreateConVar("sm_rmf_sapperthrow_charge_time",	"30.0",	"Recharge time (0.0-120.0)");
		HookConVarChange(g_RechargeTime,	ConVarChange_Time);
		HookConVarChange(g_DamageAmount,	ConVarChange_Damage);
		HookConVarChange(g_DamageRate,		ConVarChange_Time);
		
		// 挑発コマンドゲット
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");

		// アビリティクラス設定
		CreateConVar("sm_rmf_sapperthrow_class", "8", "Ability class");
	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// チームカラー設定
		g_TeamColor[_:TFTeam_Red][0] = 255;
		g_TeamColor[_:TFTeam_Red][1] = 0;
		g_TeamColor[_:TFTeam_Red][2] = 0;
		g_TeamColor[_:TFTeam_Red][3] = 255;
		g_TeamColor[_:TFTeam_Blue][0] = 0;
		g_TeamColor[_:TFTeam_Blue][1] = 0;
		g_TeamColor[_:TFTeam_Blue][2] = 255;
		g_TeamColor[_:TFTeam_Blue][3] = 255;
		
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			RemoveThrownSapper(client);
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			RemoveThrownSapper(client);

		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheModel(MDL_THROW_SAPPER);
		
		PrecacheSound(SOUND_SAPPER_REMOVED, true);
		PrecacheSound(SOUND_SAPPER_NOISE, true);
		PrecacheSound(SOUND_SAPPER_NOISE2, true);
		PrecacheSound(SOUND_SAPPER_PLANT, true);
		PrecacheSound(SOUND_SAPPER_THROW, true);
		PrecacheSound(SOUND_RECHARGED, true);
		PrecacheSound(SOUND_BOOT, true);
		PrecacheSound(SOUND_NO_THROW, true);
		
		g_EffectSprite = PrecacheModel(SPRITE_ELECTRIC_WAVE, true);
		
		PrePlayParticle(EFFECT_CORE_FLASH);
		PrePlayParticle(EFFECT_DEBRIS);
		PrePlayParticle(EFFECT_FLASH);
		PrePlayParticle(EFFECT_FLASHUP);
		PrePlayParticle(EFFECT_FLYINGEMBERS);
		PrePlayParticle(EFFECT_SMOKE);
		PrePlayParticle(EFFECT_SENTRY_FX);
		PrePlayParticle(EFFECT_SENTRY_SPARKS1);
		PrePlayParticle(EFFECT_SENTRY_SPARKS2);		
		PrePlayParticle(EFFECT_TRAIL_RED);
		PrePlayParticle(EFFECT_TRAIL_BLU);		
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
		ClearTimer(g_RemoveSapperTimer[client]);
		ClearTimer(g_SapperLoopTimer[client]);
		ClearTimer(g_DamageLoopTimer[client]);
		ClearTimer(g_RechargeTimer[client]);
		
		// サッパー削除
		RemoveThrownSapper(client);
		
		// 次に使えるまでの時間リセット
		g_NextUseTime[client] = 0.0;
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Spy)
		{
			
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_SAPPERTHROW", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_SAPPERTHROW_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_SAPPERTHROW_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_SAPPERTHROW_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_SAPPERTHROW_ATTRIBUTE_3", client, GetConVarFloat(g_RechargeTime) );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s\n%s", attribute1, attribute2, attribute3 );

			
//			if(GetConVarBool(g_AllowDamage))
//			{
//				Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_SAPPERTHROW_DAMAGE", client);
//			}
//			else
//			{
//				Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_SAPPERTHROW_NODAMAGE", client);
//			}
				
		}
		
	}
	
	
	// オブジェクト破壊
//	if(StrEqual(name, EVENT_OBJECT_DESTROYED))
//	{
//		new attacker		= GetClientOfUserId( GetEventInt( event, "attacker" ) );
//		new assister		= GetClientOfUserId( GetEventInt( event, "assister" ) );
//		new weaponid		= GetEventInt( event, "weaponid" );
//		new index			= GetEventInt( event, "index" );
//		new objecttype		= GetEventInt( event, "objecttype" );
//		new String:weapon[64];
//		GetEventString( event, "weapon", weapon, sizeof( weapon ) );
//
//		
//		PrintToChatAll("client = %d", client);	
//		PrintToChatAll("attacker = %d", attacker);	
//		PrintToChatAll("assister = %d", assister);	
//		PrintToChatAll("weaponid = %d", weaponid);	
//		PrintToChatAll("index = %d", index);	
//		PrintToChatAll("objecttype = %d", objecttype);	
//		PrintToChatAll("weapon = %s", weapon);	
//		
//		
//		
//		// イベント書き換え
//		if( attacker == client && g_Drunker[ client ] != -1 )
//		{
//			new Handle:newEvent = CreateEvent( "object_destroyed" );
//			if( newEvent != INVALID_HANDLE )
//			{
//				attacker = g_Drunker[ client ];
//				
//				SetEventInt( newEvent, "userid", GetClientUserId() );
//				SetEventInt( newEvent, "attacker", GetClientUserId() );
//				SetEventInt( newEvent, "weaponid", 0 );				
//				SetEventInt( newEvent, "victim_entindex", client );				
//				SetEventInt( newEvent, "index",  );				
//				SetEventInt( newEvent, "objecttype",  );				
//				SetEventString( newEvent, "weapon", "throw_sapper" );
//				FireEvent( newEvent );
//				return Plugin_Handled;
//			}
//		}		
//		
//	}
	
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
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy && g_AbilityUnlock[client])
	{
		// 武器チェック
		if(TF2_CurrentWeaponEqual(client, "CTFWeaponBuilder"))
		{
			// キーチェック
			if( CheckElapsedTime(client, 2.5) )
			{
				// キーを押した時間を保存
				SaveKeyTime(client);
				
				// 透明じゃないとき＆デッドリンガー準備中じゃないとき
				if(!TF2_IsPlayerCloaked(client) && !TF2_IsPlayerChangingCloak(client) && !TF2_IsReadyFeignDeath(client))
				{
					// チャージ完了している
					if( g_NextUseTime[client] <= GetGameTime() )
					{
						// サッパー投擲
						ThrowSapper(client);
						return Plugin_Continue;
					}
					else
					{
						PrintToChat(client, "\x05%T", "MESSAGE_NO_CHARGE", client, g_NextUseTime[client] - GetGameTime());
					}
				}
			}
			EmitSoundToClient(client, SOUND_NO_THROW, client, _, _, _, 1.0);
		}
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動チェック
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// スパイのみ
		if(TF2_GetPlayerClass(client) == TFClass_Spy && g_AbilityUnlock[client])
		{
			// サッパーチェック
			SapperActivateCheck(client);
			
			//new weaponIndex = GetPlayerWeaponSlot(client, 1);
			//if( weaponIndex != -1)
			//{
				//PrintToChat(client, "%f", GetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack"));
			//}
			
//			// キーチェック
//			if( CheckElapsedTime(client, 2.5) )
//			{
//				// 武器チェック
//				if(TF2_CurrentWeaponEqual(client, "CTFWeaponBuilder"))
//				{
//					// 攻撃
//					if ( GetClientButtons(client) & IN_ATTACK )
//					{
//						// キーを押した時間を保存
//						SaveKeyTime(client);
//						
//						// 透明じゃないとき＆デッドリンガー準備中じゃないとき
//						if(!TF2_IsPlayerCloaked(client) && !TF2_IsPlayerChangingCloak(client) && !TF2_IsReadyFeignDeath(client))
//						{
//							// サッパーしかけられる距離ならダメ
//							if(!TF2_IsAllowPlantSapper(client))
//							{
//								// チャージ完了している
//								if( g_NextUseTime[client] <= GetGameTime() )
//								{
//									// サッパー投擲
//									ThrowSapper(client);
//								}
//								else
//								{
//									PrintToChat(client, "\x05%T", "MESSAGE_NO_CHARGE", client, g_NextUseTime[client] - GetGameTime());
//								}
//							}
//						}
//					}
//				}

//			}			
		
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// サッパー発動チェック
//
/////////////////////////////////////////////////////////////////////
stock SapperActivateCheck(any:client)
{
	// サッパーチェック
	if(g_ThrowSapper[client] != -1)
	{
		// 正しいサッパーか
		if(IsValidEntity(g_ThrowSapper[client]))
		{	
			if(GetEntityMoveType(g_ThrowSapper[client]) != MOVETYPE_NONE)
			{
				new Float:SapperDiff[3];
				new Float:SapperPos[3];
				// 投げたサッパーの位置
				GetEntPropVector(g_ThrowSapper[client], Prop_Data, "m_vecAbsOrigin", SapperPos);
				
				// 前回位置と比較
				SapperDiff[0] = g_SapperPos[client][0] - SapperPos[0];
				SapperDiff[1] = g_SapperPos[client][1] - SapperPos[1];
				SapperDiff[2] = g_SapperPos[client][2] - SapperPos[2];
				
				// 動きが止まったら発動
				if( FloatAbs(SapperDiff[0]) < 0.1 && FloatAbs(SapperDiff[1]) < 0.1 && FloatAbs(SapperDiff[2]) < 0.1 )
				{
					// 移動しない
					SetEntityMoveType(g_ThrowSapper[client], MOVETYPE_NONE);				// 移動タイプ
					
					// 既に他の人のサッパーがあれば破壊する
					for(new i = 0; i < MAXPLAYERS + 1; i++)
					{
						if(client != i)
						{
							if(CanSeeTarget(g_ThrowSapper[client], g_SapperPos[client], g_ThrowSapper[i], g_SapperPos[i], GetConVarFloat(g_EffectiveRadius)))
							{
								RemoveThrownSapper(i);
							}
						}
					}
					
					StopSound(g_ThrowSapper[client], 0, SOUND_BOOT);			// 音止める

					// サウンド
					EmitSoundToAll(SOUND_SAPPER_NOISE, g_ThrowSapper[client], _, _, SND_CHANGEPITCH, 1.0, 150);	// ノイズ開始
					EmitSoundToAll(SOUND_SAPPER_NOISE2, g_ThrowSapper[client], _, _, SND_CHANGEPITCH, 1.0, 60);	// ノイズ開始
					EmitSoundToAll(SOUND_SAPPER_PLANT, g_ThrowSapper[client], _, _, _, 1.0);	// ノイズ開始
					
					// 消滅タイマー設定
					ClearTimer(g_RemoveSapperTimer[client]);	
					g_RemoveSapperTimer[client] = CreateTimer(GetConVarFloat(g_EffectiveTime), Timer_RemoveSapper, client);
					
					
					// ループタイマー設定
					ClearTimer(g_SapperLoopTimer[client]);
					g_SapperLoopTimer[client] = CreateTimer(0.5, Timer_SapperLoop, client, TIMER_REPEAT);
					Timer_SapperLoop(g_SapperLoopTimer[client], client);	// とりあえず一回発動
					
					ClearTimer(g_DamageLoopTimer[client]);
					g_DamageLoopTimer[client] = CreateTimer(GetConVarFloat(g_DamageRate), Timer_DamageLoop, client, TIMER_REPEAT);
					Timer_SapperLoop(g_DamageLoopTimer[client], client);	// とりあえず一回発動
					
				}
				
				// 最後の位置保存
				g_SapperPos[client][0] = SapperPos[0];
				g_SapperPos[client][1] = SapperPos[1];
				g_SapperPos[client][2] = SapperPos[2];
				
			}
		}
	}	
}

/////////////////////////////////////////////////////////////////////
//
// ループタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_SapperLoop(Handle:timer, any:client)
{
	// サッパーチェック
	if(g_ThrowSapper[client] != -1)
	{
		// 正しいエンティティ
		if(IsValidEntity(g_ThrowSapper[client]))
		{	
			// 最後の位置保存
			// 投げたサッパーの位置
			GetEntPropVector(g_ThrowSapper[client], Prop_Data, "m_vecAbsOrigin", g_SapperPos[client]);

			new team = GetClientTeam(client);
			new Float:radius = GetConVarFloat(g_EffectiveRadius);
			// ビリビリエフェクト
			TE_SetupBeamRingPoint(g_SapperPos[client], 0.1, MeterToUnit(radius) * 1.8, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 40.0, g_TeamColor[team], 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(g_SapperPos[client], 0.1, MeterToUnit(radius) * 1.4, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 40.0, g_TeamColor[team], 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(g_SapperPos[client], 0.1, MeterToUnit(radius) * 1.0, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 40.0, g_TeamColor[team], 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(g_SapperPos[client], 0.1, MeterToUnit(radius) * 0.6, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 40.0, g_TeamColor[team], 15, 0);
			TE_SendToAll();
			
			
			// 周囲のスパイの変装・透明を解除
			new maxclients = GetMaxClients();
			for (new i = 1; i <= maxclients; i++)
			{
				// ゲームに入っている
				if( IsClientInGame(i) && IsPlayerAlive(i) )
				{
					// スパイのみ
					if(TF2_GetPlayerClass(i) == TFClass_Spy)
					{
						new Float:spyPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", spyPos);
						if(CanSeeTarget(g_ThrowSapper[client], g_SapperPos[client], i, spyPos, radius))
						{ 
							// 変装解除
							if(TF2_IsPlayerDisguised(i))
							{
								//TF2_DisguisePlayer(i, TFTeam:GetClientTeam(i), TFClass_Spy);
								TF2_RemoveCond( client, TF2_COND_DISGUISED );
							}
							// クロークメーターが0に
							TF2_RemoveCond( client, TF2_COND_CLOAKED );
							TF2_SetPlayerCloakMeter(i, 0);
							if(TF2_IsPlayerCloaked(i))
							{
								SetEntPropFloat(i, Prop_Send, "m_flInvisChangeCompleteTime", GetGameTime() + 1.0);
							//	TF2_SetPlayerCloak(i, false);
							}
							
						}
					}
				}
			}
			
			new Float:effectPos[3];
			new targetCount = 0;
			// ディスペンサー
			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1)
			{
				new Float:dispPos[3];
				GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", dispPos);
				if(CanSeeTarget(g_ThrowSapper[client], g_SapperPos[client], ent, dispPos, radius))
				{
					new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					if(GetClientTeam(iOwner) != GetClientTeam(client))
					{
						if(targetCount < MAX_TARGET_BUILDING)
						{
							effectPos[0] = GetRandomFloat(-25.0, 25.0);
							effectPos[1] = GetRandomFloat(-25.0, 25.0);
							effectPos[2] = GetRandomFloat(10.0, 65.0);
							ShowParticleEntity(ent, EFFECT_SENTRY_FX, 0.05, effectPos);
							ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS1, 0.05, effectPos);
							ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS2, 0.05, effectPos);
							
							//SetEntProp(ent, Prop_Send, "m_bHasSapper", 1);
							SetEntProp(ent, Prop_Send, "m_bDisabled", 1);

							g_TargetBuilding[client][targetCount] = ent;
							targetCount += 1;
						}
					}
					
					// 設置されたサッパーにダメージ
					DoDamagePlantSapper(ent, 200);
				}
			}
			// セントリーガン
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1)
			{
				new Float:sentPos[3];
				GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", sentPos);
				if(CanSeeTarget(g_ThrowSapper[client], g_SapperPos[client], ent, sentPos, radius))
				{
					new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					if(GetClientTeam(iOwner) != GetClientTeam(client))
					{
						if(targetCount < MAX_TARGET_BUILDING)
						{
							new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
							effectPos[0] = GetRandomFloat(-20.0, 20.0);
							effectPos[1] = GetRandomFloat(-20.0, 20.0);
							switch(level)
							{
								case 1:
									effectPos[2] = GetRandomFloat(10.0, 55.0);
								case 2:
									effectPos[2] = GetRandomFloat(10.0, 65.0);
								case 3:
									effectPos[2] = GetRandomFloat(10.0, 75.0);
							}
							ShowParticleEntity(ent, EFFECT_SENTRY_FX, 0.05, effectPos);
							ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS1, 0.05, effectPos);
							ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS2, 0.05, effectPos);
							

							//SetEntProp(ent, Prop_Send, "m_bHasSapper", 1);
							SetEntProp(ent, Prop_Send, "m_bDisabled", 1);

							g_TargetBuilding[client][targetCount] = ent;
							targetCount += 1;
						}
					}
					
					// 設置されたサッパーにダメージ
					DoDamagePlantSapper(ent, 200);
				}
			}
			// テレポ入り口
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "obj_teleporter_entrance")) != -1)
			{
				new Float:entraPos[3];
				GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", entraPos);
				if(CanSeeTarget(g_ThrowSapper[client], g_SapperPos[client], ent, entraPos, radius))
				{
					new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					if(GetClientTeam(iOwner) != GetClientTeam(client))
					{
						if(targetCount < MAX_TARGET_BUILDING)
						{
							effectPos[0] = GetRandomFloat(-25.0, 25.0);
							effectPos[1] = GetRandomFloat(-25.0, 25.0);
							effectPos[2] = GetRandomFloat(5.0, 15.0);
							ShowParticleEntity(ent, EFFECT_SENTRY_FX, 0.05, effectPos);
							ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS1, 0.05, effectPos);
							ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS2, 0.05, effectPos);

							//SetEntProp(ent, Prop_Send, "m_bHasSapper", 1);
							SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
							
							g_TargetBuilding[client][targetCount] = ent;
							targetCount += 1;
							
						}
					}
					
					// 設置されたサッパーにダメージ
					DoDamagePlantSapper(ent, 200);
				}
				
								
			}
			// テレポ出口
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "obj_teleporter_exit")) != -1)
			{
				new Float:exitPos[3];
				GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", exitPos);
				if(CanSeeTarget(g_ThrowSapper[client], g_SapperPos[client], ent, exitPos, radius))
				{
					new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					if(GetClientTeam(iOwner) != GetClientTeam(client))
					{
						effectPos[0] = GetRandomFloat(-25.0, 25.0);
						effectPos[1] = GetRandomFloat(-25.0, 25.0);
						effectPos[2] = GetRandomFloat(5.0, 15.0);
						ShowParticleEntity(ent, EFFECT_SENTRY_FX, 0.05, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS1, 0.05, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS2, 0.05, effectPos);

						//SetEntProp(ent, Prop_Send, "m_bHasSapper", 1);
						SetEntProp(ent, Prop_Send, "m_bDisabled", 1);

						if(targetCount < MAX_TARGET_BUILDING)
						{
							g_TargetBuilding[client][targetCount] = ent;
							targetCount += 1;
						}
					}
					
					// 設置されたサッパーにダメージ
					DoDamagePlantSapper(ent, 200);
				}
				
			}
			return;
		}
	}
	
	// タイマークリア
	ClearTimer(g_SapperLoopTimer[client]);	
}	
/////////////////////////////////////////////////////////////////////
//
// ループタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DamageLoop( Handle:timer, any:client )
{
	// サッパーチェック
	if(g_ThrowSapper[client] != -1)
	{
		// 正しいエンティティ
		if(IsValidEntity(g_ThrowSapper[client]))
		{	
			// 最後の位置保存
			// 投げたサッパーの位置
			GetEntPropVector(g_ThrowSapper[client], Prop_Data, "m_vecAbsOrigin", g_SapperPos[client]);
			
			// ディスペンサー
			DoDamageObject( client, 0 );

			// テレポ入り口
			DoDamageObject( client, 1 );
			
			// テレポ出口
			DoDamageObject( client, 2 );

			// セントリーガン
			DoDamageObject( client, 3 );
			return;
		}
	}

	// タイマークリア
	ClearTimer(g_DamageLoopTimer[client]);	
}


/////////////////////////////////////////////////////////////////////
//
// 機械にダメージ
//
/////////////////////////////////////////////////////////////////////
stock DoDamageObject( any:client, objectType )
{
	new String:edictName[64];
	// オブジェクトタイプ判別
	switch( objectType )
	{
	case 0: edictName = "obj_dispenser";
	case 1: edictName = "obj_teleporter_entrance";
	case 2: edictName = "obj_teleporter_exit";
	case 3: edictName = "obj_sentrygun";
	}
	
	// オブジェクトを検索
	new ent = -1;
	while ( ( ent = FindEntityByClassname( ent, edictName ) ) != -1 )
	{
		// 敵チームのオブジェクト
		new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
		if(GetClientTeam( iOwner ) != GetClientTeam( client ) )
		{
			new damage = GetConVarInt( g_DamageAmount );
			new Float:radius = GetConVarFloat( g_EffectiveRadius );
			new Float:entPos[3];
			GetEntPropVector( ent, Prop_Data, "m_vecAbsOrigin", entPos );
			// 対象がサッパーから見えるかどうかチェック
			if( CanSeeTarget( g_ThrowSapper[ client ], g_SapperPos[ client ], ent, entPos, radius ) )
			{
				// そのダメージで破壊される？
				if( GetEntProp( ent, Prop_Send, "m_iHealth") - damage <= 0 )
				{
					// リストから削除
					for( new i = 0; i < MAX_TARGET_BUILDING; i++ )
					{
						if( g_TargetBuilding[ client ][ i ] == ent )
						{
							g_TargetBuilding[ client ][ i ] = -1;
						}
					}
					
					// キルログに表示
					new Handle:newEvent = CreateEvent( "object_destroyed" );
					if( newEvent != INVALID_HANDLE )
					{
						SetEventInt( newEvent,		"userid",		GetClientUserId( iOwner ) );
						SetEventInt( newEvent,		"attacker",		GetClientUserId( client ) );
						SetEventInt( newEvent,		"weaponid",		0 );				
						SetEventInt( newEvent,		"index",  		ent );				
						SetEventInt( newEvent,		"objecttype",	objectType  );				
						SetEventString( newEvent,	"weapon",		"obj_attachment_sapper" );
						FireEvent( newEvent );
					}						
				}
				
				// 実際にダメージ
				SetVariantInt( damage );
				AcceptEntityInput( ent, "RemoveHealth" );
			}
		}
	}	
}


/////////////////////////////////////////////////////////////////////
//
// 装着されたサッパーを破壊
//
/////////////////////////////////////////////////////////////////////
stock DoDamagePlantSapper(any:building, damage)
{
	if(	TF2_EdictNameEqual(building, "obj_dispenser") ||
		TF2_EdictNameEqual(building, "obj_sentrygun") || 
		TF2_EdictNameEqual(building, "obj_teleporter_entrance") || 
		TF2_EdictNameEqual(building, "obj_teleporter_exit") 
	)
	{
		if(GetEntProp(building, Prop_Send, "m_bHasSapper"))
		{
			new attachSapper = -1;
			while ((attachSapper = FindEntityByClassname(attachSapper, "obj_attachment_sapper")) != -1)
			{
				if(!GetEntProp(attachSapper, Prop_Send, "m_bPlacing"))
				{
					if(building == GetEntPropEnt(attachSapper, Prop_Send, "m_hBuiltOnEntity"))
					{
						SetVariantInt(damage);
						AcceptEntityInput(attachSapper, "RemoveHealth");
					}
				}
			}
		}	
		else
		{
			new attachSapper = -1;
			while ((attachSapper = FindEntityByClassname(attachSapper, "obj_attachment_sapper")) != -1)
			{
				if(GetEntProp(attachSapper, Prop_Send, "m_bPlacing"))
				{
					if(building == GetEntPropEnt(attachSapper, Prop_Send, "m_hBuiltOnEntity"))
					{
						//PrintToChatAll("aaa");
						// 設置前のサッパーは設置できないようにする。
						new iOwner = GetEntPropEnt(attachSapper, Prop_Send, "m_hBuilder");

						// 周囲のスパイサッパー使えない
						new weaponIndex = GetPlayerWeaponSlot(iOwner, 1);
						if( weaponIndex != -1)
						{
							SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
						}
					}
				}
			}
		}
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// サッパー投擲
//
/////////////////////////////////////////////////////////////////////
stock ThrowSapper(any:client)
{
	// サッパーを削除
	RemoveThrownSapper(client)

	// 飛ばす用のサッパー作成
	new sapper = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(sapper))
	{
		SetEntPropEnt(sapper, Prop_Data, "m_hOwnerEntity", client);	// 持ち主
		SetEntityModel(sapper, MDL_THROW_SAPPER);					// モデル
		SetEntityMoveType(sapper, MOVETYPE_VPHYSICS);				// 移動タイプ
		SetEntProp(sapper, Prop_Data, "m_CollisionGroup", 1);		// コリジョングループ
		SetEntProp(sapper, Prop_Data, "m_usSolidFlags", 16);		// あたり判定フラグ
		SetEntProp(sapper, Prop_Data, "m_nSolidType", 6);			// あたり判定タイプ
		SetEntPropFloat(sapper, Prop_Data, "m_flFriction", 10000.0);	// 摩擦力
		SetEntPropFloat(sapper, Prop_Data, "m_massScale", 100.0);		// 重さ倍率
		DispatchSpawn(sapper);										// スポーン
		new String:nameSapper[64];
		Format(nameSapper, sizeof(nameSapper), "tf2sapper%d", client);
		DispatchKeyValue(sapper, "targetname", nameSapper);
		//DispatchKeyValue(sapper, "OnHealthChanged", "!self,Break,,0,-1");
		//DispatchKeyValue(sapper, "OnBreak", "!self,Kill,,0,-1");
		//AcceptEntityInput(sapper, "SetParent", client, client, 0);
		
		new Float:pos[3];
		new Float:ang[3];
		new Float:vec[3];
		new Float:svec[3];
		new Float:pvec[3];
		GetClientEyePosition(client, pos);						// 投げる最初の位置
		GetClientEyeAngles(client, ang);						// 投げる角度
		//ang[0] -= 15.0;
		ang[1] += 2.0;
		pos[2] -= 20.0;
		GetAngleVectors(ang, vec, svec, NULL_VECTOR);	// 角度から正面取得
		ScaleVector(vec, 500.0);								// 投げる速度
		ScaleVector(svec, 30.0);								// 横移動ベクトル
		AddVectors(pos, svec, pos);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", pvec);	// プレイヤーの移動方向
		AddVectors(pvec, vec, vec);
		TeleportEntity(sapper, pos, ang, vec);					// 移動

		// 入れとく
		g_ThrowSapper[client] = sapper;	
		
		// エフェクト
		if( GetClientTeam( client ) == _:TFTeam_Red )
		{
			AttachParticle( sapper, EFFECT_TRAIL_RED, 2.0 );
		}
		else
		{
			AttachParticle( sapper, EFFECT_TRAIL_BLU, 2.0 );
		}


		// サウンド
		EmitSoundToAll(SOUND_BOOT, sapper, _, _, SND_CHANGEPITCH, 0.2, 30);	// ブート音
		EmitSoundToAll(SOUND_SAPPER_THROW, client, _, _, _, 1.0);

		// 前に持ってた武器に切り替え
		ClientCommand(client, "lastinv");
		
		// サッパー削除
//		new weaponIndex = GetPlayerWeaponSlot(client, 1);
//		if( weaponIndex != -1)
//		{
//			//RemovePlayerItem(client, weaponIndex);
//			//RemoveEdict(weaponIndex);
//			TF2_RemoveWeaponSlot(client, 1);
//		}	
		
		//ClientCommand(client, "slot1");
		// 次に使用可能になるまでの時間設定
		g_NextUseTime[client] = GetGameTime() + GetConVarFloat(g_RechargeTime);

		// リチャージタイマー発動
		ClearTimer(g_RechargeTimer[client]);	
		g_RechargeTimer[client] = CreateTimer(GetConVarFloat(g_RechargeTime), Timer_SapperRecharge, client);

		//ClientCommand(client, "slot2");
		
		
	}
}
/////////////////////////////////////////////////////////////////////
//
// チャージ完了タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_SapperRecharge(Handle:timer, any:client)
{
	g_RechargeTimer[client] = INVALID_HANDLE;
	PrintToChat(client, "\x05%T", "MESSAGE_RECHARGED_SAPPER", client);
	EmitSoundToClient(client, SOUND_RECHARGED, client, _, _, _, 1.0);
	// 次に使える時間リセット
	g_NextUseTime[client] = GetGameTime()
}

/////////////////////////////////////////////////////////////////////
//
// サッパー消滅タイマー終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_RemoveSapper(Handle:timer, any:client)
{
	g_RemoveSapperTimer[client] = INVALID_HANDLE;
	// サッパー削除
	RemoveThrownSapper(client);
}

/////////////////////////////////////////////////////////////////////
//
// 投げたサッパーを削除
//
/////////////////////////////////////////////////////////////////////
stock RemoveThrownSapper(any:client)
{
	// 消滅タイマー削除
	ClearTimer(g_RemoveSapperTimer[client]);	
	
	// ループタイマー設定
	ClearTimer(g_SapperLoopTimer[client]);	
	
	// ダメージループタイマー設定
	ClearTimer(g_DamageLoopTimer[client]);	

	// サッパー初期化
	if(g_ThrowSapper[client] != -1)
	{
		// 残ってたら削除
		if(IsValidEntity(g_ThrowSapper[client]))
		{
			// ターゲット名取得取得
			new String:nameSapper[64];
			new String:nameTarget[64];
			GetEntPropString(g_ThrowSapper[client], Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
		
			Format(nameSapper, sizeof(nameSapper), "tf2sapper%d", client);
			if(StrEqual(nameTarget, nameSapper))
			{
				new Float:SapperPos[3];
				GetEntPropVector(g_ThrowSapper[client], Prop_Data, "m_vecAbsOrigin", SapperPos);
				// エフェクト
				ShowParticle(EFFECT_CORE_FLASH, 1.0, SapperPos);
				ShowParticle(EFFECT_DEBRIS, 1.0, SapperPos);
				ShowParticle(EFFECT_FLASH, 1.0, SapperPos);
				ShowParticle(EFFECT_FLASHUP, 1.0, SapperPos);
				ShowParticle(EFFECT_FLYINGEMBERS, 1.0, SapperPos);
				ShowParticle(EFFECT_SMOKE, 1.0, SapperPos);
				
				// サウンド
				StopSound(g_ThrowSapper[client], 0, SOUND_SAPPER_NOISE);	// ノイズ音止める
				StopSound(g_ThrowSapper[client], 0, SOUND_SAPPER_NOISE2);	// ノイズ音止める
				EmitSoundToAll(SOUND_SAPPER_REMOVED, g_ThrowSapper[client], _, _, _, 1.0);
	
				// 停止させていた機器を作動させる
				for(new i = 0; i < MAX_TARGET_BUILDING; i++)
				{
					if(g_TargetBuilding[client][i] != -1)
					{
						if (IsValidEntity(g_TargetBuilding[client][i]))
						{
							//SetEntProp(g_TargetBuilding[client][i], Prop_Send, "m_bHasSapper", 0);
							SetEntProp(g_TargetBuilding[client][i], Prop_Send, "m_bDisabled", 0);
							
							// テレポーターのチャージリセット
							if(TF2_EdictNameEqual(g_TargetBuilding[client][i], "obj_teleporter_entrance") || 
								TF2_EdictNameEqual(g_TargetBuilding[client][i], "obj_teleporter_exit"))
							{
								SetEntProp(g_TargetBuilding[client][i], Prop_Send, "m_iState", 3);
							}

						}
					}
				}							
				
				// 実際に削除
				AcceptEntityInput(g_ThrowSapper[client], "Kill");
			}
		}
	}
	// いろいろ初期化
	g_ThrowSapper[client] = -1;
	// 過去位置初期化
	g_SapperPos[client][0] = 0.0;
	g_SapperPos[client][1] = 0.0;
	g_SapperPos[client][2] = 0.0;
	for(new i = 0; i < MAX_TARGET_BUILDING; i++)
	{
		g_TargetBuilding[client][i] = -1;
	}
}

