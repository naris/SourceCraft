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
native ControlJetpack(bool:plugin_only=true);

/**
 * Get the jetpack indicator of the player
 *
 * @param index 	Client index
 * @return			true if the player has a jetpack
 */
native bool:HasJetpack(client);

/**
 * Returns if the player's jetpack is on
 *
 * @param index 	Client index
 * @return			true if the player's jetpack is on
 */
native bool:IsJetpackOn(client);

/**
 * Get the jetpack fuel amount of the player
 *
 * @param index 	Client index
 * @return			amount of fuel the jetpack has
 */
native GetJetpackFuel(client);

/**
 * Get the fuel consumption rate for the jetpack of the player
 *
 * @param index 	Client index
 * @return			Rate at which the jetpack consumes fuel
 */
native GetJetpackRate(client);

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
 * @param fuel	 	Amount of fuel for the jetpack (-1 == infinate)
 * @param refuels	Number of times the jetpack can be refueled (-1 == infinate)
 * @return			none
 */
native SetJetpackFuel(client, fuel=-1, refuels=-1);

/**
 * Set the fuel consumption rate for the jetpack of the player
 *
 * @param index 	Client index
 * @param rate      Rate at which the jetpack consumes fuel (-1 == use class convars)
 * @return			none
 */
native SetJetpackRate(client, rate=-1);

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
 * @param index 	        Client index
 * @param fuel	 	        Amount of fuel for the jetpack (-1 == infinate)
 * @param refueling_time	Refueling time for the jetpack
 * @param max_refuels	    Number of times the jetpack can be refueled (-1 == infinate)
 * @param rate              Rate at which the jetpack consumes fuel (per game frame)
 * @param explode           jetpack explodes on death if true
 * @param burn              jetpack burns enemies if true
 * @return			        amount of fuel the jetpack has
 */
native GiveJetpack(client, fuel=-1, Float:refueling_time=0.0, max_refuels=-1,
                   rate=-1, bool:explode=false, bool:burn=false);

/**
 * Take the jetpack from the player
 *
 * @param index 	Client index
 * @return			none
 */
native TakeJetpack(client);

/**
 * Give jetpack fuel to the player
 *
 * @param index 	Client index
 * @param fuel	 	Amount of fuel to add to the jetpack (-1 == infinate)
 * @param refuels	Number of refuels to add to the jetpack (-1 == infinate)
 * @return			amount of fuel the jetpack has
 */
native GiveJetpackFuel(client, fuel=-1, refuels=-1);

/**
 * Take fuel from the jetpack of the player
 *
 * @param index 	Client index
 * @param fuel	 	Amount of fuel to remove from the jetpack (-1 == all)
 * @param refuels	Number of refuels to remove from the jetpack (-1 == all)
 * @return			amount of fuel the jetpack has
 */
native TakeJetpackFuel(client, fuel=-1, refuels=-1);

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

/**
 * Gets called when the Jetpack is started
 *
 * @param client: The index of the client that used the jetpack.
 * @return		  Plugin_Stop will prevent the jetpack from starting.
 */
forward Action:OnJetpack(client);

/**
 * Gets called when a Jetpack burns someone
 *
 * @param victim: The index of the victim to be set fire
 * @param client: The index of the client that is using the jetpack
 * @param damage: The damage to be done to the victim, can be changed.
 * @return		  Plugin_Stop will prevent the jetpack from burning the victim.
 */
forward Action:OnJetpackBurn(victim, client, &damage);

/**
 * Gets called when a Jetpack explodes
 *
 * @param victim: The index of the victim of the explosion
 * @param client: The index of the client that exploded
 * @param damage: The damage to be done to the victim, can be changed.
 * @return		  Plugin_Stop will prevent the jetpack from injuring the victim.
 */
forward Action:OnJetpackExplode(victim, client, &damage);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_jetpack = 
{
	name = "jetpack",
	file = "jetpack.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_jetpack_SetNTVOptional()
{
	MarkNativeAsOptional("ControlJetpack");
	MarkNativeAsOptional("HasJetpack");
	MarkNativeAsOptional("IsJetpackOn");
	MarkNativeAsOptional("GetJetpackFuel");
	MarkNativeAsOptional("GetJetpackRate");
	MarkNativeAsOptional("GetJetpackRefuelingTime");
	MarkNativeAsOptional("SetJetpackFuel");
	MarkNativeAsOptional("SetJetpackRate");
	MarkNativeAsOptional("SetJetpackRefuelingTime");
	MarkNativeAsOptional("GiveJetpack");
	MarkNativeAsOptional("TakeJetpack");
	MarkNativeAsOptional("GiveJetpackFuel");
	MarkNativeAsOptional("TakeJetpackFuel");
	MarkNativeAsOptional("StartJetpack");
	MarkNativeAsOptional("StopJetpack");
}
#endif
