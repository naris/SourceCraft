/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: range.inc
 * Description: Range and Distance functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _range_included
 #endinput
#endif
#define _range_included

stock bool:IsPointInRange(const Float:start[3], const Float:end[3],Float:maxdistance)
{
    return (GetVectorDistance(start,end)<maxdistance);
}

stock bool:IsInRange(client,index,Float:maxdistance)
{
    new Float:start[3];
    new Float:end[3];
    GetClientAbsOrigin(client,start);
    GetClientAbsOrigin(index,end);
    return (GetVectorDistance(start,end)<maxdistance);
}

stock PowerOfRange(Float:location[3],Float:radius,Float:check_location[3],maxhp,
                   Float:factor=0.20,bool:limit=true)
{
    if (radius <= 0.0)
        return maxhp;
    else
    {
        new Float:distance=GetVectorDistance(location,check_location);
        if (limit && distance > radius)
            return 0;
        else
        {
            new Float:healthtakeaway=1-FloatDiv(distance,radius)+factor;
            return (healthtakeaway > 0.0) ? RoundFloat(float(maxhp)*healthtakeaway) : 0;
        }
    }
}

