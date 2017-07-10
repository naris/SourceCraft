#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <admin>

#define PL_VERSION      "0.6.3"
#define CVAR_DISABLED   "OFF"
#define CVAR_ENABLED    "ON"

// Uncomment for debug.
//#define DEBUG           1

#include "advertisements/triggers.sp"

public Plugin:myinfo = {
    name        = "Advertisements",
    author      = "Tsunami, Otstrel.ru Team",
    description = "Display advertisements",
    version     = PL_VERSION,
    url         = "http://www.tsunami-productions.nl, http://otstrel.ru"
};

new g_iTickrate;
new Handle:g_hAdvertisements  = INVALID_HANDLE;
new Handle:g_hCenterAd[MAXPLAYERS + 1];
new Handle:g_hEnabled;
new Handle:g_hFile;
new Handle:g_hInterval;
new Handle:g_hTimer;

new Handle:g_hCvarDateFormat;
new Handle:g_hCvarTimeFormat;
new Handle:g_hCvarTime24Format;
new Handle:g_hCvarShowExitButton;

new bool:g_bAdmins;
new bool:g_bFlags;
new AdminFlag:g_fFlagList[AdminFlags_TOTAL];


static g_iSColors[9]             = {    1,              3,              3,          4,          4,          5,              5,		6,		6          };
static String:g_sSColors[9][13]  = {    "{DEFAULT}",    "{LIGHTGREEN}", "{TEAM}",   "{GREEN}",  "{RED}",    "{DARKGREEN}",  "{OLIVE}",	"{YELLOW}",	"{BLACK}"  };
static g_iTColors[13][3]         = {    {255, 255, 255},    {255,   0,   0},    {  0, 255,   0},    {  0,   0, 255}, 
                                        {255, 255,   0},    {255,   0, 255},    {  0, 255, 255},    {255, 128,   0}, 
                                        {255,   0, 128},    {128, 255,   0},    {  0, 255, 128},    {128,   0, 255}, 
                                        {  0, 128, 255} };
static String:g_sTColors[13][12] = {    "{WHITE}",          "{RED}",            "{GREEN}",          "{BLUE}",    
                                        "{YELLOW}",         "{PURPLE}",         "{CYAN}",           "{ORANGE}",    
                                        "{PINK}",           "{OLIVE}",          "{LIME}",           "{VIOLET}",    
                                        "{LIGHTBLUE}"   };

new g_iShowCountMax = 0;                                        

public OnPluginStart() {
    g_iTickrate     = GetTickInterval() ? RoundFloat(1/GetTickInterval()) : 0;
    #if defined DEBUG
        LogError("[DEBUG] Tickrate is %i", g_iTickrate);
    #endif

    CreateConVar("sm_advertisements_version", PL_VERSION, 
        "Display advertisements", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hEnabled              = CreateConVar("sm_advertisements_enabled",         "1",                  
        "Enable/disable displaying advertisements.");
    g_hFile                 = CreateConVar("sm_advertisements_file",            "advertisements.txt", 
        "File to read the advertisements from.");
    g_hInterval             = CreateConVar("sm_advertisements_interval",        "30",                 
        "Amount of seconds between advertisements.");
    g_hCvarDateFormat       = CreateConVar("sm_advertisements_dateformat",      "%m/%d/%Y", 
        "Date format for {DATE} placeholder.");
    g_hCvarTimeFormat       = CreateConVar("sm_advertisements_timeformat",      "%I:%M:%S%p", 
        "Time format for {TIME} placeholder.");
    g_hCvarTime24Format     = CreateConVar("sm_advertisements_time24format",    "%H:%M:%S", 
        "Time format for {TIME24} placeholder.");
    g_hCvarShowExitButton   = CreateConVar("sm_advertisements_showexitbutton",  "0",
        "Show exit button in menus.");
    
    HookConVarChange(g_hInterval, ConVarChange_Interval);
    RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");
    
    initTriggers();
}

public OnMapStart() {
    ParseAds();
    
    g_hTimer        = CreateTimer(GetConVarFloat(g_hInterval), Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    
    g_TotalRounds = 0;  
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if (g_hTimer != INVALID_HANDLE) {
        KillTimer(g_hTimer);
    }
    
    g_hTimer        = CreateTimer(GetConVarFloat(g_hInterval), Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public Action:Command_ReloadAds(args) {
    ParseAds();
}

public Action:Timer_DisplayAds(Handle:timer) {
    if (GetConVarBool(g_hEnabled)) {
        new Float:fMin;
        new iCurrent = -1;
        new Float:fNextShow;
        new iShowCount;
        
        KvRewind(g_hAdvertisements);
        for ( new bool:result = KvGotoFirstSubKey(g_hAdvertisements), i = 0; result ; result = KvGotoNextKey(g_hAdvertisements), i++ ) {
            // trying to find what ad to show
            fNextShow       = KvGetFloat(g_hAdvertisements, "nextshow");
            
            if ( iCurrent < 0 || fNextShow < fMin ) {
                fMin = fNextShow;
                iCurrent = i;
            }
        }
        
        if ( iCurrent < 0 )
        {
            // Not found
            return;
        }
        // Found iCurrent
        
        KvRewind(g_hAdvertisements);
        for ( new bool:result = KvGotoFirstSubKey(g_hAdvertisements), i = 0; result && i < iCurrent; result = KvGotoNextKey(g_hAdvertisements), i++ ) {
            // skip to iCurrent
        }
            
        iShowCount      = KvGetNum(g_hAdvertisements, "showcount");
        fNextShow       = KvGetFloat(g_hAdvertisements, "nextshow");
        fNextShow       += g_iShowCountMax*1.0/iShowCount;
        KvSetFloat(g_hAdvertisements, "nextshow", fNextShow);

        #if defined DEBUG
            LogError("[DEBUG] Found ad: iCurrent = %i, iShowCount = %i, fNextShow = %f, fMin = %f", iCurrent, iShowCount, fNextShow, fMin);
        #endif
                        
        decl String:sBuffer[256], String:sBuffer2[256], String:sFlags[16], 
            String:sText[256], String:sTextTmp[256], String:sType[6];
        
        KvGetString(g_hAdvertisements, "type",  sType,  sizeof(sType));
        KvGetString(g_hAdvertisements, "text",  sText,  sizeof(sText));
        KvGetString(g_hAdvertisements, "flags", sFlags, sizeof(sFlags), "none");
                
        g_bAdmins = StrEqual(sFlags, "");
        g_bFlags = !StrEqual(sFlags, "none");
        if (g_bFlags) {
            FlagBitsToArray(ReadFlagString(sFlags), g_fFlagList, sizeof(g_fFlagList));
        }
        
        if (StrContains(sText, "{CURRENTMAP}") != -1) {
            GetCurrentMap(sBuffer, sizeof(sBuffer));
            ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
        }
        
        if (StrContains(sText, "{DATE}")       != -1) {
            GetConVarString(g_hCvarDateFormat, sBuffer2, sizeof(sBuffer2));
            FormatTime(sBuffer, sizeof(sBuffer), sBuffer2);
            ReplaceString(sText, sizeof(sText), "{DATE}",       sBuffer);
        }
        
        if (StrContains(sText, "{TICKRATE}")   != -1) {
            IntToString(g_iTickrate, sBuffer, sizeof(sBuffer));
            ReplaceString(sText, sizeof(sText), "{TICKRATE}",   sBuffer);
        }
        
        if (StrContains(sText, "{TIME}")       != -1) {
            GetConVarString(g_hCvarTimeFormat, sBuffer2, sizeof(sBuffer2));
            FormatTime(sBuffer, sizeof(sBuffer), sBuffer2);
            ReplaceString(sText, sizeof(sText), "{TIME}",       sBuffer);
        }
        
        if (StrContains(sText, "{TIME24}")     != -1) {
            GetConVarString(g_hCvarTime24Format, sBuffer2, sizeof(sBuffer2));
            FormatTime(sBuffer, sizeof(sBuffer), sBuffer2);
            ReplaceString(sText, sizeof(sText), "{TIME24}",     sBuffer);
        }
        
        if (StrContains(sText, "{TIMELEFT}")   != -1) {
            Triggers_GetTimeLeft(sBuffer, sizeof(sBuffer));
            ReplaceString(sText, sizeof(sText), "{TIMELEFT}",   sBuffer);
        }        

        if (StrContains(sText, "{NEXTMAP}")    != -1) {
            Triggers_GetNextMap(sBuffer, sizeof(sBuffer));
            ReplaceString(sText, sizeof(sText), "{NEXTMAP}",    sBuffer);
        }        

        if (StrContains(sText, "\\n")          != -1) {
            ReplaceString(sText, sizeof(sText), "\\n", "\n");
        }
        
        new iStart = StrContains(sText, "{BOOL:");
        while (iStart != -1) {
            new iEnd = StrContains(sText[iStart + 6], "}");
            
            if (iEnd != -1) {
                decl String:sConVar[64], String:sName[64];
                
                strcopy(sConVar, iEnd + 1, sText[iStart + 6]);
                Format(sName, sizeof(sName), "{BOOL:%s}", sConVar);
                
                new Handle:hConVar = FindConVar(sConVar);
                if (hConVar != INVALID_HANDLE) {
                    ReplaceString(sText, sizeof(sText), sName, GetConVarBool(hConVar) ? CVAR_ENABLED : CVAR_DISABLED);
                }
            }
            
            new iStart2 = StrContains(sText[iStart + 1], "{BOOL:") + iStart + 1;
            if (iStart == iStart2) {
                break;
            } else {
                iStart = iStart2;
            }
        }
        
        iStart = StrContains(sText, "{");
        while (iStart != -1) {
            new iEnd = StrContains(sText[iStart + 1], "}");
            
            if (iEnd != -1) {
                decl String:sConVar[64], String:sName[64];
                
                strcopy(sConVar, iEnd + 1, sText[iStart + 1]);
                Format(sName, sizeof(sName), "{%s}", sConVar);
                
                new Handle:hConVar = FindConVar(sConVar);
                if (hConVar != INVALID_HANDLE) {
                    GetConVarString(hConVar, sBuffer, sizeof(sBuffer));
                    ReplaceString(sText, sizeof(sText), sName, sBuffer);
                }
            }
            
            new iStart2 = StrContains(sText[iStart + 1], "{") + iStart + 1;
            if (iStart == iStart2) {
                break;
            } else {
                iStart = iStart2;
            }
        }
        
        if (StrContains(sType, "S") != -1) {
            sTextTmp = sText;
            new iTeamColors = StrContains(sTextTmp, "{TEAM}"), String:sColor[4];
            
            for (new c = 0; c < sizeof(g_iSColors); c++) {
                if ( StrContains(sTextTmp, g_sSColors[c]) != -1 ) {
                    Format(sColor, sizeof(sColor), "%c", g_iSColors[c]);
                    ReplaceString(sTextTmp, sizeof(sTextTmp), g_sSColors[c], sColor);
                }
            }
            
            Format(sTextTmp, sizeof(sTextTmp), "\x01%s", sTextTmp);
            if (iTeamColors == -1) {
                for (new i = 1; i <= MaxClients; i++) {
                if ( CanShowToClient(i) ) {
                        #if defined DEBUG
                            LogError("[DEBUG] PrintToChat(%i): %s", i, sTextTmp);
                        #endif
                        PrintToChat(i, sTextTmp);
                    }
                }
            } else {
                for (new i = 1; i <= MaxClients; i++) {
                if ( CanShowToClient(i) ) {
                        #if defined DEBUG
                            LogError("[DEBUG] SayText2(%i): %s", i, sTextTmp);
                        #endif
                        SayText2(i, sTextTmp);
                    }
                }
            }
        }
        if (StrContains(sType, "T") != -1) {
            sTextTmp = sText;
            decl String:sColor[16];
            new iColor = -1, iPos = BreakString(sTextTmp, sColor, sizeof(sColor));
            
            for (new i = 0; i < sizeof(g_sTColors); i++) {
                if (StrEqual(sColor, g_sTColors[i])) {
                    iColor = i;
                }
            }
            
            if (iColor == -1) {
                iPos     = 0;
                iColor   = 0;
            }
            
            new Handle:hKv = CreateKeyValues("Stuff", "title", sTextTmp[iPos]);
            KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255);
            KvSetNum(hKv,   "level", 1);
            KvSetNum(hKv,   "time",  10);
            
            for (new i = 1; i <= MaxClients; i++) {
                if ( CanShowToClient(i) ) {
                    #if defined DEBUG
                        LogError("[DEBUG] CreateDialog(%i): %s", i, sTextTmp[iPos]);
                    #endif
                    CreateDialog(i, hKv, DialogType_Msg);
                }
            }
            
            CloseHandle(hKv);
        }

        // Remove colors from advertisement, because
        // C,H,M methods do not support colors.
        for (new c = 0; c < sizeof(g_iSColors); c++) {
            if ( StrContains(sText, g_sSColors[c]) != -1 ) {
                #if defined DEBUG
                    LogError("[DEBUG] Found: [%s] in [%s]. Removing", g_sSColors[c], sText);
                #endif
                ReplaceString(sText, sizeof(sText), g_sSColors[c], "");
                #if defined DEBUG
                    LogError("[DEBUG] Removed. Result: [%s].", sText);
                #endif
            }
        }
        for (new c = 0; c < sizeof(g_iTColors); c++) {
            if ( StrContains(sText, g_sTColors[c]) != -1 ) {
                #if defined DEBUG
                    LogError("[DEBUG] Found: [%s] in [%s]. Removing", g_sTColors[c], sText);
                #endif
                ReplaceString(sText, sizeof(sText), g_sTColors[c], "");
                #if defined DEBUG
                    LogError("[DEBUG] Removed. Result: [%s].", sText);
                #endif
            }
        }

        if (StrContains(sType, "C") != -1) {
            for (new i = 1; i <= MaxClients; i++) {
                if ( CanShowToClient(i) ) {
                    #if defined DEBUG
                        LogError("[DEBUG] PrintCenterText(%i): %s", i, sText);
                    #endif
                    PrintCenterText(i, sText);
                    
                    new Handle:hCenterAd;
                    g_hCenterAd[i] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                    WritePackCell(hCenterAd,   i);
                    WritePackString(hCenterAd, sText);
                }
            }
        }
        if (StrContains(sType, "H") != -1) {
            for (new i = 1; i <= MaxClients; i++) {
                if ( CanShowToClient(i) ) {
                    #if defined DEBUG
                        LogError("[DEBUG] PrintHintText(%i): %s", i, sText);
                    #endif
                    PrintHintText(i, sText);
                }
            }
        }
        if (StrContains(sType, "M") != -1) {
            new Handle:hPl = CreatePanel();
            DrawPanelText(hPl, sText);
            if ( GetConVarBool(g_hCvarShowExitButton) )
            {
                DrawPanelText(hPl, " ");
                DrawPanelItem(hPl, "Exit");
            }
            
            for (new i = 1; i <= MaxClients; i++) {
                if ( CanShowToClient(i) ) {
                    #if defined DEBUG
                        LogError("[DEBUG] SendPanel(%i): %s", i, sText);
                    #endif
                    SendPanelToClient(hPl, i, Handler_DoNothing, 10);
                }
            }
            
            CloseHandle(hPl);
        }
	if (StrContains(sType, "G") != -1) {
		decl String:sIcon[64],  String:sBackground[6],  String:sTeam[6];
		
		KvGetString(g_hAdvertisements, "icon",  sIcon,  sizeof(sIcon), "leaderboard_dominated");
		KvGetString(g_hAdvertisements, "background",  sBackground,  sizeof(sBackground), "0");
		KvGetString(g_hAdvertisements, "team", sTeam, sizeof(sTeam), "0");
		new Float:fTime = KvGetFloat(g_hAdvertisements, "time");
		TFGameText(sText, fTime, sIcon, sBackground, sTeam);
	}
    }
}

public Action:Timer_CenterAd(Handle:timer, Handle:pack) {
    decl String:sText[256];
    static iCount          = 0;
    
    ResetPack(pack);
    new iClient            = ReadPackCell(pack);
    ReadPackString(pack, sText, sizeof(sText));
    
    if (IsClientInGame(iClient) && ++iCount < 5) {
        PrintCenterText(iClient, sText);
        
        return Plugin_Continue;
    } else {
        iCount               = 0;
        g_hCenterAd[iClient] = INVALID_HANDLE;
        
        return Plugin_Stop;
    }
}

ParseAds() {
    g_iShowCountMax = 0;
    
    if (g_hAdvertisements != INVALID_HANDLE) {
        CloseHandle(g_hAdvertisements);
    }
    
    g_hAdvertisements = CreateKeyValues("Advertisements");
    
    decl String:sFile[256], String:sPath[256];
    GetConVarString(g_hFile, sFile, sizeof(sFile));
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
    
    if ( FileExists(sPath) ) {
        if ( !FileToKeyValues(g_hAdvertisements, sPath) ) {
            SetFailState("Can not convert file to KeyValues: %s", sPath);
        }
 
        new Handle:hWeights = CreateArray();
        new Handle:hCounts  = CreateArray();
        new Handle:hCountsTmp  = CreateArray();

        new index;
        new iShowCount;
        KvRewind(g_hAdvertisements);
        for ( new bool:result = KvGotoFirstSubKey(g_hAdvertisements); result ; result = KvGotoNextKey(g_hAdvertisements) ) {
            iShowCount = KvGetNum(g_hAdvertisements, "showcount");
            if ( iShowCount < 1 ) {
                iShowCount = 1;
                KvSetNum(g_hAdvertisements, "showcount", 1);
            }
            g_iShowCountMax += iShowCount;

            // count weights
            index = FindValueInArray(hWeights, iShowCount); 
            if ( index == -1 ) {
                PushArrayCell(hWeights, iShowCount);
                PushArrayCell(hCounts, 1);
                PushArrayCell(hCountsTmp, 0);
            } else {
                SetArrayCell(hCounts, index, GetArrayCell(hCounts, index)+1);
            }
        }
        
        if ( !g_iShowCountMax )
        {
            SetFailState("Can not find any data in file: %s", sPath);
        }
        
        new Float:fNextShow;
        new iCountTmp;
        new iCount;
        KvRewind(g_hAdvertisements);
        for ( new bool:result = KvGotoFirstSubKey(g_hAdvertisements); result ; result = KvGotoNextKey(g_hAdvertisements) ) {
            iShowCount = KvGetNum(g_hAdvertisements, "showcount");

            // count offsets
            index = FindValueInArray(hWeights, iShowCount); 
            iCountTmp = GetArrayCell(hCountsTmp, index);
            iCount = GetArrayCell(hCounts, index);
            fNextShow = iCountTmp*(g_iShowCountMax*1.0/(iShowCount*iCount));
            SetArrayCell(hCountsTmp, index, iCountTmp + 1);
            KvSetFloat(g_hAdvertisements, "nextshow", fNextShow);

            #if defined DEBUG
                LogError("[DEBUG] ParseAds: iShowCount = %i, fNextShow = %f, iCountTmp = %i, iCount = %i", 
                    iShowCount, fNextShow, iCountTmp, iCount);
            #endif
        }
    } else {
        SetFailState("File Not Found: %s", sPath);
    }
}

SayText2(to, const String:message[]) {
    new Handle:hBf = StartMessageOne("SayText2", to);
    
    if (hBf != INVALID_HANDLE) {
        BfWriteByte(hBf,   to);
        BfWriteByte(hBf,   true);
        BfWriteString(hBf, message);
        
        EndMessage();
    }
}

bool:HasFlag(iClient, AdminFlag:fFlagList[AdminFlags_TOTAL]) {
    new iFlags = GetUserFlagBits(iClient);
    if (iFlags & ADMFLAG_ROOT) {
        return true;
    } else {
        for (new i = 0; i < sizeof(fFlagList); i++) {
            if (iFlags & FlagToBit(fFlagList[i])) {
                return true;
            }
        }
        
        return false;
    }
}

bool:CanShowToClient(client)
{
    #if defined DEBUG
        return  IsClientInGame(client);
    #else
        return  IsClientInGame(client) 
                && !IsFakeClient(client)
                && ( ( !g_bAdmins && !(g_bFlags && HasFlag(client, g_fFlagList)) ) 
                    || ( g_bAdmins && ( GetUserFlagBits(client) & (ADMFLAG_GENERIC | ADMFLAG_ROOT) ) )
                );
    #endif
}

TFGameText(const String:message[], Float:time=10.0, const String:icon[]="leaderboard_dominated", const String:background[]="0", const String:team[]="0")
{
	if (!IsEntLimitReached(.message="unable to create game_text_tf")) {
		new Text_Ent = CreateEntityByName("game_text_tf");
		if (Text_Ent > 0 && IsValidEdict(Text_Ent))
		{
			DispatchKeyValue(Text_Ent,"message",message);
			DispatchKeyValue(Text_Ent,"display_to_team",team);
			DispatchKeyValue(Text_Ent,"icon",icon);
			DispatchKeyValue(Text_Ent,"targetname","game_text1");
			DispatchKeyValue(Text_Ent,"background",background);
			DispatchSpawn(Text_Ent);

			AcceptEntityInput(Text_Ent, "Display", Text_Ent, Text_Ent);

			CreateTimer(time, Kill_ent, EntIndexToEntRef(Text_Ent));
		}
	}
}

public Action:Kill_ent(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
	{
		decl String:classname[50];
		if (GetEdictClassname(ent, classname, sizeof(classname)) &&
		    StrEqual(classname, "game_text_tf", false))
		{
			AcceptEntityInput(ent, "kill");
		}
	}
}

/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 */
#tryinclude <entlimit>
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
	new max = GetMaxEntities();
	new count = GetEntityCount();
	new remaining = max - count;
	if (remaining <= warn)
	{
	    if (count <= critical)
	    {
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

		if (client > 0)
		{
		    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
				   count, max, remaining, message);
		}
	    }
	    else
	    {
		PrintToServer("Caution: Entity count is getting high!");
		LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

		if (client > 0)
		{
		    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
				   count, max, remaining, message);
		}
	    }
	    return count;
	}
	else
	    return 0;
    }
#endif

