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

#define AUTHINFO_ID 0

stock AuthTimer(Float:delay,index,Timer:func)
{
    decl String:auth[64];
    GetClientAuthString(index,auth,sizeof(auth));

    new Handle:arg=CreateArray(ByteCountToCells(64));
    PushArrayString(arg,auth);
    CreateTimer(delay,func,arg);
}

stock PlayerOfAuthString(const String:auth[])
{
    new index = 0;
    new max=GetMaxClients();
    decl String:authStr[64];
    for (new x=1;x<=max;x++)
    {
        if (IsClientInGame(x))
        {
            GetClientAuthString(x,authStr,sizeof(authStr));
            if (StrEqual(auth,authStr))
            {
                index = x;
                break;
            }
        }
    }
    return index;
}

stock PlayerOfAuthTimer(Handle:arg)
{
    new index = 0;
    if (arg != INVALID_HANDLE)
    {
        decl String:auth[64];
        GetArrayString(arg,AUTHINFO_ID,auth,sizeof(auth));
        index = PlayerOfAuthString(auth);
        ClearArray(arg);
        CloseHandle(arg);
    }
    return index;
}

