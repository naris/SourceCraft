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
 * File: scripting/ads/ads.config.sp
 * SVN: $Id: ads.config.sp 131 2007-10-31 17:54:46Z bugs $
**/

public OnConfigsExecuted()
{
	ReadConfig();
		
	AdsConsole_Server("%t %t %s :: By Shane A. ^BuGs^ Froebel", "Ads Console Loading", "Ads Console Version", ADS_VERSION);
}

public ReadConfig()
{
	
	ConfigParser = SMC_CreateParser();

	SMC_SetParseEnd(ConfigParser, ReadConfig_ParseEnd);
	SMC_SetReaders(ConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);

	decl String:DefaultFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, DefaultFile, sizeof(DefaultFile), "configs\\ads\\plugin.ads.cfg");
	if(FileExists(DefaultFile))
	{
		PrintToServer("[Ads] Loading %s config file", DefaultFile);
	} else {
		decl String:Error[PLATFORM_MAX_PATH + 64];
		FormatEx(Error, sizeof(Error), "[Ads] FATAL *** ERROR *** can not find %s", DefaultFile);
		SetFailState(Error);
	}
	
	new SMCError:err = SMC_ParseFile(ConfigParser, DefaultFile);

	if (err != SMCError_Okay)
	{
		decl String:buffer[64];
		if (!SMC_GetErrorString(err, buffer, sizeof(buffer)))
		{
			decl String:Error[PLATFORM_MAX_PATH + 64];
			FormatEx(Error, sizeof(Error), "[Ads] FATAL *** ERROR *** Fatal parse error in %s", DefaultFile);
			SetFailState(Error);
		}
	}
	
	CloseHandle(ConfigParser);
	
}

public SMCResult:ReadConfig_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if(name[0])
	{
		Call_StartForward(FwdNewSection);
		Call_PushString(name);
		Call_Finish();
	}

	return SMCParse_Continue;
}

public SMCResult:ReadConfig_KeyValue(Handle:smc,
										const String:key[],
										const String:value[],
										bool:key_quotes,
										bool:value_quotes)
{
	/**
	 * Is this check really even neccessary?
	 */

	if(key[0])
	{
		Call_StartForward(FwdKeyValue);
		Call_PushString(key);
		Call_PushString(value);
		Call_Finish();
	}

	return SMCParse_Continue;
}

public SMCResult:ReadConfig_EndSection(Handle:smc)
{
	return SMCParse_Continue;
}

public ReadConfig_ParseEnd(Handle:smc, bool:halted, bool:failed)
{
	if(ConfigCount == ++ParseCount)
	{
		Call_StartForward(FwdEnd);
		Call_Finish();
	}
}

public _ConfigNewSection(const String:name[])
{
	if (strcmp("Config", name, false) == 0)
	{
		ConfigState = CONFIG_STATE_CONFIG;
	} else if (strcmp("MessageOptions", name, false) == 0) {
		ConfigState = CONFIG_STATE_MSGOPT;
	} else if (strcmp("AdMessages", name, false) == 0) {
		ConfigState = CONFIG_STATE_MSG;
	} 
}

public _ConfigKeyValue(const String:key[], String:value[])
{
	switch(ConfigState)
	{
		case CONFIG_STATE_CONFIG: {
			if (strcmp("EnableAds", key, false) == 0)
			{
				EnabledAds = bool:StringToInt(value);
				ChangeAdsStatus(EnabledAds);
			} else if (strcmp("EnableOutsideAds", key, false) == 0) {
				EnabledOutsideAds = bool:StringToInt(value);
			} else if (strcmp("TimeBetweenMsg", key, false) == 0) {
				AdsTimeMsg = StringToFloat(value);
			} else if (strcmp("AllowDyanmicReplace", key, false) == 0) {
				AllowDyanmicReplace = bool:StringToInt(value);
			} else if (strcmp("LocationOfAds", key, false) == 0) {
				LocationOfAds = StringToInt(value);
			} else if (strcmp("AdsRedAlpha", key, false) == 0) {
				AdsRedAlpha = StringToInt(value);
			} else if (strcmp("AdsBlueAlpha", key, false) == 0) {
				AdsBlueAlpha = StringToInt(value);
			} else if (strcmp("AdsGreenAlpha", key, false) == 0) {
				AdsGreenAlpha = StringToInt(value);
			} else if (strcmp("AdsAlpha", key, false) == 0) {
				AdsAlpha = StringToInt(value);
			} else if (strcmp("InsurgencyAds", key, false) == 0) {
				InsurgencyAds = bool:StringToInt(value);
			} else if (strcmp("AdsChatColor", key, false) == 0) {
				AdsChatColor(value);
			}
		}
		case CONFIG_STATE_MSG: {
			NewAdsMessage(value);
		}
	}
}

public _ConfigEnd()
{
	AdsIndex = 0;
	ConfigState = CONFIG_STATE_NONE;
}