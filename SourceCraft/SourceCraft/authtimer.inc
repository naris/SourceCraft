/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: authtimer.inc
 * Description: AuthTimer functions
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _authtimer_included
 #endinput
#endif
#define _authtimer_included

stock AuthTimer(Float:delay,index,Timer:func)
{
    new Handle:temp=CreateArray(ByteCountToCells(64));
    decl String:auth[64];
    GetClientAuthString(index,auth,63);
    PushArrayString(temp,auth);
    CreateTimer(delay,func,temp);
}

stock PlayerOfAuth(const String:auth[])
{
    new max=GetMaxClients();
    decl String:authStr[64];
    for(new x=1;x<=max;x++)
    {
        if(IsClientInGame(x))
        {
            GetClientAuthString(x,authStr,63);
            if(StrEqual(auth,authStr))
                return x;
        }
    }
    return 0;
}
