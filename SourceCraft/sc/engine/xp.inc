/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: xp.inc
 * Description: The name of the file is somewhat deciving... it is basically the
 *              file that handles all the XP you get for killing people and other
 *              stuff as well. 
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */
 
#define MAX_LEVELS          16

#define HEADSHOT_XP         10
#define BACKSTAB_XP         10
#define ASSIST_XP           10
#define MELEE_XP            20
#define DOMINATED_XP        15
#define REVENGE_XP          15

#define BUILD_XP             5
#define DESTROY_XP           5
#define CHARGE_XP           30

#define DEFUSE_XP           20
#define PLANT_XP            20
#define HOSTAGERESCUED_XP   20

#define BLOCK_XP             5
#define CAPTURE_FLAG_XP     20
#define CAPTURE_POINT_XP    20

#define ROUND_WIN_XP        20
#define GAME_WIN_XP         10 // Multiplied by score
#define MVP_XP               5 // Multiplied by place * points

// Functions called from menus.inc
//public SkillMenu(client, vectorpos, Function:parentMenuFunction);

KillXP(level)
{
    new Handle:temp;
    if(SAVE_ENABLED)
        temp=GetArrayCell(vecLevelConfiguration,1);
    else
        temp=GetArrayCell(vecLevelConfiguration,3);

    if(GetArraySize(temp)==MAX_LEVELS+1)
        return GetArrayCell(temp,level);
    else
        return 0;
}

ReqLevelXP(level)
{
    new Handle:temp;
    if(SAVE_ENABLED)
        temp=GetArrayCell(vecLevelConfiguration,0);
    else
        temp=GetArrayCell(vecLevelConfiguration,2);

    if(GetArraySize(temp)==MAX_LEVELS+1)
        return GetArrayCell(temp,level);
    else
        return 0;
}

public DoLevelCheck(client,vectorpos)
{
    new bool:m_Go=true;
    while(m_Go)
    {
        new race = GetRace(vectorpos);
        new level = GetLevel(vectorpos,race);
        if (level < MAX_LEVELS)
        {
            new curXP = GetXP(vectorpos,race);
            new reqXP = ReqLevelXP(++level);
            if (curXP >= reqXP)
            {
                    new oLevel = GetOverallLevel(vectorpos);
                    SetOverallLevel(vectorpos, ++oLevel);
                    SetLevel(vectorpos,race,level);
                    SkillMenu(client, vectorpos, INVALID_FUNCTION);

                    decl String:raceName[64] = "";
                    GetArrayString(Race(race),RACE_NAME,raceName,sizeof(raceName));
                    PrintToChat(client,"%c[SourceCraft] %cYou are now a level %d %s (level %d overall).",
                                COLOR_GREEN,COLOR_DEFAULT,level, raceName, oLevel);
                    SetXP(vectorpos,race,curXP-reqXP);
            }
            else
                m_Go=false;
        }
        else
            m_Go=false;
    }
}
 
public ShowXP(client,vecpos)
{
    new race=GetRace(vecpos);
    if (race >= 0)
    {
        new level=GetLevel(vecpos,race);
        decl String:racename[64];
        new Handle:racedata=Race(race);
        GetArrayString(racedata,0,racename,63);
        if (level<MAX_LEVELS)
        {
            PrintToChat(client,"%c[SourceCraft] %c%s - Level %d - Experience %d / %d. (Overall Level %d)",
                        COLOR_GREEN,COLOR_DEFAULT,racename,level,
                        GetXP(vecpos,race),ReqLevelXP(level+1),
                        GetOverallLevel(vecpos));
        }
        else
        {
            PrintToChat(client,"%c[SourceCraft] %c%s - Level %d - Experience %d. (Overall Level %d)",
                        COLOR_GREEN,COLOR_DEFAULT,racename,level,
                        GetXP(vecpos,race),GetOverallLevel(vecpos));
        }
    }
}

public GiveKillXP(client,vectorpos,victim,bool:headshot,bool:backstab,bool:melee,
                  bool:dominated,bool:revenge,bool:assist)
{
    new amount;
    if(victim>0)
    {
        new vic_vec=GetClientVectorPosition(victim);
        amount=KillXP(GetLevel(vic_vec,GetRace(vic_vec)));
    }
    else
        amount=KillXP(GetLevel(vectorpos,GetRace(vectorpos)));

    if (headshot)
    {
        amount+=HEADSHOT_XP;
        PrintToChat(client,"%c[SourceCraft] %cYou get %d additional experience for a headshot.",
                    COLOR_GREEN,COLOR_DEFAULT,HEADSHOT_XP);
    }
    else if (backstab)
    {
        amount+=BACKSTAB_XP;
        PrintToChat(client,"%c[SourceCraft] %cYou get %d additional experience for a backstab.",
                    COLOR_GREEN,COLOR_DEFAULT,BACKSTAB_XP);
    }
    else if (melee)
    {
        amount+=MELEE_XP;
        PrintToChat(client,"%c[SourceCraft] %cYou get %d additional experience for a knife/shovel/wrench/etc kill.",
                    COLOR_GREEN,COLOR_DEFAULT,MELEE_XP);
    }

    if (dominated)
    {
        amount+=DOMINATED_XP;
        PrintToChat(client,"%c[SourceCraft] %cYou get %d additional experience for domination!",
                    COLOR_GREEN,COLOR_DEFAULT,DOMINATED_XP);
    }
    
    if (revenge)
    {
        amount+=REVENGE_XP;
        PrintToChat(client,"%c[SourceCraft] %cYou get %d additional experience for a revenge kill!",
                    COLOR_GREEN,COLOR_DEFAULT,DOMINATED_XP);
    }

    if (assist)
    {
        amount+=ASSIST_XP;
        PrintToChat(client,"%c[SourceCraft] %cYou get %d additional experience for assisting a kill.",
                    COLOR_GREEN,COLOR_DEFAULT,ASSIST_XP);
    }
    
    GiveXP(client,vectorpos,amount, assist ? "assisting a kill" : "getting a kill");
}

public GiveDefuseXP(client,vectorpos)
{
    // Called when a player defuses the bomb
    GiveXP(client,vectorpos,DEFUSE_XP, "defusing the bomb");
}

public GivePlantXP(client,vectorpos)
{
    // Called when a player plants the bomb
    GiveXP(client,vectorpos,PLANT_XP, "planting the bomb");
}

public GiveHostageRescuedXP(client,vectorpos)
{
    // Called when a player rescues a hostage
    GiveXP(client,vectorpos,HOSTAGERESCUED_XP, "rescuing a hostage");
}

public GiveChargeDeployedXP(client,vectorpos)
{
    // Called when a player deploys thier charge (medic goes uber)
    GiveXP(client,vectorpos,CHARGE_XP, "deploying Ubercharge");
}

public GiveObjectBuiltXP(client,vectorpos)
{
    // Called when a player builds an object
    GiveXP(client,vectorpos,BUILD_XP, "building something");
}

public TakeObjectBuiltXP(client,vectorpos)
{
    // Called when a player destroys thier own object
    TakeXP(client,vectorpos,BUILD_XP, "destroying your own object");
}

public GiveObjectDestroyedXP(client,vectorpos)
{
    // Called when a player destroys an object
    GiveXP(client,vectorpos,DESTROY_XP, "destroying something");
}

public GiveFlagCapturedXP(client,vectorpos)
{
    // Called when a player captures a flag
    GiveXP(client,vectorpos,CAPTURE_FLAG_XP, "capturing the intelligence");
}

public GivePointCapturedXP(client,vectorpos)
{
    // Called when a player captures a point
    GiveXP(client,vectorpos,CAPTURE_POINT_XP, "capturing a point");
}

public GiveCaptureBlockedXP(client,vectorpos)
{
    // Called when a player blocks a capture
    GiveXP(client,vectorpos,BLOCK_XP, "blocking a point");
}

public GiveRoundWinXP(client,vectorpos)
{
    // Called when a team wins a round
    GiveXP(client,vectorpos,ROUND_WIN_XP, "winning a round");
}

public GiveGameWinXP(client,vectorpos,score)
{
    // Called when a team wins a round
    GiveXP(client,vectorpos,GAME_WIN_XP*score, "winning the game");
}

public GiveMvpXP(client,vectorpos,place,points)
{
    new String:reason[64];
    Format(reason,sizeof(reason),"being MVP #%d with %d points",place, points);
    GiveXP(client,vectorpos,points*place*MVP_XP,reason);
}

public GiveXP(client,vectorpos, amount, const String:reason[])
{
    // Called when a player is given XP
    new Action:result;
    Call_StartForward(g_OnXPGivenHandle);
    Call_PushCell(client);
    Call_PushCell(vectorpos);
    Call_PushCellRef(amount);
    Call_PushCell(false);
    Call_Finish(result);

    if (result != Plugin_Stop)
    {
        new race=GetRace(vectorpos);
        new newxp=GetXP(vectorpos,race)+amount;
        SetXP(vectorpos,race,newxp);
        LogMessage("%N gained %d experience for %s", client, amount, reason);
        PrintToChat(client,"%c[SourceCraft] %cYou have gained %d experience for %s.",
                    COLOR_GREEN,COLOR_DEFAULT,amount, reason);
        if(GetLevel(vectorpos,race)!=MAX_LEVELS)
            DoLevelCheck(client,vectorpos);
    }
}

public TakeXP(client,vectorpos, amount, const String:reason[])
{
    // Called when a player destroys thier own object
    new Action:result;
    Call_StartForward(g_OnXPGivenHandle);
    Call_PushCell(client);
    Call_PushCell(vectorpos);
    Call_PushCellRef(amount);
    Call_PushCell(true);
    Call_Finish(result);

    if (result != Plugin_Stop)
    {
        new race=GetRace(vectorpos);
        new newxp=GetXP(vectorpos,race)-amount;
        SetXP(vectorpos,race,newxp);
        LogMessage("%N lost %d experience for %s", client, amount, reason);
        PrintToChat(client,"%c[SourceCraft] %cYou have lost %d experience for %s.",
                    COLOR_GREEN,COLOR_DEFAULT,amount, reason);
        if(GetLevel(vectorpos,race)!=MAX_LEVELS)
            DoLevelCheck(client,vectorpos);
    }
}
