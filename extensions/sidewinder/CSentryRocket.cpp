#include "CSentryRocket.h"

ConVar SentryCrit("sm_sentryrocket_crit", "1", 0);
ConVar SentryCritChance("sm_sentryrocket_critchance", "100", 0);
ConVar SentryHomingChance("sm_sentryrocket_homingchance", "100", 0);
ConVar SentryRocketSpeedMul("sm_sentryrocket_speedmul", "1.0", 0);

DEFINE_PROP(m_bCritical, CSentryRocket);

LINK_ENTITY_TO_CLASS(tf_projectile_sentryrocket, CSentryRocket);

/*
void CSentryRocket::Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks)
{
	BaseClass::Init(pEdict, pBaseEntity, addHooks);
}
*/

void CSentryRocket::Spawn(void)
{
	if (SetTracking(OnSeek(SidewinderSentry, ShouldSeek())))
		BaseClass::Spawn();
	else
		CEntity::Spawn();

	if (m_hOwnerEntity)
	{
		CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
		if (pOwner)
		{
			int index = pOwner->entindex();
			if (index > 0 && index < 64)
			{
				int flags = (g_ClientFlags[index] & SentryRocketTypeBits);
				if (flags != DefaultRockets)
				{
					if ((flags & CritSentryRockets))
					{
						if (( rand() % 100) < g_ClientSentryCritChance[index])
							SetCritical(true);
					}
					return;
				}
			}
		}
	}

	if (SentryCrit.GetBool())
	{
		if (( rand() % 100) <= SentryCritChance.GetInt())
			SetCritical(true);
	}
}

TrackType CSentryRocket::ShouldSeek(void)
{
	if (m_hOwnerEntity)
	{
		CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
		if (pOwner)
		{
			int index = pOwner->entindex();
			if (index > 0 && index < 64)
			{
				int flags = (g_ClientFlags[index] & SentryRocketTypeBits);
				if (flags != DefaultRockets)
				{
					if ((flags & CritTrackerSentryRockets))
						return TrackCrits;
					else if ((flags & TrackingSentryRockets) &&
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

	if (SideWinderCritTracker.GetInt() & SidewinderSentry)
		return TrackCrits;
	else if ((SideWinderEnabled.GetInt() & SidewinderSentry) &&
		 (rand() % 100) <= SentryHomingChance.GetInt())
	{
		return TrackAll;
	}
	else
		return NoTrack;
}

bool CSentryRocket::IsCritical(void)
{
	return *m_bCritical;
}

void CSentryRocket::SetCritical(bool bCritical)
{
	*m_bCritical = bCritical;
}

float CSentryRocket::GetSpeedMultiplier()
{
	return SentryRocketSpeedMul.GetFloat();
}
