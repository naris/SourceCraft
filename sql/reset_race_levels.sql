DELIMITER $$
DROP PROCEDURE IF EXISTS reset_race_levels $$
CREATE PROCEDURE reset_race_levels ()
BEGIN
	UPDATE sc_player_races pr
   	  SET level = (SELECT sum(ps.upgrade_level)
          	         FROM sc_player_upgrades ps
                    WHERE pr.player_ident = ps.player_ident
		                  AND pr.race_ident = ps.race_ident);
END;
$$
DELIMITER ;