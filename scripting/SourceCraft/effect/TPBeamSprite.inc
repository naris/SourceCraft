/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: TPBeamSprite.inc
 * Description: Define TPBeam Sprite
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _TPBeamSprite_included
 #endinput
#endif
#define _TPBeamSprite_included

#include <lib/ResourceManager>

#define SetupTPBeamSprite() SetupModel(g_tpBeamModel, g_tpBeamSprite)
#define TPBeamSprite()      PrepareModel(g_tpBeamModel, g_tpBeamSprite)

stock g_tpBeamSprite;
stock const String:g_tpBeamModel[] = "materials/sprites/tp_beam001.vmt";
