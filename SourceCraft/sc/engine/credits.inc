/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: credits.inc
 * Description: The shopmenu credit system. 
 * Author(s): Anthony Iacono  
 */

#define KILL_CREDITS_LONGTERM   2
#define KILL_CREDITS_SHORTTERM  3

#define TOUCH_CREDITS           1
#define FLAG_CREDITS            5
#define POINT_CREDITS           5
#define CHARGE_CREDITS         15

#define ROUND_WIN_CREDITS       8
#define GAME_WIN_CREDITS        2 // Multiplied by score
#define MVP_CREDITS             1 // Multiplied by place * points

public ShowCredits(client,Handle:playerHandle)
{
    if (GetShopItemCount() >= 1)
    {
        new credits=GetCredits(playerHandle);
        PrintToChat(client,"%c[SourceCraft] %cYou have %d %s.",
                    COLOR_GREEN,COLOR_DEFAULT,credits,
                    (credits == 1) ? "crystal" : "crystals");
    }
}

public GiveKillCredits(client,Handle:playerHandle)
{
    new addcredits= (SAVE_ENABLED) ? KILL_CREDITS_LONGTERM : KILL_CREDITS_SHORTTERM;
    GiveCredits(client,playerHandle,addcredits,"getting a kill");
}

public GivePickedUpFlagCredits(client,Handle:playerHandle)
{
    GiveCredits(client,playerHandle,FLAG_CREDITS,"picking up the intelligence");
}

public GivePointCapturedCredits(client,Handle:playerHandle)
{
    GiveCredits(client,playerHandle,POINT_CREDITS,"capturing a point");
}

public GivePointTouchedCredits(client,Handle:playerHandle)
{
    GiveCredits(client,playerHandle,TOUCH_CREDITS,"touching a point");
}

public GiveChargeDeployedCredits(client,Handle:playerHandle)
{
    GiveCredits(client,playerHandle,CHARGE_CREDITS,"deploying Ubercharge");
}

public GiveRoundWinCredits(client,Handle:playerHandle)
{
    GiveCredits(client,playerHandle,ROUND_WIN_CREDITS,"winning a round");
}

public GiveGameWinCredits(client,Handle:playerHandle,score)
{
    GiveCredits(client,playerHandle,GAME_WIN_CREDITS*score,"winning the game");
}

public GiveMvpCredits(client,Handle:playerHandle,place,points)
{
    new String:reason[64];
    Format(reason,sizeof(reason),"being MVP #%d with %d points",place,points);
    GiveCredits(client,playerHandle,points*place*MVP_CREDITS,reason);
}

public GiveCredits(client,Handle:playerHandle, amount, const String:reason[])
{
    if (GetShopItemCount() >= 1)
    {
        new Action:result;
        Call_StartForward(g_OnCreditsGivenHandle);
        Call_PushCell(client);
        Call_PushCell(playerHandle);
        Call_PushCellRef(amount);
        Call_PushCell(false);
        Call_Finish(result);

        if (result != Plugin_Stop)
        {
            new curcredits=GetCredits(playerHandle);
            new newcredits=curcredits+amount;

            new maxCredits = GetConVarInt(m_MaxCredits);
            if(newcredits <= maxCredits || maxCredits == 0)
            {
                SetCredits(playerHandle,newcredits);
                LogToGame("%N gained %d crystals(s) for %s", client, amount, reason);
                PrintToChat(client, "%c[SourceCraft] %cYou have gained %d %s for %s.",
                        COLOR_GREEN,COLOR_DEFAULT,amount,
                        (amount == 1) ? "crystal" : "crystals", reason);
            }
            else
            {
                new amt = maxCredits-amount;
                if (amt > 0)
                {
                    SetCredits(playerHandle,maxCredits);
                    LogToGame("%N gained %d crystal(s) for %s", client, amt, reason);
                    PrintToChat(client, "%c[SourceCraft] %cThe max amount of crystals is %d, so you have gained %d %s for %s.",
                            COLOR_GREEN,COLOR_DEFAULT,maxCredits,amt,
                            (amt == 1) ? "crystal" : "crystals", reason);
                }
            }
        }
    }
}
