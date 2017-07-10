/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Sidewinder.inc
 * Description: Native Interface to Sidewinder plugin
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _sidewinder_included
 #endinput
#endif
#define _sidewinder_included

enum SidewinderEnableFlags (<<= 1)
{
    SidewinderDisabled = 0,      // Completly disable sidewinder
    SidewinderSentryRockets = 1, // Enable homing Sentry rockets
    SidewinderRockets,           // Enable homing Soldier rockets
    SidewinderEnergyBalls,       // Enable homing Soldier Cowmangler energy balls
    SidewinderEnergyRings,       // Enable homing Soldier Bison energy rings
    SidewinderPipes,             // Enable homing Demo pipe bombs
    SidewinderFlares,            // Enable homing Pyro flares
    SidewinderArrows,            // Enable homing Huntsman arrows
    SidewinderSyringes,          // Enable homing Medic syringes
    SidewinderBolts,             // Enable homing Medic crossbow bolts
    SidewinderBalls,             // Enable homing Scout sandman balls
    SidewinderWrapBalls,         // Enable homing Scout wrap assassin balls
    SidewinderJars,              // Enable homing Sniper jarate jars
    SidewinderMilk,              // Enable homing Scout milk jars
    SidewinderCleaver,           // Enable homing Scout Flying Guillotines (cleavers)
    SidewinderOther              // Enable homing projectiles other than those mentioned above (if any)
};

#define SidewinderEnable (SidewinderSentryRockets | SidewinderRockets   | SidewinderEnergyBalls | \
                          SidewinderEnergyRings   | SidewinderPipes     | SidewinderFlares      | \
                          SidewinderArrows        | SidewinderSyringes  | SidewinderBolts       | \
                          SidewinderBalls         | SidewinderWrapBalls | SidewinderJars        | \
                          SidewinderMilk          | SidewinderCleaver   | SidewinderOther)

enum SidewinderClientFlags (<<= 1)
{
    NoTracking = 0,	              // Check convars for projectile type

    TrackingSentryRockets=1,      // Track Sentry rockets
    TrackingRockets,              // Track Soldier rockets
    TrackingEnergyBalls,          // Track Soldier Cowmangler energy balls
    TrackingEnergyRings,          // Track Soldier Bison energy rings
    TrackingPipes,                // Track Demo pipe bombs
    TrackingFlares,               // Track Pyro flares
    TrackingArrows,               // Track Huntsman arrows
    TrackingSyringes,             // Track Medic syringes
    TrackingBolts,                // Track Medic crossbow bolts
    TrackingBalls,                // Track Scout sandman balls
    TrackingWrapBalls,            // Track Scout wrap assissin balls
    TrackingJars,                 // Track Sniper jarate jars
    TrackingMilk,                 // Track Scout milk jars
    TrackingCleaver,              // Track Scout Flying Guillotines (cleavers)

    TrackingAll,                  // Track all projectiles

    CritSentryRockets,            // Sentry can fire crit rockets
    TargetHeads,                  // Projectiles target heads

    TrackingClientIsDesignated,   // Client is "designated" as a target!
    TrackingClientIsCloaked,      // Client is "cloaked" and can not be seen by rockets.
    TrackingClientIsDetected,     // Client is "detected" and can be seen even if "cloaked".
};

#define TrackingClientStatus (TrackingClientIsDesignated | TrackingClientIsCloaked | TrackingClientIsDetected)

/**
 * Control the TF2Sidewinder plugin (disable global settings).
 *
 * @param control	            Set true to disable global settings and control the sidewinder extension.
 * @param enable                If control is false, value for sm_sidewinder_enabled
 * @param sentry_crit           If control is false, value for sm_sentryrocket_crit
 * @param sentry_track_crit     If control is false, value for sm_sentryrocket_crit_tracker
 * @param rocket_track_crit     If control is false, value for sm_rocket_crit_tracker
 * @param arrow_track_crit      If control is false, value for sm_arrow_crit_tracker
 * @param flare_track_crit      If control is false, value for sm_flare_crit_tracker
 * @param pipe_track_crit       If control is false, value for sm_pipe_crit_tracker
 * @param syringe_track_crit    If control is false, value for sm_syringe_crit_tracker
 * @noreturn
 */
native SidewinderControl(bool:control=true, bool:sentry_crit=false,
                         bool:track_crits=false, bool:target_head=false,
                         SidewinderEnableFlags:enable=SidewinderDisabled);

/**
 * Enable's Sidewinder rockets for the given client
 *
 * @param client	        The client's index you want.
 * @param flags		        Sidewinder flags to use for this client.
 * @param excludeStatusBits	Set true to also set the status bits
 *                          status bits == (cloaked, detected, designated)
 * @noreturn
 */
native SidewinderFlags(client, SidewinderClientFlags:flags, bool:setStatusBits=false);

/**
 * Sets chance that a rocket will track targets
 *
 * @param client	    The client's index you want.
 * @param normal_chance Chance each non-crit rocket will track targets.
 * @param crit_chance   Chance each crit rocket will track targets (default = same as normal_chance).
 * @noreturn
 */
native SidewinderTrackChance(client, normal_chance, crit_chance=-1);

/**
 * Sets Sidewinder sentry rocket crit chance for the given client
 *
 * @param client	The client's index you want.
 * @param chance    Change each sentry rocket will be a crit rocket.
 * @noreturn
 */
native SidewinderSentryCritChance(client, chance);

/**
 * Designate priority targets for guided rockets
 *
 * @param client	The client's index you want.
 * @param value     Set to true to designate the client as a priority target.
 * @noreturn
 */
native SidewinderDesignateClient(client, bool:value);

/**
 * Cloaks or uncloaks clients from guided rockets
 *
 * @param client	The client's index you want.
 * @param value     Set to true to cloak the target from rockets.
 * @noreturn
 */
native SidewinderCloakClient(client, bool:value);

/**
 * Detects or undetects clients for guided rockets
 *
 * @param client	The client's index you want.
 * @param value     Set to true to detect the target for rockets.
 * @noreturn
 */
native SidewinderDetectClient(client, bool:value);

/**
 * @brief Called whenever Sidewinder needs to query if a shot should be made a seeker
 *
 * @param client	    Index of the client firing the weapon.
 * @param target	    Index of the client that is the target being sought
 * @param projectile	Entity of the projectile being fired
 * @param critical      True if the projectile is critical.
 * @return			    Plugin_Stop or Plugin_Handled to block tracking.
 */
forward Action:OnSidewinderSeek(client, target, projectile, bool:critical);

/**
 * Do not edit below this line!
 */
public SharedPlugin:__pl_sidewinder = 
{
	name = "sidewinder",
	file = "sidewinder.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};


#if !defined REQUIRE_PLUGIN
public __pl_sidewinder_SetNTVOptional()
{
	MarkNativeAsOptional("SidewinderControl");
	MarkNativeAsOptional("SidewinderFlags");
	MarkNativeAsOptional("SidewinderTrackChance");
	MarkNativeAsOptional("SidewinderSentryCritChance");
	MarkNativeAsOptional("SidewinderDesignateClient");
	MarkNativeAsOptional("SidewinderCloakClient");
	MarkNativeAsOptional("SidewinderDetectClient");
}
#endif

