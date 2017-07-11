/**
 * File: War3Source_XP_Gold.inc
 * Description: Stocks regarding XP and Gold
 * Author(s): War3Source Team  
 */

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

/**
 * Gets the kill XP for a player depending on his CURRENT level 
 * @param client: Client index
 * adds extra xp per leveldifference if cvar is configured
 */
#if !defined SOURCECRAFT
native W3GetKillXP(client, leveldifference = 0);
native W3GetReqXP(level); //get required xp for leveling to the level, use (level+1) for xp required for next level
#else
stock W3GetKillXP(client,leveldifference=0)
{
    new xp=GetKillXP(client)+leveldifference;
    new max=GetReqLevelXP(GetLevel(client)+1);
    return (xp < max) ? xp : max;
}

#define W3GetReqXP GetReqLevelXP
#endif

/**
 * Shows the XP and race message in chat
 * @param client: Client index
 * @noreturn
 */
#if !defined SOURCECRAFT
native War3_ShowXP(client);
#else
#define War3_ShowXP ShowXP
#endif

//nothing happens if you give 0 xp 0 gold
//automatically prints gained or lost xp/gold
#if !defined SOURCECRAFT // Not Implemented!
native W3GiveXPGold(client,W3XPAwardedBy:awardreason=XPAwardByGeneric,xpamount=0,goldamount=0,String:awardstringreason[]);
#endif

//=======================================================================
//                             FORWARDS
//=======================================================================
