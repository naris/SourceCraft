/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "War3Source/War3Source_Interface"
#include <sdktools>

// Defines
#define MAX_PLAYERS 64
#define IS_ALIVE !GetLifestate
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // Actually red for DOD

#define ITEM_ANKH             0 // Ankh of Reincarnation - Retrieve Equipment after death -- CStrike
#define ITEM_BOOTS            1 // Boots of Speed - Move Fastwer
#define ITEM_CLAWS            2 // Claws of Attack - Extra Damage
#define ITEM_CLOAK            3 // Cloak of Shadows - Invisibility
#define ITEM_MASK             4 // Mask of Death - Recieve Health for Hits
#define ITEM_NECKLACE         5 // Necklace of Immunity - Immune to Untimates
#define ITEM_ORB              6 // Orb of Frost - Slow Enemy
#define ITEM_PERIAPT          7 // Periapt of Health - Get Extra Health when Purchased
#define ITEM_TOME             8 // Tome of Experience - Get Extra Experience when Purchased
#define ITEM_SCROLL           9 // Scroll of Respawning - Respawn after death.
#define ITEM_SOCK            10 // Sock of the Feather - Jump Higher
#define ITEM_GLOVES          11 // Flaming Gloves of Warmth - Given HE Grenades over time -- CStrike
#define ITEM_RING            12 // Ring of Regeneration + 1 - Given extra health over time
#define ITEM_MOLE            13 // Mole - Respawn in enemies spawn with cloak.
#define ITEM_MOLE_PROTECTION 14 // Mole Protection - Reduce damage from a Mole.

// War3Source stuff
new shopItem[15]; // The ID we are assigned to
new lifestateOffset;
new healthOffset[MAX_PLAYERS+1];
new curWepOffset;
new myWepsOffset;
new colorOffset;
new renderModeOffset;
new moveparentOffset;
new ammotypeOffset;
new originOffset;
new Handle:vecPlayerWeapons[MAX_PLAYERS+1];
new bool:usedPeriapt[MAX_PLAYERS+1];
new bool:isMole[MAX_PLAYERS+1];

// OmG hAx!!! :] See, I have a sense of humor.
new Handle:hGameConf;
new Handle:hRoundRespawn;
new Handle:hUTILRemove;
new Handle:hGiveNamedItem;
new Handle:hWeaponDrop;
new Handle:hGiveAmmo;
new Handle:hSetModel;

public Plugin:myinfo = 
{
    name = "War3Source - Shopitems",
    author = "PimpinJuice",
    description = "The shop items that come with War3Source.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_hurt",PlayerHurtEvent);
    CreateTimer(1.0,TrackWeapons,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(1.0,ShadowsTrack,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(20.0,Gloves,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(2.0,Regeneration,INVALID_HANDLE,TIMER_REPEAT);
}

public OnWar3PluginReady()
{
    shopItem[ITEM_ANKH]=War3_CreateShopItem("Ankh of Reincarnation","If you die you will retrieve your equipment the following round.","4");
    shopItem[ITEM_BOOTS]=War3_CreateShopItem("Boots of Speed","Allows you to move faster.","7");
    shopItem[2]=War3_CreateShopItem("Claws of Attack","An additional 8 hp will be removed from the enemy on every successful attack.","3");
    shopItem[3]=War3_CreateShopItem("Cloak of Shadows","Makes you partially invisible, invisibility is increased when holding the knife.","2");
    shopItem[4]=War3_CreateShopItem("Mask of Death","You will receive health for every hit on the enemy.","5");
    shopItem[5]=War3_CreateShopItem("Necklace of Immunity","You will be immune to enemy ultimates.","2");
    shopItem[6]=War3_CreateShopItem("Orb of Frost","Slows your enemy down when you hit him.","5");
    shopItem[7]=War3_CreateShopItem("Periapt of Health","Receive extra health. (Note: CanScroll of Respawning\nonly be purchased once on death\nand once on spawn, so you can get 2 per\nround.","3");
    shopItem[8]=War3_CreateShopItem("Tome of Experience","Automatically gain experience, this item is used on purchase.","10");
    shopItem[9]=War3_CreateShopItem("Scroll of Respawning","You will respawn after death.","15");
    shopItem[10]=War3_CreateShopItem("Sock of the Feather","You will be able to jump higher.","4");
    shopItem[11]=War3_CreateShopItem("Flaming Gloves of Warmth","You will be given a high explosive grenade every 20 seconds.","5");
    shopItem[12]=War3_CreateShopItem("Ring of Regeneration + 1","Gives 1 health every 2 seconds, won't excede 100 HP.","3");
    shopItem[13]=War3_CreateShopItem("Mole","Tunnel to the enemies spawn\nat the beginning of the round\nand disguise as the enemy to\nget a quick couple of kills.","40");
    shopItem[14]=War3_CreateShopItem("Mole Protection","Deflect some damage from the mole\nto give yourself a fighting chance.","5");
    lifestateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
    myWepsOffset=FindSendPropOffs("CAI_BaseNPC","m_hMyWeapons");
    curWepOffset=FindSendPropOffs("CAI_BaseNPC","m_hActiveWeapon");
    colorOffset=FindSendPropOffs("CAI_BaseNPC","m_clrRender");
    renderModeOffset=FindSendPropOffs("CBaseAnimating","m_nRenderMode");
    moveparentOffset=FindSendPropOffs("CBaseEntity","m_hOwnerEntity");
    ammotypeOffset=FindSendPropOffs("CBaseCombatWeapon","m_iPrimaryAmmoType");
    originOffset=FindSendPropOffs("CBaseEntity","m_vecOrigin");
    LoadSDKToolStuff();
}

public LoadSDKToolStuff()
{
    hGameConf=LoadGameConfigFile("plugin.war3source");
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"RoundRespawn");
    hRoundRespawn=EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"GiveNamedItem");
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity,SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_String,SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
    hGiveNamedItem=EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Static);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"UTIL_Remove");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
    hUTILRemove=EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"Weapon_Drop");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_Vector,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
    PrepSDKCall_AddParameter(SDKType_Vector,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
    hWeaponDrop=EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"GiveAmmo");
    PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
    hGiveAmmo=EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Static);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"UTIL_SetModel");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_String,SDKPass_Pointer);
    hSetModel=EndPrepSDKCall();
}

public AuthTimer(Float:delay,index,Timer:func)
{
    new Handle:temp=CreateArray(ByteCountToCells(64));
    decl String:auth[64];
    GetClientAuthString(index,auth,63);
    PushArrayString(temp,auth);
    CreateTimer(delay,func,temp);
}

public OnWar3PlayerAuthed(client,war3player)
{
    healthOffset[client]=FindDataMapOffs(client,"m_iHealth");
    vecPlayerWeapons[client]=CreateArray(ByteCountToCells(128));
}

public OnItemPurchase(client,war3player,item)
{
    if(item==shopItem[ITEM_BOOTS]&&IS_ALIVE(client)) // Boots of Speed
        War3_SetMaxSpeed(war3player,1.4);
    if(item==shopItem[5])                            // Necklace of Immunity
        War3_SetImmunity(war3player,Immunity_Ultimates,true);
    if(item==shopItem[7]&&IS_ALIVE(client))          // Periapt of Health
    {
        usedPeriapt[client]=true;
        SetHealth(client,GetClientHealth(client)+50);
    }
    if(item==shopItem[8])                            // Tome of Experience
    {
        War3_SetXP(war3player,War3_GetRace(war3player),War3_GetXP(war3player,War3_GetRace(war3player))+100);
        War3_SetOwnsItem(war3player,shopItem[8],false);
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou gained 100XP.",COLOR_GREEN,COLOR_DEFAULT);
    }
    if(item==shopItem[9]&&!IS_ALIVE(client))         // Scroll of Respawning 
    {
        RespawnPlayer(client);
        War3_SetOwnsItem(war3player,shopItem[9],false);
    }
    if(item==shopItem[10])                           // Sock of the Feather
        War3_SetMinGravity(war3player,0.3);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(client);
    if(war3player>-1)
    {
        if(War3_GetOwnsItem(war3player,shopItem[1]))
            War3_SetMaxSpeed(war3player,1.4);
        if(War3_GetOwnsItem(war3player,shopItem[0]))
        {
            new Handle:temp=CreateArray(ByteCountToCells(128));
            new size=GetArraySize(vecPlayerWeapons[client]);
            decl String:wepName[128];
            decl String:auth[64];
            GetClientAuthString(client,auth,63);
            PushArrayString(temp,auth);
            for(new x=0;x<size;x++)
            {
                GetArrayString(vecPlayerWeapons[client],x,wepName,127);
                PushArrayString(temp,wepName);
            }
            CreateTimer(0.2,War3Source_Ankh,temp);
            War3_SetOwnsItem(war3player,shopItem[0],false);
        }
        if(War3_GetOwnsItem(war3player,shopItem[7])&&!usedPeriapt[client])
        {
            SetHealth(client,GetClientHealth(client)+50);
            usedPeriapt[client]=false;
        }
        if(War3_GetOwnsItem(war3player,shopItem[10]))
            War3_SetMinGravity(war3player,0.3);
        if(War3_GetOwnsItem(war3player,shopItem[13]))
        {
            // We need to check to use mole, or did we JUST use it?
            if(isMole[client])
            {
                // we already used it, take it away
                isMole[client]=false;
                War3_SetOwnsItem(war3player,shopItem[13],false);
            }
            else
                AuthTimer(1.0,client,DoMole);
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(client);
    if(war3player>-1)
    {
        if(War3_GetOwnsItem(war3player,shopItem[1]))
            War3_SetOwnsItem(war3player,shopItem[1],false);
        if(War3_GetOwnsItem(war3player,shopItem[2]))
            War3_SetOwnsItem(war3player,shopItem[2],false);
        if(War3_GetOwnsItem(war3player,shopItem[3]))
        {
            new count=GetEntityCount();
            for(new y=64;y<count;y++)
            {
                if(IsValidEdict(y))
                {
                    if(GetEntDataEnt(y,moveparentOffset)==client)
                        SetRenderColor(y,255,255,255,255);
                }
            }
            SetRenderColor(client,255,255,255,255);
            War3_SetOwnsItem(war3player,shopItem[3],false);
        }
        if(War3_GetOwnsItem(war3player,shopItem[4]))
            War3_SetOwnsItem(war3player,shopItem[4],false);
        if(War3_GetOwnsItem(war3player,shopItem[5]))
        {
            War3_SetOwnsItem(war3player,shopItem[5],false);
            War3_SetImmunity(war3player,Immunity_Ultimates,false);
        }
        if(War3_GetOwnsItem(war3player,shopItem[6]))
            War3_SetOwnsItem(war3player,shopItem[6],false);
        if(War3_GetOwnsItem(war3player,shopItem[7]))
        {
            usedPeriapt[client]=false;
            War3_SetOwnsItem(war3player,shopItem[7],false);
        }
        if(War3_GetOwnsItem(war3player,shopItem[9]))
        {
            War3_SetOwnsItem(war3player,shopItem[9],false);
            AuthTimer(1.0,client,RespawnPlayerHandle);
        }
        if(War3_GetOwnsItem(war3player,shopItem[10]))
            War3_SetOwnsItem(war3player,shopItem[10],false);
        if(War3_GetOwnsItem(war3player,shopItem[11]))
            War3_SetOwnsItem(war3player,shopItem[11],false);
        if(War3_GetOwnsItem(war3player,shopItem[12]))
            War3_SetOwnsItem(war3player,shopItem[12],false);
        if(War3_GetOwnsItem(war3player,shopItem[13]))
        {
            // We need to check to use mole, or did we JUST use it?
            if(isMole[client])
            {
                // we already used it, take it away
                isMole[client]=false;
                War3_SetOwnsItem(war3player,shopItem[13],false);
            }
        }
        if(War3_GetOwnsItem(war3player,shopItem[14]))
            War3_SetOwnsItem(war3player,shopItem[14],false);
        War3_SetMaxSpeed(war3player,1.0);
        War3_SetMinGravity(war3player,1.0);
    }
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new attacker_userid=GetEventInt(event,"attacker");
    if(userid&&attacker_userid&&userid!=attacker_userid)
    {
        new index=GetClientOfUserId(userid);
        new attacker_index=GetClientOfUserId(attacker_userid);
        new war3player=War3_GetWar3Player(index);
        new war3player_attacker=War3_GetWar3Player(attacker_index);
        if(war3player!=-1&&war3player_attacker!=-1)
        {
            if(!War3_GetImmunity(war3player,Immunity_ShopItems))
            {
                if(War3_GetOwnsItem(war3player_attacker,shopItem[2])&&!War3_GetImmunity(war3player,Immunity_HealthTake))
                {
                    // Claws
                    new newhealth=GetClientHealth(index)-8;
                    if(newhealth<0) newhealth=0;
                    SetHealth(index,newhealth);
                }
                if(War3_GetOwnsItem(war3player_attacker,shopItem[4]))
                {
                    // Mask
                    new newhealth=GetClientHealth(attacker_index)+2;
                    SetHealth(attacker_index,newhealth);
                }
                if(War3_GetOwnsItem(war3player_attacker,shopItem[6]))
                {
                    War3_SetOverrideSpeed(war3player,0.5);
                    AuthTimer(5.0,index,RestoreSpeed);
                }
                if(War3_GetOwnsItem(war3player,shopItem[14]))
                {
                    if(isMole[attacker_index])
                    {
                        new h1=GetEventInt(event,"health")+GetEventInt(event,"dmg_health");
                        new h2=GetClientHealth(index);
                        if(h2<h1)
                            SetHealth(index,(h1+h2)/2);
                        if(!h2)
                            SetHealth(index,0); // They should really be dead.
                    }
                }
            }
        }
    }
}

// Item specific
public Action:RestoreSpeed(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
    {
        new war3player=War3_GetWar3Player(client);
        if(war3player>-1)
            War3_SetOverrideSpeed(war3player,0.0);
    }
    ClearArray(temp);
}

public Action:Regeneration(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new x=1;x<=maxplayers;x++)
    {
        if(IsClientInGame(x)&&IS_ALIVE(x))
        {
            new war3player=War3_GetWar3Player(x);
            if(war3player>=0&&War3_GetOwnsItem(war3player,shopItem[12]))
            {
                new newhp=GetHealth(x)+1;
                if(newhp<=100)
                    SetHealth(x,newhp);
            }
        }
    }
}

public Action:Gloves(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new x=1;x<=maxplayers;x++)
    {
        if(IsClientInGame(x)&&IS_ALIVE(x))
        {
            new war3player=War3_GetWar3Player(x);
            if(war3player>=0&&War3_GetOwnsItem(war3player,shopItem[11]))
                GiveItem(x,"weapon_hegrenade");
        }
    }
}

public Action:ShadowsTrack(Handle:timer)
{
    new maxplayers=GetMaxClients();
    decl String:wepName[128];
    new count=GetEntityCount();
    for(new x=1;x<=maxplayers;x++)
    {
        if(IsClientInGame(x)&&IS_ALIVE(x))
        {
            new war3player=War3_GetWar3Player(x);
            if(war3player>=0&&War3_GetOwnsItem(war3player,shopItem[3]))
            {
                new visibility=160;
                new weaponent=GetEntDataEnt(x,curWepOffset);
                if(weaponent&&IsValidEdict(weaponent)&&weaponent<count)
                {
                    GetEdictClassname(weaponent,wepName,127);
                    if(StrEqual(wepName,"weapon_knife"))
                        visibility=90;
                }
                for(new y=64;y<count;y++)
                {
                    if(IsValidEdict(y))
                    {
                        if(GetEntDataEnt(y,moveparentOffset)==x)
                            SetRenderColor(y,255,255,255,visibility);
                    }
                }
                SetRenderColor(x,255,255,255,visibility);
            }
        }
    }
}

public Action:TrackWeapons(Handle:timer)
{
    new maxplayers=GetMaxClients();
    decl String:wepName[128];
    for(new x=1;x<=maxplayers;x++)
    {
        if(IsClientInGame(x)&&IS_ALIVE(x))
        {
            ClearArray(vecPlayerWeapons[x]);
            new iterOffset=myWepsOffset;
            for(new y=0;y<48;y++)
            {
                new wepEnt=GetEntDataEnt(x,iterOffset);
                if(wepEnt>0&&IsValidEdict(wepEnt))
                {
                    GetEdictClassname(wepEnt,wepName,127);
                    if(!StrEqual(wepName,"weapon_c4"))
                        PushArrayString(vecPlayerWeapons[x],wepName);
                }
                iterOffset+=4;
            }
        }
    }
}

public Action:War3Source_Ankh(Handle:timer,any:temp)
{
    decl String:wepName[128];
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
    {
        new Float:playerPos[3];
        GetClientAbsOrigin(client,playerPos);
        playerPos[2]+=5.0;
        new iter=myWepsOffset;
        for(new x=0;x<48;x++)
        {
            new ent=GetEntDataEnt(client,iter);
            if(ent>0&&IsValidEdict(ent))
            {
                GetEdictClassname(ent,wepName,127);
                if(!StrEqual(wepName,"weapon_c4"))
                {
                    DropWeapon(client,ent);
                    RemoveEntity(ent);
                }
            }
            iter+=4;
        }
        for(new x=1;x<GetArraySize(temp);x++)
        {
            GetArrayString(temp,x,wepName,127);
            new ent=GiveItem(client,wepName);
            new ammotype=GetAmmoType(ent);
            if(ammotype!=-1)
                GiveAmmo(client,ammotype,1000,true);
        }
        ClearArray(temp);
    }
}

public Action:DoMole(Handle:timer,Handle:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
    {
        new team=GetClientTeam(client);
        new Float:teleLoc[3];
        new searchteam=(team==2)?3:2;
        new Handle:playerList=PlayersOnTeam(searchteam); // <3 SHVector.
        if(GetArraySize(playerList)>0) // are there any enemies?
        {
            new lucky_player_iter=GetRandomInt(0,GetArraySize(playerList)-1); // who gets their position mooched off them?
            new lucky_player=GetArrayCell(playerList,lucky_player_iter);
            EntityOrigin(lucky_player,teleLoc);
            teleLoc[0]+=40.0;
            SetEntityOrigin(client,teleLoc);
            isMole[client]=true;
            (team==2)?SetModel(client,"models/player/ct_urban.mdl"):SetModel(client,"models/player/t_phoenix.mdl");
        }
        else
            War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cCould not find a place to mole to, there are no enemies!",COLOR_GREEN,COLOR_DEFAULT);
    }
    ClearArray(temp);
}

// Non-specific stuff
public SetHealth(entity,amount)
{
    SetEntData(entity,healthOffset[entity],amount,1);
}

public GetHealth(entity)
{
    return GetEntData(entity,healthOffset[entity],1);
}

public GetLifestate(client)
{
    return GetEntData(client,lifestateOffset,1);
}

stock RemoveEntity(entity)
{
    SDKCall(hUTILRemove,entity);
}

stock EntityOrigin(entity,Float:origin[3])
{
    GetEntDataVector(entity,originOffset,origin);
}

stock SetEntityOrigin(entity,Float:origin[3])
{
    SetEntDataVector(entity,originOffset,origin);
}

public GiveItem(client,const String:item[])
{
    return SDKCall(hGiveNamedItem,client,item,0);
}

public DropWeapon(client,weapon)
{
    SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,NULL_VECTOR);
}

public RespawnPlayer(client)
{
    SDKCall(hRoundRespawn,client);
}

public Action:RespawnPlayerHandle(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
        RespawnPlayer(client);
    ClearArray(temp);
}

stock PlayerOfAuth(const String:auth[])
{
    new max=GetMaxClients();
    decl String:authStr[64];
    for(new x=1;x<=max;x++)
    {
        if(IsClientConnected(x))
        {
            GetClientAuthString(x,authStr,63);
            if(StrEqual(auth,authStr))
                return x;
        }
    }
    return 0;
}

stock SetModel(entity,const String:model[])
{
    SDKCall(hSetModel,entity,model);
}

stock GetAmmoType(weapon)
{
    return GetEntData(weapon,ammotypeOffset);
}

stock GiveAmmo(client,ammotype,amount,bool:suppress)
{
    SDKCall(hGiveAmmo,client,amount,ammotype,suppress);
}

stock Float:DistanceBetween(Float:a[3],Float:b[3])
{
    return SquareRoot((b[0]-a[0])*(b[0]-a[0])+(b[1]-a[1])*(b[1]-a[1])+(b[2]-a[2])*(b[2]-a[2]));
}

stock Handle:PlayersOnTeam(team)
{
    new count=GetMaxClients();
    new Handle:temp=CreateArray();
    for(new x=1;x<=count;x++)
    {
        if(IsClientInGame(x)&&GetClientTeam(x)==team)
            PushArrayCell(temp,x);
    }
    return temp;
}

public SetRenderColor(client,r,g,b,a)
{
	if(colorOffset==-1)
        return;
	SetEntData(client,colorOffset,r,1,true);
	SetEntData(client,colorOffset+1,g,1,true);
	SetEntData(client,colorOffset+2,b,1,true);
	SetEntData(client,colorOffset+3,a,1,true);
	if(renderModeOffset==-1)
        return;
	SetEntData(client,renderModeOffset,3,1,true);
}

stock War3Source_ChatMessage(target,color,const String:szMsg[],any:...)
{
    if(strlen(szMsg)>191)
    {
        LogError("Disallow string len(%d)>191",strlen(szMsg));
        return;
    }
    decl String:buffer[192];
    VFormat(buffer,sizeof(buffer),szMsg,4);
    Format(buffer,191,"%s\n",buffer);
    new Handle:hBf;
    if(target==0)
        hBf=StartMessageAll("SayText");
    else
        hBf=StartMessageOne("SayText",target);
    if(hBf!=INVALID_HANDLE)
    {
        BfWriteByte(hBf, 0); 
        BfWriteString(hBf, buffer);
        EndMessage();
    }
}
