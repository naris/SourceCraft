/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: offsets.inc
 * Description: Offset definitions.
 * Author(s): Anthony Iacono  
 */

new m_OffsetSpeed=-1;
new m_OwnerOffset=-1;
new m_VelocityOffset=-1;
new m_OffsetGravity[MAXPLAYERS+1]={-1,...};

new m_OffsetClass=-1;
new m_OffsetMaxSpeed=-1;
new m_OffsetNumHealers=-1;
new m_OffsetPlayerCond=-1;

bool:InitOffset()
{
    new bool:ret=true;

    m_OffsetSpeed=FindSendPropInfo("CBasePlayer","m_flLaggedMovementValue");
    if(m_OffsetSpeed==-1)
    {
        LogError("Error finding speed offset.");
        ret=false;
    }

    m_OwnerOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
    if(m_OwnerOffset==-1)
    {
        LogError("Error finding OwnerEntity offset.");
        ret=false;
    }

    m_VelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
    if(m_VelocityOffset == -1)
    {
        LogError("Error finding Velocity offset.");
        ret=false;
    }

    return ret;
}

bool:InitTFOffset()
{
    new bool:ret=true;

    m_OffsetClass=FindSendPropInfo("CTFPlayer","m_iClass");
    if(m_OffsetClass == -1)
    {
        LogError("Error finding Class offset.");
        ret=false;
    }

    m_OffsetMaxSpeed=FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
    if(m_OffsetMaxSpeed == -1)
    {
        LogError("Error finding MaxSpeed offset.");
        ret=false;
    }

    m_OffsetNumHealers=FindSendPropInfo("CTFPlayer","m_nNumHealers");
    if(m_OffsetNumHealers == -1)
    {
        LogError("Error finding NumHealers offset.");
        ret=false;
    }

    m_OffsetPlayerCond=FindSendPropInfo("CTFPlayer","m_nPlayerCond");
    if(m_OffsetPlayerCond == -1)
    {
        LogError("Error finding PlayerCond offset.");
        ret=false;
    }
    return ret;
}

