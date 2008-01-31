/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: credits.inc
 * Description: The shopmenu credit system. 
 * Author(s): Anthony Iacono  
 */
 
#define KILL_CREDITS_LONGTERM 2
#define KILL_CREDITS_SHORTTERM 3

#define FLAG_CREDITS 5
#define CHARGE_CREDITS 10

#define WIN_CREDITS 8

public ShowCredits(client,vecpos)
{
    new credits=GetCredits(vecpos);
    decl String:currencies[64];
    GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
    PrintToChat(client,"%c[SourceCraft] %cYou have %d %s.",
                COLOR_GREEN,COLOR_DEFAULT,credits, currencies);
}

public GiveKillCredits(client,vectorpos)
{
    new addcredits= (SAVE_ENABLED) ? KILL_CREDITS_LONGTERM : KILL_CREDITS_SHORTTERM;
    GiveCredits(client,vectorpos,addcredits,"getting a kill");
}

public GivePickedUpFlagCredits(client,vectorpos)
{
    GiveCredits(client,vectorpos,FLAG_CREDITS,"picking up the flag");
}

public GiveChargeDeployedCredits(client,vectorpos)
{
    GiveCredits(client,vectorpos,CHARGE_CREDITS,"deploying Ubercharge");
}

public GiveRoundWinCredits(client,vectorpos)
{
    GiveCredits(client,vectorpos,WIN_CREDITS,"winning the round");
}

public GiveCredits(client,vectorpos, amount, const String:reason[])
{
    new Action:result;
    Call_StartForward(g_OnCreditsGivenHandle);
    Call_PushCell(client);
    Call_PushCell(vectorpos);
    Call_PushCellRef(amount);
    Call_PushCell(false);
    Call_Finish(result);
    if (result != Plugin_Stop)
    {
        new curcredits=GetCredits(vectorpos);
        new newcredits=curcredits+amount;

        decl String:currencies[64];
        GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));

        if(newcredits <= MAX_CREDITS || MAX_CREDITS == 0)
        {
            SetCredits(vectorpos,amount);
            PrintToChat(client, "%c[SourceCraft] %cYou have gained %d %s for %s.",
                        COLOR_GREEN,COLOR_DEFAULT,amount, currencies, reason);
        }
        else
        {
            new amt = MAX_CREDITS-amount;
            if (amt > 0)
            {
                SetCredits(vectorpos,MAX_CREDITS);
                PrintToChat(client, "%c[SourceCraft] %cThe max amount of %s is %d, so you have gained %d %s for %s.",
                            COLOR_GREEN,COLOR_DEFAULT,currencies,MAX_CREDITS,amt,currencies, reason);
            }
        }
    }
}
