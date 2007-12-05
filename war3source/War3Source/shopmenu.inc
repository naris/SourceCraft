/**
 * File: shopmenu.inc
 * Description: The root of all shopmenu specific stuff.
 * Author(s): Anthony Iacono  
 */

#define SHOPITEM_COUNT GetArraySize(shopVector)

// A vector of shopmenu infomation
new Handle:shopVector;

public Handle:CreateShopItem(String:name[],String:desc[],String:cost[])
{
    new Handle:ret=CreateArray(ByteCountToCells(256));
    PushArrayString(ret,name);
    PushArrayString(ret,desc);
    PushArrayString(ret,cost);
    return ret;
}

public bool:War3Source_InitiateShopVector()
{
    shopVector=CreateArray();
    return true;
}

public Handle:ShopItem(itemnum)
{
    return GetArrayCell(shopVector,itemnum);
}