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
#define PL_NAME "Curving Arrow"
#define PL_DESC "Curving Arrow"
#define PL_VERSION "0.0.5"
#define PL_TRANSLATION "curvingarrow.phrases"

#define SOUND_CURVARROW "weapons/fx/nearmiss/bulletltor09.wav"

#define EFFECT_CURARROW_RED "player_dripsred"
#define EFFECT_CURARROW_BLU "player_drips_blue"

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
new g_BowHold[MAXPLAYERS+1] = -1;					// �Ə����H
new g_Arrow[MAXPLAYERS+1] = -1;						// ���˂�����
new Float:g_ChargeBeginTime[MAXPLAYERS+1] = 0.0;	// �Ə��J�n����
new Float:g_ChargeTime[MAXPLAYERS+1] = 0.0;			// �`���[�W����
new Float:g_CurvDir[MAXPLAYERS+1][2];				// �J�[�u����



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
		CreateConVar("sm_rmf_tf_curvingarrow", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_curvingarrow","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		

		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_curvingarrow_class", "2", "Ability class");
	
	}
	
	// �}�b�v�J�n
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_CURARROW_RED);
		PrePlayParticle(EFFECT_CURARROW_BLU);

		PrecacheSound(SOUND_CURVARROW, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// ���x�߂�
		TF2_SetPlayerDefaultSpeed(client);
		
		// �|�����Ă�
		g_BowHold[client] = -1;
		
		// ��������Ȃ�
		g_Arrow[client] = -1;
		
		// �J�[�u�����N���A
		g_CurvDir[client][0] = 0.0;
		g_CurvDir[client][1] = 0.0;
		
		// �`���[�W���ԃN���A
		g_ChargeBeginTime[client] = 0.0;
		g_ChargeTime[client] = 0.0;
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];


			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_CURVINGARROW", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_CURVINGARROW_ATTRIBUTE_3", client );
			
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s\n%s", attribute1, attribute2, attribute3 );
			
		}

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
// �Q�[���t���[��
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �X�i�C�p�[
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper && g_AbilityUnlock[client])
		{
			// �n���c�}��
			if(TF2_CurrentWeaponEqual(client, "CTFCompoundBow"))
			{
				// �|���\���Ă���Ƃ��͓����Ȃ�
				if( CheckElapsedTime(client, 0.1) )
				{
					// �L�[�`�F�b�N���ԕۑ�
					SaveKeyTime(client);
					
					// �|�\���Ă��Ȃ���Α��x�߂�
					if(!(GetClientButtons(client) & IN_ATTACK && TF2_IsPlayerSlowed(client)))
					{
						// �f�t�H���g���x
						TF2_SetPlayerDefaultSpeed(client);
					}
					
					// �Ə���
					if(GetClientButtons(client) & IN_ATTACK && GetEntPropFloat(TF2_GetCurrentWeapon(client), Prop_Send, "m_flChargeBeginTime") != 0.0)
					{
						// �`���[�W�J�n���ԕۑ�
						if(g_BowHold[client] == -1)
						{
							g_ChargeBeginTime[client] = GetEntPropFloat(TF2_GetCurrentWeapon(client), Prop_Send, "m_flChargeBeginTime");
						}
						
						// �Ə����ɐݒ�
						g_BowHold[client] = 1;
						
						// �ړ����x���Ƃ�
						if(TF2_IsPlayerSlowed(client))
						{
							TF2_SetPlayerSpeed(client, 0.5);
						}
						
						// ��̃J�[�u�����ݒ�
						g_CurvDir[client][0] = 0.0; // Y
						g_CurvDir[client][1] = 0.0; // X
						if(GetClientButtons(client) & IN_MOVELEFT)
						{
							g_CurvDir[client][1] = 1.0;
						}
						if(GetClientButtons(client) & IN_MOVERIGHT)
						{
							g_CurvDir[client][1] = -1.0;
						}
						if(GetClientButtons(client) & IN_FORWARD)
						{
							g_CurvDir[client][0] = -1.0;
						}
						if(GetClientButtons(client) & IN_BACK)
						{
							g_CurvDir[client][0] = 1.0;
						}	
						
						
					}
					else
					{
						// �|���ˁ��J�[�u�����ݒ�ς݂�
						if(g_BowHold[client] == 1 && (g_CurvDir[client][0] != 0.0 || g_CurvDir[client][1] != 0.0))
						{
							// �`���[�W����
							g_ChargeTime[client] = GetGameTime() -g_ChargeBeginTime[client];
							
							// �������|������
							g_Arrow[client] = -1;
							new arrow = -1;
							while ((arrow = FindEntityByClassname(arrow, "tf_projectile_arrow")) != -1)
							{
								// ���˂����v���C���[�`�F�b�N
								new iOwner = GetEntPropEnt(arrow, Prop_Send, "m_hOwnerEntity");
								if(iOwner == client)
								{
									// ���ۑ�
									g_Arrow[client] = arrow;
									
									// �u�I�����ĉ�
									EmitSoundToAll(SOUND_CURVARROW, arrow, _, _, SND_CHANGEPITCH, 1.0, 40);
									
									// ��ɃG�t�F�N�g
									if(TFTeam:GetClientTeam(client) == TFTeam_Red)
									{
										AttachParticle(arrow, EFFECT_CURARROW_RED, 0.5);	
										
									}
									else
									{
										AttachParticle(arrow, EFFECT_CURARROW_BLU, 0.5);	
									}
								}
							}
					
						}
						
						// �|�\���ĂȂ�
						g_BowHold[client] = -1;
						// �f�t�H���g���x
						TF2_SetPlayerDefaultSpeed(client);
					}
					
					
				}
			}

			// ����Ȃ���
			if(g_Arrow[client] != -1 && IsValidEntity(g_Arrow[client]) )
			{
					
				new String:name[64];
				GetEntityNetClass(g_Arrow[client], name, sizeof(name));
				if(StrEqual(name, "CTFProjectile_Arrow") && GetEntityMoveType(g_Arrow[client]) == MOVETYPE_FLYGRAVITY)
				{
					new Float:arrowPos[3];	// ��̈ʒu
					new Float:arrowAng[3];	// ��̊p�x
					new Float:arrowVec[3];	// ��̕���
					new Float:arrowNewVec[3];	// ��̕���
					
					// ��̃f�[�^�ǂݍ���
					GetEntPropVector(g_Arrow[client], Prop_Data, "m_vecAbsOrigin", arrowPos);			// ��̈ʒu
					GetEntPropVector(g_Arrow[client], Prop_Data, "m_angRotation", arrowAng);			// ��̊p�x
					GetEntPropVector(g_Arrow[client], Prop_Data, "m_vecAbsVelocity", arrowVec);			// ��̕���
					
					// �Ȃ���p�x�̓`���[�W���Ԃɔ��
					arrowAng[0] += g_CurvDir[client][0] * 0.5 * g_ChargeTime[client];
					arrowAng[1] += g_CurvDir[client][1] * 0.5 * g_ChargeTime[client];
					
					// ��̐i�ޕ����擾
					GetAngleVectors(arrowAng, arrowNewVec, NULL_VECTOR, NULL_VECTOR);
					
					// ��͂��񂾂�Ɨ�������
					ScaleVector(arrowNewVec, GetVectorLength(arrowVec));
					arrowNewVec[2] -= 0.9 * (1 / g_ChargeTime[client]);
					
					// �f�[�^�㏑��
					SetEntPropVector(g_Arrow[client], Prop_Data, "m_vecAbsVelocity", arrowNewVec);
					
					// ��̊p�x�K�p
					GetVectorAngles(arrowNewVec, arrowAng);
					SetEntPropVector(g_Arrow[client], Prop_Data, "m_angRotation", arrowAng);
				}
				else
				{
					// �Ȃ�������N���A
					g_CurvDir[client][0] = 0.0;
					g_CurvDir[client][1] = 0.0;
					
					// �`���[�W���ԃN���A
					g_ChargeTime[client] = 0.0;
					
					// ��N���A
					g_Arrow[client] = -1;
				}
				
			}
		
		}

	}

}


