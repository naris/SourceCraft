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
 *	Credit to who helped create this plugin...
 *		* BAILOPAN - Sourcemod/Help/Issue List And SVN Hosting
 *		* Wiebbe - Dyanmic Replacement Function
 *		* And.. #sourcemod on irc.gamesurge.com
 *
 * 
 *	Use at your OWN risk! Please submit your changes of this
 *	script to Shane. Known issues/Submit bug reports at:
 *	
 *		http://bugs.alliedmods.net/?project=9&do=index
 *	
 *	If you post bug reports over the forums, they will not be taken.
 *
 *	Thanks...                 
 *	  -- Shane A. Froebel
 * File: ads.sp
 * SVN: $Id: ads.sp 131 2007-10-31 17:54:46Z bugs $
**/ 

#pragma semicolon 1

#include <sourcemod>
#include <ads>

#define ADS_VERSION "1.0.4.0"
#define BUILDD __DATE__
#define BUILDT __TIME__

#include "ads/ads.inc"
#include "ads/ads.config.sp"
#include "ads/ads.natives.sp"
#include "ads/ads.hl2overrides.sp"
#include "ads/ads.publicfunctions.sp"
#include "ads/ads.privatefunctions.sp"

/*****************************************************************
*                      BASE INFORMATION                          * 
******************************************************************/

public Plugin:myinfo = 
{
	name = "Ads",
	author = "Shane A. ^BuGs^ Froebel",
	description = "Send messages to all players at a set interval.",
	version = ADS_VERSION,
	url = "http://www.steamfriends.com/"
};

public OnPluginStart() 
{
	
	LoadTranslations("ads.phrases");
	
	g_Cvar_adsStatus = CreateConVar("sm_ads_status","1","Current status of the ads plugin.",FCVAR_PLUGIN,true,0.0,true,1.0);
	g_Cvar_adsVersion = CreateConVar("sm_ads_version",ADS_VERSION,"The version of 'ads' running.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_adsBuildVersion = CreateConVar("sm_ads_build",SOURCEMOD_VERSION,"The version of 'ads' was built on.",FCVAR_PLUGIN);
	
	HookConVarChange(g_Cvar_adsStatus, AdsStatus);
	
	FwdNewSection = CreateGlobalForward("_ConfigNewSection", ET_Ignore, Param_String);
	FwdKeyValue = CreateGlobalForward("_ConfigKeyValue", ET_Ignore, Param_String, Param_String);
	FwdEnd = CreateGlobalForward("_ConfigEnd", ET_Ignore);
	
	CreateTimer(5.0, OnPluginStart_Delayed);
	
	RegPluginLibrary("ads");
	
}

public AdsConsole_Server(String:text[], any:...)
{
	new String:message[255];
	VFormat(message, sizeof(message), text, 2);
	PrintToServer("[Ads] %s", message);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	g_hAdsTimer = CreateTimer(AdsTimeMsg, Ads_Message, _, TIMER_REPEAT);
}

public AdsStatus(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(g_Cvar_adsStatus) != 1)
	{
		PrintToChatAll("%c[ADS]%c Ads turned off.", GREEN, YELLOW);
	} else {
		PrintToChatAll("%c[ADS]%c Ads turned on.", GREEN, YELLOW);
	}
}

public ChangeAdsStatus(status)
{
	SetConVarInt(g_Cvar_adsStatus, status);
}