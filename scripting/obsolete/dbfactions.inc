/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: dbfactions.inc
 * Description: Sets up the sc_factions table in the database
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _dbfactions_included
 #endinput
#endif
#define _dbfactions_included

stock SetupFactions(Handle:dbHandle)
{
    // Faction information
    new const String:factionDesc[Faction][]  = { "",
        "The terrans are a young technology species with psionic potential. The terrans of the Koprulu Sector descend from the survivors of a 23rd century colonization mission from Earth. Compared to the protoss and zerg, the terrans are highly factionalized and endure frequent wars amongst themselves in addition to the more recent conflicts with their alien neighbors.  The term terran generally refers to the humans descending from the survivors of the \"Long Sleep\" and consequently to the human inhabitants of the Koprulu Sector. The term may be used synonymously with human and terrans of the Sector may extend its meaning to encompass those not descending from the \"Long Sleep\".  Humans of the Earth-based United Earth Directorate refer to themselves as humans, mankind or humanity. However, they are sometimes referred to as terrans as well.",
        "The protoss are a sentient humanoid race native to Aiur. They are technologically advanced and rely on psionic abilities and cybernetics in battle. They are the primary opponents of the zerg. The protoss of Aiur are highly religious and follow a strict code known as the Khala. The protoss have mastered their psionic powers and were recently engaged in a devastating war with the zerg. They have also had to deal with civil wars within their ranks.  Protos in Greek means 'first'. This name is given because the protoss were the first semi-successful xel'naga creation. The protoss were later deemed a failure by the greater species, leading to the engineering of the zerg.",
        "The zerg are a terrifying and ruthless amalgamation of biologically advanced, arthropodal aliens. Dedicated to the pursuit of genetic perfection, the zerg relentlessly hunt down and assimilate advanced species across the galaxy, incorporating useful genetic code into their own, and exterminate any species that might corrupt the purity of the zerg genome.",
        "The noble warriors of humanity employ both a strong military and powerful magics in the defense of their shining kingdoms. Both knights and wizards fight side by side on the field of battle against those who would threaten the sanctity and peace of the Alliance. Although the Alliance has all but fallen apart, the valiant citizens of Azeroth and Lordaeron have once again taken up arms against the enemies of humanity.",
        "The Orcs, who once cultivated a quiet Shamanistic society upon the world of Draenor, were corrupted by the chaos magics of the Burning Legion and formed into a voracious, unstoppable Horde. Lured to the world of Azeroth through a dimensional gateway, the Horde was manipulated into waging war against the human nations of Azeroth and Lordaeron. Hoping that the Horde would conquer the mortal armies of Azeroth, the Burning Legion made ready for its final invasion of the unsuspecting world.",
        "The reclusive Night Elves were the first race to awaken in the World. These shadowy, immortal beings were the first to study magic and let it loose throughout the world nearly ten thousand years ago. The Night Elves' reckless use of magic drew the Burning Legion into the world and led to a catastrophic war between the two titanic races. The Night Elves barely managed to banish the Legion from the world, but their wondrous homeland was shattered and drowned by the sea. Ever since, the Night Elves refused to use magic for fear that the dreaded Legion would return. The Night Elves closed themselves off from the rest of the world and remained hidden atop their holy mountain of Hyjal for many thousands of years. As a race, Night Elves are typically honorable and just, but they are very distrusting of the 'lesser races' of the world. They are nocturnal by nature and their shadowy powers often elicit the same distrust that they have for their mortal neighbors.",
        "The horrifying Undead army, called the Scourge, consists of thousands of walking corpses, disembodied spirits, damned mortal men and insidious extra-dimensional entities. The Scourge was created by the Burning Legion for the sole purpose of sowing terror across the world in anticipation of the Legion's inevitable invasion. The Undead are ruled by Ner'zhul, the Lich King, who lords over the icy realm of Northrend from his frozen throne. Ner'zhul commands the terrible plague of undeath, which he sends ever southward into the human lands. As the plague encroaches on the southlands, more and more humans fall prey to Ner'zhul's mental control and life-draining sickness every day. In this way, Ner'zhul has swelled the ranks of the already considerable Scourge. The Undead employ necromantic magics and the elemental powers of the cold north against their enemies.",
        "The Burning Legion (a.k.a. the great burning shadow, the Legion of the Lower Planes, or simply The Legion) is a vast, innumerable army of demons, infernals, and corrupted races who seek to destroy any trace of order in the universe. They have thrice invaded Azeroth, and were only beaten back at a terrible cost. Much of Azeroth's history  including the First, Second, and Third War were due to the Legion's influence. It should also be noted that Azeroth is the only known planet that they have ever failed to conquer.\nThe Legion's mission is, in theory, to undo the works of the titans and restore the universe back to its original, chaotic and disorganized state. In practice, the Legion scours all life, down to the last plant and mineral, from the worlds it invades. The Legion is thus responsible for the genocide of thousands of races across the universe billions, if not trillions of lives.",
        "The Hellbourne is a vast, innumerable army of walking corpses, disembodied spirits, damned mortal men, insidious extra-dimensional entities, demons, infernals, and corrupted races who seek to destroy any trace of order in the universe.",
        "The Legion consists of powerful cultures and groups bound not by desperation or necessity, but by their deep commitments to abstract concepts like nobility and honor that stuggles against the Scourge.",
        "The Sentinel consists of powerful cultures and groups bound not by desperation or necessity, but by their deep commitments to abstract concepts like nobility and honor that stuggles against the Hellbound",
        "The naga are former Highborne night elves who mutated into vengeful humanoid sea serpents. While many remain on Azeroth to attempt to reclaim the surface world, a large group followed the power-mad betrayer, Illidan Stormrage, into Outland and proceeded to claim the watery areas of the shattered land. In addition to their natural longevity, a number of naga develop mutations that increase their life spans even further. Some are immortal.",
        "The Titans, also known as the Makers, the Travelers (to the trolls), or the Great Ones (to the Oracles), are a race of extremely powerful, majestic creatures, akin to gods. These metallic giants traveled across the cosmos bringing order to worlds. Many believe them to simply be a progenitor race.",
        "The xel'naga are a psionically-attuned, ancient, cosmic race. They were occasionally referred to as the most powerful species known in the universe. While there are vague references of the xel'naga conquering worlds and uplifting species, their most notable involvement was with the protoss and zerg. Their interest in these two species was due to the xel'naga's cyclical life cycle. When the incredibly long-lived xel'naga were due to come to an end, the xel'naga would use these two species to be reborn. Ironically their survival was severely jeopardized when the zerg turned on them.\nThe xel'naga cherished all life and refused to kill anything. The protoss eventually followed a version of this philosophy, called the \"Dae'Uhl\".\nThe terminology of the word \"xel'naga\" has been described as a protoss language term meaning \"Wanderers from Afar\" but has also been described as their true name.  The protoss referred to the xel'naga as the Ihan-rii."};

    // Faction images
    new const String:factionImage[Faction][]  = { "",
        "/sc/images/Terran/Terran_Icon.jpg",
        "/sc/images/Protoss/Protoss_Icon.jpg",
        "/sc/images/Zerg/Zerg_Icon.jpg",
        "/sc/images/Alliance/humanseal.gif",
        "/sc/images/Horde/orcseal.gif",
        "/sc/images/NightElf/nightelfseal.gif",
        "/sc/images/Scourge/undeadseal.gif",
        "/sc/images/Legion/March_of_the_Legion.jpg",
        "/sc/images/Scourge/undeadseal.gif",
        "/sc/images/Alliance/humanseal.gif",
        "/sc/images/NightElf/nightelfseal.gif",
        "/sc/images/Misc/Naga.jpg",
        "/sc/images/Misc/Jotun.jpg",
        "/sc/images/Misc/XelNaga2-1.jpg"};

    for (new Faction:f = Terran; f < Faction:sizeof(factionDesc); f++)
    {
        InsertFaction(dbHandle, f,
                      g_FactionNames[Faction:f],
                      factionDesc[f],
                      factionImage[f]);
    }
}

