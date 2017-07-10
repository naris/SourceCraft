/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: defines.inc
 * Description: Define various symbols used by SourceCraft primitives
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _defines_included
 #endinput
#endif
#define _defines_included

#define MAXENTITIES          2048

#define DESCRIPTION_LENGTH   2048
#define LONG_STRING_LENGTH    256
#define ITEM_STRING_LENGTH    128
#define NAME_STRING_LENGTH     64
#define CLASS_STRING_LENGTH    32
#define SHORT_STRING_LENGTH    32  // 16
#define SMALL_STRING_LENGTH    16

// Race Energy Use Flags used by Set/GetRaceEnergyFlags() natives
#define RACE_NO_ENERGY          0
#define RACE_USES_ENERGY        1
#define RACE_USES_ACCUMULATED   2

// Define fileIds used by Config natives
#define MAIN                   -1
#define SHOPITEM                0

// Define nodes used by Config natives
#define NONE                   -1

// Utility to check a bit pattern
#define IsSet(%1,%2)            ((%1 & %2) == %2)
#define IsNotSet(%1,%2)         ((%1 & %2) != %2)
#define Bit_IsSet(%1)           ((%1) != any:0)
#define FlipBit_IsSet(%1)       ((%1) == any:0)

enum Translation
{
    Translation_Default = -1,
    Translation_None = 0,
    Translation_Auto,
    Translation_Custom,
    Translation_SC,
    Translation_W3S
};
