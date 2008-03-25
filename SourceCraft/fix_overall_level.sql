update sc_players p
   set overall_level = (SELECT sum(pr.level)
                          FROM sc_player_races pr
                         where p.player_ident = pr.player_ident)