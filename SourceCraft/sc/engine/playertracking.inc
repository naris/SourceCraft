/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: playertracking.inc
 * Description: Holds all the storage for players, temporary and long term.
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */

#if defined _player_tracking_included
 #endinput
#endif
#define _player_tracking_included

#define INFO_CLIENT_INDEX               0
#define INFO_DATABASE_IDENT             1
#define INFO_DATABASE_SAVED             2
#define INFO_RACE                       3
#define INFO_PENDING_RACE               4
#define INFO_PENDING_UPGRADE_RESET      5
#define INFO_CREDITS                    6
#define INFO_OVERALL_LEVEL              7
#define INFO_PROPERTIES                 8
#define INFO_SHOPITEMS                  9
#define INFO_IMMUNITIES                10

#define INFO_COUNT                     11

#define RACEINFO_XP                     0
#define RACEINFO_LEVEL                  1
#define RACEINFO_ACTIVE_ULTIMATE        2
#define RACEINFO_UPGRADES               3

#define UPGRADEINFO_LEVEL               0
#define UPGRADEINFO_SAVED_LEVEL         1
#define UPGRADEINFO_COUNT               2

#define TRACKING_PLUGIN_HANDLE          0
#define TRACKING_OVERRIDE_SPEED         1
#define TRACKING_OVERRIDE_GRAVITY       2
#define TRACKING_OVERRIDE_VISIBILITY    3
#define TRACKING_SPEED                  4
#define TRACKING_GRAVITY                5
#define TRACKING_VISIBILITY             6
#define TRACKING_VISIBILITY_TYPE        7
#define TRACKING_VISIBILITY_FACTOR1     8
#define TRACKING_VISIBILITY_FACTOR2     9
#define TRACKING_VISIBILITY_MODE       10
#define TRACKING_VISIBILITY_FX         11
#define TRACKING_VISIBILITY_R          12
#define TRACKING_VISIBILITY_G          13
#define TRACKING_VISIBILITY_B          14

#define TRACKING_COUNT                 15

new Handle:arrayPlayers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

// Global definition
new bool:g_RoundActive = true;

new Handle:g_OnUpgradeLevelChangedHandle = INVALID_HANDLE;
new Handle:g_OnRaceSelectedHandle = INVALID_HANDLE;

new Float:m_BaseSpeed[MAXPLAYERS+1];
new Float:m_StoppedMoving[MAXPLAYERS+1];
new Float:m_CloakTime[MAXPLAYERS+1];
new bool:m_SpeedAltered[MAXPLAYERS+1];
new bool:m_GravityAltered[MAXPLAYERS+1];
new bool:m_VisibilityAltered[MAXPLAYERS+1];

// Function called from db.inc
SavePlayer(Handle:playerHandle);

Handle:CreatePlayer(client)
{
    new Handle:newPlayer=CreateArray();
    if (newPlayer != INVALID_HANDLE)
    {
        PushArrayCell(newPlayer,client); // The first thing is client index
        PushArrayCell(newPlayer,-1); // Database Ident
        PushArrayCell(newPlayer,0); // Saved to Database Flag
        PushArrayCell(newPlayer,0); // Player race
        PushArrayCell(newPlayer,-1); // Pending race
        PushArrayCell(newPlayer,0); // Pending upgrade reset
        PushArrayCell(newPlayer,0); // Credits
        PushArrayCell(newPlayer,0); // Overall Level

        new Handle:properties=CreateArray(); // Player's properties
        PushArrayCell(newPlayer,properties); // (speed,gravity,visibility)

        new Handle:shopitems=CreateArray(); // Player's shop items
        PushArrayCell(newPlayer,shopitems);
        new shopItemCount=GetArraySize(shopVector);
        for(new x=0;x<shopItemCount;x++)
            PushArrayCell(shopitems,0);     // Owns item x

        new Handle:immunities=CreateArray(); // Player's immunities
        PushArrayCell(newPlayer,immunities);
        for(new x=0;x<IMMUNITY_COUNT;x++)
            PushArrayCell(immunities,0);     // Has immunity x

        new raceCount = GetRaceCount();
        for(new race=0;race<raceCount;race++)
        {
            new Handle:raceInfo=CreateArray(); // Player's races
            PushArrayCell(newPlayer,raceInfo);
            PushArrayCell(raceInfo,0); // Race's XP
            PushArrayCell(raceInfo,0); // Race's Level
            PushArrayCell(raceInfo,-1); // Race's Active Ultimate Upgrade 
            new upgradeCount = GetUpgradeCount(GetRaceHandle(race));
            for(new upgrade=0;upgrade<upgradeCount;upgrade++)
            {
                PushArrayCell(raceInfo,0); // Upgrade level
                PushArrayCell(raceInfo,0); // Upgrade level in DB
            }
        }

        // Perform a sanity check.
        if (GetArraySize(newPlayer)==(INFO_COUNT+raceCount))
            arrayPlayers[client] = newPlayer;
        else
        {
            // Something is really wrong!
            newPlayer = INVALID_HANDLE;
            LogError("ERROR: Player %N's data got fubard!", client);
        }
    }
    return newPlayer;
}

Handle:ClonePlayer(Handle:oldPlayer)
{
    new Handle:newPlayer=CreateArray();
    if (newPlayer != INVALID_HANDLE)
    {
        PushArrayCell(newPlayer,GetArrayCell(oldPlayer,INFO_CLIENT_INDEX)); // The first thing is client index
        PushArrayCell(newPlayer,GetArrayCell(oldPlayer,INFO_DATABASE_IDENT)); // Database Ident
        PushArrayCell(newPlayer,0); // Database Save Flag
        PushArrayCell(newPlayer,GetArrayCell(oldPlayer,INFO_RACE)); // Player race
        PushArrayCell(newPlayer,-1); // Pending race
        PushArrayCell(newPlayer,0); // Pending upgrade reset
        PushArrayCell(newPlayer,GetArrayCell(oldPlayer,INFO_CREDITS)); // Credits
        PushArrayCell(newPlayer,GetArrayCell(oldPlayer,INFO_OVERALL_LEVEL)); // Overall Level

        // Skip the lists that don't get saved.
        PushArrayCell(newPlayer,INVALID_HANDLE); // Player's properties
        PushArrayCell(newPlayer,INVALID_HANDLE); // Player's shop items
        PushArrayCell(newPlayer,INVALID_HANDLE); // Player's immunities

        new raceCount = GetRaceCount();
        for(new race=0;race<raceCount;race++)
        {
            new Handle:oldRaceinfo=GetArrayCell(oldPlayer,INFO_COUNT+race);
            new Handle:newRaceinfo=CreateArray(); // Player's races
            PushArrayCell(newPlayer,newRaceinfo);
            PushArrayCell(newRaceinfo,GetArrayCell(oldRaceinfo,RACEINFO_XP));
            PushArrayCell(newRaceinfo,GetArrayCell(oldRaceinfo,RACEINFO_LEVEL));
            PushArrayCell(newRaceinfo,GetArrayCell(oldRaceinfo,RACEINFO_ACTIVE_ULTIMATE));

            new upgradeCount = GetUpgradeCount(GetRaceHandle(race));
            for(new upgrade=0;upgrade<upgradeCount;upgrade++)
            {
                new upgradePos = RACEINFO_UPGRADES+(upgrade*UPGRADEINFO_COUNT);
                PushArrayCell(newRaceinfo, GetArrayCell(oldRaceinfo,upgradePos)); // +UPGRADEINFO_LEVEL
                PushArrayCell(newRaceinfo,GetArrayCell(oldRaceinfo,upgradePos+UPGRADEINFO_SAVED_LEVEL));
            }
        }

        // Perform a sanity check.
        if (GetArraySize(newPlayer)!=(INFO_COUNT+raceCount))
        {
            // Something is really wrong!
            newPlayer = INVALID_HANDLE;
            LogError("ERROR: cloned data got fubard!");
        }
    }
    return newPlayer;
}

ClearPlayerArray()
{
    for(new client=0;client<=MAXPLAYERS;client++)
    {
        new Handle:playerHandle=arrayPlayers[client];
        if (playerHandle != INVALID_HANDLE)
        {
            LogMessage("ClearPlayerArray-Clearing Player #%d", client);
            ClearPlayer(playerHandle);
            arrayPlayers[client] = INVALID_HANDLE;
        }
    }
}

ClearPlayer(Handle:playerHandle)
{
    if (playerHandle != INVALID_HANDLE)
    {
        new Handle:properties=GetArrayCell(playerHandle,INFO_PROPERTIES);
        if (properties != INVALID_HANDLE)
        {
            ClearArray(properties);
            CloseHandle(properties);
        }

        new Handle:shopitems=GetArrayCell(playerHandle,INFO_SHOPITEMS);
        if (shopitems != INVALID_HANDLE)
        {
            ClearArray(shopitems);
            CloseHandle(shopitems);
        }

        new Handle:immunities=GetArrayCell(playerHandle,INFO_IMMUNITIES);
        if (immunities != INVALID_HANDLE)
        {
            ClearArray(immunities);
            CloseHandle(immunities);
        }

        new raceCount = GetRaceCount();
        for(new r=0;r<raceCount;r++)
        {
            new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+r);
            ClearArray(raceInfo);
            CloseHandle(raceInfo);
        }

        ClearArray(playerHandle);
        CloseHandle(playerHandle);
    }
}

Handle:GetPlayerHandle(client)
{
    return arrayPlayers[client];
}

GetClientIndex(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_CLIENT_INDEX);
}

GetDatabaseIdent(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_DATABASE_IDENT);
}

SetDatabaseIdent(Handle:playerHandle,ident)
{
    SetArrayCell(playerHandle,INFO_DATABASE_IDENT,ident);
}

GetDatabaseSaved(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_DATABASE_SAVED);
}

SetDatabaseSaved(Handle:playerHandle,value)
{
    SetArrayCell(playerHandle,INFO_DATABASE_SAVED,value);
}

GetRace(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_RACE);
}

bool:SetRace(Handle:playerHandle,race)
{
    new oldrace=GetArrayCell(playerHandle,INFO_RACE);
    if (race != oldrace)
    {
        SavePlayer(playerHandle);
        SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
        SetArrayCell(playerHandle,INFO_RACE,race);

        new client = GetArrayCell(playerHandle,INFO_CLIENT_INDEX);

        if (GetLevel(playerHandle,race) < 0 ||
            GetXP(playerHandle,race) < 0)
        {
            LoadPlayerRaceData(client, playerHandle, race);
        }

        Call_StartForward(g_OnRaceSelectedHandle);
        Call_PushCell(client);
        Call_PushCell(playerHandle);
        Call_PushCell(oldrace);
        Call_PushCell(race);
        new result;
        Call_Finish(result);
        return true;
    }
    return false;
}

GetPendingRace(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_PENDING_RACE);
}

SetPendingRace(Handle:playerHandle,pend)
{
    SetArrayCell(playerHandle,INFO_PENDING_RACE,pend);
}

GetPendingUpgradeReset(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_PENDING_UPGRADE_RESET);
}

SetPendingUpgradeReset(Handle:playerHandle,pend)
{
    SetArrayCell(playerHandle,INFO_PENDING_UPGRADE_RESET,pend);
}

GetCredits(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_CREDITS);
}

SetCredits(Handle:playerHandle,credits)
{
    SetArrayCell(playerHandle,INFO_CREDITS,credits);
    SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
}

GetOverallLevel(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_OVERALL_LEVEL);
}

SetOverallLevel(Handle:playerHandle,level)
{
    SetArrayCell(playerHandle,INFO_OVERALL_LEVEL,level);
    SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
}

Handle:GetPropertyInfo(Handle:playerHandle)
{
    return GetArrayCell(playerHandle,INFO_PROPERTIES);
}

GetOwnsItem(Handle:playerHandle,item)
{
    if (GetShopItemCount() >= 1)
    {
        new Handle:shopitems=GetArrayCell(playerHandle,INFO_SHOPITEMS);
        if (shopitems != INVALID_HANDLE)
            return GetArrayCell(shopitems,item);
    }
    return 0;
}

SetOwnsItem(Handle:playerHandle,item,owns)
{
    if (GetShopItemCount() >= 1)
    {
        new Handle:shopitems=GetArrayCell(playerHandle,INFO_SHOPITEMS);
        if (shopitems != INVALID_HANDLE)
            SetArrayCell(shopitems,item,owns);
    }
}

GetImmunity(Handle:playerHandle,immunity)
{
    new Handle:immunities=GetArrayCell(playerHandle,INFO_IMMUNITIES);
    if (immunities != INVALID_HANDLE)
        return GetArrayCell(immunities,immunity);
    else
        return -1;
}

SetImmunity(Handle:playerHandle,immunity,imm_state)
{
    new Handle:immunities=GetArrayCell(playerHandle,INFO_IMMUNITIES);
    if (immunities != INVALID_HANDLE)
        SetArrayCell(immunities,immunity,imm_state);
}

GetXP(Handle:playerHandle,race)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
            return GetArrayCell(raceInfo,RACEINFO_XP);
    }
    return 0;
}

SetXP(Handle:playerHandle,race,xp)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            SetArrayCell(raceInfo,RACEINFO_XP,xp);
            SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
        }
    }
}

ResetXP(Handle:playerHandle,race,xp)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        SetArrayCell(raceInfo,RACEINFO_XP,xp);
        SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
        if (GetArrayCell(raceInfo,RACEINFO_LEVEL) < MAX_LEVELS)
        {
            DoLevelCheck(GetArrayCell(playerHandle,INFO_CLIENT_INDEX),
                         playerHandle);
        }
    }
}

GetLevel(Handle:playerHandle,race)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
            return GetArrayCell(raceInfo,RACEINFO_LEVEL);
    }
    return 0;
}

SetLevel(Handle:playerHandle,race,new_level)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            SetArrayCell(raceInfo,RACEINFO_LEVEL,new_level);
            SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
        }
    }
}

ResetLevel(Handle:playerHandle,race,new_level)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new old_level = GetArrayCell(raceInfo,RACEINFO_LEVEL);
            new difference = new_level-old_level;
            if (difference != 0)
            {
                SetArrayCell(raceInfo,RACEINFO_LEVEL,new_level);
                new overall_level = GetArrayCell(playerHandle,INFO_OVERALL_LEVEL);
                SetArrayCell(playerHandle,INFO_OVERALL_LEVEL,overall_level+difference);
                SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
                if (difference < 0)
                {
                    ResetUpgradesNow(GetArrayCell(playerHandle,INFO_CLIENT_INDEX),
                            playerHandle);
                }
                else // (difference > 0)
                {
                    UpgradeMenu(GetArrayCell(playerHandle,INFO_CLIENT_INDEX),
                            playerHandle);
                }
            }
        }
    }
}

GetActiveUltimate(Handle:playerHandle,race)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
            return GetArrayCell(raceInfo,RACEINFO_ACTIVE_ULTIMATE);
    }
    return -1;
}

SetActiveUltimate(Handle:playerHandle,race,upgrade)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
            SetArrayCell(raceInfo,RACEINFO_ACTIVE_ULTIMATE,upgrade);
    }
}

GetUpgradeLevel(Handle:playerHandle,race,upgrade)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new upgradePos = RACEINFO_UPGRADES+(upgrade*UPGRADEINFO_COUNT);
            return GetArrayCell(raceInfo,upgradePos); // +UPGRADEINFO_LEVEL
        }
    }
    return 0;
}

SetUpgradeLevel(Handle:playerHandle,race,upgrade,level)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new upgradePos = RACEINFO_UPGRADES+(upgrade*UPGRADEINFO_COUNT);
            new old=GetArrayCell(raceInfo,upgradePos); // +UPGRADEINFO_LEVEL
            SetArrayCell(raceInfo,upgradePos,level);
            SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
            Call_StartForward(g_OnUpgradeLevelChangedHandle);
            Call_PushCell(GetArrayCell(playerHandle,INFO_CLIENT_INDEX));
            Call_PushCell(playerHandle);
            Call_PushCell(race);
            Call_PushCell(upgrade);
            Call_PushCell(old);
            Call_PushCell(level);
            new result;
            Call_Finish(result);
        }
    }
}

IncrementUpgradeLevel(Handle:playerHandle,race,upgrade,bool:isUltimate)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new upgradePos = RACEINFO_UPGRADES+(upgrade*UPGRADEINFO_COUNT);
            new old=GetArrayCell(raceInfo,upgradePos); // +UPGRADEINFO_LEVEL
            new level=old+1;
            SetArrayCell(raceInfo,upgradePos,level);
            SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
            if (isUltimate)
                SetArrayCell(raceInfo,RACEINFO_ACTIVE_ULTIMATE,upgrade);

            Call_StartForward(g_OnUpgradeLevelChangedHandle);
            Call_PushCell(GetArrayCell(playerHandle,INFO_CLIENT_INDEX));
            Call_PushCell(playerHandle);
            Call_PushCell(race);
            Call_PushCell(upgrade);
            Call_PushCell(old);
            Call_PushCell(level);
            new result;
            Call_Finish(result);
        }
    }
}

LoadUpgradeLevel(Handle:playerHandle,race,upgrade,level)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new upgradePos = RACEINFO_UPGRADES+(upgrade*UPGRADEINFO_COUNT);
            new old=GetArrayCell(raceInfo,upgradePos);
            SetArrayCell(raceInfo,upgradePos,level); // +UPGRADEINFO_LEVEL
            SetArrayCell(raceInfo,upgradePos+UPGRADEINFO_SAVED_LEVEL,level);
            SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
            Call_StartForward(g_OnUpgradeLevelChangedHandle);
            Call_PushCell(GetArrayCell(playerHandle,INFO_CLIENT_INDEX));
            Call_PushCell(playerHandle);
            Call_PushCell(race);
            Call_PushCell(upgrade);
            Call_PushCell(old);
            Call_PushCell(level);
            new result;
            Call_Finish(result);
        }
    }
}

GetUpgradeLevelCount(Handle:playerHandle,race)
{
    new ret=0;
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new upgradeCount = GetUpgradeCount(GetRaceHandle(race));
            new last=RACEINFO_UPGRADES+(upgradeCount*UPGRADEINFO_COUNT);
            for(new x=RACEINFO_UPGRADES; x<last; x += UPGRADEINFO_COUNT)
                ret+=GetArrayCell(raceInfo,x); // +UPGRADEINFO_LEVEL
        }
    }
    return ret;
}

GetSavedUpgradeLevel(Handle:playerHandle,race,upgrade)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new upgradePos = RACEINFO_UPGRADES+(upgrade*UPGRADEINFO_COUNT);
            return GetArrayCell(raceInfo,upgradePos+UPGRADEINFO_SAVED_LEVEL);
        }
    }
    return 0;
}

SetSavedUpgradeLevel(Handle:playerHandle,race,upgrade,level)
{
    if (race >= 0 && GetRaceCount() >= 1)
    {
        new Handle:raceInfo=GetArrayCell(playerHandle,INFO_COUNT+race);
        if (raceInfo != INVALID_HANDLE)
        {
            new upgradePos = RACEINFO_UPGRADES+(upgrade*UPGRADEINFO_COUNT);
            SetArrayCell(raceInfo,upgradePos+UPGRADEINFO_SAVED_LEVEL,level);
            SetArrayCell(playerHandle,INFO_DATABASE_SAVED,0);
        }
    }
}

public Action:PlayerProperties(Handle:timer)
{
    if (g_RoundActive)
    {
        for(new client=0;client<=MAXPLAYERS;client++)
        {
            new Handle:playerHandle=arrayPlayers[client];
            if (playerHandle != INVALID_HANDLE)
            {
                //new client=GetArrayCell(playerHandle,INFO_CLIENT_INDEX);
                if(IsClientInGame(client))
                {
                    new bool:overridePlayerVisibility=false;
                    new bool:overridePlayerGravity=false;
                    new bool:overridePlayerSpeed=false;

                    new Float:gravity=-1.0,Float:speed=-1.0;
                    new visibility=-1,r=-1,g=-1,b=-1;
                    new RenderMode:mode=RenderMode:-1;
                    new RenderFx:fx=RenderFx:-1;
                    new visibilityRank=-1;

                    decl String:wepName[128] = "";
                    GetClientWeapon(client, wepName, 127);

                    new bool:isStill = IsStill(client);

                    new Handle:pinfo=GetArrayCell(playerHandle,INFO_PROPERTIES);
                    for(new y=0;y<GetArraySize(pinfo);y++)
                    {
                        // check which plugin is the highest/lowest bidder, but first, override?
                        new Handle:temp             = GetArrayCell(pinfo,y);
                        new Float:overridespeed     = GetArrayCell(temp,TRACKING_OVERRIDE_SPEED);
                        new Float:overridegravity   = GetArrayCell(temp,TRACKING_OVERRIDE_GRAVITY);
                        new overridevisibility      = GetArrayCell(temp,TRACKING_OVERRIDE_VISIBILITY);
                        new Float:checkSpeed        = GetArrayCell(temp,TRACKING_SPEED);
                        new Float:checkGravity      = GetArrayCell(temp,TRACKING_GRAVITY);
                        new checkVisibility         = GetArrayCell(temp,TRACKING_VISIBILITY);
                        new VisibilityType:type     = GetArrayCell(temp,TRACKING_VISIBILITY_TYPE);
                        new Float:factor1           = GetArrayCell(temp,TRACKING_VISIBILITY_FACTOR1);
                        new Float:factor2           = GetArrayCell(temp,TRACKING_VISIBILITY_FACTOR2);
                        new RenderFx:checkFx        = GetArrayCell(temp,TRACKING_VISIBILITY_FX);
                        new RenderMode:checkMode    = GetArrayCell(temp,TRACKING_VISIBILITY_MODE);
                        new checkR                  = GetArrayCell(temp,TRACKING_VISIBILITY_R);
                        new checkG                  = GetArrayCell(temp,TRACKING_VISIBILITY_G);
                        new checkB                  = GetArrayCell(temp,TRACKING_VISIBILITY_B);

                        if(!overridePlayerSpeed)
                        {
                            if(overridespeed >= 0.0)
                            {
                                speed=overridespeed;
                                overridePlayerSpeed=true;
                            }
                            else if(checkSpeed > speed)
                            {
                                speed=checkSpeed;
                            }
                        }

                        if(!overridePlayerGravity)
                        {
                            if(overridegravity >= 0.0)
                            {
                                gravity=overridegravity;
                                overridePlayerGravity=true;
                                m_GravityAltered[client]=true;
                            }
                            else if(checkGravity >= 0 &&
                                    (gravity < 0.0 || checkGravity < gravity))
                            {
                                gravity=checkGravity;
                                m_GravityAltered[client]=true;
                            }
                        }

                        if(!overridePlayerVisibility)
                        {
                            if(overridevisibility >= 0)
                            {
                                visibility=overridevisibility;
                                overridePlayerVisibility=true;
                                m_VisibilityAltered[client]=true;
                            }
                            else if (checkVisibility >= 0 || _:type >= 0 ||
                                    _:checkFx >= 0 || _:checkMode >= 0)
                            {
                                new checkRank = CalculateVisibility(client, wepName, isStill, checkVisibility,
                                                                    type, factor1, factor2, checkMode, checkFx);

                                if (checkRank >= 0 && (visibilityRank < 0.0 || checkRank < visibilityRank))
                                {
                                    m_VisibilityAltered[client]=true;
                                    visibilityRank=checkRank;
                                    visibility=(checkVisibility < 0) ? 255 : checkVisibility;
                                    mode=(_:checkMode < 0) ? RENDER_NORMAL : checkMode;
                                    fx=(_:checkFx < 0) ? RENDERFX_NONE : checkFx;
                                    r=(_:checkR < 0) ? 255 : checkR;
                                    g=(_:checkG < 0) ? 255 : checkG;
                                    b=(_:checkB < 0) ? 255 : checkB;
                                }
                            }
                        }
                    }

                    if (m_SpeedAltered[client] || overridePlayerSpeed || speed >= 0.0)
                    {
                        if (speed < 0.0)
                            speed = 1.0;

                        if (GameType == tf2)
                        {
                            new Float:classSpeed = GetClassSpeed(client);
                            new Float:curSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed);
                            if (m_BaseSpeed[client] == 0.0)
                                m_BaseSpeed[client] == curSpeed;

                            new Float:newSpeed = classSpeed * speed;
                            if (curSpeed != newSpeed)
                            {
                                SetEntDataFloat(client,m_OffsetMaxSpeed, newSpeed);
                                if (newSpeed == 0.0)
                                    SetEntityMoveType(client, MOVETYPE_NONE);
                                else if (GetEntityMoveType(client) == MOVETYPE_NONE)
                                    SetEntityMoveType(client, MOVETYPE_WALK);
                            }

                            m_SpeedAltered[client] = (speed != 1.0);
                        }
                        else // not tf2
                        {
                            if (GetEntDataFloat(client,m_OffsetSpeed)!=speed)
                                SetEntDataFloat(client,m_OffsetSpeed,speed);
                        }
                    }

                    if (m_VisibilityAltered[client] || overridePlayerVisibility || visibility >= 0)
                    {
                        if (visibility < 0 || visibility >= 255)
                        {
                            ResetVisibility(client);

                            // Visibility is back to normal, Reset the altered flag
                            m_VisibilityAltered[client]=false;
                        }
                        else
                            SetVisibility(client, visibility, mode, fx, r, g, b);
                    }

                    if (m_GravityAltered[client] || overridePlayerGravity || gravity >= 0.0)
                    {
                        if (gravity < 0.0)
                            gravity = 1.0;

                        if (GetEntDataFloat(client,m_OffsetGravity[client]) != gravity)
                            SetEntDataFloat(client,m_OffsetGravity[client], gravity);

                        if (gravity == 1.0)
                        {
                            // Gravity is back to normal, Reset the altered flag
                            m_GravityAltered[client]=false;
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

bool:IsStill(client)
{
    new Float:vecVelocity[3];
    GetEntDataVector(client, m_VelocityOffset, vecVelocity);
    if (vecVelocity[0] == 0.0 && vecVelocity[1] == 0.0 && vecVelocity[2] == 0.0)
    {
        if (!(GetClientButtons(client) & (IN_FORWARD|IN_BACK|IN_MOVELEFT|
                                          IN_MOVERIGHT|IN_SPEED|IN_JUMP|
                                          IN_ATTACK|IN_ATTACK2|IN_ZOOM)))
        {
            if (!(GetPlayerCond(client) & 1))
            {
                if (m_StoppedMoving[client] == 0.0)
                    m_StoppedMoving[client] = GetGameTime();
                return true;
            }
        }
    }
    m_StoppedMoving[client] = 0.0;
    return false;
}

CalculateVisibility(client, const String:wepName[], bool:isStill, &visibility,
                    VisibilityType:type, Float:factor1, Float:factor2,
                    &RenderMode:mode, &RenderFx:fx)
{
    new rank = visibility;

    if (type == TimedInvisibility || type == TimedMeleeInvisibility || type == GraduatedEffects)
    {
        if (!isStill)
            visibility = 255;
        else if (m_CloakTime[client] != 0.0) // Currently Cloaked
        {
            if (factor2 > 0.0 && (GetGameTime() - m_CloakTime[client]) >= factor2) // factor2 == duration
            {
                visibility = 255;
                if (mode == RENDER_NONE)
                    mode = RENDER_NORMAL;
            }
            else if (type != TimedMeleeInvisibility || IsEquipmentMelee(wepName))
            {
                visibility = 0;
                if (mode == RENDER_NORMAL)
                    mode = RENDER_TRANSTEXTURE;
            }
            else
            {
                visibility = 255;
                if (mode == RENDER_NONE)
                    mode = RENDER_NORMAL;
            }
        }
        else // Not Cloaked
        {
            if (factor1 <= 0.0 || (GetGameTime() - m_StoppedMoving[client]) >= factor1) // factor1 == delay
            {
                if (type != TimedMeleeInvisibility || IsEquipmentMelee(wepName))
                {
                    visibility = 0;
                    if (mode == RENDER_NORMAL)
                        mode = RENDER_TRANSTEXTURE;
                }
                else
                {
                    visibility = 255;
                    if (mode == RENDER_NONE)
                        mode = RENDER_NORMAL;
                }
            }
            else
            {
                visibility = 255;
                if (mode == RENDER_NONE)
                    mode = RENDER_NORMAL;
            }
        }

        if (type == GraduatedEffects && visibility == 255)
        {
            fx = RenderFx:((rank / 14) + 1);
            if (fx == RENDERFX_EXPLODE)
                fx = RENDERFX_PULSE_FAST_WIDER;
            else if (fx == RENDERFX_GLOWSHELL)
                fx = RENDERFX_MAX;

            mode = RENDER_TRANSTEXTURE;
        }
        else if (visibility == 0)
            fx = RENDERFX_NONE;
    }
    else //if (type == BasicVisibility)
    {
        if (visibility < 0)
            visibility = 255;

        if (factor1 >= 0.0 && factor1 != 1.0) // factor1 == melee factor
        {
            if (IsEquipmentMelee(wepName))
                visibility = RoundToNearest(float(visibility) * factor1);
        }

        if (factor2 >= 0.0 && factor2 != 1.0) // factor2 == movement factor
        {
            if (isStill)
                visibility = RoundToNearest(float(visibility) * factor2);
        }
    }

    if (mode == RENDER_NONE)
        rank = 0;
    else
    {
        rank = visibility;
        if (mode != RENDER_NORMAL)
        {
            rank--;
            if (fx != RENDERFX_NONE)
                rank -= _:fx;
        }
    }
    return rank;
}

SetVisibility(client, visibility, RenderMode:mode, RenderFx:fx, r, g, b)
{
    if (visibility == 0)
    {
        if (m_CloakTime[client] == 0.0)
            m_CloakTime[client] = GetGameTime(); // Start cloak timer
    }
    else if (m_CloakTime[client] > 0.0) // && visibility > 0)
        m_StoppedMoving[client] = 0.0; // Reset moving timer when cloak expires.

    if (m_OwnerOffset != -1)
    {
        new count=GetEntityCount();
        for (new obj=GetMaxClients()+1; obj < count; obj++)
        {
            if (IsValidEdict(obj))
            {
                if (GetEntDataEnt2(obj,m_OwnerOffset) == client)
                {
                    decl String:name[32] = "";
                    if (!GetEntityNetClass(obj,name,sizeof(name)) ||
                        (!StrEqual(name, "CCaptureFlag") &&
                         !StrEqual(name, "CSniperDot")))
                    {
                        SetEntityRenderColor(obj,r,g,b,visibility);
                        SetEntityRenderMode(obj,mode);
                        SetEntityRenderFx(obj,fx);
                    }
                    /*
                       decl String:clsname[128] = "";
                       GetEdictClassname(obj, clsname, sizeof(clsname));

                    LogMessage("%N has %s(%s)", client, name, clsname);
                    PrintToChat(client,"%c[DEBUG]%c %c%s%c(%s)-%d",
                                COLOR_GREEN,COLOR_DEFAULT,
                                COLOR_TEAM,name,COLOR_DEFAULT,
                                clsname,obj);

                    if (StrEqual(name, "CSniperDot"))
                        DumpSniperDot(client, obj);
                    */
                }
            }
        }
    }
    SetEntityRenderColor(client,r,g,b,visibility);
    SetEntityRenderMode(client,mode);
    SetEntityRenderFx(client,fx);
}

ResetVisibility(client)
{
    if (m_OwnerOffset != -1)
    {
        if(client>0)
        {
            new count=GetEntityCount();
            for(new y=GetMaxClients()+1;y<count;y++)
            {
                if(IsValidEdict(y))
                {
                    if(GetEntDataEnt2(y,m_OwnerOffset)==client)
                    {
                        SetEntityRenderColor(y,255,255,255,255);
                        SetEntityRenderMode(client,RENDER_NORMAL);
                        SetEntityRenderFx(client,RENDERFX_NONE);
                    }
                }
            }
            SetEntityRenderColor(client,255,255,255,255);
            SetEntityRenderMode(client,RENDER_NORMAL);
            SetEntityRenderFx(client,RENDERFX_NONE);
        }
    }
}

