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
 * Enable a player to utilize medic infections.
 *
 * @param index 	Client index
 * @param number    Set to number of tipmines to give the player.
 * @return			none
 */
native GiveTripmine(client,number=0);

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
	MarkNativeAsOptional("GiveTipmines");
}
#endif
