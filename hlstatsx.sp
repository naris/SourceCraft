/**
 * HLstatsX - SourceMod plugin to display ingame messages
 * http://www.hlstatsx.com/
 * Copyright (C) 2007 Tobias Oetzel (Tobi@hlstatsx.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
 
 
#include <sourcemod>
#include <keyvalues>
#include <menus>
#include <sdktools>

new String: game_mod[32];
new String: team_list[16][64];

new Handle: hlx_block_chat_commands;
new String: blocked_commands[][] = { "rank", "skill", "points", "place", "session", "session_data", 
                                     "kpd", "kdratio", "kdeath", "next", "load", "status", "servers", 
                                     "top20", "top10", "top5", "clans", "cheaters", "statsme", "weapons", 
                                     "weapon", "action", "actions", "accuracy", "targets", "target", "kills", 
                                     "kill", "player_kills", "cmd", "cmds", "command", "hlx_display 0", 
                                     "hlx_display 1", "hlx_teams 0", "hlx_teams 1", "hlx_hideranking", 
                                     "hlx_chat 0", "hlx_chat 1", "hlx_menu", "servers 1", "servers 2", 
                                     "servers 3", "gstats", "global_stats", "hlx", "hlstatsx" };

new Handle:HLstatsXMenuMain;
new Handle:HLstatsXMenuAuto;
new Handle:HLstatsXMenuEvents;

new Handle: HandleGameConf;
new Handle: HandleSwitchTeam;
new Handle: HandleRoundRespawn;
new Handle: HandleSetModel;

new Handle: PlayerColorArray;

new ct_player_color   = -1;
new ts_player_color   = -1;
new blue_player_color = -1;
new red_player_color  = -1;

new String: message_cache[192];
new String: parsed_message_cache[192];
new cached_color_index;


public Plugin:myinfo = {
	name = "HLstatsX Plugin",
	author = "Tobi17",
	description = "HLstatsX Ingame Plugin",
	version = "1.9",
	url = "http://www.hlstatsx.com"
};

public OnPluginStart() 
{
	new String: game_description[64];
	GetGameDescription(game_description, 64, true);
	
	if (strcmp(game_description, "Counter-Strike: Source") == 0) {
		game_mod = "CSS";
	}
	if (strcmp(game_description, "Day of Defeat: Source") == 0) {
		game_mod = "DODS";
	}
	if (strcmp(game_description, "Half-Life 2 Deathmatch") == 0) {
		game_mod = "HL2MP";
	}
	if (strcmp(game_description, "Team Fortress") == 0) {
		game_mod = "TF";
	}

	LogToGame("Mod Detection: %s [%s]", game_description, game_mod);
	
	HandleGameConf = LoadGameConfigFile("hlstatsx.sdktools");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(HandleGameConf, SDKConf_Signature, "SwitchTeam");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	HandleSwitchTeam = EndPrepSDKCall();	

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(HandleGameConf, SDKConf_Signature, "RoundRespawn");
	HandleRoundRespawn = EndPrepSDKCall();	

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(HandleGameConf, SDKConf_Signature, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	HandleSetModel = EndPrepSDKCall();
	
	CreateHLstatsXMenuMain(HLstatsXMenuMain);
	CreateHLstatsXMenuAuto(HLstatsXMenuAuto);
	CreateHLstatsXMenuEvents(HLstatsXMenuEvents);

	clear_message_cache();

	RegServerCmd("hlx_sm_psay",          hlx_sm_psay);
	RegServerCmd("hlx_sm_psay2",         hlx_sm_psay2);
	RegServerCmd("hlx_sm_csay",          hlx_sm_csay);
	RegServerCmd("hlx_sm_msay",          hlx_sm_msay);
	RegServerCmd("hlx_sm_tsay",          hlx_sm_tsay);
	RegServerCmd("hlx_sm_hint",          hlx_sm_hint);
	RegServerCmd("hlx_sm_browse",        hlx_sm_browse);
	RegServerCmd("hlx_sm_swap",          hlx_sm_swap);
	RegServerCmd("hlx_sm_redirect",      hlx_sm_redirect);
	RegServerCmd("hlx_sm_player_action", hlx_sm_player_action);
	RegServerCmd("hlx_sm_team_action",   hlx_sm_team_action);
	RegServerCmd("hlx_sm_world_action",  hlx_sm_world_action);

	RegConsoleCmd("say",                 hlx_block_commands);
	RegConsoleCmd("say_team",            hlx_block_commands);

	HookEvent("player_death",            HLstatsX_Event_PlayerDeath);
	HookEvent("player_team",             HLstatsX_Event_PlayerTeamChange);

	CreateConVar("hlx_plugin_version", "1.9", "HLstatsX Ingame Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("hlx_webpage", "http://www.hlstatsx.com", "http://www.hlstatsx.com", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	hlx_block_chat_commands = CreateConVar("hlx_block_commands", "1", "If activated HLstatsX commands are blocked from the chat area", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	PlayerColorArray = CreateArray();
}

public OnPluginEnd() 
{
	if (PlayerColorArray != INVALID_HANDLE) {
		CloseHandle(PlayerColorArray);
	}
}


public OnMapStart()
{
	new max_entities = GetMaxEntities();
	for (new entity_index = 0; (entity_index < max_entities); entity_index++) {
		if (IsValidEntity(entity_index)) {

			new String: entity_classname[64];
			GetEntityNetClass(entity_index, entity_classname, 64);
			
			// LogToGame("Entity: %s", entity_classname);

			if (strcmp(entity_classname, "CCSTeam") == 0) {
				new team_index;
				new index_offset = FindSendPropOffs("CCSTeam", "m_iTeamNum");				
				team_index = GetEntData(entity_index, index_offset);

				new String: team_name[64];
				new name_offset = FindSendPropOffs("CCSTeam", "m_szTeamname");				
				GetEntDataString(entity_index, name_offset, team_name, 64);
				
				if (strcmp(team_name, "") != 0) {
					team_list[team_index] = team_name;
				}
			}

			if (strcmp(entity_classname, "CDODTeam") == 0) {
				new team_index;
				new index_offset = FindSendPropOffs("CDODTeam", "m_iTeamNum");				
				team_index = GetEntData(entity_index, index_offset);

				new String: team_name[64];
				new name_offset = FindSendPropOffs("CDODTeam", "m_szTeamname");				
				GetEntDataString(entity_index, name_offset, team_name, 64);
				
				if (strcmp(team_name, "") != 0) {
					team_list[team_index] = team_name;
				}
			}

			if ((strcmp(entity_classname, "CDODTeam_Allies") == 0) || (strcmp(entity_classname, "CDODTeam_Axis") == 0)) {
				new team_index;
				new index_offset = FindSendPropOffs(entity_classname, "m_iTeamNum");				
				team_index = GetEntData(entity_index, index_offset);

				new String: team_name[64];
				new name_offset = FindSendPropOffs(entity_classname, "m_szTeamname");				
				GetEntDataString(entity_index, name_offset, team_name, 64);
				
				if (strcmp(team_name, "") != 0) {
					team_list[team_index] = team_name;
				}
			}

			if (strcmp(entity_classname, "CTFTeam") == 0) {
				new team_index;
				new index_offset = FindSendPropOffs("CTFTeam", "m_iTeamNum");				
				team_index = GetEntData(entity_index, index_offset);

				new String: team_name[64];
				new name_offset = FindSendPropOffs("CTFTeam", "m_szTeamname");				
				GetEntDataString(entity_index, name_offset, team_name, 64);
				
				if (strcmp(team_name, "") != 0) {
					team_list[team_index] = team_name;
				}
			}

		}
	}
	
	clear_message_cache();

	if (strcmp(game_mod, "CSS") == 0) {
		ct_player_color = -1;
		ts_player_color = -1;
		find_player_team_slot("CT");
		find_player_team_slot("TERRORIST");
	} else if (strcmp(game_mod, "TF") == 0) {
		blue_player_color = -1;
		red_player_color = -1;
		find_player_team_slot("Blue");
		find_player_team_slot("Red");
	}
}

stock find_player_team_slot(String: team[64]) {
	if (strcmp(game_mod, "CSS") == 0) {
		new team_index = get_team_index(team);
		if (team_index > -1) {
			if (strcmp(team, "CT") == 0) {
				ct_player_color = -1;
			} else if (strcmp(team, "TERRORIST") == 0) {
				ts_player_color = -1;
			}
			new max_clients = GetMaxClients();
			for(new i = 1; i <= max_clients; i++) {
				new player_index = i;
				if ((IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					new player_team_index = GetClientTeam(player_index);
					if (player_team_index == team_index) {
						if (strcmp(team, "CT") == 0) {
							ct_player_color = player_index;
							if (ts_player_color == ct_player_color) {
								ct_player_color = -1;
								ts_player_color = -1;
							}
							break;
						} else if (strcmp(team, "TERRORIST") == 0) {
							ts_player_color = player_index;
							if (ts_player_color == ct_player_color) {
								ct_player_color = -1;
								ts_player_color = -1;
							}
							break;
						}
					}
				}
			}
		}
	} else if (strcmp(game_mod, "TF") == 0) {
		new team_index = get_team_index(team);
		if (team_index > -1) {
			if (strcmp(team, "Blue") == 0) {
				blue_player_color = -1;
			} else if (strcmp(team, "Red") == 0) {
				red_player_color = -1;
			}
			new max_clients = GetMaxClients();
			for(new i = 1; i <= max_clients; i++) {
				new player_index = i;
				if ((IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					new player_team_index = GetClientTeam(player_index);
					if (player_team_index == team_index) {
						if (strcmp(team, "Blue") == 0) {
							blue_player_color = player_index;
							if (red_player_color == blue_player_color) {
								blue_player_color = -1;
								red_player_color = -1;
							}
							break;
						} else if (strcmp(team, "Red") == 0) {
							red_player_color = player_index;
							if (red_player_color == blue_player_color) {
								blue_player_color = -1;
								red_player_color = -1;
							}
							break;
						}
					}
				}
			}
		}
	}
}

public validate_team_colors() 
{
	if (strcmp(game_mod, "CSS") == 0) {
		if (ct_player_color > -1) {
			if ((IsClientConnected(ct_player_color)) && (IsClientInGame(ct_player_color))) {
				new player_team_index = GetClientTeam(ct_player_color);
				new String:player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("CT", player_team) != 0) {
					ct_player_color = -1;
				}
			} else {
				ct_player_color = -1;
			}
		} else if (ts_player_color > -1) {
			if ((IsClientConnected(ts_player_color)) && (IsClientInGame(ts_player_color))) {
				new player_team_index = GetClientTeam(ts_player_color);
				new String:player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("TERRORIST", player_team) != 0) {
					ts_player_color = -1;
				}
			} else {
				ts_player_color = -1;
			}
		}
		if ((ct_player_color == -1) || (ts_player_color == -1)) {
			if (ct_player_color == -1) {
				find_player_team_slot("CT");
			}
			if (ts_player_color == -1) {
				find_player_team_slot("TERRORIST");
			}
		}
	} else if (strcmp(game_mod, "TF") == 0) {
		if (blue_player_color > -1) {
			if ((IsClientConnected(blue_player_color)) && (IsClientInGame(blue_player_color))) {
				new player_team_index = GetClientTeam(blue_player_color);
				new String:player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("Blue", player_team) != 0) {
					blue_player_color = -1;
				}
			} else {
				blue_player_color = -1;
			}
		} else if (red_player_color > -1) {
			if ((IsClientConnected(red_player_color)) && (IsClientInGame(red_player_color))) {
				new player_team_index = GetClientTeam(red_player_color);
				new String:player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("Red", player_team) != 0) {
					red_player_color = -1;
				}
			} else {
				red_player_color = -1;
			}
		}
		if ((blue_player_color == -1) || (red_player_color == -1)) {
			if (blue_player_color == -1) {
				find_player_team_slot("Blue");
			}
			if (red_player_color == -1) {
				find_player_team_slot("Red");
			}
		}
	}
}

public add_message_cache(String: message[192], String: parsed_message[192], color_index) {
	message_cache = message;
	parsed_message_cache = parsed_message;
	cached_color_index = color_index;
}

public is_message_cached(String: message[192]) {
	if (strcmp(message, message_cache) == 0) {
		return 1;
	}
	return 0;
}

public clear_message_cache() {
	message_cache = "";
	parsed_message_cache = "";
	cached_color_index = -1;
}


public OnClientDisconnect(client)
{
	if (client > 0) {
		if (strcmp(game_mod, "CSS") == 0) {
			if ((ct_player_color == -1) || (client == ct_player_color)) {
				ct_player_color = -1;
				clear_message_cache();
			} else if ((ts_player_color == -1) || (client == ts_player_color)) {
				ts_player_color = -1;
				clear_message_cache();
			}
		} else if (strcmp(game_mod, "TF") == 0) {
			if ((blue_player_color == -1) || (client == blue_player_color)) {
				blue_player_color = -1;
				clear_message_cache();
			} else if ((red_player_color == -1) || (client == red_player_color)) {
				red_player_color = -1;
				clear_message_cache();
			}
		}
	}
}


stock color_player(color_type, player_index, String: client_message[192]) 
{
	new color_player_index = -1;
	if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {
		new String:client_name[192];
		GetClientName(player_index, client_name, 192);
		if (color_type == 1) {
			new String:colored_player_name[192];
			Format(colored_player_name, 192, "\x03%s\x01", client_name);
			if (ReplaceString(client_message, 192, client_name, colored_player_name) > 0) {
				return player_index;
			}
		} else {
			new String:colored_player_name[192];
			Format(colored_player_name, 192, "\x04%s\x01", client_name);
			if (ReplaceString(client_message, 192, client_name, colored_player_name) > 0) {
			}
		}
	}
	return color_player_index;
}

stock color_all_players(String: message[192]) 
{
	new color_index = -1;

	if (PlayerColorArray != INVALID_HANDLE) {

		ClearArray(PlayerColorArray);
		if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {

			new lowest_matching_pos = 192;
			new lowest_matching_pos_client = -1;

			new max_clients = GetMaxClients();
			for(new i = 1; i <= max_clients; i++) {
				new client = i;
				if ((IsClientConnected(client)) && (IsClientInGame(client))) {
					new String:client_name[192];
					GetClientName(client, client_name, 192);
					new message_pos = StrContains(message, client_name);
					if (message_pos > -1) {
						if (lowest_matching_pos > message_pos) {
							lowest_matching_pos = message_pos;
							lowest_matching_pos_client = client;
						}
						new TempPlayerColorArray[1];
						TempPlayerColorArray[0] = client;
						PushArrayArray(PlayerColorArray, TempPlayerColorArray);
					}
				}
			}
			new size = GetArraySize(PlayerColorArray);
			for (new i = 0; i < size; i++) {
				new temp_player_array[1];
				GetArrayArray(PlayerColorArray, i, temp_player_array);
				new temp_client = temp_player_array[0];
				if (temp_client == lowest_matching_pos_client) {
					new temp_color_index = color_player(1, temp_client, message);
					color_index = temp_color_index;
				} else {
					color_player(0, temp_client, message);
				}
			}
			ClearArray(PlayerColorArray);
		}
	}
	
	return color_index;
}

stock get_team_index(String: team_name[])
{
	new loop_break = 0;
	new index = 0;
	while ((loop_break == 0) && (index < sizeof(team_list))) {
   	    if (strcmp(team_name, team_list[index], true) == 0) {
       		loop_break++;
        }
   	    index++;
	}
	if (loop_break == 0) {
		return -1;
	} else {
		return index - 1;
	}
}

stock remove_color_entities(String: message[192])
{
	ReplaceString(message, 192, "x04", "");
	ReplaceString(message, 192, "x03", "");
	ReplaceString(message, 192, "x01", "");
}

stock color_entities(String: message[192])
{
	ReplaceString(message, 192, "x04", "\x04");
	ReplaceString(message, 192, "x03", "\x03");
	ReplaceString(message, 192, "x01", "\x01");
}

stock color_team_entities(String: message[192])
{
	if (strcmp(game_mod, "CSS") == 0) {
		if (ts_player_color > -1) {
			if (ReplaceString(message, 192, "TERRORIST", "\x03TERRORIST\x01") == 0) {
				if (ct_player_color > -1) {
					if (ReplaceString(message, 192, "CT", "\x03CT\x01") > 0) {
						return ct_player_color;
					}
				}
			} else {
				return ts_player_color;
			}
		} else {
			if (ct_player_color > -1) {
				if (ReplaceString(message, 192, "CT", "\x03CT\x01") > 0) {
					return ct_player_color;
				}
			}
		}
	} else if (strcmp(game_mod, "TF") == 0) {
		if (red_player_color > -1) {
			if (ReplaceString(message, 192, "Red", "\x03Red\x01") == 0) {
				if (blue_player_color > -1) {
					if (ReplaceString(message, 192, "Blue", "\x03Blue\x01") > 0) {
						return blue_player_color;
					}
				}
			} else {
				return red_player_color;
			}
		} else {
			if (blue_player_color > -1) {
				if (ReplaceString(message, 192, "Blue", "\x03Blue\x01") > 0) {
					return blue_player_color;
				}
			}
		}
	}
	
	return -1;
}

stock display_menu(player_index, time, String: full_message[1024])
{
	new String: display_message[1024];
	new offset = 0;
	new message_length = strlen(full_message); 
	for(new i = 0; i < message_length; i++) {
		if (i > 0) {
			if ((full_message[i-1] == 92) && (full_message[i] == 110)) {
				new String: buffer[1024];
				strcopy(buffer, (i - offset), full_message[offset]);
				if (strlen(display_message) == 0) {
					strcopy(display_message[strlen(display_message)], strlen(buffer) + 1, buffer); 
				} else {
					display_message[strlen(display_message)] = 10;
					strcopy(display_message[strlen(display_message)], strlen(buffer) + 1, buffer); 
				}
				i++;
				offset = i;
			}
		}
	}

	InternalShowMenu(player_index, display_message, time);
}

public Action:hlx_sm_psay(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_psay <userid><colored><message> - sends private message");
		return Plugin_Handled;
	}

	new String:client_id[32];
	GetCmdArg(1, client_id, 32);

	new String:colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new is_colored = 0;
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0) {
		is_colored = 1;
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0) {
		ignore_param = 1;
	}

	new String:client_message[192];
	new argument_count = GetCmdArgs();

	for(new i = (1 + ignore_param); i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);

		if (i > (1 + ignore_param)) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125)) {
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				} else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44)) {
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0)) {
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				} else {
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			new color_index = player_index;

			new String:display_message[192];
			if (strcmp(game_mod, "CSS") == 0) {
				
				if (is_colored > 0) {
					if (is_message_cached(client_message) > 0) {
						client_message = parsed_message_cache;
						color_index = cached_color_index;
					} else {
						new String: client_message_backup[192];
						strcopy(client_message_backup, 192, client_message);
					
						new player_color_index = color_all_players(client_message);
						if (player_color_index > -1) {
							color_index = player_color_index;
						} else {
							validate_team_colors();
							color_index = color_team_entities(client_message);
						}
						color_entities(client_message);
						add_message_cache(client_message_backup, client_message, color_index);
					}
				}
				Format(display_message, 192, "\x04HLstatsX:\x01 %s", client_message);

				new Handle:hBf;
				hBf = StartMessageOne("SayText2", player_index);
				if (hBf != INVALID_HANDLE) {
					BfWriteByte(hBf, color_index); 
					BfWriteByte(hBf, 0); 
					BfWriteString(hBf, display_message);
					EndMessage();
				}
			} else if (strcmp(game_mod, "TF") == 0) {
				
				if (is_colored > 0) {
					if (is_message_cached(client_message) > 0) {
						client_message = parsed_message_cache;
						color_index = cached_color_index;
					} else {
						new String: client_message_backup[192];
						strcopy(client_message_backup, 192, client_message);
					
						new player_color_index = color_all_players(client_message);
						if (player_color_index > -1) {
							color_index = player_color_index;
						} else {
							validate_team_colors();
							color_index = color_team_entities(client_message);
						}
						color_entities(client_message);
						add_message_cache(client_message_backup, client_message, color_index);
					}
				}
				Format(display_message, 192, "\x04HLstatsX:\x01 %s", client_message);

				new Handle:hBf;
				hBf = StartMessageOne("SayText2", player_index);
				if (hBf != INVALID_HANDLE) {
					BfWriteByte(hBf, color_index); 
					BfWriteByte(hBf, 0); 
					BfWriteString(hBf, display_message);
					EndMessage();
				}
			} else {
				Format(display_message, 192, "HLstatsX: %s", client_message);
				PrintToChat(player_index, display_message);
			}
			
		}	
	}
	return Plugin_Handled;
}


public Action:hlx_sm_psay2(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_psay2 <userid><colored><message> - sends green colored private message");
		return Plugin_Handled;
	}
	
	new String:client_id[32];
	GetCmdArg(1, client_id, 32);

	new String:colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0) {
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0) {
		ignore_param = 1;
	}

	new String:client_message[192];
	new argument_count = GetCmdArgs();

	for(new i = (1 + ignore_param); i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (i > (1 + ignore_param)) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125)) {
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				} else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44)) {
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0)) {
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				} else {
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {

			new String:display_message[192];
			if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {
				remove_color_entities(client_message);
				Format(display_message, 192, "\x04HLstatsX: %s", client_message);
				PrintToChat(player_index, display_message);
			} else {
				Format(display_message, 192, "HLstatsX: %s", client_message);
				PrintToChat(player_index, display_message);
			}
		}	
	}
	return Plugin_Handled;
}


public Action:hlx_sm_csay(args)
{
	if (args < 1) {
		PrintToServer("Usage: hlx_sm_csay <message> - display center message");
		return Plugin_Handled;
	}

	new String:display_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 1; i <= argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i, temp_argument, 192);

		if (i > 1) {
			if ((191 - strlen(display_message)) > strlen(temp_argument)) {
				display_message[strlen(display_message)] = 32;		
				strcopy(display_message[strlen(display_message)], 192, temp_argument);
			}
		} else {
			if ((192 - strlen(display_message)) > strlen(temp_argument)) {
				strcopy(display_message[strlen(display_message)], 192, temp_argument);
			}
		}
	}

	PrintCenterTextAll(display_message);
		
	return Plugin_Handled;
}

public Action:hlx_sm_msay(args)
{
	if (args < 3) {
		PrintToServer("Usage: hlx_sm_msay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}
	
	if (strcmp("mod", "HL2MP") == 0) {
		return Plugin_Handled;
	}
	
	new String:display_time[16];
	GetCmdArg(1, display_time, 16);
	new String:client_id[32];
	GetCmdArg(2, client_id, 32);

	new String:client_message[1024];
	new argument_count = GetCmdArgs();
	for(new i = 3; i <= argument_count; i++) {
		new String:temp_argument[1024];
		GetCmdArg(i, temp_argument, 1024);

		if (i > 3) {
			if ((1023 - strlen(client_message)) > strlen(temp_argument)) {
				client_message[strlen(client_message)] = 32;		
				strcopy(client_message[strlen(client_message)], 1024, temp_argument);
			}
		} else {
			if ((1024 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 1024, temp_argument);
			}
		}
	}

	new time = StringToInt(display_time);
	if (time <= 0) {
		time = 10;
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			new String: display_message[1024];
			strcopy(display_message, 1024, client_message);
			display_menu(player_index, time, display_message);			
		}	
	}		
		
	return Plugin_Handled;
}

public Action:hlx_sm_tsay(args)
{
	if (args < 3) {
		PrintToServer("Usage: hlx_sm_tsay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	new String:display_time[16];
	GetCmdArg(1, display_time, 16);
	new String:client_id[32];
	GetCmdArg(2, client_id, 32);

	new String:client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 2; i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);

		if (i > 2) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				client_message[strlen(client_message)] = 32;		
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			new Handle:values = CreateKeyValues("msg");
			KvSetString(values, "title", client_message);
			KvSetNum(values, "level", 1); 
			KvSetString(values, "time", display_time); 
			CreateDialog(player_index, values, DialogType_Msg);
			CloseHandle(values);
		}	
	}		
		
	return Plugin_Handled;
}


public Action:hlx_sm_hint(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_hint <userid><message> - send hint message");
		return Plugin_Handled;
	}

	if (strcmp("mod", "HL2MP") == 0) {
		return Plugin_Handled;
	}

	new String:client_id[32];
	GetCmdArg(1, client_id, 32);

	new String:client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 1; i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);

		if (i > 1) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125)) {
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				} else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44)) {
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0)) {
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				} else {
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			PrintHintText(player_index, client_message);
		}	
	}		
			
	return Plugin_Handled;
}

public Action:hlx_sm_browse(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_browse <userid><url> - open client ingame browser");
		return Plugin_Handled;
	}

	new String:client_id[32];
	GetCmdArg(1, client_id, 32);

	new String:client_url[192];
	new String:argument_string[512];
	GetCmdArgString(argument_string, 512);

	new find_pos = StrContains(argument_string, "http://", true);
	if (find_pos == -1) {
		new argument_count = GetCmdArgs();
		for(new i = 1; i < argument_count; i++) {
			new String:temp_argument[192];
			GetCmdArg(i+1, temp_argument, 192);

			if ((192 - strlen(client_url)) > strlen(temp_argument)) {
				strcopy(client_url[strlen(client_url)], 192, temp_argument);
			}
		}
	} else {
		strcopy(client_url, 192, argument_string[find_pos]);
		ReplaceString(client_url, 192, "\"", "");
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			ShowMOTDPanel(player_index, "HLstatsX", client_url, MOTDPANEL_TYPE_URL);
		}	
	}		
			
	return Plugin_Handled;
}

public Action:hlx_sm_swap(args)
{
	if (args < 1) {
		PrintToServer("Usage: hlx_sm_swap <userid> - swaps players to the opposite team (css only)");
		return Plugin_Handled;
	}

	new String:client_id[32];
	GetCmdArg(1, client_id, 32);

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			swap_player(player_index)
		}
	}
	return Plugin_Handled;
}


public Action:hlx_sm_redirect(args)
{
	if (args < 3) {
		PrintToServer("Usage: hlx_sm_redirect <time><userid><address><reason> - asks player to be redirected to specified gameserver");
		return Plugin_Handled;
	}

	new String:display_time[16];
	GetCmdArg(1, display_time, 16);

	new String:client_id[32];
	GetCmdArg(2, client_id, 32);

	new String:server_address[192];
	new argument_count = GetCmdArgs();
	new break_address = argument_count;

	for(new i = 2; i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (strcmp(temp_argument, ":") == 0) {
			break_address = i + 1;
		} else if (i == 3) {
			break_address = i - 1;
		}
		if (i <= break_address) {
			if ((192 - strlen(server_address)) > strlen(temp_argument)) {
				strcopy(server_address[strlen(server_address)], 192, temp_argument);
			}
		}
	}	

	new String:redirect_reason[192];
	for(new i = break_address + 1; i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if ((192 - strlen(redirect_reason)) > strlen(temp_argument)) {
			redirect_reason[strlen(redirect_reason)] = 32;		
			strcopy(redirect_reason[strlen(redirect_reason)], 192, temp_argument);
		}
	}	


	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(server_address, "") != 0)) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {

			new Handle:top_values = CreateKeyValues("msg");
			KvSetString(top_values, "title", redirect_reason);
			KvSetNum(top_values, "level", 1); 
			KvSetString(top_values, "time", display_time); 
			CreateDialog(player_index, top_values, DialogType_Msg);
			CloseHandle(top_values);
			
			new Float: display_time_float;
			display_time_float = StringToFloat(display_time);
			DisplayAskConnectBox(player_index, display_time_float, server_address);
		}	
	}		
		
	return Plugin_Handled;
}

public Action:hlx_sm_player_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_player_action <userid><action> - trigger player action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	new String:client_id[32];
	GetCmdArg(1, client_id, 32);

	new String:player_action[192];
	GetCmdArg(2, player_action, 192);

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {

			new String:player_name[64];
			if (!GetClientName(player_index, player_name, 64)) {
				strcopy(player_name, 64, "UNKNOWN");
			}

			new String:player_authid[64];
			if (!GetClientAuthString(player_index, player_authid, 64)) {
				strcopy(player_authid, 64, "UNKNOWN");
			}

			new player_team_index = GetClientTeam(player_index);
			new String:player_team[64];
			player_team = team_list[player_team_index];

			LogToGame("\"%s<%d><%s><%s>\" triggered \"%s\"", player_name, client, player_authid, player_team, player_action); 
		}
	}

	return Plugin_Handled;
}

public Action:hlx_sm_team_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_player_action <team_name><action> - trigger team action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	new String:team_name[192];
	GetCmdArg(1, team_name, 192);

	new String:team_action[192];
	GetCmdArg(2, team_action, 192);

	LogToGame("Team \"%s\" triggered \"%s\"", team_name, team_action); 

	return Plugin_Handled;
}

public Action:hlx_sm_world_action(args)
{
	if (args < 1) {
		PrintToServer("Usage: hlx_sm_world_action <action> - trigger world action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	new String:world_action[192];
	GetCmdArg(1, world_action, 192);

	LogToGame("World triggered \"%s\"", world_action); 

	return Plugin_Handled;
}

stock is_command_blocked(String: command[])
{
	new command_blocked = 0;
	new command_index = 0;
	while ((command_blocked == 0) && (command_index < sizeof(blocked_commands))) {
		if (strcmp(command, blocked_commands[command_index]) == 0) {
			command_blocked++;
		}
		command_index++;
	}
	if (command_blocked > 0) {
		return 1;
	}
	return 0;
}


public Action:hlx_block_commands(client, args)
{

	if (client) {
	
		if (client == 0) {
			return Plugin_Continue;
		}
		
		new block_chat_commands = GetConVarInt(hlx_block_chat_commands);

		new String:user_command[192];
		GetCmdArgString(user_command, 192);
		new String: origin_command[192];

		new start_index = 0
		new command_length = strlen(user_command);
		if (command_length > 0) {
			if (user_command[0] == 34)	{
				start_index = 1;
				if (user_command[command_length - 1] == 34)	{
					user_command[command_length - 1] = 0;
				}
			}
		
			strcopy(origin_command, 192, user_command[start_index]);
			
			if (user_command[start_index] == 47)	{
				start_index++;
			}
		}

		if (command_length > 0) {
			if (block_chat_commands > 0) {

				new String:command_type[32] = "say";
				new command_blocked = is_command_blocked(user_command[start_index]);
				if (command_blocked > 0) {

					// Normally the condition below should not be necessary. But sometimes an error
					// message is reported: Native "GetClientName" reported: Client xy is not connected
					// To avoid this we do the check if the client who said something is ingame...

					if ((IsClientConnected(client)) && (IsClientInGame(client))) {
						if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
							(strcmp("hlx", user_command[start_index]) == 0) ||
							(strcmp("hlstatsx", user_command[start_index]) == 0)) {
							DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
						}

						new String:player_name[64];
						if (!GetClientName(client, player_name, 64))	{
							strcopy(player_name, 64, "UNKNOWN");
						}

						new String:player_authid[64];
						if (!GetClientAuthString(client, player_authid, 64)){
							strcopy(player_authid, 64, "UNKNOWN");
						}

						new player_team_index = GetClientTeam(client);
						new String:player_team[64];
						player_team = team_list[player_team_index];

						new player_userid = GetClientUserId(client);
						LogToGame("\"%s<%d><%s><%s>\" %s \"%s\"", player_name, player_userid, player_authid, player_team, command_type, origin_command); 
					}
					return Plugin_Handled;
				}
			} else {
				if ((IsClientConnected(client)) && (IsClientInGame(client))) {
					if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
						(strcmp("hlx", user_command[start_index]) == 0) ||
						(strcmp("hlstatsx", user_command[start_index]) == 0)) {
						DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
					}
				}
				return Plugin_Continue;
			}
		}
	}
 
	return Plugin_Continue;
}


public Action:HLstatsX_Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {

		if (GetEventBool(event, "headshot")) {
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
		
			if ((attacker > 0) && (victim > 0)) {

				new victim_team_index = GetClientTeam(victim);
				new player_team_index = GetClientTeam(attacker);
		
				if (victim_team_index != player_team_index) {
		
					new String:player_team[64];
					player_team = team_list[player_team_index];

					new String:player_name[64];
					if (!GetClientName(attacker, player_name, 64))	{
						strcopy(player_name, 64, "UNKNOWN");
					}

					new String:player_authid[64];
					if (!GetClientAuthString(attacker, player_authid, 64)){
						strcopy(player_authid, 64, "UNKNOWN");
					}

					new player_userid = GetClientUserId(attacker);
					LogToGame("\"%s<%d><%s><%s>\" triggered \"headshot\"", player_name, player_userid, player_authid, player_team); 
				}
			}
		}

	} else if (strcmp(game_mod, "TF") == 0) {

		new custom_kill = GetEventInt(event, "customkill");
		
		if (custom_kill > 0) {

			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
		
			if ((attacker > 0) && (victim > 0)) {

				new victim_team_index = GetClientTeam(victim);
				new player_team_index = GetClientTeam(attacker);
		
				if (victim_team_index != player_team_index) {
		
					new String:player_team[64];
					player_team = team_list[player_team_index];

					new String:player_name[64];
					if (!GetClientName(attacker, player_name, 64))	{
						strcopy(player_name, 64, "UNKNOWN");
					}

					new String:player_authid[64];
					if (!GetClientAuthString(attacker, player_authid, 64)){
						strcopy(player_authid, 64, "UNKNOWN");
					}

					new player_userid = GetClientUserId(attacker);
					
					if (custom_kill == 1) {
						LogToGame("\"%s<%d><%s><%s>\" triggered \"headshot\"", player_name, player_userid, player_authid, player_team); 
					} else if (custom_kill == 2) {
						LogToGame("\"%s<%d><%s><%s>\" triggered \"backstab\"", player_name, player_userid, player_authid, player_team); 
					}
					
				}
			}
		}
	}
	
	return Plugin_Continue;
}


public Action: HLstatsX_Event_PlayerTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {
		new userid = GetEventInt(event, "userid");
		if (userid > 0) {
			new player_team_index = GetEventInt(event, "team");
			new String:player_team[64];
			player_team = team_list[player_team_index];
			new player_index = GetClientOfUserId(userid);
			if (player_index > 0) {
				if (IsClientInGame(player_index)) {
					if (player_index == ct_player_color) { 
						ct_player_color = -1;
					}
					if (player_index == ts_player_color) { 
						ts_player_color = -1;
					}
				}
			}
		}
	} else if (strcmp(game_mod, "TF") == 0) {
		new userid = GetEventInt(event, "userid");
		if (userid > 0) {
			new player_team_index = GetEventInt(event, "team");
			new String:player_team[64];
			player_team = team_list[player_team_index];
			new player_index = GetClientOfUserId(userid);
			if (player_index > 0) {
				if (IsClientInGame(player_index)) {
					if (player_index == blue_player_color) {
						blue_player_color = -1;
					}
					if (player_index == red_player_color) {
						red_player_color = -1;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

static const String: ct_models[4][] = {"models/player/ct_urban.mdl", 
                                       "models/player/ct_gsg9.mdl", 
                                       "models/player/ct_sas.mdl", 
                                       "models/player/ct_gign.mdl"};
static const String: ts_models[4][] = {"models/player/t_phoenix.mdl", 
                                       "models/player/t_leet.mdl", 
                                       "models/player/t_arctic.mdl", 
                                       "models/player/t_guerilla.mdl"};

stock set_player_model(client)
{
	if (client > 0) {
		if (strcmp(game_mod, "CSS") == 0) {
			if (IsClientConnected(client)) {
				new player_team_index = GetClientTeam(client);
				new String:player_team[64];
				player_team = team_list[player_team_index];			
				new new_model = GetRandomInt(0, 3);
				if (strcmp(player_team, "CT") == 0) {
					SDKCall(HandleSetModel, client, ct_models[new_model]);
				} else if (strcmp(player_team, "TERRORIST") == 0) {
					SDKCall(HandleSetModel, client, ts_models[new_model]);
				}
			}
		}
	}
}


stock swap_player(player_index)
{
	if (strcmp(game_mod, "CSS") == 0) {
		if (IsClientConnected(player_index)) {
			new player_team_index = GetClientTeam(player_index);
			new String:player_team[64];
			player_team = team_list[player_team_index];			
				
			new opposite_team_index = -1;
			if (strcmp(player_team, "CT") == 0) {
				opposite_team_index = get_team_index("TERRORIST");
			} else if (strcmp(player_team, "TERRORIST") == 0) {
				opposite_team_index = get_team_index("CT");
			}
			if (opposite_team_index > -1) {
				SDKCall(HandleSwitchTeam, player_index, opposite_team_index);
				SDKCall(HandleRoundRespawn, player_index);
				set_player_model(player_index);
			}
		}
	}
}

CreateHLstatsXMenuMain(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXMainCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Main Menu");
	AddMenuItem(MenuHandle, "", "Display Rank");
	AddMenuItem(MenuHandle, "", "Next Players");
	AddMenuItem(MenuHandle, "", "Top10 Players");
	AddMenuItem(MenuHandle, "", "Clans Ranking");
	AddMenuItem(MenuHandle, "", "Server Status");
	AddMenuItem(MenuHandle, "", "Statsme");
	AddMenuItem(MenuHandle, "", "Auto Ranking");
	AddMenuItem(MenuHandle, "", "Console Events");
	AddMenuItem(MenuHandle, "", "Weapon Usage");
	AddMenuItem(MenuHandle, "", "Weapons Accuracy");
	AddMenuItem(MenuHandle, "", "Weapons Targets");
	AddMenuItem(MenuHandle, "", "Player Kills");
	AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
	AddMenuItem(MenuHandle, "", "VAC Cheaterlist");
	AddMenuItem(MenuHandle, "", "Display Help");

	SetMenuPagination(MenuHandle, 8);
}

CreateHLstatsXMenuAuto(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXAutoCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Auto-Ranking");
	AddMenuItem(MenuHandle, "", "Enable on round-start");
	AddMenuItem(MenuHandle, "", "Enable on round-end");
	AddMenuItem(MenuHandle, "", "Enable on player death");
	AddMenuItem(MenuHandle, "", "Disable");

	SetMenuPagination(MenuHandle, 8);
}

CreateHLstatsXMenuEvents(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXEventsCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Console Events");
	AddMenuItem(MenuHandle, "", "Enable Events");
	AddMenuItem(MenuHandle, "", "Disable Events");
	AddMenuItem(MenuHandle, "", "Enable Global Chat");
	AddMenuItem(MenuHandle, "", "Disable Global Chat");

	SetMenuPagination(MenuHandle, 8);
}


stock make_player_command(client, String: player_command[]) 
{

	if (client > 0) {
		new String:player_name[64];
		if (!GetClientName(client, player_name, 64)) {
			strcopy(player_name, 64, "UNKNOWN");
		}

		new String:player_authid[64];
		if (!GetClientAuthString(client, player_authid, 64)) {
			strcopy(player_authid, 64, "UNKNOWN");
		}

		new player_team_index = GetClientTeam(client);
		new String:player_team[64];
		player_team = team_list[player_team_index];

		new player_userid = GetClientUserId(client);
		LogToGame("\"%s<%d><%s><%s>\" say \"%s\"", player_name, player_userid, player_authid, player_team, player_command); 
	}

}


public HLstatsXMainCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/rank");
				case 1 : 
					make_player_command(param1, "/next");
				case 2 : 
					make_player_command(param1, "/top10");
				case 3 : 
					make_player_command(param1, "/clans");
				case 4 : 
					make_player_command(param1, "/status");
				case 5 : 
					make_player_command(param1, "/statsme");
				case 6 : 
					DisplayMenu(HLstatsXMenuAuto, param1, MENU_TIME_FOREVER);
				case 7 : 
					DisplayMenu(HLstatsXMenuEvents, param1, MENU_TIME_FOREVER);
				case 8 : 
					make_player_command(param1, "/weapons");
				case 9 : 
					make_player_command(param1, "/accuracy");
				case 10 : 
					make_player_command(param1, "/targets");
				case 11 : 
					make_player_command(param1, "/kills");
				case 12 : 
					make_player_command(param1, "/hlx_hideranking");
				case 13 : 
					make_player_command(param1, "/cheaters");
				case 14 : 
					make_player_command(param1, "/help");
			}
		}
	}
}

public HLstatsXAutoCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/hlx_auto start rank");
				case 1 : 
					make_player_command(param1, "/hlx_auto end rank");
				case 2 : 
					make_player_command(param1, "/hlx_auto kill rank");
				case 3 : 
					make_player_command(param1, "/hlx_auto clear");
			}
		}
	}
}

public HLstatsXEventsCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/hlx_display 1");
				case 1 : 
					make_player_command(param1, "/hlx_display 0");
				case 2 : 
					make_player_command(param1, "/hlx_chat 1");
				case 3 : 
					make_player_command(param1, "/hlx_chat 0");
			}
		}
	}
}
