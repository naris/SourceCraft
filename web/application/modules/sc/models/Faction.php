<?php

/**
 * Factions
 *  
 * @author wilsonmu
 * @version 
 */

require_once ('App_Db_Table_Abstract.php');

class Faction extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = 'sc_factions';
	protected $_primary = array("faction");
	protected $_cols = array(
		'faction'	=> 'faction',
		'long_name'	=> 'long_name',
		'description'	=> 'description',
		'image'		=> 'image',
		'add_date'	=> 'add_date'
	);	

	public function getFactionList($has_races=false,$fetch=false)
	{
		$select = $this->select()
			->from(array('f' => 'sc_factions'),
			       array('faction', 'long_name', 'image',
			       	     'description' => 'f.description'));

		if ($has_races)
		{
			$select->where('exists (select * from sc_races r where r.faction = f.faction)');
		}

		$select->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getFactionListForPlayer($player_ident, $fetch=false)
	{
		$select = $this->select()
				->setIntegrityCheck(false)
				->from(array('f' => 'sc_factions'),
	                               array('faction', 'long_name', 'image',
			       	             'description' => 'f.description'))
				->joinLeft(array('pt' => 'sc_player_tech'),
				   		 'f.faction = pt.faction',
				           array('pt.tech_count','pt.tech_level'))
				->where('player_ident = ?', $player_ident)
				->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getFaction($factionId)
	{
		$select = $this->select()
				->where('faction = ?', $factionId);
		return $this->fetchRow($select);
	}
}
