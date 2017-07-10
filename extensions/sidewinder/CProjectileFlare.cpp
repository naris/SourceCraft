#include "CProjectileFlare.h"

ConVar FlareHomingChance("sm_flare_homingchance", "100", 0);
ConVar FlareSpeedMul("sm_sentryrocket_speedmul", "1.0", 0);

DEFINE_PROP(m_bCritical, CProjectileFlare);

LINK_ENTITY_TO_CLASS(tf_projectile_flare, CProjectileFlare);

/*
void CProjectileFlare::Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks)
{
	BaseClass::Init(pEdict, pBaseEntity, addHooks);
}
*/

void CProjectileFlare::Spawn(void)
{
	if (SetTracking(OnSeek(SidewinderFlare, ShouldSeek())))
		BaseClass::Spawn();
	else
		CEntity::Spawn();
}

TrackType CProjectileFlare::ShouldSeek(void)
{
	if (m_hOwnerEntity)
	{
		CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
		if (pOwner)
		{
			int index = pOwner->entindex();
			if (index > 0 && index < 64)
			{
				int flags = (g_ClientFlags[index] & FlareTypeBits);
				if (flags != DefaultFlares)
				{
					if ((flags & CritTrackerFlares))
						return TrackCrits;
					else if ((flags & TrackingFlares) &&
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

	if (SideWinderCritTracker.GetInt() & SidewinderFlare)
		return TrackCrits;
	else if ((SideWinderEnabled.GetInt() & SidewinderFlare) &&
		 (rand() % 100) <= FlareHomingChance.GetInt())
	{
		return TrackAll;
	}
	else
		return NoTrack;
}

bool CProjectileFlare::IsCritical(void)
{
	return *m_bCritical;
}

void CProjectileFlare::SetCritical(bool bCritical)
{
	*m_bCritical = bCritical;
}

float CProjectileFlare::GetSpeedMultiplier()
{
	return FlareSpeedMul.GetFloat();
}
