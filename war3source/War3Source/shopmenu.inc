/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: shopmenu.inc
 * Description: The root of all shopmenu specific stuff.
 * Author(s): Anthony Iacono  
 */

#define SHOPITEM_COUNT GetArraySize(shopVector)

#define SHOPITEM_NAME   0
#define SHOPITEM_DESC   1
#define SHOPITEM_COST   2

// A vector of shopmenu infomation
new Handle:shopVector;

public Handle:CreateShopItem(const String:name[], const String:desc[], const String:cost[])
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

public GetShopItem(const String:name[])
{
    decl String:curName[64]="";
    new size = GetArraySize(shopVector);
    for(new x=0;x<size;x++)
    {
        new Handle:item=GetArrayCell(shopVector,x);
        GetArrayString(item,SHOPITEM_NAME,curName,63);
        if(!StrEqual(name,curName,false))
            return x;
    }
    return -1;
}
