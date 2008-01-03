/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: weapons.inc
 * Description: Weapons related functions.
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _weapons_included
 #endinput
#endif
#define _weapons_included


stock bool:IsEquipmentMelee(const String:wepName[])
{
    switch (GameType)
    {
        case cstrike:
        {
            return StrEqual(wepName,"weapon_knife");
        }
        case dod:
        {
            return (StrEqual(wepName,"weapon_amerknife") ||
                    StrEqual(wepName,"weapon_spade"));
        }
        case tf2:
        {
            return (StrEqual(wepName,"tf_weapon_knife") ||
                    StrEqual(wepName,"tf_weapon_shovel") ||
                    StrEqual(wepName,"tf_weapon_wrench") ||
                    StrEqual(wepName,"tf_weapon_bat") ||
                    StrEqual(wepName,"tf_weapon_bonesaw") ||
                    StrEqual(wepName,"tf_weapon_bottle") ||
                    StrEqual(wepName,"tf_weapon_club") ||
                    StrEqual(wepName,"tf_weapon_fireaxe") ||
                    StrEqual(wepName,"tf_weapon_fists") ||
                    StrEqual(wepName,"tf_weapon_builder") ||
                    StrEqual(wepName,"tf_weapon_pda_engineer_build") ||
                    StrEqual(wepName,"tf_weapon_pda_engineer_destroy") ||
                    StrEqual(wepName,"tf_weapon_pda_spy"));
        }
    }
    return false;
}

stock bool:IsDamageFromMelee(const String:wepName[])
{
    switch (GameType)
    {
        case cstrike:
        {
            return StrEqual(wepName,"knife");
        }
        case dod:
        {
            return (StrEqual(wepName,"amerknife") ||
                    StrEqual(wepName,"spade"));
        }
        case tf2:
        {
            return (StrEqual(wepName,"knife") ||
                    StrEqual(wepName,"shovel") ||
                    StrEqual(wepName,"wrench") ||
                    StrEqual(wepName,"bat") ||
                    StrEqual(wepName,"bonesaw") ||
                    StrEqual(wepName,"bottle") ||
                    StrEqual(wepName,"club") ||
                    StrEqual(wepName,"fireaxe") ||
                    StrEqual(wepName,"fists"));
        }
    }
    return false;
}

