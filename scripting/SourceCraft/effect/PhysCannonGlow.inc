/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: PhysCannonGlow.inc
 * Description: Define PhysCannon Glow
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _PhysCannonGlow_included
 #endinput
#endif
#define _PhysCannonGlow_included

#include <lib/ResourceManager>

#define SetupPhysCannonGlow()  SetupModel(g_physCannonModel, g_physCannonGlow)
#define PhysCannonGlow()       PrepareModel(g_physCannonModel, g_physCannonGlow)

stock g_physCannonGlow;
stock const String:g_physCannonModel[] = "materials/sprites/physcannon_blueglow.vmt";
