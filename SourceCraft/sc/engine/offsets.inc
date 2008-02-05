/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: offsets.inc
 * Description: Offset definitions.
 * Author(s): Anthony Iacono  
 */

new m_OffsetSpeed;
new m_OwnerOffset;
new m_VelocityOffset;
new m_OffsetGravity;
new m_OffsetMaxSpeed;

public bool:InitOffset()
{
    new bool:ret=true;

    m_OffsetSpeed=FindSendPropInfo("CBasePlayer","m_flLaggedMovementValue");
    if(m_OffsetSpeed==-1)
    {
        PrintToServer("[SourceCraft] Error finding speed offset.");
        ret=false;
    }

    m_OwnerOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
    if(m_OwnerOffset==-1)
    {
        PrintToServer("[SourceCraft] Error finding OwnerEntity offset.");
        ret=false;
    }

    m_VelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
    if(m_VelocityOffset == -1)
    {
        PrintToServer("[SourceCraft] Error finding Velocity offset.");
        ret=false;
    }

    m_OffsetGravity=FindSendPropInfo("CBasePlayer", "m_flGravity");
    if(m_OffsetGravity == -1)
    {
        PrintToServer("[SourceCraft] Error finding Gravity offset.");
        ret=false;
    }

    if (GameType == tf2)
    {
        m_OffsetMaxSpeed=FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
        if(m_OffsetMaxSpeed == -1)
        {
            PrintToServer("[SourceCraft] Error finding Maxspeed offset.");
            ret=false;
        }
    }
    else
        m_OffsetMaxSpeed = -1;

    return ret;
}
