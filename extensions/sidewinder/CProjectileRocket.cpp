#include "CProjectileRocket.h"

ConVar RocketHomingChance("sm_rocket_homingchance", "100", 0);
ConVar RocketSpeedMul("sm_rocket_speedmul", "1.0", 0);

DEFINE_PROP(m_bCritical, CProjectileRocket);

LINK_ENTITY_TO_CLASS(tf_projectile_rocket, CProjectileRocket);

/*
void CProjectileRocket::Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks)
{
	BaseClass::Init(pEdict, pBaseEntity, addHooks);
}
*/

void CProjectileRocket::Spawn(void)
{
	if (SetTracking(OnSeek(SidewinderRocket, ShouldSeek())))
		BaseClass::Spawn();
	else
		CEntity::Spawn();
}

TrackType CProjectileRocket::ShouldSeek(void)
{
	if (m_hOwnerEntity)
	{
		CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
		if (pOwner)
		{
			int index = pOwner->entindex();
			if (index > 0 && index < 64)
			{
				int flags = (g_ClientFlags[index] & RocketTypeBits);
				if (flags != DefaultRockets)
				{
					if ((flags & CritTrackerRockets))
						return TrackCrits;
					else if ((flags & TrackingRockets) &&
						 ((rand() % 100) <= g_ClientTrackChance[index]))
					{
						return TrackAll;
					}
					else
						return NoTrack;
				}
			}
		}
	}

	if (SideWinderCritTracker.GetInt() & SidewinderRocket)
		return TrackCrits;
	else if ((SideWinderEnabled.GetInt() & SidewinderRocket) &&
		 (rand() % 100) <= RocketHomingChance.GetInt())
	{
		return TrackAll;
	}
	else
		return NoTrack;
}

bool CProjectileRocket::IsCritical(void)
{
	return *m_bCritical;
}

void CProjectileRocket::SetCritical(bool bCritical)
{
	*m_bCritical = bCritical;
}

float CProjectileRocket::GetSpeedMultiplier()
{
	return RocketSpeedMul.GetFloat();
}
