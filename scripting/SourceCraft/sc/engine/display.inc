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

DisplayDamage(client, victim, hp, const String:weapon[],
              const String:desc[], bool:no_translate=false)
{
    if (victim > 0)
    {
        new bool:clientInGame;
        new bool:clientIsFake;
        decl String:steamID[NAME_STRING_LENGTH];
        decl String:team[NAME_STRING_LENGTH];

        if (IsValidClient(client))
        {
            GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
            GetTeamName(GetClientTeam(client), team, sizeof(team));
            clientIsFake = IsFakeClient(client);
            clientInGame = true;
        }
        else
        {
            clientIsFake = true;
            clientInGame = false;
            steamID[0] = '\0';
            team[0] = '\0';
        }

        new bool:victimInGame;
        new bool:victimIsFake;
        new bool:victimIsValid;
        decl String:victimID[NAME_STRING_LENGTH];
        decl String:victimTeam[NAME_STRING_LENGTH];
        decl String:victimName[NAME_STRING_LENGTH];

        if (victim == client)
        {
            strcopy(victimID, sizeof(victimID), steamID);
            strcopy(victimTeam, sizeof(victimTeam), team);
            victimIsFake = clientIsFake;
            victimInGame = clientInGame;
            victimIsValid = true;
            victimName[0] = '\0';
        }
        else if (IsValidClient(victim))
        {
            GetClientAuthId(victim, AuthId_Steam2, victimID, sizeof(victimID));
            GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));
            victimIsFake = IsFakeClient(victim);
            victimInGame = true;
            victimIsValid = true;
            victimName[0] = '\0';
        }
        else
        {
            GetEntityName(victim, victimName, sizeof(victimName), client);
            victimIsFake = true;
            victimInGame = false;
            victimIsValid = false;
            victimTeam[0] = '\0';
            victimID[0] = '\0';
        }

        if (clientInGame && victimInGame)
        {
            if (weapon[0])
            {
               LogToGame("\"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s",
                          client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
            }
            else
            {
               LogToGame("\"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d",
                          client, client, steamID, team, victim, victim, victimID, victimTeam, hp);
            }

            if (!clientIsFake)
            {
                if (weapon[0])
                {
                    PrintToConsole(client, "[SC] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
                }
                else
                {
                    PrintToConsole(client, "[SC] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp);
                }
            }

            if (victim != client && victimInGame && !victimIsFake)
            {
                if (weapon[0])
                {
                    PrintToConsole(victim, "[SC] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
                }
                else
                {
                    PrintToConsole(victim, "[SC] \"%N<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d",
                                   client, client, steamID, team, victim, victim, victimID, victimTeam, hp);
                }
            }
        }
        else if (victimInGame)
        {
            if (weapon[0])
            {
                LogToGame("\"<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s",
                          client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
            }
            else
            {
                LogToGame("\"<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d",
                          client, steamID, team, victim, victim, victimID, victimTeam, hp);
            }

            if (!victimIsFake)
            {
                if (weapon[0])
                {
                    PrintToConsole(victim, "[SC] \"<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d with %s",
                                   client, steamID, team, victim, victim, victimID, victimTeam, hp, weapon);
                }
                else
                {
                    PrintToConsole(victim, "[SC] \"<%d><%s><%s>\" damaged \"%N<%d><%s><%s>\" for %d",
                                   client, steamID, team, victim, victim, victimID, victimTeam, hp);
                }
            }
        }

        if (victim == client)
        {
            if (victimInGame && !victimIsFake)
            {
                new Display:victimBits = g_ClientDisplayBits[victim];
                if (FlipBit_IsSet(victimBits & Display_Injury_Hints) ||
                    FlipBit_IsSet(victimBits & Display_Injury))
                {
                    new String:description[NAME_STRING_LENGTH];
                    if (desc[0] == '%')
                        Format(description, sizeof(description), "%T", desc[1], victim);
                    else if (desc[0] == '\0' && weapon[0] != '\0' && !no_translate)
                        Format(description, sizeof(description), "%T", weapon, victim);
                    else
                        strcopy(description, sizeof(description), desc);

                    if (FlipBit_IsSet(victimBits & Display_Injury_Hints))
                    {
                        if (description[0])
                        {
                            DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                        "%t", "DamagedSelfWith",
                                        hp, description);
                        }
                        else
                        {
                            DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                        "%t", "DamagedSelf", hp);
                        }
                    }
                    else //if (FlipBit_IsSet(victimBits & Display_Injury))
                    {
                        if (description[0])
                        {
                            CPrintToChat(victim, "{green}[SC]{default} %t", "DamagedSelfWith",
                                         hp, description);
                        }
                        else
                        {
                            CPrintToChat(victim, "{green}[SC]{default} %t", "DamagedSelf", hp);
                        }
                    }
                }
            }
        }
        else
        {
            if (victimInGame && !victimIsFake)
            {
                new Display:victimBits = g_ClientDisplayBits[victim];
                if (FlipBit_IsSet(victimBits & Display_Injury_Hints) ||
                    FlipBit_IsSet(victimBits & Display_Injury))
                {
                    new String:description[NAME_STRING_LENGTH];
                    if (desc[0] == '%')
                        Format(description, sizeof(description), "%T", desc[1], victim);
                    else if (desc[0] == '\0' && weapon[0] != '\0' && !no_translate)
                        Format(description, sizeof(description), "%T", weapon, victim);
                    else
                        strcopy(description, sizeof(description), desc);

                    if (FlipBit_IsSet(victimBits & Display_Injury_Hints))
                    {
                        if (clientInGame)
                        {
                            if (description[0])
                            {
                                DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                            "%t", "DamagedByWith",
                                            client, hp, description);
                            }
                            else
                            {
                                DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                            "%t", "DamagedBy", client, hp);
                            }
                        }
                        else
                        {
                            if (desc[0])
                            {
                                DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                            "%t", "DamagedWith", hp, desc);
                            }
                            else
                            {
                                DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                            "%t", "Damaged", hp);
                            }
                        }
                    }
                    else //if (FlipBit_IsSet(victimBits & Display_Injury))
                    {
                        if (clientInGame)
                        {
                            if (description[0])
                            {
                                CPrintToChat(victim, "{green}[SC]{default} %t", "DamagedByWith",
                                             client, hp, description);
                            }
                            else
                            {
                                CPrintToChat(victim, "{green}[SC]{default} %t", "DamagedBy",
                                             client, hp);
                            }
                        }
                        else
                        {
                            if (desc[0])
                            {
                                CPrintToChat(victim, "{green}[SC]{default} %t", "DamagedWith",
                                             hp, desc);
                            }
                            else
                            {
                                CPrintToChat(victim, "{green}[SC]{default} %t", "Damaged", hp);
                            }
                        }
                    }
                }
            }

            if (clientInGame && !clientIsFake)
            {
                new Display:displayBits = g_ClientDisplayBits[client];
                if (FlipBit_IsSet(displayBits & Display_Damage_Hints) ||
                    FlipBit_IsSet(displayBits & Display_Damage))
                {
                    new String:description[NAME_STRING_LENGTH];
                    if (desc[0] == '%')
                        Format(description, sizeof(description), "%T", desc[1], client);
                    else if (desc[0] == '\0' && weapon[0] != '\0' && !no_translate)
                        Format(description, sizeof(description), "%T", weapon, client);
                    else
                        strcopy(description, sizeof(description), desc);

                    if (FlipBit_IsSet(displayBits & Display_Damage_Hints))
                    {
                        if (victimIsValid)
                        {
                            if (description[0])
                            {
                                DisplayHint(client, HintSlot_Damage, false, 5.0,
                                            "%t", "YouDamagedWith",
                                            victim, hp, description);
                            }
                            else
                            {
                                DisplayHint(client, HintSlot_Damage, false, 5.0,
                                            "%t", "YouDamaged", victim, hp);
                            }
                        }
                        else if (victimName[0])
                        {
                            if (description[0])
                            {
                                DisplayHint(client, HintSlot_Damage, false, 5.0,
                                            "%t", "YouDamagedEntityWith",
                                            victimName, hp, description);
                            }
                            else
                            {
                                DisplayHint(client, HintSlot_Damage, false, 5.0,
                                            "%t", "YouDamagedEntity",
                                            victimName, hp);
                            }
                        }
                    }
                    else // if (FlipBit_IsSet(displayBits & Display_Damage))
                    {
                        if (victimIsValid)
                        {
                            if (description[0])
                            {
                                CPrintToChat(client, "{green}[SC]{default} %t", "YouDamagedWith",
                                             victim, hp, description);
                            }
                            else
                            {
                                CPrintToChat(client, "{green}[SC]{default} %t", "YouDamaged",
                                             victim, hp);
                            }
                        }
                        else if (victimName[0])
                        {
                            if (description[0])
                            {
                                CPrintToChat(client, "{green}[SC]{default} %t", "YouDamagedEntityWith",
                                             victimName, hp, description);
                            }
                            else
                            {
                                CPrintToChat(client, "{green}[SC]{default} %t", "YouDamagedEntity",
                                             victimName, hp);
                            }
                        }
                    }
                }
            }
        }
    }
}

DisplayKill(client, victim, xp=0, const String:weapon[]="",
            const String:desc[]="", bool:no_translate=false)
{
    if (victim > 0)
    {
        new bool:clientInGame;
        new bool:clientIsFake;
        decl String:steamID[NAME_STRING_LENGTH];
        decl String:team[NAME_STRING_LENGTH];

        if (IsValidClient(client))
        {
            GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
            GetTeamName(GetClientTeam(client), team, sizeof(team));
            clientIsFake = IsFakeClient(client);
            clientInGame = true;
        }
        else
        {
            clientIsFake = false;
            clientInGame = false;
            steamID[0] = 0;
            team[0] = 0;
        }

        new bool:victimInGame;
        new bool:victimIsFake;
        new bool:victimIsValid;
        decl String:victimID[NAME_STRING_LENGTH];
        decl String:victimTeam[NAME_STRING_LENGTH];
        decl String:victimName[NAME_STRING_LENGTH];

        if (victim == client)
        {
            strcopy(victimID, sizeof(victimID), steamID);
            strcopy(victimTeam, sizeof(victimTeam), team);
            victimIsFake = clientIsFake;
            victimInGame = clientInGame;
            victimIsValid = true;
            victimName[0] = '\0';
        }
        else if (IsValidClient(victim))
        {
            GetClientAuthId(victim, AuthId_Steam2, victimID, sizeof(victimID));
            GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));
            victimIsFake = IsFakeClient(victim);
            victimInGame = true;
            victimIsValid = true;
            victimName[0] = '\0';
        }
        else
        {
            GetEntityName(victim, victimName, sizeof(victimName), client);
            victimIsFake = false;
            victimInGame = false;
            victimIsValid = false;
            victimTeam[0] = 0;
            victimID[0] = 0;
        }

        if (clientInGame && victimInGame)
        {
            if (weapon[0])
            {
                if (xp != 0)
                {
                    LogToGame("\"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)",
                              client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
                }
                else
                {
                    LogToGame("\"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s",
                              client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
                }
            }
            else
            {
                if (xp != 0)
                {
                    LogToGame("\"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" (%d XP)",
                              client, client, steamID, team, victim, victim, victimID, victimTeam,  xp);
                }
                else
                {
                    LogToGame("\"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\"",
                              client, client, steamID, team, victim, victim, victimID, victimTeam);
                }
            }

            if (!clientIsFake)
            {
                if (weapon[0])
                {
                    if (xp != 0)
                    {
                        PrintToConsole(client, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
                    }
                    else
                    {
                        PrintToConsole(client, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
                    }
                }
                else
                {
                    if (xp != 0)
                    {
                        PrintToConsole(client, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" (%d XP)",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam,  xp);
                    }
                    else
                    {
                        PrintToConsole(client, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\"",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam);
                    }
                }
            }

            if (victim != client && victimInGame && !victimIsFake)
            {
                if (weapon[0])
                {
                    if (xp != 0)
                    {
                        PrintToConsole(victim, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
                    }
                    else
                    {
                        PrintToConsole(victim, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam, weapon);
                    }
                }
                else
                {
                    if (xp != 0)
                    {
                        PrintToConsole(victim, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" (%d XP)",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam,  xp);
                    }
                    else
                    {
                        PrintToConsole(victim, "[SC] \"%N<%d><%s><%s>\" killed \"%N<%d><%s><%s>\"",
                                       client, client, steamID, team, victim, victim, victimID, victimTeam);
                    }
                }
            }
        }
        else if (victimInGame)
        {
            if (weapon[0])
            {
                if (xp != 0)
                {
                    LogToGame("\"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)",
                              client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
                }
                else
                {
                    LogToGame("\"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s",
                              client, steamID, team, victim, victim, victimID, victimTeam, weapon);
                }
            }
            else
            {
                if (xp != 0)
                {
                    LogToGame("\"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" (%d XP)",
                              client, steamID, team, victim, victim, victimID, victimTeam,  xp);
                }
                else
                {
                    LogToGame("\"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\"",
                              client, steamID, team, victim, victim, victimID, victimTeam);
                }
            }

            if (victimInGame && !victimIsFake)
            {
                if (weapon[0])
                {
                    if (xp != 0)
                    {
                        PrintToConsole(victim, "[SC] \"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s (%d XP)",
                                       client, steamID, team, victim, victim, victimID, victimTeam, weapon,  xp);
                    }
                    else
                    {
                        PrintToConsole(victim, "[SC] \"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" with %s",
                                       client, steamID, team, victim, victim, victimID, victimTeam, weapon);
                    }
                }
                else
                {
                    if (xp != 0)
                    {
                        PrintToConsole(victim, "[SC] \"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\" (%d XP)",
                                       client, steamID, team, victim, victim, victimID, victimTeam,  xp);
                    }
                    else
                    {
                        PrintToConsole(victim, "[SC] \"<%d><%s><%s>\" killed \"%N<%d><%s><%s>\"",
                                       client, steamID, team, victim, victim, victimID, victimTeam);
                    }
                }
            }
        }

        if (victim == client)
        {
            if (victimInGame && !victimIsFake)
            {
                new Display:victimBits = g_ClientDisplayBits[victim];
                if (FlipBit_IsSet(victimBits & Display_Death_Hints) ||
                    FlipBit_IsSet(victimBits & Display_Deaths))
                {
                    new String:description[NAME_STRING_LENGTH];
                    if (desc[0] == '%')
                        Format(description, sizeof(description), "%T", desc[1], victim);
                    else if (desc[0] == '\0' && weapon[0] != '\0' && !no_translate)
                        Format(description, sizeof(description), "%T", weapon, victim);
                    else
                        strcopy(description, sizeof(description), desc);

                    if (FlipBit_IsSet(victimBits & Display_Injury_Hints))
                    {
                        if (description[0])
                        {
                            DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                        "%t", "KilledSelfWith",
                                        description);
                        }
                        else
                        {
                            DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                        "%t", "KilledSelf");
                        }
                    }
                    else //if (FlipBit_IsSet(victimBits & Display_Deaths))
                    {
                        if (description[0])
                        {
                            CPrintToChat(victim, "{green}[SC]{default} %t", "KilledSelfWith",
                                         description);
                        }
                        else
                        {
                            CPrintToChat(victim, "{green}[SC]{default} %t", "KilledSelf");
                        }
                    }
                }
            }
        }
        else
        {
            if (victimInGame && !victimIsFake)
            {
                new Display:victimBits = g_ClientDisplayBits[victim];
                if (FlipBit_IsSet(victimBits & Display_Death_Hints) ||
                    FlipBit_IsSet(victimBits & Display_Deaths))
                {
                    new String:description[NAME_STRING_LENGTH];
                    if (desc[0] == '%')
                        Format(description, sizeof(description), "%T", desc[1], victim);
                    else if (desc[0] == '\0' && weapon[0] != '\0' && !no_translate)
                        Format(description, sizeof(description), "%T", weapon, victim);
                    else
                        strcopy(description, sizeof(description), desc);

                    if (FlipBit_IsSet(victimBits & Display_Injury_Hints))
                    {
                        if (description[0])
                        {
                            DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                        "%t", "KilledByWith",
                                        client, description);
                        }
                        else
                        {
                            DisplayHint(victim, HintSlot_Injury, false, 5.0,
                                        "%t", "KilledBy", client);
                        }
                    }
                    else //if (FlipBit_IsSet(victimBits & Display_Deaths))
                    {
                        if (description[0])
                        {
                            CPrintToChat(victim, "{green}[SC]{default} %t", "KilledByWith",
                                         client, description);
                        }
                        else
                        {
                            CPrintToChat(victim, "{green}[SC]{default} %t", "KilledBy", client);
                        }
                    }
                }

                if (clientInGame && !clientIsFake)
                {
                    new Display:displayBits = g_ClientDisplayBits[client];
                    if (FlipBit_IsSet(displayBits & Display_Kill_Hints) ||
                        FlipBit_IsSet(displayBits & Display_Kills))
                    {
                        new String:description[NAME_STRING_LENGTH];
                        if (desc[0] == '%')
                            Format(description, sizeof(description), "%T", desc[1], client);
                        else if (desc[0] == '\0' && weapon[0] != '\0' && !no_translate)
                            Format(description, sizeof(description), "%T", weapon, client);
                        else
                            strcopy(description, sizeof(description), desc);

                        if (FlipBit_IsSet(displayBits & Display_Damage_Hints))
                        {
                            if (victimIsValid)
                            {
                                if (description[0])
                                {
                                    if (xp)
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "GainedXPForKillWith",
                                                    xp, victim, description);
                                    }
                                    else
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "YouKilledWith",
                                                    victim, description);
                                    }
                                }
                                else
                                {
                                    if (xp)
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "GainedXPForKill",
                                                    xp, victim);
                                    }
                                    else
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "YouKilled", victim);
                                    }
                                }
                            }
                            else if (victimName[0])
                            {
                                if (description[0])
                                {
                                    if (xp)
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "GainedXPForEntityKillWith",
                                                    xp, victimName, description);
                                    }
                                    else
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "YouKilledEntityWith",
                                                    victimName, description);
                                    }
                                }
                                else
                                {
                                    if (xp)
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "GainedXPForEntityKill",
                                                    xp, victimName);
                                    }
                                    else
                                    {
                                        DisplayHint(client, HintSlot_Damage, false, 5.0,
                                                    "%t", "YouKilledEntity", victimName);
                                    }
                                }
                            }
                        }
                        else // if (FlipBit_IsSet(displayBits & Display_Kills))
                        {
                            if (victimIsValid)
                            {
                                if (description[0])
                                {
                                    if (xp)
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "GainedXPForKillWith",
                                                     xp, victim, description);
                                    }
                                    else
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "YouKilledWith",
                                                     victim, description);
                                    }
                                }
                                else
                                {
                                    if (xp)
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "GainedXPForKill",
                                                     xp, victim);
                                    }
                                    else
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "YouKilled",
                                                     victim);
                                    }
                                }
                            }
                            else if (victimName[0])
                            {
                                if (description[0])
                                {
                                    if (xp)
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "GainedXPForEntityKillWith",
                                                     xp, victimName, description);
                                    }
                                    else
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "YouKilledEntityWith",
                                                     victimName, description);
                                    }
                                }
                                else
                                {
                                    if (xp)
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "GainedXPForEntityKill",
                                                     xp, victimName);
                                    }
                                    else
                                    {
                                        CPrintToChat(client, "{green}[SC]{default} %t", "YouKilledEntity",
                                                     victimName);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

DisplayMessage(client, Display:flags, const String:fmt[], any:...)
{
    decl String:buffer[1024];

    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), fmt, 4);

    // Debug
    if (StrContains(buffer, "%") >= 0)
    {
        LogError("Attempt to Display bad %s Message to %N:%s",
                 fmt, ValidClientIndex(client), buffer);
        return;
    }

    new bool:displayHint = false;
    new HintSlot:slot = HintSlot_Default;
    new bool:displayToClient = (IsValidClient(client) && !IsFakeClient(client));
    if (displayToClient)
    {
        new Display:displayBits = g_ClientDisplayBits[client];
        if (Bit_IsSet(flags & Display_Damage))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Damage_Hints);
            slot = HintSlot_Damage;
        }
        else if (Bit_IsSet(flags & Display_Kills))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Kill_Hints);
            slot = HintSlot_Damage;
        }
        else if (Bit_IsSet(flags & Display_Injury))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Injury_Hints);
            slot = HintSlot_Injury;
        }
        else if (Bit_IsSet(flags & Display_Deaths))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Death_Hints);
            slot = HintSlot_Injury;
        }
        else if (Bit_IsSet(flags & Display_Ultimate))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Ultimate_Hints);
            slot = HintSlot_Status;
        }
        else if (Bit_IsSet(flags & Display_Enemy_Ultimate))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Enemy_Ultimate_Hints);
            slot = HintSlot_Status;
        }
        else if (Bit_IsSet(flags & Display_Message))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Message_Hints);
            slot = HintSlot_Status;
        }
        else if (Bit_IsSet(flags & Display_Enemy_Message))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Enemy_Message_Hints);
            slot = HintSlot_Status;
        }
        else if (Bit_IsSet(flags & Display_Defense))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Defense_Hints);
            slot = HintSlot_Status;
        }
        else if (Bit_IsSet(flags & Display_Enemy_Defended))
        {
            displayHint = FlipBit_IsSet(displayBits & Display_Enemy_Defended_Hints);
            slot = HintSlot_Status;
        }

        if (!displayHint)
        {
            if (FlipBit_IsSet(displayBits & flags))
            {
                CPrintToChat(client, "{green}[SC]{default} %s", buffer);
                //LogMessage("%d:%N's Client Bits=%08x, Flags=%08x, Display %s",
                //           client, ValidClientIndex(client), displayBits, flags, buffer);
            }
            else if (Bit_IsSet(displayBits & Display_All_Hints))
            {
                displayHint = true;
            }
        }
    }

    CleanMessage(buffer, sizeof(buffer));

    if (displayToClient)
    {
        if (displayHint)
        {
            SubmitHint(client, slot, false, 5.0, buffer);
            //LogMessage("%d:%N's Client Bits=%08x, Flags=%08x, Hint %s",
            //           client, ValidClientIndex(client), g_ClientDisplayBits[client], flags, buffer);
        }

        PrintToConsole(client, buffer);
        CleanServerMessage(client, buffer, sizeof(buffer));
    }

    LogToGame(buffer);
    PrintToServer(buffer);

    // Debug
    if (StrContains(buffer, "{") >= 0)
    {
        LogError("Malformed %s Message displayed to %N %s",
                 fmt, ValidClientIndex(client), buffer);
    }
}

DisplayHint(client, HintSlot:slot=HintSlot_Generic, bool:exclusive=false,
            Float:duration=5.0, const String:fmt[]="", any:...)
{
    decl String:buffer[LONG_STRING_LENGTH];

    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), fmt, 6);

    CleanMessage(buffer, sizeof(buffer));
    SubmitHint(client, slot, exclusive, duration, buffer);
}

SubmitHint(client, HintSlot:slot=HintSlot_Generic, bool:exclusive=false,
           Float:duration=5.0, const String:buffer[]="", bool:update=true)
{
    new Handle:hintSlot=g_HintStack[client][slot];
    if (hintSlot == INVALID_HANDLE)
        g_HintStack[client][slot] = hintSlot = CreateArray();

    new Handle:pack = INVALID_HANDLE;
    new size = GetArraySize(hintSlot);
    for (new index=0; index < size; index++)
    {
        new Handle:cell = Handle:GetArrayCell(hintSlot,index);
        if (cell != INVALID_HANDLE)
        {
            if (exclusive)
            {
                CloseHandle(cell);
            }
            else
            {
                ResetPack(cell);
                ReadPackFloat(cell);

                decl String:line[LONG_STRING_LENGTH];
                ReadPackString(cell, line, sizeof(line));

                if (StrEqual(buffer,line,false))
                {
                    pack = cell;
                    break;
                }
            }
        }
    }

    if (exclusive)
    {
        ClearArray(hintSlot);
    }

    if (pack == INVALID_HANDLE)
    {
        pack = CreateDataPack();
        WritePackFloat(pack, GetEngineTime() + duration);
        WritePackString(pack, buffer);
        PushArrayCell(hintSlot, pack);
    }
    else // Reset the end time
    {
        ResetPack(pack);
        WritePackFloat(pack, GetEngineTime() + duration);
        //WritePackString(pack, buffer); // already in the pack
    }

    if (update)
    {
        UpdatePlayerProperties(client);
    }
}

CleanMessage(String:buffer[], maxlen)
{
    // Remove color codes
    ReplaceString(buffer, maxlen, "{default}", "", false);
    ReplaceString(buffer, maxlen, "{green}", "", false);
    ReplaceString(buffer, maxlen, "{lightgreen}", "", false);
    ReplaceString(buffer, maxlen, "{red}", "", false);
    ReplaceString(buffer, maxlen, "{blue}", "", false);
    ReplaceString(buffer, maxlen, "{olive}", "", false);
    ReplaceString(buffer, maxlen, "{custom}", "", false);

    // Convert control characters (color codes) to spaces
    for (new i = strlen(buffer)-1; i >= 0; i--)
    {
        if (buffer[i] < ' ')
            buffer[i] = ' ';
    }
}

CleanServerMessage(client, String:buffer[], maxlen)
{
    if (StrContains(buffer, "Your", false) != -1)
    {
        decl String:owner[MAX_NAME_LENGTH];
        GetClientName(client,owner,sizeof(owner));
        StrCat(owner, sizeof(owner), "'s");
        ReplaceString(buffer, maxlen, "Your", owner, false);
    }

    if (StrContains(buffer, "You have", false) != -1)
    {
        decl String:name[MAX_NAME_LENGTH];
        GetClientName(client,name,sizeof(name));
        StrCat(name, sizeof(name), " has");
        ReplaceString(buffer, maxlen, "You have", name, false);
    }

    if (StrContains(buffer, "You", false) != -1)
    {
        decl String:name[MAX_NAME_LENGTH];
        GetClientName(client,name,sizeof(name));
        ReplaceString(buffer, maxlen, "You", name, false);
    }
}

InitHint()
{
    // Hook HintText messages
    HookUserMessage(GetUserMessageId("HintText"), HintTextHook);
}

public Action:HintTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    new String:str[LONG_STRING_LENGTH];
    BfReadString(Handle:bf, str, sizeof(str), false);

    if (str[0] != ' ' && str[0] != '#')
    {
        for (new i = 0; i < playersNum; i++)
        {
            new client = players[i];
            if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
            {
                StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
                SubmitHint(client, HintSlot_Generic, false, 5.0, str, false);
            }
        }
        return Plugin_Handled;
    }
    else
        return Plugin_Continue;
}

bool:GetEntityName(entIndex, String:entName[], nameMax, lang=LANG_SERVER)
{
    decl String:entClass[NAME_STRING_LENGTH];
    GetEdictClassname(entIndex, entClass, sizeof(entClass));

    if (StrEqual(entClass, "headless_hatman")               ||
        StrEqual(entClass, "eyeball_boss")                  ||
        StrEqual(entClass, "merasmus")                      ||
        StrEqual(entClass, "tank_boss")                     ||
        StrEqual(entClass, "tf_zombie")                     ||
        StrEqual(entClass, "tf_robot_destruction_robot")    ||
        StrEqual(entClass, "ghost")                         ||
        StrEqual(entClass, "obj_sentrygun")                 ||
        StrEqual(entClass, "obj_dispenser")                 ||
        StrEqual(entClass, "obj_teleporter")                ||
        StrEqual(entClass, "obj_attachment_sapper"))
    {
        Format(entName, nameMax, "%T", entClass, lang);
        return true;
    }
    else
    {
        decl String:translation_path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, translation_path, sizeof(translation_path), "translations/sc.entity.phrases.txt");
        if (FileContains("", entClass))
        {
            LogMessage("Entity Class %s is defined in sc.entity.phrases.txt, but not in GetEntityName()", entClass);
            Format(entName, nameMax, "%T", entClass, lang);
            return true;
        }
        else
        {
            // Log other entity classes for addition to this code.
            LogError("Unknown Entity Class %s has no name", entClass);
            strcopy(entName, nameMax, entClass);
            //entName[0] = '\0';
            return false;
        }
    }
}
