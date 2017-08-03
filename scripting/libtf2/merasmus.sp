/*
 * vim: set ai et! ts=4 sw=4 :
 * [TF2] Merasmus Spawner
 * Author(s): Tak (Chaosxk)
 * File: merasmus.sp
 * Description: Allows admins to spawn Merasmus at aim.
 *
 * Ability to specify model and precache the models & sounds.
 * On admin menu
 * Public voting and cvars
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include "lib/ResourceManager"
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.1a"

#define ADMFLAG_MERASMUS ADMFLAG_CUSTOM3

new Float:g_pos[3];

new Handle:g_Size;
new Handle:g_Glow;

new Handle:v_HP_Base = INVALID_HANDLE;
new Handle:v_HP_Per_Player = INVALID_HANDLE;

new g_merasmusModel = 0;

new Handle:hAdminMenu = INVALID_HANDLE;

new bool:g_bNativeOverride = false;
new bool:g_bSoundsPrecached = false;
new bool:g_bModelsPrecached = false;

public Plugin:myinfo =
{
	name = "[TF2] Merasmus Spawner",
	author = "Tak (Chaosxk)",
	description = "RUN COWARDS! RUN!!!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CheckGame();
	
	CreateConVar("sm_merasmus_version", PLUGIN_VERSION, "Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_merasmus", Meras, ADMFLAG_GENERIC);
	RegAdminCmd("sm_meras", Meras, ADMFLAG_GENERIC);
	
	g_Size = CreateConVar("sm_merasmus_resize", "1.0", "Size of Merasmus, Scale.");
	g_Glow = CreateConVar("sm_merasmus_glow", "0.0", "Should Merasmus be glowing?");

	v_HP_Base = FindConVar("tf_merasmus_health_base");
	v_HP_Per_Player = FindConVar("tf_merasmus_health_per_player");
	
	HookConVarChange(g_Size, Convar_Changer);
	HookConVarChange(g_Glow, Convar_Changer);
	
	AutoExecConfig(true, "merasmus");
	//CacheSounds();
	//CacheModels();

	if (LibraryExists("adminmenu"))
	{
		new Handle:topmenu = GetAdminTopMenu();
		if (topmenu != INVALID_HANDLE)
			OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
    SetupModel("models/bots/merasmus/merasmus.mdl", g_merasmusModel);

    g_bModelsPrecached = false;
    g_bSoundsPrecached = false;

	//CacheSounds();
	//CacheModels();
}

public Convar_Changer(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "merasmus")) != -1)
	{
		//sets scale/glow...works pretty well with scale...
		SetEntPropFloat(i, Prop_Send, "m_flModelScale", GetConVarFloat(g_Size));
		SetEntProp(i, Prop_Send, "m_bGlowEnabled", GetConVarFloat(g_Glow));
	}
}

CheckGame()
{
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (StrEqual(strModName, "tf")) return;
	SetFailState("[SM] This plugin is only for Team Fortress 2.");
}

public Action:Meras(client, args)
{
    if (g_bNativeOverride)
    {
        ReplyToCommand(client, "[SM] This command has been disabled by the server.");
        return Plugin_Handled;
    }
    else if (!(client > 0 && client <= MaxClients && IsClientInGame(client)))
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

    switch (SpawnMerasmus(client, iLevel, modelname))
    {
        case 0:
        {
            return  Plugin_Handled;
        }
        case 1:
        {
            ReplyToCommand(client, "[SM] Entity limit is reached. Can't spawn merasmus. Change maps.");
            return Plugin_Stop;
        }
        case 2:
        {
            ReplyToCommand(client, "[SM] Could not find spawn point.");
            return Plugin_Stop;
        }
        case 3:
        {
            ReplyToCommand(client, "[SM] Model is invalid. sm_merasmus [level] [modelname].");
            return Plugin_Stop;
        }
    }

    ReplyToCommand(client, "[SM] Unable to spawn merasmus!");
    return Plugin_Stop;
}
		
SpawnMerasmus(client, iLevel, const String:model[])
{
    if (GetEntityCount() >= GetMaxEntities()-32)
        return 1;

    if(!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return 2;
    }

    CacheModels(model);
    if (model[0] != '\0' && !IsModelPrecached(model))
        return 3;

    if (!g_bSoundsPrecached)
        CacheSounds();

    new entity = CreateEntityByName("merasmus");
    if (entity > 0 && IsValidEntity(entity))
    {
        if (DispatchSpawn(entity))
        {
            if (model[0] != '\0')
                SetEntityModel(entity, model);

            new bool:def = (iLevel < 0);
            if (def || iLevel > 1)
            {
                new iBaseHP = (def) ? GetConVarInt(v_HP_Base) : 17000;
                new iHPPerLevel = (def) ? 0 : 3000;
                new iHPPerPlayer = (def) ? GetConVarInt(v_HP_Per_Player) : 400;
                new iNumPlayers = GetClientCount(true);

                new iHP = iBaseHP;
                if (iHPPerLevel > 0)
                    iHP = (iHP + ((iLevel - 2) * iHPPerLevel));
                if (iNumPlayers > 10)
                    iHP = (iHP + ((iNumPlayers - 10)*iHPPerPlayer));

                SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHP);
                SetEntityHealth(entity, iHP);
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

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

CacheModels(const String:model[])
{
    if (!g_bModelsPrecached)
    {
        PrepareModel("models/bots/merasmus/merasmus.mdl", g_merasmusModel);
        //not sure if bombonomicon spawns or how it works yet
        //PrecacheModel("models/props_halloween/bombonomicon.mdl");
        g_bModelsPrecached = true;
    }

    if (model[0] != '\0')
        PrepareModel(model);
}

CacheSounds()
{
    //sooo much stuff to precache
    PrepareSound("vo/halloween_merasmus/sf12_appears01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears14.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears15.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears16.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_appears17.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_attacks01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_attacks11.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb14.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb17.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb19.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb23.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb24.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb25.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb26.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb28.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb29.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb30.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb31.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb32.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb33.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb34.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb35.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb36.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb37.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb38.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb39.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb40.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb41.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb42.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb44.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb45.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb46.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb47.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb48.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb49.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb50.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb51.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb52.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb53.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_headbomb54.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up12.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up14.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up15.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up17.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up18.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up19.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up20.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up21.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up24.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up25.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up27.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up28.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up29.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up30.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up31.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up32.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_held_up33.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_bcon_island02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_island03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_island04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_skullhat01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_skullhat02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bcon_skullhat03.wav", true, true);

    /*
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon14.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_bombinomicon15.wav", true, true);
    */

    PrepareSound("vo/halloween_merasmus/sf12_combat_idle01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_combat_idle02.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_defeated01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_defeated12.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_found01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_found02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_found03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_found04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_found05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_found07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_found08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_found09.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_grenades03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_grenades04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_grenades05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_grenades06.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit12.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit14.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit15.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit16.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit17.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit18.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit19.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit20.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit21.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit23.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit24.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit25.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_headbomb_hit26.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_hide_heal01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal12.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal14.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal15.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal16.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal17.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_heal19.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_hide_idles01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles12.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles14.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles15.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles16.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles18.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles20.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles21.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles22.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles23.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles24.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles25.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles26.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles27.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles28.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles29.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles30.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles31.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles33.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles27.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles41.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles42.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles44.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles46.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles47.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles48.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_hide_idles49.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_leaving01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving12.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_leaving16.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_magic_backfire06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_magic_backfire07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_magic_backfire23.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_magic_backfire29.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_magicwords11.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_pain01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_pain02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_pain03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_pain04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_pain05.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_ranged_attack04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_ranged_attack05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_ranged_attack06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_ranged_attack07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_ranged_attack08.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_staff_magic02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic12.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_staff_magic13.wav", true, true);

    /* Wheel might not need to be precached since it isn't being spawned

    PrepareSound("vo/halloween_merasmus/sf12_wheel_bighead01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bighead02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bighead03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bighead04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bighead05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bighead06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bighead07.wav", true, true);


    PrepareSound("vo/halloween_merasmus/sf12_wheel_bloody01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bloody02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bloody03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bloody04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_bloody05.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_crits02.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_dance02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_dance03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_dance04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_dance05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_dance06.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_fire01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_fire02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_fire03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_fire04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_fire05.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_ghosts01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_ghosts02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_ghosts03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_ghosts05.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_gravity01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_gravity02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_gravity03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_gravity04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_gravity05.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_happy04.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_invincible11.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_jarate01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_jarate02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_jarate03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_jarate04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_jarate05.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_jump01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_jump02.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_nonspecific04.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_scared01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_scared02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_scared03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_scared04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_scared06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_scared07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_scared08.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_speed01.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin06.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin07.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin08.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin09.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin10.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin11.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin12.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin13.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin15.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin18.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin19.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin21.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin22.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin23.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin24.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin25.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_spin26.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_tinyhead01.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_tinyhead02.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_tinyhead03.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_tinyhead04.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_tinyhead05.wav", true, true);
    PrepareSound("vo/halloween_merasmus/sf12_wheel_tinyhead06.wav", true, true);

    PrepareSound("vo/halloween_merasmus/sf12_wheel_ubercharge01.wav", true, true);
    */

    g_bSoundsPrecached = true;
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
					"sm_merasmus",
					TopMenuObject_Item,
					AdminMenu_Merasmus, 
					server_commands,
					"sm_merasmus",
					ADMFLAG_MERASMUS);
		}
	}
}

public AdminMenu_Merasmus(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Call forth the (not so) magnificent Merasmus!");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		Meras(param, 0);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Native
    CreateNative("ControlMerasmus",Native_Control);
    CreateNative("TF2_SpawnMerasmus",Native_SpawnMerasmus);
    RegPluginLibrary("merasmus");
    return APLRes_Success;
}

public Native_Control(Handle:plugin,numParams)
{
    g_bNativeOverride |= GetNativeCell(1);
}

public Native_SpawnMerasmus(Handle:plugin,numParams)
{
    decl String:model[PLATFORM_MAX_PATH+1];
    GetNativeString(3, model, sizeof(model));

    return SpawnMerasmus(GetNativeCell(1), GetNativeCell(2), model);
}

