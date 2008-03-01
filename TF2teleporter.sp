#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0"

public Plugin:myinfo = 
{
  name = "Teleport Tools",
  author = "Nican132",
  description = "Decrease teleporter time in TF2",
  version = PL_VERSION,
  url = "http://sourcemod.net/"
};       

new maxents;
//new maxplayers;
//new ResourceEnt;

new TimeOffset, OwnerOffset, TeamOffset;
new Handle:TeleporterList;

#define LIST_SENTRY 0
#define LIST_TEAM 1
#define LIST_OWNER 2


#define ENABLEDTELE 0
#define TELEBLUETIME 1
#define TELEREDTIME 1

new Handle:g_cvars[3];
new Handle:teletimer = INVALID_HANDLE;

public OnPluginStart(){
	CreateConVar("sm_tf_teletools", PL_VERSION, "Teleport Tools", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cvars[ENABLEDTELE] = CreateConVar("sm_tele_on","1","Enable/Disable teleport manager");
	g_cvars[TELEBLUETIME] = CreateConVar("sm_teleblue_time","0.6","Amount of time for blue tele to recharg, 0.0 disable");
	g_cvars[TELEREDTIME] = CreateConVar("sm_telered_time","0.6","Amount of time for red tele to recharg, 0.0 disable");
	
	TimeOffset = FindSendPropInfo("CObjectTeleporter", "m_flRechargeTime");
	OwnerOffset = FindSendPropInfo("CObjectTeleporter", "m_hBuilder");
	TeamOffset = FindSendPropInfo("CObjectTeleporter", "m_iTeamNum");
	
	HookConVarChange(g_cvars[ENABLEDTELE],  TF2ConfigsChanged );
	HookConVarChange(g_cvars[TELEBLUETIME], TF2ConfigsChanged ); 
	HookConVarChange(g_cvars[TELEREDTIME],  TF2ConfigsChanged );
	
	TeleporterList = CreateArray( 3 );
	
	HookEvent("player_builtobject", Event_player_builtobject);
	
	Createtimers();
}

public TF2ConfigsChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
    Createtimers();
}

stock Createtimers(){
    if(teletimer != INVALID_HANDLE){
        KillTimer( teletimer );
        teletimer = INVALID_HANDLE;
    }
    
    if(!GetConVarBool( g_cvars[ENABLEDTELE] )){
        return;
    }
    
    if( GetConVarFloat( g_cvars[TELEBLUETIME] ) > 0.0 || GetConVarFloat( g_cvars[TELEREDTIME] ) > 0.0){
        //LogMessage("Creating timer!")
        teletimer = CreateTimer( 0.2, CheckAllTeles, 0, TIMER_REPEAT);    
    }
}

public Action:CheckAllTeles(Handle:timer, any:useless){
    new data[3] ,i, count = GetArraySize( TeleporterList );
    new Float:bluetime = GetConVarFloat( g_cvars[TELEBLUETIME] );
    new Float:redtime  = GetConVarFloat( g_cvars[TELEREDTIME] );
    
    new Float:oldtime, Float:newtime;
    
    for(i = 0; i< count; i++){
        GetArrayArray(TeleporterList, i, data);
        
        if(!IsValidEntity(data[ LIST_SENTRY ])){
            RemoveFromArray( TeleporterList, i);
            i--;
            count--;
            continue;
        }
        
        if( data[ LIST_TEAM ] == 3 && bluetime <= 0.0 )   {
            continue;        
        } else if( data[ LIST_TEAM ] == 2 && redtime <= 0.0 )   {
            continue;        
        }
        
        oldtime = GetEntDataFloat(data[ LIST_SENTRY ], TimeOffset);
        
        if( float(RoundFloat(oldtime)) == oldtime){ continue; }
        
        newtime = oldtime - 10.5;
        
        //LogMessage("Chane %0.2f %0.2f", newtime, oldtime);
        
        if( data[ LIST_TEAM ] == 3 )   {
            newtime +=  bluetime;      
        } else if( data[ LIST_TEAM ] == 2 )   {
            newtime += redtime;
        }
        
        //LogMessage("Newtime %0.2f", newtime);
        
        SetEntDataFloat(data[ LIST_SENTRY ], TimeOffset, float(RoundFloat(newtime)), true);
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
    
    ClearArray( TeleporterList );
    
    new i, info[3];
    decl String:classname[64];
    for(i = 24; i <= maxents; i++){
	 	if(IsValidEntity(i)){
			GetEntityNetClass(i, classname, 64);
			if(StrEqual(classname, "CObjectTeleporter")){				
                info[ LIST_SENTRY ] = i;
                info[ LIST_TEAM ] = GetEntData(i, TeamOffset, 4);
                info[ LIST_OWNER ] = GetEntDataEnt2(i, OwnerOffset);
                
                //LogMessage("Found: %d %d %d", i, info[ LIST_TEAM ], info[ LIST_OWNER ]);
                
                PushArrayArray(TeleporterList, info); 			
			}
		}
	} 
    
    return Plugin_Continue;
}

public OnMapStart(){
    //maxplayers = GetMaxClients();
    maxents = GetMaxEntities();
    //ResourceEnt = FindResourceObject();
	
    //if(ResourceEnt == 0)
    //    LogMessage("Attetion! Server could not find player data table");
}
/*
stock FindResourceObject(){
	new i, String:classname[64];
	
	//Isen't there a easier way?
	for(i = maxplayers; i <= maxents; i++){
	 	if(IsValidEntity(i)){
			GetEntityNetClass(i, classname, 64);
			if(StrEqual(classname, "CTFPlayerResource")){
					return i;
			}
		}
	}
	return 0;
}
*/
