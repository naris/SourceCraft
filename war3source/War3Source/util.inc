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

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // Actually red for DOD

enum Mod { undetected, tf2, cstrike, dod, hl2mp, insurgency, other };
stock Mod:GameType = undetected;

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

stock SetupSound(String:wav[])
{
    PrecacheSound(wav);

    decl String:file[PLATFORM_MAX_PATH+1];
    Format(file, PLATFORM_MAX_PATH, "sound/%s", wav);
    AddFileToDownloadsTable(file);
}

stock SetupModel(String:model[])
{
    AddFileToDownloadsTable(model);
    return PrecacheModel(model);
}

stock Float:DistanceBetween(Float:startvec[3],Float:endvec[3])
{
    new Float:distance = SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+
                                    (startvec[1]-endvec[1])*(startvec[1]-endvec[1])+
                                    (startvec[2]-endvec[2])*(startvec[2]-endvec[2]));

    if (distance < 0)
        distance *= -1;

    return distance;                                  
}

stock bool:IsInRange(client,index,Float:maxdistance)
{
    new Float:startclient[3];
    new Float:endclient[3];
    GetClientAbsOrigin(client,startclient);
    GetClientAbsOrigin(index,endclient);
    new Float:distance=DistanceBetween(startclient,endclient);
    return (distance<maxdistance);
}

