/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: RateOfFire.inc
 * Description: Native Interface to the TF2 Rate Of Fire plugin
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _RateOfFire_included
 #endinput
#endif
#define _RateOfFire_included

/**
 * Assume control of the TF2 Rate Of Fire plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the Rate Of Fire plugin.
 * @return		    	none
 */
native ControlROF(bool:plugin_only=true);

/**
 * Set the Rate Of Fire for a player.
 *
 * @param client 	Client index
 * @param rof 	    Rate Of Fire multiplier. (-1.0 = use convar, 1.0 = normal)
 * @param energy 	Amount SourceCraft Energy required per shot (if any).
 * @return			none
 */
native SetROF(client,Float:rof=-1.0, Float:energy=0.0);

/**
 * Get the Rate Of Fire (and energy required) for a player.
 *
 * @param index 	Client index
 * @param energy 	Amount SourceCraft Energy required per shot (if any).
 * @return			Rate Of Fire multiplier. (-1.0 = use convar, 1.0 = normal)
 */
native Float:GetROF(client, &Float:energy=0.0);

/**
 * Disarm a player
 *
 * @param index 	Client index
 * @param disarmed 	Set true to prevent client for shooting
 * @return			none
 */
native DisarmPlayer(client,bool:disarmed=true);

/**
 * Gets called when a player fires thier weapon
 * @param index 	Client index
 * @noreturn
 */
forward OnWeaponFired(index);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_RateOfFire = 
{
	name = "RateOfFire",
	file = "RateOfFire.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_RateOfFire_SetNTVOptional()
{
	MarkNativeAsOptional("ControlROF");
	MarkNativeAsOptional("DisarmPlayer");
	MarkNativeAsOptional("SetROF");
	MarkNativeAsOptional("GetROF");
}
#endif
