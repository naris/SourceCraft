/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.0.7
// �E1.3.1�ŃR���p�C��
// 2009/10/06 - 0.0.6
// �E����������ύX
// 2009/09/04 - 0.0.5
// �E�A�t�^�[�o�[�i�[�̉��ŔR����悤�ɂ���
// �Esm_rmf_afterburner_burn_enemy��ǉ�
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
#define PL_NAME "After Burner"
#define PL_DESC "After Burner"
#define PL_VERSION "0.0.7"
#define PL_TRANSLATION "afterburner.phrases"


#define SOUND_BURNER_START "weapons/flame_thrower_airblast.wav"
#define SOUND_BURNER_LOOP "weapons/flame_thrower_loop.wav"
#define SOUND_BURNER_END "weapons/flame_thrower_end.wav"
#define SOUND_BURNER_EMPTY "weapons/syringegun_reload_air2.wav"
#define SOUND_BURNER_VOICE "vo/pyro_laughevil01.wav"

#define EFFECT_BURNER_RED "flamethrower_crit_red"
#define EFFECT_BURNER_BLU "flamethrower_crit_blue"
#define EFFECT_BURNER_EMPTY "muzzle_minigun"
#define EFFECT_BURNER_WARP "pyro_blast_warp"
#define EFFECT_BURNER_WARP2 "pyro_blast_warp2"

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
new Handle:g_BurnerAmmoCount = INVALID_HANDLE;		// ����e��
new Handle:g_BurnerUpMulti = INVALID_HANDLE;		// �㏸�{��
new Handle:g_BurnerFallMulti = INVALID_HANDLE;		// �����{��
new Handle:g_BurnEnemy = INVALID_HANDLE;			// �R���邩�ǂ���
new bool:g_BurnerState[MAXPLAYERS+1] = false;		// �o�[�i�[�̏��
new g_BurnerParticle[MAXPLAYERS+1] = -1;			// �o�[�i�[�̃G�t�F�N�g�G���e�B�e�B
new g_BurnerCount[MAXPLAYERS+1] = 0;				// �o�[�i�[�̃J�E���g

new bool:g_FirstJump[MAXPLAYERS+1] = false;			// ����W�����v�����H
new bool:g_ReleaseButton[MAXPLAYERS+1] = false;		// �L�[�͂Ȃ����H
new bool:g_AlreadyBurnered[MAXPLAYERS+1] = false;		// �L�[�͂Ȃ����H

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
		CreateConVar("sm_rmf_tf_afterburner", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_afterburner","1","After Burner Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		
		// �p�C��
		g_BurnerAmmoCount	= CreateConVar("sm_rmf_afterburner_use_ammo",	"4",	"Ammo required (0-200)");
		g_BurnerUpMulti		= CreateConVar("sm_rmf_afterburner_up_mag",		"1.45",	"Up velocity magnification (0.0-10.0)");
		g_BurnerFallMulti	= CreateConVar("sm_rmf_afterburner_fall_mag",	"0.85",	"Fall velocity magnification (0.0-10.0)");
		g_BurnEnemy			= CreateConVar("sm_rmf_afterburner_burn_enemy",	"1",	"Burn enemy when hit After Burner's flame (0 = disabled | 1 = enabled)");

		HookConVarChange(g_BurnerAmmoCount,	ConVarChange_Ammo);
		HookConVarChange(g_BurnerUpMulti,	ConVarChange_Magnification);
		HookConVarChange(g_BurnerFallMulti,	ConVarChange_Magnification);	
		HookConVarChange(g_BurnEnemy,		ConVarChange_Bool);	
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_afterburner_class", "7", "Ability class");
	}

	
	
	// �v���O�C��������
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// ���������K�v�Ȃ���
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBurnerParticle(i);
		}
	
	}
	
	// �v���O�C����n��
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBurnerParticle(i);
		}
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			DeleteBurnerParticle(i);
		}
		
		PrePlayParticle(EFFECT_BURNER_RED);
		PrePlayParticle(EFFECT_BURNER_BLU);
		PrePlayParticle(EFFECT_BURNER_EMPTY);
		PrePlayParticle(EFFECT_BURNER_WARP);
		PrePlayParticle(EFFECT_BURNER_WARP2);
		
		PrecacheSound(SOUND_BURNER_START, true);
		PrecacheSound(SOUND_BURNER_LOOP, true);
		PrecacheSound(SOUND_BURNER_END, true);
		PrecacheSound(SOUND_BURNER_EMPTY, true);
		PrecacheSound(SOUND_BURNER_VOICE, true);
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
		// �o�[�i�[OFF
		g_BurnerState[client]=false;
		DeleteBurnerParticle(client);	
		StopSound(client, 0, SOUND_BURNER_LOOP);
		g_FirstJump[client] = false;
		g_ReleaseButton[client] = false;
		g_AlreadyBurnered[client] = false;
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];

			// �A�r���e�B��
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_AFTERBURNER", client );
			// �A�g���r���[�g
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_AFTERBURNER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_AFTERBURNER_ATTRIBUTE_1", client );
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_AFTERBURNER_ATTRIBUTE_2", client );
			
			
			// 1�y�[�W��
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2�y�[�W��
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );

		}
	}
		

	// �ؒf
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		DeleteBurnerParticle(client);	
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
		// �p�C��
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro && g_AbilityUnlock[client])
		{
			if( CheckElapsedTime(client, 0.09) )
			{
				// �A�t�^�[�o�[�i�[
				AfterBurner(client);
			}

		}

	}

}

/////////////////////////////////////////////////////////////////////
//
// �p�C���A�t�^�[�o�[�i�[
//
/////////////////////////////////////////////////////////////////////
public AfterBurner(any:client)
{
	// �󒆃W�����v
	if ( GetClientButtons(client) & IN_JUMP)
	{
		// �L�[�����������Ԃ�ۑ�
		SaveKeyTime(client);
		
		if( !(GetEntityFlags(client) & FL_ONGROUND) )
		{
			// �����܂ł̃J�E���gON
			g_BurnerCount[client] += 1;
			if( g_FirstJump[client] && g_ReleaseButton[client] )
			{

				//new iWeapon = GetPlayerWeaponSlot(client, 0);//GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
				new offset = FindDataMapOffs(client, "m_iAmmo") + (1 * 4);
				new nowAmmo = GetEntData(client, offset, 4);

				if( !g_BurnerState[client] )
				{
					if( nowAmmo > 0)
					{
						g_BurnerState[client] = true;
						
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						if(fVelocity[2] >= -300.0 && !g_AlreadyBurnered[client])
						{
							fVelocity[2] = 250.0;
							SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						}
						
						StopSound(client, 0, SOUND_BURNER_START);
						EmitSoundToAll(SOUND_BURNER_START, client, _, _, SND_CHANGEPITCH, 0.3, 150);
						CreateTimer(0.02, Timer_StartBurnerLoopSound, client);

						EmptyBurnerEffect(client);
						SetBurnerParticle(client);
						
						// �ڂ��G�t�F�N�g
						new Float:ang[3];
						ang[0] = -25.0;
						ang[1] = 90.0;
						new Float:pos[3];
						pos[1] = 10.0;
						pos[2] = 1.0;
						
						AttachParticleBone(client, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);	
						AttachParticleBone(client, EFFECT_BURNER_WARP, "flag", 0.15, pos, ang);	
						AttachParticleBone(client, EFFECT_BURNER_WARP2, "flag", 0.15, pos, ang);	
						
						// �e�����
						nowAmmo -= GetConVarInt(g_BurnerAmmoCount);
						if(nowAmmo < 0)
						{
							nowAmmo = 0;
						}
						SetEntData(client, offset, nowAmmo);
					}
					else
					{
						g_BurnerCount[client] = 0;
						g_BurnerState[client] = false;
						DeleteBurnerParticle(client);
						if( !g_AlreadyBurnered[client] )
						{
							StopSound(client, 0, SOUND_BURNER_LOOP);
							StopSound(client, 0, SOUND_BURNER_END);
							StopSound(client, 0, SOUND_BURNER_EMPTY);
							EmitSoundToAll(SOUND_BURNER_END, client, _, _, SND_CHANGEPITCH, 0.3, 120);
							EmitSoundToAll(SOUND_BURNER_EMPTY, client, _, _, SND_CHANGEPITCH, 0.4, 80);
							EmptyBurnerEffect(client);
						}
					}
					g_AlreadyBurnered[client] = true;
					
				}
				else
				{
					if( nowAmmo > 0 && !(GetEntityFlags(client) & FL_INWATER))
					{
						
						// �e�����
						nowAmmo -= GetConVarInt(g_BurnerAmmoCount);
						if(nowAmmo < 0)
						{
							nowAmmo = 0;
						}
						SetEntData(client, offset, nowAmmo);
						
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						if(fVelocity[2] >= 0)
						{
							if(fVelocity[2] < 230.0)
							{
								fVelocity[2] *= GetConVarFloat(g_BurnerUpMulti);//1.18;
							}
						}
						else
						{
							fVelocity[2] *= GetConVarFloat(g_BurnerFallMulti);
						}
						SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
						
						
						if(GetConVarBool(g_BurnEnemy))
						{
							// ���ɂ����R�₷
							new Float:clientPos[3];
							new Float:clientAng[3];
							new Float:targetPos[3];
							new Float:targetAng[3];
							new Float:diffYaw = 0.0;
							// �N���C�A���g�̈ʒu�Ɗp�x
							GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", clientPos);
							GetEntPropVector(client, Prop_Data, "m_angRotation", clientAng);
		
							new maxclients = GetMaxClients();
							for (new i = 1; i <= maxclients; i++)
							{
								// �����Ă�^�[�Q�b�g�̂�
								if(IsClientInGame(i) && IsPlayerAlive(i))
								{
									// �`�[�����Ⴄ
									if(client != i && GetClientTeam(client) != GetClientTeam(i))
									{
										// �^�[�Q�b�g�̈ʒu
										GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", targetPos);
										// �^�[�Q�b�g�ւ̊p�x
										SubtractVectors(clientPos, targetPos, targetAng);
										GetVectorAngles(targetAng, targetAng);	
										diffYaw = (targetAng[1] - 180.0) - clientAng[1];
										diffYaw = FloatAbs(diffYaw);	
										
										if( diffYaw >= 120.0 && diffYaw < 165.0 )
										{
											if(CanSeeTarget(client, clientPos, i, targetPos, 5.0, true, false))
											{
												// �R�₷
												TF2_IgnitePlayer(i, client);
											}
										}
									}
									
								}
							}
						}
						
					}
					else
					{
						g_BurnerCount[client] = 0;
						g_BurnerState[client] = false;
						DeleteBurnerParticle(client);
						StopSound(client, 0, SOUND_BURNER_LOOP);
						EmitSoundToAll(SOUND_BURNER_END, client, _, _, SND_CHANGEPITCH, 0.3, 120);
						EmitSoundToAll(SOUND_BURNER_EMPTY, client, _, _, SND_CHANGEPITCH, 0.4, 80);
						EmptyBurnerEffect(client);
					}

				}
			}
							
			g_FirstJump[client] = true;

		}
		else
		{
			g_FirstJump[client] = false;
		}

	}
	else
	{
		if(g_FirstJump[client])
		{
			g_ReleaseButton[client] = true;
		}

	}
	
	if( (GetEntityFlags(client) & FL_ONGROUND) || (GetEntityFlags(client) & FL_INWATER))
	{
		g_FirstJump[client] = false;
		g_ReleaseButton[client] = false;
		g_AlreadyBurnered[client] = false;
	}
	
	if( !(GetClientButtons(client) & IN_JUMP) || GetEntityFlags(client) & FL_ONGROUND )
	{
		g_BurnerCount[client] = 0;

		if( g_BurnerState[client] )
		{
			g_BurnerState[client] = false;
			DeleteBurnerParticle(client);
			StopSound(client, 0, SOUND_BURNER_LOOP);
			EmitSoundToAll(SOUND_BURNER_END, client, _, _, SND_CHANGEPITCH, 0.3, 120);
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �p�[�e�B�N���Z�b�g
//
/////////////////////////////////////////////////////////////////////
public SetBurnerParticle(any:client)
{
	if( client > 0 )
	{
		if( IsClientInGame(client) && GetClientTeam(client) > 1 && TF2_GetPlayerClass( client ) == TFClass_Pyro)
		{	
			new Float:ang[3];
			ang[0] = -25.0;
			ang[1] = 90.0;
			
			if(TFTeam:GetClientTeam(client) == TFTeam_Red)
	    	{
				g_BurnerParticle[client] = AttachLoopParticleBone(client, EFFECT_BURNER_RED, "flag", NULL_VECTOR, ang);
	    	}
			else
			{
				g_BurnerParticle[client] = AttachLoopParticleBone(client, EFFECT_BURNER_BLU, "flag", NULL_VECTOR, ang);
			}
			
		}
		else
		{
	    	DeleteBurnerParticle(client);
		}
	}

}
/////////////////////////////////////////////////////////////////////
//
// �p�[�e�B�N���폜
//
/////////////////////////////////////////////////////////////////////
stock DeleteBurnerParticle(any:client)
{
	if (g_BurnerParticle[client] != -1)
	{
		if(IsValidEdict(g_BurnerParticle[client]))
		{
			DeleteParticle(g_BurnerParticle[client])
			// ActivateEntity(g_BurnerParticle[client]);
			//AcceptEntityInput(g_BurnerParticle[client], "stop");
			//DeleteParticles(0.01, g_BurnerParticle[client]);
			//CreateTimer(0.01, DeleteParticles, g_BurnerParticle[client]);
			g_BurnerParticle[client] = -1;
		}
	}
} 

////////////////////////////////////////
//
// ����ڃG�t�F�N�g
//
////////////////////////////////////////
public EmptyBurnerEffect(client)
{
	new Float:ang[3];
	ang[0] = -25.0;
	ang[1] = 90.0;
	new Float:pos[3];
	pos[1] = 10.0;
	pos[2] = 1.0;
	
	AttachParticleBone(client, EFFECT_BURNER_EMPTY, "flag", 0.15, pos, ang);	
}
/////////////////////////////////////////////////////////////////////
//
// ���[�v�T�E���h�J�n�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_StartBurnerLoopSound(Handle:timer, any:client)
{
	if(g_BurnerState[client])
	{
		EmitSoundToAll(SOUND_BURNER_LOOP, client, _, _, SND_CHANGEPITCH, 0.3, 120);
		
		// ���łɃ{�C�X
		EmitSoundToAll(SOUND_BURNER_VOICE, client, _, _, SND_CHANGEPITCH, 0.8, 100);
	}
}
