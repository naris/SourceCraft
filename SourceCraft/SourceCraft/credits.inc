/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: credits.inc
 * Description: The shopmenu credit system. 
 * Author(s): Anthony Iacono  
 */
 
#define KILL_CREDITS_LONGTERM 2
#define KILL_CREDITS_SHORTTERM 3

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
    new curcredits=GetCredits(vectorpos);
    new addcredits= (SAVE_ENABLED) ? KILL_CREDITS_LONGTERM : KILL_CREDITS_SHORTTERM;
    new newcredits=curcredits+addcredits;

    decl String:currencies[64];
    GetConVarString((addcredits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));

    if(newcredits <= MAX_CREDITS || MAX_CREDITS == 0)
    {
        SetCredits(vectorpos,newcredits);
        PrintToChat(client, "%c[SourceCraft] %cYou have gained %d %s for getting a kill.",
                    COLOR_GREEN,COLOR_DEFAULT,addcredits, currencies);
    }
    else
    {
        new amt = MAX_CREDITS-curcredits;
        if (amt > 0)
        {
            SetCredits(vectorpos,MAX_CREDITS);
            PrintToChat(client, "%c[SourceCraft] %cThe max amount of %s is %d, so you have gained %d %s.",
                        COLOR_GREEN,COLOR_DEFAULT,currencies,MAX_CREDITS,amt,currencies);
        }
    }
}
