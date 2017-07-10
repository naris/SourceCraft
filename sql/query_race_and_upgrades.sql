select r.race_ident, r.race_name, r.long_name, u.upgrade, u.upgrade_name, u.description
from sc_races r 
join sc_upgrades u on u.race_ident = r.race_ident
order by r.race_ident, u.upgrade