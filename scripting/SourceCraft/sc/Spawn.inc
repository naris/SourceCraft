/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Spawn.inc
 * Description: SourceCraft Upgrade to spawn buildings.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _Spawn_included
 #endinput
#endif
#define _Spawn_included

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

stock Float:m_SpawnAmpRange[][] =
{
    { 0.0,    0.0,   0.0,   0.0 },
    { 0.0 , 100.0, 150.0, 200.0 },
    { 0.0 , 150.0, 200.0, 250.0 },
    { 0.0 , 200.0, 250.0, 300.0 },
    { 0.0 , 250.0, 300.0, 350.0 }
};

stock Float:m_SpawnNodeRange[][] =
{
    { 0.0,    0.0,   0.0,   0.0 },
    { 0.0 , 100.0, 150.0, 200.0 },
    { 0.0 , 150.0, 250.0, 300.0 },
    { 0.0 , 200.0, 300.0, 400.0 },
    { 0.0 , 250.0, 350.0, 500.0 }
};

stock m_SpawnNodeRegen[][] =
{
    { 0,  0,  0,  0 },
    { 0, 10, 15, 20 },
    { 0, 15, 20, 25 },
    { 0, 20, 25, 30 },
    { 0, 25, 30, 40 }
};

stock m_SpawnNodeShells[][] =
{
    { 0,  0,  0,  0 },
    { 0,  0,  0,  0 },
    { 0,  0,  5, 10 },
    { 0,  5, 10, 15 },
    { 0, 10, 15, 20 }
};

stock m_SpawnNodeRockets[] = { 0,  0,  0,  2,  4 };

stock static m_spawnRaceId, m_spawnUpgradeId;
stock static String:m_SpawnSound[PLATFORM_MAX_PATH];

stock SetupSpawn()
{
    SetupErrorSound();
    SetupDeniedSound();
    SetupButtonSound();
}

stock Spawn(client, level, raceId, upgradeId, maxObjects, bool:multAmps, bool:allowKrit,
            bool:engineersOnly, const String:spawnSound[], const String:menuTitle[])
{
    if (!IsValidClientAlive(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "YouHaveDied", upgradeName);
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
    else if (IsBurrowed(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWhileBurrowed", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (HasCooldownExpired(client, raceId, upgradeId))
    {
        new TFClassType:class = TF2_GetPlayerClass(client);
        if (engineersOnly && class != TFClass_Engineer)
        {
            decl String:upgradeName[64];
            GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "EngineersOnly", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
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
                     TF2_IsPlayerDeadRingered(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
            else if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);
        }

        decl String:title[64];
        Format(title, sizeof(title), "[SC] %T", menuTitle, client);

        new Handle:menu=CreateMenu(Spawn_Selected);
        SetMenuTitle(menu,title);

        new Float:energy      = GetEnergy(client);
        new Float:energy_cost = GetUpgradeEnergy(raceId,upgradeId);

        new vespene           = GetVespene(client);
        new vespene_cost      = GetUpgradeVespene(raceId,upgradeId);
        new bool:ok           = (energy >= energy_cost && vespene >= vespene_cost);

        new max_count         = (level > maxObjects) ? maxObjects : level;

        new counts[TFExtObjectType];
        new sum = CountBuildings(client, counts);

        AddMenuItemT(menu,"6","MiniSentry", client, (ok && counts[TFObject_Sentry] < max_count) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        AddMenuItemT(menu,"2","Sentry",     client, (ok && counts[TFObject_Sentry] < max_count) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

        if (m_AmpNodeAvailable)
        {
            new dispOK = (ok && counts[TFObject_Dispenser] < max_count);

            AddMenuItemT(menu,"8","RepairNode", client, (dispOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            //AddMenuItemT(menu,"9","UpgradeStation", client, (dispOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            if (multAmps)
            {
                AddMenuItemT(menu,"7,0","SlowAmplifier",       client, (dispOK && level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,1","JarAmplifier",        client, (dispOK && level >= 2) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,9","MilkAmplifier",       client, (dispOK && level >= 2) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,2","FireAmplifier",       client, (dispOK && level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,11","BleedAmplifier",     client, (dispOK && level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,15","DeathAmplifier",     client, (dispOK && level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,3","TauntAmplifier",      client, (dispOK && level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,12","StunAmplifier",      client, (dispOK && level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,4","UndisguiseAmplifier", client, (dispOK && level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,5","DecloakAmplifier",    client, (dispOK && level >= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,10","DefenseAmplifier",   client, (dispOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,14","RegenAmplifier",     client, (dispOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                AddMenuItemT(menu,"7,8","UberAmplifier",       client, (dispOK && level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

                if (allowKrit)
                {
                    AddMenuItemT(menu,"7,6","BuffAmplifier",   client, (dispOK && level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                    AddMenuItemT(menu,"7,7","KritAmplifier",   client, (dispOK && level >= 4) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
                }
            }
            else
            {
                AddMenuItemT(menu,"7","Amplifier", client, (dispOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            }
        }
        else
        {
            new dispenserOK = (ok && counts[TFObject_Dispenser] < ((max_count > 1) ? 1 : max_count));
            AddMenuItemT(menu,"0","Dispenser",  client, (dispenserOK) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        }

        AddMenuItemT(menu,"13","DestroyStructure", client, (sum > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

        m_spawnRaceId = raceId;
        m_spawnUpgradeId = upgradeId;
        strcopy(m_SpawnSound, sizeof(m_SpawnSound), spawnSound);
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
}

public Spawn_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(client,buttonWav);
        
        if (GetRace(client) == m_spawnRaceId)
        {
            decl String:num[16];
            decl String:SelectionInfo[32];
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
            new pos = BreakString(SelectionInfo, num, sizeof(num));
            new item = StringToInt(num);
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
                if (TF2_GetPlayerClass(client) == TFClass_Engineer &&
                    CountObjects(client,TF2_ObjectClassNames[item]) <= 0)
                {
                    new TFObjectType:obj;
                    if (item == _:TFExtObject_MiniSentry)
                        obj = TFObject_Sentry;
                    else if (item == _:TFExtObject_RepairNode)
                    {
                        obj = TFObject_Dispenser;
                        if (m_AmpNodeAvailable)
                        {
                            new spawn_level=GetUpgradeLevel(client,m_spawnRaceId,m_spawnUpgradeId);
                            SetRepairNode(client, .team=(spawn_level>2), .enable=true, .select=true);
                        }
                    }
                    else if (item == _:TFExtObject_Amplifier)
                    {
                        obj = TFObject_Dispenser;
                        if (m_AmpNodeAvailable)
                        {
                            new TFCond:cond = TFCond_Buffed;
                            if (pos > 0)
                            {
                                BreakString(SelectionInfo[pos], num, sizeof(num));
                                cond = TFCond:StringToInt(num);
                            }
                            SetAmplifier(client, cond, .enable=true, .select=true);
                        }
                    }
                    /*else if (item == _:TFExtObject_UpgradeStation)
                    {
                        obj = TFObject_Dispenser;
                        if (m_AmpNodeAvailable)
                        {
                            SetUpgradeStation(client, .enable=true, .select=true);
                        }
                    }*/
                    else
                        obj = TFObjectType:item;

                    ClientCommand(client, "build %d", obj);
                }
                else
                {
                    new spawn_level=GetUpgradeLevel(client,m_spawnRaceId,m_spawnUpgradeId);
                    SpawnIt(client, TFExtObjectType:item, m_spawnRaceId, m_spawnUpgradeId,
                            spawn_level, false, false, m_SpawnSound);
                }
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

stock SpawnIt(client, TFExtObjectType:type, raceId, upgradeId, level,
              bool:bMini, bool:bShielded, const String:spawnSound[])
{
    new count;

    if (!IsValidClientAlive(client))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);

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
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsBurrowed(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWhileBurrowed", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (!CheckBuild(client, TFObjectType:type, -1, count))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        DisplayMessage(client, Display_Ultimate,
                       "%t", "StructureLimitReached",
                       count, TF2_ObjectNames[type]);
    }
    else if (CanInvokeUpgrade(client, raceId, upgradeId, false))
    {
        switch (TF2_GetPlayerClass(client))
        {
            case TFClass_Spy:
            {
                if (TF2_IsPlayerCloaked(client) ||
                    TF2_IsPlayerDeadRingered(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return;
                }
                else if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
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

        m_spawnRaceId = raceId;
        m_spawnUpgradeId = upgradeId;
        strcopy(m_SpawnSound, sizeof(m_SpawnSound), spawnSound);
        new obj = BuildObject(client, type, (bMini || type == TFExtObject_MiniSentry) ? 1 : level,
                              bMini, bShielded, .bDisabled=true, .check=false);
        if (obj > 0)
        {
            //if (m_GravgunAvailable)
            //    DropEntity(obj);

            ChargeForUpgrade(client, raceId, upgradeId);
            PrepareAndEmitSoundToAll(m_SpawnSound,client);

            new spawn_level=GetUpgradeLevel(client, raceId, upgradeId);
            new num_built = CountObjects(client, TF2_ObjectClassNames[type]);
            new Float:cooldown = GetUpgradeCooldown(raceId, upgradeId) * float(4-spawn_level+((num_built > 1) ? num_built * 2 : 1));
            CreateCooldown(client, raceId, upgradeId, cooldown);

            if (m_AmpNodeAvailable)
            {
                if (type == TFExtObject_Amplifier)
                {
                    ConvertToAmplifier(obj, client, TFCond_Buffed, m_SpawnAmpRange[level]);
                }
                else if (type == TFExtObject_RepairNode)
                {
                    ConvertToRepairNode(obj, client, m_SpawnNodeRange[level],
                                        m_SpawnNodeRegen[level], m_SpawnNodeShells[level],
                                        m_SpawnNodeRockets[level], .team=(spawn_level>2));
                }
                /*else if (type == TFExtObject_UpgradeStation)
                {
                    ConvertToUpgradeStation(obj);
                }*/
            }
        }
    }
}

public Action:OnBuildCommand(client,TFObjectType:type,mode,count)
{
    if (GetRace(client) == m_spawnRaceId && IsClientInGame(client) &&
        TF2_GetPlayerClass(client) == TFClass_Engineer)
    {
        // always allow 2 teleporters or 1 of everything else without cost
        new max = (type == TFObject_Teleporter) ? 1 : 0;
        if (count > max)
        {
            if (CanInvokeUpgrade(client, m_spawnRaceId, m_spawnUpgradeId))
            {
                PrepareAndEmitSoundToAll(m_SpawnSound,client);
                CreateCooldown(client, m_spawnRaceId, m_spawnUpgradeId);
            }
            else
                return Plugin_Handled;
        }

        // Make sure to turn off Amplifiers after (possibly) building one!
        if (m_AmpNodeAvailable && type == TFObject_Dispenser)
        {
            CreateTimer(5.0,ResetAmplifier,GetClientUserId(client),
                        TIMER_FLAG_NO_MAPCHANGE);
        }
    }

    return Plugin_Continue;
}

public Action:ResetAmplifier(Handle:timer,any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0 && m_AmpNodeAvailable)
        SetAmplifier(client, .enable=false);

    return Plugin_Stop;
}

public Action:OnAmplify(builder,client,TFCond:condition)
{
    if (condition == TFCond_Buffed && builder > 0 && GetRace(builder) == m_spawnRaceId)
    {
        new Float:energy = GetEnergy(client);
        if (energy < 4.0)
            return Plugin_Stop;
        else
            SetEnergy(client, energy-4.0);
    }

    return Plugin_Continue;
}
