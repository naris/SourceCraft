/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: SteamSprite.inc
 * Description: Define Steam Sprite
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _SteamSprite_included
 #endinput
#endif
#define _SteamSprite_included

#include <lib/ResourceManager>

#define SetupSteamSprite() SetupModel(g_steamModel, g_steamSprite)
#define SteamSprite()      PrepareModel(g_steamModel, g_steamSprite)

stock g_steamSprite;
stock const String:g_steamModel[] = "materials/sprites/steam1.vmt";
