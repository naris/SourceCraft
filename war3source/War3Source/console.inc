/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: console.inc
 * Description: This file handles console variables that can be modified from the server console
 *              or RCON, and it also handles the admin commands that can be called from either
 *              server or client admin.  
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hTopMenu = INVALID_HANDLE;

public War3Source_InitCVars()
{
    CreateConVar("war3_version",VERSION,"War3Source version.",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);

    m_SaveXPConVar=CreateConVar("war3_savexp","1");
    m_MinimumUltimateLevel=CreateConVar("war3_minimumultimatelevel","8");
    m_MaxCredits=CreateConVar("war3_maxcredits","40");
    m_Currency=CreateConVar("war3_currency","credit", "Name of the currency");
    m_Currencies=CreateConVar("war3_currencies","credits", "Name of the currency in plural form");

    RegAdminCmd("war3_setxp",War3Source_CMD_SetXP,ADMFLAG_RCON,"Set a player's XP");
    RegAdminCmd("war3_givexp",War3Source_CMD_GiveXP,ADMFLAG_RCON,"Give a player XP");
    RegAdminCmd("war3_removexp",War3Source_CMD_RemoveXP,ADMFLAG_RCON,"Remove some XP from a player");
    RegAdminCmd("war3_setlevel",War3Source_CMD_SetLevel,ADMFLAG_RCON,"Set a player's level");
    RegAdminCmd("war3_givelevel",War3Source_CMD_GiveLevel,ADMFLAG_RCON,"Give a player a single level");
    RegAdminCmd("war3_removelevel",War3Source_CMD_RemoveLevel,ADMFLAG_RCON,"Remove a single level from a player");
    RegAdminCmd("war3_setcredits",War3Source_CMD_SetCredits,ADMFLAG_RCON,"Set a player's credit count");
    RegAdminCmd("war3_givecredits",War3Source_CMD_GiveCredits,ADMFLAG_RCON,"Give a player credits");
    RegAdminCmd("war3_removecredits",War3Source_CMD_RemoveCredits,ADMFLAG_RCON,"Remove some credits from a player");

    RegAdminCmd("wcadmin",War3Source_Admin,ADMFLAG_RCON,"Brings up the War3Source admin panel.");
    RegAdminCmd("wc3admin",War3Source_Admin,ADMFLAG_RCON,"Brings up the War3Source admin panel.");
    RegAdminCmd("war3admin",War3Source_Admin,ADMFLAG_RCON,"Brings up the War3Source admin panel.");

    return true;
}

public War3Source_PlayerParse(const String:matchstr[], &Handle:matchHandle)
{
    if(StrEqual(matchstr,"@all",false))
    {
        // All?
        for(new x=0;x<GetArraySize(arrayPlayers);x++)
        {
            new Handle:playerhandle=GetArrayCell(arrayPlayers,x);
            PushArrayCell(matchHandle,GetArrayCell(playerhandle,0));
        }
    }
    else
    {
        // Team?
        if(StrEqual(matchstr,"@ct",false) ||
           StrEqual(matchstr,"@red",false) ||
	       StrEqual(matchstr,"@axis",false))
        {
            for(new x=0;x<GetArraySize(arrayPlayers);x++)
            {
                new Handle:playerhandle=GetArrayCell(arrayPlayers,x);
                new index=GetArrayCell(playerhandle,0);
                if(GetClientTeam(index)==3)
                    PushArrayCell(matchHandle,index);
            }
        }
        else if (StrEqual(matchstr,"@t",false) ||
                 StrEqual(matchstr,"@blue",false) ||
                 StrEqual(matchstr,"@allies",false))
        {
            for(new x=0;x<GetArraySize(arrayPlayers);x++)
            {
                new Handle:playerhandle=GetArrayCell(arrayPlayers,x);
                new index=GetArrayCell(playerhandle,0);
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
                for(new x=0;x<GetArraySize(arrayPlayers);x++)
                {
                    new Handle:playerhandle=GetArrayCell(arrayPlayers,x);
                    new index=GetArrayCell(playerhandle,0);
                    if(GetClientUserId(index)==uid)
                        PushArrayCell(matchHandle,index);
                }
            }
            else
            {
                // Player name?
                for(new x=0;x<GetArraySize(arrayPlayers);x++)
                {
                    new Handle:playerhandle=GetArrayCell(arrayPlayers,x);
                    new index=GetArrayCell(playerhandle,0);
                    new String:name[64];
                    GetClientName(index,name,63);
                    if(StrContains(name,matchstr,false)!=-1)
                        PushArrayCell(matchHandle,index);
                }
            }
        }
    }
}

public Action:War3Source_CMD_SetXP(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_setxp <player> <xp>");
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
        new xp=StringToInt(buf);
        if(xp<0)
            xp=0;
        new Handle:matchHandle=CreateArray();
        War3Source_PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                SetXP(vecpos,race,xp);
                PrintToConsole(client,"[War3Source] You just set \"%s's\" XP to %d.",name,xp);
                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" set your XP to %d.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,xp);
                DoLevelCheck(index,vecpos);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_GiveXP(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_givexp <player> <xp>");
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
        new xp=StringToInt(buf);
        if(xp<0)
            xp=0;
        new Handle:matchHandle=CreateArray();
        War3Source_PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                SetXP(vecpos,race,GetXP(vecpos,race)+xp);
                PrintToConsole(client,"[War3Source] You just gave %d XP to \"%s\".",xp,name);
                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" gave you %d XP.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,xp);
                DoLevelCheck(index,vecpos);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_RemoveXP(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_removexp <player> <xp>");
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
        new xp=StringToInt(buf);
        if(xp<0)
            xp=0;
        new Handle:matchHandle=CreateArray();
        War3Source_PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                new race=GetRace(vecpos);
                new newxp=GetXP(vecpos,race)-xp;
                if(newxp<0)
                    newxp=0;
                SetXP(vecpos,race,newxp);
                PrintToConsole(client,"[War3Source] You just removed %d XP from \"%s\".",xp,name);
                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" removed %d XP from you.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,xp);
                DoLevelCheck(index,vecpos);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_SetLevel(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_setlevel <player> <level>");
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
        War3Source_PlayerParse(match,matchHandle);
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
                PrintToConsole(client,"[War3Source] You just set player \"%s's\" level to %d.",name,level);
                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" set your level to %d, re-pick your skills.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,level);
                if(level>0)
                    War3Source_SkillMenu(index,vecpos);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_GiveLevel(client,args)
{
    if(args!=1)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_givelevel <player>");
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
        War3Source_PlayerParse(match,matchHandle);
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
                    PrintToConsole(client,"[War3Source] Player \"%s\" is already at their max level.",name);
                else
                {
                    SetLevel(vecpos,race,newlevel);
                    PrintToConsole(client,"[War3Source] You just gave player \"%s\" a level.",name);
                    PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" gave you a level.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);
                    War3Source_SkillMenu(index,vecpos);
                }
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_RemoveLevel(client,args)
{
    if(args!=1)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_removelevel <player>");
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
        War3Source_PlayerParse(match,matchHandle);
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
                    PrintToConsole(client,"[War3Source] Player \"%s\" is already at level 0.",name);
                else
                {
                    for(new y=0;y<SKILL_COUNT;y++)
                        SetSkillLevel(vecpos,race,y,0);
                    SetLevel(vecpos,race,newlevel);
                    PrintToConsole(client,"[War3Source] You just removed a level from player \"%s\".",name);
                    PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" removed a level from you, re-pick your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);
                    if(newlevel>0)
                        War3Source_SkillMenu(index,vecpos);
                }
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_SetCredits(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_setcredits <player> <amount>");
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
        if(credits>MAX_CREDITS)
            credits=MAX_CREDITS;
            
        decl String:currencies[64];
        GetConVarString(m_Currencies, currencies, 63);

        new Handle:matchHandle=CreateArray();
        War3Source_PlayerParse(match,matchHandle);
        for(new x=0;x<GetArraySize(matchHandle);x++)
        {
            decl String:name[64];
            new index=GetArrayCell(matchHandle,x);
            GetClientName(index,name,63);
            new vecpos=GetClientVectorPosition(index);
            if(vecpos>-1)
            {
                SetCredits(vecpos,credits);
                PrintToConsole(client,"[War3Source] You just set player \"%s's\" %s to %d.",name,currencies,credits);
                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" set your %s to %d.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,currencies,credits);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_GiveCredits(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_givecredits <player> <amount>");
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
        War3Source_PlayerParse(match,matchHandle);
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
                if(newcreds>MAX_CREDITS)
                    newcreds=MAX_CREDITS;
                SetCredits(vecpos,newcreds);
                PrintToConsole(client,"[War3Source] You just gave player \"%s\" %d %s.",name,credits,currencies);
                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" give you %d %s.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,credits,currencies);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}

public Action:War3Source_CMD_RemoveCredits(client,args)
{
    if(args!=2)
        PrintToConsole(client,"[War3Source] The syntax of the command is: war3_givecredits <player> <amount>");
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
        War3Source_PlayerParse(match,matchHandle);
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
                if(newcreds>MAX_CREDITS)
                    newcreds=MAX_CREDITS;
                SetCredits(vecpos,newcreds);
                PrintToConsole(client,"[War3Source] You just removed %d %s from player \"%s\".",credits,currencies,name);
                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" removed %d %s from you.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,credits,currencies);
            }
        }
        if(GetArraySize(matchHandle)==0)
            PrintToConsole(client,"[War3Source] No players matched your query.");
    }
    return Plugin_Handled;
}
