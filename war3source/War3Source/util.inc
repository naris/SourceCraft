/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: util.inc
 * Description: Utility functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _util_included
 #endinput
#endif
#define _util_included

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // Actually red for DOD

enum Mod { undetected, tf2, cstrike, dod, hl2mp, insurgency, other };
stock Mod:GameType = undetected;

stock Mod:GetGameType()
{
    if (GameType == undetected)
    {
        new String:modname[30];
        GetGameFolderName(modname, sizeof(modname));
        if (StrEqual(modname,"cstrike",false))
            GameType=cstrike;
        else if (StrEqual(modname,"tf",false)) 
            GameType=tf2;
        else if (StrEqual(modname,"dod",false)) 
            GameType=dod;
        else if (StrEqual(modname,"hl2mp",false)) 
            GameType=hl2mp;
        else if (StrEqual(modname,"Insurgency",false)) 
            GameType=insurgency;
        else
            GameType=other;
    }
    return GameType;
}

stock SetupSound(String:wav[])
{
    PrecacheSound(wav);

    decl String:file[PLATFORM_MAX_PATH+1];
    Format(file, PLATFORM_MAX_PATH, "sound/%s", wav);
    AddFileToDownloadsTable(file);
}

stock SetupModel(String:model[])
{
    AddFileToDownloadsTable(model);
    return PrecacheModel(model);
}

stock Float:DistanceBetween(Float:startvec[3],Float:endvec[3])
{
    return SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+
                      (startvec[1]-endvec[1])*(startvec[1]-endvec[1])+
                      (startvec[2]-endvec[2])*(startvec[2]-endvec[2]));
}

stock GetDamage(Handle:event, attacker=0, min=5, max=20)
{
    new damage=GetEventInt(event,"damage");
    if (!damage)
    {
        damage = GetEventInt(event,"dmg_health");
        if (!damage)
        {
            if (attacker)
            {
                decl String:weapon[64];
                GetClientWeapon(attacker, weapon, sizeof(weapon));

                if (StrEqual(weapon, "bat"))
                    damage = GetRandomInt(30,45);
                else if (StrEqual(weapon, "knife"))
                    damage = GetRandomInt(30,40);
                else if (StrEqual(weapon, "smg"))
                    damage = GetRandomInt(6,12);
                else if (StrEqual(weapon, "pistol") || StrEqual(weapon, "pistol_scout"))
                    damage = GetRandomInt(9,25);
                else if (StrEqual(weapon, "revolver"))
                    damage = GetRandomInt(20,60);
                else if (StrEqual(weapon, "scattergun"))
                    damage = GetRandomInt(3,110);
                else if (StrEqual(weapon, "flamethrower"))
                    damage = GetRandomInt(5,15);
                else if (StrEqual(weapon, "sniperrifle"))
                    damage = GetRandomInt(30,190);
                else if (StrEqual(weapon, "syringegun_medic"))
                    damage = GetRandomInt(8,13);
                else if (StrEqual(weapon, "tf_projectile_rocket"))
                    damage = GetRandomInt(50,110);
                else if (StrEqual(weapon, "tf_projectile_pipe"))
                    damage = GetRandomInt(45,120);
                else if (StrEqual(weapon, "tf_projectile_pipe_remote"))
                    damage = GetRandomInt(85,150);
                else if (StrEqual(weapon, "shotgun_pyro") || StrEqual(weapon, "shotgun_hwg") ||
                         StrEqual(weapon, "shotgun_soldier") || StrEqual(weapon, "shotgun_primary"))
                {
                    damage = GetRandomInt(3,100);
                }
                else if (StrEqual(weapon, "shovel") || StrEqual(weapon, "fireaxe") ||
                         StrEqual(weapon, "bonesaw") || StrEqual(weapon, "machete") ||
                         StrEqual(weapon, "bottle") || StrEqual(weapon, "wrench") ||
                         StrEqual(weapon, "club") || StrEqual(weapon, "fists"))
                {
                    damage = GetRandomInt(45,90);
                }
                else
                {
                    damage = GetRandomInt(min,max);
                }
            }
            else
            {
                damage = GetRandomInt(min,max);
            }
        }
    }
    return damage;
}
