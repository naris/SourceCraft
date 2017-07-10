<?php

/**
 * PlayerAlias
 *  
 * @author wilsonmu
 * @version 
 */

require_once 'App_Db_Table_Abstract.php';

class PlayerAlias extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = "sc_player_alias";
	protected $_primary = array("player_ident", "steamid", "name");
	protected $_cols = array(
		'player_ident'  => 'player_ident',
		'steamid'    	=> 'steamid',
		'name'       	=> 'name',
		'last_used'     => 'last_used'
	);

	public function getAliasesForPlayer($player_ident)
	{
		return $this->fetchAll($this->getAliasSelect()
					->where('player_ident = ?', $player_ident)
					->order(array('last_used','name')));
	}

	public function getAliasesForSteamid($steamid)
	{
		return $this->fetchAll($this->getAliasSelect()
					->where('steamid = ?', $steamid)
					->order(array('last_used','name')));
	}

	public function getAliasesForName($name)
	{
		return $this->fetchAll($this->getAliasSelect()
					->where('name = ?', $name)
					->order(array('last_used','name')));
	}

	public function getAliasesMatchingName($name)
	{
		return $this->fetchAll($this->getAliasSelect()
					->where('name like ?', $name)->order('name')
					->order(array('last_used','name')));
	}

	private function getAliasSelect()
	{
		return $this->select()
			->from(array('pa' => 'sc_player_alias'),
				array('steamid', 'name', 'last_used',
			      		'last_used_date' => "DATE_FORMAT(last_used, '%m/%d/%y')"));
	}
}
