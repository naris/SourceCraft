#include <sourcemod>
#include <colors>
#include <clientprefs>
#include <loghelper>
#include <donator>

#pragma semicolon 1

//Uncomment for yellow (majority of the time) in TF2
#define TF2

enum
{
 	cNone = 0,
	cTeamColor,
	cGreen,
	cOlive,
	#if defined TF2
	cCustom,
	#endif
	cRandom,
	cMax
};

new String:szColorCodes[][] = {
	"\x01", "\x03", "\x04", "\x05"
	#if defined TF2
	, "\x06"
	#endif
};

new const String:szColorNames[cMax][] = {
	"None",
	"Team Color",
	"Green",
	"Olive",
	#if defined TF2
	"Custom",
	#endif
	"Random"
};

new g_iColor[MAXPLAYERS + 1];
new bool:g_bIsDonator[MAXPLAYERS + 1];
new Handle:g_ColorCookie = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Donator: Colored Chat",
	author = "Nut",
	description = "Donators get colored chat!",
	version = "0.4",
	url = ""
}

public OnPluginStart()
{
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
	
	g_ColorCookie = RegClientCookie("donator_colorcookie", "Chat color for donators.", CookieAccess_Private);
}

public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
	Donator_RegisterMenuItem("Set Chat Color", ChatColorCallback);
}

public OnPostDonatorCheck(iClient)
{
	if (!(g_bIsDonator[iClient] = IsPlayerDonator(iClient))) return;
	g_iColor[iClient] = cNone;

	if (AreClientCookiesCached(iClient))
	{
		new String:szBuffer[2];
		GetClientCookie(iClient, g_ColorCookie, szBuffer, sizeof(szBuffer));

		if (strlen(szBuffer) > 0)
			g_iColor[iClient] = StringToInt(szBuffer);
	}
}

public OnClientDisconnect(iClient)
{
	g_iColor[iClient] = cNone;
	g_bIsDonator[iClient] = false;
}

public Action:SayCallback(iClient, const String:szCommand[], iArgc)
{
	if (!iClient) return Plugin_Continue;
	if (!g_bIsDonator[iClient]) return Plugin_Continue;
	
	decl String:szArg[255], String:szChatMsg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);

	if(szArg[0] == '/' || szArg[0] == '!' || szArg[0] == '@')	return Plugin_Continue;

	new iColor = g_iColor[iClient];
	if (!iColor) return Plugin_Continue;
	if (SkipCommand(szArg)) return Plugin_Continue;
	
	if (iColor == cRandom)
		iColor = GetRandomInt(cNone+1, cRandom-1);
	
	PrintToServer("%N: %s", iClient, szArg);
	
	if (StrEqual(szCommand, "say", true))
	{
		LogPlayerEvent(iClient, "say_team", szArg);
		FormatEx(szChatMsg, 255, "\x03%N\x01 :  %c%s", iClient, szColorCodes[iColor], szArg);
		CPrintToChatAllEx(iClient, szChatMsg);
	}
	else
	{
		LogPlayerEvent(iClient, "say", szArg);
		FormatEx(szChatMsg, 255, "(TEAM) \x03%N\x01 :  %c%s", iClient, szColorCodes[iColor], szArg);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(GetClientTeam(iClient) == GetClientTeam(i))
			CPrintToChatEx(i, iClient, szChatMsg);
		}
	}
	return Plugin_Handled;
}

public DonatorMenu:ChatColorCallback(iClient) Panel_SetColor(iClient);

public Action:Panel_SetColor(iClient)
{
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Donator: Set Chat Color:");
	
	for(new i = 0; i < cMax; i++)
		if (g_iColor[iClient] == i)
			DrawPanelItem(hPanel, szColorNames[i], ITEMDRAW_DISABLED);
		else
			DrawPanelItem(hPanel, szColorNames[i], ITEMDRAW_DEFAULT);

	SendPanelToClient(hPanel, iClient, PanelHandler, 20);
	CloseHandle(hPanel);
}

public PanelHandler(Handle:menu, MenuAction:action, iClient, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new iColor = param2 - 1;
			g_iColor[iClient] = iColor;
			
			decl String:szColor[5];
			FormatEx(szColor, sizeof(szColor), "%i", iColor);
			SetClientCookie(iClient, g_ColorCookie, szColor);
			if (iColor == cRandom)
				CPrintToChat(iClient, "[SM]: Your new chat color is {olive}random{default}.");
			else
				CPrintToChatEx(iClient, iClient, "[SM]: %cThis is your new chat color.", szColorCodes[iColor]);
		}
	}
}

bool:SkipCommand(const String:szArg[])
{
	decl String:szSplit[2][64];
	ExplodeString(szArg, " ", szSplit, 2, 64);

        if (StrEqual(szSplit[0],"scmenu") ||
            StrEqual(szSplit[0],"menu"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"shopmenu") ||
                 StrEqual(szSplit[0],"scbuy") ||
                 StrEqual(szSplit[0],"buy"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"changeunit") ||
                 StrEqual(szSplit[0],"changerace"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"unitinfo") ||
                 StrEqual(szSplit[0],"raceinfo"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"reset") ||
                 StrEqual(szSplit[0],"resetupgrades") ||
                 StrEqual(szSplit[0],"resetskills"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"upgrade") ||
                 StrEqual(szSplit[0],"spendup") ||
                 StrEqual(szSplit[0],"spendupgrades") ||
                 StrEqual(szSplit[0],"spendskills"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"schelp") ||
                 StrEqual(szSplit[0],"help"))
        {
            return true;
        }
        else if(StrEqual(szSplit[0],"scsettings"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"info") ||
                 StrEqual(szSplit[0],"show"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"playerinfo") ||
                 StrEqual(szSplit[0],"showplayer"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"showup") ||
                 StrEqual(szSplit[0],"upinfo") ||
                 StrEqual(szSplit[0],"showupgrades") ||
                 StrEqual(szSplit[0],"upgradeinfo") ||
                 StrEqual(szSplit[0],"showskills") ||
                 StrEqual(szSplit[0],"skillsinfo"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"showitems") ||
                 StrEqual(szSplit[0],"inventory") ||
                 StrEqual(szSplit[0],"inv"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"xp") ||
                 StrEqual(szSplit[0],"showxp") ||
                 StrEqual(szSplit[0],"showexp") ||
                 StrEqual(szSplit[0],"showexperience"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"crystals") || 
                 StrEqual(szSplit[0],"showcrystals") ||
                 StrEqual(szSplit[0],"showc"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"vespene") || 
                 StrEqual(szSplit[0],"showvespene") ||
                 StrEqual(szSplit[0],"showv"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"energy") || 
                 StrEqual(szSplit[0],"showenergy") ||
                 StrEqual(szSplit[0],"showe"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"scinfo") || 
                 StrEqual(szSplit[0],"details") || 
                 StrEqual(szSplit[0],"lookup"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"wiki") || 
                 StrEqual(szSplit[0],"guiki"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"scinfo") || 
                 StrEqual(szSplit[0],"updates"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"scbug") || 
                 StrEqual(szSplit[0],"bug"))
        {
            return true;
        }
        else if (StrEqual(szSplit[0],"killme"))
        {
            return true;
        }
	else
		return false;
}

