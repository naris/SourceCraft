/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: armor_flags.inc
 * Description: Armor flags
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _armor_flags_included
 #endinput
#endif
#define _armor_flags_included

enum ArmorFlags (<<= 1)
{
    Armor_Default = 0,          // Armor is not a shield, default value.
    Armor_IsShield = 1,         // Armor is a shield (regenerates)
    Armor_NoLimit,              // Do NOT Limit regeneration to the client's Max HP
    Armor_NoCheckStunned,       // Don't Check Stunned restriction when regenerating
    Armor_IsShopItem,           // true  = Armor is a ShopItem, check NoShopItems restriction
}                               // false = Armor is an Upgrade, check NoUpgrades restriction

enum RegenFlags (<<=1)
{
    Regen_Default = 0,          // Check Stunned & NoUpgrades restrictions when regenerating
    Regen_NoCheckStunned = 1,   // Do NOT Check Stunned restriction when regenerating
    Regen_IsShopItem,           // true  = Regen from a ShopItem, check NoShopItems restriction
}                               // false = Regen from an Upgrade, check NoUpgrades restriction
