CREATE TABLE IF NOT EXISTS sc_races
(race_ident int not null auto_increment,
 race_name varchar(16) not null,
 long_name varchar(64),
 required_level int,
 tech_level int,
 parent_name varchar(16),
 description text,
 image varchar(45),
 add_date timestamp NOT NULL default current_timestamp,
 type enum ('Biological', 'Mechanical', 'BioMechanical', 'Robotic',
            'Energy', 'Magical', 'Mystical', 'Elemental', 'Undead'),
 faction enum ('Terran', 'Protoss', 'Zerg', 'HumanAlliance', 'OrcishHoard',
               'NightElf', 'UndeadScourge', 'Naga', 'XelNaga'),
PRIMARY KEY(race_ident),
INDEX(type,race_name),
INDEX(race_name))
ENGINE=INNODB;
