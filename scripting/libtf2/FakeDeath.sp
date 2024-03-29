/*
 *  vim: set ai et ts=4 sw=4 :

	死んだ振りMOD
*/

/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#include "entlimit"

#undef REQUIRE_PLUGIN
#include "lib/ResourceManager"
#define REQUIRE_PLUGIN

#define PL_VERSION "0.0.2"
#define SOUND_A "misc/talk.wav"

new String:DeathSound[][] = { "vo/spy_painsevere01.wav", "vo/spy_painsevere02.wav",  "vo/spy_painsevere03.wav",
                              "vo/spy_painsevere04.wav",  "vo/spy_painsevere05.wav",  "vo/spy_painsharp01.wav",
                              "vo/spy_painsharp02.wav", "vo/spy_painsharp03.wav", "vo/spy_painsharp04.wav",
							  "vo/spy_paincrticialdeath01.wav", "vo/spy_paincrticialdeath02.wav", "vo/spy_paincrticialdeath03.wav" };

new String:GenericDeathSound[][]  = { "player/death.wav" };
/*
new String:GenericDeathSound[][] = { "player/death3.wav", "player/death5.wav",  "player/death5.wav",
                                     "player/death7.wav",  "player/death8.wav",  "player/death9.wav",
			             "player/death10.wav" };
*/

public Plugin:myinfo = 
{
	name = "Fake Death",
	author = "RIKUSYO",
	description = "Spy Fake Death.",
	version = PL_VERSION,
	url = "http://ameblo.jp/rikusyo/"
}

new Handle:g_PlayerButtonDown[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_NextBody[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_IsFakeDeathOn = INVALID_HANDLE;
new Handle:g_UseCloakMeter = INVALID_HANDLE;
new Handle:g_IsStartMessageOn = INVALID_HANDLE;
new Handle:g_IsDeathMessageOn = INVALID_HANDLE;
new Handle:g_WaitTime = INVALID_HANDLE;
new Handle:g_FakeLimit = INVALID_HANDLE;
new Handle:g_Dissolve = INVALID_HANDLE;

new AtacanteID[MAXPLAYERS+1];
new String:WeaponName[MAXPLAYERS+1][32];

new bool:g_NativeControl = false;
new g_Limit[MAXPLAYERS+1];    // how many fakes player allowed
new g_Remaining[MAXPLAYERS+1];  // how many fakes player has this spawn
new bool:g_NativeDissolve[MAXPLAYERS+1];  // which players should dissolve.

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlDeath",Native_ControlDeath);
    CreateNative("GiveDeath",Native_GiveDeath);
    CreateNative("TakeDeath",Native_TakeDeath);
    CreateNative("FakeDeath",Native_FakeDeath);
    RegPluginLibrary("FakeDeath");
    return APLRes_Success;
}

public OnPluginStart()
{
	// 言語ファイル読込
	LoadTranslations("common.phrases");
	LoadTranslations("fake_death.phrases");
	
	// コマンド作成
	CreateConVar("sm_rmf_tf_fake_death", PL_VERSION, "Fake Death", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_IsFakeDeathOn = CreateConVar("sm_rmf_fake_death","0","Enable/Disable Fake Death (0 = disabled | 1 = enabled)");
	g_UseCloakMeter = CreateConVar("sm_rmf_use_cloak_meter","10.0","Cloak Meter required for fake death(0.0-100.0)");
	g_IsStartMessageOn = CreateConVar("sm_rmf_start_message","0","Enable/Disable start message (0 = disabled | 1 = enabled)");
	g_IsDeathMessageOn = CreateConVar("sm_rmf_death_message","1","Enable/Disable death message (0 = disabled | 1 = enabled)");
	g_WaitTime = CreateConVar("sm_rmf_wait_time","3.0","Time before can show the next body(0.0-10.0)");
	g_FakeLimit = CreateConVar("sm_rmf_limit", "-1", "Number of fake deaths allowed per life (-1 = unlimited)");
	g_Dissolve = CreateConVar("sm_rmf_dissolve", "0", "Dissolve ragdolls (0 = disabled | 1 = enabled)");

	// ConVarフック
	HookConVarChange(g_IsFakeDeathOn, ConVarChange_IsFakeDeathOn);
	HookConVarChange(g_UseCloakMeter, ConVarChange_UseCloakMeter);
	HookConVarChange(g_WaitTime, ConVarChange_WaitTime);

	// イベントフック
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_changeclass", Event_PlayerClass);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("teamplay_round_active", Event_RoundStart);
	HookEvent("player_hurt", Event_PlayerHurt); 
	
}


/////////////////////////////////////////////////////////////////////
//
// マップ開始
//
/////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	SetupModel("models/player/hwm/spy.mdl", .precache=true);
	
	SetupSound(SOUND_A, true);

	for (new i = 0; i < sizeof(DeathSound); i++)
	    SetupSound(DeathSound[i], true);

	for (new i = 0; i < sizeof(GenericDeathSound); i++)
	    SetupSound(GenericDeathSound[i], true);
}

/////////////////////////////////////////////////////////////////////
//
// クライアント切断
//
/////////////////////////////////////////////////////////////////////
public OnClientDisconnect(client)
{
	g_Remaining[client] = g_Limit[client] = 0;
	
	if(g_PlayerButtonDown[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerButtonDown[client]);
		g_PlayerButtonDown[client] = INVALID_HANDLE;
	}
	if(g_NextBody[client] != INVALID_HANDLE)
	{
		KillTimer(g_NextBody[client]);
		g_NextBody[client] = INVALID_HANDLE;
	}
		
}


/////////////////////////////////////////////////////////////////////
//
// ゲームフレーム
//
/////////////////////////////////////////////////////////////////////
public OnGameFrame()
{	
	// MOD有効？
	if (!g_NativeControl && !GetConVarBool(g_IsFakeDeathOn))
		return;

	for (new i = 1; i <= MaxClients; i++)
	{
		//スパイ、ボタン押してない、ゲームしてる
		if (g_Remaining[i] && g_PlayerButtonDown[i] == INVALID_HANDLE && IsClientInGame(i))
		{
			// アタック1
			if (TF2_IsPlayerInCondition(i,TFCond_Cloaked) && (GetClientButtons(i) & IN_ATTACK))
			{
				// 連続押し防止？
				g_PlayerButtonDown[i] = CreateTimer(0.5, Timer_ButtonUp, i);
			
				// 偽物の死体さくせい
				TF_SpawnFakeBody(i);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ボタンアップ
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_ButtonUp(Handle:timer, any:client)
{
	g_PlayerButtonDown[client] = INVALID_HANDLE;
}

/////////////////////////////////////////////////////////////////////
//
// 次の死体
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_NextBodyTimer(Handle:timer, any:client)
{
	g_NextBody[client] = INVALID_HANDLE;
}

/////////////////////////////////////////////////////////////////////
//
// MODのOn/Off変更
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_IsFakeDeathOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) > 0)
		PrintToChatAll("\x05[RMF]\x01 %t", "Enabled Fake Death");
	else
		PrintToChatAll("\x05[RMF]\x01 %t", "Disabled Fake Death");
}

/////////////////////////////////////////////////////////////////////
//
// クロークメーター使用量の設定
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_UseCloakMeter(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0〜100.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 100.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 100.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 次の死体を出せるまでの待ち時間の設定
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_WaitTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0〜10.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 10.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 10.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// ラウンド開始
//
/////////////////////////////////////////////////////////////////////
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new FakeDeathOn = GetConVarInt(g_IsFakeDeathOn)
	new StartMessageOn = GetConVarInt(g_IsStartMessageOn)
	if(FakeDeathOn && StartMessageOn)
	{
		PrintToChatAll("\x05[RMF]\x01 %t", "OnCommand Fake Death", GetConVarInt(g_UseCloakMeter) );
	}

}

/////////////////////////////////////////////////////////////////////
//
// プレイヤー復活
//
/////////////////////////////////////////////////////////////////////
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_NativeControl)
	    g_Remaining[client] = g_Limit[client];
	else
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (class != TFClass_Spy)
	    		g_Remaining[client] = g_Limit[client] = 0;
		else
	    		g_Remaining[client] = g_Limit[client] = GetConVarInt(g_FakeLimit);
	}

	if (g_Remaining[client] == 0)
	{
		return;
	}
	
	if(g_PlayerButtonDown[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerButtonDown[client]);
		g_PlayerButtonDown[client] = INVALID_HANDLE;
	}
	if(g_NextBody[client] != INVALID_HANDLE)
	{
		KillTimer(g_NextBody[client]);
		g_NextBody[client] = INVALID_HANDLE;
	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤークラス変更
//
/////////////////////////////////////////////////////////////////////
public Action:Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_PlayerButtonDown[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerButtonDown[client]);
		g_PlayerButtonDown[client] = INVALID_HANDLE;
	}
	if(g_NextBody[client] != INVALID_HANDLE)
	{
		KillTimer(g_NextBody[client]);
		g_NextBody[client] = INVALID_HANDLE;
	}
	
	new any:class = GetEventInt(event, "class");
	if (class != TFClass_Spy)
	{
		return;
	}

	new FakeDeathOn = GetConVarInt(g_IsFakeDeathOn)
	if(FakeDeathOn)
	{
		PrintToChat(client, "\x05[RMF]\x01 %t", "OnCommand Fake Death", GetConVarInt(g_UseCloakMeter) );
	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤー死亡
//
/////////////////////////////////////////////////////////////////////
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_PlayerButtonDown[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerButtonDown[client]);
		g_PlayerButtonDown[client] = INVALID_HANDLE;
	}
	if(g_NextBody[client] != INVALID_HANDLE)
	{
		KillTimer(g_NextBody[client]);
		g_NextBody[client] = INVALID_HANDLE;
	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーチーム変更
//
/////////////////////////////////////////////////////////////////////
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_PlayerButtonDown[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerButtonDown[client]);
		g_PlayerButtonDown[client] = INVALID_HANDLE;
	}
	if(g_NextBody[client] != INVALID_HANDLE)
	{
		KillTimer(g_NextBody[client]);
		g_NextBody[client] = INVALID_HANDLE;
	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーダメージ
//
/////////////////////////////////////////////////////////////////////
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// new victimId = GetEventInt(event, "userid")
	new client_victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_Remaining[client_victim] && GetConVarInt(g_IsDeathMessageOn))
	{
		new userid_attacker = GetEventInt(event, "attacker"); 
		AtacanteID[client_victim] = userid_attacker; 
		if (userid_attacker>0)
			GetClientWeapon(GetClientOfUserId(GetEventInt(event, "attacker")), WeaponName[client_victim], sizeof(WeaponName[]));
		else
			WeaponName[client_victim][0] = '\0';
	}
	return Plugin_Continue;
}


/////////////////////////////////////////////////////////////////////
//
// 武器クラス取得
//
/////////////////////////////////////////////////////////////////////
stock TF_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (index != 0)
		GetEntityNetClass(index, name, maxlength);
}

/////////////////////////////////////////////////////////////////////
//
// クロークメーター取得
//
/////////////////////////////////////////////////////////////////////
stock Float:TF2_GetCloakMeter(client)
{
    return GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
}

/////////////////////////////////////////////////////////////////////
//
// クロークメーター設定
//
/////////////////////////////////////////////////////////////////////
stock TF2_SetCloakMeter(client,Float:cloakMeter)
{
    SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloakMeter);
}

/////////////////////////////////////////////////////////////////////
//
// ヘルス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetHealth(client)
{
    return GetEntData(client, FindDataMapOffs(client, "m_iHealth")); 
}

/////////////////////////////////////////////////////////////////////
//
// 偽の死体作成
//
/////////////////////////////////////////////////////////////////////
stock TF_SpawnFakeBody(client)
{
	if (g_Remaining[client] > 0 || g_Limit[client] < 0 &&
	    !IsEntLimitReached(.client=client, .message="Unable to create tf_ragdoll entity"))
	{
		// メーター使用量
		new TFClassType:class = TF2_GetPlayerClass(client);
		new Float:UseMeter = (class == TFClass_Spy) ? GetConVarFloat(g_UseCloakMeter) : 0.0;
		new Float:NowMeter = (UseMeter > 0.0) ? TF2_GetCloakMeter(client) : 1.0;
		// 次に押せるまでの時間
		new Float:WaitTime = GetConVarFloat(g_WaitTime);
		new bool:dissolve = g_NativeDissolve[client] || GetConVarBool(g_Dissolve);
		new bool:explode = false;

		if( NowMeter > UseMeter  && g_NextBody[client] == INVALID_HANDLE)
		{
			if(GetConVarInt(g_IsDeathMessageOn))
			{
				new WeaponID;
				new String:WeaponName2[32];
				new CustomID = 0;

				// || !IsClientInGame(AtacanteID[client])
				if(!AtacanteID[client])
				{
					WeaponID = 0;
					CustomID = 6;
					AtacanteID[client] = GetClientUserId(client);
					WeaponName2 = "world";
					WeaponName[client] = "world"
				}
				else if(StrEqual("tf_weapon_bat", WeaponName[client], false))
				{
					WeaponID = 1;
					WeaponName2 = "bat";
				}
				else if(StrEqual("tf_weapon_bottle", WeaponName[client], false))
				{
					WeaponID = 2;
					WeaponName2 = "bottle";
				}
				else if(StrEqual("tf_weapon_fireaxe", WeaponName[client], false))
				{
					WeaponID = 3;
					WeaponName2 = "fireaxe";
				}
				else if(StrEqual("tf_weapon_axtinguisher", WeaponName[client], false))
				{
					WeaponID = 3;
					WeaponName2 = "axtinguisher";
				}
				else if(StrEqual("tf_weapon_club", WeaponName[client], false))
				{
					WeaponID = 4;
					WeaponName2 = "club";
				}
				else if(StrEqual("tf_weapon_knife", WeaponName[client], false))
				{
					WeaponID = 6;
					WeaponName2 = "knife";
				}
				else if(StrEqual("tf_weapon_fists", WeaponName[client], false))
				{
					WeaponID = 7;
					WeaponName2 = "fists";
				}
				else if(StrEqual("tf_weapon_shovel", WeaponName[client], false))
				{
					WeaponID = 8;
					WeaponName2 = "shovel";
				}
				else if(StrEqual("tf_weapon_wrench", WeaponName[client], false))
				{
					WeaponID = 9;
					WeaponName2 = "wrench";
				}
				else if(StrEqual("tf_weapon_bonesaw", WeaponName[client], false))
				{
					WeaponID = 9;
					WeaponName2 = "bonesaw";
				}
				else if(StrEqual("tf_weapon_ubersaw", WeaponName[client], false))
				{
					WeaponID = 9;
					WeaponName2 = "ubersaw";
				}
				else if(StrEqual("tf_weapon_shotgun_primary", WeaponName[client], false))
				{
					WeaponID = 11;
					WeaponName2 = "shotgun_primary";
				}
				else if(StrEqual("tf_weapon_shotgun_soldier", WeaponName[client], false))
				{
					WeaponID = 12;
					WeaponName2 = "shotgun_soldier";
				}
				else if(StrEqual("tf_weapon_shotgun_hwg", WeaponName[client], false))
				{
					WeaponID = 13;
					WeaponName2 = "shotgun_hwg";
				}
				else if(StrEqual("tf_weapon_shotgun_pyro", WeaponName[client], false))
				{
					WeaponID = 14;
					WeaponName2 = "shotgun_pyro";
				}
				else if(StrEqual("tf_weapon_scattergun", WeaponName[client], false))
				{
					WeaponID = 15;
					WeaponName2 = "scattergun";
				}
				else if(StrEqual("tf_weapon_sniperrifle", WeaponName[client], false))
				{
					WeaponID = 16;
					WeaponName2 = "sniperrifle";
				}
				else if(StrEqual("tf_weapon_minigun", WeaponName[client], false))
				{
					WeaponID = 17;
					WeaponName2 = "minigun";
				}
				else if(StrEqual("tf_weapon_smg", WeaponName[client], false))
				{
					WeaponID = 18;
					WeaponName2 = "smg";
				}
				else if(StrEqual("tf_weapon_syringegun_medic", WeaponName[client], false)){
					WeaponID = 19;
					WeaponName2 = "syringegun_medic";
				}
				else if(StrEqual("tf_weapon_blutsauger", WeaponName[client], false))
				{
					WeaponID = 19;
					WeaponName2 = "blutsauger";
				}
				else if(StrEqual("tf_weapon_rocketlauncher", WeaponName[client], false)){
					WeaponID = 21;
					WeaponName2 = "tf_projectile_rocket";
					explode = true;
				}
				else if(StrEqual("tf_weapon_flamethrower", WeaponName[client], false))
				{
					WeaponID = 24;
					WeaponName2 = "flamethrower";
				}
				else if(StrEqual("tf_weapon_backburner", WeaponName[client], false))
				{
					WeaponID = 24;
					WeaponName2 = "backburner";
				}
				else if(StrEqual("tf_weapon_pipebomblauncher", WeaponName[client], false))
				{
					WeaponID = 34;
					WeaponName2 = "tf_projectile_pipe_remote";
					explode = true;
				}
				else if(StrEqual("tf_weapon_pistol", WeaponName[client], false))
				{
					WeaponID = 37;
					WeaponName2 = "pistol";
				}
				else if(StrEqual("tf_weapon_pistol_scout", WeaponName[client], false))
				{
					WeaponID = 38;
					WeaponName2 = "pistol_scout";
				}
				else if(StrEqual("tf_weapon_revolver", WeaponName[client], false))
				{
					WeaponID = 39;
					WeaponName2 = "revolver";
				}
				else if(StrEqual("tf_weapon_grenadelauncher", WeaponName[client], false)){
					WeaponID = 49;
					WeaponName2 = "tf_projectile_pipe";
					explode = true;
				}
				else if(StrEqual("tf_weapon_flaregun", WeaponName[client], false))
				{
					WeaponID = 54;
					WeaponName2 = "flaregun";
				}
				else
				{
					WeaponID = 0;
					CustomID = 6;
					AtacanteID[client] = GetClientUserId(client);
					WeaponName2 = "world";
					WeaponName[client] = "world"
				}

				new Handle:hPlayerDeath = CreateEvent("player_death", true);
				SetEventInt(hPlayerDeath, "userid", GetClientUserId(client));	
				SetEventInt(hPlayerDeath, "attacker", AtacanteID[client]);
				SetEventString(hPlayerDeath, "weapon",	WeaponName2);
				SetEventInt(hPlayerDeath, "weaponid", WeaponID);
				SetEventInt(hPlayerDeath, "damagebits", 0);
				SetEventInt(hPlayerDeath, "customkill", CustomID);
				SetEventInt(hPlayerDeath, "death_flags", TF_DEATHFLAG_DEADRINGER);
				SetEventInt(hPlayerDeath, "assister", -1);
				SetEventInt(hPlayerDeath, "dominated", 0);
				SetEventInt(hPlayerDeath, "assister_dominated", 0);
				SetEventInt(hPlayerDeath, "revenge", 0);
				SetEventInt(hPlayerDeath, "assister_revenge", 0);
				SetEventString(hPlayerDeath, "weapon_logclassname", WeaponName[client]);
				FireEvent(hPlayerDeath);
			}

			new FakeBody = CreateEntityByName("tf_ragdoll");

			if (FakeBody > 0 && IsValidEntity(FakeBody) && DispatchSpawn(FakeBody))
			{
				new Float:PlayerPosition[3];
				//new Float:PlayerForce[3];
					
				// 発生位置
				GetClientAbsOrigin(client, PlayerPosition);
				new offset; // = FindSendPropOffs("CTFRagdoll", "m_vecRagdollOrigin");
				FindSendPropInfo("CTFRagdoll", "m_vecRagdollOrigin", .local_offset=offset);
				SetEntDataVector(FakeBody, offset, PlayerPosition);
				
				// 死体のクラスはスパイ
				FindSendPropInfo("CTFRagdoll", "m_iClass", .local_offset=offset);
				SetEntData(FakeBody, offset, class);
				
				FindSendPropInfo("CTFRagdoll", "m_iPlayerIndex", .local_offset=offset);
				//new offset2 = FindSendPropOffs("CTFPlayer", "m_nForceBone");
				//new aaa = GetEntData(client, offset2); 
				SetEntData(FakeBody, offset, client);
				
/*				
				offset = FindDataMapOffs(client, "m_bitsDamageType");
				if( (GetEntData(client, offset) & 16779272) != 0 )
				{
					FindSendPropInfo("CTFRagdoll", "m_bBurning", .local_offset=offset);
					SetEntData(FakeBody, offset, 1);
				}
*/
				
//				FindSendPropInfo("CTFPlayer", "m_nDrownDmgRate", .local_offset=offset);
//				offset = FindDataMapOffs(client, "m_nDrownDmgRate");
			
				//SetEntData(FakeBody, offset3, 1);
//				PrintToChatAll("%d", GetEntData(client, offset));

				// 死体のチームカラー
				new team = GetClientTeam(client);
				FindSendPropInfo("CTFRagdoll", "m_iTeam", .local_offset=offset);
				SetEntData(FakeBody, offset, team);

				if(TF2_IsPlayerInCondition(client,TFCond_OnFire))
				{
					FindSendPropInfo("CTFRagdoll", "m_bBurning", .local_offset=offset);
					SetEntData(FakeBody, offset, 1);
				}

				if (explode)
					SetEntProp(FakeBody, Prop_Send, "m_bGib", 1)
				else if (dissolve)
					CreateTimer(0.1, DissolveRagdoll, EntIndexToEntRef(FakeBody)); 

				if (class == TFClass_Spy)	
				{
					PrepareAndEmitSoundToAll(DeathSound[GetRandomInt(0,sizeof(DeathSound)-1)], FakeBody, _, _, _, 1.0);

					NowMeter = NowMeter - UseMeter;
					TF2_SetCloakMeter(client,NowMeter);
				}
				else
				{
					PrepareAndEmitSoundToAll(GenericDeathSound[GetRandomInt(0,sizeof(GenericDeathSound)-1)], FakeBody, _, _, _, 1.0);
				}

				g_NextBody[client] = CreateTimer(WaitTime, Timer_NextBodyTimer, client);
				return;
			}		
		}
	}
	PrepareAndEmitSoundToClient(client, SOUND_A, _, _, _, _, 0.55);
}

public Action:DissolveRagdoll(Handle:timer, any:ref)
{
    new ragdoll = EntRefToEntIndex(ref);
    if (ragdoll <= 0 || !IsValidEntity(ragdoll))
        return;

    if (!IsEntLimitReached(.message="Unable to spawn an env_entity_dissolver"))
    {
	    new String:dname[32];
	    Format(dname, sizeof(dname), "dis_%d", ragdoll);

	    new ent = CreateEntityByName("env_entity_dissolver");
	    if (ent > 0)
	    {
		    DispatchKeyValue(ragdoll, "targetname", dname);
		    DispatchKeyValue(ent, "dissolvetype", "0");
		    DispatchKeyValue(ent, "target", dname);
		    AcceptEntityInput(ent, "Dissolve");
		    AcceptEntityInput(ent, "kill");
	    }
    }
}

/////////////////////////////////////////////////////////////////////
//
// Native Interface
//
/////////////////////////////////////////////////////////////////////
public Native_ControlDeath(Handle:plugin,numParams)
{
    if (numParams == 0)
        g_NativeControl = true;
    else if(numParams == 1)
        g_NativeControl = GetNativeCell(1);
}

public Native_GiveDeath(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        g_Remaining[client] = g_Limit[client] = (numParams >= 2) ? GetNativeCell(2) : GetConVarInt(g_FakeLimit);
        g_NativeDissolve[client] = (numParams >= 3) ? GetNativeCell(3) : GetConVarBool(g_Dissolve);
    }
}

public Native_TakeDeath(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        g_Remaining[client] = g_Limit[client] = 0;
    }
}

public Native_FakeDeath(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
	TF_SpawnFakeBody(client);
    }
}
