/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: rollermine.inc
 * Description: Native Interface to rollermine
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _rollermine_included
 #endinput
#endif
#define _rollermine_included

// settings for damage (m_takedamage)
#if !defined(DAMAGE_NO)
#define DAMAGE_NO               0
#define DAMAGE_EVENTS_ONLY      1       // Call damage functions, but don't modify health
#define DAMAGE_YES              2
#define DAMAGE_AIM              3
#endif

/**
 * Assume control of the rollermine plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the rollermine plugin.
 * @return		    	none
 */
native void ControlRM(bool plugin_only=true);

/**
 * Sets (Plants) a rollermine where the client is looking.
 *
 * @param index 	Client index
 * @return			entity
 */
native int SetRollermine(int client, int takeDamage=DAMAGE_YES, int health=100,
						 float damageDelay=2.0, int explodeDamage=160,
						 int explodeRadius=250, float lifetime=0.0);

/**
 * Spawns a rollermine.
 *
 * @param index 	Client index
 * @param pos    	Position to spawn the rollermine at.
 * @return			entity
 */
native int SpawnRollerMine(int client, float pos[3], int takeDamage=DAMAGE_YES,
						   int health=100, float damageDelay=0.0,
						   int explodeDamage=160, int explodeRadius=250,
						   float lifetime=0.0);

/**
 * Counts how many mines the player has active.
 *
 * @param index 	Client index
 * @return			firemine count
 */
native int CountRollermines(int client=0);

/**
 * Counts how many mines the player has active.
 *
 * @param index 	Client index
 * @return			firemine count
 */
native int ExplodeRollermines(int client=0);

/**
 * Gets called when when a rollermine is set
 * @param client 	Client index of the player setting the rollermine
 */
forward Action OnSetRollermine(int client);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin __pl_rollermine = 
{
	name = "rollermine",
	file = "rollermine.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_rollermine_SetNTVOptional()
{
	MarkNativeAsOptional("ControlRM");
	MarkNativeAsOptional("SetRollermine");
	MarkNativeAsOptional("SpawnRollerMine");
	MarkNativeAsOptional("CountRollermines");
	MarkNativeAsOptional("ExplodeRollermines");
}
#endif
