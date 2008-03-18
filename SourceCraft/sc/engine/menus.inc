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

new Function:gShopMenuParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new Function:gRaceMenuParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new Function:gSkillMenuParentMenuFunction[MAXPLAYERS+1] = {INVALID_FUNCTION,...};
new bool:gShopMenuMode[MAXPLAYERS+1];
new bool:gRaceMenuMode[MAXPLAYERS+1];
new gShowItemsTarget[MAXPLAYERS+1];

new Handle:hTopAdminMenu = INVALID_HANDLE;

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
        hTopAdminMenu = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:topmenu)
{
    /************************************************************/
    /* Add Administer SourceCraft option to SourceMod Admin Menu */
    /************************************************************/

    /* Block us from being called twice */
    if (topmenu != hTopAdminMenu)
    {
        /* Save the Handle */
        hTopAdminMenu = topmenu;
        new TopMenuObject:server_commands = FindTopMenuCategory(hTopAdminMenu, ADMINMENU_SERVERCOMMANDS);
        AddToTopMenu(hTopAdminMenu, "sc_admin", TopMenuObject_Item, AdminTopMenu,
                     server_commands, "sc_admin", ADMFLAG_SOURCECRAFT);
    }
}

public AdminTopMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Administer SourceCraft");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        AdminMenu(param,param);
    }
}

public IntroMenu(client)
{
    new Handle:introMenu=CreateMenu(IntroMenu_Action);
    SetMenuExitButton(introMenu,false);
    if (RACE_COUNT() >= 1)
    {
        SetMenuTitle(introMenu,"Welcome to this SourceCraft *BETA TEST* server!\nYou get Experience and/or Crystals for completing objectives.\nFor each level gained from Experience, you may choose a skill to\nlevel up. Purchase items in the Shopmenu with your Crystals.\nFor a command list, type help in\nchat or menu to use the menu system.\nPlease report any bugs you notice to www.jigglysfunhouse.net\nBETA %s",VERSION);
    }
    else
    {
        SetMenuTitle(introMenu,"Welcome to this SourceCraft *BETA TEST* server!\nYou get Crystals for completing objectives.\nPurchase items in the Shopmenu with your Crystals.\nFor a command list, type help in\nchat or menu to use the menu system.\nPlease report any bugs you notice to www.jigglysfunhouse.net\nBETA %s",VERSION);
    }
    SetMenuExitButton(introMenu,true);
    AddMenuItem(introMenu,"","Exit");
    DisplayMenu(introMenu,client, 20);
}

public IntroMenu_Action(Handle:menu,MenuAction:action,client,param)
{
    if (action == MenuAction_Select ||
        (action == MenuAction_Cancel && param == MenuCancel_Timeout))
    {
        if (m_FirstSpawn[client] > 1 && RACE_COUNT() >= 1)
            RaceMenu(client, true, INVALID_FUNCTION);
        else
            m_FirstSpawn[client]=0;
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public MainMenu(client,Handle:playerHandle,Function:parentMenuFunction)
{
    new Handle:scMenu=CreateMenu(Menu_Select);
    SetMenuExitButton(scMenu,true);
    SetMenuTitle(scMenu,"[SourceCraft] Choose a task.");
    new race_style = (RACE_COUNT() >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    new shop_style = (GetArraySize(shopVector) >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    decl String:buf[11];
    Format(buf,sizeof(buf),"%d",playerHandle);
    AddMenuItem(scMenu,buf,"Bring up the shopmenu",shop_style);
    AddMenuItem(scMenu,buf,"Change your race",race_style);
    AddMenuItem(scMenu,buf,"View your race's skills information",race_style);
    AddMenuItem(scMenu,buf,"Reset your skills",race_style);
    AddMenuItem(scMenu,buf,"Spend unused skill points",race_style);
    AddMenuItem(scMenu,buf,"Show current skill levels",race_style);
    AddMenuItem(scMenu,buf,"Show current items owned",shop_style);
    AddMenuItem(scMenu,buf,"View command list");
    DisplayMenu(scMenu,client,MENU_TIME_FOREVER);
}

public Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new Handle:playerHandle=Handle:StringToInt(SelectionInfo);
        if (playerHandle == GetPlayerHandle(client))
        {
            switch(selection)
            {
                case 0: // shopmenu
                    ShopMenu(client,playerHandle,true,MainMenu);
                case 1: // changerace
                    RaceMenu(client,true,MainMenu);
                case 2: // skillsinfo
                    SkillsInfo(client,GetRace(playerHandle),false,MainMenu);
                case 3: // resetskills
                {
                    ResetSkills(client,playerHandle);
                    MainMenu(client,playerHandle,INVALID_FUNCTION);
                }
                case 4: // spendskills
                {
                    new race=GetRace(playerHandle);
                    if(GetSkillCount(playerHandle,race)<GetLevel(playerHandle,race))
                        SkillMenu(client, playerHandle, MainMenu);
                    else
                    {
                        PrintToChat(client, "%c[SourceCraft] %cYou don't have any skill points to spend, if you want to reset your skills use resetskills.", COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                case 5: // showskills
                    ShowSkills(client,client,playerHandle,MainMenu);
                case 6: // showitems
                    ShopMenu(client,playerHandle,false,MainMenu);
                case 7: // help
                    Help(client,MainMenu);
            }
        }
        else
        {
            // Client must of quit!
            CloseHandle(menu);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public RaceMenu(client,bool:change,Function:parentMenuFunction)
{
    if (RACE_COUNT() >= 1)
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
        decl String:rbuf[11];
        decl String:rname[64];
        decl String:ritem[96];
        new raceCount = RACE_COUNT();
        for(new x=0;x<raceCount;x++)
        {
            race=Race(x);
            Format(rbuf,sizeof(rbuf),"%d",x);
            GetRaceName(race,rname,sizeof(rname));
            new reqLevel = GetRaceRequiredLevel(race);
            if (reqLevel)
            {
                new level = GetOverallLevel(GetPlayerHandle(client));
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
    else
        PrintToChat(client, "%c[SourceCraft] %cThere are no races to choose!",
                COLOR_GREEN,COLOR_DEFAULT);
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
            new Handle:playerHandle=GetPlayerHandle(client);
            if (playerHandle != INVALID_HANDLE)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gRaceMenuParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(playerHandle);
                Call_PushCell(INVALID_FUNCTION);
                Call_Finish(result);
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public SkillMenu(client, Handle:playerHandle, Function:parentMenuFunction)
{
    if (RACE_COUNT() >= 1)
    {
        new Handle:sMenu=CreateMenu(SMenu_Selected);
        new race_num=GetRace(playerHandle);
        new skillcount=GetSkillCount(playerHandle,race_num);
        new level=GetLevel(playerHandle,race_num);
        SetMenuExitButton(sMenu,true);
        SetMenuExitBackButton(sMenu,(parentMenuFunction != INVALID_FUNCTION));
        SetMenuTitle(sMenu,"[SourceCraft] Select your desired skill. (%d/%d)",skillcount,level);
        decl String:skillname[64];
        new curlevel;
        new Handle:race=Race(race_num);
        new Handle:strings=GetArrayCell(race,RACE_STRINGS);
        decl String:sbuf[11];
        decl String:buf[192];
        new style = ITEMDRAW_DEFAULT;
        for(new x=0;x<SKILL_COUNT;x++)
        {
            GetArrayString(strings,RACE_SKILL+(x*2),skillname,sizeof(skillname));
            Format(sbuf,sizeof(sbuf),"%d",x);
            curlevel=GetSkillLevel(playerHandle,race_num,x);
            if(curlevel!=4)
            {
                if(x!=SKILL_ULTIMATE)
                    Format(buf,sizeof(buf),"%s (Skill Level %d)",skillname,curlevel+1);
                else
                {
                    Format(buf,sizeof(buf),"Ultimate: %s (Skill Level %d) (Minimum Level %d)",
                           skillname,curlevel+1,MIN_ULTIMATE_LEVEL);
                    if (GetLevel(playerHandle,race_num) < MIN_ULTIMATE_LEVEL)
                        style = ITEMDRAW_DISABLED;
                }
                AddMenuItem(sMenu,sbuf,buf,style);
            }
        }
        gSkillMenuParentMenuFunction[client]=parentMenuFunction;
        DisplayMenu(sMenu,client,MENU_TIME_FOREVER);
    }
    else
        PrintToChat(client, "%c[SourceCraft] %cThere are no races or skills to choose!",
                COLOR_GREEN,COLOR_DEFAULT);
}

public SMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            if (selection >= 0 && selection < SKILL_COUNT)
            {
                // Okay, they selected a valid skill
                decl String:SelectionInfo[11];
                decl String:SelectionDispText[256];
                new SelectionStyle;
                GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                            SelectionDispText,sizeof(SelectionDispText));
                new skill=StringToInt(SelectionInfo);
                if (skill > -1 && skill < SKILL_COUNT)
                {
                    new race = GetRace(playerHandle);
                    new level = GetLevel(playerHandle,race);
                    if (GetSkillCount(playerHandle,race)>=level)
                    {
                        PrintToChat(client, "%c[SourceCraft] %cYou can not choose a skill without gaining another level.",
                                    COLOR_GREEN,COLOR_DEFAULT);
                    }
                    else
                    {
                        new Handle:raceHandle=Race(race);
                        new Handle:stringHandle=GetArrayCell(raceHandle,RACE_STRINGS);
                        if (skill==SKILL_ULTIMATE)
                        {
                            if (level >= MIN_ULTIMATE_LEVEL)
                            {
                                IncrementSkillLevel(playerHandle,race,skill);
                                decl String:skillname[64];
                                GetArrayString(stringHandle,RACE_SKILL+(skill*2),skillname,sizeof(skillname));
                                PrintToChat(client, "%c[SourceCraft] %c\"%s\" is now level %d.",
                                            COLOR_GREEN,COLOR_DEFAULT,skillname,
                                            GetSkillLevel(playerHandle,race,skill));
                            }
                            else
                            {
                                PrintToChat(client, "%c[SourceCraft] %cYou need to be at least level %d to choose an ultimate.",
                                            COLOR_GREEN,COLOR_DEFAULT,MIN_ULTIMATE_LEVEL);
                            }
                        }
                        else
                        {
                            IncrementSkillLevel(playerHandle,race,skill);
                            decl String:skillname[64];
                            GetArrayString(stringHandle,RACE_SKILL+(skill*2),skillname,sizeof(skillname));
                            PrintToChat(client, "%c[SourceCraft] %c\"%s\" is now level %d.",
                                        COLOR_GREEN,COLOR_DEFAULT,skillname,
                                        GetSkillLevel(playerHandle,race,skill));
                        }

                        if (GetSkillCount(playerHandle,race)<GetLevel(playerHandle,race))
                            SkillMenu(client,playerHandle,gSkillMenuParentMenuFunction[client]);
                    }
                }
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        new Function:backFn = gSkillMenuParentMenuFunction[client];
        if (selection == MenuCancel_ExitBack && backFn != INVALID_FUNCTION)
        {
            decl result;
            ClientCommand(client,"play buttons/button14.wav");
            Call_StartFunction(INVALID_HANDLE, backFn);
            Call_PushCell(client);
            Call_PushCell(GetPlayerHandle(client));
            Call_PushCell(INVALID_FUNCTION);
            Call_Finish(result);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public ShopMenu(client, Handle:playerHandle, bool:shopmenu, Function:parentMenuFunction)
{
    new shopItemCount = GetArraySize(shopVector);
    if (shopItemCount >= 1)
    {
        new credits=GetCredits(playerHandle);
        decl String:currencies[64];
        GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
        new Handle:shopMenu=CreateMenu(ShopMenu_Selected);
        SetMenuExitButton(shopMenu,true);
        SetMenuExitBackButton(shopMenu,(parentMenuFunction != INVALID_FUNCTION));

        if (shopmenu)
            SetMenuTitle(shopMenu,"[SourceCraft] Select an item to look at. - You have %d %s",credits,currencies);
        else
            SetMenuTitle(shopMenu,"[SourceCraft] Here is a list of the items you currently have. - You have %d %s",credits,currencies);

        new Handle:itemHandle;
        decl String:itemname[64];
        decl String:itembuf[11];
        decl String:linestr[96];
        decl String:cost[8];

        new count = 0;
        for(new x=0;x<shopItemCount;x++)
        {
            if (shopmenu || GetOwnsItem(playerHandle,x))
            {
                count++;
                Format(itembuf,sizeof(itembuf),"%d",x);
                itemHandle=ShopItem(x);
                GetArrayString(itemHandle,SHOPITEM_NAME,itemname,sizeof(itemname));
                if (shopmenu)
                {
                    GetArrayString(itemHandle,SHOPITEM_COST,cost,sizeof(cost));
                    Format(linestr,sizeof(linestr),"%s - %s %s",itemname,cost,currencies);
                    AddMenuItem(shopMenu,itembuf,linestr);
                }
                else
                    AddMenuItem(shopMenu,itembuf,itemname);
            }
        }

        if (count)
        {
            gShopMenuMode[client] = shopmenu;
            gShopMenuParentMenuFunction[client]=parentMenuFunction;
            DisplayMenu(shopMenu,client,MENU_TIME_FOREVER);
        }
        else
            ShowItems(client,client,playerHandle,parentMenuFunction);
    }
    else
        PrintToChat(client, "%c[SourceCraft] %cThere are no items in the shopmenu!",
                    COLOR_GREEN,COLOR_DEFAULT);
}

public ShopMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            decl String:SelectionInfo[11];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                        SelectionDispText,sizeof(SelectionDispText));
            new item=StringToInt(SelectionInfo);
            if(item>-1 && item<GetArraySize(shopVector))
                ShopMenu_Item(client,playerHandle,item);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack &&
            gShopMenuParentMenuFunction[client] != INVALID_FUNCTION)
        {
            new Handle:playerHandle=GetPlayerHandle(client);
            if (playerHandle != INVALID_HANDLE)
            {
                decl result;
                ClientCommand(client,"play buttons/button14.wav");
                Call_StartFunction(INVALID_HANDLE, gShopMenuParentMenuFunction[client]);
                Call_PushCell(client);
                Call_PushCell(playerHandle);
                Call_PushCell(INVALID_FUNCTION);
                Call_Finish(result);
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public ShopMenu_Item(client,Handle:playerHandle,item)
{
    new credits=GetCredits(playerHandle);
    decl String:currencies[64];
    GetConVarString((credits == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
    new Handle:shopMenu_Item=CreateMenu(ShopMenu_Item_Select);
    SetMenuExitButton(shopMenu_Item,true);
    SetMenuExitBackButton(shopMenu_Item,true);
    decl String:itemname[64];
    new Handle:itemHandle;
    itemHandle=ShopItem(item);
    GetArrayString(itemHandle,SHOPITEM_NAME,itemname,sizeof(itemname));
    decl String:desc[300];
    GetArrayString(itemHandle,SHOPITEM_DESC,desc,sizeof(desc));
    Format(desc,sizeof(desc),"Description: %s",desc);
    decl String:cost[32];
    GetArrayString(itemHandle,SHOPITEM_COST,cost,sizeof(cost));
    Format(cost,sizeof(cost),"Cost: %s %s",cost, currencies);
    SetMenuTitle(shopMenu_Item,"[SourceCraft] Shop Item - %s - You have %d %s\n%s\n%s",
                 itemname,credits,currencies,desc,cost);
    decl String:buf[11];
    Format(buf,sizeof(buf),"%d",item);

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
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            decl String:SelectionInfo[11];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                        SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
            new item=StringToInt(SelectionInfo);
            if(selection==0)
            {
                // Purchase
                new credits=GetCredits(playerHandle);
                decl String:cost[11];
                new Handle:itemHandle=ShopItem(item);

                decl String:itemname[64];
                GetArrayString(itemHandle,SHOPITEM_NAME,itemname,sizeof(itemname));

                GetArrayString(itemHandle,SHOPITEM_COST,cost,sizeof(cost));
                new cost_num=StringToInt(cost);
                if(credits>=cost_num)
                {
                    if(!GetOwnsItem(playerHandle,item))
                    {
                        new newcredits=credits-cost_num;
                        SetCredits(playerHandle,newcredits);
                        SetOwnsItem(playerHandle,item,1);
                        Call_StartForward(g_OnItemPurchaseHandle);
                        Call_PushCell(client);
                        Call_PushCell(playerHandle);
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
                    EmitSoundToClient(client,notEnoughWav);
                    PrintToChat(client, "%c[SourceCraft] %cYou can not afford the %s.",
                                COLOR_GREEN,COLOR_DEFAULT,itemname);
                }
            }
            else if(selection==1)
            {
                ShopMenu(client,playerHandle,gShopMenuMode[client],
                         gShopMenuParentMenuFunction[client]);
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");
            ShopMenu(client,GetPlayerHandle(client),
                     gShopMenuMode[client],gShopMenuParentMenuFunction[client]);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public ShowItems(client,target,Handle:playerHandle,Function:parentMenuFunction)
{
    new Handle:panel=CreatePanel();

    if (client == target)
        SetPanelTitle(panel,"[SourceCraft] Here are your shop items.");
    else
    {
        decl String:buffer[256];
        Format(buffer,sizeof(buffer),"[SourceCraft] Here are %N's items.", target);
        SetPanelTitle(panel,buffer);
    }

    decl String:itemname[64];
    new Handle:itemHandle;
    DrawPanelText(panel,"-----------------------------");
    new shopItemCount = GetArraySize(shopVector);
    for(new x=0;x<shopItemCount;x++)
    {
        if (GetOwnsItem(playerHandle,x))
        {
            itemHandle=ShopItem(x);
            GetArrayString(itemHandle,SHOPITEM_NAME,itemname,sizeof(itemname));
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
        Call_PushCell(INVALID_FUNCTION);
        Call_Finish(result);
    }
}

public Action:AdminMenu(client,args)
{
    new Handle:adminMenu=CreateMenu(Admin_Selected);
    SetMenuExitButton(adminMenu,true);
    SetMenuTitle(adminMenu,"[SourceCraft] Select a player to administrate.");
    decl String:playername[64];
    decl String:playerbuf[11];
    for(new target=0;target<=MAXPLAYERS;target++)
    {
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            Format(playerbuf,sizeof(playerbuf),"%d",target);
            GetClientName(target,playername,sizeof(playername));
            AddMenuItem(adminMenu,playerbuf,playername);
        }
    }
    DisplayMenu(adminMenu,client,MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public Admin_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                    SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
            Admin_Player(client,target);
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player you selected has left the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public Admin_Player(client,target)
{
    new Handle:adminMenu_Player=CreateMenu(Admin_Player_Select);
    SetMenuExitButton(adminMenu_Player,true);
    SetMenuExitBackButton(adminMenu_Player,true);

    new race_style = (RACE_COUNT() >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    new shop_style = (GetArraySize(shopVector) >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    SetMenuTitle(adminMenu_Player,"[SourceCraft] Administration options for %N.", target);
    decl String:buf[11];
    Format(buf,sizeof(buf),"%d",target);
    decl String:currencies[64];
    GetConVarString(m_Currencies, currencies, sizeof(currencies));
    decl String:changeCredits[128];
    Format(changeCredits,sizeof(changeCredits),"Increase/Decrease %s", currencies);
    AddMenuItem(adminMenu_Player,buf,"View detailed information");
    AddMenuItem(adminMenu_Player,buf,"Reset skills", race_style);
    AddMenuItem(adminMenu_Player,buf,"Set race", race_style);
    AddMenuItem(adminMenu_Player,buf,"Give shop item", shop_style);
    AddMenuItem(adminMenu_Player,buf,"Increase/Decrease XP", race_style);
    AddMenuItem(adminMenu_Player,buf,"Increase/Decrease Level", race_style);
    AddMenuItem(adminMenu_Player,buf,changeCredits);
    DisplayMenu(adminMenu_Player,client,MENU_TIME_FOREVER);
}

public Admin_Player_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            // What do they want to do with the player?
            switch(selection)
            {
                case 0:
                {
                    // Player info selected
                    Admin_PlayerInfo(client,target);
                }
                case 1:
                {
                    // Reset skills
                    new race=GetRace(targetHandle);
                    for(new y=0;y<SKILL_COUNT;y++)
                            SetSkillLevel(targetHandle,race,y,0);

                    if(GetSkillCount(targetHandle,race)<GetLevel(targetHandle,race))
                        SkillMenu(target, targetHandle, Admin_Player);

                    PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" reset your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,client);

                    PrintToChat(client, "%c[SourceCraft] %cYou reset player \"%N\" skills.",
                                COLOR_GREEN,COLOR_DEFAULT,target);
                }
                case 2:
                {
                    // Set race
                    Admin_SetRace(client,target);
                }
                case 3:
                {
                    // Give shop item
                    Admin_GiveShopItem(client,target);
                }
                case 4:
                {
                    // Increase/Decrease XP
                    Admin_XP(client,target);
                }
                case 5:
                {
                    // Increase/Decrease Level
                    Admin_Level(client,target);
                }
                case 6:
                {
                    // Increase/Decrease Credits
                    Admin_Credits(client,target);
                }
            }
            if(selection==1)
                Admin_Player(client,target);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player you selected has left the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            ClientCommand(client,"play buttons/button14.wav");
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public Admin_PlayerInfo(client,target)
{
    new Handle:targetHandle=GetPlayerHandle(target);
    if (targetHandle != INVALID_HANDLE)
    {
        decl String:currency[64];
        GetConVarString(m_Currencies, currency, sizeof(currency));

        new Handle:playerInfo=CreateMenu(Admin_PI_Select);
        SetMenuExitButton(playerInfo,true);
        SetMenuExitBackButton(playerInfo,true);

        new race=GetRace(targetHandle);
        new Handle:rhand=Race(race);
        new Handle:shand=GetArrayCell(rhand,RACE_STRINGS);
        decl String:race_name[64];
        GetArrayString(shand,RACE_NAME,race_name,sizeof(race_name));

        new credits=GetCredits(targetHandle);
        new xp=GetXP(targetHandle,race);
        new level=GetLevel(targetHandle,race);

        SetMenuTitle(playerInfo,"[SourceCraft] Info for %N.\nRace: %s\n%s: %d\nXP: %d\nLevel: %d",
                     target,race_name,currency,credits,xp,level);

        decl String:buf[11];
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
        AdminMenu(client,0);
    }
}

public Admin_PI_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,1,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            switch(selection)
            {
                case 0: // skill levels
                    ShowSkills(client,target,targetHandle,Admin_PlayerInfo);
                case 1: // shop items
                    ShowItems(client,target,targetHandle,Admin_PlayerInfo);
                default:
                    Admin_Player(client,target);
            }
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

Admin_Return(Handle:menu,client)
{
    ClientCommand(client,"play buttons/button14.wav");
    decl String:SelectionInfo[11];
    decl String:SelectionDispText[256];
    new SelectionStyle;
    GetMenuItem(menu,1,SelectionInfo,sizeof(SelectionInfo),
                SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    new target=StringToInt(SelectionInfo);
    new Handle:targetHandle=GetPlayerHandle(target);
    if (targetHandle != INVALID_HANDLE)
        Admin_Player(client,target);
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        AdminMenu(client,0);
    }
}

public Admin_XP(client,target)
{
    new Handle:targetHandle=GetPlayerHandle(target);
    if (targetHandle != INVALID_HANDLE)
    {
        new Handle:menu=CreateMenu(Admin_XP_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);
        SetMenuTitle(menu,"[SourceCraft] Select an option for %N.",target);

        decl String:buf[11];
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
        AdminMenu(client,0);
    }
}

public Admin_XP_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            new race=GetRace(targetHandle);
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
                new newxp=GetXP(targetHandle,race)+xpadd;
                SetXP(targetHandle,race,newxp);

                PrintToChat(client, "%c[SourceCraft] %cYou gave \"%N\" %d XP.",
                            COLOR_GREEN,COLOR_DEFAULT,target,xpadd);

                PrintToChat(target, "%c[SourceCraft] %cYou recieved %d XP from admin \"%N\".",
                            COLOR_GREEN,COLOR_DEFAULT,xpadd,client);

                DoLevelCheck(target,targetHandle);
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
                new newxp=GetXP(targetHandle,race)-xprem;
                if(newxp<0)
                    newxp=0;

                SetXP(targetHandle,race,newxp);

                PrintToChat(client, "%c[SourceCraft] %cYou removed %d XP from player \"%N\".",
                            COLOR_GREEN,COLOR_DEFAULT,xprem,target);

                PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" removed %d XP from you.",
                            COLOR_GREEN,COLOR_DEFAULT,client,xprem);
            }
            Admin_XP(client,target);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public Admin_GiveShopItem(client,target)
{
    new Handle:targetHandle=GetPlayerHandle(target);
    if (targetHandle != INVALID_HANDLE)
    {
        new Handle:menu=CreateMenu(Admin_GSI_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        SetMenuTitle(menu,"[SourceCraft] Select an item to give to %N.", target);

        decl String:buf[11];
        Format(buf,sizeof(buf),"%d",target);

        decl String:itemname[64];
        new Handle:itemHandle;
        new shopItemCount = GetArraySize(shopVector);
        for(new x=0;x<shopItemCount;x++)
        {
            itemHandle=ShopItem(x);
            GetArrayString(itemHandle,SHOPITEM_NAME,itemname,sizeof(itemname));
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
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            new item=selection;
            if(!GetOwnsItem(targetHandle,item))
            {
                SetOwnsItem(targetHandle,item,1);
                Call_StartForward(g_OnItemPurchaseHandle);
                Call_PushCell(target);
                Call_PushCell(targetHandle);
                Call_PushCell(item);
                new result;
                Call_Finish(result);
                new Handle:itemHandle=ShopItem(item);
                decl String:itemname[64];
                GetArrayString(itemHandle,SHOPITEM_NAME,itemname,sizeof(itemname));

                PrintToChat(client, "%c[SourceCraft] %cYou gave \"%N\" a %s.",
                            COLOR_GREEN,COLOR_DEFAULT,target,itemname);

                PrintToChat(target, "%c[SourceCraft] %cYou recieved a %s from admin \"%N\".",
                            COLOR_GREEN,COLOR_DEFAULT,itemname,client);

                Admin_Player(client,target);
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
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public Admin_SetRace(client,target)
{
    new Handle:targetHandle=GetPlayerHandle(target);
    if (targetHandle != INVALID_HANDLE)
    {
        new Handle:menu=CreateMenu(Admin_SetRace_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        SetMenuTitle(menu,"[SourceCraft] Select a race for %N.", target);

        decl String:buf[11];
        Format(buf,sizeof(buf),"%d",target);

        decl String:racename[64];
        new raceCount = RACE_COUNT();
        for(new x=0;x<raceCount;x++)
        {
            GetRaceName(Race(x),racename,sizeof(racename));
            AddMenuItem(menu,buf,racename);
        }
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        AdminMenu(client,0);
    }
}

public Admin_SetRace_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            SetRace(targetHandle,selection);
            decl String:racename[64];
            GetRaceName(Race(selection),racename,sizeof(racename));

            PrintToChat(client, "%c[SourceCraft] %cYou set player \"%N\" to race %s.",
                        COLOR_GREEN,COLOR_DEFAULT,target,racename);

            PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" set you to race %s.",
                        COLOR_GREEN,COLOR_DEFAULT,client,racename);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public Admin_Level(client,target)
{
    new Handle:targetHandle=GetPlayerHandle(target);
    if (targetHandle != INVALID_HANDLE)
    {
        new Handle:menu=CreateMenu(Admin_Level_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        SetMenuTitle(menu,"[SourceCraft] Select an option for %N.", target);

        decl String:buf[11];
        Format(buf,sizeof(buf),"%d",target);

        AddMenuItem(menu,buf,"Give a level");
        AddMenuItem(menu,buf,"Remove a level");
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                    COLOR_GREEN,COLOR_DEFAULT);
        AdminMenu(client,0);
    }
}

public Admin_Level_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            new race=GetRace(targetHandle);
            if(selection==0)
            {
                // Give a level
                new newlevel=GetLevel(targetHandle,race)+1;
                if(newlevel>MAX_LEVELS)
                {
                    PrintToChat(client, "%c[SourceCraft] %cPlayer \"%N\" is already at the max level.",
                                COLOR_GREEN,COLOR_DEFAULT,target);
                }
                else
                {
                    SetLevel(targetHandle,race,newlevel);
                    SetOverallLevel(targetHandle, GetOverallLevel(targetHandle)+1);
                    SkillMenu(target, targetHandle, Admin_Level);

                    PrintToChat(client, "%c[SourceCraft] %cYou gave player \"%N\" a level.",
                                COLOR_GREEN,COLOR_DEFAULT,target);

                    PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" gave you a level.",
                                COLOR_GREEN,COLOR_DEFAULT,client);
                }
            }
            else
            {
                // Remove a level
                new newlevel=GetLevel(targetHandle,race)-1;
                if (newlevel<0)
                {
                    PrintToChat(client, "%c[SourceCraft] %cPlayer \"%N\" is already level 0.",
                                COLOR_GREEN,COLOR_DEFAULT,target);
                }
                else
                {
                    SetLevel(targetHandle,race,newlevel);
                    SetOverallLevel(targetHandle, GetOverallLevel(targetHandle)-1);
                    for(new x=0;x<SKILL_COUNT;x++)
                        SetSkillLevel(targetHandle,race,x,0);

                    PrintToChat(client, "%c[SourceCraft] %cYou removed a level from player \"%N\".",
                                COLOR_GREEN,COLOR_DEFAULT,target);

                    PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" removed a level from you, re-pick your skills.",
                                COLOR_GREEN,COLOR_DEFAULT,client);

                    if(newlevel>0)
                        SkillMenu(target, targetHandle, Admin_Level);
                }
            }
            Admin_Level(client,target);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public Admin_Credits(client,target)
{
    new Handle:targetHandle=GetPlayerHandle(target);
    if (targetHandle != INVALID_HANDLE)
    {
        new Handle:menu=CreateMenu(Admin_Credits_Select);
        SetMenuExitButton(menu,true);
        SetMenuExitBackButton(menu,true);

        SetMenuTitle(menu,"[SourceCraft] Select an option for %N.", target);

        decl String:buf[11];
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
        AdminMenu(client,0);
    }
}

public Admin_Credits_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        ClientCommand(client,"play buttons/button14.wav");
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            decl String:currency[64];
            GetConVarString(m_Currency, currency, sizeof(currency));
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
                new newcred=GetCredits(targetHandle)+credadd;
                new maxCredits = GetConVarInt(m_MaxCredits);
                if(newcred>maxCredits)
                    newcred=maxCredits;
                SetCredits(targetHandle,newcred);

                PrintToChat(client, "%c[SourceCraft] %cYou gave \"%N\" %d %s(s).",
                            COLOR_GREEN,COLOR_DEFAULT,target,credadd,currency);

                PrintToChat(target, "%c[SourceCraft] %cYou recieved %d %s(s) from admin \"%N\".",
                            COLOR_GREEN,COLOR_DEFAULT,credadd,currency,client);

                Admin_Credits(client,target);
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
                new newcred=GetCredits(targetHandle)-credrem;
                if(newcred<0)
                    newcred=0;
                SetCredits(targetHandle,newcred);

                PrintToChat(client, "%c[SourceCraft] %cYou removed %d %s(s) from player \"%N\".",
                            COLOR_GREEN,COLOR_DEFAULT,credrem,currency,target);

                PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" removed %d %s(s) from you.",
                            COLOR_GREEN,COLOR_DEFAULT,client,credrem,currency);

                Admin_Credits(client,target);
            }
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThe player has disconnected from the server.",
                        COLOR_GREEN,COLOR_DEFAULT);
            AdminMenu(client,0);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            Admin_Return(menu,client);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}
