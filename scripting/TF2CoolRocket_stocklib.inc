/********************************여러 플러그인에서 공통적으로 쓰일 수 있는 유용한 함수**************************/
#if defined _javaliastocklib_included
#endinput
#endif
#define _javaliastocklib_included

//this define can used with valve games only. like tf2, hl2mp, css, dods ect
#define	TEAM_UNASSIGNED 0
#define	TEAM_SPECTATOR 1
#define	TEAM_RED 2
#define	TEAM_BLUE 3
#define	TEAM_TYPE_FIRST 0
#define	TEAM_TYPE_MAX 4 //how many teams are exist? in this case, 4 team is exist

// m_lifeState values
#define	LIFE_ALIVE				0 // alive
#define	LIFE_DYING				1 // playing death animation or still falling off of a ledge waiting to hit ground
#define	LIFE_DEAD				2 // dead. lying still.
#define	LIFE_RESPAWNABLE		3
#define	LIFE_DISCARDBODY		4

//env_beam 의 터치타입
enum Touch_t{

	touch_none = 0,
	touch_player_only,
	touch_npc_only,
	touch_player_or_npc,
	touch_player_npc_physicsprop,
	
};

//print to server in server`s language`s translation
//this function is designed to save your finger against code like this
//PrintToServer("%T%T%T", "smeffectitemshop:", LANG_SERVER, "attemp", LANG_SERVER, "main db connect", LANG_SERVER);
stock PrintToServerT(const String:format[], any:...){

	decl String:txt[1024];
	
	SetGlobalTransTarget(LANG_SERVER);
	VFormat(txt, sizeof(txt), format, 2);
	
	PrintToServer(txt);

}

stock LogErrorT(const String:format[], any:...){

	decl String:txt[1024];
	
	SetGlobalTransTarget(LANG_SERVER);
	VFormat(txt, sizeof(txt), format, 2);
	
	LogError(txt);

}

stock bool:isClientConnectedIngameAlive(client){
	
	if(isClientConnectedIngame(client)){
		
		if(IsPlayerAlive(client) == true && IsClientObserver(client) == false){
			
			return true;
			
		}else{
			
			return false;
			
		}
		
	}else{
		
		return false;
		
	}
	
}

//클라이언트 상태 체크 2개를 한꺼번에 해주는 함수
//클라이언트가 게임 안에 있는지까지 검사한다.
stock bool:isClientConnectedIngame(client){
	
	if(client > 0 && client <= MaxClients){
		
		if(IsClientInGame(client) == true){
			
			return true;
			
		}else{
			
			return false;
			
		}
		
	}else{
		
		return false;
		
	}
	
}

//클라이언트가 3인칭 시점으로 보게 해 주는 함수
stock bool:activeThirdPerson(client){
	
	if(isClientConnectedIngameAlive(client)){
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		
		return true;
		
	}else{
		
		return false;
		
	}
	
}

//클라이언트가 1인칭 시점으로 보게 해 주는 함수
stock bool:activeFirstPerson(client){
	
	if(isClientConnectedIngameAlive(client)){
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		
		return true;
		
	}else{
		
		return false;
		
	}
	
}

//damagetype
#define DMG_GENERIC								0					// generic damage was done
#define DMG_CRUSH									(1 << 0)	// crushed by falling or moving object. 
// NOTE: It's assumed crush damage is occurring as a result of physics collision, so no extra physics force is generated by crush damage.
// DON'T use DMG_CRUSH when damaging entities unless it's the result of a physics collision. You probably want DMG_CLUB instead.
#define DMG_BULLET								(1 << 1)	// shot
#define DMG_SLASH									(1 << 2)	// cut, clawed, stabbed
#define DMG_BURN									(1 << 3)	// heat burned
#define DMG_VEHICLE								(1 << 4)	// hit by a vehicle
#define DMG_FALL									(1 << 5)	// fell too far
#define DMG_BLAST									(1 << 6)	// explosive blast damage
#define DMG_CLUB									(1 << 7)	// crowbar, punch, headbutt
#define DMG_SHOCK									(1 << 8)	// electric shock
#define DMG_SONIC									(1 << 9)	// sound pulse shockwave
#define DMG_ENERGYBEAM						(1 << 10)	// laser or other high energy beam 
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)	// Prevent a physics force 
#define DMG_NEVERGIB							(1 << 12)	// with this bit OR'd in, no damage type will be able to gib victims upon death
#define DMG_ALWAYSGIB							(1 << 13)	// with this bit OR'd in, any damage type can be made to gib victims upon death.
#define DMG_DROWN									(1 << 14)	// Drowning
#define DMG_PARALYZE							(1 << 15)	// slows affected creature down
#define DMG_NERVEGAS							(1 << 16)	// nerve toxins, very bad
#define DMG_POISON								(1 << 17)	// blood poisoning - heals over time like drowning damage
#define DMG_RADIATION							(1 << 18)	// radiation exposure
#define DMG_DROWNRECOVER					(1 << 19)	// drowning recovery
#define DMG_ACID									(1 << 20)	// toxic chemicals or acid burns
#define DMG_SLOWBURN							(1 << 21)	// in an oven
#define DMG_REMOVENORAGDOLL				(1 << 22)	// with this bit OR'd in, no ragdoll will be created, and the target will be quietly removed.
// use this to kill an entity that you've already got a server-side ragdoll for
#define DMG_PHYSGUN								(1 << 23)	// Hit by manipulator. Usually doesn't do any damage.
#define DMG_PLASMA								(1 << 24)	// Shot by Cremator
#define DMG_AIRBOAT								(1 << 25)	// Hit by the airboat's gun
#define DMG_DISSOLVE							(1 << 26)	// Dissolving!
#define DMG_BLAST_SURFACE					(1 << 27)	// A blast on the surface of water that cannot harm things underwater
#define DMG_DIRECT								(1 << 28)
#define DMG_BUCKSHOT							(1 << 29)	// not quite a bullet. Little, rounder, different.

stock bool:makeDamage(attacker, target, damage, damagetype, Float:damageradius, const Float:attackposition[3], const String:weaponname[] = ""){

	new pointhurt = CreateEntityByName("point_hurt");
	
	if(pointhurt != -1){
		
		//목표가 있을 경우 목표 입력, 목표가 없을 경우 범위 공격을 하게된다
		if(target != -1){
			
			decl String:targetname[64];
			Format(targetname, 128, "%f%f", GetEngineTime(), GetRandomFloat());
			DispatchKeyValue(target,"TargetName", targetname);
			DispatchKeyValue(pointhurt,"DamageTarget", targetname);
			
		}
		
		//포인트허트 위치 지정
		DispatchKeyValueVector(pointhurt, "Origin", attackposition);
		
		//데미지 지정
		decl String:number[64];
		IntToString(damage, number, 64);
		DispatchKeyValue(pointhurt,"Damage", number);
		
		//데미지타입 지정
		IntToString(damagetype, number, 64);
		DispatchKeyValue(pointhurt,"DamageType", number);
		
		//데미지 범위 지정
		DispatchKeyValueFloat(pointhurt, "DamageRadius", damageradius);
		
		//웨폰네임 오버라이드
		if(!StrEqual(weaponname, "", false)){
			
			DispatchKeyValue(pointhurt,"classname", weaponname);
			
		}
		
		DispatchSpawn(pointhurt);
		
		AcceptEntityInput(pointhurt, "Hurt", attacker != -1 ? attacker : 0);
		
		AcceptEntityInput(pointhurt, "Kill");
		
		return true;
		
	}else{
		
		return false;
		
	}

}

/*
* set damageduration to smaller than 0.0 to make it do damage forever until this entity is killed by other reason
* set damageduration to 0.0 to make it damage once.
* set customdamage to true will make point_hurt entity to not do any damage, so u should work with it yourself.
* setting customdamage to true will ignore autoremove
* be sure to set autoremove to false if u dont want to remove point_hurt entity automatically
*
* damageduration 을 0 으로 설정하면 데미지를 한번만 준다. 0보다 크게 하면 주어진 시간동안 데미지를 준다.
* 0보다 작게 하면 포인트허트 엔티티가 사라지기 전까지 계속 데미지를 준다
* customdamage 를 true 로 설정하면 엔티티는 데미지를 주지 않는다. 직접 데미지를 주게 해야 한다.
* 그리고 customdamage가 true라면 autoremove  인수는 무시된다.
* 포인트허트 엔티티가 자동으로 사라지게 하고 싶지 않다면 autoremove 를 false로 설정하라
*/
stock makeDamage2(attacker, target, damage, damagetype, Float:damageradius, Float:damagedelay, Float:damageduration, const Float:attackposition[3], const String:weaponname[] = "", bool:customdamage = false, bool:autoremove = true){

	new pointhurt = CreateEntityByName("point_hurt");
	
	if(pointhurt != -1){
		
		//목표가 있을 경우 목표 입력, 목표가 없을 경우 범위 공격을 하게된다
		if(target != -1){
			
			decl String:targetname[64];
			Format(targetname, 128, "%f%f", GetEngineTime(), GetRandomFloat());
			DispatchKeyValue(target,"TargetName", targetname);
			DispatchKeyValue(pointhurt,"DamageTarget", targetname);
			
		}
		
		//포인트허트 위치 지정
		DispatchKeyValueVector(pointhurt, "Origin", attackposition);
		
		//데미지 지정
		decl String:number[64];
		IntToString(damage, number, 64);
		DispatchKeyValue(pointhurt,"Damage", number);
		//데미지타입 지정
		IntToString(damagetype, number, 64);
		DispatchKeyValue(pointhurt,"DamageType", number);
		//데미지 범위 지정
		DispatchKeyValueFloat(pointhurt, "DamageRadius", damageradius);
		DispatchKeyValueFloat(pointhurt, "DamageDelay", damagedelay);
		
		//웨폰네임 오버라이드
		if(!StrEqual(weaponname, "", false)){
			
			DispatchKeyValue(pointhurt,"classname", weaponname);
			
		}
		
		DispatchSpawn(pointhurt);
		
		if(!customdamage){
			
			if(damageduration == 0.0){
				
				AcceptEntityInput(pointhurt, "Hurt", attacker != -1 ? attacker : 0);
				
			}else{
				
				AcceptEntityInput(pointhurt, "TurnOn", attacker != -1 ? attacker : 0);
				
			}
			
		}
		
		if(autoremove){	
			
			if(!customdamage){
				
				if(damageduration == 0.0){
					
					AcceptEntityInput(pointhurt, "Kill");
					
				}else if(damageduration > 0.0){
					
					decl String:output[256];
					
					Format(output, 256, "OnUser1 !self:kill:justkill:%.1f:1", damageduration);
					
					SetVariantString(output);
					AcceptEntityInput(pointhurt, "AddOutput");
					AcceptEntityInput(pointhurt, "FireUser1");
					
				}
				
			}
			
		}else{
			
			if(!customdamage){
				
				if(damageduration > 0.0){
					
					decl String:output[256];
					
					Format(output, 256, "OnUser1 !self:TurnOff:justTurnOff:%.1f:1", damageduration);
					
					SetVariantString(output);
					AcceptEntityInput(pointhurt, "AddOutput");
					AcceptEntityInput(pointhurt, "FireUser1");
					
				}
				
			}
			
		}
		
		return pointhurt;
		
	}else{
		
		return -1;
		
	}

}

//env_explotion 엔티티의 스폰플래그
#define SF_ENVEXPLOSION_NODAMAGE	0x00000001 // when set, ENV_EXPLOSION will not actually inflict damage
#define SF_ENVEXPLOSION_REPEATABLE	0x00000002 // can this entity be refired?
#define SF_ENVEXPLOSION_NOFIREBALL	0x00000004 // don't draw the fireball
#define SF_ENVEXPLOSION_NOSMOKE		0x00000008 // don't draw the smoke
#define SF_ENVEXPLOSION_NODECAL		0x00000010 // don't make a scorch mark
#define SF_ENVEXPLOSION_NOSPARKS	0x00000020 // don't make sparks
#define SF_ENVEXPLOSION_NOSOUND		0x00000040 // don't play explosion sound.
#define SF_ENVEXPLOSION_RND_ORIENT	0x00000080	// randomly oriented sprites
#define SF_ENVEXPLOSION_NOFIREBALLSMOKE 0x0100
#define SF_ENVEXPLOSION_NOPARTICLES 0x00000200
#define SF_ENVEXPLOSION_NODLIGHTS	0x00000400
#define SF_ENVEXPLOSION_NOCLAMPMIN	0x00000800 // don't clamp the minimum size of the fireball sprite
#define SF_ENVEXPLOSION_NOCLAMPMAX	0x00001000 // don't clamp the maximum size of the fireball sprite
#define SF_ENVEXPLOSION_SURFACEONLY	0x00002000 // don't damage the player if he's underwater.
stock makeExplosion(attacker = 0, inflictor = -1, const Float:attackposition[3], const String:weaponname[] = "", magnitude = 100, radiusoverride = 0, Float:damageforce = 0.0, flags = 0){
	
	new explosion = CreateEntityByName("env_explosion");
	
	if(explosion != -1){
		
		DispatchKeyValueVector(explosion, "Origin", attackposition);
		
		decl String:intbuffer[64];
		IntToString(magnitude, intbuffer, 64);
		DispatchKeyValue(explosion,"iMagnitude", intbuffer);
		if(radiusoverride > 0){
			
			IntToString(radiusoverride, intbuffer, 64);
			DispatchKeyValue(explosion,"iRadiusOverride", intbuffer);
			
		}
		if(damageforce > 0.0){
			
			DispatchKeyValueFloat(explosion,"DamageForce", damageforce);
			
		}
		if(flags != 0){
			
			IntToString(flags, intbuffer, 64);
			DispatchKeyValue(explosion,"spawnflags", intbuffer);
			
		}
		//웨폰네임 오버라이드
		if(!StrEqual(weaponname, "", false)){
			
			DispatchKeyValue(explosion,"classname", weaponname);
			
			if(inflictor != -1){
				
				DispatchKeyValue(inflictor,"classname", weaponname);
				
			}
			
		}
		DispatchSpawn(explosion);
		
		if(attacker != -1){
			
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker);
			
		}
		if(inflictor != -1){
			
			SetEntPropEnt(explosion, Prop_Data, "m_hInflictor", inflictor);
			
		}
		
		AcceptEntityInput(explosion, "Explode");
		
		if(~flags & SF_ENVEXPLOSION_REPEATABLE){
			
			AcceptEntityInput(explosion, "Kill");
			
		}
		
		return explosion;
		
	}else{
		
		return -1;
		
	}
	
}

//페이드 유저메시지 함수의 상수
#define FFADE_IN 	0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT	0x0002        // Fade out (not in)
#define FFADE_MODULATE	0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT	0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE	0x0010        // Purges all other fades, replacing them with this one

stock sendFadeMsg(client, duration, holdtime, fadeflag, r, g, b, a){
	
	new Handle:fademsg;
	
	if (client == 0){
		
		fademsg = StartMessageAll("Fade");
		
	}else{
		
		fademsg = StartMessageOne("Fade", client);
		
	}
	
	BfWriteShort(fademsg, duration);
	BfWriteShort(fademsg, holdtime);
	BfWriteShort(fademsg, fadeflag);
	BfWriteByte(fademsg, r);
	BfWriteByte(fademsg, g);
	BfWriteByte(fademsg, b);
	BfWriteByte(fademsg, a);
	EndMessage();
	
}

//쉐이크 유저메시지 함수의 상수
enum ShakeCommand_t{
	
	SHAKE_START = 0,		// Starts the screen shake for all players within the radius.
	SHAKE_STOP,				// Stops the screen shake for all players within the radius.
	SHAKE_AMPLITUDE,		// Modifies the amplitude of an active screen shake for all players within the radius.
	SHAKE_FREQUENCY,		// Modifies the frequency of an active screen shake for all players within the radius.
	SHAKE_START_RUMBLEONLY,	// Starts a shake effect that only rumbles the controller, no screen effect.
	SHAKE_START_NORUMBLE,	// Starts a shake that does NOT rumble the controller.
	
};

stock sendShakeMsg(client, all:shakeflag, Float:amplitude, Float:frequency, Float:duration){

	new Handle:shakemsg;
	
	if (client == 0){
		
		shakemsg = StartMessageAll("Shake");
		
	}else{
		
		shakemsg = StartMessageOne("Shake", client);
		
	}

	BfWriteByte(shakemsg, shakeflag);
	BfWriteFloat(shakemsg, amplitude);
	BfWriteFloat(shakemsg, frequency);
	BfWriteFloat(shakemsg, duration);
	EndMessage();
	
}

//호출 예제 sendHudMsg(client, 6, 0.04, 0.82, 255, 120, 0, 255, 255, 120, 0, 225, 1, 0.1, 1000.0, 10.0, 4.0, totalhud);
stock sendHudMsg(client, channel, Float:x, Float:y, r1, g1, b1, a1, r2, g2, b2, a2, effect, Float:fadein, Float:fadeout, Float:holdtime, Float:fxtime, const String:msg[]){
	
	new Handle:hudhandle = INVALID_HANDLE;
	
	if (client == 0){
		
		hudhandle = StartMessageAll("HudMsg");
		
	}else{
		
		hudhandle = StartMessageOne("HudMsg", client);
		
	}
	
	if(hudhandle != INVALID_HANDLE){
		
		BfWriteByte(hudhandle, channel); //channel
		BfWriteFloat(hudhandle, x); // x ( -1 = center )
		BfWriteFloat(hudhandle, y); // y ( -1 = center )
		// second color
		BfWriteByte(hudhandle, r1); //r1
		BfWriteByte(hudhandle, g1); //g1
		BfWriteByte(hudhandle, b1); //b1
		BfWriteByte(hudhandle, a1); //a1 // transparent?
		// init color
		BfWriteByte(hudhandle, r2); //r2
		BfWriteByte(hudhandle, g2); //g2
		BfWriteByte(hudhandle, b2); //b2
		BfWriteByte(hudhandle, a2); //a2
		BfWriteByte(hudhandle, effect); //effect (0 is fade in/fade out; 1 is flickery credits; 2 is write out)
		BfWriteFloat(hudhandle, fadein); //fadeinTime (message fade in time - per character in effect 2)
		BfWriteFloat(hudhandle, fadeout); //fadeoutTime
		BfWriteFloat(hudhandle, holdtime); //holdtime
		BfWriteFloat(hudhandle, fxtime); //fxtime (effect type(2) used)
		BfWriteString(hudhandle, msg); //Message
		EndMessage();
		
	}
	
}

//this made effect on css, but no effect at hl2mp
stock sendKeyHintTextMsg(client, String:msg[], any:...){
	
	new Handle:hudhandle = INVALID_HANDLE;
	
	if (client == 0){
		
		hudhandle = StartMessageAll("KeyHintText");
		
	}else{
		
		hudhandle = StartMessageOne("KeyHintText", client);
		
	}
	
	new String:txt[255];
	VFormat(txt, sizeof(txt), msg, 3);	
	
	if (hudhandle != INVALID_HANDLE) { 
		
		BfWriteByte(hudhandle, 1);
		BfWriteString(hudhandle, txt);
		EndMessage(); 
		
	}
	
}

//it was same as PrintHintText, but it made differant effect at hl2mp, it can print short single line msg
stock sendHintTextMsg(client, String:msg[], any:...){
	
	new Handle:hudhandle = INVALID_HANDLE;
	
	if (client == 0){
		
		hudhandle = StartMessageAll("HintText");
		
	}else{
		
		hudhandle = StartMessageOne("HintText", client);
		
	}
	
	new String:txt[255];
	VFormat(txt, sizeof(txt), msg, 3);	
	
	if (hudhandle != INVALID_HANDLE) { 
		
		BfWriteByte(hudhandle, 1);
		BfWriteString(hudhandle, txt);
		EndMessage(); 
		
	}
	
}

//this has no effect
stock sendHudText(client, String:msg[], any:...){
	
	new Handle:hudhandle = INVALID_HANDLE;
	
	if (client == 0){
		
		hudhandle = StartMessageAll("HudText");
		
	}else{
		
		hudhandle = StartMessageOne("HudText", client);
		
	}
	
	new String:txt[255];
	VFormat(txt, sizeof(txt), msg, 3);	
	
	if (hudhandle != INVALID_HANDLE) { 
		
		BfWriteString(hudhandle, txt);
		EndMessage(); 
		
	}
	
}

//this is sam for some exist functions of sourcemod
#define HUD_PRINTNOTIFY	1
#define HUD_PRINTCONSOLE	2
#define HUD_PRINTTALK		3
#define HUD_PRINTCENTER	4
stock sendTextMsg(client, msgtype, const String:msgname[], const String:msg1[] = "", const String:msg2[] = "", const String:msg3[] = "", const String:msg4[] = ""){
	
	new Handle:hudhandle = INVALID_HANDLE;
	
	if (client == 0){
		
		hudhandle = StartMessageAll("TextMsg");
		
	}else{
		
		hudhandle = StartMessageOne("TextMsg", client);
		
	}
	
	if(hudhandle != INVALID_HANDLE){
		
		BfWriteByte(hudhandle, msgtype);
		BfWriteString(hudhandle, msgname); //Message
		BfWriteString(hudhandle, msg1); //Message
		BfWriteString(hudhandle, msg2); //Message
		BfWriteString(hudhandle, msg3); //Message
		BfWriteString(hudhandle, msg4); //Message
		EndMessage();
		
	}
	
}

/*휴드와 소스모드 함수 매칭
*DIALOG_ASKCONNECT = DisplayAskConnectBox
*다른 타입들 = CreateDialog(client, Handle:kv, DialogType:type);
*/
//not so useful
stock SendTopLeftText(client, r, g, b, a, level, time, const String:text[], any:...){
	
	new String:message[100];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), text, 9);	
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", r, g, b, a);
	KvSetNum(kv, "level", level);
	KvSetNum(kv, "time", time);
	
	if(client == 0){
		
		for(new i = 1; i <= MaxClients; i++){
			
			if(isClientConnectedIngame(i)){
				
				CreateDialog(i, kv, DialogType_Msg);
				
			}
			
		}
		
	}else if(isClientConnectedIngame(client)){
		
		CreateDialog(client, kv, DialogType_Msg);
		
	}
	
	CloseHandle(kv);
	
}

//세이텍스트올
stock SayText2ToAll(client, const String:message[], any:...){ 
	
	new Handle:buffer = INVALID_HANDLE;
	
	new String:txt[255];
	
	for(new i = 1; i <= MaxClients; i++){
		
		if(IsClientInGame(i)){
			
			SetGlobalTransTarget(i);
			VFormat(txt, sizeof(txt), message, 3);	
			
			buffer = StartMessageOne("SayText2", i);
			
			if (buffer != INVALID_HANDLE) { 
				
				BfWriteByte(buffer, client);
				BfWriteByte(buffer, true);
				BfWriteString(buffer, txt);
				EndMessage(); 
				buffer = INVALID_HANDLE;
				
			}
			
		}
		
	}

}

//세이텍스트투
stock SayText2To(client, target, const String:message[], any:...){ 
	
	new Handle:buffer = StartMessageOne("SayText2", target);
	
	new String:txt[255];
	SetGlobalTransTarget(target);
	VFormat(txt, sizeof(txt), message, 4);	
	
	if (buffer != INVALID_HANDLE) { 
		
		BfWriteByte(buffer, client);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, txt);
		EndMessage(); 
		
	}

}

//라운드 종료 함수의 처리
#define ROUNDEND_TARGET_BOMBED                          0        // Target Successfully Bombed!
#define ROUNDEND_VIP_ESCAPED                            1        // The VIP has escaped!
#define ROUNDEND_VIP_ASSASSINATED                       2        // VIP has been assassinated!
#define ROUNDEND_TERRORISTS_ESCAPED                     3        // The terrorists have escaped!
#define ROUNDEND_CTS_PREVENTESCAPE                      4        // The CT's have prevented most of the terrorists from escaping!
#define ROUNDEND_ESCAPING_TERRORISTS_NEUTRALIZED        5        // Escaping terrorists have all been neutralized!
#define ROUNDEND_BOMB_DEFUSED                           6        // The bomb has been defused!
#define ROUNDEND_CTS_WIN                                7        // Counter-Terrorists Win!
#define ROUNDEND_TERRORISTS_WIN                         8        // Terrorists Win!
#define ROUNDEND_ROUND_DRAW                             9       // Round Draw!
#define ROUNDEND_ALL_HOSTAGES_RESCUED                   10       // All Hostages have been rescued!
#define ROUNDEND_TARGET_SAVED                           11       // Target has been saved!
#define ROUNDEND_HOSTAGES_NOT_RESCUED                   12       // Hostages have not been rescued!
#define ROUNDEND_TERRORISTS_NOT_ESCAPED                 13       // Terrorists have not escaped!
#define ROUNDEND_VIP_NOT_ESCAPED                        14       // VIP has not escaped!
#define ROUNDEND_GAME_COMMENCING                        15       // Game Commencing!
stock bool:EndRound(Float:time = 5.0, reason = ROUNDEND_ROUND_DRAW){
	
	//정적 변수!!!!
	static Handle:conffile = INVALID_HANDLE;
	static Handle:virtualroundend = INVALID_HANDLE;
	static bool:sdkcalltried = false;
	
	if(!sdkcalltried){
		
		conffile = LoadGameConfigFile("stocklib.games");
		
		if(conffile != INVALID_HANDLE){
			
			StartPrepSDKCall(SDKCall_GameRules);
			PrepSDKCall_SetFromConf(conffile, SDKConf_Signature, "RoundEnd");
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			virtualroundend = EndPrepSDKCall();
			
			//goodbye, configfile
			CloseHandle(conffile);
			
		}
		
		sdkcalltried = true;
		
	}
	
	if(virtualroundend != INVALID_HANDLE){
		
		SDKCall(virtualroundend, time, reason);
		return true;
		
	}else{
		
		PrintToServer("[StockLib] plugin has called endround function but failed. maybe game is not css or conf file is missing");
		return false;
		
	}
	
}

stock SetClientButtons(client, buttons){
	
	return SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	
}

//살아있는 클라이언트의 에임방향으로부터 일정 거리 떨어진 곳을 구해서 돌려준다
stock bool:getClientAimPosition(client, Float:maxtracedistance, Float:resultvecpos[3], Float:resultvecnormal[3], TraceEntityFilter:function, filter){
	
	decl Float:cleyepos[3], Float:cleyeangle[3], Float:eyeanglevector[3];
	GetClientEyePosition(client, cleyepos); 
	GetClientEyeAngles(client, cleyeangle);
	
	new Handle:traceresulthandle = INVALID_HANDLE;
	
	traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, function, filter);
	
	if(TR_DidHit(traceresulthandle) == true){
		
		decl Float:endpos[3];
		TR_GetEndPosition(endpos, traceresulthandle);
		TR_GetPlaneNormal(traceresulthandle, resultvecnormal);
		
		//거리가 일정 이하일 경우
		if((GetVectorDistance(cleyepos, endpos) <= maxtracedistance) || maxtracedistance <= 0){
			
			resultvecpos[0] = endpos[0];
			resultvecpos[1] = endpos[1];
			resultvecpos[2] = endpos[2];
			
			CloseHandle(traceresulthandle);
			return true;
			
		}else{
			
			GetAngleVectors(cleyeangle, eyeanglevector, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(eyeanglevector, eyeanglevector);
			ScaleVector(eyeanglevector, maxtracedistance);
			
			AddVectors(cleyepos, eyeanglevector, resultvecpos);
			
			CloseHandle(traceresulthandle);
			return true;
			
		}
		
	}
	
	CloseHandle(traceresulthandle);
	return false;
	
}

stock GetClientAimEntity(client, &Float:distancetoentity){

	decl Float:cleyepos[3], Float:cleyeangle[3];
	GetClientEyePosition(client, cleyepos); 
	GetClientEyeAngles(client, cleyeangle);
	
	new Handle:traceresulthandle = INVALID_HANDLE;
	
	traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
	
	if(TR_DidHit(traceresulthandle) == true){
		
		decl Float:endpos[3];
		TR_GetEndPosition(endpos, traceresulthandle);
		
		distancetoentity = GetVectorDistance(cleyepos, endpos);
		new entindextoreturn = TR_GetEntityIndex(traceresulthandle); 
		
		CloseHandle(traceresulthandle);
		
		return entindextoreturn;
		
	}
	
	CloseHandle(traceresulthandle);
	
	return -1;

}

stock GetClientAimEntity2(client){

	decl Float:temp;
	
	return GetClientAimEntity(client, temp);

}

stock GetClientAimEntity3(client, &Float:distancetoentity, Float:endpos[3]){

	decl Float:cleyepos[3], Float:cleyeangle[3];
	GetClientEyePosition(client, cleyepos); 
	GetClientEyeAngles(client, cleyeangle);
	
	new Handle:traceresulthandle = INVALID_HANDLE;
	
	traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
	
	if(TR_DidHit(traceresulthandle) == true){
		
		TR_GetEndPosition(endpos, traceresulthandle);
		
		//거리가 일정 이하일 경우
		distancetoentity = GetVectorDistance(cleyepos, endpos);
		new entindextoreturn = TR_GetEntityIndex(traceresulthandle); 
		
		CloseHandle(traceresulthandle);
		
		return entindextoreturn;
		
	}
	
	CloseHandle(traceresulthandle);
	
	return -1;

}

// settings for m_takedamage
#define	DAMAGE_NO				0
#define	DAMAGE_EVENTS_ONLY		1		// Call damage functions, but don't modify health
#define	DAMAGE_YES				2
#define	DAMAGE_AIM				3
stock setTakeDamage(entity, type){
	
	SetEntProp(entity, Prop_Data, "m_takedamage", type);
	
}

//트레이스레이필터
public bool:tracerayfilterdefault(entity, mask, any:data){
	
	if(entity != data){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

public bool:tracerayfilteronlyone(entity, mask, any:data){
	
	if(entity == data && mask & CONTENTS_HITBOX){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

//트레이스레이필터로켓
public bool:tracerayfilterrocket(entity, mask, any:data){
	
	//로켓을 쏜 사람이 아니고, 그 사람의 물건도 아닐때만 필터에 감지한다
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");//닿은 물건의 주인을 구한다
	if(entity != data && owner != data){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

//트레이스레이필터, 플레이어는 감지하지 않는다
public bool:tracerayfilternoplayer(entity, mask, any:data){
	
	if(!isClientConnectedIngameAlive(entity)){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

//0번 엔티티만 감지한다
public bool:tracerayfilteronlyworld(entity, mask, any:data){
	
	if(entity == 0){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

stock bool:IsStrBool(const String:str[], bool:onlynumeric = true){
	
	if(onlynumeric){
		
		return StrEqual(str, "1", false) || StrEqual(str, "0", false);
		
	}else{
		
		return StrEqual(str, "1", false) || StrEqual(str, "0", false) || StrEqual(str, "true", false) || StrEqual(str, "false", false);
		
	}
	
}

//엔티티가 충돌 가능한 물체인지를 검사한다!
stock bool:IsEntityCollidable(entity, bool:includeplayer = true, bool:includehostage = true, bool:includeprojectile = true){
	
	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	
	if((StrEqual(classname, "player", false) && includeplayer) || (StrEqual(classname, "hostage_entity", false) && includehostage)
			||StrContains(classname, "physics", false) != -1 || StrContains(classname, "prop", false) != -1
			|| StrContains(classname, "door", false)  != -1 || StrContains(classname, "weapon", false)  != -1
			|| StrContains(classname, "break", false)  != -1 || ((StrContains(classname, "projectile", false)  != -1) && includeprojectile)
			|| StrContains(classname, "brush", false)  != -1 || StrContains(classname, "button", false)  != -1
			|| StrContains(classname, "physbox", false)  != -1 || StrContains(classname, "plat", false)  != -1
			|| StrEqual(classname, "func_conveyor", false) || StrEqual(classname, "func_fish_pool", false)
			|| StrEqual(classname, "func_guntarget", false) || StrEqual(classname, "func_lod", false)
			|| StrEqual(classname, "func_monitor", false) || StrEqual(classname, "func_movelinear", false)
			|| StrEqual(classname, "func_reflective_glass", false) || StrEqual(classname, "func_rotating", false)
			|| StrEqual(classname, "func_tanktrain", false) || StrEqual(classname, "func_trackautochange", false)
			|| StrEqual(classname, "func_trackchange", false) || StrEqual(classname, "func_tracktrain", false)
			|| StrEqual(classname, "func_train", false) || StrEqual(classname, "func_traincontrols", false)
			|| StrEqual(classname, "func_vehicleclip", false) || StrEqual(classname, "func_traincontrols", false)
			|| StrEqual(classname, "func_water", false) || StrEqual(classname, "func_water_analog", false)){
		
		return true;
		
	}
	
	return false;
	
}

stock makeviewpunch(client, Float:angle[3]){
	
	decl Float:oldangle[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	
	oldangle[0] = oldangle[0] + angle[0];
	oldangle[1] = oldangle[1] + angle[1];
	oldangle[2] = oldangle[2] + angle[2];
	
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", angle);
	
}

stock resetviewpunch(client){
	
	new Float:angle[3] = {0.0, 0.0, 0.0};
	
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", angle);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", angle);
	
}

stock bool:sendRawAudioTo(client, target, const String:sSound[255], iVoicePitch = 100, Float:fVoiceMarkShowTime = 1.0){
	
	if(!isClientConnectedIngame(client)){
		
		return false;
		
	}
	
	//Peace-Maker has found how to use this usermsg, well, i helped him lol
	
	new Handle:buffer = StartMessageOne("RawAudio", target);
	
	if (buffer != INVALID_HANDLE){ 
		
		BfWriteByte(buffer, iVoicePitch);
		BfWriteByte(buffer, client);
		BfWriteFloat(buffer, fVoiceMarkShowTime);
		BfWriteString(buffer, sSound);
		EndMessage(); 
		
		return true;
		
	}
	
	return false;
	
}

stock bool:sendRawAudioToTeam(client, team, const String:sSound[255], iVoicePitch = 100, Float:fVoiceMarkShowTime = 1.0){
	
	if(!isClientConnectedIngame(client)){
		
		return false;
		
	}
	
	for(new i = 1; i <= MaxClients; i++){
		
		if(IsClientInGame(i) && GetClientTeam(i) == team){
			
			new Handle:buffer = StartMessageOne("RawAudio", i);
			
			if (buffer != INVALID_HANDLE) { 
				
				BfWriteByte(buffer, iVoicePitch);
				BfWriteByte(buffer, client);
				BfWriteFloat(buffer, fVoiceMarkShowTime);
				BfWriteString(buffer, sSound);
				EndMessage(); 
				
			}
			
		}
		
	}
	
	return true;

}

stock bool:sendRawAudioToTeamAndSpectator(client, team, const String:sSound[255], iVoicePitch = 100, Float:fVoiceMarkShowTime = 1.0){
	
	if(!isClientConnectedIngame(client)){
		
		return false;
		
	}
	
	for(new i = 1; i <= MaxClients; i++){
		
		if(IsClientInGame(i)){
			
			new targetTeam = GetClientTeam(i);
			
			if(targetTeam == team || targetTeam == TEAM_SPECTATOR){
				
				new Handle:buffer = StartMessageOne("RawAudio", i);
				
				if (buffer != INVALID_HANDLE) { 
					
					BfWriteByte(buffer, iVoicePitch);
					BfWriteByte(buffer, client);
					BfWriteFloat(buffer, fVoiceMarkShowTime);
					BfWriteString(buffer, sSound);
					EndMessage(); 
					
				}
				
			}
			
		}
		
	}
	
	return true;

}

stock bool:sendRawAudioToAll(client, const String:sSound[255], iVoicePitch = 100, Float:fVoiceMarkShowTime = 1.0){
	
	if(!isClientConnectedIngame(client)){
		
		return false;
		
	}
	
	new Handle:buffer = StartMessageAll("RawAudio");
	
	if (buffer != INVALID_HANDLE) { 
		
		BfWriteByte(buffer, iVoicePitch);
		BfWriteByte(buffer, client);
		BfWriteFloat(buffer, fVoiceMarkShowTime);
		BfWriteString(buffer, sSound);
		EndMessage(); 
		
		return true;
		
	}
	
	return false;

}

//i dunno, what the hell is this magic number mean, i DUNNO!
#define RADIOTEXT_MAGIC_NUMBER 3

stock bool:sendRadioTextTo(client, target, const String:sText[255], any:...){
	
	if(!isClientConnectedIngame(client)){
		
		return false;
		
	}
	
	new Handle:buffer = StartMessageOne("RadioText", target);
	
	if (buffer != INVALID_HANDLE) { 
		
		decl String:sClientName[255];
		decl String:sPlaceName[255];
		decl String:msg[255];
		GetClientName(client, sClientName, 255);
		GetEntPropString(client, Prop_Data, "m_szLastPlaceName", sPlaceName, 255);
		
		SetGlobalTransTarget(target);
		VFormat(msg, 255, sText, 4);	
		
		if(StrEqual(sPlaceName, "", false)){
			
			BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
			BfWriteByte(buffer, client);
			BfWriteString(buffer, "#Game_radio");
			BfWriteString(buffer, sClientName);
			BfWriteString(buffer, msg);
			
		}else{
			
			BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
			BfWriteByte(buffer, client);
			BfWriteString(buffer, "#Game_radio_location");
			BfWriteString(buffer, sClientName);
			BfWriteString(buffer, sPlaceName);
			BfWriteString(buffer, msg);
			
		}
		
		EndMessage(); 
		
		return true;
		
	}
	
	return false;

}

stock bool:sendRadioTextToAll(client, const String:sText[255], any:...){
	
	if(!isClientConnectedIngame(client)){
		
		return false;
		
	}
	
	for(new i = 1; i <= MaxClients; i++){
		
		if(IsClientInGame(i)){
			
			new Handle:buffer = StartMessageOne("RadioText", i);
			
			if (buffer != INVALID_HANDLE){ 
				
				decl String:sClientName[255];
				decl String:sPlaceName[255];
				decl String:msg[255];
				GetClientName(client, sClientName, 255);
				GetEntPropString(client, Prop_Data, "m_szLastPlaceName", sPlaceName, 255);
				
				SetGlobalTransTarget(i);
				VFormat(msg, 255, sText, 3);	
				
				if(StrEqual(sPlaceName, "", false)){
					
					BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
					BfWriteByte(buffer, client);
					BfWriteString(buffer, "#Game_radio");
					BfWriteString(buffer, sClientName);
					BfWriteString(buffer, msg);
					
				}else{
					
					BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
					BfWriteByte(buffer, client);
					BfWriteString(buffer, "#Game_radio_location");
					BfWriteString(buffer, sClientName);
					BfWriteString(buffer, sPlaceName);
					BfWriteString(buffer, msg);
					
				}
				
				EndMessage(); 
				
			}
			
		}
		
	}
	
	return true;

}

stock bool:sendRadioTextToTeam(client, team, const String:sText[], any:...){
	
	if(!isClientConnectedIngame(client)){
		
		return false;
		
	}
	
	decl String:sClientName[255];
	decl String:sPlaceName[255];
	decl String:msg[255];
	GetClientName(client, sClientName, 255);
	GetEntPropString(client, Prop_Data, "m_szLastPlaceName", sPlaceName, 255);
	
	for(new i = 1; i <= MaxClients; i++){
		
		if(IsClientInGame(i) && GetClientTeam(i) == team){
			
			SetGlobalTransTarget(i);
			VFormat(msg, 255, sText, 3);	
			
			new Handle:buffer = StartMessageOne("RadioText", i);
			
			if (buffer != INVALID_HANDLE){ 
				
				if(StrEqual(sPlaceName, "", false)){
					
					BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
					BfWriteByte(buffer, client);
					BfWriteString(buffer, "#Game_radio");
					BfWriteString(buffer, sClientName);
					BfWriteString(buffer, msg);
					
				}else{
					
					BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
					BfWriteByte(buffer, client);
					BfWriteString(buffer, "#Game_radio_location");
					BfWriteString(buffer, sClientName);
					BfWriteString(buffer, sPlaceName);
					BfWriteString(buffer, msg);
					
				}
				
				EndMessage(); 
				
			}
			
		}
		
	}
	
	return true;

}

stock getAliveClientOnTeam(iTeam){
	
	new iCount = 0;
	
	for(new i = 1; i <= MaxClients; i++){
		
		if(isClientConnectedIngameAlive(i) && GetClientTeam(i) == iTeam){
			
			iCount++;
			
		}
		
	}
	
	return iCount;

}

stock stripClientAllWeapon(client, const String:sServerClassName[]){

	new Weapon_Offset = FindSendPropOffs(sServerClassName, "m_hMyWeapons");
	new Max_Guns = 48;

	for(new n = 0; n < Max_Guns; n++){

		new iWeaponEntity = GetEntDataEnt2(client, Weapon_Offset + n * 4);
		
		if(iWeaponEntity > 0){

			RemovePlayerItem(client, iWeaponEntity);
			AcceptEntityInput(iWeaponEntity, "kill");

		}

	}

}

stock initVector(Float:vec[3]){

	vec[0] = 0.0;
	vec[1] = 0.0;
	vec[2] = 0.0;

}

stock bool:isStringBool(const String:text[], &resultbuffer){

	return isStringIntRange(text, 0, 1, resultbuffer);

}

stock bool:isStringColor(const String:text[], &resultbuffer){

	return isStringIntRange(text, 0, 255, resultbuffer);

}

stock bool:isStringInt(const String:text[], &resultbuffer){

	new intbuffer = StringToInt(text);
	
	if(intbuffer != 0 || StrEqual(text, "0", false) || StrEqual(text, "+0", false) || StrEqual(text, "-0", false)){
		
		//일단 숫자다
		resultbuffer = intbuffer;
		return true;
		
	}
	
	return false;

}

stock bool:isStringIntRange(const String:text[], min, max, &resultbuffer){
	
	if(isStringInt(text, resultbuffer)){
		
		return (resultbuffer >= min && resultbuffer <= max);
		
	}
	
	return false;

}

stock bool:StripQuotesOnce(String:targetstring[], maxlength){

	if(targetstring[0] == '"' && targetstring[strlen(targetstring) - 1] == '"'){
		
		ReplaceStringEx(targetstring, maxlength, "\"", "");
		targetstring[strlen(targetstring) - 1] = '\0';
		return true;
	}
	
	return false;

}

//this function will change any dublicated value on array to alternateValue.
stock removeDublicatedArrayElement(any:array[], arraysize, any:alternateValue){
	
	for(new i = 0; i < arraysize - 1; i++){
		
		if(array[i] != alternateValue){
			
			for(new searchtarget = i + 1; searchtarget < arraysize; searchtarget++){
				
				if(array[i] == array[searchtarget]){
					
					array[searchtarget] = alternateValue;
					
				}
				
			}
			
		}
		
	}

}

//u should call TE send function via yourself. not working
stock bool:setupEffectDispatch(const Float:Origin[3], const Float:Start[3], const Float:Angles[3], const Float:Normal[3], flags, const Float:magnitude, const Float:scale, attachmentindex, surfaceprop, const String:EffectName[], iMaterial, iDamageType, iHitbox, iEntIndex, iColor, Float:radius){

	static bool:checkedstringtableid = false;
	static stringtableid = INVALID_STRING_TABLE;
	
	if(!checkedstringtableid){
		
		checkedstringtableid = true;
		stringtableid = FindStringTable("EffectDispatch");
		PrintToServer("%d", stringtableid);
		
	}
	
	if(stringtableid != INVALID_STRING_TABLE){
		
		TE_Start("EffectDispatch");
		TE_WriteVector("m_vOrigin[0]", Origin);
		TE_WriteVector("m_vStart[0]", Start);
		TE_WriteVector("m_vAngles", Angles);
		TE_WriteVector("m_vNormal", Normal);
		TE_WriteNum("m_fFlags", flags);
		TE_WriteFloat("m_flMagnitude", magnitude);
		TE_WriteFloat("m_flScale", scale);
		TE_WriteNum("m_nAttachmentIndex", attachmentindex);
		TE_WriteNum("m_nSurfaceProp", surfaceprop);
		AddToStringTable(stringtableid, EffectName)
		TE_WriteNum("m_iEffectName", FindStringIndex(stringtableid, EffectName));
		PrintToServer("%d", FindStringIndex(stringtableid, EffectName));
		TE_WriteNum("m_nMaterial", iMaterial);
		TE_WriteNum("m_nDamageType", iDamageType);
		TE_WriteNum("m_nHitBox", iHitbox);
		TE_WriteNum("entindex", iEntIndex);
		TE_WriteNum("m_nColor", iColor);
		TE_WriteFloat("m_flRadius", radius);
		return true;
		
	}
	
	return false;

}

//water effect! notworking
stock bool:setupWaterSplashEffect(const Float:origin[3], bool:WaterInSlime, Float:scale, const Float:normal[3] = {0.0, 0.0, 1.0}){

	return setupEffectDispatch(origin, NULL_VECTOR, NULL_VECTOR, normal, WaterInSlime, 0.0, scale, 0, 0, "watersplash", 0, 0, 0, INVALID_ENT_REFERENCE, -1, 0.0);

}