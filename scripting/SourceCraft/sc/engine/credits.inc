/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: credits.inc
 * Description: Routines to manipulate crystals and vespene (gas). 
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 * Credits: Anthony Iacono
 */

#define KILL_CRYSTALS_LONGTERM   2
#define KILL_CRYSTALS_SHORTTERM  3

#define TOUCH_CRYSTALS           1
#define ESCORT_AMOUNT            2
#define FLAG_AMOUNT              5
#define POINT_AMOUNT             5
#define BLOCK_AMOUNT             3
#define CHARGE_CRYSTALS         15

#define PLANT_AMOUNT             5
#define DEFUSE_AMOUNT            3
#define EXPLODE_AMOUNT          20

#define KILL_PLANTER_AMOUNT      2
#define KILL_DEFUSER_AMOUNT      2

#define STUN_BOSS_AMOUNT        10
#define KILL_BOSS_AMOUNT        20
#define BOSS_LEVEL_AMOUNT        2

#define HOSTAGE_AMOUNT           2

#define ROUND_WIN_CRYSTALS       8
#define ROUND_WIN_VESPENE        2

#define DOOMSDAY_CRYSTALS       10
#define DOOMSDAY_VESPENE         4

#define GAME_WIN_CRYSTALS        2 // Multiplied by score
#define MVP_CRYSTALS             1 // Multiplied by place * points
#define MVP_ENERGY             1.0 // Multiplied by place * points

ShowCrystals(client, Display:displayFlags=Display_Crystals)
{
    if (GetShopItemCount() >= 1 && !IsFakeClient(client))
    {
        new pcrystals = GetPCrystals(client);
        if (pcrystals > 0)
        {
            DisplayMessage(client, displayFlags, "%t", "ShowPCrystals",
                           GetCrystals(client), pcrystals);
        }
        else
        {
            DisplayMessage(client, displayFlags, "%t", "ShowCrystals",
                           GetCrystals(client));
        }
    }
}

ShowVespene(client, Display:displayFlags=Display_Vespene)
{
    if (!IsFakeClient(client))
    {
        DisplayMessage(client, displayFlags, "%t", "ShowVespene",
                       GetVespene(client));
    }
}

ShowEnergy(client, Display:displayFlags=Display_Energy)
{
    if (!IsFakeClient(client))
    {
        new bool:display = (displayFlags != Display_Energy);
        if (!display)
        {
            new EnergyFlags:energyFlags = NoEnergy;
            new Float:limit = GetEnergyLimit(client);
            new Float:rate = GetEnergyRate(client);

            new race = GetRace(client);
            if (race > 0)
            {
                new Handle:raceHandle = GetRaceHandle(race);
                energyFlags = GetRaceEnergyFlags(raceHandle);

                if (rate < 0)
                    rate = GetRaceEnergyRate(raceHandle);

                if (limit < 0)
                    limit = GetRaceEnergyLimit(raceHandle);
            }

            display = (((energyFlags & UsesAccumulated) != NoEnergy) ||
                       rate > 0 || limit > 0 );
        }

        if (display)
        {
            DisplayMessage(client, displayFlags, "%t", "ShowEnergy", GetEnergy(client),
                           GetAccumulatedEnergy(client, GetRace(client)));
        }
    }
}

GiveKillCrystals(client)
{
    new addcrystals= (SAVE_ENABLED) ? KILL_CRYSTALS_LONGTERM : KILL_CRYSTALS_SHORTTERM;
    GiveCrystals(client,addcrystals,"Kill");
}

GiveBossStunCrystalsAndGas(client, level)
{
    new amount = STUN_BOSS_AMOUNT + (BOSS_LEVEL_AMOUNT * (level+1));
    GiveCrystals(client, amount, "BossStun");
    GiveVespene(client, amount, "BossStun");
}

GiveBossKillCrystalsAndGas(client, level)
{
    new amount = KILL_BOSS_AMOUNT + (BOSS_LEVEL_AMOUNT * (level+1));
    GiveCrystals(client, amount, "BossKill");
    GiveVespene(client, amount, "BossKill");
}

GivePickedUpFlagCrystalsAndGas(client)
{
    GiveCrystals(client,FLAG_AMOUNT,"PickUpIntel");
    GiveVespene(client,FLAG_AMOUNT,"PickUpIntel");
}

TakeDroppedFlagCrystalsAndGas(client)
{
    GiveCrystals(client,-FLAG_AMOUNT,"DropIntel");
    GiveVespene(client,-FLAG_AMOUNT,"DropIntel");
}

GiveFlagCapturedCrystalsAndGas(client)
{
    GiveCrystals(client,FLAG_AMOUNT*2,"CapIntel");
    GiveVespene(client,FLAG_AMOUNT*2,"CapIntel");
}

GiveFlagDefendedCrystalsAndGas(client)
{
    GiveCrystals(client,FLAG_AMOUNT*2,"DefendIntel");
    GiveVespene(client,FLAG_AMOUNT*2,"DefendIntel");
}

GivePointCapturedCrystalsAndGas(client)
{
    GiveCrystals(client,POINT_AMOUNT,"CapPoint");
    GiveVespene(client,POINT_AMOUNT,"CapPoint");
}

GiveCapBlockedCrystalsAndGas(client)
{
    GiveCrystals(client,BLOCK_AMOUNT,"BlockPoint");
    GiveVespene(client,BLOCK_AMOUNT,"BlockPoint");
}

GivePointTouchedCrystals(client)
{
    GiveCrystals(client,TOUCH_CRYSTALS,"TouchPoint");
}

GiveEscortCrystalsAndGas(client, points)
{
    GiveCrystals(client,ESCORT_AMOUNT*points,"Escort");
    GiveVespene(client,ESCORT_AMOUNT,"Escort");
}

GiveChargeDeployedCrystals(client)
{
    GiveCrystals(client,CHARGE_CRYSTALS,"DeployUber");
}

GivePlantCrystalsAndGas(client)
{
    GiveCrystals(client,PLANT_AMOUNT,"PlantBomb");
    GiveVespene(client,PLANT_AMOUNT,"PlantBomb");
}

GiveDefuseCrystalsAndGas(client)
{
    GiveCrystals(client,DEFUSE_AMOUNT,"DefuseBomb");
    GiveVespene(client,DEFUSE_AMOUNT,"DefuseBomb");
}

GiveExplodeCrystalsAndGas(client)
{
    GiveCrystals(client,DEFUSE_AMOUNT,"ExplodeBomb");
    GiveVespene(client,DEFUSE_AMOUNT,"ExplodeBomb");
}

GiveKillPlanterCrystalsAndGas(client)
{
    GiveCrystals(client,KILL_PLANTER_AMOUNT,"KillBomber");
    GiveVespene(client,KILL_PLANTER_AMOUNT,"KillBomber");
}

GiveKillDefuserCrystalsAndGas(client)
{
    GiveCrystals(client,KILL_DEFUSER_AMOUNT,"KillDefuser");
    GiveVespene(client,KILL_DEFUSER_AMOUNT,"KillDefuser");
}

GiveHostageCrystalsAndGas(client)
{
    GiveCrystals(client,ESCORT_AMOUNT,"RescueHostage");
    GiveVespene(client,ESCORT_AMOUNT,"RescueHostage");
}

GiveRoundWinCrystalsAndGas(client)
{
    GiveCrystals(client,ROUND_WIN_CRYSTALS,"WinRound");
    GiveVespene(client,ROUND_WIN_VESPENE,"WinRound");
}

GiveDoomsdayCrystalsAndGas(client)
{
    GiveCrystals(client,DOOMSDAY_CRYSTALS,"Doomsday");
    GiveVespene(client,DOOMSDAY_VESPENE,"Doomsday");
}

GiveGameWinCrystals(client,score)
{
    GiveCrystals(client,GAME_WIN_CRYSTALS*score,"WinGame");
}

GiveMvpCrystals(client,place,points)
{
    GiveCrystals(client, points*(7-place)*MVP_CRYSTALS,
                 "BeingMVP", place, points);
}

GiveMvpEnergy(client,place,points)
{
    GiveEnergy(client, float(points)*(7.0-float(place))*MVP_ENERGY,
               "BeingMVP", place, points);
}

GiveCrystals(client, amount, const String:phrase[],
             place=-1, points=-1)
{
    if (GetShopItemCount() >= 1 && GetClientCount() >= g_iMinPlayers)
    {
        new Action:result = Plugin_Continue;
        Call_StartForward(g_OnCrystalsGivenHandle);
        Call_PushCell(client);
        Call_PushCellRef(amount);
        Call_PushCell(false);
        Call_Finish(result);

        if (result != Plugin_Stop)
        {
            new String:reason[NAME_STRING_LENGTH];
            if (place >= 0 || points >= 0)
            {
                Format(reason, sizeof(reason), "%T",
                       phrase, client, place, points);
            }
            else
            {
                Format(reason, sizeof(reason), "%T",
                       phrase, client);
            }

            if (g_bUseMoney)
            {
                new curmoney = GetMoney(client);
                new newmoney = curmoney+RoundToNearest(float(amount) * g_fCrystalSellRate);
                SetMoney(client, newmoney);

                if (amount >= 0)
                {
                    LogToGame("%N gained %d money for %s", client, amount, reason);
                    DisplayMessage(client, Display_Crystals, "%t", "GainedMoney",
                                   amount, reason);
                }
                else
                {
                    LogToGame("%N lost %d money for %s", client, -amount, reason);
                    DisplayMessage(client, Display_Crystals, "%t", "LostMoney",
                                   -amount, reason);
                }
            }
            else
            {
                new curcrystals = GetCrystals(client);
                new newcrystals = curcrystals+amount;
                if (newcrystals <= g_iMaxCrystals || g_iMaxCrystals <= 0)
                {
                    SetCrystals(client,newcrystals);
                    if (amount >= 0)
                    {
                        LogToGame("%N gained %d crystals(s) for %s", client, amount, reason);
                        DisplayMessage(client, Display_Crystals, "%t", "GainedCrystals",
                                       amount, reason);
                    }
                    else
                    {
                        LogToGame("%N lost %d crystals(s) for %s", client, -amount, reason);
                        DisplayMessage(client, Display_Crystals, "%t", "LostCrystals",
                                       -amount, reason);
                    }
                }
                else
                {
                    new amt = g_iMaxCrystals-curcrystals;
                    if (amt > 0)
                    {
                        SetCrystals(client,g_iMaxCrystals);
                        LogToGame("%N gained %d crystal(s) for %s", client, amt, reason);
                        DisplayMessage(client, Display_Crystals, "%t", "GainedMaxCrystals",
                                       amt, g_iMaxCrystals, reason);
                    }
                    else if (amt < 0)
                        amt = 0;

                    new extra = amount - amt;
                    IncrementPCrystals(client, extra);

                    LogToGame("%N gained %d +crystals for %s", client, extra, reason);
                    DisplayMessage(client, Display_Crystals, "%t", "GainedPCrystals",
                                   extra, reason);
                }
            }

            if (IsFakeClient(client))
            {
                // Should the Bot buy something?
                new crystals = GetCrystals(client);
                if (crystals > 10 && GetRandomInt(0,100) < ((crystals >= 90) ? 80 : 50))
                {
                    new shopItemCount = GetShopItemCount();
                    new item = GetRandomInt(0, shopItemCount-1);
                    if (item >= 0)
                    {
                        new Handle:itemHandle = GetShopItemHandle(item);
                        if (itemHandle && GetCrystals(client) >= GetItemCrystals(itemHandle))
                            PurchaseShopItem(client, item);
                    }
                }
            }
        }
    }
}

GivePCrystals(client, amount, const String:phrase[])
{
    new String:reason[NAME_STRING_LENGTH];
    Format(reason, sizeof(reason), "%T", phrase, client);
    LogToGame("%N gained %d +crystals for %s", client, amount, reason);
    DisplayMessage(client, Display_Crystals, "%t", "GainedPCrystals",
                   amount, reason);
}

GiveVespene(client, amount, const String:phrase[],
            place=-1, points=-1)
{
    if (GetShopItemCount() >= 1 && GetClientCount() >= g_iMinPlayers)
    {
        new Action:result = Plugin_Continue;
        Call_StartForward(g_OnVespeneGivenHandle);
        Call_PushCell(client);
        Call_PushCellRef(amount);
        Call_PushCell(false);
        Call_Finish(result);

        if (result != Plugin_Stop)
        {
            new String:reason[NAME_STRING_LENGTH];
            if (place >= 0 || points >= 0)
            {
                Format(reason, sizeof(reason), "%T",
                       phrase, client, place, points);
            }
            else
            {
                Format(reason, sizeof(reason), "%T",
                       phrase, client);
            }

            new curvespene = GetVespene(client);
            new newvespene = curvespene+amount;
            if (newvespene <= g_iMaxVespene || g_iMaxVespene <= 0)
            {
                SetVespene(client,newvespene);
                if (amount >= 0)
                {
                    LogToGame("%N gained %d vespene for %s", client, amount, reason);
                    DisplayMessage(client, Display_Vespene, "%t", "GainedVespene",
                                   amount, reason);
                }
                else
                {
                    LogToGame("%N lost %d vespene for %s", client, -amount, reason);
                    DisplayMessage(client, Display_Vespene, "%t", "LostVespene",
                                   -amount, reason);
                }
            }
            else
            {
                new amt = g_iMaxVespene-curvespene;
                if (amt > 0)
                {
                    SetVespene(client,g_iMaxVespene);
                    LogToGame("%N gained %d vespene for %s", client, amt, reason);
                    DisplayMessage(client, Display_Vespene, "%t", "GainedMaxVespene",
                                   amt, g_iMaxVespene, reason);
                }
            }
        }
    }
}

GiveEnergy(client, Float:amount, const String:phrase[],
           place=-1, points=-1)
{
    if (GetShopItemCount() >= 1 && GetClientCount() >= g_iMinPlayers)
    {
        new String:reason[NAME_STRING_LENGTH];
        if (place >= 0 || points >= 0)
        {
            Format(reason, sizeof(reason), "%T",
                   phrase, client, place, points);
        }
        else
        {
            Format(reason, sizeof(reason), "%T",
                   phrase, client);
        }

        IncrementAccumulatedEnergy(client,GetRace(client),amount);
        if (amount >= 0)
        {
            LogToGame("%N gained %d accumulated energy for %s", client, amount, reason);
            DisplayMessage(client, Display_Vespene, "%t.", "GainedAccumulatedEnergy",
                           amount, reason);
        }
        else
        {
            LogToGame("%N lost %d accumulated energy for %s", client, -amount, reason);
            DisplayMessage(client, Display_Vespene, "%t", "LostAccumulatedEnergy",
                           -amount, reason);
        }
    }
}
