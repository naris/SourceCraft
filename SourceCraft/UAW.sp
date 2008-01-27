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

#include "SourceCraft/SourceCraft"

#include "SourceCraft/util"
#include "SourceCraft/range"
#include "SourceCraft/trace"
#include "SourceCraft/health"
#include "SourceCraft/authtimer"
#include "SourceCraft/respawn"
#include "SourceCraft/log"

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
    HookEvent("player_death",PlayerDeathEvent);

    CreateTimer(8.0,Negotiations,INVALID_HANDLE,TIMER_REPEAT);
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
                      "Gives you a 15-80% chance of immediately respawning where you died,\npotentially at the cost of a team mates life.",
                      "Negotiations",
                      "Various good and bad things happen at random intervals\nYou might get or lose money and experience, you might also die",
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

public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
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

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    new index  = GetClientOfUserId(userid);
    new player = GetPlayer(index);
    if (player > -1)
    {
        if (GetRace(player) == raceID)
        {
            new seniority_skill=GetSkillLevel(player,raceID,0);
            if (seniority_skill)
            {
                new buyout, jobsBank, bump;
                switch (seniority_skill)
                {
                    case 1:
                        {
                            bump=5;
                            jobsBank=7;
                            buyout=9;
                        }
                    case 2:
                        {
                            bump=10;
                            jobsBank=15;
                            buyout=22;
                        }
                    case 3:
                        {
                            bump=20;
                            jobsBank=30;
                            buyout=50;
                        }
                    case 4:
                        {
                            bump=35;
                            jobsBank=50;
                            buyout=63;
                        }
                }
                new chance = GetRandomInt(1,100);
                if (chance<=bump)
                {
                    BumpSomeone(index);
                    m_TeleportOnSpawn[index]=true;
                    GetClientAbsOrigin(index,m_SpawnLoc[index]);
                    AuthTimer(0.5,index,RespawnPlayerHandle);
                }
                else if (chance<=jobsBank)
                {
                    m_JobsBank[index]=true;
                    AuthTimer(0.5,index,RespawnPlayerHandle);
                }
                else if (chance<=buyout)
                {
                    // No monetary limit on UAW Buyout offers!
                    new amount = GetRandomInt(1,100);
                    decl String:currencies[64];
                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                    SetCredits(player, GetCredits(player)+amount);
                    PrintToChat(index,"%c[SourceCraft]%c You have recieved %d %s from a %cBuyout%c offer!",
                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);
                }
            }
        }
    }
}

public BumpSomeone(client)
{
    new clientCount = GetClientCount();
    for(new x=1;x<=clientCount;x++)
    {
        if (x != client && IsClientInGame(x) && IsPlayerAlive(x))
        {
            if (GetRandomInt(1,100) <= 0)
            {
                PrintToChat(client,"%c[SourceCraft]%c You have bumped %N due to %cUnion Rules%c!",
                            COLOR_GREEN,COLOR_DEFAULT,x,COLOR_TEAM,COLOR_DEFAULT);
                PrintToChat(x,"%c[SourceCraft]%c You have been bumped by %N due to %cUnion Rules%c!",
                            COLOR_GREEN,COLOR_DEFAULT,client,COLOR_TEAM,COLOR_DEFAULT);

                new Float:location[3];
                GetClientAbsOrigin(x,location);
                TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                TE_SendToAll();

                EmitSoundToAll(explodeWav,x);
                ForcePlayerSuicide(x);
                break;
            }
        }
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
                        PrintToChat(client,"%c[SourceCraft]%c You have joined the %cJobs Bank%c",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);
                    }
                }
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

public OnRaceSelected(client,player,oldrace,newrace)
{
    if (oldrace == raceID)
    {
        if (newrace != raceID)
        {
            m_TeleportOnSpawn[client]=false;
            m_JobsBank[client]=false;
        }
    }
    else
    {
        if (oldrace == raceID)
            TakeHook(client);
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
        new hookTime;
        switch(skilllevel)
        {
            case 1:
                hookTime=5;
            case 2:
                hookTime=15;
            case 3:
                hookTime=30;
            case 4:
                hookTime=45;
        }
        GiveHook(client,hookTime);
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
                            switch(GetRandomInt(1,20))
                            {
                                case 1: // Overtime
                                {
                                    new amount = GetRandomInt(1,10);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d %s from %cOvertime%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);

                                }
                                case 2: // Premium Pay
                                {
                                    new amount = GetRandomInt(1,10);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d %s from %cPremium Pay%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);

                                }
                                case 3: // Shift Differential 
                                {
                                    new amount = GetRandomInt(1,10);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d %s from %cShift Differential Pay%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);

                                }
                                case 4: // COLA 
                                {
                                    new amount = GetRandomInt(1,10);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d %s from %cCOLA%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);

                                }
                                case 5: // Profit Sharing 
                                {
                                    new amount = GetRandomInt(1,10);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d %s from %cProfit Sharing%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);

                                }
                                case 6: // Bonus
                                {
                                    new amount = GetRandomInt(1,10);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have recieved %d %s from a %cBonus%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,amount,currencies,COLOR_TEAM,COLOR_DEFAULT);

                                }
                                case 7: // Grievance
                                {
                                    new amount = GetRandomInt(1,10);
                                    SetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have filed a %cBrievance%c and recieved %d experience!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                }
                                case 8: // Shop Steward
                                {
                                    new amount = GetRandomInt(1,10);
                                    SetXP(player, raceID, GetXP(player, raceID)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have been made a %cShop Steward%c, recieved %d experience!",
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
                                    PrintToChat(client,"%c[SourceCraft]%c Your employer has instituted a %cLockout%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    new Float:location[3];
                                    GetClientAbsOrigin(client,location);
                                    TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                    TE_SendToAll();

                                    EmitSoundToAll(explodeWav,client);
                                    ForcePlayerSuicide(client);
                                }
                                case 16: // Workforce Reduction
                                {
                                    PrintToChat(client,"%c[SourceCraft]%c You have been layed off due to a %cWorkforce Reduction%c!",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    new Float:location[3];
                                    GetClientAbsOrigin(client,location);
                                    TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                    TE_SendToAll();

                                    EmitSoundToAll(explodeWav,client);
                                    ForcePlayerSuicide(client);
                                }
                                case 17: // Forced Buyout
                                {
                                    new amount = GetRandomInt(100,1000);
                                    decl String:currencies[64];
                                    GetConVarString((amount == 1) ? m_Currency : m_Currencies, currencies, sizeof(currencies));
                                    SetXP(player, raceID, 0);
                                    SetLevel(player, raceID, 0);
                                    SetSkillLevel(player, raceID, 0, 0);
                                    SetSkillLevel(player, raceID, 1, 0);
                                    SetSkillLevel(player, raceID, 2, 0);
                                    SetSkillLevel(player, raceID, 3, 0);
                                    SetCredits(player, GetCredits(player)+amount);
                                    PrintToChat(client,"%c[SourceCraft]%c You have been forced to accept a %cBuyout%c for %d %s! (but are reduced to level 0)",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT,amount);

                                    new Float:location[3];
                                    GetClientAbsOrigin(client,location);
                                    TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                    TE_SendToAll();

                                    EmitSoundToAll(explodeWav,client);
                                    ForcePlayerSuicide(client);
                                }
                                case 18: // Bankruptcy
                                {
                                    SetXP(player, raceID, 0);
                                    SetLevel(player, raceID, 0);
                                    SetSkillLevel(player, raceID, 0, 0);
                                    SetSkillLevel(player, raceID, 1, 0);
                                    SetSkillLevel(player, raceID, 2, 0);
                                    SetSkillLevel(player, raceID, 3, 0);
                                    PrintToChat(client,"%c[SourceCraft]%c Your employer has gone into %cBankruptcy%c! (you must start over)",
                                                COLOR_GREEN,COLOR_DEFAULT,COLOR_TEAM,COLOR_DEFAULT);

                                    new Float:location[3];
                                    GetClientAbsOrigin(client,location);
                                    TE_SetupExplosion(location,explosionModel,10.0,30,0,50,20);
                                    TE_SendToAll();

                                    EmitSoundToAll(explodeWav,client);
                                    ForcePlayerSuicide(client);
                                }
                                //case 19 & 20 do nothing
                            }
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}
