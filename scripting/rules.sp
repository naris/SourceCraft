#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.01"

public Plugin:myinfo = 
{
    name = "ConVar List",
    author = "Jannik 'Peace-Maker' Hartung",
    description = "RCON implementation of A2S_RULES query",
    version = PLUGIN_VERSION,
    url = "http://www.wcfan.de/"
}

public OnMapStart()
{
	CreateTimer(5.0, CheckCvars, 0);
}

public Action:CheckCvars(Handle:timer, any:client)
{
    new Handle:convarList = INVALID_HANDLE, Handle:conVar = INVALID_HANDLE;
    new bool:isCommand;
    new flags;
    new String:buffer[70], String:buffer2[70], String:desc[256];
    
    convarList = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc));
    if(convarList == INVALID_HANDLE)
        return Plugin_Handled;
    
    do
    {
        // don't print commands or convars without the NOTIFY flag
        if(isCommand || (!isCommand && (flags & FCVAR_NOTIFY == 0)))
            continue;
        
        conVar = FindConVar(buffer);
        GetConVarString(conVar, buffer2, sizeof(buffer2));
        SetConVarString(conVar, buffer2, false, false);
        CloseHandle(conVar);
		
    } while(FindNextConCommand(convarList, buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc)));
    
    if(convarList != INVALID_HANDLE)
        CloseHandle(convarList);
		
    return Plugin_Handled;
}
