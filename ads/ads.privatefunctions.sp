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
 * File: scripting/ads/ads.privatefunctions.sp
 * SVN: $Id: ads.privatefunctions.sp 131 2007-10-31 17:54:46Z bugs $
**/

SendAds(index)
{
	if (index != -1)
	{
		new String:sentad[255];
		GetAdsMessage(index, sentad, sizeof(sentad));
		
		if (AllowDyanmicReplace)
		{
			//	Should this be in a config?
		}

		switch(LocationOfAds)
		{
			case 1:	PrintHintTextToAll(sentad);
			case 2:	PrintCenterTextAll(sentad);
			case 3: TopMenuColorsToAll(sentad);
			default: {
				if (!InsurgencyAds)
				{
					new String:color[10];
					GetAdsChatColor(color, sizeof(color));
					PrintToChatAll("\%c %s", color, sentad);
				} else {
					InsurgencyAdsToAll(sentad);
				}
			}
		}
	}
}