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
    decl String:curName[64]="";
    new size = GetShopItemCount();
    for(new x=0;x<size;x++)
    {
        new Handle:itemHandle=GetArrayCell(shopVector,x);
        GetArrayString(itemHandle,ITEM_SHORT_NAME,curName,sizeof(curName));
        if(!StrEqual(name,curName,false))
            return x;
    }
    return -1;
}
