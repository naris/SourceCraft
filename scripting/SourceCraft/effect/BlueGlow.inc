/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: BlueGlow.inc
 * Description: Define Blue Glow
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _BlueGlow_included
 #endinput
#endif
#define _BlueGlow_included

#include <lib/ResourceManager>

#define SetupBlueGlow() SetupModel(g_blueModel, g_blueGlow)
#define BlueGlow()      PrepareModel(g_blueModel, g_blueGlow)

stock g_blueGlow;
stock const String:g_blueModel[] = "materials/sprites/blueglow1.vmt";
