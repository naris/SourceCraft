
#if defined _tf2_included
 #endinput
#endif
#define _tf2_included

#define TF2_SCOUT 1
#define TF2_SNIPER 2
#define TF2_SOLDIER 3 
#define TF2_DEMOMAN 4
#define TF2_MEDIC 5
#define TF2_HEAVY 6
#define TF2_PYRO 7
#define TF2_SPY 8
#define TF2_ENG 9


/**
 * Changes the level of a turret, the sentry has to be build
 *
 * @param index 		Player ID or Sentry ID
 * @param level			Level to change to, 1-3
 * @return				0 = sucess, 
 *						2=builing state
 *						3=It is not a sentry
 *						4=Could not find sentry of Player ID
 *						5=Client not conneted
 *						6=not a valid level
 */
native TF_TurretLevel(index, level);

/**
 * Finds the turret the player is looking at
 *
 * @param index 		Finds by trace to what turrent the player is looking at
 * @return				Sentry id, 0 on failture
 */
native TF_EyeTurret(client);


/**
 * Get the class of the player
 *
 * @param index 		Client index
 * @return				class number	
 */
native TF_GetClass(client);

/**
 * Get the max health of the player
 *
 * @param index 		Client index
 * @return				Max health
 */
native TF_GetMaxHealth(client);

/**
 * Get client total score
 *
 * @param index 		Client index
 * @return				Total score	
 */
native TF_TotalScore(client);

/**
 * Return the CTFPlayerResource id
 *
 * @return				CTFPlayerResource id
 */
native TF_GetResource(client);