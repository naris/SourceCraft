/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.3
// �E�d�l���ꕔ�ύX
// �Esm_rmf_homingrocket_battery_runtime��ǉ�
// �E1.3.1�ŃR���p�C��

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
#define PL_NAME			"Homing Rocket"
#define PL_DESC			"Homing Rocket"
#define PL_VERSION		"0.0.3"
#define PL_TRANSLATION	"homingrocket.phrases"

#define SOUND_PLANT_SHOVEL	"weapons/cbar_hit2.wav"
#define SOUND_PICKUP_SHOVEL	"weapons/blade_hit4.wav"
#define SOUND_SHOVEL_ACTIVE	"weapons/stickybomblauncher_det.wav"
#define SOUND_SHOVEL_LOOP	"ui/projector_movie.wav"
#define SOUND_SHOVEL_DEACTIVE	"weapons/weapon_crit_charged_off.wav"
#define SOUND_ROCKET_LAUNCH	"player/invulnerable_on.wav"

#define MDL_PLANT_SHOVEL	"models/weapons/w_models/w_shovel.mdl"
#define MDL_PLANT_LIGHT		"models/props_lights/hangingbulb.mdl"

#define EFFECT_BEAM_RED		"medicgun_beam_red_trail"
#define EFFECT_BEAM_BLU		"medicgun_beam_blue_trail"
#define EFFECT_LIGHT_RED	"cart_flashinglight_red"
#define EFFECT_LIGHT_BLU	"cart_flashinglight"

#define HOMING_ROCKETS_MAX	8	// �z�[�~���O���P�b�g�ő吔

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
new Handle:g_RocketCheckTimer[MAXPLAYERS+1]		= INVALID_HANDLE;	// ���P�b�g���ˌ�̃`�F�b�N�܂Ń^�C�}�[
new Handle:g_ShovelBatteryRunTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// �L������

new Handle:g_RocketsData[MAXPLAYERS+1][HOMING_ROCKETS_MAX];		// ���P�b�g�̃f�[�^
new Handle:g_ShovelData[MAXPLAYERS+1] = INVALID_HANDLE;			// �V���x���̃f�[�^
new bool:g_ActiveHoming[MAXPLAYERS+1] = false;					// �������H
new bool:g_EndBattery[MAXPLAYERS+1] = false;					// �o�b�e���[�I���H

new Handle:g_StartAccuracy = INVALID_HANDLE;		// �J�n���x
new Handle:g_FinalAccuracy = INVALID_HANDLE;		// �I�����x
new Handle:g_BatteryRunTime = INVALID_HANDLE;		// �L������

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
		CreateConVar("sm_rmf_tf_homingrocket", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_homingrocket","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		// CanVar
		g_StartAccuracy		= CreateConVar("sm_rmf_homingrocket_start_accuracy",	"70",	"Homing start accuracy (0-100)");
		g_FinalAccuracy		= CreateConVar("sm_rmf_homingrocket_final_accuracy",	"2", 	"Homing final accuracy (0-100)");
		g_BatteryRunTime	= CreateConVar("sm_rmf_homingrocket_battery_runtime",	"12.0",	"Homing system battery run time (0.0-120.0)");
		HookConVarChange( g_StartAccuracy, ConVarChange_Accuracy );
		HookConVarChange( g_FinalAccuracy, ConVarChange_Accuracy );
		HookConVarChange( g_BatteryRunTime , ConVarChange_Time );

		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_homingrocket_class", "3", "Ability class");

		
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			InitRocketData(i);
		}
	}

	
	// �v���O�C��������
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			InitRocketData(i);
		}
	}
	
	// �v���O�C����n��
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			// ���P�b�g�p�̔z��n���h���폜
			for( new j = 0; j < HOMING_ROCKETS_MAX; j++ )
			{
				if( g_RocketsData[i][j] != INVALID_HANDLE )
				{
					CloseHandle( g_RocketsData[i][j] );
				}
			}
			// �V���x���p�̔z��폜
			if( g_ShovelData[i] != INVALID_HANDLE )
			{
				CloseHandle( g_ShovelData[i] );
			}
		}
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_BEAM_RED);
		PrePlayParticle(EFFECT_BEAM_BLU);
		PrePlayParticle(EFFECT_LIGHT_RED);
		PrePlayParticle(EFFECT_LIGHT_BLU);

		PrecacheSound(SOUND_PLANT_SHOVEL, true);
		PrecacheSound(SOUND_SHOVEL_DEACTIVE, true);
		PrecacheSound(SOUND_PICKUP_SHOVEL, true);
		PrecacheSound(SOUND_ROCKET_LAUNCH, true);
		PrecacheSound(SOUND_SHOVEL_LOOP, true);
		PrecacheSound(SOUND_SHOVEL_ACTIVE, true);
		
		PrecacheModel(MDL_PLANT_SHOVEL);
		PrecacheModel(MDL_PLANT_LIGHT);
	}
	
	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �V���x���폜
		DeletePlantShovel( client );
		
		// �^�C�}�[�N���A
		ClearTimer( g_RocketCheckTimer[client] );
		ClearTimer( g_ShovelBatteryRunTimer[client] );
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:attribute3[256];
			new String:attribute4[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_HOMINGROCKET", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_2", client );
			Format( attribute3, sizeof( attribute3 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_3", client, GetConVarFloat( g_BatteryRunTime ) );
			Format( attribute4, sizeof( attribute4 ), "%T", "DESCRIPTION_HOMINGROCKET_ATTRIBUTE_4", client );
			
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );
			// 3�y�[�W��
			Format( g_PlayerHintText[ client ][ 2 ], HintTextMaxSize , "%s\n%s", attribute3, attribute4 );
			
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
	
	// �v���C���[���T�v���C
	if(StrEqual(name, EVENT_PLAYER_RESUPPLY))
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			// �\���W���[
			if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client])
			{
				// ���T�v���C�ɐG������V���x���폜
				if( g_ActiveHoming[client] )
				{
					DeletePlantShovel( client );
				}
				
			}
		}
	}

	return Plugin_Continue;
}



/////////////////////////////////////////////////////////////////////
//
// �t���[�����Ƃ̓���
//
/////////////////////////////////////////////////////////////////////
stock InitRocketData(any:client)
{
	// ���P�b�g�p�̔z��쐬
	for( new i = 0; i < HOMING_ROCKETS_MAX; i++ )
	{
		if( g_RocketsData[client][i] == INVALID_HANDLE )
		{
			g_RocketsData[client][i] = CreateTrie();
		}
	}
	
	// �V���x���p�̔z��쐬
	if( g_ShovelData[client] == INVALID_HANDLE )
	{
		g_ShovelData[client] = CreateTrie();
	}	
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
		// �\���W���[
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client])
		{
			// �V���ɃV���x���擾������h�����V���x���폜
//			if( TF2_GetItemDefIndex( GetPlayerWeaponSlot(client, 2) ) == _:ITEM_WEAPON_SHOVEL )
//			{
//				if( g_ActiveHoming[client] )
//				{
//					DeletePlantShovel( client );
//				}
//			}
			
			// �z�[�~���O�`�F�b�N
			HomingCheck(client);
			
			// �L�[�`�F�b�N
			if( CheckElapsedTime(client, 0.5) )
			{
				// �U���{�^��2
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// �L�[�����������Ԃ�ۑ�
					SaveKeyTime(client);
					
					// �`�F�b�N������
					HomingRocket(client);
				}
			}			
		}	
	}
	
}




/////////////////////////////////////////////////////////////////////
//
// �z�[�~���O����(�V���x������)
//
/////////////////////////////////////////////////////////////////////
stock HomingRocket( any:client )
{
	// ���킪�X�R�b�v�̂Ƃ�
	if( TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_SHOVEL )
	{
		// �����̃G���e�B�e�B
		new groundEnt = GetEntPropEnt( client, Prop_Data, "m_hGroundEntity" );
		if( groundEnt != -1 )
		{
			if( GetEntityMoveType( groundEnt ) == MOVETYPE_VPHYSICS )
			{
				return;
			}
			
			new String:edictName[32];
			GetEdictClassname(groundEnt, edictName, sizeof(edictName));
			if (StrEqual(edictName, "player", false)
			|| StrEqual(edictName, "obj_dispenser", false)
			|| StrEqual(edictName, "obj_teleporter_entrance", false)
			|| StrEqual(edictName, "obj_teleporter_exit", false)
			|| StrEqual(edictName, "obj_sentrygun", false))
			{
				return;
			}
		}
		
		
		// �n�ʂɂ���Ƃ�
		if( GetEntityFlags( client ) & FL_ONGROUND )
		{
			// ���ɐݒu���Ă���V���x�����폜
			DeletePlantShovel( client );
			
			// ���P�b�g�����`���[�Ɏ����ւ��A�e��������΃V���b�g�K���ɁB
			if( TF2_GetSlotAmmo( client, 0 ) > 0 || TF2_GetSlotClip( client, 0 ) > 0 )
			{
				ClientCommand(client, "slot1");
			}
			else
			{
				ClientCommand(client, "slot2");
			}
			
			// �����Ă�V���x�����폜
			new weaponIndex = GetPlayerWeaponSlot(client, 2);
			if( weaponIndex != -1)
			{
				TF2_RemoveWeaponSlot(client, 2);
				//RemovePlayerItem(client, weaponIndex);
				//AcceptEntityInput(weaponIndex, "Kill");		
			}		
				
			new bodyIndex		= -1;
			new lightIndex		= -1;
			new effectIndex		= -1;

			// �n�ʂɎh���V���x���쐬
			bodyIndex = CreateEntityByName("prop_dynamic");
			if ( IsValidEntity( bodyIndex ) )
			{
				SetEntPropEnt	(bodyIndex, Prop_Send, "m_hOwnerEntity", client);	// ������
				SetEntityModel	(bodyIndex, MDL_PLANT_SHOVEL);						// ���f��
				DispatchSpawn	(bodyIndex);										// �X�|�[��
				DispatchKeyValue(bodyIndex, "targetname", "homing_shovel");

				// �p�x�Z�o
				new Float:pos[3];
				new Float:ang[3];
				new Float:eang[3];
				new Float:upVec[3];
				GetClientAbsOrigin(client, pos);								// �v���C���[�̈ʒu�擾
				GetClientEyeAngles(client, eang);								// ������p�x

				ang[0] = -10.0;
				ang[1] = eang[1] + 90.0;
				ang[2] = 175.0;
				pos[2] += 20.0;
				TeleportEntity(bodyIndex, pos, ang, NULL_VECTOR);					// �ړ�
				
				// �n�ʂ��ړ�����^�C�v�Ȃ�e��ݒ�
				if( groundEnt != -1 )
				{
					if( GetEntityMoveType( groundEnt ) == MOVETYPE_PUSH )
					{
						SetVariantString("!activator");
						AcceptEntityInput(bodyIndex, "SetParent", groundEnt, groundEnt, 0);
					}
				}

				
				// ���C�g�쐬
				lightIndex = CreateEntityByName("prop_dynamic");
				if ( IsValidEntity( lightIndex ) )
				{
					SetEntPropEnt	(lightIndex, Prop_Send, "m_hOwnerEntity", client);	// ������
					SetEntityModel	(lightIndex, MDL_PLANT_LIGHT);						// ���f��
					DispatchSpawn	(lightIndex);										// �X�|�[��
					DispatchKeyValue(lightIndex, "targetname", "homing_light");

					GetClientAbsOrigin(client, pos);								// �v���C���[�̈ʒu�擾
					GetClientEyeAngles(client, eang);								// ������p�x
					ang[0] = -10.0;
					ang[1] = eang[1] + 90.0;
					ang[2] = 175.0;
					pos[2] += 20.0;
					
					GetAngleVectors(ang, NULL_VECTOR, NULL_VECTOR, upVec);
					ScaleVector( upVec, -5.0 );
					AddVectors( pos, upVec, pos );
					TeleportEntity(lightIndex, pos, ang, NULL_VECTOR);					// �ړ�
					
					
					// �G�t�F�N�g�𐶐�
					if( GetClientTeam( client ) == _:TFTeam_Red )
					{
						effectIndex = AttachLoopParticle( lightIndex, EFFECT_LIGHT_RED, upVec );
					}
					else
					{
						effectIndex = AttachLoopParticle( lightIndex, EFFECT_LIGHT_BLU, upVec );
					}		

					
					// �ړ��̐e��ݒ�
					if( groundEnt != -1 )
					{
						if( GetEntityMoveType( groundEnt ) == MOVETYPE_PUSH )
						{
							SetVariantString("!activator");
							AcceptEntityInput(lightIndex, "SetParent", groundEnt, groundEnt, 0);
						}
					}

					// �V���x���f�[�^�ݒ�
					SetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
					SetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
					SetTrieValue( g_ShovelData[client], "EffectIndex", effectIndex );
					
					// �`�F�b�N�^�C�}�[�쓮

					ClearTimer( g_RocketCheckTimer[client] );
					g_RocketCheckTimer[client] = CreateTimer( 0.05, Timer_RocketCheck, client );
					
					
					// �ݒu��
					StopSound(bodyIndex, 0, SOUND_PLANT_SHOVEL);
					EmitSoundToAll(SOUND_PLANT_SHOVEL, bodyIndex, _, _, _, 1.0);
					StopSound(bodyIndex, 0, SOUND_SHOVEL_ACTIVE);
					EmitSoundToAll(SOUND_SHOVEL_ACTIVE, bodyIndex, _, _, SND_CHANGEPITCH, 0.5, 10);	

					// ���[�v�T�E���h�J�n
					StopSound(bodyIndex, 0, SOUND_SHOVEL_LOOP);
					EmitSoundToAll(SOUND_SHOVEL_LOOP, bodyIndex, _, _, SND_CHANGEPITCH, 0.3, 180);				
					
					// �A�N�e�B�u
					g_ActiveHoming[client] = true;
					
					// �L�����Ԃ�ݒ�
					ClearTimer( g_ShovelBatteryRunTimer[client] );
					g_ShovelBatteryRunTimer[client] = CreateTimer( GetConVarFloat(g_BatteryRunTime), Timer_ShovelEnd, client );
				}
			}	
		}
	}
	// ����ȊO�̂Ƃ�
	else
	{
		// �߂��ɃV���x������������E��
		if( g_ActiveHoming[client] )
		{
			new bodyIndex		= -1;
			// �V���x���f�[�^�擾
			GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );

			
			new Float:playerPos[3];
			new Float:shovelPos[3];
			GetEntPropVector(client,	Prop_Data,	"m_vecAbsOrigin", playerPos);	
			GetEntPropVector(bodyIndex,	Prop_Data,	"m_vecAbsOrigin", shovelPos);
			
			// 1m�ȓ�
			if( GetVectorDistanceMeter( playerPos, shovelPos ) <= 1.0 )
			{
				// ���b�Z�[�W
				if( g_EndBattery[client] )
				{
					PrintToChat( client, "\x05%T", "MESSAGE_CHANGE_BATTERY", client );
				}
				
				// �E����
				EmitSoundToAll(SOUND_PICKUP_SHOVEL, bodyIndex, _, _, _, 1.0);
				
				// �V���x���폜
				DeletePlantShovel( client );
				
				// �V���x���擾
				TF2_GiveItem( client, ITEM_WEAPON_SHOVEL );
				
				// �V���x���Ɏ���������
				ClientCommand(client, "slot3");
				
				
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �V���x���d�r�؂�
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_ShovelEnd(Handle:timer, any:client)
{
	g_ShovelBatteryRunTimer[client] = INVALID_HANDLE;
	
	if( g_ShovelData[client] == INVALID_HANDLE )
	{
		InitRocketData(client);
	}
	
	new bodyIndex;
	new lightIndex;
	new effectIndex;

	// �V���x���f�[�^�擾
	GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
	GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
	GetTrieValue( g_ShovelData[client], "EffectIndex", effectIndex );

	// �G�t�F�N�g�폜
	DeleteParticle( effectIndex );
	
	// �V���x�����폜
	if( EdictEqual( bodyIndex, "prop_dynamic") )
	{
		// �^�[�Q�b�g���擾�擾
		new String:nameTarget[64];
		GetEntPropString(bodyIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
		
		// �ݒu�����V���x���Ȃ�
		if( StrEqual( nameTarget, "homing_shovel" ) )
		{
			// ���[�v����~
			StopSound(bodyIndex, 0, SOUND_SHOVEL_LOOP);

			// ������
			StopSound(bodyIndex, 0, SOUND_SHOVEL_DEACTIVE);
			EmitSoundToAll(SOUND_SHOVEL_DEACTIVE, bodyIndex, _, _, SND_CHANGEPITCH, 0.3, 180);	
			// �폜
			//RemoveEdict( bodyIndex );
		}
	}

	// �f�[�^�N���A
//	SetTrieValue( g_ShovelData[client], "BodyIndex", -1 );
//	SetTrieValue( g_ShovelData[client], "LightIndex", -1 );
	SetTrieValue( g_ShovelData[client], "EffectIndex", -1 );

	
	// ���P�b�g�f�[�^�N���A
	for( new i = 0; i < HOMING_ROCKETS_MAX; i++ )
	{
		// �c���Ă���G�t�F�N�g�폜
		new effIndex;
		GetTrieValue( g_RocketsData[_:client][i], "Effect", effIndex )
		DeleteParticle( effIndex );
    
		// �f�[�^������
		SetTrieValue( g_RocketsData[client][i], "Index", -1 );		// �G���e�B�e�B�C���f�b�N�X
		SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );		// �z�[�~���O���x
		SetTrieValue( g_RocketsData[client][i], "Effect", -1);		// �G�t�F�N�g
	}
	
	// �o�b�e���[�؂�
	g_EndBattery[client] = true;
	
	// ���b�Z�[�W
	PrintToChat( client, "\x05%T", "MESSAGE_OUT_OF_BATTERY", client );
}


/////////////////////////////////////////////////////////////////////
//
// �V���x���폜
//
/////////////////////////////////////////////////////////////////////
stock DeletePlantShovel( client )
{
	if( g_ShovelData[client] == INVALID_HANDLE )
	{
		InitRocketData(client);
	}
	
	new bodyIndex;
	new lightIndex;
	new effectIndex;

	// �V���x���f�[�^�擾
	GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
	GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
	GetTrieValue( g_ShovelData[client], "EffectIndex", effectIndex );

	// �G�t�F�N�g�폜
	DeleteParticle( effectIndex );
	
	// �V���x�����폜
	if( EdictEqual( bodyIndex, "prop_dynamic") )
	{
		// �^�[�Q�b�g���擾�擾
		new String:nameTarget[64];
		GetEntPropString(bodyIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
		
		// �ݒu�����V���x���Ȃ�폜
		if( StrEqual( nameTarget, "homing_shovel" ) )
		{
			if( !g_EndBattery[client] )
			{
				// ���[�v����~
				StopSound(bodyIndex, 0, SOUND_SHOVEL_LOOP);

				// ������
				StopSound(bodyIndex, 0, SOUND_SHOVEL_DEACTIVE);
				EmitSoundToAll(SOUND_SHOVEL_DEACTIVE, bodyIndex, _, _, SND_CHANGEPITCH, 0.3, 180);	
			}
			else
			{
				ClearTimer( g_ShovelBatteryRunTimer[client] );
			}
			
			// �폜
			AcceptEntityInput(bodyIndex, "Kill");
		}
	}

	// ���C�g���폜
	if( EdictEqual( lightIndex, "prop_dynamic") )
	{
		// �^�[�Q�b�g���擾�擾
		new String:nameTarget[64];
		GetEntPropString(lightIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
		
		// �ݒu�����V���x���Ȃ�폜
		if( StrEqual( nameTarget, "homing_light" ) )
		{
			// �폜
			AcceptEntityInput(lightIndex, "Kill");		
		}
	}
	
	// �f�[�^�N���A
	SetTrieValue( g_ShovelData[client], "BodyIndex", -1 );
	SetTrieValue( g_ShovelData[client], "LightIndex", -1 );
	SetTrieValue( g_ShovelData[client], "EffectIndex", -1 );

	
	// ���P�b�g�f�[�^�N���A
	for( new i = 0; i < HOMING_ROCKETS_MAX; i++ )
	{
		// �c���Ă���G�t�F�N�g�폜
		new effIndex;
		GetTrieValue( g_RocketsData[_:client][i], "Effect", effIndex )
		DeleteParticle( effIndex );
    
		// �f�[�^������
		SetTrieValue( g_RocketsData[client][i], "Index", -1 );		// �G���e�B�e�B�C���f�b�N�X
		SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );		// �z�[�~���O���x
		SetTrieValue( g_RocketsData[client][i], "Effect", -1);		// �G�t�F�N�g
	}
	
	// �d�r�؂�^�C�}�[�폜
	ClearTimer( g_ShovelBatteryRunTimer[client] );
	
	// ��A�N�e�B�u
	g_ActiveHoming[client] = false;
	g_EndBattery[client] = false;
}

/////////////////////////////////////////////////////////////////////
//
// �z�[�~���O���P�b�g
//
/////////////////////////////////////////////////////////////////////
stock HomingCheck(any:client)
{
	if( g_ActiveHoming[client] && g_RocketCheckTimer[client] == INVALID_HANDLE)
	{
		new bodyIndex		= -1;
		new lightIndex		= -1;
		// �V���x���f�[�^�擾
		GetTrieValue( g_ShovelData[client], "BodyIndex", bodyIndex );
		GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
		
		if( EdictEqual( bodyIndex, "prop_dynamic") )
		{
			new String:nameTarget[64];
			GetEntPropString( bodyIndex, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
			
			// �ݒu�����V���x��������I
			if( StrEqual( nameTarget, "homing_shovel" ) )
			{
				new Float:RocketPos[3];	// ���P�b�g�̈ʒu
				new Float:RocketAng[3];	// ���P�b�g�̊p�x
				new Float:RocketVec[3];	// ���P�b�g�̕���
				
				new Float:TargetPos[3];		// �^�[�Q�b�g�̈ʒu
				new Float:TargetVec[3];		// �^�[�Q�b�g�ւ̕���
				
				new Float:MiddleVec[3];		// ���ԃx�N�g��
				
				// �V���x���̈ʒu�擾
				GetEntPropVector( lightIndex, Prop_Data, "m_vecAbsOrigin", TargetPos );
				
				
				// ���P�b�g���X�g
				for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
				{
					new index;				
					new accuracy;				
					GetTrieValue( g_RocketsData[client][i], "Index", index );
					GetTrieValue( g_RocketsData[client][i], "Accuracy", accuracy );
					// ���˂��ꂽ���P�b�g������H
					if( EdictEqual( index, "tf_projectile_rocket") )
					{
						// ������͎�����
						new iOwner = GetEntPropEnt( index, Prop_Send, "m_hOwnerEntity" );
						if( client == iOwner )
						{
							// ���P�b�g�̃f�[�^�ǂݍ���
							GetEntPropVector( index, Prop_Data, "m_vecAbsOrigin", RocketPos );		// ���P�b�g�̈ʒu
							GetEntPropVector( index, Prop_Data, "m_angRotation", RocketAng );		// ���P�b�g�̊p�x
							GetEntPropVector( index, Prop_Data, "m_vecAbsVelocity", RocketVec );	// ���P�b�g�̕���

							new Float:RocketSpeed = GetVectorLength( RocketVec ); // ���P�b�g�̃X�s�[�h
							
							// ���P�b�g�ƃ^�[�Q�b�g�̊p�x�𒲂ׂ�
							SubtractVectors( TargetPos, RocketPos, TargetVec );	// �^�[�Q�b�g�܂ł̕��� 
							
							// ���P�b�g�̐��x����
							AddVectors( RocketVec, TargetVec, MiddleVec );
							for( new j=0; j < accuracy; j++ )
							{
								AddVectors( RocketVec, MiddleVec, MiddleVec );
							}
							AddVectors( RocketVec, MiddleVec, RocketVec );
							
							NormalizeVector( RocketVec, RocketVec );
							
							// ���P�b�g�̊p�x���㏑��
							GetVectorAngles( RocketVec, RocketAng );
							SetEntPropVector( index, Prop_Data, "m_angRotation", RocketAng);

							// ���P�b�g�̕������㏑��
							ScaleVector( RocketVec, RocketSpeed );
							SetEntPropVector( index, Prop_Data, "m_vecAbsVelocity", RocketVec );
							
							if(accuracy > GetConVarInt(g_FinalAccuracy))
							{
								accuracy -= 1;
							}
							SetTrieValue( g_RocketsData[client][i], "Accuracy", accuracy );
						}								
					}
					
				}
			}	
		}
	}
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

	// �\���W���[�̂Ƃ��̂�
	if( TF2_GetPlayerClass(client) == TFClass_Soldier )
	{
		// ���P�b�g�����`���[
		if( StrEqual( weaponname, "tf_weapon_rocketlauncher") || StrEqual( weaponname, "tf_weapon_rocketlauncher_directhit"))
		{
			if( g_ActiveHoming[client] )
			{
				// �`�F�b�N���Ȃ����Ԑݒ�
				ClearTimer( g_RocketCheckTimer[client] );
				g_RocketCheckTimer[client] = CreateTimer( 0.05, Timer_RocketCheck, client );
			}
		}
		
	}
	

	return Plugin_Continue;	
}

/////////////////////////////////////////////////////////////////////
//
// ���P�b�g�`�F�b�N
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_RocketCheck(Handle:timer, any:client)
{
	g_RocketCheckTimer[client] = INVALID_HANDLE;
	
	if( g_ActiveHoming[client] && !g_EndBattery[client] )
	{
		// ���P�b�g����Ȃ����̂̓N���A
		for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
		{		
			new bool:valid = true;
			
			new index;				
			// �f�[�^�����P�b�g���`�F�b�N
			GetTrieValue( g_RocketsData[client][i], "Index", index );			
			
			if( !EdictEqual( index, "tf_projectile_rocket") )
			{
				valid = false;
			}
			else
			{
				// �^�[�Q�b�g���擾�擾
				new String:nameTarget[64];
				GetEntPropString(index, Prop_Data, "m_iName", nameTarget, sizeof(nameTarget));
				if( !StrEqual( nameTarget, "homing_rocket" ) )
				{
					valid = false;
				}
				
			}
			
			if( !valid )
			{
				new effect;
				// �G�t�F�N�g���폜
				GetTrieValue( g_RocketsData[client][i], "Effect", effect);	
				DeleteParticle(effect);
				
				// �f�[�^���N���A
				SetTrieValue( g_RocketsData[client][i], "Index", -1 );									// �G���e�B�e�B�C���f�b�N�X
				SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );	// �z�[�~���O���x	
				SetTrieValue( g_RocketsData[client][i], "Effect", -1);									// �G�t�F�N�g				
				//PrintToChat(client, "rocket = %d", index)				
			}
		}
		
		new lightIndex		= -1;
		// �V���x���f�[�^�擾
		GetTrieValue( g_ShovelData[client], "LightIndex", lightIndex );
		StopSound(lightIndex, 0, SOUND_SHOVEL_ACTIVE);
		EmitSoundToAll(SOUND_SHOVEL_ACTIVE, lightIndex, _, _, SND_CHANGEPITCH, 0.5, 10);	

		// ���P�b�g������
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1)
		{
			// ���˂����z�̂�
			new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
			if(client == iOwner)
			{
				// �f�[�^���o�^����Ă��邩�`�F�b�N
				new bool:hasData = false;
				for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
				{				
					new index;				
					GetTrieValue( g_RocketsData[client][i], "Index", index );
					// �q�b�g�H
					if( ent == index )
					{
						hasData = true;
					}
				}
				
				// �q�b�g�Ȃ��Ȃ�f�[�^�o�^
				if( !hasData )
				{
					// �����Ă�ꏊ��T���ēo�^
					for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
					{				
						new index;				
						GetTrieValue( g_RocketsData[client][i], "Index", index );
						if( index == -1 )
						{
							// ���ʗp�̖��O
							DispatchKeyValue(ent, "targetname", "homing_rocket");
							
							// �󂫂�����������o�^
							SetTrieValue( g_RocketsData[client][i], "Index", ent );									// �G���e�B�e�B�C���f�b�N�X
							SetTrieValue( g_RocketsData[client][i], "Accuracy", GetConVarInt(g_StartAccuracy) );		// �z�[�~���O���x	
							
							// �G�t�F�N�g����
							new effect;
							if( GetClientTeam( client ) == _:TFTeam_Red )
							{
								effect = AttachLoopParticle( ent, EFFECT_BEAM_RED );
							}
							else
							{
								effect = AttachLoopParticle( ent, EFFECT_BEAM_BLU );
							}
							SetEntPropEnt(effect, Prop_Data, "m_hControlPointEnts", lightIndex);
							
							SetTrieValue( g_RocketsData[client][i], "Effect", effect);			// �G�t�F�N�g	
							
							StopSound(ent, 0, SOUND_ROCKET_LAUNCH);
							EmitSoundToAll(SOUND_ROCKET_LAUNCH, ent, _, _, SND_CHANGEPITCH, 0.5, 80);	

							break;
						}
					}
				}
				
			}
		}
	}
}


/////////////////////////////////////////////////////////////////////
//
// ���x
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Accuracy(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0�`100�܂�
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 100");
	}
}
