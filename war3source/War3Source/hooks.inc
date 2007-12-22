/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: hooks.inc
 * Description: Handles hooking functions, will be used to get chat commands.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */
 
public bool:War3Source_InitHooks()
{
    RegConsoleCmd("say",War3Source_SayCommand);
    RegConsoleCmd("say_team",War3Source_SayCommand);
    RegConsoleCmd("+ultimate",War3Source_UltimateCommand);
    RegConsoleCmd("-ultimate",War3Source_UltimateCommand);
    return true;
}

public bool:CommandCheck(const String:compare[], const String:command[], maxlen)
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

public Action:War3Source_SayCommand(client,args)
{
    decl String:arg1[32];
    GetCmdArg(1,arg1,32);
    new vecpos=GetClientVectorPosition(client);
    if(vecpos>-1)
    {
        decl String:currencies[64];
        GetConVarString(m_Currencies, currencies, 63);
        decl String:showCurrency[64];
        Format(showCurrency,63,"show%s",currencies);

        if(CommandCheck(arg1,"showxp",63))
        {
            ShowXP(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"changerace",63))
        {
            War3Source_RaceMenu(client, true);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"raceinfo",63))
        {
            War3Source_RaceMenu(client, false);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"skillsinfo",63))
        {
            War3Source_SkillsInfo(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"resetskills",63))
        {
            War3Source_ResetSkills(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"spendskills",63))
        {
            new race=GetRace(vecpos);
            if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                War3Source_SkillMenu(client,vecpos);
            else
            {
                PrintToChat(client,"%c[War3Source] %cYou don't have any skill points to spend, if you want to reset your skills use resetskills.",COLOR_GREEN,COLOR_DEFAULT);
            }
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"showskills",63))
        {
            War3Source_ShowSkills(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"showcredits",63)|| CommandCheck(arg1,showCurrency,63))
        {
            War3Source_ShowCredits(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"shopmenu",63))
        {
            War3Source_ShopMenu(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"war3help",63) || CommandCheck(arg1,"wc3help",63) ||
	       	    CommandCheck(arg1,"wchelp",63)   || CommandCheck(arg1,"help",63))
        {
            War3Source_War3Help(client);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"war3menu",63) || CommandCheck(arg1,"wc3menu",63) ||
	       	    CommandCheck(arg1,"wcmenu",63))
        {
            War3Source_War3Menu(client,vecpos);
            return Plugin_Handled;
        }
	}
    return Plugin_Continue;
}
 
public Action:War3Source_UltimateCommand(client,args)
{
    decl String:command[32];
    GetCmdArg(0,command,32);
    new vecpos=GetClientVectorPosition(client);
    if(vecpos>-1)
    {
        new race=GetRace(vecpos);
        new bool:pressed=false;
        if(!strcmp(command,"+ultimate"))
            pressed=true;

        Call_StartForward(g_OnUltimateCommandHandle);
        Call_PushCell(client);
        Call_PushCell(vecpos);
        Call_PushCell(race);
        Call_PushCell(pressed);
        new result;
        Call_Finish(result);
    }
    return Plugin_Handled;
}
