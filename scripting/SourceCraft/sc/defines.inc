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

// Define fileIds used by Config natives
#define MAIN                   -1
#define SHOPITEM                0

// Define nodes used by Config natives
#define NONE                   -1

// Define values used as unlimited amount in CreateShopItem()
#define NOT_AVAILABLE           0
#define UNLIMITED              -1

// Utility to check a bit pattern
#define IsSet(%1,%2)            ((%1 & %2) == %2)
#define IsNotSet(%1,%2)         ((%1 & %2) != %2)
#define Bit_IsSet(%1)           ((%1) != any:0)
#define FlipBit_IsSet(%1)       ((%1) == any:0)

// Race Energy Use Flags used by Set/GetRaceEnergyFlags() natives
enum EnergyFlags (<<=1)
{
    NoEnergy = 0,
    UsesEnergy = 1,
    UsesAccumulated
};

// Translation Types used by CreateRace() & CreateShopItem()
enum Translation
{
    Translation_Default = -1,
    Translation_None = 0,
    Translation_Auto,
    Translation_Custom,
    Translation_SC,
    Translation_W3S
};
