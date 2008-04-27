/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: MedicInfect.inc
 * Description: Native Interface to MedicInfect
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _medicinfect_included
 #endinput
#endif
#define _medicinfect_included

/**
 * Assume control of the MedicInfect plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the MedicInfect plugin.
 * @return		    	none
 */
native ControlMedicInfect(bool:plugin_only=true);

/**
 * Enable a player to utilize medic infections.
 *
 * @param index 	Client index
 * @param arm       Set to true to enable Medic Infections for Client when a Medic.
 * @param amount    Set to amount of damage per heartbeat, 0 = default amount from convar.
 * @return			none
 */
native SetMedicInfect(client,bool:arm=true,amount=0);

/**
 * Infect a player.
 *
 * @param index 	Client index of infector
 * @param target    Client index of target
 * @param allow     Set to true to enable Medic Infections for targets on the same team.
 * @return			none
 */
native MedicInfect(client,target,bool:allow=false);

/**
 * Heal a player.
 *
 * @param index 	Client index of infector
 * @param target    Client index of target
 * @return			none
 */
native HealInfect(client,target);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_MedicInfect = 
{
	name = "MedicInfect",
	file = "MedicInfect.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_MedicInfect_SetNTVOptional()
{
	MarkNativeAsOptional("ControlMedicInfect");
	MarkNativeAsOptional("SetMedicInfect");
	MarkNativeAsOptional("MedicInfect");
	MarkNativeAsOptional("HealInfect");
}
#endif
