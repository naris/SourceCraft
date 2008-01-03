/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: jetpack.inc
 * Description: Native Interface to Jetpacks for Source
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _jetpack_included
 #endinput
#endif
#define _jetpack_included

/**
 * Assume control of the Jetpack plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the jetpack.
 * @param announce 		Announce status changes to the player.
 * @return		    	none
 */
native ControlJetpack(bool:plugin_only=true,bool:announce=true);

/**
 * Get the jetpack indicator of the player
 *
 * @param index 	Client index
 * @return			1 if the player has a jetpack
 */
native GetJetpack(client);

/**
 * Get the jetpack fuel amount of the player
 *
 * @param index 	Client index
 * @return			amount of fuel the jetpack has
 */
native GetJetpackFuel(client);

/**
 * Get the refueling time for the jetpack of the player
 *
 * @param index 	Client index
 * @return			Refueling time for the jetpack
 */
native Float:GetJetpackRefuelingTime(client);

/**
 * Set fuel for the jetpack of the player
 *
 * @param index 	Client index
 * @param fuel	 	Amount of fuel for the jetpack
 * @return			none
 */
native SetJetpackFuel(client, fuel);

/**
 * Set the refueling time for the jetpack of the player
 *
 * @param index 	Client index
 * @param time	 	Refueling time for the jetpack
 * @return			none
 */
native SetJetpackRefuelingTime(client, Float:fuel);

/**
 * Give a jetpack to the player
 *
 * @param index 	Client index
 * @param fuel	 	Amount of fuel for the jetpack (-1 == infinate)
 * @return			amount of fuel the jetpack has
 */
native GiveJetpack(client, fuel=-1,Float:refueling_time=0.0);

/**
 * Take the jetpack from the player
 *
 * @param index 	Client index
 * @return			none
 */
native TakeJetpack(client);

/**
 * Give a jetpack to the player
 *
 * @param index 	Client index
 * @param fuel	 	Amount of fuel to add to the jetpack (-1 == infinate)
 * @return			amount of fuel the jetpack has
 */
native GiveJetpackFuel(client, fuel=-1);

/**
 * Take fuel from the jetpack of the player
 *
 * @param index 	Client index
 * @param fuel	 	Amount of fuel to remove from the jetpack (default == all)
 * @return			amount of fuel the jetpack has
 */
native TakeJetpackFuel(client, fuel=-1);

/**
 * Start the jetpack (bind to a keydown)
 *
 * @param index 	Client index
 * @return			none
 */
native StartJetpack(client);

/**
 * Stop the jetpack (bind to a keyup)
 *
 * @param index 	Client index
 * @return			none
 */
native StopJetpack(client);

