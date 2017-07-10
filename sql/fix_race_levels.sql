DELIMITER $$
DROP PROCEDURE IF EXISTS fix_race_levels $$
CREATE PROCEDURE fix_race_levels ()
BEGIN
	UPDATE sc_player_races pr
   	  SET level = GREATEST(level, (SELECT sum(ps.upgrade_level)
          	                     	   FROM sc_player_upgrades ps
                 	                  WHERE pr.player_ident = ps.player_ident
		   	             	               AND pr.race_ident = ps.race_ident));
END;
$$
DELIMITER ;