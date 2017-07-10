/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////

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
#define PL_NAME "King Kong Drumming"
#define PL_DESC "King Kong Drumming"
#define PL_VERSION "0.0.0"
#define PL_TRANSLATION "kingkongdrumming.phrases"

#define EFFECT_HAND_RED	"critical_rocket_red"
#define EFFECT_HAND_BLU	"critical_rocket_blue"

#define EFFECT_EXPLODE_1	"ExplosionCore_MidAir"
#define EFFECT_EXPLODE_2	"Explosions_MA_Debris001"
#define EFFECT_EXPLODE_3	"Explosions_MA_Dustup_2"

#define SOUND_OUT_COMBO			"weapons/medigun_no_target.wav"
#define SOUND_SUCCESS_COMBO		"player/recharged.wav"
#define SOUND_THE_END			"ui/medic_alert.wav"
#define SOUND_EXPLODE			"weapons/explode2.wav"

#define SOUND_BUFF_ON			"weapons/buffed_on.wav"
#define SOUND_BUFF_OFF			"weapons/buffed_off.wav"

#define SOUND_FAST_SHOT			"weapons/demo_charge_hit_world3.wav"
#define SOUND_FAST_SWING		"weapons/demo_sword_swing3.wav"

#define SOUND_GRANADE_PIN	"weapons/scatter_gun_double_tube_close.wav"


#define EFFECT_FOOT_FLAME		"rocketjump_flame"

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
new Handle:g_TauntDamage	= INVALID_HANDLE;						// ConVarタウントダメージ
new Handle:g_TimeLv1		= INVALID_HANDLE;						// ConVar有効時間Lv1
new Handle:g_TimeLv2		= INVALID_HANDLE;						// ConVar有効時間Lv2
new Handle:g_TimeLv3		= INVALID_HANDLE;						// ConVar有効時間Lv3
new Handle:g_FireRateMag	= INVALID_HANDLE;						// ConVar連射速度倍率
new Handle:g_MoveSpeedMag	= INVALID_HANDLE;						// ConVar移動速度倍率

new Handle:g_SetFireRateTimer[ MAXPLAYERS+1 ]	= INVALID_HANDLE;	// ファイヤレートセットタイマー
new Handle:g_TauntTimer[ MAXPLAYERS+1 ]			= INVALID_HANDLE;	// 挑発タイマー
new Handle:g_ComboTimer[ MAXPLAYERS+1 ]			= INVALID_HANDLE;	// コンボタイマー
new Handle:g_PowerupTimer[ MAXPLAYERS+1 ]		= INVALID_HANDLE;	// クリッツタイマー
new Handle:g_DamageTimer[ MAXPLAYERS+1 ]		= INVALID_HANDLE;	// ダメージ発動タイマー
new Handle:g_DamageLoopTimer[ MAXPLAYERS+1 ]	= INVALID_HANDLE;	// ダメージループタイマー
new Handle:g_SuicideTimer[ MAXPLAYERS+1 ]		= INVALID_HANDLE;	// 自爆タイマー

new g_ComboCount[ MAXPLAYERS+1 ]	= 0;				// コンボカウント
new g_NowLevel[ MAXPLAYERS+1 ]		= 0;				// 今どれ発動中？
new g_HandEffect[ MAXPLAYERS+1 ][2];					// エフェクト
new g_Attacker[ MAXPLAYERS+1 ];							// 自爆アタッカー
new bool:g_Suicide[ MAXPLAYERS+1 ];						// 自爆?
new g_EffectCount[ MAXPLAYERS+1 ]	= 0;				// エフェクト用

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
		CreateConVar("sm_rmf_tf_kingkongdrumming", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_kingkongdrumming","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_kingkongdrumming_class", "3", "Ability class");
		
		// 挑発コマンドゲット
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");

		// ConVar
		g_TauntDamage	= CreateConVar("sm_rmf_kingkongdrumming_taunt_damage",		"3",	"Base taunt damage (0-1000)");
		g_TimeLv1		= CreateConVar("sm_rmf_kingkongdrumming_time_lv1",			"4.5",	"Powerup duration Lv1(0.0-120.0)");
		g_TimeLv2		= CreateConVar("sm_rmf_kingkongdrumming_time_lv2",			"4.0",	"Powerup duration Lv2(0.0-120.0)");
		g_TimeLv3		= CreateConVar("sm_rmf_kingkongdrumming_time_lv3",			"3.5",	"Powerup duration Lv3(0.0-120.0)");
		g_MoveSpeedMag	= CreateConVar("sm_rmf_kingkongdrumming_movement_speed_mag","2.5",	"Lv1 Movement speed magnification(0.0-10.0)");
		g_FireRateMag	= CreateConVar("sm_rmf_kingkongdrumming_firing_speed_mag",	"2.0",	"Lv2 Firing speed magnification(0.0-10.0)");
		HookConVarChange( g_TauntDamage,	ConVarChange_Damage );
		HookConVarChange( g_TimeLv1,		ConVarChange_Time );
		HookConVarChange( g_TimeLv2,		ConVarChange_Time );
		HookConVarChange( g_TimeLv3,		ConVarChange_Time );
		HookConVarChange( g_FireRateMag,	ConVarChange_Magnification );
		HookConVarChange( g_MoveSpeedMag,	ConVarChange_Magnification );

	}
	

	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle( EFFECT_HAND_RED );
		PrePlayParticle( EFFECT_HAND_BLU );
		PrePlayParticle( EFFECT_EXPLODE_1 );
		PrePlayParticle( EFFECT_EXPLODE_2 );
		PrePlayParticle( EFFECT_EXPLODE_3 );
		PrePlayParticle( EFFECT_FOOT_FLAME );
		PrecacheSound( SOUND_OUT_COMBO, true);
		PrecacheSound( SOUND_SUCCESS_COMBO, true);
		PrecacheSound( SOUND_THE_END, true);
		PrecacheSound( SOUND_EXPLODE, true);
		PrecacheSound( SOUND_BUFF_ON, true);
		PrecacheSound( SOUND_BUFF_OFF, true);
		PrecacheSound( SOUND_FAST_SHOT, true);
		PrecacheSound( SOUND_FAST_SWING, true);
		PrecacheSound( SOUND_GRANADE_PIN, true);
	}
	
	// プレイヤーリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// 自爆アタッカークリア
		g_Attacker[ client ] = -1;
		
		// 自爆?
		g_Suicide[ client ] = false;
		
		// タイマークリア
		ClearTimer( g_TauntTimer[ client ] )
		ClearTimer( g_ComboTimer[ client ] )
		ClearTimer( g_PowerupTimer[ client ] )
		ClearTimer( g_DamageTimer[ client ] )
		ClearTimer( g_DamageLoopTimer[ client ] )
		ClearTimer( g_SuicideTimer[ client ] )
		ClearTimer( g_SetFireRateTimer[ client ] )
	
		// コンボカウントクリア
		g_ComboCount[ client ] = 0;
		
		// レベルクリア
		g_NowLevel[ client ] = 0;
	
		// エフェクトカウントクリア
		g_EffectCount[ client ] = 0;
		
		// サウンド停止
		StopSound( client, 0, SOUND_BUFF_ON );
		
		DeleteParticle( g_HandEffect[ client ][ 0 ] );
		DeleteParticle( g_HandEffect[ client ][ 1 ] );

		// 色設定
		SetPlayerRenderColor( client, 0 );

		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:percentage1[16];
			new String:percentage2[16];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_KINGKONGDRUMMING", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_KINGKONGDRUMMING_ATTRIBUTE_0", client );
			GetPercentageString( GetConVarFloat( g_MoveSpeedMag ), percentage1, sizeof( percentage1 ) )
			GetPercentageString( GetConVarFloat( g_FireRateMag ), percentage2, sizeof( percentage2 ) )
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_KINGKONGDRUMMING_ATTRIBUTE_1", client, percentage1, percentage2 );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_KINGKONGDRUMMING_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_KINGKONGDRUMMING_ATTRIBUTE_3", client );
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s", attribute1 );
			// 3ページ目
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s\n%s", attribute2, attribute3 );
			
		}
		
	}

	// プレイヤー復活ディレイ
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
		// ソルジャー
		if( TF2_GetPlayerClass(client) == TFClass_Soldier && g_AbilityUnlock[client] )
		{
			ClientCommand(client, "slot1");
			// セカンダリ削除
			new weaponIndex = GetPlayerWeaponSlot(client, 1);
			if( weaponIndex != -1 )
			{
				TF2_RemoveWeaponSlot(client, 1);
			}
		}
	}
		
	// プレイヤーリサプライ
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			// ソルジャー
			if( TF2_GetPlayerClass(client) == TFClass_Soldier && g_AbilityUnlock[client] )
			{
				ClientCommand(client, "slot1");
				// セカンダリ削除
				new weaponIndex = GetPlayerWeaponSlot(client, 1);
				if( weaponIndex != -1 )
				{
					TF2_RemoveWeaponSlot(client, 1);
				}
				
			}
		}
	}	
	
	// 死亡
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
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
		if( attacker == client && g_Attacker[ client ] != -1 )
		{
			new Handle:newEvent = CreateEvent( "player_death" );
			if( newEvent != INVALID_HANDLE )
			{
				attacker = g_Attacker[ client ];
				
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
				SetEventString( newEvent, "weapon", "taunt_soldier" );
				FireEvent( newEvent );
				return Plugin_Handled;
			}
		}	
		
		// イベント書き換え
		if( attacker == client && g_Suicide[ client ] )
		{
			SetEventString( event, "weapon", "taunt_soldier" );
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
// ゲームフレーム
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// ソルジャー
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client])
		{
			// 発動中
			if( g_PowerupTimer[ client ] != INVALID_HANDLE )
			{
				if( g_NowLevel[ client ] > 0 && g_NowLevel[ client ] < 4 )
				{
					// 移動速度変更
					TF2_SetPlayerSpeed( client, TF2_GetPlayerClassSpeed( client ) * GetConVarFloat( g_MoveSpeedMag ) );
					
					// エフェクト
					PlayDashEffect( client );
				}
			}
		}
	}

}

/////////////////////////////////////////////////////////////////////
//
// エフェクト発動
//
/////////////////////////////////////////////////////////////////////
stock PlayDashEffect(any:client)
{
	g_EffectCount[ client ]++;
	
	if( g_EffectCount[client] == 10 )
	{
		AttachParticleBone(client, EFFECT_FOOT_FLAME, "foot_L", 1.0);
		AttachParticleBone(client, EFFECT_FOOT_FLAME, "foot_R", 1.0);
	}

	if( g_EffectCount[client] > 10 )
	{
		new Float:vec[3];
		GetEntPropVector( client, Prop_Data, "m_vecAbsVelocity", vec );
		NormalizeVector( vec, vec );
		ScaleVector( vec, -90.0 );

		g_EffectCount[ client ] = 0;
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
	
	// ソルジャーでアビリティONのとき
	if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[ client ] && !TF2_IsPlayerTaunt( client ) && GetEntityFlags(client) & FL_ONGROUND )
	{
		// ダイレクトヒットのみ
		if(TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_DIRECTHIT )
		{
			if( g_ComboCount[ client ] == 0 )
			{
				// とりあえず前の効果終了
				Timer_EffectEnd( INVALID_HANDLE, client);
			}
			
			// 4回目は早めに発動
			if( g_ComboCount[ client ] == 3 )
			{
				// 挑発タイマー発動
				ClearTimer( g_TauntTimer[client] );
				g_TauntTimer[ client ] = CreateTimer( 2.2, Timer_TauntEnd, client );

			}
			else
			{
				// 挑発タイマー発動
				ClearTimer( g_TauntTimer[client] );
				g_TauntTimer[ client ] = CreateTimer( 3.0, Timer_TauntEnd, client );
			}
			
			// ダメージタイマー発動
			ClearTimer( g_DamageTimer[client] );
			g_DamageTimer[ client ] = CreateTimer( 0.9, Timer_DamageStart, client );
			
			// コンボタイマークリア
			ClearTimer( g_ComboTimer[client] );
			
			// エフェクト
			if( GetClientTeam( client ) == _:TFTeam_Red )
			{
				g_HandEffect[ client ][ 0 ] = AttachParticleBone(client, EFFECT_HAND_RED, "weapon_bone_1", 2.5);
				g_HandEffect[ client ][ 1 ] = AttachParticleBone(client, EFFECT_HAND_RED, "weapon_bone_L", 2.5);
			}
			else
			{
				g_HandEffect[ client ][ 0 ] = AttachParticleBone(client, EFFECT_HAND_BLU, "weapon_bone_1", 2.5);
				g_HandEffect[ client ][ 1 ] = AttachParticleBone(client, EFFECT_HAND_BLU, "weapon_bone_L", 2.5);
			}
			
		}
	}	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// ダメージループ発動
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DamageStart(Handle:timer, any:client)
{
	g_DamageTimer[ client ] = INVALID_HANDLE;
	
	if( IsClientInGame( client ) && IsPlayerAlive( client ) && TF2_IsPlayerTaunt( client ) )
	{
		// ダメージタイマー発動
		ClearTimer( g_DamageLoopTimer[client] );
		g_DamageLoopTimer[ client ] = CreateTimer( 0.25, Timer_DamageLoop, client, TIMER_REPEAT );
	}
}

/////////////////////////////////////////////////////////////////////
//
// ダメージループ
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DamageLoop(Handle:timer, any:client)
{
	if( IsClientInGame( client ) && IsPlayerAlive( client ) && TF2_IsPlayerTaunt( client ) )
	{
		// 体力を減らす
		new nowHealth = GetClientHealth( client );
		new damageAmount = GetConVarInt( g_TauntDamage ) * ( g_ComboCount[ client ] + 1 );
		
		nowHealth -= damageAmount;
		
		// 体力が亡くなったら死亡
		if( nowHealth <= 0 )
		{
			FakeClientCommand( client, "kill" );
		}
		else
		{
			SetEntityHealth( client, nowHealth );
		}
		
		// ダメージ表示
		new Handle:newEvent = CreateEvent( "player_healonhit" );
		if( newEvent != INVALID_HANDLE )
		{
			SetEventInt( newEvent, "amount", -( damageAmount ) );
			SetEventInt( newEvent, "entindex", client );
			FireEvent( newEvent );
		}

	}
	else
	{
		// ループタイマークリア
		ClearTimer( g_DamageLoopTimer[client] );
	
	}
}

/////////////////////////////////////////////////////////////////////
//
// 挑発終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntEnd(Handle:timer, any:client)
{
	g_TauntTimer[ client ] = INVALID_HANDLE;
	
	if( IsClientInGame( client ) && IsPlayerAlive( client ) && TF2_IsPlayerTaunt( client ) )
	{
		DeleteParticle( g_HandEffect[ client ][ 0 ] );
		DeleteParticle( g_HandEffect[ client ][ 1 ] );
		
		g_ComboCount[ client ] += 1;
		g_NowLevel[ client ] += 1;
		
		// コンボタイマー発動
		ClearTimer( g_ComboTimer[ client ] );
		g_ComboTimer[ client ] = CreateTimer( 1.3, Timer_ComboEnd, client );

		// ダメージループタイマークリア
		ClearTimer( g_DamageLoopTimer[client] );

		if( g_ComboCount[ client ] > 0 && g_ComboCount[ client ] < 4)
		{
			EmitSoundToClient( client, SOUND_SUCCESS_COMBO, client, _, _, SND_CHANGEPITCH, 1.0, 80 + ( g_ComboCount[ client ] * 15 ) );
//			EmitSoundToAll(SOUND_SUCCESS_COMBO, client, _, _, SND_CHANGEPITCH, 1.0, 80 + ( g_ComboCount[ client ] * 15 ) );
		}
		
		switch( g_ComboCount[ client ] )
		{
		case 1:
			{
				// パワーアップタイマー発動
				ClearTimer( g_PowerupTimer[ client ] );
				g_PowerupTimer[ client ] = CreateTimer( GetConVarFloat( g_TimeLv1 ), Timer_EffectEnd, client );
				
				// サウンド
				EmitSoundToAll( SOUND_BUFF_ON, client, _, _, SND_CHANGEPITCH, 1.0, 100 );
				
				// メッセージ
				PrintToChat(client, "\x05%T", "MESSAGE_POWERUP_LV1", client);	

				// 色設定
				SetPlayerRenderColor( client, g_NowLevel[ client ] );
			}
		case 2:
			{
				// サウンド停止
				StopSound( client, 0, SOUND_BUFF_ON );

				// パワーアップタイマー発動
				ClearTimer( g_PowerupTimer[ client ] );
				g_PowerupTimer[ client ] = CreateTimer( GetConVarFloat( g_TimeLv2 ), Timer_EffectEnd, client );
				
				// サウンド
				EmitSoundToAll( SOUND_BUFF_ON, client, _, _, SND_CHANGEPITCH, 1.0, 120 );
				
				// メッセージ
				PrintToChat(client, "\x05%T", "MESSAGE_POWERUP_LV2", client);	
				
				// 色設定
				SetPlayerRenderColor( client, g_NowLevel[ client ] );
			}
		case 3:
			{
				// サウンド停止
				StopSound( client, 0, SOUND_BUFF_ON );

				// パワーアップタイマー発動
				ClearTimer( g_PowerupTimer[ client ] );
				g_PowerupTimer[ client ] = CreateTimer( GetConVarFloat( g_TimeLv3 ), Timer_EffectEnd, client );
				
				// サウンド
				EmitSoundToAll( SOUND_BUFF_ON, client, _, _, SND_CHANGEPITCH, 1.0, 150 );
				
				// メッセージ
				PrintToChat(client, "\x05%T", "MESSAGE_POWERUP_LV3", client);	
				
				// 色設定
				SetPlayerRenderColor( client, g_NowLevel[ client ] );
			}
		case 4:
			{
				// サウンド停止
				StopSound( client, 0, SOUND_BUFF_ON );
				
				EmitSoundToAll( SOUND_GRANADE_PIN, client, _, _, SND_CHANGEPITCH, 1.0, 160 );
				EmitSoundToAll( SOUND_THE_END, client, _, _, SND_CHANGEPITCH, 0.5, 160 );
				
				// 自爆タイマー発動
				ClearTimer( g_SuicideTimer[client] );
				g_SuicideTimer[ client ] = CreateTimer( 2.2, Timer_Suicide, client );
				
				// メッセージ（手榴弾の安全ピンが抜けた！）
				PrintToChat(client, "\x05%T", "MESSAGE_RELEASE_SAFETY", client);	
				
				// 色設定
				SetPlayerRenderColor( client, g_NowLevel[ client ] );
			}
		}
	}	
}

/////////////////////////////////////////////////////////////////////
//
// 自爆
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_Suicide(Handle:timer, any:client)
{
	g_SuicideTimer[ client ] = INVALID_HANDLE;
	
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		StopSound( client, 0, SOUND_THE_END );

		// 爆発サウンド
		EmitSoundToAll( SOUND_EXPLODE, client, _, _, SND_CHANGEPITCH, 1.0, 100 );
		
		// エフェクト
		new Float:pos[3];
		pos[2] = 50.0;
		ShowParticleEntity(client, EFFECT_EXPLODE_1, 2.5, pos);
		ShowParticleEntity(client, EFFECT_EXPLODE_2, 2.5, pos);
		ShowParticleEntity(client, EFFECT_EXPLODE_3, 2.5, pos);
				
		
		// ダメージ
		RadiusDamage( client );
		RadiusDamageBuiltObject(client, 0);
		RadiusDamageBuiltObject(client, 1);
		RadiusDamageBuiltObject(client, 2);
		RadiusDamageBuiltObject(client, 3);

		// 自爆フラグ
		g_Suicide[ client ] = true;
		
		FakeClientCommand( client, "explode" );
		
		
	}
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

				// ソルジャー位置
				GetClientAbsOrigin(client, fAttackerPos);
				// 被害者位置
				GetClientAbsOrigin(victim, fVictimPos);
				// ソルジャーと被害者の位置
				distance = GetVectorDistanceMeter(fAttackerPos, fVictimPos);
				
				if(CanSeeTarget(victim, fVictimPos, client, fAttackerPos, 3.5, true, true))
				{
					//GetEdictClassname(HitEnt, edictName, sizeof(edictName)); 
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
						nowHealth -= RoundFloat( 450 * (1.5 / distance) );
						if(nowHealth < 0)
						{
							g_Attacker[ victim ] = client;
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
			if( CanSeeTarget( builtObj, fObjPos, client, fAttackerPos, 3.5, true, true) )
			{
				new damage = RoundFloat( 450 * ( 1.0 / distance ) );
				
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
						SetEventString( newEvent,	"weapon",		"taunt_soldier" );
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
// コンボ終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_ComboEnd(Handle:timer, any:client)
{
	g_ComboTimer[ client ] = INVALID_HANDLE;
	
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		EmitSoundToClient( client, SOUND_OUT_COMBO, client, _, _, SND_CHANGEPITCH, 1.0, 90 );
	}

	// コンボカウントリセット
	g_ComboCount[ client ] = 0;
}

/////////////////////////////////////////////////////////////////////
//
// クリッツ終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_EffectEnd(Handle:timer, any:client)
{
	g_PowerupTimer[ client ] = INVALID_HANDLE;
	
	// サウンド停止
	StopSound( client, 0, SOUND_BUFF_ON );
	switch( g_NowLevel[ client ] )
	{
	case 1:
		{
			// 終了サウンド
			EmitSoundToAll( SOUND_BUFF_OFF, client, _, _, SND_CHANGEPITCH, 1.0, 100 );
		}
	case 2:
		{
			// 終了サウンド
			EmitSoundToAll( SOUND_BUFF_OFF, client, _, _, SND_CHANGEPITCH, 1.0, 120 );
		}
	case 3:
		{
			// 終了サウンド
			EmitSoundToAll( SOUND_BUFF_OFF, client, _, _, SND_CHANGEPITCH, 1.0, 150 );
		}
		
	}
	
	// レベルリセット
	g_NowLevel[ client ] = 0;

	// エフェクトカウントクリア
	g_EffectCount[ client ] = 0;
	
	// スピード戻す
	TF2_SetPlayerSpeed( client, TF2_GetPlayerClassSpeed( client ) );
	
	// 色戻す
	SetPlayerRenderColor( client, 0 );
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
		// ダイレクトヒット
//		if( StrEqual( weaponname, "tf_weapon_rocketlauncher_directhit") )
//		{
			if( g_PowerupTimer[ client ] != INVALID_HANDLE )
			{
				if( g_NowLevel[ client ] >= 2 && g_NowLevel[ client ] < 4)
				{
					// ファイヤーレート設定タイマー発動
					ClearTimer( g_SetFireRateTimer[ client ] );
					g_SetFireRateTimer[ client ] = CreateTimer( 0.05, Timer_SetFireRate, client );
				}
				if( g_NowLevel[ client ] == 3 )
				{
					result = true;
					return Plugin_Handled;	
				}
			}
//		}
		
	}
	

	return Plugin_Continue;	
}


/////////////////////////////////////////////////////////////////////
//
// ファイヤレートチェック
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_SetFireRate(Handle:timer, any:client)
{
	g_SetFireRateTimer[ client ] = INVALID_HANDLE;
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		// 連射速度変更
		SetEntPropFloat( TF2_GetCurrentWeapon( client ), Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + ( 0.7 * ( 1 / GetConVarFloat( g_FireRateMag ) ) ) );
		
		// 発射音など変更
		if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon( client ) ) == _:ITEM_WEAPON_DIRECTHIT )
		{
			StopSound( TF2_GetCurrentWeapon( client ), 0, SOUND_FAST_SHOT );
			EmitSoundToAll( SOUND_FAST_SHOT, TF2_GetCurrentWeapon( client ), _, _, SND_CHANGEPITCH, 1.0, 150 );
		}
		if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon( client ) ) == _:ITEM_WEAPON_PICKAXE )
		{
			StopSound( TF2_GetCurrentWeapon( client ), 0, SOUND_FAST_SWING );
			EmitSoundToAll( SOUND_FAST_SWING, TF2_GetCurrentWeapon( client ), _, _, SND_CHANGEPITCH, 1.0, 150 );
		}
		if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon( client ) ) == _:ITEM_WEAPON_SHOVEL )
		{
			StopSound( TF2_GetCurrentWeapon( client ), 0, SOUND_FAST_SWING );
			EmitSoundToAll( SOUND_FAST_SWING, TF2_GetCurrentWeapon( client ), _, _, SND_CHANGEPITCH, 1.0, 120 );
		}

	}
}	

/////////////////////////////////////////////////////////////////////
//
// 隠れさせる(見えなくする)
//
/////////////////////////////////////////////////////////////////////
stock SetPlayerRenderColor( any:client, level )
{
	new r,g,b;
	
	switch( g_ComboCount[ client ] )
	{
	case 0:
		{
			r = 255;
			g = 255;
			b = 255;
		}
	case 1:
		{
			r = 231;
			g = 231;
			b = 231;
		}
	case 2:
		{
			r = 207;
			g = 207;
			b = 207;
		}
	case 3:
		{
			r = 183;
			g = 183;
			b = 183;
		}
	case 4:
		{
			r = 159;
			g = 159;
			b = 159;
		}
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