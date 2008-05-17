/**
 * vim: set ai et ts=4 sw=4 :
 * File: ProtossArchon.sp
 * Description: The Protoss Archon race for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_player>
#include <tf2_cloak>
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/MindControl"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/freeze"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";

new String:archonWav[][] = { "sourcecraft/paryes00.wav" ,
                             "sourcecraft/paryes01.wav" ,
                             "sourcecraft/paryes02.wav" ,
                             "sourcecraft/paryes03.wav" };

new raceID, shockwaveID, shieldsID, feedbackID, maelstormID, controlID;

new g_lightningSprite;
new g_haloSprite;

new Handle:cvarMindControlCooldown = INVALID_HANDLE;
new Handle:cvarMaelstormCooldown = INVALID_HANDLE;

new bool:m_MindControlAvailable = false;

new bool:m_AllowMaelstorm[MAXPLAYERS+1];
new bool:m_AllowMindControl[MAXPLAYERS+1];

new m_Shields[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Protoss Archon",
    author = "-=|JFH|=-Naris",
    description = "The Protoss Archon race for SourceCraft.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    if (!HookEvent("player_spawn",PlayerSpawnEvent,EventHookMode_Post))
        SetFailState("Couldn't hook the player_spawn event.");

    cvarMaelstormCooldown=CreateConVar("sc_maelstormcooldown","45");
    cvarMindControlCooldown=CreateConVar("sc_mindcontrolcooldown","45");

    CreateTimer(3.0,Regeneration,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    m_MindControlAvailable = LibraryExists("MindControl");

    raceID      = CreateRace("Protoss Archon", "archon",
                             "You are now a Protoss Archon.",
                             "You will be a Protoss Archon when you die or respawn.",
                             -1);

    shockwaveID = AddUpgrade(raceID,"Psionic Shockwave", "shockwave",
                             "A Shockwave of Psionic Energy accompanies all attacks to increase damage up to 250%, always available.");

    shieldsID   = AddUpgrade(raceID,"Plasma Shields", "shields",
                             "You are enveloped in re-generating Plasma Shields that protect you from 10%-90% damage while it is active, always available.");

    feedbackID  = AddUpgrade(raceID,"Feedback", "feedback",
                             "Gives you 5-50% chance of reflecting a shot back to the attacker, always available.");

    maelstormID = AddUpgrade(raceID,"Maelstorm", "maelstorm", 
                             "Every enemy in 25-60 feet range will \nnot be able to move for 10 seconds.\nThey will also be decloaked, always available.",
                             true); // Ultimate

    if (m_MindControlAvailable)
    {
        controlID = AddUpgrade(raceID,"Mind Control", "mind_control",
                               "Allows you to control an object from the opposite team.",
                               true); // Ultimate
    }
    else
    {
        controlID = AddUpgrade(raceID,"Mind Control", "mind_control",
                               "Not Available", true, 99, 0); // Ultimate
    }
}

public OnMapStart()
{
    m_MindControlAvailable = LibraryExists("MindControl");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    SetupSound(rechargeWav,true,true);
    SetupSound(archonWav[0],true,true);
    SetupSound(archonWav[1],true,true);
    SetupSound(archonWav[2],true,true);
    SetupSound(archonWav[3],true,true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    m_AllowMaelstorm[client]=true;
    m_AllowMindControl[client]=true;
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (race == raceID)
        {
            new shields_level = GetUpgradeLevel(player,raceID,shieldsID);
            SetupShields(client, shields_level);

            new TFTeam:team = TFTeam:GetClientTeam(client);
            SetVisibility(player, 255, BasicVisibility, -1.0, -1.0,
                          RENDER_GLOW, RENDERFX_GLOWSHELL,
                          (team == TFTeam_Red) ? 255 : 0, 0,
                          (team == TFTeam_Blue) ? 255 : 0);
        }
        else if (oldrace == raceID)
        {
            ResetMindControlledObjects(client, false);
            SetVisibility(player, -1);
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && GetRace(player) == raceID)
    {
        if (upgrade == shieldsID)
            SetupShields(client, new_level);
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client>0)
    {
        m_AllowMaelstorm[client]=true;
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            if (GetRace(player) == raceID)
            {
                new shields_level = GetUpgradeLevel(player,raceID,shieldsID);
                SetupShields(client, shields_level);

                new TFTeam:team = TFTeam:GetClientTeam(client);
                SetVisibility(player, 255, BasicVisibility, -1.0, -1.0,
                              RENDER_GLOW, RENDERFX_GLOWSHELL,
                              (team == TFTeam_Red) ? 255 : 0, 0,
                              (team == TFTeam_Blue) ? 255 : 0);
            }
        }
    }
}

public Action:OnPlayerHurtEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                attacker_index,Handle:attacker_player,attacker_race,
                                assister_index,Handle:assister_player,assister_race,
                                damage)
{
    new bool:changed=false;
    if (victim_race == raceID)
    {
        if (assister_index && assister_index != victim_index &&
            IsPlayerAlive(attacker_index))
        {
            if (Feedback(event, damage, victim_index, victim_player,
                         attacker_index, attacker_player, assister_index))
            {
                changed = true;
            }
            else
                changed = Shields(damage, victim_index, victim_player);
        }
        else
            changed = Shields(damage, victim_index, victim_player);
    }

    if (attacker_index && attacker_index != victim_index)
    {
        new amount = 0;

        if (attacker_race == raceID)
        {
            amount = PsionicShockwave(damage, victim_index, victim_player,
                                      attacker_index, attacker_player);
            if (amount)
                changed = true;
        }

        if (amount)
            changed = true;
    }

    if (assister_index && assister_index != victim_index)
    {
        new amount = 0;
        if (assister_race == raceID)
        {
            amount = PsionicShockwave(damage, victim_index, victim_player,
                                      assister_index, assister_player);
        }

        if (amount)
            changed = true;
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_race == raceID)
    {
        // Revert back to Templar upon death.
        new templar_race = FindRace("templar");
        if (templar_race)
            ChangeRace(victim_player, templar_race, true);
    }
    return Plugin_Continue;
}

public bool:Feedback(Handle:event, damage, victim_index, Handle:victim_player,
                     attacker_index, Handle:attacker_player, assister_index)
{
    decl String:weapon[64];
    if (GetEventString(event, "weapon", weapon, sizeof(weapon)) &&
        (strcmp(weapon, "feedback") == 0 ||
         strcmp(weapon, "thorns") == 0))
    {
        // Make sure not to loop damage from feedback or thorns
        return false;
    }

    new feedback_level = GetUpgradeLevel(victim_player,raceID,feedbackID);
    new Float:percent, chance;
    switch(feedback_level)
    {
        case 0:
        {
            percent=0.10;
            chance=10;
        }
        case 1:
        {
            percent=0.25;
            chance=15;
        }
        case 2:
        {
            percent=0.40;
            chance=25;
        }
        case 3:
        {
            percent=0.50;
            chance=35;
        }
        case 4:
        {
            percent=0.75;
            chance=50;
        }
    }

    if(GetRandomInt(1,100) <= chance)
    {
        new amount=RoundToNearest(float(damage)*GetRandomFloat(percent,1.00));
        new newhp=GetClientHealth(victim_index)+amount;
        new maxhp=GetMaxHealth(victim_index);
        if (newhp > maxhp)
            newhp = maxhp;

        SetEntityHealth(victim_index,newhp);

        LogToGame("[SourceCraft] Feedback prevented damage to %N from %N!\n",
                  victim_index, attacker_index);

        if (attacker_index && attacker_index != victim_index &&
            !GetImmunity(attacker_player,Immunity_HealthTake) &&
            !TF2_IsPlayerInvuln(attacker_index))
        {
            HurtPlayer(attacker_index,amount,
                       victim_index,"feedback", "Feedback");

            new Float:Origin[3];
            GetClientAbsOrigin(attacker_index, Origin);
            Origin[2] += 5;

            TE_SetupSparks(Origin,Origin,255,1);
            TE_SendToAll();
            return true;
        }
        else
        {
            if (attacker_index && attacker_index != victim_index)
            {
                PrintToChat(victim_index,"%c[SourceCraft] you %c have %cevaded%c an attack from %N!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT, attacker_index);
                PrintToChat(attacker_index,"%c[SourceCraft] %N %c has %cevaded%c your attack!",
                            COLOR_GREEN,victim_index,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
            }
            else
            {
                PrintToChat(victim_index,"%c[SourceCraft] you %c have %cevaded%c damage!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
            }
        }

        if (assister_index)
        {
            PrintToChat(assister_index,"%c[SourceCraft] %N %c has %cevaded%c your attack!",
                        COLOR_GREEN,victim_index,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    return false;
}

bool:Shields(damage, victim_index, Handle:victim_player)
{
    new shields_level = GetUpgradeLevel(victim_player,raceID,shieldsID);
    new Float:from_percent,Float:to_percent;
    switch(shields_level)
    {
        case 0:
        {
            from_percent=0.10;
            to_percent=0.50;
        }
        case 1:
        {
            from_percent=0.20;
            to_percent=0.60;
        }
        case 2:
        {
            from_percent=0.30;
            to_percent=0.70;
        }
        case 3:
        {
            from_percent=0.40;
            to_percent=0.80;
        }
        case 4:
        {
            from_percent=0.50;
            to_percent=0.90;
        }
    }
    new amount=RoundFloat(float(damage)*GetRandomFloat(from_percent,to_percent));
    new shields=m_Shields[victim_index];
    if (amount > shields)
        amount = shields;
    if (amount > 0)
    {
        new newhp=GetClientHealth(victim_index)+amount;
        new maxhp=GetMaxHealth(victim_index);
        if (newhp > maxhp)
            newhp = maxhp;

        SetEntityHealth(victim_index,newhp);

        m_Shields[victim_index] = shields - amount;

        decl String:victimName[64];
        GetClientName(victim_index,victimName,63);

        PrintToChat(victim_index,"%c[SourceCraft] %s %cyour shields absorbed %d hp",
                    COLOR_GREEN,victimName,COLOR_DEFAULT,amount);
        return true;
    }
    return false;
}

SetupShields(client, level)
{
    switch (level)
    {
        case 0: m_Shields[client] = GetMaxHealth(client) / 2;
        case 1: m_Shields[client] = GetMaxHealth(client);
        case 2: m_Shields[client] = RoundFloat(float(GetMaxHealth(client))*1.50);
        case 3: m_Shields[client] = GetMaxHealth(client) * 2;
        case 4: m_Shields[client] = RoundFloat(float(GetMaxHealth(client))*2.50); 
    }
}

public PsionicShockwave(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new shockwave_level=GetUpgradeLevel(player,raceID,shockwaveID);
    if (!GetImmunity(victim_player,Immunity_HealthTake) &&
        !TF2_IsPlayerInvuln(victim_index))
    {
        new adj = shockwave_level*10;
        if (GetRandomInt(1,100) <= GetRandomInt(10+adj,100-adj))
        {
            new amount;
            switch(shockwave_level)
            {
                case 0: amount=damage / 2;
                case 1: amount=damage;
                case 2: amount=RoundFloat(float(damage)*1.50);
                case 3: amount=damage * 2;
                case 4: amount=RoundFloat(float(damage)*2.50);
            }
            if (amount > 0)
            {
                new newhp=GetClientHealth(victim_index)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(index, victim_index, "shockwave", "Psionic Shockwave", amount);
                }
                else
                    LogDamage(index, victim_index, "shockwave", "Psionic Shockwave", amount);

                SetEntityHealth(victim_index,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victim_index, Origin);
                Origin[2] += 5;

                TE_SetupSparks(Origin,Origin,255,1);
                TE_SendToAll();
                return amount;
            }
        }
    }
    return 0;
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (pressed && race==raceID && IsPlayerAlive(client))
    {
        new maelstorm_level=GetUpgradeLevel(player,race,maelstormID);
        if (maelstorm_level)
            Maelstorm(client,player,maelstorm_level);
        else
        {
            new control_level=GetUpgradeLevel(player,race,controlID);
            if (control_level)
                DoMindControl(client,player,control_level);
        }
    }
}

public Maelstorm(client,Handle:player, level)
{
    if (m_AllowMaelstorm[client])
    {
        new Float:range;
        switch(level)
        {
            case 0: range=350.0;
            case 1: range=400.0;
            case 2: range=650.0;
            case 3: range=750.0;
            case 4: range=900.0;
        }
        new count=0;
        new Float:indexLoc[3];
        new Float:clientLoc[3];
        GetClientAbsOrigin(client, clientLoc);
        new maxplayers=GetMaxClients();
        for (new index=1;index<=maxplayers;index++)
        {
            if (client != index && IsClientInGame(index) && IsPlayerAlive(index) &&
                GetClientTeam(index) != GetClientTeam(client))
            {
                new Handle:player_check=GetPlayerHandle(index);
                if (player_check != INVALID_HANDLE)
                {
                    if (!GetImmunity(player_check,Immunity_Uncloaking))
                    {
                        SetOverrideVisiblity(player_check, 255);
                        if (TF2_GetPlayerClass(index) == TFClass_Spy)
                        {
                            TF2_RemovePlayerDisguise(index);
                            TF2_SetPlayerCloak(index, false);

                            new Float:cloakMeter = TF2_GetCloakMeter(index);
                            if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                                TF2_SetCloakMeter(index, 0.0);

                            AuthTimer(10.0,index,RecloakPlayer);
                        }
                    }

                    if (!GetImmunity(player_check,Immunity_Ultimates) &&
                        !GetImmunity(player_check,Immunity_MotionTake))
                    {
                        GetClientAbsOrigin(index, indexLoc);
                        if (IsPointInRange(clientLoc,indexLoc,range))
                        {
                            if (TraceTarget(client, index, clientLoc, indexLoc))
                            {
                                new color[4] = { 0, 255, 0, 255 };
                                TE_SetupBeamLaser(client,index,g_lightningSprite,g_haloSprite,
                                                  0, 1, 3.0, 10.0,10.0,5,50.0,color,255);
                                TE_SendToAll();

                                PrintToChat(index,"%c[SourceCraft] %N %chas tied you down with %cMaelstorm%c",
                                            COLOR_GREEN,client,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                FreezeEntity(index);
                                AuthTimer(10.0,index,UnfreezePlayer);
                                count++;
                            }
                        }
                    }
                }
            }
        }

        new Float:cooldown = GetConVarFloat(cvarMaelstormCooldown);
        if (count)
        {
            PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cMaelstorm%c to ensnare %d enemies, you now need to wait %2.0f seconds before using it again.", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
        }
        else
        {
            PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cMaelstormd Roots%c without effect, you now need to wait %2.0f seconds before using it again.", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, cooldown);
        }

        if (cooldown > 0.0)
        {
            m_AllowMaelstorm[client]=false;
            CreateTimer(cooldown,AllowMaelstorm,client);
        }
    }
}

public Action:RecloakPlayer(Handle:timer,Handle:pack)
{
    new client=ClientOfAuthTimer(pack);
    if(client)
    {
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
            SetOverrideVisiblity(player, -1);
    }
    return Plugin_Stop;
}

public DoMindControl(client,Handle:player,level)
{
    if ( m_AllowMindControl[client] && m_MindControlAvailable)
    {
        new Float:range, percent;
        switch(level)
        {
            case 1:
            {
                range=150.0;
                percent=30;
            }
            case 2:
            {
                range=300.0;
                percent=50;
            }
            case 3:
            {
                range=450.0;
                percent=70;
            }
            case 4:
            {
                range=650.0;
                percent=90;
            }
        }

        new builder;
        new objects:type;
        if (MindControl(client, range, percent, builder, type))
        {
            new Float:cooldown = GetConVarFloat(cvarMindControlCooldown);
            LogToGame("[SourceCraft] %N has stolen %d's %s!\n",
                    client,builder,TF2_ObjectNames[type]);
            PrintToChat(builder,"%c[SourceCraft] %c %N has stolen your %s!",
                    COLOR_GREEN,COLOR_DEFAULT,client,TF2_ObjectNames[type]);
            PrintToChat(client,"%c[SourceCraft] %c You have used your ultimate %cMind Control%c to steal %N's %s, you now need to wait %2.0f seconds before using it again.!", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,builder,TF2_ObjectNames[type], cooldown);

            if (cooldown > 0.0)
            {
                m_AllowMindControl[client]=false;
                CreateTimer(cooldown,AllowMindControl,client);
            }
        }
    }
}

public Action:AllowMaelstorm(Handle:timer,any:index)
{
    m_AllowMaelstorm[index]=true;

    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        if (GetRace(GetPlayerHandle(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cMaelstorm%c is now available again!",
                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}

public Action:AllowMindControl(Handle:timer,any:index)
{
    m_AllowMindControl[index]=true;
    if (IsClientInGame(index) && IsPlayerAlive(index))
    {
        if (GetRace(GetPlayerHandle(index)) == raceID)
        {
            EmitSoundToClient(index, rechargeWav);
            PrintToChat(index,"%c[SourceCraft] %cYour your ultimate %cMind Control%c is now available again!",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }                
    return Plugin_Stop;
}

public Action:Regeneration(Handle:timer)
{
    new Float:vec[3];
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceID)
                {
                    GetClientEyePosition(client, vec);
                    EmitAmbientSound(archonWav[GetRandomInt(0,3)], vec, client);

                    new max = GetMaxHealth(client);
                    if (m_Shields[client] < max)
                        m_Shields[client] += 2;
                }
            }
        }
    }
    return Plugin_Continue;
}
