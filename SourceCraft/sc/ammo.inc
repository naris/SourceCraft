/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: ammo.inc
 * Description: Ammo functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _ammo_included
 #endinput
#endif
#define _ammo_included

enum AmmoTypes
{
    Primary=1,
    Secondary=2,
    Metal=3
}

stock m_OffsetClip;
stock m_OffsetAmmoType;
stock m_OffsetActiveWeapon;

stock m_OffsetAmmo[MAXPLAYERS+1];

stock Handle:hGiveAmmo = INVALID_HANDLE;

stock FindClipOffsets()
{
    m_OffsetAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
    if(m_OffsetAmmoType==-1)
        SetFailState("Couldn't find PrimaryAmmoType offset");

    m_OffsetClip = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
    if(m_OffsetClip==-1)
        SetFailState("Couldn't find m_iClip1 offset");

    if (GameType == tf2)
    {
        m_OffsetActiveWeapon=FindSendPropOffs("CTFPlayer","m_hActiveWeapon");
        if(m_OffsetActiveWeapon==-1)
            SetFailState("Couldn't find ActiveWeapon offset");
    }
    else
    {
        m_OffsetActiveWeapon=FindSendPropOffs("CAI_BaseNPC","m_hActiveWeapon");
        if(m_OffsetActiveWeapon==-1)
            SetFailState("Couldn't find ActiveWeapon offset");

        StartPrepSDKCall(SDKCall_Entity);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"GiveAmmo");
        PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
        hGiveAmmo=EndPrepSDKCall();
    }

}

stock FindAmmoOffset(client)
{
    //if (GameType == tf2)
    {
        m_OffsetAmmo[client]=FindDataMapOffs(client,"m_iAmmo");
        if(m_OffsetAmmo[client] == -1)
            LogError("Error finding m_iAmmo offset for %d.", client);
    }
}

stock GetAmmo(entity,AmmoTypes:type)
{
    //if (GameType == tf2)
    {
        if (entity <= MAXPLAYERS && m_OffsetAmmo[entity])
            return GetEntData(entity,m_OffsetAmmo[entity] + (4*_:type));
        else
        {
            new offset = FindDataMapOffs(entity,"m_iAmmo");
            if (offset)
                return GetEntData(entity,offset + (4*_:type));
            else
                return -1;
        }
    }
}

stock SetAmmo(entity,AmmoTypes:type,amount)
{
    //if (GameType == tf2)
    {
        if (entity <= MAXPLAYERS && m_OffsetAmmo[entity])
            SetEntData(entity,m_OffsetAmmo[entity] + (4*_:type),amount);
        else
        {
            new offset = FindDataMapOffs(entity,"m_iAmmo");
            if (offset)
                SetEntData(entity,offset + (4*_:type),amount);
        }
    }
}

stock GetClip(client)
{
    return GetEntDataEnt(client, m_OffsetClip);
}

stock SetClip(weapon, amount)
{
    SetEntData(weapon, m_OffsetClip, amount);
}

stock GetActiveWeapon(client)
{
    return GetEntDataEnt(client, m_OffsetActiveWeapon);
}

stock GetAmmoType(weapon)
{
    return GetEntData(weapon,m_OffsetAmmoType);
}

stock GiveAmmo(client,ammotype,amount,bool:suppress)
{
    SDKCall(hGiveAmmo,client,amount,ammotype,suppress);
}

