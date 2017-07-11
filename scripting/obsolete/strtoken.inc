/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: strtoken.inc
 * Description: strtoken functions.
 * Author(s): Anthony Iacono  
 * Refactored by: Naris (Murray Wilson)
 */

#if defined _strtoken_included
 #endinput
#endif
#define _strtoken_included

stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
    new pos = 0;
    for (new i=1; i < tokennum; i++)
    {
        new idx = BreakString(inputstr[pos],outputstr,maxlen);
        if (idx < 0)
            break;
        else            
            pos += idx;
    }
}

stock StrTokenCount(const String:input[])
{
    decl String:buf[32];
    new idx = 0;
    new pos = 0;

    do
    {
        idx = BreakString(input[pos],buf,sizeof(buf));
        pos += idx;
        curind++;
    }
    while (idx >= 0);

    return curind;
}
