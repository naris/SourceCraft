/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: RecallTeam.inc
 * Description: SourceCraft Upgrade to recall team mates.
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined _RecallTeam_included
 #endinput
#endif
#define _RecallTeam_included

#include <gametype>
#include <tf2_flag>
#include <TeleportPlayer>

#include "sc/RecallSounds"
#include "sc/ShopItems"
#include "sc/Burrow"

stock RecallTeam(client, raceId, upgradeId)
{
    if (!IsValidClientAlive(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "YouHaveDied", upgradeName);
        PrepareAndEmitSoundToClient(client,recallErrWav);
    }
    else if (IsMole(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotAsMole", upgradeName);
        PrepareAndEmitSoundToClient(client,recallErrWav);
    }
    else if (GetGameType() == tf2 && TF2_HasTheFlag(client))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "NotWithFlag", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
    }
    else if (GetRestriction(client,Restriction_NoUltimates) ||
             GetRestriction(client,Restriction_Stunned))
    {
        decl String:upgradeName[64];
        GetUpgradeName(raceId, upgradeId, upgradeName, sizeof(upgradeName), client);
        DisplayMessage(client, Display_Ultimate, "%t", "Prevented", upgradeName);
        PrepareAndEmitSoundToClient(client,deniedWav);
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
                     TF2_IsPlayerDeadRingered(client) ||
                     TF2_IsPlayerDisguised(client))
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
                return;
            }
        }

        if (CanInvokeUpgrade(client, raceId, upgradeId))
        {
            new team = GetClientTeam(client);
            new flagcarrier = TF2_GetFlagCarrier(team);
            for (new index=1;index<=MaxClients;index++)
            {
                if (IsClientInGame(index) && IsPlayerAlive(index))
                {
                    if (index != client && GetClientTeam(index) == team && index != flagcarrier)
                    {
                        decl String:buf[12];
                        IntToString(client, buf, sizeof(buf));

                        new Handle:menu=CreateMenu(Recall_Selected);
                        SetMenuTitle(menu, "[SC] %T", "RecallTeamTitle", index, client);
                        AddMenuItem(menu,buf,"Yes");
                        AddMenuItem(menu,"0","No");
                        DisplayMenu(menu,index,MENU_TIME_FOREVER);

                        new Float:pos[3];
                        GetClientAbsOrigin(index, pos);

                        PrepareAndEmitSoundToClient(index,recallQryWav);
                    }
                }
            }

            CreateCooldown(client, raceId, upgradeId);
        }
    }
}

public Recall_Selected(Handle:menu,MenuAction:action,index,selection)
{
    if (action == MenuAction_Select)
    {
        PrepareAndEmitSoundToClient(index,buttonWav);
        
        decl String:SelectionInfo[12];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

        new id = StringToInt(SelectionInfo);
        if (IsValidClient(id) && IsValidClientAlive(id) &&
            GetClientTeam(id) == GetClientTeam(index))
        {
            if (TF2_HasTheFlag(index))
            {
                decl String:beRecalled[64];
                Format(beRecalled, sizeof(beRecalled), "%T", "BeRecalled",index);
                DisplayMessage(index, Display_Ultimate, "%t", "NotWithFlag", beRecalled);
                PrepareAndEmitSoundToClient(index, deniedWav);
            }
            else
            {
                if (IsBurrowed(index))
                    ResetBurrow(index);

                new Float:src[3];
                GetClientAbsOrigin(index, src);

                PrepareAndEmitAmbientSound(recallSrcWav,src);

                new Float:pos[3];
                GetClientAbsOrigin(id, pos);

                new Float:angles[3];
                GetClientAbsAngles(id, angles);

                TeleportPlayer(index, pos, angles, NULL_VECTOR); // Teleport to id's position

                PrepareAndEmitAmbientSound(recallDstWav,pos,id);
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}
