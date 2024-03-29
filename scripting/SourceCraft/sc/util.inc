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

stock bool:SetupSound(const String:wav[], bool:preload=false, bool:download=false)
{
    if (download)
    {
        decl String:file[PLATFORM_MAX_PATH+1];
        Format(file, PLATFORM_MAX_PATH, "sound/%s", wav);

        if(FileExists(file))
            AddFileToDownloadsTable(file);
    }
    return PrecacheSound(wav,preload);
}

stock SetupModel(const String:model[], bool:preload=false, bool:download=false)
{
    if (download && FileExists(model))
        AddFileToDownloadsTable(model);

    return PrecacheModel(model,preload);
}

