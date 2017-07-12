/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: bubble.inc
 * Description: Declares the bubble sprite for SourceCraft.
 * Author(s): Naris (Murray Wilson)
 */

#if defined _bubble_included
 #endinput
#endif
#define _bubble_included

#include <lib/ResourceManager>

stock g_bubbleModel;

stock const String:g_bubbleModelName[] = "materials/effects/bubble.vmt";

#define SetupBubbleModel() SetupModel(g_bubbleModelName, g_bubbleModel)
#define BubbleModel()      PrepareModel(g_bubbleModelName, g_bubbleModel)
