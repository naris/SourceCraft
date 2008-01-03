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
 * @return			none
 */
native GiveHook(client);

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
 * @return			none
 */
native GiveGrab(client);

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
 * @return			none
 */
native GiveRope(client);

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

