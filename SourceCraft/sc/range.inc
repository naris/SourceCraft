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

stock Float:DistanceBetween(const Float:startvec[3],const Float:endvec[3])
{
    new Float:distance = SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+
                                    (startvec[1]-endvec[1])*(startvec[1]-endvec[1])+
                                    (startvec[2]-endvec[2])*(startvec[2]-endvec[2]));

    if (distance < 0)
        distance *= -1;

    return distance;                                  
}

stock bool:IsPointInRange(const Float:start[3], const Float:end[3],Float:maxdistance)
{
    return (DistanceBetween(start,end)<maxdistance);
}

stock bool:IsInRange(client,index,Float:maxdistance)
{
    new Float:start[3];
    new Float:end[3];
    GetClientAbsOrigin(client,start);
    GetClientAbsOrigin(index,end);
    return (DistanceBetween(start,end)<maxdistance);
}

stock PowerOfRange(Float:location[3],Float:radius,Float:check_location[3],maxhp,
                   Float:factor=0.20,bool:limit=true)
{
    if (radius <= 0.0)
        return maxhp;
    else
    {
        new Float:distance=DistanceBetween(location,check_location);
        if (limit && distance > radius)
            return 0;
        else
        {
            new Float:healthtakeaway=1-FloatDiv(distance,radius)+factor;
            return (healthtakeaway > 0.0) ? RoundFloat(float(maxhp)*healthtakeaway) : 0;
        }
    }
}

