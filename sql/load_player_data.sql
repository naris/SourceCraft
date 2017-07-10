DELIMITER //

CREATE PROCEDURE load_player_data(id varchar(64))
BEGIN
    SELECT player_ident, race_ident, crystals, vespene, overall_level, settings FROM sc_players WHERE steamid = id;  
END//

DELIMITER ;
