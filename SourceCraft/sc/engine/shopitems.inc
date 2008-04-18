/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: shopitem.inc
 * Description: Defines the Shop Item Data.
 * Author(s): -=|JFH|=-Naris
 */

#define ITEM_STRINGS        0
#define ITEM_COST           1
#define ITEM_MAX            2
#define ITEM_REQUIRED_LEVEL 3
#define ITEM_DATA_COUNT     4

#define ITEM_NAME           0
#define ITEM_SHORT_NAME     1
#define ITEM_DESC           2
#define ITEM_STRING_COUNT   3

#define GetShopItemCount() GetArraySize(shopVector)

new Handle:g_OnItemPurchaseHandle = INVALID_HANDLE;

// A vector of shopmenu infomation
new Handle:shopVector = INVALID_HANDLE;

bool:InitShopVector()
{
    if (shopVector == INVALID_HANDLE)
        shopVector = CreateArray();

    return (shopVector != INVALID_HANDLE);
}

ClearShopVector()
{
    if (shopVector == INVALID_HANDLE)
    {
        new itemCount = GetShopItemCount();
        for(new x=0;x<itemCount;x++)
        {
            new Handle:vec=GetArrayCell(shopVector,x);
            new Handle:stringsHandle=GetArrayCell(vec,ITEM_STRINGS);
            ClearArray(stringsHandle);
            CloseHandle(stringsHandle);
            ClearArray(vec);
            CloseHandle(vec);
        }
    }

    ClearArray(shopVector);
    CloseHandle(shopVector);
    shopVector = INVALID_HANDLE;
}

CreateShopItem(const String:name[], const String:short[],
               const String:desc[], cost, max, required_level)
{
    new Handle:newItem=CreateArray();

    new Handle:stringsHandle=CreateArray(ByteCountToCells(192));
    PushArrayString(stringsHandle,name);
    PushArrayString(stringsHandle,short);
    PushArrayString(stringsHandle,desc);

    PushArrayCell(newItem,stringsHandle);
    PushArrayCell(newItem,cost);
    PushArrayCell(newItem,max);
    PushArrayCell(newItem,required_level);
    return PushArrayCell(shopVector,newItem); // return index.
}

Handle:GetShopItemHandle(itemnum)
{
    return GetArrayCell(shopVector,itemnum);
}

GetItemName(Handle:itemHandle, String:name[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(itemHandle,ITEM_STRINGS);
    if (stringsHandle != INVALID_HANDLE)
        GetArrayString(stringsHandle,ITEM_NAME,name,maxlength);
}

stock GetItemShortName(Handle:itemHandle, String:name[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(itemHandle,ITEM_STRINGS);
    if (stringsHandle != INVALID_HANDLE)
        GetArrayString(stringsHandle,ITEM_SHORT_NAME,name,maxlength);
}

GetItemDescription(Handle:itemHandle, String:desc[], maxlength)
{
    new Handle:stringsHandle=GetArrayCell(itemHandle,ITEM_STRINGS);
    if (stringsHandle != INVALID_HANDLE)
        GetArrayString(stringsHandle,ITEM_DESC,desc,maxlength);
}

GetItemCost(Handle:itemHandle)
{
    return GetArrayCell(itemHandle,ITEM_COST);
}

stock GetItemMax(Handle:itemHandle)
{
    return GetArrayCell(itemHandle,ITEM_MAX);
}

stock GetItemRequiredLevel(Handle:itemHandle)
{
    return GetArrayCell(itemHandle,ITEM_REQUIRED_LEVEL);
}

FindShopItem(const String:name[])
{
    decl String:curName[64];
    new size = GetShopItemCount();
    for(new x=0;x<size;x++)
    {
        new Handle:itemHandle=GetArrayCell(shopVector,x);
        new Handle:stringsHandle=GetArrayCell(itemHandle,ITEM_STRINGS);
        GetArrayString(stringsHandle,ITEM_SHORT_NAME,curName,sizeof(curName));
        if (StrEqual(name,curName,false))
            return x;
        else
        {
            GetArrayString(stringsHandle,ITEM_NAME,curName,sizeof(curName));
            if (StrEqual(name,curName,false))
                return x;
        }
    }
    return -1;
}

PurchaseShopItem(client,Handle:playerHandle,item)
{
    // Purchase
    new credits=GetCredits(playerHandle);
    new Handle:itemHandle=GetShopItemHandle(item);
    if (itemHandle != INVALID_HANDLE)
    {
        decl String:itemname[64];
        GetItemName(itemHandle, itemname, sizeof(itemname));

        new cost = GetItemCost(itemHandle);
        if(credits>=cost)
        {
            new num = GetOwnsItem(playerHandle,item);
            if (num < GetItemMax(itemHandle))
            {
                new result;
                new newcredits=credits-cost;
                SetCredits(playerHandle,newcredits);
                SetOwnsItem(playerHandle,item,++num);
                Call_StartForward(g_OnItemPurchaseHandle);
                Call_PushCell(client);
                Call_PushCell(playerHandle);
                Call_PushCell(item);
                Call_Finish(result);

                if (num > 1)
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou have successfully purchased another %s, you now have %d.",
                                COLOR_GREEN,COLOR_DEFAULT,itemname, num);
                }
                else
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou have successfully purchased the %s.",
                                COLOR_GREEN,COLOR_DEFAULT,itemname);
                }
            }
            else
            {
                if (num > 1)
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou already own the maximum allowed %d %ss.",
                                COLOR_GREEN,COLOR_DEFAULT, num, itemname);
                }
                else
                {
                    PrintToChat(client, "%c[SourceCraft] %cYou already own the %s.",
                                COLOR_GREEN,COLOR_DEFAULT, itemname);
                }
            }
        }
        else
        {
            EmitSoundToClient(client,notEnoughWav);
            PrintToChat(client, "%c[SourceCraft] %cYou can not afford the %s.",
                        COLOR_GREEN,COLOR_DEFAULT,itemname);
        }
        ShowCredits(client,playerHandle);
    }
}
