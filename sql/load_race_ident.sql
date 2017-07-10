DELIMITER $$
DROP PROCEDURE IF EXISTS load_race_ident $$
CREATE PROCEDURE load_race_ident (IN name varchar(16))
BEGIN
  SELECT race_ident FROM sc_races WHERE race_name = name;
END;
$$
DELIMITER ;