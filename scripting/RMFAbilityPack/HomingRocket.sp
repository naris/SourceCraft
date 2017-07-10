/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.3
// ・仕様を一部変更
// ・sm_rmf_homingrocket_battery_runtimeを追加
// ・1.3.1でコンパイル

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
#define PL_NAME			"Homing Rocket"
#define PL_DESC			"Homing Rocket"
#define PL_VERSION		"0.0.3"
#define PL_TRANSLATION	"homingrocket.phrases"

#define SOUND_PLANT_SHOVEL	"weapons/cbar_hit2.wav"
#define SOUND_PICKUP_SHOVEL	"weapons/blade_hit4.wav"
#define SOUND_SHOVEL_ACTIVE	"weapons/stickybomblauncher_det.wav"
#define SOUND_SHOVEL_LOOP	"ui/projector_movie.wav"
#define SOUND_SHOVEL_DEACTIVE	"weapons/weapon_crit_charged_off.wav"
#define SOUND_ROCKET_LAUNCH	"player/invulnerable_on.wav"

#define MDL_PLANT_SHOVEL	"models/weapons/w_models/w_shovel.mdl"
#define MDL_PLANT_LIGHT		"models/props_lights/hangingbulb.mdl"

#define EFFECT_BEAM_RED		"medicgun_beam_red_trail"
#define EFFECT_BEAM_BLU		"medicgun_beam_blue_trail"
#define EFFECT_LIGHT_RED	"cart_flashinglight_red"
#define EFFECT_LIGHT_BLU	"cart_flashinglight"

#define HOMING_ROCKETS_MAX	8	// ホーミングロケット最大数

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
new Handle:g_RocketCheckTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// ロケット発射後のチェックまでタイマー
new Handle:g_ShovelBatteryRunTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// 有効時間

new Handle:g_RocketsData[MAXPLAYERS+1][HOMING_ROCKETS_MAX];		// ロケットのデータ
new Handle:g_ShovelData[MAXPLAYERS+1] = INVALID_HANDLE;			// ショベルのデータ
new bool:g_ActiveHoming[MAXPLAYERS+1] = false;					// 発動中？
new bool:g_EndBattery[MAXPLAYERS+1] = false;					// バッテリー終了？

new Handle:g_StartAccuracy = INVALID_HANDLE;		// 開始精度
new Handle:g_FinalAccuracy = INVALID_HANDLE;		// 終了精度
new Handle:g_BatteryRunTime = INVALID_HANDLE;		// 有効時間

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
		CreateConVar("sm_rmf_tf_homingrocket", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_homingrocket","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		// CanVar
		g_StartAccuracy		= CreateConVar("sm_rmf_homingrocket_start_accuracy",	"70",	"Homing start accuracy (0-100)");
		g_FinalAccuracy		= CreateConVar("sm_rmf_homingrocket_final_accuracy",	"2", 	"Homing final accuracy (0-100)");
		g_BatteryRunTime	= CreateConVar("sm_rmf_homingrocket_battery_runtime",	"12.0",	"Homing system battery run time (0.0-120.0)");
		HookConVarChange( g_StartAccuracy, ConVarChange_Accuracy );
		HookConVarChange( g_FinalAccuracy, ConVarChange_Accuracy );
		HookConVarChange( g_BatteryRunTime , ConVarChange_Time );

		// アビリティクラス設定
		CreateConVar("sm_rmf_homingrocket_class", "3", "Ability class");

		
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			InitRocketData(i);
		}
	}

	
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			InitRocketData(i);
		}
	}
	
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ロケット用の配列ハンドル削除
			for( new j = 0; j < HOMING_ROCKETS_MAX; j++ )
			{
				if( g_RocketsData[i][j] != INVALID_HANDLE )
				{
					CloseHandle( g_RocketsData[i][j] );
				}
			}
			// ショベル用の配列削除
			if( g_ShovelData[i] != INVALID_HANDLE )
			{
				CloseHandle( g_ShovelData[i] );
			}
		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_BEAM_RED);
		PrePlayParticle(EFFECT_BEAM_BLU);
		PrePlayParticle(EFFECT_LIGHT_RED);
		PrePlayParticle(EFFECT_LIGHT_BLU);

		PrecacheSound(SOUND_PLANT_SHOVEL, true);
		PrecacheSound(SOUND_SHOVEL_DEACTIVE, true);
		PrecacheSound(SOUND_PICKUP_SHOVEL, true);
		PrecacheSound(SOUND_ROCKET_LAUNCH, true);
		PrecacheSound(SOUND_SHOVEL_LOOP, true);
		PrecacheSound(SOUND_SHOVEL_ACTIVE, true);
		
		PrecacheModel(MDL_PLANT_SHOVEL);
		PrecacheModel(MDL_PLANT_LIGHT);
	}
	
	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// ショベル削除
		DeletePlantShovel( client );
		
		// タイマークリア
		ClearTimer( g_RocketCheckTimer[client] );
		ClearTimer( g_ShovelBatteryRunTimer[client] );
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:attribute4[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_HOMINGROCKET", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_3", client, GetConVarFloat( g_BatteryRunTime ) );
			Format( attribute4, sizeof( attribute4 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_4", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
			// 3ページ目
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s\n%s", attribute3, attribute4 );
			
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
	
	// プレイヤーリサプライ
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			// ソルジャー
			if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client])
			{
				// リサプライに触ったらショベル削除
				if( g_ActiveHoming[client] )
				{
					DeletePlantShovel( client );
				}
				
			}
		}
	}

	return Plugin_Continue;
}



/////////////////////////////////////////////////////////////////////
//
// フレームごとの動作
//
/////////////////////////////////////////////////////////////////////
stock InitRocketData(any:client)
{
	// ロケット用の配列作成
	for( new i = 0; i < HOMING_ROCKETS_MAX; i++ )
	{
		if( g_RocketsData[client][i] == INVALID_HANDLE )
		{
			g_RocketsData[client][i] = CreateTrie();
		}
	}
	
	// ショベル用の配列作成
	if( g_ShovelData[client] == INVALID_HANDLE )
	{
		g_ShovelData[client] = CreateTrie();
	}	
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
		// ソルジャー
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client])
		{
			// 新たにショベル取得したら刺したショベル削除
//			if( TF2_GetItemDefIndex( GetPlayerWeaponSlot(client, 2) ) == _:ITEM_WEAPON_SHOVEL )
//			{
//				if( g_ActiveHoming[client] )
//				{
//					DeletePlantShovel( client );
//				}
//			}
			
			// ホーミングチェック
			HomingCheck(client);
			
			// キーチェック
			if( CheckElapsedTime(client, 0.5) )
			{
				// 攻撃ボタン2
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
					
					// チェック＆発動
					HomingRocket(client);
				}
			}			
		}	
	}
	
}




/////////////////////////////////////////////////////////////////////
//
// ホーミング発動(ショベルさす)
//
/////////////////////////////////////////////////////////////////////
stock HomingRocket( any:client )
{
	// 武器がスコップのとき
	if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_SHOVEL )
	{
		// 足元のエンティティ
		new groundEnt = GetEntPropEnt( client, Prop_Data, "m_hGroundEntity" );
		if( groundEnt != -1 )
		{
			if( GetEntityMoveType( groundEnt ) == MOVETYPE_VPHYSICS )
			{
				return;
			}
			
			new String:edictName[32];
			GetEdictClassname(groundEnt, edictName, sizeof(edictName));
			if (StrEqual(edictName, "player", false)
			|| StrEqual(edictName, "obj_dispenser", false)
			|| StrEqual(edictName, "obj_teleporter_entrance", false)
			|| StrEqual(edictName, "obj_teleporter_exit", false)
			|| StrEqual(edictName, "obj_sentrygun", false))
			{
				return;
			}
		}
		
		
		// 地面にいるとき
		if( GetEntityFlags( client ) & FL_ONGROUND )
		{
			// 既に設置してあるショベルを削除
			DeletePlantShovel( client );
			
			// ロケットランチャーに持ち替え、弾が無ければショットガンに。
			if( TF2_GetSlotAmmo( client, 0 ) > 0 || TF2_GetSlotClip( client, 0 ) > 0 )
			{
				ClientCommand(client, "slot1");
			}
			else
			{
				ClientCommand(client, "slot2");
			}
			
			// 持ってるショベルを削除
			new weaponIndex = GetPlayerWeaponSlot(client, 2);
			if( weaponIndex != -1)
			{
				TF2_RemoveWeaponSlot(client, 2);
				//RemovePlayerItem(client, weaponIndex);
				//AcceptEntityInput(weaponIndex, "Kill");		
			}		
				
			new bodyIndex		= -1;
			new lightIndex		= -1;
			new effectIndex		= -1;

			// 地面に刺すショベル作成
			bodyIndex = CreateEntityByName("prop_dynamic");
			if ( IsValidEntity( bodyIndex ) )
			{
				SetEntPropEnt	(bodyIndex, Prop_Send, "m_hOwnerEntity", client);	// 持ち主
				SetEntityModel	(bodyIndex, MDL_PLANT_SHOVEL);						// モデル
				DispatchSpawn	(bodyIndex);										// スポーン
				DispatchKeyValue(bodyIndex, "targetname", "homing_shovel");

				// 角度算出
				new Float:pos[3];
				new Float:ang[3];
				new Float:eang[3];
				new Float:upVec[3];
				GetClientAbsOrigin(client, pos);								// プレイヤーの位置取得
				GetClientEyeAngles(client, eang);								// 投げる角度

				ang[0] = -10.0;
				ang[1] = eang[1] + 90.0;
				ang[2] = 175.0;
				pos[2] += 20.0;
				TeleportEntity(bodyIndex, pos, ang, NULL_VECTOR);					// 移動
				
				// 地面が移動するタイプなら親を設定
				if( groundEnt != -1 )
				{
					if( GetEntityMoveType( groundEnt ) == MOVETYPE_PUSH )
					{
						SetVariantString("!activator");
						AcceptEntityInput(bodyIndex, "SetParent", groundEnt, groundEnt, 0);
					}
				}

				
				// ライト作成
				lightIndex = CreateEntityByName("prop_dynamic");
				if ( IsValidEntity( lightIndex ) )
				{
					SetEntPropEnt	(lightIndex, Prop_Send, "m_hOwnerEntity", client);	// 持ち主
					SetEntityModel	(lightIndex, MDL_PLANT_LIGHT);						// モデル
					DispatchSpawn	(lightIndex);										// スポーン
					DispatchKeyValue(lightIndex, "targetname", "homing_light");

					GetClientAbsOrigin(client, pos);								// プレイヤーの位置取得
					GetClientEyeAngles(client, eang);								// 投げる角度
					ang[0] = -10.0;
					ang[1] = eang[1] + 90.0;
					ang[2] = 175.0;
					pos[2] += 20.0;
					
					GetAngleVectors(ang, NULL_VECTOR, NULL_VECTOR, upVec);
					ScaleVector( upVec, -5.0 );
					AddVectors( pos, upVec, pos );
					TeleportEntity(lightIndex, pos, ang, NULL_VECTOR);					// 移動
					
					
					// エフェクトを生成
					if( GetClientTeam( client ) == _:TFTeam_Red )
					{
						effectIndex = AttachLoopParticle( lightIndex, EFFECT_LIGHT_RED, upVec );
					}
					else
					{
						effectIndex = AttachLoopParticle( lightIndex, EFFECT_LIGHT_BLU, upVec );
					}		

					
					// 移動の親を設定
					if( groundEnt != -1 )
					{
						if( GetEntityMoveType( groundEnt ) == MOVETYPE_PUSH )
						{
							SetVariantString("!activator");
							AcceptEntityInput(lightIndex, "SetParent", groundEnt, groundEnt, 0);
						}
					}

					// ショベルデータ設定
					SetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
					SetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
					SetTrieValue( g_ShovelData[client], "EffectIndex", effectIndex );
					
					// チェックタイマー作動

					ClearTimer( g_RocketCheckTimer[client] );
					g_RocketCheckTimer[client] = CreateTimer( 0.05, Timer_RocketCheck, client );
					
					
					// 設置音
					StopSound(bodyIndex, 0, SOUND_PLANT_SHOVEL);
					EmitSoundToAll(SOUND_PLANT_SHOVEL, bodyIndex, _, _, _, 1.0);
					StopSound(bodyIndex, 0, SOUND_SHOVEL_ACTIVE);
					EmitSoundToAll(SOUND_SHOVEL_ACTIVE, bodyIndex, _, _, SND_CHANGEPITCH, 0.5, 10);	

					// ループサウンド開始
					StopSound(bodyIndex, 0, SOUND_SHOVEL_LOOP);
					EmitSoundToAll(SOUND_SHOVEL_LOOP, bodyIndex, _, _, SND_CHANGEPITCH, 0.3, 180);				
					
					// アクティブ
					g_ActiveHoming[client] = true;
					
					// 有効時間を設定
					ClearTimer( g_ShovelBatteryRunTimer[client] );
					g_ShovelBatteryRunTimer[client] = CreateTimer( GetConVarFloat(g_BatteryRunTime), Timer_ShovelEnd, client );
				}
			}	
		}
	}
	// それ以外のとき
	else
	{
		// 近くにショベルがあったら拾う
		if( g_ActiveHoming[client] )
		{
			new bodyIndex		= -1;
			// ショベルデータ取得
			GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );

			
			new Float:playerPos[3];
			new Float:shovelPos[3];
			GetEntPropVector(client,	Prop_Data,	"m_vecAbsOrigin", playerPos);	
			GetEntPropVector(bodyIndex,	Prop_Data,	"m_vecAbsOrigin", shovelPos);
			
			// 1m以内
			if( GetVectorDistanceMeter( playerPos, shovelPos ) <= 1.0 )
			{
				// メッセージ
				if( g_EndBattery[client] )
				{
					PrintToChat( client, "\x05%T", "MESSAGE_CHANGE_BATTERY", client );
				}
				
				// 拾う音
				EmitSoundToAll(SOUND_PICKUP_SHOVEL, bodyIndex, _, _, _, 1.0);
				
				// ショベル削除
				DeletePlantShovel( client );
				
				// ショベル取得
				TF2_GiveItem( client, ITEM_WEAPON_SHOVEL );
				
				// ショベルに持ちかえる
				ClientCommand(client, "slot3");
				
				
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ショベル電池切れ
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_ShovelEnd(Handle:timer, any:client)
{
	g_ShovelBatteryRunTimer[client] = INVALID_HANDLE;
	
	if( g_ShovelData[client] == INVALID_HANDLE )
	{
		InitRocketData(client);
	}
	
	new bodyIndex;
	new lightIndex;
	new effectIndex;

	// ショベルデータ取得
	GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
	GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
	GetTrieValue( g_ShovelData[client], "EffectIndex", effectIndex );

	// エフェクト削除
	DeleteParticle( effectIndex );
	
	// ショベルを削除
	if( EdictEqual( bodyIndex, "prop_dynamic") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString(bodyIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
		
		// 設置したショベルなら
		if( StrEqual( nameTarget, "homing_shovel" ) )
		{
			// ループ音停止
			StopSound(bodyIndex, 0, SOUND_SHOVEL_LOOP);

			// 解除音
			StopSound(bodyIndex, 0, SOUND_SHOVEL_DEACTIVE);
			EmitSoundToAll(SOUND_SHOVEL_DEACTIVE, bodyIndex, _, _, SND_CHANGEPITCH, 0.3, 180);	
			// 削除
			//RemoveEdict( bodyIndex );
		}
	}

	// データクリア
//	SetTrieValue( g_ShovelData[client], "BodyIndex", -1 );
//	SetTrieValue( g_ShovelData[client], "LightIndex", -1 );
	SetTrieValue( g_ShovelData[client], "EffectIndex", -1 );

	
	// ロケットデータクリア
	for( new i = 0; i < HOMING_ROCKETS_MAX; i++ )
	{
		// 残っているエフェクト削除
		new effIndex;
		GetTrieValue( g_RocketsData[_:client][i], "Effect", effIndex )
		DeleteParticle( effIndex );
    
		// データ初期化
		SetTrieValue( g_RocketsData[client][i], "Index", -1 );		// エンティティインデックス
		SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );		// ホーミング精度
		SetTrieValue( g_RocketsData[client][i], "Effect", -1);		// エフェクト
	}
	
	// バッテリー切れ
	g_EndBattery[client] = true;
	
	// メッセージ
	PrintToChat( client, "\x05%T", "MESSAGE_OUT_OF_BATTERY", client );
}


/////////////////////////////////////////////////////////////////////
//
// ショベル削除
//
/////////////////////////////////////////////////////////////////////
stock DeletePlantShovel( client )
{
	if( g_ShovelData[client] == INVALID_HANDLE )
	{
		InitRocketData(client);
	}
	
	new bodyIndex;
	new lightIndex;
	new effectIndex;

	// ショベルデータ取得
	GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
	GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
	GetTrieValue( g_ShovelData[client], "EffectIndex", effectIndex );

	// エフェクト削除
	DeleteParticle( effectIndex );
	
	// ショベルを削除
	if( EdictEqual( bodyIndex, "prop_dynamic") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString(bodyIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
		
		// 設置したショベルなら削除
		if( StrEqual( nameTarget, "homing_shovel" ) )
		{
			if( !g_EndBattery[client] )
			{
				// ループ音停止
				StopSound(bodyIndex, 0, SOUND_SHOVEL_LOOP);

				// 解除音
				StopSound(bodyIndex, 0, SOUND_SHOVEL_DEACTIVE);
				EmitSoundToAll(SOUND_SHOVEL_DEACTIVE, bodyIndex, _, _, SND_CHANGEPITCH, 0.3, 180);	
			}
			else
			{
				ClearTimer( g_ShovelBatteryRunTimer[client] );
			}
			
			// 削除
			AcceptEntityInput(bodyIndex, "Kill");
		}
	}

	// ライトを削除
	if( EdictEqual( lightIndex, "prop_dynamic") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString(lightIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
		
		// 設置したショベルなら削除
		if( StrEqual( nameTarget, "homing_light" ) )
		{
			// 削除
			AcceptEntityInput(lightIndex, "Kill");		
		}
	}
	
	// データクリア
	SetTrieValue( g_ShovelData[client], "BodyIndex", -1 );
	SetTrieValue( g_ShovelData[client], "LightIndex", -1 );
	SetTrieValue( g_ShovelData[client], "EffectIndex", -1 );

	
	// ロケットデータクリア
	for( new i = 0; i < HOMING_ROCKETS_MAX; i++ )
	{
		// 残っているエフェクト削除
		new effIndex;
		GetTrieValue( g_RocketsData[_:client][i], "Effect", effIndex )
		DeleteParticle( effIndex );
    
		// データ初期化
		SetTrieValue( g_RocketsData[client][i], "Index", -1 );		// エンティティインデックス
		SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );		// ホーミング精度
		SetTrieValue( g_RocketsData[client][i], "Effect", -1);		// エフェクト
	}
	
	// 電池切れタイマー削除
	ClearTimer( g_ShovelBatteryRunTimer[client] );
	
	// 非アクティブ
	g_ActiveHoming[client] = false;
	g_EndBattery[client] = false;
}

/////////////////////////////////////////////////////////////////////
//
// ホーミングロケット
//
/////////////////////////////////////////////////////////////////////
stock HomingCheck(any:client)
{
	if( g_ActiveHoming[client] && g_RocketCheckTimer[client] == INVALID_HANDLE)
	{
		new bodyIndex		= -1;
		new lightIndex		= -1;
		// ショベルデータ取得
		GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
		GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
		
		if( EdictEqual( bodyIndex, "prop_dynamic") )
		{
			new String:nameTarget[64];
			GetEntPropString( bodyIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
			
			// 設置したショベルがある！
			if( StrEqual( nameTarget, "homing_shovel" ) )
			{
				new Float:RocketPos[3];	// ロケットの位置
				new Float:RocketAng[3];	// ロケットの角度
				new Float:RocketVec[3];	// ロケットの方向
				
				new Float:TargetPos[3];		// ターゲットの位置
				new Float:TargetVec[3];		// ターゲットへの方向
				
				new Float:MiddleVec[3];		// 中間ベクトル
				
				// ショベルの位置取得
				GetEntPropVector( lightIndex, Prop_Data, "m_vecAbsOrigin", TargetPos );
				
				
				// ロケットリスト
				for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
				{
					new index;				
					new accuracy;				
					GetTrieValue( g_RocketsData[client][i], "Index", index );
					GetTrieValue( g_RocketsData[client][i], "Accuracy", accuracy );
					// 発射されたロケットがある？
					if( EdictEqual( index, "tf_projectile_rocket") )
					{
						// 持ち主は自分か
						new iOwner = GetEntPropEnt( index, Prop_Send, "m_hOwnerEntity" );
						if( client == iOwner )
						{
							// ロケットのデータ読み込み
							GetEntPropVector( index, Prop_Data, "m_vecAbsOrigin", RocketPos );		// ロケットの位置
							GetEntPropVector( index, Prop_Data, "m_angRotation", RocketAng );		// ロケットの角度
							GetEntPropVector( index, Prop_Data, "m_vecAbsVelocity", RocketVec );	// ロケットの方向

							new Float:RocketSpeed = GetVectorLength( RocketVec ); // ロケットのスピード
							
							// ロケットとターゲットの角度を調べる
							SubtractVectors( TargetPos, RocketPos, TargetVec );	// ターゲットまでの方向 
							
							// ロケットの精度調整
							AddVectors( RocketVec, TargetVec, MiddleVec );
							for( new j=0; j < accuracy; j++ )
							{
								AddVectors( RocketVec, MiddleVec, MiddleVec );
							}
							AddVectors( RocketVec, MiddleVec, RocketVec );
							
							NormalizeVector( RocketVec, RocketVec );
							
							// ロケットの角度を上書き
							GetVectorAngles( RocketVec, RocketAng );
							SetEntPropVector( index, Prop_Data, "m_angRotation", RocketAng);

							// ロケットの方向を上書き
							ScaleVector( RocketVec, RocketSpeed );
							SetEntPropVector( index, Prop_Data, "m_vecAbsVelocity", RocketVec );
							
							if(accuracy > GetConVarInt(g_FinalAccuracy))
							{
								accuracy -= 1;
							}
							SetTrieValue( g_RocketsData[client][i], "Accuracy", accuracy );
						}								
					}
					
				}
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

	// ソルジャーのときのみ
	if( TF2_GetPlayerClass(client) == TFClass_Soldier )
	{
		// ロケットランチャー
		if( StrEqual( weaponname, "tf_weapon_rocketlauncher") || StrEqual( weaponname, "tf_weapon_rocketlauncher_directhit"))
		{
			if( g_ActiveHoming[client] )
			{
				// チェックしない時間設定
				ClearTimer( g_RocketCheckTimer[client] );
				g_RocketCheckTimer[client] = CreateTimer( 0.05, Timer_RocketCheck, client );
			}
		}
		
	}
	

	return Plugin_Continue;	
}

/////////////////////////////////////////////////////////////////////
//
// ロケットチェック
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_RocketCheck(Handle:timer, any:client)
{
	g_RocketCheckTimer[client] = INVALID_HANDLE;
	
	if( g_ActiveHoming[client] && !g_EndBattery[client] )
	{
		// ロケットじゃないものはクリア
		for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
		{		
			new bool:valid = true;
			
			new index;				
			// データがロケットかチェック
			GetTrieValue( g_RocketsData[client][i], "Index", index );			
			
			if( !EdictEqual( index, "tf_projectile_rocket") )
			{
				valid = false;
			}
			else
			{
				// ターゲット名取得取得
				new String:nameTarget[64];
				GetEntPropString(index, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
				if( !StrEqual( nameTarget, "homing_rocket" ) )
				{
					valid = false;
				}
				
			}
			
			if( !valid )
			{
				new effect;
				// エフェクトを削除
				GetTrieValue( g_RocketsData[client][i], "Effect", effect);	
				DeleteParticle(effect);
				
				// データをクリア
				SetTrieValue( g_RocketsData[client][i], "Index", -1 );									// エンティティインデックス
				SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );	// ホーミング精度	
				SetTrieValue( g_RocketsData[client][i], "Effect", -1);									// エフェクト				
				//PrintToChat(client, "rocket = %d", index)				
			}
		}
		
		new lightIndex		= -1;
		// ショベルデータ取得
		GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
		StopSound(lightIndex, 0, SOUND_SHOVEL_ACTIVE);
		EmitSoundToAll(SOUND_SHOVEL_ACTIVE, lightIndex, _, _, SND_CHANGEPITCH, 0.5, 10);	

		// ロケットを検索
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1)
		{
			// 発射した奴のみ
			new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
			if(client == iOwner)
			{
				// データが登録されているかチェック
				new bool:hasData = false;
				for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
				{				
					new index;				
					GetTrieValue( g_RocketsData[client][i], "Index", index );
					// ヒット？
					if( ent == index )
					{
						hasData = true;
					}
				}
				
				// ヒットなしならデータ登録
				if( !hasData )
				{
					// あいてる場所を探して登録
					for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
					{				
						new index;				
						GetTrieValue( g_RocketsData[client][i], "Index", index );
						if( index == -1 )
						{
							// 判別用の名前
							DispatchKeyValue(ent, "targetname", "homing_rocket");
							
							// 空きが見つかったら登録
							SetTrieValue( g_RocketsData[client][i], "Index", ent );									// エンティティインデックス
							SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );		// ホーミング精度	
							
							// エフェクト生成
							new effect;
							if( GetClientTeam( client ) == _:TFTeam_Red )
							{
								effect = AttachLoopParticle( ent, EFFECT_BEAM_RED );
							}
							else
							{
								effect = AttachLoopParticle( ent, EFFECT_BEAM_BLU );
							}
							SetEntPropEnt(effect, Prop_Data, "m_hControlPointEnts", lightIndex);
							
							SetTrieValue( g_RocketsData[client][i], "Effect", effect);			// エフェクト	
							
							StopSound(ent, 0, SOUND_ROCKET_LAUNCH);
							EmitSoundToAll(SOUND_ROCKET_LAUNCH, ent, _, _, SND_CHANGEPITCH, 0.5, 80);	

							break;
						}
					}
				}
				
			}
		}
	}
}


/////////////////////////////////////////////////////////////////////
//
// 精度
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Accuracy(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0～100まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 100");
	}
}
