/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: WarpIn.inc
 * Description: SourceCraft Upgrade to spawn amplifiers.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _WarpIn_included
 #endinput
#endif
#define _WarpIn_included

#undef REQUIRE_PLUGIN
#include <libtf2/remote>
#include <libtf2/amp_node>
#define REQUIRE_PLUGIN

#include "sc/plugins"

new Float:g_AmpRange[][][] =
{
    {   // Slow, Undisguise, Decloak, Really Slow
        { 0.0,    0.0,   0.0,   0.0 },
        { 0.0 , 130.0, 150.0, 170.0 },
        { 0.0 , 150.0, 170.0, 190.0 },
        { 0.0 , 170.0, 190.0, 210.0 },
        { 0.0 , 190.0, 210.0, 230.0 }
    },
    {   // Taunt
        { 0.0,    0.0,   0.0,   0.0 },
        { 0.0 , 100.0, 150.0, 200.0 },
        { 0.0 , 150.0, 200.0, 250.0 },
        { 0.0 , 200.0, 250.0, 300.0 },
        { 0.0 , 250.0, 300.0, 350.0 }
    },
    {   // Krit, Uber
        { 0.0,    0.0,   0.0,   0.0 },
        { 0.0 , 120.0, 150.0, 180.0 },
        { 0.0 , 150.0, 180.0, 210.0 },
        { 0.0 , 180.0, 210.0, 240.0 },
        { 0.0 , 210.0, 240.0, 280.0 }
    },
    {   // Buff, Jar, Fire, Milk, Defense
        { 0.0,    0.0,   0.0,   0.0 },
        { 0.0 , 100.0, 150.0, 200.0 },
        { 0.0 , 150.0, 200.0, 250.0 },
        { 0.0 , 200.0, 250.0, 300.0 },
        { 0.0 , 250.0, 300.0, 350.0 }
    }
};

stock static m_warpInRaceId, m_warpInUpgradeId;

WarpInAmplifier(client, amp_level, raceId, upgradeId, bool:allowKrit)
{
    if (m_BuildAvailable)
    {
        if (IsMole(client))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);

            decl String:upgradeName[64];
            GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "PreventedFromWarpingInAmplifier");
        }
        else if (CanInvokeUpgrade(client, raceId, upgradeId, .charge=false))
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);

            new Handle:menu=CreateMenu(Amplifier_Selected);
            SetMenuTitle(menu,"[SC] %T", "ChooseAmplifier", client);

            new count = CountConvertedBuildings(client, TFExtObject_Amplifier);
            new level = GetLevel(client, raceId);
            AddMenuItemT(menu,"0","SlowAmplifier",client, (count < amp_level && amp_level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"1","JarAmplifier",client, (count < amp_level && amp_level >= 2) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"9","MilkAmplifier",client, (count < amp_level && amp_level >= 2) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"2","FireAmplifier",client, (count < amp_level && amp_level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"11","BleedAmplifier",client, (count < amp_level && amp_level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"15","DeathAmplifier",client, (count < amp_level && amp_level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"3","TauntAmplifier",client, (count < amp_level && amp_level >= 3 && level >= 10) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"12","StunAmplifier",client, (count < amp_level && amp_level >= 3 && level >= 10) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"4","UndisguiseAmplifier",client, (count < amp_level && amp_level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"5","DecloakAmplifier",client, (count < amp_level && amp_level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"10","DefenseAmplifier",client, (count < amp_level) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"14","RegenAmplifier",client, (count < amp_level) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            AddMenuItemT(menu,"8","UberAmplifier",client, (count < amp_level && amp_level >= 4 && level >= 14) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            if (allowKrit)
            {
                AddMenuItemT(menu,"6","BuffAmplifier",client, (count < amp_level && amp_level >= 4 && level >= 16) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7","KritAmplifier",client, (count < amp_level && amp_level >= 4 && level >= 16) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            }

            m_warpInRaceId = raceId;
            m_warpInUpgradeId = upgradeId;
            AddMenuItemT(menu,"13","DestroyStructure",client, (count > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            DisplayMenu(menu,client,MENU_TIME_FOREVER);
        }
    }
}

public Amplifier_Selected(Handle:menu,MenuAction:action,client,selection)
{
    static const String:typeName[][] = { "SlowAmplifier", "JarAmplifier", "FireAmplifier", "TauntAmplifier", "UndisguiseAmplifier",
                                         "DecloakAmplifier", "BuffAmplifier", "KritAmplifier", "UberAmplifier", "MilkAmplifier",
                                         "DefenseAmplifier", "BleedAmplifier", "StunAmplifier", "SlowAmplifier", "RegenAmplifier",
                                         "DeathAmplifier" };

    static const TFCond:condition[] = { TFCond_Slowed,
                                        TFCond_Jarated,
                                        TFCond_OnFire,
                                        TFCond_Taunting,
                                        TFCond_Disguised,
                                        TFCond_Cloaked,
                                        TFCond_Buffed,
                                        TFCond_Kritzkrieged,
                                        TFCond_Ubercharged,
                                        TFCond_Milked,
	                                    TFCond_DefenseBuffed,
                                        TFCond_Bleeding,
                                        TFCond_Dazed,
                                        TFCond_Zoomed, // Really Slow
                                        TFCond_RegenBuffed,
                                        TFCond_MarkedForDeath
                                      };

    if (action == MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(client,buttonWav);
        
        if (GetRace(client) == m_warpInRaceId)
        {
            decl String:SelectionInfo[12];
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

            new item = StringToInt(SelectionInfo);
            if (item == 13)
            {
                if (!DestroyBuildingMenu(client))
                {
                    PrepareAndEmitSoundToClient(client,errorWav);
                    DisplayMessage(client, Display_Ultimate,
                                   "%t", "NoStructuresToDestroy");
                }
            }
            else
            {
                if (!IsPlayerAlive(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);

                    decl String:upgradeName[64];
                    GetUpgradeName(m_warpInRaceId, m_warpInUpgradeId, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client, Display_Ultimate,
                                   "%t", "YouHaveDied", upgradeName);
                }
                else if (IsMole(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);

                    decl String:upgradeName[64];
                    GetUpgradeName(m_warpInRaceId, m_warpInUpgradeId, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
                }
                else if (GetRestriction(client,Restriction_NoUltimates) ||
                         GetRestriction(client,Restriction_Stunned))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    DisplayMessage(client, Display_Ultimate,
                                   "%t", "PreventedFromWarpingInAmplifier");
                }
                else if (CanInvokeUpgrade(client, m_warpInRaceId, m_warpInUpgradeId))
                {
                    if (TF2_IsPlayerTaunting(client) ||
                        TF2_IsPlayerDazed(client))
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);
                        return;
                    }
                    //case TFClass_Scout:
                    else if (TF2_IsPlayerBonked(client))
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);
                        return;
                    }
                    //case TFClass_Spy:
                    else if (TF2_IsPlayerCloaked(client) ||
                             TF2_IsPlayerDeadRingered(client))
                    {
                        PrepareAndEmitSoundToClient(client,deniedWav);
                        return;
                    }
                    else if (TF2_IsPlayerDisguised(client))
                        TF2_RemovePlayerDisguise(client);

                    new obj = BuildObject(client, TFExtObject_Dispenser, 1, .check=false);
                    if (m_AmpNodeAvailable)
                    {
                        new percent, ri;
                        new level = GetUpgradeLevel(client,m_warpInRaceId,m_warpInUpgradeId);
                        switch (item)
                        {
                            case 0,13: // Slow, Really Slow
                            {
                                ri = 0;
                                percent = level * 25;
                                if (level > 2)
                                    item = 13; // for TFCond_Zoomed
                            }
                            case 3, 12: // Taunt, Stun
                            {
                                ri = 1;
                                percent = level * 5;
                            }
                            case 4,5: // Undisguise, Decloak
                            {
                                ri = 0;
                                percent = level * 5;
                            }
                            case 7,8: // Krit, Uber
                            {
                                ri = 2;
                                percent = level * 15;
                            }
                            default: // Buff, Jar, Fire, Milk, Defense, Bleed, Regen, Death
                            {
                                ri = 3;
                                percent = level * 25;
                            }
                        }
                        ConvertToAmplifier(obj, client, condition[item], g_AmpRange[ri][level], percent);
                    }

                    PrepareAndEmitSoundToAll(recallDstWav,client);

                    decl String:ampName[64];
                    Format(ampName, sizeof(ampName), "%T", typeName[item], client);
                    DisplayMessage(client,Display_Ultimate, "%t", "WarpedIn", ampName);
                    CreateCooldown(client, m_warpInRaceId, m_warpInUpgradeId);
                }
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}
