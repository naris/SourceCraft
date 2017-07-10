#include "CProjectileSyringe.h"

ConVar SyringeHomingChance("sm_syringe_homingchance", "100", 0);
ConVar SyringeSpeedMul("sm_syringe_speedmul", "1.0", 0);

DEFINE_PROP(m_bCritical, CProjectileSyringe);

LINK_ENTITY_TO_CLASS(tf_projectile_syringe, CProjectileSyringe);

/*
void CProjectileSyringe::Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks)
{
	BaseClass::Init(pEdict, pBaseEntity, addHooks);
}
*/

void CProjectileSyringe::Spawn(void)
{
	if (SetTracking(OnSeek(SidewinderSyringe, ShouldSeek())))
		BaseClass::Spawn();
	else
		CEntity::Spawn();
}

TrackType CProjectileSyringe::ShouldSeek(void)
{
	if (m_hOwnerEntity)
	{
		CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
		if (pOwner)
		{
			int index = pOwner->entindex();
			if (index > 0 && index < 64)
			{
				int flags = (g_ClientFlags[index] & SyringeTypeBits);
				if (flags != DefaultSyringes)
				{
					if ((flags & CritTrackerSyringes))
						return TrackCrits;
					else if ((flags & TrackingSyringes) &&
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

	if (SideWinderCritTracker.GetInt() & SidewinderSyringe)
		return TrackCrits;
	else if ((SideWinderEnabled.GetInt() & SidewinderSyringe) &&
		 (rand() % 100) <= SyringeHomingChance.GetInt())
	{
		return TrackAll;
	}
	else
		return NoTrack;
}

bool CProjectileSyringe::IsCritical(void)
{
	return *m_bCritical;
}

void CProjectileSyringe::SetCritical(bool bCritical)
{
	*m_bCritical = bCritical;
}

float CProjectileSyringe::GetSpeedMultiplier()
{
	return SyringeSpeedMul.GetFloat();
}
