/**
 * vim: set ai et ts=4 sw=4 :
 * File: area.inc
 * Description: Area Type bits
 * Author(s): -=|JFH|=-Naris
 */

#if defined _area_included
 #endinput
#endif
#define _area_included

enum AreaType (<<= 1)
{
    Area_None = 0,
    Area_Team = 0,
    Area_Enemy = 1,
    Area_LineOfSight,
    Area_NotifyState,
    Area_NotifyTime,
    Area_Beacon,
};
