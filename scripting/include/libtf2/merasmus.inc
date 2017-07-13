/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: merasmus.inc
 * Description: Native Interface to Merasmus Spawner
 * Author(s): FlaminSarge (based on Naris's work)
 */

#if defined _merasmus_included
 #endinput
#endif
#define _merasmus_included

/**
 * Spawns a Merasmus where the client is looking
 *
 * @param client 	Client index
 * @param level     Level of Merasmus to spawn
 * @param model     Model to use for Merasmus, empty string uses TF2 model
 * @return			Returns 0 if Merasmus was spawned successfully.
 */
native TF2_SpawnMerasmus(client, level=0, const String:model[]="");

/**
 * Assume control of this plugin
 *
 * @param plugin_only 	Set to 1 to assume control and disable admin functions.
 * @return		    	none
 */
native ControlMerasmus(bool:plugin_only=true);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_merasmus = 
{
	name = "merasmus",
	file = "merasmus.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_merasmus_SetNTVOptional()
{
	MarkNativeAsOptional("TF2_SpawnMerasmus");
	MarkNativeAsOptional("ControlMerasmus");
}
#endif
