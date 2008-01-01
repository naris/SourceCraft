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
 * File: quickmsg.inc
 *
**/

#define YELLOW				0x01
#define LIGHTGREEN			0x03
#define GREEN				0x04

enum State
{
	CONFIG_STATE_NONE,
	CONFIG_STATE_MSG,
	CONFIG_STATE_KEY,
	CONFIG_STATE_SIMPLE
};

new Handle:g_QuickmsgVersion;

new Handle:g_Quick = INVALID_HANDLE;

new Handle:ConfigParser = INVALID_HANDLE;

new State:ConfigState;

new ConfigCount;
new ParseCount;

new quickmessageindexinc;
new quickmessageinc;

new quickmessageindexkeyinc;
new quickmessagekeyinc;

new String:QuickMessageIndex[255][1024];
new String:QuickMessages[255][1024];

new String:QuickMessageKeyIndex[255][1024];
new String:QuickMessageKey[255][1024];
