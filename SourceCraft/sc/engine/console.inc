/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: console.inc
 * Description: This file handles console variables that can be modified from the server console
 *              or RCON, and it also handles the admin commands that can be called from either
 *              server or client admin.  
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

//#define ADMFLAG_SOURCECRAFT ADMFLAG_RCON
#define ADMFLAG_SOURCECRAFT ADMFLAG_CUSTOM1

public InitCVars()
{
    CreateConVar("sc_version",VERSION,"SourceCraft version.",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_UNLOGGED|FCVAR_DONTRECORD);

    m_SaveXPConVar=CreateConVar("sc_savexp","1");
    m_MinimumUltimateLevel=CreateConVar("sc_minimumultimatelevel","8");
    m_MaxCredits=CreateConVar("sc_maxcredits","100");
    m_Currency=CreateConVar("sc_currency","crystal", "Name of the currency");
    m_Currencies=CreateConVar("sc_currencies","crystals", "Name of the currency in plural form");

    RegAdminCmd("sc_setxp",CMD_SetXP,ADMFLAG_SOURCECRAFT,"Set a player's XP");
    RegAdminCmd("sc_givexp",CMD_GiveXP,ADMFLAG_SOURCECRAFT,"Give a player XP");
    RegAdminCmd("sc_removexp",CMD_RemoveXP,ADMFLAG_SOURCECRAFT,"Remove some XP from a player");
    RegAdminCmd("sc_setlevel",CMD_SetLevel,ADMFLAG_SOURCECRAFT,"Set a player's level");
    RegAdminCmd("sc_givelevel",CMD_GiveLevel,ADMFLAG_SOURCECRAFT,"Give a player a single level");
    RegAdminCmd("sc_removelevel",CMD_RemoveLevel,ADMFLAG_SOURCECRAFT,"Remove a single level from a player");
    RegAdminCmd("sc_setcredits",CMD_SetCredits,ADMFLAG_SOURCECRAFT,"Set a player's credit count");
    RegAdminCmd("sc_givecredits",CMD_GiveCredits,ADMFLAG_SOURCECRAFT,"Give a player credits");
    RegAdminCmd("sc_removecredits",CMD_RemoveCredits,ADMFLAG_SOURCECRAFT,"Remove some credits from a player");

    RegAdminCmd("sc_admin",AdminMenu,ADMFLAG_SOURCECRAFT,"Brings up the SourceCraft admin panel.");

    return true;
}

public PlayerParse(const String:matchstr[], &Handle:matchHandle)
{
    if(StrEqual(matchstr,"@all",false))
    {
        // All?
        new playerCount = GetArraySize(arrayPlayers);
        for(new x=0;x<playerCount;x++)
        {
            PushArrayCell(matchHandle,GetClientIndex(x));
        }
    }
    else
    {
        // Team?
        if(StrEqual(matchstr,"@ct",false) ||
           StrEqual(matchstr,"@red",false) ||
	       StrEqual(matchstr,"@axis",false))
        {
            new playerCount = GetArraySize(arrayPlayers);
            for(new x=0;x<playerCount;x++)
            {
                new index=GetClientIndex(x);
                if(GetClientTeam(index)==3)
                    PushArrayCell(matchHandle,index);
            }
        }
        else if (StrEqual(matchstr,"@t",false) ||
                 StrEqual(matchstr,"@blue",false) ||
                 StrEqual(matchstr,"@allies",false))
        {
            new playerCount = GetArraySize(arrayPlayers);
            for(new x=0;x<playerCount;x++)
            {
                new index=GetClientIndex(x);
                if(GetClientTeam(index)==2)
                    PushArrayCell(matchHandle,index);
            }
        }
        else
        {
            // Userid?
            if(matchstr[0]=='@')
            {
                new uid=StringToInt(matchstr[1]);
                new playerCount = GetArraySize(arrayPlayers);
                for(new x=0;x<playerCount;x++)
                {
                    new index=GetClientIndex(x);
                    if(GetClientUserId(index)==uid)
                        PushArrayCell(matchHandle,index);
                }
            }
            else
            {
                // Player name?
                new playerCount = GetArraySize(arrayPlayers);
                for(new x=0;x<playerCount;x++)
                {
                    new index=GetClientIndex(x);
                    new String:name[64];
                    GetClientName(index,name,63);
                    if(StrContains(name,matchstr,false)!=-1)
                        PushArrayCell(matchHandle,index);
                }
            }
        }
    }
}

public Action:CMD_SetXP(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: Setxp <player> <xp>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        decl String:buf[32];
        GetCmdArg(2,buf,31);
        new xp=StringToInt(buf);
        if(xp<0)
            xp=0;
        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            new index=GetArrayCell(matchHandle,x);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                SetXP(vecpos,race,xp);
                PrintToConsole(client,"[SourceCraft] You just set \"%N's\" XP to %d.",index,xp);
                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%N\" set your XP to %d.",
                            COLOR_GREEN,COLOR_DEFAULT,client,xp);
                DoLevelCheck(index,vecpos);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_GiveXP(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: sc_givexp <player> <xp>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        decl String:buf[32];
        GetCmdArg(2,buf,31);
        new xp=StringToInt(buf);
        if(xp<0)
            xp=0;
        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            new index=GetArrayCell(matchHandle,x);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                SetXP(vecpos,race,GetXP(vecpos,race)+xp);
                PrintToConsole(client,"[SourceCraft] You just gave %d XP to \"%N\".",xp,index);
                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%N\" gave you %d XP.",
                            COLOR_GREEN,COLOR_DEFAULT,client,xp);
                DoLevelCheck(index,vecpos);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_RemoveXP(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: sc_removexp <player> <xp>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        decl String:buf[32];
        GetCmdArg(2,buf,31);
        new xp=StringToInt(buf);
        if(xp<0)
            xp=0;
        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            new index=GetArrayCell(matchHandle,x);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                new newxp=GetXP(vecpos,race)-xp;
                if(newxp<0)
                    newxp=0;
                SetXP(vecpos,race,newxp);
                PrintToConsole(client,"[SourceCraft] You just removed %d XP from \"%N\".",xp,index);
                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%N\" removed %d XP from you.",
                            COLOR_GREEN,COLOR_DEFAULT,client,xp);
                DoLevelCheck(index,vecpos);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_SetLevel(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: Setlevel <player> <level>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        decl String:buf[32];
        GetCmdArg(2,buf,31);
        new String:adminname[64];
        if(client!=0)
            GetClientName(client,adminname,63);
        else
            adminname="Console";
        new level=StringToInt(buf);
        if(level<0)
            level=0;
        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                for(new y=0;y<SKILL_COUNT;y++)
                    SetSkillLevel(vecpos,race,y,0);
                if(level>SKILL_COUNT*4)
                    level=SKILL_COUNT*4;
                if(level<0)
                    level=0;
                SetLevel(vecpos,race,level);
                PrintToConsole(client,"[SourceCraft] You just set player \"%s's\" level to %d.",name,level);
                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" set your level to %d, re-pick your skills.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,level);
                if(level>0)
                    SkillMenu(index, vecpos, INVALID_FUNCTION);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_GiveLevel(client,args)
{
    if(args!=1)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: sc_givelevel <player>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        new String:adminname[64];
        if(client!=0)
            GetClientName(client,adminname,63);
        else
            adminname="Console";
        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                new newlevel=GetLevel(vecpos,race)+1;
                if(newlevel>MAX_LEVELS)
                    PrintToConsole(client,"[SourceCraft] Player \"%s\" is already at their max level.",name);
                else
                {
                    SetLevel(vecpos,race,newlevel);
                    SetOverallLevel(vecpos, GetOverallLevel(vecpos)+1);
                    PrintToConsole(client,"[SourceCraft] You just gave player \"%s\" a level.",name);
                    PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" gave you a level.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);
                    SkillMenu(index, vecpos, INVALID_FUNCTION);
                }
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_RemoveLevel(client,args)
{
    if(args!=1)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: sc_removelevel <player>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        new String:adminname[64];
        if(client!=0)
            GetClientName(client,adminname,63);
        else
            adminname="Console";
        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                new newlevel=GetLevel(vecpos,race)-1;
                if(newlevel<0)
                    PrintToConsole(client,"[SourceCraft] Player \"%s\" is already at level 0.",name);
                else
                {
                    for(new y=0;y<SKILL_COUNT;y++)
                        SetSkillLevel(vecpos,race,y,0);
                    SetLevel(vecpos,race,newlevel);
                    SetOverallLevel(vecpos, GetOverallLevel(vecpos)-1);
                    PrintToConsole(client,"[SourceCraft] You just removed a level from player \"%s\".",name);
                    PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" removed a level from you, re-pick your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);
                    if(newlevel>0)
                        SkillMenu(index, vecpos, INVALID_FUNCTION);
                }
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_SetCredits(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: Setcredits <player> <amount>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        decl String:buf[32];
        GetCmdArg(2,buf,31);
        new String:adminname[64];
        if(client!=0)
            GetClientName(client,adminname,63);
        else
            adminname="Console";
        new credits=StringToInt(buf);
        if(credits<0)
            credits=0;
        new maxCredits = GetConVarInt(m_MaxCredits);
        if(credits>maxCredits)
            credits=maxCredits;
            
        decl String:currencies[64];
        GetConVarString(m_Currencies, currencies, 63);

        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                SetCredits(vecpos,credits);
                PrintToConsole(client,"[SourceCraft] You just set player \"%s's\" %s to %d.",name,currencies,credits);
                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" set your %s to %d.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,currencies,credits);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_GiveCredits(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: sc_givecredits <player> <amount>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        decl String:buf[32];
        GetCmdArg(2,buf,31);
        new String:adminname[64];
        if(client!=0)
            GetClientName(client,adminname,63);
        else
            adminname="Console";
        new credits=StringToInt(buf);
        if(credits<0)
            credits=0;
            
        decl String:currencies[64];
        GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, 63);

        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new newcreds=GetCredits(vecpos)+credits;
                if(newcreds<0)
                    newcreds=0;
                new maxCredits = GetConVarInt(m_MaxCredits);
                if(newcreds>maxCredits)
                    newcreds=maxCredits;
                SetCredits(vecpos,newcreds);
                PrintToConsole(client,"[SourceCraft] You just gave player \"%s\" %d %s.",name,credits,currencies);
                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" give you %d %s.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,credits,currencies);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:CMD_RemoveCredits(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[SourceCraft] The syntax of the command is: sc_givecredits <player> <amount>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,63);
        decl String:buf[32];
        GetCmdArg(2,buf,31);
        new String:adminname[64];
        if(client!=0)
            GetClientName(client,adminname,63);
        else
            adminname="Console";
        new credits=StringToInt(buf);
        if(credits<0)
            credits=0;
            
        decl String:currencies[64];
        GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, 63);

        new Handle:matchHandle=CreateArray();
        PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new newcreds=GetCredits(vecpos)-credits;
                if(newcreds<0)
                    newcreds=0;
                new maxCredits = GetConVarInt(m_MaxCredits);
                if(newcreds>maxCredits)
                    newcreds=maxCredits;
                SetCredits(vecpos,newcreds);
                PrintToConsole(client,"[SourceCraft] You just removed %d %s from player \"%s\".",credits,currencies,name);
                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" removed %d %s from you.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,credits,currencies);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[SourceCraft] No players matched your query.");
    }
    return Plugin_Handled;
}
