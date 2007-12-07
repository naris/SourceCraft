/**
 * vim: set ai et ts=4 sw=4 syntax=cpp :
 * File: util.inc
 * Description: Utility functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#pragma semicolon 1

// Defines
#define IS_ALIVE !GetLifestate

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // DOD = Red

enum Mod { undetected, tf2, cstrike, dod, hl2mp, insurgency, other };
stock Mod:GameType = undetected;

stock healthOffset[MAXPLAYERS+1]            = { 0, ... };
stock maxHealthOffset[MAXPLAYERS+1]         = { 0, ... };

stock maxHealth[MAXPLAYERS+1]               = { 0, ... };
stock bool:healthIncreased[MAXPLAYERS+1]    = { false, ... };

stock lifestateOffset  = 0;
stock colorOffset      = 0;
stock renderModeOffset = 0;
stock movetypeOffset   = 0;
stock ownerOffset      = 0;
stock curWepOffset     = 0;

stock Mod:GetGameType()
{
    if (GameType == undetected)
    {
        new String:modname[30];
        GetGameFolderName(modname, sizeof(modname));
        if (StrEqual(modname,"cstrike",false))
            GameType=cstrike;
        else if (StrEqual(modname,"tf",false)) 
            GameType=tf2;
        else if (StrEqual(modname,"dod",false)) 
            GameType=dod;
        else if (StrEqual(modname,"hl2mp",false)) 
            GameType=hl2mp;
        else if (StrEqual(modname,"Insurgency",false)) 
            GameType=insurgency;
        else
            GameType=other;
    }
    return GameType;
}

stock FindOffsets()
{
    lifestateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
    if(lifestateOffset==-1)
    SetFailState("Couldn't find LifeState offset");

    movetypeOffset=FindSendPropOffs("CBaseEntity","movetype");
    if(movetypeOffset==-1)
        SetFailState("Couldn't find MoveType offset");

    ownerOffset = FindSendPropOffs("CBaseEntity",       "m_hOwnerEntity");
    if(ownerOffset==-1)
        SetFailState("Couldn't find OwnerEntity offset");

    colorOffset=FindSendPropOffs("CAI_BaseNPC","m_clrRender");
    if(colorOffset==-1)
        SetFailState("Couldn't find Color offset");

    renderModeOffset=FindSendPropOffs("CBaseAnimating","m_nRenderMode");
    if(renderModeOffset==-1)
        SetFailState("Couldn't find RenderMode offset");

    curWepOffset=FindSendPropOffs("CAI_BaseNPC","m_hActiveWeapon");
    if(curWepOffset==-1)
        SetFailState("Couldn't find ActiveWeapon offset");
}

stock IncreaseHealth(client, amount)
{
    new health =GetClientHealth(client)+amount;
    if (GameType == tf2 && health > GetMaxHealth(client))
    {
        SetMaxHealth(client, health);
        healthIncreased[client] = true;
    }
    SetHealth(client, health);
}

stock SetHealth(entity,amount)
{
    SetEntData(entity,healthOffset[entity],amount,1);
}

stock SetMaxHealth(entity,amount)
{
    SetEntData(entity,maxHealthOffset[entity],amount,1);
}

stock GetMaxHealth(entity)
{
    return GetEntData(entity,maxHealthOffset[entity],1);
}

stock GetLifestate(client)
{
    return GetEntData(client,lifestateOffset,1);
}

stock MakeInvisible(client, war3player, visibility)
{
    new count=GetEntityCount();
    new weaponent=GetEntDataEnt(client,curWepOffset);
    if(weaponent && IsValidEdict(weaponent) && weaponent<count)
    {
        decl String:wepName[128];
        GetEdictClassname(weaponent,wepName,127);
        if(GameType == cstrike && StrEqual(wepName,"weapon_knife"))
        {
            visibility /=2;
        }
        else if(GameType == tf2 && (StrEqual(wepName,"tf_weapon_knife") ||
                                    StrEqual(wepName,"tf_weapon_shovel") ||
                                    StrEqual(wepName,"tf_weapon_wrench") ||
                                    StrEqual(wepName,"tf_weapon_bat") ||
                                    StrEqual(wepName,"tf_weapon_bonesaw") ||
                                    StrEqual(wepName,"tf_weapon_bottle") ||
                                    StrEqual(wepName,"tf_weapon_club") ||
                                    StrEqual(wepName,"tf_weapon_fireaxe") ||
                                    StrEqual(wepName,"tf_weapon_fists") ||
                                    StrEqual(wepName,"tf_weapon_builder") ||
                                    StrEqual(wepName,"tf_weapon_pda_engineer_build") ||
                                    StrEqual(wepName,"tf_weapon_pda_engineer_destroy") ||
                                    StrEqual(wepName,"tf_weapon_pda_spy")))
        {
            visibility /=2;
        }
        else if(GameType == dod && (StrEqual(wepName,"weapon_amerknife") ||
                                    StrEqual(wepName,"weapon_spade")))
        {
            visibility /=2;
        }
    }
    for(new obj = 64; obj < count; obj++)
    {
        if(IsValidEdict(obj))
        {
            if(GetEntDataEnt(obj,ownerOffset) == client)
                SetRenderColor(obj,255,255,255,visibility);
        }
    }
    SetRenderColor(client,255,255,255,visibility);
}

stock SetRenderColor(client,r,g,b,a)
{
	if(colorOffset != -1)
    {
        SetEntData(client,colorOffset,r,1,true);
        SetEntData(client,colorOffset+1,g,1,true);
        SetEntData(client,colorOffset+2,b,1,true);
        SetEntData(client,colorOffset+3,a,1,true);

        if(renderModeOffset != -1)
            SetEntData(client,renderModeOffset,3,1,true);
    }
}
