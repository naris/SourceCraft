/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_particle.inc
 * Description: Functions to show TF2 tempent particles
 * Author(s): L. Duke
 */
 
#if defined _tf2_particle_included
 #endinput
#endif
#define _tf2_particle_included

#include <tf2_stocks>

stock TE_Particle(String:Name[],
                  Float:origin[3]=NULL_VECTOR,
                  Float:start[3]=NULL_VECTOR,
                  Float:angles[3]=NULL_VECTOR,
                  entindex=-1,
                  attachtype=-1,
                  attachpoint=-1,
                  bool:resetParticles=true,
                  Float:delay=0.0)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    TE_SendToAll(delay);
}

stock ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
    else
    {
        LogError("ShowParticle: could not create info_particle_system");
    }    
}

stock AttachParticle(ent, String:particleType[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        new Float:pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
    else
    {
        LogError("AttachParticle: could not create info_particle_system");
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
        else
        {
            LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
        }
    }
}

/***************************************************************************\
|                      standard particle names in TF2                       |
+---------------------------------------------------------------------------+
error
rockettrail_!
critical_rocket_blue
critical_rocket_bluesparks
critical_rocket_red
critical_rocket_redsparks
rockettrail_underwater
rockettrail_waterbubbles
sentry_rocket
sentry_rocket_burst
sentry_rocket_fire
rockettrail
flaregun_trail_blue
flaregun_trail_red
flaregun_trail_crit_red
flaregun_crit_red
flaregun_trail_crit_blue
teleporter_red_exit
teleporter_arms_circle_red
teleporter_red_entrance
teleporter_blue_entrance
teleporter_blue_exit
teleporter_arms_circle_blue
teleporter_blue_charged
teleporter_blue_charged_wisps
teleporter_red_charged
teleporter_blue_entrance_level2
teleporter_blue_entrance_level3
teleporter_blue_charged_level2
teleporter_blue_wisps_level2
teleporter_blue_charged_level3
teleporter_blue_wisps_level3
teleporter_blue_exit_level2
teleporter_blue_exit_level3
teleporter_red_charged_level2
teleporter_red_wisps_level2
teleporter_red_charged_level3
teleporter_red_wisps_level3
teleporter_red_entrance_level2
teleporter_red_entrance_level3
ExplosionCore_buildings
ExplosionCore_MidAir
Explosions_MA_Debris001
bday_blood
bday_1balloon
bday_bloodconfetti
bday_bloodconfetti2
ExplosionCore_Wall
ExplosionCore_Wall_underwater
bday_confetti
bday_confetti_colors
bday_balloon01
bday_balloon02
Explosions_MA_Dustup_2
ExplosionCore_MidAir_underwater
Explosions_UW_Debris001
ExplosionCore_sapperdestroyed
sapper_coreflash
sapper_debris
sapper_flash
sapper_flashup
sapper_flyingembers
sapper_smoke
player_recent_teleport_red
player_glowred
player_dripsred
player_recent_teleport_blue
player_drips_blue
player_sparkles_red
player_sparkles_blue
doublejump_puff
doublejump_smoke
deflect_fx
deflect_temp
rocketbackblast
rocketbackblastsparks
flamethrower
flamethrower_crit_red
flamethrower_crit_pilot_red
flamethrower_crit_red_glow
flamethrower_crit_red_sparks
flamethrower_underwater
pyrotaunt
pyrotaunt_flame
pyrotaunt_powerup
flamethrower_blue
flamethrower_crit_blue
pyro_blast
pyro_blast_lines
pyro_blast_warp
pyro_blast_flash
flaregun_destroyed
flaregun_destroyed_bits
burningplayer_corpse
burningplayer_corpseglow
burningplayer_blue
burningplayer_blueglow
burningplayer_red
burninggibs
blood_impact_red_01
blood_impact_red_01_chunk
blood_impact_red_01_smalldroplets
blood_spray_red_01
water_blood_impact_red_01
water_blood_impact_red_01_chunk
water_blood_impact_red_01_goop
blood_spray_red_01_far
lowV_blood_impact_red_01
lowV_smallerchunks
lowV_debrischunks
lowV_oildroplets
lowV_blood_spray_red_01
temp_blood_spray_red_01_far
temp_blood_spray_red_01
lowV_blood_spray_red_01_far
lowV_water_blood_impact_red_01
lowV_water_debris
lowV_water_bubbles
blood_trail_red_01_goop
blood_trail_red_01_droplets
muzzle_shotgun
muzzle_shotgun_flash
muzzle_grenadelauncher
muzzle_minigun
muzzle_minigun_starflash01
muzzle_minigun_core
muzzle_minigun_sparks
muzzle_minigun_smoke
muzzle_pistol
muzzle_scattergun
muzzle_smg
muzzle_smg_sparks
muzzle_revolver
muzzle_sniperrifle
muzzle_syringe
muzzle_sentry
muzzle_sentry2
muzzle_pipelauncher
muzzle_minigun_constant
muzzle_minigun_constant_core
muzzle_minigun_constant_flare
muzzle_minigun_constant_sparks
muzzle_minigun_constant_starflash
muzzle_minigun_constant_smoke
teleported_red
teleported_blue
teleportedin_red
teleportedin_blue
cig_smoke
cig_burn
crit_text
achieved
mini_fireworks
mini_firework_flare
dispenser_heal_red
dispenser_beam_red_pluses
dispenser_beam_red_trail
medicgun_beam_red_invun
medicgun_beam_red_invulnbright
medicgun_beam_red_invunglow
dispenser_heal_blue
dispenser_beam_blue_trail
medicgun_beam_blue_invun
medicgun_beam_blue_invunglow
medicgun_beam_blue_invulnbright
medicgun_invulnstatus_fullcharge_red
medicgun_invulnstatus_fullcharge_blue
medicgun_beam_blue
medicgun_beam_red
water_splash01
water_splash01_droplets
water_bulletsplash01
water_bulletsplash01_minigun
water_playerwake_static
water_playerwake_moving
water_playerdive
water_playerdive_bubbles
water_playeremerge
water_bulletsplash01_cheap
stickybombtrail_red
stickybombtrail_blue
critical_grenade_blue
critical_grenade_red
stickybomb_pulse_blue
stickybomb_pulse_red
pipebombtrail_red
pipebombtrail_blue
critical_pipe_red
critical_pipe_blue
buildingdamage_smoke2
sentrydamage_4
sentrydamage_3
sentrydamage_1
sentrydamage_2
tpdamage_1
tpdamage_2
tpdamage_3
tpdamage_smoke1
tpdamage_4
dispenserdamage_4
dispensersmoke_2
buildingdamage_dispenser_fire1
dispenserdamage_1
dispenserdamage_3
buildingdamage_dispenser_fire0
dispenserdamage_2
buildingdamage_fire1
nailtrails_medic_red
nailtrails_medic_blue
nailtrails_medic_blue_crit
nailtrails_medic_red_crit
speech_typing
speech_mediccall
speech_mediccall_attention
speech_voice
bullet_tracer01_crit
bullet_tracer01_blue
bullet_tracer01_red
bullet_tracer01_blue_crit
bullet_impact1_blue_crit
bullet_tracer01_red_crit
bullet_impact1_red_crit
bullet_scattergun_tracer01_blue_crit
bullet_scattergun_tracer01_red_crit
bullet_pistol_tracer01_blue_crit
bullet_pistol_tracer01_red_crit
bullet_shotgun_tracer01_blue_crit
bullet_shotgun_tracer01_red_crit
particle_nemesis_blue
particle_nemesis_burst_blue
particle_nemesis_red
particle_nemesis_burst_red
spy_start_disguise_red
disguise_flash_red
spy_start_disguise_blue
disguise_flash_blue
spark_electric01
sapper_sentry1_fx
sapper_sentry1_sparks1
sapper_sentry1_sparks2
candle_light1
player_intel_papertrail
player_intel_trail_red
player_intel_trail_blue
cart_flashinglight
eject_minigunbrass
medicgun_beam_attrib_drips
medicgun_beam_attrib_shards
medicgun_beam_attrib_overheal
medicgun_beam_attrib_healing
medicgun_beam_attrib_muzzle
overhealedplayer_red_pluses
overhealedplayer_blue_pluses
medicgun_beam_attrib_overheal_blue
medicgun_beam_attrib_overheal_red
bonersaw_temp
critgun_weaponmodel_blu
critgun_weaponmodel_red
healthgained_blu
healthgained_red
cinefx_goldrush_burningbarrel
cinefx_goldrush
cinefx_goldrush_flash
cinefx_goldrush_burningdebris
cinefx_goldrush_pitglow
impact_concrete_noflecks
ricochet_sparks
impact_generic_burst_2
impact_antlion
impact_metal_child_smoke
impact_metal
impact_metal_child_glowLarge
impact_generic_smoke
impact_metal_child_base
impact_generic_burn
impact_computer
impact_glass
impact_glass_child_burst
impact_glass_child_smoke
impact_glass_child_backblast
impact_concrete
impact_dirt
impact_woodbroken
impact_dirt_nosmoke
impact_wood
impact_wood_child_puff
bullet_pistol_tracer01_red
bullet_pistol_tracer01_blue
bullet_scattergun_tracer01_red
bullet_scattergun_tracer01_blue
bullet_shotgun_tracer01_red
bullet_shotgun_tracer01_blue
\***************************************************************************/
