/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
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
#define PL_NAME "Adrenalin Dash"
#define PL_DESC "Adrenalin Dash"
#define PL_VERSION "0.0.4"
#define PL_TRANSLATION "adrenalindash.phrases"

#define SOUND_DASH_ENABLE "weapons/explode2.wav"
#define SOUND_DASH_END "player/pl_scout_dodge_tired.wav"
#define SOUND_DASH_HIT "player/crit_received3.wav"
#define SOUND_DASH_HIT_VOICE "vo/taunts/soldier_taunts01.wav"

#define EFFECT_EXPLODE_DEBRIS "Explosion_Debris001"
#define EFFECT_EXPLODE_DUSTUP "Explosion_Dustup"
#define EFFECT_EXPLODE_DUSTUP2 "Explosion_Dustup_2"
#define EFFECT_EXPLODE_SMOKE "Explosion_Smoke_1"
#define EFFECT_FOOT_FLAME "rocketjump_flame"
#define EFFECT_EXPLODE_SMOKE1 "Explosion_Smoke_1"


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
new Handle:g_DashTime = INVALID_HANDLE;						// ConVar�_�b�V������
new Handle:g_DamageMag = INVALID_HANDLE;					// ConVar�_���[�W�{��

new Handle:g_TauntTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �����`�F�b�N�^�C�}�[
new Handle:g_DashEnd[MAXPLAYERS+1] = INVALID_HANDLE;		// �_�b�V���I���^�C�}�[
new Handle:g_KeyCheckTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// �G�t�F�N�g�J�n�^�C�}�[

new g_EffectCount[MAXPLAYERS+1] = 0;						// �G�t�F�N�g�J�E���g
new bool:g_EffectON[MAXPLAYERS+1] = false;					// �G�t�F�N�g�`�F�b�N
new Float:g_BeforAngle[MAXPLAYERS+1] = 0.0; 				// �O�̊p�x
new g_NowHealth[MAXPLAYERS+1] = 0; 							// ���݂̃w���X

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
		CreateConVar("sm_rmf_tf_adrenalindash", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_adrenalindash","1","Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_DashTime = CreateConVar("sm_rmf_adrenalindash_dash_time","4.0","Dash time (1.0-10.0)");
		g_DamageMag = CreateConVar("sm_rmf_adrenalindash_damage_mag","0.2","Damage magnification (0.1-5.0)");
		HookConVarChange(g_DashTime, ConVarChange_DashTime);
		HookConVarChange(g_DamageMag, ConVarChange_DashMag);

		// �����R�}���h�Q�b�g
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_adrenalindash_class", "3", "Ability class");
	}
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrePlayParticle(EFFECT_EXPLODE_DEBRIS);
		PrePlayParticle(EFFECT_EXPLODE_DUSTUP);
		PrePlayParticle(EFFECT_EXPLODE_DUSTUP2);
		PrePlayParticle(EFFECT_EXPLODE_SMOKE);
		PrePlayParticle(EFFECT_FOOT_FLAME);
		PrePlayParticle(EFFECT_EXPLODE_SMOKE1);
		
		PrecacheSound(SOUND_DASH_ENABLE, true);
		PrecacheSound(SOUND_DASH_END, true);
		PrecacheSound(SOUND_DASH_HIT, true);
		PrecacheSound(SOUND_DASH_HIT_VOICE, true);
	}

	// �v���C���[�f�[�^���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �^�C�}�[�N���A
		if(g_TauntTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_TauntTimer[client]);
			g_TauntTimer[client] = INVALID_HANDLE;
		}
		
		// �^�C�}�[�N���A
		if(g_DashEnd[client] != INVALID_HANDLE)
		{
			KillTimer(g_DashEnd[client]);
			g_DashEnd[client] = INVALID_HANDLE;
		}
		
		// �^�C�}�[�N���A
		if(g_KeyCheckTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_KeyCheckTimer[client]);
			g_KeyCheckTimer[client] = INVALID_HANDLE;
		}

		g_EffectON[client] = false;
		g_EffectCount[client] = 0;
		g_BeforAngle[client] = 0.0;
		
		// �f�t�H���g�X�s�[�h
		TF2_SetPlayerDefaultSpeed(client);
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier)
		{
			Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_0_ADRENALINDASH", client);
			//Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_ADRENALINDASH", client);
			if(GetConVarFloat(g_DamageMag) != 1.0)
			{
				Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_ADRENALINDASH", client, RoundFloat(FloatAbs(GetConVarFloat(g_DamageMag) * 100.0 - 100.0)));
			}
		}
		
		g_NowHealth[client] = GetClientHealth(client);
	}

	// �v���C���[�_���[�W
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier )
		{
			if(g_DashEnd[client] != INVALID_HANDLE)
			{
				new damage = g_NowHealth[client] - GetEventInt(event, "health");
				SetEntityHealth(client, g_NowHealth[client] - RoundFloat(damage * GetConVarFloat(g_DamageMag)));
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
// �t���[�����Ƃ̓���
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �\���W���[
		if( TF2_GetPlayerClass( client ) == TFClass_Soldier && g_AbilityUnlock[client])
		{
			// �w���X�ۑ�
			g_NowHealth[client] = GetClientHealth(client);
			
			if(g_DashEnd[client] != INVALID_HANDLE)
			{
				if ( GetClientButtons(client) & IN_FORWARD )
				{
					if( CheckElapsedTime(client, 0.25) )
					{
						// �L�[�����������Ԃ�ۑ�
						SaveKeyTime(client);
						
						// �����ʒu�擾
						if(!g_EffectON[client])
						{
							PlayFirstEffect(client);
							new Float:ang[3];
							GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", ang);
							GetVectorAngles(ang, ang);
							g_BeforAngle[client] = FloatAbs(ang[1]);
						}
					}
				
					
					// ��
					PlayDashEffect(client);
					
					// �̓�����`�F�b�N
					HitCheck(client);

					
				}
			}
		}	
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// �̓�����`�F�b�N
//
/////////////////////////////////////////////////////////////////////
stock HitCheck(client)
{
	if(g_EffectON[client])
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) && i != client && (GetClientTeam(i) != GetClientTeam(client)))
			{
				new Float:fPlayerPos[3];
				new Float:fEnemyPos[3];
				new Float:dist;
				GetEntPropVector(client, Prop_Data, "m_vecOrigin", fPlayerPos);
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fEnemyPos);
				dist = GetVectorDistanceMeter(fPlayerPos, fEnemyPos);
				if(dist < 2.0)
				{
					//PrintToChat(client, "%f", dist);
					// �v���C���[�̃x�N�g���������擾
					new Float:fKnockVelocity[3];
					// �����̕����擾
					SubtractVectors(fPlayerPos, fEnemyPos, fKnockVelocity);
					NormalizeVector(fKnockVelocity, fKnockVelocity); 
					ScaleVector(fKnockVelocity, -500.0); 
					fKnockVelocity[2] = 800.0;
					SetEntPropVector(i, Prop_Data, "m_vecAbsVelocity", fKnockVelocity);
					StopSound(client, 0, SOUND_DASH_HIT);
					EmitSoundToAll(SOUND_DASH_HIT, i, _, _, SND_CHANGEPITCH, 1.0, 90);
					EmitSoundToAll(SOUND_DASH_HIT_VOICE, client, _, _, SND_CHANGEPITCH, 1.0, 100);

				}
			}
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
	
	if(TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		AdrenalinDash(client);
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// ����
//
/////////////////////////////////////////////////////////////////////
public AdrenalinDash(any:client)
{
	// �V���x���̂�
	if(TF2_CurrentWeaponEqual(client, "CTFShovel"))
	{
		StopSound(client, 0, SOUND_DASH_END);
		if(g_TauntTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_TauntTimer[client]);
			g_TauntTimer[client] = INVALID_HANDLE;
		}
		g_TauntTimer[client] = CreateTimer(4.0, Timer_TauntEnd, client);
		
		if(g_DashEnd[client] != INVALID_HANDLE)
		{
			KillTimer(g_DashEnd[client]);
			g_DashEnd[client] = INVALID_HANDLE;
		}
		
		if(g_KeyCheckTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_KeyCheckTimer[client]);
			g_KeyCheckTimer[client] = INVALID_HANDLE;
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
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_AbilityUnlock[client])
	{
		if(TF2_IsPlayerTaunt(client))
		{
			if(g_DashEnd[client] != INVALID_HANDLE)
			{
				KillTimer(g_DashEnd[client]);
				g_DashEnd[client] = INVALID_HANDLE;
			}
			g_DashEnd[client] = CreateTimer(GetConVarFloat(g_DashTime), Timer_DashEnd, client);

			if(g_KeyCheckTimer[client] != INVALID_HANDLE)
			{
				KillTimer(g_KeyCheckTimer[client]);
				g_KeyCheckTimer[client] = INVALID_HANDLE;
			}
			g_KeyCheckTimer[client] = CreateTimer(0.5, Timer_EndCheck, client);

			g_EffectON[client] = false;
			
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �����\�H
//
/////////////////////////////////////////////////////////////////////
stock bool:IsPossibleDash(any:client)
{
	if((GetClientButtons(client) & IN_FORWARD) && !(GetClientButtons(client) & IN_MOVELEFT) && !(GetClientButtons(client) & IN_MOVERIGHT) && (GetEntityFlags(client) & FL_ONGROUND))
	{
		return true;
	}
	return false;
}

/////////////////////////////////////////////////////////////////////
//
// �����G�t�F�N�g����
//
/////////////////////////////////////////////////////////////////////
stock PlayFirstEffect(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_DashEnd[client] != INVALID_HANDLE && IsPossibleDash(client))
		{
			StopSound(client, 0, SOUND_DASH_ENABLE);
			EmitSoundToAll(SOUND_DASH_ENABLE, client, _, _, SND_CHANGEPITCH, 0.5, 200);
			TF2_SetPlayerSpeed(client, 400.0);
			
			new Float:ang[3];
			ang[1] = 180.0;
			
			ShowParticleEntity(client, EFFECT_EXPLODE_DUSTUP, 5.0, NULL_VECTOR, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_DUSTUP, 5.0, NULL_VECTOR, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_DUSTUP2, 5.0, NULL_VECTOR, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_SMOKE, 5.0, NULL_VECTOR, ang);
			g_EffectON[client] = true;

			//AttachParticleBone(client, "rocketjump_flame", "foot_L", 5.0);
			//AttachParticleBone(client, "rocketjump_flame", "foot_R", 5.0);

		}
	}	
}


/////////////////////////////////////////////////////////////////////
//
// �G�t�F�N�g����
//
/////////////////////////////////////////////////////////////////////
stock PlayDashEffect(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_DashEnd[client] != INVALID_HANDLE)
		{
			g_EffectCount[client]++;
			
			if( g_EffectCount[client] == 5 )
			{
				AttachParticleBone(client, EFFECT_FOOT_FLAME, "foot_L", 1.0);
				AttachParticleBone(client, EFFECT_FOOT_FLAME, "foot_R", 1.0);
			}

			if(g_EffectCount[client] > 5)
			{
				new Float:vec[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
				NormalizeVector(vec, vec);
				ScaleVector(vec, -90.0);

				ShowParticleEntity(client, EFFECT_EXPLODE_SMOKE1, 0.05, vec);
				g_EffectCount[client] = 0;
			}
			
			TF2_SetPlayerSpeed(client, 400.0);

			//AttachParticleBone(client, "rocketjump_flame", "foot_L", 0.05);
			//AttachParticleBone(client, "rocketjump_flame", "foot_R", 0.05);
			
		}
						
	}	
}

/////////////////////////////////////////////////////////////////////
//
// �I���`�F�b�N
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_EndCheck(Handle:timer, any:client)
{
	g_KeyCheckTimer[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_DashEnd[client] != INVALID_HANDLE)
		{
			new Float:vec[3];
			new Float:speed;
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
			speed = GetVectorLength(vec);

			new Float:ang[3];
//			new Float:diff = 0.0;
//			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", ang);
//			GetVectorAngles(ang, ang);
//			diff =  FloatAbs(FloatAbs(ang[1]) - FloatAbs(g_BeforAngle[client]));

			
	
			if ( speed < 200.0 || !(GetClientButtons(client) & IN_FORWARD) || !IsPossibleDash(client)/* ||  diff > 8.0*/)
			{
				if(g_DashEnd[client] != INVALID_HANDLE)
				{
					KillTimer(g_DashEnd[client]);
					g_DashEnd[client] = INVALID_HANDLE;
				}
				g_DashEnd[client] = CreateTimer(0.1, Timer_DashEnd, client);
				return;
			}
			g_KeyCheckTimer[client] = CreateTimer(0.1, Timer_EndCheck, client);
			g_BeforAngle[client] = FloatAbs(ang[1]);

		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �_�b�V���I���^�C�}�[�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DashEnd(Handle:timer, any:client)
{
	g_DashEnd[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		EmitSoundToAll(SOUND_DASH_END, client, _, _, SND_CHANGEPITCH, 1.0, 70);
		
		TF2_SetPlayerDefaultSpeed(client);
		g_EffectON[client]=false;
		
	}
}

/////////////////////////////////////////////////////////////////////
//
// �_�b�V������
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DashTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0�`10.0�܂�
	if (StringToFloat(newValue) < 1.0 || StringToFloat(newValue) > 10.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 10.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// �_���[�W�{��
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DashMag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.1�`5.0�܂�
	if (StringToFloat(newValue) < 0.1 || StringToFloat(newValue) > 5.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.1 and 5.0");
	}
}