/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: xp.inc
 * Description: The name of the file is somewhat deciving... it is basically the
 *              file that handles all the XP you get for killing people and other
 *              stuff as well. 
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */
 
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

public ReqLevelXP(level)
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

public DoLevelCheck(client,Handle:playerHandle)
{
    if (GetRaceCount() >= 1)
    {
        new bool:m_Go=true;
        while(m_Go)
        {
            new race = GetRace(playerHandle);
            new level = GetLevel(playerHandle,race);
            if (level < MAX_LEVELS)
            {
                new curXP = GetXP(playerHandle,race);
                new reqXP = ReqLevelXP(++level);
                if (curXP >= reqXP)
                {
                    new oLevel = GetOverallLevel(playerHandle);
                    SetOverallLevel(playerHandle, ++oLevel);
                    SetLevel(playerHandle,race,level);
                    UpgradeMenu(client, playerHandle, INVALID_FUNCTION);

                    decl String:raceName[64] = "";
                    GetRaceName(GetRaceHandle(race),raceName,sizeof(raceName));
                    PrintToChat(client,"%c[SourceCraft] %cYou are now a level %d %s (level %d overall).",
                                COLOR_GREEN,COLOR_DEFAULT,level, raceName, oLevel);
                    SetXP(playerHandle,race,curXP-reqXP);

                    if (SAVE_ENABLED)
                        SavePlayerData(client,playerHandle,true,true);
                }
                else
                    m_Go=false;
            }
            else
                m_Go=false;
        }
    }
}

public ShowXP(client,Handle:playerHandle)
{
    if (GetRaceCount() >= 1)
    {
        new race=GetRace(playerHandle);
        if (race >= 0)
        {
            new level=GetLevel(playerHandle,race);
            decl String:racename[64];
            GetRaceName(GetRaceHandle(race),racename,sizeof(racename));
            if (level<MAX_LEVELS)
            {
                PrintToChat(client,"%c[SourceCraft] %c%s - Level %d - Experience %d / %d. (Overall Level %d)",
                            COLOR_GREEN,COLOR_DEFAULT,racename,level,
                            GetXP(playerHandle,race),ReqLevelXP(level+1),
                            GetOverallLevel(playerHandle));
            }
            else
            {
                PrintToChat(client,"%c[SourceCraft] %c%s - Level %d - Experience %d. (Overall Level %d)",
                            COLOR_GREEN,COLOR_DEFAULT,racename,level,
                            GetXP(playerHandle,race),GetOverallLevel(playerHandle));
            }
        }
    }
}

public GiveKillXP(index,Handle:playerHandle,victim_index,Handle:victim_player,bool:headshot,
                  bool:backstab,bool:melee,bool:dominated,bool:revenge,bool:assist)
{
    if (GetRaceCount() >= 1)
    {
        new amount;
        if (victim_player != INVALID_HANDLE)
            amount=KillXP(GetLevel(victim_player,GetRace(victim_player)));
        else
            amount=KillXP(GetLevel(playerHandle,GetRace(playerHandle)));

        if (headshot)
        {
            amount+=HEADSHOT_XP;
            PrintToChat(index,"%c[SourceCraft] %cYou get %d additional experience for a headshot.",
                        COLOR_GREEN,COLOR_DEFAULT,HEADSHOT_XP);
        }
        else if (backstab)
        {
            amount+=BACKSTAB_XP;
            PrintToChat(index,"%c[SourceCraft] %cYou get %d additional experience for a backstab.",
                        COLOR_GREEN,COLOR_DEFAULT,BACKSTAB_XP);
        }
        else if (melee)
        {
            amount+=MELEE_XP;
            PrintToChat(index,"%c[SourceCraft] %cYou get %d additional experience for a knife/shovel/wrench/etc kill.",
                        COLOR_GREEN,COLOR_DEFAULT,MELEE_XP);
        }

        if (dominated)
        {
            amount+=DOMINATED_XP;
            PrintToChat(index,"%c[SourceCraft] %cYou get %d additional experience for domination!",
                        COLOR_GREEN,COLOR_DEFAULT,DOMINATED_XP);
        }

        if (revenge)
        {
            amount+=REVENGE_XP;
            PrintToChat(index,"%c[SourceCraft] %cYou get %d additional experience for a revenge kill!",
                        COLOR_GREEN,COLOR_DEFAULT,DOMINATED_XP);
        }

        if (assist)
        {
            amount+=ASSIST_XP;
            PrintToChat(index,"%c[SourceCraft] %cYou get %d additional experience for assisting a kill.",
                        COLOR_GREEN,COLOR_DEFAULT,ASSIST_XP);
        }

        GiveXP(index,playerHandle,amount, assist ? "assisting a kill" : "getting a kill");
    }
}

public GiveDefuseXP(client,Handle:playerHandle)
{
    // Called when a player defuses the bomb
    GiveXP(client,playerHandle,DEFUSE_XP, "defusing the bomb");
}

public GivePlantXP(client,Handle:playerHandle)
{
    // Called when a player plants the bomb
    GiveXP(client,playerHandle,PLANT_XP, "planting the bomb");
}

public GiveHostageRescuedXP(client,Handle:playerHandle)
{
    // Called when a player rescues a hostage
    GiveXP(client,playerHandle,HOSTAGERESCUED_XP, "rescuing a hostage");
}

public GiveChargeDeployedXP(client,Handle:playerHandle)
{
    // Called when a player deploys thier charge (medic goes uber)
    GiveXP(client,playerHandle,CHARGE_XP, "deploying Ubercharge");
}

public GiveObjectBuiltXP(client,Handle:playerHandle)
{
    // Called when a player builds an object
    GiveXP(client,playerHandle,BUILD_XP, "building something");
}

public TakeObjectBuiltXP(client,Handle:playerHandle)
{
    // Called when a player destroys thier own object
    TakeXP(client,playerHandle,BUILD_XP, "destroying your own object");
}

public GiveObjectDestroyedXP(client,Handle:playerHandle)
{
    // Called when a player destroys an object
    GiveXP(client,playerHandle,DESTROY_XP, "destroying something");
}

public GiveFlagCapturedXP(client,Handle:playerHandle)
{
    // Called when a player captures a flag
    GiveXP(client,playerHandle,CAPTURE_FLAG_XP, "capturing the intelligence");
}

public GivePointCapturedXP(client,Handle:playerHandle)
{
    // Called when a player captures a point
    GiveXP(client,playerHandle,CAPTURE_POINT_XP, "capturing a point");
}

public GiveCaptureBlockedXP(client,Handle:playerHandle)
{
    // Called when a player blocks a capture
    GiveXP(client,playerHandle,BLOCK_XP, "blocking a point");
}

public GiveRoundWinXP(client,Handle:playerHandle)
{
    // Called when a team wins a round
    GiveXP(client,playerHandle,ROUND_WIN_XP, "winning a round");
}

public GiveGameWinXP(client,Handle:playerHandle,score)
{
    // Called when a team wins a round
    GiveXP(client,playerHandle,GAME_WIN_XP*score, "winning the game");
}

public GiveMvpXP(client,Handle:playerHandle,place,points)
{
    new String:reason[64];
    Format(reason,sizeof(reason),"being MVP #%d with %d points",place, points);
    GiveXP(client,playerHandle,points*place*MVP_XP,reason);
}

public GiveXP(client,Handle:playerHandle, amount, const String:reason[])
{
    if (GetRaceCount() >= 1)
    {
        // Called when a player is given XP
        new Action:result;
        Call_StartForward(g_OnXPGivenHandle);
        Call_PushCell(client);
        Call_PushCell(playerHandle);
        Call_PushCellRef(amount);
        Call_PushCell(false);
        Call_Finish(result);

        if (result != Plugin_Stop)
        {
            new race=GetRace(playerHandle);
            new newxp=GetXP(playerHandle,race)+amount;
            SetXP(playerHandle,race,newxp);
            LogToGame("%N gained %d experience for %s", client, amount, reason);
            PrintToChat(client,"%c[SourceCraft] %cYou have gained %d experience for %s.",
                    COLOR_GREEN,COLOR_DEFAULT,amount, reason);
            if(GetLevel(playerHandle,race)<MAX_LEVELS)
                DoLevelCheck(client,playerHandle);
        }
    }
}

public TakeXP(client,Handle:playerHandle, amount, const String:reason[])
{
    if (GetRaceCount() >= 1)
    {
        // Called when a player destroys thier own object
        new Action:result;
        Call_StartForward(g_OnXPGivenHandle);
        Call_PushCell(client);
        Call_PushCell(playerHandle);
        Call_PushCellRef(amount);
        Call_PushCell(true);
        Call_Finish(result);

        if (result != Plugin_Stop)
        {
            new race=GetRace(playerHandle);
            new newxp=GetXP(playerHandle,race)-amount;
            SetXP(playerHandle,race,newxp);
            LogToGame("%N lost %d experience for %s", client, amount, reason);
            PrintToChat(client,"%c[SourceCraft] %cYou have lost %d experience for %s.",
                    COLOR_GREEN,COLOR_DEFAULT,amount, reason);
            if(GetLevel(playerHandle,race)<MAX_LEVELS)
                DoLevelCheck(client,playerHandle);
        }
    }
}
