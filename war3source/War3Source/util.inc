/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: util.inc
 * Description: Utility functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _util_included
 #endinput
#endif
#define _util_included

#include <cstrike>

enum Mod { undetected, tf2, cstrike, dod, hl2mp, insurgency, other };
stock Mod:GameType = undetected;

stock healthOffset[MAXPLAYERS+1]            = { 0, ... };
stock maxHealthOffset[MAXPLAYERS+1]         = { 0, ... };

stock maxHealth[MAXPLAYERS+1]               = { 0, ... };
stock bool:healthIncreased[MAXPLAYERS+1]    = { false, ... };

stock Mod:GetGameType()
{
    if (GameType == undetected)
    {
        new String:modname[30];
        GetGameFolderName(modname, sizeof(modname));
        if (StrEqual(modname,"cstrike",false))
            GameType=cstrike;
        else if (StrEqual(modname,"tf",false)) 
            GameType=tf2;
        else if (StrEqual(modname,"dod",false)) 
            GameType=dod;
        else if (StrEqual(modname,"hl2mp",false)) 
            GameType=hl2mp;
        else if (StrEqual(modname,"Insurgency",false)) 
            GameType=insurgency;
        else
            GameType=other;
    }
    return GameType;
}

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
        if(IsClientConnected(x))
        {
            GetClientAuthString(x,authStr,63);
            if(StrEqual(auth,authStr))
                return x;
        }
    }
    return 0;
}

stock SetupHealth(client)
{
    healthOffset[client]=FindDataMapOffs(client,"m_iHealth");

    if (GameType == tf2)
    {
        maxHealthOffset[client]=FindDataMapOffs(client,"m_iMaxHealth");
        maxHealth[client] = GetMaxHealth(client);
    }
}

stock IncreaseHealth(client, amount)
{
    new health = GetClientHealth(client)+amount;
    if (GameType == tf2 && health > GetMaxHealth(client))
    {
        SetMaxHealth(client, health);
        healthIncreased[client] = true;
    }
    SetHealth(client, health);
}

stock SetHealth(entity,amount)
{
    SetEntData(entity,healthOffset[entity],amount,1);
}

stock GetHealth(entity)
{
    return GetEntData(entity,healthOffset[entity],1);
}

stock SetMaxHealth(entity,amount)
{
    SetEntData(entity,maxHealthOffset[entity],amount,1);
}

stock GetMaxHealth(entity)
{
    return GetEntData(entity,maxHealthOffset[entity],1);
}

stock RespawnPlayer(client)
{
    if (GameType == cstrike)
        CS_RespawnPlayer(client);
    else
        DispatchSpawn(client);
}

stock Float:DistanceBetween(Float:startvec[3],Float:endvec[3])
{
    return SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+
                      (startvec[1]-endvec[1])*(startvec[1]-endvec[1])+
                      (startvec[2]-endvec[2])*(startvec[2]-endvec[2]));
}
