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

stock Handle:AuthTimer(Float:delay,index,Timer:func)
{
    decl String:auth[64];
    GetClientAuthString(index,auth,sizeof(auth));

    new Handle:pack;
    CreateDataTimer(delay,func,pack);
    WritePackCell(pack, index);
    WritePackString(pack, auth);
    return pack;
}

stock ClientOfAuthString(const String:auth[])
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

stock ClientOfAuthTimer(Handle:pack)
{
    new index = 0;
    new old_index = 0;
    if (pack != INVALID_HANDLE)
    {
        decl String:auth[64];

        ResetPack(pack);
        index = ReadPackCell(pack);
        old_index = index;
        ReadPackString(pack, auth, sizeof(auth));

        if (IsClientInGame(index))
        {
            decl String:authStr[64];
            GetClientAuthString(index,authStr,sizeof(authStr));
            if (!StrEqual(auth,authStr))
                index = 0;
        }
        if (index <= 0)
        {
            index = ClientOfAuthString(auth);
            if (index > 0)
            {
                // I assumed this doesn't happen in other code,
                // so get my attention so I know I have to fix a bunch of stuff!
                LogError("Player %N moved from %d to %d",
                         index, old_index, index);
            }
        }
    }
    return index;
}

