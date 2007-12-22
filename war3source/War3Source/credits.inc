/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: credits.inc
 * Description: The shopmenu credit system. 
 * Author(s): Anthony Iacono  
 */
 
#define KILL_CREDITS_LONGTERM 2
#define KILL_CREDITS_SHORTTERM 3

public War3Source_ShowCredits(client,vecpos)
{
    decl String:currency[64];
    GetConVarString(m_Currency, currency, 63);
    new credits=GetCredits(vecpos);
    if(credits!=1)
    {
        PrintToChat(client,"%c[War3Source] %cYou have %d %s.",
                    COLOR_GREEN,COLOR_DEFAULT,credits, currency);
    }
    else
    {
        PrintToChat(client,"%c[War3Source] %cYou have %d %s.",
                    COLOR_GREEN,COLOR_DEFAULT,credits, currency);
    }
}

public GiveKillCredits(client,vectorpos)
{
    new curcredits=GetCredits(vectorpos);
    new addcredits= (SAVE_ENABLED) ? KILL_CREDITS_LONGTERM : KILL_CREDITS_SHORTTERM;
    new newcredits=curcredits+addcredits;

    decl String:currency[64];
    GetConVarString(m_Currency, currency, 63);

    if(newcredits <= MAX_CREDITS || MAX_CREDITS == 0)
    {
        SetCredits(vectorpos,newcredits);
        PrintToChat(client, "%c[War3Source] %cYou have gained %d %s for getting a kill.",
                    COLOR_GREEN,COLOR_DEFAULT,addcredits, currency);
    }
    else
    {
        SetCredits(vectorpos,MAX_CREDITS);
        PrintToChat(client, "%c[War3Source] %cThe max amount of %s is %d, so you have gained %d %s.",
                    COLOR_GREEN,COLOR_DEFAULT,MAX_CREDITS,currency,MAX_CREDITS-curcredits,currency);
    }
}
