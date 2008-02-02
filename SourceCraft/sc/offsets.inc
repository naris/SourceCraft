/*
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: offsets.inc
 * Description: Offset definitions.
 * Author(s): Anthony Iacono  
 */

new m_OffsetLifestate;
new m_OffsetSpeed;
new m_OwnerOffset;
new m_ColorOffset;
new m_RenderModeOffset;
new m_VelocityOffset;
new m_OffsetGravity[MAXPLAYERS+1];
new m_OffsetMaxSpeed[MAXPLAYERS+1];

public bool:InitOffset()
{
    new bool:ret=true;

    m_OffsetLifestate=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
    if(m_OffsetLifestate==-1)
    {
        PrintToServer("[SourceCraft] Error finding life state offset.");
        ret=false;
    }

    m_OffsetSpeed=FindSendPropOffs("CBasePlayer","m_flLaggedMovementValue");
    if(m_OffsetSpeed==-1)
    {
        PrintToServer("[SourceCraft] Error finding speed offset.");
        ret=false;
    }

    m_OwnerOffset = FindSendPropOffs("CBaseEntity", "m_hOwnerEntity");
    if(m_OwnerOffset==-1)
    {
        PrintToServer("[SourceCraft] Error finding OwnerEntity offset.");
        ret=false;
    }

    m_ColorOffset=FindSendPropOffs("CAI_BaseNPC","m_clrRender");
    if(m_ColorOffset==-1)
    {
        PrintToServer("[SourceCraft] Error finding Color offset.");
        ret=false;
    }

    m_RenderModeOffset=FindSendPropOffs("CBaseAnimating","m_nRenderMode");
    if(m_RenderModeOffset==-1)
    {
        PrintToServer("[SourceCraft] Error finding RenderMode offset.");
        ret=false;
    }

    m_VelocityOffset = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
    if(m_VelocityOffset == -1)
    {
        PrintToServer("[SourceCraft] Error finding Velocity offset.");
        ret=false;
    }

    return ret;
}
