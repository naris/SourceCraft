/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.9
// �Esm_rmf_delicioussandvich_heal_amount��sm_rmf_delicioussandvich_add_heal_amount�ɕύX
// �E�ꕔ�d�l��ύX(�񕜗ʑ���A�L�����ɂ���ĉ񕜗ʂ�����)
// �E1.3.1�ŃR���p�C��
// 2009/09/18 - 0.0.7
// �E�ꕔ�d�l�ύX(�񕜗�UP�A�I�[�o�[�q�[�����)
// �Esm_rmf_delicioussandvich_heal_amount��ǉ�
// �Esm_rmf_delicioussandvich_heal_mag���폜
// �Esm_rmf_delicioussandvich_overheal���폜
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
#define PL_NAME			"Delicious Sandvich"
#define PL_DESC			"Delicious Sandvich"
#define PL_VERSION		"0.0.9"
#define PL_TRANSLATION	"delicioussandvich.phrases"

#define SOUND_END_VOICE	"vo/heavy_sandwichtaunt17.wav"

#define SOUND_KGB_ENABLE "weapons/weapon_crit_charged_on.wav"
#define SOUND_KGB_DISABLE "weapons/weapon_crit_charged_off.wav"
#define SOUND_KGB_HIT_1 "weapons/boxing_gloves_hit_crit1.wav"
#define SOUND_KGB_HIT_2 "weapons/boxing_gloves_hit_crit2.wav"
#define SOUND_KGB_HIT_3 "weapons/boxing_gloves_hit_crit3.wav"

#define EFFECT_EAT_RED	"critgun_weaponmodel_red"
#define EFFECT_EAT_BLU	"critgun_weaponmodel_blu"


/////////////////////////////////////////////////////////////////////
//
// MOD���
//
/////////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name		= PL_NAME,
	author		= "RIKUSYO",
	description	= PL_DESC,
	version		= PL_VERSION,
	url			= "http://ameblo.jp/rikusyo/"
}

/////////////////////////////////////////////////////////////////////
//
// �O���[�o���ϐ�
//
/////////////////////////////////////////////////////////////////////
new Handle:g_TauntTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// �����`�F�b�N�^�C�}�[
new Handle:g_TauntVoiceTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// �{�C�X�p�̃^�C�}�[
new Handle:g_HealthDreinTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// �̗͌��炷�p�̃^�C�}�[
new Handle:g_HealingAmount					= INVALID_HANDLE;	// ConVar�񕜗�
new Handle:g_OffTimer[MAXPLAYERS+1] 		= INVALID_HANDLE;   // �I�t�^�C�}�[

new bool:g_NowDelicious[MAXPLAYERS+1]	= false;				// �f���V���X���H
new bool:g_NeedDrein[MAXPLAYERS+1]		= false;				// �I�[�o�[�q�[�����K�v���H
new bool:g_KGBKill[MAXPLAYERS+1]		= false;				// KGBKill�H
new g_KillCout[MAXPLAYERS+1]			= 0;					// �L����
new g_Sandvich[MAXPLAYERS+1]			= -1;					// �T���h���B����
new g_SandvichEffect[MAXPLAYERS+1]		= -1;					// �T���h���B�����G�t�F�N�g
new g_LastHealth[MAXPLAYERS+1]			= 0;					// �w���X

new String:SOUND_KGB_HIT[3][] = { SOUND_KGB_HIT_1, SOUND_KGB_HIT_2, SOUND_KGB_HIT_3 };

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
		CreateConVar("sm_rmf_tf_delicioussandvich", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_delicioussandvich","1","Delicious Sandvich Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_HealingAmount = CreateConVar("sm_rmf_delicioussandvich_add_heal_amount","45","Add heal amount per 1 second (0-500)");
		HookConVarChange(g_HealingAmount, ConVarChange_Health);

		// �G���e�B�e�B�t�b�N
		HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
		
		// �����R�}���h�Q�b�g
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_delicioussandvich_class", "6", "Ability class");
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_EAT_RED);
		PrePlayParticle(EFFECT_EAT_BLU);
		
		PrecacheSound(SOUND_END_VOICE, true);
		
		PrecacheSound(SOUND_KGB_ENABLE, true);
		PrecacheSound(SOUND_KGB_DISABLE, true);
		PrecacheSound(SOUND_KGB_HIT_1, true);
		PrecacheSound(SOUND_KGB_HIT_2, true);
		PrecacheSound(SOUND_KGB_HIT_3, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �G�t�F�N�g�폜
		DeleteParticle( g_SandvichEffect[ client ] );

		// �^�C�}�[�N���A
		ClearTimer( g_TauntTimer[client] );
		ClearTimer( g_TauntVoiceTimer[client] );
		ClearTimer( g_HealthDreinTimer[client] );
		ClearTimer( g_OffTimer[ client ] );
		
		g_NowDelicious[ client ]= false;
		g_NeedDrein[ client ]	= false;
		g_KGBKill[ client ]		= false;
		g_KillCout[ client ]	= 0;
		g_LastHealth[ client ]	= 0;
		g_Sandvich[ client ]	= -1;
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy )
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_DELICIOUSSANDVICH", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_DELICIOUSSANDVICH_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_DELICIOUSSANDVICH_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_DELICIOUSSANDVICH_ATTRIBUTE_2", client );
			
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}
		
		StopSound( client, 0, SOUND_KGB_ENABLE );
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
	// �v���C���[�_���[�W
	if( StrEqual( name, EVENT_PLAYER_DAMAGE ) )
	{
		new health = GetEventInt( event, "health" );
		g_LastHealth[client] = health;
	}
	
	// �v���C���[���S
	if( StrEqual( name, EVENT_PLAYER_DEATH ) )
	{
		new attacker	= GetClientOfUserId( GetEventInt( event, "attacker" ) );
		new String:weapon[64];
		GetEventString( event, "weapon", weapon, sizeof( weapon ) );
		
		if( attacker > 0 && StrEqual( weapon, "gloves" ) )
		{
			if( IsClientInGame( attacker ) && IsPlayerAlive( attacker ) && g_AbilityUnlock[ attacker ] )
			{
				DeleteParticle( g_SandvichEffect[ attacker ] );
				g_Sandvich[ attacker ] = -1;
				
				if( g_KGBKill[ attacker ] )
				{
					new weaponIndex = GetPlayerWeaponSlot( attacker, 2 );
					EmitSoundToAll( SOUND_KGB_HIT [ GetRandomInt( 0, 2 ) ], attacker, _, _, _, 1.0, _, weaponIndex );
				}
				else
				{
					new weaponIndex = GetPlayerWeaponSlot( attacker, 2 );
					EmitSoundToAll( SOUND_KGB_ENABLE, attacker, _, _, _, 1.0, _, weaponIndex );
				}
			
				ClearTimer( g_OffTimer[ attacker ] );
				g_OffTimer[ attacker ] = CreateTimer( 5.0, Timer_DeliciousEnd, attacker );
				
				g_KGBKill[ attacker ] = true;
				
				// �L���J�E���g���₷
				g_KillCout[ attacker ]  += 1;
				
			}
		}
	}
	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// KGBOff
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DeliciousEnd( Handle:timer, any:client )
{
	DeleteParticle( g_SandvichEffect[ client ] );
	g_Sandvich[ client ]	= -1;
	g_OffTimer[ client ]	= INVALID_HANDLE;
	g_KGBKill[ client ]		= false;
	g_KillCout[ client ]	= 0;
	StopSound( client, 0, SOUND_KGB_ENABLE );
	EmitSoundToAll(SOUND_KGB_DISABLE, client, _, _, _, 1.0);
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
		// �w�r�[
		if( TF2_GetPlayerClass( client ) == TFClass_Heavy && g_AbilityUnlock[client] )
		{
			if( TF2_IsPlayerCrits(client) && TF2_IsPlayerTaunt(client) )
			{
				if( CheckElapsedTime(client, 0.01) )
				{
					// �L�[�����������Ԃ�ۑ�
					SaveKeyTime(client);

					// �U��
					if ( GetClientButtons(client) & IN_ATTACK )
					{
						DeliciousSandvich( client );
					}
				}
			}
			
			// �������Ƃ�
			if( g_KGBKill[ client ] )
			{
				if( CheckElapsedTime(client, 0.1) )
				{

					// �U��
					if ( GetClientButtons(client) & IN_ATTACK2 )
					{
						// �L�[�����������Ԃ�ۑ�
						SaveKeyTime(client);
						
						new sandvich = -1;
						while (( sandvich = FindEntityByClassname( sandvich, "item_healthkit_medium")) != -1)
						{
							//PrintToChat(client, "%d %d",client, GetEntProp(body, Prop_Send, "m_iPlayerIndex"));
							new iOwner = GetEntPropEnt( sandvich, Prop_Send, "m_hOwnerEntity" );
							if( iOwner == client && GetEntPropEnt( sandvich, Prop_Data, "m_hGroundEntity" ) == -1 )
							{
								new Float:pos[3];
								pos[2] = 10.0;
								DeleteParticle( g_SandvichEffect[ client ] );
								if( GetClientTeam( client ) == _:TFTeam_Red )
								{
									g_SandvichEffect[ client ] = AttachParticle( sandvich, "player_intel_trail_red", 25.0, pos );
								}
								else
								{
									g_SandvichEffect[ client ] = AttachParticle( sandvich, "player_intel_trail_blue", 25.0, pos );
								}
								
								// �T���h���B�b�`��ۑ�
								g_Sandvich[ client ] = sandvich;
							}
						}
					}
				}
			}
		}		
	}
}


/////////////////////////////////////////////////////////////////////
//
// �G���e�B�e�B�t�b�N
//
/////////////////////////////////////////////////////////////////////
public Action:Entity_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
	new iOwner = GetEntPropEnt( caller, Prop_Send, "m_hOwnerEntity" );
	if( iOwner != -1 )
	{
		if( g_KGBKill[ iOwner ] && g_Sandvich[ iOwner ] == caller )
		{
			DeleteParticle( g_SandvichEffect[ iOwner ] );
			g_Sandvich[ iOwner ] = -1;
			
			// �̗͂��ő�܂ŉ�
			new Handle:newEvent = CreateEvent( "player_healonhit" );
			if( newEvent != INVALID_HANDLE )
			{
				SetEventInt( newEvent, "amount", TF2_GetPlayerDefaultHealth( activator ) );
				SetEventInt( newEvent, "entindex", activator );
				FireEvent( newEvent );
			}
			
			// �K�p
			SetEntityHealth( activator, TF2_GetPlayerDefaultHealth( activator ) );
		}
	}
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
	
	// �w�r�[�ŃA�r���e�BON�̂Ƃ�
	if( TF2_GetPlayerClass(client) == TFClass_Heavy && g_AbilityUnlock[client] && !TF2_IsPlayerTaunt(client))
	{
		DeliciousSandvich(client);
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// ����
//
/////////////////////////////////////////////////////////////////////
public DeliciousSandvich(any:client)
{
		
	// �T���h���B�b�`�̂�
	if(TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_SANDVICH )
	{
		g_LastHealth[client] = GetClientHealth( client );
	
		// �����^�C�}�[����
		ClearTimer( g_TauntTimer[client] );
		g_TauntTimer[client] = CreateTimer(1.0, Timer_TauntEnd, client);
		
		// �����{�C�X�^�C�}�[����
		ClearTimer( g_TauntVoiceTimer[client] );
		g_TauntVoiceTimer[client] = CreateTimer(3.2, Timer_DeliciousVoice, client);
		
		// �I�[�o�[�q�[����Ԑݒ�
		if( TF2_IsPlayerOverHealing( client ) )
		{
			g_NeedDrein[client] = false;
		}
	}	
}

/////////////////////////////////////////////////////////////////////
//
// �T���h���B�b�`�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntEnd(Handle:timer, any:client)
{
	g_TauntTimer[client] = INVALID_HANDLE;
	
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �N���b�c��Ԓ������I�����Ă��Ȃ�
		if(TF2_IsPlayerCrits(client) && TF2_IsPlayerTaunt(client) && g_TauntVoiceTimer[client] != INVALID_HANDLE)
		{
			g_NowDelicious[client] = true;
			
			new String:effect[32];
			if( TFTeam:GetClientTeam(client) == TFTeam_Red)
			{
		    	effect = EFFECT_EAT_RED;
			}
			else
			{
				effect = EFFECT_EAT_BLU;
			}	
			
			new Float:pos[3];
			pos[0]=3.0;
			pos[2]=-10.0;
			AttachParticleBone(client, effect, "head", 0.4, pos);
			
			new nowHealth = GetClientHealth(client);
			
			if( !TF2_IsPlayerOverHealing( client ) )
			{
				g_NeedDrein[client] = true;
				
			}
			
			new Float:mag = (g_KillCout[ client ] - 1) * 0.5 + 1.0;
			new healAmout = RoundFloat( GetConVarInt(g_HealingAmount) * mag )

			new diff = 0;
			if( nowHealth != g_LastHealth[client] + 75 + healAmout )
			{
				diff = (g_LastHealth[client] + 75 + healAmout) - nowHealth - healAmout;
			}
			nowHealth += healAmout + diff;
			
			
			new Handle:newEvent = CreateEvent( "player_healonhit" );
			if( newEvent != INVALID_HANDLE )
			{
				SetEventInt( newEvent, "amount", healAmout + 75 );
				SetEventInt( newEvent, "entindex", client );
				FireEvent( newEvent );
			}

			// �ő�w���X�����Ȃ�
			if( nowHealth >= TF2_GetPlayerMaxHealth(client))
			{
				nowHealth = TF2_GetPlayerMaxHealth(client);
			}
			
			// �K�p
			SetEntityHealth(client, nowHealth);

			g_LastHealth[client] = nowHealth;
			// ��b��ɐݒ�
			g_TauntTimer[client] = CreateTimer(1.0, Timer_TauntEnd, client);
		}
	}
}
/////////////////////////////////////////////////////////////////////
//
// �{�C�X�p�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DeliciousVoice(Handle:timer, any:client)
{
	g_TauntVoiceTimer[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(TF2_IsPlayerTaunt(client))
		{
			// ���������ゾ��
			if(g_NowDelicious[client])
			{
				EmitSoundToAll(SOUND_END_VOICE, client, _, _, _, 1.0);
				g_NowDelicious[client] = false;
			}		
		}

		if( g_NeedDrein[client] )
		{
			// �w���X�h���C���p�̃^�C�}�[
			ClearTimer( g_HealthDreinTimer[client] );
			g_HealthDreinTimer[client] = CreateTimer(0.15, Timer_HealthDrein, client, TIMER_REPEAT );
			
		}
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
		if( TF2_IsPlayerOverHealing( client ) && TF2_GetNumHealers(client) == 0 )
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



