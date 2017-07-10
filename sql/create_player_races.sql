CREATE TABLE IF NOT EXISTS sc_player_races
(player_ident int not null,
 race_ident int not null,
 xp int default 0,
 level int default 0,
PRIMARY KEY(player_ident,race_ident),
FOREIGN KEY (player_ident)
        REFERENCES sc_players(player_ident)
        ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (race_ident)
        REFERENCES sc_races(race_ident)
        ON DELETE CASCADE ON UPDATE CASCADE)
ENGINE=INNODB;
