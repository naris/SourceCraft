/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: horsemann.inc
 * Description: Native Interface to horsemann
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _horsemann_included
 #endinput
#endif
#define _horsemann_included

/**
 * Spawns a horsemann where the client is looking
 *
 * @param client 	Client index
 * @param model     Model to use for the hatman, empty string uses TF2 model
 * @return			Returns 0 if a horsemann was spawned successfully
 */
native SpawnHorsemann(client, const String:model[]="");

/**
 * Changes the client's model to the hatman model
 *
 * @param client 	Client index
 * @param model     Model to use for the hatman, empty string uses TF2 model
 * @return			Returns 0 if the client's model was changed to the hatman model
 *                  Returns 1 if the client's model was changes back to normal
native SummonHorsemann(client, const String:model[]="");
 */

/**
 * Assume control of this plugin
 *
 * @param plugin_only 	Set to 1 to assume control and disable admin functions.
 * @return		    	none
 */
native ControlHorsemann(bool:plugin_only=true);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_horsemann = 
{
	name = "horsemann",
	file = "horsemann.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_horsemann_SetNTVOptional()
{
	MarkNativeAsOptional("SpawnHorsemann");
	//MarkNativeAsOptional("SummonHorsemann");
	MarkNativeAsOptional("ControlHorsemann");
}
#endif
