--
-- Table structure for table `mysql_bans`
--

DROP TABLE IF EXISTS `mysql_bans`;
CREATE TABLE IF NOT EXISTS `mysql_bans` (
  `id` int(11) NOT NULL auto_increment,
  `steam_id` varchar(32) NOT NULL,
  `player_name` varchar(65) NOT NULL,
  `ipaddr` varchar(24) NOT NULL,
  `ban_length` int(1) NOT NULL default '0',
  `ban_reason` varchar(100) NOT NULL,
  `banned_by` varchar(100) NOT NULL,
  `timestamp` timestamp NOT NULL default '0000-00-00 00:00:00' on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `steam_id` (`steam_id`),
  UNIQUE KEY `ipaddr` (`ipaddr`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
