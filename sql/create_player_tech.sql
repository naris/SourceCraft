CREATE TABLE IF NOT EXISTS sc_player_tech
(player_ident int not null,
 faction enum ('Terran', 'Protoss', 'Zerg', 'HumanAlliance', 'OrcishHoard',
               'NightElf', 'UndeadScourge', 'Naga', 'XelNaga'),
 tech_count int default 0,
 tech_level int default 0,
PRIMARY KEY(player_ident,faction),
FOREIGN KEY (player_ident)
        REFERENCES sc_players(player_ident)
        ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (faction)
        REFERENCES sc_factions(faction)
        ON DELETE CASCADE ON UPDATE CASCADE)
ENGINE=INNODB;
