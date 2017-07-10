/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: gametype.inc
 * Description: Function to determine game/mod type and mode
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _gametype_included
 #endinput
#endif
#define _gametype_included

enum Game { undetected=0, tf2=1, cstrike, csgo, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };

enum Mode
{
    Undefined,
    Medieval,
    ControlPoint,
    CaptureTheFlag,
    AttackDefend,
    TerritoryControl,
    Payload,
    Invade,
    Koth,
    PvP,
    MvM,
};

stock const String:GameTypes[][] = 
{
    "undetected",
    "tf2",
    "cstrike",
    "csgo",
    "dod",
    "hl2mp",
    "insurgency",
    "zps",
    "l4d",
    "l4d2",
    "other_game"
};

stock String:GameModeNames[][] = 
{
    "Undefined",
    "Medieval",
    "ControlPoint",
    "CaptureTheFlag",
    "AttackDefend",
    "TerritoryControl",
    "Payload",
    "Invade",
    "Koth",
    "PvP",
    "MvM",
};

stock Game:GameType = undetected;
stock Mode:GameMode = Undefined;

stock Game:GetGameType()
{
    if (GameType == undetected)
    {
        new String:modname[30];
        GetGameFolderName(modname, sizeof(modname));
        if (StrEqual(modname,"tf",false)) 
            GameType=tf2;
        else if (StrEqual(modname,"tf_beta",false)) 
            GameType=tf2;
        else if (StrEqual(modname,"cstrike",false))
            GameType=cstrike;
        else if (StrEqual(modname,"csgo",false))
            GameType=csgo;
        else if (StrEqual(modname,"dod",false))
            GameType=dod;
        else if (StrEqual(modname,"hl2mp",false))
            GameType=hl2mp;
        else if (StrEqual(modname,"Insurgency",false))
            GameType=insurgency;
        else if (StrEqual(modname,"left4dead", false))
            GameType=l4d;
        else if (StrEqual(modname,"left4dead2", false))
            GameType=l4d2;
        else if (StrEqual(modname,"zps",false))
            GameType=zps;
        else
            GameType=other_game;
    }
    return GameType;
}

#define GetGameTypeIsCS()   (GetGameType() == cstrike || GameType == csgo)
#define GameTypeIsCS()      (GameType      == cstrike || GameType == csgo)

stock Mode:GetGameMode(bool:forceUpdate=false)
{
    if ((forceUpdate || GameMode == Undefined) && GetGameType() == tf2)
        GameMode = GetTF2GameMode();

    return GameMode;
}

stock Mode:GetTF2GameMode()
{
    new entity = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
    if (entity > MaxClients && IsValidEntity(entity))
        return MvM;
    else
    {
        entity = FindEntityByClassname(-1, "tf_logic_medieval");
        if (entity > MaxClients && IsValidEntity(entity))
            return Medieval;
        else
        {
            entity = FindEntityByClassname(-1, "tf_logic_koth");
            if (entity > MaxClients && IsValidEntity(entity))
                return Koth;
            else
            {
                entity = FindEntityByClassname(-1, "mapobj_cart_dispenser");
                if (entity > MaxClients && IsValidEntity(entity))
                    return Payload;
                else
                {
                    entity = FindEntityByClassname(-1, "trigger_capture_area");
                    if (entity > MaxClients && IsValidEntity(entity))
                        return ControlPoint;
                    else
                    {
                        entity = FindEntityByClassname(-1, "item_teamflag");
                        if (entity > MaxClients && IsValidEntity(entity))
                        {
                            switch (GetEntProp(entity, Prop_Send, "m_nType"))
                            {
                                case 1: return AttackDefend;
                                case 2: return TerritoryControl;
                                case 3: return Invade;
                            }
                            return CaptureTheFlag;
                        }
                        else
                        {
                            entity = FindEntityByClassname(-1, "func_capturezone");
                            if (entity > MaxClients && IsValidEntity(entity))
                                return CaptureTheFlag;
                        }
                    }
                }
            }
        }
    }
    return PvP;
}

//Call ResetGameMode() in OnMapEnd()
#define ResetGameMode()     GameMode = Undefined

