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

#define INFO_COUNT     7 // 0)client index, 1)race, 2)pending race,
                         // 3)pending skill reset, 4)credits,
                         // 5)overall level, 6)tracking array

#define TRACKING_COUNT 11

// Global definition
new bool:g_RoundActive = true;

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
    return GetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+
                            SHOPITEM_COUNT+RACE_COUNT+race);
}

public SetLevel(vectorpos,race,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    SetArrayCell(vec,INFO_COUNT+IMMUNITY_COUNT+
                     SHOPITEM_COUNT+RACE_COUNT+race,level);
}

public GetSkillLevel(vectorpos,race,skill)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new num=INFO_COUNT+SHOPITEM_COUNT+IMMUNITY_COUNT+
            RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT)+skill;
    return GetArrayCell(vec,num);
}

public SetSkillLevel(vectorpos,race,skill,level)
{
    new Handle:vec=GetArrayCell(arrayPlayers,vectorpos);
    new num=INFO_COUNT+SHOPITEM_COUNT+IMMUNITY_COUNT+
            RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT)+skill;
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
    new num1=INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+
             RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT);
    new num2=INFO_COUNT+IMMUNITY_COUNT+SHOPITEM_COUNT+
             RACE_COUNT+RACE_COUNT+(race*SKILL_COUNT)+SKILL_COUNT;
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
                        if(overridespeed != 1.0)
                        {
                            LogMessage("[playertracking] Found overridespeed of %N to %f", client, overridespeed);
                            speed=overridespeed;
                            overridePlayerSpeed=true;
                        }
                        else if(checkSpeed>speed)
                        {
                            speed=checkSpeed;
                        }
                    }

                    if(!overridePlayerGravity)
                    {
                        if(overridegravity != 1.0)
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

                if (GameType == tf2)
                {
                    new Float:curSpeed = GetEntDataFloat(client,m_OffsetMaxSpeed);
                    if (m_BaseSpeed[client] == 0.0)
                        m_BaseSpeed[client] == curSpeed;

                    if (overridePlayerSpeed || speed != 1.0 || speedAltered[client])
                    {
                        new Float:newSpeed;
                        if (m_BaseSpeed[client] > 100.0 && curSpeed > 50.0 && curSpeed < 200.0)
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
                        {
                            SetEntDataFloat(client,m_OffsetMaxSpeed, newSpeed);
                            /*
                            if (newSpeed == 0.0)
                                SetEntityMoveType(client, MOVETYPE_NONE);
                            else if (curSpeed == 0.0)
                                SetEntityMoveType(client, MOVETYPE_WALK);
                            */

                            new Float:classSpeed = GetClassSpeed(client);
                            LogMessage("[playertracking] Set speed of %N to %f, cur=%f, base=%f, class_speed=%f, speed=%f, altered=%d, override=%d",
                                       client, newSpeed, curSpeed, m_BaseSpeed[client], classSpeed, speed, speedAltered[client], overridePlayerSpeed);
                        }

                        speedAltered[client] = (speed != 1.0);
                    }
                    else
                    {
                        new Float:classSpeed = GetClassSpeed(client);
                        if (curSpeed != classSpeed)
                        {
                            LogMessage("[playertracking] Speed of %N is %f, base=%f, class_speed=%f",
                                        client, curSpeed, m_BaseSpeed[client], classSpeed);
                        }
                    }
                }
                else // not tf2
                {
                    LogMessage("[playertracking] Set NON TF2 speed of %N to %f, altered=%d, override=%d",
                        client, speed, speedAltered[client], overridePlayerSpeed);

                    if (GetEntDataFloat(client,m_OffsetSpeed)!=speed)
                        SetEntDataFloat(client,m_OffsetSpeed,speed);
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

    if (movementFactor != 1.0 && movementFactor != -1.0)
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
                        SetEntityRenderMode(client,RENDER_TRANSTEXTURE);
                        SetEntityRenderFx(client,RENDERFX_HOLOGRAM);
                    }
                }
            }
        }
    }
    SetEntityRenderColor(client,255,255,255,visibility);
    SetEntityRenderMode(client,RENDER_TRANSTEXTURE);
    SetEntityRenderFx(client,RENDERFX_HOLOGRAM);
}
