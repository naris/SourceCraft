

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?
new thisRaceID;

new Handle:ultCooldownCvar;

new Float:TeleportDistance[5]={0.0,300.0,350.0,400.0,450.0};
new Float:obediencechance[5]={0.0,0.05,0.10,0.15,0.20};
new SKILL_HEAL;
new SKILL_GRAVITY;
stock ULT_TELEPORT;
new SKILL_MAGIC_OBEDIENCE;

new GENERIC_SKILL_TELEPORT;

new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new bool:inteleportcheck[MAXPLAYERSCUSTOM];

//new String:teleportSound[]="war3source/blinkarrival.wav";
new String:teleportSound[256];

new Float:HealAmount[5]={0.0,0.5,1.0,1.5,2.0};
new Float:Gravity[5] = {1.0, 0.85, 0.7, 0.6, 0.5};
new AuraID;
public Plugin:myinfo = 
{
    name = "Race - Twilight SPARKELLLLEEEE",
    author = "Ownz",
    description = "",
    version = "1.0",
    url = "http://war3source.com"
};

public OnPluginStart()
{
    
    ultCooldownCvar=CreateConVar("war3_twilight_teleport_cd","5.0","Cooldown between teleports");
    
    LoadTranslations("w3s.race.human.phrases");
    War3_AddSoundFolder(teleportSound, sizeof(teleportSound), "blinkarrival.mp3");
}

public OnMapStart()
{
    War3_AddCustomSound(teleportSound);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 1)
    {
        GENERIC_SKILL_TELEPORT=War3_CreateGenericSkill("g_teleport");
    }
    else if(num==240)
    {

        
#if defined SOURCECRAFT
        thisRaceID=CreateRace("twilight", .name="Twilight Sparkle", .faction=Pony, .type=Biological, .required_level=16);
#else
        thisRaceID=War3_CreateNewRace("Twilight Sparkle (TEST)","twilight");
#endif
        
        
        new Handle:genericSkillOptions=CreateArray(5,2); //block size, 5 can store an array of 5 cells
        SetArrayArray(genericSkillOptions,0,TeleportDistance,sizeof(TeleportDistance));
        SetArrayCell(genericSkillOptions,1,ultCooldownCvar);
        //ULT_TELEPORT=
        War3_UseGenericSkill(thisRaceID,"g_teleport",genericSkillOptions,"Teleport","Short range teleport");
        ///neal
        SKILL_HEAL=War3_AddRaceSkill(thisRaceID,"Connected","Global heal 2HP per second",false,4); 
        AuraID=W3RegisterAura("twilight_heal_global",999999.9);
        
        //magic obedience
        SKILL_MAGIC_OBEDIENCE=War3_AddRaceSkill(thisRaceID,"Magic Obedience","5-20% chance of silencing your enemy (on attack)",false,4); 
        SKILL_GRAVITY = War3_AddRaceSkill(thisRaceID, "Gravity","Reduces your gravity", false, 4);
        
        War3_CreateRaceEnd(thisRaceID);

        War3_AddSkillBuff(thisRaceID, SKILL_GRAVITY, fLowGravitySkill, Gravity);
    }
}
public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID)
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,inAura?HealAmount[level]:0.0);
        //DP("%d %f",inAura,HealingWaveAmountArr[level]);
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{   

    if(race==thisRaceID &&skill==SKILL_HEAL) //1
    {
            W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
    }
}



public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(!isWarcraft && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
    if(War3_GetRace(attacker)==thisRaceID){
        new level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_MAGIC_OBEDIENCE);
        if(level){
            if(W3Chance(obediencechance[level]*W3ChanceModifier(attacker))  && !Hexed(attacker) &&!W3HasImmunity(victim,Immunity_Skills) ){
                W3ApplyBuffSimple(victim,bSilenced,thisRaceID,true,2.0); 
                new String:name[33];
                GetClientName(victim,name,sizeof(name));
                PrintHintText(attacker,"You silenced %s",name);

                GetClientName(attacker,name,sizeof(name));
                PrintHintText(victim,"%s silenced you",name);
            }
        }
    }
    }
}

new TPFailCDResetToRace[MAXPLAYERSCUSTOM];
new TPFailCDResetToSkill[MAXPLAYERSCUSTOM];

public OnUltimateCommand(client,race,bool:pressed)
{
    //DP("ult pressed");
    if( pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new Handle:genericSkillOptions;
        new Float:distances[5];
        new customerrace,customerskill;
    
        new level=W3_GenericSkillLevel(client,GENERIC_SKILL_TELEPORT,genericSkillOptions,customerrace,customerskill);
        //DP("level CUSrace CUSskill %d %d %d",level,customerrace,customerskill);
        if(level)
        {
            GetArrayArray(genericSkillOptions,    0,distances);
            new Float:cooldown=GetConVarFloat(GetArrayCell(genericSkillOptions,1));
            //DP("cool %f",cooldown);
            if(War3_SkillNotInCooldown(client,customerrace,customerskill,true)) //not in the 0.2 second delay when we check stuck via moving
            {
                new bool:success = Teleport(client,distances[level]);
                if(success)
                {
                    TPFailCDResetToRace[client]=customerrace;
                    TPFailCDResetToSkill[client]=customerskill;
                    //new Float:cooldown=GetConVarFloat(ultCooldownCvar);
                    War3_CooldownMGR(client,cooldown,customerrace,customerskill,_,_);
                }
            }
        
        }
        else if(War3_GetRace(client)==customerrace)
        {
            W3MsgUltNotLeveled(client);
        }
    }

}

//Teleportation

bool:Teleport(client,Float:distance)
{
    if(!inteleportcheck[client])
    {
        
        new Float:angle[3];
        GetClientEyeAngles(client,angle);
        new Float:endpos[3];
        new Float:startpos[3];
        GetClientEyePosition(client,startpos);
        new Float:dir[3];
        GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
        
        ScaleVector(dir, distance);
        
        AddVectors(startpos, dir, endpos);
        
        GetClientAbsOrigin(client,oldpos[client]);
        
        
        ClientTracer=client;
        TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
        TR_GetEndPosition(endpos);
        
        if(enemyImmunityInRange(client,endpos)){
            W3MsgEnemyHasImmunity(client);
            return false;
        }
        
        new Float:distanceteleport=GetVectorDistance(startpos,endpos);
        if(distanceteleport<200.0){
            new String:buffer[100];
            Format(buffer, sizeof(buffer), "%T", "Distance too short.", client);
            PrintHintText(client,buffer);
            return false;
        }
        GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
        ScaleVector(dir, distanceteleport-33.0);
        
        AddVectors(startpos,dir,endpos);
        emptypos[0]=0.0;
        emptypos[1]=0.0;
        emptypos[2]=0.0;
        
        endpos[2]-=30.0;
        getEmptyLocationHull(client,endpos);
        
        if(GetVectorLength(emptypos)<1.0){
            new String:buffer[100];
            Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
            PrintHintText(client,buffer);
            return false; //it returned 0 0 0
        }
        
        
        TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
        EmitSoundToAll(teleportSound,client);
        EmitSoundToAll(teleportSound,client);
        
        
        
        teleportpos[client][0]=emptypos[0];
        teleportpos[client][1]=emptypos[1];
        teleportpos[client][2]=emptypos[2];
        
        inteleportcheck[client]=true;
        CreateTimer(0.14,checkTeleport,client);
        
        
        
        
        
        
        return true;
    }

    return false;
}
public Action:checkTeleport(Handle:h,any:client){
    inteleportcheck[client]=false;
    new Float:pos[3];
    
    GetClientAbsOrigin(client,pos);
    
    if(GetVectorDistance(teleportpos[client],pos)<0.001)//he didnt move in this 0.1 second
    {
        TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
        PrintHintText(client,"%T","CantTeleportHere",client);
        War3_CooldownReset(client,TPFailCDResetToRace[client],TPFailCDResetToSkill[client]);
        
        
    }
    else{
        
        
        PrintHintText(client,"%T","Teleported",client);
        
    }
}
public bool:AimTargetFilter(entity,mask)
{
    return !(entity==ClientTracer);
}


new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
    
    
    new Float:mins[3];
    new Float:maxs[3];
    GetClientMins(client,mins);
    GetClientMaxs(client,maxs);
    
    new absincarraysize=sizeof(absincarray);
    
    new limit=5000;
    for(new x=0;x<absincarraysize;x++){
        if(limit>0){
            for(new y=0;y<=x;y++){
                if(limit>0){
                    for(new z=0;z<=y;z++){
                        new Float:pos[3]={0.0,0.0,0.0};
                        AddVectors(pos,originalpos,pos);
                        pos[0]+=float(absincarray[x]);
                        pos[1]+=float(absincarray[y]);
                        pos[2]+=float(absincarray[z]);
                        
                        TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
                        //new ent;
                        if(!TR_DidHit(_))
                        {
                            AddVectors(emptypos,pos,emptypos); ///set this gloval variable
                            limit=-1;
                            break;
                        }
                        
                        if(limit--<0){
                            break;
                        }
                    }
                    
                    if(limit--<0){
                        break;
                    }
                }
            }
            
            if(limit--<0){
                break;
            }
            
        }
        
    }
    
} 

public bool:CanHitThis(entityhit, mask, any:data)
{
    if(entityhit == data )
    {// Check if the TraceRay hit the itself.
        return false; // Don't allow self to be hit, skip this result
    }
    if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
        return false; //skip result, prend this space is not taken cuz they on same team
    }
    return true; // It didn't hit itself
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
    //ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
    new Float:otherVec[3];
    new team = GetClientTeam(client);
    
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
        {
            GetClientAbsOrigin(i,otherVec);
            if(GetVectorDistance(playerVec,otherVec)<350)
            {
                return true;
            }
        }
    }
    return false;
}             

    
