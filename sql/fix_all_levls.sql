DELIMITER $$
DROP PROCEDURE IF EXISTS fix_all_levels $$
CREATE PROCEDURE fix_all_levels ()
BEGIN
	CALL fix_race_levels();
  CALL fix_overall_levels();
END;
$$
DELIMITER ;