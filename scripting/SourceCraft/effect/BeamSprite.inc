/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: BeamSprite.inc
 * Description: Define Beam Sprite
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _BeamSprite_included
 #endinput
#endif
#define _BeamSprite_included

#include <lib/ResourceManager>

#define SetupBeamSprite() SetupModel(g_beamModel, g_beamSprite)
#define BeamSprite()      PrepareModel(g_beamModel, g_beamSprite)

stock g_beamSprite;
stock const String:g_beamModel[] = "materials/sprites/laser.vmt";
