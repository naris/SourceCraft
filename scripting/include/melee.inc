#if defined _melee_included_
  #endinput
#endif
#define _melee_included_

/**
 * Set melee mode
 *
 * @param Enabled 	True or false, whether melee should be on or off.
 * @param Verbose   Print melee state when finished.
 * @return	none
 */
native SetMeleeMode(bool:bEnabled, bVerbose=true);

/**
 * Get melee mode
 *
 * @return	True or false, whether melee mode is enabled.
 */
native bool:GetMeleeMode();