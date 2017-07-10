/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.5
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
#define PL_NAME "Reverse Engineer"
#define PL_DESC "Reverse Engineer"
#define PL_VERSION "0.0.5"
#define PL_TRANSLATION "reverseengineer.phrases"

#define SOUND_TELEPORTER_SEND "weapons/teleporter_send.wav"
#define SOUND_TELEPORTER_RECEIVE "weapons/teleporter_receive.wav"

#define EFFECT_TELEPORT_FLASH "teleported_flash"
#define EFFECT_TELEPORT_RED "teleported_red"
#define EFFECT_TELEPORT_BLU "teleported_blue"

#define EFFECT_PLAYER_GLOW_RED "player_glowred"
#define EFFECT_PLAYER_GLOW_BLU "player_glowblue"

#define EFFECT_TELEPORTIN_RED "teleportedin_red"
#define EFFECT_PLAYER_RECENT_RED "player_recent_teleport_red"
#define EFFECT_PLAYER_DRIPS_RED "player_dripsred"
#define EFFECT_PLAYER_SPARKLES_RED "player_sparkles_red"

#define EFFECT_TELEPORTIN_BLU "teleportedin_blue"
#define EFFECT_PLAYER_RECENT_BLU "player_recent_teleport_blue"
#define EFFECT_PLAYER_DRIPS_BLU "player_drips_blue"
#define EFFECT_PLAYER_SPARKLES_BLU "player_sparkles_blue"




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
new Handle:g_ChargeTimeMag = INVALID_HANDLE;					// ConVar�`���[�W����

new Handle:g_SetChargeTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// �`���[�W���ԕύX�^�C�}�[
new Handle:g_FlashEffectTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// �t���b�V���G�t�F�N�g�^�C�}�[
new Handle:g_PlayerEffectTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// ���q�G�t�F�N�g�^�C�}�[

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
		CreateConVar("sm_rmf_tf_reverseengineer", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_reverseengineer","1","Reverse Engineer Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		g_ChargeTimeMag = CreateConVar("sm_rmf_reverseengineer_chargetime_mag","2.0","Charge time magnification (0.0-10.0)");
		HookConVarChange(g_ChargeTimeMag, ConVarChange_Magnification);

		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_reverseengineer_class", "9", "Ability class");
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheSound(SOUND_TELEPORTER_SEND, true);
		PrecacheSound(SOUND_TELEPORTER_RECEIVE, true);
		PrePlayParticle(EFFECT_TELEPORT_FLASH);
		
		PrePlayParticle(EFFECT_TELEPORT_RED);
		PrePlayParticle(EFFECT_TELEPORTIN_RED);
		PrePlayParticle(EFFECT_PLAYER_RECENT_RED);
		PrePlayParticle(EFFECT_PLAYER_GLOW_RED);
		PrePlayParticle(EFFECT_PLAYER_DRIPS_RED);
		PrePlayParticle(EFFECT_PLAYER_SPARKLES_RED);
		
		PrePlayParticle(EFFECT_TELEPORT_BLU);
		PrePlayParticle(EFFECT_TELEPORTIN_BLU);
		PrePlayParticle(EFFECT_PLAYER_RECENT_BLU);
		PrePlayParticle(EFFECT_PLAYER_GLOW_BLU);
		PrePlayParticle(EFFECT_PLAYER_DRIPS_BLU);
		PrePlayParticle(EFFECT_PLAYER_SPARKLES_BLU);
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

	// �v���C���[���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �^�C�}�[�N���A
		ClearTimer(g_SetChargeTimer[client]);
		ClearTimer(g_PlayerEffectTimer[client]);

		// �ꉞ�G�t�F�N�g����
		TF2_RemoveCond( client, TF2_COND_GLOWING );
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:percentage[16];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_REVERSEENGINEER", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_REVERSEENGINEER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_REVERSEENGINEER_ATTRIBUTE_1", client );
			GetPercentageString( GetConVarFloat( g_ChargeTimeMag ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_REVERSEENGINEER_ATTRIBUTE_2", client, percentage );
			
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
// �����`�F�b�N
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �G���W�j�A�̂�
		if(TF2_GetPlayerClass(client) == TFClass_Engineer && g_AbilityUnlock[client])
		{
			// �L�[�`�F�b�N
			if( CheckElapsedTime(client, 2.0) )
			{
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// �L�[�����������Ԃ�ۑ�
					SaveKeyTime(client);
					
					if(!TF2_CurrentWeaponEqual(client, "CTFWeaponBuilder"))
					{
						ReverseTeleport(client);
					}

				}

			}			
		
		}
	}
}


/////////////////////////////////////////////////////////////////////
//
// �t�e���|
//
/////////////////////////////////////////////////////////////////////
public ReverseTeleport(client)
{
	new groundEntity = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");
	
	// �����Ƀe���|�[�^�[�o���H
	if( groundEntity != -1 )
	{
		new String:className[64];
		GetEdictClassname(groundEntity, className, sizeof(className));
		
		if(StrEqual(className, "obj_teleporter_exit"))
		{
			// �ғ����̂�
			if(GetEntProp(groundEntity, Prop_Send, "m_iState") == 2)
			{
				
				// �������T��
				new entrance = -1;
				while ((entrance = FindEntityByClassname(entrance, "obj_teleporter_entrance")) != -1)
				{
					// ������`�F�b�N
					new iOwner = GetEntPropEnt(entrance, Prop_Send, "m_hBuilder");
					if(iOwner == client)
					{
						// �ғ����̂�
						if(GetEntProp(entrance, Prop_Send, "m_iState") == 2)
						{
								//GetEntProp(entrance, Prop_Send, "m_iState", 1);
							// ���Z�b�g
							SetEntProp(entrance, Prop_Send, "m_iState", 3);
							SetEntProp(groundEntity, Prop_Send, "m_iState", 3);
							
							// �^�C�}�[�����ݒ�
							ClearTimer(g_SetChargeTimer[client]);	
							g_SetChargeTimer[client] = CreateTimer(0.5, Timer_SetCharge, client);
							
							// �t���b�V���G�t�F�N�g�^�C�}�[�ݒ�
							ClearTimer(g_FlashEffectTimer[client]);	
							g_FlashEffectTimer[client] = CreateTimer(0.8, Timer_FlashEffect, client);
							
							// �v���C���[�G�t�F�N�g�^�C�}�[�ݒ�
							TF2_RemoveCond( client, TF2_COND_GLOWING );
							TF2_AddCond( client, TF2_COND_GLOWING );
							ClearTimer(g_PlayerEffectTimer[client]);	
							g_PlayerEffectTimer[client] = CreateTimer(10.0, Timer_PlayerEffect, client);

							// ������փe���|�[�g
							new Float:entrancePos[3];
							GetEntPropVector(entrance, Prop_Data, "m_vecAbsOrigin", entrancePos);
							entrancePos[2] += 15.0;
							new Float:entranceAng[3];
							GetEntPropVector(entrance, Prop_Data, "m_angRotation", entranceAng);
							
							TeleportEntity(client, entrancePos, entranceAng, NULL_VECTOR);
							
							// �G�t�F�N�g�ƃT�E���h
							EmitSoundToAll(SOUND_TELEPORTER_SEND, groundEntity, _, _, SND_CHANGEPITCH, 1.0, 90);
							EmitSoundToAll(SOUND_TELEPORTER_RECEIVE, entrance, _, _, SND_CHANGEPITCH, 1.0, 90);
							
							AttachParticle(groundEntity, EFFECT_TELEPORT_FLASH, 0.1);	
							//AttachParticle(entrance, "teleportedin_red", 1.0);	
							//AttachParticle(groundEntity, "teleported_red", 1.0);	
							
							ScreenFade(client, 255, 255, 255, 128, 300, IN);
							
							if(TFTeam:GetClientTeam(client) == TFTeam_Red)
							{
								AttachParticle(groundEntity, EFFECT_TELEPORT_RED, 1.0);	
								AttachParticle(entrance, EFFECT_TELEPORTIN_RED, 1.0);	
							//	AttachParticle(client, EFFECT_PLAYER_GLOW_RED, 10.0);	
							}
							else
							{
								AttachParticle(groundEntity, EFFECT_TELEPORT_BLU, 1.0);	
								AttachParticle(entrance, EFFECT_TELEPORTIN_BLU, 1.0);	
							//	AttachParticle(client, EFFECT_PLAYER_GLOW_BLU, 10.0);	
							}
							
							// �o���ɏ���Ă�����
							new maxclients = GetMaxClients();
							for (new victim = 1; victim <= maxclients; victim++)
							{
								if(IsClientInGame(victim) && IsPlayerAlive(victim))
								{
									groundEntity = GetEntPropEnt(victim, Prop_Data, "m_hGroundEntity");
									
									// �����Ƀe���|�[�^�[�o���H
									if( groundEntity != -1 )
									{
										GetEdictClassname(groundEntity, className, sizeof(className));
										
										if(StrEqual(className, "obj_teleporter_entrance"))
										{
											FakeClientCommand(victim, "explode");
										}
									}
								}
							}
							
							//AttachParticleBone(client, EFFECT_PLAYER_DRIPS_RED, "partyhat", 10.0);	
							
	//	PrePlayParticle(EFFECT_PLAYER_RECENT_RED);
		//PrePlayParticle(EFFECT_PLAYER_GLOWED);
		//PrePlayParticle(EFFECT_PLAYER_DRIPS_RED);

						}
					}
				}
			}
		}
		
	}

}

/////////////////////////////////////////////////////////////////////
//
// �e���|�[�^�[�`���[�W�ݒ�
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_SetCharge(Handle:timer, any:client)
{
	g_SetChargeTimer[client] = INVALID_HANDLE;
	
	// �������T��
	new entrance = -1;
	while ((entrance = FindEntityByClassname(entrance, "obj_teleporter_entrance")) != -1)
	{
		// ������`�F�b�N
		new iOwner = GetEntPropEnt(entrance, Prop_Send, "m_hBuilder");
		if(iOwner == client)
		{
			// ���������Ԑݒ�
			switch(GetEntProp(entrance, Prop_Send, "m_iUpgradeLevel"))
			{
			case 1:
				SetEntPropFloat(entrance, Prop_Send, "m_flRechargeTime", GetGameTime() + (10.0 * 1.5)-0.5);
			case 2:
				SetEntPropFloat(entrance, Prop_Send, "m_flRechargeTime", GetGameTime() + (5.0 * 1.5)-0.5);
			case 3:
				SetEntPropFloat(entrance, Prop_Send, "m_flRechargeTime", GetGameTime() + (3.0 * 1.5)-0.5);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �G�t�F�N�g�ݒ�
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FlashEffect(Handle:timer, any:client)
{
	g_FlashEffectTimer[client] = INVALID_HANDLE;
	
	// �o����T��
	new teleporter_exit = -1;
	while ((teleporter_exit = FindEntityByClassname(teleporter_exit, "obj_teleporter_exit")) != -1)
	{
		// ������`�F�b�N
		new iOwner = GetEntPropEnt(teleporter_exit, Prop_Send, "m_hBuilder");
		if(iOwner == client)
		{
			AttachParticle(teleporter_exit, EFFECT_TELEPORT_FLASH, 0.1);	
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �v���C���[�G�t�F�N�g�I��
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_PlayerEffect(Handle:timer, any:client)
{
	g_PlayerEffectTimer[client] = INVALID_HANDLE;

	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		TF2_RemoveCond( client, TF2_COND_GLOWING );
	}

}
