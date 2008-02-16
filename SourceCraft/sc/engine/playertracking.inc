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
#define INFO_PROPERTIES                 6
#define INFO_SHOPITEMS                  7

#define INFO_COUNT                      8

#define RACEINFO_XP                     0
#define RACEINFO_LEVEL                  1
#define RACEINFO_SKILLS                 2

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

// Global definition
new bool:g_RoundActive = true;

new Handle:g_OnSkillLevelChangedHandle = INVALID_HANDLE;
new Handle:g_OnRaceSelectedHandle = INVALID_HANDLE;

new Float:m_BaseSpeed[MAXPLAYERS+1];
new Float:m_StoppedMoving[MAXPLAYERS+1];
new Float:m_CloakTime[MAXPLAYERS+1];
new bool:m_SpeedAltered[MAXPLAYERS+1];
new bool:m_GravityAltered[MAXPLAYERS+1];
new bool:m_VisibilityAltered[MAXPLAYERS+1];

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

stock GetPlayer(client)
{
    return GetClientVectorPosition(client);
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
    return GetArrayCell(vec,INFO_PROPERTIES);
}

public Handle:GetShopItemInfo(vectorpos)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_SHOPITEMS);
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

public Handle:GetRaceInfo(vectorpos,race)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    return GetArrayCell(vec,INFO_COUNT+race);
}

public GetXP(vectorpos,race)
{
    new Handle:raceinfo=GetRaceInfo(vectorpos,race);
    return GetArrayCell(raceinfo,RACEINFO_XP);
}

public SetXP(vectorpos,race,xp)
{
    new Handle:raceinfo=GetRaceInfo(vectorpos,race);
    SetArrayCell(raceinfo,RACEINFO_XP,xp);
}

public GetLevel(vectorpos,race)
{
    new Handle:raceinfo=GetRaceInfo(vectorpos,race);
    return GetArrayCell(raceinfo,RACEINFO_LEVEL);
}

public SetLevel(vectorpos,race,level)
{
    new Handle:raceinfo=GetRaceInfo(vectorpos,race);
    SetArrayCell(raceinfo,RACEINFO_LEVEL,level);
}

public GetSkillLevel(vectorpos,race,skill)
{
    new Handle:raceinfo=GetRaceInfo(vectorpos,race);
    return GetArrayCell(raceinfo,RACEINFO_SKILLS+skill);
}

public SetSkillLevel(vectorpos,race,skill,level)
{
    new Handle:raceinfo=GetRaceInfo(vectorpos,race);
    new num=RACEINFO_SKILLS+skill;
    new old=GetArrayCell(raceinfo,num);
    SetArrayCell(raceinfo,num,level);
    Call_StartForward(g_OnSkillLevelChangedHandle);
    Call_PushCell(GetClientIndex(vectorpos));
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
    new Handle:raceinfo=GetRaceInfo(vectorpos,race);
    new num=RACEINFO_SKILLS+SKILL_COUNT;
    for(new x=RACEINFO_SKILLS;x<num;x++)
        ret+=GetArrayCell(raceinfo,x);
    return ret;
}

public GetImmunity(vectorpos,immunity)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new raceCount = GetArraySize(arrayRaces);
    return GetArrayCell(vec,INFO_COUNT+raceCount+immunity);
}

public SetImmunity(vectorpos,immunity,imm_state)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new raceCount = GetArraySize(arrayRaces);
    SetArrayCell(vec,INFO_COUNT+raceCount+immunity,imm_state);
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

                new bool:isMoving = IsMoving(client);

                new Handle:pinfo=GetPropertyInfo(x);
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
                            LogMessage("[playertracking] Found overridespeed for %N to %f", client, overridespeed);
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
                            LogMessage("[playertracking] Found overridevisibility for %N to %d", client, overridevisibility);
                            visibility=overridevisibility;
                            overridePlayerVisibility=true;
                            m_VisibilityAltered[client]=true;
                        }
                        else if (checkVisibility >= 0 || _:type >= 0 ||
                                 _:checkFx >= 0 || _:checkMode >= 0)
                        {
                            LogMessage("[playertracking] Found visibility for %N to %d, type=%d, f1=%f,f2=%f,mode=%d,fx=%d",
                                       client, checkVisibility,type,factor1,factor2,checkMode,checkFx);
                            new checkRank = CalculateVisibility(client, wepName, isMoving, checkVisibility,
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

                            LogMessage("[playertracking] Set speed of %N to %f, cur=%f, base=%f, class_speed=%f, speed=%f, altered=%d, override=%d",
                                       client, newSpeed, curSpeed, m_BaseSpeed[client], classSpeed,
                                       speed, m_SpeedAltered[client], overridePlayerSpeed);
                        }

                        m_SpeedAltered[client] = (speed != 1.0);
                    }
                    else // not tf2
                    {
                        LogMessage("[playertracking] Set NON TF2 speed of %N to %f, altered=%d, override=%d",
                                   client, speed, m_SpeedAltered[client], overridePlayerSpeed);

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

                if (m_VisibilityAltered[client] || overridePlayerVisibility || visibility >= 0)
                {
                    LogMessage("[playertracking] Visibility of %N is %f, moving=%d",
                               client, visibility, isMoving);

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
    return Plugin_Continue;
}

bool:IsMoving(client)
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

CalculateVisibility(client, const String:wepName[], bool:isMoving, &visibility,
                    VisibilityType:type, Float:factor1, Float:factor2,
                    &RenderMode:mode, &RenderFx:fx)
{
    LogMessage("[playertracking] CalcVisibility %N, type=%d", client, type);
    if (type == TimedInvisibility || type == TimedMeleeInvisibility)
    {
        if (isMoving)
            visibility = 255;
        else if (m_CloakTime[client] != 0.0) // Currently Cloaked
        {
            if (factor2 > 0.0 && GetGameTime() - m_CloakTime[client] >= factor2) // factor2 == duration
                visibility = 255;
            else if (type != TimedMeleeInvisibility || IsEquipmentMelee(wepName))
                visibility = 0;
            else
                visibility = 255;
        }
        else // Not Cloaked
        {
            if (factor1 <= 0.0 || GetGameTime() - m_StoppedMoving[client] >= factor1) // factor1 == delay
            {
                if (type != TimedMeleeInvisibility || IsEquipmentMelee(wepName))
                    visibility = 0;
                else
                    visibility = 255;
            }
            else
                visibility = 255;
        }
        new bool:isMelee = IsEquipmentMelee(wepName);
        LogMessage("[playertracking] CalcVisibility(TimedInvisibility) of %N is %d, moving=%d, melee=%d, f1=%f,f2=%f",
                   client, visibility, isMoving, isMelee,factor1,factor2);
        return visibility;
    }
    else if (type == GraduatedEffects)
    {
        new rank = visibility;
        visibility = 255;
        fx = RenderFx:((rank / 14) + 1);
        if (fx == RENDERFX_EXPLODE)
            fx = RENDERFX_PULSE_FAST_WIDER;
        else if (fx == RENDERFX_GLOWSHELL)
            fx = RENDERFX_MAX;
        return rank;
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
            if (!isMoving)
                visibility = RoundToNearest(float(visibility) * factor2);
        }

        new rank = visibility;
        if (mode > RENDER_NORMAL)
            rank--;
        if (fx > RENDERFX_NONE)
            rank -= _:fx;

        return rank;
    }
}

SetVisibility(client, visibility, RenderMode:mode, RenderFx:fx, r, g, b)
{
    LogMessage("[playertracking] SetVisibility of %N to %d, mode=%d,fx=%d,rgb=%d,%d,%d",
               client, visibility, mode, fx, r, g, b);
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
        for (new obj=GetMaxClients(); obj < count; obj++)
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
    LogMessage("[playertracking] ResetVisibility of %N", client);
    if (m_OwnerOffset != -1)
    {
        if(client>-1)
        {
            new count=GetEntityCount();
            for(new y=GetMaxClients();y<count;y++)
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

