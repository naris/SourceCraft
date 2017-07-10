<?php

/**
 * Race
 *  
 * @author wilsonmu
 * @version 
 */

require_once ('App_Db_Table_Abstract.php');

class Race extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = 'sc_races';
	protected $_primary = array("race_ident");
	protected $_cols = array(
		'race_ident'    	=> 'race_ident',
		'race_name'  		=> 'race_name',
		'long_name'  		=> 'long_name',
		'parent_name'  		=> 'parent_name',
		'faction'  		=> 'faction',
		'type'  		=> 'type',
		'description'  		=> 'description',
		'image'  		=> 'image',
		'required_level'  	=> 'required_level',
		'tech_level'  		=> 'tech_level',
		'add_date'		=> 'add_date'
	);

	public function getRaceList($fetch=false)
	{
		$select = $this->getRaceSelect()
			->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getRaceListForFaction($factionId, $fetch=false)
	{
		$select = $this->getRaceSelect()
			->where('r.faction = ?', $factionId)
			->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getRaceListForPlayer($player_ident, $fetch=false)
	{
		$select = $this->getRaceSelect()
			->join(array('pr' => 'sc_player_races'),
			      	     'pr.race_ident = r.race_ident',
			      	     array('xp', 'level'))
			->where('pr.player_ident = ?', $player_ident)
			->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getRaceListForName($name, $fetch=false)
	{
		$select = $this->getRaceSelect()
			->where('r.race_name like ?', '%' . $name . '%')
			->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getRaceForIdent($ident)
	{
		$select = $this->getRaceSelect()
			->where('r.race_ident = ?', $ident);

		return $this->fetchRow($select);
	}

	public function getRaceForName($name)
	{
		$select = $this->getRaceSelect()
			->where('r.race_name like ?', '%' . $name . '%');

		return $this->fetchRow($select);
	}

	private function getRaceSelect()
	{
		return $this->select()
			->setIntegrityCheck(false)
			->from(array('r' => 'sc_races'),
				array('race_ident', 'long_name', 'faction', 'type',
			              'parent_name', 'image', 'required_level', 'tech_level',
			       	      'description' => 'r.description'))
			->joinLeft(array('f' => 'sc_factions'),
				'f.faction = r.faction',
				array('faction_name' => 'f.long_name'))
			->joinLeft(array('rp' => 'sc_races'),
				'rp.race_name = r.parent_name',
				array('parent_long_name' => 'rp.long_name'));
	}
	
	public function selectPlayerRaces($ident)
	{
		return $this->getRaceSelect()
			    ->joinLeft(array('sc_player_races', 'pr'),
				       'r.player_ident == pr.player_ident',
				       array('pr.xp','pr.level'))
			    ->where('player_ident = ?', $ident)
			    ->order('long_name');
	}
}
