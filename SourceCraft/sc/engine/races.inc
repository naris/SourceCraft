/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: races.inc
 * Description: The root of all race specific stuff.
 * Author(s): Anthony Iacono  
 */

#define RACE_IDENT              0
#define RACE_REQUIRED_LEVEL     1
#define RACE_STRINGS            2
#define RACE_UPGRADE_FLAGS      3
#define RACE_UPGRADE_STRINGS    4
#define RACE_DATA_COUNT         5

#define RACE_NAME               0
#define RACE_SHORT_NAME         1
#define RACE_SWITCHMESSAGE      2
#define RACE_SWITCHMESSAGE_DEAD 3
#define RACE_STRING_COUNT       4

#define UPGRADE_NAME            0
#define UPGRADE_SHORT_NAME      1
#define UPGRADE_DESC            2
#define UPGRADE_DATA_COUNT      3

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
        for(new x=0;x<raceCount;x++)
        {
            new Handle:vec=GetArrayCell(arrayRaces,x);
            new Handle:stringsHandle=GetArrayCell(vec,RACE_STRINGS);
            ClearArray(stringsHandle);
            CloseHandle(stringsHandle);

            new Handle:upgradeFlagsHandle=GetArrayCell(vec,RACE_UPGRADE_FLAGS);
            ClearArray(upgradeFlagsHandle);
            CloseHandle(upgradeFlagsHandle);

            new Handle:upgradeStringsHandle=GetArrayCell(vec,RACE_UPGRADE_STRINGS);
            ClearArray(upgradeStringsHandle);
            CloseHandle(upgradeStringsHandle);

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
           required_level)
{
    new Handle:newRace=CreateArray();

    // Setup Race Strings.
    new Handle:stringsHandle=CreateArray(ByteCountToCells(192));
    PushArrayString(stringsHandle,name);
    PushArrayString(stringsHandle,short);
    PushArrayString(stringsHandle,switchmessage_instant);
    PushArrayString(stringsHandle,switchmessage_dead);

    // Setup Race Upgrade arrays.
    new Handle:upgradeStringsHandle=CreateArray(ByteCountToCells(192));
    new Handle:upgradeFlagsHandle=CreateArray();

    // Setup Race Data.
    PushArrayCell(newRace,SaveRaceInfo(short,name)); // ident from the Database
    PushArrayCell(newRace,required_level);
    PushArrayCell(newRace,stringsHandle);
    PushArrayCell(newRace,upgradeFlagsHandle);
    PushArrayCell(newRace,upgradeStringsHandle);

    // Add new Race Data into Race Array.
    return PushArrayCell(arrayRaces,newRace); // return index.
}

AddUpgrade(Handle:race, const String:name[], const String:short[], const String:desc[], bool:ultimate)
{
    new Handle:upgradeStringsHandle=GetArrayCell(race,RACE_UPGRADE_STRINGS);
    PushArrayString(upgradeStringsHandle,name);
    PushArrayString(upgradeStringsHandle,short);
    PushArrayString(upgradeStringsHandle,desc);

    new Handle:upgradeFlagsHandle=GetArrayCell(race,RACE_UPGRADE_FLAGS);
    return PushArrayCell(upgradeFlagsHandle, ultimate); // return index
}

Handle:GetRaceHandle(racenum)
{
    return GetArrayCell(arrayRaces,racenum);
}

GetRaceIdent(Handle:raceHandle)
{
    return GetArrayCell(raceHandle,RACE_IDENT);
}

GetRaceRequiredLevel(Handle:raceHandle)
{
    return GetArrayCell(raceHandle,RACE_REQUIRED_LEVEL);
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
    new Handle:upgradeStringsHandle=GetArrayCell(raceHandle,RACE_UPGRADE_STRINGS);
    if (upgradeStringsHandle != INVALID_HANDLE)
        GetArrayString(upgradeStringsHandle,(upgrade*UPGRADE_DATA_COUNT) /* +UPGRADE_NAME */,
                       name,maxlength);
}

stock GetUpgradeShortName(Handle:raceHandle,upgrade, String:name[], maxlength)
{
    new Handle:upgradeStringsHandle=GetArrayCell(raceHandle,RACE_UPGRADE_STRINGS);
    if (upgradeStringsHandle != INVALID_HANDLE)
        GetArrayString(upgradeStringsHandle,(upgrade*UPGRADE_DATA_COUNT)+UPGRADE_SHORT_NAME,
                       name,maxlength);
}

stock GetUpgradeDesc(Handle:raceHandle,upgrade, String:desc[], maxlength)
{
    new Handle:upgradeStringsHandle=GetArrayCell(raceHandle,RACE_UPGRADE_STRINGS);
    if (upgradeStringsHandle != INVALID_HANDLE)
        GetArrayString(upgradeStringsHandle,(upgrade*UPGRADE_DATA_COUNT)+UPGRADE_DESC,
                       desc,maxlength);
}

GetUpgradeNameAndDesc(Handle:raceHandle,upgrade, String:name[], maxName,
                      String:desc[], maxDesc)
{
    new Handle:upgradeStringsHandle=GetArrayCell(raceHandle,RACE_UPGRADE_STRINGS);
    if (upgradeStringsHandle != INVALID_HANDLE)
    {
        new index = (upgrade*UPGRADE_DATA_COUNT);
        GetArrayString(upgradeStringsHandle,index,name,maxName);
        GetArrayString(upgradeStringsHandle,index+UPGRADE_DESC,desc,maxDesc);
    }
}

bool:IsUpgradeUltimate(Handle:raceHandle,upgrade)
{
    new Handle:upgradeFlagsHandle=GetArrayCell(raceHandle,RACE_UPGRADE_FLAGS);
    if (upgradeFlagsHandle != INVALID_HANDLE)
        return bool:GetArrayCell(upgradeFlagsHandle, upgrade);
    else
        return false;
}

GetUpgradeCount(Handle:raceHandle)
{
    new Handle:upgradeFlagsHandle=GetArrayCell(raceHandle,RACE_UPGRADE_FLAGS);
    if (upgradeFlagsHandle != INVALID_HANDLE)
        return GetArraySize(upgradeFlagsHandle);
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
    if(pendingrace>-1)
    {
        SetPendingRace(playerHandle,-1);
        SetRace(playerHandle,pendingrace);
        decl String:buf[192];
        new Handle:raceHandle=GetRaceHandle(GetRace(playerHandle));
        GetRaceSwitchMessage(raceHandle, buf,sizeof(buf));
        PrintToChat(client,"%c[SourceCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
    }

    if (GetPendingUpgradeReset(playerHandle))
    {
        SetPendingUpgradeReset(playerHandle,0);
        ResetUpgradesNow(client,playerHandle);
    }
}

public UpgradesInfo_Back(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        UpgradesInfo(client,gRaceForUpgrades[client],gUpgradesMenuMode[client]);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");
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

UpgradesInfo(client,race,bool:change)
{
    decl String:name[64];

    new Handle:menu=CreateMenu(UpgradesInfo_Selected);
    SetMenuExitButton(menu,true);

    new Handle:raceHandle=GetRaceHandle(race);
    GetRaceName(raceHandle, name, sizeof(name));
    SetMenuTitle(menu,"[%s] Select a upgrade for more info.", name);

    new upgradeCount = GetUpgradeCount(raceHandle);
    for(new upgrade=0;upgrade<upgradeCount;upgrade++)
    {
        GetUpgradeName(raceHandle, upgrade, name, sizeof(name));
        AddMenuItem(menu,"",name);
    }
    if (change)
    {
        Format(name,sizeof(name),"%d",race);
        AddMenuItem(menu,"","",ITEMDRAW_SPACER);
        AddMenuItem(menu,name,"Change to this Race");
    }

    gRaceForUpgrades[client] = race;
    gUpgradesMenuMode[client] = change;
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public UpgradesInfo_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            new race=gRaceForUpgrades[client];
            new Handle:raceHandle=GetRaceHandle(race);
            if (selection < GetUpgradeCount(raceHandle))
                UpgradesInfo_Upgrade(client,raceHandle,selection);
            else
            {
                // They decided to change to this race.
                if(IsPlayerAlive(client) && m_FirstSpawn[client] < 2)
                {
                    SetPendingRace(playerHandle,race);
                    decl String:buf[192];
                    GetRaceSwitchMessageDead(raceHandle, buf,sizeof(buf));
                    PrintToChat(client,"%c[SourceCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
                }
                else
                {
                    SetPendingRace(playerHandle,-1);
                    SetRace(playerHandle,race);
                    decl String:buf[192];
                    GetRaceSwitchMessage(raceHandle, buf,sizeof(buf));
                    PrintToChat(client, "%c[SourceCraft] %c%s", COLOR_GREEN,COLOR_DEFAULT,buf);
                }
                m_FirstSpawn[client]=0;
            }
        }
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

ResetUpgradesNow(client,Handle:playerHandle)
{
    new race=GetRace(playerHandle);
    SetActiveUltimate(playerHandle,race,-1);

    new upgradeCount=GetUpgradeCount(GetRaceHandle(race));
    for(new upgrade=0;upgrade<upgradeCount;upgrade++)
        SetUpgradeLevel(playerHandle,race,upgrade,0);

    PrintToChat(client,"%c[SourceCraft] %cYour upgrades have been reset for your current race.",
                COLOR_GREEN,COLOR_DEFAULT);

    if(GetLevel(playerHandle,race) > 0)
        UpgradeMenu(client, playerHandle);
}
