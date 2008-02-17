/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: natives.inc
 * Description: All the natives that keep us from having to make a C++ extension,
 *              I <3 SourceMod :) (Note: Forwards are handled here too.)
 * Author(s): Anthony Iacono  
 */

// Handles
new Handle:g_OnPluginReadyHandle = INVALID_HANDLE;
new Handle:g_OnPlayerAuthedHandle = INVALID_HANDLE;
new Handle:g_OnUltimateCommandHandle = INVALID_HANDLE;
new Handle:g_OnItemPurchaseHandle = INVALID_HANDLE;
new Handle:g_OnCreditsGivenHandle = INVALID_HANDLE;
new Handle:g_OnXPGivenHandle = INVALID_HANDLE;
new Handle:g_OnPlayerHurtEventHandle = INVALID_HANDLE;
new Handle:g_OnPlayerDeathEventHandle = INVALID_HANDLE;

public Native_CreateRace(Handle:plugin,numParams)
{
    if (numParams >=12 && numParams <= 13)
    {
        decl String:name[64],String:short[16],String:switchmessage_instant[192],String:switchmessage_dead[192];
        decl String:skill1[64],String:skill1_desc[192],String:skill2[64],String:skill2_desc[192];
        decl String:skill3[64],String:skill3_desc[192],String:ult[64],String:ult_desc[192];
        decl String:required_level[4];
        GetNativeString(1,name,sizeof(name));
        GetNativeString(2,short,sizeof(short));
        GetNativeString(3,switchmessage_instant,sizeof(switchmessage_instant));
        GetNativeString(4,switchmessage_dead,sizeof(switchmessage_dead));
        GetNativeString(5,skill1,sizeof(skill1));
        GetNativeString(6,skill1_desc,sizeof(skill1_desc));
        GetNativeString(7,skill2,sizeof(skill2));
        GetNativeString(8,skill2_desc,sizeof(skill2_desc));
        GetNativeString(9,skill3,sizeof(skill3));
        GetNativeString(10,skill3_desc,sizeof(skill3_desc));
        GetNativeString(11,ult,sizeof(ult));
        GetNativeString(12,ult_desc,sizeof(ult_desc));

        if (numParams >= 13)
            GetNativeString(13,required_level,sizeof(required_level));
        else
            strcopy(required_level, sizeof(required_level), "0");

        new Handle:race=CreateRace(name,short,switchmessage_instant,switchmessage_dead,
                                   skill1,skill1_desc,skill2,skill2_desc,skill3,skill3_desc,
                                   ult,ult_desc,required_level);
        PushArrayCell(arrayRaces,race);
        return GetArraySize(arrayRaces)-1;
    }
    return -1;
}

public Native_CreateShopItem(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        decl String:name[64],String:desc[256],String:cost[4];
        GetNativeString(1,name,sizeof(name));
        GetNativeString(2,desc,sizeof(desc));
        GetNativeString(3,cost,sizeof(cost));
        new Handle:item=CreateShopItem(name,desc,cost);
        PushArrayCell(shopVector,item);
        return GetArraySize(shopVector)-1;
    }
    return -1;
}

public Native_CreateHelpCommand(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        decl String:name[64];
        GetNativeString(1,name,sizeof(name));
        decl String:desc[256];
        GetNativeString(2,desc,sizeof(desc));
        NewHelpCommand(name,desc);
    }
}

public Native_GetShopItem(Handle:plugin,numParams)
{
    if(numParams==1)
    {
        decl String:name[64];
        GetNativeString(1,name,sizeof(name));
        return GetShopItem(name);
    }
    else
        return -1;
}

/**
 * Kill a player.
 * @param client: The client's index you want.
 * @param attacker: The index of the attacker.
 * @param weapon: The weapon used to deal the damage to the client.
 * @param assister: The index of the assister.
 * @noreturn
 * native KillPlayer(client, attacker=0, const String:weapon[]="", assister=0);
 */
public Native_KillPlayer(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 4)
    {
        new client = GetNativeCell(1);
        /*
        new Handle:event = CreateEvent("player_death");
        if (event != INVALID_HANDLE)
        {
            SetEventInt(event, "userid", GetClientUserId(client));
            SetEventInt(event, "attacker", (numParams >= 2) ? GetClientUserId(GetNativeCell(2)) : 0);
            if (numParams >= 3)
            {
                decl weapon[64] = "";
                GetNativeString(3,weapon,sizeof(weapon));
                SetEventString(event, "weapon", weapon);
            }
            SetEventInt(event, "assister", (numParams >= 4) ? GetClientUserId(GetNativeCell(4)) : 0);
            SetEventBool(event, "from_sourcecraft" true);
            FireEvent(event);
        }
        */
        // die! die! die!!!!
        //SetEntityHealth(client,0);
        //ForcePlayerSuicide(client);
        FakeClientCommand(client,"kill\n");
        SaveHealth(client);
        return 0;
    }
    else
        return -1;
} 

/**
 * Take health from (damage) a player
 * @param client: The client's index you want.
 * @param damage: The amount to damage to deal to the client.
 * @param attacker: The index of the attacker.
 * @param weapon: The weapon used to deal the damage to the client.
 * @param assister: The index of the assister.
 * @noreturn
 * native HurtPlayer(client, damage, attacker=0, const String:weapon[]="", assister=0);
 */
public Native_HurtPlayer(Handle:plugin,numParams)
{
    if (numParams >= 2 && numParams <= 5)
    {
        new victim = GetNativeCell(1);
        new damage = GetNativeCell(2);
        new health = GetClientHealth(victim) - damage;
        SetEntityHealth(victim,health);
        new Handle:event = CreateEvent("player_hurt");
        if (event != INVALID_HANDLE)
        {
            new attacker = 0;
            new assister = 0;
            decl String:weapon[64] = "";
            if (numParams >= 3)
            {
                attacker = GetNativeCell(3);
                if (numParams >= 4)
                {
                    GetNativeString(4,weapon,sizeof(weapon));
                    if (numParams >= 5)
                        assister = GetNativeCell(5);
                }
            }

            SetEventInt(event, "userid", GetClientUserId(victim));
            SetEventInt(event, "attacker", (attacker) ? GetClientUserId(attacker) : 0);
            SetEventInt(event, "health", health);
            SetEventInt(event, "damage", damage);
            SetEventString(event, "weapon", weapon);
            SetEventInt(event, "assister", (assister) ? GetClientUserId(assister) : 0);
            SetEventBool(event, "from_sourcecraft", true);
            FireEvent(event);
        }
        SaveHealth(victim);
        return health;
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
 * Get a Player's TF2 class
 * @param client: The client's index you want.
 * @return The player's class
 */
public Native_GetClass(Handle:plugin,numParams)
{
    if(numParams==1 && GameType == tf2)
        return GetClass(GetNativeCell(1));
    else
        return -1;
}

public Native_GetPlayer(Handle:plugin,numParams)
{
    if(numParams==1)
        return GetClientVectorPosition(GetNativeCell(1));
    else
        return -1;
}

public Native_GetRace(Handle:plugin,numParams)
{
    if(numParams==1)
    {
        new player=GetNativeCell(1);
        if(player!=-1)
            return GetRace(player);
    }
    return -1;
}

public Native_GetLevel(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new race=GetNativeCell(2);
        if(player!=-1&&race!=-1)
            return GetLevel(player,race);
    }
    return -1;
}

public Native_SetLevel(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new player=GetNativeCell(1);
        new race=GetNativeCell(2);
        new newlevel=GetNativeCell(3);
        if(player!=-1&&race!=-1)
            SetLevel(player,race,newlevel);
    }
}

public Native_GetSkillLevel(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new player=GetNativeCell(1);
        new race=GetNativeCell(2);
        new skill=GetNativeCell(3);
        if(player!=-1&&race!=-1&&skill!=-1)
            return GetSkillLevel(player,race,skill);
    }
    return -1;
}

public Native_SetSkillLevel(Handle:plugin,numParams)
{
    if(numParams==4)
    {
        new player=GetNativeCell(1);
        new race=GetNativeCell(2);
        new skill=GetNativeCell(3);
        new newlevel=GetNativeCell(4);
        if(player!=-1&&race!=-1&&skill!=-1)
            SetSkillLevel(player,race,skill,newlevel);
    }
}

public Native_GetXP(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new race=GetNativeCell(2);
        if(player!=-1&&race!=-1)
            return GetXP(player,race);
    }
    return -1;
}

public Native_SetXP(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new player=GetNativeCell(1);
        new race=GetNativeCell(2);
        new newxp=GetNativeCell(3);
        if(player!=-1&&race!=-1&&newxp!=-1)
        {
            SetXP(player,race,newxp);
            DoLevelCheck(GetClientIndex(player),player);
        }
    }
}

public Native_GetCredits(Handle:plugin,numParams)
{
    if(numParams==1)
    {
        new player=GetNativeCell(1);
        if(player!=-1)
            return GetCredits(player);
    }
    return -1;
}

public Native_SetCredits(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new newcredits=GetNativeCell(2);
        if(player!=-1)
            SetCredits(player,newcredits);
    }
}

public Native_GetOwnsItem(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new item=GetNativeCell(2);
        if(player!=-1&&item!=-1)
            return GetOwnsItem(player,item);
    }
    return -1;
}

public Native_SetOwnsItem(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new player=GetNativeCell(1);
        new item=GetNativeCell(2);
        new owns=GetNativeCell(3);
        if(player!=-1&&item!=-1)
            SetOwnsItem(player,item,owns);
    }
}

public Native_GetImmunity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new immunity=GetNativeCell(2);
        if(player!=-1&&immunity!=-1)
            return GetImmunity(player,immunity);
    }
    return -1;
}

public Native_SetImmunity(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new player=GetNativeCell(1);
        new immunity=GetNativeCell(2);
        new imm_state=GetNativeCell(3);
        if(player!=-1&&immunity!=-1&&imm_state!=-1)
            SetImmunity(player,immunity,imm_state);
    }
}

public Native_SetSpeed(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        if (player != -1)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,0))
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
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
        }
    }
}

public Native_SetGravity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new Float:gravity=GetNativeCell(2);
        if (player!=-1)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,0))
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
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
        }
    }
}

/**
* Sets the visibility for the player that is handled within the SourceCraft system,
* good for skills and items that set (in)visibility so you don't end up making the player
* more visibile. Pass 255 as visibility when they no longer should use the (in)visibility,
* make sure to do this when they no longer have the skill or item, or whatever.
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
    if(numParams >= 1 && numParams <= 10)
    {
        new player              = GetNativeCell(1);
        new visibility          = (numParams >= 2) ? GetNativeCell(2) : -1;
        new VisibilityType:type = (numParams >= 3) ? GetNativeCell(3) : VisibilityType:-1;
        new Float:factor1       = (numParams >= 4) ? GetNativeCell(4) : -1.0;
        new Float:factor2       = (numParams >= 5) ? GetNativeCell(5) : -1.0;
        new RenderMode:mode     = (numParams >= 6) ? GetNativeCell(6) : RenderMode:-1;
        new RenderFx:fx         = (numParams >= 7) ? GetNativeCell(7) : RenderFx:-1; 
        new r                   = (numParams >= 8) ? GetNativeCell(8) : -1;
        new g                   = (numParams >= 9) ? GetNativeCell(9) : -1;
        new b                   = (numParams >= 10) ? GetNativeCell(10) : -1;
        if(player != -1)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,0))
                {
                    indice=x;
                    indiceHandle=t;
                    break;
                }
            }
            if(indice>-1)
            {
                LogMessage("[natives] Update visibility for %N to %d, type=%d,f1=%f,f2=%f,mode=%d,fx=%d",
                           GetClientIndex(player), visibility,type,factor1,factor2,mode,fx);
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
            }
            else
            {
                LogMessage("[natives] Set visibility for %N to %d, type=%d,f1=%f,f2=%f,mode=%d,fx=%d",
                           GetClientIndex(player), visibility,type,factor1,factor2,mode,fx);
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
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
        }
    }
}

public Native_SetOverrideSpeed(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        LogMessage("[natives] Set overridespeed of %N to %f", GetClientIndex(player), speed);
        if(player!=-1)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,0))
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
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
        }
    }
}

public Native_SetOverrideGravity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new Float:gravity=GetNativeCell(2);
        if(player!=-1)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,0))
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
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
        }
    }
}

public Native_SetOverrideVisiblity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new visibility=GetNativeCell(2);
        if(player!=-1)
        {
            new Handle:temp=GetPropertyInfo(player);
            new indice=-1,Handle:indiceHandle;
            for(new x=0;x<GetArraySize(temp);x++)
            {
                new Handle:t=GetArrayCell(temp,x);
                if(plugin==GetArrayCell(t,0))
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
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
        }
    }
}

public bool:InitNatives()
{
    CreateNative("CreateRace",Native_CreateRace);
    CreateNative("CreateShopItem",Native_CreateShopItem);
    CreateNative("CreateHelpCommand",Native_CreateHelpCommand);
    CreateNative("GetShopItem",Native_GetShopItem);
    CreateNative("KillPlayer",Native_KillPlayer);
    CreateNative("HurtPlayer",Native_HurtPlayer);
    CreateNative("HealPlayer",Native_HealPlayer);
    CreateNative("GetClass",Native_GetRace);
    CreateNative("GetPlayer",Native_GetPlayer);
    CreateNative("GetRace",Native_GetRace);
    CreateNative("GetLevel",Native_GetLevel);
    CreateNative("SetLevel",Native_SetLevel);
    CreateNative("GetSkillLevel",Native_GetSkillLevel);
    CreateNative("SetSkillLevel",Native_SetSkillLevel);
    CreateNative("GetXP",Native_GetXP);
    CreateNative("SetXP",Native_SetXP);
    CreateNative("GetCredits",Native_GetXP);
    CreateNative("SetCredits",Native_SetXP);
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
    return true;
}

public bool:InitForwards()
{
    g_OnPlayerAuthedHandle=CreateGlobalForward("OnPlayerAuthed",ET_Ignore,Param_Cell,Param_Cell);
    g_OnUltimateCommandHandle=CreateGlobalForward("OnUltimateCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnPluginReadyHandle=CreateGlobalForward("OnPluginReady",ET_Ignore);
    g_OnRaceSelectedHandle=CreateGlobalForward("OnRaceSelected",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnSkillLevelChangedHandle=CreateGlobalForward("OnSkillLevelChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnItemPurchaseHandle=CreateGlobalForward("OnItemPurchase",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    g_OnXPGivenHandle=CreateGlobalForward("OnXPGiven",ET_Hook,Param_Cell,Param_Cell,Param_CellByRef,Param_Cell);
    g_OnCreditsGivenHandle=CreateGlobalForward("OnCreditsGiven",ET_Hook,Param_Cell,Param_Cell,Param_CellByRef,Param_Cell);
    g_OnPlayerHurtEventHandle=CreateGlobalForward("OnPlayerHurtEvent",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_String,Param_Cell);
    g_OnPlayerDeathEventHandle=CreateGlobalForward("OnPlayerDeathEvent",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_String,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    return true;
}
