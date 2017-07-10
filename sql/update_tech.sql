insert into sc_player_tech (player_ident, faction, tech_count, tech_level)
  select pr.player_ident, r.faction, count(r.faction) as tech_count, sum(pr.level) as tech_level
    from sc_player_races pr
  left join sc_races r on pr.race_ident = r.race_ident
  where faction is not null
  group by player_ident, faction
on duplicate key update tech_count=values(tech_count), tech_level=values(tech_level)