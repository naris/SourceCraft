#include "CProjectileArrow.h"

ConVar ArrowHomingChance("sm_arrow_homingchance", "100", 0);
ConVar ArrowSpeedMul("sm_arrow_speedmul", "1.0", 0);

DEFINE_PROP(m_bCritical, CProjectileArrow);

LINK_ENTITY_TO_CLASS(tf_projectile_arrow, CProjectileArrow);

/*
void CProjectileArrow::Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks)
{
	BaseClass::Init(pEdict, pBaseEntity, addHooks);
}
*/

void CProjectileArrow::Spawn(void)
{
	if (SetTracking(OnSeek(SidewinderArrow, ShouldSeek())))
		BaseClass::Spawn();
	else
		CEntity::Spawn();
}

TrackType CProjectileArrow::ShouldSeek(void)
{
	if (m_hOwnerEntity)
	{
		CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
		if (pOwner)
		{
			int index = pOwner->entindex();
			if (index > 0 && index < 64)
			{
				int flags = (g_ClientFlags[index] & ArrowTypeBits);
				if (flags != DefaultArrows)
				{
					if ((flags & CritTrackerArrows))
						return TrackCrits;
					else if ((flags & TrackingArrows) &&
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

	if (SideWinderCritTracker.GetInt() & SidewinderArrow)
		return TrackCrits;
	else if ((SideWinderEnabled.GetInt() & SidewinderArrow) &&
		 (rand() % 100) <= ArrowHomingChance.GetInt())
	{
		return TrackAll;
	}
	else
		return NoTrack;
}

bool CProjectileArrow::IsCritical(void)
{
	return *m_bCritical;
}

void CProjectileArrow::SetCritical(bool bCritical)
{
	*m_bCritical = bCritical;
}

float CProjectileArrow::GetSpeedMultiplier()
{
	return ArrowSpeedMul.GetFloat();
}
