/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: help.inc
 * Description: Holds all the help functions.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

#define HELPCOMMAND_COUNT GetArraySize(vecHelpCommands)

new Handle:vecHelpCommands       = INVALID_HANDLE;
new Handle:vecLevelConfiguration = INVALID_HANDLE;

bool:InitHelpVector()
{
    if (vecHelpCommands == INVALID_HANDLE)
        vecHelpCommands=CreateArray();

    return (vecHelpCommands != INVALID_HANDLE);
}

ClearHelpVector()
{
    if (vecHelpCommands != INVALID_HANDLE)
    {
        ClearArray(vecHelpCommands);
        CloseHandle(vecHelpCommands);
        vecHelpCommands = INVALID_HANDLE;
    }
}

Handle:HelpItem(command)
{
    return GetArrayCell(vecHelpCommands,command);
}

NewHelpCommand(String:name[],String:info[])
{
    new Handle:vec=CreateArray(ByteCountToCells(256));
    PushArrayString(vec,name);
    PushArrayString(vec,info);
    return PushArrayCell(vecHelpCommands,vec);
}

InitHelpCommands()
{
    NewHelpCommand("say menu","Bring up the SourceCraft menu.");
    NewHelpCommand("say showxp","Show the current experience information for the current race.");
    NewHelpCommand("say changerace","Change to a different race.");
    NewHelpCommand("say raceinfo","Display information for all the races.");
    NewHelpCommand("say upgradeinfo","Display the upgrade information for the current race.");
    NewHelpCommand("say reset","Resets all your upgrade levels for the current race and allows you to rechoose.");
    NewHelpCommand("say upgrade","Spend any unused upgrade points you have.");
    NewHelpCommand("say showupgrades","Show which upgrade levels you currently have.");
    NewHelpCommand("say shopmenu","Bring up the shop menu to buy items.");
    NewHelpCommand("say showcrystals","Show your current shop crystal count.");
    NewHelpCommand("+ultimate","Use an ultimate that requires a bind.");
    NewHelpCommand("sc_admin","Bring up the admin menu to modify player info.");
}

Help(client)
{
    new Handle:helpMenu=CreateMenu(HelpMenu_Selected);
    SetMenuExitButton(helpMenu,true);
    SetMenuTitle(helpMenu,"[SourceCraft] Select a command for more info.");
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

public HelpMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new command=StringToInt(SelectionInfo);
        if(command>-1&&command<HELPCOMMAND_COUNT)
            HelpMenu_Command(client,command);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public HelpMenu_Command(client,command)
{
    new Handle:helpMenu_Command=CreateMenu(HM_Command_Select);
    SetMenuExitButton(helpMenu_Command,true);
    SetMenuExitBackButton(helpMenu_Command,true);
    decl String:name[64];
    new Handle:helpCommandHandle=HelpItem(command);
    GetArrayString(helpCommandHandle,0,name,63);
    decl String:desc[300];
    GetArrayString(helpCommandHandle,1,desc,299);
    Format(desc,299,"Description: %s",desc);
    SetMenuTitle(helpMenu_Command,"SourceCraft Command - %s\n%s",name,desc);
    AddMenuItem(helpMenu_Command,"backtohelp","Back to help commands");
    DisplayMenu(helpMenu_Command,client,MENU_TIME_FOREVER);
}

public HM_Command_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
        Help(client);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
        if (selection == MenuEnd_ExitBack)
        {
            EmitSoundToClient(client,buttonWav);
            Help(client);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

