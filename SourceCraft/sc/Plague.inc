/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Plague.inc
 * Description: The Zerg Plague upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined plague_included
 #endinput
#endif
#define plague_included

#include <entlimit>

#include "sc/sounds"
#include "sc/PlagueInfect"

stock static m_raceId, m_upgradeId;
stock static String:m_PlagueShort[64];
stock static Handle:m_PlagueTimers[MAXPLAYERS+1];

stock SetupPlague(const String:plagueSound[])
{
    //SetupDeniedSound();
    SetupSound(plagueSound);
}

stock Plague(client, raceId, upgradeId, level, PlagueType:type=NormalPlague,
             bool:targeted=false, Float:plagueRange[], const String:plagueSound[],
             const String:plagueShort[])
{
    if (IsEntLimitReached(.client=client,
                          .message="Unable to spawn anymore plague clouds"))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NoEntitiesAvailable");
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else
    {
        if (GameType == tf2)
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

        if (CanInvokeUpgrade(client, raceId, upgradeId))
        {
            new Float:targetLoc[3];
            if (targeted)
                TraceAimPosition(client, targetLoc, true);
            else
                GetClientAbsOrigin(client, targetLoc);

            new String:originData[64];
            Format(originData, sizeof(originData), "%f %f %f",
                   targetLoc[0], targetLoc[1], targetLoc[2]);

            // Create the Plague Cloud
            new String:size[5];
            new String:name[128];
            Format(size, sizeof(size), "%1.0f", plagueRange[level]);
            Format(name, sizeof(name), "Plague%i", client);
            new cloud = CreateEntityByName("env_smokestack");
            if (cloud > 0 && IsValidEdict(cloud))
            {
                DispatchKeyValue(cloud,"targetname", name);
                DispatchKeyValue(cloud,"Origin", originData);
                DispatchKeyValue(cloud,"BaseSpread", "100");
                DispatchKeyValue(cloud,"SpreadSpeed", "10");
                DispatchKeyValue(cloud,"Speed", "80");
                DispatchKeyValue(cloud,"StartSize", "100");
                DispatchKeyValue(cloud,"EndSize", size);
                DispatchKeyValue(cloud,"Rate", "15");
                DispatchKeyValue(cloud,"JetLength", "400");
                DispatchKeyValue(cloud,"Twist", "4");
                DispatchKeyValue(cloud,"RenderColor", "176 23 31");
                DispatchKeyValue(cloud,"RenderAmt", "100");
                DispatchKeyValue(cloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
                DispatchSpawn(cloud);
                AcceptEntityInput(cloud, "TurnOn");

                PrepareAndEmitSoundToAll(plagueSound, client, .origin=targetLoc);

                decl String:upgradeName[64];
                GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName));
                DisplayMessage(client,Display_Ultimate,"%t", "Invoked", upgradeName);
                CreateCooldown(client, raceId, upgradeId);

                new Float:length = 5.0 * float(level);
                new Handle:entitypack = CreateDataPack();
                WritePackCell(entitypack, EntIndexToEntRef(cloud));
                WritePackCell(entitypack, client);
                CreateTimer(length, RemovePlague, entitypack);

                if (m_PlagueTimers[client] == INVALID_HANDLE)
                {
                    new Handle:pack;
                    m_raceId = raceId;
                    m_upgradeId = upgradeId;
                    strcopy(m_PlagueShort, sizeof(m_PlagueShort), plagueShort);
                    m_PlagueTimers[client] = CreateDataTimer(0.2, PlagueTimer, pack,
                                                             TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                    if (pack != INVALID_HANDLE)
                    {
                        WritePackCell(pack, client);
                        WritePackCell(pack, _:type);
                        WritePackFloat(pack, plagueRange[level]);
                        WritePackFloat(pack, GetEngineTime() + length);
                        WritePackFloat(pack, targetLoc[0]);
                        WritePackFloat(pack, targetLoc[1]);
                        WritePackFloat(pack, targetLoc[2]);
                    }
                }
            }
            else
                LogError("Unable to create plague cloud!");
        }
    }
}

public Action:PlagueTimer(Handle:timer, Handle:pack)
{
    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        new client=ReadPackCell(pack);
        if (IsClientInGame(client))
        {
            if (GetRace(client) == m_raceId)
            {
                new level=GetUpgradeLevel(client,m_raceId,m_upgradeId);
                if (level > 0)
                {
                    new PlagueType:type = PlagueType:ReadPackCell(pack);
                    new Float:range     = ReadPackFloat(pack);
                    new Float:endTime   = ReadPackFloat(pack);

                    new Float:targetLoc[3];
                    targetLoc[0] = ReadPackFloat(pack);
                    targetLoc[1] = ReadPackFloat(pack);
                    targetLoc[2] = ReadPackFloat(pack);

                    new Float:indexLoc[3];
                    new team = GetClientTeam(client);
                    for (new index=1;index<=MaxClients;index++)
                    {
                        if (index != client && IsClientInGame(index) &&
                            IsPlayerAlive(index) && GetClientTeam(index) != team)
                        {
                            if (!GetImmunity(index,Immunity_Ultimates) &&
                                !GetImmunity(index,Immunity_HealthTaking) &&
                                !GetImmunity(index,Immunity_Restore) &&
                                !IsInvulnerable(index))
                            {
                                GetClientAbsOrigin(index, indexLoc);
                                if (IsPointInRange(targetLoc,indexLoc,range) &&
                                    TraceTargetIndex(client, index, targetLoc, indexLoc))
                                {
                                    PlagueInfect(client, index, level * 3, level,
                                                 type, m_PlagueShort);
                                }
                            }
                        }
                    }
                    if (GetEngineTime() < endTime)
                        return Plugin_Continue;
                }
            }
        }
        m_PlagueTimers[client] = INVALID_HANDLE;
    }
    return Plugin_Stop;
}

public Action:RemovePlague(Handle:timer, Handle:entitypack)
{
    ResetPack(entitypack);
    new cloud = EntRefToEntIndex(ReadPackCell(entitypack));
    new client = ReadPackCell(entitypack);

    ResetPlague(client);

    if (cloud > 0 && IsValidEntity(cloud))
    {
        AcceptEntityInput(cloud, "TurnOff");
        CreateTimer(5.0, KillPlague, entitypack);
    }
}

public Action:KillPlague(Handle:timer, Handle:entitypack)
{
    ResetPack(entitypack);

    new cloud = EntRefToEntIndex(ReadPackCell(entitypack));
    if (cloud > 0 && IsValidEntity(cloud))
        AcceptEntityInput(cloud, "Kill");

    CloseHandle(entitypack);
}

stock ResetPlague(client)
{
    if (m_PlagueTimers[client] != INVALID_HANDLE)
    {
        KillTimer(m_PlagueTimers[client], true);
        m_PlagueTimers[client] = INVALID_HANDLE;	
    }
}
