////////////////////////////////////////////////////////////////////////////////
// Original Hashing method by "PM", tweaked by psychonic
////////////////////////////////////////////////////////////////////////////////

#define chars_per_cell (cellbits / 8)

compute_hash(const String:input[])
{
	new res = 0xFFFFFFFF;

	for (new i = 0; input[i]; ++i)
	{
		if (input[i] == '\0')
		{
			break;
		}
		res ^= input[i] << ((i % chars_per_cell)*8);
	}
	return res;
}


#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

#define LOG_HIT_OFFSET     7 

#define LOG_HIT_SHOTS      0
#define LOG_HIT_HITS       1
#define LOG_HIT_KILLS      2
#define LOG_HIT_HEADSHOTS  3
#define LOG_HIT_TEAMKILLS  4
#define LOG_HIT_DAMAGE     5
#define LOG_HIT_DEATHS     6
#define LOG_HIT_GENERIC    7
#define LOG_HIT_HEAD       8
#define LOG_HIT_CHEST      9
#define LOG_HIT_STOMACH    10
#define LOG_HIT_LEFTARM    11
#define LOG_HIT_RIGHTARM   12
#define LOG_HIT_LEFTLEG    13
#define LOG_HIT_RIGHTLEG   14

CalcInitialHashes()
{
	for (new i = 0; i < MAX_LOG_WEAPONS; ++i)
	{
		g_weapon_hashes[i] = compute_hash(g_weapon_list[i]);
	}
	#if defined TF2
		for (new i = 0; i < SHOOTAUXCOUNT; ++i)
		{
			g_weapon_hashes_shootaux[i] = compute_hash(g_weapon_list_shootaux[i]);
		}
		for (new i = 0; i < HITAUXCOUNT; ++i)
		{
			g_weapon_hashes_hitaux[i] = compute_hash(g_weapon_list_hitaux[i]);
		}
	#endif
}

dump_player_stats(client)
{
	if (IsClientInGame(client) && IsClientConnected(client))
	{
		decl String: player_authid[64];
		if (!GetClientAuthString(client, player_authid, sizeof(player_authid)))
		{
			strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
		}
		new player_team_index = GetClientTeam(client);

		new player_userid = GetClientUserId(client);

		new is_logged;
		for (new i = 0; (i < MAX_LOG_WEAPONS); i++)
		{
			#if defined INS
			if (g_weapon_stats[client][i][LOG_HIT_HITS] > 0)
			{
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"weapon_%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", client, player_userid, player_authid, g_team_list[player_team_index], g_weapon_list[i], g_weapon_stats[client][i][LOG_HIT_SHOTS], g_weapon_stats[client][i][LOG_HIT_HITS], g_weapon_stats[client][i][LOG_HIT_KILLS], g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], g_weapon_stats[client][i][LOG_HIT_DAMAGE], g_weapon_stats[client][i][LOG_HIT_DEATHS]); 
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"weapon_%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", client, player_userid, player_authid, g_team_list[player_team_index], g_weapon_list[i], g_weapon_stats[client][i][LOG_HIT_HEAD], g_weapon_stats[client][i][LOG_HIT_CHEST], g_weapon_stats[client][i][LOG_HIT_STOMACH], g_weapon_stats[client][i][LOG_HIT_LEFTARM], g_weapon_stats[client][i][LOG_HIT_RIGHTARM], g_weapon_stats[client][i][LOG_HIT_LEFTLEG], g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]);
			#else
			if (g_weapon_stats[client][i][LOG_HIT_SHOTS] > 0)
			{
				#if defined GES
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"weapon_%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", client, player_userid, player_authid, g_team_list[player_team_index], g_weapon_loglist[i], g_weapon_stats[client][i][LOG_HIT_SHOTS], g_weapon_stats[client][i][LOG_HIT_HITS], g_weapon_stats[client][i][LOG_HIT_KILLS], g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], g_weapon_stats[client][i][LOG_HIT_DAMAGE], g_weapon_stats[client][i][LOG_HIT_DEATHS]); 
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"weapon_%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", client, player_userid, player_authid, g_team_list[player_team_index], g_weapon_loglist[i], g_weapon_stats[client][i][LOG_HIT_HEAD], g_weapon_stats[client][i][LOG_HIT_CHEST], g_weapon_stats[client][i][LOG_HIT_STOMACH], g_weapon_stats[client][i][LOG_HIT_LEFTARM], g_weapon_stats[client][i][LOG_HIT_RIGHTARM], g_weapon_stats[client][i][LOG_HIT_LEFTLEG], g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]); 
				#else
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", client, player_userid, player_authid, g_team_list[player_team_index], g_weapon_list[i], g_weapon_stats[client][i][LOG_HIT_SHOTS], g_weapon_stats[client][i][LOG_HIT_HITS], g_weapon_stats[client][i][LOG_HIT_KILLS], g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], g_weapon_stats[client][i][LOG_HIT_DAMAGE], g_weapon_stats[client][i][LOG_HIT_DEATHS]); 
				#if ! defined TF2
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", client, player_userid, player_authid, g_team_list[player_team_index], g_weapon_list[i], g_weapon_stats[client][i][LOG_HIT_HEAD], g_weapon_stats[client][i][LOG_HIT_CHEST], g_weapon_stats[client][i][LOG_HIT_STOMACH], g_weapon_stats[client][i][LOG_HIT_LEFTARM], g_weapon_stats[client][i][LOG_HIT_RIGHTARM], g_weapon_stats[client][i][LOG_HIT_LEFTLEG], g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]);
				#endif
				#endif
			#endif
				is_logged++;
			}
		}
		if (is_logged > 0)
		{
			reset_player_stats(client);
		}
	}
}

reset_player_stats(client)
{
	for (new i = 0; (i < MAX_LOG_WEAPONS); i++)
	{
		g_weapon_stats[client][i][LOG_HIT_SHOTS]     = 0;
		g_weapon_stats[client][i][LOG_HIT_HITS]      = 0;
		g_weapon_stats[client][i][LOG_HIT_KILLS]     = 0;
		g_weapon_stats[client][i][LOG_HIT_HEADSHOTS] = 0;
		g_weapon_stats[client][i][LOG_HIT_TEAMKILLS] = 0;
		g_weapon_stats[client][i][LOG_HIT_DAMAGE]    = 0;
		g_weapon_stats[client][i][LOG_HIT_DEATHS]    = 0;
		#if ! defined TF2
		g_weapon_stats[client][i][LOG_HIT_GENERIC]   = 0;
		g_weapon_stats[client][i][LOG_HIT_HEAD]      = 0;
		g_weapon_stats[client][i][LOG_HIT_CHEST]     = 0;
		g_weapon_stats[client][i][LOG_HIT_STOMACH]   = 0;
		g_weapon_stats[client][i][LOG_HIT_LEFTARM]   = 0;
		g_weapon_stats[client][i][LOG_HIT_RIGHTARM]  = 0;
		g_weapon_stats[client][i][LOG_HIT_LEFTLEG]   = 0;
		g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]  = 0;
		#endif
	}
}

stock get_weapon_index(const String: weapon_name[], tf2aux = 0)
{
	new hash = compute_hash(weapon_name);
	new loop_break = 0;
	new index = 0;
	while ((loop_break == 0) && (index < MAX_LOG_WEAPONS))
	{
		if (g_weapon_hashes[index] == hash)
		{
			loop_break++;
		}
		index++;
	}
	
	if (loop_break == 0)
	{
		#if defined TF2
			switch (tf2aux)
			{
				case SHOOT:
				{
					loop_break = 0;
					index = 0;
					while ((loop_break == 0) && (index < SHOOTAUXCOUNT))
					{
						if (g_weapon_hashes_shootaux[index] == hash)
						{
							loop_break++;
						}
						index++;
					}
					if (loop_break == 0)
					{
						return -1;
					}
					return index - 1;
				}
				case HIT:
				{
					loop_break = 0;
					index = 0;
					while ((loop_break == 0) && (index < HITAUXCOUNT))
					{
						if (g_weapon_hashes_hitaux[index] == hash)
						{
							loop_break++;
						}
						index++;
					}
					if (loop_break == 0)
					{
						return -1;
					}
					return index - 1;
				}
			}
		#endif
		return -1;
	}

	return index - 1;
}


WstatsDumpAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		dump_player_stats(i);
	}
}

public OnClientDisconnect(client)
{
	dump_player_stats(client);
	reset_player_stats(client);
}