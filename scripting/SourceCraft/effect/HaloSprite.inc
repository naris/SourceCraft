/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: HaloSprite.inc
 * Description: Define Halo Sprite
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _HaloSprite_included
 #endinput
#endif
#define _HaloSprite_included

#include <lib/ResourceManager>

#define SetupHaloSprite()  SetupModel(g_haloModel, g_haloSprite)
#define HaloSprite()       PrepareModel(g_haloModel, g_haloSprite)

stock g_haloSprite;
stock const String:g_haloModel[] = "materials/sprites/halo01.vmt";
