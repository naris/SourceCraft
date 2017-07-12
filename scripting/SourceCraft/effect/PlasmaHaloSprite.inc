/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: PlasmaHaloSprite.inc
 * Description: Define PlasmaHalo Sprite
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _PlasmaHaloSprite_included
 #endinput
#endif
#define _PlasmaHaloSprite_included

#include <lib/ResourceManager>

#define SetupPlasmaHaloSprite() SetupModel(g_plasmaHaloModel, g_plasmaHaloSprite)
#define PlasmaHaloSprite()      PrepareModel(g_plasmaHaloModel, g_plasmaHaloSprite)

stock g_plasmaHaloSprite;
stock const String:g_plasmaHaloModel[] = "materials/sprites/plasmahalo.vmt";
