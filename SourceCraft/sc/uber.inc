/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: uber.inc
 * Description: Function to determine if Player is Ubered.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _uber_included
 #endinput
#endif
#define _uber_included

stock m_OffsetNumHealers;
stock m_OffsetPlayerCond;

stock FindUberOffsets()
{
    if (GameType == tf2)
    {
        m_OffsetNumHealers=FindSendPropInfo("CTFPlayer","m_nNumHealers");
        if(m_OffsetNumHealers == -1)
            SetFailState("[SourceCraft] Error finding NumHealers offset.");

        m_OffsetPlayerCond=FindSendPropInfo("CTFPlayer","m_nPlayerCond");
        if(m_OffsetPlayerCond == -1)
            SetFailState("[SourceCraft] Error finding PlayerCond offset.");
    }
}

stock IsUber(client)
{
    if (GameType == tf2 && m_OffsetPlayerCond)
        return (GetEntData(client,m_OffsetPlayerCond) & 32) != 0;
    else
        return false;
}
