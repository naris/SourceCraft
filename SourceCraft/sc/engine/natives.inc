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
new Handle:g_OnSkillLevelChangedHandle = INVALID_HANDLE;
new Handle:g_OnRaceSelectedHandle = INVALID_HANDLE;
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
 * @param weapon: The weapon used to deal the damage to the client.
 * @param attacker: The index of the attacker.
 * @param attacker: The index of the assister.
 * @noreturn
 * native HurtPlayer(client, damage, const String:weapon[]="", attacker=0, assister=0);
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
            decl String:weapon[64] = "";
            if (numParams >= 4)
                GetNativeString(4,weapon,sizeof(weapon));

            SetEventInt(event, "userid", GetClientUserId(victim));
            SetEventInt(event, "attacker", (numParams >= 3) ? GetClientUserId(GetNativeCell(3)) : 0);
            SetEventInt(event, "health", health);
            SetEventInt(event, "damage", damage);
            SetEventString(event, "weapon", weapon);
            SetEventInt(event, "assister", (numParams >= 5) ? GetClientUserId(GetNativeCell(5)) : 0);
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
 * @noreturn
 * native HealPlayer(client, amount);
 */
public Native_HealPlayer(Handle:plugin,numParams)
{
    if (numParams == 2)
    {
        new client = GetNativeCell(1);
        new amount = GetNativeCell(2);
        new health = GetClientHealth(client) + amount;
        SetEntityHealth(client,health);
        SaveHealth(client);
        return health;
    }
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
        new Handle:playerHandle=GetArrayCell(arrayPlayers,player);
        if(player!=-1&&race!=-1&&newxp!=-1)
        {
            SetXP(player,race,newxp);
            DoLevelCheck(GetArrayCell(playerHandle,0),player);
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

public Native_SetMaxSpeed(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        if(player != -1 && speed > 0)
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
                SetArrayCell(indiceHandle,1,speed);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,speed); // maxspeed speed
                PushArrayCell(indiceHandle,1.0); // mingravity gravity
                PushArrayCell(indiceHandle,255); // minvisibility 
                PushArrayCell(indiceHandle,1.0); // visibility melee factor
                PushArrayCell(indiceHandle,1.0); // visibility movement factor
                PushArrayCell(indiceHandle,1.0); // force speed?
                PushArrayCell(indiceHandle,1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(player,temp);
        }
    }
}

public Native_SetMinGravity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new Float:gravity=GetNativeCell(2);
        if(player!=-1&&gravity>0)
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
                SetArrayCell(indiceHandle,2,gravity);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,1.0); // maxspeed speed
                PushArrayCell(indiceHandle,gravity); // mingravity gravity
                PushArrayCell(indiceHandle,255); // minvisibility 
                PushArrayCell(indiceHandle,1.0); // visibility melee factor
                PushArrayCell(indiceHandle,1.0); // visibility movement factor
                PushArrayCell(indiceHandle,1.0); // force speed?
                PushArrayCell(indiceHandle,1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(player,temp);
        }
    }
}

public Native_SetMinVisibility(Handle:plugin,numParams)
{
    if(numParams >= 2 && numParams <= 4)
    {
        new player=GetNativeCell(1);
        new visibility=GetNativeCell(2);
        new Float:meleeFactor = (numParams > 2) ? GetNativeCell(3) : 1.0;
        new Float:movementFactor = (numParams > 3) ? GetNativeCell(4) : 1.0;
        if(player != -1 && visibility > -1)
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
                SetArrayCell(indiceHandle,3,visibility);
                SetArrayCell(indiceHandle,4,meleeFactor);
                SetArrayCell(indiceHandle,5,movementFactor);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,1.0); // maxspeed speed
                PushArrayCell(indiceHandle,1.0); // mingravity gravity
                PushArrayCell(indiceHandle,visibility); // minvisibility 
                PushArrayCell(indiceHandle,meleeFactor); // visibility melee factor
                PushArrayCell(indiceHandle,movementFactor); // visibility movement factor
                PushArrayCell(indiceHandle,1.0); // force speed?
                PushArrayCell(indiceHandle,1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(player,temp);
        }
    }
}

public Native_SetOverrideSpeed(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new player=GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        LogMessage("[natives] Set overridespeed of %d to %f", player, speed);
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
                SetArrayCell(indiceHandle,6,speed);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,1.0); // maxspeed speed
                PushArrayCell(indiceHandle,1.0); // mingravity gravity
                PushArrayCell(indiceHandle,255); // minvisibility 
                PushArrayCell(indiceHandle,1.0); // visibility melee factor
                PushArrayCell(indiceHandle,1.0); // visibility movement factor
                PushArrayCell(indiceHandle,speed); // force speed?
                PushArrayCell(indiceHandle,1.0); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(player,temp);
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
                SetArrayCell(indiceHandle,7,gravity);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,1.0); // maxspeed speed
                PushArrayCell(indiceHandle,1.0); // mingravity gravity
                PushArrayCell(indiceHandle,255); // minvisibility 
                PushArrayCell(indiceHandle,1.0); // visibility melee factor
                PushArrayCell(indiceHandle,1.0); // visibility movement factor
                PushArrayCell(indiceHandle,1.0); // force speed?
                PushArrayCell(indiceHandle,gravity); // force gravity?
                PushArrayCell(indiceHandle,-1); // force visibility?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(player,temp);
        }
    }
}

public Native_SetOverrideVisible(Handle:plugin,numParams)
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
                SetArrayCell(indiceHandle,8,visibility);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,1.0); // maxspeed speed
                PushArrayCell(indiceHandle,1.0); // mingravity gravity
                PushArrayCell(indiceHandle,255); // minvisibility 
                PushArrayCell(indiceHandle,1.0); // visibility melee factor
                PushArrayCell(indiceHandle,1.0); // visibility movement factor
                PushArrayCell(indiceHandle,1.0); // force speed?
                PushArrayCell(indiceHandle,1.0); // force gravity?
                PushArrayCell(indiceHandle,visibility); // force visibility?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(player,temp);
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
    CreateNative("SetMaxSpeed",Native_SetMaxSpeed);
    CreateNative("SetMinGravity",Native_SetMinGravity);
    CreateNative("SetMinVisibility",Native_SetMinVisibility);
    CreateNative("SetOverrideSpeed",Native_SetOverrideSpeed);
    CreateNative("SetOverrideGravity",Native_SetOverrideGravity);
    CreateNative("SetOverrideVisible",Native_SetOverrideVisible);
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
