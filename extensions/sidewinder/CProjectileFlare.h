#ifndef _INCLUDE_CPROJECTILEFLARE_H_
#define _INCLUDE_CPROJECTILEFLARE_H_

#include "CTrackingProjectile.h"

class CProjectileFlare : public CTrackingProjectile
{
public:
	DECLARE_CLASS(CProjectileFlare, CTrackingProjectile);

//	virtual void Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks);
	virtual void Spawn(void);

	virtual bool IsCritical(void);
	virtual void SetCritical(bool bCritical);
	virtual float GetSpeedMultiplier();

	TrackType ShouldSeek(void);

private:
	DECLARE_SENDPROP(bool, m_bCritical);
};


#endif // _INCLUDE_CPROJECTILEFLARE_H_
