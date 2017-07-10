// TF2 FortWars Include File
// By Matheus28

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#if defined _fortwars_included
 #endinput
#endif
#define _fortwars_included

#define FORTWARS_PREFIX "\x04[FortWars]\x01"
#define FORTWARS_MAX_UNLOCK_LEVEL 16

// 300 is already enough to cause an reliable snapshot overflow,
// I'll leave 400 for people that build on a local server
#define FORTWARS_MAX_PROPS_PER_TEAM 400
#define FORTWARS_PROPS_ARRAY_SIZE FORTWARS_MAX_PROPS_PER_TEAM*2+1
#define FORTWARS_MAX_APROPS 64

#define FORTWARS_HEALTH_VERYLOW 100
#define FORTWARS_HEALTH_LOW 300
#define FORTWARS_HEALTH_MEDIUM 500
#define FORTWARS_HEALTH_HIGH 750
#define FORTWARS_HEALTH_VERYHIGH 1000
#define FORTWARS_HEALTH_EXTREME 1500

/*
* You should register your unlock in the forward OnFortWarsLoad,
* 
* 
* Please remember that, if your plugin doesn't loads successfully
* (if it doesn't calls FW_AddUnlock), clients that get their data refreshed
* will lose your unlock information.
* 
* Unlocks numerical id may change every time the fortwars plugin starts,
* unlocks id won't.
* 
* There are circumstances where the OnPropDestroyed won't fire,
* like when the map restarts.
* 
*/

/*
* How to add a prop with multiple models
* 
* - Register your prop using FW_AddProp2
* - Add each new model using FW_AddPropModel,
* the apropid is the return value of FW_AddProp2
*/

/*
* How to change a prop entity:
* 
* - Register your prop using FW_AddProp
* - Make a function for OnPropBuilt and check if it is your propid
* - Create the entity you want
* - Call FW_SetPropEntity
* - Destroy the old entity
* 
* The input fired for the "Remove Prop" is "Break".
* Props will only be detected that they were destroyed on the output "OnBreak"
*/

public SharedPlugin:__pl_fortwars = 
{
	name = "fortwars",
	file = "fortwars.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

enum FWProp{
	INVALID_PROP=-1,
	maxProps=FORTWARS_PROPS_ARRAY_SIZE
}
enum FWAProp{
	INVALID_APROP=-1,
	maxAProps=FORTWARS_MAX_APROPS
}

forward OnBuildStart();
forward OnBuildEnd();
// If you change allow to false, you must display the error using FW_ShowError
forward OnPropBuilt_Pre(builder, &bool:allow, FWAProp:propid);
forward OnPropBuilt(builder, ent, FWProp:prop, FWAProp:propid, const Float:pos[3], const Float:ang[3]);
forward OnPropRotated(builder, ent, FWProp:prop, FWAProp:propid, const Float:pos[3], const Float:ang[3]);
forward OnPropDestroyed(ent, FWProp:prop);


/**
 * Adds this plugin as a dependent of FortWars,
 * if fortwars gets unloaded, your plugin will get unloaded too.
 * 
 * @noreturn
 * @error			None
 */
native FW_AddDependence();

/**
 * Checks if fortwars is running, this will return false before OnFortWarsLoaded
 * 
 * @return			True if it is running
 * @error			None
 */
native bool:FW_IsRunning();

/**
 * Registers an Unlock, id should not contain any "=" or ";"
 *
 * @param id		Unlock's id, sizeof(id) must be <= 64
 * @param name		Unlock's name to display on the menu, sizeof(name) must be <= 128
 * @param cost		Unlock's cost
 * @return			Unlocks's numerical id or -1 if any error occurs
 * @error			Invalid Id
 */
native FW_AddUnlock(const String:id[], const String:name[], cost);

/**
 * Registers an Unlock with more options, id should not contain any "=" or ";"
 *
 * @param id			Unlock's id, sizeof(id) must be <= 64
 * @param name			Unlock's name to display on the menu, sizeof(name) must be <= 128
 * @param numLevels		Number of levels (1 = Same behavior as FW_AddUnlock)
 * @param cost			Unlock's cost per level (0 = level 1)
 * @param required		Required unlock id to be able to unlock this
 * @param requiredLevel	Required unlock level
 * @return				Unlocks's numerical id or -1 if any error occurs
 * @error				Invalid Id
 */
native FW_AddUnlock2(const String:id[], const String:name[], numLevels, cost[], const String:required[]="", requireLevel=1);

/**
 * Removes an Unlock based on its id
 *
 * @param id		Unlock's id, sizeof(id) must be <= 64
 * @return			true if it was removed, false otherwise (if it didn't exist)
 * @error			None
 */
 native FW_RemoveUnlock(const String:id[]);

/**
 * Returns if the client has an unlock, and its level (0 if the client doesn't have)
 *
 * @param client	Client's entindex
 * @param id		Unlock's numerical id
 * @return			Unlock level (0 if the client doesn't have)
 * @error			If unlock doesn't exist
 */
native bool:FW_HasUnlock(client, id);

/**
 * Returns if an unlock exists, if you are interested in the unlock
 * numerical id, you should use FW_UnlockIdToNumId and checks if the
 * result is different from -1
 *
 * @param id		Unlock's id
 * @return			true if it exists, false otherwise
 * @error			None
 */
native bool:FW_UnlockExists(const String:id[]);

/**
 * Returns an unlock numerical id, -1 if it doesn't exist
 *
 * @param id		Unlock's id
 * @return			Unlock's numerical id
 * @error			None
 */
native FW_UnlockIdToNumId(const String:id[]);


functag public FW_ClientCallback(client);
//Not implemented yet: functag public bool:FW_NameCallback(client, String:name[]);

/**
 * Add an item to the FortWars Main Menu, if its id already exists,
 * it will overwrite it
 *
 * @param id				Menu item id (must be at least 3 chars long)
 * @param name				Menu item name
 * @param buildPhaseOnly	Only enable item when it's on building phase
 * @param func				Callback when a client selects it
 * @return					Menu item numerical id
 * @error					None
 */
native FW_AddMenuItem(const String:id[], const String:name[], bool:buildPhaseOnly=false, FW_ClientCallback:func);

/**
 * Removes an Menu Item based on its id
 *
 * @param id		Menu item id, sizeof(id) must be <= 64
 * @return			true if it was removed, false otherwise (if it didn't exist)
 * @error			None
 */
 native FW_RemoveMenuItem(const String:id[]);

/**
 * Shows the FortWars Main Menu to the client
 *
 * @param client			Client index
 * @param page				Menu Page
 * @noreturn
 * @error					None
 */
native FW_ShowMainMenu(client, page=0);

/**
 * Adds a new prop to the menu
 *
 * @param name			Prop name
 * @param path			Path to the prop model
 * @param health		Amount of health
 * @param cost			Client index
 * @param count			Amount of props to count to the prop limit
 * @param stick			If the props stickies, it can't be rotated and when it's created, it stickies.
 * @param pitchOffset	Pitch offset for when it's created/rotated
 * @param yawOffset		Yaw offset for when it's created/rotated
 * @param rollOffset	Roll offset for when it's created/rotated
 * @return				Prop id
 * @error				None
 */
 native FWAProp:FW_AddProp(const String:name[], const String:path[], health, cost, count=1, bool:stick=false, Float:posOffset[3]=NULL_VECTOR, Float:anglesOffset[3]=NULL_VECTOR);
 
 /**
 * Adds a new dynamic prop to the menu, you need to add models to it using FW_AddPropModel
 * (Only use this if you are going to use multiple models)
 *
 * @param name			Prop name
 * @param health		Amount of health
 * @param cost			Client index
 * @param stick			If the props stickies, it can't be rotated and when it's created, it stickies.
 * @param pitchOffset	Pitch offset for when it's created/rotated
 * @param yawOffset		Yaw offset for when it's created/rotated
 * @param rollOffset	Roll offset for when it's created/rotated
 * @return				Prop id
 * @error				None
 */
 native FWAProp:FW_AddProp2(const String:name[], health, cost, count=1, bool:stick=false, Float:posOffset[3]=NULL_VECTOR, Float:anglesOffset[3]=NULL_VECTOR);
 
 /**
 * Adds a new dynamic prop to the menu, you need to add models to it using FW_AddPropModel
 * (Only use this if you are going to use multiple models)
 *
 * @param propid		Prop id
 * @param path			Path to the model
 * @noreturn
 * @error				None
 */
 native FW_AddPropModel(FWAProp:apropid, const String:path[]);
 
 /**
 * Set a prop entity, so fortwars will hook it and consider it
 * as an prop. (The builder will be able to destroy it, etc)
 * 
 * This function will teleport the entity to the old entity origin and angles
 * If the client uses "Delete Prop", it will fire the OnPropDestroyed and the Kill input
 * You must manually fire "FW_PropDestroyed".
 *
 * @param prop			Prop
 * @param ent			Entity
 * @noreturn
 * @error				None
 */
 native FW_SetPropEntity(FWProp:prop, ent);
 
 /**
 * Gets the Prop Id of the entity, or INVALID_PROP if it isn't a FortWars prop.
 *
 * @param ent			Entity
 * @return				Prop Id of the entity, or INVALID_PROP if it isn't a FortWars prop
 * @error				None
 */
 native FWProp:FW_GetEntityProp(ent);
 
 /**
 * Tells FortWars that this prop was destroyed, this will trigger the OnPropDestroyed.
 * You still need to remove the entity
 *
 * @param prop			Prop
 * @noreturn
 * @error				None
 */
 native FW_PropDestroyed(FWProp:prop);
 
 
 // Prop Count = Number of props that the client/team built
 native FW_AddPropCount(client, amount);
 native FW_GetTeamPropCount(team);
 native FW_GetClientPropCount(client);
 
 native FW_ShowError(client, Float:duration=5.0, const String:error[]);