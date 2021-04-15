/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: rollermine.inc
 * Description: Native Interface to rollermine
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _rollermine_included
 #endinput
#endif
#define _rollermine_included

/**
 * Assume control of the rollermine plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the rollermine plugin.
 * @return		    	none
 */
native ControlRM(bool:plugin_only=true);

/**
 * Sets (Plants) a rollermine where the client is looking.
 *
 * @param index 	Client index
 * @return			entity
 */
native SetRollermine(client);

/**
 * Spawns a rollermine.
 *
 * @param index 	Client index
 * @param pos    	Position to spawn the rollermine at.
 * @return			entity
 */
native SpawnRollerMine(client);

/**
 * Gets called when when a rollermine is set
 * @param client 	Client index of the player setting the rollermine
 */
forward Action:OnSetRollermine(client);

/* DO NOT EDIT BELOW THIS LINE */

{
	name = "rollermine",
	file = "rollermine.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_firemines_SetNTVOptional()
{
	MarkNativeAsOptional("ControlRM");
	MarkNativeAsOptional("SetRollermine");
}
#endif
