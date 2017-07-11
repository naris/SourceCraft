/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: screen.inc
 * Description: Screen Effects
 * Author(s): Naris (Murray Wilson)
 * Thanks to: V0gelz (Frederik) frederik156@hotmail.com
 */

#if defined _screen_included
#endinput
#endif
#define _screen_included

#define FFADE_IN        0x0001  // Fade in
#define FFADE_OUT       0x0002  // Fade out (not in)
#define FFADE_MODULATE  0x0004  // Modulate (don't blend)
#define FFADE_STAYOUT   0x0008  // ignores the duration, stays faded out until new Fade message received
#define FFADE_PURGE     0x0010  // Purges all other fades, replacing them with this one

#define RGBA_COLOR_RED		{255,0,0,80}
#define RGBA_COLOR_GREEN	{0,255,0,80}
#define RGBA_COLOR_BLUE		{0,0,255,80}
#define RGBA_COLOR_YELLOW	{255,255,0,80}
#define RGBA_COLOR_ORANGE	{255,69,0,80}
#define RGBA_COLOR_PURPLE	{128,0,128,80}
#define RGBA_COLOR_CYAN		{255,0,255,80}
#define RGBA_COLOR_WHITE	{255,255,255,80}
#define RGBA_COLOR_BLACK	{0,0,0,80}
#define RGBA_COLOR_GREY		{128,128,128,80}
#define RGBA_COLOR_PINK		{255,20,147,80}
#define RGBA_COLOR_MAROON	{128,0,0,80}
#define RGBA_COLOR_SKYBLUE	{135,206,25,80}
#define RGBA_COLOR_GOLD		{255,215,0,80}
#define RGBA_COLOR_BROWN	{139,69,19,80}
#define RGBA_COLOR_VIOLET	{238,130,238,80}

stock Fade(clients[], numClients, duration,time,const color[4], code=FFADE_IN)
{
    new Handle:hBf=StartMessage("Fade", clients, numClients);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteShort(hBf,duration); //*400);
        BfWriteShort(hBf,time); //*400);
        BfWriteShort(hBf,code);
        BfWriteByte(hBf,color[0]);
        BfWriteByte(hBf,color[1]);
        BfWriteByte(hBf,color[2]);
        BfWriteByte(hBf,color[3]);
        EndMessage();
    }
}

stock FadeOne(client, duration,time,const color[4], code=FFADE_IN)
{
    new Handle:hBf=StartMessageOne("Fade", client);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteShort(hBf,duration); //*400);
        BfWriteShort(hBf,time); //*400);
        BfWriteShort(hBf,code);
        BfWriteByte(hBf,color[0]);
        BfWriteByte(hBf,color[1]);
        BfWriteByte(hBf,color[2]);
        BfWriteByte(hBf,color[3]);
        EndMessage();
    }
}

stock FadeAll(duration,time,const color[4], code=FFADE_IN)
{
    new Handle:hBf=StartMessageAllLiving("Fade");
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteShort(hBf,duration); //*400);
        BfWriteShort(hBf,time); //*400);
        BfWriteShort(hBf,code);
        BfWriteByte(hBf,color[0]);
        BfWriteByte(hBf,color[1]);
        BfWriteByte(hBf,color[2]);
        BfWriteByte(hBf,color[3]);
        EndMessage();
    }
}

stock Shake(const clients[],numClients,on_off=0,Float:amplitude=30.0,Float:duration=1.0,Float:frequency=30.0)
{
    new Handle:hBf=StartMessage("Shake", clients, numClients);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, on_off);
        BfWriteFloat(hBf,amplitude);
        BfWriteFloat(hBf,frequency);
        BfWriteFloat(hBf,duration);
        EndMessage();
    }
}

stock ShakeOne(client,on_off=0,Float:amplitude=30.0,Float:duration=1.0,Float:frequency=30.0)
{
    new Handle:hBf=StartMessageOne("Shake", client);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, on_off);
        BfWriteFloat(hBf,amplitude);
        BfWriteFloat(hBf,frequency);
        BfWriteFloat(hBf,duration);
        EndMessage();
    }
}

stock ShakeAll(on_off,Float:amplitude=30.0,Float:duration=1.0,Float:frequency=30.0)
{
    new Handle:hBf=(on_off) ? StartMessageAll("Shake")
                            : StartMessageAllLiving("Shake");
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, on_off);
        BfWriteFloat(hBf,amplitude);
        BfWriteFloat(hBf,frequency);
        BfWriteFloat(hBf,duration);
        EndMessage();
    }
}

/**
 * Starts a usermessage (network message) that broadcasts to all living clients.
 * @note See StartMessage or StartMessageEx().
 *
 * @param msgname		Message name to start.
 * @param flags			Optional flags to set.
 * @return				A handle to a bf_write bit packing structure, or
 *						INVALID_HANDLE on failure.
 */
stock Handle:StartMessageAllLiving(String:msgname[], flags=0)
{
    new total = 0;
    new clients[MaxClients];
    for (new i=1; i<=MaxClients; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) &&
            IsPlayerAlive(i) && !IsFakeClient(i))
        {
            clients[total++] = i;
        }
    }

    if (total > 0)
        return StartMessage(msgname, clients, total, flags);
    else
        return INVALID_HANDLE;
}

stock FadeVulerable(duration,time,const color[4], code=FFADE_IN)
{
    new total = 0;
    new clients[MaxClients];
    for (new i=1; i<=MaxClients; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) &&
            IsPlayerAlive(i) && !IsFakeClient(i))
        {
            if (!GetImmunity(i,Immunity_Blindness))
            {
                clients[total++] = i;
            }
        }
    }

    if (total > 0)
        Fade(clients, total, duration,time,color,code);
}
