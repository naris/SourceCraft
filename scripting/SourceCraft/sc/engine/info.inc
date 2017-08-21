/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: info.inc
 * Description: Display information about a player
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _info_included
 #endinput
#endif
#define _info_included

#include "sc/engine/menumode"

new MenuMode:gPlayerInfoMenuMode[MAXPLAYERS+1];
new MenuMode:gUpgradesMenuMode[MAXPLAYERS+1];
new gUpgradesInfoTarget[MAXPLAYERS+1];
new gRaceForUpgrades[MAXPLAYERS+1];

PlayerInfoMenu(client,MenuMode:mode)
{
    if (IsValidClient(client) && !IsFakeClient(client))
    {
        new Handle:playerMenu=CreateMenu(View_Selected);
        SetMenuTitle(playerMenu,"[SC] %T", "ViewPlayer", client);
        SetMenuExitButton(playerMenu,true);

        if (mode & EnableMenuExitBack)
            SetMenuExitBackButton(playerMenu,true);

        //AddTargetsToMenu(playerMenu, client, true, false);
        AddTargetsToMenu2(playerMenu, client, COMMAND_FILTER_NO_IMMUNITY);
        gPlayerInfoMenuMode[client] = mode|InfoMode;
        DisplayMenu(playerMenu,client,MENU_TIME_FOREVER);
    }
}

public View_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        new userid, target;
        decl String:SelectionInfo[SMALL_STRING_LENGTH];
        PrepareAndEmitSoundToClient(client,buttonWav);
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
        userid=StringToInt(SelectionInfo);
        if ((target = GetClientOfUserId(userid)) == 0)
            CPrintToChat(client, "{green}[SC]{default} %t", "NoPlayer");
        else
            PlayerInfo(client,target,gPlayerInfoMenuMode[client]);
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
            PlayerInfoMenu(client,gPlayerInfoMenuMode[client]);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public PlayerInfo(client,target,MenuMode:mode)
{
    if (IsValidClient(client) && !IsFakeClient(client) &&
        IsValidClient(target))
    {
        decl String:title[LONG_STRING_LENGTH];
        new race = GetRace(target);
        if (race >= 0)
        {
            new Handle:raceHandle=GetRaceHandle(race);

            decl String:raceName[NAME_STRING_LENGTH];
            GetRaceName(raceHandle, raceName, sizeof(raceName));

            new Faction:techId = GetRaceFactionId(raceHandle);
            new UnitType:typeId = GetRaceType(raceHandle);
            if (techId > Generic)
            {
                decl String:techName[NAME_STRING_LENGTH];
                GetFactionName(techId, techName, sizeof(techName));

                decl String:unitType[NAME_STRING_LENGTH];
                GetUnitTypeName(typeId, unitType, sizeof(unitType));
                Format(title,sizeof(title),"%s: %s {%s}",
                       techName, raceName, unitType);

                new len=strlen(title);
                Format(title[len], sizeof(title)-len,"\n%T", "PlayerTechLevel", client,
                       techName, GetTechLevel(target,techId));
            }
            else if (typeId > GenericUnit)
            {
                decl String:unit[NAME_STRING_LENGTH];
                GetUnitTypeName(typeId, unit, sizeof(unit));
                Format(title,sizeof(title),"%s {%s}",
                       raceName, unit);
            }
            else
            {
                strcopy(title, sizeof(title), raceName);
            }

            new len      = strlen(title);
            new level    = GetLevel(target,race);
            new maxLevel = GetRaceMaxLevel(raceHandle);
            Format(title[len], sizeof(title)-len, "\n%T", "PlayerLevel", client,
                   level, maxLevel, GetOverallLevel(target));

            if (level<maxLevel)
            {
                len = strlen(title);
                Format(title[len], sizeof(title)-len, "\n%T", "PlayerExperience",
                       client, GetXP(target,race), ReqLevelXP(level+1));
            }
            else
            {
                len = strlen(title);
                Format(title[len], sizeof(title)-len, "\n%T", "PlayerExperienceMaxed",
                       client, GetXP(target,race));
            }

            len = strlen(title);
            Format(title[len], sizeof(title)-len, "\n%T", "PlayerAccumulatedEnergy",
                   client, GetEnergy(target), GetAccumulatedEnergy(target,race));
        }
        else
        {
            Format(title, sizeof(title), "\n%T", "PlayerEnergy",
                   client, GetEnergy(target));
        }

        new len = strlen(title);
        Format(title[len], sizeof(title)-len, "\n%T", "PlayerCrystals",
               client, GetCrystals(target));

        len = strlen(title);
        Format(title[len], sizeof(title)-len, "\n%T", "PlayerVespene",
               client, GetVespene(target));

        new Handle:playerInfo=CreateMenu(PlayerInfo_Select);
        SetMenuTitle(playerInfo, "[SC] %T", "PlayerInfo", client,
                     IsFakeClient(target) ? "[BOT] " : "",
                     target, title);

        SetMenuExitButton(playerInfo,true);

        if (mode & EnableMenuExitBack)
            SetMenuExitBackButton(playerInfo,true);

        decl String:buf[SMALL_STRING_LENGTH];
        Format(buf,sizeof(buf),"%d",target);

        if (client == target)
        {
            if (race > 0)
                AddMenuItemT(playerInfo,buf,"ViewUpgradeLevels", client);

            AddMenuItemT(playerInfo,buf,"ViewShopItems", client);
        }
        else
        {
            if (race > 0)
                AddMenuItemT(playerInfo,buf,"ViewPlayersUpgradeLevels", client);

            if (mode & AdminMode)
                AddMenuItemT(playerInfo,buf,"ViewPlayersShopItems", client);
        }

        AddMenuItem(playerInfo,"","",ITEMDRAW_SPACER);
        AddMenuItemT(playerInfo,buf,"BackToOptions", client);

        gPlayerInfoMenuMode[client] = mode;
        DisplayMenu(playerInfo,client,MENU_TIME_FOREVER);
    }
    else
    {
        CPrintToChat(client, "{green}[SC]{default} %t", "NoPlayer");

        if (mode & FromAdminMenu)
            AdminMenu(client,0);
        else if (mode & FromPlayerInfoMenu)
            PlayerInfoMenu(client,gPlayerInfoMenuMode[client]);
        else if (mode & FromMainMenu)
            MainMenu(client);
    }
}

public PlayerInfo_Select(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:SelectionInfo[SMALL_STRING_LENGTH];
        PrepareAndEmitSoundToClient(client,buttonWav);
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
        new target=StringToInt(SelectionInfo);
        if (IsValidClient(target))
        {
            if (target == client || (gPlayerInfoMenuMode[client] & AdminMode))
            {
                switch(selection)
                {
                    case 0: // upgrade levels
                    {
                        UpgradesInfo(client,target,GetRace(target),
                                     gPlayerInfoMenuMode[client]|FromPlayerInfo);
                    }
                    case 1: // shop items
                    {
                        ShopMenu(client,target,
                                 gPlayerInfoMenuMode[client]|InfoMode|FromPlayerInfo);
                    }
                    default:
                    {
                        new MenuMode:mode = gPlayerInfoMenuMode[client];
                        if (mode & FromAdminMenu)
                            Admin_Player(client,target);
                        else if (mode & FromMainMenu)
                            MainMenu(client);
                    }
                }
            }
            else // Only option (for other players) is Upgrade Info for non-admins
            {
                new race = GetRace(target);
                if (race > 0)
                {
                    UpgradesInfo(client, target, race,
                                 gPlayerInfoMenuMode[client]|FromPlayerInfo);
                }
            }
        }
        else
        {
            CPrintToChat(client, "{green}[SC]{default} %t", "NoPlayer");

            new MenuMode:mode = gPlayerInfoMenuMode[client];
            if (mode & FromAdminMenu)
                AdminMenu(client,0);
            else if (mode & FromMainMenu)
                MainMenu(client);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            new MenuMode:mode = gPlayerInfoMenuMode[client];
            if (mode & FromAdminMenu)
                Admin_Return(menu,client);
            else if (mode & FromMainMenu)
                MainMenu(client);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

UpgradesInfo(client,target,race,MenuMode:mode)
{
    TraceInto("Info", "UpgradesInfo", "client=%d:%N, target=%d, race=%d, mode=%d", \
              client, client, target, race, mode);

    if (IsValidClient(client) && !IsFakeClient(client) &&
        (client == target || IsValidClient(target)))
    {
        decl String:item[ITEM_STRING_LENGTH];
        decl String:buf[SMALL_STRING_LENGTH];

        new Handle:menu=CreateMenu(UpgradesInfo_Selected);
        SetMenuExitButton(menu,true);

        if (mode & EnableMenuExitBack)
            SetMenuExitBackButton(menu,true);

        new Handle:raceHandle=GetRaceHandle(race);

        decl String:raceName[NAME_STRING_LENGTH];
        GetRaceName(raceHandle, raceName, sizeof(raceName));

        if (client == target)
        {
            decl String:short[SHORT_STRING_LENGTH];
            GetRaceShortName(raceHandle, short, sizeof(short));

            decl String:unitType[NAME_STRING_LENGTH];
            GetUnitTypeName(GetRaceType(raceHandle), unitType,
                            sizeof(unitType), client);

            decl String:factionName[NAME_STRING_LENGTH];
            GetFactionName(GetRaceFaction(raceHandle), factionName,
                           sizeof(factionName), client);

            SetMenuTitle(menu,"[SC] %T", "RaceInfo", client, raceName, short,
                         GetRaceMaxLevel(raceHandle), factionName, unitType);
        }
        else
        {
            SetMenuTitle(menu,"[SC] %T", "RaceInfoFor", client, raceName,
                         IsFakeClient(target) ? "[BOT] " : "", target);
        }

        if (mode & ChangeRaceMode)
        {
            AddMenuItemT(menu,"-1","ChangeToRace",client);
            AddMenuItem(menu,"","",ITEMDRAW_SPACER);
        }

        new maxLevel = GetRaceMaxLevel(raceHandle);
        new upgradeCount = GetUpgradeCount(raceHandle);
        for(new upgrade=0;upgrade<upgradeCount;upgrade++)
        {
            new upgradeCategory = GetUpgradeCategory(raceHandle, upgrade);
            if (upgradeCategory > 1)
            {
                Format(item, sizeof(item), "%T:", "UltimateN",
                       client, upgradeCategory);
            }
            else if (upgradeCategory == 1)
                Format(item, sizeof(item), "%T:", "Ultimate", client);
            else
                item[0] = 0;

            decl String:upgradeName[NAME_STRING_LENGTH];
            GetUpgradeName(raceHandle, upgrade, upgradeName, sizeof(upgradeName), client);
            StrCat(item, sizeof(item), upgradeName);

            new maxUpgradeLevel = GetUpgradeMaxLevel(raceHandle,upgrade);
            new requiredLevel   = GetUpgradeRequiredLevel(raceHandle,upgrade);
            new bool:disabled   = GetUpgradeDisabled(raceHandle,upgrade);
            if (requiredLevel < 1 && !disabled)
            {
                new len=strlen(item);
                Format(item[len], sizeof(item)-len," [%T]", "AlwaysAvailable", client);
            }
            else if (disabled || requiredLevel > maxLevel || maxUpgradeLevel <= 0)
            {
                new len=strlen(item);
                Format(item[len], sizeof(item)-len," [%T]", "NotAvailable", client);
            }
            else if (requiredLevel > 1)
            {
                new len=strlen(item);
                Format(item[len], sizeof(item)-len," [%T]", "MinimumLevel", client, requiredLevel);
            }

            new upgradeLevel;
            if (mode & (InfoMode|QueryMode))
            {
                upgradeLevel=GetUpgradeLevel(target,race,upgrade);
                if (upgradeLevel > 0)
                {
                    new len=strlen(item);
                    Format(item[len], sizeof(item)-len," (%T)", "IsLevel", client, upgradeLevel);
                }
            }
            else
                upgradeLevel = 0;

            if ((mode & QueryMode) == NoMode || upgradeLevel > 0 ||
                requiredLevel < 1 || upgradeCount < 8)
            {
                Format(buf,sizeof(buf),"%d",upgrade);
                AddMenuItem(menu,buf,item);
            }
        }

        gRaceForUpgrades[client] = race;
        gUpgradesMenuMode[client] = mode;
        gUpgradesInfoTarget[client]=target;
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }

    TraceReturn();
}

public UpgradesInfo_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action==MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(client,buttonWav);
        new target = gUpgradesInfoTarget[client];
        if (IsValidClient(target))
        {
            decl String:SelectionInfo[SMALL_STRING_LENGTH];
            PrepareAndEmitSoundToClient(client,buttonWav);
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
            if (SelectionInfo[0])
            {
                new race=gRaceForUpgrades[client];
                new Handle:raceHandle=GetRaceHandle(race);
                new upgrade=StringToInt(SelectionInfo);
                if (upgrade < 0) // They decided to change to this race.
                {
                    ChangeRace(target, race, raceHandle, false, true, false);
                    if (gUpgradesMenuMode[client] & FromMainMenu)
                        MainMenu(client);
                }
                else
                {
                    UpgradesInfo_Upgrade(client,race,raceHandle,upgrade,gUpgradesMenuMode[client]);
                }
            }
        }
        else if (target != client)
        {
            CPrintToChat(client, "{green}[SC]{default} %t", "NoPlayer");
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            new MenuMode:mode = gUpgradesMenuMode[client];
            if (mode & FromPlayerInfo)
                PlayerInfo(client,gUpgradesInfoTarget[client], mode);
            else if (mode & FromAdminMenu)
                AdminMenu(client,gUpgradesInfoTarget[client]);
            else if (mode & FromFactionMenu)
                FactionMenu(client);
            else if (mode & FromRaceMenu)
                RaceMenu(client,mode);
            else if (mode & FromMainMenu)
                MainMenu(client);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

UpgradesInfo_Upgrade(client, race, Handle:raceHandle, upgrade, MenuMode:mode)
{
    TraceInto("Info", "UpgradesInfo_Upgrade", "client=%d:%N, raceHandle=0x%08x, upgrade=%d, mode=%d", \
              client, client, raceHandle, upgrade, mode);

    new category = GetUpgradeCategory(raceHandle, upgrade);
    new MenuMode:isUpgradeMode = (mode & UpgradeMode);

    decl String:name[NAME_STRING_LENGTH];
    decl String:desc[DESCRIPTION_LENGTH];
    decl String:bind[DESCRIPTION_LENGTH];
    decl String:item[DESCRIPTION_LENGTH];
    GetUpgradeNameAndDesc(raceHandle, upgrade, name, sizeof(name), desc, sizeof(desc), bind, sizeof(bind), client);
    Trace("GetUpgradeNameAndDesc:name=%s,desc=%s,bind=%s",name,desc,bind);

    new Handle:menu = CreateMenu(UpgradesInfo_Back);
    SetMenuExitButton(menu,true);
    SetMenuExitBackButton(menu,true);

    SetMenuTitle(menu, "[SC] %T", "UpgradeInfo", client, name);
    AddMenuItem(menu, "", desc, ITEMDRAW_DISABLED);

    if (isUpgradeMode)
    {
        decl String:sbuf[SMALL_STRING_LENGTH];
        Format(sbuf,sizeof(sbuf),"%d",upgrade);
        AddMenuItemT(menu, sbuf, "SelectUpgrade", client);
        AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
    }

    if (GetUpgradeRequiredLevel(raceHandle,upgrade) == 0)
    {
        Format(item, sizeof(item), "%T", "AlwaysAvailable", client);
        AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
    }

    new Float:energy = GetUpgradeEnergy(raceHandle, upgrade);
    new Float:recurring_energy = GetUpgradeRecurringEnergy(raceHandle, upgrade);
    if (recurring_energy > 0.0)
    {
        if (energy > 0.0)
        {
            // TODO: Make configurable (add recurring energy time factor attribute to upgrade)
            Format(item, sizeof(item), "%T", "UsesEnergyPerSecond", client, energy, 1.0); // recurring_energy);
            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }
        else
        {
            Format(item, sizeof(item), "%T", "UsesEnergyPerUse", client, recurring_energy);
            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }
    }
    else if (energy > 0.0)
    {
        Format(item, sizeof(item), "%T", "UsesEnergy", client, energy);
        AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
    }

    new crystals = GetUpgradeCrystals(raceHandle, upgrade);
    if (crystals > 0)
    {
        Format(item, sizeof(item), "%T", "CostsCrystalsPerUse", client, crystals);
        AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
    }

    new vespene = GetUpgradeVespene(raceHandle, upgrade);
    if (vespene > 0)
    {
        Format(item, sizeof(item), "%T", "CostsVespenePerUse", client, vespene);
        AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
    }

    if (g_bChargeForUpgrades)
    {
        new crystal_cost = GetUpgradeCostCrystals(raceHandle, upgrade);
        if (crystal_cost < 0)
        {
            crystal_cost = g_iUpgradeCrystalsCost;
        }
        
        if (crystal_cost > 0)
        {
            Format(item, sizeof(item), "%T", "CostsCrystalsToUpgrade", client, crystal_cost);
            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }

        new vespene_cost = GetUpgradeCostVespene(raceHandle, upgrade);
        if (vespene_cost < 0)
        {
            vespene_cost = g_iUpgradeVespeneCost;
        }
        
        if (vespene_cost > 0)
        {
            Format(item, sizeof(item), "%T", "CostsVespeneToUpgrade", client, vespene_cost);
            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }
    }

    if (bind[0] != '\0')
    {
        AddMenuItem(menu, "", bind, ITEMDRAW_DISABLED);
    }

    if (category == 1)
    {
        if (!StrContains(bind, "+ultimate") && !StrContains(desc, "+ultimate"))
        {
            Format(item, sizeof(item), "%T", "InvokedWithUltimate", client, category);
            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }

        if (!StrContains(bind, "console") && !StrContains(desc, "console"))
        {
            Format(item, sizeof(item), "%T", "BindUltimate", client, category, "f");
            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }
    }
    else if (category > 1)
    {
        if (!StrContains(bind, "+ultimate") && !StrContains(desc, "+ultimate"))
        {
            Format(item, sizeof(item), "%T", "InvokedWithUltimateN", client, category);
            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }
        
        if (!StrContains(bind, "console") && !StrContains(desc, "console"))
        {
            new String:bindKey[][] = { "", "f", "b", "n", "p", "x" };
            Format(item, sizeof(item), "%T", "BindUltimateN", client, category,
                    (category >= 1 && category < sizeof(bindKey)) ? bindKey[category] : "x");

            AddMenuItem(menu, "", item, ITEMDRAW_DISABLED);
        }
    }

    AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
    AddMenuItemT(menu, "-1", "BackToUpgrades", client);
    
    gRaceForUpgrades[client] = race;
    gUpgradesMenuMode[client] = mode;
    gUpgradesInfoTarget[client]=client;
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
    TraceReturn();
}

public UpgradesInfo_Back(Handle:menu,MenuAction:action,client,selection)
{
    TraceInto("Menus", "UpgradesInfo_Back", "client=%d, menu=%d, action=%d, selection=%d", \
              client, menu, action, selection);

    if (action == MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(client,buttonWav);
        if (IsValidClient(client))
        {
            //if (gUpgradesMenuMode[client] & FromUpgradeMenu)
            decl String:SelectionInfo[SMALL_STRING_LENGTH];
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
            new upgrade=StringToInt(SelectionInfo);
            
            new race = gRaceForUpgrades[client];
            new Handle:raceHandle=GetRaceHandle(race);
            new upgradeCount=GetUpgradeCount(raceHandle);
            if (upgrade >= 0 && upgrade < upgradeCount)
            {
                SelectUpgrade(client, race, upgrade, raceHandle);
            }
            else
            {
                UpgradesInfo(client,gUpgradesInfoTarget[client],
                             gRaceForUpgrades[client],
                             gUpgradesMenuMode[client]);
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (selection == MenuCancel_ExitBack)
        {
            PrepareAndEmitSoundToClient(client,buttonWav);
            if (gUpgradesMenuMode[client] & FromUpgradeMenu)
            {
                UpgradeMenu(client, gUpgradesMenuMode[client], true);
            }
            else
            {
                UpgradesInfo(client,gUpgradesInfoTarget[client],
                             gRaceForUpgrades[client],
                             gUpgradesMenuMode[client]);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }

    TraceReturn();
}
