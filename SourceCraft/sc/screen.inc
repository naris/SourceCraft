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

#define FADE_IN  0x0001
#define FADE_OUT 0x0002

stock Fade(const clients[], numClients, duration,time,const color[4])
{
    new Handle:hBf=StartMessage("Fade", clients, numClients);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteShort(hBf,duration); //*400);
        BfWriteShort(hBf,time); //*400);
        BfWriteShort(hBf,FADE_IN);
        BfWriteByte(hBf,color[0]);
        BfWriteByte(hBf,color[1]);
        BfWriteByte(hBf,color[2]);
        BfWriteByte(hBf,color[3]);
        EndMessage();
    }
}

stock FadeOne(client, duration,time,const color[4])
{
    new Handle:hBf=StartMessageOne("Fade", client);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteShort(hBf,duration); //*400);
        BfWriteShort(hBf,time); //*400);
        BfWriteShort(hBf,FADE_IN);
        BfWriteByte(hBf,color[0]);
        BfWriteByte(hBf,color[1]);
        BfWriteByte(hBf,color[2]);
        BfWriteByte(hBf,color[3]);
        EndMessage();
    }
}
stock FadeAll(duration,time,const color[4])
{
    new Handle:hBf=StartMessageAll("Fade");
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteShort(hBf,duration); //*400);
        BfWriteShort(hBf,time); //*400);
        BfWriteShort(hBf,FADE_IN);
        BfWriteByte(hBf,color[0]);
        BfWriteByte(hBf,color[1]);
        BfWriteByte(hBf,color[2]);
        BfWriteByte(hBf,color[3]);
        EndMessage();
    }
}

stock Shake(const clients[],numClients,on_off,Float:amplitude,Float:duration,Float:frequency)
{
    new Handle:hBf=StartMessage("Shake", clients, numClients);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, on_off);
        BfWriteFloat(hBf,amplitude);
        BfWriteFloat(hBf,duration);
        BfWriteFloat(hBf,frequency);
        EndMessage();
    }
}

stock ShakeOne(client,on_off,Float:amplitude,Float:duration,Float:frequency)
{
    new Handle:hBf=StartMessageOne("Shake", client);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, on_off);
        BfWriteFloat(hBf,amplitude);
        BfWriteFloat(hBf,duration);
        BfWriteFloat(hBf,frequency);
        EndMessage();
    }
}

stock ShakeAll(on_off,Float:amplitude,Float:duration,Float:frequency)
{
    new Handle:hBf=StartMessageAll("Shake");
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, on_off);
        BfWriteFloat(hBf,amplitude);
        BfWriteFloat(hBf,duration);
        BfWriteFloat(hBf,frequency);
        EndMessage();
    }
}
