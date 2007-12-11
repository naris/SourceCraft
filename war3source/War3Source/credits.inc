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
    new credits=GetCredits(vecpos);
    if(credits!=1)
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have %d shop credits.",COLOR_GREEN,COLOR_DEFAULT,credits);
    else
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have %d shop credit.",COLOR_GREEN,COLOR_DEFAULT,credits);
}

public GiveKillCredits(client,vectorpos)
{
    new newcredits;
    if(SAVE_ENABLED)
    {
        newcredits=GetCredits(vectorpos)+KILL_CREDITS_LONGTERM;
        if(newcredits<=MAX_CREDITS||MAX_CREDITS==0)
        {
            SetCredits(vectorpos,newcredits);
            War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d credits for getting a kill.",COLOR_GREEN,COLOR_DEFAULT,KILL_CREDITS_LONGTERM);
        }
        else
        {
            War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cThe max amount of credits is %d, so you have gained %d credits.",COLOR_GREEN,COLOR_DEFAULT,MAX_CREDITS,MAX_CREDITS-GetCredits(vectorpos));
            SetCredits(vectorpos,MAX_CREDITS);
        }
    }
    else
    {
        newcredits=GetCredits(vectorpos)+KILL_CREDITS_SHORTTERM;
        if(newcredits<=MAX_CREDITS||MAX_CREDITS==0)
        {
            SetCredits(vectorpos,newcredits);
            War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d credits for getting a kill.",COLOR_GREEN,COLOR_DEFAULT,KILL_CREDITS_LONGTERM);
        }
        else
        {
            War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cThe max amount of credits is %d, so you have gained %d credits.",MAX_CREDITS,MAX_CREDITS-GetCredits(vectorpos));
            SetCredits(vectorpos,MAX_CREDITS);
        }
    }  
}
