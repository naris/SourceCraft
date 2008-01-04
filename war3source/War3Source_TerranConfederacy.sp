/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_TerranConfederacy .sp
 * Description: The Terran Confederacy race for War3Source.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "jetpack.inc"

#include "War3Source/War3Source_Interface"

#include "War3Source/util"
#include "War3Source/health"
#include "War3Source/damage"

// War3Source stuff
new raceID; // The ID we are assigned to

new g_smokeSprite;
new g_lightningSprite;

new m_Armor[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "War3Source Race - Terran Confederacy",
    author = "-=|JFH|=-Naris",
    description = "The Terran Confederacy race for War3Source.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

public OnPluginStart()
{
    GetGameType();

    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_hurt",PlayerHurtEvent);
}

public OnWar3PluginReady()
{
    raceID=War3_CreateRace("Terran Confederacy",
                           "terran",
                           "You are now part of the Terran Confederacy.",
                           "You will be part of the Terran Confederacy when you die or respawn.",
                           "Cloaking Device",
                           "Makes you partially invisible, \n62% visibility - 37% visibility.\nTotal Invisibility when standing still",
                           "Heavy Armor",
                           "Reduces damage.",
                           "Stimpacks",
                           "Gives you a speed boost, 8-36% faster.",
                           "Jetpack",
                           "Allows you to fly until you run out of fuel.");

    ControlJetpack(true,true);
    SetJetpackRefuelingTime(0,30.0);
    SetJetpackFuel(0,100);
}

public OnMapStart()
{
    g_smokeSprite = SetupModel("materials/sprites/smoke.vmt");
    if (g_smokeSprite == -1)
        SetFailState("Couldn't find smoke Model");

    g_lightningSprite = SetupModel("materials/sprites/lgtning.vmt");
    if (g_lightningSprite == -1)
        SetFailState("Couldn't find lghtning Model");
}


public OnWar3PlayerAuthed(client,war3player)
{
    SetupHealth(client);
}

public OnRaceSelected(client,war3player,oldrace,race)
{
    if (race != oldrace && oldrace == raceID)
    {
        TakeJetpack(client);
        War3_SetMinVisibility(war3player, 255, 1.0, 1.0);
    }
}

public OnGameFrame()
{
    SaveAllHealth();
}

public OnUltimateCommand(client,war3player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            StartJetpack(client);
        else
            StopJetpack(client);
    }
}

public OnSkillLevelChanged(client,war3player,race,skill,oldskilllevel,newskilllevel)
{
    if(race == raceID && newskilllevel > 0 && War3_GetRace(war3player) == raceID && IsPlayerAlive(client))
    {
        if (skill==0)
            TerranConfederacy_Cloak(client, war3player, newskilllevel);
        else if (skill==1)
            TerranConfederacy_SetupArmor(client, newskilllevel);
        else if (skill==2)
            TerranConfederacy_Stimpacks(client, war3player, newskilllevel);
        else if (skill==3)
            TerranConfederacy_Jetpack(client, war3player, newskilllevel);
    }
}

public OnItemPurchase(client,war3player,item)
{
    new race=War3_GetRace(war3player);
    if (race == raceID && IsPlayerAlive(client))
    {
        new boots = War3_GetShopItem("Boots of Speed");
        if (boots == item)
        {
            new skill=War3_GetSkillLevel(war3player,race,2);
            TerranConfederacy_Stimpacks(client, war3player, skill);
        }
    }
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if (client)
    {
        SetupMaxHealth(client);

        new war3player=War3_GetWar3Player(client);
        if (war3player>-1)
        {
            new race = War3_GetRace(war3player);
            if (race == raceID)
            {
                new skill_cloak=War3_GetSkillLevel(war3player,race,0);
                if (skill_cloak)
                    TerranConfederacy_Cloak(client, war3player, skill_cloak);

                new skill_armor = War3_GetSkillLevel(war3player,raceID,1);
                if (skill_armor)
                    TerranConfederacy_SetupArmor(client, skill_armor);

                new skill_stimpacks = War3_GetSkillLevel(war3player,race,2);
                if (skill_stimpacks)
                    TerranConfederacy_Stimpacks(client, war3player, skill_stimpacks);

                new skill_jetpack=War3_GetSkillLevel(war3player,race,3);
                if (skill_jetpack)
                    TerranConfederacy_Jetpack(client, war3player, skill_jetpack);
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);

    if (client)
    {
        // Reset MaxHealth back to normal
        if (healthIncreased[client] && GameType == tf2)
        {
            SetMaxHealth(client, maxHealth[client]);
            healthIncreased[client] = false;
        }

        // Reset invisibility
        new war3player=War3_GetWar3Player(client);
        if (war3player != -1)
        {
            War3_SetMinVisibility(war3player, 255, 1.0, 1.0);
        }

    }
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid=GetEventInt(event,"userid");
    if (victimUserid)
    {
        new victimIndex      = GetClientOfUserId(victimUserid);
        new victimWar3player = War3_GetWar3Player(victimIndex);
        if (victimWar3player != -1)
        {
            new victimrace = War3_GetRace(victimWar3player);
            if (victimrace == raceID)
            {
                TerranConfederacy_Armor(event, victimIndex, victimWar3player);
            }
        }
    }
}

public TerranConfederacy_Cloak(client, war3player, skilllevel)
{
    new alpha;
    switch(skilllevel)
    {
        case 1:
            alpha=168;
        case 2:
            alpha=147;
        case 3:
            alpha=125;
        case 4:
            alpha=110; // 94;
    }

    /* If the Player also has the Cloak of Shadows,
     * Decrease the visibility further
     */
    new cloak = War3_GetShopItem("Cloak of Shadows");
    if (cloak != -1 && War3_GetOwnsItem(war3player,cloak))
    {
        alpha *= 0.90;
    }

    new Float:start[3];
    GetClientAbsOrigin(client, start);

    new color[4] = { 0, 255, 50, 128 };
    TE_SetupBeamRingPoint(start,30.0,60.0,g_lightningSprite,g_lightningSprite,
                          0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
    TE_SendToAll();

    War3_SetMinVisibility(war3player,alpha, 0.80, 0.1);
}

public TerranConfederacy_SetupArmor(client, skilllevel)
{
    switch (skilllevel)
    {
        case 1: m_Armor[client] = GetMaxHealth(client);
        case 2: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*1.50);
        case 3: m_Armor[client] = GetMaxHealth(client)*2;
        case 4: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*2.50);
    }
}

public bool:TerranConfederacy_Armor(Handle:event, victimIndex, victimWar3player)
{
    new skill_level_armor = War3_GetSkillLevel(victimWar3player,raceID,1);
    if (skill_level_armor)
    {
        new Float:from_percent,Float:to_percent;
        switch(skill_level_armor)
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
        new damage=GetDamage(event, victimIndex);
        new amount=RoundFloat(float(damage)*GetRandomFloat(from_percent,to_percent));
        new armor=m_Armor[victimIndex];
        if (amount > armor)
            amount = armor;
        if (amount > 0)
        {
            new newhp=GetClientHealth(victimIndex)+amount;
            new maxhp=GetMaxHealth(victimIndex);
            if (newhp > maxhp)
                newhp = maxhp;

            SetHealth(victimIndex,newhp);

            m_Armor[victimIndex] = armor - amount;

            decl String:victimName[64];
            GetClientName(victimIndex,victimName,63);

            PrintToChat(victimIndex,"%c[War3Source] %s %cyour armor absorbed %d hp",
                        COLOR_GREEN,victimName,COLOR_DEFAULT,amount);
        }
        return true;
    }
    return false;
}

public TerranConfederacy_Stimpacks(client, war3player, skilllevel)
{
    new Float:speed=1.0;
    switch (skilllevel)
    {
        case 1:
            speed=1.10;
        case 2:
            speed=1.21;
        case 3:
            speed=1.32;
        case 4:
            speed=1.50;
    }

    /* If the Player also has the Boots of Speed,
     * Increase the speed further
     */
    new boots = War3_GetShopItem("Boots of Speed");
    if (boots != -1 && War3_GetOwnsItem(war3player,boots))
    {
        speed *= 1.1;
    }

    new Float:start[3];
    GetClientAbsOrigin(client, start);

    new color[4] = { 255, 100, 0, 255 };
    TE_SetupBeamRingPoint(start,20.0,60.0,g_smokeSprite,g_smokeSprite,
                          0, 1, 1.0, 4.0, 0.0 ,color, 10, 0);
    TE_SendToAll();

    War3_SetMaxSpeed(war3player,speed);
}

public TerranConfederacy_Jetpack(client, war3player, skilllevel)
{
    if (skilllevel)
    {
        new fuel,Float:refueling_time;
        switch(skilllevel)
        {
            case 1:
            {
                fuel=60;
                refueling_time=45.0;
            }
            case 2:
            {
                fuel=90;
                refueling_time=30.0;
            }
            case 3:
            {
                fuel=120;
                refueling_time=20.0;
            }
            case 4:
            {
                fuel=150;
                refueling_time=10.0;
            }
        }
        GiveJetpack(client, fuel, refueling_time);
    }
}
