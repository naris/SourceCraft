/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: log.inc
 * Description: Writes message to console and log.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _log_included
 #endinput
#endif
#define _log_included

stock Log(String:message[])
{
    PrintToServer(message);
    LogMessage(message);
}

stock Error(String:message[])
{
    PrintToServer(message);
    LogError(message);
}

stock Fail(String:message[])
{
    PrintToServer(message);
    SetFailState(message);
}

stock LogDamage(client, victim, String:weapon[], String:description[], hp, xp=0)
{
    decl String:steamID[64];
    GetClientAuthString(client,steamID,63);

    decl String:team[64];
    GetTeamName(GetClientTeam(client), team, sizeof(team));

    decl String:victimID[64];
    GetClientAuthString(victim,victimID,63);

    decl String:victimTeam[64];
    GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

    PrintToChat(victim, "%c[SourceCraft] %N %chas damaged you for %d with a %c%s%c",
                COLOR_GREEN,client,COLOR_DEFAULT,hp,COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToChat(client, "%c[SourceCraft] %cYou damaged %N for %d hp with a %c%s%c.",
                COLOR_GREEN,COLOR_DEFAULT,victim, hp, COLOR_TEAM,description,COLOR_DEFAULT);

    PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

    PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

    LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
              client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
}

stock LogKill(client, victim, String:weapon[], String:description[], hp=0, xp=0)
{
    decl String:steamID[64];
    GetClientAuthString(client,steamID,63);

    decl String:team[64];
    GetTeamName(GetClientTeam(client), team, sizeof(team));

    decl String:victimID[64];
    GetClientAuthString(victim,victimID,63);

    decl String:victimTeam[64];
    GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

    PrintToChat(victim, "%c[SourceCraft] %N %c killed you with a %c%s%c",
                COLOR_GREEN,client,COLOR_DEFAULT,COLOR_TEAM,description,COLOR_DEFAULT);

    if (xp)
    {
        PrintToChat(client, "%c[SourceCraft] %cYou gained %d XP for killing %N with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,xp,victim, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

        PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

        LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" fatally injured \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                  client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
    }
    else
    {
        PrintToChat(client, "%c[SourceCraft] %cYou killed %N with a %c%s%c.",
                    COLOR_GREEN,COLOR_DEFAULT,victim, COLOR_TEAM,description,COLOR_DEFAULT);

        PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

        PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s\n",
                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

        LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" fatally injured \"%N<%d><%s><%s>\" with %s\n",
                  client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
    }
}

stock LogEventDamage(Handle:event,damage,const String:source[], race_id)
{
    new userid=GetEventInt(event,"userid");
    new victim=GetClientOfUserId(userid);
    new victim_vec=GetPlayer(victim);
    new victim_race=(victim_vec>-1) ? GetRace(victim_vec) : -1;

    new attacker_uid=GetEventInt(event,"attacker");
    new attacker=GetClientOfUserId(attacker_uid);
    new attacker_vec=GetPlayer(attacker);
    new attacker_race=(attacker_vec>-1) ? GetRace(attacker_vec) : -1;

    new assister_uid = GetEventInt(event,"assister");
    new assister=GetClientOfUserId(assister_uid);
    new assister_vec=GetPlayer(assister);
    new assister_race=(assister_vec>-1) ? GetRace(assister_vec) : -1;

    if (race_id == victim_race   || race_id == attacker_race ||
        race_id == assister_race || race_id < 0)
    {
        new health=0;
        decl String:team[64] = "";
        decl String:steamID[64] = "";
        decl String:attacker_weapon[64] = "";
        if (attacker)
        {
            GetClientAuthString(attacker,steamID,sizeof(steamID));
            GetTeamName(GetClientTeam(attacker), team, sizeof(team));
            GetClientWeapon(attacker, attacker_weapon, sizeof(attacker_weapon));
            health=GetClientHealth(attacker);
        }
        else
            strcopy(steamID,sizeof(steamID), "World");

        decl String:victimID[64];
        GetClientAuthString(victim,victimID,sizeof(victimID));

        decl String:victimTeam[64];
        GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

        new victimHealth=GetClientHealth(victim);

        decl String:event_weapon[64];
        GetEventString(event,"weapon",event_weapon,sizeof(event_weapon));

        new event_damage = GetEventInt(event, "damage");

        if (assister)
        {
            decl String:assisterID[64];
            GetClientAuthString(assister,assisterID,63);

            decl String:assisterTeam[64];
            GetTeamName(GetClientTeam(assister), assisterTeam, sizeof(assisterTeam));

            decl String:assister_weapon[64];
            GetClientWeapon(assister, assister_weapon, sizeof(assister_weapon));

            new assisterHealth=GetClientHealth(assister);

            LogMessage("[%s] \"%N<%d><%s><%s>[%d]\"+\"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s+%s)",
                       source, attacker, attacker, steamID, team, health,
                       assister, assister,assisterID, assisterTeam, assisterHealth,
                       victim, victim, victimID, victimTeam, victimHealth,
                       damage, event_damage, event_weapon, attacker_weapon, assister_weapon);

            LogToGame("[%s] \"%N<%d><%s><%s>[%d]\"+\"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s+%s)",
                      source, attacker, attacker, steamID, team, health,
                      assister, assister,assisterID, assisterTeam, assisterHealth,
                      victim, victim, victimID, victimTeam, victimHealth,
                      damage, event_damage, event_weapon, attacker_weapon, assister_weapon);
        }
        else
        {
            LogMessage("[%s] \"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s)",
                       source, attacker, attacker, steamID, team, health,
                       victim, victim, victimID, victimTeam, victimHealth,
                       damage, event_damage, event_weapon, attacker_weapon);
            LogToGame("[%s] \"%N<%d><%s><%s>[%d]\" damaged \"%N<%d><%s><%s>[%d]\" for %d(%d) with %s(%s)\n",
                      source, attacker, attacker, steamID, team, health,
                      victim, victim, victimID, victimTeam, victimHealth,
                      damage, event_damage, event_weapon, attacker_weapon);
        }
    }
}

stock DumpSniperDot(client, obj)
{
    new Float:m_vecOrigin[3];
    new Float:m_vecMins[3];
    new Float:m_vecMaxs[3];
    new Float:m_vecSpecifiedSurroundingMins[3];
    new Float:m_vecSpecifiedSurroundingMaxs[3];

    //CSniperDot:
    // Sub-Class Table (1 Deep): DT_SniperDot
    //  Sub-Class Table (2 Deep): DT_BaseEntity
    new m_flSimulationTime = GetEntData(obj, FindSendPropInfo("CSniperDot","m_flSimulationTime")); // (bits 8)
    GetEntDataVector(obj, FindSendPropInfo("CSniperDot","m_vecOrigin"), m_vecOrigin);
    new m_nModelIndex = GetEntData(obj, FindSendPropInfo("CSniperDot","m_nModelIndex")); // (bits 11)
    new m_nRenderFX = GetEntData(obj, FindSendPropInfo("CSniperDot","m_nRenderFX")); // (bits 8)
    new m_nRenderMode = GetEntData(obj, FindSendPropInfo("CSniperDot","m_nRenderMode")); // (bits 8)
    new m_fEffects = GetEntData(obj, FindSendPropInfo("CSniperDot","m_fEffects")); // (bits 10)
    new m_clrRender = GetEntData(obj, FindSendPropInfo("CSniperDot","m_clrRender")); // (bits 32)
    new m_iTeamNum = GetEntData(obj, FindSendPropInfo("CSniperDot","m_iTeamNum")); // (bits 6)
    new m_CollisionGroup = GetEntData(obj, FindSendPropInfo("CSniperDot","m_CollisionGroup")); // (bits 5)
    new Float:m_flElasticity = GetEntDataFloat(obj, FindSendPropInfo("CSniperDot","m_flElasticity"));
    new Float:m_flShadowCastDistance = GetEntDataFloat(obj, FindSendPropInfo("CSniperDot","m_flShadowCastDistance")); // (bits 12)
    new m_hOwnerEntity = GetEntDataEnt2(obj, FindSendPropInfo("CSniperDot","m_hOwnerEntity")); // (bits 21)
    new m_hEffectEntity = GetEntDataEnt2(obj, FindSendPropInfo("CSniperDot","m_hEffectEntity")); // (bits 21)
    new moveparent = GetEntDataEnt2(obj, FindSendPropInfo("CSniperDot","moveparent")); // (bits 21)
    new m_iParentAttachment = GetEntData(obj, FindSendPropInfo("CSniperDot","m_iParentAttachment")); // (bits 6)
    new movetype = GetEntData(obj, FindSendPropInfo("CSniperDot","movetype")); // (bits 4)
    new movecollide = GetEntData(obj, FindSendPropInfo("CSniperDot","movecollide")); // (bits 3)
    new m_angRotation = GetEntData(obj, FindSendPropInfo("CSniperDot","m_angRotation")); // (bits 13)
    new m_iTextureFrameIndex = GetEntData(obj, FindSendPropInfo("CSniperDot","m_iTextureFrameIndex")); // (bits 8)
    new bool:m_bSimulatedEveryTick = bool:GetEntData(obj, FindSendPropInfo("CSniperDot","m_bSimulatedEveryTick"));
    new bool:m_bAnimatedEveryTick = bool:GetEntData(obj, FindSendPropInfo("CSniperDot","m_bAnimatedEveryTick"));
    new bool:m_bAlternateSorting = bool:GetEntData(obj, FindSendPropInfo("CSniperDot","m_bAlternateSorting"));
    new Float:m_flChargeStartTime = GetEntDataFloat(obj, FindSendPropInfo("CSniperDot","m_flChargeStartTime"));

    //   Sub-Class Table (3 Deep): DT_AnimTimeMustBeFirst
    new m_flAnimTime = GetEntData(obj, FindSendPropInfo("CSniperDot","m_flAnimTime")); // (bits 8)

    //   Sub-Class Table (3 Deep): DT_CollisionProperty
    GetEntDataVector(obj, FindSendPropInfo("CSniperDot","m_vecMins"), m_vecMins);
    GetEntDataVector(obj, FindSendPropInfo("CSniperDot","m_vecMaxs"), m_vecMaxs);
    new m_nSolidType = GetEntData(obj, FindSendPropInfo("CSniperDot","m_nSolidType")); // (bits 3)
    new m_usSolidFlags = GetEntData(obj, FindSendPropInfo("CSniperDot","m_usSolidFlags")); // (bits 10)
    new m_nSurroundType = GetEntData(obj, FindSendPropInfo("CSniperDot","m_nSurroundType")); // (bits 3)
    new m_triggerBloat = GetEntData(obj, FindSendPropInfo("CSniperDot","m_triggerBloat")); // (bits 8)
    GetEntDataVector(obj, FindSendPropInfo("CSniperDot","m_vecSpecifiedSurroundingMins"), m_vecSpecifiedSurroundingMins);
    GetEntDataVector(obj, FindSendPropInfo("CSniperDot","m_vecSpecifiedSurroundingMaxs"), m_vecSpecifiedSurroundingMaxs);

    //   Sub-Class Table (3 Deep): DT_PredictableId
    new m_PredictableID = GetEntData(obj, FindSendPropInfo("CSniperDot","m_PredictableID")); // (bits 31)
    new bool:m_bIsPlayerSimulated = bool:GetEntData(obj, FindSendPropInfo("CSniperDot","m_bIsPlayerSimulated"));

    LogMessage("m_flSimulationTime=%d",m_flSimulationTime);
    LogMessage("m_vecOrigin=(%d,%d,%d)",m_vecOrigin[0],m_vecOrigin[1],m_vecOrigin[2]);
    LogMessage("m_nModelIndex=%d",m_nModelIndex);
    LogMessage("m_nRenderFX=%d",m_nRenderFX);
    LogMessage("m_nRenderMode=%d",m_nRenderMode);
    LogMessage("m_fEffects=%d",m_fEffects);
    LogMessage("m_clrRender=%d",m_clrRender);
    LogMessage("m_iTeamNum=%d",m_iTeamNum);
    LogMessage("m_CollisionGroup=%d",m_CollisionGroup);
    LogMessage("m_flElasticity=%f",m_flElasticity);
    LogMessage("m_flShadowCastDistance=%f",m_flShadowCastDistance);
    LogMessage("m_hOwnerEntity=%d",m_hOwnerEntity);
    LogMessage("m_hEffectEntity=%d",m_hEffectEntity);
    LogMessage("moveparent=%d",moveparent);
    LogMessage("m_iParentAttachment=%d",m_iParentAttachment);
    LogMessage("movetype=%d",movetype);
    LogMessage("movecollide=%d",movecollide);
    LogMessage("m_angRotation=%d",m_angRotation);
    LogMessage("m_iTextureFrameIndex=%d",m_iTextureFrameIndex);
    LogMessage("m_bSimulatedEveryTick=%d",m_bSimulatedEveryTick);
    LogMessage("m_bAnimatedEveryTick=%d",m_bAnimatedEveryTick);
    LogMessage("m_bAlternateSorting=%d",m_bAlternateSorting);
    LogMessage("m_flChargeStartTime=%d",m_flChargeStartTime);
    LogMessage("m_flAnimTime=%d",m_flAnimTime);
    LogMessage("m_vecMins=(%d,%d,%d)",m_vecMins[0],m_vecMins[1],m_vecMins[2]);
    LogMessage("m_vecMaxs=(%d,%d,%d)",m_vecMaxs[0],m_vecMaxs[1],m_vecMaxs[2]);
    LogMessage("m_nSolidType=%d",m_nSolidType);
    LogMessage("m_usSolidFlags=%d",m_usSolidFlags);
    LogMessage("m_nSurroundType=%d",m_nSurroundType);
    LogMessage("m_triggerBloat=%d",m_triggerBloat);
    LogMessage("m_vecSpecifiedSurroundingMins=(%d,%d,%d)",m_vecSpecifiedSurroundingMins[0],m_vecSpecifiedSurroundingMins[1],m_vecSpecifiedSurroundingMins[2]);
    LogMessage("m_vecSpecifiedSurroundingMaxs=(%d,%d,%d)",m_vecSpecifiedSurroundingMaxs[0],m_vecSpecifiedSurroundingMaxs[1],m_vecSpecifiedSurroundingMaxs[2]);
    LogMessage("m_PredictableID=%d",m_PredictableID);
    LogMessage("m_bIsPlayerSimulated=%d",m_bIsPlayerSimulated);
}
