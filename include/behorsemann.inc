/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: behorsemann.inc
 * Description: Native Interface to behorsemann
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _behorsemann_included
 #endinput
#endif
#define _behorsemann_included

/**
 * Spawns a horsemann where the client is looking
 *
 * @param client 	    Client index
 * @param health  	    Amount of health HHH should have (default to use convar)
 * @param thirdPerson   true to change view to 3rd person (default to use convar)
 * @return			    Returns 0 if a horsemann was spawned successfully
 */
native MakeHorsemann(client, health=-1, bool:thirdPerson=bool:-1);

/**
 * Returns true if the client is a Horsemann
 *
 * @param client 	Client index
 * @return			Returns true if the client is a Horsemann
 */
native IsHorsemann(client);

/**
 * Scare players around the client like the Horsemann does
 *
 * @param client 	Client index
 * @return			Returns count of players that were scared
 */
native HorsemannScare(client);

/**
 * Assume control of this plugin
 *
 * @param plugin_only 	Set to 1 to assume control and disable admin functions.
 * @return		    	none
 */
native ControlBeHorsemann(bool:plugin_only=true);

/**
 * Gets called when the Horsemann scares someone
 *
 * @param client:   The index of the client that is the hhh
 * @param target:   The index of the player that is being scared (0 means scare was invoked, before targets are identified)
 * @return		    Plugin_Stop will prevent the client from being affected.
 */
forward Action:OnHorsemannScare(client,target);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_behorsemann = 
{
	name = "behorsemann",
	file = "behorsemann.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_behorsemann_SetNTVOptional()
{
	MarkNativeAsOptional("IsHorsemann");
	MarkNativeAsOptional("MakeHorsemann");
	MarkNativeAsOptional("HorsemannScare");
	MarkNativeAsOptional("ControlBeHorsemann");
}
#endif
