/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: hooks.inc
 * Description: Handles hooking functions, will be used to get chat commands.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */
 
public bool:InitHooks()
{
    RegConsoleCmd("say",SayCommand);
    RegConsoleCmd("say_team",SayCommand);
    RegConsoleCmd("+ultimate",UltimateCommand,"use SourceCraft ultimate ability (keydown)",FCVAR_GAMEDLL);
    RegConsoleCmd("-ultimate",UltimateCommand,"use SourceCraft ultimate ability (keyup)",FCVAR_GAMEDLL);
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

public Action:SayCommand(client,args)
{
    decl String:arg1[32];
    GetCmdArg(1,arg1,sizeof(arg1));
    new vecpos=GetClientVectorPosition(client);
    if(vecpos>-1)
    {
        decl String:currencies[64];
        GetConVarString(m_Currencies, currencies, sizeof(currencies));
        decl String:showCurrency[64];
        Format(showCurrency,sizeof(showCurrency),"show%s",currencies);

        if(CommandCheck(arg1,"showxp",63))
        {
            ShowXP(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"changerace",63))
        {
            RaceMenu(client,true,INVALID_FUNCTION);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"raceinfo",63))
        {
            RaceMenu(client,false,INVALID_FUNCTION);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"skillsinfo",63))
        {
            SkillsInfo(client,GetRace(vecpos),false,INVALID_FUNCTION);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"resetskills",63))
        {
            ResetSkills(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"spendskills",63))
        {
            new race=GetRace(vecpos);
            if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                SkillMenu(client,vecpos,INVALID_FUNCTION);
            else
            {
                PrintToChat(client,"%c[SourceCraft] %cYou don't have any skill points to spend, if you want to reset your skills use resetskills.",COLOR_GREEN,COLOR_DEFAULT);
            }
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"showskills",63))
        {
            ShowSkills(client,client,vecpos,INVALID_FUNCTION);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"showcredits",63)|| CommandCheck(arg1,showCurrency,63))
        {
            ShowCredits(client,vecpos);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"shopmenu",63))
        {
            ShopMenu(client,vecpos,true,INVALID_FUNCTION);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"showitems",63) || CommandCheck(arg1,"inventory",63) ||
                CommandCheck(arg1,"inven",63) || CommandCheck(arg1,"inv",63))
        {
            ShopMenu(client,vecpos,false,INVALID_FUNCTION);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"schelp",63) || CommandCheck(arg1,"help",63))
        {
            Help(client,INVALID_FUNCTION);
            return Plugin_Handled;
        }
        else if(CommandCheck(arg1,"scmenu",63) || CommandCheck(arg1,"menu",63))
        {
            MainMenu(client,vecpos,INVALID_FUNCTION);
            return Plugin_Handled;
        }
	}
    return Plugin_Continue;
}
 
public Action:UltimateCommand(client,args)
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