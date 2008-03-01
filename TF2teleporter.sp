#include <sourcemod>
#include <sdktools>

#define PL_VERSION "2.0"

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
new TeleporterList[ 33 ][ 2 ], maxplayers;

#define LIST_SENTRY 0
#define LIST_TEAM 1


#define ENABLEDTELE 0
#define TELEBLUETIME 1
#define TELEREDTIME 1

new Handle:g_cvars[3];
new Handle:teletimer = INVALID_HANDLE;

new temp;

public OnPluginStart(){
	CreateConVar("sm_tf_teletools", PL_VERSION, "Teleport Tools", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cvars[ENABLEDTELE] = CreateConVar("sm_tele_on","1","Enable/Disable teleport manager");
	g_cvars[TELEBLUETIME] = CreateConVar("sm_teleblue_time","0.6","Amount of time for blue tele to recharg, 0.0 disable");
	g_cvars[TELEREDTIME] = CreateConVar("sm_telered_time","0.6","Amount of time for red tele to recharg, 0.0 disable");
	
	TimeOffset = FindSendPropInfo("CObjectTeleporter", "m_flRechargeTime");
	OwnerOffset = FindSendPropInfo("CObjectTeleporter", "m_hBuilder");
	TeamOffset = FindSendPropInfo("CObjectTeleporter", "m_iTeamNum");
	temp = FindSendPropInfo("CObjectTeleporter", "m_iObjectType");
	
	HookConVarChange(g_cvars[ENABLEDTELE],  TF2ConfigsChanged );
	HookConVarChange(g_cvars[TELEBLUETIME], TF2ConfigsChanged ); 
	HookConVarChange(g_cvars[TELEREDTIME],  TF2ConfigsChanged );
	
	
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
    
    new Float:bluetime = GetConVarFloat( g_cvars[TELEBLUETIME] );
    new Float:redtime  = GetConVarFloat( g_cvars[TELEREDTIME] );
    
    if( bluetime > 0.0 && redtime > 0.0){
        if(redtime > bluetime){
            CreateTeleTimer( bluetime );    
        } else if ( redtime < bluetime) {
            CreateTeleTimer( redtime );    
        } else{
            CreateTeleTimer( bluetime );    
        }
        return;
    }
    
    if (bluetime > 0.0){
        CreateTeleTimer( bluetime ); 
    }
    
    if (redtime > 0.0){
        CreateTeleTimer( redtime ); 
    }
}

stock CreateTeleTimer( Float:time ){
    teletimer = CreateTimer( time, CheckAllTeles, 0, TIMER_REPEAT);
}

public Action:CheckAllTeles(Handle:timer, any:useless){
    new i;
    new Float:bluetime = GetConVarFloat( g_cvars[TELEBLUETIME] );
    new Float:redtime  = GetConVarFloat( g_cvars[TELEREDTIME] );
    
    new Float:oldtime, Float:newtime;
    
    for(i = 1; i< maxplayers; i++){    
        if(TeleporterList[i][LIST_SENTRY] == 0)
            continue;
        
        if(!IsValidEntity(  TeleporterList[i][LIST_SENTRY])){
            TeleporterList[i][LIST_SENTRY] = 0;
            continue;
        }
        
        if( TeleporterList[i][ LIST_TEAM ] == 3 && bluetime <= 0.0 )   {
            continue;        
        } else if( TeleporterList[i][ LIST_TEAM ] == 2 && redtime <= 0.0 )   {
            continue;        
        }
        
        oldtime = GetEntDataFloat(TeleporterList[i][ LIST_SENTRY ], TimeOffset);
        
        if( float(RoundFloat(oldtime)) == oldtime){ continue; }
        
        newtime = oldtime - 10.5;
        
        //LogMessage("Chane %0.2f %0.2f", newtime, oldtime);
        
        if( TeleporterList[i][ LIST_TEAM ] == 3 )   {
            newtime +=  bluetime;      
        } else if( TeleporterList[i][ LIST_TEAM ] == 2 )   {
            newtime += redtime;
        }
        
        //LogMessage("Newtime %0.2f", newtime);
        
        SetEntDataFloat(TeleporterList[i][ LIST_SENTRY ], TimeOffset, float(RoundFloat(newtime)), true);
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
    for(i =  maxplayers + 1; i <= maxents; i++){
	 	if(IsValidEntity(i)){
			GetEntityNetClass(i, classname, sizeof(classname));
			if(StrEqual(classname, "CObjectTeleporter")){
		        if( GetEntData(i, temp, 4) == 1 ){
                    owner = GetEntDataEnt2(i, OwnerOffset);		    
                    TeleporterList[owner][ LIST_TEAM ] = GetEntData(i, TeamOffset, 4);
			        TeleporterList[owner][ LIST_SENTRY ] = i;	
                }	
			}
		}
	} 
    
    return Plugin_Continue;
}

public OnMapStart(){
    maxplayers = GetMaxClients();
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
