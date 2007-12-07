/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 * Modifications by: Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "War3Source/War3Source_Interface"
#include <sdktools>

// Defines
#define IS_ALIVE !GetLifeState
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // Actually red for DOD

#define ITEM_ANKH             0 // Ankh of Reincarnation - Retrieve Equipment after death
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
#define ITEM_GLOVES          11 // Flaming Gloves of Warmth - Given HE Grenades over time
#define ITEM_RING            12 // Ring of Regeneration + 1 - Given extra health over time
#define ITEM_GOGGLES         12 // The Goggles - They do nothing!
#define ITEM_MOLE            13 // Mole - Respawn in enemies spawn with cloak.
#define ITEM_MOLE_PROTECTION 14 // Mole Protection - Reduce damage from a Mole.

// War3Source stuff

new lifestateOffset  = 0;
new curWepOffset     = 0;
new myWepsOffset     = 0;
new colorOffset      = 0;
new renderModeOffset = 0;
new ownerOffset      = 0;
new ammotypeOffset   = 0;
new originOffset     = 0;
new clipOffset       = 0;
new clip2Offset      = 0;
new ammoOffset       = 0;
new ammo2Offset      = 0;
new metalOffset      = 0;

new healthOffset[MAXPLAYERS+1]            = { 0, ... };
new maxHealthOffset[MAXPLAYERS+1]         = { 0, ... };

new Handle:vecPlayerWeapons[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new bool:usedPeriapt[MAXPLAYERS+1]        = { false, ... };
new bool:isMole[MAXPLAYERS+1]             = { false, ... };
new maxHealth[MAXPLAYERS+1]               = { 100, ... };

enum Mod { undetected, tf2, cstrike, dod, hl2mp, insurgency, other };
new Mod:GameType = undetected;

new Handle:hGameConf      = INVALID_HANDLE;
new Handle:hRoundRespawn  = INVALID_HANDLE;
new Handle:hUTILRemove    = INVALID_HANDLE;
new Handle:hGiveNamedItem = INVALID_HANDLE;
new Handle:hWeaponDrop    = INVALID_HANDLE;
new Handle:hGiveAmmo      = INVALID_HANDLE;
new Handle:hSetModel      = INVALID_HANDLE;

new shopItem[15];

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
    new String:modname[30];
    GetGameFolderName(modname, sizeof(modname));
    if (StrEqual(modname,"cstrike",false))
        GameType=cstrike;
    else if (StrEqual(modname,"tf",false)) 
        GameType=tf2;
    else if (StrEqual(modname,"dod",false)) 
        GameType=dod;
    else if (StrEqual(modname,"hl2mp",false)) 
        GameType=hl2mp;
    else if (StrEqual(modname,"Insurgency",false)) 
        GameType=insurgency;
    else
        GameType=other;

    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_hurt",PlayerHurtEvent);

    CreateTimer(1.0,ShadowsTrack,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(20.0,Gloves,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(2.0,Regeneration,INVALID_HANDLE,TIMER_REPEAT);

    if (GameType == cstrike)
        CreateTimer(1.0,TrackWeapons,INVALID_HANDLE,TIMER_REPEAT);
}

public OnWar3PluginReady()
{
    shopItem[ITEM_BOOTS]=War3_CreateShopItem("Boots of Speed","Allows you to move faster.","7");
    shopItem[ITEM_CLAWS]=War3_CreateShopItem("Claws of Attack","An additional 8 hp will be removed from the enemy on every successful attack.","3");
    shopItem[ITEM_MASK]=War3_CreateShopItem("Mask of Death","You will receive health for every hit on the enemy.","5");
    shopItem[ITEM_NECKLACE]=War3_CreateShopItem("Necklace of Immunity","You will be immune to enemy ultimates.","2");
    shopItem[ITEM_ORB]=War3_CreateShopItem("Orb of Frost","Slows your enemy down when you hit him.","5");
    shopItem[ITEM_PERIAPT]=War3_CreateShopItem("Periapt of Health","Receive extra health. (Note: CanScroll of Respawning\nonly be purchased once on death\nand once on spawn, so you can get 2 per\nround.","3");
    shopItem[ITEM_TOME]=War3_CreateShopItem("Tome of Experience","Automatically gain experience, this item is used on purchase.","10");
    shopItem[ITEM_SOCK]=War3_CreateShopItem("Sock of the Feather","You will be able to jump higher.","4");
    shopItem[ITEM_RING]=War3_CreateShopItem("Ring of Regeneration + 1","Gives 1 health every 2 seconds, won't excede 100 HP.","3");
    shopItem[ITEM_MOLE]=War3_CreateShopItem("Mole","Tunnel to the enemies spawn\nat the beginning of the round\nand disguise as the enemy to\nget a quick couple of kills.","40");
    shopItem[ITEM_MOLE_PROTECTION]=War3_CreateShopItem("Mole Protection","Deflect some damage from the mole\nto give yourself a fighting chance.","5");

    if (GameType == cstrike)
    {
        shopItem[ITEM_ANKH]=War3_CreateShopItem("Ankh of Reincarnation","If you die you will retrieve your equipment the following round.","4");
        shopItem[ITEM_CLOAK]=War3_CreateShopItem("Cloak of Shadows","Makes you partially invisible, invisibility is increased when holding the knife.","2");
        shopItem[ITEM_SCROLL]=War3_CreateShopItem("Scroll of Respawning","You will respawn after death.","15");
        shopItem[ITEM_GLOVES]=War3_CreateShopItem("Flaming Gloves of Warmth","You will be given a high explosive grenade every 20 seconds.","5");
    }
    else
    {
        shopItem[ITEM_ANKH]=War3_CreateShopItem("Ankh of Reincarnation","If you die you will retrieve your shopitems the following round.","4");
        shopItem[ITEM_CLOAK]=War3_CreateShopItem("Cloak of Shadows","Makes you partially invisible, invisibility is increased when holding a melee weapon.","2");
        //shopItem[ITEM_SCROLL]=War3_CreateShopItem("Scroll of Respawning","You will respawn immediately after death?","15");
        shopItem[ITEM_GOGGLES]=War3_CreateShopItem("The Goggles","They do nothing!","15");
        shopItem[ITEM_GLOVES]=War3_CreateShopItem("Flaming Gloves of Warmth","You will be given extra ammo every 20 seconds.","5");
    }

    LoadSDKToolStuff();
}

public LoadSDKToolStuff()
{
    lifestateOffset  = FindSendPropOffs("CAI_BaseNPC",       "m_lifeState");
    myWepsOffset     = FindSendPropOffs("CAI_BaseNPC",       "m_hMyWeapons");
    curWepOffset     = FindSendPropOffs("CAI_BaseNPC",       "m_hActiveWeapon");
    colorOffset      = FindSendPropOffs("CAI_BaseNPC",       "m_clrRender");
    ownerOffset      = FindSendPropOffs("CBaseEntity",       "m_hOwnerEntity");
    originOffset     = FindSendPropOffs("CBaseEntity",       "m_vecOrigin");
    renderModeOffset = FindSendPropOffs("CBaseAnimating",    "m_nRenderMode");
    ammotypeOffset   = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
    clipOffset       = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
    clip2Offset      = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");

    if (GameType == tf2)
    {
        ammoOffset   = FindSendPropOffs("CTFPlayer",         "m_iAmmo");
        ammo2Offset  = ammoOffset  + 4;
        metalOffset  = ammo2Offset + 4;
    }
    else
    {
        ammoOffset   = FindSendPropOffs("CBasePlayer",       "m_iAmmo");
    }

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

    if (GameType == tf2)
    {
        maxHealthOffset[client]=FindDataMapOffs(client,"m_iMaxHealth");
        maxHealth[client] = GetMaxHealth(client);
    }
    else if (GameType == cstrike)
        vecPlayerWeapons[client]=CreateArray(ByteCountToCells(128));
}

public OnItemPurchase(client,war3player,item)
{
    if(item==shopItem[ITEM_BOOTS] && IS_ALIVE(client))              // Boots of Speed
        War3_SetMaxSpeed(war3player,1.4);
    else if(item==shopItem[ITEM_NECKLACE])                          // Necklace of Immunity
        War3_SetImmunity(war3player,Immunity_Ultimates,true);
    else if(item==shopItem[ITEM_PERIAPT] && IS_ALIVE(client))       // Periapt of Health
        UsePeriapt(client);
    else if(item==shopItem[ITEM_TOME])                              // Tome of Experience
    {
        War3_SetXP(war3player,War3_GetRace(war3player),War3_GetXP(war3player,War3_GetRace(war3player))+100);
        War3_SetOwnsItem(war3player,shopItem[8],false);
        War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou gained 100XP.",COLOR_GREEN,COLOR_DEFAULT);
    }
    else if(item==shopItem[ITEM_SCROLL] && !IS_ALIVE(client))       // Scroll of Respawning 
    {
        RespawnPlayer(client);
        War3_SetOwnsItem(war3player,shopItem[9],false);
    }
    else if(item==shopItem[ITEM_SOCK])                              // Sock of the Feather
        War3_SetMinGravity(war3player,0.3);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new war3player=War3_GetWar3Player(client);
    if(war3player>-1)
    {
        if(War3_GetOwnsItem(war3player,shopItem[ITEM_ANKH]))        // Ankh of Reincarnation
        {
            if (GameType == cstrike)
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
            }
            War3_SetOwnsItem(war3player,shopItem[ITEM_ANKH],false);
        }

        if(War3_GetOwnsItem(war3player,shopItem[ITEM_BOOTS]))  // Boots of Speed
            War3_SetMaxSpeed(war3player,1.4);

        if(War3_GetOwnsItem(war3player,shopItem[ITEM_PERIAPT]) && !usedPeriapt[client])    // Periapt of Health
            UsePeriapt(client);

        if(War3_GetOwnsItem(war3player,shopItem[ITEM_SOCK]))   // Sock of the Feather
            War3_SetMinGravity(war3player,0.3);

        if(War3_GetOwnsItem(war3player,shopItem[ITEM_MOLE]))   // Mole
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
        if (GameType == cstrike ||
            !War3_GetOwnsItem(war3player,shopItem[ITEM_ANKH]))
        {
            if(War3_GetOwnsItem(war3player,shopItem[ITEM_BOOTS]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_BOOTS],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_CLAWS]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_CLAWS],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_CLOAK]))
            {
                new count=GetEntityCount();
                for(new y=64;y<count;y++)
                {
                    if(IsValidEdict(y))
                    {
                        if(GetEntDataEnt(y,ownerOffset)==client)
                            SetRenderColor(y,255,255,255,255);
                    }
                }
                SetRenderColor(client,255,255,255,255);
                War3_SetOwnsItem(war3player,shopItem[3],false);
            }

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_MASK]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_MASK],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_NECKLACE]))
            {
                War3_SetOwnsItem(war3player,shopItem[ITEM_NECKLACE],false);
                War3_SetImmunity(war3player,Immunity_Ultimates,false);
            }

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_ORB]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_ORB],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_PERIAPT]))
            {
                War3_SetOwnsItem(war3player,shopItem[ITEM_PERIAPT],false);
            }

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_SCROLL]))
            {
                War3_SetOwnsItem(war3player,shopItem[ITEM_SCROLL],false);
                AuthTimer(1.0,client,RespawnPlayerHandle);
            }

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_SOCK]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_SOCK],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_GLOVES]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_GLOVES],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_GOGGLES]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_GOGGLES],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_RING]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_RING],false);

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_MOLE]))
            {
                // We need to check to use mole, or did we JUST use it?
                if(isMole[client])
                {
                    // we already used it, take it away
                    isMole[client]=false;
                    War3_SetOwnsItem(war3player,shopItem[ITEM_MOLE],false);
                }
            }

            if(War3_GetOwnsItem(war3player,shopItem[ITEM_MOLE_PROTECTION]))
                War3_SetOwnsItem(war3player,shopItem[ITEM_MOLE_PROTECTION],false);
        }

        War3_SetMaxSpeed(war3player,1.0);
        War3_SetMinGravity(war3player,1.0);

        // Reset MaxHealth back to normal
        if (usedPeriapt[client] && GameType == tf2)
            SetMaxHealth(client, maxHealth[client]);

        usedPeriapt[client]=false;
    }
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid          = GetEventInt(event,"userid");
    new attacker_userid = GetEventInt(event,"attacker");
    new assister_userid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
    if(userid && attacker_userid && userid != attacker_userid)
    {
        new index               = GetClientOfUserId(userid);
        new attacker_index      = GetClientOfUserId(attacker_userid);

        new war3player          = War3_GetWar3Player(index);
        new war3player_attacker = War3_GetWar3Player(attacker_index);

        new assister_index      = -1;
        new war3player_assister = -1;

        if (assister_userid != 0)
        {
            assister_index      = GetClientOfUserId(assister_userid);
            war3player_assister = War3_GetWar3Player(assister_index);
        }

        if(war3player !=-1 && war3player_attacker != -1)
        {
            if(!War3_GetImmunity(war3player,Immunity_ShopItems))
            {
                if (!War3_GetImmunity(war3player,Immunity_HealthTake))
                {
                    if (War3_GetOwnsItem(war3player_attacker,shopItem[ITEM_CLAWS]))
                    {
                        new newhealth=GetClientHealth(index)-8;
                        if(newhealth<0) newhealth=0;
                        SetHealth(index,newhealth);
                    }
                    if (War3_GetOwnsItem(war3player_assister,shopItem[ITEM_CLAWS]))
                    {
                        new newhealth=GetClientHealth(index)-8;
                        if(newhealth<0) newhealth=0;
                        SetHealth(index,newhealth);
                    }
                }

                if (War3_GetOwnsItem(war3player_attacker,shopItem[ITEM_MASK]))
                {
                    new newhealth=GetClientHealth(attacker_index)+2;
                    SetHealth(attacker_index,newhealth);
                }

                if (War3_GetOwnsItem(war3player_assister,shopItem[ITEM_MASK]))
                {
                    new newhealth=GetClientHealth(assister_index)+2;
                    SetHealth(assister_index,newhealth);
                }

                if (War3_GetOwnsItem(war3player_attacker,shopItem[ITEM_ORB]) ||
                    War3_GetOwnsItem(war3player_assister,shopItem[ITEM_ORB]))
                {
                    War3_SetOverrideSpeed(war3player,0.5);
                    AuthTimer(5.0,index,RestoreSpeed);
                }

                if (War3_GetOwnsItem(war3player,shopItem[ITEM_MOLE_PROTECTION]))
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
        if(IsClientInGame(x) && IS_ALIVE(x))
        {
            new war3player=War3_GetWar3Player(x);
            if(war3player>=0 && War3_GetOwnsItem(war3player,shopItem[ITEM_RING]))
            {
                new newhp=GetHealth(x)+1;
                new maxhp=(GameType == tf2) ? GetMaxHealth(x) : 100;
                if(newhp<=maxhp)
                    SetHealth(x,newhp);
            }
        }
    }
}

public Action:Gloves(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        //LogMessage("Glove] Checking %d\n", client);
        if(IsClientInGame(client) && IS_ALIVE(client))
        {
            new war3player=War3_GetWar3Player(client);
            if (war3player>=0) // && War3_GetOwnsItem(war3player,shopItem[ITEM_GLOVES]))
            {
                //LogMessage("Glove] Give something to %d\n", client);
                //War3Source_ChatMessage(client,COLOR_DEFAULT,"%c[War3Source] %cYou have been given ammo.",COLOR_GREEN,COLOR_DEFAULT);
                War3Source_ChatMessage(client,COLOR_DEFAULT,
                                       "%c[War3Source] %c clip1=%d,clip2=%d,ammo=%d,ammo2=%d,metal=%d",
                                       COLOR_GREEN,COLOR_DEFAULT, GetEntData(client, clipOffset, 4),
                                       GetEntData(client, clip2Offset, 4),
                                       GetEntData(client, ammoOffset, 4),
                                       GetEntData(client, ammo2Offset, 4),
                                       GetEntData(client, metalOffset, 4));
                if (GameType == cstrike)
                {
                    GiveItem(client,"weapon_hegrenade");
                }
                else if (GameType == tf2)
                {
                    new ammo = GetEntData(client, ammo2Offset, 4) + 5;
                    SetEntData(client, ammo2Offset, ammo, 4, true);

                    new metal = GetEntData(client, metalOffset, 4) + 5;
                    SetEntData(client, metalOffset, metal, 4, true);
                }
                else
                {
                    new ammoType  = -2;
                    new curWeapon = GetEntDataEnt(client, curWepOffset);
                    if (curWeapon > 0)
                    {
                        ammoType = GetAmmoType(curWeapon);
                        if (ammoType > 0)
                            GiveAmmo(client,ammoType,1000,true);
                        else
                            SetEntData(curWeapon, clipOffset, 5, 4, true);
                    }
                    LogMessage("Glove] Client=%d,curWeapon=%d,ammoType=%d\n", client, curWeapon, ammoType);
                    War3Source_ChatMessage(client,COLOR_DEFAULT,
                                           "%c[War3Source] %cYou have been given %d ammo for %d.",
                                           COLOR_GREEN,COLOR_DEFAULT, curWeapon, ammoType);
                }
            }
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
        if(IsClientInGame(x) && IS_ALIVE(x))
        {
            new war3player=War3_GetWar3Player(x);
            if(war3player>=0 && War3_GetOwnsItem(war3player,shopItem[ITEM_CLOAK]))
            {
                new visibility=140; // 160;
                new weaponent=GetEntDataEnt(x,curWepOffset);
                if(weaponent && IsValidEdict(weaponent) && weaponent<count)
                {
                    GetEdictClassname(weaponent,wepName,127);
                    if(GameType == cstrike && StrEqual(wepName,"weapon_knife"))
                    {
                        visibility=80; // 90;
                    }
                    else if(GameType == tf2 && (StrEqual(wepName,"tf_weapon_knife") ||
                                                StrEqual(wepName,"tf_weapon_shovel") ||
                                                StrEqual(wepName,"tf_weapon_wrench") ||
                                                StrEqual(wepName,"tf_weapon_bat") ||
                                                StrEqual(wepName,"tf_weapon_bonesaw") ||
                                                StrEqual(wepName,"tf_weapon_bottle") ||
                                                StrEqual(wepName,"tf_weapon_club") ||
                                                StrEqual(wepName,"tf_weapon_fireaxe") ||
                                                StrEqual(wepName,"tf_weapon_fists") ||
                                                StrEqual(wepName,"tf_weapon_builder") ||
                                                StrEqual(wepName,"tf_weapon_pda_engineer_build") ||
                                                StrEqual(wepName,"tf_weapon_pda_engineer_destroy") ||
                                                StrEqual(wepName,"tf_weapon_pda_spy")))
                    {
                        visibility=90;
                    }
                    else if(GameType == dod && (StrEqual(wepName,"weapon_amerknife") ||
                                                StrEqual(wepName,"weapon_spade")))
                    {
                        visibility=90;
                    }
                }
                for(new y=64;y<count;y++)
                {
                    if(IsValidEdict(y))
                    {
                        if(GetEntDataEnt(y,ownerOffset)==x)
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
    if (GameType == cstrike)
    {
        new maxplayers=GetMaxClients();
        decl String:wepName[128];
        for(new x=1;x<=maxplayers;x++)
        {
            if(IsClientInGame(x) && IS_ALIVE(x))
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
    if (client)
    {
        new team=GetClientTeam(client);
        new Float:teleLoc[3];
        new searchteam=(team==2)?3:2;
        new Handle:playerList=PlayersOnTeam(searchteam); // <3 SHVector.
        if (GetArraySize(playerList)>0) // are there any enemies?
        {
            // who gets their position mooched off them?
            new lucky_player_iter=GetRandomInt(0,GetArraySize(playerList)-1);
            new lucky_player=GetArrayCell(playerList,lucky_player_iter);
            EntityOrigin(lucky_player,teleLoc);
            teleLoc[0]+=40.0;
            SetEntityOrigin(client,teleLoc);
            isMole[client]=true;
            if (GameType == cstrike)
            {
                SetModel(client, (team == 2) ? "models/player/ct_urban.mdl"
                                             : "models/player/t_phoenix.mdl");
            }
        }
        else
        {
            War3Source_ChatMessage(client,COLOR_DEFAULT,
                                   "%c[War3Source] %cCould not find a place to mole to, there are no enemies!",
                                   COLOR_GREEN,COLOR_DEFAULT);
        }
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

public SetMaxHealth(entity,amount)
{
    SetEntData(entity,maxHealthOffset[entity],amount,1);
}

public GetMaxHealth(entity)
{
    return GetEntData(entity,maxHealthOffset[entity],1);
}

public GetLifeState(client)
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

stock UsePeriapt(client)
{
    usedPeriapt[client]=true;
    new health =GetClientHealth(client)+50;
    if (GameType == tf2 && health > GetMaxHealth(client))
    {
        SetMaxHealth(client, health);
    }
    SetHealth(client, health);
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
        if(IsClientInGame(x) && GetClientTeam(x)==team)
            PushArrayCell(temp,x);
    }
    return temp;
}

public SetRenderColor(client,r,g,b,a)
{
    if(colorOffset != -1)
    {
        SetEntData(client,colorOffset,r,1,true);
        SetEntData(client,colorOffset+1,g,1,true);
        SetEntData(client,colorOffset+2,b,1,true);
        SetEntData(client,colorOffset+3,a,1,true);
        if(renderModeOffset==-1)
            return;
        else
            SetEntData(client,renderModeOffset,3,1,true);
    }
}

stock War3Source_ChatMessage(target,color,const String:szMsg[],any:...)
{
    if(strlen(szMsg)>191)
    {
        LogError("Disallow string len(%d)>191",strlen(szMsg));
        return;
    }
    else
    {
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
}
