/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Lightning.inc
 * Description: Define Lightning
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _Lightning_included
 #endinput
#endif
#define _Lightning_included

#include <lib/ResourceManager>

#define SetupLightning() SetupModel(g_lightningModel, g_lightningSprite)
#define Lightning()      PrepareModel(g_lightningModel, g_lightningSprite)

stock g_lightningSprite;
stock const String:g_lightningModel[] = "materials/sprites/lgtning.vmt";
