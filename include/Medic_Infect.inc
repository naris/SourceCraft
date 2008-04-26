/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Medic_Infect.inc
 * Description: Native Interface to Medic_Infect
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _medicinfect_included
 #endinput
#endif
#define _medicinfect_included

/**
 * Assume control of the HookGrabRope plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the Medic_Infect plugin.
 * @return		    	none
 */
native ControlMedicInfect(bool:plugin_only=true);

/**
 * Give a hook to the player
 *
 * @param index 	Client index
 * @param arm       Set to true to enable Medic Infections for Client when a Medic.
 * @param amount    Set to amount of damage per heartbeat, 0 = default amount from convar.
 * @return			none
 */
native SetMedicInfect(client,bool:arm=true,amount=0);

