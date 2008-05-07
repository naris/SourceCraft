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
#define REQUIRE_EXTENSIONS

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/freeze"
#include "sc/log"

new String:rechargeWav[] = "sourcecraft/transmission.wav";

new raceID, immunityID, shieldsID, feedbackID, maelstormID;

new bool:m_AllowMaelstorm[MAXPLAYERS+1];
new Handle:cvarMaelstormCooldown = INVALID_HANDLE;

new g_lightningSprite;
new g_haloSprite;

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

    cvarMaelstormCooldown=CreateConVar("sc_entangledrootscooldown","45");
}

public OnPluginReady()
{
    raceID      = CreateRace("Protoss Archon", "archon",
                             "You are now a Protoss Archon.",
                             "You will be a Protoss Archon when you die or respawn.");

    immunityID  = AddUpgrade(raceID,"Immunity", "immunity",
                             "Makes you Immune to: Decloaking at Level 1,\nMotion Taking at Level 2,\nCrystal Theft at level 3,\nand ShopItems at Level 4.");

    shieldsID   = AddUpgrade(raceID,"Plasma Shields", "shields", "You are enveloped in re-generating Plasma Shields that protect you from damage.");

    feedbackID  = AddUpgrade(raceID,"Feedback", "feedback",
                             "Gives you 5-50% chance of reflecting a shot back to the attacker.");

    maelstormID = AddUpgrade(raceID,"Maelstorm", "maelstorm", 
                             "Every enemy in 25-60 feet range will \nnot be able to move for 10 seconds.\nThey will also be decloaked",
                             true); // Ultimate
}

public OnMapStart()
{
    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt", true);
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");

    g_haloSprite = SetupModel("materials/sprites/halo01.vmt", true);
    if (g_haloSprite == -1)
        SetFailState("Couldn't find halo Model");

    SetupSound(rechargeWav,true,true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
    m_AllowMaelstorm[client]=true;
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            m_TeleportCount[client]=0;
            ResetMaxHealth(client);

            // Turn off Immunities
            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,false);
        }
        else if (race == raceID)
        {
            // Turn on Immunities
            new immunity_level=GetUpgradeLevel(player,race,immunityID);
            if (immunity_level)
                DoImmunity(client, player, immunity_level,true);

            new shields_level = GetUpgradeLevel(player,raceID,shieldsID);
            if (shields_level)
                SetupShields(client, shield_level);
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && new_level > 0 && GetRace(player) == raceID)
    {
        if (upgrade == immunityID)
            DoImmunity(client, player, new_level,true);
        else if (upgrade == shieldsID)
            SetupShields(client, new_level);
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new index=GetClientOfUserId(userid);
    if (index>0)
    {
        m_AllowMaelstorm[index]=true;
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            if (GetRace(player) == raceID)
            {
                new immunity_level=GetUpgradeLevel(player,raceID,immunityID);
                if (immunity_level)
                    DoImmunity(client, player, immunity_level,true);

                new shields_level = GetUpgradeLevel(player,raceID,shieldsID);
                if (shields_level)
                    SetupShields(client, shields_level);
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
        if (Feedback(damage, victim_index, victim_player,
                     attacker_index, assister_index))
        {
            changed = true;
        }
        else
            changed = Shields(damage, victim_index, victim_player);
    }

    if (attacker_index && attacker_index != victim_index)
    {
        new amount = 0;

        if (attacker_race == raceID)
        {
            amount = TrueshotAura(damage, victim_index, victim_player,
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
            amount = TrueshotAura(damage, victim_index, victim_player,
                                  assister_index, assister_player);
        }

        if (amount)
            changed = true;
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public bool:Feedback(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    new feedback_level = GetUpgradeLevel(victim_player,raceID,feedbackID);
    if (feedback_level)
    {
        new chance;
        switch(feedback_level)
        {
            case 1: chance=15;
            case 2: chance=25;
            case 3: chance=35;
            case 4: chance=50;
        }

        if(GetRandomInt(1,100) <= chance)
        {
            new newhp=GetClientHealth(victim_index)+damage;
            new maxhp=GetMaxHealth(victim_index);
            if (newhp > maxhp)
                newhp = maxhp;

            SetEntityHealth(victim_index,newhp);

            LogToGame("[SourceCraft] Feedback prevented damage to %N from %N!\n",
                      victim_index, attacker_index);

            if (attacker_index && attacker_index != victim_index &&
                !GetImmunity(player,Immunity_HealthTake) &&
                !TF2_IsPlayerInvuln(index))
            {
                new newhp=GetClientHealth(index)-damage;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(victim_index, index, "feedback", "Feedback", damage);
                }
                else
                    LogDamage(victim_index, index, "feedback", "Feedback", damage);

                SetEntityHealth(index,newhp);

                new Float:Origin[3];
                GetClientAbsOrigin(victim_index, Origin);
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
    }
    return false;
}

bool:Shields(damage, victim_index, Handle:victim_player)
{
    new shields_level = GetUpgradeLevel(victim_player,raceID,shieldsID);
    if (shields_level)
    {
        new Float:from_percent,Float:to_percent;
        switch(shields_level)
        {
            case 1:
            {
                from_percent=0.0;
                to_percent=0.10;
            }
            case 2:
            {
                from_percent=0.0;
                to_percent=0.30;
            }
            case 3:
            {
                from_percent=0.10;
                to_percent=0.60;
            }
            case 4:
            {
                from_percent=0.20;
                to_percent=0.80;
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
    }
    return false;
}

DoImmunity(client, Handle:player, level, bool:value)
{
    if (level >= 1)
    {
        SetImmunity(player,Immunity_Uncloaking,value);
        if (level >= 2)
        {
            SetImmunity(player,Immunity_MotionTake,value);
            if (level >= 3)
            {
                SetImmunity(player,Immunity_Theft,value);
                if (level >= 4)
                    SetImmunity(player,Immunity_ShopItems,value);
            }
        }

        if (value)
        {
            new Float:start[3];
            GetClientAbsOrigin(client, start);

            new color[4] = { 0, 255, 50, 128 };
            TE_SetupBeamRingPoint(start,30.0,60.0,g_lightningSprite,g_lightningSprite,
                                  0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
            TE_SendToAll();
        }
    }
}

SetupShields(client, level)
{
    switch (level)
    {
        case 0: m_Shields[client] = 0;
        case 1: m_Shields[client] = GetMaxHealth(client) / 4;
        case 2: m_Shields[client] = GetMaxHealth(client) / 3;
        case 3: m_Shields[client] = GetMaxHealth(client) / 2;
        case 4: m_Shields[client] = GetMaxHealth(client); 
    }
}

public TrueshotAura(damage, victim_index, Handle:victim_player, index, Handle:player)
{
    // Trueshot Aura
    new trueshot_level=GetUpgradeLevel(player,raceID,trueshotID);
    if (trueshot_level &&
        !GetImmunity(victim_player,Immunity_HealthTake) &&
        !TF2_IsPlayerInvuln(victim_index))
    {
        if (GetRandomInt(1,100) <= GetRandomInt(30,60))
        {
            new Float:percent;
            switch(trueshot_level)
            {
                case 1:
                    percent=0.20;
                case 2:
                    percent=0.35;
                case 3:
                    percent=0.60;
                case 4:
                    percent=0.80;
            }

            new amount=RoundFloat(float(damage)*percent);
            if (amount > 0)
            {
                new newhp=GetClientHealth(victim_index)-amount;
                if (newhp <= 0)
                {
                    newhp=0;
                    LogKill(index, victim_index, "trueshot_aura", "Trueshot Aura", amount);
                }
                else
                    LogDamage(index, victim_index, "trueshot_aura", "Trueshot Aura", amount);

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
    if (race==raceID && pressed && IsPlayerAlive(client) &&
        m_AllowMaelstorm[client])
    {
        new ult_level=GetUpgradeLevel(player,race,rootsID);
        if(ult_level)
        {
            new Float:range=1.0;
            switch(ult_level)
            {
                case 1:
                    range=300.0;
                case 2:
                    range=450.0;
                case 3:
                    range=650.0;
                case 4:
                    range=800.0;
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
                PrintToChat(client,"%c[SourceCraft]%c You have used your ultimate %cMaelstormd Roots%c to ensnare %d enemies, you now need to wait %2.0f seconds before using it again.", COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, count, cooldown);
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
