CREATE TABLE IF NOT EXISTS sc_upgrades
(race_ident int NOT NULL,
 upgrade int NOT NULL,
 category int,
 upgrade_name VARCHAR(16),
 long_name VARCHAR(64),
 description TEXT,
 add_date timestamp NOT NULL default current_timestamp,
PRIMARY KEY (race_ident, upgrade),
FOREIGN KEY (race_ident)
        REFERENCES sc_races(race_ident)
        ON DELETE CASCADE ON UPDATE CASCADE)
ENGINE=INNODB;