SELECT pr.player_ident, name, pr.race_ident, r.long_name, pr.level, sum(ps.upgrade_level) as calc
  FROM sc_player_races pr
LEFT JOIN sc_player_upgrades ps ON pr.player_ident = ps.player_ident
                               AND pr.race_ident = ps.race_ident
LEFT JOIN sc_races r            ON pr.race_ident = r.race_ident
LEFT JOIN sc_players p    	ON p.player_ident = pr.player_ident
GROUP BY pr.player_ident, pr.race_ident
