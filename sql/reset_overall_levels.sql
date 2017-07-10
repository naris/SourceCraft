DELIMITER $$
DROP PROCEDURE IF EXISTS reset_overall_levels $$
CREATE PROCEDURE reset_overall_levels ()
BEGIN
	UPDATE sc_players p
	   SET overall_level = (SELECT sum(pr.level)
				                    FROM sc_player_races pr
                           WHERE p.player_ident = pr.player_ident);
END;
$$
DELIMITER ;