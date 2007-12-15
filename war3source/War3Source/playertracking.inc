/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: playertracking.inc
 * Description: Holds all the storage for players, temporary and long term.
 * Author(s): Anthony Iacono  
 */

#include <tf2>

#define IS_ALIVE !GetLifestate

#define INFO_COUNT     5
#define TRACKING_COUNT 11

// Global definition
new Handle:g_OnRaceSelectedHandle;
new Handle:g_OnSkillLevelChangedHandle;

new bool:speedAltered[MAXPLAYERS+1]      = { false, ... };
new bool:gravityAltered[MAXPLAYERS+1]    = { false, ... };
new bool:visibilityAltered[MAXPLAYERS+1] = { false, ... };

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
    SetArrayCell(vec,1,race);
    Call_StartForward(g_OnRaceSelectedHandle);
    Call_PushCell(GetArrayCell(vec,0));
    Call_PushCell(vectorpos);
    Call_PushCell(oldrace);
    Call_PushCell(race);
    new result;
    Call_Finish(result);
}

public GetLifestate(client)
{
    return GetEntData(client,m_OffsetLifestate,1);
}

public Handle:GetPropertyInfo(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,4);
}

public SetPropertyInfo(vectorpos,Handle:info)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,4,info);
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

public GetCredits(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,3);
}

public SetCredits(vectorpos,credits)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,3,credits);
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
    // Boy, this is going to be fun.
    for(new x=0;x<GetArraySize(arrayPlayers);x++)
    {
        new Handle:playerHandle=GetArrayCell(arrayPlayers,x);
        new client=GetArrayCell(playerHandle,0);
        if(IsClientInGame(client))
        {
            new Handle:pinfo=GetPropertyInfo(x);
            new Float:gravity=1.0,Float:speed=1.0,visibility=255,Float:meleeFactor=1.0;
            new bool:overridePlayerSpeed=false;
            new bool:overridePlayerGravity=false;
            new bool:overridePlayerVisibility=false;
            for(new y=0;y<GetArraySize(pinfo);y++)
            {
                // check which plugin is the highest/lowest bidder, but first, override?
                new Handle:temp           = GetArrayCell(pinfo,y);
                new Float:maxSpeed        = GetArrayCell(temp,1);
                new Float:minGravity      = GetArrayCell(temp,2);
                new minVisibility         = GetArrayCell(temp,3);
                new Float:maxmeleeFactor  = GetArrayCell(temp,4);
                new Float:overridespeed   = GetArrayCell(temp,5);
                new Float:overridegravity = GetArrayCell(temp,6);
                new overridevisibility    = GetArrayCell(temp,7);

                if(!overridePlayerSpeed)
                {
                    if(overridespeed>0.0)
                    {
                        speed=overridespeed;
                        overridePlayerSpeed=true;
                        speedAltered[client]=true;
                    }
                    else if(maxSpeed>speed)
                    {
                        speed=maxSpeed;
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
                    else if(minGravity<gravity)
                    {
                        gravity=minGravity;
                        gravityAltered[client]=true;
                    }
                }
                if(!overridePlayerVisibility)
                {
                    if(overridevisibility>-1)
                    {
                        meleeFactor=1.0;
                        visibility=overridevisibility;
                        overridePlayerVisibility=true;
                        visibilityAltered[client]=true;
                    }
                    else if(visibility>minVisibility)
                    {
                        visibility=minVisibility;
                        meleeFactor=maxmeleeFactor;
                        visibilityAltered[client]=true;
                    }
                }
            }

            if (speedAltered[client] || overridePlayerSpeed || speed != 1.0)
            {
                if (GameType == tf2)
                {
                    if (m_BaseSpeed[client] > 1.0)
                    {
                        new Float:newSpeed;
                        new Float:curSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed[client]);
                        if (curSpeed < 100.0) // && TF_GetClass(client) == TF2_HEAVY)
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

                        /**/
                        LogMessage("[War3Source] BaseSpeed=%f, curSpeed=%f, newSpeed=%f\n",
                                   m_BaseSpeed[client], curSpeed, newSpeed);

                        /*
                        War3Source_ChatMessage(client,COLOR_DEFAULT,
                                               "%c[War3Source] %c BaseSpeed=%f, speed=%f, curSpeed=%f, newSpeed=%f",
                                               COLOR_GREEN,COLOR_DEFAULT, m_BaseSpeed[client], speed, curSpeed, newSpeed);
                        */

                        if (curSpeed != newSpeed)
                            SetEntDataFloat(client,m_OffsetMaxSpeed[client], newSpeed);
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

            if (visibilityAltered[client] || overridePlayerVisibility || visibility != 255)
            {
                if (visibility >= 255)
                {
                    MakeVisible(client);

                    // Visibility is back to normal, Reset the altered flag
                    visibilityAltered[client]=false;
                }
                else
                {
                    MakeInvisible(client, visibility, meleeFactor);
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
}

stock MakeVisible(client)
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

stock MakeInvisible(client, visibility, Float:meleeFactor)
{
    decl String:wepName[128];
    GetClientWeapon(client, wepName, 127);

    if (meleeFactor != 1.0 && meleeFactor != -1.0)
    {
        if(GameType == cstrike && StrEqual(wepName,"weapon_knife"))
        {
            visibility *= meleeFactor;
        }
        else if(GameType == tf2 && (StrEqual(wepName,"tf_weapon_knife") ||
                                    StrEqual(wepName,"tf_weapon_shovel") ||
                                    StrEqual(wepName,"tf_weapon_wrench") ||
                                    StrEqual(wepName,"tf_weapon_bat") ||
                                    StrEqual(wepName,"tf_weapon_bonesaw") ||
                                    StrEqual(wepName,"tf_weapon_bottle") ||
                                    StrEqual(wepName,"tf_weapon_club") ||
                                    StrEqual(wepName,"tf_weapon_fireaxe") ||
                                    StrEqual(wepName,"tf_weapon_fists") ||
                                    StrEqual(wepName,"tf_weapon_builder") ||
                                    StrEqual(wepName,"tf_weapon_pda_engineer_build") ||
                                    StrEqual(wepName,"tf_weapon_pda_engineer_destroy") ||
                                    StrEqual(wepName,"tf_weapon_pda_spy")))
        {
            visibility *= meleeFactor;
        }
        else if(GameType == dod && (StrEqual(wepName,"weapon_amerknife") ||
                                    StrEqual(wepName,"weapon_spade")))
        {
            visibility *= meleeFactor;
        }
    }

    new count=GetEntityCount();
    for(new obj = 64; obj < count; obj++)
    {
        if(IsValidEdict(obj))
        {
            if(GetEntDataEnt(obj,m_OwnerOffset) == client)
                SetRenderColor(obj,255,255,255,visibility);
        }
    }
    SetRenderColor(client,255,255,255,visibility);
}

stock SetRenderColor(entity,r,g,b,a)
{
	if(m_ColorOffset != -1)
    {
        SetEntData(entity,m_ColorOffset,r,1,true);
        SetEntData(entity,m_ColorOffset+1,g,1,true);
        SetEntData(entity,m_ColorOffset+2,b,1,true);
        SetEntData(entity,m_ColorOffset+3,a,1,true);

        if(m_RenderModeOffset != -1)
            SetEntData(entity,m_RenderModeOffset,3,1,true);
    }
}

stock CreateIfColumnDoesntExist(Handle:DB,const String:columnname[],const String:settings[])
{
    decl String:query[256];
    Format(query,255,"SELECT %s FROM war3source",columnname);
    if(!SQL_FastQuery(DB,query))
    {
        Format(query,255,"ALTER TABLE war3source ADD COLUMN %s %s",columnname,settings);
        SQL_FastQuery(DB,query);
    }
}

public SQLPlayerInt(Handle:query,const String:columnname[])
{
    new column;
    SQL_FieldNameToNum(query,columnname,column);
    decl String:result[16];
    SQL_FetchString(query,column,result,sizeof(result));
    return StringToInt(result);
}

public War3Source_SQLTable()
{
    if(DBIDB)
    {
        // Check if the table exists
        new Handle:tableCheck=SQL_Query(DBIDB,"SELECT * FROM war3source");
        new bool:created=true; // assume its already there
        if(tableCheck==INVALID_HANDLE)
            created=false;
        else
            CloseHandle(tableCheck);
        if(!created)
        {
            if(SQL_FastQuery(DBIDB,"CREATE TABLE war3source (steamid varchar(64));"))
                created=true;
            else
                SetFailState("[War3Source] Unknown error in the creation of the SQL table.");
        }
        if(created)
        {
            // We need to check again because we may set to true in the last function
            CreateIfColumnDoesntExist(DBIDB,"steamid","varchar(64)");
            CreateIfColumnDoesntExist(DBIDB,"race","varchar(30)");
            CreateIfColumnDoesntExist(DBIDB,"credits","varchar(30)");
        }
    }
}

public War3Source_InsertPlayer(Handle:db,client)
{
    decl String:steamid[64];
    if(GetClientAuthString(client,steamid,63))
    {
        decl String:buffer[1024];
        Format(buffer,1023,"INSERT INTO war3source (steamid,race,credits");
        for(new x=0;x<RACE_COUNT;x++)
        {
            decl String:short[16];
            new Handle:race=Race(x);
            GetArrayString(race,1,short,15);
            Format(buffer,1023,"%s,%s_xp,%s_level",buffer,short,short);
            for(new y=0;y<SKILL_COUNT;y++)
                Format(buffer,1023,"%s,%s_skilllevel_%d",buffer,short,y);
        }
        Format(buffer,1023,"%s) VALUES ('%s','0','0'",buffer,steamid);
        for(new x=0;x<RACE_COUNT;x++)
        {
            Format(buffer,1023,"%s,'0','0'",buffer);
            for(new y=0;y<SKILL_COUNT;y++)
                Format(buffer,1023,"%s,'0'",buffer);
        }
        Format(buffer,1023,"%s)",buffer);
        SQL_FastQuery(db,buffer);
    }
}

public War3Source_LoadPlayerData(client,vectorpos)
{
    if(DBIDB)
    {
        decl String:steamid[64];
        if(GetClientAuthString(client,steamid,63))
        {
            decl String:buf[256];
            Format(buf,255,"SELECT * FROM war3source WHERE steamid = '%s'",steamid);
            new Handle:query=SQL_Query(DBIDB,buf);
            if(query)
            {
                SQL_Rewind(query);
                new bool:fetch=SQL_FetchRow(query);
                if(!fetch)
                    War3Source_InsertPlayer(DBIDB,client);
                else
                {
                    if(fetch)
                    {
                        SetRace(vectorpos,SQLPlayerInt(query,"race"));
                        SetCredits(vectorpos,SQLPlayerInt(query,"credits"));
                        for(new x=0;x<RACE_COUNT;x++)
                        {
                            new Handle:race=Race(x);
                            decl String:short[16];
                            GetArrayString(race,1,short,15);
                            decl String:buffer[64];
                            Format(buffer,63,"%s_xp",short);
                            SetXP(vectorpos,x,SQLPlayerInt(query,buffer));
                            Format(buffer,63,"%s_level",short);
                            SetLevel(vectorpos,x,SQLPlayerInt(query,buffer));
                            for(new y=0;y<SKILL_COUNT;y++)
                            {
                                Format(buffer,63,"%s_skilllevel_%d",short,y);
                                SetSkillLevel(vectorpos,x,y,SQLPlayerInt(query,buffer));
                            }
                        }
                        CloseHandle(query);
                    }
                }
            }
        }
    }
}

public War3Source_SavePlayerData(client,vectorpos)
{
    if(DBIDB)
    {
        decl String:steamid[64];
        if(GetClientAuthString(client,steamid,63))
        {
            decl String:bufferSave[2048]="";
            Format(bufferSave,2047,"race = '%d',",GetRace(vectorpos));
            Format(bufferSave,2047,"%s credits = '%d'",bufferSave,GetCredits(vectorpos));
            for(new x=0;x<RACE_COUNT;x++)
            {
                new Handle:race=Race(x);
                decl String:short[16];
                GetArrayString(race,1,short,15);
                Format(bufferSave,2047,"%s, %s_xp = '%d'",bufferSave,short,GetXP(vectorpos,x));
                Format(bufferSave,2047,"%s, %s_level = '%d'",bufferSave,short,GetLevel(vectorpos,x));
                for(new y=0;y<SKILL_COUNT;y++)
                    Format(bufferSave,2047,"%s, %s_skilllevel_%d = '%d'",bufferSave,short,y,GetSkillLevel(vectorpos,x,y));
            }
            decl String:querySave[2400];
            Format(querySave,2399,"UPDATE war3source SET %s WHERE steamid = '%s'",bufferSave,steamid);
            SQL_FastQuery(DBIDB,querySave);
        }
    }
}
