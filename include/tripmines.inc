/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tripmines.inc
 * Description: Native Interface to tripmines
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _tripmines_included
 #endinput
#endif
#define _tripmines_included

/**
 * Assume control of the tripmines plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the MedicInfect plugin.
 * @return		    	none
 */
native ControlTripmines(bool:plugin_only=true);

/**
 * Give a player one or more tripmines to plant
 *
 * @param index 	Client index
 * @param number    Set to number of tipmines to give the player.
 * @return			none
 */
native GiveTripmine(client,number=0);

/**
 * Returns how many tripmines a player has (or is allowed).
 *
 * @param index 	Client index
 * @param allowed   Set to  true to return number allowed, otherwise
 * @return			returns number of remaining tripmines.
 */
native HasTripmine(client,bool:allowed=false);

/**
 * Sets (Plants) a tripmine.
 *
 * @param index 	Client index
 * @return			none
 */
native SetTripmine(client);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_tripmines = 
{
	name = "tripmines",
	file = "tripmines.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_tripmines_SetNTVOptional()
{
	MarkNativeAsOptional("ControlTripmiens");
	MarkNativeAsOptional("GiveTipmine");
	MarkNativeAsOptional("HasTipmine");
	MarkNativeAsOptional("SetTipmine");
}
#endif
