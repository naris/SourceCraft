/*
 * fairteambalancer.sp
 * 
 * Description:
 *	Keeps teams the same size and strength
 * 
 * Versions:
 *	2.7.1
 *		* Added support for SourceMod.
 *		* Attempts to balance levels in addition to frags.
 *	2.7
 *		* Plugins waits 15 minutes before a player is switched again
 *	2.6
 *		* Teams are no longer checked periodically or on certain events, but whenever a
 *		  player dies
 *		* threshold: if player's score - the needed score <= threshold, switch
 *	2.5.2
 *		* Bugfix: plugin actually does something again
 *	2.5.1
 *		* Team balance info is shown the cool way(tm) in TF2
 *		* Admins are only immune when they have a certain flag
 *	2.5
 *		* Added defines for the event hooks and chat messages
 *		* Timer interval can be changed via CVar
 *	2.4.1
 *		* Specs were counted, causing an "array index out of bounds" error
 *	2.4
 *		* Typo: Only Admins were switched
 *		* Clients are switched one second after they died
 *	2.3
 *		* Timer
 *	2.2
 *		* Changed hooks for TF2 and DoD:S to better resemble gameplay
 *	2.1
 *		* Some bugfixes
 *	2.0
 *		* Changed by MistaGee to take team strengths into account
 *	1.0
 *		* Initial Release by dalto:
 *		  http://forums.alliedmods.net/showthread.php?p=519837
 *
 * Credits:
 *	* dalto for making the original plugin
 *	* Extreme_One, StevenT, lambdacore, ThatGuy, CrimsonGT and everyone else who helped testing
 *
 */


#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include "sc/SourceCraft"
#define REQUIRE_PLUGIN

#pragma semicolon 1


// Admin level that makes players immune
#define ADMINFLAG Admin_Cheats

#define PLUGIN_VERSION "2.7.1"

// Wait time before a player is switched again
#define SWITCH_WAIT_TIME (60*15)

#define TEAM_1 2
#define TEAM_2 3

stock abs( a )   return ( a >= 0 ? a : -a );
stock max( a,b ) return ( a > b  ? a :  b );
stock min( a,b ) return ( a < b  ? a :  b );


// Plugin definitions
public Plugin:myinfo =
{
	name			= "Fair Team Balancer",
	author			= "MistaGee",
	description		= "Keeps teams the same size and strength",
	version			= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net"
};

new Handle:cvarEnabled		= INVALID_HANDLE,
    Handle:cvarThreshold	= INVALID_HANDLE,
    Handle:cvarLevelThreshold	= INVALID_HANDLE,
    biggerTeam			= 0,
    clientLastSwitched[MAXPLAYERS],
    dCount			= 0,
    bool:game_is_tf2		= false,
    switches_pending		= 0,
    bool:cstrikeExtAvail	= false,
    bool:sourcecraftModAvail	= false,
    plID[MAXPLAYERS];				// Player IDs of players to be switched


public OnPluginStart(){
	cvarEnabled = CreateConVar(
		"sm_team_balancer_enable",
		"1",
		"Enables the Team Balancer plugin"
		);

	CreateConVar(
		"sm_team_balancer_version",
		PLUGIN_VERSION,
		"Team Balancer Version",
		FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY
		);
	
	cvarThreshold = CreateConVar(
		"sm_team_balancer_threshold",
		"3",
		"Maximum score difference for players to be switched",
		FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY
		);
	
	cvarLevelThreshold = CreateConVar(
		"sm_team_balancer_level_threshold",
		"3",
		"Maximum level difference for players to be switched",
		FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY
		);
	
	RegAdminCmd( "sm_teams", Command_Teams, ADMFLAG_KICK, "Balance teams" );
	
	decl String:theFolder[40];
	GetGameFolderName( theFolder, sizeof(theFolder) );
	
	game_is_tf2 = StrEqual( theFolder, "tf" );
	
	// Death event is always needed in order for the actual switching to happen
	HookEvent( "player_death",			Event_PlayerDeath );
	
	// Check for cstrike extension - if available, CS_SwitchTeam is used
	cstrikeExtAvail = ( GetExtensionFileStatus( "game.cstrike.ext" ) == 1 );

	// Check for sourcecraft mod.
	sourcecraftModAvail = LibraryExists( "sourcecraft" );
	
	}

public Action:Command_Teams( client, args ){
	PerformTeamCheck( true );
	return Plugin_Handled;
	}

void:PerformTeamCheck( bool:switchImmed = false ){
	// If we are disabled - exit
	if( !GetConVarBool(cvarEnabled) )
		return;
	
	// Count the size and frags of each team
	new tPlayers[2] = { 0, 0 },
	    tFrags[2]   = { 0, 0 },
	    tLevels[2]  = { 0, 0 },
	    mc          = GetMaxClients(),
	    Handle:pHandle,
	    cTeam;
	
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) ){
			cTeam = GetClientTeam(i);
			// Thanks to lambdacore for the hint
			if( cTeam < 2 ){
				continue;
				}
			tPlayers[ cTeam-2 ]++;
			tFrags[ cTeam-2 ] += GetClientFrags(i);
			if( sourcecraftModAvail ){
				pHandle = GetPlayerHandle(i);
				if (pHandle != INVALID_HANDLE){
					tLevels[ cTeam-2] += GetOverallLevel(pHandle);
					}
				}
			}
		}
	
	// Calc score difference, div by player count difference
	// eg: if T1 has 6 players and 12 Frags, and T2 has 8 players and 16 frags,
	// player diff is 2 and frag diff is 4. That means, we need to switch 1 player (diff/2),
	// who has 2 frags ((diff/2)/players).
	
	dCount = abs(tPlayers[0]-tPlayers[1]) / 2;
	new dScore = ( abs(tFrags[0]-tFrags[1]) / 2 ) / max( dCount, 1 );
	new dLevel = ( abs(tLevels[0]-tLevels[1]) / 2 ) / max( dCount, 1 );
	
	if( dCount == 0  && dLevel == 0 ){
		return;
		}
	
	// Purge the ID array
	for( new n = 0; n < MAXPLAYERS; n++ ){
		plID[n] = 0;
		}
	
	biggerTeam = ( tPlayers[0] > tPlayers[1] ? TEAM_1 : TEAM_2 );
	
	// Find the player(s) who fit best for team change
	// these are those n who come closest to the needed frag count
	
	new plScoreDelta[MAXPLAYERS],	// Difference of players' score to dScore
	    plLevelDelta[MAXPLAYERS],	// Difference of players' level to dLevel
	    plFragDelta,
	    plLvlDelta,
	    AdminId:plAdminID;
	
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) &&
		    GetClientTeam(i) == biggerTeam &&		// Switch people from bigger team
		    ( ( plAdminID = GetUserAdmin(i) ) == INVALID_ADMIN_ID ||// Who are not admins or...
		      !GetAdminFlag( plAdminID, ADMINFLAG )	// ...not immune
		    )
		  ){
			plFragDelta = abs( GetClientFrags(i) - dScore );
			if( sourcecraftModAvail ){
				pHandle = GetPlayerHandle(i);
				if (pHandle != INVALID_HANDLE){
					plLvlDelta = abs( GetOverallLevel(pHandle) - dLevel );
					}
				}

			// Iterate through first n slots of array
			for( new s = 0; s < dCount; s++ ){
				// if no player found or difference bigger
				if( plID[s] == 0 || plScoreDelta[s] > plFragDelta  || plLevelDelta[s] > plLvlDelta  ){
					plID[s] = i;
					plScoreDelta[s] = plFragDelta;
					plLevelDelta[s] = plLvlDelta;
					}
				}
			}
		}
	
	PrintToChatAll( "[SM] Balancing teams in size and strength, switching %d players.", dCount );
	
	// Now we found the players to switch, so maybe do it
	if( switchImmed ){
		for( new s = 0; s < dCount; s++ ){
			PerformSwitch( plID[s] );
			plID[s] = 0;
			}
		PrintToServer(  "[SM] Teams have been balanced." );
		}
	else{
		// We're not to switch immediately, but maybe some of the players we want to
		// switch are already dead, so don't wait for them to die again
		for( new s = 0; s < dCount; s++ ){
			if( IsPlayerAlive( plID[s] ) )
				continue;
			
			PerformSwitch( plID[s] );
			plID[s] = 0;
			}
		}
	}

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast ){
	// If we are disabled - exit
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) ),
	    AdminId:plAdminID = GetUserAdmin(client);
	
	if( !GetConVarBool(cvarEnabled) ||
	    ( plAdminID != INVALID_ADMIN_ID && GetAdminFlag( plAdminID, ADMINFLAG ) )
	  )
		return;
	
	// Count the size and frags of each team
	new tPlayers[2] = { 0, 0 },
	    tFrags[2]   = { 0, 0 },
	    tLevels[2]  = { 0, 0 },
	    mc          = GetMaxClients(),
	    plLvlDelta	= -1,
	    Handle:pHandle,
	    cTeam;
	
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) ){
			cTeam = GetClientTeam(i);
			// Thanks to lambdacore for the hint
			if( cTeam < 2 )
				continue;
			tPlayers[ cTeam-2 ]++;
			tFrags[ cTeam-2 ] += GetClientFrags(i);
			if( sourcecraftModAvail ){
				pHandle = GetPlayerHandle(i);
				if (pHandle != INVALID_HANDLE){
					tLevels[ cTeam-2] += GetOverallLevel(pHandle);
					}
				}
			}
		}
	
	// Calc score difference, div by player count difference
	// eg: if T1 has 6 players and 12 Frags, and T2 has 8 players and 16 frags,
	// player diff is 2 and frag diff is 4. That means, we need to switch 1 player (diff/2),
	// who has 2 frags ((diff/2)/players).
	
	dCount = max( ( abs(tPlayers[0]-tPlayers[1]) / 2 ) - switches_pending, 0 );
	new dScore = ( abs(tFrags[0]-tFrags[1]) / 2 ) / max( dCount, 1 );
	new dLevel = ( abs(tLevels[0]-tLevels[1]) / 2 ) / max( dCount, 1 );
	
	if( dCount == 0  && dLevel == 0 ){
		return;
		}
	
	biggerTeam = ( tPlayers[0] > tPlayers[1] ? TEAM_1 : TEAM_2 );
	
	// Check for correct Team and last time user was switched
	if( GetClientTeam(client) != biggerTeam ||
	    GetTime() - clientLastSwitched[client] < SWITCH_WAIT_TIME
	  )
		return;

	// Get the player's level for sourcecraft
	if( sourcecraftModAvail ){
		pHandle = GetPlayerHandle(client);
		if (pHandle != INVALID_HANDLE){
			plLvlDelta = abs( GetOverallLevel(pHandle) - dLevel );
			}
		}

	// If the guy has the score or level we need, switch them and be done
	if( abs( GetClientFrags(client) - dScore ) <= GetConVarInt(cvarThreshold) ||
	    (plLvlDelta >= 0 && plLvlDelta <= GetConVarInt(cvarLevelThreshold))){
		PerformTimedSwitch( client );
		clientLastSwitched[client] = GetTime();
		}
	}

public OnClientDisconnect_Post( client ){
	clientLastSwitched[client] = 0;
	}

void:PerformTimedSwitch( client ){
	CreateTimer( 0.5, Timer_TeamSwitch, client );
	switches_pending++;
	}

public Action:Timer_TeamSwitch( Handle:timer, any:client ){
	if( !IsClientInGame( client ) )
		return Plugin_Stop;
	
	switches_pending--;
	
	// Maybe the player already switched?
	if( GetClientTeam( client ) == biggerTeam ){
		PerformSwitch( client );
		}
	
	return Plugin_Stop;
	}

void:PerformSwitch( client ){
	if( cstrikeExtAvail )
		CS_SwitchTeam( client, 5 - biggerTeam );
	else
		ChangeClientTeam( client, 5 - biggerTeam );
	
	LogAction(0, client, "[SM] %N has been switched for team balance.", client );

	if( game_is_tf2 ){
		new Handle:event = CreateEvent( "teamplay_teambalanced_player" );
		SetEventInt( event, "player", client         );
		SetEventInt( event, "team",   5 - biggerTeam );
		FireEvent( event );
		}
	else{
		PrintToChatAll( "[SM] %N has been switched for team balance.", client );
		}
	}
