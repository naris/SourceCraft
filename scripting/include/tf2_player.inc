/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_player.inc
 * Description: Stocks to return information about TF2 player condition, etc.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _tf2_player_included
 #endinput
#endif
#define _tf2_player_included

#include <tf2_stocks>
#include "weapons"

stock const String:TF2_TeamName[TFTeam][] = { "Unassigned", "Spectator", "Red", "Blue" };
#define TF2_GetTeamName(%1) TF2_TeamName[%1]

stock const String:TF2_ClassName[TFClassType][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic",
                                                   "Heavy", "Pyro", "Spy", "Engineer" };
#define TF2_GetClassName(%1) TF2_ClassName[%1]

stock const TF2_ClassHealth[TFClassType] = { 0, 125, 125, 200, 175, 150, 300, 175, 125, 125 };
#define TF2_GetClassHealth(%1) TF2_ClassHealth[%1]

//stock const Float:TF2_ClassSpeed[TFClassType] = { 0.0, 400.0, 300.0, 240.0, 280.0, 320.0, 230.0, 300.0, 300.0, 300.0 };
stock const Float:TF2_ClassSpeed[10] = { 0.0, 400.0, 300.0, 240.0, 280.0, 320.0, 230.0, 300.0, 300.0, 300.0 };
#define TF2_GetClassSpeed(%1) TF2_ClassSpeed[%1]

#define TF2_IsPlayerSlowed(%1)              TF2_IsPlayerInCondition(%1,TFCond_Slowed)
#define TF2_IsPlayerZoomed(%1)              TF2_IsPlayerInCondition(%1,TFCond_Zoomed)
#define TF2_IsPlayerDisguising(%1)          TF2_IsPlayerInCondition(%1,TFCond_Disguising)
#define TF2_IsPlayerDisguised(%1)           TF2_IsPlayerInCondition(%1,TFCond_Disguised)
#define TF2_IsPlayerCloaked(%1)             TF2_IsPlayerInCondition(%1,TFCond_Cloaked)
#define TF2_IsPlayerUbercharged(%1)         TF2_IsPlayerInCondition(%1,TFCond_Ubercharged)
#define TF2_IsPlayerTeleportedGlow(%1)      TF2_IsPlayerInCondition(%1,TFCond_TeleportedGlow)
#define TF2_IsPlayerTaunting(%1)            TF2_IsPlayerInCondition(%1,TFCond_Taunting)
#define TF2_IsPlayerUberchargeFading(%1)    TF2_IsPlayerInCondition(%1,TFCond_UberchargeFading)
#define TF2_IsPlayerCloakFlicker(%1)        TF2_IsPlayerInCondition(%1,TFCond_CloakFlicker)
#define TF2_IsPlayerTeleporting(%1)         TF2_IsPlayerInCondition(%1,TFCond_Teleporting)
#define TF2_IsPlayerKritzkrieged(%1)        TF2_IsPlayerInCondition(%1,TFCond_Kritzkrieged)
#define TF2_IsPlayerTmpDamageBonus(%1)      TF2_IsPlayerInCondition(%1,TFCond_TmpDamageBonus)
#define TF2_IsPlayerDeadRingered(%1)        TF2_IsPlayerInCondition(%1,TFCond_DeadRingered)
#define TF2_IsPlayerBonked(%1)              TF2_IsPlayerInCondition(%1,TFCond_Bonked)
#define TF2_IsPlayerDazed(%1)               TF2_IsPlayerInCondition(%1,TFCond_Dazed)
#define TF2_IsPlayerBuffed(%1)              TF2_IsPlayerInCondition(%1,TFCond_Buffed)
#define TF2_IsPlayerCharging(%1)            TF2_IsPlayerInCondition(%1,TFCond_Charging)
#define TF2_IsPlayerDemoBuff(%1)            TF2_IsPlayerInCondition(%1,TFCond_DemoBuff)
#define TF2_IsPlayerCritCola(%1)            TF2_IsPlayerInCondition(%1,TFCond_CritCola)
#define TF2_IsPlayerInHealRadius(%1)        TF2_IsPlayerInCondition(%1,TFCond_InHealRadius)
#define TF2_IsPlayerHealing(%1)             TF2_IsPlayerInCondition(%1,TFCond_Healing)
#define TF2_IsPlayerOnFire(%1)              TF2_IsPlayerInCondition(%1,TFCond_OnFire)
#define TF2_IsPlayerOverhealed(%1)          TF2_IsPlayerInCondition(%1,TFCond_Overhealed)
#define TF2_IsPlayerJarated(%1)             TF2_IsPlayerInCondition(%1,TFCond_Jarated)
#define TF2_IsPlayerBleeding(%1)            TF2_IsPlayerInCondition(%1,TFCond_Bleeding)
#define TF2_IsPlayerDefenseBuffed(%1)       TF2_IsPlayerInCondition(%1,TFCond_DefenseBuffed)
#define TF2_IsPlayerMilked(%1)              TF2_IsPlayerInCondition(%1,TFCond_Milked)
#define TF2_IsPlayerMegaHealed(%1)          TF2_IsPlayerInCondition(%1,TFCond_MegaHeal)
#define TF2_IsPlayerRegenBuffed(%1)         TF2_IsPlayerInCondition(%1,TFCond_RegenBuffed)
#define TF2_IsPlayerMarkedForDeath(%1)      TF2_IsPlayerInCondition(%1,TFCond_MarkedForDeath)
#define TF2_IsPlayerNoHealingDamageBuff(%1) TF2_IsPlayerInCondition(%1,TFCond_NoHealingDamageBuff)
#define TF2_IsPlayerSpeedBuffAlly(%1)       TF2_IsPlayerInCondition(%1,TFCond_SpeedBuffAlly)
#define TF2_IsPlayerHalloweenCritCandy(%1)  TF2_IsPlayerInCondition(%1,TFCond_HalloweenCritCandy)
#define TF2_IsPlayerCritHype(%1)            TF2_IsPlayerInCondition(%1,TFCond_CritHype)
#define TF2_IsPlayerCritOnFirstBlood(%1)    TF2_IsPlayerInCondition(%1,TFCond_CritOnFirstBlood)
#define TF2_IsPlayerCritOnWin(%1)           TF2_IsPlayerInCondition(%1,TFCond_CritOnWin)
#define TF2_IsPlayerCritOnFlagCapture(%1)   TF2_IsPlayerInCondition(%1,TFCond_CritOnFlagCapture)
#define TF2_IsPlayerCritOnKill(%1)          TF2_IsPlayerInCondition(%1,TFCond_CritOnKill)
#define TF2_IsPlayerRestrictToMelee(%1)     TF2_IsPlayerInCondition(%1,TFCond_RestrictToMelee)

#define TF2_IsPlayerCrit(%1) (TF2_IsPlayerKritzkrieged(%1)       || \
                              TF2_IsPlayerCritCola(%1)           || \
                              TF2_IsPlayerHalloweenCritCandy(%1) || \
                              TF2_IsPlayerCritHype(%1)           || \
                              TF2_IsPlayerCritOnFirstBlood(%1)   || \
                              TF2_IsPlayerCritOnWin(%1)          || \
                              TF2_IsPlayerCritOnFlagCapture(%1)  || \
                              TF2_IsPlayerCritOnKill(%1))

/**
 * Gets a player's estimated speed based on class, weapon and conditions
 *
 * @param client		Player's index.
 * @return				Player's estimated speed
 */
stock Float:TF2_GetPlayerSpeed(client)
{
    new Float:speed;
    new TFClassType:class = TF2_GetPlayerClass(client);
    switch (class)
    {
        case TFClass_Sniper:
        {
            // Is the Snipers's rifle zoomed?
            speed = TF2_IsPlayerSlowed(client) ? 80.0 : 300.0; // TF2_GetClassSpeed(class);
        }
        case TFClass_Soldier:
        {
            new weapon = GetActiveWeapon(client);
            if (weapon > 0 && GetEntProp(weapon,  Prop_Send, "m_iItemDefinitionIndex") == 128)
            {
                // The Equalizer is active
                new health = GetClientHealth(client);
                if (health > 160)
                    speed = 240.0;
                else if (health > 120)
                    speed = 264.0;
                else if (health > 80)
                    speed = 288.0;
                else if (health > 40)
                    speed = 336.0;
                else
                    speed = 384.0;
            }
            else
                speed = 240.0; // TF2_GetClassSpeed(class);
        }
        case TFClass_DemoMan:
        {
            // Is The Scotsman's Skullcutter active?
            new weapon = GetActiveWeapon(client);
            speed = (weapon > 0 && GetEntProp(weapon,  Prop_Send, "m_iItemDefinitionIndex") == 172)
                    ? (TF2_IsPlayerCharging(client) ? 638.0 : 238.0)
                    : (TF2_IsPlayerCharging(client) ? 750.0 : 280.0); // TF2_GetClassSpeed(class));
        }
        case TFClass_Heavy:
        {
            if (TF2_IsPlayerSlowed(client))
                speed = 110.0; // The minigun is spinning
            else if (TF2_IsPlayerCritCola(client))
                speed = 310.0; // Ate Buffalo Steak Sandvitch
            else
            {
                // Are The Heavy's G.R.U.s active?
                new weapon = GetActiveWeapon(client);
                speed =  (weapon > 0 && GetEntProp(weapon,  Prop_Send, "m_iItemDefinitionIndex") == 239)
                         ? 300.0 : 230.0; // TF2_GetClassSpeed(class);
            }
        }
        case TFClass_Pyro:
        {
            speed = TF2_GetClassSpeed(class);

            // Does the Pyro have the Degreaser?
            new primary = GetPlayerWeaponSlot(client, 0);
            if (primary > 0 && GetEntProp(primary,  Prop_Send, "m_iItemDefinitionIndex") == 215)
            {
                // And the Powerjack
                new melee = GetPlayerWeaponSlot(client, 2);
                if (melee > 0 && GetEntProp(melee,  Prop_Send, "m_iItemDefinitionIndex") == 214)
                {
                    // And is wearing the Attendant
                    new item = -1;
                    while ((item = FindEntityByClassname(item, "tf_wearable_item")) != -1)
                    {
                        if (GetEntPropEnt(item, Prop_Send, "m_hOwnerEntity") == client &&
                            GetEntProp(item, Prop_Send, "m_iItemDefinitionIndex") == 213)
                        {
                            speed = 330.0;
                        }
                    }
                }
            }
        }
        case TFClass_Engineer:
        {
            // Is the Engineer toting a building?
            speed = (GetEntPropEnt(client,  Prop_Send, "m_hCarriedObject") > 0)
                    ? 225.0 : 300.0; // TF2_GetClassSpeed(class);
        }
        default:
        {
            speed = TF2_GetClassSpeed(class);
        }
    }

    if (TF2_IsPlayerDazed(client))
        speed *= 0.5;

    if (TF2_IsPlayerSpeedBuffAlly(client))
    {
        speed *= 1.4;
        if (speed > 450.0)
            speed = 450.0;
    }

    return speed;
}

/**
 * Gets a player's estimated max health based on class, weapon and conditions
 *
 * @param client		Player's index.
 * @return				Player's estimated max health
 */
stock TF2_GetPlayerMaxHealth(client)
{
    new TFClassType:class = TF2_GetPlayerClass(client);
    switch (class)
    {
        case TFClass_Scout:
        {
            new melee = GetPlayerWeaponSlot(client, 2);
            if (melee > 0)
            {
                new itemIndex = GetEntProp(melee,  Prop_Send, "m_iItemDefinitionIndex");
                if (itemIndex == 44)
                {
                    // Is The Sandman equipped?
                    return 110;
                }
                else if (itemIndex == 221)
                {
                    // The Scout has the Holy Mackerel,
                    new primary = GetPlayerWeaponSlot(client, 2);
                    if (primary > 0 && GetEntProp(primary,  Prop_Send, "m_iItemDefinitionIndex") == 220)
                    {
                        // and the Shortstop,
                        new item = -1;
                        while ((item = FindEntityByClassname(item, "tf_wearable_item")) != -1)
                        {
                            if (GetEntPropEnt(item, Prop_Send, "m_hOwnerEntity") == client &&
                                GetEntProp(item, Prop_Send, "m_iItemDefinitionIndex") == 222)
                            {
                                // And is wearing Mad Milk!
                                return 150;
                            }
                        }
                    }
                }
            }
        }
        case TFClass_DemoMan:
        {
            new health = TF2_GetClassHealth(class);
            new melee = GetPlayerWeaponSlot(client, 2);
            if (melee > 0)
            {
                new itemIndex = GetEntProp(melee,  Prop_Send, "m_iItemDefinitionIndex");
                if (itemIndex == 132 || itemIndex == 266)
                {
                    // Is The Eyelander or Horseless Headless Horsemann's Headtaker equipped?
                    health = 150 + (GetEntProp(client,  Prop_Send, "m_iDecapitations") * 15);
                }
                else if (itemIndex == 327)
                {
                    // Is The Claidheamh Mor equipped?
                    health = 135 + (GetEntProp(client,  Prop_Send, "m_iDecapitations") * 15);
                }
            }

            new primary = GetPlayerWeaponSlot(client, 0);
            if (primary > 0)
            {
                new itemIndex = GetEntProp(primary,  Prop_Send, "m_iItemDefinitionIndex");
                if (itemIndex == 405)
                {
                    // Are Ali Baba's Wee Booties equipped?
                    health += 25;
                }
            }
            return health;
        }
        case TFClass_Engineer:
        {
            // Is The Gunslinger equipped?
            new melee = GetPlayerWeaponSlot(client, 2);
            if (melee > 0 && GetEntProp(melee,  Prop_Send, "m_iItemDefinitionIndex") == 142)
                return 150;
        }
        case TFClass_Spy:
        {
            // Is The Big Earner equipped?
            new melee = GetPlayerWeaponSlot(client, 2);
            if (melee > 0 && GetEntProp(melee,  Prop_Send, "m_iItemDefinitionIndex") == 461)
                return 100;
        }
    }
    return TF2_GetClassHealth(class);
}

#define TF2_IsSlowed(%1)                    (((%1) & TF_CONDFLAG_SLOWED) != TF_CONDFLAG_NONE)
#define TF2_IsZoomed(%1)                    (((%1) & TF_CONDFLAG_ZOOMED) != TF_CONDFLAG_NONE)
#define TF2_IsDisguising(%1)                (((%1) & TF_CONDFLAG_DISGUISING) != TF_CONDFLAG_NONE)
#define TF2_IsDisguised(%1)                 (((%1) & TF_CONDFLAG_DISGUISED) != TF_CONDFLAG_NONE)
#define TF2_IsCloaked(%1)                   (((%1) & TF_CONDFLAG_CLOAKED) != TF_CONDFLAG_NONE)
#define TF2_IsUbercharged(%1)               (((%1) & TF_CONDFLAG_UBERCHARGED) != TF_CONDFLAG_NONE)
#define TF2_IsTeleportedGlow(%1)            (((%1) & TF_CONDFLAG_TELEPORTGLOW) != TF_CONDFLAG_NONE)
#define TF2_IsTaunting(%1)                  (((%1) & TF_CONDFLAG_TAUNTING) != TF_CONDFLAG_NONE)
#define TF2_IsUberchargeFading(%1)          (((%1) & TF_CONDFLAG_UBERCHARGEFADE) != TF_CONDFLAG_NONE)
#define TF2_IsCloakFlicker(%1)              (((%1) & TF_CONDFLAG_CLOAKFLICKER) != TF_CONDFLAG_NONE)
#define TF2_IsTeleporting(%1)               (((%1) & TF_CONDFLAG_TELEPORTING) != TF_CONDFLAG_NONE)
#define TF2_IsKritzkrieged(%1)              (((%1) & TF_CONDFLAG_KRITZKRIEGED) != TF_CONDFLAG_NONE)
#define TF2_IsDeadRingered(%1)              (((%1) & TF_CONDFLAG_DEADRINGERED) != TF_CONDFLAG_NONE)
#define TF2_IsBonked(%1)                    (((%1) & TF_CONDFLAG_BONKED) != TF_CONDFLAG_NONE)
#define TF2_IsDazed(%1)                     (((%1) & TF_CONDFLAG_DAZED) != TF_CONDFLAG_NONE)
#define TF2_IsBuffed(%1)                    (((%1) & TF_CONDFLAG_BUFFED) != TF_CONDFLAG_NONE)
#define TF2_IsCharging(%1)                  (((%1) & TF_CONDFLAG_CHARGING) != TF_CONDFLAG_NONE)
#define TF2_IsDemoBuff(%1)                  (((%1) & TF_CONDFLAG_DEMOBUFF) != TF_CONDFLAG_NONE)
#define TF2_IsCritCola(%1)                  (((%1) & TF_CONDFLAG_CRITCOLA) != TF_CONDFLAG_NONE)
#define TF2_IsInHealRadius(%1)              (((%1) & TF_CONDFLAG_INHEALRADIUS) != TF_CONDFLAG_INHEALRADIUS)
#define TF2_IsHealing(%1)                   (((%1) & TF_CONDFLAG_HEALING) != TF_CONDFLAG_NONE)
#define TF2_IsOnFire(%1)                    (((%1) & TF_CONDFLAG_ONFIRE) != TF_CONDFLAG_NONE)
#define TF2_IsOverhealed(%1)                (((%1) & TF_CONDFLAG_OVERHEALED) != TF_CONDFLAG_NONE)
#define TF2_IsJarated(%1)                   (((%1) & TF_CONDFLAG_JARATED) != TF_CONDFLAG_NONE)
#define TF2_IsBleeding(%1)                  (((%1) & TF_CONDFLAG_BLEEDING) != TF_CONDFLAG_NONE)
#define TF2_IsDefenseBuffed(%1)             (((%1) & TF_CONDFLAG_DEFENSEBUFFED) != TF_CONDFLAG_NONE)
#define TF2_IsMilked(%1)                    (((%1) & TF_CONDFLAG_MILKED) != TF_CONDFLAG_NONE)
#define TF2_IsMegaHealed(%1)                (((%1) & TF_CONDFLAG_MEGAHEAL) != TF_CONDFLAG_MEGAHEAL)
#define TF2_IsRegenBuffed(%1)               (((%1) & TF_CONDFLAG_REGENBUFFED) != TF_CONDFLAG_REGENBUFFED)
#define TF2_IsMarkedForDeath(%1)            (((%1) & TF_CONDFLAG_MARKEDFORDEATH) != TF_CONDFLAG_MARKEDFORDEATH)

#define TF_CONDFLAGEX_SPEEDBUFFALLY         (1 << (_:TFCond_SpeedBuffAlly-32))

#define TF2_IsSpeedBuffAlly(%1)             (((%1) & TF_CONDFLAGEX_SPEEDBUFFALLY) != TF_CONDFLAGEX_SPEEDBUFFALLY)

/**
 * Gets a player's lower 32 condition bits
 *
 * @param client		Player's index.
 * @return				Player's lower 32 condition bits
 */
stock TF2_GetPlayerConditionLowBits(client)
{
	return GetEntProp(client, Prop_Send, "m_nPlayerCond")|GetEntProp(client, Prop_Send, "_condition_bits");
}

/**
 * Gets a player's upper 32 condition bits
 *
 * @param client		Player's index.
 * @return				Player's upper 32 condition bits
 */
stock TF2_GetPlayerConditionHighBits(client)
{
	return GetEntProp(client, Prop_Send, "m_nPlayerCondEx");
}

/**
 * Gets a string representing the player's condition bits
 * Mostly used to debug and/or log them in a, more or less, readable fashion
 *
 * @param client		Player's index.
 * @return				String representing the Player's condition bits
 */
stock TF2_GetPlayerConditionString(client, String:condStr[], condStrLen, &pcond=0, &pcond2)
{
    pcond = TF2_GetPlayerConditionLowBits(client);
    pcond2 = TF2_GetPlayerConditionHighBits(client);
    
    //                        00000000001111111111222222222233333333334
    //                        01234567890123456789012345678901234567890
    new String:condFlags[] = "                                        ";
    if (TF2_IsPlayerSlowed(client))
        condFlags[0]  = 'S';
    if (TF2_IsPlayerZoomed(client))
        condFlags[1]  = 'Z';
    if (TF2_IsPlayerDisguising(client))
        condFlags[2]  = 'd';
    if (TF2_IsPlayerDisguised(client))
        condFlags[3]  = 'D';
    if (TF2_IsPlayerCloaked(client))
        condFlags[4]  = 'C';
    if (TF2_IsPlayerUbercharged(client))
        condFlags[5]  = 'U';
    if (TF2_IsPlayerTeleportedGlow(client))
        condFlags[6]  = 'g';
    if (TF2_IsPlayerTaunting(client))
        condFlags[7]  = 'T';
    if (TF2_IsPlayerUberchargeFading(client))
        condFlags[8]  = 'f';
    if (TF2_IsPlayerCloakFlicker(client))
        condFlags[9]  = 'c';
    if (TF2_IsPlayerTeleporting(client))
        condFlags[10] = 'p';
    if (TF2_IsPlayerKritzkrieged(client))
        condFlags[11] = 'K';
    if (TF2_IsPlayerTmpDamageBonus(client))
        condFlags[12] = '2';
    if (TF2_IsPlayerDeadRingered(client))
        condFlags[13] = 'R';
    if (TF2_IsPlayerBonked(client))
        condFlags[14] = 'b';
    if (TF2_IsPlayerDazed(client))
        condFlags[15] = 'A';
    if (TF2_IsPlayerBuffed(client))
        condFlags[16] = 'B';
    if (TF2_IsPlayerCharging(client))
        condFlags[17] = '-';
    if (TF2_IsPlayerDemoBuff(client))
        condFlags[18] = '>';
    if (TF2_IsPlayerCritCola(client))
        condFlags[19] = 'r';
    if (TF2_IsPlayerInHealRadius(client))
        condFlags[20] = '+';
    if (TF2_IsPlayerHealing(client))
        condFlags[21] = 'H';
    if (TF2_IsPlayerOnFire(client))
        condFlags[22] = 'F';
    if (TF2_IsPlayerOverhealed(client))
        condFlags[23] = 'O';
    if (TF2_IsPlayerJarated(client))
        condFlags[24] = 'J';
    if (TF2_IsPlayerBleeding(client))
        condFlags[25] = 'L';
    if (TF2_IsPlayerDefenseBuffed(client))
        condFlags[26] = 'E';
    if (TF2_IsPlayerMilked(client))
        condFlags[27] = 'M';
    if (TF2_IsPlayerMegaHealed(client))
        condFlags[28] = '!';
    if (TF2_IsPlayerRegenBuffed(client))
        condFlags[29] = 'G';
    if (TF2_IsPlayerMarkedForDeath(client))
        condFlags[30] = 'e';
    if (TF2_IsPlayerNoHealingDamageBuff(client))
        condFlags[31] = '3';
    if (TF2_IsPlayerSpeedBuffAlly(client))
        condFlags[32] = 'a';
    if (TF2_IsPlayerHalloweenCritCandy(client))
        condFlags[33] = 'y';
    if (TF2_IsPlayerCritHype(client))
        condFlags[34] = 'h';
    if (TF2_IsPlayerCritOnFirstBlood(client))
        condFlags[35] = '1';
    if (TF2_IsPlayerCritOnWin(client))
        condFlags[36] = 'W';
    if (TF2_IsPlayerCritOnFlagCapture(client))
        condFlags[37] = '#';
    if (TF2_IsPlayerCritOnKill(client))
        condFlags[38] = '*';
    if (TF2_IsPlayerRestrictToMelee(client))
        condFlags[39] = 'M';

    return strcopy(condStr, condStrLen, condFlags);
}