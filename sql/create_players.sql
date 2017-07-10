CREATE TABLE IF NOT EXISTS sc_players
(player_ident int not null auto_increment,
 steamid varchar(64) not null,
 name varchar(64),
 race_ident int default 0,
 crystals int default 0,
 vespene int default 0,
 overall_level int default 0,
 settings int default 0,
 username varchar(25),
 last_update timestamp default current_timestamp,
PRIMARY KEY(player_ident),
UNIQUE INDEX (steamid),
UNIQUE INDEX (username))
ENGINE=INNODB;