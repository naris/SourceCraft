/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: races.inc
 * Description: The root of all race specific stuff.
 * Author(s): Anthony Iacono  
 */

#define RACE_COUNT GetArraySize(arrayRaces)
#define SKILL_COUNT 4
#define SKILL_ULTIMATE 3 // Yes, its the 4th, but 3th when you are talking iteriators

// A vector of race infomation
new Handle:arrayRaces;

new Handle:currentRaceForSkills[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

public Handle:CreateRace(String:name[],String:short[],String:switchmessage_instant[],String:switchmessage_dead[],String:skill1[],String:skill1_desc[],String:skill2[],String:skill2_desc[],String:skill3[],String:skill3_desc[],String:ult[],String:ult_desc[])
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
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
    }
}

public War3Source_SkillsInfo_Back(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");

        new Handle:raceHandle = currentRaceForSkills[client];
        if(raceHandle != INVALID_HANDLE)
            War3Source_ShowSkillsInfo(client,raceHandle);
        else
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos>-1)
                War3Source_SkillsInfo(client,vecpos);
        }
    }
}

public War3Source_SkillsInfo_Skill(client,race,skill)
{
    new Handle:menu=CreateMenu(War3Source_SkillsInfo_Back);
    SetMenuExitButton(menu,true);
    new Handle:raceHandle=Race(race);
    decl String:name[64];
    GetArrayString(raceHandle,4+(skill*2),name,63);
    decl String:desc[256];
    GetArrayString(raceHandle,4+(skill*2)+1,desc,255);
    SetMenuTitle(menu,"[War3Source] Skill information for %s\nDescription: %s",name,desc);
    AddMenuItem(menu,"","Back to the skills");
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
            new race=GetRace(vecpos);
            War3Source_SkillsInfo_Skill(client,race,skill);
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
    War3Source_ShowSkillsInfo(client, raceHandle);
}

public War3Source_ShowSkillsInfo(client, Handle:raceHandle)
{
    new Handle:menu=CreateMenu(War3Source_SkillsInfo_Selected);
    SetMenuExitButton(menu,true);
    SetMenuTitle(menu,"[War3Source] Select a skill for more info.");
    decl String:buf[64];
    for(new x=0;x<SKILL_COUNT;x++)
    {
        GetArrayString(raceHandle,4+(x*2),buf,63);
        AddMenuItem(menu,"",buf);
    }
    currentRaceForSkills[client] = raceHandle;
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public War3Source_ResetSkills(client,vecpos)
{
    new race=GetRace(vecpos);
    if(!GetLifestate(client))
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou are not allowed to resetskills while alive.",COLOR_GREEN,COLOR_DEFAULT);
    else
    {
        for(new x=0;x<SKILL_COUNT;x++)
            SetSkillLevel(vecpos,race,x,0);
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYour skills have been reset for your current race.",COLOR_GREEN,COLOR_DEFAULT);
        if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
            War3Source_SkillMenu(client,vecpos);
    }
}

public War3Source_ShowSkills(client,vecpos)
{
    new race=GetRace(vecpos);
    new Handle:raceHandle=Race(race);
    new Handle:panel=CreatePanel();
    SetPanelTitle(panel,"[War3Source] Here are your skill levels.");
    decl String:buf[64];
    decl String:bufout[256];
    DrawPanelText(panel,"-----------------------------");
    for(new x=0;x<SKILL_COUNT;x++)
    {
        GetArrayString(raceHandle,4+(x*2),buf,63);
        Format(bufout,255,"%s - Level %d",buf,GetSkillLevel(vecpos,race,x));
        DrawPanelText(panel,bufout);
    }
    DrawPanelText(panel,"-----------------------------");
    DrawPanelItem(panel,"Close");
    SendPanelToClient(panel,client,War3Source_ShowSkills_Selected,0);
}
