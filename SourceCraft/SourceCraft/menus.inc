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

new Function:gRaceMenuParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new Function:gSkillMenuParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new Function:gShopMenuParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new bool:gShopMenuMode[MAXPLAYERS+1];
new bool:gRaceMenuMode[MAXPLAYERS+1];
new gShowItemsTarget[MAXPLAYERS+1];

new Handle:hAdminMenu = INVALID_HANDLE;

public InitMenus()
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
    /* Add Administer SourceCraft option to SourceMod Admin Menu */
    /************************************************************/

    /* Block us from being called twice */
    if (topmenu != hAdminMenu)
    {
        /* Save the Handle */
        hAdminMenu = topmenu;
        new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
        AddToTopMenu(hAdminMenu, "sc_admin", TopMenuObject_Item, AdminMenu, server_commands, "sc_admin", ADMFLAG_SOURCECRAFT);
    }
}

public AdminMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Administer SourceCraft");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        Admin(param,param);
    }
}

public IntroMenu(client)
{
    new Handle:introMenu=CreateMenu(IntroMenu_Action);
    SetMenuExitButton(introMenu,false);
    SetMenuTitle(introMenu,"Welcome to this SourceCraft server!\nYou get XP points for completing objectives.\nEach level gained, you may choose a skill to\nlevel up. For a command list, type help in\nchat.\n%s",VERSION);
    SetMenuExitButton(introMenu,true);
    AddMenuItem(introMenu,"","Exit");
    DisplayMenu(introMenu,client, 20);
}

public IntroMenu_Action(Handle:menu,MenuAction:action,client,param)
{
    if (action == MenuAction_Select ||
        (action == MenuAction_Cancel && param == MenuCancel_Timeout))
    {
        if (m_FirstSpawn[client] > 1)
            RaceMenu(client, true, INVALID_FUNCTION);
        else
            m_FirstSpawn[client]=0;
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public MainMenu(client,vecpos)
{
    new Handle:scMenu=CreateMenu(Menu_Select);
    SetMenuExitButton(scMenu,true);
    SetMenuTitle(scMenu,"[SourceCraft] Choose a task.");
    decl String:buf[4];
    Format(buf,sizeof(buf),"%d",vecpos);
    AddMenuItem(scMenu,buf,"View command list");
    AddMenuItem(scMenu,buf,"Change your race");
    AddMenuItem(scMenu,buf,"View your race's skills information");
    AddMenuItem(scMenu,buf,"Reset your skills");
    AddMenuItem(scMenu,buf,"Spend unused skill points");
    AddMenuItem(scMenu,buf,"Show current skill levels");
    AddMenuItem(scMenu,buf,"Show current items owned");
    AddMenuItem(scMenu,buf,"Bring up the shopmenu");
    DisplayMenu(scMenu,client,MENU_TIME_FOREVER);
}

public Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new player=StringToInt(SelectionInfo);
        if(player>-1)
        {
            switch(selection)
            {
                case 0: // help
                    Help(client,MainMenu);
                case 1: // changerace
                    RaceMenu(client,true,MainMenu);
                case 2: // skillsinfo
                    SkillsInfo(client,GetRace(player),false,MainMenu);
                case 3: // resetskills
                {
                    ResetSkills(client,player);
                    MainMenu(client,0);
                }
                case 4: // spendskills
                {
                    new race=GetRace(player);
                    if(GetSkillCount(player,race)<GetLevel(player,race))
                        SkillMenu(client, player, MainMenu);
                    else
                    {
                        PrintToChat(client, "%c[SourceCraft] %cYou don't have any skill points to spend, if you want to reset your skills use resetskills.", COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                case 5: // showskills
                    ShowSkills(client,client,player,MainMenu);
                case 6: // showitems
                    ShopMenu(client,player,false,MainMenu);
                case 7: // shopmenu
                    ShopMenu(client,player,true,MainMenu);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public RaceMenu(client,bool:change,Function:parentMenuFunction)
{
    new Handle:crMenu=CreateMenu(RaceMenu_Selected);
    
    if (change)
        SetMenuTitle(crMenu, "[SourceCraft] Select your desired race.\n");
    else
        SetMenuTitle(crMenu, "[SourceCraft] Select a race to view.");

    SetMenuExitButton(crMenu,true);
    SetMenuExitBackButton(crMenu,(parentMenuFunction != INVALID_FUNCTION));

    // Iterate through the races and print them out
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
    gRaceMenuMode[client]=change;
    gRaceMenuParentMenuFunction[client]=parentMenuFunction;
    DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
}

public CRMenu_Selected(Handle:menu,MenuAction:action,client,selection)
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
                if(IsPlayerAlive(client) && m_FirstSpawn[client] < 2)
                {
                    SetPendingRace(vecpos,selection);
                    new Handle:race=Race(selection);
                    decl String:buf[192];
                    GetArrayString(race,3,buf,sizeof(buf));
                    PrintToChat(client,"%c[SourceCraft] %c%s",COLOR_GREEN,COLOR_DEFAULT,buf);
                }
                else
                {
                    SetPendingRace(vecpos,-1);
                    SetRace(vecpos,selection);
                    new Handle:race=Race(selection);
                    decl String:buf[192];
                    GetArrayString(race,2,buf,sizeof(buf));
                    PrintToChat(client, "%c[SourceCraft] %c%s", COLOR_GREEN,COLOR_DEFAULT,buf);
                }
                m_FirstSpawn[client]=0;
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack &&
            gRaceMenuParentMenuFunction[client] != INVALID_FUNCTION)
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos >- 1)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gRaceMenuParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(vecpos);
                Call_Finish(result);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public RaceMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        SkillsInfo(client,selection,gRaceMenuMode[client],RaceMenu);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack &&
            gRaceMenuParentMenuFunction[client] != INVALID_FUNCTION)
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos >- 1)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gRaceMenuParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(vecpos);
                Call_Finish(result);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public SkillMenu(client, vectorpos, Function:parentMenuFunction)
{
    new Handle:sMenu=CreateMenu(SMenu_Selected);
    new race_num=GetRace(vectorpos);
    new skillcount=GetSkillCount(vectorpos,race_num);
    new level=GetLevel(vectorpos,race_num);
    SetMenuExitButton(sMenu,true);
    SetMenuExitBackButton(sMenu,(parentMenuFunction != INVALID_FUNCTION));
    SetMenuTitle(sMenu,"[SourceCraft] Select your desired skill. (%d/%d)",skillcount,level);
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
    gSkillMenuParentMenuFunction[client]=parentMenuFunction;
    DisplayMenu(sMenu,client,MENU_TIME_FOREVER);
}

public SMenu_Selected(Handle:menu,MenuAction:action,client,selection)
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
                                PrintToChat(client, "%c[SourceCraft] %c\"%s\" is now level %d.",
                                            COLOR_GREEN,COLOR_DEFAULT,skillname,
                                            GetSkillLevel(vecpos,race,skill));
                            }
                            else
                            {
                                PrintToChat(client, "%c[SourceCraft] %cYou can not choose a skill without gaining another level.",
                                            COLOR_GREEN,COLOR_DEFAULT);
                            }
                        }
                        else
                        {
                            PrintToChat(client, "%c[SourceCraft] %cYou need to be at least level %d to choose an ultimate.",
                                        COLOR_GREEN,COLOR_DEFAULT,MIN_ULTIMATE_LEVEL);
                        }
                        if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                            SkillMenu(client,vecpos,gSkillMenuParentMenuFunction[client]);
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
                            PrintToChat(client, "%c[SourceCraft] %c\"%s\" is now level %d.",
                                        COLOR_GREEN,COLOR_DEFAULT,skillname,
                                        GetSkillLevel(vecpos,race,skill));
                        }
                        else
                        {
                            PrintToChat(client, "%c[SourceCraft] %cYou can not choose a skill without gaining another level.",
                                        COLOR_GREEN,COLOR_DEFAULT);
                        }

                        if(GetSkillCount(vecpos,race)<GetLevel(vecpos,race))
                            SkillMenu(client,vecpos,gSkillMenuParentMenuFunction[client]);
                    }
                }
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack &&
            gSkillMenuParentMenuFunction[client] != INVALID_FUNCTION)
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos >- 1)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gSkillMenuParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(vecpos);
                Call_Finish(result);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public ShopMenu(client, vectorpos, bool:shopmenu, Function:parentMenuFunction)
{
    new credits=GetCredits(vectorpos);
    decl String:currencies[64];
    GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
    new Handle:shopMenu=CreateMenu(ShopMenu_Selected);
    SetMenuExitButton(shopMenu,true);
    SetMenuExitBackButton(shopMenu,(parentMenuFunction != INVALID_FUNCTION));

    if (shopmenu)
        SetMenuTitle(shopMenu,"[SourceCraft] Select an item to look at. - You have %d %s",credits,currencies);
    else
        SetMenuTitle(shopMenu,"[SourceCraft] Here is a list of the items you currently have. - You have %d %s",credits,currencies);

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
    gShopMenuMode[client] = shopmenu;
    gShopMenuParentMenuFunction[client]=parentMenuFunction;
    DisplayMenu(shopMenu,client,MENU_TIME_FOREVER);
}

public ShopMenu_Selected(Handle:menu,MenuAction:action,client,selection)
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
                ShopMenu_Item(client,vecpos,item);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack &&
            gShopMenuParentMenuFunction[client] != INVALID_FUNCTION)
        {
            new vecpos=GetClientVectorPosition(client);
            if(vecpos >- 1)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gShopMenuParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(vecpos);
                Call_Finish(result);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public ShopMenu_Item(client,vecpos,item)
{
    new credits=GetCredits(vecpos);
    decl String:currencies[64];
    GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
    new Handle:shopMenu_Item=CreateMenu(ShopMenu_Item_Select);
    SetMenuExitButton(shopMenu_Item,true);
    SetMenuExitBackButton(shopMenu_Item,true);
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
    SetMenuTitle(shopMenu_Item,"[SourceCraft] Shop Item - %s - You have %d %s\n%s\n%s",
                 itemname,credits,currencies,desc,cost);
    decl String:buf[4];
    Format(buf,3,"%d",item);

    if (gShopMenuMode[client])
        AddMenuItem(shopMenu_Item,buf,"Purchase");

    AddMenuItem(shopMenu_Item,buf,"Back to items");
    DisplayMenu(shopMenu_Item,client,MENU_TIME_FOREVER);
}

public ShopMenu_Item_Select(Handle:menu,MenuAction:action,client,selection)
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
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                        SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
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

                        PrintToChat(client, "%c[SourceCraft] %cYou have successfully purchased the %s.",
                                    COLOR_GREEN,COLOR_DEFAULT,itemname);
                    }
                    else
                    {
                        PrintToChat(client, "%c[SourceCraft] %cYou already own the %s.",
                                    COLOR_GREEN,COLOR_DEFAULT, itemname);
                    }
                }
                else
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou can not afford the %s.",
                                COLOR_GREEN,COLOR_DEFAULT,itemname);
                }
            }
            else if(selection==1)
            {
                ShopMenu(client,vecpos,gShopMenuMode[client],
                         gShopMenuParentMenuFunction[client]);
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");
            new vecpos=GetClientVectorPosition(client);
            if(vecpos>-1)
            {
                ShopMenu(client,vecpos,gShopMenuMode[client],
                         gShopMenuParentMenuFunction[client]);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public ShowItems(client,target,vectorpos,Function:parentMenuFunction)
{
    new Handle:panel=CreatePanel();

    if (client == target)
        SetPanelTitle(panel,"[SourceCraft] Here are your skill items.");
    else
    {
        decl String:buffer[256];
        Format(buffer,sizeof(buffer),"[SourceCraft] Here are %N's items.", target);
        SetPanelTitle(panel,buffer);
    }

    decl String:itemname[64];
    new Handle:itemHandle;
    DrawPanelText(panel,"-----------------------------");
    for(new x=0;x<SHOPITEM_COUNT;x++)
    {
        if (GetOwnsItem(vectorpos,x))
        {
            itemHandle=ShopItem(x);
            GetArrayString(itemHandle,0,itemname,sizeof(itemname));
            DrawPanelText(panel,itemname);
        }
    }
    DrawPanelText(panel,"-----------------------------");
    DrawPanelItem(panel,"Close");

    gShowItemsTarget[client]=target;
    gShopMenuParentMenuFunction[client]=parentMenuFunction;
    SendPanelToClient(panel,client,ShowItems_Selected,0);
    CloseHandle(panel);
}

public ShowItems_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (gShopMenuParentMenuFunction[client] != INVALID_FUNCTION)
    {
        decl result;
        ClientCommand(client,"play buttons/button14.wav");
        Call_StartFunction(INVALID_HANDLE, gShopMenuParentMenuFunction[client]);
        Call_PushCell(client);
        Call_PushCell(gShowItemsTarget[client]);
        Call_Finish(result);
    }
}

public Action:Admin(client,args)
{
    new Handle:adminMenu=CreateMenu(Admin_Selected);
    SetMenuExitButton(adminMenu,true);
    SetMenuTitle(adminMenu,"[SourceCraft] Select a player to administrate.");
    decl String:playername[64];
    decl String:playerbuf[4];
    new Handle:playerHandle;
    for(new x=0;x<GetArraySize(arrayPlayers);x++)
    {
        playerHandle=GetArrayCell(arrayPlayers,x);
        Format(playerbuf,sizeof(playerbuf),"%d",GetArrayCell(playerHandle,0));
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        AddMenuItem(adminMenu,playerbuf,playername);
    }
    DisplayMenu(adminMenu,client,MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public Admin_Selected(Handle:menu,MenuAction:action,client,selection)
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
        new player=GetClientVectorPosition(index);
        if(player>-1)
            Admin_Player(client,player);
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player you selected has left the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Admin_Player(client,targetvecpos)
{
    new Handle:adminMenu_Player=CreateMenu(Admin_Player_Select);
    SetMenuExitButton(adminMenu_Player,true);
    SetMenuExitBackButton(adminMenu_Player,true);
    decl String:playername[64];
    new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
    GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
    SetMenuTitle(adminMenu_Player,"[SourceCraft] Administration options for %s.",playername);
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

public Admin_Player_Select(Handle:menu,MenuAction:action,client,selection)
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
        new player=GetClientVectorPosition(index);
        new String:adminname[64];
        GetClientName(client,adminname,sizeof(adminname));
        if(player>-1)
        {
            new String:targetname[64];
            GetClientName(index,targetname,sizeof(targetname));
            // What do they want to do with the player?
            switch(selection)
            {
                case 0:
                {
                    // Player info selected
                    Admin_PlayerInfo(client,index);
                }
                case 1:
                {
                    // Reset skills
                    new race=GetRace(player);
                    for(new y=0;y<SKILL_COUNT;y++)
                            SetSkillLevel(player,race,y,0);

                    if(GetSkillCount(player,race)<GetLevel(player,race))
                        SkillMenu(index, player, Admin_Player);

                    PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" reset your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);

                    PrintToChat(client, "%c[SourceCraft] %cYou reset player \"%s\" skills.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);
                }
                case 2:
                {
                    // Set race
                    Admin_SetRace(client,index);
                }
                case 3:
                {
                    // Give shop item
                    Admin_GiveShopItem(client,index);
                }
                case 4:
                {
                    // Increase/Decrease XP
                    Admin_XP(client,index);
                }
                case 5:
                {
                    // Increase/Decrease Level
                    Admin_Level(client,index);
                }
                case 6:
                {
                    // Increase/Decrease Credits
                    Admin_Credits(client,index);
                }
            }
            if(selection==1)
                Admin_Player(client,player);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player you selected has left the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            Admin(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");
            Admin(client,0);
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Admin_PlayerInfo(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        decl String:currency[64];
        GetConVarString(m_Currencies, currency, sizeof(currency));

        new Handle:playerInfo=CreateMenu(Admin_PI_Select);
        SetMenuExitButton(playerInfo,true);
        SetMenuExitBackButton(playerInfo,true);

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

        SetMenuTitle(playerInfo,"[SourceCraft] Info for %s.\nRace: %s\n%s: %d\nXP: %d\nLevel: %d",
                     playername,race_name,currency,credits,xp,level);

        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        AddMenuItem(playerInfo,buf,"View Player's skill levels");
        AddMenuItem(playerInfo,buf,"View Player's shop items");
        AddMenuItem(playerInfo,buf,"Back to options");
        DisplayMenu(playerInfo,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        Admin(client,0);
    }
}

public Admin_PI_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,1,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new index=StringToInt(SelectionInfo);
        new targetvecpos=GetClientVectorPosition(index);
        if (targetvecpos>-1)
        {
            switch(selection)
            {
                case 0: // skill levels
                    ShowSkills(client,index,targetvecpos,Admin_PlayerInfo);
                case 1: // shop items
                    ShowItems(client,index,targetvecpos,Admin_PlayerInfo);
                default:
                    Admin_Player(client,targetvecpos);
            }
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            Admin(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

Admin_Return(Handle:menu,client)
{
    ClientCommand(client,"play buttons/button14.wav");
    decl String:SelectionInfo[4];
    decl String:SelectionDispText[256];
    new SelectionStyle;
    GetMenuItem(menu,1,SelectionInfo,sizeof(SelectionInfo),
                SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    new index=StringToInt(SelectionInfo);
    new targetvecpos=GetClientVectorPosition(index);
    if (targetvecpos>-1)
        Admin_Player(client,targetvecpos);
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        Admin(client,0);
    }
}

public Admin_XP(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(Admin_XP_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[SourceCraft] Select an option for %s.",playername);

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
    {
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        Admin(client,0);
    }
}

public Admin_XP_Select(Handle:menu,MenuAction:action,client,selection)
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

                PrintToChat(client, "%c[SourceCraft] %cYou gave \"%s\" %d XP.",
                            COLOR_GREEN,COLOR_DEFAULT,targetname,xpadd);

                PrintToChat(index, "%c[SourceCraft] %cYou recieved %d XP from admin \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,xpadd,adminname);

                DoLevelCheck(index,targetvecpos);
                Admin_XP(client,index);
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

                PrintToChat(client, "%c[SourceCraft] %cYou removed %d XP from player \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,xprem,targetname);

                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" removed %d XP from you.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,xprem);

                Admin_XP(client,index);
            }
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            Admin(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Admin_GiveShopItem(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(Admin_GSI_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[SourceCraft] Select an item to give to %s.",playername);

        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);

        decl String:itemname[64];
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
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public Admin_GSI_Select(Handle:menu,MenuAction:action,client,selection)
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

                PrintToChat(client, "%c[SourceCraft] %cYou gave \"%s\" a %s.",
                            COLOR_GREEN,COLOR_DEFAULT,targetname,itemname);

                PrintToChat(index, "%c[SourceCraft] %cYou recieved a %s from admin \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,itemname,adminname);

                Admin_Player(client,targetvecpos);
            }
            else
            {
                PrintToChat(client, "%c[SourceCraft] %cThe player already owns this item.",
                            COLOR_GREEN,COLOR_DEFAULT);
            }
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            Admin(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Admin_SetRace(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(Admin_SetRace_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[SourceCraft] Select a race for %s.",playername);

        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);

        decl String:racename[64];
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
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        Admin(client,0);
    }
}

public Admin_SetRace_Select(Handle:menu,MenuAction:action,client,selection)
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

            PrintToChat(client, "%c[SourceCraft] %cYou set player \"%s\" to race %s.",
                        COLOR_GREEN,COLOR_DEFAULT,targetname,racename);

            PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" set you to race %s.",
                        COLOR_GREEN,COLOR_DEFAULT,adminname,racename);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            Admin(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Admin_Level(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(Admin_Level_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[SourceCraft] Select an option for %s.",playername);

        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);

        AddMenuItem(menu,buf,"Give a level");
        AddMenuItem(menu,buf,"Remove a level");
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        Admin(client,0);
    }
}

public Admin_Level_Select(Handle:menu,MenuAction:action,client,selection)
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
                    PrintToChat(client, "%c[SourceCraft] %cPlayer \"%s\" is already at the max level.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);
                }
                else
                {
                    SetLevel(targetvecpos,race,newlevel);
                    SetOverallLevel(targetvecpos, GetOverallLevel(targetvecpos)+1);
                    SkillMenu(index, targetvecpos, Admin_Level);

                    PrintToChat(client, "%c[SourceCraft] %cYou gave player \"%s\" a level.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);

                    PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" gave you a level.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);
                }
            }
            else
            {
                // Remove a level
                new newlevel=GetLevel(targetvecpos,race)-1;
                if (newlevel<0)
                {
                    PrintToChat(client, "%c[SourceCraft] %cPlayer \"%s\" is already level 0.",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);
                }
                else
                {
                    SetLevel(targetvecpos,race,newlevel);
                    SetOverallLevel(targetvecpos, GetOverallLevel(targetvecpos)-1);
                    for(new x=0;x<SKILL_COUNT;x++)
                        SetSkillLevel(targetvecpos,race,x,0);

                    PrintToChat(client, "%c[SourceCraft] %cYou removed a level from player \"%s\".",
                                COLOR_GREEN,COLOR_DEFAULT,targetname);

                    PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" removed a level from you, re-pick your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,adminname);

                    if(newlevel>0)
                        SkillMenu(index, targetvecpos, Admin_Level);
                }
            }
            Admin_Level(client,index);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            Admin(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Admin_Credits(client,target)
{
    new targetvecpos=GetClientVectorPosition(target);
    if(targetvecpos>-1)
    {
        new Handle:menu=CreateMenu(Admin_Credits_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        decl String:playername[64];
        new Handle:playerHandle=GetArrayCell(arrayPlayers,targetvecpos);
        GetClientName(GetArrayCell(playerHandle,0),playername,sizeof(playername));
        SetMenuTitle(menu,"[SourceCraft] Select an option for %s.",playername);

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
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        Admin(client,0);
    }
}

public Admin_Credits_Select(Handle:menu,MenuAction:action,client,selection)
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

                PrintToChat(client, "%c[SourceCraft] %cYou gave \"%s\" %d %s(s).",
                            COLOR_GREEN,COLOR_DEFAULT,targetname,credadd,currency);

                PrintToChat(index, "%c[SourceCraft] %cYou recieved %d %s(s) from admin \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,credadd,currency,adminname);

                Admin_Credits(client,index);
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

                PrintToChat(client, "%c[SourceCraft] %cYou removed %d %s(s) from player \"%s\".",
                            COLOR_GREEN,COLOR_DEFAULT,credrem,currency,targetname);

                PrintToChat(index, "%c[SourceCraft] %cAdmin \"%s\" removed %d %s(s) from you.",
                            COLOR_GREEN,COLOR_DEFAULT,adminname,credrem,currency);

                Admin_Credits(client,index);
            }
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            Admin(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}
