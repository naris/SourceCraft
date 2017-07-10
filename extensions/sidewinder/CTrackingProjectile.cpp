#include "extension.h"
#include "CSentryRocket.h"
#include "CPlayer.h"
#include "worldsize.h"

SH_DECL_MANUALEXTERN3(FVisible, bool, CBaseEntity *, int, CBaseEntity **);

/*
void CTrackingProjectile::Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks)
{
	m_bCritical = false;
	m_bHasThought = false;
	m_Projectile = 0;
	m_baseSpeed = 0.0;

//	BaseClass::Init(pEdict, pBaseEntity, addHooks);
	BaseClass::Init(pEdict, pBaseEntity);

//	ADD_DEFAULTHANDLER_HOOK(CTrackingProjectile, FVisible);

	sm_sendprop_info_t info;
	GET_SENDPROP_POINTER(bool, m_pEdict, BaseEntity(), &info, m_bCritical);
}
*/

void CTrackingProjectile::Init(edict_t *pEdict, CBaseEntity *pBaseEntity)
{
	BaseClass::Init(pEdict, pBaseEntity);

	m_baseSpeed = 0.0;
	m_bSpawning = false;
	m_Projectile = 0;
	m_bHasThought = false;
}

void CTrackingProjectile::Spawn(void)
{
 	BaseClass::Spawn();

	m_bSpawning = true;

	SetThink(&CTrackingProjectile::FindThink);
	SetNextThink(gpGlobals->curtime); 
}

void CTrackingProjectile::FindThink(void)
{
	if (m_bSpawning)
	{
		Vector rocketVec = GetAbsVelocity();
		vec_t speed = rocketVec.Length();
		m_baseSpeed = speed;
		speed *= GetSpeedMultiplier();
		rocketVec.NormalizeInPlace();

		rocketVec *= speed;

		Teleport(NULL, NULL, &rocketVec);
		m_bSpawning = false;
	}

	CEntity *pBestVictim = NULL;
	float flBestVictim = MAX_TRACE_LENGTH;
	float flVictimDist;
	bool bBestDesignated = false;
	bool bVictimDesignated = false;

	CBaseEntity *pBaseEntity = NULL;

	if (!m_bHasThought)
	{
		m_bHasThought = true;
		if (m_Tracking == TrackCrits)
			m_Tracking = OnSeek(m_Projectile, m_Tracking);
	}

	if (m_Tracking != TrackCrits || IsCritical())
	{
		for (int index = 1; index <= gpGlobals->maxClients; index++)
		{
			CEntity *pEntity = CEntity::Instance(index);

			if (!IsValidTarget(pEntity, bVictimDesignated))
			{
				continue;
			}

			flVictimDist = (GetLocalOrigin() - pEntity->GetLocalOrigin()).Length();

			//Find closest
			if ((flVictimDist < flBestVictim && (bVictimDesignated || !bBestDesignated))
				|| (bVictimDesignated && !bBestDesignated))
			{
				pBestVictim = pEntity;
				flBestVictim = flVictimDist;
				bBestDesignated = bVictimDesignated;
			}
		}
	}

	if (pBestVictim == NULL) 
	{
		SetThink(&CTrackingProjectile::FindThink);
		SetNextThink(gpGlobals->curtime);
		return;
	}

	TurnToTarget(pBestVictim);

	m_currentTarget = pBestVictim->entindex();
	SetThink(&CTrackingProjectile::TrackThink);
	SetNextThink(gpGlobals->curtime);
	m_lastSearch = gpGlobals->curtime;
}

void CTrackingProjectile::TrackThink(void)
{
	CEntity *pVictim = CEntity::Instance(m_currentTarget);

	bool designated;
	if (!IsValidTarget(pVictim, designated))
	{
		/* This finds a new target and aims at it, or starts looping find until it does */
		FindThink();
		return;
	}

	TurnToTarget(pVictim);

	if (gpGlobals->curtime > 0.1 + m_lastSearch)
	{
		SetThink(&CTrackingProjectile::FindThink);
		SetNextThink(gpGlobals->curtime);	
	}
	else
	{
		SetThink(&CTrackingProjectile::TrackThink);
		SetNextThink(gpGlobals->curtime);
	}
}

bool CTrackingProjectile::IsValidTarget(CEntity *pEntity, bool &designated)
{
	designated = false;

	if(!pEntity)
		return false;

	if(!pEntity->IsPlayer())
		return false;

	CPlayer *pPlayer = static_cast<CPlayer *>(pEntity);

	if(!pPlayer->IsAlive())
		return false;

	int flags;
	int index = pPlayer->entindex();
	if (index > 0 && index < 64)
	{
		flags = g_ClientFlags[index];
		if ((flags & ClientIsCloaked) && !(flags & ClientIsDetected))
			return false;
		else if ((flags & ClientIsDesignated) && pEntity->GetTeam() != GetTeam())
		{
			designated = true;
			return true;
		}
	}
	else
		flags = 0;

	if (pPlayer->GetPlayerClass() == PLAYERCLASS_SPY) 
	{
		//Cloaky
		if (pPlayer->GetPlayerCond() & PLAYERCOND_SPYCLOAK)
			return false;

		//Disguised
		if (pPlayer->IsDisguised() && pPlayer->GetDisguisedTeam() == GetTeam())
			return false;
	}

//	if (pEntity->GetTeam() != GetTeam() && FVisible(pEntity->BaseEntity(), MASK_OPAQUE, NULL))
	if(pEntity->GetTeam() != GetTeam() && pPlayer->FVisible(BaseEntity(), MASK_OPAQUE, NULL))
		return true;

	return false;
}

void CTrackingProjectile::TurnToTarget(CEntity *pEntity)
{
	Vector targetLocation = pEntity->GetLocalOrigin();
	Vector rocketLocation = GetLocalOrigin();

	Vector rocketVec = GetAbsVelocity();
//	vec_t speed = 1100.0 * RocketSpeedMul.GetFloat();
	vec_t speed = GetBaseSpeed() * GetSpeedMultiplier();

	Vector locationToTarget = targetLocation;
	locationToTarget.z += 50;
	Vector newVec = locationToTarget - rocketLocation;
	newVec.NormalizeInPlace();

	QAngle angles;
	VectorAngles(newVec, angles);

	newVec *= speed;

	Teleport(NULL, &angles, &newVec);
}

TrackType CTrackingProjectile::OnSeek(cell_t projectile, TrackType value)
{
	if ((value != TrackCrits || m_bHasThought) &&
	    g_fwdSidewinderSeek->GetFunctionCount() > 0)
	{
		if (m_hOwnerEntity)
		{
			CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
			if (pOwner)
			{
				int index = pOwner->entindex();
				if (index > 0 && index < 64)
				{
					cell_t result = 0;
					g_fwdSidewinderSeek->PushCell(index);
					g_fwdSidewinderSeek->PushCell(projectile);
					g_fwdSidewinderSeek->PushCell(IsCritical());
					g_fwdSidewinderSeek->PushCellByRef(reinterpret_cast<cell_t*>(&value));
					g_fwdSidewinderSeek->Execute(&result);

					// block Seeking
					if (result==Pl_Handled || result==Pl_Stop)
						return NoTrack;
				}
			}
		}
	}
	m_Projectile = projectile;
	return value;
}

bool CTrackingProjectile::IsCritical(void)
{
	return false; //(m_bCritical) ? *m_bCritical : false;
}

void CTrackingProjectile::SetCritical(bool bCritical)
{
	//if (m_bCritical)
	//	*m_bCritical = bCritical;
}

bool CTrackingProjectile::SetTracking(TrackType type)
{
	m_Tracking = type;
	return (type != NoTrack);
}

float CTrackingProjectile::GetSpeedMultiplier()
{
	return 1.0;
}

float CTrackingProjectile::GetBaseSpeed()
{
	return m_baseSpeed;
}

//DECLARE_DEFAULTHANDLER(CTrackingProjectile, FVisible, bool, (CBaseEntity *pEntity, int traceMask, CBaseEntity **ppBlocker), (pEntity, traceMask, ppBlocker));
