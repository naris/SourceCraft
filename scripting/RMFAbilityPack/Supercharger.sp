/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.7
// �E�ꕔ�d�l��ύX
// �E1.3.1�ŃR���p�C��
// �Esm_rmf_supercharger_drain_speed��ǉ�
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

/////////////////////////////////////////////////////////////////////
//
// �萔
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Supercharger"
#define PL_DESC "Supercharger"
#define PL_VERSION "0.0.7"
#define PL_TRANSLATION "supercharger.phrases"


#define EFFECT_ABLE_SMOKE "sapper_smoke"
#define EFFECT_ABLE_EMBERS "sapper_flyingembers"
#define EFFECT_ABLE_FLASH "sapper_flashup"
#define EFFECT_ABLE_DEBRIS "sapper_debris"

#define EFFECT_CHARGER_SPARK1 "buildingdamage_sparks2"
#define EFFECT_CHARGER_SPARK2 "buildingdamage_sparks4"
#define EFFECT_CHARGER_FIRE "buildingdamage_fire3"

#define SOUND_CHARGER_ON "weapons/sapper_removed.wav"
#define SOUND_CHARGER_START "weapons/minifun_wind_up.wav"
#define SOUND_CHARGER_LOOP "misc/hologram_malfunction.wav"
#define SOUND_CHARGER_STOP "weapons/minigun_wind_down.wav"

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
new Handle:g_ChargeLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ���[�v����
new Handle:g_ChargeSpeed = INVALID_HANDLE;							// ConVar�񕜑��x
new Handle:g_ChargeRate = INVALID_HANDLE;							// ConVar�񕜃��[�g
new Handle:g_DrainSpeed = INVALID_HANDLE;							// ConVar�h���C���X�s�[�h
new Handle:g_DrainLoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;				// �h���C�����[�v����
new g_LoopEffect[MAXPLAYERS+1][3];									// ���[�v�G�t�F�N�g
new bool:g_NowHealing[MAXPLAYERS+1] = false; 						// �񕜒��H

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
		CreateConVar("sm_rmf_tf_supercharger", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_supercharger","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_ChargeSpeed	= CreateConVar("sm_rmf_supercharger_charg_speed",	"1.0",	"Charge Speed (0.0-120.0)");
		g_ChargeRate	= CreateConVar("sm_rmf_supercharger_charge_rate",	"2",	"Charge rate (0-100)");
		g_DrainSpeed	= CreateConVar("sm_rmf_supercharger_drain_speed",	"0.25",	"Ubercharge drain speed (0.0-120.0)");
		HookConVarChange(g_ChargeSpeed,	ConVarChange_Time);
		HookConVarChange(g_ChargeRate,	ConVarChange_Uber);
		HookConVarChange(g_DrainSpeed,	ConVarChange_Time);
		
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_supercharger_class", "5", "Ability class");
		
	}
	
	// �}�b�v�J�n
	if(StrEqual(name, EVENT_MAP_START))
	{
		
		PrePlayParticle(EFFECT_CHARGER_SPARK1);
		PrePlayParticle(EFFECT_CHARGER_SPARK2);
		PrePlayParticle(EFFECT_CHARGER_FIRE);
		
		PrePlayParticle(EFFECT_ABLE_SMOKE);
		PrePlayParticle(EFFECT_ABLE_EMBERS);
		PrePlayParticle(EFFECT_ABLE_FLASH);
		PrePlayParticle(EFFECT_ABLE_DEBRIS);

		
		PrecacheSound(SOUND_CHARGER_ON, true);
		PrecacheSound(SOUND_CHARGER_START, true);
		PrecacheSound(SOUND_CHARGER_LOOP, true);
		PrecacheSound(SOUND_CHARGER_STOP, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		for(new i = 0; i < 3; i++)
		{
			DeleteParticle(g_LoopEffect[client][i]);
			g_LoopEffect[client][i] = -1;
		}

		// �T�E���h��~
		StopSound(client, 0, SOUND_CHARGER_LOOP);
	
		// �񕜏�ԃN���A
		g_NowHealing[client] = false;

		// �^�C�}�[�N���A
		ClearTimer( g_ChargeLoopTimer[ client ] );
		ClearTimer( g_DrainLoopTimer[ client ] );
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Medic)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_SUPERCHARGER", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_SUPERCHARGER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_SUPERCHARGER_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_SUPERCHARGER_ATTRIBUTE_2", client );
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );

		}

	}

	// �v���C���[�����f�B���C
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
		// ����
		if( TF2_GetPlayerClass( client ) == TFClass_Medic && g_AbilityUnlock[client])
		{
			Supercharger( client );
			// �ߐڕ���ȊO�폜
			ClientCommand(client, "slot2");
			new weaponIndex;
			for(new i=0;i<3;i++)
			{
				if(i != 1)
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
			
			ClearTimer( g_DrainLoopTimer[ client ] );
			g_DrainLoopTimer[client] = CreateTimer( GetConVarFloat( g_DrainSpeed ), Timer_DrainLoop, client, TIMER_REPEAT);
		}
	}

	// �v���C���[���T�v���C
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			// ���f�B�b�N
			if( TF2_GetPlayerClass(client) == TFClass_Medic && g_AbilityUnlock[client] )
			{
				// �ߐڕ���ȊO�폜
				ClientCommand(client, "slot2");
				new weaponIndex;
				for(new i=0;i<3;i++)
				{
					if(i != 1)
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
// ����
//
/////////////////////////////////////////////////////////////////////
public Supercharger( any:client )
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �A�������p�^�C�}�[����
		ClearTimer( g_ChargeLoopTimer[ client ] );
		g_ChargeLoopTimer[client] = CreateTimer(GetConVarFloat(g_ChargeSpeed), Timer_ChargeLoop, client, TIMER_REPEAT);
		
		
		// �T�E���h�Ƃ��G�t�F�N�g
		EmitSoundToAll(SOUND_CHARGER_ON, client, _, _, SND_CHANGEPITCH, 0.2, 80);
	
		AttachParticleBone(client, EFFECT_ABLE_SMOKE, "flag", 1.0);
		AttachParticleBone(client, EFFECT_ABLE_EMBERS, "flag", 1.0);
		AttachParticleBone(client, EFFECT_ABLE_FLASH, "flag", 1.0);
		AttachParticleBone(client, EFFECT_ABLE_DEBRIS, "flag", 1.0);
		
		g_LoopEffect[client][0] = AttachLoopParticleBone(client, EFFECT_CHARGER_SPARK1, "flag")
		g_LoopEffect[client][1] = AttachLoopParticleBone(client, EFFECT_CHARGER_SPARK2, "flag")
		//g_LoopEffect[client][2] = AttachLoopParticleBone(client, EFFECT_CHARGER_FIRE, "flag")
	}
}


/////////////////////////////////////////////////////////////////////
//
// ���[�o�[�h���C�����[�v
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DrainLoop(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		// �񕜑Ώۂ����Ȃ������[�o�[������Ȃ��B
		if( TF2_GetHealingTarget(client) <= 0 && !TF2_IsPlayerUber(client))
		{
			// ���݂̃��[�o�[�ʎ擾
			new nowUber = TF2_GetPlayerUberLevel(client);
			
			// 1�ȏ�̎�
			if( nowUber > 0 )
			{
				nowUber -= 1;
			}
			// ���[�o�[�ʐݒ�
			TF2_SetPlayerUberLevel(client, nowUber);
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ���[�v�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_ChargeLoop(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		// �񕜑Ώۂ�����B
		if(TF2_GetHealingTarget(client) > 0 && !TF2_IsPlayerUber(client))
		{
			// �񕜂͂��߂����T�E���h�ƃ��[�v�G�t�F�N�g�Đ�
			if(!g_NowHealing[client])
			{
				EmitSoundToAll(SOUND_CHARGER_ON, client, _, _, SND_CHANGEPITCH, 0.2, 80);
				
				AttachParticleBone(client, EFFECT_ABLE_DEBRIS, "flag", 1.0);
				AttachParticleBone(client, EFFECT_ABLE_FLASH, "flag", 1.0);
				AttachParticleBone(client, EFFECT_ABLE_SMOKE, "flag", 1.0);
				
				
				EmitSoundToAll(SOUND_CHARGER_LOOP, client, _, _, SND_CHANGEPITCH, 0.2, 120);
				//g_LoopEffect[client][1] = AttachLoopParticleBone(client, EFFECT_CHARGER_SPARK2, "flag")
				g_LoopEffect[client][2] = AttachLoopParticleBone(client, EFFECT_CHARGER_FIRE, "flag")
			}
			
			// ���݂̃��[�o�[�ʎ擾
			new nowCharge = TF2_GetPlayerUberLevel(client);
			
			// ���^���łȂ��Ƃ�
			if( nowCharge < 100 )
			{
				nowCharge += GetConVarInt(g_ChargeRate);

				if(nowCharge >= 100)
				{
					nowCharge = 100;
				}
				
				// ���[�o�[�ʐݒ�
				TF2_SetPlayerUberLevel(client, nowCharge)
				
				//AttachParticleBone(client, EFFECT_ABLE_SMOKE, "flag", 1.0);

		    		
			}
			
			AttachParticleBone(client, EFFECT_ABLE_EMBERS, "flag", 1.0);
			g_NowHealing[client] = true;
		}
		else
		{
			// �񕜒�����Ȃ���΃T�E���h�Ƃ���~
			if(g_NowHealing[client])
			{
				// �T�E���h��~
				StopSound(client, 0, SOUND_CHARGER_LOOP);
				//DeleteParticle(g_LoopEffect[client][1], 0.01);
				
				EmitSoundToAll(SOUND_CHARGER_STOP, client, _, _, SND_CHANGEPITCH, 0.5, 200);
				DeleteParticle(g_LoopEffect[client][2], 0.01);
				g_NowHealing[client] = false;
			}
			
		}
	
	}
	else
	{
		ClearTimer( g_ChargeLoopTimer[ client ] );
	}
}


/////////////////////////////////////////////////////////////////////
//
// �`���[�W���x
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_ChargeSpeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0�`5.0�܂�
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 5.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 5.0");
	}
}
/////////////////////////////////////////////////////////////////////
//
// �`���[�W���[�g
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_ChargeRate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0�`100�܂�
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 100");
	}
}
