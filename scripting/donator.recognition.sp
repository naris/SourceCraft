/*
* Gives those donators the recognition they deserve :)
* 
* Changelog:
* 
* v0.3 - release
* v0.4 - Enable/ disable in donator > sprite menu/ proper error without interface
* v.05 - Expanded to support multiple sprites/ fixed SetParent error
* v.06 - Naris merged changes to support other mods besides TF2 and
* 	 Support using an admin flag instead of the donator.core plugin
*
*/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#undef REQUIRE_EXTENSIONS
#include <donator>

#tryinclude <gametype>
#tryinclude <entlimit>

#pragma semicolon 1

#define PLUGIN_VERSION	"0.6"

//Supports multiple sprites
#define TOTAL_SPRITE_FILES 2

new gVelocityOffset;

new const String:szSpriteNames[TOTAL_SPRITE_FILES][] =
{
	"Money Sign",
	"Money Sign / Cloud"
};

//NOTE: Path to the filename ONLY (vtf/vmt added in plugin)
new const String:szSpriteFiles[TOTAL_SPRITE_FILES][] = 
{
	"materials/custom/$",
	"materials/custom/donator2"
};

enum _:tColors
{
	tColor_Black,
	tColor_White,
	tColor_Orange,
	tColor_Yellow,
	tColor_Green,
	tColor_Blue,
	tColor_Red,
	tColor_Lime,
	tColor_Aqua,
	tColor_Grey,
	tColor_Purple,
	tColor_Max
}

new const String:szColorValues[tColor_Max][11] =
{
	"0 0 0", "255 255 255", "255 102 0",
	"255 255 0", "0 128 0", "0 0 255",
	"255 0 0", "0 255 0", "0 255 255",
	"128 128 128", "128 0 128"
};

new const String:szColorNames[tColor_Max][11] =
{
	"Black", "White", "Orange",
	"Yellow", "Green", "Blue",
	"Red", "Lime", "Aqua",
	"Grey", "Purple"
};

new g_EntList[MAXPLAYERS + 1];
new g_bIsDonator[MAXPLAYERS + 1];
new bool:g_bRoundEnded;
new bool:g_bDonatorLoaded;
new bool:g_bDisplaySprites;
new Handle:g_HudSync = INVALID_HANDLE;
new Handle:g_TagColorCookie = INVALID_HANDLE;
new Handle:g_SpriteShowCookie = INVALID_HANDLE;

new Handle:g_AlwaysCvar = INVALID_HANDLE;
new Handle:g_AtStartCvar = INVALID_HANDLE;
new Handle:g_AdminFlagCvar = INVALID_HANDLE;
new Handle:g_DuringSetupCvar = INVALID_HANDLE;

new g_iTagColor[MAXPLAYERS + 1][4];
new g_iShowSprite[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Donator Recognition",
	author = "Nut",
	description = "Give donators the recognition they deserve.",
	version = PLUGIN_VERSION,
	url = "http://www.lolsup.com/tf2"
}

/**
 * Description: Function to determine game/mod type
 */
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
    {
        if (GameType == undetected)
        {
            new String:modname[30];
            GetGameFolderName(modname, sizeof(modname));
            if (StrEqual(modname,"cstrike",false))
                GameType=cstrike;
            else if (StrEqual(modname,"tf",false)) 
                GameType=tf2;
            else if (StrEqual(modname,"dod",false)) 
                GameType=dod;
            else if (StrEqual(modname,"hl2mp",false)) 
                GameType=hl2mp;
            else if (StrEqual(modname,"Insurgency",false)) 
                GameType=insurgency;
            else if (StrEqual(modname,"left4dead", false)) 
                GameType=l4d;
            else if (StrEqual(modname,"left4dead2", false)) 
                GameType=l4d2;
            else if (StrEqual(modname,"zps",false)) 
                GameType=zps;
            else
                GameType=other_game;
        }
        return GameType;
    }
#endif

/**
 * Description: Function to determine if too many entities have been used
 */
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
	new max = GetMaxEntities();
	new count = GetEntityCount();
	new remaining = max - count;
	if (remaining <= warn)
	{
	    if (count <= critical)
	    {
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

		if (client > 0)
		{
		    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
				   count, max, remaining, message);
		}
	    }
	    else
	    {
		PrintToServer("Caution: Entity count is getting high!");
		LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

		if (client > 0)
		{
		    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
				   count, max, remaining, message);
		}
	    }
	    return count;
	}
	else
	    return 0;
    }
#endif


public OnPluginStart()
{
	CreateConVar("basicdonator_recog_v", PLUGIN_VERSION, "Donator Recognition Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_DuringSetupCvar = CreateConVar("basicdonator_during_setup", "1", "Donator Recognition During Setup?", FCVAR_PLUGIN);
	g_AdminFlagCvar = CreateConVar("basicdonator_admin_flag", "", "Optional Admin flag that indicates a donator", FCVAR_PLUGIN);
	g_AtStartCvar = CreateConVar("basicdonator_at_start", "1", "Donator Recognition When Round Starts?", FCVAR_PLUGIN);
	g_AlwaysCvar = CreateConVar("basicdonator_always", "0", "Donator Recognition All the Time?", FCVAR_PLUGIN);
	
	HookEventEx("player_spawn", event_player_spawn, EventHookMode_Post);
	HookEventEx("player_death", event_player_death, EventHookMode_Post);

	if (GetGameType() == tf2)
	{
		HookEventEx("teamplay_round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("arena_round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_round_win", hook_Win, EventHookMode_PostNoCopy);
		HookEventEx("arena_win_panel", hook_Win, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_setup_finished", hook_Setup, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_round_active", hook_Active, EventHookMode_PostNoCopy);
	}
	else if (GameType == dod)
	{
		HookEventEx("dod_round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("dod_round_active", hook_Setup, EventHookMode_PostNoCopy);
		HookEventEx("dod_round_win", hook_Win, EventHookMode_Post);
	}
	else if (GameType == cstrike)
	{
		HookEventEx("round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("round_active", hook_Setup, EventHookMode_PostNoCopy);
		HookEventEx("round_end", hook_Win, EventHookMode_Post);
	}
	
	g_HudSync = CreateHudSynchronizer();
	g_TagColorCookie = RegClientCookie("donator_tagcolor", "Chat color for donators.", CookieAccess_Private);
	g_SpriteShowCookie = RegClientCookie("donator_spriteshow", "Which donator sprite to show.", CookieAccess_Private);
	
	AddCommandListener(SayCallback, "donator_tag");
	AddCommandListener(SayCallback, "donator_tagcolor");

	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

public OnAllPluginsLoaded()
{
	//if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
	g_bDonatorLoaded = LibraryExists("donator.core");
	if (g_bDonatorLoaded)
	{
		Donator_RegisterMenuItem("Change Donator Tag", ChangeTagCallback);
		Donator_RegisterMenuItem("Change Tag Color", ChangeTagColorCallback);
		Donator_RegisterMenuItem("Change Sprite", SpriteControlCallback);
	}
}

public OnConfigsExecuted()
{
	if (!g_bDonatorLoaded)
	{
		decl String:adminFlag[2];
		GetConVarString(g_AdminFlagCvar, adminFlag, sizeof(adminFlag));
		if (adminFlag[0] == '\0')
		{
			SetFailState("Unabled to find plugin: Basic Donator Interface and basicdonator_admin_flag is not set!");
		}
	}
}

public OnMapStart()
{
	decl String:szBuffer[128];
	for (new i = 0; i < TOTAL_SPRITE_FILES; i++)
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[i]);
		PrecacheGeneric(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		FormatEx(szBuffer, sizeof(szBuffer), "%s.vtf", szSpriteFiles[i]);
		PrecacheGeneric(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
	}
}

public OnPostDonatorCheck(iClient)
{
	if (!IsPlayerDonator(iClient)) return;
	
	g_bIsDonator[iClient] = true;
	g_iShowSprite[iClient] = 1;
	g_iTagColor[iClient] = {255, 255, 255, 255};
	
	new String:szBuffer[256];
	if (AreClientCookiesCached(iClient))
	{
		GetClientCookie(iClient, g_TagColorCookie, szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) > 0)
		{
			decl String:szTmp[3][16];
			ExplodeString(szBuffer, " ", szTmp, 3, sizeof(szTmp[]));
			g_iTagColor[iClient][0] = StringToInt(szTmp[0]); 
			g_iTagColor[iClient][1] = StringToInt(szTmp[1]);
			g_iTagColor[iClient][2] = StringToInt(szTmp[2]);
		}
		
		GetClientCookie(iClient, g_SpriteShowCookie, szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) > 0)
			g_iShowSprite[iClient] = StringToInt(szBuffer);
	}
	
	GetDonatorMessage(iClient, szBuffer, sizeof(szBuffer));
	ShowDonatorMessage(iClient, szBuffer);
}

public OnClientPostAdminCheck(client)
{
	decl String:adminFlag[2];
	GetConVarString(g_AdminFlagCvar, adminFlag, sizeof(adminFlag));

	if (adminFlag[0])
	{
		new AdminFlag:flag;
		if (FindFlagByChar(adminFlag[0], flag))
		{
			new AdminId:aid = GetUserAdmin(client);
			g_bIsDonator[client] = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, flag, Access_Effective);
		}
		else
		{
			SetFailState("Admin flag %c not found", adminFlag[0]);
		}
	}
}

public OnClientDisconnect(iClient)
{
	g_bIsDonator[iClient] = false;
	KillSprite(iClient);
}

public Action:SayCallback(iClient, const String:command[], argc)
{
	if(!iClient) return Plugin_Continue;
	if (!g_bDonatorLoaded) return Plugin_Continue;
	if (!g_bIsDonator[iClient]) return Plugin_Continue;

	decl String:szArg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);

	if (StrEqual(command, "donator_tag", true))
	{
		decl String:szTmp[256];
		if (strlen(szArg) < 1)
		{
			GetDonatorMessage(iClient, szTmp, sizeof(szTmp));
			ReplyToCommand(iClient, "[SM] Your current tag is: %s", szTmp);
		}
		else
		{
			PrintToChat(iClient, "\x01[SM] You have sucessfully changed your tag to: \x04%s\x01", szArg);
			SetDonatorMessage(iClient, szArg);
		}
	}
	else if (StrEqual(command, "donator_tagcolor", true))
	{
		decl String:szTmp[3][16];
		if (strlen(szArg) < 1)
		{
			GetClientCookie(iClient, g_TagColorCookie, szTmp[0], sizeof(szTmp[]));
			ReplyToCommand(iClient, "[SM] Your current tag color is: %s", szTmp[0]);
		}
		else
		{
			ExplodeString(szArg, " ", szTmp, 3, sizeof(szTmp[]));
			ReplyToCommand(iClient, "[SM] You have sucessfully changed your color to %s", szArg);
			SetClientCookie(iClient, g_TagColorCookie, szArg);
		}
	}
	return Plugin_Handled;
}

public ShowDonatorMessage(iClient, String:message[])
{
	SetHudTextParamsEx(-1.0, 0.22, 4.0, g_iTagColor[iClient], {0, 0, 0, 255}, 1, 5.0, 0.15, 0.15);
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			ShowSyncHudText(i, g_HudSync, message);
}

public hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bDisplaySprites = GetConVarBool(g_AtStartCvar);
	if (g_bDisplaySprites)
	{
		decl String:szBuffer[128];
		for(new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
			if (!g_bIsDonator[i]) continue;
			
			if (g_iShowSprite[i] > 0)
			{
				if (g_iShowSprite[i] > TOTAL_SPRITE_FILES) g_iShowSprite[i] = TOTAL_SPRITE_FILES - 1;
				FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[g_iShowSprite[i]-1]);
				CreateSprite(i, szBuffer, 25.0);
			}
		}
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (!g_bIsDonator[i]) continue;
			KillSprite(i);
		}
	}
	g_bRoundEnded = false;
}

public hook_Setup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_AtStartCvar) && !GetConVarBool(g_AlwaysCvar))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			KillSprite(i);
		}
	}
	g_bDisplaySprites = false;
}

public hook_Active(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_AlwaysCvar))
	{
		if (GetConVarBool(g_DuringSetupCvar))
		{
			new timer = FindEntityByClassname(MaxClients+1, "team_round_timer");
			if (timer > 0 && GetEntProp(timer, Prop_Send, "m_nState") == 0)
			{
				new m_nSetupTimeLength = GetEntProp(timer, Prop_Send, "m_nSetupTimeLength");
				if (m_nSetupTimeLength > 0)
				{
					// Create a timer in case the setup isn't real
					// (such as the last stage of plr_pipeline)
					CreateTimer(float(m_nSetupTimeLength), Timer_SetupOver);
					return;
				}
			}
		}

		hook_Setup(event, name, dontBroadcast);
	}
}

public Action:Timer_SetupOver(Handle:timer, any:client)
{
	if (g_bDisplaySprites)
		hook_Setup(INVALID_HANDLE, "SetupOver", false);
}

public hook_Win(Handle:event, const String:name[], bool:dontBroadcast)
{	
	decl String:szBuffer[128];
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
		if (!g_bIsDonator[i]) continue;
		
		if (g_iShowSprite[i] > 0)
		{
			if (g_iShowSprite[i] > TOTAL_SPRITE_FILES) g_iShowSprite[i] = TOTAL_SPRITE_FILES - 1;
			FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[g_iShowSprite[i]-1]);
			CreateSprite(i, szBuffer, 25.0);
		}
	}
	g_bRoundEnded = true;
	g_bDisplaySprites = true;
}

public TF2_OnWaitingForPlayersStart()
{
    decl String:szBuffer[128];
    for(new i = 1; i <= MaxClients; i++)
    {
	    if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
	    if (!g_bIsDonator[i]) continue;
	    
	    if (g_iShowSprite[i] > 0)
	    {
		    if (g_iShowSprite[i] > TOTAL_SPRITE_FILES) g_iShowSprite[i] = TOTAL_SPRITE_FILES - 1;
		    FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[g_iShowSprite[i]-1]);
		    CreateSprite(i, szBuffer, 25.0);
	    }
    }
    g_bDisplaySprites = true;
}

public TF2_OnWaitingForPlayersEnd()
{
    hook_Setup(INVALID_HANDLE, "WaitingEnd", false);
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:szBuffer[128];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bDisplaySprites && g_bIsDonator[client] && g_iShowSprite[client] > 0)
	{
		if (g_iShowSprite[client] > TOTAL_SPRITE_FILES) g_iShowSprite[client] = TOTAL_SPRITE_FILES - 1;
		FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[g_iShowSprite[client]-1]);
		CreateSprite(client, szBuffer, 25.0);
	}
	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bRoundEnded) return Plugin_Continue;
	KillSprite(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

public DonatorMenu:ChangeTagCallback(iClient) Panel_ChangeTag(iClient);
public DonatorMenu:ChangeTagColorCallback(iClient) Panel_ChangeTagColor(iClient);
public DonatorMenu:SpriteControlCallback(iClient) Panel_SpriteControl(iClient);

public Action:Panel_ChangeTag(iClient)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Donator: Change Tag:");
	
	new String:szBuffer[256];
	GetDonatorMessage(iClient, szBuffer, sizeof(szBuffer));
	DrawPanelItem(panel, "Your current donator tag is:", ITEMDRAW_DEFAULT);
	DrawPanelItem(panel, szBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "space", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "Type the following in the console to change your tag:", ITEMDRAW_CONTROL);
	DrawPanelItem(panel, "donator_tag \"YOUR TAG GOES HERE\"", ITEMDRAW_RAWLINE);
	
	SendPanelToClient(panel, iClient, PanelHandlerBlank, 20);
	CloseHandle(panel);
}

public Action:Panel_ChangeTagColor(iClient)
{
	new Handle:menu = CreateMenu(TagColorMenuSelected);
	SetMenuTitle(menu,"Donator: Change Tag Color:");
	
	decl String:szBuffer[256];
	FormatEx(szBuffer, sizeof(szBuffer), "%i %i %i", g_iTagColor[iClient][0], g_iTagColor[iClient][1], g_iTagColor[iClient][2]);

	decl String:szItem[4];
	for (new i = 0; i < tColor_Max; i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		if (StrEqual(szBuffer, szColorValues[i]))
			AddMenuItem(menu, szItem, szColorNames[i], ITEMDRAW_DISABLED);
		else
			AddMenuItem(menu, szItem, szColorNames[i], ITEMDRAW_DEFAULT);
	}
	DisplayMenu(menu, iClient, 20);
}

public Action:Panel_SpriteControl(iClient)
{
	new Handle:menu = CreateMenu(SpriteControlSelected);
	SetMenuTitle(menu,"Donator: Sprite Control:");
	
	if (g_iShowSprite[iClient] > 0)
		AddMenuItem(menu, "0", "Disable Sprite", ITEMDRAW_DEFAULT);
	else
		AddMenuItem(menu, "0", "Disable Sprite", ITEMDRAW_DISABLED);
	
	decl String:szItem[4];
	for (new i = 0; i < TOTAL_SPRITE_FILES; i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i+1);	//need to offset the menu items by one since we added the enable / disable outside of the loop
		if (g_iShowSprite[iClient]-1 != i)
			AddMenuItem(menu, szItem, szSpriteNames[i], ITEMDRAW_DEFAULT);
		else
			AddMenuItem(menu, szItem, szSpriteNames[i],ITEMDRAW_DISABLED);
	}
	DisplayMenu(menu, iClient, 20);
}

public TagColorMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:szTmp[3][16], iColor[4];
			
			ExplodeString(szColorValues[iSelected], " ", szTmp, 3, sizeof(szTmp[]));
			iColor[0] = StringToInt(szTmp[0]); 
			iColor[1] = StringToInt(szTmp[1]);
			iColor[2] = StringToInt(szTmp[2]);
			iColor[3] = 255;
			
			g_iTagColor[param1] = iColor;
			
			SetHudTextParamsEx(-1.0, 0.22, 4.0, iColor, {0, 0, 0, 255}, 1, 5.0, 0.15, 0.15);
			ShowSyncHudText(param1, g_HudSync, "This is your new tag color.");
			SetClientCookie(param1, g_TagColorCookie, szColorValues[iSelected]);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

public SpriteControlSelected(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			g_iShowSprite[param1] = iSelected;
			decl String:szSelected[2];
			Format(szSelected, sizeof(szSelected), "%i", iSelected);
			SetClientCookie(param1, g_SpriteShowCookie, szSelected);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

public PanelHandlerBlank(Handle:menu, MenuAction:action, iClient, param2) {}

//--------------------------------------------------------------------------------------------------

stock CreateSprite(iClient, String:sprite[], Float:offset)
{
	if (g_EntList[iClient] > 0 || IsEntLimitReached())
		return;

	new String:szTemp[64]; 
	Format(szTemp, sizeof(szTemp), "client%i", iClient);
	DispatchKeyValue(iClient, "targetname", szTemp);

	new Float:vOrigin[3];
	GetClientAbsOrigin(iClient, vOrigin);
	vOrigin[2] += offset;
	new ent = CreateEntityByName("env_sprite_oriented");
	if (ent)
	{
		DispatchKeyValue(ent, "model", sprite);
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "donator_spr");
		DispatchKeyValue(ent, "parentname", szTemp);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);

		g_EntList[iClient] = ent;

		if (GameType != tf2)
		{
			SetVariantString(szTemp);
			AcceptEntityInput(ent, "SetParent", ent, ent, 0);
			SetVariantString("head");
			AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
		}
	}
}

stock KillSprite(iClient)
{
	if (g_EntList[iClient] > 0 && IsValidEntity(g_EntList[iClient]))
	{
		AcceptEntityInput(g_EntList[iClient], "kill");
		g_EntList[iClient] = 0;
	}
}
public OnGameFrame()
{
	if (GameType != tf2) return;
	if (!g_bRoundEnded && !g_bDisplaySprites) return;
	new ent, Float:vOrigin[3], Float:vVelocity[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if ((ent = g_EntList[i]) > 0)
		{
			if (!IsValidEntity(ent))
				g_EntList[i] = 0;
			else
				if ((ent = EntRefToEntIndex(ent)) > 0)
				{
					GetClientEyePosition(i, vOrigin);
					vOrigin[2] += 25.0;
					GetEntDataVector(i, gVelocityOffset, vVelocity);
					TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
				}
		}
	}
}
