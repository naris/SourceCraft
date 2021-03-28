#if defined _AdvancedInfiniteAmmo_included
  #endinput
#endif
#define _AdvancedInfiniteAmmo_included

#define AMMOFLAG_NONE			0
#define AMMOFLAG_CLIP			(1 << 0)
#define AMMOFLAG_AMMO			(1 << 1) 
#define AMMOFLAG_EXTRA			(1 << 2)
#define AMMOFLAG_METAL			(1 << 3)
#define AMMOFLAG_SENTRY			(1 << 4)
#define AMMOFLAG_CLOAK			(1 << 5)
#define AMMOFLAG_SPELLS			(1 << 6)
#define AMMOFLAG_ALL			AMMOFLAG_CLIP|AMMOFLAG_AMMO|AMMOFLAG_EXTRA|AMMOFLAG_METAL|AMMOFLAG_SENTRY|AMMOFLAG_CLOAK|AMMOFLAG_SPELLS

#define AMMOSOURCE_NONE				0
#define AMMOSOURCE_COMMAND			(1 << 0)
#define AMMOSOURCE_TIMER			(1 << 1)  
#define AMMOSOURCE_CVAR_ALL			(1 << 2) 
#define AMMOSOURCE_CVAR_ROUNDWIN		(1 << 3) 
#define AMMOSOURCE_CVAR_WAITINGFORPLAYERS	(1 << 4)
#define AMMOSOURCE_PLUGIN			(1 << 5)
 
/**
 * Check if player has Advanced Infinite Ammo active
 *
 * @param client		Player's index.
 * @return        		True if player has AIA, else false
 * @error			Invalid Client index
 */
native bool AIA_HasAIA(int client);

/**
 * Set Advanced Infinite Ammo On player
 *
 * @param client		Player's index.
 * @param onoff			True to enable AIA on player, false to disable.
 * @param time      How many seconds to enable infinite ammo (0.0 == forever)
 * @noreturn
 * @error			Invalid Client index
 */
native void AIA_SetAIA(int client, bool onoff, float time=0.0);

/**
 * Get player's current ammo flag bits
 *
 * @param client		Player's index.
 * @return        		Current ammo flag bits
 * @error			Invalid Client index
 */
native int AIA_GetAmmoFlags(int client);

/**
 * Set player's current ammo flag bits
 *
 * @param client		Player's index.
 * @param flags			Flag bits to change.
 * @param onoff			True to add flags, false to remove them.
 * @noreturn
 * @error			Invalid Client index
 */
native int AIA_SetAmmoFlags(int client, int flags, bool onoff);

/**
 * Fired when AIA is enabled/disabled on player
 *
 * @param client		Player's index.
 * @param flags			Flag bits being added or removed
 * @param onoff			True if flags being added, false if being removed
 * @noreturn
 */
forward void AIA_OnAIAChanged(int client, int flags, bool onoff);

/**
 * Assume control of the AdvancedInfiniteAmmo plugin
 *
 * @param plugin_only 	Set to 1 to assume complete control of the AdvancedInfiniteAmmo plugin.
 * @param announce	 	Set to 1 to show Advanced Infinite Ammo changes in chat.
 * @return		    	none
 */
native AIA_Control(bool:plugin_only=true, bool:announce=false);

/**
 * Give a player ammo for the weapon in a slot
 *
 * @param index 	Client index
 * @param slot    Slot of the weapon to provide ammo for (-1 for active weapon)
 * @return			none
 */
native AIA_FillAmmo(client,slot=-1);

/**
 * Give a player ammo for a weapon
 *
 * @param index 	Client index
 * @param weapon  Weapon to provide ammo for
 * @return			none
 */
native AIA_FillWeaponAmmo(client,weapon);
