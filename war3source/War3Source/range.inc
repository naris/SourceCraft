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

stock Float:DistanceBetween(Float:startvec[3],Float:endvec[3])
{
    new Float:distance = SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+
                                    (startvec[1]-endvec[1])*(startvec[1]-endvec[1])+
                                    (startvec[2]-endvec[2])*(startvec[2]-endvec[2]));

    if (distance < 0)
        distance *= -1;

    return distance;                                  
}

stock bool:IsInRange(client,index,Float:maxdistance)
{
    new Float:startclient[3];
    new Float:endclient[3];
    GetClientAbsOrigin(client,startclient);
    GetClientAbsOrigin(index,endclient);
    new Float:distance=DistanceBetween(startclient,endclient);
    return (distance<maxdistance);
}

stock PowerOfRange(Float:location[3],Float:radius,Float:check_location[3],maxhp)
{
    new Float:distance=DistanceBetween(location,check_location);
    new Float:healthtakeaway=0.0;
    if(distance<radius)
        healthtakeaway=1-FloatDiv(distance,radius)+0.20;
    return RoundFloat(float(maxhp)*healthtakeaway);
}

