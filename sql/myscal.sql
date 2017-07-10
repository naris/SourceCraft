--
-- Table structure for table `sm_logging`
--

CREATE TABLE IF NOT EXISTS `sm_logging` (
  `ID` int(11) NOT NULL auto_increment,
  `Server_ID` int(11) NOT NULL,
  `steamid` varchar(100) collate utf8_bin NOT NULL,
  `logtag` varchar(100) collate utf8_bin NOT NULL,
  `message` varchar(255) collate utf8_bin NOT NULL,
  `time_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin AUTO_INCREMENT=1269 ;

-- --------------------------------------------------------

--
-- Table structure for table `sm_servercfg`
--

CREATE TABLE IF NOT EXISTS `sm_servercfg` (
  `ID` int(11) NOT NULL auto_increment,
  `Server_ID` int(11) default NULL,
  `Command_Name` varchar(64) collate utf8_bin NOT NULL default '',
  `Command_Value` varchar(255) collate utf8_bin NOT NULL default '',
  `Filename` varchar(64) collate utf8_bin NOT NULL default '',
  `Default_Command_Value` varchar(255) collate utf8_bin NOT NULL default '',
  `TYPE` varchar(16) collate utf8_bin default NULL,
  `time_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin AUTO_INCREMENT=90 ;
