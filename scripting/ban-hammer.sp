/*

1.3.3:
	Added the slay-hammer to do everything except acually ban the victim;
	Added AdminMenu options for the Ban-Hammer and the Slay-Hammer;
	Merged the TF2 and CS:S versions back into one;
	Added function OnClientConnected();

1.3.2:
	TF2 version: added annotations
	Fixed SourceBans support
	
1.3.1:
	CS:S and TF2 versions splitted
	
1.3.0:
	Now all admins (players with BAN-flag) uses one list of victims;
	added effects (tf2/css) to faster searching victims;
	more commands...
	
1.2.2:
	Added function OnClientDisconnected();
	now you can't use banhammer vs other admins with flag ADMFLAG_BAN;
	fixed buddha (he disabled buddha everytime so that conflict with other plugins)
	
1.2.1:
	Common phrases (required for ReplyToTargetError()) fixed
	
1.2.0:
	Added argument to command (argument is a one or many targets, can be empty);
	added buddha ("ubercharge" for css );
	fixed buddha/ubercharging with any weapon;
	fixed media checks/paths;
	added render color changing for css;
	now you must set as weapon only default weapons (for example: if you want use "sledgehammer" you still must set "fireaxe"...)
	
1.1.1:
	Fixed effects, added sounds
	
1.1.0:
	Added debug mode (no-ban-mode);
	added compatibility with CS:S;
	added effects, fixed death-log disabling
	
1.0.1:
	Fixed text in chat;
	added custom log (Admin killed cheater with banhammer)
	
1.0.0:
	First release

*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.3.3"
//#define DEBUG

enum Hammer { NoHammer, BanHammer, SlayHammer, BanAllHammer };

new bool:g_IsTeamFortress = false;
new bool:g_IsCounterStrike = false;
new Handle:g_Enabled;
new Handle:g_Weapon;
new Handle:g_BanTime;
new Handle:g_Annotations;
new Hammer:g_Players[MAXPLAYERS+1] = { NoHammer, ... };
new g_VictimsArray[MAXPLAYERS+1] = { 0, ... };
new g_VictimsCount = 0;
new Float:g_LastKeyCheckTime[MAXPLAYERS+1] = { 0.0, ... };
new g_ExplosionSprite;
new g_GlowSprite;

new Handle:hAdminMenu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Ban-Hammer!",
	author = "Leonardo",
	description = "Admin can ban everyone by selected weapon",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	decl String:sGameType[16];
	GetGameFolderName(sGameType, sizeof(sGameType));
	g_IsTeamFortress = StrEqual(sGameType, "tf", true);
	if(g_IsTeamFortress)
	{
		g_Weapon = CreateConVar("banhammer_weapon", "fireaxe", "Weapon to use for the ban-hammer", 0);
		g_Annotations = CreateConVar("banhammer_annotations", "owned", "Enable/disable annotations");
	}
	else
	{
		g_IsCounterStrike = StrEqual(sGameType, "cstrike", true);
		if(g_IsCounterStrike)
			g_Weapon = CreateConVar("banhammer_weapon", "knife", "Weapon to use for the ban-hammer", 0);
		else
			SetFailState("This plugin is for TF2 or CS:S only.");
	}
	
	CreateConVar("banhammer_version", PLUGIN_VERSION, "", FCVAR_NOTIFY);
	g_Enabled = CreateConVar("banhammer_enable", "1", "Enable or disable plugin", 0, true, 0.0, true, 1.0);
	g_BanTime = CreateConVar("banhammer_bantime", "0", "Ban-time in minutes; 0=Permanent", 0, true, 0.0);
	
	RegAdminCmd("slayhammer", CmdEnable, ADMFLAG_SLAY, "Enable/disable slay-hammer");
	RegAdminCmd("banhammer", CmdEnable, ADMFLAG_BAN, "Enable/disable ban-hammer");
	RegAdminCmd("bh_toggle", CmdEnable, ADMFLAG_BAN, "Enable/disable ban-hammer");
	RegAdminCmd("bh_toggleall", CmdEnableAll, ADMFLAG_BAN, "Enable/disable ban-all-hammer");
	RegAdminCmd("bh_victims", CmdManage, ADMFLAG_BAN, "Manage list of players-to-ban");

	LoadTranslations("common.phrases.txt");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	if (LibraryExists("adminmenu"))
	{
		new Handle:topmenu = GetAdminTopMenu();
		if (topmenu != INVALID_HANDLE)
			OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	if(g_IsCounterStrike)
	{
		g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
		PrecacheSound("weapons/c4/c4_explode1.wav", true);
		g_GlowSprite = PrecacheModel("sprites/glow.vmt");
	}
	else if(g_IsTeamFortress)
	{
		PrecacheSound("items/cart_explode.wav", true);
		PrecacheSound("vo/announcer_victory.wav", true);
		g_GlowSprite = PrecacheModel("sprites/light_glow03.vmt");
	}

	for(new cell = 0; cell <= MAXPLAYERS; cell++)
	{
		g_VictimsArray[cell] = 0;
		g_Players[cell] = NoHammer;
		g_LastKeyCheckTime[cell] = 0.0;
	}
	g_VictimsCount = 0;
}

public OnGameFrame()
{
	if(GetConVarBool(g_Enabled))
	{
		for (new iClient = 1; iClient <= MaxClients; iClient++)
		{
			if( IsValidClient(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) > 1 )
			{
				new String:sWeapon[64], String:sCvarWeapon[64];
				GetClientWeapon(iClient, sWeapon, sizeof(sWeapon));
				GetConVarString(g_Weapon, sCvarWeapon, sizeof(sCvarWeapon));
				
				if( g_Players[iClient] > NoHammer && StrContains(sWeapon, sCvarWeapon, false) != -1 )
				{
					if(g_IsTeamFortress)
					{
						if( CheckElapsedTime(iClient,1.0) ) // prevent spamming
						{
							TF2_AddCondition(iClient, TFCond:TFCond_Ubercharged, 1.12);
							TF2_AddCondition(iClient, TFCond:TFCond_TeleportedGlow, 1.12);
							TF2_AddCondition(iClient, TFCond:TFCond_Kritzkrieged, 1.12);
							TF2_AddCondition(iClient, TFCond:TFCond_Overhealed, 1.12);
							SaveKeyTime(iClient);
						}
					}
					else if(g_IsCounterStrike)
					{
						if( IsValidEntity(iClient) )
							SetEntityRenderColor(iClient, 255, 87, 0, 91);
					}
					SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);
				}
				else
				{
					new bool:victimFound = false;
					for(new cell = 0; cell <= MAXPLAYERS; cell++)
					{
						if(g_VictimsArray[cell]!=0)
						{
							if(g_VictimsArray[cell]==iClient)
							{
								victimFound = true;
								break;
							}
						}
					}
					if(victimFound)
					{
						decl Float:clientOrigin[3];
						GetClientAbsOrigin(iClient, clientOrigin);
						clientOrigin[2] += 50;
						TE_SetupGlowSprite(clientOrigin, g_GlowSprite, 0.1, 0.5, 150);
						TE_SendToAll();
					}
					//SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
					if(g_IsCounterStrike)
					{
						if( IsValidEntity(iClient) )
							SetEntityRenderColor(iClient, 255, 255, 255, 100);
					}
				}
			}
		}
	}
}

public Action:CmdEnable(iClient, iArgs)
{
	if(iArgs>=1)
	{
		if (CmdManage(iClient, iArgs) == Plugin_Handled)
			return Plugin_Handled;
	}

	if(GetConVarBool(g_Enabled) && IsValidClient(iClient) && iClient>0)
	{
		decl String:command[64];
		GetCmdArg(0, command, sizeof(command));
		new bool:slay = StrEqual(command, "slayhammer");

		if(g_Players[iClient] != NoHammer)
		{
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
			if(g_IsCounterStrike)
				SetEntityRenderColor(iClient, 255, 255, 255, 255);

			ReplyToCommand(iClient, "%s-Hammer disabled for you.", (g_Players[iClient] == SlayHammer) ? "Slay" : "BAN");
			g_Players[iClient] = NoHammer;
		}
		else if(slay)
		{
			g_Players[iClient] = SlayHammer;
			ReplyToCommand(iClient, "Slay-Hammer enabled for you!");
		}
		else if(g_VictimsCount==0)
			ReplyToCommand(iClient, "BAN-Hammer: isn't allowed (victims not found).");
		else
		{
			g_Players[iClient] = BanHammer;
			ReplyToCommand(iClient, "BAN-Hammer: enabled for you.");
		}
	}
	return Plugin_Handled;
}


public Action:CmdEnableAll(iClient, iArgs)
{
	if(GetConVarBool(g_Enabled) && IsValidClient(iClient) && iClient>0)
	{
		if( g_Players[iClient]>NoHammer )
		{
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
			if(g_IsCounterStrike)
				SetEntityRenderColor(iClient, 255, 255, 255, 255);

			ReplyToCommand(iClient, "%s-Hammer disabled for you.", (g_Players[iClient] == SlayHammer) ? "Slay" : "BAN");
			g_Players[iClient] = NoHammer;
		}
		else
		{
			g_Players[iClient] = BanAllHammer;
			ReplyToCommand(iClient, "BAN-Hammer: enabled for you; you can ban anyone!");
		}
	}
	return Plugin_Handled;
}

public Action:CmdManage(iClient, iArgs)
{
	new String:buffer[512];
	new manageType = 0;
	
	if(iArgs>=1)
	{
		GetCmdArg(1, buffer, sizeof(buffer));
		if(StrEqual(buffer, "reset", false))
			manageType = 3;
		else if(!StrEqual(buffer, "list", false))
			manageType = 1;
	}
	
	if(iArgs==2)
	{
		GetCmdArg(2, buffer, sizeof(buffer));
		if(StrEqual(buffer, "remove", false))
			manageType = 2;
		else
			manageType = 1;
	}
	
	GetCmdArg(1, buffer, sizeof(buffer));
	if(manageType>0)
	{
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		new bool:dpl_check;
		
		if(manageType==3)
		{
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
				g_VictimsArray[cell] = 0;
			g_VictimsCount = 0;
			PrintToConsole(iClient, "BAN-Hammer: victims list cleaned");
#if defined DEBUG
			PrintToConsole(iClient, "BAN-Hammer: victims count: %d", g_VictimsCount);
#endif
			return Plugin_Handled;
		}
		
		if( (target_count = ProcessTargetString(buffer, iClient, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(iClient, target_count);
			return Plugin_Handled;
		}
		
		if(manageType==2)
		{
			decl tmpArray[MAXPLAYERS+1];
			new tmpCount;
			new victimsRemoved = 0;
			for(new count = 0; count <= target_count; count++)
			{
				if(IsValidClient(target_list[count]))
				{
					for(new cell = 0; cell <= MAXPLAYERS; cell++)
					{
						if(g_VictimsArray[cell]!=0)
						{
							if(g_VictimsArray[cell] == target_list[count])
							{
								g_VictimsArray[cell] = 0;
								victimsRemoved++;
							}
						}
					}
				}
			}
			tmpArray = g_VictimsArray;
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
			{
				if(tmpArray[cell]!=0)
				{
					g_VictimsArray[tmpCount++] = tmpArray[cell];
				}
			}
			g_VictimsCount = tmpCount;
			PrintToConsole(iClient, "BAN-Hammer: %d victims removed", victimsRemoved);
#if defined DEBUG
			PrintToConsole(iClient, "BAN-Hammer: victims count: %d", g_VictimsCount);
#endif
		}
		else
		{
			new victimsAdded = 0;
			for(new count = 0; count <= target_count; count++)
			{
				if(IsValidClient(target_list[count]) && target_list[count]>0)
				{
					if(target_list[count]!=iClient && !(GetUserFlagBits(target_list[count]) & ADMFLAG_BAN))
					{
						dpl_check = false;
						if(g_VictimsCount>0)
						{
							for(new cell = 0; cell <= MAXPLAYERS; cell++)
							{
								if(g_VictimsArray[cell]!=0)
								{
									if(g_VictimsArray[cell] == target_list[count])
									{
										dpl_check = true;
										break;
									}
								}
							}
						}
						if(!dpl_check)
						{
							for(new cell = 0; cell <= MAXPLAYERS; cell++)
							{
								if(g_VictimsArray[cell]==0)
								{
									g_VictimsArray[cell] = target_list[count];
									victimsAdded++;
									break;
								}
							}
						}
					}
				}
			}
			g_VictimsCount = 0;
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
			{
				if(g_VictimsArray[cell]!=0)
					g_VictimsCount++;
			}
			PrintToConsole(iClient, "BAN-Hammer: %d victims added", victimsAdded);
#if defined DEBUG
			PrintToConsole(iClient, "BAN-Hammer: victims count: %d", g_VictimsCount);
#endif
		}
	}
	else
	{
#if !defined DEBUG
		if(g_VictimsCount>0)
		{
#endif
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
			{
				if(g_VictimsArray[cell]>0)
				{
					new String:clientName[64];
					GetClientName(g_VictimsArray[cell], clientName, sizeof(clientName));
					PrintToConsole(iClient, "BAN-Hammer: victim #%d: %s (#%d)", cell, clientName, g_VictimsArray[cell]);
				}
			}
#if !defined DEBUG
		}
		else
			PrintToConsole(iClient, "BAN-Hammer: victims not found.");
#endif
	}
		
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	// checking settings:
	if (!GetConVarBool(g_Enabled)) return Plugin_Continue;

	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iVictim)) return Plugin_Continue;

	// Make sure the victim doesn't retain a hammer after death!
	if (g_Players[iVictim] != NoHammer)
	{
		SetEntProp(iVictim, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(iVictim, "%s-Hammer disabled for you.", (g_Players[iVictim] == SlayHammer) ? "Slay" : "BAN");
		g_Players[iVictim] = NoHammer;
	}

	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iAttacker)) return Plugin_Continue;
	
	new String:sAttackerAuth[32];
	//GetClientAuthString(iAttacker, sAttackerAuth, sizeof(sAttackerAuth));
	GetClientAuthId(iAttacker, AuthId_Steam2, sAttackerAuth, sizeof(sAttackerAuth));
	if( !(GetUserFlagBits(iAttacker) & ADMFLAG_BAN) ) return Plugin_Continue;
	
	if(g_Players[iAttacker]<=NoHammer) return Plugin_Continue;
	
	if(g_Players[iAttacker]==BanHammer)
	{
		if( g_VictimsCount==0 ) return Plugin_Continue;
	
		new String:sWeapon[64], String:sCVarWeapon[64];
		GetClientWeapon(iAttacker, sWeapon, sizeof(sWeapon));
		GetConVarString(g_Weapon, sCVarWeapon, sizeof(sCVarWeapon));
		if( StrContains(sWeapon, sCVarWeapon, false) < 0 ) return Plugin_Continue;
	
		// checking target-list:
		new bool:bVictimFound = false;
		for(new i = 0; i <= MAXPLAYERS; i++)
		{
			if(g_VictimsArray[i]>0)
			{
				if(g_VictimsArray[i] == iVictim)
				{
					bVictimFound = true;
					g_VictimsArray[i] = 0;
					g_VictimsCount--;
					break;
				}
			}
		}

		// prevent banning wrong player
		if(!bVictimFound) return Plugin_Continue;
	}
	
	if(g_IsTeamFortress) // prevent fake death in TF2
	{
		if( GetEventBool(hEvent, "feign_death") ) SetEventBool(hEvent, "feign_death", false);
	}
	
	// if everything is okay:
	SetEventString(hEvent, "weapon_logclassname", "banhammer");
	
	// effects, byatch!
	new bool:slay = (g_Players[iAttacker] == SlayHammer);
	CPrintToChatAllEx(iVictim, "\x01Player \x03%N\x01 humiliated by \x04%s-Hammer\x01!!!", iVictim, slay ? "Slay" : "BAN");
	CreateTimer(0.01, Timer_TimeToRunEffects, iVictim, TIMER_FLAG_NO_MAPCHANGE);
	
	if(g_IsTeamFortress) // prevent fake death in TF2
	{
		new String:sAnnotationText[32];
		GetConVarString(g_Annotations,sAnnotationText,sizeof(sAnnotationText));
		if(strlen(sAnnotationText)>2)
		{
			new Handle:hTmpEvent = CreateEvent("show_annotation");
			if (hTmpEvent != INVALID_HANDLE)
			{
				decl Float:pos[3];
				GetClientAbsOrigin(iVictim, pos);
				SetEventInt(hTmpEvent, "id", GetRandomInt(1,1000)*GetRandomInt(1,1000));
				SetEventFloat(hTmpEvent, "worldPosX", pos[0]);
				SetEventFloat(hTmpEvent, "worldPosY", pos[1]);
				SetEventFloat(hTmpEvent, "worldPosZ", pos[2]);
				SetEventInt(hTmpEvent, "visibilityBitfield", 16777215);
				SetEventString(hTmpEvent, "text", sAnnotationText);
				SetEventFloat(hTmpEvent, "lifetime", 10.0);
				FireEvent(hTmpEvent);
			}
		}
	}
	
	// banning...
#if !defined DEBUG
	if (!slay)
	{
		// if its not a debug mode, then this is for real :D
		CreateTimer(3.25, Timer_TimeToBan, iVictim, TIMER_FLAG_NO_MAPCHANGE);
	}
#endif
	
	// everyone banned? so, its time to disable banhammer
	if( g_Players[iAttacker]==BanHammer && g_VictimsCount==0 )
		FakeClientCommand(iAttacker, "banhammer");
	
	return Plugin_Continue;
}

public OnClientConnected(client)
{
	g_LastKeyCheckTime[client] = 0.0;
	g_Players[client] = NoHammer;
}

public OnClientDisconnect(iClient)
{
	for(new cell = 0; cell <= MAXPLAYERS; cell++)
	{
		if(g_VictimsArray[cell] == iClient)
		{
			g_VictimsArray[cell] = 0;
			g_VictimsCount--;
		}
	}
	if(g_VictimsCount==0)
	{
		for(new iAdmin = 0; iAdmin <= MAXPLAYERS; iAdmin++)
		{
			if(g_Players[iAdmin]==BanHammer && (GetUserFlagBits(iAdmin) & ADMFLAG_BAN))
				FakeClientCommand(iAdmin, "bh_toggle");
		}
	}
}

public Action:Timer_TimeToRunEffects(Handle:hTimer, any:iClient)
{
	decl Float:fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);
	if(g_IsTeamFortress)
	{
		EmitSoundToAll("items/cart_explode.wav", 0, SNDCHAN_WEAPON, 0, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, fOrigin, NULL_VECTOR, true, 0.0);
		ShowParticle(fOrigin, "cinefx_goldrush", 2.0);
	}
	if(g_IsCounterStrike)
	{
		EmitSoundToAll("weapons/c4/c4_explode1.wav", 0, SNDCHAN_WEAPON, 0, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, fOrigin, NULL_VECTOR, true, 0.0);
		TE_SetupExplosion(fOrigin, g_ExplosionSprite, 100.0, 1, 0, 0, 0);
		TE_SendToAll();
	}
	return Plugin_Handled;
}

public Action:Timer_TimeToBan(Handle:hTimer, any:iClient)
{
	if(FindConVar("sb_version")!=INVALID_HANDLE)
		ServerCommand("sm_ban #%d %d \"Humiliated by BAN-Hammer\"", GetClientUserId(iClient), GetConVarInt(g_BanTime));
	else
	{
		decl String:sBanReason[128];
		if(GetConVarInt(g_BanTime)>0)
			Format(sBanReason,sizeof(sBanReason),"You're banned for %d minutes on this server.");
		else
			Format(sBanReason,sizeof(sBanReason),"You're permanently banned on this server.");
		BanClient(iClient, GetConVarInt(g_BanTime), (BANFLAG_AUTHID|BANFLAG_IP), "Humiliated by BAN-Hammer", sBanReason);
	}

	if(g_IsTeamFortress)
	{
		decl Float:fOrigin[3];
		GetClientAbsOrigin(iClient, fOrigin);
		EmitSoundToAll("vo/announcer_victory.wav", 0, SNDCHAN_AUTO, 0, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, fOrigin, NULL_VECTOR, true, 0.0);
	}
	return Plugin_Handled;
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
            RemoveEdict(particle);
    }
}

stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    return IsClientInGame(iClient);
}

stock SaveKeyTime(any:iClient)
{
	if(iClient)
		g_LastKeyCheckTime[iClient] = GetGameTime();
}

stock bool:CheckElapsedTime(any:iClient, Float:time)
{
	if(iClient)
		if(IsClientInGame(iClient))
			if( GetGameTime() - g_LastKeyCheckTime[iClient] >= time)
				return true;
	return false;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu != hAdminMenu)
	{
		hAdminMenu = topmenu;

		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		if (server_commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(hAdminMenu,
					"banhammer",
					TopMenuObject_Item,
					AdminMenu_banhammer, 
					server_commands,
					"banhammer",
					ADMFLAG_BAN);

			AddToTopMenu(hAdminMenu,
					"slayhammer",
					TopMenuObject_Item,
					AdminMenu_slayhammer, 
					server_commands,
					"slayhammer",
					ADMFLAG_SLAY);
		}

		new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
		if (player_commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(hAdminMenu,
					"banknave",
					TopMenuObject_Item,
					AdminMenu_banknave, 
					player_commands,
					"banhammer",
					ADMFLAG_BAN);
		}
	}
}

public AdminMenu_banhammer( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		if(g_Players[param] == NoHammer)
			Format(buffer, maxlength, "Wield the mighty Ban Hammer!");
		else
			Format(buffer, maxlength, "Put down the Hammer.");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		CmdEnableAll(param, 0);
	}
}

public AdminMenu_slayhammer( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		if(g_Players[param] == NoHammer)
			Format(buffer, maxlength, "Wield the not so mighty Slay Hammer.");
		else
			Format(buffer, maxlength, "Put down the Hammer.");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		FakeClientCommand(param, "slayhammer");
	}
}

public AdminMenu_banknave( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		if(g_Players[param] == NoHammer)
			Format(buffer, maxlength, "Hunt a knave with the mighty Ban Hammer!");
		else
			Format(buffer, maxlength, "Put down the Hammer.");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param, BanHammer);
	}
}

DisplayPlayerMenu(client, Hammer:type)
{
	new Handle:menu = CreateMenu(MenuHandler_Players);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose a knave for the %s Hammer:", (type==SlayHammer) ? "slay" : "BAN");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	g_Players[client] = type;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target");
		}
		else
		{
			if (g_Players[param1] == SlayHammer)
				FakeClientCommand(param1, "slayhammer #%d", GetClientUserId(target));
			else
				FakeClientCommand(param1, "banhammer #%d", GetClientUserId(target));
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1, g_Players[param1]);
		}
	}
}

