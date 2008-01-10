/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: menus.inc
 * Description: This file handles the menu aspects of the plugin.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

new bool:shopMenuMode[MAXPLAYERS+1];

new Handle:hAdminMenu = INVALID_HANDLE;

public War3Source_InitMenus()
{
    /* Account for late loading */
    new Handle:topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
    {
        OnAdminMenuReady(topmenu);
    }

    return true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
 
public OnAdminMenuReady(Handle:topmenu)
{
    /************************************************************/
    /* Add Administer War3Source option to SourceMod Admin Menu */
    /************************************************************/

    /* Block us from being called twice */
    if (topmenu != hAdminMenu)
    {
        /* Save the Handle */
        hAdminMenu = topmenu;
        new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
        AddToTopMenu(hAdminMenu, "war3admin", TopMenuObject_Item, War3Source_AdminMenu, server_commands, "war3admin", ADMFLAG_WAR3);
    }
}

public War3Source_AdminMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Administer War3Source");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        War3Source_Admin(param,param);
    }
}

public War3Source_IntroMenu(client)
{
    new Handle:introMenu=CreateMenu(War3Source_IntroMenu_Action);
    SetMenuExitButton(introMenu,false);
    SetMenuTitle(introMenu,"Welcome to this War3Source server!\nYou get XP points for completing objectives.\nEach level gained, you may choose a skill to\nlevel up. For a command list, type war3help in\nchat.\n%s",VERSION);
    AddMenuItem(introMenu,"","Exit");
    DisplayMenu(introMenu,client, 20);
}

public War3Source_IntroMenu_Action(Handle:menu,MenuAction:action,client,param)
{
    if (action == MenuAction_Select ||
        (action == MenuAction_Cancel && param == MenuCancel_Timeout))
    {
        if (m_FirstSpawn[client] > 1)
        {
            War3Source_RaceMenu(client, true);
        }
        m_FirstSpawn[client]=0;
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_War3Menu(client,vecpos)
{
    new Handle:war3Menu=CreateMenu(War3Source_War3Menu_Select);
    SetMenuExitButton(war3Menu,true);
    SetMenuTitle(war3Menu,"[War3Source] Choose a task.");
    decl String:buf[4];
    Format(buf,sizeof(buf),"%d",vecpos);
    AddMenuItem(war3Menu,buf,"View War3Source command list");
    AddMenuItem(war3Menu,buf,"Change your race");
    AddMenuItem(war3Menu,buf,"View your race's skills information");
    AddMenuItem(war3Menu,buf,"Reset your skills");
    AddMenuItem(war3Menu,buf,"Spend unused skill points");
    AddMenuItem(war3Menu,buf,"Show current skill levels");
    AddMenuItem(war3Menu,buf,"Show current items owned");
    AddMenuItem(war3Menu,buf,"Bring up the shopmenu");
    DisplayMenu(war3Menu,client,MENU_TIME_FOREVER);
}

public War3Source_War3Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new war3player=StringToInt(SelectionInfo);
        if(war3player>-1)
        {
            switch(selection)
            {
                case 0: // war3help
                {
                    War3Source_War3Help(client);
                }
                case 1: // changerace
                {
                    War3Source_RaceMenu(client, true);
                }
                case 2: // skillsinfo
                {
                    War3Source_SkillsInfo(client,war3player);
                }
                case 3: // resetskills
                {
                    War3Source_ResetSkills(client,war3player);
                }
                case 4: // spendskills
                {
                    new race=GetRace(war3player);
                    if(GetSkillCount(war3player,race)<GetLevel(war3player,race))
                        War3Source_SkillMenu(client,war3player);
                    else
                    {
                        PrintToChat(client, "%c[War3Source] %cYou don't have any skill points to spend, if you want to reset your skills use resetskills.", COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                case 5: // showskills
                {
                    War3Source_ShowSkills(client,war3player);
                }
                case 6: // showitems
                {
                    War3Source_ShopMenu(client,war3player, false);
                }
                case 7: // shopmenu
                {
                    War3Source_ShopMenu(client,war3player, true);
                }
            }
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_RaceMenu(client, bool:change)
{
    new Handle:crMenu;
    
    if (change)
    {
        crMenu=CreateMenu(War3Source_CRMenu_Selected);
        SetMenuTitle(crMenu, "[War3Source] Select your desired race.\n");
    }
    else
    {
        crMenu=CreateMenu(War3Source_RIMenu_Selected);
        SetMenuTitle(crMenu, "[War3Source] Select a race to view.");
    }

    SetMenuExitButton(crMenu,true);
    // Iteriate through the races and print them out
    new Handle:race;
    decl String:rbuf[4];
    decl String:rname[64];
    decl String:rlevel[4];
    decl String:ritem[96];
    for(new x=0;x<RACE_COUNT;x++)
    {
        race=Race(x);
        Format(rbuf,sizeof(rbuf),"%d",x);
        GetArrayString(race,RACE_NAME,rname,sizeof(rname));
        GetArrayString(race,RACE_REQUIRED_LEVEL,rlevel,sizeof(rlevel));
        new reqLevel = StringToInt(rlevel);
        if (reqLevel)
        {
            new level = GetOverallLevel(GetClientVectorPosition(client));
            new style = (change && level < reqLevel) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
            Format(ritem,sizeof(ritem),"%s (overall level must be >= %d)",rname, reqLevel);
            AddMenuItem(crMenu,rbuf,ritem,style);
        }
        else
            AddMenuItem(crMenu,rbuf,rname);
    }
    DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
}

public War3Source_CRMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new vecpos=GetClientVectorPosition(client);
        if(vecpos >- 1)
        {
            if(selection >= 0&&selection<RACE_COUNT)
            {
                // Okay, they selected a valid race
                if(IsPlayerAlive(client))
                {
                    SetPendingRace(vecpos,selection);
                    new Handle:race=Race(selection);
                    decl String:buf[192];
                    GetArrayString(race,3,buf,sizeof(buf));
                    PrintToChat(client,"%c[War3Source] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
                }
                else
                {
                    SetPendingRace(vecpos,-1);
                    SetRace(vecpos,selection);
                    new Handle:race=Race(selection);
                    decl String:buf[192];
                    GetArrayString(race,2,buf,sizeof(buf));
                    PrintToChat(client, "%c[War3Source] %c%s", COLOR_GREEN,COLOR_DEFAULT,buf);
                }
            }
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_RIMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new vecpos=GetClientVectorPosition(client);
        if(vecpos > -1)
        {
            if(selection >= 0 && selection < RACE_COUNT)
            {
                // Okay, they selected a valid race
                new Handle:raceHandle=Race(selection);
                War3Source_ShowSkillsInfo(client, raceHandle);
            }
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_SkillMenu(client,vectorpos)
{
    new Handle:sMenu=CreateMenu(War3Source_SMenu_Selected);
    new race_num=GetRace(vectorpos);
    new skillcount=GetSkillCount(vectorpos,race_num);
    new level=GetLevel(vectorpos,race_num);
    SetMenuExitButton(sMenu,true);
    SetMenuTitle(sMenu,"[War3Source] Select your desired skill. (%d/%d)",skillcount,level);
    decl String:skillname[64];
    new curlevel;
    new Handle:race=Race(race_num);
    decl String:sbuf[4];
    decl String:buf[192];
    for(new x=0;x<SKILL_COUNT;x++)
    {
        GetArrayString(race,4+(x*2),skillname,sizeof(skillname));
        Format(sbuf,sizeof(sbuf),"%d",x);
        curlevel=GetSkillLevel(vectorpos,race_num,x);
        if(x!=SKILL_ULTIMATE)
            Format(buf,191,"%s (Skill Level %d)",skillname,curlevel+1);
        else
        {
            Format(buf,191,"Ultimate: %s (Skill Level %d) (Minimum Level %d)",
                   skillname,curlevel+1,MIN_ULTIMATE_LEVEL);
        }
        if(curlevel!=4)
            AddMenuItem(sMenu,sbuf,buf);
    }
    DisplayMenu(sMenu,client,MENU_TIME_FOREVER);
}

public War3Source_SMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new vecpos=GetClientVectorPosition(client);
        if(vecpos>-1)
        {
            if(selection>=0&&selection<SKILL_COUNT)
            {
                // Okay, they selected a valid skill
                decl String:SelectionInfo[4];
                decl String:SelectionDispText[256];
                new SelectionStyle;
                GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                            SelectionDispText,sizeof(SelectionDispText));
                new skill=StringToInt(SelectionInfo);
                if(skill>-1&&skill<SKILL_COUNT)
                {
                    if(skill==SKILL_ULTIMATE)
                    {
                        new race=GetRace(vecpos);
                        new Handle:raceHandle=Race(race);
                        new level=GetLevel(vecpos,race);
                        if(level>=MIN_ULTIMATE_LEVEL)
                        {
                            if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                            {
                                SetSkillLevel(vecpos,race,skill,GetSkillLevel(vecpos,race,skill)+1);
                                decl String:skillname[64];
                                GetArrayString(raceHandle,4+(skill*2),skillname,sizeof(skillname));
                                PrintToChat(client, "%c[War3Source] %c\"%s\" is now level %d.",
                                            COLOR_GREEN,COLOR_DEFAULT,skillname,
                                            GetSkillLevel(vecpos,race,skill));
                            }
                            else
                            {
                                PrintToChat(client, "%c[War3Source] %cYou can not choose a skill without gaining another level.",
                                            COLOR_GREEN,COLOR_DEFAULT);
                            }
                        }
                        else
                        {
                            PrintToChat(client, "%c[War3Source] %cYou need to be at least level %d to choose an ultimate.",
                                        COLOR_GREEN,COLOR_DEFAULT,MIN_ULTIMATE_LEVEL);
                        }
                        if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                            War3Source_SkillMenu(client,vecpos);
                    }
                    else
                    {
                        new race=GetRace(vecpos);
                        new Handle:raceHandle=Race(race);
                        if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                        {
                            SetSkillLevel(vecpos,race,skill,GetSkillLevel(vecpos,race,skill)+1);
                            decl String:skillname[64];
                            GetArrayString(raceHandle,4+(skill*2),skillname,sizeof(skillname));
                            PrintToChat(client, "%c[War3Source] %c\"%s\" is now level %d.",
                                        COLOR_GREEN,COLOR_DEFAULT,skillname,
                                        GetSkillLevel(vecpos,race,skill));
                        }
                        else
                        {
                            PrintToChat(client, "%c[War3Source] %cYou can not choose a skill without gaining another level.",
                                        COLOR_GREEN,COLOR_DEFAULT);
                        }

                        if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                            War3Source_SkillMenu(client,vecpos);
                    }
                }
            }
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_ShopMenu(client,vectorpos,bool:shopmenu)
{
    new credits=GetCredits(vectorpos);
    decl String:currencies[64];
    GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
    new Handle:shopMenu=CreateMenu(War3Source_ShopMenu_Selected);
    SetMenuExitButton(shopMenu,true);

    if (shopmenu)
        SetMenuTitle(shopMenu,"[War3Source] Select an item to look at. - You have %d %s",credits,currencies);
    else
        SetMenuTitle(shopMenu,"[War3Source] Here is a list of the items you currently have. - You have %d %s",credits,currencies);

    decl String:itemname[64];
    decl String:itembuf[4];
    decl String:linestr[96];
    decl String:cost[8];
    new Handle:itemHandle;
    for(new x=0;x<SHOPITEM_COUNT;x++)
    {
        if (shopmenu || GetOwnsItem(vectorpos,x))
        {
            Format(itembuf,sizeof(itembuf),"%d",x);
            itemHandle=ShopItem(x);
            GetArrayString(itemHandle,0,itemname,sizeof(itemname));
            GetArrayString(itemHandle,2,cost,7);
            Format(linestr,95,"%s - %s %s",itemname,cost,currencies);
            AddMenuItem(shopMenu,itembuf,linestr);
        }
    }
    shopMenuMode[client] = shopmenu;
    DisplayMenu(shopMenu,client,MENU_TIME_FOREVER);
}

public War3Source_ShopMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new vecpos=GetClientVectorPosition(client);
        if(vecpos>-1)
        {
            decl String:SelectionInfo[4];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                        SelectionDispText,sizeof(SelectionDispText));
            new item=StringToInt(SelectionInfo);
            if(item>-1 && item<SHOPITEM_COUNT)
                War3Source_ShopMenu_Item(client,vecpos,item);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_ShopMenu_Item(client,vecpos,item)
{
    new credits=GetCredits(vecpos);
    decl String:currencies[64];
    GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
    new Handle:shopMenu_Item=CreateMenu(War3Source_ShopMenu_Item_Select);
    SetMenuExitButton(shopMenu_Item,true);
    decl String:itemname[64];
    new Handle:itemHandle;
    itemHandle=ShopItem(item);
    GetArrayString(itemHandle,0,itemname,sizeof(itemname));
    decl String:desc[300];
    GetArrayString(itemHandle,1,desc,sizeof(desc));
    Format(desc,sizeof(desc),"Description: %s",desc);
    decl String:cost[32];
    GetArrayString(itemHandle,2,cost,31);
    Format(cost,31,"Cost: %s %s",cost, currencies);
    SetMenuTitle(shopMenu_Item,"[War3Source] Shop Item - %s - You have %d %s\n%s\n%s",
                 itemname,credits,currencies,desc,cost);
    decl String:buf[4];
    Format(buf,3,"%d",item);

    if (shopMenuMode[client])
        AddMenuItem(shopMenu_Item,buf,"Purchase");

    AddMenuItem(shopMenu_Item,buf,"Back to items");
    DisplayMenu(shopMenu_Item,client,MENU_TIME_FOREVER);
}

public War3Source_ShopMenu_Item_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new vecpos=GetClientVectorPosition(client);
        if(vecpos>-1)
        {
            decl String:SelectionInfo[4];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
            new item=StringToInt(SelectionInfo);
            if(selection==0)
            {
                // Purchase
                new credits=GetCredits(vecpos);
                decl String:cost[4];
                new Handle:itemHandle=ShopItem(item);

                decl String:itemname[64];
                GetArrayString(itemHandle,0,itemname,sizeof(itemname));

                GetArrayString(itemHandle,2,cost,3);
                new cost_num=StringToInt(cost);
                if(credits>=cost_num)
                {
                    if(!GetOwnsItem(vecpos,item))
                    {
                        new newcredits=credits-cost_num;
                        SetCredits(vecpos,newcredits);
                        SetOwnsItem(vecpos,item,1);
                        Call_StartForward(g_OnItemPurchaseHandle);
                        Call_PushCell(client);
                        Call_PushCell(vecpos);
                        Call_PushCell(item);
                        new result;
                        Call_Finish(result);

                        PrintToChat(client, "%c[War3Source] %cYou have successfully purchased the %s.",
                                    COLOR_GREEN,COLOR_DEFAULT,itemname);
                    }
                    else
                    {
                        PrintToChat(client, "%c[War3Source] %cYou already own the %s.",
                                    COLOR_GREEN,COLOR_DEFAULT, itemname);
                    }
                }
                else
                {
                    PrintToChat(client, "%c[War3Source] %cYou can not afford the %s.",
                                COLOR_GREEN,COLOR_DEFAULT,itemname);
                }
            }
            else if(selection==1)
                War3Source_ShopMenu(client,vecpos,shopMenuMode[client]);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:War3Source_Admin(client,args)
{
    new Handle:adminMenu=CreateMenu(War3Source_Admin_Selected);
    SetMenuExitButton(adminMenu,true);
    SetMenuTitle(adminMenu,"[War3Source] Select a player to administrate.");
    decl String:playername[64];
    decl String:war3playerbuf[4];
    new Handle:playerHandle;
    for(new x=0;x<GetArraySize(arrayPlayers);x++)
    {
        playerHandle=GetArrayCell(arrayPlayers,x);
        Format(war3playerbuf,sizeof(war3playerbuf),"%d",GetArrayCell(playerHandle,0));
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        AddMenuItem(adminMenu,war3playerbuf,playername);
    }
    DisplayMenu(adminMenu,client,MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public War3Source_Admin_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                    SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new war3player=GetClientVectorPosition(index);
        if(war3player>-1)
            War3Source_Admin_Player(client,war3player);
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player you selected has left the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_Player(client,targetvecpos)
{
    new Handle:adminMenu_Player=CreateMenu(War3Source_Admin_Player_Select);
    SetMenuExitButton(adminMenu_Player,true);
    decl String:playername[64];
    new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
    GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
    SetMenuTitle(adminMenu_Player,"[War3Source] Administration options for %s.",playername);
    decl String:buf[4];
    Format(buf,3,"%d",GetArrayCell(playerHandle,0));
    decl String:currencies[64];
    GetConVarString(m_Currencies, currencies, sizeof(currencies));
    decl String:changeCredits[128];
    Format(changeCredits,sizeof(changeCredits),"Increase/Decrease %s", currencies);
    AddMenuItem(adminMenu_Player,buf,"View detailed information");
    AddMenuItem(adminMenu_Player,buf,"Reset skills");
    AddMenuItem(adminMenu_Player,buf,"Set race");
    AddMenuItem(adminMenu_Player,buf,"Give shop item");
    AddMenuItem(adminMenu_Player,buf,"Increase/Decrease XP");
    AddMenuItem(adminMenu_Player,buf,"Increase/Decrease Level");
    AddMenuItem(adminMenu_Player,buf,changeCredits);
    DisplayMenu(adminMenu_Player,client,MENU_TIME_FOREVER);
}

public War3Source_Admin_Player_Select(Handle:menu,MenuAction:action,client,selection)
{
    // This is gonna be fun... NOT.
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new war3player=GetClientVectorPosition(index);
        new String:adminname[64];
        GetClientName(client,adminname,sizeof(adminname));
        if(war3player>-1)
        {
            new String:targetname[64];
            GetClientName(index,targetname,sizeof(targetname));
            // What do they want to do with the player?
            switch(selection)
            {
                case 0:
                {
                    // Player info selected
                    War3Source_Admin_PlayerInfo(client,index);
                }
                case 1:
                {
                    // Reset skills
                    new race=GetRace(war3player);
                    for(new y=0;y<SKILL_COUNT;y++)
                            SetSkillLevel(war3player,race,y,0);

                    if(GetSkillCount(war3player,race)<GetLevel(war3player,race))
                        War3Source_SkillMenu(index,war3player);

                    PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" reset your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);

                    PrintToChat(client, "%c[War3Source] %cYou reset player \"%s\" skills.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);
                }
                case 2:
                {
                    // Set race
                    War3Source_Admin_SetRace(client,index);
                }
                case 3:
                {
                    // Give shop item
                    War3Source_Admin_GiveShopItem(client,index);
                }
                case 4:
                {
                    // Increase/Decrease XP
                    War3Source_Admin_XP(client,index);
                }
                case 5:
                {
                    // Increase/Decrease Level
                    War3Source_Admin_Level(client,index);
                }
                case 6:
                {
                    // Increase/Decrease Credits
                    War3Source_Admin_Credits(client,index);
                }
            }
            if(selection==1)
                War3Source_Admin_Player(client,war3player);
        }
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player you selected has left the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_PlayerInfo(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        decl String:currency[64];
        GetConVarString(m_Currencies, currency, sizeof(currency));
        new Handle:playerInfo=CreateMenu(War3Source_Admin_PI_Select);
        SetMenuExitButton(playerInfo,true);
        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        new race=GetRace(targetvecpos);
        new Handle:rhand=Race(race);
        decl String:race_name[64];
        GetArrayString(rhand,0,race_name,sizeof(race_name));
        new credits=GetCredits(targetvecpos);
        new xp=GetXP(targetvecpos,race);
        new level=GetLevel(targetvecpos,race);

        SetMenuTitle(playerInfo,"[War3Source] Info for %s.\nRace: %s\n%s: %d\nXP: %d\nLevel: %d",
                     playername,race_name,currency,credits,xp,level);

        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        AddMenuItem(playerInfo,buf,"Back to options");
        DisplayMenu(playerInfo,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public War3Source_Admin_PI_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new war3player=GetClientVectorPosition(index);
        if(war3player>-1)
            War3Source_Admin_Player(client,war3player);
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_XP(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(War3Source_Admin_XP_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[War3Source] Select an option for %s.",playername);
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        AddMenuItem(menu,buf,"Give 100 XP");
        AddMenuItem(menu,buf,"Give 1000 XP");
        AddMenuItem(menu,buf,"Give 10000 XP");
        AddMenuItem(menu,buf,"Remove 100 XP");
        AddMenuItem(menu,buf,"Remove 1000 XP");
        AddMenuItem(menu,buf,"Remove 10000 XP");
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
        PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
}

public War3Source_Admin_XP_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new targetvecpos=GetClientVectorPosition(index);
        if(targetvecpos>-1)
        {
            new race=GetRace(targetvecpos);
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(index,targetname,sizeof(targetname));
            if(selection<3) // Give XP
            {
                new xpadd;
                switch(selection)
                {
                    case 0:
                        xpadd=100;
                    case 1:
                        xpadd=1000;
                    case 2:
                        xpadd=10000;
                }
                new newxp=GetXP(targetvecpos,race)+xpadd;
                SetXP(targetvecpos,race,newxp);

                PrintToChat(client, "%c[War3Source] %cYou gave \"%s\" %d XP.",
                            COLOR_GREEN,COLOR_DEFAULT,targetname,xpadd);

                PrintToChat(index, "%c[War3Source] %cYou recieved %d XP from admin \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,xpadd,adminname);

                DoLevelCheck(index,targetvecpos);
                War3Source_Admin_XP(client,index);
            }
            else
            {
                new xprem;
                switch(selection)
                {
                    case 3:
                        xprem=100;
                    case 4:
                        xprem=1000;
                    case 5:
                        xprem=10000;
                }
                new newxp=GetXP(targetvecpos,race)-xprem;
                if(newxp<0)
                    newxp=0;

                SetXP(targetvecpos,race,newxp);

                PrintToChat(client, "%c[War3Source] %cYou removed %d XP from player \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,xprem,targetname);

                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" removed %d XP from you.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,xprem);

                War3Source_Admin_XP(client,index);
            }
        }
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_GiveShopItem(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(War3Source_Admin_GSI_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[War3Source] Select an item to give to %s.",playername);
        decl String:itemname[64];
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        new Handle:itemHandle;
        for(new x=0;x<SHOPITEM_COUNT;x++)
        {
            itemHandle=ShopItem(x);
            GetArrayString(itemHandle,0,itemname,sizeof(itemname));
            AddMenuItem(menu,buf,itemname);
        }
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public War3Source_Admin_GSI_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new targetvecpos=GetClientVectorPosition(index);
        if(targetvecpos>-1)
        {
            new item=selection;
            if(!GetOwnsItem(targetvecpos,item))
            {
                SetOwnsItem(targetvecpos,item,1);
                Call_StartForward(g_OnItemPurchaseHandle);
                Call_PushCell(index);
                Call_PushCell(targetvecpos);
                Call_PushCell(item);
                new result;
                Call_Finish(result);
                new Handle:itemHandle=ShopItem(item);
                decl String:itemname[64];
                GetArrayString(itemHandle,0,itemname,sizeof(itemname));
                decl String:adminname[64];
                GetClientName(client,adminname,sizeof(adminname));
                decl String:targetname[64];
                GetClientName(index,targetname,sizeof(targetname));

                PrintToChat(client, "%c[War3Source] %cYou gave \"%s\" a %s.",
                            COLOR_GREEN,COLOR_DEFAULT,targetname,itemname);

                PrintToChat(index, "%c[War3Source] %cYou recieved a %s from admin \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,itemname,adminname);

                War3Source_Admin_Player(client,targetvecpos);
            }
            else
            {
                PrintToChat(client, "%c[War3Source] %cThe player already owns this item.",
                            COLOR_GREEN,COLOR_DEFAULT);
            }
        }
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_SetRace(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(War3Source_Admin_SetRace_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[War3Source] Select a race for %s.",playername);
        decl String:racename[64];
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        new Handle:raceHandle;
        for(new x=0;x<RACE_COUNT;x++)
        {
            raceHandle=Race(x);
            GetArrayString(raceHandle,0,racename,sizeof(racename));
            AddMenuItem(menu,buf,racename);
        }
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public War3Source_Admin_SetRace_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new targetvecpos=GetClientVectorPosition(index);
        if(targetvecpos>-1)
        {
            SetRace(targetvecpos,selection);
            new Handle:racehandle=Race(selection);
            decl String:racename[64];
            GetArrayString(racehandle,0,racename,sizeof(racename));
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(index,targetname,sizeof(targetname));

            PrintToChat(client, "%c[War3Source] %cYou set player \"%s\" to race %s.",
                        COLOR_GREEN,COLOR_DEFAULT,targetname,racename);

            PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" set you to race %s.",
                        COLOR_GREEN,COLOR_DEFAULT,adminname,racename);
        }
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_Level(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(War3Source_Admin_Level_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[War3Source] Select an option for %s.",playername);
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        AddMenuItem(menu,buf,"Give a level");
        AddMenuItem(menu,buf,"Remove a level");
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public War3Source_Admin_Level_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new targetvecpos=GetClientVectorPosition(index);
        if(targetvecpos>-1)
        {
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(index,targetname,sizeof(targetname));
            new race=GetRace(targetvecpos);
            if(selection==0)
            {
                // Give a level
                new newlevel=GetLevel(targetvecpos,race)+1;
                if(newlevel>MAX_LEVELS)
                {
                    PrintToChat(client, "%c[War3Source] %cPlayer \"%s\" is already at the max level.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);
                }
                else
                {
                    SetLevel(targetvecpos,race,newlevel);
                    War3Source_SkillMenu(index,targetvecpos);

                    PrintToChat(client, "%c[War3Source] %cYou gave player \"%s\" a level.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);

                    PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" gave you a level.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);
                }
            }
            else
            {
                // Remove a level
                new newlevel=GetLevel(targetvecpos,race)-1;
                if (newlevel<0)
                {
                    PrintToChat(client, "%c[War3Source] %cPlayer \"%s\" is already level 0.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);
                }
                else
                {
                    SetLevel(targetvecpos,race,newlevel);
                    for(new x=0;x<SKILL_COUNT;x++)
                        SetSkillLevel(targetvecpos,race,x,0);

                    PrintToChat(client, "%c[War3Source] %cYou removed a level from player \"%s\".",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);

                    PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" removed a level from you, re-pick your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);

                    if(newlevel>0)
                        War3Source_SkillMenu(index,targetvecpos);
                }
            }
            War3Source_Admin_Level(client,index);
        }
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_Credits(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(War3Source_Admin_Credits_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[War3Source] Select an option for %s.",playername);

        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);

        decl String:display[64];
        decl String:currency[64];
        decl String:currencies[64];
        GetConVarString(m_Currency, currency, sizeof(currency));
        GetConVarString(m_Currencies, currencies, sizeof(currencies));

        Format(display,sizeof(display),"Give 1 %s", currency);
        AddMenuItem(menu,buf,display);

        Format(display,sizeof(display),"Give 5 %s", currencies);
        AddMenuItem(menu,buf,display);

        Format(display,sizeof(display),"Give 10 %s", currencies);
        AddMenuItem(menu,buf,display);

        Format(display,sizeof(display),"Remove 1 %s", currency);
        AddMenuItem(menu,buf,display);

        Format(display,sizeof(display),"Remove 5 %s", currencies);
        AddMenuItem(menu,buf,display);

        Format(display,sizeof(display),"Remove 10 %s", currencies);
        AddMenuItem(menu,buf,display);

        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public War3Source_Admin_Credits_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new targetvecpos=GetClientVectorPosition(index);
        if(targetvecpos>-1)
        {
            decl String:currency[64];
            GetConVarString(m_Currency, currency, sizeof(currency));
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(index,targetname,sizeof(targetname));
            if(selection<3) // Give credits
            {
                new credadd;
                switch(selection)
                {
                    case 0:
                        credadd=1;
                    case 1:
                        credadd=5;
                    case 2:
                        credadd=10;
                }
                new newcred=GetCredits(targetvecpos)+credadd;
                if(newcred>MAX_CREDITS)
                    newcred=MAX_CREDITS;
                SetCredits(targetvecpos,newcred);

                PrintToChat(client, "%c[War3Source] %cYou gave \"%s\" %d %s(s).",
                            COLOR_GREEN,COLOR_DEFAULT,targetname,credadd,currency);

                PrintToChat(index, "%c[War3Source] %cYou recieved %d %s(s) from admin \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,credadd,currency,adminname);

                War3Source_Admin_Credits(client,index);
            }
            else
            {
                new credrem;
                switch(selection)
                {
                    case 3:
                        credrem=1;
                    case 4:
                        credrem=5;
                    case 5:
                        credrem=10;
                }
                new newcred=GetCredits(targetvecpos)-credrem;
                if(newcred<0)
                    newcred=0;
                SetCredits(targetvecpos,newcred);

                PrintToChat(client, "%c[War3Source] %cYou removed %d %s(s) from player \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,credrem,currency,targetname);

                PrintToChat(index, "%c[War3Source] %cAdmin \"%s\" removed %d %s(s) from you.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,credrem,currency);

                War3Source_Admin_Credits(client,index);
            }
        }
        else
        {
            PrintToChat(client, "%c[War3Source] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
