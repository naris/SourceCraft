/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: shields.inc
 * Description: The Shields Upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _shields_included
 #endinput
#endif
#define _shields_included

#include <entlimit>
#include "sc/armor"

//Uncomment this to enable shield particles effects.
//#define ENABLE_SHIELD_PARTICLES

// Define Shield aliases for Armor functions
#define SetShields          SetArmorAmount
#define GetShields          GetArmor
#define SetShieldsPercent   SetArmorPercent

/**
 * Sets up the amount of shields the client has, an alias for SetupArmor()
 *
 * @param client 	    Client
 * @param level         The upgrade level used to index into the initialArmor[] array
 * @param initialArmor  Array of initial armor amounts for each level (as percent of health).
 * @param armorPercent  Array that holds a range of percent damage the armor absorbs for each level.
 * @param regenRate:    The rate to regenerate shields per 1.0 second tick (-1.0 = same as level)
 * @param flags         The ArmorFlags (set Armor_Check* to check restrictions before regenerating)
 * @param upgrade       Set true if shields are being upgraded
 * @return			    Amount of armor given.
 */
stock SetupShields(client, level, const Float:initialArmor[],
                   const Float:armorPercent[][2], Float:regenRate=-1.0,
                   ArmorFlags:flags=Armor_IsShield, maxShields=-1,
                   bool:upgrade=false)
{
    new amount = SetupArmor(client, level, initialArmor, armorPercent,
                            "Shields", flags, maxShields, upgrade);

    SetShieldRegen(client, (regenRate >= 0.0) ? regenRate : float(level));
    return amount;
}

/**
 * Sets up the amount of armor the client has when they also have shields
 *
 * @param client 	    Client
 * @param armor_level   The armor level used to index into the initialArmor[] array
 * @param shields_level The shields level used to index into the maxShields[] array
 * @param initialArmor  Array of initial armor amounts for each level (as percent of health).
 * @param maxShields    Array of maximum shield amounts for each level (as percent of health).
 * @param armorPercent  Array that holds a range of percent damage the armor absorbs for each level.
 * @param armorName:    What to call the armor in messages. (max 64) [defaults to Shields]
 * @param flags         The ArmorFlags (set Armor_Check* to check restrictions before regenerating)
 * @param upgrade       Set true when upgrading
 * @return			    Amount of armor given.
 */
stock SetupArmorAndShields(client, armor_level, shields_level, const Float:initialArmor[],
                           const Float:armorPercent[][2], const Float:maxShields[],
                           ArmorFlags:flags=Armor_IsShield, bool:upgrade=false)
{
    new amount = 0;
    ResetMaxHealth(client);
    if (armor_level > 0 || shields_level > 0)
    {
        new maxhp = GetPlayerMaxHealth(client);
        amount = RoundFloat(float(maxhp)*(initialArmor[armor_level]+maxShields[shields_level]));
    }

    if (upgrade)
    {
        new oldArmor = m_savedArmor[client];
        if (amount > oldArmor)
            amount = oldArmor;
        else
        {
            new armor = GetArmor(client);
            if (armor > m_savedArmor[client])
                m_savedArmor[client] = armor;
        }
    }
    else
        m_savedArmor[client] = amount;

    new bool:hasShields = (shields_level > 0);
    new level = (armor_level > shields_level) ? armor_level : shields_level;
    SetArmor(client, amount, armorPercent[level],
             (hasShields) ? "Shields" : "Armor",
             (hasShields) ? flags : Armor_Default);
    return amount;
}

/**
 * Resets Shields (turns them off)
 *
 * @param client 	Client
 * @return			none
 */
stock ResetShields(client)
{
    ResetArmor(client);
    SetShieldRegen(client, 0.0);
}
