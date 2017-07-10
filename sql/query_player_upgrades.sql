SELECT pu.player_ident, p.name, pu.race_ident, r.long_name as race,
       pu.upgrade, u.long_name as upgrade, pu.upgrade_level
FROM sc_player_upgrades pu
LEFT JOIN sc_players p     ON p.player_ident = pu.player_ident
LEFT JOIN sc_races r       ON r.race_ident = pu.race_ident
LEFT JOIN sc_upgrades u    ON u.race_ident = pu.race_ident AND u.upgrade = pu.upgrade
#where concat_ws(",", pu.race_ident, pu.upgrade)
#      not in (select concat_ws(",", u.race_ident, u.upgrade) from sc_upgrades u)