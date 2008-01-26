/**
 * vim: set ai et ts=4 sw=4 :
 * File: ShopItems.sp
 * Description: The shop items that come with SourceCraft.
 * Author(s): Anthony Iacono
 * Modifications by: Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#include "SourceCraft/SourceCraft"

#include "SourceCraft/util"
#include "SourceCraft/health"
#include "SourceCraft/authtimer"
#include "SourceCraft/respawn"
#include "SourceCraft/log"

// Defines

#define ITEM_ANKH             0 // Ankh of Reincarnation - Retrieve Equipment after death
#define ITEM_BOOTS            1 // Boots of Speed - Move Faster
#define ITEM_CLAWS            2 // Claws of Attack - Extra Damage
#define ITEM_CLOAK            3 // Cloak of Shadows - Invisibility
#define ITEM_MASK             4 // Mask of Death - Recieve Health for Hits
#define ITEM_NECKLACE         5 // Necklace of Immunity - Immune to Ultimates
#define ITEM_ORB              6 // Orb of Frost - Slow Enemy
#define ITEM_PERIAPT          7 // Periapt of Health - Get Extra Health when Purchased
#define ITEM_TOME             8 // Tome of Experience - Get Extra Experience when Purchased
#define ITEM_SCROLL           9 // Scroll of Respawning - Respawn after death.
#define ITEM_SOCK            10 // Sock of the Feather - Jump Higher
#define ITEM_GLOVES          11 // Flaming Gloves of Warmth - Given HE Grenades or ammo or metal over time
#define ITEM_RING            12 // Ring of Regeneration + 1 - Given extra health over time
#define ITEM_MOLE            13 // Mole - Respawn in enemies spawn with cloak.
#define ITEM_MOLE_PROTECTION 14 // Mole Protection - Reduce damage from a Mole.
#define ITEM_GOGGLES         15 // The Goggles - They do nothing!
#define MAXITEMS             15
 
new myWepsOffset;
new curWepOffset;
new ammotypeOffset;
new clipOffset;
new ammoOffset; // Primary Ammo
new ammo2Offset; // Secondary Ammo
new metalOffset; // metal (3rd Ammo)

new Handle:vecPlayerWeapons[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Float:spawnLoc[MAXPLAYERS+1][3];
new bool:usedPeriapt[MAXPLAYERS+1];
new bool:isMole[MAXPLAYERS+1];

enum TFClass { none, scout, sniper, soldier, demoman, medic, heavy, pyro, spy, engineer };
stock String:tfClassNames[10][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy Guy", "Pyro", "Spy", "Engineer" };

new Handle:hGameConf      = INVALID_HANDLE;
new Handle:hUTILRemove    = INVALID_HANDLE;
new Handle:hGiveNamedItem = INVALID_HANDLE;
new Handle:hWeaponDrop    = INVALID_HANDLE;
new Handle:hGiveAmmo      = INVALID_HANDLE;
new Handle:hSetModel      = INVALID_HANDLE;

new shopItem[MAXITEMS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft - Shopitems",
    author = "PimpinJuice",
    description = "The shop items that come with SourceCraft.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    SetupRespawn();
    return true;
}

public OnPluginStart()
{
    GetGameType();

    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent,EventHookMode_Pre);
    HookEvent("player_hurt",PlayerHurtEvent,EventHookMode_Pre);

    if (GameType == tf2)
        HookEvent("player_changeclass",PlayerChangeClassEvent);

    CreateTimer(20.0,Gloves,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(2.0,Regeneration,INVALID_HANDLE,TIMER_REPEAT);

    if (GameType == cstrike)
        CreateTimer(1.0,TrackWeapons,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    shopItem[ITEM_ANKH]=CreateShopItem("Ankh of Reincarnation","If you die you will retrieve your equipment the following round.","40");
    shopItem[ITEM_BOOTS]=CreateShopItem("Boots of Speed","Allows you to move faster.","7");
    shopItem[ITEM_CLAWS]=CreateShopItem("Claws of Attack","An additional 8 hp will be removed from the enemy on every successful attack.","3");
    shopItem[ITEM_CLOAK]=CreateShopItem("Cloak of Shadows","Makes you partially invisible, invisibility is increased when holding the knife, shovel or other melee weapon.","2");
    shopItem[ITEM_MASK]=CreateShopItem("Mask of Death","You will receive health for every hit on the enemy.","5");
    shopItem[ITEM_NECKLACE]=CreateShopItem("Necklace of Immunity","You will be immune to enemy ultimates.","2");
    shopItem[ITEM_ORB]=CreateShopItem("Orb of Frost","Slows your enemy down when you hit him.","15");
    shopItem[ITEM_PERIAPT]=CreateShopItem("Periapt of Health","Receive extra health.","3");
    shopItem[ITEM_TOME]=CreateShopItem("Tome of Experience","Automatically gain experience, this item is used on purchase.","10");
    shopItem[ITEM_SCROLL]=CreateShopItem("Scroll of Respawning","You will respawn immediately after death?\n(Note: Scroll of Respawning\nCan only be purchased once on death\nand once on spawn, so you can get 2 per\nround.","15");
    shopItem[ITEM_SOCK]=CreateShopItem("Sock of the Feather","You will be able to jump higher.","4");
    shopItem[ITEM_GLOVES]=CreateShopItem("Flaming Gloves of Warmth","You will be given a grenade or ammo or metal every 20 seconds.","5");
    shopItem[ITEM_RING]=CreateShopItem("Ring of Regeneration + 1","Gives 1 health every 2 seconds, won't exceed your normal HP.","3");
    shopItem[ITEM_MOLE]=CreateShopItem("Mole","Tunnel to the enemies spawn\nat the beginning of the round\nand disguise as the enemy to\nget a quick couple of kills.","90");
    shopItem[ITEM_MOLE_PROTECTION]=CreateShopItem("Mole Protection","Deflect some damage from the mole\nto give yourself a fighting chance.","5");
    shopItem[ITEM_GOGGLES]=CreateShopItem("The Goggles","They do nothing!","0");

    LoadSDKToolStuff();
}

public LoadSDKToolStuff()
{
    hGameConf=LoadGameConfigFile("plugin.sourcecraft");

    ammoOffset = FindSendPropOffs("CBasePlayer", "m_iAmmo");
    if(curWepOffset==-1)
        SetFailState("Couldn't find Ammo offset");

    if (GameType == tf2)
    {
        ammo2Offset     = ammoOffset  + 4;
        metalOffset     = ammo2Offset + 4;
    }
    else
    {
        ammotypeOffset  = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
        if(curWepOffset==-1)
            SetFailState("Couldn't find PrimaryAmmoType offset");

        clipOffset      = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
        if(curWepOffset==-1)
            SetFailState("Couldn't find Clip offset");

        curWepOffset=FindSendPropOffs("CAI_BaseNPC","m_hActiveWeapon");
        if(curWepOffset==-1)
            SetFailState("Couldn't find ActiveWeapon offset");

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

    if (GameType == cstrike)
    {
        myWepsOffset    = FindSendPropOffs("CAI_BaseNPC",       "m_hMyWeapons");

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
    }

    if (GameType == cstrike || GameType == dod)
    {
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"GiveNamedItem");
        PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity,SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_String,SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
        hGiveNamedItem=EndPrepSDKCall();
        StartPrepSDKCall(SDKCall_Static);
    }
}

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);

    if (GameType == cstrike)
        vecPlayerWeapons[client]=CreateArray(ByteCountToCells(128));
}

public OnItemPurchase(client,player,item)
{
    if(item==shopItem[ITEM_BOOTS] && IsPlayerAlive(client))              // Boots of Speed
        SetMaxSpeed(player,1.4);
    else if(item==shopItem[ITEM_CLOAK] && IsPlayerAlive(client))         // Cloak of Shadows
        SetMinVisibility(player, (GameType == tf2) ? 140 : 160, 0.50);
    else if(item==shopItem[ITEM_NECKLACE])                          // Necklace of Immunity
        SetImmunity(player,Immunity_Ultimates,true);
    else if(item==shopItem[ITEM_PERIAPT] && IsPlayerAlive(client))       // Periapt of Health
        UsePeriapt(client);
    else if(item==shopItem[ITEM_TOME])                              // Tome of Experience
    {
        SetXP(player,GetRace(player),GetXP(player,GetRace(player))+100);
        SetOwnsItem(player,shopItem[8],false);
        PrintToChat(client,"%c[JigglyCraft] %cYou gained 100XP.",COLOR_GREEN,COLOR_DEFAULT);
    }
    else if(item==shopItem[ITEM_SCROLL] && !IsPlayerAlive(client))       // Scroll of Respawning 
    {
        RespawnPlayer(client);
        SetOwnsItem(player,shopItem[9],false);
    }
    else if(item==shopItem[ITEM_SOCK])                              // Sock of the Feather
        SetMinGravity(player,0.3);
}

public PlayerChangeClassEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
        ResetMaxHealth(client);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        SetupMaxHealth(client);
        GetClientAbsOrigin(client,spawnLoc[client]);

        new player=GetPlayer(client);
        if(player>-1)
        {
            if(GetOwnsItem(player,shopItem[ITEM_ANKH]))        // Ankh of Reincarnation
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
                    CreateTimer(0.2,Ankh,temp);
                }
                SetOwnsItem(player,shopItem[ITEM_ANKH],false);
            }

            if(GetOwnsItem(player,shopItem[ITEM_BOOTS]))                           // Boots of Speed
                SetMaxSpeed(player,1.4);

            if(GetOwnsItem(player,shopItem[ITEM_CLOAK]))                           // Cloak of Shadows
                SetMinVisibility(player, (GameType == tf2) ? 140 : 160, 0.80);

            if(GetOwnsItem(player,shopItem[ITEM_PERIAPT]) && !usedPeriapt[client]) // Periapt of Health
                UsePeriapt(client);

            if(GetOwnsItem(player,shopItem[ITEM_SOCK]))                            // Sock of the Feather
                SetMinGravity(player,0.3);

            if(GetOwnsItem(player,shopItem[ITEM_MOLE]))                            // Mole
            {
                // We need to check to use mole, or did we JUST use it?
                if(isMole[client])
                {
                    // we already used it, take it away
                    isMole[client]=false;
                    SetOwnsItem(player,shopItem[13],false);
                }
                else
                    AuthTimer(1.0,client,DoMole);
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    new player=GetPlayer(client);
    if(player>-1)
    {
        if (GameType == cstrike ||
            !GetOwnsItem(player,shopItem[ITEM_ANKH]))
        {
            if(GetOwnsItem(player,shopItem[ITEM_BOOTS]))
                SetOwnsItem(player,shopItem[ITEM_BOOTS],false);

            if(GetOwnsItem(player,shopItem[ITEM_CLAWS]))
                SetOwnsItem(player,shopItem[ITEM_CLAWS],false);

            if(GetOwnsItem(player,shopItem[ITEM_CLOAK]))
            {
                SetMinVisibility(player, 255, 1.0);
                SetOwnsItem(player,shopItem[3],false);
            }

            if(GetOwnsItem(player,shopItem[ITEM_MASK]))
                SetOwnsItem(player,shopItem[ITEM_MASK],false);

            if(GetOwnsItem(player,shopItem[ITEM_NECKLACE]))
            {
                SetOwnsItem(player,shopItem[ITEM_NECKLACE],false);
                SetImmunity(player,Immunity_Ultimates,false);
            }

            if(GetOwnsItem(player,shopItem[ITEM_ORB]))
                SetOwnsItem(player,shopItem[ITEM_ORB],false);

            if(GetOwnsItem(player,shopItem[ITEM_PERIAPT]))
            {
                SetOwnsItem(player,shopItem[ITEM_PERIAPT],false);
            }

            if(GetOwnsItem(player,shopItem[ITEM_SCROLL]))
            {
                SetOwnsItem(player,shopItem[ITEM_SCROLL],false);
                AuthTimer(1.0,client,RespawnPlayerHandle);
            }

            if(GetOwnsItem(player,shopItem[ITEM_SOCK]))
                SetOwnsItem(player,shopItem[ITEM_SOCK],false);

            if(GetOwnsItem(player,shopItem[ITEM_GLOVES]))
                SetOwnsItem(player,shopItem[ITEM_GLOVES],false);

            if(GetOwnsItem(player,shopItem[ITEM_GOGGLES]))
                SetOwnsItem(player,shopItem[ITEM_GOGGLES],false);

            if(GetOwnsItem(player,shopItem[ITEM_RING]))
                SetOwnsItem(player,shopItem[ITEM_RING],false);

            if(GetOwnsItem(player,shopItem[ITEM_MOLE]))
            {
                // We need to check to use mole, or did we JUST use it?
                if(isMole[client])
                {
                    // we already used it, take it away
                    isMole[client]=false;
                    SetOwnsItem(player,shopItem[ITEM_MOLE],false);
                }
            }

            if(GetOwnsItem(player,shopItem[ITEM_MOLE_PROTECTION]))
                SetOwnsItem(player,shopItem[ITEM_MOLE_PROTECTION],false);
        }

        SetMaxSpeed(player,1.0);
        SetMinGravity(player,1.0);

        // Reset Overrides when players die
        SetOverrideSpeed(player,1.0);

        // Reset MaxHealth back to normal
        if (usedPeriapt[client] && GameType == tf2)
            SetMaxHealth(client, maxHealth[client]);

        usedPeriapt[client]=false;
    }
}

public Action:PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid          = GetEventInt(event,"userid");
    new attacker_userid = GetEventInt(event,"attacker");
    new assister_userid = (GameType==tf2) ? GetEventInt(event,"assister") : 0;
    new bool:changed    = false;

    if(userid && attacker_userid && userid != attacker_userid)
    {
        new index           = GetClientOfUserId(userid);
        new attacker_index  = GetClientOfUserId(attacker_userid);

        new player          = GetPlayer(index);
        new player_attacker = GetPlayer(attacker_index);

        new assister_index  = -1;
        new player_assister = -1;

        if (assister_userid != 0)
        {
            assister_index  = GetClientOfUserId(assister_userid);
            player_assister = GetPlayer(assister_index);
        }

        if(player !=-1 && player_attacker != -1)
        {
            if(!GetImmunity(player,Immunity_ShopItems))
            {
                if (!GetImmunity(player,Immunity_HealthTake))
                {
                    if (GetOwnsItem(player_attacker,shopItem[ITEM_CLAWS]))
                    {
                        new newhealth=GetClientHealth(index)-8;
                        if (newhealth <= 0)
                        {
                            newhealth=0;
                            LogKill(attacker_index, index, "item_claws", "Claws of Attack", 8);
                        }
                        else
                            LogDamage(attacker_index, index, "item_claws", "Claws of Attack", 8);

                        SetHealth(index,newhealth);
                        changed = true;
                    }

                    if (player_assister != -1 && GetOwnsItem(player_assister,shopItem[ITEM_CLAWS]))
                    {
                        new newhealth = GetClientHealth(index)-8;
                        if (newhealth <= 0)
                        {
                            newhealth=0;
                            LogKill(assister_index, index, "item_claws", "Claws of Attack", 8);
                        }
                        else
                            LogDamage(assister_index, index, "item_claws", "Claws of Attack", 8);

                        SetHealth(index,newhealth);
                        changed = true;
                    }
                }

                if (GetOwnsItem(player_attacker,shopItem[ITEM_MASK]))
                {
                    new newhealth=GetClientHealth(attacker_index)+2;
                    SetHealth(attacker_index,newhealth);
                    changed = true;

                    decl String:victimName[64];
                    GetClientName(index,victimName,sizeof(victimName));
                    PrintToChat(attacker_index,"%c[JigglyCraft]%c You have received 2 hp from %s using %cMask of Death%c.",
                                COLOR_GREEN,COLOR_DEFAULT,victimName,COLOR_TEAM,COLOR_DEFAULT);
                }

                if (player_assister != -1 && GetOwnsItem(player_assister,shopItem[ITEM_MASK]))
                {
                    new newhealth=GetClientHealth(assister_index)+2;
                    SetHealth(assister_index,newhealth);
                    changed = true;

                    decl String:victimName[64];
                    GetClientName(index,victimName,sizeof(victimName));
                    PrintToChat(attacker_index,"%c[JigglyCraft]%c You have received 2 hp from %s using %cMask of Death%c.",
                                COLOR_GREEN,COLOR_DEFAULT,victimName,COLOR_TEAM,COLOR_DEFAULT);
                }

                if (GetOwnsItem(player_attacker,shopItem[ITEM_ORB]) ||
                    (player_assister != -1 &&
                     GetOwnsItem(player_assister,shopItem[ITEM_ORB])))
                {
                    SetOverrideSpeed(player,0.5);
                    AuthTimer(5.0,index,RestoreSpeed);

                    decl String:aname[128];
                    GetClientName(attacker_index,aname,sizeof(aname));
                    if (assister_index > -1)
                    {
                        decl String:assister[64];
                        GetClientName(attacker_index,assister,sizeof(aname));
                        StrCat(aname,sizeof(aname), "+");
                        StrCat(aname,sizeof(aname), assister);
                    }
                    PrintToChat(index,"%c[JigglyCraft] %s %chas frozen you with the %cOrb of Frost%c",
                                COLOR_GREEN,aname,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                }

                if (GetOwnsItem(player,shopItem[ITEM_MOLE_PROTECTION]))
                {
                    if(isMole[attacker_index])
                    {
                        new damage=GetDamage(event, index);
                        new h1=GetEventInt(event,"health")+damage;
                        new h2=GetClientHealth(index);
                        if(h2<h1)
                            SetHealth(index,(h1+h2)/2);
                        if(!h2)
                            SetHealth(index,0); // They should really be dead.

                        changed = true;
                    }
                }
            }
        }
    }
    return changed ? Plugin_Changed : Plugin_Continue;
}

// Item specific
public Action:RestoreSpeed(Handle:timer,any:temp)
{
    decl String:auth[64];
    GetArrayString(temp,0,auth,63);
    new client=PlayerOfAuth(auth);
    if(client)
    {
        new player=GetPlayer(client);
        if(player>-1)
            SetOverrideSpeed(player,0.0);
    }
    ClearArray(temp);
    return Plugin_Stop;
}

public Action:Regeneration(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new x=1;x<=maxplayers;x++)
    {
        if(IsClientInGame(x) && IsPlayerAlive(x))
        {
            new player=GetPlayer(x);
            if(player>=0 && GetOwnsItem(player,shopItem[ITEM_RING]))
            {
                new newhp=GetClientHealth(x)+1;
                new maxhp=(GameType == tf2) ? GetMaxHealth(x) : 100;
                if(newhp<=maxhp)
                    SetHealth(x,newhp);
            }
        }
    }
    return Plugin_Continue;
}

public Action:Gloves(Handle:timer)
{
    new maxclients=GetMaxClients();
    for(new client=1;client<=maxclients;client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            new player=GetPlayer(client);
            if (player>=0 && GetOwnsItem(player,shopItem[ITEM_GLOVES]))
            {
                if (GameType == cstrike)
                {
                    GiveItem(player,"weapon_hegrenade");
                }
                else if (GameType == dod)
                {
                    new team=GetClientTeam(player);
                    GiveItem(player,team == 2 ? "weapon_frag_us" : "weapon_frag_ger");
                }
                else if (GameType == tf2)
                {
                    switch (TF_GetClass(client))
                    {
                        case TF2_HEAVY: 
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 10;
                            if (ammo < 400.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[JigglyCraft]%c You have received ammo from %cFlaming Gloves of Warmth%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        case TF2_PYRO: 
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 10;
                            if (ammo < 400.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[JigglyCraft]%c You have received ammo from %cFlaming Gloves of Warmth%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        case TF2_MEDIC: 
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 10;
                            if (ammo < 300.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[JigglyCraft]%c You have received ammo from %cFlaming Gloves of Warmth%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        case TF2_ENG: // Gets Metal instead of Ammo
                        {
                            new metal = GetEntData(client, metalOffset, 4) + 10;
                            if (metal < 400.0)
                            {
                                SetEntData(client, metalOffset, metal, 4, true);
                                PrintToChat(client,"%c[JigglyCraft]%c You have received metal from %cFlaming Gloves of Warmth%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        default:
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 2;
                            if (ammo < 60.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[JigglyCraft]%c You have received ammo from %cFlaming Gloves of Warmth%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                    }
                }
                else
                {
                    new ammoType  = 0;
                    new curWeapon = GetEntDataEnt(client, curWepOffset);
                    if (curWeapon > 0)
                        ammoType  = GetAmmoType(curWeapon);

                    if (ammoType > 0)
                        GiveAmmo(client,ammoType,10,true);
                    else if (clipOffset)
                        SetEntData(curWeapon, clipOffset, 5, 4, true);
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:TrackWeapons(Handle:timer)
{
    if (GameType == cstrike)
    {
        new maxclients=GetMaxClients();
        decl String:wepName[128];
        for(new x=1;x<=maxclients;x++)
        {
            if(IsClientInGame(x) && IsPlayerAlive(x))
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
    return Plugin_Continue;
}

public Action:Ankh(Handle:timer,any:temp)
{
    if (GameType == cstrike)
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
        }
    }
    ClearArray(temp);
    return Plugin_Stop;
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
            //EntityOrigin(lucky_player,teleLoc);
            teleLoc[0]=spawnLoc[lucky_player][0] + 5.0;
            teleLoc[1]=spawnLoc[lucky_player][1];
            teleLoc[2]=spawnLoc[lucky_player][2];
            TeleportEntity(client,teleLoc, NULL_VECTOR, NULL_VECTOR);
            isMole[client]=true;
            if (GameType == cstrike)
            {
                SetModel(client, (team == 2) ? "models/player/ct_urban.mdl"
                                             : "models/player/t_phoenix.mdl");
            }
        }
        else
        {
            PrintToChat(client, "%c[JigglyCraft] %cCould not find a place to mole to, there are no enemies!", COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    ClearArray(temp);
    return Plugin_Stop;
}

stock UsePeriapt(client)
{
    IncreaseHealth(client, 50);
    usedPeriapt[client]=true;
}

// Non-specific stuff

stock RemoveEntity(entity)
{
    SDKCall(hUTILRemove,entity);
}

public GiveItem(client,const String:item[])
{
    return SDKCall(hGiveNamedItem,client,item,0);
}

public DropWeapon(client,weapon)
{
    SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,NULL_VECTOR);
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
