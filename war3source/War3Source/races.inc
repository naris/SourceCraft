/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: races.inc
 * Description: The root of all race specific stuff.
 * Author(s): Anthony Iacono  
 */

#define RACE_COUNT GetArraySize(arrayRaces)
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
public War3Source_SkillMenu(client, vectorpos, Function:parentMenuFunction);

// A vector of race infomation
new Handle:arrayRaces;

new Handle:currentRaceForSkills[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

new Function:gSkillsInfoParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};

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

public bool:War3Source_InitiatearrayRaces()
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

public War3Source_PendingCheck(client,vectorpos)
{
    new pendingrace=GetPendingRace(vectorpos);
    if(pendingrace>-1)
    {
        SetPendingRace(vectorpos,-1);
        SetRace(vectorpos,pendingrace);
        decl String:buf[192];
        new Handle:race=Race(GetRace(vectorpos));
        GetArrayString(race,2,buf,191);
        PrintToChat(client,"%c[JigglyCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
    }

    if (GetPendingSkillReset(vectorpos))
    {
        SetPendingSkillReset(vectorpos,0);
        ResetSkills(client,vectorpos);
    }
}

public War3Source_SkillsInfo_Back(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");

        new Handle:raceHandle = currentRaceForSkills[client];
        if(raceHandle == INVALID_HANDLE)
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                raceHandle=Race(race);
            }
        }
        War3Source_ShowSkillsInfo(client,raceHandle,gSkillsInfoParentMenuFunction[client]);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");

            new Handle:raceHandle = currentRaceForSkills[client];
            if(raceHandle == INVALID_HANDLE)
            {
                new vecpos=GetClientVectorPosition(client);
                if(vecpos>-1)
                {
                    new race=GetRace(vecpos);
                    raceHandle=Race(race);
                }
            }
            War3Source_ShowSkillsInfo(client,raceHandle,gSkillsInfoParentMenuFunction[client]);
        }
    }
}

public War3Source_SkillsInfo_Skill(client,Handle:raceHandle,skill)
{
    new Handle:menu=CreateMenu(War3Source_SkillsInfo_Back);
    SetMenuExitButton(menu,true);
    //new Handle:raceHandle=Race(race);
    decl String:name[64];
    GetArrayString(raceHandle,4+(skill*2),name,sizeof(name));
    decl String:desc[256];
    GetArrayString(raceHandle,4+(skill*2)+1,desc,sizeof(desc));
    SetMenuTitle(menu,"Skill information for %s\nDescription: %s",name,desc);
    AddMenuItem(menu,"","Back to the skills");
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,true);
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public War3Source_SkillsInfo_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new vecpos=GetClientVectorPosition(client);
        if(vecpos>-1)
        {
            new skill=selection;
            //new Handle:race=GetRace(Race(vecpos));
            new Handle:race=currentRaceForSkills[client];
            War3Source_SkillsInfo_Skill(client,race,skill);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack &&
            gSkillsInfoParentMenuFunction[client] != INVALID_FUNCTION)
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos >- 1)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gSkillsInfoParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(vecpos);
                Call_Finish(result);
            }
        }
    }
}

public War3Source_ShowSkills_Selected(Handle:menu,MenuAction:action,client,selection)
{
}

public War3Source_SkillsInfo(client,vecpos)
{
    new race=GetRace(vecpos);
    new Handle:raceHandle=Race(race);
    War3Source_ShowSkillsInfo(client, raceHandle, INVALID_FUNCTION);
}

public War3Source_ShowSkillsInfo(client, Handle:raceHandle, Function:parentMenuFunction)
{
    new Handle:menu=CreateMenu(War3Source_SkillsInfo_Selected);
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,(parentMenuFunction != INVALID_FUNCTION));

    decl String:name[64];
    GetRaceName(raceHandle,name,sizeof(name));
    SetMenuTitle(menu,"[%s] Select a skill for more info.", name);

    decl String:buf[64];
    for(new x=0;x<SKILL_COUNT;x++)
    {
        GetArrayString(raceHandle,4+(x*2),buf,sizeof(buf));
        AddMenuItem(menu,"",buf);
    }
    currentRaceForSkills[client] = raceHandle;
    gSkillsInfoParentMenuFunction[client]=parentMenuFunction;
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public War3Source_ResetSkills(client,vecpos)
{
    if(IsPlayerAlive(client))
    {
        SetPendingSkillReset(vecpos,1);
        PrintToChat(client,"%c[JigglyCraft] %cYour skills for your current race will be reset when you die or respawn.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
    else
        ResetSkills(client,vecpos);
}

public War3Source_ShowSkills(client,vecpos)
{
    new race=GetRace(vecpos);
    new Handle:raceHandle=Race(race);
    new Handle:panel=CreatePanel();

    SetPanelTitle(panel,"[JigglyCraft] Here are your skill levels.");

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
    SendPanelToClient(panel,client,War3Source_ShowSkills_Selected,0);
}

ResetSkills(client,vecpos)
{
    {
        new race=GetRace(vecpos);
        for(new x=0;x<SKILL_COUNT;x++)
            SetSkillLevel(vecpos,race,x,0);

        PrintToChat(client,"%c[JigglyCraft] %cYour skills have been reset for your current race.",
                    COLOR_GREEN,COLOR_DEFAULT);

        if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
            War3Source_SkillMenu(client, vecpos, INVALID_FUNCTION);
    }
}
