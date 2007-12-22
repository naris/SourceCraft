/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: War3Source_Interface.inc
 * Description: The file to be included for creating races and whatnot.
 * Author(s): Anthony Iacono  
 */

#if defined _war3source_interface_included
 #endinput
#endif
#define _war3source_interface_included

// The types of immunities you can get/set from.
enum War3Immunity
{
	Immunity_Ultimates = 0, // Immune from ultimates
	Immunity_HealthTake = 1, // Immune from health taking
	Immunity_Explosion = 2, // Immune from explosion based stuff
	Immunity_ShopItems = 3, // Immune from shop items
};

/**
 * Registers a race with the War3Source plugin
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
 * @return The return value will be the race index or -1 if there was a problem.
 */         
native War3_CreateRace(String:name[],String:short[],String:switchmessage_instant[],String:switchmessage_dead[],String:skill1[],String:skill1_desc[],String:skill2[],String:skill2_desc[],String:skill3[],String:skill3_desc[],String:ult[],String:ult_desc[]);

/**
 * Registers a shop item with the War3Source plugin
 * @param name: The name of the item. (max 64)
 * @param desc: The description of the item. (max 256) 
 * @param cost: The cost of the item as a string for vector reasons. (max 4 chars)
 * @return The return value will be the item index or -1 if there was a problem.
 */         
native War3_CreateShopItem(String:name[],String:desc[],String:cost[]);

/**
 * Registers a help command with the War3Source plugin for war3help
 * @param name: The name of the command. (max 64)
 * @param desc: The description of the command. (max 256) 
 * @noreturn
 */
native War3_CreateHelpCommand(String:name[],String:desc[]);

/**
 * Get the ShopItem ID of a shop item
 * @param name: The name of the item. (max 64)
 * @return The return value will be the item index or -1 if there was a problem.
 */         
native War3_GetShopItem(String:name[]);

/**
 * Gets the War3Player ID used for the rest of the War3 interface natives.
 * @param client: The client's index you want.
 * @return The return value will be the War3Player ID, -1 on failure.
 */
native War3_GetWar3Player(client);

/**
 * Gets the current level for the provided race.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param race: The race ID returned from War3_CreateRace
 * @return The return value will be the level, if -1 then it failed.
 */
native War3_GetLevel(war3player,race);

/**
 * Gets the current race for the war3player.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @return The return value will be the race of the player, if -1 then it failed.
 */
native War3_GetRace(war3player);

/**
 * Gets the XP for the provided race.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param race: The race ID returned from War3_CreateRace
 * @return The return value will be the xp, if -1 then it failed.
 */
native War3_GetXP(war3player,race);

/**
 * Sets the XP for the provided race.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param race: The race ID returned from War3_CreateRace
 * @param newxp: The XP you want to set to 
 * @noreturn
 */
native War3_SetXP(war3player,race,newxp);

/**
 * Gets the current level for the skill for the provided race.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param race: The race ID returned from War3_CreateRace
 * @param skill: The skill you want to lookup with, (0==skill1,1==skill2,2==skill3,3==ultimate) 
 * @return The return value will be the skill level, if -1 then it failed.
 */
native War3_GetSkillLevel(war3player,race,skill);

/**
 * Gets if the player owns a specific item.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param item: The item ID returned from War3_CreateShopItem
 * @return The return value will be 1 if they own it, if 0 they don't, if -1 then it failed.
 */
native War3_GetOwnsItem(war3player,item);

/**
 * Sets if the player owns a specific item.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param item: The item ID returned from War3_CreateShopItem
 * @param owns: 1 if you want them to own it, 0 if you want them not to own it 
 * @noreturn
 */
native War3_SetOwnsItem(war3player,item,owns=1);

/**
 * Gets the state of a certain immunity.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param immunity: The immunity you want to check. 
 * @return The return value will be 1 if they are immune, if 0 they aren't, if -1 then it failed.
 */
native War3_GetImmunity(war3player,War3Immunity:immunity);

/**
 * Sets if the player owns a specific item.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param immunity: The immunity you want to set.
 * @param imm_state: The state of immunity, 1 if they are, 0 if they aren't.
 * @noreturn
 */
native War3_SetImmunity(war3player,War3Immunity:immunity,imm_state=1);

/**
 * Sets the speed for the player that is handled within the War3Source system, good for skills and items that set speed so you don't end up making the player slower.
 * Pass 1.0 as speed when they no longer should use the speed, make sure to do this when they no longer have the skill or item, or whatever.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param speed: The speed you want to pass.
 * @noreturn
 */
native War3_SetMaxSpeed(war3player,Float:speed=1.0);

/**
 * Sets the gravity for the player that is handled within the War3Source system, good for skills and items that set gravity so you don't end up making the player jump lower.
 * Pass 1.0 as gravity when they no longer should use the gravity, make sure to do this when they no longer have the skill or item, or whatever.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param gravity: The gravity you want to pass.
 * @noreturn
 */
native War3_SetMinGravity(war3player,Float:gravity=1.0);

/**
 * Sets the (in)visibility for the player that is handled within the War3Source system, good for skills and items that set (in)visibility so you don't end up making the player more visibile.
 * Pass 255 as visibility when they no longer should use the (in)visibility, make sure to do this when they no longer have the skill or item, or whatever.
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param visibility: The visibility you want to pass.
 * @param melee_factor: The value to multiply the visibility by when player uses a melee weapon (Pass 1.0 to not check for melee weapons)
 * @noreturn
 */
native War3_SetMinVisibility(war3player,visibility=255,Float:melee_factor=1.0);

/**
 * Overrides the speed for War3Source, useful for punishing them or whatever.
 * Pass 0.0 as speed when you want the War3Source system to take over again, make sure to do this when they are no longer supposed to follow!
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param speed: The speed you want to pass.
 * @noreturn
 */
native War3_SetOverrideSpeed(war3player,Float:speed=0.0);

/**
 * Overrides the gravity for War3Source, useful for punishing them or whatever.
 * Pass 0.0 as gravity when you want the War3Source system to take over again, make sure to do this when they are no longer supposed to follow!
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param gravity: The gravity you want to pass.
 * @noreturn
 */
native War3_SetOverrideGravity(war3player,Float:gravity=0.0);

/**
 * Overrides the (in)visibility for War3Source, useful for punishing them or whatever.
 * Pass -1 as visibility when you want the War3Source system to take over again, make sure to do this when they are no longer supposed to follow!
 * @param war3player: The War3Player ID to use. Can be retrieved with War3_GetWar3Player.
 * @param visibility: The visibility you want to pass.
 * @noreturn
 */
native War3_SetOverrideVisibility(war3player,visibility=-1);

/**
 * Called when the plugin is ready.
 */
forward OnWar3PluginReady();
 
/**
 * Gets called when the War3Player has been authed.
 * @param client: The client's index.
 * @param war3player: The War3Player ID that was authed.
 */
forward OnWar3PlayerAuthed(client,war3player);

/**
 * Gets called when someone changes their race.
 * @param client: The client's index.
 * @param war3player: The War3Player ID of the client.
 * @param oldrace: The player's old race. 
 * @param newrace: The player's new race.
 */
forward OnRaceSelected(client,war3player,oldrace,newrace);
#define OnRaceChanged OnRaceSelected

/**
 * Gets called when the +ultimate or -ultimate command is called, IT ISNT ALWAYS FOR YOUR RACE, YOU NEED TO CHECK!!!
 * @param client: The client's index.
 * @param war3player: The War3Player ID of the client.
 * @param race: The race for which it was called.
 * @param pressed: If true, +ultimate, false, -ultimate.
 */
forward OnUltimateCommand(client,war3player,race,bool:pressed);

/**
 * Gets called when a player purchases an item.
 * @param client: The client's index.
 * @param war3player: The War3Player ID of the client.
 * @param item: The item that was purchased.
 */
forward OnItemPurchase(client,war3player,item);

/**
 * Gets called when a skill level is changed.
 * @param client: The client's index.
 * @param war3player: The War3Player ID of the client.
 * @param race: The race effected.
 * @param skill: The skill effected.
 * @param oldskilllevel: The old skill level.
 * @param newskilllevel: The new skill level.   
 */
forward OnSkillLevelChanged(client,war3player,race,skill,oldskilllevel,newskilllevel);
