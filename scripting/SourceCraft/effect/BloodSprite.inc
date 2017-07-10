/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: BloodSprite.inc
 * Description: Define BloodSprite models
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _BloodSprite_included
 #endinput
#endif
#define _BloodSprite_included

#include <ResourceManager>

#define SetupBloodSpray() SetupModel(g_bloodSprayModel, g_bloodSpray)
#define BloodSpray()      PrepareModel(g_bloodSprayModel, g_bloodSpray)

#define SetupBloodDrop() SetupModel(g_bloodDropModel, g_bloodDrop)
#define BloodDrop()      PrepareModel(g_bloodDropModel, g_bloodDrop)

stock g_bloodSpray;
stock const String:g_bloodSprayModel[] = "sprites/blood.vmt";

stock g_bloodDrop;
stock const String:g_bloodDropModel[] = "sprites/blood.vmt";
