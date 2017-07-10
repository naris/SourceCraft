#ifndef _INCLUDE_CPROJECTILESYRINGE_H_
#define _INCLUDE_CPROJECTILESYRINGE_H_

#include "CTrackingProjectile.h"

class CProjectileSyringe : public CTrackingProjectile
{
public:
	DECLARE_CLASS(CProjectileSyringe, CTrackingProjectile);

//	virtual void Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks);
	virtual void Spawn(void);

	virtual bool IsCritical(void);
	virtual void SetCritical(bool bCritical);
	virtual float GetSpeedMultiplier();

	TrackType ShouldSeek(void);

private:
	DECLARE_SENDPROP(bool, m_bCritical);
};


#endif // _INCLUDE_CPROJECTILESYRINGE_H_
