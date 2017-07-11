/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: buildlimit.inc
 * Description: Native Interface to buildlimit
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _buildlimit_included
 #endinput
#endif
#define _buildlimit_included

/**
 * Assume control of the buildlimit plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the Firemines plugin.
 * @return		    	none
 */
native ControlBuild(bool:plugin_only=true);

/**
 * Sets the number of buildings the payer can build.
 *
 * @param index 	        Client index
 * @param sentry            Set to number of sentries the player can build. (-1 is unlimited)
 * @param dispenser         Set to number of dispensers the player can build. (-1 is unlimited)
 * @param teleport_entry    Set to number of teleport_entrys the player can build. (-1 is unlimited)
 * @param teleport_exit     Set to number of sentries teleport_exits player can build. (-1 is unlimited)
 * @return			        none
 */
native GiveBuild(client,sentry=1,dispenser=1,teleport_entry=1,teleport_exit=1);

/**
 * Reset the build restriction back to 1 of each type of building.
 *
 * @param index 	Client index
 * @return			none
 */
native ResetBuild(client);

/**
 * Check if the client is allowed to build the building.
 *
 * @param index 	Client index
 * @param object:   The type of building being built
 * @param count:    Reference that returns the number of existing buildings
 * @return			true if the building can be built.
 */
native bool:CheckBuild(client,object,&count=0);

/**
 * Gets called when a building is built
 * @param client:   The index of the client that is building
 * @param object:   The type of building being built
 * @param count:    The number of that type of building already built by client
 * @return          Plugin_Handled will block building.
 */
functag OnBuildCommandFunc Action:public(client,object,count);

/**
 * Hook Pickups
 *
 * @param func 	Function to call when buildings are build
 * @return		none
 */
native HookBuildCommand(OnBuildCommandFunc:func);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_buildlimit = 
{
	name = "buildlimit",
	file = "buildlimit.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_buildlimit_SetNTVOptional()
{
	MarkNativeAsOptional("ControlBuild");
	MarkNativeAsOptional("ResetBuild");
	MarkNativeAsOptional("GiveBuild");
	MarkNativeAsOptional("HookBuildCommand");
}
#endif
