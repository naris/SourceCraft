
#pragma semicolon 1

new Handle:g_Cvar_WinLimit  = INVALID_HANDLE;
new Handle:g_Cvar_FragLimit = INVALID_HANDLE;
new Handle:g_Cvar_MaxRounds = INVALID_HANDLE;

new g_TotalRounds;

/* Round count tracking */
public Event_TFRestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
    /* Game got restarted - reset our round count tracking */
    g_TotalRounds = 0;  
}

public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    /* Game got restarted - reset our round count tracking */
    g_TotalRounds = 0;  
}

public Event_TeamPlayWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetEventInt(event, "round_complete") == 1 || StrEqual(name, "arena_win_panel"))
    {
        g_TotalRounds++;
    }
}
/* You ask, why don't you just use team_score event? And I answer... Because CSS doesn't. */
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_TotalRounds++;
}

initTriggers()
{
    LoadTranslations("advertisements.phrases");
    g_Cvar_WinLimit     = FindConVar("mp_winlimit");
    g_Cvar_FragLimit    = FindConVar("mp_fraglimit");
    g_Cvar_MaxRounds    = FindConVar("mp_maxrounds");
    HookEvent("round_end",                  Event_RoundEnd);
    HookEventEx("teamplay_win_panel",       Event_TeamPlayWinPanel);
    HookEventEx("teamplay_restart_round",   Event_TFRestartRound);
    HookEventEx("arena_win_panel",          Event_TeamPlayWinPanel);
}

Triggers_GetNextMap(String:sMap[], size)
{
    decl String:map[64];
    
    if ( !GetNextMap(map, sizeof(map)) )
    {
        Format(sMap, size, "%t", "Pending Vote");
    }
    else
    {
        Format(sMap, size, "%t", "Next Map", map);
    }
    
    #if defined DEBUG
        LogError("[DEBUG] GetNextMap: sMap=%s", sMap);
    #endif
}

Triggers_GetTimeLeft(String:sTimeLeft[], size)
{
    new bool:lastround = false;
    new bool:written = false;
    new bool:notimelimit = false;
    
    decl String:finalOutput[1024];
    finalOutput[0] = 0;
    
    new timeleft;
    if (GetMapTimeLeft(timeleft))
    {
        new mins, secs;
        new timelimit;
        
        if (timeleft > 0)
        {
            mins = timeleft / 60;
            secs = timeleft % 60;
            written = true;
            FormatEx(finalOutput, sizeof(finalOutput), "%d:%02d", mins, secs);
        }
        else if (GetMapTimeLimit(timelimit) && timelimit == 0)
        {
            notimelimit = true;
        }
        else
        {
            /* 0 timeleft so this must be the last round */
            lastround=true;
        }
    }
    
    if (!lastround)
    {
        if (g_Cvar_WinLimit != INVALID_HANDLE)
        {
            new winlimit = GetConVarInt(g_Cvar_WinLimit);
            
            if (winlimit > 0)
            {
                if (written)
                {
                    new len = strlen(finalOutput);
                    if (len < sizeof(finalOutput))
                    {
                        if (winlimit > 1)
                        {
                            FormatEx(finalOutput[len], sizeof(finalOutput)-len, "%t", "WinLimitAppendPlural", winlimit);
                        }
                        else
                        {
                            FormatEx(finalOutput[len], sizeof(finalOutput)-len, "%t", "WinLimitAppend");
                        }
                    }
                }
                else
                {
                    if (winlimit > 1)
                    {
                        FormatEx(finalOutput, sizeof(finalOutput), "%t", "WinLimitPlural", winlimit);
                    }
                    else
                    {
                        FormatEx(finalOutput, sizeof(finalOutput), "%t", "WinLimit");
                    }
                    
                    written = true;
                }
            }
        }
        
        if (g_Cvar_FragLimit != INVALID_HANDLE)
        {
            new fraglimit = GetConVarInt(g_Cvar_FragLimit);
            
            if (fraglimit > 0)
            {
                if (written)
                {
                    new len = strlen(finalOutput);
                    if (len < sizeof(finalOutput))
                    {
                        if (fraglimit > 1)
                        {
                            FormatEx(finalOutput[len], sizeof(finalOutput)-len, "%t", "FragLimitAppendPlural", fraglimit);
                        }
                        else
                        {
                            FormatEx(finalOutput[len], sizeof(finalOutput)-len, "%t", "FragLimitAppend");
                        }
                    }   
                }
                else
                {
                    if (fraglimit > 1)
                    {
                        FormatEx(finalOutput, sizeof(finalOutput), "%t", "FragLimitPlural", fraglimit);
                    }
                    else
                    {
                        FormatEx(finalOutput, sizeof(finalOutput), "%t", "FragLimit");
                    }
                    
                    written = true;
                }           
            }
        }
        
        if (g_Cvar_MaxRounds != INVALID_HANDLE)
        {
            new maxrounds = GetConVarInt(g_Cvar_MaxRounds);
            
            if (maxrounds > 0)
            {
                new remaining = maxrounds - g_TotalRounds;
                
                if (written)
                {
                    new len = strlen(finalOutput);
                    if (len < sizeof(finalOutput))
                    {
                        if (remaining > 1)
                        {
                            FormatEx(finalOutput[len], sizeof(finalOutput)-len, "%t", "MaxRoundsAppendPlural", remaining);
                        }
                        else
                        {
                            FormatEx(finalOutput[len], sizeof(finalOutput)-len, "%t", "MaxRoundsAppend");
                        }
                    }
                }
                else
                {
                    if (remaining > 1)
                    {
                        FormatEx(finalOutput, sizeof(finalOutput), "%t", "MaxRoundsPlural", remaining);
                    }
                    else
                    {
                        FormatEx(finalOutput, sizeof(finalOutput), "%t", "MaxRounds");
                    }
                    
                    written = true;
                }           
            }       
        }
    }
    
    if (lastround)
    {
        FormatEx(finalOutput, sizeof(finalOutput), "%t", "LastRound");
    }
    else if (notimelimit && !written)
    {
        FormatEx(finalOutput, sizeof(finalOutput), "%t", "NoTimelimit");
    }
    #if defined DEBUG
        LogError("[DEBUG] GetTimeLeft: finalOutput=%s", finalOutput);
    #endif
    
    strcopy(sTimeLeft, size, finalOutput);
}

