/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: SupplyDepot.inc
 * Description: The Terran Supply Depot upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */

#if defined _SupplyDepot_included
 #endinput
#endif
#define _SupplyDepot_included

#include <weapons>

#undef REQUIRE_EXTENSIONS
#include "dod"
#include "tf2_ammo"
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include "libtf2/AdvancedInfiniteAmmo"
#define REQUIRE_PLUGIN

#include "sc/plugins"

enum SupplyTypes ( <<= 1) { SupplyDefault = 1, SupplyPrimary, SupplySecondary, SupplyMetal, SupplyGrenade, SupplySmoke };

stock SupplyAmmo(client, amount, const String:source[],
                 SupplyTypes:types=SupplyDefault,
                 heavyFactor=10, bool:full=false)
{
    new ammoSupplied = 0;
    if (amount > 0)
    {
        if (GameType == tf2)
        {
            if (full && m_InfiniteAmmoAvailable)
            {
                ammoSupplied = AIA_FillAmmo(client) ? 4 : 0;
            }

            if (ammoSupplied == 0)
            {
                switch (TF2_GetPlayerClass(client))
                {
                    case TFClass_Scout: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 64.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if (full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 72.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied += 2;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }
                    }
                    case TFClass_Sniper: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 50.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if ( full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 150.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied += 2;
                            }
                        }
                    }
                    case TFClass_Soldier: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 40.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if (full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 64.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied += 2;
                            }
                        }
                    }
                    case TFClass_DemoMan: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 60.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if (full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 80.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied = 1;
                            }
                        }
                    }
                    case TFClass_Medic: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 300.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + (amount * heavyFactor), Primary, weapon);
                                ammoSupplied = 1;
                            }
                        }
                    }
                    case TFClass_Heavy: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 400.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + (amount * heavyFactor), Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if (full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 64.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied += 2;
                            }
                        }

                    }
                    case TFClass_Pyro: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 400.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + (amount * heavyFactor), Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if (full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 64.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied += 2;
                            }
                        }
                    }
                    case TFClass_Spy: 
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 48.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Primary, weapon);
                                ammoSupplied = 1;
                            }
                        }
                    }
                    case TFClass_Engineer: // Gets Metal instead of Ammo
                    {
                        if (full || !types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyMetal)   == SupplyMetal)
                        {
                            new ammo = TF2_GetAmmoAmount(client, Metal);
                            if (ammo >= 0 && ammo < 400.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + (amount * heavyFactor), Metal);
                                ammoSupplied += 2;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplyPrimary;
                        }

                        if (full || (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 64.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if (full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 200.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied += 2;
                            }
                        }
                    }
                    default:
                    {
                        if (!types ||
                            (types & SupplyDefault) == SupplyDefault ||
                            (types & SupplyPrimary) == SupplyPrimary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
                            new ammo = TF2_GetAmmoAmount(client, Primary, weapon);
                            if (ammo >= 0 && ammo < 100.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Primary, weapon);
                                ammoSupplied = 1;
                            }
                            else if ((types & SupplyDefault) == SupplyDefault)
                                types |= SupplySecondary;
                        }

                        if (full || (types & SupplySecondary) == SupplySecondary)
                        {
                            new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
                            new ammo = TF2_GetAmmoAmount(client, Secondary, weapon);
                            if (ammo >= 0 && ammo < 100.0)
                            {
                                TF2_SetAmmoAmount(client, ammo + amount, Secondary, weapon);
                                ammoSupplied += 2;
                            }
                        }
                    }
                }
            }
        }
        else if (GameType == dod)
        {
            new Max[4];
            new DODWeapon:Slot[4];
            new DODTeam:team = DODTeam:GetClientTeam(client);
            switch (DOD_GetPlayerClass(client))
            {
                case DODClass_Rifleman:
                {
                    if (team == DODTeam_Allies) 
                    {
                        Slot[0] = DODWeapon_Garand;
                        Max[0]  = 99;
                        Slot[1] = DODWeapon_Colt;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_USRifleGrenade;
                        Max[2]  = 4;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                    else
                    {
                        Slot[0] = DODWeapon_K98;
                        Max[0]  = 99;
                        Slot[1] = DODWeapon_P38;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_GermanRifleGrenade;
                        Max[2]  = 4;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                }
                case DODClass_Assault:
                {
                    if (team == DODTeam_Allies) 
                    {
                        Slot[0] = DODWeapon_Thompson;
                        Max[0]  = 999;
                        Slot[1] = DODWeapon_Colt;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_FragGrenade;
                        Max[2]  = 4;
                        Slot[3] = DODWeapon_USSmokeGrenade;
                        Max[3]  = 4;
                    }
                    else
                    {
                        Slot[0] = DODWeapon_MP40;
                        Max[0]  = 999;
                        Slot[1] = DODWeapon_P38;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_StickGrenade;
                        Max[2]  = 4;
                        Slot[3] = DODWeapon_GermanSmokeGrenade;
                        Max[3]  = 4;
                    }
                }
                case DODClass_Support:
                {
                    if (team == DODTeam_Allies) 
                    {
                        Slot[0] = DODWeapon_BAR;
                        Max[0]  = 999;
                        Slot[1] = DODWeapon_Colt;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_FragGrenade;
                        Max[2]  = 4;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                    else
                    {
                        Slot[0] = DODWeapon_MP44;
                        Max[0]  = 999;
                        Slot[1] = DODWeapon_P38;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_StickGrenade;
                        Max[2]  = 4;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                }
                case DODClass_Sniper:
                {
                    if (team == DODTeam_Allies) 
                    {
                        Slot[0] = DODWeapon_Springfield;
                        Max[0]  = 99;
                        Slot[1] = DODWeapon_Colt;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_None;
                        Max[2]  = 0;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                    else
                    {
                        Slot[0] = DODWeapon_ScopedK98;
                        Max[0]  = 99;
                        Slot[1] = DODWeapon_P38;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_None;
                        Max[2]  = 0;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                }
                case DODClass_MachineGunner:
                {
                    if (team == DODTeam_Allies) 
                    {
                        Slot[0] = DODWeapon_30CalMG;
                        Max[0]  = 999;
                        Slot[1] = DODWeapon_Colt;
                        Max[1]  = 99;
                        Slot[2] = DODWeapon_None;
                        Max[2]  = 0;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                    else
                    {
                        Slot[0] = DODWeapon_MG42;
                        Max[0]  = 999;
                        Slot[1] = DODWeapon_P38;
                        Max[1]  = 999;
                        Slot[2] = DODWeapon_None;
                        Max[2]  = 0;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                }
                case DODClass_Rocketman:
                {
                    if (team == DODTeam_Allies) 
                    {
                        Slot[0] = DODWeapon_Bazooka;
                        Max[0]  = 99;
                        Slot[1] = DODWeapon_M1Carbine;
                        Max[1]  = 999;
                        Slot[2] = DODWeapon_None;
                        Max[2]  = 0;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                    else
                    {
                        Slot[0] = DODWeapon_Panzerschrek;
                        Max[0]  = 99;
                        Slot[1] = DODWeapon_C96;
                        Max[1]  = 999;
                        Slot[2] = DODWeapon_None;
                        Max[2]  = 0;
                        Slot[3] = DODWeapon_None;
                        Max[3]  = 0;
                    }
                }
            }

            new m_iAmmo; // = FindSendPropOffs("CDODPlayer", "m_iAmmo");
            FindSendPropInfo("CDODPlayer", "m_iAmmo", .local_offset=m_iAmmo);
            for (new i=0; i < sizeof(Slot); i++)
            {
                if (i == 0 && !(!types || (types & SupplyDefault) || (types & SupplyPrimary)))
                    continue;
                else if (i == 1 && !(types & SupplySecondary))
                    continue;
                else if (i == 2 && !(types & SupplyGrenade))
                    continue;
                else if (i == 3 && !(types & SupplySmoke))
                    continue;
                else
                {
                    new DODWeapon:weapon = Slot[i];
                    if (weapon > DODWeapon_None)
                    {
                        new offset = m_iAmmo + DOD_AmmoOffset[weapon];
                        new ammo = GetEntData(client, offset);
                        if (ammo < Max[i])
                        {
                            SetEntData(client, offset, ammo + amount, 4, true);
                            ammoSupplied = 1;
                        }
                    }
                }
            }
        }
        else
        {
            new curWeapon = GetActiveWeapon(client);
            if (curWeapon > 0)
            {
                SetClip(curWeapon, 5);
                ammoSupplied = 1;
            }
        }
    }

    if (ammoSupplied > 0)
    {
        decl String:type[64];
        type[0] = '\0';

        if (GameType == tf2)
        {
            switch(ammoSupplied)
            {
                case 1: Format(type,sizeof(type), "%T", "Primary", client);
                case 2: Format(type,sizeof(type), "%T", "Secondary", client);
                case 3: Format(type,sizeof(type), "%T", "PrimaryAndSecondary", client);
            }            
        }            

        DisplayMessage(client,Display_Message, "%t", "RecievedAmmo", type, source);
    }
}
