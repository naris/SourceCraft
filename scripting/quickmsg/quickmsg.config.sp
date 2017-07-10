/**
 * ===============================================================
 * Quick Messages, Copyright (C) 2007
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
 * 	Author(s):	Shane A. ^BuGs^ Froebel
 * 
 *	About:
 *
 *	This script simple takes your custom messages so you can
 *	quickly show them to all players using the quick GUI I/O.
 *
 *	Built with my favorite gaming group around: EAST COAST GUARDINGS
 *
 *
 * File: quickmsg.config.sp
 *
**/

public OnConfigsExecuted()
{
	ResetKeys();
	ReadConfig();
	
	g_Quick = BuildQm();
	
	QMConsole_Server("%t %t %s :: By Shane A. ^BuGs^ Froebel", "QuickMessage Console Loading", "QuickMessage Console Version", QUICKMSG_VERSION);
}

public ReadConfig()
{
	
	ConfigParser = SMC_CreateParser();

	SMC_SetParseEnd(ConfigParser, ReadConfig_ParseEnd);
	SMC_SetReaders(ConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);

	decl String:DefaultFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, DefaultFile, sizeof(DefaultFile), "configs\\quickmsg\\plugin.quickmsg.cfg");
	if(FileExists(DefaultFile))
	{
		PrintToServer("[QM] Loading %s config file", DefaultFile);
	} else {
		decl String:Error[PLATFORM_MAX_PATH + 64];
		FormatEx(Error, sizeof(Error), "[QM] FATAL *** ERROR *** can not find %s", DefaultFile);
		SetFailState(Error);
	}
	
	new SMCError:err = SMC_ParseFile(ConfigParser, DefaultFile);

	if (err != SMCError_Okay)
	{
		decl String:buffer[64];
		if (!SMC_GetErrorString(err, buffer, sizeof(buffer)))
		{
			decl String:Error[PLATFORM_MAX_PATH + 64];
			FormatEx(Error, sizeof(Error), "[QM] FATAL *** ERROR *** Fatal parse error in %s", DefaultFile);
			SetFailState(Error);
		}
	}
	
	CloseHandle(ConfigParser);
}

public SMCResult:ReadConfig_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if(name[0])
	{
		if(strcmp("QuickMessagesData", name, false) == 0)
		{
			ConfigState = CONFIG_STATE_MSG;
		} else if(strcmp("QuickKey", name, false) == 0) {
			ConfigState = CONFIG_STATE_KEY;
		} else if(strcmp("QuickMessages", name, false) == 0) {
			ConfigState = CONFIG_STATE_SIMPLE;
		}
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
		switch(ConfigState)
		{
			case CONFIG_STATE_MSG: {
				NewMessageIndex(key);
				NewMessage(value);
			}
			case CONFIG_STATE_KEY: {
				NewKeyIndex(key);
				NewKey(value);
			}
			case CONFIG_STATE_SIMPLE: {
				NewSimpleMessage(key,value);
			}
		}
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
		ConfigState = CONFIG_STATE_NONE;
	}
}
