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
    RegConsoleCmd("sc_changerace",BuyCommand,"SourceCraft command to change race.");

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
        decl String:arg[64];
        GetCmdArg(1,arg,sizeof(arg));
        if(CommandCheck(arg,"showexperience") ||
           CommandCheck(arg,"showxp"))
        {
            ShowXP(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"changerace"))
        {
            GetCmdArg(2,arg,sizeof(arg));
            if (strlen(arg) > 0)
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

            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"raceinfo"))
        {
            RaceMenu(client,false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg,"upgradeinfo") ||
                 CommandCheck(arg,"skillsinfo"))
        {
            UpgradesInfo(client,GetRace(playerHandle),false);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg,"reset") ||
                 CommandCheck(arg,"resetupgrade") ||
                 CommandCheck(arg,"resetupgrades") ||
                 CommandCheck(arg,"resetskills"))
        {
            ResetUpgrades(client,playerHandle);
            return Plugin_Handled;
        }
        else if (CommandCheck(arg,"upgrade") ||
                 CommandCheck(arg,"spendupgrade") ||
                 CommandCheck(arg,"spendupgrades") ||
                 CommandCheck(arg,"spendskills"))
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
        else if(CommandCheck(arg,"showupgrade") ||
                CommandCheck(arg,"showupgrades") ||
                CommandCheck(arg,"showskills"))
        {
            ShowUpgrades(client,client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"crystals") || 
                CommandCheck(arg,"showcrystals") ||
                CommandCheck(arg,"showcredits"))
        {
            ShowCredits(client,playerHandle);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"shopmenu") ||
                CommandCheck(arg,"scbuy") ||
                CommandCheck(arg,"buy"))
        {
            GetCmdArg(2,arg,sizeof(arg));
            if (strlen(arg) > 0)
            {
                new item = FindShopItem(arg);
                if (item >= 0)
                    PurchaseShopItem(client, playerHandle, item);
                else
                    ShopMenu(client,true);
            }
            else
                ShopMenu(client,true);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"showitems") ||
                CommandCheck(arg,"inventory") ||
                CommandCheck(arg,"inven") ||
                CommandCheck(arg,"inv"))
        {
            ShopMenu(client,false);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"schelp") ||
                CommandCheck(arg,"help"))
        {
            Help(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"scmenu") ||
                CommandCheck(arg,"menu"))
        {
            MainMenu(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg,"scsave") ||
                CommandCheck(arg,"save"))
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
        decl String:arg[64];
        GetCmdArg(1,arg,sizeof(arg));
        new item = FindShopItem(arg);
        if (item > -1)
            PurchaseShopItem(client, playerHandle, item);
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
        GetCmdArg(1,arg,sizeof(arg));
        if (strlen(arg) > 0)
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

