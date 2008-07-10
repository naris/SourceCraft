/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: display.inc
 * Description: Display information on Damage and Kills
 * Author(s): Naris (Murray Wilson)
 */

#if defined _display_included
 #endinput
#endif
#define _display_included

DisplayDamage(client, victim, const String:weapon[], const String:description[], hp)
{
    if (victim)
    {
        decl String:steamID[64];
        decl String:team[64];

        if (client)
        {
            GetClientAuthString(client,steamID,63);
            GetTeamName(GetClientTeam(client), team, sizeof(team));
        }
        else
        {
            steamID[0] = 0;
            team[0] = 0;
        }

        decl String:victimID[64];
        GetClientAuthString(victim,victimID,63);

        decl String:victimTeam[64];
        GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

        if (weapon[0] || description[0])
        {
            PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
                           client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

            LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
                      client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);

            if (victim == client)
            {
                if ((g_DisplayFlags[victim] & SC_DISPLAY_DAMAGE_TAKEN) == 0)
                {
                    PrintToChat(victim, "%c[SourceCraft]%c You have damaged yourself for %d with %c%s%c",
                                COLOR_GREEN,COLOR_DEFAULT,hp,COLOR_TEAM,description,COLOR_DEFAULT);
                }
            }
            else
            {
                if ((g_DisplayFlags[victim] & SC_DISPLAY_DAMAGE_TAKEN) == 0)
                {
                    PrintToChat(victim, "%c[SourceCraft] %N %chas damaged you for %d with %c%s%c",
                                COLOR_GREEN,client,COLOR_DEFAULT,hp,COLOR_TEAM,description,COLOR_DEFAULT);
                }

                if (client)
                {
                    if ((g_DisplayFlags[victim] & SC_DISPLAY_DAMAGE_DONE) == 0)
                    {
                        PrintToChat(client, "%c[SourceCraft] %cYou damaged %N for %d hp with %c%s%c.",
                                    COLOR_GREEN,COLOR_DEFAULT,victim, hp, COLOR_TEAM,description,COLOR_DEFAULT);
                    }

                    PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s\n",
                                client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
                }
            }
        }
    }
}

DisplayKill(client, victim, const String:weapon[], const String:description[], xp=0)
{
    if (victim)
    {
        decl String:steamID[64];
        decl String:team[64];

        if (client)
        {
            GetClientAuthString(client,steamID,63);
            GetTeamName(GetClientTeam(client), team, sizeof(team));
        }
        else
        {
            steamID[0] = 0;
            team[0] = 0;
        }

        decl String:victimID[64];
        GetClientAuthString(victim,victimID,63);

        decl String:victimTeam[64];
        GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

        if (weapon[0] || description[0])
        {
            if (victim == client)
            {
                if ((g_DisplayFlags[victim] & SC_DISPLAY_DEATHS) == 0)
                {
                    PrintToChat(victim, "%c[SourceCraft]%c You killed yourself with %c%s%c",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,description,COLOR_DEFAULT);
                }

                PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s\n",
                               client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

                LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" fatally injured \"%N<%d><%s><%s>\" with %s\n",
                          client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
            }
            else
            {
                if ((g_DisplayFlags[victim] & SC_DISPLAY_DEATHS) == 0)
                {
                    PrintToChat(victim, "%c[SourceCraft] %N %c killed you with %c%s%c",
                                COLOR_GREEN,client,COLOR_DEFAULT,COLOR_TEAM,description,COLOR_DEFAULT);
                }

                if (xp)
                {
                    if (client && (g_DisplayFlags[victim] & SC_DISPLAY_KILLS) == 0)
                    {
                        PrintToChat(client, "%c[SourceCraft] %cYou gained %d XP for killing %N with %c%s%c.",
                                    COLOR_GREEN,COLOR_DEFAULT,xp,victim, COLOR_TEAM,description,COLOR_DEFAULT);
                    }

                    PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

                    PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);

                    LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" fatally injured \"%N<%d><%s><%s>\" with %s (%d XP)\n",
                              client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
                }
                else
                {
                    if (client && (g_DisplayFlags[victim] & SC_DISPLAY_KILLS) == 0)
                    {
                        PrintToChat(client, "%c[SourceCraft] %cYou killed %N with %c%s%c.",
                                    COLOR_GREEN,COLOR_DEFAULT,victim, COLOR_TEAM,description,COLOR_DEFAULT);
                    }

                    PrintToConsole(client, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s\n",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

                    PrintToConsole(victim, "[SourceCraft] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s\n",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);

                    LogToGame("[SourceCraft] \"%N<%d><%s><%s>\" fatally injured \"%N<%d><%s><%s>\" with %s\n",
                              client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
                }
            }
        }
    }
}

DisplayMessage(client, flags, const String:fmt[], any:...)
{
        decl String:buffer[1024];

        VFormat(buffer, sizeof(buffer), fmt, 4);

        LogToGame(buffer);
        PrintToServer(buffer);

        if (client)
        {
            PrintToConsole(client, buffer);
            if ((g_DisplayFlags[client] & flags) == 0)
                PrintToChat(client, buffer);
        }
}
