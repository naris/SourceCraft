#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Soul Reaper",
    author = "War3Source Team",
    description = "The Soul Reaper race for War3Source."
};

new thisRaceID;

#if !defined SOURCECRAFT
new Handle:ultCooldownCvar;
#endif

new SKILL_JUDGE, SKILL_PRESENCE,SKILL_INHUMAN, ULT_EXECUTE;


// Chance/Data Arrays
new JudgementAmount[5]={0,10,20,30,40};
new Float:JudgementCooldownTime=10.0;
new Float:JudgementRange=200.0;

new Float:PresenseAmount[5]={0.0,0.5,1.0,1.5,2.0}; 
new Float:PresenceRange=400.0;

new InhumanAmount[5]={0,5,10,15,20};
new Float:InhumanRange=400.0;

new Float:ultRange=300.0;
new Float:ultiDamageMulti[5]={0.0,0.4,0.6,0.8,1.0};

new String:judgesnd[256]; //="war3source/sr/judgement.mp3";
new String:ultsnd[256]; //="war3source/sr/ult.mp3";

public OnPluginStart()
{
    HookEvent("player_death",PlayerDeathEvent);
    
#if !defined SOURCECRAFT
    ultCooldownCvar=CreateConVar("war3_sr_ult_cooldown","20","Cooldown time for CD ult overload.");
#endif
    
    LoadTranslations("w3s.race.sr.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==100)
    {
#if defined SOURCECRAFT
        thisRaceID=CreateRace("sr", .faction=Hellbourne, .type=Demonic, .required_level=32);
#else
        thisRaceID=War3_CreateNewRaceT("sr");
#endif
        SKILL_JUDGE=War3_AddRaceSkillT(thisRaceID,"Judgement",false,4);
        SKILL_PRESENCE=War3_AddRaceSkillT(thisRaceID,"WitheringPresence",false,4);
        SKILL_INHUMAN=War3_AddRaceSkillT(thisRaceID,"InhumanNature",false,4);
        ULT_EXECUTE=War3_AddRaceSkillT(thisRaceID,"DemonicExecution",true,4); 

#if defined SOURCECRAFT
        // Setup upgrade costs & energy use requirements
        // Can be altered in the race config file
        SetUpgradeCost(thisRaceID, SKILL_PRESENCE, 20);
        SetUpgradeEnergy(thisRaceID, SKILL_PRESENCE, 1.0);

        SetUpgradeCost(thisRaceID, SKILL_INHUMAN, 10);
        SetUpgradeEnergy(thisRaceID, SKILL_INHUMAN, 1.0);

        SetUpgradeCost(thisRaceID, SKILL_JUDGE, 30);
        SetUpgradeCategory(thisRaceID, SKILL_JUDGE, 2);
        SetUpgradeCooldown(thisRaceID, SKILL_JUDGE, JudgementCooldownTime);
        JudgementCooldownTime = GetUpgradeCooldown(thisRaceID,SKILL_JUDGE);
        SetUpgradeEnergy(thisRaceID, SKILL_JUDGE, JudgementCooldownTime);

        SetUpgradeCost(thisRaceID, ULT_EXECUTE, 30);
        SetUpgradeCategory(thisRaceID, ULT_EXECUTE, 1);
        SetUpgradeCooldown(thisRaceID, ULT_EXECUTE, 20.0);
        SetUpgradeEnergy(thisRaceID, ULT_EXECUTE, GetUpgradeCooldown(thisRaceID,ULT_EXECUTE));

        // Get Configuration Data
        JudgementRange=GetConfigFloat("range", JudgementRange, thisRaceID, SKILL_JUDGE);

        GetConfigArray("amount",  JudgementAmount, sizeof(JudgementAmount),
                JudgementAmount, thisRaceID, SKILL_JUDGE);

        PresenceRange=GetConfigFloat("range", PresenceRange, thisRaceID, SKILL_PRESENCE);

        GetConfigArray("amount",  PresenseAmount, sizeof(PresenseAmount),
                PresenseAmount, thisRaceID, SKILL_PRESENCE);

        InhumanRange=GetConfigFloat("radius", InhumanRange, thisRaceID, SKILL_INHUMAN);

        GetConfigArray("amount",  InhumanAmount, sizeof(InhumanAmount),
                InhumanAmount, thisRaceID, SKILL_INHUMAN);

        ultRange=GetConfigFloat("range", ultRange, thisRaceID, ULT_EXECUTE);

        GetConfigFloatArray("damage",  ultiDamageMulti, sizeof(ultiDamageMulti),
                ultiDamageMulti, thisRaceID, ULT_EXECUTE);
#endif

        War3_CreateRaceEnd(thisRaceID);

        War3_AddAuraSkillBuff(thisRaceID, SKILL_PRESENCE, fHPDecay, PresenseAmount, 
                              "witheringpresense", PresenceRange, 
                              true);
        
    }
}

public OnMapStart()
{
    War3_AddSoundFolder(judgesnd, sizeof(judgesnd), "sr/judgement.mp3");
    War3_AddSoundFolder(ultsnd, sizeof(ultsnd), "sr/ult.mp3");

    War3_AddCustomSound(judgesnd);
    War3_AddCustomSound(ultsnd);
}



public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_JUDGE);
        if(skill_level>0)
        {
            
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_JUDGE,true))
            {
                new amount=JudgementAmount[skill_level];
                
                new Float:playerOrigin[3];
                GetClientAbsOrigin(client,playerOrigin);
                
                new team = GetClientTeam(client);
                new Float:otherVec[3];
                for(new i=1;i<=MaxClients;i++){
                    if(ValidPlayer(i,true)){
                        GetClientAbsOrigin(i,otherVec);
                        if(GetVectorDistance(playerOrigin,otherVec)<JudgementRange)
                        {
                            if(GetClientTeam(i)==team){
                                War3_HealToMaxHP(i,amount);
                            }
                            else{
                                War3_DealDamage(i,amount,client,DMG_BURN,"judgement",W3DMGORIGIN_SKILL);
                            }
                            
                        }
                    }
                }
                PrintHintText(client,"%T","+/- {amount} HP",client,amount);
                W3EmitSoundToAll(judgesnd,client);
                //EmitSoundToAll(judgesnd,client);
                War3_CooldownMGR(client,JudgementCooldownTime,thisRaceID,SKILL_JUDGE,true,true);
                
            }
        }
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        //if(
        
        new skill=War3_GetSkillLevel(client,race,ULT_EXECUTE);
        if(skill>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_EXECUTE,true))
            {
                new target=War3_GetTargetInViewCone(client,ultRange,false);
                if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
                {

                    new hpmissing=War3_GetMaxHP(target)-GetClientHealth(target);
                    
                    new dmg=RoundFloat(FloatMul(float(hpmissing),ultiDamageMulti[skill]));
                    
                    if(War3_DealDamage(target,dmg,client,_,"demonicexecution"))
                    {
                        PrintToConsole(client,"T%","Executed for {amount} damage",client,War3_GetWar3DamageDealt());

#if defined SOURCECRAFT
                        new Float:cooldown= GetUpgradeCooldown(thisRaceID,ULT_EXECUTE);
                        War3_CooldownMGR(client,cooldown,thisRaceID,ULT_EXECUTE,true,true);
#else
                        War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_EXECUTE,true,true);
#endif
                    
                        W3EmitSoundToAll(ultsnd,client);
                        
                        W3EmitSoundToAll(ultsnd,target);
                    }
                }
                else
                {
                    W3MsgNoTargetFound(client,ultRange);
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new victim=GetClientOfUserId(userid);
    
    if(victim>0)
    {
        new Float:deathvec[3];
        GetClientAbsOrigin(victim,deathvec);
        
        new Float:gainhpvec[3];
        
        for(new client=1;client<=MaxClients;client++)
        {
            if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
                GetClientAbsOrigin(client,gainhpvec);
                if(GetVectorDistance(deathvec,gainhpvec)<InhumanRange){
                    new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INHUMAN);
                    if(skilllevel>0&&!Hexed(client)){
#if defined SOURCECRAFT
                        if (CanInvokeUpgrade(client,thisRaceID,SKILL_INHUMAN, .notify=false))
#endif
                        War3_HealToMaxHP(client,InhumanAmount[skilllevel]);
                    }
                }
            }
        }
        //new deathFlags = GetEventInt(event, "death_flags");
    // where is the list of flags? idksee firefox
        //if (War3_GetGame()==Game_TF&&deathFlags & 32)
        //{
           //PrintToChat(client,"war3 debug: dead ringer kill");
        //}

        
    }
}
