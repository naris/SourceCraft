/*
 * vim: set ai et ts=4 sw=4 syntax=cpp :
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
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have %d shop %s.",COLOR_GREEN,COLOR_DEFAULT,credits, currency);
    else
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have %d shop %s.",COLOR_GREEN,COLOR_DEFAULT,credits, currency);
}

public GiveKillCredits(client,vectorpos)
{
    decl String:currency[64];
    GetConVarString(m_Currency, currency, 63);
    new newcredits;
    if(SAVE_ENABLED)
    {
        newcredits=GetCredits(vectorpos)+KILL_CREDITS_LONGTERM;
        if(newcredits<=MAX_CREDITS||MAX_CREDITS==0)
        {
            SetCredits(vectorpos,newcredits);
            War3Source_ChatMessage(client,COLOR_DEFAULT,
                                   "%c[War3Source] %cYou have gained %d %s for getting a kill.",
                                   COLOR_GREEN,COLOR_DEFAULT,KILL_CREDITS_LONGTERM, currency);
        }
        else
        {
            War3Source_ChatMessage(client,COLOR_DEFAULT,
                                   "%c[War3Source] %cThe max amount of %s is %d, so you have gained %d %s.",
                                   COLOR_GREEN,COLOR_DEFAULT,MAX_CREDITS,currency,MAX_CREDITS-GetCredits(vectorpos),currency);
            SetCredits(vectorpos,MAX_CREDITS);
        }
    }
    else
    {
        newcredits=GetCredits(vectorpos)+KILL_CREDITS_SHORTTERM;
        if(newcredits<=MAX_CREDITS||MAX_CREDITS==0)
        {
            SetCredits(vectorpos,newcredits);
            War3Source_ChatMessage(client,COLOR_DEFAULT,
                                   "%c[War3Source] %cYou have gained %d %s for getting a kill.",
                                   COLOR_GREEN,COLOR_DEFAULT,KILL_CREDITS_LONGTERM,currency);
        }
        else
        {
            War3Source_ChatMessage(client,COLOR_DEFAULT,
                                   "%c[War3Source] %cThe max amount of %s is %d, so you have gained %d %s.",
                                   MAX_CREDITS,currency,MAX_CREDITS-GetCredits(vectorpos),currency);
            SetCredits(vectorpos,MAX_CREDITS);
        }
    }  
}
