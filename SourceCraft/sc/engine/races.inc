/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: races.inc
 * Description: The root of all race specific stuff.
 * Author(s): Anthony Iacono  
 */

#define SKILL_COUNT 4
#define SKILL_ULTIMATE 3 // Index of the Ultimate, starting at 0

#define RACE_IDENT              0
#define RACE_REQUIRED_LEVEL     1
#define RACE_STRINGS            2
#define RACE_SKILLS             3

#define RACE_NAME               0
#define RACE_SHORT_NAME         1
#define RACE_SWITCHMESSAGE      2
#define RACE_SWITCHMESSAGE_DEAD 3

#define RACE_SKILL              0
#define RACE_SKILL_DESC         1
#define RACE_SKILL_2            2
#define RACE_SKILL_2_DESC       3
#define RACE_SKILL_3            4
#define RACE_SKILL_3_DESC       5
#define RACE_ULTIMATE           6
#define RACE_ULTIMATE_DESC      7

#define RACE_COUNT() GetArraySize(arrayRaces)

// A vector of race infomation
new Handle:arrayRaces;

new Function:gSkillsInfoParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new bool:gSkillsMenuMode[MAXPLAYERS+1];
new gShowSkillsTarget[MAXPLAYERS+1];
new gRaceForSkills[MAXPLAYERS+1];

public CreateRace(const String:name[],                  const String:short[],
                  const String:switchmessage_instant[], const String:switchmessage_dead[],
                  const String:skill1[],                const String:skill1_desc[],
                  const String:skill2[],                const String:skill2_desc[],
                  const String:skill3[],                const String:skill3_desc[],
                  const String:ult[],                   const String:ult_desc[],
                  required_level)
{
    new Handle:newRace=CreateArray();

    // Setup Race Strings.
    new Handle:stringsHandle=CreateArray(ByteCountToCells(192));
    PushArrayString(stringsHandle,name);
    PushArrayString(stringsHandle,short);
    PushArrayString(stringsHandle,switchmessage_instant);
    PushArrayString(stringsHandle,switchmessage_dead);

    new Handle:skillsHandle=CreateArray(); // Races's skills
    PushArrayString(skillsHandle,skill1);
    PushArrayString(skillsHandle,skill1_desc);
    PushArrayString(skillsHandle,skill2);
    PushArrayString(skillsHandle,skill2_desc);
    PushArrayString(skillsHandle,skill3);
    PushArrayString(skillsHandle,skill3_desc);
    PushArrayString(skillsHandle,ult);
    PushArrayString(skillsHandle,ult_desc);

    // Setup Race Data.
    PushArrayCell(newRace,SaveRaceInfo(short,name)); // ident from the Database
    PushArrayCell(newRace,required_level);
    PushArrayCell(newRace,stringsHandle);
    PushArrayCell(newRace,skillsHandle);

    // Add new Race Data into Race Array.
    return PushArrayCell(arrayRaces,newRace); // return index.
}

public bool:InitRaceArray()
{
    arrayRaces=CreateArray();
    return bool:(arrayRaces != INVALID_HANDLE);
}

public ClearRaceArray()
{
    new raceCount = RACE_COUNT();
    for(new x=0;x<raceCount;x++)
    {
        new Handle:vec=GetArrayCell(arrayRaces,x);
        new Handle:stringsHandle=GetArrayCell(vec,RACE_STRINGS);
        new Handle:skillsHandle=GetArrayCell(vec,RACE_SKILLS);
        ClearArray(stringsHandle);
        ClearArray(skillsHandle);
        ClearArray(vec);
    }
    ClearArray(arrayRaces);
}

public Handle:GetRaceHandle(racenum)
{
    return GetArrayCell(arrayRaces,racenum);
}

public GetRaceIdent(Handle:raceHandle)
{
    return GetArrayCell(raceHandle,RACE_IDENT);
}

public GetRaceRequiredLevel(Handle:raceHandle)
{
    return GetArrayCell(raceHandle,RACE_REQUIRED_LEVEL);
}

public Handle:GetRaceStrings(Handle:raceHandle)
{
    return GetArrayCell(raceHandle,RACE_STRINGS);
}

public GetRaceName(Handle:raceHandle, String:name[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    GetArrayString(stringsHandle,RACE_NAME,name,maxlength);
}

public GetRaceShortName(Handle:raceHandle, String:name[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    GetArrayString(stringsHandle,RACE_SHORT_NAME,name,maxlength);
}

public GetRaceSwitchMessage(Handle:raceHandle, String:message[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    GetArrayString(stringsHandle,RACE_SWITCHMESSAGE,message,maxlength);
}

public GetRaceSwitchMessageDead(Handle:raceHandle, String:message[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(raceHandle,RACE_STRINGS);
    GetArrayString(stringsHandle,RACE_SWITCHMESSAGE_DEAD,message,maxlength);
}

public GetSkillName(Handle:raceHandle,skill, String:name[], maxlength)
{
    new Handle:skillsHandle=GetArrayCell(raceHandle,RACE_SKILLS);
    GetArrayString(skillsHandle,(skill*2),name,maxlength);
}

public GetSkillDesc(Handle:raceHandle,skill, String:desc[], maxlength)
{
    new Handle:skillsHandle=GetArrayCell(raceHandle,RACE_SKILLS);
    GetArrayString(skillsHandle,(skill*2)+1,desc,maxlength);
}

public GetSkillNameAndDesc(Handle:raceHandle,skill, String:name[], maxName,
                           String:desc[], maxDesc)
{
    new Handle:skillsHandle=GetArrayCell(raceHandle,RACE_SKILLS);
    new index = (skill*2);
    GetArrayString(skillsHandle,index,name,maxName);
    GetArrayString(skillsHandle,index+1,desc,maxDesc);
}

public FindRace(const String:name[])
{
    decl String:curName[64]="";
    new size = GetArraySize(arrayRaces);
    for(new race=0;race<size;race++)
    {
        GetRaceShortName(GetRaceHandle(race),curName,sizeof(curName));
        if(StrEqual(name,curName,false))
            return race;
    }
    return -1;
}

public FindRaceForIdent(ident)
{
    new size = GetArraySize(arrayRaces);
    for(new race=0;race<size;race++)
    {
        if (GetRaceIdent(GetRaceHandle(race)) == ident)
            return race;
    }
    return -1;
}

public PendingCheck(client,Handle:playerHandle)
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

    if (GetPendingSkillReset(playerHandle))
    {
        SetPendingSkillReset(playerHandle,0);
        ResetSkillsNow(client,playerHandle);
    }
}

public SkillsInfo_Back(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        SkillsInfo(client,gRaceForSkills[client],gSkillsMenuMode[client],
                   gSkillsInfoParentMenuFunction[client]);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");
            SkillsInfo(client,gRaceForSkills[client],gSkillsMenuMode[client],
                       gSkillsInfoParentMenuFunction[client]);
        }
    }
}

public SkillsInfo_Skill(client,Handle:raceHandle,skill)
{
    decl String:name[64];
    decl String:desc[256];

    new Handle:menu=CreateMenu(SkillsInfo_Back);
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,true);

    GetSkillNameAndDesc(raceHandle, skill, name, sizeof(name), desc, sizeof(desc));

    SetMenuTitle(menu,"Skill information for %s\nDescription: %s",name,desc);
    AddMenuItem(menu,"","Back to the skills");
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public SkillsInfo(client,race,bool:change,Function:parentMenuFunction)
{
    decl String:name[64];

    new Handle:menu=CreateMenu(SkillsInfo_Selected);
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,(parentMenuFunction != INVALID_FUNCTION));

    new Handle:raceHandle=GetRaceHandle(race);
    GetRaceName(raceHandle, name, sizeof(name));
    SetMenuTitle(menu,"[%s] Select a skill for more info.", name);

    for(new skill=0;skill<SKILL_COUNT;skill++)
    {
        GetSkillName(raceHandle, skill, name, sizeof(name));
        AddMenuItem(menu,"",name);
    }
    if (change)
    {
        Format(name,sizeof(name),"%d",race);
        AddMenuItem(menu,"","",ITEMDRAW_SPACER);
        AddMenuItem(menu,name,"Change to this Race");
    }

    gRaceForSkills[client] = race;
    gSkillsMenuMode[client] = change;
    gSkillsInfoParentMenuFunction[client]=parentMenuFunction;
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public SkillsInfo_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            new race=gRaceForSkills[client];
            new Handle:raceHandle=GetRaceHandle(race);
            if (selection < SKILL_COUNT)
                SkillsInfo_Skill(client,raceHandle,selection);
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
    else if (action == MenuAction_Cancel)
    {
        new Function:backFn = gSkillsInfoParentMenuFunction[client];
        if (selection == MenuCancel_ExitBack && backFn != INVALID_FUNCTION)
        {
            decl result;
            ClientCommand(client,"play buttons/button14.wav");
            Call_StartFunction(INVALID_HANDLE, backFn);
            Call_PushCell(client);

            if (backFn == RaceMenu)
                Call_PushCell(gSkillsMenuMode[client]);
            else
                Call_PushCell(GetPlayerHandle(client));

            Call_PushCell(INVALID_FUNCTION);
            Call_Finish(result);
        }
    }
}

public ResetSkills(client,Handle:playerHandle)
{
    if(IsPlayerAlive(client))
    {
        SetPendingSkillReset(playerHandle,1);
        PrintToChat(client,"%c[SourceCraft] %cYour skills for your current race will be reset when you die or respawn.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
    else
        ResetSkillsNow(client,playerHandle);
}

public ShowSkills(client,target,Handle:playerHandle,Function:parentMenuFunction)
{
    new race=GetRace(playerHandle);
    new Handle:raceHandle=GetRaceHandle(race);
    new Handle:panel=CreatePanel();

    decl String:name[64];
    GetRaceName(raceHandle, name, sizeof(name));

    decl String:buffer[256];
    if (client == target)
        Format(buffer,sizeof(buffer),"[SourceCraft] Here are your %s skill levels.", name);
    else
        Format(buffer,sizeof(buffer),"[SourceCraft] Here are %N's %s skill levels.", target, name);

    SetPanelTitle(panel,buffer);

    decl String:buf[64];
    decl String:bufout[256];
    DrawPanelText(panel,"-----------------------------");
    for(new skill=0;skill<SKILL_COUNT;skill++)
    {
        GetSkillName(raceHandle, skill, buf, sizeof(buf));
        Format(bufout,sizeof(bufout),"%s - Level %d",buf,GetSkillLevel(playerHandle,race,skill));
        DrawPanelText(panel,bufout);
    }
    DrawPanelText(panel,"-----------------------------");
    DrawPanelItem(panel,"Close");

    gShowSkillsTarget[client]=target;
    gSkillsInfoParentMenuFunction[client]=parentMenuFunction;
    SendPanelToClient(panel,client,ShowSkills_Selected,0);
    CloseHandle(panel);
}

public ShowSkills_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (gSkillsInfoParentMenuFunction[client] != INVALID_FUNCTION)
    {
        decl result;
        ClientCommand(client,"play buttons/button14.wav");
        Call_StartFunction(INVALID_HANDLE, gSkillsInfoParentMenuFunction[client]);
        Call_PushCell(client);
        Call_PushCell(gShowSkillsTarget[client]);
        Call_PushCell(INVALID_FUNCTION);
        Call_Finish(result);
    }
}

ResetSkillsNow(client,Handle:playerHandle)
{
    new race=GetRace(playerHandle);
    for(new skill=0;skill<SKILL_COUNT;skill++)
        SetSkillLevel(playerHandle,race,skill,0);

    PrintToChat(client,"%c[SourceCraft] %cYour skills have been reset for your current race.",
                COLOR_GREEN,COLOR_DEFAULT);

    if(GetLevel(playerHandle,race) > 0)
        SkillMenu(client, playerHandle, INVALID_FUNCTION);

    SavePlayerData(client,playerHandle,false);
}
