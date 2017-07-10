CREATE TABLE IF NOT EXISTS sc_player_alias
(player_ident int not null,
 steamid varchar(64),
 name varchar(64),
 last_used timestamp default current_timestamp,
PRIMARY KEY(player_ident,steamid,name),
FOREIGN KEY(player_ident)
        REFERENCES sc_players(player_ident)
        ON DELETE CASCADE ON UPDATE CASCADE)
ENGINE=INNODB;
