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
#define PL_NAME "Sleep Switch"
#define PL_DESC "Sleep Switch"
#define PL_VERSION "0.0.5"
#define PL_TRANSLATION "sleepswitch.phrases"

#define EFFECT_WAKEUP "sapper_debris"

#define MDL_SLEEP_ICON "models/extras/info_speech.mdl"

#define SOUND_STATE_CHANGE "items/cart_explode_trigger.wav"
#define SOUND_ERROR "items/cart_explode_falling.wav"
#define SOUND_SLEEP_ON "weapons/sentry_move_short2.wav"
#define SOUND_SLEEP_OFF "weapons/sentry_finish.wav"
#define SOUND_WAKEUP "weapons/pistol_shoot.wav"
#define SOUND_GOODNIGHT "vo/engineer_jeers04.wav"

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
new Handle:g_EffectiveDist = INVALID_HANDLE;				// ConVar�L������
new Handle:g_AddHealth = INVALID_HANDLE;					// ConVar�񕜗�


new bool:g_IsSentrySleep[MAXPLAYERS+1] = false;				// �Z���g���[�X���[�v���H
new g_PlayerSentry[MAXPLAYERS+1] = -1;						// ���݂����Z���g���[
new g_SleepIcon[MAXPLAYERS+1] = -1;							// �X���[�v�A�C�R��

new Handle:g_CheckTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �Z���g���[�`�F�b�N�^�C�}�[
new Handle:g_BreathTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// �Q���^�C�}�[

new String:SOUND_WAKEUP_VOICE[9][64];						// �E�F�C�N�A�b�v�{�C�X
new String:SOUND_BREATH[2][64];								// �Q��
new g_BreathNum = 0;										//�Q���J�E���g

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
		CreateConVar("sm_rmf_tf_sleepswitch", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_sleepswitch","1","Sleep Switch Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		
		g_EffectiveDist = CreateConVar("sm_rmf_sleepswitch_dist","20.0","Effective dist[meter] (0.0-100.0)");
		g_AddHealth = CreateConVar("sm_rmf_sleepswitch_heal_amount","20","Heal amount (0-500)");
		HookConVarChange(g_EffectiveDist,	ConVarChange_Radius);
		HookConVarChange(g_AddHealth,		ConVarChange_Health);

		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_sleepswitch_class", "9", "Ability class");
		
		// �{�C�X
		SOUND_WAKEUP_VOICE[0] = "vo/engineer_cheers01.wav";
		SOUND_WAKEUP_VOICE[1] = "vo/engineer_cheers02.wav";
		SOUND_WAKEUP_VOICE[2] = "vo/engineer_moveup01.wav";
		SOUND_WAKEUP_VOICE[3] = "vo/engineer_battlecry07.wav";
		SOUND_WAKEUP_VOICE[4] = "vo/engineer_battlecry06.wav";
		SOUND_WAKEUP_VOICE[5] = "vo/engineer_battlecry03.wav";
		SOUND_WAKEUP_VOICE[6] = "vo/engineer_cheers07.wav";
		SOUND_WAKEUP_VOICE[7] = "vo/engineer_yes03.wav";
		SOUND_WAKEUP_VOICE[8] = "vo/engineer_autobuildingsentry01.wav";

		SOUND_BREATH[0] = "weapons/sentry_upgrading_steam1.wav";
		SOUND_BREATH[1] = "weapons/sentry_upgrading_steam4.wav";
	}

	// �v���O�C��������
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// �X���[�v�X�C�b�`������~
			ForceStopSleepMode(i)
		}
	}
	// �v���O�C����n��
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// �X���[�v�X�C�b�`������~
			ForceStopSleepMode(i)
		}
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// �X���[�v�X�C�b�`������~
			ForceStopSleepMode(i)
		}
		
		PrecacheSound(SOUND_STATE_CHANGE);
		PrecacheSound(SOUND_ERROR);
		PrecacheSound(SOUND_SLEEP_ON);
		PrecacheSound(SOUND_SLEEP_OFF);
		PrecacheSound(SOUND_WAKEUP);
		PrecacheSound(SOUND_GOODNIGHT);
		
		for( new i = 0; i < 7; i++)
		{
			PrecacheSound(SOUND_WAKEUP_VOICE[i], true);
		}

		for( new i = 0; i < 2; i++)
		{
			PrecacheSound(SOUND_BREATH[i], true);
		}
	
		
		PrecacheModel(MDL_SLEEP_ICON, true);

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
		// �A�r���e�BOFF�Ȃ�ڂ��o�܂�
		if(!g_AbilityUnlock[client] && g_IsSentrySleep[client])
		{
			// �X���[�v�X�C�b�`������~
			ForceStopSleepMode(client)
			
			// OFF
			g_IsSentrySleep[client] = false;
		}
		
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_SLEEPSWITCH", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_SLEEPSWITCH_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_SLEEPSWITCH_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_SLEEPSWITCH_ATTRIBUTE_2", client );
			
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
		}
	}
	
	// �I�u�W�F�N�g����
	if(StrEqual(name, EVENT_PLAYER_BUILT_OBJECT))
	{
		new objType = GetEventInt(event, "object");
		
		if( objType == 3 )
		{
			ForceStopSleepMode(client);
		}		
	}

	// �I�u�W�F�N�g�j��
	if(StrEqual(name, EVENT_OBJECT_DESTROYED))
	{
		new objType = GetEventInt(event, "objecttype");
		
		if( objType == 3 )
		{
			ForceStopSleepMode(client);
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
			// �����`�̂�
			if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_WRENCH )
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
							SleepSwitch(client);
						}
					}

				}			
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �X���[�v�Z���g���[�`�F�b�N
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_SentryCheck(Handle:timer, any:client)
{
	// �������Ȃ�`�F�b�N
	if(g_IsSentrySleep[client])
	{
		// �������I�u�W�F�N�g���`�F�b�N
		if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun"))
		{
			// ���������p
			new Float:pos[3];
			pos[1] = 15.0;
			new Float:ang[3];

			// �Z���g���[�K���̃��x���`�F�b�N
			new sentryLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
			// ���x���ɍ��킹�ăA�C�R���̍�������
			if( sentryLevel == 1 )
			{
				pos[2] = 60.0;
			}
			else if( sentryLevel == 2 )
			{
				pos[2] = 80.0;
			}
			else if( sentryLevel == 3 )
			{
				pos[2] = 90.0;
			}
			
			// �A�C�R������������Έړ�
			if(g_SleepIcon[client] != -1 && IsValidEdict(g_SleepIcon[client]) && TF2_EdictNameEqual(g_SleepIcon[client], "prop_dynamic"))
			{
				TeleportEntity(g_SleepIcon[client], pos, ang, NULL_VECTOR);
			}
			
			// �Z���g���[��~
			SetEntProp(g_PlayerSentry[client], Prop_Send, "m_bDisabled", 1);
		}
	}
	else
	{
		// �X���[�v�X�C�b�`������~
		ForceStopSleepMode(client)
	}
}
/////////////////////////////////////////////////////////////////////
//
// �Q���^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_BreathTimer(Handle:timer, any:client)
{
	// �������Ȃ�`�F�b�N
	if(g_IsSentrySleep[client])
	{
		// �������I�u�W�F�N�g���`�F�b�N
		if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun") && GetEntProp(g_PlayerSentry[client], Prop_Send, "m_bHasSapper") != 1)
		{
			// �Q��
			EmitSoundToAll(SOUND_BREATH[g_BreathNum], g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 0.2, 75);
			
			new nowHealth = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iHealth");
			new nowLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
			new addHealth = GetConVarInt(g_AddHealth);		// �񕜗�
		
			// �w���X����
			nowHealth += addHealth;
			
			if( nowLevel == 1 )
			{
				if(nowHealth > 150)
				{
					addHealth = nowHealth - 150;
				}
			}
			else if( nowLevel == 2 )
			{
				if(nowHealth > 180)
				{
					addHealth = nowHealth - 180;
				}
			}
			else if( nowLevel == 3 )
			{
				if(nowHealth > 216)
				{
					addHealth = nowHealth - 216;
				}
			}			
			
			// �w���X�K�p
			//SetEntProp(g_PlayerSentry[client], Prop_Send, "m_iHealth", nowHealth);
			SetVariantInt(addHealth);
			AcceptEntityInput(g_PlayerSentry[client], "AddHealth");
			
			if(g_BreathNum == 0)
			{
				g_BreathNum = 1;
			}
			else
			{
				g_BreathNum = 0;
			}
		}
	}

}


/////////////////////////////////////////////////////////////////////
//
// �X���[�v�X�C�b�`����
//
/////////////////////////////////////////////////////////////////////
stock SleepSwitch(client)
{
	// �������Ȃ�����A��������Ă�Ȃ甭��
	if(!g_IsSentrySleep[client])
	{
		// �J�n
		StartSleepMode(client);
	}
	else
	{
		// ��~
		StopSleepMode(client);
	}

}
/////////////////////////////////////////////////////////////////////
//
// �X���[�v���[�h�J�n
//
/////////////////////////////////////////////////////////////////////
stock StartSleepMode(client)
{
	// �Z���g���[�K����{��
	new obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_sentrygun")) != -1)
	{
		new iOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if(iOwner == client)
		{
			new Float:sentryPos[3];
			GetEntPropVector(obj, Prop_Data, "m_vecAbsOrigin", sentryPos);
			new Float:playerPos[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", playerPos);
			
			if(GetEntProp(obj, Prop_Send, "m_iState") == 1 && GetVectorDistanceMeter(sentryPos, playerPos) <= GetConVarFloat(g_EffectiveDist) )
			{
				// �Z���g���[��ۑ�
				g_PlayerSentry[client] = obj;
				
				// �`�F�b�N�^�C�}�[����
				ClearTimer(g_CheckTimer[client]);
				g_CheckTimer[client] = CreateTimer(0.5, Timer_SentryCheck, client, TIMER_REPEAT);
				
				// �Q���^�C�}�[����
				ClearTimer(g_BreathTimer[client]);
				g_BreathTimer[client] = CreateTimer(2.5, Timer_BreathTimer, client, TIMER_REPEAT);

				// �Q���J�E���g
				g_BreathNum = 0;
				
				// �X���[�v�A�C�R���쐬
				CreateSleepIcon(client);
				
				// �؂�ւ��T�E���h
				EmitSoundToClient(client, SOUND_STATE_CHANGE, client, _, _, SND_CHANGEPITCH, 0.3, 80);
				
				// ���˂ފJ�n
				EmitSoundToAll(SOUND_SLEEP_ON, g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 50);
				EmitSoundToAll(SOUND_GOODNIGHT, g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 140);

				// �X���[�vON
				g_IsSentrySleep[client] = true;
				
				return;
			}
			else
			{
				// ���ꂷ��
				if( GetVectorDistanceMeter(sentryPos, playerPos) > GetConVarFloat(g_EffectiveDist) )
				{
					// �G���[���b�Z�[�W
					PrintToChat(client, "\x05%T", "MESSAGE_LONG_DISTANCE", client);
				}
			}
		}
	}
	
	// �G���[��
	EmitSoundToClient(client, SOUND_ERROR, client, _, _, SND_CHANGEPITCH, 0.3, 200);
	
}

/////////////////////////////////////////////////////////////////////
//
// �X���[�v���[�h��~
//
/////////////////////////////////////////////////////////////////////
stock StopSleepMode(client)
{

	// �������I�u�W�F�N�g���`�F�b�N
	if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun"))
	{
		new Float:sentryPos[3];
		GetEntPropVector(g_PlayerSentry[client], Prop_Data, "m_vecAbsOrigin", sentryPos);
		new Float:playerPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", playerPos);
		
		// �T�b�p�[�����Ă��Ȃ����
		if(GetEntProp(g_PlayerSentry[client], Prop_Send, "m_bHasSapper") != 1 && GetVectorDistanceMeter(sentryPos, playerPos) <= GetConVarFloat(g_EffectiveDist) )
		{
			// �`�F�b�N�^�C�}�[��~
			ClearTimer(g_CheckTimer[client]);
			// �Q���^�C�}�[��~
			ClearTimer(g_BreathTimer[client]);

			// �Z���g���[��~����
			SetEntProp(g_PlayerSentry[client], Prop_Send, "m_bDisabled", 0);
			
			// �A�C�R���폜
			RemoveSleepIcon(client);

			// ���ڊo��
			EmitSoundToAll(SOUND_SLEEP_OFF, g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 150);
			EmitSoundToAll(SOUND_WAKEUP_VOICE[GetRandomInt(0, 8)], g_PlayerSentry[client], _, _, SND_CHANGEPITCH, 1.0, 140);
			
			// �؂�ւ��T�E���h
			EmitSoundToClient(client, SOUND_STATE_CHANGE, client, _, _, SND_CHANGEPITCH, 0.3, 80);

			// �Z���g���[�N���A
			g_PlayerSentry[client] = -1;
			
			// �X���[�vOFF
			g_IsSentrySleep[client] = false;	
			
			return;
		}
		else
		{
			// ���ꂷ��
			if( GetVectorDistanceMeter(sentryPos, playerPos) > GetConVarFloat(g_EffectiveDist) )
			{
				// �G���[���b�Z�[�W
				PrintToChat(client, "\x05%T", "MESSAGE_LONG_DISTANCE", client);
			}
		}
		
	}

	if(TF2_GetPlayerClass(client) == TFClass_Engineer && g_AbilityUnlock[client])
	{
		// �G���[��
		EmitSoundToClient(client, SOUND_ERROR, client, _, _, SND_CHANGEPITCH, 0.3, 200);
	}
	else
	{
		// �`�F�b�N�^�C�}�[��~
		ClearTimer(g_CheckTimer[client]);
		// �Q���^�C�}�[��~
		ClearTimer(g_BreathTimer[client]);
	}
						
}


/////////////////////////////////////////////////////////////////////
//
// �X���[�v���[�h������~
//
/////////////////////////////////////////////////////////////////////
stock ForceStopSleepMode(client)
{
	// �`�F�b�N�^�C�}�[��~
	ClearTimer(g_CheckTimer[client]);
	// �Q���^�C�}�[��~
	ClearTimer(g_BreathTimer[client]);

	// �X���[�v�A�C�R��������
	if(g_SleepIcon[client] != -1 && IsValidEdict(g_SleepIcon[client]) && TF2_EdictNameEqual(g_SleepIcon[client], "prop_dynamic"))
	{
		// �A�C�R���폜
		AcceptEntityInput(g_SleepIcon[client], "Kill");
		g_SleepIcon[client] = -1;
	}	
	
	
	// �������I�u�W�F�N�g���`�F�b�N
	if(g_PlayerSentry[client] != -1 && IsValidEdict(g_PlayerSentry[client]) && TF2_EdictNameEqual(g_PlayerSentry[client], "obj_sentrygun"))
	{

		// �T�b�p�[�����Ă��Ȃ����
		if(GetEntProp(g_PlayerSentry[client], Prop_Send, "m_bHasSapper") != 1)
		{
			// �Z���g���[��~����
			SetEntProp(g_PlayerSentry[client], Prop_Send, "m_bDisabled", 0);
			
		}
	
	}

	// �Z���g���[�N���A
	g_PlayerSentry[client] = -1;
	
	// �X���[�vOFF
	g_IsSentrySleep[client] = false;	
}


/////////////////////////////////////////////////////////////////////
//
// �X���[�v�A�C�R���쐬
//
/////////////////////////////////////////////////////////////////////
stock CreateSleepIcon(any:client)
{
	// �X���[�v�A�C�R���쐬
	g_SleepIcon[client] = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(g_SleepIcon[client]))
	{
		new String:tName[32];
		GetEntPropString(g_PlayerSentry[client], Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(g_SleepIcon[client], "targetname", "sleep_icon");
		DispatchKeyValue(g_SleepIcon[client], "parentname", tName);
		SetEntityModel(g_SleepIcon[client], MDL_SLEEP_ICON);
		DispatchSpawn(g_SleepIcon[client]);
		SetVariantString("!activator");
		AcceptEntityInput(g_SleepIcon[client], "SetParent", g_PlayerSentry[client], g_PlayerSentry[client], 0);
		//SetVariantString("build_point_0");
		//AcceptEntityInput(g_SleepIcon[client], "SetParentAttachment", g_SleepIcon[client], g_SleepIcon[client], 0);
		ActivateEntity(g_SleepIcon[client]);

		// �Z���g���[�̈ʒu�擾
		new Float:pos[3];
		pos[1] = 15.0;
		new Float:ang[3];

		// �Z���g���[�̃��x���ɍ��킹�č�������
		new sentryLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
		if( sentryLevel ==  1 )
		{
			pos[2] = 60.0;
		}
		else if( sentryLevel ==  2 )
		{
			pos[2] = 80.0;
		}
		else if( sentryLevel ==  3 )
		{
			pos[2] = 90.0;
		}
		TeleportEntity(g_SleepIcon[client], pos, ang, NULL_VECTOR);
	}	
					
}
/////////////////////////////////////////////////////////////////////
//
// �X���[�v�A�C�R���폜
//
/////////////////////////////////////////////////////////////////////
stock RemoveSleepIcon(any:client)
{
	// �X���[�v�A�C�R��������
	if(g_SleepIcon[client] != -1 && IsValidEdict(g_SleepIcon[client]) && TF2_EdictNameEqual(g_SleepIcon[client], "prop_dynamic"))
	{
		// �E�F�C��A�b�v�G�t�F�N�g
		// �Z���g���[�̃��x���ɍ��킹�č�������
		new sentryLevel = GetEntProp(g_PlayerSentry[client], Prop_Send, "m_iUpgradeLevel");
		new Float:pos[3];
		pos[1] = 15.0;
		new Float:ang[3];
		if( sentryLevel ==  1 )
		{
			pos[2] = 60.0;
		}
		else if( sentryLevel ==  2 )
		{
			pos[2] = 80.0;
		}
		else if( sentryLevel ==  3 )
		{
			pos[2] = 90.0;
		}
		AttachParticle(g_PlayerSentry[client], EFFECT_WAKEUP, 1.0, pos, ang);

		// ����鉹
		EmitSoundToAll(SOUND_WAKEUP, g_SleepIcon[client], _, _, SND_CHANGEPITCH, 1.0, 200);

		// �A�C�R���폜
		AcceptEntityInput(g_SleepIcon[client], "Kill");
		g_SleepIcon[client] = -1;
	}	
					
}

