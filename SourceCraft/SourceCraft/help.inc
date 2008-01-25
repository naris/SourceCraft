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

new Function:gHelpParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};

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

public bool:InitiateHelpVector()
{
    vecHelpCommands=CreateArray();
    return true;
}

public InitHelpCommands()
{
    NewHelpCommand("say scmenu","Bring up the SourceCraft menu.");
    NewHelpCommand("say showxp","Show the current experience information for the current race.");
    NewHelpCommand("say changerace","Change to a different race.");
    NewHelpCommand("say raceinfo","Display information for all the races.");
    NewHelpCommand("say skillsinfo","Display the skill information for the current race.");
    NewHelpCommand("say resetskills","Resets all your skill levels for the current race and allows you to rechoose.");
    NewHelpCommand("say spendskills","Spend any unused skill points you have.");
    NewHelpCommand("say showskills","Show which skill levels you currently have.");
    NewHelpCommand("say shopmenu","Bring up the shop menu to buy items.");

    decl String:currencies[64];
    GetConVarString(m_Currencies, currencies, 63);
    if (!StrEqual(currencies, "credits"))
    {
        decl String:name[64];
        Format(name,63,"say show%s", currencies);
        decl String:desc[128];
        Format(desc,127,"Show your current %s count.", currencies,127);
        NewHelpCommand(name,desc);
    }
    else
        NewHelpCommand("say showcredits","Show your current shop credit count.");

    NewHelpCommand("+ultimate","Use an ultimate that required a bind.");
    NewHelpCommand("sc_admin","Bring up the admin menu to modify player info.");
}

public Help(client,Function:parentMenuFunction)
{
    new Handle:helpMenu=CreateMenu(HelpMenu_Selected);
    SetMenuExitButton(helpMenu,true);
    SetMenuExitBackButton(helpMenu,(parentMenuFunction != INVALID_FUNCTION));
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
    gHelpParentMenuFunction[client]=parentMenuFunction;
    DisplayMenu(helpMenu,client,MENU_TIME_FOREVER);
}

public HelpMenu_Selected(Handle:menu,MenuAction:action,client,selection)
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
            HelpMenu_Command(client,command);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack &&
            gHelpParentMenuFunction[client] != INVALID_FUNCTION)
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos >- 1)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gHelpParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(vecpos);
                Call_PushCell(INVALID_FUNCTION);
                Call_Finish(result);
            }
        }
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
    SetMenuTitle(helpMenu_Command,"[SourceCraft] War3Source Command - %s\n%s",name,desc);
    AddMenuItem(helpMenu_Command,"backtohelp","Back to help commands");
    DisplayMenu(helpMenu_Command,client,MENU_TIME_FOREVER);
}

public HM_Command_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        Help(client,gHelpParentMenuFunction[client]);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
        if (selection == MenuEnd_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");
            Help(client,gHelpParentMenuFunction[client]);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}
