/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: hgr.inc
 * Description: Native Interface to HookGrabRope
 * Author(s): Sheepdude and SumGuy14
 */

#if defined _hgr_included
 #endinput
#endif
#define _hgr_included

#define HGR_GIVE 0
#define HGR_TAKE 1

#define HGR_HOOK 0
#define HGR_GRAB 1
#define HGR_ROPE 2

/**
 * Called when a player tries to hook.
 *
 * @param client     Player index.
 * @return           Plugin_Handled; to stop the player from hooking.
 */
forward Action:HGR_OnClientHook(client);

/**
 * Called when a player tries to search for a grab target.
 *
 * @param client     Player index.
 * @return           Plugin_Handled; to stop the player from searching.
 */
forward Action:HGR_OnClientGrabSearch(client);

/**
 * Called when a player stops grabbing (drops) the target.
 *
 * @param client     Player index.
 * @return           Plugin_Handled; has no effect.
 */
forward Action:HGR_OnClientGrabStop(client);

/**
 * Called when a player tries to grab a valid target.
 *
 * @param client     Player index.
 * @return           Plugin_Handled; to stop the player from grabbing.
 */
forward Action:HGR_OnClientGrab(client);

/**
 * Called when a player tries to rope.
 *
 * @param client     Player index.
 * @return           Plugin_Handled; to stop the player from roping.
 */
forward Action:HGR_OnClientRope(client);

/**
 * Gives or removes group access to hook, grab, or rope.
 * Each client will receive a notification in chat.
 *
 * @param target     Group target [@all/@ct/@t] (String)
 * @param access     0 - Give, 1 - Take (integer)
 * @param action     0 - Hook, 1 - Grab, 2 - Rope (integer)
 * @return           The number of players whose access was set.
 */
native HGR_Access(const String:target[], access, action);

/**
 * Gives or removes client access to hook, grab, or rope.
 * The client will receive a notification in chat.
 *
 * @param client     Player index (integer)
 * @param access     0 - Give, 1 - Take (integer)
 * @param action     0 - Hook, 1 - Grab, 2 - Rope (integer)
 * @return           True if successful, false if client is a bot.
 * @error            Player index is out of bounds.
 */
native bool:HGR_ClientAccess(client, access, action);

/**
 * Gives or removes client access to hook, grab, or rope.
 * The client will receive a notification in chat.
 *
 * @param client     Player index (integer)
 * @param duration   How long (in seconds) player has access, <=0 is unlimited
 * @param action     0 - Hook, 1 - Grab, 2 - Rope (integer)
 * @return           True if successful, false if client is a bot.
 * @error            Player index is out of bounds.
 */
native bool:HGR_TimedClientAccess(client, Float:duration, action);

/**
 * Returns whether or not a client is using the hook.
 *
 * @param client     Player index (integer)
 * @return           True if player is hooking, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsHooking(client);

/**
 * Returns whether or not a client is using the grab.
 *
 * @param client     Player index (integer)
 * @return           True if player is grabbing, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsGrabbing(client);

/**
 * Returns whether or not a client is being grabbed.
 *
 * @param client     Player index (integer)
 * @return           True if player is being grabbed, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsBeingGrabbed(client);

/**
 * Returns whether or not a client is using the rope.
 *
 * @param client     Player index (integer)
 * @return           True if player is using the rope, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsRoping(client);

/**
 * Returns whether or not a client is hooking backward
 *
 * @param client     Player index (integer)
 * @return           True if player is hooking backward, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsPushing(client);

/**
 * Returns whether or not a client is attracting a grab target
 *
 * @param client     Player index (integer)
 * @return           True if player is attracting grab target, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsAttracting(client);

/**
 * Returns whether or not a client is repelling a grab target
 *
 * @param client     Player index (integer)
 * @return           True if player is repelling grab target, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsRepelling(client);

/**
 * Returns whether or not a client is ascending a rope
 *
 * @param client     Player index (integer)
 * @return           True if player is ascending a rope, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsAscending(client);

/**
 * Returns whether or not a client is descending a rope
 *
 * @param client     Player index (integer)
 * @return           True if player is descending a rope, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_IsDescending(client);

/**
 * Retrieves the location where a client's hook is attached.
 *
 * @param client     Player index (integer)
 * @param buffer     Buffer to store the location in (Float)
 * @return           True if player is hooking, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_GetHookLocation(client, Float:buffer[3]);

/**
 * Retrieves the location where a client's grab is attached.
 *
 * @param client     Player index (integer)
 * @param buffer     Buffer to store the location in (Float)
 * @return           True if player is grabbing, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_GetGrabLocation(client, Float:buffer[3]);

/**
 * Retrieves the location where a client's rope is attached.
 *
 * @param client     Player index (integer)
 * @param buffer     Buffer to store the location in (Float)
 * @return           True if player is using the rope, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_GetRopeLocation(client, Float:buffer[3]);

/**
 * Retrieves the location opposite of where a client's hook is attached.
 *
 * @param client     Player index (integer)
 * @param buffer     Buffer to store the location in (Float)
 * @return           True if player is using the hook, false otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_GetPushLocation(client, Float:buffer[3]);

/**
 * Retrieves the distance between the client and where their hook landed
 *
 * @param client     Player index (integer)
 * @return           Hook distance, or -1 if client is not hooking.
 * @error            Player index is out of bounds.
 */
native Float:HGR_GetHookDistance(client);

/**
 * Retrieves the distance between the client and their grab target
 *
 * @param client     Player index (integer)
 * @return           Grab distance, or -1 if client is not hooking.
 * @error            Player index is out of bounds.
 */
native Float:HGR_GetGrabDistance(client);

/**
 * Retrieves the distance between the client and where their rope landed
 *
 * @param client     Player index (integer)
 * @return           Rope distance, or -1 if client is not hooking.
 * @error            Player index is out of bounds.
 */
native Float:HGR_GetRopeDistance(client);

/**
 * Retrieves the distance between the client and the location opposite of where their hook landed
 *
 * @param client     Player index (integer)
 * @return           Push distance, or -1 if client is not hooking.
 * @error            Player index is out of bounds.
 */
native Float:HGR_GetPushDistance(client);

/**
 * Retrieves the entity index of a client's hook target.
 *
 * @param client     Player index (integer)
 * @return           Entity index of hook target, or -1 if client has no target.
 * @error            Player index is out of bounds.
 */
native HGR_GetHookTarget(client);

/**
 * Retrieves the entity index of a client's grab target.
 *
 * @param client     Player index (integer)
 * @return           Entity index of grab target, or -1 if client has no target.
 * @error            Player index is out of bounds.
 */
native HGR_GetGrabTarget(client);

/**
 * Retrieves the entity index of a client's rope target.
 *
 * @param client     Player index (integer)
 * @return           Entity index of rope target, or -1 if client has no target.
 * @error            Player index is out of bounds.
 */
native HGR_GetRopeTarget(client);

/**
 * Retrieves the entity index opposite of a client's hook target.
 *
 * @param client     Player index (integer)
 * @return           Entity index of push target, or -1 if client has no target.
 * @error            Player index is out of bounds.
 */
native HGR_GetPushTarget(client);

/**
 * Forces a client to use their hook.
 *
 * @param client     Player index (integer)
 * @return           False if player is performing an action and unable to hook, true otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_ForceHook(client);

/**
 * Forces a client to use their grab.
 *
 * @param client     Player index (integer)
 * @return           False if player is performing an action and unable to grab, true otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_ForceGrab(client);

/**
 * Forces a client to use their rope.
 *
 * @param client     Player index (integer)
 * @return           False if player is performing an action and unable to rope, true otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_ForceRope(client);

/**
 * Forces a client to use their hook push.
 *
 * @param client     Player index (integer)
 * @return           False if player is performing an action and unable to push, true otherwise.
 * @error            Player index is out of bounds.
 */
native bool:HGR_ForcePush(client);

/**
 * Stops a client hook in progress.
 *
 * @param client     Player index (integer)
 * @return           True if successful, false if player is not hooking.
 * @error            Player index is out of bounds.
 */
native bool:HGR_StopHook(client);

/**
 * Stops a client grab in progress.
 *
 * @param client     Player index (integer)
 * @return           True if successful, false if player is not grabbing.
 * @error            Player index is out of bounds.
 */
native bool:HGR_StopGrab(client);

/**
 * Stops a client rope in progress.
 *
 * @param client     Player index (integer)
 * @return           True if successful, false if player is not roping.
 * @error            Player index is out of bounds.
 */
native bool:HGR_StopRope(client);

/**
 * Stops a client hook push in progress.
 *
 * @param client     Player index (integer)
 * @return           True if successful, false if player is not pushing.
 * @error            Player index is out of bounds.
 */
native bool:HGR_StopPush(client);

public SharedPlugin:__pl_hookgrabrope =
{
    name = "hookgrabrope",
    file = "hookgrabrope.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_hookgrabrope_SetNTVOptional()
{
	MarkNativeAsOptional("HGR_Access");
	MarkNativeAsOptional("HGR_ClientAccess");
	MarkNativeAsOptional("HGR_IsHooking");
	MarkNativeAsOptional("HGR_IsGrabbing");
	MarkNativeAsOptional("HGR_IsBeingGrabbed");
	MarkNativeAsOptional("HGR_IsRoping");
	MarkNativeAsOptional("HGR_IsPushing");
	MarkNativeAsOptional("HGR_IsAttracting");
	MarkNativeAsOptional("HGR_IsRepelling");
	MarkNativeAsOptional("HGR_IsAscending");
	MarkNativeAsOptional("HGR_IsDescending");
	MarkNativeAsOptional("HGR_GetHookLocation");
	MarkNativeAsOptional("HGR_GetGrabLocation");
	MarkNativeAsOptional("HGR_GetRopeLocation");
	MarkNativeAsOptional("HGR_GetPushLocation");
	MarkNativeAsOptional("HGR_GetHookDistance");
	MarkNativeAsOptional("HGR_GetGrabDistance");
	MarkNativeAsOptional("HGR_GetRopeDistance");
	MarkNativeAsOptional("HGR_GetPushDistance");
	MarkNativeAsOptional("HGR_GetHookTarget");
	MarkNativeAsOptional("HGR_GetGrabTarget");
	MarkNativeAsOptional("HGR_GetRopeTarget");
	MarkNativeAsOptional("HGR_GetPushTarget");
	MarkNativeAsOptional("HGR_ForceHook");
	MarkNativeAsOptional("HGR_ForceGrab");
	MarkNativeAsOptional("HGR_ForceRope");
	MarkNativeAsOptional("HGR_ForcePush");
	MarkNativeAsOptional("HGR_StopHook");
	MarkNativeAsOptional("HGR_StopGrab");
	MarkNativeAsOptional("HGR_StopRope");
	MarkNativeAsOptional("HGR_StopPush");
}
#endif
