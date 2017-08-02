/**
 * vim: set ai et ts=4 sw=4 :
 * File: RateOfFire.sp
 * Description: SourceCraft/TF2 Rate of Fire plugin
 * Author(s): -=|JFH|=-Naris (Murray Wilson)
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <gametype>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <tf2_player>
#define REQUIRE_EXTENSIONS

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#include <lib/trace>

#include "weapons"

#tryinclude "sc/SourceCraft"
#include "sc/weapons"

public Plugin:myinfo = 
{
    name = "SourceCraft Rate of Fire plugin",
    author = "-=|JFH|=-Naris",
    description = "Exports natives to change the Rate of Fire",
    version = SOURCECRAFT_VERSION,
    url = "http://www.jigglysfunhouse.net/"
}

new m_WeaponRateQueueLen                 = 0;
new m_WeaponRateQueue[MAXPLAYERS+1]      = { 0, ... };
new Float:m_EnergyAmount[MAXPLAYERS+1]   = { 0.0, ... };
new Float:m_WeaponRateMult[MAXPLAYERS+1] = { 0.0, ... };
new Float:m_ClientRateMult[MAXPLAYERS+1] = { 0.0, ... };
new bool:m_ClientDisarmed[MAXPLAYERS+1]  = { false, ... };

new bool:g_NativeControl                 = false;
new Handle:g_OnWeaponFiredHandle         = INVALID_HANDLE;
new Handle:g_hROF                        = INVALID_HANDLE;
new Float:g_mult                         = 1.0;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    if (GetGameTypeIsCS())
    {
            if (!HookEvent("weapon_fire",WeaponFireEvent, EventHookMode_Pre))
            {
                strcopy(error, err_max, "Failed to hook the weapon_fire event");
                return APLRes_SilentFailure;
            }
    }
    else if (GameType == dod)
    {
        if (!HookEvent("dod_stats_weapon_attack",WeaponFireEvent, EventHookMode_Pre))
        {
            strcopy(error, err_max, "Failed to hook the dod_stats_weapon_attack event");
            return APLRes_SilentFailure;
        }
    }
    else if (GameType != tf2)
    {
        // Do not hook player_shoot for tf2, which uses TF2_CalcIsAttackCritical()
        if (!HookEvent("player_shoot",WeaponFireEvent, EventHookMode_Pre))
        {
            strcopy(error, err_max, "Failed to hook the player_shoot event");
            return APLRes_SilentFailure;
        }
    }

    CreateNative("DisarmPlayer", Native_DisarmPlayer);
    CreateNative("ControlROF", Native_ControlROF);
    CreateNative("SetROF", Native_SetROF);
    CreateNative("GetROF", Native_GetROF);

    g_OnWeaponFiredHandle = CreateGlobalForward("OnWeaponFired", ET_Ignore,Param_Cell,Param_Cell);

    RegPluginLibrary("RateOfFire");
    return  APLRes_Success;
}

public OnPluginStart()
{
    g_hROF = CreateConVar("sm_rof", "1.0", "Rate Of Fire multiplier.", FCVAR_NOTIFY);
    HookConVarChange(g_hROF, Cvar_rof);
}

public OnConfigsExecuted()
{
    g_mult = 1.0/GetConVarFloat(g_hROF);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    m_ClientRateMult[client] = 0.0;
    return true;
}

public OnClientDisconnect(client)
{
    m_ClientRateMult[client] = 0.0;
}

public OnGameFrame()
{
    if (m_WeaponRateQueueLen)
    {
        new Float:enginetime = GetGameTime();
        for (new i=0;i<m_WeaponRateQueueLen;i++)
        {
            new ent = m_WeaponRateQueue[i];
            if (IsValidEntity(ent))
            {
                new Float:rofmult = m_WeaponRateMult[i];
                if (rofmult != 1.0)
                {
                    new Float:time = (GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack")-enginetime)*rofmult;
                    SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", time+enginetime);

                    time = (GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack")-enginetime)*rofmult;
                    SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", time+enginetime);

                    Trace("Adjust rate Len=%d, i=%d, ent=%d, rate=%f", \
                          m_WeaponRateQueueLen, i, ent, rofmult);
                }
            }
        }
        m_WeaponRateQueueLen = 0;
    }
}

public Cvar_rof(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_mult = 1.0/GetConVarFloat(g_hROF);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
    if (client > 0 && weapon > 0)
    {
        new Float:rate = g_NativeControl ? m_ClientRateMult[client] : g_mult;
        if (rate < 0.0)
            rate = g_mult;

        if (rate != 0.0 && rate != 1.0)
        {
            // Don't enable rapid fire for Melee Weapons or the Pyro's Flamethrower
            // (since it's not very useful and eats energy)
            // Also don't allow zoomed snipers to have rapid fire!
            if (!IsEquipmentMelee(weaponname) &&
                 ((!StrEqual(weaponname, "tf_weapon_flamethrower") &&
                  (TF2_GetPlayerClass(client) != TFClass_Sniper ||
                   !TF2_IsPlayerZoomed(client)))))
            {
#if defined SOURCECRAFT
                if (DecrementEnergy(client, m_EnergyAmount[client]))
#endif
                {
                    m_WeaponRateQueue[m_WeaponRateQueueLen] = weapon;
                    m_WeaponRateMult[m_WeaponRateQueueLen] = rate;
                    m_WeaponRateQueueLen++;

                    Trace("Set rate for %d:%N, Len=%d, weapon=%d:%s, rate=%f", \
                          client, ValidClientIndex(client), m_WeaponRateQueueLen, \
                          weapon, weaponname, rate);
                }
            }
            else
            {
                Trace("Rate rejected for %d:%N, Len=%d, weapon=%d:%s, rate=%f", \
                        client, ValidClientIndex(client), m_WeaponRateQueueLen, \
                        weapon, weaponname, rate);
            }
        }
        else
        {
            Trace("Default rate for %d:%N, Len=%d, weapon=%d:%s, rate=%f, g_NativeControl=%d, m_ClientRateMult=%f", \
                    client, ValidClientIndex(client), m_WeaponRateQueueLen, \
                    weapon, weaponname, rate, g_NativeControl, m_ClientRateMult[client]);
        }

        new Action:res = Plugin_Continue;
        Call_StartForward(g_OnWeaponFiredHandle);
        Call_PushCell(client);
        Call_Finish(res);
    }
    return Plugin_Continue;
}

public WeaponFireEvent(Handle:event,const String:name[],bool:dontBroadcast)
{ 
    new client = (GameType == dod) ? GetEventInt(event,"attacker")
                                   : GetClientOfUserId(GetEventInt(event,"userid"));

    new weapon = GetActiveWeapon(client);
    if (weapon > 0)
    {
        new Float:rate = g_NativeControl ? m_ClientRateMult[client] : g_mult;
        if (rate < 0.0)
            rate = g_mult;

        if (rate != 0.0 && rate != 1.0)
        {
#if defined SOURCECRAFT
            new Float:energy = GetEnergy(client);
            new Float:amount = m_EnergyAmount[client];
            if (energy >= amount)
#endif
            {
                m_WeaponRateQueue[m_WeaponRateQueueLen] = weapon;
                m_WeaponRateMult[m_WeaponRateQueueLen] = rate;
                m_WeaponRateQueueLen++;

#if defined SOURCECRAFT
                if (amount > 0.0)
                    SetEnergy(client, energy-amount);
#endif
            }
        }

        new Action:result = Plugin_Continue;
        Call_StartForward(g_OnWeaponFiredHandle);
        Call_PushCell(client);
        Call_Finish(result);
    } 
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (client > 0)
    {
        if (m_ClientDisarmed[client] ||
            GetRestriction(client,Restriction_Disarmed) ||
            GetRestriction(client,Restriction_Stunned))
        {
            if ((buttons & (IN_ATTACK|IN_ATTACK2)))
            {
                buttons &= ~(IN_ATTACK|IN_ATTACK2);
            }
        }
    }
    return Plugin_Continue;
}

public Native_ControlROF(Handle:plugin, numParams)
{
    g_NativeControl = GetNativeCell(1);
    Trace("ControlROF(%d)", g_NativeControl);
}

public Native_DisarmPlayer(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    m_ClientDisarmed[client] = bool:GetNativeCell(2);
}

public Native_SetROF(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    m_ClientRateMult[client] = Float:GetNativeCell(2);
    m_EnergyAmount[client] = Float:GetNativeCell(3);

    Trace("Set %d:%N's Rate=%f,energy=%f", \
          client, ValidClientIndex(client), \
          m_ClientRateMult[client], m_EnergyAmount[client]);
}

public Native_GetROF(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    SetNativeCellRef(2, m_EnergyAmount[client]);
    return _:m_ClientRateMult[client];          
}
