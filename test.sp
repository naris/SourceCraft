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

#include "SourceCraft/sc/SourceCraft"

new m_OffsetCloakMeter;
new m_OffsetDisguiseTeam;
new m_OffsetDisguiseClass;
new m_OffsetDisguiseHealth;
new m_OffsetDisguiseTargetIndex;
new m_OffsetDesiredDisguiseTeam;
new m_OffsetDesiredDisguiseClass;
new m_OffsetInvisChangeCompleteTime;
new m_OffsetCritMult;
new m_OffsetStealthNoAttackExpire;
new m_OffsetStealthNextChangeTime;
new m_OffsetPlayerState;
new m_OffsetNumHealers;
new m_OffsetPlayerCond;
new m_OffsetClass;
new m_OffsetPoisoned;
new m_OffsetWearingSuit;

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
    CreateTimer(1.0,TrackVariables,INVALID_HANDLE,TIMER_REPEAT);
}

// Events
public OnMapStart()
{
        m_OffsetCloakMeter=FindSendPropInfo("CTFPlayer","m_flCloakMeter");
        m_OffsetDisguiseTeam=FindSendPropInfo("CTFPlayer","m_nDisguiseTeam");
        m_OffsetDisguiseClass=FindSendPropInfo("CTFPlayer","m_nDisguiseClass");
        m_OffsetDisguiseHealth=FindSendPropInfo("CTFPlayer","m_iDisguiseHealth");
        m_OffsetDisguiseTargetIndex=FindSendPropInfo("CTFPlayer","m_iDisguiseTargetIndex");
        m_OffsetDesiredDisguiseTeam=FindSendPropInfo("CTFPlayer","m_nDesiredDisguiseTeam");
        m_OffsetDesiredDisguiseClass=FindSendPropInfo("CTFPlayer","m_nDesiredDisguiseClass");
        m_OffsetInvisChangeCompleteTime=FindSendPropInfo("CTFPlayer","m_flInvisChangeCompleteTime");
        m_OffsetCritMult=FindSendPropInfo("CTFPlayer","m_iCritMult");
        m_OffsetStealthNoAttackExpire=FindSendPropInfo("CTFPlayer","m_flStealthNoAttackExpire");
        m_OffsetStealthNextChangeTime=FindSendPropInfo("CTFPlayer","m_flStealthNextChangeTime");
        m_OffsetPlayerState=FindSendPropInfo("CTFPlayer","m_nPlayerState");
        m_OffsetNumHealers=FindSendPropInfo("CTFPlayer","m_nNumHealers");
        m_OffsetPlayerCond=FindSendPropInfo("CTFPlayer","m_nPlayerCond");
        m_OffsetClass=FindSendPropInfo("CTFPlayer","m_iClass");
        m_OffsetPoisoned=FindSendPropInfo("CTFPlayer","m_bPoisoned");
        m_OffsetWearingSuit=FindSendPropInfo("CTFPlayer","m_bWearingSuit");
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
                new class = m_OffsetClass>0 ? GetEntData(client,m_OffsetClass) : -99;
                new Float:cloakMeter = m_OffsetCloakMeter>0 ? GetEntDataFloat(client,m_OffsetCloakMeter) : -99.9;
                new disguiseTeam = m_OffsetDisguiseTeam>0 ? GetEntData(client,m_OffsetDisguiseTeam) : -99;
                new disguiseClass = m_OffsetDisguiseClass>0 ? GetEntData(client,m_OffsetDisguiseClass) : -99;
                new disguiseTarget = m_OffsetDisguiseTargetIndex>0 ? GetEntData(client,m_OffsetDisguiseTargetIndex) : -99;
                new disguiseHealth = m_OffsetDisguiseHealth>0 ? GetEntData(client,m_OffsetDisguiseHealth) : -99;
                new desiredDisguiseTeam = m_OffsetDesiredDisguiseTeam>0 ? GetEntData(client,m_OffsetDesiredDisguiseTeam) : -99;
                new desiredDisguiseClass = m_OffsetDesiredDisguiseClass>0 ? GetEntData(client,m_OffsetDesiredDisguiseClass) : -99;
                new Float:invisChangeCompleteTime = m_OffsetInvisChangeCompleteTime>0 ? GetEntDataFloat(client,m_OffsetInvisChangeCompleteTime) : -99.9;
                new critMult = m_OffsetCritMult>0 ? GetEntData(client,m_OffsetCritMult) : -99;
                new Float:stealthNoAttackExpire = m_OffsetStealthNoAttackExpire>0 ? GetEntDataFloat(client,m_OffsetStealthNoAttackExpire) : -99.9;
                new Float:stealthNextChangeTime = m_OffsetStealthNextChangeTime>0 ? GetEntDataFloat(client,m_OffsetStealthNextChangeTime) : -99.9;
                new playerState = m_OffsetPlayerState>0 ? GetEntData(client,m_OffsetPlayerState) : -99;
                new numHealers = m_OffsetNumHealers>0 ? GetEntData(client,m_OffsetNumHealers) : -99;
                new playerCond = m_OffsetPlayerCond>0 ? GetEntData(client,m_OffsetPlayerCond) : -99;
                new poisened = m_OffsetPoisoned>0 ? GetEntData(client,m_OffsetPoisoned) : -99;
                new wearingSuit = m_OffsetWearingSuit>0 ? GetEntData(client,m_OffsetWearingSuit) : -99;

                LogMessage("client=%N,tfClass=%d,class=%d,cloakMeter=%f,disguiseTeam=%d,disguiseClass=%d,disguiseTarget=%d,disguiseHealth=%d,desiredDisguiseTeam=%d,desiredDisguiseClass=%d,invisChangeCompleteTime=%f,critMult=%d,stealthNoAttackExpire=%f,stealthNextChangeTime=%f,playerState=%d,numHealers=%d,playerCond=%d,poisoned=%d,wearingSuit=%d",client,tfClass,class,cloakMeter,disguiseTeam,disguiseClass,disguiseTarget,disguiseHealth,desiredDisguiseTeam,desiredDisguiseClass,invisChangeCompleteTime,critMult,stealthNoAttackExpire,stealthNextChangeTime,playerState,numHealers,playerCond,poisened,wearingSuit);
                PrintToChat( client,"dTeam=%d,dClass=%d,dTarget=%d,dHealth=%d,dDTeam=%d,dDClass=%d,iCCTime=%f,cMult=%d,sNAExpire=%f,sNCTime=%f,pState=%d,nHealers=%d,pCond=%d",disguiseTeam,disguiseClass,disguiseTarget,disguiseHealth,desiredDisguiseTeam,desiredDisguiseClass,invisChangeCompleteTime,critMult,stealthNoAttackExpire,stealthNextChangeTime,playerState,numHealers,playerCond);
            }
        }
    }
    return Plugin_Continue;
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (m_OffsetCloakMeter>0)
    {
        SetEntData(client,m_OffsetDisguiseTeam, 0);
        SetEntData(client,m_OffsetDisguiseClass, 0);
        SetEntData(client,m_OffsetDisguiseHealth, 0);
    }
}


