/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: Detector.inc
 * Description: The Detector Upgrade for SourceCraft.
 * Author(s): -=|JFH|=-Naris
 */
 
#include "sc/plugins"

stock bool:m_Detected[MAXPLAYERS+1][MAXPLAYERS+1];

stock ClearDetectedHud(client)
{
    decl String:message[64];
    GetHudMessage(client, message, sizeof(message));

    decl String:detected[64];
    Format(message, sizeof(message), "%T", "DetectedHud", client);
    ReplaceString(message, sizeof(message), "*", "");
    ReplaceString(message, sizeof(message), " ", "");

    decl String:uncloaked[64];
    Format(message, sizeof(message), "%T", "UncloakedHud", client);
    ReplaceString(message, sizeof(message), "*", "");
    ReplaceString(message, sizeof(message), " ", "");

    if (StrContains(message, detected) != -1 ||
        StrContains(message, uncloaked) != -1)
    {
        ClearHud(client);
    }
}

stock ResetDetection(client)
{
    for (new index=1;index<=MaxClients;index++)
    {
        if (IsClientInGame(index))
        {
            SetOverrideVisiblity(index, -1, m_Detected[client][index]);
            if (m_SidewinderAvailable)
                SidewinderDetectClient(index, false);
        }

        if (m_Detected[client][index])
        {
            m_Detected[client][index] = false;
            ClearDetectedHud(index);
        }
    }
}

stock ResetDetected(index)
{
    if (IsClient(index))
    {
        SetOverrideVisiblity(index, -1);
        if (m_SidewinderAvailable && IsClientInGame(index))
            SidewinderDetectClient(index, false);

        for (new client=1;client<=MaxClients;client++)
        {
            if (m_Detected[client][index])
            {
                m_Detected[client][index] = false;
                ClearDetectedHud(index);
            }
        }
    }
}

