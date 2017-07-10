/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: weapons.inc
 * Description: Weapons related functions.
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#if defined _scweapons_included
 #endinput
#endif
#define _scweapons_included

#include "range"

stock bool:GetWeapon(Handle:event, index,
                     String:buffer[], buffersize)
{
    new bool:is_equipment;

    if (event != INVALID_HANDLE)
    {
        buffer[0] = 0;
        GetEventString(event, "weapon", buffer, buffersize);

        if (buffer[0] == '\0' && index && IsPlayerAlive(index))
        {
            is_equipment = true;
            GetClientWeapon(index, buffer, buffersize);
        }
        else
            is_equipment = false;
    }
    else
        is_equipment = false;

    return is_equipment;
}

stock bool:IsEquipmentMelee(const String:weapon[])
{
    if (GameTypeIsCS())
    {
        return StrEqual(weapon,"weapon_knife");
    }
    else
    {
        switch (GameType)
        {
            case dod:
            {
                return (StrEqual(weapon,"weapon_amerknife") ||
                        StrEqual(weapon,"weapon_spade"));
            }
            case tf2:
            {
                return (StrEqual(weapon,"tf_weapon_knife") ||
                        StrEqual(weapon,"tf_weapon_shovel") ||
                        StrEqual(weapon,"tf_weapon_wrench") ||
                        StrEqual(weapon,"tf_weapon_bat") ||
                        StrEqual(weapon,"tf_weapon_bat_wood") ||
                        StrEqual(weapon,"tf_weapon_bat_fish") ||
                        StrEqual(weapon,"tf_weapon_bonesaw") ||
                        StrEqual(weapon,"tf_weapon_bottle") ||
                        StrEqual(weapon,"tf_weapon_club") ||
                        StrEqual(weapon,"tf_weapon_fireaxe") ||
                        StrEqual(weapon,"tf_weapon_fists") ||
                        StrEqual(weapon,"tf_weapon_sword") ||
                        StrEqual(weapon,"tf_weapon_katana") ||
                        StrEqual(weapon,"tf_weapon_bat_fish") ||
                        StrEqual(weapon,"tf_weapon_robot_arm") ||
                        StrEqual(weapon,"tf_weapon_stickbomb") ||
                        StrEqual(weapon,"tf_wearable_item_demoshield"));
            }
        }
    }
    return false;
}

stock bool:IsDamageFromMelee(const String:weapon[])
{
    if (GameTypeIsCS())
    {
        return StrEqual(weapon,"weapon_knife");
    }
    else
    {
        switch (GameType)
        {
            case dod:
            {
                return (StrEqual(weapon,"amerknife") ||
                        StrEqual(weapon,"spade") ||
                        StrEqual(weapon,"punch"));
            }
            case tf2:
            {
                return (StrEqual(weapon,"knife") ||
                        StrEqual(weapon,"eternal_reward") ||
                        StrEqual(weapon,"shovel") ||
                        StrEqual(weapon,"wrench") ||
                        StrEqual(weapon,"wrench_golden") ||
                        StrEqual(weapon,"bat") ||
                        StrEqual(weapon,"sandman") ||
                        StrEqual(weapon,"holy_mackerel") ||
                        StrEqual(weapon,"bonesaw") ||
                        StrEqual(weapon,"ubersaw") ||
                        StrEqual(weapon,"amputator") ||
                        StrEqual(weapon,"battleneedle") ||
                        StrEqual(weapon,"bottle") ||
                        StrEqual(weapon,"club") ||
                        StrEqual(weapon,"tribalkukri") ||
                        StrEqual(weapon,"fireaxe") ||
                        StrEqual(weapon,"axtinguisher") ||
                        StrEqual(weapon,"sledgehammer") ||
                        StrEqual(weapon,"powerjack") ||
                        StrEqual(weapon,"fists") ||
                        StrEqual(weapon,"pickaxe") ||
                        StrEqual(weapon,"sword") ||
                        StrEqual(weapon,"demoshield") ||
                        StrEqual(weapon,"bear_claws") ||
                        StrEqual(weapon,"warrior_spirit") ||
                        StrEqual(weapon,"steel_fists") ||
                        StrEqual(weapon,"ullapool_caber") ||
                        StrEqual(weapon,"ullapool_caber_explosion") ||
                        StrEqual(weapon,"boston_basher")   ||
                        StrEqual(weapon,"back_scratcher") ||
                        StrEqual(weapon,"candy_cane") ||
                        StrEqual(weapon,"wrench_jag") ||
                        StrEqual(weapon,"taunt_scout") ||
                        StrEqual(weapon,"taunt_sniper") ||
                        StrEqual(weapon,"taunt_pyro") ||
                        StrEqual(weapon,"taunt_demoman") ||
                        StrEqual(weapon,"taunt_heavy") ||
                        StrEqual(weapon,"taunt_spy") ||
                        StrEqual(weapon,"taunt_soldier") ||
                        StrEqual(weapon,"taunt_medic") ||
                        StrEqual(weapon,"taunt_guitar_kill") ||
                        StrEqual(weapon,"robot_arm_blender_kill") ||
                        StrEqual(weapon,"robot_arm_combo_kill") ||
                        StrEqual(weapon,"robot_arm") ||
                        StrEqual(weapon,"southern_hospitality") ||
                        StrEqual(weapon,"gloves") ||
                        StrEqual(weapon,"gloves_running_urgently") ||
                        StrEqual(weapon,"paintrain") ||
                        StrEqual(weapon,"fryingpan") ||
                        StrEqual(weapon,"claidheamohmor") ||
                        StrEqual(weapon,"battleaxe") ||
                        StrEqual(weapon,"headtaker") ||
                        StrEqual(weapon,"lava_bat") ||
                        StrEqual(weapon,"lava_axe") ||
                        StrEqual(weapon,"warfan") ||
                        StrEqual(weapon,"kunai") ||
                        StrEqual(weapon,"demokatana") ||
                        StrEqual(weapon,"scout_sword") ||
                        StrEqual(weapon,"the_maul") ||
                        StrEqual(weapon,"saxxy") ||
                        StrEqual(weapon,"eviction_notice") ||
                        StrEqual(weapon,"splendid_screen") ||
                        StrEqual(weapon,"solemn_vow") ||
                        StrEqual(weapon,"big_earner") ||
                        StrEqual(weapon,"shahanshah") ||
                        StrEqual(weapon,"market_gardener") ||
                        StrEqual(weapon,"disciplinary_action") ||
                        StrEqual(weapon,"mantreads") ||
                        StrEqual(weapon,"atomizer") ||
                        StrEqual(weapon,"persian_persuader") ||
                        StrEqual(weapon,"nessieclub") ||
                        StrEqual(weapon,"bushwacka") ||
                        StrEqual(weapon,"unique_pickaxe") ||
                        StrEqual(weapon,"mailbox") ||
                        StrEqual(weapon,"apocofists")  ||
                        StrEqual(weapon,"voodoo_pin") ||
                        StrEqual(weapon,"sharp_dresser"));
            }
        }
    }
    return false;
}

stock bool:IsEquipmentGrenadeOrRocket(const String:weapon[])
{
    if (GameTypeIsCS())
    {
        return StrEqual(weapon,"hegrenade");
    }
    else
    {
        switch (GameType)
        {
            case dod:
            {
                return (StrEqual(weapon,"weapon_frag_us") ||
                        StrEqual(weapon,"weapon_frag_us",false) ||
                        StrEqual(weapon,"weapon_frag_ger",false) ||
                        StrEqual(weapon,"weapon_riflegren_us") ||
                        StrEqual(weapon,"weapon_riflegren_ger") ||
                        StrEqual(weapon,"weapon_bazooka") ||
                        StrEqual(weapon,"weapon_pschreck"));
            }
            case tf2:
            {
                return (StrEqual(weapon,"tf_weapon_rocketlauncher") ||
                        StrEqual(weapon,"tf_weapon_rocketlauncher_directhit") ||
                        StrEqual(weapon,"tf_weapon_grenadelauncher") ||
                        StrEqual(weapon,"tf_weapon_pipebomblauncher"));
            }
        }
    }
    return false;
}

stock bool:IsDamageFromGrenadeOrRocket(const String:weapon[])
{
    if (GameTypeIsCS())
    {
        return StrEqual(weapon,"hegrenade");
    }
    else
    {
        switch (GameType)
        {
            case dod:
            {
                return (StrEqual(weapon,"weapon_frag_us") ||
                        StrEqual(weapon,"weapon_frag_us",false) ||
                        StrEqual(weapon,"weapon_frag_ger",false) ||
                        StrEqual(weapon,"weapon_riflegren_us") ||
                        StrEqual(weapon,"weapon_riflegren_ger") ||
                        StrEqual(weapon,"bazookarocket") ||
                        StrEqual(weapon,"panzerschreckrocket"));
            }
            case tf2:
            {
                return (StrEqual(weapon,"tf_projectile_pipe") ||
                        StrEqual(weapon,"tf_projectile_pipe_remote") ||
                        StrEqual(weapon,"tf_projectile_rocket") ||
                        StrEqual(weapon,"tf_weapon_rocketlauncher") ||
                        StrEqual(weapon,"rocketlauncher_directhit") ||
                        StrEqual(weapon,"sticky_resistance") ||
                        StrEqual(weapon,"deflect_rocket") ||
                        StrEqual(weapon,"deflect_sticky") ||
                        StrEqual(weapon,"deflect_promode") ||
                        StrEqual(weapon,"tf_pumpkin_bomb") ||
                        StrEqual(weapon,"blackbox") ||
                        StrEqual(weapon,"rocketlauncher_blackbox") ||
                        StrEqual(weapon,"stickybomb_defender") ||
                        StrEqual(weapon,"grenadelauncher") ||
                        StrEqual(weapon,"pipebomblauncher") ||
                        StrEqual(weapon,"loch_n_load") ||
                        StrEqual(weapon,"liberty_launcher") ||
                        StrEqual(weapon,"cow_mangler") ||
                        StrEqual(weapon,"tf_projectile_energy_ball") ||
                        StrEqual(weapon,"quake_rl") ||
                        StrEqual(weapon,"ullapool_caber") ||
                        StrEqual(weapon,"ullapool_caber_explosion") ||
                        StrEqual(weapon,"taunt_soldier"));
            }
        }
    }
    return false;
}

stock bool:IsMelee(const String:weapon[], bool:is_equipment, index, victim, Float:range=100.0)
{
    if (is_equipment)
    {
        if (IsEquipmentMelee(weapon))
            return IsInRange(index,victim,range);
        else
            return false;
    }
    else
        return IsDamageFromMelee(weapon);
}

stock bool:IsNotMelee(const String:weapon[], bool:is_equipment, index, victim, Float:range=100.0)
{
    if (is_equipment)
    {
        if (IsEquipmentMelee(weapon))
            return false;
        else
            return !IsInRange(index,victim,range);
    }
    else
        return !IsDamageFromMelee(weapon);
}

stock bool:IsGrenadeOrRocket(const String:weapon[], bool:is_equipment)
{
    return (is_equipment) ? IsEquipmentGrenadeOrRocket(weapon)
                          : IsDamageFromGrenadeOrRocket(weapon);
}

