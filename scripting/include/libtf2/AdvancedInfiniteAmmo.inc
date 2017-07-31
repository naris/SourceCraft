/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: AdvancedInfiniteAmmo.inc
 * Description: Native Interface to the TF2 AdvancedInfiniteAmmo
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _AdvancedInfiniteAmmo_included
 #endinput
#endif
#define _AdvancedInfiniteAmmo_included

/**
 * Assume control of the TF2 AdvancedInfiniteAmmo plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the AdvancedInfiniteAmmo plugin.
 * @param announce	 	Set to 1 to show Advanced Infinite Ammo changes in chat.
 * @return		    	none
 */
native ControlInfiniteAmmo(bool:plugin_only=true, bool:announce=false);

/**
 * Enable AdvancedInfiniteAmmo for the player
 *
 * @param index 	Client index
 * @param enable    Enable/Disable Infinite Ammo for client
 * @param time      How many seconds to enable infinate ammo (0.0 == forever)
 * @return			none
 */
native SetInfiniteAmmo(client,bool:enable=true,Float:time=0.0);

/**
 * Give a player ammo for the weapon in a slot
 *
 * @param index 	Client index
 * @param slot      Slot of the weapon to provide ammo for (-1 for active weapon)
 * @return			none
 */
native FillAmmo(client,slot=-1);

/**
 * Give a player ammo for a weapon
 *
 * @param index 	Client index
 * @param slot      Weapon to provide ammo for
 * @return			none
 */
native FillWeaponAmmo(client,weapon);


/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_aia = 
{
	name = "aia",
	file = "AdvancedInfiniteAmmo.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_aia_SetNTVOptional()
{
	MarkNativeAsOptional("ControlInfiniteAmmo");
	MarkNativeAsOptional("SetInfiniteAmmo");
	MarkNativeAsOptional("FillWeaponAmmo");
	MarkNativeAsOptional("FillAmmo");
}
#endif
