/*
 * vim: set ai et! ts=4 sw=4 :
 * [TF2] Be the Horsemann
 * Author(s): FlaminSarge
 * File: behorsemann.sp
 * Description: Allows admins to turn players into Horseless Headless Horsemenn
 *
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.5"

#define HHH               "models/bots/headless_hatman.mdl"
#define AXE               "models/weapons/c_models/c_bigaxe/c_bigaxe.mdl"

#define SND_LAUGH         "Halloween.HeadlessBossLaugh"
#define SND_DYING         "Halloween.HeadlessBossDying"
//#define SND_DYING       "vo/halloween_boss/knight_dying.wav"
#define SND_DEATH         "Halloween.HeadlessBossDeath"
#define SND_DEFEATED      "ui/halloween_boss_defeated_fx.wav"
#define SND_DEATHVO       "vo/halloween_boss/knight_death02.wav"
#define SND_PAIN          "Halloween.HeadlessBossPain"
#define SND_BOO           "Halloween.HeadlessBossBoo"
#define SND_ALERT         "Halloween.HeadlessBossAlert"
#define SND_KNIGHT_ALERT  "vo/halloween_boss/knight_alert.wav"
#define SND_ATTACK        "Halloween.HeadlessBossAttack"
#define SND_SPAWN         "Halloween.HeadlessBossSpawn"
//#define SND_SPAWN       "ui/halloween_boss_summoned_fx.wav"
#define SND_SPAWNRUMBLE   "Halloween.HeadlessBossSpawnRumble"
//#define SND_SPAWNRUMBLE "ui/halloween_boss_summon_rumble.wav"
#define SND_SPAWNVO       "vo/halloween_boss/knight_spawn.wav"
#define SND_FOOT          "Halloween.HeadlessBossFootfalls"
#define SND_LEFTFOOT      "player/footsteps/giant1.wav"
#define SND_RIGHTFOOT     "player/footsteps/giant2.wav"
#define SND_AXEHITFLESH   "Halloween.HeadlessBossAxeHitFlesh"
#define SND_AXEHITWORLD   "Halloween.HeadlessBossAxeHitWorld"
#define SND_LAUGH01       "vo/halloween_boss/knight_laugh01.wav"
#define SND_LAUGH02       "vo/halloween_boss/knight_laugh02.wav"
#define SND_LAUGH03       "vo/halloween_boss/knight_laugh03.wav"
#define SND_LAUGH04       "vo/halloween_boss/knight_laugh04.wav"
#define SND_ATTACK01      "vo/halloween_boss/knight_attack01.wav"
#define SND_ATTACK02      "vo/halloween_boss/knight_attack02.wav"
#define SND_ATTACK03      "vo/halloween_boss/knight_attack03.wav"
#define SND_ATTACK04      "vo/halloween_boss/knight_attack04.wav"
#define SND_PAIN01        "vo/halloween_boss/knight_pain01.wav"
#define SND_PAIN02        "vo/halloween_boss/knight_pain02.wav"
#define SND_PAIN03        "vo/halloween_boss/knight_pain03.wav"

public Plugin myinfo = 
{
    name = "[TF2] Be the Horsemann",
    author = "FlaminSarge,Pelipoika",
    description = "Be the Horsemann",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=166819"
}

Handle hCvarThirdPerson = INVALID_HANDLE;
Handle hCvarHealth = INVALID_HANDLE;
Handle hCvarSounds = INVALID_HANDLE;
Handle hCvarBoo = INVALID_HANDLE;
Handle fwdOnScare = INVALID_HANDLE;

bool   g_bNativeOverride = false;
bool   g_IsModel[MAXPLAYERS+1];
bool   g_bIsTP[MAXPLAYERS+1];
bool   g_bIsHHH[MAXPLAYERS + 1];

int    g_iHHHParticle[MAXPLAYERS + 1][3];
int    g_iHealth[MAXPLAYERS + 1];

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    CreateConVar("bethehorsemann_version", PLUGIN_VERSION, "[TF2] Be the Horsemann version", FCVAR_NOTIFY | FCVAR_SPONLY);
    hCvarHealth = CreateConVar("behhh_health", "750", "Amount of health to ADD to the HHH (stacks on current class health)", FCVAR_NONE);
    hCvarSounds = CreateConVar("behhh_sounds", "1", "Use Horsemann sounds (spawn, death, footsteps; will not disable BOO)", FCVAR_NONE, true, 0.0, true, 1.0);
    hCvarBoo = CreateConVar("behhh_boo", "2", "2-Boo stuns nearby enemies; 1-Boo is sound only; 0-no Boo", FCVAR_NONE, true, 0.0, true, 2.0);
    hCvarThirdPerson = CreateConVar("behhh_thirdperson", "1", "Whether or not Horsemenn ought to be in third-person", FCVAR_NONE, true, 0.0, true, 1.0);

    RegAdminCmd("sm_behhh", Command_Horsemann, ADMFLAG_ROOT, "It's a good time to run - turns <target> into a Horsemann");

    AddNormalSoundHook(HorsemannSH);

    HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_death", Event_Death,  EventHookMode_Post);
}

public void OnClientPutInServer(int client)
{
    OnClientDisconnect_Post(client);
}

public void OnClientDisconnect_Post(int client)
{
    if(g_bIsHHH[client])
    {
        g_IsModel[client] = false;
        g_bIsTP[client] = false;
        g_bIsHHH[client] = false;
        ClearHorsemannParticles(client);
    }
}

public void OnPluginEnd()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if(IsValidClient(client))
            ClearHorsemannParticles(client);
    }
}

public void OnMapStart()
{
    PrecacheModel(HHH, true);
    PrecacheModel(AXE, true);

    PrecacheSound(SND_LEFTFOOT, true);
    PrecacheSound(SND_RIGHTFOOT, true);
    
    PrecacheSound(SND_DEFEATED, true);
    PrecacheSound(SND_LAUGH01, true);
    PrecacheSound(SND_LAUGH02, true);
    PrecacheSound(SND_LAUGH03, true);
    PrecacheSound(SND_LAUGH04, true);
    PrecacheSound(SND_ATTACK01, true);
    PrecacheSound(SND_ATTACK02, true);
    PrecacheSound(SND_ATTACK03, true);
    PrecacheSound(SND_ATTACK04, true);
    PrecacheSound(SND_PAIN01, true);
    PrecacheSound(SND_PAIN02, true);
    PrecacheSound(SND_PAIN03, true);
    PrecacheSound(SND_KNIGHT_ALERT, true);

    PrecacheScriptSound(SND_LAUGH);
    PrecacheScriptSound(SND_DYING);
    PrecacheScriptSound(SND_DEATH);
    PrecacheScriptSound(SND_PAIN);
    PrecacheScriptSound(SND_BOO);
    PrecacheScriptSound(SND_ALERT);
    PrecacheScriptSound(SND_ATTACK);
    PrecacheScriptSound(SND_SPAWN);
    PrecacheScriptSound(SND_SPAWNRUMBLE);
    PrecacheScriptSound(SND_FOOT);
    PrecacheScriptSound(SND_AXEHITFLESH);
    PrecacheScriptSound(SND_AXEHITWORLD);
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (g_bIsHHH[client])
    {
        SetVariantInt(0);
        AcceptEntityInput(client, "SetForcedTauntCam");
    
        RemoveModel(client);
        ClearHorsemannParticles(client);
    }

    /*
    if (GetClientHealth(client) > g_iHealth[client])
        SetEntityHealth(client, g_iHealth[client]);
    */

    g_bIsHHH[client] = false;
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int deathflags = GetEventInt(event, "death_flags");

    if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
    {
        if (IsValidClient(client) && g_bIsHHH[client])
        {
            ClearHorsemannParticles(client);

            if (GetConVarBool(hCvarSounds))
            {
                EmitGameSoundToAll(SND_DYING);
                EmitGameSoundToAll(SND_DEATH);
            }
            
            SetVariantInt(0);
            AcceptEntityInput(client, "SetForcedTauntCam");
            
            RemoveModel(client);
            
            g_bIsHHH[client] = false;
        }
    }
}

public void Event_PlayerHurt(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
    int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
    if (iVictim != iAttacker && IsValidClient(iAttacker) && g_bIsHHH[iAttacker] && IsValidClient(iVictim >= 1))
    {
        if (IsPlayerAlive(iVictim) && GetEventInt(hEvent, "health") > 0 && !TF2_IsPlayerInCondition(iVictim, TFCond_Dazed))
        {
            TF2_StunPlayer(iVictim, 1.5, _, TF_STUNFLAGS_GHOSTSCARE);
        }
    }
}

public Action SetModel(int client, const char[] model)
{
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        SetVariantString(model);
        AcceptEntityInput(client, "SetCustomModel");

        SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

        g_IsModel[client] = true;
    }
}

public Action RemoveModel(int client)
{
    if (IsValidClient(client) && g_IsModel[client])
    {
        SetVariantString("");
        AcceptEntityInput(client, "SetCustomModel");
        g_IsModel[client] = false;
    }
    // return Plugin_Handled;
}

/*
stock SwitchView (target, bool:observer, bool:viewmodel, bool:self)
{
    SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target:-1);
    SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1:0);
    SetEntProp(target, Prop_Send, "m_iFOV", observer ? 100 : GetEntProp(target, Prop_Send, "m_iDefaultFOV"));
    SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1:0);

    SetVariantBool(self);
    if (self) AcceptEntityInput(target, "SetCustomModelVisibletoSelf");
    g_bIsTP[target] = observer;
}*/

stock void ClearHorsemannParticles(int client)
{
    TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 0.0);
    TE_ParticleToAll("halloween_boss_death", _, _, _, client);
    
    for (int i = 0; i < 3; i++)
    {
        int ent = EntRefToEntIndex(g_iHHHParticle[client][i]);
        if (ent > MaxClients && IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
        g_iHHHParticle[client][i] = INVALID_ENT_REFERENCE;
    }
}

stock void DoHorsemannParticles(int client)
{
    /*
    halloween_boss_summon
    halloween_boss_eye_glow
    halloween_boss_foot_impact
    halloween_boss_death
    */

    ClearHorsemannParticles(client);
    int lefteye = MakeParticle(client, "halloween_boss_eye_glow", "lefteye");
    if (IsValidEntity(lefteye))
    {
        g_iHHHParticle[client][0] = EntIndexToEntRef(lefteye);
    }

    int righteye = MakeParticle(client, "halloween_boss_eye_glow", "righteye");
    if (IsValidEntity(righteye))
    {
        g_iHHHParticle[client][1] = EntIndexToEntRef(righteye);
    }

/*  int bodyglow = MakeParticle(client, "halloween_boss_shape_glow", "");
    if (IsValidEntity(bodyglow))
    {
        g_iHHHParticle[client][2] = EntIndexToEntRef(bodyglow);
    }*/

    TE_ParticleToAll("ghost_pumpkin", _, _, _, client);
}

stock int MakeParticle(int client, char[] effect, char[] attachment)
{
        float pos[3];
        float ang[3];
        char buffer[128];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
        GetClientEyeAngles(client, ang);
        ang[0] *= -1;
        ang[1] += 180.0;
        if (ang[1] > 180.0) ang[1] -= 360.0;
        ang[2] = 0.0;
    //  GetAngleVectors(ang, pos2, NULL_VECTOR, NULL_VECTOR);

        int particle = CreateEntityByName("info_particle_system");
        if (!IsValidEntity(particle)) return -1;
        TeleportEntity(particle, pos, ang, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", effect);
        SetVariantString("!activator");
        AcceptEntityInput(particle, "SetParent", client, particle, 0);
        if (attachment[0] != '\0')
        {
            SetVariantString(attachment);
            AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
        }
        Format(buffer, sizeof(buffer), "%s_%s%d", effect, attachment, particle);
        DispatchKeyValue(particle, "targetname", buffer);
        DispatchSpawn(particle);
        ActivateEntity(particle);
        SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
        AcceptEntityInput(particle, "Start");
        return particle;
}

public Action Command_Horsemann(int client, int args)
{
    if (g_bNativeOverride)
    {
        ReplyToCommand(client, "This command has been disabled by the server.");
        return Plugin_Handled;
    }

    char arg1[32];
    if (args < 1)
        arg1 = "@me";
    else
        GetCmdArg(1, arg1, sizeof(arg1));

    if (!StrEqual(arg1, "@me") && !CheckCommandAccess(client, "sm_behhh_others", ADMFLAG_ROOT, true))
    {
        ReplyToCommand(client, "[SM] %t", "No Access");
        return Plugin_Handled;
    }

    /**
     * target_name - stores the noun identifying the target(s)
     * target_list - array to store clients
     * target_count - variable to store number of clients
     * tn_is_ml - stores whether the noun must be translated
     */
    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(
                    arg1,
                    client,
                    target_list,
                    MAXPLAYERS,
                    COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), /* Only allow alive players. If targetting self, allow self. */
                    target_name,
                    sizeof(target_name),
                    tn_is_ml)) <= 0)
    {
/*      if (strcmp(arg1, "@me", false) == 0 && target_count == COMMAND_TARGET_IMMUNE)
        {
            target_list[0] = client;
            target_count = 1;
        }
        else*/
        /* This function replies to the admin with a failure message */
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    int health = GetConVarInt(hCvarHealth);
    bool thirdPerson = GetConVarBool(hCvarThirdPerson);
    for (int i = 0; i < target_count; i++)
    {
        MakeHorsemann(target_list[i], health, thirdPerson);
        LogAction(client, target_list[i], "\"%L\" made \"%L\" a Horseless Headless Horsemann", client, target_list[i]);
    }
    
    return Plugin_Handled;
}

void MakeHorsemann(int client, int health, bool thirdPerson)
{
    TF2_SetPlayerClass(client, TFClass_DemoMan);
    TF2_RegeneratePlayer(client);

    if (GetConVarBool(hCvarSounds))
    {
        EmitGameSoundToAll(SND_SPAWN);
        EmitGameSoundToAll(SND_SPAWNRUMBLE);
        //EmitSoundToAll(SND_SPAWNVO);
    }

    int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");

    char weaponname[32];
    GetClientWeapon(client, weaponname, sizeof(weaponname));
    if (strcmp(weaponname, "tf_weapon_minigun", false) == 0) 
    {
        SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
        TF2_RemoveCondition(client, TFCond_Slowed);
    }

    TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
    CreateTimer(0.0, Timer_Switch, client);
    //  TF2Items_GiveWeapon(client, 8266);
    SetModel(client, HHH);

    if (thirdPerson)
    {
        SetVariantInt(1);
        AcceptEntityInput(client, "SetForcedTauntCam");
    }

    DoHorsemannParticles(client);

    TF2_RemoveWeaponSlot(client, 0);
    TF2_RemoveWeaponSlot(client, 1);
    TF2_RemoveWeaponSlot(client, 5);
    TF2_RemoveWeaponSlot(client, 3);

    g_iHealth[client] = GetClientHealth(client);
    SetEntityHealth(client, 350 + health);
    //TF2_SetHealth(client, 350 + health);  //overheal, will seep down to normal max health... probably.

    TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 2.0);

    static const float vecHHHMins[3] = {-25.505956, -38.176700, -11.582711};
    static const float vecHHHMaxs[3] = {17.830757, 38.176841, 138.456878};

    SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecHHHMins);
    SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecHHHMaxs);

    g_bIsHHH[client] = true;
    //  g_bIsTP[client] = true;
}

/*
stock TF2_SetHealth(client, NewHealth)
{
    SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
    SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
*/

public Action Timer_Switch(Handle timer, any client)
{
    if (IsValidClient(client))
        GiveAxe(client);
}

stock void GiveAxe(int client)
{
    TF2_RemoveAllWearables(client);
    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);

    Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
    if (hWeapon != INVALID_HANDLE)
    {
        TF2Items_SetClassname(hWeapon, "tf_weapon_sword");
        TF2Items_SetItemIndex(hWeapon, 266);
        TF2Items_SetLevel(hWeapon, 100);
        TF2Items_SetQuality(hWeapon, 5);

        char weaponAttribs[256];
        //This is so, so bad and I am so very, very sorry, but TF2Attributes will be better.
        Format(weaponAttribs, sizeof(weaponAttribs), "264 ; 1.75 ; 263 ; 1.3 ; 15 ; 0 ; 26 ; %d ; 2 ; 999.0 ; 107 ; 4.0 ; 109 ; 0.0 ; 62 ; 0.70 ; 205 ; 0.05 ; 206 ; 0.05 ; 68 ; -2 ; 69 ; 0.0 ; 53 ; 1.0 ; 27 ; 1.0", GetConVarInt(hCvarHealth));
        //char weaponAttribs[] = "15 ; 0 ; 26 ; 750.0 ; 2 ; 999.0 ; 107 ; 4.0 ; 109 ; 0.0 ; 62 ; 0.70 ; 205 ; 0.05 ; 206 ; 0.05 ; 68 ; -2 ; 69 ; 0.0 ; 53 ; 1.0 ; 27 ; 1.0";

        char weaponAttribsArray[32][32];
        int attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
        if (attribCount > 0) {
            TF2Items_SetNumAttributes(hWeapon, attribCount/2);
            int i2 = 0;
            for (int i = 0; i < attribCount; i+=2) {
                TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
                i2++;
            }
        } else {
            TF2Items_SetNumAttributes(hWeapon, 0);
        }

        int weapon = TF2Items_GiveNamedItem(client, hWeapon);
        EquipPlayerWeapon(client, weapon);
        CloseHandle(hWeapon);
        SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", PrecacheModel(AXE));
        SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", PrecacheModel(AXE), _, 0);
    }
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
    if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
    {
        char classname[64];
        int wep = GetPlayerWeaponSlot(client, slot);
        if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
        {
            FakeClientCommandEx(client, "use %s", classname);
            SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
        }
    }
}

public Action HorsemannSH(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH],
                          int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (!IsValidClient(entity)) return Plugin_Continue;
    if (!g_bIsHHH[entity]) return Plugin_Continue;

    if (strncmp(sample, "player/footsteps/", 17, false) == 0)
    {
        if (GetConVarBool(hCvarSounds))
        {
            if (StrContains(sample, "1.wav", false) != -1 || StrContains(sample, "3.wav", false) != -1)
                sample = SND_LEFTFOOT;
            else if (StrContains(sample, "2.wav", false) != -1 || StrContains(sample, "4.wav", false) != -1)
                sample = SND_RIGHTFOOT;
            else
            {
                switch(GetRandomInt(1, 2))
                {
                    case 1: Format(sample, sizeof(sample), SND_LEFTFOOT);
                    case 2: Format(sample, sizeof(sample), SND_RIGHTFOOT);
                }
            }
        }
        EmitSoundToAll(sample, entity);

        float clientPos[3];
        GetClientAbsOrigin(entity, clientPos);
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i)) continue;
            if (!IsPlayerAlive(i)) continue;
            if (i == entity) continue;
            
            float zPos[3];
            GetClientAbsOrigin(i, zPos);

            float flDistance = GetVectorDistance(clientPos, zPos);
            if (flDistance < 500.0)
            {
                ScreenShake(i, FloatAbs((500.0 - flDistance) / (500.0 - 0.0) * 15.0), 5.0, 1.0);
            }
        }
    
        return Plugin_Changed;
    }
    
    if (StrContains(sample, "knight_axe_miss", false) != -1 || StrContains(sample, "knight_axe_hit", false) != -1)
    {
        float clientPos[3];
        GetClientAbsOrigin(entity, clientPos);
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i)) continue;
            if (!IsPlayerAlive(i)) continue;

            float zPos[3];
            GetClientAbsOrigin(i, zPos);

            float flDistance = GetVectorDistance(clientPos, zPos);
            if (flDistance < 500.0)
            {
                ScreenShake(i, FloatAbs((500.0 - flDistance) / (500.0 - 0.0) * 15.0), 5.0, 1.0);
            }
        }
    }
    else if(StrContains(sample, "sword_swing", false) != -1 || StrContains(sample, "cbar_miss", false) != -1)
    {
        switch(GetRandomInt(1, 4))
        {
            case 1: Format(sample, sizeof(sample), SND_ATTACK01);
            case 2: Format(sample, sizeof(sample), SND_ATTACK02);
            case 3: Format(sample, sizeof(sample), SND_ATTACK03);
            case 4: Format(sample, sizeof(sample), SND_ATTACK04);
        }
        EmitSoundToAll(sample, entity, SNDCHAN_VOICE, 95, 0, 1.0, 100);
        TE_ParticleToAll("ghost_pumpkin", _, _, _, entity);
        
        return Plugin_Changed;
    }
    else if(StrContains(sample, "vo/", false) != -1)
    {
        if(StrContains(sample, "_medic0", false) != -1)
        {
            int boo = GetConVarInt(hCvarBoo);
            if (boo && StrContains(sample, "_medic0", false) != -1)
            {
                Format(sample, sizeof(sample), SND_KNIGHT_ALERT);
                if (boo > 1)
                    DoHorsemannScare(entity);
            }
            return Plugin_Changed;
        }
        else if(StrContains(sample, "pain", false) != -1)
        {
            //Format(sample, sizeof(sample), "Halloween.HeadlessBossPain");
            switch(GetRandomInt(1, 3))
            {
                case 1: Format(sample, sizeof(sample), SND_PAIN01);
                case 2: Format(sample, sizeof(sample), SND_PAIN02);
                case 3: Format(sample, sizeof(sample), SND_PAIN03);
            }
            return Plugin_Changed;
        }
        else
        {
            switch(GetRandomInt(1, 4))
            {
                case 1: Format(sample, sizeof(sample), SND_LAUGH01);
                case 2: Format(sample, sizeof(sample), SND_LAUGH02);
                case 3: Format(sample, sizeof(sample), SND_LAUGH03);
                case 4: Format(sample, sizeof(sample), SND_LAUGH04);
            }
            
            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

int DoHorsemannScare(int client)
{
    Action res = Plugin_Continue;
    Call_StartForward(fwdOnScare);
    Call_PushCell(client);
    Call_PushCell(0);
    Call_Finish(res);

    if (res != Plugin_Continue)
        return 0;

    float pos[3];
    float HorsemannPosition[3];
    GetClientAbsOrigin(client, HorsemannPosition);

    int count = 0;
    int HorsemannTeam = GetClientTeam(client);

    TF2_StunPlayer(client, 1.3, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsPlayerAlive(i) || HorsemannTeam == GetClientTeam(i))
            continue;

        Call_StartForward(fwdOnScare);
        Call_PushCell(client);
        Call_PushCell(i);
        Call_Finish(res);

        if (res != Plugin_Continue)
            continue;

        GetClientAbsOrigin(i, pos);
        if (GetVectorDistance(HorsemannPosition, pos) <= 500 && !FindHHHSaxton(i) && !g_bIsHHH[i])
        {
            TF2_StunPlayer(i, 4.0, 0.3, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_SLOWDOWN);
            count++;
        }
    }

    return count;
}

stock bool IsValidClient(int client)
{
    if (client <= 0) return false;
    if (client > MaxClients) return false;
//  if (!IsClientConnected(client)) return false;
    return IsClientInGame(client);
}

stock bool FindHHHSaxton(int client)
{
    int edict = MaxClients+1;
    while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
    {
        char netclass[32];
        if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
        {
            int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
            if ((idx == 277 || idx == 278) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
            {
                return true;
            }
        }
    }
    return false;
}

stock void TF2_RemoveAllWearables(int client)
{
    int wearable = -1;
    while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
    {
        if (IsValidEntity(wearable))
        {
            int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
            if (client == player)
            {
                TF2_RemoveWearable(client, wearable);
            }
        }
    }

    while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
    {
        if (IsValidEntity(wearable))
        {
            int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
            if (client == player)
            {
                TF2_RemoveWearable(client, wearable);
            }
        }
    }

    while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
    {
        if (IsValidEntity(wearable))
        {
            int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
            if (client == player)
            {
                TF2_RemoveWearable(client, wearable);
            }
        }
    }
}

void TE_ParticleToAll(char[] Name, float origin[3]=NULL_VECTOR, float start[3]=NULL_VECTOR,float angles[3]=NULL_VECTOR,
                      int entindex=-1,int attachtype=-1,int attachpoint=-1, bool resetParticles=true)
{
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    // find particle index
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;
    int i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    TE_SendToAll();
}

stock void ScreenShake(int target, float intensity=30.0, float duration=10.0, float frequency=3.0)
{
    Handle bf; 
    if ((bf = StartMessageOne("Shake", target)) != INVALID_HANDLE)
    {
        BfWriteByte(bf, 0);
        BfWriteFloat(bf, intensity);
        BfWriteFloat(bf, duration);
        BfWriteFloat(bf, frequency);
        EndMessage();
    }
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
    /* If startEnt isn't valid shifting it back to the nearest valid one */
    while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
    return FindEntityByClassname(startEnt, classname);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Register Native
    CreateNative("IsHorsemann",Native_IsHorsemann);
    CreateNative("MakeHorsemann",Native_MakeHorsemann);
    CreateNative("HorsemannScare",Native_HorsemannScare);
    CreateNative("ControlBeHorsemann",Native_Control);

    fwdOnScare=CreateGlobalForward("OnHorsemannScare",ET_Hook,Param_Cell,Param_Cell);

    RegPluginLibrary("behorsemann");
    return APLRes_Success;
}

public int Native_Control(Handle plugin, int numParams)
{
    g_bNativeOverride |= GetNativeCell(1);
}

public int Native_MakeHorsemann(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (IsValidClient(client))
    {
        int health = GetNativeCell(2);
        if (health < 0)
            health = GetConVarInt(hCvarHealth);

        bool thirdPerson = view_as<bool>(GetNativeCell(3));
        if (view_as<int>(thirdPerson) < 0)
            thirdPerson = GetConVarBool(hCvarThirdPerson);

        MakeHorsemann(client, health, thirdPerson);

        EmitSoundToAll(SND_SPAWN);
        EmitSoundToAll(SND_SPAWNRUMBLE);
        EmitSoundToAll(SND_SPAWNVO);

        return view_as<int>(g_bIsHHH[client]);
    }
    else
        return view_as<int>(false);
}

public int Native_IsHorsemann(Handle plugin,int numParams)
{
    int client = GetNativeCell(1);
    if (client > 0 && client < sizeof(g_bIsHHH))
        return view_as<int>(g_bIsHHH[client]);
    else
        return view_as<int>(false);
}

public int Native_HorsemannScare(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (IsValidClient(client))
    {
        EmitSoundToAll(SND_BOO);
        return DoHorsemannScare(client);
    }
    else
        return 0;
}