/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.6
// �E�G�t�F�N�g�Ȃǂ�ǉ�
// �E1.3.1�ŃR���p�C��
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
#define PL_NAME "Sticky Flash"
#define PL_DESC "Sticky Flash"
#define PL_VERSION "0.0.6"
#define PL_TRANSLATION "stickyflash.phrases"

#define SOUND_BOMB_BANG "player/medic_charged_death.wav"
#define SOUND_BOMB_BANG2 "player/pl_impact_airblast2.wav"
#define SOUND_BOMB_SIGNAL "weapons/stickybomblauncher_det.wav"

#define EFFECT_EXPLODE_SMOKE "Explosions_MA_Smoke_1"
#define EFFECT_EXPLODE_DEBRIS "Explosions_MA_Debris001"
#define EFFECT_EXPLODE_FLASH "teleported_flash"
#define EFFECT_PUSE_RED "stickybomb_pulse_red"
#define EFFECT_PUSE_BLU "stickybomb_pulse_blue"

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
new Handle:g_BlindTime = INVALID_HANDLE;						// ConVar�ڂ�ῂގ��ԃx�[�X
new Handle:g_BlindTimeNormalAdd = INVALID_HANDLE;				// ConVar�ڂ�ῂގ��Ԓǉ�
new Handle:g_BlindTimeCriticalAdd = INVALID_HANDLE;				// ConVar�N���e�B�J�����̖ڂ�ῂގ���

new Handle:g_TauntTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �����`�F�b�N�^�C�}�[
new Handle:g_FlashTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �t���b�V���I���^�C�}�[
new Handle:g_SoundTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �T�E���h�����^�C�}�[

new g_FlashPower[MAXPLAYERS+1] = 0;		// �t���b�V���p���[

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
		CreateConVar("sm_rmf_tf_stickyflash", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_stickyflash","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_BlindTime				= CreateConVar("sm_rmf_stickyflash_base_blindtime",		"2.0","Base blind time (0.0-120.0)");
		g_BlindTimeNormalAdd	= CreateConVar("sm_rmf_stickyflash_blindtime_add",		"2.0","Add blind time (0.0-120.0)");
		g_BlindTimeCriticalAdd	= CreateConVar("sm_rmf_stickyflash_blindtime_add_crits","4.0","Add blind time critical(0.0-120.0)");
		HookConVarChange(g_BlindTime,				ConVarChange_Time);
		HookConVarChange(g_BlindTimeNormalAdd,		ConVarChange_Time);
		HookConVarChange(g_BlindTimeCriticalAdd,	ConVarChange_Time);

		// �����R�}���h�Q�b�g
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_stickyflash_class", "4", "Ability class");
		
	}
	
	// �}�b�v�J�n
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_EXPLODE_SMOKE);
		PrePlayParticle(EFFECT_EXPLODE_DEBRIS);
		PrePlayParticle(EFFECT_EXPLODE_FLASH);
		
		PrecacheSound(SOUND_BOMB_BANG, true);
		PrecacheSound(SOUND_BOMB_BANG2, true);
		PrecacheSound(SOUND_BOMB_SIGNAL, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		ClearTimer(g_TauntTimer[client]);
		ClearTimer(g_FlashTimer[client]);
		ClearTimer(g_SoundTimer[client]);
		
		g_FlashPower[client] = 0;
		
		ScreenFade(client, 255, 255, 255, 0, 0, 0);

		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_DemoMan)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_STICKYFLASH", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_STICKYFLASH_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_STICKYFLASH_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_STICKYFLASH_ATTRIBUTE_2", client );
			
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
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
		if( !TF2_IsPlayerTaunt(client) && GetEntityFlags(client) & FL_ONGROUND )
		{
			StickyFlash(client);
		}
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// ����
//
/////////////////////////////////////////////////////////////////////
public StickyFlash(any:client)
{
	// �O���l�[�h�����`���[�̂�
	if(TF2_CurrentWeaponEqual(client, "CTFGrenadeLauncher"))
	{
		ClearTimer(g_TauntTimer[client]);
		g_TauntTimer[client] = CreateTimer(2.0, Timer_TauntEnd, client);

		ClearTimer(g_SoundTimer[client]);
		g_SoundTimer[client] = CreateTimer(1.5, Timer_Sound, client);
	}	
}
/////////////////////////////////////////////////////////////////////
//
// �T�E���h�I���^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_Sound(Handle:timer, any:client)
{
	g_SoundTimer[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if( TF2_IsPlayerTaunt(client) )
		{
			// �T����Ă���S�����擾
			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_projectile_pipe_remote")) != -1)
			{
				// �S���̃I�[�i�[
				new iOwner = GetEntDataEnt2(ent, FindSendPropInfo("CTFGrenadePipebombProjectile", "m_hThrower"));
				if(iOwner == client)
				{
					if(IsValidEntity(ent))
					{
						if( GetClientTeam(client) == _:TFTeam_Red )
						{
							ShowParticleEntity(ent, EFFECT_PUSE_RED, 0.5);
							
						}
						else
						{
							ShowParticleEntity(ent, EFFECT_PUSE_BLU, 0.5);
						}
						EmitSoundToAll(SOUND_BOMB_SIGNAL, ent, _, _, SND_CHANGEPITCH, 1.0, 80);
					}		
				}
			}		
		
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
		if( TF2_IsPlayerTaunt(client) )
		{
			// �t���b�V������
			SpawnFlash(client);
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �t���b�V������
//
/////////////////////////////////////////////////////////////////////
stock SpawnFlash(client)
{
	// �S���{��
	new ent = -1;
	new count = 0;
	new bomb[14];

	// �Ƃ肠�����N���A
	for( new i = 0; i < 14; i++)
	{
		bomb[i] = -1;
	}
	
	// �T����Ă���S�����擾
	while ((ent = FindEntityByClassname(ent, "tf_projectile_pipe_remote")) != -1)
	{
		// �S���̃I�[�i�[
		new iOwner = GetEntDataEnt2(ent, FindSendPropInfo("CTFGrenadePipebombProjectile", "m_hThrower"));
		if(iOwner == client)
		{
			if(IsValidEntity(ent))
			{
				bomb[count] = ent;
				count++;
			}		
		}
	}
	
	new Float:fBombPos[3];
	new Float:fVictimPos[3];
	new Float:dist;
	new maxclients = GetMaxClients();

	// ��Q�`�F�b�N
	for (new victim = 1; victim <= maxclients; victim++)
	{
		if( IsClientInGame(victim) && IsPlayerAlive(victim) )
		{
			// ��炤�͓̂G�Ǝ���
			if( GetClientTeam(victim) != GetClientTeam(client) || victim == client )
			{
				new blindPower = 0;
				new Float:blindTime = GetConVarFloat(g_BlindTime);
				new Float:bonusTime = 0.0;

				// �T����Ă���S�����`�F�b�N
				for( new i = 0; i < 14; i++)
				{
					if(IsValidEntity(bomb[i]))
					{
						// �{���ʒu
						GetEntPropVector(bomb[i], Prop_Data, "m_vecOrigin", fBombPos);
						// ��Q�҈ʒu
						GetEntPropVector(victim, Prop_Data, "m_vecOrigin", fVictimPos);
						// �{���Ɣ�Q�҂̈ʒu
						dist = GetVectorDistanceMeter(fBombPos, fVictimPos);
						new Float:eyePos[3];		// ��Q�҂̎��_�ʒu
						// �ڂ̈ʒu�擾
						GetClientEyePosition(victim, eyePos); 

						if(CanSeeTarget(victim, eyePos, bomb[i], fBombPos, 10.0, true, false))
						{
							new Float:eyeAngles[3];		// ��Q�҂̎��_�p�x
							new Float:bombAngles[3];	// �S���ւ̕���
							new Float:diffYaw = 0.0;	// �����ƔS�������ւ̍�
							new power = 0;				// ���̃p���[
							
							// �ڐ����擾
							GetClientEyeAngles(victim, eyeAngles);
							// �S���ւ̊p�x
							SubtractVectors(eyePos, fBombPos, bombAngles);
							GetVectorAngles(bombAngles, bombAngles);
							diffYaw = (bombAngles[1] - 180.0) - eyeAngles[1];
							diffYaw = FloatAbs(diffYaw);
							
							// �S���ւ̌����ɂ���Ēጸ
							if(diffYaw < 45.0)
							{
								power = 255;
							}
							else if( diffYaw >= 45.0 && diffYaw < 90.0 )
							{
								power = 128;
							}
							else if( diffYaw >= 90.0 && diffYaw < 135.0 )
							{
								power = 64;
							}
							else
							{
								power = 32;
							}

							// �����ɂ���Ă��ጸ
							if(dist < 4.0)
							{
								power = RoundFloat(power * 1.0);
							}
							else if( dist >= 4.0 && dist < 6.0 )
							{
								power = RoundFloat(power * 1.0);
							}
							else if( dist >= 6.0 && dist < 8.0 )
							{
								power = RoundFloat(power * 0.4);
							}
							else
							{
								power = RoundFloat(power * 0.2);
							}

							// ���v�l
							blindPower += power;
							// ��������ő�l
							if(blindPower > 255)
							{
								blindPower = 255;
							}
							
							// ��������
							if(GetEntProp(bomb[i], Prop_Send, "m_bCritical") == 1)
							{
								bonusTime += GetConVarFloat(g_BlindTimeCriticalAdd) * (1 / dist);
							}				
							else
							{
								blindTime += GetConVarFloat(g_BlindTimeNormalAdd) * (1 / dist);
							}							
						}
					}
				}
				
				// �ŏI�I�Ȗ�ῂ�
				g_FlashPower[victim] = blindPower;
				// ���ʓK�p
				ScreenFade(victim, 255, 255, 255, g_FlashPower[victim], 1000000, IN);
				
				// ���A�^�C�}�[
				ClearTimer(g_FlashTimer[victim]);
				g_FlashTimer[victim] = CreateTimer(blindTime + bonusTime, Timer_FadeEnd, victim);
			}
		}
	}

	// �S������
	for( new i = 0; i < 14; i++)
	{
		if(IsValidEntity(bomb[i]))
		{
			SetEntPropVector(bomb[i], Prop_Send, "m_angRotation", NULL_VECTOR);
			ShowParticleEntity(bomb[i], EFFECT_EXPLODE_SMOKE, 0.5);
			ShowParticleEntity(bomb[i], EFFECT_EXPLODE_DEBRIS, 0.5);
			ShowParticleEntity(bomb[i], EFFECT_EXPLODE_FLASH, 0.5);

			EmitSoundToAll(SOUND_BOMB_BANG, bomb[i], _, _, SND_CHANGEPITCH, 1.0, 200);
			EmitSoundToAll(SOUND_BOMB_BANG2, bomb[i], _, _, SND_CHANGEPITCH, 1.0, 120);
			AcceptEntityInput(bomb[i], "Kill");
		}
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// �t�F�[�h�A�E�g
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FadeEnd(Handle:timer, any:client)
{
	g_FlashTimer[client] = INVALID_HANDLE;

	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		ScreenFade(client, 255, 255, 255, g_FlashPower[client], 0, IN);
	}
	g_FlashPower[client] = 0;
}


