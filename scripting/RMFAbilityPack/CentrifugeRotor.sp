/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.7
// �E1.3.1�ŃR���p�C��
// �E�d�l���ꕔ�ύX
// �Esm_rmf_centrifugerotor_movement_speed_mag��ǉ�
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
#define PL_NAME "Centrifuge Rotor"
#define PL_DESC "Centrifuge Rotor"
#define PL_VERSION "0.0.7"
#define PL_TRANSLATION "centrifugerotor.phrases"

#define SOUND_ROTER_ON "ui/projector_screen_down.wav"
#define SOUND_ROTER_OFF "ui/projector_screen_up.wav"
#define SOUND_ROTER_OFF2 "weapons/syringegun_reload_air2.wav"

#define EFFECT_ACTIVE	"ghost_flash"
#define EFFECT_DEACTIVE	"Explosions_UW_Debris001"



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
new Handle:g_ConVarGravityMag = INVALID_HANDLE;			// ConVar�Z���g���t���[�W���[�^�̏d��
new Handle:g_ConVarSpeedMag = INVALID_HANDLE;			// ConVar�Z���g���t���[�W���[�^�̈ړ��{�肤t
new bool:g_RoterState[MAXPLAYERS+1] = false;		// �Z���g���t���[�W���[�^�̏��

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
		CreateConVar("sm_rmf_tf_centrifugerotor", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_centrifugerotor","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// �w�r�[
		g_ConVarGravityMag = CreateConVar("sm_rmf_centrifugerotor_gravity",				"10.0",	"Generate gravity (0.0-10.0)");
		HookConVarChange(g_ConVarGravityMag, ConVarChange_Magnification);
		g_ConVarSpeedMag = CreateConVar("sm_rmf_centrifugerotor_movement_speed_mag",	"0.6",	"Movement speed magnification (0.0-10.0)");
		HookConVarChange(g_ConVarSpeedMag, ConVarChange_Magnification);
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_centrifugerotor_class", "6", "Ability class");
		
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_ACTIVE);
		PrePlayParticle(EFFECT_DEACTIVE);
		
		PrecacheSound(SOUND_ROTER_ON, true);
		PrecacheSound(SOUND_ROTER_OFF, true);
		PrecacheSound(SOUND_ROTER_OFF2, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �d�͂����ɖ߂��B
		SetEntityGravity(client,0.0);
		// �J���[���ɖ߂��B
		SetEntityRenderColor(client, 255, 255, 255, 255);
		// �d�͑��uOFF
		g_RoterState[client]=false;
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:percentage[16];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_CENTRIFUGEROTOR", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_1", client );
			GetPercentageString( GetConVarFloat( g_ConVarGravityMag ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_2", client, percentage );
			GetPercentageString( GetConVarFloat( g_ConVarSpeedMag ), percentage, sizeof( percentage ) )
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_CENTRIFUGEROTOR_ATTRIBUTE_3", client, percentage );
			
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
// �t���[�����Ƃ̓���
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �w�r�[
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy && g_AbilityUnlock[client] )
		{
			// �~�j�K���̂�
			if(TF2_CurrentWeaponEqual(client, "CTFMinigun"))
			{
				if( (g_RoterState[client] &&  CheckElapsedTime(client, 0.4)) || (!g_RoterState[client] && CheckElapsedTime(client, 0.1)))
				{
					// �A�^�b�N2
					if (GetClientButtons(client) & IN_ATTACK2 )
					{
						
						// �L�[�����������Ԃ�ۑ�
						SaveKeyTime(client);

						
						// �d�͕ύX
						if( GetEntityFlags(client) & FL_ONGROUND /* && GetEntityFlags(client) & FL_DUCKING */ )
						{
							ChangeRoterState(client, true);
						}
						else
						{
							ChangeRoterState(client, false);
						}
					}
					else
					{
						ChangeRoterState(client, false);
					}
					
				}
			}
			else
			{
				ChangeRoterState(client, false);
			}
		}	
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// �����_�[�J���[�ύX
//
/////////////////////////////////////////////////////////////////////
stock SetPlayerRenderColor(any:client, bool:enable)
{
	// �F��ύX
	if( enable )
	{
		new r,g,b;
		if( GetClientTeam( client ) == _:TFTeam_Red )
		{
			r = 120;
			g = 80;
			b = 80;
		}
		else
		{
			r = 100;
			g = 100;
			b = 220;
		}	
		
		// �v���C���[
		SetEntityRenderColor(client, r, g, b, 255);
		
		// ����
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
				SetEntityRenderColor(weaponIndex, r, g, b, 255);
			}
		}	
		
		// �X�q
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
	else
	{
		// �v���C���[
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		// ����
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
				SetEntityRenderColor(weaponIndex, 255, 255, 255, 255);
			}
		}		
		
		// �X�q
		new hat = -1;
		while ((hat = FindEntityByClassname(hat, "tf_wearable_item")) != -1)
		{
			new iOwner = GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				SetEntityRenderColor(hat, 255, 255, 255, 255);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �w�r�[�d�͔����ύX
//
/////////////////////////////////////////////////////////////////////
stock ChangeRoterState(any:client, bool:roterState)
{
	if( roterState )	//ON�ɂ���
	{
		// �ŏ������N����
		if( !g_RoterState[client] )	
		{
			SetPlayerRenderColor( client, true );	
			
			// �p�[�e�B�N��
			new Float:pos[3];
			GetClientAbsOrigin( client, pos );
			pos[2] += 30.0;
			// �p�[�e�B�N��
			//AttachParticleBone(client, EFFECT_ACTIVE, "head", 1.0, pos);
  			TE_Particle( EFFECT_ACTIVE, pos, _, _,client);
			new maxclients = GetMaxClients();
			for ( new i = 1; i <= maxclients; i++ )
			{
				if( IsClientInGame( i ) && i != client && !IsFakeClient( i ) )
				{
					TE_SendToClient( i );
				}
			}
			
			// �N����
			EmitSoundToAll(SOUND_ROTER_ON, client, _, _, SND_CHANGEPITCH, 1.00, 45);
			
			// �d��
			SetEntityGravity( client, GetConVarFloat( g_ConVarGravityMag ) );

			// ���x
			TF2_SetPlayerSpeed( client, TF2_GetPlayerClassSpeed( client ) * GetConVarFloat( g_ConVarSpeedMag ) );
			
			// ON
			g_RoterState[client] = true;
			
		}
		else
		{
			// �d��
			SetEntityGravity( client, GetConVarFloat( g_ConVarGravityMag ) );

			// ���x
			TF2_SetPlayerSpeed( client, TF2_GetPlayerClassSpeed( client ) * GetConVarFloat( g_ConVarSpeedMag ) );
			
		}
	}
	else		//OFF�ɂ���
	{
		// ���ʐ؂ꂽ�Ƃ������N����
		if( g_RoterState[client] )	
		{
			// �N����
			EmitSoundToAll(SOUND_ROTER_OFF, client, _, _, SND_CHANGEPITCH, 0.50, 40);
			EmitSoundToAll(SOUND_ROTER_OFF2, client, _, _, SND_CHANGEPITCH, 1.00, 25);
			
			// �p�[�e�B�N��
			new Float:pos[3];
			GetClientAbsOrigin( client, pos );
			pos[2] += 30.0;
			// �p�[�e�B�N��
			//AttachParticleBone(client, EFFECT_ACTIVE, "head", 1.0, pos);
  			TE_Particle( EFFECT_ACTIVE, pos, _, _,client);
			new maxclients = GetMaxClients();
			for ( new i = 1; i <= maxclients; i++ )
			{
				if( IsClientInGame( i ) && i != client && !IsFakeClient( i ) )
				{
					TE_SendToClient( i );
				}
			}
			// �p�[�e�B�N��
			ShowParticleEntity(client, EFFECT_DEACTIVE, 1.0);

			// �F�߂�
			//SetEntityRenderColor(client, 255, 255, 255, 255);
			
			SetPlayerRenderColor( client, false );	
			
			// �d��
			SetEntityGravity(client,0.0);
			
			// OFF
			g_RoterState[client] = false;
			
			// ���x�߂�
			TF2_SetPlayerDefaultSpeed( client );
		}
	}
	
}


/////////////////////////////////////////////////////////////////////
//
// �Z���g���t���[�W���[�^�[�̏d��
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_RoterGravity(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0�`20.0�܂�
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 20.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 20.0");
	}
}



