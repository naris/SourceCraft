/*
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: beetlemenu.sp
 * Description: This adds Beetle's adminmenu to the SourceMod menu.
 * Author: -=|JFH|=- Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0"

new Handle:hTopMenu = INVALID_HANDLE;

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Beetle's Menu",
	author = "-=|JFH|=-Naris",
	description = "Adds Beetle's Menu to the SourceMod Menu",
	version = PLUGIN_VERSION,
	url = "http://www.jigglysfunhouse.net"
};

public OnPluginStart()
{
    /* Add ConVar for Version */
    CreateConVar("sm_beetles_menu_version", PLUGIN_VERSION, "Beetle's Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    /* Account for late loading */
    new Handle:topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
    {
        OnAdminMenuReady(topmenu);
    }

    return true;
}

public OnAdminMenuReady(Handle:topmenu)
{
    /* Block us from being called twice */
    if (topmenu != hTopMenu)
    {
        /* Save the Handle */
        hTopMenu = topmenu;
        new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
        AddToTopMenu(hTopMenu, "BeetleMenu", TopMenuObject_Item, BeetleMenu, server_commands, "admin_menu", ADMFLAG_GENERIC);
    }
}

public BeetleMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Administer BeetleMod");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        ServerCommand("admin_menu");
        //ClientCommand("admin_menu");
    }
}
