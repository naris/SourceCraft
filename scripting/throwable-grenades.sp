#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Just another damn Grenade plugin-mod",
	author = "Assyrian/Nergal, thanks to CrancK and ^Pb | chicken aka solly :P",
	description = "Brings back Original TF Grenades into TF2.",
	version = PLUGIN_VERSION,
	url = "www.PwndorasBox.net"
};

//convar handles
new Handle:PluginEnabled;
new Handle:AllowBlu;
new Handle:AllowRed;
new Handle:GrenadeFromSpencer;
new Handle:FragDamage;
new Handle:FragsMax;
new Handle:AmountSpawn;
new Handle:GrenadeRadius;

new Handle:HudMessage;

//grenade flags
#define GRENFLAG_GRENPRIMED		(1 << 0)
#define GRENFLAG_GRENHOLDING		(1 << 1)
new GrenFlags[MAXPLAYERS+1];

//defines
#define GrenadeRingModel	"sprites/laser.vmt"
#define MDL_FRAG		"models/weapons/nades/duke1/w_grenade_frag.mdl"

//sounds
#define SND_THROWNADE		"weapons/grenade_throw.wav"
#define SND_NADE_FRAG		"weapons/explode"
#define SND_PRIMENADE		"grenade/prime_grenade.mp3"

new String:GrenadeSoundTimers[][] = { //PROPS TO FLAMIN' SARGE
	"grenade/default.mp3",
	"grenade/detpack_timer1.mp3",
	"grenade/detpack_timer2.mp3",
	"grenade/Elmos.mp3",
	"grenade/sprutimer.mp3",
	"grenade/tangtimer.mp3",
	"grenade/tf2_default.mp3"
};

//ints
new GrenadePrimary[MAXPLAYERS+1][2]; //(2 = Current amount, Max amount)
new LaserRingModel;
new g_NadeId;
new GrenadeCount = 0;

//non-cvar handles?
new Handle:NadeTimers[MAXPLAYERS+1][6];
new Handle:HudTimer[MAXPLAYERS+1];
new Handle:DispenserTimer[MAXPLAYERS+1];
new Handle:SoundCookie;

//floats
new Float:gHoldingArea[3]; //Holding area Origin in client/player
new Float:GrenadeSpeed = 900.0;

//strings
new String:GrenadeName[256]; //Grenade name obviously
new String:GrenadeSkin[16];

//BOOLS
new bool:g_bThrown[2048];
new bool:g_bPlayerIsDead[MAXPLAYERS+1];

public OnPluginStart() 
{
	PluginEnabled = CreateConVar("sm_tf2nades_enabled", "1", "Enable Grenades plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AllowBlu = CreateConVar("sm_tf2nades_blu", "0", "(Dis)Allow grenades for BLU team", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AllowRed = CreateConVar("sm_tf2nades_red", "1", "(Dis)Allow grenades for RED team", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GrenadeFromSpencer = CreateConVar("sm_tf2nades_from_dispenser", "1", "allow getting grenades from dispensers", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//NoNadeSpam = CreateConVar("sm_tf2nades_OnlyOneGrenade", "0", "if enabled, players can only throw ONE grenade at a time and can't throw another until the original has exploded.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	FragDamage = CreateConVar("sm_tf2nades_damage", "145", "how much damage grenades will do", FCVAR_PLUGIN, true, 1.0, true, 1000.0);
	FragsMax = CreateConVar("sm_tf2nades_frags_max", "5", "max amount of frags players can have", FCVAR_PLUGIN, true, 1.0, true, 999.0);
	AmountSpawn = CreateConVar("sm_tf2nades_frags_spawn", "5", "how many grenades player will spawn with, must be equal to or under sm_tf2nades_frags_max cvar", FCVAR_PLUGIN, true, 1.0, true, 999.0);
	GrenadeRadius = CreateConVar("sm_tf2nades_grenaderadius", "256", "radius of the grenade damage", FCVAR_PLUGIN, true, 1.0, true, 1000.0);

	SoundCookie = RegClientCookie("tf2nades_timersounds", "player's selected grenade timer sound", CookieAccess_Protected);

	RegConsoleCmd("sm_grenadetimers", Command_SetPlayerNadeTimerSound, "menu that let's player customize their grenade timer sounds");
	//RegConsoleCmd("+nade1", Command_Nade1);
	//RegConsoleCmd("-nade1", Command_UnNade1);

	//RegConsoleCmd("+nade2", Command_Nade2);
	//RegConsoleCmd("-nade2", Command_UnNade2);

	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_Resupply);
	/*HookEvent("player_changeclass", ChangeClass); will use when adding more than one grenade
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_restart_round", MainEvents);
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);*/

	HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput_OnPlayerTouch);

	HudMessage = CreateHudSynchronizer();

	for (new c = 0; c < 3; c++)
	{
		gHoldingArea[c] = -10000.0; //DON'T FUCKING TOUCH THIS
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
}
public OnClientPutInServer(client)
{
	if (IsValidClient(client) && GetConVarBool(PluginEnabled))
	{
		GrenadePrimary[client][0] = 0; //(4 = Current amount, Max amount, Damage, Grenade Radii)
		GrenadePrimary[client][1] = GetConVarInt(FragsMax); //max
		HudTimer[client] = CreateTimer(0.3, Timer_GrenadeHud, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		DispenserTimer[client] = CreateTimer(0.5, Timer_DispenserRefillNades, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		GrenFlags[client] = 0;
		new String:check[64];
		GetClientCookie(client, SoundCookie, check, sizeof(check));
		if (!StrContains(check, "grenades/", false)) SetSoundSetting(client, GrenadeSoundTimers[0]);
	}
}
public OnClientDisconnect(client)
{
	for (new i = 0; i < 2; i++)
	{
		GrenadePrimary[client][i] = 0;
	}
	if (HudTimer[client] != INVALID_HANDLE) ClearTimer(HudTimer[client]);
	if (DispenserTimer[client] != INVALID_HANDLE) ClearTimer(DispenserTimer[client]);
	GrenFlags[client] = 0;
}
public Action:Timer_GrenadeHud(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && GetConVarBool(PluginEnabled)) UpdateGrenHUD(client);
	return Plugin_Continue;
}
public Action:Timer_DispenserRefillNades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && GetConVarBool(PluginEnabled) && GetConVarBool(GrenadeFromSpencer))
	{
		if (IsNearSpencer(client))
		{
			new GrenadeProbability = GetRandomInt(0, 100);
			if (GrenadeProbability >= 70) GrenadePrimary[client][0] += 1;

			if (GrenadePrimary[client][0] > GrenadePrimary[client][1])
				GrenadePrimary[client][0] = GrenadePrimary[client][1];
		}
	}
	return Plugin_Continue;
}
public OnMapStart()
{
	decl String:s[PLATFORM_MAX_PATH];
	// precache models
	PrecacheModel(MDL_FRAG, true);
	LaserRingModel = PrecacheModel(GrenadeRingModel, true);

	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_frag.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_frag.mdl");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_frag.phy");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_frag.sw.vtx");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_frag.vvd");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_frag.dx90.vtx");

	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_frag_blu.vmt");
	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_frag_blu.vtf");
	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_frag_red.vmt");
	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_frag_red.vtf");

	//precache sounds heer!
	PrecacheSound(SND_THROWNADE, true);
	for (new f = 0; f < sizeof(GrenadeSoundTimers); f++)
	{
		Format(s, PLATFORM_MAX_PATH, "%s", GrenadeSoundTimers[f]);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);
	}
	for (new e = 1; e <= 3; e++)
	{
		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", SND_NADE_FRAG, e);
		PrecacheSound(s, true);
	}
	PrecacheSound(SND_PRIMENADE, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", SND_PRIMENADE);
	AddFileToDownloadsTable(s);

	for (new i = 1; i <= MaxClients; i++)
		GrenFlags[i] = 0;
}
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(PluginEnabled)) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && IsClientInGame(client))
	{
		g_bPlayerIsDead[client] = false;
		GrenadePrimary[client][0] = GetConVarInt(AmountSpawn);
	}
	return Plugin_Continue;
}
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(PluginEnabled)) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && IsClientInGame(client))
	{
		if ((GrenFlags[client] & GRENFLAG_GRENHOLDING) && !g_bThrown[EntRefToEntIndex(g_NadeId)])
		{
			g_bPlayerIsDead[client] = true;
			ThrowNade(GetClientUserId(client), g_NadeId);
		}
	}
	new String:weapon[64];
	GetEventString(event, "weapon_logclassname", weapon, sizeof(weapon));
	if(strcmp(weapon[0], "env_explosion", false) == 0)
	{
		SetEventString(event, "weapon_logclassname", "Grenade");
		SetEventString(event, "weapon", "taunt_soldier");
		SetEventInt(event, "customkill", 0);
	}
	return Plugin_Continue;
}
new bool:l_bPressed[MAXPLAYERS+1] = { false, ... };
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (!GetConVarBool(PluginEnabled)) return Plugin_Continue;

	if (!IsPlayerAlive(client) || !IsValidClient(client)) return Plugin_Continue;

	if (!GetConVarBool(AllowBlu) && (GetClientTeam(client) == 3)) return Plugin_Continue;
	if (!GetConVarBool(AllowRed) && (GetClientTeam(client) == 2)) return Plugin_Continue;

	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond & 16 || cond & 128 || cond & 16384) return Plugin_Continue;

	if (!l_bPressed[client] && (buttons & IN_ATTACK3))
	{
		l_bPressed[client] = true;
		PrimeGrenade(GetClientUserId(client));
	}
	if (l_bPressed[client] && !(buttons & IN_ATTACK3))
	{
		l_bPressed[client] = false;
		if (!(GrenFlags[client] & GRENFLAG_GRENPRIMED)) return Plugin_Continue;
		ThrowNade(GetClientUserId(client), g_NadeId);
	}
	return Plugin_Continue;
}
public PrimeGrenade(any:userid/*, */)
{
	new client = GetClientOfUserId(userid);
	if (!IsPlayerAlive(client) || !IsValidClient(client)) return;

	if ((GrenFlags[client] & GRENFLAG_GRENPRIMED) || (GrenFlags[client] & GRENFLAG_GRENHOLDING)) return;

	if (GrenadePrimary[client][0] > 0) GrenadePrimary[client][0] -= 1; //we primed a grenade, so we have 1 less saved
	else
	{
		new ZeroNadeMSG = GetRandomInt(0, 5);
		switch (ZeroNadeMSG)
		{
			case 0: PrintToChat(client, "Hey Rambo, you're out of grenades...");
			case 1: PrintToChat(client, "Bruce Willis here needs more grenades");
			case 2: PrintToChat(client, "Hey Neo, Why don't you spawn() more grenades?..");
			case 3: PrintToChat(client, "Schwarzenegger over here thinks he has infinite grenades...");
			case 4: PrintToChat(client, "You're out of combustible lemons");
			case 5: PrintToChat(client, "Call of Duty simulator is temporarily down, please acquire more grenades to continue");
		}
		return;
	}
	GrenFlags[client] |= GRENFLAG_GRENPRIMED; //set flag that grenade is primed + being held
	GrenFlags[client] |= GRENFLAG_GRENHOLDING;

	new nadeid = SpawnGrenade(client); //create the actual grenade
	g_NadeId = EntIndexToEntRef(nadeid); //convert index to a ref and apply it on a global var

	new String:lol[PLATFORM_MAX_PATH];
	if (IsValidClient(client) && AreClientCookiesCached(client)) GetClientCookie(client, SoundCookie, lol, sizeof(lol));
	EmitSoundToAll(SND_PRIMENADE, client); //let nearby players know that player has primed a nade.
	EmitSoundToClient(client, SND_PRIMENADE);
	EmitSoundToClient(client, lol); //emit custom grenade timer sound for personalizing client :3

	new Handle:GrenadeDataPack; //This datapack importante, it allows us to remember which nade should explode first or whatev
	if (GrenadeCount == 6) GrenadeCount = 0;
	NadeTimers[client][GrenadeCount] = CreateDataTimer(3.8, NadeExplode, GrenadeDataPack, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(GrenadeDataPack, g_NadeId);
	WritePackCell(GrenadeDataPack, GetClientUserId(client));
	GrenadeCount++;
}
public ThrowNade(userid, NadeId)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	//new TFClassType:class = TF2_GetPlayerClass(client);
	if (IsValidEdict(NadeId))
	{
		GrenFlags[client] &= ~GRENFLAG_GRENHOLDING;
		GrenFlags[client] &= ~GRENFLAG_GRENPRIMED;
		g_bThrown[EntRefToEntIndex(NadeId)] = true;

		new team = GetClientTeam(client), color[4], rand[] = {30, 50, 90, 128, 180, 255};
		color[0] = rand[GetRandomInt(0, sizeof(rand)-1)];
		color[1] = rand[GetRandomInt(0, sizeof(rand)-1)];
		color[2] = rand[GetRandomInt(0, sizeof(rand)-1)];
		color[3] = 255;
		switch (team)
		{
			case TFTeam_Red: AttachParticle(NadeId, "scorchshot_trail_crit_red", 0.0, 4.0);
			case TFTeam_Blue: AttachParticle(NadeId, "scorchshot_trail_crit_blue", 0.0, 4.0);
		}

		Format(GrenadeSkin, sizeof(GrenadeSkin), "%d", GetClientTeam(client)-2);
		DispatchKeyValue(NadeId, "skin", GrenadeSkin);

		// get position and angles
		new Float:startpt[3], Float:angle[3], Float:speed[3];
		GetClientEyePosition(client, startpt);

		angle[0] = GetRandomFloat(-180.0, 180.0);
		angle[1] = GetRandomFloat(-180.0, 180.0);
		angle[2] = GetRandomFloat(-180.0, 180.0);

		GetClientEyePosition(client, startpt);
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);

		if (g_bPlayerIsDead[client])
		{
			new Float:deadangle[3] = {0.0, 0.0, 200.0}; //IF player is dead, the grenade should be thrown straight up.
			TeleportEntity(NadeId, startpt, deadangle, NULL_VECTOR);
		}
		else
		{
			speed[2] += 0.2;
			ScaleVector(speed, GrenadeSpeed);
			//speed[0] *= GrenadeSpeed, speed[1] *= GrenadeSpeed, speed[2] *= GrenadeSpeed;
			TeleportEntity(NadeId, startpt, angle, speed);
		}
		//if (GetConVarFloat(cvDifGrav) != 1.0) SetEntityGravity(NadeId, GetConVarFloat(cvDifGrav));
		//SDKHook(NadeId, SDKHook_Touch, Bouncey);
		EmitSoundToAll(SND_THROWNADE, client);
		ShowTrail(NadeId, color); //adds a sexy team colored trail to alert players of INCOMING.
	}
}
public ShowTrail(nade, color[4])
{
	TE_SetupBeamFollow(nade, LaserRingModel, 0, Float:2.0, Float:30.0, Float:30.0, 5, color);
	TE_SendToAll();
}
public Action:NadeExplode(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new grenade = ReadPackCell(pack);
	new clientID = ReadPackCell(pack);
	new client = GetClientOfUserId(clientID);
	if (IsValidClient(client) && IsValidEdict(grenade)) ExplodeNade(clientID, grenade);
	return Plugin_Continue;
}
public ExplodeNade(userid, NadeId)
{
	new client = GetClientOfUserId(userid);
	if (IsValidEdict(NadeId) && IsValidClient(client))
	{
		if ((GrenFlags[client] & GRENFLAG_GRENHOLDING) && !g_bThrown[EntRefToEntIndex(NadeId)])
		{
			ThrowNade(client, NadeId); //if player is holding a nade and hasn't thrown it yet, force them to throw it before splodey
		}
		g_bThrown[EntRefToEntIndex(NadeId)] = false;

		new Float:center[3];
		new String:sound[PLATFORM_MAX_PATH];
		new damage = GetConVarInt(FragDamage); //Get damage
		GetEntPropVector(NadeId, Prop_Send, "m_vecOrigin", center); //get nades origin vecs
		MakeParticles(NadeId, "ExplosionCore_MidAir", NULL_VECTOR, 2.0); //make sexy visuals
		Format(sound, PLATFORM_MAX_PATH, "%s%i.wav", SND_NADE_FRAG, GetRandomInt(1, 3)); //play boom sounds
		EmitSoundToAll(sound, 0, SNDCHAN_AUTO, SNDLEVEL_TRAIN, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
		CreateExplosion(client, center, damage); //use env_explosion to deliver damage and radius; alot cheaper than using sdkhooks and making particles with the added benefit that it obeys TF2 attributes like explosives resistance.
//TF_WEAPON_GRENADE_NORMAL
		CreateTimer(0.0, RemoveEnt, NadeId); //safely remove nade
	}
}
public Action:RemoveEnt(Handle:timer, any:entid)
{
	new ent = EntRefToEntIndex(entid);
	if (ent > 0 && IsValidEdict(ent)) AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}
public CreateExplosion(client, Float:pos[3], dmg)
{
	new radius = GetConVarInt(GrenadeRadius);
        new String:weapon[32];
	new splodey = CreateEntityByName("env_explosion");
	if (IsValidEdict(splodey))
	{
		DispatchKeyValue(splodey, "spawnflags", "4");
		DispatchKeyValueFloat(splodey, "DamageForce", 1.0);
		SetEntProp(splodey, Prop_Data, "m_iMagnitude", dmg, 0); 
		SetEntProp(splodey, Prop_Data, "m_iRadiusOverride", radius, 2);
		SetEntPropEnt(splodey, Prop_Data, "m_hOwnerEntity", client); //Set the owner of the explosion
		
		if (!StrEqual(weapon, ""))
		{
			//PrintToChat(victim, "weaponname = %s", weapon);
			DispatchKeyValue(splodey, "classname", weapon);
		}
		DispatchSpawn(splodey);
		
		SetVariantInt(GetClientTeam(client));
		AcceptEntityInput(splodey, "TeamNum", -1, -1, 0);
		
		SetVariantInt(GetClientTeam(client));
		AcceptEntityInput(splodey, "SetTeam", -1, -1, 0);
		
		TeleportEntity(splodey, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(splodey, "Explode", -1, -1, 0);
		CreateTimer(1.0, RemoveEnt, EntIndexToEntRef(splodey));
	}
}
public UpdateGrenHUD(client)
{
	if (!IsClientObserver(client))
	{
		SetHudTextParams(0.15, 0.95, 1.0, 100, 85, 106, 255);
		ShowSyncHudText(client, HudMessage, "Grenades: %d", GrenadePrimary[client][0]);
	}
	if (IsClientObserver(client) || !IsPlayerAlive(client))
	{
		new spec = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (IsValidClient(spec) && IsPlayerAlive(spec) && spec != client)
		{
			SetHudTextParams(0.15, 0.95, 1.0, 100, 85, 106, 255);
			ShowSyncHudText(client, HudMessage, "Player's Grenades: %d", GrenadePrimary[spec][0]);
		}
	}
}
public EntityOutput_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
	if (GetConVarBool(PluginEnabled))
	{
		if (IsValidEdict(caller))
		{
			new String:classname[128];
			GetEdictClassname(caller, classname, sizeof(classname));
			if (StrEqual(classname, "item_ammopack_full"))
			{
				if (IsValidEdict(activator))
				{
					if (!GetConVarBool(AllowBlu) && (GetClientTeam(activator) == 3)) return;
					if (!GetConVarBool(AllowRed) && (GetClientTeam(activator) == 2)) return;

					GrenadePrimary[activator][0] += 2;
					if (GrenadePrimary[activator][0] > GrenadePrimary[activator][1])
						GrenadePrimary[activator][0] = GrenadePrimary[activator][1];
				}
			}
			else if (StrEqual(classname, "item_ammopack_medium"))
			{
				if (IsValidEdict(activator))
				{
					if (!GetConVarBool(AllowBlu) && (GetClientTeam(activator) == 3)) return;
					if (!GetConVarBool(AllowRed) && (GetClientTeam(activator) == 2)) return;

					GrenadePrimary[activator][0] += GetRandomInt(1, 2);
					if (GrenadePrimary[activator][0] > GrenadePrimary[activator][1])
						GrenadePrimary[activator][0] = GrenadePrimary[activator][1];
				}
			}
			else if (StrEqual(classname, "item_ammopack_small"))
			{
				if (IsValidEdict(activator))
				{
					if (!GetConVarBool(AllowBlu) && (GetClientTeam(activator) == 3)) return;
					if (!GetConVarBool(AllowRed) && (GetClientTeam(activator) == 2)) return;

					GrenadePrimary[activator][0] += 1;
					if (GrenadePrimary[activator][0] > GrenadePrimary[activator][1])
						GrenadePrimary[activator][0] = GrenadePrimary[activator][1];
				}
			}
		}
	}
	return;
}
public Action:Event_Resupply(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(PluginEnabled)) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (client && IsClientInGame(client))
	{
		if (!GetConVarBool(AllowBlu) && GetClientTeam(client) == 3) return Plugin_Continue;
		if (!GetConVarBool(AllowRed) && GetClientTeam(client) == 2) return Plugin_Continue;

		GrenadePrimary[client][0] = GrenadePrimary[client][1];
		if (GrenadePrimary[client][0] > GrenadePrimary[client][1])
			GrenadePrimary[client][0] = GrenadePrimary[client][1];
	}
	return Plugin_Continue;
}
SetSoundSetting(client, String:sound[])
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	decl String:sndpick[64];
	strcopy(sndpick, sizeof(sndpick), sound);
	SetClientCookie(client, SoundCookie, sndpick);
}
/*
new myArray[8][16][32];
sizeof(myArray) //returns 8
sizeof(myArray[]) //returns 16
sizeof(myArray[][]) //returns 32
*/
public Action:Command_SetPlayerNadeTimerSound(client, args)
{
	if (IsValidClient(client) && IsClientInGame(client) && GetConVarBool(PluginEnabled))
	{
		new Handle:SNDMenu = CreateMenu(MenuHandler_SetPlayerNadeTimerSound);
		SetMenuTitle(SNDMenu, "TF2Nades: Select your Grenade Timer sound");
		for (new i = 0; i < sizeof(GrenadeSoundTimers); i++) //multidimensional array
		{
			AddMenuItem(SNDMenu, "sound", GrenadeSoundTimers[i]);
		}
		SetMenuExitBackButton(SNDMenu, true);
		DisplayMenu(SNDMenu, client, MENU_TIME_FOREVER);
	}
}
public MenuHandler_SetPlayerNadeTimerSound(Handle:menu, MenuAction:action, client, param2)
{
	decl String:sndslct[64];
	GetMenuItem(menu, param2, sndslct, sizeof(sndslct));
	if (action == MenuAction_Select)
        {
                param2++;
		SetSoundSetting(client, GrenadeSoundTimers[param2-1]);
		ReplyToCommand(client, "[TF2Nades] Your timer sound is set to %s", GrenadeSoundTimers[param2-1]);
	}
	else if (action == MenuAction_End)
        {
		CloseHandle(menu);
	}
}
////////////////////////////////////////////////////// S T O C K S ///////////////////////////////////////////////////////////////
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients) return false;
	if (!IsClientInGame(iClient)) return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient))) return false;
	return true;
}
stock GetHealingTarget(client)
{
	new String:s[64];
	new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (medigun <= MaxClients || !IsValidEdict(medigun)) return -1;
	GetEdictClassname(medigun, s, sizeof(s));
	if (strcmp(s, "tf_weapon_medigun", false) == 0)
	{
		if (GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}
	return -1;
}
stock bool:IsNearSpencer(client)
{
	new bool:dispenserheal, medics = 0;
	new healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
	if (healers > 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && GetHealingTarget(i) == client)
				medics++;
		}
	}
	dispenserheal = (healers > medics) ? true : false;
	return dispenserheal;
}
stock ClearTimer(&Handle:Timer)
{
	if (Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
}
stock MakeParticles(entity, String:particlename[], Float:addPos[3]=NULL_VECTOR, Float:time)
{
	new mparticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(mparticle))
	{
		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		TeleportEntity(mparticle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(mparticle, "effect_name", particlename);
		ActivateEntity(mparticle);
		AcceptEntityInput(mparticle, "start");
		CreateTimer(time, RemoveEnt, EntIndexToEntRef(mparticle));
	}
	else LogError("************ShowParticle: could not create info_particle_system************");
}
stock AttachParticle(ent, String:particleType[], Float:offset = 0.0, Float:killtime = 0.0, bool:battach = true)
{
	new particle = CreateEntityByName("info_particle_system");
	decl String:tName[128];
	decl Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2] += offset;
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	if (battach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(killtime, RemoveEnt, EntIndexToEntRef(particle));
	return particle;
}
stock SpawnGrenade(client)
{
	new Nade = CreateEntityByName("prop_physics_override");
	if (IsValidEdict(Nade) && IsValidEntity(Nade))
	{
		/*GetClientEyeAngles(iClient, angles);
		GetAngleVectors(angles, vectors, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vectors, (1000.0 + (250.0 * 0.4)));
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", velocity);
		AddVectors(vectors, velocity, vectors);
		SetEntPropVector(Prop, Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropFloat(Prop, Prop_Send, "m_flElasticity", 0.2);
		TeleportEntity(Prop, position, angles, vectors);*/

		SetEntPropEnt(Nade, Prop_Data, "m_hOwnerEntity", client);
		SetEntityModel(Nade, MDL_FRAG);
		SetEntityMoveType(Nade, MOVETYPE_FLYGRAVITY);
                SetEntityGravity(Nade, 300.0);
		SetEntProp(Nade, Prop_Send, "m_CollisionGroup", 2);
		SetEntProp(Nade, Prop_Send, "m_usSolidFlags", 13);
		//SetEntPropFloat(Nade, Prop_Send, "m_flElasticity", 0.2);
	        SetEntPropFloat(Nade, Prop_Data, "m_flFriction", 3.5);
		SetEntPropFloat(Nade, Prop_Data, "m_massScale", 100.0);	

		DispatchSpawn(Nade);
		Format(GrenadeName, sizeof(GrenadeName), "frag_grenade");
		DispatchKeyValue(Nade, "targetname", GrenadeName);
		AcceptEntityInput(Nade, "DisableDamageForces");
		AcceptEntityInput(Nade, "DisableFloating");
		TeleportEntity(Nade, gHoldingArea, NULL_VECTOR, NULL_VECTOR);
	}
	return Nade;
}
