/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: shopitem.inc
 * Description: Defines the Shop Item Data.
 * Author(s): -=|JFH|=-Naris
 */

enum ItemInfo
{
    ItemInfo_Strings = 0,
    ItemInfo_Crystals,
    ItemInfo_Vespene,
    ItemInfo_Money,
    bool:ItemInfo_CanUsePCrystals,
    ItemInfo_XP,
    ItemInfo_Max,
    ItemInfo_RequiredLevel,
    Translation:ItemInfo_Translation,
    ItemInfo_StoreID,
    ItemInfo_ShopID,
    ItemInfo_Ident
}

enum ItemStringInfo
{
    ItemString_ShortName = 0,
    ItemString_Category,
    ItemString_Name,
    ItemString_Description,
    ItemString_TranslationFile
}

// Accessor Macros for Shop Item & Index Arrays
#define GetShopItemCount()                  GetArraySize(shopVector)
#define GetShopIndexCount()                 GetArraySize(shopIndex)

#define GetShopItemHandle(%1)               (Handle:GetArrayCell(shopVector,%1))
#define GetItemIndexHandle(%1)              (Handle:GetArrayCell(shopIndex,%1))

// Accessor Macros for Shop Item Data
#define GetShopId(%1)                       GetArrayCell(%1,_:ItemInfo_ShopID)
#define SetShopId(%1,%2)                    SetArrayCell(%1,_:ItemInfo_ShopID,%2)

#define GetShopIdent(%1)                    GetArrayCell(%1,_:ItemInfo_Ident)
#define SetShopIdent(%1,%2)                 SetArrayCell(%1,_:ItemInfo_Ident,%2)

#define GetItemCrystals(%1)                 GetArrayCell(%1,_:ItemInfo_Crystals)
#define SetItemCrystals(%1,%2)              SetArrayCell(%1,_:ItemInfo_Crystals,%2)

#define GetItemVespene(%1)                  GetArrayCell(%1,_:ItemInfo_Vespene)
#define SetItemVespene(%1,%2)               SetArrayCell(%1,_:ItemInfo_Vespene,%2)

#define GetItemCanUsePCrystals(%1)          bool:GetArrayCell(%1,_:ItemInfo_CanUsePCrystals)
#define SetItemCanUsePCrystals(%1,%2)       SetArrayCell(%1,_:ItemInfo_CanUsePCrystals,_:%2)

#define GetItemMoney(%1)                    GetArrayCell(%1,_:ItemInfo_Money)
#define SetItemMoney(%1,%2)                 SetArrayCell(%1,_:ItemInfo_Money,%2)

#define GetItemXP(%1)                       GetArrayCell(%1,_:ItemInfo_XP)
#define SetItemXP(%1,%2)                    SetArrayCell(%1,_:ItemInfo_XP,%2)

#define GetItemMax(%1)                      GetArrayCell(%1,_:ItemInfo_Max)
#define SetItemMax(%1,%2)                   SetArrayCell(%1,_:ItemInfo_Max,%2)

#define GetItemRequiredLevel(%1)            GetArrayCell(%1,_:ItemInfo_RequiredLevel)
#define SetItemRequiredLevel(%1,%2)         SetArrayCell(%1,_:ItemInfo_RequiredLevel,%2)

#define GetItemTranslation(%1)              (Translation:GetArrayCell(%1,_:ItemInfo_Translation))
#define SetItemTranslation(%1,%2)           SetArrayCell(%1,_:ItemInfo_Translation,_:%2)

#define GetItemStore(%1)                    GetArrayCell(%1,_:ItemInfo_StoreID)
#define SetItemStore(%1,%2)                 SetArrayCell(%1,_:ItemInfo_StoreID,%2)

// Accessor Macros for Shop Item Strings
#define GetItemStringHandle(%1)             GetArrayCell(%1,_:ItemInfo_Strings)

#define GetItemShortName(%1,%2,%3)          GetArrayString(GetItemStringHandle(%1),_:ItemString_ShortName,%2,%3)
#define SetItemShortName(%1,%2)             SetArrayString(GetItemStringHandle(%1),_:ItemString_ShortName,%2)

#define GetItemCategoryString(%1,%2,%3)     GetArrayString(GetItemStringHandle(%1),_:ItemString_Category,%2,%3)
#define SetItemCategoryString(%1,%2)        SetArrayString(GetItemStringHandle(%1),_:ItemString_Category,%2)

#define GetItemNameString(%1,%2,%3)         GetArrayString(GetItemStringHandle(%1),_:ItemString_Name,%2,%3)
#define SetItemName(%1,%2)                  SetArrayString(GetItemStringHandle(%1),_:ItemString_Name,%2)

#define GetItemDescriptionString(%1,%2,%3)  GetArrayString(GetItemStringHandle(%1),_:ItemString_Description,%2,%3)
#define SetItemDescription(%1,%2)           SetArrayString(GetItemStringHandle(%1),_:ItemString_Description,%2)

#define GetItemTranslationFile(%1,%2,%3)    GetArrayString(GetItemStringHandle(%1),_:ItemString_TranslationFile,%2,%3)
#define SetItemTranslationFile(%1,%2)       SetArrayString(GetItemStringHandle(%1),_:ItemString_TranslationFile,%2)

// A vector of shopmenu infomation
new Handle:shopVector = INVALID_HANDLE;
new Handle:shopIndex = INVALID_HANDLE;

new Handle:g_OnItemPurchaseExHandle = INVALID_HANDLE;
new Handle:g_OnItemPurchaseHandle = INVALID_HANDLE;
new Handle:g_OnItemLostHandle = INVALID_HANDLE;

bool:InitShopVector()
{
    SetTraceCategory("Array");
    TraceInto("ShopItems", "InitShopVector");

    if (shopVector == INVALID_HANDLE)
        shopVector = CreateArray();

    if (shopIndex == INVALID_HANDLE)
        shopIndex = CreateArray();

    TraceReturn("shopVector=0x%08x, shopIndex=0x%08x", shopVector, shopIndex);

    return (shopVector != INVALID_HANDLE &&
            shopIndex  != INVALID_HANDLE);
}

ClearShopVector()
{
    TraceInto("ShopItems", "ClearShopVector");

    if (shopVector == INVALID_HANDLE)
    {
        new itemCount = GetShopItemCount();
        for(new x=0;x<itemCount;x++)
        {
            new Handle:item=GetArrayCell(shopVector,x);
            new Handle:stringsHandle=GetArrayCell(item,_:ItemInfo_Strings);
            ClearArray(stringsHandle);
            CloseHandle(stringsHandle);

            ClearArray(item);
            CloseHandle(item);

            SetTraceCategory("Array");
            Trace("CloseArray itemStringsHandle[%d]=0x%08x", x, stringsHandle);
            Trace("CloseArray item[%d]=0x%08x", x, item);
        }
    }

    SetTraceCategory("Array");
    Trace("CloseArray shopVector=0x%08x", shopVector);
    Trace("CloseArray shopIndex=0x%08x", shopIndex);

    ClearArray(shopVector);
    CloseHandle(shopVector);
    shopVector = INVALID_HANDLE;

    ClearArray(shopIndex);
    CloseHandle(shopIndex);
    shopIndex = INVALID_HANDLE;

    TraceReturn();
}

CreateShopItem(const String:short[], crystals=0, vespene=0, money=0, bool:pcrystals=false, xp=0, max=1,
               required_level=0, storeId=0, Translation:translation=Translation_Auto, const String:translation_file[]="",
               const String:category[]="", const String:name[]="", const String:desc[]="", const String:image[]="")
{
    TraceInto("ShopItems", "CreateShopItem", "name=%s", name);

    decl String:translation_path[PLATFORM_MAX_PATH];
    if (translation_file[0] != '\0')
    {
        strcopy(translation_path, sizeof(translation_path), translation_file);
        LoadTranslations(translation_file);
        if (translation < Translation_Custom)
            translation = Translation_Custom;
    }
    else
        translation_path[0] = '\0';

    // Load shop item config, if any
    if (short[0] != '\0')
    {
        new itemLoaded;
        new bool:itemFound;
        new Handle:itemConfig = LoadItemConfig(itemLoaded);
        if (itemLoaded == CONFIG_NOT_LOADED)
        {
            KvRewind(itemConfig);
            itemFound = KvJumpToKey(itemConfig, short, false);
            if (itemFound)
            {
                required_level = KvGetNum(itemConfig,"required_level", required_level);
                crystals = KvGetNum(itemConfig,"crystals", crystals);
                vespene = KvGetNum(itemConfig,"vespene", vespene);
                money = KvGetNum(itemConfig,"money", money);
                pcrystals = bool:KvGetNum(itemConfig,"can_use_pcrystals", pcrystals);
                xp = KvGetNum(itemConfig,"xp", xp);
                max = KvGetNum(itemConfig,"max", max);
            }
            else
                SetItemConfigLoaded(CONFIG_WAS_UPDATED);
        }
        else
            itemFound = false;

        if (!itemFound)
        {
            KvRewind(itemConfig);
            if (KvJumpToKey(itemConfig, short, true))
            {
                if (required_level > 0)
                    KvSetNum(itemConfig,"required_level", required_level);

                if (crystals > 0)
                    KvSetNum(itemConfig,"crystals", crystals);

                if (vespene > 0)
                    KvSetNum(itemConfig,"vespene", vespene);

                if (money > 0)
                    KvSetNum(itemConfig,"money", money);

                if (pcrystals)
                    KvSetNum(itemConfig,"can_use_pcrystals", pcrystals);

                if (xp > 0)
                    KvSetNum(itemConfig,"xp", xp);

                if (max > 1)
                    KvSetNum(itemConfig,"max", max);

                KvGoBack(itemConfig);
            }
            else
                LogError("Unable to create shopitem %s section", short);
        }

        if (translation_file[0] == '\0')
        {
            // Check for and Load Translations, if any
            decl String:file[NAME_STRING_LENGTH];

            switch (translation)
            {
                case Translation_SC:
                {
                    // Check for SourceCraft translations
                    Format(file,sizeof(file),"sc.%s.phrases.txt",short);
                    BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                    if (FileExists(translation_path))
                        LoadTranslations(file);
                    else
                    {
                        // Check for SourceCraft translations without the prefix
                        Format(file,sizeof(file),"%s.phrases.txt",short);
                        BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                        if (FileExists(translation_path))
                            LoadTranslations(file);
                        else
                        {
                            // Use sc.shopitems.phrases.txt
                            BuildPath(Path_SM, translation_path, sizeof(translation_path),
                                      "translations/sc.shopitems.phrases.txt");
                        }
                    }
                }
                case Translation_W3S:
                {
                    // Check for War3Source translations
                    Format(file,sizeof(file),"w3s.item.%s.phrases.txt",short);
                    BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                    if (FileExists(translation_path))
                        LoadTranslations(file);
                    else
                        translation_path[0] = '\0';
                }
                case Translation_Auto, Translation_Default, Translation_Custom:
                {
                    // Check for SourceCraft translations
                    Format(file,sizeof(file),"sc.%s.phrases.txt",short);
                    BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                    if (FileExists(translation_path))
                    {
                        LoadTranslations(file);
                        translation = Translation_SC;
                    }
                    else
                    {
                        // Check for SourceCraft translations without the prefix
                        Format(file,sizeof(file),"%s.phrases.txt",short);
                        BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                        if (FileExists(translation_path))
                        {
                            LoadTranslations(file);
                            translation = Translation_SC;
                        }
                        else
                        {
                            // Check for War3Source translations
                            Format(file,sizeof(file),"w3s.item.%s.phrases.txt",short);
                            BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                            if (FileExists(translation_path))
                            {
                                LoadTranslations(file);
                                translation = Translation_W3S;
                            }
                            else
                            {
                                // Use sc.shopitems.phrases.txt
                                BuildPath(Path_SM, translation_path, sizeof(translation_path),
                                          "translations/sc.shopitems.phrases.txt");

                                if (category[0] == '\0' && name[0] == '\0' && desc[0] == '\0')
                                    translation = Translation_SC;
                            }
                        }
                    }
                }
            }
        }
    }

    new shopId = FindShopItem(short);
    if (shopId > 0)
    {
        new Handle:itemHandle=GetShopItemHandle(shopId);

        SetItemCrystals(itemHandle,crystals);
        SetItemVespene(itemHandle,vespene);
        SetItemMoney(itemHandle,money);
        SetItemCanUsePCrystals(itemHandle,pcrystals);
        SetItemXP(itemHandle,xp);
        SetItemMax(itemHandle,max);
        SetItemRequiredLevel(itemHandle,required_level);
        SetItemTranslation(itemHandle,translation);
        SetItemStore(itemHandle,storeId);

        new Handle:stringsHandle=GetItemStringHandle(itemHandle);
        SetArrayString(stringsHandle,_:ItemString_ShortName,short);
        SetArrayString(stringsHandle,_:ItemString_Category,category);
        SetArrayString(stringsHandle,_:ItemString_Name,name);
        SetArrayString(stringsHandle,_:ItemString_Description,desc);
        SetArrayString(stringsHandle,_:ItemString_TranslationFile,translation_path);
    }
    else
    {
        new Handle:stringsHandle=CreateArray(ByteCountToCells(LONG_STRING_LENGTH));
        PushArrayString(stringsHandle,short);
        PushArrayString(stringsHandle,category);
        PushArrayString(stringsHandle,name);
        PushArrayString(stringsHandle,desc);
        PushArrayString(stringsHandle,translation_path);

        new Handle:newItem=CreateArray();
        PushArrayCell(newItem,stringsHandle);
        PushArrayCell(newItem,crystals);
        PushArrayCell(newItem,vespene);
        PushArrayCell(newItem,money);
        PushArrayCell(newItem,pcrystals);
        PushArrayCell(newItem,xp);
        PushArrayCell(newItem,max);
        PushArrayCell(newItem,required_level);
        PushArrayCell(newItem,translation);
        PushArrayCell(newItem,storeId);

        // Add new Shop Item into Shop Vector.
        shopId = PushArrayCell(shopVector,newItem); // return index.
        PushArrayCell(newItem,shopId);

        SetTraceCategory("Array");
        Trace("CreateArray item[%d]=0x%08x", shopId, newItem);
        Trace("CreateArray itemStringsHandle[%d]=0x%08x", shopId, stringsHandle);

        decl String:newCategory[NAME_STRING_LENGTH];
        GetItemCategory(newItem, newCategory, sizeof(newCategory));

        decl String:newName[NAME_STRING_LENGTH];
        GetItemName(newItem, newName, sizeof(newName));

        new item=0;
        new indexCount=GetArraySize(shopIndex);
        for(;item<indexCount;item++)
        {
            new Handle:itemHandle = GetItemIndexHandle(item);
            decl String:itemCategory[NAME_STRING_LENGTH];
            GetItemCategory(itemHandle, itemCategory, sizeof(itemCategory));

            new cmpCategory = strcmp(newCategory,itemCategory,false);
            if (cmpCategory <= 0)
            {
                new itemLevel = GetItemRequiredLevel(itemHandle);
                if (itemLevel < 0)
                    itemLevel = 65535;
                if (cmpCategory <= 0 || required_level <= itemLevel)
                {
                    decl String:itemName[NAME_STRING_LENGTH];
                    GetItemName(itemHandle, itemName, sizeof(itemName));
                    if (cmpCategory < 0 || required_level < itemLevel ||
                        (cmpCategory == 0 && required_level == itemLevel &&
                         strcmp(newName,itemName,false) < 0))
                    {
                        ShiftArrayUp(shopIndex, item);
                        SetArrayCell(shopIndex, item, newItem);
                        indexCount++;
                        break;
                    }
                }
            }
        }

        if (item >= indexCount)
            PushArrayCell(shopIndex,newItem);

        // Find item_ident
        new itemIdent = LoadItemIdent(short);
        if (itemIdent < 0 || g_bCreate || g_bUpdate)
        {
            decl String:itemDesc[DESCRIPTION_LENGTH];
            GetItemDescription(newItem, itemDesc, sizeof(itemDesc));

            decl String:itemImage[NAME_STRING_LENGTH];
            GetItemImage(newItem, itemImage, sizeof(itemImage), image);

            itemIdent = InsertItem(short, newName, itemDesc, newCategory,
                                   required_level, crystals, vespene, max,
                                   itemImage);
        }

        PushArrayCell(newItem,itemIdent);
    }

    TraceReturn("shopId=%d", shopId);
    return shopId;
}

FindShopItem(const String:name[])
{
    decl String:curName[64];
    new size = GetShopItemCount();
    for(new x=0;x<size;x++)
    {
        new Handle:itemHandle=GetArrayCell(shopVector,x);
        new Handle:stringsHandle=GetArrayCell(itemHandle,_:ItemInfo_Strings);
        GetArrayString(stringsHandle,_:ItemString_ShortName,curName,sizeof(curName));
        if (StrEqual(name,curName,false))
            return x;
        else
        {
            GetArrayString(stringsHandle,_:ItemString_Name,curName,sizeof(curName));
            if (StrEqual(name,curName,false))
                return x;
        }
    }
    return -1;
}

bool:PurchaseShopItem(client,item)
{
    if (GetRestriction(client, Restriction_NoShopItems) ||
        GetRestriction(client, Restriction_Stunned))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Item, "%t", "PreventedFromItems");
        return false;
    }
    else
    {
        // Purchase
        new Handle:itemHandle=GetShopItemHandle(item);
        if (itemHandle != INVALID_HANDLE)
        {
            decl String:itemName[64];
            GetItemName(itemHandle, itemName, sizeof(itemName),client);

            new xp = GetItemXP(itemHandle);
            new gas = GetItemVespene(itemHandle);
            new bool:use_pcrystals = GetItemCanUsePCrystals(itemHandle);
            new pcrystals = (use_pcrystals) ? GetPCrystals(client) : 0;

            new cost, funds;
            if (g_bUseMoney)
            {
                funds = GetMoney(client);
                cost = GetItemMoney(itemHandle);
                if (cost == 0)
                    cost = RoundToNearest(float(cost) * g_fCrystalSellRate);
            }
            else
            {
                funds = GetCrystals(client);
                cost = GetItemCrystals(itemHandle);
                if (cost < 0)
                    cost = pcrystals;
            }

            if (funds + pcrystals >= cost)
            {
                new vespene = GetVespene(client);
                if (vespene >= gas)
                {
                    new race = GetRace(client);
                    new experience = GetXP(client, race);
                    if (experience >= xp)
                    {
                        new num = GetOwnsItem(client,item);
                        if (num < GetItemMax(itemHandle))
                        {
                            new Action:result = Plugin_Continue;
                            Call_StartForward(g_OnItemPurchaseExHandle);
                            Call_PushCell(client);
                            Call_PushCell(item);
                            Call_PushCellRef(use_pcrystals);
                            Call_PushCellRef(cost);
                            Call_PushCellRef(gas);
                            Call_PushCellRef(xp);
                            Call_Finish(result);

                            if (result == Plugin_Continue)
                            {
                                Call_StartForward(g_OnItemPurchaseHandle);
                                Call_PushCell(client);
                                Call_PushCell(item);
                                Call_Finish(result);
                            }

                            if (result != Plugin_Stop)
                            {
                                if (cost > 0)
                                {
                                    if (g_bUseMoney)
                                        SetMoney(client,funds-cost);
                                    else
                                    {
                                        if (use_pcrystals)
                                        {
                                            pcrystals -= cost;
                                            if (pcrystals < 0)
                                            {
                                                cost = pcrystals * -1;
                                                pcrystals = 0;
                                            }
                                            else
                                                cost = 0;

                                            SetPCrystals(client, pcrystals);
                                        }

                                        if (cost > 0)
                                        {
                                            SetCrystals(client,funds-cost);
                                        }
                                    }
                                }

                                if (gas > 0)
                                    SetVespene(client,vespene-gas);

                                if (xp > 0)
                                    SetXP(client,race,experience-xp);

                                SetOwnsItem(client,item,++num);

                                if (IsClientInGame(client) && !IsFakeClient(client))
                                {
                                    if (num > 1)
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "AnotherItemPurchased", itemName, num);
                                    }
                                    else
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "ItemPurchased", itemName);
                                    }
                                }

                                return true;
                            }
                        }
                        else if (IsClientInGame(client) && !IsFakeClient(client))
                        {
                            if (num > 1)
                            {
                                CPrintToChat(client, "{green}[SC]{default} %t", "AlreadyOwnMax", num, itemName);
                            }
                            else
                            {
                                CPrintToChat(client, "{green}[SC]{default} %t", "AlreadyOwn", itemName);
                            }
                        }
                    }
                    else if (IsClientInGame(client) && !IsFakeClient(client))
                    {
                        new Faction:faction;
                        if (race >= 0)
                        {
                            new Handle:raceHandle=GetRaceHandle(race);
                            faction=GetRaceFactionId(raceHandle);
                        }
                        else
                            faction=Generic;

                        EmitXPSoundToClient(client, faction);
                        CPrintToChat(client, "{green}[SC]{default} %t", "InsufficientXPFor", itemName, gas);
                    }
                }
                else if (IsClientInGame(client) && !IsFakeClient(client))
                {
                    new Faction:faction;
                    new race = GetRace(client);
                    if (race >= 0)
                    {
                        new Handle:raceHandle=GetRaceHandle(race);
                        faction=GetRaceFactionId(raceHandle);
                    }
                    else
                        faction=Generic;

                    EmitVespeneSoundToClient(client, faction);
                    CPrintToChat(client, "{green}[SC]{default} %t", "InsufficientVespeneFor", itemName, gas);
                }
            }
            else if (IsClientInGame(client) && !IsFakeClient(client))
            {
                new Faction:faction;
                new race = GetRace(client);
                if (race >= 0)
                {
                    new Handle:raceHandle=GetRaceHandle(race);
                    faction=GetRaceFactionId(raceHandle);
                }
                else
                    faction=Generic;

                EmitCrystalSoundToClient(client, faction);

                if (g_bUseMoney)
                    CPrintToChat(client, "{green}[SC]{default} %t", "InsufficientMoneyFor", itemName, cost);
                else
                    CPrintToChat(client, "{green}[SC]{default} %t", "InsufficientCrystalsFor", itemName, cost);
            }

            if (xp > 0)
                ShowXP(client);

            if (gas > 0)
                ShowVespene(client);

            if (cost > 0 && !g_bUseMoney)
                ShowCrystals(client);
        }
        return false;
    }
}

GetItemName(Handle:itemHandle, String:name[], maxlength, lang=LANG_SERVER)
{
    GetItemNameString(itemHandle, name, maxlength);
    if (name[0] == '%')
        Format(name,maxlength,"%T",name[1],lang);
    else
    {
        new Translation:translation = GetItemTranslation(itemHandle);
        if (translation > Translation_Auto)
        {
            // Translate the short name to get the name
            decl String:short[NAME_STRING_LENGTH];
            GetItemShortName(itemHandle, short, sizeof(short));

            if (translation == Translation_W3S)
            {
                // Use the War3Source key
                decl String:key[NAME_STRING_LENGTH];
                Format(key,sizeof(key),"%s_ItemName",short);
                Format(name,maxlength,"%T",key,lang);
            }
            else
            {
                // Translate the short name to get the name
                Format(name,maxlength,"%T",short,lang);
            }
        }
        else
            name[0] = '\0';
    }
}

GetItemCategory(Handle:itemHandle, String:category[], maxlength, lang=LANG_SERVER)
{
    GetItemCategoryString(itemHandle, category, maxlength);
    if (category[0] == '%')
        Format(category,maxlength,"%T",category[1],lang);
    else
    {
        new Translation:translation = GetItemTranslation(itemHandle);
        if (translation > Translation_Auto)
        {
            decl String:short[NAME_STRING_LENGTH];
            GetItemShortName(itemHandle, short, sizeof(short));

            if (translation == Translation_W3S)
            {
                // Use the War3Source key
                decl String:key[NAME_STRING_LENGTH];
                Format(key,sizeof(key),"%s_ItemCat",short);
                Format(category,maxlength,"%T",key,lang);
            }
            else
            {
                // Translate the key to get the category
                decl String:key[NAME_STRING_LENGTH];
                Format(key,sizeof(key),"%s_category",short);
                Format(category,maxlength,"%T",key,lang);
            }
        }
        else
            category[0] = '\0';
    }
}

GetItemDescription(Handle:itemHandle, String:description[], maxlength, lang=LANG_SERVER)
{
    GetItemDescriptionString(itemHandle, description, maxlength);
    if (description[0] == '%')
        Format(description,maxlength,"%T",description[1],lang);
    else
    {
        new Translation:translation = GetItemTranslation(itemHandle);
        if (translation > Translation_Auto)
        {
            // Translate the key to get the description
            decl String:short[DESCRIPTION_LENGTH];
            GetItemShortName(itemHandle, short, sizeof(short));

            if (translation == Translation_W3S)
            {
                // Use the War3Source key
                decl String:key[NAME_STRING_LENGTH];
                Format(key,sizeof(key),"%s_ItemDesc",short);
                Format(description,maxlength,"%T",key,lang);
            }
            else
            {
                decl String:key[NAME_STRING_LENGTH];
                Format(key,sizeof(key),"%s_desc",short);
                Format(description,maxlength,"%T",key,lang);
            }
        }
        else
            description[0] = '\0';
    }
}

GetItemImage(Handle:itemHandle, String:image[], maxlength,
             const String:imageString[]="", lang=LANG_SERVER)
{
    if (imageString[0] == '%')
        Format(image,maxlength,"%T",imageString[1],lang);
    else
    {
        new Translation:translation = GetItemTranslation(itemHandle);
        if (translation > Translation_Auto)
        {
            decl String:file[LONG_STRING_LENGTH];
            GetItemTranslationFile(itemHandle, file, sizeof(file));
            if (file[0])
            {
                decl String:short[SHORT_STRING_LENGTH];
                GetItemShortName(itemHandle, short, sizeof(short));

                if (translation == Translation_W3S)
                {
                    // Translate the short name + _ItemImage to get the image 
                    decl String:key[ITEM_STRING_LENGTH];
                    Format(key,sizeof(key),"%s_ItemImage",short);
                    if (FileContains(file, key))
                        Format(image,maxlength,"%T",key,lang);
                    else
                    {
                        strcopy(image,maxlength,imageString);
                    }
                }
                else
                {
                    // Translate the short name + _image to get the image 
                    decl String:key[ITEM_STRING_LENGTH];
                    Format(key,sizeof(key),"%s_image",short);
                    if (FileContains(file, key))
                        Format(image,maxlength,"%T",key,lang);
                    else
                    {
                        strcopy(image,maxlength,imageString);
                    }
                }
            }
            else
            {
                strcopy(image,maxlength,imageString);
            }
        }
        else
        {
            strcopy(image,maxlength,imageString);
        }
    }
}

