<?php

/**
 * PlayerRace
 *  
 * @author wilsonmu
 * @version 
 */

require_once 'App_Db_Table_Abstract.php';

class PlayerRace extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = "sc_player_races";
	protected $_primary = array("player_ident", "race_ident");
	protected $_cols = array(
		'player_ident'  => 'player_ident',
		'race_ident'    => 'race_ident',
		'xp'       	=> 'xp',
		'level'        	=> 'level'
	);	
}
