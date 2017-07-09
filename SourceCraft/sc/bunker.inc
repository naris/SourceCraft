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

#include <ResourceManager>
#include <gametype>
#include <tf2_flag>

#include "sc/ShopItems"
#include "sc/burrow"
#include "sc/sounds"
#include "sc/armor"

#define LeaveBunker         UnBurrow
#define InBunker            IsBurrowed
#define ResetBunker         ResetBurrow

#define SetupBunker()       SetupDeniedSound()

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
