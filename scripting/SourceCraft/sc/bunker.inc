/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: bunker.inc
 * Description: The Terran Bunker upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _bunker_included
 #endinput
#endif
#define _bunker_included

#include <gametype>
#include <tf2_flag>
#include <lib/ResourceManager>

#include "sc/ShopItems"
#include "sc/burrow"
#include "sc/sounds"
#include "sc/armor"

#define LeaveBunker         UnBurrow
#define InBunker            IsBurrowed
#define ResetBunker         ResetBurrow

#define SetupBunker()       SetupDeniedSound()

/**
 * Add the Terran Bunker upgrade to a race.
 *
 * @param raceId 	        Race to add Bunker to.
 * @param category:         Ultimate Category to use. (default is 2)
 * @param required_level:   Level required to upgrade Bunker. (default is 8)
 * @param energy:           Amount of energy required to invoke Bunker. (default is 30)
 * @param cooldown:         Duration of the cooldown. (default is 5.0)
 * @param cost_crystals:    Amount of crystals required to purchase Bunker for 1 map. (default is 10)
 * @return                  The return value will be the upgrade index or -1 if there was a problem.
 */
stock AddBunkerUpgrade(raceId, category=2, required_level=8, Float:energy=30.0,
                       Float:cooldown=5.0, cost_crystals=10)
{
    LoadTranslations("sc.bunker.phrases.txt");

    return AddUpgrade(raceId, "bunker", category, required_level, .energy=energy,
                      .cooldown=cooldown, .cost_crystals=cost_crystals);
}

/**
 * The client Enters (or Leaves) the Bunker,
 * depending on if they are already in the Bunker.
 *
 * @param client 	Client
 * @param armor:    The amount of additional armor provided by the Bunker.
 * @return			none
 */
stock EnterBunker(client, armor, raceId, upgradeId)
{
    if (InBunker(client))
    {
        Burrow(client, 4, 2, armor, "Bunker");
        DisplayMessage(client,Display_Ultimate,
                       "%t", "LeftBunker");

        CreateCooldown(client, raceId, upgradeId);
    }
    else if (IsMole(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "CantEnterBunkerAsMole");
    }
    else if (GetGameType() == tf2 && TF2_HasTheFlag(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "CantEnterBunkerWithFlag");
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "PreventedFromEnteringBunker");
    }
    else if (CanInvokeUpgrade(client, raceId, upgradeId, false))
    {
        if (Burrow(client, 4, 2, armor, "Bunker"))
        {
            ChargeForUpgrade(client, raceId, upgradeId);
            CreateCooldown(client, raceId, upgradeId);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "EnteredBunker");
        }
    }
}
