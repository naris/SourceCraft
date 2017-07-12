/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Explosion.inc
 * Description: Define Explosion
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _Explosion_included
 #endinput
#endif
#define _Explosion_included

#include <lib/ResourceManager>

#define SetupFireSprite()      SetupModel(g_fireModel, g_fireSprite)
#define FireSprite()           PrepareModel(g_fireModel, g_fireSprite)

#define SetupFire2Sprite()     SetupModel(g_fire2Model, g_fire2Sprite)
#define Fire2Sprite()          PrepareModel(g_fire2Model, g_fire2Sprite)

#define SetupExplosion()       SetupModel(g_explosionModel, g_explosionSprite)
#define Explosion()            PrepareModel(g_explosionModel, g_explosionSprite)

#define BigExplosion()         ((GameType == tf2) ? PrepareModel(g_bigExplosionModel, g_bigExplosionSprite) \
                                                  : PrepareModel(g_explosionModel, g_explosionSprite))

stock g_fireSprite;
stock g_fire2Sprite;
stock g_explosionSprite;
stock g_bigExplosionSprite;

stock const String:g_fireModel[]         = "sprites/sprite_fire01.vmt";
stock const String:g_fire2Model[]        = "sprites/sprite_fire2.vmt";
stock const String:g_explosionModel[]    = "materials/sprites/zerogxplode.vmt";
stock const String:g_bigExplosionModel[] = "materials/particles/explosion/explosionfiresmoke.vmt";

stock bool:SetupBigExplosion()
{
    if (GameType == tf2)
    {
        SetupModel(g_bigExplosionModel, g_bigExplosionSprite);
        return true;
    }
    else
    {
        SetupExplosion();
        return false;
    }
}
