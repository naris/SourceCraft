/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: ammo.inc
 * Description: Ammo functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _ammo_included
 #endinput
#endif
#define _ammo_included

stock GetClip(weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iClip1");
}

stock SetClip(weapon, amount)
{
    SetEntProp(weapon, Prop_Send, "m_iClip1", amount);
}

stock GetAmmoType(weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
}

stock SetActiveWeaponAmmo(client,amount)
{
    new iWeapon = GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
    SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), amount);
}
