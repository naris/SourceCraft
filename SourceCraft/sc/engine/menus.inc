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

new bool:gShopMenuMode[MAXPLAYERS+1];
new bool:gRaceMenuMode[MAXPLAYERS+1];
new gShowItemsTarget[MAXPLAYERS+1];

new Handle:hTopAdminMenu = INVALID_HANDLE;
new Handle:g_IntroMenu   = INVALID_HANDLE;
new Handle:g_MainMenu    = INVALID_HANDLE;

InitMenus()
{
    /* Account for late loading */
    new Handle:topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
    {
        OnAdminMenuReady(topmenu);
    }
    return true;
}

CleanupMenus()
{
    if (g_IntroMenu != INVALID_HANDLE)
    {
        CloseHandle(g_IntroMenu);
        g_IntroMenu = INVALID_HANDLE;
    }

    if (g_MainMenu != INVALID_HANDLE)
    {
        CloseHandle(g_MainMenu);
        g_MainMenu = INVALID_HANDLE;
    }
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

IntroMenu(client)
{
    if (g_IntroMenu == INVALID_HANDLE)
    {
        g_IntroMenu=CreateMenu(IntroMenu_Action);
        SetMenuExitButton(g_IntroMenu,false);
        if (GetRaceCount() >= 1)
        {
            if (GetShopItemCount() >= 1)
            {
                SetMenuTitle(g_IntroMenu,"Welcome to this SourceCraft *BETA TEST* server!\nYou get Experience and/or Crystals for completing objectives.\nFor each level gained from Experience, you may choose an Upgrade to\nlevel up. Purchase items in the Shopmenu with your Crystals.\nFor a command list, type help in chat or menu to use the menu system.\nPlease report any bugs you notice to www.jigglysfunhouse.net\nBETA %s",VERSION);
            }
            else
            {
                SetMenuTitle(g_IntroMenu,"Welcome to this SourceCraft *BETA TEST* server!\nYou get Experience for completing objectives.\nFor each level gained from Experience, you may choose an Upgrade to level up. \nFor a command list, type help in chat or menu to use the menu system.\nPlease report any bugs you notice to www.jigglysfunhouse.net\nBETA %s",VERSION);
            }
        }
        else
        {
            SetMenuTitle(g_IntroMenu,"Welcome to this SourceCraft *BETA TEST* server!\nYou get Crystals for completing objectives.\nPurchase items in the Shopmenu with your Crystals.\nFor a command list, type help in\nchat or menu to use the menu system.\nPlease report any bugs you notice to www.jigglysfunhouse.net\nBETA %s",VERSION);
        }
        SetMenuExitButton(g_IntroMenu,true);
        AddMenuItem(g_IntroMenu,"","Exit");
    }
    DisplayMenu(g_IntroMenu,client, 20);
}

public IntroMenu_Action(Handle:menu,MenuAction:action,client,param)
{
    if (action == MenuAction_Select ||
        (action == MenuAction_Cancel && param == MenuCancel_Timeout))
    {
        if (m_FirstSpawn[client] > 1 && GetRaceCount() >= 1)
            RaceMenu(client, true);

        m_FirstSpawn[client]=0;
    }
    else if (action == MenuAction_Cancel)
    {
        m_FirstSpawn[client]=0;
    }
}

MainMenu(client)
{
    if (g_MainMenu == INVALID_HANDLE)
    {
        g_MainMenu=CreateMenu(Menu_Select);
        SetMenuExitButton(g_MainMenu,true);
        SetMenuTitle(g_MainMenu,"[SourceCraft] Choose a task.");
        new race_style = (GetRaceCount() >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
        new shop_style = (GetArraySize(shopVector) >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
        AddMenuItem(g_MainMenu,"0","Bring up the shopmenu",shop_style);
        AddMenuItem(g_MainMenu,"1","Change your race",race_style);
        AddMenuItem(g_MainMenu,"2","View your race's upgrade information",race_style);
        AddMenuItem(g_MainMenu,"3","Reset your upgrades",race_style);
        AddMenuItem(g_MainMenu,"4","Spend unused upgrade points",race_style);
        AddMenuItem(g_MainMenu,"5","Show current upgrade levels",race_style);
        AddMenuItem(g_MainMenu,"6","Show current items owned",shop_style);
        AddMenuItem(g_MainMenu,"7","View command list");
    }
    DisplayMenu(g_MainMenu,client,MENU_TIME_FOREVER);
}

public Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
        switch(selection)
        {
            case 0: // shopmenu
                ShopMenu(client,true);
            case 1: // changerace
                RaceMenu(client,true);
            case 2: // upgradesinfo
            {
                new Handle:playerHandle=GetPlayerHandle(client);
                if (playerHandle != INVALID_HANDLE)
                {
                    UpgradesInfo(client,GetRace(playerHandle),false);
                }
            }
            case 3: // resetupgrades
            {
                new Handle:playerHandle=GetPlayerHandle(client);
                if (playerHandle != INVALID_HANDLE)
                {
                    ResetUpgrades(client,playerHandle);
                }
                MainMenu(client);
            }
            case 4: // spendupgrades
            {
                new Handle:playerHandle=GetPlayerHandle(client);
                new race=GetRace(playerHandle);
                if (GetUpgradeLevelCount(playerHandle,race)<GetLevel(playerHandle,race))
                    UpgradeMenu(client, playerHandle);
                else
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou don't have any upgrade points to spend, if you want to reset your upgrades use resetupgrades.", COLOR_GREEN,COLOR_DEFAULT);
                }
            }
            case 5: // showupgrades
            {
                new Handle:playerHandle=GetPlayerHandle(client);
                if (playerHandle != INVALID_HANDLE)
                {
                    ShowUpgrades(client,client,playerHandle);
                }
            }
            case 6: // showitems
                ShopMenu(client,false);
            case 7: // help
                Help(client);
        }
    }
}

RaceMenu(client,bool:change)
{
    if (GetRaceCount() >= 1)
    {
        new Handle:crMenu=CreateMenu(RaceMenu_Selected);

        if (change)
            SetMenuTitle(crMenu, "[SourceCraft] Select your desired race.\n");
        else
            SetMenuTitle(crMenu, "[SourceCraft] Select a race to view.");

        SetMenuExitButton(crMenu,true);

        // Iterate through the races and print them out
        new Handle:raceHandle;
        decl String:rbuf[11];
        decl String:name[64];
        decl String:item[256];
        new reqLevel, level, style;
        new raceCount = GetRaceCount();
        for(new race=0;race<raceCount;race++)
        {
            raceHandle=GetRaceHandle(race);
            reqLevel = GetRaceRequiredLevel(raceHandle);
            if (reqLevel)
            {
                level = GetOverallLevel(GetPlayerHandle(client));
                style = (change && level < reqLevel) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
                GetRaceName(raceHandle,name,sizeof(name));
                Format(item,sizeof(item),"%s (overall level must be >= %d)",name, reqLevel);
            }
            else
            {
                style = ITEMDRAW_DEFAULT;
                GetRaceName(raceHandle,item,sizeof(item));
            }
            AddMenuItem(crMenu,rbuf,item,style);

            /*
            new upgradeCount = GetUpgradeCount(raceHandle);
            for(new upgrade=0;upgrade<upgradeCount;upgrade++)
            {
                if (upgrade == 0)
                    strcopy(item,sizeof(item),"   (");
                else
                    StrCat(item,sizeof(item),",");

                GetUpgradeName(raceHandle, upgrade, name, sizeof(name));
                StrCat(item,sizeof(item),name);
                if (IsUpgradeUltimate(raceHandle, upgrade) > 0)
                    StrCat(item,sizeof(item),"[U]");
            }
            StrCat(item,sizeof(item),")");
            Format(rbuf,sizeof(rbuf),"%d",race);
            AddMenuItem(crMenu,rbuf,item,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE);
            */
        }
        gRaceMenuMode[client]=change;
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
        EmitSoundToClient(client,buttonWav);
        UpgradesInfo(client,selection,gRaceMenuMode[client]);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

UpgradeMenu(client, Handle:playerHandle)
{
    if (GetRaceCount() >= 1)
    {
        new Handle:sMenu=CreateMenu(UpgradeMenu_Selected);
        new race=GetRace(playerHandle);
        new Handle:raceHandle=GetRaceHandle(race);
        new upgradecount=GetUpgradeLevelCount(playerHandle,race);
        new level=GetLevel(playerHandle,race);
        SetMenuExitButton(sMenu,true);
        SetMenuTitle(sMenu,"[SourceCraft] Select your desired upgrade. (%d/%d)",upgradecount,level);
        new upgradeLevel, requiredLevel, style, bool:ultimate, maxLevel;
        decl String:sbuf[11];
        decl String:buf[192];
        decl String:buf2[192];
        decl String:minLevel[64];
        decl String:upgradename[64];
        new raceLevel = GetLevel(playerHandle,race);
        new activeUltimate = GetActiveUltimate(playerHandle,race);
        new upgradeCount = GetUpgradeCount(raceHandle);
        for(new upgrade=0;upgrade<upgradeCount;upgrade++)
        {
            GetUpgradeName(raceHandle, upgrade, upgradename, sizeof(upgradename));
            Format(sbuf,sizeof(sbuf),"%d",upgrade);

            requiredLevel = GetUpgradeRequiredLevel(raceHandle,upgrade);
            if (raceLevel < requiredLevel)
            {
                upgradeLevel = 0;
                maxLevel = 0;
                style = ITEMDRAW_DISABLED;
            }
            else
            {
                upgradeLevel=GetUpgradeLevel(playerHandle,race,upgrade);
                maxLevel=GetUpgradeMaxLevel(raceHandle,upgrade);
                if (upgradeLevel >= maxLevel)
                    style = ITEMDRAW_DISABLED;
                else
                    style = ITEMDRAW_DEFAULT;
            }

            ultimate = IsUpgradeUltimate(raceHandle, upgrade);
            if (ultimate)
            {
                if (activeUltimate >= 0 && activeUltimate != upgrade)
                    style = ITEMDRAW_DISABLED;
            }

            Format(buf,sizeof(buf),"%s%s", (ultimate ? "Ultimate:" : ""), upgradename);

            if (requiredLevel > 0)
                Format(minLevel,sizeof(minLevel)," (Minimum Level %d)", requiredLevel);
            else
                minLevel = "";

            if (style == ITEMDRAW_DEFAULT)
                Format(buf2,sizeof(buf2),"%s%s (Upgrade Level %d)",buf,minLevel,upgradeLevel+1);
            else
                Format(buf2,sizeof(buf2),"%s%s",buf,minLevel);

            LogMessage("%n's Upgrade #%d(%s), ult=%d,req=%d,max=%d",
                       client,upgrade,upgradename,ultimate,requiredLevel,maxLevel);

            AddMenuItem(sMenu,sbuf,buf2,style);
        }
        DisplayMenu(sMenu,client,MENU_TIME_FOREVER);
    }
    else
        PrintToChat(client, "%c[SourceCraft] %cThere are no races or upgrades to choose!",
                    COLOR_GREEN,COLOR_DEFAULT);
}

public UpgradeMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            new race = GetRace(playerHandle);
            new Handle:raceHandle=GetRaceHandle(race);
            new upgradeCount=GetUpgradeCount(raceHandle);

            decl String:SelectionInfo[11];
            decl String:SelectionDispText[256];
            new SelectionStyle;
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                        SelectionDispText,sizeof(SelectionDispText));
            new upgrade=StringToInt(SelectionInfo);
            if (upgrade >= 0 && upgrade < upgradeCount)
            {
                // Okay, they selected a valid upgrade
                new level = GetLevel(playerHandle,race);
                if (GetUpgradeLevelCount(playerHandle,race)>=level)
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou can not choose a upgrade without gaining another level.",
                                COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    if (IsUpgradeUltimate(raceHandle, upgrade))
                    {
                        new minLevel = MIN_ULTIMATE_LEVEL;
                        if (level >= minLevel)
                        {
                            new activeUltimate = GetActiveUltimate(playerHandle,race);
                            if (activeUltimate < 0 || activeUltimate == upgrade)
                            {
                                IncrementUpgradeLevel(playerHandle,race,upgrade,true);
                                decl String:upgradename[64];
                                GetUpgradeName(raceHandle, upgrade, upgradename, sizeof(upgradename));
                                PrintToChat(client, "%c[SourceCraft] %c\"%s\" is now level %d.",
                                            COLOR_GREEN,COLOR_DEFAULT,upgradename,
                                            GetUpgradeLevel(playerHandle,race,upgrade));
                            }
                            else
                            {
                                decl String:activename[64];
                                GetUpgradeName(raceHandle, activeUltimate, activename, sizeof(activename));
                                PrintToChat(client, "%c[SourceCraft] %cYou have already chosen \"%s\" as your ultimate, to reset your upgrades use resetupgrades.", COLOR_GREEN,COLOR_DEFAULT,activename);
                            }
                        }
                        else
                        {
                            PrintToChat(client, "%c[SourceCraft] %cYou need to be at least level %d to choose an ultimate.",
                                        COLOR_GREEN,COLOR_DEFAULT,minLevel);
                        }
                    }
                    else
                    {
                        IncrementUpgradeLevel(playerHandle,race,upgrade,false);
                        decl String:upgradename[64];
                        GetUpgradeName(raceHandle, upgrade, upgradename, sizeof(upgradename));
                        PrintToChat(client, "%c[SourceCraft] %c\"%s\" is now level %d.",
                                    COLOR_GREEN,COLOR_DEFAULT,upgradename,
                                    GetUpgradeLevel(playerHandle,race,upgrade));
                    }

                    if (GetUpgradeLevelCount(playerHandle,race)<GetLevel(playerHandle,race))
                        UpgradeMenu(client,playerHandle);
                    else if (DBIDB && SAVE_ENABLED)
                        SavePlayerData(client,playerHandle,false);
                }
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShopMenu(client, bool:shopmenu)
{
    new shopItemCount = GetArraySize(shopVector);
    if (shopItemCount >= 1)
    {
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            new credits=GetCredits(playerHandle);
            new Handle:shopMenu=CreateMenu(ShopMenu_Selected);
            SetMenuExitButton(shopMenu,true);

            if (shopmenu)
                SetMenuTitle(shopMenu,"[SourceCraft] Select an item to look at. - You have %d %s",credits,(credits == 1) ? "crystal" : "crystals");
            else
                SetMenuTitle(shopMenu,"[SourceCraft] Here is a list of the items you currently have. - You have %d %s",credits,(credits == 1) ? "crystal" : "crystals");

            new Handle:itemHandle;
            decl String:itemname[64];
            decl String:itembuf[11];
            decl String:linestr[96];
            decl cost;

            new count = 0;
            for(new x=0;x<shopItemCount;x++)
            {
                if (shopmenu || GetOwnsItem(playerHandle,x))
                {
                    count++;
                    Format(itembuf,sizeof(itembuf),"%d",x);
                    itemHandle=GetShopItemHandle(x);
                    GetItemName(itemHandle, itemname, sizeof(itemname));
                    if (shopmenu)
                    {
                        cost = GetItemCost(itemHandle);
                        Format(linestr,sizeof(linestr),"%s - %d crystals",itemname,cost);
                        AddMenuItem(shopMenu,itembuf,linestr);
                    }
                    else
                        AddMenuItem(shopMenu,itembuf,itemname);
                }
            }

            if (count)
            {
                gShopMenuMode[client] = shopmenu;
                DisplayMenu(shopMenu,client,MENU_TIME_FOREVER);
            }
            else
                ShowItems(client,client,playerHandle);
        }
        else
        {
            PrintToChat(client, "%c[SourceCraft] %cThere are no items in the shopmenu!",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
}

public ShopMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
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
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public ShopMenu_Item(client,Handle:playerHandle,item)
{
    new credits=GetCredits(playerHandle);
    new Handle:shopMenu_Item=CreateMenu(ShopMenu_Item_Select);
    SetMenuExitButton(shopMenu_Item,true);
    SetMenuExitBackButton(shopMenu_Item,true);
    new Handle:itemHandle=GetShopItemHandle(item);
    decl String:itemname[64];
    GetItemName(itemHandle, itemname, sizeof(itemname));
    decl String:desc[300];
    GetItemDescription(itemHandle, desc, sizeof(desc));
    Format(desc,sizeof(desc),"Description: %s",desc);
    new cost = GetItemCost(itemHandle);
    SetMenuTitle(shopMenu_Item,"[SourceCraft] Shop Item - %s - You have %d %s\n%s\nCost: %d crystals",
                 itemname,credits,(credits == 1) ? "crystal" : "crystals",desc,cost);
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
        new Handle:playerHandle=GetPlayerHandle(client);
        if (playerHandle != INVALID_HANDLE)
        {
            EmitSoundToClient(client,buttonWav);
            if(selection==0)
            {
                new SelectionStyle;
                decl String:SelectionInfo[11];
                decl String:SelectionDispText[256];
                GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                            SelectionStyle, SelectionDispText,sizeof(SelectionDispText));

                PurchaseShopItem(client, playerHandle, StringToInt(SelectionInfo));
            }
            else if(selection==1)
                ShopMenu(client,gShopMenuMode[client]);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            EmitSoundToClient(client,buttonWav);
            ShopMenu(client,gShopMenuMode[client]);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShowItems(client,target,Handle:playerHandle)
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
            itemHandle=GetShopItemHandle(x);
            GetItemName(itemHandle, itemname, sizeof(itemname));
            DrawPanelText(panel,itemname);
        }
    }
    DrawPanelText(panel,"-----------------------------");
    DrawPanelItem(panel,"Close");

    gShowItemsTarget[client]=target;
    SendPanelToClient(panel,client,ShowItems_Selected,0);
    CloseHandle(panel);
}

public ShowItems_Selected(Handle:menu,MenuAction:action,client,selection)
{
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
        EmitSoundToClient(client,buttonWav);
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

Admin_Player(client,target)
{
    new Handle:adminMenu_Player=CreateMenu(Admin_Player_Select);
    SetMenuExitButton(adminMenu_Player,true);
    SetMenuExitBackButton(adminMenu_Player,true);

    new race_style = (GetRaceCount() >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    new shop_style = (GetArraySize(shopVector) >= 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    SetMenuTitle(adminMenu_Player,"[SourceCraft] Administration options for %N.", target);
    decl String:buf[11];
    Format(buf,sizeof(buf),"%d",target);
    AddMenuItem(adminMenu_Player,buf,"View detailed information");
    AddMenuItem(adminMenu_Player,buf,"Reset upgrades", race_style);
    AddMenuItem(adminMenu_Player,buf,"Set race", race_style);
    AddMenuItem(adminMenu_Player,buf,"Give shop item", shop_style);
    AddMenuItem(adminMenu_Player,buf,"Increase/Decrease XP", race_style);
    AddMenuItem(adminMenu_Player,buf,"Increase/Decrease Level", race_style);
    AddMenuItem(adminMenu_Player,buf,"Increase/Decrease Crystals");
    DisplayMenu(adminMenu_Player,client,MENU_TIME_FOREVER);
}

public Admin_Player_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        EmitSoundToClient(client,buttonWav);
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
                    // Reset upgrades
                    new race=GetRace(targetHandle);
                    new upgradeCount=GetUpgradeCount(GetRaceHandle(race));
                    for(new y=0;y<upgradeCount;y++)
                            SetUpgradeLevel(targetHandle,race,y,0);

                    if(GetUpgradeLevelCount(targetHandle,race)<GetLevel(targetHandle,race))
                        UpgradeMenu(target, targetHandle);

                    PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" reset your upgrades.",
                                COLOR_GREEN,COLOR_DEFAULT,client);

                    PrintToChat(client, "%c[SourceCraft] %cYou reset player \"%N\" upgrades.",
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
            EmitSoundToClient(client,buttonWav);
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
        new Handle:playerInfo=CreateMenu(Admin_PI_Select);
        SetMenuExitButton(playerInfo,true);
        SetMenuExitBackButton(playerInfo,true);

        new race=GetRace(targetHandle);
        new xp=GetXP(targetHandle,race);
        new level=GetLevel(targetHandle,race);
        new credits=GetCredits(targetHandle);

        decl String:raceName[64];
        GetRaceName(GetRaceHandle(race), raceName, sizeof(raceName));

        SetMenuTitle(playerInfo,"[SourceCraft] Info for %N.\nRace: %s\nCrystals: %d\nXP: %d\nLevel: %d",
                     target,raceName,credits,xp,level);

        decl String:buf[11];
        Format(buf,sizeof(buf),"%d",target);
        AddMenuItem(playerInfo,buf,"View Player's upgrade levels");
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
        EmitSoundToClient(client,buttonWav);
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
                case 0: // upgrade levels
                    ShowUpgrades(client,target,targetHandle);
                case 1: // shop items
                    ShowItems(client,target,targetHandle);
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
    EmitSoundToClient(client,buttonWav);
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

Admin_XP(client,target)
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
        EmitSoundToClient(client,buttonWav);
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

Admin_GiveShopItem(client,target)
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
            itemHandle=GetShopItemHandle(x);
            GetItemName(itemHandle, itemname, sizeof(itemname));
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
        EmitSoundToClient(client,buttonWav);
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
                new Handle:itemHandle=GetShopItemHandle(item);
                decl String:itemname[64];
                GetItemName(itemHandle, itemname, sizeof(itemname));

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

Admin_SetRace(client,target)
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
        new raceCount = GetRaceCount();
        for(new race=0;race<raceCount;race++)
        {
            GetRaceName(GetRaceHandle(race),racename,sizeof(racename));
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
        EmitSoundToClient(client,buttonWav);
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
            GetRaceName(GetRaceHandle(selection),racename,sizeof(racename));

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

Admin_Level(client,target)
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
        EmitSoundToClient(client,buttonWav);
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
                    UpgradeMenu(target, targetHandle);

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
                    new upgradeCount=GetUpgradeCount(GetRaceHandle(race));
                    for(new x=0;x<upgradeCount;x++)
                        SetUpgradeLevel(targetHandle,race,x,0);

                    PrintToChat(client, "%c[SourceCraft] %cYou removed a level from player \"%N\".",
                                COLOR_GREEN,COLOR_DEFAULT,target);

                    PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" removed a level from you, re-pick your upgrades.",
                                COLOR_GREEN,COLOR_DEFAULT,client);

                    if(newlevel>0)
                        UpgradeMenu(target, targetHandle);
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

Admin_Credits(client,target)
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

        AddMenuItem(menu,buf,"Give 1 crystal");
        AddMenuItem(menu,buf,"Give 5 crystals");
        AddMenuItem(menu,buf,"Give 10 crystals");
        AddMenuItem(menu,buf,"Remove 1 crystal");
        AddMenuItem(menu,buf,"Remove 5 crystals");
        AddMenuItem(menu,buf,"Remove 10 crystals");

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
        EmitSoundToClient(client,buttonWav);
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
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

                PrintToChat(client, "%c[SourceCraft] %cYou gave \"%N\" %d crystals.",
                            COLOR_GREEN,COLOR_DEFAULT,target,credadd);

                PrintToChat(target, "%c[SourceCraft] %cYou recieved %d crystals from admin \"%N\".",
                            COLOR_GREEN,COLOR_DEFAULT,credadd,client);

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

                PrintToChat(client, "%c[SourceCraft] %cYou removed %d crystals from player \"%N\".",
                            COLOR_GREEN,COLOR_DEFAULT,credrem,target);

                PrintToChat(target, "%c[SourceCraft] %cAdmin \"%N\" removed %d crystals from you.",
                            COLOR_GREEN,COLOR_DEFAULT,client,credrem);

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
