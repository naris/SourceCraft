/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: events.inc
 * Description: The handler for all the source engine events.
 * Author(s): Naris (Murray Wilson)
 * Credits: Anthony Iacono  
 */

#include <particle>
#include <entlimit>
#include <tf2_uber>

new Handle:m_PackageTimer[MAXENTITIES];
new Float:m_PackageEnergy[MAXENTITIES];
new m_PackageRefs[MAXENTITIES];
new m_PackageVictim[MAXENTITIES];
new m_PackageCrystals[MAXENTITIES];
new m_PackagePCrystals[MAXENTITIES];
new m_PackageMoney[MAXENTITIES];
new m_PackageXP[MAXENTITIES];
new m_SpawnRace[MAXPLAYERS+1];
new m_SpawnLevel[MAXPLAYERS+1];

new g_PackageCount = 0;

bool:HookEvents()
{
    if (!HookEventEx("player_spawn",PlayerSpawnEvent))
    {
        LogError("Could not hook the player_spawn event.");
        return false;
    }

    if (!HookEventEx("player_hurt",PlayerHurtPreEvent, EventHookMode_Pre))
    {
        LogError("Could not hook the player_hurt pre-event.");
        return false;
    }

    if (!HookEventEx("player_hurt",PlayerHurtEvent))
    {
        LogError("Could not hook the player_hurt event.");
        return false;
    }

    if (!HookEventEx("player_death",CorrectDeathEvent, EventHookMode_Pre))
    {
        LogError("Could not hook the player_death pre event.");
        return false;
    }

    if (!HookEventEx("player_death",PlayerDeathEvent))
    {
        LogError("Could not hook the player_death event.");
        return false;
    }

    return true;
}

public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname, "func_respawnroom"))	// TF2 Respawn room
    {
        SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
        SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
    }
    else if (StrEqual(classname, "headless_hatman") ||
             StrEqual(classname, "eyeball_boss")    ||
             StrEqual(classname, "merasmus")        ||
             StrEqual(classname, "tank_boss"))
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage);
    }
#if 0 
    else if (strncmp(classname, "obj_", 4) == 0)
        SDKHook(entity, SDKHook_OnTakeDamage, OnObjectTakeDamage);
#endif
}

public SpawnStartTouch(spawn, client)
{
    if (IsClient(client) && IsClientConnected(client) && IsClientInGame(client))
        g_IsInSpawn[client] = true;
}

public SpawnEndTouch(spawn, client)
{
    if (IsClient(client) && IsClientConnected(client) && IsClientInGame(client))
        g_IsInSpawn[client] = false;
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    if (client > 0)
    {
        TraceInto("Events", "PlayerSpawnEvent", "client=%d:%L", \
                  client, ValidClientIndex(client));

        PendingCheck(client);

        new race=GetRace(client);
        new Handle:raceHandle = (race > 0) ? GetRaceHandle(race) : INVALID_HANDLE;

        if (IsFakeClient(client))
        {
            if (raceHandle)
            {
                // Level up the bot?
                new max = GetUpgradeLevelCount(client,race);
                new level = GetLevel(client,race);
                if (level < max)
                {
                    new count = GetUpgradeCount(raceHandle)-1;
                    if (count >= 0 )
                    {
                        // Count the current upgrade levels
                        for(new upgrade=0;upgrade<count;upgrade++)
                        {
                            level -= GetUpgradeLevel(client, race, upgrade);
                        }

                        // And pick which ones to, err, upgrade (if any)...
                        while (level > 0)
                        {
                            new upgrade = GetRandomInt(0, count);
                            new ulevel = GetUpgradeLevel(client, race, upgrade);
                            new maxLevel = GetUpgradeMaxLevel(raceHandle,upgrade);
                            if (ulevel < maxLevel)
                            {
                                SetUpgradeLevel(client, race, upgrade, ++ulevel);
                            }
                            level--;
                        }
                    }
                }
            }
        }
        else
        {
            if (g_FirstSpawn[client])
            {
                CPrintToChat(client, "%t", "Welcome");
                CPrintToChat(client, "%t", "ReportBugs", g_BugURL);

                // Only show them the Intro if they
                // haven't played before
                // (Not found in DB)
                if (GetDatabaseLoaded(client) == DataNotFound)
                    IntroMenu(client);
                else
                    g_FirstSpawn[client]=false;
            }
            else if (GetDatabaseLoaded(client) != DataLoading &&
                     GetUpgradeLevelCount(client,race) < GetLevel(client,race))
            {
                UpgradeMenu(client, UpgradeMode, false);
            }
        }

        new Float:initial = GetInitialEnergy(client);

        Trace("%d:%N's initial energy is %1.0f", \
              client, ValidClientIndex(client), initial);

        if (raceHandle && initial < 0.0)
        {
            initial = GetRaceInitialEnergy(raceHandle);

            #if defined _TRACE
                decl String:rname[64]; GetRaceName(GetRaceHandle(race),rname,sizeof(rname));
                Trace("Race %d:%s's initial energy is %d", race, rname, initial);
            #endif
        }

        if (initial < 0.0)
            initial = 0.0;

        SetEnergy(client, initial);

        // Stash values of resources we might drop on death.
        m_SpawnRace[client]        = GetRace(client);
        m_SpawnLevel[client]       = GetLevel(client,m_SpawnRace[client]);
        m_PackageXP[client]        = GetXP(client,m_SpawnRace[client]);
        m_PackageMoney[client]     = GetMoney(client);
        m_PackageCrystals[client]  = GetCrystals(client);
        m_PackagePCrystals[client] = GetPCrystals(client);
        m_PackageEnergy[client]    = GetEnergy(client);

        Trace("Setting %d:%N's energy to %d", \
              client, ValidClientIndex(client), initial);

        if (GetDatabaseLoaded(client) >= DataOK)
        {
            ShowXP(client);
            ShowCrystals(client);
            ShowVespene(client);
            ShowEnergy(client);
        }

        #if defined _TRACE
            if (GameType == tf2)
            {
                new hp = m_BaseHealth[client] = m_SpawnHealth[client] = GetClientHealth(client);
                new Float:speed = m_BaseSpeed[client] = m_SpawnSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
                TraceCat("Speed", "%d:%N spawned with %d hp and speed=%1.0f", client, ValidClientIndex(client), hp, speed);
            }
        #endif

        g_IsInSpawn[client] = true;
        g_InjuredBy[client] = 0;
        g_KilledBy[client] = 0;
        g_Killed[client] = false;
        g_Dead[client] = false;

        if (m_IsChangingClass[client])
            m_IsChangingClass[client]=false;
        else
            CooldownEvent(client, Cooldown_ResetOnSpawn);

        CooldownSpawn(client);

        new Action:result;
        Call_StartForward(g_OnPlayerSpawnEventHandle);
        Call_PushCell(event);
        Call_PushCell(client);
        Call_PushCell(race);
        Call_Finish(result);

        CreateHUDTimer(client);
        CreatePropertyTimer(client);

        #if defined TRACK_DAMAGE
            CreateHealthTimer(client);
        #endif

        TraceReturn();
    }
}

public Action:OnJetpack(client)
{
    if (GetRestriction(client,Restriction_Grounded))
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action:OnWeaponSwitch(client, weapon)
{
    #if defined _TRACE
        decl String:sWeapon[32];
        GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

        TraceInto("Events", "OnWeaponSwitch", "client=%d:%L, weapon=%d:%s", \
                  client, ValidClientIndex(client), weapon, sWeapon);

        new Float:speed = m_BaseSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
        TraceCat("Speed", "%d:%N's speed=%1.0f", client, ValidClientIndex(client), speed);
    #endif

    UpdatePlayerProperties(client);

    #if defined _TRACE
        TraceReturn();                  
    #endif

    return Plugin_Continue;
}

public Action:OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
    static bool:inTakeDamage = false;
    new    Action:result     = Plugin_Continue;

    #if defined _TRACE
        static count = 0;
    #endif

    if (IsClient(victim))
    {
        SetTraceCategory("Event");
        TraceInto("Events", "OnTakeDamage", "count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d", \
                  count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, damage, damagetype);

        if (IsClient(attacker) && attacker != victim &&
            GetImmunity(victim, Immunity_RangedAttacks) &&
            !IsInRange(attacker,victim,300.0))
        {
            Trace("%N was protected by Immunity to Ranged Attacks in OnTakeDamage, damage was %f", victim, damage);

            DisplayMessage(victim, Display_Defense, "%t", "YouWereProtected", attacker);
            DisplayMessage(attacker, Display_Enemy_Defended, "%t", "TargetWasProtected", victim);

            if (GameType == tf2 && GetGameMode() != MvM)
            {
                decl Float:pos[3];
                GetClientEyePosition(victim, pos);
                pos[2] += 4.0;
                TE_SetupParticle("miss_text", pos);
                TE_SendToClient(attacker);
            }

            TraceReturn("return=Plugin_Handled");
            return Plugin_Handled;
        }

        if (g_bSupressOnPlayerTakeDamage)
        {
            Trace("Supressing TakeDamage Forward: %d:%N was damaged by %d:%N for %f", \
                  victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), \
                  damage);

            g_bSupressOnPlayerTakeDamage = false;
        }
        else if (!inTakeDamage)
        {
            Trace("OnPlayerTakeDamage: %d:%N was damaged by %d:%N for %f", \
                  victim, ValidClientIndex(victim), \
                  attacker, ValidClientIndex(attacker), \
                  damage);

            inTakeDamage = true;
            Call_StartForward(g_OnPlayerTakeDamageHandle);
            Call_PushCell(victim);
            Call_PushCellRef(attacker);
            Call_PushCellRef(inflictor);
            Call_PushFloatRef(damage);
            Call_PushCellRef(damagetype);
            Call_Finish(result);
            inTakeDamage = false;
        }

        TraceReturn("count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d, result=%d", \
                    count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, \
                    damage, damagetype, result);
    }
    else
    {
        SetTraceCategory("Event");
        TraceInto("Events", "OnTakeDamage", "count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d", \
                  count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, damage, damagetype);

        if (!inTakeDamage)
        {
            Trace("OnEntityTakeDamage: %d was damaged by %d:%N for %f", \
                  victim, attacker, ValidClientIndex(attacker), \
                  damage);

            inTakeDamage = true;
            Call_StartForward(g_OnEntityTakeDamageHandle);
            Call_PushCell(victim);
            Call_PushCellRef(attacker);
            Call_PushCellRef(inflictor);
            Call_PushFloatRef(damage);
            Call_PushCellRef(damagetype);
            Call_Finish(result);
            inTakeDamage = false;
        }

        TraceReturn("count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d, result=%d", \
                    count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, \
                    damage, damagetype, result);
    }

    #if defined _TRACE
        count++;
    #endif

    return result;
}

public Action:OnEntityTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
    static bool:inTakeDamage = false;
    new    Action:result     = Plugin_Continue;

    #if defined _TRACE
        static count = 0;
    #endif

    SetTraceCategory("Event");
    TraceInto("Events", "OnEntityTakeDamage", "count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d", \
              count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, damage, damagetype);

    if (!inTakeDamage)
    {
        Trace("OnEntityTakeDamage: %d was damaged by %d:%N for %f", \
              victim, attacker, ValidClientIndex(attacker), \
              damage);

        inTakeDamage = true;
        Call_StartForward(g_OnEntityTakeDamageHandle);
        Call_PushCell(victim);
        Call_PushCellRef(attacker);
        Call_PushCellRef(inflictor);
        Call_PushFloatRef(damage);
        Call_PushCellRef(damagetype);
        Call_Finish(result);

        // Don't simulate hurt events for npc entities since they fire npc_hurt

        inTakeDamage = false;
    }

    TraceReturn("count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d, result=%d", \
                count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, \
                damage, damagetype, result);

    #if defined _TRACE
        count++;
    #endif

    return result;
}

public Action:OnObjectTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
    static bool:inTakeDamage = false;
    new    Action:result     = Plugin_Continue;

    #if defined _TRACE
        static count = 0;
    #endif

    SetTraceCategory("Event");
    TraceInto("Events", "OnObjectTakeDamage", "count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d", \
              count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, damage, damagetype);

    if (!inTakeDamage)
    {
        new builder = GetEntPropEnt(victim, Prop_Send, "m_hBuilder");

        Trace("OnObjectTakeDamage: %d was damaged by %d:%N for %f", \
              victim, attacker, ValidClientIndex(attacker), \
              damage);

        inTakeDamage = true;
        Call_StartForward(g_OnObjectTakeDamageHandle);
        Call_PushCell(victim);
        Call_PushCell(builder);
        Call_PushCellRef(attacker);
        Call_PushCellRef(inflictor);
        Call_PushFloatRef(damage);
        Call_PushCellRef(damagetype);
        Call_Finish(result);

#if 0
        if (result == Plugin_Continue && IsClient(attacker))
        {
            // Simulate a sourcecraft entity hurt handler for objects
            ProcessEntityHurt(INVALID_HANDLE, victim, attacker, RoundToNearest(damage));
        }
#endif

        inTakeDamage = false;
    }

    TraceReturn("count=%d, victim=%d:%L, attacker=%d:%L, inflictor=%d, damage=%f, damagetype=%d, result=%d", \
                count, victim, ValidClientIndex(victim), attacker, ValidClientIndex(attacker), inflictor, \
                damage, damagetype, result);

    #if defined _TRACE
        count++;
    #endif

    return result;
}

ProcessEntityHurt(Handle:event, victim_index, attacker_index, damage)
{
    new Action:result = Plugin_Continue;
    new attacker_race = GetRace(attacker_index);

    Call_StartForward(g_OnEntityHurtEventHandle);
    Call_PushCell(event);
    Call_PushCell(victim_index);
    Call_PushCell(attacker_index);
    Call_PushCell(attacker_race);
    Call_PushCell(damage);
    Call_Finish(result);

    if (result == Plugin_Continue)
    {
        Call_StartForward(g_OnPlayerHurtEventHandle);
        Call_PushCell(event);
        Call_PushCell(victim_index);
        Call_PushCell(0);
        Call_PushCell(attacker_index);
        Call_PushCell(attacker_race);
        Call_PushCell(damage);
        Call_PushCell(0);
        Call_PushCell(false);
        Call_Finish(result);
    }

    if (result < Plugin_Handled)
    {
        new assister_index, assister_race;
        if (CheckAssist(attacker_index, assister_index, assister_race) &&
            assister_index > 0)
        {
            new Action:rcassist = Plugin_Continue;
            Call_StartForward(g_OnEntityAssistEventHandle);
            Call_PushCell(event);
            Call_PushCell(victim_index);
            Call_PushCell(assister_index);
            Call_PushCell(assister_race);
            Call_PushCell(damage);
            Call_Finish(rcassist);

            if (rcassist == Plugin_Continue)
            {
                Call_StartForward(g_OnPlayerAssistEventHandle);
                Call_PushCell(event);
                Call_PushCell(victim_index);
                Call_PushCell(0);
                Call_PushCell(assister_index);
                Call_PushCell(assister_race);
                Call_PushCell(damage);
                Call_PushCell(0);
                Call_Finish(rcassist);
            }

            if (result < rcassist)
                result = rcassist;
        }
    }
}

bool:CheckAssist(attacker_index, &assister_index, &assister_race)
{
    // Check for an "assister" (Medic ubering/criting/healing)
    new numHealers = TF2_GetNumHealers(attacker_index);

    Trace("numHealers=%d, pcond=%08x", numHealers, \
          TF2_GetPlayerConditionLowBits(attacker_index));

    if (numHealers > 0 ||
        TF2_IsPlayerUbercharged(attacker_index) ||
        TF2_IsPlayerKritzkrieged(attacker_index) ||
        TF2_IsPlayerHealing(attacker_index))
    {
        for(new index=1;index<=MaxClients;index++)
        {
            if (IsClientInGame(index))
            {
                if (TF2_GetHealingTarget(index) == attacker_index)
                {
                    assister_index = index;
                    assister_race  = GetRace(index);

                    Trace("assister_index=%d:%L", \
                          assister_index, ValidClientIndex(assister_index));
                    return true;
                }
            }
        }
    }
    return false;
}

public Action:PlayerHurtPreEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victim_index = GetClientOfUserId(GetEventInt(event,"userid"));

    TraceInto("Events", "PlayerHurtPreEvent", "victim_index=%d:%L", \
              victim_index, ValidClientIndex(victim_index));

    if (IsClient(victim_index))
    {
        // Don't damage dead people!
        if (g_Killed[victim_index] || g_Dead[victim_index])
        {
            TraceReturn("return=Plugin_Handled");
            return Plugin_Handled;
        }

        new attacker_index = GetClientOfUserId(GetEventInt(event,"attacker"));
        if (attacker_index > 0 && attacker_index != victim_index &&
            GetImmunity(victim_index, Immunity_RangedAttacks) &&
            !IsInRange(attacker_index,victim_index,300.0))
        {
            #if defined _TRACE
                new health = GetClientHealth(victim_index);
                new damage = GetDamage(event, victim_index);
                Trace("%N was protected by Immunity to Ranged Attacks in PlayerHurtPreEvent, health was left at %d, damage was %d", victim_index, health, damage);
            #endif

            DisplayMessage(victim_index, Display_Defense, "%t", "YouWereProtected", attacker_index);
            DisplayMessage(attacker_index, Display_Enemy_Defended, "%t", "TargetWasProtected", victim_index);

            new assister_index = GetClientOfUserId(GetEventInt(event,"assister"));
            if (assister_index > 0)
            {
                DisplayMessage(assister_index, Display_Enemy_Defended, "%t",
                               "TargetWasProtected", victim_index);
            }

            TraceReturn("return=Plugin_Handled");
            return Plugin_Handled;
        }
    }

    TraceReturn("return=Plugin_Continue");
    return Plugin_Continue;
}

public Action:PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new Action:result = Plugin_Continue;
    new victim_index = GetClientOfUserId(GetEventInt(event,"userid"));
    if (IsClient(victim_index))
    {
        new damage = GetDamage(event, victim_index);
        new attacker_index = GetClientOfUserId(GetEventInt(event,"attacker"));

        TraceInto("Events", "PlayerHurtEvent", "victim_index=%d:%L, attacker_index=%d:%L, damage=%d", \
                  victim_index, ValidClientIndex(victim_index), attacker_index, \
                  ValidClientIndex(attacker_index), damage);

        new injured_by = g_InjuredBy[victim_index];
        if (injured_by == attacker_index)
            g_InjuredBy[victim_index] = 0;

        if ((attacker_index > 0 && attacker_index != victim_index &&
             GetImmunity(victim_index, Immunity_RangedAttacks) &&
             !IsInRange(attacker_index,victim_index,300.0)))
        {
            new health = GetClientHealth(victim_index) + damage;
            SetEntityHealth(victim_index, health);
            SetEventInt(event, "health", health);
            result = Plugin_Changed;

            #if defined TRACK_DAMAGE
                SetSavedHealth(victim_index, health);
            #endif

            Trace("%N was protected by Immunity to Ranged Attacks in PlayerHurtEvent, health was restored to %d, damage was %d", victim_index, health, damage);

            if (attacker_index && attacker_index != victim_index)
            {
                DisplayMessage(victim_index, Display_Defense, "%t", "YouWereProtected", attacker_index);
                DisplayMessage(attacker_index, Display_Enemy_Defended, "%t", "TargetWasProtected", victim_index);
            }
            else
            {
                DisplayMessage(victim_index, Display_Defense, "%t", "ProtectedFromDamage");
            }
        }
        else
        {
            new amount = 0;
            new absorbed = GetEventInt(event, "absorbed");
            new armor = GetArmor(victim_index);
            if (armor > 0)
            {
                new all_damage = damage+absorbed;
                amount = RoundFloat(float(all_damage)
                         * GetRandomFloat(m_ArmorPercent[victim_index][0],
                                          m_ArmorPercent[victim_index][1]));

                if (amount > 0)
                {
                    if (amount > armor)
                        amount = armor;

                    if (absorbed < amount)
                    {
                        new delta = amount-absorbed;
                        new newhp = GetClientHealth(victim_index)+delta;
                        new maxhp = GetMaxHealth(victim_index);
                        if (newhp > maxhp)
                            newhp = maxhp;

                        damage -= delta;
                        absorbed += delta;
                        m_Armor[victim_index] -= delta;

                        SetEntityHealth(victim_index,newhp);
                    }

                    result = Plugin_Changed;

                    TraceCat("Armor", "%d:%N's armor absorbed %d/%d of %d/%d, burrowed=%d, m_ArmorPercent=%1.2f,%1.2f, m_ArmorName='%s'", \
                             victim_index,ValidClientIndex(victim_index), amount, absorbed, all_damage, damage, \
                             GetAttribute(victim_index, Attribute_IsBurrowed), \
                             m_ArmorPercent[victim_index][0], \
                             m_ArmorPercent[victim_index][1], \
                             m_ArmorName[victim_index]);

                    DisplayMessage(victim_index, Display_Defense, "%t", "ArmorAbsorbed",
                                   m_ArmorName[victim_index], (amount > absorbed) ? amount : absorbed);
                }
            }

            new victim_race   = GetRace(victim_index);
            new attacker_race = (attacker_index > 0) ? GetRace(attacker_index) : 0;
            new bool:from_sc  = (injured_by == attacker_index) ||
                                GetEventBool(event, "sourcecraft");

            Call_StartForward(g_OnPlayerHurtEventHandle);
            Call_PushCell(event);
            Call_PushCell(victim_index);
            Call_PushCell(victim_race);
            Call_PushCell(attacker_index);
            Call_PushCell(attacker_race);
            Call_PushCell(damage);
            Call_PushCell(absorbed);
            Call_PushCell(from_sc);
            Call_Finish(result);

            if (!from_sc && GameType == tf2 && result < Plugin_Handled &&
                attacker_index > 0 && victim_index != attacker_index)
            {
                new assister_index, assister_race;
                if (CheckAssist(attacker_index, assister_index, assister_race) &&
                    assister_index > 0)
                {
                    Call_StartForward(g_OnPlayerAssistEventHandle);
                    Call_PushCell(event);
                    Call_PushCell(victim_index);
                    Call_PushCell(victim_race);
                    Call_PushCell(assister_index);
                    Call_PushCell(assister_race);
                    Call_PushCell(damage);
                    Call_PushCell(absorbed);
                    Call_Finish(result);
                }
            }

            if (amount > 0)
                result = Plugin_Changed;

            #if defined TRACK_DAMAGE
                if (result != Plugin_Continue)
                {
                    if (attacker_index)
                        SaveHealth(attacker_index);

                    if (assister_index)
                        SaveHealth(assister_index);
                }

                new health = SaveHealth(victim_index);
                if (result != Plugin_Continue)
                    SetEventInt(event, "health", health);
            #else
                if (result != Plugin_Continue)
                    SetEventInt(event, "health", GetClientHealth(victim_index));
            #endif
        }

        TraceReturn("result=%d", result);
    }

    g_bDamageFromPlayerHurt = false;
    return result;
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victim = GetEventInt(event,"userid");
    new victim_index = GetClientOfUserId(victim);
    if (victim_index > 0 && !g_Dead[victim_index])
    {
        new customkill;
        new deathFlags;
        new bool:backstab;
        new bool:headshot;

        g_InjuredBy[victim_index] = 0;
        g_KilledBy[victim_index] = 0;

        if (GameType == cstrike)
        {
            backstab   = false;
            headshot   = GetEventBool(event,"headshot");
            customkill = headshot ? TF_CUSTOM_HEADSHOT : 0;
            deathFlags = 0;
        }
        else if (GameType == dod)
        {
            backstab   = false;
            headshot   = GetEventBool(event,"headshot");
            customkill = headshot ? TF_CUSTOM_HEADSHOT : 0;
            deathFlags = 0;
        }
        else if (GameType == tf2)
        {
            deathFlags = GetEventInt(event, "death_flags");
            if (deathFlags & TF_DEATHFLAG_DEADRINGER)
            {
                g_Dead[victim_index] = false;
                g_Killed[victim_index] = false;
                return;			//skip dead ringer / FakeDeath
            }
            else
            {
                customkill = GetEventInt(event,"customkill");
                if (customkill != TF_CUSTOM_FISH_KILL &&
                    GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH)
                {
                    g_Dead[victim_index] = false;
                    g_Killed[victim_index] = false;
                    return; // skip fishy kill
                }
                else
                {
                    headshot = (customkill == TF_CUSTOM_HEADSHOT);
                    backstab = (customkill == TF_CUSTOM_BACKSTAB);
                }
            }
        }

        new victim_race=(victim_index > 0) ? GetRace(victim_index) : -1;

        new attacker_index=GetClientOfUserId(GetEventInt(event,"attacker"));
        new attacker_race=(attacker_index > 0) ? GetRace(attacker_index) : -1;

        new assister_index=GetClientOfUserId(GetEventInt(event,"assister"));
        new assister_race=(assister_index > 0) ? GetRace(assister_index) : -1;

        decl String:weapon[64];
        new bool:is_equipment = GetWeapon(event, attacker_index,
                                          weapon, sizeof(weapon));

        KillHUDTimer(victim_index);
        KillPropertyTimer(victim_index);

        #if defined TRACK_DAMAGE
            KillHealthTimer(victim_index);
        #endif

        ResetInvulnerability(victim_index);
        SetImmunity(victim_index,Immunity_RangedAttacks,false);
        ResetPlayerProperties(victim_index);

        // Clear HUD Message
        m_HudMessage[victim_index][0] = '\0';
        ClearSyncHud(victim_index, m_HudSynch[3]);

        new damage     = GetDamage(event, victim_index);
        new bool:melee = backstab || IsMelee(weapon, is_equipment,
                                             attacker_index,
                                             victim_index);

        new Action:result;
        Call_StartForward(g_OnPlayerDeathEventHandle);
        Call_PushCell(event);
        Call_PushCell(victim_index);
        Call_PushCell(victim_race);
        Call_PushCell(attacker_index);
        Call_PushCell(attacker_race);
        Call_PushCell(assister_index);
        Call_PushCell(assister_race);
        Call_PushCell(damage);
        Call_PushString(weapon);
        Call_PushCell(is_equipment);
        Call_PushCell(customkill);
        Call_PushCell(headshot);
        Call_PushCell(backstab);
        Call_PushCell(melee);
        Call_Finish(result);

        if (GetGameType() == tf2 &&
            g_PackageCount < g_iMaxPackages &&
            !IsEntLimitReached(.client=victim_index,
                               .message="Unable to spawn anymore packages"))
        {
            // Determine if player earned resources this life and if he should drop any
            new money;
            new drop_money = 0;
            if (GetGameMode() != MvM)
            {
                // Don't drop money in MvM
                money = GetMoney(victim_index);
                if (money > m_PackageMoney[victim_index])
                {
                    drop_money = GetRandomInt(g_iDropMoneyBias, money-m_PackageMoney[victim_index]);
                    if (drop_money < 0)
                        drop_money = 0;
                    else if (drop_money > g_iMaxDropMoney)
                        drop_money = g_iMaxDropMoney;
                }
            }

            new crystals = GetCrystals(victim_index);
            new drop_crystals = 0;
            if (crystals > m_PackageCrystals[victim_index])
            {
                drop_crystals = GetRandomInt(g_iDropCrystalBias, crystals-m_PackageCrystals[victim_index]);
                if (drop_crystals < 0)
                    drop_crystals = 0;
                else if (drop_crystals > g_iMaxDropCrystals)
                    drop_crystals = g_iMaxDropCrystals;
            }

            new pcrystals = GetPCrystals(victim_index);
            new drop_pcrystals = 0;
            if (pcrystals > m_PackagePCrystals[victim_index])
            {
                drop_pcrystals = GetRandomInt(g_iDropCrystalBias, pcrystals-m_PackagePCrystals[victim_index]);
                if (drop_pcrystals < 0)
                    drop_pcrystals = 0;
                else if (drop_pcrystals > g_iMaxDropPCrystals)
                    drop_pcrystals = g_iMaxDropPCrystals;
            }

            new xp;
            new drop_xp = 0;
            new race = GetRace(victim_index);
            new level = GetLevel(victim_index,race);
            if (race == m_SpawnRace[victim_index] && level == m_SpawnLevel[victim_index])
            {
                // Don't drop any XP if the race or level changed
                xp = GetXP(victim_index,race);
                if (xp > m_PackageXP[victim_index])
                {
                    drop_xp = GetRandomInt(g_iDropXPBias,xp-m_PackageXP[victim_index]);
                    if (drop_xp < 0)
                        drop_xp = 0;
                    else if (drop_xp > g_iMaxDropXP)
                        drop_xp = g_iMaxDropXP;
                }
            }

            if (drop_money > 0 || drop_crystals > 0 || drop_xp > 0)
            {
                new package = CreateEntityByName("prop_physics_override");
                if (package > 0 && IsValidEntity(package))
                {
                    new n;
                    if (GetGameMode() == MvM)
                        n = 3;
                    else
                    {
                        new drop = drop_money + drop_crystals + drop_xp;
                        if (drop > 100)
                            n = 3;
                        else if (drop > 50)
                            n = 2;
                        else if (drop > 25)
                            n = 1;
                        else
                            n = 0;
                    }

                    SetEntityModel(package, mdlPackage[n]);
                    DispatchSpawn(package);

                    new Float:origin[3];
                    GetClientAbsOrigin(victim_index, origin);

                    new Float:angles[3];
                    GetClientEyeAngles(victim_index, angles);

                    new Float:velocity[3];
                    GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
                    NormalizeVector(velocity,velocity);
                    ScaleVector(velocity,350.0);

                    TeleportEntity(package, origin, angles, velocity);

                    m_PackageMoney[package] = drop_money;
                    if (drop_money > 0)
                        SetMoney(victim_index, money - drop_money);

                    m_PackageCrystals[package] = drop_crystals;
                    if (drop_crystals > 0)
                        SetCrystals(victim_index, crystals - drop_crystals);

                    m_PackagePCrystals[package] = drop_pcrystals;
                    if (drop_pcrystals > 0)
                        SetPCrystals(victim_index, crystals - drop_pcrystals);

                    m_PackageEnergy[package] = GetEnergy(victim_index);

                    m_PackageXP[package] = drop_xp;
                    if (drop_xp > 0)
                        SetXP(victim_index, race, xp - drop_xp);

                    g_PackageCount++;
                    m_PackageVictim[package] = victim; // userid
                    m_PackageRefs[package] = EntIndexToEntRef(package);
                    SDKHook(package, SDKHook_Touch, OnPackageTouched);
                    m_PackageTimer[package] = CreateTimer(g_fPackageDuration, RemoveDroppedPackage,
                                                          package, TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }

        if (attacker_index != victim_index)
        {
            if (attacker_index > 0)
            {
                if (GetClientTeam(attacker_index) != GetClientTeam(victim_index))
                {
                    GiveKillCrystals(attacker_index);
                    GiveKillXP(attacker_index, victim_index,
                               headshot, backstab, melee,
                               ((deathFlags & TF_DEATHFLAG_KILLERDOMINATION) != 0),
                               ((deathFlags & TF_DEATHFLAG_KILLERREVENGE) != 0),
                               false);
                }
            }

            #if defined TRACK_DAMAGE
                SaveHealth(attacker_index);
            #endif

            if (assister_index > 0 && assister_index != attacker_index)
            {
                if (GetClientTeam(assister_index) != GetClientTeam(victim_index))
                {
                    GiveKillCrystals(assister_index);
                    GiveKillXP(assister_index, victim_index,
                               headshot, backstab, melee,
                               ((deathFlags & TF_DEATHFLAG_ASSISTERDOMINATION) != 0),
                               ((deathFlags & TF_DEATHFLAG_ASSISTERREVENGE) != 0),
                               true);
                }

                #if defined TRACK_DAMAGE
                    SaveHealth(assister_index);
                #endif
            }
        }

        if (victim_index > 0)
        {
            new Float:initial = GetInitialEnergy(victim_index);
            if (initial < 0.0 && victim_race > 0)
                initial = GetRaceInitialEnergy(GetRaceHandle(victim_race));

            // Accumulate energy and zero the players active energy.
            new Float:energy = GetEnergy(victim_index) - initial;
            if (energy > 0.0 && victim_race > 0)
                IncrementAccumulatedEnergy(victim_index, victim_race, energy);

            SetEnergy(victim_index, 0.0);

            // Check for pending race change.
            new race = GetRace(victim_index);
            if (race > 0)
            {
                if (PendingCheck(victim_index) < 0)
                {
                    new Handle:raceHandle = GetRaceHandle(race);
                    new parentRace = GetRaceParentId(raceHandle);
                    if (parentRace > 0)
                    {
                        // Revert back to Parent race after death as a Summoned race.
                        // (Set pending race to the parent)
                        ChangeRace(victim_index, parentRace, GetRaceHandle(parentRace), false, false);
                        race = 0; // and skip upgrade check below.
                    }
                }

                if (GetDatabaseLoaded(victim_index) != DataLoading &&
                    GetUpgradeLevelCount(victim_index,race) < GetLevel(victim_index,race))
                {
                    UpgradeMenu(victim_index, UpgradeMode, false);
                }
            }
        }

        #if defined TRACK_DAMAGE
            SaveHealth(victim_index);
        #endif

        g_Dead[victim_index] = true;

        CooldownEvent(victim_index, Cooldown_ResetOnDeath);

        if (IsFakeClient(victim_index))
        {
            // Should the Bot buy a mole?
            new amount = GetCrystals(victim_index);
            if (GetRandomInt(0,100) >= ((amount >= 100) ? 10 : 50))
            {
                new mole = FindShopItem("mole");
                if (mole >= 0)
                {
                    new Handle:moleHandle = GetShopItemHandle(mole);
                    if (moleHandle && amount >= GetItemCrystals(moleHandle))
                        PurchaseShopItem(victim_index, mole);
                }
            }
        }
    }

    g_bDamageFromPlayerHurt = false;
}

public Action:OnPackageTouched(package, client)
{
    if (IsValidClientAlive(client) && package > 0 && IsValidEdict(package) &&
        EntRefToEntIndex(m_PackageRefs[package]) == package)
    {
        AcceptEntityInput(package, "kill");
        m_PackageRefs[package] = INVALID_ENT_REFERENCE;
        g_PackageCount--;

        new Handle:timer = m_PackageTimer[package];
        if (timer != INVALID_HANDLE)
        {
            PrepareAndEmitSoundToClient(client, sndPickup, .channel=SNDCHAN_WEAPON);

            CloseHandle(m_PackageTimer[package]);
            m_PackageTimer[package] = INVALID_HANDLE;

            new origin = m_PackageVictim[package];

            new money = m_PackageMoney[package];
            if (money > 0)
            {
                SetMoney(client, GetMoney(client) + money);
                m_PackageMoney[package] = 0;
            }

            new crystals = m_PackageCrystals[package];
            new pcrystals = m_PackagePCrystals[package];
            if (client == origin)
            {
                if (crystals > 0)
                {
                    GiveCrystals(client, crystals, "Recovered");
                    m_PackageCrystals[package] = 0;
                }

                if (pcrystals > 0)
                {
                    GivePCrystals(client, pcrystals, "Recovered");
                    m_PackagePCrystals[package] = 0;
                }
            }
            else
            {
                if (crystals > 0 ||pcrystals > 0)
                {
                    GiveCrystals(client, crystals +pcrystals, "Package");
                    m_PackageCrystals[package] = 0;
                    m_PackagePCrystals[package] = 0;
                }

                new Float:energy = m_PackageEnergy[package];
                new Float:extra  = GetRandomFloat(0.0, 10.0) - GetEnergy(client);
                if (extra > 0)
                    energy += extra;

                if (energy > 0)
                {
                    IncrementEnergy(client,energy);
                    m_PackageEnergy[package] = 0.0;
                }
            }

            new xp = m_PackageXP[package];
            if (xp > 0)
            {
                GiveXP(client, xp, (client == origin) ? "Recovered" : "Package");
                m_PackageXP[package] = 0;
            }
        }
    }
}

public Action:RemoveDroppedPackage(Handle:timer, any:package)
{
    if (EntRefToEntIndex(m_PackageRefs[package]) == package &&
        IsValidEdict(package))
    {
        AcceptEntityInput(package, "kill");
        m_PackageRefs[package] = INVALID_ENT_REFERENCE;
        g_PackageCount--;

        if (m_PackageTimer[package] == timer)
        {
            m_PackageTimer[package] = INVALID_HANDLE;

            new client = GetClientOfUserId(m_PackageVictim[package]);
            if (IsValidClient(client))
            {
                PrepareAndEmitSoundToClient(client, sndPickup, .channel=SNDCHAN_WEAPON);

                new money = m_PackageMoney[package];
                if (money > 0)
                    SetMoney(client, GetMoney(client) + money);

                new crystals = m_PackageCrystals[package];
                if (crystals > 0)
                    GiveCrystals(client, crystals, "Recovered");

                new xp = m_PackageXP[package];
                if (xp > 0)
                    GiveXP(client, xp, "Recovered");
            }

            m_PackageCrystals[package] = 0;
            m_PackageMoney[package] = 0;
            m_PackageXP[package] = 0;
        }
    }

    return Plugin_Handled;
}

public Action:CorrectDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victim_index=GetClientOfUserId(GetEventInt(event,"userid"));
    if (victim_index > 0)
    {
        // Don't allow double kills/deaths!
        if (g_Dead[victim_index])
            return Plugin_Handled;
        else
        {
            new attacker_index=GetClientOfUserId(GetEventInt(event,"attacker"));
            new killed_by = g_KilledBy[victim_index];
            if (killed_by != attacker_index && IsValidClient(killed_by) &&
                !GetEventBool(event,"fake"))
            {
                SetEventInt(event,"attacker",GetClientUserId(killed_by));
                g_KilledBy[victim_index] = 0;
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

public PlayerChangeClassEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index = GetClientOfUserId(userid);
        if (IsValidClient(index))
        {
            TraceInto("Events", "PlayerChangeClassEvent", "index=%d:%L", \
                      index, ValidClientIndex(index));

            if (IsPlayerAlive(index))
                m_IsChangingClass[index] = true;

            // Reset energy when changing class
            new Float:initial = GetInitialEnergy(index);

            Trace("%d:%N's initial energy is %1.0f", \
                  index, ValidClientIndex(index), initial);

            new race = GetRace(index);
            if (race > 0)
            {
                new Handle:raceHandle = GetRaceHandle(race);
                if (raceHandle && initial < 0.0)
                {
                    initial = GetRaceInitialEnergy(raceHandle);

                    #if defined _TRACE
                        decl String:rname[64]; GetRaceName(GetRaceHandle(race),rname,sizeof(rname));
                        Trace("Race %d:%s's initial energy is %1.0f", race, rname, initial);
                    #endif
                }
            }

            if (initial < 0.0)
                initial = 0.0;

            SetEnergy(index,initial);

            TraceReturn("Setting %d:%N's energy to %1.0f", \
                        index, ValidClientIndex(index), \
                        initial);
        }
    }
}

public RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundState = RoundStarted;
    g_iRoundNumber++;

    if (GameType == cstrike)
    {
        new Handle:freezeTimeCvar=FindConVar("mp_freezetime");
        if (freezeTimeCvar)
        {
            new Float:fFreezeTime=GetConVarFloat(freezeTimeCvar);
            if (fFreezeTime>0.0)
            {
                CreateTimer(fFreezeTime,EndFreezeTime,g_iRoundNumber);
                g_RoundState = RoundFreeze;
            }
        }
    }

    #if defined _TRACE
        LogRoundEvent(event,name,dontBroadcast);
    #endif

    for(new index=1;index<=MaxClients;index++)
    {
        if (IsClientInGame(index))
            ResetInvulnerability(index);
    }
}

public Action:EndFreezeTime(Handle:timer,any:roundNumber)
{
	if (roundNumber==g_iRoundNumber)
        g_RoundState = RoundActive;
}

public EventRoundActive(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundState = RoundActive;

    #if defined _TRACE
        LogRoundEvent(event,name,dontBroadcast);
    #endif

    for(new index=1;index<=MaxClients;index++)
    {
        if (IsClientInGame(index))
            ResetInvulnerability(index);
    }
}

public EventRoundSuddenDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundState = RoundSuddenDeath;

    #if defined _TRACE
        LogRoundEvent(event,name,dontBroadcast);
    #endif

    for(new index=1;index<=MaxClients;index++)
    {
        m_IsChangingClass[index]=false;
        if (IsClientInGame(index))
            ResetInvulnerability(index);
    }
}

public EventRoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundState = RoundOver;

    #if defined _TRACE
        LogRoundEvent(event,name,dontBroadcast);
    #endif

    for(new index=1;index<=MaxClients;index++)
    {
        m_IsChangingClass[index]=false;
        if (IsClientInGame(index))
            ResetInvulnerability(index);
    }
}

public EventRoundWin(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundState = RoundOver;

    #if defined _TRACE
        LogRoundEvent(event,name,dontBroadcast);
    #endif

    new team  = GetEventInt(event,"team");
    for(new index=1;index<=MaxClients;index++)
    {
        m_IsChangingClass[index]=false;
        if (IsClientInGame(index))
        {
            ResetInvulnerability(index);
            if (GetClientTeam(index) == team)
            {
                GiveRoundWinCrystalsAndGas(index);
                GiveRoundWinXP(index);
            }
        }
    }

    //if (SAVE_ENABLED)
    //    SaveAllPlayersData();
}

public EventGameOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_RoundState = GameOver;
    g_MapChanging = true;

    #if defined _TRACE
        LogRoundEvent(event,name,dontBroadcast);
    #endif
}

public BombPlantedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event,"userid"));
    if (index > 0)
    {
        GivePlantXP(index);
        GivePlantCrystalsAndGas(index);
    }
}

public BombDefusedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event,"userid"));
    if (index > 0)
    {
        GiveDefuseXP(index);
        GiveDefuseCrystalsAndGas(index);
    }
}

public BombExplodedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event,"userid"));
    if (index > 0)
    {
        GiveExplodeXP(index);
        GiveExplodeCrystalsAndGas(index);
    }
}

#if defined _TRACE
    public LogEvent(Handle:event,const String:name[],bool:dontBroadcast)
    {
        SetTraceCategory("Event");
        TraceInto("Events_TF2", "LogEvent");

        if (event == INVALID_HANDLE)
            TraceError("event=%s", name);
        else
        {
            new userid=GetEventInt(event,"userid");
            new entindex=GetEventInt(event,"entindex");
            new index=GetClientOfUserId(userid);
            new player=GetEventInt(event,"player");
            new pindex=GetClientOfUserId(player);
            new team=GetEventInt(event,"team");
            new amount=GetEventInt(event,"amount");
            new type=GetEventInt(event,"type");
            new short=GetEventInt(event,"short");
            new medic=GetEventInt(event,"medic");
            new ownerid=GetEventInt(event,"ownerid");
            new weaponid=GetEventInt(event,"weaponid");
            new buff_type=GetEventInt(event,"buff_type");
            new buff_owner =GetEventInt(event,"buff_owner");
            Trace("event=%s, userid=%d(client=%d:%N), player=%d(client=%d:%N), entindex=%d:%N, team=%d, amount=%d, type=%d, short=%d, medic=%d:%N, ownerid=%d:%N, weaponid=%d,buff_type=%d, buff_owner=%d:%N", \
                  name, userid, index, ValidClientIndex(index), player, pindex, ValidClientIndex(pindex), \
                  entindex, ValidClientIndex(entindex), team, amount, type, short, medic,  \
                  ValidClientIndex(medic), ownerid, ValidClientIndex(ownerid), weaponid, \
                  buff_type, buff_owner, ValidClientIndex(buff_owner));
        }

        TraceReturn();
    }

    public LogRoundEvent(Handle:event,const String:name[],bool:dontBroadcast)
    {
        SetTraceCategory("Event");
        TraceInto("Events_TF2", "LogRoundEvent");

        if (event == INVALID_HANDLE)
            TraceError("event=%s, RoundState=%d(%s)", name, g_RoundState, RoundStateNames[g_RoundState]);
        else
        {
            new team=GetEventInt(event,"team");
            new amount=GetEventInt(event,"amount");
            new type=GetEventInt(event,"type");
            new short=GetEventInt(event,"short");
            Trace("event=%s, RoundState=%d(%s), team=%d, amount=%d, type=%d, short=%d", \
                  name, g_RoundState, RoundStateNames[g_RoundState], team, amount, type, short);
        }

        TraceReturn();
    }

    public LogBuildingEvent(Handle:event,const String:name[],bool:dontBroadcast)
    {
        SetTraceCategory("Event");
        TraceInto("Events_TF2", "LogBuildingEvent");

        if (event == INVALID_HANDLE)
            TraceError("event=%s", name);
        else
        {
            Trace("event=%s, building_type=%d, object_mode=%d, remove=%d, object=%d, index=%d", name, \
                  GetEventInt(event,"building_type"), GetEventInt(event,"object_mode"), \
                  GetEventInt(event,"remove"), GetEventInt(event,"object"), \
                  GetEventInt(event,"index"));
        }

        TraceReturn();
    }
#endif
