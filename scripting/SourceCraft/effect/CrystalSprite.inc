/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: CrystalSprite.inc
 * Description: Define Crystal Sprite
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _CrystalSprite_included
 #endinput
#endif
#define _CrystalSprite_included

#include <lib/ResourceManager>

#define SetupCrystalSprite() SetupModel(g_crystalModel, g_crystalSprite)
#define CrystalSprite()      PrepareModel(g_crystalModel, g_crystalSprite)

stock g_crystalSprite;
stock const String:g_crystalModel[] = "materials/sprites/crystal_beam1.vmt";
