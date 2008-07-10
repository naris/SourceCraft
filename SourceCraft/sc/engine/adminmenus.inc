/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: adminmenus.inc
 * Description: This file handles the admin menu.
 * Author(s): Naris (Murray Wilson)
 */

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

new Handle:hTopAdminMenu = INVALID_HANDLE;

InitAdminMenu()
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

                    if(GetUpgradeLevelCount(targetHandle, race) < GetLevel(targetHandle,race))
                        UpgradeMenu(target, targetHandle, false);

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
        decl String:raceName[64];
        new Handle:playerInfo=CreateMenu(Admin_PI_Select);
        SetMenuExitButton(playerInfo,true);
        SetMenuExitBackButton(playerInfo,true);

        new race=GetRace(targetHandle);
        new xp=GetXP(targetHandle,race);
        new level=GetLevel(targetHandle,race);
        new credits=GetCredits(targetHandle);

        if (race >= 0)
            GetRaceName(GetRaceHandle(race), raceName, sizeof(raceName));
        else
            strcopy(raceName, sizeof(raceName), "none");

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
        decl String:racename[64];
        new raceCount = GetRaceCount();
        for(new race=0;race<raceCount;race++)
        {
            GetRaceName(GetRaceHandle(race),racename,sizeof(racename));
            if (racename[0])
            {
                Format(buf,sizeof(buf),"%d,%d",target,race);
                AddMenuItem(menu,buf,racename);
            }
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
        decl String:SelectionData[2][5];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),
                    SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        ExplodeString(SelectionInfo,",",SelectionData, 2, 5);
        new target=StringToInt(SelectionData[0]);
        new Handle:targetHandle=GetPlayerHandle(target);
        if (targetHandle != INVALID_HANDLE)
        {
            new race=StringToInt(SelectionData[1]);
            SetRace(targetHandle,race);
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
                    UpgradeMenu(target, targetHandle, false);

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
                        UpgradeMenu(target, targetHandle, false);
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
