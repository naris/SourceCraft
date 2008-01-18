/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: playertracking.inc
 * Description: Holds all the storage for players, temporary and long term.
 * Author(s): Anthony Iacono  
 */

#if defined _player_tracking_included
 #endinput
#endif
#define _player_tracking_included

#include <tf2>

#define INFO_COUNT     7 // 0)client index, 1)race, 2)pending race,
                         // 3)pending skill reset, 4)credits,
                         // 5)overall level, 6)tracking array

#define TRACKING_COUNT 11

// Global definition
new Handle:g_OnRaceSelectedHandle;
new Handle:g_OnSkillLevelChangedHandle;

new bool:speedAltered[MAXPLAYERS+1];
new bool:gravityAltered[MAXPLAYERS+1];
new bool:visibilityAltered[MAXPLAYERS+1];

public GetClientVectorPosition(client)
{
    new size=GetArraySize(arrayPlayers);
    for(new x=0;x<size;x++)
    {
        new Handle:ply=GetArrayCell(arrayPlayers,x);
        new curClient=GetArrayCell(ply,0);
        if(client==curClient)
            return x;
    }
    return -1;
}

public GetRace(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,1);
}

public SetRace(vectorpos,race)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new oldrace=GetArrayCell(vec,1);
    if (race != oldrace)
    {
        SetArrayCell(vec,1,race);
        Call_StartForward(g_OnRaceSelectedHandle);
        Call_PushCell(GetArrayCell(vec,0));
        Call_PushCell(vectorpos);
        Call_PushCell(oldrace);
        Call_PushCell(race);
        new result;
        Call_Finish(result);
    }
}

public GetPendingRace(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,2);
}

public SetPendingRace(vectorpos,pend)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,2,pend);
}

public GetPendingSkillReset(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,3);
}

public SetPendingSkillReset(vectorpos,pend)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,3,pend);
}

public GetCredits(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,4);
}

public SetCredits(vectorpos,credits)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,4,credits);
}

public GetOverallLevel(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,5);
}

public SetOverallLevel(vectorpos,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,5,level);
}

public Handle:GetPropertyInfo(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,6);
}

public SetPropertyInfo(vectorpos,Handle:info)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,6,info);
}

public GetImmunity(vectorpos,immunity)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_COUNT+immunity);
}

public SetImmunity(vectorpos,immunity,imm_state)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_COUNT+immunity,imm_state);
}

public GetOwnsItem(vectorpos,item)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+item);
}

public SetOwnsItem(vectorpos,item,owns)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+item,owns);
}

public GetXP(vectorpos,race)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+race);
}

public SetXP(vectorpos,race,xp)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+race,xp);
}

public GetLevel(vectorpos,race)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+RACE_COUNT+race);
}

public SetLevel(vectorpos,race,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+RACE_COUNT+race,level);
}

public GetSkillLevel(vectorpos,race,skill)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new num=INFO_COUNT+SHOPITEM_COUNT+IMMUNITY_COUNT+RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT)+skill;
    return GetArrayCell(vec,num);
}

public SetSkillLevel(vectorpos,race,skill,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new num=INFO_COUNT+SHOPITEM_COUNT+IMMUNITY_COUNT+RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT)+skill;
    new old=GetArrayCell(vec,num);
    SetArrayCell(vec,num,level);
    Call_StartForward(g_OnSkillLevelChangedHandle);
    Call_PushCell(GetArrayCell(vec,0));
    Call_PushCell(vectorpos);
    Call_PushCell(race);
    Call_PushCell(skill);
    Call_PushCell(old);
    Call_PushCell(level);
    new result;
    Call_Finish(result);
}

public GetSkillCount(vectorpos,race)
{
    new ret=0;
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new num1=INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT);
    new num2=INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT)+SKILL_COUNT;
    for(new x=num1;x<num2;x++)
        ret+=GetArrayCell(vec,x);
    return ret;
}

public Action:PlayerProperties(Handle:timer)
{
    for(new x=0;x<GetArraySize(arrayPlayers);x++)
    {
        new Handle:playerHandle=GetArrayCell(arrayPlayers,x);
        new client=GetArrayCell(playerHandle,0);
        if(IsClientInGame(client))
        {
            decl String:wepName[128] = "";
            GetClientWeapon(client, wepName, 127);

            new Float:vecVelocity[3];
            GetEntDataVector(client, m_VelocityOffset, vecVelocity);

            new Handle:pinfo=GetPropertyInfo(x);
            new visibility=255;
            new Float:gravity=1.0,Float:speed=1.0;
            new bool:overridePlayerSpeed=false;
            new bool:overridePlayerGravity=false;
            new bool:overridePlayerVisibility=false;
            for(new y=0;y<GetArraySize(pinfo);y++)
            {
                // check which plugin is the highest/lowest bidder, but first, override?
                new Handle:temp             = GetArrayCell(pinfo,y);
                new Float:checkSpeed        = GetArrayCell(temp,1);
                new Float:checkGravity      = GetArrayCell(temp,2);
                new checkVisibility         = GetArrayCell(temp,3);
                new Float:meleeFactor       = GetArrayCell(temp,4);
                new Float:movementFactor    = GetArrayCell(temp,5);
                new Float:overridespeed     = GetArrayCell(temp,6);
                new Float:overridegravity   = GetArrayCell(temp,7);
                new overridevisibility      = GetArrayCell(temp,8);

                if(!overridePlayerSpeed)
                {
                    if(overridespeed>0.0)
                    {
                        speed=overridespeed;
                        overridePlayerSpeed=true;
                        speedAltered[client]=true;
                    }
                    else if(checkSpeed>speed)
                    {
                        speed=checkSpeed;
                        speedAltered[client]=true;
                    }
                }

                if(!overridePlayerGravity)
                {
                    if(overridespeed>0.0)
                    {
                        gravity=overridegravity;
                        overridePlayerGravity=true;
                        gravityAltered[client]=true;
                    }
                    else if(checkGravity<gravity)
                    {
                        gravity=checkGravity;
                        gravityAltered[client]=true;
                    }
                }

                if(!overridePlayerVisibility)
                {
                    if(overridevisibility>-1)
                    {
                        visibility=overridevisibility;
                        overridePlayerVisibility=true;
                        visibilityAltered[client]=true;
                    }
                    else
                    {
                        checkVisibility = CalculateVisibility(client, wepName, vecVelocity,
                                                              checkVisibility, meleeFactor,
                                                              movementFactor);
                        if (checkVisibility >= 0 && visibility > checkVisibility)
                        {
                            visibility=checkVisibility;
                            visibilityAltered[client]=true;
                        }
                    }
                }
            }

            if (speedAltered[client] || overridePlayerSpeed || speed != 1.0)
            {
                if (GameType == tf2)
                {
                    if (m_BaseSpeed[client] > 1.0 && m_OffsetMaxSpeed[client])
                    {
                        new Float:curSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed[client]);
                        if (curSpeed > 1.0 || speedAltered[client]) // Don't alter initial map freeze
                        {
                            new Float:newSpeed;
                            if (curSpeed < 200.0)
                            {
                                // Speed for heavy  while firing == 80, while not firing == 230
                                // Speed for sniper while zoomed == 80, while not zoomed == 300
                                // ensure we don't accelerate firing heavy or zoomed sniper too much!
                                newSpeed = 80.0 * speed;
                            }
                            else
                            {
                                newSpeed = m_BaseSpeed[client] * speed;
                            }

                            if (curSpeed != newSpeed)
                                SetEntDataFloat(client,m_OffsetMaxSpeed[client], newSpeed);
                        }
                    }
                }
                else
                {
                    if (GetEntDataFloat(client,m_OffsetSpeed)!=speed)
                        SetEntDataFloat(client,m_OffsetSpeed,speed);
                }

                if (speed == 1.0)
                {
                    // Speed is back to normal, Reset the altered flag
                    speedAltered[client]=false;
                }
            }

            if (visibilityAltered[client] || overridePlayerVisibility || (visibility >= 0 && visibility < 255))
            {
                if (visibility < 0 || visibility >= 255)
                {
                    MakeVisible(client);

                    // Visibility is back to normal, Reset the altered flag
                    visibilityAltered[client]=false;
                }
                else
                {
                    MakeInvisible(client, visibility);
                }
            }

            if (gravityAltered[client] || overridePlayerGravity || gravity != 1.0)
            {
                if (GetEntDataFloat(client,m_OffsetGravity[client]) != gravity)
                    SetEntDataFloat(client,m_OffsetGravity[client], gravity);

                if (gravity == 1.0)
                {
                    // Gravity is back to normal, Reset the altered flag
                    gravityAltered[client]=false;
                }
            }
        }
    }
    return Plugin_Continue;
}

stock CalculateVisibility(client, const String:wepName[], const Float:vecVelocity[3], visibility,
                          Float:meleeFactor, Float:movementFactor)
{
    if (meleeFactor != 1.0 && meleeFactor != -1.0)
    {
        if (IsEquipmentMelee(wepName))
            visibility *= meleeFactor;
    }

    if (m_VelocityOffset != -1 && movementFactor != 1.0 && movementFactor != -1.0)
    {
        if (vecVelocity[0] == 0.0 && vecVelocity[1] == 0.0 && vecVelocity[2] == 0.0)
            visibility *= movementFactor;
    }
    return visibility;
}

stock MakeVisible(client)
{
    if (m_OwnerOffset != -1)
    {
        if(client>-1)
        {
            new count=GetEntityCount();
            for(new y=64;y<count;y++)
            {
                if(IsValidEdict(y))
                {
                    if(GetEntDataEnt(y,m_OwnerOffset)==client)
                    SetRenderColor(y,255,255,255,255);
                }
            }
            SetRenderColor(client,255,255,255,255);
        }
    }
}

stock MakeInvisible(client, visibility)
{
    if (m_OwnerOffset != -1)
    {
        new count=GetEntityCount();
        for (new obj = 64; obj < count; obj++)
        {
            if (IsValidEdict(obj))
            {
                if (GetEntDataEnt(obj,m_OwnerOffset) == client)
                {
                    decl String:name[32] = "";
                    if (!GetEntityNetClass(obj,name,sizeof(name)) ||
                        !StrEqual(name, "CCaptureFlag"))
                    {
                        if (!StrEqual(name, "CSniperDot"))
                        {
                            // If the sniper is sniping, make minimum visibility 100
                            // and don't hide the sniper dot!
                            if (visibility < 100)
                                visibility = 100;
                        }
                        else
                            SetRenderColor(obj,255,255,255,visibility);
                    }
                }
            }
        }
    }
    SetRenderColor(client,255,255,255,visibility);
}

stock SetRenderColor(entity,r,g,b,a)
{
	if (m_ColorOffset != -1)
    {
        SetEntData(entity,m_ColorOffset,r,1,true);
        SetEntData(entity,m_ColorOffset+1,g,1,true);
        SetEntData(entity,m_ColorOffset+2,b,1,true);
        SetEntData(entity,m_ColorOffset+3,a,1,true);

        if(m_RenderModeOffset != -1)
            SetEntData(entity,m_RenderModeOffset,3,1,true);
    }
}

public War3Source_SQLTable()
{
    if (DBIDB)
    {
        // Create the tables, if they don;t exist
        if(!SQL_FastQuery(DBIDB,"CREATE TABLE IF NOT EXISTS w3s_players (steamid varchar(64) not null, race varchar(30), credits int default 0, overall_level int default 0, last_update timestamp default current_timestamp, PRIMARY KEY(steamid))"))
        {
            decl String:error[256] = "";
            SQL_GetError(DBIDB, error, sizeof(error));
            LogError("[War3Source] Error in the creation of the w3s_players SQL table:%s", error);
            SetFailState("[War3Source] Error in the creation of the w3s_players SQL table");
        }
        else if(!SQL_FastQuery(DBIDB,"CREATE TABLE IF NOT EXISTS w3s_player_races (steamid varchar(64) not null, race varchar(30) not null, xp int default 0, level int default 0, PRIMARY KEY(steamid,race))"))
        {
            decl String:error[256] = "";
            SQL_GetError(DBIDB, error, sizeof(error));
            LogError("[War3Source] Error in the creation of the w3s_skills SQL table:%s", error);
            SetFailState("[War3Source] Error in the creation of the w3s_skills SQL table");
        }
        else if(!SQL_FastQuery(DBIDB,"CREATE TABLE IF NOT EXISTS w3s_player_skills (steamid varchar(64) not null, race varchar(30) not null, skill int not null, skill_level int default 0,  PRIMARY KEY(steamid,race,skill))"))
        {
            decl String:error[256] = "";
            SQL_GetError(DBIDB, error, sizeof(error));
            LogError("[War3Source] Error in the creation of the w3s_skills SQL table:%s", error);
            SetFailState("[War3Source] Error in the creation of the w3s_skills SQL table");
        }
    }
}

public bool:FetchSQLString(Handle:query,const String:columnname[], String:result[], maxlength)
{
    new column;
    SQL_FieldNameToNum(query,columnname,column);
    if (SQL_IsFieldNull(query, column))
        return false;
    else
        return (SQL_FetchString(query,column,result,maxlength) > 0);
}

public FetchSQLInt(Handle:query,const String:columnname[])
{
    new column;
    SQL_FieldNameToNum(query,columnname,column);
    return SQL_FetchInt(query,column);
}

public War3Source_LoadPlayerData(client,vectorpos)
{
    new bool:fetch=false;
    if(DBIDB)
    {
        decl String:steamid[64] = "";
        if(GetClientAuthString(client,steamid,sizeof(steamid)))
        {
            decl String:buf[256] = "";
            Format(buf,sizeof(buf),
                   "SELECT race, credits, overall_level FROM w3s_players WHERE steamid = '%s'",
                   steamid);

            new Handle:query=SQL_Query(DBIDB,buf);
            if(query)
            {
                fetch = SQL_FetchRow(query);
                if (fetch)
                {
                    decl String:raceName[64]="";
                    SQL_FetchString(query,0,raceName,sizeof(raceName));

                    SetRace(vectorpos,FindRace(raceName));
                    SetCredits(vectorpos,SQL_FetchInt(query,1));
                    SetOverallLevel(vectorpos,SQL_FetchInt(query,2));

                    Format(buf,sizeof(buf),
                           "SELECT race, xp, level FROM w3s_player_races WHERE steamid = '%s'",
                           steamid);

                    new Handle:raceQuery=SQL_Query(DBIDB,buf);
                    if(raceQuery)
                    {
                        while (SQL_FetchRow(raceQuery))
                        {
                            SQL_FetchString(raceQuery,0,raceName,sizeof(raceName));
                            new raceId=FindRace(raceName);

                            SetXP(vectorpos,raceId,SQL_FetchInt(raceQuery,1));
                            SetLevel(vectorpos,raceId,SQL_FetchInt(raceQuery,2));

                            Format(buf,sizeof(buf),
                                   "SELECT skill, skill_level FROM w3s_player_skills WHERE steamid = '%s' and race = '%s'",
                                   steamid,raceName);

                            new Handle:skillQuery=SQL_Query(DBIDB,buf);
                            if(skillQuery)
                            {
                                while (SQL_FetchRow(skillQuery))
                                {
                                    SetSkillLevel(vectorpos,raceId,
                                                  SQL_FetchInt(skillQuery,0),
                                                  SQL_FetchInt(skillQuery,1));
                                }
                                CloseHandle(skillQuery);
                            }
                        }
                        CloseHandle(raceQuery);
                    }
                }
                CloseHandle(query);
            }
        }
    }

    // Return 2 if not fetched so race selection menu will be displayed
    return (fetch) ? 1 : 2;
}

public War3Source_SavePlayerData(client,vectorpos)
{
    if(DBIDB)
    {
        decl String:steamid[64]="";
        if(GetClientAuthString(client,steamid,sizeof(steamid)))
        {
            decl String:raceName[64]="";
            GetRaceShortName(Race(GetRace(vectorpos)), raceName, sizeof(raceName));

            new credits       = GetCredits(vectorpos);
            new overall_level = GetOverallLevel(vectorpos);

            decl String:replaceQuery[512] = "";
            Format(replaceQuery,sizeof(replaceQuery),
                   "REPLACE INTO w3s_players (steamid,race,credits,overall_level,last_update) VALUES ('%s','%s',%d,%d,current_timestamp)",
                   steamid, raceName, credits, overall_level);

            if (!SQL_FastQuery(DBIDB,replaceQuery))
            {
                decl String:error[256] = "";
                SQL_GetError(DBIDB, error, sizeof(error));
                LogError("[War3Source] Unable to replace player: %s\nSQL:%s\n",
                         error, replaceQuery);
                return;
            }

            for(new raceId=0;raceId<RACE_COUNT;raceId++)
            {
                new Handle:race=Race(raceId);
                GetArrayString(race,RACE_SHORT_NAME,raceName,sizeof(raceName));

                new xp    = GetXP(vectorpos,raceId);
                new level = GetLevel(vectorpos,raceId);

                if (xp || level)
                {
                    Format(replaceQuery,sizeof(replaceQuery),
                           "REPLACE INTO w3s_player_races (steamid,race,xp,level) VALUES ('%s','%s',%d,%d)",
                           steamid, raceName, xp, level);

                    if (!SQL_FastQuery(DBIDB,replaceQuery))
                    {
                        decl String:error[256] = "";
                        SQL_GetError(DBIDB, error, sizeof(error));
                        LogError("[War3Source] Unable to replace player's race: %s\nSQL:%s\n",
                                 error, replaceQuery);
                        return;
                    }

                    for(new skill=0;skill<SKILL_COUNT;skill++)
                    {
                        new skillLevel = GetSkillLevel(vectorpos,raceId,skill);
                        if (skilllevel)
                        {
                            Format(replaceQuery,sizeof(replaceQuery),
                                   "REPLACE INTO w3s_player_skills (steamid,race,skill,skill_level) VALUES ('%s','%s',%d,%d)",
                                   steamid, raceName, skill, skillLevel);

                            if (!SQL_FastQuery(DBIDB,replaceQuery))
                            {
                                decl String:error[256] = "";
                                SQL_GetError(DBIDB, error, sizeof(error));
                                LogError("[War3Source] Unable to insert player's skill: %s\nSQL:%s\n",
                                         error, replaceQuery);
                                return;
                            }
                        }
                    }
                }
            }
        }
    }
}
