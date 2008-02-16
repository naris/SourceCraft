/*
File: immunity.inc
Description: All the immunity types.
Author(s): Naris
*/

// The types of immunities you can get/set from.
enum Immunity
{
	Immunity_Ultimates,  // Immune from ultimates
	Immunity_HealthTake, // Immune from health taking
	Immunity_Explosion,  // Immune from explosion based stuff
	Immunity_ShopItems,  // Immune from shop items
	Immunity_Freezing,   // Immune from freezing
	Immunity_Fire        // Immune from fire (does NOT include pyro's flames)
};

#define IMMUNITY_COUNT 6

