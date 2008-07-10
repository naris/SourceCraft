/**
 * vim: set ai et ts=4 sw=4 :
 * File: MedicInfect.sp
 * Description: Medic Infection for TF2
 * Author(s): Twilight Suzuka
 */

//Osaka: This plugin IS CPU INTENSIVE.
//	I will note the various optimizations, great and small, used to bring the intensiveness down as far as possible.
//	One optimization not used, but that is implimentable, is to cache ConVar's directly into variables.

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

new ClientInfected[MAXPLAYERS + 1];
new InfectionSource[MAXPLAYERS + 1];
new bool:ClientFriendlyInfected[MAXPLAYERS + 1];
new Float:MedicInfectDelay[MAXPLAYERS + 1];

new bool:NativeHooked = false;
new bool:NativeControl = false;
new bool:NativeMedicArmed[MAXPLAYERS + 1] = { false, ...};
new NativeAmount[MAXPLAYERS + 1];
new NativeChance[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
    name = "Medic Infection",
    author = "Twilight Suzuka & -=|JFH|=-Naris",
    description = "Allows medics to infect again",
    version = "Gamma:7.1",
    url = "http://www.sourcemod.net/"
};

new Handle:CvarEnable = INVALID_HANDLE;
new Handle:CvarAnnounce = INVALID_HANDLE; //

new Handle:Cvar_DmgAmount = INVALID_HANDLE;
new Handle:Cvar_DmgTime = INVALID_HANDLE;

new Handle:Cvar_InfectEnable = INVALID_HANDLE;
new Handle:Cvar_InfectDistance = INVALID_HANDLE;

new Handle:Cvar_InfectMedi = INVALID_HANDLE;
new Handle:Cvar_InfectMediCheckTime = INVALID_HANDLE;
new Handle:Cvar_InfectSyringe = INVALID_HANDLE;

new Handle:Cvar_InfectMedics = INVALID_HANDLE;
new Handle:Cvar_InfectHeal = INVALID_HANDLE;
new Handle:Cvar_InfectSameTeam = INVALID_HANDLE;
new Handle:Cvar_InfectOpposingTeam = INVALID_HANDLE;

new Handle:Cvar_InfectFailedDelay = INVALID_HANDLE;
new Handle:Cvar_InfectSucceededDelay = INVALID_HANDLE;

new Handle:Cvar_SpreadEnable = INVALID_HANDLE;
new Handle:Cvar_SpreadDistance = INVALID_HANDLE;
new Handle:Cvar_SpreadCheckTime = INVALID_HANDLE;

new Handle:Cvar_SpreadAll = INVALID_HANDLE;
new Handle:Cvar_SpreadInfector = INVALID_HANDLE;
new Handle:Cvar_SpreadMedics = INVALID_HANDLE;
new Handle:Cvar_SpreadSameTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadOpposingTeam = INVALID_HANDLE;

new Handle:Cvar_SameColors = INVALID_HANDLE;
new Handle:Cvar_GunColors = INVALID_HANDLE;
new Handle:Cvar_BothTeamsRed, Handle:Cvar_BothTeamsBlue, Handle:Cvar_BothTeamsGreen, Handle:Cvar_BothTeamsAlpha;
new Handle:Cvar_RTeamRed, Handle:Cvar_RTeamBlue, Handle:Cvar_RTeamGreen, Handle:Cvar_RTeamAlpha;
new Handle:Cvar_BTeamRed, Handle:Cvar_BTeamBlue, Handle:Cvar_BTeamGreen, Handle:Cvar_BTeamAlpha;

new Handle:InfectionTimer = INVALID_HANDLE;
new Handle:MediTimer = INVALID_HANDLE;
new Handle:SpreadTimer = INVALID_HANDLE;

new Handle:OnInfectedHandle = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlMedicInfect",Native_ControlMedicInfect);
    CreateNative("HookInfection",Native_HookInfection);
    CreateNative("SetMedicInfect",Native_SetMedicInfect);
    CreateNative("MedicInfect",Native_MedicInfect);
    CreateNative("HealInfect",Native_HealInfect);
    //OnInfectedHandle=CreateGlobalForward("OnInfected",ET_Hook,Param_Cell,Param_Cell,Param_Cell,Param_Array);
    OnInfectedHandle=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Cell,Param_Array);
    RegPluginLibrary("MedicInfect");
    return true;
}

public OnPluginStart()
{
    CvarEnable = CreateConVar("medic_infect_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
    CvarAnnounce = CreateConVar("medic_infect_announce", "1", "This will enable announcements that the plugin is loaded", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    Cvar_DmgAmount = CreateConVar("sv_medic_infect_dmg_amount", "10", "Amount of damage medic infect does each heartbeat",FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_DmgTime = CreateConVar("sv_medic_infect_dmg_time", "12.0", "Amount of time between infection heartbeats",FCVAR_PLUGIN|FCVAR_NOTIFY);

    Cvar_InfectEnable = CreateConVar("sv_medic_infect_allow_infect", "1", "Can medics infect?", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
    Cvar_InfectDistance = CreateConVar("sv_medic_infect_infect_distance", "0.0", "Distance infection can be injected from", FCVAR_PLUGIN);

    Cvar_InfectMedi = CreateConVar("sv_medic_infect_medi", "1", "Infect using medi gun", FCVAR_PLUGIN);
    Cvar_InfectMediCheckTime = CreateConVar("sv_medic_infect_medi_check_time", "0.2", "Amount of time between checks, 0.0 for gameframe", FCVAR_PLUGIN);
    Cvar_InfectSyringe = CreateConVar("sv_medic_infect_syringe", "0", "Infect using syringe gun", FCVAR_PLUGIN);

    Cvar_InfectHeal = CreateConVar("sv_medic_infect_heal", "1", "Allow medics to uninfect players", FCVAR_PLUGIN);
    Cvar_InfectFailedDelay = CreateConVar("sv_medic_failed_infect_delay", "1.0", "Delay between failed infections", FCVAR_PLUGIN);
    Cvar_InfectSucceededDelay = CreateConVar("sv_medic_succeeded_infect_delay", "5.0", "Delay between succeeded infections", FCVAR_PLUGIN);

    Cvar_InfectMedics = CreateConVar("sv_medic_infect_medics", "0", "Allow medics to be infected", FCVAR_PLUGIN);
    Cvar_InfectSameTeam = CreateConVar("sv_medic_infect_friendly", "1", "Allow medics to infect friends", FCVAR_PLUGIN);
    Cvar_InfectOpposingTeam = CreateConVar("sv_medic_infect_enemy", "1", "Allow medics to infect enemies", FCVAR_PLUGIN);

    Cvar_SpreadEnable = CreateConVar("sv_medic_infect_allow_spread", "1", "Can the infection spread?", FCVAR_PLUGIN);
    Cvar_SpreadDistance = CreateConVar("sv_medic_infect_spread_distance", "2000.0", "Distance infection can spread", FCVAR_PLUGIN);	
    Cvar_SpreadCheckTime = CreateConVar("sv_medic_infect_spread_check_time", "1.0", "Amount of time between checks, 0.0 for gameframe", FCVAR_PLUGIN);

    Cvar_SpreadAll = CreateConVar("sv_medic_infect_spread_all", "0", "Allow medical infections to run rampant",FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_SpreadInfector = CreateConVar("sv_medic_infect_spread_infector", "0", "Should infectors be vaccinated?", FCVAR_PLUGIN);
    Cvar_SpreadMedics = CreateConVar("sv_medic_infect_spread_medics", "0", "Should medics be vaccinated?", FCVAR_PLUGIN);
    Cvar_SpreadSameTeam = CreateConVar("sv_medic_infect_spread_friendly", "1", "Allow medical infections to run rampant inside a team",FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_SpreadOpposingTeam = CreateConVar("sv_medic_infect_spread_enemy", "0", "Allow medical infections to run rampant between teams",FCVAR_PLUGIN|FCVAR_NOTIFY);

    Cvar_SameColors = CreateConVar("medic_infect_same_colors", "0", "Infected from both teams use same colors", FCVAR_NOTIFY);
    Cvar_GunColors = CreateConVar("medic_infect_gun_colors", "1", "Infected players guns reflect teams", FCVAR_NOTIFY);

    Cvar_BothTeamsRed = CreateConVar("medic_infect_teams_red", "0", "[Both Teams Infected] Amount of Red", FCVAR_NOTIFY, true, 0.0, true, 255.0);
    Cvar_BothTeamsGreen = CreateConVar("medic_infect_teams_green", "255", "[Both Team Infected] Amount of Green", FCVAR_NOTIFY, true, 0.0, true, 255.0);
    Cvar_BothTeamsBlue = CreateConVar("medic_infect_teams_blue", "100", "[Both Team Infected] Amount of Blue", FCVAR_NOTIFY, true, 0.0, true, 255.0);
    Cvar_BothTeamsAlpha = CreateConVar("medic_infect_teams_alpha", "255", "[Both Team Infected] Amount of Transperency", FCVAR_NOTIFY, true, 0.0, true, 255.0);

    Cvar_RTeamRed = CreateConVar("medic_infect_red_team_red", "255", "Amount of Red for the Red Team", FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_RTeamGreen = CreateConVar("medic_infect_red_team_green", "100", "Amount of Green for the Red Team", FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_RTeamBlue = CreateConVar("medic_infect_red_team_blue", "60", "Amount of Blue for the Red Team", FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_RTeamAlpha = CreateConVar("medic_infect_red_team_alpha", "255", "Amount of Transperency for the Red Team", FCVAR_PLUGIN|FCVAR_NOTIFY);

    Cvar_BTeamRed = CreateConVar("medic_infect_blue_team_red", "0", "Amount of Red for the Blue Team", FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_BTeamGreen = CreateConVar("medic_infect_blue_team_green", "255", "Amount of Green for the Blue Team", FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_BTeamBlue = CreateConVar("medic_infect_blue_team_blue", "100", "Amount of Blue for the Blue Team", FCVAR_PLUGIN|FCVAR_NOTIFY);
    Cvar_BTeamAlpha = CreateConVar("medic_infect_blue_team_alpha", "255", "Amount of Transperency for the Blue Team", FCVAR_PLUGIN|FCVAR_NOTIFY);

    HookEvent("teamplay_round_active", RoundStartEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_hurt",PlayerHurtEvent);
    HookEventEx("player_death", MedicModify, EventHookMode_Pre);

}

// Osaka: Start up the infection timer
public OnConfigsExecuted()
{
    InfectionTimer = CreateTimer(GetConVarFloat(Cvar_DmgTime), HandleInfection, _, TIMER_REPEAT);

    new Float:timeval = GetConVarFloat(Cvar_InfectMediCheckTime);
    if (timeval > 0.0)
        MediTimer = CreateTimer(timeval, HandleMediInfection, _, TIMER_REPEAT);
    else
        MediTimer = INVALID_HANDLE;

    timeval = GetConVarFloat(Cvar_SpreadCheckTime);
    if (timeval > 0.0)
        SpreadTimer = CreateTimer(timeval, HandleSpreadInfection, _, TIMER_REPEAT);
    else
        SpreadTimer = INVALID_HANDLE;

    //LogMessage("OnConfigsExecuted(), Infectiontimer=%d,MediTimer=%d,SpreadTimer=%d",
    //           InfectionTimer,MediTimer,SpreadTimer);

    HookConVarChange(Cvar_DmgTime, HandleInfectionChange);
    HookConVarChange(Cvar_InfectMediCheckTime, HandleMediChange);
    HookConVarChange(Cvar_SpreadCheckTime, HandleSpreadChange);
}

// Osaka: catching CVAR's is cheap; reallocating a timer is slower.
//	So catch the ConVar changes and change the timer only in those situations
public HandleInfectionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (InfectionTimer != INVALID_HANDLE)
        CloseHandle(InfectionTimer);

    InfectionTimer = CreateTimer(StringToFloat(newValue), HandleInfection, _, TIMER_REPEAT);
}

// Osaka: The timer which damages infected players
public Action:HandleInfection(Handle:timer)
{
    if(!NativeControl && !GetConVarBool(CvarEnable)) return;
    //LogMessage("HandleInfection");

    new maxplayers = GetMaxClients();
    for(new client = 1; client <= maxplayers; client++)
    {
        // Osaka: Don't check to see if they are in game. Infected people must be in game.
        //	Doing this reduces the CPU usage significantly for high change rates, but requires testing.
        if(ClientInfected[client] == 0)
            continue;

        // Naris: Let's prove Osaka's theory.
        else if(!IsClientInGame(client) || !IsPlayerAlive(client))
        {
            LogError("Assumption Failed in HandleInfection! %d is not in game or is dead", client);
            continue;
        }

        // Osaka: This is relatively expensive, but we need to keep them updated.
        new r, b, g, a;
        GetInfectColors(client, r, b, g, a);
        SetInfectColors(client, r, b, g, a);

        new hp = GetClientHealth(client);
        hp -= (NativeControl) ? NativeAmount[InfectionSource[client]] : GetConVarInt(Cvar_DmgAmount);

        if(hp <= 0)
            ForcePlayerSuicide(client);
        else
        {
            SetEntityHealth(client,hp);
            //SetEntProp(client, Prop_Send, "m_iHealth", hp, 1);
            //SetEntProp(client, Prop_Data, "m_iHealth", hp, 1);
        }
    }	
}

// Osaka: Redundant, but allows us to skip checks
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    ClientInfected[client] = 0;
    InfectionSource[client] = 0;
    ClientFriendlyInfected[client] = false;
    NativeMedicArmed[client] = false;
    NativeAmount[client] = 0;
    return true;
}

// Osaka: Redundant, but allows us to skip checks
public OnClientDisconnect(client)
{
    ClientInfected[client] = 0;
    InfectionSource[client] = 0;
    ClientFriendlyInfected[client] = false;
    NativeMedicArmed[client] = false;
    NativeAmount[client] = 0;
}

// Osaka: Modifies death message to give credit for infections
public Action:MedicModify(Handle:event, const String:name[], bool:dontBroadcast)
{
    new id = GetClientOfUserId(GetEventInt(event,"userid"));
    if (!ClientInfected[id])
        return Plugin_Continue;

    //LogMessage("MedicModify");

    new infector = ClientInfected[id];
    new source = InfectionSource[id];

    ClientInfected[id] = 0;
    InfectionSource[id] = 0;
    ClientFriendlyInfected[id] = false;

    if (IsClientInGame(id))
    {
        SetEntityRenderColor(id);
        //SetEntityRenderMode(id, RENDER_NORMAL);

        if (IsClientInGame(infector))
        {
            new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
            if (!attacker || attacker == id)
            {
                SetEventInt(event,"attacker",GetClientUserId(infector));
                if (source && source != infector)
                    SetEventInt(event,"assister",GetClientUserId(source));
                /*
                if(TF2_GetPlayerClass(infector) != TFClass_Medic)
                {
                    if(ClientInfected[infector])
                        SetEventInt(event,"assister",GetClientUserId(ClientInfected[infector]));
                }
                */
                //SetEventString(event,"weapon","infection");
                //SetEventInt(event,"customkill",1); // This makes the kill a Headshot!
            }
            else //if (attacker != infector)
            {
                new assister = GetEventInt(event,"assister");
                if (assister <= 0)
                {
                    if (source && assister != source && attacker != source)
                        SetEventInt(event,"assister",GetClientUserId(source));
                    else if (assister != infector && attacker != infector)
                        SetEventInt(event,"assister",GetClientUserId(infector));
                }
            }
        }
        else
            LogError("Assumption Failed in MedicModify -- infector %d is not in game", id);
    }
    else
        LogError("Assumption Failed in MedicModify -- infectee %d is not in game", id);
    return Plugin_Continue;
}

// Osaka: For Syringes, we use the critical attack function, and hope it works well enough. Time will tell.
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
    if(GetConVarBool(CvarEnable) && !NativeControl)
        return Plugin_Continue;
    else if (NativeControl && !NativeMedicArmed[client])
        return Plugin_Continue;
    else if (!GetConVarInt(Cvar_InfectSyringe) ||
             MedicInfectDelay[client] > GetGameTime() ||
             TF2_GetPlayerClass(client) != TFClass_Medic)
    {
        return Plugin_Continue;
    }
    else if(StrEqual(weaponname, "tf_weapon_syringegun_medic") )
    {
        MedicInject(client);
    }

    return Plugin_Continue;
}

// Osaka: These checks are worth it if the variables are usually false
//	Spreading the infection need not be in game frame, but some people might want it to be.
public OnGameFrame()
{
    if(MediTimer != INVALID_HANDLE)
        MediInfection();

    if(SpreadTimer != INVALID_HANDLE)
        SpreadInfection();
}

public HandleMediChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (MediTimer != INVALID_HANDLE)
        CloseHandle(MediTimer);

    new Float:val = StringToFloat(newValue);
    if(val > 0.0)
        MediTimer = CreateTimer(val, HandleMediInfection, _, TIMER_REPEAT);
    else
        MediTimer = INVALID_HANDLE;
}

// Osaka: There is no way around it; we need to check each medic and see if they are shooting.
//	I wish SP had an inline directive, but it doesn't. We'll suffer the cost of a function call for modularity
public Action:HandleMediInfection(Handle:timer)
{
    //LogMessage("HandleMediInfection()");
    MediInfection();
}

MediInfection()
{
    if(GetConVarBool(CvarEnable) && !NativeControl)
        return; 
    else if(!GetConVarInt(Cvar_InfectMedi))
        return;

    decl String:classname[32];
    new maxplayers = GetMaxClients();

    //LogMessage("MediInfection()");

    for(new client = 1; client <= maxplayers; client++)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            if (TF2_GetPlayerClass(client) == TFClass_Medic) 
            {
                new weaponent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                if (weaponent && GetEdictClassname(weaponent, classname , sizeof(classname)) )
                {
                    if(StrEqual(classname, "tf_weapon_medigun") )
                    {
                        //LogMessage("Medigun used by %N", client);
                        MedicInject(client);
                    }
                }
            }
        }
    }
}

stock MedicInject(client)
{
    //LogMessage("MedicInject(%d)",client);

    new buttons = GetClientButtons(client);
    if (buttons & (IN_ATTACK|IN_RELOAD) )
    {
        new target = GetClientAimTarget(client);
        if (target > 0) 
        {
            //LogMessage(">MedicInfect(%d,%d,%d)",target, client,(buttons & IN_RELOAD) != 0);
            MedicInfect(target, client, (buttons & IN_RELOAD) != 0);
            MedicInfectDelay[client] = GetGameTime() + GetConVarFloat(Cvar_InfectSucceededDelay);
            return;
        }
    }
    MedicInfectDelay[client] = GetGameTime() + GetConVarFloat(Cvar_InfectFailedDelay); 
}

public MedicInfect(to, from, bool:friendlyInfect)
{
    if (!GetConVarInt(Cvar_InfectEnable))
        return;

    else if (!IsClientInGame(to) || !IsClientInGame(from))
    {
        LogError("Assumption Failed in MedicInfect! %d or %d is not in game", to, from);
        return;
    }

    //LogMessage("MedicInfect(%d,%d,%d)",to,from,friendlyInfect);

    new same = GetClientTeam(to) == GetClientTeam(from);

    if (ClientInfected[to]) 
    {
        if (!friendlyInfect && same && GetConVarInt(Cvar_InfectHeal) )
            UnInfect(to, from); 
        return;
    }
    else if(!friendlyInfect && (same || !GetConVarInt(Cvar_InfectOpposingTeam) ) )
        return;
    else if(friendlyInfect && (!same || !GetConVarInt(Cvar_InfectSameTeam) ) )
        return;	
    else
    {
        if (NativeControl)
        {
            if (!NativeMedicArmed[from])
                return;	
        }

        if (MedicInfectDelay[from] > GetGameTime()) 
            return;	
        if (TF2_GetPlayerClass(to) == TFClass_Medic && !GetConVarInt(Cvar_InfectMedics) )
            return;

        decl Float:ori1[3], Float:ori2[3], Float:distance;
        distance = GetConVarFloat(Cvar_InfectDistance);

        if(distance > 0.1)
        {
            GetClientAbsOrigin(to, ori1);
            GetClientAbsOrigin(from, ori2);

            if( GetVectorDistance(ori1, ori2, true) > distance )
            {
                return;
            }
        }

        Infect(to, from, friendlyInfect, true);
    }
}

// Osaka: Spread algorithm
//	The naive algorithm would check each player against every other player, resulting in n^2 behavior (32 * 32)
//	However, note that infected players need only check against uninfected players, and uninfected players need not check at all
//	This reduces the complexity to (n * m), where n = infected and m = uninfected. (16 * 16)

//	How does this improve anything? 
//	The worst case is actually significantly better. 
//	32 * 32 checks is enormous, and done for every single iteration.
//	The worst case for n * m is when n = m, at which case it reduces to n^2.
//	HOWEVER, note that in this case, n = all/2, not n = all such as in the first example.
//	This leads me to believe the n * m algorithm to perform, on average, logarithmically.
//	I cannot prove it, however, for our bounded example of 32 players, it is obvious that 16 * 16 for a worst case is better than 32 * 32.

public HandleSpreadChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (SpreadTimer != INVALID_HANDLE)
        CloseHandle(SpreadTimer);

    new Float:val = StringToFloat(newValue);
    if(val > 0.0)
        SpreadTimer = CreateTimer(val, HandleSpreadInfection, _, TIMER_REPEAT);
    else
        SpreadTimer = INVALID_HANDLE;
}

public Action:HandleSpreadInfection(Handle:timer)
{
    SpreadInfection();
}

// Osaka: Enough of that, onto the function!
public SpreadInfection()
{
    if(!GetConVarInt(Cvar_SpreadEnable))
        return;

    //LogMessage("SpreadInfection");

    static Float:InfectedVec[MAXPLAYERS + 1][3];
    static Float:NotInfectedVec[MAXPLAYERS + 1][3];
    static InfectedPlayerVec[MAXPLAYERS + 1];
    static NotInfectedPlayerVec[MAXPLAYERS + 1];

    new InfectedCount = 0, NotInfectedCount = 0;

    new maxplayers = GetMaxClients();
    new client;
    for(client = 1; client <= maxplayers; client++)
    {
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
            continue;

        if(ClientInfected[client])
        {
            GetClientAbsOrigin(client, InfectedVec[InfectedCount]);
            InfectedPlayerVec[InfectedCount] = client;
            InfectedCount++;
        }
        else
        {
            GetClientAbsOrigin(client, NotInfectedVec[NotInfectedCount]);
            NotInfectedPlayerVec[NotInfectedCount] = client;
            NotInfectedCount++;
        }
    }

    if(NotInfectedCount == 0 || InfectedCount == 0)
        return;

    // Osaka: Check the infected against the uninfected
    new check;
    new Float:distance = GetConVarFloat(Cvar_SpreadDistance);
    for(client = 0; client < InfectedCount; client++)
    {
        for(check = 0; check < NotInfectedCount; check++)
        {
            // Osaka: We could gain speed by disabling those who are newly infected
            //	However, the common case is that players will NOT be infected via this method
            //	The reason for this is that there is a VERY LARGE amount of space where there ISN'T infected players
            //	Therefore, we reasonably optimize for the common case, and do not encumber the process
            //	This causes the worst case to be easier to predict, and makes certain we don't prematurely optimize

            if(GetVectorDistance(InfectedVec[client], NotInfectedVec[check], true) < distance )
            {
                TransmitInfection(NotInfectedPlayerVec[check],InfectedPlayerVec[client]);
            }
        }
    }
}

stock TransmitInfection(to,from)
{
    // Osaka: Don't allow infection at all if it is disabled
    if(!GetConVarInt(Cvar_SpreadEnable))
        return;

    else if (!IsClientInGame(from) || !IsClientInGame(to))
    {
        LogError("Assumption Failed in TransmitInfection! %d or %d is not in game", to, from);
        return;
    }

    // Osaka: Ignore all other options if spread all is on
    else if(GetConVarInt(Cvar_SpreadAll) )
    {
        Infect(to, from, GetClientTeam(from) == GetClientTeam(to), false);
        return;
    }

    else if (!GetConVarInt(Cvar_SpreadMedics) && (TF2_GetPlayerClass(to) == TFClass_Medic)  )
    {
        return;
    }

    // Osaka: Scan back and see if the original infector is about to be infected
    else if(!GetConVarInt(Cvar_SpreadInfector))
    {
        /*
           new a = from;
           while(ClientInfected[a])
           {
           if(ClientInfected[a] == to) return;
           a = ClientInfected[a];
           }
           */
        if (InfectionSource[from] == to)
            return;
    }

    // Osaka: are the teams identical?
    new t_same = GetClientTeam(from) == GetClientTeam(to);

    // Osaka: Spread to same team
    if(GetConVarInt(Cvar_SpreadSameTeam) && t_same )
    {
        Infect(to, from, true, false);
    }
    // Osaka: Spread to opposing team
    else if(GetConVarInt(Cvar_SpreadOpposingTeam) && !t_same )
    {
        Infect(to, from, false, false);
    }
    // Osaka: If a medic infects a friendly, allow the infection to spread across team boundaries
    else if(GetConVarInt(Cvar_InfectSameTeam) && !t_same && ClientFriendlyInfected[from] )
    {
        Infect(to, from, false, false);
    }
}

// Osaka: The encapsulated base of the infection. Add checking layers on top of this.
stock Infect(to, from, bool:friendly, bool:infect)
{
    if (GetConVarBool(CvarEnable) && !NativeControl)
        return; 
    else if (ClientInfected[to])
        return;

    new r, b, g, a;
    GetInfectColors(to, r, b, g, a);

    if (NativeHooked)
    {
        new Action:result = Plugin_Continue;
        new color[4];
        color[0] = r;
        color[1] = b;
        color[2] = g;
        color[3] = a;

        Call_StartForward(OnInfectedHandle);
        Call_PushCell(to);
        Call_PushCell(from);
        Call_PushCell(true);
        Call_PushArray(color, sizeof(color));
        Call_Finish(result);
        if (result != Plugin_Continue)
            return;
    }

    SetInfectColors(to, r, b, g, a);

    ClientInfected[to] = from;
    InfectionSource[to] = infect ? from : InfectionSource[from];
    ClientFriendlyInfected[to] = friendly;

    PrintHintText(to, "You have been infected!");

    if (infect)
        PrintHintText(from, "Virus administered!");
    else
        PrintHintText(from, "Virus spread!");
}

// Osaka: The encapsulated base of the uninfection. Add checking layers on top of this.
stock UnInfect(to, from=0)
{
    if(GetConVarBool(CvarEnable) && !NativeControl)
        return; 
    else if(!ClientInfected[to])
        return;

    if (NativeHooked)
    {
        new Action:result = Plugin_Continue;
        new color[4] = {255, 255, 255, 255};
        Call_StartForward(OnInfectedHandle);
        Call_PushCell(to);
        Call_PushCell(from);
        Call_PushCell(false);
        Call_PushArray(color, sizeof(color));
        Call_Finish(result);
        if (result != Plugin_Continue)
            return;
    }

    ClientInfected[to] = 0;
    ClientFriendlyInfected[to] = false;
    SetEntityRenderColor(to);

    if (IsPlayerAlive(to))
        PrintHintText(to, "You have been uninfected!");

    if (from)
        PrintHintText(from, "Anti-Virus administered!");
}

// Naris: Retrieve the colors to use for infected players from ConVars.
stock GetInfectColors(client, &r=0, &b=0, &g=0, &a=0)
{
    new TFTeam:team = TFTeam:GetClientTeam(client);
    new SameColors = GetConVarInt( Cvar_SameColors );

    // Osaka: This branch saves us two comparisons, and eliminates the need to check SameColors twice.
    if(SameColors > 1) team = TFTeam:SameColors;

    if( SameColors  == 1 )
    {
        r = GetConVarInt(Cvar_BothTeamsRed);
        b = GetConVarInt(Cvar_BothTeamsBlue);
        g = GetConVarInt(Cvar_BothTeamsGreen);
        a = GetConVarInt(Cvar_BothTeamsAlpha);
    }		
    else if( team == TFTeam_Red)
    {
        r = GetConVarInt(Cvar_RTeamRed);
        b = GetConVarInt(Cvar_RTeamBlue);
        g = GetConVarInt(Cvar_RTeamGreen);
        a = GetConVarInt(Cvar_RTeamAlpha);
    }
    else if( team == TFTeam_Blue)
    {
        r = GetConVarInt(Cvar_BTeamRed);
        b = GetConVarInt(Cvar_BTeamBlue);
        g = GetConVarInt(Cvar_BTeamGreen);
        a = GetConVarInt(Cvar_BTeamAlpha);
    }
}

// Osaka: Change the colors of the infected player, and their gun, depending on ConVar's
stock SetInfectColors(client, r, b, g, a)
{
    SetEntityRenderColor(client, r, b, g, a);

    // Osaka: Set their gun to their team color. Don't change alpha.
    new SameColors = GetConVarInt( Cvar_SameColors );
    if( GetConVarInt(Cvar_GunColors) || SameColors)
    {
        new TFTeam:team = TFTeam:GetClientTeam(client);
        new r2 = (team == TFTeam_Red) ? 255 : 0;
        new b2 = (team == TFTeam_Blue) ? 255: 0;
        new gun = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (gun > 0 && IsValidEntity(gun))
            SetEntityRenderColor(gun, r2, 0, b2, a);
    }
}

public Action:RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!NativeControl && GetConVarBool(CvarEnable) && GetConVarBool(CvarAnnounce))
    {
        if(GetConVarBool(Cvar_InfectOpposingTeam) )
        {
            if(GetConVarBool(Cvar_InfectMedi) )
                PrintToChatAll("%c[SM] %cMedics can infect enemy players using thier medigun", COLOR_GREEN,COLOR_DEFAULT);

            if(GetConVarBool(Cvar_InfectSyringe) )
                PrintToChatAll("%c[SM] %cMedics can infect enemy players using thier syringe gun", COLOR_GREEN,COLOR_DEFAULT);
        }

        if(GetConVarBool(Cvar_InfectSameTeam) )
            PrintToChatAll("%c[SM] %cMedics can infect teammates by reloading thier medigun", COLOR_GREEN,COLOR_DEFAULT);

        PrintToChatAll("%c[SM] %cMedics can heal infected teammates using thier medigun", COLOR_GREEN,COLOR_DEFAULT);

        new bool:spreadAll = GetConVarBool(Cvar_SpreadAll);

        if(!spreadAll && GetConVarBool(Cvar_InfectMedics) )
            PrintToChatAll("%c[SM] %cMedics are immune to infections", COLOR_GREEN,COLOR_DEFAULT);

        if(spreadAll || GetConVarBool(Cvar_SpreadSameTeam) )
            PrintToChatAll("%c[SM] %cInfections will spread to teammates", COLOR_GREEN,COLOR_DEFAULT);
        if(spreadAll || GetConVarBool(Cvar_SpreadOpposingTeam) )
            PrintToChatAll("%c[SM] %cInfections will spread to the enemy", COLOR_GREEN,COLOR_DEFAULT);
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
    ClientInfected[index]=0;
    InfectionSource[index] = 0;
    ClientFriendlyInfected[index]=false;
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new bool:infected = false;
    new victim=GetClientOfUserId(GetEventInt(event,"userid"));
    if (victim > 0)
    {
        new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
        if (attacker > 0 && attacker != victim &&
            MedicInfectDelay[attacker] <= GetGameTime() &&
            IsClientInGame(attacker) && IsPlayerAlive(attacker)) 
        {
            if (NativeControl)
            {
                if (NativeMedicArmed[attacker] &&
                    GetRandomInt(1,100)<=NativeChance[attacker])
                {
                    MedicInfect(victim, attacker, false);
                    MedicInfectDelay[attacker] = GetGameTime() + GetConVarFloat(Cvar_InfectSucceededDelay);
                    infected = true;
                }
            }
            else if (TF2_GetPlayerClass(attacker) == TFClass_Medic) 
            {
                decl String:weaponname[32];
                new weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
                if (weaponent && GetEdictClassname(weaponent, weaponname, sizeof(weaponname)) )
                {
                    if (StrEqual(weaponname, "tf_weapon_syringegun_medic") )
                    {
                        MedicInfect(victim, attacker, false);
                        MedicInfectDelay[attacker] = GetGameTime() + GetConVarFloat(Cvar_InfectSucceededDelay);
                        infected = true;
                    }
                }
            }
        }

        if (NativeControl && !infected)
        {
            new assister=GetClientOfUserId(GetEventInt(event,"assister"));
            if (assister > 0 && NativeMedicArmed[assister] &&
                MedicInfectDelay[assister] <= GetGameTime() &&
                IsClientInGame(assister) && IsPlayerAlive(assister)) 
            {
                if (NativeMedicArmed[assister] &&
                    GetRandomInt(1,100)<=NativeChance[assister])
                {
                    MedicInfect(victim, assister, false);
                    MedicInfectDelay[assister] = GetGameTime() + GetConVarFloat(Cvar_InfectSucceededDelay);
                }
            }
        }
    }
}


public Native_ControlMedicInfect(Handle:plugin,numParams)
{
    if (numParams == 0)
        NativeControl = true;
    else if(numParams == 1)
        NativeControl = GetNativeCell(1);
}

public Native_HookInfection(Handle:plugin,numParams)
{
    if(numParams == 1)
    {
        AddToForward(OnInfectedHandle, plugin, Function:GetNativeCell(1));
        NativeHooked = true;
    }
}

public Native_SetMedicInfect(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 4)
    {
        new client = GetNativeCell(1);
        NativeMedicArmed[client] = (numParams >= 2) ? GetNativeCell(2) : true;
        NativeAmount[client] = (numParams >= 3) ? GetNativeCell(3) : 0;
        NativeChance[client] = (numParams >= 4) ? GetNativeCell(4) : 100;
    }
}

public Native_MedicInfect(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 3)
    {
        new client = GetNativeCell(1);
        new target = GetNativeCell(2);
        new bool:allow = (numParams >= 3) ? (bool:GetNativeCell(3)) : false;
        MedicInfect(target,client,allow);
        MedicInfectDelay[client] = GetGameTime() + GetConVarFloat(Cvar_InfectSucceededDelay);
    }
}

public Native_HealInfect(Handle:plugin,numParams)
{
    if (numParams == 2)
    {
        new client = GetNativeCell(1);
        new target = GetNativeCell(2);
        if (ClientInfected[target] || ClientFriendlyInfected[target])
            UnInfect(target, client);
    }
}
