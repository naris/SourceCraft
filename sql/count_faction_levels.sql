select pr.player_ident, r.faction, count(r.faction) as tech_count, sum(pr.level) as tech_level
  from sc_player_races pr
left join sc_races r on pr.race_ident = r.race_ident
where faction is not null
group by player_ident, faction