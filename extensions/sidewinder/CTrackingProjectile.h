#ifndef _INCLUDE_CTRACKINGPROJECTILE_H_
#define _INCLUDE_CTRACKINGPROJECTILE_H_

#include "CEntityManager.h"
#include "CEntity.h"

enum TrackType { NoTrack=0, TrackAll, TrackCrits };

class CTrackingProjectile : public CEntity
{
public:
	DECLARE_CLASS(CTrackingProjectile, CEntity);

//	virtual void Init(edict_t *pEdict, CBaseEntity *pBaseEntity, bool addHooks);
	virtual void Init(edict_t *pEdict, CBaseEntity *pBaseEntity);
	virtual void Spawn(void);

public:
	virtual void TrackThink(void);
	virtual void FindThink(void);
	bool IsValidTarget(CEntity *pEntity, bool &designated);
	void TurnToTarget(CEntity *pEntity);

	virtual float GetSpeedMultiplier();
	virtual float GetBaseSpeed();

	virtual bool IsCritical(void);
	virtual void SetCritical(bool bCritical);

	bool SetTracking(TrackType type);

	TrackType OnSeek(cell_t projectile, TrackType value);

//public: // CBasePlayer virtuals
//	virtual	bool FVisible(CBaseEntity *pEntity, int traceMask = MASK_BLOCKLOS, CBaseEntity **ppBlocker = NULL);

//public: //Autohandlers
//	DECLARE_DEFAULTHEADER(FVisible, bool, (CBaseEntity *pEntity, int traceMask, CBaseEntity **ppBlocker));

private:
	int m_currentTarget;
	float m_lastSearch;

	bool m_bSpawning;
	float m_baseSpeed;

	TrackType m_Tracking;

protected:	
	bool   m_bHasThought;
	cell_t m_Projectile;
};

#endif // _INCLUDE_CTRACKINGPROJECTILE_H_
