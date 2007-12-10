/*
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: natives.inc
 * Description: All the natives that keep us from having to make a C++ extension,
 *              I <3 SourceMod :) (Note: Forwards are handled here too.)
 * Author(s): Anthony Iacono  
 */

// Handles
new Handle:g_OnWar3PlayerAuthedHandle;
new Handle:g_OnUltimateCommandHandle;
new Handle:g_OnItemPurchaseHandle;
new Handle:g_OnWar3PluginReadyHandle;

public Native_War3_CreateRace(Handle:plugin,numParams)
{
    if(numParams==12)
    {
        decl String:name[64],String:short[16],String:switchmessage_instant[192],String:switchmessage_dead[192],String:skill1[64],String:skill1_desc[192],String:skill2[64],String:skill2_desc[192],String:skill3[64],String:skill3_desc[192],String:ult[64],String:ult_desc[192];
        GetNativeString(1,name,63);
        GetNativeString(2,short,15);
        GetNativeString(3,switchmessage_instant,191);
        GetNativeString(4,switchmessage_dead,191);
        GetNativeString(5,skill1,63);
        GetNativeString(6,skill1_desc,191);
        GetNativeString(7,skill2,63);
        GetNativeString(8,skill2_desc,191);
        GetNativeString(9,skill3,63);
        GetNativeString(10,skill3_desc,191);
        GetNativeString(11,ult,63);
        GetNativeString(12,ult_desc,191);
        new Handle:race=CreateRace(name,short,switchmessage_instant,switchmessage_dead,skill1,skill1_desc,skill2,skill2_desc,skill3,skill3_desc,ult,ult_desc);
        PushArrayCell(arrayRaces,race);
        if(DBIDB)
        {
            decl String:buffer[32]="";
            new Handle:raceHandle=Race(RACE_COUNT-1);
            GetArrayString(raceHandle,1,short,15);
            Format(buffer,31,"%s_xp",short);
            CreateIfColumnDoesntExist(DBIDB,buffer,"varchar(30)");
            Format(buffer,31,"%s_level",short);
            CreateIfColumnDoesntExist(DBIDB,buffer,"varchar(30)");
            for(new y=0;y<SKILL_COUNT;y++)
            {
                Format(buffer,31,"%s_skilllevel_%d",short,y);
                CreateIfColumnDoesntExist(DBIDB,buffer,"varchar(30)");
            }
        }
        return GetArraySize(arrayRaces)-1;
    }
    return -1;
}

public Native_War3_CreateShopItem(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        decl String:name[64],String:desc[256],String:cost[4];
        GetNativeString(1,name,63);
        GetNativeString(2,desc,255);
        GetNativeString(3,cost,3);
        new Handle:item=CreateShopItem(name,desc,cost);
        PushArrayCell(shopVector,item);
        return GetArraySize(shopVector)-1;
    }
    return -1;
}

public Native_War3_GetWar3Player(Handle:plugin,numParams)
{
    if(numParams==1)
        return GetClientVectorPosition(GetNativeCell(1));
    return -1;
}

public Native_War3_GetRace(Handle:plugin,numParams)
{
    if(numParams==1)
    {
        new war3player=GetNativeCell(1);
        if(war3player!=-1)
            return GetRace(war3player);
    }
    return -1;
}

public Native_War3_GetLevel(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new race=GetNativeCell(2);
        if(war3player!=-1&&race!=-1)
            return GetLevel(war3player,race);
    }
    return -1;
}

public Native_War3_GetSkillLevel(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new war3player=GetNativeCell(1);
        new race=GetNativeCell(2);
        new skill=GetNativeCell(3);
        if(war3player!=-1&&race!=-1&&skill!=-1)
            return GetSkillLevel(war3player,race,skill);
    }
    return -1;
}

public Native_War3_GetXP(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new race=GetNativeCell(2);
        if(war3player!=-1&&race!=-1)
            return GetXP(war3player,race);
    }
    return -1;
}

public Native_War3_SetXP(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new war3player=GetNativeCell(1);
        new race=GetNativeCell(2);
        new newxp=GetNativeCell(3);
        new Handle:player=GetArrayCell(arrayPlayers,war3player);
        if(war3player!=-1&&race!=-1&&newxp!=-1)
        {
            SetXP(war3player,race,newxp);
            DoLevelCheck(GetArrayCell(player,0),war3player);
        }
    }
}

public Native_War3_GetOwnsItem(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new item=GetNativeCell(2);
        if(war3player!=-1&&item!=-1)
            return GetOwnsItem(war3player,item);
    }
    return -1;
}

public Native_War3_SetOwnsItem(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new war3player=GetNativeCell(1);
        new item=GetNativeCell(2);
        new owns=GetNativeCell(3);
        if(war3player!=-1&&item!=-1)
            SetOwnsItem(war3player,item,owns);
    }
}

public Native_War3_GetImmunity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new immunity=GetNativeCell(2);
        if(war3player!=-1&&immunity!=-1)
            return GetImmunity(war3player,immunity);
    }
    return -1;
}

public Native_War3_SetImmunity(Handle:plugin,numParams)
{
    if(numParams==3)
    {
        new war3player=GetNativeCell(1);
        new immunity=GetNativeCell(2);
        new imm_state=GetNativeCell(3);
        if(war3player!=-1&&immunity!=-1&&imm_state!=-1)
            SetImmunity(war3player,immunity,imm_state);
    }
}

public Native_War3_CreateHelpCommand(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        decl String:name[64];
        GetNativeString(1,name,63);
        decl String:desc[256];
        GetNativeString(2,desc,255);
        NewHelpCommand(name,desc);
    }
}

public Native_War3_SetMaxSpeed(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        if(war3player!=-1&&speed>0)
        {
            new Handle:temp=GetPropertyInfo(war3player);
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
                PushArrayCell(indiceHandle,0.0); // force speed?
                PushArrayCell(indiceHandle,0.0); // force gravity?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(war3player,temp);
        }
    }
}

public Native_War3_SetMinGravity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new Float:gravity=GetNativeCell(2);
        if(war3player!=-1&&gravity>0)
        {
            new Handle:temp=GetPropertyInfo(war3player);
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
                PushArrayCell(indiceHandle,0.0); // force speed?
                PushArrayCell(indiceHandle,0.0); // force gravity?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(war3player,temp);
        }
    }
}

public Native_War3_SetOverrideSpeed(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new Float:speed=GetNativeCell(2);
        if(war3player!=-1)
        {
            new Handle:temp=GetPropertyInfo(war3player);
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
                SetArrayCell(indiceHandle,3,speed);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,1.0); // maxspeed speed
                PushArrayCell(indiceHandle,1.0); // mingravity gravity
                PushArrayCell(indiceHandle,speed); // force speed?
                PushArrayCell(indiceHandle,0.0); // force gravity?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(war3player,temp);
        }
    }
}

public Native_War3_SetOverrideGravity(Handle:plugin,numParams)
{
    if(numParams==2)
    {
        new war3player=GetNativeCell(1);
        new Float:gravity=GetNativeCell(2);
        if(war3player!=-1)
        {
            new Handle:temp=GetPropertyInfo(war3player);
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
                SetArrayCell(indiceHandle,4,gravity);
                SetArrayCell(temp,indice,indiceHandle);
            }
            else
            {
                // create a new entry
                indiceHandle=CreateArray();
                PushArrayCell(indiceHandle,plugin); // plugin handle
                PushArrayCell(indiceHandle,1.0); // maxspeed speed
                PushArrayCell(indiceHandle,1.0); // mingravity gravity
                PushArrayCell(indiceHandle,0.0); // force speed?
                PushArrayCell(indiceHandle,gravity); // force gravity?
                PushArrayCell(temp,indiceHandle); // insert into the property info
            }
            SetPropertyInfo(war3player,temp);
        }
    }
}

public bool:War3Source_InitNatives()
{
    CreateNative("War3_CreateRace",Native_War3_CreateRace);
    CreateNative("War3_CreateShopItem",Native_War3_CreateShopItem);
    CreateNative("War3_CreateHelpCommand",Native_War3_CreateHelpCommand);
    CreateNative("War3_GetWar3Player",Native_War3_GetWar3Player);
    CreateNative("War3_GetRace",Native_War3_GetRace);
    CreateNative("War3_GetLevel",Native_War3_GetLevel);
    CreateNative("War3_GetSkillLevel",Native_War3_GetSkillLevel);
    CreateNative("War3_GetXP",Native_War3_GetXP);
    CreateNative("War3_SetXP",Native_War3_SetXP);
    CreateNative("War3_GetOwnsItem",Native_War3_GetOwnsItem);
    CreateNative("War3_SetOwnsItem",Native_War3_SetOwnsItem);
    CreateNative("War3_GetImmunity",Native_War3_GetImmunity);
    CreateNative("War3_SetImmunity",Native_War3_SetImmunity);
    CreateNative("War3_SetMaxSpeed",Native_War3_SetMaxSpeed);
    CreateNative("War3_SetMinGravity",Native_War3_SetMinGravity);
    CreateNative("War3_SetOverrideSpeed",Native_War3_SetOverrideSpeed);
    CreateNative("War3_SetOverrideGravity",Native_War3_SetOverrideGravity);
    return true;
}

public bool:War3Source_InitForwards()
{
    g_OnWar3PlayerAuthedHandle=CreateGlobalForward("OnWar3PlayerAuthed",ET_Ignore,Param_Cell,Param_Cell);
    g_OnUltimateCommandHandle=CreateGlobalForward("OnUltimateCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnWar3PluginReadyHandle=CreateGlobalForward("OnWar3PluginReady",ET_Ignore);
    g_OnRaceSelectedHandle=CreateGlobalForward("OnRaceSelected",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnSkillLevelChangedHandle=CreateGlobalForward("OnSkillLevelChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    g_OnItemPurchaseHandle=CreateGlobalForward("OnItemPurchase",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    return true;
}