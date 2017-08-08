/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: changesettings.inc
 * Description: This file handles player settings.
 * Author(s): Naris (Murray Wilson)
 */

#include <clientprefs>
#include "sc/settings"

enum Display_Cookies
{
    Display_Defense_Cookie = 0,
    Display_Defense_Hints_Cookie,
    Display_Damage_Cookie,
    Display_Damage_Hints_Cookie,
    Display_Kills_Cookie,
    Display_Kills_Hints_Cookie,
    Display_Ultimate_Cookie,
    Display_Ultimate_Hints_Cookie,
    Display_Item_Cookie,
    Display_Item_Hints_Cookie,
    Display_Message_Cookie,
    Display_Message_Hints_Cookie,
    Display_Enemy_Defended_Cookie,
    Display_Enemy_Def_Hints_Cookie,
    Display_Injury_Cookie,
    Display_Injury_Hints_Cookie,
    Display_Deaths_Cookie,
    Display_Death_Hints_Cookie,
    Display_Enemy_Ultimate_Cookie,
    Display_Enemy_Ult_Hints_Cookie,
    Display_Enemy_Item_Cookie,
    Display_Enemy_Item_Hints_Cookie,
    Display_Enemy_Message_Cookie,
    Display_Enemy_Msg_Hints_Cookie,
    Display_XP_Cookie,
    Display_Crystals_Cookie,
    Display_Vespene_Cookie,
    Display_Energy_Cookie,
    Display_Package_Cookie,
    Display_Details_Cookie,
    Display_All_Hints_Cookie,
};

enum Settings_Cookies
{
    Reduce_Queasiness_Cookie,
    Remove_Queasiness_Cookie,
    Disable_Beacons_Cookie,
    Disable_OBeacons_Cookie,
    Disable_DEffects_Cookie,
    Disable_Effects_Cookie,
    Display_Widescreen_Cookie,
    Enable_Alternate_HUD_Cookie,
    Disable_HUD_Cookie,
    Disable_Hints_Cookie,
    Show_Upgrade_Info_Cookie,
    Show_All_Races_Cookie,
    Debug_Condition_Cookie,
    Debug_Speed_Cookie,
    Debug_Meters_Cookie,
    Debug_Other_Cookie
};

stock const String:g_strDisplayCookieName[Display_Cookies][] =
{
    "sc_display_defense",
    "sc_display_defense_hints",
    "sc_display_damage",
    "sc_display_damage_hints",
    "sc_display_kills",
    "sc_display_kill_hints",
    "sc_display_ultimate",
    "sc_display_ultimate_hints",
    "sc_display_item",
    "sc_display_item_hints",
    "sc_display_misc_message",
    "sc_display_message_hints",
    "sc_display_enemy_defended",
    "sc_display_enemy_defended_hints",
    "sc_display_injury",
    "sc_display_injury_hints",
    "sc_display_deaths",
    "sc_display_death_hints",
    "sc_display_enemy_ultimate",
    "sc_display_enemy_ultimate_hints",
    "sc_display_enemy_item",
    "sc_display_enemy_item_hints",
    "sc_display_enemy_message",
    "sc_display_enemy_message_hints",
    "sc_display_xp",
    "sc_display_crystals",
    "sc_display_vespene",
    "sc_display_energy",
    "sc_display_package",
    "sc_display_details",
    "sc_display_all_hints"
};

stock const String:g_strCookieName[Settings_Cookies][] =
{
    "sc_reduce_queasiness",
    "sc_remove_queasiness",
    "sc_disable_beacons",
    "sc_disable_obeacons",
    "sc_disable_deffects",
    "sc_disable_effects",
    "sc_display_widescreen",
    "sc_enable_alternate_hud",
    "sc_disable_hud",
    "sc_disable_hints",
    "sc_show_upgrade_info",
    "sc_show_all_races",
    "sc_debug_condition",
    "sc_debug_speed",
    "sc_debug_meters",
    "sc_debug_other"
};

stock const String:g_strDisplayCookiePrompt[Display_Cookies][] =
{
    "DisplayDefense",
    "DisplayDefenseHints",
    "DisplayDamage",
    "DisplayDamageHints",
    "DisplayKills",
    "DisplayKillHints",
    "DisplayUltimate",
    "DisplayUltimateHints",
    "DisplayItem",
    "DisplayItemHints",
    "DisplayMessage",
    "DisplayMessageHints",
    "DisplayEnemyDefended",
    "DisplayEnemyDefendedHints",
    "DisplayInjury",
    "DisplayInjuryHints",
    "DisplayDeaths",
    "DisplayDeathHints",
    "DisplayEnemyUltimate",
    "DisplayEnemyUltimateHints",
    "DisplayEnemyItem",
    "DisplayEnemyItemHints",
    "DisplayEnemyMessage",
    "DisplayEnemyMessageHints",
    "DisplayXP",
    "DisplayCrystals",
    "DisplayVespene",
    "DisplayEnergy",
    "DisplayPackage",
    "DisplayDetails",
    "DisplayAllHints"
};

stock const String:g_strCookiePrompt[Settings_Cookies][] =
{
    "ReduceQueasiness",
    "RemoveQueasiness",
    "DisableBeacons",
    "DisableOBeacons",
    "DisableDEffects",
    "DisableEffects",
    "DisplayWidescreen",
    "EnableAltHUD",
    "DisableHUD",
    "DisableHints",
    "ShowUpgradeInfo",
    "ShowAllRaces",
    "DebugCondition",
    "DebugSpeed",
    "DebugMeters",
    "DebugOther"
};

stock const bool:g_bDisplayCookieFlip[Display_Cookies] =
{
    false,  // Display_Defense
    false,  // Display_Defense_Hints
    false,  // Display_Damage
    false,  // Display_Damage_Hints
    false,  // Display_Kills
    false,  // Display_Kill_Hints
    false,  // Display_Ultimate
    false,  // Display_Ultimate_Hints
    false,  // Display_Item
    false,  // Display_Item_Hints
    false,  // Display_Message
    false,  // Display_Message_Hints
    false,  // Display_Enemy_Defended
    false,  // Display_Enemy_Defended_Hints
    false,  // Display_Injury
    false,  // Display_Injury_Hints
    false,  // Display_Deaths
    false,  // Display_Death_Hints
    false,  // Display_Enemy_Ultimate
    false,  // Display_Enemy_Ultimate_Hints
    false,  // Display_Enemy_Item
    false,  // Display_Enemy_Item_Hints
    false,  // Display_Enemy_Message
    false,  // Display_Enemy_Message_Hints
    false,  // Display_XP
    false,  // Display_Crystals
    false,  // Display_Vespene
    false,  // Display_Energy
    false,  // Display_Package
    false,  // Display_Details
    true,   // Display_All_Hints
};

stock const bool:g_bCookieFlip[Settings_Cookies] =
{
    true,   // Reduce_Queasiness
    true,   // Remove_Queasiness
    true,   // Disable_Beacons
    true,   // Disable_OBeacons
    true,   // Disable_DEffects
    true,   // Disable_Effects
    false,  // Display_Widescreen
    false,  // Enable_Alternate_HUD
    true,   // Disable_HUD
    true,   // Disable_Hints
    false,  // Show_Upgrade_Info
    true,   // Show_All_Races
    true,   // Debug_Condition
    true,   // Debug_Speed
    true,   // Debug_Meters
    true    // Debug_Other
};

new Handle:g_hDisplayCookie[Display_Cookies];
new Handle:g_hCookie[Settings_Cookies];
new g_bCookieSelected[MAXPLAYERS];

InitCookies()
{
    decl String:buffer[LONG_STRING_LENGTH];

    // Setup Display Settings Cookies
    for (new any:i = 0; i < Display_Cookies; i++)
    {
        Format(buffer, sizeof(buffer), "%T", g_strDisplayCookiePrompt[i], LANG_SERVER);
        g_hDisplayCookie[i] = RegClientCookie(g_strDisplayCookieName[i], buffer, CookieAccess_Public);
    }

    // Setup Settings Cookies
    for (new any:i = 0; i < Settings_Cookies; i++)
    {
        Format(buffer, sizeof(buffer), "%T", g_strCookiePrompt[i], LANG_SERVER);
        g_hCookie[i] = RegClientCookie(g_strCookieName[i], buffer, CookieAccess_Public);
    }

    // Hook the TextMsg displayed when the user changes a cookie.
    HookUserMessage(GetUserMessageId("TextMsg"), CookieTextHook);

    //add to clientpref's built-in !settings menu
    SetCookieMenuItem(SourceCraftCookieMenu, 0, "SourceCraft Prefs");
}

public OnClientCookiesCached(client)
{
    // SourceCraft DataBase info takes precedence over clientprefs
    if (GetDatabaseLoaded(client) < DataLoaded)
    {
        decl String:strCookie[2];

        // Get Display Cookies
        for (new Display_Cookies:i = Display_Cookies:0; i < Display_Cookies; i++)
        {
            GetClientCookie(client, g_hDisplayCookie[i], strCookie, sizeof(strCookie));
            if (g_bDisplayCookieFlip[i])
            {
                if (strCookie[0] != '1')
                    g_ClientDisplayBits[client] |= Display:(1 << _:i);
            }
            else
            {
                if (strCookie[0] == '1')
                    g_ClientDisplayBits[client] |= Display:(1 << _:i);
            }
        }

        // Get Cookies
        for (new Settings_Cookies:i = Settings_Cookies:0; i < Settings_Cookies; i++)
        {
            GetClientCookie(client, g_hCookie[i], strCookie, sizeof(strCookie));
            if (g_bCookieFlip[i])
            {
                if (strCookie[0] != '1')
                    g_ClientSettingsBits[client] |= Settings:(1 << _:i);
            }
            else
            {
                if (strCookie[0] == '1')
                    g_ClientSettingsBits[client] |= Settings:(1 << _:i);
            }
        }
    }
}

public CookieSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
    if (action == CookieMenuAction_DisplayOption )
    {
        if (info >= 0 && info < Display_Cookies)
        {
            // Translate the buffer
            Format(buffer, maxlen, "%T", g_strDisplayCookiePrompt[info], client);
        }
        else if (info >= Display_Cookies && info < _:Display_Cookies+_:Settings_Cookies)
        {
            // Translate the buffer
            Format(buffer, maxlen, "%T", g_strCookiePrompt[info-_:Display_Cookies], client);
        }
        else
            LogError("Invalid cookie %d requested", info);
    }
    else if (client > 0 && action == CookieMenuAction_SelectOption)
    {
        g_bCookieSelected[client] = info+1; // We need 0 to be not selected.
    }
}

public Action:CookieTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    if (playersNum == 1)
    {
        new client = players[0];
        if (client > 0)
        {
            new any:info = g_bCookieSelected[client]-1;
            if (info >= 0)
            {
                new String:text[LONG_STRING_LENGTH];
                BfReadByte(bf);
                BfReadString(bf, text, sizeof(text));
                if (info < Display_Cookies)
                {
                    if (strncmp(text, "[SM]", 4) == 0 && StrContains(text, "\"sc_") >= 0)
                    {
                        decl String:strCookie[2];
                        GetClientCookie(client, g_hDisplayCookie[info], strCookie, sizeof(strCookie));

                        if (g_bCookieFlip[info])
                        {
                            if (strCookie[0] != '1')
                                g_ClientDisplayBits[client] |= Display:(1 << info);
                            else
                                g_ClientDisplayBits[client] &= Display:(~(1 << info));
                        }
                        else
                        {
                            if (strCookie[0] == '1')
                                g_ClientDisplayBits[client] |= Display:(1 << info);
                            else
                                g_ClientDisplayBits[client] &= Display:(~(1 << info));
                        }
                    }
                }
                else if (info < _:Display_Cookies+_:Settings_Cookies)
                {
                    if (strncmp(text, "[SM]", 4) == 0 && StrContains(text, "\"sc_") >= 0)
                    {
                        decl String:strCookie[2];
                        GetClientCookie(client, g_hCookie[info], strCookie, sizeof(strCookie));

                        if (g_bCookieFlip[info])
                        {
                            if (strCookie[0] != '1')
                                g_ClientSettingsBits[client] |= Settings:(1 << (info-_:Display_Cookies));
                            else
                                g_ClientSettingsBits[client] &= Settings:(~(1 << (info-_:Display_Cookies)));
                        }
                        else
                        {
                            if (strCookie[0] == '1')
                                g_ClientSettingsBits[client] |= Settings:(1 << (info-_:Display_Cookies));
                            else
                                g_ClientSettingsBits[client] &= Settings:(~(1 << (info-_:Display_Cookies)));
                        }
                    }
                }
                g_bCookieSelected[client] = 0;
            }
        }
    }
    return Plugin_Continue;
}

//add to clientpref's built-in !settings menu
public SourceCraftCookieMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
    if (action == CookieMenuAction_SelectOption)
    {
        ChangeSettings(client, false);
    }
}

ChangeSettings(client, bool:fromMain)
{
    new Handle:SettingsMenu=CreateMenu(Settings_Select);
    SetMenuTitle(SettingsMenu,"[SC] %T", "ChooseSetting", client);
    SetMenuExitButton(SettingsMenu,true);
    if (fromMain)
        SetMenuExitBackButton(SettingsMenu,true);

    new AdminId:aid = GetUserAdmin(client);
    new bool:isAdmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);

    decl String:buf[12];
    new Display:displayFlags = g_ClientDisplayBits[client];
    //LogMessage("%d:%N's Client Bits=%08x", client, ValidClientIndex(client), flags);
    for (new any:i = 0; i < Display_Cookies; i++)
    {
        IntToString(i, buf, sizeof(buf));
        new bool:value = FlipBit_IsSet(displayFlags & Display:(1 << i));
        //LogMessage("Setting #%d [Flip:%d] %s=%d",i,g_bCookieFlip[i],g_strCookiePrompt[i],value);
        AddSetting(client, SettingsMenu, buf, g_strDisplayCookiePrompt[i], g_bDisplayCookieFlip[i] ? !value : value);
    }

    new Settings:flags = g_ClientSettingsBits[client];
    //LogMessage("%d:%N's Client Bits=%08x", client, ValidClientIndex(client), flags);
    for (new any:i = 0; i < Settings_Cookies; i++)
    {
        // Only allow Admins to enable Debug modes
        if (isAdmin || strncmp(g_strCookiePrompt[i], "Debug", 5, false) != 0)
        {
            IntToString(i+_:Display_Cookies, buf, sizeof(buf));
            new bool:value = FlipBit_IsSet(flags & Settings:(1 << i));
            //LogMessage("Setting #%d [Flip:%d] %s=%d",i,g_bCookieFlip[i],g_strCookiePrompt[i],value);
            AddSetting(client, SettingsMenu, buf, g_strCookiePrompt[i], g_bCookieFlip[i] ? !value : value);
        }
    }

    DisplayMenu(SettingsMenu,client,MENU_TIME_FOREVER);
}

public Settings_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:SelectionInfo[SMALL_STRING_LENGTH];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

        // Update the settings bits
        new any:info = StringToInt(SelectionInfo);
        if (info >= 0)
        {
            if (info < Display_Cookies)
            {
                new Display:bit = Display:(1 << info);
                g_ClientDisplayBits[client] ^= bit;

                // Set the cookie
                SetClientCookie(client, g_hDisplayCookie[info],
                                (g_ClientDisplayBits[client] & bit) ? "1" : "0");

                PrepareAndEmitSoundToClient(client,buttonWav);
                ChangeSettings(client,false);
            }
            else if (info < _:Display_Cookies+_:Settings_Cookies)
            {
                new setting = info - _:Display_Cookies;
                new Settings:bit = Settings:(1 << setting);
                g_ClientSettingsBits[client] ^= bit;

                // Set the cookie
                SetClientCookie(client, g_hCookie[setting],
                                (g_ClientSettingsBits[client] & bit) ? "1" : "0");

                PrepareAndEmitSoundToClient(client,buttonWav);
                ChangeSettings(client,false);
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            PrepareAndEmitSoundToClient(client,buttonWav);
            MainMenu(client);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

AddSetting(client, Handle:SettingsMenu, const String:info[], const String:setting[], bool:value)
{
    decl String:buffer[ITEM_STRING_LENGTH];
    Format(buffer, sizeof(buffer), "[%s] %T", value ? "Y" : "N", setting, client);
    AddMenuItem(SettingsMenu,info,buffer);
}
