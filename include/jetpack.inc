
#if defined _jetpack_included
 #endinput
#endif
#define _jetpack_included

/**
 * Get the jetpack indicator of the player
 *
 * @param index 		Client index
 * @return			1 if the player has a jetpack
 */
native GetJetpack(client);

/**
 * Get the jetpack fuel amount of the player
 *
 * @param index 		Client index
 * @return			amount of fuel the jetpack has
 */
native GetJetpackFuel(client);

/**
 * Get the refueling time for the jetpack of the player
 *
 * @param index 		Client index
 * @return			Refueling time for the jetpack
 */
native Float:GetJetpackRefuelingTime(client);

/**
 * Set the jetpack indicator for the player
 *
 * @param index 		Client index
 * @return			1 if the player has a jetpack
 */
native SetJetpack(client);

/**
 * Set fuel for the jetpack of the player
 *
 * @param index 		Client index
 * @param fuel	 		Amount of fuel for the jetpack
 * @return			none
 */
native SetJetpackFuel(client, fuel);

/**
 * Set the refueling time for the jetpack of the player
 *
 * @param index 		Client index
 * @param time	 		Refueling time for the jetpack
 * @return			none
 */
native SetJetpackRefuelingTime(client, Float:fuel);

/**
 * Give a jetpack to the player
 *
 * @param index 		Client index
 * @param fuel	 		Amount of fuel for the jetpack (-1 == infinate)
 * @return			amount of fuel the jetpack has
 */
native GiveJetpack(client, fuel=-1);

/**
 * Take the jetpack from the player
 *
 * @param index 		Client index
 * @return			0
 */
native TakeJetpack(client);

/**
 * Give a jetpack to the player
 *
 * @param index 		Client index
 * @param fuel	 		Amount of fuel to add to the jetpack (-1 == infinate)
 * @return			amount of fuel the jetpack has
 */
native GiveJetpackFuel(client, fuel=-1);

/**
 * Take fuel from the jetpack of the player
 *
 * @param index 		Client index
 * @param fuel	 		Amount of fuel to remove from the jetpack (default == all)
 * @return			amount of fuel the jetpack has
 */
native TakeJetpackFuel(client, fuel=-1);

/**
 * Start the jetpack (bind to a keydown)
 *
 * @param index 		Client index
 * @return			none
 */
native StartJetpack(client);

/**
 * Stop the jetpack (bind to a keyup)
 *
 * @param index 		Client index
 * @return			none
 */
native StopJetpack(client);

