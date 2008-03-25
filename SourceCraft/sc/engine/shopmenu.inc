/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: shopmenu.inc
 * Description: The root of all shopmenu specific stuff.
 * Author(s): Anthony Iacono  
 */

#define SHOPITEM_NAME   0
#define SHOPITEM_DESC   1
#define SHOPITEM_COST   2

#define GetShopItemCount() GetArraySize(shopVector)

// A vector of shopmenu infomation
new Handle:shopVector;

Handle:CreateShopItem(const String:name[], const String:desc[], const String:cost[])
{
    new Handle:ret=CreateArray(ByteCountToCells(256));
    PushArrayString(ret,name);
    PushArrayString(ret,desc);
    PushArrayString(ret,cost);
    return ret;
}

bool:InitiateShopVector()
{
    shopVector=CreateArray();
    return true;
}

Handle:ShopItem(itemnum)
{
    return GetArrayCell(shopVector,itemnum);
}

GetShopItem(const String:name[])
{
    decl String:curName[64]="";
    new size = GetShopItemCount();
    for(new x=0;x<size;x++)
    {
        new Handle:item=GetArrayCell(shopVector,x);
        GetArrayString(item,SHOPITEM_NAME,curName,sizeof(curName));
        if(!StrEqual(name,curName,false))
            return x;
    }
    return -1;
}
