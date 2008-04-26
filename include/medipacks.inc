/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: medipacks.inc
 * Description: Native Interface to the TF2 Medipacks
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _medipacks_included
 #endinput
#endif
#define _medipacks_included

/**
 * Assume control of the TF2 Medipacks plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the Medipacks plugin.
 * @return		    	none
 */
native ControlMediPacks(bool:plugin_only=true);

/**
 * Give a hook to the player
 *
 * @param index 	Client index
 * @param arm       Set to true to enable Medic Infections for Client when a Medic.
 * @param amount    Set to amount of initial uber when a medic.
 * @return			none
 */
native SetMediPack(client,bool:arm=true,amount=0);

