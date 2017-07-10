/**
* vim: set ts=4 :
* =============================================================================
* CEntity Entity Handling Framework
* Copyright (C) 2009 Matt Woodrow.  All rights reserved.
* =============================================================================
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License, version 3.0, as published by the
* Free Software Foundation.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "CPlayer.h"
#include "shareddefs.h"
#include "in_buttons.h"

SH_DECL_MANUALHOOK3(FVisible, 0, 0, 0, bool, CBaseEntity *, int, CBaseEntity **);
SH_DECL_MANUALHOOK2_void(PlayerRunCmd, 0, 0, 0, CUserCmd *, IMoveHelper *);

DECLARE_HOOK(FVisible, CPlayer);
DECLARE_HOOK(PlayerRunCmd, CPlayer);

LINK_ENTITY_TO_CLASS(player, CPlayer);

//Sendprops
DEFINE_PROP(m_flNextAttack, CPlayer);
DEFINE_PROP(m_hActiveWeapon, CPlayer);
DEFINE_PROP(m_hMyWeapons, CPlayer);
DEFINE_PROP(m_iHealth, CPlayer);
DEFINE_PROP(m_lifeState, CPlayer);
DEFINE_PROP(m_iClass, CPlayer);
DEFINE_PROP(m_nPlayerCond, CPlayer);
DEFINE_PROP(m_bJumping, CPlayer);
DEFINE_PROP(m_nPlayerState, CPlayer);
DEFINE_PROP(m_nDisguiseTeam, CPlayer);
DEFINE_PROP(m_nDisguiseClass, CPlayer);
DEFINE_PROP(m_iDisguiseTargetIndex, CPlayer);
DEFINE_PROP(m_iDisguiseHealth, CPlayer);

//Datamaps
DEFINE_PROP(m_nButtons, CPlayer);


DECLARE_DEFAULTHANDLER(CPlayer, FVisible, bool, (CBaseEntity *pEntity, int traceMask, CBaseEntity **ppBlocker), (pEntity, traceMask, ppBlocker));
DECLARE_DEFAULTHANDLER_void(CPlayer, PlayerRunCmd, (CUserCmd *pCmd, IMoveHelper *pHelper), (pCmd, pHelper));

bool CPlayer::IsPlayer()
{
	return true;
}

bool CPlayer::IsAlive()
{
	return *m_lifeState == LIFE_ALIVE;
}

int CPlayer::GetPlayerClass()
{
	return *m_iClass;
}

int CPlayer::GetPlayerCond()
{
	return *m_nPlayerCond;
}

bool CPlayer::IsDisguised()
{
	return (*m_nPlayerCond & PLAYERCOND_DISGUISED) == PLAYERCOND_DISGUISED;
}

int CPlayer::GetDisguisedTeam()
{
	return *m_nDisguiseTeam;
}

int CPlayer::GetButtons()
{
	return *m_nButtons;
}
