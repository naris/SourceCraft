CREATE OR REPLACE VIEW sc_race_list AS
SELECT r.*,f.long_name AS faction_name, pr.long_name as parent_long_name
FROM sc_races r
LEFT JOIN sc_factions f ON f.faction = r.faction
LEFT JOIN sc_races pr ON pr.race_name = r.parent_name
