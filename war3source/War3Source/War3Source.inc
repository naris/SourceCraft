/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source.inc
 * Description: Holds all the War3Source specific functions.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */
 
// Temporary Definitions
new Handle:arrayPlayers = INVALID_HANDLE;

// ConVar definitions
new Handle:m_SaveXPConVar = INVALID_HANDLE;
new Handle:m_MinimumUltimateLevel = INVALID_HANDLE;
new Handle:m_MaxCredits = INVALID_HANDLE;

// DBI
new Handle:DBIDB = INVALID_HANDLE;

enum Mod { other, tf2, cstrike, dod, hl2mp };
new Mod:GameType = other;

#define SAVE_ENABLED GetConVarInt(m_SaveXPConVar)==1
#define MIN_ULTIMATE_LEVEL GetConVarInt(m_MinimumUltimateLevel)
#define MAX_CREDITS GetConVarInt(m_MaxCredits)

// War3Source Includes
#include "War3Source/immunity"
#include "War3Source/offsets"
#include "War3Source/messages"
#include "War3Source/races"
#include "War3Source/xp"
#include "War3Source/events"
#include "War3Source/events_tf2"
#include "War3Source/events_cstrike"
#include "War3Source/credits"
#include "War3Source/console"
#include "War3Source/shopmenu"
#include "War3Source/playertracking"
#include "War3Source/natives"
#include "War3Source/hooks"
#include "War3Source/menus"
#include "War3Source/log"

// SourceMod stuff
#include <keyvalues>

new Handle:vecHelpCommands       = INVALID_HANDLE;
new Handle:vecLevelConfiguration = INVALID_HANDLE;

#define HELPCOMMAND_COUNT GetArraySize(vecHelpCommands)

public bool:War3Source_ParseSettings()
{
    new Handle:keyValue=CreateKeyValues("War3SourceSettings");
    decl String:path[1024];
    BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
    FileToKeyValues(keyValue,path);
    decl String:error[256];
    DBIDB=SQL_DefConnect(error,255);
    if(!DBIDB)
    {
        // TODO: Tell them that they didn't get a good DBI connection.
        LogError("Unable to get a Database Connection.");
    }
    // Load level configuration
    KvRewind(keyValue);
    vecLevelConfiguration=CreateArray();
    if(!KvJumpToKey(keyValue,"levels"))
    {
        LogError("KvJumpToKey failed in ParseSettings");
        return false;
    }
    new Handle:longterm_required=CreateArray();
    new Handle:longterm_killxp=CreateArray();
    new Handle:shortterm_required=CreateArray();
    new Handle:shortterm_killxp=CreateArray();
    decl String:temp[2048];
    if(!KvGotoFirstSubKey(keyValue))
    {
        LogError("KvJumpToKey failed in ParseSettings");
        return false;
    }
    // required xp, long term
    KvGetString(keyValue,"required_xp",temp,2047);
    new tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for required xp, long term in ParseSettings");
        return false;
    }
    decl String:temp_iter[16];
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(longterm_required,StringToInt(temp_iter));
    }
    // kill xp, long term
    KvGetString(keyValue,"kill_xp",temp,2047);
    tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for kill xp, long term in ParseSettings");
        return false;
    }
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(longterm_killxp,StringToInt(temp_iter));
    }
    if(!KvGotoNextKey(keyValue))
    {
        LogError("KvGotoNextKey failed in ParseSettings");
        return false;
    }
    // required xp, short term
    KvGetString(keyValue,"required_xp",temp,2047);
    tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for required xp, short term in ParseSettings");
        return false;
    }
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(shortterm_required,StringToInt(temp_iter));
    }
    // kill xp, short term
    KvGetString(keyValue,"kill_xp",temp,2047);
    tokencount=StrTokenCount(temp);
    if(tokencount!=MAX_LEVELS+1)
    {
        LogError("Invalid tokencount for kill xp, short term in ParseSettings");
        return false;
    }
    for(new x=1;x<=tokencount;x++)
    {
        // store it
        StrToken(temp,x,temp_iter,15);
        PushArrayCell(shortterm_killxp,StringToInt(temp_iter));
    }
    PushArrayCell(vecLevelConfiguration,longterm_required);
    PushArrayCell(vecLevelConfiguration,longterm_killxp);
    PushArrayCell(vecLevelConfiguration,shortterm_required);
    PushArrayCell(vecLevelConfiguration,shortterm_killxp);
    return true;
}

KillXP(level)
{
    new Handle:temp;
    if(SAVE_ENABLED)
        temp=GetArrayCell(vecLevelConfiguration,1);
    else
        temp=GetArrayCell(vecLevelConfiguration,3);
    if(GetArraySize(temp)==MAX_LEVELS+1)
        return GetArrayCell(temp,level);
    return 0;
}

ReqLevelXP(level)
{
    new Handle:temp;
    if(SAVE_ENABLED)
        temp=GetArrayCell(vecLevelConfiguration,0);
    else
        temp=GetArrayCell(vecLevelConfiguration,2);
    if(GetArraySize(temp)==MAX_LEVELS+1)
        return GetArrayCell(temp,level);
    return 0;
}

public Handle:HelpItem(command)
{
    return GetArrayCell(vecHelpCommands,command);
}

public NewHelpCommand(String:name[],String:info[])
{
    new Handle:vec=CreateArray(ByteCountToCells(256));
    PushArrayString(vec,name);
    PushArrayString(vec,info);
    PushArrayCell(vecHelpCommands,vec);
}

public bool:War3Source_InitiateHelpVector()
{
    vecHelpCommands=CreateArray();
    return true;
}

public War3Source_InitHelpCommands()
{
    NewHelpCommand("say war3menu","Don't like keyboard shortcuts? You can \naccess all the menu-based functions from here.");
    NewHelpCommand("say showxp","Show the current experience information for the current race.");
    NewHelpCommand("say changerace","Change to a different race.");
    NewHelpCommand("say skillsinfo","Display the skill information for the current race.");
    NewHelpCommand("say resetskills","Resets all your skill levels for the current race and allows you to rechoose.");
    NewHelpCommand("say spendskills","Spend any unused skill points you have.");
    NewHelpCommand("say showskills","Show which skill levels you currently have.");
    NewHelpCommand("say showcredits","Show your current shop credit count.");
    NewHelpCommand("say shopmenu","Bring up the shop menu at which you can buy items.");
    NewHelpCommand("+ultimate","Use an ultimate that required a bind.");
    NewHelpCommand("war3admin","Bring up the admin menu at which you can modify player info.");
}

public War3Source_War3Help(client)
{
    new Handle:helpMenu=CreateMenu(War3Source_HelpMenu_Selected);
    SetMenuExitButton(helpMenu,true);
    SetMenuTitle(helpMenu,"[War3Source] Select a command for more info.");
    decl String:commandname[64];
    decl String:helpbuf[4];
    new Handle:commandHandle;
    for(new x=0;x<HELPCOMMAND_COUNT;x++)
    {
        Format(helpbuf,3,"%d",x);
        commandHandle=HelpItem(x);
        GetArrayString(commandHandle,0,commandname,63);
        AddMenuItem(helpMenu,helpbuf,commandname);
    }
    DisplayMenu(helpMenu,client,MENU_TIME_FOREVER);
}

public War3Source_HelpMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new command=StringToInt(SelectionInfo);
        if(command>-1&&command<HELPCOMMAND_COUNT)
            War3Source_HelpMenu_Command(client,command);
    }
}

public War3Source_HelpMenu_Command(client,command)
{
    new Handle:helpMenu_Command=CreateMenu(War3Source_HM_Command_Select);
    SetMenuExitButton(helpMenu_Command,true);
    decl String:name[64];
    new Handle:helpCommandHandle=HelpItem(command);
    GetArrayString(helpCommandHandle,0,name,63);
    decl String:desc[300];
    GetArrayString(helpCommandHandle,1,desc,299);
    Format(desc,299,"Description: %s",desc);
    SetMenuTitle(helpMenu_Command,"[War3Source] War3Source Command - %s\n%s",name,desc);
    AddMenuItem(helpMenu_Command,"backtohelp","Back to help commands");
    DisplayMenu(helpMenu_Command,client,MENU_TIME_FOREVER);
}

public War3Source_HM_Command_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        War3Source_War3Help(client);
    }
}

// Stocks
stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
    new String:buf[maxlen+1];
    new cur_idx;
    new idx;
    new curind;
    idx=BreakString(inputstr,buf,maxlen);
    if(tokennum==1)
    {
        strcopy(outputstr,maxlen,buf);
        return;
    }
    curind=1;
    while(idx!=-1)
    {
        cur_idx+=idx;
        idx=BreakString(inputstr[cur_idx],buf,maxlen);
        curind++;
        if(tokennum==curind)
        {
            strcopy(outputstr,maxlen,buf);
            break;
        }
    }
}

stock StrTokenCount(const String:input[])
{
    decl String:buf[32];
    new cur_idx;
    new idx;
    new curind;
    while(idx!=-1)
    {
        cur_idx+=idx;
        idx=BreakString(input[cur_idx],buf,31);
        curind++;
    }
    return curind;
}
