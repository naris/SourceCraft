/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: hgrsource.inc
 * Description: Native Interface to HookGrabRope for Source
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _hgrsource_included
 #endinput
#endif
#define _hgrsource_included

/**
 * Assume control of the HookGrabRope plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the HGR plugin.
 * @return		    	none
 */
native ControlHookGrabRope(bool:plugin_only=true);

/**
 * Give a hook to the player
 *
 * @param index 	Client index
 * @param duration  How long (in seconds) player can hook, <=0 is unlimited (default 0)
 * @param range     Range of the hook, <=0.0 is unlimited (default 0.0)
 * @param flags     Not used yet.
 * @return			none
 */
native GiveHook(client,duration=0,Float:range=0.0,flags=0);

/**
 * Take the hook from the player
 *
 * @param index 	Client index
 * @return			none
 */
native TakeHook(client);

/**
 * Give a grabber to the player
 *
 * @param index 	Client index
 * @param duration  How long (in seconds) player can grab, <=0 is unlimited
 * @param range     Range of the grab, <=0.0 is unlimited (default 0.0)
 * @param flags     1==Puller (drag victim closer), 0==Grabber (keep distance constant {more or less}) (default 0)
 * @return			none
 */
native GiveGrab(client,duration=0,Float:range=0.0,flags=0);

/**
 * Take the grabber from the player
 *
 * @param index 	Client index
 * @return			none
 */
native TakeGrab(client);

/**
 * Give a rope to the player
 *
 * @param index 	Client index
 * @param duration  How long (in seconds) player can rope, <=0 is unlimited
 * @param range     Range of the rope, <=0.0 is unlimited (default 0.0)
 * @param flags     Not used yet.
 * @return			none
 */
native GiveRope(client,duration=0,Float:range=0.0,flags=0);

/**
 * Take the rope from the player
 *
 * @param index 	Client index
 * @return			none
 */
native TakeRope(client);

/**
 * Use the hook (bind to a keydown)
 *
 * @param index 	Client index
 * @return			none
 */
native Hook(client);

/**
 * Stop using the hook (bind to a keyup)
 *
 * @param index 	Client index
 * @return			none
 */
native UnHook(client);

/**
 * Toggle the state of the hook
 *
 * @param index 	Client index
 * @return			none
 */
native ToggleHook(client);

/**
 * Use the grabber (bind to a keydown)
 *
 * @param index 	Client index
 * @return			none
 */
native Grab(client);

/**
 * Stop using the grabber (bind to a keyup)
 *
 * @param index 	Client index
 * @return			none
 */
native Drop(client);

/**
 * Toggle the state of the grabber
 *
 * @param index 	Client index
 * @return			none
 */
native ToggleGrab(client);

/**
 * Use the rope (bind to a keydown)
 *
 * @param index 	Client index
 * @return			none
 */
native Rope(client);

/**
 * Stop using the rope (bind to a keyup)
 *
 * @param index 	Client index
 * @return			none
 */
native Detach(client);

/**
 * Toggle the state of the rope
 *
 * @param index 	Client index
 * @return			none
 */
native ToggleRope(client);

/**
 * Gets called when the grabber grabs someone
 * @param client: The index of the client that used the grabber.
 * @param target: The index of the target that got grabbed
 */
forward OnGrab(client,target);

/**
 * Gets called when the grabber drops someone
 * @param client: The index of the client that used the grabber.
 * @param target: The index of the target that got grabbed
 */
forward OnDrop(client,target);
