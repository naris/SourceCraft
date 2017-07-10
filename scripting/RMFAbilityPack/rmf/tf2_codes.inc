/////////////////////////////////////////////////////////////////////
//
// TF2用関数群
//
/////////////////////////////////////////////////////////////////////
#if defined _tf2_codes_included
#endinput
#endif
#define _tf2_codes_included

/////////////////////////////////////////////////////////////////////
//
// インクルード
//
/////////////////////////////////////////////////////////////////////
#include <tf2_stocks>
#include "rmf/tf2_items"

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define TF2_PLAYER_SLOWED		(1 << 0)    // 1		スロー中
#define TF2_PLAYER_ZOOMED		(1 << 1)    // 2		ズーム中
#define TF2_PLAYER_DISGUISING	(1 << 2)    // 4		変装開始
#define TF2_PLAYER_DISGUISED	(1 << 3)    // 8		変装中
#define TF2_PLAYER_CLOAKED		(1 << 4)    // 16		透明中
#define TF2_PLAYER_INVULN		(1 << 5)    // 32		無敵ユーバー中
#define TF2_PLAYER_GLOWING		(1 << 6)    // 64		テレポーター粒子付着中
#define TF2_PLAYER_TAUNTING		(1 << 7)    // 128		挑発中
//#define TF2_PLAYER_??	        (1 << 8)    // 256 		?
//#define TF2_PLAYER_??	        (1 << 9)    // 512 		?
#define TF2_PLAYER_TELEPORT		(1 << 10)   // 1024		テレポート中
#define TF2_PLAYER_CRITS	    (1 << 11)   // 2048		クリティカルユーバー中
//#define TF2_PLAYER_??	        (1 << 12)   // 4096 	
#define TF2_PLAYER_FEIGNDEATH	(1 << 13)   // 8192		偽死体出現中
#define TF2_PLAYER_BLUR			(1 << 14)   // 16384	Bonk中
#define TF2_PLAYER_STUN			(1 << 15)   // 32768 	ピヨり
#define TF2_PLAYER_BUFF			(1 << 16)   // 65536 	バフ中
#define TF2_PLAYER_CHARGING		(1 << 17)   // 131072 	タックル中
#define TF2_PLAYER_HEALING		(1 << 19)   // 524288 	回復され中
#define TF2_PLAYER_ONFIRE		(1 << 20)   // 1048576 	炎上中
#define TF2_PLAYER_OVERHEALING  (1 << 21)   // 2097152	オーバーヒール中
#define TF2_PLAYER_URINE		(1 << 22)   // 4194304	小便まみれ

// COND
#define TF2_COND_SLOWED			0	// 	スロー中
#define TF2_COND_ZOOMED			1	// 	ズーム中
#define TF2_COND_DISGUISING		2	// 	変装開始
#define TF2_COND_DISGUISED		3	// 	変装中
#define TF2_COND_CLOAKED		4	// 	透明中
#define TF2_COND_INVULN			5	// 	無敵ユーバー中
#define TF2_COND_GLOWING		6	// 	テレポーター粒子付着中
#define TF2_COND_TAUNTING		7	// 	挑発中
//#define TF2_PLAYER_??	        8	// 	?
//#define TF2_PLAYER_??	        9	// 	?
#define TF2_COND_TELEPORT		10	// 	テレポート中
#define TF2_COND_CRITS	    	11	// 	クリティカルユーバー中
//#define TF2_PLAYER_??	        12	// 	
#define TF2_COND_FEIGNDEATH		13	// 	偽死体出現中
#define TF2_COND_BLUR			14	// 	Bonk中
#define TF2_COND_STUN			15	// 	ピヨり
#define TF2_COND_BUFF			16	// 	バフ中
#define TF2_COND_CHARGING		17	// 	タックル中
#define TF2_COND_HEALING		19	// 	回復され中
#define TF2_COND_ONFIRE			20	//  	炎上中
#define TF2_COND_OVERHEALING  	21	// 	オーバーヒール中
#define TF2_COND_URINE			22	// 	小便まみれ


// フェード
#define IN  (0x0001 | 0x0010)
#define OUT (0x0002 | 0x0008)


// ゲームモード
enum TFGameType
{
	TFGameMode_UNKOWN,
	TFGameMode_CP,
	TFGameMode_CTF,
	TFGameMode_ARENA,
	TFGameMode_PL,
	TFGameMode_PLR,
	TFGameMode_KOTH
};

// 武器アイテム(ダメージ受けたイベントで使用)
enum TFWeaponID
{
	WEAPONID_BAT				= 1,	// バット
	WEAPONID_SANDMAN			= 2,	// サンドマン
	WEAPONID_BOTTLE				= 3,	// ボトル
	WEAPONID_FIREAXE			= 4,	// 消防斧・消火斧
	WEAPONID_KUKRI				= 5,	// ククリ
	WEAPONID_KNIFE				= 7,	// ナイフ
	WEAPONID_FISTS				= 8,	// フィスト・KGB
	WEAPONID_SHOVEL				= 9,	// ショベル・イコライザー
	WEAPONID_WRENCH				= 10,	// レンチ
	WEAPONID_BONESAW			= 11,	// ボーンソウ・ユーバーソウ
	WEAPONID_SHOTGUN_ENG		= 12,	// ショットガン(エンジ)
	WEAPONID_SHOTGUN_SOLDIER	= 13,	// ショットガン(ソルジャー)
	WEAPONID_SHOTGUN_HEAVY		= 14,	// ショットガン(ヘビー)
	WEAPONID_SCATTERGUN			= 16,	// スカッターガン・FAN
	WEAPONID_SHOTGUN_PYRO		= 15,	// ショットガン(パイロ)
	WEAPONID_SNIPERIFLE			= 17,	// スナイパーライフル
	WEAPONID_MINIGUN			= 18,	// ミニガン・ナターシャ
	WEAPONID_SMG				= 19,	// サブマシンガン
	WEAPONID_SYRINGEGUN			= 20,	// シリンジガン・ブルートザオガー
	WEAPONID_ROCKETLAUNCHER		= 22,	// ロケットランチャー
	WEAPONID_GRENADELAUNCHER	= 23,	// グレネードランチャー
	WEAPONID_STICKYBOMBLAUNCHER	= 24,	// 粘着爆弾ランチャー
	WEAPONID_FLAMETHROWER		= 25,	// 火炎放射器・バックバーナー
	WEAPONID_PISTOL_ENG			= 40,	// ピストル(エンジ)
	WEAPONID_PISTOL_SCOUT		= 41,	// ピストル(スカウト)
	WEAPONID_REVOLVER			= 42,	// リボルバー・アンバサダー
	WEAPONID_FLAREGUN			= 57,	// フレアガン
	WEAPONID_HUNTSMAN			= 60,	// ハンツマン
	WEAPONID_EYELANDER			= 63,	// アイランダー
	WEAPONID_DIRECTHIT			= 64	// ダイレクトヒット
};
	
/////////////////////////////////////////////////////////////////////
//
// グローバル変数
//
/////////////////////////////////////////////////////////////////////
new g_FilteredEntity = -1;		// フィルタ


/////////////////////////////////////////////////////////////////////
//
// プレイヤー状態取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetPlayerCond(client)
{
    return GetEntProp(client, Prop_Send, "m_nPlayerCond");
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤー状態設定
//
/////////////////////////////////////////////////////////////////////
stock TF2_SetPlayerCond(client,playerCond)
{
    SetEntProp(client, Prop_Send, "m_nPlayerCond", playerCond);
}

/////////////////////////////////////////////////////////////////////
//
// ヒーラー数取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetNumHealers(client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

/////////////////////////////////////////////////////////////////////
//
// ズーム中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerZoomed(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_ZOOMED) != 0) : false;
}
/////////////////////////////////////////////////////////////////////
//
// 回復中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerHealing(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_HEALING) != 0) : false;
}
/////////////////////////////////////////////////////////////////////
//
// オーバーヒールされてる？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerOverHealing(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_OVERHEALING) != 0) : false;
}
/////////////////////////////////////////////////////////////////////
//
// 尿まみれ？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerUrine(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_URINE) != 0) : false;
}
/////////////////////////////////////////////////////////////////////
//
// 挑発中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerTaunt(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_TAUNTING) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// スロー中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerSlowed(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_SLOWED) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// 変装中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerDisguised(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_DISGUISED) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// 透明・解除移行中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerChangingCloak(client)
{
	if( TF2_GetPlayerClass(client) == TFClass_Spy )
	{
		if(GetGameTime() <= GetEntPropFloat(client, Prop_Send, "m_flInvisChangeCompleteTime"))
		{
			return true;
		}
	}
	return false;
}

/////////////////////////////////////////////////////////////////////
//
// 透明中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerCloaked(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_CLOAKED) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// 偽死亡中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerFeignDeath(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_FEIGNDEATH) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// Bonk中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerBlur(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_BLUR) != 0) : false;
}
/////////////////////////////////////////////////////////////////////
//
// Stun中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerStun(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_STUN) != 0) : false;
}
/////////////////////////////////////////////////////////////////////
//
// ユーバー発動中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerChargeReleased(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if( StrEqual(classname, "CWeaponMedigun") )
		{
			return bool:GetEntProp(index, Prop_Send, "m_bChargeRelease");
		}
	}		
	return false;
}

/////////////////////////////////////////////////////////////////////
//
// ユーバー発動中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerUber(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & (TF2_PLAYER_INVULN | TF2_PLAYER_CRITS)) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// 無敵ユーバー中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerInvuln(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_INVULN) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// クリッツユーバー中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerCrits(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_CRITS) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// 炎上中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerOnFire(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_ONFIRE) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// タックル中？
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsPlayerCharging(client)
{
    new pcond = TF2_GetPlayerCond(client);
    return pcond >= 0 ? ((pcond & TF2_PLAYER_CHARGING) != 0) : false;
}

/////////////////////////////////////////////////////////////////////
//
// 透明状態設定
//
/////////////////////////////////////////////////////////////////////
stock TF2_SetPlayerCloak(client, bool:enabled)
{
    new playerCond = TF2_GetPlayerCond(client);
    if (enabled)
        TF2_SetPlayerCond(client, (playerCond | TF2_PLAYER_CLOAKED));
    else
        TF2_SetPlayerCond(client, (playerCond & (~TF2_PLAYER_CLOAKED)));
}

/////////////////////////////////////////////////////////////////////
//
// 各クラス移動速度取得
//
/////////////////////////////////////////////////////////////////////
stock Float:TF2_GetClassSpeed(TFClassType:class)
{
    switch (class)
    {
        case TFClass_Scout:     return 400.0;
        case TFClass_Soldier:   return 240.0;
        case TFClass_DemoMan:   return 280.0;
        case TFClass_Medic:     return 320.0;
        case TFClass_Pyro:      return 300.0;
        case TFClass_Spy:       return 300.0;
        case TFClass_Engineer:  return 300.0;
        case TFClass_Sniper:    return 300.0;
        case TFClass_Heavy:     return 230.0;
    }
    return 0.0;
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーの速度取得
//
/////////////////////////////////////////////////////////////////////
stock Float:TF2_GetPlayerClassSpeed(client)
{
	// スロー時
    if( TF2_IsPlayerSlowed( client ) )
	{
		// ハンツマン構えてるときは違う
		if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon( client ) ) == _:ITEM_WEAPON_HUNTSMAN )
		{
			if( TF2_GetPlayerSniperCharge( client ) > 0 )
			{
				return 160.0;
			}
		}
		
		return 80.0;
	}
	
	// イコライザーのときは可変
	if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon( client ) ) == _:ITEM_WEAPON_PICKAXE )
	{
		new health = GetClientHealth( client );
		if( health <= 300 && health > 160)
		{
	        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) );
		}
		else if( health <= 160 && health > 120)
		{
	        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.1;
		}
		else if( health <= 120 && health > 80)
		{
	        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.2;
		}
		else if( health <= 80 && health > 40)
		{
	        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.4;
		}
		else if( health <= 40 && health > 0)
		{
	        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.6;
		}
	}
	
	// アイランダーのときも可変
	new weaponIndex = GetPlayerWeaponSlot(client, 2);
	if( weaponIndex != -1)
	{
		if( TF2_GetItemDefIndex( weaponIndex ) == _:ITEM_WEAPON_EYELANDER )
		{
			new head = TF2_GetDecapitations( client );
			if( head == 1 )
			{
		        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.08;
			}
			else if( head == 2 )
			{
		        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.16;
			}
			else if( head == 3 )
			{
		        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.24;
			}
			else if( head >= 4 )
			{
		        return TF2_GetClassSpeed( TF2_GetPlayerClass( client ) ) * 1.32;
			}
		}
	}

	
	// タックル中は750
	if( TF2_IsPlayerCharging( client ) )
	{
		return 750.0;
	}
	
	return TF2_GetClassSpeed(TF2_GetPlayerClass(client));
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーの速度取得
//
/////////////////////////////////////////////////////////////////////
stock Float:TF2_GetPlayerSpeed(client)
{
	if( client > 0 )
	{
		new Float:vec[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
		return GetVectorLength(vec);
	}
	return 0.0;
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーの速度設定
//
/////////////////////////////////////////////////////////////////////
stock Float:TF2_SetPlayerSpeed(client, Float:speed)
{
	if( client > 0 )
	{
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", speed);
	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーの足の速さデフォルトに
//
/////////////////////////////////////////////////////////////////////
stock Float:TF2_SetPlayerDefaultSpeed(client)
{
	if( client > 0 )
	{
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", TF2_GetPlayerClassSpeed(client));
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", TF2_GetPlayerClassSpeed(client));
	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーのデフォルトヘルス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetPlayerDefaultHealth(client)
{
	if( client > 0 )
	{
	    return GetEntProp(client, Prop_Data, "m_iMaxHealth");
	}  
	return 100;
}
/////////////////////////////////////////////////////////////////////
//
// プレイヤーの最大ヘルス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetPlayerMaxHealth(client)
{
	if( client > 0 )
	{	
		switch ( TF2_GetPlayerClass( client ) )
		{
			case TFClass_Scout:
			{
				// サンドマン時は140
				new weaponIndex = GetPlayerWeaponSlot( client, 2 );
				if( weaponIndex != -1)
				{
					if( TF2_GetItemDefIndex( weaponIndex ) == _:ITEM_WEAPON_SANDMAN )
					{
						return 140;
					}
					else
					{
						return 185;
					}
				}
			}
			case TFClass_Soldier:	return 300;
			case TFClass_DemoMan:
			{
				// アイランダーのときは可変
				new weaponIndex = GetPlayerWeaponSlot( client, 2 );
				if( TF2_GetItemDefIndex( weaponIndex ) == _:ITEM_WEAPON_EYELANDER )
				{
					new head = TF2_GetDecapitations( client );
					if( head == 1 )
					{
				 		return 248;
					}
					else if( head == 2 )
					{
						return 270;
					}
					else if( head == 3 )
					{
				        return 293;
					}
					else if( head >= 4 )
					{
						return 315;
					}
					else
					{
						return 225;
					}
				}	
				else
				{
					return 260;
				}
			}
			case TFClass_Medic:		return 225;
			case TFClass_Pyro:		return 260;
			case TFClass_Spy:		return 185;
			case TFClass_Engineer:	return 185;
			case TFClass_Sniper:	return 185;
			case TFClass_Heavy:		return 450;
		}
	}
	return 100;	
	
//	
//	
//		return RoundFloat(GetEntProp(client, Prop_Data, "m_iMaxHealth") * 1.5);
//	}  
//	return 100;
}

/////////////////////////////////////////////////////////////////////
//
// ターゲットがプレイヤーかどうかチェック
//
/////////////////////////////////////////////////////////////////////
stock bool:IsPlayer( client )
{
	if( client > 0 )
	{
		new String:classname[64];
		TF2_GetWeaponClass( client, classname, sizeof( classname ) );
		
		if( StrEqual(classname, "CTFPlayer") )
		{
			return true;
		}
	}
	
	return false;
}
/////////////////////////////////////////////////////////////////////
//
// ターゲットが人間かどうかチェック
//
/////////////////////////////////////////////////////////////////////
stock bool:IsHuman( client )
{
	if( client > 0 )
	{
		new String:classname[64];
		TF2_GetWeaponClass( client, classname, sizeof( classname ) );
		
		if( StrEqual(classname, "CTFPlayer") )
		{
			if( !IsFakeClient( client ) )
			{
				return true;
			}
		}
	}
	
	return false;
}

/////////////////////////////////////////////////////////////////////
//
// 現在の制圧数取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetPlayerDominations( client )
{
	new dominations;
	new offset = FindSendPropInfo("CTFPlayerResource", "m_iActiveDominations");
	new ent = FindEntityByClassname(-1, "tf_player_manager");
	if (ent != -1)
		dominations = GetEntData(ent, (offset + client*4), 4);    
	return dominations;
}

/////////////////////////////////////////////////////////////////////
//
// 武器クラス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if( client > 0 )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

/////////////////////////////////////////////////////////////////////
//
// 指定武器クラス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetWeaponClass(index, String:name[], maxlength)
{
	if (index > 0)
		GetEntityNetClass(index, name, maxlength);
}

/////////////////////////////////////////////////////////////////////
//
// 指定武器クラス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetWeaponEdictName(index, String:name[], maxlength)
{
	if (index > 0)
		GetEdictClassname(index, name, maxlength);
}

////////////////////////////////////////
//
// 切り落とした首の数取得
//
////////////////////////////////////////
stock TF2_GetDecapitations(any:client)
{
	if( client > 0 )
	{
		// チェック
		return GetEntProp(client, Prop_Send, "m_iDecapitations");
	}
	return -1;
}
////////////////////////////////////////
//
// 現在の武器チェック
//
////////////////////////////////////////
stock bool:TF2_CurrentWeaponEqual(client, String:name[])
{
	if( client > 0 )
	{
		// 武器名取得
		new String:classname[64];
		TF2_GetCurrentWeaponClass(client, classname, 64);
		return StrEqual(classname, name);
	}
	return false;
}
////////////////////////////////////////
//
// 現在の武器
//
////////////////////////////////////////
stock TF2_GetCurrentWeapon(any:client)
{
	if( client > 0 )
	{
		// チェック
		new weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		return weaponIndex;
	}
	return -1;
}
////////////////////////////////////////
//
// スロットの残弾数
//
////////////////////////////////////////
stock TF2_GetSlotAmmo(any:client, slot)
{
	if( client > 0 )
	{
		new offset = FindDataMapOffs(client, "m_iAmmo") + ((slot + 1) * 4);
		return GetEntData(client, offset, 4);
	}
	return -1;
}

////////////////////////////////////////
//
// スロット武器のクリップ残弾数
//
////////////////////////////////////////
stock TF2_GetSlotClip(any:client, slot)
{
	if( client > 0 )
	{
		new weaponIndex = GetPlayerWeaponSlot(client, slot);
		if( weaponIndex != -1 )
		{
			return GetEntProp( weaponIndex, Prop_Send, "m_iClip1" );
		}
	}
	return -1;
}

////////////////////////////////////////
//
// スロットの武器取得
//
////////////////////////////////////////
stock TF2_GetSlotWeapon(any:client, slot)
{
	if( client > 0 && slot >= 0)
	{
		new weaponIndex = GetPlayerWeaponSlot(client, slot-1);
		return weaponIndex;
	}
	return -1;
}

/////////////////////////////////////////////////////////////////////
//
// 指定したスロットの武器を削除
//
/////////////////////////////////////////////////////////////////////
stock DeletePlayerSlot(any:client, deleteSlot, afterSlot)
{
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// 指定スロットの武器削除
		new weaponIndex = GetPlayerWeaponSlot(client, deleteSlot);
		if( weaponIndex != -1 )
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
			TF2_RemoveWeaponSlot(client, deleteSlot);
			
			if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == -1)
			{
				ClientCommand(client, "slot%d", afterSlot);
			}
		}	
	}			
}

////////////////////////////////////////
//
// サッパーが仕掛けられるかチェック
//
////////////////////////////////////////
stock bool:TF2_IsAllowPlantSapper(client)
{
	if( client > 0 )
	{
		if(TF2_CurrentWeaponEqual(client, "CTFWeaponBuilder"))
		{
			// チェック
			new weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (weaponIndex > 0)
			{
				if(GetEntProp(weaponIndex, Prop_Send, "m_iBuildState")==2)
				{
					return true;
				}
			}
		}
	}
	return false;
}

////////////////////////////////////////
//
// 名前チェック
//
////////////////////////////////////////
stock bool:TF2_EdictNameEqual(entity, String:name[])
{
	if( entity > 0 )
	{
		if(IsValidEdict(entity))
		{
			new String:edictName[64];
			GetEdictClassname(entity, edictName, sizeof(edictName)); 
			return StrEqual(edictName, name);
		}
	}
	return false;
}

			
////////////////////////////////////////
//
// ユーバー量取得
//
////////////////////////////////////////
stock TF2_GetPlayerUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
					
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if( StrEqual(classname, "CWeaponMedigun") )
		{
			return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
		}
		
	}
	return 0;
}

////////////////////////////////////////
//
// ユーバー量設定
//
////////////////////////////////////////
stock TF2_SetPlayerUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if( StrEqual(classname, "CWeaponMedigun") )
		{
			SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
		}
	}
}

////////////////////////////////////////
//
// ヒール対象取得
//
////////////////////////////////////////
stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));
	
	if( StrEqual(classname, "CWeaponMedigun") )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}
		
	return -1;
}

/////////////////////////////////////////////////////////////////////
//
// DeadRinger準備中
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_IsReadyFeignDeath(client)
{
	if( TF2_GetPlayerClass(client) == TFClass_Spy )
	{
	    return bool:GetEntProp(client, Prop_Send, "m_bFeignDeathReady");
	}
	
	return false;
}
/////////////////////////////////////////////////////////////////////
//
// クロークメーター取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetPlayerCloakMeter(client)
{
	if( TF2_GetPlayerClass(client) == TFClass_Spy )
	{
	    return RoundFloat(GetEntPropFloat(client, Prop_Send, "m_flCloakMeter"));
	}
	
	return 100;
}

/////////////////////////////////////////////////////////////////////
//
// クロークメーター設定
//
/////////////////////////////////////////////////////////////////////
stock TF2_SetPlayerCloakMeter(client, cloakMeter)
{
 	if( TF2_GetPlayerClass(client) == TFClass_Spy )
	{
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloakMeter*1.0);
	}
}

/////////////////////////////////////////////////////////////////////
//
// メタル取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetPlayerMetalAmount(client)
{
	return GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
}

/////////////////////////////////////////////////////////////////////
//
// メタル設定
//
/////////////////////////////////////////////////////////////////////
stock TF2_SetPlayerMetalAmount(client, metal)
{
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), metal, 4);  
}


////////////////////////////////////////
//
// スナイパーチャージ量取得
//
////////////////////////////////////////
stock TF2_GetPlayerSniperCharge(client)
{
	new index = GetPlayerWeaponSlot(client, 0);
	if (index > 0)
	{
		if( TF2_GetItemDefIndex( index ) == _:ITEM_WEAPON_SNIPERRIFLE )
		{
			return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargedDamage") * 0.666);
		}
		else if( TF2_GetItemDefIndex( index ) == _:ITEM_WEAPON_HUNTSMAN )
		{
			new Float:charge = GetGameTime() - GetEntPropFloat(index, Prop_Send, "m_flChargeBeginTime");
			
			// 最大100%
			if( charge > 1.0 )
			{
				charge = 1.0;
			}
			
			if( TF2_IsPlayerSlowed( client ) )
			{
				return RoundFloat( charge * 100.0 ) ;
			}
		}
		
	}
	return 0;
}

////////////////////////////////////////
//
// スナイパーチャージ量設定
//
////////////////////////////////////////
stock TF2_SetPlayerSniperCharge(client, chargelevel)
{
	new index = GetPlayerWeaponSlot(client, 0);
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if( StrEqual(classname, "CTFSniperRifle") )
		{
			SetEntPropFloat(index, Prop_Send, "m_flChargedDamage", chargelevel * 1.5);
		}
	}
}


////////////////////////////////////////
//
// ランダムでクラスを取得
//
////////////////////////////////////////
stock TF2_GetRandomClass() 
{
	return GetRandomInt(1, 9);
}
////////////////////////////////////////
//
// 指定クラスの人数を取得
//
////////////////////////////////////////
stock TF2_GetClassPlayers( team, cls ) 
{
	new numPlayers = 0;
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if( IsClientInGame(i) && IsClientConnected(i) )
		{
			if(GetClientTeam(i) == team && TF2_GetPlayerClass(i) == TFClassType:cls)
			{
				numPlayers++;
			}
		}
	}
	return numPlayers;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////
//
// タイマークリア
//
////////////////////////////////////////
stock ClearTimer( &Handle:timer )
{
	// タイマークリア
	if( timer != INVALID_HANDLE )
	{
		KillTimer( timer );
	}
	timer = INVALID_HANDLE;
}

////////////////////////////////////////
//
// Edict名チェック
//
////////////////////////////////////////
stock bool:EdictEqual(ent, const String:name[])
{
	if( ent != -1 && IsValidEdict( ent ) )
	{
		new String:edictName[32];
		GetEdictClassname( ent, edictName, sizeof( edictName ) );
		return StrEqual( edictName, name );
	}
	return false;
}


/////////////////////////////////////////////////////////////////////
//
// オブジェクトが見えるかどうか
//
/////////////////////////////////////////////////////////////////////
stock bool:CanSeeTarget( any:origin, Float:pos[3], any:target, Float:targetPos[3], Float:range, bool:throughPlayer=true, bool:throughBuild=true )
{
	new Float:distance;			// ターゲットとの距離(メートル)
	new Float:backpos[3];		// 保存用
	backpos = pos;
	
	// ターゲット位置と距離の取得
	distance = GetVectorDistanceMeter( pos, targetPos );
	
	// ターゲットが範囲外なら脱出
	if( distance >= range )
	{
		//PrintToChatAll("%f %f", distance, range);
		return false;
	}
	
	// トレースチェック
	new Handle:TraceEx = INVALID_HANDLE
	g_FilteredEntity = origin;
	TraceEx = TR_TraceRayFilterEx( pos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter );
	new hitEnt = -1;
	hitEnt = TR_GetEntityIndex( TraceEx );	// ヒットエンティティ
	new Float:hitPos[3];
	TR_GetEndPosition( hitPos, TraceEx );	// ヒット位置
	
//	PrintToChatAll("Dist=%f", GetVectorDistanceMeter( hitPos, targetPos ));
//		new String:name[32];
//		GetEdictClassname( hitEnt, name, sizeof(name));
//	PrintToChatAll("Hit=%s", name);
//		GetEdictClassname( target, name, sizeof(name));
//		PrintToChatAll("Target=%s", name);

	// トレース先がスルー対象ならそこから更にチェック
	if( GetVectorDistanceMeter( hitPos, targetPos ) <= 1.0 )
	{
		// プレイヤースルー
		if( throughPlayer )
		{
			// ヒットしたエンティティがプレイヤー
			new String:edictName[64];
			GetEdictClassname( hitEnt, edictName, sizeof( edictName ) ); 
			if( StrEqual( edictName, "player" ) )  
			{
				// ターゲットと重なっているならヒットと判断
				GetEntPropVector( hitEnt, Prop_Data, "m_vecAbsOrigin", pos );
				if(GetVectorDistanceMeter( pos, targetPos ) > 1.0)
				{
					g_FilteredEntity = hitEnt;
					TraceEx = TR_TraceRayFilterEx( hitPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter );
					hitEnt = TR_GetEntityIndex(TraceEx);	// ヒットエンティティ
					TR_GetEndPosition( hitPos, TraceEx );	// ヒット位置
				}
				else
				{
					// 重なってる時は無条件
					pos = targetPos;
				}
			}
		}		
		// 建物スルー
		if( throughBuild )
		{
			// ヒットしたエンティティが建物
			new String:edictName[64];
			GetEdictClassname( hitEnt, edictName, sizeof( edictName ) ); 
			if( StrEqual(edictName, "obj_dispenser")
			|| StrEqual(edictName, "obj_sentrygun") 
			||	StrEqual(edictName, "obj_teleporter_entrance") 
			||	StrEqual(edictName, "obj_teleporter_exit")
			||	StrEqual(edictName, "obj_attachment_sapper")
			)
			{
				// ターゲットと重なっているならヒットと判断
				GetEntPropVector( hitEnt, Prop_Data, "m_vecAbsOrigin", pos );
				if(GetVectorDistanceMeter( pos, targetPos ) > 1.0)
				{
					g_FilteredEntity = hitEnt;
					TraceEx = TR_TraceRayFilterEx( hitPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter );
					hitEnt = TR_GetEntityIndex(TraceEx);	// ヒットエンティティ
					TR_GetEndPosition( hitPos, TraceEx );	// ヒット位置
				}
				else
				{
					// 重なってる時は無条件
					pos = targetPos;
				}
			}
		}		
	}
	// トレース地点がヒット地点と1.0以内
	if( GetVectorDistanceMeter( hitPos, targetPos ) <= 1.0 )
	{
		pos = backpos;
		return true;
	}
	//PrintToChatAll("%d %d %d", origin, target, hitEnt);

	//PrintToChatAll("disy=%f", GetVectorDistanceMeter( hitPos, targetPos ));
	
	// 値復帰
	pos = backpos;

	return false;
}


////////////////////////////////////////
//
// エンティティの最大数？
//
////////////////////////////////////////
stock bool:IsEntLimitReached()
{
	new maxclients = GetMaxClients();
	new maxents = GetMaxEntities();
	new i, c = 0;
	for(i = maxclients; i <= maxents; i++)
	{
	 	if(IsValidEntity(i))
			c += 1;
	}
	if (c >= (maxents-16))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", c, maxents);
		return true;
	}
	else
		return false;
}

////////////////////////////////////////
//
// エンティティフィルタ
//
////////////////////////////////////////
public bool:TraceFilter(ent, contentMask)
{
   return (ent == g_FilteredEntity) ? false : true;
}

////////////////////////////////////////
//
// メートルに変換
//
////////////////////////////////////////
stock Float:UnitToMeter(Float:distance)
{
   return distance / 50.00;
}

////////////////////////////////////////
//
// メートルからTFサイズ変換
//
////////////////////////////////////////
stock Float:MeterToUnit(Float:distance)
{
   return distance * 50.00;
}
////////////////////////////////////////
//
// 2点の距離をメートルで取得
//
////////////////////////////////////////
stock Float:GetVectorDistanceMeter(const Float:vec1[3], const Float:vec2[3], bool:squared=false) 
{
	return UnitToMeter( GetVectorDistance( vec1, vec2, squared ) );
}
////////////////////////////////////////
//
// 2つのオブジェクトの距離をメートルで取得
//
////////////////////////////////////////
stock Float:GetDistanceMeter(const ent1, const ent2, bool:squared=false) 
{
	new Float:pos1[3];
	new Float:pos2[3];
	
	GetEntPropVector( ent1, Prop_Data, "m_vecAbsOrigin", pos1 );
	GetEntPropVector( ent2, Prop_Data, "m_vecAbsOrigin", pos2 );
	
	return UnitToMeter( GetVectorDistance( pos1, pos2, squared ) );
}


////////////////////////////////////////
//
// パーティクル先読み
//
////////////////////////////////////////
stock PrePlayParticle(String:particlename[])
{
	if(IsValidEntity(0))
	{
	    new particle = CreateEntityByName("info_particle_system");
	    if (IsValidEdict(particle))
	    {
			new String:tName[32];
			GetEntPropString(0, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchSpawn(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", 0, particle, 0);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(0.01, RemoveParticle, particle);
	    }
	}
}


////////////////////////////////////////
//
// 簡易パーティクル
//
////////////////////////////////////////
stock ShowParticle(String:particlename[], Float:time, Float:pos[3], Float:ang[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, RemoveParticle, particle);
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
	}	
}

////////////////////////////////////////
//
// 簡易パーティクル
//
////////////////////////////////////////
stock any:ShowParticleEntity(ent, String:particleType[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if ( IsValidEdict(particle) )
	{
		new Float:pos[3];
		new Float:ang[3];
		new String:tName[32];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);

		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		//AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, RemoveParticle, particle);
	}
	else
	{
		LogError("AttachParticle: could not create info_particle_system");
	}
	
	return particle;
}

////////////////////////////////////////
//
// 簡易パーティクル
//
////////////////////////////////////////
stock any:AttachParticle(ent, String:particleType[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		new Float:ang[3];
		new String:tName[32];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);

		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, RemoveParticle, particle);
	}
	else
	{
		LogError("AttachParticle: could not create info_particle_system");
	}
	return particle;
}

////////////////////////////////////////
//
// アタッチボーン
//
////////////////////////////////////////
stock AttachParticleBone(ent, String:particleType[], String:attachBone[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
		SetVariantString(attachBone);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);

		TeleportEntity(particle, addPos, addAngle, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, RemoveParticle, particle);
	}
}

////////////////////////////////////////
//
// アタッチループパーティクル
//
////////////////////////////////////////
stock any:AttachLoopParticle(ent, String:particleType[], Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		new Float:ang[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);

		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
//		SetVariantString(attachBone);
//		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);

		AcceptEntityInput(particle, "start");
	}
	return particle;
}

////////////////////////////////////////
//
// アタッチループパーティクルボーン
//
////////////////////////////////////////
stock any:AttachLoopParticleBone(ent, String:particleType[], String:attachBone[], Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
		SetVariantString(attachBone);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);

		TeleportEntity(particle, addPos, addAngle, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

/////////////////////////////////////////////////////////////////////
//
// ループパーティクル削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteParticle(&particle, Float:delay = 0.0)
{
	if ( particle != -1 )
	{
		if( IsValidEdict( particle ) )
		{
			new String:classname[32];
			GetEdictClassname( particle, classname, sizeof( classname ) );
			if( StrEqual( classname, "info_particle_system", false ) )
			{
				ActivateEntity( particle );
				AcceptEntityInput( particle, "stop" );
				CreateTimer( delay, RemoveParticle, particle );
				particle = -1;
	        }
		}
	}
} 


////////////////////////////////////////
//
// パーティクル削除タイマー
//
////////////////////////////////////////
public Action:RemoveParticle( Handle:timer, any:particle )
{
    if ( IsValidEntity( particle) )
    {
        new String:classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "Kill");
			particle = -1;
//			RemoveEdict(particle);
        }
     //   else
    //    {
   //         LogError("RemoveParticle: not removing entity - not a particle '%s'", classname);
    //    }
    }
}

/////////////////////////////////////////////////////////////////////
//
// TEパーティクル
//
/////////////////////////////////////////////////////////////////////
stock TE_Particle(String:Name[],
			Float:origin[3]=NULL_VECTOR,
			Float:start[3]=NULL_VECTOR,
			Float:angles[3]=NULL_VECTOR,
			entindex=-1,
			attachtype=-1,
			attachpoint=-1,
			bool:resetParticles=true)
{
	// find string table
	new tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx==INVALID_STRING_TABLE) 
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}

	// find particle index
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	new i;
	for (i=0; i<count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx==INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	if (entindex!=-1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype!=-1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint!=-1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
}



/////////////////////////////////////////////////////////////////////
//
// スクリーンフェード
//
/////////////////////////////////////////////////////////////////////
public ScreenFade(client, red, green, blue, alpha, duration, type)
{
	new Handle:msg
	
	msg = StartMessageOne("Fade", client)
	BfWriteShort(msg, 255)
	BfWriteShort(msg, duration)
	BfWriteShort(msg, type)
	BfWriteByte(msg, red)
	BfWriteByte(msg, green)
	BfWriteByte(msg, blue)	
	BfWriteByte(msg, alpha)
	EndMessage()
}
/////////////////////////////////////////////////////////////////////
//
// フェード終了
//
/////////////////////////////////////////////////////////////////////
public Action:UnFade(Handle:timer, any:client)
{
    if (client)
    {
        if (IsClientInGame(client))
        {
            if (IsPlayerAlive(client))
            {
				ScreenFade(client, 0, 0, 0, 0, 2000, IN)
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// 小文字を大文字に
//
/////////////////////////////////////////////////////////////////////
stock StringToUpper(String:target[], String:source[])
{
	for(new i = 0; i < strlen(source); i++)
	{
		target[i] = CharToUpper(source[i]);		
	}
}

/////////////////////////////////////////////////////////////////////
//
// 大文字を小文字に
//
/////////////////////////////////////////////////////////////////////
stock StringToLower(String:target[], String:source[])
{
	for(new i = 0; i < strlen(source); i++)
	{
		target[i] = CharToLower(source[i]);		
	}
}

/////////////////////////////////////////////////////////////////////
//
// クライアントテキスト
//
/////////////////////////////////////////////////////////////////////
stock SayText2Client(client, const String:message[])
{
    new Handle:buffer = StartMessageOne("SayText2", client);
    if ( buffer != INVALID_HANDLE )
    {
        BfWriteByte(buffer, client);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  


/////////////////////////////////////////////////////////////////////
//
// オールテキスト
//
/////////////////////////////////////////////////////////////////////
stock SayText2All(client, const String:message[])
{
    new Handle:buffer = StartMessageAll("SayText2");
    if ( buffer != INVALID_HANDLE )
    {
        BfWriteByte(buffer, client);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  

/////////////////////////////////////////////////////////////////////
//
// ゲームモード取得
//
/////////////////////////////////////////////////////////////////////
stock TFGameType:GetGameType()
{
	new String:mapName[256];
	GetCurrentMap(mapName, sizeof(mapName));

	if( StrContains( mapName, "arena_", false ) != -1 )
	{
		return TFGameMode_ARENA;
	}
	else if( StrContains( mapName, "cp_", false ) != -1 )
	{
		return TFGameMode_CP;
	}
	else if( StrContains( mapName, "ctf_", false ) != -1 )
	{
		return TFGameMode_CTF;
	}
	else if( StrContains( mapName, "pl_", false ) != -1 )
	{
		return TFGameMode_PL;
	}
	else if( StrContains( mapName, "plr_", false ) != -1 )
	{
		return TFGameMode_PLR;
	}
	else if( StrContains( mapName, "koth_", false ) != -1 )
	{
		return TFGameMode_KOTH;
	}
	return TFGameMode_UNKOWN;

}

/////////////////////////////////////////////////////////////////////
//
// Add Cond
//
/////////////////////////////////////////////////////////////////////
stock TF2_AddCond( client, cond )
{
	new Handle:cvar = FindConVar( "sv_cheats" );
	new bool:enabled = GetConVarBool( cvar );
	new flags = GetConVarFlags( cvar );
	
	if( !enabled )
	{
		SetConVarFlags( cvar, flags^(FCVAR_NOTIFY|FCVAR_REPLICATED) );
		SetConVarBool( cvar, true );
	}
	FakeClientCommand( client, "addcond %i", cond );
	if( !enabled )
	{
		SetConVarBool( cvar, false );
		SetConVarFlags( cvar, flags );
	}
}

/////////////////////////////////////////////////////////////////////
//
// Remove Cond
//
/////////////////////////////////////////////////////////////////////
stock TF2_RemoveCond(client, cond)
{
	new Handle:cvar = FindConVar( "sv_cheats" );
	new bool:enabled = GetConVarBool( cvar );
	new flags = GetConVarFlags( cvar );
	
	if( !enabled )
	{
		SetConVarFlags( cvar, flags^(FCVAR_NOTIFY|FCVAR_REPLICATED) );
		SetConVarBool( cvar, true );
	}
	FakeClientCommand(client, "removecond %i", cond);
	if( !enabled )
	{
		SetConVarBool( cvar, false );
		SetConVarFlags( cvar, flags );
	}
}  

/////////////////////////////////////////////////////////////////////
//
// アトリビュート用の％テキスト取得
//
/////////////////////////////////////////////////////////////////////
stock GetPercentageString( Float:magnification, String:str[], maxlength )
{
	// パーセンテージを取得
	new percentage = RoundFloat( magnification * 100.0 - 100.0 );
	new String:value[16];
	
	// ストリングに変換
	IntToString( percentage, value, sizeof( value ) );
	
	if( magnification > 1.0 )
	{
		new String:plus[16];
		plus = "+";
		StrCat( plus, sizeof( plus ), value );
		strcopy( str, maxlength, plus);
	}
	else
	{
		strcopy( str, maxlength, value);
	}
}

