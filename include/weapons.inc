/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: weapons.inc
 * Description: Stocks to return information about weapons.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _weapons_included
 #endinput
#endif
#define _weapons_included

#define MAX_SLOTS 48

//stock GetPrimaryAmmoType(weapon)
#define GetPrimaryAmmoType(%1)   GetEntProp(%1, Prop_Send, "m_iPrimaryAmmoType")

//stock GetSecondaryAmmoType(weapon)
#define GetSecondaryAmmoType(%1) GetEntProp(%1, Prop_Send, "m_iSecondaryAmmoType")

//stock GetClip(weapon)
#define GetClip(%1)              GetEntProp(%1, Prop_Send, "m_iClip1", 1)

//stock SetClip(weapon, amount)
#define SetClip(%1,%2)           SetEntProp(%1, Prop_Send, "m_iClip1", %2, 1)

stock GetActiveWeapon(client, bool:validate=true)
{
    decl String:classname[64];
    new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    return (!validate ||
            (weapon > 0 && IsValidEntity(weapon) && IsValidEdict(weapon) &&
             GetEdictClassname(weapon, classname, sizeof(classname)) &&
             StrContains(classname, "weapon") == 0))
           ? weapon : INVALID_ENT_REFERENCE;
}

stock GetCurrentWeaponClass(client, String:name[], maxlength)
{
    new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (index > 0 && IsValidEntity(index))
        GetEntityNetClass(index, name, maxlength);
    else
        name[0] = '\0';
}

stock GetCurrentWeaponEdictClass(client, String:name[], maxlength)
{
    new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (index > 0 && IsValidEntity(index))
        GetEdictClassname(index, name, maxlength);
    else
        name[0] = '\0';
}

/**
 * Prevents a player from attacking for duration
 *
 * @param client 	Client
 * @param duration 	When to allow the next attack
 * @param melee 	Set melee attacks also?
 * @return			none
 */
stock SetNextAttack(client, Float:duration=0.0)
{
    new Float:nextAttack = GetGameTime()+duration;
    new offset=FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
    for(new i=0;i<MAX_SLOTS;i++)
    {
        new weapon=GetEntDataEnt2(client,offset);
        if (weapon > 0 && IsValidEdict(weapon))
        {
            SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", nextAttack);
            SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", nextAttack);
        }
        offset += 4;
    }
}

