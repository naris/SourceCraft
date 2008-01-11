/*
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: beetlemenu.sp
 * Description: This adds Beetle's adminmenu to the SourceMod admin menu.
 *              It also syncronizes Beetle's bm_nextmap and SM's sm_nextmap.
 * Author: -=|JFH|=- Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0"

new Handle:hAdminMenu = INVALID_HANDLE;

new Handle:bm_nextmap = INVALID_HANDLE;
new Handle:sm_nextmap = INVALID_HANDLE;

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

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
 
public OnAdminMenuReady(Handle:topmenu)
{
    /* Block us from being called twice */
    if (topmenu != hAdminMenu)
    {
        /* Save the Handle */
        hAdminMenu = topmenu;
        new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
        AddToTopMenu(hAdminMenu, "BeetleMenu", TopMenuObject_Item, BeetleMenu, server_commands, "admin_menu", ADMFLAG_GENERIC);
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
        FakeClientCommandEx(param, "@menu");
    }
}

public OnConfigsExecuted()
{
    if (bm_nextmap == INVALID_HANDLE)
    {
        bm_nextmap = FindConVar("bm_nextmap");
        if (bm_nextmap != INVALID_HANDLE)
            HookConVarChange(bm_nextmap, bm_nextmap_changed);
    }

    if (sm_nextmap == INVALID_HANDLE)
    {
        sm_nextmap = FindConVar("sm_nextmap");
        if (sm_nextmap != INVALID_HANDLE)
            HookConVarChange(sm_nextmap, sm_nextmap_changed);
    }

    if (bm_nextmap != INVALID_HANDLE && sm_nextmap != INVALID_HANDLE)
    {
        new String:bm_value[256];
        GetConVarString(bm_nextmap, bm_value, sizeof(bm_value));

        new String:sm_value[256];
        GetConVarString(sm_nextmap, sm_value, sizeof(sm_value));

        if (!StrEqual(bm_value, sm_value))
            SetConVarString(sm_nextmap, bm_value, true, true);
    }
}

public bm_nextmap_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (sm_nextmap != INVALID_HANDLE)
    {
        new String:sm_value[256];
        GetConVarString(sm_nextmap, sm_value, sizeof(sm_value));
        if (!StrEqual(newValue, sm_value))
            SetConVarString(sm_nextmap, newValue, true, true);
    }
}

public sm_nextmap_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (bm_nextmap != INVALID_HANDLE)
    {
        new String:bm_value[256];
        GetConVarString(bm_nextmap, bm_value, sizeof(bm_value));
        if (!StrEqual(newValue, bm_value))
            SetConVarString(bm_nextmap, newValue, true, true);
    }
}
