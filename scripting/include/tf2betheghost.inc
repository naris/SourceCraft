#if defined _tf2btg_included
	#endinput
#endif
#define _tf2btg_included

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * @brief Is player - ghost?
 *
 * @param iClient		-
 *
 * @return				True or false
 **/
native bool:TF2BTG_IsPlayerGhost( iClient );

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Return Plugin_Handled or Plugin_Stop to prevent
 **/
forward Action:TF2BTG_CanPlayAsGhost( iClient );

/**
 * Return Plugin_Handled or Plugin_Stop to prevent
 **/
forward Action:TF2BTG_CanBeScared( iGhost, iClient );

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public SharedPlugin:__pl_tf2btg = 
{
	name = "tf2betheghost",
	file = "tf2betheghost.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#if !defined REQUIRE_PLUGIN
public __pl_tf2btg_SetNTVOptional()
{
	MarkNativeAsOptional("TF2BTG_IsPlayerGhost");
}
#endif