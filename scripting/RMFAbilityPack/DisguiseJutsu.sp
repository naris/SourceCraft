/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2009/03/01 - 0.0.4
// ・1.3.1でコンパイル
// ・チャージをロッカーで回復できるようにした。
// 2009/10/06 - 0.0.2
// ・内部処理を変更
// 2009/09/05 - 0.0.1
// ・サーバーに入って最初の復活の際、画面が観戦モードのようになるのを修正

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
#define PL_NAME "Disguise Jutsu"
#define PL_DESC "Disguise Jutsu"
#define PL_VERSION "0.0.4"
#define PL_TRANSLATION "disguisejutsu.phrases"

#define MDL_WOODEN_BARREL "models/props_farm/wooden_barrel.mdl"

//#define SOUND_SPAWN_BARREL "player/pl_impact_stun.wav"
#define SOUND_SPAWN_BARREL "items/pumpkin_drop.wav"
//#define SOUND_CHARGE_POWER "ui/item_acquired.wav"
#define SOUND_CHARGE_POWER "player/recharged.wav"
#define SOUND_NO_POWER "weapons/medigun_no_target.wav"

#define EFFECT_BARREL_SPAWN_SMOKE "Explosion_Smoke_1"
#define EFFECT_BARREL_SPAWN_FLASH "Explosion_Flash_1"

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
new Handle:g_ChargeTime = INVALID_HANDLE;						// ConVarチャージ時間

new g_BarrelModel[MAXPLAYERS+1] = -1;			// モデル
new g_IsBarrelActive[MAXPLAYERS+1] = -1;		// 樽の中？
new Handle:g_HideVoicehTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// ボイスタイマー
new Handle:g_PowerChargeTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// パワーチャージタイマー
new String:SOUND_START_VOICE[5][64];							// 隠れ開始ボイス
new String:SOUND_HIDE_VOICE[5][64];								// 隠れボイス
new String:SOUND_UNHIDE_VOICE[5][64];							// 登場ボイス
new HideVoiceCount = 0;											// ボイスカウント
new g_NowHealth[MAXPLAYERS+1] = 0; 								// 現在のヘルス
new Float:g_NextUseTime[MAXPLAYERS+1] = 0.0; 					// 次に使えるようになるまでの時間

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
		CreateConVar("sm_rmf_tf_disguisejutsu", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_disguisejutsu","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		g_ChargeTime = CreateConVar("sm_rmf_disguisejutsu_charge_time","15.0","Pyro Power charge time (1.0-60.0)");
		HookConVarChange(g_ChargeTime, ConVarChange_Time);
		
		// 回復棚にタッチ
//		HookEntityOutput("func_regenerate",  "m_OnStartTouch",    EntityOutput_StartTouch);

		// アビリティクラス設定
		CreateConVar("sm_rmf_disguisejutsu_class", "7", "Ability class");
		
		// 隠れボイス
		SOUND_HIDE_VOICE[0] = "vo/pyro_laughevil02.wav";
		SOUND_HIDE_VOICE[1] = "vo/pyro_autoonfire02.wav";
		SOUND_HIDE_VOICE[2] = "vo/pyro_laughevil04.wav";
		SOUND_HIDE_VOICE[3] = "vo/pyro_goodjob01.wav";
		SOUND_HIDE_VOICE[4] = "vo/pyro_laughevil03.wav";
		// 登場ボイス
		SOUND_UNHIDE_VOICE[0] = "vo/pyro_battlecry01.wav";
		SOUND_UNHIDE_VOICE[1] = "vo/pyro_battlecry02.wav";
		SOUND_UNHIDE_VOICE[2] = "vo/pyro_cheers01.wav";
		SOUND_UNHIDE_VOICE[3] = "vo/pyro_helpme01.wav";
		SOUND_UNHIDE_VOICE[4] = "vo/pyro_laughevil01.wav";
		// 隠れ開始ボイス
		SOUND_START_VOICE[0] = "vo/pyro_positivevocalization01.wav";
		SOUND_START_VOICE[1] = "vo/pyro_specialcompleted01.wav";
		SOUND_START_VOICE[2] = "vo/pyro_standonthepoint01.wav";
		SOUND_START_VOICE[3] = "vo/pyro_autocappedintelligence01.wav";
		SOUND_START_VOICE[4] = "vo/pyro_autodejectedtie01.wav";

	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// モデル削除
			DeleteModel(client)
			
			
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// モデル削除
			DeleteModel(client)
		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		// エフェクト先読み
		PrePlayParticle(EFFECT_BARREL_SPAWN_SMOKE);
		PrePlayParticle(EFFECT_BARREL_SPAWN_FLASH);

		// モデル読み込み
		PrecacheModel(MDL_WOODEN_BARREL, true);
		
		//サウンド読み込み
		PrecacheSound(SOUND_SPAWN_BARREL, true);
		PrecacheSound(SOUND_CHARGE_POWER, true);
		PrecacheSound(SOUND_NO_POWER, true);
		for( new i = 0; i < 5; i++)
		{
			PrecacheSound(SOUND_HIDE_VOICE[i], true);
			PrecacheSound(SOUND_UNHIDE_VOICE[i], true);
			PrecacheSound(SOUND_START_VOICE[i], true);
		}
		
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// モデル削除
			DeleteModel(client)
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

	
	// プレイヤーリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// 速度戻す
		TF2_SetPlayerDefaultSpeed(client);

		// 次に使えるまでの時間リセット
		g_NextUseTime[client] = 0.0;
		
		// ボイスタイマー停止
		ClearTimer(g_HideVoicehTimer[client]);
		
		// パワーチャージタイマー停止
		ClearTimer(g_PowerChargeTimer[client]);
		
		// ボイスカウントリセット
		HideVoiceCount = 0;
		
		// 現在のヘルス保存
		g_NowHealth[client] = GetClientHealth(client);
		
		// 見える
		SetPlayerRenderHide(client, false);

		// 視点を戻す
		//SetClientViewEntity(client, client);
		//SetEntProp(client, Prop_Send, "m_iObserverMode", 0);

		// モデル削除
		DeleteModel(client);
		
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];


			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_DISGUISEJUTSU", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_DISGUISEJUTSU_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_DISGUISEJUTSU_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_DISGUISEJUTSU_ATTRIBUTE_2", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );

		}
		
	}
	

	// プレイヤーダメージ
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		// パイロ
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro )
		{
			// 樽の中に入っている
			if(g_IsBarrelActive[client])
			{
				// 食らったダメージ取得
				new damage = g_NowHealth[client] - GetEventInt(event, "health");
				
				// 50以上のダメージを受けたら解除
				if( damage > 50 )
				{
					// ボイスタイマー停止
					ClearTimer(g_HideVoicehTimer[client]);

					// 見える
					SetPlayerRenderHide(client, false);

					// 視点を戻す
					SetEntProp(client, Prop_Send, "m_iObserverMode", 0);

					// モデル削除
					DeleteModel(client);
					
					// 速度戻す
					TF2_SetPlayerDefaultSpeed(client);
		
					// 次に使用可能になるまでの時間設定
					g_NextUseTime[client] = GetGameTime() + GetConVarFloat(g_ChargeTime);
								
					// パワーチャージタイマー発動
					ClearTimer(g_PowerChargeTimer[client]);
					g_PowerChargeTimer[client] = CreateTimer(GetConVarFloat(g_ChargeTime), Timer_PowerChargeTimer, client);
								
				}
			}
		}
	}	
	
	// プレイヤーリサプライ
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		// パイロ
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro && g_AbilityUnlock[client] )
		{
			// ロッカーに触るとチャージ
			if( g_PowerChargeTimer[client] != INVALID_HANDLE )
			{
				ClearTimer(g_PowerChargeTimer[client]);
				Timer_PowerChargeTimer( INVALID_HANDLE, client );
			}

		}
	}

	return Plugin_Continue;
}



/////////////////////////////////////////////////////////////////////
//
// フレームアクション
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// パイロのみ
		if(TF2_GetPlayerClass(client) == TFClass_Pyro && g_AbilityUnlock[client])
		{
			// 発動中なら終了チェック
			if( g_IsBarrelActive[client] )
			{
				//AdjustCameraPos(client);
				// 終了チェック
				EndCheck(client);
			}
			
			// キーチェック
			if( CheckElapsedTime(client, 0.5) )
			{
				// 攻撃ボタン
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
					DisguiseJutsu(client);
				}

			}
		}
	}
}
/////////////////////////////////////////////////////////////////////
//
// 樽出現
//
/////////////////////////////////////////////////////////////////////
stock DisguiseJutsu(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// 武器はバックバーナーのみ
		//new weaponIndex = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_BACKBURNER )
		{
			// 発動していなかったら発動
			if( !g_IsBarrelActive[client]  )
			{
				// まだ使えないならメッセージ
				if( g_NextUseTime[client] > GetGameTime() )
				{
					EmitSoundToClient(client, SOUND_NO_POWER, client, _, _, _, 1.0);
					PrintToChat(client, "\x05%T", "MESSAGE_NO_CHARGE", client, g_NextUseTime[client] - GetGameTime());
					return;
				}
				
				// しゃがんだ状態・地上・移動していない
				if( GetEntityFlags(client) & FL_DUCKING
					&& GetEntityFlags(client) & FL_ONGROUND
					&& !(GetEntityFlags(client) & FL_INWATER)
					&& TF2_GetPlayerSpeed(client) == 0.0
				)
				{
					// 発動エフェクト
					new Float:pos[3];
					new Float:ang[3];
					ang[0] = -90.0;
					pos[2] = -30.0;
					
					AttachParticle(client, EFFECT_BARREL_SPAWN_FLASH, 1.0, pos, ang);
					for(new i = 0; i < 10; i++)
					{
						pos[0] = GetRandomFloat(-5.0, 5.0);
						pos[1] = GetRandomFloat(-5.0, 5.0);
						AttachParticle(client, EFFECT_BARREL_SPAWN_SMOKE, 1.0, pos, ang);
					}
					
					// 画面を一瞬灰色に。
					ScreenFade(client, 50, 50, 50, 255, 100, IN);
					
					// 発動サウンド
					//EmitSoundToAll(SOUND_SPAWN_BARREL, client, _, _, SND_CHANGEPITCH, 0.8, 50);
					EmitSoundToAll(SOUND_SPAWN_BARREL, client, _, _, SND_CHANGEPITCH, 1.0, 55);
					EmitSoundToAll(SOUND_START_VOICE[GetRandomInt(0, 4)], client, _, _, _, 1.0);
					
					// 樽モデル作成
					g_BarrelModel[client] = CreateEntityByName("prop_dynamic");
					if (IsValidEdict(g_BarrelModel[client]))
					{
						new String:tName[32];
						GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
						DispatchKeyValue(g_BarrelModel[client], "targetname", "pyro_barrel");
						DispatchKeyValue(g_BarrelModel[client], "parentname", tName);
						SetEntityModel(g_BarrelModel[client], MDL_WOODEN_BARREL);
						DispatchSpawn(g_BarrelModel[client]);
						SetVariantInt(99999);
						AcceptEntityInput(g_BarrelModel[client], "SetHealth");	
						// モデルをプレイヤーの位置に移動
						new Float:Pos[3];
						GetClientAbsOrigin(client, Pos);
						Pos[2] += 30.0;
						TeleportEntity(g_BarrelModel[client], Pos, NULL_VECTOR, NULL_VECTOR);
						
				    }	
					
					// プレイヤーを見えなくする
					SetPlayerRenderHide(client, true);

					// 視点が変わらないよう前の死体を消す
					new body = -1;
					while ((body = FindEntityByClassname(body, "tf_ragdoll")) != -1)
					{
						//PrintToChat(client, "%d %d",client, GetEntProp(body, Prop_Send, "m_iPlayerIndex"));
						new iOwner = GetEntProp(body, Prop_Send, "m_iPlayerIndex");
						if(iOwner == client)
						{
							AcceptEntityInput(body, "Kill");
						}
					}

					// 三人称視点
					SetEntPropEnt(client, Prop_Data, "m_hObserverTarget", client);
					SetEntProp(client, Prop_Data, "m_iObserverMode", 1);
				
					// ボイスタイマー発動
					ClearTimer(g_HideVoicehTimer[client]);
					g_HideVoicehTimer[client] = CreateTimer(3.5, Timer_HideVoiceTimer, client, TIMER_REPEAT);
					
					// ボイスカウントリセット
					HideVoiceCount = 0;

					// 現在のヘルスを保存
					g_NowHealth[client] = GetClientHealth(client);

					// 樽の中に入った
					g_IsBarrelActive[client] = true;
				}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// 隠れさせる(見えなくする)
//
/////////////////////////////////////////////////////////////////////
stock SetPlayerRenderHide(any:client, bool:hide)
{
	// 透明にする
	if( hide )
	{
		// プレイヤー
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 0);
		
		// 武器
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
				SetEntityRenderMode(weaponIndex, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weaponIndex, 255, 255, 255, 0);
			}
		}	
		
		// 帽子
		new hat = -1;
		while ((hat = FindEntityByClassname(hat, "tf_wearable_item")) != -1)
		{
			new iOwner = GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				SetEntityRenderMode(hat, RENDER_TRANSCOLOR);
				SetEntityRenderColor(hat, 255, 255, 255, 0);
			}
		}
	}
	else
	{
		// プレイヤー
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		// 武器
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
				SetEntityRenderMode(weaponIndex, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weaponIndex, 255, 255, 255, 255);
			}
		}		
		
		// 帽子
		new hat = -1;
		while ((hat = FindEntityByClassname(hat, "tf_wearable_item")) != -1)
		{
			new iOwner = GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				SetEntityRenderMode(hat, RENDER_TRANSCOLOR);
				SetEntityRenderColor(hat, 255, 255, 255, 255);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ボイスタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_HideVoiceTimer(Handle:timer, any:client)
{
	// 発動中ならチェック
	if(g_IsBarrelActive[client])
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			EmitSoundToAll(SOUND_HIDE_VOICE[HideVoiceCount], client, _, _, _, 1.0);
			HideVoiceCount++;
			if(HideVoiceCount > 4)
			{
				HideVoiceCount = 0;
			}
			
		}
	}
	else
	{
		// ボイスタイマー削除
		ClearTimer(g_HideVoicehTimer[client]);
	}

}

/////////////////////////////////////////////////////////////////////
//
// 発動終了チェック
//
/////////////////////////////////////////////////////////////////////
stock EndCheck(any:client)
{
	// 移動・攻撃または立つ・地上以外は解除
	if(// GetClientButtons(client) & IN_FORWARD
//		|| GetClientButtons(client) & IN_BACK
//		|| GetClientButtons(client) & IN_MOVELEFT
//		|| GetClientButtons(client) & IN_MOVERIGHT
		 GetClientButtons(client) & IN_ATTACK 
		|| GetEntityFlags(client) & FL_INWATER 
		|| !(GetEntityFlags(client) & FL_DUCKING)
		|| !(GetEntityFlags(client) & FL_ONGROUND)
	) 
	{
		// ボイスタイマー停止
		ClearTimer(g_HideVoicehTimer[client]);

		// プレイヤーが解除したならボイス出す
		if( IsPlayerAlive(client) && GetEntityFlags(client) & FL_ONGROUND && !TF2_IsPlayerTaunt(client))
		{
			EmitSoundToAll(SOUND_UNHIDE_VOICE[GetRandomInt(0, 4)], client, _, _, _, 1.0);
		}
		
		// 見える
		SetPlayerRenderHide(client, false);

		// 視点を戻す
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		
		// モデル削除
		DeleteModel(client);
		
		// 速度戻す
		TF2_SetPlayerDefaultSpeed(client);
		
		// 次に使用可能になるまでの時間設定
		g_NextUseTime[client] = GetGameTime() + GetConVarFloat(g_ChargeTime);
				
		// パワーチャージタイマー発動
		ClearTimer(g_PowerChargeTimer[client]);
		g_PowerChargeTimer[client] = CreateTimer(GetConVarFloat(g_ChargeTime), Timer_PowerChargeTimer, client);
		
		
	}
	else
	{
		// もしプレイヤーが移動したら樽も移動
		if( g_BarrelModel[client] != -1 && g_BarrelModel[client] != 0)
		{
			if( IsValidEntity(g_BarrelModel[client]) )
			{
				new Float:Pos[3];
				GetClientAbsOrigin(client, Pos);
				Pos[2] += 30.0;
				TeleportEntity(g_BarrelModel[client], Pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
		
		
		// 移動速度落とす
		TF2_SetPlayerSpeed(client, 0.5);
		
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// パワーチャージ完了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_PowerChargeTimer(Handle:timer, any:client)
{
	g_PowerChargeTimer[client] = INVALID_HANDLE;
	
	// 次に使える時間リセット
	g_NextUseTime[client] = GetGameTime()
	
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		PrintToChat(client, "\x05%T", "MESSAGE_POWER_CHARGED", client);
		EmitSoundToClient(client, SOUND_CHARGE_POWER, client, _, _, _, 1.0);
	}
}

/////////////////////////////////////////////////////////////////////
//
// 樽破壊
//
/////////////////////////////////////////////////////////////////////
stock BreakBarrel(any:client)
{
	// 樽の破片
	new gibModel = CreateEntityByName("prop_physics_override");
	if (IsValidEdict(gibModel))
	{
		SetEntityModel(gibModel, MDL_WOODEN_BARREL);
		DispatchSpawn(gibModel);
		
		// モデルをプレイヤーの位置に移動
		new Float:pos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos);
		pos[2] += 30.0;
		new Float:ang[3];
		GetClientEyeAngles(client, ang);
		ang[0] = 0.0;
		ang[1] += 40.0;
		ang[2] = 0.0;
		TeleportEntity(gibModel, pos, ang, NULL_VECTOR);
		AcceptEntityInput(gibModel, "Break");
		AcceptEntityInput(gibModel, "Kill");
	}	
}
/////////////////////////////////////////////////////////////////////
//
// ロッカータッチ
//
/////////////////////////////////////////////////////////////////////
//public EntityOutput_StartTouch( const String:output[], caller, activator, Float:delay )
//{
//	PrintToServer("Touch");
//	PrintToChat(activator, "Touch");
//	if(TF2_EdictNameEqual(activator, "player"))
//	{
//		// 次に使用可能になるまでの時間設定
//		g_NextUseTime[activator] = GetGameTime();
//		Timer_PowerChargeTimer(g_PowerChargeTimer[activator], activator);
//	}
//}



/////////////////////////////////////////////////////////////////////
//
// モデル削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteModel(any:client)
{
	// モデルを削除
	if( g_BarrelModel[client] != -1 && g_BarrelModel[client] != 0)
	{
		if( IsValidEntity(g_BarrelModel[client]) )
		{
			// 樽破壊
			BreakBarrel(client);
			
//			ActivateEntity(g_BarrelModel[client]);
//			RemoveEdict(g_BarrelModel[client]);
			AcceptEntityInput( g_BarrelModel[ client ], "Kill" );
			g_BarrelModel[client] = -1;
		}	
	}
	
	g_IsBarrelActive[client] = false;
}

