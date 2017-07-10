SELECT    p.player_ident, name, overall_level, r.race_ident, r.long_name as race,
          pr.level, pr.xp, u.long_name as upgrade, pu.upgrade_level
     FROM sc_players p
LEFT JOIN sc_player_races pr    ON p.player_ident = pr.player_ident
LEFT JOIN sc_races r            ON pr.race_ident = r.race_ident
LEFT JOIN sc_player_upgrades pu ON p.player_ident = pu.player_ident AND pr.race_ident = pu.race_ident
LEFT JOIN sc_upgrades u         ON u.race_ident = pu.race_ident     AND u.upgrade = pu.upgrade
ORDER BY p.player_ident, r.race_ident, upgrade
