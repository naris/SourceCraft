/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: menus.inc
 * Description: This file handles most of the menus.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

new bool:gShopMenuMode[MAXPLAYERS+1];
new bool:gRaceMenuMode[MAXPLAYERS+1];
new gShowItemsTarget[MAXPLAYERS+1];

new Handle:g_IntroMenu   = INVALID_HANDLE;
new Handle:g_MainMenu    = INVALID_HANDLE;

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
       (action == MenuAction_Cancel
        && (param == MenuCancel_Timeout ||
            param == MenuCancel_Exit)))
    {
        if (m_FirstSpawn[client] > 1 && GetRaceCount() >= 1)
            RaceMenu(client, true, false);

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
        AddMenuItem(g_MainMenu,"8","Change Settings");
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
                ShopMenu(client,true,true);
            case 1: // changerace
                RaceMenu(client,true, true);
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
                    UpgradeMenu(client, playerHandle, true);
                else
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou don't have any upgrade points to spend, if you want to reset your upgrades use resetupgrades.", COLOR_GREEN,COLOR_DEFAULT);
                    MainMenu(client);
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
                ShopMenu(client,false,true);
            case 7: // help
                Help(client);
            case 8: // settings
                ChangeSettings(client,true);
        }
    }
}

RaceMenu(client,bool:change, bool:fromMain)
{
    if (GetRaceCount() >= 1)
    {
        new Handle:crMenu=CreateMenu(RaceMenu_Selected);

        if (change)
            SetMenuTitle(crMenu, "[SourceCraft] Select your desired race.\n");
        else
            SetMenuTitle(crMenu, "[SourceCraft] Select a race to view.");

        SetMenuExitButton(crMenu,true);
        if (fromMain)
            SetMenuExitBackButton(crMenu,true);

        // Iterate through the races and print them out
        new Handle:raceHandle;
        decl String:rbuf[11];
        decl String:name[64];
        decl String:item[256];
        new bool:disable, reqLevel, level, style;
        new raceCount = GetRaceCount();
        for(new race=0;race<raceCount;race++)
        {
            raceHandle=GetRaceHandle(race);
            reqLevel = GetRaceRequiredLevel(raceHandle);
            if (reqLevel == 0)
            {
                style = ITEMDRAW_DEFAULT;
                GetRaceName(raceHandle,item,sizeof(item));
            }
            else
            {
                level = GetOverallLevel(GetPlayerHandle(client));
                disable = (level < reqLevel || reqLevel < 0);
                style = (change && disable) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
                if (disable || !change)
                {
                    GetRaceName(raceHandle,name,sizeof(name));
                    if (name[0] != 0)
                    {
                        if (reqLevel > 0)
                        {
                            Format(item,sizeof(item),"%s (overall level must be >= %d)",
                                   name, reqLevel);
                        }
                        else
                            Format(item,sizeof(item),"%s (locked)", name);
                    }
                    else
                        item[0] = 0;
                }
                else
                    GetRaceName(raceHandle,item,sizeof(item));
            }

            if (item[0] != 0)
            {
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

                Format(rbuf,sizeof(rbuf),"%d",race);
                AddMenuItem(crMenu,rbuf,item,style);
            }
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
        decl String:SelectionInfo[11];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle,
                    SelectionDispText,sizeof(SelectionDispText));
        if (SelectionInfo[0])
        {
            EmitSoundToClient(client,buttonWav);
            UpgradesInfo(client,StringToInt(SelectionInfo),gRaceMenuMode[client]);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            EmitSoundToClient(client,buttonWav);
            MainMenu(client);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

UpgradeMenu(client, Handle:playerHandle, bool:fromMain)
{
    if (GetRaceCount() >= 1)
    {
        new Handle:sMenu=CreateMenu(UpgradeMenu_Selected);
        new race=GetRace(playerHandle);
        new Handle:raceHandle=GetRaceHandle(race);
        new upgradecount=GetUpgradeLevelCount(playerHandle,race);
        new level=GetLevel(playerHandle,race);
        SetMenuTitle(sMenu,"[SourceCraft] Select your desired upgrade. (%d/%d)",upgradecount,level);

        SetMenuExitButton(sMenu,true);
        if (fromMain)
            SetMenuExitBackButton(sMenu,true);

        new upgradeLevel, maxUpgradeLevel, requiredLevel, style;
        decl String:sbuf[11];
        decl String:buf[192];
        decl String:minLevel[64];
        decl String:toLevel[64];
        decl String:upgradename[64];
        new String:ult[] = "Ultimate:";
        new maxLevel = GetRaceMaxLevel(raceHandle);
        new raceLevel = GetLevel(playerHandle,race);
        new activeUltimate = GetActiveUltimate(playerHandle,race);
        new upgradeCount = GetUpgradeCount(raceHandle);
        for(new upgrade=0;upgrade<upgradeCount;upgrade++)
        {
            upgradeLevel=GetUpgradeLevel(playerHandle,race,upgrade);
            requiredLevel=GetUpgradeRequiredLevel(raceHandle,upgrade);
            maxUpgradeLevel=GetUpgradeMaxLevel(raceHandle,upgrade);

            if (requiredLevel > maxLevel || maxUpgradeLevel <= 0)
            {
                style = ITEMDRAW_DISABLED;
                Format(minLevel,sizeof(minLevel)," [Not Available]");
            }
            else if (raceLevel < requiredLevel)
            {
                style = ITEMDRAW_DISABLED;
                Format(minLevel,sizeof(minLevel)," [Minimum Level %d]", requiredLevel);
            }
            else
            {
                minLevel[0] = 0;
                if (upgradeLevel >= maxUpgradeLevel)
                    style = ITEMDRAW_DISABLED;
                else
                    style = ITEMDRAW_DEFAULT;
            }

            if (IsUpgradeUltimate(raceHandle, upgrade))
            {
                ult[0] = 'U';
                if (activeUltimate >= 0 && activeUltimate != upgrade)
                    style = ITEMDRAW_DISABLED;
            }
            else
                ult[0] = 0;

            if (style == ITEMDRAW_DEFAULT)
                Format(toLevel,sizeof(toLevel)," (Upgrade Level %d)", upgradeLevel+1);
            else
                toLevel[0] = 0;

            GetUpgradeName(raceHandle, upgrade, upgradename, sizeof(upgradename));
            Format(buf,sizeof(buf),"%s%s%s%s",ult,upgradename,minLevel,toLevel);
            Format(sbuf,sizeof(sbuf),"%d",upgrade);
            AddMenuItem(sMenu,sbuf,buf,style);
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
                    new minLevel = GetUpgradeRequiredLevel(raceHandle,upgrade);
                    if (level >= minLevel)
                    {
                        if (IsUpgradeUltimate(raceHandle, upgrade))
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
                            IncrementUpgradeLevel(playerHandle,race,upgrade,false);
                            decl String:upgradename[64];
                            GetUpgradeName(raceHandle, upgrade, upgradename, sizeof(upgradename));
                            PrintToChat(client, "%c[SourceCraft] %c\"%s\" is now level %d.",
                                        COLOR_GREEN,COLOR_DEFAULT,upgradename,
                                        GetUpgradeLevel(playerHandle,race,upgrade));
                        }

                        if (GetUpgradeLevelCount(playerHandle,race)<GetLevel(playerHandle,race))
                            UpgradeMenu(client, playerHandle, false);
                        else if (DBIDB && SAVE_ENABLED)
                            SavePlayerData(client,playerHandle,false);
                    }
                    else
                    {
                        decl String:upgradename[64];
                        GetUpgradeName(raceHandle, upgrade, upgradename, sizeof(upgradename));
                        PrintToChat(client, "%c[SourceCraft] %cYou need to be at least level %d to choose %s.",
                                COLOR_GREEN,COLOR_DEFAULT,minLevel,upgradename);
                    }
                }
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShopMenu(client, bool:shopmenu, bool:fromMain)
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
            if (fromMain)
                SetMenuExitBackButton(shopMenu,true);

            if (shopmenu)
                SetMenuTitle(shopMenu,"[SourceCraft] Select an item to look at. - You have %d %s",credits,(credits == 1) ? "crystal" : "crystals");
            else
                SetMenuTitle(shopMenu,"[SourceCraft] Here is a list of the items you currently have. - You have %d %s",credits,(credits == 1) ? "crystal" : "crystals");

            new Handle:itemHandle;
            decl String:itemname[64];
            decl String:shortname[16];
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
                        GetItemShortName(itemHandle, shortname, sizeof(shortname));
                        Format(linestr,sizeof(linestr),"%s (%s) - %d crystals",
                               itemname,shortname,cost);
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
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            EmitSoundToClient(client,buttonWav);
            MainMenu(client);
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
                ShopMenu(client, gShopMenuMode[client], false);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            EmitSoundToClient(client,buttonWav);
            ShopMenu(client,gShopMenuMode[client],false);
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
