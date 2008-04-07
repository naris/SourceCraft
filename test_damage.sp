/**
 * vim: set ai et ts=4 sw=4 :
 * File: test_damage.sp
 * Description: Display damage for every hit.
 * Author(s): Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_nican>

#include "SourceCraft/sc/util"
#include "SourceCraft/sc/maxhealth"
#include "SourceCraft/sc/engine/damage"

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

public OnGameFrame()
{
    SaveAllHealth();
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    new index = GetClientOfUserId(userid);
    if (index && IsClientConnected(index) && IsPlayerAlive(index))
    {
        SaveHealth(index);

        new health = GetClientHealth(index);

        new offset2 = FindDataMapOffs(index,"m_iHealth");
        new health2 = offset2 != -1 ? GetEntData(index,offset2) : -1;

        new offset3 = FindSendPropInfo("CTFPlayer","m_iHealth");
        new health3 = offset3 != -1 ? GetEntData(index,offset3) : -1;

        new maxhealth  = TF_GetMaxHealth(index);

        new maxoffset2 = FindDataMapOffs(index,"m_iMaxHealth");
        new maxhealth2 = maxoffset2 != -1 ? GetEntData(index,maxoffset2) : -1; 

        LogMessage("[Spawn] %d - health=%d,%d,%d, maxHealth=%d,%d",
                   index, health, health2, health3, maxhealth, maxhealth2);

        if (index &&  IsClientInGame(index))
            PrintToChat(index, "health=%d,%d,%d, maxHealth=%d,%d",
                        health, health2, health3, maxhealth, maxhealth2);
    }
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid = GetEventInt(event,"userid");
    new victimIndex = GetClientOfUserId(victimUserid);

    new attackerUserid = GetEventInt(event,"attacker");
    new attackerIndex = GetClientOfUserId(attackerUserid);

    new health = GetEventInt(event,"health");
    new oldHealth = GetSavedHealth(victimIndex);

    new damage = GetDamage(event, victimIndex);

    decl String:victimName[64] = "";
    decl String:attackerName[64] = "";
    decl String:weapon[64] = "";

    if (victimIndex)
        GetClientName(victimIndex,victimName,sizeof(victimName));

    if (attackerIndex)
    {
        GetClientName(attackerIndex,attackerName,sizeof(attackerName));
        GetClientWeapon(attackerIndex, weapon, sizeof(weapon));
    }

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

    new health1 = GetClientHealth(victimIndex);

    new offset2 = FindDataMapOffs(victimIndex,"m_iHealth");
    new health2 = offset2 != -1 ? GetEntData(victimIndex,offset2) : -1;

    new offset3 = FindSendPropInfo("CTFPlayer","m_iHealth");
    new health3 = offset3 != -1 ? GetEntData(victimIndex,offset3) : -1;

    new maxhealth  = TF_GetMaxHealth(victimIndex);

    new maxoffset2 = FindDataMapOffs(victimIndex,"m_iMaxHealth");
    new maxhealth2 = maxoffset2 != -1 ? GetEntData(victimIndex,maxoffset2) : -1; 

    LogMessage("[Hurt] %d - health=%d,%d,%d, maxHealth=%d,%d",
               victimIndex, health1, health2, health3, maxhealth, maxhealth2);

    if (victimIndex &&  IsClientInGame(victimIndex))
        PrintToChat(victimIndex, "health=%d,%d,%d, maxHealth=%d,%d",
                    health1, health2, health3, maxhealth, maxhealth2);
}
