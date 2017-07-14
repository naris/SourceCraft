/*
 * vim: set ai et! ts=4 sw=4 :
 * [TF2] Monoculus Spawner
 * Author(s): DarthNinja (based on Geit, modifications by FlaminSarge, retsam, naris)
 * File: MonoSpawn.sp
 * Description: Allows admins to spawn Monoculus at aim.
 *
 * Ability to specify model and precache the models & sounds.
 * On admin menu
 * Public voting and cvars
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "2.1.1"

#define ADMFLAG_EYEBOSS	ADMFLAG_CUSTOM3	

#define INVIS			{255,255,255,0}
#define NORMAL			{255,255,255,255}

#define EYEBOSS_MODEL		"models/props_halloween/halloween_demoeye.mdl"
#define EYEROCKET_MODEL     "models/props_halloween/eyeball_projectile.mdl"

new Handle:Cvar_Eyeboss_AllowPublic = INVALID_HANDLE;
new Handle:Cvar_Eyeboss_Votesneeded = INVALID_HANDLE;
new Handle:Cvar_Eyeboss_VoteDelay = INVALID_HANDLE;

new Handle:v_BaseHP_Level2 = INVALID_HANDLE;
new Handle:v_HP_Per_Player = INVALID_HANDLE;
new Handle:v_HP_Per_Level = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;

new Float:g_pos[3];
new Float:g_fVotesNeeded;

new g_eyeBossModel = 0;
new g_eyeRocketModel = 0;
new g_iLetsChangeThisEvent = 0;

new g_iVotes = 0;
new g_Voters = 0;
new g_VotesNeeded = 0;
new g_voteDelayTime;

new bool:g_bIsEnabled = true;
new bool:g_bVotesStarted = false;
new bool:g_bNativeOverride = false;
new bool:g_bSoundsPrecached = false;
new bool:g_bModelsPrecached = false;
new bool:g_bHasVoted[MAXPLAYERS + 1] = { false, ... };
//new bool:g_IsMonoculus[MAXPLAYERS+1] = { false, ...};

public Plugin:myinfo = 
{
	name = "[TF2] Monoculus Spawner",
	author = "DarthNinja, FlaminSarge, retsam, -=JFH=-Naris",
	description = "Spawns a Monoculus where you're looking.",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

/**
 * Description: Manage precaching resources.
 */
#tryinclude <lib/ResourceManager>
#if !defined _ResourceManager_included
    #tryinclude <ResourceManager>
#endif
#if !defined _ResourceManager_included
    #define AUTO_DOWNLOAD   -1
	#define DONT_DOWNLOAD    0
	#define DOWNLOAD         1
	#define ALWAYS_DOWNLOAD  2

	enum State { Unknown=0, Defined, Download, Force, Precached };

	// Trie to hold precache status of sounds
	new Handle:g_soundTrie = INVALID_HANDLE;
    new Handle:g_modelTrie = INVALID_HANDLE;

	stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=false)
	{
        #pragma unused force
        new State:value = Unknown;
        if (!GetTrieValue(g_soundTrie, sound, value) || value < Precached)
        {
            PrecacheSound(sound, preload);
            SetTrieValue(g_soundTrie, sound, Precached);
        }
        return true;
    }

    stock SetupModel(const String:model[], &index=0, bool:download=false,
                     bool:precache=false, bool:preload=false)
    {
        if (download && FileExists(model))
            AddFileToDownloadsTable(model);

        if (precache)
            index = PrecacheModel(model,preload);
        else
            index = 0;
    }

    stock PrepareModel(const String:model[], &index=0, bool:preload=true)
    {
        if (g_modelTrie == INVALID_HANDLE)
            g_modelTrie = CreateTrie();

        if (index <= 0)
            GetTrieValue(g_modelTrie, model, index);

        if (index <= 0)
        {
            index = PrecacheModel(model, preload);
            SetTrieValue(g_modelTrie, model, index);
        }
        return index;
    }
#endif

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_monospawn_version", PLUGIN_VERSION, "Monoculus Spawner Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_Eyeboss_AllowPublic = CreateConVar("sm_eyeboss_allowvoting", "0", "Allow public Monoculus voting?(1/0 = yes/no)", _, true, 0.0, true, 1.0);
	Cvar_Eyeboss_Votesneeded = CreateConVar("sm_eyeboss_votesneeded", "0.50", "Percent of votes required for successful Monoculus vote. (0.50 = 50%)", _, true, 0.10, true, 1.0);
	Cvar_Eyeboss_VoteDelay = CreateConVar("sm_eyeboss_votedelay", "120.0", "Delay time in seconds between calling votes.");

	v_BaseHP_Level2 = FindConVar("tf_eyeball_boss_health_at_level_2");
	v_HP_Per_Player = FindConVar("tf_eyeball_boss_health_per_player");
	v_HP_Per_Level = FindConVar("tf_eyeball_boss_health_per_level");

	HookEvent("eyeball_boss_summoned", BossSummoned, EventHookMode_Pre);

	//RegAdminCmd("sm_makemeeye", Command_Summon, ADMFLAG_EYEBOSS);
	RegAdminCmd("sm_eyeboss", GreatBallRockets, ADMFLAG_EYEBOSS);

	RegConsoleCmd("voteeyeboss", Command_VoteSpawnEyeboss, "Trigger to vote to spawn Monoculus.");
	RegConsoleCmd("voteeye", Command_VoteSpawnEyeboss, "Trigger to vote to spawn Monoculus.");

	HookConVarChange(Cvar_Eyeboss_AllowPublic, Cvars_Changed);
	HookConVarChange(Cvar_Eyeboss_Votesneeded, Cvars_Changed);

	AutoExecConfig(true, "plugin.voteeyeboss");

	if (LibraryExists("adminmenu"))
	{
		new Handle:topmenu = GetAdminTopMenu();
		if (topmenu != INVALID_HANDLE)
			OnAdminMenuReady(topmenu);
	}
}

public OnClientPutInServer(client)
{
	if(IsFakeClient(client))
		return;

	g_bHasVoted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_fVotesNeeded);
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;

	if(g_bHasVoted[client])
	{
		g_iVotes--;
		g_bHasVoted[client] = false;
	}

	g_Voters--;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_fVotesNeeded);
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Eyeboss_AllowPublic);
	g_fVotesNeeded = GetConVarFloat(Cvar_Eyeboss_Votesneeded);
}

public OnMapStart()
{
    #if !defined _ResourceManager_included
        if (g_soundTrie == INVALID_HANDLE)
            g_soundTrie = CreateTrie();
        else
            ClearTrie(g_soundTrie);

        if (g_modelTrie == INVALID_HANDLE)
            g_modelTrie = CreateTrie();
        else
            ClearTrie(g_modelTrie);
    #endif

    SetupModel(EYEROCKET_MODEL, g_eyeRocketModel);
    SetupModel(EYEBOSS_MODEL, g_eyeBossModel);

    g_bModelsPrecached = false;
    g_bSoundsPrecached = false;
    g_bVotesStarted = false;
    g_VotesNeeded = 0;
    g_Voters = 0;
    g_iVotes = 0;
}

PrepareEyebossModel(const String:model[])
{
    if (!g_bModelsPrecached)
    {
        PrepareModel(EYEROCKET_MODEL, g_eyeRocketModel);
        PrepareModel(EYEBOSS_MODEL, g_eyeBossModel);
        g_bModelsPrecached = true;
    }

    if (model[0] != '\0')
        PrepareModel(model);
}

PrepareEyebossSounds()
{
    PrepareSound("ui/halloween_boss_summon_rumble.wav", true, true);
    PrepareSound("ui/halloween_boss_chosen_it.wav", true, true);
    PrepareSound("ui/halloween_boss_defeated_fx.wav", true, true);
    PrepareSound("ui/halloween_boss_defeated.wav", true, true);
    PrepareSound("ui/halloween_boss_player_becomes_it.wav", true, true);
    PrepareSound("ui/halloween_boss_summoned_fx.wav", true, true);
    PrepareSound("ui/halloween_boss_summoned.wav", true, true);
    PrepareSound("ui/halloween_boss_tagged_other_it.wav", true, true);
    PrepareSound("ui/halloween_boss_escape.wav", true, true);
    PrepareSound("ui/halloween_boss_escape_sixty.wav", true, true);
    PrepareSound("ui/halloween_boss_escape_ten.wav", true, true);
    PrepareSound("ui/halloween_boss_tagged_other_it.wav", true, true);

    PrepareSound("vo/halloween_eyeball/eyeball_biglaugh01.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_boss_pain01.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_laugh01.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_laugh02.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_laugh03.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_mad01.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_mad02.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_mad03.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball_teleport01.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball01.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball02.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball03.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball04.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball05.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball06.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball07.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball08.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball09.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball10.wav", true, true);
    PrepareSound("vo/halloween_eyeball/eyeball11.wav", true, true);

    g_bSoundsPrecached = true;
}

// FUNCTIONS

public Action:BossSummoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iLetsChangeThisEvent != 0)
	{
		new Handle:hEvent = CreateEvent(name);
		if (hEvent == INVALID_HANDLE)
			return Plugin_Handled;
		
		SetEventInt(hEvent, "level", g_iLetsChangeThisEvent);
		FireEvent(hEvent);
		g_iLetsChangeThisEvent = 0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action:Command_VoteSpawnEyeboss(client, args)
{
	if(client < 1 || !IsClientInGame(client))
		return Plugin_Handled;

	if(g_bNativeOverride || !g_bIsEnabled)
	{
		PrintToChat(client, "\x01[SM] This vote trigger has been disabled by the server.");
		return Plugin_Handled;
	}
	
	if(g_voteDelayTime > GetTime())
	{
		new timeleft = g_voteDelayTime - GetTime();
		
		PrintToChat(client, "\x01[SM] There are %d seconds remaining before another Monoculus vote is allowed.", timeleft);
		return Plugin_Handled;
	}
	
	if(g_bHasVoted[client])
	{
		PrintToChat(client, "\x01[SM] You have already voted, you FOOL!");
		return Plugin_Handled;
	}
	
	if(!g_bVotesStarted)
	{
		g_bVotesStarted = true;
		CreateTimer(90.0, Timer_ResetVotes, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_iVotes++;
	g_bHasVoted[client] = true;
  
	if(g_iVotes >= g_VotesNeeded)
	{
		PrintToChatAll("[SM] Vote to spawn Monoculus was successful! [%d/%d]", g_iVotes, g_VotesNeeded);
		GreatBallRockets(client, 0);
		g_voteDelayTime = GetTime() + GetConVarInt(Cvar_Eyeboss_VoteDelay);
		ResetAllVotes();
	}
	else
	{
		PrintToChatAll("\x01[SM] \x03%N \x01has voted to spawn Monoculus: Type \x04!votehhh \x01/ \x04!voteeyeboss \x01to vote YES. [%d/%d]", client, g_iVotes, g_VotesNeeded);
	}

	return Plugin_Handled;
}

stock IsValidClient(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public Action:GreatBallRockets(client, args)
{
    if (g_bNativeOverride)
	{
		ReplyToCommand(client, "[SM] This command has been disabled by the server.");
		return Plugin_Handled;
	}
    else if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[SM] You must be an in-game admin to use this command!");
        return Plugin_Stop;
    }

    new iLevel = 0;
    if (args >= 1)
    {
        decl String:buffer[15];
        GetCmdArg(1, buffer, sizeof(buffer));
        iLevel = StringToInt(buffer);
    }

    decl String:modelname[PLATFORM_MAX_PATH+1];
    if (args >= 2)
    {
        GetCmdArg(2, modelname, sizeof(modelname));
        if (!FileExists(modelname, true))
        {
            ReplyToCommand(client, "[SM] Model is invalid. sm_eyeboss [level] [modelname].");
            return Plugin_Handled;
        }
    }
    else
        modelname[0] = '\0';

    switch (SpawnEyeBoss(client, iLevel, modelname))
    {
		case 0:
		{
			return  Plugin_Handled;
		}
        case 1:
        {
            ReplyToCommand(client, "[SM] Entity limit is reached. Can't spawn anymore eye bosses. Change maps.");
            return Plugin_Stop;
        }
        case 2:
        {
            ReplyToCommand(client, "[SM] Could not find spawn point.");
            return Plugin_Stop;
        }
        case 3:
        {
            ReplyToCommand(client, "[SM] Model is invalid. sm_eyeboss [level] [modelname].");
            return Plugin_Stop;
        }
    }

    ReplyToCommand(client, "[SM] Unable to spawn eye boss!");
    return Plugin_Stop;
}

SpawnEyeBoss(client, iLevel, const String:model[])
{
    if (GetEntityCount() >= GetMaxEntities()-32)
        return 1;

    if(!SetTeleportEndPoint(client))
        return 2;

    PrepareEyebossModel(model);
    if (model[0] != '\0' && !IsModelPrecached(model))
        return 3;

    if (!g_bSoundsPrecached)
        PrepareEyebossSounds();

    new entity = CreateEntityByName("eyeball_boss");
    if (entity > 0 && IsValidEntity(entity))
    {
        if (DispatchSpawn(entity))
        {
            if (model[0] != '\0')
                SetEntityModel(entity, model);

            if (iLevel > 1)
            {
                new iHP = GetConVarInt(v_BaseHP_Level2);

                iHP += (iLevel - 2) * GetConVarInt(v_HP_Per_Level);

                new iNumPlayers = GetClientCount(true);
                if (iNumPlayers > 10)
                    iHP += (iNumPlayers - 10) * GetConVarInt(v_HP_Per_Player);

                SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHP);
                SetEntityHealth(entity, iHP);

                g_iLetsChangeThisEvent = iLevel;
            }

            g_pos[2] -= 10.0;
            TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
            return 0;
        }
    }
    return 4;
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

/*
public Action:Command_Summon(client, args)
{
    decl String:modelname[256];
    if (args == 0)
        modelname[0] = '\0';
    else
    {
        GetCmdArgString(modelname, sizeof(modelname));
        if (!FileExists(modelname, true))
        {
            ReplyToCommand(client, "[SM] Model is invalid. sm_beeye [modelname].");
            return Plugin_Handled;
        }
    }

    if (modelname[0] != '\0' && !IsModelPrecached(modelname))
    {
        ReplyToCommand(client, "[SM] Model is invalid. sm_beeye [modelname].");
        return Plugin_Handled;
    }

    switch (SummonEyeBoss(client, modelname))
    {
        case 0:
        {
            ReplyToCommand(client, "\x04[\x03eyeboss\x04]\x01: You are now the eyeboss!");
            return  Plugin_Handled;
        }
        case 1:
        {
            ReplyToCommand(client, "\x04[\x03eyeboss\x04]\x01: You are now back to normal!");
            return  Plugin_Handled;
        }
        case -1:
        {
            ReplyToCommand(client, "[SM] Model is invalid. sm_beeye [level] [modelname].");
            return Plugin_Stop;
        }
    }

    ReplyToCommand(client, "[SM] Unable to set eye boss model!");
    return Plugin_Stop;
}

SummonEyeBoss(client, const String:model[])
{
	PrepareEyebossModel(model);
	if (model[0] != '\0' && !IsModelPrecached(model))
		return -1;

	if (IsPlayerAlive(client) && IsValidEntity(client) && !g_IsMonoculus[client])
	{
		SetVariantString(model[0] ? model : EYEBOSS_MODEL);
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		Colorize(client, INVIS);

		g_IsMonoculus[client] = true;
		return 0;
	}
	else if (IsValidEntity(client) && g_IsMonoculus[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Colorize(client, NORMAL);

		g_IsMonoculus[client] = false;
		return 1;
	}
	
	return -2;
}

//Credit to pheadxdll for invisibility code.
public Colorize(client, color[4])
{	
	//Colorize the weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	
	new String:classname[256];
	new type;
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if(weapon > -1 )
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if((StrContains(classname, "tf_weapon_",false) >= 0))
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	//Colorize the wearables, such as hats
	SetWearablesRGBA_Impl( client, "tf_wearable_item", "CTFWearableItem",color );
	SetWearablesRGBA_Impl( client, "tf_wearable_item_demoshield", "CTFWearableItemDemoShield", color);
	
	//Colorize the player
	//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	//SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if(color[3] > 0)
		type = 1;
	
	InvisibleHideFixes(client, class, type);
}

SetWearablesRGBA_Impl( client,  const String:entClass[], const String:serverClass[], color[4])
{
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, entClass)) != -1 )
	{
		if ( IsValidEntity(ent) )
		{		
			if (GetEntDataEnt2(ent, FindSendPropOffs(serverClass, "m_hOwnerEntity")) == client)
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
			}
		}
	}
}

InvisibleHideFixes(client, TFClassType:class, type)
{
	if(class == TFClass_DemoMan)
	{
		new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(decapitations >= 1)
		{
			if(!type)
			{
				//Removes Glowing Eye
				TF2_RemoveCondition(client, TFCond_DemoBuff);
			}
			else
			{
				//Add Glowing Eye
				TF2_AddCondition(client, TFCond_DemoBuff, 0.0);
			}
		}
	}
	else if(class == TFClass_Spy)
	{
		new disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(IsValidEntity(disguiseWeapon))
		{
			if(!type)
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = INVIS;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
			else
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = NORMAL;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
		}
	}
}
*/

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public Action:Timer_ResetVotes(Handle:timer)
{
	if(g_bVotesStarted)
	{
		PrintToChatAll("[SM] Vote to spawn eyeboss FAILED! [%d/%d]", g_iVotes, g_VotesNeeded);
		g_bVotesStarted = false;
		ResetAllVotes();
	}
}

ResetAllVotes()
{
	g_bVotesStarted = false;
	g_iVotes = 0;
	
	for(new x = 1; x <= MaxClients; x++) 
	{
		if(!IsClientInGame(x))
		{
			continue;
		}
		
		if(g_bHasVoted[x])
		{
			g_bHasVoted[x] = false;
		}
	}
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Eyeboss_AllowPublic)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_Eyeboss_Votesneeded)
	{
		g_fVotesNeeded = StringToFloat(newValue);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (!g_bNativeOverride && topmenu != hAdminMenu)
	{
		hAdminMenu = topmenu;

		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		if (server_commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(hAdminMenu,
					"sm_eyeboss",
					TopMenuObject_Item,
					AdminMenu_eyeboss, 
					server_commands,
					"sm_eyeboss",
					ADMFLAG_EYEBOSS);
		}
	}
}

public AdminMenu_eyeboss(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Call forth the mighty eyeboss");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		GreatBallRockets(param, 0);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Native
    CreateNative("ControlMonoculus",Native_Control);
    CreateNative("TF2_SpawnMonoculus",Native_SpawnEyeBoss);
    //CreateNative("TF2_SummonMonoculus",Native_SummonEyeBoss);
    RegPluginLibrary("MonoSpawn");
    return APLRes_Success;
}

public Native_Control(Handle:plugin,numParams)
{
    g_bNativeOverride |= GetNativeCell(1);
}

public Native_SpawnEyeBoss(Handle:plugin,numParams)
{
    decl String:model[PLATFORM_MAX_PATH+1];
    GetNativeString(3, model, sizeof(model));

    return SpawnEyeBoss(GetNativeCell(1), GetNativeCell(2), model);
}

/*
public Native_SummonEyeBoss(Handle:plugin,numParams)
{
    decl String:model[PLATFORM_MAX_PATH+1];
    GetNativeString(2, model, sizeof(model));

    return SummonEyeBoss(GetNativeCell(1), model);
}
*/

