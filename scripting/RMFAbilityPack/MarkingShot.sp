/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.1.1
// �E�d�l��ύX
// �Esm_rmf_markingshot_charge_mag��ǉ�
// �Esm_rmf_markingshot_time_max��ǉ�
// �Esm_rmf_markingshot_time_min��ǉ�
// �E1.3.1�ŃR���p�C��
// 2009/10/06 - 0.0.5
// �E����������ύX
// �E�}�[�L���O���Ԃ̃x�[�X�l��ύX�B
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
#define PL_NAME "Marking Shot"
#define PL_DESC "Marking Shot"
#define PL_VERSION "0.1.1"
#define PL_TRANSLATION "markingshot.phrases"

#define SOUND_PLAYER_MARKED "items/cart_explode_trigger.wav"

#define SOUND_MARKING_FIRE "player/flame_out.wav"
#define SOUND_MARKING_HIT "weapons/jar_explode.wav"

#define EFFECT_PEE_HIT "peejar_groundsplash"

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
new Float:g_PlayerMarkingEndTime[MAXPLAYERS+1] = 0.0;				// �}�[�L���O�J�n����
new Float:g_PlayerMarkingTime[MAXPLAYERS+1] = 0.0;					// �}�[�L���O����
new Handle:g_MarkingEndTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �}�[�L���O�I���^�C�}�[
new bool:g_PlayerMarked[MAXPLAYERS+1] = false;						// �A�}�[�N���ꂽ�H
new Handle:g_MarkingTimeMax = INVALID_HANDLE;						// ConVar�ő�}�[�L���O����
new Handle:g_MarkingTimeMin = INVALID_HANDLE;						// ConVar�ŏ��}�[�L���O����
new Handle:g_ChargeMag = INVALID_HANDLE;							// ConVar�`���[�W�ʔ{��


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
		CreateConVar("sm_rmf_tf_markingshot", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_markingshot","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_markingshot_class", "2", "Ability class");
		
		g_MarkingTimeMax	= CreateConVar("sm_rmf_markingshot_time_max",	"25.0","Max marking time (0.0-120.0)");
		g_MarkingTimeMin	= CreateConVar("sm_rmf_markingshot_time_min",	"2.0","Min marking time (0.0-120.0)");
		g_ChargeMag			= CreateConVar("sm_rmf_markingshot_charge_mag",	"0.8","Charge amount magnification (0.0-10.0)");
		HookConVarChange(g_MarkingTimeMin, ConVarChange_Time);
		HookConVarChange(g_MarkingTimeMax, ConVarChange_Time);
		HookConVarChange(g_ChargeMag, ConVarChange_Magnification);

		
	}
	
	// �}�b�v�J�n
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_PEE_HIT);
		PrecacheSound(SOUND_MARKING_FIRE, true);
		PrecacheSound(SOUND_MARKING_HIT, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �^�C�}�[�N���A
		ClearTimer( g_MarkingEndTimer[ client ] );
		
		// �}�[�L���O����Ă��Ȃ�
		g_PlayerMarkingEndTime[client] =  0.0;
		g_PlayerMarkingTime[client] = 0.0
		g_PlayerMarked[client] = false;
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:percentage[16];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_MARKINGSHOT", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_1", client );
			GetPercentageString( GetConVarFloat( g_ChargeMag ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_2", client, percentage );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_MARKINGSHOT_ATTRIBUTE_3", client );
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s\n%s", attribute1, attribute2, attribute3 );
		}

	}
	
	// �v���C���[�����f�B���C
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{
		// ����
		if( TF2_GetPlayerClass( client ) == TFClass_Sniper && g_AbilityUnlock[client])
		{
			ClientCommand(client, "slot1");
			// �Z�J���_���폜
			new weaponIndex = GetPlayerWeaponSlot(client, 1);
			if( weaponIndex != -1 )
			{
				TF2_RemoveWeaponSlot(client, 1);
				//RemovePlayerItem(client, weaponIndex);
				//AcceptEntityInput(weaponIndex, "Kill");		
			}	
		}
	}
	
	// �v���C���[�_���[�W
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new health = GetEventInt(event, "health");
		
		if( attacker > 0 && attacker != client && TF2_GetPlayerClass( attacker ) == TFClass_Sniper && g_AbilityUnlock[attacker] && health > 0 )
		{
			if(TF2_CurrentWeaponEqual(attacker, "CTFSniperRifle"))
			{
				// �}�[�L���O���Ԃ̓`���[�W���Ԃɔ��
				new Float:time = TF2_GetPlayerSniperCharge( attacker ) * 0.1 * 5.0;
				
				// �`���[�W���Ă�ꍇ�̂�
				if( time > 0.0 )
				{
					// ���ɐݒ�ς݂̃}�[�L���O���Ԃ��Ȃ����Ƃ�����
					if(( g_PlayerMarkingEndTime[client] - GetGameTime() ) <= time )
					{
						// �ő�ݒ�
						if( time > GetConVarFloat( g_MarkingTimeMax ) )
						{
							time = GetConVarFloat( g_MarkingTimeMax );
						}
						
						// �ŏ��ݒ�
						if( time < GetConVarFloat( g_MarkingTimeMin ) )
						{
							time = GetConVarFloat( g_MarkingTimeMin );
						}
						
						// �J�n���Ԃ�ۑ�
						g_PlayerMarkingEndTime[client] = GetGameTime() +  time;
						// �}�[�L���O����
						g_PlayerMarkingTime[client] = time;

						//PrintToChat(attacker, "%f", g_PlayerMarkingTime[client]);
						// �`���[�W���Ă�Ƃ�����
						if( g_PlayerMarkingTime[client] > 0.0 )
						{
							EmitSoundToAll(SOUND_MARKING_HIT, client, _, _, SND_CHANGEPITCH, 1.0, 150);		
							
							new Float:pos[3];
							pos[2] = 50.0;
							AttachParticle( client, EFFECT_PEE_HIT, 2.0, pos );
							
							// �I���^�C�}�[�ݒ�
							//PrintToChatAll("%f", time);
							ClearTimer( g_MarkingEndTimer[ client ] );	
							g_MarkingEndTimer[ client ] = CreateTimer( time,  Timer_MarkingEnd, client );
							
							// �A�܂݂�
							TF2_RemoveCond( client, TF2_COND_URINE );
							TF2_AddCond( client, TF2_COND_URINE );
							
							// �}�[�L���O���ꂽ
							g_PlayerMarked[ client ] = true;
							
							// ���b�Z�[�W�\��
							PrintToChat(client, "\x05%T", "MARKINGSHOT_TAKE_MARK", client);	// �}�[�L���O���ꂽ�I
						}
					}
				}
			}
		}
	}	

	// �v���C���[���T�v���C
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame( client ) && IsPlayerAlive( client ) )
		{
			// �^�C�}�[�N���A
			ClearTimer( g_MarkingEndTimer[ client ] );
			
			// �}�[�L���O����Ă��Ȃ�
			g_PlayerMarkingEndTime[ client ] = 0.0;
			g_PlayerMarkingTime[ client ] = 0.0
			g_PlayerMarked[ client ] = false;
			
			// �X�i�C�p�[
			if( TF2_GetPlayerClass(client) == TFClass_Sniper && g_AbilityUnlock[client] )
			{
				// ����Ď擾���Ȃ��悤��
				// �Z�J���_���폜
				ClientCommand(client, "slot1");
				new weaponIndex = GetPlayerWeaponSlot(client, 1);
				if( weaponIndex != -1 )
				{
					TF2_RemoveWeaponSlot(client, 1);
					//RemovePlayerItem(client, weaponIndex);
					//AcceptEntityInput(weaponIndex, "Kill");		
				}	
			}
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
// �t���[���A�N�V����
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �X�i�C�p�[�̂�
		if( TF2_GetPlayerClass(client) == TFClass_Sniper && g_AbilityUnlock[client] )
		{
			// �Y�[����
			if( TF2_IsPlayerZoomed( client ) )
			{
				// �`���[�W�ʐ���
				if( TF2_GetPlayerSniperCharge(client) > 100 * GetConVarFloat( g_ChargeMag ) )
				{	
					TF2_SetPlayerSniperCharge( client, RoundFloat( 100 * GetConVarFloat( g_ChargeMag ) ) );
				}
			}
		}
	}
}
/////////////////////////////////////////////////////////////////////
//
// �}�[�L���O�I��
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_MarkingEnd(Handle:timer, any:client)
{
	g_MarkingEndTimer[ client ] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		// �}�[�L���O����Ă��ĔA�܂݂�Ȃ����
		if( g_PlayerMarked[ client ] && TF2_IsPlayerUrine( client ) )
		{
			TF2_RemoveCond( client, TF2_COND_URINE );
			g_PlayerMarkingEndTime[ client ] = 0.0;
			g_PlayerMarkingTime[ client ] = 0.0
			g_PlayerMarked[ client ] = false;
		}
	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// �N���e�B�J�����o
//
/////////////////////////////////////////////////////////////////////
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	// MOD��ON�̎�����
	if( !g_IsRunning )
		return Plugin_Continue;	

	// �X�i�C�p�[�̂Ƃ��̂�
	if( TF2_GetPlayerClass(client) == TFClass_Sniper && g_AbilityUnlock[client] )
	{
		// �X�i�C�p�[���C�t��
		if( TF2_CurrentWeaponEqual(client, "CTFSniperRifle" ) && TF2_GetPlayerSniperCharge(client) > 0)
		{
			EmitSoundToAll(SOUND_MARKING_FIRE, TF2_GetCurrentWeapon(client), _, _, SND_CHANGEPITCH, 1.0, 180);		
		}
		
	}

	return Plugin_Continue;	
}

