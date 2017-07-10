CREATE TABLE IF NOT EXISTS sc_factions
(faction enum ('Terran', 'Protoss', 'Zerg', 'HumanAlliance', 'OrcishHoard',
               'NightElf', 'UndeadScourge', 'Naga', 'XelNaga'),
 long_name varchar(64),
 description text,
 image varchar(45),
 add_date timestamp NOT NULL default current_timestamp,
PRIMARY KEY(faction))
ENGINE=INNODB;
