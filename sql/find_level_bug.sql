SELECT p.steamid, p.name, p.overall_level, r.race_ident, r.race_name, pr.level, pu.upgrade_level
FROM sc_players p
LEFT JOIN sc_player_races pr ON p.player_ident = pr.player_ident
LEFT JOIN sc_player_upgrades pu ON p.player_ident = pu.player_ident 
LEFT JOIN sc_races r ON pr.race_ident = r.race_ident
WHERE pr.level < (SELECT SUM(ps.upgrade_level) FROM sc_player_upgrades ps WHERE p.player_ident = ps.player_ident AND pr.race_ident = ps.race_ident GROUP BY race_ident)
GROUP BY r.race_ident
LIMIT 100;