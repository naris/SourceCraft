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
*
* CEntity Entity Handling Framework version 1.0 by Matt 'pRED*' Woodrow
*
* - Credits:
*		- This is largely (or entirely) based on a concept by voogru - http://voogru.com/
*		- The virtual function hooking is powered by the SourceHook library by Pavol "PM OnoTo" Marko.
*
* - About:
*		- CEntity is (and its derived classes are) designed to emulate the CBaseEntity class from the HL2 SDK.
*		- Valve code (like entire class definitions and CBaseEntity functions) from the SDK should almost just work when copied into this.
*			- References to CBaseEntity need to be changed to CEntity.
*			- Sendprops and datamaps are pointers to the actual values so references to these need to be dereferenced.
*				- Code that uses unexposed data members won't work - Though you could reimplement these manually.
*		- Virtual functions handle identically to ones in a real derived class.
*			- Calls from valve code to a virtual in CEntity (with no derived versions) fall back directly to the valve code.
*			- Calls from valve code to a virtual (with a derived version) will call that code, and the valve code can be optionally run using BaseClass::Function().
*
*			- Calls from your code to a virtual in CEntity (with no derived versions) will make a call to the valve code.
*			- Calls from your code to a virtual (with a derived version) will call that code, and the valve code can be optionally run using BaseClass::Function().
*			
*
* - Notes:
*		- If you inherit Init() or Destroy() in a derived class, I would highly recommend calling the BaseClass equivalent.
* 
* - TODO (in no particular order):
*		- Add handling of custom keyvalues commands
*			- Add datamapping to class values so keyvalues can parse to them
*		- Add handling of Inputs
*		- Include more CEntity virtuals and props/datamaps
*		- Create more derived classes
*		- Include more Think/Touch etc handlers
*			- Can we access the actual valve internal m_pfnThink somehow
*			- Valve code now has lists of thinks, can we access this?
*		- Forcibly deleting entities?
*		- Handling of custom entity names in Create
*			- Requires a pre-hook to switch out the custom string with one it can actually handle
*				- Probably need a new LINK_ENTITY_TO_CUSTOM_CLASS to define which real entity name to use instead
*			- Need to hook FindFactory and return the matched real entity factory so CanCreate (sp?) will succeed.
*		- Support mods other than TF2 (CPlayer should only contain CBasePlayer sdk stuff and create optional CTFPlayer/CCSPlayer derives)
*
*	- Change log
*		- 1.0
*			- Initial import of basic CEntity and CPlayer
*/

#ifndef _INCLUDE_CENTITY_H_
#define _INCLUDE_CENTITY_H_

#include "extension.h"
#include "IEntityFactory.h"
#include "vector.h"
#include "server_class.h"
#include "macros.h"

#include "../game/shared/ehandle.h"
class CBaseEntity;
typedef CHandle<CBaseEntity> EHANDLE;
#include "../game/shared/takedamageinfo.h"
#include "vphysics_interface.h"
#include <typeinfo>
#include <../server/variant_t.h>

extern variant_t g_Variant;

class CEntity;

#define DECLARE_DEFAULTHEADER(name, ret, params) \
	ret Internal##name params; \
	bool m_bIn##name;

#define SetThink(a) ThinkSet(static_cast <void (CEntity::*)(void)> (a), 0, NULL)
typedef void (CEntity::*BASEPTR)(void);

class CEntity // : public CBaseEntity  - almost.
{
public: // CEntity
	DECLARE_CLASS_NOBASE(CEntity);

	virtual void Init(edict_t *pEdict, CBaseEntity *pBaseEntity);
	void InitHooks();
	void InitProps();
	void ClearFlags();
	virtual void Destroy();
	CBaseEntity *BaseEntity();

public: // CBaseEntity virtuals
	virtual void Teleport(const Vector *origin, const QAngle* angles, const Vector *velocity);
	virtual void UpdateOnRemove();
	virtual void Spawn();
	virtual int OnTakeDamage(const CTakeDamageInfo &info);
	virtual void Think();
	virtual bool AcceptInput(const char *szInputName, CBaseEntity *pActivator, CBaseEntity *pCaller, variant_t Value, int outputID);

public: // CBaseEntity non virtual helpers
	BASEPTR	ThinkSet(BASEPTR func, float thinkTime, const char *szContext);
	void SetNextThink(float thinkTime, const char *szContext = NULL);
	void CheckHasThinkFunction(bool isThinking);
	bool WillThink();

	void AddEFlags(int nEFlagMask);
	void RemoveEFlags(int nEFlagMask);
	bool IsEFlagSet(int nEFlagMask) const;

	const char* GetClassname();

	int GetTeamNumber()  const;
	virtual void ChangeTeam(int iTeamNum);
	bool InSameTeam(CEntity *pEntity) const;

	const Vector &GetLocalOrigin() const;
	const Vector &GetAbsVelocity() const;
	const Vector &GetVelocity() const;

	CEntity *GetMoveParent();

	edict_t *edict();
	int entindex();

	static CEntity *Instance(const CBaseHandle &hEnt);
	static CEntity *Instance(const edict_t *pEnt);
	static CEntity *Instance(edict_t *pEnt);
	static CEntity* Instance(int iEnt);
	static CEntity* Instance(CBaseEntity *pEnt);

	virtual	bool IsPlayer();
	int GetTeam();

public: // All the internal hook implementations for the above virtuals
	DECLARE_DEFAULTHEADER(Teleport, void, (const Vector *origin, const QAngle* angles, const Vector *velocity));
	DECLARE_DEFAULTHEADER(UpdateOnRemove, void, ());
	DECLARE_DEFAULTHEADER(Spawn, void, ());
	DECLARE_DEFAULTHEADER(OnTakeDamage, int, (const CTakeDamageInfo &info));
	DECLARE_DEFAULTHEADER(Think, void, ());
	DECLARE_DEFAULTHEADER(AcceptInput, bool, (const char *szInputName, CBaseEntity *pActivator, CBaseEntity *pCaller,variant_t Value, int outputID));

protected: // CEntity
	CBaseEntity *m_pEntity;
	edict_t *m_pEdict;

protected: //Sendprops
	DECLARE_SENDPROP(uint8_t, m_iTeamNum);
	DECLARE_SENDPROP(Vector, m_vecOrigin);
	DECLARE_SENDPROP(uint8_t, m_CollisionGroup);
	DECLARE_SENDPROP(CBaseHandle, m_hOwnerEntity);
	DECLARE_SENDPROP(uint16_t, m_fFlags);

protected: //Datamaps
	DECLARE_DATAMAP(Vector, m_vecAbsVelocity);
	DECLARE_DATAMAP(string_t, m_iClassname);
	DECLARE_DATAMAP(matrix3x4_t, m_rgflCoordinateFrame);
	DECLARE_DATAMAP(Vector, m_vecVelocity);
	DECLARE_DATAMAP(Vector, m_vecAngVelocity);
	DECLARE_DATAMAP(Vector, m_vecBaseVelocity);
	DECLARE_DATAMAP(CBaseHandle, m_hMoveParent);
	DECLARE_DATAMAP(int, m_iEFlags);
	DECLARE_DATAMAP(IPhysicsObject *, m_pPhysicsObject);
	DECLARE_DATAMAP(int, m_nNextThinkTick);

	/* Thinking Stuff */
	void (CEntity::*m_pfnThink)(void);
};


#endif // _INCLUDE_CENTITY_H_
