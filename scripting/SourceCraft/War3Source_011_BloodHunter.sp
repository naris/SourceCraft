#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Race - Blood Hunter",
    author = "War3Source Team",
    description = "The Blood Hunter race for War3Source."
};

new thisRaceID;

#if !defined SOURCECRAFT
new Handle:ultCooldownCvar;
#endif

new SKILL_CRAZY, SKILL_FEAST,SKILL_SENSE,ULT_RUPTURE;

new Float:CrazyDuration[5] = {0.0, 4.0, 6.0, 8.0, 10.0};
new Float:CrazyUntil[MAXPLAYERSCUSTOM];
new bool:bCrazyDot[MAXPLAYERSCUSTOM];
new CrazyBy[MAXPLAYERSCUSTOM];

new Float:FeastAmount[5]={0.0,0.05,0.1,0.15,0.2}; 

new Float:BloodSense[5]={0.0,0.1,0.15,0.2,0.25}; 

new Float:ultRange = 300.0;
new Float:ultiDamageMultiPerDistance[5] = {0.0, 0.06, 0.073, 0.086, 0.10}; 
new Float:ultiDamageMultiPerDistanceCS[5] = {0.0, 0.09, 0.11, 0.13, 0.15}; 
new Float:lastRuptureLocation[MAXPLAYERSCUSTOM][3];
new Float:RuptureDuration = 8.0;
new Float:RuptureUntil[MAXPLAYERSCUSTOM];
new bool:bRuptured[MAXPLAYERSCUSTOM];
new RupturedBy[MAXPLAYERSCUSTOM];

new String:ultsnd[256]; //="war3source/bh/ult.mp3";

public OnPluginStart()
{
#if !defined SOURCECRAFT
    ultCooldownCvar = CreateConVar("war3_bh_ult_cooldown", "20", "Cooldown time for Ultimate.");
#endif

    CreateTimer(0.1, RuptureCheckLoop, _, TIMER_REPEAT);
    CreateTimer(0.5, BloodCrazyDOTLoop, _, TIMER_REPEAT);
    
    LoadTranslations("w3s.race.bh.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==110)
    {
#if defined SOURCECRAFT
        thisRaceID=CreateRace("bh", .faction=Hellbourne, .type=Biological, .required_level=48);
#else
        thisRaceID = War3_CreateNewRaceT("bh");
#endif

        SKILL_CRAZY = War3_AddRaceSkillT(thisRaceID, "BloodCrazy", false);
        SKILL_FEAST = War3_AddRaceSkillT(thisRaceID, "Feast", false);
        SKILL_SENSE = War3_AddRaceSkillT(thisRaceID, "BloodSense", false);
        ULT_RUPTURE = War3_AddRaceSkillT(thisRaceID, "Hemorrhage", true);

#if defined SOURCECRAFT
        // Setup upgrade costs & energy use requirements
        // Can be altered in the race config file
        SetUpgradeCost(thisRaceID, SKILL_CRAZY, 20);
        SetUpgradeEnergy(thisRaceID, SKILL_CRAZY, 1.0);

        SetUpgradeCost(thisRaceID, SKILL_FEAST, 10);
        SetUpgradeEnergy(thisRaceID, SKILL_FEAST, 1.0);

        SetUpgradeCost(thisRaceID, SKILL_SENSE, 20);
        SetUpgradeEnergy(thisRaceID, SKILL_SENSE, 1.0);

        SetUpgradeCost(thisRaceID, ULT_RUPTURE, 30);
        SetUpgradeCooldown(thisRaceID, ULT_RUPTURE, 20.0);
        SetUpgradeEnergy(thisRaceID, ULT_RUPTURE, GetUpgradeCooldown(thisRaceID,ULT_RUPTURE));

        // Get Configuration Data
        GetConfigFloatArray("duration",  CrazyDuration, sizeof(CrazyDuration),
                CrazyDuration, thisRaceID, SKILL_CRAZY);

        GetConfigFloatArray("amount",  FeastAmount, sizeof(FeastAmount),
                FeastAmount, thisRaceID, SKILL_FEAST);

        GetConfigFloatArray("percent_hp",  BloodSense, sizeof(BloodSense),
                BloodSense, thisRaceID, SKILL_SENSE);

        ultRange=GetConfigFloat("range", ultRange, thisRaceID, ULT_RUPTURE);
        RuptureDuration=GetConfigFloat("duration", RuptureDuration, thisRaceID, ULT_RUPTURE);

        if(War3_GetGame()==Game_CS)
        {
            GetConfigFloatArray("damage",  ultiDamageMultiPerDistanceCS, sizeof(ultiDamageMultiPerDistanceCS),
                    ultiDamageMultiPerDistanceCS, thisRaceID, ULT_RUPTURE);
        }
        else if(War3_GetGame()==Game_TF)
        {
            GetConfigFloatArray("damage",  ultiDamageMultiPerDistance, sizeof(ultiDamageMultiPerDistance),
                    ultiDamageMultiPerDistance, thisRaceID, ULT_RUPTURE);
        }
#endif

        War3_CreateRaceEnd(thisRaceID);
    }
}

public OnMapStart()
{
    War3_AddSoundFolder(ultsnd, sizeof(ultsnd), "bh/ult.mp3");
    War3_AddCustomSound(ultsnd);
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(race == thisRaceID && pressed && ValidPlayer(client, true))
    {
        new skill = War3_GetSkillLevel(client, race, ULT_RUPTURE);
        if(skill > 0)
        {
            if(!Silenced(client) && War3_SkillNotInCooldown(client, thisRaceID, ULT_RUPTURE, true))
            {
                new target = War3_GetTargetInViewCone(client, ultRange, false);
                if(ValidPlayer(target, true) && !W3HasImmunity(target, Immunity_Ultimates))
                {
                    bRuptured[target] = true;
                    RupturedBy[target] = client;
                    RuptureUntil[target] = GetGameTime() + RuptureDuration;
                    GetClientAbsOrigin(target, lastRuptureLocation[target]);
                    
#if defined SOURCECRAFT
                    new Float:cooldown= GetUpgradeCooldown(thisRaceID,ULT_RUPTURE);
                    War3_CooldownMGR(client,cooldown,thisRaceID,ULT_RUPTURE,true,true);
#else
                    War3_CooldownMGR(client, GetConVarFloat(ultCooldownCvar), thisRaceID, ULT_RUPTURE, true, true);
#endif

                    W3EmitSoundToAll(ultsnd,client);
                    W3EmitSoundToAll(ultsnd,target);
                    W3EmitSoundToAll(ultsnd,target);
                    PrintHintText(target, "%T", "You have been ruptured! You take damage if you move!", target);
                    PrintHintText(client, "%T", "Rupture!", client);
                }
                else
                {
                    W3MsgNoTargetFound(client, ultRange);
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

public OnWar3EventSpawn(client)
{
    bRuptured[client] = false;
    bCrazyDot[client] = false;
}

public OnWar3EventDeath(victim, attacker, deathrace)
{
    if(ValidPlayer(attacker,true))
    {
        if(War3_GetRace(attacker) == thisRaceID)
        {
            new skill = War3_GetSkillLevel(attacker, thisRaceID, SKILL_FEAST);
            if(skill > 0 && !Hexed(attacker, false))
            {
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_FEAST, .notify=false))
                {
#endif
                War3_HealToMaxHP(attacker, RoundFloat((float(War3_GetMaxHP(victim)) * FeastAmount[skill])));
                W3FlashScreen(attacker, RGBA_COLOR_GREEN, 0.3, _, FFADE_IN);
#if defined SOURCECRAFT
                }
#endif
            }
        }
    }
}

public Action:RuptureCheckLoop(Handle:h, any:data)
{
    new Float:origin[3];
    new attacker;
    new skilllevel;
    new Float:dist;
    for(new i=1;i<=MaxClients;i++)
    {
        if(!ValidPlayer(i, true) || !bRuptured[i])
        {
            continue;
        }
        
        attacker = RupturedBy[i];
        if(ValidPlayer(attacker))
        {
            if(War3_GetGame() == Game_TF)
            {
                Gore(i);
            }
            skilllevel = War3_GetSkillLevel(attacker, thisRaceID, ULT_RUPTURE);
            GetClientAbsOrigin(i,origin);
            dist=GetVectorDistance(origin, lastRuptureLocation[i]);
            
            new damage = RoundFloat((dist * (War3_GetGame() == CS ? ultiDamageMultiPerDistanceCS[skilllevel] : ultiDamageMultiPerDistance[skilllevel])));
            if(damage > 0)
            {
                if(War3_GetGame() == Game_TF)
                {
                    War3_DealDamage(i, damage, attacker, _, "rupture", _, W3DMGTYPE_TRUEDMG);
                }
                else
                {
                    if(GetClientHealth(i) > damage)
                    {
                        War3_DecreaseHP(i, damage);
                    }
                    else
                    {
                        War3_DealDamage(i, damage, attacker, _, "rupture", _, W3DMGTYPE_TRUEDMG);
                    }
                }
                War3_ShowHealthLostParticle(i);
                
                lastRuptureLocation[i][0] = origin[0];
                lastRuptureLocation[i][1] = origin[1];
                lastRuptureLocation[i][2] = origin[2];
                W3FlashScreen(i, RGBA_COLOR_RED, 1.0, _, FFADE_IN);
            }
        }
        
        if(GetGameTime() > RuptureUntil[i])
        {
            bRuptured[i] = false;
        }
    }
}
public Action:BloodCrazyDOTLoop(Handle:h,any:data)
{
    new attacker;
    for(new i=1; i <= MaxClients; i++)
    {
        if(!ValidPlayer(i, true) || !bCrazyDot[i])
        {
            continue;
        }
    
        attacker = CrazyBy[i];
        if(ValidPlayer(attacker))
        {
            if(War3_GetGame() == Game_TF)
            {
                War3_DealDamage(i, 1, attacker, _, "bleed_kill");
            }
            else
            {
                if(War3_GetGame() == Game_CS && GetClientHealth(i) > 1)
                {
                    War3_DecreaseHP(i, 1);
                }
                else
                {
                    War3_DealDamage(i, 1, attacker, _, "bloodcrazy");
                }
            }
            War3_ShowHealthLostParticle(i);
        }
        
        if(GetGameTime() > CrazyUntil[i])
        {
            bCrazyDot[i] = false;
        }
    }
}

public OnW3EnemyTakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(War3_GetRace(attacker) == thisRaceID && !Hexed(attacker, false))
    {
        new skilllevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_CRAZY);
        if(skilllevel > 0)
        {
#if defined SOURCECRAFT
            if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_CRAZY, .notify=false))
            {
#endif
            bCrazyDot[victim] = true;
            CrazyBy[victim] = attacker;
            CrazyUntil[victim] = GetGameTime() + CrazyDuration[skilllevel];
#if defined SOURCECRAFT
            }
#endif
        }
        
        skilllevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_SENSE);
        if(skilllevel > 0)
        {
            if((float(GetClientHealth(victim)) / float(War3_GetMaxHP(victim))) < BloodSense[skilllevel])
            {
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_SENSE, .notify=false))
                {
#endif
                W3FlashScreen(victim, RGBA_COLOR_RED, 0.3,_, FFADE_IN);
                War3_DamageModPercent(2.0);
                PrintToConsole(attacker, "%T", "Double Damage against low HP enemies!", attacker);
#if defined SOURCECRAFT
                }
#endif
            }
        }
    }
}

public Gore(client)
{
    WriteParticle(client, "blood_spray_red_01_far");
    WriteParticle(client, "blood_impact_red_01");
}

WriteParticle(client, String:ParticleName[])
{
    decl Float:fPos[3], Float:fAngles[3];

    fAngles[0] = GetRandomFloat(0.0, 360.0);
    fAngles[1] = GetRandomFloat(0.0, 15.0);
    fAngles[2] = GetRandomFloat(0.0, 15.0);

    GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
    fPos[2] += GetRandomFloat(35.0, 65.0);
    
    AttachThrowAwayParticle(client, ParticleName, fPos, "", 6.0, fAngles);
}
