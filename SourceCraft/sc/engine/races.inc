/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: races.inc
 * Description: The root of all race specific stuff.
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 * Credits: Anthony Iacono
 */

#include "sc/cooldown"

#define RACE_STRINGS                             0
#define RACE_MESSAGES                            1
#define RACE_UPGRADES                            2
#define RACE_IDENT                               3
#define RACE_REQUIRED_LEVEL                      4
#define RACE_TECH_LEVEL                          5
#define RACE_MAX_LEVEL                           6
#define RACE_INITIAL_ENERGY                      7
#define RACE_ENERGY_LIMIT                        8
#define RACE_ENERGY_RATE                         9
#define RACE_ENERGY_FLAGS                       10
#define RACE_FACTION                            11
#define RACE_TYPE                               12
#define RACE_ID                                 13
#define RACE_IS_NEW                             14
#define RACE_PARENT_ID                          15
#define RACE_TRANSLATION                        16
#define RACE_CONFIG_HANDLE                      17
#define RACE_CONFIG_LOADED                      18
#define RACE_COMPLETED                          19

#define RACE_NAME                                0
#define RACE_SHORT_NAME                          1
#define RACE_PARENT_NAME                         2

#define RACE_SWITCHMESSAGE                       0
#define RACE_SWITCHMESSAGE_DEAD                  1
#define RACE_TRANSLATIONFILE                     2

#define UPGRADE_STRINGS                          0
#define UPGRADE_ENERGY                           1
#define UPGRADE_RECURRING_ENERGY                 2
#define UPGRADE_ACCUMULATED                      3
#define UPGRADE_CRYSTALS                         4
#define UPGRADE_VESPENE                          5
#define UPGRADE_COOLDOWN                         6
#define UPGRADE_COOLDOWN_TYPE                    7
#define UPGRADE_REQUIRED_LEVEL                   8
#define UPGRADE_MAX_LEVEL                        9
#define UPGRADE_COST_CRYSTALS                   10
#define UPGRADE_COST_VESPENE                    11
#define UPGRADE_CATEGORY                        12
#define UPGRADE_DISABLED                        13
#define UPGRADE_DATA_COUNT                      14

#define UPGRADE_NAME                             0
#define UPGRADE_SHORT_NAME                       1
#define UPGRADE_DESC                             2
#define UPGRADE_PARM                             3

// Valid values for *_CONFIG_LOADED
#define CONFIG_NOT_LOADED                        0
#define CONFIG_WAS_LOADED                        1
#define CONFIG_WAS_UPDATED                       2

// Race Energy Use Flags
#define RACE_NO_ENERGY                           0
#define RACE_USES_ENERGY                         1
#define RACE_USES_ACCUMULATED                    2

// Accessor Macros for Race & Index Arrays
#define GetRaceCount()                           GetArraySize(raceArray)
#define GetRaceIndexCount()                      GetArraySize(raceIndex)

#define GetRaceHandle(%1)                        (Handle:GetArrayCell(raceArray,%1))
#define GetRaceIndexHandle(%1)                   (Handle:GetArrayCell(raceIndex,%1))

// Accessor Macros for Race Data
#define GetRaceId(%1)                            GetArrayCell(%1,RACE_ID)
#define SetRaceId(%1,%2)                         SetArrayCell(%1,RACE_ID,%2)

#define GetRaceIdent(%1)                         GetArrayCell(%1,RACE_IDENT)
#define SetRaceIdent(%1,%2)                      SetArrayCell(%1,RACE_IDENT,%2)

#define GetRaceRequiredLevel(%1)                 GetArrayCell(%1,RACE_REQUIRED_LEVEL)
#define SetRaceRequiredLevel(%1,%2)              SetArrayCell(%1,RACE_REQUIRED_LEVEL,%2)

#define GetRaceTechLevel(%1)                     GetArrayCell(%1,RACE_TECH_LEVEL)
#define SetRaceTechLevel(%1,%2)                  SetArrayCell(%1,RACE_TECH_LEVEL,%2)

#define GetRaceMaxLevel(%1)                      GetArrayCell(%1,RACE_MAX_LEVEL)
#define SetRaceMaxLevel(%1,%2)                   SetArrayCell(%1,RACE_MAX_LEVEL,%2)

#define GetRaceInitialEnergy(%1)                 Float:GetArrayCell(%1,RACE_INITIAL_ENERGY)
#define SetRaceInitialEnergy(%1,%2)              SetArrayCell(%1,RACE_INITIAL_ENERGY,%2)

#define GetRaceEnergyLimit(%1)                   Float:GetArrayCell(%1,RACE_ENERGY_LIMIT)
#define SetRaceEnergyLimit(%1,%2)                SetArrayCell(%1,RACE_ENERGY_LIMIT,%2)

#define GetRaceEnergyRate(%1)                    Float:GetArrayCell(%1,RACE_ENERGY_RATE)
#define SetRaceEnergyRate(%1,%2)                 SetArrayCell(%1,RACE_ENERGY_RATE,%2)

#define GetRaceEnergyFlags(%1)                   GetArrayCell(%1,RACE_ENERGY_FLAGS)
#define SetRaceEnergyFlags(%1,%2)                SetArrayCell(%1,RACE_ENERGY_FLAGS,%2)

#define GetRaceFaction(%1)                       (Faction:GetArrayCell(%1,RACE_FACTION))
#define SetRaceFaction(%1,%2)                    SetArrayCell(%1,RACE_FACTION,_:%2)

#define GetRaceType(%1)                          (UnitType:GetArrayCell(%1,RACE_TYPE))
#define SetRaceType(%1,%2)                       SetArrayCell(%1,RACE_TYPE,_:%2)

#define GetRaceIsNew(%1)                         (bool:GetArrayCell(%1,RACE_IS_NEW))
#define SetRaceIsNew(%1,%2)                      SetArrayCell(%1,RACE_IS_NEW,%2)

#define GetRaceConfigHandle(%1)                  (Handle:GetArrayCell(%1,RACE_CONFIG_HANDLE))
#define SetRaceConfigHandle(%1,%2)               SetArrayCell(%1,RACE_CONFIG_HANDLE,_:%2)

#define GetRaceConfigIsLoaded(%1)                GetArrayCell(%1,RACE_CONFIG_LOADED)
#define SetRaceConfigIsLoaded(%1,%2)             SetArrayCell(%1,RACE_CONFIG_LOADED,%2)

#define GetRaceHasBeenCompleted(%1)              (bool:GetArrayCell(%1,RACE_COMPLETED))
#define SetRaceHasBeenCompleted(%1,%2)           SetArrayCell(%1,RACE_COMPLETED,%2)

#define GetRaceTranslation(%1)                   (Translation:GetArrayCell(%1,RACE_TRANSLATION))
#define SetRaceTranslation(%1,%2)                SetArrayCell(%1,RACE_TRANSLATION,_:%2)

// Accessor Macros for Race Strings
#define GetRaceStringHandle(%1)                  GetArrayCell(%1,RACE_STRINGS)

#define GetRaceShortName(%1,%2,%3)               GetArrayString(GetRaceStringHandle(%1),RACE_SHORT_NAME,%2,%3)
#define SetRaceShortName(%1,%2)                  SetArrayString(GetRaceStringHandle(%1),RACE_SHORT_NAME,%2)

#define GetRaceNameString(%1,%2,%3)              GetArrayString(GetRaceStringHandle(%1),RACE_NAME,%2,%3)
#define SetRaceName(%1,%2)                       SetArrayString(GetRaceStringHandle(%1),RACE_NAME,%2)

#define GetRaceParentName(%1,%2,%3)              GetArrayString(GetRaceStringHandle(%1),RACE_PARENT_NAME,%2,%3)
#define SetRaceParentName(%1,%2)                 SetArrayString(GetRaceStringHandle(%1),RACE_PARENT_NAME,%2)

// Accessor Macros for Race Messages
#define GetRaceMessageHandle(%1)                 GetArrayCell(%1,RACE_MESSAGES)

#define GetRaceSwitchString(%1,%2,%3)            GetArrayString(GetRaceMessageHandle(%1),RACE_SWITCHMESSAGE,%2,%3)
#define SetRaceSwitchString(%1,%2)               SetArrayString(GetRaceMessageHandle(%1),RACE_SWITCHMESSAGE,%2)

#define GetRaceSwitchStringDead(%1,%2,%3)        GetArrayString(GetRaceMessageHandle(%1),RACE_SWITCHMESSAGE_DEAD,%2,%3)
#define SetRaceSwitchStringDead(%1,%2)           SetArrayString(GetRaceMessageHandle(%1),RACE_SWITCHMESSAGE_DEAD,%2)

#define GetRaceTranslationFile(%1,%2,%3)         GetArrayString(GetRaceMessageHandle(%1),RACE_TRANSLATIONFILE,%2,%3)
#define SetRaceTranslationFile(%1,%2)            SetArrayString(GetRaceMessageHandle(%1),RACE_TRANSLATIONFILE,%2)

// Accessor Macros for Upgrade Data
#define GetUpgradeListHandle(%1)                 GetArrayCell(%1,RACE_UPGRADES)
#define GetUpgradeHandle(%1,%2)                  GetArrayCell(GetUpgradeListHandle(%1),%2)

#define GetUpgradeEnergy(%1,%2)                  Float:GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_ENERGY)
#define SetUpgradeEnergy(%1,%2,%3)               SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_ENERGY,%3)

#define GetUpgradeRecurringEnergy(%1,%2)         Float:GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_RECURRING_ENERGY)
#define SetUpgradeRecurringEnergy(%1,%2,%3)      SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_RECURRING_ENERGY,%3)

#define GetUpgradeCanUseAccumulated(%1,%2)          (bool:GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_ACCUMULATED))
#define SetUpgradeUseAccumulated(%1,%2,%3)       SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_ACCUMULATED,_:%3)

#define GetUpgradeCrystals(%1,%2)                GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_CRYSTALS)
#define SetUpgradeCrystals(%1,%2,%3)             SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_CRYSTALS,%3)

#define GetUpgradeVespene(%1,%2)                 GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_VESPENE)
#define SetUpgradeVespene(%1,%2,%3)              SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_VESPENE,%3)

#define GetUpgradeCostCrystals(%1,%2)            GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COST_CRYSTALS)
#define SetUpgradeCostCrystals(%1,%2,%3)         SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COST_CRYSTALS,%3)

#define GetUpgradeCostVespene(%1,%2)             GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COST_VESPENE)
#define SetUpgradeCostVespene(%1,%2,%3)          SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COST_VESPENE,%3)

#define GetUpgradeCooldownDuration(%1,%2)        (Float:GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COOLDOWN))
#define SetUpgradeCooldownDuration(%1,%2,%3)     SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COOLDOWN,_:%3)

#define GetUpgradeCooldownType(%1,%2)            (CooldownType:GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COOLDOWN_TYPE))
#define SetUpgradeCooldownType(%1,%2,%3)         SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_COOLDOWN_TYPE,_:%3)

#define GetUpgradeRequiredLevel(%1,%2)           GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_REQUIRED_LEVEL)
#define SetUpgradeRequiredLevel(%1,%2,%3)        SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_REQUIRED_LEVEL,%3)

#define GetUpgradeMaxLevel(%1,%2)                GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_MAX_LEVEL)
#define SetUpgradeMaxLevel(%1,%2,%3)             SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_MAX_LEVEL,%3)

#define GetUpgradeCategory(%1,%2)                GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_CATEGORY)
#define SetUpgradeCategory(%1,%2,%3)             SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_CATEGORY,%3)

#define GetUpgradeDisabled(%1,%2)                GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_DISABLED)
#define SetUpgradeDisabled(%1,%2,%3)             SetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_DISABLED,%3)

// Accessor Macros for Upgrade Strings
#define GetUpgradeStringHandle(%1,%2)            GetArrayCell(GetUpgradeHandle(%1,%2),UPGRADE_STRINGS)

#define GetUpgradeShortName(%1,%2,%3,%4)         GetArrayString(GetUpgradeStringHandle(%1,%2),UPGRADE_SHORT_NAME,%3,%4)
#define SetUpgradeShortName(%1,%2,%3)            SetArrayString(SetUpgradeStringHandle(%1,%2),UPGRADE_SHORT_NAME,%3)

#define GetUpgradeNameString(%1,%2,%3,%4)        GetArrayString(GetUpgradeStringHandle(%1,%2),UPGRADE_NAME,%3,%4)
#define SetUpgradeName(%1,%2,%3)                 SetArrayString(SetUpgradeStringHandle(%1,%2),UPGRADE_NAME,%3)

#define GetUpgradeDescriptionString(%1,%2,%3,%4) GetArrayString(GetUpgradeStringHandle(%1,%2),UPGRADE_DESC,%3,%4)
#define SetUpgradeDescription(%1,%2,%3)          SetArrayString(SetUpgradeStringHandle(%1,%2),UPGRADE_DESC,%3)

#define GetUpgradeParameter(%1,%2,%3,%4,%5)      GetArrayString(GetUpgradeStringHandle(%1,%2),UPGRADE_PARM+%3,%4,%5)
#define SetUpgradeParameter(%1,%2,%3,%4)         SetArrayString(SetUpgradeStringHandle(%1,%2),UPGRADE_PARM+%3,%4)

// A vector of race infomation
new Handle:raceArray = INVALID_HANDLE;
new Handle:raceIndex = INVALID_HANDLE;

bool:InitRaceArray()
{
    if (raceArray == INVALID_HANDLE)
    {
        raceArray = CreateArray();

        #if defined _TRACE
            LogMessage("CreateArray raceArray=0x%08x", raceArray);
        #endif
    }

    if (raceIndex == INVALID_HANDLE)
    {
        raceIndex = CreateArray();

        #if defined _TRACE
            LogMessage("CreateArray raceIndex=0x%08x", raceIndex);
        #endif
    }

    if (raceArray != INVALID_HANDLE &&
        raceIndex != INVALID_HANDLE)
    {
        // Use up the the 0 index so actual races start at 1
        #if defined _TRACE
            PushArrayCell(raceArray, INVALID_HANDLE);
            PushArrayCell(raceIndex, INVALID_HANDLE);
        #else
            new raceZero = CreateRace("", -1, -1, -1, 0.0, 0.0, 0.0, Generic, GenericUnit, "", Translation_None);
            RaceComplete(raceZero);
        #endif
        return true;
    }
    else
        return false;
}

ClearRaceArray()
{
    TraceInto("Race", "ClearRaceArray");

    if (raceArray == INVALID_HANDLE)
    {
        new raceCount = GetRaceCount();
        for(new race=1;race<raceCount;race++)
        {
            new Handle:raceHandle=GetArrayCell(raceArray,race);
            new Handle:upgradeListHandle=GetUpgradeListHandle(raceHandle);
            new upgradeCount = GetArraySize(upgradeListHandle);
            for(new upgrade=0;upgrade<upgradeCount;upgrade++)
            {
                new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
                new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);

                ClearArray(upgradeHandle);
                CloseHandle(upgradeHandle);
                ClearArray(upgradeStringHandle);
                CloseHandle(upgradeStringHandle);

                TraceCat("Array", "CloseArray raceUpgradeHandle[%d,%d]=0x%08x", \
                         race, upgrade, upgradeHandle);

                TraceCat("Array", "CloseArray raceUpgradeStringHandle[%d,%d]=0x%08x", \
                         race, upgrade, upgradeStringHandle);
            }

            new Handle:stringsHandle=GetRaceStringHandle(raceHandle);
            ClearArray(stringsHandle);
            CloseHandle(stringsHandle);

            new Handle:messagesHandle=GetRaceMessageHandle(raceHandle);
            ClearArray(messagesHandle);
            CloseHandle(messagesHandle);

            ClearArray(upgradeListHandle);
            CloseHandle(upgradeListHandle);

            ClearArray(raceHandle);
            CloseHandle(raceHandle);

            TraceCat("Array", "CloseArray raceStringsHandle[%d]=0x%08x", \
                     race, stringsHandle);

            TraceCat("Array", "CloseArray raceMessagesHandle[%d]=0x%08x", \
                     race, messagesHandle);

            TraceCat("Array", "CloseArray raceUpgradeListHandle[%d]=0x%08x", \
                     race, upgradeListHandle);

            TraceCat("Array", "CloseArray raceHandle[%d]=0x%08x", \
                     race, raceHandle);
        }

        TraceCat("Array", "CloseArray raceArray=0x%08x", raceArray);
        TraceCat("Array", "CloseArray raceIndex=0x%08x", raceIndex);

        ClearArray(raceArray);
        CloseHandle(raceArray);
        raceArray = INVALID_HANDLE;

        ClearArray(raceIndex);
        CloseHandle(raceIndex);
        raceIndex = INVALID_HANDLE;
    }

    TraceReturn();
}

CreateRace(const String:short[], required_level=0, tech_level=0, max_level=16,
           Float:initial_energy=30.0, Float:energy_limit=100.0, Float:energy_rate=1.0, Faction:faction=Generic,
           UnitType:type=GenericUnit, const String:parent[]="", Translation:translation=Translation_Auto,
           const String:translation_file[]="", const String:name[]="", const String:switch_message[]="",
           const String:pending_message[]="", const String:desc[]="", const String:image[]="")
{
    new Handle:raceConfig;
    new Handle:raceHandle;
    new raceLoaded;

    TraceInto("Race", "CreateRace", "short=%s, required_level=%d, tech_level=%d, max_level=%d, initial_energy=%f, energy_limit=%f, energy_rate=%f, faction=%d, type=%d, parent=%s, translation=%d, file=%s, name=%s, switch_message=%s, pending_message=%s, image=%s, desc=%s", short, required_level, tech_level, max_level, initial_energy, energy_limit, energy_rate, faction, type, parent, translation, translation_file, name, switch_message, pending_message, image, desc);

    // Load translation_file, if any
    decl String:translation_path[PLATFORM_MAX_PATH];
    if (translation_file[0] != '\0')
    {
        strcopy(translation_path, sizeof(translation_path), translation_file);
        LoadTranslations(translation_file);
        if (translation < Translation_Custom)
            translation = Translation_Custom;
    }
    else
        translation_path[0] = '\0';

    // Load race config, if any
    if (short[0] == '\0')
        raceConfig = INVALID_HANDLE;
    else
    {
        raceConfig = LoadRaceConfig(short, raceLoaded);
        if (raceLoaded == CONFIG_NOT_LOADED)
        {
            if (faction == Unassigned)
                KvSetNum(raceConfig,"faction", _:faction);

            if (type == UnassignedUnit)
                KvSetNum(raceConfig,"unit_type", _:type);

            if (required_level >= 0)
                KvSetNum(raceConfig,"required_level", required_level);

            if (tech_level >= 0)
                KvSetNum(raceConfig,"tech_level", tech_level);

            if (initial_energy > 0.0)
                KvSetFloat(raceConfig,"initial_energy", initial_energy);

            if (energy_rate > 0.0)
                KvSetFloat(raceConfig,"energy_rate", energy_rate);

            if (energy_limit > 0)
                KvSetFloat(raceConfig,"energy_limit", energy_limit);
        }
        else
        {
            faction = Faction:KvGetNum(raceConfig,"faction", _:faction);
            type = UnitType:KvGetNum(raceConfig,"unit_type", _:type);
            required_level = KvGetNum(raceConfig,"required_level", required_level);
            tech_level = KvGetNum(raceConfig,"tech_level", tech_level);
            initial_energy = KvGetFloat(raceConfig,"initial_energy", initial_energy);
            energy_rate = KvGetFloat(raceConfig,"energy_rate", energy_rate);
            energy_limit = KvGetFloat(raceConfig,"energy_limit", energy_limit);
        }

        if (translation_file[0] == '\0')
        {
            // Check for and Load Translations, if any
            decl String:file[NAME_STRING_LENGTH];

            switch (translation)
            {
                case Translation_SC:
                {
                    Format(file,sizeof(file),"sc.%s.phrases.txt",short);
                    BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                    if (FileExists(translation_path))
                        LoadTranslations(file);
                    else
                    {
                        Format(file,sizeof(file),"%s.phrases.txt",short);
                        BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                        LoadTranslations(file);
                    }
                }
                case Translation_W3S:
                {
                    Format(file,sizeof(file),"w3s.race.%s.phrases.txt",short);
                    BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                    LoadTranslations(file);
                }
                case Translation_Auto, Translation_Default, Translation_Custom:
                {
                    // Check for SourceCraft translations
                    Format(file,sizeof(file),"sc.%s.phrases.txt",short);
                    BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                    if (FileExists(translation_path))
                    {
                        translation = Translation_SC;
                        LoadTranslations(file);
                    }
                    else
                    {
                        // Check for SourceCraft translations without the prefix
                        Format(file,sizeof(file),"%s.phrases.txt",short);
                        BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                        if (FileExists(translation_path))
                        {
                            translation = Translation_SC;
                            LoadTranslations(file);
                        }
                        else
                        {
                            // Check for War3Source translations
                            Format(file,sizeof(file),"w3s.race.%s.phrases.txt",short);
                            BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/%s", file);
                            if (FileExists(translation_path))
                            {
                                translation = Translation_W3S;
                                LoadTranslations(file);
                            }
                            else
                                translation = Translation_None;
                        }
                    }
                }
            }
        }
    }

    new raceId = FindRace(short);
    if (raceId > 0)
    {
        raceHandle=GetRaceHandle(raceId);

        // Toss out the old config handle, if any.
        new Handle:oldConfig = GetRaceConfigHandle(raceHandle);
        if (oldConfig != INVALID_HANDLE)
            CloseHandle(oldConfig);

        // Assign the new values
        SetRaceRequiredLevel(raceHandle,required_level);
        SetRaceTechLevel(raceHandle,tech_level);
        SetRaceMaxLevel(raceHandle,max_level);
        SetRaceInitialEnergy(raceHandle,initial_energy);
        SetRaceEnergyLimit(raceHandle,energy_limit);
        SetRaceEnergyRate(raceHandle,energy_rate);
        SetRaceFaction(raceHandle,faction);
        SetRaceType(raceHandle,type);
        SetRaceTranslation(raceHandle,translation);
        SetRaceConfigHandle(raceHandle,raceConfig);
        SetRaceConfigIsLoaded(raceHandle,raceLoaded);
        SetRaceHasBeenCompleted(raceHandle,false);

        new Handle:messagesHandle=GetRaceMessageHandle(raceHandle);
        SetArrayString(messagesHandle,RACE_SWITCHMESSAGE,switch_message);
        SetArrayString(messagesHandle,RACE_SWITCHMESSAGE_DEAD,pending_message);
        SetArrayString(messagesHandle,RACE_TRANSLATIONFILE,translation_path);

        new Handle:stringsHandle=GetRaceStringHandle(raceHandle);
        SetArrayString(stringsHandle,RACE_NAME,name);
        SetArrayString(stringsHandle,RACE_SHORT_NAME,short);
        SetArrayString(stringsHandle,RACE_PARENT_NAME,parent);
    }
    else
    {
        // Setup Race Strings.
        new Handle:messagesHandle=CreateArray(ByteCountToCells(LONG_STRING_LENGTH));
        PushArrayString(messagesHandle,switch_message);
        PushArrayString(messagesHandle,pending_message);
        PushArrayString(messagesHandle,translation_path);

        // Setup Race Messages.
        new Handle:stringsHandle=CreateArray(ByteCountToCells(NAME_STRING_LENGTH));
        PushArrayString(stringsHandle,name);
        PushArrayString(stringsHandle,short);
        PushArrayString(stringsHandle,parent);

        // Setup Race Upgrade array.
        new Handle:upgradeListHandle=CreateArray();

        // Setup race_ident and is_new flag
        new raceIdent;
        if (short[0] == '\0')
            raceIdent = 0;
        else if (faction <= Unassigned)
            raceIdent = LoadRaceData(short, faction, type);
        else
            raceIdent = LoadRaceIdent(short);

        new bool:raceIsNew = (raceIdent < 0);

        if (faction <= Unassigned)
            faction = Generic;

        if (type <= UnassignedUnit)
            type = GenericUnit;

        // Setup Race Data.
        raceHandle=CreateArray();
        PushArrayCell(raceHandle,stringsHandle);
        PushArrayCell(raceHandle,messagesHandle);
        PushArrayCell(raceHandle,upgradeListHandle);
        PushArrayCell(raceHandle,raceIdent);
        PushArrayCell(raceHandle,required_level);
        PushArrayCell(raceHandle,tech_level);
        PushArrayCell(raceHandle,max_level);
        PushArrayCell(raceHandle,initial_energy);
        PushArrayCell(raceHandle,energy_limit);
        PushArrayCell(raceHandle,energy_rate);
        PushArrayCell(raceHandle,false); // accumulated
        PushArrayCell(raceHandle,faction);
        PushArrayCell(raceHandle,type);

        // Add new Race Data into Race Array.
        raceId = PushArrayCell(raceArray,raceHandle); // return index.
        PushArrayCell(raceHandle,raceId);
        PushArrayCell(raceHandle,raceIsNew);
        PushArrayCell(raceHandle,0); // parent id
        PushArrayCell(raceHandle,translation);
        PushArrayCell(raceHandle,raceConfig); // config handle
        PushArrayCell(raceHandle,raceLoaded); // config loaded
        PushArrayCell(raceHandle,false); // completed

        SetTraceCategory("Array");
        Trace("CreateArray raceHandle[%d]=0x%08x", raceId, raceHandle);
        Trace("CreateArray raceMessagesHandle[%d]=0x%08x", raceId, messagesHandle);
        Trace("CreateArray raceStringsHandle[%d]=0x%08x", raceId, stringsHandle);
        Trace("CreateArray raceUpgradeListHandle[%d]=0x%08x", raceId, upgradeListHandle);

        if (raceIsNew)
        {
            if (faction <= Unassigned)
                faction = Generic;

            if (type <= UnassignedUnit)
                type = GenericUnit;

            if (translation > Translation_Auto)
            {
                decl String:raceName[NAME_STRING_LENGTH];
                GetRaceName(raceHandle, raceName, sizeof(raceName));

                decl String:raceDesc[DESCRIPTION_LENGTH];
                GetRaceDescription(raceHandle, raceDesc, sizeof(raceDesc), desc);

                decl String:raceImage[NAME_STRING_LENGTH];
                GetRaceImage(raceHandle, raceImage, sizeof(raceImage), image);

                raceIdent = InsertRace(short, raceName, required_level, tech_level,
                                       parent, faction, type, raceDesc, raceImage);
            }
            else
            {
                raceIdent = InsertRace(short, name, required_level, tech_level,
                                       parent, faction, type, desc, image);
            }

            SetRaceIdent(raceHandle, raceIdent);
        }
        else if (raceIdent > 0 && faction > Unassigned && (g_bCreate || g_bUpdate))
        {
            if (translation > Translation_Auto)
            {
                decl String:raceName[NAME_STRING_LENGTH];
                GetRaceName(raceHandle, raceName, sizeof(raceName));

                decl String:raceDesc[DESCRIPTION_LENGTH];
                GetRaceDescription(raceHandle, raceDesc, sizeof(raceDesc), desc);

                decl String:raceImage[NAME_STRING_LENGTH];
                GetRaceImage(raceHandle, raceImage, sizeof(raceImage), image);

                UpdateRace(raceIdent, short, raceName, required_level, tech_level,
                           parent, faction, type, raceDesc, raceImage);
            }
            else
            {
                UpdateRace(raceIdent, short, name, required_level, tech_level,
                           parent, faction, type, desc, image);
            }
        }
    }

    TraceReturn("short=%s, raceId=%d, raceHandle=0x%08x", short, raceId, raceHandle);
    return raceId;
}

RaceComplete(race, const String:desc[]="", const String:image[]="")
{
    new Handle:raceHandle = GetRaceHandle(race);
    if (raceHandle != INVALID_HANDLE)
    {
        SetRaceHasBeenCompleted(raceHandle,true);

        // Add new Race Data into Race Index.
        decl String:raceName[NAME_STRING_LENGTH];
        GetRaceName(raceHandle, raceName, sizeof(raceName));

        decl String:raceFactionName[NAME_STRING_LENGTH];
        GetFactionName(GetRaceFaction(raceHandle),raceFactionName,sizeof(raceFactionName));

        decl String:raceParent[NAME_STRING_LENGTH];
        GetRaceParentName(raceHandle,raceParent,sizeof(raceParent));
        new raceLevel = (raceParent[0] != '\0') ? 32767 : GetRaceRequiredLevel(raceHandle);
        if (raceLevel < 0)
            raceLevel = 65535;

        new index=1;
        new indexCount=GetRaceIndexCount();
        for(;index<indexCount;index++)
        {
            decl String:indexFactionName[NAME_STRING_LENGTH];
            new Handle:indexHandle = GetRaceIndexHandle(index);
            new Faction:indexFaction = GetRaceFaction(indexHandle);
            GetFactionName(indexFaction,indexFactionName,sizeof(indexFactionName));
            new cmpFaction = strcmp(raceFactionName,indexFactionName,false);
            if (cmpFaction <= 0)
            {
                decl String:indexParent[SHORT_STRING_LENGTH];
                GetRaceParentName(indexHandle,indexParent,sizeof(indexParent));
                new indexLevel = (indexParent[0] != '\0') ? 32767 : GetRaceRequiredLevel(indexHandle);
                if (indexLevel < 0)
                    indexLevel = 65535;

                if (cmpFaction <= 0 || raceLevel <= indexLevel)
                {
                    decl String:indexName[NAME_STRING_LENGTH];
                    GetRaceName(indexHandle, indexName, sizeof(indexName));
                    if (cmpFaction < 0 || raceLevel < indexLevel ||
                        (cmpFaction == 0 && raceLevel == indexLevel &&
                         strcmp(raceName,indexName,false) < 0))
                    {
                        ShiftArrayUp(raceIndex, index);
                        SetArrayCell(raceIndex, index, raceHandle);
                        indexCount++;
                        break;
                    }
                }
            }
        }

        if (index >= indexCount)
            PushArrayCell(raceIndex,raceHandle);

        // Save and Close the race's config file
        new Handle:raceConfig = GetRaceConfigHandle(raceHandle);
        if (raceConfig != INVALID_HANDLE)
        {
            if (GetRaceConfigIsLoaded(raceHandle) != CONFIG_WAS_LOADED)
            {
                decl String:short[SHORT_STRING_LENGTH];
                GetRaceShortName(raceHandle, short, sizeof(short));
                SaveConfig(raceConfig, short);
            }

            CloseHandle(raceConfig);
            SetRaceConfigHandle(raceHandle,INVALID_HANDLE);
            SetRaceConfigIsLoaded(raceHandle,CONFIG_NOT_LOADED);
        }

        // Update the database, if specified
        if (g_bCreate || g_bUpdate)
        {
            new raceIdent = GetRaceIdent(raceHandle);
            new Faction:faction = GetRaceFaction(raceHandle);
            if (raceIdent > 0 && faction > Unassigned)
            {
                new tech_level = GetRaceTechLevel(raceHandle);
                new required_level = GetRaceRequiredLevel(raceHandle);
                new UnitType:type = GetRaceType(raceHandle);

                decl String:short[SHORT_STRING_LENGTH];
                GetRaceShortName(raceHandle, short, sizeof(short));

                decl String:raceDesc[DESCRIPTION_LENGTH];
                GetRaceDescription(raceHandle, raceDesc, sizeof(raceDesc), desc);

                decl String:raceImage[NAME_STRING_LENGTH];
                GetRaceImage(raceHandle, raceImage, sizeof(raceImage), image);

                UpdateRace(raceIdent, short, raceName, required_level, tech_level,
                           raceParent, faction, type, raceDesc, raceImage);
            }
        }
    }
}

AddUpgrade(race, Handle:raceHandle, const String:short[], upgrade_category=0, required_level=-1, max_level=4,
           Float:energy=0.0, Float:recurring_energy=0.0, bool:accumulated=false, crystals=0, vespene=0,
           cost_crystals=-1, cost_vespene=-1, Float:cooldown=0.0, CooldownType:cooldown_type=Cooldown_None,
           bool:disabled=false, const String:name[]="", const String:desc[]="", const String:image[]="",
           const String:p1[]="", const String:p2[]="", const String:p3[]="", const String:p4[]="",
           const String:p5[]="", const String:p6[]="", const String:p7[]="", const String:p8[]="")
{
    #if defined _TRACE
        TraceInto("Race", "AddUpgrade", "race=%d, raceHandle=0x%08x, short=%s, upgrade_category=%d, required_level=%d, max_level=%d, energy=%f, recurring_energy=%f, accumulated=%d, crystals=%d, vespene=%d, cost_crystals=%d, cost_vespene=%d, cooldown=%f, cooldown_type=%d, disabled=%d, name=%s, desc=%s, image=%s, p1=%s, p2=%s, p3=%s, p4=%s, p5=%s, p6=%s, p7=%s, p8=%s", race, raceHandle, short, upgrade_category, required_level, max_level, energy, recurring_energy, accumulated, crystals, vespene, cost_crystals, cost_vespene, cooldown, cooldown_type, disabled, name, desc, image, p1, p2, p3, p4, p5, p6, p7, p8);
    #else
        #pragma unused race
    #endif

    if (cost_crystals < 0)
        cost_crystals = g_iUpgradeCrystalsCost;

    if (cost_vespene < 0)
        cost_vespene = g_iUpgradeVespeneCost;

    new raceLoaded;
    new Handle:raceConfig = GetRaceConfig(raceHandle, raceLoaded);
    if (raceConfig != INVALID_HANDLE)
    {
        new bool:upgradeFound;
        new raceMaxLevel = GetRaceMaxLevel(raceHandle);
        if (raceLoaded != CONFIG_NOT_LOADED)
        {
            KvRewind(raceConfig);
            upgradeFound = KvJumpToKey(raceConfig, short, false);
            if (upgradeFound)
            {
                required_level = KvGetNum(raceConfig,"required_level", required_level);
                energy = KvGetFloat(raceConfig,"energy", energy);
                recurring_energy = KvGetFloat(raceConfig,"recurring_energy", recurring_energy);
                crystals = KvGetNum(raceConfig,"crystals", crystals);
                vespene = KvGetNum(raceConfig,"vespene", vespene);
                cost_crystals = KvGetNum(raceConfig,"cost_crystals", crystals);
                cost_vespene = KvGetNum(raceConfig,"cost_vespene", vespene);
                cooldown = KvGetFloat(raceConfig,"cooldown", cooldown);
                KvGoBack(raceConfig);
            }
            else if (required_level < raceMaxLevel)
                SetRaceConfigIsLoaded(raceHandle,CONFIG_WAS_UPDATED);
        }
        else
            upgradeFound = false;

        if (!upgradeFound && required_level < raceMaxLevel)
        {
            KvRewind(raceConfig);
            if (KvJumpToKey(raceConfig, short, true))
            {
                if (required_level >= 0)
                    KvSetNum(raceConfig,"required_level", required_level);

                if (crystals > 0)
                    KvSetNum(raceConfig,"crystals", crystals);

                if (vespene > 0)
                    KvSetNum(raceConfig,"vespene", vespene);

                if (cost_crystals > 0)
                    KvSetNum(raceConfig,"cost_crystals", cost_crystals);

                if (cost_vespene > 0)
                    KvSetNum(raceConfig,"cost_vespene", cost_vespene);

                if (energy > 0.0)
                    KvSetFloat(raceConfig,"energy", energy);

                if (recurring_energy > 0.0)
                    KvSetFloat(raceConfig,"recurring_energy", recurring_energy);

                if (cooldown > 0.0 || cooldown_type != Cooldown_None)
                    KvSetFloat(raceConfig,"cooldown", cooldown);

                KvGoBack(raceConfig);
            }
            else
                LogError("Unable to create %s section for race %d", short, race);
        }
    }
    else
        LogError("Unable to create config keyvalues for race %d", race);

    if (required_level < 0)
        required_level = (upgrade_category >= 1) ? g_iMinUltimate : 1;

    new Handle:upgradeStringHandle;
    new upgrade = FindUpgrade(raceHandle, short);
    if (upgrade >= 0)
    {
        new Handle:upgradeListHandle=GetUpgradeListHandle(raceHandle);
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        SetArrayCell(upgradeHandle, UPGRADE_ENERGY,energy);
        SetArrayCell(upgradeHandle, UPGRADE_RECURRING_ENERGY,recurring_energy);
        SetArrayCell(upgradeHandle, UPGRADE_ACCUMULATED,accumulated);
        SetArrayCell(upgradeHandle, UPGRADE_CRYSTALS,crystals);
        SetArrayCell(upgradeHandle, UPGRADE_VESPENE,vespene);
        SetArrayCell(upgradeHandle, UPGRADE_COOLDOWN,cooldown);
        SetArrayCell(upgradeHandle, UPGRADE_COOLDOWN_TYPE,cooldown_type);
        SetArrayCell(upgradeHandle, UPGRADE_REQUIRED_LEVEL,required_level);
        SetArrayCell(upgradeHandle, UPGRADE_MAX_LEVEL,max_level);
        SetArrayCell(upgradeHandle, UPGRADE_COST_CRYSTALS,cost_crystals);
        SetArrayCell(upgradeHandle, UPGRADE_COST_VESPENE,cost_vespene);
        SetArrayCell(upgradeHandle, UPGRADE_CATEGORY,upgrade_category);
        SetArrayCell(upgradeHandle, UPGRADE_DISABLED,disabled);

        upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
        SetArrayString(upgradeStringHandle,UPGRADE_NAME,name);
        SetArrayString(upgradeStringHandle,UPGRADE_SHORT_NAME,short);
        SetArrayString(upgradeStringHandle,UPGRADE_DESC,desc);

        // Remove any leftover parameter strings.
        ResizeArray(upgradeStringHandle, UPGRADE_PARM);
    }
    else
    {
        upgradeStringHandle=CreateArray(ByteCountToCells(LONG_STRING_LENGTH));
        PushArrayString(upgradeStringHandle,name);
        PushArrayString(upgradeStringHandle,short);
        PushArrayString(upgradeStringHandle,desc);

        new Handle:upgradeHandle=CreateArray();
        PushArrayCell(upgradeHandle,upgradeStringHandle);
        PushArrayCell(upgradeHandle,energy);
        PushArrayCell(upgradeHandle,recurring_energy);
        PushArrayCell(upgradeHandle,accumulated);
        PushArrayCell(upgradeHandle,crystals);
        PushArrayCell(upgradeHandle,vespene);
        PushArrayCell(upgradeHandle,cooldown);
        PushArrayCell(upgradeHandle,cooldown_type);
        PushArrayCell(upgradeHandle,required_level);
        PushArrayCell(upgradeHandle,max_level);
        PushArrayCell(upgradeHandle,cost_crystals);
        PushArrayCell(upgradeHandle,cost_vespene);
        PushArrayCell(upgradeHandle,upgrade_category);
        PushArrayCell(upgradeHandle,disabled);

        new Handle:upgradeListHandle=GetUpgradeListHandle(raceHandle);
        upgrade = PushArrayCell(upgradeListHandle, upgradeHandle); // return index

        SetTraceCategory("Array");
        Trace("CreateArray raceUpgradeStringHandle[%d,%d]=0x%08x", race, upgrade, upgradeStringHandle);
        Trace("CreateArray raceUpgradeHandle[%d,%d]=0x%08x", race, upgrade, upgradeHandle);
    }

    // Push parameter strings for the description (if any).
    if (p1[0] != '\0')
    {
        PushArrayString(upgradeStringHandle,p1);
        Trace("Parameter1=%s", p1);
        if (p2[0] != '\0')
        {
            PushArrayString(upgradeStringHandle,p2);
            Trace("Parameter2=%s", p2);
            if (p3[0] != '\0')
            {
                PushArrayString(upgradeStringHandle,p3);
                Trace("Parameter3=%s", p3);
                if (p4[0] != '\0')
                {
                    PushArrayString(upgradeStringHandle,p4);
                    Trace("Parameter4=%s", p4);
                    if (p5[0] != '\0')
                    {
                        PushArrayString(upgradeStringHandle,p5);
                        Trace("Parameter5=%s", p5);
                        if (p6[0] != '\0')
                        {
                            PushArrayString(upgradeStringHandle,p6);
                            Trace("Parameter6=%s", p6);
                            if (p7[0] != '\0')
                            {
                                PushArrayString(upgradeStringHandle,p7);
                                Trace("Parameter7=%s", p7);
                                if (p8[0] != '\0')
                                {
                                    PushArrayString(upgradeStringHandle,p8);
                                    Trace("Parameter8=%s", p8);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // If this upgrade requires more energy than the race's limit,
    // change the race's energy limit.
    if (energy > 0.0)
    {
        new Float:limit = GetRaceEnergyLimit(raceHandle);
        if (limit >= 0.0 && energy > limit)
            SetRaceEnergyLimit(raceHandle, energy);

        // set the race's EnergyFlags
        new energy_flags = GetRaceEnergyFlags(raceHandle) | RACE_USES_ENERGY;

        if (accumulated)
            energy_flags |= RACE_USES_ACCUMULATED;

        SetRaceEnergyFlags(raceHandle, energy_flags);
    }

    if (GetRaceIsNew(raceHandle) || g_bCreate || g_bUpdate)
    {
        decl String:upgradeName[NAME_STRING_LENGTH];
        GetUpgradeName(raceHandle, upgrade, upgradeName, sizeof(upgradeName));

        decl String:upgradeDesc[DESCRIPTION_LENGTH];
        GetUpgradeDescription(raceHandle, upgrade, upgradeDesc, sizeof(upgradeDesc));

        decl String:upgradeImage[NAME_STRING_LENGTH];
        GetUpgradeImage(raceHandle, upgrade, upgradeImage, sizeof(upgradeImage), image);

        // Update database with upgrade description
        InsertUpgrade(GetRaceIdent(raceHandle), upgrade, upgrade_category,
                      short, upgradeName, upgradeDesc, upgradeImage,
                      cost_crystals, cost_vespene, required_level,
                      max_level, energy, accumulated,
                      recurring_energy, crystals,
                      vespene, cooldown);
    }

    #if defined _TRACE
        TraceReturn("race=%d, raceHandle=0x%08x, name=%s, upgrade=%d", race, raceHandle, name, upgrade);
    #endif

    return upgrade;
}

SetUpgradeCooldown(race, Handle:raceHandle, upgrade, Float:cooldown, CooldownType:cooldown_type)
{
    #if defined _TRACE
        TraceInto("Race", "SetUpgradeCooldown", "race=%d, raceHandle=0x%08x, cooldown=%f,cooldown_type=%d", \
                  race, raceHandle, cooldown, cooldown_type);
    #else
        #pragma unused race
    #endif

    new Handle:upgradeHandle=GetUpgradeHandle(raceHandle,upgrade);
    SetArrayCell(upgradeHandle, UPGRADE_COOLDOWN,cooldown);
    SetArrayCell(upgradeHandle, UPGRADE_COOLDOWN_TYPE,cooldown_type);

    #if defined _TRACE
        TraceReturn();
    #endif
}

Float:GetUpgradeCooldown(race, Handle:raceHandle, upgrade, &CooldownType:cooldown_type)
{
    #if defined _TRACE
        TraceInto("Race", "GetUpgradeCooldown", "race=%d, raceHandle=0x%08x", \
                  race, raceHandle);
    #else
        #pragma unused race
    #endif

    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);

    cooldown_type = CooldownType:GetArrayCell(upgradeHandle, UPGRADE_COOLDOWN_TYPE);
    new Float:cooldown = Float:GetArrayCell(upgradeHandle, UPGRADE_COOLDOWN);

    #if defined _TRACE
        TraceReturn("cooldown=%f,cooldown_type=%d", cooldown, cooldown_type);
    #endif

    return cooldown;
}

Faction:GetRaceFactionId(Handle:raceHandle)
{
    new Faction:factionId=GetRaceFaction(raceHandle);
    return (factionId < Generic) ? Generic : factionId;
}

GetRaceParentId(Handle:raceHandle)
{
    if (raceHandle != INVALID_HANDLE)
    {
        new parent = GetArrayCell(raceHandle,RACE_PARENT_ID);
        if (parent == 0)
        {
            decl String:name[NAME_STRING_LENGTH]; name[0] = '\0';
            GetRaceParentName(raceHandle, name, sizeof(name));
            parent = (name[0] != '\0') ? FindRace(name) : -1;
            SetArrayCell(raceHandle,RACE_PARENT_ID,parent);
        }
        return parent;
    }
    else
        return 0;

}

GetRaceName(Handle:raceHandle, String:name[], maxlength, lang=LANG_SERVER)
{
    GetRaceNameString(raceHandle,name,maxlength);
    if (name[0] == '%')
        Format(name,maxlength,"%T",name[1],lang);
    else
    {
        new Translation:translation = GetRaceTranslation(raceHandle);
        if (translation > Translation_Auto)
        {
            // Translate the short name to get the name
            decl String:short[NAME_STRING_LENGTH];
            GetRaceShortName(raceHandle, short, sizeof(short));

            if (translation == Translation_W3S)
            {
                // Use the War3Source key
                decl String:key[ITEM_STRING_LENGTH];
                Format(key,sizeof(key),"%s_RaceName",short);
                Format(name,maxlength,"%T",key,lang);
            }
            else
            {
                // Translate the short name to get the name
                Format(name,maxlength,"%T",short,lang);
            }
        }
    }
}

GetRaceDescription(Handle:raceHandle, String:desc[], maxlength,
                   const String:descString[]="", lang=LANG_SERVER,
                   bool:query=false)
{
    // Translate the short name to get the description
    decl String:short[SHORT_STRING_LENGTH];
    GetRaceShortName(raceHandle, short, sizeof(short));

    new Translation:translation = GetRaceTranslation(raceHandle);
    if (translation == Translation_SC)
    {
        decl String:key[ITEM_STRING_LENGTH];
        Format(key,sizeof(key),"%s_desc",short);
        Format(desc,maxlength,"%T",key,lang);
    }
    else
    {
        decl String:file[LONG_STRING_LENGTH];
        GetRaceTranslationFile(raceHandle, file, sizeof(file));
        if (file[0])
        {
            decl String:key[ITEM_STRING_LENGTH];
            Format(key,sizeof(key),"%s_Desc",short);
            if (file[0] && FileContains(file, key))
                Format(desc,maxlength,"%T",key,lang);
            else if (query)
                QueryRaceDescription(GetRaceIdent(raceHandle), desc, maxlength);
            else
                strcopy(desc,maxlength,descString);
        }
        else
            strcopy(desc,maxlength,descString);
    }
}

GetRaceImage(Handle:raceHandle, String:image[], maxlength,
             const String:imageString[]="", lang=LANG_SERVER,
             bool:query=false)
{
    // Translate the short name + _image to get the image 
    decl String:short[SHORT_STRING_LENGTH];
    GetRaceShortName(raceHandle, short, sizeof(short));

    new Translation:translation = GetRaceTranslation(raceHandle);
    if (translation == Translation_SC)
    {
        decl String:key[ITEM_STRING_LENGTH];
        Format(key,sizeof(key),"%s_image",short);
        Format(image,maxlength,"%T",key,lang);
    }
    else
    {
        decl String:file[LONG_STRING_LENGTH];
        GetRaceTranslationFile(raceHandle, file, sizeof(file));
        if (file[0])
        {
            decl String:key[ITEM_STRING_LENGTH];
            Format(key,sizeof(key),"%s_Image",short);
            if (FileContains(file, key))
                Format(image,maxlength,"%T",key,lang);
            else if (query)
                QueryRaceImage(GetRaceIdent(raceHandle), image, maxlength);
            else
                strcopy(image,maxlength,imageString);
        }
        else
            strcopy(image,maxlength,imageString);
    }
}

GetRaceSwitchMessage(Handle:raceHandle, String:message[], maxlength, lang)
{
    GetRaceSwitchString(raceHandle, message, maxlength);
    if (message[0] == '%')
        Format(message,maxlength,"%T",message[1],lang);
    else
    {
        // Translate the short name to get the switch message
        decl String:short[SHORT_STRING_LENGTH];
        GetRaceShortName(raceHandle, short, sizeof(short));

        new Translation:translation = GetRaceTranslation(raceHandle);
        if (translation == Translation_SC)
        {
            decl String:key[ITEM_STRING_LENGTH];
            Format(key,sizeof(key),"%s_switch",short);
            Format(message,maxlength,"%T",key,lang);
        }
        else
        {
            decl String:file[LONG_STRING_LENGTH];
            GetRaceTranslationFile(raceHandle, file, sizeof(file));
            if (file[0])
            {
                decl String:key[ITEM_STRING_LENGTH];
                Format(key,sizeof(key),"%s_Switch",short);
                if (FileContains(file, key))
                    Format(message,maxlength,"%T",key,lang);
            }
        }
    }

    if (message[0] == '\0')
    {
        decl String:raceName[NAME_STRING_LENGTH];
        GetRaceName(raceHandle, raceName, sizeof(raceName));
        Format(message, maxlength, "%T", "RaceChanged", lang, raceName);
    }
}

GetRaceSwitchMessageDead(Handle:raceHandle, String:message[], maxlength, lang)
{
    GetRaceSwitchStringDead(raceHandle, message, maxlength);
    if (message[0] == '%')
        Format(message,maxlength,"%T",message[1],lang);
    else
    {
        // Translate the short name to get the pending message
        decl String:short[SHORT_STRING_LENGTH];
        GetRaceShortName(raceHandle, short, sizeof(short));

        new Translation:translation = GetRaceTranslation(raceHandle);
        if (translation == Translation_SC)
        {
            decl String:key[ITEM_STRING_LENGTH];
            Format(key,sizeof(key),"%s_pending",short);
            Format(message,maxlength,"%T",key,lang);
        }
        else
        {
            decl String:file[LONG_STRING_LENGTH];
            GetRaceTranslationFile(raceHandle, file, sizeof(file));
            if (file[0])
            {
                decl String:key[ITEM_STRING_LENGTH];
                Format(key,sizeof(key),"%s_Pending",short);
                if (FileContains(file, key))
                    Format(message,maxlength,"%T",key,lang);
            }
        }
    }

    if (message[0] == '\0')
    {
        decl String:raceName[NAME_STRING_LENGTH];
        GetRaceName(raceHandle, raceName, sizeof(raceName));
        Format(message, maxlength, "%T", "PendingRaceChange", lang, raceName);
    }
}

GetUpgradeName(Handle:raceHandle, upgrade, String:name[], maxlength, lang=LANG_SERVER)
{
    GetUpgradeNameString(raceHandle,upgrade,name,maxlength);
    if (name[0] == '%')
        Format(name,maxlength,"%T",name[1],lang);
    else
    {
        new Translation:translation = GetRaceTranslation(raceHandle);
        if (translation > Translation_Auto)
        {
            decl String:race[NAME_STRING_LENGTH];
            GetRaceShortName(raceHandle, race,sizeof(race));

            decl String:short[NAME_STRING_LENGTH];
            GetUpgradeShortName(raceHandle,upgrade,short,sizeof(short));

            decl String:key[ITEM_STRING_LENGTH];
            if (translation == Translation_W3S)
            {
                // Use the War3Source key
                Format(key,sizeof(key),"%s_skill_%s",race,short);
            }
            else
            {
                // Translate the race_name + short name to get the name
                Format(key,sizeof(key),"%s_%s",race,short);
            }

            // Translate the key to get the name
            Format(name,maxlength,"%T",key,lang);
        }
    }
}

GetUpgradeImage(Handle:raceHandle, upgrade, String:image[], maxlength,
                const String:imageString[]="", lang=LANG_SERVER,
                bool:query=false)
{
    TraceInto("Race", "GetUpgradeImage", "raceHandle=0x%08x", raceHandle);

    if (imageString[0] == '%')
        Format(image,maxlength,"%T",imageString[1],lang);
    else
    {
        new Translation:translation = GetRaceTranslation(raceHandle);
        if (translation > Translation_Auto)
        {
            decl String:file[LONG_STRING_LENGTH];
            GetRaceTranslationFile(raceHandle, file, sizeof(file));
            if (file[0])
            {
                decl String:race[NAME_STRING_LENGTH];
                GetRaceShortName(raceHandle, race,sizeof(race));

                decl String:short[NAME_STRING_LENGTH];
                GetUpgradeShortName(raceHandle,upgrade,short,sizeof(short));

                decl String:key[ITEM_STRING_LENGTH];
                if (translation == Translation_W3S)
                {
                    // Use the War3Source key
                    Format(key,sizeof(key),"%s_skill_%s_image",race,short);
                }
                else
                {
                    // Translate the race_name + short name + _image to get the image
                    Format(key,sizeof(key),"%s_%s_image",race,short);
                }

                if (FileContains(file, key))
                    Format(image,maxlength,"%T",key,lang);

            }
            else if (!image[0])
            {
                if (imageString[0])
                    strcopy(image,maxlength,imageString);
                else if (query)
                    QueryUpgradeImage(GetRaceIdent(raceHandle), upgrade, image, maxlength);
            }
        }
        else
            strcopy(image,maxlength,imageString);
    }

    TraceReturn("image=%s", image);
}

GetUpgradeDescription(Handle:raceHandle, upgrade, String:desc[], maxlength, lang=LANG_SERVER)
{
    TraceInto("Race", "GetUpgradeDescription", "raceHandle=0x%08x", raceHandle);

    GetUpgradeDescriptionString(raceHandle,upgrade,desc,maxlength);
    if (desc[0] == '%')
    {
        Trace("Translate %s", desc[1]);
        Format(desc,maxlength,"%T",desc[1],lang);
    }
    else
    {
        new Translation:translation = GetRaceTranslation(raceHandle);
        if (translation > Translation_Auto)
        {
            decl String:race[NAME_STRING_LENGTH];
            GetRaceShortName(raceHandle, race,sizeof(race));

            decl String:short[NAME_STRING_LENGTH];
            GetUpgradeShortName(raceHandle,upgrade,short,sizeof(short));

            decl String:key[ITEM_STRING_LENGTH];
            if (translation == Translation_W3S)
            {
                // Use the War3Source key
                Format(key,sizeof(key),"%s_skill_%s_desc",race,short);
            }
            else
            {
                // Translate the race_name + short name + _desc to get the description
                Format(key,sizeof(key),"%s_%s_desc",race,short);
            }

            FormatUpgradeDescription(raceHandle, upgrade, translation,
                                     key, desc, maxlength, lang);
        }
    }

    TraceReturn("desc=%s", desc);
}

GetUpgradeNameAndDesc(Handle:raceHandle, upgrade, String:name[], maxName,
                      String:desc[], maxDesc, lang=LANG_SERVER)
{
    TraceInto("Race", "GetUpgradeNameAndDesc", "raceHandle=0x%08x, upgrade=%d", raceHandle, upgrade);

    new Handle:upgradeStringHandle=GetUpgradeStringHandle(raceHandle,upgrade);
    GetArrayString(upgradeStringHandle, UPGRADE_NAME, name, maxName);
    GetArrayString(upgradeStringHandle, UPGRADE_DESC, desc, maxDesc);

    new Translation:translation = GetRaceTranslation(raceHandle);
    if (translation > Translation_Auto)
    {
        decl String:race[NAME_STRING_LENGTH];
        GetRaceShortName(raceHandle, race,sizeof(race));

        decl String:short[NAME_STRING_LENGTH];
        GetUpgradeShortName(raceHandle,upgrade,short,sizeof(short));

        decl String:key[ITEM_STRING_LENGTH];
        if (translation == Translation_W3S)
        {
            // Use the War3Source key
            Format(key,sizeof(key),"%s_skill_%s",race,short);
        }
        else
        {
            // Translate the race_name + short name to get the name
            Format(key,sizeof(key),"%s_%s",race,short);
        }

        if (name[0] != '%')
            Format(name,maxName,"%T",key,lang);

        if (desc[0] != '%')
        {
            StrCat(key,sizeof(key),"_desc");
            FormatUpgradeDescription(raceHandle, upgrade, translation,
                                     key, desc, maxDesc, lang);
        }
    }

    if (name[0] == '%')
        Format(name,maxName,"%T",name[1],lang);

    if (desc[0] == '%')
        Format(desc,maxDesc,"%T",desc[1],lang);

    TraceReturn("name=%s, desc=%s", name, desc);
}

FormatUpgradeDescription(Handle:raceHandle, upgrade, Translation:translation,
                         const String:key[], String:desc[], maxlength, lang=LANG_SERVER)
{
    TraceInto("Race", "FormatUpgradeDescription", "raceHandle=0x%08x, key=%s", raceHandle, key);

    if (translation == Translation_W3S)
    {
        Trace("Translate W3S key %s", key);
        Format(desc,maxlength,"%T",key,lang);

        new Handle:upgradeListHandle=GetUpgradeListHandle(raceHandle);
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
        new numParms = GetArraySize(upgradeStringHandle) - UPGRADE_PARM;
        if (numParms > 0)
        {
            Trace("replace %d parms", numParms);
            decl String:pkey[ITEM_STRING_LENGTH];
            new String:parm[NAME_STRING_LENGTH];
            for (new i=0; i < numParms; i++)
            {
                Format(pkey,sizeof(pkey),"#%d#",i+1);
                GetUpgradeParameter(raceHandle,upgrade,i,parm,sizeof(parm));
                Trace("replace parm%d key %s=%s", i, pkey, parm);
                ReplaceString(desc,maxlength,pkey,parm);
            }
        }

        //Change any references to +ability to +ultimate
        ReplaceString(desc, maxlength, "+ability2", "+ultimate4", false);
        ReplaceString(desc, maxlength, "ability2",  "+ultimate4", false);
        ReplaceString(desc, maxlength, "+ability1", "+ultimate3", false);
        ReplaceString(desc, maxlength, "ability1",  "+ultimate3", false);
        ReplaceString(desc, maxlength, "+ability0", "+ultimate2", false);
        ReplaceString(desc, maxlength, "+ability",  "+ultimate2", false);
        ReplaceString(desc, maxlength, "(ability)", "(+ultimate2)", false);
        //ReplaceString(desc, maxlength, "ability", "+ultimate2", false);
    }
    else
    {
        new Handle:upgradeListHandle=GetUpgradeListHandle(raceHandle);
        new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
        new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
        new numParms = GetArraySize(upgradeStringHandle) - UPGRADE_PARM;
        if (numParms > 0)
        {
            decl String:parm[8][NAME_STRING_LENGTH];
            for (new i=0 ; i < numParms; i++)
            {
                GetUpgradeParameter(raceHandle,upgrade,i,parm[i],sizeof(parm[]));
            }

            if (numParms == 1)
            {
                Trace("Translate key %s(%s)", key, parm[0]);
                Format(desc,maxlength,"%T",key, lang, parm[0]);
            }
            else if (numParms == 2)
            {
                Trace("Translate key %s(%s,%s)", key, parm[0], parm[1]);
                Format(desc,maxlength,"%T",key, lang, parm[0], parm[1]);
            }
            else if (numParms == 3)
            {
                Trace("Translate key %s(%s,%s,%s)", key, parm[0], \
                      parm[1], parm[2]);

                Format(desc,maxlength,"%T",key, lang, parm[0], parm[1],
                       parm[2]);
            }
            else if (numParms == 4)
            {
                Trace("Translate key %s(%s,%s,%s,%s)", key, parm[0], \
                      parm[1], parm[2], parm[3]);

                Format(desc,maxlength,"%T",key, lang, parm[0], parm[1],
                       parm[2], parm[3]);
            }
            else if (numParms == 5)
            {
                Trace("Translate key %s(%s,%s,%s,%s,%s)", key, parm[0], \
                      parm[1], parm[2], parm[3], parm[4]);

                Format(desc,maxlength,"%T",key, lang, parm[0], parm[1],
                       parm[2], parm[3], parm[4]);
            }
            else if (numParms == 6)
            {
                Trace("Translate key %s(%s,%s,%s,%s,%s,%s)", key, parm[0], \
                      parm[1], parm[2], parm[3], parm[4], parm[5]);

                Format(desc,maxlength,"%T",key, lang, parm[0], parm[1],
                       parm[2], parm[3], parm[4], parm[5]);
            }
            else if (numParms == 7)
            {
                Trace("Translate key %s(%s,%s,%s,%s,%s,%s,%s)", \
                      key, parm[0], parm[1], parm[2], parm[3], \
                      parm[4], parm[5], parm[6]);

                Format(desc,maxlength,"%T",key, lang, parm[0], parm[1],
                       parm[2], parm[3], parm[4], parm[5], parm[6]);
            }
            else if (numParms == 8)
            {
                Trace("Translate key %s(%s,%s,%s,%s,%s,%s,%s,%s)", \
                      key, parm[0], parm[1], parm[2], parm[3], parm[4], \
                      parm[5], parm[6], parm[7]);

                Format(desc,maxlength,"%T",key, lang, parm[0], parm[1],
                       parm[2], parm[3], parm[4], parm[5], parm[6],
                       parm[7]);
            }
        }
        else
        {
            Trace("Translate key %s", key);
            Format(desc,maxlength,"%T",key,lang);
        }
    }
    TraceReturn("desc=%s", desc);
}

GetUpgradeCount(Handle:raceHandle)
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
        return GetArraySize(upgradeListHandle);
    else
        return 0;
}

FindUpgrade(Handle:raceHandle, const String:short[])
{
    new Handle:upgradeListHandle=GetArrayCell(raceHandle,RACE_UPGRADES);
    if (upgradeListHandle != INVALID_HANDLE)
    {
        decl String:curName[NAME_STRING_LENGTH];
        new size = GetArraySize(upgradeListHandle);
        for(new upgrade=0;upgrade<size;upgrade++)
        {
            new Handle:upgradeHandle=GetArrayCell(upgradeListHandle,upgrade);
            if (upgradeHandle != INVALID_HANDLE)
            {
                new Handle:upgradeStringHandle=GetArrayCell(upgradeHandle,UPGRADE_STRINGS);
                if (upgradeStringHandle != INVALID_HANDLE)
                {
                    GetArrayString(upgradeStringHandle,UPGRADE_SHORT_NAME, curName, sizeof(curName));
                    if (StrEqual(short,curName,false))
                        return upgrade;
                }
            }
        }
    }
    return -1;
}

FindRace(const String:name[])
{
    decl String:curName[NAME_STRING_LENGTH];
    new size = GetRaceCount();
    for(new race=1;race<size;race++)
    {
        GetRaceShortName(GetRaceHandle(race),curName,sizeof(curName));
        if (StrEqual(name,curName,false))
            return race;
    }
    return -1;
}

FindRaceForIdent(ident)
{
    new size = GetRaceCount();
    for(new race=1;race<size;race++)
    {
        //if (GetRaceIdent(GetRaceHandle(race)) == ident)
        new Handle:raceHandle=GetRaceHandle(race);
        if (GetArrayCell(raceHandle,RACE_IDENT) == ident)
            return race;
    }
    return -1;
}

PendingCheck(client)
{
    if (GetPendingUpgradeReset(client))
    {
        SetPendingUpgradeReset(client,false);
        ResetUpgradesNow(client,-1);
    }

    new pendingRace = GetPendingRace(client);
    if (pendingRace > 0)
    {
        decl String:buf[LONG_STRING_LENGTH];
        SetPendingRace(client,-1);
        SetRace(client,pendingRace);
        new Handle:raceHandle=GetRaceHandle(pendingRace);
        GetRaceSwitchMessage(raceHandle, buf, sizeof(buf), client);
        CPrintToChat(client,"{green}[SC]{default} %s", buf);
    }
    return pendingRace;
}

ChangeRace(client, race, Handle:raceHandle, bool:forceNow, bool:check)
{
    TraceInto("Race", "ChangeRace", "Change %d:%N's race to %1, raceHandle=0x%08x, forceNow=%d,check=%d", \
              client, ValidClientIndex(client), race, raceHandle, forceNow, check);

    if (check)
    {
        new reqLevel = GetRaceRequiredLevel(raceHandle);
        new techLevel = GetRaceTechLevel(raceHandle);
        if (techLevel < 0 || reqLevel < 0)
        {
            // If forceNow is on and the reqLevel < 0 then
            //     Change to the parent race instead.
            if (forceNow)
            {
                decl String:parent[NAME_STRING_LENGTH];
                new Handle:oldHandle = raceHandle;
                new oldRace = race;
                parent[0] = '\0';

                do
                {
                    GetRaceParentName(raceHandle, parent, sizeof(parent));
                    if (parent[0] == '\0')
                        break;
                    else
                    {
                        race = FindRace(parent);
                        if (race <= 0)
                            break;
                        else
                        {
                            raceHandle = GetRaceHandle(race);
                            reqLevel = GetRaceRequiredLevel(raceHandle);
                            techLevel = GetRaceTechLevel(raceHandle);
                        }
                    }
                }
                while (techLevel < 0 || reqLevel < 0);

                if (techLevel < 0 || reqLevel < 0)
                {
                    raceHandle = oldHandle;
                    race = oldRace;
                }
            }

            if (techLevel < 0 || reqLevel < 0)
            {
                decl String:name[NAME_STRING_LENGTH];
                GetRaceName(raceHandle, name, sizeof(name));
                CPrintToChat(client,"{green}[SC]{default} %t", "IsNotAvailable", name);
                return;
            }
        }

        new level = GetOverallLevel(client);
        if (level < reqLevel)
        {
            decl String:name[NAME_STRING_LENGTH];
            GetRaceName(raceHandle, name, sizeof(name));
            CPrintToChat(client,"{green}[SC]{default} %t", "InsufficientLevels", reqLevel, name);
            return;
        }

        if (techLevel > 0)
        {
            new Faction:techId = GetRaceFaction(raceHandle, false);
            if (techId > Generic)
            {
                new tlvl = GetTechLevel(client, techId);
                if (tlvl < techLevel)
                {
                    decl String:tech[NAME_STRING_LENGTH];
                    GetFactionName(techId, tech, sizeof(tech));

                    decl String:name[NAME_STRING_LENGTH];
                    GetRaceName(raceHandle, name, sizeof(name));
                    CPrintToChat(client,"{green}[SC]{default} %t", "InsufficientTechLevels",
                                techLevel, tech, name, tlvl);
                    return;
                }
            }
        }
    }

    // If the race is invalid, default race to human for new players.
    if (race <= 0)
        race = FindRace("human");

    if (!forceNow && !g_FirstSpawn[client] && IsPlayerAlive(client))
    {
        if (g_bSaveXP && GetPlayerStatus(client) != PlayerDisabled &&
            GetRaceLoaded(client,race) < DataOK)
        {
            if (g_bDatabaseConnected)
            {
                new oldrace = GetRace(client);
                if (oldrace > 0 && !GetDatabaseSaved(client) &&
                    GetDatabaseLoaded(client) >= DataOK &&
                    GetRaceLoaded(client, oldrace) >= DataOK)
                {
                    Trace("Save %d:%N's race=%d Data", \
                          client,ValidClientIndex(client), \
                          race);

                    SavePlayerData(client);
                }

                Trace("Load %d:%N's race=%d Data", \
                      client, ValidClientIndex(client), \
                      race);

                LoadPlayerRaceData(client, race);
            }
            else
            {
                LogError("Database not available to load %N's levels!", client);
                PrintHintText(client, "%t", "NoDatabaseForLoad");
            }
        }

        decl String:buf[LONG_STRING_LENGTH];
        GetRaceSwitchMessageDead(raceHandle, buf, sizeof(buf), client);
        CPrintToChat(client, "{green}[SC]{default} %s", buf);
        SetPendingRace(client,race);
    }
    else
    {
        decl String:buf[LONG_STRING_LENGTH];
        GetRaceSwitchMessage(raceHandle, buf, sizeof(buf), client);
        CPrintToChat(client, "{green}[SC]{default} %s", buf);
        g_FirstSpawn[client]=false;
        SetPendingRace(client,-1);
        SetRace(client,race);
    }
    TraceReturn();
}

ResetUpgrades(client)
{
    if (IsPlayerAlive(client) &&
        GetRaceRequiredLevel(GetRaceHandle(GetRace(client))) >= 0)
    {
        SetPendingUpgradeReset(client,true);
        CPrintToChat(client, "{green}[SC]{default} %t", "UpgradesPendingReset");
    }
    else
        ResetUpgradesNow(client,-1);
}

ResetUpgradesNow(client,race)
{
    if (GetDatabaseLoaded(client) == DataLoading)
    {
        CPrintToChat(client, "{green}[SC]{default} %t", "StillLoadingUnableToReset");
    }
    else
    {
        if (race < 0)
            race = GetRace(client);

        SetActiveUltimate(client,race,1,-1);
        SetActiveUltimate(client,race,2,-1);
        SetActiveUltimate(client,race,3,-1);

        // DON'T reset the saved flag for resets!
        //SetDatabaseSaved(client, false);

        new upgradeCount=GetUpgradeCount(GetRaceHandle(race));
        for (new upgrade=0;upgrade<upgradeCount;upgrade++)
        {
            SetUpgradeLevel(client,race,upgrade,0);
            SetSavedUpgradeLevel(client,race,upgrade,-1);
        }

        CPrintToChat(client,"{green}[SC]{default} %t", "UpgradesReset");

        if (GetLevel(client,race) > 0)
            UpgradeMenu(client, UpgradeMode, true);
    }
}

bool:FileContains(const String:fileName[], const String:string[])
{
    new bool:found = false;
    new Handle:file = OpenFile(fileName, "r");
    if (file != INVALID_HANDLE)
    {
        decl String:buffer[DESCRIPTION_LENGTH];
        while (!IsEndOfFile(file))
        {
            if (ReadFileLine(file, buffer, sizeof(buffer)))
            {
                if (StrContains(buffer, string) >= 0)
                {
                    found = true;
                    break;
                }
            }
        }
        CloseHandle(file);
    }
    return found;
}
