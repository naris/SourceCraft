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

new m_OffsetMaxSpeed=-1;

bool:InitOffset()
{
    new bool:ret=true;

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

    if (GameType == tf2)
    {
        m_OffsetMaxSpeed=FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
        if(m_OffsetMaxSpeed == -1)
        {
            LogError("Error finding MaxSpeed offset.");
            ret=false;
        }
    }
    else
    {
        m_OffsetSpeed=FindSendPropInfo("CBasePlayer","m_flLaggedMovementValue");
        if(m_OffsetSpeed==-1)
        {
            LogError("Error finding speed offset.");
            ret=false;
        }
    }

    return ret;
}

