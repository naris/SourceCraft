/**
* vim: set ai et ts=4 sw=4 syntax=sourcepawn :
* =============================================================================
* File: sc/Hallucinate.inc
* Description: SourceCraft Helper functions for Hallucinate
*/

#if defined schallucinate_included
 #endinput
#endif
#define schallucinate_included

#include <ResourceManager>
#include <Hallucinate>

#include "sc/client"

stock const String:cureWav[] = "sc/ptehal01.wav";
stock const String:hallucinateWav[] = "sc/ptehal00.wav";

stock SetupHallucinate()
{
    SetupSound(cureWav);
    SetupSound(hallucinateWav);
}

stock bool:Hallucinate(victim_index, index, level, Float:amount,
                       const hallucinateChance[])
{
    if (IsValidClient(victim_index) &&
        !GetRestriction(index, Restriction_NoUpgrades) &&
        !GetRestriction(index, Restriction_Stunned) &&
        !GetImmunity(victim_index,Immunity_Blindness) &&
        !GetImmunity(victim_index,Immunity_Upgrades) &&
        !GetImmunity(victim_index,Immunity_Restore))
    {
        if (GetRandomInt(1,100) <= hallucinateChance[level])
        {
            new Float:energy = GetEnergy(index);
            if (energy >= amount)
            {
                if (GetSetting(victim_index,Remove_Queasiness) ||
                    GetImmunity(victim_index,Immunity_Drugs))
                {
                    PerformBlind(victim_index, 225);
                    SetEnergy(index, energy-amount);
                    CreateTimer(5.0+(float(level)*2.0),UnblindPlayer,
                                GetClientUserId(victim_index),
                                TIMER_FLAG_NO_MAPCHANGE);
                }
                else
                {
                    if (PerformDrug(victim_index, 1,
                                    GetSetting(victim_index,Reduce_Queasiness)
                                    ? DRUG_CRAZY : DRUG_RANDOM))
                    {
                        PrepareAndEmitSoundToAll(hallucinateWav,index);
                        DisplayMessage(victim_index, Display_Enemy_Message,
                                       "%t", "YouAreHallucinating", index);

                        DisplayMessage(index, Display_Message,
                                       "%t", "IsHallucinating", victim_index);

                        CreateTimer(float(level)*2.0,CurePlayer,
                                    GetClientUserId(victim_index),
                                    TIMER_FLAG_NO_MAPCHANGE);

                        SetEnergy(index, energy-amount);
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

public Action:CurePlayer(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        PrepareAndEmitSoundToAll(cureWav,client);
        PerformDrug(client, 0);
    }
    return Plugin_Stop;
}

public Action:UnblindPlayer(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        PrepareAndEmitSoundToAll(cureWav,client);
        PerformBlind(client, 0);
    }
    return Plugin_Stop;
}

