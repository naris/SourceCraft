/**
 * vim: set ts=4 sw=4 :
 * =============================================================================
 * SourceMod Sample Extension
 * Copyright (C) 2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id: extension.cpp 249 2008-08-27 21:48:35Z pred $
 */

#include "extension.h"
#include <mathlib.h>
#include "sh_list.h"
#include "datamap.h"
#include "const.h"
#include "bspflags.h"
#include "convar.h"
#include "filesystem.h"
#include "CEntityManager.h"
#include "dt_send.h"

/**
 * @file extension.cpp
 * @brief Implement extension code here.
 */

Sidewinder g_Sidewinder;

SMEXT_LINK(&g_Sidewinder);

ICvar *icvar = NULL;

IGameConfig *g_pGameConf = NULL;

IServerGameEnts *gameents;

CGlobalVars *gpGlobals;

ConVar SideWinderVersion("sidewinder_version", "2.1.1", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, "Sidewinder Version");
ConVar SideWinderEnabled("sm_sidewinder_enabled", "63", 0);
ConVar SideWinderCritTracker("sm_sidewinder_crit_tracker", "63", 0);

ConVar *pTagsVar = NULL;

void *g_EntList = NULL;
int gMaxClients = 0;

/** hooks **/
SH_DECL_HOOK1_void(IServerGameClients, ClientDisconnect, SH_NOATTRIB, 0, edict_t *);
SH_DECL_HOOK2_void(IServerGameClients, ClientPutInServer, SH_NOATTRIB, 0, edict_t *, char const *);
SH_DECL_HOOK3_void(IServerGameDLL, ServerActivate, SH_NOATTRIB, 0, edict_t *, int, int)

SH_DECL_HOOK6(IServerGameDLL, LevelInit, SH_NOATTRIB, 0, bool, const char *, const char *, const char *, const char *, bool, bool);

/** SM forwards **/
IForward *g_fwdSidewinderSeek = NULL;

cell_t g_ClientFlags[64] = { 0 };
cell_t g_ClientTrackChance[64] = { 0 };
cell_t g_ClientSentryCritChance[64] = { 0 };

/** natives **/
cell_t Native_SidewinderControl(IPluginContext *pContext, const cell_t *params);
cell_t Native_SidewinderFlags(IPluginContext *pContext, const cell_t *params);
cell_t Native_SidewinderTrackChance(IPluginContext *pContext, const cell_t *params);
cell_t Native_SidewinderSentryCritChance(IPluginContext *pContext, const cell_t *params);
cell_t Native_SidewinderDesignateClient(IPluginContext *pContext, const cell_t *params);

cell_t Native_SidewinderCloakClient(IPluginContext *pContext, const cell_t *params);
cell_t Native_SidewinderDetectClient(IPluginContext *pContext, const cell_t *params);

const sp_nativeinfo_t SidewinderNatives[] = 
{
	{"SidewinderFlags",				Native_SidewinderFlags},
	{"SidewinderControl",			Native_SidewinderControl},
	{"SidewinderTrackChance",		Native_SidewinderTrackChance},
	{"SidewinderSentryCritChance",	Native_SidewinderSentryCritChance},
	{"SidewinderDesignateClient",	Native_SidewinderDesignateClient},
	{"SidewinderCloakClient",		Native_SidewinderCloakClient},
	{"SidewinderDetectClient",		Native_SidewinderDetectClient},
	{NULL,							NULL},
};

bool Sidewinder::SDK_OnLoad(char *error, size_t maxlength, bool late)
{
	char conf_error[255] = "";
	if (!gameconfs->LoadGameConfigFile("centity.offsets", &g_pGameConf, conf_error, sizeof(conf_error)))
	{
		if (conf_error[0])
		{
			g_pSM->Format(error, maxlength, "Could not read centity.offsets.txt: %s", conf_error);
		}
		return false;
	}

	GetEntityManager()->Init(g_pGameConf);

	return true;
}

void AddTag()
{
	if (pTagsVar == NULL)
	{
		return;
	}

	const char *curTags = pTagsVar->GetString();
	const char *ourTag = "supersentries";

	if (strstr(curTags, ourTag) != NULL)
	{
		/* Already tagged */
		return;
	}

	/* New tags buffer (+2 for , and null char) */
	int newLen = strlen(curTags) + strlen(ourTag) + 2;
	char *newTags = new char[newLen];

	g_pSM->Format(newTags, newLen, "%s,%s", curTags, ourTag);

	pTagsVar->SetValue(newTags);

	delete [] newTags;
}

bool LevelInitHook(char const *pMapName, 
				   char const *pMapEntities, char const *pOldLevel, 
				   char const *pLandmarkName, bool loadGame, bool background)
{
	if (SideWinderEnabled.GetInt() > 0)
	{
		AddTag();
	}

	return true;
}

bool Sidewinder::SDK_OnMetamodLoad(ISmmAPI *ismm, char *error, size_t maxlen, bool late)
{
	GET_V_IFACE_CURRENT(GetServerFactory, gameents, IServerGameEnts, INTERFACEVERSION_SERVERGAMEENTS);
	gpGlobals = ismm->GetCGlobals();

	GET_V_IFACE_CURRENT(GetEngineFactory, icvar, ICvar, CVAR_INTERFACE_VERSION);

	g_pCVar = icvar;
	pTagsVar = icvar->FindVar("sv_tags");

	SH_ADD_HOOK(IServerGameDLL, LevelInit, gamedll, LevelInitHook, true);
	
	ConVar_Register(0, this);

	// add standard plugin hooks
	SH_ADD_HOOK_MEMFUNC(IServerGameClients, ClientDisconnect, serverclients, &g_Sidewinder, &Sidewinder::ClientDisconnect, true);
	SH_ADD_HOOK_MEMFUNC(IServerGameClients, ClientPutInServer, serverclients, &g_Sidewinder, &Sidewinder::ClientPutInServer, true);
	SH_ADD_HOOK_MEMFUNC(IServerGameDLL, ServerActivate, gamedll, &g_Sidewinder, &Sidewinder::ServerActivate, true);

	return true;
}

bool Sidewinder::RegisterConCommandBase(ConCommandBase *pCommand)
{
	META_REGCVAR(pCommand);

	return true;
}

bool Sidewinder::SDK_OnMetamodUnload(char *error, size_t maxlength)
{
	SH_REMOVE_HOOK(IServerGameDLL, LevelInit, gamedll, LevelInitHook, true);

	// remove standard plugin hooks
	SH_REMOVE_HOOK_MEMFUNC(IServerGameClients, ClientDisconnect, serverclients, &g_Sidewinder, &Sidewinder::ClientDisconnect, true);
	SH_REMOVE_HOOK_MEMFUNC(IServerGameClients, ClientPutInServer, serverclients, &g_Sidewinder, &Sidewinder::ClientPutInServer, true);
	SH_REMOVE_HOOK_MEMFUNC(IServerGameDLL, ServerActivate, gamedll, &g_Sidewinder, &Sidewinder::ServerActivate, true);
	return true;
}

void Sidewinder::SDK_OnUnload()
{
	forwards->ReleaseForward(g_fwdSidewinderSeek);

}

void Sidewinder::SDK_OnAllLoaded()
{
	sharesys->AddNatives(myself, SidewinderNatives);
	ParamType p1[] = {Param_Cell, Param_Cell, Param_Cell, Param_CellByRef};
	
	g_fwdSidewinderSeek = forwards->CreateForward("OnSidewinderSeek", ET_Hook, 3, p1);
}

// *************************************************
// Standard MM:S Plugin Hooks
void Sidewinder::ServerActivate(edict_t *pEdictList, int edictCount, int clientMax)
{
	gMaxClients = clientMax;
	RETURN_META(MRES_IGNORED);
}

void Sidewinder::ClientPutInServer(edict_t *pEntity, char const *playername)
{
	IServerUnknown *unk = pEntity->GetUnknown();
	if (unk)
	{
		CBaseEntity *pBase = unk->GetBaseEntity();
		if (pBase)
		{
			int index = engine->IndexOfEdict(servergameents->BaseEntityToEdict(pBase));
			if (index > 0 && index < 64)
				g_ClientFlags[index] = 0;
		}
	}
	RETURN_META(MRES_IGNORED);
}

void Sidewinder::ClientDisconnect(edict_t *pEntity)
{
	IServerUnknown *unk = pEntity->GetUnknown();
	if (unk)
	{
		CBaseEntity *pBase = unk->GetBaseEntity();
		if (pBase)
		{
			int index = engine->IndexOfEdict(servergameents->BaseEntityToEdict(pBase));
			if (index > 0 && index < 64)
				g_ClientFlags[index] = 0;
		}
	}
	RETURN_META(MRES_IGNORED);
}

cell_t Native_SidewinderControl(IPluginContext *pContext, const cell_t *params)
{
	if (params[1])
	{
			SentryCrit.SetValue(false);
			SideWinderEnabled.SetValue(0);
			SideWinderCritTracker.SetValue(0);
	}
	else
	{
			SentryCrit.SetValue(params[2]);
			SideWinderEnabled.SetValue(params[3]);
			SideWinderCritTracker.SetValue(params[4]);
	}
	return 0;
}

cell_t Native_SidewinderSentryCritChance(IPluginContext *pContext, const cell_t *params)
{
	cell_t client = params[1];
	if (client >= 0 && client < 64)
			g_ClientSentryCritChance[client] = params[2];

	return 0;
}

cell_t Native_SidewinderTrackChance(IPluginContext *pContext, const cell_t *params)
{
	cell_t client = params[1];
	if (client >= 0 && client < 64)
			g_ClientTrackChance[client] = params[2];

	return 0;
}

cell_t Native_SidewinderFlags(IPluginContext *pContext, const cell_t *params)
{
	cell_t client = params[1];
	if (client >= 0 && client < 64)
	{
			if (params[3])
			{
				g_ClientFlags[client] |= (params[2] & (SentryRocketTypeBits|RocketTypeBits|
													   ArrowTypeBits|FlareTypeBits|
													   PipeTypeBits|SyringeTypeBits));
			}
			else
				g_ClientFlags[client] = params[2];
	}

	return 0;
}

cell_t Native_SidewinderDesignateClient(IPluginContext *pContext, const cell_t *params)
{
	cell_t client = params[1];
	if (client >= 0 && client < 64)
	{
			if (params[2])
				g_ClientFlags[client] |= ClientIsDesignated;
			else
				g_ClientFlags[client] &= ~ClientIsDesignated;
	}

	return 0;
}

cell_t Native_SidewinderCloakClient(IPluginContext *pContext, const cell_t *params)
{
	cell_t client = params[1];
	if (client >= 0 && client < 64)
	{
			if (params[2])
				g_ClientFlags[client] |= ClientIsCloaked;
			else
				g_ClientFlags[client] &= ~ClientIsCloaked;
	}

	return 0;
}

cell_t Native_SidewinderDetectClient(IPluginContext *pContext, const cell_t *params)
{
	cell_t client = params[1];
	if (client >= 0 && client < 64)
	{
			if (params[2])
				g_ClientFlags[client] |= ClientIsDetected;
			else
				g_ClientFlags[client] &= ~ClientIsDetected;
	}

	return 0;
}

