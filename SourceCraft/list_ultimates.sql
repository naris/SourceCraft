SELECT    p.player_ident, name, overall_level,
          r.long_name, pr.xp, pr.level, ps.skill, ps.skill_level
     FROM sc_players p
LEFT JOIN sc_player_races pr  ON p.player_ident = pr.player_ident
LEFT JOIN sc_player_skills ps ON p.player_ident = ps.player_ident
                             AND pr.race_ident = ps.race_ident
LEFT JOIN sc_races   r        ON pr.race_ident = r.race_ident
    WHERE ps.skill_level > 0
      AND ps.skill > 2
ORDER BY p.player_ident, r.race_ident, skill