/**
 * File: War3Source_Races.inc
 * Description: Stocks regarding Races
 * Author(s): War3Source Team  
 */

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

//creates a new race, returns the race id
//a valid race is >0
#if !defined SOURCECRAFT
native War3_CreateNewRace(String:name[],String:shortname[]);
#else
stock War3_CreateNewRace(const String:name[],const String:shortname[])
{
    return CreateRace(shortname, .name=name, .initial_energy=0.0,
                      .energy_limit=0.0, .energy_rate=0.0);
}
#endif

//adds a skill or a ultimate
native War3_AddRaceSkill(raceid,String:tskillorultname[],String:tskillorultdescription[],bool:isult=false,maxskilllevel=DEF_MAX_SKILL_LEVEL);

//translated
//creates a new race, returns the race id
#if !defined SOURCECRAFT
native War3_CreateNewRaceT(String:shortname[]);
#else
stock War3_CreateNewRaceT(const String:shortname[])
{
    return CreateRace(shortname, .initial_energy=0.0,
                      .energy_limit=0.0, .energy_rate=0.0);
}
#endif

//translated
//adds a skill or a ultimate
//additional parameters replaces #1# #2# ... in the translation string (max 5)
// % does not need to be escaped
native War3_AddRaceSkillT(raceid,String:SkillNameIdentifier[],bool:isult=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);

//ends race creation!!! MUST CALL THIS!!!
#if !defined SOURCECRAFT
native War3_CreateRaceEnd(raceid);
#else
#define War3_CreateRaceEnd RaceComplete
#endif

#if !defined SOURCECRAFT
native War3_GetRaceName(raceid,String:retstr[],maxlen);
native War3_GetRaceShortname(raceid,String:retstr[],maxlen);
#else
#define War3_GetRaceName GetRaceName
#define War3_GetRaceShortname GetRaceShortName
#endif

#pragma deprecated Not Fully Implemented, possibly in the future
native W3GetRaceString(raceid,RaceString:property,String:retstr[],maxlen);
#pragma deprecated Not Fully Implemented, possibly in the future
native W3GetRaceSkillString(raceid,skillnum,SkillString:property,String:retstr[],maxlen);


//ALLOCATES an ID ( >0 ) for a generic skill, identified by gskillname
//recall safe
native War3_CreateGenericSkill(String:gskillname[]);

//genericSkillData is an array or trie that modifies behavior of that generic skill
//if NEW HANDLE is passed, OLD will NOT be closed (it is possible that it already closed if you unloaded the original race)
//this means you CAN recreate new handles and pass them, the old one will be closed
//recall safe
//returns a usual skill_id for the race
native War3_UseGenericSkill(raceid,String:gskillname[],Handle:genericSkillData,String:yourskillname[],String:untranslatedSkillDescription[]="ERR: No Skill Description Entered.",bool:translated=false,bool:isUltimate=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);

//is raceid, skillid using generic skill
//generic skillid id returned, otherwise 0 if its not using a generic skill
native W3_IsSkillUsingGenericSkill(raceid,skill_id);

#if !defined SOURCECRAFT
native War3_GetRacesLoaded();
native W3GetRaceMaxLevel(race);

native War3_IsSkillUltimate(raceid, skillnum);
native War3_GetRaceSkillCount(raceid);
native W3GetRaceSkillName(raceid,skillindex,String:retstr[],maxlen);
native W3GetRaceSkillDesc(raceid,skillindex,String:retstr[],maxlen);
native W3GetRaceSkillMaxLevel(raceid, skillnum);
#else
#define War3_GetRacesLoaded GetRaceCount
#define W3GetRaceMaxLevel GetRaceMaxLevel

#define War3_IsSkillUltimate GetRaceCategory
#define War3_GetRaceSkillCount GetUpgradeCount
#define W3GetRaceSkillName GetUpgradeName
#define W3GetRaceSkillDesc GetUpgradeDescription
#define W3GetRaceSkillMaxLevel GetUpgradeMaxLevel
#endif

#if !defined SOURCECRAFT // Not Implemented!
native W3GetRaceOrder(raceid);
//Flag is a generic string. We compare the race_flags cvar to the string you passed
native bool:W3RaceHasFlag(raceid,String:flag[]);

//returns a simple array of race IDs, sorted properly.
//Does not include "hidden" races
//pass array of MAXRACES, returns number of races in the array. starts at index 0
//ordered properly (war3_sort_minlevel or <shortname>_raceorder
//returns the size of the array
native W3GetRaceList(racelist[]);
#endif

//a valid race is >0
//returns 0 if not found
#if !defined SOURCECRAFT
native War3_GetRaceIDByShortname(String:raceshortname[]);
#else
#define War3_GetRaceIDByShortname FindRace
#endif

#if !defined SOURCECRAFT // Not Implemented!
native W3GetRaceAccessFlagStr(raceid,String:ret[],maxlen);
native W3GetRaceItemRestrictionsStr(raceid,String:ret[],maxlen);
native W3GetRaceMaxLimitTeam(raceid, team);
native W3GetRaceMaxLimitTeamCvar(raceid, team); //returns the internal cvar id (int not handle)
native W3GetRaceMinLevelRequired(raceid);
native W3IsRaceTranslated(raceid);

native W3GetRaceCell(raceid,ENUM_RaceObject:property);
native W3SetRaceCell(raceid,ENUM_RaceObject:property,any:somevalue);
#endif

//probably usefull since it allready gots a getbyshortname brother
stock War3_GetRaceIDByName(const String:racename[64]) {
    new RacesLoaded = War3_GetRacesLoaded();
    decl String:buffer[64],id;
    id=-1;//so.. -1 means invalid/not found
    for(new x=1;x<=RacesLoaded;x++)
    {
        War3_GetRaceName(x,buffer,sizeof(buffer));
        if(StrEqual(buffer,racename)) {
            id=x;
            break;
        }
    }
    return id;
}
