/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: firemines.inc
 * Description: Native Interface to firemines
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _firemines_included
 #endinput
#endif
#define _firemines_included

/**
 * Assume control of the firemines plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the Firemines plugin.
 * @return		    	none
 */
native void ControlMines(bool plugin_only=true);

/**
 * Give a player one or more firemines to plant
 *
 * @param index 	Client index
 * @param number    Set to number of firemines to give the player. (-1 is unlimited)
 * @param per_spawn Set to number of firemines to give the player on each spawn. (-1 is unlimited)
 * @param maximum   Set to number of firemines allowed to be active. (-1 is plugin default)
 * @return			none
 */
native void GiveMines(int client, int number=1, int per_spawn=-1, int maximum=-1);

/**
 * Take a player's firemines away
 *
 * @param index 	Client index
 * @return			none
 */
native void TakeMines(int client);

/**
 * Adds or more firemines for the player to plant
 *
 * @param index 	Client index
 * @param number    Number of firemines to add.
 * @return			none
 */
native void AddMines(int client, int number=1);

/**
 * Subtracts or more firemines for the player to plant
 *
 * @param index 	Client index
 * @param number    Number of firemines to subtract.
 * @return			none
 */
native void SubMines(int client, int number=1);

/**
 * Returns how many firemines a player has (or is allowed).
 *
 * @param index 	Client index
 * @param allowed   Set to  true to return number allowed, otherwise
 * @return			returns number of remaining firemines.
 */
native int HasMines(int client, bool allowed=false);

/**
 * Counts how many mines the player has active.
 *
 * @param index 	Client index
 * @return			firemine count
 */
native int CountMines(int client);

/**
 * Sets (Plants) a firemine where the client is looking.
 *
 * @param index 	Client index
 * @param seeking 	Set true to have the mine seek enemies.
 * @return			entity
 */
native int SetMine(int client, bool seeking=false);

/**
 * Gets called when when a mine is set
 * @param client 	Client index of the player setting the mine
 */
forward Action OnSetMine(int client);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin __pl_firemines = 
{
	name = "firemines",
	file = "firemines.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_firemines_SetNTVOptional()
{
	MarkNativeAsOptional("ControlMines");
	MarkNativeAsOptional("CountMines");
	MarkNativeAsOptional("GiveMines");
	MarkNativeAsOptional("TakeMines");
	MarkNativeAsOptional("AddMines");
	MarkNativeAsOptional("SubMines");
	MarkNativeAsOptional("HasMines");
	MarkNativeAsOptional("SetMine");
}
#endif
