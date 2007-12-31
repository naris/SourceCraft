/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_UndeadScourge.sp
 * Description: The Undead Scourge race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/health"
#include "War3Source/damage"
#include "War3Source/log"

public Plugin:myinfo = 
{
    name = "test_damage",
    author = "Naris",
    description = "Test damage.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

// War3Source Functions
public OnPluginStart()
{
    GetGameType();

    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnClientPutInServer(client)
{
    SetupHealth(client);
}

public OnGameFrame()
{
    SaveAllHealth();
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    new index = GetClientOfUserId(userid);
    if (index && IsClientConnected(index) && IsPlayerAlive(index))
        SaveHealth(index);
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid = GetEventInt(event,"userid");
    new victimIndex = GetClientOfUserId(victimUserid);

    new attackerUserid = GetEventInt(event,"attacker");
    new attackerIndex = GetClientOfUserId(attackerUserid);

    new health = GetEventInt(event,"health");
    new oldHealth = GetSavedHealth(victimIndex);

    new damage = GetDamage(event, victimIndex, attackerIndex, -1, -1);

    decl String:victimName[64];
    GetClientName(victimIndex,victimName,sizeof(victimName));

    decl String:attackerName[64];
    GetClientName(attackerIndex,attackerName,sizeof(attackerName));

    decl String:weapon[64];
    GetClientWeapon(attackerIndex, weapon, sizeof(weapon));

    LogMessage("%s has attacked %s with %s for %d damage with %d of %d health remaining.\n",
               attackerName, victimName, weapon, damage, health, oldHealth);

    if (victimIndex)
        PrintToChat(victimIndex,"%s has attacked %s with %s for %d damage with %d of %d health remaining.",
                    attackerName, victimName, weapon, damage, health, oldHealth);

    if (attackerIndex)
        PrintToChat(attackerIndex,"%s has attacked %s with %s for %d damage with %d of %d health remaining.",
                    attackerName, victimName, weapon, damage, health, oldHealth);

    if (victimIndex)
        SaveHealth(victimIndex);
}
