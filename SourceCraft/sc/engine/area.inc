/**
 * vim: set ai et ts=4 sw=4 :
 * File: area.inc
 * Description: Area processing
 * Author(s): -=|JFH|=-Naris
 */

#include "sc/area"

// Handles
new Handle:g_OnAreaExpiredHandle = INVALID_HANDLE;
new Handle:m_PlayerAreaTrie[MAXPLAYERS+1];
new Handle:m_PlayerAreaArray[MAXPLAYERS+1];

new Handle:m_AuraList = INVALID_HANDLE;
CreateAura(Float:distance, Float:interval=1.0,
           AreaType:type=Area_Team, priority=0, const String:name[]="",
           Float:beaconColor[4] = { 0, 0, 0, 0 },
           const String:beamModel[]="",
           const String:haloModel[]="")
{
    TraceInto("Area", "CreateArea", "distance=%f", \
              distance);

    new auraId = 0;

    if (distance > 0.0)
    {
        new Handle:pack = CreateDataPack();
        if (pack != INVALID_HANDLE)
        {
            WritePackFloat(pack, distance);
            WritePackFloat(pack, interval);
            WritePackCell(pack, _:type);
            WritePackCell(pack, priority);
            WritePackString(pack, name);

            if (m_AuraList == INVALID_HANDLE)
            {
                m_AuraList = CreateArray();

                TraceCat("Array", "CreateArray m_AuraList=0x%08x", \
                         m_AuraList);
            }

            auraId = PushArrayCell(m_AuraList, pack);
        }
    }

    TraceReturn("auraId=%d", auraId);
    return auraId;
}

ApplyAura(client, auraID,bool:auraOriginatesFromPlayer=true,level=1);

IsInAura(client, auraID, &level);

forward OnAura(client, auraID, bool:inAura, level);

CreateArea(client, race, upgrade, Float:distance, Float:interval=1.0,
           AreaType:type=Area_Team, priority=0, const String:name[]="",
           Float:beaconColor[4] = { 0, 0, 0, 0 })
{
    TraceInto("Area", "CreateArea", "client=%d:%N, race=%d, upgrade=%d, distance=%f", \
              client, ValidClientIndex(client), race, upgrade, distance);

    new areaID = 0;

    if (distance > 0.0)
    {
        new Handle:pack = CreateDataPack();
        if (pack != INVALID_HANDLE)
        {
            WritePackCell(pack, client);
            WritePackCell(pack, GetClientUserId(client));
            WritePackCell(pack, race);
            WritePackCell(pack, upgrade);
            WritePackFloat(pack, distance);
            WritePackFloat(pack, interval);
            WritePackCell(pack, _:type);
            WritePackCell(pack, priority);
            WritePackString(pack, name);

            new Handle:array = m_PlayerAreaArray[client];
            if (array == INVALID_HANDLE)
            {
                array = m_PlayerAreaArray[client] = CreateArray();

                TraceCat("Array", "CreateArray m_PlayerAreaArray[%d]=0x%08x", \
                         client,array);
            }

            areaID = PushArrayCell(array, pack);
        }
    }

    TraceReturn("areaID=%d", areaID);
    return areaID;
}

AreaSpawn(client)
{
    new race = GetRace(client);
    new Handle:raceHandle = GetRaceHandle(race);
    new upgradeCount=GetUpgradeCount(raceHandle);
    for (new upgrade=0;upgrade<upgradeCount;upgrade++)
    {
        new AreaType:type = GetUpgradeAreaType(raceHandle,upgrade);
        if ((type & Area_CreateOnSpawn) == Area_CreateOnSpawn)
        {
            new Float:cooldown = GetUpgradeAreaDuration(raceHandle,upgrade);
            if (cooldown > 0.0)
            {
                decl String:name[64];
                GetUpgradeName(raceHandle, upgrade, name, sizeof(name), client);
                CreateArea(client, race, upgrade, cooldown, name, type, "");
            }
        }
    }
}

AreaEvent(client, AreaType:resetBits)
{
    TraceInto("Area", "AreaEvent", "client=%d:%N, resetBits=0x%02x", \
              client, ValidClientIndex(client), resetBits);

    new Handle:array = m_PlayerAreaArray[client];
    if (array != INVALID_HANDLE)
    {
        // Iterate backwards since we will be removing elements.
        for (new i = GetArraySize(array)-1; i >= 0 ; i--)
        {
            new Handle:pack = Handle:GetArrayCell(array, i);
            ResetPack(pack);

            ReadPackCell(pack); // index
            new userid = ReadPackCell(pack);
            new race = ReadPackCell(pack);
            new upgrade = ReadPackCell(pack);
            new Float:expireTime = ReadPackFloat(pack);
            new AreaType:type = AreaType:ReadPackCell(pack);
            new Handle:timerHandle = Handle:ReadPackCell(pack);

            new bool:remove = (GetClientOfUserId(userid) != client);
            if (remove || ((type & resetBits) != Area_TimerOnly &&
                           expireTime > GetGameTime()))
            {
                new Action:result = Plugin_Continue;
                Call_StartForward(g_OnAreaExpiredHandle);
                Call_PushCell(client);
                Call_PushCell(race);
                Call_PushCell(upgrade);
                Call_PushCell(false);
                Call_Finish(result);

                if (remove || result == Plugin_Continue)
                {
                    new Handle:trie = m_PlayerAreaTrie[client];
                    if (trie != INVALID_HANDLE)
                    {
                        decl String:key[SHORT_STRING_LENGTH];
                        Format(key, sizeof(key), "%d-%d", race, upgrade);
                        RemoveFromTrie(trie, key);
                    }

                    RemoveFromArray(array, i);

                    if (timerHandle != INVALID_HANDLE)
                    {
                        KillTimer(timerHandle, true);

                        TraceCat("Array", "CloseDataTimer Area[%d,%d,%d]=0x%08x; pack=0x%08x", \
                                 client, race, upgrade, timerHandle, pack);
                    }
                    else
                    {
                        CloseHandle(pack);

                        TraceCat("Array", "CloseDataPack Area[%d,%d,%d]=0x%08x; pack=0x%08x", \
                                 client, race, upgrade, timerHandle, pack);
                    }
                }
            }
        }
    }

    TraceReturn();
}

AreaDisconnect(client)
{
    TraceInto("Area", "AreaDisconnect", "client=%d:%N", \
              client, ValidClientIndex(client));

    new Handle:trie = m_PlayerAreaTrie[client];
    if (trie != INVALID_HANDLE)
    {
        ClearTrie(trie);
        CloseHandle(trie);
        m_PlayerAreaTrie[client] = INVALID_HANDLE;

        TraceCat("Array", "CloseTrie m_PlayerAreaTrie[%d]=0x%08x", \
                 client,trie);
    }

    new Handle:array = m_PlayerAreaArray[client];
    if (array != INVALID_HANDLE)
    {
        // Iterate backwards for consistency.
        for (new i = GetArraySize(array)-1; i >= 0 ; i--)
        {
            new Handle:pack = Handle:GetArrayCell(array, i);
            ResetPack(pack);
            ReadPackCell(pack); // index
            ReadPackCell(pack); // userid
            new race = ReadPackCell(pack); // race
            new upgrade = ReadPackCell(pack); // upgrade
            ReadPackFloat(pack); // expireTime
            ReadPackCell(pack); // AreaType:type
            new Handle:timerHandle = Handle:ReadPackCell(pack);

            #if !defined _TRACE
                #pragma unused race, upgrade
            #endif

            if (timerHandle != INVALID_HANDLE)
            {
                KillTimer(timerHandle, true);

                TraceCat("Array", "CloseDataTimer Area[%d,%d,%d]=0x%08x; pack=0x%08x", \
                         client, race, upgrade, timerHandle, pack);
            }
            else
            {
                CloseHandle(pack);

                TraceCat("Array", "CloseDataPack Area[%d,%d,%d]=0x%08x; pack=0x%08x", \
                         client, race, upgrade, timerHandle, pack);
            }
        }

        ClearArray(array);
        CloseHandle(array);
        m_PlayerAreaArray[client] = INVALID_HANDLE;

        TraceCat("Array", "CloseArray m_PlayerAreaArray[%d]=0x%08x", \
                 client,array);
    }

    TraceReturn();
}

ResetAllAreas()
{
    for (new i = 1; i <= MaxClients; i++)
        AreaDisconnect(i);
}

ResetArea(client, race, upgrade, bool:notify)
{
    TraceInto("Area", "ResetArea", "client=%d:%N, race=$d, upgrade=%d, notify=%d", \
              client, ValidClientIndex(client), race, upgrade, notify);

    new Handle:trie = m_PlayerAreaTrie[client];
    if (trie != INVALID_HANDLE)
    {
        decl String:key[SHORT_STRING_LENGTH];
        Format(key, sizeof(key), "%d-%d", race, upgrade);

        new Handle:pack;
        if (GetTrieValue(trie, key, pack))
        {
            ResetPack(pack);
            ReadPackCell(pack); // index
            ReadPackCell(pack); // userid
            ReadPackCell(pack); // race
            ReadPackCell(pack); // upgrade
            ReadPackFloat(pack); // expireTime
            new AreaType:type = AreaType:ReadPackCell(pack);
            new Handle:timerHandle = Handle:ReadPackCell(pack);

            new Action:result = Plugin_Continue;
            Call_StartForward(g_OnAreaExpiredHandle);
            Call_PushCell(client);
            Call_PushCell(race);
            Call_PushCell(upgrade);
            Call_PushCell(false);
            Call_Finish(result);

            if (result == Plugin_Continue)
            {
                if ((type & (Area_ExpireNotify|Area_AlwaysNotify)) != Area_TimerOnly)
                {
                    if (IsClientInGame(client) && IsPlayerAlive(client))
                    {
                        if (notify || (type & Area_AlwaysNotify) != Area_TimerOnly)
                        {
                            decl String:name[NAME_STRING_LENGTH];
                            ReadPackString(pack, name, sizeof(name));

                            decl String:expireSound[LONG_STRING_LENGTH];
                            ReadPackString(pack, expireSound, sizeof(expireSound));

                            if (!name[0])
                            {
                                new Handle:raceHandle=GetRaceHandle(race);
                                new upgradeCategory = GetUpgradeCategory(raceHandle, upgrade);
                                if (upgradeCategory > 1)
                                    Format(name,sizeof(name),"Ultimate%d",upgradeCategory);
                                else if (upgradeCategory == 1)
                                    strcopy(name, sizeof(name), "Ultimate");
                                else
                                    strcopy(name, sizeof(name), "Upgrade");
                            }

                            if (expireSound[0])
                            {
                                PrepareAndEmitSoundToClient(client, expireSound);
                            }
                            else
                            {
                                PrepareAndEmitSoundToClient(client, rechargeWav);
                            }

                            DisplayMessage(client, Display_Ultimate,
                                           "%t", "IsReady", name);
                        }
                    }
                }

                RemoveFromTrie(trie, key);

                new Handle:array = m_PlayerAreaArray[client];
                if (array != INVALID_HANDLE)
                {
                    new item = FindValueInArray(array, pack);
                    if (item >= 0)
                        RemoveFromArray(array, item);
                }

                if (timerHandle != INVALID_HANDLE)
                {
                    KillTimer(timerHandle, true);

                    TraceCat("Array", "CloseDataTimer Area[%d,%d,%d]=0x%08x; pack=0x%08x", \
                             client, race, upgrade, timerHandle, pack);
                }
                else
                {
                    CloseHandle(pack);

                    TraceCat("Array", "CloseDataPack Area[%d,%d,%d]=0x%08x; pack=0x%08x", \
                             client, race, upgrade, timerHandle, pack);
                }
            }
        }
    }

    TraceReturn();
}

public Action:TransfusionTimer(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (IsValidClientAlive(client))
    {
        if (GetRace(client) == raceID)
        {
            new healing_aura_level = GetUpgradeLevel(client,raceID,healingID);
            new Float:healing_range = g_HealingRange[healing_aura_level];

            new transfusion_level = GetUpgradeLevel(client,raceID,transfusionID);
            new Float:transfusion_range = g_TransfusionRange[transfusion_level];

            new detecting_level = GetUpgradeLevel(client,raceID,detectorID);
            new Float:detecting_range = g_DetectingRange[detecting_level];

            if ((healing_aura_level <= 0 && transfusion_level <= 0 && detecting_level <= 0) ||
                GetRestriction(client, Restriction_NoUpgrades) ||
                GetRestriction(client, Restriction_Stunned))
            {
                ResetDetection(client);
            }
            else
            {
                static const healingColor[4] = {0, 255, 0, 255};
                new Float:indexLoc[3];
                new Float:clientLoc[3];
                GetClientAbsOrigin(client, clientLoc);
                clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

                decl String:upgradeName[64];
                GetUpgradeName(raceID, detectorID, upgradeName, sizeof(upgradeName), client);

                new count=0;
                new alt_count=0;
                new list[MaxClients+1];
                new alt_list[MaxClients+1];
                new team=GetClientTeam(client);
                new auraAmount = healing_aura_level*5;
                for (new index=1;index<=MaxClients;index++)
                {
                    if (index != client && IsClientInGame(index))
                    {
                        new bool:alive = IsPlayerAlive(index);
                        GetClientAbsOrigin(index, indexLoc);

                        if (GetClientTeam(index) == team)
                        {
                            if (!GetSetting(index, Disable_Beacons) &&
                                !GetSetting(index, Remove_Queasiness))
                            {
                                if (GetSetting(index, Reduce_Queasiness))
                                    alt_list[alt_count++] = index;
                                else
                                    list[count++] = index;
                            }

                            if (alive && (transfusion_level > 0 || healing_aura_level > 0) &&
                                TraceTargetIndex(client, index, clientLoc, indexLoc))
                            {
                                if (transfusion_level > 0)
                                {
                                    if (IsPointInRange(clientLoc,indexLoc,transfusion_range))
                                    {
                                        new SupplyTypes:type;
                                        if (GameType == dod)
                                        {
                                            new pick = GetRandomInt(0,10);
                                            type = (pick > 6) ? SupplyDefault :
                                                   (pick > 3) ? SupplySecondary
                                                              : (SupplyGrenade|SupplySmoke);
                                        }
                                        else
                                        {
                                            type = (GetRandomInt(0,10) > 5) ? SupplyDefault : SupplySecondary;
                                        }

                                        SupplyAmmo(index, transfusion_level, "Transfusion", type);
                                    }
                                }

                                if (healing_aura_level > 0)
                                {
                                    if (IsPointInRange(clientLoc,indexLoc,healing_range))
                                    {
                                        new health=GetClientHealth(index);
                                        new max=GetMaxHealth(index);
                                        if (health < max)
                                            HealPlayer(index,auraAmount,health,max);
                                    }
                                }
                            }
                        }
                        else
                        {
                            if (detecting_level > 0)
                            {
                                if (alive && IsPointInRange(clientLoc,indexLoc,detecting_range) &&
                                    TraceTargetIndex(client, index, clientLoc, indexLoc))
                                {
                                    new bool:uncloaked = false;
                                    if (GetGameType() == tf2 &&
                                        !GetImmunity(index,Immunity_Uncloaking) &&
                                        TF2_GetPlayerClass(index) == TFClass_Spy)
                                    {
                                        TF2_RemoveCondition(index, TFCond_Cloaked);

                                        uncloaked = true;
                                        HudMessage(index, "%t", "UncloakedHud");
                                        DisplayMessage(index, Display_Enemy_Message, "%t",
                                                       "HasUncloaked", client, upgradeName);
                                    }

                                    if (!GetImmunity(index,Immunity_Detection))
                                    {
                                        SetOverrideVisiblity(index, 255);
                                        if (m_SidewinderAvailable)
                                            SidewinderDetectClient(index, true);

                                        if (!m_Detected[client][index])
                                        {
                                            m_Detected[client][index] = true;
                                            ApplyPlayerSettings(index);
                                        }

                                        if (!uncloaked)
                                        {
                                            HudMessage(index, "%t", "DetectedHud");
                                            DisplayMessage(index, Display_Enemy_Message, "%t",
                                                           "HasDetected", client, upgradeName);
                                        }
                                    }
                                }
                                else // undetect
                                {
                                    SetOverrideVisiblity(index, -1);
                                    if (m_SidewinderAvailable)
                                        SidewinderDetectClient(index, false);

                                    if (m_Detected[client][index])
                                    {
                                        m_Detected[client][index] = false;
                                        ApplyPlayerSettings(index);
                                        ClearDetectedHud(index);
                                    }
                                }
                            }
                        }
                    }
                }

                if (!GetSetting(client, Disable_Beacons) &&
                    !GetSetting(client, Remove_Queasiness))
                {
                    if (GetSetting(client, Reduce_Queasiness))
                        alt_list[alt_count++] = client;
                    else
                        list[count++] = client;
                }

                static const transfusionColor[4] = {255, 225, 0, 255};
                static const detectColor[4] = {202, 225, 255, 255};
                clientLoc[2] -= 50.0; // Adjust position back to the feet.

                if (count > 0)
                {
                    if (transfusion_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, 10.0, transfusion_range, BeamSprite(), HaloSprite(),
                                              0, 15, 0.5, 5.0, 0.0, transfusionColor, 10, 0);
                        TE_Send(list, count, 0.0);
                    }

                    if (detecting_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, 10.0, detecting_range, BeamSprite(), HaloSprite(),
                                              0, 10, 0.6, 10.0, 0.5, detectColor, 10, 0);
                        TE_Send(list, count, 0.0);
                    }

                    if (healing_aura_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, 10.0, healing_range, BeamSprite(), HaloSprite(),
                                              0, 5, 0.7, 15.0, 1.0, healingColor, 10, 0);
                        TE_Send(list, count, 0.0);
                    }
                }

                if (alt_count > 0)
                {
                    if (transfusion_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, transfusion_range-10.0, transfusion_range, BeamSprite(), HaloSprite(),
                                              0, 15, 0.5, 5.0, 0.0, transfusionColor, 10, 0);
                        TE_Send(alt_list, alt_count, 0.0);
                    }

                    if (detecting_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, detecting_range-10.0, detecting_range, BeamSprite(), HaloSprite(),
                                              0, 10, 0.6, 10.0, 0.5, detectColor, 10, 0);
                        TE_Send(alt_list, alt_count, 0.0);
                    }

                    if (healing_aura_level > 0)
                    {
                        TE_SetupBeamRingPoint(clientLoc, healing_range-10.0, healing_range, BeamSprite(), HaloSprite(),
                                              0, 5, 0.7, 15.0, 1.0, healingColor, 10, 0);
                        TE_Send(alt_list, alt_count, 0.0);
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}
