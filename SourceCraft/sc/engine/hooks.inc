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

    RegConsoleCmd("sc_menu",SCMenuCommand,"use SourceCraft menu to change race, reset upgrades, etc...");
    RegConsoleCmd("sc_shopmenu",BuyCommand,"use SourceCraft shopmenu to purchase shop items");
    RegConsoleCmd("sc_buy",BuyCommand,"Purchase a SourceCraft Item");

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
    new Handle:playerHandle=GetPlayerHandle(client);
    if (playerHandle != INVALID_HANDLE)
    {
        decl String:arg[64];
        GetCmdArg(1,arg,sizeof(arg));
        if(CommandCheck(arg,"showexperience",sizeof(arg)) ||
           CommandCheck(arg,"showxp",63))
        {
            ShowXP(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"changerace",sizeof(arg)))
        {
            RaceMenu(client,true);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"raceinfo",sizeof(arg)))
        {
            RaceMenu(client,false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg,"upgradeinfo",sizeof(arg)) ||
                 CommandCheck(arg,"skillsinfo",63))
        {
            UpgradesInfo(client,GetRace(playerHandle),false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg,"reset",sizeof(arg)) ||
                 CommandCheck(arg,"resetupgrade",sizeof(arg)) ||
                 CommandCheck(arg,"resetupgrades",sizeof(arg)) ||
                 CommandCheck(arg,"resetskills",sizeof(arg)))
        {
            ResetUpgrades(client,playerHandle);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg,"upgrade",sizeof(arg)) ||
                 CommandCheck(arg,"spendupgrade",sizeof(arg)) ||
                 CommandCheck(arg,"spendupgrades",sizeof(arg)) ||
                 CommandCheck(arg,"spendskills",sizeof(arg)))
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
        else if(CommandCheck(arg,"showupgrade",sizeof(arg)) ||
                CommandCheck(arg,"showupgrades",sizeof(arg)) ||
                CommandCheck(arg,"showskills",sizeof(arg)))
        {
            ShowUpgrades(client,client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"crystals",sizeof(arg)) || 
                CommandCheck(arg,"showcrystals",sizeof(arg)) ||
                CommandCheck(arg,"showcredits",sizeof(arg)))
        {
            ShowCredits(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"shopmenu",sizeof(arg)) ||
                CommandCheck(arg,"scbuy",sizeof(arg)) ||
                CommandCheck(arg,"buy",sizeof(arg)))
        {
            GetCmdArg(2,arg,sizeof(arg));
            new item = FindShopItem(arg);
            if (item > -1)
                PurchaseShopItem(client, playerHandle, item);
            else
                ShopMenu(client,true);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"showitems",sizeof(arg)) ||
                CommandCheck(arg,"inventory",sizeof(arg)) ||
                CommandCheck(arg,"inven",sizeof(arg)) ||
                CommandCheck(arg,"inv",sizeof(arg)))
        {
            ShopMenu(client,false);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"schelp",sizeof(arg)) ||
                CommandCheck(arg,"help",sizeof(arg)))
        {
            Help(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"scmenu",sizeof(arg)) ||
                CommandCheck(arg,"menu",sizeof(arg)))
        {
            MainMenu(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"scsave",sizeof(arg)) ||
                CommandCheck(arg,"save",sizeof(arg)))
        {
            if (SavePlayerData(client, playerHandle, false))
                PrintToChat(client,"%c[SourceCraft] %cSaved data to Database.",
                            COLOR_GREEN,COLOR_DEFAULT);
            else
                PrintToChat(client,"%c[SourceCraft] %cSaving data to Database.",
                            COLOR_GREEN,COLOR_DEFAULT);
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
        new result;
        new race=GetRace(playerHandle);
        new bool:pressed=false;
        if(!strcmp(command,"+ultimate"))
            pressed=true;

        Call_StartForward(g_OnUltimateCommandHandle);
        Call_PushCell(client);
        Call_PushCell(playerHandle);
        Call_PushCell(race);
        Call_PushCell(pressed);
        Call_Finish(result);
    }
    return Plugin_Handled;
}
 
public Action:SCMenuCommand(client,args)
{
    MainMenu(client);
    return Plugin_Handled;
}

public Action:BuyCommand(client,args)
{
    new Handle:playerHandle=GetPlayerHandle(client);
    if (playerHandle != INVALID_HANDLE)
    {
        decl String:arg[32];
        GetCmdArg(1,arg,sizeof(arg));
        new item = FindShopItem(arg);
        if (item > -1)
            PurchaseShopItem(client, playerHandle, item);
        else
            ShopMenu(client,true);
    }
    return Plugin_Handled;
}

public Action:ChangelevelCommand(client,args)
{
    decl String:arg[32];
    GetCmdArg(1,arg,sizeof(arg));
    LogMessage("ChangelevelCommand(%s)", arg);
    g_MapChanging = true;
    return Plugin_Continue;
}

