create temporary table player_levels
SELECT pr.player_ident, pr.race_ident, pr.level, sum(ps.upgrade_level) as level_sum
   FROM sc_player_races pr, sc_player_upgrades ps
  WHERE pr.player_ident = ps.player_ident
    AND pr.race_ident = ps.race_ident
group by pr.player_ident, pr.race_ident
order by pr.player_ident, pr.race_ident;

SELECT p.name, p.steamid, r.race_name, level, level_sum, p.last_update
from player_levels pl
join sc_players p on p.player_ident = pl.player_ident
join sc_races r on r.race_ident = pl.race_ident
where level_sum > level
