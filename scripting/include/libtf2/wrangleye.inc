/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: wrangleye.inc
 * Description: Native Interface to Wrangle Monoculus (Eye)
 * Author(s): FlaminSarge (based on Naris's work)
 */

#if defined _wrangleye_included
 #endinput
#endif
#define _wrangleye_included

/**
 * Wrangle the Monoculus to look where the client is looking
 *
 * @param client    Client index
 * @param force     Set to true to force wrangling even if someone else already is.
 * @return          Returns Plugin_Handled if a Monoculus was wrangled successfully.
 */
native Action:TF2_WrangleMonoculus(client, bool:force=false);

/**
 * Assume control of this plugin
 *
 * @param plugin_only   Set to 1 to assume control and disable admin functions.
 * @return              none
 */
native ControlWrangleMonoculus(bool:plugin_only=true);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_wrangleye = 
{
    name = "wrangleye",
    file = "wrangleye.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_wrangleye_SetNTVOptional()
{
    MarkNativeAsOptional("TF2_WrangleMonoculus");
    MarkNativeAsOptional("ControlWrangleMonoculus");
}
#endif
