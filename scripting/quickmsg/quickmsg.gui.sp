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
 * File: quickmsg.gui.sp
 *
**/

Handle:BuildQm()
{
	new Handle:menu = CreateMenu(Menu_QmMessage);
	for (new i = 0; i < quickmessageinc; i++)
	{
	
		new String:key[1024];
		GetKeyIndex(i, key, sizeof(key));
		
		new String:shortmessage[1024];
		GetKey(i, shortmessage, sizeof(shortmessage));
		
		AddMenuItem(menu, key, shortmessage);
	}
	
	SetMenuTitle(menu, "Please select a message:");
 
	return menu;
}


public Menu_QmMessage(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[1024];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new index = StringToInt(info);
		new	String:message[1024];
		GetMessage(index, message, sizeof(message));

		SendMessage(message);
	}
}