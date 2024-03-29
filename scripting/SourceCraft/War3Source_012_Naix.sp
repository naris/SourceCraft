#include <sourcemod>
#include <sdktools_functions>    //For teleport
#include <sdktools_sound>        //For sound effect
#include "W3SIncs/War3Source_Interface"

#if defined SOURCECRAFT
#include <TeleportPlayer>
#endif

public Plugin:myinfo = 
{
    name = "War3Source - Race - Naix",
    author = "War3Source Team",
    description = "The Naix Mage race for War3Source."
};

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_LIGHTGREEN 0x03
#define COLOR_GREEN 0x04 // DOD = Red //kinda already defiend in war3 interface

//Skills Settings
 
new Float:HPPercentHealPerKill[5] = { 0.0,0.05,  0.10,  0.15,  0.20 }; //SKILL_INFEST settings
//Skill 1_1 really has 5 settings, so it's not a mistake
new HPIncrease[5]       = { 0, 10, 20, 30, 40 };     //Increases Maximum health

new Float:feastPercent[5] = { 0.0, 0.04,  0.06,  0.08,  0.10 };   //Feast ratio (leech based on current victim hp

new Float:RageAttackSpeed[5] = {1.0, 1.15,  1.25,  1.3334,  1.4001 };   //Rage Attack Rate
new Float:RageDuration[5] = {0.0, 3.0,  4.0,   5.0,  6.0 };   //Rage duration

new bool:bDucking[MAXPLAYERSCUSTOM];
//End of skill Settings

#if !defined SOURCECRAFT
new Handle:ultCooldownCvar;
#endif

new thisRaceID, SKILL_INFEST, SKILL_BLOODBATH, SKILL_FEAST, ULT_RAGE;

new String:skill1snd[256]; //="war3source/naix/predskill1.mp3";
new String:ultsnd[256]; //="war3source/naix/predult.mp3";

public OnPluginStart()
{
#if !defined SOURCECRAFT
    ultCooldownCvar=CreateConVar("war3_naix_ult_cooldown","20","Cooldown time for Rage.");
#endif
    
    LoadTranslations("w3s.race.naix.phrases");
}
public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==120)
    {
#if defined SOURCECRAFT
		thisRaceID=CreateRace("naix", .faction=UndeadScourge, .type=Undead, .required_level=32);
#else
        thisRaceID=War3_CreateNewRaceT("naix");
#endif

        SKILL_INFEST = War3_AddRaceSkillT(thisRaceID, "Infest", false,4,"5-20%");
        SKILL_BLOODBATH = War3_AddRaceSkillT(thisRaceID, "BloodBath", false,4,"10-40");
        SKILL_FEAST = War3_AddRaceSkillT(thisRaceID, "Feast", false,4,"4-10%");
        ULT_RAGE = War3_AddRaceSkillT(thisRaceID, "Rage", true,4,"15-40%","3-6");
        
#if defined SOURCECRAFT
        // Setup upgrade costs & energy use requirements
        // Can be altered in the race config file
        SetUpgradeCost(thisRaceID, SKILL_INFEST, 20);
        SetUpgradeEnergy(thisRaceID, SKILL_INFEST, 1.0);

        SetUpgradeCost(thisRaceID, SKILL_BLOODBATH, 20);

        SetUpgradeCost(thisRaceID, SKILL_FEAST, 10);
        SetUpgradeEnergy(thisRaceID, SKILL_FEAST, 1.0);

        SetUpgradeCost(thisRaceID, ULT_RAGE, 30);
        SetUpgradeCooldown(thisRaceID, ULT_RAGE, 20.0);
        SetUpgradeEnergy(thisRaceID, ULT_RAGE, GetUpgradeCooldown(thisRaceID,ULT_RAGE));

        // Get Configuration Data
        GetConfigFloatArray("percent_heal",  HPPercentHealPerKill, sizeof(HPPercentHealPerKill),
                HPPercentHealPerKill, thisRaceID, SKILL_INFEST);

        GetConfigArray("amount",  HPIncrease, sizeof(HPIncrease),
                HPIncrease, thisRaceID, SKILL_INFEST);

        GetConfigFloatArray("percent",  feastPercent, sizeof(feastPercent),
                feastPercent, thisRaceID, SKILL_FEAST);

        GetConfigFloatArray("attack_speed",  RageAttackSpeed, sizeof(RageAttackSpeed),
                RageAttackSpeed, thisRaceID, ULT_RAGE);

        GetConfigFloatArray("duration",  RageDuration, sizeof(RageDuration),
                RageDuration, thisRaceID, ULT_RAGE);
#endif

        War3_CreateRaceEnd(thisRaceID);
    }
}

stock bool:IsOurRace(client) {

  return (War3_GetRace(client)==thisRaceID);
}


public OnMapStart() 
{ 
    War3_AddSoundFolder(skill1snd, sizeof(skill1snd), "naix/predskill1.mp3");
    War3_AddSoundFolder(ultsnd, sizeof(ultsnd), "naix/predult.mp3");

    War3_AddCustomSound(skill1snd);
    War3_AddCustomSound(ultsnd);
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(ValidPlayer(victim)&&W3Chance(W3ChanceModifier(attacker))&&ValidPlayer(attacker)&&IsOurRace(attacker)&&victim!=attacker){
        new level = War3_GetSkillLevel(attacker, thisRaceID, SKILL_FEAST);
        if(level>0&&!Hexed(attacker,false)&&W3Chance(W3ChanceModifier(attacker))){
            if(!W3HasImmunity(victim,Immunity_Skills)){    
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_FEAST, .notify=false))
                {
#endif
                new targetHp = GetClientHealth(victim)+ RoundToFloor(damage);
                new restore = RoundToNearest( float(targetHp) * feastPercent[level] );

                War3HealToHP(attacker,restore,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);
            
                PrintToConsole(attacker,"%T","Feast +{amount} HP",attacker,restore);
#if defined SOURCECRAFT
                }
#endif
            }
        }
    }
}
public OnWar3EventSpawn(client){
    if(IsOurRace(client)){
        new level = War3_GetSkillLevel(client, thisRaceID, SKILL_BLOODBATH);
        if(level>=0){ //zeroth level passive
            //War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,HPIncrease[level]);
            
            //War3_SetMaxHP(client, War3_GetMaxHP(client) + );
            War3_ChatMessage(client,"%T","Your Maximum HP Increased by {amount}",client,HPIncrease[level]);    
        }
    }
}
/*
public OnRaceChanged(client,oldrace,newrace)
{
    if(oldrace==thisRaceID){
        War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
    }

}*/
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    
    bDucking[client]=(buttons & IN_DUCK)?true:false;
    return Plugin_Continue;
}
//new Float:teleportTo[66][3];
public OnWar3EventDeath(victim, attacker, deathrace){
    if(ValidPlayer(victim)&&ValidPlayer(attacker)&&IsOurRace(attacker)){
        new iSkillLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_INFEST);
        if (iSkillLevel>0)
        {
            
            if (Hexed(attacker,false))  
            {    
                //decl String:name[50];
                //GetClientName(victim, name, sizeof(name));
                PrintHintText(attacker,"%T","Could not infest, you are hexed",attacker);
            }
            else if (W3HasImmunity(victim,Immunity_Skills))  
            {    
                //decl String:name[50];
                //GetClientName(victim, name, sizeof(name));
                PrintHintText(attacker,"%T","Could not infest, enemy immunity",attacker);
            }
            else{
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_INFEST, .notify=false))
                {
#endif
                
                
                if(bDucking[attacker]){
                    decl Float:location[3];
                    GetClientAbsOrigin(victim,location);
                    //.PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);
                    War3_CachedPosition(victim,location);
                    //PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);
                    
                    
                    //CreateTimer(0.1,setlocation,attacker);
                    
                    #if defined SOURCECRAFT
                    TeleportPlayer(attacker, location, NULL_VECTOR, NULL_VECTOR);
                    #else
                    TeleportEntity(attacker, location, NULL_VECTOR, NULL_VECTOR);
                    #endif
                }
                
                new addHealth = RoundFloat((float(War3_GetMaxHP(victim)) * HPPercentHealPerKill[iSkillLevel]));
                
                War3HealToHP(attacker,addHealth,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);
                //Effects?
                //EmitAmbientSound("npc/zombie/zombie_pain2.wav",location);
                W3EmitSoundToAll(skill1snd,attacker);
#if defined SOURCECRAFT
                }
#endif
            }
        }
    }
}
/*
public Action:setlocation(Handle:t,any:attacker){
    TeleportEntity(attacker, teleportTo[attacker], NULL_VECTOR, NULL_VECTOR);
}*/

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ultLevel=War3_GetSkillLevel(client,thisRaceID,ULT_RAGE);
        if(ultLevel>0)
        {    
            //PrintToChatAll("level %d %f %f",ultLevel,RageDuration[ultLevel],RageAttackSpeed[ultLevel]);
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_RAGE,true ))
            {
                War3_ChatMessage(client,"%T","You rage for {amount} seconds, {amount} percent attack speed",client,
                COLOR_LIGHTGREEN, 
                RageDuration[ultLevel],
                COLOR_DEFAULT, 
                COLOR_LIGHTGREEN, 
                (RageAttackSpeed[ultLevel]-1.0)*100.0 ,
                COLOR_DEFAULT
                );

                War3_SetBuff(client,fAttackSpeed,thisRaceID,RageAttackSpeed[ultLevel]);
                
                CreateTimer(RageDuration[ultLevel],stopRage,client);
                W3EmitSoundToAll(ultsnd,client);
                W3EmitSoundToAll(ultsnd,client);
#if defined SOURCECRAFT
                new Float:cooldown= GetUpgradeCooldown(thisRaceID,ULT_RAGE);
                War3_CooldownMGR(client,cooldown,thisRaceID,ULT_RAGE,_,_);
#else
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_RAGE,_,_);
#endif
                
            }
            
            
        }
        else{
            PrintHintText(client,"%T","No Ultimate Leveled",client);
        }

    }
}
public Action:stopRage(Handle:t,any:client){
    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
    if(ValidPlayer(client,true)){
        PrintHintText(client,"%T","You are no longer in rage mode",client);
    }
}
