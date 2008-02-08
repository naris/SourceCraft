/**
 * vim: set ai et ts=4 sw=4 :
 * File: UAW.sp
 * Description: The UAW race for SourceCraft.
 * Author(s): -=|JFH|=-Naris (Murray Wilson) 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "hgrsource.inc"

#include "sc/SourceCraft"

#include "sc/util"
#include "sc/range"
#include "sc/trace"
#include "sc/authtimer"
#include "sc/respawn"
#include "sc/log"

new raceID; // The ID we are assigned to

new explosionModel;
new g_purpleGlow;

new String:explodeWav[] = "weapons/explode5.wav";

// Reincarnation variables
new bool:m_JobsBank[MAXPLAYERS+1];
new bool:m_TeleportOnSpawn[MAXPLAYERS+1];
new Float:m_SpawnLoc[MAXPLAYERS+1][3];

new Handle:m_Currency   = INVALID_HANDLE; 
new Handle:m_Currencies = INVALID_HANDLE; 

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

public OnConfigsExecuted()
{
    m_Currency = FindConVar("sc_currency");
    if (m_Currency == INVALID_HANDLE)
        SetFailState("Couldn't find sc_currency variable");

    m_Currencies = FindConVar("sc_currencies");
    if (m_Currencies == INVALID_HANDLE)
        SetFailState("Couldn't find sc_currencies variable");
}

public OnPluginReady()
{
    raceID=CreateRace("UAW", "uaw",
                      "You have joined the UAW.",
                      "You will join the UAW when you die or respawn.",
                      "Inflated Wages",
                      "You get paid more and level faster.",
                      "Seniority",
                      "Gives you a 15-80% chance of immediately respawning where you died.",
                      "Negotiations",
                      "Various good and not so good things happen at random intervals\nYou might get or lose money or experience, you might also die\n (However, you will no longer ever lose levels or XP)!",
                      "Work Rules",
                      "Use your ultimate bind to hook a line to a wall and traverse it.");

    ControlHookGrabRope(true);
}

public OnMapStart()
{
    g_purpleGlow = SetupModel("materials/sprites/purpleglow1.vmt");
    if (g_purpleGlow == -1)
        SetFailState("Couldn't find purpleglow Model");

    if (GameType == tf2)
    {
        explosionModel=SetupModel("materials/particles/explosion/explosionfiresmoke.vmt");
        if (explosionModel == -1)
            SetFailState("Couldn't find Explosion Model");
    }
    else
    {
        explosionModel=SetupModel("materials/sprites/zerogxplode.vmt");
        if (explosionModel == -1)
            SetFailState("Couldn't find Explosion Model");
    }

    SetupSound(explodeWav);
}

public OnXPGiven(client,player,&amount)
{
    if (GetRace(player)==raceID && IsPlayerAlive(client))
    {
        new skill_inflated_wages=GetSkillLevel(player,raceID,0);
        if (skill_inflated_wages)
        {
            switch(skill_inflated_wages)
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

public OnCreditsGiven(client,player,&amount)
{
    if (GetRace(player)==raceID && IsPlayerAlive(client))
    {
        new skill_inflated_wages=GetSkillLevel(player,raceID,0);
        if (skill_inflated_wages)
        {
            switch(skill_inflated_wages)
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

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            Hook(client);
        else
            UnHook(client);
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        new player=GetPlayer(client);
        if (player>-1)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new skill_workrules=GetSkillLevel(player,race,3);
                if (skill_workrules)
                    WorkRules(client, player, skill_workrules);

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

public Action:OnPlayerDeathEvent(Handle:event,victim_index,victim_player,victim_race,
                                 attacker_index,attacker_player,attacker_race,
                                 assister_index,assister_player,assister_race,
                                 damage,const String:weapon[], bool:is_equipment,
                                 customkill,bool:headshot,bool:backstab,bool:melee)
{
    LogEventDamage(event, damage, "TerranConfederacy::PlayerDeathEvent", raceID);

    if (victim_race == raceID)
    {
        new seniority_skill=GetSkillLevel(victim_player,raceID,0);
        if (seniority_skill)
        {
            new buyout, jobsBank, sheltered;
            switch (seniority_skill)
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
                decl String:currencies[64];
                GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                SetCredits(victim_player, GetCredits(victim_player)+amount);
                PrintToChat(victim_index,"%c[SourceCraft]%c Due to %cSeniority%c, you have recieved %d %s from a %cBuyout%c offer!",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);
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

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
            TakeHook(client);
        else if (race == raceID)
        {
            m_JobsBank[client]=false;
            m_TeleportOnSpawn[client]=false;

            new skill_workrules=GetSkillLevel(player,race,3);
            if (skill_workrules)
                WorkRules(client, player, skill_workrules);
        }
    }
}

public OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && newskilllevel > 0 && GetRace(player) == raceID && IsPlayerAlive(client))
    {
        if (skill==3)
            WorkRules(client, player, newskilllevel);
    }
}

public WorkRules(client, player, skilllevel)
{
    if (skilllevel)
    {
        new duration, Float:range;
        switch(skilllevel)
        {
            case 1:
            {
                duration=5;
                range=150.0;
            }
            case 2:
            {
                duration=10;
                range=300.0;
            }
            case 3:
            {
                duration=20;
                range=450.0;
            }
            case 4:
            {
                duration=30;
                range=0.0;
            }
        }
        GiveHook(client,duration,range);
    }
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
                new player=GetPlayer(client);
                if(player>=0 && GetRace(player) == raceID)
                {
                    new skill_negotiations=GetSkillLevel(player,raceID,2);
                    if (skill_negotiations)
                    {
                        new percent;
                        switch(skill_negotiations)
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
                            switch(GetRandomInt(1,30))
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
                                    SetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have filed a %cGrievance%c and recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 8: // Shop Steward
                                {
                                    new amount = GetRandomInt(1,10);
                                    SetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have been made a %cShop Steward%c, recieve %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 9: // Arbitration
                                {
                                    new amount = GetRandomInt(1,10);
                                    SetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c Due to %cArbitration%c, you have recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 10: // Collective Bargaining
                                {
                                    new amount = GetRandomInt(1,10);
                                    SetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c Due to %cCollective Bargaining%c, you have recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 11: // Fringe Benefits
                                {
                                    new amount = GetRandomInt(1,10);
                                    SetXP(player, raceID, GetXP(player, raceID)+amount);
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
                                    new amount = GetRandomInt(100,1000);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have been forced to accept a %cBuyout%c for %d %s!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount,currencies);

                                    new Float:location[3];
                                    GetClientAbsOrigin(client,location);
                                    TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                    TE_SendToAll();

                                    EmitSoundToAll(explodeWav,client);
                                    KillPlayer(client);
                                }
                                case 18: // Bankruptcy
                                {
                                    PrintToChat(client,"%c[SourceCraft]%c Your employer has gone into %cBankruptcy%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    new Float:location[3];
                                    GetClientAbsOrigin(client,location);
                                    TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                    TE_SendToAll();

                                    EmitSoundToAll(explodeWav,client);
                                    KillPlayer(client);
                                }
                                case 19: // Union Dues
                                {
                                    new balance = GetCredits(player);
                                    new amount = GetRandomInt(1,balance);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, amount-balance);
                                    PrintToChat(client,"%c[SourceCraft]%c You must pay %d %s for %cUnion Dues%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);
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

AddCredits(client, player, amount, const String:reason[])
{
    decl String:currencies[64];
    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
    SetCredits(player, GetCredits(player)+amount);
    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d %s from %c%s%c!",
                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,reason,COLOR_TEAM,COLOR_DEFAULT);
}
