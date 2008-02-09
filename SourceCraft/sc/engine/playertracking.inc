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
#define INFO_RACE                       1
#define INFO_PENDING_RACE               2
#define INFO_PENDING_SKILL_RESET        3
#define INFO_CREDITS                    4
#define INFO_OVERALL_LEVEL              5
#define INFO_PROPERTY                   6
#define INFO_SHOPITEMS                  7

#define INFO_COUNT                      8

#define TRACKING_PLUGIN_HANDLE          0
#define TRACKING_SPEED                  1
#define TRACKING_GRAVITY                2
#define TRACKING_VISIBILITY             3
#define TRACKING_MELEE_FACTOR           4
#define TRACKING_MOVEMENT_FACTOR        5
#define TRACKING_OVERRIDE_SPEED         6
#define TRACKING_OVERRIDE_GRAVITY       7
#define TRACKING_OVERRIDE_VISIBILITY    8

#define TRACKING_COUNT                  9

// Global definition
new bool:g_RoundActive = true;

new Handle:g_OnSkillLevelChangedHandle = INVALID_HANDLE;
new Handle:g_OnRaceSelectedHandle = INVALID_HANDLE;

new Float:m_BaseSpeed[MAXPLAYERS+1];
new bool:speedAltered[MAXPLAYERS+1];
new bool:gravityAltered[MAXPLAYERS+1];
new bool:visibilityAltered[MAXPLAYERS+1];

public GetClientVectorPosition(client)
{
    new size=GetArraySize(arrayPlayers);
    for(new x=0;x<size;x++)
    {
        new Handle:ply=GetArrayCell(arrayPlayers,x);
        new curClient=GetArrayCell(ply,INFO_CLIENT_INDEX);
        if(client==curClient)
            return x;
    }
    return -1;
}

public GetClientIndex(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_CLIENT_INDEX);
}

public GetRace(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_RACE);
}

public SetRace(vectorpos,race)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new oldrace=GetArrayCell(vec,INFO_RACE);
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
    return GetArrayCell(vec,INFO_PENDING_RACE);
}

public SetPendingRace(vectorpos,pend)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_PENDING_RACE,pend);
}

public GetPendingSkillReset(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_PENDING_SKILL_RESET);
}

public SetPendingSkillReset(vectorpos,pend)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_PENDING_SKILL_RESET,pend);
}

public GetCredits(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_CREDITS);
}

public SetCredits(vectorpos,credits)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_CREDITS,credits);
}

public GetOverallLevel(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_OVERALL_LEVEL);
}

public SetOverallLevel(vectorpos,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_OVERALL_LEVEL,level);
}

public Handle:GetPropertyInfo(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_PROPERTY);
}

public Handle:GetShopItemInfo(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_SHOPITEMS);
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
    new Handle:shopitems=GetShopItemInfo(vectorpos);
    return GetArrayCell(shopitems,item);
}

public SetOwnsItem(vectorpos,item,owns)
{
    new Handle:shopitems=GetShopItemInfo(vectorpos);
    SetArrayCell(shopitems,item,owns);
}

public GetXP(vectorpos,race)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+race);
}

public SetXP(vectorpos,race,xp)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+race,xp);
}

public GetLevel(vectorpos,race)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new raceCount = GetArraySize(arrayRaces);
    return GetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+raceCount+race);
}

public SetLevel(vectorpos,race,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new raceCount = GetArraySize(arrayRaces);
    SetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+raceCount+race,level);
}

public GetSkillLevel(vectorpos,race,skill)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new raceCount = GetArraySize(arrayRaces);
    new num=INFO_COUNT+IMMUNITY_COUNT+(raceCount*2)+(race*SKILL_COUNT)+skill;
    return GetArrayCell(vec,num);
}

public SetSkillLevel(vectorpos,race,skill,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new raceCount = GetArraySize(arrayRaces);
    new num=INFO_COUNT+IMMUNITY_COUNT+(raceCount*2)+(race*SKILL_COUNT)+skill;
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
    new raceCount = GetArraySize(arrayRaces);
    new num1=INFO_COUNT+IMMUNITY_COUNT+(raceCount*2)+(race*SKILL_COUNT);
    new num2=num1+SKILL_COUNT;
    for(new x=num1;x<num2;x++)
        ret+=GetArrayCell(vec,x);
    return ret;
}

public Action:PlayerProperties(Handle:timer)
{
    if (g_RoundActive)
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
                new visibility=-1;
                new Float:gravity=-1.0,Float:speed=-1.0;
                new bool:overridePlayerSpeed=false;
                new bool:overridePlayerGravity=false;
                new bool:overridePlayerVisibility=false;
                for(new y=0;y<GetArraySize(pinfo);y++)
                {
                    // check which plugin is the highest/lowest bidder, but first, override?
                    new Handle:temp             = GetArrayCell(pinfo,y);
                    new Float:checkSpeed        = GetArrayCell(temp,TRACKING_SPEED);
                    new Float:checkGravity      = GetArrayCell(temp,TRACKING_GRAVITY);
                    new checkVisibility         = GetArrayCell(temp,TRACKING_VISIBILITY);
                    new Float:meleeFactor       = GetArrayCell(temp,TRACKING_MELEE_FACTOR);
                    new Float:movementFactor    = GetArrayCell(temp,TRACKING_MOVEMENT_FACTOR);
                    new Float:overridespeed     = GetArrayCell(temp,TRACKING_OVERRIDE_SPEED);
                    new Float:overridegravity   = GetArrayCell(temp,TRACKING_OVERRIDE_GRAVITY);
                    new overridevisibility      = GetArrayCell(temp,TRACKING_OVERRIDE_VISIBILITY);

                    if(!overridePlayerSpeed)
                    {
                        if(overridespeed >= 0.0)
                        {
                            LogMessage("[playertracking] Found overridespeed of %N to %f", client, overridespeed);
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
                            gravityAltered[client]=true;
                        }
                        else if(checkGravity >= 0 &&
                                (gravity < 0.0 || checkGravity < gravity))
                        {
                            gravity=checkGravity;
                            gravityAltered[client]=true;
                        }
                    }

                    if(!overridePlayerVisibility)
                    {
                        if(overridevisibility >= 0)
                        {
                            visibility=overridevisibility;
                            overridePlayerVisibility=true;
                            visibilityAltered[client]=true;
                        }
                        else if (checkVisibility >= 0 || meleeFactor >= 0.0 || movementFactor >= 0.0)
                        {
                            checkVisibility = CalculateVisibility(client, wepName, vecVelocity,
                                                                  checkVisibility, meleeFactor,
                                                                  movementFactor);
                            if (checkVisibility >= 0 &&
                                (visibility < 0.0 || checkVisibility < visibility))
                            {
                                visibility=checkVisibility;
                                visibilityAltered[client]=true;
                            }
                        }
                    }
                }

                if (speedAltered[client] || overridePlayerSpeed || speed >= 0.0)
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

                            LogMessage("[playertracking] Set speed of %N to %f, cur=%f, base=%f, class_speed=%f, speed=%f, altered=%d, override=%d",
                                       client, newSpeed, curSpeed, m_BaseSpeed[client], classSpeed,
                                       speed, speedAltered[client], overridePlayerSpeed);
                        }

                        speedAltered[client] = (speed != 1.0);
                    }
                    else // not tf2
                    {
                        LogMessage("[playertracking] Set NON TF2 speed of %N to %f, altered=%d, override=%d",
                                   client, speed, speedAltered[client], overridePlayerSpeed);

                        if (GetEntDataFloat(client,m_OffsetSpeed)!=speed)
                            SetEntDataFloat(client,m_OffsetSpeed,speed);
                    }
                }
                else
                {
                    if (GameType == tf2)
                    {
                        new Float:classSpeed = GetClassSpeed(client);
                        new Float:curSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed);
                        if (curSpeed != classSpeed)
                        {
                            LogMessage("[playertracking] Speed of %N is %f, base=%f, class_speed=%f",
                                       client, curSpeed, m_BaseSpeed[client], classSpeed);
                        }
                    }
                }

                if (visibilityAltered[client] || overridePlayerVisibility || visibility >= 0)
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

                if (gravityAltered[client] || overridePlayerGravity || gravity >= 0.0)
                {
                    if (gravity < 0.0)
                        gravity = 1.0;

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
    return Plugin_Continue;
}

stock CalculateVisibility(client, const String:wepName[], const Float:vecVelocity[3], visibility,
                          Float:meleeFactor, Float:movementFactor)
{
    if (visibility < 0)
        visibility = 255;

    if (meleeFactor >= 0.0 && meleeFactor != 1.0)
    {
        if (IsEquipmentMelee(wepName))
            visibility *= meleeFactor;
    }

    if (movementFactor >= 0.0 && movementFactor != 1.0)
    {
        if (!(GetClientButtons(client) & (IN_FORWARD|IN_BACK|IN_MOVELEFT|
                                          IN_MOVERIGHT|IN_SPEED|IN_JUMP|
                                          IN_ATTACK|IN_ATTACK2|IN_ZOOM)))
        {
            if (vecVelocity[0] == 0.0 && vecVelocity[1] == 0.0 && vecVelocity[2] == 0.0)
                visibility *= movementFactor;
        }
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

stock MakeInvisible(client, visibility)
{
    if (m_OwnerOffset != -1)
    {
        new count=GetEntityCount();
        for (new obj = 64; obj < count; obj++)
        {
            if (IsValidEdict(obj))
            {
                if (GetEntDataEnt2(obj,m_OwnerOffset) == client)
                {
                    decl String:name[32] = "";
                    if (!GetEntityNetClass(obj,name,sizeof(name)) ||
                        !StrEqual(name, "CCaptureFlag"))
                    {
                        SetEntityRenderColor(obj,255,255,255,visibility);
                        if (visibility> 0)
                        {
                            SetEntityRenderMode(client,RENDER_TRANSTEXTURE);
                            SetEntityRenderFx(client,RENDERFX_HOLOGRAM);
                        }
                        else
                        {
                            SetEntityRenderMode(client,RENDER_GLOW);
                            SetEntityRenderFx(client,RENDERFX_FADE_FAST);
                        }
                    }
                }
            }
        }
    }
    SetEntityRenderColor(client,255,255,255,visibility);
    SetEntityRenderMode(client,RENDER_TRANSTEXTURE);
    SetEntityRenderFx(client,RENDERFX_HOLOGRAM);
}
