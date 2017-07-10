/*
 * vim: set ai et ts=4 sw=4 :
quakesounds.sp

Description:
	Plays Quake Sounds

Versions:
	0.4
		* Initial Release
	
	0.5
		* Added support for loading sounds from a configuration file

	0.6
		* Made user preferences persistent
		* Removed some unused code
		
	0.7
		* Cleaned up announcement text
		* Added error handling for missing sould list config file
		* Added teamkiller sounds
		* Added a more flexible kill count system
		* Added numerous control CVAR's
		* Added additional comments and #defines for readability
	
	0.8
		* Added cvar to suppress announcements
		* Made the current choice show in menu
		
	0.9
		* added progressive combo sounds
		* added progressive headshot sounds
		* restructured code
		* switched from play to EmitSound
		
	0.95
		* added DOD:S support
		* fixed announce cvar
		* added better error handling of sounds
		
	0.96
		* Added DOD:S smoke grenades
		* Added some better error handling for DOD:S
		* Fixed the sm_quakesounds_announce cvar....again
	
	1.0
		* Added time to the settings data to allow pruning at a later date
		* Added support for translations
		* Added text display of quake events
		* Added a cvar for default sound preference for new users
		* added a cvar for default text display preference
		* Moved sound setting cvar's into an array
		* Added individual sound and text information per sound
		
	1.1
		* Added the ability to print the names of those involved in the text
	
	1.2
		* Fixed numerous bugs surrounding the selecting and saving of text preferences
		* Switched MAX_CLIENTS to MAXPLAYERS
	
	1.3
		* Moved individual sound preferences to config file
		
	1.3.1
		* Fixed text for ROUND_PLAY
		* Fixed a bug in the play and text commands when the users sound preferences were not being accounted for
		* Fixed array out of bounds messages in PlayQuakeSounds()
		
	1.4
		* Added the ability to add and remove sound sets
		* Removed cvarMinKills and cvarFemale
		* Added the ability for the kill sounds to have custom kill counts
		
	1.4.1
		* Changed the behavior of disabled sounds
		
	1.4.2
		* Added some additional checks for hl2mp

	1.4.3
		* Added hl2mp weapons
		
	1.5
		* Added support for late loading
		* Added translation for the announce message
		
	1.6
		* Added event sounds framework and a join server sound
		* Changed the behavior of sm_quakesounds_announce
		* Added German Translation courtesy of -<[PAGC]>- Isias
		
	1.7
		* Updated some string declarations
		* Added an exit option
		* Switched from panels to menus
		* Changed menu behavior
		* Added join server sound
		
	1.8
		* Changed name to Quake Sounds
		* Fixed array out of bounds problem
		* Added volume adjustment
		* Moved config file location
		* Made the config file load automatically
		
	1.9
		* Modified by -=|JFH|=- Naris
		* Added support for tf2
		* Added ability to assign seperate sounds to each melee weapon.
		
	1.91
		* Modified by steambob
		* Fixed DOUBLECOMBO,TRIPLECOMBO,.. sound series not reseting after a long time without a kill
		* Fixed array out of bounds error for more than 50 consecutive kills 
		* Number of melee kills producing many-kill melee sounds (e.g. knife3 and knife5) is now reset when player connects and at map end
		* In HL2MP melee weapons can get now different sounds: stunstick is "knife" and crowbar is "fists"
	
	1.92
		* Modified by steambob
		* First blood sound will now not be played  for a suicide with "world"
		* Consecutive kills will now not be reset on a suicide with "world"
		* Removed many double checks from the player_death code
		* Fixed small bug with DOUBLECOMBO,TRIPLECOMBO,.. sound series from 1.91 for mods with "assister"
		* Fixed bug when sounds from consecutive kills would be played on suicidies
		* Added some checks before playing sound and showing text - this could cause problems with bots and playing sounds to specific group 
		
	1.93
		* Modified by -=|JFH|=- Naris
		* Merged steambob's version
		* Close kvQUS OnPluginEnd()
		
	1.94
		* Modified by -=|JFH|=- Naris
		* Merged FeuerSturm's DoD Headshot fix
		
	1.95
		* Modified by -=|JFH|=- Naris
		* Added rocket, critrocket, train and drowned sounds
		* Don't precache sounds until they are actually used
		* Added code to save text preferences in MenuHandlerQuake()

    3.0
		* Modified by -=|JFH|=- Naris
        * Merged Clientprefs cookies from Grrrs Revamped 2.0.7 version
        * Modified to use ResourceManager (if available when compiled)
        * Modified to use gametype.inc
        * Updated TF2 weapons
*/


#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>

#pragma semicolon 1

#define PLUGIN_VERSION "3.0"
#define MAX_FILE_LEN 64
#define SET_NAME_LEN 30
#define DISABLE_CHOICE 3
#define NO_KILLS -1.0
#define MAX_NUM_SETS 5
#define MAX_MELEE 9

#define MAX_CONKILLS 50

#define HEADSHOT 0
#define GRENADE 1
#define ROCKET 2
#define CRITROCKET 3
#define SELFKILL 4
#define TRAINKILL 5
#define DROWNED 6
#define ROUND_PLAY 7
#define MELEE 8
#define KILLS_1 9
#define KILLS_2 10
#define KILLS_3 11
#define KILLS_4 12
#define KILLS_5 13
#define KILLS_6 14
#define KILLS_7 15
#define KILLS_8 16
#define KILLS_9 17
#define KILLS_10 18
#define KILLS_11 19
#define FIRSTBLOOD 20
#define TEAMKILL 21
#define DOUBLECOMBO 22
#define TRIPLECOMBO 23
#define QUADCOMBO 24
#define MONSTERCOMBO 25
#define HEADSHOT3 26
#define HEADSHOT5 27
#define BACKSTAB 28
#define BACKSTAB3 29
#define BACKSTAB5 30
#define KNIFE 31
#define KNIFE3 32
#define KNIFE5 33
#define FISTS 34
#define FISTS3 35
#define FISTS5 36
#define BAT 37
#define BAT3 38
#define BAT5 39
#define WRENCH 40
#define WRENCH3 41
#define WRENCH5 42
#define BOTTLE 43
#define BOTTLE3 44
#define BOTTLE5 45
#define BONESAW 46
#define BONESAW3 47
#define BONESAW5 48
#define SHOVEL 49
#define SHOVEL3 50
#define SHOVEL5 51
#define FIREAXE 52
#define FIREAXE3 53
#define FIREAXE5 54
#define CLUB 55			// snipers machete
#define CLUB3 56
#define CLUB5 57
//#define NUM_SOUNDS 58

//#define NUM_EVENT_SOUNDS 1
#define JOINSERVER 0

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Quake Sounds",
	author = "dalto",
	description = "Quake Sounds Plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

static const String:eventSoundNames[][] = {"join server"};
static const String:soundNames[][] = {"headshot", "grenade", "rocket", "critrocket", "selfkill", "train",
"drowned", "round play", "melee", "killsound 1", "killsound 2", "killsound 3", "killsound 4", "killsound 5",
"killsound 6", "killsound 7", "killsound 8", "killsound 9", "killsound 10", "killsound 11", "first blood",
"teamkill", "double combo", "triple combo", "quad combo", "monster combo", "headshot 3", "headshot 5",
"backstab", "backstab 3", "backstab 5", "knife", "knife 3", "knife 5", "fists", "fists 3", "fists 5",
"bat", "bat 3", "bat 5", "wrench", "wrench 3", "wrench 5","bottle", "bottle 3", "bottle 5",
"bonesaw", "bonesaw 3", "bonesaw 5", "shovel", "shovel 3", "shovel 5",
"fireaxe", "fireaxe 3", "fireaxe 5", "club", "club 3", "club 5"};

// Global Variables
new String:soundsList[MAX_NUM_SETS][sizeof(soundNames)][MAX_FILE_LEN];
new String:eventSoundsList[sizeof(eventSoundNames)][MAX_FILE_LEN];
new String:setNames[MAX_NUM_SETS][SET_NAME_LEN];

new killNumSetting[MAX_CONKILLS];
new settingsArray[sizeof(soundNames)];
new eventSettingsArray[sizeof(eventSoundNames)];

new meleeCount[MAX_MELEE + 1][MAXPLAYERS + 1];

new soundPreference[MAXPLAYERS + 1];
new textPreference[MAXPLAYERS + 1];
new consecutiveKills[MAXPLAYERS + 1];
new Float:lastKillTime[MAXPLAYERS + 1];
new lastKillCount[MAXPLAYERS + 1];
new headShotCount[MAXPLAYERS + 1];
new backStabCount[MAXPLAYERS + 1];

new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:cvarTextDefault = INVALID_HANDLE;
new Handle:cvarSoundDefault = INVALID_HANDLE;
new Handle:cvarVolume = INVALID_HANDLE;
new Handle:cookieTextPref = INVALID_HANDLE;
new Handle:cookieSoundPref = INVALID_HANDLE;

new bool:IsHooked = false;
new bool:lateLoaded;
new totalKills;
new numSets;

// We need to capture if the plugin was late loaded so we can make sure initializations
// are handled properly
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoaded = late;
	return APLRes_Success;
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Get the game/mod type ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected=0, tf2=1, cstrike, csgo, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
    {
        if (GameType == undetected)
        {
            new String:modname[30];
            GetGameFolderName(modname, sizeof(modname));
            if (StrEqual(modname,"tf",false)) 
                GameType=tf2;
            else if (StrEqual(modname,"tf_beta",false)) 
                GameType=tf2;
            else if (StrEqual(modname,"cstrike",false))
                GameType=cstrike;
            else if (StrEqual(modname,"csgo",false))
                GameType=csgo;
            else if (StrEqual(modname,"dod",false)) 
                GameType=dod;
            else if (StrEqual(modname,"hl2mp",false)) 
                GameType=hl2mp;
            else if (StrEqual(modname,"Insurgency",false)) 
                GameType=insurgency;
            else if (StrEqual(modname,"left4dead", false)) 
                GameType=l4d;
            else if (StrEqual(modname,"left4dead2", false)) 
                GameType=l4d2;
            else if (StrEqual(modname,"zps",false)) 
                GameType=zps;
            else
                GameType=other_game;
        }
        return GameType;
    }

    #define GetGameTypeIsCS()   (GetGameType() == cstrike || GameType == csgo)
    #define GameTypeIsCS()      (GameType      == cstrike || GameType == csgo)
#endif

//*****************************************************************
//	------------------------------------------------------------- *
//				*** Manage precaching resources ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
	#define DONT_DOWNLOAD    0
	#define DOWNLOAD         1
	#define ALWAYS_DOWNLOAD  2

	enum State { Unknown=0, Defined, Download, Force, Precached };

	new Handle:cvarDownloadThreshold = INVALID_HANDLE;
	new Handle:cvarSoundThreshold    = INVALID_HANDLE;
	new Handle:cvarSoundLimit        = INVALID_HANDLE;

	new g_iSoundCount                = 0;
	new g_iDownloadCount             = 0;
	new g_iRequiredCount             = 0;
	new g_iPrevDownloadIndex         = 0;
	new g_iDownloadThreshold         = -1;
	new g_iSoundThreshold            = -1;
	new g_iSoundLimit                = -1;

	// Trie to hold precache status of sounds
	new Handle:g_soundTrie = INVALID_HANDLE;

	stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=false)
	{
        new State:value = Unknown;
        if (!GetTrieValue(g_soundTrie, sound, value) || value < Precached)
        {
            if (force || value >= Force || g_iSoundLimit <= 0 ||
                (g_soundTrie ? GetTrieSize(g_soundTrie) : 0) < g_iSoundLimit)
            {
                PrecacheSound(sound, preload);
                SetTrieValue(g_soundTrie, sound, Precached);
            }
            else
                return false;
        }
        return true;
    }

	stock SetupSound(const String:sound[], bool:force=false, download=DOWNLOAD,
	                 bool:precache=false, bool:preload=false)
	{
        new State:value = Unknown;
        new bool:update = !GetTrieValue(g_soundTrie, sound, value);
        if (update || value < Defined)
        {
            g_iSoundCount++;
            value  = Defined;
            update = true;
        }

        if (value < Download && download && g_iDownloadThreshold != 0)
        {
            decl String:file[PLATFORM_MAX_PATH+1];
            Format(file, sizeof(file), "sound/%s", sound);

            if (FileExists(file))
            {
                if (download < 0)
                {
                    if (!strncmp(file, "ambient", 7) ||
                        !strncmp(file, "beams", 5) ||
                        !strncmp(file, "buttons", 7) ||
                        !strncmp(file, "coach", 5) ||
                        !strncmp(file, "combined", 8) ||
                        !strncmp(file, "commentary", 10) ||
                        !strncmp(file, "common", 6) ||
                        !strncmp(file, "doors", 5) ||
                        !strncmp(file, "friends", 7) ||
                        !strncmp(file, "hl1", 3) ||
                        !strncmp(file, "items", 5) ||
                        !strncmp(file, "midi", 4) ||
                        !strncmp(file, "misc", 4) ||
                        !strncmp(file, "music", 5) ||
                        !strncmp(file, "npc", 3) ||
                        !strncmp(file, "physics", 7) ||
                        !strncmp(file, "pl_hoodoo", 9) ||
                        !strncmp(file, "plats", 5) ||
                        !strncmp(file, "player", 6) ||
                        !strncmp(file, "resource", 8) ||
                        !strncmp(file, "replay", 6) ||
                        !strncmp(file, "test", 4) ||
                        !strncmp(file, "ui", 2) ||
                        !strncmp(file, "vehicles", 8) ||
                        !strncmp(file, "vo", 2) ||
                        !strncmp(file, "weapons", 7))
                    {
                        // If the sound starts with one of those directories
                        // assume it came with the game and doesn't need to
                        // be downloaded.
                        download = 0;
                    }
                    else
                        download = 1;
                }

                if (download > 0 &&
                    (download > 1 || g_iDownloadThreshold < 0 ||
                     (g_iSoundCount > g_iPrevDownloadIndex &&
                      g_iDownloadCount < g_iDownloadThreshold + g_iRequiredCount)))
                {
                    AddFileToDownloadsTable(file);

                    update = true;
                    value  = Download;
                    g_iDownloadCount++;

                    if (download > 1)
                        g_iRequiredCount++;

                    if (download <= 1 || g_iSoundCount == g_iPrevDownloadIndex + 1)
                        g_iPrevDownloadIndex = g_iSoundCount;
                }
            }
        }

        if (value < Precached && (precache || (g_iSoundThreshold > 0 &&
                                               g_iSoundCount < g_iSoundThreshold)))
        {
            if (force || g_iSoundLimit <= 0 &&
                (g_soundTrie ? GetTrieSize(g_soundTrie) : 0) < g_iSoundLimit)
            {
                PrecacheSound(sound, preload);

                if (value < Precached)
                {
                    value  = Precached;
                    update = true;
                }
            }
        }
        else if (force && value < Force)
        {
            value  = Force;
            update = true;
        }

        if (update)
            SetTrieValue(g_soundTrie, sound, value);
    }
#endif

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Plugin Start ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public OnPluginStart()
{
    if(GetGameType() == l4d2 || GetGameType() == l4d)
        SetFailState("The Left 4 Dead series is not supported!");

    // Before we do anything else lets make sure that the plugin is not disabled
    cvarEnabled = CreateConVar("sm_quakesounds_enable", "1", "Enables the Quake sounds plugin");
    HookConVarChange(cvarEnabled, EnableChanged);

    LoadTranslations("plugin.quakesounds");

    // Create the remainder of the CVARs
    CreateConVar("sm_quakesounds_version", PLUGIN_VERSION, "Quake Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvarAnnounce = CreateConVar("sm_quakesounds_announce", "1", "Announcement preferences");
    cvarTextDefault = CreateConVar("sm_quakesounds_text", "1", "Default text setting for new users");
    cvarSoundDefault = CreateConVar("sm_quakesounds_sound", "1", "Default sound for new users, 1=Standard, 2=Female, 0=Disabled");
    cvarVolume = CreateConVar("sm_quakesounds_volume", "1.0", "Volume: should be a number between 0.0. and 1.0");

#if !defined _ResourceManager_included
    cvarDownloadThreshold = CreateConVar("sm_quakesounds_download_threshold", "-1", "Number of sounds to download per map start (-1=unlimited).", FCVAR_PLUGIN);
    cvarSoundThreshold = CreateConVar("sm_quakesounds_sound_threshold", "0", "Number of sounds to precache on map start (-1=unlimited).", FCVAR_PLUGIN);
    cvarSoundLimit     = CreateConVar("sm_quakesounds_sound_max", "-1", "Maximum number of sounds to allow (-1=unlimited).", FCVAR_PLUGIN);
#endif

    // Hook events and register commands as needed
    if(GetConVarBool(cvarEnabled))
    {
        HookEvent("player_death", EventPlayerDeath);

        if(GameType == tf2)
        {
            HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
            HookEvent("teamplay_round_active", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
        }
        else
        {
            HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
            if(GameTypeIsCS())
                HookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
            else if(GameType == dod)
            {
                HookEvent("dod_warmup_ends", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
                HookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
                HookEventEx("dod_stats_player_damage", OnPlayerHeadshot, EventHookMode_Post);
            }
        }
        IsHooked = true;
    }
    RegConsoleCmd("quake", MenuQuake);

    // Execute the config file
    AutoExecConfig(true, "sm_quakesounds");

    // Load the sounds
    LoadSounds();

    //initialize QUS cookies
    cookieTextPref = RegClientCookie("Quake Text Pref", "Text setting", CookieAccess_Private);
    cookieSoundPref = RegClientCookie("Quake Sound Pref", "Sound setting", CookieAccess_Private);

    //add to clientpref's built-in !settings menu
    SetCookieMenuItem(QuakePrefSelected, 0, "Quake Sound Prefs");

    // if the plugin was loaded late we have a bunch of initialization that needs to be done
    if(lateLoaded)
    {
        // First we need to do whatever we would have done at RoundStart()
        NewRoundInitialization();

        // Next we need to whatever we would have done as each client authorized
        new textDefault = GetConVarInt(cvarTextDefault);
        new soundDefault = GetConVarInt(cvarSoundDefault) - 1;
        for(new i = 1; i < GetMaxClients(); i++)
        {
            if(IsClientInGame(i))
            {
                textPreference[i] = textDefault;
                soundPreference[i] = soundDefault;
                PrepareClient(i);
            }
        }
    }
}

public OnMapStart()
{
    #if !defined _ResourceManager_included
        g_iDownloadThreshold = GetConVarInt(cvarDownloadThreshold);
        g_iSoundThreshold    = GetConVarInt(cvarSoundThreshold);
        g_iSoundLimit        = GetConVarInt(cvarSoundLimit);

        // Setup trie to keep track of precached sounds
        if (g_soundTrie == INVALID_HANDLE)
            g_soundTrie = CreateTrie();
        else
            ClearTrie(g_soundTrie);
    #endif

	SetupQuakeSounds();
	SetupEventSounds();

	ResetConsecutiveKills();
	ResetMeleeKills();

	if(GameType == hl2mp)
		NewRoundInitialization();
}


public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		PrintToChat(client, "%t", "announce message");

	return Plugin_Stop;
}

// When a new client joins we reset sound preferences
// and let them know how to turn the sounds on and off
public OnClientPutInServer(client)
{
    // Initializations and preferences loading
    textPreference[client] = GetConVarInt(cvarTextDefault);
    soundPreference[client] = GetConVarInt(cvarSoundDefault) - 1;
    PrepareClient(client);

    // Play event sound
    if(eventSettingsArray[JOINSERVER] && !IsFakeClient(client))
    {
        if (PrepareSound(eventSoundsList[JOINSERVER]))
        {
            if (GetGameType() == csgo)
            {
                ClientCommand(client, "playgamesound \"*%s\"", eventSoundsList[JOINSERVER]);
            }
            else
            {
                EmitSoundToClient(client, eventSoundsList[JOINSERVER],
                                  _, _, _, _, GetConVarFloat(cvarVolume));
            }
        }
    }
}

// Handle DoD Headshots
public Action:OnPlayerHeadshot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Hitgroup = GetEventInt(event, "hitgroup");
	new attackerteam = GetClientTeam(attacker);
	new victimteam = GetClientTeam(victim);
	if(attacker < 1 || victim < 1 || !IsClientInGame(attacker) || !IsClientInGame(victim) || attackerteam == victimteam)
	{
		return Plugin_Continue;
	}
	if(Hitgroup == 1 && GetClientHealth(victim) <= 0)
	{
		new soundId = -1;
		switch(++headShotCount[attacker])
		{
			case 3:
			{
				if(settingsArray[HEADSHOT3])
				{
					soundId = HEADSHOT3;
				}
			}
			case 5:
			{
				if(settingsArray[HEADSHOT5])
				{
					soundId = HEADSHOT5;
				}
			}
			default:
			{
				if(settingsArray[HEADSHOT])
				{
					soundId = HEADSHOT;
				}
			}
		}
		if(soundId != -1)
		{
			PlayQuakeSound(soundId, attacker, 0, victim);
			PrintQuakeText(soundId, attacker, 0, victim);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

// The death event this is where we decide what sound to play
// It is important to note that we will play no more than one sound per death event
// so we will order them as to choose the most appropriate one
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new assisterId = GetEventInt(event, "assister");
	new attackerClient = GetClientOfUserId(attackerId);
	new assisterClient = GetClientOfUserId(assisterId);
	new victimClient = GetClientOfUserId(victimId);
	new bool:headshot;
	new bool:backstab;
	new soundId = -1;
	new bits;

	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if(GameTypeIsCS())
	{
		headshot = GetEventBool(event, "headshot");
		backstab = false;
	}
	else if(GameType == tf2)
	{
		new customkill = GetEventInt(event, "customkill");
		if (customkill != TF_CUSTOM_FISH_KILL &&
			GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH)
        {
			return;		//skip fishy kill
		}
		bits = GetEventInt(event,"damagebits");
		headshot = (customkill == 1);
		backstab = (customkill == 2);
	}
	else
	{
		headshot = false;
		backstab = false;
	}

	if(IsGrenade(weapon) && settingsArray[GRENADE])
	{
		if (GameType != tf2 || attackerId == victimId)
			soundId = GRENADE;
	}
	else if(IsRocket(weapon))
	{
		if (GameType == tf2)
		{
			if((bits & 1048576) && attackerId > 0 && settingsArray[CRITROCKET])
				soundId = CRITROCKET;
			else if(attackerId == victimId && settingsArray[ROCKET])
				soundId = ROCKET;
		}
		else
			soundId = ROCKET;
	}

	//start of long IF
	if (attackerClient > 0 && attackerClient <= MAXPLAYERS)
	{	
		if (attackerId == victimId)
		{
			if(settingsArray[SELFKILL])
				soundId = SELFKILL;
		}
		else if (attackerId > 0)
		{
			totalKills++;
			consecutiveKills[attackerClient]++;

			if(victimClient)
				consecutiveKills[victimClient] = 0;

			if(totalKills == 1 && settingsArray[FIRSTBLOOD])
				soundId = FIRSTBLOOD;

			if(headshot)
			{
				switch(++headShotCount[attackerClient]) {
					case 3:
						if(settingsArray[HEADSHOT3]) soundId = HEADSHOT3;
					case 5:
						if(settingsArray[HEADSHOT5]) soundId = HEADSHOT5;
					default: if(settingsArray[HEADSHOT]) soundId = HEADSHOT;
				}
			}
		
			if(backstab)
			{
				switch(++backStabCount[attackerClient]) {
					case 3:
						if(settingsArray[BACKSTAB3]) soundId = BACKSTAB3;
					case 5:
						if(settingsArray[BACKSTAB5]) soundId = BACKSTAB5;
					default:
						if(settingsArray[BACKSTAB]) soundId = BACKSTAB;
				}
			}
			else
			{
				new melee = IsMelee(weapon);
				if(melee)
				{
					new index = ((melee - 1) * 3) + KNIFE;
					switch(++meleeCount[melee][attackerClient])
 					{
						case 3:
							if(settingsArray[index + 1]) soundId = index + 1;
								else if (settingsArray[KNIFE3]) soundId = KNIFE3;
									else if (settingsArray[MELEE]) soundId = MELEE;
						case 5:
							if(settingsArray[index + 2]) soundId = index + 2;
								else if (settingsArray[KNIFE5]) soundId = KNIFE5;
									else if (settingsArray[MELEE]) soundId = MELEE;
						default:
							if(settingsArray[index]) soundId = index;
								else if (settingsArray[KNIFE]) soundId = KNIFE;
									else if (settingsArray[MELEE])	soundId = MELEE;
					}
				}
				else if(melee && settingsArray[MELEE])
					 soundId = MELEE;
			}
	
			if (consecutiveKills[attackerClient] < MAX_CONKILLS)
			{
				if(killNumSetting[consecutiveKills[attackerClient]])
					soundId = killNumSetting[consecutiveKills[attackerClient]];
			}
	
			if((settingsArray[DOUBLECOMBO] || settingsArray[TRIPLECOMBO] ||
			    settingsArray[QUADCOMBO] || settingsArray[MONSTERCOMBO]))
			{
				if(lastKillTime[attackerClient] != -1.0)
				{
					if((GetEngineTime() - lastKillTime[attackerClient]) < 1.5)
					{
						switch(++lastKillCount[attackerClient])
						{
							case 2:
								soundId = DOUBLECOMBO;
							case 3:
								soundId = TRIPLECOMBO;
							case 4:
								soundId = QUADCOMBO;
							case 5:
								soundId = MONSTERCOMBO;
						}
					}
					else
					{
						lastKillCount[attackerClient] = 1;
					}
				}
				else
				{
					lastKillCount[attackerClient] = 1;
				}
				lastKillTime[attackerClient] = GetEngineTime();
			}
			
			if(victimClient && GetClientTeam(attackerClient) == GetClientTeam(victimClient) && settingsArray[TEAMKILL])
				soundId = TEAMKILL;
		}
		else
		{
			if(GameType == tf2)
			{
				if (bits == 16 && victimClient > 0)
					soundId = TRAINKILL;
				else if (bits == 16384 && victimClient > 0)
					soundId = DROWNED;
			}
		}
	}	
	//end of long IF

	//For MODs with "assister" variable in player_death
	if (assisterClient > 0 && assisterClient <= MAXPLAYERS && assisterId != victimId)
	{
		if (consecutiveKills[assisterClient] < MAX_CONKILLS)
		{
			if(killNumSetting[consecutiveKills[assisterClient]])
				soundId = killNumSetting[consecutiveKills[assisterClient]];
		}
	
		if((settingsArray[DOUBLECOMBO] ||
			settingsArray[TRIPLECOMBO] ||
			settingsArray[QUADCOMBO] ||
			settingsArray[MONSTERCOMBO]))
		{
			if(lastKillTime[assisterClient] != -1.0) {
				if((GetEngineTime() - lastKillTime[assisterClient]) < 1.5) {
					switch(++lastKillCount[assisterClient])
					{
						case 2:
							soundId = DOUBLECOMBO;
						case 3:
							soundId = TRIPLECOMBO;
						case 4:
							soundId = QUADCOMBO;
						case 5:
							soundId = MONSTERCOMBO;
					}
				} else 
				lastKillCount[assisterClient] = 1;
			} else
				lastKillCount[assisterClient] = 1;
			lastKillTime[assisterClient] = GetEngineTime();
		}
	}	

	// Play the appropriate sound if there was a reason to do so 
	if(soundId != -1)
    {
		PlayQuakeSound(soundId, attackerClient, assisterClient, victimClient);
		PrintQuakeText(soundId, attackerClient, assisterClient, victimClient);
	}
}

//  This selects or disables the quake sounds
public MenuHandlerQuake(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        // The Disable Choice moves around based on if female sounds are enabled
        new disableChoice = numSets + 1;

        // Update both the soundPreference array and User Settings KV
        if(param2 == disableChoice)
            soundPreference[param1] = 0;
        else if(param2 == 0)
            textPreference[param1] = (textPreference[param1]) ? 0 : 1;
        else
            soundPreference[param1] = param2;

        decl String:buffer[5];
        IntToString(textPreference[param1], buffer, sizeof(buffer));
        SetClientCookie(param1, cookieTextPref, buffer);
        IntToString(soundPreference[param1], buffer, sizeof(buffer));
        SetClientCookie(param1, cookieSoundPref, buffer);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

//  This creates the Quake menu
public Action:MenuQuake(client, args)
{
	ShowQuakeMenu(client);
	return Plugin_Handled;
}

//add to clientpref's built-in !settings menu
public QuakePrefSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
    if (action == CookieMenuAction_SelectOption)
        ShowQuakeMenu(client);
}

ShowQuakeMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandlerQuake);
    decl String:buffer[100];

    Format(buffer, sizeof(buffer), "%T", "quake menu", client);
    SetMenuTitle(menu, buffer);

    if(textPreference[client] == 0)
        Format(buffer, sizeof(buffer), "%T", "enable text", client);
    else
        Format(buffer, sizeof(buffer), "%T", "disable text", client);
    AddMenuItem(menu, "text pref", buffer);

    for(new set = 0; set < numSets; set++)
    {
        if(soundPreference[client] == set + 1)
            Format(buffer, 50, "%T(Enabled)", setNames[set], client);
        else
            Format(buffer, 50, "%T", setNames[set], client);

        AddMenuItem(menu, "sound set", buffer);
    }

    if(soundPreference[client] == 0)
        Format(buffer, sizeof(buffer), "%T(Enabled)", "no quake sounds", client);
    else
        Format(buffer, sizeof(buffer), "%T", "no quake sounds", client);

    AddMenuItem(menu, "no sounds", buffer);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);
}

// Loads the soundsList array with the quake sounds
public LoadSounds()
{
    new Handle:kvQSL = CreateKeyValues("QuakeSoundsList");
    decl String:fileQSL[MAX_FILE_LEN];
    decl String:buffer[30];

    BuildPath(Path_SM, fileQSL, MAX_FILE_LEN, "configs/QuakeSoundsList.cfg");
    FileToKeyValues(kvQSL, fileQSL);

    if (!KvJumpToKey(kvQSL, "sound sets"))
    {
        SetFailState("configs/QuakeSoundsList.cfg not found or not correctly structured");
        return;
    }

    // Load the quake sounds
    // Read the sound set information in
    numSets = 0;
    for(new i = 0; i < MAX_NUM_SETS; i++)
    {
        Format(buffer, 30, "sound set %i", i + 1);
        KvGetString(kvQSL, buffer, setNames[numSets], sizeof(setNames[]));
        if(setNames[numSets][0])
            numSets++;
    }

    for(new soundKey = 0; soundKey < sizeof(soundNames); soundKey++)
    {
        KvRewind(kvQSL);
        KvJumpToKey(kvQSL, soundNames[soundKey]);
        for(new set = 0; set < numSets; set++)
        {
            KvGetString(kvQSL, setNames[set], soundsList[set][soundKey], MAX_FILE_LEN);
            if(StrEqual(soundsList[set][soundKey], ""))
                PrintToServer("Failed to load %s:%s", soundsList[set], soundNames[soundKey]);
        }
        if(soundKey >= KILLS_1 && soundKey <= KILLS_11)
            killNumSetting[KvGetNum(kvQSL, "kills")] = soundKey;
        settingsArray[soundKey] = KvGetNum(kvQSL, "config", 9);
    }

    // Load the event sounds
    KvRewind(kvQSL);
    // If the event sounds section is missing we have an old config file
    if(!KvJumpToKey(kvQSL, "event sounds"))
        SetFailState("configs/QuakeSoundsList.cfg is missing event sounds section, you may need to upgrade it");

    // read the sounds in
    for(new eventKey = 0; eventKey < sizeof(eventSoundNames); eventKey++)
    {
        KvRewind(kvQSL);
        KvJumpToKey(kvQSL, "event sounds");
        KvJumpToKey(kvQSL, eventSoundNames[eventKey]);
        KvGetString(kvQSL, "sound", eventSoundsList[eventKey], sizeof(eventSoundsList[]));
        eventSettingsArray[eventKey] = KvGetNum(kvQSL, "config", 1);
    }

    CloseHandle(kvQSL);
}

// The Precaches all the sounds and adds them to the downloads table so that
// clients can automatically download them
// As of version 0.7 we only do this if the sounds are enabled
public SetupQuakeSounds()
{
    for(new sound=0; sound < sizeof(soundNames); sound++)
    {
        if((settingsArray[sound] & 1) || (settingsArray[sound] & 2) || (settingsArray[sound] & 4))
        {                                      
            for(new set = 0; set < numSets; set++)
            {
                if(soundsList[set][sound][0])
                    SetupSound(soundsList[set][sound]);
            }
        }
    }
}

public SetupEventSounds()
{
    for(new sound = 0; sound < sizeof(eventSoundNames); sound++)
    {
        if(eventSoundsList[sound][0])
            SetupSound(eventSoundsList[sound][0]);
    }
}

// This plays the quake sounds based on soundPreference
public PlayQuakeSound(soundKey, attackerClient, assisterClient, victimClient)
{
    new playersConnected = GetMaxClients();

    if(settingsArray[soundKey] & 1)
    {
        for (new i = 1; i < playersConnected; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i) && soundPreference[i] && soundsList[soundPreference[i]-1][soundKey][0])
            {
                if (PrepareSound(soundsList[soundPreference[i]-1][soundKey]))
                {
                    if (GetGameType() == csgo)
                    {
                        ClientCommand(i, "playgamesound \"*%s\"", soundsList[soundPreference[i]-1][soundKey]);
                    }
                    else
                    {
                        EmitSoundToClient(i, soundsList[soundPreference[i]-1][soundKey],
                                          _, _, _, _, GetConVarFloat(cvarVolume));
                    }
                }
            }
        }
        return;
    }

    if(attackerClient && IsClientInGame(attackerClient) && !IsFakeClient(attackerClient))
    {
        if(soundPreference[attackerClient] && (settingsArray[soundKey] & 2) && soundsList[soundPreference[attackerClient]-1][soundKey][0])
        {
            if (PrepareSound(soundsList[soundPreference[attackerClient]-1][soundKey]))
            {
                if (GetGameType() == csgo)
                {
                    ClientCommand(attackerClient, "playgamesound \"*%s\"", soundsList[soundPreference[attackerClient]-1][soundKey]);
                }
                else
                {
                    EmitSoundToClient(attackerClient, soundsList[soundPreference[attackerClient]-1][soundKey],
                                      _, _, _, _, GetConVarFloat(cvarVolume));
                }
            }
        }
    }

    if(assisterClient && IsClientInGame(assisterClient) && !IsFakeClient(assisterClient))
    {
        if(soundPreference[assisterClient] && (settingsArray[soundKey] & 2) && soundsList[soundPreference[assisterClient]-1][soundKey][0])
        {
            if (PrepareSound(soundsList[soundPreference[assisterClient]-1][soundKey]))
            {
                if (GetGameType() == csgo)
                {
                    ClientCommand(assisterClient, "playgamesound \"*%s\"", soundsList[soundPreference[assisterClient]-1][soundKey]);
                }
                else
                {
                    EmitSoundToClient(assisterClient, soundsList[soundPreference[assisterClient]-1][soundKey],
                                      _, _, _, _, GetConVarFloat(cvarVolume));
                }
            }
        }
    }

    if(victimClient && IsClientInGame(victimClient) && !IsFakeClient(victimClient))
    {
        if(soundPreference[victimClient] && (settingsArray[soundKey] & 4) && soundsList[soundPreference[victimClient]-1][soundKey][0])
        {
            if (PrepareSound(soundsList[soundPreference[victimClient]-1][soundKey]))
            {
                if (GetGameType() == csgo)
                {
                    ClientCommand(victimClient, "playgamesound \"*%s\"", soundsList[soundPreference[victimClient]-1][soundKey]);
                }
                else
                {
                    EmitSoundToClient(victimClient, soundsList[soundPreference[victimClient]-1][soundKey],
                                      _, _, _, _, GetConVarFloat(cvarVolume));
                }
            }
        }
    }
}

// This prints the quake text
public PrintQuakeText(soundKey, attackerClient, assisterClient, victimClient)
{
    new playersConnected = GetMaxClients();
    decl String:attackerName[62];
    decl String:victimName[30];

    // Get the names of the victim and the attacker
    if(attackerClient && IsClientInGame(attackerClient))
    {
        GetClientName(attackerClient, attackerName, 30);
        if(assisterClient && IsClientInGame(assisterClient))
        {
            decl String:assisterName[30];
            GetClientName(assisterClient, assisterName, 30);
            StrCat(attackerName, sizeof(attackerName), "+");
            StrCat(attackerName, sizeof(attackerName), assisterName);
        }
    }
    else if(assisterClient && IsClientInGame(assisterClient))
        GetClientName(assisterClient, attackerName, 30);
    else
        attackerName = "Nobody";

    if(victimClient && IsClientInGame(victimClient))
        GetClientName(victimClient, victimName, 30);
    else
        victimName = "Nobody";

    if(settingsArray[soundKey] & 8)
    {
        for(new i = 1; i < playersConnected; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i) && textPreference[i])
                PrintCenterText(i, "%t", soundNames[soundKey], attackerName, victimName);
        }                
        return;
    }

    if(attackerClient && IsClientInGame(attackerClient) && !IsFakeClient(attackerClient))
    {
        if(textPreference[attackerClient] && (settingsArray[soundKey] & 16))
            PrintCenterText(attackerClient, "%t", soundNames[soundKey], attackerName, victimName);
    }

    if(assisterClient && IsClientInGame(assisterClient) && !IsFakeClient(assisterClient))
    {
        if(textPreference[assisterClient] && (settingsArray[soundKey] & 16))
            PrintCenterText(assisterClient, "%t", soundNames[soundKey], attackerName, victimName);
    }

    if(victimClient && IsClientInGame(victimClient) && !IsFakeClient(victimClient))
    {
        if(textPreference[victimClient] && (settingsArray[soundKey] & 32))
            PrintCenterText(victimClient, "%t", soundNames[soundKey], attackerName, victimName);
    }
}

// Play the starting sound
public EventRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	PlayQuakeSound(ROUND_PLAY, 0, 0, 0);
	PrintQuakeText(ROUND_PLAY, 0, 0, 0);
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GameType != hl2mp)
        NewRoundInitialization();
}

public ResetConsecutiveKills()
{
    for(new i=1; i <= MAXPLAYERS; i++)
        consecutiveKills[i] = 0;
}

public ResetMeleeKills()
{
    for(new i=1; i < sizeof(meleeCount); i++)
    {
        for(new j=1; j <= MAXPLAYERS; j++)
            meleeCount[i][j] = 0;
    }
}

public ResetLastKillTime()
{
	for(new i=1; i <= MAXPLAYERS; i++)
		lastKillTime[i] = NO_KILLS;
}

public IsGrenade(const String:weapon[])
{
    if (GameTypeIsCS())
    {
        // Counter Strike:Source grenades
        return (StrEqual(weapon, "hegrenade") ||
                StrEqual(weapon, "smokegrenade") ||
                StrEqual(weapon, "flashbang"));
    }
    else
    {
        switch (GameType)
        {
            case dod:
            {
                // Day of Defeat:Source grenades
                return (StrEqual(weapon, "riflegren_ger") ||
                        StrEqual(weapon, "riflegren_us") ||
                        StrEqual(weapon, "frag_ger") ||
                        StrEqual(weapon, "frag_us") ||
                        StrEqual(weapon, "smoke_ger") ||
                        StrEqual(weapon, "smoke_us"));
            }
            case hl2mp:
            {
                // HL2:Deathmatch grenades
                return (StrEqual(weapon, "grenade_frag"));
            }
            case tf2:
            {
                return (StrEqual(weapon,"tf_projectile_pipe") ||
                        StrEqual(weapon,"tf_projectile_pipe_remote") ||
                        StrEqual(weapon,"sticky_resistance") ||
                        StrEqual(weapon,"deflect_sticky") ||
                        StrEqual(weapon,"deflect_promode") ||
                        StrEqual(weapon,"tf_pumpkin_bomb") ||
                        StrEqual(weapon,"stickybomb_defender") ||
                        StrEqual(weapon,"grenadelauncher") ||
                        StrEqual(weapon,"pipebomblauncher") ||
                        StrEqual(weapon,"loch_n_load"));
            }
        }
    }
    return 0;
}

public IsRocket(const String:weapon[])
{
    switch (GameType)
    {
        case dod:
        {
            // Day of Defeat:Source rockets
            return (StrEqual(weapon,"bazookarocket") ||
                    StrEqual(weapon,"panzerschreckrocket"));
        }
        case tf2:
        {
            // tf2 rockets
            return (StrEqual(weapon,"tf_projectile_rocket") ||
                    StrEqual(weapon,"tf_weapon_rocketlauncher") ||
                    StrEqual(weapon,"rocketlauncher_directhit") ||
                    StrEqual(weapon,"deflect_rocket") ||
                    StrEqual(weapon,"blackbox") ||
                    StrEqual(weapon,"rocketlauncher_blackbox") ||
                    StrEqual(weapon,"liberty_launcher") ||
                    StrEqual(weapon,"quake_rl") ||
                    StrEqual(weapon,"cow_mangler") ||
                    StrEqual(weapon,"tf_projectile_energy_ball"));
        }
    }
    return 0;
}

IsMelee(const String:weapon[])
{
    if (GameTypeIsCS())
    {
        return StrEqual(weapon,"weapon_knife");
    }
    else
    {
        switch (GameType)
        {
            case dod:
            {
                return (StrEqual(weapon,"amerknife") ||
                        StrEqual(weapon,"spade") ||
                        StrEqual(weapon,"punch"));
            }
            case hl2mp:
            {
                if(StrEqual(weapon, "stunstick"))
                    return 1;
                else if(StrEqual(weapon, "crowbar"))
                    return 2;
            }
            case tf2:
            {
                if (StrEqual(weapon,"knife") ||
                    StrEqual(weapon,"eternal_reward") ||
                    StrEqual(weapon,"voodoo_pin") ||
                    StrEqual(weapon,"sharp_dresser") ||
                    StrEqual(weapon,"kunai") ||
                    StrEqual(weapon,"big_earner") ||
                    StrEqual(weapon,"taunt_spy"))
                {
                    return 1;
                }
                else if(StrEqual(weapon,"fists") ||
                        StrEqual(weapon,"bear_claws") ||
                        StrEqual(weapon,"warrior_spirit") ||
                        StrEqual(weapon,"steel_fists") ||
                        StrEqual(weapon,"gloves") ||
                        StrEqual(weapon,"gloves_running_urgently") ||
                        StrEqual(weapon,"eviction_notice") ||
                        StrEqual(weapon,"apocofists")  ||
                        StrEqual(weapon,"taunt_heavy"))
                {
                    return 2;
                }
                else if(StrEqual(weapon,"bat") ||
                        StrEqual(weapon,"sandman") ||
                        StrEqual(weapon,"holy_mackerel") ||
                        StrEqual(weapon,"candy_cane") ||
                        StrEqual(weapon,"boston_basher")   ||
                        StrEqual(weapon,"scout_sword") ||
                        StrEqual(weapon,"warfan") ||
                        StrEqual(weapon,"lava_bat") ||
                        StrEqual(weapon,"atomizer") ||
                        StrEqual(weapon,"taunt_scout"))
                {
                    return 3;
                }
                else if (StrEqual(weapon,"wrench") ||
                        StrEqual(weapon,"wrench_jag") ||
                        StrEqual(weapon,"wrench_golden") ||
                        StrEqual(weapon,"robot_arm_blender_kill") ||
                        StrEqual(weapon,"robot_arm_combo_kill") ||
                        StrEqual(weapon,"robot_arm") ||
                        StrEqual(weapon,"southern_hospitality") ||
                        StrEqual(weapon,"taunt_guitar_kill"))
                {
                    return 4;
                }
                else if(StrEqual(weapon,"bottle") ||
                        StrEqual(weapon,"sword") ||
                        StrEqual(weapon,"battleaxe") ||
                        StrEqual(weapon,"claidheamohmor") ||
                        StrEqual(weapon,"persian_persuader") ||
                        StrEqual(weapon,"headtaker") ||
                        StrEqual(weapon,"nessieclub") ||
                        StrEqual(weapon,"demoshield") ||
                        StrEqual(weapon,"splendid_screen") ||
                        StrEqual(weapon,"ullapool_caber") ||
                        StrEqual(weapon,"ullapool_caber_explosion") ||
                        StrEqual(weapon,"taunt_demoman"))
                {
                    return 5;
                }
                else if(StrEqual(weapon,"bonesaw") ||
                        StrEqual(weapon,"ubersaw") ||
                        StrEqual(weapon,"amputator") ||
                        StrEqual(weapon,"battleneedle") ||
                        StrEqual(weapon,"solemn_vow") ||
                        StrEqual(weapon,"taunt_medic"))
                {
                    return 6;
                }
                else if(StrEqual(weapon,"shovel") ||
                        StrEqual(weapon,"pickaxe") ||
                        StrEqual(weapon,"unique_pickaxe") ||
                        StrEqual(weapon,"fryingpan") ||
                        StrEqual(weapon,"market_gardener") ||
                        StrEqual(weapon,"disciplinary_action") ||
                        StrEqual(weapon,"mantreads") ||
                        StrEqual(weapon,"taunt_soldier"))
                {
                    return 7;
                }
                else if(StrEqual(weapon,"fireaxe") ||
                        StrEqual(weapon,"axtinguisher") ||
                        StrEqual(weapon,"sledgehammer") ||
                        StrEqual(weapon,"powerjack") ||
                        StrEqual(weapon,"the_maul") ||
                        StrEqual(weapon,"back_scratcher") ||
                        StrEqual(weapon,"mailbox") ||
                        StrEqual(weapon,"lava_axe") ||
                        StrEqual(weapon,"taunt_pyro"))
                {
                    return 8;
                }
                else if(StrEqual(weapon,"club") ||
                        StrEqual(weapon,"tribalkukri") ||
                        StrEqual(weapon,"shahanshah") ||
                        StrEqual(weapon,"bushwacka") ||
                        StrEqual(weapon,"taunt_sniper"))
                {
                    return 9;
                }
                else if (StrEqual(weapon,"paintrain") ||
                        StrEqual(weapon,"demokatana") ||
                        StrEqual(weapon,"saxxy"))
                {
                    return 1;
                }
            }
        }
    }
    return 0;
}

// This is called from EventRoundStart or OnMapStart depending on the mod
public NewRoundInitialization()
{
    totalKills = 0;
    for(new i; i <= MAXPLAYERS; i++)
    {
        headShotCount[i] = 0;
        backStabCount[i] = 0;
        lastKillCount[i] = -1;
    }
    ResetLastKillTime();
}

public PrepareClient(client)
{
    if(client)
    {
        if(IsFakeClient(client))
        {
            soundPreference[client] = -1;
            textPreference[client] = 0;
        }
        else
        {
            if(AreClientCookiesCached(client))
            {
                decl String:buffer[5];

                GetClientCookie(client, cookieTextPref, buffer, sizeof(buffer));
                if(buffer[0])
                    textPreference[client] = StringToInt(buffer);

                GetClientCookie(client, cookieSoundPref, buffer, sizeof(buffer));
                if(buffer[0])
                    soundPreference[client] = StringToInt(buffer);
            }

            // Make the announcement in 30 seconds unless announcements are turned off
            if(GetConVarBool(cvarAnnounce))
                CreateTimer(30.0, TimerAnnounce, client);
        }

        // Initialize variables
        consecutiveKills[client] = 0;
        lastKillTime[client] = -1.0;
        for(new i=1; i < sizeof(meleeCount); i++)
            meleeCount[i][client] = 0;
    }
}

// Looks for cvar changes of the enable cvar and hooks or unhooks the events
public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(GetConVarBool(cvarEnabled) && !IsHooked)
    {
        HookEvent("player_death", EventPlayerDeath);
        if(GameTypeIsCS())
            HookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
        else if(GameType == dod)
            HookEvent("dod_warmup_ends", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
        else if(GameType == tf2)
            HookEvent("teamplay_round_active", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
        if(GameType == dod)
            HookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
        else if(GameType == tf2)
            HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
        else
            HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
        IsHooked = true;
    }
    else if(!GetConVarBool(cvarEnabled) && IsHooked)
    {
        UnhookEvent("player_death", EventPlayerDeath);
        if(GameTypeIsCS())
            UnhookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
        else if(GameType == dod)
            UnhookEvent("dod_warmup_ends", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
        else if(GameType == tf2)
            UnhookEvent("teamplay_round_active", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
        if(GameType == dod)
            UnhookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
        else if(GameType == tf2)
            UnhookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
        else
            UnhookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
        IsHooked = false;
    }
}
