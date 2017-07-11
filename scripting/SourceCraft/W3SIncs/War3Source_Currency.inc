/**
 * File: War3Source_Currency.inc
 * Description: Interface to the currency system
 * Author(s): War3Source Team  
 */

enum W3CurrencyMode {
    CURRENCY_MODE_INVALID   = -1,
    CURRENCY_MODE_WAR3_GOLD = 0,
    CURRENCY_MODE_DORRAR    = 1
};

#define MAX_CURRENCY_NAME     64

// Forwards

#if !defined SOURCECRAFT // Not Implemented!
// Fired everytime somebodys currency changes
forward OnCurrencyChanged(client, oldCurrency, newCurrency);
#endif

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// These are most interesting to a plugin author ;)

/**
 * Retrieve the amount of currency this player has
 */
#if !defined SOURCECRAFT
native War3_GetCurrency(client);
#else
#define War3_GetCurrency GetMoney
#endif

/**
 * Give currency to a player, respecting the maximum 
 * 
 * @returns If the currency was changed or not
 */
#if !defined SOURCECRAFT
native bool:War3_AddCurrency(client, currencyToAdd);
#else
stock bool:War3_AddCurrency(client, currencyToAdd)
{
    return (SetMoney(client, GetMoney(client) + currencyToAdd) >= 0);
}
#endif

/**
 * Remove currency from a player, respecting the minimum
 * 
 * @returns If the currency was changed or not
 */
#if !defined SOURCECRAFT
native bool:War3_SubstractCurrency(client, currencyToSubstract);
#else
stock bool:War3_SubstractCurrency(client, currencyToSubstract)
{
    return (SetMoney(client, GetMoney(client) - currencyToSubstract) >= 0);
}
#endif

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// These cater more towards internal usage

#if !defined SOURCECRAFT // Not Implemented!
/**
 * Change the currency of this player to a new value
 * 
 * @returns If the currency was changed or not
 */
native bool:War3_SetCurrency(client, newCurrency);
#endif

/** 
 * Gets/Sets the War3Source internal gold currency value for this player
 */
#if !defined SOURCECRAFT
native War3_GetGold(client);
native War3_SetGold(client, newGold);
#else
#define War3_SetGold SetCrystals
#define War3_GetGold GetCrystals
#endif

#if !defined SOURCECRAFT // Not Implemented!
/**
 * Get the name of the currency for the given amount of units
 * 
 * Uses the value stored with SetTrans() for translating!
 */
native War3_GetCurrencyName(amount, String:currencyName[], maxLength);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Working on the core? You might have to touch these

/**
 * Retrieve the currently set currency mode as defined by the cvar war3_currency_mode
 * 
 * CURRENCY_MODE_WAR3_GOLD  War3 Gold
 * CURRENCY_MODE_DORRAR     $ in Counter-Strike Source or Team Fortress 2 MVM mode
 */
native W3CurrencyMode:War3_GetCurrencyMode();
#endif

/**
 * Retrieve the maximum amount of currency a player can hold as defined by the cvar war3_max_currency
 */
#if !defined SOURCECRAFT
native War3_GetMaxCurrency();
#else
#define War3_GetMaxCurrency GetMaxCrystals
#endif

/**
 * Retrieve the amount of currency gained per kill as defined by the cvar war3_currency_per_kill
 * or the amount of currency gained per assist as defined by the cvar war3_currency_per_assist
 */
#if !defined SOURCECRAFT // Not Implemented!
native War3_GetKillCurrency();
native War3_GetAssistCurrency();
#endif
