/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.8
// �E�d�l��ύX
// �E1.3.1�ŃR���p�C��
// �Esm_rmf_dopinginjection_doping_time��ǉ�
// �Esm_rmf_dopinginjection_use_ammo��ǉ�
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
#include <sdkhooks>

/////////////////////////////////////////////////////////////////////
//
// �萔
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Doping Injection"
#define PL_DESC "Doping Injection"
#define PL_VERSION "0.0.8"
#define PL_TRANSLATION "dopinginjection.phrases"

#define EFFECT_HEAL_RED	"healthgained_red"
#define EFFECT_HEAL_BLU	"healthgained_blu"
#define EFFECT_BLOOD	"blood_impact_red_01"
#define EFFECT_BREAK	"lowV_debrischunks"

//#define SOUND_HEAL_START "weapons/minigun_wind_up.wav"
//#define SOUND_HEAL_LOOP "weapons/minigun_spin.wav"
//#define SOUND_HEAL_STOP "weapons/minigun_wind_down.wav"

#define SOUND_DOPING_INJECTION "weapons/ubersaw_hit1.wav"
#define SOUND_BREAK_SYRINGE "weapons/bottle_break.wav"
#define SOUND_NO_TARGET "weapons/medigun_no_target.wav"

#define MDL_SYRINGE "models/weapons/w_models/w_syringe.mdl"
#define MDL_INSIDE "models/effects/miniguncasing.mdl"

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
new Handle:g_HealLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ���[�v����
new Handle:g_HealSpeed = INVALID_HANDLE;		// ConVar�񕜑��x
new Handle:g_HealRate = INVALID_HANDLE;			// ConVar�񕜃��[�g
new bool:g_NowHealing[MAXPLAYERS+1] = false; 						// �񕜒��H

new Handle:g_HealthDreinTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// �̗͌��炷�p�̃^�C�}�[
new bool:g_NeedDrein[MAXPLAYERS+1]		= false;				// �h���C�����K�v���H
new Handle:g_DopingTime = INVALID_HANDLE;			// ConVar��������
new Handle:g_UseAmmo = INVALID_HANDLE;				// ConVa�g�p�e��
new g_SyringeModel[MAXPLAYERS+1] = -1; 							// ���Ɏh������
new g_InsideModel[MAXPLAYERS+1] = -1; 							// ���Ɏh�����˂̒��g
new bool:g_NowDoping[MAXPLAYERS+1] = false; 					// �h�[�s���O���H
new Handle:g_SyringeTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ���˃^�C�}�[
new Handle:g_DopingLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// ���[�v����
new g_NowTrans[MAXPLAYERS+1] = 255; 							// �t�̂̓����x

new String:SOUND_VOICE[9][64];				// �{�C�X�t�@�C���� 9�N���X

new model = -1;


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
		CreateConVar("sm_rmf_tf_dopinginjection", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_dopinginjection","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_HealSpeed	= CreateConVar("sm_rmf_dopinginjection_heal_speed",		"1.0",	"heal Speed (0.0-120.0)");
		g_HealRate	= CreateConVar("sm_rmf_dopinginjection_heal_rate",		"10",	"Heal rate (0-500)");
		g_DopingTime= CreateConVar("sm_rmf_dopinginjection_doping_time",	"10.0",	"Doping duration (0.0-120.0)");
		g_UseAmmo	= CreateConVar("sm_rmf_dopinginjection_use_ammo",		"20",	"Ammo required (0-200)");
		HookConVarChange(g_HealSpeed, ConVarChange_Time);
		HookConVarChange(g_HealRate, ConVarChange_Health);
		HookConVarChange(g_DopingTime, ConVarChange_Time);
		HookConVarChange(g_UseAmmo, ConVarChange_Ammo);
	
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_dopinginjection_class", "5", "Ability class");
		
		// �{�C�X�t�@�C��
		SOUND_VOICE[_:TFClass_Scout - 1]	= "vo/scout_painsharp01.wav"
		SOUND_VOICE[_:TFClass_Sniper - 1]	= "vo/sniper_painsharp01.wav"
		SOUND_VOICE[_:TFClass_Soldier - 1]	= "vo/soldier_painsharp01.wav"
		SOUND_VOICE[_:TFClass_DemoMan - 1]	= "vo/demoman_painsharp02.wav"
		SOUND_VOICE[_:TFClass_Medic - 1]	= "vo/medic_painsharp08.wav"
		SOUND_VOICE[_:TFClass_Heavy - 1]	= "vo/heavy_painsharp02.wav"
		SOUND_VOICE[_:TFClass_Pyro - 1]		= "vo/pyro_painsharp03.wav"
		SOUND_VOICE[_:TFClass_Spy - 1]		= "vo/spy_painsharp03.wav"
		SOUND_VOICE[_:TFClass_Engineer - 1]	= "vo/engineer_painsharp02.wav"
		
		
	}
	// �v���O�C��������
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ���ˍ폜
			DeleteSyringe(i);
		}
	}
	// �v���O�C����n��
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ���ˍ폜
			DeleteSyringe(i);
		}
	}
	
	// �}�b�v�J�n
	if(StrEqual(name, EVENT_MAP_START))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ���ˍ폜
			DeleteSyringe(client)
		}

		PrePlayParticle(EFFECT_HEAL_RED);
		PrePlayParticle(EFFECT_HEAL_BLU);
		PrePlayParticle(EFFECT_BLOOD);
		PrePlayParticle(EFFECT_BREAK);
		
//		PrecacheSound(SOUND_HEAL_START, true);
//		PrecacheSound(SOUND_HEAL_LOOP, true);
//		PrecacheSound(SOUND_HEAL_STOP, true);
		PrecacheSound(SOUND_DOPING_INJECTION, true);
		PrecacheSound(SOUND_BREAK_SYRINGE, true);
		PrecacheSound(SOUND_NO_TARGET, true);
		
		// �{�C�X�ǂݍ���
		for(new i = 0; i < 9; i++)
		{
			PrecacheSound(SOUND_VOICE[i], true);
		}		
		
		model=PrecacheModel(MDL_SYRINGE, true);
		PrecacheModel(MDL_INSIDE, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �T�E���h��~
//		StopSound(client, 0, SOUND_HEAL_LOOP);
	
		// �񕜏�ԃN���A
		g_NowHealing[client] = false;
		g_NowDoping[client] = false;

		// �����x���Z�b�g
		g_NowTrans[client] = 255;
		

		// �^�C�}�[�N���A
		ClearTimer( g_HealLoopTimer[ client ] );
		ClearTimer( g_SyringeTimer[ client ] );
		ClearTimer( g_DopingLoopTimer[ client ] );
		ClearTimer( g_HealthDreinTimer[client] );

		// �h���C�����Z�b�g
		g_NeedDrein[ client ]	= false;
		
		// �J���[���ɖ߂��B
		SetEntityRenderColor(client, 255, 255, 255, 255);

		// ���̒��ˍ폜
		DeleteSyringe(client);
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Medic)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_DOPINGINJECTION", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_DOPINGINJECTION_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_DOPINGINJECTION_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_DOPINGINJECTION_ATTRIBUTE_2", client, GetConVarInt( g_UseAmmo ) );
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s", attribute1 );
			// 3�y�[�W��
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s", attribute2 );
		}
	}
	
	// �v���C���[�����f�B���C
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
//		// ����
//		if( TF2_GetPlayerClass( client ) == TFClass_Medic && g_AbilityUnlock[client])
//		{
//			ClientCommand(client, "slot2");
//			// �Z�J���_���폜
//			new weaponIndex = GetPlayerWeaponSlot(client, 0);
//			if( weaponIndex != -1 )
//			{
//			//	TF2_RemoveWeaponSlot(client, 0);
//				//RemovePlayerItem(client, weaponIndex);
//				//AcceptEntityInput(weaponIndex, "Kill");		
//			}			
//			// �A�������p�^�C�}�[����
//			//ClearTimer( g_HealLoopTimer[ client ] );
//			//g_HealLoopTimer[client] = CreateTimer(GetConVarFloat(g_HealSpeed), Timer_HealLoop, client, TIMER_REPEAT);
//			
//			// �F�ύX
//			if( TFTeam:GetClientTeam(client) == TFTeam_Red )
//			{
//				SetEntityRenderColor(client, 255, 200, 200, 255);
//			}
//			else
//			{
//				SetEntityRenderColor(client, 220, 220, 255, 255);
//			}	
//		}
	}
		
	// �v���C���[���T�v���C
//	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
//	{
//		if( IsClientInGame(client) && IsPlayerAlive(client) )
//		{
//			// ���f�B�b�N
//			if( TF2_GetPlayerClass(client) == TFClass_Medic && g_AbilityUnlock[client] )
//			{
//				// ����Ď擾���Ȃ��悤��
//				// ���ˏe�E�u���[�g�U�I�K�[�폜
//				ClientCommand(client, "slot2");
//				// �Z�J���_���폜
//				new weaponIndex = GetPlayerWeaponSlot(client, 0);
//				if( weaponIndex != -1 )
//				{
//			//		TF2_RemoveWeaponSlot(client, 0);
//					//RemovePlayerItem(client, weaponIndex);
//					//AcceptEntityInput(weaponIndex, "Kill");		
//				}
//				
//				// �F�ύX
//				if( TFTeam:GetClientTeam(client) == TFTeam_Red )
//				{
//					SetEntityRenderColor(client, 255, 200, 200, 255);
//				}
//				else
//				{
//					SetEntityRenderColor(client, 220, 220, 255, 255);
//				}	
//					
//			}
//		}
//	}
	// �v���C���[�ڑ�
	if(StrEqual(name, EVENT_PLAYER_CONNECT))
	{
	}
	
	// �v���C���[�ؒf
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
	}
	
	// �Q�[���t���[��
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
// �t���[���A�N�V����
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// ���f�B�b�N�̂�
		if(TF2_GetPlayerClass(client) == TFClass_Medic && g_AbilityUnlock[client])
		{
			// �L�[�`�F�b�N
			if( CheckElapsedTime(client, 1.5) )
			{
				// �U���{�^��
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// �L�[�����������Ԃ�ۑ�
					SaveKeyTime(client);
					DopingInjection(client);
				}

			}
		}
		
		// �X�p�C�̓����`�F�b�N
		if( TF2_GetPlayerClass(client) == TFClass_Spy && g_NowDoping[ client ] )
		{
			// �ϑ����ⓧ�����Ȃ璍�ˉB��
			if( TF2_IsPlayerDisguised(client)
				|| TF2_IsPlayerChangingCloak(client)
				|| TF2_IsPlayerCloaked(client)
				|| TF2_IsPlayerFeignDeath(client) )
			{
				if( g_SyringeModel[ client ] != -1 )
				{
					SetEntityRenderMode( g_SyringeModel[ client ], RENDER_TRANSCOLOR );
					SetEntityRenderColor( g_SyringeModel[ client ], 255, 255, 255, 0 );
				}
				
				if( g_InsideModel[ client ] != -1 )
				{
					SetEntityRenderColor( g_InsideModel[ client ], 255, 255, 255, 0 );
				}
			}
			else
			{
				if( g_SyringeModel[ client ] != -1 )
				{
					SetEntityRenderMode( g_SyringeModel[ client ], RENDER_NORMAL );
					SetEntityRenderColor( g_SyringeModel[ client ], 255, 255, 255, 255 );
				}
				
				if( g_InsideModel[ client ] != -1 )
				{
					SetEntityRenderColor( g_InsideModel[ client ], 255, 255, 255, g_NowTrans[client] );
				}
			}
			
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ���ˎh��
//
/////////////////////////////////////////////////////////////////////
stock DopingInjection(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// ����͒��ˏe�ƃu���[�g�U�I�K�[
		if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_SYRINGEGUN 
		|| TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_BLUTSAUGER )
		{
			// �^�[�Q�b�g���擾
			new target = GetClientAimTarget(client, false);
//			if(target < 1)
//				target = client;
			
			// �^�[�Q�b�g������
			if( target != -1 && IsPlayer( client )  )
			{
				if( GetClientTeam( client ) == GetClientTeam( target ) && GetDistanceMeter( client, target ) <= 2.0 )
				{
					// ���˂��ĂȂ�
					if( !g_NowDoping[ target ] )
					{
						new nowAmmo = GetEntProp( TF2_GetCurrentWeapon(client), Prop_Send, "m_iClip1"); 
						
						// �e���w�萔�ȏ�
						if( nowAmmo >= GetConVarInt( g_UseAmmo ) )
						{
							// �I���^�C�}�[����
							ClearTimer( g_SyringeTimer[ target ] );
							g_SyringeTimer[ target ] = CreateTimer( GetConVarFloat( g_DopingTime ), Timer_DopingEnd, target );
							
							// �A�������p�^�C�}�[����
							ClearTimer( g_DopingLoopTimer[ target ] );
							g_DopingLoopTimer[ target ] = CreateTimer(GetConVarFloat(g_HealSpeed), Timer_DopingLoop, target, TIMER_REPEAT);
							
							// ���ɒ���
							SpawnSyringe( target );
							
							// �e���炷
							nowAmmo -= GetConVarInt( g_UseAmmo );
							SetEntProp( TF2_GetCurrentWeapon(client), Prop_Send, "m_iClip1", nowAmmo ); 
							
							// ����
							g_NowDoping[ target ] = true;
							
							// ���b�Z�[�W
							PrintToChat( target, "\x05%T", "MESSAGE_INJECTION", client);

							return;
						}
					}
				}
			}
			EmitSoundToClient(client, SOUND_NO_TARGET, client, _, _, _, 1.0);
		}
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// ���[�v�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DopingLoop(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// �ϑ����ⓧ�����͉񕜂ł��Ȃ�
		if( !TF2_IsPlayerDisguised(client)
			&& !TF2_IsPlayerChangingCloak(client)
			&& !TF2_IsPlayerCloaked(client)
			&& !TF2_IsPlayerFeignDeath(client) )
		{
			// ��
			new nowHealth = GetClientHealth(client);
			if( nowHealth < TF2_GetPlayerMaxHealth(client) )
			{
				
				// �w���X����
				nowHealth += GetConVarInt(g_HealRate);
				
				if(nowHealth >= TF2_GetPlayerMaxHealth(client))
				{
					nowHealth = TF2_GetPlayerMaxHealth(client);
				}
				
				// ���̉񕜂ɂ���ăI�[�o�[�q�[����ԂɂȂ�����h���C�����K�v
				if( GetClientHealth(client) <= TF2_GetPlayerDefaultHealth(client) && nowHealth > TF2_GetPlayerDefaultHealth(client) )
				{
					g_NeedDrein[client] = true;
				}

				// �f�t�H���g�ȉ��Ȃ炢��Ȃ�
				if( nowHealth <= TF2_GetPlayerDefaultHealth(client) )
				{
					g_NeedDrein[client] = false;
				}
				
				// �̗͐ݒ�
				SetEntityHealth(client, nowHealth);

				// �񕜕\��
				new Handle:newEvent = CreateEvent( "player_healonhit" );
				if( newEvent != INVALID_HANDLE )
				{
					SetEventInt( newEvent, "amount", GetConVarInt(g_HealRate) );
					SetEventInt( newEvent, "entindex", client );
					FireEvent( newEvent );
				}

				// �G�t�F�N�g
				new Float:pos[3];
				for(new i = 0; i < GetConVarInt(g_HealRate); i++)
				{
					pos[0] = GetRandomFloat(-20.0, 20.0);
					pos[1] = GetRandomFloat(-20.0, 20.0);
					pos[2] = GetRandomFloat(-20.0, 0.0);
					if( TFTeam:GetClientTeam(client) == TFTeam_Red)
					{
			    		
						AttachParticleBone(client, EFFECT_HEAL_RED, "head", GetRandomFloat(1.0, 3.0), pos);
			    	}
					else
					{
						AttachParticleBone(client, EFFECT_HEAL_BLU, "head", GetRandomFloat(1.0, 3.0), pos);
					}
				}

				// �h���C���^�C�}�[����
				ClearTimer( g_HealthDreinTimer[client] );
				if( g_NeedDrein[client] )
				{
					g_HealthDreinTimer[client] = CreateTimer(0.25, Timer_HealthDrein, client, TIMER_REPEAT );
				}
				
			}
					
			// �t�̂𔖂߂�
			if( g_InsideModel[ client ]  != -1 )
			{
				g_NowTrans[client] -= RoundFloat( 255.0 / ( (GetConVarFloat( g_DopingTime ) / GetConVarFloat( g_HealSpeed ) ) ) );
				if( g_NowTrans[client] < 0 )
				{
					g_NowTrans[client] = 0;
				}
				SetEntityRenderColor( g_InsideModel[ client ], 255, 255, 255, g_NowTrans[client] );
			}
		}
	
	}
	else
	{
		ClearTimer( g_DopingLoopTimer[ client ] );
	}
}

/////////////////////////////////////////////////////////////////////
//
// �w���X�h���C���p
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_HealthDrein(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �I�[�o�[�q�[����ԁ��񕜂���Ă��Ȃ�
		if( TF2_IsPlayerOverHealing( client ) && TF2_GetNumHealers(client) == 0 && g_NeedDrein[client] )
		{
			// 1���炷
			new nowHealth = GetClientHealth(client);
			
			// �ʏ�w���X�ȏ�Ȃ�h���C��
			if( nowHealth > TF2_GetPlayerDefaultHealth(client))
			{
				nowHealth--;
				SetEntityHealth(client, nowHealth);
				return;
			}
		}		
	}

	// �����������ĂȂ���ΏI��
	ClearTimer( g_HealthDreinTimer[client] );
}

/////////////////////////////////////////////////////////////////////
//
// �h�[�s���O�I��
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DopingEnd(Handle:timer, any:client)
{
	g_SyringeTimer[ client ] = INVALID_HANDLE;
	ClearTimer( g_DopingLoopTimer[ client ] );
	
	// �����I��
	g_NowDoping[ client ] = false;
	
	// �Q�[���ɓ����Ă���
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		// �ϑ����ⓧ�����ȊO
		if( !TF2_IsPlayerDisguised(client)
			&& !TF2_IsPlayerChangingCloak(client)
			&& !TF2_IsPlayerCloaked(client)
			&& !TF2_IsPlayerFeignDeath(client) )
		{
			if( g_SyringeModel[client] != -1 && g_SyringeModel[client] != 0)
			{
				if( IsValidEntity(g_SyringeModel[client]) )
				{
					// �G�t�F�N�g
					new Float:pos[3];
					pos[0] = -5.0;
					pos[2] = 10.0;
					AttachParticleBone(client, EFFECT_BREAK, "head", 1.0, pos);
					
					// ��ꂽ��
					EmitSoundToAll( SOUND_BREAK_SYRINGE, g_SyringeModel[client], _, _, SND_CHANGEPITCH, 0.5, 100);		
				}	
			}
		}
		
		DeleteSyringe( client );
							
		// ���b�Z�[�W
		PrintToChat( client, "\x05%T", "MESSAGE_END", client);
	}
}

/////////////////////////////////////////////////////////////////////
//
// ���[�v�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
//public Action:Timer_HealLoop(Handle:timer, any:client)
//{
//	// �Q�[���ɓ����Ă���
//	if( IsClientInGame(client) && IsPlayerAlive(client) )
//	{
//		// ��
//		new nowHealth = GetClientHealth(client);
//		// �I�[�o�[�q�[������Ă��Ȃ��Ƃ��B
//		if( nowHealth < TF2_GetPlayerDefaultHealth(client) )
//		{
//			// �񕜂͂��߂������[�v�T�E���h�Đ�
//			if(!g_NowHealing[client])
//			{
//				// �T�E���h�Ƃ��G�t�F�N�g
//				EmitSoundToAll(SOUND_HEAL_START, client, _, _, SND_CHANGEPITCH, 0.08, 150);
//				EmitSoundToAll(SOUND_HEAL_LOOP, client, _, _, SND_CHANGEPITCH, 0.05, 170);
//			}
//
//			nowHealth += GetConVarInt(g_HealRate);
//
//			if(nowHealth >= TF2_GetPlayerDefaultHealth(client))
//			{
//				nowHealth = TF2_GetPlayerDefaultHealth(client);
//			}
//			
//			// �̗͐ݒ�
//			SetEntityHealth(client, nowHealth);
//
//			// �񕜕\��
//			new Handle:newEvent = CreateEvent( "player_healonhit" );
//			if( newEvent != INVALID_HANDLE )
//			{
//				SetEventInt( newEvent, "amount", GetConVarInt(g_HealRate) );
//				SetEventInt( newEvent, "entindex", client );
//				FireEvent( newEvent );
//			}
//			
//			new Float:pos[3];
//			for(new i = 0; i < GetConVarInt(g_HealRate); i++)
//			{
//		    	pos[0] = GetRandomFloat(-20.0, 20.0);
//		    	pos[1] = GetRandomFloat(-20.0, 20.0);
//		    	pos[2] = GetRandomFloat(-20.0, 0.0);
//		    	if( TFTeam:GetClientTeam(client) == TFTeam_Red)
//		    	{
//		    		
//					AttachParticleBone(client, EFFECT_HEAL_RED, "head", GetRandomFloat(1.0, 3.0), pos);
//		    	}
//				else
//				{
//					AttachParticleBone(client, EFFECT_HEAL_BLU, "head", GetRandomFloat(1.0, 3.0), pos);
//				}
//			}
//			g_NowHealing[client] = true;	
//		}
//		else
//		{
//			// �񕜒�����Ȃ���΃T�E���h��~
//			if(g_NowHealing[client])
//			{
//				// �T�E���h��~
//				StopSound(client, 0, SOUND_HEAL_LOOP);
//				EmitSoundToAll(SOUND_HEAL_STOP, client, _, _, SND_CHANGEPITCH, 0.08, 150);
//				g_NowHealing[client] = false;
//			}
//			
//		}
//	
//	}
//	else
//	{
//		ClearTimer( g_HealLoopTimer[ client ] );
//	}
//}


/////////////////////////////////////////////////////////////////////
//
// ���̒��ˍ쐬
//
/////////////////////////////////////////////////////////////////////
stock SpawnSyringe(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// ��U�폜
		DeleteSyringe( client );
//		new Float:pos[3];
//		new Float:vec[3];
//		new Float:vel[3];
//		vec[0] = 1.0;
//		vec[1] = 1.0;
//		vec[2] = 1.0;
//		GetClientAbsOrigin(client, pos);
//		TE_Start("Client Projectile");
//		TE_WriteVector("m_vecOrigin",pos);
//		TE_WriteVector("m_vecVelocity",vel);
//		TE_WriteNum("m_nModelIndex",model);
//		TE_WriteNum("m_nLifeTime",100);
//		TE_WriteNum("m_hOwner",client);
//		TE_SendToClient(client)


		// �쐬
		new syringe = CreateEntityByName("prop_dynamic");
		if ( IsValidEdict( syringe ) )
		{
			new String:tName[32];
			GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof( tName ) );
			DispatchKeyValue(syringe,	"targetname",	"head_syringe");
			DispatchKeyValue(syringe,	"parentname",	tName);
			SetEntityModel( syringe, MDL_SYRINGE );
			DispatchSpawn( syringe );
			SetVariantString( "!activator" );
			AcceptEntityInput(syringe, "SetParent",				client, client, 0);
			SetVariantString( "head" );
			AcceptEntityInput(syringe, "SetParentAttachment",	client, client, 0);
			ActivateEntity(syringe);
			SetEntPropEnt(syringe, Prop_Send, "m_hOwnerEntity", client );
			new Float:pos[3];
			new Float:ang[3];
			pos[0] = -5.0;
			pos[1] = 0.0;
			pos[2] = 18.0;
			ang[0] = 165.0;
			ang[1] = 0.0;
			ang[2] = 0.0;

			// �h�����Ă���悤�Ɉړ�
			TeleportEntity( syringe , pos, ang, NULL_VECTOR );

			// ����
			AttachParticleBone( client, EFFECT_BLOOD, "head", GetRandomFloat(1.0, 3.0) );
			
			// �{�C�X�Đ�
			EmitSoundToAll(SOUND_VOICE[_:TF2_GetPlayerClass( client ) -1], client, _, _, SND_CHANGEPITCH, 1.0, 100);
			
			// ��������
			EmitSoundToAll( SOUND_DOPING_INJECTION, client, _, _, SND_CHANGEPITCH, 0.8, 80);
			
			// �f�[�^������
			g_SyringeModel[ client ] = syringe;
			
			// SDKHook
			SDKHook( g_SyringeModel[ client ], SDKHook_SetTransmit, Hook_SetTransmit );

			// ���ˊ�̒��g
			new inside = CreateEntityByName("prop_dynamic");
			if ( IsValidEdict( inside ) )
			{
				GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof( tName ) );
				DispatchKeyValue(inside,	"targetname",	"head_inside");
				DispatchKeyValue(inside,	"parentname",	tName);
				SetEntityModel( inside, MDL_INSIDE );
				DispatchSpawn( inside );
				SetVariantString( "!activator" );
				AcceptEntityInput(inside, "SetParent",				client, client, 0);
				SetVariantString( "head" );
				AcceptEntityInput(inside, "SetParentAttachment",	client, client, 0);
				ActivateEntity(inside);
				SetEntPropEnt(inside, Prop_Send, "m_hOwnerEntity", client );
				new Float:pos2[3];
				new Float:ang2[3];
				pos2[0] = -2.0;
				pos2[1] = 0.0;
				pos2[2] = 7.0;
				ang2[0] = 0.0;
				ang2[1] = 90.0;
				ang2[2] = -105.0;
				
				// �h�����Ă���悤�Ɉړ�
				TeleportEntity( inside , pos2, ang2, NULL_VECTOR );
				
				g_NowTrans[client] = 255;
				SetEntityRenderMode( inside, RENDER_TRANSCOLOR );
				SetEntityRenderColor( inside, 255, 255, 255, g_NowTrans[client] );

				// �f�[�^������
				g_InsideModel[ client ] = inside;
				
				// SDKHook
				SDKHook( g_InsideModel[ client ], SDKHook_SetTransmit, Hook_SetTransmit );
			}
			
			
			// �h���C���^�C�}�[�N���A
			ClearTimer( g_HealthDreinTimer[client] );
	    }
	}
}
/////////////////////////////////////////////////////////////////////
//
// ���̒��ˍ폜
//
/////////////////////////////////////////////////////////////////////
stock DeleteSyringe(any:client)
{
	// ���˂̃��f�����폜
	if( g_SyringeModel[client] != -1 && g_SyringeModel[client] != 0)
	{
		// SDKUnhook
		SDKUnhook( g_SyringeModel[client], SDKHook_SetTransmit, Hook_SetTransmit );
		if( IsValidEntity(g_SyringeModel[client]) )
		{
			ActivateEntity(g_SyringeModel[client]);
			AcceptEntityInput(g_SyringeModel[client], "Kill");
			g_SyringeModel[client] = -1;
		}	
	}
	// ���˂̃��f�����폜
	if( g_InsideModel[client] != -1 && g_InsideModel[client] != 0)
	{
		if( IsValidEntity(g_InsideModel[client]) )
		{
			ActivateEntity(g_InsideModel[client]);
			AcceptEntityInput(g_InsideModel[client], "Kill");
			g_InsideModel[client] = -1;
		}	
	}
}

/////////////////////////////////////////////////////////////////////
//
// ��l�̂ł̕\����\��
//
/////////////////////////////////////////////////////////////////////
public Action:Hook_SetTransmit( entity, client )
{

	if( TF2_EdictNameEqual( entity, "prop_dynamic") )
	{
		// �^�[�Q�b�g���擾�擾
		new String:nameTarget[64];
		GetEntPropString( entity, Prop_Data, "m_iName", nameTarget, sizeof( nameTarget ) );

		// �ݒu�����V���x���Ȃ�
		if( StrEqual( nameTarget, "head_syringe" ) || StrEqual( nameTarget, "head_inside" ) )
		{
			// �����i�O�l�̒��ȊO�j�͌����Ȃ�
			if( client == GetEntPropEnt( entity, Prop_Send, "m_hOwnerEntity" ) && !TF2_IsPlayerTaunt(client) )
			{
			    return Plugin_Handled;
			}
		}
		
	}
    return Plugin_Continue;
}  
