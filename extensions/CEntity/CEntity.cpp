/**
* vim: set ts=4 :
* =============================================================================
* CEntity Entity Handling Framework
* Copyright (C) 2009 Matt Woodrow.  All rights reserved.
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
*/

#include "CEntity.h"
#include "../game/shared/shareddefs.h"
#include "CEntityManager.h"

CEntity *pEntityData[MAX_EDICTS+1] = {NULL};

IHookTracker *IHookTracker::m_Head = NULL;
IPropTracker *IPropTracker::m_Head = NULL;

SH_DECL_MANUALHOOK3_void(Teleport, 0, 0, 0, const Vector *, const QAngle *, const Vector *);
SH_DECL_MANUALHOOK0_void(UpdateOnRemove, 0, 0, 0);
SH_DECL_MANUALHOOK0_void(Spawn, 0, 0, 0);
SH_DECL_MANUALHOOK1(OnTakeDamage, 0, 0, 0, int, const CTakeDamageInfo &);
SH_DECL_MANUALHOOK0_void(Think, 0, 0, 0);
SH_DECL_MANUALHOOK5(AcceptInput, 0, 0, 0, bool, const char *, CBaseEntity *, CBaseEntity *, variant_t, int);

DECLARE_HOOK(Teleport, CEntity);
DECLARE_HOOK(UpdateOnRemove, CEntity);
DECLARE_HOOK(Spawn, CEntity);
DECLARE_HOOK(OnTakeDamage, CEntity);
DECLARE_HOOK(Think, CEntity);
DECLARE_HOOK(AcceptInput, CEntity);

//Sendprops
DEFINE_PROP(m_iTeamNum, CEntity);
DEFINE_PROP(m_vecOrigin, CEntity);
DEFINE_PROP(m_CollisionGroup, CEntity);
DEFINE_PROP(m_hOwnerEntity, CEntity);
DEFINE_PROP(m_fFlags, CEntity);
DEFINE_PROP(m_vecVelocity, CEntity);

//Datamaps
DEFINE_PROP(m_vecAbsVelocity, CEntity);
DEFINE_PROP(m_nNextThinkTick, CEntity);
DEFINE_PROP(m_iClassname, CEntity);
DEFINE_PROP(m_rgflCoordinateFrame, CEntity);
DEFINE_PROP(m_vecAngVelocity, CEntity);
DEFINE_PROP(m_vecBaseVelocity, CEntity);
DEFINE_PROP(m_hMoveParent, CEntity);
DEFINE_PROP(m_iEFlags, CEntity);
DEFINE_PROP(m_pPhysicsObject, CEntity);


LINK_ENTITY_TO_CLASS(baseentity, CEntity);

variant_t g_Variant;

void CEntity::Init(edict_t *pEdict, CBaseEntity *pBaseEntity)
{
	m_pEntity = pBaseEntity;
	m_pEdict = pEdict;

	assert(!pEntityData[entindex()]);

	pEntityData[entindex()] = this;

	if(!m_pEntity || !m_pEdict)
		return;

	m_pfnThink = NULL;
}

void CEntity::Destroy()
{
	pEntityData[entindex()] = NULL;
	delete this;
}

CBaseEntity * CEntity::BaseEntity()
{
	return m_pEntity;
}

/* Expanded handler for readability and since this one actually does something */
void CEntity::UpdateOnRemove()
{
	if (!m_bInUpdateOnRemove)
	{
		SH_MCALL(BaseEntity(), UpdateOnRemove);
		return;
	}

	SET_META_RESULT(MRES_IGNORED);

	SH_GLOB_SHPTR->DoRecall();
	SourceHook::EmptyClass *thisptr = reinterpret_cast<SourceHook::EmptyClass*>(SH_GLOB_SHPTR->GetIfacePtr());
	(thisptr->*(__SoureceHook_FHM_GetRecallMFPUpdateOnRemove(thisptr)))();

	SET_META_RESULT(MRES_SUPERCEDE);
}

void CEntity::InternalUpdateOnRemove()
{
	SET_META_RESULT(MRES_SUPERCEDE);

	CEntity *pEnt = CEntity::Instance(META_IFACEPTR(CBaseEntity));
	if (!pEnt)
	{
		RETURN_META(MRES_IGNORED);
	}

	pEnt->m_bInUpdateOnRemove = true;
	pEnt->UpdateOnRemove();
	pEnt->m_bInUpdateOnRemove = false;

	pEnt->Destroy();
}

DECLARE_DEFAULTHANDLER_void(CEntity, Teleport, (const Vector *origin, const QAngle* angles, const Vector *velocity), (origin, angles, velocity));
DECLARE_DEFAULTHANDLER_void(CEntity, Spawn, (), ());
DECLARE_DEFAULTHANDLER(CEntity, OnTakeDamage, int, (const CTakeDamageInfo &info), (info));

void CEntity::Think()
{
	if (m_pfnThink)
	{
		(this->*m_pfnThink)();
	}

	if (!m_bInThink)
	{
		SH_MCALL(BaseEntity(), Think)();
		return;
	}

	SET_META_RESULT(MRES_IGNORED);
	SH_GLOB_SHPTR->DoRecall();
	SourceHook::EmptyClass *thisptr = reinterpret_cast<SourceHook::EmptyClass*>(SH_GLOB_SHPTR->GetIfacePtr());
	(thisptr->*(__SoureceHook_FHM_GetRecallMFPThink(thisptr)))();
	SET_META_RESULT(MRES_SUPERCEDE);
}

void CEntity::InternalThink()
{
	SET_META_RESULT(MRES_SUPERCEDE);

	CEntity *pEnt = CEntity::Instance(META_IFACEPTR(CBaseEntity));
	if (!pEnt)
	{
		RETURN_META(MRES_IGNORED);
	}

	pEnt->m_bInThink = true;
	pEnt->Think();
	pEnt->m_bInThink = false;
}


BASEPTR	CEntity::ThinkSet(BASEPTR func, float thinkTime, const char *szContext)
{
	return m_pfnThink = func;
}

void CEntity::SetNextThink(float thinkTime, const char *szContext)
{
	int thinkTick = ( thinkTime == TICK_NEVER_THINK ) ? TICK_NEVER_THINK : TIME_TO_TICKS(thinkTime);

	// Are we currently in a think function with a context?
	if ( !szContext )
	{
		// Old system
		*m_nNextThinkTick = thinkTick;
		CheckHasThinkFunction( thinkTick == TICK_NEVER_THINK ? false : true );
		return;
	}
}

void CEntity::AddEFlags(int nEFlagMask)
{
	*m_iEFlags |= nEFlagMask;
}

void CEntity::RemoveEFlags(int nEFlagMask)
{
	*m_iEFlags &= ~nEFlagMask;
}

bool CEntity::IsEFlagSet(int nEFlagMask) const
{
	return (*m_iEFlags & nEFlagMask) != 0;
}

void CEntity::CheckHasThinkFunction(bool isThinking)
{
	if ( IsEFlagSet( EFL_NO_THINK_FUNCTION ) && isThinking )
	{
		RemoveEFlags( EFL_NO_THINK_FUNCTION );
	}
	else if ( !isThinking && !IsEFlagSet( EFL_NO_THINK_FUNCTION ) && !WillThink() )
	{
		AddEFlags( EFL_NO_THINK_FUNCTION );
	}
}

bool CEntity::WillThink()
{
	if (*m_nNextThinkTick > 0)
		return true;

	return false;
}

const char* CEntity::GetClassname()
{
	return STRING(*m_iClassname);
}

void CEntity::ChangeTeam(int iTeamNum)
{
	*m_iTeamNum = iTeamNum;
}

int CEntity::GetTeamNumber(void) const
{
	return *m_iTeamNum;
}

bool CEntity::InSameTeam(CEntity *pEntity) const
{
	if (!pEntity)
		return false;

	return (pEntity->GetTeamNumber() == GetTeamNumber());
}

const Vector& CEntity::GetLocalOrigin(void) const
{
	return *m_vecOrigin;
}

const Vector &CEntity::GetAbsVelocity() const
{
	if (IsEFlagSet(EFL_DIRTY_ABSVELOCITY))
	{
		//const_cast<CEntity*>(this)->CalcAbsoluteVelocity();
	}
	return *m_vecAbsVelocity;
}

const Vector & CEntity::GetVelocity() const
{
	return *m_vecVelocity;
}

CEntity *CEntity::GetMoveParent(void)
{
	return Instance(*m_hMoveParent); 
}

edict_t *CEntity::edict()
{
	return m_pEdict;
}

int CEntity::entindex()
{
	return engine->IndexOfEdict(edict());
}

CEntity *CEntity::Instance(CBaseEntity *pEnt)
{
	edict_t *pEdict = gameents->BaseEntityToEdict(META_IFACEPTR(CBaseEntity));
	
	if (!pEdict)
	{
		return NULL;
	}

	return Instance(pEdict);
}

CEntity *CEntity::Instance(int iEnt)
{
	return pEntityData[iEnt];
}

CEntity *CEntity::Instance(const edict_t *pEnt)
{
	return Instance(engine->IndexOfEdict(pEnt));
}

CEntity *CEntity::Instance(const CBaseHandle &hEnt)
{
	if (!hEnt.IsValid())
	{
		return NULL;
	}

	int index = hEnt.GetEntryIndex();

	edict_t *pStoredEdict;
	CBaseEntity *pStoredEntity;

	pStoredEdict = engine->PEntityOfEntIndex(index);
	if (!pStoredEdict || pStoredEdict->IsFree())
	{
		return NULL;
	}

	IServerUnknown *pUnk;
	if ((pUnk = pStoredEdict->GetUnknown()) == NULL)
	{
		return NULL;
	}

	pStoredEntity = pUnk->GetBaseEntity();

	if (pStoredEntity == NULL)
	{
		return NULL;
	}

	IServerEntity *pSE = pStoredEdict->GetIServerEntity();

	if (pSE == NULL)
	{
		return NULL;
	}

	if (pSE->GetRefEHandle() != hEnt)
	{
		return NULL;
	}

	return Instance(index);
}

CEntity *CEntity::Instance(edict_t *pEnt)
{
	return Instance(engine->IndexOfEdict(pEnt));
}

bool CEntity::IsPlayer()
{
	return false;
}

int CEntity::GetTeam()
{
	return *m_iTeamNum;
}

DECLARE_DEFAULTHANDLER(CEntity, AcceptInput, bool, (const char *szInputName, CBaseEntity *pActivator, CBaseEntity *pCaller, variant_t Value, int outputID), (szInputName, pActivator, pCaller, Value, outputID));

void CEntity::InitHooks()
{
	IHookTracker *pTracker = IHookTracker::m_Head;
	while (pTracker)
	{
		pTracker->AddHook(this);
		pTracker = pTracker->m_Next;
	}
}

void CEntity::InitProps()
{
	IPropTracker *pTracker = IPropTracker::m_Head;
	while (pTracker)
	{
		pTracker->InitProp(this);
		pTracker = pTracker->m_Next;
	}
}

void CEntity::ClearFlags()
{
	IHookTracker *pTracker = IHookTracker::m_Head;
	while (pTracker)
	{
		pTracker->ClearFlag(this);
		pTracker = pTracker->m_Next;
	}
}
