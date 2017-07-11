#if defined _tf2bte_included
	#endinput
#endif
#define _tf2bte_included

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * @brief Is player - eyeboss?
 *
 * @param iClient		-
 *
 * @return				True or false
 **/
native bool:TF2BTE_IsPlayerEye( iClient );

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Return Plugin_Handled or Plugin_Stop to prevent.
 **/
forward Action:TF2BTE_CanPlayAsEye( iClient );

/**
 * Cannot be prevented.
 **/
forward TF2BTE_OnEyeStunned( iEye, iAttacker );

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public SharedPlugin:__pl_tf2bte = 
{
	name = "tf2betheeye",
	file = "tf2betheeye.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#if !defined REQUIRE_PLUGIN
public __pl_tf2bte_SetNTVOptional()
{
	MarkNativeAsOptional("TF2BTG_IsPlayerEye");
}
#endif