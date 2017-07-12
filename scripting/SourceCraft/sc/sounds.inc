/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: sounds.inc
 * Description: Defines Common SourceCraft Sounds
 * Author(s): -=|JFH|=-Naris
 */
 
#if defined sounds_included
 #endinput
#endif
#define sounds_included

#include <lib/ResourceManager>

stock const String:errorWav[]    = "sc/perror.mp3";
stock const String:deniedWav[]   = "sc/buzz.wav";
stock const String:buttonWav[]   = "buttons/button14.wav";
stock const String:rechargeWav[] = "sc/transmission.wav";

#define SetupErrorSound()    SetupSound(errorWav, true, DOWNLOAD, true, true)
#define SetupDeniedSound()   SetupSound(deniedWav, true, DOWNLOAD, true, true)
#define SetupButtonSound()   SetupSound(buttonWav, true, DONT_DOWNLOAD, true, true)
#define SetupRechargeSound() SetupSound(rechargeWav, true, DOWNLOAD, true, true)
