/**
 * vim: set ai et ts=4 sw=4 :
 * File: TerranConfederacy .sp
 * Description: The Terran Confederacy race for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "jetpack.inc"

#include "SourceCraft/SourceCraft"

#include "SourceCraft/util"
#include "SourceCraft/health"

new raceID; // The ID we are assigned to

new g_smokeSprite;
new g_lightningSprite;

new m_Armor[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SourceCraft Race - Terran Confederacy",
    author = "-=|JFH|=-Naris",
    description = "The Terran Confederacy race for SourceCraft.",
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

public OnPluginReady()
{
    raceID=CreateRace("Terran Confederacy", "terran",
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


public OnPlayerAuthed(client,player)
{
    SetupHealth(client);
}

public OnRaceSelected(client,player,oldrace,race)
{
    if (race != oldrace)
    {
        if (oldrace == raceID)
        {
            TakeJetpack(client);
            SetMinVisibility(player, 255, 1.0, 1.0);
        }
        else if (race == raceID)
        {
            new skill_cloak=GetSkillLevel(player,race,0);
            if (skill_cloak)
                Cloak(client, player, skill_cloak);

            new skill_armor = GetSkillLevel(player,raceID,1);
            if (skill_armor)
                SetupArmor(client, skill_armor);

            new skill_stimpacks = GetSkillLevel(player,race,2);
            if (skill_stimpacks)
                Stimpacks(client, player, skill_stimpacks);

            new skill_jetpack=GetSkillLevel(player,race,3);
            if (skill_jetpack)
                Jetpack(client, skill_jetpack);
        }
    }
}

public OnUltimateCommand(client,player,race,bool:pressed)
{
    if (race==raceID && IsPlayerAlive(client))
    {
        if (pressed)
            StartJetpack(client);
        else
            StopJetpack(client);
    }
}

public OnSkillLevelChanged(client,player,race,skill,oldskilllevel,newskilllevel)
{
    if (race == raceID && newskilllevel > 0 && GetRace(player) == raceID)
    {
        if (skill==0)
            Cloak(client, player, newskilllevel);
        else if (skill==1)
            SetupArmor(client, newskilllevel);
        else if (skill==2)
            Stimpacks(client, player, newskilllevel);
        else if (skill==3)
            Jetpack(client, newskilllevel);
    }
}

public OnItemPurchase(client,player,item)
{
    new race=GetRace(player);
    if (race == raceID && IsPlayerAlive(client))
    {
        new boots = GetShopItem("Boots of Speed");
        if (boots == item)
        {
            new skill=GetSkillLevel(player,race,2);
            Stimpacks(client, player, skill);
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

        new player=GetPlayer(client);
        if (player>-1)
        {
            new race = GetRace(player);
            if (race == raceID)
            {
                new skill_cloak=GetSkillLevel(player,race,0);
                if (skill_cloak)
                    Cloak(client, player, skill_cloak);

                new skill_armor = GetSkillLevel(player,raceID,1);
                if (skill_armor)
                    SetupArmor(client, skill_armor);

                new skill_stimpacks = GetSkillLevel(player,race,2);
                if (skill_stimpacks)
                    Stimpacks(client, player, skill_stimpacks);

                new skill_jetpack=GetSkillLevel(player,race,3);
                if (skill_jetpack)
                    Jetpack(client, skill_jetpack);
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
        new player=GetPlayer(client);
        if (player != -1)
        {
            SetMinVisibility(player, 255, 1.0, 1.0);
        }

    }
}

public Action:PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new bool:changed=false;
    new victimUserid=GetEventInt(event,"userid");
    if (victimUserid)
    {
        new victimIndex      = GetClientOfUserId(victimUserid);
        new victimplayer = GetPlayer(victimIndex);
        if (victimplayer != -1)
        {
            new victimrace = GetRace(victimplayer);
            if (victimrace == raceID)
            {
                changed |= Armor(event, victimIndex, victimplayer);
            }
        }
    }
    return changed ? Plugin_Changed : Plugin_Continue;
}

bool:Cloak(client, player, skilllevel)
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
    new cloak = GetShopItem("Cloak of Shadows");
    if (cloak != -1 && GetOwnsItem(player,cloak))
    {
        alpha *= 0.90;
    }

    new Float:start[3];
    GetClientAbsOrigin(client, start);

    new color[4] = { 0, 255, 50, 128 };
    TE_SetupBeamRingPoint(start,30.0,60.0,g_lightningSprite,g_lightningSprite,
                          0, 1, 2.0, 10.0, 0.0 ,color, 10, 0);
    TE_SendToAll();

    SetMinVisibility(player,alpha, 0.80, 0.0);
}

SetupArmor(client, skilllevel)
{
    switch (skilllevel)
    {
        case 1: m_Armor[client] = GetMaxHealth(client);
        case 2: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*1.50);
        case 3: m_Armor[client] = GetMaxHealth(client)*2;
        case 4: m_Armor[client] = RoundFloat(float(GetMaxHealth(client))*2.50);
    }
}

bool:Armor(Handle:event, victimIndex, victimplayer)
{
    new skill_level_armor = GetSkillLevel(victimplayer,raceID,1);
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

            PrintToChat(victimIndex,"%c[SourceCraft] %s %cyour armor absorbed %d hp",
                        COLOR_GREEN,victimName,COLOR_DEFAULT,amount);
            return true;
        }
    }
    return false;
}

Stimpacks(client, player, skilllevel)
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
    new boots = GetShopItem("Boots of Speed");
    if (boots != -1 && GetOwnsItem(player,boots))
    {
        speed *= 1.1;
    }

    new Float:start[3];
    GetClientAbsOrigin(client, start);

    new color[4] = { 255, 100, 0, 255 };
    TE_SetupBeamRingPoint(start,20.0,60.0,g_smokeSprite,g_smokeSprite,
                          0, 1, 1.0, 4.0, 0.0 ,color, 10, 0);
    TE_SendToAll();

    SetMaxSpeed(player,speed);
}

Jetpack(client, skilllevel)
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
