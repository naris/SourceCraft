/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: messages.inc
 * Description: This file is the user message function handler.  
 * Author(s): Anthony Iacono
 * Note(s): The stocks in this file were created by jopmako, thanks =) 
 */

#if defined _messages_included
 #endinput
#endif
#define _messages_included

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // Actually red for DOD

/*
stock War3Source_ChatMessage(target,color,const String:szMsg[],any:...)
{
    if(strlen(szMsg)>191)
    {
        LogError("Disallow string len(%d)>191",strlen(szMsg));
        return;
    }
    decl String:buffer[192];
    VFormat(buffer,sizeof(buffer),szMsg,4);
    Format(buffer,191,"%s\n",buffer);
    new Handle:hBf;
    if(target==0)
        hBf=StartMessageAll("SayText");
    else
        hBf=StartMessageOne("SayText",target);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, 0); 
        BfWriteString(hBf, buffer);
        EndMessage();
    }
}
*/
