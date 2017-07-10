/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/*

Versions:
	3.0
        	+ Fixed handle leaks in serverdirect.sp

	1.1
		+ Can prevent empty servers from being advertised by setting sm_redirect_ads_hideempty to 1
 		+ {MAP}, {CURR} and {MAX} can now be used in the sm_redirect_ads_format var.
		+ Interval between ads can now be changed without having to reload the plugin.

	1.0 - initial release
	
*/

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <serverredirect>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "3.0"
#define LIB_REDIR "serverredir"

new Handle:g_varAdsInterval;
new Handle:g_varAdsFormat;
new Handle:g_varHideEmptyServers;						// When set, empty servers will not be shown in the ads
new Handle:g_adsTimer = INVALID_HANDLE;

new String:g_lastAddress[50];			// address which was most recently advertised
new bool:g_isRedirLibLoaded;			// whether the redirect library has been loaded

public Plugin:myinfo = 
{
	name = "Server Redirect Ads",
	author = "Brainstorm",
	description = "Advertises redirect servers.",
	version = PLUGIN_VERSION,
	url = "http://www.teamfortress.be"
}

public OnPluginStart()
{
	strcopy(g_lastAddress, sizeof(g_lastAddress), "[nothing]");
	g_varAdsInterval = CreateConVar("sm_redirect_ads_interval", "60", "sm_redirect_ads_interval - interval in seconds", 0, true, 2.0, false);
	g_varAdsFormat = CreateConVar("sm_redirect_ads_format", "Also available: {NAME} ({IP}) - Say !servers to switch servers.", "sm_redirect_ads_format - formatting string for advertisements");
	g_varHideEmptyServers = CreateConVar("sm_redirect_ads_hideempty", "0", "sm_redirect_ads_hideempty - when set, servers without players will not be advertised", 0, true, 0.0, true, 1.0);
	
	g_isRedirLibLoaded = LibraryExists(LIB_REDIR);

	AutoExecConfig(true, "plugin.serverredirect_ads");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, LIB_REDIR))
	{
		g_isRedirLibLoaded = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, LIB_REDIR))
	{
		g_isRedirLibLoaded = true;
	}
}

public OnMapStart()
{
	StartAdsTimer();
	HookConVarChange(g_varAdsInterval, OnAdsIntervalChange);
}

public OnMapEnd()
{
	EndAdsTimer();
	UnhookConVarChange(g_varAdsInterval, OnAdsIntervalChange);
}

public OnAdsIntervalChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EndAdsTimer();
	StartAdsTimer();
}

StartAdsTimer()
{
	EndAdsTimer();
	new Float:interval = GetConVarFloat(g_varAdsInterval);
	g_adsTimer = CreateTimer(interval, Timer_AdsUpdate, INVALID_HANDLE, TIMER_REPEAT);
}

EndAdsTimer()
{
	if (g_adsTimer != INVALID_HANDLE)
	{
		KillTimer(g_adsTimer);
		g_adsTimer = INVALID_HANDLE;
	}
}

public Action:Timer_AdsUpdate(Handle:timer)
{
	if (!g_isRedirLibLoaded)
	{
		LogError("Server redirect plugin not loaded, unable to display redirect ads. Please check your server configuration.");
	}
	else
	{
		LoadServerRedirectListFiltered(false, false, RedirListLoaded, 0);
	}
}

public Action:Command_List(client, args)
{
	LoadServerRedirectListFiltered(false, true, RedirListLoaded, 0);
	return Plugin_Handled;
}

public RedirListLoaded(serverCount, const String:error[], Handle:serverList, any:nothing)
{
	if (serverCount < 0)
	{
		LogError("Failed to load redirect server list, error: %s", error);
	}
	else if (serverCount > 0)
	{
		// remove empty servers if needed
		new bool:hideEmpty = GetConVarBool(g_varHideEmptyServers);
		
		if (hideEmpty)
		{
			KvRewind(serverList);
			KvGotoFirstSubKey(serverList);
			new bool:hasMore;
			do
			{
				new playerCount = KvGetNum(serverList, "currentplayers", 0);
				if (playerCount <= 0)
				{
					new result = KvDeleteThis(serverList);
					if (result == 1)
					{
						hasMore = true;
					}
					else if (result == -1)
					{
						hasMore = false;
					}
					else
					{
						// should not happen
						LogError("Failed to delete empty server upon disoplaying redirect ads");
					}
				}
				else
				{
					hasMore = KvGotoNextKey(serverList);
				}
			}
			while(hasMore);
		}
		
		// find a server to be displayed. Attempt to exclude the most recent address.
		decl String:address[50];
		new mostRecentIndex = -1;			// index of the most recent address in the current list
		new currentIndex = 0;
		
		// count servers, determine index of current address
		KvRewind(serverList);
		KvGotoFirstSubKey(serverList);
		do
		{
			KvGetSectionName(serverList, address, sizeof(address));
			
			if (strcmp(address, g_lastAddress, false) == 0)
			{
				mostRecentIndex = currentIndex;
			}
			
			currentIndex++;
		}
		while (KvGotoNextKey(serverList));

		// select the right index
		new selectedIndex;
		if (mostRecentIndex >= 0)
		{
			selectedIndex = mostRecentIndex + 1;
			
			// clamp index
			if (selectedIndex >= serverCount)
			{
				selectedIndex = 0;
			}
		}
		else
		{
			selectedIndex = GetRandomInt(0, serverCount - 1);
		}
			
		// obtain the selected key
		KvRewind(serverList);
		KvGotoFirstSubKey(serverList);
		currentIndex = 0;
		while (currentIndex < selectedIndex && currentIndex < serverCount)
		{
			KvGotoNextKey(serverList);
			currentIndex++;
		}
		
		// create ad
		decl String:display_name[255];
		KvGetSectionName(serverList, address, sizeof(address));
		KvGetString(serverList, "display_name", display_name, sizeof(display_name));
		strcopy(g_lastAddress, sizeof(g_lastAddress), address);
		decl String:mapName[64];
		KvGetString(serverList, "map", mapName, sizeof(mapName));
		new currentPlayers = KvGetNum(serverList, "currentplayers");
		new maxPlayers = KvGetNum(serverList, "maxplayers");

		decl String:adText[255];
		FormatAdText(adText, sizeof(adText), address, display_name, mapName, currentPlayers, maxPlayers);
		PrintToChatAll(adText, 0x04);
	}
}

FormatAdText(String:buffer[], bufferSize, const String:address[], const String:displayName[], const String:map[], currPlayers, maxPlayers)
{
	GetConVarString(g_varAdsFormat, buffer, bufferSize);
	Format(buffer, bufferSize, "%%c%s", buffer);		// add color formatter

	decl String:tmpVal[10];
	if (StrContains(buffer, "{NAME}") != -1)
	{
		ReplaceString(buffer, bufferSize, "{NAME}", displayName);
	}
	if (StrContains(buffer, "{IP}") != -1)
	{
		ReplaceString(buffer, bufferSize, "{IP}", address);
	}
	if (StrContains(buffer, "{MAP}") != -1)
	{
		ReplaceString(buffer, bufferSize, "{MAP}", map);
	}
	if (StrContains(buffer, "{CURR}") != -1)
	{
		IntToString(currPlayers, tmpVal, sizeof(tmpVal));
		ReplaceString(buffer, bufferSize, "{CURR}", tmpVal);
	}
	if (StrContains(buffer, "{MAX}") != -1)
	{
		IntToString(maxPlayers, tmpVal, sizeof(tmpVal));
		ReplaceString(buffer, bufferSize, "{MAX}", tmpVal);
	}
}
