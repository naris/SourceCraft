#ifndef _INCLUDE_CPROJECTILEROCKET_H_
#define _INCLUDE_CPROJECTILEROCKET_H_

#include "CTrackingProjectile.h"

class CProjectileRocket : public CTrackingProjectile
{
public:
	DECLARE_CLASS(CProjectileRocket, CTrackingProjectile);

//	virtual void Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks);
	virtual void Spawn(void);


	virtual bool IsCritical(void);
	virtual void SetCritical(bool bCritical);
	virtual float GetSpeedMultiplier();
	TrackType ShouldSeek(void);

private:
	DECLARE_SENDPROP(bool, m_bCritical);
};


#endif // _INCLUDE_CPROJECTILEROCKET_H_
