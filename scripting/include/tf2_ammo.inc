/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_ammo.inc
 * Description: Functions to return information about TF2 ammo.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _tf2_ammo_included
 #endinput
#endif
#define _tf2_ammo_included

enum TFAmmoTypes
{
    Primary=1,
    Secondary=2,
    Metal=3
}

//stock TF2_GetMetalAmount(client)
#define TF2_GetMetalAmount(%1)    GetEntProp(%1, Prop_Send, "m_iAmmo", .element=_:Metal)

//stock TF2_SetMetalAmount(client, metal)
#define TF2_SetMetalAmount(%1,%2) SetEntProp(%1, Prop_Send, "m_iAmmo", %2, .element=_:Metal)

stock TF2_GetAmmoAmount(client,TFAmmoTypes:type=Primary, weapon=0)
{
    new ammoType = _:type;
    if (weapon > 0 && IsValidEntity(weapon))
    {
        switch (type)
        {
            case Primary:   ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
            case Secondary: ammoType = GetEntProp(weapon, Prop_Send, "m_iSecondaryAmmoType");
        }
    }

    //return GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (_:type * 4), 4);
    return (ammoType >= 0) ? GetEntProp(client, Prop_Send, "m_iAmmo", .element=ammoType) : -1;
}

stock TF2_SetAmmoAmount(client, ammo = 999,TFAmmoTypes:type=Primary, weapon=0)
{
    new ammoType = _:type;
    if (weapon > 0 && IsValidEntity(weapon))
    {
        switch (type)
        {
            case Primary:   ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
            case Secondary: ammoType = GetEntProp(weapon, Prop_Send, "m_iSecondaryAmmoType");
        }
    }

    //SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (_:type * 4), ammo, 4);
    if (ammoType >= 0)
        SetEntProp(client, Prop_Send, "m_iAmmo", ammo, .element=ammoType);
}

// TF2 Weapon properties

//stock Float:GetEnergyAmmo(weapon)
#define TF2_GetEnergyAmmo(%1)     GetEntPropFloat(%1, Prop_Send, "m_flEnergy")

//stock SetEnergyAmmo(weapon, Float:flEnergyAmmo)
#define TF2_SetEnergyAmmo(%1,%2)  SetEntPropFloat(%1, Prop_Send, "m_flEnergy", %2);

stock TF2_ResetCaber(weapon)
{
	SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
	SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
}
