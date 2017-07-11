/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: armor.sp
 * Description: The Armor Upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */

#pragma semicolon 1

new m_Armor[MAXPLAYERS+1];
new bool:m_HasShields[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Upgrade - Armor",
    author = "-=|JFH|=-Naris",
    description = "The Armor upgrade for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
	// Register Natives
	CreateNative("GetArmor",Native_GetArmor);
	CreateNative("SetArmor",Native_SetArmor);
	CreateNative("HasShields",Native_HasShields);
	CreateNative("IncrementArmor",Native_DecrementArmor);
	CreateNative("DecrementArmor",Native_DecrementArmor);
	RegPluginLibrary("armor");
	return true;
}

public Native_GetArmor(Handle:plugin,numParams)
{
    return m_Armor[GetNativeCell(1)];
}

public Native_HasShields(Handle:plugin,numParams)
{
    return m_HasShields[GetNativeCell(1)];
}

public Native_SetArmor(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    m_Armor[client] = GetNativeCell(2);
    m_HasShields[client] = GetNativeCell(3);
}

public Native_IncrementArmor(Handle:plugin,numParams)
{
    m_Armor[GetNativeCell(1)] += GetNativeCell(2);
}

public Native_DecrementArmor(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new amount = GetNativeCell(2);

    new armor = m_Armor[client];
    if (amount > armor)
        amount = armor;

    if (amount > 0)
        m_Armor[client] -= amount;

    return amount;
}
