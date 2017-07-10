/////////////////////////////////////////////////////////////////////
//
// TF2用関数群
//
/////////////////////////////////////////////////////////////////////
#if defined _tf2_items_included
#endinput
#endif
#define _tf2_items_included

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define TF2_ITEM_NUM 140       //アイテム数


// アイテムのタイプ
enum TFItemType
{
	TYPE_UNKOWN		= 0,
	TYPE_WEAPON		= 1,
	TYPE_WEAR		= 2
};

// アイテムのスロット
enum TFItemSlot
{
	SLOT_PRIMARY	= 0,
	SLOT_SECONDARY	= 1,
	SLOT_MELEE		= 2,
	SLOT_PDA_1		= 3,
	SLOT_PDA_2		= 4,
	SLOT_BUILDING	= 5,
	SLOT_HEAD		= 6,
	SLOT_MISC		= 7,
	SLOT_UNKOWN		= 9
};

// アイテムのクオリティ
enum TFItemQuality
{
	QUALITY_NORMAL		= 0,
	QUALITY_COMMON		= 1,
	QUALITY_RARE		= 2,
	QUALITY_UNIQUE		= 3,
	QUALITY_COMMUNITY	= 7,
	QUALITY_DEVELOPER	= 8,
	QUALITY_SELFMADE	= 9
};

// 武器アイテム
enum TFItems
{
	ITEM_WEAPON_BAT					= 0,
	ITEM_WEAPON_BOTTLE				= 1,
	ITEM_WEAPON_FIREAXE				= 2,
	ITEM_WEAPON_KUKRI				= 3,
	ITEM_WEAPON_KNIFE				= 4,
	ITEM_WEAPON_FISTS				= 5,
	ITEM_WEAPON_SHOVEL				= 6,
	ITEM_WEAPON_WRENCH				= 7,
	ITEM_WEAPON_BONESAW				= 8,
	ITEM_WEAPON_SHOTGUN_ENG			= 9,
	ITEM_WEAPON_SHOTGUN_SOLDIER		= 10,
	ITEM_WEAPON_SHOTGUN_HWG			= 11,
	ITEM_WEAPON_SHOTGUN_PYRO		= 12,
	ITEM_WEAPON_SCATTERGUN			= 13,
	ITEM_WEAPON_SNIPERRIFLE			= 14,
	ITEM_WEAPON_MINIGUN				= 15,
	ITEM_WEAPON_SMG					= 16,
	ITEM_WEAPON_SYRINGEGUN			= 17,
	ITEM_WEAPON_ROCKETLAUNCHER		= 18,
	ITEM_WEAPON_GRENADELAUNCHER		= 19,
	ITEM_WEAPON_STICKYBOMBLAUNCHER	= 20,
	ITEM_WEAPON_FLAMETHROWER		= 21,
	ITEM_WEAPON_PISTOL_ENG			= 22,
	ITEM_WEAPON_PISTOL_SCOUT		= 23,
	ITEM_WEAPON_REVOLVER			= 24,
	ITEM_WEAPON_PDA_BUILD			= 25,
	ITEM_WEAPON_PDA_DESTROY			= 26,
	ITEM_WEAPON_PDA_DISGUISE		= 27,
	ITEM_WEAPON_TOOLBOX				= 28,
	ITEM_WEAPON_MEDIGUN				= 29,
	ITEM_WEAPON_WATCH_INVIS			= 30,
	ITEM_WEAPON_FLAREGUN			= 31,
	ITEM_WEAPON_BONESAW_LV1			= 32,
	ITEM_WEAPON_SYRINGEGUN_LV1		= 33,
	ITEM_WEAPON_MEDIGUN_LV1			= 34,
	ITEM_WEAPON_KRITZKRIEG			= 35,
	ITEM_WEAPON_BLUTSAUGER			= 36,
	ITEM_WEAPON_UBERSAW				= 37,
	ITEM_WEAPON_AXTINGUISHER		= 38,
	ITEM_WEAPON_FLAREGUN_HALF		= 39,
	ITEM_WEAPON_BACKBURNER			= 40,
	ITEM_WEAPON_NATASCHA			= 41,
	ITEM_WEAPON_SANDVICH			= 42,
	ITEM_WEAPON_KGB					= 43,
	ITEM_WEAPON_SANDMAN				= 44,
	ITEM_WEAPON_FAN					= 45,
	ITEM_WEAPON_BONKDRINK			= 46,
	ITEM_WEAR_DEMO_AFRO				= 47,
	ITEM_WEAR_ENG_LIGHT				= 48,
	ITEM_WEAR_HEAVY_FOOTBALL		= 49,
	ITEM_WEAR_MEDIC_PICKELHAUBE		= 50,
	ITEM_WEAR_PYRO_BEANIE			= 51,
	ITEM_WEAR_SCOUT_BATTER			= 52,
	ITEM_WEAR_SNIPER_TROPHY			= 53,
	ITEM_WEAR_SOLDIER_STASH			= 54,
	ITEM_WEAR_SPY_FEDORA			= 55,
	ITEM_WEAPON_HUNTSMAN			= 56,
	ITEM_WEAR_RAZORBACK				= 57,
	ITEM_WEAPON_JARATE				= 58,
	ITEM_WEAPON_WATCH_DEADRINGER	= 59,
	ITEM_WEAPON_WATCH_CAD			= 60,
	ITEM_WEAPON_AMBASSADOR			= 61,
	ITEM_WEAR_ENG_TENGALLON			= 94,
	ITEM_WEAR_ENG_CAP				= 95,
	ITEM_WEAR_HEAVY_USHANKA			= 96,
	ITEM_WEAR_HEAVY_STOCKING		= 97,
	ITEM_WEAR_SOLDIER_POT			= 98,
	ITEM_WEAR_SOLDIER_TYRANT		= 99,
	ITEM_WEAR_DEMO_GLENGARRY		= 100,
	ITEM_WEAR_MEDIC_TYROLEAN		= 101,
	ITEM_WEAR_PYRO_CHIKEN			= 102,
	ITEM_WEAR_SPY_CAMERA			= 103,
	ITEM_WEAR_MEDIC_MIRROR			= 104,
	ITEM_WEAR_PYRO_FIREMAN			= 105,
	ITEM_WEAR_SCOUT_BONK			= 106,
	ITEM_WEAR_SCOUT_BAKER			= 107,
	ITEM_WEAR_SPY_BILLYCOCK			= 108,
	ITEM_WEAR_SNIPER_PANAMA			= 109,
	ITEM_WEAR_SNIPER_BAND			= 110,
	ITEM_WEAR_SCOUT_HATLESS			= 111,
	ITEM_WEAR_HALLOWEEN_HAT			= 115,
	ITEM_WEAR_DOMINATION_HAT		= 116,
	ITEM_WEAR_SNIPER_HATLESS		= 117,
	ITEM_WEAR_ENG_HATLESS			= 118,
	ITEM_WEAR_DEMO_TOPHAT			= 120,
	ITEM_WEAR_SOLDIER_MEDAL			= 121,
	ITEM_CHEAT_DETECTED_MINOR		= 122,
	ITEM_CHEAT_DETECTED_MAJOR		= 123,
	ITEM_CHEAT_DETECTED_HONESTY		= 124,
	ITEM_WARE_HONEST_HALO			= 125,
	ITEM_WARE_BILL_HAT				= 126,
	ITEM_WEAPON_DIRECTHIT			= 127,
	ITEM_WEAPON_PICKAXE				= 128,
	ITEM_WEAPON_BATTLE_BANNER		= 129,
	ITEM_WEAPON_SCOTTISH_RESISTANCE	= 130,
	ITEM_WEAPON_CHARGIN_TARGE		= 131,
	ITEM_WEAPON_EYELANDER			= 132,
	ITEM_WEAPON_GUNBOATS			= 133,
	ITEM_WEAR_CONTEST_FIRST_PLACE	= 134,
	ITEM_WEAR_TOWERING_PILLAR		= 135,
	ITEM_WEAR_CONTEST_SECOND_PLACE	= 136,
	ITEM_WEAR_NOBLE_AMASSMENT		= 137,
	ITEM_WEAR_CONTEST_THIRD_PLACE	= 138,
	ITEM_WEAR_MODEST_PILE			= 139
};

/////////////////////////////////////////////////////////////////////
//
// グローバル変数
//
/////////////////////////////////////////////////////////////////////
new Handle:g_GameConf			= INVALID_HANDLE;		// ゲームコンフィグ
//new Handle:g_hGiveNamedItem		= INVALID_HANDLE;		// 指定アイテム取得関数
new Handle:g_hWeaponEquip		= INVALID_HANDLE;		// 武器装備関数
new Handle:g_hEquipWearable		= INVALID_HANDLE;		// ウェア装備
new Handle:g_hRemoveWearable	= INVALID_HANDLE;		// ウェア削除


// アイテムデータ
new Handle:g_ItemData[TF2_ITEM_NUM] = INVALID_HANDLE;

/////////////////////////////////////////////////////////////////////
//
// ゲームコンフィグ初期化
//
/////////////////////////////////////////////////////////////////////
stock InitGameConf()
{
	// ゲームコンフィグ読み込み
	g_GameConf = LoadGameConfigFile("rmf.games");

	// 指定アイテム取得関数
//	StartPrepSDKCall(SDKCall_Player);
//	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "GiveNamedItem");
//	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
//	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
//	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
//	g_hGiveNamedItem = EndPrepSDKCall();

	// 武器装備関数
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();

	// ウェア装備関数
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	// ウェア削除関数
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "RemoveWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hRemoveWearable = EndPrepSDKCall();
	
	
	// アイテムデータ初期化
	InitItemData();
}


/////////////////////////////////////////////////////////////////////
//
// アイテムデータ初期化
//
/////////////////////////////////////////////////////////////////////
stock InitItemData()
{
	// とりあえずTrie作成
	for( new i = 0; i < TF2_ITEM_NUM; i++)
	{
		// なんか入っていたら一旦削除
		if( g_ItemData[i] != INVALID_HANDLE )
		{
			ClearTrie( g_ItemData[i] );
		}
		else
		{
			// まだ作成されていなければ作成
			g_ItemData[i] = CreateTrie();
		}
	}
	
	
	// アイテムインデックス
	SetTrieValue( g_ItemData[0],	"ItemDefinitionIndex",		0	 );
	SetTrieValue( g_ItemData[1],	"ItemDefinitionIndex",		1	 );
	SetTrieValue( g_ItemData[2],	"ItemDefinitionIndex",		2	 );
	SetTrieValue( g_ItemData[3],	"ItemDefinitionIndex",		3	 );
	SetTrieValue( g_ItemData[4],	"ItemDefinitionIndex",		4	 );
	SetTrieValue( g_ItemData[5],	"ItemDefinitionIndex",		5	 );
	SetTrieValue( g_ItemData[6],	"ItemDefinitionIndex",		6	 );
	SetTrieValue( g_ItemData[7],	"ItemDefinitionIndex",		7	 );
	SetTrieValue( g_ItemData[8],	"ItemDefinitionIndex",		8	 );
	SetTrieValue( g_ItemData[9],	"ItemDefinitionIndex",		9	 );
	SetTrieValue( g_ItemData[10],	"ItemDefinitionIndex",		10	 );
	SetTrieValue( g_ItemData[11],	"ItemDefinitionIndex",		11	 );
	SetTrieValue( g_ItemData[12],	"ItemDefinitionIndex",		12	 );
	SetTrieValue( g_ItemData[13],	"ItemDefinitionIndex",		13	 );
	SetTrieValue( g_ItemData[14],	"ItemDefinitionIndex",		14	 );
	SetTrieValue( g_ItemData[15],	"ItemDefinitionIndex",		15	 );
	SetTrieValue( g_ItemData[16],	"ItemDefinitionIndex",		16	 );
	SetTrieValue( g_ItemData[17],	"ItemDefinitionIndex",		17	 );
	SetTrieValue( g_ItemData[18],	"ItemDefinitionIndex",		18	 );
	SetTrieValue( g_ItemData[19],	"ItemDefinitionIndex",		19	 );
	SetTrieValue( g_ItemData[20],	"ItemDefinitionIndex",		20	 );
	SetTrieValue( g_ItemData[21],	"ItemDefinitionIndex",		21	 );
	SetTrieValue( g_ItemData[22],	"ItemDefinitionIndex",		22	 );
	SetTrieValue( g_ItemData[23],	"ItemDefinitionIndex",		23	 );
	SetTrieValue( g_ItemData[24],	"ItemDefinitionIndex",		24	 );
	SetTrieValue( g_ItemData[25],	"ItemDefinitionIndex",		25	 );
	SetTrieValue( g_ItemData[26],	"ItemDefinitionIndex",		26	 );
	SetTrieValue( g_ItemData[27],	"ItemDefinitionIndex",		27	 );
	SetTrieValue( g_ItemData[28],	"ItemDefinitionIndex",		28	 );
	SetTrieValue( g_ItemData[29],	"ItemDefinitionIndex",		29	 );
	SetTrieValue( g_ItemData[30],	"ItemDefinitionIndex",		30	 );
	SetTrieValue( g_ItemData[31],	"ItemDefinitionIndex",		31	 );
	SetTrieValue( g_ItemData[32],	"ItemDefinitionIndex",		32	 );
	SetTrieValue( g_ItemData[33],	"ItemDefinitionIndex",		33	 );
	SetTrieValue( g_ItemData[34],	"ItemDefinitionIndex",		34	 );
	SetTrieValue( g_ItemData[35],	"ItemDefinitionIndex",		35	 );
	SetTrieValue( g_ItemData[36],	"ItemDefinitionIndex",		36	 );
	SetTrieValue( g_ItemData[37],	"ItemDefinitionIndex",		37	 );
	SetTrieValue( g_ItemData[38],	"ItemDefinitionIndex",		38	 );
	SetTrieValue( g_ItemData[39],	"ItemDefinitionIndex",		39	 );
	SetTrieValue( g_ItemData[40],	"ItemDefinitionIndex",		40	 );
	SetTrieValue( g_ItemData[41],	"ItemDefinitionIndex",		41	 );
	SetTrieValue( g_ItemData[42],	"ItemDefinitionIndex",		42	 );
	SetTrieValue( g_ItemData[43],	"ItemDefinitionIndex",		43	 );
	SetTrieValue( g_ItemData[44],	"ItemDefinitionIndex",		44	 );
	SetTrieValue( g_ItemData[45],	"ItemDefinitionIndex",		45	 );
	SetTrieValue( g_ItemData[46],	"ItemDefinitionIndex",		46	 );
	SetTrieValue( g_ItemData[47],	"ItemDefinitionIndex",		47	 );
	SetTrieValue( g_ItemData[48],	"ItemDefinitionIndex",		48	 );
	SetTrieValue( g_ItemData[49],	"ItemDefinitionIndex",		49	 );
	SetTrieValue( g_ItemData[50],	"ItemDefinitionIndex",		50	 );
	SetTrieValue( g_ItemData[51],	"ItemDefinitionIndex",		51	 );
	SetTrieValue( g_ItemData[52],	"ItemDefinitionIndex",		52	 );
	SetTrieValue( g_ItemData[53],	"ItemDefinitionIndex",		53	 );
	SetTrieValue( g_ItemData[54],	"ItemDefinitionIndex",		54	 );
	SetTrieValue( g_ItemData[55],	"ItemDefinitionIndex",		55	 );
	SetTrieValue( g_ItemData[56],	"ItemDefinitionIndex",		56	 );
	SetTrieValue( g_ItemData[57],	"ItemDefinitionIndex",		57	 );
	SetTrieValue( g_ItemData[58],	"ItemDefinitionIndex",		58	 );
	SetTrieValue( g_ItemData[59],	"ItemDefinitionIndex",		59	 );
	SetTrieValue( g_ItemData[60],	"ItemDefinitionIndex",		60	 );
	SetTrieValue( g_ItemData[61],	"ItemDefinitionIndex",		61	 );
	SetTrieValue( g_ItemData[94],	"ItemDefinitionIndex",		94	 );
	SetTrieValue( g_ItemData[95],	"ItemDefinitionIndex",		95	 );
	SetTrieValue( g_ItemData[96],	"ItemDefinitionIndex",		96	 );
	SetTrieValue( g_ItemData[97],	"ItemDefinitionIndex",		97	 );
	SetTrieValue( g_ItemData[98],	"ItemDefinitionIndex",		98	 );
	SetTrieValue( g_ItemData[99],	"ItemDefinitionIndex",		99	 );
	SetTrieValue( g_ItemData[100],	"ItemDefinitionIndex",		100	 );
	SetTrieValue( g_ItemData[101],	"ItemDefinitionIndex",		101	 );
	SetTrieValue( g_ItemData[102],	"ItemDefinitionIndex",		102	 );
	SetTrieValue( g_ItemData[103],	"ItemDefinitionIndex",		103	 );
	SetTrieValue( g_ItemData[104],	"ItemDefinitionIndex",		104	 );
	SetTrieValue( g_ItemData[105],	"ItemDefinitionIndex",		105	 );
	SetTrieValue( g_ItemData[106],	"ItemDefinitionIndex",		106	 );
	SetTrieValue( g_ItemData[107],	"ItemDefinitionIndex",		107	 );
	SetTrieValue( g_ItemData[108],	"ItemDefinitionIndex",		108	 );
	SetTrieValue( g_ItemData[109],	"ItemDefinitionIndex",		109	 );
	SetTrieValue( g_ItemData[110],	"ItemDefinitionIndex",		110	 );
	SetTrieValue( g_ItemData[111],	"ItemDefinitionIndex",		111	 );
	SetTrieValue( g_ItemData[115],	"ItemDefinitionIndex",		115	 );
	SetTrieValue( g_ItemData[116],	"ItemDefinitionIndex",		116	 );
	SetTrieValue( g_ItemData[117],	"ItemDefinitionIndex",		117	 );
	SetTrieValue( g_ItemData[118],	"ItemDefinitionIndex",		118	 );
	SetTrieValue( g_ItemData[120],	"ItemDefinitionIndex",		120	 );
	SetTrieValue( g_ItemData[121],	"ItemDefinitionIndex",		121	 );
	SetTrieValue( g_ItemData[122],	"ItemDefinitionIndex",		122	 );
	SetTrieValue( g_ItemData[123],	"ItemDefinitionIndex",		123	 );
	SetTrieValue( g_ItemData[124],	"ItemDefinitionIndex",		124	 );
	SetTrieValue( g_ItemData[125],	"ItemDefinitionIndex",		125	 );
	SetTrieValue( g_ItemData[126],	"ItemDefinitionIndex",		126	 );
	SetTrieValue( g_ItemData[127],	"ItemDefinitionIndex",		127	 );
	SetTrieValue( g_ItemData[128],	"ItemDefinitionIndex",		128	 );
	SetTrieValue( g_ItemData[129],	"ItemDefinitionIndex",		129	 );
	SetTrieValue( g_ItemData[130],	"ItemDefinitionIndex",		130	 );
	SetTrieValue( g_ItemData[131],	"ItemDefinitionIndex",		131	 );
	SetTrieValue( g_ItemData[132],	"ItemDefinitionIndex",		132	 );
	SetTrieValue( g_ItemData[133],	"ItemDefinitionIndex",		133	 );
	SetTrieValue( g_ItemData[134],	"ItemDefinitionIndex",		134	 );
	SetTrieValue( g_ItemData[135],	"ItemDefinitionIndex",		135	 );
	SetTrieValue( g_ItemData[136],	"ItemDefinitionIndex",		136	 );
	SetTrieValue( g_ItemData[137],	"ItemDefinitionIndex",		137	 );
	SetTrieValue( g_ItemData[138],	"ItemDefinitionIndex",		138	 );
	SetTrieValue( g_ItemData[139],	"ItemDefinitionIndex",		139	 );
	
	// アイテムスロット
	SetTrieValue( g_ItemData[0],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[1],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[2],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[3],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[4],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[5],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[6],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[7],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[8],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[9],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[10],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[11],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[12],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[13],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[14],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[15],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[16],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[17],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[18],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[19],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[20],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[21],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[22],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[23],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[24],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[25],	"ItemSlot",		_:SLOT_PDA_1		);
	SetTrieValue( g_ItemData[26],	"ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData[27],	"ItemSlot",		_:SLOT_PDA_1		);
	SetTrieValue( g_ItemData[28],	"ItemSlot",		_:SLOT_BUILDING		);
	SetTrieValue( g_ItemData[29],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[30],	"ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData[31],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[32],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[33],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[34],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[35],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[36],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[37],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[38],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[39],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[40],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[41],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[42],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[43],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[44],	"ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData[45],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[46],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[47],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[48],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[49],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[50],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[51],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[52],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[53],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[54],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[55],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[56],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[57],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[58],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[59],	"ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData[60],	"ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData[61],	"ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData[94],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[95],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[96],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[97],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[98],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[99],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[100],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[101],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[102],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[103],	"ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData[104],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[105],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[106],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[107],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[108],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[109],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[110],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[111],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[115],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[116],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[117],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[118],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[120],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[121],	"ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData[122],	"ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData[123],	"ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData[124],	"ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData[125],	"ItemSlot",		_:SLOT_HEAD			);	
	SetTrieValue( g_ItemData[126],	"ItemSlot",		_:SLOT_HEAD			);	
	SetTrieValue( g_ItemData[127],	"ItemSlot",		_:SLOT_PRIMARY		);	
	SetTrieValue( g_ItemData[128],	"ItemSlot",		_:SLOT_MELEE		);	
	SetTrieValue( g_ItemData[129],	"ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData[130],	"ItemSlot",		_:SLOT_PRIMARY		);	
	SetTrieValue( g_ItemData[131],	"ItemSlot",		_:SLOT_PRIMARY		);	
	SetTrieValue( g_ItemData[132],	"ItemSlot",		_:SLOT_MELEE		);	
	SetTrieValue( g_ItemData[133],	"ItemSlot",		_:SLOT_SECONDARY	);	
	SetTrieValue( g_ItemData[134],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[135],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[136],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[137],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[138],	"ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData[139],	"ItemSlot",		_:SLOT_HEAD			);
	
	// アイテムタイプ
	SetTrieValue( g_ItemData[0],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[1],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[2],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[3],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[4],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[5],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[6],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[7],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[8],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[9],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[10],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[11],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[12],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[13],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[14],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[15],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[16],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[17],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[18],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[19],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[20],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[21],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[22],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[23],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[24],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[25],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[26],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[27],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[28],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[29],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[30],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[31],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[32],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[33],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[34],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[35],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[36],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[37],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[38],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[39],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[40],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[41],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[42],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[43],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[44],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[45],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[46],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[47],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[48],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[49],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[50],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[51],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[52],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[53],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[54],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[55],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[56],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[57],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[58],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[59],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[60],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[61],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[94],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[95],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[96],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[97],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[98],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[99],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[100],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[101],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[102],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[103],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[104],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[105],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[106],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[107],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[108],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[109],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[110],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[111],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[115],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[116],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[117],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[118],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[120],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[121],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[122],	"ItemType",		_:TYPE_UNKOWN	);
	SetTrieValue( g_ItemData[123],	"ItemType",		_:TYPE_UNKOWN	);
	SetTrieValue( g_ItemData[124],	"ItemType",		_:TYPE_UNKOWN	);
	SetTrieValue( g_ItemData[125],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[126],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[127],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[128],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[129],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[130],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[131],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[132],	"ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData[133],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[134],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[135],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[136],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[137],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[138],	"ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData[139],	"ItemType",		_:TYPE_WEAR		);
	
	// アイテム名
	SetTrieString( g_ItemData[0],	"ItemName",		"#TF_Weapon_Bat"								);
	SetTrieString( g_ItemData[1],	"ItemName",		"#TF_Weapon_Bottle"								);
	SetTrieString( g_ItemData[2],	"ItemName",		"#TF_Weapon_FireAxe"							);
	SetTrieString( g_ItemData[3],	"ItemName",		"#TF_Weapon_Club"								);
	SetTrieString( g_ItemData[4],	"ItemName",		"#TF_Weapon_Knife"								);
	SetTrieString( g_ItemData[5],	"ItemName",		"#TF_Weapon_Fists"								);
	SetTrieString( g_ItemData[6],	"ItemName",		"#TF_Weapon_Shovel"								);
	SetTrieString( g_ItemData[7],	"ItemName",		"#TF_Weapon_Wrench"								);
	SetTrieString( g_ItemData[8],	"ItemName",		"#TF_Weapon_Bonesaw"							);
	SetTrieString( g_ItemData[9],	"ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData[10],	"ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData[11],	"ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData[12],	"ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData[13],	"ItemName",		"#TF_Weapon_Scattergun"							);
	SetTrieString( g_ItemData[14],	"ItemName",		"#TF_Weapon_SniperRifle"						);
	SetTrieString( g_ItemData[15],	"ItemName",		"#TF_Weapon_Minigun"							);
	SetTrieString( g_ItemData[16],	"ItemName",		"#TF_Weapon_SMG"								);
	SetTrieString( g_ItemData[17],	"ItemName",		"#TF_Weapon_SyringeGun"							);
	SetTrieString( g_ItemData[18],	"ItemName",		"#TF_Weapon_RocketLauncher"						);
	SetTrieString( g_ItemData[19],	"ItemName",		"#TF_Weapon_GrenadeLauncher"					);
	SetTrieString( g_ItemData[20],	"ItemName",		"#TF_Weapon_PipebombLauncher"					);
	SetTrieString( g_ItemData[21],	"ItemName",		"#TF_Weapon_FlameThrower"						);
	SetTrieString( g_ItemData[22],	"ItemName",		"#TF_Weapon_Pistol"								);
	SetTrieString( g_ItemData[23],	"ItemName",		"#TF_Weapon_Pistol"								);
	SetTrieString( g_ItemData[24],	"ItemName",		"#TF_Weapon_Revolver"							);
	SetTrieString( g_ItemData[25],	"ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData[26],	"ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData[27],	"ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData[28],	"ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData[29],	"ItemName",		"#TF_Weapon_Medigun"							);
	SetTrieString( g_ItemData[30],	"ItemName",		"#TF_Weapon_Watch"								);
	SetTrieString( g_ItemData[31],	"ItemName",		"#TF_Weapon_Flaregun"							);
	SetTrieString( g_ItemData[32],	"ItemName",		"#TF_Weapon_Bonesaw"							);
	SetTrieString( g_ItemData[33],	"ItemName",		"#TF_Weapon_SyringeGun"							);
	SetTrieString( g_ItemData[34],	"ItemName",		"#TF_Weapon_Medigun"							);
	SetTrieString( g_ItemData[35],	"ItemName",		"#TF_Unique_Achievement_Medigun1"				);
	SetTrieString( g_ItemData[36],	"ItemName",		"#TF_Unique_Achievement_Syringegun1"			);
	SetTrieString( g_ItemData[37],	"ItemName",		"#TF_Unique_Achievement_Bonesaw1"				);
	SetTrieString( g_ItemData[38],	"ItemName",		"#TF_Unique_Achievement_FireAxe1"				);
	SetTrieString( g_ItemData[39],	"ItemName",		"#TF_Unique_Achievement_Flaregun"				);
	SetTrieString( g_ItemData[40],	"ItemName",		"#TF_Unique_Achievement_Flamethrower"			);
	SetTrieString( g_ItemData[41],	"ItemName",		"#TF_Unique_Achievement_Minigun"				);
	SetTrieString( g_ItemData[42],	"ItemName",		"#TF_Unique_Achievement_LunchBox"				);
	SetTrieString( g_ItemData[43],	"ItemName",		"#TF_Unique_Achievement_Fists"					);
	SetTrieString( g_ItemData[44],	"ItemName",		"#TF_Unique_Achievement_Bat"					);
	SetTrieString( g_ItemData[45],	"ItemName",		"#TF_Unique_Achievement_Scattergun_Double"		);
	SetTrieString( g_ItemData[46],	"ItemName",		"#TF_Unique_Achievement_EnergyDrink"			);
	SetTrieString( g_ItemData[47],	"ItemName",		"#TF_Demo_Hat_1"								);
	SetTrieString( g_ItemData[48],	"ItemName",		"#TF_Engineer_Hat_1"							);
	SetTrieString( g_ItemData[49],	"ItemName",		"#TF_Heavy_Hat_1"								);
	SetTrieString( g_ItemData[50],	"ItemName",		"#TF_Medic_Hat_1"								);
	SetTrieString( g_ItemData[51],	"ItemName",		"#TF_Pyro_Hat_1"								);
	SetTrieString( g_ItemData[52],	"ItemName",		"#TF_Scout_Hat_1"								);
	SetTrieString( g_ItemData[53],	"ItemName",		"#TF_Sniper_Hat_1"								);
	SetTrieString( g_ItemData[54],	"ItemName",		"#TF_Soldier_Hat_1"								);
	SetTrieString( g_ItemData[55],	"ItemName",		"#TF_Spy_Hat_1"									);
	SetTrieString( g_ItemData[56],	"ItemName",		"#TF_Unique_Achievement_CompoundBow"			);
	SetTrieString( g_ItemData[57],	"ItemName",		"#TF_Unique_Backstab_Shield"					);
	SetTrieString( g_ItemData[58],	"ItemName",		"#TF_Unique_Achievement_Jar"					);
	SetTrieString( g_ItemData[59],	"ItemName",		"#TF_Unique_Achievement_FeignWatch"				);
	SetTrieString( g_ItemData[60],	"ItemName",		"#TF_Unique_Achievement_CloakWatch"				);
	SetTrieString( g_ItemData[61],	"ItemName",		"#TF_Unique_Achievement_Revolver"				);
	SetTrieString( g_ItemData[94],	"ItemName",		"#TF_Engineer_Cowboy_Hat"						);
	SetTrieString( g_ItemData[95],	"ItemName",		"#TF_Engineer_Train_Hat"						);
	SetTrieString( g_ItemData[96],	"ItemName",		"#TF_Heavy_Ushanka_Hat"							);
	SetTrieString( g_ItemData[97],	"ItemName",		"#TF_Heavy_Stocking_cap"						);
	SetTrieString( g_ItemData[98],	"ItemName",		"#TF_Soldier_Pot_Hat"							);
	SetTrieString( g_ItemData[99],	"ItemName",		"#TF_Soldier_Viking_Hat"						);
	SetTrieString( g_ItemData[100],	"ItemName",		"#TF_Demo_Scott_Hat"							);
	SetTrieString( g_ItemData[101],	"ItemName",		"#TF_Medic_Tyrolean_Hat"						);
	SetTrieString( g_ItemData[102],	"ItemName",		"#TF_Pyro_Chicken_Hat"							);
	SetTrieString( g_ItemData[103],	"ItemName",		"#TF_Spy_Camera_Beard"							);
	SetTrieString( g_ItemData[104],	"ItemName",		"#TF_Medic_Mirror_Hat"							);
	SetTrieString( g_ItemData[105],	"ItemName",		"#TF_Pyro_Fireman_Helmet"						);
	SetTrieString( g_ItemData[106],	"ItemName",		"#TF_Scout_Bonk_Helmet"							);
	SetTrieString( g_ItemData[107],	"ItemName",		"#TF_Scout_Newsboy_Cap"							);
	SetTrieString( g_ItemData[108],	"ItemName",		"#TF_Spy_Derby_Hat"								);
	SetTrieString( g_ItemData[109],	"ItemName",		"#TF_Sniper_Straw_Hat"							);
	SetTrieString( g_ItemData[110],	"ItemName",		"#TF_Sniper_Jarate_Headband"					);
	SetTrieString( g_ItemData[111],	"ItemName",		"#TF_Hatless_Scout"								);
	SetTrieString( g_ItemData[115],	"ItemName",		"#TF_Halloween_Hat"								);
	SetTrieString( g_ItemData[116],	"ItemName",		"#TF_Wearable_Hat"								);
	SetTrieString( g_ItemData[117],	"ItemName",		"#TF_Hatless_Sniper"							);
	SetTrieString( g_ItemData[118],	"ItemName",		"#TF_Hatless_Engineer"							);
	SetTrieString( g_ItemData[120],	"ItemName",		"#TF_Demo_Top_Hat"								);
	SetTrieString( g_ItemData[121],	"ItemName",		"#TF_Soldier_Medal_Web_Sleuth"					);
	SetTrieString( g_ItemData[122],	"ItemName",		"#TF_CheatDetectedMinor"						);
	SetTrieString( g_ItemData[123],	"ItemName",		"#TF_CheatDetectedMajor"						);
	SetTrieString( g_ItemData[124],	"ItemName",		"#TF_HonestyReward"								);
	SetTrieString( g_ItemData[125],	"ItemName",		"#TF_Wearable_HonestyHalo"						);
	SetTrieString( g_ItemData[126],	"ItemName",		"#TF_Wearable_L4DHat"							);
	SetTrieString( g_ItemData[127],	"ItemName",		"#TF_Unique_Achievement_RocketLauncher"			);
	SetTrieString( g_ItemData[128],	"ItemName",		"#TF_Unique_Achievement_Pickaxe"				);
	SetTrieString( g_ItemData[129],	"ItemName",		"#TF_Unique_Achievement_SoldierBuff"			);
	SetTrieString( g_ItemData[130],	"ItemName",		"#TF_Unique_Achievement_StickyLauncher"			);
	SetTrieString( g_ItemData[131],	"ItemName",		"#TF_Unique_Achievement_Shield"					);
	SetTrieString( g_ItemData[132],	"ItemName",		"#TF_Unique_Achievement_Sword"					);
	SetTrieString( g_ItemData[133],	"ItemName",		"#TF_Unique_Blast_Boots"						);
	SetTrieString( g_ItemData[134],	"ItemName",		"#TF_PropagandaContest_FirstPlace"				);
	SetTrieString( g_ItemData[135],	"ItemName",		"#TF_ToweringPillar_Hat"						);
	SetTrieString( g_ItemData[136],	"ItemName",		"#TF_PropagandaContest_SecondPlace"				);
	SetTrieString( g_ItemData[137],	"ItemName",		"#TF_NobleAmassment_Hat"						);
	SetTrieString( g_ItemData[138],	"ItemName",		"#TF_PropagandaContest_ThirdPlace"				);
	SetTrieString( g_ItemData[139],	"ItemName",		"#TF_ModestPile_Hat"							);
	
	// アイテム管理名
	SetTrieString( g_ItemData[0],	"ItemEdictName",		"tf_weapon_bat"						);
	SetTrieString( g_ItemData[1],	"ItemEdictName",		"tf_weapon_bottle"					);
	SetTrieString( g_ItemData[2],	"ItemEdictName",		"tf_weapon_fireaxe"					);
	SetTrieString( g_ItemData[3],	"ItemEdictName",		"tf_weapon_club"					);
	SetTrieString( g_ItemData[4],	"ItemEdictName",		"tf_weapon_knife"					);
	SetTrieString( g_ItemData[5],	"ItemEdictName",		"tf_weapon_fists"					);
	SetTrieString( g_ItemData[6],	"ItemEdictName",		"tf_weapon_shovel"					);
	SetTrieString( g_ItemData[7],	"ItemEdictName",		"tf_weapon_wrench"					);
	SetTrieString( g_ItemData[8],	"ItemEdictName",		"tf_weapon_bonesaw"					);
	SetTrieString( g_ItemData[9],	"ItemEdictName",		"tf_weapon_shotgun_primary"			);
	SetTrieString( g_ItemData[10],	"ItemEdictName",		"tf_weapon_shotgun_soldier"			);
	SetTrieString( g_ItemData[11],	"ItemEdictName",		"tf_weapon_shotgun_hwg"				);
	SetTrieString( g_ItemData[12],	"ItemEdictName",		"tf_weapon_shotgun_pyro"			);
	SetTrieString( g_ItemData[13],	"ItemEdictName",		"tf_weapon_scattergun"				);
	SetTrieString( g_ItemData[14],	"ItemEdictName",		"tf_weapon_sniperrifle"				);
	SetTrieString( g_ItemData[15],	"ItemEdictName",		"tf_weapon_minigun"					);
	SetTrieString( g_ItemData[16],	"ItemEdictName",		"tf_weapon_smg"						);
	SetTrieString( g_ItemData[17],	"ItemEdictName",		"tf_weapon_syringegun_medic"		);
	SetTrieString( g_ItemData[18],	"ItemEdictName",		"tf_weapon_rocketlauncher"			);
	SetTrieString( g_ItemData[19],	"ItemEdictName",		"tf_weapon_grenadelauncher"			);
	SetTrieString( g_ItemData[20],	"ItemEdictName",		"tf_weapon_pipebomblauncher"		);
	SetTrieString( g_ItemData[21],	"ItemEdictName",		"tf_weapon_flamethrower"			);
	SetTrieString( g_ItemData[22],	"ItemEdictName",		"tf_weapon_pistol"					);
	SetTrieString( g_ItemData[23],	"ItemEdictName",		"tf_weapon_pistol_scout"			);
	SetTrieString( g_ItemData[24],	"ItemEdictName",		"tf_weapon_revolver"				);
	SetTrieString( g_ItemData[25],	"ItemEdictName",		"tf_weapon_pda_engineer_build"		);
	SetTrieString( g_ItemData[26],	"ItemEdictName",		"tf_weapon_pda_engineer_destroy"	);
	SetTrieString( g_ItemData[27],	"ItemEdictName",		"tf_weapon_pda_spy"					);
	SetTrieString( g_ItemData[28],	"ItemEdictName",		"tf_weapon_builder"					);
	SetTrieString( g_ItemData[29],	"ItemEdictName",		"tf_weapon_medigun"					);
	SetTrieString( g_ItemData[30],	"ItemEdictName",		"tf_weapon_invis"					);
	SetTrieString( g_ItemData[31],	"ItemEdictName",		"tf_weapon_flaregun"				);
	SetTrieString( g_ItemData[32],	"ItemEdictName",		"tf_weapon_bonesaw"					);
	SetTrieString( g_ItemData[33],	"ItemEdictName",		"tf_weapon_syringegun_medic"		);
	SetTrieString( g_ItemData[34],	"ItemEdictName",		"tf_weapon_medigun"					);
	SetTrieString( g_ItemData[35],	"ItemEdictName",		"tf_weapon_medigun"					);
	SetTrieString( g_ItemData[36],	"ItemEdictName",		"tf_weapon_syringegun_medic"		);
	SetTrieString( g_ItemData[37],	"ItemEdictName",		"tf_weapon_bonesaw"					);
	SetTrieString( g_ItemData[38],	"ItemEdictName",		"tf_weapon_fireaxe"					);
	SetTrieString( g_ItemData[39],	"ItemEdictName",		"tf_weapon_flaregun"				);
	SetTrieString( g_ItemData[40],	"ItemEdictName",		"tf_weapon_flamethrower"			);
	SetTrieString( g_ItemData[41],	"ItemEdictName",		"tf_weapon_minigun"					);
	SetTrieString( g_ItemData[42],	"ItemEdictName",		"tf_weapon_lunchbox"				);
	SetTrieString( g_ItemData[43],	"ItemEdictName",		"tf_weapon_fists"					);
	SetTrieString( g_ItemData[44],	"ItemEdictName",		"tf_weapon_bat_wood"				);
	SetTrieString( g_ItemData[45],	"ItemEdictName",		"tf_weapon_scattergun"				);
	SetTrieString( g_ItemData[46],	"ItemEdictName",		"tf_weapon_lunchbox_drink"			);
	SetTrieString( g_ItemData[47],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[48],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[49],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[50],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[51],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[52],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[53],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[54],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[55],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[56],	"ItemEdictName",		"tf_weapon_compound_bow"			);
	SetTrieString( g_ItemData[57],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[58],	"ItemEdictName",		"tf_weapon_jar"						);
	SetTrieString( g_ItemData[59],	"ItemEdictName",		"tf_weapon_invis"					);
	SetTrieString( g_ItemData[60],	"ItemEdictName",		"tf_weapon_invis"					);
	SetTrieString( g_ItemData[61],	"ItemEdictName",		"tf_weapon_revolver"				);
	SetTrieString( g_ItemData[94],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[95],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[96],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[97],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[98],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[99],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[100],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[101],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[102],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[103],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[104],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[105],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[106],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[107],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[108],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[109],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[110],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[111],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[115],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[116],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[117],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[118],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[120],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[121],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[122],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[123],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[124],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[125],	"ItemEdictName",		"tf_wearable_item"					);	
	SetTrieString( g_ItemData[126],	"ItemEdictName",		"tf_wearable_item"					);	
	SetTrieString( g_ItemData[127],	"ItemEdictName",		"tf_weapon_rocketlauncher_directhit");
	SetTrieString( g_ItemData[128],	"ItemEdictName",		"tf_weapon_shovel"					);
	SetTrieString( g_ItemData[129],	"ItemEdictName",		"tf_weapon_buff_item"				);
	SetTrieString( g_ItemData[130],	"ItemEdictName",		"tf_weapon_pipebomblauncher"		);
	SetTrieString( g_ItemData[131],	"ItemEdictName",		"tf_wearable_item_demoshield"		);
	SetTrieString( g_ItemData[132],	"ItemEdictName",		"tf_weapon_sword"					);
	SetTrieString( g_ItemData[133],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[134],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[135],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[136],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[137],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[138],	"ItemEdictName",		"tf_wearable_item"					);
	SetTrieString( g_ItemData[139],	"ItemEdictName",		"tf_wearable_item"					);
	
	// アイテムモデル
	SetTrieValue( g_ItemData[0],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bat.mdl", true )	);
	SetTrieValue( g_ItemData[1],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bottle.mdl", true )	);
	SetTrieValue( g_ItemData[2],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_fireaxe.mdl", true )	);
	SetTrieValue( g_ItemData[3],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_machete.mdl", true )	);
	SetTrieValue( g_ItemData[4],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_knife.mdl", true )	);
	SetTrieValue( g_ItemData[5],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[6],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shovel.mdl", true )	);
	SetTrieValue( g_ItemData[7],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_wrench.mdl", true )	);
	SetTrieValue( g_ItemData[8],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bonesaw.mdl", true )	);
	SetTrieValue( g_ItemData[9],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData[10],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData[11],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData[12],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData[13],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_scattergun.mdl", true )	);
	SetTrieValue( g_ItemData[14],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_sniperrifle.mdl", true )	);
	SetTrieValue( g_ItemData[15],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_minigun.mdl", true )	);
	SetTrieValue( g_ItemData[16],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_smg.mdl", true )	);
	SetTrieValue( g_ItemData[17],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_syringegun.mdl", true )	);
	SetTrieValue( g_ItemData[18],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_rocketlauncher.mdl", true )	);
	SetTrieValue( g_ItemData[19],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_grenadelauncher.mdl", true )	);
	SetTrieValue( g_ItemData[20],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_stickybomb_launcher.mdl", true )	);
	SetTrieValue( g_ItemData[21],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_flamethrower.mdl", true )	);
	SetTrieValue( g_ItemData[22],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_pistol.mdl", true )	);
	SetTrieValue( g_ItemData[23],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_pistol.mdl", true )	);
	SetTrieValue( g_ItemData[24],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_revolver.mdl", true )	);
	SetTrieValue( g_ItemData[25],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_builder.mdl", true )	);
	SetTrieValue( g_ItemData[26],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_builder.mdl", true )	);
	SetTrieValue( g_ItemData[27],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_cigarette_case.mdl", true )	);
	SetTrieValue( g_ItemData[28],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_builder.mdl", true )	);
	SetTrieValue( g_ItemData[29],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_medigun.mdl", true )	);
	SetTrieValue( g_ItemData[30],	"ItemModelIndex",		PrecacheModel( "models/weapons/v_models/v_watch_spy.mdl", true )	);
	SetTrieValue( g_ItemData[31],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_pistol.mdl", true )	);
	SetTrieValue( g_ItemData[32],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bonesaw.mdl", true )	);
	SetTrieValue( g_ItemData[33],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_syringegun.mdl", true )	);
	SetTrieValue( g_ItemData[34],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_medigun.mdl", true )	);
	SetTrieValue( g_ItemData[35],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_medigun/c_medigun.mdl", true )	);
	SetTrieValue( g_ItemData[36],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_leechgun/c_leechgun.mdl", true )	);
	SetTrieValue( g_ItemData[37],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_ubersaw/c_ubersaw.mdl", true )	);
	SetTrieValue( g_ItemData[38],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_axtinguisher/c_axtinguisher_pyro.mdl", true )	);
	SetTrieValue( g_ItemData[39],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_flaregun_pyro/c_flaregun_pyro.mdl", true )	);
	SetTrieValue( g_ItemData[40],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_flamethrower/c_flamethrower.mdl", true )	);
	SetTrieValue( g_ItemData[41],	"ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_minigun.mdl", true )	);
	SetTrieValue( g_ItemData[42],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_sandwich/c_sandwich.mdl", true )	);
	SetTrieValue( g_ItemData[43],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl", true )	);
	SetTrieValue( g_ItemData[44],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_wooden_bat/c_wooden_bat.mdl", true )	);
	SetTrieValue( g_ItemData[45],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_double_barrel.mdl", true )	);
	SetTrieValue( g_ItemData[46],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_energy_drink/c_energy_drink.mdl", true )	);
	SetTrieValue( g_ItemData[47],	"ItemModelIndex",		PrecacheModel( "models/player/items/demo/demo_afro.mdl", true )	);
	SetTrieValue( g_ItemData[48],	"ItemModelIndex",		PrecacheModel( "models/player/items/engineer/mining_hat.mdl", true )	);
	SetTrieValue( g_ItemData[49],	"ItemModelIndex",		PrecacheModel( "models/player/items/heavy/football_helmet.mdl", true )	);
	SetTrieValue( g_ItemData[50],	"ItemModelIndex",		PrecacheModel( "models/player/items/medic/medic_helmet.mdl", true )	);
	SetTrieValue( g_ItemData[51],	"ItemModelIndex",		PrecacheModel( "models/player/items/pyro/pyro_hat.mdl", true )	);
	SetTrieValue( g_ItemData[52],	"ItemModelIndex",		PrecacheModel( "models/player/items/scout/batter_helmet.mdl", true )	);
	SetTrieValue( g_ItemData[53],	"ItemModelIndex",		PrecacheModel( "models/player/items/sniper/tooth_hat.mdl", true )	);
	SetTrieValue( g_ItemData[54],	"ItemModelIndex",		PrecacheModel( "models/player/items/soldier/soldier_hat.mdl", true )	);
	SetTrieValue( g_ItemData[55],	"ItemModelIndex",		PrecacheModel( "models/player/items/spy/spy_hat.mdl", true )	);
	SetTrieValue( g_ItemData[56],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_bow/c_bow.mdl", true )	);
	SetTrieValue( g_ItemData[57],	"ItemModelIndex",		PrecacheModel( "models/player/items/sniper/knife_shield.mdl", true )	);
	SetTrieValue( g_ItemData[58],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/urinejar.mdl", true )	);
	SetTrieValue( g_ItemData[59],	"ItemModelIndex",		PrecacheModel( "models/weapons/v_models/v_watch_pocket_spy.mdl", true )	);
	SetTrieValue( g_ItemData[60],	"ItemModelIndex",		PrecacheModel( "models/weapons/v_models/v_watch_leather_spy.mdl", true )	);
	SetTrieValue( g_ItemData[61],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_ambassador/c_ambassador.mdl", true )	);
	SetTrieValue( g_ItemData[94],	"ItemModelIndex",		PrecacheModel( "models/player/items/engineer/engineer_cowboy_hat.mdl", true )	);
	SetTrieValue( g_ItemData[95],	"ItemModelIndex",		PrecacheModel( "models/player/items/engineer/engineer_train_hat.mdl", true )	);
	SetTrieValue( g_ItemData[96],	"ItemModelIndex",		PrecacheModel( "models/player/items/heavy/heavy_ushanka.mdl", true )	);
	SetTrieValue( g_ItemData[97],	"ItemModelIndex",		PrecacheModel( "models/player/items/heavy/heavy_stocking_cap.mdl", true )	);
	SetTrieValue( g_ItemData[98],	"ItemModelIndex",		PrecacheModel( "models/player/items/soldier/soldier_pot.mdl", true )	);
	SetTrieValue( g_ItemData[99],	"ItemModelIndex",		PrecacheModel( "models/player/items/soldier/soldier_viking.mdl", true )	);
	SetTrieValue( g_ItemData[100],	"ItemModelIndex",		PrecacheModel( "models/player/items/demo/demo_scott.mdl", true )	);
	SetTrieValue( g_ItemData[101],	"ItemModelIndex",		PrecacheModel( "models/player/items/medic/medic_tyrolean.mdl", true )	);
	SetTrieValue( g_ItemData[102],	"ItemModelIndex",		PrecacheModel( "models/player/items/pyro/pyro_chicken.mdl", true )	);
	SetTrieValue( g_ItemData[103],	"ItemModelIndex",		PrecacheModel( "models/player/items/spy/spy_camera_beard.mdl", true )	);
	SetTrieValue( g_ItemData[104],	"ItemModelIndex",		PrecacheModel( "models/player/items/medic/medic_mirror.mdl", true )	);
	SetTrieValue( g_ItemData[105],	"ItemModelIndex",		PrecacheModel( "models/player/items/pyro/fireman_helmet.mdl", true )	);
	SetTrieValue( g_ItemData[106],	"ItemModelIndex",		PrecacheModel( "models/player/items/scout/bonk_helmet.mdl", true )	);
	SetTrieValue( g_ItemData[107],	"ItemModelIndex",		PrecacheModel( "models/player/items/scout/newsboy_cap.mdl", true )	);
	SetTrieValue( g_ItemData[108],	"ItemModelIndex",		PrecacheModel( "models/player/items/spy/derby_hat.mdl", true )	);
	SetTrieValue( g_ItemData[109],	"ItemModelIndex",		PrecacheModel( "models/player/items/sniper/straw_hat.mdl", true )	);
	SetTrieValue( g_ItemData[110],	"ItemModelIndex",		PrecacheModel( "models/player/items/sniper/jarate_headband.mdl", true )	);
	SetTrieValue( g_ItemData[111],	"ItemModelIndex",		-1 )
	SetTrieValue( g_ItemData[115],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[116],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[117],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[118],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[120],	"ItemModelIndex",		PrecacheModel( "models/player/items/demo/top_hat.mdl", true )	);
	SetTrieValue( g_ItemData[121],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[122],	"ItemModelIndex",		-1 )
	SetTrieValue( g_ItemData[123],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[124],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[125],	"ItemModelIndex",		PrecacheModel( "models/player/items/all_class/all_halo.mdl", true )	);
	SetTrieValue( g_ItemData[126],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[127],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_directhit/c_directhit.mdl", true )	);
	SetTrieValue( g_ItemData[128],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_pickaxe/c_pickaxe.mdl", true )	);
	SetTrieValue( g_ItemData[129],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_bugle/c_bugle.mdl", true )	);
	SetTrieValue( g_ItemData[130],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_stickybomb_launcher.mdl", true )	);
	SetTrieValue( g_ItemData[131],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_targe/c_targe.mdl", true )	);
	SetTrieValue( g_ItemData[132],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_claymore/c_claymore.mdl", true )	);
	SetTrieValue( g_ItemData[133],	"ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_rocketboots_soldier.mdl", true )	);
	SetTrieValue( g_ItemData[134],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[135],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[136],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[137],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[138],	"ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData[139],	"ItemModelIndex",		-1 );
	
	// アイテム最小レベル
	SetTrieValue( g_ItemData[0],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[1],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[2],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[3],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[4],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[5],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[6],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[7],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[8],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[9],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[10],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[11],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[12],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[13],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[14],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[15],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[16],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[17],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[18],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[19],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[20],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[21],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[22],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[23],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[24],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[25],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[26],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[27],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[28],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[29],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[30],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[31],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[32],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[33],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[34],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[35],	"ItemMinLevel",		8	 );
	SetTrieValue( g_ItemData[36],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[37],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[38],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[39],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[40],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[41],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[42],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[43],	"ItemMinLevel",		7	 );
	SetTrieValue( g_ItemData[44],	"ItemMinLevel",		15	 );
	SetTrieValue( g_ItemData[45],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[46],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[47],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[48],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[49],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[50],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[51],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[52],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[53],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[54],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[55],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[56],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[57],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[58],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[59],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[60],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[61],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[94],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[95],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[96],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[97],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[98],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[99],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[100],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[101],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[102],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[103],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[104],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[105],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[106],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[107],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[108],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[109],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[110],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[111],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[115],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[116],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[117],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[118],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[120],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[121],	"ItemMinLevel",		100	 );
	SetTrieValue( g_ItemData[122],	"ItemMinLevel",		100	 );
	SetTrieValue( g_ItemData[123],	"ItemMinLevel",		100	 );
	SetTrieValue( g_ItemData[124],	"ItemMinLevel",		100	 );
	SetTrieValue( g_ItemData[125],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[126],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[127],	"ItemMinLevel",		1	 );
	SetTrieValue( g_ItemData[128],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[129],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[130],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[131],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[132],	"ItemMinLevel",		5	 );
	SetTrieValue( g_ItemData[133],	"ItemMinLevel",		10	 );
	SetTrieValue( g_ItemData[134],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[135],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[136],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[137],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[138],	"ItemMinLevel",		0	 );
	SetTrieValue( g_ItemData[139],	"ItemMinLevel",		0	 );

	// アイテム最大レベル
	SetTrieValue( g_ItemData[0],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[1],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[2],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[3],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[4],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[5],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[6],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[7],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[8],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[9],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[10],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[11],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[12],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[13],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[14],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[15],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[16],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[17],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[18],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[19],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[20],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[21],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[22],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[23],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[24],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[25],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[26],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[27],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[28],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[29],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[30],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[31],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[32],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[33],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[34],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[35],	"ItemMaxLevel",		8	 );
	SetTrieValue( g_ItemData[36],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[37],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[38],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[39],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[40],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[41],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[42],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[43],	"ItemMaxLevel",		7	 );
	SetTrieValue( g_ItemData[44],	"ItemMaxLevel",		15	 );
	SetTrieValue( g_ItemData[45],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[46],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[47],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[48],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[49],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[50],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[51],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[52],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[53],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[54],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[55],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[56],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[57],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[58],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[59],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[60],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[61],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[94],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[95],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[96],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[97],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[98],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[99],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[100],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[101],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[102],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[103],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[104],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[105],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[106],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[107],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[108],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[109],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[110],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[111],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[115],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[116],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[117],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[118],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[120],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[121],	"ItemMaxLevel",		100	 );
	SetTrieValue( g_ItemData[122],	"ItemMaxLevel",		100	 );
	SetTrieValue( g_ItemData[123],	"ItemMaxLevel",		100	 );
	SetTrieValue( g_ItemData[124],	"ItemMaxLevel",		100	 );
	SetTrieValue( g_ItemData[125],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[126],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[127],	"ItemMaxLevel",		1	 );
	SetTrieValue( g_ItemData[128],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[129],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[130],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[131],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[132],	"ItemMaxLevel",		5	 );
	SetTrieValue( g_ItemData[133],	"ItemMaxLevel",		10	 );
	SetTrieValue( g_ItemData[134],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[135],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[136],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[137],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[138],	"ItemMaxLevel",		0	 );
	SetTrieValue( g_ItemData[139],	"ItemMaxLevel",		0	 );


	// アイテムクオリティ
	SetTrieValue( g_ItemData[0],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[1],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[2],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[3],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[4],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[5],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[6],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[7],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[8],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[9],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[10],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[11],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[12],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[13],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[14],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[15],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[16],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[17],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[18],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[19],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[20],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[21],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[22],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[23],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[24],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[25],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[26],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[27],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[28],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[29],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[30],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[31],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[32],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[33],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[34],	"ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData[35],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[36],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[37],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[38],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[39],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[40],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[41],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[42],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[43],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[44],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[45],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[46],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[47],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[48],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[49],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[50],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[51],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[52],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[53],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[54],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[55],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[56],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[57],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[58],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[59],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[60],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[61],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[94],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[95],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[96],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[97],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[98],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[99],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[100],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[101],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[102],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[103],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[104],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[105],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[106],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[107],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[108],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[109],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[110],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[111],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[115],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[116],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[117],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[118],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[120],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[121],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[122],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[123],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[124],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[125],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[126],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[127],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[128],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[129],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[130],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[131],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[132],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[133],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[135],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[136],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[137],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[138],	"ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData[139],	"ItemQuality",		QUALITY_UNIQUE );
	
	//// モデル読み込み
	//for( new i = 0; i < TF2_ITEM_NUM; i++)
	//{
	//	// アイテムデータが設定されている
	//	if( GetTrieSize(g_ItemData[i]) > 0 )
	//	{
	//		// モデル名を取得
	//		new String:modelName[64];
	//		GetTrieString( g_ItemData[i], "ItemModelIndex", modelName, sizeof(modelName));
	//		if( !StrEqual( modelName, "" ) )
	//		{
	//			PrecacheModel( modelName, true );
	//		}
	//	}
	//}
		
}


/////////////////////////////////////////////////////////////////////
//
// ゲームコンフィグ後処理
//
/////////////////////////////////////////////////////////////////////
stock FinalItemData()
{
	// ハンドルクローズ
	for( new i = 0; i < TF2_ITEM_NUM; i++)
	{
		if( g_ItemData[i] != INVALID_HANDLE )
		{
			CloseHandle( g_ItemData[i] );
		}
	}
}


/////////////////////////////////////////////////////////////////////
//
// アイテム配布
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_GiveItem( any:client, TFItems:itemIndex )
{
	// クライアント
	if( client > 0 )
	{
		// ゲームに入ってる
		if( IsClientInGame( client ) )
		{
			// アイテムデータが設定されている
			if( GetTrieSize(g_ItemData[itemIndex]) > 0 )
			{
				// アイテムインデックス取得
				new ItemDefinitionIndex;
				GetTrieValue( g_ItemData[itemIndex], "ItemDefinitionIndex", ItemDefinitionIndex );
				// スロット取得
				new ItemSlot;
				GetTrieValue( g_ItemData[itemIndex], "ItemSlot", ItemSlot );
				// 管理名を取得
				new String:edictName[64];
				GetTrieString( g_ItemData[itemIndex], "ItemEdictName", edictName, sizeof(edictName));
				// モデルインデックスを取得
				new ItemModelIndex;
				GetTrieValue( g_ItemData[itemIndex], "ItemModelIndex", ItemModelIndex );
				// アイテムタイプ取得
				new ItemType;
				GetTrieValue( g_ItemData[itemIndex], "ItemType", ItemType );
				// アイテム最小レベル取得
				new ItemMinLevel;
				GetTrieValue( g_ItemData[itemIndex], "ItemMinLevel", ItemMinLevel );
				// アイテム最大レベル取得
				new ItemMaxLevel;
				GetTrieValue( g_ItemData[itemIndex], "ItemMaxLevel", ItemMaxLevel );
				// アイテムクオリティ取得
				new ItemQuality;
				GetTrieValue( g_ItemData[itemIndex], "ItemQuality", ItemQuality );
				
				
				// 入れるスロットを削除
				if( ItemSlot < _:SLOT_BUILDING )
				{
					new weaponIndex = GetPlayerWeaponSlot( client, ItemSlot );
					if( weaponIndex != -1 )
					{
						//RemovePlayerItem( client, weaponIndex );
						//RemoveEdict( weaponIndex );
						TF2_RemoveWeaponSlot( client, ItemSlot );
					}	
					
				}
				// ウェア検索
				new ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_wearable_item")) != -1)
				{
					// clientのウェア
					new iOwner = GetEntPropEnt( ent, Prop_Send, "m_hOwnerEntity")
					if(iOwner == client)
					{
						// スロットが同じなら削除
						if( TF2_GetItemSlot( ent ) == TFItemSlot:ItemSlot )
						{
							// 削除
							SDKCall( g_hRemoveWearable, client, ent );
						}
					}
				}				
				
				// アイテム取得＆装備
				//new giveItem = SDKCall( g_hGiveNamedItem, client, edictName, 0 );
				
				new giveItem = CreateEntityByName(edictName);
				// 生成できた？
				if( IsValidEdict(giveItem) )//giveItem != -1 )
				{
					
					// 武器
					if( ItemType == _:TYPE_WEAPON )
					{
						SetEntProp(giveItem, Prop_Send, "m_bInitialized", 			1 );
						SetEntProp(giveItem, Prop_Send, "m_nSkin",					( GetClientTeam( client ) - 2 ) );
						SetEntProp(giveItem, Prop_Send, "m_iItemDefinitionIndex",	ItemDefinitionIndex );
						SetEntProp(giveItem, Prop_Send, "m_iEntityLevel",			GetRandomInt(ItemMinLevel, ItemMaxLevel) );
						SetEntProp(giveItem, Prop_Send, "m_iEntityQuality",			ItemQuality );
						if( ItemModelIndex != -1 )
						{
							SetEntProp(giveItem, Prop_Send, "m_iWorldModelIndex",			ItemModelIndex );
						}
						DispatchSpawn(giveItem);
						// 出来たら装備
						SDKCall( g_hWeaponEquip, client, giveItem );
						
						return true;
					}
					// ウェア
					else if( ItemType == _:TYPE_WEAR )
					{
						SetEntProp(giveItem, Prop_Send, "m_bInitialized", 			1 );
						SetEntProp(giveItem, Prop_Send, "m_nSkin",					( GetClientTeam( client ) - 2 ) );
						SetEntProp(giveItem, Prop_Send, "m_iItemDefinitionIndex",	ItemDefinitionIndex );
						SetEntProp(giveItem, Prop_Send, "m_iEntityLevel",			GetRandomInt(ItemMinLevel, ItemMaxLevel) );
						SetEntProp(giveItem, Prop_Send, "m_iEntityQuality",			ItemQuality );
						DispatchSpawn(giveItem);
						// 出来たら装備
						SDKCall( g_hEquipWearable, client, giveItem );
						if( ItemModelIndex != -1 )
						{
							SetEntProp(giveItem, Prop_Send, "m_nModelIndex",			ItemModelIndex );
						}
						return true;
						
					}
					
					// アイテム番号設定
					//SetEntProp( giveItem, Prop_Send, "m_iItemDefinitionIndex", itemIndex );
					
				}
			}
		}
	}

	return false;
}





/////////////////////////////////////////////////////////////////////
//
// アイテム設定インデックス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetItemDefIndex( entIndex )
{
	if( entIndex != -1 )
	{
		return GetEntProp( entIndex, Prop_Send, "m_iItemDefinitionIndex" );
	}
	return -1;
}

/////////////////////////////////////////////////////////////////////
//
// アイテムクオリティ取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetItemQuality( entIndex )
{
	if( entIndex != -1 )
	{
		return GetEntProp( entIndex, Prop_Send, "m_iEntityQuality" );
	}
	return -1;
}


/////////////////////////////////////////////////////////////////////
//
// アイテムスロット取得
//
/////////////////////////////////////////////////////////////////////
stock TFItemSlot:TF2_GetItemSlot( entIndex )
{
	new itemIndex = TF2_GetItemDefIndex( entIndex );
	if( itemIndex != -1)
	{
		new TFItemSlot:ItemSlot;
		GetTrieValue( g_ItemData[itemIndex], "ItemSlot",  ItemSlot);
		return ItemSlot;
	}
	return SLOT_UNKOWN;
}

/////////////////////////////////////////////////////////////////////
//
// アイテム名取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetItemName(entIndex, String:name[], maxlength)
{
	new itemIndex = TF2_GetItemDefIndex( entIndex );
	if( itemIndex != -1)
	{
		GetTrieString( g_ItemData[itemIndex], "ItemName", name, maxlength);
	}
	
}


