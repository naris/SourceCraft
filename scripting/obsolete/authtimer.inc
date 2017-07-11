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

stock Handle:AuthTimer(Float:delay,index,Timer:func, flags=TIMER_FLAG_NO_MAPCHANGE)
{
    new Handle:pack;
    AuthTimerEx(delay, index, func, pack, flags);
    return pack;
}

stock Handle:AuthTimerEx(Float:delay,index,Timer:func,
                         &Handle:pack=INVALID_HANDLE,
                         flags=TIMER_FLAG_NO_MAPCHANGE)
{
    decl String:auth[64];
    GetClientAuthString(index,auth,sizeof(auth));

    new Handle:timer = CreateDataTimer(delay,func,pack, flags);
    if (timer != INVALID_HANDLE && pack != INVALID_HANDLE)
    {
        WritePackCell(pack, index);
        WritePackString(pack, auth);
    }
    return timer;
}

stock ClientOfAuthString(const String:auth[])
{
    new index = 0;
    decl String:authStr[64];
    for (new x=1;x<=MaxClients;x++)
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
    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        index = ReadPackCell(pack);

        if (IsClientInGame(index))
        {
            decl String:auth[64];
            ReadPackString(pack, auth, sizeof(auth));

            decl String:authStr[64];
            GetClientAuthString(index,authStr,sizeof(authStr));
            if (!StrEqual(auth,authStr))
                index = 0;
        }
        else
            index = 0;
    }
    return index;
}

