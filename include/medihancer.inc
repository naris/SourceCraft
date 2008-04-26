/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: medihancer.inc
 * Description: Native Interface to the Medic Enhancer
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _medihancer_included
 #endinput
#endif
#define _medihancer_included

/**
 * Assume control of the Medic Enhancer plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the Medic Enhancer plugin.
 * @return		    	none
 */
native ControlMedicEnhancer(bool:plugin_only=true);

/**
 * Give a hook to the player
 *
 * @param index 	Client index
 * @param arm       Set to true to enable Medic Enhancement for Client when a Medic.
 * @param amount    Set to amount of uber per heartbeat, 0 = default amount from convar.
 * @return			none
 */
native SetMedicEnhancement(client,bool:arm=true,amount=0);

