/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: hooks.inc
 * Description: Handles hooking functions, will be used to get chat commands.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

bool:InitHooks()
{
    RegConsoleCmd("say",SayCommand);
    RegConsoleCmd("say_team",SayCommand);
    RegConsoleCmd("changelevel",ChangelevelCommand);
    RegConsoleCmd("shopmenu",ShopMenuCommand,"use SourceCraft shopmenu to purchase shop items");
    RegConsoleCmd("sc_menu",SCMenuCommand,"use SourceCraft menu to change race, reset upgrades, etc...");
    RegConsoleCmd("+ultimate",UltimateCommand,"use SourceCraft ultimate ability (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate",UltimateCommand,"use SourceCraft ultimate ability (keyup)",FCVAR_GAMEDLL);
    return true;
}

bool:CommandCheck(const String:compare[], const String:command[], maxlen)
{
    decl String:command2[maxlen+1];
    decl String:command3[maxlen+1];
    Format(command2,maxlen,"\\%s",command);
    Format(command3,maxlen,"/%s",command);
    if(!strcmp(compare,command,false) || !strcmp(compare,command2,false) ||
       !strcmp(compare,command3,false))
    {
        return true;
    }
    else
	    return false;
}

public Action:SayCommand(client,args)
{
    decl String:arg1[32];
    GetCmdArg(1,arg1,sizeof(arg1));
    new Handle:playerHandle=GetPlayerHandle(client);
    if (playerHandle != INVALID_HANDLE)
    {
        if(CommandCheck(arg1,"showexperience",63) ||
           CommandCheck(arg1,"showxp",63))
        {
            ShowXP(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"changerace",63))
        {
            RaceMenu(client,true);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"raceinfo",63))
        {
            RaceMenu(client,false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg1,"upgradeinfo",63) ||
                 CommandCheck(arg1,"skillsinfo",63))
        {
            UpgradesInfo(client,GetRace(playerHandle),false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg1,"reset",63) ||
                 CommandCheck(arg1,"resetupgrade",63) ||
                 CommandCheck(arg1,"resetupgrades",63) ||
                 CommandCheck(arg1,"resetskills",63))
        {
            ResetUpgrades(client,playerHandle);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg1,"upgrade",63) ||
                 CommandCheck(arg1,"spendupgrade",63) ||
                 CommandCheck(arg1,"spendupgrades",63) ||
                 CommandCheck(arg1,"spendskills",63))
        {
            new race=GetRace(playerHandle);
            if(GetUpgradeLevelCount(playerHandle,race)<GetLevel(playerHandle,race))
                UpgradeMenu(client,playerHandle);
            else
            {
                PrintToChat(client,"%c[SourceCraft] %cYou don't have any upgrade points to spend, if you want to reset your upgrades use reset.",COLOR_GREEN,COLOR_DEFAULT);
            }
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"showupgrade",63) ||
                CommandCheck(arg1,"showupgrades",63) ||
                CommandCheck(arg1,"showskills",63))
        {
            ShowUpgrades(client,client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"crystals",63) || 
                CommandCheck(arg1,"showcrystals",63) ||
                CommandCheck(arg1,"showcredits",63))
        {
            ShowCredits(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"shopmenu",63))
        {
            ShopMenu(client,true);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"showitems",63) ||
                CommandCheck(arg1,"inventory",63) ||
                CommandCheck(arg1,"inven",63) ||
                CommandCheck(arg1,"inv",63))
        {
            ShopMenu(client,false);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"schelp",63) ||
                CommandCheck(arg1,"help",63))
        {
            Help(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"scmenu",63) ||
                CommandCheck(arg1,"menu",63))
        {
            MainMenu(client);
            return Plugin_Handled;
        }
	}
    return Plugin_Continue;
}
 
public Action:UltimateCommand(client,args)
{
    decl String:command[32];
    GetCmdArg(0,command,32);
    new Handle:playerHandle=GetPlayerHandle(client);
    if (playerHandle != INVALID_HANDLE)
    {
        new race=GetRace(playerHandle);
        new bool:pressed=false;
        if(!strcmp(command,"+ultimate"))
            pressed=true;

        Call_StartForward(g_OnUltimateCommandHandle);
        Call_PushCell(client);
        Call_PushCell(playerHandle);
        Call_PushCell(race);
        Call_PushCell(pressed);
        new result;
        Call_Finish(result);
    }
    return Plugin_Handled;
}
 
public Action:ShopMenuCommand(client,args)
{
    ShopMenu(client,true);
    return Plugin_Handled;
}
 
public Action:SCMenuCommand(client,args)
{
    MainMenu(client);
    return Plugin_Handled;
}

public Action:ChangelevelCommand(client,args)
{
    decl String:arg1[32];
    GetCmdArg(1,arg1,sizeof(arg1));
    LogMessage("ChangelevelCommand(%s)", arg1);
    g_MapChanging = true;
    return Plugin_Continue;
}

