/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: plugins.inc
 * Description: stock to check if various plugins are available.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined plugins_included
 #endinput
#endif
#define plugins_included

stock bool:m_ROFAvailable = false;
stock bool:m_TNTAvailable = false;
stock bool:m_GasAvailable = false;
stock bool:m_NadesAvailable = false;
stock bool:m_GravgunAvailable = false;
stock bool:m_JetpackAvailable = false;
stock bool:m_FireminesAvailable = false;
stock bool:m_TripminesAvailable = false;
stock bool:m_RollermineAvailable = false;
stock bool:m_HGRSourceAvailable = false;
stock bool:m_PiggybackAvailable = false;
stock bool:m_FlamethrowerAvailable = false;

stock bool:m_DodAmmoAvailable = false;
stock bool:m_HealthkitAvailable = false;
stock bool:m_MedicClassAvailable = false;

stock bool:m_InfiniteAmmoAvailable = false;
stock bool:m_PlagueInfectAvailable = false;
stock bool:m_MindControlAvailable = false;
stock bool:m_UberChargerAvailable = false;
stock bool:m_BeHorsemannAvailable = false;
stock bool:m_UberShieldAvailable = false;
stock bool:m_SidewinderAvailable = false;
stock bool:m_TeleporterAvailable = false;
stock bool:m_HorsemannAvailable = false;
stock bool:m_MonoculusAvailable = false;
stock bool:m_WrangleyeAvailable = false;
stock bool:m_FakeDeathAvailable = false;
stock bool:m_InfectionAvailable = false;
stock bool:m_AmmopacksAvailable = false;
stock bool:m_MedipacksAvailable = false;
stock bool:m_AmpNodeAvailable = false;
stock bool:m_RemoteAvailable = false;

// Build and Remote are in the same plugin
#define m_BuildAvailable m_RemoteAvailable
#define IsBuildAvailable IsRemoteAvailable

//new const String:shieldWav[]            = "sc/tvedef00.wav";    // UberShield (Defensive Matrix) sound
stock const String:shieldStopWav[]        = "sc/tvedefstop.wav";  // UberShield stop sound
stock const String:shieldStartWav[]       = "sc/tvedefstart.wav"; // UberShield start sound
stock const String:shieldActiveWav[]      = "sc/tvedefloop.wav";  // UberShield active(loop) sound

stock bool:IsROFAvailable(bool:force=false)
{
    if (!m_ROFAvailable && (force || LibraryExists("RateOfFire")))
    {
        ControlROF(true);
        m_ROFAvailable = true;
    }
    return m_ROFAvailable;
}

stock bool:IsTNTAvailable(bool:force=false)
{
    if (!m_TNTAvailable && (force || LibraryExists("sm_tnt")))
    {
        ControlTNT(true);
        m_TNTAvailable = true;
    }
    return m_TNTAvailable;
}

stock bool:IsGasAvailable(bool:force=false)
{
    if (!m_GasAvailable && (force || LibraryExists("sm_gas")))
    {
        ControlGas(true);
        m_GasAvailable = true;
    }
    return m_GasAvailable;
}

stock bool:IsHGRSourceAvailable(bool:force=false)
{
    if (!m_HGRSourceAvailable && (force || LibraryExists("hgrsource")))
    {
        ControlHookGrabRope(true);
        m_HGRSourceAvailable = true;
    }
    return m_HGRSourceAvailable;
}

stock bool:IsGravgunAvailable(bool:force=false)
{
    if (!m_GravgunAvailable && (force || LibraryExists("ztf2grab")))
    {
        ControlZtf2grab(true);
        m_GravgunAvailable = true;
    }
    return m_GravgunAvailable;
}

stock bool:IsNadesAvailable(bool:force=false)
{
    if (!m_NadesAvailable && (force || LibraryExists("ztf2nades")))
    {
        ControlNades(true, true);
        m_NadesAvailable = true;
    }
    return m_NadesAvailable;
}

stock bool:IsFireminesAvailable(bool:force=false)
{
    if (!m_FireminesAvailable && (force || LibraryExists("firemines")))
    {
        ControlMines(true);
        m_FireminesAvailable = true;
    }
    return m_FireminesAvailable;
}

stock bool:IsTripminesAvailable(bool:force=false)
{
    if (!m_TripminesAvailable && (force || LibraryExists("tripmines")))
    {
        ControlTripmines(true);
        m_TripminesAvailable = true;
    }
    return m_TripminesAvailable;
}


stock bool:IsRollermineAvailable(bool:force=false)
{
    if (!m_RollermineAvailable && (force || LibraryExists("rollermine")))
    {
        ControlRM(true);
        m_RollermineAvailable = true;
    }
    return m_RollermineAvailable;
}

stock bool:IsJetpackAvailable(bool:force=false)
{
    if (!m_JetpackAvailable && (force || LibraryExists("jetpack")))
    {
        ControlJetpack(true);
        SetJetpackRefuelingTime(0,30.0);
        SetJetpackFuel(0,100);
        m_JetpackAvailable = true;
    }
    return m_JetpackAvailable;
}

stock bool:IsPiggybackAvailable(bool:force=false)
{
    if (!m_PiggybackAvailable && 
        (force || LibraryExists("piggyback")))
    {
        ControlPiggyback(true);
        m_PiggybackAvailable = true;
    }
    return m_PiggybackAvailable;
}

stock bool:IsFlamethrowerAvailable(bool:force=false)
{
    if (!m_FlamethrowerAvailable && 
        (force || LibraryExists("sm_flame")))
    {
        ControlFlamethrower(true);
        m_FlamethrowerAvailable = true;
    }
    return m_FlamethrowerAvailable;
}

stock bool:IsDodAmmoAvailable(bool:force=false)
{
    if (!m_DodAmmoAvailable && GetGameType() == dod && 
        (force || LibraryExists("dodammo")))
    {
        ControlDodAmmo(true);
        m_DodAmmoAvailable = true;
    }
    return m_DodAmmoAvailable;
}

stock bool:IsHealthkitAvailable(bool:force=false)
{
    if (!m_HealthkitAvailable && GetGameType() == dod && 
        (force || LibraryExists("dodammo")))
    {
        ControlHealthkits(true);
        m_HealthkitAvailable = true;
    }
    return m_HealthkitAvailable;
}

stock bool:IsMedicClassAvailable(bool:force=false)
{
    if (!m_MedicClassAvailable && GetGameType() == dod && 
        (force || LibraryExists("medic_class")))
    {
        ControlMedic(true, 100, 0, 0, 0, 0);
        m_MedicClassAvailable = true;
    }
    return m_MedicClassAvailable;
}

stock bool:IsPlagueInfectAvailable(bool:force=false)
{
    if (!m_PlagueInfectAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("PlagueInfect")))
    {
        m_PlagueInfectAvailable = true;
    }
    return m_PlagueInfectAvailable;
}

stock bool:IsMindControlAvailable(bool:force=false)
{
    if (!m_MindControlAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("MindControl")))
    {
        m_MindControlAvailable = true;
    }
    return m_MindControlAvailable;
}

stock bool:IsInfiniteAmmoAvailable(bool:force=false)
{
    if (!m_InfiniteAmmoAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("aia")))
    {
        AIA_Control(true);
        m_InfiniteAmmoAvailable = true;
    }
    return m_InfiniteAmmoAvailable;
}

stock bool:IsSidewinderAvailable(bool:force=false)
{
    if (!m_SidewinderAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("sidewinder")))
    {
        SidewinderControl(true);
        m_SidewinderAvailable = true;
    }
    return m_SidewinderAvailable;
}

stock bool:IsUberChargerAvailable(bool:force=false)
{
    if (!m_UberChargerAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("ubercharger")))
    {
        ControlUberCharger(true);
        m_UberChargerAvailable = true;
    }
    return m_UberChargerAvailable;
}

stock bool:IsRemoteAvailable(bool:force=false)
{
    if (!m_RemoteAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("remote")))
    {
        ControlBuild(true);
        ControlRemote(true);
        m_RemoteAvailable = true;
    }
    return m_RemoteAvailable;
}

stock bool:IsAmpNodeAvailable(bool:force=false)
{
    if (!m_AmpNodeAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("amp_node")))
    {
        ControlAmpNode(true);
        m_AmpNodeAvailable = true;
    }
    return m_AmpNodeAvailable;
}

stock bool:IsUberShieldAvailable(bool:force=false)
{
    if (!m_UberShieldAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("ubershield")))
    {
        ControlUberShield(true);
        SetAlternateShieldSound(shieldStartWav, shieldActiveWav,
                                shieldStopWav, 2.0, 2.0);
        m_UberShieldAvailable = true;
    }
    return m_UberShieldAvailable;
}

stock bool:IsAmmopacksAvailable(bool:force=false)
{
    if (!m_AmmopacksAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("ammopacks")))
    {
        ControlAmmopacks(true);
        m_AmmopacksAvailable = true;
    }
    return m_AmmopacksAvailable;
}

stock bool:IsMedipacksAvailable(bool:force=false)
{
    if (!m_MedipacksAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("medipacks")))
    {
        ControlMedipacks(true);
        m_MedipacksAvailable = true;
    }
    return m_MedipacksAvailable;
}

stock bool:IsTeleporterAvailable(bool:force=false)
{
    if (!m_TeleporterAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("teleporter")))
    {
        ControlTeleporter(true);
        m_TeleporterAvailable = true;
    }
    return m_TeleporterAvailable;
}

stock bool:IsFakeDeathAvailable(bool:force=false)
{
    if (!m_FakeDeathAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("FakeDeath")))
    {
        ControlDeath(true);
        m_FakeDeathAvailable = true;
    }
    return m_FakeDeathAvailable;
}

stock bool:IsInfectionAvailable(bool:force=false)
{
    if (!m_InfectionAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("MedicInfect")))
    {
        ControlMedicInfect(true);
        HookInfection(OnInfected);
        m_InfectionAvailable = true;
    }
    return m_InfectionAvailable;
}

stock bool:IsHorsemannAvailable(bool:force=false)
{
    if (!m_HorsemannAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("horsemann")))
    {
        ControlHorsemann(true);
        m_HorsemannAvailable = true;
    }
    return m_HorsemannAvailable;
}

stock bool:IsMonoculusAvailable(bool:force=false)
{
    if (!m_MonoculusAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("MonoSpawn")))
    {
        ControlMonoculus(true);
        m_MonoculusAvailable = true;
    }
    return m_MonoculusAvailable;
}

stock bool:IsBeHorsemannAvailable(bool:force=false)
{
    if (!m_BeHorsemannAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("behorsemann")))
    {
        ControlBeHorsemann(true);
        m_BeHorsemannAvailable = true;
    }
    return m_BeHorsemannAvailable;
}

stock bool:IsWrangleyeAvailable(bool:force=false)
{
    if (!m_WrangleyeAvailable && GetGameType() == tf2 && 
        (force || LibraryExists("wrangleye")))
    {
        ControlWrangleMonoculus(true);
        m_WrangleyeAvailable = true;
    }
    return m_WrangleyeAvailable;
}
