#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Crypt Lord",
    author = "War3Source Team",
    description = "The Crypt Lord race for War3Source."
};

new thisRaceID;

new SKILL_IMPALE,SKILL_SPIKE,SKILL_BEETLES,ULT_LOCUST;

//skill 1
new Float:ImpaleChanceArr[]={0.0,0.05,0.09,0.12,0.15}; 

//skill 2
new Float:SpikeDamageRecieve[]={1.0,0.95,0.9,0.85,0.80}; //TEST
new Float:SpikeArmorGainArr[]={0.0,0.1,0.20,0.3,0.40}; 
new Float:SpikeReturnDmgArr[]={0.0,0.05,0.10,0.15,0.2}; 

//skill 3
new BeetleDamage=10;
new Float:BeetleChanceArr[]={0.0,0.05,0.1,0.15,0.20};

//ultimate
#if defined SOURCECRAFT
new Float:ultmaxdistance = 800.0;
new max_ult = 0;
#else
new Handle:ultCooldownCvar;
new Handle:ultRangeCvar;
new Handle:ultMaxCvar;
#endif
new Float:LocustDamagePercent[]={0.0,0.1,0.2,0.3,0.4};
new UltimateUsed[MAXPLAYERS+1]; 

//new String:ultimateSound[]="war3source/locustswarmloop.wav";
new String:ultimateSound[256]; //="war3source/locustswarmloop.mp3";

public OnPluginStart()
{
#if !defined SOURCECRAFT    
    ultCooldownCvar=CreateConVar("war3_crypt_locust_cooldown","20","Cooldown between ultimate usage");
    ultRangeCvar=CreateConVar("war3_crypt_locust_range","800","Range of locust ultimate");
    ultMaxCvar=CreateConVar("war3_crypt_locust_max","0","Max use of ultimate per life");
#endif
    
    LoadTranslations("w3s.race.crypt.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==80)
    {                        
#if defined SOURCECRAFT
        thisRaceID=CreateRace("crypt", .faction=UndeadScourge, .type=Undead, .required_level=64);
#else
        thisRaceID=War3_CreateNewRaceT("crypt");
#endif

        SKILL_IMPALE=War3_AddRaceSkillT(thisRaceID,"Impale",false,4);
        SKILL_SPIKE=War3_AddRaceSkillT(thisRaceID,War3_GetGame()==Game_CS?"SpikedCarapaceCS":"SpikedCarapaceTF",false,4);
        SKILL_BEETLES=War3_AddRaceSkillT(thisRaceID,"CarrionBeetles",false,4);
        ULT_LOCUST=War3_AddRaceSkillT(thisRaceID,"LocustSwarm",true,4); 

#if defined SOURCECRAFT
        // Setup upgrade costs & energy use requirements
        // Can be altered in the race config file
        SetUpgradeCost(thisRaceID, SKILL_IMPALE, 20);
        SetUpgradeEnergy(thisRaceID, SKILL_IMPALE, 2.0);

        SetUpgradeCost(thisRaceID, SKILL_SPIKE, 20);
        SetUpgradeEnergy(thisRaceID, SKILL_SPIKE, 5.0);

        SetUpgradeCost(thisRaceID, SKILL_BEETLES, 20);
        SetUpgradeEnergy(thisRaceID, SKILL_BEETLES, 1.0);

        SetUpgradeCost(thisRaceID, ULT_LOCUST, 30);
        SetUpgradeCooldown(thisRaceID, ULT_LOCUST, 20.0);
        SetUpgradeEnergy(thisRaceID, ULT_LOCUST, GetUpgradeCooldown(thisRaceID,ULT_LOCUST));

        // Get Configuration Data
        GetConfigFloatArray("chance",  ImpaleChanceArr, sizeof(ImpaleChanceArr),
                ImpaleChanceArr, thisRaceID, SKILL_IMPALE);

        GetConfigFloatArray("damage_recieve",  SpikeDamageRecieve, sizeof(SpikeDamageRecieve),
                SpikeDamageRecieve, thisRaceID, SKILL_SPIKE);

        GetConfigFloatArray("armor_gain",  SpikeArmorGainArr, sizeof(SpikeArmorGainArr),
                SpikeArmorGainArr, thisRaceID, SKILL_SPIKE);

        GetConfigFloatArray("return_damage",  SpikeReturnDmgArr, sizeof(SpikeReturnDmgArr),
                SpikeReturnDmgArr, thisRaceID, SKILL_SPIKE);

        BeetleDamage=GetConfigNum("damage", BeetleDamage, thisRaceID, SKILL_BEETLES);

        GetConfigFloatArray("chance",  BeetleChanceArr, sizeof(BeetleChanceArr),
                BeetleChanceArr, thisRaceID, SKILL_BEETLES);

        ultmaxdistance=GetConfigFloat("distance", ultmaxdistance, thisRaceID, ULT_LOCUST);

        GetConfigFloatArray("damage_percent",  LocustDamagePercent, sizeof(LocustDamagePercent),
                LocustDamagePercent, thisRaceID, ULT_LOCUST);
#endif

        War3_CreateRaceEnd(thisRaceID);    
    }

}

public OnMapStart()
{
    War3_AddSoundFolder(ultimateSound, sizeof(ultimateSound), "locustswarmloop.mp3");
    War3_AddCustomSound(ultimateSound);
}

public OnUltimateCommand(client,race,bool:pressed)
{

    if(race==thisRaceID && pressed && ValidPlayer(client,true) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_LOCUST);
        if(ult_level>0)
        {
#if !defined SOURCECRAFT
            new max_ult=GetConVarInt(ultMaxCvar);
#endif
            if(max_ult<0)
                max_ult*=-ult_level;
            if(max_ult>0 && UltimateUsed[client]>=max_ult)
            {
                PrintHintText(client,"YOU HAVE USED ALL %d LOCUST CHARGES",max_ult);
                return;
            }

            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_LOCUST,true))
            {
                new Float:posVec[3];
                GetClientAbsOrigin(client,posVec);
                new Float:otherVec[3];
                new Float:bestTargetDistance=999999.0; 
                new team = GetClientTeam(client);
                new bestTarget=0;
                
#if !defined SOURCECRAFT
                new Float:ultmaxdistance=GetConVarFloat(ultRangeCvar);
#endif
                for(new i=1;i<=MaxClients;i++)
                {
                    if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
                    {
                        GetClientAbsOrigin(i,otherVec);
                        new Float:dist=GetVectorDistance(posVec,otherVec);
                        if(dist<bestTargetDistance&&dist<ultmaxdistance)
                        {
                            bestTarget=i;
                            bestTargetDistance=GetVectorDistance(posVec,otherVec);
                            
                        }
                    }
                }
                if(bestTarget==0)
                {
                    W3MsgNoTargetFound(client,ultmaxdistance);
                }
                else
                {
                    new damage=RoundFloat(float(War3_GetMaxHP(bestTarget))*LocustDamagePercent[ult_level]);
                    if(damage>0)
                    {
                        
                        if(War3_DealDamage(bestTarget,damage,client,DMG_BULLET,"locust")) //default magic
                        {
                            W3PrintSkillDmgHintConsole(bestTarget,client,War3_GetWar3DamageDealt(),ULT_LOCUST);
                            W3FlashScreen(bestTarget,RGBA_COLOR_RED);
                            
                            W3EmitSoundToAll(ultimateSound,client);
#if defined SOURCECRAFT
                            new Float:cooldown= GetUpgradeCooldown(thisRaceID,ULT_LOCUST);
                            War3_CooldownMGR(client,cooldown,thisRaceID,ULT_LOCUST,false,true);
#else
                            War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_LOCUST,false,true);
#endif
                        }
                    }
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}




public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
    if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        if(War3_GetRace(victim)==thisRaceID)
        {
            new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_SPIKE);
            if(skill_level>0&&!Hexed(victim,false) )
            {
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(victim,thisRaceID,SKILL_SPIKE, .notify=false))
#endif
                War3_DamageModPercent(SpikeDamageRecieve[skill_level]);  
            }
        }    
    }
}
public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(!isWarcraft&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
    
        if(War3_GetRace(victim)==thisRaceID &&W3Chance(W3ChanceModifier(attacker)) )
        {
            new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_SPIKE);
            if(skill_level>0&&!Hexed(victim,false))
            {
                if(!W3HasImmunity(attacker,Immunity_Skills)){
#if defined SOURCECRAFT
                    if (CanInvokeUpgrade(victim,thisRaceID,SKILL_SPIKE, .notify=false))
                    {
#endif
                    if(War3_GetGame()==Game_CS)
                    {
                        new armor=War3_GetCSArmor(victim);
                        new armor_add=RoundFloat(damage*SpikeArmorGainArr[skill_level]);
                        if(armor_add>20) armor_add=20;
                        War3_SetCSArmor(victim,armor+armor_add);
                        
                        
                    }
                    new returndmg=RoundFloat((SpikeReturnDmgArr[skill_level] * damage));
                    returndmg=returndmg<40?returndmg:40;
                    if(GAMETF)  // Team Fortress 2 is stable with code below:
                    {
                    if(War3_DealDamage(attacker,returndmg,victim,_,"spiked_carapace",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL))
                        {
                            W3PrintSkillDmgConsole(attacker,victim,War3_GetWar3DamageDealt(),SKILL_SPIKE);
                        }
                    }
                    else // Code for CS STuff or others:
                    {
                    War3_DealDamageDelayed(attacker,victim,returndmg,"spiked_carapace",0.1,true,SKILL_SPIKE);
                    }
#if defined SOURCECRAFT
                    }
#endif
                }
            }
            
            
            skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_IMPALE);
            if(skill_level>0&&!Hexed(victim,false)&&GetRandomFloat(0.0,1.0)<=ImpaleChanceArr[skill_level])
            {
                if(W3HasImmunity(attacker,Immunity_Skills))
                {
                    PrintHintText(attacker,"%T","Blocked Impale",attacker);
                    PrintHintText(victim,"%T","Enemy Blocked Impale",victim);
                }
                else
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(victim,thisRaceID,SKILL_IMPALE, .notify=false))
#endif
                {
                    War3_ShakeScreen(attacker,2.0,50.0,40.0);
                    PrintHintText(victim,"%T","Impaled enemy",victim);
                    PrintHintText(attacker,"%T","You got impaled by enemy",attacker);
                    W3FlashScreen(attacker,{0,0,128,80});
                }
            }    
        }
        if(War3_GetRace(attacker)==thisRaceID)
        {
            new Float:chance_mod=W3ChanceModifier(attacker);
            new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BEETLES);
            if(!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=BeetleChanceArr[skill_level]*chance_mod)
            {
                if(W3HasImmunity(victim,Immunity_Skills))
                {
                    PrintHintText(victim,"%T","You blocked beetles attack",victim);
                    PrintHintText(attacker,"%T","Beetles attack was blocked",attacker);
                }
                else
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_BEETLES, .notify=false))
#endif
                {
                    
                    War3_DealDamage(victim,BeetleDamage,attacker,DMG_BULLET,"beetles");
                    W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_BEETLES);
                    W3FlashScreen(victim,RGBA_COLOR_RED);
                    
                }
            }
            skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_IMPALE);
            if(skill_level>0&&!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=ImpaleChanceArr[skill_level]*chance_mod) //spike always activates except chancemod reduction
            {
                if(W3HasImmunity(victim,Immunity_Skills)){
                    PrintHintText(victim,"%T","Blocked Impale",victim);
                    PrintHintText(attacker,"%T","Enemy Blocked Impale",attacker);
                }
                else
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_IMPALE, .notify=false))
#endif
                {
                    War3_ShakeScreen(victim,2.0,50.0,40.0);
                    PrintHintText(victim,"%T","You got impaled by enemy",victim);
                    PrintHintText(attacker,"%T","Impaled enemy",attacker);
                    W3FlashScreen(victim,{0,0,128,80});
                }
            }
        }
    }
}

// Events
public OnWar3EventSpawn(client)
{
    if(War3_GetRace(client)==thisRaceID)
        UltimateUsed[client]=0;
}
