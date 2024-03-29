/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: ztf2nades.inc
 * Description: Native Interface to ztf2nades
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _ztf2nades_included
 #endinput
#endif
#define _ztf2nades_included


// *************************************************
// defines
// *************************************************

// Nade Types
enum NadeType
{
	DefaultNade = 0, // use class for nade type
	ConcNade,
	BearTrap,
	NailNade,
	MirvNade,
	HealthNade,
	HeavyNade,
	NapalmNade,
	HallucNade,
	EmpNade,
	Bomblet,
	SmokeNade,
	GasNade,
	TargetingDrone,
	FragNade
};

#if defined _ztf2nades_plugin
 #endinput
#endif

/**
 * Assume control of the ztf2nades plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of ztf2nades.
 * @param targetting 	Set to 1 to assume control of targetting.
 * @return		    	none
 */
native ControlNades(bool:plugin_only=true, bool:targetting=false);

/**
 * Give nades to the player
 *
 * @param client 	        Client index
 * @param frag              How many frag nades to give to the player
 * @param frag_per_spawn    How many frag nades to give to the player on each spawn
 * @param special           How many special nades to give to the player
 * @param special_per_spawn How many special nades to give to the player on each spawn
 * @param can_restock       Can the player restock at cabinets?
 * @param special_type      What type of nade is the special (default is use class to determine)
 * @param category          Optional SourceCraft Category to use in HurtPlayer()
 * @return		    	    none
 */
native GiveNades(client, frag=-1, frag_per_spawn=-1, special=-1, special_per_spawn=-1,
                 can_restock=false, NadeType:special_type=DefaultNade, category=0);

/**
 * Take the nades from the player
 *
 * @param client 	Client index
 * @return			none
 */
native TakeNades(client);

/**
 * Adds one or more frag nades for the player to use
 *
 * @param client 	Client index
 * @param number    Number of frag nades to add.
 * @param category  Optional SourceCraft Category to use in HurtPlayer()
 * @return			none
 */
native AddFragNades(client, number=1, category=0);

/**
 * Subtracts one or more frag nades for the player to use
 *
 * @param client 	Client index
 * @param number    Number of frag nades to add.
 * @return			none
 */
native SubFragNades(client, number=1);

/**
 * Returns how many frag nades a player has (or is allowed).
 *
 * @param index 	Client index
 * @param property  Set to 0 to return number of remaining frag nades,
 *                         1 to return number of frag nades allowed
 *                         2 to return category
 * @return			returns property specified above.
 */
native HasFragNades(client, property=0);

/**
 * Adds one or more special nades for the player to use
 *
 * @param client 	Client index
 * @param number    Number of special nades to add.
 * @param category  Optional SourceCraft Category to use in HurtPlayer()
 * @return			none
 */
native AddSpecialNades(client, number=1, category=0);

/**
 * Subtracts one or more special nades for the player to use
 *
 * @param client 	Client index
 * @param number    Number of special nades to add.
 * @return			none
 */
native SubSpecialNades(client, number=1);

/**
 * Returns how many special nades a player has (or is allowed).
 *
 * @param index 	Client index
 * @param property  Set to 0 to return number of remaining special nades,
 *                         1 to return number of special nades allowed
 *                         2 to return category
 * @return			returns property specified above.
 */
native HasSpecialNades(client, property=0);

/**
 * Throw a Frag nade
 *
 * @param client 	Client index
 * @param pressed   Set true when pressed, false when released
 * @return			none
 */
native ThrowFragNade(client, bool:pressed);

/**
 * Throw a Special nade
 *
 * @param client 	Client index
 * @param pressed   Set true when pressed, false when released
 * @return			none
 */
native ThrowSpecialNade(client, bool:pressed);

/**
 * Damage Buildings in range of an attack
 *
 * @param attacker 	Client index of attacker
 * @param start     Starting Location
 * @param start     radius of damage
 * @param damage    amount of damage
 * @param ent       Entity doing damage
 * @param trace     Set true to check using trace
 * @return			none
 */
native DamageBuildings(attacker, Float:start[3], Float:radius, damage, ent, bool:trace);

/**
 * Always throw specified type of nade, does NOT alter remaining count.
 *
 * @param client 	Client index
 * @param pressed   Set true when pressed, false when released
 * @param type      Type of nade to throw
 * @return			none
 */
native ThrowNade(client, bool:pressed, NadeType:type=DefaultNade);

/**
 * Returns if a player has been targetted by the targetting drone
 *
 * @param index 	Client index
 * @return			returns true if the client has been targetted
 */
native IsTargeted(client);

/**
 * Gets called when when a grenade explodes
 * @param victim:   The index of the victim of the nade
 * @param attacker:	Client index of the player that threw the nade
 * @param damage:   The damage to be done to the victim, can be changed.
 * @param type      The type of nade
 * @param pos 	    The location of the nade
 */
forward Action:OnNadeExplode(victim, attacker, &damage, NadeType:type, const Float:pos[3]);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_ztf2nades = 
{
	name = "ztf2nades",
	file = "ztf2nades.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ztf2nades_SetNTVOptional()
{
	MarkNativeAsOptional("ControlNades");
	MarkNativeAsOptional("AddFragNades");
	MarkNativeAsOptional("SubFragNades");
	MarkNativeAsOptional("HasFragNades");
	MarkNativeAsOptional("ThrowFragNade");
	MarkNativeAsOptional("AddSpecialNades");
	MarkNativeAsOptional("SubSpecialNades");
	MarkNativeAsOptional("HasSpecialNades");
	MarkNativeAsOptional("ThrowSpecialNade");
	MarkNativeAsOptional("DamageBuildings");
	MarkNativeAsOptional("IsTargeted");
	MarkNativeAsOptional("GiveNades");
	MarkNativeAsOptional("TakeNades");
	MarkNativeAsOptional("ThrowNade");
}
#endif
