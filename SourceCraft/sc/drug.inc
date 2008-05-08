/**
* vim: set ai et ts=4 sw=4 syntax=sourcepawn :
* =============================================================================
* SourceMod Basefuncommands Plugin
* Provides drug functionality
*
* SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
* =============================================================================
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License, version 3.0, as published by the
* Free Software Foundation.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program.  If not, see <http://www.gnu.org/licenses/>.
*
* As a special exception, AlliedModders LLC gives you permission to link the
* code of this program (as well as its derivative works) to "Half-Life 2," the
* "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
* by the Valve Corporation.  You must obey the GNU General Public License in
* all respects for all other code used.  Additionally, AlliedModders LLC grants
* this exception to all derivative works.  AlliedModders LLC defines further
* exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
* or <http://www.sourcemod.net/license.php>.
*
* Version: $Id: drug.sp 1833 2007-12-28 16:46:42Z ferret $
*/

new Handle:g_DrugTimers[MAXPLAYERS+1];
new Float:g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;

SetupDrugs()
{
    g_FadeUserMsgId = GetUserMessageId("Fade");
}

CreateDrug(client)
{
    g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);	
}

KillDrug(client)
{
    KillDrugTimer(client);

    new Float:pos[3];
    GetClientAbsOrigin(client, pos);
    new Float:angs[3];
    GetClientEyeAngles(client, angs);

    angs[2] = 0.0;

    TeleportEntity(client, pos, angs, NULL_VECTOR);	

    new clients[2];
    clients[0] = client;	

    new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
    BfWriteShort(message, 1536);
    BfWriteShort(message, 1536);
    BfWriteShort(message, (0x0001 | 0x0010));
    BfWriteByte(message, 0);
    BfWriteByte(message, 0);
    BfWriteByte(message, 0);
    BfWriteByte(message, 0);
    EndMessage();	
}

KillDrugTimer(client)
{
    KillTimer(g_DrugTimers[client]);
    g_DrugTimers[client] = INVALID_HANDLE;	
}

KillAllDrugs()
{
    new maxclients = GetMaxClients();
    for (new i = 1; i <= maxclients; i++)
    {
        if (g_DrugTimers[i] != INVALID_HANDLE)
        {
            if(IsClientInGame(i))
            KillDrug(i);
            else
            KillDrugTimer(i);
        }
    }
}

bool:PerformDrug(target, toggle)
{
    switch (toggle)
    {
        case (2):
        {
            if (g_DrugTimers[target] == INVALID_HANDLE)
            {
                CreateDrug(target);
                return true;
            }
            else
            KillDrug(target);
        }

        case (1):
        {
            if (g_DrugTimers[target] == INVALID_HANDLE)
            {
                CreateDrug(target);
                return true;
            }
        }

        case (0):
        {
            if (g_DrugTimers[target] != INVALID_HANDLE)
            KillDrug(target);
        }
    }
    return false;
}

public Action:Timer_Drug(Handle:timer, any:client)
{
    if (!IsClientInGame(client))
    {
        KillDrugTimer(client);
        return Plugin_Handled;
    }

    if (!IsPlayerAlive(client))
    {
        KillDrug(client);
        return Plugin_Handled;
    }

    new Float:pos[3];
    GetClientAbsOrigin(client, pos);

    new Float:angs[3];
    GetClientEyeAngles(client, angs);

    angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];

    TeleportEntity(client, pos, angs, NULL_VECTOR);

    new clients[2];
    clients[0] = client;	

    new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
    BfWriteShort(message, 255);
    BfWriteShort(message, 255);
    BfWriteShort(message, (0x0002));
    BfWriteByte(message, GetRandomInt(0,255));
    BfWriteByte(message, GetRandomInt(0,255));
    BfWriteByte(message, GetRandomInt(0,255));
    BfWriteByte(message, 128);

    EndMessage();	

    return Plugin_Handled;
}
