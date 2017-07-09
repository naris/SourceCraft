/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: playerinfo.inc
 * Description: Holds all the storage for players, temporary and long term.
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _player_info_included
 #endinput
#endif
#define _player_info_included

enum ClientInfo
{
    Immunity:ClientInfo_Immunities = 0,
    Restriction:ClientInfo_Restrictions,
    Attribute:ClientInfo_Attributes,
    ClientInfo_Race,
    Float:ClientInfo_Energy,
    Float:ClientInfo_EnergyRate,
    Float:ClientInfo_EnergyLimit,
    Float:ClientInfo_InitialEnergy,
    ClientInfo_EnergyFlags,
    ClientInfo_Crystals,
    ClientInfo_Vespene,
    ClientInfo_PCrystals,
    ClientInfo_PendingRace,
    ClientInfo_PendingUpgradeReset,
    ClientInfo_OverallLevel,
    ClientInfo_DatabaseIdent,
    DataStatus:ClientInfo_DatabaseLoaded,
    bool:ClientInfo_DatabaseSaved,
    Float:ClientInfo_DatabaseSaveTime,
    PlayerStatus:ClientInfo_PlayerStatus,
    Handle:ClientInfo_Properties,
    Handle:ClientInfo_ShopItems,
    Handle:ClientInfo_RaceData,
    Handle:ClientInfo_TechData
};

enum RaceInfo
{
    RaceInfo_XP = 0,
    RaceInfo_Level,
    Float:RaceInfo_AccumulatedEnergy,
    RaceInfo_ActiveUltimate1,
    RaceInfo_ActiveUltimate2,
    RaceInfo_ActiveUltimate3,
    RaceInfo_ActiveUltimate4,
    DataStatus:RaceInfo_DatabaseLoaded,
    RaceInfo_SavedXP
};

#define RACEINFO_ACTIVE_ULTIMATE_1  _:RaceInfo_ActiveUltimate1
#define RACEINFO_ACTIVE_ULTIMATE_2  _:RaceInfo_ActiveUltimate2
#define RACEINFO_ACTIVE_ULTIMATE_3  _:RaceInfo_ActiveUltimate3
#define RACEINFO_ACTIVE_ULTIMATE_4  _:RaceInfo_ActiveUltimate4
#define RACEINFO_SIZE               _:RaceInfo

#define MAX_ULTIMATE_CATEGORY   4


enum UpgradeInfo
{
    UpgradeInfo_Level = 0,
    UpgradeInfo_SavedLevel,
};

#define UPGRADEINFO_SAVED_LEVEL _:UpgradeInfo_SavedLevel
#define UPGRADEINFO_SIZE        _:UpgradeInfo


enum TechInfo
{
    TechInfo_Count = 0,
    TechInfo_Level,
    DataStatus:TechInfo_DatabaseLoaded
};

#define TECHINFO_SIZE   _:TechInfo


enum PropInfo
{
    Handle:PropInfo_PluginHandle = 0,
    PropInfo_Identifier,
    Float:PropInfo_OverrideSpeed,
    Float:PropInfo_OverrideGravity,
    PropInfo_OverrideVisibility,
    Float:PropInfo_Speed,
    Float:PropInfo_Gravity,
    PropInfo_Visibility,
    VisibilityType:PropInfo_VisibilityType,
    Float:PropInfo_VisibilityFactor1,
    Float:PropInfo_VisibilityFactor2,
    RenderMode:PropInfo_VisibilityMode,
    RenderFx:PropInfo_Visibility_FX,
    PropInfo_Visibility_R,
    PropInfo_Visibility_G,
    PropInfo_Visibility_B,
    PropInfo_Weapon_VisAlpha,
    bool:PropInfo_VisibilityWeapons,
    VisibilityPriority:PropInfo_VisibilityPriority,
    Float:PropInfo_VisibilityTime,
    Immunity:PropInfo_Immunities,
    Restriction:PropInfo_Restrictions,
    MoveType:PropInfo_MoveType,
    RegenFlags:PropInfo_RegenHealthFlags,
    RegenFlags:PropInfo_RegenShieldFlags,
    Float:PropInfo_RegenHealth,
    Float:PropInfo_RegenShield,
    Float:PropInfo_PhysicalArmor,
    Float:PropInfo_MagicalArmor
};

enum DataStatus
{
    DataNotLoaded = 0,
    DataLoading,
    DataOK,
    DataNotFound,
    DataLoaded,
    DataSaved
}

enum PlayerStatus
{
    PlayerStatus_Unknown = 0,
    PlayerDisabled,
    PlayerActive
}

new playerArray[MAXPLAYERS+1][ClientInfo];
new String:playerPrevName[MAXPLAYERS+1][NAME_STRING_LENGTH];
new String:playerName[MAXPLAYERS+1][NAME_STRING_LENGTH];
new String:playerID[MAXPLAYERS+1][CLASS_STRING_LENGTH];

new Display:g_ClientDisplayBits[MAXPLAYERS+1];
new Settings:g_ClientSettingsBits[MAXPLAYERS+1];

new bool:m_IsChangingClass[MAXPLAYERS+1];

new m_Armor[MAXPLAYERS+1];
new m_MaxShields[MAXPLAYERS+1];
new Float:m_ArmorPercent[MAXPLAYERS+1][2];
new ArmorFlags:m_ArmorFlags[MAXPLAYERS+1];
new String:m_ArmorName[MAXPLAYERS+1][NAME_STRING_LENGTH];

// Accessor Macros for IsChangingClass
#define IsChangingClass(%1)                     m_IsChangingClass[%1]
#define SetChangingClass(%1,%2)                 m_IsChangingClass[%1] = %2

// Accessor Macros for Client DisplayBits

#define GetDisplayBits(%1)                     g_ClientDisplayBits[%1]
#define SetDisplayBits(%1,%2)                  g_ClientDisplayBits[%1] = %2
#define LoadDisplayBits(%1,%2)                 g_ClientDisplayBits[%1] = %2

#define GetDisplaySetting(%1,%2)               IsSet(g_ClientDisplayBits[%1],%2)

// Accessor Macros for Client SettingsBits

#define GetSettingsBits(%1)                     g_ClientSettingsBits[%1]
#define SetSettingsBits(%1,%2)                  g_ClientSettingsBits[%1] = %2
#define LoadSettingsBits(%1,%2)                 g_ClientSettingsBits[%1] = %2 & ~(Debug_Condition|Debug_Speed|Debug_Meters|Debug_Other)

#define GetSetting(%1,%2)                       IsSet(g_ClientSettingsBits[%1],%2)

// Accessor Macros for Armor

#define GetArmor(%1)                            m_Armor[%1]
#define SetArmor(%1,%2)                         m_Armor[%1] = %2

#define IncrementArmor(%1,%2)                   m_Armor[%1] += %2
#define DecrementArmor(%1,%2)                   m_Armor[%1] -= %2

#define GetArmorFlags(%1)                       m_ArmorFlags[%1]
#define SetArmorFlags(%1,%2)                    m_ArmorFlags[%1] = %2
#define HasShields(%1)                          IsSet(m_ArmorFlags[%1], Armor_IsShield)

#define GetMaxShields(%1)                       m_MaxShields[%1]
#define SetMaxShields(%1,%2)                    m_MaxShields[%1] = %2

#define GetArmorPercent(%1,%2)                  m_ArmorPercent[%1][%2]
#define SetArmorPercent(%1,%2,%3)               m_ArmorPercent[%1][%2] = %3

// Accessor Macros for playerArray

#define GetDatabaseIdent(%1)                    playerArray[%1][ClientInfo_DatabaseIdent]
#define SetDatabaseIdent(%1,%2)                 playerArray[%1][ClientInfo_DatabaseIdent] = %2

#define GetDatabaseLoaded(%1)                   playerArray[%1][ClientInfo_DatabaseLoaded]
#define SetDatabaseLoaded(%1,%2)                playerArray[%1][ClientInfo_DatabaseLoaded] = %2

#define GetDatabaseSaved(%1)                    playerArray[%1][ClientInfo_DatabaseSaved]
#define SetDatabaseSaved(%1,%2)                 playerArray[%1][ClientInfo_DatabaseSaved] = %2

#define GetDatabaseSaveTime(%1)                 playerArray[%1][ClientInfo_DatabaseSaveTime]
#define SetDatabaseSaveTime(%1,%2)              playerArray[%1][ClientInfo_DatabaseSaveTime] = %2

#define GetPlayerStatus(%1)                     playerArray[%1][ClientInfo_PlayerStatus]
#define SetPlayerStatus(%1,%2)                  playerArray[%1][ClientInfo_PlayerStatus] = %2

#define GetRace(%1)                             playerArray[%1][ClientInfo_Race]
#define SetRaceValue(%1,%2)                     playerArray[%1][ClientInfo_Race] = %2

#define GetPendingRace(%1)                      playerArray[%1][ClientInfo_PendingRace]
#define SetPendingRace(%1,%2)                   playerArray[%1][ClientInfo_PendingRace] = %2

#define GetPendingUpgradeReset(%1)              playerArray[%1][ClientInfo_PendingUpgradeReset]
#define SetPendingUpgradeReset(%1,%2)           playerArray[%1][ClientInfo_PendingUpgradeReset] = %2

#define GetEnergy(%1)                           playerArray[%1][ClientInfo_Energy]
#define SetEnergy(%1,%2)                        playerArray[%1][ClientInfo_Energy] = %2

#define IncrementEnergy(%1,%2)                  playerArray[%1][ClientInfo_Energy] += %2
#define DecrementEnergy(%1,%2)                  playerArray[%1][ClientInfo_Energy] -= %2

#define GetEnergyRate(%1)                       playerArray[%1][ClientInfo_EnergyRate]
#define SetEnergyRate(%1,%2)                    playerArray[%1][ClientInfo_EnergyRate] = %2

#define GetEnergyLimit(%1)                      playerArray[%1][ClientInfo_EnergyLimit]
#define SetEnergyLimit(%1,%2)                   playerArray[%1][ClientInfo_EnergyLimit] = %2

#define GetInitialEnergy(%1)                    playerArray[%1][ClientInfo_InitialEnergy]
#define SetInitialEnergy(%1,%2)                 playerArray[%1][ClientInfo_InitialEnergy] = %2

#define GetEnergyFlags(%1)                      playerArray[%1][ClientInfo_EnergyFlags]
#define SetEnergyFlags(%1,%2)                   playerArray[%1][ClientInfo_EnergyFlags] = %2

#define GetCrystals(%1)                         playerArray[%1][ClientInfo_Crystals]
#define SetCrystalsValue(%1,%2)                 playerArray[%1][ClientInfo_Crystals] = %2

#define IncrementCrystalsValue(%1,%2)           playerArray[%1][ClientInfo_Crystals] += %2
#define DecrementCrystalsValue(%1,%2)           playerArray[%1][ClientInfo_Crystals] -= %2

#define GetVespene(%1)                          playerArray[%1][ClientInfo_Vespene]
#define SetVespeneValue(%1,%2)                  playerArray[%1][ClientInfo_Vespene] = %2

#define IncrementVespeneValue(%1,%2)            playerArray[%1][ClientInfo_Vespene] += %2
#define DecrementVespeneValue(%1,%2)            playerArray[%1][ClientInfo_Vespene] -= %2

#define GetPCrystals(%1)                          playerArray[%1][ClientInfo_PCrystals]
#define SetPCrystals(%1,%2)                       playerArray[%1][ClientInfo_PCrystals] = %2

#define IncrementPCrystals(%1,%2)                 playerArray[%1][ClientInfo_PCrystals] += %2
#define DecrementPCrystals(%1,%2)                 playerArray[%1][ClientInfo_PCrystals] -= %2

#define GetOverallLevel(%1)                     playerArray[%1][ClientInfo_OverallLevel]
#define SetOverallLevelValue(%1,%2)             playerArray[%1][ClientInfo_OverallLevel] = %2

#define GetImmunityBits(%1)                     playerArray[%1][ClientInfo_Immunities]
#define SetImmunityBits(%1,%2)                  playerArray[%1][ClientInfo_Immunities] = %2

#define GetImmunity(%1,%2)                      IsSet(playerArray[%1][ClientInfo_Immunities], %2)

#define GetRestrictionBits(%1)                  playerArray[%1][ClientInfo_Restrictions]
#define SetRestrictionBits(%1,%2)               playerArray[%1][ClientInfo_Restrictions] = %2

#define GetRestriction(%1,%2)                   IsSet(playerArray[%1][ClientInfo_Restrictions], %2)

#define GetAttributeBits(%1)                    playerArray[%1][ClientInfo_Attributes]
#define SetAttributeBits(%1,%2)                 playerArray[%1][ClientInfo_Attributes] = %2

#define GetAttribute(%1,%2)                     IsSet(playerArray[%1][ClientInfo_Attributes], %2)

#define GetPropData(%1)                         playerArray[%1][ClientInfo_Properties]
#define SetPropData(%1,%2)                      playerArray[%1][ClientInfo_Properties] = %2

#define GetShopitems(%1)                        playerArray[%1][ClientInfo_ShopItems]
#define SetShopitems(%1,%2)                     playerArray[%1][ClientInfo_ShopItems] = %2

#define GetRaceData(%1)                         playerArray[%1][ClientInfo_RaceData]
#define SetRaceData(%1,%2)                      playerArray[%1][ClientInfo_RaceData] = %2

#define GetTechData(%1)                         playerArray[%1][ClientInfo_TechData]
#define SetTechData(%1,%2)                      playerArray[%1][ClientInfo_TechData] = %2

// Accessor Macros for raceInfo

#define GetRaceInfoXP(%1)                       GetArrayCell(%1,_:RaceInfo_XP)
#define SetRaceInfoXP(%1,%2)                    SetArrayCell(%1,_:RaceInfo_XP,%2)

#define GetRaceInfoLevel(%1)                    GetArrayCell(%1,_:RaceInfo_Level)
#define SetRaceInfoLevel(%1,%2)                 SetArrayCell(%1,_:RaceInfo_Level,%2)

#define GetRaceInfoAccumulatedEnergy(%1)        Float:GetArrayCell(%1,_:RaceInfo_AccumulatedEnergy)
#define SetRaceInfoAccumulatedEnergy(%1,%2)     SetArrayCell(%1,_:RaceInfo_AccumulatedEnergy,%2)

#define GetRaceInfoActiveUltimate1(%1)          GetArrayCell(%1,_:RaceInfo_ActiveUltimate1)
#define SetRaceInfoActiveUltimate1(%1,%2)       SetArrayCell(%1,_:RaceInfo_ActiveUltimate1,%2)

#define GetRaceInfoActiveUltimate2(%1)          GetArrayCell(%1,_:RaceInfo_ActiveUltimate2)
#define SetRaceInfoActiveUltimate2(%1,%2)       SetArrayCell(%1,_:RaceInfo_ActiveUltimate2,%2)

#define GetRaceInfoActiveUltimate3(%1)          GetArrayCell(%1,_:RaceInfo_ActiveUltimate3)
#define SetRaceInfoActiveUltimate3(%1,%2)       SetArrayCell(%1,_:RaceInfo_ActiveUltimate3,%2)

#define GetRaceInfoActiveUltimate4(%1)          GetArrayCell(%1,_:RaceInfo_ActiveUltimate4)
#define SetRaceInfoActiveUltimate4(%1,%2)       SetArrayCell(%1,_:RaceInfo_ActiveUltimate4,%2)

#define GetRaceInfoLoaded(%1)                   GetArrayCell(%1,_:RaceInfo_DatabaseLoaded)
#define SetRaceInfoLoaded(%1,%2)                SetArrayCell(%1,_:RaceInfo_DatabaseLoaded,%2)

#define GetRaceInfoSavedXP(%1)                  GetArrayCell(%1,_:RaceInfo_SavedXP)
#define SetRaceInfoSavedXP(%1,%2)               SetArrayCell(%1,_:RaceInfo_SavedXP,%2)

#define GetRaceInfoUpgradePos(%1)               (RACEINFO_SIZE+(%1*UPGRADEINFO_SIZE))

#define GetRaceInfoUpgradeLevel(%1,%2)          GetArrayCell(%1,GetRaceInfoUpgradePos(%2))
#define SetRaceInfoUpgradeLevel(%1,%2,%3)       SetArrayCell(%1,GetRaceInfoUpgradePos(%2),%3)

#define GetRaceInfoSavedUpgradeLevel(%1,%2)     GetArrayCell(%1,GetRaceInfoUpgradePos(%2)+UPGRADEINFO_SAVED_LEVEL)
#define SetRaceInfoSavedUpgradeLevel(%1,%2,%3)  SetArrayCell(%1,GetRaceInfoUpgradePos(%2)+UPGRADEINFO_SAVED_LEVEL,%3)

// Accessor Macros for techInfo

#define GetTechInfoCount(%1)                    GetArrayCell(%1,_:TechInfo_Count)
#define SetTechInfoCount(%1,%2)                 SetArrayCell(%1,_:TechInfo_Count,%2)

#define GetTechInfoLevel(%1)                    GetArrayCell(%1,_:TechInfo_Level)
#define SetTechInfoLevel(%1,%2)                 SetArrayCell(%1,_:TechInfo_Level,%2)

#define GetTechInfoLoaded(%1)                   GetArrayCell(%1,_:TechInfo_DatabaseLoaded)
#define SetTechInfoLoaded(%1,%2)                SetArrayCell(%1,_:TechInfo_DatabaseLoaded,%2)


// Accessor Macros for propInfo

#define GetPropInfoPlugin(%1)                   GetArrayCell(%1,_:PropInfo_PluginHandle)
#define SetPropInfoPlugin(%1,%2)                SetArrayCell(%1,_:PropInfo_PluginHandle,%2)

#define GetPropInfoId(%1)                       GetArrayCell(%1,_:PropInfo_Identifier)
#define SetPropInfoId(%1,%2)                    SetArrayCell(%1,_:PropInfo_Identifier,%2)

#define GetPropInfoOverrideSpeed(%1)            GetArrayCell(%1,_:PropInfo_OverrideSpeed)
#define SetPropInfoOverrideSpeed(%1,%2)         SetArrayCell(%1,_:PropInfo_OverrideSpeed,%2)

#define GetPropInfoOverrideGravity(%1)          GetArrayCell(%1,_:PropInfo_OverrideGravity)
#define SetPropInfoOverrideGravity(%1,%2)       SetArrayCell(%1,_:PropInfo_OverrideGravity,%2)

#define GetPropInfoOverrideVisibility(%1)       GetArrayCell(%1,_:PropInfo_OverrideVisibility)
#define SetPropInfoOverrideVisibility(%1,%2)    SetArrayCell(%1,_:PropInfo_OverrideVisibility,%2)

#define GetPropInfoSpeed(%1)                    GetArrayCell(%1,_:PropInfo_Speed)
#define SetPropInfoSpeed(%1,%2)                 SetArrayCell(%1,_:PropInfo_Speed,%2)

#define GetPropInfoGravity(%1)                  GetArrayCell(%1,_:PropInfo_Gravity)
#define SetPropInfoGravity(%1,%2)               SetArrayCell(%1,_:PropInfo_Gravity,%2)

#define GetPropInfoVisibility(%1)               GetArrayCell(%1,_:PropInfo_Visibility)
#define SetPropInfoVisibility(%1,%2)            SetArrayCell(%1,_:PropInfo_Visibility,%2)

#define GetPropInfoVisibilityType(%1)           GetArrayCell(%1,_:PropInfo_VisibilityType)
#define SetPropInfoVisibilityType(%1,%2)        SetArrayCell(%1,_:PropInfo_VisibilityType,%2)

#define GetPropInfoVisibilityFactor1(%1)        GetArrayCell(%1,_:PropInfo_VisibilityFactor1)
#define SetPropInfoVisibilityFactor1(%1,%2)     SetArrayCell(%1,_:PropInfo_VisibilityFactor1,%2)

#define GetPropInfoVisibilityFactor2(%1)        GetArrayCell(%1,_:PropInfo_VisibilityFactor2)
#define SetPropInfoVisibilityFactor2(%1,%2)     SetArrayCell(%1,_:PropInfo_VisibilityFactor2,%2)

#define GetPropInfoVisibilityMode(%1)           GetArrayCell(%1,_:PropInfo_VisibilityMode)
#define SetPropInfoVisibilityMode(%1,%2)        SetArrayCell(%1,_:PropInfo_VisibilityMode,%2)

#define GetPropInfoVisibilityFx(%1)             GetArrayCell(%1,_:PropInfo_Visibility_FX)
#define SetPropInfoVisibilityFx(%1,%2)          SetArrayCell(%1,_:PropInfo_Visibility_FX,%2)

#define GetPropInfoVisibilityR(%1)              GetArrayCell(%1,_:PropInfo_Visibility_R)
#define SetPropInfoVisibilityR(%1,%2)           SetArrayCell(%1,_:PropInfo_Visibility_R,%2)

#define GetPropInfoVisibilityG(%1)              GetArrayCell(%1,_:PropInfo_Visibility_G)
#define SetPropInfoVisibilityG(%1,%2)           SetArrayCell(%1,_:PropInfo_Visibility_G,%2)

#define GetPropInfoVisibilityB(%1)              GetArrayCell(%1,_:PropInfo_Visibility_B)
#define SetPropInfoVisibilityB(%1,%2)           SetArrayCell(%1,_:PropInfo_Visibility_B,%2)

#define GetPropInfoVisibilityWeaponAlpha(%1)    GetArrayCell(%1,_:PropInfo_Weapon_VisAlpha)
#define SetPropInfoVisibilityWeaponAlpha(%1,%2) SetArrayCell(%1,_:PropInfo_Weapon_VisAlpha,%2)

#define GetPropInfoVisibilityWeapons(%1)        GetArrayCell(%1,_:PropInfo_VisibilityWeapons)
#define SetPropInfoVisibilityWeapons(%1,%2)     SetArrayCell(%1,_:PropInfo_VisibilityWeapons,%2)

#define GetPropInfoVisibilityPriority(%1)       GetArrayCell(%1,_:PropInfo_VisibilityPriority)
#define SetPropInfoVisibilityPriority(%1,%2)    SetArrayCell(%1,_:PropInfo_VisibilityPriority,%2)

#define GetPropInfoVisibilityTime(%1)           GetArrayCell(%1,_:PropInfo_VisibilityTime)
#define SetPropInfoVisibilityTime(%1,%2)        SetArrayCell(%1,_:PropInfo_VisibilityTime,%2)

#define GetPropInfoImmunities(%1)               GetArrayCell(%1,_:PropInfo_Immunities)
#define SetPropInfoImmunities(%1,%2)            SetArrayCell(%1,_:PropInfo_Immunities,%2)

#define GetPropInfoRestrictions(%1)             GetArrayCell(%1,_:PropInfo_Restrictions)
#define SetPropInfoRestrictions(%1,%2)          SetArrayCell(%1,_:PropInfo_Restrictions,%2)

#define GetPropInfoMoveType(%1)                 GetArrayCell(%1,_:PropInfo_MoveType)
#define SetPropInfoMoveType(%1,%2)              SetArrayCell(%1,_:PropInfo_MoveType,%2)

#define GetPropInfoRegenHealthFlags(%1)         GetArrayCell(%1,_:PropInfo_RegenHealthFlags)
#define SetPropInfoRegenHealthFlags(%1,%2)      SetArrayCell(%1,_:PropInfo_RegenHealthFlags,%2)

#define GetPropInfoRegenShieldFlags(%1)         GetArrayCell(%1,_:PropInfo_RegenShieldFlags)
#define SetPropInfoRegenShieldFlags(%1,%2)      SetArrayCell(%1,_:PropInfo_RegenShieldFlags,%2)

#define GetPropInfoRegenHealth(%1)              GetArrayCell(%1,_:PropInfo_RegenHealth)
#define SetPropInfoRegenHealth(%1,%2)           SetArrayCell(%1,_:PropInfo_RegenHealth,%2)

#define GetPropInfoRegenShield(%1)              GetArrayCell(%1,_:PropInfo_RegenShield)
#define SetPropInfoRegenShield(%1,%2)           SetArrayCell(%1,_:PropInfo_RegenShield,%2)

#define GetPropInfoPhysicalArmor(%1)            GetArrayCell(%1,_:PropInfo_PhysicalArmor)
#define SetPropInfoPhysicalArmor(%1,%2)         SetArrayCell(%1,_:PropInfo_PhysicalArmor,%2)

#define GetPropInfoMagicalArmor(%1)             GetArrayCell(%1,_:PropInfo_MagicalArmor)
#define SetPropInfoMagicalArmor(%1,%2)          SetArrayCell(%1,_:PropInfo_MagicalArmor,%2)


// Accessor Functions for raceInfo

#if defined _TRACE
    #define GetRaceInfo(%1,%2)                  GetRaceInfoHandle(%1,%2)
#else
    #define GetRaceInfo(%1,%2)                  GetArrayCell(GetRaceData(%1),%2)
#endif

stock Handle:GetRaceInfoHandle(client,race)
{
    TraceInto("PlayerInfo", "GetRaceInfo", "client=%d:%N, race=%d", \
              client, ValidClientIndex(client), race);

    new Handle:raceInfo = INVALID_HANDLE;
    if (race >= 0) // && GetRaceCount() > 1)
    {
        new Handle:raceData = GetRaceData(client);
        if (raceData != INVALID_HANDLE)
            raceInfo=GetArrayCell(raceData,race);
        else
        {
            //decl String:rname[64]; GetRaceName(GetRaceHandle(race),rname,sizeof(rname));
            //LogError("ERROR: Player %d:%N's race %s(%d) data is missing!",
            //         client, ValidClientIndex(client), rname, race);
            LogError("ERROR: Player %d:%N's race %d data is missing!",
                     client, ValidClientIndex(client), race);
        }
    }

    TraceReturn("raceInfo=0x%08x", raceInfo);
    return raceInfo;
}


// Accessor Functions for techInfo

#if defined _TRACE
    #define GetTechInfo(%1,%2)                  GetTechInfoHandle(%1,%2)
#else
    #define GetTechInfo(%1,%2)                  GetArrayCell(GetTechData(%1),_:%2)
#endif

stock Handle:GetTechInfoHandle(client,Faction:techId)
{
    TraceInto("PlayerInfo", "GetTechInfo", "client=%d:%N, techId=%d", \
              client, ValidClientIndex(client), techId);

    new Handle:techInfo = INVALID_HANDLE;
    if (techId >= Generic)
    {
        new Handle:techData = GetTechData(client);
        if (techData != INVALID_HANDLE)
        techInfo = GetArrayCell(techData,_:techId);
    }

    TraceReturn("techInfo=0x%08x", techInfo);
    return techInfo;
}



// Accessor Functions for playerArray

stock SetCrystals(client,crystals)
{
    SetCrystalsValue(client, crystals);
    SetDatabaseSaved(client, false);
}

stock IncrementCrystals(client,crystals)
{
    IncrementCrystalsValue(client, crystals);
    SetDatabaseSaved(client, false);
}

stock DecrementCrystals(client,crystals)
{
    DecrementCrystalsValue(client, crystals);
    SetDatabaseSaved(client, false);
}

stock SetVespene(client,vespene)
{
    SetVespeneValue(client, vespene);
    SetDatabaseSaved(client, false);
}

stock IncrementVespene(client,vespene)
{
    IncrementVespeneValue(client, vespene);
    SetDatabaseSaved(client, false);
}

stock DecrementVespene(client,vespene)
{
    DecrementVespeneValue(client, vespene);
    SetDatabaseSaved(client, false);
}

stock SetOverallLevel(client,level)
{
    SetOverallLevelValue(client, level);
    SetDatabaseSaved(client, false);
}

stock SetImmunity(client,Immunity:imm,bool:imm_state)
{
    new Immunity:immunities = GetImmunityBits(client);

    if (imm_state)
        immunities |= imm;
    else
        immunities &= ~imm;

    SetTraceCategory("Immunity");
    TraceInto("PlayerInfo", "SetImmunity", "Set %d:%N's 0x%08x immunity to %1, immunities=0x%08x", \
              client, ValidClientIndex(client), imm, imm_state, immunities);

    SetImmunityBits(client, immunities);

    TraceReturn();
}

stock SetRestriction(client,Restriction:restrict,bool:restrict_state)
{
    new Restriction:restrictions = GetRestrictionBits(client);

    if (restrict_state)
        restrictions |= restrict;
    else
        restrictions &= ~restrict;

    SetTraceCategory("Restriction");
    TraceInto("PlayerInfo", "SetRestriction", "Set %d:%N's 0x%08x restriction to %1, restrictions=0x%08x", \
              client, ValidClientIndex(client), restrict, restrict_state, restrictions);

    SetRestrictionBits(client, restrictions);

    TraceReturn();
}

stock SetAttribute(client,Attribute:attrib,bool:attrib_state)
{
    new Attribute:attributes = GetAttributeBits(client);

    if (attrib_state)
        attributes |= attrib;
    else
        attributes &= ~attrib;

    SetTraceCategory("Attribute");
    TraceInto("PlayerInfo", "SetAttribute", "Set %d:%N's 0x%08x attribute to %1, attributes=0x%08x", \
              client, ValidClientIndex(client), attrib, attrib_state, attributes);

    SetAttributeBits(client, attributes);

    TraceReturn();
}

// Accessor methods for game client properties

#define GameHasMoney()  (GameTypeIsCS() || GameType == tf2)

stock GetMoney(client)
{
    if (GameType == tf2)
        return GetEntProp(client, Prop_Send, "m_nCurrency");
    else if (GameTypeIsCS())
        return GetEntProp(client, Prop_Send, "m_iAccount");
    else
        return -1;
}

stock SetMoney(client, amount)
{
    if (GameType == tf2)
        SetEntProp(client, Prop_Send, "m_nCurrency", amount);
    else if (GameTypeIsCS())
        SetEntProp(client, Prop_Send, "m_iAccount", amount);
}
