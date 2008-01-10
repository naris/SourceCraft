#include <sourcemod>
#include <sdktools>

/*Pointmultiplikatoren*/
#define PM_KILL 1
#define PM_KILL_HELP 1
#define PM_OBJ_DEST 1
#define PM_OBJ_DEST_ASI 1
#define PM_CAP_CP 3
#define PM_CAP_FLAG 3
#define PM_CAP_BLK 2
#define PM_TEAM_WIN 3
/*Pointmultiplikatoren ENDE*/

#define PLUGIN_VERSION "0.0.2"
#define MAX_LINE_WIDTH 60
new String:buffer1[2048];

/*PUNKT ARRAYS*/
new KILL1[64]
new KILL2[64]
new KILL3[64]

new KILLHELP1[64]
new KILLHELP2[64]
new KILLHELP3[64]

new OBJDEST1[64]
new OBJDEST2[64]
new OBJDEST3[64]

new OBJDESTASI1[64]
new OBJDESTASI2[64]
new OBJDESTASI3[64]

new CAPFLAG1[64]
new CAPFLAG2[64]
new CAPFLAG3[64]

new CAPPOINT1[64]
new CAPPOINT2[64]
new CAPPOINT3[64]

new CAPBLOCK1[64]
new CAPBLOCK2[64]
new CAPBLOCK3[64]

new TEAMWIN1[64]
new TEAMWIN2[64]
new TEAMWIN3[64]

new Points[64];
new Points2[64];
new Points3[64];

new Contime[64];
new Contime2[64];
new Contime3[64];
/*PUNKT ARRAYS ENDE*/
new Handle:db;

public Plugin:myinfo = 
{
	name = "TF2 Stats",
	author = "R-Hehl",
	description = "TF2 Player Stats",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};

public OnPluginStart()
{
	CreateConVar("sm_tf2_stats_version", PLUGIN_VERSION, "TF2 Player Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	DatabaseInit();
	RegConsoleCmd("say", Command_Say);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("object_destroyed", Eventobjectdestroyed);
	HookEvent("ctf_flag_captured", Eventctfflagcaptured);
	HookEvent("teamplay_point_captured", Eventteamplaypointcaptured);
	HookEvent("teamplay_capture_blocked", Eventteamplaycaptureblocked);
	HookEvent("teamplay_round_win", Eventteamplayroundwin);
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			KILL1[i]=0
			KILL2[i]=0
			KILL3[i]=0

			KILLHELP1[i]=0
			KILLHELP2[i]=0
			KILLHELP3[i]=0

			OBJDEST1[i]=0
			OBJDEST2[i]=0
			OBJDEST3[i]=0

			OBJDESTASI1[i]=0
			OBJDESTASI2[i]=0
			OBJDESTASI3[i]=0

			CAPFLAG1[i]=0
			CAPFLAG2[i]=0
			CAPFLAG3[i]=0

			CAPPOINT1[i]=0
			CAPPOINT2[i]=0
			CAPPOINT3[i]=0

			CAPBLOCK1[i]=0
			CAPBLOCK2[i]=0
			CAPBLOCK3[i]=0

			TEAMWIN1[i]=0
			TEAMWIN2[i]=0
			TEAMWIN3[i]=0

			Points[i]=0
			Points2[i]=0
			Points3[i]=0

			Contime[i]=0
			Contime2[i]=0
			Contime3[i]=0
			Contime[i] = GetTime();
			Contime2[i] = Contime[i];
		}
	}

public DatabaseInit(){

		new String:error[255]
		db = SQL_DefConnect(error, sizeof(error))
		if (db == INVALID_HANDLE)
		{
			PrintToServer("Failed to connect: %s", error)
		} else {
			PrintToServer("DatabaseInit (CONNECTED)");
		}
		
		new Handle:queryBase = SQL_Query(db, "SELECT * FROM User")
		if (queryBase == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error))
			PrintToServer("Failed to query: %s", error)
		} else {
			CloseHandle(queryBase)
		}
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		PrintToServer("Last Connect SQL Error: %s", error);
	}
}
public OnClientAuthorized(client, const String:auth[])
{
KILL1[client]=0
KILL2[client]=0
KILL3[client]=0

KILLHELP1[client]=0
KILLHELP2[client]=0
KILLHELP3[client]=0

OBJDEST1[client]=0
OBJDEST2[client]=0
OBJDEST3[client]=0

OBJDESTASI1[client]=0
OBJDESTASI2[client]=0
OBJDESTASI3[client]=0

CAPFLAG1[client]=0
CAPFLAG2[client]=0
CAPFLAG3[client]=0

CAPPOINT1[client]=0
CAPPOINT2[client]=0
CAPPOINT3[client]=0

CAPBLOCK1[client]=0
CAPBLOCK2[client]=0
CAPBLOCK3[client]=0

TEAMWIN1[client]=0
TEAMWIN2[client]=0
TEAMWIN3[client]=0

Points[client]=0
Points2[client]=0
Points3[client]=0

Contime[client]=0
Contime2[client]=0
Contime3[client]=0
	
InitializeClient(client);
updateUsertime(client);
Contime[client] = GetTime();
Contime2[client] = Contime[client];
}
public InitializeClient( client )
{
decl String:name[MAX_LINE_WIDTH];
decl String:steamId[MAX_LINE_WIDTH];
decl String:buffer[200];
GetClientName( client, name, sizeof(name) );
ReplaceString(name, sizeof(name), "'", "");
ReplaceString(name, sizeof(name), "<?", "");
ReplaceString(name, sizeof(name), "?>", "");
ReplaceString(name, sizeof(name), "\"", "");
ReplaceString(name, sizeof(name), "<?PHP", "");
ReplaceString(name, sizeof(name), "<?php", "");
GetClientAuthString(client, steamId, sizeof(steamId));
Format(buffer1, sizeof(buffer1), "SELECT NAME FROM User WHERE STEAMID LIKE '%s'", steamId);
new Handle:queryBase = SQL_Query(db, buffer1)
if(!SQL_FetchRow(queryBase))
{
	Format(buffer, sizeof(buffer), "INSERT INTO User (`NAME`,`STEAMID`) VALUES ('%s','%s')", name, steamId)
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}
else
{
	Format(buffer1, sizeof(buffer1), "UPDATE User SET NAME =  '%s' WHERE STEAMID LIKE '%s'", name, steamId);
	if (!SQL_FastQuery(db, buffer1))
{
	new String:error[255]
	SQL_GetError(db, error, sizeof(error))
	PrintToServer("Failed to query (error: %s)", error)
}	
}
}
public OnClientDisconnect(client)
{
	saveUser(client);
	updateUsertime(client);
	}
public saveUser(client){
			Contime[client] = GetTime()
			decl String:steamId[MAX_LINE_WIDTH];
			GetClientAuthString(client, steamId, sizeof(steamId));
			Contime3[client] = Contime[client] - Contime2[client]
			Points3[client] = Points[client] - Points2[client]
			KILL3[client] = KILL1[client] - KILL2[client]

			KILLHELP3[client] = KILLHELP1[client] - KILLHELP2[client]
			OBJDEST3[client] = OBJDEST1[client] - OBJDEST2[client]
			OBJDESTASI3[client] = OBJDESTASI1[client] - OBJDESTASI2[client]
			CAPFLAG3[client] = CAPFLAG1[client] - CAPFLAG2[client]
			CAPPOINT3[client] = CAPPOINT1[client] - CAPPOINT2[client]
			CAPBLOCK3[client] = CAPBLOCK1[client] - CAPBLOCK2[client]
			TEAMWIN3[client] = TEAMWIN1[client] - TEAMWIN2[client]
			
			Format(buffer1, sizeof(buffer1), "UPDATE User SET POINTS = POINTS + %i, PLAYTIME = PLAYTIME + %i, KILLS = KILLS + %i, KILLHELP = KILLHELP + %i, OBJDEST = OBJDEST + %i, OBJDESTASI = OBJDESTASI + %i, CAPCP = CAPCP + %i, CAPFLAG = CAPFLAG + %i, CAPBLK = CAPBLK + %i, TEAMWIN = TEAMWIN + %i WHERE steamId = '%s'",Points3[client] ,Contime3[client] ,KILL3[client] ,KILLHELP3[client] ,OBJDEST3[client] ,OBJDESTASI3[client] ,CAPPOINT3[client] ,CAPFLAG3[client] ,CAPBLOCK3[client] ,TEAMWIN3[client] ,steamId);
			SQL_FastQuery(db, buffer1);
			
			KILLHELP2[client] = KILLHELP1[client]
			OBJDEST2[client] = OBJDEST1[client]
			OBJDESTASI2[client] = OBJDESTASI1[client]
			CAPFLAG2[client] = CAPFLAG1[client]
			CAPPOINT2[client] = CAPPOINT1[client]
			CAPBLOCK2[client] = CAPBLOCK1[client]
			TEAMWIN2[client] = TEAMWIN1[client]
			
			KILL2[client] = KILL1[client]
			Points2[client] = Points[client]
			Contime2[client] = Contime[client]
			updpph(client);
			}
public Action:Command_Say(client, args){
	decl String:text[192], String:command[64];

	new startidx = 0;

	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{		
	text[strlen(text)-1] = '\0';
	startidx = 1;	
	} 	
	if (strcmp(command, "say2", false) == 0)
	startidx += 4;
	if (strcmp(text[startidx], "save_rank", false) == 0)
{
	new String:name[32];
	GetClientName(client, name, 32);
	PrintToChatAll("%s has Saved %i Points",name ,Points[client]);
	saveUser(client)
}
	else if (strcmp(text[startidx], "!Rank", false) == 0)
{
	echo_rank(client)
}
	else if (strcmp(text[startidx], "Rank", false) == 0)
{
	echo_rank(client)
}
	else if (strcmp(text[startidx], "Top10", false) == 0)
{
	echo_top10(client)
}
	else if (strcmp(text[startidx], "Rank2", false) == 0)
{
	new String:name[32];
	GetClientName(client, name, 32);
	PrintToChatAll("%s has", name)
	PrintToChatAll("%i Points", Points[client])
	PrintToChatAll("%i Kills", KILL1[client])
	PrintToChatAll("%i Kill Help", KILLHELP1[client])
	PrintToChatAll("%i OBJECTDEST", OBJDEST1[client])
	PrintToChatAll("%i OBJECTDEST HELP", OBJDESTASI1[client])
	PrintToChatAll("%i CAPFLAG", CAPFLAG1[client])
	PrintToChatAll("%i CAPPOINT", CAPPOINT1[client])
	PrintToChatAll("%i CAPBLOCK", CAPBLOCK1[client])
	PrintToChatAll("%i TEAMWIN", TEAMWIN1[client])
	
	}
	return Plugin_Continue;
}
public updateUsertime(client){
	decl String:steamId[MAX_LINE_WIDTH];
	GetClientAuthString(client, steamId, sizeof(steamId));
	new time = GetTime()
	Format(buffer1, sizeof(buffer1), "UPDATE User SET LASTONTIME = %i WHERE steamId = '%s'",time ,steamId);
	SQL_FastQuery(db, buffer1);
}
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new assister = GetClientOfUserId(GetEventInt(event, "assister"))


	
	if(victim != attacker){
		KILL1[attacker]++;
		Points[attacker]=Points[attacker]+PM_KILL;
		if(assister != 0){
		KILLHELP1[assister]++;
		Points[assister]=Points[assister]+PM_KILL_HELP;
		}
	}
}
public Eventobjectdestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new assister = GetClientOfUserId(GetEventInt(event, "assister"))
	if(victim != attacker){
	OBJDEST1[attacker]++;
	Points[attacker]=Points[attacker]+PM_OBJ_DEST;
	if(assister != 0){
	OBJDESTASI1[assister]++;
	Points[assister]=Points[assister]+PM_OBJ_DEST_ASI;
	}
}
}
public Eventctfflagcaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	new cappingteam = GetEventInt(event, "capping_team")
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			if (GetClientTeam(i)==cappingteam)
			{
			CAPFLAG1[i]++;
			Points[i]=Points[i]+PM_CAP_FLAG;
			}
		}
	
}
public Eventteamplaypointcaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team")
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			if (GetClientTeam(i)==team)
			{
			CAPPOINT1[i]++;
			Points[i]=Points[i]+PM_CAP_CP;
			}
		}
	
}
public Eventteamplaycaptureblocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	new blocker = GetEventInt(event, "blocker")
	CAPBLOCK1[blocker]++;
	Points[blocker]=Points[blocker]+PM_CAP_BLK;
}
public Eventteamplayroundwin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team")
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			if (GetClientTeam(i)==team)
			{
			TEAMWIN1[i]++;
			Points[i]=Points[i]+PM_TEAM_WIN;
			}
		}
}
public updpph(client){
		new pnts,plytime,pps,pph
		decl String:steamId[MAX_LINE_WIDTH];
		GetClientAuthString(client, steamId, sizeof(steamId));
		Format(buffer1, sizeof(buffer1), "SELECT POINTS,PLAYTIME FROM `User` WHERE `STEAMID` LIKE '%s'", steamId);
		new Handle:queryBase = SQL_Query(db, buffer1)
		while (SQL_FetchRow(queryBase))
	{
		pnts = SQL_FetchInt(queryBase, 0);
		plytime = SQL_FetchInt(queryBase, 1);
		
	}
		pph = pnts * 3600
		pps = plytime ? pph/plytime : 0
		Format(buffer1, sizeof(buffer1), "UPDATE User SET PPH = %i WHERE steamId = '%s'",pps ,steamId);
		SQL_FastQuery(db, buffer1);
	
	}
public echo_rank(client){
		saveUser(client)
		new id,plytime,plytimem,pph
		decl String:steamId[MAX_LINE_WIDTH];
		GetClientAuthString(client, steamId, sizeof(steamId));
		Format(buffer1, sizeof(buffer1), "SELECT POINTS,PLAYTIME,PPH FROM `User` WHERE `STEAMID` LIKE '%s'", steamId);
		new Handle:queryBase = SQL_Query(db, buffer1)
		while (SQL_FetchRow(queryBase))
	{
		id = SQL_FetchInt(queryBase, 0);
		plytime = SQL_FetchInt(queryBase, 1);
		pph = SQL_FetchInt(queryBase, 2);
	}
		plytimem = plytime/60
		PrintToChat(client,"Points: %i",id);
		PrintToChat(client,"Playtime Min: %i",plytimem);
		new rank
		Format(buffer1, sizeof(buffer1), "SELECT ID FROM `User` WHERE `PPH` >=%i", pph);
		new Handle:queryBase2 = SQL_Query(db, buffer1)
		rank = SQL_GetRowCount(queryBase2)
		PrintToChat(client,"Rank: %i",rank);
		}
public echo_top10(client){
		saveUser(client)
		new points
		decl String:name[MAX_LINE_WIDTH];
		decl String:steamId[MAX_LINE_WIDTH];
		GetClientAuthString(client, steamId, sizeof(steamId));
		Format(buffer1, sizeof(buffer1), "SELECT NAME,POINTS FROM `User` ORDER BY PPH DESC LIMIT 0,10");
		new Handle:queryBase = SQL_Query(db, buffer1)
		new place = 1
		while (SQL_FetchRow(queryBase))
	{
		
		SQL_FetchString(queryBase, 0, name, sizeof(name));
		points = SQL_FetchInt(queryBase, 1);
		if(points !=0)
		{
		PrintToChat(client,"%i. %s Points: %i",place ,name ,points);
		place++
		}
	}
		}
