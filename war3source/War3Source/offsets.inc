/*
 * vim: set ai et ts=4 sw=4 :
 * File: offsets.inc
 * Description: Offset definitions.
 * Author(s): Anthony Iacono  
 */

new m_OffsetLifestate              = 0;
new m_OffsetSpeed                  = 0;
new m_OwnerOffset                  = 0;
new m_ColorOffset                  = 0;
new m_RenderModeOffset             = 0;
new m_OffsetGravity[MAXPLAYERS+1]  = { 0, ... };
new m_OffsetMaxSpeed[MAXPLAYERS+1] = { 0, ... };

public bool:War3Source_InitOffset()
{
    new bool:ret=true;

    m_OffsetLifestate=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
    if(m_OffsetLifestate==-1)
    {
        PrintToServer("[War3Source] Error finding life state offset.");
        ret=false;
    }

    m_OffsetSpeed=FindSendPropOffs("CBasePlayer","m_flLaggedMovementValue");
    if(m_OffsetSpeed==-1)
    {
        PrintToServer("[War3Source] Error finding speed offset.");
        ret=false;
    }

    m_OwnerOffset = FindSendPropOffs("CBaseEntity", "m_hOwnerEntity");
    if(m_OwnerOffset==-1)
    {
        PrintToServer("[War3Source] Error finding OwnerEntity offset.");
        ret=false;
    }

    m_ColorOffset=FindSendPropOffs("CAI_BaseNPC","m_clrRender");
    if(m_ColorOffset==-1)
    {
        PrintToServer("[War3Source] Error finding Color offset.");
        ret=false;
    }

    m_RenderModeOffset=FindSendPropOffs("CBaseAnimating","m_nRenderMode");
    if(m_RenderModeOffset==-1)
    {
        PrintToServer("[War3Source] Error finding RenderMode offset.");
        ret=false;
    }

    return ret;
}
