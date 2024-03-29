/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: hooks.inc
 * Description: Handles hooking functions, will be used to get chat commands.
 * Author(s): Naris (Murray Wilson)
 * Credits: Anthony Iacono
 */

InitHooks()
{
    AddCommandListener(SayCommand, "say");
    AddCommandListener(SayCommand, "say_team");
    AddCommandListener(ChangelevelCommand, "changelevel");

    RegConsoleCmd("sc_menu",SCMenuCommand,"use SourceCraft menu to change race, reset upgrades, etc...");
    RegConsoleCmd("sm_menu",SCMenuCommand,"use SourceCraft menu to change race, reset upgrades, etc...");
    RegConsoleCmd("sc_buy",BuyCommand,"Purchase a SourceCraft Item");
    RegConsoleCmd("sm_buy",BuyCommand,"Purchase a SourceCraft Item");
    RegConsoleCmd("shopmenu",BuyCommand,"use SourceCraft shopmenu to purchase shop items");
    RegConsoleCmd("changeunit",ChangeRaceCommand,"SourceCraft command to change unit.");
    RegConsoleCmd("changerace",ChangeRaceCommand,"SourceCraft command to change race.");
    RegConsoleCmd("sc_settings",ChangeSettingsCommand,"SourceCraft command to change settings.");
    RegConsoleCmd("sc_ds",ChangeDisplaySettingsCommand,"SourceCraft command to change display settings.");
    RegConsoleCmd("sc_gs",ChangeGameSettingsCommand,"SourceCraft command to change game settings.");
    RegConsoleCmd("sc_info",InfoCommand,"View SourceCraft Information and lookup players");
    RegConsoleCmd("sm_info",InfoCommand,"View SourceCraft Information and lookup players");
    RegConsoleCmd("sc_updates",UpdatesCommand,"View SourceCraft Updates");
    RegConsoleCmd("sm_updates",UpdatesCommand,"View SourceCraft Updates");
    RegConsoleCmd("sc_wiki",WikiCommand,"View SourceCraft Wiki");
    RegConsoleCmd("sm_wiki",WikiCommand,"View SourceCraft Wiki");
    RegConsoleCmd("sc_bug",BugCommand,"Report Bugs");
    RegConsoleCmd("sm_bug",BugCommand,"Report Bugs");

    RegConsoleCmd("+ultimate",UltimateCommand,"use SourceCraft ultimate (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate",UltimateCommand,"use SourceCraft ultimate (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate1",UltimateCommand,"use SourceCraft ultimate/ability 1 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate1",UltimateCommand,"use SourceCraft ultimate/ability 1 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate2",UltimateCommand,"use SourceCraft ultimate/ability 2 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate2",UltimateCommand,"use SourceCraft ultimate/ability 2 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate3",UltimateCommand,"use SourceCraft ultimate/ability 3 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate3",UltimateCommand,"use SourceCraft ultimate/ability 3 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate4",UltimateCommand,"use SourceCraft ultimate/ability 4 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate4",UltimateCommand,"use SourceCraft ultimate/ability 4 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate5",UltimateCommand,"use SourceCraft ultimate/ability 5 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate5",UltimateCommand,"use SourceCraft ultimate/ability 5 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate6",UltimateCommand,"use SourceCraft ultimate/ability 6 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate6",UltimateCommand,"use SourceCraft ultimate/ability 6 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate7",UltimateCommand,"use SourceCraft ultimate/ability 7 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate7",UltimateCommand,"use SourceCraft ultimate/ability 7 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate8",UltimateCommand,"use SourceCraft ultimate/ability 8 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate8",UltimateCommand,"use SourceCraft ultimate/ability 8 (keyup)",FCVAR_GAMEDLL);

    RegConsoleCmd("+ultimate9",UltimateCommand,"use SourceCraft ultimate/ability 9 (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate9",UltimateCommand,"use SourceCraft ultimate/ability 9 (keyup)",FCVAR_GAMEDLL);
}

public Action:SayCommand(client, const String:command[], argc)
{
    TraceInto("Hooks", "SayCommand", "client=%d:%L, argc=%d, command=%s", \
              client, ValidClientIndex(client), argc, command);

    if (IsValidClient(client))
    {
        decl String:text[128];
        GetCmdArg(1,text,sizeof(text));

        decl String:arg[2][64];
        new argCount = ExplodeString(text, " ", arg, 2, 64);

        new String:firstChar[] = " ";
        firstChar[0] = arg[0][0];
        if (StrContains("!/\\",firstChar) >= 0)
            strcopy(arg[0], sizeof(arg[]), arg[0][1]);

        if (StrEqual(arg[0],"menu", false) ||
            StrEqual(arg[0],"scmenu", false) ||
            StrEqual(arg[0],"wcsmenu", false))
        {
            MainMenu(client);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"shopmenu", false) ||
                 StrEqual(arg[0],"shop", false) ||
                 StrEqual(arg[0],"scbuy", false) ||
                 StrEqual(arg[0],"buy", false))
        {
            if (argCount > 1 && strlen(arg[1]) > 0)
            {
                new item = FindShopItem(arg[1]);
                if (item >= 0)
                    PurchaseShopItem(client, item);
                else
                    ShopMenu(client,client,PurchaseItemMode);
            }
            else
                ShopMenu(client,client,PurchaseItemMode);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"changeunit", false) ||
                 StrEqual(arg[0],"changerace", false))
        {
            if (argCount > 1 && strlen(arg[1]) > 0)
            {
                new race = FindRace(arg[1]);
                if (race >= 0)
                {
                    new Handle:raceHandle=GetRaceHandle(race);
                    if (raceHandle != INVALID_HANDLE)
                        ChangeRace(client, race, raceHandle, false, true, false);
                    else
                        RaceMenu(client,ChangeRaceMode);
                }
                else
                    RaceMenu(client,ChangeRaceMode);
            }
            else
                RaceMenu(client,ChangeRaceMode);

            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"unitinfo", false) ||
                 StrEqual(arg[0],"raceinfo", false))
        {
            RaceMenu(client,InfoMode);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"reset", false) ||
                 StrEqual(arg[0],"resetupgrades", false) ||
                 StrEqual(arg[0],"resetskills", false))
        {
            ResetUpgrades(client);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"upgrade", false) ||
                 StrEqual(arg[0],"spendup", false) ||
                 StrEqual(arg[0],"spendupgrades", false) ||
                 StrEqual(arg[0],"spendskills", false))
        {
            new race=GetRace(client);
            if (GetUpgradeLevelCount(client, race) < GetLevel(client, race))
                UpgradeMenu(client, UpgradeMode, true);
            else
            {
                CPrintToChat(client,"{green}[SC]{default} %t", "NoPoints");
            }
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"schelp", false) ||
                 StrEqual(arg[0],"help", false))
        {
            Help(client);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"scsettings", false) ||
                 StrEqual(arg[0],"settings", false))
        {
            ChangeSettings(client, false);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"ds", false) ||
                 StrEqual(arg[0],"scds", false) ||
                 StrEqual(arg[0],"displaysettings", false))
        {
            ChangeDisplaySettings(client, false);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"gs", false) ||
                 StrEqual(arg[0],"scgs", false) ||
                 StrEqual(arg[0],"gamesettings", false))
        {
            ChangeGameSettings(client, false);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"info", false) ||
                 StrEqual(arg[0],"show", false))
        {
            PlayerInfo(client,client,InfoMode|QueryMode);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"playerinfo", false) ||
                 StrEqual(arg[0],"showplayer", false))
        {
            PlayerInfoMenu(client,InfoMode);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"showup") ||
                 StrEqual(arg[0],"upinfo") ||
                 StrEqual(arg[0],"showupgrades") ||
                 StrEqual(arg[0],"upgradeinfo") ||
                 StrEqual(arg[0],"showskills") ||
                 StrEqual(arg[0],"skillsinfo"))
        {
            UpgradesInfo(client,client,GetRace(client),InfoMode);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"showitems", false) ||
                 StrEqual(arg[0],"inventory", false) ||
                 StrEqual(arg[0],"inv", false))
        {
            ShopMenu(client,client,InfoMode);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"xp", false) ||
                 StrEqual(arg[0],"showxp", false) ||
                 StrEqual(arg[0],"showexp", false) ||
                 StrEqual(arg[0],"showexperience", false))
        {
            ShowXP(client,Display_Generic);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"crystals", false) || 
                 StrEqual(arg[0],"showcrystals", false) ||
                 StrEqual(arg[0],"showc", false))
        {
            ShowCrystals(client,Display_Generic);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"vespene", false) || 
                 StrEqual(arg[0],"showvespene", false) ||
                 StrEqual(arg[0],"showv", false))
        {
            ShowVespene(client,Display_Generic);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"energy", false) || 
                 StrEqual(arg[0],"showenergy", false) ||
                 StrEqual(arg[0],"showe", false))
        {
            ShowEnergy(client,Display_Generic);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"scinfo", false) || 
                 StrEqual(arg[0],"details", false) || 
                 StrEqual(arg[0],"lookup", false))
        {
            ShowInfo(client);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"scwiki", false) || 
                 StrEqual(arg[0],"wiki", false))
        {
            ShowWiki(client);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"scinfo", false) || 
                 StrEqual(arg[0],"updates", false))
        {
            ShowUpdates(client);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"scbug", false) || 
                 StrEqual(arg[0],"bug", false))
        {
            ReportBugs(client);
            return Plugin_Handled;
        }
        else if (StrEqual(arg[0],"killme", false))
        {
            KillPlayer(client, client, "sc_suicide", "Suicide");
        }
        else if (StrEqual(arg[0],"entities", false))
        {
            new max = GetMaxEntities();
            new count = GetEntityCount();
            new remaining = max - count;

            LogMessage("There are %d of %d entities available, %d are used.",
                       remaining,max,count);

            DisplayMessage(client, Display_Generic,
                           "There are {green}%d of %d{default} entities available, %c%d%c are used.",
                           remaining,max,count);
        }
    }
    else
    {
        TraceCat("Connect", "Command issued from Invalid client=%d", client);
    }

    TraceReturn();
    return Plugin_Continue;
}

public Action:UltimateCommand(client,args)
{
    TraceInto("Hooks", "UltimateCommand");

    if (IsValidClientAlive(client))
    {
        if (GameType == tf2)
        {
            if (TF2_IsPlayerTaunting(client) ||
                TF2_IsPlayerDazed(client))
            {
                PrepareSound(deniedWav);
                EmitSoundToClient(client,deniedWav);
                TraceReturn();
                return Plugin_Handled;
            }
            //case TFClass_Scout:
            else if (TF2_IsPlayerBonked(client))
            {
                PrepareSound(deniedWav);
                EmitSoundToClient(client,deniedWav);
                TraceReturn();
                return Plugin_Handled;
            }
            //case TFClass_Spy:
            else if (TF2_IsPlayerCloaked(client) ||
                     TF2_IsPlayerDeadRingered(client))
            {
                PrepareSound(deniedWav);
                EmitSoundToClient(client,deniedWav);
                TraceReturn();
                return Plugin_Handled;
            }
        }

        new result;
        new race=GetRace(client);

        decl String:command[CLASS_STRING_LENGTH];
        GetCmdArg(0,command,sizeof(command));
        new bool:pressed=(command[0] == '+');

        new arg;
        if (IsCharNumeric(command[9]))
        {
            arg = command[9]-'0';

            Trace("%N issuing %s: +ultimate%d, pressed=%d, args=%d, CmdArgs=%d", \
                  client, command, arg, pressed, args, GetCmdArgs());
        }
        else if (args > 1) // (GetCmdArgs() > 1)
        {
            decl String:argString[16];
            GetCmdArg(1,argString,sizeof(argString));
            arg = StringToInt(argString);

            Trace("%N issuing %s: +ultimate %s(%d), pressed=%d, args=%d, CmdArgs=%d", \
                  client, command, argString, arg, pressed, args, GetCmdArgs());
        }
        else
        {
            arg = 1;

            Trace("%N issuing %s: +ultimate, pressed=%d, args=%d, CmdArgs=%d", \
                  client, command, pressed, args, GetCmdArgs());
        }

        Call_StartForward(g_OnUltimateCommandHandle);
        Call_PushCell(client);
        Call_PushCell(race);
        Call_PushCell(pressed);
        Call_PushCell(arg);
        Call_Finish(result);

        Trace("%N completed +ultimate %s, pressed=%d", client, arg, pressed);
    }

    TraceReturn();
    return Plugin_Handled;
}

public Action:SCMenuCommand(client,args)
{
    MainMenu(client);
    return Plugin_Handled;
}

public Action:BuyCommand(client,args)
{
    if (IsValidClient(client))
    {
        decl String:arg[64];
        if (GetCmdArg(1,arg,sizeof(arg)) > 0)
        {
            new item = FindShopItem(arg);
            if (item >= 0)
                PurchaseShopItem(client, item);
            else
                ShopMenu(client,client,PurchaseItemMode);
        }
        else
            ShopMenu(client,client,PurchaseItemMode);
    }
    return Plugin_Handled;
}

public Action:ChangeRaceCommand(client,args)
{
    if (IsValidClient(client))
    {
        decl String:arg[64];
        if (GetCmdArg(1,arg,sizeof(arg)) > 0)
        {
            new race = FindRace(arg);
            if (race >= 0)
            {
                new Handle:raceHandle=GetRaceHandle(race);
                if (raceHandle != INVALID_HANDLE)
                    ChangeRace(client, race, raceHandle, false, true, false);
                else
                    RaceMenu(client,ChangeRaceMode);
            }
            else
                RaceMenu(client,ChangeRaceMode);
        }
        else
            RaceMenu(client,ChangeRaceMode);
    }
    return Plugin_Handled;
}

public Action:ChangeSettingsCommand(client,args)
{
    ChangeSettings(client, false);
    return Plugin_Handled;
}

public Action:ChangeDisplaySettingsCommand(client,args)
{
    ChangeDisplaySettings(client, false);
    return Plugin_Handled;
}

public Action:ChangeGameSettingsCommand(client,args)
{
    ChangeGameSettings(client, false);
    return Plugin_Handled;
}

public Action:InfoCommand(client,args)
{
    ShowInfo(client);
    return Plugin_Handled;
}

ShowInfo(client)
{
    decl String:url[128];
    decl String:steamid[CLASS_STRING_LENGTH];
    if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
        Format(url, sizeof(url), g_InfoURL, steamid);
    else
        strcopy(url, sizeof(url), g_InfoBaseURL);

    ShowMOTDPanel(client, "SourceCraft Information", url, MOTDPANEL_TYPE_URL);
}

public Action:WikiCommand(client,args)
{
    ShowWiki(client);
    return Plugin_Handled;
}

ShowWiki(client)
{
    ShowMOTDPanel(client, "SourceCraft Wiki", g_WikiURL, MOTDPANEL_TYPE_URL);
}

public Action:UpdatesCommand(client,args)
{
    ShowUpdates(client);
    return Plugin_Handled;
}

ShowUpdates(client)
{
    ShowMOTDPanel(client, "SourceCraft Updates", g_UpdateURL, MOTDPANEL_TYPE_URL);
}

public Action:BugCommand(client,args)
{
    ReportBugs(client);
    return Plugin_Handled;
}

ReportBugs(client)
{
    ShowMOTDPanel(client, "SourceCraft Bugs", g_BugURL, MOTDPANEL_TYPE_URL);
}

public Action:ChangelevelCommand(client, const String:command[], argc)
{
    g_MapChanging = true;
    return Plugin_Continue;
}

