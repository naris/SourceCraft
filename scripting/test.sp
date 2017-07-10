/**
 * vim: set ai et ts=4 sw=4 :
 * File: test.sp
 * Description: Display values of various variables.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <regex>

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
new m_OffsetBonusProgress;
new m_OffsetBonusChallenge;
new m_OffsetAirDash;
new m_OffsetMaxspeed;
new m_OffsetMyWepons;

new Handle:cvarTrack = INVALID_HANDLE;

enum objects { dispenser, teleporter_entry, teleporter_exit, sentrygun, sapper, unknown };

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
    cvarTrack=CreateConVar("sm_track_tf2","0");
    RegConsoleCmd("ent_remove",EntityRemoved);
    AddGameLogHook(InterceptLog);

    if(!HookEvent("player_builtobject", PlayerBuiltObject))
        SetFailState("Could not hook the player_builtobject event.");

    if (GetConVarBool(cvarTrack))
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
    m_OffsetBonusProgress=FindSendPropInfo("CTFPlayer","m_iBonusProgress");
    m_OffsetBonusChallenge=FindSendPropInfo("CTFPlayer","m_iBonusChallenge");
    m_OffsetAirDash=FindSendPropInfo("CTFPlayer","m_bAirDash");
    m_OffsetMaxspeed=FindSendPropInfo("CTFPlayer","m_flMaxspeed");
    m_OffsetMyWepons=FindSendPropOffs("CTFPlayer", "m_hMyWeapons");
}

public Action:TrackVariables(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for (new client=1;client<=maxplayers;client++)
    {
        if (IsClientInGame(client))
        {
            if (IsPlayerAlive(client))
            {
                new TFClassType:tfClass = TF2_GetPlayerClass(client);
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
                new bonusProgress = m_OffsetBonusProgress>0 ? GetEntData(client,m_OffsetBonusProgress) : -99;
                new bonusChallenge = m_OffsetBonusChallenge>0 ? GetEntData(client,m_OffsetBonusChallenge) : -99;
                new airDash = m_OffsetAirDash>0 ? GetEntData(client,m_OffsetAirDash) : -99;
                new Float:maxSpeed= m_OffsetMaxspeed>0 ? GetEntDataFloat(client,m_OffsetMaxspeed) : -99.9;

                LogMessage("client=%d(%N),tfClass=%d,class=%d,cloakMeter=%f,disguiseTeam=%d,disguiseClass=%d,disguiseTarget=%d,disguiseHealth=%d,desiredDisguiseTeam=%d,desiredDisguiseClass=%d,invisChangeCompleteTime=%f,critMult=%d,stealthNoAttackExpire=%f,stealthNextChangeTime=%f,playerState=%d,numHealers=%d,playerCond=%d,poisoned=%d,wearingSuit=%d,bonusProgress=%d,bonusChallenge=%d,airDash=%d,maxSpeed=%f",client,client,tfClass,class,cloakMeter,disguiseTeam,disguiseClass,disguiseTarget,disguiseHealth,desiredDisguiseTeam,desiredDisguiseClass,invisChangeCompleteTime,critMult,stealthNoAttackExpire,stealthNextChangeTime,playerState,numHealers,playerCond,poisened,wearingSuit,bonusProgress,bonusChallenge,airDash,maxSpeed);
                PrintToChat( client,"plrState=%d,plrCond=%d,bP=%d,bC=%d,aD=%d",playerState,playerCond,bonusProgress,bonusChallenge,airDash);
            }
        }
    }
    return Plugin_Continue;
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (pressed && IsPlayerAlive(client))
    {
        decl String:wepName[128];
        new iterOffset=m_OffsetMyWepons;
        for(new y=0;y<48;y++)
        {
            new wepEnt=GetEntDataEnt(client,iterOffset);
            if(wepEnt>0&&IsValidEdict(wepEnt))
            {
                GetEdictClassname(wepEnt,wepName,sizeof(wepName));
                PrintToChat(client, wepName);
            }
            iterOffset+=4;
        }
    }
}

public Action:EntityRemoved(client,args)
{
    decl String:arg[64];
    if (GetCmdArg(1,arg,sizeof(arg)) > 0)
    {
        if (IsPlayerAlive(client))
            PrintToChat(client, "ent_remove %s", arg);
    }
    return Plugin_Continue;
}

//19:26:28 L 04/18/2008 - 19:26:32: "-=|JFH|=-Naris<3><STEAM_0:1:5037159><Red>" triggered "killedobject" (object "OBJ_SENTRYGUN") (weapon "pda_engineer") (objectowner "-=|JFH|=-Naris<3><STEAM_0:1:5037159><Red>") (attacker_position "2100 2848 -847")

public Action:InterceptLog(const String:message[])
{
    if (StrContains(message, "killedobject", true) >= 0)
    {
        new attacker = 0;
        new builder = 0;
        //decl String:buffer[5];
        decl String:object[64];
        decl String:a[64];
        decl String:b[64];
        //new Handle:re = CompileRegex("\".+<([0-9]+)><.+><.+>.*\" triggered \"killedobject\" \\(object \"([A-Z_])\"\\) .*\\(objectowner \".+<([0-9]+)><.+>\"\\)");
        new Handle:re = CompileRegex("\".+<([0-9]+)><.+><.+>.*\".* triggered \"killedobject\" .object \"([[:word:]]+)\". .*objectowner \".+<([0-9]+)><.+>\"");
        if (re != INVALID_HANDLE)
        {
            if (MatchRegex(re, message))
            {
                if (GetRegexSubString(re, 1, a, sizeof(a)))
                {
                    attacker = StringToInt(a);
                    if (GetRegexSubString(re, 2, object, sizeof(object)))
                    {
                        if (GetRegexSubString(re, 3, b, sizeof(b)))
                            builder = StringToInt(b);
                    }
                    else
                        object[0] = 0;
                }
                LogMessage("===> %d(%s) destroyed %d(%s)'s %s!", attacker, a, builder, b, object);
                //PrintToChat(attacker, "%d (%N) destroyed %d(%N)'s  %s!", attacker, attacker, builder, builder, object);
                //PrintToChat(builder, "%d (%N) destroyed %d(%N)'s  %s!", attacker, attacker, builder, builder, object);
            }
            else
                LogMessage("NO MATCH:%s", message);

            CloseHandle(re);
        }
        else
            LogMessage("Invalid Regex!");
    }
}

public PlayerBuiltObject(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    if (userid > 0)
    {
        new index=GetClientOfUserId(userid);

        //new objects:type = unknown;
        new object = GetEventInt(event,"object");

        LogMessage("player_objectbuilt: userid=%d(%d), object=%d",
                   userid, index, object);
    }
}

public OnObjectKilled(attacker, builder,const String:object[])
{
    new objects:type = unknown;
    if (StrEqual(object, "OBJ_SENTRYGUN", false))
        type = sentrygun;
    else if (StrEqual(object, "OBJ_DISPENSER", false))
        type = dispenser;
    else if (StrEqual(object, "OBJ_TELEPORTER_ENTRANCE", false))
        type = teleporter_entry;
    else if (StrEqual(object, "OBJ_TELEPORTER_EXIT", false))
        type = teleporter_exit;

    LogMessage("objectkilled: builder=%d, type=%d, object=%s",
               builder, type, object);
}

