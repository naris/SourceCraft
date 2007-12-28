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
 * File: scripting/ads/ads.publicfunctions.sp
 * SVN: $Id: ads.publicfunctions.sp 131 2007-10-31 17:54:46Z bugs $
**/

public Action:Ads_Message(Handle:timer)
{
	if ((GetConVarInt(g_Cvar_adsStatus)) && (admessageinc > 0))
	{
		if (AdsIndex == admessageinc)
		{
			AdsIndex = 0;
		}
		
		SendAds(AdsIndex);
		AdsIndex++;
	}
}

public NewAdsMessage(const String:message[])
{
	strcopy(AdMessages[admessageinc], sizeof(AdMessages[]), message);
	admessageinc++;
}

GetAdsMessage(index, String:output[], maxlengh)
{
	strcopy(output, maxlengh, AdMessages[index]);
}

public AdsChatColor(const String:color[])
{
	strcopy(AdChatColor, sizeof(AdChatColor), color);
}

GetAdsChatColor(String:output[], maxlengh)
{
	strcopy(output, maxlengh, AdChatColor);
}