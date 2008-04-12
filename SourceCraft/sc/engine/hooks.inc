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
    RegConsoleCmd("sc_buy",BuyCommand,"Purchase a SourceCraft Item");
    RegConsoleCmd("shopmenu",BuyCommand,"use SourceCraft shopmenu to purchase shop items");
    RegConsoleCmd("changerace",ChangeRaceCommand,"SourceCraft command to change race.");

    RegConsoleCmd("+ultimate",UltimateCommand,"use SourceCraft ultimate ability (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate",UltimateCommand,"use SourceCraft ultimate ability (keyup)",FCVAR_GAMEDLL);
    return true;
}

bool:CommandCheck(const String:compare[], const String:command[])
{
    if(!strcmp(compare,command,false))
        return true;
    else
    {
        new String:firstChar[] = " ";
        firstChar{0} = compare{0};
        if (StrContains("!/\\",firstChar) >= 0)
            return !strcmp(compare[1],command,false);
        else
	        return false;
    }
}

public Action:SayCommand(client,args)
{
    new Handle:playerHandle=GetPlayerHandle(client);
    if (playerHandle != INVALID_HANDLE)
    {
        decl String:command[128];
        GetCmdArg(1,command,sizeof(command));

        decl String:arg[2][64];
        ExplodeString(command, " ", arg, 2, 64);

        if(CommandCheck(arg[0],"showexperience") ||
           CommandCheck(arg[0],"showxp"))
        {
            ShowXP(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"changerace"))
        {
            if (strlen(arg[1]) > 0)
            {
                new race = FindRace(arg[1]);
                if (race >= 0)
                {
                    new Handle:raceHandle=GetRaceHandle(race);
                    if (raceHandle != INVALID_HANDLE)
                        ChangeRace(client, playerHandle, race, raceHandle);
                    else
                        RaceMenu(client,true);
                }
                else
                    RaceMenu(client,true);
            }
            else
                RaceMenu(client,true);

            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"raceinfo"))
        {
            RaceMenu(client,false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg[0],"upgradeinfo") ||
                 CommandCheck(arg[0],"skillsinfo"))
        {
            UpgradesInfo(client,GetRace(playerHandle),false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg[0],"reset") ||
                 CommandCheck(arg[0],"resetupgrade") ||
                 CommandCheck(arg[0],"resetupgrades") ||
                 CommandCheck(arg[0],"resetskills"))
        {
            ResetUpgrades(client,playerHandle);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg[0],"upgrade") ||
                 CommandCheck(arg[0],"spendupgrade") ||
                 CommandCheck(arg[0],"spendupgrades") ||
                 CommandCheck(arg[0],"spendskills"))
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
        else if(CommandCheck(arg[0],"showupgrade") ||
                CommandCheck(arg[0],"showupgrades") ||
                CommandCheck(arg[0],"showskills"))
        {
            ShowUpgrades(client,client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"crystals") || 
                CommandCheck(arg[0],"showcrystals") ||
                CommandCheck(arg[0],"showcredits"))
        {
            ShowCredits(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"shopmenu") ||
                CommandCheck(arg[0],"scbuy") ||
                CommandCheck(arg[0],"buy"))
        {
            if (strlen(arg[1]) > 0)
            {
                new item = FindShopItem(arg[1]);
                if (item >= 0)
                    PurchaseShopItem(client, playerHandle, item);
                else
                    ShopMenu(client,true);
            }
            else
                ShopMenu(client,true);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"showitems") ||
                CommandCheck(arg[0],"inventory") ||
                CommandCheck(arg[0],"inven") ||
                CommandCheck(arg[0],"inv"))
        {
            ShopMenu(client,false);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"schelp") ||
                CommandCheck(arg[0],"help"))
        {
            Help(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"scmenu") ||
                CommandCheck(arg[0],"menu"))
        {
            MainMenu(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg[0],"scsave") ||
                CommandCheck(arg[0],"save"))
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
    new Handle:playerHandle=GetPlayerHandle(client);
    if (playerHandle != INVALID_HANDLE)
    {
        new result;
        new race=GetRace(playerHandle);
        new bool:pressed=false;

        decl String:command[32];
        GetCmdArg(0,command,sizeof(command));
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
        decl String:arg[64];
        if (GetCmdArg(1,arg,sizeof(arg)) > 0)
        {
            new item = FindShopItem(arg);
            if (item >= 0)
                PurchaseShopItem(client, playerHandle, item);
            else
                ShopMenu(client,true);
        }
        else
            ShopMenu(client,true);
    }
    return Plugin_Handled;
}

public Action:ChangeRaceCommand(client,args)
{
    new Handle:playerHandle=GetPlayerHandle(client);
    if (playerHandle != INVALID_HANDLE)
    {
        decl String:arg[64];
        if (GetCmdArg(1,arg,sizeof(arg)) > 0)
        {
            new race = FindRace(arg);
            if (race >= 0)
            {
                new Handle:raceHandle=GetRaceHandle(race);
                if (raceHandle != INVALID_HANDLE)
                    ChangeRace(client, playerHandle, race, raceHandle);
                else
                    RaceMenu(client,true);
            }
            else
                RaceMenu(client,true);
        }
        else
            RaceMenu(client,true);
    }
    return Plugin_Handled;
}


public Action:ChangelevelCommand(client,args)
{
    g_MapChanging = true;
    return Plugin_Continue;
}

