select f.long_name, count(*)
from sc_races r
join sc_factions f on f.faction = r.faction
group by r.faction