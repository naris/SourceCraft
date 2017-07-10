#ifndef _INCLUDE_CPROJECTILEARROW_H_
#define _INCLUDE_CPROJECTILEARROW_H_

#include "CTrackingProjectile.h"

class CProjectileArrow : public CTrackingProjectile
{
public:
	DECLARE_CLASS(CProjectileArrow, CTrackingProjectile);

//	virtual void Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks);
	virtual void Spawn(void);

	virtual bool IsCritical(void);
	virtual void SetCritical(bool bCritical);
	virtual float GetSpeedMultiplier();

	TrackType ShouldSeek(void);

private:
	DECLARE_SENDPROP(bool, m_bCritical);
};


#endif // _INCLUDE_CPROJECTILEARROW_H_
