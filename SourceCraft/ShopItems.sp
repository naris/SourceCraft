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

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2_stocks>
#include <tf2_player>
#include <tftools>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/respawn"
#include "sc/weapons"
#include "sc/log"

new Handle:hGameConf      = INVALID_HANDLE;

#include "sc/ammo"

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
#define ITEM_PACK            12 // Ammo Pack - Given Grenades
#define ITEM_SACK            13 // Sack of looting - Loot crystals from corpses.
#define ITEM_LOCKBOX         14 // Lockbox - Keep crystals safe from theft.
#define ITEM_RING            15 // Ring of Regeneration + 1 - Given extra health over time
#define ITEM_RING3           16 // Ring of Regeneration + 3 - Given extra health over time
#define ITEM_RING5           17 // Ring of Regeneration + 5 - Given extra health over time
#define ITEM_MOLE            18 // Mole - Respawn in enemies spawn with cloak.
#define ITEM_MOLE_PROTECTION 19 // Mole Protection - Reduce damage from a Mole.
#define ITEM_MOLE_REFLECTION 20 // Mole Reflection - Reflects damage back to the Mole.
#define ITEM_MOLE_RETENTION  21 // Mole Retention - Keep Mole Protection/Reflection until used.
//#define ITEM_GOGGLES       22 // The Goggles - They do nothing!
//#define ITEM_ADMIN         23 // Purchase Admin on the Server
#define MAXITEMS             22
 
new myWepsOffset;

new Handle:vecPlayerWeapons[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Float:spawnLoc[MAXPLAYERS+1][3];
new bool:usedPeriapt[MAXPLAYERS+1];
new bool:isMole[MAXPLAYERS+1];
new Float:gClawTime[MAXPLAYERS+1];

enum TFClass { none, scout, sniper, soldier, demoman, medic, heavy, pyro, spy, engineer };
stock String:tfClassNames[10][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy Guy", "Pyro", "Spy", "Engineer" };

new Handle:hUTILRemove    = INVALID_HANDLE;
new Handle:hGiveNamedItem = INVALID_HANDLE;
new Handle:hWeaponDrop    = INVALID_HANDLE;
new Handle:hSetModel      = INVALID_HANDLE;

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
    shopItem[ITEM_ANKH]=CreateShopItem("Ankh of Reincarnation", "ankh",
                                       "If you die you will retrieve your equipment the following round.",
                                       40);

    shopItem[ITEM_BOOTS]=CreateShopItem("Boots of Speed", "boots", 
                                        "Allows you to move faster.",
                                        55);

    shopItem[ITEM_CLAWS]=CreateShopItem("Claws of Attack", "claws", 
                                        "Up to an additional 8 hp will be removed from the enemy on every successful attack.",
                                        60);

    shopItem[ITEM_CLOAK]=CreateShopItem("Cloak of Shadows", "cloak", 
                                        "Makes you immune to uncloaking, also makes you invisible for 10 seconds\nwhen standing still AND holding a melee weapon.",
                                        30);

    shopItem[ITEM_MASK]=CreateShopItem("Mask of Death", "mask", 
                                       "You will receive health for every hit on the enemy.",
                                       10);

    shopItem[ITEM_NECKLACE]=CreateShopItem("Necklace of Immunity", "necklace", 
                                           "You will be immune to enemy ultimates.",
                                           20);

    shopItem[ITEM_ORB]=CreateShopItem("Orb of Frost", "orb", 
                                      "Slows your enemy down when you hit him.",
                                      35);

    shopItem[ITEM_PERIAPT]=CreateShopItem("Periapt of Health", " periapt",
                                          "Receive extra health.",
                                          50);

    shopItem[ITEM_TOME]=CreateShopItem("Tome of Experience", "tome", 
                                       "Automatically gain experience, this item is used on purchase.",
                                       50);

    shopItem[ITEM_SCROLL]=CreateShopItem("Scroll of Respawning", "scroll",
                                         "You will respawn immediately after death.",
                                         15);

    shopItem[ITEM_SOCK]=CreateShopItem("Sock of the Feather", "sock", 
                                       "You will be able to jump higher.",
                                       45);

    if (GameType == cstrike)
    {
        shopItem[ITEM_GLOVES]=CreateShopItem("Flaming Gloves of Warmth", "gloves", 
                                             "You will be given a grenade every 10 seconds.",
                                             35);
    }
    else
        shopItem[ITEM_GLOVES]=-1;

    shopItem[ITEM_PACK]=CreateShopItem("Infinite Ammo Pack", "ammo", 
                                       "You will be given ammo or metal every 10 seconds.",
                                       35);

    shopItem[ITEM_SACK]=CreateShopItem("Sack of Looting", "sack", 
                                       "Gives you a 55-85% chance to loot up to 25-50% of a corpse's crystals when you kill them.\nAttacking with melee weapons increases the odds and amount of crystals stolen.\nBackstabbing further increases the odds and amount!",
                                       85);

    shopItem[ITEM_LOCKBOX]=CreateShopItem("Lockbox", "lockbox", 
                                          "A lockbox to keep your crystals safe from theft.",
                                          10);

    shopItem[ITEM_RING]=CreateShopItem("Ring of Regeneration + 1", "ring+1",
                                       "Gives 1 health every second, won't exceed your normal HP.",
                                       15);

    shopItem[ITEM_RING3]=CreateShopItem("Ring of Regeneration + 3", "ring+3",
                                        "Gives 3 health every second, won't exceed your normal HP.",
                                        35);

    shopItem[ITEM_RING5]=CreateShopItem("Ring of Regeneration + 5", "ring+5",
                                        "Gives 5 health every second, won't exceed your normal HP.",
                                        55);

    shopItem[ITEM_MOLE]=CreateShopItem("Mole", "mole",
                                       "Tunnel to the enemies spawn\nat the beginning of the round\nand disguise as the enemy to\nget a quick couple of kills.",
                                       75);

    shopItem[ITEM_MOLE_PROTECTION]=CreateShopItem("Mole Protection", "mole_protection",
                                                  "Deflect some damage from the mole\nto give yourself a fighting chance.",
                                                  15);

    shopItem[ITEM_MOLE_REFLECTION]=CreateShopItem("Mole Reflection", "mole_reflection",
                                                  "Reflect some damage back to the mole\nto give yourself a fighting chance.",
                                                  45);

    shopItem[ITEM_MOLE_RETENTION]=CreateShopItem("Mole Retention", "mole_retrntion",
                                                 "Keep your Mole Protection and/or Reflection\nafter you die until it is used.",
                                                 15);

    //shopItem[ITEM_GOGGLES]=CreateShopItem("The Goggles","They do nothing!","0");

    FindClipOffsets();
    LoadSDKToolStuff();
}

public LoadSDKToolStuff()
{
    hGameConf=LoadGameConfigFile("plugin.sourcecraft");

    if (GameType == cstrike)
    {
        myWepsOffset = FindSendPropOffs("CAI_BaseNPC", "m_hMyWeapons");

        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"UTIL_SetModel");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_String,SDKPass_Pointer);
        hSetModel=EndPrepSDKCall();

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
    }

    if (GameType == cstrike || GameType == dod)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"GiveNamedItem");
        PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity,SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_String,SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
        hGiveNamedItem=EndPrepSDKCall();
    }
}

public OnMapStart()
{
    SetupSound(bootsWav, true, true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindAmmoOffset(client);
    FindMaxHealthOffset(client);
    if (GameType == cstrike)
        vecPlayerWeapons[client]=CreateArray(ByteCountToCells(128));
}

public OnItemPurchase(client,Handle:player,item)
{
    if(item==shopItem[ITEM_BOOTS] && IsPlayerAlive(client))             // Boots of Speed
    {
        SetSpeed(player,1.2);
        EmitSoundToAll(bootsWav,client);
    }
    else if(item==shopItem[ITEM_CLOAK] && IsPlayerAlive(client))        // Cloak of Shadows
    {
        SetVisibility(player, 0, TimedMeleeInvisibility, 1.0, 10.0);
        SetImmunity(player,Immunity_Uncloaking,true);
    }
    else if(item==shopItem[ITEM_NECKLACE])                              // Necklace of Immunity
        SetImmunity(player,Immunity_Ultimates,true);
    else if(item==shopItem[ITEM_LOCKBOX])                               // Lockbox
        SetImmunity(player,Immunity_Theft,true);
    else if(item==shopItem[ITEM_PERIAPT] && IsPlayerAlive(client))      // Periapt of Health
        UsePeriapt(client);
    else if(item==shopItem[ITEM_TOME])                                  // Tome of Experience
    {
        SetXP(player,GetRace(player),GetXP(player,GetRace(player))+25);
        SetOwnsItem(player,shopItem[ITEM_TOME],false);
        PrintToChat(client,"%c[SourceCraft] %cYou gained 25XP.",COLOR_GREEN,COLOR_DEFAULT);
    }
    else if(item==shopItem[ITEM_SCROLL] && !IsPlayerAlive(client))      // Scroll of Respawning 
    {
        SetOwnsItem(player,shopItem[ITEM_SCROLL],false);
        RespawnPlayer(client);
    }
    else if(item==shopItem[ITEM_SOCK])                                  // Sock of the Feather
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
            if(GetOwnsItem(player,shopItem[ITEM_ANKH]))                 // Ankh of Reincarnation
            {
                if (GameType == cstrike)
                {
                    decl String:wepName[128];
                    new Handle:pack = AuthTimer(0.2,client,Ankh);
                    new size=GetArraySize(vecPlayerWeapons[client]);
                    WritePackCell(pack, size);
                    for(new x=0;x<size;x++)
                    {
                        GetArrayString(vecPlayerWeapons[client],x,wepName,sizeof(wepName));
                        WritePackString(pack, wepName);
                    }
                    SetOwnsItem(player,shopItem[ITEM_ANKH],false);
                }
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
        if (victim_index != attacker_index && attacker_player != INVALID_HANDLE)
        {
            if(GetOwnsItem(attacker_player,shopItem[ITEM_SACK]))
                LootCorpse(event, victim_index, victim_player, attacker_index, attacker_player);
        }

        if (assister_player != INVALID_HANDLE)
        {
            if(GetOwnsItem(assister_player,shopItem[ITEM_SACK]))
                LootCorpse(event, victim_index, victim_player, assister_index, assister_player);
        }

        if (GameType == cstrike || !GetOwnsItem(victim_player,shopItem[ITEM_ANKH]))
        {
            if(GetOwnsItem(victim_player,shopItem[ITEM_BOOTS]))
            {
                SetOwnsItem(victim_player,shopItem[ITEM_BOOTS],false);
                StopSound(victim_index,SNDCHAN_AUTO,bootsWav);
            }

            if(GetOwnsItem(victim_player,shopItem[ITEM_CLAWS]))
                SetOwnsItem(victim_player,shopItem[ITEM_CLAWS],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_CLOAK]))
            {
                SetOwnsItem(victim_player,shopItem[ITEM_CLOAK],false);
                SetImmunity(victim_player,Immunity_Uncloaking,false);
            }

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

            if(GetOwnsItem(victim_player,shopItem[ITEM_GLOVES]))
                SetOwnsItem(victim_player,shopItem[ITEM_GLOVES],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_PACK]))
                SetOwnsItem(victim_player,shopItem[ITEM_PACK],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_SACK]))
                SetOwnsItem(victim_player,shopItem[ITEM_SACK],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_LOCKBOX]))
            {
                SetOwnsItem(victim_player,shopItem[ITEM_LOCKBOX],false);
                SetImmunity(victim_player,Immunity_Theft,false);
            }

            if(GetOwnsItem(victim_player,shopItem[ITEM_RING]))
                SetOwnsItem(victim_player,shopItem[ITEM_RING],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_RING3]))
                SetOwnsItem(victim_player,shopItem[ITEM_RING3],false);

            if(GetOwnsItem(victim_player,shopItem[ITEM_RING5]))
                SetOwnsItem(victim_player,shopItem[ITEM_RING5],false);

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

            if (!GetOwnsItem(victim_player,shopItem[ITEM_MOLE_RETENTION]))
            {
                if(GetOwnsItem(victim_player,shopItem[ITEM_MOLE_PROTECTION]))
                    SetOwnsItem(victim_player,shopItem[ITEM_MOLE_PROTECTION],false);

                if(GetOwnsItem(victim_player,shopItem[ITEM_MOLE_REFLECTION]))
                    SetOwnsItem(victim_player,shopItem[ITEM_MOLE_REFLECTION],false);
            }
        }
        else if (GetOwnsItem(victim_player,shopItem[ITEM_ANKH]))
            SetOwnsItem(victim_player,shopItem[ITEM_ANKH],false);

        if(GetOwnsItem(victim_player,shopItem[ITEM_PERIAPT]) && usedPeriapt[victim_index])
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
            if (attacker_index && isMole[attacker_index])
            {
                new reflection = GetOwnsItem(victim_player,shopItem[ITEM_MOLE_REFLECTION]);
                new protection = GetOwnsItem(victim_player,shopItem[ITEM_MOLE_PROTECTION]);
                if (reflection || protection)
                {
                    new victim_health = GetClientHealth(victim_index);
                    new prev_health   = victim_health+damage;
                    new new_health    = (victim_health+prev_health)/2;

                    if (new_health <= victim_health)
                        new_health = victim_health+(damage/2);

                    if (reflection && protection && GetRandomInt(1,100)<=50)
                        new_health += (damage*GetRandomFloat(0.25,0.75));

                    if (new_health>victim_health)
                    {
                        changed = true;
                        new amount = new_health-victim_health;

                        if (reflection)
                        {
                            if(!GetImmunity(attacker_player,Immunity_ShopItems) &&
                               !GetImmunity(attacker_player,Immunity_HealthTake) &&
                               !TF2_IsPlayerInvuln(attacker_index))
                            {
                                new reflect=RoundToNearest(damage * GetRandomFloat(0.50,1.10));
                                HurtPlayer(attacker_index,reflect,victim_index,"mole_reflection", "Mole Reflection", 10);

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

                    if(GetOwnsItem(victim_player,shopItem[ITEM_MOLE_RETENTION]))
                    {
                        SetOwnsItem(victim_player,shopItem[ITEM_MOLE_RETENTION],false);
                        PrintToChat(victim_index,"%c[SourceCraft]%c You have have used your %cMole Retention%c.",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                    }
                }
            }

            if(!GetImmunity(victim_player,Immunity_ShopItems))
            {
                if (!GetImmunity(victim_player,Immunity_HealthTake) &&
                    !TF2_IsPlayerInvuln(victim_index))
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
                    if (IsClientInGame(attacker_index) && IsPlayerAlive(attacker_index))
                    {
                        new newhealth=GetClientHealth(attacker_index)+2;
                        SetEntityHealth(attacker_index,newhealth);
                        changed = true;

                        PrintToChat(attacker_index,"%c[SourceCraft]%c You have received 2 hp from %N using %cMask of Death%c.",
                                    COLOR_GREEN,COLOR_DEFAULT,victim_index,COLOR_TEAM,COLOR_DEFAULT);
                    }
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
                     GetOwnsItem(assister_player,shopItem[ITEM_ORB])) &&
                     !GetImmunity(victim_player,Immunity_Freezing))
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
public Action:RestoreSpeed(Handle:timer,Handle:pack)
{
    new client=ClientOfAuthTimer(pack);
    if(client)
    {
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
            SetOverrideSpeed(player,-1.0);
    }
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
            if (player != INVALID_HANDLE)
            {
                new addhp = 0;
                if ( GetOwnsItem(player,shopItem[ITEM_RING]))
                    addhp += 1;
                if ( GetOwnsItem(player,shopItem[ITEM_RING3]))
                    addhp += 3;
                if ( GetOwnsItem(player,shopItem[ITEM_RING5]))
                    addhp += 5;

                if (addhp > 0)
                {
                    new newhp=GetClientHealth(x)+addhp;
                    new maxhp=GetMaxHealth(x);
                    if(newhp<=maxhp)
                        SetEntityHealth(x,newhp);
                }
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
            if (player != INVALID_HANDLE)
            {
                if (shopItem[ITEM_GLOVES] >= 0 && GetOwnsItem(player,shopItem[ITEM_GLOVES]))
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
                }

                if (shopItem[ITEM_PACK] >= 0 && GetOwnsItem(player,shopItem[ITEM_PACK]))
                {
                    if (GameType == tf2)
                    {
                        switch (TF2_GetPlayerClass(client))
                        {
                            case TFClass_Heavy: 
                            {
                                new ammo = GetAmmo(client, Primary) + 20;
                                if (ammo < 400.0)
                                {
                                    SetAmmo(client, Primary, ammo);
                                    PrintToChat(client,"%c[SourceCraft]%c You have received ammo from the %cInfinite Ammo Pack%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                }
                            }
                            case TFClass_Pyro: 
                            {
                                new ammo = GetAmmo(client, Primary) + 20;
                                if (ammo < 400.0)
                                {
                                    SetAmmo(client, Primary, ammo);
                                    PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                }
                            }
                            case TFClass_Medic: 
                            {
                                new ammo = GetAmmo(client, Primary) + 20;
                                if (ammo < 300.0)
                                {
                                    SetAmmo(client, Primary, ammo);
                                    PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                }
                            }
                            case TFClass_Engineer: // Gets Metal instead of Ammo
                            {
                                new ammo = GetAmmo(client, Metal) + 20;
                                if (ammo < 400.0)
                                {
                                    SetAmmo(client, Metal, ammo);
                                    PrintToChat(client,"%c[SourceCraft]%c You have received metal from %cInfinite Ammo Pack%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                }
                            }
                            default:
                            {
                                new ammo = GetAmmo(client, Primary) + 20;
                                if (ammo < 60.0)
                                {
                                    SetAmmo(client, Primary, ammo);
                                    PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                }
                            }
                        }
                    }
                    else
                    {
                        new ammoType  = 0;
                        new curWeapon = GetActiveWeapon(client);
                        if (curWeapon > 0)
                            ammoType  = GetAmmoType(curWeapon);

                        if (ammoType > 0)
                            GiveAmmo(client,ammoType,10,true);
                        else
                            SetClip(curWeapon, 5);

                        PrintToChat(client,"%c[SourceCraft]%c You have received ammo from %cInfinite Ammo Pack%c.",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                    }
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

public Action:Ankh(Handle:timer,Handle:pack)
{
    if (GameType == cstrike)
    {
        new client=ClientOfAuthTimer(pack);
        if(client)
        {
            decl String:wepName[128];
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
            new size = ReadPackCell(pack);
            for(new x=1;x<size;x++)
            {
                ReadPackString(pack, wepName,sizeof(wepName));
                new ent=GiveItem(client,wepName);
                new ammotype=GetAmmoType(ent);
                if(ammotype!=-1)
                    GiveAmmo(client,ammotype,1000,true);
            }
        }
    }
    return Plugin_Stop;
}

public Action:DoMole(Handle:timer,Handle:pack)
{
    new client=ClientOfAuthTimer(pack);
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
    return Plugin_Stop;
}

public Action:DoPeriapt(Handle:timer,Handle:pack)
{
    new client=ClientOfAuthTimer(pack);
    if(client)
    {
        SaveMaxHealth(client);
        UsePeriapt(client);
    }
    return Plugin_Stop;
}

UsePeriapt(client)
{
    IncreaseHealth(client, 50);
    usedPeriapt[client]=true;
}

LootCorpse(Handle:event,victim_index, Handle:victim_player, index, Handle:player)
{
    decl String:weapon[64];
    new bool:is_equipment = GetWeapon(event,index,weapon,sizeof(weapon));
    new bool:backstab     = GetEventInt(event, "customkill") == 2;
    new bool:is_melee     = backstab || IsMelee(weapon, is_equipment,
                                                index, victim_index);

    new chance=backstab ? 85 : (is_melee ? 75 : 55);
    if( GetRandomInt(1,100)<=chance && !GetImmunity(victim_player,Immunity_Theft))
    {
        new victim_cash=GetCredits(victim_player);
        if (victim_cash > 0)
        {
            new Float:percent=GetRandomFloat(backstab ? 0.40 : 0.10,is_melee ? 0.50 : 0.25);
            new cash=GetCredits(player);
            new amount = RoundToCeil(float(victim_cash) * percent);

            SetCredits(victim_player,victim_cash-amount);
            SetCredits(player,cash+amount);

            LogToGame("%N looted %d crystals from %N", index, amount, victim_index);

            PrintToChat(index,"%c[SourceCraft]%c You have looted %d %s from %N!",
                        COLOR_GREEN,COLOR_DEFAULT,amount,
                        (amount == 1) ? "crystal" : "crystals",
                        victim_index,COLOR_TEAM,COLOR_DEFAULT);

            PrintToChat(victim_index,"%c[SourceCraft]%c %N looted %d %s from your corpse!",
                        COLOR_GREEN,COLOR_DEFAULT,index,amount,
                        (amount == 1) ? "crystal" : "crystals");
        }
    }
}

// Non-specific stuff

stock RemoveEntity(entity)
{
    SDKCall(hUTILRemove,entity);
}

stock GiveItem(client,const String:item[])
{
    return SDKCall(hGiveNamedItem,client,item,0);
}

stock DropWeapon(client,weapon)
{
    SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,NULL_VECTOR);
}

stock SetModel(entity,const String:model[])
{
    SDKCall(hSetModel,entity,model);
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
