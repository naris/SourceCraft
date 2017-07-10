/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: MonoSpawn.inc
 * Description: Native Interface to Monoculus Spawner
 * Author(s): FlaminSarge (based on Naris's work)
 */

#if defined _MonoSpawn_included
 #endinput
#endif
#define _MonoSpawn_included

/**
 * Spawns a Monoculus where the client is looking
 *
 * @param client 	Client index
 * @param level     Level of monoculus to spawn
 * @param model     Model to use for the eyeboss, empty string uses TF2 model
 * @return			Returns 0 if a Monoculus was spawned successfully.
 */
native TF2_SpawnMonoculus(client, level=0, const String:model[]="");

/**
 * Changes the client's model to the EyeBoss model
 *
 * @param client 	Client index
 * @param model     Model to use for the eyeboss, empty string uses TF2 model
 * @return			Returns 0 if the client's model was changed to the eyeboss model
 *                  Returns 1 if the client's model was changes back to normal
native TF2_SummonMonoculus(client, const String:model[]="");
 */

/**
 * Assume control of this plugin
 *
 * @param plugin_only 	Set to 1 to assume control and disable admin functions.
 * @return		    	none
 */
native ControlMonoculus(bool:plugin_only=true);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_MonoSpawn = 
{
	name = "MonoSpawn",
	file = "MonoSpawn.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_MonoSpawn_SetNTVOptional()
{
	MarkNativeAsOptional("TF2_SpawnMonoculus");
	//MarkNativeAsOptional("TF2_SummonMonoculus");
	MarkNativeAsOptional("ControlMonoculus");
}
#endif
