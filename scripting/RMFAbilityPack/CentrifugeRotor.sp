/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.7
// ・1.3.1でコンパイル
// ・仕様を一部変更
// ・sm_rmf_centrifugerotor_movement_speed_magを追加
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
#define PL_NAME "Centrifuge Rotor"
#define PL_DESC "Centrifuge Rotor"
#define PL_VERSION "0.0.7"
#define PL_TRANSLATION "centrifugerotor.phrases"

#define SOUND_ROTER_ON "ui/projector_screen_down.wav"
#define SOUND_ROTER_OFF "ui/projector_screen_up.wav"
#define SOUND_ROTER_OFF2 "weapons/syringegun_reload_air2.wav"

#define EFFECT_ACTIVE	"ghost_flash"
#define EFFECT_DEACTIVE	"Explosions_UW_Debris001"



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
new Handle:g_ConVarGravityMag = INVALID_HANDLE;			// ConVarセントリフュージロータの重力
new Handle:g_ConVarSpeedMag = INVALID_HANDLE;			// ConVarセントリフュージロータの移動倍りうt
new bool:g_RoterState[MAXPLAYERS+1] = false;		// セントリフュージロータの状態

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
		CreateConVar("sm_rmf_tf_centrifugerotor", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_centrifugerotor","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// ヘビー
		g_ConVarGravityMag = CreateConVar("sm_rmf_centrifugerotor_gravity",				"10.0",	"Generate gravity (0.0-10.0)");
		HookConVarChange(g_ConVarGravityMag, ConVarChange_Magnification);
		g_ConVarSpeedMag = CreateConVar("sm_rmf_centrifugerotor_movement_speed_mag",	"0.6",	"Movement speed magnification (0.0-10.0)");
		HookConVarChange(g_ConVarSpeedMag, ConVarChange_Magnification);
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_centrifugerotor_class", "6", "Ability class");
		
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_ACTIVE);
		PrePlayParticle(EFFECT_DEACTIVE);
		
		PrecacheSound(SOUND_ROTER_ON, true);
		PrecacheSound(SOUND_ROTER_OFF, true);
		PrecacheSound(SOUND_ROTER_OFF2, true);
	}

	// プレイヤーデータリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// 重力を元に戻す。
		SetEntityGravity(client,0.0);
		// カラー元に戻す。
		SetEntityRenderColor(client, 255, 255, 255, 255);
		// 重力装置OFF
		g_RoterState[client]=false;
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:percentage[16];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_CENTRIFUGEROTOR", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_1", client );
			GetPercentageString( GetConVarFloat( g_ConVarGravityMag ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_2", client, percentage );
			GetPercentageString( GetConVarFloat( g_ConVarSpeedMag ), percentage, sizeof( percentage ) )
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_3", client, percentage );
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s\n%s", attribute1, attribute2, attribute3 );
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
		// ヘビー
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy && g_AbilityUnlock[client] )
		{
			// ミニガンのみ
			if(TF2_CurrentWeaponEqual(client, "CTFMinigun"))
			{
				if( (g_RoterState[client] &&  CheckElapsedTime(client, 0.4)) || (!g_RoterState[client] && CheckElapsedTime(client, 0.1)))
				{
					// アタック2
					if (GetClientButtons(client) & IN_ATTACK2 )
					{
						
						// キーを押した時間を保存
						SaveKeyTime(client);

						
						// 重力変更
						if( GetEntityFlags(client) & FL_ONGROUND /* && GetEntityFlags(client) & FL_DUCKING */ )
						{
							ChangeRoterState(client, true);
						}
						else
						{
							ChangeRoterState(client, false);
						}
					}
					else
					{
						ChangeRoterState(client, false);
					}
					
				}
			}
			else
			{
				ChangeRoterState(client, false);
			}
		}	
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// レンダーカラー変更
//
/////////////////////////////////////////////////////////////////////
stock SetPlayerRenderColor(any:client, bool:enable)
{
	// 色を変更
	if( enable )
	{
		new r,g,b;
		if( GetClientTeam( client ) == _:TFTeam_Red )
		{
			r = 120;
			g = 80;
			b = 80;
		}
		else
		{
			r = 100;
			g = 100;
			b = 220;
		}	
		
		// プレイヤー
		SetEntityRenderColor(client, r, g, b, 255);
		
		// 武器
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
				SetEntityRenderColor(weaponIndex, r, g, b, 255);
			}
		}	
		
		// 帽子
		new hat = -1;
		while ((hat = FindEntityByClassname(hat, "tf_wearable_item")) != -1)
		{
			new iOwner = GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				SetEntityRenderColor(hat, r, g, b, 255);
			}
		}
	}
	else
	{
		// プレイヤー
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		// 武器
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
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
				SetEntityRenderColor(hat, 255, 255, 255, 255);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ヘビー重力発生変更
//
/////////////////////////////////////////////////////////////////////
stock ChangeRoterState(any:client, bool:roterState)
{
	if( roterState )	//ONにする
	{
		// 最初だけ起動音
		if( !g_RoterState[client] )	
		{
			SetPlayerRenderColor( client, true );	
			
			// パーティクル
			new Float:pos[3];
			GetClientAbsOrigin( client, pos );
			pos[2] += 30.0;
			// パーティクル
			//AttachParticleBone(client, EFFECT_ACTIVE, "head", 1.0, pos);
  			TE_Particle( EFFECT_ACTIVE, pos, _, _,client);
			new maxclients = GetMaxClients();
			for ( new i = 1; i <= maxclients; i++ )
			{
				if( IsClientInGame( i ) && i != client && !IsFakeClient( i ) )
				{
					TE_SendToClient( i );
				}
			}
			
			// 起動音
			EmitSoundToAll(SOUND_ROTER_ON, client, _, _, SND_CHANGEPITCH, 1.00, 45);
			
			// 重力
			SetEntityGravity( client, GetConVarFloat( g_ConVarGravityMag ) );

			// 速度
			TF2_SetPlayerSpeed( client, TF2_GetPlayerClassSpeed( client ) * GetConVarFloat( g_ConVarSpeedMag ) );
			
			// ON
			g_RoterState[client] = true;
			
		}
		else
		{
			// 重力
			SetEntityGravity( client, GetConVarFloat( g_ConVarGravityMag ) );

			// 速度
			TF2_SetPlayerSpeed( client, TF2_GetPlayerClassSpeed( client ) * GetConVarFloat( g_ConVarSpeedMag ) );
			
		}
	}
	else		//OFFにする
	{
		// 効果切れたときだけ起動音
		if( g_RoterState[client] )	
		{
			// 起動音
			EmitSoundToAll(SOUND_ROTER_OFF, client, _, _, SND_CHANGEPITCH, 0.50, 40);
			EmitSoundToAll(SOUND_ROTER_OFF2, client, _, _, SND_CHANGEPITCH, 1.00, 25);
			
			// パーティクル
			new Float:pos[3];
			GetClientAbsOrigin( client, pos );
			pos[2] += 30.0;
			// パーティクル
			//AttachParticleBone(client, EFFECT_ACTIVE, "head", 1.0, pos);
  			TE_Particle( EFFECT_ACTIVE, pos, _, _,client);
			new maxclients = GetMaxClients();
			for ( new i = 1; i <= maxclients; i++ )
			{
				if( IsClientInGame( i ) && i != client && !IsFakeClient( i ) )
				{
					TE_SendToClient( i );
				}
			}
			// パーティクル
			ShowParticleEntity(client, EFFECT_DEACTIVE, 1.0);

			// 色戻す
			//SetEntityRenderColor(client, 255, 255, 255, 255);
			
			SetPlayerRenderColor( client, false );	
			
			// 重力
			SetEntityGravity(client,0.0);
			
			// OFF
			g_RoterState[client] = false;
			
			// 速度戻す
			TF2_SetPlayerDefaultSpeed( client );
		}
	}
	
}


/////////////////////////////////////////////////////////////////////
//
// セントロフュージローターの重力
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_RoterGravity(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0～20.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 20.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 20.0");
	}
}



