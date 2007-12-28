/**
 * ===============================================================
 * Ads, Copyright (C) 2007
 * Released under the Steamfriends.com Brand
 * All rights reserved.
 * ===============================================================
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * To view the latest information, see: http://forums.alliedmods.net/showthread.php?t=57430
 * 	Author(s):	Shane A. ^BuGs^ Froebel
 *
 *
 * File: scripting/ads/ads.inc
 * SVN: $Id: ads.inc 131 2007-10-31 17:54:46Z bugs $
**/

#define YELLOW               0x01
#define GREEN                0x04

enum State
{
	CONFIG_STATE_NONE,
	CONFIG_STATE_CONFIG,
	CONFIG_STATE_MSGOPT,
	CONFIG_STATE_MSG,
};

new Handle:g_Cvar_adsStatus;
new Handle:g_Cvar_adsVersion;
new Handle:g_Cvar_adsBuildVersion;
new Handle:g_hAdsTimer = INVALID_HANDLE;

new Handle:ConfigParser = INVALID_HANDLE;
new Handle:FwdNewSection = INVALID_HANDLE;
new Handle:FwdKeyValue = INVALID_HANDLE;
new Handle:FwdEnd = INVALID_HANDLE;

new Float:AdsTimeMsg;

new State:ConfigState;

new bool:EnabledAds;
new bool:EnabledOutsideAds;
new bool:AllowDyanmicReplace;
new bool:InsurgencyAds;

new AdsRedAlpha;
new AdsBlueAlpha;
new AdsGreenAlpha;
new AdsAlpha;

new ConfigCount;
new ParseCount;

new indexsaytext2;
new admessageinc;

new LocationOfAds;

new AdsIndex;

new String:AdMessages[255][1024];
new String:AdChatColor[10];

/* Ins Support */

stock InsurgencyAdsToAll(const String:sentad[])
{
	new maxclients = GetMaxClients();
		
	// Send to all players...
	for (new i = 1; i <= maxclients; i++)
	{
		if (IsClientInGame(i))
		{
			SendMsg_SayText2(i, sentad);	
		}
	}
}

stock SendMsg_SayText2(target, const String:message[], any:...)
{
	if (strlen(message) > 191)
	{
		LogError("Disallow string len(%d) > 191", strlen(message));
		return;
	}
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), message, 3);
	new Handle:hBf;
	if (target == 0)
	{
		hBf = StartMessageAll("SayText");
	} else {
		hBf = StartMessageOne("SayText", target);
	}
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, indexsaytext2); 
		BfWriteString(hBf, buffer);
		BfWriteByte(hBf, 1);
		EndMessage();
	}
}

/* Top Menu Colors */

stock TopMenuColorsToAll(const String:sentad[])
{
	new maxclients = GetMaxClients();
		
	// Send to all players...
	for (new i = 1; i <= maxclients; i++)
	{
		if (IsClientInGame(i))
		{
			SendTopMessage(i, AdsRedAlpha, AdsGreenAlpha, AdsBlueAlpha, AdsAlpha, "%s", sentad);	
		}
	}
}

stock SendTopMessage(client, r, g, b, a, String:text[], any:...)
{
	new String:message[100];
	VFormat(message,191,text, 7);
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", r, g, b, a);
	KvSetNum(kv, "level", 1);
	KvSetNum(kv, "time", 10);

	CreateDialog(client, kv, DialogType_Msg);

	CloseHandle(kv);

	return;
}