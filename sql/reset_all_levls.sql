DELIMITER $$
DROP PROCEDURE IF EXISTS reset_all_levels $$
CREATE PROCEDURE reset_all_levels ()
BEGIN
  CALL reset_race_levels();
  CALL reset_overall_levels();
END;
$$
DELIMITER ;
