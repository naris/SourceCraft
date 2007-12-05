/*
 * vim: set ai et ts=4 sw=4 syntax=cpp :
File: offsets.inc
Description: Offset definitions.
Author(s): Anthony Iacono  
*/

new m_OffsetLifestate;
new m_OffsetSpeed;
new m_OffsetGravity[MAXPLAYERS+1];

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
    if(m_OffsetLifestate==-1)
    {
        PrintToServer("[War3Source] Error finding speed offset.");
        ret=false;
    }
    return ret;
}
