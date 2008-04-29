/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: SourceCraft.inc
 * Description: Definitions for SourceCraft Natives.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

#include "sc/immunity"
#include "sc/visibility"

#if defined sourcecraft_included
 #endinput
#endif
#define sourcecraft_included

/**
 * Registers a race with the SourceCraft plugin
 * @param name: The name of the race. (max 64)
 * @param short: The short name of the race. (max 16) 
 * @param switchmessage_instant: The message displayed to the player when they are switched to a new race. (max 192)
 * @param switchmessage_dead: The message displayed to the play when they try to switch to the race, but they are alive so they need to wait until they die or the new round. (max 192)
 * @param required_level: The overeall level the player must obtain before changing to this race. (default is 0)
 * @param max_level: The maximum level the race can attain. (default is 16)
 * @return The return value will be the race index or -1 if there was a problem.
 */         
native CreateRace(String:name[],String:short[],String:switchmessage_instant[],String:switchmessage_dead[],
                  required_level=0,max_level=16);

/**
 * Adds an upgrade to a race
 * @param race: The race ID returned from CreateRace
 * @param name: The name of the upgrade. (max 64)
 * @param short: The short name of the upgrade. (max 16) 
 * @param desc: The description of the upgrade. (max 192)
 * @param ultimate: Set to true to indicate upgrade is an ultimate. (default is false)
 * @param required_level: The race level required before this upgrade becomes available.
 *                        (default is the minumum ultimate level {usually 8} and 0 for all others)
 * @param max_level: The maximum level the upgrade can attain. (default is 4)
 * @return The return value will be the upgrade index or -1 if there was a problem.
 */         
native AddUpgrade(race,String:name[],String:short[],String:desc[],
                  bool:ultimate=false,required_level=-1,max_level=4);

/**
 * Registers a shop item with the SourceCraft plugin
 * @param name: The name of the item. (max 64)
 * @param short: The short name of the item. (max 16) 
 * @param desc: The description of the item. (max 256) 
 * @param cost: The cost of the item.
 * @param max: The maximum number of this item that the player can own.
 * @param required_level: The overall level the player must obtain before buying this item.
 * @return The return value will be the item index or -1 if there was a problem.
 */         
native CreateShopItem(String:name[],String:short[],String:desc[],cost,max=1,required_level=0);

/**
 * Registers a help command with the SourceCraft plugin for help
 * @param name: The name of the command. (max 64)
 * @param desc: The description of the command. (max 256) 
 * @return The return value will be the help index or -1 if there was a problem.
 */
native CreateHelpCommand(String:name[],String:desc[]);

/**
 * Find the ShopItem ID of a shop item
 * @param name: The name of the item. (max 64)
 * @return The return value will be the item index or -1 if there was a problem.
 */         
native FindShopItem(String:name[]);

/**
 * Give health to (heal) a player
 * @param client: The client's index you want.
 * @param amount: The amount of health to give to the client.
 * @param health: The health of the client (looks up if not provided).
 * @param max:    The max health of the client (looks up if not provided).
 * @noreturn
 * native HealPlayer(client, amount,health=-1,max=-1);
 */
native HealPlayer(client, amount,health=-1,max=-1);

/**
 * Take health from (damage) a player
 * @param victim: The victim's index you want.
 * @param damage: The amount to damage to deal to the victim.
 * @param attacker: The index of the attacker.
 * @param weapon_name: The name of the weapon used to deal the damage to the client.
 * @param weapon_desc: The description of the weapon used to deal the damage to the client.
 * @param xp: Amount of extra xp for a kill.
 * @noreturn
 */
native HurtPlayer(victim, damage, attacker=0, const String:weapon_name[]="",
                  const String:weapon_desc[]="", xp=0);

/**
 * Kill a player.
 * @param victim: The victim's index.
 * @param attacker: The index of the attacker.
 * @param weapon_name: The name of the weapon used to deal the damage to the client.
 * @param weapon_desc: The description of the weapon used to deal the damage to the client.
 * @param xp: Amount of extra xp for a kill.
 * @noreturn
 */
native KillPlayer(victim, attacker=0, const String:weapon_name[]="",
                  const String:weapon_desc[]="", xp=0);

/**
 * Gets the Player Handle used for the rest of the interface natives.
 * @param client: The client's index you want.
 * @return The return value will be the Player Handle, INVALID_HANDLE on failure.
 */
native Handle:GetPlayerHandle(client);

/**
 * Gets the current level for the provided race.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @return The return value will be the level, if -1 then it failed.
 */
native GetLevel(Handle:player,race=-1);

/**
 * Sets the current level for the provided race.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @param newlevel: The level you want to set to 
 * @noreturn
 */
native SetLevel(Handle:player,race,newlevel);

/**
 * Resets the current level for the provided race, also adjusts Upgrade levels as required.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @param newlevel: The level you want to set to 
 * @noreturn
 */
native ResetLevel(Handle:player,race,newlevel);

/**
 * Gets the current race for the player.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @return The return value will be the race of the player, if -1 then it failed.
 */
native GetRace(Handle:player);

/**
 * Gets the XP for the provided race.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @return The return value will be the xp, if -1 then it failed.
 */
native GetXP(Handle:player,race=-1);

/**
 * Sets the XP for the provided race.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @param newxp: The XP you want to set to 
 * @noreturn
 */
native SetXP(Handle:player,race,newxp);

/**
 * Resets the XP for the provided race, also adjusts Levels and Upgrades as required.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @param newxp: The XP you want to set to 
 * @noreturn
 */
native ResetXP(Handle:player,race,newxp);

/**
 * Gets the current level for the upgrade for the provided race.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @param upgrade: The upgrade you want to lookup with, (0==upgrade1,1==upgrade2,2==upgrade3,3==ultimate) 
 * @return The return value will be the upgrade level, if -1 then it failed.
 */
native GetUpgradeLevel(Handle:player,race,upgrade);

/**
 * Sets the current level for the upgrade for the provided race.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace or -1 for current race
 * @param upgrade: The upgrade you want to lookup with, (0==upgrade1,1==upgrade2,2==upgrade3,3==ultimate) 
 * @param newlevel: The level you want to set to 
 * @noreturn
 */
native SetUpgradeLevel(Handle:player,race,upgrade,newlevel);

/**
 * Resets the levels for the upgrade for the curerent race.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @noreturn
 */
native ResetSetUpgradeLevels(Handle:player);

/**
 * Gets the amount of Credits a player has.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @return The return value will be the xp, if -1 then it failed.
 */
native GetCredits(Handle:player);

/**
 * Sets the amunt of Credits a player has.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param newcredits: The XP you want to set to 
 * @noreturn
 */
native SetCredits(Handle:player,newcredits);

/**
 * Gets the player's current overall level. (Total level of all races)
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @return The return value will be the overall level, if -1 then it failed.
 */
native GetOverallLevel(Handle:player);

/**
 * Sets the player's overall level.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param newlevel: The level you want to set to 
 * @noreturn
 */
native SetOverallLevel(Handle:player,newlevel);

/**
 * Gets if the player owns a specific item.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param item: The item ID returned from CreateShopItem
 * @return The return value will be 1 if they own it, if 0 they don't, if -1 then it failed.
 */
native GetOwnsItem(Handle:player,item);

/**
 * Sets if the player owns a specific item.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param item: The item ID returned from CreateShopItem
 * @param owns: 1 if you want them to own it, 0 if you want them not to own it 
 * @noreturn
 */
native SetOwnsItem(Handle:player,item,owns=1);

/**
 * Gets the state of a certain immunity.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param immunity: The immunity you want to check. 
 * @return The return value will be 1 if they are immune, if 0 they aren't, if -1 then it failed.
 */
native GetImmunity(Handle:player,Immunity:immunity);

/**
 * Sets if the player owns a specific item.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param immunity: The immunity you want to set.
 * @param imm_state: The state of immunity, 1 if they are, 0 if they aren't.
 * @noreturn
 */
native SetImmunity(Handle:player,Immunity:immunity,imm_state=1);

/**
 * Sets the speed for the player that is handled within the SourceCraft system,
 * good for upgrades and items that set speed so you don't end up making the player slower.
 * Pass -1.0 as speed when they no longer should use the speed, make sure to do this when
 * they no longer have the upgrade or item, or whatever.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param speed: The speed you want to pass.
 * @param apply: Set to true to apply the setting immedately.
 * @noreturn
 */
native SetSpeed(Handle:player,Float:speed=-1.0,bool:apply=false);

/**
 * Sets the gravity for the player that is handled within the SourceCraft system,
 * good for upgrades and items that set gravity so you don't end up making the player jump lower.
 * Pass -1.0 as gravity when they no longer should use the gravity, make sure to do this when
 * they no longer have the upgrade or item, or whatever.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param gravity: The gravity you want to pass.
 * @param apply: Set to true to apply the setting immedately.
 * @noreturn
 */
native SetGravity(Handle:player,Float:gravity=-1.0,bool:apply=false);

/**
 * Sets the visibility for the player that is handled within the SourceCraft system,
 * good for upgrades and items that set (in)visibility so you don't end up making the player
 * more visibile. Pass 255 as visibility when they no longer should use the (in)visibility,
 * make sure to do this when they no longer have the upgrade or item, or whatever.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param visibility: The visibility you want to pass.
 * @param type: The type of visibility to use.
 * @param factor1: The 1st factor (either melee factor or activation delay)
 * @param factor2: The 2nd factopr (either movement factor or duration)
 * @param mode: The Render mode
 * @param fx: The Render Fx
 * @param r: Red Component.
 * @param g: Green Component.
 * @param b: Blue Component.
 * @param apply: Set to true to apply the setting immedately.
 * @noreturn
 */
native SetVisibility(Handle:player,visibility=-1,
                     VisibilityType:type=VisibilityType:-1,
                     Float:factor1=-1.0,Float:factor2=-1.0,
                     RenderMode:mode=RenderMode:-1,
                     RenderFx:fx=RenderFx:-1,
                     r=-1,g=-1,b=-1,
                     bool:colorWeapons=false,
                     bool:apply=false);

/**
 * Overrides the speed for SourceCraft, useful for punishing them or whatever.
 * Pass -1.0 as speed when you want the SourceCraft system to take over again,
 * make sure to do this when they are no longer supposed to follow!
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param speed: The speed you want to pass.
 * @param apply: Set to true to apply the setting immedately.
 * @noreturn
 */
native SetOverrideSpeed(Handle:player,Float:speed=-1.0,bool:apply=false);

/**
 * Overrides the gravity for SourceCraft, useful for punishing them or whatever.
 * Pass -1.0 as gravity when you want the SourceCraft system to take over again,
 * make sure to do this when they are no longer supposed to follow!
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param gravity: The gravity you want to pass.
 * @param apply: Set to true to apply the setting immedately.
 * @noreturn
 */
native SetOverrideGravity(Handle:player,Float:gravity=-1.0,bool:apply=false);

/**
 * Overrides the (in)visibility for SourceCraft , useful for punishing them or whatever.
 * Pass -1 as visibility when you want the SourceCraft system to take over again,
 * make sure to do this when they are no longer supposed to follow!
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param visibility: The visibility you want to pass.
 * @param apply: Set to true to apply the setting immedately.
 * @noreturn
 */
native SetOverrideVisiblity(Handle:player,visibility=-1,bool:apply=false);

/**
 * Restores Settings for a player (removes all overrides)
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param apply: Set to true to apply the setting immedately.
 * @noreturn
 */
native RestorePlayer(Handle:player,bool:apply=false);

/**
 * Applies the Speed, Gravity and Visibility settings for all players
 * right away. This function is not required to change the player's state.
 * If this is not called, the settings will be applied automatically within 2 seconds.
 * @noreturn
 */
native ApplyPlayerSettings();

/**
 * Called when the plugin is ready.
 */
forward OnPluginReady();
 
/**
 * Gets called when the player has been authed.
 * @param client: The client's index.
 * @param player: The player handle that was authed.
 */
forward OnPlayerAuthed(client,Handle:player);

/**
 * Gets called when someone changes their race.
 * @param client: The client's index.
 * @param player: The player handle of the client.
 * @param oldrace: The player's old race. 
 * @param newrace: The player's new race.
 */
forward OnRaceSelected(client,Handle:player,oldrace,newrace);
#define OnRaceChanged OnRaceSelected

/**
 * Gets called when the +ultimate or -ultimate command is called,
 * IT ISN'T ALWAYS FOR YOUR RACE, YOU NEED TO CHECK!!!
 * @param client: The client's index.
 * @param player: The player handle of the client.
 * @param race: The race for which it was called.
 * @param pressed: If true, +ultimate, false, -ultimate.
 */
forward OnUltimateCommand(client,Handle:player,race,bool:pressed);

/**
 * Gets called when a player purchases an item.
 * @param client: The client's index.
 * @param player: The player handle of the client.
 * @param item: The item that was purchased.
 */
forward OnItemPurchase(client,Handle:player,item);

/**
 * Gets called when a upgrade level is changed.
 * @param client: The client's index.
 * @param player: The player handle of the client.
 * @param race: The race effected.
 * @param upgrade: The upgrade effected.
 * @param oldupgradelevel: The old upgrade level.
 * @param newupgradelevel: The new upgrade level.   
 */
forward OnUpgradeLevelChanged(client,Handle:player,race,upgrade,oldupgradelevel,newupgradelevel);

/**
 * Gets called when XP is given to a player
 * @param client: The client's index.
 * @param player: The player handle of the client.
 * @param amount: The amount given (updateable).
 * @param taken: The amount is to be taken instead of given.
 */
forward OnXPGiven(client,Handle:player,&amount,bool:taken);

/**
 * Gets called when credits are given to a player
 * @param client: The client's index.
 * @param player: The player handle of the client.
 * @param amount: The amount given (updateable).
 * @param taken: The amount is to be taken instead of given.
 */
forward OnCreditsGiven(client,Handle:player,&amount,bool:taken);

/**
 * Gets called for player_hurt
 * @param victim_index: The victim's index.
 * @param victim_player: The player handle of the victim.
 * @param attacker_race: The race of the victim.
 * @param attacker_index: The attacker's index.
 * @param attacker_player: The player handle of the attacker.
 * @param attacker_race: The race of the attacker.
 * @param assister_index: The attacker's assister.
 * @param assister_player: The player handle of the assister.
 * @param assister_race: The race of the assister.
 * @param damage: The amount of damage infliced on the victim.
 */
forward Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage);

/**
 * Gets called for player_death
 * @param victim_index: The victim's index.
 * @param victim_player: The player handle of the victim.
 * @param attacker_race: The race of the victim.
 * @param attacker_index: The attacker's index.
 * @param attacker_player: The player handle of the attacker.
 * @param attacker_race: The race of the attacker.
 * @param assister_index: The attacker's assister.
 * @param assister_player: The player handle of the assister.
 * @param assister_race: The race of the assister.
 * @param damage: The amount of damage infliced on the victim.
 * @param weapon: The weapon used by the attacker.
 * @param is_equipment: Set to true if weapon is client weapon, false if from event.
 * @param customkill: The custom kill value from TF2.
 * @param headshot: Set to true for headshots.
 * @param backstab: Set to true for backstabs.
 * @param melee: Set to true when a melee weapon (knife, etc) was used.
 */
forward Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                  attacker_index,Handle:attacker_player,attacker_race,
                                  assister_index,Handle:assister_player,assister_race,
                                  damage,const String:weapon[],bool:is_equipment,
                                  customkill,bool:headshot,bool:backstab,bool:melee);

/**
 * Gets called when an object is killed (destroyed).
 * @param attacker: The attacker's index.
 * @param builder: The builder's index.
 * @param player: The player handle of the client.
 * @param object: The object.   
 */
forward OnObjectKilled(attacker, builder,const String:object[]);

/**
 * Do not edit below this line!
 */

public SharedPlugin:__pl_sourcecraft = 
{
	name = "sourcecraft",
	file = "sourcecraft.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_sourcecraft_SetNTVOptional()
{
	MarkNativeAsOptional("CreateRace");
	MarkNativeAsOptional("AddUpgrade");
	MarkNativeAsOptional("CreateShopItem");
	MarkNativeAsOptional("CreateHelpCommand");
	MarkNativeAsOptional("FindShopItem");
	MarkNativeAsOptional("HealPlayer");
	MarkNativeAsOptional("HurtPlayer");
	MarkNativeAsOptional("KillPlayer");
	MarkNativeAsOptional("GetPlayerHandle");
	MarkNativeAsOptional("GetLevel");
	MarkNativeAsOptional("SetLevel");
	MarkNativeAsOptional("ResetLevel");
	MarkNativeAsOptional("GetRace");
	MarkNativeAsOptional("GetXP");
	MarkNativeAsOptional("SetXP");
	MarkNativeAsOptional("ResetXP");
	MarkNativeAsOptional("GetUpgradeLevel");
	MarkNativeAsOptional("SetUpgradeLevel");
	MarkNativeAsOptional("ResetSetUpgradeLevels");
	MarkNativeAsOptional("SetCredits");
	MarkNativeAsOptional("GetOverallLevel");
	MarkNativeAsOptional("SetOverallLevel");
	MarkNativeAsOptional("GetOwnsItem");
	MarkNativeAsOptional("SetOwnsItem");
	MarkNativeAsOptional("GetImmunity");
	MarkNativeAsOptional("SetImmunity");
	MarkNativeAsOptional("SetSpeed");
	MarkNativeAsOptional("SetGravity");
	MarkNativeAsOptional("SetVisibility");
	MarkNativeAsOptional("SetOverrideSpeed");
	MarkNativeAsOptional("SetOverrideGravity");
	MarkNativeAsOptional("SetOverrideVisiblity");
	MarkNativeAsOptional("RestorePlayer");
	MarkNativeAsOptional("ApplyPlayerSettings");
}
#endif
