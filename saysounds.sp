/*
Say Sounds
Hell Phoenix
http://www.charliemaurice.com/plugins

This plugin is somewhat a port of the classic SankSounds.  Basically, it uses a chat trigger then plays a 
sound associated with it.  People get a certain "quota" of sounds per map (default is 5).  They are warned 
at a certain amount (default 3) that they only have so many left.  This plugin also allows you to ban 
people from the sounds, reset sound quotas for everyone or just one person, and allow only admins to use
certain sounds.  

Thanks To:
	Ferret for his initial sourcemod plugins.  I used a few functions from his plugins as a learning tool.
	Teame06 for his help with the string replace function
	Bailopan for the pack stream info
	
Versions:
	1.0
		* First Public Release!
	1.1
		* Removed "downloadtable extension" dependency
		* Added Insurgency Mod Support
	1.2
		* Fixed some errors
		* Added admin only triggers
		* Join/Exit sound added
	1.3
		* Made join/exit sounds for admins only
		* Fixed errors on linux
	1.4
		* Fixed sound reset bug (thanks to lambdacore for pointing it out)
		* Added join/exit and wazza sound files to the download
	1.5 September 26, 2007
		* Uses EmitSountToClient instead of play (should allow multiple sounds to play at once)
			- Note that the path for the file changed because of this...remove the sound/ from your 
				cfg file...IE. change sound/misc/wazza.wav to misc/wazza.wav
		* Clients using "!soundlist" in chat will get a list of triggers in their console
		* Added a cvar to control how long between each sound to wait and a message to the user

Todo:
	* Multiple sound files for trigger word
	* Optimise keyvalues usage
	* Save user settings
 
Cvarlist (default value):
	sm_sound_enable 1						Turns Sounds On/Off
	sm_sound_warn 3							Number of sounds to warn person at
	sm_sound_limit 5 						Maximum sounds per person
	sm_join_exit 0 							Play sounds when someone joins or exits the game
	sm_time_between_sounds 4.5 	Time between each sound trigger, 0.0 to disable checking

Admin Commands:
	sm_sound_ban <user>
	sm_sound_unban <user>
	sm_sound_reset <all|user>
	
User Commands:
	!sounds - when used in chat turns sounds on/off for that client
	!soundlist - when used in chat will print all the trigger words to the console

	
Make sure "saysounds.cfg" is in your addons/sourcemod/configs/ directory.
Sounds go in your mods "sound" directory (such as sound/misc/filename.wav).
File Format:
	"Sound Combinations"
		{
			"wazza"  //Word trigger
			{
				"file"	"misc/wazza.wav" //"file" is always there, next is the filepath (always starts with "sound/")
				"admin"	"1"	//1 is admin only, 0 is anyone
			}
		}
	
*/


#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1

#define PLUGIN_VERSION "1.6"
#define MAX_PLAYERS 64

new Handle:cvarsoundenable;
new Handle:cvarsoundlimit;
new Handle:cvarsoundwarn;
new Handle:cvarjoinexit;
new Handle:cvarpersonaljoinexit;
new Handle:cvartimebetween;
new Handle:listfile;
new Handle:hTopMenu = INVALID_HANDLE;
new String:soundlistfile[PLATFORM_MAX_PATH];
new restrict_playing_sounds[MAX_PLAYERS+1];
new SndOn[MAX_PLAYERS+1];
new SndCount[MAX_PLAYERS+1];
new Float:LastSound[MAX_PLAYERS+1];

public Plugin:myinfo = 
{
	name = "Say Sounds",
	author = "Hell Phoenix",
	description = "Say Sounds",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart(){
	CreateConVar("sm_saysounds_version", PLUGIN_VERSION, "Say Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarsoundenable = CreateConVar("sm_sound_enable","1","Turns Sounds On/Off",FCVAR_PLUGIN);
	cvarsoundwarn = CreateConVar("sm_sound_warn","3","Number of sounds to warn person at",FCVAR_PLUGIN);
	cvarsoundlimit = CreateConVar("sm_sound_limit","5","Maximum sounds per person",FCVAR_PLUGIN);
	cvarjoinexit = CreateConVar("sm_join_exit","0","Play sounds when someone joins or exits the game",FCVAR_PLUGIN);
	cvarpersonaljoinexit = CreateConVar("sm_personal_join_exit","0","Play sounds when specific steam ID joins or exits the game",FCVAR_PLUGIN);
	cvartimebetween = CreateConVar("sm_time_between_sounds","4.5","Time between each sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	RegAdminCmd("sm_sound_ban", Command_Sound_Ban, ADMFLAG_BAN, "sm_sound_ban <user> : Bans a player from using sounds");
	RegAdminCmd("sm_sound_unban", Command_Sound_Unban, ADMFLAG_BAN, "sm_sound_unban <user> : Unbans a player from using sounds");
	RegAdminCmd("sm_sound_reset", Command_Sound_Reset, ADMFLAG_BAN, "sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsurgencySay);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("soundlist", Command_Sound_List, "List available sounds to console");
	RegConsoleCmd("soundmenu", Command_Sound_Menu, "Display a menu of sounds to play");
	RegAdminCmd("adminsounds", Command_Admin_Sounds,ADMFLAG_RCON, "Display a menu of Admin sounds to play");

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
    /*************************************************************/
    /* Add a Play Admin Sound option to the SourceMod Admin Menu */
    /*************************************************************/

    /* Block us from being called twice */
    if (topmenu != hTopMenu)
    {
        /* Save the Handle */
        hTopMenu = topmenu;
        new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
        AddToTopMenu(hTopMenu, "Play_Admin_Sound", TopMenuObject_Item, Play_Admin_Sound, server_commands, "Play_Admin_Sound", ADMFLAG_GENERIC);
    }
}

public Play_Admin_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Play Admin Sound");
    }
    else if (action == TopMenuAction_SelectOption)
    {
	Sound_Menu(param,true);
    }
}

public OnMapStart(){
	CreateTimer(0.1, Load_Sounds);
}

public Action:Load_Sounds(Handle:timer){
	// precache sounds, loop through sounds
	BuildPath(Path_SM,soundlistfile,sizeof(soundlistfile),"configs/saysounds.cfg");
	if(!FileExists(soundlistfile)) {
		LogMessage("saysounds.cfg not parsed...file doesnt exist!");
	}else{
		listfile = CreateKeyValues("soundlist");
		FileToKeyValues(listfile,soundlistfile);
		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		do{
			decl String:filelocation[255];
			decl String:dl[255];
			KvGetString(listfile, "file", filelocation, sizeof(filelocation));
			Format(dl, sizeof(filelocation), "sound/%s", filelocation);
			if(FileExists(dl)){
				PrecacheSound(filelocation, true);
				AddFileToDownloadsTable(dl);
			}
		} while (KvGotoNextKey(listfile));
	}
}

public OnClientAuthorized(client, const String:auth[]){
	if(!IsFakeClient(client)){
		if(client != 0){
			SndOn[client] = 1;
			SndCount[client] = 0;
			LastSound[client] = 0.0;
			
			if(GetConVarInt(cvarjoinexit)){
				decl String:filelocation[255];
				if (KvJumpToKey(listfile, "JoinSound")){
					KvGetString(listfile, "file", filelocation, sizeof(filelocation));
					new adminonly = KvGetNum(listfile, "admin");
					new singleonly = KvGetNum(listfile, "single");

					new Handle:pack;
					CreateDataTimer(0.2,Command_Play_Sound,pack);
					WritePackCell(pack, client);
					WritePackCell(pack, adminonly);
					WritePackCell(pack, singleonly);
					WritePackString(pack, filelocation);

					SndCount[client] = 0;
				}
			}

			if(GetConVarInt(cvarpersonaljoinexit)){
				decl String:filelocation[255];
				if (KvJumpToKey(listfile, auth)){
					KvGetString(listfile, "file", filelocation, sizeof(filelocation));
					new adminonly = KvGetNum(listfile, "admin");
					new singleonly = KvGetNum(listfile, "single");

					new Handle:pack;
					CreateDataTimer(0.2,Command_Play_Sound,pack);
					WritePackCell(pack, client);
					WritePackCell(pack, adminonly);
					WritePackCell(pack, singleonly);
					WritePackString(pack, filelocation);

					SndCount[client] = 0;
				}
			}
		}
	}
}

public OnClientDisconnect(client){
	if(GetConVarInt(cvarjoinexit)){
		SndCount[client] = 0;

		decl String:filelocation[255];
		if (KvJumpToKey(listfile, "ExitSound")){
			KvGetString(listfile, "file", filelocation, sizeof(filelocation));
			new adminonly = KvGetNum(listfile, "admin");
			new singleonly = KvGetNum(listfile, "single");

			new Handle:pack;
			CreateDataTimer(0.2,Command_Play_Sound,pack);
			WritePackCell(pack, client);
			WritePackCell(pack, adminonly);
			WritePackCell(pack, singleonly);
			WritePackString(pack, filelocation);
		}
	}
}

public Action:Command_Say(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarInt(cvarsoundenable))
			return Plugin_Continue;
	
		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
		decl String:clientName[64];
		GetClientName(client,clientName,64);
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"'){
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
				speech[len-1] = '\0';
			}
		}
						
		if(strcmp(speech[startidx],"!sounds",false) == 0){
				if(SndOn[client] == 1){
					SndOn[client] = 0;
					PrintToChat(client,"[Say Sounds] Sounds Disabled");
				}else{
					SndOn[client] = 1;
					PrintToChat(client,"[Say Sounds] Sounds Enabled");
				}
				return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!soundlist",false) == 0){
			List_Sounds(client);
			PrintToChat(client,"[Say Sounds] Check your console for a list of sound triggers");
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!soundmenu",false) == 0){
			Sound_Menu(client,false);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!adminsounds",false) == 0){
			Sound_Menu(client,true);
			return Plugin_Handled;
		}
		
		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		decl String:buffer[255];
		decl String:filelocation[255];
		new adminonly;
		new singleonly;
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (strcmp(speech[startidx],buffer,false) == 0){
				KvGetString(listfile, "file", filelocation, sizeof(filelocation));
				adminonly = KvGetNum(listfile, "admin");
				singleonly = KvGetNum(listfile, "single");
				new Handle:pack;
				CreateDataTimer(0.1,Command_Play_Sound,pack);
				WritePackCell(pack, client);
				WritePackCell(pack, adminonly);
				WritePackCell(pack, singleonly);
				WritePackString(pack, filelocation);
				break;
			}
		} while (KvGotoNextKey(listfile));
 
		return Plugin_Continue;
	}	
	return Plugin_Continue;
}

public Action:Command_InsurgencySay(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarInt(cvarsoundenable))
			return Plugin_Continue;
	
		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
		decl String:clientName[64];
		GetClientName(client,clientName,64);
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 4;
		if (speech[0] == '"'){
			startidx = 5;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
				speech[len-1] = '\0';
			}
		}
						
		if(strcmp(speech[startidx],"!sounds",false) == 0){
				if(SndOn[client] == 1){
					SndOn[client] = 0;
					PrintToChat(client,"[Say Sounds] Sounds Disabled");
				}else{
					SndOn[client] = 1;
					PrintToChat(client,"[Say Sounds] Sounds Enabled");
				}
				return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!soundlist",false) == 0){
			List_Sounds(client);
			PrintToChat(client,"[Say Sounds] Check your console for a list of sound triggers");
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!soundmenu",false) == 0){
			Sound_Menu(client,false);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!adminsounds",false) == 0){
			Sound_Menu(client,true);
			return Plugin_Handled;
		}
			
		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		decl String:buffer[255];
		decl String:filelocation[255];
		new adminonly;
		new singleonly;
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (strcmp(speech[startidx],buffer,false) == 0){
				KvGetString(listfile, "file", filelocation, sizeof(filelocation));
				adminonly = KvGetNum(listfile, "admin");
				singleonly = KvGetNum(listfile, "single");
				new Handle:pack;
				CreateDataTimer(0.1,Command_Play_Sound,pack);
				WritePackCell(pack, client);
				WritePackCell(pack, adminonly);
				WritePackCell(pack, singleonly);
				WritePackString(pack, filelocation);
				break;
			}
		} while (KvGotoNextKey(listfile));
		
		return Plugin_Continue;
	}	
	return Plugin_Continue;
}

public Action:Command_Play_Sound(Handle:timer,Handle:pack){
	decl String:filelocation[255];
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new adminonly = ReadPackCell(pack);
	new singleonly = ReadPackCell(pack);
	ReadPackString(pack, filelocation, sizeof(filelocation));
	
	if(adminonly){
		new AdminId:aid = GetUserAdmin(client);
		if (aid == INVALID_ADMIN_ID)
			return Plugin_Handled;
	}
	
	new Float:waitTime = GetConVarFloat(cvartimebetween);
	new Float:thetime = GetGameTime();
	
	if (LastSound[client] >= thetime){
		PrintToChat(client,"[Say Sounds] Please dont spam the sounds!");
	}
	
	if ((SndCount[client] < GetConVarInt(cvarsoundlimit)) && (LastSound[client] < thetime)){
		SndCount[client] = (SndCount[client] + 1);
		LastSound[client] = thetime + waitTime;
		if (singleonly){
			if(IsClientInGame(client)){
				if(SndOn[client]){
					EmitSoundToClient(client, filelocation);
				}
			}
		}else{
			new playersconnected;
			playersconnected = GetMaxClients();
			for (new i = 1; i <= playersconnected; i++){
				if(IsClientInGame(i)){
					if(SndOn[i]){
						EmitSoundToClient(i, filelocation);
					}
				}
			}
		}
	}

	if ((SndCount[client]) >= GetConVarInt(cvarsoundlimit)){
		PrintToChat(client,"[Say Sounds] Sorry you have reached your sound quota!");
	}else if ((SndCount[client]) == GetConVarInt(cvarsoundwarn)){
		new numberleft;
		numberleft = (GetConVarInt(cvarsoundlimit) - GetConVarInt(cvarsoundwarn));
		PrintToChat(client,"[Say Sounds] You only have %d sounds left!",numberleft);
	}
	return Plugin_Handled;
}

public Action:Command_Sound_Reset(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
		return Plugin_Handled;	
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	if(strcmp(arg,"all",false) == 0 ){
		for (new i = 1; i <= MAX_PLAYERS; i++)
			SndCount[i] = 0;
		ReplyToCommand(client, "[Say Sounds] Quota has been reset for all players");	
	}else{
		new user[2];
		new numplayer = SearchForClients(arg, user, 2);
		
		if (numplayer == 0){
			ReplyToCommand(client, "[Say Sounds] No matching client");
			return Plugin_Handled;
		}else if (numplayer > 1){
			ReplyToCommand(client, "[Say Sounds] More than one client matches");
			return Plugin_Handled;
		}else if ((client != 0) && (!CanUserTarget(client, user[0]))){
			ReplyToCommand(client, "[Say Sounds] Unable to target");
			return Plugin_Handled;
		}else if (IsFakeClient(user[0])){
			ReplyToCommand(client, "[Say Sounds] Cannot target a bot");
			return Plugin_Handled;
		}
			
		SndCount[user[0]] = 0;
		new String:clientname[64];
		GetClientName(user[0],clientname,MAX_PLAYERS);
		ReplyToCommand(client, "[Say Sounds] Quota has been reset for %s", clientname);
	}
	return Plugin_Handled;
}

public Action:Command_Sound_Ban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_ban <user> : Bans a player from using sounds");
		return Plugin_Handled;	
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	new user[2];
	new numplayer = SearchForClients(arg, user, 2);
	
	if (numplayer == 0){
		ReplyToCommand(client, "[Say Sounds] No matching client");
		return Plugin_Handled;
	}else if (numplayer > 1){
		ReplyToCommand(client, "[Say Sounds] More than one client matches");
		return Plugin_Handled;
	}else if ((client != 0) && (!CanUserTarget(client, user[0]))){
		ReplyToCommand(client, "[Say Sounds] Unable to target");
		return Plugin_Handled;
	}else if (IsFakeClient(user[0])){
		ReplyToCommand(client, "[Say Sounds] Cannot target a bot");
		return Plugin_Handled;
	}
	
	new String:BanClient2[64];
	GetClientName(user[0],BanClient2,MAX_PLAYERS);
	
	if (restrict_playing_sounds[user[0]] == 1){
		ReplyToCommand(client, "[Say Sounds] %s is already banned!", BanClient2);
	}else{
		restrict_playing_sounds[user[0]]=1;
		ReplyToCommand(client,"[Say Sounds] %s has been banned!", BanClient2);
	}

	return Plugin_Handled;
}

public Action:Command_Sound_Unban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_unban <user> <1|0> : Unbans a player from using sounds");
		return Plugin_Handled;	
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	new user[2];
	new numplayer = SearchForClients(arg, user, 2);
	
	if (numplayer == 0){
		ReplyToCommand(client, "[Say Sounds] No matching client");
		return Plugin_Handled;
	}else if (numplayer > 1){
		ReplyToCommand(client, "[Say Sounds] More than one client matches");
		return Plugin_Handled;
	}else if ((client != 0) && (!CanUserTarget(client, user[0]))){
		ReplyToCommand(client, "[Say Sounds] Unable to target");
		return Plugin_Handled;
	}else if (IsFakeClient(user[0])){
		ReplyToCommand(client, "[Say Sounds] Cannot target a bot");
		return Plugin_Handled;
	}
	
	new String:BanClient2[64];
	GetClientName(user[0],BanClient2,MAX_PLAYERS);
	
	if (restrict_playing_sounds[user[0]] == 0){
		ReplyToCommand(client,"[Say Sounds] %s is not banned!", BanClient2);
	}else{
		restrict_playing_sounds[user[0]]=0;
		ReplyToCommand(client,"[Say Sounds] %s has been unbanned!", BanClient2);
	}
	return Plugin_Handled;
}


public Action:Command_Sound_List(client, args){
	List_Sounds(client);
}

List_Sounds(client){
	KvRewind(listfile);
	KvJumpToKey(listfile, "ExitSound", false);
	KvGotoNextKey(listfile, true);
	decl String:buffer[255];
	do{
		KvGetSectionName(listfile, buffer, sizeof(buffer));
		PrintToConsole(client, buffer);
	} while (KvGotoNextKey(listfile));
	
}

public Action:Command_Sound_Menu(client, args){
	Sound_Menu(client,false);
}

public Action:Command_Admin_Sounds(client, args){
	Sound_Menu(client,true);
}

public Sound_Menu(client, bool:adminsounds){
	new bool:isadmin = (GetUserAdmin(client) != INVALID_ADMIN_ID);
	if (!isadmin)
		adminsounds=false;

	new Handle:soundmenu=CreateMenu(Menu_Select);
	SetMenuExitButton(soundmenu,true);
	SetMenuTitle(soundmenu,"Choose a sound to play.");

	KvRewind(listfile);
	KvJumpToKey(listfile, "ExitSound", false);
	KvGotoNextKey(listfile, true);

	decl String:num[4];
	decl String:buffer[255];
	new count=1;

	do{
		Format(num,3,"%d",count);
		KvGetSectionName(listfile, buffer, sizeof(buffer));

		if (adminsounds)
		{
			if (KvGetNum(listfile, "admin"))
			{
				AddMenuItem(soundmenu,num,buffer);
				count++;
			}
		}
		else
		{
			if (!KvGetNum(listfile, "admin") || isadmin)
			{
				AddMenuItem(soundmenu,num,buffer);
				count++;
			}
		}
	} while (KvGotoNextKey(listfile));

	DisplayMenu(soundmenu,client,MENU_TIME_FOREVER);
}

public Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
	    decl String:SelectionInfo[4];
	    decl String:SelectionDispText[256];
	    new SelectionStyle;
	    if (GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText))){
		    KvRewind(listfile);
		    KvGotoFirstSubKey(listfile);
		    decl String:buffer[255];
		    decl String:filelocation[255];
		    new adminonly;
		    new singleonly;
		    do{
			    KvGetSectionName(listfile, buffer, sizeof(buffer));
			    if (strcmp(SelectionDispText,buffer,false) == 0){
				    KvGetString(listfile, "file", filelocation, sizeof(filelocation));
				    adminonly = KvGetNum(listfile, "admin");
				    singleonly = KvGetNum(listfile, "single");
				    new Handle:pack;
				    CreateDataTimer(0.1,Command_Play_Sound,pack);
				    WritePackCell(pack, client);
				    WritePackCell(pack, adminonly);
				    WritePackCell(pack, singleonly);
				    WritePackString(pack, filelocation);
				    break;
			    }
		    } while (KvGotoNextKey(listfile));
	    }
    }
}

public OnPluginEnd(){
  CloseHandle(listfile);
}
