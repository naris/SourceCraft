/**
* File: War3Source_FarSeer.sp
* Description: FarSeer for war3source.
* Author(s): Teacher, xDr.HaaaaaaaXx, Revan
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/revantools.inc"
//#include "W3SIncs/revantools"
new bool:bFaerie[66];
// War3Source stuff
new thisRaceID;

#if defined SOURCECRAFT
new Float:ult_cooldown = 15.0;
new bool:TransformSoundOn = true;
#else
new Handle:ultCooldownCvar;
new Handle:TransformSoundOn;
#endif

new bool:bBeenHit[MAXPLAYERS][MAXPLAYERS];
// Chance/Data Arrays
new Float:WebFreezeChance[5] = { 0.0, 0.18, 0.23, 0.27, 0.31 };
//new Float:EvadeChance[5] = { 0.0, 0.21, 0.25, 0.27, 0.30 };
new Float:JumpMultiplier[5] = { 1.0, 1.3, 1.6, 1.9, 2.45 };
//new Float:SpiderSpeed[5] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:PushForce[5] = { 0.0, 0.7, 1.1, 1.3, 1.7 };
new MinimumDamage[5]={10,15,18,27,38};
new MaximumDamage[5]={15,18,27,38,49};
// Sounds
//new String:ult_sound[] = "npc/strider/fire.wav";
new String:trans_sound[] = "ambient/levels/labs/teleport_winddown1.wav";
new String:trans_back[] = "npc/dog/dog_footstep_run6.wav";
new String:mark_sound[] = "bot/market.wav";
// Other
new ValveGameEnum:g_GameType;
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new BeamSprite, pfaden, GlowSprite;
new bool:bIsWolf[MAXPLAYERS];
new SKILL_FAR_SEER, SKILL_CHAINLGHT, SKILL_FERAL, ULT_QUAKE;
new Float:ChainDistance[5]={0.0,150.0,200.0,250.0,300.0};
new Float:FaerieMaxDistance[]={0.0,650.0,700.0,750.0,800.0,850.0,900.0,950.0,1000.0};
new Float:Delay[]={0.0,2.0,3.5,4.0,4.5,5.0,5.5,6.0,6.2};
public Plugin:myinfo = 
{
    name = "Far Seer",
    author = "Teacher, xDr.HaaaaaaaXx, Revan",
    description = "FarSeer for war3source.",
    version = "0.8.0.0",
    url = "www.wcs-lagerhaus.de"
};

public OnMapStart()
{
    //War3_PrecacheSound( ult_sound );
    PrecacheSound("npc/strider/fire.wav");
    War3_PrecacheSound( trans_sound );
    War3_PrecacheSound( trans_back );
    War3_PrecacheSound( mark_sound );
    BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
    pfaden = PrecacheModel( "effects/com_shield003a.vmt" );
    GlowSprite=PrecacheModel("effects/redflare.vmt");
}

public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
    m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );

    g_GameType = War3_GetGame();
    if(g_GameType==CS)
        HookEvent( "player_jump", PlayerJumpEvent );

#if !defined SOURCECRAFT
    ultCooldownCvar=CreateConVar("war3_farseer_chain_cooldown","15","Cooldown time for chain lightning.");
    TransformSoundOn=CreateConVar("war3_farseer_transform_sound","0","Enable/Disable the transforming sound?");
#endif
}

public OnWar3PluginReady()
{
#if defined SOURCECRAFT
    thisRaceID=CreateRace("farseer", .name="Far Seer", .faction=OrcishHorde, .type=Biological, .required_level=48);
#else
    thisRaceID = War3_CreateNewRace( "Far Seer", "farseer" );
#endif

    SKILL_FAR_SEER = War3_AddRaceSkill( thisRaceID, "Far Seer", "Marks a target enemy hero(ability1)", false, 4 );
    SKILL_CHAINLGHT = War3_AddRaceSkill( thisRaceID, "Chain Lightning", "Casts bolt of damaging lightning to jump at each enemy in your near.\nEach jump deals less damage.", false, 4 );   
    SKILL_FERAL = War3_AddRaceSkill( thisRaceID, "Feral Spirit", "Transforms yourself into a Spirit Wolf(ability)", false, 4 );
    ULT_QUAKE = War3_AddRaceSkill( thisRaceID, "Earthquake", "Makes the ground tremble and break, cause 50 damage and slows units down within area of effect", true, 4 );
    
#if defined SOURCECRAFT
    // Setup upgrade costs & energy use requirements
    // Can be altered in the race config file
    SetUpgradeCost(thisRaceID, SKILL_CHAINLGHT, 20);
    SetUpgradeEnergy(thisRaceID, SKILL_CHAINLGHT, 1.0);

    SetUpgradeCost(thisRaceID, SKILL_FAR_SEER, 30);
    SetUpgradeCooldown(thisRaceID, SKILL_FAR_SEER, 10.0);
    SetUpgradeEnergy(thisRaceID, SKILL_FAR_SEER, GetUpgradeCooldown(thisRaceID,SKILL_FAR_SEER));

    SetUpgradeCost(thisRaceID, SKILL_FERAL, 30);
    SetUpgradeCategory(thisRaceID, SKILL_FERAL, 2);
    SetUpgradeCooldown(thisRaceID, SKILL_FERAL, 15.0);
    SetUpgradeEnergy(thisRaceID, SKILL_FERAL, GetUpgradeCooldown(thisRaceID,SKILL_FERAL));

    ult_cooldown=GetConfigFloat("cooldown_on_invoke", ult_cooldown, thisRaceID, ULT_QUAKE);
    SetUpgradeEnergy(thisRaceID, ULT_QUAKE, ult_cooldown);
    SetUpgradeCategory(thisRaceID, ULT_QUAKE, 1);
    SetUpgradeCost(thisRaceID, ULT_QUAKE, 30);

    // Get Configuration Data
    GetConfigFloatArray("change",  WebFreezeChance, sizeof(WebFreezeChance),
                WebFreezeChance, thisRaceID, SKILL_CHAINLGHT);

    GetConfigFloatArray("distance",  ChainDistance, sizeof(ChainDistance),
                ChainDistance, thisRaceID, SKILL_CHAINLGHT);

    GetConfigFloatArray("distance",  FaerieMaxDistance, sizeof(FaerieMaxDistance),
                FaerieMaxDistance, thisRaceID, SKILL_FAR_SEER);

    TransformSoundOn=bool:GetConfigNum("sound", TransformSoundOn, thisRaceID, SKILL_FERAL);

    GetConfigFloatArray("jump_multiplier",  JumpMultiplier, sizeof(JumpMultiplier),
                JumpMultiplier, thisRaceID, SKILL_FERAL);

    GetConfigFloatArray("duration",  Delay, sizeof(Delay),
                Delay, thisRaceID, SKILL_FERAL);

    GetConfigFloatArray("force",  PushForce, sizeof(PushForce),
                PushForce, thisRaceID, ULT_QUAKE);

    GetConfigArray("damage_min",  MinimumDamage, sizeof(MinimumDamage),
            MinimumDamage, thisRaceID, ULT_QUAKE);

    GetConfigArray("damage_max",  MaximumDamage, sizeof(MaximumDamage),
            MaximumDamage, thisRaceID, ULT_QUAKE);
#endif

    W3SkillCooldownOnSpawn( thisRaceID, ULT_QUAKE, 6.0, _ );
    
    War3_CreateRaceEnd( thisRaceID );
}

public OnWar3EventSpawn(client)
{
    bFaerie[client]=false;
}

public OnGameFrame()
{
    for(new i=1;i<=MaxClients;i++){
        if(ValidPlayer(i,true))
        {
            if(bFaerie[i])
            {
                new Float:this_pos[3];
                GetClientAbsOrigin(i,this_pos);
                TE_SetupGlowSprite(this_pos,GlowSprite,0.1,1.0,90);
                TE_SendToAll();
            }
        }
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FERAL);
        if(skill_level>0)
        {
            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FERAL,true))
            {
                PrintHintText(client,"Feral Spirit : Wolf Form (Longjump)");
                bIsWolf[client]=true;

#if defined SOURCECRAFT
                if(TransformSoundOn)
#else
                if(GetConVarBool(TransformSoundOn))
#endif
                    EmitSoundToAll( trans_sound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.1 );

                CreateTimer(Delay[skill_level]+2.0, W3_TransformBackFromWolf, client);
#if defined SOURCECRAFT
                new Float:cooldown= GetUpgradeCooldown(thisRaceID,SKILL_FERAL);
                War3_CooldownMGR(client,cooldown,thisRaceID,SKILL_FERAL,_,_);
#else
                War3_CooldownMGR(client,15.0,thisRaceID,SKILL_FERAL,_,_);
#endif
            }
            
        }
        else
        {
            PrintHintText(client,"Level Your Ability First");
        }
    }
    if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FAR_SEER);
        if(skill_level>0)
        {
            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FAR_SEER,true))
            {
                new target = War3_GetTargetInViewCone(client,FaerieMaxDistance[skill_level],false,23.0);
                if(target>0)
                {
                    TE_SetupBeamFollow(target,BeamSprite,0,0.5,0.5,17.8,15,{250,250,100,255});
                    TE_SendToAll();
                    PrintHintText(client,"Far Seer: Marked Target");
                    bFaerie[target]=true;
                    EmitSoundToAll( mark_sound, target );
#if defined SOURCECRAFT
                    new Float:cooldown= GetUpgradeCooldown(thisRaceID,SKILL_FAR_SEER);
                    War3_CooldownMGR(client,cooldown,thisRaceID,SKILL_FAR_SEER,_,_);
#else
                    War3_CooldownMGR(client,10.0,thisRaceID,SKILL_FAR_SEER,_,_);
#endif
                }
                else
                {
                    PrintHintText(client,"NO VALID TARGETS WITHIN %.1f FEET",FaerieMaxDistance[skill_level]/10.0);
                }
            }
            
        }
        else
        {
            PrintHintText(client,"Level Your Ability First");
        }
    }
}

public Action:W3_TransformBackFromWolf(Handle:timer, any:client)
{      
    bIsWolf[client]=false;

    if (ValidPlayer(client, true))
    {
        PrintHintText(client,"Feral Spirit : Human Form");
        EmitSoundToAll( trans_back, client );
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(!isWarcraft && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_CHAINLGHT );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= WebFreezeChance[skill_level] )
            {
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,thisRaceID,SKILL_CHAINLGHT, .notify=false))
                {
#endif
                for(new x=0;x<65;x++)
                bBeenHit[attacker][x]=false;

                new Float:distance=ChainDistance[skill_level];
                DoChain(attacker,distance,GetRandomInt(10, 60),true,0);
                //W3Effect1( victim, "Glow3", pfaden);
#if defined SOURCECRAFT
                }
#endif
            }
        }
    }
}

public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    if(client>0&&last_target>0) {
        new target=0;
        new Float:target_dist=distance+1.0;
        new caster_team=GetClientTeam(client);
        new Float:start_pos[3];
        GetClientAbsOrigin(client,start_pos);
        GetClientAbsOrigin(last_target,start_pos);
        for(new x=1;x<=MaxClients;x++)
        {
            if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
            {
                new Float:this_pos[3];
                GetClientAbsOrigin(x,this_pos);
                new Float:dist_check=GetVectorDistance(start_pos,this_pos);
                if(dist_check<=target_dist)
                {
                    target=x;
                    target_dist=dist_check;
                }
            }
        }
        if(target<=0)
        {
            if(first_call)
            {
                W3MsgNoTargetFound(client,distance);
            }
        }
        else
        {
            bBeenHit[client][target]=true;
            War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"chainlightning");
            PrintHintText(target,"Hit by Chain Lightning -%d HP",War3_GetWar3DamageDealt());
            start_pos[2]+=30.0;
            new Float:target_pos[3];
            GetClientAbsOrigin(target,target_pos);
            target_pos[2]+=30.0;
            TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,BeamSprite,0,35,1.5,10.0,10.0,0,20.0,{20,20,255,255},40);
            TE_SendToAll();
            new new_dmg=RoundFloat(float(dmg)*0.35);
            DoChain(client,distance,new_dmg,false,target);
        }
    }
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill_long = War3_GetSkillLevel( client, race, SKILL_FERAL );
        if( skill_long > 0 && bIsWolf[client])
        {
            new Float:velocity[3] = { 0.0, 0.0, 0.0 };
            velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
            velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
            velocity[0] *= JumpMultiplier[skill_long] * 1.45;
            velocity[1] *= JumpMultiplier[skill_long] * 1.45;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
            new Float:target_pos[3];
            GetClientAbsOrigin(client,target_pos);
            TE_SetupBeamRingPoint(target_pos,10.0,300.0,BeamSprite,BeamSprite,0,0,1.0,120.0,1.0,{ 255,120,120,255},0,0);
            TE_SendToAll(0.4);
        }
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (g_GameType != Game_CS && (buttons & IN_JUMP)) // Feral Spirit for non CS games
    {
        new race = War3_GetRace( client );
        if( race == thisRaceID )
        {
            new skill_long = War3_GetSkillLevel( client, race, SKILL_FERAL );
            if( skill_long > 0 && bIsWolf[client])
            {
                new Float:velocity[3] = { 0.0, 0.0, 0.0 };
                velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
                velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
                velocity[0] *= JumpMultiplier[skill_long] * 1.45;
                velocity[1] *= JumpMultiplier[skill_long] * 1.45;
                SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
                new Float:target_pos[3];
                GetClientAbsOrigin(client,target_pos);
                TE_SetupBeamRingPoint(target_pos,10.0,300.0,BeamSprite,BeamSprite,0,0,1.0,120.0,1.0,{ 255,120,120,255},0,0);
                TE_SendToAll(0.4);
            }
        }
    }
    return Plugin_Continue;
}

/*public Action:Timer_StopSmoke(Handle:timer, Handle:pack)
{      
    ResetPack(pack);
    new SmokeEnt = ReadPackCell(pack);
    RemoveSmokeEnt(SmokeEnt);
}
RemoveSmokeEnt(target)
{
    if (IsValidEntity(target))
    {
        AcceptEntityInput(target, "Kill");
        PrintToServer("notice - rem. smokestack from far seer");
    }
}*/

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_QUAKE );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_QUAKE, true ) )
            {
                FarSeerUltimate( client );
                //UTIL_SmokeStack1Player( client );
#if !defined SOURCECRAFT
                new Float:ult_cooldown=GetConVarFloat(ultCooldownCvar);
#endif
                War3_CooldownMGR(client,ult_cooldown,thisRaceID,ULT_QUAKE,_,_);
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}

FarSeerUltimate( client )
{
    if( client > 0 && IsPlayerAlive( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_QUAKE );
        new Float:startpos[3];
        new Float:endpos[3];
        new Float:localvector[3];
        new Float:velocity[3];
        
        GetClientAbsOrigin( client, startpos );
        GetClientAbsOrigin( client, endpos );
        endpos[2]+=120.0;
        localvector[2] = endpos[2] - startpos[2];
        velocity[2] = localvector[2] * PushForce[ult_level];
        
        SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        //W3Blowup( client, client, "war3effects", 0.0);
        //CreateTesla(client,1.0,2.0,10.0,50.0,0.2,0.4,300.0,"20","45","255 255 255","npc/strider/fire.wav","effects/com_shield003a.vmt",false);
        startpos[2] += 65.0;
        //EmitSoundToAll( ult_sound, client );
        TE_SetupBeamRingPoint(startpos,10.0,300.0,pfaden,pfaden,0,0,1.0,120.0,1.0,{ 255,255,255,255},0,0);
        TE_SendToAll();
        TE_SetupBeamRingPoint(startpos,10.0,300.0,pfaden,pfaden,0,0,1.0,120.0,1.0,{ 255,255,255,255},0,0);
        TE_SendToAll(0.2);
        TE_SetupBeamRingPoint(startpos,10.0,300.0,BeamSprite,BeamSprite,0,0,1.0,120.0,1.0,{ 255,120,120,255},0,0);
        TE_SendToAll(0.4);
        TE_SetupBeamRingPoint(startpos,10.0,300.0,BeamSprite,BeamSprite,0,0,1.0,120.0,1.0,{ 255,128,20,255},0,0);
        TE_SendToAll(0.6);
        for(new x=1;x<=MaxClients;x++)
        {
            if(ValidPlayer(x,true)&&GetClientTeam(client)!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
            {
                new Float:targetpos[3];
                GetClientAbsOrigin(x,targetpos);
                new Float:dist_check=GetVectorDistance(startpos,targetpos);
                if(dist_check<=300)
                {
                    War3_ShakeScreen(x,18.0,15.0,4.5);
                    CreateFire(x,"35","4","50","normal","8",0.0,5.0);
                    //damage
                    War3_DealDamage(x,GetRandomInt(MinimumDamage[ult_level],MaximumDamage[ult_level]),client,DMG_BULLET,"earthquake");
                    targetpos[2]+=20;
                    TE_SetupBeamPoints(startpos,targetpos,BeamSprite,BeamSprite,0,20,20.0,5.0,10.0,1,1.0,{255,128,128,225},20);
                    TE_SendToAll();
                    TE_SetupGlowSprite(targetpos,GlowSprite,1.0,1.0,200);
                    TE_SendToAll();
                }
            }
        }
    }
}
