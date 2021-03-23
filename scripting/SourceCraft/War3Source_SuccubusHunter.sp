/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_SuccubusHunter.sp
 * Description: The Succubus Hunter race for War3Source.
 * Author(s): DisturbeD 
 * Adapted to TF2 by: -=|JFH|=-Naris (Murray Wilson)
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <TeleportPlayer>
#define REQUIRE_EXTENSIONS

#include "W3SIncs/War3Source_Interface"

new raceID, hunterID, totemID, assaultID, transID;
new m_iAccount = -1;

new ValveGameEnum:g_GameType;
new bool:m_IsChangingClass[MAXPLAYERS+1];
new bool:m_IsTransformed[MAXPLAYERS+1];
new skulls[MAXPLAYERS+1];
new assaultskip[MAXPLAYERS+1];

#if defined SOURCECRAFT
new SkullChance = 1;
new AssaultSkip = 2;
#else
new Handle:cvarSkullChance;
new Handle:cvarAssaultSkip;
new Handle:cvarAssaultCooldown;
new Handle:cvarTransformCooldown;
#endif

//Effects
new BeamSprite;
new Laser;

public Plugin:myinfo = 
{
    name = "Succubus Hunter",
    author = "DisturbeD",
    description = "",
    version = "3.0",
    url = "http://war3source.com/"
};

public OnMapStart()
{
    PrecacheSound("npc/fast_zombie/claw_strike1.wav");
    PrecacheModel("models/gibs/hgibs.mdl", true);
    BeamSprite=PrecacheModel("materials/sprites/purpleglow1.vmt");
    Laser=PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==130)
    {
#if defined SOURCECRAFT
        raceID=CreateRace("succubus", .name="Succubus Hunter",
                          .required_level=80, .faction=Hellbourne, .type=Undead,
                          .switch_message="You transformed into a Succubus Hunter.",
                          .pending_message="Night is approaching: You will awake as a Succubus Hunter when you die.");
#else
        raceID=War3_CreateNewRace("Succubus Hunter", "succubus");
#endif

        hunterID = War3_AddRaceSkillT(raceID, "HeadHunter", false,_,"0-20%");
        totemID = War3_AddRaceSkillT(raceID, "TIncantation", false);
        assaultID = War3_AddRaceSkillT(raceID, "ATackle", false);
        transID = War3_AddRaceSkillT(raceID, "DTransformation", true);

#if defined SOURCECRAFT
        // Setup upgrade costs & energy use requirements
        // Can be altered in the race config file
        SetUpgradeCost(raceID, totemID, 10);

        SetUpgradeCost(raceID, hunterID, 20);
        SetUpgradeEnergy(raceID, hunterID, 1.0);

        SetUpgradeCost(raceID, assaultID, 20);
        SetUpgradeCooldown(raceID, assaultID, 2.0);
        SetUpgradeEnergy(raceID, assaultID, GetUpgradeCooldown(raceID,assaultID));

        SetUpgradeCost(raceID, transID, 30);
        SetUpgradeCooldown(raceID, transID, 20.0);
        SetUpgradeEnergy(raceID, transID, GetUpgradeCooldown(raceID,transID));

        // Get Configuration Data
        SkullChance=GetConfigNum("chance", SkullChance, raceID, hunterID);
        AssaultSkip=GetConfigNum("skip", AssaultSkip, raceID, assaultID);
#endif

        War3_CreateRaceEnd(raceID);
    }
}

public OnPluginStart()
{
    g_GameType = War3_GetGame();
    switch (g_GameType)
    {
        case Game_CS:
        {
            HookEvent("player_jump",PlayerJumpEvent);

            FindSendPropInfo("CCSPlayer", "m_iAccount", .local_offset=m_iAccount);
        }
        case Game_TF:
        {
			HookEvent("player_changeclass",PlayerChangeClassEvent);
			HookEvent("teamplay_teambalanced_player",PlayerChangeClassEvent);

			HookEvent("arena_round_start",RoundStartEvent,EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_start",RoundStartEvent,EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_active",RoundStartEvent,EventHookMode_PostNoCopy);

			FindSendPropInfo("CTFPlayer", "m_nCurrency", .local_offset=m_iAccount);
        }
    }

    AddCommandListener(SayCommand, "say");
    AddCommandListener(SayCommand, "say_team");

#if !defined SOURCECRAFT
    cvarSkullChance=CreateConVar("war3_succ_skull_chance","1","Chance per death for Succubus to gain a skill if GetRandomInt(1..n) <= level");
    cvarAssaultSkip=CreateConVar("war3_succ_assault_skip","2","Skip factor for Succubus's Assault Tackle");
    cvarAssaultCooldown=CreateConVar("war3_succ_assault_cooldown","2.0","Cooldown for Succubus Assault Tackle");
    cvarTransformCooldown=CreateConVar("war3_succ_ult_cooldown","20.0","Cooldown for Succubus ultimate");
#endif

    LoadTranslations("w3s.race.succubus.phrases");
}

public OnWar3EventSpawn(client)
{
    new race=War3_GetRace(client); 
    if (race==raceID) 
    {
        new totem_level=War3_GetSkillLevel(client,race,totemID); 
        if (totem_level>0 && !m_IsChangingClass[client])
        {
            new maxhp = War3_GetMaxHP(client);
            new hp, dollar, xp; 
            switch(totem_level)
            {
                case 1: 
                {
                    hp=RoundToNearest(float(maxhp) * 0.01);
                    dollar=25;
                    xp=1;
                }
                case 2: 
                {
                    hp=RoundToNearest(float(maxhp) * 0.01);
                    dollar=30;
                    xp=2;
                }
                case 3: 
                {
                    hp=RoundToNearest(float(maxhp) * 0.02);
                    dollar=35;
                    xp=3;
                }
                case 4:
                {
                    hp=RoundToNearest(float(maxhp) * 0.02);
                    dollar=50;
                    xp=5;
                }
            }

            hp *= skulls[client];
            dollar *= skulls[client];
            xp *= skulls[client];

            new old_health=GetClientHealth(client);
            SetEntityHealth(client,old_health+hp);

            new old_XP = War3_GetXP(client,raceID);
            new kill_XP = W3GetKillXP(War3_GetLevel(client,raceID));
            if (xp > kill_XP)
                xp = kill_XP;

            War3_SetXP(client,raceID,old_XP+xp);

            if (m_iAccount>0) //game with money
            {
                War3_AddCurrency(client, dollar);
                PrintToChat(client,"%T","[Totem Incanation] You gained {amount} HP, {amount} dollars and {amount} XP",client,0x04,0x01,hp,dollar,xp);
            }
            else
            {
                new max = W3GetMaxGold();
                new old_credits=War3_GetGold(client);
                if (old_credits < max)
                {
                    dollar /= max;
                    new new_credits = old_credits + dollar;
                    if (new_credits > max)
                        new_credits = max;

                    War3_SetGold(client,new_credits);
                    new_credits = War3_GetGold(client);

                    if (new_credits > 0)
                        dollar = new_credits-old_credits;
                }

                PrintToChat(client,"%T","[Totem Incanation] You gained {amount} HP, {amount} credits and {amount} XP",client,0x04,0x01,hp,dollar,xp);
            }
        }

        m_IsTransformed[client]=false;
        m_IsChangingClass[client]=false;

        War3_SetBuff(client,fMaxSpeed,raceID,1.0);
        War3_SetBuff(client,fLowGravitySkill,raceID,1.0);   

        #if defined SOURCECRAFT
            HudMessage(client, "Skulls: %d", skulls[client]);
        #endif
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(!isWarcraft && ValidPlayer(victim, true, true) && ValidPlayer(attacker) && victim != attacker)
    {
        if (War3_GetRace(attacker)==raceID)
        {
            // Head Hunter
            new hunter_level = War3_GetSkillLevel(attacker,raceID,hunterID);
            if (hunter_level > 0 && damage > 0.0 &&
                !W3HasImmunity(victim,Immunity_PhysicalDamage) &&
                !W3HasImmunity(victim,Immunity_Skills) &&
                !Hexed(attacker))
            {
#if defined SOURCECRAFT
                if (CanInvokeUpgrade(attacker,raceID,hunterID, .notify=false))
                {
#endif
                new xdamage = 0;
                if (W3IsDamageFromMelee(weapon))
                {
                    new Float:percent;
                    switch(hunter_level)
                    {
                        case 1: percent=0.20;
                        case 2: percent=0.40;
                        case 3: percent=0.60;
                        case 4: percent=0.80;
                    }
                    xdamage= RoundFloat(damage * percent);

                    new Float:vec[3];
                    GetClientAbsOrigin(attacker,vec);
                    vec[2]+=50.0;
                    TE_SetupGlowSprite(vec, BeamSprite, 2.0, 10.0, 5);
                    TE_SendToAll();
                }
                else
                {
                    new percent;
                    switch (hunter_level)
                    {
                        case 1: percent=10;
                        case 2: percent=15;
                        case 3: percent=20;
                        case 4: percent=30;
                    }
                    if(GetRandomInt(1,100)<=percent)
                    {
                        xdamage = RoundFloat(0.2 * damage * skulls[attacker] / 20);
                    }
                }

                if (xdamage>0.0)
                {
                    War3_DealDamage(victim, xdamage, attacker,_,"headhunter",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL);
                    W3PrintSkillDmgConsole(victim,attacker,War3_GetWar3DamageDealt(),hunterID);
                }
#if defined SOURCECRAFT
                }
#endif
            }
        }
    }
}

public OnWar3EventDeath(victim, attacker, deathrace)
{
    #define DMG_CRITS       1048576    //crits = DAMAGE_ACID

    static const String:tf2_decap_weapons[][] = { "sword",   "club",      "axtinguisher",
                                                  "fireaxe", "battleaxe", "tribalkukri",
                                                  "headhunter"};

    if (ValidPlayer(victim) && ValidPlayer(attacker) && victim != attacker)
    {
        if (War3_GetRace(attacker) == raceID)
        {
            // Head Hunter
            new hunter_level=War3_GetSkillLevel(attacker,raceID,hunterID);
            if (hunter_level && !Hexed(attacker))
            {
                new bool:headshot;
                new Handle:event = W3GetVar(SmEvent);
                switch (g_GameType)
                {
                    case Game_CS:
                    {
                        headshot = GetEventBool(event, "headshot");
                    }
                    case Game_TF:
                    {
                        // Don't count dead ringer fake deaths
                        if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) == 0)
                        {
                            // Check for headshot or backstab
                            new customkill = GetEventInt(event, "customkill");
                            headshot = (customkill == 1 || customkill == 2);
                        }
                    }
                    case Game_DOD:
                    {
                        headshot = false;
                    }
                }

                new bool:decap = false;
                if (g_GameType == Game_TF)
                {
                    decl String:weapon[128];
                    GetEventString(event, "weapon", weapon, sizeof(weapon));

                    for (new i = 0; i < sizeof(tf2_decap_weapons); i++)
                    {
                        if (StrEqual(weapon,tf2_decap_weapons[i],false))
                        {
                            decap = ((GetEventInt(event, "damagebits") & DMG_CRITS) != 0);
                            break;
                        }
                    }
                }
                else
                    decap = false;

#if !defined SOURCECRAFT
                new SkullChance = GetConVarInt(cvarSkullChance);
#endif
                if (headshot || decap || GetRandomInt(1,SkullChance)<=hunter_level)
                {
                    decl Float:Origin[3], Float:Direction[3];
                    GetClientAbsOrigin(victim, Origin);
                    Direction[0] = GetRandomFloat(-1.0, 1.0);
                    Direction[1] = GetRandomFloat(-1.0, 1.0);
                    Direction[2] = 500.0;
                    Gib(Origin, Direction, "models/gibs/hgibs.mdl");

                    if (skulls[attacker]<(5*hunter_level))
                    {
                        skulls[attacker]++;
                        War3_ChatMessage(attacker,"%T","You gained a SKULL [{amount}/{amount}]",attacker,skulls[attacker],(5*hunter_level));

#if defined SOURCECRAFT
                        HudMessage(attacker, "Skulls: %d", skulls[attacker]);
#endif
                    }
                }
            }
        }
    }
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));
    new race=War3_GetRace(client);
    if (race==raceID)
    {
        new assault_level=War3_GetSkillLevel(client,race,assaultID);
        if (assault_level>0)
        {
            assaultskip[client]--;
            if(assaultskip[client]<1||War3_SkillNotInCooldown(client,raceID,assaultID)&&!Hexed(client))
            {
                new Float:velocity[3];
                GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
                velocity[0]*=float(assault_level)*0.20;
                velocity[1]*=float(assault_level)*0.20;
                SetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

                new bool:weaponFound=false;
                new color[4]={0,25,255,200};
                if(GetClientTeam(client)==TEAM_RED) // TEAM_T
                {
                    color[0]=255;
                    color[2]=0;
                }

                if (m_IsTransformed[client])
                    color[1] = 100;

                decl String:wpnstr[32];
                GetClientWeapon(client, wpnstr, sizeof(wpnstr));
                for(new slot=0;slot<10;slot++)
                {
                    new wpn=GetPlayerWeaponSlot(client, slot);
                    if (wpn>0)
                    {
                        //PrintToChatAll("wpn %d",wpn);
                        new String:comparestr[32];
                        GetEdictClassname(wpn, comparestr, 32);
                        //PrintToChatAll("%s %s",wpn, comparestr);
                        if(StrEqual(wpnstr,comparestr,false))
                        {
                            TE_SetupKillPlayerAttachments(wpn);
                            TE_SendToAll();
                            
                            TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
                            TE_SendToAll();
                            weaponFound=true;
                            break;
                        }
                    }
                }

                if (!weaponFound)
                {
                    TE_SetupKillPlayerAttachments(client);
                    TE_SendToAll();

                    TE_SetupBeamFollow(client,Laser,0,0.5,2.0,7.0,1,color);
                    TE_SendToAll();
                }

#if defined SOURCECRAFT
                assaultskip[client]+=AssaultSkip;

                new Float:cooldown= GetUpgradeCooldown(raceID,assaultID);
#else
                assaultskip[client]+=GetConVarInt(cvarAssaultSkip);

                new Float:cooldown = GetConVarFloat(cvarAssaultCooldown);
#endif
                if (cooldown > 0.0)
                    War3_CooldownMGR(client,cooldown,raceID,assaultID,_,false);
            }
        }
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (g_GameType != Game_CS && (buttons & IN_JUMP)) //assault for non CS games
    {
        if (War3_GetRace(client) == raceID)
        {
            new assault_level=War3_GetSkillLevel(client,raceID,assaultID);
            if (assault_level>0 && !Hexed(client) && War3_SkillNotInCooldown(client,raceID,assaultID))
            {
                decl Float:velocity[3];
                GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

                if (!(GetEntityFlags(client) & FL_ONGROUND))
                {
                    new Float:absvel = velocity[0];
                    if (absvel < 0.0)
                        absvel *= -1.0;

                    if (velocity[1] < 0.0)
                        absvel -= velocity[1];
                    else
                        absvel += velocity[1];

                    new Float:maxvel = m_IsTransformed[client] ? 1000.0 : 500.0;
                    if (absvel > maxvel)
                        return Plugin_Continue;
                }

                if (TF2_HasTheFlag(client))
                    return Plugin_Continue;

                new Float:amt = 1.0 + (float(assault_level)*0.20);
                velocity[0]*=amt;
                velocity[1]*=amt;
                TeleportPlayer(client, NULL_VECTOR, NULL_VECTOR, velocity);

#if defined SOURCECRAFT
                new Float:cooldown= GetUpgradeCooldown(raceID,assaultID);
#else
                new Float:cooldown = GetConVarFloat(cvarAssaultCooldown);
#endif
                if (cooldown > 0.0)
                    War3_CooldownMGR(client,cooldown,raceID,assaultID,_,false);

                if (!War3_IsCloaked(client))
                {
                    new bool:weaponFound=false;
                    new color[4]={0,25,255,200};
                    if(GetClientTeam(client)==TEAM_RED) // TEAM_T
                    {
                        color[0]=255;
                        color[2]=0;
                    }

                    if (m_IsTransformed[client])
                        color[1] = 100;

                    new String:wpnstr[32];
                    GetClientWeapon(client, wpnstr, sizeof(wpnstr));
                    for(new slot=0;slot<10;slot++)
                    {
                        new wpn=GetPlayerWeaponSlot(client, slot);
                        if (wpn>0)
                        {
                            //PrintToChatAll("wpn %d",wpn);
                            new String:comparestr[32];
                            GetEdictClassname(wpn, comparestr, 32);
                            //PrintToChatAll("%s %s",wpn, comparestr);
                            if(StrEqual(wpnstr,comparestr,false))
                            {
                                TE_SetupKillPlayerAttachments(wpn);
                                TE_SendToAll();
                                
                                TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
                                TE_SendToAll();
                                weaponFound=true;
                                break;
                            }
                        }
                    }

                    if (!weaponFound)
                    {
                        TE_SetupKillPlayerAttachments(client);
                        TE_SendToAll();

                        TE_SetupBeamFollow(client,Laser,0,0.5,2.0,7.0,1,color);
                        TE_SendToAll();
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public OnClientPutInServer(client)
{
    skulls[client] = 0;
    m_IsTransformed[client]=false;
    m_IsChangingClass[client]=false;

    War3_SetBuff(client,fMaxSpeed,raceID,1.0);
    War3_SetBuff(client,fLowGravitySkill,raceID,1.0);   
}

public OnRaceChanged(client,newrace)
{
    if (newrace==raceID)
    {
        if (m_IsTransformed[client])
        {
            War3_SetBuff(client,fMaxSpeed,raceID,1.0);
            War3_SetBuff(client,fLowGravitySkill,raceID,1.0);   
        }

        #if defined SOURCECRAFT
            ClearHud(client, "Skulls");
        #endif
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(pressed && race==raceID && ValidPlayer(client,true))
    {
        new trans_level=War3_GetSkillLevel(client,raceID,transID);
        if (trans_level>0) // Deamonic Transformation
        {
            if (War3_SkillNotInCooldown(client,raceID,transID,true))
            {
                if (skulls[client] < trans_level)
                {
                    new required = trans_level - skulls[client];
                    PrintCenterText(client,"INSUFFICIENT SKULLS, %d MORE REQUIRED", required);
                    PrintToChat(client,"%T","[Daemonic transformation] You do not have enough skulls: {amount} more required",client,0x04,0x01,required);
                }
                else
                {
                    m_IsTransformed[client]=true;
                    skulls[client] -= trans_level;

                    War3_SetBuff(client,fMaxSpeed,raceID,float(trans_level)/5.00+1.00);
                    War3_SetBuff(client,fLowGravitySkill,raceID,1.00-float(trans_level)/5.00);

                    new old_health=GetClientHealth(client);
                    SetEntityHealth(client,old_health+trans_level*10);

                    PrintToChat(client,"%T","[Daemonic transformation] Your daemonic powers boost your strength",client,0x04,0x01);
                    CreateTimer(10.0,FinishTrans,GetClientUserId(client));

#if defined SOURCECRAFT
                    new Float:cooldown= GetUpgradeCooldown(raceID,transID);
#else
                    new Float:cooldown = GetConVarFloat(cvarTransformCooldown);
#endif
                    if (cooldown > 0.0)
                        War3_CooldownMGR(client,cooldown,raceID,transID);
                }
            }
        }
    }
}

public Action:FinishTrans(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    if (m_IsTransformed[client] && ValidPlayer(client))
    {
        m_IsTransformed[client]=false;
        War3_SetBuff(client,fMaxSpeed,raceID,1.0);
        War3_SetBuff(client,fLowGravitySkill,raceID,1.0);

        if (IsPlayerAlive(client))
        {
            PrintToChat(client,"%T","[Daemonic transformation] You transformed back to normal",client,0x04,0x01);
        }
    }
}

stock Gib(Float:Origin[3], Float:Direction[3], String:Model[])
{
    if (!IsEntLimitReached(.message="Unable to create gibs"))
    {
        new Ent = CreateEntityByName("prop_physics");
        if (Ent > 0 && IsValidEntity(Ent))
        {
            DispatchKeyValue(Ent, "model", Model);
            SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 1); 
            DispatchSpawn(Ent);
            TeleportEntity(Ent, Origin, Direction, Direction);
            CreateTimer(GetRandomFloat(15.0, 30.0), RemoveGib,
                        EntIndexToEntRef(Ent));
        }
        else
            LogError("Unable to create gibs!");
    }
}

public Action:RemoveGib(Handle:Timer, any:Ref)
{
    new Ent = EntRefToEntIndex(Ref);
    if (Ent > 0 && IsValidEdict(Ent))
    {
        AcceptEntityInput(Ent, "kill");
    }
}

/**
 * Detect when changing classes in TF2
 */

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new index=1;index<=MaxClients;index++)
    {
        m_IsChangingClass[index]=false;
        m_IsTransformed[index]=false;
    }
}

public Action:PlayerChangeClassEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    if (client > 0 && War3_GetRace(client) == raceID)
    {
        if (IsPlayerAlive(client))
        {
            m_IsChangingClass[client] = true;
            m_IsTransformed[client]=false;
        }
    }
    return Plugin_Continue;
}

public Action:SayCommand(client, const String:command[], argc)
{
    if (client > 0 && IsClientInGame(client))
    {
        decl String:text[128];
        GetCmdArg(1,text,sizeof(text));

        decl String:arg[2][64];
        ExplodeString(text, " ", arg, 2, 64);

        new String:firstChar[] = " ";
        firstChar[0] = arg[0][0];
        if (StrContains("!/\\",firstChar) >= 0)
            strcopy(arg[0], sizeof(arg[]), arg[0][1]);

        if (StrEqual(arg[0],"skulls"))
        {
            new hunter_level = (War3_GetRace(client)==raceID) ? War3_GetSkillLevel(client,raceID,hunterID) : 0;
            if (hunter_level)
                War3_ChatMessage(client,"You have (%d/%d) \x04SKULL\x01s.",skulls[client],(5*hunter_level));
            else
                War3_ChatMessage(client,"You have %d \x04SKULL\x01s.",skulls[client]);

            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 */
#tryinclude <entlimit>
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
        new max = GetMaxEntities();
        new count = GetEntityCount();
        new remaining = max - count;
        if (remaining <= warn)
        {
            if (count <= critical)
            {
                PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
                LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            else
            {
                PrintToServer("Caution: Entity count is getting high!");
                LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            return count;
        }
        else
            return 0;
    }
#endif
