/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: races.inc
 * Description: The root of all race specific stuff.
 * Author(s): Anthony Iacono  
 */

#define RACE_STRINGS            0
#define RACE_UPGRADES           1
#define RACE_IDENT              2
#define RACE_REQUIRED_LEVEL     3
#define RACE_MAX_LEVEL          4
#define RACE_DATA_COUNT         5

#define RACE_NAME               0
#define RACE_SHORT_NAME         1
#define RACE_SWITCHMESSAGE      2
#define RACE_SWITCHMESSAGE_DEAD 3
#define RACE_STRING_COUNT       4

#define UPGRADE_STRINGS         0
#define UPGRADE_REQUIRED_LEVEL  1
#define UPGRADE_MAX_LEVEL       2
#define UPGRADE_ULTIMATE        3
#define UPGRADE_DATA_COUNT      4

#define UPGRADE_NAME            0
#define UPGRADE_SHORT_NAME      1
#define UPGRADE_DESC            2
#define UPGRADE_STRING_COUNT    3

#define GetRaceCount() GetArraySize(arrayRaces)

// A vector of race infomation
new Handle:arrayRaces = INVALID_HANDLE;

new bool:gUpgradesMenuMode[MAXPLAYERS+1];
new gShowUpgradesTarget[MAXPLAYERS+1];
new gRaceForUpgrades[MAXPLAYERS+1];

bool:InitRaceArray()
{
    if (arrayRaces == INVALID_HANDLE)
        arrayRaces = CreateArray();

    return bool:(arrayRaces != INVALID_HANDLE);
}

ClearRaceArray()
{
    if (arrayRaces == INVALID_HANDLE)
    {
        new raceCount = GetRaceCount();
        for(new race=0;race<raceCount;race++)
        {
            new Handle:vec=GetArrayCell(arrayRaces,race);
            new Handle:stringsHandle=GetArrayCell(vec,RACE_STRINGS);
            ClearArray(stringsHandle);
            CloseHandle(stringsHandle);

            new Handle:upgradeListHandle=GetArrayCell(vec,RACE_UPGRADES);

            new upgradeCount = GetArraySize(upgradeListHandle);
            for(new upgrade=0;upgrade<upgradeCount;upgrade++)
            {
                new Handle:upgradeStringsHandle=GetArrayCell(upgradeListHandle,UPGRADE_STRINGS);
                ClearArray(upgradeStringsHandle);
                CloseHandle(upgradeStringsHandle);
            }

            ClearArray(upgradeListHandle);
            CloseHandle(upgradeListHandle);

            ClearArray(vec);
            CloseHandle(vec);
        }
        ClearArray(arrayRaces);
        CloseHandle(arrayRaces);
        arrayRaces = INVALID_HANDLE;
    }
}

CreateRace(const String:name[],                  const String:short[],
           const String:switchmessage_instant[], const String:switchmessage_dead[],
           required_level, max_level)
{
    // Setup Race Strings.
    new Handle:stringsHandle=CreateArray(ByteCountToCells(192));
    PushArrayString(stringsHandle,name);
    PushArrayString(stringsHandle,short);
    PushArrayString(stringsHandle,switchmessage_instant);
    PushArrayString(stringsHandle,switchmessage_dead);

    // Setup Race Upgrade array.
    new Handle:upgradeListHandle=CreateArray();

    // Setup Race Data.
    new Handle:raceHandle=CreateArray();
    PushArrayCell(raceHandle,stringsHandle);
    PushArrayCell(raceHandle,upgradeListHandle);
    PushArrayCell(raceHandle,LoadRaceIdent(short, name)); // from the Database
    PushArrayCell(raceHandle,required_level);
    PushArrayCell(raceHandle,max_level);

    // Add new Race Data into Race Array.
    new raceId = PushArrayCell(arrayRaces,raceHandle); // return index.
    return raceId;
}

AddUpgrade(Handle:raceHandle, const String:name[], const String:short[], const String:desc[],
           bool:ultimate, required_level, max_level)
{
    if (required_level < 0)
        required_level = (ultimate ? MIN_ULTIMATE_LEVEL : 0);

    new Handle:upgradeStringHandle=CreateArray(ByteCountToCells(192));
    PushArrayString(upgradeStringHandle,name);
    PushArrayString(upgradeStringHandle,short);
    PushArrayString(upgradeStringHandle,desc);

    new Handle:upgradeHandle=CreateArray();
    PushArrayCell(upgradeHandle,upgradeStringHandle);
    PushArrayCell(upgradeHandle,required_level);
    PushArrayCell(upgradeHandle,max_level);
    PushArrayCell(upgradeHandle,ultimate);

    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    return PushArrayCell(upgradeListHandle, upgradeHandle); // return index
}

Handle:GetRaceHandle(racenum)
{
    return (racenum >= 0) ? GetArrayCell(arrayRaces,racenum) : INVALID_HANDLE;
}

GetRaceIdent(Handle:raceHandle)
{
    return (raceHandle != INVALID_HANDLE) ? GetArrayCell(raceHandle,RACE_IDENT) : 0;
}

GetRaceRequiredLevel(Handle:raceHandle)
{
    return GetArrayCell(raceHandle,RACE_REQUIRED_LEVEL);
}

GetRaceMaxLevel(Handle:raceHandle)
{
    return GetArrayCell(raceHandle,RACE_MAX_LEVEL);
}

GetRaceName(Handle:raceHandle, String:name[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    if (stringsHandle != INVALID_HANDLE)
        GetArrayString(stringsHandle,RACE_NAME,name,maxlength);
}

GetRaceShortName(Handle:raceHandle, String:name[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    if (stringsHandle != INVALID_HANDLE)
        GetArrayString(stringsHandle,RACE_SHORT_NAME,name,maxlength);
}

GetRaceSwitchMessage(Handle:raceHandle, String:message[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    if (stringsHandle != INVALID_HANDLE)
        GetArrayString(stringsHandle,RACE_SWITCHMESSAGE,message,maxlength);
}

GetRaceSwitchMessageDead(Handle:raceHandle, String:message[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    if (stringsHandle != INVALID_HANDLE)
        GetArrayString(stringsHandle,RACE_SWITCHMESSAGE_DEAD,message,maxlength);
}

GetUpgradeName(Handle:raceHandle,upgrade, String:name[], maxlength)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        if (upgradeHandle != INVALID_HANDLE)
        {
            new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
            if (upgradeStringHandle != INVALID_HANDLE)
                GetArrayString(upgradeStringHandle,UPGRADE_NAME, name,maxlength);
        }
    }
}

stock GetUpgradeShortName(Handle:raceHandle,upgrade, String:name[], maxlength)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        if (upgradeHandle != INVALID_HANDLE)
        {
            new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
            if (upgradeStringHandle != INVALID_HANDLE)
                GetArrayString(upgradeStringHandle,UPGRADE_SHORT_NAME, name,maxlength);
        }
    }
}

stock GetUpgradeDesc(Handle:raceHandle,upgrade, String:desc[], maxlength)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        if (upgradeHandle != INVALID_HANDLE)
        {
            new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
            if (upgradeStringHandle != INVALID_HANDLE)
                GetArrayString(upgradeStringHandle,UPGRADE_DESC, name,maxlength);
        }
    }
}

GetUpgradeNameAndDesc(Handle:raceHandle,upgrade, String:name[], maxName,
                      String:desc[], maxDesc)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        if (upgradeHandle != INVALID_HANDLE)
        {
            new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
            if (upgradeStringHandle != INVALID_HANDLE)
            {
                GetArrayString(upgradeStringHandle, UPGRADE_NAME, name, maxName);
                GetArrayString(upgradeStringHandle, UPGRADE_DESC, desc, maxDesc);
            }
        }
    }
}

GetUpgradeRequiredLevel(Handle:raceHandle,upgrade)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        if (upgradeHandle != INVALID_HANDLE)
            return GetArrayCell(upgradeHandle, UPGRADE_REQUIRED_LEVEL);
    }
    return -1;
}

GetUpgradeMaxLevel(Handle:raceHandle,upgrade)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        if (upgradeHandle != INVALID_HANDLE)
            return GetArrayCell(upgradeHandle, UPGRADE_MAX_LEVEL);
    }
    return -1;
}

bool:IsUpgradeUltimate(Handle:raceHandle,upgrade)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        if (upgradeHandle != INVALID_HANDLE)
            return bool:GetArrayCell(upgradeHandle, UPGRADE_ULTIMATE);
    }
    return false;
}

GetUpgradeCount(Handle:raceHandle)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
        return GetArraySize(upgradeListHandle);
    else
        return -1;
}

FindRace(const String:name[])
{
    decl String:curName[64];
    new size = GetArraySize(arrayRaces);
    for(new race=0;race<size;race++)
    {
        GetRaceShortName(GetRaceHandle(race),curName,sizeof(curName));
        if(StrEqual(name,curName,false))
            return race;
    }
    return -1;
}

FindRaceForIdent(ident)
{
    new size = GetArraySize(arrayRaces);
    for(new race=0;race<size;race++)
    {
        if (GetRaceIdent(GetRaceHandle(race)) == ident)
            return race;
    }
    return -1;
}

PendingCheck(client,Handle:playerHandle)
{
    new pendingrace=GetPendingRace(playerHandle);
    if (pendingrace > -1)
    {
        decl String:buf[192];
        SetPendingRace(playerHandle,-1);
        SetRace(playerHandle,pendingrace);
        new Handle:raceHandle=GetRaceHandle(pendingrace);
        GetRaceSwitchMessage(raceHandle, buf,sizeof(buf));
        PrintToChat(client,"%c[SourceCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
    }

    if (GetPendingUpgradeReset(playerHandle))
    {
        SetPendingUpgradeReset(playerHandle,0);
        ResetUpgradesNow(client,playerHandle);
    }
}

ChangeRace(client, Handle:playerHandle, race, Handle:raceHandle)
{
    decl String:buf[192];
    if(IsPlayerAlive(client) && m_FirstSpawn[client] < 2)
    {
        SetPendingRace(playerHandle,race);
        GetRaceSwitchMessageDead(raceHandle, buf,sizeof(buf));
        PrintToChat(client,"%c[SourceCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
    }
    else
    {
        SetPendingRace(playerHandle,-1);
        SetRace(playerHandle,race);
        GetRaceSwitchMessage(raceHandle, buf,sizeof(buf));
        PrintToChat(client, "%c[SourceCraft] %c%s", COLOR_GREEN,COLOR_DEFAULT,buf);
        m_FirstSpawn[client]=0;
        LogMessage("Reset Firstspawn in ChangeRace()");
    }
}

ResetUpgrades(client,Handle:playerHandle)
{
    if (IsPlayerAlive(client))
    {
        SetPendingUpgradeReset(playerHandle,1);
        PrintToChat(client,"%c[SourceCraft] %cYour upgrades for your current race will be reset when you die or respawn.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
    else
        ResetUpgradesNow(client,playerHandle);
}

ResetUpgradesNow(client,Handle:playerHandle)
{
    new race=GetRace(playerHandle);
    SetActiveUltimate(playerHandle,race,-1);

    new upgradeCount=GetUpgradeCount(GetRaceHandle(race));
    for(new upgrade=0;upgrade<upgradeCount;upgrade++)
    {
        SetUpgradeLevel(playerHandle,race,upgrade,0);
        SetSavedUpgradeLevel(playerHandle,race,upgrade,-1);
    }

    PrintToChat(client,"%c[SourceCraft] %cYour upgrades have been reset for your current race.",
                COLOR_GREEN,COLOR_DEFAULT);

    if(GetLevel(playerHandle,race) > 0)
        UpgradeMenu(client, playerHandle);
}

UpgradesInfo(client,race,bool:change)
{
    new maxUpgradeLevel, requiredLevel;
    decl String:minLevel[64];
    decl String:name[64];
    decl String:buf[192];

    new Handle:menu=CreateMenu(UpgradesInfo_Selected);
    SetMenuExitButton(menu,true);

    new Handle:raceHandle=GetRaceHandle(race);
    GetRaceName(raceHandle, name, sizeof(name));
    SetMenuTitle(menu,"[%s] Select an upgrade for more info.", name);

    if (change)
    {
        Format(name,sizeof(name),"%d",race);
        AddMenuItem(menu,name,"Change to this Race");
        AddMenuItem(menu,"","",ITEMDRAW_SPACER);
    }

    new String:ult[] = "Ultimate:";
    new maxLevel = GetRaceMaxLevel(raceHandle);
    new upgradeCount = GetUpgradeCount(raceHandle);
    for(new upgrade=0;upgrade<upgradeCount;upgrade++)
    {
        requiredLevel=GetUpgradeRequiredLevel(raceHandle,upgrade);
        maxUpgradeLevel=GetUpgradeMaxLevel(raceHandle,upgrade);

        if (requiredLevel > maxLevel || maxUpgradeLevel <= 0)
            Format(minLevel,sizeof(minLevel)," [Not Available]");
        else if (requiredLevel > 1)
            Format(minLevel,sizeof(minLevel)," [Minimum Level %d]", requiredLevel);
        else
            minLevel[0] = 0;

        if (IsUpgradeUltimate(raceHandle, upgrade))
            ult[0] = 'U';
        else
            ult[0] = 0;

        GetUpgradeName(raceHandle, upgrade, name, sizeof(name));

        Format(buf,sizeof(buf),"%s%s%s",ult,name,minLevel);
        AddMenuItem(menu,"",buf);
    }

    gRaceForUpgrades[client] = race;
    gUpgradesMenuMode[client] = change;
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public UpgradesInfo_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            new race=gRaceForUpgrades[client];
            new Handle:raceHandle=GetRaceHandle(race);
            if (selection < GetUpgradeCount(raceHandle))
                UpgradesInfo_Upgrade(client,raceHandle,selection);
            else // They decided to change to this race.
                ChangeRace(client, playerHandle, race, raceHandle);
        }
    }
}

public UpgradesInfo_Back(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
        UpgradesInfo(client,gRaceForUpgrades[client],gUpgradesMenuMode[client]);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            EmitSoundToClient(client,buttonWav);
            UpgradesInfo(client,gRaceForUpgrades[client],gUpgradesMenuMode[client]);
        }
    }
}

UpgradesInfo_Upgrade(client,Handle:raceHandle,upgrade)
{
    decl String:name[64];
    decl String:desc[256];

    new Handle:menu=CreateMenu(UpgradesInfo_Back);
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,true);

    GetUpgradeNameAndDesc(raceHandle, upgrade, name, sizeof(name), desc, sizeof(desc));

    SetMenuTitle(menu,"Upgrade information for %s\nDescription: %s",name,desc);
    AddMenuItem(menu,"","Back to the upgrades");
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

ShowUpgrades(client,target,Handle:playerHandle)
{
    new race=GetRace(playerHandle);
    new Handle:raceHandle=GetRaceHandle(race);
    new Handle:panel=CreatePanel();

    decl String:name[64];
    GetRaceName(raceHandle, name, sizeof(name));

    decl String:buffer[256];
    if (client == target)
        Format(buffer,sizeof(buffer),"[SourceCraft] Here are your %s upgrade levels.", name);
    else
        Format(buffer,sizeof(buffer),"[SourceCraft] Here are %N's %s upgrade levels.", target, name);

    SetPanelTitle(panel,buffer);

    decl String:buf[64];
    decl String:bufout[256];
    DrawPanelText(panel,"-----------------------------");
    new upgradeCount = GetUpgradeCount(raceHandle);
    for(new upgrade=0;upgrade<upgradeCount;upgrade++)
    {
        GetUpgradeName(raceHandle, upgrade, buf, sizeof(buf));
        Format(bufout,sizeof(bufout),"%s - Level %d",buf,GetUpgradeLevel(playerHandle,race,upgrade));
        DrawPanelText(panel,bufout);
    }
    DrawPanelText(panel,"-----------------------------");
    DrawPanelItem(panel,"Close");

    gShowUpgradesTarget[client]=target;
    SendPanelToClient(panel,client,ShowUpgrades_Selected,0);
    CloseHandle(panel);
}

public ShowUpgrades_Selected(Handle:menu,MenuAction:action,client,selection)
{
}

