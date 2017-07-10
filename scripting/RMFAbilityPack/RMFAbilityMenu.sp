/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/03/01 - 0.1.0
// �E1.3.1�ŃR���p�C��
// �Esm_rmf_ability_menu_admin_only��ǉ�
// 2009/09/20 - 0.0.8
// �E���j���[�\���R�}���h�̖����C��
// 2009/09/20 - 0.0.7
// �E�V���[�g�R�}���h���ځB"!r"�ł����j���[���\���\�ɂȂ����B
// 2009/09/05 - 0.0.6
// �E�ϐ�E�܂��̓`�[����I��ł��Ȃ��ꍇ�̓��j���[��\�����Ȃ��悤�ɂ����B
// 2009/08/24 - 0.0.5
// �E���X�|�����[�����Ȃ炷���ɑ����ύX�ł���悤�ɂ����B
// �E�A���[�i���[�h�E�T�h���f�X���[�h�̏ꍇ�̓��E���h�J�n���琔�b���o�߂���ƕύX�s��
// �E1.2.3�ŃR���p�C��
// 2009/08/14 - 0.0.2
// �E�N���X���X�A�b�v�f�[�g�ɑΉ�(1.2.2�ŃR���p�C��)
// �Esm_rmf_allow_ability_menu��0�ɂ��Ă����j���[���\������Ă����̂��C��


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
#define PL_NAME "RMF Ability Menu"
#define PL_DESC "RMF Ability Menu"
#define PL_VERSION "0.1.0"

#define MAX_PLUGINS 64
#define MAX_PLUGIN_NAME 64

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
new Handle:g_ConVarAdminOnly = INVALID_HANDLE;				// ConVarAdminOnly

new String:g_RMFPlugins[MAX_PLUGINS][MAX_PLUGIN_NAME];	// �v���O�C����
new g_PluginNum = 0;									// �v���O�C����

new Handle:g_MenuTimer = INVALID_HANDLE;				// ���j���[�I���^�C�}�[
new bool:g_AbilityLock = false;							// �A���[�i�J�n�ς݁H
new bool:g_SelectedAbility[MAXPLAYERS+1] = false;		// �A�r���e�B�[�I���ς݁H
new String:g_NextAbilityName[MAXPLAYERS+1][128];
new String:g_NowAbilityName[MAXPLAYERS+1][128];

new bool:g_InRespawnRoom[MAXPLAYERS+1] = false;			// ���X�|�����[���ɂ���H


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
		LoadTranslations("rmf_abilitymenu.phrases");

		// �R�}���h�쐬
		CreateConVar("sm_rmf_tf_ability_menu", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_ability_menu","1","Ability menu Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		RegConsoleCmd("say", Command_Say);
		RegConsoleCmd("say_team", Command_Say);
		
		// ���X�|�����[���̑ޏo�Ȃǂ��t�b�N
		HookEntityOutput("func_respawnroom",  "OnStartTouch",    EntityOutput_StartTouch);
		HookEntityOutput("func_respawnroom", "OnEndTouch",    EntityOutput_EndTouch);
		
		g_ConVarAdminOnly = CreateConVar("sm_rmf_ability_menu_admin_only",	"0",	"Admin Only Enable/Disable (0 = disabled | 1 = enabled)");
		HookConVarChange(g_ConVarAdminOnly,		ConVarChange_Bool);	
		
		// RMF�v���O�C�����X�g�擾
		new String:file[256];
		BuildPath(Path_SM, file, 255, "configs/RMFPlugins.txt");
		
		// �t�@�C������擾
		new Handle:fileh = OpenFile(file, "r");
		if(fileh != INVALID_HANDLE)
		{
			new String:buffer[256];
			new String:smxName[128];
			while (ReadFileLine(fileh, buffer, sizeof(buffer)))
			{
				// ���s�R�[�h���C��
				//new len = strlen(buffer)
				//if(buffer[len-1] == '\n')
				//{
				//	PrintToServer("%s", buffer);
		   		//	buffer[len-1] = '\0';
				//}
				
				// �g����
				TrimString(buffer);
				
				// SMX�t�@�C�������邩�`�F�b�N
				Format(smxName, sizeof(smxName), "addons/sourcemod/plugins/%s.smx", buffer)
				//PrintToServer("%s %d", smxName, FileExists(smxName));
				if(FileExists(smxName))
				{
					new String:phrasesPath[256];
					new String:phrasesName[256];
					// ���݂�����v���O�C������(��FAfterBurner)���X�g�ɕۑ�
					strcopy(g_RMFPlugins[g_PluginNum], MAX_PLUGIN_NAME, buffer);
					
					// ����t�@�C�����ݒ�
					StringToLower(phrasesName, buffer);	// �啶������������
					Format(phrasesName, sizeof(phrasesName), "%s.phrases", phrasesName)
					Format(phrasesPath, sizeof(phrasesPath), "addons/sourcemod/translations/%s.txt", phrasesName)
					//PrintToServer("%s", phrasesPath);
					
					// �t�@�C�������݂����猾��t�@�C���ǂݍ���
					if(FileExists(phrasesPath))
					{
						LoadTranslations(phrasesName);
					}
					
					// �v���O�C������ۑ�
					g_PluginNum += 1;
				}
				
				if(IsEndOfFile(fileh))
					break;
			}		
		}
		else
		{
			// �ǂ߂܂���ł���
			LogMessage("configs/RMFPlugins.txt was not able to be read.");
		}
			
		g_AbilityLock = false;
	}

	// �v���O�C����ԕύX
	if(StrEqual(name, EVENT_PLUGIN_STATE_CHANGED))
	{
		// �S�������ݒ�
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			if( IsClientInGame(i) )
			{
				// �A�r���e�B�S���g�p�s�ɁB
				for(new j = 0; j < g_PluginNum; j++)
				{
					ServerCommand("rmf_ability %d %s 0", i, g_RMFPlugins[j]);
				}		
				g_SelectedAbility[i] = false;
				g_NextAbilityName[i] = "";
				g_NowAbilityName[i] = "";
			}
		}
		
	}

	
	
	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			g_SelectedAbility[client] = false;
			g_NextAbilityName[client] = "";
			g_NowAbilityName[client] = "";
		}
		
		
	}
	// �}�b�v�G���h
	if(StrEqual(name, EVENT_MAP_END))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			g_SelectedAbility[client] = false;
			g_NextAbilityName[client] = "";
			g_NowAbilityName[client] = "";
		}
		// �^�C�}�[�N���A
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		// ���E���h�I��
		g_AbilityLock = false;		
	}	
	// �A���[�i���E���h�A�N�e�B�u
	if(StrEqual(name, EVENT_ARENA_ROUND_ACTIVE))
	{

		// �^�C�}�[�N���A
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		g_MenuTimer = CreateTimer(5.0, Timer_MenuEnd, 0);
		// ���E���h�J�n
		g_AbilityLock = true;
	
	}
	// �T�h���f�X�J�n
	if(StrEqual(name, EVENT_SUDDEN_DEATH_START))
	{

		// �^�C�}�[�N���A
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		g_MenuTimer = CreateTimer(10.0, Timer_MenuEnd, 0);
		// ���E���h�J�n
		g_AbilityLock = true;
	}
	
	// �A���[�iWin�p�l��
	if(StrEqual(name, EVENT_ARENA_WIN_PANEL))
	{
		// �^�C�}�[�N���A
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		// ���E���h�I��
		g_AbilityLock = false;
	
	}
	// Win�p�l��
	if(StrEqual(name, EVENT_WIN_PANEL))
	{
		// �^�C�}�[�N���A
		if(g_MenuTimer != INVALID_HANDLE)
		{
			KillTimer(g_MenuTimer);
			g_MenuTimer = INVALID_HANDLE;
		}
		// ���E���h�I��
		g_AbilityLock = false;
	
	}
	
	// �v���C���[�N���X�ύX
	if(StrEqual(name, EVENT_PLAYER_CHANGE_CLASS))
	{
		
		if( IsClientInGame(client) && !IsPlayerAlive(client))
		{
			// ��荇�����A�r���e�B�S���g�p�s�ɁB
			for(new i = 0; i < g_PluginNum; i++)
			{
				ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
			}		
			g_SelectedAbility[client] = false;
			g_NextAbilityName[client] = "";
			g_NowAbilityName[client] = "";
		}

	}
	// �v���C���[����
	if(StrEqual(name, EVENT_PLAYER_SPAWN))
	{
	
		// �^�C�}�[�N���A
//		if(g_MenuTimer[client] != INVALID_HANDLE)
//		{
//			KillTimer(g_MenuTimer[client]);
//			g_MenuTimer[client] = INVALID_HANDLE;
//		}
//		g_MenuTimer[client] = CreateTimer(10.0, Timer_MenuEnd, client);

		if(!StrEqual(g_NowAbilityName[client], "") || !StrEqual(g_NextAbilityName[client], ""))
		{
			new bool:otherClass = false;
			new String:lowerName[64];
			new String:buffer[128];
			new Handle:cvar;

			// ���̃A�r���e�B
			StringToLower(lowerName, g_NextAbilityName[client]);	// �啶������������
			// �N���XCVAR�擾
			Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
			cvar = FindConVar(buffer);
			if(cvar != INVALID_HANDLE && TFClassType:GetConVarInt(cvar) != TF2_GetPlayerClass( client ))
			{
				otherClass = true;
			}
			
			lowerName = "";
			buffer = "";
			
			// ���̃A�r���e�B
			StringToLower(lowerName, g_NowAbilityName[client]);	// �啶������������
			// �N���XCVAR�擾
			Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
			
			cvar = FindConVar(buffer);
			if(cvar != INVALID_HANDLE && TFClassType:GetConVarInt(cvar) != TF2_GetPlayerClass( client ))
			{
				otherClass = true;
			}
			
			if(otherClass)
			{
				// �A�r���e�B�S���g�p�s�ɁB
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
				}	
				
				g_SelectedAbility[client] = false;
				g_NextAbilityName[client] = "";
				g_NowAbilityName[client] = "";
				
			}
			
		}

		
		
		// �A�r���e�B�ύX
		if(!StrEqual(g_NextAbilityName[client], ""))
		{
			if(!StrEqual(g_NextAbilityName[client], "Unequipped"))
			{

				g_NowAbilityName[client] = g_NextAbilityName[client];
				
				// �啶���擾
				new String:upperName[32];
				StringToUpper(upperName, g_NextAbilityName[client]);	// ��������啶����
				
				// ��荇�����A�r���e�B�S���g�p�s�ɁB
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
				}		

				// �I�������A�r���e�B��L��
				ServerCommand("rmf_ability %d %s 1", client, g_NextAbilityName[client]);

				// �v���O�C�����擾
				new String:pluginName[64];
				Format(pluginName, sizeof(pluginName), "ABILITYNAME_%s", upperName);
				Format(pluginName, sizeof(pluginName), "%T", pluginName, client);
				PrintToChat(client, "\x04%T", "ABILITYMENU_EQUIPPED", client, pluginName);
				
				g_SelectedAbility[client] = true;
				g_NextAbilityName[client] = "";
			
			}
			else
			{
				// �A�r���e�B�S���g�p�s�ɁB
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
				}	
				
				if(g_SelectedAbility[client])
				{
					PrintToChat(client, "\x04%T", "ABILITYMENU_UNEQUIPPED", client);
				}
				g_SelectedAbility[client] = false;
				g_NextAbilityName[client] = "";
				g_NowAbilityName[client] = "";
			}
		}
				
	}

	// �v���C���[���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		if(g_IsRunning)
		{
			if(!g_SelectedAbility[client] && g_PluginNum > 0)
			{
				Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_MENU", client);
			}
		}

		
	}
	// �v���C���[�����f�B���C
	if(StrEqual(name, EVENT_PLAYER_SPAWN_DELAY))
	{

	}
	
	// �v���C���[�ؒf
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		// ��荇�����A�r���e�B�S���g�p�s�ɁB
		for(new i = 0; i < g_PluginNum; i++)
		{
			ServerCommand("rmf_ability %d %s 0", client, g_RMFPlugins[i]);
		}		
		g_SelectedAbility[client] = false;
		g_NextAbilityName[client] = "";
		g_NowAbilityName[client] = "";

	}	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// ���j���[�I���^�C�}�[�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_MenuEnd(Handle:timer, any:client)
{
	g_MenuTimer = INVALID_HANDLE;

}

/////////////////////////////////////////////////////////////////////
//
// ���j���[�\���R�}���h
//
/////////////////////////////////////////////////////////////////////
public Action:Command_Say(client, args)
{
	if(g_IsRunning)
	{
		// Admin�I�����[�H
		if( GetConVarBool( g_ConVarAdminOnly ) == true )
		{
			if( GetUserAdmin( client ) == INVALID_ADMIN_ID )
			{
				PrintToChat( client, "\x04%T", "MESSAGE_ADMIN_ONLY", client );
				return Plugin_Handled;
			}
		}
		
		decl String:originalstring[191];
		GetCmdArgString(originalstring, sizeof(originalstring));
		ReplaceString( originalstring, sizeof(originalstring), "\"", "" );
		//PrintToChat(client, "%d", strlen(originalstring));
		//PrintToChat(client, "%s", originalstring);
		if( ( StrContains(originalstring, "rmf_menu") != -1 && strlen(originalstring) == 8 )
		|| ( StrContains(originalstring, "!r") != -1 && strlen(originalstring) == 2 ) )
		{

			//PrintToChat(client, "%d", GetEntProp(g_RoundTimer, Prop_Send, "m_nState"));
				//GetEntProp(g_RoundTimer, Prop_Send, "m_iRoundState"));
		
			//PrintToChat(client, "%d", g_InRespawnRoom[client]);
		
			
			if( client > 0 && ( GetClientTeam(client) == _:TFTeam_Red || GetClientTeam(client) == _:TFTeam_Blue ) )
			{
				// ���j���[���J��
				AbilityMenu(client);
				
			}

		
				
			/*
			if(g_MenuTimer[client] != INVALID_HANDLE)
			{
			}
			else
			{
				if(g_SelectedAbility[client])
				{
					PrintToChat(client, "\x03%T", "ABILITYMENU_CANTCHANGE", client);
				}
				else
				{
					PrintToChat(client, "\x03%T", "ABILITYMENU_TIMEOVER", client);
				}
			}		*/
			return Plugin_Handled;
		}

	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// ���j���[�I��
//
/////////////////////////////////////////////////////////////////////
public AbilityMenu(client)
{
	new Handle:menu = CreateMenu(AbilityMenuHandler);
	
	// ���j���[�^�C�g��
	new String:title[64];
	Format(title, sizeof(title), "%T", "ABILITYMENU_TITLE", client);
	SetMenuTitle(menu, title);
	
	new allowCount = 0;
	for(new i = 0; i < g_PluginNum; i++)
	{
		// �����������Ă���
		if(!StrEqual(g_RMFPlugins[i], ""))
		{
			
			// �啶���������p��
			new String:lowerName[64];
			new String:upperName[64];
			new String:buffer[128];
			new Handle:cvar;
			
			StringToLower(lowerName, g_RMFPlugins[i]);	// �啶������������
			StringToUpper(upperName, g_RMFPlugins[i]);	// ��������啶����
			
			// ON/OFF��CVAR�擾
			Format(buffer, sizeof(buffer), "sm_rmf_allow_%s", lowerName);
			cvar = FindConVar(buffer);
			// �v���O�C����ON���I�t���`�F�b�N
			if(cvar != INVALID_HANDLE && GetConVarInt(cvar))
			{
				// �N���XCVAR�擾
				Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
				cvar = FindConVar(buffer);
				//PrintToServer("%d, %d", GetConVarInt(cvar), TF2_GetPlayerClass( client ));
				// �N���X���������`�F�b�N
				if(cvar != INVALID_HANDLE && TFClassType:GetConVarInt(cvar) == TF2_GetPlayerClass( client ))
				{
					// �g�����X���[�V�����擾
					new String:pluginName[128];
					Format(pluginName, sizeof(pluginName), "ABILITYNAME_%s", upperName);
					Format(pluginName, sizeof(pluginName), "%T", pluginName, client);
					
					// ���j���[�ɒǉ�
					AddMenuItem(menu, g_RMFPlugins[i], pluginName);
					
					// �J�E���g�A�b�v
					allowCount += 1;
				}
				
			}
		}
		
	}
	// �g�p���Ȃ����j���[
	new String:notuse[128];
	if(g_SelectedAbility[client])
	{
		Format(notuse, sizeof(notuse), "%T", "ABILITYMENU_CANCEL", client);
		AddMenuItem(menu, "NOTUSE", notuse);
	}
	//else
	//{
	//	Format(notuse, sizeof(notuse), "%T", "ABILITYMENU_NOTUSE", client);
	//}
	SetMenuExitButton(menu, true);
	
	if(allowCount > 0)
	{
		DisplayMenu(menu, client, 10);
	}	
}

/////////////////////////////////////////////////////////////////////
//
// ���j���[�I��
//
/////////////////////////////////////////////////////////////////////
public AbilityMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
	// �A�C�e���I������
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		// �A�r���e�B�g��
		if(!StrEqual(info, "NOTUSE"))
		{
			// �܂��I��łȂ�
			if(!g_SelectedAbility[param1] && g_InRespawnRoom[param1]/* && g_MenuTimer[param1] != INVALID_HANDLE*/)
			{
				// �啶���擾
				new String:upperName[32];
				StringToUpper(upperName, info);	// ��������啶����
				new String:lowerName[64];
				StringToLower(lowerName, info);	// �啶������������
					
				// ��荇�����A�r���e�B�S���g�p�s�ɁB
				for(new i = 0; i < g_PluginNum; i++)
				{
					ServerCommand("rmf_ability %d %s 0", param1, g_RMFPlugins[i]);
				}		

				// �N���XCVAR�擾
				new String:buffer[128];
				Format(buffer, sizeof(buffer), "sm_rmf_%s_class", lowerName);
				new Handle:cvar = FindConVar(buffer);
				// �N���X���������`�F�b�N
				if(TFClassType:GetConVarInt(cvar) == TF2_GetPlayerClass( param1 ))
				
				{				// �I�������A�r���e�B��L��
					ServerCommand("rmf_ability %d %s 1", param1, info);

					// �v���O�C�����擾
					new String:pluginName[64];
					Format(pluginName, sizeof(pluginName), "ABILITYNAME_%s", upperName);
					Format(pluginName, sizeof(pluginName), "%T", pluginName, param1);
					PrintToChat(param1, "\x04%T", "ABILITYMENU_EQUIPPED", param1, pluginName);
					
					g_SelectedAbility[param1] = true;
					g_NowAbilityName[param1] = info;
				}
			}
			// �I��ł�
			else
			{
				g_NextAbilityName[param1] = info;
				
				// �O�ƈႤ��Ȃ�ۑ�
				if(!StrEqual(g_NextAbilityName[param1], g_NowAbilityName[param1]))
				{
					// ���b�Z�[�W
					//PrintToChat(param1, "henkou");
					// �A���[�i����уT�h���f�X�̏ꍇ�͐������ԓ�
					if(!g_AbilityLock || g_MenuTimer != INVALID_HANDLE)
					{
						// ���X�|�����[�����Ȃ炷���؂�ւ�
						if(g_InRespawnRoom[param1])
						{
							TF2_RespawnPlayer(param1);
						}
						else
						{
							PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE", param1);
						}
					}
					else
					{
						// ���͕ύX�ł��Ȃ����b�Z�[�W
						PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE_NOW", param1);
					}
					
				}

			}
		}
		else
		{
			g_NextAbilityName[param1] = "Unequipped";
			// �A���[�i����уT�h���f�X�̏ꍇ�͐������ԓ�
			if(!g_AbilityLock || g_MenuTimer != INVALID_HANDLE)
			{
				// ���X�|�����[�����Ȃ炷���؂�ւ�
				if(g_InRespawnRoom[param1])
				{
					TF2_RespawnPlayer(param1);
				}
				else
				{
					PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE", param1);
				}
			}
			else
			{
				// ���͕ύX�ł��Ȃ����b�Z�[�W
				PrintToChat(param1, "\x04%T", "ABILITYMENU_CANT_CHANGE_NOW", param1);
			}			
	
			// �A�r���e�B�S���g�p�s�ɁB
			/*
			for(new i = 0; i < g_PluginNum; i++)
			{
				ServerCommand("rmf_ability %d %s 0", param1, g_RMFPlugins[i]);
			}	
			
			if(g_SelectedAbility[param1])
			{
				PrintToChat(param1, "%T", "ABILITYMENU_CANCELED", param1);
			}
			g_SelectedAbility[param1] = false;
			g_NextAbilityName[param1] = "";
			g_NowAbilityName[param1] = "";*/
		}
	}
	// �L�����Z��
	else if (action == MenuAction_Cancel)
	{
		// �A�r���e�B�g�p�s��
	}
	// ���j���[����
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
			
		

}

/////////////////////////////////////////////////////////////////////
//
// ���X�|�����[���o�����
//
/////////////////////////////////////////////////////////////////////
public EntityOutput_StartTouch( const String:output[], caller, activator, Float:delay )
{
//	PrintToChat(activator, "Touch");
	if(TF2_EdictNameEqual(activator, "player"))
	{
		g_InRespawnRoom[activator] = true;
	}
}
public EntityOutput_EndTouch( const String:output[], caller, activator, Float:delay )
{
//	PrintToChat(activator, "NoTouch");
	if(TF2_EdictNameEqual(activator, "player"))
	{
		g_InRespawnRoom[activator] = false;
	}

}

