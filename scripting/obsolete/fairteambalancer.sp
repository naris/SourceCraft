/*
 * vim: set ai et ts=4 sw=4 :
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
#include <tf2_stocks>
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

new Handle:cvarEnabled		    = INVALID_HANDLE,
    Handle:cvarAdminsImmune	    = INVALID_HANDLE,
    Handle:cvarThreshold	    = INVALID_HANDLE,
    Handle:cvarScoreThreshold	= INVALID_HANDLE,
    Handle:cvarLevelThreshold	= INVALID_HANDLE,
    biggerTeam			        = 0,
    dCount			            = 0,
    switches_pending		    = 0,
    bool:game_is_tf2		    = false,
    bool:tf2ExtAvail	        = false,
    bool:cstrikeExtAvail	    = false,
    bool:sourcecraftModAvail	= false,
    clientLastSwitched[MAXPLAYERS],
    plID[MAXPLAYERS];				// Player IDs of players to be switched


public OnPluginStart()
{
    cvarEnabled = CreateConVar(
            "sm_team_balancer_enable",
            "0",
            "Enables the Team Balancer plugin"
            );

    CreateConVar(
            "sm_team_balancer_version",
            PLUGIN_VERSION,
            "Team Balancer Version",
            FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY
            );

    cvarAdminsImmune = CreateConVar(
            "sm_team_balancer_admins_immune",
            "0",
            "Set true to make admins immune ot balancing"
            );

    cvarThreshold = CreateConVar(
            "sm_team_balancer_threshold",
            "3",
            "Maximum frag difference for players to be switched",
            FCVAR_PLUGIN
            );

    cvarScoreThreshold = CreateConVar(
            "sm_team_balancer_score_threshold",
            "5",
            "Maximum score difference for players to be switched",
            FCVAR_PLUGIN
            );

    cvarLevelThreshold = CreateConVar(
            "sm_team_balancer_level_threshold",
            "8",
            "Maximum level difference for players to be switched",
            FCVAR_PLUGIN
            );

    RegAdminCmd( "sm_teams", Command_Teams, ADMFLAG_KICK, "Balance teams" );

    decl String:theFolder[40];
    GetGameFolderName( theFolder, sizeof(theFolder) );

    game_is_tf2 = StrEqual( theFolder, "tf" );

    // Check for cstrike extension - if available, CS_SwitchTeam() is used
    cstrikeExtAvail = ( GetExtensionFileStatus( "game.cstrike.ext" ) == 1 );

    // Check for tf2 extension - if available, TF2_GetPlayerResourceData() is used.
    tf2ExtAvail = ( GetExtensionFileStatus( "game.tf2.ext" ) == 1 );

    // Check for sourcecraft mod - if available, GetOverallLevel() is used.
    sourcecraftModAvail = LibraryExists( "sourcecraft" );

    // Death event is always needed in order for the actual switching to happen
    HookEvent( "player_death", Event_PlayerDeath );

    if (game_is_tf2)
    {
        HookEventEx("teamplay_round_win",Event_RoundWin);
        HookEventEx("teamplay_round_stalemate",Event_RoundOver);
        HookEventEx("teamplay_win_panel",Event_GameWin);
    }
}

public Action:Command_Teams( client, args )
{
    PerformTeamCheck( true );
    return Plugin_Handled;
}

void:PerformTeamCheck( bool:switchImmed = false )
{
    // If we are disabled - exit
    if( !GetConVarBool(cvarEnabled) )
        return;

    // Count the size and frags of each team
    new tPlayers[2] = { 0, 0 },
        tFrags[2]   = { 0, 0 },
        tScore[2]   = { 0, 0 },
        tLevels[2]  = { 0, 0 },
        tFragsLo[2] = { 0, 0 },
        tFragsHi[2] = { 0, 0 },
        tScoreLo[2] = { 0, 0 },
        tScoreHi[2] = { 0, 0 },
        tLevelLo[2] = { 0, 0 },
        tLevelHi[2] = { 0, 0 },
        pFrags[MAXPLAYERS] = { 0, ... },
        pScore[MAXPLAYERS] = { 0, ... },
        pLevel[MAXPLAYERS] = { 0, ... },
        cTeam;

    for( new i = 1; i < MaxClients; i++ )
    {
        if( IsClientInGame(i) )
        {
            cTeam = GetClientTeam(i);
            // Thanks to lambdacore for the hint
            if( cTeam >= 2 )
            {
                new t =cTeam-2;
                tPlayers[t]++;
                tFrags[t] += (pFrags[i] = GetClientFrags(i));
                if (tFragsLo[t] > pFrags[i])
                    tFragsLo[t] = i;
                if (tFragsHi[t] < pFrags[i])
                    tFragsHi[t] = i;

                if (tf2ExtAvail)
                {
                    tScore[t] += (pScore[i] = TF2_GetPlayerResourceData(i,TFResource_Score));
                    if (tScoreLo[t] > pFrags[i])
                        tScoreLo[t] = i;
                    if (tScoreHi[t] < pFrags[i])
                        tScoreHi[t] = i;
                }

                if (sourcecraftModAvail)
                {
                    tLevels[t] += (pLevel[i] = GetOverallLevel(i));
                    if (tLevelLo[t] > pLevel[i])
                        tLevelLo[t] = i;
                    if (tLevelHi[t] < pLevel[i])
                        tLevelHi[t] = i;
                }
            }
        }
    }

    // Calc score difference, div by player count difference
    // eg: if T1 has 6 players and 12 Frags, and T2 has 8 players and 16 frags,
    // player diff is 2 and frag diff is 4. That means, we need to switch 1 player (diff/2),
    // who has 2 frags ((diff/2)/players).

    dCount = abs(tPlayers[0]-tPlayers[1]) / 2;
    new dFrags = ( abs(tFrags[0]-tFrags[1]) / 2 ) / max( dCount, 1 );
    new dScore = ( abs(tScore[0]-tScore[1]) / 2 ) / max( dCount, 1 );
    new dLevel = ( abs(tLevels[0]-tLevels[1]) / 2 ) / max( dCount, 1 );

    if( dCount == 0  && dFrags == 0 && dScore == 0 && dLevel == 0 )
        return;

    // Purge the ID array
    for( new n = 0; n < MAXPLAYERS; n++ )
        plID[n] = 0;

    // Check team sizes and comparative score/levels/frags
    if (tPlayers[0] == tPlayers[1])
    {
        if (tScore[0] == tScore[1])
        {
            if (tLevels[0] == tLevels[1])
            {
                if (tFrags[0] == tFrags[1])
                    return;
                else
                    biggerTeam = ( tFrags[0] > tFrags[1] ? TEAM_1 : TEAM_2 );
            }
            else
                biggerTeam = ( tLevels[0] > tLevels[1] ? TEAM_1 : TEAM_2 );
        }
        else
            biggerTeam = ( tScore[0] > tScore[1] ? TEAM_1 : TEAM_2 );
    }
    else
        biggerTeam = ( tPlayers[0] > tPlayers[1] ? TEAM_1 : TEAM_2 );

    // Find the player(s) who fit best for team change
    // these are those n who come closest to the needed frag count

    new plFragDelta[MAXPLAYERS],	// Difference of players' frags to dFrags
        plScoreDelta[MAXPLAYERS],	// Difference of players' level to dScore
        plLevelDelta[MAXPLAYERS],	// Difference of players' level to dLevel
        fragDelta,
        scoreDelta,
        levelDelta,
        AdminId:plAdminID;

    for( new i = 1; i < MaxClients; i++ )
    {

        // Switch people from bigger team
        if (IsClientInGame(i) && GetClientTeam(i) == biggerTeam)
        {
            // Skip Admins if they are immune
            if (GetConVarBool(cvarAdminsImmune) &&
                plAdminID != INVALID_ADMIN_ID &&
                GetAdminFlag(plAdminID, ADMINFLAG))
            {
                continue;
            }

            fragDelta  = abs( pFrags[i] - dFrags );
            scoreDelta = abs( pScore[i] - dScore );
            levelDelta = abs( pLevel[i] - dLevel );

            // Iterate through first n slots of array
            for (new s = 0; s < dCount; s++ )
            {
                // if no player found or difference bigger
                if (plID[s] == 0 || (plFragDelta[s] > fragDelta &&
                                     plScoreDelta[s] > scoreDelta &&
                                     plLevelDelta[s] > levelDelta))
                {
                    plID[s] = i;
                    plFragDelta[s]  = fragDelta;
                    plScoreDelta[s] = scoreDelta;
                    plLevelDelta[s] = levelDelta;
                }
            }
        }
    }

    PrintToChatAll( "[SM] Balancing teams in size and strength, switching %d players.", dCount );

    // Now we found the players to switch, so maybe do it
    if( switchImmed )
    {
        for( new s = 0; s < dCount; s++ )
        {
            PerformSwitch( plID[s] );
            plID[s] = 0;
        }
        PrintToServer(  "[SM] Teams have been balanced." );
    }
    else
    {
        // We're not to switch immediately, but maybe some of the players we want to
        // switch are already dead, so don't wait for them to die again
        for( new s = 0; s < dCount; s++ )
        {
            if( !IsPlayerAlive( plID[s] ) )
            {
                PerformSwitch( plID[s] );
                plID[s] = 0;
            }
        }
    }
}

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
    // If we are disabled - exit
    if (!GetConVarBool(cvarEnabled))
        return;

    new client = GetClientOfUserId( GetEventInt( event, "userid" ) ),
        AdminId:plAdminID = GetUserAdmin(client);

    if (GetConVarBool(cvarAdminsImmune) &&
        plAdminID != INVALID_ADMIN_ID &&
        GetAdminFlag(plAdminID, ADMINFLAG))
    {
        return;
    }

    // Count the size and frags of each team
    new tPlayers[2] = { 0, 0 },
        tFrags[2]   = { 0, 0 },
        tLevels[2]  = { 0, 0 },
        tScore[2]  = { 0, 0 },
        pFrags[MAXPLAYERS] = { 0, ... },
        pScore[MAXPLAYERS] = { 0, ... },
        pLevel[MAXPLAYERS] = { 0, ... },
        cTeam;

    for( new i = 1; i < MaxClients; i++ )
    {
        if( IsClientInGame(i) )
        {
            cTeam = GetClientTeam(i);
            // Thanks to lambdacore for the hint
            if( cTeam >= 2 )
            {
                new t =cTeam-2;
                tPlayers[t]++;
                tFrags[t] += (pFrags[i] = GetClientFrags(i));
                if (tf2ExtAvail)
                    tScore[t] += (pScore[i] = TF2_GetPlayerResourceData(i,TFResource_Score));
                if (sourcecraftModAvail)
                    tLevels[t] += (pLevel[i] = GetOverallLevel(i));
            }
        }
    }

    // Calc score difference, div by player count difference
    // eg: if T1 has 6 players and 12 Frags, and T2 has 8 players and 16 frags,
    // player diff is 2 and frag diff is 4. That means, we need to switch 1 player (diff/2),
    // who has 2 frags ((diff/2)/players).

    dCount = max( ( abs(tPlayers[0]-tPlayers[1]) / 2 ) - switches_pending, 0 );
    new dFrags = ( abs(tFrags[0]-tFrags[1]) / 2 ) / max( dCount, 1 );
    new dScore = ( abs(tScore[0]-tScore[1]) / 2 ) / max( dCount, 1 );
    new dLevel = ( abs(tLevels[0]-tLevels[1]) / 2 ) / max( dCount, 1 );

    if( dCount == 0  && dFrags == 0 && dScore == 0 && dLevel == 0 )
        return;

    // Check team sizes and comparative score/levels/frags
    if (tPlayers[0] == tPlayers[1])
        return;
    else
        biggerTeam = ( tPlayers[0] > tPlayers[1] ? TEAM_1 : TEAM_2 );

    // Check for correct Team and last time user was switched
    if (GetClientTeam(client) != biggerTeam ||
        GetTime() - clientLastSwitched[client] < SWITCH_WAIT_TIME)
    {
        return;
    }

    // If the guy has the score and level we need, switch them and be done
    if (abs( pFrags[client] - dFrags ) <= GetConVarInt(cvarThreshold) &&
        abs( pScore[client] - dScore ) <= GetConVarInt(cvarScoreThreshold) &&
        abs( pLevel[client] - dLevel ) <= GetConVarInt(cvarLevelThreshold))
    {
        PerformTimedSwitch( client );
        clientLastSwitched[client] = GetTime();
    }
}

public OnClientDisconnect_Post( client )
{
    clientLastSwitched[client] = 0;
}

void:PerformTimedSwitch( client )
{
    CreateTimer( 0.5, Timer_TeamSwitch, client );
    switches_pending++;
}

public Action:Timer_TeamSwitch( Handle:timer, any:client )
{
    if( !IsClientInGame( client ) )
        return Plugin_Stop;

    switches_pending--;

    // Maybe the player already switched?
    if( GetClientTeam( client ) == biggerTeam )
        PerformSwitch( client );

    return Plugin_Stop;
}

void:PerformSwitch( client )
{
    if( cstrikeExtAvail )
        CS_SwitchTeam( client, 5 - biggerTeam );
    else
        ChangeClientTeam( client, 5 - biggerTeam );

    LogAction(0, client, "[SM] %N has been switched for team balance {last_switch=%d}.", client, GetTime() - clientLastSwitched[client] );

    if( game_is_tf2 )
    {
        new Handle:event = CreateEvent( "teamplay_teambalanced_player" );
        SetEventInt( event, "player", client         );
        SetEventInt( event, "team",   5 - biggerTeam );
        FireEvent( event );
    }
    else
        PrintToChatAll( "[SM] %N has been switched for team balance.", client );
}

public Event_RoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    LogMessage("RoundOver(%s)", name);
}

public Event_RoundWin(Handle:event,const String:name[],bool:dontBroadcast)
{
    new team  = GetEventInt(event,"team");
    new caps  = GetEventInt(event,"flagcaplimit");
    new lose  = GetEventInt(event,"losing_team_num_caps");
    new death = GetEventInt(event,"was_sudden_death");
    LogMessage("RoundWin(%s) winner=%d, caps=%d, loser_caps=%d, sudden_death=%d",
               name, team, caps, lose, death);
}

public Event_GameWin(Handle:event,const String:name[],bool:dontBroadcast)
{
    new team   = GetEventInt(event,"winning_team");
    new score0 = GetEventInt(event,"blue_score");
    new score1 = GetEventInt(event,"red_score");
    new prev0  = GetEventInt(event,"blue_score_prev");
    new prev1  = GetEventInt(event,"red_score_prev");

    new index1 = GetEventInt(event, "player_1");
    new index2 = GetEventInt(event, "player_2");
    new index3 = GetEventInt(event, "player_3");
    LogMessage("GameWin(%s) winner=%d, blue=%d[%d], red=%d[%d], MVP1=%N,2=%N,3=%N",
               name, team, score0, prev0, score1, prev1, index1, index2, index3);
}

public Event_GameOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    LogMessage("GameOver(%s)", name);
}

