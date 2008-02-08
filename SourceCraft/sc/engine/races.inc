/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: races.inc
 * Description: The root of all race specific stuff.
 * Author(s): Anthony Iacono  
 */

#define SKILL_COUNT 4
#define SKILL_ULTIMATE 3 // Yes, its the 4th, but 3th when you are talking iteriators

#define RACE_NAME               0
#define RACE_SHORT_NAME         1
#define RACE_SWITCHMESSAGE      2
#define RACE_SWITCHMESSAGE_DEAD 3
#define RACE_SKILL_1            4
#define RACE_SKILL_1_DESC       5
#define RACE_SKILL_2            6
#define RACE_SKILL_2_DESC       7
#define RACE_SKILL_3            8
#define RACE_SKILL_3_DESC       9
#define RACE_ULTIMATE          10
#define RACE_ULTIMATE_DESC     11
#define RACE_REQUIRED_LEVEL    12

// Functions called from menus.inc
//public SkillMenu(client, vectorpos, Function:parentMenuFunction);

// A vector of race infomation
new Handle:arrayRaces;

new Function:gSkillsInfoParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new bool:gSkillsMenuMode[MAXPLAYERS+1];
new gShowSkillsTarget[MAXPLAYERS+1];
new gRaceForSkills[MAXPLAYERS+1];

public Handle:CreateRace(const String:name[],                  const String:short[],
                         const String:switchmessage_instant[], const String:switchmessage_dead[],
                         const String:skill1[],                const String:skill1_desc[],
                         const String:skill2[],                const String:skill2_desc[],
                         const String:skill3[],                const String:skill3_desc[],
                         const String:ult[],                   const String:ult_desc[],
                         const String:required_level[])
{
    new Handle:ret=CreateArray(ByteCountToCells(192));
    PushArrayString(ret,name);
    PushArrayString(ret,short);
    PushArrayString(ret,switchmessage_instant);
    PushArrayString(ret,switchmessage_dead);
    PushArrayString(ret,skill1);
    PushArrayString(ret,skill1_desc);
    PushArrayString(ret,skill2);
    PushArrayString(ret,skill2_desc);
    PushArrayString(ret,skill3);
    PushArrayString(ret,skill3_desc);
    PushArrayString(ret,ult);
    PushArrayString(ret,ult_desc);
    PushArrayString(ret,required_level);
    return ret;
}

public bool:InitiatearrayRaces()
{
    arrayRaces=CreateArray();
    return true;
}

public Handle:Race(racenum)
{
    return GetArrayCell(arrayRaces,racenum);
}

public GetRaceName(Handle:race, String:name[], maxlength)
{
    GetArrayString(race,RACE_NAME,name,maxlength);
}

public GetRaceShortName(Handle:race, String:name[], maxlength)
{
    GetArrayString(race,RACE_SHORT_NAME,name,maxlength);
}

public FindRace(const String:name[])
{
    decl String:curName[64]="";
    new size = GetArraySize(arrayRaces);
    for(new x=0;x<size;x++)
    {
        new Handle:race=GetArrayCell(arrayRaces,x);
        GetArrayString(race,RACE_SHORT_NAME,curName,sizeof(curName));
        if(StrEqual(name,curName,false))
            return x;
    }
    return -1;
}

public PendingCheck(client,vectorpos)
{
    new pendingrace=GetPendingRace(vectorpos);
    if(pendingrace>-1)
    {
        SetPendingRace(vectorpos,-1);
        SetRace(vectorpos,pendingrace);
        decl String:buf[192];
        new Handle:race=Race(GetRace(vectorpos));
        GetArrayString(race,2,buf,191);
        PrintToChat(client,"%c[SourceCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
    }

    if (GetPendingSkillReset(vectorpos))
    {
        SetPendingSkillReset(vectorpos,0);
        ResetSkillsNow(client,vectorpos);
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
    new Handle:menu=CreateMenu(SkillsInfo_Back);
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,true);

    decl String:name[64];
    GetArrayString(raceHandle,4+(skill*2),name,sizeof(name));
    decl String:desc[256];
    GetArrayString(raceHandle,4+(skill*2)+1,desc,sizeof(desc));

    SetMenuTitle(menu,"Skill information for %s\nDescription: %s",name,desc);
    AddMenuItem(menu,"","Back to the skills");
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public SkillsInfo(client,race,bool:change,Function:parentMenuFunction)
{
    new Handle:menu=CreateMenu(SkillsInfo_Selected);
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,(parentMenuFunction != INVALID_FUNCTION));

    decl String:name[64];
    new Handle:raceHandle=Race(race);
    GetRaceName(raceHandle,name,sizeof(name));
    SetMenuTitle(menu,"[%s] Select a skill for more info.", name);

    decl String:buf[64];
    for(new x=0;x<SKILL_COUNT;x++)
    {
        GetArrayString(raceHandle,4+(x*2),buf,sizeof(buf));
        AddMenuItem(menu,"",buf);
    }
    if (change)
    {
        Format(buf,sizeof(buf),"%d",race);
        AddMenuItem(menu,"","",ITEMDRAW_SPACER);
        AddMenuItem(menu,buf,"Change to this Race");
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
        new vecpos=GetClientVectorPosition(client);
        if(vecpos>-1)
        {
            new race=gRaceForSkills[client];
            new Handle:raceHandle=Race(race);
            if (selection < SKILL_COUNT)
                SkillsInfo_Skill(client,raceHandle,selection);
            else
            {
                // They decided to change to this race.
                if(IsPlayerAlive(client) && m_FirstSpawn[client] < 2)
                {
                    SetPendingRace(vecpos,race);
                    decl String:buf[192];
                    GetArrayString(raceHandle,3,buf,sizeof(buf));
                    PrintToChat(client,"%c[SourceCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
                }
                else
                {
                    SetPendingRace(vecpos,-1);
                    SetRace(vecpos,race);
                    decl String:buf[192];
                    GetArrayString(raceHandle,2,buf,sizeof(buf));
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
                Call_PushCell(GetClientVectorPosition(client));

            Call_PushCell(INVALID_FUNCTION);
            Call_Finish(result);
        }
    }
}

public ResetSkills(client,vecpos)
{
    if(IsPlayerAlive(client))
    {
        SetPendingSkillReset(vecpos,1);
        PrintToChat(client,"%c[SourceCraft] %cYour skills for your current race will be reset when you die or respawn.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
    else
        ResetSkillsNow(client,vecpos);
}

public ShowSkills(client,target,vecpos,Function:parentMenuFunction)
{
    new race=GetRace(vecpos);
    new Handle:raceHandle=Race(race);
    new Handle:panel=CreatePanel();

    if (client == target)
        SetPanelTitle(panel,"[SourceCraft] Here are your skill levels.");
    else
    {
        decl String:buffer[256];
        Format(buffer,sizeof(buffer),"[SourceCraft] Here are %N's skill levels.", target);
        SetPanelTitle(panel,buffer);
    }

    decl String:buf[64];
    decl String:bufout[256];
    DrawPanelText(panel,"-----------------------------");
    for(new x=0;x<SKILL_COUNT;x++)
    {
        GetArrayString(raceHandle,4+(x*2),buf,sizeof(buf));
        Format(bufout,sizeof(bufout),"%s - Level %d",buf,GetSkillLevel(vecpos,race,x));
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

ResetSkillsNow(client,vecpos)
{
    new race=GetRace(vecpos);
    for(new x=0;x<SKILL_COUNT;x++)
        SetSkillLevel(vecpos,race,x,0);

    PrintToChat(client,"%c[SourceCraft] %cYour skills have been reset for your current race.",
                COLOR_GREEN,COLOR_DEFAULT);

    if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
        SkillMenu(client, vecpos, INVALID_FUNCTION);
}
