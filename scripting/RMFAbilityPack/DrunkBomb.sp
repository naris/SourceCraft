/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.8
// ・一部仕様を変更
// ・キルログに対応
// ・1.3.1でコンパイル
// ・sm_rmf_drunkbomb_gravity_scaleを削除
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
//#include "rmf/drug"

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Drunk Bomb"
#define PL_DESC "Drunk Bomb"
#define PL_VERSION "0.0.8"
#define PL_TRANSLATION "drunkbomb.phrases"

#define SOUND_DEMO_BEEP "items/cart_explode_trigger.wav"
#define SOUND_DEMO_SING "vo/taunts/demoman_taunts01.wav"
#define SOUND_DEMO_EXPLOSION "items/cart_explode.wav"
#define SOUND_DEMO_EXPLOSION_MISS "weapons/explode2.wav"


#define MDL_BIG_BOMB_BLU "models/props_trainyard/bomb_cart.mdl"
#define MDL_BIG_BOMB_RED "models/props_trainyard/bomb_cart_red.mdl"
//#define MDL_BIG_BOMB "models/props_trainyard/cart_bomb_separate.mdl"

#define EFFECT_EXPLODE_EMBERS "cinefx_goldrush_embers"
#define EFFECT_EXPLODE_DEBRIS "cinefx_goldrush_debris"
#define EFFECT_EXPLODE_INITIAL_SMOKE "cinefx_goldrush_initial_smoke"
#define EFFECT_EXPLODE_FLAMES "cinefx_goldrush_flames"
#define EFFECT_EXPLODE_FLASH "cinefx_goldrush_flash"
#define EFFECT_EXPLODE_BURNINGDEBIS "cinefx_goldrush_burningdebris"
#define EFFECT_EXPLODE_SMOKE "cinefx_goldrush_smoke"
#define EFFECT_EXPLODE_HUGEDUSTUP "cinefx_goldrush_hugedustup"

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
new Handle:g_FuseTime = INVALID_HANDLE;						// ConVar爆弾タイマー時間
new Handle:g_MoveSpeedMag = INVALID_HANDLE;					// ConVar移動速度
new Handle:g_DamageRadius = INVALID_HANDLE;					// ConVar有効範囲
new Handle:g_BaseDamage = INVALID_HANDLE;					// ConVarベースダメージ

new Handle:g_TauntTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// 挑発チェックタイマー
new Handle:g_FuseEnd[MAXPLAYERS+1] = INVALID_HANDLE;		// ダッシュ終了タイマー
new Handle:g_TauntChain[MAXPLAYERS+1] = INVALID_HANDLE;		// 挑発コンボタイマー
new Handle:g_LoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ループ処理
new Handle:g_LoopVisualTimer[MAXPLAYERS+1] = INVALID_HANDLE;// 視界エフェクト処理

new bool:g_FirstTaunt[MAXPLAYERS+1] = false;				// 挑発コンボ成功？
new bool:g_HasBomb[MAXPLAYERS+1] = false;					// 発動チュ？
new g_AngleDir[MAXPLAYERS+1] = 1;							// 視界の回転方向
new g_FadeColor[MAXPLAYERS+1][3];							// カラー
new g_Drunker[MAXPLAYERS+1] = -1;							// 攻撃者


new g_BombModel[MAXPLAYERS+1] = -1;			// 爆弾モデル

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
		CreateConVar("sm_rmf_tf_drunkbomb", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_drunkbomb","1","Drunk Bomb Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_FuseTime		= CreateConVar("sm_rmf_drunkbomb_fuse",			"5.5","Fuse time (0.0-120.0)");
		g_MoveSpeedMag	= CreateConVar("sm_rmf_drunkbomb_speed_mag",	"0.8","Movement speed magnification(0.0-10.0)");
		g_DamageRadius	= CreateConVar("sm_rmf_drunkbomb_radius",		"10.0","Damage radius (0.0-100.0)");
		g_BaseDamage	= CreateConVar("sm_rmf_drunkbomb_base_damage",	"800","Base damage (0-1000)");
		HookConVarChange(g_FuseTime,		ConVarChange_Time);
		HookConVarChange(g_MoveSpeedMag,	ConVarChange_Magnification);
		HookConVarChange(g_DamageRadius,	ConVarChange_Radius);
		HookConVarChange(g_BaseDamage,		ConVarChange_Damage);


		// 挑発コマンドゲット
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_drunkbomb_class", "4", "Ability class");
	}
	
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 爆弾削除
			DeleteBigBomb(i)
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 爆弾削除
			DeleteBigBomb(i)
		}
	}

	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// 爆弾削除
			DeleteBigBomb(client)
		}

		PrePlayParticle(EFFECT_EXPLODE_EMBERS);
		PrePlayParticle(EFFECT_EXPLODE_DEBRIS);
		PrePlayParticle(EFFECT_EXPLODE_INITIAL_SMOKE);
		PrePlayParticle(EFFECT_EXPLODE_FLAMES);
		PrePlayParticle(EFFECT_EXPLODE_FLASH);
		PrePlayParticle(EFFECT_EXPLODE_BURNINGDEBIS);
		PrePlayParticle(EFFECT_EXPLODE_SMOKE);
		PrePlayParticle(EFFECT_EXPLODE_HUGEDUSTUP);
		
		PrecacheSound(SOUND_DEMO_BEEP, true);
		PrecacheSound(SOUND_DEMO_SING, true);
		PrecacheSound(SOUND_DEMO_EXPLOSION, true);
		PrecacheSound(SOUND_DEMO_EXPLOSION_MISS, true);

		PrecacheModel(MDL_BIG_BOMB_BLU, true);
		PrecacheModel(MDL_BIG_BOMB_RED, true);

	}	
	
	// プレイヤーリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// 未発動
		g_HasBomb[client] = false;
		
		// 攻撃者クリア
		g_Drunker[client] = -1;
		
		// タイマークリア
		ClearTimer(g_TauntTimer[client]);
		
		// タイマークリア
		ClearTimer(g_FuseEnd[client]);
		
		// タイマークリア
		ClearTimer(g_TauntChain[client]);
		
		// タイマークリア
		ClearTimer(g_LoopTimer[client]);
		
		// タイマークリア
		ClearTimer(g_LoopVisualTimer[client]);

		// 初期挑発成功フラグクリア
		g_FirstTaunt[client] = false;
				
		// デフォルトスピード
		TF2_SetPlayerDefaultSpeed(client);
		//SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", TF2_GetPlayerClassSpeed(client));

		// 重力戻す
		SetEntityGravity(client, 1.0);
		
		// 歌とめる
		StopSound(client, 0, SOUND_DEMO_SING);
		
		// 爆弾のモデルを削除
		DeleteBigBomb(client);
		
		// 視界エフェクト
		g_AngleDir[client] = 1;
		g_FadeColor[client][0] = 255;
		g_FadeColor[client][1] = 255;
		g_FadeColor[client][2] = 255;
		ScreenFade(client, 0, 0, 0, 0, 255, IN);
		
		// 視界戻す。
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_DemoMan)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:attribute4[256];
			new String:percentage[16];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_DRUNKBOMB", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_3", client, GetConVarFloat(g_FuseTime) );
			GetPercentageString( GetConVarFloat( g_MoveSpeedMag ), percentage, sizeof( percentage ) )
			Format( attribute4, sizeof( attribute4 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_4", client, percentage );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s", attribute1);
			// 3ページ目
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s\n%s\n%s", attribute2, attribute3, attribute4 );
			
		}
	}
	
	// 切断
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		g_BombModel[client] = -1;
	}

	// 死亡
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		// 失敗エフェクト
		if(g_HasBomb[client])
		{
			new Float:pos[3];
			pos[0] = 0.0;
			pos[1] = 0.0;
			pos[2] = 50.0;
			new Float:ang[3];
			ang[0] = -90.0;
			ang[1] = 0.0;
			ang[2] = 0.0;
			EmitSoundToAll(SOUND_DEMO_EXPLOSION_MISS, client, _, _, SND_CHANGEPITCH, 1.0, 80);
			ShowParticleEntity(client, EFFECT_EXPLODE_EMBERS, 1.0, pos, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_DEBRIS, 1.0, pos, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_INITIAL_SMOKE, 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_flames", 1.0, pos, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_FLASH, 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_burningdebris", 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_smoke", 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_hugedustup", 1.0, pos, ang);
		
		}
		
		new attacker		= GetClientOfUserId( GetEventInt( event, "attacker" ) );
		new assister		= GetClientOfUserId( GetEventInt( event, "assister" ) );
		new stun_flags		= GetEventInt( event, "stun_flags" );
		new death_flags		= GetEventInt( event, "death_flags" );
		new weaponid		= GetEventInt( event, "weaponid" );
		new victim_entindex	= GetEventInt( event, "victim_entindex" );
		new damagebits		= GetEventInt( event, "damagebits" );
		new customkill		= GetEventInt( event, "customkill" );
		new String:weapon[64];
		GetEventString( event, "weapon", weapon, sizeof( weapon ) );

		// イベント書き換え
		if( attacker == client && g_Drunker[ client ] != -1 )
		{
			new Handle:newEvent = CreateEvent( "player_death" );
			if( newEvent != INVALID_HANDLE )
			{
				attacker = g_Drunker[ client ];
				
				SetEventInt( newEvent, "userid", GetClientUserId(client) );
				SetEventInt( newEvent, "attacker", GetClientUserId(attacker) );
				if( assister > 0)
					SetEventInt( newEvent, "assister", GetClientUserId(assister) );				
				SetEventInt( newEvent, "stun_flags", stun_flags );				
				SetEventInt( newEvent, "death_flags", 128 );				
				SetEventInt( newEvent, "weaponid", -1 );				
				SetEventInt( newEvent, "victim_entindex", client );				
				SetEventInt( newEvent, "damagebits", 2359360 );				
				SetEventInt( newEvent, "customkill", 0 );				
				SetEventString( newEvent, "weapon", "drunk_bomb" );
				FireEvent( newEvent );
				return Plugin_Handled;
			}
		}		
		
	}
	
	// プレイヤーリサプライ
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			// デモマン
			if( TF2_GetPlayerClass(client) == TFClass_DemoMan && g_AbilityUnlock[client] && g_FuseEnd[client] != INVALID_HANDLE )
			{
				// 武器再取得しないように
				// 近接武器以外削除
				ClientCommand(client, "slot3");
				new weaponIndex;
				for(new i=0;i<3;i++)
				{
					if(i != 2)
					{
						weaponIndex = GetPlayerWeaponSlot(client, i);
						if( weaponIndex != -1 )
						{
							TF2_RemoveWeaponSlot(client, i);
							//RemovePlayerItem(client, weaponIndex);
							//AcceptEntityInput(weaponIndex, "Kill");		
						}
					}
				}			
			}
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
		TauntCheck(client);
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動
//
/////////////////////////////////////////////////////////////////////
public TauntCheck(any:client)
{
	// フューズ着火していない
	if( g_FuseEnd[client] == INVALID_HANDLE )
	{
		// 武器名取得
		new String:classname[64];
		TF2_GetCurrentWeaponClass(client, classname, 64);
		
		// グレラン
		if(StrEqual(classname, "CTFGrenadeLauncher"))
		{
			ClearTimer(g_TauntTimer[client]);
			g_TauntTimer[client] = CreateTimer(2.0, Timer_TauntEnd, client);
		}
		
		// ボトル＆ コンボ時間内
		if(StrEqual(classname, "CTFBottle") && g_FirstTaunt[client])
		{
			ClearTimer(g_TauntTimer[client]);
			g_TauntTimer[client] = CreateTimer(4.3, Timer_TauntEnd, client);
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
		if(TF2_IsPlayerTaunt(client))
		{
			// 武器名取得
			new String:classname[64];
			TF2_GetCurrentWeaponClass(client, classname, 64);
			
			// グレラン
			if(StrEqual(classname, "CTFGrenadeLauncher"))
			{
				g_FirstTaunt[client] = true;
				
				// コンボタイマー発動
				ClearTimer(g_TauntChain[client]);
				g_TauntChain[client] = CreateTimer(3.0, Timer_TauntChainEnd, client);
				
			}
			else if(StrEqual(classname, "CTFBottle"))
			{
				// 時限爆弾スタート
				BomTimerStart(client);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// コンボ時間終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntChainEnd(Handle:timer, any:client)
{
	g_TauntChain[client] = INVALID_HANDLE;
	g_FirstTaunt[client] = false;
}


/////////////////////////////////////////////////////////////////////
//
// 時限爆弾スタート
//
/////////////////////////////////////////////////////////////////////
stock BomTimerStart(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// 発動
		g_HasBomb[client] = true;
		
		// フューズ着火
		ClearTimer(g_FuseEnd[client]);
		g_FuseEnd[client] = CreateTimer(GetConVarFloat(g_FuseTime), Timer_FuseEnd, client);
		//AttachParticleBone(client, "warp_version", "eyes", GetConVarFloat(g_FuseTime));

		
		// 体力全快
		//SetEntityHealth(client, TF2_GetPlayerMaxHealth(client));
		
		// 発動サウンド(歌)
		EmitSoundToAll(SOUND_DEMO_BEEP, client, _, _, SND_CHANGEPITCH, 1.0, 100);
		EmitSoundToAll(SOUND_DEMO_SING, client, _, _, SND_CHANGEPITCH, 1.0, 100);

		// 連続処理用タイマー発動
		ClearTimer(g_LoopTimer[client]);
		g_LoopTimer[client] = CreateTimer(0.05, Timer_Loop, client, TIMER_REPEAT);

		// 連続処理用タイマー発動
		ClearTimer(g_LoopVisualTimer[client]);
		g_LoopVisualTimer[client] = CreateTimer(0.8, Timer_LoopVisual, client, TIMER_REPEAT);

		
		//PrintToChat(client, "%d", GetPlayerWeaponSlot(client, 0));

		// 視界のゆれ
		//CreateDrug(client);

		
		// 背中に爆弾背負う
		g_BombModel[client] = CreateEntityByName("prop_dynamic");
		if (IsValidEdict(g_BombModel[client]))
		{
			new String:tName[32];
			GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(g_BombModel[client], "targetname", "back_bomb");
			DispatchKeyValue(g_BombModel[client], "parentname", tName);
			if( TFTeam:GetClientTeam(client) == TFTeam_Red)
			{
				SetEntityModel(g_BombModel[client], MDL_BIG_BOMB_RED);
			}
			else
			{
				SetEntityModel(g_BombModel[client], MDL_BIG_BOMB_BLU);
			}
			DispatchSpawn(g_BombModel[client]);
			SetVariantString("!activator");
			AcceptEntityInput(g_BombModel[client], "SetParent", client, client, 0);
			SetVariantString("flag");
			AcceptEntityInput(g_BombModel[client], "SetParentAttachment", client, client, 0);
			ActivateEntity(g_BombModel[client]);
			new Float:pos[3];
			new Float:ang[3];
			pos[0] = 0.0;
			pos[1] = 15.0;
			pos[2] = 15.0;
			ang[0] = 25.0;
			ang[1] = 90.0;
			ang[2] = -10.0;

			TeleportEntity(g_BombModel[client], pos, ang, NULL_VECTOR);
			//AcceptEntityInput(ent, "start");

	    }	
		g_FadeColor[client][0] = GetRandomInt(100, 180);
		g_FadeColor[client][1] = GetRandomInt(100, 180);
		g_FadeColor[client][2] = GetRandomInt(100, 180);
		ScreenFade(client, g_FadeColor[client][0], g_FadeColor[client][1], g_FadeColor[client][2], 240, 200, OUT);

		// 近接武器以外削除
		ClientCommand(client, "slot3");
		new weaponIndex;
		for(new i=0;i<3;i++)
		{
			if(i != 2)
			{
				weaponIndex = GetPlayerWeaponSlot(client, i);
				if( weaponIndex != -1 )
				{
					TF2_RemoveWeaponSlot(client, i);
					//RemovePlayerItem(client, weaponIndex);
					//AcceptEntityInput(weaponIndex, "Kill");		
				}
			}
		}				

	}	
}

/////////////////////////////////////////////////////////////////////
//
// ループタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_Loop(Handle:timer, any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_FuseEnd[client] != INVALID_HANDLE)
	{
		// 体力徐々に回復
//		new nowHealth = GetClientHealth(client);
//		nowHealth += 1;
//		if( nowHealth > TF2_GetPlayerMaxHealth(client) )
//		{
//			nowHealth = TF2_GetPlayerMaxHealth(client);
//		}
//		SetEntityHealth(client, nowHealth);

		// タックル中以外足の速さダウン
		if( !TF2_IsPlayerCharging(client) )
		{
			TF2_SetPlayerSpeed(client, TF2_GetPlayerClassSpeed(client) * GetConVarFloat(g_MoveSpeedMag));
		}
		//SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(g_MoveSpeedMag));

		// 武器再取得しないように
		// 近接武器以外削除
//		ClientCommand(client, "slot3");
//		new weaponIndex;
//		for(new i=0;i<3;i++)
//		{
//			if(i != 2)
//			{
//				weaponIndex = GetPlayerWeaponSlot(client, i);
//				if( weaponIndex != -1 )
//				{
//					//RemovePlayerItem(client, weaponIndex);
//					//RemoveEdict(weaponIndex);
//					TF2_RemoveWeaponSlot(client, i);
//				}
//			}
//		}			
		
		
		// 視界ゆれ
		new Float:angs[3];
		GetClientEyeAngles(client, angs);
		
		g_AngleDir[client] = GetRandomInt(-1,1);
		
		if( g_AngleDir[client] != 0 )
		{
//			angs[0] += GetRandomFloat(0.0,15.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
//			angs[1] += GetRandomFloat(0.0,40.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
//			angs[2] += GetRandomFloat(0.0,15.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
			angs[0] += GetRandomFloat(0.0,10.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
			angs[1] += GetRandomFloat(0.0,20.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
			angs[2] += GetRandomFloat(0.0,10.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
		}
		TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
		
		
	}
	else
	{
		ClearTimer(g_LoopTimer[client]);
		g_LoopTimer[client] = INVALID_HANDLE;
	}
}

/////////////////////////////////////////////////////////////////////
//
// ループタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_LoopVisual(Handle:timer, any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_FuseEnd[client] != INVALID_HANDLE)
	{
		if(g_FadeColor[client][0] + g_FadeColor[client][1] + g_FadeColor[client][2] == 765)
		{
			g_FadeColor[client][0] = GetRandomInt(100, 180);
			g_FadeColor[client][1] = GetRandomInt(100, 180);
			g_FadeColor[client][2] = GetRandomInt(100, 180);

			ScreenFade(client, g_FadeColor[client][0], g_FadeColor[client][1], g_FadeColor[client][2], 240, 200, OUT);
		}
		else
		{
			ScreenFade(client, g_FadeColor[client][0], g_FadeColor[client][1], g_FadeColor[client][2], 240, 200, IN);
			g_FadeColor[client][0] = 255;
			g_FadeColor[client][1] = 255;
			g_FadeColor[client][2] = 255;
		}
	}
	else
	{
		ClearTimer(g_LoopVisualTimer[client]);
		g_LoopVisualTimer[client] = INVALID_HANDLE;
	}
}

/////////////////////////////////////////////////////////////////////
//
// フューズ終了終了タイマーー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FuseEnd(Handle:timer, any:client)
{
	g_FuseEnd[client] = INVALID_HANDLE;
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// 歌とめる
		StopSound(client, 0, SOUND_DEMO_SING);
		
		//ClientCommand(client, "slot3");
		
		// 爆発エフェクト
		ExplodeEffect(client);
		
		// ダメージチェック
		RadiusDamageBuiltObject(client, 0);
		RadiusDamageBuiltObject(client, 1);
		RadiusDamageBuiltObject(client, 2);
		RadiusDamageBuiltObject(client, 3);
		RadiusDamage(client);
		
		if( g_BombModel[client] != -1 )
		{
			if( IsValidEntity(g_BombModel[client]) )
			{
				ActivateEntity(g_BombModel[client]);
				AcceptEntityInput(g_BombModel[client], "Kill");
				g_BombModel[client] = -1;
			}	
		}
		
		// 視界エフェクト削除
		//KillDrug(client);
		
		// 発動完了
		g_HasBomb[client] = false;
		// 自爆
		FakeClientCommand(client, "explode");
		 
	}
}

/////////////////////////////////////////////////////////////////////
//
// 爆発エフェクト
//
/////////////////////////////////////////////////////////////////////
stock ExplodeEffect(any:client)
{
	EmitSoundToAll(SOUND_DEMO_EXPLOSION, client, _, _, SND_CHANGEPITCH, 0.8, 200);
	new Float:ang[3];
	ang[0] = -90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;
	new Float:pos[3];
	pos[0] = 0.0;
	pos[1] = 0.0;
	pos[2] = 50.0;	
	ShowParticleEntity(client, EFFECT_EXPLODE_EMBERS, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_DEBRIS, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_INITIAL_SMOKE, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_FLAMES, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_FLASH, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_BURNINGDEBIS, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_SMOKE, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_HUGEDUSTUP, 1.0, pos, ang);
}

/////////////////////////////////////////////////////////////////////
//
// 人体へのダメージ
//
/////////////////////////////////////////////////////////////////////
stock RadiusDamage(any:client)
{
	new Float:fAttackerPos[3];
	new Float:fVictimPos[3];
	new Float:distance;
	new maxclients = GetMaxClients();

	// 被害チェック
	for (new victim = 1; victim <= maxclients; victim++)
	{
		if( IsClientInGame(victim) && IsPlayerAlive(victim) )
		{
			if( GetClientTeam(victim) != GetClientTeam(client) && victim != client )
			{

				// デモマン位置
				GetClientAbsOrigin(client, fAttackerPos);
				// 被害者位置
				GetClientAbsOrigin(victim, fVictimPos);
				// デモマンと被害者の位置
				distance = GetVectorDistanceMeter(fAttackerPos, fVictimPos);
				
				if(CanSeeTarget(victim, fVictimPos, g_BombModel[client], fAttackerPos, GetConVarFloat(g_DamageRadius), true, true))
				{
					//GetEdictClassname(HitEnt, edictName, sizeof(edictName)); 
					//PrintToChat(client,"hit = %s", edictName);
					//AttachParticleBone(victim, "conc_stars", "head",1.0);
					
					GetClientAbsOrigin(client, fAttackerPos);
					new Float:fKnockVelocity[3];	// 爆発の反動
					
					// 反動の方向取得
					SubtractVectors(fAttackerPos, fVictimPos, fKnockVelocity);
					NormalizeVector(fKnockVelocity, fKnockVelocity); 

					// 被害者のベクトル方向を取得
					new Float:fVelocity[3];
					GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
					
					
					fVelocity[2] += 400.0;
					
					// 反動を算出
					ScaleVector(fKnockVelocity, -1000.0 * (1.0 / distance)); 
					AddVectors(fVelocity, fKnockVelocity, fVelocity);
					
					// プレイヤーへの反動を設定
					SetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
							
					if( !TF2_IsPlayerInvuln(victim) && !TF2_IsPlayerBlur(client) )
					{
						new nowHealth = GetClientHealth(victim);
						nowHealth -= RoundFloat(GetConVarInt(g_BaseDamage) * (1.5 / distance));
						if(nowHealth < 0)
						{
							g_Drunker[ victim ] = client;
							FakeClientCommand(victim, "explode");
						}
						else
						{
							//PrintToChat(client, "%d", nowHealth);
							SetEntityHealth(victim, nowHealth);
							//SlapPlayer(victim, RoundFloat(800 * (1.0 / distance))); 
						}
					}						
					
				}
					
					//CloseHandle(TraceEx);					

				//}
				
			}
		}
	}	
	
}

/////////////////////////////////////////////////////////////////////
//
// 範囲ダメージ建設物
//
/////////////////////////////////////////////////////////////////////
stock RadiusDamageBuiltObject(any:client, objectType)
{
	new Float:fAttackerPos[3];
	new Float:fObjPos[3];
	new Float:distance;

	new String:edictName[64];
	// オブジェクトタイプ判別
	switch( objectType )
	{
	case 0: edictName = "obj_dispenser";
	case 1: edictName = "obj_teleporter_entrance";
	case 2: edictName = "obj_teleporter_exit";
	case 3: edictName = "obj_sentrygun";
	}
	// オブジェクト検索
	new builtObj = -1;
	while ( ( builtObj = FindEntityByClassname( builtObj, edictName ) ) != -1 )
	{
		// 持ち主チェック
		new iOwner = GetEntPropEnt( builtObj, Prop_Send, "m_hBuilder" );
		if( GetClientTeam( iOwner ) != GetClientTeam( client ) )
		{
			// アタッカーの位置
			GetClientAbsOrigin( client, fAttackerPos );
			// オブジェクトの位置取得
			GetEntPropVector( builtObj, Prop_Data, "m_vecOrigin", fObjPos );
			// アタッカーと被害者の位置
			distance = GetVectorDistanceMeter( fAttackerPos, fObjPos );
			
			// ダメージを適用
			if( CanSeeTarget( builtObj, fObjPos, g_BombModel[ client ], fAttackerPos, GetConVarFloat( g_DamageRadius ), true, true) )
			{
				new damage = RoundFloat( GetConVarInt( g_BaseDamage ) * ( 1.0 / distance ) );
				
				// そのダメージで破壊される？
				if( GetEntProp( builtObj, Prop_Send, "m_iHealth") - damage <= 0 )
				{
					// キルログに表示
					new Handle:newEvent = CreateEvent( "object_destroyed" );
					if( newEvent != INVALID_HANDLE )
					{
						SetEventInt( newEvent,		"userid",		GetClientUserId( iOwner ) );
						SetEventInt( newEvent,		"attacker",		GetClientUserId( client ) );
						SetEventInt( newEvent,		"weaponid",		0 );				
						SetEventInt( newEvent,		"index",  		builtObj );				
						SetEventInt( newEvent,		"objecttype",	objectType  );				
						SetEventString( newEvent,	"weapon",		"drunk_bomb" );
						FireEvent( newEvent );
					}						
				}				
				
				SetVariantInt( damage );
				AcceptEntityInput( builtObj, "RemoveHealth" );
				//PrintToChat(client, "%d", damage);

			}
		}
	}				
}

/////////////////////////////////////////////////////////////////////
//
// 背中の爆弾削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteBigBomb(any:client)
{
	// 爆弾のモデルを削除
	if( g_BombModel[client] != -1 && g_BombModel[client] != 0)
	{
		if( IsValidEntity(g_BombModel[client]) )
		{
			ActivateEntity(g_BombModel[client]);
			AcceptEntityInput(g_BombModel[client], "Kill");
			g_BombModel[client] = -1;
		}	
	}
}

