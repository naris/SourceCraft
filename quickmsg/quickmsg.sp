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
 *	USAGE:
 *
 *	sm_quick
 *	!quick
 *	/quick
 *
**/

#pragma semicolon 1
#include <sourcemod>

#define QUICKMSG_VERSION "1.0.4.0"
#define BUILDD __DATE__
#define BUILDT __TIME__

#include "quickmsg/quickmsg.inc"
#include "quickmsg/quickmsg.config.sp"
#include "quickmsg/quickmsg.gui.sp"

/*****************************************************************
*                      BASE INFORMATION                          * 
******************************************************************/

public Plugin:myinfo =
{
	name = "Quick Messages",
	author = "Shane A. ^BuGs^ Froebel",
	description = "Quick messages for messaging commonly said things.",
	version = QUICKMSG_VERSION,
	url = "http://bugssite.org/"
}
public OnPluginStart() 
{

	LoadTranslations("plugin.quickmsg");

	g_QuickmsgVersion = CreateConVar("sm_quickmsg_version", QUICKMSG_VERSION, "The version of 'Quick Msg' running.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_quick", Command_QuickMessage, ADMFLAG_RESERVATION, "sm_quick - show GUI nenu");
	
}

public QMConsole_Server(String:text[], any:...)
{
	new String:message[255];
	VFormat(message, sizeof(message), text, 2);
	PrintToServer("[QM] %s", message);
}

public OnMapEnd()
{
	if (g_Quick != INVALID_HANDLE)
	{
		CloseHandle(g_Quick);
		g_Quick = INVALID_HANDLE;
	}
}

ResetKeys()
{
	for (new i = 0; i < quickmessageindexinc; i++)
	{
		 NewMessageIndexReset(i, "");
	}
	for (new i = 0; i < quickmessageinc; i++)
	{
		NewMessageReset(i, "");
	}
	for (new i = 0; i < quickmessageindexkeyinc; i++)
	{
		NewKeyIndexReset(i, "");
	}
	for (new i = 0; i < quickmessagekeyinc; i++)
	{
		NewKeyReset(i, "");
	}
	quickmessageindexinc = 0;
	quickmessageinc = 0;
	quickmessageindexkeyinc = 0;
	quickmessagekeyinc = 0;
}

/*****************************************************************
*                       ACTION FUNCTIONS                         *
*****************************************************************/

public Action:Command_QuickMessage(client, args)
{
	if (client == 0)
	{
		return Plugin_Handled;
	}
	DisplayMenu(g_Quick, client, MENU_TIME_FOREVER);
	return Plugin_Stop;
}

/*****************************************************************
*                        PUBLIC FUNCTIONS                        * 
******************************************************************/

public NewSimpleMessage(const String:key[], const String:message[])
{
	strcopy(QuickMessageKeyIndex[quickmessageindexkeyinc], sizeof(QuickMessageKeyIndex[]), key);
	quickmessageindexkeyinc++;

	strcopy(QuickMessageIndex[quickmessageindexinc], sizeof(QuickMessageIndex[]), message);
	quickmessageindexinc++;
}


public NewMessageIndex(const String:message[])
{
	strcopy(QuickMessageIndex[quickmessageindexinc], sizeof(QuickMessageIndex[]), message);
	quickmessageindexinc++;
}

public NewMessage(const String:message[])
{
	strcopy(QuickMessages[quickmessageinc], sizeof(QuickMessages[]), message);
	quickmessageinc++;
}

public NewMessageIndexReset(index, const String:message[])
{
	strcopy(QuickMessageIndex[index], sizeof(QuickMessageIndex[]), message);
}

public NewMessageReset(index, const String:message[])
{
	strcopy(QuickMessages[index], sizeof(QuickMessages[]), message);
}

GetMessage(index, String:output[], maxlengh)
{
	strcopy(output, maxlengh, QuickMessages[index]);
}

public NewKeyIndex(const String:message[])
{
	strcopy(QuickMessageKeyIndex[quickmessageindexkeyinc], sizeof(QuickMessageKeyIndex[]), message);
	quickmessageindexkeyinc++;
}

public NewKey(const String:message[])
{
	strcopy(QuickMessageKey[quickmessagekeyinc], sizeof(QuickMessageKey[]), message);
	quickmessagekeyinc++;
}

public NewKeyIndexReset(index, const String:message[])
{
	strcopy(QuickMessageKeyIndex[index], sizeof(QuickMessageKeyIndex[]), message);
}

public NewKeyReset(index, const String:message[])
{
	strcopy(QuickMessageKey[index], sizeof(QuickMessageKey[]), message);
}

GetKeyIndex(index, String:output[], maxlengh)
{
	strcopy(output, maxlengh, QuickMessageKeyIndex[index]);
}

GetKey(index, String:output[], maxlengh)
{
	strcopy(output, maxlengh, QuickMessageKey[index]);
}

public SendMessage(const String:message[])
{
	PrintToChatAll("%c %s", LIGHTGREEN, message);
	return true;
}
