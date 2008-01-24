/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: SourceCraft.inc
 * Description: Definitions for SourceCraft Natives.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

#if defined sourcecraft_included
 #endinput
#endif
#define sourcecraft_included

// The types of immunities you can get/set from.
enum Immunity
{
	Immunity_Ultimates = 0, // Immune from ultimates
	Immunity_HealthTake = 1, // Immune from health taking
	Immunity_Explosion = 2, // Immune from explosion based stuff
	Immunity_ShopItems = 3, // Immune from shop items
};

/**
 * Registers a race with the SourceCraft plugin
 * @param name: The name of the race. (max 64)
 * @param short: The shortname used for SQL stuff. (max 16) 
 * @param switchmessage_instant: The message displayed to the player when they are switched to a new race. (max 192)
 * @param switchmessage_dead: The message displayed to the play when they try to switch to the race, but they are alive so they need to wait until they die or the new round. (max 192)
 * @param skill1: The name of the first skill. (max 64)
 * @param skill1_desc: The description of the first skill. (max 192)
 * @param skill2: The name of the second skill. (max 64)
 * @param skill2_desc: The description of the second skill. (max 192)
 * @param skill3: The name of the third skill. (max 64)
 * @param skill3_desc: The description of the third skill. (max 192)
 * @param ult: The name of the ultimate. (max 64)
 * @param ult_desc: The description of the ultimate. (max 192)
 * @param required_level: The overeall level the player must obtain before changing to this race. (as a string)
 * @return The return value will be the race index or -1 if there was a problem.
 */         
native CreateRace(String:name[],String:short[],String:switchmessage_instant[],String:switchmessage_dead[],String:skill1[],String:skill1_desc[],String:skill2[],String:skill2_desc[],String:skill3[],String:skill3_desc[],String:ult[],String:ult_desc[], String:required_level[]="0");

/**
 * Registers a shop item with the SourceCraft plugin
 * @param name: The name of the item. (max 64)
 * @param desc: The description of the item. (max 256) 
 * @param cost: The cost of the item as a string for vector reasons. (max 4 chars)
 * @return The return value will be the item index or -1 if there was a problem.
 */         
native CreateShopItem(String:name[],String:desc[],String:cost[]);

/**
 * Registers a help command with the SourceCraft plugin for help
 * @param name: The name of the command. (max 64)
 * @param desc: The description of the command. (max 256) 
 * @noreturn
 */
native CreateHelpCommand(String:name[],String:desc[]);

/**
 * Get the ShopItem ID of a shop item
 * @param name: The name of the item. (max 64)
 * @return The return value will be the item index or -1 if there was a problem.
 */         
native GetShopItem(String:name[]);

/**
 * Gets the health of client that was saved in the last GameFrame
 * @param client: The client's index you want.
 * @return The return value will be the amount of health client had last GameFrame.
 */
native GetSavedHealth(client);

/**
 * Gets (or Calculates) damage for the given event.
 * @param event: The Handle to the event
 * @param client: The client's index you want (defaults to userid from event)
 * @return The return value will be the amount of damage
 */
native GetDamage(Handle:event, client=0);

/**
 * Gets the Player ID used for the rest of the interface natives.
 * @param client: The client's index you want.
 * @return The return value will be the Player ID, -1 on failure.
 */
native GetPlayer(client);

/**
 * Gets the current level for the provided race.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param race: The race ID returned from War3_CreateRace
 * @return The return value will be the level, if -1 then it failed.
 */
native GetLevel(player,race);

/**
 * Gets the current race for the player.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @return The return value will be the race of the player, if -1 then it failed.
 */
native GetRace(player);

/**
 * Gets the XP for the provided race.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param race: The race ID returned from War3_CreateRace
 * @return The return value will be the xp, if -1 then it failed.
 */
native GetXP(player,race);

/**
 * Sets the XP for the provided race.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param race: The race ID returned from War3_CreateRace
 * @param newxp: The XP you want to set to 
 * @noreturn
 */
native SetXP(player,race,newxp);

/**
 * Gets the current level for the skill for the provided race.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param race: The race ID returned from War3_CreateRace
 * @param skill: The skill you want to lookup with, (0==skill1,1==skill2,2==skill3,3==ultimate) 
 * @return The return value will be the skill level, if -1 then it failed.
 */
native GetSkillLevel(player,race,skill);

/**
 * Gets if the player owns a specific item.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param item: The item ID returned from War3_CreateShopItem
 * @return The return value will be 1 if they own it, if 0 they don't, if -1 then it failed.
 */
native GetOwnsItem(player,item);

/**
 * Sets if the player owns a specific item.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param item: The item ID returned from War3_CreateShopItem
 * @param owns: 1 if you want them to own it, 0 if you want them not to own it 
 * @noreturn
 */
native SetOwnsItem(player,item,owns=1);

/**
 * Gets the state of a certain immunity.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param immunity: The immunity you want to check. 
 * @return The return value will be 1 if they are immune, if 0 they aren't, if -1 then it failed.
 */
native GetImmunity(player,Immunity:immunity);

/**
 * Sets if the player owns a specific item.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param immunity: The immunity you want to set.
 * @param imm_state: The state of immunity, 1 if they are, 0 if they aren't.
 * @noreturn
 */
native SetImmunity(player,Immunity:immunity,imm_state=1);

/**
 * Sets the speed for the player that is handled within the War3Source system, good for skills and items that set speed so you don't end up making the player slower.
 * Pass 1.0 as speed when they no longer should use the speed, make sure to do this when they no longer have the skill or item, or whatever.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param speed: The speed you want to pass.
 * @noreturn
 */
native SetMaxSpeed(player,Float:speed=1.0);

/**
 * Sets the gravity for the player that is handled within the War3Source system, good for skills and items that set gravity so you don't end up making the player jump lower.
 * Pass 1.0 as gravity when they no longer should use the gravity, make sure to do this when they no longer have the skill or item, or whatever.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param gravity: The gravity you want to pass.
 * @noreturn
 */
native SetMinGravity(player,Float:gravity=1.0);

/**
 * Sets the (in)visibility for the player that is handled within the War3Source system, good for skills and items that set (in)visibility so you don't end up making the player more visibile.
 * Pass 255 as visibility when they no longer should use the (in)visibility, make sure to do this when they no longer have the skill or item, or whatever.
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param visibility: The visibility you want to pass.
 * @param melee_factor: The value to multiply the visibility by when player uses a melee weapon (Pass 1.0 to not check for melee weapons)
 * @param melee_factor: The value to multiply the visibility by when player is not moving.
 * @noreturn
 */
native SetMinVisibility(player,visibility=255,Float:melee_factor=1.0,Float:movement_factor=1.0);

/**
 * Overrides the speed for War3Source, useful for punishing them or whatever.
 * Pass 0.0 as speed when you want the War3Source system to take over again, make sure to do this when they are no longer supposed to follow!
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param speed: The speed you want to pass.
 * @noreturn
 */
native SetOverrideSpeed(player,Float:speed=0.0);

/**
 * Overrides the gravity for War3Source, useful for punishing them or whatever.
 * Pass 0.0 as gravity when you want the War3Source system to take over again, make sure to do this when they are no longer supposed to follow!
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param gravity: The gravity you want to pass.
 * @noreturn
 */
native SetOverrideGravity(player,Float:gravity=0.0);

/**
 * Overrides the (in)visibility for War3Source, useful for punishing them or whatever.
 * Pass -1 as visibility when you want the War3Source system to take over again, make sure to do this when they are no longer supposed to follow!
 * @param player: The player ID to use. Can be retrieved with GetPlayer.
 * @param visibility: The visibility you want to pass.
 * @noreturn
 */
native SetOverrideVisible(player,visibility=-1);

/**
 * Called when the plugin is ready.
 */
forward OnPluginReady();
 
/**
 * Gets called when the player has been authed.
 * @param client: The client's index.
 * @param player: The player ID that was authed.
 */
forward OnPlayerAuthed(client,player);

/**
 * Gets called when someone changes their race.
 * @param client: The client's index.
 * @param player: The player ID of the client.
 * @param oldrace: The player's old race. 
 * @param newrace: The player's new race.
 */
forward OnRaceSelected(client,player,oldrace,newrace);
#define OnRaceChanged OnRaceSelected

/**
 * Gets called when the +ultimate or -ultimate command is called, IT ISNT ALWAYS FOR YOUR RACE, YOU NEED TO CHECK!!!
 * @param client: The client's index.
 * @param player: The player ID of the client.
 * @param race: The race for which it was called.
 * @param pressed: If true, +ultimate, false, -ultimate.
 */
forward OnUltimateCommand(client,player,race,bool:pressed);

/**
 * Gets called when a player purchases an item.
 * @param client: The client's index.
 * @param player: The player ID of the client.
 * @param item: The item that was purchased.
 */
forward OnItemPurchase(client,player,item);

/**
 * Gets called when a skill level is changed.
 * @param client: The client's index.
 * @param player: The player ID of the client.
 * @param race: The race effected.
 * @param skill: The skill effected.
 * @param oldskilllevel: The old skill level.
 * @param newskilllevel: The new skill level.   
 */
forward OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel);
