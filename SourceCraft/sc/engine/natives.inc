/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: natives.inc
 * Description: All the natives that keep us from having to make a C++ extension,
 *              I <3 SourceMod :) (Note: Forwards are handled here too.)
 * Author(s): Anthony Iacono  
 * Rewritten by: -=|JFH|=-Naris (Murray Wilson)
 */

// Handles
new Handle:g_OnPluginReadyHandle = INVALID_HANDLE;
new Handle:g_OnPlayerAuthedHandle = INVALID_HANDLE;
new Handle:g_OnUltimateCommandHandle = INVALID_HANDLE;
new Handle:g_OnCreditsGivenHandle = INVALID_HANDLE;
new Handle:g_OnXPGivenHandle = INVALID_HANDLE;
new Handle:g_OnPlayerHurtEventHandle = INVALID_HANDLE;
new Handle:g_OnPlayerDeathEventHandle = INVALID_HANDLE;
new Handle:g_OnObjectKilledHandle = INVALID_HANDLE;

new g_KilledBy[MAXPLAYERS+1] = { 0, ...};

/**
 * Registers a race with the SourceCraft plugin
 * @param name: The name of the race. (max 64)
 * @param short: The short name of the race. (max 16) 
 * @param switchmessage_instant: The message displayed to the player when they are switched to a new race. (max 192)
 * @param switchmessage_dead: The message displayed to the play when they try to switch to the race, but they are alive so they need to wait until they die or the new round. (max 192)
 * @param required_level: The overeall level the player must obtain before changing to this race.
 * @param max_level: The maximum level the race can attain. (default is 16)
 * @return The return value will be the race index or -1 if there was a problem.
 *
 * native CreateRace(const String:name[],const String:short[],const String:switchmessage_instant[],
 *                   const String:switchmessage_dead[],required_level=0,max_level=16);
 */         
public Native_CreateRace(Handle:plugin,numParams)
{
    if (numParams >=4 && numParams <= 6)
    {
        decl String:name[64],String:short[16];
        decl String:switchmessage_instant[192];
        decl String:switchmessage_dead[192];
        GetNativeString(1,name,sizeof(name));
        GetNativeString(2,short,sizeof(short));
        GetNativeString(3,switchmessage_instant,sizeof(switchmessage_instant));
        GetNativeString(4,switchmessage_dead,sizeof(switchmessage_dead));

        new required_level  = (numParams >= 5) ? GetNativeCell(5) : 0;
        new max_level       = (numParams >= 6) ? GetNativeCell(6) : MAX_LEVELS;

        return CreateRace(name,short,switchmessage_instant,switchmessage_dead,
                          required_level,max_level);
    }
    return -1;
}

/**
 * Adds an upgrade to a race
 * @param race: The race ID returned from CreateRace
 * @param name: The name of the upgrade. (max 64)
 * @param short: The short name of the upgrade. (max 16) 
 * @param desc: The description of the upgrade. (max 192)
 * @param ultimate: Set to true to indicate upgrade is an ultimate. (default is false)
 * @param required_level: The race level required before this upgrade becomes available.
 *                        (default is the minumum ultimate level {usually 8} and 0 for all others)
 * @param max_level: The maximum level the upgrade can attain. (default is 4)
 * @return The return value will be the upgrade index or -1 if there was a problem.
 * native AddUpgrade(race,const String:name[],const String:short[],const String:desc[],
                     bool:ultimate=false,required_level=-1,max_level=4);
 */         
public Native_AddUpgrade(Handle:plugin,numParams)
{
    if (numParams >=4 && numParams <= 7)
    {
        new Handle:raceHandle = GetRaceHandle(GetNativeCell(1));
        if (raceHandle != INVALID_HANDLE)
        {
            decl String:name[64],String:short[16],String:desc[192];
            GetNativeString(2,name,sizeof(name));
            GetNativeString(3,short,sizeof(short));
            GetNativeString(4,desc,sizeof(desc));
            new bool:ultimate   = bool:(numParams >= 5) ? GetNativeCell(5) : false;
            new required_level  = (numParams >= 6) ? GetNativeCell(6) : -1;
            new max_level       = (numParams >= 7) ? GetNativeCell(7) : 4;
            return AddUpgrade(raceHandle, name, short, desc,
                              ultimate, required_level, max_level);
        }
    }
    return -1;
}

/**
 * Registers a shop item with the SourceCraft plugin
 * @param name: The name of the item. (max 64)
 * @param short: The short name of the item. (max 16) 
 * @param desc: The description of the item. (max 192) 
 * @param cost: The cost of the item.
 * @param max: The maximum number of this item that the player can own.
 * @param required_level: The overall level the player must obtain before buying this item.
 * @return The return value will be the item index or -1 if there was a problem.
 *
 * native CreateShopItem(String:name[],String:short[],String:desc[],cost,max=1,required_level=0);
 */         
public Native_CreateShopItem(Handle:plugin,numParams)
{
    if (numParams >= 4 && numParams <= 6)
    {
        decl String:name[64],String:short[16],String:desc[192];
        GetNativeString(1,name,sizeof(name));
        GetNativeString(2,short,sizeof(short));
        GetNativeString(3,desc,sizeof(desc));
        new cost = GetNativeCell(4);
        new max = (numParams >= 5) ? GetNativeCell(5) : 0;
        new required_level = (numParams >= 6) ? GetNativeCell(6) : 0;
        return CreateShopItem(name,short,desc,cost,max,required_level);
    }
    else
        return -1;
}

/**
 * Registers a help command with the SourceCraft plugin for help
 * @param name: The name of the command. (max 64)
 * @param desc: The description of the command. (max 256) 
 * @return The return value will be the help index or -1 if there was a problem.
 *
 * native CreateHelpCommand(const String:name[],const String:desc[]);
 */
public Native_CreateHelpCommand(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        decl String:name[64],String:desc[256];
        GetNativeString(1,name,sizeof(name));
        GetNativeString(2,desc,sizeof(desc));
        return NewHelpCommand(name,desc);
    }
    else
        return -1;
}

/**
 * Find the ShopItem ID of a shop item
 * @param name: The name of the item. (max 64)
 * @return The return value will be the item index or -1 if there was a problem.
 *
 * native FindShopItem(const String:name[]);
 */         
public Native_FindShopItem(Handle:plugin,numParams)
{
    if(numParams==1)
    {
        decl String:name[16];
        GetNativeString(1,name,sizeof(name));
        return FindShopItem(name);
    }
    else
        return -1;
}

/**
 * Find the Race ID of a race
 * @param name: The name of the race. (max 64)
 * @return The return value will be the race index or -1 if there was a problem.
 *
 * native FindRace(const String:name[]);
 */         
public Native_FindRace(Handle:plugin,numParams)
{
    if(numParams==1)
    {
        decl String:name[16];
        GetNativeString(1,name,sizeof(name));
        return FindRace(name);
    }
    else
        return -1;
}

/**
 * Give health to (heal) a player
 * @param client: The client's index you want.
 * @param amount: The amount of health to give to the client.
 * @param health: The health of the client.
 * @param max:    The max health of the client.
 * @noreturn
 *
 * native HealPlayer(client, amount,health=0,max=0);
 */
public Native_HealPlayer(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 4)
    {
        new client = GetNativeCell(1);
        new amount = GetNativeCell(2);
        new health = (numParams >= 3) ? GetNativeCell(3) : GetClientHealth(client);
        new max    = (numParams >= 4) ? GetNativeCell(4) : GetMaxHealth(client);
        health    += amount;
        if (health > max)
            health = max;
        SetEntityHealth(client,health);
        SaveHealth(client);
        return health;
    }
    else
        return -1;
}

/**
 * Take health from (damage) a player
 * @param victim: The victim's index you want.
 * @param damage: The amount to damage to deal to the client.
 * @param attacker: The index of the attacker.
 * @param weapon_name: The name of the weapon used to deal the damage to the client.
 * @param weapon_desc: The description of the weapon used to deal the damage to the client.
 * @param xp: Amount of extra xp for a kill.
 * @noreturn
 * native HurtPlayer(victim, damage, attacker=0, const String:weapon_name[]="",
 *                   const String:weapon_desc[]="", xp=0);
 */
public Native_HurtPlayer(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 6)
    {
        new victim = GetNativeCell(1);
        if (victim)
        {
            new damage = GetNativeCell(2);
            new attacker = 0;
            new xp = 0;
            decl String:weapon_name[64];
            decl String:weapon_desc[64];
            if (numParams >= 3)
            {
                attacker = GetNativeCell(3);
                if (numParams >= 4)
                {
                    GetNativeString(4,weapon_name,sizeof(weapon_name));
                    if (numParams >= 5)
                    {
                        GetNativeString(5,weapon_desc,sizeof(weapon_desc));
                        if (numParams >= 6)
                            xp = GetNativeCell(6);
                        else
                            weapon_desc[0] = 0;
                    }
                    else
                    {
                        weapon_name[0] = 0;
                        weapon_desc[0] = 0;
                    }
                }
                else
                {
                    weapon_name[0] = 0;
                    weapon_desc[0] = 0;
                }
            }

            new health = GetClientHealth(victim) - damage;
            if (health > 0)
            {
                SetEntityHealth(victim,health);
                new Handle:event = CreateEvent("player_hurt");
                if (event != INVALID_HANDLE)
                {
                    DisplayDamage(attacker, victim, weapon_name, weapon_desc, damage);

                    SetEventInt(event, "userid", GetClientUserId(victim));
                    SetEventInt(event, "attacker", (attacker) ? GetClientUserId(attacker) : 0);
                    SetEventInt(event, "health", health);
                    SetEventInt(event, "damage", damage);
                    SetEventString(event, "weapon", weapon_name);
                    SetEventBool(event, "from_sourcecraft", true);
                    FireEvent(event);
                }
            }
            else
                KillPlayer(victim, attacker, weapon_name, weapon_desc, xp);

            SaveHealth(victim);
            return health;
        }
    }
    return -1;
}

/**
 * Kill a player.
 * @param victim: The victim's index.
 * @param attacker: The index of the attacker.
 * @param weapon_name: The name of the weapon used to deal the damage to the client.
 * @param weapon_desc: The description of the weapon used to deal the damage to the client.
 * @param xp: Amount of extra xp for a kill.
 * @noreturn
 * native KillPlayer(victim, attacker=0, const String:weapon_name[]="",
 *                   const String:weapon_desc[]="", xp=0);
 */
public Native_KillPlayer(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 5)
    {
        new victim = GetNativeCell(1);
        if (victim)
        {
            new attacker = 0;
            new xp = 0;
            decl String:weapon_name[64];
            decl String:weapon_desc[64];
            if (numParams >= 2)
            {
                attacker = GetNativeCell(2);
                if (numParams >= 3)
                {
                    GetNativeString(3,weapon_name,sizeof(weapon_name));
                    if (numParams >= 4)
                    {
                        GetNativeString(4,weapon_desc,sizeof(weapon_desc));
                        if (numParams >= 5)
                            xp = GetNativeCell(5);
                    }
                    else
                        weapon_desc[0] = 0;
                }
                else
                {
                    weapon_name[0] = 0;
                    weapon_desc[0] = 0;
                }
            }
            else
            {
                weapon_name[0] = 0;
                weapon_desc[0] = 0;
            }

            KillPlayer(victim, attacker, weapon_name, weapon_desc, xp);
            SaveHealth(victim);
            return 0;
        }
    }
    return -1;
} 

KillPlayer(victim, attacker, const String:weapon_name[], const String:weapon_desc[], xp)
{
    if (victim)
    {
        g_KilledBy[victim] = attacker;
        ForcePlayerSuicide(victim);
        if (xp && attacker && victim != attacker)
        {
            if (GetClientTeam(attacker) == GetClientTeam(victim))
                xp = 0; // No points for Team kills!
            else
            {
                new Handle:attacker_player = GetPlayerHandle(attacker);
                new race=GetRace(attacker_player);
                new newxp=GetXP(attacker_player,race)+xp;
                SetXP(attacker_player,race,newxp);
            }
        }
        DisplayKill(attacker, victim, weapon_name, weapon_desc, xp);
    }
}

/**
 * Displays damage inflicted upon a player
 * @param client: The index of the player that inflicted the damage (attacker)
 * @param victim: The index of the player that got damaged
 * @param weapon: The short name of the weapon used to inflice the damage (for the log)
 * @param description: The description of the weapon (displayed to the players)
 * @param hp: The amount of damage dealt
 * @noreturn
 * native DisplayDamage(client, victim, const String:weapon[], const String:description[], hp);
 */
public Native_DisplayDamage(Handle:plugin,numParams)
{
    if (numParams == 5)
    {
        decl String:weapon[64],String:desc[192];
        new client = GetNativeCell(1);
        new victim = GetNativeCell(2);
        new hp = GetNativeCell(5);
        GetNativeString(3,weapon,sizeof(weapon));
        GetNativeString(4,desc,sizeof(desc));
        DisplayDamage(client, victim, weapon, desc, hp);
    }
}

/**
 * Displays when a player is killed
 * @param client: The index of the attacking player (attacker)
 * @param victim: The index of the player that got killed
 * @param weapon: The short name of the weapon used to inflice the damage (for the log)
 * @param description: The description of the weapon (displayed to the players)
 * @param xp: The amount of XP gained
 * @noreturn
 * native DisplayKill(client, victim, const String:weapon[], const String:description[], xp=0);
 */
public Native_DisplayKill(Handle:plugin,numParams)
{
    if (numParams >= 4 && numParams <= 4)
    {
        decl String:weapon[64],String:desc[192];
        new client = GetNativeCell(1);
        new victim = GetNativeCell(2);
        new xp = (numParams >= 5) ? GetNativeCell(5) : 0;
        GetNativeString(3,weapon,sizeof(weapon));
        GetNativeString(4,desc,sizeof(desc));
        DisplayKill(client, victim, weapon, desc, xp);
    }
}

/**
 * Displays a message to a player
 * @param client: The index of the player to display the message to
 * @param flags: The message flags to categorize the message
 * @param fmt: The format string for the message
 * @param ...: Format arguments (if any)
 * @noreturn
 * native DisplayMessage(client, flags, const String:fmt[], any:...);
 */
public Native_DisplayMessage(Handle:plugin,numParams)
{
    if (numParams >= 3)
    {
        decl String:buffer[1024], written;
        new client = GetNativeCell(1);
        new flags = GetNativeCell(2);

        FormatNativeString(0, /* Use an output buffer */
                           3, /* Format param */
                           4, /* Format argument #1 */
                           sizeof(buffer), /* Size of output buffer */
                           written, /* Store # of written bytes */
                           buffer /* Use our buffer */
        );

        LogToGame(buffer);
        PrintToServer(buffer);

        if (client)
        {
            PrintToConsole(client, buffer);
            if ((g_DisplayFlags[client] & flags) == 0)
                PrintToChat(client, buffer);
        }
    }
}


/**
 * Gets the Player Handle used for the rest of the interface natives.
 * @param client: The client's index you want.
 * @return The return value will be the Player Handle, INVALID_HANDLE on failure.
 * native Handle:GetPlayerHandle(client);
 */
public Native_GetPlayerHandle(Handle:plugin,numParams)
{
    if (numParams == 1)
        return _:GetPlayerHandle(GetNativeCell(1));
    else
        return _:INVALID_HANDLE;
}

/**
 * Gets the current race for the player.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @return The return value will be the race of the player, if -1 then it failed.
 * native GetRace(Handle:player);
 */
public Native_GetRace(Handle:plugin,numParams)
{
    if (numParams==1)
    {
        new Handle:player=Handle:GetNativeCell(1);
        if (player != INVALID_HANDLE)
            return GetRace(player);
    }
    return -1;
}

/**
 * Changes the current race of the player.
 * @param player: The player handle to use. Can be retrieved with GetPlayerHandle.
 * @param race: The race ID returned from CreateRace.
 * @param force: Set true to force the race to change now or false to change on death.
 * @param check: Set true to check race requirements before changing.
 * @noreturn
 * native ChangeRace(Handle:player,race,bool:force=false,bool:check=true);
 */
public Native_ChangeRace(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 4)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new race=GetNativeCell(2);
        new bool:force=(numParams >= 3) ? (bool:GetNativeCell(3)) : false;
        new bool:check=(numParams >= 4) ? (bool:GetNativeCell(4)) : true;

        if (player != INVALID_HANDLE && race != -1)
        {
            ChangeRace(GetClientIndex(player), player, race,
                       GetRaceHandle(race), force, check);
        }
    }
}

public Native_GetLevel(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 2)
    {
        new Handle:player=Handle:GetNativeCell(1);

        new race = (numParams >= 2) ? GetNativeCell(2) : -1;
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1)
            return GetLevel(player,race);
    }
    return -1;
}

public Native_SetLevel(Handle:plugin,numParams)
{
    if (numParams==3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new newlevel=GetNativeCell(3);

        new race=GetNativeCell(2);
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1)
            SetLevel(player,race,newlevel);
    }
}

public Native_ResetLevel(Handle:plugin,numParams)
{
    if (numParams==3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new newlevel=GetNativeCell(3);

        new race=GetNativeCell(2);
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1)
            ResetLevel(player,race,newlevel);
    }
}

public Native_GetUpgradeLevel(Handle:plugin,numParams)
{
    if (numParams==3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new upgrade=GetNativeCell(3);

        new race=GetNativeCell(2);
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1 && upgrade != -1)
            return GetUpgradeLevel(player,race,upgrade);
    }
    return -1;
}

public Native_SetUpgradeLevel(Handle:plugin,numParams)
{
    if (numParams==4)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new upgrade=GetNativeCell(3);
        new newlevel=GetNativeCell(4);

        new race=GetNativeCell(2);
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1 && upgrade != -1)
            SetUpgradeLevel(player,race,upgrade,newlevel);
    }
}

public Native_ResetUpgradeLevels(Handle:plugin,numParams)
{
    if (numParams==1)
    {
        new Handle:player=Handle:GetNativeCell(1);
        if (player != INVALID_HANDLE)
        {
            ResetUpgradesNow(GetClientIndex(player),
                             player);
        }
    }
}

public Native_GetXP(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 2)
    {
        new Handle:player=Handle:GetNativeCell(1);

        new race = (numParams >= 2) ? GetNativeCell(2) : -1;
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1)
            return GetXP(player,race);
    }
    return -1;
}

public Native_SetXP(Handle:plugin,numParams)
{
    if (numParams==3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new newxp=GetNativeCell(3);

        new race=GetNativeCell(2);
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1 && newxp != -1)
        {
            SetXP(player,race,newxp);
            DoLevelCheck(GetClientIndex(player),player);
        }
    }
}

public Native_ResetXP(Handle:plugin,numParams)
{
    if (numParams==3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new newxp=GetNativeCell(3);

        new race=GetNativeCell(2);
        if (race == -1)
            race = GetRace(player);

        if (player != INVALID_HANDLE && race != -1 && newxp != -1)
        {
            ResetXP(player,race,newxp);
            DoLevelCheck(GetClientIndex(player),player);
        }
    }
}

public Native_GetCredits(Handle:plugin,numParams)
{
    if (numParams==1)
    {
        new Handle:player=Handle:GetNativeCell(1);
        if (player != INVALID_HANDLE)
            return GetCredits(player);
    }
    return -1;
}

public Native_SetCredits(Handle:plugin,numParams)
{
    if (numParams==2)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new newcredits=GetNativeCell(2);
        if (player != INVALID_HANDLE)
            SetCredits(player,newcredits);
    }
}

public Native_GetOverallLevel(Handle:plugin,numParams)
{
    if (numParams == 1)
    {
        new Handle:player=Handle:GetNativeCell(1);
        if (player != INVALID_HANDLE)
            return GetOverallLevel(player);
    }
    return -1;
}

public Native_SetOverallLevel(Handle:plugin,numParams)
{
    if (numParams==2)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new newlevel=GetNativeCell(2);

        if (player != INVALID_HANDLE)
            SetOverallLevel(player,newlevel);
    }
}

public Native_GetOwnsItem(Handle:plugin,numParams)
{
    if (numParams==2)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new item=GetNativeCell(2);
        if (player != INVALID_HANDLE && item != -1)
            return GetOwnsItem(player,item);
    }
    return -1;
}

public Native_SetOwnsItem(Handle:plugin,numParams)
{
    if (numParams==3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new item=GetNativeCell(2);
        new owns=GetNativeCell(3);
        if (player != INVALID_HANDLE && item != -1)
            SetOwnsItem(player,item,owns);
    }
}

public Native_GetImmunity(Handle:plugin,numParams)
{
    if (numParams==2)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new immunity=GetNativeCell(2);
        if (player != INVALID_HANDLE && immunity != -1)
            return GetImmunity(player,immunity);
    }
    return -1;
}

public Native_SetImmunity(Handle:plugin,numParams)
{
    if (numParams==3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new immunity=GetNativeCell(2);
        new imm_state=GetNativeCell(3);
        if (player != INVALID_HANDLE && immunity != -1 && imm_state != -1)
            SetImmunity(player,immunity,imm_state);
    }
}

public Native_SetSpeed(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        if (player != INVALID_HANDLE)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1, Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,TRACKING_PLUGIN_HANDLE))
                {
                    indice=x;
                    indiceHandle=t;
                    break;
                }
            }
            if(indice>-1)
            {
                // update existing entry
                SetArrayCell(indiceHandle,TRACKING_SPEED,speed);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,-1.0); // force speed?
                PushArrayCell(indiceHandle,-1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(indiceHandle,speed); // speed
                PushArrayCell(indiceHandle,-1.0); // gravity
                PushArrayCell(indiceHandle,-1); // visibility 
                PushArrayCell(indiceHandle,-1); // visibility type
                PushArrayCell(indiceHandle,-1.0); // visibility factor1 (melee/delay)
                PushArrayCell(indiceHandle,-1.0); // visibility factor2 (movement/duration)
                PushArrayCell(indiceHandle,-1); // visibility render mode
                PushArrayCell(indiceHandle,-1); // visibility render fx
                PushArrayCell(indiceHandle,-1); // visibility red component
                PushArrayCell(indiceHandle,-1); // visibility green component
                PushArrayCell(indiceHandle,-1); // visibility blue component
                PushArrayCell(indiceHandle,false); // visibility color weapons flag
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            if (numParams >= 3 && bool:GetNativeCell(3))
                TriggerTimer(m_PlayerPropertiesTimer, true);
        }
    }
}

public Native_SetGravity(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 3)
    {
        new Handle:player=Handle:GetNativeCell(1);
        new Float:gravity=GetNativeCell(2);
        if (player!=INVALID_HANDLE)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,TRACKING_PLUGIN_HANDLE))
                {
                    indice=x;
                    indiceHandle=t;
                    break;
                }
            }
            if(indice>-1)
            {
                // update existing entry
                SetArrayCell(indiceHandle,TRACKING_GRAVITY,gravity);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,-1.0); // force speed?
                PushArrayCell(indiceHandle,-1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(indiceHandle,-1.0); // speed
                PushArrayCell(indiceHandle,gravity); // gravity
                PushArrayCell(indiceHandle,-1); // visibility 
                PushArrayCell(indiceHandle,-1); // visibility type
                PushArrayCell(indiceHandle,-1.0); // visibility factor1 (melee/delay)
                PushArrayCell(indiceHandle,-1.0); // visibility factor2 (movement/duration)
                PushArrayCell(indiceHandle,-1); // visibility render mode
                PushArrayCell(indiceHandle,-1); // visibility render fx
                PushArrayCell(indiceHandle,-1); // visibility red component
                PushArrayCell(indiceHandle,-1); // visibility green component
                PushArrayCell(indiceHandle,-1); // visibility blue component
                PushArrayCell(indiceHandle,false); // visibility color weapons flag
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            if (numParams >= 3 && bool:GetNativeCell(3))
                TriggerTimer(m_PlayerPropertiesTimer, true);
        }
    }
}

/**
* Sets the visibility for the player that is handled within the SourceCraft system,
* good for upgrades and items that set (in)visibility so you don't end up making the player
* more visibile. Pass 255 as visibility when they no longer should use the (in)visibility,
* make sure to do this when they no longer have the upgrade or item, or whatever.
* @param player: The player ID to use. Can be retrieved with GetPlayer.
* @param visibility: The visibility you want to pass.
* @param type: The type of visibility to use.
* @param factor1: The 1st factor (either melee factor or activation delay)
* @param factor2: The 2nd factopr (either movement factor or duration)
* @param mode: The Render mode
* @param fx: The Render Fx
* @param r: Red Component.
* @param g: Green Component.
* @param b: Blue Component.
* @noreturn
* native SetVisibility(player,visibility,VisibilityType:type,Float:factor1,Float:factor2,
*                      RenderFx:fx,RenderMode:mode,r,g,b);
*/
public Native_SetVisibility(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 12)
    {
        new Handle:player       = Handle:GetNativeCell(1);
        new visibility          = (numParams >= 2) ? GetNativeCell(2) : -1;
        new VisibilityType:type = (numParams >= 3) ? GetNativeCell(3) : VisibilityType:-1;
        new Float:factor1       = (numParams >= 4) ? GetNativeCell(4) : -1.0;
        new Float:factor2       = (numParams >= 5) ? GetNativeCell(5) : -1.0;
        new RenderMode:mode     = (numParams >= 6) ? GetNativeCell(6) : RenderMode:-1;
        new RenderFx:fx         = (numParams >= 7) ? GetNativeCell(7) : RenderFx:-1; 
        new r                   = (numParams >= 8) ? GetNativeCell(8) : -1;
        new g                   = (numParams >= 9) ? GetNativeCell(9) : -1;
        new b                   = (numParams >= 10) ? GetNativeCell(10) : -1;
        new colorWeapons        = (numParams >= 11) ? GetNativeCell(11) : -1;
        if(player != INVALID_HANDLE)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,TRACKING_PLUGIN_HANDLE))
                {
                    indice=x;
                    indiceHandle=t;
                    break;
                }
            }
            if(indice>-1)
            {
                //LogMessage("[natives] Update visibility for %N to %d, type=%d,f1=%f,f2=%f,mode=%d,fx=%d",
                //           GetClientIndex(player), visibility,type,factor1,factor2,mode,fx);
                // update existing entry
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY,visibility);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_TYPE,type);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_FACTOR1,factor1);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_FACTOR2,factor2);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_MODE,mode);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_FX,fx);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_R,r);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_G,g);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_B,b);
                SetArrayCell(indiceHandle,TRACKING_VISIBILITY_WEAPONS,colorWeapons);
            }
            else
            {
                //LogMessage("[natives] Set visibility for %N to %d, type=%d,f1=%f,f2=%f,mode=%d,fx=%d",
                //           GetClientIndex(player), visibility,type,factor1,factor2,mode,fx);
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,-1.0); // force speed?
                PushArrayCell(indiceHandle,-1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(indiceHandle,-1.0); // speed
                PushArrayCell(indiceHandle,-1.0); // gravity
                PushArrayCell(indiceHandle,visibility); // visibility 
                PushArrayCell(indiceHandle,type); // visibility type
                PushArrayCell(indiceHandle,factor1); // visibility factor1 (melee/delay)
                PushArrayCell(indiceHandle,factor2); // visibility factor2 (movement/duration)
                PushArrayCell(indiceHandle,mode); // visibility render mode
                PushArrayCell(indiceHandle,fx); // visibility render fx
                PushArrayCell(indiceHandle,r); // visibility red component
                PushArrayCell(indiceHandle,g); // visibility green component
                PushArrayCell(indiceHandle,b); // visibility blue component
                PushArrayCell(indiceHandle,colorWeapons); // visibility color weapons flag
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            if (numParams >= 12 && bool:GetNativeCell(12))
                TriggerTimer(m_PlayerPropertiesTimer, true);
        }
    }
}

public Native_SetOverrideSpeed(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 3)
    {
        new Handle:player = Handle:GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        //LogMessage("[natives] Set overridespeed of %N to %f", GetClientIndex(player), speed);
        if (player != INVALID_HANDLE)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,TRACKING_PLUGIN_HANDLE))
                {
                    indice=x;
                    indiceHandle=t;
                    break;
                }
            }
            if(indice>-1)
            {
                // update existing entry
                SetArrayCell(indiceHandle,TRACKING_OVERRIDE_SPEED,speed);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,speed); // force speed?
                PushArrayCell(indiceHandle,-1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(indiceHandle,-1.0); // speed
                PushArrayCell(indiceHandle,-1.0); // gravity
                PushArrayCell(indiceHandle,-1); // visibility 
                PushArrayCell(indiceHandle,-1); // visibility type
                PushArrayCell(indiceHandle,-1.0); // visibility factor1 (melee/delay)
                PushArrayCell(indiceHandle,-1.0); // visibility factor2 (movement/duration)
                PushArrayCell(indiceHandle,-1); // visibility render mode
                PushArrayCell(indiceHandle,-1); // visibility render fx
                PushArrayCell(indiceHandle,-1); // visibility red component
                PushArrayCell(indiceHandle,-1); // visibility green component
                PushArrayCell(indiceHandle,-1); // visibility blue component
                PushArrayCell(indiceHandle,false); // visibility color weapons flag
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            if (numParams >= 3 && bool:GetNativeCell(3))
                TriggerTimer(m_PlayerPropertiesTimer, true);
        }
    }
}

public Native_SetOverrideGravity(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 3)
    {
        new Handle:player = Handle:GetNativeCell(1);
        new Float:gravity=GetNativeCell(2);
        if (player != INVALID_HANDLE)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,TRACKING_PLUGIN_HANDLE))
                {
                    indice=x;
                    indiceHandle=t;
                    break;
                }
            }
            if(indice>-1)
            {
                // update existing entry
                SetArrayCell(indiceHandle,TRACKING_OVERRIDE_GRAVITY,gravity);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,-1.0); // force speed?
                PushArrayCell(indiceHandle,gravity); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(indiceHandle,-1.0); // speed
                PushArrayCell(indiceHandle,-1.0); // gravity
                PushArrayCell(indiceHandle,-1); // visibility 
                PushArrayCell(indiceHandle,-1); // visibility type
                PushArrayCell(indiceHandle,-1.0); // visibility factor1 (melee/delay)
                PushArrayCell(indiceHandle,-1.0); // visibility factor2 (movement/duration)
                PushArrayCell(indiceHandle,-1); // visibility render mode
                PushArrayCell(indiceHandle,-1); // visibility render fx
                PushArrayCell(indiceHandle,-1); // visibility red component
                PushArrayCell(indiceHandle,-1); // visibility green component
                PushArrayCell(indiceHandle,-1); // visibility blue component
                PushArrayCell(indiceHandle,false); // visibility color weapons flag
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            if (numParams >= 3 && bool:GetNativeCell(3))
                TriggerTimer(m_PlayerPropertiesTimer, true);
        }
    }
}

public Native_SetOverrideVisiblity(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 3)
    {
        new Handle:player = Handle:GetNativeCell(1);
        new visibility=GetNativeCell(2);
        if (player != INVALID_HANDLE)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,TRACKING_PLUGIN_HANDLE))
                {
                    indice=x;
                    indiceHandle=t;
                    break;
                }
            }
            if(indice>-1)
            {
                // update existing entry
                SetArrayCell(indiceHandle,TRACKING_OVERRIDE_VISIBILITY,visibility);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,-1.0); // force speed?
                PushArrayCell(indiceHandle,-1.0); // force gravity?
                PushArrayCell(indiceHandle,visibility); // force visibility?
                PushArrayCell(indiceHandle,-1.0); // speed
                PushArrayCell(indiceHandle,-1.0); // gravity
                PushArrayCell(indiceHandle,-1); // visibility 
                PushArrayCell(indiceHandle,-1); // visibility type
                PushArrayCell(indiceHandle,-1.0); // visibility factor1 (melee/delay)
                PushArrayCell(indiceHandle,-1.0); // visibility factor2 (movement/duration)
                PushArrayCell(indiceHandle,-1); // visibility render mode
                PushArrayCell(indiceHandle,-1); // visibility render fx
                PushArrayCell(indiceHandle,-1); // visibility red component
                PushArrayCell(indiceHandle,-1); // visibility green component
                PushArrayCell(indiceHandle,-1); // visibility blue component
                PushArrayCell(indiceHandle,false); // visibility color weapons flag
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            if (numParams >= 3 && bool:GetNativeCell(3))
                TriggerTimer(m_PlayerPropertiesTimer, true);
        }
    }
}

public Native_RestorePlayer(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 2)
    {
        new Handle:player=Handle:GetNativeCell(1);
        if (player != INVALID_HANDLE)
        {
            new Handle:pinfo=GetArrayCell(player,INFO_PROPERTIES);
            for(new y=0;y<GetArraySize(pinfo);y++)
            {
                new Handle:temp = GetArrayCell(pinfo,y);
                SetArrayCell(temp,TRACKING_OVERRIDE_SPEED, -1.0);
                SetArrayCell(temp,TRACKING_OVERRIDE_GRAVITY, -1.0);
                SetArrayCell(temp,TRACKING_OVERRIDE_VISIBILITY, -1.0);
                SetArrayCell(temp,TRACKING_VISIBILITY_R, -1);
                SetArrayCell(temp,TRACKING_VISIBILITY_G, -1);
                SetArrayCell(temp,TRACKING_VISIBILITY_B, -1);
            }
            if (numParams >= 2 && bool:GetNativeCell(2))
                TriggerTimer(m_PlayerPropertiesTimer, true);
        }
    }
}

public Native_ApplyPlayerSettings(Handle:plugin,numParams)
{
    TriggerTimer(m_PlayerPropertiesTimer, true);
}

bool:InitNatives()
{
    CreateNative("CreateRace",Native_CreateRace);
    CreateNative("AddUpgrade",Native_AddUpgrade);
    CreateNative("CreateShopItem",Native_CreateShopItem);
    CreateNative("CreateHelpCommand",Native_CreateHelpCommand);
    CreateNative("FindShopItem",Native_FindShopItem);
    CreateNative("FindRace",Native_FindRace);
    CreateNative("HealPlayer",Native_HealPlayer);
    CreateNative("HurtPlayer",Native_HurtPlayer);
    CreateNative("KillPlayer",Native_KillPlayer);
    CreateNative("DisplayDamage",Native_DisplayDamage);
    CreateNative("DisplayKill",Native_DisplayKill);
    CreateNative("DisplayMessage",Native_DisplayMessage);
    CreateNative("GetPlayerHandle",Native_GetPlayerHandle);
    CreateNative("GetRace",Native_GetRace);
    CreateNative("ChangeRace",Native_ChangeRace);
    CreateNative("GetLevel",Native_GetLevel);
    CreateNative("SetLevel",Native_SetLevel);
    CreateNative("ResetLevel",Native_ResetLevel);
    CreateNative("GetUpgradeLevel",Native_GetUpgradeLevel);
    CreateNative("SetUpgradeLevel",Native_SetUpgradeLevel);
    CreateNative("ResetUpgradeLevels",Native_ResetUpgradeLevels);
    CreateNative("GetXP",Native_GetXP);
    CreateNative("SetXP",Native_SetXP);
    CreateNative("ResetXP",Native_ResetXP);
    CreateNative("GetCredits",Native_GetCredits);
    CreateNative("SetCredits",Native_SetCredits);
    CreateNative("GetOverallLevel",Native_GetOverallLevel);
    CreateNative("SetOverallLevel",Native_SetOverallLevel);
    CreateNative("GetOwnsItem",Native_GetOwnsItem);
    CreateNative("SetOwnsItem",Native_SetOwnsItem);
    CreateNative("GetImmunity",Native_GetImmunity);
    CreateNative("SetImmunity",Native_SetImmunity);
    CreateNative("SetSpeed",Native_SetSpeed);
    CreateNative("SetGravity",Native_SetGravity);
    CreateNative("SetVisibility",Native_SetVisibility);
    CreateNative("SetOverrideSpeed",Native_SetOverrideSpeed);
    CreateNative("SetOverrideGravity",Native_SetOverrideGravity);
    CreateNative("SetOverrideVisiblity",Native_SetOverrideVisiblity);
    CreateNative("ApplyPlayerSettings",Native_ApplyPlayerSettings);
    CreateNative("RestorePlayer",Native_RestorePlayer);
    RegPluginLibrary("sourcecraft");
    return true;
}

bool:InitForwards()
{
    g_OnPlayerAuthedHandle=CreateGlobalForward("OnPlayerAuthed",ET_Ignore,Param_Cell,Param_Cell);
    g_OnUltimateCommandHandle=CreateGlobalForward("OnUltimateCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnPluginReadyHandle=CreateGlobalForward("OnPluginReady",ET_Ignore);
    g_OnRaceSelectedHandle=CreateGlobalForward("OnRaceSelected",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnUpgradeLevelChangedHandle=CreateGlobalForward("OnUpgradeLevelChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnItemPurchaseHandle=CreateGlobalForward("OnItemPurchase",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    g_OnXPGivenHandle=CreateGlobalForward("OnXPGiven",ET_Hook,Param_Cell,Param_Cell,Param_CellByRef,Param_Cell);
    g_OnCreditsGivenHandle=CreateGlobalForward("OnCreditsGiven",ET_Hook,Param_Cell,Param_Cell,Param_CellByRef,Param_Cell);
    g_OnPlayerHurtEventHandle=CreateGlobalForward("OnPlayerHurtEvent",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_String,Param_Cell);
    g_OnPlayerDeathEventHandle=CreateGlobalForward("OnPlayerDeathEvent",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_String,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnObjectKilledHandle = CreateGlobalForward("OnObjectKilled",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    return true;
}
