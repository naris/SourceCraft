/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Mutate.inc
 * Description: SourceCraft Upgrade to Mutate into buildings.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _Mutate_included
 #endinput
#endif
#define _Mutate_included

#include <ResourceManager>

#undef REQUIRE_PLUGIN
#include <remote>
#include <amp_node>
#include <ztf2grab>
#define REQUIRE_PLUGIN

#include "sc/menuitemt"
#include "sc/ShopItems"
#include "sc/plugins"
#include "sc/burrow"
#include "sc/sounds"

stock const String:mutateWav[] = "sc/zchrdy00.wav";
stock const String:mutateErr[] = "sc/zzdmin00.wav";

stock Float:m_MutateAmpRange[][] =
{
    { 0.0,    0.0,   0.0,   0.0 },
    { 0.0 , 100.0, 150.0, 200.0 },
    { 0.0 , 150.0, 200.0, 250.0 },
    { 0.0 , 200.0, 250.0, 300.0 },
    { 0.0 , 250.0, 300.0, 350.0 }
};

stock Float:m_MutateNodeRange[][] =
{
    { 0.0,    0.0,   0.0,   0.0 },
    { 0.0 , 100.0, 150.0, 200.0 },
    { 0.0 , 150.0, 250.0, 300.0 },
    { 0.0 , 200.0, 300.0, 400.0 },
    { 0.0 , 250.0, 350.0, 500.0 }
};

stock m_MutateNodeRegen[][] =
{
    { 0,  0,  0,  0 },
    { 0, 10, 15, 20 },
    { 0, 15, 20, 25 },
    { 0, 20, 25, 30 },
    { 0, 25, 30, 40 }
};

stock m_MutateNodeShells[][] =
{
    { 0,  0,  0,  0 },
    { 0,  0,  0,  0 },
    { 0,  0,  5, 10 },
    { 0,  5, 10, 15 },
    { 0, 10, 15, 20 }
};

stock m_MutateNodeRockets[] = { 0,  0,  0,  2,  4 };

stock m_MutateDisableLevel        = 0;
stock bool:m_MutateMultiplyEnergy = false;
stock bool:m_MutateMultiplyVespene= false;

stock static m_raceId, m_upgradeId;
stock static m_maxUpgradeID, m_maxObjects;

stock SetupMutate()
{
    SetupErrorSound();
    SetupButtonSound();

    SetupSound(mutateErr);
}

stock Mutate(client, level, raceId, upgradeId, maxUpgradeID=-1,
             maxObjects=5, bool:engineersOnly=false)
{
    if (GetGameType() != tf2 || !m_BuildAvailable)
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        PrintHintText(client,"%t", "IsNotAvailable", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (!IsValidClientAlive(client))
    {
        PrepareAndEmitSoundToClient(client,mutateErr);

        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "YouHaveDied", upgradeName);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (IsBurrowed(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWhileBurrowed", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (CanInvokeUpgrade(client, raceId, upgradeId, false))
    {
        if (engineersOnly && TF2_GetPlayerClass(client) != TFClass_Engineer)
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "EngineersOnly", upgradeName);
            PrepareAndEmitSoundToClient(client,mutateErr);
            return;
        }
        else
        {
            if (TF2_IsPlayerTaunting(client) ||
                TF2_IsPlayerDazed(client))
            {
                PrepareAndEmitSoundToClient(client,mutateErr);
                return;
            }
            //case TFClass_Scout:
            else if (TF2_IsPlayerBonked(client))
            {
                PrepareAndEmitSoundToClient(client,mutateErr);
                return;
            }
            //case TFClass_Spy:
            else if (TF2_IsPlayerCloaked(client) ||
                     TF2_IsPlayerDeadRingered(client) ||
                     TF2_IsPlayerDisguised(client))
            {
                PrepareAndEmitSoundToClient(client,mutateErr);
                return;
            }
        }

        new Handle:menu=CreateMenu(Mutate_Selected);
        SetMenuTitle(menu, "[SC] %T", "MutateTitle", client);

        new maxCount=(maxUpgradeID >= 0) ? GetUpgradeLevel(client,raceId,maxUpgradeID) + 1 : 1;
        if (maxCount > maxObjects)
            maxCount = maxObjects;

        new Float:energy      = GetEnergy(client);
        new Float:energy_cost = GetUpgradeEnergy(raceId, upgradeId);

        new vespene           = GetVespene(client);
        new vespene_cost      = GetUpgradeVespene(raceId, upgradeId);

        new bool:ok           = (energy >= energy_cost && vespene >= vespene_cost);

        new counts[TFExtObjectType];
        new sum = CountBuildings(client, counts);

        AddMenuItemT(menu,"6","MiniSentry", client, (ok && counts[TFObject_Sentry] < maxCount) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

        if (level >= 2)
        {
            AddMenuItemT(menu,"2","Sentry", client, (ok && counts[TFObject_Sentry] < maxCount) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        }
        else
        {
            AddMenuItemT(menu,"2","SentryRequiresLevel2", client, ITEMDRAW_DISABLED);
        }

        new dispenserOK = (ok && counts[TFObject_Dispenser] < maxCount);

        if (m_AmpNodeAvailable)
        {
            AddMenuItemT(menu,"7","Amplifier", client, (dispenserOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            AddMenuItemT(menu,"8","RepairNode", client, (dispenserOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        }
        else
        {
            AddMenuItemT(menu,"0","Dispenser", client, (dispenserOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        }

        AddMenuItemT(menu,"12","DestroyStructure", client, (sum > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

        m_raceId = raceId;
        m_upgradeId = upgradeId;
        m_maxObjects = maxObjects;
        m_maxUpgradeID = maxUpgradeID;

        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
}

public Mutate_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(client,buttonWav);

        if (GetRace(client) == m_raceId)
        {
            decl String:SelectionInfo[12];
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

            new item = StringToInt(SelectionInfo);
            if (item == 12)
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
                new mutate_level=GetUpgradeLevel(client,m_raceId,m_upgradeId);
                MutateInto(client, m_raceId, m_upgradeId, m_maxUpgradeID, m_maxObjects,
                           TFExtObjectType:item, (mutate_level > 1) ? mutate_level - 1 : 1,
                           .bDisabled = (mutate_level < m_MutateDisableLevel));
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

stock MutateInto(client, raceId, upgradeId, maxUpgradeID, maxObjects=5,
                 TFExtObjectType:type, level=1, bool:bMini=false,
                 bool:bShielded=false, bool:bDisabled=true)
{
    if (!IsValidClientAlive(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "YouHaveDied", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (IsBurrowed(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWhileBurrowed", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,mutateErr);
    }
    else if (CanInvokeUpgrade(client, raceId, upgradeId, false))
    {
        if (TF2_IsPlayerTaunting(client) ||
            TF2_IsPlayerDazed(client))
        {
            PrepareAndEmitSoundToClient(client,mutateErr);
            return;
        }
        //case TFClass_Scout:
        else if (TF2_IsPlayerBonked(client))
        {
            PrepareAndEmitSoundToClient(client,mutateErr);
            return;
        }
        //case TFClass_Spy:
        else if (TF2_IsPlayerCloaked(client) ||
                 TF2_IsPlayerDeadRingered(client) ||
                 TF2_IsPlayerDisguised(client))
        {
            PrepareAndEmitSoundToClient(client,mutateErr);
            return;
        }

        new maxCount = (maxUpgradeID >= 0) ? GetUpgradeLevel(client,raceId,maxUpgradeID) + 1 : 1;
        if (maxCount > maxObjects)
            maxCount = maxObjects;

        new numBuilt = CountObjects(client, TF2_ObjectClassNames[type]);
        new costNum = numBuilt+1;

        if (numBuilt >= maxCount)
        {
            PrepareAndEmitSoundToClient(client,mutateErr);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "MutateLimitReached",
                           TF2_ObjectNames[type], costNum);
            return;
        }

        new Float:energy = GetEnergy(client);
        new Float:energy_cost = GetUpgradeEnergy(raceId, upgradeId);

        new vespene = GetVespene(client);
        new vespene_cost = GetUpgradeVespene(raceId, upgradeId);

        if (costNum > 1)
        {
            if (m_MutateMultiplyEnergy)
            {
                energy_cost *= float(costNum);
                if (energy < energy_cost)
                {
                    decl String:upgradeName[64];
                    GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client, Display_Energy, "%t", "InsufficientEnergyFor", upgradeName, energy_cost);
                    EmitEnergySoundToClient(client,GetRaceFaction(raceId));
                    return;
                }
            }

            if (m_MutateMultiplyVespene)
            {
                vespene_cost *= costNum;
                if (vespene < vespene_cost)
                {
                    decl String:upgradeName[64];
                    GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
                    DisplayMessage(client, Display_Energy, "%t", "InsufficientVespeneFor", upgradeName, vespene_cost);
                    EmitVespeneSoundToClient(client,GetRaceFaction(raceId));
                    return;
                }
            }
        }

        new Float:pos[3];
        new ent = BuildObject(client, type, (bMini || type == TFExtObject_MiniSentry) ? 1 : level,
                              bMini, bShielded, .iHealth=GetClientHealth(client),
                              .pos=pos, .check=false, .bDisabled=bDisabled);
        if (ent > 0)
        {
            SetEnergy(client, energy-energy_cost);
            SetVespene(client, vespene-vespene_cost);
            //ChargeForUpgrade(client, raceId, upgradeId);

            KillPlayer(client, .silent=true);
            PrepareAndEmitAmbientSound(mutateWav,pos,ent);
            DisplayMessage(client, Display_Ultimate, "%t",
                           "Mutated", TF2_ObjectNames[type]);

            new Float:cooldown = GetUpgradeCooldown(raceId, upgradeId) * float(costNum * 2);
            CreateCooldown(client, raceId, upgradeId, cooldown);

            if (m_AmpNodeAvailable)
            {
                if (type == TFExtObject_Amplifier)
                {
                    ConvertToAmplifier(ent, client, TFCond_Buffed, m_MutateAmpRange[level]);
                }
                else if (type == TFExtObject_RepairNode)
                {
                    ConvertToRepairNode(ent, client, m_MutateNodeRange[level],
                                        m_MutateNodeRegen[level], m_MutateNodeShells[level],
                                        m_MutateNodeRockets[level], .team=true);
                }
            }
        }
        else
        {
            PrepareAndEmitSoundToClient(client,mutateErr);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "UnableToMutate");
        }
    }
}
