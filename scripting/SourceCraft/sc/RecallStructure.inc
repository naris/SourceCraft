/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: RecallStructure.inc
 * Description: SourceCraft Upgrade to recall buildings.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _RecallStructure_included
 #endinput
#endif
#define _RecallStructure_included

#undef REQUIRE_PLUGIN
#include "lib/ztf2grab"
#include "libtf2/remote"
#define REQUIRE_PLUGIN

#include "tf2_flag"
#include "gametype"

#include "sc/RecallSounds"
#include "sc/ShopItems"
#include "sc/plugins"

stock static m_raceId, m_upgradeId;
stock static bool:m_RecallStructureDelay[MAXPLAYERS+1];

stock RecallStructure(client, raceId, upgradeId, bool:disable, bool:engineersOnly)
{
    if (!IsValidClientAlive(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "YouHaveDied", upgradeName);
        PrepareAndEmitSoundToClient(client,recallErrWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,recallErrWav);
    }
    else if (GetGameType() == tf2 && TF2_HasTheFlag(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWithFlag", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceId, upgradeId, false))
    {
        if (engineersOnly)
        {
            if (TF2_GetPlayerClass(client) != TFClass_Engineer)
            {
                decl String:upgradeName[64];
                GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
                DisplayMessage(client, Display_Ultimate, "%t", "EngineersOnly", upgradeName);
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
        }
        else
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
                     TF2_IsPlayerDeadRingered(client) ||
                     TF2_IsPlayerDisguised(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
        }

        new target = GetClientAimTarget(client);
        if (target > 0) 
            RecallIt(client, raceId, upgradeId, target, disable);
        else
        {
            new Handle:menu=CreateMenu(RecallStructure_Selected);
            SetMenuTitle(menu, "[SC] %T", "RecallStructureTitle", client);

            new counts[TFOBJECT_COUNT];
            new sum = AddBuildingsToMenu(menu, client, false, counts, target);
            if (sum == 1)
                RecallIt(client, raceId, upgradeId, target, disable);
            else if (sum > 0)
            {
                m_raceId = raceId;
                m_upgradeId = upgradeId;
                m_RecallStructureDelay[client] = disable;
                DisplayMenu(menu,client,MENU_TIME_FOREVER);
            }
            else
            {
                CancelMenu(menu);
                PrepareAndEmitSoundToClient(client,errorWav);
                DisplayMessage(client, Display_Ultimate,
                               "%t", "NoStructuresToRecall");
            }
        }
    }
}

public RecallStructure_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(client,buttonWav);
        
        if (GetRace(client) == m_raceId)
        {
            decl String:SelectionInfo[12];
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

            new ref = StringToInt(SelectionInfo);
            if (ref != 0)
            {
                new ent = EntRefToEntIndex(ref);
                if (ent > 0 && IsValidEntity(ent))
                    RecallIt(client, m_raceId, m_upgradeId, ent, m_RecallStructureDelay[client]);
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

stock RecallIt(client, raceId, upgradeId, target, bool:disable)
{
    if (!IsValidClientAlive(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "YouHaveDied", upgradeName);
        PrepareAndEmitSoundToClient(client,recallErrWav);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,recallErrWav);
    }
    else if (GetGameType() == tf2 && TF2_HasTheFlag(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWithFlag", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (CanInvokeUpgrade(client, raceId, upgradeId, false))
    {
        switch (TF2_GetPlayerClass(client))
        {
            case TFClass_Spy:
            {
                if (TF2_IsPlayerCloaked(client) ||
                    TF2_IsPlayerDeadRingered(client) ||
                    TF2_IsPlayerDisguised(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return;
                }
            }
            case TFClass_Scout:
            {
                if (TF2_IsPlayerBonked(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return;
                }
            }
        }

        if (IsValidEdict(target) && IsValidEntity(target))
        {
            new TFExtObjectType:type=TF2_GetExtObjectType(target);
            if (type != TFExtObject_Unknown)
            {
                if (GetEntPropEnt(target, Prop_Send, "m_hBuilder") == client &&
                    !GetEntProp(target, Prop_Send, "m_bHasSapper") &&
                    !GetEntProp(target, Prop_Send, "m_bDisabled"))
                {
                    new Float:src[3];
                    GetEntPropVector(target, Prop_Send, "m_vecOrigin", src);

                    PrepareAndEmitAmbientSound(recallSrcWav,src);

                    new Float:size[3];
                    GetEntPropVector(target, Prop_Send, "m_vecBuildMaxs", size);

                    new Float:pos[3];
                    GetClientAbsOrigin(client, pos);

                    new Float:angles[3];
                    GetClientAbsAngles(client, angles);

                    if (type == TFExtObject_Teleporter ||
                        type == TFExtObject_TeleporterEntry ||
                        type == TFExtObject_TeleporterExit)
                    {
                        // Move player up
                        new Float:newPos[3];
                        newPos = pos;
                        newPos[2] += size[2] * 1.1;

                        TeleportEntity(client, newPos, NULL_VECTOR, NULL_VECTOR);
                    }
                    else
                    {
                        // Make it noclip so you don't get stuck
                        SetEntProp(target, Prop_Send, "m_CollisionGroup", 5);
                        CreateTimer(2.0, ResetCollisionGroup, target, TIMER_FLAG_NO_MAPCHANGE);
                    }

                    TeleportEntity(target, pos, angles, NULL_VECTOR); // Teleport building

                    PrepareAndEmitAmbientSound(recallDstWav,pos,target);

                    if (m_GravgunAvailable)
                        DropEntity(target);

                    if (disable)
                    {
                        new recall_structure_level = GetUpgradeLevel(client,raceId,upgradeId);
                        new Float:delay = float(5-recall_structure_level) * 0.5;
                        if (type == TFExtObject_Sentry &&
                            GetEntProp(target, Prop_Send, "m_bMiniBuilding") == 0)
                        {
                            delay *= float(GetEntProp(target, Prop_Send, "m_iUpgradeLevel")) * 0.25;
                        }

                        if (delay > 0.0)
                        {
                            SetEntProp(target, Prop_Send, "m_bDisabled", 1);
                            CreateTimer(delay, Activate, EntIndexToEntRef(target), TIMER_FLAG_NO_MAPCHANGE);
                        }
                    }

                    ChargeForUpgrade(client, raceId, upgradeId);
                    CreateCooldown(client, raceId, upgradeId);
                }
                else
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    DisplayMessage(client, Display_Ultimate, "%t", "TargetInvalid");
                }
            }
            else
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                DisplayMessage(client, Display_Ultimate, "%t", "TargetInvalid");
            }
        }
        else
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate, "%t", "TargetInvalid");
        }
    }
}

public Action:Activate(Handle:timer,any:ref)
{
    new obj = EntRefToEntIndex(ref);
    if (obj > 0 && IsValidEdict(obj) && IsValidEntity(obj))
    {
        if (!GetEntProp(obj, Prop_Send, "m_bHasSapper"))
            SetEntProp(obj, Prop_Send, "m_bDisabled", 0);
        else
            CreateTimer(0.2, Activate, ref, TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Stop;
}

public Action:ResetCollisionGroup(Handle:timer,any:obj)
{
    if (IsValidEdict(obj) && IsValidEntity(obj))
    {
        if (TF2_GetExtObjectType(obj) != TFExtObject_Unknown)
        {
            if (GetEntProp(obj, Prop_Send, "m_CollisionGroup") != 0)
            {
                new builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
                if (IsValidClientAlive(builder))
                {
                    decl Float:playerPos[3];
                    GetClientAbsOrigin(builder, playerPos);

                    decl Float:objectPos[3];
                    GetEntPropVector(obj, Prop_Send, "m_vecOrigin", objectPos);

                    decl Float:size[3];
                    GetEntPropVector(obj, Prop_Send, "m_vecBuildMaxs", size);

                    new Float:distance = GetVectorDistance(objectPos, playerPos);
                    if (distance < size[0] * -1.1 || distance > size[0] * 1.1)
                        SetEntProp(obj, Prop_Send, "m_CollisionGroup", 0);
                    else
                        CreateTimer(2.0, ResetCollisionGroup, obj, TIMER_FLAG_NO_MAPCHANGE);
                }
                else
                    SetEntProp(obj, Prop_Send, "m_CollisionGroup", 0);
            }
        }
    }
    return Plugin_Stop;
}
