/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: medipacks.inc
 * Description: Native Interface to the TF2 Medipacks
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _medipacks_included
 #endinput
#endif
#define _medipacks_included

/**
 * Assume control of the TF2 Medipacks plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the Medipacks plugin.
 * @return		    	none
 */
native ControlMedipacks(bool:plugin_only=true);

/**
 * Enable Medipacks for a player.
 *
 * @param index 	Client index
 * @param enable    Enable/Disable medipacks for client (0 = disabled   | 1 = on death |
 *                                                       2 = on command | 3 = on death and command)
 * @param amount    Set to amount of initial uber when a medic.
 * @return			none
 */
native SetMedipack(client,enable=3,amount=0);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_medipacks = 
{
	name = "medipacks",
	file = "medipacks.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_medipacks_SetNTVOptional()
{
	MarkNativeAsOptional("ControlMedipacks");
	MarkNativeAsOptional("SetMedipack");
}
#endif
