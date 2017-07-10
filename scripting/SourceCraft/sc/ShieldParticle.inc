/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: ShieldParticle.inc
 * Description: Functions to show Shield Particles
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _ShieldParticle_included
 #endinput
#endif
#define _ShieldParticle_included

#if defined ENABLE_SHIELD_PARTICLES
stock g_ShieldParticle[MAXPLAYERS+1][2];

stock ShowShieldParticle(client)
{
    new armor = GetArmor(client);
    if (armor > 25)
    {
        new Float:pos[3];
        pos[2] = 70.0;
        new Float:ang[3];
        ang[2] = 180.0;

        new team = GetClientTeam(client);
        if (TF2_GetPlayerClass(client) == TFClass_Spy)
        {
            if (TF2_IsPlayerCloaked(client))
            {
                DeleteShieldParticles(client);
                return;
            }
            else if (TF2_IsPlayerDisguised(client))
                team = (team == 2) ? 3 : 2;
        }

        if( team == 2 )
        {
            if (g_ShieldParticle[client][0] <= 0)
                g_ShieldParticle[client][0] = CreateParticle("teleporter_red_exit", 0.0, client, Attach, "", pos, ang);

            if (g_ShieldParticle[client][1] <= 0)
                g_ShieldParticle[client][1] = CreateParticle("teleporter_red_entrance", 0.0, client, Attach, "");
        }
        else if( team == 3 )
        {
            if (g_ShieldParticle[client][0] <= 0)
                g_ShieldParticle[client][0] = CreateParticle("teleporter_blue_exit", 0.0, client, Attach, "", pos, ang);

            if (g_ShieldParticle[client][1] <= 0)
                g_ShieldParticle[client][1] = CreateParticle("teleporter_blue_entrance", 0.0, client, Attach, "");
        }	
    }
    else
        DeleteShieldParticles(client);
}

stock DeleteShieldParticles(client)
{
    if (IsClientInGame(client))
    {
        new particle = g_ShieldParticle[client][0];
        if (particle != 0)
        {
            DeleteParticle(particle);
            g_ShieldParticle[client][0] = 0;
        }

        particle = g_ShieldParticle[client][1];
        if (particle != 0)
        {
            DeleteParticle(particle);
            g_ShieldParticle[client][1] = 0;
        }
    }
}
#else
    #define ShowShieldParticle(%1);
    #define DeleteShieldParticles(%1);
#endif
