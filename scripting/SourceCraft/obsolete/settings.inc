/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: settings.inc
 * Description: This file handles player settings.
 * Author(s): Naris (Murray Wilson)
 */

#include "sc/display_flags"

ChangeSettings(client, bool:fromMain)
{
    new Handle:SettingsMenu=CreateMenu(Settings_Select);
    SetMenuTitle(SettingsMenu,"[SourceCraft] Choose a setting.");
    SetMenuExitButton(SettingsMenu,true);
    if (fromMain)
        SetMenuExitBackButton(SettingsMenu,true);

    new flags = g_DisplayFlags[client];
    AddSetting(SettingsMenu,"0","Display defense", (flags & SC_DISPLAY_DEFENSE) == 0);
    AddSetting(SettingsMenu,"1","Display damage done", (flags & SC_DISPLAY_DAMAGE_DONE) == 0);
    AddSetting(SettingsMenu,"2","Display kills", (flags & SC_DISPLAY_KILLS) == 0);
    AddSetting(SettingsMenu,"3","Display ultimate results", (flags & SC_DISPLAY_ULTIMATE) == 0);
    AddSetting(SettingsMenu,"4","Display misc. messages", (flags & SC_DISPLAY_MISC_MESSAGE) == 0);
    AddSetting(SettingsMenu,"5","Display enemies defense", (flags & SC_DISPLAY_ENEMY_DEFENDED) == 0);
    AddSetting(SettingsMenu,"6","Display damage taken", (flags & SC_DISPLAY_DAMAGE_TAKEN) == 0);
    AddSetting(SettingsMenu,"7","Display deaths", (flags & SC_DISPLAY_DEATHS) == 0);
    AddSetting(SettingsMenu,"8","Display enemies ultimates", (flags & SC_DISPLAY_ENEMY_ULTIMATE) == 0);
    AddSetting(SettingsMenu,"9","Display enemies misc. messages", (flags & SC_DISPLAY_ENEMY_MESSAGE) == 0);
    AddSetting(SettingsMenu,"10","Display experience gained", (flags & SC_DISPLAY_XP) == 0);
    AddSetting(SettingsMenu,"11","Display credits earned", (flags & SC_DISPLAY_CREDITS) == 0);
    AddSetting(SettingsMenu,"12","Display package messages", (flags & SC_DISPLAY_PACKAGE) == 0);
    AddSetting(SettingsMenu,"13","Display details", (flags & SC_DISPLAY_DETAILS) == 0);
    DisplayMenu(SettingsMenu,client,MENU_TIME_FOREVER);
}

public Settings_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
        switch(selection)
        {
            case 0: g_DisplayFlags[client] ^= SC_DISPLAY_DEFENSE; // defense
            case 1: g_DisplayFlags[client] ^= SC_DISPLAY_DAMAGE_DONE; // damage done
            case 2: g_DisplayFlags[client] ^= SC_DISPLAY_KILLS; // kills
            case 3: g_DisplayFlags[client] ^= SC_DISPLAY_ULTIMATE; // ultimate results
            case 4: g_DisplayFlags[client] ^= SC_DISPLAY_MISC_MESSAGE; // misc. messages
            case 5: g_DisplayFlags[client] ^= SC_DISPLAY_ENEMY_DEFENDED; // enemies defense
            case 6: g_DisplayFlags[client] ^= SC_DISPLAY_DAMAGE_TAKEN; // damage taken
            case 7: g_DisplayFlags[client] ^= SC_DISPLAY_DEATHS; // deaths
            case 8: g_DisplayFlags[client] ^= SC_DISPLAY_ENEMY_ULTIMATE; // enemies ultimates
            case 9: g_DisplayFlags[client] ^= SC_DISPLAY_ENEMY_MESSAGE; // enemies misc. messages
            case 10: g_DisplayFlags[client] ^= SC_DISPLAY_XP; // experience gained messages
            case 11: g_DisplayFlags[client] ^= SC_DISPLAY_CREDITS; // credits earned messages
            case 12: g_DisplayFlags[client] ^= SC_DISPLAY_PACKAGE; // package
            case 13: g_DisplayFlags[client] ^= SC_DISPLAY_DETAILS; // details
        }
        ChangeSettings(client,false);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            EmitSoundToClient(client,buttonWav);
            MainMenu(client);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

AddSetting(Handle:SettingsMenu, const String:info[], const String:setting[], bool:value)
{
    decl String:buffer[64];
    Format(buffer, sizeof(buffer), "[%s] %s", value ? "Y" : "N", setting);
    AddMenuItem(SettingsMenu,info,buffer);
}

