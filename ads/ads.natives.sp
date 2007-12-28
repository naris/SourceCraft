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
 * File: scripting/ads/ads.natives.sp
 * SVN: $Id: ads.natives.sp 131 2007-10-31 17:54:46Z bugs $
**/

/* Native_AddAdsMessage */
public Native_AddAdsMessage(Handle:plugin, numParams)
{
	if (!EnabledOutsideAds)
	{
		return false;
	}
	
	new len;
	GetNativeStringLength(1, len);
	
	if (len > 192)
	{
		return false;
	}
	
	new String:string[len+1];
	GetNativeString(1, string, len+1);
	
	
	new checkinc = admessageinc;
	NewAdsMessage(string);
	
	if ((checkinc+1) == admessageinc)
	{
		return true;	
	} else {
		return false;	
	}
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:Error[])
{
	CreateNative("Add_Ads_Message", Native_AddAdsMessage);
	return true;
}