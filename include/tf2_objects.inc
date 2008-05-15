/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2_objects.inc
 * Description: Functions to return infomation about TF2 objects.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _tf2_objects_included
 #endinput
#endif
#define _tf2_objects_included

enum objects { dispenser, teleporter_entry, teleporter_exit, sentrygun, sapper, unknown };

stock String:TF2_ObjectNames[objects][] = { "Dispenser", "Teleporter Entrance", "Teleporter Exit", "Sentry Gun", "Sapper", "" };

