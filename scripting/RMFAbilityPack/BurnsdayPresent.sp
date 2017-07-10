/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.2
// ・1.3.1でコンパイル
// ・火炎放射器で敵のバーンズデイプレゼントの炎を消火できなかったのを修正

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
#define PL_NAME "Burnsday Present"
#define PL_DESC "Burnsday Present"
#define PL_VERSION "0.0.2"
#define PL_TRANSLATION "burnsdaypresent.phrases"

#define MDL_BOX			"models/effects/bday_gib01.mdl"
#define MDL_BURNAREA	"models/props_farm/haypile001.mdl"

#define EFFECT_EXPLOSION_STAR		"mini_fireworks"
#define EFFECT_EXPLOSION_CONFETTI	"bday_confetti"
#define EFFECT_EXPLOSION_FLASH		"teleported_flash"
#define EFFECT_EXPLOSION_DEBRIS		"Explosions_UW_Debris001"
#define EFFECT_AREA_FIRE			"buildingdamage_dispenser_fire1"
#define EFFECT_TRAIL_RED			"critical_rocket_red"
#define EFFECT_TRAIL_BLU			"critical_rocket_blue"

#define SOUND_EXPLOSION_1		"weapons/jar_explode.wav"
#define SOUND_EXPLOSION_2		"misc/happy_birthday.wav"
#define SOUND_FLAME				"misc/flame_engulf.wav"
#define SOUND_EXTINGUISH		"player/flame_out.wav"
#define SOUND_NOAMMO			"weapons/medigun_no_target.wav"
#define SOUND_SHOOT				"weapons/grenade_launcher_shoot.wav"

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
new Handle:g_PresentBoxData[MAXPLAYERS+1]	= INVALID_HANDLE;	// プレゼントデータ
new Handle:g_JarData[MAXPLAYERS+1]			= INVALID_HANDLE;	// 消火用尿瓶データ

new Handle:g_BurnTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// 炎消滅タイマー
new Handle:g_BurnDamageTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// 炎ベース消滅タイマー
new Handle:g_FuseTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// フューズタイマー
new Handle:g_JarLaunchTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	//ジャラテ発射タイマー

new String:SOUND_SHOOT_VOICE[5][64];							// 発射ボイス

new Handle:g_Damage			= INVALID_HANDLE;				// ConVarダメージ
new Handle:g_DamageInterval	= INVALID_HANDLE;				// ConVarダメージ間隔
new Handle:g_BurningTime	= INVALID_HANDLE;				// ConVar燃える時間
new Handle:g_UseAmmo		= INVALID_HANDLE;				// ConVar弾薬消費量
//new Handle:g_FireRate		= INVALID_HANDLE;				// ConVarファイヤレート

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
		CreateConVar("sm_rmf_tf_burnsdaypresent", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_burnsdaypresent","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// アビリティクラス設定
		CreateConVar("sm_rmf_burnsdaypresent_class", "7", "Ability class");
		
		
		g_Damage			= CreateConVar("sm_rmf_burnsdaypresent_damage",				"5",	"Damage (0-1000)");
		g_DamageInterval	= CreateConVar("sm_rmf_burnsdaypresent_damage_interval",	"0.1",	"Damage interval (0.0-120.0)");
		g_BurningTime		= CreateConVar("sm_rmf_burnsdaypresent_burning_time",		"7.0",	"Burning time (0.0-120.0)");
		g_UseAmmo			= CreateConVar("sm_rmf_burnsdaypresent_use_ammo",			"50",	"Ammo required (0-200)");
		//g_FireRate			= CreateConVar("sm_rmf_burnsdaypresent_fire_rate",			"5.0",	"Fire rate (1.0-10.0)");

		HookConVarChange( g_Damage,			ConVarChange_Damage );
		HookConVarChange( g_DamageInterval,	ConVarChange_Time );
		HookConVarChange( g_BurningTime,	ConVarChange_Time );
		HookConVarChange( g_UseAmmo,		ConVarChange_Ammo );
		//HookConVarChange( g_FireRate,		ConVarChange_FireRate );

		// 発射ボイス
		SOUND_SHOOT_VOICE[0] = "vo/pyro_battlecry01.wav";
		SOUND_SHOOT_VOICE[1] = "vo/pyro_cheers01.wav";
		SOUND_SHOOT_VOICE[2] = "vo/pyro_headleft01.wav";
		SOUND_SHOOT_VOICE[3] = "vo/pyro_laughshort01.wav";
		SOUND_SHOOT_VOICE[4] = "vo/pyro_positivevocalization01.wav";

		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			InitPresentBoxData(i);
			InitJarData(i);
		}
	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			InitPresentBoxData(i);
			InitJarData(i);
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			if( g_PresentBoxData[i] != INVALID_HANDLE )
			{
				CloseHandle( g_PresentBoxData[i] );
			}
			if( g_JarData[i] != INVALID_HANDLE )
			{
				CloseHandle( g_JarData[i] );
			}
		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheModel( MDL_BOX );
		PrecacheModel( MDL_BURNAREA );
		PrePlayParticle( EFFECT_EXPLOSION_CONFETTI );
		PrePlayParticle( EFFECT_EXPLOSION_FLASH );
		PrePlayParticle( EFFECT_EXPLOSION_DEBRIS );
		PrePlayParticle( EFFECT_AREA_FIRE );
		PrePlayParticle( EFFECT_EXPLOSION_STAR );
		PrePlayParticle( EFFECT_TRAIL_RED );
		PrePlayParticle( EFFECT_TRAIL_BLU );
		PrecacheSound( SOUND_EXPLOSION_1, true );
		PrecacheSound( SOUND_EXPLOSION_2, true );
		PrecacheSound( SOUND_FLAME, true );
		PrecacheSound( SOUND_EXTINGUISH, true );
		PrecacheSound( SOUND_NOAMMO, true );
		PrecacheSound( SOUND_SHOOT, true );
		for( new i = 0; i < 5; i++)
		{
			PrecacheSound(SOUND_SHOOT_VOICE[i], true);
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
		// データが初期化されていなければ生成
		if( g_PresentBoxData[client] == INVALID_HANDLE )
		{
			InitPresentBoxData( client );
		}
		// データが初期化されていなければ生成
		if( g_JarData[client] == INVALID_HANDLE )
		{
			InitJarData( client );
		}		
		// Jarateデータ初期化
		SetTrieValue( g_JarData[client], "JarIndex",	-1 );
		SetTrieValue( g_JarData[client], "Launch",		false );
		SetTrieArray( g_JarData[client], "LastPos",		NULL_VECTOR, 3 );
		
		// プレゼント削除
		RemovePresent( client );
		RemoveBurnArea( client );
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro )
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_BURNSDAYPRESENT", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_BURNSDAYPRESENT_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_BURNSDAYPRESENT_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_BURNSDAYPRESENT_ATTRIBUTE_2", client, GetConVarInt( g_UseAmmo ));
			
			
			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}
		
	}
	

	// プレイヤーダメージ
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
	}	
	return Plugin_Continue;
}


/////////////////////////////////////////////////////////////////////
//
// プレゼント配列初期化
//
/////////////////////////////////////////////////////////////////////
stock InitPresentBoxData( any:client )
{
	// 配列作成
	if( g_PresentBoxData[client] == INVALID_HANDLE )
	{
		new array[12] = -1;
		g_PresentBoxData[client] = CreateTrie();
		SetTrieValue( g_PresentBoxData[client], "BoxIndex",	 		-1 );
		SetTrieValue( g_PresentBoxData[client], "VelUp",			false );
		SetTrieArray( g_PresentBoxData[client], "LastPos",			NULL_VECTOR,	3 );
		SetTrieArray( g_PresentBoxData[client], "FireEffects",		array,			12 );
		SetTrieValue( g_PresentBoxData[client], "BurnAreaIndex",	-1 );
	}	
}
/////////////////////////////////////////////////////////////////////
//
// 消火用尿瓶データ初期化
//
/////////////////////////////////////////////////////////////////////
stock InitJarData( any:client )
{
	// 配列作成
	if( g_JarData[client] == INVALID_HANDLE )
	{
		g_JarData[client] = CreateTrie();
		SetTrieValue( g_JarData[client], "JarIndex",	 	-1 );
		SetTrieValue( g_JarData[client], "Launch",			false );
		SetTrieArray( g_JarData[client], "LastPos",			NULL_VECTOR,	3 );
	}	
}

/////////////////////////////////////////////////////////////////////
//
// フレームアクション
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		// スナイパーのみ
		if( TF2_GetPlayerClass(client) == TFClass_Sniper )
		{
			// ジャラテで消火チェック
			FireExtinguishJar( client );
		}
		
		// プレゼント停止チェック
		PresentExplosion( client );
		
		// パイロのみ
		if( TF2_GetPlayerClass(client) == TFClass_Pyro && g_AbilityUnlock[client] )
		{
			// セカンダリ
			if ( GetClientButtons( client ) & IN_ATTACK2 &&  !( GetClientButtons( client ) & IN_ATTACK ) )
			{
				// バックバーナーならOK
				if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon( client ) ) == _:ITEM_WEAPON_BACKBURNER )
				{
					// キーチェック
//					if( CheckElapsedTime( client, GetConVarFloat( g_FireRate ) ) )
					if( CheckElapsedTime( client, 1.0 ) )
					{
						// キーを押した時間を保存
						SaveKeyTime(client);
					
						// 発射チェック
						BurnsdayPresent( client );
					}
				}
			}
		}
		// パイロのみ
		if( TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			// セカンダリ
			if ( GetClientButtons( client ) & IN_ATTACK2 &&  !( GetClientButtons( client ) & IN_ATTACK ) )
			{
				// 消火
				if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon( client ) ) == _:ITEM_WEAPON_FLAMETHROWER )
				{
					// キーチェック
					if( CheckElapsedTime( client, 0.5 ) )
					{
						// キーを押した時間を保存
						SaveKeyTime(client);
						
						// 消火チェック
						FireExtinguish( client );
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

	// スナイパーのときのみ
	if( TF2_GetPlayerClass(client) == TFClass_Sniper )
	{
		// JARATE
		if( StrEqual( weaponname, "tf_weapon_jar") )
		{
			// チェックしない時間設定
			ClearTimer( g_JarLaunchTimer[client] );
			g_JarLaunchTimer[client] = CreateTimer( 0.15, Timer_JarLaunch, client );
		}
		
	}
	

	return Plugin_Continue;	
}

/////////////////////////////////////////////////////////////////////
//
// ジャラテ発射
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_JarLaunch(Handle:timer, any:client)
{
	g_JarLaunchTimer[client] = INVALID_HANDLE;
	
	// データが初期化されていなければ生成
	if( g_JarData[client] == INVALID_HANDLE )
	{
		InitJarData( client );
	}		
	
	// ゲームに入っている
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		new weaponIndex = GetPlayerWeaponSlot(client, 1);
		new ent = -1;
		while ( ( ent = FindEntityByClassname( ent, "tf_projectile_jar" ) ) != -1 )
		{
			// 発射した奴のみ
			new iOwner = GetEntPropEnt( ent, Prop_Send, "m_hLauncher" );
			//PrintToChat(client, "%d, %d", weaponIndex, iOwner);
			if( weaponIndex == iOwner )
			{
				// データが初期化されていなければ生成
				if( g_JarData[client] == INVALID_HANDLE )
				{
					InitJarData( client )
				}
			
				new Float:pos[3];
				// 位置
				GetEntPropVector( ent, Prop_Data, "m_vecAbsOrigin", pos );
				
				// データ入れる
				SetTrieValue( g_JarData[client], "JarIndex",ent );
				SetTrieValue( g_JarData[client], "Launch",	true );
				SetTrieArray( g_JarData[client], "LastPos",	pos, 3 );
				return;
			}
		}
	}
}


/////////////////////////////////////////////////////////////////////
//
// 消火Jarチェック
//
/////////////////////////////////////////////////////////////////////
stock FireExtinguishJar( any:client )
{
	// データが初期化されていなければ生成
	if( g_PresentBoxData[client] == INVALID_HANDLE )
	{
		InitPresentBoxData( client );
	}
	// データが初期化されていなければ生成
	if( g_JarData[client] == INVALID_HANDLE )
	{
		InitJarData( client );
	}		

	// データ取り出し
	new JarIndex = -1;
	GetTrieValue( g_JarData[client], "JarIndex", JarIndex );
	new bool:Launch = false;
	GetTrieValue( g_JarData[client], "Launch", Launch );
	
	// 正しい尿瓶
	if( EdictEqual( JarIndex, "tf_projectile_jar") )
	{
		// 発射済み？
		if( Launch )
		{
			// 新しい位置を保存
			new Float:pos[3];
			// 位置
			GetEntPropVector( JarIndex, Prop_Data, "m_vecAbsOrigin", pos );
			
			// データ入れる
			SetTrieArray( g_JarData[client], "LastPos",	pos, 3 );
			//PrintToChatAll("%f %f %f", pos[0], pos[1], pos[2] );
			return;
		}
	}
	// 既に破裂・もしくは発射してない
	else 
	{
		// もし発射済みなら消火チェック
		if( Launch )
		{
			new Float:pos[3];
			// 位置
			GetTrieArray( g_JarData[client], "LastPos",	pos, 3 );

			// 登録データからチェック
			new maxclients = GetMaxClients();
			for (new burnArea = 1; burnArea <= maxclients; burnArea++)
			{
				// データが初期化されていなければ生成
				if( g_PresentBoxData[burnArea] == INVALID_HANDLE )
				{
					InitPresentBoxData( burnArea );
				}
				
				// データ取り出し
				new BurnAreaIndex = -1;
				GetTrieValue( g_PresentBoxData[burnArea], "BurnAreaIndex", BurnAreaIndex );
				
				if( BurnAreaIndex != -1 )
				{
					// ターゲット名取得取得
					new String:nameTarget[64];
					GetEntPropString( BurnAreaIndex, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );
					// バーンズエリア
					if( StrEqual( nameTarget, "BurnsArea" ) )
					{
						// 相手チームのみ
						new iOwner = GetEntPropEnt(BurnAreaIndex, Prop_Send, "m_hOwnerEntity");
						
						if( GetClientTeam( client ) != GetClientTeam( iOwner ) )
						{
							new Float:firePos[3];
							// 火の位置
							GetEntPropVector( BurnAreaIndex, Prop_Data, "m_vecAbsOrigin", firePos );
							firePos[2] += 5.0;
							
						
							if( CanSeeTarget( BurnAreaIndex, firePos, -1,  pos, 2.5, true, false ) )
							{
								//PrintToChat( client, "OK");
								EmitSoundToAll( SOUND_EXTINGUISH,	BurnAreaIndex, _, _, _, 1.0 );
								RemoveBurnArea( iOwner );
							}
						}
					}
				}
			}
		}
	}
	// データクリア
	SetTrieValue( g_JarData[client], "JarIndex",	-1 );
	SetTrieValue( g_JarData[client], "Launch",		false );
	SetTrieArray( g_JarData[client], "LastPos",		NULL_VECTOR, 3 );

	
}

/////////////////////////////////////////////////////////////////////
//
// 消火チェック
//
/////////////////////////////////////////////////////////////////////
stock FireExtinguish( any:client )
{
	new weapon = TF2_GetCurrentWeapon( client );
	if( GetEntPropFloat( weapon, Prop_Send, "m_flNextPrimaryAttack" ) > GetGameTime() + 0.5 )
	{
		// データが初期化されていなければ生成
		if( g_PresentBoxData[client] == INVALID_HANDLE )
		{
			InitPresentBoxData( client );
		}
		// データが初期化されていなければ生成
		if( g_JarData[client] == INVALID_HANDLE )
		{
			InitJarData( client );
		}		
		
		// 登録データからチェック
		new maxclients = GetMaxClients();
		for (new burnArea = 1; burnArea <= maxclients; burnArea++)
		{
			// データが初期化されていなければ生成
			if( g_PresentBoxData[burnArea] == INVALID_HANDLE )
			{
				InitPresentBoxData( burnArea );
			}
			
			// データ取り出し
			new BurnAreaIndex = -1;
			GetTrieValue( g_PresentBoxData[burnArea], "BurnAreaIndex", BurnAreaIndex );
			
			if( BurnAreaIndex != -1 )
			{
				// ターゲット名取得取得
				new String:nameTarget[64];
				GetEntPropString( BurnAreaIndex, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );
				// バーンズエリア
				if( StrEqual( nameTarget, "BurnsArea" ) )
				{
					// 相手チームのみ
					new iOwner = GetEntPropEnt(BurnAreaIndex, Prop_Send, "m_hOwnerEntity");
					
					if( GetClientTeam( client ) != GetClientTeam( iOwner ) )
					{		
						new Float:firePos[3];
						// 火の位置
						GetEntPropVector( BurnAreaIndex, Prop_Data, "m_vecAbsOrigin", firePos );
						
						// 目の位置取得
						new Float:eyePos[3];		// 被害者の視点位置
						GetClientEyePosition( client, eyePos ); 
						
						firePos[2] += 5.0;
						if( CanSeeTarget( BurnAreaIndex, firePos, client, eyePos, 3.0, true, false ) )
						{
							new Float:eyeAngles[3];		// 被害者の視点角度
							new Float:areaAngles[3];	// 対象への方向
							new Float:diffYaw = 0.0;	// 視線と対象方向への差
							new Float:diffPitch = 0.0;	// 視線と対象方向への差
							
							// 目線を取得
							GetClientEyeAngles(client, eyeAngles);
							// 対象への角度
							SubtractVectors(eyePos, firePos, areaAngles);
							GetVectorAngles(areaAngles, areaAngles);
							diffYaw		= ( areaAngles[1] - 180.0 ) - eyeAngles[1];
							diffYaw		= FloatAbs(diffYaw);
							diffPitch	= ( areaAngles[0] - 180.0 ) - eyeAngles[0];
							diffPitch	= FloatAbs( diffPitch );
							
							//PrintToChat(client, "%f %f", diffYaw, diffPitch)
							// 対象への向きによって低減
							if( ( diffYaw < 35.0 || diffYaw > 325.0 ) && diffPitch < 150.0)
							{
								//PrintToChat( client, "OK");
								
								EmitSoundToAll( SOUND_EXTINGUISH,	BurnAreaIndex, _, _, _, 1.0 );
								RemoveBurnArea( iOwner );
								return;
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
// 発射チェック
//
/////////////////////////////////////////////////////////////////////
stock BurnsdayPresent( any:client )
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// 弾薬を取得
		new offset = FindDataMapOffs( client, "m_iAmmo" ) + ( 1 * 4 );
		new nowAmmo = GetEntData( client, offset, 4 );
		
		// 弾薬があるときだけ&発射してない
		if( nowAmmo >= GetConVarInt( g_UseAmmo ) && g_BurnTimer[client] == INVALID_HANDLE && g_FuseTimer[client] == INVALID_HANDLE )
		{
			// 弾薬消費
			nowAmmo -= GetConVarInt( g_UseAmmo );
			
			// プレゼント生成
			SpawnPresent( client );
			
			// 消費弾薬を設定
			SetEntData( client, offset, nowAmmo );
			
			// 発射音
			EmitSoundToAll( SOUND_SHOOT, TF2_GetCurrentWeapon( client ), _, _, SND_CHANGEPITCH, 1.0, 80 );
			
			// 発射ボイス
			EmitSoundToAll( SOUND_SHOOT_VOICE[ GetRandomInt( 0, 4 ) ], client, _, _, _, 1.0 );
		}
		else
		{
			// 発射できないサウンド
			EmitSoundToClient( client, SOUND_NOAMMO, client, _, _, _, 1.0 );
			
			// 発射できないメッセージ
			if(  nowAmmo >= GetConVarInt( g_UseAmmo ) )
			{
				PrintToChat(client, "\x05%T", "MESSAGE_NO_EXTINGISH", client);
			}
			else
			{
				PrintToChat(client, "\x05%T", "MESSAGE_NO_AMMO", client);
			}
		}
	}	
}

/////////////////////////////////////////////////////////////////////
//
// プレゼント生成
//
/////////////////////////////////////////////////////////////////////
stock SpawnPresent( any:client )
{
	// データが初期化されていなければ生成
	if( g_PresentBoxData[client] == INVALID_HANDLE )
	{
		InitPresentBoxData( client );
	}

	// 残っているのを削除
	RemovePresent( client );
	
	new box = CreateEntityByName("prop_physics_multiplayer");
	if( IsValidEntity( box ) )
	{
		DispatchKeyValue	( box, "targetname", "BurnsPresent" );				// 名前設定
		SetEntPropEnt		( box, Prop_Data, "m_hOwnerEntity",		client);	// 持ち主
		SetEntProp			( box, Prop_Data, "m_CollisionGroup",	1);			// コリジョングループ
		SetEntProp			( box, Prop_Data, "m_usSolidFlags",		16);		// あたり判定フラグ
		SetEntProp			( box, Prop_Data, "m_nSolidType",		6);			// あたり判定タイプ
		SetEntPropFloat		( box, Prop_Data, "m_flFriction",		10000.0);	// 摩擦力
		SetEntPropFloat		( box, Prop_Data, "m_massScale",		100.0);		// 重さ倍率
		SetEntityMoveType	( box, MOVETYPE_VPHYSICS );							// 移動タイプ
		SetEntityModel		( box, MDL_BOX );									// モデル
		DispatchSpawn( box );
		
		new Float:pos[3];
		new Float:ang[3];
		new Float:vec[3];
		new Float:svec[3];
		new Float:pvec[3];
		GetClientEyePosition( client, pos );								// クライアントの視点
		GetClientEyeAngles	( client, ang );								// クライアントの角度
		ang[1] += 2.0;
		GetAngleVectors( ang, vec, svec, NULL_VECTOR );						// 前方ベクトルを取得
		ScaleVector( vec, 800.0 );											// 投擲速度
		ScaleVector( svec, 10.0 );											// 横移動ベクトル
		AddVectors( pos, svec, pos );										// 初期位置を設定
		GetEntPropVector( client, Prop_Data, "m_vecAbsVelocity", pvec );	// プレイヤーの移動ベクトル取得
		AddVectors(pvec, vec, vec);											// ベクトル合成
		TeleportEntity( box, pos, ang, vec );								// 実際に適用
//		TeleportEntity( box, pos, ang, NULL_VECTOR );								// 実際に適用
		
		// データ入れる
		SetTrieValue( g_PresentBoxData[client], "BoxIndex", box );

		// タイマー作成
		ClearTimer( g_FuseTimer[ client ] );
		g_FuseTimer[ client ] = CreateTimer( 5.0, Timer_FuseEnd, client );
		
		if( GetClientTeam( client ) == _:TFTeam_Red )
		{
			AttachParticle( box, EFFECT_TRAIL_RED, 5.0 );
		}
		else
		{
			AttachParticle( box, EFFECT_TRAIL_BLU, 5.0 );
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// 消滅タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FuseEnd(Handle:timer, any:client)
{
	g_FuseTimer[ client ] = INVALID_HANDLE;
}


/////////////////////////////////////////////////////////////////////
//
// プレゼント削除
//
/////////////////////////////////////////////////////////////////////
stock RemovePresent( any:client )
{
	// データが初期化されていなければ生成
	if( g_PresentBoxData[client] == INVALID_HANDLE )
	{
		InitPresentBoxData( client );
	}

	// データ取り出し
	new BoxIndex = -1;
	GetTrieValue( g_PresentBoxData[client], "BoxIndex", BoxIndex );
	
	// Edict名チェック
	if( EdictEqual( BoxIndex, "prop_physics_multiplayer") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString( BoxIndex, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );
		
		// バーンズプレゼントなら削除
		if( StrEqual( nameTarget, "BurnsPresent" ) )
		{
			// 削除
			AcceptEntityInput(BoxIndex, "Kill");
		}
	}
	
	// データを空に
	SetTrieValue( g_PresentBoxData[client], "BoxIndex", -1 );
	
	// 消滅タイマー終了
	ClearTimer( g_FuseTimer[ client ] );
}

/////////////////////////////////////////////////////////////////////
//
// プレゼント爆発チェック
//
/////////////////////////////////////////////////////////////////////
stock PresentExplosion( any:client )
{
	// データが初期化されていなければ生成
	if( g_JarData[client] == INVALID_HANDLE )
	{
		InitJarData( client );
	}		

	// データ取り出し
	new BoxIndex = -1;
	GetTrieValue( g_PresentBoxData[client], "BoxIndex", BoxIndex );
	
	// Edict名チェック
	if( EdictEqual( BoxIndex, "prop_physics_multiplayer") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString( BoxIndex, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );

		// 足元のエンティティチェック
		new Float:boxpos[3];
		new Float:checkpos[3];
		// とりあえず現在位置取得
		GetEntPropVector( BoxIndex, Prop_Data, "m_vecAbsOrigin", boxpos );
		GetEntPropVector( BoxIndex, Prop_Data, "m_vecAbsOrigin", checkpos );
		// ちょっと下をチェック
		checkpos[2] -= 10.0;
		// トレースしてチェック
		g_FilteredEntity = BoxIndex;
		new Handle:TraceEx = TR_TraceRayFilterEx(boxpos, checkpos, MASK_SOLID, RayType_EndPoint, TraceFilter);
		new groundEnt = TR_GetEntityIndex(TraceEx);
		CloseHandle(TraceEx);
		
		// 下のオブジェクトチェック
		if( groundEnt != -1 )
		{
			new String:edictName[32];
			GetEdictClassname(groundEnt, edictName, sizeof(edictName));
			// 下のオブジェクトがエンジの建物および物理オブジェクトなら位置をずらして抜ける
			if (GetEntityMoveType( groundEnt ) == MOVETYPE_VPHYSICS
			|| StrEqual(edictName, "obj_dispenser",				false)
			|| StrEqual(edictName, "obj_teleporter_entrance",	false)
			|| StrEqual(edictName, "obj_teleporter_exit",		false)
			|| StrEqual(edictName, "obj_sentrygun",			false))
			{
				new Float:vel[3];
				GetEntPropVector( BoxIndex, Prop_Data, "m_vecAbsVelocity", vel );
				vel[0] += GetRandomFloat(0.1,1.0);
				vel[1] += GetRandomFloat(0.1,1.0);
				TeleportEntity( BoxIndex, NULL_VECTOR, NULL_VECTOR, vel );
				return;
			}
		}
		
		
		// バーンズプレゼントならチェック
		if( StrEqual( nameTarget, "BurnsPresent" ) )
		{
			new Float:nowPos[3];
			new Float:lastPos[3];
			new Float:diffPos[3];
			GetEntPropVector( BoxIndex, Prop_Data, "m_vecAbsOrigin", nowPos );	// 現在位置取得
			GetTrieArray( g_PresentBoxData[client], "LastPos", lastPos, 3 );	// 前回の位置取得
			SubtractVectors( lastPos, nowPos, diffPos );						// 前回との差を取得
			
			// 上昇チェック
			if( diffPos[2] > 0 )
			{
				SetTrieValue( g_PresentBoxData[client], "VelUp",	false );
			}
			else if( diffPos[2] < 0 )
			{
				SetTrieValue( g_PresentBoxData[client], "VelUp",	true );				
			}
			
			new VelUp;
			GetTrieValue( g_PresentBoxData[client], "VelUp",	VelUp );
			
			// 移動速度がほぼ停止状態なら削除(地面)
			if( GetVectorLength( diffPos ) <= 0.01 && !VelUp)
			{
				// 向きを変える
				new Float:ang[3];
				TeleportEntity( BoxIndex, NULL_VECTOR, ang, NULL_VECTOR );
				new Float:effAng[3];
				effAng[0] = 90.0;
				// エフェクト
				ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_STAR,		5.0 );
				ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_CONFETTI,	5.0 );
				ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_FLASH,		5.0 );
				ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_DEBRIS,	5.0, NULL_VECTOR, effAng );
				
				// サウンド
				StopSound( BoxIndex, 0, SOUND_EXPLOSION_1 );
				StopSound( BoxIndex, 0, SOUND_EXPLOSION_2 );
				StopSound( BoxIndex, 0, SOUND_FLAME );
				EmitSoundToAll( SOUND_EXPLOSION_1,	BoxIndex, _, _, SND_CHANGEPITCH, 0.5, 40 );
				EmitSoundToAll( SOUND_EXPLOSION_2,	BoxIndex, _, _, _, 1.0 );
				EmitSoundToAll( SOUND_FLAME,		BoxIndex, _, _, SND_CHANGEPITCH, 1.0, 100 );
				
				// 燃えるエリア作成
				SpawnBurnArea( client );

				// 削除
				RemovePresent( client );
			}
			else
			{
				// 消滅タイマー終了してたら消す
				if( g_FuseTimer[ client ] == INVALID_HANDLE )
				{
					// 向きを変える
					new Float:ang[3];
					TeleportEntity( BoxIndex, NULL_VECTOR, ang, NULL_VECTOR );
					new Float:effAng[3];
					effAng[0] = 90.0;
					
					// エフェクト
					ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_STAR,		5.0 );
					ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_CONFETTI,	5.0 );
					ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_FLASH,		5.0 );
					ShowParticleEntity( BoxIndex,	EFFECT_EXPLOSION_DEBRIS,	5.0, NULL_VECTOR, effAng );
					
					// サウンド
					StopSound( BoxIndex, 0, SOUND_EXPLOSION_1 );
					StopSound( BoxIndex, 0, SOUND_EXPLOSION_2 );
					EmitSoundToAll( SOUND_EXPLOSION_1,	BoxIndex, _, _, SND_CHANGEPITCH, 0.5, 40 );
					EmitSoundToAll( SOUND_EXPLOSION_2,	BoxIndex, _, _, _, 1.0 );
					
					// 削除
					RemovePresent( client );
				}
				else
				{
					// 現在位置保存
					SetTrieArray( g_PresentBoxData[client], "LastPos", nowPos, 3 );
				}
			}
			
		}
	}
	
}


/////////////////////////////////////////////////////////////////////
//
// 燃えるエリア作成
//
/////////////////////////////////////////////////////////////////////
stock SpawnBurnArea( any:client )
{
	// データが初期化されていなければ生成
	if( g_PresentBoxData[client] == INVALID_HANDLE )
	{
		InitPresentBoxData( client )
	}

	// 残っているのを削除
	RemoveBurnArea( client );
	
	// データ取り出し
	new BoxIndex = -1;
	GetTrieValue( g_PresentBoxData[client], "BoxIndex", BoxIndex );
	
	// Edict名チェック
	if( EdictEqual( BoxIndex, "prop_physics_multiplayer") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString( BoxIndex, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );

		if( StrEqual( nameTarget, "BurnsPresent" ) )
		{	
			new area = CreateEntityByName("prop_dynamic");
			if( IsValidEntity( area ) )
			{
				DispatchKeyValue( area, "targetname", "BurnsArea" );				// 名前設定
				SetEntPropEnt	( area, Prop_Data, "m_hOwnerEntity",	client);	// 持ち主
				SetEntityModel	( area, MDL_BURNAREA );								// モデル
				DispatchSpawn	( area );
						
				// 移動
				new Float:pos[3];
				GetEntPropVector( BoxIndex, Prop_Data, "m_vecAbsOrigin", pos );		// 現在位置取得
				// 移動
				pos[2] -= 15.0;
				TeleportEntity( area, pos, NULL_VECTOR, NULL_VECTOR );
			
				// チームで色分け
				SetEntityRenderMode( area, RENDER_TRANSCOLOR );
				AcceptEntityInput( area, "DisableShadow" );
				if( GetClientTeam( client ) == _:TFTeam_Red )
				{
					SetEntityRenderColor( area, 200, 0, 0, 64 );
				}
				else
				{
					SetEntityRenderColor( area, 0, 0, 255, 64 );
				}
				
				// 消滅時間
				new Float:burnTime = GetConVarFloat( g_BurningTime );
				
				// データ取り出し
				new FireEffects[12] = -1;
				GetTrieArray( g_PresentBoxData[client], "FireEffects", FireEffects, 12 );

				// 炎のエフェクト出現
				new Float:posFire[3];
				posFire[2] = 5.0;
//				AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = 22.0;
				posFire[1] = 22.0;
				FireEffects[0] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = -22.0;
				posFire[1] = -22.0;
				FireEffects[1] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = -22.0;
				posFire[1] = 22.0;
				FireEffects[2] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = 22.0;
				posFire[1] = -22.0;
				FireEffects[3] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				
				posFire[0] = 0.0;
				posFire[1] = -30.0;
				FireEffects[4] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = 0.0;
				posFire[1] = 30.0;
				FireEffects[5] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = -30.0;
				posFire[1] = 0.0;
				FireEffects[6] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = 30.0;
				posFire[1] = 0.0;
				FireEffects[7] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				
				posFire[0] = 0.0;
				posFire[1] = -15.0;
				FireEffects[8] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = 0.0;
				posFire[1] = 15.0;
				FireEffects[9] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = -15.0;
				posFire[1] = 0.0;
				FireEffects[10] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );
				posFire[0] = 15.0;
				posFire[1] = 0.0;
				FireEffects[11] = AttachLoopParticle( area, EFFECT_AREA_FIRE, posFire );

				// データ保存
				SetTrieArray( g_PresentBoxData[client], "FireEffects", FireEffects, 12 );
			
				
				// タイマー作成
				ClearTimer( g_BurnTimer[ client ] );
				g_BurnTimer[ client ] = CreateTimer( burnTime, Timer_BurnEnd, client );

				// 一度ダメージ
				CreateTimer( 0.0, Timer_BurnDamage, client );

				// タイマー作成
				ClearTimer( g_BurnDamageTimer[ client ] );
				g_BurnDamageTimer[ client ] = CreateTimer( GetConVarFloat( g_DamageInterval ), Timer_BurnDamage, client, TIMER_REPEAT );
				
				
				// データ入れる
				SetTrieValue( g_PresentBoxData[client], "BurnAreaIndex", area );

				// 足元のエンティティチェック
				new Float:areapos[3];
				new Float:checkpos[3];
				// とりあえず現在位置取得
				GetEntPropVector( area, Prop_Data, "m_vecAbsOrigin", areapos );
				GetEntPropVector( area, Prop_Data, "m_vecAbsOrigin", checkpos );
				// 少し下をチェック
				checkpos[2] -= 10.0;
				// トレースチェック
				g_FilteredEntity = area;
				new Handle:TraceEx = TR_TraceRayFilterEx(areapos, checkpos, MASK_SOLID, RayType_EndPoint, TraceFilter);
				new groundEnt = TR_GetEntityIndex(TraceEx);
				CloseHandle(TraceEx);
				
				// 地面が移動するタイプなら親を設定
				if( groundEnt != -1 )
				{
					if( GetEntityMoveType( groundEnt ) == MOVETYPE_PUSH )
					{
						SetVariantString( "!activator" );
						AcceptEntityInput( area, "SetParent", groundEnt, groundEnt, 0 );
					}
				}
				
			}
		}
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// バーンエリア消滅
//
/////////////////////////////////////////////////////////////////////
stock RemoveBurnArea( any:client )
{
	ClearTimer(g_BurnTimer[client]);
	
	// データが初期化されていなければ生成
	if( g_PresentBoxData[client] == INVALID_HANDLE )
	{
		InitPresentBoxData( client );
	}		
	
	// データ取り出し
	new FireEffects[12] = -1;
	GetTrieArray( g_PresentBoxData[client], "FireEffects", FireEffects, 12 );
	
	for( new i = 0; i < 12; i++ )
	{
		//PrintToChat( client, "%d", FireEffects[i] );
		DeleteParticle( FireEffects[i] )
		FireEffects[i] = -1;
	}

	// データ取り出し
	new BurnAreaIndex = -1;
	GetTrieValue( g_PresentBoxData[client], "BurnAreaIndex", BurnAreaIndex );

	// Edict名チェック
	if( EdictEqual( BurnAreaIndex, "prop_dynamic") )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString( BurnAreaIndex, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );
		
		// バーンズプレゼントなら削除
		if( StrEqual( nameTarget, "BurnsArea" ) )
		{
			// 削除
			AcceptEntityInput(BurnAreaIndex, "Kill");
		}
	}
	// データを空に
	SetTrieValue( g_PresentBoxData[client], "BurnAreaIndex", -1 );
	
	// データ保存
	SetTrieArray( g_PresentBoxData[client], "FireEffects", FireEffects, 12 );
	
}

/////////////////////////////////////////////////////////////////////
//
// 炎消滅
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_BurnEnd(Handle:timer, any:client)
{
	g_BurnTimer[client] = INVALID_HANDLE;
	
	// バーンエリア削除
	RemoveBurnArea( client );
}

/////////////////////////////////////////////////////////////////////
//
// ダメージ
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_BurnDamage(Handle:timer, any:client)
{
	// データが初期化されていなければ生成
	if( g_PresentBoxData[client] == INVALID_HANDLE )
	{
		InitPresentBoxData( client );
	}		

	// データ取り出し
	new BurnAreaIndex = -1;
	GetTrieValue( g_PresentBoxData[client], "BurnAreaIndex", BurnAreaIndex );

	// Edict名チェック
	if( EdictEqual( BurnAreaIndex, "prop_dynamic" ) )
	{
		// ターゲット名取得取得
		new String:nameTarget[64];
		GetEntPropString( BurnAreaIndex, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );
		
		// バーンズエリア
		if( StrEqual( nameTarget, "BurnsArea" ) )
		{
			if( !( GetEntityFlags( BurnAreaIndex ) & FL_INWATER ) )
			{
				// 近くにいる敵にダメージ＆燃やす
				new maxclients = GetMaxClients();
				for (new target = 1; target <= maxclients; target++)
				{
					// ターゲットが生きてる パイロ以外 無敵じゃない
					if( IsClientInGame( target ) && IsPlayerAlive( target )
					&& TF2_GetPlayerClass( target ) != TFClass_Pyro 
					&& !TF2_IsPlayerInvuln(target) 
					&& !TF2_IsPlayerBlur(target) )
					{
						// 敵チーム
						if( GetClientTeam( client ) != GetClientTeam( target ) )
						{
							new Float:firePos[3];
							// 火の位置
							GetEntPropVector( BurnAreaIndex, Prop_Data, "m_vecAbsOrigin", firePos );
							firePos[2] += 20.0;
							new Float:targetPos[3];
							GetEntPropVector( target, Prop_Data, "m_vecAbsOrigin", targetPos );
							
							if( CanSeeTarget( BurnAreaIndex, firePos, target, targetPos, 1.5, true, false ) )
							{
								// 燃える
								TF2_IgnitePlayer( target, client );
								
								// ダメージ
								new nowHealth = GetClientHealth( target );
								nowHealth -= GetConVarInt( g_Damage );
								if( nowHealth <= 0 )
								{
									nowHealth = 1;
								}
								SetEntityHealth( target, nowHealth );
								
								// ダメージ表示
								new Handle:newEvent = CreateEvent( "player_hurt" );
								if( newEvent != INVALID_HANDLE )
								{
									SetEventInt( newEvent, "userid", GetClientUserId( target ) );
									SetEventInt( newEvent, "health", nowHealth );
									SetEventInt( newEvent, "attacker", GetClientUserId( client ) );
									SetEventInt( newEvent, "damageamount", GetConVarInt( g_Damage ) );
									SetEventInt( newEvent, "weaponid", _:WEAPONID_FLAMETHROWER );
									FireEvent( newEvent );
								}
							}
						}
					}
				}			
			
				return;
			}
		}
	}
	
	// タイマー削除
	ClearTimer( g_BurnDamageTimer[ client ] );
}

