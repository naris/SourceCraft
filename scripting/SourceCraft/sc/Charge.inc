/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Charge.inc
 * Description: The Charge Upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */

#if defined _Charge_included
 #endinput
#endif
#define _Charge_included

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include "tf2_meter"
#include "tf2_player"
#include "TeleportPlayer"
#define REQUIRE_EXTENSIONS

#include "sc/sounds"
#include "sc/ShopItems"

#define SetupCharge()   SetupDeniedSound()

//Define this before inclusion.
//new const Float:g_ChargePercent[] = { 0.15, 0.40, 0.65, 0.85, 1.00 };

stock bool:m_ChargeActive[MAXPLAYERS+1];

Charge(client, race, upgrade, level, immunity, damage, Float:force, Float:impulse)
{
    if (level > 0)
    {
        if (IsMole(client))
        {
            decl String:upgradeName[64];
            GetUpgradeName(race, upgrade, upgradeName, sizeof(upgradeName), client);
            DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
            PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else if (GetRestriction(client,Restriction_NoUltimates) ||
                 GetRestriction(client,Restriction_Stunned))
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            DisplayMessage(client, Display_Ultimate,
                           "%t", "PreventedFromCharging");
        }
        else
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerTaunting(client) ||
                    TF2_IsPlayerDazed(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return;
                }
                //case TFClass_Scout:
                else if (TF2_IsPlayerBonked(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return;
                }
                //case TFClass_Spy:
                else if (TF2_IsPlayerCloaked(client) ||
                         TF2_IsPlayerDeadRingered(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    return;
                }
                else if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            if (CanInvokeUpgrade(client, race, upgrade))
            {
                PrepareAndEmitSoundToAll(g_ChargeSound, client);
                m_ChargeActive[client] = true;

                new Float:velocity = float(level) * impulse;
                new Float:vecAngles[3], Float:vecVelocity[3];    
                GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
                GetClientEyeAngles(client, vecAngles);

                vecAngles[1] = DegToRad(vecAngles[1]);

                vecVelocity[0] = ( Cosine(vecAngles[1]) * velocity ) + vecVelocity[0];
                vecVelocity[1] = ( Sine(vecAngles[1])   * velocity ) + vecVelocity[1];
                vecVelocity[2] = ( Sine(DegToRad(vecAngles[0]))  * velocity ) + vecVelocity[2];

                new Handle:pack;
                CreateDataTimer(0.2, ChargeTimer, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                if (pack != INVALID_HANDLE)
                {
                    WritePackCell(pack, 0); // count
                    WritePackCell(pack, client);
                    WritePackCell(pack, level);
                    WritePackCell(pack, immunity);
                    WritePackCell(pack, damage);
                    WritePackFloat(pack, force);
                    WritePackFloat(pack, vecVelocity[0]);
                    WritePackFloat(pack, vecVelocity[1]);
                    WritePackFloat(pack, vecVelocity[2]);
                }

                CreateCooldown(client, race, upgrade);
            }
        }
    }
}

public Action:ChargeTimer(Handle:timer,any:pack)
{
    static const chargeColor[4] = {139, 69, 19, 255};

    if (pack != INVALID_HANDLE)
    {
        ResetPack(pack);
        new count=ReadPackCell(pack);
        new client=ReadPackCell(pack);
        if (m_ChargeActive[client] && IsValidClientAlive(client) &&
            !GetRestriction(client,Restriction_NoUltimates) &&
            !GetRestriction(client,Restriction_Stunned))
        {
            if (GameType == tf2)
            {
                if (TF2_IsPlayerTaunting(client) ||
                    TF2_IsPlayerDazed(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    m_ChargeActive[client] = false;
                    return Plugin_Stop;
                }
                //case TFClass_Scout:
                else if (TF2_IsPlayerBonked(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    m_ChargeActive[client] = false;
                    return Plugin_Stop;
                }
                //case TFClass_Spy:
                else if (TF2_IsPlayerCloaked(client) ||
                         TF2_IsPlayerDeadRingered(client))
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    m_ChargeActive[client] = false;
                    return Plugin_Stop;
                }
                else if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);
            }

            new level=ReadPackCell(pack);
            new immunity=ReadPackCell(pack);
            new base_damage=ReadPackCell(pack);
            new Float:base_force=ReadPackFloat(pack);

            new Float:range = 50.0 + float(level)*50.0;
            new dmg = level*base_damage;

            new Float:force = float(level) * base_force * -1.0;
            new Float:minVert = base_force * 4.0;
            new Float:vertForce = force * -2.0;
            if (vertForce < minVert)
                vertForce = minVert;

            new Float:indexLoc[3];
            new Float:clientLoc[3];
            GetClientAbsOrigin(client, clientLoc);
            clientLoc[2] += 50.0; // Adjust trace position to the middle of the person instead of the feet.

            new team = GetClientTeam(client);
            for (new index=1;index<=MaxClients;index++)
            {
                if (client != index && IsClientInGame(index) &&
                    IsPlayerAlive(index) && GetClientTeam(index) != team)
                {
                    GetClientAbsOrigin(index, indexLoc);
                    indexLoc[2] += 50.0;

                    if (IsPointInRange(clientLoc, indexLoc, range) &&
                        TraceTargetIndex(client, index, clientLoc, indexLoc))
                    {
                        // Almost everybody gets brushed aside!
                        if ((immunity >= 3 || !GetImmunity(index,Immunity_Ultimates)) &&
                            !GetImmunity(index,Immunity_MotionTaking) &&
                            !GetAttribute(index,Attribute_IsMassive))
                        {
                            Push(index, indexLoc, clientLoc, force, vertForce);
                        }

                        new bool:isUber = IsInvulnerable(index);
                        if ((immunity >= 2 || !GetImmunity(index,Immunity_HealthTaking)) &&
                            (immunity >= 3 || !GetImmunity(index,Immunity_Ultimates)) &&
                            (immunity >= 4 || !isUber))
                        {
                            TE_SetupBeamPoints(clientLoc,indexLoc,g_lightningSprite,g_haloSprite,
                                               0, 1, 10.0, 10.0,10.0,2,50.0,chargeColor,255);
                            TE_SendQEffectToAll(client,index);

                            new dmgamt=RoundFloat(float(dmg)*(1.0+g_ChargePercent[level]));
                            if (isUber)
                                dmgamt /= 2;

                            FlashScreen(index,RGBA_COLOR_RED);
                            HurtPlayer(index, dmgamt, client,
                                       "sc_charge", .type=DMG_SLASH);
                        }
                    }
                }
            }

            if (GetGameType() == tf2)
            {
                if (TF2_IsPlayerDisguised(client))
                    TF2_RemovePlayerDisguise(client);

                if (TF2_IsPlayerCloaked(client))
                    TF2_RemoveCondition(client,TFCond_Cloaked);

                if (TF2_IsPlayerDeadRingered(client))
                {
                    m_ChargeActive[client] = false;
                    return Plugin_Stop;
                }

                new Float:cloakMeter = TF2_GetCloakMeter(client);
                if (cloakMeter > 0.0 && cloakMeter <= 100.0)
                    TF2_SetCloakMeter(client, 0.0);

                // Damage Structures
                //
                new Float:pos[3];
                new maxents = GetMaxEntities();
                for (new ent = MaxClients; ent < maxents; ent++)
                {
                    if (IsValidEdict(ent) && IsValidEntity(ent))
                    {
                        if (TF2_GetExtObjectType(ent) != TFExtObject_Unknown)
                        {
                            if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team)
                            {
                                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
                                if (IsPointInRange(clientLoc, pos, range) &&
                                    TraceTargetEntity(client, ent, clientLoc, pos))
                                {
                                    SetVariantInt(dmg);
                                    AcceptEntityInput(ent, "RemoveHealth", client, client);
                                }
                            }
                        }
                    }
                }
            }

            // Push charging player forward
            //
            new Float:vecVelocity[3];
            vecVelocity[0]=ReadPackFloat(pack);
            vecVelocity[1]=ReadPackFloat(pack);
            vecVelocity[2]=ReadPackFloat(pack);
            TeleportPlayer(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);

            new num = GetRandomInt(0,sizeof(g_ChargeAttackSound)-1);
            PrepareAndEmitSoundToAll(g_ChargeAttackSound[num], client);

            if (++count < level*6)
            {
                ResetPack(pack);
                WritePackCell(pack, count);
                return Plugin_Continue;
            }
        }
        m_ChargeActive[client] = false;
    }
    return Plugin_Stop;
}

Push(victim, Float:victimLoc[3], const Float:clientLoc[3], Float:force, Float:vertForce)
{
    victimLoc[2] += 5;
    PrepareAndEmitSoundToAll(g_ChargeSound,victim);
    TE_SetupSparks(victimLoc,victimLoc,255,1);
    TE_SendEffectToAll();

    new Float:vector[3];
    MakeVectorFromPoints(victimLoc, clientLoc, vector);
            
    NormalizeVector(vector, vector);
    ScaleVector(vector, force);
    if (vector[2] < vertForce)
        vector[2] = vertForce;
            
    TeleportPlayer(victim, NULL_VECTOR, NULL_VECTOR, vector);
}
