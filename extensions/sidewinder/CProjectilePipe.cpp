#include "CProjectilePipe.h"

ConVar PipeHomingChance("sm_pipe_homingchance", "100", 0);
ConVar PipeSpeedMul("sm_pipe_speedmul", "1.0", 0);

DEFINE_PROP(m_bCritical, CProjectilePipe);

LINK_ENTITY_TO_CLASS(tf_projectile_pipe, CProjectilePipe);

/*
void CProjectilePipe::Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks)
{
	BaseClass::Init(pEdict, pBaseEntity, addHooks);
}
*/

void CProjectilePipe::Spawn(void)
{
	if (SetTracking(OnSeek(SidewinderPipe, ShouldSeek())))
		BaseClass::Spawn();
	else
		CEntity::Spawn();
}

TrackType CProjectilePipe::ShouldSeek(void)
{
	if (m_hOwnerEntity)
	{
		CEntity *pOwner = CEntity::Instance(*m_hOwnerEntity);
		if (pOwner)
		{
			int index = pOwner->entindex();
			if (index > 0 && index < 64)
			{
				int flags = (g_ClientFlags[index] & PipeTypeBits);
				if (flags != DefaultPipes)
				{
					if ((flags & CritTrackerPipes))
						return TrackCrits;
					else if ((flags & TrackingPipes) &&
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

	if (SideWinderCritTracker.GetInt() & SidewinderPipe)
		return TrackCrits;
	else if ((SideWinderEnabled.GetInt() & SidewinderPipe) &&
		 (rand() % 100) <= PipeHomingChance.GetInt())
	{
		return TrackAll;
	}
	else
		return NoTrack;
}

bool CProjectilePipe::IsCritical(void)
{
	return *m_bCritical;
}

void CProjectilePipe::SetCritical(bool bCritical)
{
	*m_bCritical = bCritical;
}

float CProjectilePipe::GetSpeedMultiplier()
{
	return PipeSpeedMul.GetFloat();
}
