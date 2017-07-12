/**
 * vim: set ai et ts=4 sw=4 :
 * File: PsionicRage.inc
 * Description: The Psionic Rage Upgrade for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _PsionicRage_included
 #endinput
#endif
#define _PsionicRage_included

#include <lib/ResourceManager>
#include "sc/shields"
#include "sc/sounds"

#define SetupPsionicRage() SetupDeniedSound()

stock Float:m_PsionicRageTime = 2.0;

stock static m_raceId, m_upgradeId;
stock static String:m_RageExpireSound[PLATFORM_MAX_PATH];
stock bool:m_RageActive[MAXPLAYERS+1];

PsionicRage(client, raceId, upgradeId, level,
            const String:activeSound[],
            const String:expireSound[])
{
    if (level > 0)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);

        if (GetRestriction(client,Restriction_NoUltimates) ||
            GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t",
                           "Prevented", upgradeName);
        }
        else if (CanInvokeUpgrade(client, raceId, upgradeId))
        {
            SetEnergy(client, 0.0);
            SetShields(client, 0);

            m_raceId = raceId;
            m_upgradeId = upgradeId;
            m_RageActive[client] = true;
            TF2_SetPlayerPowerPlay(client, true);
            strcopy(m_RageExpireSound, sizeof(m_RageExpireSound), expireSound);
            CreateTimer(m_PsionicRageTime * float(level), EndRage, GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);

            HudMessage(client, "%t", "RageHud");
            PrintHintText(client, "%t", "YouAreRaging");

            PrepareAndEmitSoundToAll(activeSound,client);
        }
    }
}

public Action:EndRage(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClient(client) && m_RageActive[client])
    {
        m_RageActive[client]=false;
        TF2_SetPlayerPowerPlay(client, false);
        SetEnergy(client, 0.0);
        SetShields(client, 0);

        if (IsPlayerAlive(client))
        {
            PrepareAndEmitSoundToAll(m_RageExpireSound,client);
            PrintHintText(client, "%t", "YouStoppedRaging");
        }

        decl String:message[64];
        Format(message, sizeof(message), "%T", "RageHud", client);
        ReplaceString(message, sizeof(message), "*", "");
        ReplaceString(message, sizeof(message), " ", "");
        ClearHud(client, message);

        CreateCooldown(client, m_raceId, m_upgradeId,
                       .type=Cooldown_CreateNotify
                            |Cooldown_AlwaysNotify);
    }
}

