/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: burrow.inc
 * Description: The Zerg Burrow upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _burrow_included
 #endinput
#endif
#define _burrow_included

#define BURROW_OWN_STRUCTURES   0
#define BURROW_TEAM_STRUCTURES  1
#define BURROW_ANY_STRUCTURE    2

#define BURROWED_COMPLETELY     4

/**
 * Add the Zerg Burrow upgrade to a race.
 *
 * @param raceId 	        Race to add Borrow to.
 * @param category:         Ultimate Category to use. (default is 2)
 * @param required_level:   Level required to upgrade Bunker. (default is 6)
 * @param max_level:        Max Burrow levels to allow for this race [1-4]. (default is 1)
 * @param start_level:      Level to start Burrow at[0-4]. (default is 0, burrow has to be upgraded to be used)
 *                          Levels allow: (1=strip weapons/prevent attack, 2=attack unburrows, 3=attack unburrows instantly, 4=unlimited attack - for Bunkers)
 * @param energy:           Amount of energy required to invoke upgrade. (default is 30)
 * @param cooldown:         Duration of the cooldown. (default is 5.0)
 * @param cost_crystals:    Amount of crystals required to purchase upgrade for 1 map. (default is 10)
 * @return                  The return value will be the upgrade index or -1 if there was a problem.
 */
stock AddBurrowUpgrade(raceId, category=2, required_level=6, max_level=1, start_level=0, cost_crystals=10)
{
    AdditionalTranslations("sc.burrow.phrases.txt");

    decl String:desc[NAME_STRING_LENGTH];
    if (max_level >= start_level && start_level > 0 && start_level < 3)
        Format(desc, sizeof(desc), "%%burrow_%d.%d", start_level, max_level);
    else
        Format(desc, sizeof(desc), "%%burrow_%d", max_level);

    return AddUpgrade(raceId, "burrow", category, required_level, max_level-start_level,
                      .desc=desc, .cost_crystals=cost_crystals,
                      .name="%Burrow", .image="%burrow_image");
}

/**
 * Starts burrowing, or unburrowing, a player depending on
 * if they are already burrowed
 *
 * @param client 	Client
 * @param level:    The level the client has in burrow
 *                  (1=strip weapons, 2=prevent attack, 3=allow attack, 4=unlimited attack - for Bunkers)
 * @param depth:    The maximum depth to burrow to
 *                  (4 is fully burrowed, 2 is 1/2 burrowed - for Bunkers)
 * @param armor:    The amount of additional armor provided (if any) - for Bunkers.
 * @param name:     What to call the additional armor in the HUD and messages - for Bunkers.
 * @return			Retruns true if the player succeeded in burrowing.
 */
native bool:Burrow(client, level, depth=4, armor=0, const String:name[]="");

/**
 * Starts unburrowing, a player if they are burrowed.
 *
 * @param client 	Client
 * @return			none
 */
native UnBurrow(client);

/**
 * Returns true if the entity or client is Burrowed.
 *
 * @param entity 	Entity (or client)
 * @return			4 if the entity is burrowed, 1-3 if the entity is burrowing
 *                  and -1 if the entity is being respawned by Burrow()
 */
native IsBurrowed(entity);

/**
 * Reset a Burrowed Player.
 *
 * @param client 	Client
 * @param unborrow  Starts Unburrowing the player if true, instantly resets burrow if false.
 * @return			none
 */
native ResetBurrow(client, bool:unburrow=false);

/**
 * Starts burrowing, or unburrowing, one or more structures that belong
 * to a particular client depending on if they are already burrowed
 *
 * @param client 	Client
 * @param amount 	Amount of energy required to Burrow one Structure.
 * @param flags 	Flags that indicate whose buildings can be burrowed (Own, Team or Any).
 * @return			none
 */
native BurrowStructure(client, Float:amount, flags=BURROW_OWN_STRUCTURES);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_Burrow = 
{
	name = "Burrow",
	file = "Burrow.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_Burrow_SetNTVOptional()
{
	MarkNativeAsOptional("Burrow");
	MarkNativeAsOptional("UnBurrow");
	MarkNativeAsOptional("IsBurrowed");
	MarkNativeAsOptional("ResetBurrow");
	MarkNativeAsOptional("BurrowStructure");
}
#endif
