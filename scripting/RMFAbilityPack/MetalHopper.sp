/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.6
// �ꕔ�d�l��ύX
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
#define PL_NAME "Metal Hopper"
#define PL_DESC "Metal Hopper"
#define PL_VERSION "0.0.6"
#define PL_TRANSLATION "metalhopper.phrases"

#define SOUND_HOP_VOICE "vo/engineer_battlecry06.wav"

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
new Handle:g_BaseDamage = INVALID_HANDLE;					// ConVar�x�[�X�_���[�W
new Handle:g_BasePower = INVALID_HANDLE;					// ConVar�x�[�X�p���[
//new Handle:g_IsEnemyDamage = INVALID_HANDLE;				// ConVar�G�Ƀ_���[�W�H
//new Handle:g_EnemyBaseDamage = INVALID_HANDLE;				// ConVar�x�[�X�_���[�W(�G)
//new Handle:g_EnemyBasePower = INVALID_HANDLE;				// ConVar�x�[�X�p���[(�G)
//new Handle:g_EnemyDamageRadius = INVALID_HANDLE;			// ConVar�_���[�W���a
//new g_AttackerDispenser[MAXPLAYERS+1]	= -1;				// ���j���󂯂��f�B�X�y���T�[�̎�����

new bool:g_Hop[MAXPLAYERS+1] = false;						// �z�b�v�����H

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
		CreateConVar("sm_rmf_tf_metalhopper", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_metalhopper","1","Metal Hopper Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		// �_���[�W�ƃp���[
		g_BaseDamage		= CreateConVar("sm_rmf_metalhopper_base_damage",		"35",	"Base damage(0-1000)");
		g_BasePower			= CreateConVar("sm_rmf_metalhopper_base_power",			"300.0","Base power(10.0-5000.0)");
//		g_IsEnemyDamage		= CreateConVar("sm_rmf_metalhopper_allow_damage",		"1",	"Damage to enemy Enable/Disable (0 = disabled | 1 = enabled)");
//		g_EnemyBaseDamage	= CreateConVar("sm_rmf_metalhopper_enemy_base_damage",	"20",	"Base damage to enemy(0-100)");
//		g_EnemyBasePower	= CreateConVar("sm_rmf_metalhopper_enemy_base_power",	"100.0","Base power to enemy(10.0-5000.0)");
//		g_EnemyDamageRadius	= CreateConVar("sm_rmf_metalhopper_enemy_damage_radius","2.0",	"Damage radius to enemy(0.0-100.0)");
		HookConVarChange(g_BaseDamage,			ConVarChange_Damage);
		HookConVarChange(g_BasePower,			ConVarChange_BasePower);
//		HookConVarChange(g_IsEnemyDamage,		ConVarChange_Bool);
//		HookConVarChange(g_EnemyBaseDamage, 	ConVarChange_Damage);
//		HookConVarChange(g_EnemyBasePower,		ConVarChange_BasePower);
//		HookConVarChange(g_EnemyDamageRadius,	ConVarChange_Radiuss);
		
		// �f�X�g���C�R�}���h�Q�b�g
		RegConsoleCmd("destroy", Command_Destroy, "Destroy");
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_metalhopper_class", "9", "Ability class");
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheSound(SOUND_HOP_VOICE, true);
	}

	// �v���C���[���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
//		g_AttackerDispenser[ client ] = -1;
		g_Hop[ client ] = false;
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_METALHOPPER", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_METALHOPPER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_METALHOPPER_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_METALHOPPER_ATTRIBUTE_2", client );
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
			
//			if( GetConVarBool( g_IsEnemyDamage ) )
//			{
//				Format(g_PlayerHintText[client][2], HintTextMaxSize , "%T", "DESCRIPTION_2_METALHOPPER", client);
//
//			}
		}
	}
	
	// �v���C���[���S
//	if(StrEqual(name, EVENT_PLAYER_DEATH))
//	{
//		new attacker		= GetClientOfUserId( GetEventInt( event, "attacker" ) );
//		new assister		= GetClientOfUserId( GetEventInt( event, "assister" ) );
//		new stun_flags		= GetEventInt( event, "stun_flags" );
//		new death_flags		= GetEventInt( event, "death_flags" );
//		new weaponid		= GetEventInt( event, "weaponid" );
//		new victim_entindex	= GetEventInt( event, "victim_entindex" );
//		new damagebits		= GetEventInt( event, "damagebits" );
//		new customkill		= GetEventInt( event, "customkill" );
//		new String:weapon[64];
//		GetEventString( event, "weapon", weapon, sizeof( weapon ) );
//
//		// �C�x���g��������
//		if( attacker == client && g_AttackerDispenser[ client ] != -1 )
//		{
//			new Handle:newEvent = CreateEvent( "player_death" );
//			if( newEvent != INVALID_HANDLE )
//			{
//				attacker = g_AttackerDispenser[ client ];
//				
//				SetEventInt( newEvent, "userid", GetClientUserId(client) );
//				SetEventInt( newEvent, "attacker", GetClientUserId(attacker) );
//				if( assister > 0)
//					SetEventInt( newEvent, "assister", GetClientUserId(assister) );				
//				SetEventInt( newEvent, "stun_flags", stun_flags );				
//				SetEventInt( newEvent, "death_flags", 128 );				
//				SetEventInt( newEvent, "weaponid", -1 );				
//				SetEventInt( newEvent, "victim_entindex", client );				
//				SetEventInt( newEvent, "damagebits", 2359360 );				
//				SetEventInt( newEvent, "customkill", 0 );				
//				SetEventString( newEvent, "weapon", "dispenser_explosion" );
//				FireEvent( newEvent );
//				return Plugin_Handled;
//			}
//		}
//	}
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
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		// �G���W�j�A
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer && g_AbilityUnlock[client] )
		{
			// �L�[�`�F�b�N
			if( CheckElapsedTime(client, 1.0) )
			{
				// �U���{�^��2
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// �L�[�����������Ԃ�ۑ�
					SaveKeyTime(client);
					
					MetalHop(client);
					g_Hop[ client ] = true;
				}
			}			
		}	
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// �f�X�g���C�R�}���h�擾
//
/////////////////////////////////////////////////////////////////////
public Action:Command_Destroy(client, args)
{
	// MOD��ON�̎�����
	if( !g_IsRunning || client <= 0 )
		return Plugin_Continue;
	
	if(TF2_GetPlayerClass(client) == TFClass_Engineer && g_AbilityUnlock[client])
	{
		new String:arg[128];
		if(args == 1)
		{
			// ��ڂ̈����Q�b�g
			GetCmdArg(1, arg, sizeof(arg));
			
			new objType = StringToInt(arg);
			
			if( objType == 0 && g_Hop[ client ] )
			{
				// �f�B�X�y���T�[�W�����v
				//MetalHop(client);
				
				g_Hop[ client ] = false;
			}
		}
	}	

	return Plugin_Continue;
}


/////////////////////////////////////////////////////////////////////
//
// �f�B�X�y���T�[�W�����v
//
/////////////////////////////////////////////////////////////////////
public MetalHop(client)
{
	// �f�B�X�y���T�[����
	new obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_dispenser")) != -1)
	{
		// ������`�F�b�N
		new iOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if(iOwner == client)
		{
			new Float:fObjPos[3];			// �I�u�W�F�N�g�̈ʒu
			new Float:fPlayerPos[3];		// �v���C���[�̈ʒu
			new Float:fKnockVelocity[3];	// �����̔���
			new Float:Power = GetConVarFloat(g_BasePower) * -1;		// �����̃x�[�X�l
			new Float:distance;				// �Z���g���[�ƃv���C���[�̋���
			
			// �v���C���[�ʒu�擾
			GetClientAbsOrigin(client, fPlayerPos);
			// �f�B�X�y���T�[�̈ʒu�擾
			GetEntPropVector(obj, Prop_Data, "m_vecOrigin", fObjPos);
			// �v���C���[�ƃf�B�X�y���T�[�̋����Z�o
			distance = GetVectorDistanceMeter( fPlayerPos, fObjPos );
			
			// ���͂Ƀ_���[�W
//			if( GetConVarBool( g_IsEnemyDamage ) )
//			{
//				RadiusDamage(obj);
//			}

			// 4m�ȓ��Ńf�B�X�y���T�[��荂���ʒu�ɋ���ꍇ�̂�
			if( distance < 4.0 && fPlayerPos[2] > fObjPos[2])
			{
				// �����̕����擾
				SubtractVectors(fObjPos, fPlayerPos, fKnockVelocity);
				NormalizeVector(fKnockVelocity, fKnockVelocity); 
				
				// �����ɂ�錸��
				//Power *= (1.0 / distance);
				
				// �f�B�X�y���T�[�̃��^���c�ʂƃ��x���擾
				new metal = GetEntProp(obj, Prop_Send, "m_iAmmoMetal");
				new level = GetEntProp(obj, Prop_Send, "m_iUpgradeLevel");
				
				// �v���C���[�̃x�N�g���������擾
				new Float:fVelocity[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
				
				
				// ���x���ƃ��^���c�ʂɂ��ω�
				Power -= (level * 125);
				Power -= (metal / 2);
				
				// �������Z�o
				ScaleVector(fKnockVelocity, Power); 
				AddVectors(fVelocity, fKnockVelocity, fVelocity);

				// �v���C���[�ւ̔�����ݒ�
				SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
			
				// �_���[�W�Z�o
				new dmg = RoundFloat((GetConVarInt(g_BaseDamage) + (metal / 20)) * (1.0 / distance) + (level * 20));
				
				// ���G����Ȃ�
				if( !TF2_IsPlayerInvuln(client) )
				{
					if( GetClientHealth(client) - dmg <= 0 )
					{
						// �_���[�W���w���X���������甚��
						FakeClientCommand(client, "explode");
					}
					else
					{
						// �_���[�W
						SetEntityHealth(client, GetClientHealth(client) - dmg);
						// ���łɃ{�C�X
						EmitSoundToAll(SOUND_HOP_VOICE, client, _, _, SND_CHANGEPITCH, 0.8, 100);
					}
				}
				
				//AttachParticle(client, "warp_version", 1.0);
				
				FakeClientCommand( client, "Destroy 0" );
			}
		}
	
	}
}


/////////////////////////////////////////////////////////////////////
//
// �l�̂ւ̃_���[�W
//
/////////////////////////////////////////////////////////////////////
/*
stock RadiusDamage(any:obj)
{
	new Float:fVictimPos[3];
	new maxclients = GetMaxClients();
	new Float:fObjPos[3];			// �I�u�W�F�N�g�̈ʒu
	new Float:fKnockVelocity[3];	// �����̔���
	new iOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	
	// ��Q�`�F�b�N
	for (new victim = 1; victim <= maxclients; victim++)
	{
		if( IsClientInGame(victim) && IsPlayerAlive(victim) )
		{
			if( GetClientTeam(victim) != GetClientTeam(iOwner) && victim != iOwner )
			{
				new Float:Power = GetConVarFloat(g_EnemyBasePower) * -1;		// �����̃x�[�X�l
				new Float:distance;				// �Z���g���[�ƃv���C���[�̋���
				
				// �v���C���[�ʒu�擾
				GetClientAbsOrigin(victim, fVictimPos);
				// �f�B�X�y���T�[�̈ʒu�擾
				GetEntPropVector(obj, Prop_Data, "m_vecOrigin", fObjPos);
				// �v���C���[�ƃf�B�X�y���T�[�̋����Z�o
				distance = GetVectorDistanceMeter( fVictimPos, fObjPos );

				// 5m�ȓ�
				if( CanSeeTarget(victim, fVictimPos, iOwner, fObjPos, GetConVarFloat(g_EnemyDamageRadius), true, true) )
				{
//					PrintToChat(iOwner, "fObjPos = %f %f %f", fObjPos[0], fObjPos[1], fObjPos[2]);
//					PrintToChat(iOwner, "fVictimPos = %f %f %f", fVictimPos[0], fVictimPos[1], fVictimPos[2]);
					// �����̕����擾
					SubtractVectors(fObjPos, fVictimPos, fKnockVelocity);
					NormalizeVector(fKnockVelocity, fKnockVelocity); 
					
					// �����ɂ�錸��
					//Power *= (1.0 / distance);
					
					// �f�B�X�y���T�[�̃��^���c�ʂƃ��x���擾
					new metal = GetEntProp(obj, Prop_Send, "m_iAmmoMetal");
					new level = GetEntProp(obj, Prop_Send, "m_iUpgradeLevel");
					
					// �v���C���[�̃x�N�g���������擾
					new Float:fVelocity[3];
					GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
					fVelocity[2] = 280.0;
					
					// ���x���ƃ��^���c�ʂɂ��ω�
					Power -= (level * 125);
					Power -= (metal / 2);
					
					// �������Z�o
					ScaleVector(fKnockVelocity, Power * 0.8); 
					AddVectors(fVelocity, fKnockVelocity, fVelocity);
					
					// �v���C���[�ւ̔�����ݒ�
					SetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
				
					// �_���[�W�Z�o
					new dmg = RoundFloat((GetConVarInt(g_EnemyBaseDamage) + (metal / 10)) * (1.0 / distance) + (level * 35) );
					
					// ���G����Ȃ�
					if( !TF2_IsPlayerInvuln(victim) && !TF2_IsPlayerBlur(victim) )
					{
						if( GetClientHealth(victim) - dmg <= 0 )
						{
							// �_���[�W���w���X���������甚��
							g_AttackerDispenser[ victim ] = iOwner;
							FakeClientCommand(victim, "explode");
						}
						else
						{
							// �_���[�W
							SetEntityHealth(victim, GetClientHealth(victim) - dmg);
						}
					}
					
					//AttachParticle(victim, "warp_version", 1.0);
				
				}
					
			}
		}
	}	
	
}
*/
/////////////////////////////////////////////////////////////////////
//
// �x�[�X�p���[
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_BasePower(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 10.0�`5000.0�܂�
	if (StringToFloat(newValue) < 10.0 || StringToFloat(newValue) > 5000.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 10.0 and 5000.0");
	}
}
