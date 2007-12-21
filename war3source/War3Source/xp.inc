/*
 * vim: set ai et ts=4 sw=4 :
 * File: xp.inc
 * Description: The name of the file is somewhat deciving... it is basically the
 *              file that handles all the XP you get for killing people and other
 *              stuff as well. 
 * Author(s): Anthony Iacono  
 * Modifications by: Naris (Murray Wilson)
 */
 
#define MAX_LEVELS 16
#define HEADSHOT_XP 10
#define KNIFE_XP 40
#define BACKSTAB_XP 60

#define DEFUSE_XP 20
#define PLANT_XP 20
#define HOSTAGERESCUED_XP 20

#define BUILD_XP 20
#define DESTROY_XP 20
#define BLOCK_XP 20
#define CAPTURE_FLAG_XP 20
#define CAPTURE_POINT_XP 20

// Functions called from menus.inc
public War3Source_SkillMenu(client,vectorpos);

public DoLevelCheck(client,vectorpos)
{
    new bool:m_Go=true;
    while(m_Go)
    {
        new curlevel=GetLevel(vectorpos,GetRace(vectorpos));
        if(curlevel<MAX_LEVELS)
        {
            if(GetXP(vectorpos,GetRace(vectorpos))>=ReqLevelXP(curlevel+1))
            {
                    SetLevel(vectorpos,GetRace(vectorpos),GetLevel(vectorpos,GetRace(vectorpos))+1);
                    War3Source_SkillMenu(client,vectorpos);
                    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou are now level %d.",COLOR_GREEN,COLOR_DEFAULT,GetLevel(vectorpos,GetRace(vectorpos)));
                    SetXP(vectorpos,GetRace(vectorpos),GetXP(vectorpos,GetRace(vectorpos))-ReqLevelXP(curlevel+1));
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
    new level=GetLevel(vecpos,race);
    decl String:racename[64];
    new Handle:racedata=Race(race);
    GetArrayString(racedata,0,racename,63);
    if(level!=MAX_LEVELS)
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %c%s - Level %d - %d XP / %d XP.",COLOR_GREEN,COLOR_DEFAULT,racename,level,GetXP(vecpos,race),ReqLevelXP(level+1));
    else
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %c%s - Level %d - %d XP.",COLOR_GREEN,COLOR_DEFAULT,racename,level,GetXP(vecpos,race));
}
 
public GiveKillXP(client,vectorpos,victim,bool:headshot,bool:knife,bool:backstab)
{
    new newxp,killxp;
    new race=GetRace(vectorpos);
    if(victim>0)
    {
        new vic_vec=GetClientVectorPosition(victim);
        killxp=KillXP(GetLevel(vic_vec,GetRace(vic_vec)));
    }
    else
        killxp=KillXP(GetLevel(vectorpos,GetRace(vectorpos)));

    newxp+=GetXP(vectorpos,GetRace(vectorpos))+killxp;

    if (headshot)
    {
        newxp+=HEADSHOT_XP;
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou get %d additional XP for a headshot.",COLOR_GREEN,COLOR_DEFAULT,HEADSHOT_XP);
    }
    else if (backstab)
    {
        newxp+=BACKSTAB_XP;
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou get %d additional XP for a backstab.",COLOR_GREEN,COLOR_DEFAULT,BACKSTAB_XP);
    }
    else if (knife)
    {
        newxp+=KNIFE_XP;
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou get %d additional XP for a knife/shovel/wrench/etc kill.",COLOR_GREEN,COLOR_DEFAULT,KNIFE_XP);
    }

    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for getting a kill.",COLOR_GREEN,COLOR_DEFAULT,killxp);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}
 
public GiveDefuseXP(client,vectorpos)
{
    // Called when a player defuses the bomb
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+DEFUSE_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for defusing the bomb.",COLOR_GREEN,COLOR_DEFAULT,DEFUSE_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}

public GivePlantXP(client,vectorpos)
{
    // Called when a player plants the bomb
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+PLANT_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for planting the bomb.",COLOR_GREEN,COLOR_DEFAULT,PLANT_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}

public GiveHostageRescuedXP(client,vectorpos)
{
    // Called when a player rescues a hostage
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+HOSTAGERESCUED_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for rescuing a hostage.",COLOR_GREEN,COLOR_DEFAULT,HOSTAGERESCUED_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}

public GiveObjectBuiltXP(client,vectorpos)
{
    // Called when a player captures a flag
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+DESTROY_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for building something.",COLOR_GREEN,COLOR_DEFAULT,BUILD_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}

public GiveObjectDestroyedXP(client,vectorpos)
{
    // Called when a player captures a flag
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+DESTROY_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for destroying something.",COLOR_GREEN,COLOR_DEFAULT,DESTROY_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}

public GiveFlagCapturedXP(client,vectorpos)
{
    // Called when a player captures a flag
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+CAPTURE_FLAG_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for capturing the flag.",COLOR_GREEN,COLOR_DEFAULT,CAPTURE_FLAG_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}

public GivePointCapturedXP(client,vectorpos)
{
    // Called when a player captures a point
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+CAPTURE_POINT_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for capturing a point.",COLOR_GREEN,COLOR_DEFAULT,CAPTURE_POINT_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}

public GiveCaptureBlockedXP(client,vectorpos)
{
    // Called when a player blocks a capture
    new newxp;
    new race=GetRace(vectorpos);
    newxp=GetXP(vectorpos,race)+BLOCK_XP;
    SetXP(vectorpos,race,newxp);
    War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have gained %d XP for blocking a point.",COLOR_GREEN,COLOR_DEFAULT,BLOCK_XP);
    if(GetLevel(vectorpos,race)!=MAX_LEVELS)
        DoLevelCheck(client,vectorpos);
}
