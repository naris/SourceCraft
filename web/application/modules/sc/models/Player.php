<?php

require_once ('App_Db_Table_Abstract.php');

class Player extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = "sc_players";
	protected $_primary = "player_ident";
	protected $_sequence = true;
	protected $_cols = array(
		'player_ident'  => 'player_ident',
		'steamid'       => 'steamid',
		'name'        	=> 'name',
		'race_ident'    => 'race_ident',
		'crystals'   	=> 'crystals',
		'vespene'   	=> 'vespene',
		'overall_level' => 'overall_level',
		'settings' 		=> 'settings',
		'last_update' 	=> 'last_update',
		'username'		=> 'username'
	);

	public function getPlayerList($fetch=false)
	{
		$select = $this->getPlayerSelect();

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getPlayerForIdent($ident)
	{
		$select = $this->getPlayerSelect()
			->where('player_ident = ?', $ident);

		return $this->fetchRow($select);
	}

	public function getPlayerForSteamid($steamid)
	{
		$select = $this->getPlayerSelect()
			->where('steamid = ?', $steamid);

		return $this->fetchRow($select);
	}

	public function getPlayerForUsername($username)
	{
		$select = $this->getPlayerSelect()
			->where('username = ?', $username);

		return $this->fetchRow($select);
	}

	public function getPlayerForName($name)
	{
		$select = $this->getPlayerSelect()
			->where('name like ?', '%' . $name . '%');

		return $this->fetchAll($select);
	}

	private function getPlayerSelect()
	{
		return $this->select()
			->from(array('p' => 'sc_players'),
				array('player_ident', 'steamid', 'overall_level',
			       		'name', 'crystals', 'vespene', 'last_update',
			      		'last_update_date' => "DATE_FORMAT(last_update, '%m/%d/%y')"));
	}

	public function getPlayerListMatchingName($name, $fetch=false)
	{
		$select_players = $this->select()
					->setIntegrityCheck(false)
					->from(array('p' => 'sc_players'),
						array('player_ident', 'steamid', 'overall_level',
					       		'crystals', 'vespene', 'name'))
					->where('name like ?', '%' . $name . '%');

		$select_aliases = $this->select()
					->setIntegrityCheck(false)
					->from(array('p' => 'sc_players'),
						array('player_ident', 'steamid', 'overall_level',
					       		'crystals', 'vespene'))
					->join(array('pa' => 'sc_player_alias'),
				      			"pa.player_ident = p.player_ident",
				      			"name")
					->where('pa.name like ?', '%' . $name . '%');

		$select_union = $this->select()
					->setIntegrityCheck(false)
					->union(array($select_players, $select_aliases))
					->order('name');

		return $fetch ? $this->fetchAll($select_union) : $select_union;		
	}
}

?>
