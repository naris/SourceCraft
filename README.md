# README #

This README would normally document whatever steps are necessary to get your application up and running.

### What is this repository for? ###

SourceCraft is a mod for TF2, DoD, Counter-Strike, CS-GO and other games built on Valve's SourceEngine. It adds Role Playing (RPG) and Real Time Strategy (RTS) elements into the game.  It does not directly modify any of the core game mechanics or classes, but instead allows players to choose a race to augment the class they are playing with new and enhanced abilities. For example, some races have movement rate improvements which allow them to run faster, many increase damage output, and some add damage absorption (armor or shields). Others add completely new abilities, such as a grappling hook or a jetpack. No one race is the best, and each player must decide what fits their play-style the best.

* Quick summary
* Version
* [Learn Markdown](https://bitbucket.org/tutorials/markdowndemo)

### How do I get set up? ###

* Summary of set up
* Configuration
* Dependencies
* Database configuration
* How to run tests
* Deployment instructions

### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

* Repo owner or admin
* Other community or team contact

### What is SourceCraft? ###

SourceCraft is a mod for TF2, DoD, Counter-Strike, CS-GO and other games built on Valve's SourceEngine. It adds Role Playing (RPG) and Real Time Strategy (RTS) elements into the game.  It does not directly modify any of the core game mechanics or classes, but instead allows players to choose a race to augment the class they are playing with new and enhanced abilities. For example, some races have movement rate improvements which allow them to run faster, many increase damage output, and some add damage absorption (armor or shields). Others add completely new abilities, such as a grappling hook or a jetpack. No one race is the best, and each player must decide what fits their play-style the best.

There are many racess, mostly based on the StarCraft and WarCraft genres, each with it's own strengths and weaknesses.  Each race keeps track of the experience points the player has earned while playing it, so each race must be individually leveled up. All experience and levels are saved to a database so that the player does not lose them when they leave the server.  When players first join the game, they will be prompted to choose a race. Players can also change races at any time, but the new race won't become the active until the player respawns.

Many races will not initially be available as they require a minimum amount of overall levels to unlock. The Overall Level is calculated by adding all of the levels the player has across all races. Some races always show as locked, without a minimum level; these are Summoned races, that have to be "summoned" from another race that has the ability to summon it. An example is Protoss Archon, which is summoned from Protoss Templar.

Races are grouped into Factions, such as Terran, Protoss, Zerg, Human Alliance, Undead Scourge, Night Elf, Orcish Hord, etc, based on the backstory of the race. The race menu is then categorized by those factions.

Players gain experience from kills and obtaining objectives, such as capping a flag, which are then used to gain levels in the race they are currently playing. Each level allows the player to choose an upgrade to augment that race. Most upgrades work for any chosen class, though some have restrictions which are typically stated in the ability or are obvious. For example, one race has an ability that allows a medic to charge his uber faster. Obviously, that particular ability does not affect any other class, while damage enhancers will help every class. Some upgrades are passive and other, ultimate upgrades, are invoked using a key bound to an +ultimate command. All experience, levels and upgrades are earned for the player's current race and are not transferrable to other races.

Once a player obtains enough experience points to gain a level in their race, a menu will automatically appear with the available upgrades for that race and an upgrade point can be invested in one of those upgrades. Upgrade points can be reset at any time, so the expenditure is not permanent. Note, some upgrades require a minimum level in a given race to be able to spend points into them.

There are two categories of upgrades: passive and ultimates. Passive upgrades happen automatically, while ultimates are used via keybindings. An example of a passive upgrade would be U238 shells, which increase the damage done by weapons. Each shot automatically has the damage bonus applied. On the other hand, an example of an ultimate upgrade would be Jetpack, which allows the player to fly around a map.

Most ultimate upgrades consume energy while only some passive ones do. Those upgrades that consume energy will not operate without a sufficient energy supply. Energy is automatically accumulated during play, usually 1 per second, and does not require any effort on the player's part to obtain.

When a player dies, any energy they have will be added to a special category of "accumulated energy". Only a few upgrades can use "accumulated energy". Typically upgrades that require a large amount of energy, such as most race summons that require 100-300 or more energy.

Players will also earn crystals and/or vespene from kills and objectives that allow them to purchase items in the shopmenu to add to thier arsenal of abilities. Most are passive, but there are some items, such as jetpack, nades & mines, that are invoked, usually by using a key bound to an +item command. Most items are lost when a player dies unless they own the Ankh of Reincarnation, which will be lost instead (which can then be be re-purchased, if desired).

Several race's upgrades also consume Vespene, such as Zerg Drone's Mutate, and won't function without a sufficient vespene supply.

Experience points, levels, crystals, vespene, and energy all are all automatically displayed in chat each time a player spawns.  Energy, armor, crystals and vespene are also displayed continously in an additional HUD while the player is alive.  There are commands to view each one while in play, which is detailed in the commands section. There is also a settings menu that contains toggles for what information is sent to the screen, amongst other preferences.

Sourcecraft options are accessed by typing 'menu' into chat. From there you can do just about anything. For a description of the different races and what their upgrades do type "raceinfo" into chat or refer to the http://www.jigglysfunhouse.net/sc web site. You can access the shop menu through the mod menu or by typing 'buy into chat.  Upgrades can be reassigned any time through the mod menu or by typing "reset" into chat. The next time you spawn you will be asked to reassign your upgrade points.

Sourcecraft, in all its glory, does a lot of unusual and unexpected things. Do not be surprised to spawn and find someone from the other team waiting there to greet you. Some engineers can carry their sentry guns, some spies run as fast as a scout and cloak for a lot longer than normal, and medics often charge ubers quicker. Just about anything can happen.

Commands:          |                              |
-------------------|------------------------------|
say menu           |Bring up the SourceCraft menu.
sc_menu            |Allows you to bind a key to bring up the SourceCraft menu.
say showxp         |Show the current experience information for the current race.
say changerace     |Change to a different race
say raceinfo       |Display information for all the races.
say upgradeinfo    |Display the upgrade information for the current race.
say reset          |Resets all your upgrade levels for the current race and allows you to rechoose
say upgrade        |Spend any unused upgrade points you have.
say showupgrades   |Show which upgrade levels you currently have.
say shopmenu       |Bring up the shop menu to buy items.
say info           |Show your status (race, level, upgrades and items).
say inv            |Show what items you currently possess
say crystals       |Show your current crystal count.
say vespene        |Show your current vespene gas amount.
say energy         |Show your current energy
say playerinfo     |Show someone else\'s status.
say settings       |Change your settings
sc_admin           |Bring up the admin menu to modify player info.
sc_buy             |Allows you to bind buying shop items.
+ultimate1         |Use your 1st ultimate that requires a bind
+ultimate2         |Use your 2nd ultimate that requires a bind
+ultimate3         |Use your 3rd ultimate that requires a bind
+ultimate4         |Use your 4th ultimate that requires a bind
+item1             |Throw a frag nade if you have one
+item2             |Throw a special nade if you have one
+item3             |Plant a mine if you have one
+item4             |Plant a tripmine if you have one
+nade1             |Throw a frag nade if you have one
+nade2             |Throw a special nade if you have one

