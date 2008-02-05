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
        {
            LogError("[SourceCraft] Error finding NumHealers offset.");
            ret=false;
        }

        m_OffsetPlayerCond=FindSendPropInfo("CTFPlayer","m_nPlayerCond");
        if(m_OffsetPlayerCond == -1)
        {
            LogError("[SourceCraft] Error finding PlayerCond offset.");
            ret=false;
        }
    }
}

stock IsUber(client)
{
    if (GameType == tf2)
        return GetEntData(client,m_OffsetNumHealers) > 0 &&
               (GetEntData(client,m_OffsetPlayerCond) & 2080);
    else
        return false;
}
