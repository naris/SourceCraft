/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2teleporter.sp
 * Description: Decrease teleporter time in TF2
 * Author(s): Nican132
 */

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "3.0"

public Plugin:myinfo = 
{
    name = "Teleport Tools",
    author = "Nican132",
    description = "Decrease teleporter time in TF2",
    version = PL_VERSION,
    url = "http://sourcemod.net/"
};       

new maxents;
new maxplayers;

new TeleporterList[ MAXPLAYERS ][ 2 ];
new Float:TeleporterTime[ MAXPLAYERS ] = { 0.0, ...};

#define LIST_OBJECT 0
#define LIST_TEAM 1

#define ENABLEDTELE 0
#define TELEBLUETIME 1
#define TELEREDTIME 2
#define TELETIME 3

new Handle:g_cvars[4];
new Handle:teletimer = INVALID_HANDLE;

public OnPluginStart()
{
    CreateConVar("sm_tf_teletools", PL_VERSION, "Teleport Tools", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[ENABLEDTELE] = CreateConVar("sm_tele_on","1","Enable/Disable teleport manager");
    g_cvars[TELEBLUETIME] = CreateConVar("sm_teleblue_time","0.6","Amount of time for blue tele to recharg, 0.0=disable");
    g_cvars[TELEREDTIME] = CreateConVar("sm_telered_time","0.6","Amount of time for red tele to recharg, 0.0=disable");
    g_cvars[TELETIME] = CreateConVar("sm_tele_time","0.0","Amount of time for the recharge timer, 0.0=auto");

    HookEvent("player_builtobject", Event_player_builtobject);
}

public OnConfigsExecuted()
{
    Createtimers();

    HookConVarChange(g_cvars[ENABLEDTELE],  TF2ConfigsChanged );
    HookConVarChange(g_cvars[TELEBLUETIME], TF2ConfigsChanged ); 
    HookConVarChange(g_cvars[TELEREDTIME],  TF2ConfigsChanged );
    HookConVarChange(g_cvars[TELETIME],  TF2ConfigsChanged );
}

public TF2ConfigsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    Createtimers();
}

stock Createtimers()
{
    if(teletimer != INVALID_HANDLE)
    {
        KillTimer( teletimer );
        teletimer = INVALID_HANDLE;
    }

    if(GetConVarBool( g_cvars[ENABLEDTELE] ))
    {
        new Float:time = GetConVarFloat( g_cvars[TELETIME] );

        if (time > 0.0)
            CreateTeleTimer( time ); 
        else
        {
            new Float:bluetime = GetConVarFloat( g_cvars[TELEBLUETIME] );
            new Float:redtime  = GetConVarFloat( g_cvars[TELEREDTIME] );

            if(redtime > bluetime)
                CreateTeleTimer( bluetime );    
            else if (redtime > 0.0)
                CreateTeleTimer( redtime ); 
            else if (bluetime > 0.0)
                CreateTeleTimer( bluetime ); 
            else
                LogError("tf2_teletools have been disabled, sm_tele_on is set, but no sm_tele*_time values are");
        }
    }
}

stock CreateTeleTimer( Float:time )
{
    teletimer = CreateTimer( time, CheckAllTeles, 0, TIMER_REPEAT);
}

public Action:CheckAllTeles(Handle:timer, any:useless)
{
    new i;
    new Float:bluetime = GetConVarFloat( g_cvars[TELEBLUETIME] );
    new Float:redtime  = GetConVarFloat( g_cvars[TELEREDTIME] );

    new Float:oldtime, Float:newtime, Float:time;

    for(i = 1; i< maxplayers; i++)
    {    
        if(TeleporterList[i][LIST_OBJECT] == 0)
            continue;
        else if(!IsValidEntity(TeleporterList[i][LIST_OBJECT]))
        {
            TeleporterList[i][LIST_OBJECT] = 0;
            continue;
        }

        time = TeleporterTime[i];
        if (time <= 0.0)
        {
            if( TeleporterList[i][LIST_TEAM] == 3)
                time = bluetime;
            else if( TeleporterList[i][LIST_TEAM] == 2)
                time = redtime;
            else // Unknown Team!
                time = 0.0;

            if (time <= 0.0)
                continue;
        }

        oldtime = GetEntPropFloat(TeleporterList[i][LIST_OBJECT], Prop_Send, "m_flChargeLevel");
        if( float(RoundFloat(oldtime)) == oldtime)
            continue;

        newtime = oldtime - 10.5 + time;

        LogMessage("Change %0.2f %0.2f %0.2f", newtime, oldtime, GetGameTime());

        SetEntPropFloat(TeleporterList[i][LIST_OBJECT], Prop_Send, "m_flChargeLevel",
                        float(RoundFloat(newtime)));
    } 
}

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
    //new id = GetEventInt(event, "object");
    //Does not work, object return what type of structure it is
    //0=dispenser
    //1=teleporter entrance
    //2=teleporter exit
    //3=sentry

    if ( GetEventInt(event, "object") != 1)
        return Plugin_Continue;

    new i, owner;
    decl String:classname[19];
    for(i =  maxplayers + 1; i <= maxents; i++)
    {
        if(IsValidEntity(i))
        {
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CObjectTeleporter"))
            {
                if( GetEntProp(i, Prop_Send, "m_iObjectType") == 1 )
                {
                    owner = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
                    TeleporterList[owner][ LIST_TEAM ] = GetEntProp(i, Prop_Send, "m_iTeamNum");
                    TeleporterList[owner][ LIST_OBJECT ] = i;	
                }	
            }
        }
    } 

    return Plugin_Continue;
}

public OnMapStart()
{
    maxplayers = GetMaxClients();
    maxents = GetMaxEntities();
}
