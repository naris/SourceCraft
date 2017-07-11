#if !defined SOURCECRAFT // Not Implemented Yet!
native War3_SetRaceConfigString(raceID, String:key[], String:value[]);
native War3_SetRaceConfigFloat(raceID, String:key[], Float:value);
native War3_SetRaceConfigInt(raceID, String:key[], value);
native War3_SetRaceConfigBool(raceID, String:key[], bool:value);
native War3_SetRaceConfigArray(raceID, String:key[], any:value[], maxlen, KvDataTypes:type = KvData_Float);
// Note! Allows you to define arrays that use strings for keys!
native War3_SetRaceConfigArrayValue(raceID, String:array[], String:key[], String:value[]);
native War3_SetRaceGlobalConfigString(String:key[], String:value[]);
#endif

#if !defined SOURCECRAFT
native Float:War3_GetRaceConfigFloat(raceID, String:key[]);
native War3_GetRaceConfigInt(raceID, String:key[]);
native bool:War3_GetRaceConfigBool(raceID, String:key[]);
native War3_GetRaceConfigArray(raceID, String:key[], any:array[], maxlen, KvDataTypes:type = KvData_Float);
#else
#define War3_GetRaceConfigFloat(%1,%2) GetConfigFloat(%2,.fileId=%1)
#define War3_GetRaceConfigInt(%1,%2) GetConfigNum(%2,.fileId=%1)
#define War3_GetRaceConfigBool(%1,%2) (bool:GetConfigNum(%2,.fileId=%1))
stock War3_GetRaceConfigArray(race, const String:key[], any:array[], maxlen, KvDataTypes:type = KvData_Float)
{
    if (type == KvData_Float)
        return GetConfigFloatArray(key[], array[], maxlen, .fileId=race);
    else
        return GetConfigArray(key[], array[], maxlen, .fileId=race);
}
#endif

#if !defined SOURCECRAFT // Not Implemented Yet!
// Note! Allows you to define arrays that use strings for keys!
native War3_GetRaceConfigArrayValue(raceID, String:array[], String:key[], String:value[]);
#endif

#if !defined SOURCECRAFT
native War3_GetRaceConfigString(raceID, String:key[], String:value[]);
#else
#define War3_GetRaceConfigString(%1,%2,%3) GetConfigString(%2,%3,.fileId=%1)
#endif

#if !defined SOURCECRAFT // Not Implemented Yet!
native War3_GotoRaceConfigArray(raceID, String:array[]);
native bool:War3_GetRaceConfigArrayNextValue(String:value[]);
#endif

#if !defined SOURCECRAFT // Not Implemented Yet!
native War3_SetItemConfigString(ItemID, String:key[], String:value[]);
native War3_SetItemConfigFloat(ItemID, String:key[], Float:value);
native War3_SetItemConfigInt(ItemID, String:key[], value);
native War3_SetItemConfigBool(ItemID, String:key[], bool:value);
native War3_SetItemConfigArray(ItemID, String:key[], any:array[], maxlen, KvDataTypes:type = KvData_Float);
// Note! Allows you to define arrays that use strings for keys!
native War3_SetItemConfigArrayValue(ItemID, String:array[], String:key[], String:value[]);
native War3_SetItemGlobalConfigString(String:key[], String:value[]);
#endif

#if !defined SOURCECRAFT
native Float:War3_GetItemConfigFloat(ItemID, String:key[]);
native War3_GetItemConfigInt(ItemID, String:key[]);
native bool:War3_GetItemConfigBool(ItemID, String:key[]);
native War3_GetItemConfigArray(ItemID, String:key[], any:value[], maxlen, KvDataTypes:type = KvData_Float);
#else
#define War3_GetItemConfigFloat(%1,%2) GetConfigFloat(%2,.fileId=SHOPITEM,.node=%1)
#define War3_GetItemConfigInt(%1,%2) GetConfigNum(%2,.fileId=SHOPITEM,.node=%1)
#define War3_GetItemConfigBool(%1,%2) (bool:GetConfigNum(%2,.fileId=SHOPITEM,.node=%1))
stock War3_GetItemConfigArray(ItemID, const String:key[], any:array[], maxlen, KvDataTypes:type = KvData_Float)
{
    if (type == KvData_Float)
        return GetConfigFloatArray(key[], array[], maxlen, .fileId=SHOPITEM, .node=ItemID);
    else
        return GetConfigArray(key[], array[], maxlen, .fileId=SHOPITEM,. node=ItemID);
}
#endif

#if !defined SOURCECRAFT // Not Implemented Yet!
// Note! Allows you to define arrays that use strings for keys!
native War3_GetItemConfigArrayValue(ItemID, String:array[], String:key[], String:value[]);
#endif

#if !defined SOURCECRAFT
native War3_GetItemConfigString(ItemID, String:key[], String:value[]);
#else
#define War3_GetItemConfigString(%1,%2,%3) GetConfigString(%2,%3,.fileId=SHOPITEM,.node=%1)
#endif

#if !defined SOURCECRAFT // Not Implemented Yet!
native War3_GotoItemConfigArray(raceID, String:array[]);
native bool:War3_GetItemConfigArrayNextValue(String:value[]);
#endif
