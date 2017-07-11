/**
 * File: War3Source_Shopitems.inc
 * Description: Stocks regarding Shopitems
 * Author(s): War3Source Team  
 */

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

/**
 * Registers a shop item with the War3Source plugin
 * @param name: The name of the item. 
 * @param shortname: the shortname of the item, must be unique
 * @param desc: The description of the item. 
 * @param cost: The cost of the item 
 * @param lost_upon_death: If true the item will automatically be removed when the player dies. Defaults to true
 * @return The return value will be the item index or -1 if there was a problem.
 */
#if !defined SOURCECRAFT
native War3_CreateShopItem(String:name[], String:shortname[], String:desc[], cost, bool:lost_upon_death=true);
#else
stock War3_CreateShopItem(const String:name[], const String:shortname[], const String:desc[], cost, bool:lost_upon_death=true)
{
    CreateShopItem(shortname, cost, .name=name, .desc=desc);
}
#endif

//translated
#if !defined SOURCECRAFT
native War3_CreateShopItemT(String:shortname[], cost, bool:lost_upon_death=true);
#else
stock War3_CreateShopItemT(const String:shortname[], cost, bool:lost_upon_death=true)
{
    CreateShopItem(shortname, cost);
}
#endif

#if !defined SOURCECRAFT // Not Implemented!
//see W3ItemProp enum for available properties
native War3_SetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY,value);
native War3_GetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY);
#endif

//remember itemid that is valid is more than 0
//returns -1 if not found
#if !defined SOURCECRAFT
native War3_GetItemIdByShortname(String:itemshortname[]);

native W3GetItemName(itemid,String:ret[],maxlen);
native W3GetItemShortname(itemid,String:ret[],maxlen);
native W3GetItemDescription(itemid,String:ret[],maxlen);
#else
#define War3_GetItemIdByShortname FindShopItem

#define W3GetItemName GetItemName
#define W3GetItemShortname GetItemShortName
#define W3GetItemDescription GetItemDescription
#endif

#if !defined SOURCECRAFT // Not Implemented!
native W3GetItemCost(itemid);
native W3GetItemOrder(itemid);
native W3ItemHasFlag(itemid,String:flagsearch[]);
#endif

#if !defined SOURCECRAFT
native W3GetItemCategory(itemid,String:retcatagorystr[],maxlen);
native W3GetItemsLoaded(); //how many items are loaded?
#else
#define W3GetItemCategory GetItemCategory
#define W3GetItemsLoaded GetShopItemCount
#endif

#if !defined SOURCECRAFT // Not Implemented!
native bool:W3IsItemDisabledGlobal(itemid);
native bool:W3IsItemDisabledForRace(race,itemid);
#endif

#if !defined SOURCECRAFT // Not Implemented!
native GetClientItemsOwned(client);
native GetMaxShopitemsPerPlayer();
#endif

//max gold a player can have (cvar read)
#if !defined SOURCECRAFT
native W3GetMaxGold();
#else
#define W3GetMaxGold GetMaxCrystals
#endif

/**
 * Gets if the player owns a specific item.
 * @param client: Client index
 * @param item: The item ID returned from War3_CreateShopItem
 * @return The return value will be 1 if they own it, if 0 they don't, if -1 then it failed.
 */
#if !defined SOURCECRAFT
native War3_GetOwnsItem(client, item);
native War3_SetOwnsItem(client,item,bool:ownsitem);
#else
#define War3_GetOwnsItem GetOwnsItem
#define War3_SetOwnsItem SetOwnsItem
#endif

/**
 * After a player has died and this command is invoked they will
 * try to buy all their previously owned items again

 * @param client: Client index
 */
#if !defined SOURCECRAFT // Not Implemented!
native War3_RestoreItemsFromDeath(client);
#endif

//=======================================================================
//                             FORWARDS
//=======================================================================

/**
 * Gets called when a player purchases an item.
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS OWNERSHIP BY THIS POINT  
 */
#if !defined SOURCECRAFT
forward OnItemPurchase(client, item);
#else
// defined in SourceCraft.inc
#endif

/**
 * Gets called when a player loses an item. (after death (ownership to false) or traded it back..)
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS LOST OWNERSHIP BY THIS POINT   
 */
#if !defined SOURCECRAFT
forward OnItemLost(client, item);
#else
// defined in SourceCraft.inc
#endif
