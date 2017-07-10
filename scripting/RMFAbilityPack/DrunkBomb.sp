/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.8
// �E�ꕔ�d�l��ύX
// �E�L�����O�ɑΉ�
// �E1.3.1�ŃR���p�C��
// �Esm_rmf_drunkbomb_gravity_scale���폜
// 2009/10/06 - 0.0.4
// �E����������ύX
// 2009/08/29 - 0.0.3
// �E�P�̓���ɑΉ��B
// �E1.2.3�ŃR���p�C��
// 2009/08/14 - 0.0.1
// �E�N���X���X�A�b�v�f�[�g�ɑΉ�(1.2.2�ŃR���p�C��)

/////////////////////////////////////////////////////////////////////
//
// �C���N���[�h
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
// �萔
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
// MOD���
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
// �O���[�o���ϐ�
//
/////////////////////////////////////////////////////////////////////
new Handle:g_FuseTime = INVALID_HANDLE;						// ConVar���e�^�C�}�[����
new Handle:g_MoveSpeedMag = INVALID_HANDLE;					// ConVar�ړ����x
new Handle:g_DamageRadius = INVALID_HANDLE;					// ConVar�L���͈�
new Handle:g_BaseDamage = INVALID_HANDLE;					// ConVar�x�[�X�_���[�W

new Handle:g_TauntTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �����`�F�b�N�^�C�}�[
new Handle:g_FuseEnd[MAXPLAYERS+1] = INVALID_HANDLE;		// �_�b�V���I���^�C�}�[
new Handle:g_TauntChain[MAXPLAYERS+1] = INVALID_HANDLE;		// �����R���{�^�C�}�[
new Handle:g_LoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ���[�v����
new Handle:g_LoopVisualTimer[MAXPLAYERS+1] = INVALID_HANDLE;// ���E�G�t�F�N�g����

new bool:g_FirstTaunt[MAXPLAYERS+1] = false;				// �����R���{�����H
new bool:g_HasBomb[MAXPLAYERS+1] = false;					// �����`���H
new g_AngleDir[MAXPLAYERS+1] = 1;							// ���E�̉�]����
new g_FadeColor[MAXPLAYERS+1][3];							// �J���[
new g_Drunker[MAXPLAYERS+1] = -1;							// �U����


new g_BombModel[MAXPLAYERS+1] = -1;			// ���e���f��

/////////////////////////////////////////////////////////////////////
//
// �C�x���g����
//
/////////////////////////////////////////////////////////////////////
stock Action:Event_FiredUser(Handle:event, const String:name[], any:client=0)
{
	
	// �v���O�C���J�n
	if(StrEqual(name, EVENT_PLUGIN_START))
	{
		// ����t�@�C���Ǎ�
		LoadTranslations(PL_TRANSLATION);

		// �R�}���h�쐬
		CreateConVar("sm_rmf_tf_drunkbomb", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_drunkbomb","1","Drunk Bomb Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_FuseTime		= CreateConVar("sm_rmf_drunkbomb_fuse",			"5.5","Fuse time (0.0-120.0)");
		g_MoveSpeedMag	= CreateConVar("sm_rmf_drunkbomb_speed_mag",	"0.8","Movement speed magnification(0.0-10.0)");
		g_DamageRadius	= CreateConVar("sm_rmf_drunkbomb_radius",		"10.0","Damage radius (0.0-100.0)");
		g_BaseDamage	= CreateConVar("sm_rmf_drunkbomb_base_damage",	"800","Base damage (0-1000)");
		HookConVarChange(g_FuseTime,		ConVarChange_Time);
		HookConVarChange(g_MoveSpeedMag,	ConVarChange_Magnification);
		HookConVarChange(g_DamageRadius,	ConVarChange_Radius);
		HookConVarChange(g_BaseDamage,		ConVarChange_Damage);


		// �����R�}���h�Q�b�g
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_drunkbomb_class", "4", "Ability class");
	}
	
	// �v���O�C��������
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ���e�폜
			DeleteBigBomb(i)
		}
	}
	// �v���O�C����n��
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ���e�폜
			DeleteBigBomb(i)
		}
	}

	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ���e�폜
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
	
	// �v���C���[���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// ������
		g_HasBomb[client] = false;
		
		// �U���҃N���A
		g_Drunker[client] = -1;
		
		// �^�C�}�[�N���A
		ClearTimer(g_TauntTimer[client]);
		
		// �^�C�}�[�N���A
		ClearTimer(g_FuseEnd[client]);
		
		// �^�C�}�[�N���A
		ClearTimer(g_TauntChain[client]);
		
		// �^�C�}�[�N���A
		ClearTimer(g_LoopTimer[client]);
		
		// �^�C�}�[�N���A
		ClearTimer(g_LoopVisualTimer[client]);

		// �������������t���O�N���A
		g_FirstTaunt[client] = false;
				
		// �f�t�H���g�X�s�[�h
		TF2_SetPlayerDefaultSpeed(client);
		//SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", TF2_GetPlayerClassSpeed(client));

		// �d�͖߂�
		SetEntityGravity(client, 1.0);
		
		// �̂Ƃ߂�
		StopSound(client, 0, SOUND_DEMO_SING);
		
		// ���e�̃��f�����폜
		DeleteBigBomb(client);
		
		// ���E�G�t�F�N�g
		g_AngleDir[client] = 1;
		g_FadeColor[client][0] = 255;
		g_FadeColor[client][1] = 255;
		g_FadeColor[client][2] = 255;
		ScreenFade(client, 0, 0, 0, 0, 255, IN);
		
		// ���E�߂��B
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_DemoMan)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:attribute4[256];
			new String:percentage[16];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_DRUNKBOMB", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_3", client, GetConVarFloat(g_FuseTime) );
			GetPercentageString( GetConVarFloat( g_MoveSpeedMag ), percentage, sizeof( percentage ) )
			Format( attribute4, sizeof( attribute4 ), "%T", "DESCRIPTION_DRUNKBOMB_ATTRIBUTE_4", client, percentage );
			
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s", attribute1);
			// 3�y�[�W��
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s\n%s\n%s", attribute2, attribute3, attribute4 );
			
		}
	}
	
	// �ؒf
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		g_BombModel[client] = -1;
	}

	// ���S
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		// ���s�G�t�F�N�g
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

		// �C�x���g��������
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
	
	// �v���C���[���T�v���C
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			// �f���}��
			if( TF2_GetPlayerClass(client) == TFClass_DemoMan && g_AbilityUnlock[client] && g_FuseEnd[client] != INVALID_HANDLE )
			{
				// ����Ď擾���Ȃ��悤��
				// �ߐڕ���ȊO�폜
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
// �����R�}���h�擾
//
/////////////////////////////////////////////////////////////////////
public Action:Command_Taunt(client, args)
{
	// MOD��ON�̎�����
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
// ����
//
/////////////////////////////////////////////////////////////////////
public TauntCheck(any:client)
{
	// �t���[�Y���΂��Ă��Ȃ�
	if( g_FuseEnd[client] == INVALID_HANDLE )
	{
		// ���햼�擾
		new String:classname[64];
		TF2_GetCurrentWeaponClass(client, classname, 64);
		
		// �O������
		if(StrEqual(classname, "CTFGrenadeLauncher"))
		{
			ClearTimer(g_TauntTimer[client]);
			g_TauntTimer[client] = CreateTimer(2.0, Timer_TauntEnd, client);
		}
		
		// �{�g���� �R���{���ԓ�
		if(StrEqual(classname, "CTFBottle") && g_FirstTaunt[client])
		{
			ClearTimer(g_TauntTimer[client]);
			g_TauntTimer[client] = CreateTimer(4.3, Timer_TauntEnd, client);
		}
		
	}
}

/////////////////////////////////////////////////////////////////////
//
// �����I���^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntEnd(Handle:timer, any:client)
{
	g_TauntTimer[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(TF2_IsPlayerTaunt(client))
		{
			// ���햼�擾
			new String:classname[64];
			TF2_GetCurrentWeaponClass(client, classname, 64);
			
			// �O������
			if(StrEqual(classname, "CTFGrenadeLauncher"))
			{
				g_FirstTaunt[client] = true;
				
				// �R���{�^�C�}�[����
				ClearTimer(g_TauntChain[client]);
				g_TauntChain[client] = CreateTimer(3.0, Timer_TauntChainEnd, client);
				
			}
			else if(StrEqual(classname, "CTFBottle"))
			{
				// �������e�X�^�[�g
				BomTimerStart(client);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �R���{���ԏI��
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntChainEnd(Handle:timer, any:client)
{
	g_TauntChain[client] = INVALID_HANDLE;
	g_FirstTaunt[client] = false;
}


/////////////////////////////////////////////////////////////////////
//
// �������e�X�^�[�g
//
/////////////////////////////////////////////////////////////////////
stock BomTimerStart(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// ����
		g_HasBomb[client] = true;
		
		// �t���[�Y����
		ClearTimer(g_FuseEnd[client]);
		g_FuseEnd[client] = CreateTimer(GetConVarFloat(g_FuseTime), Timer_FuseEnd, client);
		//AttachParticleBone(client, "warp_version", "eyes", GetConVarFloat(g_FuseTime));

		
		// �̗͑S��
		//SetEntityHealth(client, TF2_GetPlayerMaxHealth(client));
		
		// �����T�E���h(��)
		EmitSoundToAll(SOUND_DEMO_BEEP, client, _, _, SND_CHANGEPITCH, 1.0, 100);
		EmitSoundToAll(SOUND_DEMO_SING, client, _, _, SND_CHANGEPITCH, 1.0, 100);

		// �A�������p�^�C�}�[����
		ClearTimer(g_LoopTimer[client]);
		g_LoopTimer[client] = CreateTimer(0.05, Timer_Loop, client, TIMER_REPEAT);

		// �A�������p�^�C�}�[����
		ClearTimer(g_LoopVisualTimer[client]);
		g_LoopVisualTimer[client] = CreateTimer(0.8, Timer_LoopVisual, client, TIMER_REPEAT);

		
		//PrintToChat(client, "%d", GetPlayerWeaponSlot(client, 0));

		// ���E�̂��
		//CreateDrug(client);

		
		// �w���ɔ��e�w����
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

		// �ߐڕ���ȊO�폜
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
// ���[�v�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_Loop(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_FuseEnd[client] != INVALID_HANDLE)
	{
		// �̗͏��X�ɉ�
//		new nowHealth = GetClientHealth(client);
//		nowHealth += 1;
//		if( nowHealth > TF2_GetPlayerMaxHealth(client) )
//		{
//			nowHealth = TF2_GetPlayerMaxHealth(client);
//		}
//		SetEntityHealth(client, nowHealth);

		// �^�b�N�����ȊO���̑����_�E��
		if( !TF2_IsPlayerCharging(client) )
		{
			TF2_SetPlayerSpeed(client, TF2_GetPlayerClassSpeed(client) * GetConVarFloat(g_MoveSpeedMag));
		}
		//SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(g_MoveSpeedMag));

		// ����Ď擾���Ȃ��悤��
		// �ߐڕ���ȊO�폜
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
		
		
		// ���E���
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
// ���[�v�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_LoopVisual(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
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
// �t���[�Y�I���I���^�C�}�[�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FuseEnd(Handle:timer, any:client)
{
	g_FuseEnd[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �̂Ƃ߂�
		StopSound(client, 0, SOUND_DEMO_SING);
		
		//ClientCommand(client, "slot3");
		
		// �����G�t�F�N�g
		ExplodeEffect(client);
		
		// �_���[�W�`�F�b�N
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
		
		// ���E�G�t�F�N�g�폜
		//KillDrug(client);
		
		// ��������
		g_HasBomb[client] = false;
		// ����
		FakeClientCommand(client, "explode");
		 
	}
}

/////////////////////////////////////////////////////////////////////
//
// �����G�t�F�N�g
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
// �l�̂ւ̃_���[�W
//
/////////////////////////////////////////////////////////////////////
stock RadiusDamage(any:client)
{
	new Float:fAttackerPos[3];
	new Float:fVictimPos[3];
	new Float:distance;
	new maxclients = GetMaxClients();

	// ��Q�`�F�b�N
	for (new victim = 1; victim <= maxclients; victim++)
	{
		if( IsClientInGame(victim) && IsPlayerAlive(victim) )
		{
			if( GetClientTeam(victim) != GetClientTeam(client) && victim != client )
			{

				// �f���}���ʒu
				GetClientAbsOrigin(client, fAttackerPos);
				// ��Q�҈ʒu
				GetClientAbsOrigin(victim, fVictimPos);
				// �f���}���Ɣ�Q�҂̈ʒu
				distance = GetVectorDistanceMeter(fAttackerPos, fVictimPos);
				
				if(CanSeeTarget(victim, fVictimPos, g_BombModel[client], fAttackerPos, GetConVarFloat(g_DamageRadius), true, true))
				{
					//GetEdictClassname(HitEnt, edictName, sizeof(edictName)); 
					//PrintToChat(client,"hit = %s", edictName);
					//AttachParticleBone(victim, "conc_stars", "head",1.0);
					
					GetClientAbsOrigin(client, fAttackerPos);
					new Float:fKnockVelocity[3];	// �����̔���
					
					// �����̕����擾
					SubtractVectors(fAttackerPos, fVictimPos, fKnockVelocity);
					NormalizeVector(fKnockVelocity, fKnockVelocity); 

					// ��Q�҂̃x�N�g���������擾
					new Float:fVelocity[3];
					GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
					
					
					fVelocity[2] += 400.0;
					
					// �������Z�o
					ScaleVector(fKnockVelocity, -1000.0 * (1.0 / distance)); 
					AddVectors(fVelocity, fKnockVelocity, fVelocity);
					
					// �v���C���[�ւ̔�����ݒ�
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
// �͈̓_���[�W���ݕ�
//
/////////////////////////////////////////////////////////////////////
stock RadiusDamageBuiltObject(any:client, objectType)
{
	new Float:fAttackerPos[3];
	new Float:fObjPos[3];
	new Float:distance;

	new String:edictName[64];
	// �I�u�W�F�N�g�^�C�v����
	switch( objectType )
	{
	case 0: edictName = "obj_dispenser";
	case 1: edictName = "obj_teleporter_entrance";
	case 2: edictName = "obj_teleporter_exit";
	case 3: edictName = "obj_sentrygun";
	}
	// �I�u�W�F�N�g����
	new builtObj = -1;
	while ( ( builtObj = FindEntityByClassname( builtObj, edictName ) ) != -1 )
	{
		// ������`�F�b�N
		new iOwner = GetEntPropEnt( builtObj, Prop_Send, "m_hBuilder" );
		if( GetClientTeam( iOwner ) != GetClientTeam( client ) )
		{
			// �A�^�b�J�[�̈ʒu
			GetClientAbsOrigin( client, fAttackerPos );
			// �I�u�W�F�N�g�̈ʒu�擾
			GetEntPropVector( builtObj, Prop_Data, "m_vecOrigin", fObjPos );
			// �A�^�b�J�[�Ɣ�Q�҂̈ʒu
			distance = GetVectorDistanceMeter( fAttackerPos, fObjPos );
			
			// �_���[�W��K�p
			if( CanSeeTarget( builtObj, fObjPos, g_BombModel[ client ], fAttackerPos, GetConVarFloat( g_DamageRadius ), true, true) )
			{
				new damage = RoundFloat( GetConVarInt( g_BaseDamage ) * ( 1.0 / distance ) );
				
				// ���̃_���[�W�Ŕj�󂳂��H
				if( GetEntProp( builtObj, Prop_Send, "m_iHealth") - damage <= 0 )
				{
					// �L�����O�ɕ\��
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
// �w���̔��e�폜
//
/////////////////////////////////////////////////////////////////////
stock DeleteBigBomb(any:client)
{
	// ���e�̃��f�����폜
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

