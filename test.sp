/**
 * vim: set ai et ts=4 sw=4 :
 * File: test.sp
 * Description: Display values of various variables.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <tf2>

new m_OffsetCloakMeter[MAXPLAYERS+1];
new m_OffsetDisguiseTeam[MAXPLAYERS+1];
new m_OffsetDisguiseClass[MAXPLAYERS+1];
new m_OffsetDisguiseTargetIndex[MAXPLAYERS+1];
new m_OffsetDisguiseHealth[MAXPLAYERS+1];
new m_OffsetDesiredDisguiseTeam[MAXPLAYERS+1];
new m_OffsetDesiredDisguiseClass[MAXPLAYERS+1];
new m_OffsetInvisChangeCompleteTime[MAXPLAYERS+1];
new m_OffsetCritMult[MAXPLAYERS+1];
new m_OffsetStealthNoAttackExpire[MAXPLAYERS+1];
new m_OffsetStealthNextChangeTime[MAXPLAYERS+1];
new m_OffsetPlayerState[MAXPLAYERS+1];
new m_OffsetNumHealers[MAXPLAYERS+1];
new m_OffsetPlayerCond[MAXPLAYERS+1];
new m_OffsetClass[MAXPLAYERS+1];
new m_OffsetPoisoned[MAXPLAYERS+1];
new m_OffsetWearingSuit[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "Test Module",
    author = "-=|JFH|=-Naris",
    description = "A Testing Module to track various variables.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    HookEvent("player_spawn",PlayerSpawnEvent);
    CreateTimer(2.0,TrackVariables,INVALID_HANDLE,TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
    if (client)
    {
        m_OffsetCloakMeter[client]=0;
        m_OffsetDisguiseTeam[client]=0;
        m_OffsetDisguiseClass[client]=0;
        m_OffsetDisguiseTargetIndex[client]=0;
        m_OffsetDisguiseHealth[client]=0;
        m_OffsetDesiredDisguiseTeam[client]=0;
        m_OffsetDesiredDisguiseClass[client]=0;
        m_OffsetInvisChangeCompleteTime[client]=0;
        m_OffsetCritMult[client]=0;
        m_OffsetStealthNoAttackExpire[client]=0;
        m_OffsetStealthNextChangeTime[client]=0;
        m_OffsetInvisChangeCompleteTime[client]=0;
        m_OffsetPlayerState[client]=0;
        m_OffsetNumHealers[client]=0;
        m_OffsetPlayerCond[client]=0;
        m_OffsetClass[client]=0;
        m_OffsetPoisoned[client]=0;
        m_OffsetWearingSuit[client]=0;
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        m_OffsetCloakMeter[client]=FindDataMapOffs(client,"m_flCloakMeter");
        m_OffsetDisguiseTeam[client]=FindDataMapOffs(client,"m_nDisguiseTeam");
        m_OffsetDisguiseClass[client]=FindDataMapOffs(client,"m_nDisguiseClass");
        m_OffsetDisguiseTargetIndex[client]=FindDataMapOffs(client,"m_iDisguiseTargetIndex");
        m_OffsetDisguiseHealth[client]=FindDataMapOffs(client,"m_iDisguiseHealth");
        m_OffsetDesiredDisguiseTeam[client]=FindDataMapOffs(client,"m_nDesiredDisguiseTeam");
        m_OffsetDesiredDisguiseClass[client]=FindDataMapOffs(client,"m_nDesiredDisguiseClass");
        m_OffsetInvisChangeCompleteTime[client]=FindDataMapOffs(client,"m_flInvisChangeCompleteTime");
        m_OffsetCritMult[client]=FindDataMapOffs(client,"m_iCritMult");
        m_OffsetStealthNoAttackExpire[client]=FindDataMapOffs(client,"m_flStealthNoAttackExpire");
        m_OffsetStealthNextChangeTime[client]=FindDataMapOffs(client,"m_flStealthNextChangeTime");
        m_OffsetPlayerState[client]=FindDataMapOffs(client,"m_nPlayerState");
        m_OffsetNumHealers[client]=FindDataMapOffs(client,"m_nNumHealers");
        m_OffsetPlayerCond[client]=FindDataMapOffs(client,"m_nPlayerCond");
        m_OffsetClass[client]=FindDataMapOffs(client,"m_iClass");
        m_OffsetPoisoned[client]=FindDataMapOffs(client,"m_bPoisoned");
        m_OffsetWearingSuit[client]=FindDataMapOffs(client,"m_bWearingSuit");
    }
}

public Action:TrackVariables(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                new tfClass = TF_GetClass(client);
                new class = GetEntData(client,m_OffsetClass[client]);
                new Float:cloakMeter = GetEntDataFloat(client,m_OffsetCloakMeter[client]);
                new disguiseTeam = GetEntData(client,m_OffsetDisguiseTeam[client]);
                new disguiseClass = GetEntData(client,m_OffsetDisguiseClass[client]);
                new disguiseTarget = GetEntData(client,m_OffsetDisguiseTargetIndex[client]);
                new disguiseHealth = GetEntData(client,m_OffsetDisguiseHealth[client]);
                new desiredDisguiseTeam = GetEntData(client,m_OffsetDesiredDisguiseTeam[client]);
                new desiredDisguiseClass = GetEntData(client,m_OffsetDesiredDisguiseClass[client]);
                new Float:invisChangeCompleteTime = GetEntDataFloat(client,m_OffsetInvisChangeCompleteTime[client]);
                new critMult = GetEntData(client,m_OffsetCritMult[client]);
                new Float:stealthNoAttackExpire = GetEntDataFloat(client,m_OffsetStealthNoAttackExpire[client]);
                new Float:stealthNextChangeTime = GetEntDataFloat(client,m_OffsetStealthNextChangeTime[client]);
                new playerState = GetEntData(client,m_OffsetPlayerState[client]);
                new numHealers = GetEntData(client,m_OffsetNumHealers[client]);
                new playerCond = GetEntData(client,m_OffsetPlayerCond[client]);
                new bool:poisened = bool:GetEntData(client,m_OffsetPoisoned[client]);
                new bool:wearingSuit = bool:GetEntData(client,m_OffsetWearingSuit[client]);
                LogMessage("client=%N,tfClass=%d,class=%d,cloakMeter=%f,disguiseTeam=%d,disguiseClass=%d,disguiseTarget=%d,disguiseHealth=%d,desiredDisguiseTeam=%d,desiredDisguiseClass=%d,invisChangeCompleteTime=%f,critMult=%d,stealthNoAttackExpire=%f,stealthNextChangeTime=%f,playerState=%d,numHealers=%d,playerCond=%d,poisened=%d,wearingSuit=%d",client,tfClass,class,cloakMeter,disguiseTeam,disguiseClass,disguiseTarget,disguiseHealth,desiredDisguiseTeam,desiredDisguiseClass,invisChangeCompleteTime,critMult,stealthNoAttackExpire,stealthNextChangeTime,playerState,numHealers,playerCond,poisened,wearingSuit);
                PrintToChat( client,"tfC=%d,c=%d,cMeter=%f,dTeam=%d,dClass=%d,dTarget=%d,dHealth=%d,dDTeam=%d,dDClass=%d,iCCTime=%f,cMult=%d,sNAExpire=%f,sNCTime=%f,pState=%d,nHealers=%d,pCond=%d,p=%d,Suit=%d",tfClass,class,cloakMeter,disguiseTeam,disguiseClass,disguiseTarget,disguiseHealth,desiredDisguiseTeam,desiredDisguiseClass,invisChangeCompleteTime,critMult,stealthNoAttackExpire,stealthNextChangeTime,playerState,numHealers,playerCond,poisened,wearingSuit);
            }
        }
    }
    return Plugin_Continue;
}

