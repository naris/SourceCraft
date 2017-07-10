/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: display_flags.inc
 * Description: Defines the display flags for SourceCraft
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _display_flags_included
 #endinput
#endif
#define _display_flags_included

#define SC_DISPLAY_DEFENSE        (1 << 0)    // 1
#define SC_DISPLAY_DAMAGE_DONE    (1 << 1)    // 2
#define SC_DISPLAY_KILLS          (1 << 2)    // 4
#define SC_DISPLAY_ULTIMATE       (1 << 3)    // 8
#define SC_DISPLAY_MISC_MESSAGE   (1 << 4)    // 16
#define SC_DISPLAY_ENEMY_DEFENDED (1 << 5)    // 32
#define SC_DISPLAY_DAMAGE_TAKEN   (1 << 6)    // 64
#define SC_DISPLAY_DEATHS         (1 << 7)    // 128
#define SC_DISPLAY_ENEMY_ULTIMATE (1 << 8)    // 256
#define SC_DISPLAY_ENEMY_MESSAGE  (1 << 9)    // 512
#define SC_DISPLAY_XP             (1 << 10)   // 1024
#define SC_DISPLAY_CREDITS        (1 << 11)   // 2048
#define SC_DISPLAY_DETAILS        (1 << 12)   // 4096
