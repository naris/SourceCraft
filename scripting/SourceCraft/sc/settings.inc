/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: settings.inc
 * Description: Defines the settings bits for SourceCraft
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _settings_included
 #endinput
#endif
#define _settings_included

enum Display (<<= 1)
{
    Display_Generic = 0,
    Display_Defense = 1,
    Display_Defense_Hints,
    Display_Damage,
    Display_Damage_Hints,
    Display_Kills,
    Display_Kill_Hints,
    Display_Ultimate,
    Display_Ultimate_Hints,
    Display_Item,
    Display_Item_Hints,
    Display_Message,
    Display_Message_Hints,
    Display_Enemy_Defended,
    Display_Enemy_Defended_Hints,
    Display_Injury,
    Display_Injury_Hints,
    Display_Deaths,
    Display_Death_Hints,
    Display_Enemy_Ultimate,
    Display_Enemy_Ultimate_Hints,
    Display_Enemy_Item,
    Display_Enemy_Item_Hints,
    Display_Enemy_Message,
    Display_Enemy_Message_Hints,
    Display_XP,
    Display_Crystals,
    Display_Vespene,
    Display_Energy,
    Display_Package,
    Display_Details,
    Display_All_Hints
};

enum Settings (<<= 1)
{
    Default_Settings = 0,
    Reduce_Queasiness = 1,
    Remove_Queasiness,
    Disable_Beacons,
    Disable_OBeacons,
    Disable_DEffects,
    Disable_Effects,
    Display_Widescreen,
    Enable_Alternate_HUD,
    Disable_HUD,
    Disable_Hints,
    Show_Upgrade_Info,
    Show_All_Races,
    Debug_Condition,
    Debug_Speed,
    Debug_Meters,
    Debug_Other
};

enum HintSlot               // W3HintPriority
{
    HintSlot_Generic = 0,   // HINT_NORMAL
    HintSlot_Status,        // HINT_SKILL_STATUS
    HintSlot_Damage,        // HINT_DMG_DEALT
    HintSlot_Injury,        // HINT_DMG_RCVD
    HintSlot_NotReady,      // HINT_COOLDOWN_NOTREADY (SINGLE)
    HintSlot_Expired,       // HINT_COOLDOWN_EXPIRED
    HintSlot_Countdown,     // HINT_COOLDOWN_COUNTDOWN (SINGLE)
    HintSlot_Default        // HINT_LOWEST
}
