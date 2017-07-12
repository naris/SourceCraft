/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: smoke.inc
 * Description: Declares the smoke sprite for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _smoke_included
 #endinput
#endif
#define _smoke_included

#include <lib/ResourceManager>

stock g_smokeSprite;

stock const String:g_smokeModel[] = "materials/sprites/smoke.vmt";

#define SetupSmokeSprite()    SetupModel(g_smokeModel, g_smokeSprite)
#define SmokeSprite()         PrepareModel(g_smokeModel, g_smokeSprite)
