/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_optional.inc
 * Description: Makes all the TF2 natives optional.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _tf2_optional_included
 #endinput
#endif
#define _tf2_optional_included

#include <tf2>

#if !defined REQUIRE_EXTENSIONS
public __ext_tf2_SetNTVOptional()
{
	MarkNativeAsOptional("TF2_IgnitePlayer");
	MarkNativeAsOptional("TF2_RespawnPlayer");
	MarkNativeAsOptional("TF2_RegeneratePlayer");
	MarkNativeAsOptional("TF2_AddCondition");
	MarkNativeAsOptional("TF2_RemoveCondition");
	MarkNativeAsOptional("TF2_SetPlayerPowerPlay");
	MarkNativeAsOptional("TF2_DisguisePlayer");
	MarkNativeAsOptional("TF2_RemovePlayerDisguise");
	MarkNativeAsOptional("TF2_StunPlayer");
	MarkNativeAsOptional("TF2_GetResourceEntity");
	MarkNativeAsOptional("TF2_GetClass");
}
#endif
