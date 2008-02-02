/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: strtoken.inc
 * Description: strtoken functions.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

// Stocks
stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
    new String:buf[maxlen+1];
    new cur_idx;
    new idx;
    new curind;
    idx=BreakString(inputstr,buf,maxlen);
    if(tokennum==1)
    {
        strcopy(outputstr,maxlen,buf);
        return;
    }
    curind=1;
    while(idx!=-1)
    {
        cur_idx+=idx;
        idx=BreakString(inputstr[cur_idx],buf,maxlen);
        curind++;
        if(tokennum==curind)
        {
            strcopy(outputstr,maxlen,buf);
            break;
        }
    }
}

stock StrTokenCount(const String:input[])
{
    decl String:buf[32];
    new cur_idx;
    new idx;
    new curind;
    while(idx!=-1)
    {
        cur_idx+=idx;
        idx=BreakString(input[cur_idx],buf,31);
        curind++;
    }
    return curind;
}
