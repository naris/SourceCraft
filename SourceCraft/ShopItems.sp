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

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/uber"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/respawn"
#include "sc/weapons"
#include "sc/log"

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
#define ITEM_PACK            11 // Ammo Pack - Given HE Grenades or ammo or metal over time
#define ITEM_SACK            12 // Sack of looting - Loot crystals from corpses.
#define ITEM_RING            13 // Ring of Regeneration + 1 - Given extra health over time
#define ITEM_MOLE            14 // Mole - Respawn in enemies spawn with cloak.
#define ITEM_MOLE_PROTECTION 15 // Mole Protection - Reduce damage from a Mole.
#define ITEM_MOLE_REFLECTION 16 // Mole Protection - Reflects damage back to the Mole.
//#define ITEM_GOGGLES       17 // The Goggles - They do nothing!
//#define ITEM_ADMIN         18 // Purchase Admin on the Server
#define MAXITEMS             16
 
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
new Float:gClawTime[MAXPLAYERS+1];

enum TFClass { none, scout, sniper, soldier, demoman, medic, heavy, pyro, spy, engineer };
stock String:tfClassNames[10][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy Guy", "Pyro", "Spy", "Engineer" };

new Handle:hGameConf      = INVALID_HANDLE;
new Handle:hUTILRemove    = INVALID_HANDLE;
new Handle:hGiveNamedItem = INVALID_HANDLE;
new Handle:hWeaponDrop    = INVALID_HANDLE;
new Handle:hGiveAmmo      = INVALID_HANDLE;
new Handle:hSetModel      = INVALID_HANDLE;

new Handle:m_Currency   = INVALID_HANDLE; 
new Handle:m_Currencies = INVALID_HANDLE; 

new shopItem[MAXITEMS+1];

new String:bootsWav[] = "sourcecraft/bootospeed.mp3";

public Plugin:myinfo = 
{
    name = "SourceCraft - Shopitems",
    author = "PimpinJuice",
    description = "The shop items that come with SourceCraft.",
    version = "1.0.0.0",
    url = "http://pimpinjuice.net/"
};

public OnConfigsExecuted()
{
    m_Currency = FindConVar("sc_currency");
    if (m_Currency == INVALID_HANDLE)
        SetFailState("Couldn't find sc_currency variable");

    m_Currencies = FindConVar("sc_currencies");
    if (m_Currencies == INVALID_HANDLE)
        SetFailState("Couldn't find sc_currencies variable");
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    SetupRespawn();
    return true;
}

public OnPluginStart()
{
    GetGameType();

    if (!HookEvent("player_spawn",PlayerSpawnEvent))
        SetFailState("Couldn't hook the player_spawn event.");

    CreateTimer(10.0,AmmoPack,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(1.0,Regeneration,INVALID_HANDLE,TIMER_REPEAT);

    if (GameType == cstrike)
        CreateTimer(1.0,TrackWeapons,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    shopItem[ITEM_ANKH]=CreateShopItem("Ankh of Reincarnation","If you die you will retrieve your equipment the following round.","40");
    shopItem[ITEM_BOOTS]=CreateShopItem("Boots of Speed","Allows you to move faster.","55");
    shopItem[ITEM_CLAWS]=CreateShopItem("Claws of Attack","Up to an additional 8 hp will be removed from the enemy on every successful attack.","60");
    shopItem[ITEM_CLOAK]=CreateShopItem("Cloak of Shadows","Makes you invisible when standing still AND holding the knife, shovel or other melee weapon.","45");
    shopItem[ITEM_MASK]=CreateShopItem("Mask of Death","You will receive health for every hit on the enemy.","10");
    shopItem[ITEM_NECKLACE]=CreateShopItem("Necklace of Immunity","You will be immune to enemy ultimates.","20");
    shopItem[ITEM_ORB]=CreateShopItem("Orb of Frost","Slows your enemy down when you hit him.","35");
    shopItem[ITEM_PERIAPT]=CreateShopItem("Periapt of Health","Receive extra health.","50");
    shopItem[ITEM_TOME]=CreateShopItem("Tome of Experience","Automatically gain experience, this item is used on purchase.","50");
    shopItem[ITEM_SCROLL]=CreateShopItem("Scroll of Respawning","You will respawn immediately after death?\n(Note: Scroll of Respawning\nCan only be purchased once on death\nand once on spawn, so you can get 2 per\nround.","15");
    shopItem[ITEM_SOCK]=CreateShopItem("Sock of the Feather","You will be able to jump higher.","45");
    shopItem[ITEM_PACK]=CreateShopItem("Infinite Ammo Pack","You will be given ammo or metal every 10 seconds.","35");
    shopItem[ITEM_SACK]=CreateShopItem("Sack of Looting","Gives you a 55-85% chance to loot up to 25-50% of a corpse's crystals when you kill them.\nAttacking with melee weapons increases the odds and amount of crystals stolen.\nBackstabbing further increases the odds and amount!","85");
    shopItem[ITEM_RING]=CreateShopItem("Ring of Regeneration + 1","Gives 1 health every second, won't exceed your normal HP.","15");
    shopItem[ITEM_MOLE]=CreateShopItem("Mole","Tunnel to the enemies spawn\nat the beginning of the round\nand disguise as the enemy to\nget a quick couple of kills.","75");
    shopItem[ITEM_MOLE_PROTECTION]=CreateShopItem("Mole Protection","Deflect some damage from the mole\nto give yourself a fighting chance.","15");
    shopItem[ITEM_MOLE_REFLECTION]=CreateShopItem("Mole Reflection","Reflect some damage back to the mole\nto give yourself a fighting chance.","45");
    //shopItem[ITEM_GOGGLES]=CreateShopItem("The Goggles","They do nothing!","0");

    FindUberOffsets();
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
        ammo2Offset = ammoOffset  + 4;
        metalOffset = ammo2Offset + 4;
    }
    else
    {
        ammotypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
        if(curWepOffset==-1)
            SetFailState("Couldn't find PrimaryAmmoType offset");

        clipOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
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
        myWepsOffset = FindSendPropOffs("CAI_BaseNPC", "m_hMyWeapons");

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

public OnMapStart()
{
    SetupSound(bootsWav, true, true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    if (GameType == cstrike)
        vecPlayerWeapons[client]=CreateArray(ByteCountToCells(128));
}

public OnItemPurchase(client,Handle:player,item)
{
    if(item==shopItem[ITEM_BOOTS] && IsPlayerAlive(client))              // Boots of Speed
    {
        SetSpeed(player,1.2);
        EmitSoundToAll(bootsWav,client);
    }
    else if(item==shopItem[ITEM_CLOAK] && IsPlayerAlive(client))         // Cloak of Shadows
        SetVisibility(player, 0, TimedMeleeInvisibility, 1.0, 10.0);
    else if(item==shopItem[ITEM_NECKLACE])                          // Necklace of Immunity
        SetImmunity(player,Immunity_Ultimates,true);
    else if(item==shopItem[ITEM_PERIAPT] && IsPlayerAlive(client))       // Periapt of Health
        UsePeriapt(client);
    else if(item==shopItem[ITEM_TOME])                              // Tome of Experience
    {
        SetXP(player,GetRace(player),GetXP(player,GetRace(player))+25);
        SetOwnsItem(player,shopItem[ITEM_TOME],false);
        PrintToChat(client,"%c[SourceCraft] %cYou gained 25XP.",COLOR_GREEN,COLOR_DEFAULT);
    }
    else if(item==shopItem[ITEM_SCROLL] && !IsPlayerAlive(client))       // Scroll of Respawning 
    {
        SetOwnsItem(player,shopItem[ITEM_SCROLL],false);
        if (GameType == tf2)
            SetEntPropFloat(client, Prop_Send, "m_flDeathTime", 0.0);
        else
            RespawnPlayer(client);
    }
    else if(item==shopItem[ITEM_SOCK])                              // Sock of the Feather
        SetGravity(player,0.5);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        GetClientAbsOrigin(client,spawnLoc[client]);

        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            if(GetOwnsItem(player,shopItem[ITEM_ANKH]))        // Ankh of Reincarnation
            {
                if (GameType == cstrike)
                {
                    new Handle:temp=CreateArray(ByteCountToCells(128));
                    new size=GetArraySize(vecPlayerWeapons[client]);
                    decl String:wepName[128];
                    decl String:auth[64];
                    GetClientAuthString(client,auth,sizeof(auth));
                    PushArrayString(temp,auth);
                    for(new x=0;x<size;x++)
                    {
                        GetArrayString(vecPlayerWeapons[client],x,wepName,sizeof(wepName));
                        PushArrayString(temp,wepName);
                    }
                    CreateTimer(0.2,Ankh,temp);
                }
                SetOwnsItem(player,shopItem[ITEM_ANKH],false);
            }

            if(GetOwnsItem(player,shopItem[ITEM_BOOTS]))                           // Boots of Speed
            {
                SetSpeed(player,1.2);
                StopSound(client,SNDCHAN_AUTO,bootsWav);
                EmitSoundToAll(bootsWav,client);
            }

            if(GetOwnsItem(player,shopItem[ITEM_CLOAK]))                           // Cloak of Shadows
                SetVisibility(player, 0, TimedMeleeInvisibility, 0.0, 0.0);

            if(GetOwnsItem(player,shopItem[ITEM_PERIAPT]) && !usedPeriapt[client]) // Periapt of Health
                AuthTimer(0.1,client,DoPeriapt);

            if(GetOwnsItem(player,shopItem[ITEM_SOCK]))                            // Sock of the Feather
                SetGravity(player,0.5);

            if(GetOwnsItem(player,shopItem[ITEM_MOLE]))                            // Mole
            {
                // We need to check to use mole, or did we JUST use it?
                if(isMole[client])
                {
                    // we already used it, take it away
                    isMole[client]=false;
                    SetOwnsItem(player,shopItem[ITEM_MOLE],false);
                }
                else
                    AuthTimer(1.0,client,DoMole);
            }
        }
    }
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_player != INVALID_HANDLE)
    {
        if (attacker_player != INVALID_HANDLE)
        {
            if(GetOwnsItem(attacker_player,shopItem[ITEM_SACK]))
                LootCorpse(event, victim_index, victim_player, attacker_index, attacker_player);
        }

        if (assister_player != INVALID_HANDLE)
        {
            if(GetOwnsItem(assister_player,shopItem[ITEM_SACK]))
                LootCorpse(event, victim_index, victim_player, assister_index, assister_player);
        }

        if (GameType == cstrike ||
            !GetOwnsItem(victim_player,shopItem[ITEM_ANKH]))
        {
            if(GetOwnsItem(victim_player,shopItem[ITEM_BOOTS]))
            {
                SetOwnsItem(victim_player,shopItem[ITEM_BOOTS],false);
                StopSound(victim_index,SNDCHAN_AUTO,bootsWav);
            }

            if(GetOwnsItem(victim_player,shopItem[ITEM_CLAWS]))
                SetOwnsItem(victim_player,shopItem[ITEM_CLAWS],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_CLOAK]))
                SetOwnsItem(victim_player,shopItem[ITEM_CLOAK],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_MASK]))
                SetOwnsItem(victim_player,shopItem[ITEM_MASK],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_NECKLACE]))
            {
                SetOwnsItem(victim_player,shopItem[ITEM_NECKLACE],false);
                SetImmunity(victim_player,Immunity_Ultimates,false);
            }

            if(GetOwnsItem(victim_player,shopItem[ITEM_ORB]))
                SetOwnsItem(victim_player,shopItem[ITEM_ORB],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_SCROLL]))
            {
                SetOwnsItem(victim_player,shopItem[ITEM_SCROLL],false);
                AuthTimer(1.0,victim_index,RespawnPlayerHandle);
            }

            if(GetOwnsItem(victim_player,shopItem[ITEM_SOCK]))
                SetOwnsItem(victim_player,shopItem[ITEM_SOCK],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_PACK]))
                SetOwnsItem(victim_player,shopItem[ITEM_PACK],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_SACK]))
                SetOwnsItem(victim_player,shopItem[ITEM_SACK],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_RING]))
                SetOwnsItem(victim_player,shopItem[ITEM_RING],false);

            //if(GetOwnsItem(victim_player,shopItem[ITEM_GOGGLES]))
            //    SetOwnsItem(victim_player,shopItem[ITEM_GOGGLES],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_MOLE]))
            {
                // We need to check to use mole, or did we JUST use it?
                if(isMole[victim_index])
                {
                    // we already used it, take it away
                    isMole[victim_index]=false;
                    SetOwnsItem(victim_player,shopItem[ITEM_MOLE],false);
                }
            }

            if(GetOwnsItem(victim_player,shopItem[ITEM_MOLE_PROTECTION]))
                SetOwnsItem(victim_player,shopItem[ITEM_MOLE_PROTECTION],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_MOLE_REFLECTION]))
                SetOwnsItem(victim_player,shopItem[ITEM_MOLE_REFLECTION],false);
        }

        if(GetOwnsItem(victim_player,shopItem[ITEM_PERIAPT]))
            SetOwnsItem(victim_player,shopItem[ITEM_PERIAPT],false);

        // Reset player speed/gravity/visibility attributes when they doe
        SetSpeed(victim_player,-1.0);
        SetGravity(victim_player,-1.0);
        SetVisibility(victim_player, -1);

        // Reset Overrides when players die
        SetOverrideSpeed(victim_player,-1.0);

        // Reset MaxHealth back to normal
        if (usedPeriapt[victim_index])
        {
            usedPeriapt[victim_index]=false;
            ResetMaxHealth(victim_index);
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed = false;

    if(victim_index && victim_index != attacker_index)
    {
        if (victim_player != INVALID_HANDLE && attacker_player != INVALID_HANDLE)
        {
            if(isMole[attacker_index])
            {
                new reflection = GetOwnsItem(victim_player,shopItem[ITEM_MOLE_REFLECTION]);
                if (reflection || GetOwnsItem(victim_player,shopItem[ITEM_MOLE_PROTECTION]))
                {
                    new victim_health = GetClientHealth(victim_index);
                    new prev_health   = victim_health+damage;
                    new new_health    = (victim_health+prev_health)/2;

                    if (new_health <= victim_health)
                        new_health = victim_health+(damage/2);

                    if (new_health>victim_health)
                    {
                        changed = true;
                        new amount = new_health-victim_health;

                        if (reflection)
                        {
                            if(!GetImmunity(attacker_player,Immunity_ShopItems) &&
                               !GetImmunity(attacker_player,Immunity_HealthTake) && !IsUber(attacker_index))
                            {
                                new reflect=RoundToNearest(damage * GetRandomFloat(0.50,1.10));
                                new newhp=GetClientHealth(attacker_index)-reflect;
                                if (newhp <= 0)
                                {
                                    newhp=0;
                                    LogKill(victim_index, attacker_index, "mole_reflection", "Mole Reflection", reflect);
                                }
                                else
                                    LogDamage(victim_index, attacker_index, "mole_reflection", "Mole Reflection", reflect);

                                SetEntityHealth(attacker_index,newhp);

                                if (amount < reflect)
                                {
                                    new_health += reflect - amount;
                                    amount = reflect;
                                }
                            }

                            PrintToChat(victim_index,"%c[SourceCraft]%c You have received %d hp from %cMole Reflection%c.",
                                        COLOR_GREEN,COLOR_DEFAULT,amount,COLOR_TEAM,COLOR_DEFAULT);
                        }
                        else
                        {
                            PrintToChat(victim_index,"%c[SourceCraft]%c You have received %d hp from %cMole Protection%c.",
                                        COLOR_GREEN,COLOR_DEFAULT,amount,COLOR_TEAM,COLOR_DEFAULT);
                        }
                        SetEntityHealth(victim_index,new_health);
                    }
                }
            }

            if(!GetImmunity(victim_player,Immunity_ShopItems))
            {
                if (!GetImmunity(victim_player,Immunity_HealthTake) && !IsUber(victim_index))
                {
                    if (GetOwnsItem(attacker_player,shopItem[ITEM_CLAWS]) &&
                        (!gClawTime[attacker_index] ||
                         GetGameTime() - gClawTime[attacker_index] > 1.000))
                    {
                        new amount=RoundToCeil(float(damage)*0.10);
                        if (amount > 8)
                            amount = 8;
                        else if (amount < 1)
                            amount = 1;

                        new newhealth=GetClientHealth(victim_index)-amount;
                        if (newhealth <= 0)
                        {
                            newhealth=0;
                            LogKill(attacker_index, victim_index, "item_claws", "Claws of Attack", amount);
                        }
                        else
                            LogDamage(attacker_index, victim_index, "item_claws", "Claws of Attack", amount);

                        SetEntityHealth(victim_index,newhealth);
                        gClawTime[attacker_index] = GetGameTime();
                        changed = true;
                    }

                    if (assister_player != INVALID_HANDLE &&
                        GetOwnsItem(assister_player,shopItem[ITEM_CLAWS]) &&
                        (!gClawTime[assister_index] ||
                         GetGameTime() - gClawTime[assister_index] > 1.000))
                    {
                        new amount=RoundToFloor(float(damage)*0.10);
                        if (amount > 8)
                            amount = 8;
                        new newhealth=GetClientHealth(victim_index)-amount;
                        if (newhealth <= 0)
                        {
                            newhealth=0;
                            LogKill(assister_index, victim_index, "item_claws", "Claws of Attack", amount);
                        }
                        else
                            LogDamage(assister_index, victim_index, "item_claws", "Claws of Attack", amount);

                        SetEntityHealth(victim_index,newhealth);
                        gClawTime[assister_index] = GetGameTime();
                        changed = true;
                    }
                }

                if (GetOwnsItem(attacker_player,shopItem[ITEM_MASK]))
                {
                    new newhealth=GetClientHealth(attacker_index)+2;
                    SetEntityHealth(attacker_index,newhealth);
                    changed = true;

                    PrintToChat(attacker_index,"%c[SourceCraft]%c You have received 2 hp from %N using %cMask of Death%c.",
                                COLOR_GREEN,COLOR_DEFAULT,victim_index,COLOR_TEAM,COLOR_DEFAULT);
                }

                if (assister_player != INVALID_HANDLE &&
                    GetOwnsItem(assister_player,shopItem[ITEM_MASK]))
                {
                    new newhealth=GetClientHealth(assister_index)+2;
                    SetEntityHealth(assister_index,newhealth);
                    changed = true;

                    PrintToChat(attacker_index,"%c[SourceCraft]%c You have received 2 hp from %N using %cMask of Death%c.",
                                COLOR_GREEN,COLOR_DEFAULT,victim_index,COLOR_TEAM,COLOR_DEFAULT);
                }

                if (GetOwnsItem(attacker_player,shopItem[ITEM_ORB]) ||
                    (assister_player != INVALID_HANDLE &&
                     GetOwnsItem(assister_player,shopItem[ITEM_ORB])))
                {
                    SetOverrideSpeed(victim_player,0.5);
                    AuthTimer(5.0,victim_index,RestoreSpeed);

                    decl String:aname[128];
                    GetClientName(attacker_index,aname,sizeof(aname));
                    if (assister_index > 0)
                    {
                        decl String:assister[64];
                        GetClientName(assister_index,assister,sizeof(aname));
                        StrCat(aname,sizeof(aname), "+");
                        StrCat(aname,sizeof(aname), assister);
                    }
                    PrintToChat(victim_index,"%c[SourceCraft] %s %chas frozen you with the %cOrb of Frost%c",
                                COLOR_GREEN,aname,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
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
    GetArrayString(temp,AUTHINFO_ID,auth,sizeof(auth));
    new client=PlayerOfAuth(auth);
    if(client)
    {
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
            SetOverrideSpeed(player,-1.0);
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
            new Handle:player=GetPlayerHandle(x);
            if (player != INVALID_HANDLE &&
                GetOwnsItem(player,shopItem[ITEM_RING]))
            {
                new newhp=GetClientHealth(x)+1;
                new maxhp=GetMaxHealth(x);
                if(newhp<=maxhp)
                    SetEntityHealth(x,newhp);
            }
        }
    }
    return Plugin_Continue;
}

public Action:AmmoPack(Handle:timer)
{
    new maxclients=GetMaxClients();
    for(new client=1;client<=maxclients;client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            new Handle:player=GetPlayerHandle(client);
            if (player != INVALID_HANDLE &&
                GetOwnsItem(player,shopItem[ITEM_PACK]))
            {
                if (GameType == cstrike)
                {
                    GiveItem(client,"weapon_hegrenade");
                }
                else if (GameType == dod)
                {
                    new team=GetClientTeam(client);
                    GiveItem(client,team == 2 ? "weapon_frag_us" : "weapon_frag_ger");
                }
                else if (GameType == tf2)
                {
                    switch (TF_GetClass(client))
                    {
                        case TF2_HEAVY: 
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 20;
                            if (ammo < 400.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[SourceCraft]%c You have received ammo from the %cInfinite Ammo Pack%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        case TF2_PYRO: 
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 20;
                            if (ammo < 400.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        case TF2_MEDIC: 
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 20;
                            if (ammo < 300.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        case TF2_ENG: // Gets Metal instead of Ammo
                        {
                            new metal = GetEntData(client, metalOffset, 4) + 20;
                            if (metal < 400.0)
                            {
                                SetEntData(client, metalOffset, metal, 4, true);
                                PrintToChat(client,"%c[SourceCraft]%c You have received metal from %cInfinite Ammo Pack%c.",
                                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                            }
                        }
                        default:
                        {
                            new ammo = GetEntData(client, ammoOffset, 4) + 8;
                            if (ammo < 60.0)
                            {
                                SetEntData(client, ammoOffset, ammo, 4, true);
                                PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
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
                        GetEdictClassname(wepEnt,wepName,sizeof(wepName));
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
        GetArrayString(temp,AUTHINFO_ID,auth,sizeof(auth));
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
                    GetEdictClassname(ent,wepName,sizeof(wepName));
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
                GetArrayString(temp,x,wepName,sizeof(wepName));
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
    GetArrayString(temp,AUTHINFO_ID,auth,sizeof(auth));
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
            PrintToChat(client, "%c[SourceCraft] %cCould not find a place to mole to, there are no enemies!", COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    ClearArray(temp);
    return Plugin_Stop;
}

public Action:DoPeriapt(Handle:timer,Handle:temp)
{
    decl String:auth[64];
    GetArrayString(temp,AUTHINFO_ID,auth,sizeof(auth));
    new client=PlayerOfAuth(auth);
    if(client)
    {
        SaveMaxHealth(client);
        UsePeriapt(client);
    }
    ClearArray(temp);
    return Plugin_Stop;
}

UsePeriapt(client)
{
    IncreaseHealth(client, 50);
    usedPeriapt[client]=true;
}

LootCorpse(Handle:event,victim_index, Handle:victim_player, index, Handle:player)
{
    decl String:weapon[64] = "";
    new bool:is_equipment=GetWeapon(event,index,weapon,sizeof(weapon));
    new bool:is_melee=IsMelee(weapon, is_equipment);
    new bool:backstab=GetEventInt(event, "customkill") == 2;

    new chance=backstab ? 85 : (is_melee ? 75 : 55);
    if(GetRandomInt(1,100)<=chance)
    {
        new victim_cash=GetCredits(victim_player);
        if (victim_cash > 0)
        {
            new Float:percent=GetRandomFloat(backstab ? 0.40 : 0.10,is_melee ? 0.50 : 0.25);
            new cash=GetCredits(player);
            new amount = RoundToCeil(float(victim_cash) * percent);

            SetCredits(victim_player,victim_cash-amount);
            SetCredits(player,cash+amount);

            decl String:currencies[64];
            GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));

            LogMessage("%N stole %d %s from %N", index, amount, currencies, victim_index);

            PrintToChat(index,"%c[SourceCraft]%c You have looted %d %s from %N!",
                        COLOR_GREEN,COLOR_DEFAULT,amount,currencies,victim_index,COLOR_TEAM,COLOR_DEFAULT);
            PrintToChat(victim_index,"%c[SourceCraft]%c %N looted %d %s from your corpse!",
                        COLOR_GREEN,COLOR_DEFAULT,index,amount,currencies);
        }
    }
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
