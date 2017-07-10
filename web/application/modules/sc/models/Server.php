<?php

/**
 * Server
 *  
 * @author wilsonmu
 * @version 
 */

require_once ('App_Db_Table_Abstract.php');

class Server extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sm";
	protected $_name = 'server';
	protected $_primary = array("id");
	protected $_cols = array(
		'id'    	=> 'id',
		'address'    	=> 'address',
		'groupnumber'  	=> 'groupnumber',
		'last_update'	=> 'last_update',
		'display_name'  => 'display_name',
		'offline_name'  => 'offline_name',
		'maxplayers'  	=> 'maxplayers',
		'currplayers'  	=> 'currplayers',
		'description'  	=> 'description',
		'map'  		=> 'map'
	);

	public function getServerList($fetch=false)
	{
		$select = $this->select()
			->order('display_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getActiveServerList($fetch=false)
	{
		$select = $this->select()
			->where("groupnumber = '1' AND last_update >= DATE_SUB(NOW(), INTERVAL 60 MINUTE)")
			->order('display_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}
}
