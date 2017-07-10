#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#tryinclude <tf2betheeye>
//#tryinclude <updater>

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_UPDATE_URL "http://files.xpenia.org/sourcemod/tf2bte/updatelist.txt"

#define ERROR_NONE		0		// PrintToServer only
#define ERROR_LOG		(1<<0)	// use LogToFile
#define ERROR_BREAKF	(1<<1)	// use ThrowError
#define ERROR_BREAKN	(1<<2)	// use ThrowNativeError
#define ERROR_BREAKP	(1<<3)	// use SetFailState
#define ERROR_NOPRINT	(1<<4)	// don't use PrintToServer

#define HAUNTED_COLOR 0x8650AC

#define TIMER_HUD_REFRESH 0.5

/////////////
/* Globals */

static const String:strEyeModels[][PLATFORM_MAX_PATH] = {
	"models/props_halloween/halloween_demoeye.mdl",
	"models/props_halloween/eyeball_projectile.mdl"
};
static const String:strEyeShoot[][PLATFORM_MAX_PATH] = {
	"vo/halloween_eyeball/eyeball04.wav",
	"vo/halloween_eyeball/eyeball_mad01.wav",
	"vo/halloween_eyeball/eyeball_mad02.wav",
	"vo/halloween_eyeball/eyeball_mad03.wav"
};
static const String:strEyeLaugh[][PLATFORM_MAX_PATH] = {
	"vo/halloween_eyeball/eyeball_laugh01.wav",
	"vo/halloween_eyeball/eyeball_laugh02.wav",
	"vo/halloween_eyeball/eyeball_laugh03.wav",
	"vo/halloween_eyeball/eyeball11.wav"
};
static const String:strEyeStun[][PLATFORM_MAX_PATH] = {
	"vo/halloween_eyeball/eyeball09.wav"
};

new Handle:fwdCanPlayAsEye = INVALID_HANDLE;
new Handle:fwdOnEyeStunned = INVALID_HANDLE;

new Handle:hHUD_Health = INVALID_HANDLE;
new Handle:hHUD_Rage = INVALID_HANDLE;

new Handle:sm_tf2bte_version = INVALID_HANDLE;
new Handle:sm_tf2bte_debug = INVALID_HANDLE;
new Handle:sm_tf2bte_notify = INVALID_HANDLE;
new Handle:sm_tf2bte_eye_health = INVALID_HANDLE;
new Handle:sm_tf2bte_eye_health_per_player = INVALID_HANDLE;
new Handle:sm_tf2bte_eye_stunned_duration = INVALID_HANDLE;
new Handle:sm_tf2bte_eye_rage_multiplier = INVALID_HANDLE;
new Handle:sm_tf2bte_eye_rage_subtraction = INVALID_HANDLE;
new Handle:sm_tf2bte_eye_respawn = INVALID_HANDLE;
new Handle:sm_tf2bte_hud_xpos = INVALID_HANDLE;
new Handle:sm_tf2bte_hud_ypos = INVALID_HANDLE;

new bool:bDebugMode = false;
new nNotifications = 2;
new iEyeHealth = 10000;
new iEyeHPP = 100;
new Float:flStunDuration = 10.0;
new Float:flRageMult = 0.0001;
new Float:flRageSubt = 0.01;
new bool:bEyeRespawn = true;
new Float:flHUDPositionX = -1.0;
new Float:flHUDPositionY = -1.0;

new bool:bLateLoaded;
new bool:bPlayingOnEyeaduct;

new bool:bEyeEnabled[MAXPLAYERS+1];
new bool:bEyeStatus[MAXPLAYERS+1];
new bool:bEyeRage[MAXPLAYERS+1];
new Float:flEyeRage[MAXPLAYERS+1];
new bool:bSkipUpdateCheck[MAXPLAYERS+1];
new iOriginalTeam[MAXPLAYERS+1];
new TFClassType:iOriginalClass[MAXPLAYERS+1];
new Float:flOriginalMaxSpeed[MAXPLAYERS+1];

/////////////////
/* Plugin info */

public Plugin:myinfo = {
	name = "[TF2] Be The Monoculus",
	author = "Leonardo",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org"
};

///////////////
/* SM Events */

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	CreateNative( "TF2BTE_IsPlayerEye", Native_IsPlayerEye );
	fwdCanPlayAsEye = CreateGlobalForward( "TF2BTE_CanPlayAsEye", ET_Hook, Param_Cell );
	fwdOnEyeStunned = CreateGlobalForward( "TF2BTE_OnEyeStunned", ET_Ignore, Param_Cell, Param_Cell );
	RegPluginLibrary("tf2betheeye");
	bLateLoaded = bLateLoad;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	
	sm_tf2bte_version = CreateConVar( "sm_tf2bte_version", PLUGIN_VERSION, "TF2 Be The Ghost plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_tf2bte_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2bte_version, OnConVarChanged_PluginVersion );
	
	sm_tf2bte_debug = CreateConVar( "sm_tf2bte_debug", "0", "Debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bte_debug, OnConVarChanged );
	
	sm_tf2bte_notify = CreateConVar( "sm_tf2bte_notify", "2", "Chat notificationsn2 - public, 1 - private, 0 - disabled", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	HookConVarChange( sm_tf2bte_notify, OnConVarChanged );
	
	sm_tf2bte_eye_health = CreateConVar( "sm_tf2bte_eye_health", "5000", "Base health level", FCVAR_PLUGIN, true, 100.0 );
	HookConVarChange( sm_tf2bte_eye_health, OnConVarChanged );
	
	sm_tf2bte_eye_health_per_player = CreateConVar( "sm_tf2bte_eye_health_per_player", "100", "Health regeneration per kill", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2bte_eye_health_per_player, OnConVarChanged );
	
	sm_tf2bte_eye_stunned_duration = CreateConVar( "sm_tf2bte_eye_stunned_duration", "10.0", "Stunned eye duration", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2bte_eye_stunned_duration, OnConVarChanged );
	
	sm_tf2bte_eye_rage_multiplier = CreateConVar( "sm_tf2bte_eye_rage_multiplier", "0.001", "", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bte_eye_rage_multiplier, OnConVarChanged );
	
	sm_tf2bte_eye_rage_subtraction = CreateConVar( "sm_tf2bte_eye_rage_subtraction", "0.01", "", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bte_eye_rage_subtraction, OnConVarChanged );
	
	sm_tf2bte_eye_respawn = CreateConVar( "sm_tf2bte_eye_respawn", "1", "Once the Eye was killed, respawn as it again", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bte_eye_respawn, OnConVarChanged );
	
	sm_tf2bte_hud_xpos = CreateConVar( "sm_tf2bte_hud_xpos", "0.86", "", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bte_hud_xpos, OnConVarChanged );
	
	sm_tf2bte_hud_ypos = CreateConVar( "sm_tf2bte_hud_ypos", "0.91", "", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bte_hud_ypos, OnConVarChanged );
	
	decl String:strGameDir[8];
	GetGameFolderName(strGameDir, sizeof(strGameDir));
	if(!StrEqual(strGameDir, "tf", false) && !StrEqual(strGameDir, "tf_beta", false))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	HookEvent( "player_activate", OnPlayerActivate, EventHookMode_Post );
	HookEvent( "player_death", OnPlayerDeath, EventHookMode_Pre );
	HookEvent( "post_inventory_application", OnPlayerUpdate, EventHookMode_Post );
	
	AddNormalSoundHook( NormalSoundHook );
	
	RegConsoleCmd( "sm_betheeye", Command_ToggleEffect );
	RegConsoleCmd( "sm_bte", Command_ToggleEffect );
	RegConsoleCmd( "sm_bte_stun", Command_FakeStun );
	
	AddCommandListener( Command_VoiceMenu, "voicemenu" );
	
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
	{
		if( IsValidClient(iClient) )
		{
			RemoveModel( iClient );
			SDKHook( iClient, SDKHook_OnTakeDamage, OnTakeDamage );
			SDKHook( iClient, SDKHook_OnTakeDamagePost, OnTakeDamagePost );
		}
		else
			ResetData( iClient );
	}
	
	if( bLateLoaded )
	{
		new iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "trigger_capture_area" ) ) != -1 )
		{
			SDKHook( iEntity, SDKHook_StartTouch, OnCPTouch );
			SDKHook( iEntity, SDKHook_Touch, OnCPTouch );
		}
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "item_teamflag" ) ) != -1 )
		{
			SDKHook( iEntity, SDKHook_StartTouch, OnFlagTouch );
			SDKHook( iEntity, SDKHook_Touch, OnFlagTouch );
		}
	}
	
	hHUD_Health = CreateHudSynchronizer();
	hHUD_Rage = CreateHudSynchronizer();
	CreateTimer( TIMER_HUD_REFRESH, Timer_HUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	
#if defined _updater_included
	if( LibraryExists("updater") )
        Updater_AddPlugin( PLUGIN_UPDATE_URL );
#endif
}

public OnPluginEnd()
{
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
		if( bEyeEnabled[iClient] )
		{
			DontBeTheMonoculus( iClient );
			ResetData( iClient );
		}
}

public OnLibraryAdded( const String:strName[] )
{
#if defined _updater_included
	if( strcmp( strName, "updater", nope ) == 0 )
        Updater_AddPlugin( PLUGIN_UPDATE_URL );
#endif
}

public OnMapStart()
{
	decl String:strMapName[20];
	GetCurrentMap( strMapName, sizeof(strMapName) );
	bPlayingOnEyeaduct = StrEqual( strMapName, "koth_viaduct_event", false );
	
	PrecacheModels( strEyeModels, sizeof(strEyeModels) );
	PrecacheSounds( strEyeShoot, sizeof(strEyeShoot) );
	PrecacheSounds( strEyeLaugh, sizeof(strEyeLaugh) );
	PrecacheSounds( strEyeStun, sizeof(strEyeStun) );
}

public OnEntityCreated( iEntity, const String:strClassname[] )
{
	if( StrEqual( strClassname, "trigger_capture_area", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnCPTouch );
		SDKHook( iEntity, SDKHook_Touch, OnCPTouch );
	}
	else if( StrEqual( strClassname, "item_teamflag", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnFlagTouch );
		SDKHook( iEntity, SDKHook_Touch, OnFlagTouch );
	}
}

public OnConfigsExecuted()
{
	bDebugMode = GetConVarBool( sm_tf2bte_debug );
	nNotifications = GetConVarInt( sm_tf2bte_notify );
	iEyeHealth = GetConVarInt( sm_tf2bte_eye_health );
	iEyeHPP = GetConVarInt( sm_tf2bte_eye_health_per_player );
	flStunDuration = GetConVarFloat( sm_tf2bte_eye_stunned_duration );
	flRageMult = GetConVarFloat( sm_tf2bte_eye_rage_multiplier );
	flRageSubt = GetConVarFloat( sm_tf2bte_eye_rage_subtraction );
	bEyeRespawn = GetConVarBool( sm_tf2bte_eye_respawn );
	flHUDPositionX = GetConVarFloat( sm_tf2bte_hud_xpos );
	flHUDPositionY = GetConVarFloat( sm_tf2bte_hud_ypos );
}

public OnClientDisconnect( iClient )
{
	ResetData( iClient );
}

/////////////////
/* Game Events */

public OnPlayerActivate( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iClient) )
		return;
	
	ResetData( iClient );
	SDKHook( iClient, SDKHook_OnTakeDamage, OnTakeDamage );
	SDKHook( iClient, SDKHook_OnTakeDamagePost, OnTakeDamagePost );
}

public OnPlayerUpdate( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( bEyeRespawn && IsValidClient(iClient) && bEyeEnabled[iClient] && !bSkipUpdateCheck[iClient] )
		BeTheMonoculus( iClient );
}

public Action:OnPlayerDeath( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iClient) )
		return Plugin_Continue;
	
	if( bEyeStatus[iClient] )
	{
		DontBeTheMonoculus( iClient );
		if( !bEyeRespawn )
		{
			bEyeEnabled[iClient] = false;
			PrintStatus( iClient );
		}
		return Plugin_Continue;
	}
	
	new iKiller = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	if( !IsValidClient(iKiller) || !bEyeStatus[iKiller] )
		return Plugin_Continue;
	
	SetEventString( hEvent, "weapon", "eyeball_rocket" );
	SetEventInt( hEvent, "weaponid", 0 );
	SetEventString( hEvent, "weapon_logclassname", "eyeball_rocket" );
	SetEventInt( hEvent, "customkill", TF_CUSTOM_EYEBALL_ROCKET );
	
	if( IsPlayerAlive(iKiller) )
	{
		new iNewHealth = GetClientHealth(iKiller) + iEyeHPP;
		SetEntityHealth( iKiller, iNewHealth >= iEyeHealth ? iEyeHealth : iNewHealth );
	}
	
	return Plugin_Continue;
}

public Action:NormalSoundHook( iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags )
{
	if( !IsValidClient(iEntity) || !bEyeStatus[iEntity] )
		return Plugin_Continue;
	
	if( StrContains( strSample, "footsteps", false ) != -1 )
		return Plugin_Handled;
	
	if( bDebugMode )
		PrintToServer( "%N - Sample: %s", iEntity, strSample );
	
	if( StrContains( strSample, "vo/", false ) == 0 && StrContains( strSample, "vo/halloween_", false ) == -1 )
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:OnTakeDamage( iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamageType, &iWeapon, Float:flDamageForce[3], Float:flDamagePos[3], iDamageCustom )
{
	if( !IsValidClient( iVictim ) || !bEyeStatus[iVictim] )
		return Plugin_Continue;
	
	if( iVictim == iAttacker || (iDamageType & DMG_FALL) == DMG_FALL || (iDamageType & DMG_DROWN) == DMG_DROWN )
	{
		flDamage = 0.0; // what?
		return Plugin_Handled;
	}
	
	if( GetFeatureStatus( FeatureType_Capability, "SDKHook_DmgCustomInOTD" ) == FeatureStatus_Available )
	{
		if( iDamageCustom == TF_CUSTOM_BACKSTAB )
		{
			iDamageType &= ~DMG_CRIT;
			iDamageCustom = 0;
			flDamage /= 10.0;
			return Plugin_Changed;
		}
	}
	else if( IsValidEntity(iWeapon) && ( iDamageType & DMG_CRIT ) == DMG_CRIT && flDamage >= 300.0 )
	{
		decl String:strWeaponClass[32];
		GetEntityClassname( iWeapon, strWeaponClass, sizeof(strWeaponClass) );
		if( strcmp( strWeaponClass, "tf_weapon_knife", false ) == 0 || strcmp( strWeaponClass, "saxxy", false ) == 0 )
		{
			iDamageType &= ~DMG_CRIT;
			flDamage /= 10.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public OnTakeDamagePost( iVictim, iAttacker, iInflictor, Float:flDamage, iDamageType )
{
	if( !IsValidClient( iVictim ) || !bEyeStatus[iVictim] )
		return;
	
	if( bDebugMode )
		PrintToChat( iVictim, ">> damage taken: %d %d %0.2f %d", iAttacker, iInflictor, flDamage, iDamageType );
	
	if( !IsValidClient( iAttacker ) )
		return;
	
	if( bDebugMode )
		PrintToChat( iVictim, ">> rage meter: %0.6f +%0.6f", flEyeRage[iVictim], flDamage * flRageMult );
	
	flEyeRage[iVictim] += flDamage * flRageMult;
	if( flEyeRage[iVictim] >= 1.0 && !bEyeRage[iVictim] )
	{
		bEyeRage[iVictim] = true;
		CreateTimer( 0.1, Timer_CalmDown, iVictim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

public Action:OnCPTouch( iPoint, iOther )
{
	if( IsValidClient(iOther) && bEyeStatus[iOther] )
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action:OnFlagTouch( iFlag, iOther )
{
	if( IsValidClient(iOther) && bEyeStatus[iOther] )
		return Plugin_Handled;
	return Plugin_Continue;
}

//////////////////
/* CMDs & CVars */

public Action:Command_ToggleEffect( iClient, nArgs )
{
	if( iClient > 0 && !CheckCommandAccess( iClient, "sm_BeTheMonoculus_override", ADMFLAG_GENERIC ) )
		return Plugin_Continue;
	
	decl String:strCommandName[16];
	GetCmdArg( 0, strCommandName, sizeof(strCommandName) );
	
	if( nArgs == 0 && IsValidClient(iClient) ) 
	{
		bEyeEnabled[iClient] = !bEyeEnabled[iClient];
		PrintStatus(iClient);
		if( IsPlayerAlive(iClient) )
		{
			if( bEyeEnabled[iClient] )
				BeTheMonoculus( iClient );
			else
				DontBeTheMonoculus( iClient );
		}
	}
	else if( nArgs == 1 ) 
	{
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		
		if( IsCharNumeric(strTargets[0]) )
		{
			if( !IsValidClient(iClient) )
			{
				ReplyToCommand( iClient, "Usage: %s <target> [0/1]", strCommandName );
				return Plugin_Handled;
			}
			
			bEyeEnabled[iClient] = StringToInt(strTargets) != 0;
			PrintStatus(iClient);
			if( IsPlayerAlive(iClient) )
			{
				if( bEyeEnabled[iClient] )
					BeTheMonoculus( iClient );
				else
					DontBeTheMonoculus( iClient );
			}
			return Plugin_Handled;
		}
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS];
		decl nTargets;
		decl bool:tn_is_ml;
		if((nTargets = ProcessTargetString(strTargets, iClient, iTargets, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError( iClient, nTargets );
			return Plugin_Handled;
		}
		for( new i = 0; i < nTargets; i++ )
			if( IsValidClient( iTargets[i] ) )
			{
				bEyeEnabled[iTargets[i]] = !bEyeEnabled[iTargets[i]];
				PrintStatus(iTargets[i]);
				if( IsPlayerAlive(iTargets[i]) )
				{
					if( bEyeEnabled[iTargets[i]] )
						BeTheMonoculus( iTargets[i] );
					else
						DontBeTheMonoculus( iTargets[i] );
				}
			}
	}
	else if( nArgs == 2 )
	{
		decl String:strState[2];
		GetCmdArg( 2, strState, sizeof(strState) );
		new bool:bState = StringToInt( strState ) != 0;
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS];
		decl nTargets;
		decl bool:tn_is_ml;
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		if((nTargets = ProcessTargetString(strTargets, iClient, iTargets, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError( iClient, nTargets );
			return Plugin_Handled;
		}
		for( new i = 0; i < nTargets; i++ )
			if( IsValidClient( iTargets[i] ) )
			{
				bEyeEnabled[iTargets[i]] = bState;
				PrintStatus(iTargets[i]);
				if( IsPlayerAlive(iTargets[i]) )
				{
					if( bEyeEnabled[iTargets[i]] )
						BeTheMonoculus( iTargets[i] );
					else
						DontBeTheMonoculus( iTargets[i] );
				}
			}
	}
	else if( !IsValidClient(iClient) )
		ReplyToCommand( iClient, "Usage: %s <target> [0/1]", strCommandName );
	else
		ReplyToCommand( iClient, "Usage: %s [target] [0/1]", strCommandName );
	
	return Plugin_Handled;
}

public Action:Command_FakeStun( iClient, nArgs )
{
	if( !IsValidClient(iClient) || !bEyeStatus[iClient] )
		return Plugin_Continue;
	
	StunMonoculus( iClient, iClient );
	return Plugin_Handled;
}

public Action:Command_VoiceMenu( iClient, const String:strCmdName[], nArgs )
{
	if( !IsValidClient(iClient) || !bEyeStatus[iClient] )
		return Plugin_Continue;
	
	static Float:flLastSound[MAXPLAYERS+1];
	if( GetEngineTime() >= flLastSound[iClient] )
	{
		EmitSoundToAll( strEyeLaugh[ GetRandomInt( 0, sizeof(strEyeLaugh)-1 ) ], iClient );
		flLastSound[iClient] = GetEngineTime() + 2.0;
	}
	
	return Plugin_Handled;
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );

public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

public Action:OnPlayerRunCmd( iClient, &iButtons, &iImpulse, Float:vecVelocity[3], Float:vecAngles[3], &iWeapon )
{
	static iLastButtons[MAXPLAYERS+1];
	static Float:flLastAttack[MAXPLAYERS+1];
	static Float:flLastSound[MAXPLAYERS+1];
	
	if( !IsValidClient(iClient) || !bEyeEnabled[iClient] )
		return Plugin_Continue;
	
	if( GetEntityMoveType( iClient ) == MOVETYPE_FLY )
	{
		new Float:flMaxSpeed = GetEntPropFloat( iClient, Prop_Data, "m_flMaxspeed" );
		new Float:flFallVel = GetEntPropFloat( iClient, Prop_Send, "m_flFallVelocity" ) * -1.0;
		
		if( flMaxSpeed > 320.0 )
			flMaxSpeed = 320.0;
		
		if( (iButtons&IN_JUMP) == IN_JUMP )
		{
			if ( flFallVel <= flMaxSpeed * -1 + 20)
				vecVelocity[2] = flMaxSpeed / 2;
			else
				vecVelocity[2] = flMaxSpeed;
		}
		
		if( (iButtons&IN_DUCK) == IN_DUCK )
		{
			if ( flFallVel >= flMaxSpeed - 20)
				vecVelocity[2] = flMaxSpeed / -2;
			else
				vecVelocity[2] = flMaxSpeed * -1;
		}
	}
	
	if( !TF2_IsPlayerInCondition( iClient, TFCond_Dazed ) )
	{
		if( (iButtons & IN_RELOAD) == IN_RELOAD )
		{
			new Float:vecOrigin[3];
			GetClientAbsOrigin( iClient, vecOrigin );
			
			vecOrigin[0] = vecOrigin[0] + 2.0 * Cosine( DegToRad(vecAngles[1]) );
			vecOrigin[1] = vecOrigin[1] + 2.0 * Sine( DegToRad(vecAngles[1]) );
			vecOrigin[2] = vecOrigin[2] - 2.0 * Sine( DegToRad(vecAngles[0]) );
			
			TeleportEntity( iClient, vecOrigin, vecAngles, vecVelocity );
		}

		if( !((iLastButtons[iClient] & IN_ATTACK2) == IN_ATTACK2) && (iButtons & IN_ATTACK2) == IN_ATTACK2 )
		{
			if( bPlayingOnEyeaduct )
			{
				// teleportation code goes here
				PrintToChat( iClient, "* Teleportation is not available in this build." );
			}
			else
				PrintToChat( iClient, "* You can teleport only on Eyeaduct." );
		}
		else if( (iButtons & IN_ATTACK) == IN_ATTACK && ( GetEngineTime() - ( bEyeRage[iClient] ? 0.5 : 1.0 ) ) > flLastAttack[iClient] )
		{
			flLastAttack[iClient] = GetEngineTime();
			if( ShootRocket( iClient ) )
			{
				if( GetEngineTime() >= flLastSound[iClient] )
				{
					decl String:strSndName[PLATFORM_MAX_PATH];
					strcopy( strSndName, sizeof(strSndName), bEyeRage[iClient] ? strEyeShoot[ GetRandomInt( 1, sizeof(strEyeShoot)-1 ) ] : strEyeShoot[0] );
					
					flLastSound[iClient] = GetEngineTime() + /* GetSoundDuration( strSndName ) + */ 1.0;
					EmitSoundToAll( strSndName, iClient );
				}
			}
		}
	}
	
	iLastButtons[iClient] = iButtons;
	return Plugin_Changed;
}

///////////////
/* Functions */

ResetData( iClient )
{
	if( iClient < 0 || iClient > MAXPLAYERS )
		return;
	
	bEyeEnabled[iClient] = false;
	bEyeStatus[iClient] = false;
	bEyeRage[iClient] = false;
	flEyeRage[iClient] = 0.0;
	bSkipUpdateCheck[iClient] = false;
}

public Action:Timer_HUD( Handle:hTimer, any:iUnusedVariable )
{
	if( hHUD_Health == INVALID_HANDLE || hHUD_Rage == INVALID_HANDLE )
		return Plugin_Stop;
	
	new iHealth;
	decl String:strBuffer[128];
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) && bEyeStatus[i] )
		{
			iHealth = GetClientHealth(i);
			SetHudTextParams( flHUDPositionX, flHUDPositionY, TIMER_HUD_REFRESH + 0.01, 255, iHealth >= 500 ? 255 : 0, iHealth >= 500 ? 255 : 0, 255, 0, 0.0, 0.0, 0.0 );
			Format( strBuffer, sizeof(strBuffer), "Health: %d", GetClientHealth(i) );
			ShowSyncHudText( i, hHUD_Health, strBuffer );
			
			SetHudTextParams( flHUDPositionX, flHUDPositionY + 0.03, TIMER_HUD_REFRESH + 0.01, 255, bEyeRage[i] ? 0 : 255, bEyeRage[i] ? 0 : 255, 255, 0, 0.0, 0.0, 0.0 );
			Format( strBuffer, sizeof(strBuffer), "Rage: %d%%", RoundFloat( flEyeRage[i] * 100.0 ) );
			ShowSyncHudText( i, hHUD_Rage, strBuffer );
		}
	return Plugin_Continue;
}

public Action:Timer_CalmDown( Handle:hTimer, any:iClient )
{
	if( !IsValidClient(iClient) || !bEyeStatus[iClient] || !bEyeRage[iClient] )
		return Plugin_Stop;
	
	flEyeRage[iClient] -= flRageSubt;
	if( flEyeRage[iClient] <= 0.0 )
	{
		flEyeRage[iClient] = 0.0;
		bEyeRage[iClient] = false;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

BeTheMonoculus( iClient )
{
	if( !IsValidClient(iClient) )
	{
		Error( ERROR_LOG, _, "Invalid client: %d", iClient );
		return;
	}
	
	new Action:result;
	Call_StartForward( fwdCanPlayAsEye );
	Call_PushCell( iClient );
	Call_Finish( result );
	if( result >= Plugin_Handled )
		return;
	
	bSkipUpdateCheck[iClient] = true;
	TF2_RegeneratePlayer( iClient );
	bSkipUpdateCheck[iClient] = false;
	
	CreateTimer( 0.0, Timer_BeTheMonoculus, iClient );
}

public Action:Timer_BeTheMonoculus( Handle:hTimer, any:iClient )
{
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	if( !bEyeStatus[iClient] )
	{
		iOriginalTeam[iClient] = GetClientTeam(iClient);
		iOriginalClass[iClient] = TF2_GetPlayerClass(iClient);
		flOriginalMaxSpeed[iClient] = GetEntPropFloat( iClient, Prop_Data, "m_flMaxspeed" );
	}
	
	bEyeStatus[iClient] = true;
	bEyeRage[iClient] = false;
	flEyeRage[iClient] = 0.0;
	
	SetEntProp( iClient, Prop_Send, "m_iTeamNum", 0 );
	TF2_SetPlayerClass( iClient, TFClassType:10, _, true );
	SetEntPropFloat( iClient, Prop_Data, "m_flMaxspeed", 265.0 );
	
	AttachParticle( iClient, "ghost_appearation", _, 2.0, 2.0 );
	//EmitSoundToAll( strGhostMoans[ GetRandomInt( 0, sizeof(strGhostMoans)-1 ) ], iClient );
	SetModel( iClient );
	SetWeaponsAlpha( iClient, 0 );
	SetEntityMoveType( iClient, MOVETYPE_FLY );
	SetEntProp( iClient, Prop_Send, "m_bDrawViewmodel", 0 );
	TF2_RemoveAllWeapons( iClient );
	
	CreateTimer( 0.0, Timer_SetBossHealth, iClient );
	return Plugin_Stop;
}
public Action:Timer_SetBossHealth( Handle:hTimer, any:iClient )
{
	if( !IsValidClient(iClient) || !bEyeStatus[iClient] )
		return Plugin_Stop;
	
	SetEntityHealth( iClient, iEyeHealth );
	return Plugin_Stop;
}
DontBeTheMonoculus( iClient )
{
	if( !IsValidClient(iClient) )
	{
		Error( ERROR_LOG, _, "Invalid client: %d", iClient );
		return;
	}
	
	bEyeStatus[iClient] = false;
	bEyeRage[iClient] = false;
	flEyeRage[iClient] = 0.0;
	
	if( hHUD_Health != INVALID_HANDLE )
		ClearSyncHud( iClient, hHUD_Health );
	if( hHUD_Rage != INVALID_HANDLE )
		ClearSyncHud( iClient, hHUD_Rage );
	
	SetEntProp( iClient, Prop_Send, "m_iTeamNum", iOriginalTeam[iClient] );
	TF2_SetPlayerClass( iClient, iOriginalClass[iClient], _, true );
	SetEntPropFloat( iClient, Prop_Data, "m_flMaxspeed", flOriginalMaxSpeed[iClient] );
	
	RemoveModel( iClient );
	SetWeaponsAlpha( iClient, 255 );
	AttachParticle( iClient, "ghost_appearation", _, 2.0, 2.0 );
	//EmitSoundToAll( strGhostEffects[ GetRandomInt( 0, sizeof(strGhostEffects)-1 ) ], iClient );
	SetEntityMoveType( iClient, MOVETYPE_WALK );
	SetEntityHealth( iClient, 200 );
	bSkipUpdateCheck[iClient] = true;
	TF2_RegeneratePlayer( iClient );
	bSkipUpdateCheck[iClient] = false;
	SetEntProp( iClient, Prop_Send, "m_bDrawViewmodel", 1 );
}

SetModel( iClient )
{
	if( !IsValidClient( iClient ) )
		return;
	
	if( !IsModelPrecached( strEyeModels[0] ) )
		if( PrecacheModel( strEyeModels[0] ) == 0 )
		{
			Error( ERROR_LOG, _, "Faild to precache model: %s", strEyeModels[0] );
			return;
		}
	
	SetVariantString( strEyeModels[0] );
	AcceptEntityInput( iClient, "SetCustomModel" );
	
	SetVariantString( "" );
	AcceptEntityInput( iClient, "DisableShadow" );
}
RemoveModel( iClient )
{
	if( !IsValidClient( iClient ) )
		return;
	
	SetVariantString( "" );
	AcceptEntityInput( iClient, "EnableShadow" );
	
	SetVariantString( "" );
	AcceptEntityInput( iClient, "SetCustomModel" );
	
	SetVariantString( "ParticleEffectStop" );
	AcceptEntityInput(iClient, "DispatchEffect");
}

bool:ShootRocket( iClient )
{
	if( !IsValidClient( iClient ) || !bEyeStatus[iClient] )
		return false;
	
	
	new iRocket = CreateEntityByName("tf_projectile_rocket");
	
	if( !IsValidEntity(iRocket) )
		return false;
	
	SetEntPropEnt( iRocket, Prop_Send, "m_hOwnerEntity", iClient );
	SetEntPropEnt( iRocket, Prop_Send, "m_hLauncher", iClient );
	SetEntProp( iRocket, Prop_Send, "m_bCritical", 1 );
	
	static offsRocketDeflected = -1;
	if( offsRocketDeflected == -1 )
		offsRocketDeflected = FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected");
	if( offsRocketDeflected != -1 )
		SetEntDataFloat( iRocket, offsRocketDeflected+4, 50.0, true );
	else
	{
		Error( ERROR_LOG, _, "Failed to set rocket damage!" );
		return false;
	}
	
	DispatchSpawn( iRocket );
	
	
	SetEntityModel( iRocket, strEyeModels[1] );
	
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecVelocity[3], Float:flMult;
	GetClientAbsOrigin( iClient, vecOrigin );
	GetClientEyeAngles( iClient, vecAngles );
	
	flMult = 56.0;
	vecOrigin[0] += flMult * Cosine( DegToRad(vecAngles[1]) );
	vecOrigin[1] += flMult * Sine( DegToRad(vecAngles[1]) );
	vecOrigin[2] += 48.0 - flMult * Sine( DegToRad(vecAngles[0]) );
	
	flMult = _:bEyeRage[iClient] ? 1500.0 : 500.0;
	GetAngleVectors( vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector( vecVelocity, vecVelocity );
	ScaleVector( vecVelocity, flMult );
	
	TeleportEntity( iRocket, vecOrigin, vecAngles, vecVelocity );
	return true;
}

StunMonoculus( iClient, iAttacker )
{
	if( !IsValidClient(iClient) || !bEyeStatus[iClient] )
		return;
	
	TF2_StunPlayer( iClient, flStunDuration, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_THIRDPERSON|TF_STUNFLAG_SLOWDOWN );
	SetEntityMoveType( iClient, MOVETYPE_WALK );
	EmitSoundToAll( strEyeStun[ GetRandomInt( 0, sizeof(strEyeStun)-1 ) ], iClient );
	
	Call_StartForward( fwdOnEyeStunned );
	Call_PushCell( iClient );
	Call_PushCell( iAttacker );
	Call_Finish();
	
	CreateTimer( flStunDuration, Timer_UnstunMonoculus, iClient );
}
public Action:Timer_UnstunMonoculus( Handle:hTimer, any:iClient )
{
	if( !IsValidClient(iClient) || !bEyeStatus[iClient] )
		return Plugin_Stop;
	
	SetEntityMoveType( iClient, MOVETYPE_FLY );
	return Plugin_Stop;
}

PrintStatus( iClient )
{
	if( !IsValidClient(iClient) )
		return;
	if( bEyeEnabled[iClient] )
	{
		if( nNotifications == 2 )
			PrintToChatAll( "\x07%06X%N\x01 is now as Monoculus.", HAUNTED_COLOR, iClient );
		else if( nNotifications == 1 )
			PrintToChat( iClient, "* You're now as Monoculus." );
	}
	else
	{
		if( nNotifications == 2 )
			PrintToChatAll( "\x07%06X%N\x01 is no longer as Monoculus.", HAUNTED_COLOR, iClient );
		else if( nNotifications == 1 )
			PrintToChat( iClient, "* You're no longer as Monoculus." );
	}
}

AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0, Float:flSelfDestruct=0.0)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if(strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		
		if( flSelfDestruct > 0.0 )
			CreateTimer( flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
		
		return iParticle;
	}
	
	return 0;
}
public Action:Timer_DeleteParticle(Handle:hTimer, any:iRefEnt)
{
	new iEntity = EntRefToEntIndex(iRefEnt);
	if(iEntity > MaxClients)
		AcceptEntityInput(iEntity, "Kill");
	
	return Plugin_Handled;
}

/////////////
/* Natives */

public Native_IsPlayerEye( Handle:hPlugin, nParams )
{
	new iClient = GetNativeCell(1);
	return IsValidClient( iClient ) && bEyeStatus[iClient];
}

////////////
/* Stocks */

stock Error( iFlags = ERROR_NONE, iNativeErrCode = SP_ERROR_NONE, const String:strMessage[], any:... )
{
	decl String:strBuffer[1024];
	VFormat( strBuffer, sizeof(strBuffer), strMessage, 4 );
	
	if( iFlags )
	{
		if( iFlags & ERROR_LOG )
		{
			decl String:strFile[PLATFORM_MAX_PATH];
			FormatTime( strFile, sizeof(strFile), "%Y%m%d" );
			Format( strFile, sizeof(strFile), "TF2BTE%s", strFile );
			BuildPath( Path_SM, strFile, sizeof(strFile), "logs/%s.log", strFile );
			LogToFileEx( strFile, strBuffer );
		}
		
		if( iFlags & ERROR_BREAKF )
			ThrowError( strBuffer );
		if( iFlags & ERROR_BREAKN )
			ThrowNativeError( iNativeErrCode, strBuffer );
		if( iFlags & ERROR_BREAKP )
			SetFailState( strBuffer );
		
		if( iFlags & ERROR_NOPRINT )
			return;
	}
	
	PrintToServer( strBuffer );
}

stock PrecacheModels( const String:strModels[][], iArraySize )
{
	for( new i = 0; i < iArraySize; i++ )
		if( PrecacheModel( strModels[i], true ) == 0 )
			Error( ERROR_LOG, _, "Faild to precache model: %s", strModels[i] );
}
stock PrecacheSounds( const String:strModels[][], iArraySize )
{
	for( new i = 0; i < iArraySize; i++ )
		if( !PrecacheSound( strModels[i], true ) )
			Error( ERROR_LOG, _, "Faild to precache sound: %s", strModels[i] );
}

stock SetWeaponsAlpha( iClient, iAlpha )
{
	if( IsClientInGame(iClient) )
	{
		decl String:classname[64];
		new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
		for(new i = 0, weapon; i < 47; i += 4)
		{
			weapon = GetEntDataEnt2(iClient, m_hMyWeapons + i);
			if(weapon > -1 && IsValidEdict(weapon))
			{
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "saxxy", false) != -1 || StrContains(classname, "tf_wearable", false) != -1)
				{
					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, 255, 255, 255, iAlpha);
				}
			}
		}
		
		new iEnt;
		while( ( iEnt = FindEntityByClassname( iEnt, "tf_wearable" ) ) != -1 )
		{
			if( GetEntPropEnt( iEnt, Prop_Send, "m_hOwnerEntity" ) == iClient )
			{
				SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEnt, 255, 255, 255, iAlpha);
			}
		}
		iEnt = 0;
		while( ( iEnt = FindEntityByClassname( iEnt, "tf_wearable_demoshield" ) ) != -1 )
		{
			if( GetEntPropEnt( iEnt, Prop_Send, "m_hOwnerEntity" ) == iClient )
			{
				SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEnt, 255, 255, 255, iAlpha);
			}
		}
		iEnt = 0;
		while( ( iEnt = FindEntityByClassname( iEnt, "tf_wearable_robot_arm" ) ) != -1 )
		{
			if( GetEntPropEnt( iEnt, Prop_Send, "m_hOwnerEntity" ) == iClient )
			{
				SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEnt, 255, 255, 255, iAlpha);
			}
		}
	}
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}