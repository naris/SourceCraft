<?php

/**
 * Upgrade
 *  
 * @author wilsonmu
 * @version 
 */

require_once 'App_Db_Table_Abstract.php';

class Upgrade extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = 'sc_upgrades';
	protected $_primary = array("race_ident", "upgrade");
	protected $_cols = array(
		'race_ident'    	=> 'race_ident',
		'upgrade'  			=> 'upgrade',
		'category'      	=> 'category',
		'upgrade_name'  	=> 'upgrade_name',
		'long_name'  		=> 'long_name',
		'description'		=> 'description',
		'invoke'			=> 'invoke',
		'bind'				=> 'bind',
		'image'				=> 'image',
		'required_level'	=> 'required_level',
		'max_level'			=> 'max_level',
		'cost_crystals'		=> 'cost_crystals',
		'cost_vespene'		=> 'cost_vespene',
		'energy'			=> 'energy',
		'accumulated'		=> 'accumulated',
		'recurring_energy'	=> 'recurring_energy',
		'crystals'			=> 'crystals',
		'vespene'			=> 'vespene',
		'cooldown'			=> 'cooldown',
		'add_date'			=> 'add_date'
	);

	public function getUpgradeListForFaction($factionId, $fetch=false)
	{
		$select = $this->select()
			->setIntegrityCheck(false)
			->from(array('u' => 'sc_upgrades'),
				array('u.upgrade', 'u.long_name', 'u.image',
				      'description' 	 => 'u.description',
				      'invoke' 			 => 'u.invoke',
				      'bind' 			 => 'u.bind',
				      'category' 		 => 'u.category',
				      'required_level'	 => 'u.required_level',
				      'max_level'		 => 'u.max_level',
				      'cost_crystals'	 => 'u.cost_crystals',
				      'cost_vespene'	 => 'u.cost_vespene',
				      'energy'			 => 'u.energy',
				      'accumulated'		 => 'u.accumulated',
				      'recurring_energy' => 'u.recurring_energy',
				      'crystals'		 => 'u.crystals',
				      'vespene'			 => 'u.vespene',
				      'cooldown'		 => 'u.cooldown'))
			->join(array('r' => 'sc_races'),
			      'u.race_ident = r.race_ident',
			      array("r.race_ident"))
			->where('r.faction = ?', $factionId)
			->order(array('u.race_ident', 'u.upgrade'));

		return $fetch ? $this->fetchAll($select) : $select;
	}

	public function getUpgradeListForRace($race_ident, $fetch=false)
	{
		$select = $this->select()
			->from(array('u' => 'sc_upgrades'),
				array('u.race_ident', 'u.upgrade', 'u.long_name', 'u.image',
				      'description'		 => 'u.description',
				      'invoke'			 => 'u.invoke',
				      'bind'			 => 'u.bind',
				      'category'		 => 'u.category',
				      'required_level'	 => 'u.required_level',
				      'max_level'		 => 'u.max_level',
				      'cost_crystals'	 => 'u.cost_crystals',
				      'cost_vespene'	 => 'u.cost_vespene',
				      'energy'			 => 'u.energy',
				      'accumulated'		 => 'u.accumulated',
				      'recurring_energy' => 'u.recurring_energy',
				      'crystals'		 => 'u.crystals',
				      'vespene'			 => 'u.vespene',
				      'cooldown'		 => 'u.cooldown'))
			->where('u.race_ident = ?', $race_ident)
			->order(array('u.race_ident', 'u.upgrade'));

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getUpgradeListForPlayer($player_ident, $fetch=false)
	{
		$select = $this->select()
			->setIntegrityCheck(false)
			->from(array('pr' => 'sc_player_races'))
			->join(array('u' => 'sc_upgrades'),
				      'u.race_ident = pr.race_ident',
				      array('u.race_ident', 'u.upgrade', 'u.long_name', 'u.image',
			       	    'description'	   => 'u.description',
			       	    'invoke'		   => 'u.invoke',
			       	    'bind'			   => 'u.bind',
					    'category'		   => 'u.category',
					    'required_level'   => 'u.required_level',
					    'max_level'		   => 'u.max_level',
					    'cost_crystals'	   => 'u.cost_crystals',
					    'cost_vespene'	   => 'u.cost_vespene',
					    'energy'		   => 'u.energy',
					    'accumulated'	   => 'u.accumulated',
					    'recurring_energy' => 'u.recurring_energy',
					    'crystals'		   => 'u.crystals',
					    'vespene'		   => 'u.vespene',
					    'cooldown'		   => 'u.cooldown'))
			->joinLeft(array('pu' => 'sc_player_upgrades'),
					  'pu.race_ident = u.race_ident and pu.upgrade = u.upgrade and pu.player_ident = pr.player_ident',
					  array('pu.upgrade_level'))
			->where('pr.player_ident = ?', $player_ident)
			->order(array('u.race_ident', 'u.upgrade'));

		return $fetch ? $this->fetchAll($select) : $select;		
	}
}
