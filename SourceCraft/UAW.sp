/**
 * vim: set ai et ts=4 sw=4 :
 * File: UAW.sp
 * Description: The UAW race for SourceCraft.
 * Author(s): -=|JFH|=-Naris (Murray Wilson) 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include "hgrsource.inc"

#include "sc/SourceCraft"
#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/maxhealth"
#include "sc/respawn"
#include "sc/log"

new String:explodeWav[] = "weapons/explode5.wav";

new raceID, wageID, seniorityID, negotiationID, hookID, ropeID;

new explosionModel;
new g_purpleGlow;

// Reincarnation variables
new bool:m_JobsBank[MAXPLAYERS+1];
new bool:m_TeleportOnSpawn[MAXPLAYERS+1];
new Float:m_SpawnLoc[MAXPLAYERS+1][3];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - UAW",
    author = "-=|JFH|=-Naris (Murray Wilson)",
    description = "The UAW race for War3Source.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    SetupRespawn();
    return true;
}

public OnPluginStart()
{
    GetGameType();
    HookEvent("player_spawn",PlayerSpawnEvent);
    CreateTimer(10.0,Negotiations,INVALID_HANDLE,TIMER_REPEAT);
}

public OnPluginReady()
{
    raceID          = CreateRace("UAW", "uaw",
                                 "You have joined the UAW.",
                                 "You will join the UAW when you die or respawn.",
                                 16);

    wageID          = AddUpgrade(raceID,"Inflated Wages", "wages",
                                 "You get paid more and level faster.");

    seniorityID     = AddUpgrade(raceID,"Seniority", "seniority",
                                 "Gives you a 15-80% chance of immediately respawning where you died.");

    negotiationID = AddUpgrade(raceID,"Negotiations", "negotiations",
                               "Various good and not so good things happen at random intervals\nYou might get or lose money or experience, you might also die\n (However, you will no longer ever lose levels or XP)!");

    hookID        = AddUpgrade(raceID,"Work Rules", "hook",
                               "Use your ultimate bind to hook a line to a wall and traverse it.",
                               true); // Ultimate

    ropeID        = AddUpgrade(raceID,"Swing Shift", "rope",
                               "Use your ultimate swing from a rope.",
                               true); // Ultimate

    ControlHookGrabRope(true);
}

public OnMapStart()
{
    g_purpleGlow = SetupModel("materials/sprites/purpleglow1.vmt", true);
    if (g_purpleGlow == -1)
        SetFailState("Couldn't find purpleglow Model");

    if (GameType == tf2)
    {
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt", true);
        if (explosionModel == -1)
            SetFailState("Couldn't find Explosion Model");
    }
    else
    {
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt", true);
        if (explosionModel == -1)
            SetFailState("Couldn't find Explosion Model");
    }

    SetupSound(explodeWav, true, true);
}

public OnPlayerAuthed(client,Handle:player)
{
    FindMaxHealthOffset(client);
}

public OnXPGiven(client,Handle:player,&amount)
{
    if (GetRace(player)==raceID && IsPlayerAlive(client))
    {
        new inflated_wages_level=GetUpgradeLevel(player,raceID,wageID);
        if (inflated_wages_level)
        {
            switch(inflated_wages_level)
            {
                case 1:
                    amount=RoundToNearest(float(amount)*1.5);
                case 2:
                    amount=RoundToNearest(float(amount)*2.0);
                case 3:
                    amount=RoundToNearest(float(amount)*2.5);
                case 4:
                    amount=RoundToNearest(float(amount)*3.0);
            }
        }
    }
}

public OnCreditsGiven(client,Handle:player,&amount)
{
    if (GetRace(player)==raceID && IsPlayerAlive(client))
    {
        new inflated_wages_level=GetUpgradeLevel(player,raceID,wageID);
        if (inflated_wages_level)
        {
            switch(inflated_wages_level)
            {
                case 1:
                    amount *= 2;
                case 2:
                    amount *= 3;
                case 3:
                    amount *= 4;
                case 4:
                    amount *= 5;
            }
        }
    }
}

public OnUltimateCommand(client,Handle:player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
        {
            if (GetUpgradeLevel(player,race,hookID))
                Hook(client);
            else if (GetUpgradeLevel(player,race,ropeID))
                Rope(client);
        }
        else
        {
            if (GetUpgradeLevel(player,race,hookID))
                UnHook(client);
            else if (GetUpgradeLevel(player,race,ropeID))
                Detach(client);
        }
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new Handle:player=GetPlayerHandle(client);
        if (player != INVALID_HANDLE)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new hook_level=GetUpgradeLevel(player,race,hookID);
                if (hook_level)
                    SetupHook(client, player, hook_level);
                else
                {
                    new rope_level=GetUpgradeLevel(player,race,ropeID);
                    if (rope_level)
                        SetupRope(client, player, rope_level);
                }

                if (m_TeleportOnSpawn[client])
                {
                    m_TeleportOnSpawn[client]=false;
                    TeleportEntity(client,m_SpawnLoc[client], NULL_VECTOR, NULL_VECTOR);
                    TE_SetupGlowSprite(m_SpawnLoc[client],g_purpleGlow,1.0,3.5,150);
                    TE_SendToAll();
                }
                else
                {
                    GetClientAbsOrigin(client,m_SpawnLoc[client]);

                    if (m_JobsBank[client])
                    {
                        m_JobsBank[client]=false;
                        TE_SetupGlowSprite(m_SpawnLoc[client],g_purpleGlow,1.0,3.5,150);
                        TE_SendToAll();
                        PrintToChat(client,"%c[SourceCraft]%c Due to %cSeniority%c, you have joined the %cJobs Bank%c",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                    }
                }
            }
        }
    }
}

public Action:OnPlayerDeathEvent(Handle:event,victim_index,Handle:victim_player,victim_race,
                                 attacker_index,Handle:attacker_player,attacker_race,
                                 assister_index,Handle:assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    if (victim_race == raceID)
    {
        new seniority_level=GetUpgradeLevel(victim_player,raceID,seniorityID);
        if (seniority_level)
        {
            new buyout, jobsBank, sheltered;
            switch (seniority_level)
            {
                case 1:
                {
                    sheltered=5;
                    jobsBank=7;
                    buyout=9;
                }
                case 2:
                {
                    sheltered=10;
                    jobsBank=15;
                    buyout=22;
                }
                case 3:
                {
                    sheltered=20;
                    jobsBank=30;
                    buyout=50;
                }
                case 4:
                {
                    sheltered=35;
                    jobsBank=50;
                    buyout=63;
                }
            }
            new chance = GetRandomInt(1,100);
            if (chance<=sheltered)
            {
                PrintToChat(victim_index,"%c[SourceCraft]%c You have been sheltered from an attack due to %cSeniority%c!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                if (attacker_index && attacker_index != victim_index)
                {
                    PrintToChat(attacker_index,"%c[SourceCraft]%c %N has been sheltered from your attack due to %cSeniority%c!",
                                COLOR_GREEN,COLOR_DEFAULT,victim_index,COLOR_TEAM,COLOR_DEFAULT);
                }

                if (assister_index && assister_index != victim_index)
                {
                    PrintToChat(assister_index,"%c[SourceCraft]%c %N has been sheltered from your attack due to %cSeniority%c!",
                                COLOR_GREEN,COLOR_DEFAULT,victim_index,COLOR_TEAM,COLOR_DEFAULT);
                }

                m_TeleportOnSpawn[victim_index]=true;
                GetClientAbsOrigin(victim_index,m_SpawnLoc[victim_index]);
                AuthTimer(0.5,victim_index,RespawnPlayerHandle);
            }
            else if (chance<=jobsBank)
            {
                m_JobsBank[victim_index]=true;
                AuthTimer(0.5,victim_index,RespawnPlayerHandle);
            }
            else if (chance<=buyout)
            {
                // No monetary limit on UAW Buyout offers!
                new amount = GetRandomInt(1,100);
                SetCredits(victim_player, GetCredits(victim_player)+amount);
                PrintToChat(victim_index,"%c[SourceCraft]%c Due to %cSeniority%c, you have recieved %d crystals from a %cBuyout%c offer!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,amount,COLOR_TEAM,COLOR_DEFAULT);
            }
        }
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=MAXPLAYERS;x++)
    {
        m_TeleportOnSpawn[x]=false;
        m_JobsBank[x]=false;
    }
}

public OnRaceSelected(client,Handle:player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            TakeHook(client);
            TakeRope(client);
        }
        else if (race == raceID)
        {
            m_JobsBank[client]=false;
            m_TeleportOnSpawn[client]=false;

            new hook_level=GetUpgradeLevel(player,race,hookID);
            if (hook_level)
                SetupHook(client, player, hook_level);
            else
            {
                new rope_level=GetUpgradeLevel(player,race,ropeID);
                if (rope_level)
                    SetupRope(client, player, rope_level);
            }
        }
    }
}

public OnUpgradeLevelChanged(client,Handle:player,race,upgrade,old_level,new_level)
{
    if (race == raceID && GetRace(player) == raceID)
    {
        if (upgrade==hookID)
            SetupHook(client, player, new_level);
        else if (upgrade==ropeID)
            SetupRope(client, player, new_level);
    }
}

public SetupHook(client, Handle:player, level)
{
    if (level)
    {
        new duration, Float:range, Float:cooldown;
        switch(level)
        {
            case 1:
            {
                duration=5;
                range=150.0;
                cooldown=20.0;
            }
            case 2:
            {
                duration=10;
                range=300.0;
                cooldown=15.0;
            }
            case 3:
            {
                duration=20;
                range=450.0;
                cooldown=10.0;
            }
            case 4:
            {
                duration=30;
                range=0.0;
                cooldown=5.0;
            }
        }
        TakeRope(client);
        GiveHook(client,duration,range,cooldown,0);
    }
    else
        TakeHook(client);
}

public SetupRope(client, Handle:player, level)
{
    if (level)
    {
        new duration, Float:range, Float:cooldown;
        switch(level)
        {
            case 1:
            {
                duration=5;
                range=150.0;
                cooldown=20.0;
            }
            case 2:
            {
                duration=10;
                range=300.0;
                cooldown=15.0;
            }
            case 3:
            {
                duration=20;
                range=450.0;
                cooldown=10.0;
            }
            case 4:
            {
                duration=0;
                range=0.0;
                cooldown=0.0;
            }
        }
        TakeHook(client);
        GiveRope(client,duration,range,cooldown,0);
    }
    else
        TakeRope(client);
}

public Action:Negotiations(Handle:timer)
{
    new maxplayers=GetMaxClients();
    for(new client=1;client<=maxplayers;client++)
    {
        if(IsClientInGame(client))
        {
            if (IsPlayerAlive(client))
            {
                new Handle:player=GetPlayerHandle(client);
                if(player != INVALID_HANDLE && GetRace(player) == raceID)
                {
                    new negotiations_level=GetUpgradeLevel(player,raceID,negotiationID);
                    if (negotiations_level)
                    {
                        new percent;
                        switch(negotiations_level)
                        {
                            case 1:
                                percent=10;
                            case 2:
                                percent=25;
                            case 3:
                                percent=35;
                            case 4:
                                percent=50;
                        }
                        if (GetRandomInt(1,100) <= percent)
                        {
                            /*Negotiations:
                             * Overtime/Premium Pay/Shift differential/COLA/Profit Sharing/Bonus - Get Money
                             * Grievance/Shop Steward/Arbitration/Collective Bargaining/Fringe Benefits - Get XP
                             * Boycott/Strike/Picketing (you teleport back to spawn)
                             * Lockout/Workforce Reduction (you die)
                             * Forced Buyout (you die and get money for XP and Level)
                             * Bankruptcy (you die & lose level & XP)
                             */
                            // No monetary limit on UAW Money!
                            switch(GetRandomInt(1,41) % 30)
                            {
                                case 1: // Overtime
                                    AddCredits(client, player, GetRandomInt(1,10), "Overtime");
                                case 2: // Premium Pay
                                    AddCredits(client, player, GetRandomInt(1,10), "Premium Pay");
                                case 3: // Shift Differential 
                                    AddCredits(client, player, GetRandomInt(1,10), "Shift Differential Pay");
                                case 4: // COLA 
                                    AddCredits(client, player, GetRandomInt(1,10), "COLA");
                                case 5: // Profit Sharing 
                                    AddCredits(client, player, GetRandomInt(1,10), "Profit Sharing");
                                case 6: // Bonus
                                    AddCredits(client, player, GetRandomInt(1,10), "Bonus");
                                case 7: // Grievance
                                {
                                    new amount = GetRandomInt(1,10);
                                    ResetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have filed a %cGrievance%c and recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 8: // Shop Steward
                                {
                                    new amount = GetRandomInt(1,10);
                                    ResetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have been made a %cShop Steward%c and recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 9: // Arbitration
                                {
                                    new amount = GetRandomInt(1,10);
                                    ResetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c Due to %cArbitration%c, you have recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 10: // Collective Bargaining
                                {
                                    new amount = GetRandomInt(1,10);
                                    ResetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c Due to %cCollective Bargaining%c, you have recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 11: // Fringe Benefits
                                {
                                    new amount = GetRandomInt(1,10);
                                    ResetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You are entitled to %cFringe Benefits%c of %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 12: // Boycott
                                {
                                    PrintToChat(client,"%c[SourceCraft]%c The union has ordered that you %cBoycott%c this action!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    AuthTimer(0.5,client,RespawnPlayerHandle);
                                }
                                case 13: // Strike
                                {
                                    PrintToChat(client,"%c[SourceCraft]%c The union has gone on %cStrike%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    AuthTimer(0.5,client,RespawnPlayerHandle);
                                }
                                case 14: // Picketing
                                {
                                    PrintToChat(client,"%c[SourceCraft]%c The union is now %cPicketing%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    AuthTimer(0.5,client,RespawnPlayerHandle);
                                }
                                case 15: // Lockout
                                {
                                    if (GetRandomInt(1,100) > 20)
                                        client--; // Get a different Negotiation
                                    else
                                    {
                                        PrintToChat(client,"%c[SourceCraft]%c Your employer has instituted a %cLockout%c!",
                                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                        new Float:location[3];
                                        GetClientAbsOrigin(client,location);
                                        TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                        TE_SendToAll();

                                        EmitSoundToAll(explodeWav,client);
                                        KillPlayer(client);
                                    }
                                }
                                case 16: // Workforce Reduction
                                {
                                    if (GetRandomInt(1,100) > 20)
                                        client--; // Get a different Negotiation
                                    else
                                    {
                                        PrintToChat(client,"%c[SourceCraft]%c You have been layed off due to a %cWorkforce Reduction%c!",
                                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                        new Float:location[3];
                                        GetClientAbsOrigin(client,location);
                                        TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                        TE_SendToAll();

                                        EmitSoundToAll(explodeWav,client);
                                        KillPlayer(client);
                                    }
                                }
                                case 17: // Forced Buyout
                                {
                                    new level = GetLevel(player, raceID);
                                    if (level < 8 || GetRandomInt(1,100) > 5)
                                        client--; // Get a different Negotiation
                                    else
                                    {
                                        new amount = GetRandomInt(100,1000);
                                        SetCredits(player, GetCredits(player)+amount);

                                        new reduction = GetRandomInt(0,level) - (level/4);
                                        if (reduction > 0)
                                        {
                                            PrintToChat(client,"%c[SourceCraft]%c You have been forced to accept a %cBuyout%c for %d crystals and have been reduced by %d levels!",
                                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount,reduction);
                                        }
                                        else
                                        {
                                            PrintToChat(client,"%c[SourceCraft]%c You have been forced to accept a %cBuyout%c for %d crystals!",
                                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);
                                        }

                                        new Float:location[3];
                                        GetClientAbsOrigin(client,location);
                                        TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                        TE_SendToAll();

                                        EmitSoundToAll(explodeWav,client);
                                        KillPlayer(client);
                                        if (reduction > 0)
                                            ResetLevel(player, raceID, level-reduction);
                                    }
                                }
                                case 18: // Bankruptcy
                                {
                                    new level = GetLevel(player, raceID);
                                    if (level < 8 || GetRandomInt(1,100) > 5)
                                        client--; // Get a different Negotiation
                                    else
                                    {
                                        new reduction = GetRandomInt(0,level) - (level/2);
                                        if (reduction > 0)
                                        {
                                            PrintToChat(client,"%c[SourceCraft]%c Your employer has gone into %cBankruptcy%c, you have been reduced by %d levels!",
                                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT, reduction);
                                        }
                                        else
                                        {
                                            PrintToChat(client,"%c[SourceCraft]%c Your employer has gone into %cBankruptcy%c!",
                                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                                        }

                                        new Float:location[3];
                                        GetClientAbsOrigin(client,location);
                                        TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                        TE_SendToAll();

                                        EmitSoundToAll(explodeWav,client);
                                        KillPlayer(client);

                                        if (reduction > 0)
                                            ResetLevel(player, raceID, level-reduction);
                                    }
                                }
                                case 19: // Union Dues
                                {
                                    new balance = GetCredits(player);
                                    new amount = GetRandomInt(1,balance);
                                    SetCredits(player, amount-balance);
                                    PrintToChat(client,"%c[SourceCraft]%c You must pay %d crystals for %cUnion Dues%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,COLOR_TEAM,COLOR_DEFAULT);
                                }
                                case 20: // OSHA
                                {
                                    PrintToChat(client,"%c[SourceCraft]%c You have been forced to leave due to %cOSHA Rules%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    new Float:location[3];
                                    GetClientAbsOrigin(client,location);
                                    TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                    TE_SendToAll();

                                    EmitSoundToAll(explodeWav,client);
                                    KillPlayer(client);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

AddCredits(client, Handle:player, amount, const String:reason[])
{
    SetCredits(player, GetCredits(player)+amount);
    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d crystals from %c%s%c!",
                COLOR_GREEN,COLOR_DEFAULT,amount,COLOR_TEAM,reason,COLOR_DEFAULT);
}
